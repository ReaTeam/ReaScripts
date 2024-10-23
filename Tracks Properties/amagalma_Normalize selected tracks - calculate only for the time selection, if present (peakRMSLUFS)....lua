-- @description Normalize selected tracks - calculate only for the time selection, if present (peak/RMS/LUFS)...
-- @author amagalma
-- @version 1.02
-- @changelog - Request a specific version of ReaImGui's API
-- @donation https://www.paypal.me/amagalma
-- @about
--   Normalizes the selected tracks' volume to hit the desired value with the desired method.
--   If a time selection is present, then the calculations will be based only on the part of the tracks that is inside the time selection.
--   Upon completion, a CSV file containing all new track statistics is copied to the clipboard. You can paste it to a spreadsheet editor to view it.
--
--   - Requires ReaImGui


dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.5.10') -- current version at the time of writing the script


-- first time run values
local wanted_value = -23
local selected_method, wanted_method = 1, "LUFSI"

local ext_state = reaper.GetExtState( "amagalma_NormalizeTracks", "last settings" )
if ext_state ~= "" then
  wanted_value, selected_method = ext_state:match("(%S+) (%S+)")
  selected_method = tonumber(selected_method)
end

local reaper_ini = reaper.get_ini_file()

-------------------------------------------------------------------------------------


local function Normalize()
  local _, project_filename = reaper.EnumProjects( -1 )
  local sep = package.config:sub(1,1)
  local _, render_path = reaper.GetSetProjectInfo_String( 0, "RENDER_FILE", "", false )

  if project_filename == "" or render_path == "" then -- unsaved
    render_path = reaper.GetProjectPath() .. sep ..
    ({reaper.BR_Win32_GetPrivateProfileString("reaper", "defrenderpath", "", reaper_ini)})[2] .. sep
  end


  -- Calculate loudness of selected tracks within time selection via dry run render
  local track_cnt = reaper.CountSelectedTracks( 0 )
  if track_cnt == 0 then return reaper.defer(function() end) end

  local tracks = {}

  -- Set vol to 0dB to avoid miscalculations for tracks with -inf volume
  for i = 0, track_cnt-1 do
    local track = reaper.GetSelectedTrack(0, i )
    local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL" )
    tracks[i+1] = {ptr = track, prev_vol = vol}
    reaper.SetMediaTrackInfo_Value( track, "D_VOL", 1 )
  end

  local ok, result = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", "42439", false)


  local function Restore_volumes()
    for i = 1, track_cnt do
      reaper.SetMediaTrackInfo_Value( tracks[i].ptr, "D_VOL", tracks[i].prev_vol )
    end
  end


  if not ok or result == "" or result:match(":[%d%-%.]-;") == nil then
    Restore_volumes()
    return reaper.defer(function() end)
  end

  local floor,ceil = math.floor,math.ceil

  local function round(num)
    if num >= 0 then return floor(num * 10 + 0.5) / 10
    else return ceil(num * 10 - 0.5) / 10 end
  end

  local cnt = 0
  local fields = {}

  reaper.Undo_BeginBlock()

  for field in result:gmatch("[^;]+") do
    local name, value = field:match("(%u+):(.+)")
    if name == "FILE" then
      cnt = cnt + 1
      local id_from_field = math.tointeger(reaper.GetMediaTrackInfo_Value( tracks[cnt].ptr, "IP_TRACKNUMBER" ))
      local name_from_field = value:match(".+[\\/](.*)")
      local current_track = reaper.GetSelectedTrack( 0, cnt-1 )
      -- comparison needed to make sure that the results are NOT from a previous run
      if ({reaper.GetSetMediaTrackInfo_String( current_track, "P_NAME", "", false )})[2] ~= name_from_field or
         math.tointeger(reaper.GetMediaTrackInfo_Value( current_track, "IP_TRACKNUMBER" )) ~= id_from_field
      then
        -- mismatch : the results are from a previous run
        mismatch = true
        Restore_volumes()
        reaper.Undo_EndBlock( "Failed to normalize tracks", 1)
        return reaper.defer(function() end)
      end
      tracks[cnt].id = id_from_field
      tracks[cnt].name = name_from_field
    else
      if not fields[name] then fields[name] = true end
      value = tonumber(value)
      tracks[cnt][name] = value
      if name == wanted_method then
        local change = wanted_value - value
        tracks[cnt].change = change
        reaper.SetMediaTrackInfo_Value( tracks[cnt].ptr, "D_VOL", 10^((change)/20) )
      end
    end
  end

  -- Order fields
  local Fields = {}
  local Fields_cnt = 0
  for field in pairs(fields) do
    if field ~= "CLIP" and field ~= "TRUPEAKCLIP" then
      Fields_cnt = Fields_cnt + 1
      Fields[Fields_cnt] = field
    end
  end
  table.sort( Fields, function(a,b) return a<b end)
  fields = nil


  -- Export CSV
  local csv = {[1] = "Track Nr,Name," .. table.concat(Fields, ",")}
  for i = 1, cnt do
    local t = {[1] = tracks[i].id, [2] = tracks[i].name}
    for f = 1, Fields_cnt do
      if Fields[f] == "LRA" then
        t[#t+1] = tracks[i].LRA
      elseif tracks[i][Fields[f]] and tracks[i].change then
        t[#t+1] = round(tracks[i][Fields[f]] + tracks[i].change)
      else
        t[#t+1] = "-"
      end
    end
    csv[i+1] = table.concat(t, ",")
  end

  if #csv ~= 1 then
    reaper.ClearConsole()
    csv = table.concat(csv, "\n")
    reaper.CF_SetClipboard( csv )
    reaper.ShowConsoleMsg("CSV: (copied to clipboard, paste in spreadsheet to see)\n\n" .. csv .. "\n\n")
  end

  reaper.Undo_EndBlock( "Set selected tracks to " .. wanted_value .. "dB " .. wanted_method, 1)
end


-- GUI --------------------------------------------------------------------------------

local _, true_peak = reaper.BR_Win32_GetPrivateProfileString( "reaper", "renderclosewhendone", "", reaper_ini )
if true_peak ~= "" and tonumber(true_peak) & 256 == 256 then
  tp_en = true
end
local Methods = {{"LUFS-I", "LU", "LUFSI"}, {"RMS-I", "dB", "RMSI"}, {(tp_en and "True " or "") .."Peak", "dB", 
            (tp_en and "TRUE" or "") .."PEAK"}, {"LUFS-M max", "LU", "LUFSMMAX"}, {"LUFS-S max", "LU", "LUFSSMAX"}}
wanted_method = Methods[selected_method][3]

local ctx = reaper.ImGui_CreateContext('amagalma_NormalizeSelectedTracks')
local font_size = reaper.GetAppVersion():match('OSX') and math.floor( 16 *0.8+0.5 ) or 16
local font = reaper.ImGui_CreateFont('sans-serif', font_size)
reaper.ImGui_AttachFont(ctx, font)

local WhatToDo_flags =  reaper.ImGui_WindowFlags_NoCollapse() |
                        reaper.ImGui_WindowFlags_NoResize() |
                        reaper.ImGui_WindowFlags_NoSavedSettings()

local NoArrowButton =  reaper.ImGui_ComboFlags_NoArrowButton()

local decimal = reaper.ImGui_InputTextFlags_CharsDecimal()

reaper.ImGui_SetNextWindowSize(ctx, 0, 0)
local scr_center_x, scr_center_y = reaper.ImGui_Viewport_GetWorkCenter(reaper.ImGui_GetMainViewport(ctx))
reaper.ImGui_SetNextWindowPos(ctx, scr_center_x, scr_center_y, nil, 0.5, 0.5)



local function loop()
  reaper.ImGui_PushFont(ctx, font)
  local visible, open = reaper.ImGui_Begin(ctx, 'Normalize Selected Tracks', true, WhatToDo_flags)
  if visible then

    local wheel = reaper.ImGui_GetMouseWheel(ctx)

    reaper.ImGui_Spacing( ctx )


    reaper.ImGui_AlignTextToFramePadding( ctx )
    reaper.ImGui_Text(ctx, 'Normalize to:')


    reaper.ImGui_SameLine( ctx )


    reaper.ImGui_PushItemWidth(ctx, 100)
    if reaper.ImGui_BeginCombo(ctx, '##Methods', Methods[selected_method][1], NoArrowButton) then
      for i = 1, 5 do
        local is_selected = selected_method == i
        if reaper.ImGui_Selectable(ctx, Methods[i][1], is_selected) then
          selected_method = i
        end
        if is_selected then
          reaper.ImGui_SetItemDefaultFocus(ctx)
        end
      end
      reaper.ImGui_EndCombo(ctx)
    end
    reaper.ImGui_PopItemWidth(ctx)

    if reaper.ImGui_IsItemHovered(ctx) then
      if wheel > 0 then
        selected_method = selected_method-1
        if selected_method < 1 then selected_method = 1 end
      elseif wheel < 0 then
        selected_method = selected_method + 1
        if selected_method > 5 then selected_method = 5 end
      end
    end

    reaper.ImGui_SameLine( ctx )

    reaper.ImGui_PushItemWidth(ctx, 50)
    local retval
    retval, wanted_value = reaper.ImGui_InputText(ctx, " " .. Methods[selected_method][2] .. '##Unit', wanted_value, decimal)
    if retval then
      if tonumber(wanted_value) and tonumber(wanted_value) > 0 then wanted_value = 0 end
    end
    reaper.ImGui_PopItemWidth(ctx)


    reaper.ImGui_Spacing( ctx )


    reaper.ImGui_PushTextWrapPos(ctx, 292)
    reaper.ImGui_Text(ctx, 'If a time selection is present, the calculation will take into account \z
    only the portion of the tracks that is inside the time selection.')
    reaper.ImGui_PopTextWrapPos(ctx)


    reaper.ImGui_Spacing( ctx ) ; reaper.ImGui_Spacing( ctx )


    reaper.ImGui_SetCursorPosX( ctx, 30 )
    if reaper.ImGui_Button( ctx, "OK", 100 ) then
      wanted_value = tonumber(wanted_value)
      open = false
      wanted_method = Methods[selected_method][3]
      run_action = true
    end


    reaper.ImGui_SameLine( ctx, 130, 29 )


    if reaper.ImGui_Button( ctx, "Cancel", 100 ) then
      open = false
    end

    reaper.ImGui_Spacing( ctx )

    reaper.ImGui_End(ctx)
  end

  reaper.ImGui_PopFont(ctx)

  if open then
    reaper.defer(loop)
  else
    reaper.ImGui_DestroyContext(ctx)
    reaper.SetExtState( "amagalma_NormalizeTracks", "last settings",
                        wanted_value .. " " .. selected_method, true )
    if run_action then
      reaper.defer(Normalize)
    else
      return reaper.defer(function() end)
    end
  end
end


-- RUN ------------------------------------------------------------------


reaper.defer(loop)

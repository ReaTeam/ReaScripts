-- @description Normalize selected tracks - calculate only for the time selection, if present (peak/RMS/LUFS)...
-- @author amagalma
-- @version 1.09
-- @changelog
--    - Added new v7.79 stereo actions
--    - Improved working with unnamed tracks
-- @donation https://www.paypal.me/amagalma
-- @about
--   Normalizes the selected tracks' volume to hit the desired value with the desired method.
--   If a time selection is present, then the calculations will be based only on the part of the tracks that is inside the time selection.
--
--   - Requires ReaImGui and SWS

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.5.10') -- current version at the time of writing the script


-- first time run values
local wanted_value = -23
local selected_method, wanted_method = 1, "LUFSI"
local Channels = { "1 & 2 Only (Stereo)", "All channels" }
local wanted_channels = 1

local ext_state = reaper.GetExtState( "amagalma_NormalizeTracks", "last settings" )
if ext_state ~= "" then
  wanted_value, selected_method = ext_state:match("(%S+) (%S+)")
  selected_method = tonumber(selected_method)
end

-------------------------------------------------------------------------------------

local max_name = 0
local function Normalize()
  reaper.PreventUIRefresh( 1 )
  local _, project_filename = reaper.EnumProjects( -1 )
  local sep = package.config:sub(1,1)
  local _, render_path = reaper.GetSetProjectInfo_String( 0, "RENDER_FILE", "", false )

  if project_filename == "" or render_path == "" then -- unsaved
    render_path = reaper.GetProjectPath() .. sep ..
    ({reaper.BR_Win32_GetPrivateProfileString("reaper", "defrenderpath", "", reaper.get_ini_file())})[2] .. sep
  end

  -- Calculate loudness of selected tracks within time selection via dry run render
  local track_cnt = reaper.CountSelectedTracks( 0 )
  if track_cnt == 0 then return reaper.defer(function() end) end

  local tracks = {}
  local tracks_with_change = {}

  -- Set vol to 0dB to avoid miscalculations for tracks with -inf volume
  for i = 0, track_cnt-1 do
    local track = reaper.GetSelectedTrack(0, i )
    local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL" )
    local _, name = reaper.GetTrackName( track )
    local _, orig_name = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
    if #name > max_name then max_name = #name end
    local guid = reaper.GetTrackGUID( track )
    local id = math.tointeger(reaper.GetMediaTrackInfo_Value( track, "IP_TRACKNUMBER" ))
    tracks[guid] = {ptr = track, prev_vol = vol, name = name, id = id, orig_name = orig_name}
    reaper.GetSetMediaTrackInfo_String( track, "P_NAME", guid, true )
    reaper.SetMediaTrackInfo_Value( track, "D_VOL", 1 )
  end
  
  local render_settings = reaper.SNM_GetIntConfigVar( "renderclosewhendone", -5555 )
  local new_render_settings = render_settings
  local currently_calculating_RMS = render_settings & 1536 == 1536
  local currently_calculating_TruePeak = render_settings & 256 == 256
  
  if currently_calculating_RMS and (selected_method == 1 or selected_method == 4 or selected_method == 5) then
    new_render_settings = new_render_settings & ~1536
  elseif (not currently_calculating_RMS) and selected_method == 2 then
    new_render_settings = new_render_settings | 1536
  end
  
  if currently_calculating_TruePeak and selected_method ~= 6 then
    new_render_settings = new_render_settings & ~256
  elseif selected_method == 6 and (not currently_calculating_TruePeak) then
    new_render_settings = new_render_settings | 256
  end
    
  -- Set new render settings
  reaper.SNM_SetIntConfigVar( "renderclosewhendone", new_render_settings )

  local ok, result = reaper.GetSetProjectInfo_String(0, "RENDER_STATS", wanted_channels == 1 and "43811" or "42439", false)

  -- Restore previous render settings
  reaper.SNM_SetIntConfigVar( "renderclosewhendone", render_settings )

  local function Restore_volumes_names( volumes, names )
    for guid, info in pairs(tracks) do
      if volumes then
        reaper.SetMediaTrackInfo_Value( info.ptr, "D_VOL", info.prev_vol )
      end
      if names then
        reaper.GetSetMediaTrackInfo_String( info.ptr, "P_NAME", info.orig_name, true )
      end
    end
  end

  if not ok or result == "" or result:match(":[%d%-%.]-;") == nil then
    Restore_volumes_names( true, true )
    return reaper.defer(function() end)
  end

  local floor,ceil = math.floor,math.ceil

  local function round(num)
    if num >= 0 then return floor(num * 10 + 0.5) / 10
    else return ceil(num * 10 - 0.5) / 10 end
  end

  local fields = {}

  reaper.Undo_BeginBlock()

  local current_guid, current_track
  for field in result:gmatch("[^;]+") do
    local name, value = field:match("(%u+):(.+)")
    if name == "FILE" then
      current_guid = value
      current_track = tracks[current_guid].ptr
    else
      if not fields[name] then fields[name] = true end
      value = tonumber(value)
      tracks[current_guid][name] = value
      if name == wanted_method then
        local change = wanted_value - value
        tracks_with_change[current_guid] = true
        tracks[current_guid].change = change
        reaper.SetMediaTrackInfo_Value( current_track, "D_VOL", 10^((change)/20) )
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


  -- Show info
  max_name = max_name + 3
  
  local function Sp( str ) -- add spaces
    if type(str) ~= "string" then str = tostring(str) end
    return ( str .. string.rep(" ", max_name - #str ) )
  end
  
  local fields_with_space = {}
  for i = 1, #Fields do
    fields_with_space[i] = Sp(Fields[i])
  end
  
  local info = {[1] = "0"}
  local i = 1
  for guid in pairs(tracks) do
    i = i + 1
    local t = {[1] = Sp(tracks[guid].id), [2] = Sp(tracks[guid].name)}
    for f = 1, Fields_cnt do
      if Fields[f] == "LRA" then
        t[#t+1] = Sp(tracks[guid].LRA)
      elseif tracks[guid][Fields[f]] and tracks[guid].change then
        t[#t+1] = Sp(round(tracks[guid][Fields[f]] + tracks[guid].change))
      else
        t[#t+1] = Sp("-")
      end
    end
    info[i] = table.concat(t)
  end

  if #info ~= 1 then
    reaper.Main_OnCommand(42663, 0) -- Show ReaScript console
    reaper.ClearConsole()
    table.sort( info, function(a,b) 
      local A = a:match("^%d+")
      local B = b:match("^%d+")
      if A and B then
        return A < B
      else
        return b > a
      end
    end)
    info[1] = Sp("Track") .. Sp("Name") .. table.concat(fields_with_space)
    info = table.concat(info, "\n")
    reaper.ShowConsoleMsg( info )
  end
  
  Restore_volumes_names( false, true )
  
  for guid, info in pairs(tracks) do
    if not tracks_with_change[guid] then
      reaper.SetMediaTrackInfo_Value( info.ptr, "D_VOL", info.prev_vol )
    end
  end

  reaper.PreventUIRefresh( -1 )
  reaper.Undo_EndBlock( "Set selected tracks to " .. wanted_value .. "dB " .. wanted_method, 1)
end

-- GUI --------------------------------------------------------------------------------

local Methods = {{"LUFS-I", "LU", "LUFSI"}, {"RMS-I", "dB", "RMSI"}, {"Peak", "dB", "PEAK"},
                {"LUFS-M max", "LU", "LUFSMMAX"}, {"LUFS-S max", "LU", "LUFSSMAX"}, {"True Peak", "dB", "TRUEPEAK"}}
wanted_method = Methods[selected_method][3]

local ctx = reaper.ImGui_CreateContext('amagalma_NormalizeSelectedTracks')
local font_size = reaper.GetAppVersion():match('OSX') and math.floor( 16 * 0.8+0.5 ) or 16
local font = reaper.ImGui_CreateFont('sans-serif', font_size)
local font_size2 = reaper.GetAppVersion():match('OSX') and math.floor( 14 * 0.8+0.5 ) or 14
local font2 = reaper.ImGui_CreateFont('sans-serif', font_size2)
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
    local txt_w = reaper.ImGui_CalcTextSize( ctx, "Use Channels:    " )

    reaper.ImGui_SameLine( ctx, txt_w )

    reaper.ImGui_PushItemWidth(ctx, 100)
    if reaper.ImGui_BeginCombo(ctx, '##Methods', Methods[selected_method][1], NoArrowButton) then
      for i = 1, 6 do
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
        if selected_method > 6 then selected_method = 6 end
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

    reaper.ImGui_Text(ctx, 'Use Channels:')
    reaper.ImGui_SameLine( ctx, txt_w )
    
    reaper.ImGui_PushItemWidth(ctx, 158)
    if reaper.ImGui_BeginCombo(ctx, '##Channels', Channels[wanted_channels], NoArrowButton) then
      for i = 1, 2 do
        local is_selected = wanted_channels == i
        if reaper.ImGui_Selectable(ctx, Channels[i], is_selected) then
          wanted_channels = i
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
        wanted_channels = wanted_channels-1
        if wanted_channels < 1 then wanted_channels = 1 end
      elseif wheel < 0 then
        wanted_channels = wanted_channels + 1
        if wanted_channels > 2 then wanted_channels = 2 end
      end
    end
    
    reaper.ImGui_Spacing( ctx )

    reaper.ImGui_PushFont(ctx, font2)
    reaper.ImGui_PushTextWrapPos(ctx, 300)
    reaper.ImGui_Text(ctx, 'If a time selection is present, the calculation will only consider \z
                      the portion of the tracks that falls within the time selection.')
    reaper.ImGui_PopFont(ctx)
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

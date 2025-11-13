-- @description Spectral Edits Preset System
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Requires ReaImgui and SWS extensions.

local SIZE = 4
---------------------------------------------------

local script_version = "1.00"
local Script_Name = "amagalma_Spectral Edits Presets"
local _, script_filename, section, cmdID = reaper.get_action_context()
local presets_file = script_filename:match("^.+[/\\]") .. Script_Name .. ".txt"

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.10.0.2'

if SIZE < 1 then SIZE = 1 end
local font_sz = 9 + SIZE
local isMac = reaper.GetOS():match("OS")
local format = string.format
local floor, ceil, log = math.floor, math.ceil, math.log
local ini = reaper.get_ini_file()

-- Check for SWS
if not reaper.SNM_GetDoubleConfigVar then
  reaper.ReaScriptError("SWS Extensions are not installed!")
end

-- Toolbar
reaper.SetToggleCommandState( section, cmdID, 1 ) -- Set ON
reaper.RefreshToolbar2( section, cmdID )

------------------------------------------------------------------------------

-- Presets and default values
local Presets, Presets_cnt = {}, 0
local PresetsDisplay = {} -- For displaying/sorting in the table
local selected_preset = 0
local default_visible = { 0, 0, 0, 0, 0, 0, 1, -224, -224 }
local default_actual = { 0, 0, 0, 0, 1, 1, 1, 0, 0 }
local data = {
  visible = { 0, 0, 0, 0, 0, 0, 1, -224, -224 },
  actual = { 0, 0, 0, 0, 1, 1, 1, 0, 0 },
  ini_name = {
    "specedit_fadein", "specedit_fadeout", "specedit_fadelow", "specedit_fadehi",
    "specedit_gain", "specedit_compthresh", "specedit_compratio",
    "specedit_gatethresh", "specedit_gatefloor"
  }
}
local save_as


------------------------------------------------------------------------------
-- Functions

local function Val2dB(val)
  if val <= 0 then return -224 else return 20*log(val, 10) end
end

local function dB2Val(dB) 
  if dB == -224 then return 0 else return 10^(dB/20) end
end

local function Val2Perc(val)
  return floor(val*100+0.5)
end

local function Perc2Val(val)
  return val/100
end

local function GetExt( key )
  local ret = reaper.GetExtState( Script_Name, key )
  if ret == "" then
    return nil
    else
    return ret
  end
end

local function SetExt( key, val )
  reaper.SetExtState( Script_Name, key, val, true )
end

local function GetCurrentSettings()
  local t = {}
  for i = 1, 9 do
    local val = reaper.SNM_GetDoubleConfigVar( data.ini_name[i], -555555 )
    if val == -555555 then
      reaper.ReaScriptError("Error getting values from reaper.ini!")
    else
      data.actual[i] = val
    end
  end
end

local function UpdateValues()
  for i = 1, 9 do
    if i < 5 then
      data.visible[i] = Val2Perc(data.actual[i])
    elseif i == 7 then
      data.visible[i] = data.actual[i]
    else
      data.visible[i] = Val2dB(data.actual[i])
    end
  end
end

local function SortPresetsDisplay( sort_column_id, sort_direction )
  if sort_direction == ImGui.SortDirection_None or sort_column_id == 0 then
    table.sort(PresetsDisplay, function(a, b)
      return a.preset_idx < b.preset_idx
    end)
  else
    local sort_field = (sort_column_id == 1) and "name" or "comment"
    table.sort(PresetsDisplay, function(a, b)
      local val_a = a[sort_field]
      local val_b = b[sort_field]
      if sort_direction == ImGui.SortDirection_Ascending then
        return val_a < val_b
      else
        return val_a > val_b
      end
    end)
  end
end

local function RebuildPresetsDisplay()
  PresetsDisplay = {}
  for i = 1, Presets_cnt do
    PresetsDisplay[i] = {
      preset_idx = i,  -- Reference back to the Presets table
      name = Presets[i].name,
      comment = Presets[i].comment
    }
  end
  SortPresetsDisplay( sort_column_id, sort_direction )
end

local function GetPresetsFromFile()
  if reaper.file_exists( presets_file ) then
    local file = io.open(presets_file)
    local contents = file:read("*all")
    file:close()
    for line in contents:gmatch("[^\n\r]+") do
      local _, en, name, comment = line:find("^(.+)$$(.*)>> ")
      if en then
        local t = {true, true, true, true, true, true, true, true, true, name = name, comment = comment }
        local c = 0
        local rest = line:sub(en+1)
        for val in rest:gmatch("%S+") do
          c = c + 1
          t[c] = tonumber( val )
          if c == 9 then
            Presets_cnt = Presets_cnt + 1
            Presets[Presets_cnt] = t
          end
        end
      end
    end
  else 
    local file = io.open(presets_file, "w")
    file:close()
  end
  RebuildPresetsDisplay()
end

local function WritePresetsToFile()
  local file = io.open(presets_file, "w")
  local t = {}
  for i = 1, Presets_cnt do
    local preset = Presets[i]
    t[i] = format("%s$$%s>> %s",preset.name, preset.comment, table.concat(preset, " "))
  end
  file:write(table.concat(t, "\n"))
  file:close()
end

local function LoadPreset( preset_idx )
  for i = 1, 9 do
    data.actual[i] = Presets[preset_idx][i]
    reaper.SNM_SetDoubleConfigVar(data.ini_name[i], data.actual[i])
  end
  UpdateValues()
  selected_preset = preset_idx
end

local function SavePreset( name, comment )
  local t, t2 = {}, {}
  for i = 1, 9 do
    t[i] = data.actual[i]
  end
  t.name, t.comment = name, comment
  Presets_cnt = Presets_cnt + 1
  Presets[Presets_cnt] = t
  WritePresetsToFile()
  RebuildPresetsDisplay()
  selected_preset = Presets_cnt
end

local function OverwritePreset( preset_idx )
  if selected_preset == 0 then
    save_as = true
  else
    for i = 1, 9 do
      Presets[preset_idx][i] = data.actual[i]
    end
    WritePresetsToFile()
  end
end

local function DeletePreset( preset_idx )
  if preset_idx == selected_preset then
    selected_preset = 0
  elseif preset_idx < selected_preset then
    selected_preset = selected_preset - 1
  end
  Presets_cnt = Presets_cnt - 1
  table.remove(Presets, preset_idx)
  WritePresetsToFile()
  RebuildPresetsDisplay()
end

------------------------------------------------------------------------------
-- ReaImgui

local window_title = "amagalma's Spectral Edits Preset Tool  -  v" .. script_version .. "###Title"
local presets_header_open_flag = GetExt( "p_" ) == "0" and 0 or ImGui.TreeNodeFlags_DefaultOpen
local settings_header_open_flag = GetExt( "s_" ) == "0" and 0 or ImGui.TreeNodeFlags_DefaultOpen
local settings_header, presets_header
local ctx = ImGui.CreateContext(Script_Name)

-- Flags
local autoresize = ImGui.WindowFlags_AlwaysAutoResize
local window_flags = ImGui.WindowFlags_NoDocking | ImGui.WindowFlags_NoResize | ImGui.WindowFlags_NoCollapse
local clamp_slider = ImGui.SliderFlags_AlwaysClamp
local logar = ImGui.SliderFlags_Logarithmic | clamp_slider
local allow_overlap = ImGui.TreeNodeFlags_AllowOverlap
local table_flags = ImGui.TableFlags_Resizable | ImGui.TableFlags_Sortable |
      ImGui.TableFlags_RowBg | ImGui.TableFlags_SortTristate | ImGui.TableFlags_ScrollX |
      ImGui.TableFlags_BordersOuter | ImGui.TableFlags_BordersV | ImGui.TableFlags_ScrollY
local preset_nr_flags = ImGui.TableColumnFlags_NoResize | ImGui.TableColumnFlags_NoSort
local stretch_width_flag = ImGui.TableColumnFlags_WidthStretch
local span_all_columns_flag = ImGui.SelectableFlags_SpanAllColumns
local auto_select_all_flag = ImGui.InputTextFlags_AutoSelectAll
local Alt_key = ImGui.Mod_Alt
local Right_MB = ImGui.MouseButton_Right
local left_MB = ImGui.MouseButton_Left
local clipper = ImGui.CreateListClipper(ctx)
ImGui.Attach(ctx, clipper)

local drag_vel = 0.31
local drag_vel_slow = 0.05
local reset_btn = { name = " Reset to Default Values " }
local refresh_btn = { name = "  Refresh Values  " }
local saveas_btn = { name = "   Save as   " }
local save_btn = { name = " Save/overwrite " }
local delete_btn = { name = " Delete preset " }
local save_name, save_comment, focus, close_popup, isNameHovered, rename_row, rename_what, txt, confirm_delete
local keys = {"name", "comment"}
local mousewheel_v
local sort_column_id, sort_direction = 0, 0

-- Measurements according to font
local font = ImGui.CreateFont("sans-serif", isMac and floor(font_sz * 0.8) or font_sz)
ImGui.Attach(ctx, font)
ImGui.PushFont(ctx, font, font_sz)
local longest_name = ImGui.CalcTextSize(ctx, "Compression Threshold")
local width = floor(longest_name * 2.8 + 0.5)
local border_sz = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
local slider_w = -longest_name - border_sz
local num_PresetsToDisplay = ImGui.GetTextLineHeightWithSpacing( ctx ) * 9
refresh_btn.w = ImGui.CalcTextSize(ctx, refresh_btn.name) + 8
saveas_btn.w = ImGui.CalcTextSize(ctx, saveas_btn.name) + 8
save_btn.w = ImGui.CalcTextSize(ctx, save_btn.name) + 8
delete_btn.w = ImGui.CalcTextSize(ctx, delete_btn.name) + 8
local space2 = floor( ( width - (saveas_btn.w + save_btn.w + delete_btn.w) - border_sz*2 ) / 4 )
save_btn.pos = space2 + border_sz
delete_btn.pos = width - border_sz - space2 - delete_btn.w
saveas_btn.pos = save_btn.pos + save_btn.w + space2
local buttons_w = floor( width * 0.28 )
ImGui.PopFont(ctx)

------------------------------------------------------------------------------
-- ReaImgui Functions


local function ApplyMousewheel( var, min, max, rv )
  if mousewheel_v ~= 0 and ImGui.IsItemHovered( ctx ) then
    var = var + mousewheel_v
    if var < min then var = min
      elseif var > max then var = max
    end
    rv = true
  end
  return var, rv
end

local function CheckResetToDefault(idx)
  if ImGui.IsItemHovered(ctx) then
    if (ImGui.IsMouseClicked(ctx, Right_MB)) or
       (ImGui.IsMouseClicked(ctx, left_MB) and ImGui.GetKeyMods(ctx) & Alt_key ~= 0) then
      data.actual[idx] = default_actual[idx]
      data.visible[idx] = default_visible[idx]
      reaper.SNM_SetDoubleConfigVar(data.ini_name[idx], data.actual[idx])
      return true
    end
  end
  return false
end

local function Enter()
  return ImGui.IsKeyDown(ctx, ImGui.Key_Enter)
end

local function Esc()
  return ImGui.IsKeyDown(ctx, ImGui.Key_Escape)
end

------------------------------------------------------------------------------

local function loop()
  ImGui.PushFont(ctx, font, font_sz)
  ImGui.SetNextWindowSize(ctx, width, 0)

  local visible, open = ImGui.Begin(ctx, window_title, true, window_flags)

  if visible then
    local rv
    settings_header = ImGui.CollapsingHeader(ctx, 'Current Settings', nil, settings_header_open_flag | allow_overlap )


    if settings_header then
      mousewheel_v = ImGui.GetMouseWheel(ctx)
      ImGui.PushItemWidth( ctx , slider_w )

      rv, data.visible[1] = ImGui.DragInt(ctx, 'Fade In', data.visible[1], drag_vel, 0, 100, '%d%%', clamp_slider)
      data.visible[1], rv = ApplyMousewheel( data.visible[1], 0, 100, rv)
      if rv or CheckResetToDefault(1) then
        data.actual[1] = Perc2Val(data.visible[1])
        reaper.SNM_SetDoubleConfigVar( "specedit_fadein", data.actual[1] )
      end

      rv, data.visible[2] = ImGui.DragInt(ctx, 'Fade Out', data.visible[2], drag_vel, 0, 100, '%d%%', clamp_slider)
      data.visible[2], rv = ApplyMousewheel( data.visible[2], 0, 100, rv)
      if rv or CheckResetToDefault(2) then
        data.actual[2] = Perc2Val(data.visible[2])
        reaper.SNM_SetDoubleConfigVar( "specedit_fadeout", data.actual[2] )
      end

      rv, data.visible[3] = ImGui.DragInt(ctx, 'Low Frequency Fade', data.visible[3], drag_vel, 0, 100, '%d%%', clamp_slider)
      data.visible[3], rv = ApplyMousewheel( data.visible[3], 0, 100, rv)
      if rv or CheckResetToDefault(3) then
        data.actual[3] = Perc2Val(data.visible[3])
        reaper.SNM_SetDoubleConfigVar( "specedit_fadelow", data.actual[3] )
      end

      rv, data.visible[4] = ImGui.DragInt(ctx, 'High Frequency Fade', data.visible[4], drag_vel, 0, 100, '%d%%', clamp_slider)
      data.visible[4], rv = ApplyMousewheel( data.visible[4], 0, 100, rv)
      if rv or CheckResetToDefault(4) then
        data.actual[4] = Perc2Val(data.visible[4])
        reaper.SNM_SetDoubleConfigVar( "specedit_fadehi", data.actual[4] )
      end

      ImGui.Separator(ctx)
      rv, data.visible[5] = ImGui.DragDouble(ctx, 'Gain', data.visible[5], drag_vel_slow, -224, 100, "%.2f dB", clamp_slider)
      data.visible[5], rv = ApplyMousewheel( data.visible[5], -224, 100, rv)
      if rv or CheckResetToDefault(5) then
        data.actual[5] = dB2Val(data.visible[5])
        reaper.SNM_SetDoubleConfigVar( "specedit_gain", data.actual[5] )
      end

      rv, data.visible[6] = ImGui.DragDouble(ctx, 'Compression Threshold', data.visible[6], drag_vel_slow, -224, 100, "%.2f dB", clamp_slider)
      data.visible[6], rv = ApplyMousewheel( data.visible[6], -224, 100, rv)
      if rv or CheckResetToDefault(6) then
        data.actual[6] = dB2Val(data.visible[6])
        reaper.SNM_SetDoubleConfigVar( "specedit_compthresh", data.actual[6] )
      end

      rv, data.visible[7] = ImGui.DragDouble(ctx, 'Compression Ratio', data.visible[7], drag_vel_slow, 0.1, 100, data.visible[7]<1 and
      format("1 : %.1f",1/data.visible[7]) or format("%.1f : 1",data.visible[7]), logar)
      if mousewheel_v ~= 0 and ImGui.IsItemHovered( ctx ) then
        data.visible[7] = data.visible[7] * (mousewheel_v > 0 and 1.1 or 0.9)
        if data.visible[7] < 0.1 then data.visible[7] = 0.1
          elseif data.visible[7] > 100 then data.visible[7] = 100
        end
        rv = true
      end
      if rv or CheckResetToDefault(7) then
        data.actual[7] = data.visible[7]
        reaper.SNM_SetDoubleConfigVar( "specedit_compratio", data.actual[7] )
      end

      ImGui.Separator(ctx)

      rv, data.visible[8] = ImGui.DragDouble(ctx, 'Gate Threshold', data.visible[8], drag_vel_slow, -224, 100, "%.2f dB", clamp_slider)
      data.visible[8], rv = ApplyMousewheel( data.visible[8], -224, 100, rv)
      if rv or CheckResetToDefault(8) then
        data.actual[8] = dB2Val(data.visible[8])
        reaper.SNM_SetDoubleConfigVar( "specedit_gatethresh", data.actual[8] )
      end

      rv, data.visible[9] = ImGui.DragDouble(ctx, 'Gate Floor', data.visible[9], drag_vel_slow, -224, 100, "%.2f dB", clamp_slider)
      data.visible[9], rv = ApplyMousewheel( data.visible[9], -224, 100, rv)
      if rv or CheckResetToDefault(9) then
        data.actual[9] = dB2Val(data.visible[9])
        reaper.SNM_SetDoubleConfigVar( "specedit_gatefloor", data.actual[9] )
      end

      ImGui.PopItemWidth( ctx )
      ImGui.Spacing(ctx) ; ImGui.Spacing(ctx)

      rv = ImGui.Button(ctx, reset_btn.name)
      if rv then
        for i = 1, 9 do
          data.actual[i] = default_actual[i]
          data.visible[i] = default_visible[i]
          reaper.SNM_SetDoubleConfigVar(data.ini_name[i], data.actual[i])
        end
        selected_preset = 0
      end

      ImGui.SameLine(ctx )
      rv = ImGui.Button(ctx, refresh_btn.name)
      if rv then
        GetCurrentSettings()
        UpdateValues()
      end

      ImGui.Spacing(ctx) ; ImGui.Spacing(ctx)
      ImGui.Separator(ctx) ; ImGui.Separator(ctx)
      ImGui.Spacing(ctx) ; ImGui.Spacing(ctx)
    end

    ----------------------------------------------------------------------------------------
    presets_header = ImGui.CollapsingHeader(ctx, 'Presets', nil, presets_header_open_flag)

    if presets_header then
      ImGui.SetNextItemWidth(ctx, width-14)
      if ImGui.BeginTable(ctx, 'Presets table', 3, table_flags, nil, num_PresetsToDisplay) then 
        ImGui.TableSetupColumn(ctx, 'ID', preset_nr_flags, 0, 0)
        ImGui.TableSetupColumn(ctx, 'Name', stretch_width_flag, 0, 1)
        ImGui.TableSetupColumn(ctx, 'Comment', stretch_width_flag, 0, 2)
        ImGui.TableHeadersRow(ctx)

        _, sort_column_id, _, sort_direction = ImGui.TableGetColumnSortSpecs( ctx, 0 )


        if ImGui.TableNeedSort( ctx ) then
          SortPresetsDisplay( sort_column_id, sort_direction )
        end

        ImGui.ListClipper_Begin( clipper, #PresetsDisplay)
        while ImGui.ListClipper_Step( clipper ) do
          local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
          for row_n = display_start+1, display_end do
            local display_item = PresetsDisplay[row_n]
            local preset_idx = display_item.preset_idx
            local current_selection = selected_preset == preset_idx

            ImGui.TableNextRow(ctx)
            ImGui.TableSetColumnIndex(ctx, 0)
            if ImGui.Selectable(ctx, preset_idx, current_selection, span_all_columns_flag | ImGui.SelectableFlags_AllowDoubleClick) then
              if ImGui.GetKeyMods(ctx) & Alt_key ~= 0 then
                confirm_delete = preset_idx
              elseif ImGui.IsMouseDoubleClicked(ctx, left_MB) then
                rename = true
                rename_row = preset_idx
              else
                selected_preset = preset_idx
                LoadPreset( selected_preset )
              end
            end
            ImGui.TableNextColumn( ctx )
            ImGui.Text( ctx, display_item.name )
            ImGui.TableNextColumn( ctx )
            ImGui.Text( ctx, display_item.comment )
            isNameHovered = ImGui.TableGetHoveredColumn(ctx) == 1
          end
        end
        ImGui.EndTable( ctx )
      end

      if confirm_delete then
        ImGui.OpenPopup(ctx, '###ConfirmDelete')
      end

      ImGui.Spacing(ctx) ; ImGui.Spacing(ctx)

      ImGui.SetCursorPosX(ctx, save_btn.pos )
      rv = ImGui.Button(ctx, save_btn.name)
      if rv then
        OverwritePreset( selected_preset )
      end

      ImGui.SameLine(ctx)

      ImGui.SetCursorPosX(ctx, saveas_btn.pos )
      rv = ImGui.Button(ctx, saveas_btn.name)
      if rv then
        save_as = true
      end

      ImGui.SameLine(ctx)

      ImGui.SetCursorPosX(ctx, delete_btn.pos )
      rv = ImGui.Button(ctx, delete_btn.name)
      if rv then
        if selected_preset ~= 0 then
          confirm_delete = selected_preset
        end
      end

      ImGui.Spacing(ctx)
    end

    if save_as then
      ImGui.OpenPopup(ctx, 'Save As')
      save_as = nil
      if selected_preset ~= 0 then
        save_name = Presets[selected_preset].name
        save_comment = Presets[selected_preset].comment
      end
      focus = true
    elseif rename then
        ImGui.OpenPopup(ctx, '###Rename')
        rename_what = (isNameHovered and "name" or "comment")
        txt = Presets[rename_row][rename_what]
        rename = nil
        focus = true
    end

    -- Confirm Delete Popup
    if ImGui.BeginPopupModal(ctx, 'Confirm Delete###ConfirmDelete', nil, autoresize) then
      ImGui.Text(ctx, "Are you sure you want to delete this preset?")
      ImGui.Spacing(ctx)
      if confirm_delete and Presets[confirm_delete] then
        ImGui.Text(ctx, "Name: " .. Presets[confirm_delete].name)
      end
      ImGui.Spacing(ctx)
      ImGui.Separator(ctx)
      ImGui.Spacing(ctx)

      if ImGui.Button(ctx, 'Yes', buttons_w, 0) or Enter() then
        DeletePreset(confirm_delete)
        confirm_delete = nil
        ImGui.CloseCurrentPopup(ctx)
      end
      ImGui.SetItemDefaultFocus(ctx)
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Cancel', buttons_w, 0) or Esc() then
        confirm_delete = nil
        ImGui.CloseCurrentPopup(ctx)
      end
      ImGui.EndPopup(ctx)
    end

    if ImGui.BeginPopupModal(ctx, 'Save As', nil, autoresize) then
      if focus then
        ImGui.SetKeyboardFocusHere(ctx)
        focus = nil
      end
      rv, save_name = ImGui.InputText(ctx, "Name", save_name, auto_select_all_flag)
      rv, save_comment = ImGui.InputText(ctx, "Comment", save_comment)
      ImGui.Spacing( ctx )
      ImGui.Separator(ctx)
      ImGui.Spacing( ctx )
      if ImGui.Button(ctx, 'Save', buttons_w, 0) or Enter() then
        if save_name and save_name ~= "" then
          save_name = save_name:match("%s*(.-)%s*$")
          SavePreset( save_name, save_comment )
          close_popup = true
        else
          focus = true
        end
      end
      ImGui.SetItemDefaultFocus(ctx)
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Cancel', buttons_w, 0) or close_popup or Esc() then
        save_name, save_comment, close_popup = nil, nil, nil
        ImGui.CloseCurrentPopup(ctx)
      end
      ImGui.EndPopup(ctx)
    end

    local popupmodalname = (rename_what == "name" and "Enter New Name :###Rename" or "Rename Comment###Rename")

    if ImGui.BeginPopupModal(ctx, popupmodalname, nil, autoresize) then
      if focus then
        local x, y = reaper.GetMousePosition()
        ImGui.SetWindowPosEx(ctx, popupmodalname, x-90, y-80 )
        ImGui.SetKeyboardFocusHere(ctx)
        focus = nil
      end
      rv, txt = ImGui.InputText(ctx, "##", txt, auto_select_all_flag)
      ImGui.Spacing( ctx )
      ImGui.Separator(ctx)
      ImGui.Spacing( ctx )
      if ImGui.Button(ctx, 'OK', buttons_w, 0) or Enter() then
        if rename_what then
          if txt and txt ~= "" then
            txt = txt:match("%s*(.-)%s*$")
            Presets[rename_row][rename_what] = txt
            txt, rename_row = nil, nil
            close_popup = true
            WritePresetsToFile()
            RebuildPresetsDisplay()
          else
            focus = true
          end
          rename_what = nil
        end
      end
      ImGui.SetItemDefaultFocus(ctx)
      ImGui.SameLine(ctx)
      if ImGui.Button(ctx, 'Cancel', buttons_w, 0) or close_popup or Esc() then
        rename_row, txt, close_popup = nil, nil, nil
        ImGui.CloseCurrentPopup(ctx)
      end
      ImGui.EndPopup(ctx)
    end

    ImGui.End(ctx)
  end

  ImGui.PopFont(ctx)

  if open then
    reaper.defer(loop)
  end
end

------------------------------------------------------------------------------

reaper.atexit(function()
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  SetExt( "p_", presets_header == false and "0" or "1" )
  SetExt( "s_", settings_header == false and "0" or "1" )
  return
end)

------------------------------------------------------------------------------
-- Initialize and run

GetCurrentSettings()
UpdateValues()
GetPresetsFromFile()
loop()

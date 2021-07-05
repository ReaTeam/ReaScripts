-- @description Track name groups
-- @author Rodilab
-- @version 1.10
-- @changelog
--   - Drag and drop name buttons to move tracks
--   - New "Insert new track" on right click menu
--   - New "Clear all" on right click menu
--   - New text input no-popup widget when add or edit names
--   - Displays the default track color of the Reaper theme
-- @link Forum thread https://forum.cockos.com/showthread.php?t=255223
-- @donation Donate via PayPal https://www.paypal.com/donate?hosted_button_id=N5DUAELFWX4DC
-- @about
--   This track utility allows to select, show/hide, mute or solo a group of tracks by track name.
--   All tracks whose name starts with the entered name, and its children, are recognized by the script.
--   The name list are saved in each project.
--
--   - Click on buttons to [B]exclusive[/B] select, show/hide, mute or solo
--   - [Any-modifier + left-click] to keep and add selection, show/hide, mute or solo
--   - [Right-click] on name buttons to edit, insert new track, remove or clear all
--   - Click on bottom crosses to show / unmute / unsolo all tracks
--   - Drag and drop name buttons to move tracks
--   - Buttons are automatically reordered according to the order of the tracks in the session
--   - Buttons take the color of first track found

r = reaper
script_name = 'Track name groups'

function TestVersion(version,version_min)
  local i = 0
  for num in string.gmatch(tostring(version),'%d+') do
    i = i + 1
    if version_min[i] and tonumber(num) > version_min[i] then
      return true
    elseif version_min[i] and tonumber(num) < version_min[i] then
      return false
    end
  end
  if i < #version_min then return false
  else return true end
end

-- Extensions check
if r.APIExists('ImGui_CreateContext') == true then
  if TestVersion(({r.ImGui_GetVersion()})[2],{0,5,1}) then

FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()

---------------------------------------------------------------------------------
--- ExtState --------------------------------------------------------------------
---------------------------------------------------------------------------------

r.atexit(function()
  ExtState_Save()
end)

extstate_id = 'RODILAB_Track_name_groups'
group_list = {}
conf = {}

function ExtState_Load()
  def = {
    dock = -3,
    mousepos = false,
    background = true
  }
  for key in pairs(def) do
    if r.HasExtState(extstate_id,key) then
      local state = r.GetExtState(extstate_id, key)
      if state == "true" then state = true
      elseif state == "false" then state = false end
      conf[key] = tonumber(state) or state
    else
      conf[key] = def[key]
    end
  end
  conf.dock = math.min(conf.dock, -1)

  local rv, string = r.GetProjExtState(0, extstate_id, 'group_list')
  local i = 0
  for name in string.gmatch(string, '[^;]+') do
    i = i+1
    table.insert(group_list, name)
  end
end

function ExtState_Save()
  for key in pairs(conf) do
    r.SetExtState(extstate_id, key, tostring(conf[key]), true)
  end

  local string = ''
  for i, name in ipairs(group_list) do
    if i > 1 then string = string..';' end
    string = string..name
  end
  r.SetProjExtState(0, extstate_id, 'group_list', string)
end

---------------------------------------------------------------------------------
--- Actions ---------------------------------------------------------------------
---------------------------------------------------------------------------------

function AddNewGroup(name)
  if #name > 0 then
    table.insert(group_list, name)
  end
end

function SelectGroup(name)
  r.PreventUIRefresh(1)
  if mods == 0 then
    r.Main_OnCommand(40297,0) -- Unselect all tracks
  end
  for i, track in ipairs(list_tracks[name]) do
    r.SetTrackSelected(track, true)
  end
  r.SetCursorContext(0, nil)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function VisibleGroup(i, name, bool)
  r.PreventUIRefresh(1)
  local all_visible = true
  for i, visible in ipairs(list_visible) do
    if not visible then
      all_visible = false
      break
    end
  end

  if mods == 0 then
    if all_visible then bool = not bool end
    local count = r.CountTracks(0)
    for i=0, count-1 do
      local track = r.GetTrack(0, i)
      r.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 0)
    end
  end
  for i, track in ipairs(list_tracks[name]) do
    r.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', bool and 1 or 0)
  end

  r.TrackList_AdjustWindows(false)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function MuteGroup(name, bool)
  r.PreventUIRefresh(1)
  if mods == 0 then
    r.Main_OnCommand(40339,0) -- Unmute all tracks
  end
  for i, track in ipairs(list_tracks[name]) do
    r.SetMediaTrackInfo_Value(track, 'B_MUTE', bool and 1 or 0)
  end
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function SoloGroup(name, bool)
  r.PreventUIRefresh(1)
  if mods == 0 then
    r.Main_OnCommand(40340,0) -- Unsolo all tracks
  end
  for i, track in ipairs(list_tracks[name]) do
    r.SetMediaTrackInfo_Value(track, 'I_SOLO', bool and 1 or 0)
  end
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function IsInTheList(parent_track)
  for name, list in pairs(list_tracks) do
    for i, track in ipairs(list) do
      if track == parent_track then
        return true, name
      end
    end
  end
  return false
end

function IncPrefix(trackname)
  for i=0, #trackname-1 do
    local pos = #trackname-i
    local num = tonumber(string.sub(trackname, #trackname-i, #trackname-i))
    if not num and i > 0 then
      local prefix = string.sub(trackname, pos+1)
      local new_prefix = tonumber(prefix)
      if new_prefix then
        new_prefix = tostring(tonumber(prefix) + 1)
        for i=1, math.max(0, #prefix - #new_prefix) do
          new_prefix = '0'..new_prefix
        end
        return string.sub(trackname,1,pos)..new_prefix
      end
    end
  end
  return trackname
end

function InsertNewTrack(i)
  r.PreventUIRefresh(1)
  local name = group_list[i]
  local count = r.CountTracks(0)
  if count > 0 then
    for i = 0, count-1 do
      i = count-1-i
      local track = r.GetTrack(0, i)
      local rv, trackname = r.GetTrackName(track)
      if rv and string.sub(trackname, 0, #name) == name then
        r.InsertTrackAtIndex(i+1, true)
        local new_track = r.GetTrack(0, i+1)
        r.GetSetMediaTrackInfo_String(new_track, 'P_NAME', IncPrefix(trackname), true)
        r.SetMediaTrackInfo_Value(new_track, 'I_CUSTOMCOLOR', r.GetMediaTrackInfo_Value(track, 'I_CUSTOMCOLOR'))
        if r.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH') == -1 then
          r.SetMediaTrackInfo_Value(new_track, 'I_FOLDERDEPTH', -1)
          r.SetMediaTrackInfo_Value(track,     'I_FOLDERDEPTH', 0 )
        end
        break
      end
    end
  end
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function MoveTracks(o_source, o_target)
  o_source = tonumber(o_source)
  o_target = tonumber(o_target)
  if o_source < o_target then
    o_target = o_target + 1
  end
  local source = group_list_order[o_source]
  local target = group_list_order[o_target]
  local source_name = group_list[source]
  local target_name = group_list[target]
  local new_id, after
  local count = r.CountTracks(0)
  if not group_list_exist[target_name] then
    after = true
    target = group_list_order[o_target - 1]
    target_name = group_list[target]
  end
  if count > 0 and target_name then
    for i = 0, count-1 do
      if after then i = count - 1 - i end
      local track = r.GetTrack(0, i)
      local rv, trackname = r.GetTrackName(track)
      if rv and string.sub(trackname, 1, #target_name) == target_name then
        new_id = i
        if after then new_id = new_id + 1 end
        break
      end
    end
  end
  if type(new_id) == 'number' then
    r.PreventUIRefresh(1)
    r.Main_OnCommand(40297,0) -- Unselect all tracks
    for i, track in ipairs(list_tracks[source_name]) do
      r.SetTrackSelected(track, true)
    end
    r.ReorderSelectedTracks(new_id, 0)
    r.PreventUIRefresh(-1)
    r.UpdateArrange()
  end
end

---------------------------------------------------------------------------------
--- ImGui -----------------------------------------------------------------------
---------------------------------------------------------------------------------

function StartContext()
  ctx = r.ImGui_CreateContext(script_name, r.ImGui_ConfigFlags_DockingEnable())
  font = r.ImGui_CreateFont('Arial',12)
  r.ImGui_AttachFont(ctx,font)
  if conf.mousepos then
    cur_x, cur_y = r.GetMousePosition()
    cur_x, cur_y = r.ImGui_PointConvertNative(ctx, cur_x, cur_y, false)
  end
end

function DrawCheckButton(ctx, label, size, color, active)
  local pos = {r.ImGui_GetCursorScreenPos(ctx)}
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
  r.ImGui_InvisibleButton(ctx, label, size, size)
  if r.ImGui_IsItemHovered(ctx) and not r.ImGui_IsItemActive(ctx) then
    color = color - 100
  end
  local radius = math.floor(size/2)
  local radius_1 = math.floor(radius*0.8)
  local radius_2 = math.floor(radius_1*0.5)
  local center = {pos[1]+radius, pos[2]+radius}
  r.ImGui_DrawList_AddCircle(draw_list, center[1], center[2], radius_1, color, 20, 1)
  if active then
    r.ImGui_DrawList_AddCircleFilled(draw_list, center[1], center[2], radius_2, color, 20)
  end
  return r.ImGui_IsItemActivated(ctx)
end

function DrawCrossButton(ctx, label, size, color)
  local pos = {r.ImGui_GetCursorScreenPos(ctx)}
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
  r.ImGui_InvisibleButton(ctx, label, size, size)
  if r.ImGui_IsItemHovered(ctx) and not r.ImGui_IsItemActive(ctx) then
    color = color - 100
  end
  local cross_size = math.floor((size/2)-5)
  local center = {pos[1]+size/2 , pos[2]+size/2}
  local x1 = center[1] - cross_size
  local x2 = center[1] + cross_size
  local y1 = center[2] - cross_size
  local y2 = center[2] + cross_size
  r.ImGui_DrawList_AddLine(draw_list, x1, y1, x2, y2, color, 2)
  r.ImGui_DrawList_AddLine(draw_list, x1, y2, x2, y1, color, 2)
  return r.ImGui_IsItemActivated(ctx)
end

function DrawGear(ctx, label, size, color, color_hov)
  local pos = {r.ImGui_GetCursorScreenPos(ctx)}
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
  r.ImGui_InvisibleButton(ctx, label, size, size)
  if r.ImGui_IsItemHovered(ctx) then
    color = color_hov
  end
  local center = {pos[1]+size/2 , pos[2]+size/2}
  size = size/2
  -- User values --
  local int_radius = size*0.5 -- Int circle radius
  local ext_radius = size*0.8 -- Ext circle radius
  local angle_1 = math.rad(15) -- Angle for the base width of teeth
  local angle_2 = math.rad(8) -- Angle for the width of teeth tip
  local teeth = 6 -- Number of teeth
  -----------------
  for i=0, teeth-1 do
    local angle = math.rad(i*(360/teeth))
    local p1_x = center[1] + math.sin(angle+angle_1) * ext_radius
    local p1_y = center[2] + math.cos(angle+angle_1) * ext_radius
    local p2_x = center[1] + math.sin(angle-angle_1) * ext_radius
    local p2_y = center[2] + math.cos(angle-angle_1) * ext_radius
    local p3_x = center[1] + math.sin(angle-angle_2) * size
    local p3_y = center[2] + math.cos(angle-angle_2) * size
    local p4_x = center[1] + math.sin(angle+angle_2) * size
    local p4_y = center[2] + math.cos(angle+angle_2) * size
    r.ImGui_DrawList_AddQuadFilled(draw_list, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y, p4_x, p4_y, color)
  end
  r.ImGui_DrawList_AddCircle(draw_list, center[1], center[2], (int_radius+ext_radius)/2, color, 0, ext_radius-int_radius+1)
  return r.ImGui_IsItemActivated(ctx)
end

function DrawDock(ctx, label, heigth, color, color_hov)
  local pos = {r.ImGui_GetCursorScreenPos(ctx)}
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
  local width = math.floor(heigth*1.3)
  r.ImGui_InvisibleButton(ctx, label, width, heigth)
  if r.ImGui_IsItemHovered(ctx) then
    color = color_hov
  end
  r.ImGui_DrawList_AddRect      (draw_list, pos[1], pos[2], pos[1]+width, pos[2]+heigth, color)
  r.ImGui_DrawList_AddRectFilled(draw_list, pos[1], pos[2], pos[1]+5    , pos[2]+heigth, color)
  return r.ImGui_IsItemActivated(ctx)
end

function TextURL(ctx,text,url)
  local pos = {r.ImGui_GetCursorScreenPos(ctx)}
  local text_size = {r.ImGui_CalcTextSize(ctx,text,0,0)}
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
  if r.ImGui_InvisibleButton(ctx, text, text_size[1], r.ImGui_GetTextLineHeightWithSpacing(ctx) ) then
    r.CF_ShellExecute(url)
  end
  local color = 0x99C5FFff
  if r.ImGui_IsItemHovered(ctx) then color = 0xffffffff end
  r.ImGui_DrawList_AddText(draw_list, pos[1], pos[2], color, text )
  pos[2] = pos[2] + r.ImGui_GetTextLineHeight(ctx)
  r.ImGui_DrawList_AddLine(draw_list, pos[1], pos[2], pos[1]+text_size[1], pos[2], color, 1)
end

---------------------------------------------------------------------------------
--- Body ------------------------------------------------------------------------
---------------------------------------------------------------------------------

function ImGuiBody()
  local rv
  local WindowSize = {r.ImGui_GetWindowSize(ctx)}
  mods = r.ImGui_GetKeyMods( ctx )
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameRounding(), 4.0)

  ----------------------------------------------------------------
  -- Popups
  ----------------------------------------------------------------

  if not r.ImGui_IsPopupOpen( ctx, 'Menu Name') then
    name_focused = nil
  end

  if r.ImGui_BeginPopup(ctx, 'Menu Name', r.ImGui_WindowFlags_NoMove() | r.ImGui_WindowFlags_NoResize()) then
    if r.ImGui_Selectable(ctx,'Edit') then
      edit = name_focused
    end
    if group_list_exist[group_list[name_focused]] then
      if r.ImGui_Selectable(ctx,'Insert new track') then
        InsertNewTrack(name_focused)
      end
    end
    if r.ImGui_Selectable(ctx,'Remove') then
      table.remove(group_list,name_focused)
    end
    if r.ImGui_Selectable(ctx,'Clear all') then
      group_list = {}
    end
    r.ImGui_EndPopup(ctx)
  end

  if r.ImGui_BeginPopup(ctx, 'Settings') then
    rv, conf.mousepos =   r.ImGui_Checkbox(ctx, 'Open on mouse position', conf.mousepos)
    rv, conf.background = r.ImGui_Checkbox(ctx, 'Use Reaper theme background color', conf.background)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 0, 4)
    TextURL(ctx, 'Discuss in REAPER forum thread', 'https://forum.cockos.com/showthread.php?t=255223')
    TextURL(ctx, 'Support with a Paypal donation', 'https://www.paypal.com/donate?hosted_button_id=N5DUAELFWX4DC')
    r.ImGui_PopStyleVar(ctx)
    r.ImGui_EndPopup(ctx)
  end

  ----------------------------------------------------------------
  -- Main button
  ----------------------------------------------------------------
  group_list_order = {}
  group_list_exist = {}
  list_tracks = {}
  list_visible = {}
  list_mute = {}
  list_solo = {}
  list_color = {}
  for i, name in ipairs(group_list) do
    list_tracks[name] = {}
  end
  local count = r.CountTracks(0)
  local all_visible = true
  for t=0, count-1 do
    local track = r.GetTrack(0, t)
    local SHOWINTCP = r.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP')
    if all_visible and SHOWINTCP == 0 then
      all_visible = false
    end
    local rv, trackname = r.GetTrackName(track)
    if rv then
      local parent = r.GetParentTrack(track)
      local has_parent, parent_i, parent_name
      if parent then
        has_parent, parent_name = IsInTheList(parent)
      end
      for i, name in ipairs(group_list) do
        if (has_parent and parent_name == name) or string.sub(trackname, 0, #name) == name then
          table.insert(list_tracks[name], track)
          if not group_list_exist[name] then
            table.insert(group_list_order, i)
          end
          group_list_exist[name] = true
          if type(list_visible[i]) == 'nil' or (type(list_visible[i]) == 'boolean' and list_visible[i] == true) then
            local state = SHOWINTCP
            if state == 0 then state = false else state = true end
            list_visible[i] = state
          end
          if type(list_mute[i]) == 'nil' or (type(list_mute[i]) == 'boolean' and list_mute[i] == true) then
            local state = r.GetMediaTrackInfo_Value(track, 'B_MUTE')
            if state == 0 then state = false else state = true end
            list_mute[i] = state
          end
          if type(list_solo[i]) == 'nil' or (type(list_solo[i]) == 'boolean' and list_solo[i] == true) then
            local state = r.GetMediaTrackInfo_Value(track, 'I_SOLO')
            if state == 0 then state = false else state = true end
            list_solo[i] = state
          end
          if not list_color[i] then
            list_color[i] = r.ImGui_ColorConvertNative(r.GetTrackColor(track)& 0xffffff)
          end
        end
      end
    end
  end

  for i, name in ipairs(group_list) do
    if not group_list_exist[name] then
      table.insert(group_list_order, i)
    end
  end

  local button_size = 18
  for i, name in ipairs(group_list) do
    local text_size = r.ImGui_CalcTextSize(ctx, name, 0, 0)
    button_size = math.max(button_size, text_size)
  end
  button_size = button_size + 16

  local color_visible = r.ImGui_ColorConvertHSVtoRGB(0,0,0.8,1)
  local color_mute =    r.ImGui_ColorConvertHSVtoRGB(0,0.6,0.8,1)
  local color_solo =    r.ImGui_ColorConvertHSVtoRGB(0.15,0.6,0.8,1)

  for j, i in ipairs(group_list_order) do
    local name = group_list[i]
    if list_color[i] then
      local color
      if list_color[i] == 0 then
        color = r.ImGui_ColorConvertNative(r.GetThemeColor('col_seltrack2', 0))
      else
        color = list_color[i]
      end
      color = color * 16^2 + 255
      color_button = color + 255
      color_button_hov = color + 190
      color_button_active = color_button
    else
      color_button =        0x454545ff
      color_button_hov =    0x525252ff
      color_button_active = 0x666666ff
    end
    if edit == i then
      r.ImGui_PushItemWidth(ctx, button_size)
      if not input_text then
        r.ImGui_SetKeyboardFocusHere(ctx)
        input_text = group_list[i]
      end
      rv, input_text = r.ImGui_InputTextWithHint(ctx, '##Edit'..i, 'name', input_text, r.ImGui_InputTextFlags_EnterReturnsTrue() | r.ImGui_InputTextFlags_AutoSelectAll())
      if rv then
        input_text = input_text:gsub(';','')
        if #input_text > 0 then
          group_list[i] = input_text
        end
        edit, input_text, first_frame = nil, nil, nil
      end
      if first_frame and not r.ImGui_IsItemFocused(ctx) then
        edit, input_text, first_frame = nil, nil, nil
      end
      if edit and input_text then first_frame = true end
      r.ImGui_PopItemWidth(ctx)
    else
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        color_button)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  color_button_active)
      r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), color_button_hov)
      if r.ImGui_Button(ctx, name, button_size) then
        SelectGroup(name)
      end
      r.ImGui_PopStyleColor(ctx, 3)
      if group_list_exist[name] then
        if r.ImGui_BeginDragDropSource(ctx) then
          r.ImGui_SetDragDropPayload(ctx, 'DnD_Group', j)
          r.ImGui_Text(ctx, name)
          r.ImGui_EndDragDropSource(ctx)
        end
        if r.ImGui_BeginDragDropTarget(ctx) then
          local rv, payload = r.ImGui_AcceptDragDropPayload(ctx, 'DnD_Group', '')
          if rv then
            MoveTracks(payload, j)
          end
          r.ImGui_EndDragDropTarget(ctx)
        end
      end
    end
    if r.ImGui_IsItemClicked(ctx, r.ImGui_MouseButton_Right()) then
      name_focused = i
      r.ImGui_OpenPopup(ctx,'Menu Name')
    end
    if group_list_exist[name] then
      r.ImGui_SameLine(ctx)
      if DrawCheckButton(ctx, 'V##'..name, 18, color_visible, list_visible[i]) then
        VisibleGroup(i, name, not list_visible[i])
      end
      r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 0, 4)
      r.ImGui_SameLine(ctx)
      if DrawCheckButton(ctx, 'M##'..name, 18, color_mute, list_mute[i]) then
        MuteGroup(name, not list_mute[i])
      end
      r.ImGui_SameLine(ctx)
      if DrawCheckButton(ctx, 'S##'..name, 18, color_solo, list_solo[i]) then
        SoloGroup(name, not list_solo[i])
      end
      r.ImGui_PopStyleVar(ctx)
    end
  end

  if edit == 0 then
    r.ImGui_PushItemWidth(ctx, button_size)
    if not  input_text then
      r.ImGui_SetKeyboardFocusHere(ctx)
      input_text = ''
    end
    rv, input_text = r.ImGui_InputTextWithHint(ctx, '##Add new', 'name', input_text,  r.ImGui_InputTextFlags_EnterReturnsTrue())
    if rv then
      input_text = input_text:gsub(';','')
      if #input_text > 0 then
        table.insert(group_list, input_text)
      end
      edit, input_text, first_frame = nil, nil, nil
    end
    if first_frame and not r.ImGui_IsItemFocused(ctx) then
      edit, input_text, first_frame = nil, nil, nil
    end
    if edit and input_text then first_frame = true end
    r.ImGui_PopItemWidth(ctx)
  else
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        0x454545ff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(), 0x525252ff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  0x666666ff)
    if r.ImGui_Button(ctx, '+', button_size) then
      edit = 0
    end
    r.ImGui_PopStyleColor(ctx, 3)
  end
  r.ImGui_SameLine(ctx)
  if DrawCrossButton(ctx, 'V##All', 18, color_visible) then
    local count = r.CountTracks(0)
    for i=0, count-1 do
      local track = r.GetTrack(0, i)
      r.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', 1)
    end
    r.TrackList_AdjustWindows(false)
  end
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 0, 4)
  r.ImGui_SameLine(ctx)
  if DrawCrossButton(ctx, 'M##All', 18, color_mute) then
    r.Main_OnCommand(40339,0)
  end
  r.ImGui_SameLine(ctx)
  if DrawCrossButton(ctx, 'S##All', 18, color_solo) then
    r.Main_OnCommand(40340,0)
  end

  r.ImGui_PopStyleVar(ctx)
  r.ImGui_PopStyleVar(ctx)

  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(), 10, 10)
  r.ImGui_Spacing(ctx)
  r.ImGui_Separator(ctx)
  if DrawGear(ctx, '##Settings', 14, 0xaaaaaaff, 0xffffffff) then
    r.ImGui_OpenPopup(ctx, 'Settings')
  end

  r.ImGui_SameLine(ctx)
  if DrawDock(ctx, '##Dock', 14, 0xaaaaaaff, 0xffffffff) then
    dock = dockID
  end
  r.ImGui_PopStyleVar(ctx)
end

function loop()

  r.ImGui_PushFont(ctx, font)
  background_color = conf.background and r.ImGui_ColorConvertNative(r.GetThemeColor('col_main_bg2',0)) * 16^2 + 255 or 0x333333ff
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(), background_color)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ChildBg()  , background_color)
  r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowTitleAlign(), 0.5, 0.5)

  r.ImGui_SetNextWindowSizeConstraints(ctx, 100, 50, FLT_MAX, FLT_MAX)
  local window_flag = r.ImGui_WindowFlags_NoCollapse()
                    | r.ImGui_WindowFlags_AlwaysAutoResize()

  if dock then
    if dock < 0 then
      dock = 0
    else
      dock = conf.dock
    end
    r.ImGui_SetNextWindowDockID(ctx, dock)
    dock = nil
  end

  if cur_x and dockID and not isdock then
    r.ImGui_SetNextWindowPos(ctx, cur_x, cur_y, r.ImGui_Cond_Once(), 0.5)
  end

  local visible, open = r.ImGui_Begin(ctx, script_name, true, window_flag)
  dockID = r.ImGui_GetWindowDockID(ctx)
  isdock = r.ImGui_IsWindowDocked(ctx)
  if dockID < 0 then
    conf.dock = dockID
  end
  r.ImGui_PopStyleColor(ctx, 2)

  if visible then
    ImGuiBody()
    r.ImGui_End(ctx)
  end

  r.ImGui_PopStyleVar(ctx)
  r.ImGui_PopFont(ctx)

  if not open or r.ImGui_IsKeyDown(ctx, 27) or close then
    r.ImGui_DestroyContext(ctx)
  else
    r.defer(loop)
  end
end

ExtState_Load()
StartContext()
r.defer(loop)

-- Extensions check end
  else
    r.ShowMessageBox("Please update v0.5.1 or later of  \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
    local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
    if ReaPack_exist == true then
      r.ReaPack_BrowsePackages('ReaImGui: ReaScript binding for Dear ImGui')
    end
  end
else
  r.ShowMessageBox("Please install \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
  local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
  if ReaPack_exist == true then
    r.ReaPack_BrowsePackages('ReaImGui: ReaScript binding for Dear ImGui')
  end
end

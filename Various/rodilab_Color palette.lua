-- @description Color palette
-- @author Rodilab
-- @version 1.51
-- @changelog
--   - Track Manager and Region/Marker Manager work on all OS
--   - Ctrl+Alt-click (Ctrl-click on Mac) with 'Takes' target set color to all takes (active, and non actives)
--   - Highlight border is black if color is very light
--   - Improved "Set 1st user to default tracks" option
--   - Improved "Track Manager and Region / Marker Manager" detection
-- @about
--   # Color tool with customizable color gradient palette and a user palette.
--
--   Use it to set custom Tracks / Items / Takes / Takes Markers / Markers / Regions colors.
--
--   [Thread in Cockos forum](https://forum.cockos.com/showthread.php?t=252219)
--
--   ---
--
--   Requirement :
--   - ReaImGui: ReaScript binding for Dear ImGui
--   - js_ReaScriptAPI: API functions for ReaScripts
--   - SWS Extension
--
--   ---
--
--   Features :
--   - Click on any color to set in selected Tracks/Items/Takes/Markers/Take Markers/Regions
--   - Target button automatically switch according to the last valid context
--   - Click on target button to fast switch inside each category :
--   - Tracks -> Tracks by Name
--         - Items -> Takes -> Take Markers
--         - Markers -> Regions
--   - Right-click on Target button manually choose to any target
--   - Click on Action button to start the displayed action
--   - Right-click on Action button to choose another action (last action is stored for next open) : Default / Random All / Random Each / In Order
--   - Right-click on "Settings" button to dock/undock (there is also a checkbox in the settings)
--   - Drag any palette color and drop it in user color
--   - Drag and drop any user color to move it
--   - Right-click to edit/add user color with color picker popup
--   - Alt-click to remove user color
--   - Shit-click to get first selected target color in user color
--   - Cmd-click (Ctrl in Windows) to past clipboard (HEX color value)
--   - Ctrl-click (Ctrl+Alt in Windows) to set color to children tracks
--   - Save as and Load user colors list
--   - Many settings... read the "Help" tab in Settings window
--
--   by Rodrigo Diaz (aka Rodilab)

r = reaper
script_name = "Color palette"
OS_Win = string.match(reaper.GetOS(),"Win")
OS_Mac = string.match(reaper.GetOS(),"OSX")
r_version = r.GetAppVersion()
r_version = tonumber(r_version:match[[(%d+.%d+)]])

-- Extensions check
if r.APIExists('CF_GetClipboard') == true then
  if r.APIExists('ImGui_CreateContext') == true then
    if r.APIExists('JS_Dialog_BrowseForOpenFiles') == true then
      if OS_Win or not r_version or r_version >= 6.28 then

-- Colors
rounding = 4.0
background_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.2,1)
background_popup_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.15,1)
framegb_color = r.ImGui_ColorConvertHSVtoRGB(0,0,0.15,1)
default_usercolor = r.ImGui_ColorConvertHSVtoRGB(0,0,0.27)

col_border_1 = r.ImGui_ColorConvertHSVtoRGB(0,0,1,1)
col_border_2 = r.ImGui_ColorConvertHSVtoRGB(0,0,0,1)

button_back = r.ImGui_ColorConvertHSVtoRGB(0,0,0.27,1)
button_hover = r.ImGui_ColorConvertHSVtoRGB(0,0,0.32,1)
button_active = r.ImGui_ColorConvertHSVtoRGB(0,0,0.4,1)

-- Flags
windows_flag = r.ImGui_WindowFlags_NoDecoration()
popup_flags = r.ImGui_WindowFlags_NoMove()
picker_flags = r.ImGui_ColorEditFlags_NoAlpha()
             | r.ImGui_ColorEditFlags_NoSidePreview()
             | r.ImGui_ColorEditFlags_PickerHueWheel()
             | r.ImGui_ColorEditFlags_NoInputs()
settings_window_flag = r.ImGui_WindowFlags_AlwaysAutoResize()
                     | r.ImGui_WindowFlags_NoTitleBar()

-- Don't change
command_colchildren = r.NamedCommandLookup('_SWS_COLCHILDREN')
recalc_colors = true
restart = false
set_tmp_values = false
set_default_sizes = false
settings = 0
file_dialog = 0
open_context = r.GetCursorContext2(true)
extension_list = "Text file (.txt)\0*.txt\0\0"
target_category_list = {1,1,2,2,2,3,3,3}
target_button_list = {'Tracks by Name','Tracks','Items','Takes','T Marks','Markers','Regions','Mk & Rg'}
action_button_list = {'Default','Rnd All','Rnd Each','In order'}
tmp = {}
last_track_state = 2
last_item_state = 3
last_marker_state = 8
seltracks_colors = {}
manager_focus = 0
trackmanager_title = reaper.JS_Localize('Track Manager', "common")
regionmanager_title = reaper.JS_Localize('Region/Marker Manager', "common")

-- User color file
info = debug.getinfo(1,'S')
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
separ = package.config:sub(1,1)
if script_path then
  last_palette_on_exit = script_path.."rodilab_"..script_name..separ.."last_palette_on_exit.txt"
  UserPalettes_path = script_path.."rodilab_"..script_name..separ
  reaper.RecursiveCreateDirectory(UserPalettes_path,1)
end

---------------------------------------------------------------------------------
--- Ext State -------------------------------------------------------------------
---------------------------------------------------------------------------------

conf = {}

extstate_id = "RODILAB_Color_palette"
function ExtState_Load()
  def = {
    color_hue = 0,
    color_saturation_min = 0.26,
    color_saturation_max = 0.50,
    color_lightness_min = 0.50,
    color_lightness_max = 0.71,
    color_grey = true,
    number_x = 15,
    palette_y = 3,
    user_y = 1,
    size = 18,
    spacing = 1,
    vertical = false,
    setcolor_childs = false,
    mouse_pos = true,
    auto_close = false,
    randfrom = 1,
    namestart_char = '',
    action_button = 1,
    dock = false,
    remplace_default = false,
    highlight = true,
    x = -1,
    y = -1
    }
  for key in pairs(def) do
    if r.HasExtState(extstate_id,key) then
      local state = r.GetExtState(extstate_id,key)
      if state == "true" then state = true
      elseif state == "false" then state = false end
      conf[key] = tonumber(state) or state
      if (type(conf[key]) ~= 'number' and (key=='color_hue'
                                       or key=='color_saturation_min'
                                       or key=='color_saturation_max'
                                       or key=='color_lightness_min'
                                       or key=='color_lightness_max'
                                       or key=='number_x'
                                       or key=='palette_y'
                                       or key=='user_y'
                                       or key=='size'
                                       or key=='spacing'
                                       or key=='randfrom'
                                       or key=='action_button'
                                       or key=='x'
                                       or key=='y'))
      or (type(conf[key]) ~= 'boolean'and (key=='color_grey'
                                       or key=='vertical'
                                       or key=='setcolor_childs'
                                       or key=='mouse_pos'
                                       or key=='auto_close'
                                       or key=='dock'
                                       or key=='highlight'
                                       or key=='remplace_default')) then
        conf[key] = def[key]
      end
    else
      conf[key] = def[key]
    end
  end
end

function ExtState_Save()
  for key in pairs(conf) do
    r.SetExtState(extstate_id, key, tostring(conf[key]), true)
  end
end

function restore_default_colors()
  conf.color_hue = def.color_hue
  conf.color_saturation_min = def.color_saturation_min
  conf.color_saturation_max = def.color_saturation_max
  conf.color_lightness_min = def.color_lightness_min
  conf.color_lightness_max = def.color_lightness_max
  conf.color_grey = def.color_grey
end

function restore_default_sizes()
  conf.number_x = def.number_x
  conf.palette_y = def.palette_y
  conf.user_y = def.user_y
  conf.spacing = def.spacing
  conf.size = def.size
  conf.vertical = def.vertical
end

---------------------------------------------------------------------------------
--- User Color Files ------------------------------------------------------------
---------------------------------------------------------------------------------

function SaveColorFile(palette_file)
  if palette_file then
    file = io.open(palette_file,"w+")
    for i,color_int in ipairs(usercolors) do
      local color_hex = INTtoHEX(color_int)
      file:write(color_hex,'\n')
    end
    file:close()
  end
end

function LoadColorFile(palette_file)
  local color_int_list = {}
  if palette_file then
    local palette = io.open(palette_file,"r")
    if palette ~= nil then
      for line in io.lines(palette_file) do
        local color_int = HEXtoINT(line)
        if color_int then
          table.insert(color_int_list,color_int)
        end
      end
      palette:close()
      return color_int_list
    end
    return color_int_list
  else
    return color_int_list
  end
end

---------------------------------------------------------------------------------
--- Convert Colors --------------------------------------------------------------
---------------------------------------------------------------------------------

function intRGBtoRGB(rgb)
  local r = rgb >> 16 & 0xFF
  local g = rgb >>  8 & 0xFF
  local b = rgb       & 0xFF
  return r,g,b
end

function INTtoHEX(int)
  local hex = string.format('%02x',int)
  hex = string.upper(hex)
  for i = 1, 6-string.len(hex) do
    hex = "0"..hex
  end
  return hex
end

function HEXtoINT(hex)
  int = tonumber(hex,16)
  return int
end

function NATIVEtoINT(native)
  local r, g, b = reaper.ColorFromNative(native)
  local int = b + g*16^2 + r*16^4
  return int
end

function INTtoNATIVE(int)
  local r, g, b = intRGBtoRGB(int)
  return reaper.ColorToNative(r,g,b)
end

---------------------------------------------------------------------------------
--- Others ----------------------------------------------------------------------
---------------------------------------------------------------------------------

function set_window()
  if conf.spacing > 3 then
    separator_spacing = conf.spacing
  else
    separator_spacing = 3
  end

  local width = (conf.number_x*conf.size)+((conf.number_x-1)*conf.spacing)
  local heigth = ((conf.palette_y + conf.user_y)*conf.size)+((conf.palette_y+conf.user_y-1)*conf.spacing)

  if conf.palette_y > 0 and conf.user_y > 0 then
    heigth = heigth+(separator_spacing+3)
  end

  if conf.vertical == true then
    local tmp_width = width
    local tmp_heigth = heigth
    width = tmp_heigth + 15
    heigth = tmp_width + 101
  else
    width = width + 15
    heigth = heigth + 39
  end

  local width_min
  if conf.vertical == true then
    width_min = 80
  else
    width_min = 215
  end

  if width < width_min then
    width = width_min
  end

  if type(conf.x) ~= 'number' then conf.x = -1 end
  if type(conf.y) ~= 'number' then conf.x = -1 end

  if restart == false and (conf.mouse_pos == true or conf.x < 0 or conf.y < 0) then
    conf.x, conf.y = r.GetMousePosition()
    conf.x = math.floor(conf.x - (width/2))
    conf.y = math.floor(conf.y + (heigth/2))
  end

  button_color = calc_colors()
  ctx = r.ImGui_CreateContext(script_name,width,heigth,conf.x,conf.y)
  hwnd = r.ImGui_GetNativeHwnd(ctx)
  if conf.dock == true then
    r.DockWindowAddEx(hwnd,script_name,script_name,true)
  end
end

function align_groups(i)
  local modulo = (i-1) % conf.number_x
  -- First item in each line
  if modulo == 0 then
    -- Exept first item
    if i ~= 1 then
      r.ImGui_EndGroup(ctx)
      -- If vertical, same line for each group
      if conf.vertical == true then
        r.ImGui_SameLine(ctx)
      end
    end
    r.ImGui_BeginGroup(ctx)
  end
  -- If horizontal, same line for each item in group
  if conf.vertical == false and modulo > 0 then
    r.ImGui_SameLine(ctx)
  end
end

function get_window_pos()
  rv, conf.x, conf.y,ctx_right,ctx_bottom = r.JS_Window_GetClientRect(hwnd)
  if not OS_Win then
    conf.y = conf.y - 10
  end
end

function get_tmp_values()
  for key, value in pairs(conf) do
    if key == 'number_x' or key == 'palette_y' or key == 'size' or key == 'spacing' or key == 'vertical' then
      tmp[key] = conf[key]
    end
  end
end

function calc_colors()
  local color_table = {}
  local line = -1
  for i=1, conf.number_x*conf.palette_y do
    if (i-1) % conf.number_x == 0 then
      line = line + 1
    end
    local hue
    if conf.color_grey == false then
      hue = (1/(conf.number_x))*((i-1)%conf.number_x)+conf.color_hue
    else
      if (i-1)%conf.number_x == 0 then
        hue = 0
      else
        hue = (1/(conf.number_x-1))*((i-2)%conf.number_x)+conf.color_hue
      end
    end
    local lightness = conf.color_lightness_max
    local saturation = conf.color_lightness_min
    if conf.palette_y > 1 then
      lightness =  (line/(conf.palette_y-1)*(conf.color_lightness_min -conf.color_lightness_max ))+conf.color_lightness_max
      saturation = (line/(conf.palette_y-1)*(conf.color_saturation_max-conf.color_saturation_min))+conf.color_saturation_min
    end
    if conf.color_grey == true and (i-1)%conf.number_x == 0 then
      saturation = 0
    end
    local buttonColor = r.ImGui_ColorConvertHSVtoRGB(hue,saturation,lightness)
    table.insert(color_table,buttonColor)
  end
  return color_table
end

function compare_sel_colors(color_int)
  for i,sel_colors in ipairs(seltracks_colors) do
    if sel_colors == color_int then
      return true
    end
  end
  return false
end

function insert_new_user(position,new_value)
  local size = #usercolors
  if position > size then
    table.insert(usercolors,new_value)
  else
    for i=0, size-1 do
      j = size-i
      if j > position then
        usercolors[j+1] = usercolors[j]
      elseif j == position then
        usercolors[j+1] = usercolors[j]
        usercolors[j] = new_value
      end
    end
  end
end

function get_clipboard_color()
  local clipboard = r.CF_GetClipboard()
  local color_int = HEXtoINT(clipboard)
  return color_int
end

function centered_button()
  if conf.vertical == true then
    r.ImGui_NewLine(ctx)
    r.ImGui_SameLine(ctx,(display_w-button_size)/2)
  end
end

---------------------------------------------------------------------------------
--- Managers --------------------------------------------------------------------
---------------------------------------------------------------------------------

function get_HWND_selitems_list(hWnd)
  if hWnd == nil then
    return
  end
  local container = r.JS_Window_FindChildByID(hWnd, 1071)
  local sel_count, sel_indexes = r.JS_ListView_ListAllSelItems(container)
  if sel_count == 0 then
    return
  end
  local names = {}
  local i = 0
  for index in string.gmatch(sel_indexes,'[^,]+') do
    i = i + 1
    local name = r.JS_ListView_GetItemText(container,tonumber(index),1)
    if name and name ~= '' then
      table.insert(names,name)
    end
  end
  return names
end

function get_managers_list(category, what)
  if hwnd_regions and r.JS_Window_IsWindow(hwnd_regions) == false then hwnd_regions = nil end
  if hwnd_tracks and r.JS_Window_IsWindow(hwnd_tracks) == false then hwnd_tracks = nil end
  if (manager_focus == 1 and not hwnd_regions) or (manager_focus == 2 and not hwnd_tracks) then
    manager_focus = 0
    return nil, nil
  elseif manager_focus == 1 and category == 3 then
    return get_HWND_selitems_list(hwnd_regions), nil
  elseif manager_focus == 2 and what == 'Tracks' then
    return nil, get_HWND_selitems_list(hwnd_tracks)
  end
end

---------------------------------------------------------------------------------
--- Actions ---------------------------------------------------------------------
---------------------------------------------------------------------------------

function set_firstuser_defaulttracks()
  if usercolors[1] then
    local count = reaper.CountTracks(0)
    if count > 0 then
      for i=0, count-1 do
        local track =  reaper.GetTrack(0,i)
        local trackcolor = reaper.GetTrackColor(track)
        if trackcolor == 0 then
          local color = INTtoNATIVE(usercolors[1])
          reaper.SetTrackColor(track,color|0x1000000)
        end
      end
    end
  end
end

function random_color()
  local list
  if #button_color > 0 and (conf.randfrom == 1 or (conf.randfrom == 2 and #usercolors == 0)) then
    list = button_color
  elseif #usercolors > 0 and (conf.randfrom == 2 or (conf.randfrom == 1 and #button_color == 0)) then
    list = usercolors
  end
  if #list > 0 then
    local random = math.random(#list)
    local color = INTtoNATIVE(list[random])
    return color
  else
    return nil
  end
end

function random_color_list(number)
  local source_list = {}
  local random_list = {}
  if #button_color > 0 and (conf.randfrom == 1 or (conf.randfrom == 2 and #usercolors == 0)) then
    for i, value in ipairs(button_color) do
      table.insert(source_list,value)
    end
  elseif #usercolors > 0 and (conf.randfrom == 2 or (conf.randfrom == 1 and #button_color == 0)) then
    for i, value in ipairs(usercolors) do
      table.insert(source_list,value)
    end
  end
  if #source_list > 0 then
    if not number or number > #source_list then
      number = #source_list
    end
    for i=1, number do
      local random = math.random(#source_list)
      local color = INTtoNATIVE(source_list[random])
      table.insert(random_list,color)
      table.remove(source_list,random)
    end
    return random_list
  else
    return nil
  end
end

function get_target_infos()
  -- Get Target
  local category = target_category_list[target_button]
  local what = target_button_list[target_button]
  local count
  -- Get count
  if what == 'Tracks' then
    count = reaper.CountSelectedTracks(0)
  elseif what == 'Tracks by Name' then
    count = reaper.CountTracks(0)
  elseif category == 2 then
    count = reaper.CountSelectedMediaItems(0)
  elseif category == 3 then
    local rv, num_markers, num_regions = reaper.CountProjectMarkers(0)
    count = num_markers + num_regions
  end
  if category == 3 or what == 'T Marks' then
    time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
    cursor = reaper.GetCursorPosition()
  end
  return category, what, count, cursor, time_sel_start, time_sel_end
end

function is_marker_selected(i,what,list)
  local rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color = reaper.EnumProjectMarkers3(0,i)
  if what == 'Mk & Rg' or (isrgn == true and what == 'Regions') or (isrgn == false and what == 'Markers') then
    if list then
      local MName  = ''
      if isrgn == true then MName = 'R'..markrgnindexnumber
      else MName = 'M'..markrgnindexnumber end

      for i,name in ipairs(list) do
        if MName == name then
          return true, rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color
        end
      end
    elseif (time_sel_start ~= time_sel_end and
            (
              (isrgn == true and
                (
                  (pos >= time_sel_start and pos <= time_sel_end)
                  or
                  (rgnend >= time_sel_start and rgnend <= time_sel_end)
                  or
                  (time_sel_start >= pos and time_sel_start <= rgnend)
                )
              )
              or
              (isrgn == false and (pos >= time_sel_start and pos <= time_sel_end))
            )
          )
          or
          (time_sel_start == time_sel_end and
            (
              (isrgn == true and (cursor >= pos and cursor <= rgnend))
              or
              (isrgn == false and pos == cursor)
            )
          )
    then
      return true, rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color
    end
  end
  return false, nil
end

function get_sel_target_colors_list()
  seltracks_colors = {}
  -- Get Target
  local category, what, count, cursor, time_sel_start, time_sel_end = get_target_infos()
  -- List manager
  local manager_regions_list, manager_tracks_list = get_managers_list(category, what)
  if manager_tracks_list then
    count = #manager_tracks_list
  end
  -- For each target
  for i=0, count-1 do
    local color = nil
    if category == 1 then
      local track
      if manager_tracks_list then
        track = reaper.GetTrack(0,manager_tracks_list[i+1]-1)
      else
        track = reaper.GetSelectedTrack(0,i)
      end
      if track then
        color = reaper.GetMediaTrackInfo_Value(track,"I_CUSTOMCOLOR")
      else
        break
      end
    elseif category == 2 then
      local item = reaper.GetSelectedMediaItem(0,i)
      if what == 'Items' then
        color = reaper.GetMediaItemInfo_Value(item,"I_CUSTOMCOLOR")
      else
        local take = reaper.GetActiveTake(item)
        if what == 'Takes' then
          color = reaper.GetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR")
        elseif what == 'T Marks' then
          for j=0, reaper.GetNumTakeMarkers(take)-1 do
            local rv, name, tmark_color = reaper.GetTakeMarker(take,j)
            if tmark_color then
              table.insert(seltracks_colors,NATIVEtoINT(tmark_color))
            end
          end
        end
      end
    elseif category == 3 then
      local is_selected, rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color = is_marker_selected(i,what,manager_regions_list)
      if is_selected == true then
        color = tmp_color
      else
        color = nil
      end
    end
    if color then
      table.insert(seltracks_colors,NATIVEtoINT(color))
    end
  end
end

function get_first_sel_target_color()
  -- Get Target
  local category, what, count, cursor, time_sel_start, time_sel_end = get_target_infos()
  -- List manager
  local manager_regions_list, manager_tracks_list = get_managers_list(category, what)
  if manager_tracks_list then
    count = #manager_tracks_list
  end
  -- For each target
  for i=0, count-1 do
    local color = nil
    if category == 1 then
      local track
      if manager_tracks_list then
        track = reaper.GetTrack(0,manager_tracks_list[i+1]-1)
      else
        track = reaper.GetSelectedTrack(0,i)
      end
      color = reaper.GetMediaTrackInfo_Value(track,"I_CUSTOMCOLOR")
      return color
    elseif category == 2 then
      local item = reaper.GetSelectedMediaItem(0,i)
      if what == 'Items' then
        color = reaper.GetMediaItemInfo_Value(item,"I_CUSTOMCOLOR")
        return color
      else
        local take = reaper.GetActiveTake(item)
        if what == 'Takes' then
          color = reaper.GetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR")
          return color
        elseif what == 'T Marks' then
          for j=0, reaper.GetNumTakeMarkers(take)-1 do
            local rv, name, tmark_color = reaper.GetTakeMarker(take,j)
            if tmark_color then
              return tmark_color
            end
          end
        end
      end
    elseif category == 3 then
      local is_selected, rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color = is_marker_selected(i,what,manager_regions_list)
      if is_selected == true then
        return tmp_color
      end
    end
  end
  return nil
end

---------------------------------------------------------------------------------
--- Main ------------------------------------------------------------------------
---------------------------------------------------------------------------------

function SetColor(color_int)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  -- Get Target
  local category, what, count, cursor, time_sel_start, time_sel_end = get_target_infos()
  -- List manager
  local manager_regions_list, manager_tracks_list = get_managers_list(category, what)
  if manager_tracks_list then
    count = #manager_tracks_list
  end
  -- Get color
  local color
  local color_list
  if type(color_int) == 'number' then
    color = INTtoNATIVE(color_int)|0x1000000
  elseif color_int == 'Default' then
    color = 0
  elseif color_int == 'Rnd All' then
    color = random_color()|0x1000000
  elseif color_int == 'Rnd Each' then
    if what == 'Takes' and (mods == 5 or mods == 8) then
      color_list = random_color_list(nil)
    else
      color_list = random_color_list(count)
    end
  elseif color_int == 'In order' then
    if conf.randfrom == 1 then
      if #button_color > 0 then
        color_list = button_color
      elseif #usercolors > 0 then
        color_list = usercolors
      else
        return
      end
    else
      if #usercolors > 0 then
        color_list = usercolors
      elseif #button_color > 0 then
        color_list = button_color
      else
        return
      end
    end
  end
  local j = 0
  -- For each target
  for i=0, count-1 do
    -- Random/In order for each selected target
    if color_int == 'Rnd Each' or color_int == 'In order' then
      j = j%(#color_list)
      color = color_list[j+1]
      if color_int == 'Rnd Each' then
        color = color|0x1000000
      elseif color_int == 'In order' then
        color = INTtoNATIVE(color)|0x1000000
      end
    end
    if not color then
      return
    end
    if category == 1 then
      local track
      local set = false
      if what == 'Tracks' then
        if manager_tracks_list then
          track = reaper.GetTrack(0,manager_tracks_list[i+1]-1)
          set = true
        else
          track = reaper.GetSelectedTrack(0,i)
          local parent = reaper.GetParentTrack(track)
          if parent and (conf.setcolor_childs == true or mods == 5 or mods == 8) and reaper.IsTrackSelected(parent) == true then
            set = false
          else
            set = true
          end
        end
      elseif what == 'Tracks by Name' then
        track = reaper.GetTrack(0,i)
        local retval, trackname = reaper.GetTrackName(track)
        if retval == true then
          local trackname = string.sub(trackname,1,string.len(conf.namestart_char))
          if trackname == conf.namestart_char then
            set = true
          end
        end
      end
      if set == true then
        reaper.SetMediaTrackInfo_Value(track,"I_CUSTOMCOLOR",color)
        j = j + 1
      end
    elseif category == 2 then
      local item = reaper.GetSelectedMediaItem(0,i)
      if what == 'Items' then
        reaper.SetMediaItemInfo_Value(item,"I_CUSTOMCOLOR",color)
        j = j + 1
        -- Set default colors for all takes
        reaper.Main_OnCommand(41337,0)
      else
        local take = reaper.GetActiveTake(item)
        if what == 'Takes' then
          if mods == 5 or mods == 8 then
            for k = 0, reaper.CountTakes(item)-1 do
              if color_int == 'Rnd Each' or color_int == 'In order' then
                j = (j%(#color_list))
                color = color_list[j+1]|0x1000000
              end
              local take = reaper.GetMediaItemTake(item,k)
              reaper.SetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR",color)
              j = j + 1
            end
          else
            reaper.SetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR",color)
            j = j + 1
          end
        elseif what == 'T Marks' then
          local zoom = (1/reaper.GetHZoomLevel())*2
          local item_pos = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
          local startoffs = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")
          local playrate = reaper.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE")
          for j=0, reaper.GetNumTakeMarkers(take)-1 do
            local rv, name = reaper.GetTakeMarker(take,j)
            local pos = item_pos+(rv-startoffs)*(1/playrate)
            if (pos > cursor-zoom and pos < cursor+zoom) or (pos > time_sel_start and pos < time_sel_end) then
              if color_int == 'Rnd Each' or color_int == 'In order' then
                j = (j%(#color_list))
                color = color_list[j+1]|0x1000000
              end
              reaper.SetTakeMarker(take,j,name,rv,color)
              j = j + 1
            end
          end
        end
      end
    elseif category == 3 then
      local is_selected, rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color = is_marker_selected(i,what,manager_regions_list)
      if is_selected == true then
        reaper.SetProjectMarker3(0,markrgnindexnumber,isrgn,pos,rgnend,name,color)
        j = j + 1
      end
    end
  end
  -- Children tracks color
  if (category == 1 or what == 'tracks_names') and command_colchildren ~= 0 and (conf.setcolor_childs == true or mods == 5 or mods == 8) then
    reaper.Main_OnCommand(command_colchildren,0)
  end
  if conf.auto_close == true then
    close = true
  end
  reaper.Undo_EndBlock(script_name,-1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

---------------------------------------------------------------------------------
--- ImGui -----------------------------------------------------------------------
---------------------------------------------------------------------------------

reaper.atexit(function()
  ExtState_Save()
  SaveColorFile(last_palette_on_exit)
end)

last_left_click = 0
last_right_click = 0
function get_last_context()
  local left_click = r.JS_Mouse_GetState(1)
  local right_click = r.JS_Mouse_GetState(2)
  if open_context then
    target_button = open_context + 2
    open_context = nil
  else
    if (left_click == 1 and last_left_click ~= 1) or (right_click == 2 and last_right_click ~= 2) then
      local window, segment, details = r.BR_GetMouseCursorContext()
      if window ~= 'unknown' then
        manager_focus = 0
        if window == 'tcp' or window == 'mcp' then
          target_button = last_track_state
        elseif window == 'arrange' then
          target_button = last_item_state
        elseif window == 'ruler' then
          if segment == 'marker_lane' then
            target_button = 6
            last_marker_state = 6
          elseif segment == 'region_lane' then
            target_button = 7
            last_marker_state = 7
          else
            target_button = last_marker_state
          end
        end
      else
        -- If unknown, get focus hwnd and parent
        local hwnd_focus = r.JS_Window_GetFocus()
        if hwnd_focus and hwnd_focus ~= hwnd then
          local hwnd_focus_parent = r.JS_Window_GetParent(hwnd_focus)
          if hwnd_focus_parent and hwnd_focus_parent ~= hwnd then
            local hwnd_focus_parent_title = r.JS_Window_GetTitle(hwnd_focus_parent)
            if hwnd_focus_parent_title == trackmanager_title then
              hwnd_tracks = hwnd_focus_parent
              manager_focus, target_button = 2,2
            elseif hwnd_focus_parent_title == regionmanager_title then
              hwnd_regions = hwnd_focus_parent
              manager_focus, target_button = 1,8
            end
          end
        end
      end
    end
  end
  last_left_click = left_click
  last_right_click = right_click
end

function highlight_sel(color)
  col_border = nil
  if compare_sel_colors(color) == true then
    local border_size
    local Br,Bg,Bb = intRGBtoRGB(color)
    if math.max(Br,Bg,Bb) > 220 then
      col_border = col_border_2
      border_size = 1
    else
      col_border = col_border_1
      border_size = 1
    end
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Border(),col_border)
    r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),border_size)
  end
end

function loop()
  get_last_context()

  -- Set 1st user color to default tracks option
  if conf.remplace_default == true then
    if count_tracks then
      local new_count_tracks = reaper.CountTracks(0)
      if new_count_tracks > count_tracks then
        count_tracks = new_count_tracks
        set_firstuser_defaulttracks()
      elseif new_count_tracks < count_tracks then
        count_tracks = new_count_tracks
      end
    else
      count_tracks = reaper.CountTracks(0)
      set_firstuser_defaulttracks()
    end
  elseif conf.remplace_default == false and count_tracks then
    count_tracks = nil
  end

  -- Get selected tracks color
  if conf.highlight == true then
    get_sel_target_colors_list()
  else
    seltracks_colors = {}
  end

  -- Save/Load Dialog (reset script)
  if file_dialog > 0 then
    if not OS_Mac then
      r.ImGui_DestroyContext(ctx2)
      r.ImGui_DestroyContext(ctx)
    end
    -- Save Dialog
    if file_dialog == 1 then
      rv, fileName = r.JS_Dialog_BrowseForSaveFile('Save user palette',UserPalettes_path,'',extension_list)
      if rv == 1 or rv == true then
        if fileName:sub(string.len(fileName)-3,string.len(fileName)) ~= '.txt' then
          fileName = fileName..'.txt'
        end
        SaveColorFile(fileName)
      end
    end
    -- Load Dialog
    if file_dialog == 2 then
      local rv, fileName = r.JS_Dialog_BrowseForOpenFiles('Open user palette',UserPalettes_path,'',extension_list,false)
      if rv == 1 then
        usercolors = LoadColorFile(fileName)
      end
    end
    file_dialog = 0
    settings = 0
    if not OS_Mac then
      set_window()
    end
  end

  -- Close Window ?
  if r.ImGui_IsCloseRequested(ctx) or r.ImGui_IsKeyDown(ctx,53) or close == true then
    if settings == 2 then
      r.ImGui_DestroyContext(ctx2)
    end
    get_window_pos()
    r.ImGui_DestroyContext(ctx)
    return
  end

  -- Restart
  if restart == true then
    if set_tmp_values == true then
      set_tmp_values = false
      for key,value in pairs(tmp) do
        conf[key] = tmp[key]
      end
    end
    if set_default_sizes == true then
      restore_default_sizes()
    end
    get_tmp_values()
    button_color = calc_colors()
    get_window_pos()
    r.ImGui_DestroyContext(ctx)
    set_window()
    restart = false
  end

  local rv
  display_w, display_h = r.ImGui_GetDisplaySize(ctx)

  ----------------------------------------------------------------
  -- Settings Window
  ----------------------------------------------------------------

  if settings > 0 then
    if settings == 1 then
      local settings_width = 270
      local settings_heigth = 250
      local x,y
      if conf.dock == true then
        x = nil
        y = nil
      else
        get_window_pos()
        x = conf.x
        if x < 0 then x = 0 end
        if OS_Win then
          y = conf.y - settings_heigth - 65
          if y < settings_heigth then
            y = ctx_bottom + 65
          end
        else
          y = ctx_bottom - 35
          if y < settings_heigth then
            y = conf.y + settings_heigth + 30
          end
        end
      end
      ctx2 = r.ImGui_CreateContext(script_name.." - Settings",settings_width,settings_heigth,x,y)
      settings = 2
    end
    local display_w, display_h = r.ImGui_GetDisplaySize(ctx2)
    r.ImGui_SetNextWindowPos(ctx2,0,0)
    r.ImGui_SetNextWindowSize(ctx2,display_w,display_h)
    r.ImGui_PushStyleColor(ctx2,r.ImGui_Col_WindowBg(),background_color)
    r.ImGui_Begin(ctx2,'wnd2',nil,settings_window_flag)
    r.ImGui_PopStyleColor(ctx2)
    r.ImGui_PushStyleVar(ctx2,r.ImGui_StyleVar_FrameRounding(),rounding)

    -- Content
    if r.ImGui_BeginTabBar(ctx2,'Tabbar') then
      if r.ImGui_BeginTabItem(ctx2,'Settings') then
        r.ImGui_Spacing(ctx2)
        r.ImGui_AlignTextToFramePadding(ctx2)
        r.ImGui_Text(ctx2,'User file :')
        r.ImGui_SameLine(ctx2)
        if r.ImGui_Button(ctx2,'Save as') then
          file_dialog = 1
        end
        r.ImGui_SameLine(ctx2)
        if r.ImGui_Button(ctx2,'Load') then
          file_dialog = 2
        end
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        rv,conf.setcolor_childs = r.ImGui_Checkbox(ctx2,'Set always color to children',conf.setcolor_childs)
        rv,conf.remplace_default = r.ImGui_Checkbox(ctx2,'Set 1st user to default tracks',conf.remplace_default)
        rv,conf.highlight = r.ImGui_Checkbox(ctx2,'Highlight matching colors',conf.highlight)
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        r.ImGui_Text(ctx2,'Random and In Order from :')
        rv,conf.randfrom = r.ImGui_RadioButtonEx(ctx2,'Palette colors',conf.randfrom,1)
        rv,conf.randfrom = r.ImGui_RadioButtonEx(ctx2,'User colors',conf.randfrom,2)
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        rv,conf.mouse_pos = r.ImGui_Checkbox(ctx2,'Open window on mouse position',conf.mouse_pos)
        rv,conf.auto_close = r.ImGui_Checkbox(ctx2,'Quit after apply color',conf.auto_close)
        rv,conf.dock = r.ImGui_Checkbox(ctx2,'Dock window',conf.dock)
        if r.ImGui_IsItemClicked(ctx2,0) then
          if conf.dock == true then conf.dock = false
          else conf.dock = true end
          restart = true
        end
        r.ImGui_EndTabItem(ctx2)
      end
      if r.ImGui_BeginTabItem(ctx2,'Colors') then
        button_color = calc_colors()
        r.ImGui_PushItemWidth(ctx2,-1)
        rv,conf.color_hue = r.ImGui_SliderDouble(ctx2,'##Hue',conf.color_hue,0.0,1.0,'Initial Hue %.2f')
        r.ImGui_PushItemWidth(ctx2,150)
        rv,conf.color_saturation_min,conf.color_saturation_max = r.ImGui_DragFloatRange2(ctx2,'Saturation',conf.color_saturation_min,conf.color_saturation_max,0.01,0.0,1.0,'Min %.2f',"Max %.2f",r.ImGui_SliderFlags_AlwaysClamp())
        rv,conf.color_lightness_min,conf.color_lightness_max = r.ImGui_DragFloatRange2(ctx2,'Lightness',conf.color_lightness_min,conf.color_lightness_max,0.01,0.0,1.0,'Min %.2f',"Max %.2f",r.ImGui_SliderFlags_AlwaysClamp())
        r.ImGui_PushItemWidth(ctx2,-1)
        rv,conf.color_grey = r.ImGui_Checkbox(ctx2,'First col is grey',conf.color_grey)
        if r.ImGui_Button(ctx2,'Restore') then
          restore_default_colors()
          button_color = calc_colors()
        end
        r.ImGui_EndTabItem(ctx2)
      end
      if r.ImGui_BeginTabItem(ctx2,'Size') then
        r.ImGui_PushItemWidth(ctx2,90)
        rv, tmp.number_x = r.ImGui_InputInt(ctx2,'Rows',tmp.number_x,1,10)
        if tmp.number_x < 1 then tmp.number_x = 1 end
        rv,tmp.palette_y = r.ImGui_InputInt(ctx2,'Palette Lines',tmp.palette_y,1,10)
        rv,tmp.user_y = r.ImGui_InputInt(ctx2,'User Lines',tmp.user_y,1,10)
        rv,tmp.size = r.ImGui_InputInt(ctx2,'Size (pixels)',tmp.size,1,10)
        rv,tmp.spacing = r.ImGui_InputInt(ctx2,'Spacing (pixels)',tmp.spacing,1,10)
        rv,tmp.vertical = r.ImGui_Checkbox(ctx2,'Vertical mod',tmp.vertical)
        -- Positives values
        for key, value in pairs(tmp) do
          if type(value) == 'number' and value < 0 then
            tmp[key] = 0
          end
        end
        r.ImGui_PopItemWidth(ctx2)
        if r.ImGui_Button(ctx2,'Apply') then
          restart = true
          set_tmp_values = true
        end
        r.ImGui_SameLine(ctx2)
        if r.ImGui_Button(ctx2,'Restore') then
          restart = true
          set_default_sizes = true
        end
        r.ImGui_EndTabItem(ctx2)
      end
      if r.ImGui_BeginTabItem(ctx2,'Help') then
        local msg_list = {'Drag and drop to insert color in user palette',
                          'Right-click to edit user color',
                          'Alt-click to remove user color',
                          'Cmd-click to past HEX value',
                          'Ctrl-click set color in children tracks',
                          'Shift-click to get first selected target color in user',
                          'Click on Target button to fast switch target in each category (any modifier-click for Tracks by Name text input)',
                          'Right-click on Target button to manually change the next target',
                          'Right-click on Action button to set Default/Random All/Random Each/In Order mode',
                          'Right-click on Settings button to dock/undock window'}
        if not OS_Mac then
          msg_list[4] = string.gsub(msg_list[4],'Cmd','Ctrl')
          msg_list[5] = string.gsub(msg_list[5],'Ctrl','Ctrl+Alt')
        end
        for i,msg in ipairs(msg_list) do
          r.ImGui_Bullet(ctx2)
          r.ImGui_TextWrapped(ctx2,msg)
          r.ImGui_Spacing(ctx2)
        end
        r.ImGui_EndTabItem(ctx2)
      end
      r.ImGui_EndTabBar(ctx2)
    end
    r.ImGui_PopStyleVar(ctx2)
    r.ImGui_End(ctx2)
    if r.ImGui_IsCloseRequested(ctx2) or restart == true then
      r.ImGui_DestroyContext(ctx2)
      settings = 0
    end
  end

  ----------------------------------------------------------------
  -- Main Window
  ----------------------------------------------------------------

  r.ImGui_SetNextWindowPos(ctx,0,0)
  r.ImGui_SetNextWindowSize(ctx,display_w,display_h)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg(),background_color)
  r.ImGui_Begin(ctx,'wnd',nil,windows_flag)
  r.ImGui_PopStyleColor(ctx)

  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),rounding)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_PopupBg(),background_popup_color)

  -- Get modifiers key
  mods = r.ImGui_GetKeyMods(ctx)
  if mods == 1 then
    mods_help = 'Past'
  elseif mods == 2 then
    mods_help = 'Get color'
  elseif mods == 4 then
    mods_help = 'Remove'
  elseif  mods == 5 or mods == 8 then
    mods_help = 'Childs'
  else
    mods_help = nil
  end

  --[[
  -- Undo
  if mods == 1 and r.ImGui_IsKeyPressed(ctx,13,false) == true then
    r.Undo_DoUndo2(0)
  end
  ]]--

  -- Top buttons
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),button_back)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),button_hover)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),button_active)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBg(),button_back)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgHovered(),button_hover)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgActive(),button_active)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Header(),button_back)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_HeaderHovered(),button_hover)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_HeaderHovered(),button_active)

  if conf.vertical == true then
    button_size = 65
  else
    button_size = nil
  end

  centered_button()
  -- Target utton
  if target_button > 1 then
    if not button_size then button_size_item = 56 else button_size_item = button_size end
    if r.ImGui_Button(ctx,target_button_list[target_button],button_size_item) then
      if target_button >= 3 and target_button <= 5 then
        target_button = (target_button-2)%3+3
        last_item_state = target_button
      elseif target_button >= 6 and target_button <= 8 then
        target_button = (target_button-5)%3+6
        last_marker_state = target_button
      elseif target_button == 2 then
        target_button = 1
        last_track_state = target_button
      end
    end
  else
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBg(),framegb_color)
    if button_size then
      r.ImGui_PushItemWidth(ctx,button_size)
    else
      r.ImGui_PushItemWidth(ctx,56)
    end
    rv,conf.namestart_char = r.ImGui_InputTextWithHint(ctx,'##NameStart Input','name ?',conf.namestart_char)
    if r.ImGui_IsItemClicked(ctx) and mods > 0 then
      target_button = 2
      last_track_state = target_button
    end
    r.ImGui_PopStyleColor(ctx)
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'target_combo',1)

  if conf.vertical == false then r.ImGui_SameLine(ctx) end
  centered_button()

  -- Action button
  if not button_size then button_size_default = 64 else button_size_default = button_size end
  if r.ImGui_Button(ctx,action_button_list[conf.action_button],button_size_default) then
    SetColor(action_button_list[conf.action_button])
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'action_combo',1)

  if conf.vertical == false then r.ImGui_SameLine(ctx) end
  centered_button()

  -- Settings button
  if r.ImGui_Button(ctx,'Settings',button_size) then
    settings = 1
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'Dock Popup',1)
  if mods_help then
    if conf.vertical == false then r.ImGui_SameLine(ctx) end
    r.ImGui_TextDisabled(ctx,mods_help)
  else
    if conf.vertical == true then
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,r.ImGui_GetFontSize(ctx)+4)
      r.ImGui_Spacing(ctx)
      r.ImGui_PopStyleVar(ctx)
    end
  end
  r.ImGui_PopStyleColor(ctx,9)

  ----------------------------------------------------------------
  -- Popups
  ----------------------------------------------------------------

  -- Popup Color Picker
  if r.ImGui_BeginPopup(ctx,'Color Editor',popup_flags) then
    if display_w > display_h then
      picker_width = display_h
    else
      picker_width = display_w
    end
    picker_width = picker_width * 0.8
    if picker_width < 70 then picker_width = 70 end
    r.ImGui_PushItemWidth(ctx,picker_width)
    rv, usercolors[selected_button] = r.ImGui_ColorPicker4(ctx,'##ColorPicker',usercolors[selected_button],picker_flags)
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Settings Dock/Undock
  if r.ImGui_BeginPopup(ctx,'Dock Popup',popup_flags) then
    local text
    if conf.dock == true then text = 'Undock'
    else text = 'Dock' end
    r.ImGui_Text(ctx,text)
    if r.ImGui_IsItemClicked(ctx) then
      restart = true
      if conf.dock == true then conf.dock = false
      else conf.dock = true end
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Target combo lists
  if r.ImGui_BeginPopup(ctx,'target_combo',popup_flags) then
    for i,key in ipairs(target_button_list) do
      if i ~= target_button then
        if r.ImGui_Selectable(ctx,key) then
          target_button = i
          if i == 1 or i == 2 then last_track_state = i
          elseif i >= 3 and i <= 5 then last_item_state = i end
        end
      end
      if i < #target_button_list and target_category_list[i] ~= target_category_list[i+1] then
        r.ImGui_Separator(ctx)
      end
    end
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Action combo lists
  if r.ImGui_BeginPopup(ctx,'action_combo',popup_flags) then
    for i,key in ipairs(action_button_list) do
      if i ~= conf.action_button then
        if r.ImGui_Selectable(ctx,key) then
          conf.action_button = i
        end
        if i < #action_button_list then
          if conf.action_button == #action_button_list then
            if i ~= #action_button_list - 1 then
              r.ImGui_Separator(ctx)
            end
          else
            r.ImGui_Separator(ctx)
          end
        end
      end
    end
    r.ImGui_EndPopup(ctx)
  end

  ----------------------------------------------------------------
  -- Bouton Colors
  ----------------------------------------------------------------

  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),1)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),0)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),conf.spacing,conf.spacing)
  -- Palette Colors
  for i=1, conf.number_x*conf.palette_y do
    align_groups(i)

    -- Last line, dont bottom spacing
    if i == conf.number_x*(conf.palette_y-1)+1 and conf.vertical == false then
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),conf.spacing,0)
    end

    local button_flags =  r.ImGui_ColorEditFlags_NoAlpha()
                        | r.ImGui_ColorEditFlags_NoTooltip()
                        | r.ImGui_ColorEditFlags_NoDragDrop()
    highlight_sel(button_color[i])
    if not col_border then
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    if r.ImGui_ColorButton(ctx,'##'..i,button_color[i],button_flags,conf.size,conf.size) then
      SetColor(button_color[i])
    end

    if col_border then
      r.ImGui_PopStyleColor(ctx)
      r.ImGui_PopStyleVar(ctx)
    end

    -- Drag and Drop source
    if r.ImGui_BeginDragDropSource(ctx,r.ImGui_DragDropFlags_None()) then
      r.ImGui_SetDragDropPayload(ctx,'DnD_Color',button_color[i])
      r.ImGui_ColorButton(ctx,'DnD_Preview',button_color[i],r.ImGui_ColorEditFlags_NoAlpha())
      r.ImGui_EndDragDropSource(ctx)
    end
  end
  if conf.palette_y > 0 then
    r.ImGui_EndGroup(ctx)
    if conf.vertical == false then r.ImGui_PopStyleVar(ctx) end
  end

  if conf.vertical == false then
    if conf.palette_y > 0 and conf.user_y > 0 then
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,separator_spacing)
      r.ImGui_Spacing(ctx)
      r.ImGui_PopStyleVar(ctx)
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,separator_spacing+1)
      r.ImGui_Separator(ctx)
      r.ImGui_PopStyleVar(ctx)
    end
  elseif conf.vertical == true and conf.palette_y > 0 then
    r.ImGui_SameLine(ctx,nil,separator_spacing*2+1)
  end

  -- User colors
  for i=1, conf.number_x*conf.user_y do
    align_groups(i)
    local button_user_color
    local button_empty
    if usercolors[i] then
      button_user_color = usercolors[i]
      button_empty = false
    else
      button_user_color = default_usercolor
      button_empty = true
    end

    -- Flags
    local button_flags =  r.ImGui_ColorEditFlags_NoAlpha()
                        | r.ImGui_ColorEditFlags_NoTooltip()
                        | r.ImGui_ColorEditFlags_NoDragDrop()
    highlight_sel(usercolors[i])
    if not col_border then
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    -- Main Button
    if r.ImGui_ColorButton(ctx,'##User'..i,button_user_color,button_flags,conf.size,conf.size) then
      if mods == 4 then
        if button_empty == false then
          table.remove(usercolors,i)
        end
      elseif mods == 1 then
        local past_color = get_clipboard_color()
        if past_color then
          if button_empty == false then
            usercolors[i] = past_color
          else
            usercolors[#usercolors+1] = past_color
          end
        end
      elseif mods == 2 then
        local first_sel_target_color = get_first_sel_target_color()
        if first_sel_target_color and first_sel_target_color ~= 0 then
          first_sel_target_color = NATIVEtoINT(first_sel_target_color)
          if button_empty == false then
            usercolors[i] = first_sel_target_color
          else
            usercolors[#usercolors+1] = first_sel_target_color
          end
        end
      else
        if button_empty == false then
          SetColor(button_user_color)
        end
      end
    end

    if col_border then
      r.ImGui_PopStyleColor(ctx)
      r.ImGui_PopStyleVar(ctx)
    end

    -- Drag and drop source
    if button_empty == false then
      if r.ImGui_BeginDragDropSource(ctx) then
        r.ImGui_SetDragDropPayload(ctx,'DnD_Color',usercolors[i])
        if not dragdrop_source_id then
          dragdrop_source_id = i
        end
        r.ImGui_ColorButton(ctx,'DnD_Preview',usercolors[i],r.ImGui_ColorEditFlags_NoAlpha())
        r.ImGui_EndDragDropSource(ctx)
      end
    end
    -- Drag and drop target
    if r.ImGui_BeginDragDropTarget(ctx) then
      local rv,payload = r.ImGui_AcceptDragDropPayload(ctx,'DnD_Color')
      if rv == true then
        if dragdrop_source_id then
          table.remove(usercolors,dragdrop_source_id)
          dragdrop_source_id = nil
        end
        insert_new_user(i,tonumber(payload))
      end
      r.ImGui_EndDragDropTarget(ctx)
    end

    -- Right Click open Color Pick Popup
    if r.ImGui_IsItemClicked(ctx,r.ImGui_MouseButton_Right()) then
      if button_empty == false then
        selected_button = i
      elseif button_empty == true then
        selected_button = #usercolors+1
      end
      r.ImGui_OpenPopup(ctx,'Color Editor')
    end
  end
  if conf.user_y > 0 then
    r.ImGui_EndGroup(ctx)
  end

  -- Global pop
  r.ImGui_PopStyleColor(ctx,1)
  r.ImGui_PopStyleVar(ctx,4)

  -- End loop
  r.ImGui_End(ctx)
  r.defer(loop)
end

---------------------------------------------------------------------------------
-- DO IT ------------------------------------------------------------------------
---------------------------------------------------------------------------------

ExtState_Load()
usercolors = LoadColorFile(last_palette_on_exit)
get_tmp_values()
set_window()
r.defer(loop)

-- Extentions check end
      else
        r.ShowMessageBox('Please install Reaper 6.28 or later',script_name,0)
      end
    else
      r.ShowMessageBox("Please install \"js_ReaScriptAPI: API functions for ReaScripts\" with ReaPack and restart Reaper",script_name,0)
      local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
      if ReaPack_exist == true then
        r.ReaPack_BrowsePackages('js_ReaScriptAPI: API functions for ReaScripts')
      end
    end
  else
    r.ShowMessageBox("Please install \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
    local ReaPack_exist = r.APIExists('ReaPack_BrowsePackages')
    if ReaPack_exist == true then
      r.ReaPack_BrowsePackages('ReaImGui: ReaScript binding for Dear ImGui')
    end
  end
else
  r.ShowMessageBox("Please install \"SWS extension\" : https://www.sws-extension.org",script_name,0)
end

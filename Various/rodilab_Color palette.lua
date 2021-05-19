-- @description Color palette
-- @author Rodilab
-- @version 1.8.1
-- @changelog Updated due to the new version of ReaImGui v0.4.0
-- @about
--   # Color tool with customizable color gradient palette and a user palette.
--
--   Use it to set custom Tracks / Items / Takes / Takes Markers / Markers / Regions colors.
--
--   [Thread in Cockos forum](https://forum.cockos.com/showthread.php?t=252219)
--
--   ---
--   Requirement :
--   - ReaImGui: ReaScript binding for Dear ImGui
--   - js_ReaScriptAPI: API functions for ReaScripts
--   - SWS Extension
--   ---
--   Features :
--   - Click on any color to set in selected Tracks/Items/Takes/Markers/Take Markers/Regions
--   - Target button automatically switch according to the last valid context
--   - Click on target button to fast switch inside each category
--   - Right-click on Target button manually choose to any target
--   - Click on Action button to start the displayed action
--   - Right-click on Action button to choose another action (Default / Random All / Random Each / In Order) :
--   - Right-click on "Settings" button to dock/undock (there is also a checkbox in the settings)
--   - Drag any palette color and drop it in user color
--   - Drag and drop any user color to move it (or drop away to remove)
--   - Right-click on user color to open popup menu (Edit / Get first selected target color / Paste Hex value / Remove / Clear all)
--   ---
--   Mouse modifiers :
--   - Customize all mouse modifiers in Settings/Shortcuts menu
--   - [Ctrl]/[Cmd] Insert new target with clicked color
--   - [Ctrl+Alt]/[Cmd+Opt] Insert new named target with clicked color
--   - [Shift+Ctrl]/[Opt] Check/Uncheck color
--   - [Alt]/[Ctrl] Set color to children tracks too / to all takes (non active too)
--   ---
--   Shortcuts :
--   - Keyboard shortcuts (see Settings/Shortcuts menu)
--   - Arrows : Navigation - Go to next/previous element, depends on target
--   - 1-9 numbers : Set user color by ID (works with modifiers also)
--   - 0 : Set default color (works with modifiers also)
--   - Enter : Run action button (works with modifiers also)
--   - R : Run Random All (works with modifiers also)
--   - E : Run Random Each (works with modifiers also)
--   - I : Run In Order (works with modifiers also)
--   - Backspace / Delete : Remove user color under mouse cursor
--   - Ctrl+C : Copy hex color under mouse cursor in clipboard
--   - Ctrl+V : Paste hex color from clipboard under mouse cursor
--   - Spacebar : Check/Uncheck color under mouse cursor, only on "Check list" mode for Random / In Order
--   - [Ctrl+S] / [Cmd+S] : Save as user colors
--   - [Ctrl+O] / [Cmd+O] : Load user colors file
--   - Many settings...
--
--   by Rodrigo Diaz (aka Rodilab)

r = reaper
script_name = "Color palette"
OS_Win = string.match(reaper.GetOS(),"Win")
OS_Mac = string.match(reaper.GetOS(),"OSX")
r_version = tonumber(r.GetAppVersion():match[[(%d+.%d+)]])

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
if r.APIExists('CF_GetClipboard') == true then
  if r.APIExists('ImGui_CreateContext') == true then
    local imgui_version, reaimgui_version = r.ImGui_GetVersion()
    if TestVersion(reaimgui_version,{0,4,0}) then
      if r.APIExists('JS_Dialog_BrowseForOpenFiles') == true then
        if not OS_Mac or not r_version or r_version >= 6.28 then
-- Colors
rounding = 4.0
background_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.2,1)
background_popup_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.15,1)
framegb_color = r.ImGui_ColorConvertHSVtoRGB(0,0,0.15,1)
default_usercolor = r.ImGui_ColorConvertHSVtoRGB(0,0,0.27)
col_border = r.ImGui_ColorConvertHSVtoRGB(0,0,1,1)
button_back = r.ImGui_ColorConvertHSVtoRGB(0,0,0.27,1)
button_hover = r.ImGui_ColorConvertHSVtoRGB(0,0,0.32,1)
button_active = r.ImGui_ColorConvertHSVtoRGB(0,0,0.4,1)
arm_button_col = r.ImGui_ColorConvertHSVtoRGB(0,0.6,0.4,1)
arm_hover_col = r.ImGui_ColorConvertHSVtoRGB(0,0.6,0.5,1)
arm_active_col = r.ImGui_ColorConvertHSVtoRGB(0,0.6,0.6,1)
circle_col = r.ImGui_ColorConvertHSVtoRGB(0,0,1,1)
circle_border_col = r.ImGui_ColorConvertHSVtoRGB(0,0,0,0.7)
-- Flags
windows_flag = r.ImGui_WindowFlags_NoDecoration()
popup_flags = r.ImGui_WindowFlags_NoMove() | r.ImGui_WindowFlags_NoResize()
picker_flags = r.ImGui_ColorEditFlags_NoAlpha()
             | r.ImGui_ColorEditFlags_NoSidePreview()
             | r.ImGui_ColorEditFlags_PickerHueWheel()
             | r.ImGui_ColorEditFlags_NoInputs()
settings_window_flag = r.ImGui_WindowFlags_AlwaysAutoResize()
                     | r.ImGui_WindowFlags_NoTitleBar()
-- Don't change
FLT_MIN = 1.17549e-38
recalc_colors = true
settings = 0
open_context = r.GetCursorContext2(true)
if open_context and open_context > 0 then
  target_button = open_context + 2
else
  target_button = 2
end
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
trackmanager_title = r.JS_Localize('Track Manager',"common")
regionmanager_title = r.JS_Localize('Region/Marker Manager',"common")
last_left_click = 0
last_right_click = 0
-- Shortcut
keycode =
  {esc=27, enter=13, backspace=8, delete=46, space=32,
  left=37, right=39, down=40, up=38,
  num0=96, num1=97, num2=98, num3=99, num4=100, num5=101, num6=102, num7=103, num8=104, num9=105,
  k1=string.byte('1'), k2=string.byte('2'), k3=string.byte('3'), k4=string.byte('4'), k5=string.byte('5'), k6=string.byte('6'), k7=string.byte('7'), k8=string.byte('8'), k9=string.byte('9'), k0=string.byte('0'),
  z=string.byte('Z'), w=string.byte('W'), c=string.byte('C'), v=string.byte('V'), r=string.byte('R'), e=string.byte('E'), i=string.byte('I'), o=string.byte('O'), p=string.byte('P'), s=string.byte('S')
  }
if OS_Mac then
  mods_names = {'Left-click',--1
                'Cmd',--2
                'Shift',--3
                'Shift+Cmd',--4
                'Opt',--5
                'Cmd+Alt',--6
                'Shift+Opt',--7
                'Shift+Cmd+Opt',--8
                'Ctrl',--9
                'Cmd+Ctrl',--10
                'Shift+Ctrl',--11
                'Shift+Cmd+Ctrl',--12
                'Opt+Ctrl',--13
                'Cmd+Opt+Ctrl',--14
                'Shift+Opt+Ctrl',--15
                'Shift+Cmd+Opt+Ctrl'}--16
else
  mods_names = {'Left-click',--1
                'Ctrl',--2
                'Shift',--3
                'Shift+Ctrl',--4
                'Alt',--5
                'Ctrl+Alt',--6
                'Shift+Alt',--7
                'Shift+Ctrl+Alt',--8
                'Win',--9
                'Win+Ctrl',--10
                'Shift+Win',--11
                'Shift+Win+Ctrl',--12
                'Alt+Win',--13
                'Win+Alt+Ctrl',--14
                'Shift+Alt+Win',--15
                'Shift+Win+Alt+Ctrl'}--16
end
click_actions = {long={' ',--1
                       'Set selected targets to color',--2
                       'Set also children tracks / all takes to color',--3
                       'Insert new target',--4
                       'Insert new named target',--5
                       'Select all targets with this color',--6
                       'Check/Uncheck color for Random/In Order',--7
                       'User color: Add/Edit',--8
                       'User color: Get first selected target color',--9
                       'User color: Paste the hex color from the clipboard',--10
                       'User color: Remove',--11
                       'User color: Clear all'--12
                       },
                 short={' ',--1
                       'Set',--2
                       'Children / All Takes',--3
                       'Insert ',--4
                       'Insert named ',--5
                       'Select',--6
                       'Check/Uncheck',--7
                       'Edit',--7
                       'Get sel',--8
                       'Paste',--9
                       'Remove',--10
                       'Clear all'--11
                       }
                }
popup_menu_usercolor_list = {8,9,10,11,12}
popup_menu_empty_list = {8,9,10,12}
shortcuts_actions = {
            'Quit Color palette',
            'Undo (on Reaper)',
            'Redo (on Reaper)',
            'Save user colors list as',
            'Load user color list file',
            'Run current button action',
            'Run user color button by index',
            'Run default color',
            'Run Random All',
            'Run Random Each',
            'Run In Order',
            'Navigation: Next/Previous target',
            'Edit/Add user color with Picker',
            'Copy hex color under mouse cursor',
            'Paste hex color under mouse cursor',
            'Check/Uncheck color under mouse cursor'
            }
          shortcuts_keys = {
            'Esc',
            mods_names[2]..'+Z',
            mods_names[4]..'+Z',
            mods_names[2]..'+S',
            mods_names[2]..'+O',
            'Enter',
            '1-9',
            '0',
            'R',
            'E',
            'I',
            'Arrows',
            'P',
            mods_names[2]..'+C',
            mods_names[2]..'+V',
            'Spacebar'
            }
click_actions_combostring = ''
for i,action in ipairs(click_actions.long) do
  click_actions_combostring = click_actions_combostring..action..'\31'
end
mods_left = {}
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

reaper.atexit(function()
  ExtState_Save()
  SaveColorFile(last_palette_on_exit)
end)

function CommastringToList(string)
  local list = {}
  local i = 0
  for value in string.gmatch(string,'[^,]+') do
    i = i+1
    value = tonumber(value)
    if not value or value < 1 or value > #click_actions.long then
      value = 1
    end
    table.insert(list,value)
  end
  return list
end

function BoolListToNumber(list)
  local string = '1'
  for i, value in ipairs(list) do
    if type(value) == 'boolean' and value == true then
      string = string..1
    else
      string = string..0
    end
  end
  local num = tonumber(string,2)
  return num
end

function TableResize(list,size,value)
  if #list > size then
    for i=1, #list-size do
      table.remove(list)
    end
  elseif #list < size then
    for i=1, size-#list do
      table.insert(list,value)
    end
  end
  return list
end

function NumberToBoolList(num)
  local list={}
  while num>0 do
    local rest=num%2
    local bool = false
    if rest == 1 then bool = true end
    table.insert(list,1,bool)
    num=(num-rest)/2
  end
  table.remove(list,1)
  return list
end

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
    dock = 0,
    remplace_default = false,
    highlight = true,
    x = -1,
    y = -1,
    checklist_palette = 7,
    checklist_usercolors = 7
    }
  if OS_Mac then
    def.mods_left = '2,4,6,1,7,5,1,1,3,1,1,1,1,1,1,1'
  else
    def.mods_left = '2,4,6,7,3,5,1,1,1,1,1,1,1,1,1,1'
  end
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
                                       or key=='dock'
                                       or key=='x'
                                       or key=='y'
                                       or key=='checklist_palette'
                                       or key=='checklist_usercolors'))
      or (type(conf[key]) ~= 'boolean'and (key=='color_grey'
                                       or key=='vertical'
                                       or key=='setcolor_childs'
                                       or key=='mouse_pos'
                                       or key=='auto_close'
                                       or key=='highlight'
                                       or key=='remplace_default'))
      or (type(conf[key]) ~= 'string' and (key=='mods_left')) then
        conf[key] = def[key]
      end
    else
      conf[key] = def[key]
    end
  end
  -- Get Mods actions list
  mods_left = CommastringToList(conf.mods_left)
  if #mods_left < #mods_names then
    local def_list = CommastringToList(def.mods_left)
    for i=(#mods_left+1), #mods_names do
      table.insert(mods_left,def_list[i])
    end
  end
  -- Get Check list
  checklist_palette = NumberToBoolList(conf.checklist_palette)
  checklist_usercolors = NumberToBoolList(conf.checklist_usercolors)
end

function ExtState_Save()
  -- Get Mods actions string list
  local extstate_mods_left = ''
  for i,action in ipairs(mods_left) do
    extstate_mods_left = extstate_mods_left..action
    if i < #mods_left then
      extstate_mods_left = extstate_mods_left..','
    end
  end
  -- Get Check list
  conf.checklist_palette = BoolListToNumber(checklist_palette)
  conf.checklist_usercolors = BoolListToNumber(checklist_usercolors)
  -- Save
  conf.mods_left = extstate_mods_left
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

function BrowseDialog(num)
  if num == 0 then
    -- Save Dialog
    rv, fileName = r.JS_Dialog_BrowseForSaveFile('Save user palette',UserPalettes_path,'',extension_list)
    if rv == 1 or rv == true then
      if fileName:sub(string.len(fileName)-3,string.len(fileName)) ~= '.txt' then
        fileName = fileName..'.txt'
      end
      SaveColorFile(fileName)
    end
  else
    -- Load Dialog
    local rv, fileName = r.JS_Dialog_BrowseForOpenFiles('Open user palette',UserPalettes_path,'',extension_list,false)
    if rv == 1 then
      usercolors = LoadColorFile(fileName)
    end
  end
end

---------------------------------------------------------------------------------
--- Convert Colors --------------------------------------------------------------
---------------------------------------------------------------------------------

function INTtoHEX(int)
  local hex = string.format('%02x',int)
  hex = string.upper(hex)
  for i = 1, 6-string.len(hex) do
    hex = "0"..hex
  end
  return hex
end

function HEXtoINT(hex)
  hex = tostring(hex):upper():match('%x%x%x%x%x%x')
  if hex then
    int = tonumber(hex,16)
    return int
  else
    return nil
  end
end

---------------------------------------------------------------------------------
--- Others ----------------------------------------------------------------------
---------------------------------------------------------------------------------

function set_window()
  separator_spacing = math.max(conf.spacing,3)
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
    width = math.max(width,80)
  else
    width = width + 16
    heigth = heigth + 39
    width = math.max(width,215)
  end
  if not restart and (conf.mouse_pos == true or conf.x < 0 or conf.y < 0) then
    mouse = {r.GetMousePosition()}
    conf.x = math.floor(mouse[1] - (width/2))
    conf.y = mouse[2]
  end
  if OS_Win then
    conf.y = math.max(conf.y,30)
  else
    conf.y = math.max(conf.y,0)
  end
  conf.x = math.max(conf.x,0)
  button_color = calc_colors()
  ctx = r.ImGui_CreateContext(script_name,width,heigth,conf.x,conf.y,conf.dock,reaper.ImGui_ConfigFlags_NoSavedSettings())
  hwnd = r.ImGui_GetNativeHwnd(ctx)
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
  rv, conf.x, conf.y, ctx_right, ctx_bottom = r.JS_Window_GetClientRect(hwnd)
end

function get_tmp_values()
  for key, value in pairs(conf) do
    if key == 'number_x' or key == 'palette_y' or key == 'user_y' or key == 'size' or key == 'spacing' or key == 'vertical' then
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

function get_clipboard_color()
  local clipboard = r.ImGui_GetClipboardText(ctx)
  local color_int = HEXtoINT(clipboard)
  return color_int
end

function centered_button(windth)
  if conf.vertical == true then
    r.ImGui_NewLine(ctx)
    r.ImGui_SameLine(ctx,(windth-button_size)/2)
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

function main_action(color,palette,id)
  if not color then return end
  if mods_left[mods] == 2 then
    SetColor(color,false)
  elseif mods_left[mods] == 3 then
    SetColor(color,true)
  elseif mods_left[mods] == 4 then
    insert_new_target(color)
  elseif mods_left[mods] == 5 then
    last_color = color
    r.ImGui_OpenPopup(ctx,'Name Input')
  elseif mods_left[mods] == 6 then
    select_target(color)
  elseif mods_left[mods] == 7 then
    if palette and id then
      if palette == 'palette' then
        checklist_palette[id] = not checklist_palette[id]
      elseif palette == 'usercolors' then
        checklist_usercolors[id] = not checklist_usercolors[id]
      end
    end
  end
end

function set_firstuser_defaulttracks()
  if usercolors[1] then
    local count = reaper.CountTracks(0)
    if count > 0 then
      for i=0, count-1 do
        local track =  reaper.GetTrack(0,i)
        local trackcolor = reaper.GetTrackColor(track)
        if trackcolor == 0 then
          local color = r.ImGui_ColorConvertNative(usercolors[1])
          reaper.SetTrackColor(track,color|0x1000000)
        end
      end
    end
  end
end

function get_random_source_list()
  local list = {}
  if conf.randfrom == 1 or (conf.randfrom == 2 and #usercolors == 0) then
    for i, value in ipairs(button_color) do
      table.insert(list,value)
    end
  elseif conf.randfrom == 2 or (conf.randfrom == 1 and #button_color == 0) then
    for i, value in ipairs(usercolors) do
      table.insert(list,value)
    end
  elseif conf.randfrom == 3 then
    for i, bool in ipairs(checklist_palette) do
      if bool == true then
        table.insert(list,button_color[i])
      end
    end
    for i, bool in ipairs(checklist_usercolors) do
      if bool == true then
        table.insert(list,usercolors[i])
      end
    end
    if #list == 0 then
      for i, value in ipairs(button_color) do
        table.insert(list,value)
      end
      for i, value in ipairs(usercolors) do
        table.insert(list,value)
      end
    end
  end
  if #list > 0 then
    return list
  else
    return nil
  end
end

function random_color()
  local list = get_random_source_list()
  if #list > 0 then
    local random = math.random(#list)
    local color = r.ImGui_ColorConvertNative(list[random])
    return color
  else
    return nil
  end
end

function random_color_list(number)
  local random_list = {}
  local source_list = get_random_source_list()
  if #source_list > 0 then
    if not number or number > #source_list then
      number = #source_list
    end
    for i=1, number do
      local random = math.random(#source_list)
      local color = r.ImGui_ColorConvertNative(source_list[random])
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
  else
    count = 0
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
      for i,manager_name in ipairs(list) do
        if MName == manager_name then
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
  if count > 0 then
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
                seltracks_colors[r.ImGui_ColorConvertNative(tmark_color) & 0xffffff]=true
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
        seltracks_colors[r.ImGui_ColorConvertNative(color) & 0xffffff]=true
      end
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

function SetColor(color_int,children)
  if not color_int then return end
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
    color = r.ImGui_ColorConvertNative(color_int)|0x1000000
  elseif color_int == 'Default' then
    color = 0
  elseif color_int == 'Rnd All' then
    color = random_color()|0x1000000
  elseif color_int == 'Rnd Each' then
    if (what == 'Takes' and children == true) or what == 'T Marks' then
      color_list = random_color_list(nil)
    else
      color_list = random_color_list(count)
    end
  elseif color_int == 'In order' then
    color_list = get_random_source_list()
  end
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
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
        color = r.ImGui_ColorConvertNative(color)|0x1000000
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
          if parent and (conf.setcolor_childs == true or children == true) and reaper.IsTrackSelected(parent) == true then
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
          if children == true then
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
          for k=0, reaper.GetNumTakeMarkers(take)-1 do
            local rv, name = reaper.GetTakeMarker(take,k)
            local pos = item_pos+(rv-startoffs)*(1/playrate)
            if (pos > cursor-zoom and pos < cursor+zoom) or (pos > time_sel_start and pos < time_sel_end) then
              if color_int == 'Rnd Each' or color_int == 'In order' then
                j = (j%(#color_list))
                color = color_list[j+1]|0x1000000
              end
              reaper.SetTakeMarker(take,k,name,rv,color)
              j = j + 1
            end
          end
        end
      end
    elseif category == 3 then
      local is_selected, rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color = is_marker_selected(i,what,manager_regions_list)
      if is_selected == true then
        if color ~= 0 then
          reaper.SetProjectMarker3(0,markrgnindexnumber,isrgn,pos,rgnend,name,color)
        else
          reaper.DeleteProjectMarkerByIndex(0,i)
          reaper.AddProjectMarker(0,isrgn,pos,rgnend,name,math.max(i,1))
        end
        j = j + 1
      end
    end
  end
  -- Children tracks color
  if (category == 1 or what == 'tracks_names') and (conf.setcolor_childs == true or children == true) then
    reaper.Main_OnCommand(r.NamedCommandLookup('_SWS_COLCHILDREN'),0)
  end
  close = conf.auto_close
  reaper.Undo_EndBlock(script_name,-1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

function insert_new_target(color_int,name)
  if not color_int then return end
  -- Get Target
  local category, what, count, cursor, time_sel_start, time_sel_end = get_target_infos()
  -- Get Name
  name = name or ''
  -- Get color
  local color
  local color_list
  if type(color_int) == 'number' then
    color = r.ImGui_ColorConvertNative(color_int)|0x1000000
  elseif color_int == 'Default' then
    color = 0
  elseif color_int == 'Rnd All' or color_int == 'Rnd Each' then
    color = random_color()|0x1000000
  elseif color_int == 'In order' then
    if conf.randfrom == 1 then
      if #button_color > 0 then
        color = button_color[1]|0x1000000
      elseif #usercolors > 0 then
        color = usercolors[1]|0x1000000
      else
        return
      end
    else
      if #usercolors > 0 then
        color = usercolors[1]|0x1000000
      elseif #button_color > 0 then
        color = button_color[1]|0x1000000
      else
        return
      end
    end
  end
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local real_target = ''
  if category == 1 then
    reaper.Main_OnCommand(40001,0)
    local track = reaper.GetSelectedTrack(0,0)
    reaper.SetMediaTrackInfo_Value(track,'I_CUSTOMCOLOR',color)
    reaper.GetSetMediaTrackInfo_String(track,'P_NAME',name,true)
    real_target = 'track'
  elseif what == 'Items' or what == 'Takes' then
    reaper.Main_OnCommand(40214,0)
    local item =  reaper.GetSelectedMediaItem(0,0)
    local take = reaper.GetActiveTake(item)
    reaper.SetMediaItemInfo_Value(item,'I_CUSTOMCOLOR',color)
    reaper.GetSetMediaItemTakeInfo_String(take,'P_NAME',name,true)
    real_target = 'midi item'
  elseif what == 'T Marks' then
    if count > 0 then
      for i=0, count-1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        local position = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
        local length = reaper.GetMediaItemInfo_Value(item,'D_LENGTH')
        if cursor >= position and cursor <= position+length then
          local take = reaper.GetActiveTake(item)
          local startoffs = reaper.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS')
          local playrate = reaper.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
          local srcposIn = (cursor-position+startoffs)*playrate
          reaper.SetTakeMarker(take,-1,name,srcposIn,color)
        end
      end
    end
    real_target = 'take marker'
  elseif what == 'Markers' or (what == 'Mk & Rg' and time_sel_start == time_sel_end) then
    reaper.AddProjectMarker2(0,false,cursor,0,name,-1,color)
    real_target = 'marker'
  elseif (what == 'Regions' or what == 'Mk & Rg') and time_sel_start ~= time_sel_end then
    reaper.AddProjectMarker2(0,true,time_sel_start,time_sel_end,name,-1,color)
    real_target = 'region'
  end
  close = conf.auto_close
  reaper.Undo_EndBlock(script_name..' - Insert new '..real_target,-1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

function navigation(direction)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  -- Get Target
  local what = target_button_list[target_button]
  local category = target_category_list[target_button]
  if what == 'Tracks' then
    if direction == 'down' or direction == 'right' then
      -- Go to next track
      reaper.Main_OnCommand(40285,0)
    else
      -- Go to previous track
      reaper.Main_OnCommand(40286,0)
    end
  elseif what == 'Items' or what == 'Takes' then
    if direction == 'left' then
      -- Item navigation: Select and move to previous item
      reaper.Main_OnCommand(40416,0)
    elseif direction == 'right' then
      -- Item navigation: Select and move to next item
      reaper.Main_OnCommand(40417,0)
    elseif direction == 'up' then
      -- Item navigation: Select and move to item in previous track
      reaper.Main_OnCommand(40418,0)
    elseif direction == 'down' then
      -- Item navigation: Select and move to item in next track
      reaper.Main_OnCommand(40419,0)
    end
  elseif what == 'T Marks' then
    reaper.Main_OnCommand(40020,0)
    if direction == 'left' then
      -- 42393
      reaper.Main_OnCommand(42393,0)
    elseif direction == 'right' then
      -- Item: Set cursor to next take marker in selected items
      reaper.Main_OnCommand(42394,0)
    elseif direction == 'up' then
      -- Item navigation: Select and move to item in previous track
      reaper.Main_OnCommand(40418,0)
    elseif direction == 'down' then
      -- Item navigation: Select and move to item in next track
      reaper.Main_OnCommand(40419,0)
    end
  elseif category == 3 then
    local cursor = reaper.GetCursorPosition()
    local rv, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local count = num_markers + num_regions
    if count > 0 then
      for i=0, count-1 do
        if direction == 'left' then
          i = count-1-i
        end
        local rv, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
        if (what=='Mk & Rg' or (not isrgn and what=='Markers') or (isrgn and what=='Regions'))
        and ((direction=='left' and pos<cursor) or (direction=='right' and pos>cursor)) then
          reaper.SetEditCurPos(pos,false,false)
          if isrgn then
            reaper.GetSet_LoopTimeRange(true,false,pos,rgnend,false)
          else
            reaper.Main_OnCommand(40020,0)
          end
          break
        end
      end
    end
  end
  reaper.Undo_EndBlock(script_name..' - Navigation '..direction,-1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

function select_target(color_int)
  -- Get color
  local color
  if type(color_int) == 'number' then
    -- Get native
    color = reaper.ImGui_ColorConvertNative(color_int) + 16^6
  elseif color_int == 'Default' then
    color = 0
  else
    return
  end
  -- Get Target
  local what = target_button_list[target_button]
  local category = target_category_list[target_button]
  local cursor = reaper.GetCursorPosition(0)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  if category == 1 then
    local count = reaper.CountTracks(0)
    if count > 0 then
      reaper.Main_OnCommand(40297,0) -- Unselect all tracks
      for i=0, count-1 do
        local track = reaper.GetTrack(0,i)
        local track_color = reaper.GetTrackColor(track)
        if track_color > 0 then track_color = track_color end
        if track_color == color then
          reaper.SetTrackSelected(track,true)
        end
      end
    end
  elseif what == 'Items' or what == 'Takes' then
    local count = reaper.CountMediaItems(0)
    if count > 0 then
      reaper.Main_OnCommand(40289,0) -- Unselect all items
      for i=0, count-1 do
        local item = reaper.GetMediaItem(0,i)
        local take = reaper.GetActiveTake(item)
        local item_color = reaper.GetDisplayedMediaItemColor2(item,take)
        if item_color > 0 then item_color = item_color end
        if item_color == color then
          reaper.SetMediaItemSelected(item,true)
        end
      end
    end
  elseif what == 'T Marks' then
    local count = reaper.CountMediaItems(0)
    if count > 0 then
      local pos_list = {}
      for i=0, count-1 do
        local item = reaper.GetMediaItem(0,i)
        local take = reaper.GetActiveTake(item)
        local num = reaper.GetNumTakeMarkers(take)
        if num > 0 then
          local position = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
          local length = reaper.GetMediaItemInfo_Value(item,'D_LENGTH')
          local startoffs = reaper.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS')
          local playrate = reaper.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
          for j=0, num-1 do
            local source_pos, name, mark_color = reaper.GetTakeMarker(take,j)
            if mark_color > 0 then mark_color = mark_color end
            if mark_color == color then
              local pos = (position+(startoffs+source_pos)/playrate)
              table.insert(pos_list,pos)
            end
          end
        end
      end
      if #pos_list > 0 then
        reaper.Main_OnCommand(40635,0) -- Time selection: Remove time selection
        table.sort(pos_list)
        for i,pos in ipairs(pos_list) do
          if pos > cursor then
            reaper.SetEditCurPos(pos,false,false)
            break
          elseif i == #pos_list then
            reaper.SetEditCurPos(pos_list[1],false,false)
          end
        end
      end
    end
  elseif category == 3 then
    local rv, num_markers, num_regions = reaper.CountProjectMarkers(0)
    local count = num_markers + num_regions
    if count > 0 then
      local find, first_pos, first_rgnend, first_isrgn
      for i=0, count-1 do
        local rv, isrgn, pos, rgnend, name, markrgnindexnumber, mark_color = reaper.EnumProjectMarkers3(0,i)
        if what == 'Mk & Rg' or (what == 'Markers' and isrgn == false) or (what == 'Regions' and isrgn == true) then
          if mark_color > 0 then mark_color = mark_color end
          if mark_color == color then
            if not first_pos and pos < cursor then
              first_pos = pos
              first_rgnend = rgnend
              first_isrgn = isrgn
            end
            if pos > cursor then
              find = true
              reaper.SetEditCurPos(pos,false,false)
              if isrgn == true then
                reaper.GetSet_LoopTimeRange(true,false,pos,rgnend,false)
              else
                reaper.Main_OnCommand(40635,0) -- Time selection: Remove time selection
              end
              break
            end
          end
        end
      end
      if not find and first_pos then
        reaper.SetEditCurPos(first_pos,false,false)
        if first_isrgn == true then
          reaper.GetSet_LoopTimeRange(true,false,first_pos,first_rgnend,false)
        else
          reaper.Main_OnCommand(40635,0) -- Time selection: Remove time selection
        end
      end
    end
  end
  reaper.Undo_EndBlock(script_name..' - Select '..what,-1)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

---------------------------------------------------------------------------------
--- User colors actions ---------------------------------------------------------
---------------------------------------------------------------------------------

function usercolor_get(i)
  local first_sel_target_color = get_first_sel_target_color()
  if first_sel_target_color and first_sel_target_color ~= 0 then
    first_sel_target_color = r.ImGui_ColorConvertNative(first_sel_target_color) & 0xffffff
    i = math.min(i,#usercolors+1)
    usercolors[i] = first_sel_target_color
  end
end

function usercolor_paste(i)
  local paste_color = get_clipboard_color()
  if paste_color then
    i = math.min(i,#usercolors+1)
    usercolors[i] = paste_color
  end
end

function usercolor_remove(i)
  if i <= #usercolors then
    table.remove(usercolors,i)
  end
end

---------------------------------------------------------------------------------
--- ImGui -----------------------------------------------------------------------
---------------------------------------------------------------------------------

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

function urlOpen(url)
  if OS_Win then
    reaper.ExecProcess('cmd.exe /C start "" "' .. url .. '"', 0)
  elseif OS_Mac then
    reaper.ExecProcess("/usr/bin/open " .. url, 0)
  else
    reaper.ExecProcess('xdg-open "' .. url .. '"', 0)
  end
end

function loop()
  conf.dock = r.ImGui_GetDock(ctx)
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

  -- Close Window ?
  if r.ImGui_IsCloseRequested(ctx) or (not modal_focus and r.ImGui_IsKeyDown(ctx,keycode.esc) and r.ImGui_GetKeyDownDuration(ctx,keycode.esc) == 0) or close == true then
    if settings == 2 then
      r.ImGui_DestroyContext(ctx2)
    end
    get_window_pos()
    r.ImGui_DestroyContext(ctx)
    return
  end

  -- Restart
  if restart then
    if set_tmp_values then
      set_tmp_values = false
      for key,value in pairs(tmp) do
        conf[key] = tmp[key]
      end
    end
    if set_default_sizes then
      set_default_sizes = false
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
      local settings_width = 320
      local settings_heigth = 270
      local x,y
      if conf.dock%2 ~= 0 then
        x = nil
        y = nil
      else
        get_window_pos()
        x = math.max(conf.x,0)
        if OS_Mac then
          y = ctx_bottom - 40
          if y < settings_heigth then
            y = conf.y + settings_heigth + 40
          end
        else
          y = conf.y - settings_heigth - 40
          if y < settings_heigth then
            y = ctx_bottom + 40
          end
        end
      end
      ctx2 = r.ImGui_CreateContext(script_name.." - Settings",settings_width,settings_heigth,x,y,nil,r.ImGui_ConfigFlags_NoSavedSettings())
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
          BrowseDialog(0)
        end
        r.ImGui_SameLine(ctx2)
        if r.ImGui_Button(ctx2,'Load') then
          BrowseDialog(2)
        end
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        rv,conf.setcolor_childs = r.ImGui_Checkbox(ctx2,'Set always color to children',conf.setcolor_childs)
        rv,conf.remplace_default = r.ImGui_Checkbox(ctx2,'Set 1st user to default tracks',conf.remplace_default)
        rv,conf.highlight = r.ImGui_Checkbox(ctx2,'Highlight matching colors',conf.highlight)
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        r.ImGui_Text(ctx2,'Random and In Order from :')
        rv,conf.randfrom = r.ImGui_Combo(ctx2,'##randfrom',conf.randfrom-1,'Palette colors\31User colors\31Check List\31')
        conf.randfrom = conf.randfrom+1
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        rv,conf.mouse_pos = r.ImGui_Checkbox(ctx2,'Open window on mouse position',conf.mouse_pos)
        rv,conf.auto_close = r.ImGui_Checkbox(ctx2,'Quit after apply color',conf.auto_close)
        rv,conf.dock = r.ImGui_CheckboxFlags(ctx2,'Dock window',conf.dock,1)
        if rv then
          r.ImGui_SetDock(ctx,conf.dock)
        end
        r.ImGui_EndTabItem(ctx2)
      end
      if r.ImGui_BeginTabItem(ctx2,'Colors') then
        button_color = calc_colors()
        r.ImGui_PushItemWidth(ctx2,-FLT_MIN)
        rv,conf.color_hue = r.ImGui_SliderDouble(ctx2,'##Hue',conf.color_hue,0.0,1.0,'Initial Hue %.2f')
        r.ImGui_PopItemWidth(ctx2)
        r.ImGui_PushItemWidth(ctx2,150)
        rv,conf.color_saturation_min,conf.color_saturation_max = r.ImGui_DragFloatRange2(ctx2,'Saturation',conf.color_saturation_min,conf.color_saturation_max,0.01,0.0,1.0,'Min %.2f',"Max %.2f",r.ImGui_SliderFlags_AlwaysClamp())
        rv,conf.color_lightness_min,conf.color_lightness_max = r.ImGui_DragFloatRange2(ctx2,'Lightness',conf.color_lightness_min,conf.color_lightness_max,0.01,0.0,1.0,'Min %.2f',"Max %.2f",r.ImGui_SliderFlags_AlwaysClamp())
        r.ImGui_PopItemWidth(ctx2)
        r.ImGui_PushItemWidth(ctx2,-FLT_MIN)
        rv,conf.color_grey = r.ImGui_Checkbox(ctx2,'First col is grey',conf.color_grey)
        r.ImGui_PopItemWidth(ctx2)
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
      if r.ImGui_BeginTabItem(ctx2,'Shortcuts') then
        local TEXT_BASE_WIDTH  = r.ImGui_CalcTextSize(ctx2,'A')
        local combo_width = display_w-r.ImGui_CalcTextSize(ctx2,'Shift+Cmd+Opt+Ctrl')-50
        if r.ImGui_BeginTable(ctx2,'Mouse Modifiers',2,r.ImGui_TableFlags_Borders()) then
          r.ImGui_TableSetupColumn(ctx2,'Modifier')
          r.ImGui_TableSetupColumn(ctx2,'Action')
          r.ImGui_TableHeadersRow(ctx2)
          for mod, name in ipairs(mods_names) do
            if not OS_Win or (OS_Win and name ~= 'Win') then
              r.ImGui_TableNextRow(ctx2)
              if mod == 1 then
                r.ImGui_TableSetColumnIndex(ctx2,0)
                r.ImGui_TableSetColumnIndex(ctx2,1)
              end
              r.ImGui_PushID(ctx2,'Mouse Modifiers'..mod)
              r.ImGui_TableSetColumnIndex(ctx2,0)
              r.ImGui_Text(ctx2,name)
              r.ImGui_TableSetColumnIndex(ctx2,1)
              r.ImGui_PushItemWidth(ctx2,combo_width)
              rv,mods_left[mod] = r.ImGui_Combo(ctx2,'##combo'..name,mods_left[mod]-1,click_actions_combostring)
              r.ImGui_PopItemWidth(ctx2)
              mods_left[mod] = mods_left[mod]+1
              r.ImGui_PopID(ctx2)
            end
          end
          r.ImGui_EndTable(ctx2)
        end
        if r.ImGui_Button(ctx2,'Restore##modifiers') then
          mods_left = CommastringToList(def.mods_left)
        end
        r.ImGui_Spacing(ctx2)
        if r.ImGui_BeginTable(ctx2,'Shortcuts List',2,r.ImGui_TableFlags_Borders()) then
          r.ImGui_TableSetupColumn(ctx2,'Key')
          r.ImGui_TableSetupColumn(ctx2,'Action')
          r.ImGui_TableHeadersRow(ctx2)
          for row, action in ipairs(shortcuts_actions) do
            r.ImGui_TableNextRow(ctx2)
            if row == 1 then
              r.ImGui_TableSetColumnIndex(ctx2,0)
              r.ImGui_TableSetColumnIndex(ctx2,1)
            end
            r.ImGui_PushID(ctx2,'Shortcuts'..row)
            r.ImGui_TableSetColumnIndex(ctx2,0)
            r.ImGui_Text(ctx2,shortcuts_keys[row])
            r.ImGui_TableSetColumnIndex(ctx2,1)
            r.ImGui_Text(ctx2,action)
            r.ImGui_PopID(ctx2)
          end
          r.ImGui_EndTable(ctx2)
        end
        r.ImGui_EndTabItem(ctx2)
      end
      if r.ImGui_BeginTabItem(ctx2,'About') then
        r.ImGui_TextDisabled(ctx2,'Click to open url')
        r.ImGui_Spacing(ctx2)
        r.ImGui_Bullet(ctx2)
        if r.ImGui_Selectable(ctx2,'Discuss in REAPER forum thread') then
          urlOpen("https://forum.cockos.com/showthread.php?t=252219")
        end
        r.ImGui_Bullet(ctx2)
        if r.ImGui_Selectable(ctx2,'Support with a Paypal donation') then
          urlOpen("https://www.paypal.com/donate?hosted_button_id=N5DUAELFWX4DC")
        end
        r.ImGui_EndTabItem(ctx2)
      end
      r.ImGui_EndTabBar(ctx2)
    end

    r.ImGui_PopStyleVar(ctx2)
    r.ImGui_End(ctx2)
    if r.ImGui_IsCloseRequested(ctx2) or restart then
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

  ----------------------------------------------------------------
  -- Get shurtcuts and modifiers
  ----------------------------------------------------------------

  -- Get modifiers
  mods = r.ImGui_GetKeyMods(ctx)+1
  if mods > 1 then
    mods_help = click_actions.short[mods_left[mods]]
    if mods_left[mods] == 4 or mods_left[mods] == 5 then
      local category = target_category_list[target_button]
      if category == 1 then
        mods_help = mods_help..'track'
      elseif category == 2 then
        mods_help = mods_help..'midi item'
      elseif target_button == 6 then
        mods_help = mods_help..'marker'
      elseif target_button == 7 then
        mods_help = mods_help..'region'
      elseif target_button == 8 then
        mods_help = mods_help..'mk/rg'
      end
    end
  else
    mods_help = nil
  end

  -- Get shortcuts
  if not tracksbyname_focus and not modal_focus then
    if r.ImGui_IsKeyPressed(ctx,keycode.z,false) then
      if mods == 2 then
        r.Undo_DoUndo2(0)
      elseif mods == 4 or mods == 6 then
        r.Undo_DoRedo2(0)
      end
    elseif mods == 2 and r.ImGui_IsKeyPressed(ctx,keycode.s,false) then
      BrowseDialog(0)
    elseif mods == 2 and r.ImGui_IsKeyPressed(ctx,keycode.o,false) then
      BrowseDialog(1)
    elseif r.ImGui_IsKeyPressed(ctx,keycode.enter,false) then
      main_action(action_button_list[conf.action_button])
    elseif r.ImGui_IsKeyPressed(ctx,keycode.up,false) then
      navigation('up')
    elseif r.ImGui_IsKeyPressed(ctx,keycode.down,false) then
      navigation('down')
    elseif r.ImGui_IsKeyPressed(ctx,keycode.left,false) then
      navigation('left')
    elseif r.ImGui_IsKeyPressed(ctx,keycode.right,false) then
      navigation('right')
    elseif r.ImGui_IsKeyPressed(ctx,keycode.r,false) then
      main_action('Rnd All')
    elseif r.ImGui_IsKeyPressed(ctx,keycode.e,false) then
      main_action('Rnd Each')
    elseif r.ImGui_IsKeyPressed(ctx,keycode.i,false) then
      main_action('In order')
    else
      for i=0, 9 do
        local numpad = keycode['num'..i]
        local numbers = keycode['k'..i]
        if r.ImGui_IsKeyPressed(ctx,numpad,false) or r.ImGui_IsKeyPressed(ctx,numbers,false) then
          if i > 0 then
            main_action(usercolors[i])
          else
            main_action('Default')
          end
          break
        end
      end
    end
  end

  --
  if tooltip_copy then
    tooltip_copy = tooltip_copy + 1
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_Text(ctx,'Copied')
    r.ImGui_EndTooltip(ctx)
    if tooltip_copy > 20 then tooltip_copy = nil end
  end

  ----------------------------------------------------------------
  -- Header buttons
  ----------------------------------------------------------------

  if conf.vertical == true then
    button_size = 65
  else
    button_size = nil
  end

  centered_button(display_w)
  -- Target utton
  if target_button > 1 then
    tracksbyname_focus = nil
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
    r.ImGui_PopItemWidth(ctx)
    if r.ImGui_IsItemClicked(ctx) and mods > 1 then
      target_button = 2
      last_track_state = target_button
    end
    if r.ImGui_IsItemFocused(ctx) then
      tracksbyname_focus = true
    else
      tracksbyname_focus = nil
    end
    r.ImGui_PopStyleColor(ctx)
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'Popup Menu Target',1)

  if conf.vertical == false then r.ImGui_SameLine(ctx) end
  centered_button(display_w)

  -- Action button
  if not button_size then button_size_default = 64 else button_size_default = button_size end
  if r.ImGui_Button(ctx,action_button_list[conf.action_button],button_size_default) then
    main_action(action_button_list[conf.action_button])
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'Popup Menu Action',1)

  if conf.vertical == false then r.ImGui_SameLine(ctx) end
  centered_button(display_w)

  -- Settings button
  if r.ImGui_Button(ctx,'Settings',button_size) then
    settings = 1
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'Popup Menu Settings',1)

  if conf.vertical == false then r.ImGui_SameLine(ctx) end

  -- Mods help text
  r.ImGui_TextDisabled(ctx,mods_help)

  ----------------------------------------------------------------
  -- Popups
  ----------------------------------------------------------------

  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_PopupBg(),background_color)
  -- Popup Color Picker
  if r.ImGui_BeginPopup(ctx,'Color Editor',popup_flags) then
    open_edit_popup = nil
    if display_w > display_h then
      picker_width = display_h
    else
      picker_width = display_w
    end
    picker_width = picker_width * 0.8
    if picker_width < 70 then picker_width = 70 end
    r.ImGui_PushItemWidth(ctx,picker_width)
    rv, usercolors[selected_button] = r.ImGui_ColorPicker4(ctx,'##ColorPicker',usercolors[selected_button],picker_flags)
    r.ImGui_PopItemWidth(ctx)
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Settings Dock/Undock
  if r.ImGui_BeginPopup(ctx,'Popup Menu Settings',popup_flags) then
    local text
    if conf.dock%2 == 0 then text = 'Dock'
    else text = 'Undock' end
    if r.ImGui_Selectable(ctx,text) then
      conf.dock = conf.dock ~ 1
      r.ImGui_SetDock(ctx,conf.dock)
    end
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Target combo lists
  if r.ImGui_BeginPopup(ctx,'Popup Menu Target',popup_flags) then
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
  if r.ImGui_BeginPopup(ctx,'Popup Menu Action',popup_flags) then
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
  -- Popup User color combo lists
  if r.ImGui_BeginPopup(ctx,'Popup Menu User Color',popup_flags) then
    for i=8, 12 do
      if selected_button > #usercolors and i == 11 then

      else
        local name
        if selected_button > #usercolors and i == 8 then name = 'Add'
        else name = click_actions.short[i] end
        if r.ImGui_Selectable(ctx,name) then
          if i == 8 then
            open_edit_popup = true
          elseif i == 9 then
            usercolor_get(selected_button)
          elseif i == 10 then
            usercolor_paste(selected_button)
          elseif i == 11 then
            usercolor_remove(selected_button)
          elseif i == 12 then
            open_cleanall_popup = true
          end
        end
      end
    end
    r.ImGui_EndPopup(ctx)
  end
  if open_edit_popup then
    r.ImGui_OpenPopup(ctx,'Color Editor')
  elseif open_cleanall_popup then
    r.ImGui_OpenPopup(ctx,'Clear all')
  end
  -- Popup palette combo list
  if r.ImGui_BeginPopup(ctx,'Popup Menu Palette Color',popup_flags) then
    if r.ImGui_Selectable(ctx,'Copy') then
      r.ImGui_SetClipboardText(ctx,INTtoHEX(button_color[selected_button]))
      selected_button = nil
    end
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Name input
  local modal_width = display_w*0.9
  if conf.vertical == true then
    button_size = 48
    r.ImGui_SetNextWindowSize(ctx,modal_width,-1,nil)
  else
    button_size = nil
  end
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_TitleBgActive(),button_hover)
  -- Popup are you sure ?
  if r.ImGui_BeginPopupModal(ctx,'Clear all',nil,popup_flags) then
    local modal_width = r.ImGui_GetWindowSize(ctx)
    modal_focus = true
    open_cleanall_popup = nil
    centered_button(modal_width)
    if r.ImGui_Button(ctx,'Cancel##Clear all',button_size) or r.ImGui_IsKeyDown(ctx,keycode.esc) then
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    if conf.vertical == false then r.ImGui_SameLine(ctx) end
    centered_button(modal_width)
    if r.ImGui_Button(ctx,'Ok##Clear all',button_size) or r.ImGui_IsKeyDown(ctx,keycode.enter) then
      usercolors = {}
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_EndPopup(ctx)
  end
  if not last_color then modal_bg = 0
  else modal_bg = (last_color*256)+150
  end
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ModalWindowDimBg(),modal_bg)
  r.ImGui_SetNextWindowSize(ctx,modal_width,-1,nil)
  if r.ImGui_BeginPopupModal(ctx,'Name Input',nil,popup_flags) then
    r.ImGui_PushItemWidth(ctx,-FLT_MIN)
    if not modal_focus then r.ImGui_SetKeyboardFocusHere(ctx) end
    rv, insert_name = r.ImGui_InputText(ctx,'##Name',insert_name,r.ImGui_InputTextFlags_AutoSelectAll())
    modal_focus = true
    r.ImGui_PopItemWidth(ctx)
    centered_button(modal_width)
    if r.ImGui_Button(ctx,'Cancel##Name Input',button_size) or r.ImGui_IsKeyDown(ctx,keycode.esc) then
      last_color = nil
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    if conf.vertical == false then r.ImGui_SameLine(ctx) end
    centered_button(modal_width)
    if r.ImGui_Button(ctx,'Ok##Name Input',button_size) or r.ImGui_IsKeyDown(ctx,keycode.enter) then
      insert_new_target(last_color,insert_name)
      last_color = nil
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    if conf.vertical == false then r.ImGui_SameLine(ctx) end
    centered_button(modal_width)
    if r.ImGui_Button(ctx,'+##Name Input',button_size) then
      insert_new_target(last_color,insert_name)
    end
    r.ImGui_EndPopup(ctx)
  end
  r.ImGui_PopStyleColor(ctx,3) -- Popup modal colors
  r.ImGui_PopStyleColor(ctx,9) -- Butons colors
  r.ImGui_PopStyleVar(ctx) -- Rounding

  ----------------------------------------------------------------
  -- Bouton Colors
  ----------------------------------------------------------------
  checklist_palette = TableResize(checklist_palette,conf.number_x*conf.palette_y,false)
  checklist_usercolors = TableResize(checklist_usercolors,#usercolors,false)
  local radius = conf.size/6

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
    local highlight = false
    if seltracks_colors[button_color[i]] then
      r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Border(),col_border)
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),1)
      highlight = true
    else
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    local pos,center,draw_list,draw
    if conf.randfrom == 3 and checklist_palette[i] then
      pos = {r.ImGui_GetCursorScreenPos(ctx)}
      center = {pos[1]+(conf.size/2), pos[2]+(conf.size/2)}
      draw_list = r.ImGui_GetWindowDrawList(ctx)
      draw = true
    end

    if r.ImGui_ColorButton(ctx,'##'..i,button_color[i],button_flags,conf.size,conf.size) then
      main_action(button_color[i],'palette',i)
    end
    if r.ImGui_IsItemHovered(ctx) then
      if mods == 2 and r.ImGui_IsKeyPressed(ctx,keycode.c,false) then
        r.ImGui_SetClipboardText(ctx,INTtoHEX(button_color[i]))
        tooltip_copy = 0
      elseif conf.randfrom == 3 and mods == 1 and r.ImGui_IsKeyPressed(ctx,keycode.space,false) then
        checklist_palette[i] = not checklist_palette[i]
      end
    end
    -- Right Click open popup menu
    if r.ImGui_IsItemClicked(ctx,r.ImGui_MouseButton_Right()) then
      selected_button = i
      r.ImGui_OpenPopup(ctx,'Popup Menu Palette Color')
    end

    if draw == true then
      r.ImGui_DrawList_AddCircleFilled(draw_list,center[1],center[2],radius,circle_col)
      r.ImGui_DrawList_AddCircle(draw_list,center[1],center[2],radius,circle_border_col)
    end

    if highlight == true then
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

  if not r.ImGui_IsAnyItemActive(ctx) then
    dragdrop_color = nil
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
    local highlight = false

    if seltracks_colors[usercolors[i]] then
      r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Border(),col_border)
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),1)
      highlight = true
    else
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    local pos,center,draw_list,draw
    if conf.randfrom == 3 and checklist_usercolors[i] then
      pos = {r.ImGui_GetCursorScreenPos(ctx)}
      center = {pos[1]+(conf.size/2), pos[2]+(conf.size/2)}
      draw_list = r.ImGui_GetWindowDrawList(ctx)
      draw = true
    end

    -- Main Button
    if r.ImGui_ColorButton(ctx,'##User'..i,button_user_color,button_flags,conf.size,conf.size) then
      if mods_left[mods] == 8 then
        selected_button = math.min(i,#usercolors+1)
        r.ImGui_OpenPopup(ctx,'Color Editor')
      elseif mods_left[mods] == 9 then
        usercolor_get(i)
      elseif mods_left[mods] == 10 then
        usercolor_paste(i)
      elseif mods_left[mods] == 11 then
        usercolor_remove(i)
      elseif mods_left[mods] == 12 then
        r.ImGui_OpenPopup(ctx,'Clear all')
      else
        if not button_empty then
          main_action(button_user_color,'usercolors',i)
        else
          selected_button = #usercolors+1
          r.ImGui_OpenPopup(ctx,'Color Editor')
        end
      end
    end
    if r.ImGui_IsItemHovered(ctx) then
      if mods == 2 and r.ImGui_IsKeyPressed(ctx,keycode.c,false) and not button_empty then
        r.ImGui_SetClipboardText(ctx,INTtoHEX(usercolors[i]))
        tooltip_copy = 0
      elseif conf.randfrom == 3 and not button_empty and mods == 1 and r.ImGui_IsKeyPressed(ctx,keycode.space,false) then
        checklist_usercolors[i] = not checklist_usercolors[i]
      elseif mods == 2 and r.ImGui_IsKeyPressed(ctx,keycode.v,false) then
        usercolor_paste(i)
      elseif mods == 1 and r.ImGui_IsKeyPressed(ctx,keycode.p,false) then
        selected_button = math.min(i,#usercolors+1)
        r.ImGui_OpenPopup(ctx,'Color Editor')
      elseif not button_empty and (r.ImGui_IsKeyPressed(ctx,keycode.backspace,false) or r.ImGui_IsKeyPressed(ctx,keycode.delete,false)) then
        usercolor_remove(i)
      end
    end

    if draw == true then
      r.ImGui_DrawList_AddCircleFilled(draw_list,center[1],center[2],radius,circle_col)
      r.ImGui_DrawList_AddCircle(draw_list,center[1],center[2],radius,circle_border_col)
    end

    if highlight == true then
      r.ImGui_PopStyleColor(ctx)
      r.ImGui_PopStyleVar(ctx)
    end

    -- Drag and drop source
    if r.ImGui_IsItemActive(ctx) and
        r.ImGui_IsMouseDragging(ctx, r.ImGui_MouseButton_Left()) and
        r.ImGui_BeginDragDropSource(ctx, r.ImGui_DragDropFlags_SourceExtern()) then
      r.ImGui_SetDragDropPayload(ctx,'DnD_Color','user')
      if not dragdrop_color then
        dragdrop_color = usercolors[i]
        table.remove(usercolors,i)
      end
      r.ImGui_ColorButton(ctx,'DnD_Preview',dragdrop_color,r.ImGui_ColorEditFlags_NoAlpha())
      r.ImGui_EndDragDropSource(ctx)
    end
    -- Drag and drop target
    if r.ImGui_BeginDragDropTarget(ctx) then
      local rv,payload = r.ImGui_AcceptDragDropPayload(ctx,'DnD_Color')
      if rv == true then
        if payload == 'user' then payload = dragdrop_color end
        if i > #usercolors then
          table.insert(usercolors,tonumber(payload))
        else
          table.insert(usercolors,i,tonumber(payload))
        end
        dragdrop_color = nil
      end
      r.ImGui_EndDragDropTarget(ctx)
    end

    -- Right Click open popup menu
    if r.ImGui_IsItemClicked(ctx,r.ImGui_MouseButton_Right()) then
      selected_button = math.min(i,#usercolors+1)
      r.ImGui_OpenPopup(ctx,'Popup Menu User Color')
    end
  end
  if conf.user_y > 0 then
    r.ImGui_EndGroup(ctx)
  end

  -- Color buttons pop
  r.ImGui_PopStyleVar(ctx) -- Spacing

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
      r.ShowMessageBox("Please update v0.3.1 or later of  \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
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
else
  r.ShowMessageBox("Please install \"SWS extension\" : https://www.sws-extension.org",script_name,0)
end

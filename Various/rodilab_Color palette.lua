-- @description Color palette
-- @author Rodilab
-- @version 2.21
-- @changelog - Fix behavior of the "quit after apply color" option
-- @provides
--   [data] rodilab_Color palette/color_palette_arm.cur
--   [data] rodilab_Color palette/color_palette_arm_insert.cur
-- @link Forum thread https://forum.cockos.com/showthread.php?t=252219
-- @screenshot Screenshot https://www.rodrigodiaz.fr/prive/color_palette/Color_Palette_v2.jpg
-- @donation Donate via PayPal https://www.paypal.com/donate?hosted_button_id=N5DUAELFWX4DC
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
--   - [SWS Extension](https://www.sws-extension.org)
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
--   - [A] : Switch to Arm mode
--   - Many settings...
--
--   by Rodrigo Diaz (aka Rodilab)

r = reaper
script_name = "Color palette"
OS_Win = string.match(r.GetOS(),"Win")
OS_Mac = string.match(r.GetOS(),"OSX")

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
    if TestVersion(({r.ImGui_GetVersion()})[2],{0,5,1}) then
      if r.APIExists('JS_Dialog_BrowseForOpenFiles') == true then
        if TestVersion(r.GetAppVersion(),{6,28}) then

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.6')
FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()
recalc_colors = true
do
  local open_context = r.GetCursorContext2(true)
  if open_context and open_context > 0 then
    target_button = open_context + 2
  else
    target_button = 2
  end
end
target_category_list = {1,1,2,2,2,3,3,3}
target_button_list = {'Tracks by Name','Tracks','Items','Takes','T Marks','Markers','Regions','Mk & Rg','Arm'}
action_button_list = {'Default','Rnd All','Rnd Each','In order'}
tmp = {}
last_track_state = 2
last_item_state = 3
last_marker_state = 8
seltracks_colors = {}
manager_focus = 0
trackmanager_title = r.JS_Localize('Track Manager',"common")
regionmanager_title = r.JS_Localize('Region/Marker Manager',"common")
arm = {1,1}
last_left_click = 0
last_right_click = 0
target_list = {}
gradient_points = 0
-- Shortcut
keycode =
  {esc=27, enter=13, backspace=8, delete=46, space=32,
  left=37, right=39, down=40, up=38,
  num0=96, num1=97, num2=98, num3=99, num4=100, num5=101, num6=102, num7=103, num8=104, num9=105
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
            'Check/Uncheck color under mouse cursor',
            'Switch to arm mode'
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
            'Spacebar',
            'A'
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
  last_palette_on_exit = script_path..'rodilab_'..script_name..separ..'last_palette_on_exit.txt'
  UserPalettes_path    = script_path..'rodilab_'..script_name..separ
  r.RecursiveCreateDirectory(UserPalettes_path,1)
  arm_cursor =        r.JS_Mouse_LoadCursorFromFile(r.GetResourcePath()..'/Data/rodilab_Color palette/color_palette_arm.cur')
  arm_insert_cursor = r.JS_Mouse_LoadCursorFromFile(r.GetResourcePath()..'/Data/rodilab_Color palette/color_palette_arm_insert.cur')
end

---------------------------------------------------------------------------------
--- Ext State -------------------------------------------------------------------
---------------------------------------------------------------------------------

r.atexit(function()
  if intercept then r.JS_WindowMessage_ReleaseAll() end
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

function CommastringToList2(string)
  local list = {}
  local i = 0
  for value in string.gmatch(string,'[^,]+') do
    i = i+1
    value = math.max(math.min(tonumber(value),1),0)
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
    action_button = 1,
    auto_close = false,
    background = true,
    checklist_palette = 7,
    checklist_usercolors = 7,
    color_grey = true,
    color_hue = 0,
    color_lum = '0.71,0.50',
    color_sat = '0.26,0.50',
    highlight = true,
    mouse_pos = true,
    namestart_char = '',
    number_x = 15,
    palette_y = 3,
    randfrom = 1,
    remplace_default = false,
    setcolor_childs = false,
    spacing = 1,
    user_y = 1,
    vertical = false,
    dock = -1
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
                                       or key=='number_x'
                                       or key=='palette_y'
                                       or key=='user_y'
                                       or key=='spacing'
                                       or key=='randfrom'
                                       or key=='action_button'
                                       or key=='checklist_palette'
                                       or key=='dock'
                                       or key=='checklist_usercolors'))
      or (type(conf[key]) ~= 'boolean'and (key=='color_grey'
                                       or key=='vertical'
                                       or key=='setcolor_childs'
                                       or key=='mouse_pos'
                                       or key=='auto_close'
                                       or key=='highlight'
                                       or key=='background'
                                       or key=='remplace_default'))
      or (type(conf[key]) ~= 'string' and (key=='mods_left')) then
        conf[key] = def[key]
      end
    else
      conf[key] = def[key]
    end
  end
  conf.dock = math.min(conf.dock, -1)
  -- Get sat/lum list
  sat = CommastringToList2(conf.color_sat)
  lum = CommastringToList2(conf.color_lum)
  -- Get old keys
  if r.HasExtState(extstate_id,'color_saturation_min') and r.HasExtState(extstate_id,'color_saturation_max') and r.HasExtState(extstate_id,'color_lightness_min') and r.HasExtState(extstate_id,'color_lightness_max') then
    sat = {tonumber(r.GetExtState(extstate_id,'color_saturation_min')),tonumber(r.GetExtState(extstate_id,'color_saturation_max'))}
    lum = {tonumber(r.GetExtState(extstate_id,'color_lightness_max')),tonumber(r.GetExtState(extstate_id,'color_lightness_min'))}
    r.DeleteExtState(extstate_id,'color_saturation_min',true)
    r.DeleteExtState(extstate_id,'color_saturation_max',true)
    r.DeleteExtState(extstate_id,'color_lightness_min',true)
    r.DeleteExtState(extstate_id,'color_lightness_max',true)
  end
  local old_keys = {'size','x','y','namestart'}
  for i, key in ipairs(old_keys) do
    if r.HasExtState(extstate_id,key) then
      r.DeleteExtState(extstate_id,key,true)
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
  -- Get sat/lum list
  conf.color_lum = ''
  conf.color_sat = ''
  for i, value in ipairs(lum) do
    if i > 1 then
      conf.color_lum = conf.color_lum..','
      conf.color_sat = conf.color_sat..','
    end
    conf.color_lum = conf.color_lum..lum[i]
    conf.color_sat = conf.color_sat..sat[i]
  end
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
  conf.color_sat = def.color_sat
  conf.color_lum = def.color_lum
  conf.color_grey = def.color_grey
  sat = CommastringToList2(conf.color_sat)
  lum = CommastringToList2(conf.color_lum)
end

function restore_default_sizes()
  conf.number_x = def.number_x
  conf.palette_y = def.palette_y
  conf.user_y = def.user_y
  conf.spacing = def.spacing
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
  local extension_list = "Text file (.txt)\0*.txt\0\0"
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
  button_color = calc_colors()
  ctx = r.ImGui_CreateContext(script_name, r.ImGui_ConfigFlags_DockingEnable())
  font = r.ImGui_CreateFont('Arial',12)
  r.ImGui_AttachFont(ctx,font)
  if conf.mouse_pos then
    cur_x, cur_y = r.GetMousePosition()
    cur_x, cur_y = r.ImGui_PointConvertNative(ctx, cur_x, cur_y)
  end
end

function GetCellSize(width, heigth)
  local x = conf.vertical and (conf.palette_y + conf.user_y) or conf.number_x
  local y = conf.vertical and conf.number_x or (conf.palette_y + conf.user_y)
  local marge_side = 16
  local marge_top  = conf.vertical and 115 or 55
  if conf.user_y > 0 and conf.palette_y > 0 then
    if conf.vertical then
      marge_side = marge_side + (separator_spacing * 2 + 1)
    else
      marge_top  = marge_top  + (separator_spacing * 2 + 1)
    end
  end
  local size_1 = (width  - marge_side - (x-1) * conf.spacing) / x
  local size_2 = (heigth - marge_top  - (y-1) * conf.spacing) / y
  return math.floor(math.min(size_1,size_2))
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

function calc_colors()
  local color_table = {}
  local line = -1
  for i=1, conf.number_x*conf.palette_y do
    if (i-1) % conf.number_x == 0 then
      line = line + 1
    end
    local hue
    if not conf.color_grey then
      hue = (1/(conf.number_x))*((i-1)%conf.number_x)+conf.color_hue
    else
      if (i-1)%conf.number_x == 0 then
        hue = 0
      else
        hue = (1/(conf.number_x-1))*((i-2)%conf.number_x)+conf.color_hue
      end
    end
    local lightness = lum[1]
    local saturation = sat[1]
    if conf.palette_y > 1 then
      for i=2, #lum do
        local line_scale = line/(conf.palette_y-1)
        if line_scale <= (1/(#lum-1))*(i-1) then
          line_scale = (line_scale -  (i-2)/(#lum-1) ) * (#lum-1)
          lightness  = (line_scale*(lum[i]-lum[i-1]))+lum[i-1]
          saturation = (line_scale*(sat[i]-sat[i-1]))+sat[i-1]
          break
        end
      end
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
  if target_button == 9 then
    if palette and id then
      arm = {palette,id}
    end
  else
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
    elseif mods_left[mods] == 7 and target_button ~= 9 then
      if palette and id then
        if palette == 0 then
          checklist_palette[id] = not checklist_palette[id]
        elseif palette == 1 then
          checklist_usercolors[id] = not checklist_usercolors[id]
        end
      end
    end
  end
end

function set_firstuser_defaulttracks()
  if usercolors[1] then
    local count = r.CountTracks(0)
    if count > 0 then
      for i=0, count-1 do
        local track =  r.GetTrack(0,i)
        local trackcolor = r.GetTrackColor(track)
        if trackcolor == 0 then
          local color = r.ImGui_ColorConvertNative(usercolors[1])
          r.SetTrackColor(track,color|0x1000000)
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
    count = r.CountSelectedTracks(0)
  elseif what == 'Tracks by Name' then
    count = r.CountTracks(0)
  elseif category == 2 then
    count = r.CountSelectedMediaItems(0)
  elseif category == 3 then
    local rv, num_markers, num_regions = r.CountProjectMarkers(0)
    count = num_markers + num_regions
  else
    count = 0
  end
  if category == 3 or what == 'T Marks' then
    time_sel_start, time_sel_end = r.GetSet_LoopTimeRange(false,false,0,0,false)
    cursor = r.GetCursorPosition()
  end
  return category, what, count, cursor, time_sel_start, time_sel_end
end

function is_marker_selected(i,what,list)
  local rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color = r.EnumProjectMarkers3(0,i)
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
          track = r.GetTrack(0,manager_tracks_list[i+1]-1)
        else
          track = r.GetSelectedTrack(0,i)
        end
        if track then
          color = r.GetMediaTrackInfo_Value(track,"I_CUSTOMCOLOR")
        else
          break
        end
      elseif category == 2 then
        local item = r.GetSelectedMediaItem(0,i)
        if what == 'Items' then
          color = r.GetMediaItemInfo_Value(item,"I_CUSTOMCOLOR")
        else
          local take = r.GetActiveTake(item)
          if what == 'Takes' then
            color = r.GetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR")
          elseif what == 'T Marks' then
            for j=0, r.GetNumTakeMarkers(take)-1 do
              local rv, name, tmark_color = r.GetTakeMarker(take,j)
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
        track = r.GetTrack(0,manager_tracks_list[i+1]-1)
      else
        track = r.GetSelectedTrack(0,i)
      end
      color = r.GetMediaTrackInfo_Value(track,"I_CUSTOMCOLOR")
      return color
    elseif category == 2 then
      local item = r.GetSelectedMediaItem(0,i)
      if what == 'Items' then
        color = r.GetMediaItemInfo_Value(item,"I_CUSTOMCOLOR")
        return color
      else
        local take = r.GetActiveTake(item)
        if what == 'Takes' then
          color = r.GetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR")
          return color
        elseif what == 'T Marks' then
          for j=0, r.GetNumTakeMarkers(take)-1 do
            local rv, name, tmark_color = r.GetTakeMarker(take,j)
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
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
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
          track = r.GetTrack(0,manager_tracks_list[i+1]-1)
          set = true
        else
          track = r.GetSelectedTrack(0,i)
          local parent = r.GetParentTrack(track)
          if parent and (conf.setcolor_childs == true or children == true) and r.IsTrackSelected(parent) == true then
            set = false
          else
            set = true
          end
        end
      elseif what == 'Tracks by Name' then
        track = r.GetTrack(0,i)
        local retval, trackname = r.GetTrackName(track)
        if retval == true then
          local trackname = string.sub(trackname,1,string.len(conf.namestart_char))
          if trackname == conf.namestart_char then
            set = true
          end
        end
      end
      if set == true then
        r.SetMediaTrackInfo_Value(track,"I_CUSTOMCOLOR",color)
        j = j + 1
      end
    elseif category == 2 then
      local item = r.GetSelectedMediaItem(0,i)
      if what == 'Items' then
        r.SetMediaItemInfo_Value(item,"I_CUSTOMCOLOR",color)
        j = j + 1
        -- Set default colors for all takes
        r.Main_OnCommand(41337,0)
      else
        local take = r.GetActiveTake(item)
        if what == 'Takes' then
          if children == true then
            for k = 0, r.CountTakes(item)-1 do
              if color_int == 'Rnd Each' or color_int == 'In order' then
                j = (j%(#color_list))
                color = color_list[j+1]|0x1000000
              end
              local take = r.GetMediaItemTake(item,k)
              r.SetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR",color)
              j = j + 1
            end
          else
            r.SetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR",color)
            j = j + 1
          end
        elseif what == 'T Marks' then
          local zoom = (1/r.GetHZoomLevel())*2
          local item_pos = r.GetMediaItemInfo_Value(item,"D_POSITION")
          local startoffs = r.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")
          local playrate = r.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE")
          for k=0, r.GetNumTakeMarkers(take)-1 do
            local rv, name = r.GetTakeMarker(take,k)
            local pos = item_pos+(rv-startoffs)*(1/playrate)
            if (pos > cursor-zoom and pos < cursor+zoom) or (pos > time_sel_start and pos < time_sel_end) then
              if color_int == 'Rnd Each' or color_int == 'In order' then
                j = (j%(#color_list))
                color = color_list[j+1]|0x1000000
              end
              r.SetTakeMarker(take,k,name,rv,color)
              j = j + 1
            end
          end
        end
      end
    elseif category == 3 then
      local is_selected, rv, isrgn, pos, rgnend, name, markrgnindexnumber, tmp_color = is_marker_selected(i,what,manager_regions_list)
      if is_selected == true then
        if color ~= 0 then
          r.SetProjectMarker3(0,markrgnindexnumber,isrgn,pos,rgnend,name,color)
        else
          r.DeleteProjectMarkerByIndex(0,i)
          r.AddProjectMarker(0,isrgn,pos,rgnend,name,math.max(i,1))
        end
        j = j + 1
      end
    end
  end
  -- Children tracks color
  if (category == 1 or what == 'tracks_names') and (conf.setcolor_childs == true or children == true) then
    r.Main_OnCommand(r.NamedCommandLookup('_SWS_COLCHILDREN'),0)
  end
  close = conf.auto_close
  r.Undo_EndBlock(script_name,-1)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
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
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  local real_target = ''
  if category == 1 then
    r.Main_OnCommand(40001,0)
    local track = r.GetSelectedTrack(0,0)
    r.SetMediaTrackInfo_Value(track,'I_CUSTOMCOLOR',color)
    r.GetSetMediaTrackInfo_String(track,'P_NAME',name,true)
    real_target = 'track'
  elseif what == 'Items' or what == 'Takes' then
    r.Main_OnCommand(40214,0)
    local item =  r.GetSelectedMediaItem(0,0)
    local take = r.GetActiveTake(item)
    r.SetMediaItemInfo_Value(item,'I_CUSTOMCOLOR',color)
    r.GetSetMediaItemTakeInfo_String(take,'P_NAME',name,true)
    real_target = 'midi item'
  elseif what == 'T Marks' then
    if count > 0 then
      for i=0, count-1 do
        local item = r.GetSelectedMediaItem(0,i)
        local position = r.GetMediaItemInfo_Value(item,'D_POSITION')
        local length = r.GetMediaItemInfo_Value(item,'D_LENGTH')
        if cursor >= position and cursor <= position+length then
          local take = r.GetActiveTake(item)
          local startoffs = r.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS')
          local playrate = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
          local srcposIn = (cursor-position+startoffs)*playrate
          r.SetTakeMarker(take,-1,name,srcposIn,color)
        end
      end
    end
    real_target = 'take marker'
  elseif what == 'Markers' or (what == 'Mk & Rg' and time_sel_start == time_sel_end) then
    r.AddProjectMarker2(0,false,cursor,0,name,-1,color)
    real_target = 'marker'
  elseif (what == 'Regions' or what == 'Mk & Rg') and time_sel_start ~= time_sel_end then
    r.AddProjectMarker2(0,true,time_sel_start,time_sel_end,name,-1,color)
    real_target = 'region'
  end
  close = conf.auto_close
  r.Undo_EndBlock(script_name..' - Insert new '..real_target,-1)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function navigation(direction)
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  -- Get Target
  local what = target_button_list[target_button]
  local category = target_category_list[target_button]
  if what == 'Tracks' then
    if direction == 'down' or direction == 'right' then
      -- Go to next track
      r.Main_OnCommand(40285,0)
    else
      -- Go to previous track
      r.Main_OnCommand(40286,0)
    end
  elseif what == 'Items' or what == 'Takes' then
    if direction == 'left' then
      -- Item navigation: Select and move to previous item
      r.Main_OnCommand(40416,0)
    elseif direction == 'right' then
      -- Item navigation: Select and move to next item
      r.Main_OnCommand(40417,0)
    elseif direction == 'up' then
      -- Item navigation: Select and move to item in previous track
      r.Main_OnCommand(40418,0)
    elseif direction == 'down' then
      -- Item navigation: Select and move to item in next track
      r.Main_OnCommand(40419,0)
    end
  elseif what == 'T Marks' then
    r.Main_OnCommand(40020,0)
    if direction == 'left' then
      -- 42393
      r.Main_OnCommand(42393,0)
    elseif direction == 'right' then
      -- Item: Set cursor to next take marker in selected items
      r.Main_OnCommand(42394,0)
    elseif direction == 'up' then
      -- Item navigation: Select and move to item in previous track
      r.Main_OnCommand(40418,0)
    elseif direction == 'down' then
      -- Item navigation: Select and move to item in next track
      r.Main_OnCommand(40419,0)
    end
  elseif category == 3 then
    local cursor = r.GetCursorPosition()
    local rv, num_markers, num_regions = r.CountProjectMarkers(0)
    local count = num_markers + num_regions
    if count > 0 then
      for i=0, count-1 do
        if direction == 'left' then
          i = count-1-i
        end
        local rv, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers(i)
        if (what=='Mk & Rg' or (not isrgn and what=='Markers') or (isrgn and what=='Regions'))
        and ((direction=='left' and pos<cursor) or (direction=='right' and pos>cursor)) then
          r.SetEditCurPos(pos,false,false)
          if isrgn then
            r.GetSet_LoopTimeRange(true,false,pos,rgnend,false)
          else
            r.Main_OnCommand(40020,0)
          end
          break
        end
      end
    end
  end
  r.Undo_EndBlock(script_name..' - Navigation '..direction,-1)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function select_target(color_int)
  -- Get color
  local color
  if type(color_int) == 'number' then
    -- Get native
    color = r.ImGui_ColorConvertNative(color_int) + 16^6
  elseif color_int == 'Default' then
    color = 0
  else
    return
  end
  -- Get Target
  local what = target_button_list[target_button]
  local category = target_category_list[target_button]
  local cursor = r.GetCursorPosition(0)
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  if category == 1 then
    local count = r.CountTracks(0)
    if count > 0 then
      r.Main_OnCommand(40297,0) -- Unselect all tracks
      for i=0, count-1 do
        local track = r.GetTrack(0,i)
        local track_color = r.GetTrackColor(track)
        if track_color > 0 then track_color = track_color end
        if track_color == color then
          r.SetTrackSelected(track,true)
        end
      end
    end
  elseif what == 'Items' or what == 'Takes' then
    local count = r.CountMediaItems(0)
    if count > 0 then
      r.Main_OnCommand(40289,0) -- Unselect all items
      for i=0, count-1 do
        local item = r.GetMediaItem(0,i)
        local take = r.GetActiveTake(item)
        local item_color = r.GetDisplayedMediaItemColor2(item,take)
        if item_color > 0 then item_color = item_color end
        if item_color == color then
          r.SetMediaItemSelected(item,true)
        end
      end
    end
  elseif what == 'T Marks' then
    local count = r.CountMediaItems(0)
    if count > 0 then
      local pos_list = {}
      for i=0, count-1 do
        local item = r.GetMediaItem(0,i)
        local take = r.GetActiveTake(item)
        local num = r.GetNumTakeMarkers(take)
        if num > 0 then
          local position = r.GetMediaItemInfo_Value(item,'D_POSITION')
          local length = r.GetMediaItemInfo_Value(item,'D_LENGTH')
          local startoffs = r.GetMediaItemTakeInfo_Value(take,'D_STARTOFFS')
          local playrate = r.GetMediaItemTakeInfo_Value(take,'D_PLAYRATE')
          for j=0, num-1 do
            local source_pos, name, mark_color = r.GetTakeMarker(take,j)
            if mark_color > 0 then mark_color = mark_color end
            if mark_color == color then
              local pos = (position+(startoffs+source_pos)/playrate)
              table.insert(pos_list,pos)
            end
          end
        end
      end
      if #pos_list > 0 then
        r.Main_OnCommand(40635,0) -- Time selection: Remove time selection
        table.sort(pos_list)
        for i,pos in ipairs(pos_list) do
          if pos > cursor then
            r.SetEditCurPos(pos,false,false)
            break
          elseif i == #pos_list then
            r.SetEditCurPos(pos_list[1],false,false)
          end
        end
      end
    end
  elseif category == 3 then
    local rv, num_markers, num_regions = r.CountProjectMarkers(0)
    local count = num_markers + num_regions
    if count > 0 then
      local find, first_pos, first_rgnend, first_isrgn
      for i=0, count-1 do
        local rv, isrgn, pos, rgnend, name, markrgnindexnumber, mark_color = r.EnumProjectMarkers3(0,i)
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
              r.SetEditCurPos(pos,false,false)
              if isrgn == true then
                r.GetSet_LoopTimeRange(true,false,pos,rgnend,false)
              else
                r.Main_OnCommand(40635,0) -- Time selection: Remove time selection
              end
              break
            end
          end
        end
      end
      if not find and first_pos then
        r.SetEditCurPos(first_pos,false,false)
        if first_isrgn == true then
          r.GetSet_LoopTimeRange(true,false,first_pos,first_rgnend,false)
        else
          r.Main_OnCommand(40635,0) -- Time selection: Remove time selection
        end
      end
    end
  end
  r.Undo_EndBlock(script_name..' - Select '..what,-1)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
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
--- Arm -------------------------------------------------------------------------
---------------------------------------------------------------------------------

function Arm_SetCursor(arm_context)
  if arm_context then
    local pos = {r.GetMousePosition()}
    local windowUnderMouse = r.JS_Window_FromPoint(pos[1],pos[2])
    if windowUnderMouse then 
      if mods_left[mods] == 4 or mods_left[mods] == 5 then
        if arm_insert_cursor then
          r.JS_Mouse_SetCursor(arm_insert_cursor)
        else
          arm_tooltip = true
          r.TrackCtl_SetToolTip('Color palette: insert',pos[1]+10,pos[2]+(OS_Mac and 10 or -10),true)
        end
      else
        if arm_cursor then
          r.JS_Mouse_SetCursor(arm_cursor)
        else
          arm_tooltip = true
          r.TrackCtl_SetToolTip('Color palette',pos[1]+10,pos[2]+(OS_Mac and 10 or -10),true)
        end
      end
      r.JS_WindowMessage_Intercept(windowUnderMouse,"WM_SETCURSOR",false)
      r.JS_WindowMessage_Intercept(windowUnderMouse,"WM_MOUSEFIRST",false)
      r.JS_WindowMessage_Intercept(windowUnderMouse,"WM_LBUTTONDOWN",false)
      r.JS_WindowMessage_Intercept(windowUnderMouse,"WM_LBUTTONUP",false)
      intercept = true
    end
    return
  end
  if intercept then
    intercept = false
    r.JS_WindowMessage_ReleaseAll()
  end
  if arm_tooltip then
    r.TrackCtl_SetToolTip('',0,0,true)
  end
end

function Arm_SetColor(color,context,data,sel_in,sel_out)
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  if context == 'track' then
    r.SetMediaTrackInfo_Value(data,"I_CUSTOMCOLOR",color)
    -- Children tracks color
    if conf.setcolor_childs == true or mods_left[mods] == 3 then
      r.SetOnlyTrackSelected(data)
      r.Main_OnCommand(r.NamedCommandLookup('_SWS_COLCHILDREN'),0)
    end
  elseif context == 'item' then
    r.SetMediaItemInfo_Value(data,"I_CUSTOMCOLOR",color)
  elseif context == 'marker' or context == 'region' then
    local rv, num_markers, num_regions = r.CountProjectMarkers(0)
    local count = num_markers + num_regions
    local zoom = (1/r.GetHZoomLevel())*15
    if count > 0 then
      for i=0, count-1 do
        local rv, isrgn, pos, rgnend, name, markrgnindexnumber = r.EnumProjectMarkers2(0,i)
        if context == 'marker' and isrgn == false and ((pos >= sel_in and pos <= sel_out) or (sel_in==sel_out and pos >= sel_in-zoom and pos <= sel_in)) then
          r.SetProjectMarker3(0,markrgnindexnumber,isrgn,pos,rgnend,name,color)
        elseif context == 'region' and isrgn == true and 
                          ((pos >= sel_in and pos <= sel_out)
                          or
                          (rgnend >= sel_in and rgnend <= sel_out)
                          or
                          (sel_in >= pos and sel_in <= rgnend)) then
          r.SetProjectMarker3(0,markrgnindexnumber,isrgn,pos,rgnend,name,color)
        end
      end
    end
  end
  r.Undo_EndBlock(script_name,-1)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function Arm_InsertNew(color,context,pos_1)
  r.Undo_BeginBlock()
  r.PreventUIRefresh(1)
  if context == 'track' then
    local track = r.BR_GetMouseCursorContext_Track()
    local ip = r.GetMediaTrackInfo_Value(track,'IP_TRACKNUMBER')
    r.InsertTrackAtIndex(ip,true)
    local new_track = r.GetTrack(0,ip)
    r.SetMediaTrackInfo_Value(new_track,'I_CUSTOMCOLOR',color)
  elseif context == 'item' then
    -- Nothing
  elseif context == 'marker' then
    local pos =  r.BR_GetMouseCursorContext_Position()
    if not pos then return end
    r.AddProjectMarker2(0,false,pos,0,'',-1,color)
  elseif context == 'region' then
    local pos_2 = r.BR_GetMouseCursorContext_Position()
    if not pos_1 or not pos_2 then return end
    r.AddProjectMarker2(0,true,math.min(pos_1,pos_2),math.max(pos_1,pos_2),'',-1,color)
  end
  r.Undo_EndBlock(script_name,-1)
  r.PreventUIRefresh(-1)
  r.UpdateArrange()
end

function Arm_GetContext(arm_context)
  local left_click = r.JS_Mouse_GetState(1)
  if left_click == 1 and last_left_click == 0 then
    if mods_left[mods] == 4 or mods_left[mods] == 5 then
      insert_mode = true
    else
      insert_mode = false
    end
    target_list = {}
    first_arm_context = nil
    color = nil
    if not arm_context then return end
    -- Get native color
    if arm[1] == 0 then color = button_color[arm[2]]
    elseif arm[1] == 1 then color = usercolors[arm[2]] end
    if not color then return end
    color = r.ImGui_ColorConvertNative(color) + 16^6
    -- Save context
    first_arm_context = arm_context
    if arm_context == 'region' or arm_context == 'marker' then
      arm_pos_in = r.BR_GetMouseCursorContext_Position()
      arm_pos_out = arm_pos_in
    end
    -- Insert mode
    if insert_mode and arm_context ~= 'region' then
      Arm_InsertNew(color,arm_context)
    end
  end
  if left_click == 1 and first_arm_context then
    -- Set time selection
    if first_arm_context == 'marker' or first_arm_context == 'region' then
      arm_pos_out = r.BR_GetMouseCursorContext_Position() or arm_pos_out
      r.GetSet_LoopTimeRange(true,false,math.min(arm_pos_in,arm_pos_out),math.max(arm_pos_in,arm_pos_out),false)
    elseif not insert_mode then
      if first_arm_context == 'track' then
        local track = r.BR_GetMouseCursorContext_Track()
        if track and not target_list[track] then
          Arm_SetColor(color,first_arm_context,track)
          target_list[track] = true
        end
      elseif first_arm_context == 'item' then
        local item = r.BR_GetMouseCursorContext_Item()
        if item and not target_list[item] then
          Arm_SetColor(color,first_arm_context,item)
          target_list[item] = true
        end
      end
    end
  elseif left_click == 0 and last_left_click == 1 and first_arm_context then
    if first_arm_context == 'region' and insert_mode then
      Arm_InsertNew(color,first_arm_context,arm_pos_in)
    elseif (first_arm_context == 'marker' or first_arm_context == 'region') and not insert_mode then
      Arm_SetColor(color,first_arm_context,nil,math.min(arm_pos_in,arm_pos_out),math.max(arm_pos_in,arm_pos_out))
    end
    if conf.auto_close then close = true end
  end
  last_left_click = left_click
end

---------------------------------------------------------------------------------
--- Get target on click ---------------------------------------------------------
---------------------------------------------------------------------------------

function get_last_context()
  local left_click = r.JS_Mouse_GetState(1)
  local right_click = r.JS_Mouse_GetState(2)
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
      if hwnd_focus then
        local hwnd_focus_parent = r.JS_Window_GetParent(hwnd_focus)
        if hwnd_focus_parent then
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
  last_left_click = left_click
  last_right_click = right_click
end

function DrawGear(x,y,size,color)
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
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
    local p1_x = x + math.sin(angle+angle_1) * ext_radius
    local p1_y = y + math.cos(angle+angle_1) * ext_radius
    local p2_x = x + math.sin(angle-angle_1) * ext_radius
    local p2_y = y + math.cos(angle-angle_1) * ext_radius
    local p3_x = x + math.sin(angle-angle_2) * size
    local p3_y = y + math.cos(angle-angle_2) * size
    local p4_x = x + math.sin(angle+angle_2) * size
    local p4_y = y + math.cos(angle+angle_2) * size
    r.ImGui_DrawList_AddQuadFilled(draw_list, p1_x, p1_y, p2_x, p2_y, p3_x, p3_y, p4_x, p4_y, color)
  end
  r.ImGui_DrawList_AddCircle(draw_list, x, y, (int_radius+ext_radius)/2, color, 0, ext_radius-int_radius+1)
end

---------------------------------------------------------------------------------
--- Settings --------------------------------------------------------------------
---------------------------------------------------------------------------------

function TextURL(ctx,text,url)
  local pos = {r.ImGui_GetCursorScreenPos(ctx)}
  local text_size = {r.ImGui_CalcTextSize(ctx,text,0,0)}
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
  r.ImGui_InvisibleButton(ctx, text, text_size[1], r.ImGui_GetTextLineHeightWithSpacing(ctx) )
  if r.ImGui_IsItemClicked(ctx, r.ImGui_MouseButton_Left()) then
    r.CF_ShellExecute(url)
  end
  local color = 0x99C5FFff
  if r.ImGui_IsItemHovered(ctx) then color = 0xffffffff end
  r.ImGui_DrawList_AddText(draw_list, pos[1], pos[2], color, text )
  pos[2] = pos[2] + r.ImGui_GetTextLineHeight(ctx)
  r.ImGui_DrawList_AddLine(draw_list, pos[1], pos[2], pos[1]+text_size[1], pos[2], color, 1)
end

function myGradrient(ctx,label,h,s,v,size)
  if type(h)~='number' then h = 0 else h = math.max(math.min(h,1),0) end
  if type(size)~='number' then size = 100 else size = math.max(size,50) end
  local count_points
  if type(s)=='table' and type(v)=='table' and math.min(#s,#v) >= 2 then
    count_points = math.min(#s,#v)
  else
    s, v, count_points = {0.2,0.9}, {0.9,0.2}, 2
  end
  local pos = {r.ImGui_GetCursorScreenPos(ctx)}
  local draw_list = r.ImGui_GetWindowDrawList(ctx)
  local mouse_delta = {r.ImGui_GetMouseDelta(ctx)}
  local radius = 4
  r.ImGui_InvisibleButton(ctx,label,size,size)
  local value_changed = false
  local is_active = r.ImGui_IsItemActive(ctx)
  local is_hovered = r.ImGui_IsItemHovered(ctx)
  if is_active then
    local mouse_pos = {r.ImGui_GetMousePos(ctx)}
    local mouse_pos_in_canvas = {math.min(math.max(mouse_pos[1]-pos[1],0),size), math.min(math.max(mouse_pos[2]-pos[2],0),size)}
    if not myGradient_sel_point then
      for i=1, count_points do
        if mouse_pos_in_canvas[1] > s[i]*size-radius and mouse_pos_in_canvas[1] < s[i]*size+radius
        and mouse_pos_in_canvas[2] > (1-v[i])*size-radius and mouse_pos_in_canvas[2] < (1-v[i])*size+radius then
          myGradient_sel_point = i
          break
        end
      end
    end
    if myGradient_sel_point then
      s[myGradient_sel_point] = math.floor(mouse_pos_in_canvas[1]/size*100)/100
      v[myGradient_sel_point] = math.floor((1-(mouse_pos_in_canvas[2]/size))*100)/100
      value_changed = true
    end
  else
    myGradient_sel_point = false
  end
  local white = 0xffffffff
  local black = 0x000000ff
  local color = r.ImGui_ColorConvertHSVtoRGB(h,1,1,1)
  r.ImGui_DrawList_AddRectFilledMultiColor(draw_list, pos[1], pos[2], pos[1] + size, pos[2] + size, white, color, color, white)
  r.ImGui_DrawList_AddRectFilledMultiColor(draw_list, pos[1], pos[2], pos[1] + size, pos[2] + size, 0, 0, black, black)
  for i = 1, count_points do
    r.ImGui_DrawList_AddCircleFilled(draw_list, pos[1]+s[i]*size, pos[2]+size-v[i]*size, radius, white)
    if i > 1 then
      r.ImGui_DrawList_AddLine(draw_list, pos[1]+s[i-1]*size, pos[2]+size-v[i-1]*size, pos[1]+s[i]*size, pos[2]+size-v[i]*size,white)
    end
  end
  return value_changed, s, v
end

function ImGuiContent_Settings()
  local rv
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),4)

  -- Content
  if r.ImGui_BeginTabBar(ctx,'Tabbar') then
    if r.ImGui_BeginTabItem(ctx,'Settings') then
      r.ImGui_Spacing(ctx)
      r.ImGui_AlignTextToFramePadding(ctx)
      r.ImGui_Text(ctx,'User file :')
      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx,'Save as') then
        BrowseDialog(0)
      end
      r.ImGui_SameLine(ctx)
      if r.ImGui_Button(ctx,'Load') then
        BrowseDialog(2)
      end
      r.ImGui_Spacing(ctx)r.ImGui_Separator(ctx)r.ImGui_Spacing(ctx)
      rv,conf.vertical = r.ImGui_Checkbox(ctx,'Vertical mod',conf.vertical)
      rv,conf.setcolor_childs = r.ImGui_Checkbox(ctx,'Set always color to children',conf.setcolor_childs)
      rv,conf.remplace_default = r.ImGui_Checkbox(ctx,'Set 1st user to default tracks',conf.remplace_default)
      rv,conf.highlight = r.ImGui_Checkbox(ctx,'Highlight matching colors',conf.highlight)
      r.ImGui_Spacing(ctx)r.ImGui_Separator(ctx)r.ImGui_Spacing(ctx)
      r.ImGui_Text(ctx,'Random and In Order from :')
      rv,conf.randfrom = r.ImGui_Combo(ctx,'##randfrom',conf.randfrom-1,'Palette colors\31User colors\31Check List\31')
      conf.randfrom = conf.randfrom+1
      r.ImGui_Spacing(ctx)r.ImGui_Separator(ctx)r.ImGui_Spacing(ctx)
      rv,conf.mouse_pos = r.ImGui_Checkbox(ctx,'Open window on mouse position',conf.mouse_pos)
      rv,conf.auto_close = r.ImGui_Checkbox(ctx,'Quit after apply color',conf.auto_close)
      rv = r.ImGui_Checkbox(ctx,'Dock window',isdock)
      if rv then
        change_dock = true
      end
      rv,conf.background = r.ImGui_Checkbox(ctx,'Use Reaper theme background color',conf.background)
      r.ImGui_EndTabItem(ctx)
    end
    if r.ImGui_BeginTabItem(ctx,'Colors') then
        button_color = calc_colors()
        local picker_size = 200
        r.ImGui_PushItemWidth(ctx,picker_size)
        rv,conf.color_hue = r.ImGui_SliderDouble(ctx,'##Hue',conf.color_hue,0.0,1.0,'Initial Hue %.2f')
        rv, curve_points = r.ImGui_SliderInt(ctx,'##Curve points',#lum,2,5,'Curve points: %d')
        r.ImGui_PopItemWidth(ctx)
        if rv then
          if curve_points > #lum then
            for i=1, curve_points-#lum do
              table.insert(sat,2,(sat[1]+sat[2])/2)
              table.insert(lum,2,(lum[1]+lum[2])/2)
            end
          elseif curve_points < #lum then
            for i=1, #lum-curve_points do
              table.remove(sat,2)
              table.remove(lum,2)
            end
          end
        end
        rv, sat, lum = myGradrient(ctx,'Settings Gradient',conf.color_hue,sat,lum,picker_size)
        r.ImGui_PushItemWidth(ctx,-FLT_MIN)
        rv,conf.color_grey = r.ImGui_Checkbox(ctx,'First col is grey',conf.color_grey)
        r.ImGui_PopItemWidth(ctx)
        if r.ImGui_Button(ctx,'Restore') then
          restore_default_colors()
          button_color = calc_colors()
        end
        r.ImGui_EndTabItem(ctx)
      end
      if r.ImGui_BeginTabItem(ctx,'Size') then
        settings_open = true
        r.ImGui_PushItemWidth(ctx,90)
        rv, conf.number_x = r.ImGui_InputInt(ctx,'Rows',conf.number_x,1,10)
        if rv then conf.number_x = math.max(1,conf.number_x) button_color = calc_colors() end
        rv,conf.palette_y = r.ImGui_InputInt(ctx,'Palette Lines',conf.palette_y,1,10)
        if rv then conf.palette_y = math.max(0,conf.palette_y) button_color = calc_colors() end
        rv,conf.user_y = r.ImGui_InputInt(ctx,'User Lines',conf.user_y,1,10)
        if rv then conf.user_y = math.max(0,conf.user_y) button_color = calc_colors() end
        rv,conf.spacing = r.ImGui_InputInt(ctx,'Spacing (pixels)',conf.spacing,1,10)
        if rv then conf.spacing = math.max(0,conf.spacing) button_color = calc_colors() end
        r.ImGui_PopItemWidth(ctx)
        if r.ImGui_Button(ctx,'Restore') then
          restore_default_sizes()
          button_color = calc_colors()
        end
        r.ImGui_EndTabItem(ctx)
      end
      if r.ImGui_BeginTabItem(ctx,'Shortcuts') then
        local TEXT_BASE_WIDTH  = r.ImGui_CalcTextSize(ctx,'A')
        local combo_width = display_w-r.ImGui_CalcTextSize(ctx,'Shift+Cmd+Opt+Ctrl')-50
        if r.ImGui_BeginTable(ctx,'Mouse Modifiers',2,r.ImGui_TableFlags_Borders()) then
          r.ImGui_TableSetupColumn(ctx,'Modifier')
          r.ImGui_TableSetupColumn(ctx,'Action')
          r.ImGui_TableHeadersRow(ctx)
          for mod, name in ipairs(mods_names) do
            if not OS_Win or (OS_Win and name ~= 'Win') then
              r.ImGui_TableNextRow(ctx)
              if mod == 1 then
                r.ImGui_TableSetColumnIndex(ctx,0)
                r.ImGui_TableSetColumnIndex(ctx,1)
              end
              r.ImGui_PushID(ctx,'Mouse Modifiers'..mod)
              r.ImGui_TableSetColumnIndex(ctx,0)
              r.ImGui_Text(ctx,name)
              r.ImGui_TableSetColumnIndex(ctx,1)
              r.ImGui_PushItemWidth(ctx,combo_width)
              rv,mods_left[mod] = r.ImGui_Combo(ctx,'##combo'..name,mods_left[mod]-1,click_actions_combostring)
              r.ImGui_PopItemWidth(ctx)
              mods_left[mod] = mods_left[mod]+1
              r.ImGui_PopID(ctx)
            end
          end
          r.ImGui_EndTable(ctx)
        end
        if r.ImGui_Button(ctx,'Restore##modifiers') then
          mods_left = CommastringToList(def.mods_left)
        end
        r.ImGui_Spacing(ctx)
        if r.ImGui_BeginTable(ctx,'Shortcuts List',2,r.ImGui_TableFlags_Borders()) then
          r.ImGui_TableSetupColumn(ctx,'Key')
          r.ImGui_TableSetupColumn(ctx,'Action')
          r.ImGui_TableHeadersRow(ctx)
          for row, action in ipairs(shortcuts_actions) do
            r.ImGui_TableNextRow(ctx)
            if row == 1 then
              r.ImGui_TableSetColumnIndex(ctx,0)
              r.ImGui_TableSetColumnIndex(ctx,1)
            end
            r.ImGui_PushID(ctx,'Shortcuts'..row)
            r.ImGui_TableSetColumnIndex(ctx,0)
            r.ImGui_Text(ctx,shortcuts_keys[row])
            r.ImGui_TableSetColumnIndex(ctx,1)
            r.ImGui_Text(ctx,action)
            r.ImGui_PopID(ctx)
          end
          r.ImGui_EndTable(ctx)
        end
        r.ImGui_EndTabItem(ctx)
      end
      if r.ImGui_BeginTabItem(ctx,'About') then
        r.ImGui_TextDisabled(ctx,'Click to open url')
        r.ImGui_Spacing(ctx)
        r.ImGui_Bullet(ctx) r.ImGui_SameLine(ctx)
        TextURL(ctx, 'Discuss in REAPER forum thread', 'https://forum.cockos.com/showthread.php?t=252219')
        r.ImGui_Bullet(ctx) r.ImGui_SameLine(ctx)
        TextURL(ctx, 'Support with a Paypal donation', 'https://www.paypal.com/donate?hosted_button_id=N5DUAELFWX4DC')
        r.ImGui_EndTabItem(ctx)
      end
      r.ImGui_EndTabBar(ctx)
    end
    r.ImGui_PopStyleVar(ctx)
end

---------------------------------------------------------------------------------
--- Main Content ----------------------------------------------------------------
---------------------------------------------------------------------------------

function ImGuiContent_Main()
  local rv
  separator_spacing = math.max(conf.spacing,3)
  -- Top buttons
  local button_back = 0x454545ff
  local button_hover = 0x525252ff
  local button_active = 0x666666ff
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),button_back)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),button_hover)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),button_active)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBg(),button_back)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgHovered(),button_hover)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBgActive(),button_active)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Header(),button_back)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_HeaderHovered(),button_hover)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_HeaderHovered(),button_active)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),4)

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
    if r.ImGui_IsKeyPressed(ctx,string.byte('Z'),false) then
      if mods == 2 then
        r.Undo_DoUndo2(0)
      elseif mods == 4 or mods == 6 then
        r.Undo_DoRedo2(0)
      end
    elseif mods == 2 and r.ImGui_IsKeyPressed(ctx,string.byte('S'),false) then
      BrowseDialog(0)
    elseif mods == 2 and r.ImGui_IsKeyPressed(ctx,string.byte('O'),false) then
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
    elseif r.ImGui_IsKeyPressed(ctx,string.byte('R'),false) then
      main_action('Rnd All')
    elseif r.ImGui_IsKeyPressed(ctx,string.byte('E'),false) then
      main_action('Rnd Each')
    elseif r.ImGui_IsKeyPressed(ctx,string.byte('I'),false) then
      main_action('In order')
    elseif r.ImGui_IsKeyPressed(ctx,string.byte('A'),false) then
      if target_button ~= 9 then target_button = 9
      else target_button = 2 end
    else
      for i=0, 9 do
        if r.ImGui_IsKeyPressed(ctx,keycode['num'..i],false) or r.ImGui_IsKeyPressed(ctx,string.byte(i),false) then
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
    if target_button == 9 then
      r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),0x662929ff)
      r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),0x803333ff)
      r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),0x993d3dff)
    end
    rv = r.ImGui_Button(ctx,target_button_list[target_button],button_size_item) 
    if target_button == 9 then
      r.ImGui_PopStyleColor(ctx,3)
    end
    if rv then
      if target_button >= 3 and target_button <= 5 then
        target_button = (target_button-2)%3+3
        last_item_state = target_button
      elseif target_button >= 6 and target_button <= 8 then
        target_button = (target_button-5)%3+6
        last_marker_state = target_button
      elseif target_button == 2 then
        target_button = 1
        last_track_state = target_button
      elseif target_button == 9 then
        target_button = r.GetCursorContext2(true) + 2
      end
    end
  else
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBg(),0x262626ff)
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
  do
    if not button_size then square_button_size = r.ImGui_GetFrameHeight(ctx) else square_button_size = button_size end
    local pos = {r.ImGui_GetCursorScreenPos(ctx)}
    if r.ImGui_Button(ctx,'##Settings',square_button_size) then
      settings = true
    end
    r.ImGui_OpenPopupOnItemClick(ctx,'Popup Menu Settings',1)
    do
      local w, h = r.ImGui_GetItemRectSize(ctx)
      local center = {pos[1]+(w/2), pos[2]+(h/2)}
      DrawGear(center[1],center[2],h*0.6,0xffffffff)
    end
  end

  if conf.vertical == false then r.ImGui_SameLine(ctx) end

  -- Mods help text
  r.ImGui_TextColored(ctx,text_color,mods_help)

  ----------------------------------------------------------------
  -- Popups
  ----------------------------------------------------------------
  local popup_flags = r.ImGui_WindowFlags_NoMove() | r.ImGui_WindowFlags_NoResize()
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_PopupBg(), background_color)
  -- Popup Color Picker
  if r.ImGui_BeginPopup(ctx, 'Color Editor', popup_flags) then
    open_edit_popup = nil
    if display_w > display_h then
      picker_width = display_h
    else
      picker_width = display_w
    end
    picker_width = picker_width * 0.8
    if picker_width < 70 then picker_width = 70 end
    r.ImGui_PushItemWidth(ctx,picker_width)
    rv, usercolors[selected_button] = r.ImGui_ColorPicker4(ctx,'##ColorPicker',usercolors[selected_button],
                                           r.ImGui_ColorEditFlags_NoAlpha()
                                         | r.ImGui_ColorEditFlags_NoSidePreview()
                                         | r.ImGui_ColorEditFlags_PickerHueWheel()
                                         | r.ImGui_ColorEditFlags_NoInputs())
    r.ImGui_PopItemWidth(ctx)
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Settings Dock/Undock
  if r.ImGui_BeginPopup(ctx, 'Popup Menu Settings', popup_flags) then
    local text = isdock and 'Undock' or 'Dock'
    if r.ImGui_Selectable(ctx,text) then
      change_dock = true
    end
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Target combo lists
  if r.ImGui_BeginPopup(ctx, 'Popup Menu Target', popup_flags) then
    for i,key in ipairs(target_button_list) do
      if i ~= target_button then
        if i == 9 then
          local red = r.ImGui_ColorConvertHSVtoRGB(0,0.5,1,1)
          r.ImGui_PushStyleColor(ctx,r.ImGui_Col_HeaderHovered(),0x803333ff)
        end
        if r.ImGui_Selectable(ctx,key) then
          target_button = i
          if i == 1 or i == 2 then last_track_state = i
          elseif i >= 3 and i <= 5 then last_item_state = i end
        end
        if i == 9 then
          r.ImGui_PopStyleColor(ctx)
        end
      end
      if i < #target_button_list and target_category_list[i] ~= target_category_list[i+1] then
        r.ImGui_Separator(ctx)
      end
    end
    r.ImGui_EndPopup(ctx)
  end
  -- Popup Action combo lists
  if r.ImGui_BeginPopup(ctx, 'Popup Menu Action', popup_flags) then
    for i,key in ipairs(action_button_list) do
      if i ~= conf.action_button then
        if r.ImGui_Selectable(ctx,key) then
          conf.action_button = i
        end
      end
    end
    r.ImGui_EndPopup(ctx)
  end
  -- Popup User color combo lists
  if r.ImGui_BeginPopup(ctx, 'Popup Menu User Color', popup_flags) then
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
  if r.ImGui_BeginPopup(ctx, 'Popup Menu Palette Color', popup_flags) then
    if r.ImGui_Selectable(ctx,'Copy') then
      r.ImGui_SetClipboardText(ctx,INTtoHEX(button_color[selected_button]))
      selected_button = nil
    end
    r.ImGui_EndPopup(ctx)
  end

  -- Popup Modal
  local screen_center = {r.ImGui_Viewport_GetCenter(r.ImGui_GetMainViewport(ctx))}
  r.ImGui_SetNextWindowPos(ctx,screen_center[1],screen_center[2], r.ImGui_Cond_Appearing(), 0.5, 0.5)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_TitleBgActive(),button_hover)

  -- Popup are you sure ?
  if r.ImGui_BeginPopupModal(ctx, 'Clear all', nil, popup_flags) then
    modal_focus = true
    open_cleanall_popup = nil
    if r.ImGui_Button(ctx,'Cancel##Clear all',button_size) or r.ImGui_IsKeyDown(ctx,keycode.esc) then
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx,'Ok##Clear all',button_size) or r.ImGui_IsKeyDown(ctx,keycode.enter) then
      usercolors = {}
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_EndPopup(ctx)
  end

  if r.ImGui_BeginPopupModal(ctx, 'Name Input', nil, popup_flags) then
    r.ImGui_PushItemWidth(ctx,-FLT_MIN)
    if not modal_focus then r.ImGui_SetKeyboardFocusHere(ctx) end
    rv, insert_name = r.ImGui_InputText(ctx,'##Name',insert_name,r.ImGui_InputTextFlags_AutoSelectAll())
    modal_focus = true
    r.ImGui_PopItemWidth(ctx)
    if r.ImGui_Button(ctx,'Cancel##Name Input',button_size) or r.ImGui_IsKeyDown(ctx,keycode.esc) then
      last_color = nil
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx,'Ok##Name Input',button_size) or r.ImGui_IsKeyDown(ctx,keycode.enter) then
      insert_new_target(last_color,insert_name)
      last_color = nil
      modal_focus = nil
      r.ImGui_CloseCurrentPopup(ctx)
    end
    r.ImGui_SameLine(ctx)
    if r.ImGui_Button(ctx,'+##Name Input',button_size) then
      insert_new_target(last_color,insert_name)
    end
    r.ImGui_EndPopup(ctx)
  end
  r.ImGui_PopStyleColor(ctx,2) -- Popup modal colors
  r.ImGui_PopStyleColor(ctx,9) -- Butons colors
  r.ImGui_PopStyleVar(ctx) -- Rounding
  ----------------------------------------------------------------
  -- Bouton Colors
  ----------------------------------------------------------------
  color_size = GetCellSize(display_w, display_h )

  checklist_palette = TableResize(checklist_palette,conf.number_x*conf.palette_y,false)
  checklist_usercolors = TableResize(checklist_usercolors,#usercolors,false)
  local radius = color_size/6

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
      r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Border(),0xffffffff)
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),1)
      highlight = true
    else
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    local pos,center,draw_list,draw,circle_col
    if (conf.randfrom == 3 and checklist_palette[i] and target_button ~= 9) or (target_button == 9 and arm[1] and arm[1] == 0 and arm[2] and arm[2] == i) then
      pos = {r.ImGui_GetCursorScreenPos(ctx)}
      center = {pos[1]+(color_size/2), pos[2]+(color_size/2)}
      draw_list = r.ImGui_GetWindowDrawList(ctx)
      draw = true
      if target_button == 9 then
        circle_col = 0x660000ff
        circle_border_col = 0xffffffb3
      else
        circle_col = 0xffffffff
        circle_border_col = 0x000000b3
      end
    end

    if r.ImGui_ColorButton(ctx,'##'..i,button_color[i],button_flags,color_size,color_size) then
      main_action(button_color[i],0,i)
    end
    if r.ImGui_IsItemHovered(ctx) then
      if mods == 2 and r.ImGui_IsKeyPressed(ctx,string.byte('C'),false) then
        r.ImGui_SetClipboardText(ctx,INTtoHEX(button_color[i]))
        tooltip_copy = 0
      elseif target_button ~= 9 and conf.randfrom == 3 and mods == 1 and r.ImGui_IsKeyPressed(ctx,keycode.space,false) then
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
      button_user_color = 0x454545
      button_empty = true
    end

    -- Flags
    local button_flags =  r.ImGui_ColorEditFlags_NoAlpha()
                        | r.ImGui_ColorEditFlags_NoTooltip()
                        | r.ImGui_ColorEditFlags_NoDragDrop()
    local highlight = false

    if seltracks_colors[usercolors[i]] then
      r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Border(),0xffffffff)
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),1)
      highlight = true
    else
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    local pos,center,draw_list,draw,circle_col
    if (conf.randfrom == 3 and checklist_usercolors[i] and target_button ~= 9) or (target_button == 9 and arm and arm[1] == 1 and arm[2] == i) then
      pos = {r.ImGui_GetCursorScreenPos(ctx)}
      center = {pos[1]+(color_size/2), pos[2]+(color_size/2)}
      draw_list = r.ImGui_GetWindowDrawList(ctx)
      draw = true
      if target_button == 9 then
        circle_col = 0x660000ff
        circle_border_col = 0xffffffb3
      else
        circle_col = 0xffffffff
        circle_border_col = 0x000000b3
      end
    end

    -- Main Button
    if r.ImGui_ColorButton(ctx,'##User'..i,button_user_color,button_flags,color_size,color_size) then
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
          main_action(button_user_color,1,i)
        else
          selected_button = #usercolors+1
          r.ImGui_OpenPopup(ctx,'Color Editor')
        end
      end
    end
    if r.ImGui_IsItemHovered(ctx) then
      if mods == 2 and r.ImGui_IsKeyPressed(ctx,string.byte('C'),false) and not button_empty then
        r.ImGui_SetClipboardText(ctx,INTtoHEX(usercolors[i]))
        tooltip_copy = 0
      elseif target_button ~= 9 and conf.randfrom == 3 and not button_empty and mods == 1 and r.ImGui_IsKeyPressed(ctx,keycode.space,false) then
        checklist_usercolors[i] = not checklist_usercolors[i]
      elseif mods == 2 and r.ImGui_IsKeyPressed(ctx,string.byte('V'),false) then
        usercolor_paste(i)
      elseif mods == 1 and r.ImGui_IsKeyPressed(ctx,string.byte('P'),false) then
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
    if not button_empty and
        r.ImGui_IsItemActive(ctx) and
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
  r.ImGui_SameLine(ctx)
  max_x = r.ImGui_GetCursorPos(ctx)
  r.ImGui_NewLine(ctx)
  _, max_y = r.ImGui_GetCursorPos(ctx)


  -- Color buttons pop
  r.ImGui_PopStyleVar(ctx) -- Spacing
end

---------------------------------------------------------------------------------
--- Loop ------------------------------------------------------------------------
---------------------------------------------------------------------------------

function loop()

  if target_button == 9 then
    if not arm then arm = {1,1} end
    if (arm[1]==0 and not button_color[arm[2]]) or (arm[1]==1 and not usercolors[arm[2]]) then
      if usercolors[1] then arm = {1,1} else arm = {0,1} end
    end
    local window, segment, details = r.BR_GetMouseCursorContext()
    local arm_context
    if (window=='tcp' or window=='mcp') and segment=='track' then arm_context = 'track'
    elseif details=='item' then arm_context = 'item'
    elseif segment=='region_lane' then arm_context = 'region'
    elseif segment=='marker_lane' then arm_context = 'marker' end
    Arm_SetCursor(arm_context)
    Arm_GetContext(arm_context)
  else
    get_last_context()
  end

  -- Set 1st user color to default tracks option
  if conf.remplace_default == true then
    if count_tracks then
      local new_count_tracks = r.CountTracks(0)
      if new_count_tracks > count_tracks then
        count_tracks = new_count_tracks
        set_firstuser_defaulttracks()
      elseif new_count_tracks < count_tracks then
        count_tracks = new_count_tracks
      end
    else
      count_tracks = r.CountTracks(0)
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

  r.ImGui_PushFont(ctx, font)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_WindowTitleAlign(),0.5,0.5)

  ----------------------------------------------------------------
  -- Settings Window
  ----------------------------------------------------------------  

  if settings then
    local setting_heigh = 310
    r.ImGui_SetNextWindowSize(ctx, 245, setting_heigh, r.ImGui_Cond_Appearing())
    local setting_y = main_pos[2] - setting_heigh
    if setting_y < 0 then
      setting_y = main_pos[2] + display_h
    end

    if not isdock then
      r.ImGui_SetNextWindowPos(ctx, main_pos[1], setting_y, r.ImGui_Cond_Appearing())
    end

    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg(),0x333333ff)
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ChildBg() ,0x333333ff)
    local visible, open = r.ImGui_Begin(ctx, script_name..' - Settings', true, r.ImGui_WindowFlags_NoCollapse() | r.ImGui_WindowFlags_NoDocking())
    r.ImGui_PopStyleColor(ctx, 2)

    if visible then
      ImGuiContent_Settings()
      r.ImGui_End(ctx)
    end

    if not open then
      settings = false
    end
  end

  ----------------------------------------------------------------
  -- Main Window
  ----------------------------------------------------------------

  background_color = conf.background and r.ImGui_ColorConvertNative(r.GetThemeColor('col_main_bg2',0)) * 16^2 + 255 or 0x333333ff
  text_color = conf.background and r.ImGui_ColorConvertNative(r.GetThemeColor('col_main_text2',0)) * 16^2 + 255 or 0x707070ff

  if change_dock then
    conf.dock = isdock and dock or conf.dock
    dock = isdock and 0 or conf.dock
    r.ImGui_SetNextWindowDockID(ctx, dock)
    change_dock = false
  end

  r.ImGui_SetNextWindowSize(ctx, 300, 140, r.ImGui_Cond_FirstUseEver())
  if dock and not isdock and max_x and max_y and not settings_open then
    r.ImGui_SetNextWindowSize(ctx, max_x + 8, max_y + 8)
  else
    settings_open = false
  end
  r.ImGui_SetNextWindowSizeConstraints(ctx, conf.vertical and 70 or 170, conf.vertical and 100 or 50, FLT_MAX, FLT_MAX)

  if cur_x and dock and not isdock then
    r.ImGui_SetNextWindowPos(ctx, cur_x, cur_y, r.ImGui_Cond_Once(), 0.5)
  end

  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg()     ,background_color)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ChildBg()      ,background_color)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_TitleBgActive(),0x252525ff)
  local visible, open = r.ImGui_Begin(ctx, script_name, true, r.ImGui_WindowFlags_NoCollapse())
  r.ImGui_PopStyleColor(ctx, 3)
  dock = r.ImGui_GetWindowDockID(ctx)
  isdock = r.ImGui_IsWindowDocked(ctx)
  display_w, display_h = r.ImGui_GetWindowSize(ctx)
  main_pos = {r.ImGui_GetWindowPos(ctx)}

  if visible then
    ImGuiContent_Main()
    r.ImGui_End(ctx)
  end

  -- END

  r.ImGui_PopFont(ctx)
  r.ImGui_PopStyleVar(ctx)

  if not open or close or r.ImGui_IsKeyDown(ctx, 27) then
    r.ImGui_DestroyContext(ctx)
  else
    r.defer(loop)
  end

end

---------------------------------------------------------------------------------
-- DO IT ------------------------------------------------------------------------
---------------------------------------------------------------------------------

ExtState_Load()
usercolors = LoadColorFile(last_palette_on_exit)
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
else
  r.ShowMessageBox("Please install \"SWS extension\" : https://www.sws-extension.org",script_name,0)
end

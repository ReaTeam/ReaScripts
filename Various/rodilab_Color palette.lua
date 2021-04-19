-- @description Color palette
-- @author Rodilab
-- @version 1.4
-- @changelog New Marker mode (set marker and region color by time selection or else cursor position), Right-click on "Item" button to set Take/Marker/Track by Name mode, Right-click on "Default" button to set "Random All / Random Each" mode, Set preferred palette to random mode in Settings, Browse dialog bug fixed in Linux.
-- @about
--   Color tool with a color gradient palette and a customizable user palette.
--   Use it to set new tracks/objects/takes/markers/regions colors.
--
--   Requirement :
--   - ReaImGui: ReaScript binding for Dear ImGui
--   - js_ReaScriptAPI: API functions for ReaScripts
--   - SWS Extension
--
--   Features :
--   - Click on color to set in selected tracks/objects/takes/markers/regions (depends on focus and first button)
--   - Can also set color in all tracks whose name begins with a given value
--   - Set children tracks color option
--   - Drag and drop colors to user palette
--   - Edit color by right-click with color picker popup
--   - Save as and Load user colors list
--   - Many settings...
--
--   by Rodrigo Diaz (aka Rodilab)

r = reaper
script_name = "Color palette"
rounding = 4.0
-- Don't change
recalc_colors = true
restart = false
set_tmp_values = false
set_default_sizes = false
settings = 0
file_dialog = 0
extension_list = "Text file (.txt)\0*.txt\0\0"
command_colchildren = r.NamedCommandLookup('_SWS_COLCHILDREN')
item_button_list = {'Item','Take','Marker','Tracks by Name'}
item_button = 1
default_button_list = {'Default','Rnd all','Rnd each'}
default_button = 1
tmp = {}
-- User color file
info = debug.getinfo(1,'S')
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
OS_Win = string.match(reaper.GetOS(),"Win")
OS_Mac = string.match(reaper.GetOS(),"OSX")
separ = package.config:sub(1,1)
last_palette_on_exit = script_path .."rodilab_"..script_name..separ.."last_palette_on_exit.txt"
UserPalettes_path = script_path .. "rodilab_"..script_name..separ
reaper.RecursiveCreateDirectory(UserPalettes_path,1)

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
    namestart = 1,
    namestart_char = '',
    dock = false,
    x = -1,
    y = -1
    }
  for key in pairs(def) do
    if r.HasExtState(extstate_id,key) then
      local state = r.GetExtState(extstate_id,key)
      if state == "true" then state = true
      elseif state == "false" then state = false end
      conf[key] = tonumber(state) or state
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
  file = io.open(palette_file,"w+")
  for i,color_int in ipairs(usercolors) do
    local color_hex = INTtoHEX(color_int)
    ---- Write to file ----
    file:write(color_hex,'\n')
  end
  file:close()
end

function LoadColorFile(palette_file)
  local color_int_list = {}
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
    width_min = 210
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
      -- Si vertical, meme ligne pour chaque groupe
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
    tmp[key] = conf[key]
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

function get_seltracks_colors()
  seltracks_colors = {}
  local count = r.CountSelectedTracks(0)
  if count > 0 then
    for i=0, count-1 do
      local track = r.GetSelectedTrack(0,i)
      local track_color = r.GetTrackColor(track)
      local r, g, b = r.ColorFromNative(track_color)
      track_color = b + g*16^2 + r*16^4
      table.insert(seltracks_colors,track_color)
    end
  end
end

function compare_sel_colors(color_int)
  for i,sel_colors in ipairs(seltracks_colors) do
    if sel_colors == color_int then
      return true
    end
  end
  return false
end

function remove_user_color(i)
  for j,color in ipairs(usercolors) do
    if j >= i and j < #usercolors then
      usercolors[j] =  usercolors[j+1]
    elseif j == #usercolors then
      usercolors[j] = nil
    end
  end
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

function get_first_seltrack_color()
  local count = r.CountSelectedTracks(0)
  if count > 0 then
    local track = r.GetSelectedTrack(0,0)
    local track_color = r.GetTrackColor(track)
    local r,g,b = r.ColorFromNative(track_color)
    track_color = b + g*16^2 + r*16^4
    return track_color
  end
  return nil
end

function centered_button()
  if conf.vertical == true then
    r.ImGui_NewLine(ctx)
    r.ImGui_SameLine(ctx,(display_w-button_size)/2)
  end
end

function random_color()
  local list
  if conf.randfrom == 1 then
    list = button_color
    if #list == 0 then list = usercolors end
  else
    list = usercolors
    if #list == 0 then list = button_color end
  end
  if #list > 0 then
    local random = math.random(#list)
    local color = list[random]
    local r,g,b = intRGBtoRGB(color)
    return reaper.ColorToNative(r,g,b)
  else
    return nil
  end
end

---------------------------------------------------------------------------------
--- Main ------------------------------------------------------------------------
---------------------------------------------------------------------------------

function SetColor(color_int)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Get color
  local color
  if type(color_int) == 'number' then
    local r,g,b = intRGBtoRGB(color_int)
    color = reaper.ColorToNative(r,g,b)
  elseif color_int == 'rnd_all' then
    color = random_color()
  end

  -- Get context target
  local context = reaper.GetCursorContext2(true)
  local what
  if conf.namestart == 2 then
    what = 'tracks_names'
  else
    if context == 1 then
      if item_button == 1 then
        what = 'items'
      elseif item_button == 2 then
        what = 'takes'
      elseif item_button == 3 then
        what = 'markers'
      end
    else
      what = 'tracks'
    end
  end

  -- Get count
  local count
  if what == 'tracks' then
    count = reaper.CountSelectedTracks(0)
  elseif what == 'tracks_names' then
    count = reaper.CountTracks(0)
  elseif what == 'items' or what == 'takes' then
    count = reaper.CountSelectedMediaItems(0)
  elseif what == 'markers' then
    time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)
    cursor = reaper.GetCursorPosition()
    local rv, num_markers, num_regions = reaper.CountProjectMarkers(0)
    count = num_markers + num_regions
  end

  -- For each target
  for i=0, count-1 do

    -- Random color for each selected
    if color_int == 'rnd_each' then
      color = random_color()
    end

    if not color and color_int ~= 'default' then
      return
    end

    if what == 'tracks' or  what == 'tracks_names' then
      local track
      local set = false
      if what == 'tracks' then
        track = reaper.GetSelectedTrack(0,i)
        set = true
      elseif what == 'tracks_names' then
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
        if color_int == 'default' then
          -- Set default track colors
          reaper.Main_OnCommand(40359,0)
        else
          reaper.SetTrackColor(track,color)
        end
      end
    elseif what == 'items' or what == 'takes' then
      local item = reaper.GetSelectedMediaItem(0,i)
      if what == 'items' then
        if color_int == 'default' then
          -- Set default item colors
          reaper.Main_OnCommand(40707,0)
        else
          reaper.SetMediaItemInfo_Value(item,"I_CUSTOMCOLOR",color|0x1000000)
        end
      else
        local take = reaper.GetActiveTake(item)
        if color_int == 'default' then
          -- Set default active take colors
          reaper.Main_OnCommand(41333,0)
        else
          reaper.SetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR",color|0x1000000)
        end
      end
    elseif what == 'markers' then
      local rv, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers2(0,i)
      if pos == cursor or (pos > time_sel_start and pos < time_sel_end) then
        if color_int ~= 'default' then
          reaper.SetProjectMarker3(0,markrgnindexnumber,isrgn,pos,rgnend,name,color|0x1000000)
        end
      end
    end
  end

  -- Children tracks color
  if context ~= 1 and command_colchildren ~= 0 and (conf.setcolor_childs == true or mods == 5 or mods == 8) then
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

function loop()
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
    restart = false
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
  end

  -- Get selected tracks color
  get_seltracks_colors()

  local rv
  local windows_flag = r.ImGui_WindowFlags_NoDecoration()
  display_w, display_h = r.ImGui_GetDisplaySize(ctx)

  -- Window Settings
  if settings > 0 then
    if settings == 1 then
      local settings_width = 250
      local settings_heigth = 230
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
    local settings_window_flag = r.ImGui_WindowFlags_AlwaysAutoResize()
                               | r.ImGui_WindowFlags_NoTitleBar()
    r.ImGui_Begin(ctx2,'wnd2',nil,settings_window_flag)
    r.ImGui_PopStyleColor(ctx2)
    r.ImGui_PushStyleVar(ctx2,r.ImGui_StyleVar_FrameRounding(),rounding)

    -- Content
    if r.ImGui_BeginTabBar(ctx2,'Tabbar',r.ImGui_TabBarFlags_None()) then
      if r.ImGui_BeginTabItem(ctx2,'Settings') then
        r.ImGui_Spacing(ctx2)
        r.ImGui_AlignTextToFramePadding(ctx2)
        r.ImGui_Text(ctx2,'User file :')
        r.ImGui_SameLine(ctx2)
        --local extension_list = "Text file (.txt)\0*.txt\0\0"
        if r.ImGui_Button(ctx2,'Save as') then
          file_dialog = 1
        end
        r.ImGui_SameLine(ctx2)
        if r.ImGui_Button(ctx2,'Load') then
          file_dialog = 2
        end
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        if command_colchildren ~= 0 then
          rv,conf.setcolor_childs = r.ImGui_Checkbox(ctx2,'Set always color to children',conf.setcolor_childs)
        else
          rv,conf.setcolor_childs = r.ImGui_Checkbox(ctx2,'Set always color to children',false)
          if rv == true then
            r.ImGui_OpenPopup(ctx2,'SWS_Error')
          end
          if r.ImGui_BeginPopup(ctx2,'SWS_Error') then
            r.ImGui_Text(ctx2,'Need SWS extension')
            r.ImGui_EndPopup(ctx2)
          end
        end
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        r.ImGui_Text(ctx2,'Random from :')
        rv,conf.randfrom = r.ImGui_RadioButtonEx(ctx2,'Palette colors',conf.randfrom,1)
        rv,conf.randfrom = r.ImGui_RadioButtonEx(ctx2,'User colors',conf.randfrom,2)
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        rv,conf.mouse_pos = r.ImGui_Checkbox(ctx2,'Open window on mouse position',conf.mouse_pos)
        rv,conf.auto_close = r.ImGui_Checkbox(ctx2,'Quit after apply color',conf.auto_close)
        if r.ImGui_IsItemClicked(ctx2) then
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
                          'Shift-click to get first selected track color in user',
                          'Right-click on Item button to set Items/Takes/Markers/Track by Name mode',
                          'Right-click on Default button to set Default/Random All/Random Each mode',
                          'Right-click on Settings button to dock/undock window'}
        if not OS_Mac then
          msg_list[4] = string.gsub(msg_list[4],'Cmd','Ctrl')
          msg_list[5] = string.gsub(msg_list[5],'Ctrl','Ctrl+Alt')
        end
        for i,msg in ipairs(msg_list) do
          r.ImGui_Bullet(ctx2)
          r.ImGui_TextWrapped(ctx2,msg)
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

  -- Window
  r.ImGui_SetNextWindowPos(ctx,0,0)
  r.ImGui_SetNextWindowSize(ctx,display_w,display_h)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg(),background_color)
  r.ImGui_Begin(ctx,'wnd',nil,windows_flag)
  r.ImGui_PopStyleColor(ctx)

  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),rounding)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_PopupBg(),background_popup_color)

  mods = r.ImGui_GetKeyMods(ctx)
  if mods == 1 then
    mods_help = 'Past'
  elseif mods == 2 then
    mods_help = 'Get trk'
  elseif mods == 4 then
    mods_help = 'Remove'
  elseif  mods == 5 or mods == 8 then
    mods_help = 'Childs'
  else
    mods_help = nil
  end

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
  if conf.namestart == 1 then
    if not button_size then button_size_item = 49 else button_size_item = button_size end
    if r.ImGui_Button(ctx,item_button_list[item_button],button_size_item) then
      if item_button > 2 then
        item_button = 1
      else
        item_button = item_button%2+1
      end
    end
  elseif conf.namestart == 2 then
    r.ImGui_PushStyleColor(ctx,r.ImGui_Col_FrameBg(),framegb_color)
    if button_size then
      r.ImGui_PushItemWidth(ctx,button_size)
    else
      r.ImGui_PushItemWidth(ctx,49)
    end
    rv,conf.namestart_char = r.ImGui_InputTextWithHint(ctx,'##NameStart Input','name ?',conf.namestart_char)
    if r.ImGui_IsItemClicked(ctx) and mods > 0 then
      conf.namestart = 1
    end
    r.ImGui_PopStyleColor(ctx)
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'item_combo',1)

  if conf.vertical == false then r.ImGui_SameLine(ctx) end
  centered_button()

  if not button_size then button_size_default = 64 else button_size_item = button_size end
  if r.ImGui_Button(ctx,default_button_list[default_button],button_size_default) then
    if default_button == 1 then
      SetColor('default')
    elseif default_button == 2 then
      SetColor('rnd_all')
    elseif default_button == 3 then
      SetColor('rnd_each')
    end
  end
  r.ImGui_OpenPopupOnItemClick(ctx,'default_combo',1)

  if r.ImGui_BeginPopup(ctx,'default_combo') then
    for i,key in ipairs(default_button_list) do
      if r.ImGui_Selectable(ctx,key) then
        default_button = i
      end
      if i < #default_button_list then r.ImGui_Separator(ctx) end
    end
    r.ImGui_EndPopup(ctx)
  end

  if r.ImGui_BeginPopup(ctx,'item_combo') then
    for i,key in ipairs(item_button_list) do
      if r.ImGui_Selectable(ctx,key) then
        if i < 4 then
          item_button = i
          conf.namestart = 1
        else
          conf.namestart = 2
        end
      end
      if i < #item_button_list then r.ImGui_Separator(ctx) end
    end
    r.ImGui_EndPopup(ctx)
  end

  if conf.vertical == false then r.ImGui_SameLine(ctx) end
  centered_button()
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

  -- POPUP Color Picker
  if r.ImGui_BeginPopup(ctx,'Color Editor') then
    local flags = r.ImGui_ColorEditFlags_NoAlpha()
                  | r.ImGui_ColorEditFlags_NoSidePreview()
                  | r.ImGui_ColorEditFlags_PickerHueWheel()
                  | r.ImGui_ColorEditFlags_NoInputs()
    if display_w > display_h then
      picker_width = display_h
    else
      picker_width = display_w
    end
    picker_width = picker_width * 0.8
    if picker_width < 70 then picker_width = 70 end
    r.ImGui_PushItemWidth(ctx,picker_width)
    rv, usercolors[selected_button] = r.ImGui_ColorPicker4(ctx,'##ColorPicker',usercolors[selected_button],flags)
    r.ImGui_EndPopup(ctx)
  end

  if r.ImGui_BeginPopup(ctx,'Dock Popup') then
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

  -- SWS Error Popup
  if r.ImGui_BeginPopup(ctx,'SWS_Error') then
    r.ImGui_Text(ctx,'Need SWS extension')
    r.ImGui_EndPopup(ctx)
  end

  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),1)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Border(),col_border)
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
    if compare_sel_colors(button_color[i]) == false then
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    if r.ImGui_ColorButton(ctx,'##'..i,button_color[i],button_flags,conf.size,conf.size) then
      SetColor(button_color[i])
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
    if compare_sel_colors(button_user_color) == false then
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    -- Main Button
    if r.ImGui_ColorButton(ctx,'##User'..i,button_user_color,button_flags,conf.size,conf.size) then
      if mods == 4 then
        if button_empty == false then
          remove_user_color(i)
        end
      elseif mods == 1 then
        if r.APIExists('CF_GetClipboard') == true then
          local past_color = get_clipboard_color()
          if past_color then
            if button_empty == false then
              usercolors[i] = past_color
            else
              usercolors[#usercolors+1] = past_color
            end
          end
        else
          r.ImGui_OpenPopup(ctx,'SWS_Error')
        end
      elseif  mods == 2 then
        local first_seltrack_color = get_first_seltrack_color()
        if first_seltrack_color then
          if button_empty == false then
            usercolors[i] = first_seltrack_color
          else
            usercolors[#usercolors+1] = first_seltrack_color
          end
        end
      else
        if button_empty == false then
          SetColor(button_user_color)
        end
      end
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
          remove_user_color(dragdrop_source_id)
          dragdrop_source_id = nil
        end
        insert_new_user(i,tonumber(payload))
      end
      r.ImGui_EndDragDropTarget(ctx)
    end

    -- Right Click open popup
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
  r.ImGui_PopStyleColor(ctx,2)
  r.ImGui_PopStyleVar(ctx,4)

  -- End loop
  r.ImGui_End(ctx)
  r.defer(loop)
end

---------------------------------------------------------------------------------
-- DO IT ------------------------------------------------------------------------
---------------------------------------------------------------------------------

local ImGui_exist = r.APIExists('ImGui_CreateContext')
if ImGui_exist == true then
  local JS_API_exist = r.APIExists('JS_Dialog_BrowseForOpenFiles')
  if JS_API_exist == true then
    -- Colors
    background_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.2,1)
    background_popup_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.15,1)
    framegb_color = r.ImGui_ColorConvertHSVtoRGB(0,0,0.15,1)
    default_usercolor = r.ImGui_ColorConvertHSVtoRGB(0,0,0.27)
    col_border = r.ImGui_ColorConvertHSVtoRGB(0,0,1,1)
    button_back = r.ImGui_ColorConvertHSVtoRGB(0,0,0.27,1)
    button_hover = r.ImGui_ColorConvertHSVtoRGB(0,0,0.32,1)
    button_active = r.ImGui_ColorConvertHSVtoRGB(0,0,0.4,1)

    ExtState_Load()
    usercolors = LoadColorFile(last_palette_on_exit)
    get_tmp_values()
    set_window()
    r.defer(loop)
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

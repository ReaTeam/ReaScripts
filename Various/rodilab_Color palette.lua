-- @description Color palette
-- @author Rodilab
-- @version 1.1
-- @changelog Update : Set color to children tracks option, drag and drop insert (not remplace), improved spacing.
-- @about
--   Color tool with a color gradient palette and a customizable user palette.
--   Use it to set new tracks/objects/takes colors.
--
--   User interface generated with ReaImGui (Dear ImGui), please install it first with ReaPack and restart Reaper.
--
--   - Click on color to set in selected tracks/objects/takes (depends on focus)
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
default_usercolor = r.ImGui_ColorConvertHSVtoRGB(0,0,0.2)
col_border = r.ImGui_ColorConvertHSVtoRGB(0,0,1,1)
-- Don't change
item_button = 'Item'
recalc_colors = true
restart = false
set_tmp_values = false
set_default_sizes = false
settings = 0
command_colchildren = r.NamedCommandLookup('_SWS_COLCHILDREN')
-- User color file
separ = string.match(reaper.GetOS(), "Win") and "\\" or "/"
info = debug.getinfo(1,'S')
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
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
    setcolor_childs = false,
    mouse_pos = true,
    auto_close = false,
    namestart = 1,
    namestart_char = ''
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

  local width = (conf.number_x * conf.size) + ((conf.number_x -1 )* conf.spacing) + 15
  if width < 190 then
    width = 190
  end

  local heigth = ((conf.palette_y + conf.user_y) * conf.size) + ((conf.palette_y + conf.user_y - 1) * conf.spacing) + 39
  if conf.palette_y > 0 and conf.user_y > 0 then
    heigth = heigth + (separator_spacing+3)
  end
  if restart == false then
    if conf.mouse_pos == true then
      x, y = r.GetMousePosition()
      x = math.floor(x - (width/2))
      y = math.floor(y + (heigth/2))
    else
      x = nil
      y = nil
    end
  end

  button_color = calc_colors()
  ctx = r.ImGui_CreateContext(script_name,width,heigth,x,y)
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
  local r,g,b = intRGBtoRGB(color_int)
  local color = reaper.ColorToNative(r,g,b)

  local color_list = {}

  local count = reaper.CountSelectedTracks(0)
  if count > 0 then
    for i=0, count-1 do
      local track = reaper.GetSelectedTrack(0,i)
      local track_color = reaper.ColorToNative(reaper.ColorFromNative(reaper.GetTrackColor(track)))
      table.insert(color_list,track_color)
    end
  end

  for i,sel_colors in ipairs(color_list) do
    if sel_colors == color then
      return true
    end
  end
  return false
end

function get_tmp_values()
  tmp_number_x = conf.number_x
  tmp_palette_y = conf.palette_y
  tmp_user_y = conf.user_y
  tmp_size = conf.size
  tmp_spacing = conf.spacing
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
  local clipboard = reaper.CF_GetClipboard()

  local color_int = HEXtoINT(clipboard)
  return color_int
end

function get_first_sel_trackcolor()
  local count = reaper.CountSelectedTracks(0)
  if count > 0 then
    local track = reaper.GetSelectedTrack(0,0)
    local track_color = reaper.GetTrackColor(track)
    return track_color
  end
  return nil
end

---------------------------------------------------------------------------------
--- Main ------------------------------------------------------------------------
---------------------------------------------------------------------------------

function SetColor(color_int)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local context = reaper.GetCursorContext2(true)
  local color,r,g,b
  if color_int ~= 'default' then
    r,g,b = intRGBtoRGB(color_int)
    color = reaper.ColorToNative(r,g,b)
  end

  if conf.namestart == 1 then
    local count = reaper.CountSelectedMediaItems(0)
    if context == 1 and count > 0 then
      for i=0, count-1 do
        local item = reaper.GetSelectedMediaItem(0,i)
        local take = reaper.GetActiveTake(item)
        if color_int ~= 'default' then
          if item_button == 'Item' then
            reaper.SetMediaItemInfo_Value(item,"I_CUSTOMCOLOR",color|0x1000000)
          elseif item_button == 'Take' then
            reaper.SetMediaItemTakeInfo_Value(take,"I_CUSTOMCOLOR",color|0x1000000)
          end
        else
          if item_button == 'Item' then
            -- Set default item colors
            reaper.Main_OnCommand(40707,0)
          elseif item_button == 'Take' then
            -- Set default active take colors
            reaper.Main_OnCommand(41333,0)
          end
        end
      end
    else
      count = reaper.CountSelectedTracks(0)
      if count > 0 then
        for i=0, count-1 do
          local track = reaper.GetSelectedTrack(0,i)
          if color_int ~= 'default' then
            reaper.SetTrackColor(track,color)
          else
            -- Set default track colors
            reaper.Main_OnCommand(40359,0)
          end
        end
      end
    end
  -- Set Color with StartName
  elseif conf.namestart == 2 then
    local count = reaper.CountTracks(0)
    if count > 0 then
      for i=0, count-1 do
        local track = reaper.GetTrack(0,i)
        local retval, trackname = reaper.GetTrackName(track)
        if retval == true then
          --
          trackname = string.sub(trackname,1,string.len(conf.namestart_char))
          if trackname == conf.namestart_char then
            if color_int ~= 'default' then
              reaper.SetTrackColor(track,color)
            else
              -- Set default track colors
              reaper.SetOnlyTrackSelected(track)
              reaper.Main_OnCommand(40359,0)
            end
          end
        end
      end
    end
  end

  -- Children tracks color
  if context ~= 1 and conf.setcolor_childs == true and command_colchildren ~= 0 then
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

function loop()
  -- Reset
  if restart == true then
    if set_tmp_values == true then
      conf.number_x = tmp_number_x
      conf.palette_y = tmp_palette_y
      conf.user_y = tmp_user_y
      conf.size = tmp_size
      conf.spacing = tmp_spacing
      set_tmp_values = false
    end
    if set_default_sizes == true then
      restore_default_sizes()
    end
    get_tmp_values()
    button_color = calc_colors()
    r.ImGui_DestroyContext(ctx)
    set_window()
    restart = false
  end

  -- Close Window ?
  if r.ImGui_IsCloseRequested(ctx) or r.ImGui_IsKeyDown(ctx,53) or close == true then
    SaveColorFile(last_palette_on_exit)
    r.ImGui_DestroyContext(ctx)
    ExtState_Save()
    return
  end

  local rv
  local windows_flag = r.ImGui_WindowFlags_NoDecoration()
  local background_color = r.ImGui_ColorConvertHSVtoRGB(1,0,0.1,1)
  local rounding = 4.0
  local display_w, display_h = r.ImGui_GetDisplaySize(ctx)

  -- Window Settings
  if settings > 0 then
    if settings == 1 then
    local settings_width = 250
      local settings_heigth = 220
      local x,y = r.GetMousePosition()
      x = math.floor(x-settings_width/2)
      y = y-display_h-20
      ctx2 = r.ImGui_CreateContext(script_name.." - Settings",settings_width,settings_heigth,x,y)
      settings = 2
    end
    local display_w, display_h = r.ImGui_GetDisplaySize(ctx2)
    r.ImGui_SetNextWindowPos(ctx2,0,0)
    r.ImGui_SetNextWindowSize(ctx2,display_w,display_h)
    r.ImGui_PushStyleColor(ctx2,r.ImGui_Col_WindowBg(),background_color)
    r.ImGui_Begin(ctx2,'wnd2',nil,windows_flag)
    r.ImGui_PopStyleColor(ctx2)
    r.ImGui_PushStyleVar(ctx2,r.ImGui_StyleVar_FrameRounding(),rounding)

    -- Content
    if r.ImGui_BeginTabBar(ctx2,'Tabbar',r.ImGui_TabBarFlags_None()) then
      if r.ImGui_BeginTabItem(ctx2,'Settings') then
        r.ImGui_Spacing(ctx2)
        r.ImGui_AlignTextToFramePadding(ctx2)
        r.ImGui_Text(ctx2,'User file :')
        r.ImGui_SameLine(ctx2)
        if r.ImGui_Button(ctx2,'Save as') then
          local rv, fileName = r.JS_Dialog_BrowseForSaveFile('Save user palette',UserPalettes_path,'','*.txt')
          if rv ==  1 then
            SaveColorFile(fileName..'.txt')
          end
        end
        r.ImGui_SameLine(ctx2)
        if r.ImGui_Button(ctx2,'Load') then
          local rv, fileName = r.JS_Dialog_BrowseForOpenFiles('Open user palette',UserPalettes_path,'','*.txt',false)
          if rv == 1 then
            usercolors = LoadColorFile(fileName)
          end
        end
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        reaper.ImGui_Text(ctx2,'Set colors to :')
        rv,conf.namestart = r.ImGui_RadioButtonEx(ctx2,'Selected tracks/items/takes',conf.namestart,1)
        rv,conf.namestart = r.ImGui_RadioButtonEx(ctx2,'Tracks by name',conf.namestart,2)
        if command_colchildren ~= 0 then
          rv,conf.setcolor_childs = r.ImGui_Checkbox(ctx2,'Set color to children tracks',conf.setcolor_childs)
        else
          rv,conf.setcolor_childs = r.ImGui_Checkbox(ctx2,'Set color to children tracks',false)
          if rv == true then
            r.ImGui_OpenPopup(ctx2,'SWS_Error')
          end
          if r.ImGui_BeginPopup(ctx2,'SWS_Error') then
            r.ImGui_Text(ctx2,'Need SWS extension')
            r.ImGui_EndPopup(ctx2)
          end
        end
        r.ImGui_Spacing(ctx2)r.ImGui_Separator(ctx2)r.ImGui_Spacing(ctx2)
        rv,conf.mouse_pos = r.ImGui_Checkbox(ctx2,'Open window on mouse position',conf.mouse_pos)
        rv,conf.auto_close = r.ImGui_Checkbox(ctx2,'Quit after apply color',conf.auto_close)
        r.ImGui_EndTabItem(ctx2)
      end
      if r.ImGui_BeginTabItem(ctx2,'Colors') then
        rv,conf.color_hue = r.ImGui_SliderDouble(ctx2,'##Hue',conf.color_hue,0.0,1.0,'Initial Hue %.2f')
        rv,conf.color_saturation_min,conf.color_saturation_max = r.ImGui_DragFloatRange2(ctx2,'Saturation',conf.color_saturation_min,conf.color_saturation_max,0.01,0.0,1.0,'Min %.2f',"Max %.2f",r.ImGui_SliderFlags_AlwaysClamp())
        rv,conf.color_lightness_min,conf.color_lightness_max = r.ImGui_DragFloatRange2(ctx2,'Lightness',conf.color_lightness_min,conf.color_lightness_max,0.01,0.0,1.0,'Min %.2f',"Max %.2f",r.ImGui_SliderFlags_AlwaysClamp())
        rv,conf.color_grey = r.ImGui_Checkbox(ctx2,'First col is grey',conf.color_grey)
        if r.ImGui_Button(ctx2,'Restore') then
          restore_default_colors()
        end
        if r.ImGui_IsAnyItemActive(ctx2) == true then
          button_color = calc_colors()
        end
        r.ImGui_EndTabItem(ctx2)
      end
      if r.ImGui_BeginTabItem(ctx2,'Size') then
        r.ImGui_PushItemWidth(ctx2,90)
        rv, tmp_number_x = r.ImGui_InputInt(ctx2,'Rows',tmp_number_x,1,10)
        if tmp_number_x < 1 then tmp_number_x = 1 end
        rv,tmp_palette_y = r.ImGui_InputInt(ctx2,'Palette Lines',tmp_palette_y,1,10)
        rv,tmp_user_y = r.ImGui_InputInt(ctx2,'User Lines',tmp_user_y,1,10)
        rv,tmp_size = r.ImGui_InputInt(ctx2,'Size (pixels)',tmp_size,1,10)
        rv,tmp_spacing = r.ImGui_InputInt(ctx2,'Spacing (pixels)',tmp_spacing,1,10)
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
        local msg_list = {
                          'Drag and drop to copy/past color in user palette',
                          'Right-click to edit user color',
                          'Alt-click to remove user color',
                          'Cmd-click to past HEX value in user color',
                          'Shift-click to get first selected track color into user color'
                          }
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

  -- Window
  r.ImGui_SetNextWindowPos(ctx,0,0)
  r.ImGui_SetNextWindowSize(ctx,display_w,display_h)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_WindowBg(),background_color)
  r.ImGui_Begin(ctx,'wnd',nil,windows_flag)
  r.ImGui_PopStyleColor(ctx)

  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),rounding)

  local mods = r.ImGui_GetKeyMods(ctx)
  if mods == 4 then
    mods_help = 'Remove'
  elseif mods == 1 then
    mods_help = 'Past'
  elseif  mods == 2 then
    mods_help = 'Get trk'
  else
    mods_help = nil
  end

  local button_back = r.ImGui_ColorConvertHSVtoRGB(0,0,0.2,1)
  local button_hover = r.ImGui_ColorConvertHSVtoRGB(0,0,0.3,1)
  local button_active = r.ImGui_ColorConvertHSVtoRGB(0,0,0.4,1)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Button(),button_back)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonHovered(),button_hover)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_ButtonActive(),button_active)
  if conf.namestart == 1 then
    if r.ImGui_Button(ctx,item_button) then
      if item_button == 'Item' then
        item_button = 'Take'
      else
        item_button = 'Item'
      end
    end
  elseif conf.namestart == 2 then
    r.ImGui_PushItemWidth(ctx,42)
    rv,conf.namestart_char = r.ImGui_InputTextWithHint(ctx,'##NameStart Input','name?',conf.namestart_char)
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx,'Default') then
    SetColor('default')
  end
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx,'Settings') then
    settings = 1
  end
  if mods_help then
    r.ImGui_SameLine(ctx)
    r.ImGui_TextDisabled(ctx,mods_help)
  end
  r.ImGui_PopStyleColor(ctx,3)

  -- POPUP Color Picker
  if r.ImGui_BeginPopupContextItem(ctx,'Color Editor') then
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

  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameBorderSize(),1)
  r.ImGui_PushStyleColor(ctx,r.ImGui_Col_Border(),col_border)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_FrameRounding(),0)
  r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),conf.spacing,conf.spacing)
  -- Palette Colors
  for i=1, conf.number_x*conf.palette_y do
    if ((i-1) % conf.number_x) ~= 0 then
      r.ImGui_SameLine(ctx)
    end

    local button_flags =  r.ImGui_ColorEditFlags_NoAlpha()
                        | r.ImGui_ColorEditFlags_NoTooltip()
                        | r.ImGui_ColorEditFlags_NoDragDrop()
    if compare_sel_colors(button_color[i]) == false then
      button_flags = button_flags | r.ImGui_ColorEditFlags_NoBorder()
    end

    -- Last line, dont bottom spacing
    if i > conf.number_x*(conf.palette_y-1) then
      r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),conf.spacing,0)
    end

    if r.ImGui_ColorButton(ctx,'##'..i,button_color[i],button_flags,conf.size,conf.size) then
      SetColor(button_color[i])
    end

    if i > conf.number_x*(conf.palette_y-1) then
      r.ImGui_PopStyleVar(ctx)
    end

    -- Drag and Drop source
    if r.ImGui_BeginDragDropSource(ctx,r.ImGui_DragDropFlags_None()) then
      r.ImGui_SetDragDropPayload(ctx,'DnD_Color',button_color[i])
      r.ImGui_ColorButton(ctx,'DnD_Preview',button_color[i],r.ImGui_ColorEditFlags_NoAlpha())
      r.ImGui_EndDragDropSource(ctx)
    end
  end

  if conf.palette_y > 0 and conf.user_y > 0 then
    r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,separator_spacing)
    r.ImGui_Spacing(ctx)
    r.ImGui_PopStyleVar(ctx)
    r.ImGui_PushStyleVar(ctx,r.ImGui_StyleVar_ItemSpacing(),0,separator_spacing+1)
    r.ImGui_Separator(ctx)
    r.ImGui_PopStyleVar(ctx)
  end

  -- User colors
  for i=1, conf.number_x*conf.user_y do
    local button_user_color
    local button_empty
    if usercolors[i] then
      button_user_color = usercolors[i]
      button_empty = false
    else
      button_user_color = default_usercolor
      button_empty = true
    end

    if ((i-1) % conf.number_x) ~= 0 then
      r.ImGui_SameLine(ctx)
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
        local past_color = get_clipboard_color()
        if past_color then
          if button_empty == false then
            usercolors[i] = past_color
          else
            usercolors[#usercolors+1] = past_color
          end
        end
      elseif  mods == 2 then
        local first_sel_color = get_first_sel_trackcolor()
        if first_sel_color then
          if button_empty == false then
            usercolors[i] = first_sel_color
          else
            usercolors[#usercolors+1] = first_sel_color
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
        insert_new_user(i,payload)
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
    end
    r.ImGui_OpenPopupOnItemClick(ctx,'Color Editor',1)
  end
  r.ImGui_PopStyleColor(ctx,1)
  r.ImGui_PopStyleVar(ctx,4)

  -- End loop
  r.ImGui_End(ctx)
  r.defer(loop)
end

---------------------------------------------------------------------------------
-- DO IT ------------------------------------------------------------------------
---------------------------------------------------------------------------------

if r.ImGui_CreateContext ~= nil then
  ExtState_Load()
  usercolors = LoadColorFile(last_palette_on_exit)
  get_tmp_values()
  set_window()
  r.defer(loop)
else
  r.ShowMessageBox("Please install \"ReaImGui: ReaScript binding for Dear ImGui\" with ReaPack and restart Reaper",script_name,0)
end

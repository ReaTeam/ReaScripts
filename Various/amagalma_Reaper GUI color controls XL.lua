-- @description Reaper GUI color controls XL
-- @author amagalma
-- @version 1.08
-- @changelog
--   - If settings are the default ones then, the tie button does not lit green
--   - User is not prompted to tie if the values are the default ones (except if there are already other tied values)
-- @link http://forum.cockos.com/showthread.php?p=2281705#post2281705
-- @about
--   # Similar to native Theme Color Controls, with extra features
--
--   - Additional preset support
--   - Additional A/B function to compare current settings to untweaked ones
--   - "Tie to current theme" button is used to relate the current settings to the current theme. So that each time the theme loads, the settings are recalled
--   - The above is the default and only method of the native implementation. This version can set temporary settings that won't be recalled if one wishes to
--   - The "Tie to current theme" lits green if a setting for Theme Color Controls is found in the reaperhemeconfig.ini, which means that there is a tie for the current theme.
--   - Script requires Lokasenna GUI v2 and at least Reaper v6.09+dev0502 to run

local version = "1.08"

----------------------------------------------------------------------------

local reaper = reaper
local AB_mode = false
local lock_buttons = false
local cur_ParmValues = {}
local cur_Theme_ParmValues = {}
local default_ParmValues = {1000, 0, 0, 0, 256, 192}
local tied = false
local prev_tied = false
local info = debug.getinfo(1,'S')
local presets_file = info.source:match[[^@?(.*[\/])[^\/]-$]] .. "Color Control Presets.txt"
local active_preset
local cur_theme = reaper.GetLastColorThemeFile()
local theme_name = cur_theme:match("^.+[/\\](.+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee][Zz]?[Ii]?[Pp]?")
local themeconfig = reaper.GetResourcePath().. (string.find(reaper.GetOS(), "Win" ) and "\\" or "/").. [[reaper-themeconfig.ini]]
local check, _, apply_to_proj_colors = reaper.ThemeLayout_GetParameter( -1006 )
----------------------------------------------------------------------------

-- Check Reaper version
if not check then
  reaper.MB("This script uses a native API that is available from Reaper v6.11 onwards.", "Required API is not available", 0)
  return
end

-- Check Lokasenna_GUI library availability --
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" or not reaper.file_exists(lib_path .. "Core.lua") then
  local not_installed = false
  local Core_library = {reaper.GetResourcePath(), "Scripts", "ReaTeam Scripts", "Development", "Lokasenna_GUI v2", "Library", "Core.lua"}
  local sep = reaper.GetOS():find("Win") and "\\" or "/"
  Core_library = table.concat(Core_library, sep)
  if reaper.file_exists(Core_library) then
    local cmdID = reaper.NamedCommandLookup( "_RS1c6ad1164e1d29bb4b1f2c1acf82f5853ce77875" )
    if cmdID > 0 then
          reaper.MB("Lokasenna's GUI path will be set now. Please, re-run the script", "Lokasenna GUI v2 Installation", 0)
      -- Set Lokasenna_GUI v2 library path.lua
      reaper.Main_OnCommand(cmdID, 0)
      return reaper.defer(function() end)
    else
      not_installed = true
    end
  else
    not_installed = true
  end
  if not_installed then
    reaper.MB("Please, right-click and install 'Lokasenna's GUI library v2 for Lua' in the next window. Then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List. After all is set, you can run this script again. Thanks!", "Install Lokasenna GUI v2", 0)
    reaper.ReaPack_BrowsePackages( "Lokasenna GUI library v2 for Lua" )
    return reaper.defer(function() end)
  end
end
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Textbox.lua")()
if missing_lib then 
  reaper.MB("Please re-install 'Lokasenna's GUI library v2 for Lua'", "Missing library!", 0)
  return reaper.defer(function() end)
end
local GUI = GUI

-- Refresh toolbar
local _, _, section, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState( section, cmdID, 1 )
reaper.RefreshToolbar2( section, cmdID )

----------------------------------------------------------------------------

-- Functions

function GetParmValues()
  for i = 1, 6 do
    local _, _, value, _, min, max = reaper.ThemeLayout_GetParameter( -999 -i )
    cur_ParmValues[i] = {v = value, min = min, max = max}
  end
end

function SetParmValues(table, persist)
  if not persist then persist = false else persist = true end
  if persist then tied = true end
  local c = false
  if table == cur_ParmValues then
    c = true
  end
  for i = 1, 6 do
    reaper.ThemeLayout_SetParameter( -999 -i, c and cur_ParmValues[i].v or table[i], persist )
  end
end

function ABfunc()
  AB_mode = not AB_mode
  GUI.elms.AB.col_fill = AB_mode and "green" or "elm_frame"
  GUI.elms.AB:init()
  if AB_mode then
    SetParmValues(default_ParmValues)
  else
    SetParmValues(cur_ParmValues)
  end
end

function CurrentValuesAreDefault()
  -- check if the current values are the default ones
  local default = true
  for i = 1, 6 do
    if cur_ParmValues[i].v ~= default_ParmValues[i] then
      default = false
      break
    end
  end
  return default
end

function TieToTheme()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  --if not CurrentValuesAreDefault() then tied = true end
  tied = true
  SetParmValues(cur_ParmValues, true)
  GetLiaison()
end

function WritePresetsToFile(presets)
  local file = io.open(presets_file, "w")
  for i = 1, #presets do
    file:write(presets[i].name .. "  @  ")
    for v = 1, 6 do
      file:write(presets[i][v] .. (v < 6 and "," or "\n") )
    end
  end
  file:close()
end

function GetPresetsFromFile()
  local presets, names = {}, {}
  local preset_cnt = 0
  if reaper.file_exists(presets_file) then
    local file = io.open(presets_file)
    local contents = file:read("*a")
    file:close()
    for name,a,b,c,d,e,f in contents:gmatch("(.-)  @  (%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%d+),(%d+)\n") do
      preset_cnt = preset_cnt + 1
      presets[preset_cnt] = {a,b,c,d,e,f, name = name}
    end
    table.sort(presets, function(a,b) return a.name:upper() < b.name:upper() end)
  else
    local file = io.open(presets_file, "w")
    file:close()
  end
  if #presets > 0 then
    for i = 1, #presets do
      names[presets[i].name] = i
    end
  end
  return presets, names
end

function Presetsfunc()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  local presets, names = GetPresetsFromFile()
  -- Create menu
  local menu = ""
  if #presets > 0 then
    for i = 1, #presets do
      local checked = active_preset == presets[i].name and "!" or ""
      menu = menu .. checked .. presets[i].name .. "|"
    end
  else
    menu = "#(no saved presets)|"
  end
  local a = active_preset and "" or "#"
  local options = "|Save as new preset|" .. a .. "Rename selected preset|" .. 
  a .. "Update settings of selected preset|" .. a .. "Delete selected preset"
  -- Show menu
  gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y
  local selection = gfx.showmenu( menu .. options )
  local update = false
  local selection_cnt = (#presets == 0 and 1 or #presets) + 4
 -- What to do with selection
  if selection == selection_cnt - 3 then
    -- Save
    local ok, name = reaper.GetUserInputs( "Save preset", 1, "Enter preset name :,extrawidth=100", "" )
    if ok then
      name = name:match("^%s*(.-)%s*$") -- remove any leading and trailing spaces
      if name == "" then
        reaper.MB( "Name cannot be empty!", "Empty name", 0 )
        return
      end
      if name then
        if not names[name] then
          local values = {}
          for i = 1, 6 do
            values[i] = cur_ParmValues[i].v
          end
          local file = io.open(presets_file, "a")
          file:write(name .. "  @  " .. table.concat(values, ",") .. "\n")
          file:close()
        else
          update = true
        end
        active_preset = name
      end
    end
  elseif selection == selection_cnt - 2 then
    -- Rename
    local ok, name = reaper.GetUserInputs( "Rename preset", 1, "Enter new name :,extrawidth=100", "" )
    if ok then
      name = name:match("^%s*(.-)%s*$")
      if name == "" then
        reaper.MB( "Name cannot be empty!", "Empty name", 0 )
        return
      end
      if name then
        local i = names[active_preset]
        presets[i].name = name
        WritePresetsToFile(presets)
        active_preset = name
      end
    end
  elseif selection == selection_cnt then
    -- Delete
    local ok = reaper.MB( "Are you sure you want to delete the selected preset?", "Delete selected preset", 4 )
    if ok == 6 then
      local i = names[active_preset]
      table.remove(presets, i)
      WritePresetsToFile(presets)
      active_preset = nil
    end
  elseif #presets > 0 and selection ~= 0 and not (selection == selection_cnt - 1 or update) then
    -- Load
    for i = 1, 6 do
      local val = (presets[selection][i] - cur_ParmValues[i].min) / (cur_ParmValues[i].max - cur_ParmValues[i].min)
      GUI.elms[i]:setcurval(1, val, true)
    end
    active_preset = presets[selection].name
  end
  if selection == selection_cnt - 1 or update then
    -- Update
    local ok = reaper.MB( "Would you like to update the settings of the selected preset?", "Update selected preset", 4 )
    if ok == 6 then
      local name = update and name or active_preset
      local i = names[name]
      for v = 1, 6 do
        presets[i][v] = cur_ParmValues[v].v
      end
      WritePresetsToFile(presets)
    end
  end
end

function GetLiaison()
  -- check if there is an entry for this theme in theconfig.ini
  if not reaper.file_exists(themeconfig) then return end
  local file = io.open(themeconfig)
  local found, liaison = false, false
  -- locate settings
  for line in file:lines() do
    if not found and line == "[" .. theme_name .. "]" then
      found = true
    elseif found and line:match("%[.*%]$") then
      break
    elseif found then
      if line:match("^__coloradjust") then
        liaison = true
        local i = 0
        for value in line:gmatch("%s?(%-?[%d%.]+)") do
          i = i + 1
          if i == 1 then value = math.floor(value*1000) end
          cur_Theme_ParmValues[i] = tonumber(value)
        end
      break
      end  
    end
  end
  file:close()
  return liaison
end

function SameLiaisonState()
  -- check if the current values are the same with the ones in the themeconfig.ini
  local same = true
  for i = 1, 6 do
    if cur_ParmValues[i].v ~= cur_Theme_ParmValues[i] then
      same = false
      break
    end
  end
  return same
end

function ResetAll()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  for i = 1, 6 do
    GUI.Val(i, GUI.elms[i].defaults[1])
  end
end

function ApplyToProjColors()
  _, _, apply_to_proj_colors = reaper.ThemeLayout_GetParameter( -1006 )
  apply_to_proj_colors = 1 - apply_to_proj_colors
  reaper.ThemeLayout_SetParameter( -1006, apply_to_proj_colors, false )
  GUI.elms.Apply.col_fill = apply_to_proj_colors == 1 and "green" or "elm_frame",
  GUI.elms.Apply:draw()
  GUI.elms.Apply:init()
end

function exit()
  if (CurrentValuesAreDefault() and GetLiaison() == false) or SameLiaisonState() then
    -- do not prompt to save
  else
    local ok = reaper.MB( "This means that the next time you will load this theme, these settings won't be recalled.\n\nWould you like to tie these settings to the current theme, so that they load each time you load it?", "Current settings are not tied to the current theme", 4 )
    if ok == 6 then
      SetParmValues(cur_ParmValues, true)
    end
  end
  reaper.SetToggleCommandState( section, cmdID, 0 )
  reaper.RefreshToolbar2( section, cmdID )
  return reaper.defer(function() end)
end

----------------------------------------------------------------------------

-- GUI

GUI.name = "Reaper GUI color controls XL  -  v" .. version
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 336, 355
GUI.anchor, GUI.corner = "screen", "C"
local top_space = 25
local slider_space = 40
local slider_width = 170
local slider_pos = 80
local box_space = 10
local button_space = 20
local button_width = 90
local box_width = 48
local button_height = 24

GUI.New(1, "Slider", {
    z = 1,
    x = slider_pos,
    y = top_space,
    w = slider_width,
    caption = "Gamma:",
    min = 0.25,
    max = 2,
    defaults = {75},
    inc = 0.01,
    dir = "h",
    font_a = 3,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -31 - slider_width/2,
    cap_y = 20
})

GUI.New(7, "Textbox", {
    z = 1,
    x = slider_pos + slider_width + box_space,
    y = top_space - 5,
    w = box_width,
    h = 20,
    caption = "",
    cap_pos = "right",
    font_a = 3,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 0,
    undo_limit = 5
})

GUI.New(2, "Slider", {
    z = 1,
    x = slider_pos,
    y = top_space + slider_space,
    w = slider_width,
    caption = "Shadows:",
    min = -1,
    max = 1,
    defaults = {100},
    inc = 0.01,
    dir = "h",
    font_a = 3,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -35 - slider_width/2,
    cap_y = 20
})

GUI.New(8, "Textbox", {
    z = 1,
    x = slider_pos + slider_width + box_space,
    y = top_space + slider_space -5,
    w = box_width,
    h = 20,
    caption = "",
    cap_pos = "right",
    font_a = 3,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 0,
    undo_limit = 5
})

GUI.New(3, "Slider", {
    z = 1,
    x = slider_pos,
    y = top_space + slider_space*2,
    w = slider_width,
    caption = "Midtones:",
    min = -1,
    max = 1,
    defaults = {100},
    inc = 0.01,
    dir = "h",
    font_a = 3,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -36 - slider_width/2,
    cap_y = 20
})

GUI.New(9, "Textbox", {
    z = 1,
    x = slider_pos + slider_width + box_space,
    y = top_space + slider_space*2 - 5,
    w = box_width,
    h = 20,
    caption = "",
    cap_pos = "right",
    font_a = 3,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 0,
    undo_limit = 5
})

GUI.New(4, "Slider", {
    z = 1,
    x = slider_pos,
    y = top_space + slider_space*3,
    w = slider_width,
    caption = "Highlights:",
    min = -1,
    max = 1,
    defaults = {100},
    inc = 0.01,
    dir = "h",
    font_a = 3,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -38 - slider_width/2,
    cap_y = 20
})

GUI.New(10, "Textbox", {
    z = 1,
    x = slider_pos + slider_width + box_space,
    y = top_space + slider_space*3 - 5,
    w = box_width,
    h = 20,
    caption = "",
    cap_pos = "right",
    font_a = 3,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 0,
    undo_limit = 5
})

GUI.New(5, "Slider", {
    z = 1,
    x = slider_pos,
    y = top_space + slider_space*4,
    w = slider_width,
    caption = "Saturation:",
    min = 0,
    max = 200,
    defaults = {100},
    inc = 1,
    dir = "h",
    font_a = 3,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -39 - slider_width/2,
    cap_y = 20
})

GUI.New(11, "Textbox", {
    z = 1,
    x = slider_pos + slider_width + box_space,
    y = top_space + slider_space*4 - 5,
    w = box_width,
    h = 20,
    caption = "%",
    cap_pos = "right",
    font_a = 3,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 5,
    undo_limit = 5
})

GUI.New(6, "Slider", {
    z = 1,
    x = slider_pos,
    y = top_space + slider_space*5,
    w = slider_width,
    caption = "Tint:",
    min = -180,
    max = 180,
    defaults = {180},
    inc = 1,
    dir = "h",
    font_a = 3,
    font_b = 2,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = -21 - slider_width/2,
    cap_y = 20
})

GUI.New(12, "Textbox", {
    z = 1,
    x = slider_pos + slider_width + box_space,
    y = top_space + slider_space*5 - 5,
    w = box_width,
    h = 20,
    caption = "deg",
    cap_pos = "right",
    font_a = 3,
    font_b = "monospace",
    color = "white",
    bg = "wnd_bg",
    shadow = true,
    pad = 3,
    undo_limit = 5
})

GUI.New("Presets", "Button", {
    z = 1,
    x = button_space,
    y = top_space + slider_space*6 - 5,
    w = button_width,
    h = button_height,
    caption = "Presets",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = Presetsfunc
})

GUI.New("AB", "Button", {
    z = 1,
    x = (GUI.w - button_width)/2,
    y = top_space + slider_space*6 - 5,
    w = button_width,
    h = button_height,
    caption = "A  /  B",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = ABfunc
})

GUI.New("Reset", "Button", {
    z = 1,
    x = GUI.w - button_width - button_space,
    y = top_space + slider_space*6 - 5,
    w = button_width,
    h = button_height,
    caption = "Reset all",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = ResetAll
})

GUI.New("Tie", "Button", {
    z = 1,
    x = button_space+5,
    y = top_space + slider_space*7 - 5,
    w = button_width * 1.55,
    h = button_height,
    caption = "Tie to current theme",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = TieToTheme
})

GUI.New("Apply", "Button", {
    z = 1,
    x = GUI.w - button_width*1.5 - button_space - 5,
    y = top_space + slider_space*7 - 5,
    w = button_width*1.55,
    h = button_height,
    caption = "Apply to proj colors",
    font = 2,
    col_txt = "white",
    col_fill = apply_to_proj_colors == 1 and "green" or "elm_frame",
    func = ApplyToProjColors
})


----------------------------------------------------------------------------

-- GUI FUNCTIONS

function GUI.Textbox:lostfocus()
  local val = tonumber(self.retval)
  if not val then return end
  local slider = GUI.elms[self.name - 6]
  if val < slider.min then
    val = slider.min
  elseif val > slider.max then
    val = slider.max
  end
  GUI.Val(self.name - 6, ( slider.steps * ( val - slider.min ) ) / ( slider.max - slider.min ) )
end

function GUI.Slider:drawslidervalue(x, y, sldr)
  if not GUI.elms[self.name + 6].focus then
    local output = self.handles[sldr].retval
    if self.name < 5 then
      output = string.format("%.2f", output)
    end
    GUI.Val(self.name + 6, output)
  end
end

function GUI.Slider:setretval(sldr)
  local val = self.inc * self.handles[sldr].curstep + self.min
  self.handles[sldr].retval = val
end

function SetParameter(nr)
  local parm = -999 - (nr)
  local _, _, cur_reap_val, _, min, max = reaper.ThemeLayout_GetParameter(parm)
  local reap_val = GUI.round( GUI.elms[nr].handles[1].curval * (max - min) + min )
  cur_ParmValues[nr].v = reap_val
  reaper.ThemeLayout_SetParameter( parm, reap_val, false )
end

function GUI.Slider:setcurstep(sldr, step, set)
  if set == nil then set = true end
  self.handles[sldr].curstep = step
  self.handles[sldr].curval = self.handles[sldr].curstep / self.steps
  self:setretval(sldr)
  if set then
    SetParameter(self.name)
  end
end

function GUI.Slider:setcurval(sldr, val, set)
  if set == nil then set = true end
  self.handles[sldr].curval = val
  self.handles[sldr].curstep = GUI.round(val * self.steps)
  self:setretval(sldr)
  if set then
    SetParameter(self.name)
  end
end

function SetSliders()
-- Set sliders to current values
  for i = 1, 6 do
    local val = (cur_ParmValues[i].v - cur_ParmValues[i].min) / (cur_ParmValues[i].max - cur_ParmValues[i].min)
    GUI.elms[i]:setcurval(1, val, false)
  end
end

function extra()
 local theme = reaper.GetLastColorThemeFile() 
  if theme ~= cur_theme then
    cur_theme = theme
    theme_name = cur_theme:match("^.+[/\\](.+)%.[Rr][Ee][Aa][Pp][Ee][Rr][Tt][Hh][Ee][Mm][Ee][Zz]?[Ii]?[Pp]?")
    GetParmValues()
    SetSliders()
    tied = GetLiaison() and SameLiaisonState()
  end
  if prev_tied ~= tied then
    prev_tied = tied
    GUI.elms.Tie.col_fill = (tied and (not CurrentValuesAreDefault())) and "green" or "elm_frame"
    GUI.elms.Tie:init()
  end
  if AB_mode then
    for i = 1, 6 do
      if GUI.elms[i].focus then
        AB_mode = false
        GUI.elms.AB.col_fill = AB_mode and "green" or "elm_frame"
        GUI.elms.AB:init()
      end
    end
  end
end

local function force_size()
  gfx.quit()
  gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock, GUI.x, GUI.y)
  GUI.cur_w, GUI.cur_h = GUI.w, GUI.h
end

----------------------------------------------------------------------------

-- START SCRIPT

local fonts = GUI.get_OS_fonts()
GUI.fonts.monospace = {fonts.mono, 12}
GUI.fonts[2] = {fonts.sans, 18}
GUI.fonts.version = {fonts.sans, 13, "i"}
GUI.colors.white = {225, 225, 225, 255}
GUI.Draw_Version = function ()
  if not GUI.version then return 0 end
  local str = "Script by amagalma  -  using Lokasenna_GUI " .. GUI.version
  GUI.font("version")
  GUI.color("txt")
  local str_w, str_h = gfx.measurestr(str)
  gfx.x = gfx.w/2 - str_w/2
  gfx.y = gfx.h - str_h - 4
  gfx.drawstr(str)
end

GetLiaison()
GetParmValues()
SetSliders()
tied = SameLiaisonState()
GUI.onresize = force_size
GUI.func = extra
GUI.exit = exit
GUI.Init()
GUI.Main()

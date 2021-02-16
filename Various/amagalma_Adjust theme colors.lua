-- @description Adjust theme colors
-- @author amagalma
-- @version 2.19
-- @changelog
--   - added "Selected track background" which had been forgotten out
-- @provides [extension windows] 7za.exe https://www.dropbox.com/s/nyrrt3h64u0gojw/7za.exe?dl=1
-- @link http://forum.cockos.com/showthread.php?t=232639
-- @about
--   # Adjusts the colors of any ReaperTheme/ReaperThemeZip
--
--   - Theme supports both zipped and unzipped themes
--   - Offers Brightness, Contrast and Gamma adjustments
--   - Tooltips to always inform user of what is happening
--   - A/B Button to toggle between the current setting and the original theme colors
--   - Use the Take Snapshot button to store settings and make new adjustments on these rather than the original theme's colors
--   - Take Snapshot button: left-click to add new, right-click to replace current selected
--   - The Snapshots are the base colors on which you make adjustments using the sliders
--   - The adjustments are applied to the selected color groups in the Color Groups Tab. The rest of the theme colors are copied over
--   - In the Color Groups Tab you can inspect or change the theme colors on which the adjustments apply
--   - In the Listbox you can choose (click) or delete (Alt-click) your saved Snapshots
--   - If you change the Color Groups selection, and the new selection includes groups of the previous selection, a Snapshot is automatically taken
--   - UNDO/REDO buttons to undo/redo adjustments made on the selected theme color Snapshot in the Listbox
--   - User is prompted to save when exiting and if there were color changes in comparison to the original theme
--   - If user changes theme while the script is running, script automatically closes and prompts user to save if there were any changes
--   - The new saved adjusted theme inherits the old theme's "Default_6.0 theme adjuster" settings, if any
--   - Script Requires Lokasenna GUI v2 and JS_ReaScriptAPI to work. Both are checked if they exist at the start of the script


local version = "2.19"
-----------------------------------------------------------------------


-- Global variables
local reaper = reaper
local math = math

local path, theme
local ReaperThemeName -- name_of_theme.ReaperTheme
local zipped = false -- if ReaperThemeZip
local loaded, userchangedtheme = false, false -- used to check if user changed theme while script is running

local Win = string.find(reaper.GetOS(), "Win" )
local sep = Win and "\\" or "/"
local ResourcePath = reaper.GetResourcePath()
local Start = reaper.time_precise()

local AB_mode = false -- toggle current colors vs original theme colors

-- Variables and Tables working with color data
local current = 1 -- current colors to be adjusted (1 = original theme colors)
local cur_version = 1 -- used for undo/redo
local snapshot = 0 -- used for enumerating the snapshots
local settings = {} -- table to store sliders' values
settings[cur_version] = {g = 1, b = 0, c = 0} -- default settings / no changed colors
-- table with the Color Groups selection
local group_settings = { false, true, false, true, true, true, false, false, false, true, true, true, true, false }
local col = {} -- holds the actual color values for the reconstruction of the ReaperTheme file
local fon = {} -- holds the fonts/etc for the reconstruction of the ReaperTheme file
col[0] = {{}}
col[1] = {{}}


----------------------------------------------------------------------- Checks


-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_Dialog_BrowseForSaveFile") then
  reaper.MB( "Please, right-click and install 'js_ReaScriptAPI: API functions for ReaScripts'. Then restart Reaper and run the script again. Thanks!", "JS_ReaScriptAPI Installation", 0 )
  local ok, err = reaper.ReaPack_AddSetRepository( "ReaTeam Extensions", "https://github.com/ReaTeam/Extensions/raw/master/index.xml", true, 1 )
  if ok then
    reaper.ReaPack_BrowsePackages( "js_ReaScriptAPI" )
  else
    reaper.MB( err, "Something went wrong...", 0)
  end
  return reaper.defer(function() end)
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
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Listbox.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Tabs.lua")()
if missing_lib then 
  reaper.MB("Please re-install 'Lokasenna's GUI library v2 for Lua'", "Missing library!", 0)
  return reaper.defer(function() end)
end
GUI.colors.dark = {76,76,76,255} -- color for inactive buttons
local GUI = GUI


-- Function to extract theme --
function UnzipReaperTheme(ReaperThemeZip)
  ReaperThemeName = ReaperThemeZip:match([[.*[\/]([^\/]-)[zZ][iI][pP]$]])
  local TempFolder = string.match(reaper.time_precise()*100, "(%d+)%.") -- will be a random number in the same dir as the ReaperThemeZip
  local FullTempFolder = (Win and ReaperThemeZip:match("(.*\\)") or ReaperThemeZip:match("(.*/)")) .. TempFolder
  local ColorthemePath = ResourcePath .. sep .. "ColorThemes" .. sep
  local cmd, script_path
  if Win then
    local exepath = ResourcePath .. sep .. "UserPlugins" .. sep .. "7za.exe"
    if not reaper.file_exists(exepath) then
      reaper.MB( "7za.exe is needed for the extraction.\n" .. exepath, "Quitting...", 0 )
      return
    end
    reaper.ExecProcess( 'cmd.exe /C ""' .. exepath .. '" e "' .. ReaperThemeZip .. '" *.ReaperTheme -y -o"' .. FullTempFolder .. '""', 500 )
  else -- OSX/LINUX (use unzip)
    local pipe = io.popen('read a; read d; unzip -oqq "$a" "*.ReaperTheme" -d "$d"', "w")
    pipe:write(ReaperThemeZip .. '\n')
    pipe:write(FullTempFolder .. '\n')
    pipe:close()
  end
  local ReaperTheme = reaper.EnumerateFiles( FullTempFolder, 0 )
  if ReaperTheme then
    -- Move extracted theme to ColorThemes directory and name it as the zipped file
    os.rename(FullTempFolder .. sep .. ReaperTheme, ColorthemePath .. ReaperThemeName)
    -- Delete temporary folder
    if Win then
      reaper.ExecProcess('cmd.exe /C rd /s/q "'.. FullTempFolder ..'"' , 200)
    else
      local ok = os.remove(FullTempFolder)
      if not ok then os.execute('rm -r "'.. FullTempFolder ..'"') end
    end
    return ColorthemePath .. ReaperThemeName -- full path to extracted ReaperTheme file
  else
    local msg
    if Win then
      msg = ""
    else
      msg = "Check that you have 'unzip' installed."
    end
    reaper.MB( "Failed to unzip the ReaperThemeZip file. " .. msg, "Something went wrong...", 0 )
    return
  end
end


-- Load theme --
theme = reaper.GetLastColorThemeFile()
-- fix for native function's erratic behavior of sometimes returning the actual .ReaperThemeZip ---
theme = theme:gsub("([zZ][iI][pP])$", "")                                                        --
---------------------------------------------------------------------------------------------------
--reaper.ShowConsoleMsg(theme .. "\n")
if not reaper.file_exists(theme) then
  if reaper.file_exists(theme .. "Zip") then
    -- do not change order!
    zipped = theme
    theme = theme .. "Zip"
    theme = UnzipReaperTheme(theme)
  else
    reaper.MB( "The file of the currently loaded theme does no longer exist.", "Quitting...", 0 )
    return reaper.defer(function() end)
  end
end
if theme then
  if Win then
    path, theme = theme:match("(.*\\)(.+)")
  else
    path, theme = theme:match("(.*/)(.+)")
  end
else
  return reaper.defer(function() end)
end
ReaperThemeName = theme


-----------------------------------------------------------------------


-- Table with all the color groups that will be adjusted --
local gr = {}
-- Main window
gr[2] = { "col_main_bg2", "col_main_text2", "col_main_textshadow", "col_main_3dhl", "col_main_3dsh", "col_main_resize2", "col_transport_editbk", "col_toolbar_text", "col_toolbar_text_on", "col_toolbar_frame", "toolbararmed_color", "io_text", "io_3dhl", "io_3dsh", "col_tracklistbg", "col_mixerbg", "col_trans_bg", "col_trans_fg" }
-- Other windows (like Action List etc)
gr[3] = { "col_main_text", "col_main_bg", "col_main_editbk", "genlist_bg", "genlist_fg", "genlist_grid", "genlist_selbg", "genlist_selfg", "genlist_seliabg", "genlist_seliafg" }
-- Dockers & Tabs
gr[4] = { "docker_shadow", "docker_selface", "docker_unselface", "docker_text", "docker_text_sel", "docker_bg", "windowtab_bg" }
-- Timeline & Lanes
gr[5] = { "col_tl_fg", "col_tl_fg2", "col_tl_bg", "col_tl_bgsel", "col_tl_bgsel2", "region", "region_lane_bg", "region_lane_text", "marker", "marker_lane_bg", "marker_lane_text", "col_tsigmark", "ts_lane_bg", "ts_lane_text", "timesig_sel_bg" }
-- Arrange
gr[6] = { "col_tr1_bg", "col_tr2_bg", "selcol_tr1_bg", "selcol_tr2_bg", "col_tr1_divline", "col_tr2_divline", "col_envlane1_divline", "col_envlane2_divline", "col_arrangebg", "arrange_vgrid", "col_gridlines2", "col_gridlines3", "col_gridlines" }
-- Media Item Labels
gr[7] = { "col_mi_label", "col_mi_label_sel", "col_mi_label_float", "col_mi_label_float_sel" }
-- Media Item Peaks
gr[8] = { "col_tr1_peaks", "col_tr2_peaks", "col_tr1_ps2", "col_tr2_ps2", "col_peaksedge", "col_peaksedge2", "col_peaksedgesel", "col_peaksedgesel2", "col_peaksfade1", "col_peaksfade2" }
-- Marks on Media Items
gr[9] = { "col_mi_fades", "fadezone_color", "fadearea_color", "col_mi_fade2", "item_grouphl", "col_offlinetext", "col_stretchmarker", "col_stretchmarker_h0", "col_stretchmarker_h1", "col_stretchmarker_h2", "col_stretchmarker_b", "col_stretchmarker_text", "col_stretchmarker_tm", "take_marker" }
-- MCP texts (FX & Sends)
gr[10] = { "mcp_fx_normal", "mcp_fx_bypassed", "mcp_fx_offlined", "mcp_sends_normal", "mcp_sends_muted", "mcp_send_midihw", "mcp_sends_levels", "mcp_fxparm_normal", "mcp_fxparm_bypassed", "mcp_fxparm_offlined" }
-- MIDI Editor
gr[11] = { "midieditorlist_bg", "midieditorlist_fg", "midieditorlist_grid", "midieditorlist_selbg", "midieditorlist_selfg", "midieditorlist_seliabg", "midieditorlist_seliafg", "midieditorlist_bg2", "midieditorlist_fg2", "midieditorlist_selbg2", "midieditorlist_selfg2" }
-- MIDI List Editor
gr[12] = { "midi_rulerbg", "midi_rulerfg", "midi_grid2", "midi_grid3", "midi_grid1", "midi_trackbg1", "midi_trackbg2", "midi_trackbg_outer1", "midi_trackbg_outer2", "midi_selpitch1", "midi_selpitch2", "midi_selbg", "midi_gridhc", "midi_gridh", "midi_ccbut", "midioct", "midi_inline_trackbg1", "midi_inline_trackbg2", "midioct_inline", "midi_endpt" }
-- Wiring
gr[13] = { "wiring_grid2", "wiring_grid", "wiring_border", "wiring_tbg", "wiring_ticon", "wiring_recbg", "wiring_recitem", "wiring_media", "wiring_recv", "wiring_send", "wiring_fader", "wiring_parent", "wiring_parentwire_border", "wiring_parentwire_master", "wiring_parentwire_folder", "wiring_pin_normal", "wiring_pin_connected", "wiring_pin_disconnected", "wiring_horz_col", "wiring_sendwire", "wiring_hwoutwire", "wiring_recinputwire", "wiring_hwout", "wiring_recinput" }
-- All cursors (play/edit/midi)
gr[14] = { "col_cursor", "col_cursor2", "playcursor_color", "midi_editcurs" }

-- Table that will hold the selected tables combined
local t = {}


-----------------------------------------------------------------------


-- Functions --


function round(num)
  if num >= 0 then return math.floor(num + 0.5)
  else return math.ceil(num - 0.5)
  end
end


function rng(value) -- Keep value between range 0 to 255
  if value < 0 then value = 0 end
  if value > 255 then value = 255 end
  return round(value)
end


function MakeColorGroupTable(grouplist)
  t = {} -- empty current combination
  local n = 0
  for i = 2, 14 do
    if grouplist[i] then
      for j = 1, #gr[i] do
        n = n + 1
        t[n] = gr[i][j]
      end
    end
  end
end


function TableContentsAreEqual(t1, t2)
  for k,v in pairs(t1) do
    if (t2[k] == nil) or (t2[k] ~= v) then return false end
  end
  return true
end


function CompareGroupSelection(new, old)
  local total = 0
  local same = 0
  for i = 1, 14 do
    if old[i] then
      total = total + 1
      if new[i] == old[i] then same = same + 1 end
    end
  end
  -- returns -1 for being exactly the same | 0 for new not having common groups | 1 for having common groups selected
  return same == 0 and 0 or (same == total and -1 or 1)
end


function BrightnessContrast(r,g,b, brightness, contrast) -- change range -255 to 255
  local f = 5440/21 -- 259.047619048
  local factor = (f * (contrast + 255)) / (255 * (f - contrast))
  r = factor * (r - 128) + 128 + brightness
  g = factor * (g - 128) + 128 + brightness
  b = factor * (b - 128) + 128 + brightness
  return rng(r), rng(g), rng(b)
end


function Gamma(r,g,b, change) -- change range 0.01 to 7.99
  local correction = 1 / change
  r = 255 * (r / 255) ^ correction
  g = 255 * (g / 255) ^ correction
  b = 255 * (b / 255) ^ correction
  return rng(r), rng(g), rng(b)
end


function GetThemeColors()
  local file, record, reap = io.open(path .. theme)
  for line in file:lines() do
    if line == "[color theme]" then
      record = true
      reap = false
    end
    if line == "[REAPER]" then
      record = false
      reap = true
    end
    if record then
      local k, v = string.match(line, "([^%s]-)=([^%s/n/r]+)")
      if k and v then
        col[0][1][k] = tonumber(v) -- table with original theme colors (for AB)
        col[1][1][k] = tonumber(v) -- table to store theme colors
      end
    end
    if reap then
      -- point to zip file if zipped
      if zipped then 
        if line:find("^[uU][iI]_[iI][mM][gG]%s*=") then
          line = "ui_img=" .. ReaperThemeName .. "Zip"
        elseif line:find("^[uU][iI]_[iI][mM][gG]_[pP][aA][tT][hH]%s*=") then
          line = nil
        end
      end
      if line then fon[#fon+1] = line end
    end
  end
  io.close(file)
end


function WriteFile(setting,version)
  local file = io.open(path .. "adjusted__" .. theme, "w+")
  file:write("[color theme]\n")
  for k, v in pairs(col[setting][version]) do
    file:write(k .. "=" .. tostring(v) .. "\n")
  end
  file:write(table.concat(fon, "\n"))
  io.close(file)
  reaper.OpenColorThemeFile(path .. "adjusted__" .. theme )
end


function AdjustColors()
  -- if settings have not been changed then do nothing and tell to user
  if settings[cur_version] and ( (settings[cur_version].g == GUI.Val("Gamma") and
     settings[cur_version].c == GUI.Val("Contrast") and
     settings[cur_version].b == GUI.Val("Brightness")) )
  then
    GUI.settooltip( "No changed settings" )
    return
  end
  -- prepare to overwrite settings (needed for clean undo-redo)
  if cur_version ~= #settings then
    for i = cur_version+1, #settings do
      settings[i] = nil
      col[current][i] = nil
    end
  end
  -- create new table for new settings
  cur_version = #settings + 1
  col[current][cur_version] = {}
  -- copy the base settings from the first setting
  for k,v in pairs(col[current][1]) do
    col[current][cur_version][k] = v
  end
  for i = 1, #t do
    if col[current][1][t[i]] then
      local fix = 0
      if col[current][1][t[i]] < 0 then fix = 2147483648 end
      local r, g, b = reaper.ColorFromNative( col[current][1][t[i]] - fix )
      r, g, b = BrightnessContrast(r, g, b, GUI.Val("Brightness"), GUI.Val("Contrast") )
      r, g, b = Gamma(r, g, b, GUI.Val("Gamma"))
      col[current][cur_version][t[i]] = reaper.ColorToNative( r, g, b ) + fix
    end
  end
  -- store settings
  settings[cur_version] = {}
  settings[cur_version].g = GUI.Val("Gamma")
  settings[cur_version].b = GUI.Val("Brightness")
  settings[cur_version].c = GUI.Val("Contrast")
  -- Enable Undo Button
    SetUndoRedoButtons(1, 0)
  -- Write adjusted file
  WriteFile(current, cur_version)
end


function SetUndoRedoButtons(undo, redo) -- -1 = no change, 0 = disabled, 1 = enabled
  if undo ~= -1 then
    GUI.elms.Undo.col_txt = undo == 0 and "txt" or "white"
    GUI.elms.Undo.col_fill = undo == 0 and "dark" or "elm_frame"
    GUI.elms.Undo:init()
    GUI.elms.Undo:redraw()
  end
  if redo ~= -1 then
    GUI.elms.Redo.col_txt = redo == 0 and "txt" or "white"
    GUI.elms.Redo.col_fill = redo == 0 and "dark" or "elm_frame"
    GUI.elms.Redo:init()
    GUI.elms.Redo:redraw()
  end
end


function SetSliders(brightness, contrast, gamma)
  GUI.Val("Brightness", (brightness - GUI.elms.Brightness.min)/GUI.elms.Brightness.inc )
  GUI.Val("Contrast", (contrast - GUI.elms.Contrast.min)/GUI.elms.Contrast.inc )
  GUI.Val("Gamma", (gamma - GUI.elms.Gamma.min)/GUI.elms.Gamma.inc )
end


function Load(setting,version)
  WriteFile(setting,version)
  -- Set sliders
  SetSliders(settings[version].b, settings[version].c, settings[version].g)
end


function AB()
  AB_mode = not AB_mode -- toggle
  -- change color button
  GUI.elms.AB.col_fill = AB_mode and "green" or "elm_frame"
  GUI.elms.AB:init()
  GUI.settooltip( "Toggle between current setting and original theme colors" )
  if AB_mode then -- recall original
    Load(0,1)
  else -- recall previous
    Load(current, cur_version)
  end
end


function InheritSettings(SectionName)
  local copy = false
  local themeconfig = ResourcePath .. sep .. [[reaper-themeconfig.ini]]
  if not reaper.file_exists(themeconfig) then return end
  file = io.open(themeconfig, "a+")
  -- locate settings to inherit
  local section = ReaperThemeName:match("(.*)%.[rR][eE][aA][pP][eE][rR][tT][hH][eE][mM][eE]$")
  local section_settings = {}
  for line in file:lines() do
    if line == "[" .. section .. "]" then copy = true
    elseif copy and line:match("%[.*%]$") then copy = false
    end
    if copy then
      section_settings[#section_settings+1] = line
    end
  end
  -- append inherited settings if they exist
  if #section_settings > 1 then
    section_settings[1] = "[" .. SectionName .. "]"
    file:write("\n" .. table.concat(section_settings, "\n"))
  end
  file:close()
end


function TakeSnapshot(automatic, overwrite)
-- set automatic to true if function is NOT called by the Take Snapshot button
-- set overwrite to true if you want to overwrite the current Snapshot
  -- disable if in AB_mode
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  if not automatic then
    -- if settings have not been changed (same with the previous) then do nothing and tell to user
    if not settings[cur_version-1] or ( 
        settings[cur_version-1].g == GUI.Val("Gamma") and
        settings[cur_version-1].c == GUI.Val("Contrast") and
        settings[cur_version-1].b == GUI.Val("Brightness")
        )
    then
      GUI.settooltip("No adjustments have been made")
      return
    end
  end
  overwrite = overwrite and -1 or 0
  snapshot = snapshot + 1
  if overwrite == 0 then -- create new
    col[#col+1] = {[1] = col[current][cur_version]}
  else -- overwrite
    col[current][1] = col[current][cur_version]
  end
  -- delete undo settings no longer needed
  for i = 2, #col[current] do
    col[current][i] = nil
  end
  -- make a new start for adjustments
  settings = {}
  cur_version = 1
  settings[cur_version] = {g = 1, b = 0, c = 0}
  current = overwrite == 0 and #col or current
  -- Set sliders
  SetSliders(0, 0, 1)
  -- Update listbox
  GUI.elms.Compare.list[overwrite == 0 and #GUI.elms.Compare.list+1 or current] = "Adjusted colors Snapshot #" .. snapshot
  GUI.elms.Compare:init()
  GUI.Val("Compare", current)
  if #settings > 6 then
    GUI.elms.Compare.wnd_y = GUI.clamp(1, GUI.elms.Compare.wnd_y + 1, math.max(#GUI.elms.Compare.list - GUI.elms.Compare.wnd_h + 1, 1))
    GUI.elms.Compare:redraw()
  end
  -- darken Undo & Redo buttons
  SetUndoRedoButtons(0, 0)
  if overwrite == 0 then
    GUI.settooltip( "Added new Snapshot" )
  else
    GUI.settooltip( "Overwrote current Snapshot" )
  end
end


function UNDO()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  elseif #settings == 1 then
    GUI.settooltip( "There are no other settings" )
    return
  elseif cur_version == 1 then
    GUI.settooltip( "Cannot Undo\nReached first setting" )
    return
  end
  cur_version = cur_version - 1
  Load(current, cur_version)
  local undo = cur_version == 1 and 0 or 1
  local redo = cur_version == #settings and 0 or 1
  SetUndoRedoButtons(undo, redo)
end


function REDO()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  elseif #settings == 1 then
    GUI.settooltip( "There are no other settings" )
    return
  elseif cur_version == #settings then
    GUI.settooltip( "Cannot Redo\nReached last setting" )
    return
  end
  cur_version = cur_version + 1
  Load(current, cur_version)
  local undo = cur_version == 1 and 0 or 1
  local redo = cur_version == #settings and 0 or 1
  SetUndoRedoButtons(undo, redo)
end


-----------------------------------------------------------------------


-- GUI Code --


GUI.name = "Adjust Theme Colors  -  v" .. version
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 330, 455
GUI.anchor, GUI.corner = "screen", "C"


-- Modified to display tooltip centered
function GUI.settooltip(str)
  if not str or str == "" then return end
  local x, y = gfx.clienttoscreen( gfx.mouse_x, gfx.mouse_y )
  reaper.TrackCtl_SetToolTip(str, x, y + 20, true)
  local hwnd = reaper.GetTooltipWindow()
  local ok, width = reaper.JS_Window_GetClientSize( hwnd )
  width = ok and math.floor(width/2) or 0
  if hwnd then reaper.JS_Window_Move( hwnd, x - width, y + 22 ) end
  GUI.tooltip = str
end


-- modified to not let user change values in AB_mode
function GUI.Slider:ondrag()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  local mouse_val, n, ln = table.unpack(self.dir == "h"
      and {(GUI.mouse.x - self.x) / self.w, GUI.mouse.x, GUI.mouse.lx}
      or  {(GUI.mouse.y - self.y) / self.h, GUI.mouse.y, GUI.mouse.ly}
  )
  local cur = self.cur_handle or 1
  -- Ctrl?
  local ctrl = GUI.mouse.cap&4==4
  -- A multiplier for how fast the slider should move. Higher values = slower
  --            Ctrl              Normal
  local adj = ctrl and 1200 or 150
  local adj_scale = (self.dir == "h" and self.w or self.h) / 150
  adj = adj * adj_scale
  self:setcurval(cur, GUI.clamp( self.handles[cur].curval + ((n - ln) / adj) , 0, 1 ) )
  self:redraw()
end


-- modified to not let user change values in AB_mode
function GUI.Slider:onwheel()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  local mouse_val = self.dir == "h"
          and (GUI.mouse.x - self.x) / self.w
          or  (GUI.mouse.y - self.y) / self.h
  local inc = GUI.round( self.dir == "h" and GUI.mouse.inc
                      or -GUI.mouse.inc )
    local cur = self:getnearesthandle(mouse_val)
  local ctrl = GUI.mouse.cap&4==4
  -- How many steps per wheel-step
  local fine = 1
  local coarse = self.steps == 400 and 10 or 5
  local adj = ctrl and fine or coarse
    self:setcurval(cur, GUI.clamp( self.handles[cur].curval + (inc * adj / self.steps) , 0, 1) )
  self:redraw()
  AdjustColors()
end


-- modified to not let user change values in AB_mode
function GUI.Slider:onmousedown()
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  local mouse_val = self.dir == "h"
    and (GUI.mouse.x - self.x) / self.w
    or  (GUI.mouse.y - self.y) / self.h
  self.cur_handle = self:getnearesthandle(mouse_val)
  self:setcurval(self.cur_handle, GUI.clamp(mouse_val, 0, 1) )
  self:redraw()
end


-- modified to not let user change values in AB_mode
function GUI.Slider:onmouseup()
  -- if in AB mode, do not let user apply changes
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  AdjustColors()
end


GUI.New("Gamma", "Slider", {
    z = 1,
    x = 15,
    y = 210,
    w = 300,
    caption = "Gamma",
    min = 0.1,
    max = 6,
    defaults = 45,
    inc = 0.02,
    dir = "h",
    font_a = 2,
    font_b = 3,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0,
    align_values = 1
})


-- Needed to display correctly number like eg 1.02
function GUI.elms.Gamma:formatretval(val)
  if val == 1 then return 1 else return val end
end


GUI.New("Brightness", "Slider", {
    z = 1,
    x = 15,
    y = 80,
    w = 300,
    caption = "Brightness",
    min = -200,
    max = 200,
    defaults = 200,
    inc = 1,
    dir = "h",
    font_a = 2,
    font_b = 3,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0,
    align_values = 1
})


GUI.New("Contrast", "Slider", {
    z = 1,
    x = 15,
    y = 145,
    w = 300,
    caption = "Contrast",
    min = -200,
    max = 200,
    defaults = 200,
    inc = 1,
    dir = "h",
    font_a = 2,
    font_b = 3,
    col_txt = "white",
    col_fill = "elm_fill",
    bg = "wnd_bg",
    show_handles = true,
    show_values = true,
    cap_x = 0,
    cap_y = 0,
    align_values = 1
})


GUI.New("Snapshot", "Button", {
    z = 1,
    x = 21,
    y = 255,
    w = 111,
    h = 28,
    caption = "Take Snapshot",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = TakeSnapshot,
})


-- Right-clicking Snapshot
function GUI.elms.Snapshot:onmouser_up()
  if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
    TakeSnapshot(false, true) -- Overwrite
  end
end


GUI.New("AB", "Button", {
    z = 1,
    x = 139,
    y = 255,
    w = 170,
    h = 28,
    caption = "A / B current vs original",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = AB,
})


-- Modified to display items centered
function GUI.Listbox:drawtext()
  GUI.color(self.color)
  GUI.font(self.font_b)
  local tmp = {}
  for i = self.wnd_y, math.min(self:wnd_bottom() - 1, #self.list) do
    local str = tostring(self.list[i]) or ""
    tmp[#tmp + 1] = str
  end
  gfx.y = self.y + self.pad
  for i = 1, #tmp do
    gfx.x = self.x + self.pad
    local r = gfx.x + self.w - 2*self.pad
    local b = gfx.y + self.h - 2*self.pad
    gfx.drawstr( tmp[i], 1, r, b)
    gfx.y = gfx.y + 20
  end
end


-- Modified so that: Load when you click | Delete when Alt-click an item
function GUI.Listbox:onmouseup()
  if not self:overscrollbar() then
    local x, y = gfx.clienttoscreen( GUI.elms.Compare.x, GUI.elms.Compare.y )
    local item = self:getitem(GUI.mouse.y)
    
    -- Alt-click --
    if GUI.mouse.cap & 16 == 16 then
      if item == 1 then -- protect original colors setting
        GUI.settooltip( "Can't delete first Snapshot" )
        return
      else
        if AB_mode then
          if item == current then
            GUI.settooltip( "Can't delete previous setting while in A/B mode" )
            return
          else
            table.remove(self.list, item)
            table.remove(col, item)
            if current > item then
              current = current - 1
              GUI.Val("Compare", current)
            end
          end
        else -- delete item and setting
          table.remove(self.list, item)
          table.remove(col, item)
          if current >= item then
            current = current - 1
            GUI.Val("Compare", current)
            Load(current,1)
          end
        end
      end
        
    -- Left Click --
    else
      if not AB_mode and current == item then
        GUI.settooltip( "Your color adjustments are\napplied on this version already" )
        return
      elseif AB_mode and item == 1 then
        GUI.settooltip( "A / B mode is enabled. Already\nviewing original theme colors" )
        return
      else
        -- Load selected item
        self.retval = {[item] = true}
        Load(item,1)
        -- if in AB mode, exit it
        if AB_mode then
          GUI.elms.AB.col_fill = "elm_frame"
          GUI.elms.AB:init()
          AB_mode = false
        end
        current = item
      end
    
    end
  end
  self:redraw()
end


GUI.New("Compare", "Listbox", {
    z = 1,
    x = 21,
    y = 300,
    w = 210,
    h = 131,
    list = {"--  Original theme colors  --"},
    multi = false,
    caption = "",
    font_a = 3,
    font_b = 2,
    color = "white",
    col_fill = "elm_fill",
    bg = "elm_bg",
    cap_bg = "wnd_bg",
    shadow = false,
    pad = 5,
})


-- modified to create Table for Color Groups
function GUI.Tabs:onmousedown()
  -- disable if in AB_mode
  if AB_mode then
    GUI.settooltip( "Exit A/B mode first" )
    return
  end
  -- Offset for the first tab
  local previous_state = self.state  
  local adj = 0.75*self.h
  local mouseopt = (GUI.mouse.x - (self.x + adj)) / (#self.optarray * (self.tab_w + self.pad))
  mouseopt = GUI.clamp((math.floor(mouseopt * #self.optarray) + 1), 1, #self.optarray)
  -- Create table when leaving Color Groups tab
  if previous_state == 2 and mouseopt == 1 then
    -- check that there is at least one selected Group before leaving
    local ok = false
    for i = 1, 14 do
      if GUI.elms.Groups.optsel[i] then
        ok = true
        break
      end
    end
    if not ok then
      GUI.settooltip("Cannot exit if not at least\none group is selected")
      return
    end
    local result = CompareGroupSelection(GUI.elms.Groups.optsel, group_settings)
    if result == -1 then
      -- do nothing
    else
      group_settings = {table.unpack(GUI.elms.Groups.optsel)}
      MakeColorGroupTable(GUI.elms.Groups.optsel)
      if result == 1 and cur_version ~= 1 then
        TakeSnapshot(true)
        GUI.settooltip("New Color Groups selection has common groups with the old one: new Snapshot was automatically taken")
      else
        TakeSnapshot(true, true)
        GUI.settooltip("New Color Groups selection has no common groups with the previous: new Snapshot overwrote old one")
      end
    end 
  end
  self.state = mouseopt
  self:redraw()
end


GUI.New("Tabs", "Tabs", {
    z = 10,
    x = 13,
    y = 10,
    w = 300,
    caption = "Tabs",
    optarray = {"Settings", "Color Groups"},
    tab_w = 134,
    tab_h = 22,
    pad = 5,
    font_a = 2,
    font_b = 2,
    col_txt = "white",
    col_tab_a = "green",
    col_tab_b = "tab_bg",
    bg = "elm_bg",
    fullwidth = false
})
GUI.elms.Tabs:update_sets({ [1] = {1}, [2] = {2} })


GUI.New("Undo", "Button", {
    z = 1,
    x = 239,
    y = 312,
    w = 70,
    h = 35,
    caption = "UNDO",
    font = 3,
    col_txt = "txt", -- white
    col_fill = "dark", -- "elm_frame"
    func = UNDO
})


GUI.New("Redo", "Button", {
    z = 1,
    x = 239,
    y = 368,
    w = 70,
    h = 35,
    caption = "REDO",
    font = 3,
    col_txt = "txt", -- white
    col_fill = "dark", -- "elm_frame"
    func = REDO
})


-- modified to toggle Select/Unselect All
function GUI.Checklist:onmouseup()
  if not self.focus then
    self:redraw()
    return
  end
  local mouseopt = self:getmouseopt()
  if not mouseopt then return end
  self.optsel[mouseopt] = not self.optsel[mouseopt]
  -- toggle Select All
  if mouseopt == 1 then
    if self.optsel[mouseopt] then
      -- select all
      for i = 2, 14 do
        self.optsel[i] = true
      end
    else -- unselect all
      for i = 2, 14 do
        self.optsel[i] = false
      end
    end
  else
    -- Set Select All to false, if any button is false, or true if all true
    for i = 2, 14 do
      if not self.optsel[i] then
        self.optsel[1] = false
        break
      else
        self.optsel[1] = true
      end
    end
  end
  self.focus = false
  self:redraw()
end


GUI.New("Groups", "Checklist", {
    z = 2,
    x = 15,
    y = 51,
    w = 300,
    h = 376,
    caption = "",
    optarray = {"--  SELECT ALL  --", "Main window", "Other windows  ( like Action List etc )", "Dockers & Tabs", "Timeline & Marker / Region Lanes", "Arrange", "Media Item Labels", "Media Item Peaks", "Marks on Media Items", "MCP texts  ( FX & Sends )", "MIDI Editor", "MIDI List Editor", "Wiring", "All cursors  ( play / edit / midi )"},
    dir = "v",
    pad = 6,
    font_a = 2,
    font_b = 2,
    col_txt = "white",
    col_fill = "green",
    bg = "wnd_bg",
    frame = true,
    shadow = true,
    swap = false,
    opt_size = 20
})


-----------------------------------------------------------------------


function Additional()
  -- do not let resize
  if gfx.w ~= GUI.w or gfx.h ~= GUI.h then
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, 0, GUI.x, GUI.y)
  end
  -- check if the user changed theme while having open the script
  if GUI.last_time >= Start + 1 then
    Start = GUI.last_time
    loaded = reaper.GetLastColorThemeFile()
    -- fix for native function's erratic behavior of sometimes returning the actual .ReaperThemeZip ---
    loaded = loaded:gsub("([zZ][iI][pP])$", "")   
    local loaded2 = loaded:match(".*[\\/](.+)")
    --reaper.ShowConsoleMsg(theme .. "\n" .. loaded .. "\n\n")
    if loaded2 ~= theme and loaded2 ~= "adjusted__" .. theme then
      userchangedtheme = true
      gfx.quit()
    end
  end
end


function delete_adjustedTheme()
  os.remove(path .. "adjusted__" .. theme)
  if not userchangedtheme then reaper.OpenColorThemeFile( path .. theme ) end
end


function exit()
  -- if current theme colors are not changed, then do not prompt to save
  if TableContentsAreEqual(col[current][cur_version], col[0][1]) then
    delete_adjustedTheme()
  else -- prompt
    local ok
    if userchangedtheme then
      ok = reaper.MB( "Would you like to save the changes you made under a new name?", "Script quits because you changed theme", 4 )
    else
      ok = reaper.MB( "Would you like to save the theme under a new name?", "Save current color theme?", 4 )
    end
    local file
    if ok == 6 then
      -- protect _adjusted theme file
      file = io.open(path .. "adjusted__" .. theme)
      local ok, filename = reaper.JS_Dialog_BrowseForSaveFile( "Save theme as:", path, theme, "Color Theme files (*.ReaperTheme)\0*.ReaperTheme\0\0" )
      if ok == 1 and filename ~= "" then
        -- make sure that extension exists
        if not string.find(filename, "%.[rR][eE][aA][pP][eE][rR][tT][hH][eE][mM][eE]$") then
          filename = filename .. ".ReaperTheme"
        end
        local SectionName = filename:match(".*[\\/]([^\\/]+)%.[rR][eE][aA][pP][eE][rR][tT][hH][eE][mM][eE]")
        if file then file:close() end -- unprotect
        -- in case we want to overwrite a file
        if reaper.file_exists( filename ) then
          os.remove( filename )
        end
        os.rename( path .. "adjusted__" .. theme, filename)
        InheritSettings(SectionName)
        reaper.OpenColorThemeFile( filename )
      else
        if file then file:close() end -- unprotect
        delete_adjustedTheme()
      end
    else
      delete_adjustedTheme()
    end
  end
  return reaper.defer(function() end)
end


-----------------------------------------------------------------------


GUI.exit = exit
GUI.freq = 0
GUI.func = Additional


-- Set defaults
GUI.Val("Compare", 1)
GUI.elms.Groups.optsel = {table.unpack(group_settings)}
MakeColorGroupTable(group_settings)
GetThemeColors()


-- Delete extracted theme, that is no more needed
if zipped then os.remove(zipped) end


GUI.Init()
GUI.Main()

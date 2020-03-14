-- @description amagalma_Adjust theme colors
-- @author amagalma
-- @version 1.27
-- @about
--   # Adjusts the colors of any unzipped ReaperTheme
--
--   - Theme must be unzipped for the colors to be adjusted
--   - Requires Lokasenna GUI v2 and JS_ReaScriptAPI
--   - Offers Gamma, Brightness and Contrast adjustments
--   - Listbox with previous settings
--   - Alt-click an item in the Listbox to remove a setting
--   - A/B Button to toggle between current setting and original theme colors

--[[
  @changelog
    Various optimizations and improvements of the A/B mode
    Bug fixes of some corner cases
--]]

-- @link http://forum.cockos.com/showthread.php?t=232639

local reaper = reaper
local debug = false
local version = "1.27"
local path, theme
local current = 1
local previous = 1
local settings = {}
local AB_mode = false
local Win = string.match(reaper.GetOS(), "Win" ) == "Win"
settings[1] = {g = 1, b = 0, c = 0}
-- tables to store data
local l, fon = {}, {}

-- Table with all the colors that will be adjusted
local t = { "col_cursor", "col_cursor2", "guideline_color", "col_arrangebg", "col_mixerbg", "col_tracklistbg", 
"col_envlane2_divline", "col_envlane1_divline", "col_env12", "col_env11", "col_env13", "col_env14", "col_env15", 
"col_env16", "env_item_mute", "env_item_pan", "env_item_pitch", "env_item_vol", "col_env5", "col_env6", 
"env_track_mute", "col_env4", "col_env3", "env_sends_mute", "col_env8", "col_env10", "col_env7", "col_env9", 
"auto_item_unsel", "col_env2", "col_env1", "col_fadearm2", "col_fadearm", "col_fadearm3", "col_mi_label_float", 
"col_mi_label_float_sel", "group_0", "group_9", "group_10", "group_11", "group_12", "group_13", "group_14", 
"group_15", "group_16", "group_17", "group_18", "group_1", "group_19", "group_20", "group_21", "group_22", "group_23", 
"group_24", "group_25", "group_26", "group_27", "group_28", "group_2", "group_29", "group_30", "group_31", "group_32",
"group_33", "group_34", "group_35", "group_36", "group_37", "group_38", "group_3", "group_39", "group_40", 
"group_41", "group_42", "group_43", "group_44", "group_45", "group_46", "group_47", "group_48", "group_4", "group_49",
"group_50", "group_51", "group_52", "group_53", "group_54", "group_55", "group_56", "group_57", "group_58", "group_5",
"group_59", "group_60", "group_61", "group_62", "group_63", "group_6", "group_7", "group_8", "io_3dhl", "io_3dsh",
"io_text", "midi_ccbut", "midi_trackbg1", "midi_trackbg2", "midi_trackbg_outer1", "midi_trackbg_outer2",
"midi_selpitch1", "midi_selpitch2", "midi_editcurs", "midi_endpt", "midi_ofsn", "midi_ofsnsel", "midi_itemctl",
"midifont_col_dark", "midifont_col_light", "midifont_col_dark_unsel", "midifont_col_light_unsel", "midi_notemute_sel",
"midi_notemute", "midi_notefg", "midi_notebg", "midioct", "midi_rulerbg", "midi_rulerfg", "midi_selbg",
"midi_inline_trackbg1", "midi_inline_trackbg2", "midioct_inline", "midieditorlist_bg", "midieditorlist_bg2",
"midieditorlist_selbg", "midieditorlist_seliabg", "midieditorlist_selbg2", "midieditorlist_selfg",
"midieditorlist_seliafg", "midieditorlist_selfg2", "midieditorlist_fg", "midieditorlist_fg2", "score_bg",
"score_loop", "score_sel", "score_fg", "score_timesel", "midi_pkey1", "midi_pkey3", "midi_pkey2",
"midi_noteon_flash", "midi_leftbg", "col_main_3dhl", "col_main_3dsh", "col_main_resize2", "col_main_textshadow",
"col_main_bg2", "col_main_text2", "marker_lane_bg", "marker_lane_text", "marker", "col_explorer_sel",
"col_explorer_seledge", "col_offlinetext", "col_mi_bg2", "col_mi_bg", "col_tr2_itembgsel", "col_tr1_itembgsel",
"item_grouphl", "col_mi_fade2", "col_mi_fades", "col_mi_label", "col_mi_label_sel", "col_tr2_peaks", "col_tr1_peaks",
"col_peaksedge2", "col_peaksedge", "col_peaksedgesel2", "col_peaksedgesel", "col_peaksfade2", "col_peaksfade1",
"col_tr2_ps2", "col_tr1_ps2", "col_stretchmarker_h0", "col_stretchmarker_h2", "col_stretchmarker_h1",
"col_stretchmarker_b", "col_stretchmarker", "col_stretchmarker_text", "col_stretchmarker_tm", "mcp_fxparm_bypassed",
"mcp_fxparm_normal", "mcp_fxparm_offlined", "mcp_fx_bypassed", "mcp_fx_normal", "mcp_fx_offlined", "mcp_sends_levels",
"mcp_send_midihw", "mcp_sends_muted", "mcp_sends_normal", "playcursor_color", "playrate_edited", "region_lane_bg",
"region_lane_text", "region", "col_routinghl2", "col_routinghl1", "col_seltrack", "docker_bg", "windowtab_bg",
"docker_selface", "docker_shadow", "docker_text", "docker_text_sel", "docker_unselface", "col_tl_bgsel",
"col_tsigmark", "ts_lane_bg", "ts_lane_text", "timesig_sel_bg", "col_tl_bg", "col_tl_bgsel2", "col_tl_fg",
"col_tl_fg2", "toolbararmed_color", "col_toolbar_text_on", "col_toolbar_text", "col_toolbar_frame", "col_tr2_bg",
"col_tr1_bg", "col_tr2_divline", "col_tr1_divline", "col_tcp_textsel", "col_tcp_text", "col_transport_editbk",
"col_trans_bg", "col_trans_fg", "col_vuind4", "col_vuind2", "col_vuind3", "col_vuind1", "col_vubot", "col_vuclip",
"col_vuintcol", "col_vumid", "col_vumidi", "col_vutop", "col_main_editbk", "genlist_bg", "genlist_grid",
"genlist_selbg", "genlist_seliabg", "genlist_selfg", "genlist_seliafg", "genlist_fg", "col_main_text", "wiring_grid2",
"wiring_grid", "wiring_tbg", "wiring_border", "wiring_ticon", "wiring_fader", "wiring_hwoutwire", "wiring_horz_col",
"wiring_parent", "wiring_parentwire_master", "wiring_parentwire_folder", "wiring_parentwire_border", "wiring_media",
"wiring_pin_connected", "wiring_pin_disconnected", "wiring_pin_normal", "wiring_recv", "wiring_recinputwire",
"wiring_recbg", "wiring_recitem", "wiring_sendwire", "wiring_send", "wiring_hwout", "wiring_recinput" }

-- Check if JS_ReaScriptAPI is installed
if not reaper.APIExists("JS_Dialog_BrowseForSaveFile") then
  local answer = reaper.MB( "You have to install JS_ReaScriptAPI for this script to work. Would you like to open the relative web page in your browser?", "JS_ReaScriptAPI not installed", 4 )
  if answer == 6 then
    local url = "https://forum.cockos.com/showthread.php?t=212174"
    if not Win then
      os.execute('open "" "' .. url .. '"')
    else
      os.execute('start "" "' .. url .. '"')
    end
  end
  return
end

-- Load theme --
theme = reaper.GetLastColorThemeFile()
if not reaper.file_exists(theme) then
  reaper.MB( "The currently loaded theme may be zipped or its file does no longer exist.\n\nIf the theme is zipped, please unzip it and try again.\n( Extract the ReaperTheme file from the ReaperThemeZip file and load the extracted theme. )", "Problem...", 0 )
  return
end
if string.find(theme, "adjusted__") then
  theme = string.gsub(theme, "adjusted__", "")
  reaper.OpenColorThemeFile( theme )
end
if theme then
  if Win then
    path, theme = theme:match("(.*\\)(.+)")
  else
    path, theme = theme:match("(.*/)(.+)")
  end
end

-- Check Lokasenna_GUI library availability --
local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
  reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
  return
end
loadfile(lib_path .. "Core.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Listbox.lua")()
if missing_lib then return 0 end

-----------------------------------------------------------------------

-- Functions --

function DEBUG(extra)
  if debug then
    local msg = string.format("\nCurrent = %s, Previous = %s, AB_mode = %s\n_______________\n", tostring(current), tostring(previous), tostring(AB_mode))
    if extra then msg = "\n" .. extra .. msg end
    reaper.ShowConsoleMsg(msg)
    local windowHWND = reaper.JS_Window_Find( "ReaScript console output", true )
    if windowHWND then reaper.JS_Window_SetZOrder( windowHWND, "TOP" ) end
  end
end

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
        l[k] = {[1] = tonumber(v)} -- table to store theme colors
      end
    end
    if reap then
      fon[#fon+1] = line
    end
  end
  io.close(file)
end

function WriteFile(setting)
  local file = io.open(path .. "adjusted__" .. theme, "w+")
  file:write("[color theme]\n")
  for k, v in pairs(l) do
    file:write(k .. "=" .. tostring(v[setting]) .. "\n")
  end
  file:write(table.concat(fon, "\n"))
  io.close(file)
  reaper.OpenColorThemeFile(path .. "adjusted__" .. theme )
end

function AdjustColors()
  local x, y = gfx.clienttoscreen( GUI.elms.Apply.x, GUI.elms.Apply.y )
  -- if settings have not been changed then do nothing and tell to user
  if settings[current] and ( (settings[current].g == GUI.Val("Gamma") and
     settings[current].c == GUI.Val("Contrast") and
     settings[current].b == GUI.Val("Brightness")) )
  then
    reaper.TrackCtl_SetToolTip( "You haven't changed any settings", x-4, y+35, true )
    return
  end
  -- if in AB mode, do net let user apply changes
  if AB_mode then
    AB_mode = false
    GUI.elms.AB.col_fill = "elm_frame"
    GUI.elms.AB:init()
  end
  -- create new table for new settings
  current = #settings + 1
  for k,v in pairs(l) do
    l[k][current] = v[1]
  end
  for i = 1, #t do
    if l[t[i]] then
      local r, g, b = reaper.ColorFromNative( l[t[i]][1] )
      r, g, b = BrightnessContrast(r, g, b, GUI.Val("Brightness"), GUI.Val("Contrast") )
      r, g, b = Gamma(r, g, b, GUI.Val("Gamma"))
      l[t[i]][current] = reaper.ColorToNative( r, g, b )
    end
  end
  -- store settings
  settings[current] = {}
  settings[current].g = GUI.Val("Gamma")
  settings[current].b = GUI.Val("Brightness")
  settings[current].c = GUI.Val("Contrast")
  -- Write adjusted file
  WriteFile(current)
  -- Update listbox
  GUI.elms.Compare.list[#GUI.elms.Compare.list+1] = string.format("|    %d    |    %d    |    %.2f    |", settings[current].b, settings[current].c, settings[current].g)
  GUI.elms.Compare:init()
  GUI.Val("Compare", current)
  if #settings > 6 then
    GUI.elms.Compare.wnd_y = GUI.clamp(1, GUI.elms.Compare.wnd_y + 1, math.max(#GUI.elms.Compare.list - GUI.elms.Compare.wnd_h + 1, 1))
    GUI.elms.Compare:redraw()
  end
  DEBUG("Created " .. current)
end
  
function Load(setting)
  WriteFile(setting)
  current = setting
  -- Set sliders
  GUI.Val("Gamma", (settings[setting].g - GUI.elms.Gamma.min)/GUI.elms.Gamma.inc )
  GUI.Val("Brightness", (settings[setting].b - GUI.elms.Brightness.min)/GUI.elms.Brightness.inc )
  GUI.Val("Contrast", (settings[setting].c - GUI.elms.Contrast.min)/GUI.elms.Contrast.inc )
end

function AB()
  local extra
  local x, y = gfx.clienttoscreen( GUI.elms.AB.x, GUI.elms.AB.y )
  -- if no other settings are available then do nothing and tell to user
  if #settings == 1 then
    extra = "No other settings are available"
    reaper.TrackCtl_SetToolTip( extra, x-90, y+35, true )
    return
  elseif current == 0 then
    extra = "Setting deleted - cannot toggle"
    reaper.TrackCtl_SetToolTip( extra, x-90, y+35, true )
    return
  elseif current == 1 and not AB_mode then
    extra = "Already viewing original theme colors"
    reaper.TrackCtl_SetToolTip( extra, x-169, y+35, true )
    return
  elseif not settings[previous] then
    extra = "Previous setting no longer exists"
    reaper.TrackCtl_SetToolTip( extra, x-100, y+35, true )
    return
  end
  AB_mode = not AB_mode -- toggle
  -- change color button
  GUI.elms.AB.col_fill = AB_mode and "green" or "elm_frame"
  GUI.elms.AB:init()
  reaper.TrackCtl_SetToolTip( "Toggle between current setting and original theme colors", x-199, y+35, true )
  if AB_mode then -- recall original
    previous = current
    current = 1
  else -- recall previous
    current = previous
    previous = 1
  end
  Load(current)
  --GUI.Val("Compare", current)
  DEBUG(extra)
end

-----------------------------------------------------------------------

-- GUI Code --
GUI.name = "Adjust theme colors v" .. version
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 330, 415
GUI.anchor, GUI.corner = "screen", "C"

GUI.New("Gamma", "Slider", {
    z = 11,
    x = 15,
    y = 170,
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
    cap_y = 0
})
GUI.elms.Gamma.align_values = 1

-- Needed to display correctly number like eg 1.02
function GUI.elms.Gamma:formatretval(val)
  if val == 1 then return 1 else return val end
end

GUI.New("Brightness", "Slider", {
    z = 11,
    x = 15,
    y = 40,
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
    cap_y = 0
})
GUI.elms.Brightness.align_values = 1

GUI.New("Contrast", "Slider", {
    z = 11,
    x = 15,
    y = 105,
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
    cap_y = 0
})
GUI.elms.Contrast.align_values = 1

GUI.New("Apply", "Button", {
    z = 11,
    x = 35,
    y = 214,
    w = 180,
    h = 25,
    caption = "Apply settings",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = AdjustColors
})

GUI.New("AB", "Button", {
    z = 11,
    x = 224,
    y = 214,
    w = 70,
    h = 25,
    caption = "A / B",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = AB
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
  local extra
  if not self:overscrollbar() then
    local x, y = gfx.clienttoscreen( GUI.elms.Compare.x, GUI.elms.Compare.y )
    local item = self:getitem(GUI.mouse.y)
    -- Alt-click
    if GUI.mouse.cap & 16 == 16 then
      if item == 1 then -- protect original colors setting
        reaper.TrackCtl_SetToolTip( "Can't delete original theme colors", x+35, y-20, true )
        return
      else
        if AB_mode and item == previous then
          reaper.TrackCtl_SetToolTip( "Can't delete previous setting while in A/B mode", x-3, y-20, true )
          return
        else -- delete item and setting
          table.remove(self.list, item)
          table.remove(settings, item)
          extra = "Removed " .. item
          -- when deleting active setting
          if current == item then
            current = 0
            extra = extra .. " (last active)"
          end
          -- adjust previous setting if deleting an item before it
          if item < previous then
            previous = previous - 1
            GUI.Val("Compare", previous)
          end
        end
        DEBUG(extra)
      end
    else -- Click
      if current == 1 and item == 1 then
        DEBUG()
        reaper.TrackCtl_SetToolTip( "Already viewing original theme colors", x+24, y-20, true )
        return
      else
        -- Load selected item
        self.retval = {[item] = true}
        Load(item)
        extra = "Loaded " .. tostring(item)
        -- if in AB mode, exit it
        if AB_mode then
          GUI.elms.AB.col_fill = "elm_frame"
          GUI.elms.AB:init()
          AB_mode = false
          extra = "Loaded " .. tostring(item .. " and exited A/B mode")
          previous = 1
        end
        DEBUG(extra)
      end
    end
  end
  self:redraw()
end

GUI.New("Compare", "Listbox", {
    z = 11,
    x = 35,
    y = 260,
    w = 260,
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

-----------------------------------------------------------------------

function Additional()
  -- do not let resize
  if gfx.w ~= GUI.w or gfx.h ~= GUI.h then
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, 0, GUI.x, GUI.y)
  end
end

function delete_adjustedTheme()
  os.remove(path .. "adjusted__" .. theme)
  reaper.OpenColorThemeFile( path .. theme )
end

function exit()
  -- if current theme colors are not changed, then do not prompt to save
  if current ~= 0 and settings[current].g == 1 and settings[current].b == 0 and settings[current].c == 0 then
    delete_adjustedTheme()
  else -- prompt
    local ok = reaper.MB( "Would you like to save the theme under a new name?", "Save current color theme?", 4 )
    local file
    if ok == 6 then
      -- protect _adjusted theme file
      file = io.open(path .. "adjusted__" .. theme)
      local ok, filename = reaper.JS_Dialog_BrowseForSaveFile( "Save theme as:", path, theme, "Color Theme files (*.ReaperTheme)\0*.ReaperTheme\0\0" )
      if ok == 1 and filename ~= "" then
        -- make sure that extension exists
        if not string.find(filename, ".ReaperTheme$") then
          filename = filename .. ".ReaperTheme"
        end
        if file then file:close() end -- unprotect
        -- in case we want to overwrite a file
        if reaper.file_exists( filename ) then
          os.remove( filename )
        end
        os.rename( path .. "adjusted__" .. theme, filename)
        reaper.OpenColorThemeFile( filename )
      else
        if file then file:close() end -- unprotect
        delete_adjustedTheme()
      end
    else
      delete_adjustedTheme()
    end
  end
  return
end

GUI.exit = exit
GUI.freq = 0
GUI.Val("Compare", 1)
GUI.func = Additional
GetThemeColors()
GUI.Init()
GUI.Main()

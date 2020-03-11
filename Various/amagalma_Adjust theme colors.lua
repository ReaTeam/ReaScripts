-- @description amagalma_Adjust theme colors
-- @author amagalma
-- @version 1.0
-- @about
--   # Adjusts the colors of any unzipped ReaperTheme
--
--   - Theme must be unzipped for the colors to be adjusted
--   - Requires Lokasenna GUI v2 and JS_ReaScriptAPI
--   - Offers Gamma, Brightness and Contrast adjustments

-- @link http://forum.cockos.com/showthread.php?t=232639

local reaper = reaper
local version = "1.0"
local path, theme
local current = 0
local settings = {}
settings[0] = {g = 1, b = 0, c = 0}
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
    if string.match(reaper.GetOS(), "OSX" ) == "OSX" then
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
  reaper.MB( "The currently loaded theme may be zipped. Please unzip it for this script to work.\n\n( Extract the ReaperTheme file from the ReaperThemeZip file )", "Problem: theme is zipped", 0 )
  return
end
if string.find(theme, "adjusted__") then
  theme = string.gsub(theme, "adjusted__", "")
  reaper.OpenColorThemeFile( theme )
end
if theme then
  path, theme = theme:match("(.*\\)(.+)")
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
if missing_lib then return 0 end

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
        l[k] = {[0] = tonumber(v)} -- table to store theme colors
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
  -- if settings have not been changed then do nothing and tell to user
  if settings[current].g == GUI.Val("Gamma") and
  settings[current].c == GUI.Val("Contrast") and
  settings[current].b == GUI.Val("Brightness") then
    local x, y = gfx.clienttoscreen( gfx.mouse_x, gfx.mouse_y )
    reaper.TrackCtl_SetToolTip( "You haven't changed any settings", x-92, y+20, true )
    return
  end
  -- create new table for new settings
  current = #settings + 1
  for k,v in pairs(l) do
    l[k][current] = v[0]
  end
  for i = 1, #t do
    if l[t[i]] then
      local r, g, b = reaper.ColorFromNative( l[t[i]][0] )
      r, g, b = Gamma(r, g, b, GUI.Val("Gamma"))
      r, g, b = BrightnessContrast(r, g, b, GUI.Val("Brightness"), GUI.Val("Contrast") )
      l[t[i]][current] = reaper.ColorToNative( r, g, b )
    end
  end
  -- store settings for undoing
  settings[current] = {}
  settings[current].g = GUI.Val("Gamma")
  settings[current].b = GUI.Val("Brightness")
  settings[current].c = GUI.Val("Contrast")
  -- Write adjusted file
  WriteFile(current)
end

function SetSliders(setting)
  GUI.Val("Gamma", (settings[setting].g - GUI.elms.Gamma.min)/GUI.elms.Gamma.inc )
  GUI.Val("Brightness", (settings[setting].b - GUI.elms.Brightness.min)/GUI.elms.Brightness.inc )
  GUI.Val("Contrast", (settings[setting].c - GUI.elms.Contrast.min)/GUI.elms.Contrast.inc )
end

function Undo()
  if current == 0 then
    local x, y = gfx.clienttoscreen( gfx.mouse_x, gfx.mouse_y )
    reaper.TrackCtl_SetToolTip( "Theme is in initial state - cannot undo", x-125, y+20, true )
    return
  end
  current = current - 1
  -- Set sliders
  SetSliders(current)
  -- Undo adjustments
  WriteFile(current)
end

function Redo()
  if current == #settings then
    local x, y = gfx.clienttoscreen( gfx.mouse_x, gfx.mouse_y )
    reaper.TrackCtl_SetToolTip( "Cannot redo", x-50, y+20, true )
    return
  end
  current = current + 1
  -- Set sliders
  SetSliders(current)
  -- Undo adjustments
  WriteFile(current)
end

-----------------------------------------------------------------------

-- GUI Code --
GUI.name = "Adjust theme colors v" .. version
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 330, 270
GUI.anchor, GUI.corner = "screen", "C"

GUI.New("Gamma", "Slider", {
    z = 11,
    x = 15.0,
    y = 40.0,
    w = 300,
    caption = "Gamma",
    min = 0.2,
    max = 2,
    defaults = {40},
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

GUI.New("Brightness", "Slider", {
    z = 11,
    x = 15.0,
    y = 105,
    w = 300,
    caption = "Brightness",
    min = -127,
    max = 127,
    defaults = {127},
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

GUI.New("Contrast", "Slider", {
    z = 11,
    x = 15.0,
    y = 170.0,
    w = 300,
    caption = "Contrast",
    min = -127,
    max = 127,
    defaults = {127},
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

GUI.New("Apply settings", "Button", {
    z = 11,
    x = 30,
    y = 220.0,
    w = 120,
    h = 25,
    caption = "Apply settings",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = AdjustColors
})

GUI.New("Undo", "Button", {
    z = 11,
    x = 188,
    y = 220.0,
    w = 50,
    h = 25,
    caption = "Undo",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = Undo
})

GUI.New("Redo", "Button", {
    z = 11,
    x = 248,
    y = 220.0,
    w = 50,
    h = 25,
    caption = "Redo",
    font = 2,
    col_txt = "white",
    col_fill = "elm_frame",
    func = Redo
})


-----------------------------------------------------------------------

function noResize()
  -- do not let resize
  if gfx.w ~= GUI.w or gfx.h ~= GUI.h then
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, 0, GUI.x, GUI.y)
  end
end

function exit()
  -- if current theme colors are not changed, then do not prompt to save
  if settings[current].g == 1 and settings[current].b == 0 and settings[current].c == 0 then
    goto done
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
          if file then file:close() end -- unprotect
          os.rename( path .. "adjusted__" .. theme, filename)
          reaper.OpenColorThemeFile( filename )
          return
        end
      end
    end
  end
  ::done::
  if file then file:close() end -- unprotect
  os.remove(path .. "adjusted__" .. theme)
  reaper.OpenColorThemeFile( path .. theme )
end

GUI.exit = exit
GUI.func = noResize
a = GUI.dock
GetThemeColors()
GUI.Init()
GUI.Main()

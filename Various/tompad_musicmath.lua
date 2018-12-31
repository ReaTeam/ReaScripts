-- @description tompad_MusicMath - bpm/tone to ms/Hz converter
-- @author Thomas Dahl
-- @version 1.1
-- @changelog
--   Added coverter note to Hz
--   Added tooltip "Click to copy to clipboard"
--   Added flashing green when clicking on ms or Hz label
-- @about
--   tompad_MusicMath is a reascript to get ms from bpm in a Reaperproject.
--   --   When script window is opened, it takes the current bpm from Reaper and by choosing note buttons it convert bpm to ms.
--   --   By clicking the resulting ms-text the script is copying the ms to the systems clipboard (for pasting in to delay f.ex)
--   --
--   --   Any comments on coding, requests, bugs etc is welcome! PM me (tompad) on Reaper Forum (https://forum.cockos.com/member.php?u=19103).

-- Script generated by Lokasenna's GUI Builder


local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
  reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Set Lokasenna_GUI v2 library path.lua' in the Lokasenna_GUI folder.", "Whoops!", 0)
  return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Menubox.lua")()


-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

GUI.name = "MusicMath"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 210, 470
GUI.anchor, GUI.corner = "mouse", "C"


GUI.New("tabs", "Tabs", 1, 0, 0, 64, 20, "mS,Hz", 16)
-- Telling the tabs which z layers to display
-- See Classes/Tabs.lua for more detail
GUI.elms.tabs:update_sets(
  --  Tab
  --			Layers
  { [1] = {2},
    [2] = {3},
  }
)

GUI.tooltip_time = 0.1


-- <hide-code desc='Tab ms'>

GUI.New("bpm_label", "Label", {
  z = 2,
  x = 70,
  y = 32,
  caption = "",
  font = 1,
  color = "txt",
  bg = "wnd_bg",
  shadow = false
})


-- <hide-code desc='1/1'>

GUI.New("btn_1_1", "Button", {
  z = 2,
  x = 26.0,
  y = 76.0,
  w = 48,
  h = 48,
  caption = "1/1",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_1dot", "Button", {
  z = 2,
  x = 80.0,
  y = 76.0,
  w = 48,
  h = 48,
  caption = "1/1.",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_1t", "Button", {
  z = 2,
  x = 134.0,
  y = 76.0,
  w = 48,
  h = 48,
  caption = "1/1t",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

-- </hide-code>

-- <hide-code desc='1/2'>

GUI.New("btn_1_2", "Button", {
  z = 2,
  x = 26.0,
  y = 130.0,
  w = 48,
  h = 48,
  caption = "1/2",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_2dot", "Button", {
  z = 2,
  x = 80.0,
  y = 130.0,
  w = 48,
  h = 48,
  caption = "1/2.",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_2t", "Button", {
  z = 2,
  x = 134.0,
  y = 130.0,
  w = 48,
  h = 48,
  caption = "1/2t",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})
-- </hide-code>

-- <hide-code desc='1/4'>

GUI.New("btn_1_4", "Button", {
  z = 2,
  x = 26.0,
  y = 184.0,
  w = 48,
  h = 48,
  caption = "1/4",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_4dot", "Button", {
  z = 2,
  x = 80.0,
  y = 184.0,
  w = 48,
  h = 48,
  caption = "1/4.",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_4t", "Button", {
  z = 2,
  x = 134.0,
  y = 184.0,
  w = 48,
  h = 48,
  caption = "1/4t",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

-- </hide-code>

-- <hide-code desc='1/8'>

GUI.New("btn_1_8", "Button", {
  z = 2,
  x = 26.0,
  y = 238.0,
  w = 48,
  h = 48,
  caption = "1/8",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_8dot", "Button", {
  z = 2,
  x = 80.0,
  y = 238.0,
  w = 48,
  h = 48,
  caption = "1/8.",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_8t", "Button", {
  z = 2,
  x = 134.0,
  y = 238.0,
  w = 48,
  h = 48,
  caption = "1/8t",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

-- </hide-code>

-- <hide-code desc='1/16'>
GUI.New("btn_1_16", "Button", {
  z = 2,
  x = 26.0,
  y = 292.0,
  w = 48,
  h = 48,
  caption = "1/16",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_16dot", "Button", {
  z = 2,
  x = 80.0,
  y = 292.0,
  w = 48,
  h = 48,
  caption = "1/16.",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_16t", "Button", {
  z = 2,
  x = 134.0,
  y = 292.0,
  w = 48,
  h = 48,
  caption = "1/16t",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

-- </hide-code>

-- <hide-code desc='1/32'>

GUI.New("btn_1_32", "Button", {
  z = 2,
  x = 26.0,
  y = 346.0,
  w = 48,
  h = 48,
  caption = "1/32",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_32dot", "Button", {
  z = 2,
  x = 80.0,
  y = 346.0,
  w = 48,
  h = 48,
  caption = "1/32.",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})

GUI.New("btn_1_32t", "Button", {
  z = 2,
  x = 134.0,
  y = 346.0,
  w = 48,
  h = 48,
  caption = "1/32t",
  font = 2,
  col_txt = "txt",
  col_fill = "elm_frame"
})
-- </hide-code>

GUI.New("ms_label", "Label", {
  z = 2,
  x = 105,
  y = 410,
  caption = "0 ms",
  font = 1,
  color = "txt",
  bg = "wnd_bg",
  shadow = false,
  tooltip = "Click to copy to clipboard"
})


function check_Tempo ()
  local tempo = reaper.Master_GetTempo()
  local tempo_str = tempo .." bpm"
  GUI.Val("bpm_label", tempo_str)
  --Centrerar bpm_label och ms_label mittpunkt
  local x = (GUI.w / 2)
  GUI.elms.bpm_label.x = x - ((gfx.measurestr(tempo_str)) / 2)
  GUI.elms.ms_label.x = x - ((gfx.measurestr(GUI.elms.ms_label.caption)) / 2)
  return tempo
end

function GUI.elms.ms_label:onmousedown()
  GUI.Label.onmousedown(self)

  GUI.elms.ms_label.bg = "elm_fill"
  GUI.elms.ms_label:init()
  GUI.elms.ms_label:redraw()

end

function GUI.elms.ms_label:onmouseup()
  GUI.Label.onmouseup(self)
  local str = string.gsub(GUI.elms.ms_label.caption, " ms", "")
  reaper.CF_SetClipboard(str)

  GUI.elms.ms_label.bg = "wnd_bg"
  GUI.elms.ms_label:init()
  GUI.elms.ms_label:redraw()

end

-- <hide-code desc='btn_1_1'>

function GUI.elms.btn_1_1dot:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 1)
end

function GUI.elms.btn_1_1:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 2)
end

function GUI.elms.btn_1_1t:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 3)
end
-- </hide-code>

-- <hide-code desc='1/2'>

function GUI.elms.btn_1_2dot:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 4)
end

function GUI.elms.btn_1_2:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 5)
end

function GUI.elms.btn_1_2t:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 6)
end
-- </hide-code>

-- <hide-code desc='1/4'>

function GUI.elms.btn_1_4dot:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 7)
end

function GUI.elms.btn_1_4:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 8)
end

function GUI.elms.btn_1_4t:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 9)
end
-- </hide-code>

-- <hide-code desc='1/8'>

function GUI.elms.btn_1_8dot:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 10)
end

function GUI.elms.btn_1_8:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 11)
end

function GUI.elms.btn_1_8t:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 12)
end
-- </hide-code>

-- <hide-code desc='1/16'>

function GUI.elms.btn_1_16dot:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 13)
end

function GUI.elms.btn_1_16:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 14)
end

function GUI.elms.btn_1_16t:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 15)
end
-- </hide-code>

-- <hide-code desc='1/32'>

function GUI.elms.btn_1_32dot:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 16)
end

function GUI.elms.btn_1_32:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 17)
end

function GUI.elms.btn_1_32t:onmouseup()
  GUI.Button.onmouseup(self)
  local tempo = check_Tempo()
  check_ms(tempo, 18)
end
-- </hide-code>

function check_ms (bpm, notvarde)
  local mSeconds = 60000 / bpm

  if notvarde == 1 then
    value_ms = mSeconds * 6 --1/1.
  elseif notvarde == 2 then
    value_ms = mSeconds * 4 -- 1/1
  elseif notvarde == 3 then
    value_ms = mSeconds * 2.666 -- 1/1T
  elseif notvarde == 4 then
    value_ms = mSeconds * 3 -- 1/2.
  elseif notvarde == 5 then
    value_ms = mSeconds * 2 -- 1/2
  elseif notvarde == 6 then
    value_ms = mSeconds * 1.333 -- 1/2T
  elseif notvarde == 7 then
    value_ms = mSeconds * 1.5 -- 1/4.
  elseif notvarde == 8 then
    value_ms = mSeconds * 1 -- 1/4
  elseif notvarde == 9 then
    value_ms = mSeconds * 0.666 -- 1/4T
  elseif notvarde == 10 then
    value_ms = mSeconds * 0.75 -- 1/8.
  elseif notvarde == 11 then
    value_ms = mSeconds * 0.5 -- 1/8
  elseif notvarde == 12 then
    value_ms = mSeconds * 0.333 -- 1/8T
  elseif notvarde == 13 then
    value_ms = mSeconds * 0.375 --1/16.
  elseif notvarde == 14 then
    value_ms = mSeconds * 0.25 --1/16
  elseif notvarde == 15 then
    value_ms = mSeconds * 0.1665 --1/16T
  elseif notvarde == 16 then
    value_ms = mSeconds * 0.1875 --1/32.
  elseif notvarde == 17 then
    value_ms = mSeconds * 0.125 -- 1/32
  elseif notvarde == 18 then
    value_ms = mSeconds * 0.08325 -- 1/32T
  end

  local ms_str = round(value_ms, 3) .." ms"
  GUI.Val("ms_label", ms_str)
  --Centrerar ms_label mittpunkt
  local x = (GUI.w / 2)
  GUI.elms.ms_label.x = x - ((gfx.measurestr(ms_str)) / 2)

end

function round(number, decimals)
  local power = 10^decimals
  return math.floor(number * power) / power
end
-- </hide-code>

-- <hide-code desc='Tab Hz'>


GUI.New("tunings", "Menubox", {
  z = 3,
  x = 108,
  y = 42,
  w = 50,
  h = 20,
  caption = "Tuning:",
  opts = "432, 434, 436, 438, 440, 442, 444, 446",
  retval = 3.0,
  font_a = 2,
  font_b = 4,
  col_txt = "txt",
  col_cap = "txt",
  bg = "wnd_bg",
  pad = 2,
  noarrow = false,
  align = 2
})

GUI.New("note_sldr", "Slider", {
  z = 3,
  x = 58,
  y = 106,
  w = 250,
  caption = "Note",
  min = 0,
  max = 11,
  defaults = 11,
  inc = 1,
  dir = "v",
  font_a = 2,
  font_b = 4,
  col_txt = "txt",
  col_fill = "elm_bg",
  bg = "wnd_bg",
  show_handles = true,
  show_values = false,
  cap_x = 0,
  cap_y = 0

})

GUI.New("octave_sldr", "Slider", {
  z = 3,
  x = 141,
  y = 106,
  w = 250,
  caption = "Octave",
  min = 0,
  max = 8,
  defaults = 4,
  inc = 1,
  dir = "v",
  font_a = 2,
  font_b = 4,
  col_txt = "txt",
  col_fill = "elm_bg",
  bg = "wnd_bg",
  show_handles = true,
  show_values = false,
  cap_x = 0,
  cap_y = 0
})


GUI.New("note_octave_lbl", "Label", {
  z = 3,
  x = 95,
  y = 375,
  caption = "C4",
  font = 2,
  color = "txt",
  bg = "wnd_bg",
  shadow = false
})


GUI.New("hz_label", "Label", {
  z = 3,
  x = 105,
  y = 410,
  caption = "0 Hz",
  font = 1,
  color = "txt",
  bg = "wnd_bg",
  shadow = false,
  tooltip = "Click to copy to clipboard"
})


-- <hide-code desc='Tunings Menubox'>

function GUI.elms.tunings:onwheel()
  GUI.Menubox.onwheel(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

function GUI.elms.tunings:onmouseup()
  GUI.Menubox.onmouseup(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end
-- </hide-code>


-- <hide-code desc='note-slider'>

function GUI.elms.note_sldr:onmousedown()
  GUI.Slider.onmousedown(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

function GUI.elms.note_sldr:ondrag()
  GUI.Slider.ondrag(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

function GUI.elms.note_sldr:onwheel()
  GUI.Slider.onwheel(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

function GUI.elms.note_sldr:ondoubleclick()
  GUI.Slider.ondoubleclick(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end
-- </hide-code>

-- <hide-code desc='octave-slider'>

function GUI.elms.octave_sldr:onmousedown()
  GUI.Slider.onmousedown(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

function GUI.elms.octave_sldr:ondrag()
  GUI.Slider.ondrag(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

function GUI.elms.octave_sldr:onwheel()
  GUI.Slider.onwheel(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

function GUI.elms.octave_sldr:ondoubleclick()
  GUI.Slider.ondoubleclick(self)
  check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
end

-- </hide-code>

function check_tunings (tunings_val)
  if tunings_val == 1 then
    return 432
  elseif tunings_val == 2 then
    return 434
  elseif tunings_val == 3 then
    return 436
  elseif tunings_val == 4 then
    return 438
  elseif tunings_val == 5 then
    return 440
  elseif tunings_val == 6 then
    return 442
  elseif tunings_val == 7 then
    return 444
  elseif tunings_val == 8 then
    return 446
  end

end

function check_notename (note, octave, tunings)
  local notsteg
  local notename
  if note == 0 then
    notename = "C"..octave
    notsteg = -9
  elseif note == 1 then
    notename = "C#/Db"..octave
    notsteg = -8
  elseif note == 2 then
    notename = "D"..octave
    notsteg = -7
  elseif note == 3 then
    notename = "D#/Eb"..octave
    notsteg = -6
  elseif note == 4 then
    notename = "E"..octave
    notsteg = -5
  elseif note == 5 then
    notename = "F"..octave
    notsteg = -4
  elseif note == 6 then
    notename = "F#/Gb"..octave
    notsteg = -3
  elseif note == 7 then
    notename = "G"..octave
    notsteg = -2
  elseif note == 8 then
    notename = "G#/Ab"..octave
    notsteg = -1
  elseif note == 9 then
    notename = "A"..octave
    notsteg = 0
  elseif note == 10 then
    notename = "A#/Bb"..octave
    notsteg = 1
  elseif note == 11 then
    notename = "B"..octave
    notsteg = 2
  end

  local tuningHz

  if octave == 0 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz / 16
  elseif octave == 1 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz / 8
  elseif octave == 2 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz / 4
  elseif octave == 3 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz / 2
  elseif octave == 4 then
    tuningHz = check_tunings(tunings)
  elseif octave == 5 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz * 2
  elseif octave == 6 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz * 4
  elseif octave == 7 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz * 8
  elseif octave == 8 then
    tuningHz = check_tunings(tunings)
    tuningHz = tuningHz * 16
  end

  local hz = tuningHz * 1.05946309436^notsteg

  hz = round(hz, 3)
  --reaper.ShowConsoleMsg(hz)
  local hz_str = hz .." Hz"
  GUI.Val("hz_label", hz_str)
  local x = (GUI.w / 2)
  --Centrerar hz_label mittpunkt
  GUI.elms.hz_label.x = x - ((gfx.measurestr(hz_str)) / 2)

  GUI.Val("note_octave_lbl", notename)
  local x = (GUI.w / 2)
  GUI.elms.note_octave_lbl.x = x - ((gfx.measurestr(notename)) / 2)

end


function GUI.elms.hz_label:onmousedown()
  GUI.Label.onmousedown(self)

  GUI.elms.hz_label.bg = "elm_fill"
  GUI.elms.hz_label:init()
  GUI.elms.hz_label:redraw()

end

function GUI.elms.hz_label:onmouseup()
  GUI.Label.onmouseup(self)
  local str = string.gsub(GUI.elms.hz_label.caption, " Hz", "")
  reaper.CF_SetClipboard(str)

  GUI.elms.hz_label.bg = "wnd_bg"
  GUI.elms.hz_label:init()
  GUI.elms.hz_label:redraw()
end
-- </hide-code>

------------------------------------
-------- Main functions ------------
------------------------------------
-- This will be run on every update loop of the GUI script; anything you would put
-- inside a reaper.defer() loop should go here. (The function name doesn't matter)
local function Main()

  -- Prevent the user from resizing the window
  if GUI.resized then

    -- If the window's size has been changed, reopen it
    -- at the current position with the size we specified
    local __, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
    gfx.quit()
    gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
    GUI.redraw_z[0] = true
  end

  check_Tempo()

end


-- Open the script window and initialize a few things
GUI.Init()
--GUI.elms.tunings.x = x - ((gfx.measurestr(GUI.elms.tunings.caption) - 90) / 2)
GUI.Val("tunings", 5) -- select 440 HZ
check_notename(GUI.Val("note_sldr"), GUI.Val("octave_sldr"), GUI.Val("tunings"))
-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main
-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.freq = 0
-- Start the main loop
GUI.Main()
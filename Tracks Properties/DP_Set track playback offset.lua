-- @description Set track playback offset
-- @author Daniel Philistin
-- @version 1
-- @screenshot https://imgur.com/a/ZOpZQkU
-- @about
--   # Set Track Playback Offset
--
--   Requires Lokasenna_GUI v2
--
--   This script allows you to quickly apply a playback time offset to a selected track without having to keep opening the track routing options.
--
--   1. Select a track
--   2. Run the script
--   3. Drag the bar to apply a delay. You can also use the buttons to add a fixed delay +-1 ms or 10ms. You can also type the delay you want in the textbox and then press the "Set delay" button to apply whatever is in the textbox.


local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Label.lua")()


local trackcount = reaper.CountSelectedTracks()
local track = reaper.GetSelectedTrack(0, 0)

if not track or track== "" then
	reaper.MB("No track selected. Select a track first", "Whoops!", 0)
	return
end

local delay= reaper.GetMediaTrackInfo_Value(track, "D_PLAY_OFFSET")*1000



GUI.name = "Set playback offset"
GUI.x, GUI.y, GUI.w, GUI.h = 200, 200, 300, 160


	
	GUI.New("delay_slider", "Slider",  10, 20, 40, 250,     "Playback Offset (ms):", -300,   300,  300,    1)
	GUI.New("delay_txtbox", "Textbox", 50, 100, 80, 100, 40, "")
	GUI.New("set_button", "Button",  1, 220,  90, 64, 24, "Set delay", set_track_delay)
	GUI.New("buttonp1", "Button",  1, 60,  80, 34, 24, "+1", track_delay_1)
	GUI.New("buttonm1", "Button",  1, 20,  80, 34, 24, "-1", track_delay_m1)
	GUI.New("buttonp10", "Button",  1, 60,  110, 34, 24, "+10", track_delay_10)
	GUI.New("buttonm10", "Button",  1, 20,  110, 34, 24, "-10", track_delay_m10)

function slider_set_playback_delay()
	reaper.Undo_BeginBlock()
	track = reaper.GetSelectedTrack(0, 0)
	local val = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
	if val&1 ~= 0 then
	   reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", val&(~1))
	 end
  reaper.SetMediaTrackInfo_Value(track, "D_PLAY_OFFSET", GUI.Val("delay_slider")/1000)
  delay= GUI.Val("delay_slider")/1000

end


function get_newtrack()
track = reaper.GetSelectedTrack(0, 0)
if not track or track== "" then
	 return
end

delay= reaper.GetMediaTrackInfo_Value(track, "D_PLAY_OFFSET")*1000
GUI.Val("delay_slider",delay+300)
end

function GUI.elms.delay_slider:ondrag()

 GUI.Slider.ondrag(self)
	slider_set_playback_delay()

end

function GUI.elms.delay_slider:onmousedown()

 GUI.Slider.onmousedown(self)
	slider_set_playback_delay()

end

function GUI.elms.delay_slider:ondoubleclick()
	delay=0
	GUI.Val("delay_slider",delay+300)
	slider_set_playback_delay()

end



function GUI.elms.set_button:onmousedown()
	track = reaper.GetSelectedTrack(0, 0)
	local val = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
	if val&1 ~= 0 then
	   reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", val&(~1))
	 end
	
	local txt=GUI.Val("delay_txtbox")
	delay=tonumber(txt)
	GUI.Val("delay_slider",delay+300)
	reaper.SetMediaTrackInfo_Value(track, "D_PLAY_OFFSET", GUI.Val("delay_slider")/1000)

end

function GUI.elms.buttonp1:onmousedown()
	track = reaper.GetSelectedTrack(0, 0)
	local val = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
	if val&1 ~= 0 then
	   reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", val&(~1))
	 end
	

	delay=delay+1
	GUI.Val("delay_slider",delay+300)
	reaper.SetMediaTrackInfo_Value(track, "D_PLAY_OFFSET", delay/1000)

end

function GUI.elms.buttonm1:onmousedown()
	track = reaper.GetSelectedTrack(0, 0)
	local val = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
	if val&1 ~= 0 then
	   reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", val&(~1))
	 end
	

	delay=delay-1
	GUI.Val("delay_slider",delay+300)
	reaper.SetMediaTrackInfo_Value(track, "D_PLAY_OFFSET", delay/1000)

end

function GUI.elms.buttonp10:onmousedown()
	track = reaper.GetSelectedTrack(0, 0)
	local val = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
	if val&1 ~= 0 then
	   reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", val&(~1))
	 end

	delay=delay+10
	GUI.Val("delay_slider",delay+300)
	reaper.SetMediaTrackInfo_Value(track, "D_PLAY_OFFSET", delay/1000)

end

function GUI.elms.buttonm10:onmousedown()
	track = reaper.GetSelectedTrack(0, 0)
	local val = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
	if val&1 ~= 0 then
	   reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", val&(~1))
	 end
	
	delay=delay-10
	GUI.Val("delay_slider",delay+300)
	reaper.SetMediaTrackInfo_Value(track, "D_PLAY_OFFSET", delay/1000)

end

GUI.onmousemove=get_newtrack
GUI.Init()
GUI.Main()

::exit::


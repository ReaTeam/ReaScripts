-- NoIndex: true

--[[
	Lokasenna_GUI

- Using the Main loop to monitor and interact with things in Reaper
	- Using z layers and related functions to move elements around
	- Changing elements' methods for your own purposes

]]--

-- The Core library must be loaded prior to anything else

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Frame.lua")()

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end




------------------------------------
-------- Data + functions ----------
------------------------------------


-- Pre-declaring this so every function has access to it
local tr


local function update_pan()
	
	reaper.SetMediaTrackInfo_Value( tr, "D_PAN", GUI.Val("sldr_pan")/100 )
	
end




------------------------------------
-------- Window settings -----------
------------------------------------


GUI.name = "Example - Main, Z, and Methods"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 300, 128
GUI.anchor, GUI.corner = "mouse", "C"




------------------------------------
-------- GUI Elements --------------
------------------------------------


--[[	

	Frame		z, 	x, 	y, 	w, 	h[, shadow, fill, color, round]
	Label		z, 	x, 	y,		caption[, shadow, font, color, bg]
	Slider		z, 	x, 	y, 	w, 	caption, min, max, defaults[, inc, dir]
	
]]--

GUI.New("lbl_track", "Label",	1,	96, 8, "No track selected!", true, 2, "red")
GUI.New("frm_track", "Frame",	2,	0, 0, 300, 128, false, true, "faded", 0)
GUI.New("sldr_pan", "Slider",	3,	88, 64, 128, "First selected track's Pan:", -100, 100, 100, nil, "h")


-- Layer 5 will never be shown or updated
-- (See the Main function below)
GUI.elms_hide[5] = true




------------------------------------
-------- Method overrides ----------
------------------------------------


-- Class methods can be overwritten, either at the class level or
-- for individual elements.

-- You can also easily append your own code to the stock methods:
function GUI.elms.sldr_pan:onmousedown()
	
	-- Run the slider's normal method
	GUI.Slider.onmousedown(self)

	-- Note that we have to call the method as a function here; we
	-- can't use the : syntax because sldr_pan's 'self' needs to be
	-- passed on as a value. If we used a :, it would pass GUI.Slider

	update_pan()
	
end
function GUI.elms.sldr_pan:ondrag()
	GUI.Slider.ondrag(self)
	update_pan()
end
function GUI.elms.sldr_pan:onwheel()
	GUI.Slider.onwheel(self)
	update_pan()
end
function GUI.elms.sldr_pan:ondoubleclick()
	GUI.Slider.ondoubleclick(self)
	update_pan()
end




------------------------------------
-------- Main loop -----------------
------------------------------------


-- This will be run on every update loop of the GUI script; anything you would put
-- inside a reaper.defer() loop should go here. (The function name doesn't matter)
local function Main()
	
	-- Check the track state and toggle our warning label as needed
	tr = reaper.GetSelectedTrack( 0, 0 )
	
	if tr then
		
		-- Save a bit of CPU by only doing this if we need to
		if GUI.elms.lbl_track.z == 1 then
			
			-- These both accomplish the same thing...
			
			-- lbl_track is moved to a different layer, which we've permanently
			-- hidden above. Use this if you have several elements on a single 
			-- layer and only want to hide one of them. e.g. adjusting which
			-- options are available depending on other things the user does.
			GUI.elms.lbl_track.z = 5
			
			-- frm_track's entire layer is hidden. This is what the Tabs element
			-- uses.
			GUI.elms_hide[GUI.elms.frm_track.z] = true
			
			
			-- Layers can also be frozen; they'll be drawn, but won't receive
			-- any user input. Use this for i.e. having a slider display an
			-- RMS value, since the user can't do anything with it.
			
			-- Completely unnecessary here, because frm_track is on top and will
			-- "steal" any user input.
			
			GUI.elms_freeze[GUI.elms.sldr_pan.z] = false
			
			
			-- Force a redraw of every layer
			GUI.redraw_z[0] = true
			
		end
		
		-- See if the track's Pan value has been changed and update the slider
		local pan = reaper.GetMediaTrackInfo_Value( tr, "D_PAN" )
		if math.abs( pan - (GUI.Val("sldr_pan") / 100) ) > 0.00 then
			
			-- Converting the returned value (-1 to 1) to Slider steps (0 to 200)
			pan = (math.floor(100*pan) - GUI.elms.sldr_pan.min )

			GUI.Val("sldr_pan", pan )
			
		end	
	
	-- If we don't have a track, hide the track elements
    -- and pop up a warning
	else
	
		if GUI.elms.lbl_track.z == 5 then
			
			GUI.elms.lbl_track.z = 1
			GUI.elms_hide[GUI.elms.frm_track.z] = false
			GUI.elms_freeze[GUI.elms.sldr_pan.z] = true
		
			GUI.redraw_z[0] = true
			
		end
	
	end
	
	
end


GUI.Init()

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.freq = 0

GUI.Main()
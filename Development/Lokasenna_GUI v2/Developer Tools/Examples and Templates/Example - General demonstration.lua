-- NoIndex: true

--[[
    Lokasenna_GUI example

    - General demonstration
	- Tabs and layer sets
    - Subwindows
	- Accessing elements' parameters

]]--

-- The Core library must be loaded prior to anything else

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Knob.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Slider.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Menubox.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Options.lua")()
GUI.req("Classes/Class - Window.lua")()

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end




------------------------------------
-------- Functions -----------------
------------------------------------


local function fade_lbl()

   -- Fade out the label
    if GUI.elms.my_lbl.z == 3 then
        GUI.elms.my_lbl:fade(1, 3, 6)

    -- Bring it back
    else
        GUI.elms.my_lbl:fade(1, 3, 6, -3)
    end

end


local function btn_click()

    -- Open the Window element
	GUI.elms.wnd_test:open()

end


local function wnd_OK()

    -- Close the Window element
    GUI.elms.wnd_test:close()

end


-- Returns a list of every element on the specified z-layer and
-- a second list of each element's values
local function get_values_for_tab(tab_num)

	-- The '+ 2' here is just to translate from a tab number to its'
	-- associated z layer. More complicated scripts would have to
	-- actually access GUI.elms.tabs.z_sets[tab_num] and iterate over
	-- the table's contents (see the call to GUI.elms.tabs:update_sets
	-- below)
    local strs_v, strs_val = {}, {}
	for k, v in pairs(GUI.elms_list[tab_num + 2]) do

        strs_v[#strs_v + 1] = v
		local val = GUI.Val(v)
		if type(val) == "table" then
			local strs = {}
			for k, v in pairs(val) do
                local str = tostring(v)

                -- For conciseness, reduce boolean values to T/F
				if str == "true" then
                    str = "T"
                elseif str == "false" then
                    str = "F"
                end
                strs[#strs + 1] = str
			end
			val = table.concat(strs, ", ")
		end

        -- Limit the length of the returned string so it doesn't
        -- spill out past the edge of the window
		strs_val[#strs_val + 1] = string.len(tostring(val)) <= 35
                                and tostring(val)
                                or  string.sub(val, 1, 32) .. "..."

	end

    return strs_v, strs_val

end




------------------------------------
-------- Window settings -----------
------------------------------------


GUI.name = "New Window"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 432, 500
GUI.anchor, GUI.corner = "mouse", "C"


--[[

	Button		z, 	x, 	y, 	w, 	h, caption, func[, ...]
	Checklist	z, 	x, 	y, 	w, 	h, caption, opts[, dir, pad]
	Frame		z, 	x, 	y, 	w, 	h[, shadow, fill, color, round]
	Knob		z, 	x, 	y, 	w, 	caption, min, max, default[, inc, vals]
	Label		z, 	x, 	y,		caption[, shadow, font, color, bg]
	Menubox		z, 	x, 	y, 	w, 	h, caption, opts
	Radio		z, 	x, 	y, 	w, 	h, caption, opts[, dir, pad]
	Slider		z, 	x, 	y, 	w, 	caption, min, max, defaults[, inc, dir]
	Tabs		z, 	x, 	y, 		tab_w, tab_h, opts[, pad]
	Textbox		z, 	x, 	y, 	w, 	h[, caption, pad]
    Window      z,  x,  y,  w,  h,  caption, z_set[, center]

]]--


-- Elements can be created in any order you want. I find it easiest to organize them
-- by tab, or by what part of the script they're involved in.




------------------------------------
-------- General elements ----------
------------------------------------


GUI.New("tabs", 	"Tabs", 		1, 0, 0, 64, 20, "Stuff,Sliders,Options", 16)
GUI.New("tab_bg",	"Frame",		2, 0, 0, 448, 20, false, true, "elm_bg", 0)
GUI.New("my_btn", 	"Button", 		1, 168, 28, 96, 20, "Go!", btn_click)
GUI.New("btn_frm",	"Frame",		1, 0, 56, GUI.w, 4, true, true)

-- Telling the tabs which z layers to display
-- See Classes/Tabs.lua for more detail
GUI.elms.tabs:update_sets(
	--  Tab
	--			Layers
	{	[1] =	{3},
		[2] =	{4},
		[3] =	{5},
	}
)

-- Notice that layers 1 and 2 aren't assigned to a tab; this leaves them visible
-- all the time.




------------------------------------
-------- Tab 1 Elements ------------
------------------------------------


GUI.New("my_lbl", 	"Label", 		3, 256, 96, "Label!", true, 1)
GUI.New("my_knob", 	"Knob", 		3, 64, 112, 48, "Volume", 0, 11, 44, 0.25)
GUI.New("my_mnu", 	"Menubox", 		3, 256, 176, 64, 20, "Options:", "1,2,3,4,5,6.12435213613")
GUI.New("my_btn2",  "Button",       3, 256, 256, 64, 20, "Click me!", fade_lbl)
GUI.New("my_txt", 	"Textbox", 		3, 96, 224, 96, 20, "Text:", 4)
GUI.New("my_frm", 	"Frame", 		3, 16, 288, 192, 128, true, false, "elm_frame", 4)


-- We have too many values to be legible if we draw them all; we'll disable them, and
-- have the knob's caption update itself to show the value instead.
GUI.elms.my_knob.vals = false
function GUI.elms.my_knob:redraw()

    GUI.Knob.redraw(self)

    self.caption = self.retval .. "dB"

end

-- Make sure it shows the value right away
GUI.elms.my_knob:redraw()


GUI.Val("my_frm",   "this is a really long string of text with no carriage returns so hopefully "..
                    "it will be wrapped correctly to fit inside this frame")
GUI.elms.my_frm.bg = "elm_bg"




------------------------------------
-------- Tab 2 Elements ------------
------------------------------------


GUI.New("my_rng", 	"Slider", 		4, 32, 128, 256, "Sliders", 0, 30, {5, 10, 15, 20, 25})
GUI.New("my_pan", 	"Slider", 		4, 32, 192, 256, "Pan", -100, 100, 100)
GUI.New("my_sldr", 	"Slider",		4, 128, 256, 128, "Slider", 0, 10, 20, 0.25, "v")
GUI.New("my_rng2", 	"Slider",		4, 352, 96, 256, "Vertical?", 0, 30, {5, 10, 15, 20, 25}, nil, "v")

-- Using a function to change the value label depending on the value
GUI.elms.my_pan.output = function(val)

	val = tonumber(val)
	return (val == 0	and "0"
						or	(math.abs(val)..
							(val < 0 and "L" or "R")
							)
			)

end




------------------------------------
-------- Tab 3 Elements ------------
------------------------------------


GUI.New("my_chk", 	"Checklist", 	5, 32, 96, 160, 160, "Checklist:", "Alice,Bob,Charlie,Denise,Edward,Francine", "v", 4)
GUI.New("my_opt", 	"Radio", 		5, 200, 96, 160, 160, "Options:", "Apples,Bananas,_,Donuts,Eggplant", "v", 4)
GUI.New("my_chk2",	"Checklist",	5, 32, 280, 384, 64, "Whoa, another Checklist", "A,B,C,_,D,E,F,_,G,H,I", "h", 4)
GUI.New("my_opt2",	"Radio",		5, 32, 364, 384, 64, "Horizontal options", "A,A#,B,C,C#,D,D#,E,F,F#,G,G#", "h", 4)

GUI.elms.my_opt.swap = true
GUI.elms.my_chk2.swap = true




------------------------------------
-------- Subwindow and -------------
-------- its elements  -------------
------------------------------------


GUI.New("wnd_test", "Window", 10, 0, 0, 312, 244, "Dialog Box", {9, 10})
GUI.New("lbl_elms", "Label", 9, 16, 16, "", false, 4)
GUI.New("lbl_vals", "Label", 9, 96, 16, "", false, 4, nil, elm_bg)
GUI.New("btn_close", "Button", 9, 0, 184, 48, 24, "OK", wnd_OK)

-- We want these elements out of the way until the window is opened
GUI.elms_hide[9] = true
GUI.elms_hide[10] = true


-- :onopen is a hook provided by the Window class. This function will be run
-- every time the window opens.
function GUI.elms.wnd_test:onopen()

    -- :adjustelm places the element's specified x,y coordinates relative to
    -- the Window. i.e. creating an element at 0,0 and adjusting it will put
    -- the element in the Window's top-left corner.
    self:adjustelm(GUI.elms.btn_close)

    -- Buttons look nice when they're centered.
    GUI.elms.btn_close.x, _ = GUI.center(GUI.elms.btn_close, self)

    self:adjustelm(GUI.elms.lbl_elms)
    self:adjustelm(GUI.elms.lbl_vals)

    -- Set the Window's title
	local tab_num = GUI.Val("tabs")
    self.caption = "Element values for Tab " .. tab_num

    -- This Window provides a readout of the values for every element
    -- on the current tab.
    local strs_v, strs_val = get_values_for_tab(tab_num)

    GUI.Val("lbl_elms", table.concat(strs_v, "\n"))
    GUI.Val("lbl_vals", table.concat(strs_val, "\n"))

end




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
		local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
		gfx.quit()
		gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
		GUI.redraw_z[0] = true
	end

end


-- Open the script window and initialize a few things
GUI.Init()

-- Tell the GUI library to run Main on each update loop
-- Individual elements are updated first, then GUI.func is run, then the GUI is redrawn
GUI.func = Main

-- How often (in seconds) to run GUI.func. 0 = every loop.
GUI.freq = 0


-- Start the main loop
GUI.Main()

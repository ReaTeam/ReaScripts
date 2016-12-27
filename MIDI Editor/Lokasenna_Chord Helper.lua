--[[
Description: Chord Helper
Version: 5.0
Author: Lokasenna
Changelog:
  Added "all notes off" button
  Chord tooltips now display extended intervals as '^2' rather than '13',
    just to make things more readable
  Fixed a few minor bugs, fiddled with the GUI a bit
Links:
  Forum Thread http://forum.cockos.com/showthread.php?t=185358
  Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
  # Chord Helper

  Provides a selection of chords than can be built from a given scale.

  - Select a .reascale at the top-left.
  - Select a key scale at the top-center.
  - A list of "legal" chords for the current scale is generated.
  - Chords can be played directly, or inserted into the MIDI editor using
    the editor's note settings.
  - Other options include different chord sets, playing chords as arpeggios
    (can't insert notes as arpeggios yet), and playing the current scale.
   
  - IMPORTANT: Due to limitations with Reaper's scripting API, the following
    track settings are required in order to preview notes:
    1. Record-armed.
    2. Monitoring.
    3. Receiving input from the Virtual MIDI Keyboard (any channel).
--]]

-- Licensed under the GNU GPL v3
	

---- Libraries added with Lokasenna's Script Compiler ----

--[=[
	Lokasenna_GUI Library
	by Lokasenna

	Provides functions and classes for adding a GUI to a LUA script with minimal effort
	
	To use:

	1. 	Copy/paste the code below into the beginning of your script.

	2. 	To create the window:
	
		GUI.name = "My window's title"
		GUI.x, GUI.y = __, __
		GUI.w, GUI.h = __, __
		GUI.anchor, GUI.corner = __, __
		

		x,y		offset coordinates from the anchor position
		w,h		window dimensions
		anchor	"screen" or "mouse"
		corner	"TL"
				"T"
				"TR"
				"R"
				"BR"
				"B"
				"BL"
				"L"
				"C"
		
		If no anchor and corner are specified, it will default to the top-left corner of the screen.
	
	
	3.	To add GUI elements, declare a table called GUI.elms and populate it like so:
	
		GUI.elms = {

			item1 = type:New(parameters),
			item2 = type:New(parameters),
			item3 = type:New(parameters),
			...etc...

		}

		(Don't forget those commas at the end)
		
		See the :New method for each element below for a list of parameters
	
	
	4. Additional documentation:
		
		Lokasenna_GUI script example.lua		A working example of the various GUI elements
		Lokasenna_GUI example functions.lua		Common things you might want the GUI to do for you
]=]--

----------------------------------------------------------------
------------------Copy everything from here---------------------
----------------------------------------------------------------

local function GUI_table ()

local GUI = {}

GUI.version = "beta 4"


	---- Keyboard constants ----
	
GUI.chars = {
	
	ESCAPE		= 27,
	SPACE		= 32,
	BACKSPACE	= 8,
	HOME		= 1752132965,
	END			= 6647396,
	INSERT		= 6909555,
	DELETE		= 6579564,
	RETURN		= 13,
	UP			= 30064,
	DOWN		= 1685026670,
	LEFT		= 1818584692,
	RIGHT		= 1919379572,
	
	F1			= 26161,
	F2			= 26162,
	F3			= 26163,
	F4			= 26164,
	F5			= 26165,
	F6			= 26166,
	F7			= 26167,
	F8			= 26168,
	F9			= 26169,
	F10			= 6697264,
	F11			= 6697265,
	F12			= 6697266

}


--[[	Font and color presets
	
	Can be set using the accompanying functions GUI.font
	and GUI.color. i.e.
	
	GUI.font(2)				applies the Header preset
	GUI.color("elm_fill")	applies the Element Fill color preset
	
	Colors are converted from 0-255 to 0-1 when GUI.Init() runs,
	so if you need to access the values directly at any point be
	aware of which format you're getting in return.
		
]]--
GUI.fonts = {
	
	-- Font, size, bold/italics/underline
	-- 				^ One string: "b", "iu", etc.
	{"Calibri", 36, "b"},	-- 1. Title
	{"Calibri", 28},	-- 2. Header
	{"Calibri", 22},	-- 3. Label
	{"Calibri", 18}	-- 4. Value
	
}


GUI.colors = {
	
	-- Element colors
	wnd_bg = {64, 64, 64, 255},			-- Window BG
	elm_bg = {48, 48, 48, 255},			-- Element BG
	elm_frame = {96, 96, 96, 255},		-- Element Frame
	elm_fill = {64, 192, 64, 255},		-- Element Fill
	elm_outline = {32, 32, 32, 255},
	txt = {192, 192, 192, 255},			-- Text
	
	shadow = {0, 0, 0, 102},			-- Shadow
	
	
	-- Standard 16 colors
	black = {0, 0, 0, 255},
	white = {255, 255, 255, 255},
	red = {255, 0, 0, 255},
	lime = {0, 255, 0, 255},
	blue =  {0, 0, 255, 255},
	yellow = {255, 255, 0, 255},
	cyan = {0, 255, 255, 255},
	magenta = {255, 0, 255, 255},
	silver = {192, 192, 192, 255},
	gray = {128, 128, 128, 255},
	maroon = {128, 0, 0, 255},
	olive = {128, 128, 0, 255},
	green = {0, 128, 0, 255},
	purple = {128, 0, 128, 255},
	teal = {0, 128, 128, 255},
	navy = {0, 0, 128, 255},
	
	none = {0, 0, 0, 0},
	

}


GUI.font = function (fnt)
	local font, size, str = table.unpack(GUI.fonts[fnt])
	
	-- ASCII values:
	-- Bold		 98
	-- Italics	 105
	-- Underline 117
	--[[ old way
	local flags = 0
	if b == 1 then flags = flags + 98 end
	if i == 1 then flags = flags + 105 end
	if u == 1 then flags = flags + 117 end
	]]--
	
	local flags = 0
	
	if str then
		for i = 1, str:len() do 
			flags = flags * 256 + string.byte(str, i) 
		end 	
	end
	
	gfx.setfont(1, font, size, flags)

end


GUI.color = function (col)
	gfx.set(table.unpack(GUI.colors[col]))
end



-- Global shadow size, in pixels
GUI.shadow_dist = 2


-- Draw the given string of the first color with a shadow 
-- of the second color (at 45' to the bottom-right)
GUI.shadow = function (str, col1, col2)
	
	local x, y = gfx.x, gfx.y
	
	GUI.color(col2)
	for i = 1, GUI.shadow_dist do
		gfx.x, gfx.y = x + i, y + i
		gfx.drawstr(str)
	end
	
	GUI.color(col1)
	gfx.x, gfx.y = x, y
	gfx.drawstr(str)
	
end


-- Draw the given string using the given text and outline color presets
GUI.outline = function (str, col1, col2)

	local x, y = gfx.x, gfx.y
	
	GUI.color(col2)
	
	gfx.x, gfx.y = x + 1, y + 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x - 1, y + 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x - 1, y - 1
	gfx.drawstr(str)
	gfx.x, gfx.y = x + 1, y - 1
	gfx.drawstr(str)
	
	GUI.color(col1)
	gfx.x, gfx.y = x, y
	gfx.drawstr(str)
	
end

	---- General functions ----
		

-- Print stuff to the Reaper console. For debugging purposes.
GUI.Msg = function (message)
	reaper.ShowConsoleMsg(tostring(message).."\n")
end


-- Copy the contents of one table to another, since Lua can't do it natively
GUI.table_copy = function (source)
	
	if type(source) ~= "table" then return source end
	
	local meta = getmetatable(source)
	local new = {}
	for k, v in pairs(source) do
		if type(v) == "table" then
			new[k] = GUI.table_copy(v)
		else
			new[k] = v
		end
	end
	
	setmetatable(new, meta)
	return new
	
end

-- Compare the contents of one table to another, since Lua can't do it natively
GUI.table_compare = function (t_a, t_b)
	
	if type(t_a) ~= "table" or type(t_b) ~= "table" then return false end
	
	local key_exists = {}
	for k1, v1 in pairs(t_a) do
		local v2 = t_b[k1]
		if v2 == nil or not GUI.table_compare(v1, v2) then return false end
		key_exists[k1] = true
	end
	for k2, v2 in pairs(t_b) do
		if not key_exists[k2] then return false end
	end
	
end
		

-- Allows "for x, y in pairs(z) do" in alphabetical/numerical order
-- Copied from Programming In Lua, 19.3
GUI.kpairs = function (t, f)

	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
	
		i = i + 1
		
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
		
	end
	
	return iter
end


-- Returns an ordinal string (i.e. 30 --> 30th)
GUI.ordinal = function (num)
	
	rem = num % 10
	num = GUI.round(num)
	if num == 1 then
		str = num.."st"
	elseif rem == 2 then
		str = num.."nd"
	elseif num == 13 then
		str = num.."th"
	elseif rem == 3 then
		str = num.."rd"
	else
		str = num.."th"
	end
	
	return str
	
end



-- Take 8-bit RGB values and return the combined integer
-- (equal to hex colors of the form 0xRRGGBB)
GUI.rgb2num = function (red, green, blue)
	
	green = green * 256
	blue = blue * 256 * 256
	
	return red + green + blue

end


-- Convert a number to hexadecimal
GUI.num2hex = function (num)
	
		local hexstr = '0123456789abcdef'
		local s = ''
		
		while num > 0 do
			local mod = math.fmod(num, 16)
			s = string.sub(hexstr, mod+1, mod+1) .. s
			num = math.floor(num / 16)
		end
		
		if s == '' then s = '0' end
		return s
		
end


-- Convert a hex color to 8-bit values r,g,b
GUI.hex2rgb = function (num)
	
	if string.sub(num, 1, 2) == "0x" then
		num = string.sub(num, 3)
	end

	local red = string.sub(num, 1, 2)
	local blue = string.sub(num, 3, 4)
	local green = string.sub(num, 5, 6)
	
	red = tonumber(red, 16)
	blue = tonumber(blue, 16)
	green = tonumber(green, 16)
	
	return red, green, blue
	
end


-- Round a number to the nearest integer
GUI.round = function (num)
    return num % 1 >= 0.5 and math.ceil(num) or math.floor(num)
end


-- Improved roundrect() function with fill, adapted from mwe's EEL example.
GUI.roundrect = function (x, y, w, h, r, antialias, fill)
	
	local aa = antialias or 1
	fill = fill or 0
	
	if fill == 0 or false then
		gfx.roundrect(x, y, w, h, r, aa)
	elseif h >= 2 * r then
		
		-- Corners
		gfx.circle(x + r, y + r, r, 1, aa)			-- top-left
		gfx.circle(x + w - r, y + r, r, 1, aa)		-- top-right
		gfx.circle(x + w - r, y + h - r, r , 1, aa)	-- bottom-right
		gfx.circle(x + r, y + h - r, r, 1, aa)		-- bottom-left
		
		-- Ends
		gfx.rect(x, y + r, r, h - r * 2)
		gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
			
		-- Body + sides
		gfx.rect(x + r, y, w - r * 2, h + 1)
		
	else
	
		r = h / 2 - 1
	
		-- Ends
		gfx.circle(x + r, y + r, r, 1, aa)
		gfx.circle(x + w - r, y + r, r, 1, aa)
		
		-- Body
		gfx.rect(x + r, y, w - r * 2, h)
		
	end	
	
end


-- Improved triangle() function with optional non-fill
GUI.triangle = function (fill, ...)
	
	-- Pass any calls for a filled triangle on to the original function
	if fill == 1 then
		
		gfx.triangle(...)
		
	else
	
		-- Store all of the provided coordinates into an array
		local coords = {...}
		
		-- Duplicate the first pair at the end, so the last line will
		-- be drawn back to the starting point.
		coords[#coords + 1] = coords[1]
		coords[#coords + 1] = coords[2]
	
		-- Draw a line from each pair of coords to the next pair.
		for i = 1, #coords - 2, 2 do			
				
			gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])
		
		end		
	
	end
	
end


--[[ 
	Takes an angle in radians (omit Pi) and a radius, returns x, y
	Will return coordinates relative to an origin of 0, or absolute
	coordinates if an origin point is specified
]]--
GUI.polar2cart = function (angle, radius, ox, oy)
	
	local angle = angle * math.pi
	local x = radius * math.cos(angle)
	local y = radius * math.sin(angle)

	
	if ox and oy then x, y = x + ox, y + oy end

	return x, y
	
end


-- Are these coordinates inside the given element?
GUI.IsInside = function (elm, x, y)
	
	local inside = 
		x >= elm.x and x < (elm.x + elm.w) and 
		y >= elm.y and y < (elm.y + elm.h)
		
	return inside
	
end


-- Make sure the window position is on-screen
GUI.check_window_pos = function ()
	
	local x, y, w, h = GUI.x, GUI.y, GUI.w, GUI.h
	local l, t, r, b = x, y, x + w, y + h
	
	local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)
	
	if l < 0 then GUI.x = 0 end
	if r > screen_w then GUI.x = (screen_w - w - 16) end
	if t < 0 then GUI.y = 0 end
	if b > screen_h then GUI.y = (screen_h - h - 40) end
	
end

--[[
Returns x,y coordinates for a window with the specified anchor position

If no anchor is specified, it will default to the top-left corner of the screen.
	x,y		offset coordinates from the anchor position
	w,h		window dimensions
	anchor	"screen" or "mouse"
	corner	"TL"
			"T"
			"TR"
			"R"
			"BR"
			"B"
			"BL"
			"L"
			"C"
]]--
GUI.get_window_pos = function (x, y, w, h, anchor, corner)

	local ax, ay, aw, ah = 0, 0, 0 ,0
	local __, __, scr_w, scr_h = reaper.my_getViewport(x, y, x + w, y + h, x, y, x + w, y + h, 1)
	
	if anchor == "screen" then
		aw, ah = scr_w, scr_h
	elseif anchor =="mouse" then
		ax, ay = reaper.GetMousePosition()
	end
	
	local cx, cy = 0, 0
	if corner then
		local corners = {
			TL = 	{0, 				0},
			T =		{(aw - w) / 2, 		0},
			TR = 	{(aw - w) - 16,		0},
			R =		{(aw - w) - 16,		(ah - h) / 2},
			BR = 	{(aw - w) - 16,		(ah - h) - 40},
			B =		{(aw - w) / 2, 		(ah - h) - 40},
			BL = 	{0, 				(ah - h) - 40},
			L =	 	{0, 				(ah - h) / 2},
			C =	 	{(aw - w) / 2,		(ah - h) / 2},
		}
		
		cx, cy = table.unpack(corners[corner])
	end	
	
	x = x + ax + cx
	y = y + ay + cy
	
	
	-- Make sure the window is entirely on-screen
	local l, t, r, b = x, y, x + w, y + h
	
	if l < 0 then x = 0 end
	if r > scr_w then x = (scr_w - w - 16) end
	if t < 0 then y = 0 end
	if b > scr_h then y = (scr_h - h - 40) end
	
	return x, y	
	
end



	---- Our main functions ----
	
	


GUI.Init = function ()
	
	
	-- Create the window
	gfx.clear = GUI.rgb2num(table.unpack(GUI.colors.wnd_bg))
	
	-- local x, y = reaper.GetMousePosition()
	-- if GUI.x == "c" then GUI.x = x - (GUI.w / 2) end
	-- if GUI.y == "c" then GUI.y = y - (GUI.h / 2) end	
	
	if not GUI.x then GUI.x = 0 end
	if not GUI.y then GUI.y = 0 end
	if not GUI.w then GUI.w = 640 end
	if not GUI.h then GUI.h = 480 end
	

	
	GUI.x, GUI.y = GUI.get_window_pos(GUI.x, GUI.y, GUI.w, GUI.h, GUI.anchor, GUI.corner)
		
	gfx.init(GUI.name, GUI.w, GUI.h, 0, GUI.x, GUI.y)
	
	GUI.cur_w, GUI.cur_h = gfx.w, gfx.h

	-- Measure the window's title bar, in case we need it
	local __, __, wnd_y, __, __ = gfx.dock(-1, 0, 0, 0, 0)
	local __, gui_y = gfx.clienttoscreen(0, 0)
	GUI.title_height = gui_y - wnd_y


-- Initialize a few values
	GUI.last_time = 0
	GUI.mouse = {
	
		x = 0,
		y = 0,
		cap = 0,
		down = false,
		r_down = false,
		wheel = 0,
		lwheel = 0
		
	}
		
	-- Convert color presets from 0..255 to 0..1
	for i, col in pairs(GUI.colors) do
		col[1], col[2], col[3], col[4] = col[1] / 255, col[2] / 255, col[3] / 255, col[4] / 255
	end
	
	if GUI.Exit then reaper.atexit(GUI.Exit) end

end


GUI.Main = function ()
	
	-- Update mouse and keyboard state, window dimensions
	GUI.mouse.x, GUI.mouse.y = gfx.mouse_x, gfx.mouse_y
	GUI.mouse.wheel = gfx.mouse_wheel
	GUI.mouse.cap = gfx.mouse_cap
	GUI.char = gfx.getchar() 
	
	if GUI.cur_w ~= gfx.w or GUI.cur_h ~= gfx.h then
		GUI.cur_w, GUI.cur_h = gfx.w, gfx.h
		GUI.resized = true
	else
		GUI.resized = false
	end
	
	--	(Escape key)	(Window closed)		(User function says to close)
	if GUI.char == 27 or GUI.char == -1 or GUI.quit == true then
		return 0
	else
		reaper.defer(GUI.Main)
	end

	-- Update each element's state, starting from the top down.
		-- This is very important, so that lower elements don't
		-- "steal" the mouse.
	for key, elm in pairs(GUI.elms_top) do
		GUI.Update(elm)
	end
	for key, elm in pairs(GUI.elms) do
		GUI.Update(elm)
	end
	for key, elm in pairs(GUI.elms_bottom) do
		GUI.Update(elm)
	end	
	for key, elm in pairs(GUI.elms_bg) do
		GUI.Update(elm)
	end
	
	-- If the user gave us a function to run, check to see if it needs to be run again, and do so.
	if GUI.func then
		
		GUI.freq = GUI.freq or 1
		
		local new_time = os.time()
		if new_time - GUI.last_time >= GUI.freq then
			GUI.func()
			GUI.last_time = new_time
		
		end
	end
	
	-- Redraw all of the elements, starting from the bottom up.
	for key, elm in pairs(GUI.elms_bottom) do
		elm:draw()
	end
	for key, elm in pairs(GUI.elms) do
		elm:draw()
	end
	for key, elm in pairs(GUI.elms_top) do
		elm:draw()
	end

	
	GUI.Draw_Version()
	
	gfx.update()
	
end


GUI.Update = function (elm)
	
	local x, y = GUI.mouse.x, GUI.mouse.y
	local wheel = GUI.mouse.wheel
	local char = GUI.char
	local inside = GUI.IsInside(elm, x, y)
	

	-- Left button click
	if GUI.mouse.cap&1==1 then
		
		-- If it wasn't down already...
		if not GUI.mouse.down then

			-- Was a different element clicked?
			if not inside then 
		
				elm.focus = false
			else	
	
				GUI.mouse.down = true
				GUI.mouse.ox, GUI.mouse.oy = x, y
				GUI.mouse.lx, GUI.mouse.ly = x, y
				elm.focus = true
				elm:onmousedown()
			
			end
			
			-- Double clicked?
			if GUI.mouse.uptime and os.clock() - GUI.mouse.uptime < 0.15 then
				elm:ondoubleclick()
			end
		
		-- 		Dragging? 									Did the mouse start out in this element?
		elseif (x ~= GUI.mouse.lx or y ~= GUI.mouse.ly) and GUI.IsInside(elm, GUI.mouse.ox, GUI.mouse.oy) then
			if elm.focus ~= nil then elm:ondrag() end
			GUI.mouse.lx, GUI.mouse.ly = x, y
		end

	-- If it was originally clicked in this element and has now been released
	elseif GUI.mouse.down and GUI.IsInside(elm, GUI.mouse.ox, GUI.mouse.oy) then 
	
		elm:onmouseup()
		GUI.mouse.down = false
		GUI.mouse.ox, GUI.mouse.oy = -1, -1
		GUI.mouse.lx, GUI.mouse.ly = -1, -1
		GUI.mouse.uptime = os.clock()

	end
	
	
	-- Right button click
	if GUI.mouse.cap&2==2 then
		
		-- If it wasn't down already...
		if not GUI.mouse.r_down then

			-- Was a different element clicked?
			if not inside then 
				--elm.focus = false
			else
	
				GUI.mouse.r_down = true
				GUI.mouse.r_ox, GUI.mouse.r_oy = x, y
				GUI.mouse.r_lx, GUI.mouse.r_ly = x, y
				--elm.focus = true
				elm:onmouser_down()
			
			end
			
			-- Double clicked?
			if GUI.mouse.r_uptime and os.clock() - GUI.mouse.r_uptime < 0.15 then
				elm:onr_doubleclick()
			end
		
		-- 		Dragging? 									Did the mouse start out in this element?
		elseif (x ~= GUI.mouse.r_lx or y ~= GUI.mouse.r_ly) and GUI.IsInside(elm, GUI.mouse.r_ox, GUI.mouse.r_oy) then
			if elm.focus ~= nil then elm:onr_drag() end
			GUI.mouse.r_lx, GUI.mouse.r_ly = x, y
		end

	-- If it was originally clicked in this element and has now been released
	elseif GUI.mouse.r_down and GUI.IsInside(elm, GUI.mouse.r_ox, GUI.mouse.r_oy) then 
	
		elm:onmouser_up()
		GUI.mouse.r_down = false
		GUI.mouse.r_ox, GUI.mouse.r_oy = -1, -1
		GUI.mouse.r_lx, GUI.mouse.r_ly = -1, -1
		GUI.mouse.r_uptime = os.clock()

	end
	
	
	-- If the mouse is hovering over the element
	if not GUI.mouse.down and not GUI.mouse.r_down and inside then
		elm:onmouseover()
	else
		--elm.hovering = false
	end
	
	
	-- If the mousewheel's state has changed
	if GUI.mouse.wheel ~= GUI.mouse.lwheel and inside then
		
		local inc = (GUI.mouse.wheel - GUI.mouse.lwheel) / 120
		
		elm:onwheel(inc)
		GUI.mouse.lwheel = GUI.mouse.wheel
	
	end
	
	-- If the element is in focus and the user typed something
	if elm.focus and char ~= 0 then elm:ontype(char) end
	
end


-- For use with external user functions. Returns the given element's current value or, if specified, sets a new one.
GUI.Val = function (elm, newval)

	if not GUI.elms[elm] then return nil end
	
	if newval then
		GUI.elms[elm]:val(newval)
	else
		return GUI.elms[elm]:val()
	end

end


-- Display the version number
GUI.Draw_Version = function ()
	
	local str = "built with Lokasenna_GUI "..GUI.version
	
	gfx.setfont(1, "Arial", 12, 105)
	GUI.color("txt")
	
	local str_w, str_h = gfx.measurestr(str)
	
	--gfx.x = GUI.w - str_w - 4
	--gfx.y = GUI.h - str_h - 4
	gfx.x = gfx.w - str_w - 4
	gfx.y = gfx.h - str_h - 4
	
	gfx.drawstr(str)	
	
end




	---- Elements ----


--[[	Label class.
	
	---- User parameters ----
x, y			Coordinates of top-left corner
caption			Label text
shadow			(1) Draw a shadow
font			Which of the GUI's font values to use
	
]]--
-- Label - New
GUI.Label = {}
function GUI.Label:new(x, y, caption, shadow, font)
	
	local label = {}	
	
	label.type = "Label"
	
	label.x, label.y = x, y
	
	-- Placeholders for these values, since we don't need them but some functions will throw a fit if they aren't there
	label.w, label.h = 0, 0
	
	label.retval = caption
	
	label.shadow = shadow or 0
	label.font = font or 1
	
	
	setmetatable(label, self)
    self.__index = self 
    return label
	
end


-- Label - Draw
function GUI.Label:draw()
	
	local x, y = self.x, self.y
		
	GUI.font(self.font)
	GUI.color(self.color or "txt")
	
	gfx.x, gfx.y = x, y
	
	if self.h == 0 then	
		self.w, self.h = gfx.measurestr(self.retval)
	end
	
	if self.shadow == 1 then	
		GUI.shadow(self.retval, self.color or "txt", "shadow")
	else
		gfx.drawstr(self.retval)
	end	

end


-- Label - Get/set value
function GUI.Label:val(newval)

	if newval then
		self.retval = newval
		GUI.font(self.font)
		self.w, self.h = gfx.measurestr(self.retval)
	else
		return self.retval
	end

end

-- Label - Unused methods.
function GUI.Label:onmousedown() end
function GUI.Label:onmouseup() end
function GUI.Label:ondoubleclick() end
function GUI.Label:ondrag() end
function GUI.Label:onmouser_down() end
function GUI.Label:onmouser_up() end
function GUI.Label:onr_doubleclick() end
function GUI.Label:onr_drag() end
function GUI.Label:onwheel() end
function GUI.Label:onmouseover() end
function GUI.Label:ontype() end


--[[	Slider class.

	---- User parameters ----
x, y, w			Coordinates of top-left corner, width. Height is fixed.
caption			Label / question
min, max		Minimum and maximum slider values
steps			How many steps between min and max
default			Where the slider should start
				(also sets the start of the fill bar)
ticks			Display ticks or not. **Currently does nothing**

]]--

-- Slider - New
GUI.Slider = {}
function GUI.Slider:new(x, y, w, caption, min, max, steps, default, ticks)
	
	local Slider = {}
	Slider.type = "Slider"
	
	Slider.x, Slider.y, Slider.w, Slider.h = x, y, w, 8

	Slider.caption = caption
	
	Slider.min, Slider.max = min, max
	Slider.steps = steps
	Slider.default, Slider.curstep = default, default
	
	Slider.ticks = ticks
	
	Slider.curval = Slider.curstep / steps
	Slider.retval = GUI.round((((max - min) / steps) * Slider.curstep) + min)
	
	setmetatable(Slider, self)
	self.__index = self
	return Slider	
	
end


-- Slider - Draw
function GUI.Slider:draw()
	
	
	local x, y, w, h = self.x, self.y, self.w, self.h

	local steps = self.steps
	local curstep = self.curstep
	local min, max = self.min, self.max
	
	-- Size of the handle
	local radius = 8


	-- Draw track
	GUI.color("elm_bg")
	GUI.roundrect(x, y, w, h, 4, 1, 1)
	GUI.color("elm_outline")
	GUI.roundrect(x, y, w, h, 4, 1, 0)

	
	-- Limit everything to be drawn within the square part of the track
	x, w = x + 4, w - 8

	
	-- Handle
	local inc = w / steps
	local ox, oy = x + inc * curstep, y + (h / 2)
	
	-- Fill in between the two handles
	local fill_x = GUI.round( x + ((self.default / steps) * w) )
	local fill_w = GUI.round( ox - fill_x )
	

	if fill_w < 0 then
		fill_w = math.abs(fill_w)
		fill_x = fill_x - fill_w
	end
		
	GUI.color("elm_fill")
	gfx.rect(fill_x, y + 1, fill_w, h - 2, 1)
	
	
	-- Handle shadows
	GUI.color("shadow")
	for i = 1, GUI.shadow_dist do
		
		gfx.circle(ox + i, oy + i, radius - 1, 1, 1)
		
	end

	-- Handle bodies
	GUI.color("elm_frame")
	gfx.circle(ox, oy, radius - 1, 1, 1)
	
	GUI.color("elm_outline")
	gfx.circle(ox, oy, radius, 0, 1)


	-- Draw caption	
	GUI.font(3)
	
	local str_w, str_h = gfx.measurestr(self.caption)
	
	gfx.x = x + (w - str_w) / 2
	gfx.y = y - h - str_h


	GUI.shadow(self.caption, "txt", "shadow")
	
	-- Draw ticks + highlighted labels if specified	
	-- Draw slider value otherwise 
	
	GUI.font(4)
	
	local output = self.output or self.retval
	
	local str_w, str_h = gfx.measurestr(output)
	gfx.x = x + (w - str_w) / 2
	gfx.y = y + h + h
	
	gfx.drawstr(output)
	
end


-- Slider - Get/set value
function GUI.Slider:val(newval)

	if newval then
		self.retval = newval
	else
		return self.retval
	end

end


-- Slider - Mouse down
function GUI.Slider:onmousedown()
	
	-- Snap to the nearest value
	self.curval = (GUI.mouse.x - self.x) / self.w
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end
	
	self.curstep = GUI.round(self.curval * self.steps)
	
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	
end


-- Slider - Dragging
function GUI.Slider:ondrag()
	
	local x = GUI.mouse.x
	local lx = GUI.mouse.lx
	
	-- Ctrl?
	local ctrl = GUI.mouse.cap&4==4
	
	-- A multiplier for how fast the slider should move. Higher values = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150
	
	-- Make sliders behave consistently at different sizes
	local adj_scale = self.w / 150
	adj = adj * adj_scale
		
	self.curval = self.curval + ((x - lx) / adj)
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end
	
	self.curstep = GUI.round(self.curval * self.steps)
	
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	
end


-- Slider - Mousewheel
function GUI.Slider:onwheel(inc)
	
	local ctrl = GUI.mouse.cap&4==4
	
	-- How many steps per wheel-step.
	local fine = 1
	local coarse = math.max( GUI.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse
	
	self.curval = self.curval + inc * adj / self.steps
	
	if self.curval < 0 then self.curval = 0 end
	if self.curval > 1 then self.curval = 1 end

	self.curstep = GUI.round(self.curval * self.steps)
	
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)

end


-- Slider - Unused methods
function GUI.Slider:onmouseup() end
function GUI.Slider:ondoubleclick() end
function GUI.Slider:ontype() end
function GUI.Slider:onmouser_down() end
function GUI.Slider:onmouser_up() end
function GUI.Slider:onr_doubleclick() end
function GUI.Slider:onr_drag() end
function GUI.Slider:onmouseover() end




--[[	Range class
	
		---- User parameters ----
x, y, w			Coordinates of top-left corner, width. Height is fixed.
caption			Label / question
min, max		Minimum and maximum slider values
steps			How many steps between min and max
default_a		Where the sliders should start
default_b		
ticks			Display ticks or not. **Currently does nothing**
	
	
]]--
GUI.Range = {}
function GUI.Range:new(x, y, w, caption, min, max, steps, default_a, default_b)
	
	local Range = {}
	Range.type = "Range"
	
	Range.x, Range.y, Range.w, Range.h = x, y, w, 8

	Range.caption = caption
	
	Range.min, Range.max = min, max
	Range.steps = steps
	Range.default_a, Range.default_b = default_a, default_b
	Range.curstep_a, Range.curstep_b = default_a, default_b
	
	Range.curval_a = Range.curstep_a / steps
	Range.curval_b = Range.curstep_b / steps

	Range.retval_a = GUI.round(((max - min) / steps) * Range.curstep_a + min)
	Range.retval_b = GUI.round(((max - min) / steps) * Range.curstep_b + min)
	
	setmetatable(Range, self)
	self.__index = self
	return Range	
	
end


-- Range - Draw
function GUI.Range:draw()

	local x, y, w, h = self.x, self.y, self.w, self.h

	local steps = self.steps
	local curstep_a = self.curstep_a
	local curstep_b = self.curstep_b
	
	local min, max = self.min, self.max
	
	-- Size of the handle
	local radius = 8


	-- Draw track
	GUI.color("elm_bg")
	GUI.roundrect(x, y, w, h, 4, 1, 1)
	GUI.color("elm_outline")
	GUI.roundrect(x, y, w, h, 4, 1, 0)

	
	-- Limit everything to be drawn within the square part of the track
	x, w = x + 4, w - 8


	-- Handles
	local inc = w / steps
	local ox_a, oy_a = x + inc * curstep_a, y + (h / 2)
	local ox_b, oy_b = x + inc * curstep_b, oy_a
	local ox_fill = ox_a < ox_b and ox_a or ox_b
	
	local fill_w = math.abs(ox_a - ox_b)
	
	-- Fill in between the two handles
	GUI.color("elm_fill")
	gfx.rect(ox_fill, y + 1, fill_w, h - 2, 1)
	
	-- Handle shadows
	GUI.color("shadow")
	for i = 1, GUI.shadow_dist do
		
		gfx.circle(ox_a + i, oy_a + i, radius - 1, 1, 1)
		gfx.circle(ox_b + i, oy_b + i, radius - 1, 1, 1)

	end

	-- Handle bodies
	GUI.color("elm_frame")
	gfx.circle(ox_a, oy_a, radius - 1, 1, 1)
	gfx.circle(ox_b, oy_b, radius - 1, 1, 1)
	
	GUI.color("elm_outline")
	gfx.circle(ox_a, oy_a, radius, 0, 1)
	gfx.circle(ox_b, oy_b, radius, 0, 1)
	

	-- Draw caption	
	GUI.font(3)
	
	local str_w, str_h = gfx.measurestr(self.caption)
	
	gfx.x = x + (w - str_w) / 2
	gfx.y = y - h - str_h
	
	GUI.shadow(self.caption, "txt", "shadow")
	
	
	GUI.font(4)
	
	-- Handle A's value
	local output_a = self.output_a or self.retval_a
	local str_w, str_h = gfx.measurestr(output)
	gfx.x = x
	gfx.y = y + h + h
	
	gfx.drawstr(output_a)
	
	-- Handle B's value
	local output_b = self.output_b or self.retval_b
	local str_w, str_h = gfx.measurestr(output_b)
	gfx.x = x + w - str_w
	--gfx.y = y + h + h
	
	gfx.drawstr(output_b)	
	
end


-- Range - Get/set value
function GUI.Range:val(newval_a, newval_b)
	
	if newval_a or newval_b then
		retval_a = newval_a
		retval_b = newval_b
		
		if retval_a > retval_b then
			retval_a, retval_b = retval_b, retval_a
		end
		
		self.retval_a = retval_a
		self.retval_b = retval_b
	
	else
		
		return self.retval_a, self.retval_b
		
	end

end


-- Range - Mouse down
function GUI.Range:onmousedown()
	
	-- Snap the nearest slider to the nearest value
	
	local mouse_val = (GUI.mouse.x - self.x) / self.w

	local diff_a = math.abs(mouse_val - self.curval_a)
	local diff_b = math.abs(mouse_val - self.curval_b)

	local handle = (diff_a < diff_b) and "a" or "b"
	
	-- I really like being able to specify which handle to use like this. I think it's neat.
	local val = "curval_"..handle
	local step = "curstep_"..handle
	local ret = "retval_"..handle
	
	self[val] = mouse_val
	if self[val] > 1 then self[val] = 1 end
	if self[val] < 0 then self[val] = 0 end
	
	self[step] = GUI.round(self[val] * self.steps)
	
	self.handle = handle
	
	self[ret] = GUI.round(((self.max - self.min) / self.steps) * self[step] + self.min)
	
end


-- Range - Dragging
function GUI.Range:ondrag()
	
	local x = GUI.mouse.x
	local lx = GUI.mouse.lx
	
	local ret = "retval_"..self.handle
	local dragval = "curval_"..self.handle
	local dragstep = "curstep_"..self.handle
	
	
	-- Ctrl?
	local ctrl = GUI.mouse.cap&4==4
	
	-- A multiplier for how fast the slider should move. Higher values = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150
	local adj_scale = self.w / 150
	adj = adj * adj_scale
	
	
	self[dragval] = self[dragval] + ((x - lx) / adj)
	if self[dragval] > 1 then self[dragval] = 1 end
	if self[dragval] < 0 then self[dragval] = 0 end
	
	self[dragstep] = GUI.round(self[dragval] * self.steps)
	
	self[ret] = GUI.round(((self.max - self.min) / self.steps) * self[dragstep] + self.min)
	
end


-- Range - Mousewheel
function GUI.Range:onwheel(inc)
	
	local mouse_val = (GUI.mouse.x - self.x) / self.w

	local diff_a = math.abs(mouse_val - self.curval_a)
	local diff_b = math.abs(mouse_val - self.curval_b)

	local handle = (diff_a < diff_b) and "a" or "b"
	
	local val = "curval_"..handle
	local step = "curstep_"..handle
	local ret = "retval_"..handle
	
	
	local ctrl = GUI.mouse.cap&4==4
	
	-- How many steps per wheel-step
	local fine = 1
	local coarse = math.max( GUI.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse

	
	self[val] = self[val] + inc * adj / self.steps
	
	if self[val] < 0 then self[val] = 0 end
	if self[val] > 1 then self[val] = 1 end

	self[step] = GUI.round(self[val] * self.steps)
	
	self[ret] = GUI.round(((self.max - self.min) / self.steps) * self[step] + self.min)
	
end


function GUI.Range:onmouseup() end
function GUI.Range:ondoubleclick() end
function GUI.Range:ontype() end
function GUI.Range:onmouser_down() end
function GUI.Range:onmouser_up() end
function GUI.Range:onr_doubleclick() end
function GUI.Range:onr_drag() end
function GUI.Range:onmouseover() end


--[[	Knob class.

	---- User parameters ----
x, y, w			Coordinates of top-left corner, width. Height is fixed.
caption			Label / question
min, max		Minimum and maximum slider values
steps			How many steps between min and max
default			Where the slider should start
ticks			(1) display tick marks, (0) no tick marks
	
]]--

-- Knob - New.
GUI.Knob = {}
function GUI.Knob:new(x, y, w, caption, min, max, steps, default, ticks)
	
	local Knob = {}
	Knob.type = "Knob"
	
	Knob.x, Knob.y, Knob.w, Knob.h = x, y, w, w

	Knob.caption = caption
	
	Knob.min, Knob.max = min, max
	
	Knob.steps, Knob.ticks = steps - 1, ticks or 0
	
	-- Determine the step angle
	Knob.stepangle = (3 / 2) / Knob.steps
	
	Knob.default, Knob.curstep = default - 1, default - 1
	
	Knob.retval = GUI.round(((max - min) / Knob.steps) * Knob.curstep + min)
	Knob.output = {}

	Knob.curval = Knob.curstep / Knob.steps
	
	setmetatable(Knob, self)
	self.__index = self
	return Knob

end


-- Knob - Draw
function GUI.Knob:draw()
	
	
	local x, y, w = self.x, self.y, self.w

	local caption = self.caption
	
	local min, max = self.min, self.max

	local default = self.default
	
	local ticks = self.ticks
	local stepangle = self.stepangle
	
	local curstep = self.curstep
	
	local steps = self.steps
	
	local r = w / 2
	local o = {x = x + r, y = y + r}
	
	
	-- Figure out where the knob is pointing
	local curangle = (-5 / 4) + (curstep * stepangle)
	

	-- Ticks and labels	
	if ticks > 0 then
		
		GUI.font(4)
		
		for i = 0, steps do
			
			local angle = (-5 / 4 ) + (i * stepangle)
			
			GUI.color("elm_frame")
			
			-- Tick marks
			local x1, y1 = GUI.polar2cart(angle, r * 1.2, o.x, o.y)
			local x2, y2 = GUI.polar2cart(angle, r * 1.6, o.x, o.y)

			gfx.line(x1, y1, x2, y2)
			
			-- Highlight the current value
			if i == curstep then
				GUI.color("elm_fill")
			else
				GUI.color("txt")
			end
			
			-- Values
			--local str = self.stepcaps[i] or tostring(i + min)
			local str = self.output[i] or tostring(i + min)
			local cx, cy = GUI.polar2cart(angle, r * 2, o.x, o.y)
			local str_w, str_h = gfx.measurestr(str)
			gfx.x, gfx.y = cx - str_w / 2, cy - str_h / 2
			
			gfx.drawstr(str)
			
		
		end
	end
	
	
	-- Caption
	
	GUI.font(3)
	cx, cy = GUI.polar2cart(1/2, r * 2, o.x, o.y)
	local str_w, str_h = gfx.measurestr(caption)
	gfx.x, gfx.y = cx - str_w / 2, cy - str_h / 2
	GUI.shadow(caption, "txt", "shadow")

	
	-- Figure out the points of the triangle
	local curangle = (-5 / 4) + (curstep * stepangle) 

	local Ax, Ay = GUI.polar2cart(curangle, 1.4 * r, o.x, o.y)
	local Bx, By = GUI.polar2cart(curangle + 1/2, r - 1, o.x, o.y)
	local Cx, Cy = GUI.polar2cart(curangle - 1/2, r - 1, o.x, o.y)
	
	-- Shadow
	GUI.color("shadow")
	local dist = GUI.shadow_dist
	for i = 1, dist do
		gfx.triangle(Ax + i, Ay + i, Bx + i, By + i, Cx + i, Cy + i)
		gfx.circle(o.x + i, o.y + i, r, 1)
	end

	
	-- Head
	GUI.color("elm_fill")
	GUI.triangle(1, Ax, Ay, Bx, By, Cx, Cy)
	GUI.color("elm_outline")
	GUI.triangle(0, Ax, Ay, Bx, By, Cx, Cy)	
	
	-- Body
	GUI.color("elm_frame")
	gfx.circle(o.x, o.y, r, 1)
	GUI.color("elm_outline")
	gfx.circle(o.x, o.y, r, 0)		

	--self.retval = GUI.round(((max - min) / steps) * curstep + min)
	
end


-- Knob - Get/set value
function GUI.Knob:val(newval)
	
	if newval then
		self.retval = newval
		self.curstep = newval - self.min
		self.curval = self.curstep / self.steps
		
	else
		return self.retval
	end	

end


-- Knob - Dragging.
function GUI.Knob:ondrag()
	
	local y = GUI.mouse.y
	local ly = GUI.mouse.ly

	-- Ctrl?
	local ctrl = GUI.mouse.cap&4==4
	
	-- Multiplier for how fast the knob turns. Higher = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150
	
	self.curval = self.curval + ((ly - y) / adj)
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end
	
	self.curstep = GUI.round(self.curval * self.steps)
	
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	
end


-- Knob - Mousewheel
function GUI.Knob:onwheel(inc)

	local ctrl = GUI.mouse.cap&4==4
	
	-- How many steps per wheel-step
	local fine = 1
	local coarse = math.max( GUI.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse
	
	self.curval = self.curval + inc * adj / self.steps
	
	if self.curval < 0 then self.curval = 0 end
	if self.curval > 1 then self.curval = 1 end

	self.curstep = GUI.round(self.curval * self.steps)
	
	self:val()

end


-- Unused methods.
function GUI.Knob:onmousedown() end
function GUI.Knob:onmouseup() end
function GUI.Knob:ondoubleclick() end
function GUI.Knob:ontype() end
function GUI.Knob:onmouser_down() end
function GUI.Knob:onmouser_up() end
function GUI.Knob:onr_doubleclick() end
function GUI.Knob:onr_drag() end
function GUI.Knob:onmouseover() end


--[[	Radio class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and each option

]]--

-- Radio - New.
GUI.Radio = {}
function GUI.Radio:new(x, y, w, h, caption, opts, pad)
	
	local opt_lst = {}
	opt_lst.type = "Radio"
	
	opt_lst.x, opt_lst.y, opt_lst.w, opt_lst.h = x, y, w, h

	opt_lst.caption = caption
	
	opt_lst.pad = pad
	
	-- Parse the string of options into a table
	opt_lst.optarray = {}
	local tempidx = 1
	for word in string.gmatch(opts, '([^,]+)') do
		opt_lst.optarray[tempidx] = word
		tempidx = tempidx + 1
	end
	
	opt_lst.numopts = tempidx - 1
	
	-- Currently-selected option
	opt_lst.retval, opt_lst.state = 1, 1
	
	setmetatable(opt_lst, self)
    self.__index = self 
    return opt_lst
	
end


-- Radio - Draw.
function GUI.Radio:draw()
	
	
	local x, y, w, h = self.x, self.y, self.w, self.h

	local pad = self.pad
	
	-- Draw the list frame
	GUI.color("elm_frame")
	gfx.rect(x, y, w, h, 0)
	

	-- Draw the caption

	GUI.font(2)
	
	local str_w, str_h = gfx.measurestr(self.caption)
	self.capheight = str_h

	gfx.x = x + (w - str_w) / 2
	gfx.y = y
	
	GUI.shadow(self.caption, "txt", "shadow")
	
	GUI.font(3)

	-- Draw the options
	GUI.color("txt")
	local optheight = (h - self.capheight - 2 * pad) / self.numopts
	local cur_y = y + self.capheight + pad
	local radius = 10
	
	for i = 1, self.numopts do	
		

		--gfx.set(r, g, b, 1)

		-- Option bubble
		GUI.color("elm_frame")
		gfx.circle(x + 2 * radius, cur_y + optheight / 2, radius, 0)

		-- Fill in the selected option and set its label to the window's bg color
		if i == self.state then
			GUI.color("elm_fill")
			gfx.circle(x + 2 * radius, cur_y + optheight / 2, radius * 0.5, 1)
		end
		
		-- Labels
		GUI.color("txt")
		local str_w, str_h = gfx.measurestr(self.optarray[i])
		
		gfx.x = x + 4 * radius
		gfx.y = cur_y + (optheight - str_h) / 2
		gfx.drawstr(self.optarray[i])		
		
		cur_y = cur_y + optheight

		
	end
	
end


-- Radio - Get/set value
function GUI.Radio:val(newval)
	
	if newval then
		self.state = newval
	else
		return self.retval
	end	
	
end


-- Radio - Mouse down.
function GUI.Radio:onmousedown()
			
	--See which option it's on
	local adj_y = self.y + self.capheight + self.pad
	local adj_h = self.h - self.capheight - self.pad
	local mouseopt = (GUI.mouse.y - adj_y) / adj_h
		
	mouseopt = math.floor(mouseopt * self.numopts) + 1

	self.state = mouseopt
	
end


-- Radio - Mouse up
function GUI.Radio:onmouseup()
		
	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		self.retval = self.state
	else
		self.state = self.retval	
	end
	
end


-- Radio - Dragging
function GUI.Radio:ondrag() 

	self:onmousedown()

end


-- Radio - Mousewheel
function GUI.Radio:onwheel(inc)
	
	self.state = self.state - inc
	
	if self.state < 1 then self.state = 1 end
	if self.state > self.numopts then self.state = self.numopts end
	
	self.retval = self.state
	
end


-- Radio - Unused methods.
function GUI.Radio:ondoubleclick() end
function GUI.Radio:ontype() end
function GUI.Radio:onmouser_down() end
function GUI.Radio:onmouser_up() end
function GUI.Radio:onr_doubleclick() end
function GUI.Radio:onr_drag() end
function GUI.Radio:onmouseover() end



--[[	Checklist class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and each option


]]--

-- Checklist - New
GUI.Checklist = {}
function GUI.Checklist:new(x, y, w, h, caption, opts, pad)
	
	local chk = {}
	chk.type = "Checklist"
	
	chk.x, chk.y, chk.w, chk.h = x, y, w, h

	chk.caption = caption
	
	chk.pad = pad


	-- Parse the string of options into a table
	chk.optarray, chk.optsel = {}, {}
	local tempidx = 1
	for word in string.gmatch(opts, '([^,]+)') do
		chk.optarray[tempidx] = word
		chk.optsel[tempidx] = false
		tempidx = tempidx + 1
	end
	
	chk.retval = chk.optsel
	
	chk.numopts = tempidx - 1
	
	setmetatable(chk, self)
    self.__index = self 
    return chk
	
end


-- Checklist - Draw
function GUI.Checklist:draw()
	
	
	local x, y, w, h = self.x, self.y, self.w, self.h

	local pad = self.pad
	
	-- Draw the element frame
	
	if self.caption ~= "" then
		
		GUI.color("elm_frame")
		gfx.rect(x, y, w, h, 0)
		
	end	


	GUI.font(2)
	
	-- Draw the caption
	local str_w, str_h = gfx.measurestr(self.caption)
	self.capheight = str_h
	gfx.x = x + (w - str_w) / 2
	gfx.y = y
	GUI.shadow(self.caption, "txt", "shadow")
	

	-- Draw the options
	GUI.color("txt")
	local optheight = (h - str_h - 2 * pad) / self.numopts
	local cur_y = y + str_h + pad
	local size = 20
	GUI.font(3)

	for i = 1, self.numopts do

		
		-- Draw the option frame
		GUI.color("elm_frame")
		gfx.rect(x + size / 2, cur_y + (optheight - size) / 2, size, size, 0)
				
		-- Fill in if selected
		if self.optsel[i] == true then
			
			GUI.color("elm_fill")
			gfx.rect(x + size * 0.75, cur_y + (optheight - size) / 2 + size / 4, size / 2, size / 2, 1)
		
		end
		
		local str_w, str_h = gfx.measurestr(self.optarray[i])
		gfx.x = x + 2 * size
		gfx.y = cur_y + (optheight - str_h) / 2
		
		if self.numopts == 1 then
			GUI.shadow(self.optarray[i], "txt", "shadow")
		else
			GUI.color("txt")
			gfx.drawstr(self.optarray[i])
		end
		
		cur_y = cur_y + optheight
		
	end
	
end


-- Checklist - Get/set value. Returns a table of boolean values for each option.
function GUI.Checklist:val(...)
	
	if ... then 
		local newvals = {...}
		for i = 1, self.numopts do
			self.optsel[i] = newvals[i]
		end
	else
		return self.optsel
	end
	
end


-- Checklist - Mouse down
function GUI.Checklist:onmouseup()

	
	-- See which option it's on
	local adj_y = self.y + self.capheight
	local adj_h = self.h - self.capheight
	local mouseopt = (GUI.mouse.y - adj_y) / adj_h
	mouseopt = math.floor(mouseopt * self.numopts) + 1
	
	-- Make that the current option
	
	self.optsel[mouseopt] = not self.optsel[mouseopt] 
	
	--self:val()
	
end

-- Checklist - Unused methods.
function GUI.Checklist:onwheel() end
function GUI.Checklist:onmousedown() end
function GUI.Checklist:ondoubleclick() end
function GUI.Checklist:ondrag() end
function GUI.Checklist:ontype() end
function GUI.Checklist:onmouser_down() end
function GUI.Checklist:onmouser_up() end
function GUI.Checklist:onr_doubleclick() end
function GUI.Checklist:onr_drag() end
function GUI.Checklist:onmouseover() end



--[[	Button class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, height
caption			Label / question
func			Function to perform when clicked
...				If provided, any parameters to pass to that function

Add afterward:
r_func			Function to perform when right-clicked
r_params		If provided, any parameters to pass to that function
]]--

-- Button - New
GUI.Button = {}
function GUI.Button:new(x, y, w, h, caption, func, ...)

	local Button = {}
	Button.type = "Button"
	
	Button.x, Button.y, Button.w, Button.h = x, y, w, h

	Button.caption = caption
	
	Button.func = func or function () end
	Button.params = {...}
	
	Button.state = 0

	setmetatable(Button, self)
	self.__index = self
	return Button

end


-- Button - Draw.
function GUI.Button:draw()
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	local state = self.state
		
	
	-- Draw the shadow if not pressed
	if state == 0 then
		local dist = GUI.shadow_dist
		GUI.color("shadow")
		for i = 1, dist do
			GUI.roundrect(x + i, y + i, w, h, 8, 1, 1)
		end
	end
	
	-- Draw the button
	GUI.color("elm_frame")
	GUI.roundrect(x + 2 * state, y + 2 * state, w, h, 8, 1, 1)
	
	
	-- Draw the caption
	GUI.color("txt")
	GUI.font(4)	
	
	local str_w, str_h = gfx.measurestr(self.caption)
	gfx.x = x + 2 * state + ((w - str_w) / 2)-- - 2
	gfx.y = y + 2 * state + ((h - str_h) / 2)-- - 2
	gfx.drawstr(self.caption)
	
end


-- Button - Mouse down.
function GUI.Button:onmousedown()
	
	self.state = 1
	
end


-- Button - Mouse up.
function GUI.Button:onmouseup() 
	
	self.state = 0
	
	-- If the mouse was released on the button, run func
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		
		self.func(table.unpack(self.params))
		
	end

end


-- Button - Right mouse up
function GUI.Button:onmouser_up()

	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) and self.r_func then
	
		self.r_func(table.unpack(self.r_params))

	end
end

-- Button - Unused methods.
function GUI.Button:val() end
function GUI.Button:onwheel() end
function GUI.Button:ondoubleclick() end
function GUI.Button:ondrag() end
function GUI.Button:ontype() end
function GUI.Button:onmouser_down() end
function GUI.Button:onr_doubleclick() end
function GUI.Button:onr_drag() end
function GUI.Button:onmouseover() end


--[[	Textbox class. Adapted from schwa's example code.
	
	---- User parameters ----
x, y, w, h		Coordinates of tep-left corner, width, height
pad				Padding between the left side and first character.

	
]]--

-- Textbox - New
GUI.Textbox = {}
function GUI.Textbox:new(x, y, w, h, caption, pad)
	
	local txt = {}
	txt.type = "Textbox"
	
	txt.x, txt.y, txt.w, txt.h = x, y, w, h

	txt.caption = caption
	txt.pad = pad
	
	txt.caret = 0
	txt.sel = 0
	txt.blink = 0
	txt.retval = ""
	txt.focus = false
	
	setmetatable(txt, self)
	self.__index = self
	return txt

end


-- Textbox - Draw.
function GUI.Textbox:draw()
	
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
	local caption = self.caption
	local caret = self.caret
	local sel = self.sel
	local text = self.retval
	local focus = self.focus
	local pad = self.pad
	
	-- Draw the caption
	GUI.font(3)
	local str_w, str_h = gfx.measurestr(caption)
	gfx.x = x
	gfx.y = y - str_h - pad
	GUI.shadow(caption, "txt", "shadow")
	
	-- Draw the textbox frame, and make it brighter if focused.
	
	GUI.color("elm_bg")
	gfx.rect(x, y, w, h, 1)
	
	if focus then 
				
		GUI.color("elm_fill")
		gfx.rect(x + 1, y + 1, w - 2, h - 2, 0)
		
	else
	
		GUI.color("elm_frame")
	end

	gfx.rect(x, y, w, h, 0)

	-- Draw the text
	GUI.color("txt")
	GUI.font(4)
	str_w, str_h = gfx.measurestr(text)
	gfx.x = x + pad
	gfx.y = y + (h - str_h) / 2
	gfx.drawstr(text)
	
	-- Is any text selected?
	if sel ~= 0 then
	
		-- Use the caret and selection positions to figure out the dimensions
		local sel_start, sel_end = caret, caret + sel
		if sel_start > sel_end then sel_start, sel_end = sel_end, sel_start end
		local x_start = gfx.measurestr(string.sub(text, 0, sel_start))
		
		
		local w_sel = gfx.measurestr(string.sub(text, sel_start + 1, sel_end))
		
		
		-- Draw the selection highlight
		GUI.color("txt")
		gfx.rect(x + x_start + pad, y + 4, w_sel, h - 8, 1)
		
		-- Draw the selected text
		GUI.color("wnd_bg")
		gfx.x, gfx.y = x + x_start + pad, y + (h - str_h) / 2
		gfx.drawstr(string.sub(text, sel_start + 1, sel_end))
		
	end
	
	-- If the box is focused, draw the caret...
	if focus then
		
		-- ...but only for half of the blink cycle
		if self.blink < 8 then
			
			local caret_x = x + pad + gfx.measurestr(string.sub(text, 0, caret))

			GUI.color("elm_frame")
			gfx.line(caret_x, y + 4, caret_x, y + h - 8)
			
		end
		
		-- Increment the blink cycle
		self.blink = (self.blink + 1) % 16
		
	end
	
end


-- Textbox - Get/set value
function GUI.Textbox:val(newval)
	
	if newval then
		self.retval = newval
	else
		return self.retval
	end
end


-- Textbox - Get the closest character position to the mouse.
function GUI.Textbox:getcaret()
	
	local len = string.len(self.retval)
	GUI.font(3)
	
	for i = 1, len do
		
		w = gfx.measurestr(string.sub(self.retval, 1, i))
		if GUI.mouse.x < (self.x + self.pad + w) then return i - 1 end
	
	end
	
	return len

end


-- Textbox - Mouse down.
function GUI.Textbox:onmousedown()
	
	local x, y = GUI.mouse.x, GUI.mouse.y
	
	-- Was the mouse clicked inside this element?
	self.focus = GUI.IsInside(self, x, y)
	if self.focus then
		
		-- Place the caret on the nearest character and reset the blink cycle
		self.caret = self:getcaret()
		self.cursstate = 0
		self.sel = 0
		self.caret = self:getcaret()

	end
	
end


-- Textbox - Double-click.
function GUI.Textbox:ondoubleclick()
	
	local len = string.len(self.retval)
	self.caret, self.sel = len, -len

end


-- Textbox - Mouse drag.
function GUI.Textbox:ondrag()
	
	self.sel = self:getcaret() - self.caret
	
end


-- Textbox - Typing.
function GUI.Textbox:ontype(char)

	GUI.font(3)
	
	local caret = self.caret
	local text = self.retval
	local maxlen = gfx.measurestr(text) >= (self.w - (self.pad * 3))
	

	-- Is there text selected?
	if self.sel ~= 0 then
		
		-- Delete the selected text
		local sel_start, sel_end = caret, caret + self.sel
		if sel_start > sel_end then sel_start, sel_end = sel_end, sel_start end
		
		text = string.sub(text, 0, sel_start)..string.sub(text, sel_end + 1)
		
	end
		

	if char		== GUI.chars.LEFT then
		if caret > 0 then self.caret = caret - 1 end

	elseif char	== GUI.chars.RIGHT then
		if caret < string.len(text) then self.caret = caret + 1 end
	
	elseif char == GUI.chars.BACKSPACE then
		if string.len(text) > 0 and self.sel == 0 then
			text = string.sub(text, 1, caret - 1)..(string.sub(text, caret + 1))
			self.caret = caret - 1
		end
		
	elseif char == GUI.chars.DELETE then
		if string.len(text) > 0 and self.sel == 0 then
			text = string.sub(text, 1, caret)..(string.sub(text, caret + 2))
		end
		
	elseif char == GUI.chars.RETURN then
		self.focus = false
		
	elseif char == GUI.chars.HOME then
		self.caret = 0
		
	elseif char == GUI.chars.END then
		self.caret = string.len(text)		
	
	-- Any other valid character, as long as we haven't filled up the textbox
	elseif char >= 32 and char <= 125 and maxlen == false then

		-- Insert the typed character at the caret position
		text = string.format("%s%c%s", string.sub(text, 1, caret), char, string.sub(text, caret + 1))
		self.caret = self.caret + 1
		
	end
	
	self.retval = text
	self.sel = 0
	
end


-- Textbox - Unused methods.
function GUI.Textbox:onwheel() end
function GUI.Textbox:onmouseup() end
function GUI.Textbox:onmouser_down() end
function GUI.Textbox:onmouser_up() end
function GUI.Textbox:onr_doubleclick() end
function GUI.Textbox:onr_drag() end
function GUI.Textbox:onmouseover() end



--[[	MenuBox class
	
	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and each option
	
]]--
GUI.Menubox = {}
function GUI.Menubox:new(x, y, w, h, caption, opts, pad)
	
	local menu = {}
	menu.type = "Menubox"
	
	menu.x, menu.y, menu.w, menu.h = x, y, w, h

	menu.caption = caption
	
	menu.pad = pad
	
	-- Parse the string of options into a table
	menu.optarray = {}
	local tempidx = 1

	for word in string.gmatch(opts, '([^,]+)') do
		menu.optarray[tempidx] = word
		tempidx = tempidx + 1
	end
	
	menu.retval = 1
	menu.numopts = tempidx - 1
	
	setmetatable(menu, self)
    self.__index = self 
    return menu
	
end


-- Menubox - Draw
function GUI.Menubox:draw()	
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
	local caption = self.caption
	local text = self.optarray[self.retval]

	local focus = self.focus
	

	-- Draw the caption
	GUI.font(3)
	local str_w, str_h = gfx.measurestr(caption)
	gfx.x = x - str_w - self.pad
	gfx.y = y + (h - str_h) / 2
	GUI.shadow(caption, "txt", "shadow")
	
	
	-- Draw the frame background
	GUI.color("elm_bg")
	gfx.rect(x, y, w, h, 1)
	
	
	-- Draw the frame, and make it brighter if focused.
	if focus then 
				
		GUI.color("elm_fill")
		gfx.rect(x + 1, y + 1, w - 2, h - 2, 0)
		
	else
	
		GUI.color("elm_frame")
	end

	gfx.rect(x, y, w, h, 0)

	-- Draw the dropdown indicator
	gfx.rect(x + w - h, y, h, h, 1)
	GUI.color("elm_bg")
	
	-- Triangle size
	local r = 6
	local rh = 2 * r / 5
	
	local ox = (x + w - h) + h / 2
	local oy = y + h / 2 - (r / 2)

	local Ax, Ay = GUI.polar2cart(1/2, r, ox, oy)
	local Bx, By = GUI.polar2cart(0, r, ox, oy)
	local Cx, Cy = GUI.polar2cart(1, r, ox, oy)
	
	GUI.triangle(1, Ax, Ay, Bx, By, Cx, Cy)


	-- Draw the text
	GUI.font(4)
	GUI.color("txt")

	str_w, str_h = gfx.measurestr(text)
	gfx.x = x + self.pad
	gfx.y = y + (h - str_h) / 2
	gfx.drawstr(text)
	
end


-- Menubox - Get/set value
function GUI.Menubox:val(newval)
	
	if newval then
		self.retval = newval
	else
		return self.retval
	end
	
end


-- Menubox - Mouse up
function GUI.Menubox:onmouseup()
	
	local menu_str = ""
	
	for i = 1, self.numopts do
		if i == self.curopt then menu_str = menu_str .. "!" end
		menu_str = menu_str .. self.optarray[i] .. "|"
	end
	
	--gfx.x = self.x
	--gfx.y = self.y + self.h
	gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y
	
	local curopt = gfx.showmenu(menu_str)
	if curopt ~= 0 then self.retval = curopt end
	self.focus = false
end


-- Menubox - Mousewheel
function GUI.Menubox:onwheel(inc)
	
	local curopt = self.retval - inc
	
	if curopt < 1 then curopt = 1 end
	if curopt > self.numopts then curopt = self.numopts end
	
	self.retval = curopt
	
end


function GUI.Menubox:onmousedown() end
function GUI.Menubox:ondrag() end
function GUI.Menubox:ondoubleclick() end
function GUI.Menubox:ontype() end
function GUI.Menubox:onmouser_down() end
function GUI.Menubox:onmouser_up() end
function GUI.Menubox:onr_doubleclick() end
function GUI.Menubox:onr_drag() end
function GUI.Menubox:onmouseover() end


--[[	Frame class
	
	
]]--
GUI.Frame = {}
function GUI.Frame:new(x, y, w, h, shadow, fill, color, round)
	
	local Frame = {}
	Frame.type = "Frame"
	
	Frame.x, Frame.y, Frame.w, Frame.h = x, y, w, h
	
	Frame.shadow = shadow
	Frame.fill = fill or false
	Frame.color = color or "elm_frame"
	Frame.round = round or 0
	Frame.thick = thick or 0
	
	
	setmetatable(Frame, self)
	self.__index = self
	return Frame
	
end

function GUI.Frame:draw()
	
	if self.color == "none" then return 0 end
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	local dist = GUI.shadow_dist
	local fill = self.fill
	local round = self.round
	local shadow = self.shadow
	
	--GUI.roundrect = function (x, y, w, h, r, antialias, fill)
	
	if shadow then
		GUI.color("shadow")
		for i = 1, dist do
			if round > 0 then
				GUI.roundrect(x + i, y + i, w, h, round, 1, fill)
			else
				gfx.rect(x + i, y + i, w, h, fill)
			end
		end
	end
	
	
	GUI.color(self.color)
	if round > 0 then
		GUI.roundrect(x, y, w, h, round, 1, fill)
	else
		gfx.rect(x, y, w, h, fill)
	end

end
	
	
function GUI.Frame:val() end
function GUI.Frame:onmousedown() end
function GUI.Frame:onmouseup() end
function GUI.Frame:ondoubleclick() end
function GUI.Frame:ondrag() end
function GUI.Frame:onwheel() end
function GUI.Frame:ontype() end
function GUI.Frame:onmouser_down() end
function GUI.Frame:onmouser_up() end
function GUI.Frame:onr_doubleclick() end
function GUI.Frame:onr_drag() end
function GUI.Frame:onmouseover() end



-- ****NOT YET IMPLEMENTED****
--[[	Tabframe class
	
]]--
GUI.Tabframe = {}
function GUI.Tabframe:new(x, y, w, h, tabs) 
	
	local tab = {}
	tab.type = "Tabframe"
	
	tab.x, tab.y, tab.w, tab.h = x, y, w, h
	
	-- Parse the string of options into a table
	tab.optarray = {}
	local tempidx = 1

	for word in string.gmatch(tabs, '([^,]+)') do
		tab.optarray[tempidx] = word
		tempidx = tempidx + 1
	end
	
	tab.retval = 1
	tab.numopts = tempidx - 1
	
	for i = 1, tab.numopts do
		tab[i] = {}
	end
	
end


function GUI.Tabframe:draw() 
	
	-- Determine current tab
	-- Set all of current tab's elements to elm.visible = true,
	-- all other elements to elm.visible = false
	
	
	-- Draw tabs, highlighting current one
	
	
	-- Draw frame
	
	
	-- Draw the current tab's elements
	for elm, __ in pairs(self[self.retval]) do
		
		elm:draw()
		
	end
	
	
end


function GUI.Tabframe:val() end
function GUI.Tabframe:onmousedown() end
function GUI.Tabframe:onmouseup() end
function GUI.Tabframe:ondoubleclick() end
function GUI.Tabframe:ondrag() end
function GUI.Tabframe:onwheel() end
function GUI.Tabframe:ontype() end
function GUI.Tabframe:onmouser_down() end
function GUI.Tabframe:onmouser_up() end
function GUI.Tabframe:onr_doubleclick() end
function GUI.Tabframe:onr_drag() end
function GUI.Tabframe:onmouseover() end


-- Make our table full of functions available to the parent script
return GUI

end
GUI = GUI_table()

----------------------------------------------------------------
----------------------------To here-----------------------------
----------------------------------------------------------------



---- General settings, declaring variables ----

GUI.name = "Lokasenna's Chord Helper"
GUI.x, GUI.y, GUI.w, GUI.h = -48, 0, 800, 600
GUI.anchor, GUI.corner = "mouse", "T"

GUI.fonts[1] = {"Calibri", 32}
GUI.fonts[2] = {"Calibri", 20}
GUI.fonts[3] = {"Calibri", 16}
GUI.fonts[4] = {"Calibri", 16}

-- For track monitoring warning
GUI.fonts[5] = {"Calibri", 16, "bi"}

-- For the reascale label
GUI.fonts[6] = {"Calibri", 18, "b"}



local root_arr = {[0] = "C","C#/Db","D","D#/Eb","E","F","F#/Gb","G","G#/Ab","A","A#/Bb","B"}
local notes_str = "5,4,3,2"
local oct_str = "9,8,7,6,5,4,3,2,1,0"
local inv_str = "2,1,0"
local chords_str = "Diads,Basic Triads,More"
local chords_arr = {
	{
		-- Diads
		A_min2 =	{0, 1},
		B_maj2 =	{0, 2},
		C_min3 =	{0, 3},
		D_maj3 =	{0, 4},
		E_P4 =		{0, 5},
		F_dim5 =	{0, 6},
		G_P5 =		{0, 7},
		H_min6 =	{0, 8},
		I_maj6 =	{0, 9},
		J_min7 =	{0, 10},
		K_maj7 =	{0, 11},
		L_oct =		{0, 12},
	},
	{
		-- Basic Triads
		A_maj =		{0, 4, 7},
		B_min =		{0, 3, 7},
		C_dim =		{0, 3, 6},
	},
	{
		-- More
		A_maj = 	{0, 4, 7},
		B_maj7 = 	{0, 4, 7, 11},
		C_min =		{0, 3, 7},
		D_min7 =	{0, 3, 7, 10},
		E__7 =		{0, 4, 7, 10},		
		F_dim =		{0, 3, 6},
		G_dim7 =	{0, 3, 6, 9},		
		H_aug = 	{0, 4, 8},		
		I_sus2 =	{0, 2, 7},
		J_sus4 =	{0, 5, 7},		
		K_sus9 =	{0, 7, 14},
		L_add9 = 	{0, 4, 7, 14},
	},
}
		
-- We'll store the current scale's chords here		
local chords_legal = {}

-- Timestamps for turning notes on and off
local notes_pending = {}
local notes_timing = {}

local cur_wnd = reaper.MIDIEditor_GetActive()
if not cur_wnd then
	reaper.ShowMessageBox( "This script needs an active MIDI editor.", "No MIDI editor found", 0)
	return 0
end
local cur_take = reaper.MIDIEditor_GetTake(cur_wnd)
local snap = reaper.MIDIEditor_GetSetting_int(cur_wnd, "snap_enabled")

-- Variables for all of our chord/scale shit
local key = 0
local key_num = 0
local scale_num = 1
local scale = ""
local scale_size = 0
local scale_name = ""
local scale_arr = {}
local chord_set = 1

-- Global value for the divider line so everything else can reference from it
local line_x = 200

-- Base values for the button array
local btn_template = {line_x + 16, 96, 48, 20}
local btn_space_h = 8
local btn_space_v = 6

-- Highlight for last-clicked chords
local high_template = {false, false, "elm_fill", 11}

-- An excessive number of variables just for displaying tooltips on the buttons
local ini_file = reaper.get_ini_file()
local __, tooltip_delay = reaper.BR_Win32_GetPrivateProfileString("reaper", "tooltipdelay", "200", ini_file)
tooltip_delay = tonumber(tooltip_delay) / 1000
local tooltip_time = 0
local tooltip_active = false
local tooltip_btn = nil
--local tooltip_x, tooltip_y = 0, 0

-- Number of buttons in the longest row, for adjusting lbl_clickplay
local most_chords = 0

-- Instruction string below the chord array
local clickplay_str = 
[[Click to preview a chord using the editor's note settings.
Shift-click to insert a chord using the editor's note settings.
                     (no arpeggios yet)
Double-click any empty space to reset the chord highlights.]]



--"Click to preview, shift + click to insert using current grid settings.\nDouble-click any empty space to clear the chord highlights."


-- MIDI defaults
local chan = 0
local vel = 0

-- Are we snapping to the MIDI editor?
local synced = false

local reascale_arr = {{["pre"] = 0, ["name"] = "-no scale-", ["scale"] = 0}}
local mnu_scale_arr = {[0] = 0, 0, 0}


-- Browse for a new .reascale, parse it, and save it
local function get_reascale(startup)

	local file_path = ""

	-- Get a file to work with
	if startup then
		file_path = reaper.GetExtState(GUI.name, "current reascale") or ""
	else
		__, file_path = reaper.GetUserFileNameForRead("", "Choose a .reascale file", ".reascale")
		reaper.SetExtState(GUI.name, "current reascale", file_path, 1)
	end
	
	file = io.open(file_path) or nil
	
	if file then
		
		-- For our label, trim the path down to just a file name
		local slash_index = string.find(file_path, "[/\\][^/\\]*$")
		local file_name = string.sub(file_path, slash_index + 1)
		GUI.Val("lbl_reascale", file_name)
		
		reascale_arr = {}
		
		local i = 1
				
		for line in file:lines() do
		
			local line_pre, line_name, line_scale = ""
			
			-- We don't care about commented lines
			if line:sub(1, 1) ~= "#" then
			
				line_pre = line:match("^(-?%d+)") or ""
				line_name = line:match("\"(.+)\"") or ""
				line_scale = line:match("%d*$") or ""
			
				if line_pre ~= "" then
					reascale_arr[i] = {["pre"] = tonumber(line_pre), ["name"] = line_name, ["scale"] = line_scale}
					i = i + 1
				end
			end	
		end
		
		-- Convert the array into gfx.showmenu's format
		mnu_scale_arr = {}
		local menu_val = GUI.Val("mnu_scale")
		local menu_str = ""
		local temp_scale_arr = {}

		for i = 1, #reascale_arr do
			
			local pre = reascale_arr[i].pre
		
			if 		pre == 0 or pre == 1 then 
				mnu_scale_arr[i] = reascale_arr[i].name
				table.insert(temp_scale_arr, reascale_arr[i])
			elseif 	pre == 2 or pre == 3 then 
				mnu_scale_arr[i] = ">"..reascale_arr[i].name
			elseif	pre == -1 then 	
				mnu_scale_arr[i] = ""
			elseif	pre == -2 then			
				mnu_scale_arr[i-1] = "<"..mnu_scale_arr[i-1]
				mnu_scale_arr[i] = ""
			end		
		end
		
		-- Rewrite the scale array with folders and spacers filtered out
		reascale_arr = temp_scale_arr

		GUI.elms.mnu_scale.optarray = mnu_scale_arr
		GUI.elms.mnu_scale.numopts = #mnu_scale_arr
		
		-- Was the script just loaded? Check for saved values.
		if startup then
			scale_num = tonumber(reaper.GetExtState(GUI.name, "current scale")) or 1
			key_num = tonumber(reaper.GetExtState(GUI.name, "current key")) or 1
		else
			scale_num = 1
			key_num = 0
		end
	end	
end


-- Play the current scale as an arpeggio, up or down depending on dir
local function play_scale(dir)
	
	if dir ~= 1 and dir ~= -1 then return 0 end
	
	-- Get note offset for key and octave
	local offset = ( (GUI.elms.mnu_octave.numopts - GUI.Val("mnu_octave") + 1) * 12) + key	
	
	chan = reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_chan")
	vel = reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_vel") 	

	-- Get note length ***IN QN***
	local grid_len, __, note_len = reaper.MIDI_GetGrid(cur_take)
	local len_QN = (note_len ~= 0) and note_len or grid_len

	local QN_length = 60 / reaper.Master_GetTempo()	
	
	local scale_arr = {table.unpack(scale_arr, 1, (scale_size + 1))}
	
	local arp_start = 0
	
	
	-- Ascending scale
	if dir == 1 then
		arp_start = 1

	-- Descending scale
	else
		arp_start = scale_size + 1
	end
	
	for key, note in pairs(scale_arr) do
		
		note = offset + note
		
		local time_adj = (arp_start - 1 ) * len_QN * QN_length
		--GUI.Msg("arp = "..arp.." | "..note.." | "..arp_start.." | "..time_adj)
				
		notes_pending[note] = {reaper.time_precise() + time_adj, (len_QN * QN_length)}
		--GUI.Msg("pending note "..note.." @ "..(reaper.time_precise() + time_adj))
		
		arp_start = arp_start + dir
		
	end
	
	
end


-- Clear all current and pending notes
local function notes_off()
	notes_pending = {}
	reaper.Main_OnCommand(40345, 0)
end


--[[	Classes and parameters
	(see comments in LS GUI.lua for more thorough documentation)
	
	Frame		x y w h[shadow		fill	color	round]
	Label		x y		caption		shadow	font
	Button		x y w h caption		func	...
	Radio		x y w h caption 	opts	pad
	Checklist	x y w h caption 	opts	pad
	Knob		x y w	caption 	min 	max		steps	default		ticks
	Slider		x y w	caption 	min 	max 	steps 	default
	Range		x y w	caption		min		max		steps 	default_a 	default_b
	Textbox		x y w h	caption		pad
	Menubox		x y w h caption		opts	pad
	
	Example:
	
	GUI.elms = {
	
	my_textbox	= GUI.Textbox:new(	340, 210, 200, 30, "Favorite book:", 4),
										(make sure you include the comma) ^^^
	
	}
	
	
]]--
GUI.elms_bg = { bg = GUI.Frame:new(			0, 0, GUI.w, GUI.h, false, false, "none", 0) }
GUI.elms_bottom = {
	frm_tooltip = GUI.Frame:new(		line_x, 46, 2000, 24, false, true, "elm_bg", 0),
}
GUI.elms = {
	div = GUI.Frame:new(				line_x, 0, 4, 2000, true, true),		
	lbl_key = GUI.Label:new(			line_x + 24, 6, "C", 0, 1),
	lbl_scale = GUI.Label:new(			line_x + 48, 6, "blah", 0, 1),
	lbl_reascale = GUI.Label:new(		8, 12, "( no .reascale loaded )", 0, 6),
	lbl_clickplay = GUI.Label:new(		line_x + 200, 500, clickplay_str, 0, 4),
	mnu_key = GUI.Menubox:new(			0, -24, 0, 0, "", "C,C#/Db,D,D#/Eb,E,F,F#/Gb,G,G#/Ab,A,A#/Bb,B", 0),
	mnu_scale = GUI.Menubox:new(		0, -24, 0, 0, "", "-no scale-", 0),
	--mnu_num_notes = GUI.Menubox:new(	84, 48, 128, 20, "Notes", notes_str, 4),
	--mnu_inversion =	GUI.Menubox:new(	88, 220, 100, 20, "Inversion", inv_str, 4),
	mnu_octave =	GUI.Menubox:new(	88, 122, 100, 20, "Octave:", oct_str, 4),
	mnu_chords =	GUI.Menubox:new(	88, 96, 100, 20, "Chord Set:", chords_str, 4),
	chk_follow =	GUI.Checklist:new(	8, 48, 130, 20, "", "Sync w/ editor", 0),
	mnu_chord_arp =	GUI.Menubox:new(   	88, 148, 100, 20, "Arpeggio:","None,Ascending,Descending", 4),
	lbl_play_scale = GUI.Label:new(		44, 200, "Play current scale:", 1, 3),
	btn_play_up = GUI.Button:new(		102, 226, 84, 20, "Ascending", play_scale, 1),
	btn_play_dn = GUI.Button:new(		10, 226, 84, 20, "Descending", play_scale, -1),
	btn_notes_off = GUI.Button:new(		54, 252, 88, 20, "All notes off", notes_off),

}
GUI.elms_top = {}

--GUI.Val("mnu_num_notes", 3)
--GUI.Val("mnu_inversion", 3)
GUI.Val("mnu_octave", 6)
GUI.Val("mnu_chords", 3)


-- Clear all chord highlights
function GUI.elms_bg.bg:ondoubleclick()
	for key, val in pairs(GUI.elms_bottom) do
		if string.find(key, "high_") then
			GUI.elms_bottom[key] = nil
		end
	end	
end


-- Redirecting label clicks to a hidden dropdown
-- (A lazy way of giving the label more functionality)

function GUI.elms.lbl_key:onmouseup() 
	
	if GUI.Val("chk_follow")[1] == true and keysnap == 1 then return end
		
	GUI.elms.mnu_key:onmouseup()
	
	-- Array indexes don't like being given a decimal value	
	key_num = math.floor(GUI.elms.mnu_key.retval) - 1

end

function GUI.elms.lbl_scale:onmouseup()
	
	if GUI.Val("chk_follow")[1] == true and keysnap == 1 then return end

	GUI.elms.mnu_scale:onmouseup()
	
	-- Array indexes don't like being given a decimal value
	scale_num = math.floor(GUI.elms.mnu_scale.retval)

end

function GUI.elms.lbl_reascale:onmouseup()
	get_reascale()
end


-- On click, play/insert the chord's notes
local function btn_click(deg, chord, btn) 
	
	-- If Shift+click then insert notes
	-- If normal click then play notes

	local btn = GUI.elms[btn]
	local high = {table.unpack(high_template)}
	local high_name = "high_"..deg

	-- Update this column's last-clicked chord highlight
	GUI.elms_bottom[high_name] = GUI.Frame:new(btn.x - 3, btn.y - 3, btn.w + 6, btn.h + 6, high[1], high[2], high[3], high[4])

	
	-- Get cursor position
	local cursor_pos = reaper.GetCursorPosition()
	local cursor_ppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, cursor_pos)
	local cursor_QN = reaper.MIDI_GetProjQNFromPPQPos(cur_take, cursor_ppq)

	-- Get note length ***IN QN***
	local grid_len, __, note_len = reaper.MIDI_GetGrid(cur_take)
	local len_QN = (note_len ~= 0) and note_len or grid_len
	
	local end_ppq = reaper.MIDI_GetPPQPosFromProjQN(cur_take, cursor_QN + len_QN)
	
	-- Get note offset for key and octave
	local offset = ( (GUI.elms.mnu_octave.numopts - GUI.Val("mnu_octave") + 1) * 12) + key
	chan = reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_chan")
	vel = reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_vel") 
	
	local shift = GUI.mouse.cap&8==8
	local QN_length = 60 / reaper.Master_GetTempo()	
	
	local arp = GUI.Val("mnu_chord_arp")
	local num_notes = #chords_legal[deg][chord]
	
	local arp_start, arp_dir = 0, 0
	
	-- Ascending arpeggio
	if arp == 2 then
		arp_start = 0
		arp_dir = 1
	-- Descending arpeggio
	elseif arp == 3 then
		arp_start = num_notes - 1
		arp_dir = -1
	end
	
	-- Insert notes, send Note Ons, and store the current time
	if shift then reaper.MIDI_SelectAll(cur_take, 0) end
	for name, note in pairs(chords_legal[deg][chord]) do

		note = offset + scale_arr[deg] + note
		
		if shift then
			reaper.MIDI_InsertNote(cur_take, 1, 0, cursor_ppq, end_ppq, chan, note, vel, 1)
		end
		
		local time_adj = arp_start * len_QN * QN_length
		arp_start = arp_start + arp_dir
		--GUI.Msg("arp = "..arp.." | "..note.." | "..arp_start.." | "..time_adj)
				
		notes_pending[note] = {reaper.time_precise() + time_adj, (len_QN * QN_length)}
		
	end
	
	reaper.MIDI_Sort(cur_take)
	if shift then reaper.ApplyNudge(0, 0, 6, 15, len_QN / 4, 0, 0) end
	
end


function GUI.Button:onmouseover()

	if self.tooltip and not tooltip_btn then 
		tooltip_btn = self
		--tooltip_time = reaper.time_precise()
	end
end


-- Create/update button array
local function update_buttons()
	
	-- Reset the column height
	most_chords = 0

	if GUI.elms.lbl_no_chords then GUI.elms.lbl_no_chords = nil end

	-- Strip old buttons and column labels from array, create new buttons
	for key, value in pairs(GUI.elms) do
		if string.find(key, "btn_chords") or string.find(key, "lbl_chords") then
			GUI.elms[key] = nil
		end
	end
	
	-- Create new buttons
	local x, y, w, h, func = table.unpack(btn_template)
	
	for i = 1, scale_size do
		
		local x_offset = (w + btn_space_h) * (i - 1)
	
		-- Create a label for the column
		GUI.font(2)

		local lbl_caption = root_arr[(scale_arr[i] + key) % 12]
		local lbl_w, lbl_h = gfx.measurestr(lbl_caption)
		local lbl_x = x + x_offset + ((w - lbl_w) / 2)				
		
		GUI.elms["lbl_chords_"..i] = GUI.Label:new(lbl_x, y - lbl_h - 4, lbl_caption, 1, 2)
		
		local row = 1
		local num_chords = 0
		
		for name, __ in GUI.kpairs(chords_legal[i]) do
			
			local caption = string.match(name, "%u_+(.+)")
			
			local y_offset = (h + btn_space_v) * (row - 1)
			row = row + 1
			
			local btn_name = "btn_chords_"..i.."_"..name
			
			GUI.elms[btn_name] = GUI.Button:new(x + x_offset, y + y_offset, w, h, caption, btn_click, i, name, btn_name)
			
			
			-- Write out a tooltip for this button - the chord, its recipe, and its notes
			local tip_str = (root_arr[(scale_arr[i] + key) % 12]).." "..caption..": "
			local tip_str2 = "|"
			local note_str = ""
			
			for name, note in ipairs(chords_legal[i][name]) do
				note_str = note
				if note == 0 then
					note_str = "R"
				elseif note > 11 then
					note_str = "^"..(note - 12)
				end
				tip_str = tip_str..note_str.." "
				tip_str2 = tip_str2.." "..(root_arr[(key + note + scale_arr[i]) % 12])
			end
			
			GUI.elms[btn_name].tooltip = tip_str..tip_str2


			num_chords = num_chords + 1
			
		end
		
		most_chords = math.max(num_chords,most_chords)

	end

	if most_chords == 0 then
		GUI.elms.lbl_no_chords = GUI.Label:new(line_x + 48, 150, " -- no legal chords -- ", 0, 3)
	end	
	
end


-- (CURRENTLY UNUSED)
-- Update the inversion list if necessary
local function update_inversions()
	
	local temp_array = {}
		
	for i = scale_size - 1, 1, -1 do
		table.insert(temp_array, GUI.ordinal(i))
	end
	
	table.insert(temp_array, "Root")
	
	cur_sel = GUI.elms.mnu_inversion.numopts - GUI.Val("mnu_inversion")
	
	if cur_sel >= scale_size then cur_sel = scale_size - 1 end
	
	GUI.elms.mnu_inversion.numopts = scale_size
	GUI.elms.mnu_inversion.optarray = temp_array
	

	GUI.Val("mnu_inversion", scale_size - cur_sel)
end



-- Let the user know if we're unable to preview notes
local function check_track_armed()
	
	local cur_track = reaper.GetMediaItemTake_Track(cur_take)
	local input = reaper.GetMediaTrackInfo_Value(cur_track, "I_RECINPUT")
	local arm = reaper.GetMediaTrackInfo_Value(cur_track, "I_RECARM")
	local monitor = reaper.GetMediaTrackInfo_Value(cur_track, "I_RECMON")
	
	local track_armed = input >= 6080 and input <= 6096 and arm == 1 and monitor > 0
	
	if not track_armed then

		GUI.font(5)
		local str1 = "Unable to preview notes: Track must be armed, monitoring,"
		local str2 = "and set to receive input from the Virtual MIDI Keyboard."
				
		local str_w, str_h = gfx.measurestr(str1)
		
		GUI.color("elm_bg")
		
		local rect_y = GUI.cur_h - 26 - (2 * str_h) - 2
		local rect_h = 2 * str_h + 4
		
		gfx.rect(line_x, rect_y, GUI.cur_w - line_x, rect_h)

		GUI.color("red")
		gfx.x = (GUI.cur_w - str_w - line_x) / 2 + line_x
		gfx.y = GUI.cur_h - 26 - (2 * str_h)
		gfx.drawstr(str1)
		
		str_w, __ = gfx.measurestr(str2)
		gfx.x = (GUI.cur_w - str_w - line_x) / 2 + line_x
		gfx.y = gfx.y + str_h
		gfx.drawstr(str2)
		
		-- Set the color back so none of the other elements' text is written in red
		GUI.color("txt")
		
	end
	
end


local function Main()
	
	
	-- See if the MIDI editor is open
	if not reaper.MIDIEditor_GetActive() then
		GUI.quit = true
		reaper.Main_OnCommand(40345, 0)
		return 0
	end
		
	check_track_armed()
		
	-- Check if any pending notes are ready
	local time = reaper.time_precise()
	for note, stamp in pairs(notes_pending) do
		if time >= stamp[1] then
			--GUI.Msg(note.." is ready.  -  "..stamp[1].."  "..(time + stamp[2]))
			
			reaper.StuffMIDIMessage(0, 0x90 + chan, note, vel)
			notes_timing[note] = time + stamp[2]	
			notes_pending[note] = nil
			
		end
	end
		
	-- Check if any active notes are finished
	for note, stamp in pairs(notes_timing) do
		if time >= stamp then
			reaper.StuffMIDIMessage(0, 0x80 + chan, note, vel)
			notes_timing[note] = nil
		
		end
	end
	
--[[
	-- See if the user pressed a shortcut key
	local char = GUI.char
	if char ~= 0 then
		
		-- X --> All notes off
		if char == string.byte("x") then 
			
			notes_pending = {}
			reaper.Main_OnCommand(40345, 0)
		end
		
	end
]]--

	-- Button array tooltips
	if tooltip_btn then
		if GUI.IsInside(tooltip_btn, GUI.mouse.x, GUI.mouse.y) then
			--[[
			if time >= (tooltip_time + 0.200) and tooltip_active == false then
				local _, x, y, _, _ = gfx.dock(-1,0,0,0,0)
				-- Tooltip at the button
				--x, y = x + tooltip_btn.x + tooltip_btn.w, y + tooltip_btn.y + tooltip_btn.h
				-- Tooltip at top-right
				x, y = x + GUI.cur_w - 150, y + GUI.title_height
				reaper.TrackCtl_SetToolTip(tooltip_btn.tooltip, x, y, true)
				tooltip_active = true
			end
			]]--
			GUI.font(4)
			local str_w, __ = gfx.measurestr(tooltip_btn.tooltip)
			local new_x = (GUI.cur_w - str_w - line_x) / 2 + line_x
			GUI.elms.tooltip = GUI.Label:new(new_x, 50, tooltip_btn.tooltip, 0, 4)

			
		else

			--reaper.TrackCtl_SetToolTip("", 0, 0, false)
			GUI.elms.tooltip = nil
			tooltip_active = false
			tooltip_time = 0
			tooltip_btn = nil
		end
	end
	
	
	-- See if the key, scale, or chord set have changed
	local cur_key, cur_name, cur_scale, cur_chords = "", "", "", GUI.Val("mnu_chords")
	
	keysnap = reaper.MIDIEditor_GetSetting_int(cur_wnd, "scale_enabled")
	local cur_synced = (GUI.Val("chk_follow")[1] == true and keysnap == 1)
	
	if cur_synced then
		__, cur_key, __, cur_name = reaper.MIDI_GetScale(cur_take, 0, 0, "")
		__, cur_scale = reaper.MIDIEditor_GetSetting_str(cur_wnd, "scale", "")
	else
		cur_key = key_num
		cur_name = reascale_arr[scale_num].name
		cur_scale = reascale_arr[scale_num].scale
	end
	
	
	-- Update our sync state, and fade out the scale
	-- text if we're synced to the MIDI editor			
	if synced ~= cur_synced then
		synced = cur_synced
		GUI.elms.lbl_key.color = synced and "gray" or "txt"
		GUI.elms.lbl_scale.color = synced and "gray" or "txt"
	end

	
	if key ~= cur_key or scale ~= cur_scale or chords ~= cur_chords then
		
		key = cur_key
		scale = cur_scale
		scale_name = cur_name
		chords = cur_chords
		
		reaper.SetExtState(GUI.name, "current scale", scale_num, 1)
		reaper.SetExtState(GUI.name, "current key", key, 1)
		

		-- Clear last-clicked highlights
		for key, value in pairs(GUI.elms_bottom) do
			if string.find(key, "high_") then
				GUI.elms_bottom[key] = nil
			end
		end
		
	
		-- Update the scale label's caption
		local str = root_arr[key].." "..scale_name
		
		GUI.Val("lbl_key", root_arr[key])
		GUI.Val("lbl_scale", scale_name)
		
		-- Size = number of non-zero values in the scale
		__, scale_size = string.gsub(scale, "[^0]", "")
		
		
		scale_arr = {[0] = 0}
		for i = 1, scale_size do

			scale_arr[i] = string.find(scale, "[^0]", scale_arr[i-1] + 1)
			
			-- Span three octaves so we can still use extended chords on the 7th degree
			scale_arr[i + scale_size] = scale_arr[i] + 12
			scale_arr[i + (2 * scale_size)] = scale_arr[i] + 24
			
		end
	
		
		-- Adjust the values so that root = 0
		for i = 1, #scale_arr do
			scale_arr[i] = scale_arr[i] - 1
		end
		
		
		-- Load the chord set to check against
		local chord_set = chords_arr[chords]
		
		chord_legal = {}
		
		-- Update the list of legal chords
		for i = 1, scale_size do

			-- Each scale degree will have its own subtable
			chords_legal[i] = {}
			
			for name, chord in pairs(chord_set) do

				-- Run each note through the scale array. Really inefficient?
				local exist_count = 0
				for __, note in pairs(chord) do
					
					-- Add the root note for this degree
					note = note + scale_arr[i]
					for j = 0, #scale_arr do
						
						if scale_arr[j] == note then
							exist_count = exist_count + 1
							break
						elseif scale_arr[j] > note then break
						end			
					end		
				end
				
				-- If all of our notes were present, add the chord to the subtable
				if exist_count == #chord then
					chords_legal[i][name] = chord
				end
			end	
		end
		
		update_buttons()
		--update_inversions()
			
		
		-- Update the width of the window to fit our buttons (min 7)
		-- 22px on the right makes the buttons' shadow look balanced, I guess		
		local new_w = ( (btn_template[3] + btn_space_h) * (scale_size >= 7 and scale_size or 7)) + 22 + line_x
		local new_h = btn_template[2] + ( most_chords * (btn_template[4] + btn_space_v) ) + 100
		if new_w ~= GUI.cur_w or new_h ~= GUI.cur_h then
			local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
			gfx.quit()
			gfx.init(GUI.name, new_w, new_h, 0, x, y)
			GUI.cur_w, GUI.cur_h = new_w, new_h
		end

		GUI.resized = true
	end


	-- If the mouse is over the key, scale, or reascale labels,
	-- hightlight it so they can tell it's clickable
	local x, y = GUI.mouse.x, GUI.mouse.y
	if not synced then
		
		GUI.elms.lbl_key.color = "txt"
		GUI.elms.lbl_scale.color = "txt"
		GUI.elms.lbl_reascale.color = "txt"
		
		GUI.elms.lbl_key.shadow = 0
		GUI.elms.lbl_scale.shadow = 0
		GUI.elms.lbl_reascale.shadow = 0
		
		if GUI.IsInside(GUI.elms.lbl_key, x, y) then
			GUI.elms.lbl_key.color = "white"
			GUI.elms.lbl_key.shadow = 1
		elseif GUI.IsInside(GUI.elms.lbl_scale, x, y) then
			GUI.elms.lbl_scale.color = "white"
			GUI.elms.lbl_scale.shadow = 1
		elseif GUI.IsInside(GUI.elms.lbl_reascale, x, y) then
			GUI.elms.lbl_reascale.color = "white"
			GUI.elms.lbl_reascale.shadow = 1
		end
	end
	
	-- See if the window has been resized by the user
	-- Duplicating code from the "scale was changed" structure, there must be a better way
	if GUI.resized then
		
		local min_w = (btn_template[3] + btn_space_h) * 7 + 22 + line_x
		local min_h_a = btn_template[2] + (most_chords * (btn_template[4] + btn_space_v)) + 140
		local min_h_b = GUI.elms.btn_notes_off.y + GUI.elms.btn_notes_off.h + 8
		
		local min_h = math.max(min_h_a, min_h_b)
		
		if GUI.cur_w < min_w or GUI.cur_h < min_h then
			local new_w = math.max(GUI.cur_w, min_w)
			local new_h = math.max(GUI.cur_h, min_h)
			local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
			gfx.quit()
			gfx.init(GUI.name, new_w, new_h, 0, x, y)
		end
		
		GUI.elms_bg.bg.w, GUI.elms_bg.bg.h = gfx.w, gfx.h
		
	
		--[[
		Reset mouse variables
		Without this, the window is reset before the mouse registers as Up,
		so all mouse commands get frozen until the UI is stretched to put
		chk_follow back where it was and the mouse is clicked on it.
		]]--
		GUI.mouse.down = false
		GUI.mouse.ox, GUI.mouse.oy = -1, -1
		GUI.mouse.lx, GUI.mouse.ly = -1, -1
		GUI.mouse.uptime = os.clock()
				

		-- Adjust the scale label to follow the key label's width
		local max_w = GUI.elms.chk_follow.x - 16 - line_x
		local cur_w = 0
		
		GUI.font(GUI.elms.lbl_key.font)
		GUI.elms.lbl_key.w, GUI.elms.lbl_key.h = gfx.measurestr(GUI.Val("lbl_key").." ")	
		GUI.elms.lbl_scale.x = GUI.elms.lbl_key.x + GUI.elms.lbl_key.w
		
		-- Center the instruction and no-chord labels below the buttons
		if GUI.elms.lbl_no_chords then
			local str = GUI.Val("lbl_no_chords")
			GUI.font(GUI.elms.lbl_no_chords.font)
			local str_w, str_h = gfx.measurestr(str)
			
			GUI.elms.lbl_no_chords.x = (GUI.cur_w - line_x - str_w) / 2 + line_x 
			GUI.elms.lbl_no_chords.y = btn_template[2] + btn_space_v + 6
			GUI.elms.lbl_clickplay.y = -200
		else
			local str = GUI.Val("lbl_clickplay")	
			GUI.font(GUI.elms.lbl_clickplay.font)
			local str_w, str_h = gfx.measurestr(str)
		
			--GUI.elms.lbl_clickplay.x = (GUI.cur_w - line_x - str_w) / 2 + line_x
			GUI.elms.lbl_clickplay.x = line_x + 16
			GUI.elms.lbl_clickplay.y = btn_template[2] + (most_chords * (btn_template[4] + btn_space_v) + 6)
		end
		

		
		-- Center the reascale label in the left pane
		local str = GUI.Val("lbl_reascale")
		GUI.font(GUI.elms.lbl_reascale.font)
		local str_w, str_h = gfx.measurestr(str)
		
		GUI.elms.lbl_reascale.x = (line_x - str_w) / 2
		
	end
	
end

GUI.func = Main
GUI.freq = 0

GUI.Exit = function ()
	reaper.Main_OnCommand(40345, 0)
	reaper.TrackCtl_SetToolTip("", 0, 0, false)	
end

GUI.Init()
get_reascale(1)
GUI.Main()

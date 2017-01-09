--[[
Description: Duplicate selected notes chromatically...
Version: 1.5
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Reworked the script to include individual actions
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Duplicates the selected notes up or down a specified interval diatonically
Extensions: 
Provides:
	[main] Lokasenna_Duplicate selected notes chromatically/*.lua
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

GUI.version = "beta 5"


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



	---- Color and drawing functions ----

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
	if GUI.elms_top then
		for key, elm in pairs(GUI.elms_top) do
			GUI.Update(elm)
		end
	end
	for key, elm in pairs(GUI.elms) do
		GUI.Update(elm)
	end
	if GUI.elms_bottom then
		for key, elm in pairs(GUI.elms_bottom) do
			GUI.Update(elm)
		end	
	end
	if GUI.elms_bg then
		for key, elm in pairs(GUI.elms_bg) do
			GUI.Update(elm)
		end
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
	if GUI.elms_bottom then
		for key, elm in pairs(GUI.elms_bottom) do
			elm:draw()
		end
	end
	for key, elm in pairs(GUI.elms) do
		elm:draw()
	end
	if GUI.elms_top then
		for key, elm in pairs(GUI.elms_top) do
			elm:draw()
		end
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

	if not GUI.version then return 0 end

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
		self.curstep = newval
		self.curval = self.curstep / self.steps
		self.retval = GUI.round((((self.max - self.min) / self.steps) * self.curstep) + self.min)
		--self.retval = newval
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
x, y, w, h		Coordinates of top-left corner, width, height
caption			Text to display to the left of the textbox
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

GUI.name = "Duplicate selected notes (chromatic)..."
GUI.x, GUI.y, GUI.w, GUI.h = -48, 0, 250, 56
GUI.anchor, GUI.corner = "mouse", "C"

local interval_arr = {
	{"up a major seventh (+11)", 11},
	{"up a minor seventh (+10)", 10},
	{"up a major sixth (+9)", 9},
	{"up a minor sixth (+8)", 8},
	{"up a perfect fifth (+7)", 7},
	{"up a tritone (+6)", 6},
	{"up a perfect fourth (+5)", 5},
	{"up a major third (+4)", 4},
	{"up a minor third (+3)", 3},
	{"up a major second (+2)", 2},
	{"up a minor second (+1)", 1},
	{" ", 0},
	{"down a minor second (-1)", -1},
	{"down a major second (-2)", -2},
	{"down a minor third (-3)", -3},
	{"down a major third (-4)", -4},
	{"down a perfect fourth (-5)", -5},
	{"down a tritone (-6)", -6},
	{"down a perfect fifth (-7)", -7},
	{"down a minor sixth (-8)", -8},
	{"down a major sixth (-9)", -9},
	{"down a minor seventh (-10)", -10},
	{"down a major seventh (-11)", -11},
}

local interval_str = interval_arr[1][1]
for i = 2, #interval_arr do
	interval_str = interval_str..","..interval_arr[i][1]
end

local function dup_notes()
	
	local cur_wnd = reaper.MIDIEditor_GetActive()
	if not cur_wnd then
		reaper.ShowMessageBox( "This script needs an active MIDI editor.", "No MIDI editor found", 0)
		return 0
	end
	local cur_take = reaper.MIDIEditor_GetTake(cur_wnd)
	
	
	-- Parse the text to get an interval
	local val = interval or interval_arr[GUI.Val("mnu_intervals")][2]
	if not val then
		return 0
	else
		
		reaper.Undo_BeginBlock()
		
		-- Get all of the selected notes
		local sel_notes = {}
	
		local cur_note = -2
		local note_val
		while cur_note ~= -1 do
		
			cur_note = reaper.MIDI_EnumSelNotes(cur_take, cur_note)
			if cur_note == -1 then break end
			cur_arr = {reaper.MIDI_GetNote(cur_take, cur_note)}
			table.remove(cur_arr, 1)
			table.insert(sel_notes, cur_arr)
	
		end
		
		reaper.MIDI_SelectAll(cur_take, false)
		
		-- For each note in the array, add interval and duplicate
		for i = 1, #sel_notes do
			sel_notes[i][6] = sel_notes[i][6] + val
		local sel, mute, start, _end, chan, pitch, vel = table.unpack(sel_notes[i])
			reaper.MIDI_InsertNote(cur_take, sel, mute, start, _end, chan, pitch, vel, true)
		end
		
		reaper.MIDI_Sort(cur_take)
		
		reaper.Undo_EndBlock("Duplicate selected notes at "..((val > 0) and "+" or "")..val.." semitones", -1)

	end
end

GUI.elms = {
	lbl_duplicate = GUI.Label:new(4, 4, "Duplicate selected notes ", 1, 4),
	mnu_intervals = GUI.Menubox:new(64, 4, 196, 18, "", interval_str, 4), 
	btn_go = GUI.Button:new(4, 26, 64, 22, "Go", dup_notes),
	--lbl_semitones = GUI.Label:new(4, 4, "", 1, 4),
}

GUI.Val("mnu_intervals", 12)

if interval then
	dup_notes()
	return 0
else	
	GUI.version = nil
	GUI.Init()

	GUI.font(4)
	local str_w_a, __ = gfx.measurestr(GUI.Val("lbl_duplicate"))
	local str_w_b, __ = gfx.measurestr(GUI.Val("lbl_semitones"))
	local __, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)

	GUI.elms.mnu_intervals.x = 4 + str_w_a + 4
	--GUI.elms.lbl_semitones.x = GUI.elms.mnu_intervals.x + GUI.elms.mnu_intervals.w + 4
	--local new_w = GUI.elms.lbl_semitones.x + str_w_b + 4
	local new_w = GUI.elms.mnu_intervals.x + GUI.elms.mnu_intervals.w + 4

	GUI.elms.btn_go.x = (new_w - GUI.elms.btn_go.w) / 2

	gfx.quit()
	gfx.init(GUI.name, new_w, h, 0, x, y)
	GUI.cur_w = new_w

	GUI.Main()
end

--[[
Description: MIDI Note Selector
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Takes an existing note selection and selects only every 'n'th 
    note.
Extensions:
--]]

-- Licensed under the GNU GPL v3



-- Create a master table to store all of our functions
-- After each function we'll read it into the table with:
--	GUI.xxx = xxx
local GUI = {}


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
	
	-- Font, size, bold, italics, underline
	-- 				^ (Only one at a time) ^
	{"Calibri", 36, 1, 0, 0},	-- 1. Title
	{"Calibri", 28, 0, 0, 0},	-- 2. Header
	{"Calibri", 22, 0, 0, 0},	-- 3. Label
	{"Calibri", 18, 0, 0, 0}	-- 4. Value
	
}


GUI.colors = {
	
	wnd_bg = {64, 64, 64, 1},			-- Window BG
	elm_bg = {48, 48, 48, 1},			-- Element BG
	elm_frame = {96, 96, 96, 1},		-- Element Frame
	elm_fill = {64, 192, 64, 1},		-- Element Fill
	elm_outline = {32, 32, 32, 1},
	txt = {192, 192, 192, 1},			-- Text
	
	shadow = {0, 0, 0, 0.4}				-- Shadow

}


GUI.font = function (fnt)
	local font, size, b, i, u = table.unpack(GUI.fonts[fnt])
	
	-- ASCII values:
	-- Bold		 98
	-- Italics	 105
	-- Underline 117
	local flags = 0
	if b == 1 then flags = flags + 98 end
	if i == 1 then flags = flags + 105 end
	if u == 1 then flags = flags + 117 end

	
	gfx.setfont(1, font, size, flags)
end


GUI.color = function (col)
	gfx.set(table.unpack(GUI.colors[col]))
end



-- Global shadow size, in pixels
GUI.shadow_dist = 2


-- Draw the given string with a shadow
GUI.shadow = function (str)
	
	local x, y = gfx.x, gfx.y
	
	GUI.color("shadow")
	for i = 1, GUI.shadow_dist do
		gfx.x, gfx.y = x + i, y + i
		gfx.drawstr(str)
	end
	
	GUI.color("txt")
	gfx.x, gfx.y = x, y
	gfx.drawstr(str)
	
end


	---- General functions ----
		

-- Print stuff to the Reaper console. For debugging purposes.
GUI.Msg = function (message)
	reaper.ShowConsoleMsg(tostring(message).."\n")
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
	


	-- Initialize a few values
	GUI.last_time = 0
	GUI.mouse = {
	
		x = 0,
		y = 0,
		cap = 0,
		down = false,
		wheel = 0,
		lwheel = 0
		
	}
		
	-- Convert color presets from 0..255 to 0..1
	for i, col in pairs(GUI.colors) do
		col[1], col[2], col[3] = col[1] / 255, col[2] / 255, col[3] / 255
	end

end


GUI.Main = function ()


	-- Update mouse and keyboard state
	GUI.mouse.x, GUI.mouse.y = gfx.mouse_x, gfx.mouse_y
	GUI.mouse.wheel = gfx.mouse_wheel
	GUI.mouse.cap = gfx.mouse_cap
	GUI.char = gfx.getchar() 
	
	--	(Escape key)	(Window closed)		(User function says to close)
	if GUI.char == 27 or GUI.char == -1 or GUI.quit == true then
		
		-- See if an exit function was specified
		if GUI.exit then
			GUI.exit()
		end
		return 0
	else
		reaper.defer(GUI.Main)
	end
	
	-- Update each element's state
	for key, elm in pairs(GUI.elms) do
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
	
	-- Redraw each element
	for key, elm in pairs(GUI.elms) do
		elm:draw()
	end		
	
	gfx.update()
	
end


GUI.Update = function (elm)
	
	local x, y = GUI.mouse.x, GUI.mouse.y
	local wheel = GUI.mouse.wheel
	local char = GUI.char

	-- Left button down
	if GUI.mouse.cap&1==1 then
		
		-- If it wasn't down already...
		if not GUI.mouse.down then
			
			-- Was a different element clicked?
			if not GUI.IsInside(elm, x, y) then 
				
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
	
	-- If the mousewheel's state has changed
	if GUI.mouse.wheel ~= GUI.mouse.lwheel and GUI.IsInside(elm, GUI.mouse.x, GUI.mouse.y) then
		
		local inc = (GUI.mouse.wheel - GUI.mouse.lwheel) / 120
		
		elm:onwheel(inc)
		GUI.mouse.lwheel = GUI.mouse.wheel
	
	end
	
	-- If the element is in focus and the user typed something
	if elm.focus and char ~= 0 then elm:ontype(char) end
	
end


-- For use with external user functions. Returns the given element's current value or, if specified, sets a new one.
GUI.Val = function (elm, newval)

	if newval then
		GUI.elms[elm]:val(newval)
	else
		return GUI.elms[elm]:val()
	end

end




	---- Elements ----
	
	
	

--[[	Label class.
	
	---- User parameters ----
x, y			Coordinates of top-left corner
caption			Label text
shadow			(1) Draw a shadow, (2) No shadow
	
]]--

-- Label - New
GUI.Label = {}
function GUI.Label:new(x, y, caption, shadow)
	
	local label = {}
	label.type = "Label"
	
	label.x, label.y = x, y
	
	-- Placeholders for these values, since we don't need them but some functions will throw a fit if they aren't there
	label.w, label.h = 0, 0
	
	label.retval = caption
	
	label.shadow = shadow or 0
	
	setmetatable(label, self)
    self.__index = self 
    return label
	
end


-- Label - Draw
function GUI.Label:draw()
	
	local x, y = self.x, self.y
		
	GUI.font(1)
	
	gfx.x, gfx.y = x, y
	
	local output = self.output or self.retval
	
	if self.shadow == 1 then	
		GUI.shadow(output)
	else
		gfx.drawstr(output)
	end	

end


-- Label - Get/set value
function GUI.Label:val(newval)

	if newval then
		self.retval = newval
	else
		return self.retval
	end

end


-- Label - Unused methods.
function GUI.Label:onmousedown() end
function GUI.Label:onmouseup() end
function GUI.Label:ondoubleclick() end
function GUI.Label:ondrag() end
function GUI.Label:onwheel() end
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
local Slider = {}
function Slider:new(x, y, w, caption, min, max, steps, default, ticks)
	
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
function Slider:draw()
	
	
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


	GUI.shadow(self.caption)
	
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
function Slider:val(newval)

	if newval then
		self.retval = newval
	else
		return self.retval
	end

end


-- Slider - Mouse down
function Slider:onmousedown()
	
	-- Snap to the nearest value
	self.curval = (GUI.mouse.x - self.x) / self.w
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end
	
	self.curstep = GUI.round(self.curval * self.steps)
	
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	
end


-- Slider - Dragging
function Slider:ondrag()
	
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
function Slider:onwheel(inc)
	
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
function Slider:onmouseup() end
function Slider:ondoubleclick() end
function Slider:ontype() end


GUI.Slider = Slider




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
local Range = {}
function Range:new(x, y, w, caption, min, max, steps, default_a, default_b)
	
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
function Range:draw()

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
	
	GUI.shadow(self.caption)
	
	
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
function Range:val(newval_a, newval_b)
	
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
function Range:onmousedown()
	
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
function Range:ondrag()
	
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
function Range:onwheel(inc)
	
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


function Range:onmouseup() end
function Range:ondoubleclick() end
function Range:ontype() end


GUI.Range = Range




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
local Knob = {}
function Knob:new(x, y, w, caption, min, max, steps, default, ticks)
	
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
function Knob:draw()
	
	
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
	GUI.shadow(caption)

	
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
function Knob:val(newval)
	
	if newval then
		self.retval = newval
		self.curstep = newval - self.min
		self.curval = self.curstep / self.steps
		
	else
		return self.retval
	end	

end


-- Knob - Dragging.
function Knob:ondrag()
	
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
function Knob:onwheel(inc)

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
function Knob:onmousedown() end
function Knob:onmouseup() end
function Knob:ondoubleclick() end
function Knob:ontype() end


GUI.Knob = Knob


--[[	Radio class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and each option

]]--

-- Radio - New.
local Radio = {}
function Radio:new(x, y, w, h, caption, opts, pad)
	
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
function Radio:draw()
	
	
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
	
	GUI.shadow(self.caption)
	
	GUI.font(3)

	-- Draw the options
	GUI.color("txt")
	local optheight = (h - self.capheight - 2 * pad) / self.numopts
	local cur_y = y + self.capheight + pad
	local radius = 10
	
	for i = 1, self.numopts do	
		

		gfx.set(r, g, b, 1)

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
function Radio:val(newval)
	
	if newval then
		self.state = newval
	else
		return self.retval
	end	
	
end


-- Radio - Mouse down.
function Radio:onmousedown()
			
	--See which option it's on
	local adj_y = self.y + self.capheight + self.pad
	local adj_h = self.h - self.capheight - self.pad
	local mouseopt = (GUI.mouse.y - adj_y) / adj_h
		
	mouseopt = math.floor(mouseopt * self.numopts) + 1

	self.state = mouseopt
	
end


-- Radio - Mouse up
function Radio:onmouseup()
		
	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		self.retval = self.state
	else
		self.state = self.retval	
	end
	
end


-- Radio - Dragging
function Radio:ondrag() 

	self:onmousedown()

end


-- Radio - Mousewheel
function Radio:onwheel(inc)
	
	self.state = self.state - inc
	
	if self.state < 1 then self.state = 1 end
	if self.state > self.numopts then self.state = self.numopts end
	
	self.retval = self.state
	
end


-- Radio - Unused methods.
function Radio:ondoubleclick() end
function Radio:ontype() end


GUI.Radio = Radio




--[[	Checklist class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and each option


]]--

-- Checklist - New
local Checklist = {}
function Checklist:new(x, y, w, h, caption, opts, pad)
	
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
function Checklist:draw()
	
	
	local x, y, w, h = self.x, self.y, self.w, self.h

	local pad = self.pad
	
	-- Draw the element frame
	
	if self.numopts > 1 then
		
		GUI.color("elm_frame")
		gfx.rect(x, y, w, h, 0)
		
	end	


	GUI.font(2)
	
	-- Draw the caption
	local str_w, str_h = gfx.measurestr(self.caption)
	self.capheight = str_h
	gfx.x = x + (w - str_w) / 2
	gfx.y = y
	GUI.shadow(self.caption)
	

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
			GUI.shadow(self.optarray[i])
		else
			GUI.color("txt")
			gfx.drawstr(self.optarray[i])
		end
		
		cur_y = cur_y + optheight
		
	end
	
end


-- Checklist - Get/set value. Returns a table of boolean values for each option.
function Checklist:val(...)
	
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
function Checklist:onmousedown()
			
	-- See which option it's on
	local adj_y = self.y + self.capheight
	local adj_h = self.h - self.capheight
	local mouseopt = (GUI.mouse.y - adj_y) / adj_h
	mouseopt = math.floor(mouseopt * self.numopts) + 1
	
	-- Make that the current option
	self.optsel[mouseopt] = not self.optsel[mouseopt]
	
	self:val()
	
end

-- Checklist - Unused methods.
function Checklist:onwheel() end
function Checklist:onmouseup() end
function Checklist:ondoubleclick() end
function Checklist:ondrag() end
function Checklist:ontype() end


GUI.Checklist = Checklist




--[[	Button class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, height
caption			Label / question
func			Function to perform when clicked
...				If provided, any parameters to pass to that function.
	
]]--

-- Button - New
local Button = {}
function Button:new(x, y, w, h, caption, func, ...)

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
function Button:draw()
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	local r, g, b = self.r, self.g, self.b
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
	gfx.x = x + 2 * state + ((w - str_w) / 2) - 2
	gfx.y = y + 2 * state + ((h - str_h) / 2) - 2
	gfx.drawstr(self.caption)

end


-- Button - Mouse down.
function Button:onmousedown()
	
	self.state = 1
	
end


-- Button - Mouse up.
function Button:onmouseup() 
	
	self.state = 0
	
	-- If the mouse was released on the button, run func
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		
		self.func(table.unpack(self.params))
		
	end

end


-- Button - Unused methods.
function Button:val() end
function Button:onwheel() end
function Button:ondoubleclick() end
function Button:ondrag() end
function Button:ontype() end


GUI.Button = Button




--[[	Textbox class. Adapted from schwa's example code.
	
	---- User parameters ----
x, y, w, h		Coordinates of tep-left corner, width, height
pad				Padding between the left side and first character.

	
]]--

-- Textbox - New
local Textbox = {}
function Textbox:new(x, y, w, h, caption, pad)
	
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
function Textbox:draw()
	
	
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
	GUI.shadow(caption)
	
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
function Textbox:val(newval)
	
	if newval then
		self.retval = newval
	else
		return self.retval
	end
end


-- Textbox - Get the closest character position to the mouse.
function Textbox:getcaret()
	
	local len = string.len(self.retval)
	GUI.font(3)
	
	for i = 1, len do
		
		w = gfx.measurestr(string.sub(self.retval, 1, i))
		if GUI.mouse.x < (self.x + self.pad + w) then return i - 1 end
	
	end
	
	return len

end


-- Textbox - Mouse down.
function Textbox:onmousedown()
	
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
function Textbox:ondoubleclick()
	
	local len = string.len(self.retval)
	self.caret, self.sel = len, -len

end


-- Textbox - Mouse drag.
function Textbox:ondrag()
	
	self.sel = self:getcaret() - self.caret
	
end


-- Textbox - Typing.
function Textbox:ontype(char)

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
function Textbox:onwheel() end
function Textbox:onmouseup() end


GUI.Textbox = Textbox



--[[	MenuBox class
	
	---- User parameters ----
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and each option
	
]]--
local Menubox = {}
function Menubox:new(x, y, w, h, caption, opts, pad)
	
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
function Menubox:draw()	
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	
	local caption = self.caption
	local text = self.optarray[self.retval]

	local focus = self.focus
	

	-- Draw the caption
	GUI.font(3)
	local str_w, str_h = gfx.measurestr(caption)
	gfx.x = x - str_w - self.pad
	gfx.y = y + (h - str_h) / 2
	GUI.shadow(caption)
	
	
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
function Menubox:val(newval)
	
	if newval then
		self.retval = newval
	else
		return self.retval
	end
	
end


-- Menubox - Mouse up
function Menubox:onmouseup()
	
	local menu_str = ""
	
	for i = 1, self.numopts do
		if i == self.curopt then menu_str = menu_str .. "!" end
		menu_str = menu_str .. self.optarray[i] .. "|"
	end
	
	gfx.x = self.x
	gfx.y = self.y + self.h
	
	local curopt = gfx.showmenu(menu_str)
	if curopt ~= 0 then self.retval = curopt end
	self.focus = false
end


-- Menubox - Mousewheel
function Menubox:onwheel(inc)
	
	local curopt = self.retval - inc
	
	if curopt < 1 then curopt = 1 end
	if curopt > self.numopts then curopt = self.numopts end
	
	self.retval = curopt
	
end


function Menubox:onmousedown() end
function Menubox:ondrag() end
function Menubox:ondoubleclick() end
function Menubox:ontype() end


GUI.Menubox = Menubox



GUI.name = "LS MIDI Note Selector"
GUI.x, GUI.y, GUI.w, GUI.h = 200, 50, 200, 100


local cur_editor = reaper.MIDIEditor_GetActive()
local cur_take = reaper.MIDIEditor_GetTake(cur_editor)

local cur_selection = {}

-- Store the initial MIDI selection in a table
local selection = {}
local function get_selection()
	
	local cur_note = -2
	while cur_note ~= -1 do
		
		cur_note = reaper.MIDI_EnumSelNotes(cur_take, cur_note)
		table.insert(selection, cur_note)
		
	end
	
end

-- Returns an ordinal string (i.e. 30 --> 30th)
local function ordinal(num)
	
	rem = num % 10
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

local last_sel, last_off = 0, 0

local function func()
	
	local cur_sel = GUI.Val("sel_sldr")
	local cur_off = GUI.Val("off_sldr")
	
	-- See if either slider has been changed
	if cur_sel ~= last_sel or cur_off ~= last_off then

		-- Select every _sel_th note, starting at _off_
		reaper.MIDI_SelectAll(cur_take, 0)
		for i = cur_off, #selection, cur_sel do
			reaper.MIDI_SetNote(cur_take, selection[i], 1)
		end
		
		-- Update the element captions
		GUI.elms.sel_sldr.caption = "Select every "..ordinal(cur_sel).." note,"
		GUI.elms.off_sldr.caption = "starting with the "..ordinal(cur_off).." note"
		
		-- Erase the slider values
		GUI.elms.sel_sldr.output = ""
		GUI.elms.off_sldr.output = ""
	
		-- Save current state
		last_sel = cur_sel
		last_off = cur_off

	end

end
GUI.func = func
GUI.freq = 0

GUI.elms = {
	
	-- Select every ___th note
	sel_sldr = GUI.Slider:new(25, 35, 150, "Select every 2nd note,", 1, 16, 17, 1),
		
	-- Selection offset
	off_sldr = GUI.Slider:new(25, 80, 150, "starting with the 1st note", 1, 16, 16, 0),
	
}

reaper.Undo_BeginBlock()

get_selection()

GUI.Init()
GUI.Main()
reaper.Undo_EndBlock("LS MIDI Note Selector", -1)

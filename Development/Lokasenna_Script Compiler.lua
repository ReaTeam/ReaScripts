--[[
Description: Script compiler
Version: 2.0.1
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	A few small bug fixes
	Checking if the output folder was created is disabled, due to
	the API function giving buggy return values
	Refactored/reorganized the code for readability
Links:
	Forum thread http://forum.cockos.com/showthread.php?t=185264
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Simplifies the process of working with and distributing additional
	library files for Lua scripters, by scanning your script for a few
	specific commands and using them to copy the external libraries'
	contents directly into the base script.
	
	See the forum thread for a more detailed explanation.
Extensions: SWS/S&M 2.8.3
--]]

-- Licensed under the GNU GPL v3

local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]


local function req(file)
	
	local ret = loadfile(script_path .. file) or loadfile(script_path .. "Libraries\\" .. file)
	if not ret then
		reaper.ShowMessageBox("Couldn't find "..file.."\n\nLokasenna probably forgot to compile the script again.", "Missing library", 0)
		return 0
	else 
		return ret
	end	

end

req("Lokasenna_GUI library beta 7.lua")()


------------------------------------
-------- GUI Setup -----------------
------------------------------------


GUI.name = "Lokasenna's Script Compiler"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 600, 600
GUI.anchor, GUI.corner = "mouse", "C"


GUI.fonts[1] = {"Calibri", 32}
GUI.fonts[2] = {"Calibri", 20}
GUI.fonts[3] = {"Calibri", 16}
GUI.fonts[4] = {"Calibri", 16}
GUI.fonts[6] = {"Calibri", 18, "b"}


------------------------------------
-------- Variables + Data ----------
------------------------------------


local help_str = 
[=[This script aims to simplify the process of distributing Lua ReaScripts that make use of additional 
libraries, i.e. by 'require', 'loadfile', or '@import'. It searches through your base script for a few
specifically-formatted comments to determine what libraries you need, then copies their contents
directly into the body of the script.
 
	Example:
 	
---- Libraries added with Lokasenna's Script Compiler ----



---- Beginning of file: Lokasenna_GUI library beta 7.lua ----

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



GUI.version = "beta 7"

-- Might want to know this
GUI.OS = reaper.GetOS()

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
	tab_bg = {56, 56, 56, 255},
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
	
	if string.find(GUI.OS, "OSX") then
		size = math.floor(size * 0.8)
	end
	
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


-- Draws a string using the given text and outline color presets
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
		

-- To open files in their default app, or URLs in a browser
-- Copied from Heda; cheers!
GUI.open_file = function (path)
  local OS = reaper.GetOS()
  if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. path .. '"')
  else
    os.execute('start "" "' .. path .. '"')
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


-- Round a number to the nearest integer (or optional decimal places)
GUI.round = function (num, places)
    --return num % 1 >= 0.5 and math.ceil(num) or math.floor(num)
	if not places then
		return math.floor(num + 0.5)
	else
		places = 10^places
		return math.floor(num * places + 0.5) / places
	end
	
end

-- Make sure val is between min and max
GUI.clamp = function (num, min, max)
	if min > max then min, max = max, min end
	return math.min(math.max(num, min), max)
end


GUI.pi = 3.1415927


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
	
		r = (h / 2 - 1)
	
		-- Ends
		gfx.circle(x + r, y + r, r, 1, aa)
		gfx.circle(x + w - r, y + r, r, 1, aa)
		
		-- Body
		gfx.rect(x + r, y, w - (r * 2), h)
		
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
	
	local angle = angle * GUI.pi
	local x = radius * math.cos(angle)
	local y = radius * math.sin(angle)

	
	if ox and oy then x, y = x + ox, y + oy end

	return x, y
	
end


--[[
	Takes cartesian coords, with optional origin coords, and returns
	an angle (in radians) and radius. The angle is given without reference
	to pi; that is, pi/4 rads would return as simply 0.25
]]--
GUI.cart2polar = function (x, y, ox, oy)
	
	local dx, dy = x - (ox or 0), y - (oy or 0)
	
	local angle = math.atan(dy, dx) / GUI.pi
	local r = math.sqrt(dx * dx + dy * dy)

	return angle, r
	
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
	
-- Maintain a list of all GUI elements, sorted by their z order	
GUI.update_elms_list = function (init)
	
	local z_table = {}
	if init then 
		GUI.elms_list = {}
		GUI.z_max = 0 
	end

	for key, __ in pairs(GUI.elms) do

		local z = GUI.elms[key].z or 5

		if z == -1 then
			
			GUI.elms[key] = nil
			
		else

			if z_table[z] then
				table.insert(z_table[z], key)

			else
				z_table[z] = {key}

			end
		
		end
		
		if init then GUI.z_max = math.max(z, GUI.z_max)	end

	end

	for i = 0, GUI.z_max do
		if not z_table[i] then z_table[i] = {} end
	end

	GUI.elms_list = z_table
	
end



GUI.Init = function ()
	
	
	-- Create the window
	gfx.clear = GUI.rgb2num(table.unpack(GUI.colors.wnd_bg))
	
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
	
	-- Initialize the tables for our z-order functions
	GUI.update_elms_list(true)	
	if not GUI.elms_hide then 
		GUI.elms_hide = {}
	end
	if not GUI.elms_freeze then GUI.elms_freeze = {} end
	
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
	GUI.update_elms_list()
	
	-- We'll use this to break the update loop early if the user did something
	-- Slightly more efficient, and averts any bugs from false positives
	GUI.elm_updated = false

	for i = 0, GUI.z_max do
		if #GUI.elms_list[i] > 0 and not (GUI.elms_hide[i] or GUI.elms_freeze[i]) then
			for __, elm in pairs(GUI.elms_list[i]) do
				
				GUI.cur_elm = elm
				GUI.Update(GUI.elms[elm])
				if GUI.elm_updated then break end
				
			end
		end
		
		if GUI.elm_updated then break end
		
	end

	GUI.mouse.last_down = GUI.mouse.down
	GUI.mouse.last_r_down = GUI.mouse.r_down

	-- If the user gave us a function to run, check to see if it needs to be run again, and do so.
	-- 
	if GUI.func then
		
		GUI.freq = GUI.freq or 1
		
		local new_time = os.time()
		if new_time - GUI.last_time >= GUI.freq then
			GUI.func()
			GUI.last_time = new_time
		
		end
	end
	
	-- Redraw all of the elements, starting from the bottom up.
	GUI.update_elms_list()

	for i = GUI.z_max, 0, -1 do
		if #GUI.elms_list[i] > 0 and not GUI.elms_hide[i] then
			for __, elm in pairs(GUI.elms_list[i]) do
				if not GUI.elms[elm] then GUI.Msg(elm.." doesn't exist?") end
				GUI.elms[elm]:draw()
			end
		end
	end
	GUI.Draw_Version()
	
	gfx.update()
	
end


GUI.Update = function (elm)
	
	local x, y = GUI.mouse.x, GUI.mouse.y
	local wheel = GUI.mouse.wheel
	local inside = GUI.IsInside(elm, x, y)
	

	-- Left button click
	if GUI.mouse.cap&1==1 then
		
		-- If it wasn't down already...
		if not GUI.mouse.last_down then

			-- Was a different element clicked?
			if not inside then 
				elm.focus = false
			else	
	
				GUI.mouse.down = true
				GUI.mouse.ox, GUI.mouse.oy = x, y
				GUI.mouse.lx, GUI.mouse.ly = x, y
				elm.focus = true
				elm:onmousedown()
				GUI.elm_updated = true
				
				-- Double clicked?
				if GUI.mouse.uptime and os.clock() - GUI.mouse.uptime < 0.20 then
					elm:ondoubleclick()
					GUI.elm_updated = true
				end				
				
			end
			

		
		-- 		Dragging? 									Did the mouse start out in this element?
		elseif (x ~= GUI.mouse.lx or y ~= GUI.mouse.ly) and GUI.IsInside(elm, GUI.mouse.ox, GUI.mouse.oy) then
			if elm.focus ~= false then 
				elm:ondrag()
				GUI.elm_updated = true
			end
			GUI.mouse.lx, GUI.mouse.ly = x, y
		end

	-- If it was originally clicked in this element and has now been released
	elseif GUI.mouse.down and GUI.IsInside(elm, GUI.mouse.ox, GUI.mouse.oy) then 
	
		elm:onmouseup()
		GUI.elm_updated = true
		GUI.mouse.down = false
		GUI.mouse.ox, GUI.mouse.oy = -1, -1
		GUI.mouse.lx, GUI.mouse.ly = -1, -1
		GUI.mouse.uptime = os.clock()

	end
	
	
	-- Right button click
	if GUI.mouse.cap&2==2 then
		
		-- If it wasn't down already...
		if not GUI.mouse.last_r_down then

			-- Was a different element clicked?
			if not inside then 
				--elm.focus = false
			else
	
				GUI.mouse.r_down = true
				GUI.mouse.r_ox, GUI.mouse.r_oy = x, y
				GUI.mouse.r_lx, GUI.mouse.r_ly = x, y
				--elm.focus = true
				elm:onmouser_down()
				GUI.elm_updated = true
			
			end
			
			-- Double clicked?
			if GUI.mouse.r_uptime and os.clock() - GUI.mouse.r_uptime < 0.20 then
				elm:onr_doubleclick()
				GUI.elm_updated = true
			end
		
		-- 		Dragging? 									Did the mouse start out in this element?
		elseif (x ~= GUI.mouse.r_lx or y ~= GUI.mouse.r_ly) and GUI.IsInside(elm, GUI.mouse.r_ox, GUI.mouse.r_oy) then
			if elm.focus ~= false then 
				elm:onr_drag()
				GUI.elm_updated = true
			end
			GUI.mouse.r_lx, GUI.mouse.r_ly = x, y
		end

	-- If it was originally clicked in this element and has now been released
	elseif GUI.mouse.r_down and GUI.IsInside(elm, GUI.mouse.r_ox, GUI.mouse.r_oy) then 
	
		elm:onmouser_up()
		GUI.elm_updated = true
		GUI.mouse.r_down = false
		GUI.mouse.r_ox, GUI.mouse.r_oy = -1, -1
		GUI.mouse.r_lx, GUI.mouse.r_ly = -1, -1
		GUI.mouse.r_uptime = os.clock()

	end
	
	
	-- If the mouse is hovering over the element
	if not GUI.mouse.down and not GUI.mouse.r_down and inside then
		elm:onmouseover()
		GUI.elm_updated = true
		elm.mouseover = true
	else
		elm.mouseover = false
		--elm.hovering = false
	end
	
	
	-- If the mousewheel's state has changed
	if GUI.mouse.wheel ~= GUI.mouse.lwheel and inside then
		
		GUI.mouse.inc = (GUI.mouse.wheel - GUI.mouse.lwheel) / 120
		
		elm:onwheel()
		GUI.elm_updated = true
		GUI.mouse.lwheel = GUI.mouse.wheel
	
	end
	
	-- If the element is in focus and the user typed something
	if elm.focus and GUI.char ~= 0 then
		elm:ontype() 
		GUI.elm_updated = true
	end
	
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

	local str = "Lokasenna_GUI "..GUI.version
	
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

GUI.Element = {}
function GUI.Element:new()
	
	local elm = {}
	setmetatable(elm, self)
	self.__index = self
	return elm
	
end

function GUI.Element:onmouseover()
	
	if self.tooltip and not GUI.tooltip_elm then GUI.tooltip_elm = self end

end

function GUI.Element:val() end
function GUI.Element:onmousedown() end
function GUI.Element:onmouseup() end
function GUI.Element:ondoubleclick() end
function GUI.Element:ondrag() end
function GUI.Element:onmouser_down() end
function GUI.Element:onmouser_up() end
function GUI.Element:onr_doubleclick() end
function GUI.Element:onr_drag() end
function GUI.Element:onwheel() end
function GUI.Element:ontype() end



--[[	Label class.
	
	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y			Coordinates of top-left corner
caption			Label text
shadow			(1) Draw a shadow
font			Which of the GUI's font values to use
	
	
Additional parameters
color			Use one of the GUI.colors keys to override the standard text color
fade			Pops up text with a fadeout effect. Call like so:
				
					GUI.elms.lbl_blah.fade = { 2, 0, 18 }
											time (s)
												bring to z
													send back to z
													or -1 to delete
				Note: Fade won't work properly if the label is shadowed. For now.
]]--
-- Label - New
GUI.Label = GUI.Element:new()
function GUI.Label:new(z, x, y, caption, shadow, font)
	
	local label = {}	
	
	label.type = "Label"
	
	label.z = z
	
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


function GUI.Label:fade(len, z_new, z_end)
	
	self.z = z_new
	self.fade_arr = { len, z_end, reaper.time_precise() }
	
end


-- Label - Draw
function GUI.Label:draw()
	
	local x, y = self.x, self.y
		
	GUI.font(self.font)
	GUI.color(self.color or "txt")
	
	if self.fade_arr then
		
		-- Seconds for fade effect, roughly
		local fade_len = self.fade_arr[1]
		
		local diff = (reaper.time_precise() - self.fade_arr[3]) / fade_len
		diff = math.floor(diff * 1000) / 1000
		diff = diff * diff * diff
		--diff = diff * diff
		local a = 1 - (gfx.a * (diff))
		--GUI.Msg("a = "..a)
		if a < 0.02 then
			self.z = self.fade_arr[2]
			self.fade_arr = nil
			return 0 
		end
		gfx.set(gfx.r, gfx.g, gfx.b, a)
	end

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



--[[	Slider class.

	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.	
x, y, w			Coordinates of top-left corner, width. Height is fixed.
caption			Label / question
min, max		Minimum and maximum slider values
steps			How many steps between min and max
default			Where the slider should start
				(also sets the start of the fill bar)
ticks			Display ticks or not. **Currently does nothing**

]]--

-- Slider - New
GUI.Slider = GUI.Element:new()
function GUI.Slider:new(z, x, y, w, dir, caption, min, max, steps, default, ticks)
	
	local Slider = {}
	Slider.type = "Slider"
	
	Slider.z = z
	
	Slider.x, Slider.y = x, y
	Slider.w, Slider.h = table.unpack(dir == "h" and {w, 8} or {8, w})
	
	Slider.dir = dir
	if dir == "v" then
		min, max, default = max, min, steps - default
		
	end

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

	local dir = self.dir
	local steps = self.steps
	local curstep = self.curstep
	local min, max = self.min, self.max
	
	-- Size of the handle
	local radius = 8


	if dir == "h" then
		
		-- Draw track
		GUI.color("elm_bg")
		GUI.roundrect(x, y, w, h, 3, 1, 1)
		GUI.color("elm_outline")
		GUI.roundrect(x, y, w, h, 3, 1, 0)
	
		-- Limit everything to be drawn within the square part of the track
		x, w = x + 4, w - 8

		
		-- Handle
		local inc = w / steps
		local ox, oy = x + inc * curstep, y + (h / 2)
		
		-- Fill in between the handle and the starting point
		local fill_x = GUI.round( x + ((self.default / steps) * w) )
		local fill_w = GUI.round( ox - fill_x )
		
		if fill_w ~= 0 then
			
			GUI.color(self.col_fill or "elm_fill")
			gfx.circle(fill_x - 1, oy, h / 2 - 1, 1, 1)	
			
			-- gfx.rect gets cranky about drawing a negative height			
			if fill_w < 0 then
				fill_w = math.abs(fill_w)
				fill_x = fill_x - fill_w
			end

			gfx.rect(fill_x, y + 1, fill_w, h - 1, 1)
			
		end
		
		-- Handle shadow
		GUI.color("shadow")
		for i = 1, GUI.shadow_dist do
			
			gfx.circle(ox + i, oy + i, radius - 1, 1, 1)
			
		end

		-- Handle body
		GUI.color("elm_frame")
		gfx.circle(ox, oy, radius - 1, 1, 1)
		
		GUI.color("elm_outline")
		gfx.circle(ox, oy, radius, 0, 1)


		-- Draw caption	
		if self.caption ~= "" then
			GUI.font(3)
			
			local str_w, str_h = gfx.measurestr(self.caption)
			
			gfx.x = x + (w - str_w) / 2
			gfx.y = y - h - str_h


			GUI.shadow(self.caption, "txt", "shadow")
		end
		
		-- Draw ticks + highlighted labels if specified	
		-- Draw slider value otherwise 
		


		local output = self.output or self.retval

		if output ~= "" then
			
			GUI.color("txt")
			GUI.font(4)
			
			local str_w, str_h = gfx.measurestr(output)
			gfx.x = x + (w - str_w) / 2
			gfx.y = y + h + h
			
			gfx.drawstr(output)
		end
	
	
	elseif dir == "v" then
	
		-- Draw track
		GUI.color("elm_bg")
		GUI.roundrect(x, y, w, h, 3, 1, 1)
		GUI.color("elm_outline")
		GUI.roundrect(x, y, w, h, 3, 1, 0)	
		
	
		-- Limit everything to be drawn within the square part of the track
		y, h = y + 4, h - 8

		
		-- Get the handle's location
		local inc = h / steps
		local ox, oy = GUI.round(x + (w / 2)), y + inc * curstep
		
		-- Fill in between the handle and the starting point
		local fill_y = GUI.round( y + ((self.default / steps) * h) )
		local fill_h = GUI.round( oy - fill_y )
				
		if fill_h ~= 0 then
			
			-- If the user has given us two colors to make a gradient with
			if self.col_fill_a then
				
				-- Make a gradient, 
				local col_a = GUI.colors[self.col_fill_a]
				local col_b = GUI.colors[self.col_fill_b]
				
				local r = math.abs(col_a[1] + ((curstep / steps) * (col_b[1] - col_a[1])))
				local g = math.abs(col_a[2] + ((curstep / steps) * (col_b[2] - col_a[2])))
				local b = math.abs(col_a[3] + ((curstep / steps) * (col_b[3] - col_a[3])))
				local a = math.abs(col_a[4] + ((curstep / steps) * (col_b[4] - col_a[4])))
					
				gfx.set(r, g, b, a)
									
			else
				GUI.color(self.col_fill or "elm_fill")
			end
			gfx.circle(ox, fill_y, w / 2 - 1, 1, 1)

			-- gfx.rect gets cranky about drawing a negative height
			if fill_h < 0 then
				fill_h = math.abs(fill_h)
				fill_y = fill_y - fill_h
			end

			gfx.rect(x + 1, fill_y, w - 1, fill_h, 1)

		end
		
		-- Handle shadow
		GUI.color("shadow")
		for i = 1, GUI.shadow_dist do
			
			gfx.circle(ox + i, oy + i, radius - 1, 1, 1)
			
		end

		-- Handle body
		GUI.color("elm_frame")
		gfx.circle(ox, oy, radius - 1, 1, 1)
		
		GUI.color("elm_outline")
		gfx.circle(ox, oy, radius, 0, 1)


		-- Draw caption	
		if self.caption ~= "" then
			GUI.font(3)
			
			local str_w, str_h = gfx.measurestr(self.caption)

			gfx.x = x + (w - str_w) / 2
			gfx.y = y - h - str_h


			GUI.shadow(self.caption, "txt", "shadow")
		end
		
		-- Draw ticks + highlighted labels if specified	
		-- Draw slider value otherwise 

		local output = self.output or self.retval
		
		if output ~= "" then
			
			GUI.color("txt")
			GUI.font(4)
		
			local str_w, str_h = gfx.measurestr(output)
			gfx.x = x + (w - str_w) / 2
			gfx.y = y + h + w
			
			gfx.drawstr(output)
		end
	end
	
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
	self.curval = self.dir == "h" 
					and (GUI.mouse.x - self.x) / self.w 
					or  (GUI.mouse.y - self.y) / self.h	
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end
	
	self.curstep = GUI.round(self.curval * self.steps)
	
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	
end


-- Slider - Dragging
function GUI.Slider:ondrag()
	
	-- If this works, I love this structure
	local coord, lastcoord, size = 
		table.unpack(self.dir == "h"
					and {GUI.mouse.x, GUI.mouse.lx, self.w}
					or  {GUI.mouse.y, GUI.mouse.ly, self.h}
		)
	
	-- Ctrl?
	local ctrl = GUI.mouse.cap&4==4
	
	-- A multiplier for how fast the slider should move. Higher values = slower
	--					Ctrl	Normal
	local adj = ctrl and 1200 or 150
	
	-- Make sliders behave consistently at different sizes
	local adj_scale = size / 150
	adj = adj * adj_scale
		
	self.curval = self.curval + ((coord - lastcoord) / adj)
	if self.curval > 1 then self.curval = 1 end
	if self.curval < 0 then self.curval = 0 end
	
	self.curstep = GUI.round(self.curval * self.steps)
	
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	
end


-- Slider - Mousewheel
function GUI.Slider:onwheel()
	
	local ctrl = GUI.mouse.cap&4==4
	local inc = self.dir == "h" and GUI.mouse.inc
							or -GUI.mouse.inc
	
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




--[[	Range class
	
		---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.		
x, y, w			Coordinates of top-left corner, width. Height is fixed.
caption			Label / question
min, max		Minimum and maximum slider values
steps			How many steps between min and max
default_a		Where the sliders should start
default_b		
ticks			Display ticks or not. **Currently does nothing**
	
	
]]--
GUI.Range = GUI.Element:new()
function GUI.Range:new(z, x, y, w, caption, min, max, steps, default_a, default_b)
	
	local Range = {}
	Range.type = "Range"
	
	Range.z = z
	
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
	
	-- Handle A
	GUI.color("elm_frame")
	gfx.circle(ox_a, oy_a, radius - 1, 1, 1)
	GUI.color("elm_outline")
	gfx.circle(ox_a, oy_a, radius, 0, 1)

	
	-- Handle B
	GUI.color("elm_frame")
	gfx.circle(ox_b, oy_b, radius - 1, 1, 1)
	GUI.color("elm_outline")
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
function GUI.Range:onwheel()
	
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

	
	self[val] = self[val] + GUI.mouse.inc * adj / self.steps
	
	if self[val] < 0 then self[val] = 0 end
	if self[val] > 1 then self[val] = 1 end

	self[step] = GUI.round(self[val] * self.steps)
	
	self[ret] = GUI.round(((self.max - self.min) / self.steps) * self[step] + self.min)
	
end



--[[	Knob class.

	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.	
x, y, w			Coordinates of top-left corner, width. Height is fixed.
caption			Label / question
min, max		Minimum and maximum slider values
steps			How many steps between min and max
default			Where the slider should start
ticks			(1) display tick marks, (0) no tick marks
	
]]--

-- Knob - New.
GUI.Knob = GUI.Element:new()
function GUI.Knob:new(z, x, y, w, caption, min, max, steps, default, ticks)
	
	local Knob = {}
	Knob.type = "Knob"
	
	Knob.z = z
	
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
function GUI.Knob:onwheel()

	local ctrl = GUI.mouse.cap&4==4
	
	-- How many steps per wheel-step
	local fine = 1
	local coarse = math.max( GUI.round(self.steps / 30), 1)

	local adj = ctrl and fine or coarse
	
	self.curval = self.curval + GUI.mouse.inc * adj / self.steps
	
	if self.curval < 0 then self.curval = 0 end
	if self.curval > 1 then self.curval = 1 end

	self.curstep = GUI.round(self.curval * self.steps)
	
	self:val()

end



--[[	Radio class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.	
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and each option

]]--

-- Radio - New.
GUI.Radio = GUI.Element:new()
function GUI.Radio:new(z, x, y, w, h, caption, opts, pad)
	
	local opt_lst = {}
	opt_lst.type = "Radio"
	
	opt_lst.z = z
	
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
function GUI.Radio:onwheel()
	
	self.state = self.state - GUI.mouse.inc
	
	if self.state < 1 then self.state = 1 end
	if self.state > self.numopts then self.state = self.numopts end
	
	self.retval = self.state
	
end



--[[	Checklist class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.	
x, y			Coordinates of top-left corner
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
dir				"h" lays the options out to the right, "v" downward
pad				Padding between the caption and each option


]]--

-- Checklist - New
GUI.Checklist = GUI.Element:new()
function GUI.Checklist:new(z, x, y, caption, opts, dir, pad)
	
	local chk = {}
	chk.type = "Checklist"
	
	chk.z = z
	
	chk.x, chk.y = x, y
	
	-- constant for the square size
	chk.chk_w = 20

	chk.caption = caption
	
	chk.dir = dir
	
	chk.pad = pad

	chk.f_color = "elm_fill"

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
	
	--[[
		-- Figure out the total size of the Tab now that we know the number of buttons
	-- Necessary so we can do the math for clicking on it
	Tab.w, Tab.h = 
		table.unpack(Tab.dir == "h" 
			and { (w + pad) * Tab.numopts, h }
			or  { w, (h + pad) * Tab.numopts }
		)
	]]--
	
	-- Work out the total size of the checklist now that we have the number of options
	-- Necessary
	chk.w, chk.h =
		table.unpack(chk.dir == "h"
			and { (chk.chk_w + pad) * chk.numopts, chk.chk_w}
			or	{ chk.chk_w, (chk.chk_w + pad) * chk.numopts}
		)
				
	
	setmetatable(chk, self)
    self.__index = self 
    return chk
	
end


-- Checklist - Draw
function GUI.Checklist:draw()

	local x, y, w, h = self.x, self.y, self.w, self.h

	local dir = self.dir
	local pad = self.pad
	local f_color = self.f_color
	
	-- Draw the element frame
	
	if self.caption ~= "" then
		
		GUI.color("elm_frame")
		gfx.rect(x, y, w, h, 0)
		
		GUI.font(2)
	
		-- Draw the caption
		local str_w, str_h = gfx.measurestr(self.caption)
		self.capheight = str_h
		gfx.x = x + (w - str_w) / 2
		gfx.y = y
		GUI.shadow(self.caption, "txt", "shadow")	
	
	end	


	-- Draw the options
	GUI.color("txt")

	local size = self.chk_w
	
	local x_adj, y_adj = table.unpack(dir == "h" and { (size + pad), 0 } or { 0, (size + pad) })
	
	GUI.font(self.font or 3)

	for i = 1, self.numopts do
		
		local str = self.optarray[i]
		
		if str ~= "__" then
		
			local chk_x, chk_y = x + (i - 1) * x_adj, y + (i - 1) * y_adj
			
			-- Draw the option frame
			GUI.color("elm_frame")
			gfx.rect(chk_x, chk_y, size, size, 0)
					
			-- Fill in if selected
			if self.optsel[i] == true then
				
				GUI.color(f_color)
				gfx.rect(chk_x + size * 0.25, chk_y + size * 0.25, size / 2, size / 2, 1)
			
			end
		
			
			local str_w, str_h = gfx.measurestr(self.optarray[i])
			local swap = self.swap
			
			if dir == "h" then
				if not swap then
					gfx.x, gfx.y = chk_x + (size - str_w) / 2, chk_y - size
				else
					gfx.x, gfx.y = chk_x + (size - str_w) / 2, chk_y + size + 4
				end
			else
			if not swap then
				gfx.x, gfx.y = chk_x + 1.5 * size, chk_y + (size - str_h) / 2
			else
				gfx.x, gfx.y = chk_x - str_w - 8, chk_y + (size - str_h) / 2
				end
			end
	
		
			if self.numopts == 1 then
				GUI.shadow(self.optarray[i], "txt", "shadow")
			else
				GUI.color("txt")
				gfx.drawstr(self.optarray[i])
			end
		end
		
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
	local mouseopt = self.dir == "h" and ((GUI.mouse.x - self.x + self.pad / 2) / self.w) or ((GUI.mouse.y - self.y + self.pad / 2) / self.h)

	mouseopt = math.floor(mouseopt * self.numopts) + 1
	
	-- Make that the current option
	
	self.optsel[mouseopt] = not self.optsel[mouseopt] 
	
	--self:val()
	
end



--[[	Button class. Adapted from eugen2777's simple GUI template.

	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y, w, h		Coordinates of top-left corner, width, height
caption			Label / question
func			Function to perform when clicked
...				If provided, any parameters to pass to that function

Add afterward:
r_func			Function to perform when right-clicked
r_params		If provided, any parameters to pass to that function
]]--

-- Button - New
GUI.Button = GUI.Element:new()
function GUI.Button:new(z, x, y, w, h, caption, func, ...)

	local Button = {}
	Button.type = "Button"
	
	Button.z = z
	
	Button.x, Button.y, Button.w, Button.h = x, y, w, h

	Button.caption = caption
	
	Button.font = 4
	
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
	
	-- Draw an outline
	GUI.color("elm_outline")
	GUI.roundrect(x + 2 * state, y + 2 * state, w, h, 8, 1, 0)
	
	
	-- Draw the caption
	GUI.color("txt")
	GUI.font(self.font)	
	
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


-- Button - Execute (extra method)
-- Used for allowing hotkeys to press a button
function GUI.Button:exec(r)
	
	if r then
		self.r_func(table.unpack(self.r_params))
	else
		self.func(table.unpack(self.params))
	end
	
end


--[[	Textbox class. Adapted from schwa's example code.
	
	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y, w, h		Coordinates of top-left corner, width, height
caption			Text to display to the left of the textbox
pad				Padding between the left side and first character.

	
]]--

-- Textbox - New
GUI.Textbox = GUI.Element:new()
function GUI.Textbox:new(z, x, y, w, h, caption, pad)
	
	local txt = {}
	txt.type = "Textbox"
	
	txt.z = z
	
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
	gfx.x = x - str_w - pad
	gfx.y = y
	GUI.shadow(caption, "txt", "shadow")
	
	-- Draw the textbox frame, and make it brighter if focused.
	
	GUI.color("elm_bg")
	gfx.rect(x, y, w, h, 1)
	
	if focus then 
				
		GUI.color("elm_fill")
		gfx.rect(x + 1, y + 1, w - 2, h - 2, 0)
		
	else
		
		-- clear the selection while we're here
		sel = 0
		
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

			GUI.color("txt")
			gfx.rect(caret_x, y + 4, 2, h - 8)
			
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
	--self.focus = GUI.IsInside(self, x, y)
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
function GUI.Textbox:ontype()

	GUI.font(3)
	
	local char = GUI.char
	local caret = self.caret
	local text = self.retval
	local maxlen = gfx.measurestr(text) >= (self.w - (self.pad * 3))
	

	-- Is there text selected?
	if self.sel ~= 0 then
		
		-- Delete the selected text
		local sel_start, sel_end = caret, caret + self.sel
		if sel_start > sel_end then sel_start, sel_end = sel_end, sel_start end
		
		text = string.sub(text, 0, sel_start)..string.sub(text, sel_end + 1)
		
		self.caret = sel_start
		
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



--[[	MenuBox class
	
	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
pad				Padding between the caption and the box
	
]]--
GUI.Menubox = GUI.Element:new()
function GUI.Menubox:new(z, x, y, w, h, caption, opts, pad)
	
	local menu = {}
	menu.type = "Menubox"
	
	menu.z = z
	
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
	local val = self.retval
	local text = type(self.optarray[val]) == "table" 
					and self.optarray[val][1] 
					or self.optarray[val]

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
	gfx.x = x + 4
	gfx.y = y + (h - str_h) / 2
	gfx.drawstr(text)
	
end


-- Menubox - Get/set value
function GUI.Menubox:val(newval)
	
	if newval then
		self.retval = newval
	else
		return math.floor(self.retval)
	end
	
end


-- Menubox - Mouse up
function GUI.Menubox:onmouseup()
	
	local menu_str = ""
	
	for i = 1, self.numopts do
		if i == self.curopt then menu_str = menu_str .. "!" end
		menu_str = menu_str .. (type(self.optarray[i]) == "table" and self.optarray[i][1] or self.optarray[i]) .. "|"
	end
	
	--gfx.x = self.x
	--gfx.y = self.y + self.h
	gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y
	
	local curopt = gfx.showmenu(menu_str)
	if curopt ~= 0 then self.retval = curopt end
	self.focus = false
end


-- Menubox - Mousewheel
function GUI.Menubox:onwheel()
	
	local curopt = self.retval - GUI.mouse.inc
	
	if curopt < 1 then curopt = 1 end
	if curopt > self.numopts then curopt = self.numopts end
	
	self.retval = curopt
	
end


--[[	Frame class
	
	
]]--
GUI.Frame = GUI.Element:new()
function GUI.Frame:new(z, x, y, w, h, shadow, fill, color, round)
	
	local Frame = {}
	Frame.type = "Frame"
	
	Frame.z = z
	
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
	


--[[	Tabframe class
caption		does nothing ATM
dir			"h" or "v"


z_sets are defined like so:

GUI.elms.tabs_blah:update_sets(
	{
			   __ z-levels shown on that tab
	  __ tab  /
	 /		  |
	 |		  v
	 v     
	[1] = {2, 3, 4}, 
	[2] = {2, 5, 6}, 
	[3] = {2, 7, 8},
	}
)

- z-levels not included in any set (set 1, above) will always be active unless frozen/hidden manually
- z-levels in multiple sets (set 2, above) will be active on all of those tabs
- Elements can have their .z changed, handy if you want to hide specific bits rather than the whole layer


]]--
GUI.Tabframe = GUI.Element:new()
function GUI.Tabframe:new(z, x, y, w, h, caption, opts, pad)
	
	local Tab = {}
	Tab.type = "Tabframe"
	
	Tab.z = z
	
	Tab.x, Tab.y = x, y
	Tab.btn_w, Tab.btn_h = w, h

	Tab.caption = caption
	
	Tab.font_A, Tab.font_B = 3, 4
	
	Tab.dir = dir or "h"
	
	Tab.pad = pad
	
	-- Parse the string of options into a table
	Tab.optarray = {}
	local tempidx = 1
	for word in string.gmatch(opts, '([^,]+)') do
		Tab.optarray[tempidx] = word
		tempidx = tempidx + 1
	end
	
	Tab.numopts = tempidx - 1
	
	Tab.z_sets = {}
	for i = 1, Tab.numopts do
		Tab.z_sets[i] = {}
	end
	
	-- Figure out the total size of the Tab now that we know the number of buttons
	-- Necessary so we can do the math for clicking on it
	Tab.w, Tab.h = 
		table.unpack(Tab.dir == "h" 
			and { (w + pad) * Tab.numopts, h }
			or  { w, (h + pad) * Tab.numopts }
		)

	-- Currently-selected option
	Tab.retval, Tab.state = 1, 1

	setmetatable(Tab, self)
	self.__index = self
	return Tab

end


function GUI.Tabframe:update_sets(init)
	
	
	local state = self.state
	
	if init then
		self.z_sets = init
		GUI.elms_hide = GUI.elms_hide or {}
	end
	
	local z_sets = self.z_sets	
	for i = 1, #z_sets do
		
		if i ~= state then
			for tab, z in pairs(z_sets[i]) do
		
				GUI.elms_hide[z] = true
				
			end
		end
	end
	
	for tab, z in pairs(z_sets[state]) do
		
		GUI.elms_hide[z] = false
		
	end
	
end


function GUI.Tabframe:draw_tab(x, y, w, h, dir, font, col_txt, col_bg, lbl)

	local dist = GUI.shadow_dist

	GUI.color("shadow")
	
	for i = 1, dist do
		
		gfx.rect(x + i, y, w, h, true)
		
		gfx.triangle(x + i, y, x + i, y + h, x + i - (h / 2), y + h)
		gfx.triangle(x + i + w, y, x + i + w, y + h, x + i + w + (h / 2), y + h)
		
	end

	-- Hide those gross, pixellated edges
	gfx.line(x + dist, y, x + dist - (h / 2), y + h, 1)
	gfx.line(x + dist + w, y, x + dist + w + (h / 2), y + h, 1)

	GUI.color(col_bg)

	gfx.rect(x, y, w, h, true)
	
	gfx.triangle(x, y, x, y + h, x - (h / 2), y + h)
	gfx.triangle(x + w, y, x + w, y + h, x + w + (h / 2), y + h)
	
	gfx.line(x, y, x - (h / 2), y + h, 1)
	gfx.line(x + w, y, x + w + (h / 2), y + h, 1)
	
	
	-- Draw the tab's label
	GUI.color(col_txt)
	GUI.font(font)
	
	local str_w, str_h = gfx.measurestr(lbl)
	gfx.x = x + ((w - str_w) / 2)
	gfx.y = y + ((h - str_h) / 2) - 2 -- Don't include the bit we drew under the frame
	gfx.drawstr(lbl)	
	--gfx.line(x, y, x - (h / 2), y + h, 1)
	--gfx.line(x + w, y, x + w + (h / 2), y + h, 1)

end


function GUI.Tabframe:draw()
	
	local x, y, w, h = self.x, self.y + 2, self.btn_w, self.btn_h
	local pad = self.pad
	local font = self.font_B
	local dir = self.dir
	local state = self.state
	local optarray = self.optarray

	GUI.color("elm_bg")
	gfx.rect(0, 0, gfx.w, h, true)
			
	local x_adj, y_adj = table.unpack(dir == "h" and { (w + pad), 0 } or { 0, (h + pad) })
	
	-- Draw the buttons
	for i = self.numopts, 1, -1 do

		if i ~= state then
			--											  v-- Add a slight perspective effect to the bg tabs
			local btn_x, btn_y = x + (i - 1) * x_adj, y + GUI.shadow_dist + (i - 1) * y_adj

			self:draw_tab(btn_x, btn_y, w, h, dir, font, "txt", "tab_bg", optarray[i])

		end
	
	end
	
	-- Draw a line across the bottom of the inactive tabs for depth
	GUI.color("elm_outline")
	gfx.line(x - (h / 2), self.y + h - 1, x + (x_adj * self.numopts), self.y + h - 1)

	self:draw_tab(x + (state - 1) * x_adj, y + (state - 1) * y_adj, w, h, dir, self.font_A, "txt", "wnd_bg", optarray[state])

	-- Draw the frame
	GUI.color("wnd_bg")		
	gfx.rect(0, self.y + h, gfx.w, 6, true)


	
end


-- Tabframe - Mouse down.
function GUI.Tabframe:onmousedown()
			
	--See which option it's on
	local mouseopt = (self.dir == "h") and ((GUI.mouse.x - self.x) / self.w) or ((GUI.mouse.y - self.y) / self.h)
	--local adj_y = self.y + self.capheight + self.pad
	--local adj_h = self.h - self.capheight - self.pad
	--local mouseopt = (GUI.mouse.y - adj_y) / adj_h
		
	mouseopt = math.floor(mouseopt * self.numopts) + 1

	self.state = mouseopt
	
end


-- Tabframe - Mouse up
function GUI.Tabframe:onmouseup()
		
	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		self.retval = self.state
		
		self:update_sets()
		
	else
		self.state = self.retval	
	end
	
end


-- Tabframe - Dragging
function GUI.Tabframe:ondrag() 

	self:onmousedown()

end


-- Tabframe - Mousewheel
function GUI.Tabframe:onwheel()
	--[[
	self.state = self.state + (dir == "h" and GUI.mouse.inc or -GUI.mouse.inc)
	
	if self.state < 1 then self.state = 1 end
	if self.state > self.numopts then self.state = self.numopts end
	
	self.retval = self.state
	]]--
end





-- Make our table full of functions available to the parent script
return GUI

end
GUI = GUI_table()

----------------------------------------------------------------
----------------------------To here-----------------------------
----------------------------------------------------------------

---- End of file: Lokasenna_GUI library beta 7.lua ----

---- End of libraries ----

 
 
Alternatively, it can look for filenames called by a user-defined function, req(), like so:

req("Core.lua")()
 
In this case, Script Compiler will look for the given file name/path relative to the script being 
compiled, or in a separate folder as specified in the Options tab.
 
Either way, make sure the library is set up so that copy/pasting it will work.
  
]=]

local thread_URL = [[http://forum.cockos.com/showthread.php?t=185264]]
local donate_URL = [[https://www.paypal.me/Lokasenna]]


local base_file_path = ""
local base_folder = ""
local base_file = {}
local base_file_compiled = {}
local reqs_start, reqs_end = 0, 0
local req_file_paths = {}
local req_file = {}
local new_file_path = ""


-- So we can tell if anything has been changed
local prev_base_file = ""
local prev_optsel = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local prev_file_out = ""


------------------------------------
-------- Loading + Parsing ---------
------------------------------------


-- Read through the file to find any requirements
local function parse_reqs(file)
	
	base_file = {}
	local paths = {}
	local line_num = 1
	reqs_start, reqs_end = 0, 0				
	
	for line in file:lines() do
		
		table.insert(base_file, line)

		if line:match("REQUIRES START") and reqs_start == 0 then
			reqs_start = line_num

		elseif line:match("!!REQUIRES END") and reqs_end == 0 then
			reqs_end = line_num

		elseif (line:match('%-%-!!REQUIRE ".+%.lua"') 
			or line:match('^req%(')) and reqs_end == 0 then
		
			-- Trim this line down to just the file path and name
			local file_path = line:match("\"(.+)\"") or ""
			file_path = string.gsub(file_path, [[\\]], [[\]])
			table.insert(paths, {["line_num"] = line_num, ["path"] = file_path})

		end
	
	line_num = line_num + 1
	
	end
	
	if #paths < 1 then
		reaper.ShowMessageBox("No library requirements found.", "Whoops", 0)
		return
	end

	if reqs_start == 0 then	reqs_start = paths[1].line_num end
	if reqs_end == 0 then reqs_end = paths[#paths].line_num end
	
	return paths
	
end


-- Trim the Requires table down to just filenames for displaying in the checklist
local function get_req_filenames()
	
	for i = 1, #req_file_paths do
	
		local line = req_file_paths[i].path	

		line = (string.len(line) > 46) and ("..."..string.sub(line, string.len(line) - 46)) or line
		GUI.elms.chk_reqs.optarray[i] = line
		GUI.elms.chk_reqs.optsel[i] = true
		
		GUI.elms.chk_reqs.retval = GUI.elms.chk_reqs.optsel
		GUI.elms.chk_reqs.numopts = #GUI.elms.chk_reqs.optarray

	end
	
end


-- Resize the window to fit the length of the required file checklist
local function fit_wnd_to_reqs()	

	local d, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
	local chk_h = (#req_file_paths * 24)
	local y_adj = GUI.elms.chk_reqs.y + chk_h + 24
	h = math.max( y_adj + 96 , GUI.h )

	if h ~= GUI.h then
		GUI.elms.lbl_save.y = y_adj
		GUI.elms.txt_save.y = y_adj + 20
		GUI.elms.btn_go.y = y_adj + 56

		gfx.quit()
		gfx.init(GUI.name, w, h, 0, x, y)
	end
	
	-- Adjust the Checklist's internal width and height while we're here
	GUI.elms.chk_reqs.w = w - GUI.elms.chk_reqs.x
	GUI.elms.chk_reqs.h = chk_h
	
end


-- Load a script and parse it for required files
local function load_base_file()
	
	__, base_file_path = reaper.GetUserFileNameForRead("", "Choose a .lua script", ".lua")
	
	local file = io.open(base_file_path) or nil
	
	-- Read the base file into memory, and find all of the REQUIRE lines
	if file then
		
		local path_lbl = (string.len(base_file_path) > 40) and string.sub(base_file_path, string.len(base_file_path) - 40) or base_file_path
		
		GUI.Val("lbl_base_file", "( ..."..path_lbl.." )")
		
		base_folder = string.match(base_file_path, "(.+[\\/])[^\\/]+") or ""
		
		-- Parse the base file for requirements
		req_file_paths = parse_reqs(file)
		if not req_file_paths or #req_file_paths == 0 then return 0 end
		
		-- Reset the checklist
		GUI.elms.chk_reqs = GUI.Checklist:new(	2,	16, 96, "", "", "v", 4)
		
		-- Populate it with the reqs' filenames
		get_req_filenames()
		
		-- Resize the window to fit the length of the req checklist
		fit_wnd_to_reqs()
		
		-- Suggest a default name for the output file	
		local slash_index = string.find(base_file_path, "[/\\][^/\\]*$") + 1
		local file_name = string.sub(base_file_path, slash_index)
		local ext_idx = string.find(file_name, ".lua") - 1
		local suff = GUI.Val("txt_suff")
		if suff ~= "" then suff = " "..suff end
		local default_out = GUI.Val("txt_pref")..string.sub(file_name, 1, ext_idx)..suff..".lua"
		GUI.Val("txt_save", default_out)
		
		io.close(file)
	
	end
	
end


------------------------------------
-------- Compiling -----------------
------------------------------------


-- Copy the required files' contents into one table
local function compile_reqs()
	
	local all_reqs = {}
	
	for i = 1, #req_file_paths do
	
		if GUI.Val("chk_reqs")[i] == true then

			local line_num, path = req_file_paths[i].line_num, req_file_paths[i].path

			if string.sub(path, 2, 2) == ":" then
			else
				if string.sub(path, 1, 1) == "\\" or string.sub(path, 1, 1) == "/" then
					path = string.sub(path, 2)
				end
			end
			
			if reaper.file_exists(path) then
				file = io.open(path) or nil
			elseif reaper.file_exists(GUI.Val("txt_notfound")..path) then
				file = io.open(GUI.Val("txt_notfound")..path) or nil
			else
				reaper.ShowMessageBox( "Couldn't find library file:\n"..path, "Library not found", 0)
				__, path = reaper.GetUserFileNameForRead("", "Library not found", ".lua")
				file = io.open(path) or nil
			end
			
			
			if file then 
				
				table.insert(all_reqs, "\n\n---- Beginning of file: "..path.." ----\n")
				
				for line in file:lines() do
					table.insert(all_reqs, line)
				end
				
				table.insert(all_reqs, "\n---- End of file: "..path.." ----\n")
			end
			io.close(file)
	
			
		end
		
	end
	
	return all_reqs
	
end


-- Write the compiled script to the output file
local function write_to_file()
	
	local slash_index = string.find(base_file_path, "[/\\][^/\\]*$")
	local base_path = string.sub(base_file_path, 1, slash_index)	
	
	-- Create the output file
	local path_out = GUI.Val("txt_save")	
	if string.sub(path_out, 1, 1) == "\\" or string.sub(path_out, 1, 1) == "/" then
		path_out = string.sub(path_out, 2)
	end

	local path = string.match(path_out, "^(.+\\)") 
	
	-- Reaper 5.78 is giving inconsistent return values for this function, so the
	-- folder check is disabled for now.

	local ret = path and reaper.RecursiveCreateDirectory(base_path..path, 0)	
	--if not ret or ret == 0 then
	--	reaper.ShowMessageBox("Couldn't create the output folder. Maybe a permission issue?", "Oops", 0)
	--	return
	--end

	local file_out = io.open(base_path..path_out, "w+")
	if not file_out then
		reaper.ShowMessageBox("Couldn't create specified file. Check the the folder exists, and that there aren't any permission issues.", "Oops", 0)
		return
	end
	
	
	-- Write the compiled script into the output file
	for i = 1, #base_file_compiled do
	
		-- Look for any optional tags and insert them
		-- Should probably be written as its own function with a table of tags to look for
		
		if string.match(base_file_compiled[i], "2.0.1") then
			
			local ver
			for i = 1, reqs_start do
				
				ver = string.match(base_file[i], "Version: (.*)")
				if ver then break end
				
			end
			
			ver = ver or "(no version number found)"
			
			base_file_compiled[i] = string.gsub(base_file_compiled[i], "2.0.1", tostring(ver))
			
		end		

		file_out:write(base_file_compiled[i].."\n")
	end
	file_out:close()	
	
end


local function compile_script()
	
	if #base_file == 0 then return 0 end

	local compiled_reqs = compile_reqs()
	
	-- Make a copy of base_file we can mess with
	base_file_compiled = GUI.table_copy(base_file)

	-- Clear the Reqs section from the base file
	-- Going backwards to keep the line numbers from being messed up
	for i = reqs_end, reqs_start, -1 do
		table.remove(base_file_compiled, i)
	end	

	-- Add a couple of watermarks
	table.insert(compiled_reqs, 1, "---- Libraries added with Lokasenna's Script Compiler ----\n")
	table.insert(compiled_reqs, "---- End of libraries ----\n")

	-- Insert the compiled requirements into the base script
	for i = 1, #compiled_reqs do
		table.insert(base_file_compiled, reqs_start + i - 1, compiled_reqs[i])
	end

	
	-- Write our compiled script to disk
	write_to_file()
	
	
	-- Tell the user we're finished
	local y = GUI.elms.btn_go.y - 6
	GUI.elms.lbl_done = GUI.Label:new(1,	128, y, "Done!", 0, 1)
	GUI.elms.lbl_done.fade = {2, reaper.time_precise(), "lbl_done"}
	
	prev_base_file = base_file_path
	prev_file_out = GUI.Val("txt_save")
	prev_optsel = GUI.table_copy(GUI.elms.chk_reqs.optsel)
	
	-- Open the text editor if the user wants us to
	if GUI.Val("chk_open")[1] then

		reaper.CF_ShellExecute(base_path..path_out)
		
	end
	
	
end


------------------------------------
-------- Helpers -------------------
------------------------------------


local function browse_for_path()
	
	local __, path = reaper.GetUserFileNameForRead("", "Choose a file in the target folder", "")
	
	if path == "" then return 0 end
	
	local slash_index = string.find(path, "[/\\][^/\\]*$")
	path = string.sub(path, 1, slash_index)
	
	GUI.Val("txt_notfound", path)
	
end


local function save_states()
	
	reaper.SetExtState(GUI.name, "library path", GUI.Val("txt_notfound"), 1)
	reaper.SetExtState(GUI.name, "default prefix", GUI.Val("txt_pref"), 1)
	reaper.SetExtState(GUI.name, "default suffix", GUI.Val("txt_suff"), 1)
	local chk_state = GUI.Val("chk_open")
	reaper.SetExtState(GUI.name, "open text editor", tostring(chk_state[1]), 1)
	
end


local function load_states()
	
	GUI.Val("txt_notfound", reaper.GetExtState(GUI.name, "library path"))
	GUI.Val("txt_pref", reaper.GetExtState(GUI.name, "default prefix"))
	GUI.Val("txt_suff", reaper.GetExtState(GUI.name, "default suffix"))
		
	local chk_state = reaper.GetExtState(GUI.name, "open text editor")
	if chk_state == nil or chk_state == "" or chk_state == "false" then chk_state = false else chk_state = true end
	GUI.Val("chk_open", chk_state)

end


------------------------------------
-------- GUI Elements --------------
------------------------------------


--[[	Classes and parameters
	(see comments in LS GUI.lua for more thorough documentation)

	Tabframe	z	x y w h caption		tabs	pad
	Frame		z	x y w h[shadow		fill	color	round]
	Label		z	x y		caption		shadow	font
	Button		z	x y w h caption		func	...
	Radio		z	x y w h caption 	opts	pad
	Checklist	z	x y w h caption 	opts	dir		pad
	Knob		z	x y w	caption 	min 	max		steps	default		ticks
	Slider		z	x y w	caption 	min 	max 	steps 	default
	Range		z	x y w	caption		min		max		steps 	default_a 	default_b
	Textbox		z	x y w h	caption		pad
	Menubox		z	x y w h caption		opts	pad

]]--

GUI.elms = {
	
	tabs = GUI.Tabframe:new(		7,	16, 0, 64, 22, "", "Compile,Options,Help", 8),


	---- Tab 1: Compile ----
	btn_load_scr = GUI.Button:new(	2,	16, 32, 80, 22, "Load script", load_base_file),
	lbl_base_file = GUI.Label:new(	2,	104, 32, "( open a .lua file )", 0, 2),
	lbl_reqs = GUI.Label:new(		2,	32, 64, "Required files:", 1, 2),
	lbl_save = GUI.Label:new(		2,	16, 496, "Save compiled script as:", 0, 2),
	txt_save = GUI.Textbox:new(		2,	16, 528, 568, 22, "", 4),
	btn_go = GUI.Button:new(		2,	32, 560, 80, 22, "Go!", compile_script),
	
	
	---- Tab 2: Options ----
	lbl_notfound = GUI.Label:new(	3,	32, 32, "If libraries aren't found relative to the base script's folder, look for them in:", 0, 2),
	txt_notfound = GUI.Textbox:new(	3,	16, 56, 568, 22, "", 4),
	lbl_load_lib = GUI.Label:new(	3,	120, 92, "(Due to API limitations, please choose a FILE in the library folder)", 0, 4),
	btn_load_lib = GUI.Button:new(	3,	32, 88, 80, 22, "Browse", browse_for_path),
	
	frm_defaults = GUI.Frame:new(	4,	8, 128, 584, 96, false, false, "elm_frame", 0),
	lbl_defaults = GUI.Label:new(	3,	32, 136, "Default formatting for output filename", 0, 2),
	
	lbl_pref = GUI.Label:new(		3,	16, 168, "Folder/prefix:", 0, 3),
	txt_pref = GUI.Textbox:new(		3,	16, 184, 192, 22, "", 4),
	lbl_myscr = GUI.Label:new(		3,	214, 187, "my_new_script", 0, 3),
	lbl_suff = GUI.Label:new(		3,	302, 168, "Suffix:", 0, 3),
	txt_suff = GUI.Textbox:new(		3,	302, 184, 192, 22, "", 4),
	lbl_lua = GUI.Label:new(		3,	498, 187, ".lua", 0, 3),
	
	chk_open = GUI.Checklist:new(	3,	32, 236, "", "Open in text editor after compiling", "v", 4),
		
	
	---- Tab 3: Help ----
	lbl_help = GUI.Label:new(		5,	32, 40, help_str, 0, 4),
	--frm_code = GUI.Frame:new(		6,	16, 140, 568, 180, false, true, "elm_bg", 4),
	
	btn_thread = GUI.Button:new(	5,	48, 560, 96, 22, "Forum thread", GUI.open_file, thread_URL),
	btn_donate = GUI.Button:new(	5,	160, 560, 80, 22, "Donate", GUI.open_file, donate_URL),
	
}

GUI.elms.tabs:update_sets(
	{
	[1] = {2},
	[2] = {3, 4},
	[3] = {5, 6},
	}
)

GUI.elms.tabs.font_A = 6


------------------------------------
-------- Main ----------------------
------------------------------------


local function Main()
	--[[
		if any of these have changed, hide the Done! label:
			base file
			Req selection
			output file
			
			local prev_base_file = ""
			local prev_optsel = {}
			local prev_file_out = ""

	]]--
	
	local opts_changed = false
	if GUI.elms.chk_reqs then

		local optsel = GUI.elms.chk_reqs.optsel or {}

		for i = 1, #optsel do
			if optsel[i] ~= prev_optsel[i] then opts_changed = true end
		end	
	end
			
	if prev_base_file ~= base_file_path 
	or prev_file_out ~= GUI.Val("txt_save")
	or opts_changed == true

	then
		if GUI.elms.lbl_done then

			GUI.elms.lbl_done = nil
		end
	end
	
end


reaper.atexit(save_states)

load_states()

GUI.func = Main
GUI.freq = 0
GUI.Init()
GUI.Main()

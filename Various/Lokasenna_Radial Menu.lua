--[[
Description: Radial Menu 
Version: 2.7.4
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Fixed issue with shortcuts highlighting the wrong menu
        (Courtesy of AdmiralBumbleBee)
Links:
	Forum Thread http://forum.cockos.com/showthread.php?p=1788321
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Provides a circular "quick menu" for commonly-used actions, similar
	to how weapons are selected in many FPS games. 
	
	Use the accompanying script "Lokasenna_Radial Menu Setup.lua" to
	configure the menu and additional settings.
	
	See the forum thread for further documentation/bug reports/help.
Extensions:
Provides:
	[main] Lokasenna_Radial Menu/Lokasenna_Radial Menu Setup.lua > Lokasenna_Radial Menu Setup.lua
	Lokasenna_Radial Menu/Lokasenna_Radial Menu - example settings.txt > Lokasenna_Radial Menu - example settings.txt
--]]

-- Licensed under the GNU GPL v3

--[[
	Just to make debug messaging simpler:
	
	_=dm and Msg("debug stuff here")
	
	More efficient than calling another function and making it check
	
]]--

local reaper, gfx, string, table = reaper, gfx, string, table


local dm, _ = debug_mode
local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end


local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]

---- Libraries added with Lokasenna's Script Compiler ----



---- Beginning of file: Lokasenna_GUI library beta 8.lua ----

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



GUI.version = "beta 8"

-- Might want to know this
GUI.OS = reaper.GetOS()

--[[	Use when working with file paths if you need to add your own /s
		(Borrowed from X-Raym)	
]]--
GUI.file_sep = string.match(GUI.OS, "Win") and "\\" or "/"




-- Also might need to know this
GUI.SWS_exists = function ()
	
	local exists = reaper.APIExists("BR_Win32_GetPrivateProfileString")
	if not exists then reaper.ShowMessageBox( "This script requires the SWS extension.", "SWS not found", 0) end
	return exists
	
end


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
				{"Calibri", 32},	-- 1. Title
				{"Calibri", 20},	-- 2. Header
				{"Calibri", 16},	-- 3. Label
				{"Calibri", 16},	-- 4. Value
	version = 	{"Calibri", 12, "i"},
	
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
	
	shadow = {0, 0, 0, 80},			-- Shadow
	faded = {0, 0, 0, 64},
	
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
	local font, size, str = table.unpack( type(fnt) == "table" and fnt or GUI.fonts[fnt])
	
	
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


-- Start drawing with one of the colors from the table
GUI.color = function (col)

	-- If we're given a table of color values, just pass it right along
	if type(col) == "table" then

		gfx.set(col[1], col[2], col[3], col[4] or 1)
	else
		gfx.set(table.unpack(GUI.colors[col]))
	end	

end



-- Global shadow size, in pixels
GUI.shadow_dist = 2

--[[
	How fast the caret in textboxes should blink, measured in GUI update loops.
	
	'16' looks like a fairly typical textbox caret.
	
	Because each On and Off redraws the textbox's Z layer, this can cause CPU issues
	in scripts with lots of drawing to do. In that case, raising it to 24 or 32
	will still look alright but require less redrawing.
]]--
GUI.txt_blink_rate = 16


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

--[[
	Copy the contents of one table to another, since Lua can't do it natively
	
	Provide a second table as 'base' to use it as the basis for copying, only
	bringing over keys from the source table that don't exist in the base
	
	'depth' only exists to provide indenting for my debug messages, it can
	be left out when calling the function.
]]--
GUI.table_copy = function (source, base, depth)
	
	-- 'Depth' is only for indenting debug messages
	depth = ((not not depth) and (depth + 1)) or 0
	
	
	
	if type(source) ~= "table" then return source end
	
	local meta = getmetatable(source)
	local new = base or {}
	for k, v in pairs(source) do
		

		
		if type(v) == "table" then
			
			--_=dm and GUI.Msg(string.rep("\t", depth + 1)..tostring(k).." is a table; recursing...")
			
			if base then
				_=dm and GUI.Msg(string.rep("\t", depth).."base:\t"..tostring(k))
				new[k] = GUI.table_copy(v, base[k], depth)
			else
				new[k] = GUI.table_copy(v, nil, depth)
			end
			
		else
			if not base or (base and new[k] == nil) then 
				_=dm and GUI.Msg(string.rep("\t", depth).."added:\t"..tostring(k).." = "..tostring(v))		
				new[k] = v
			end
		end
		
		--_=dm and GUI.Msg(string.rep("\t", depth).."done with "..tostring(k))
	end
	setmetatable(new, meta)
	
	--_=dm and GUI.Msg(string.rep("\t", depth).."finished copying")
	
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


-- 	Sorting function taken from: http://lua-users.org/wiki/SortedIteration
GUI.full_sort = function (op1, op2)

	if type(op1) == "string" and string.match(op1, "^(%-?%d+)") then
		op1 = tonumber( string.match(op1, "^(%-?%d+)") )
	end
	if type(op2) == "string" and string.match(op2, "^(%-?%d+)") then
		op2 = tonumber( string.match(op2, "^(%-?%d+)") )
	end

	--if op1 == "0" then op1 = 0 end
	--if op2 == "0" then op2 = 0 end
	local type1, type2 = type(op1), type(op2)
	if type1 ~= type2 then --cmp by type
		return type1 < type2
	elseif type1 == "number" and type2 == "number"
		or type1 == "string" and type2 == "string" then
		return op1 < op2 --comp by default
	elseif type1 == "boolean" and type2 == "boolean" then
		return op1 == true
	else
		return tostring(op1) < tostring(op2) --cmp by address
	end
	
end


--[[
	Allows "for x, y in pairs(z) do" in alphabetical/numerical order
	Copied from Programming In Lua, 19.3
	
	Call with f = "full" to use the full sorting function above
	
]]--
GUI.kpairs = function (t, f)

	--GUI.Msg("kpairs start")

	if f == "full" then
		f = GUI.full_sort
	end

	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	--GUI.Msg("kpairs sorting")
	table.sort(a, f)
	--GUI.Msg("kpairs sorted")
	
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
	
		i = i + 1
		
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
		
	end
	
	--GUI.Msg("kpairs end")
	
	return iter
end



	---- Text functions ----


--[[	Preapres a table of character widths
	
	Iterates through all of the font presets, storing the widths
	of every printable ASCII character in a table. 
	
	Accessable via:		GUI.txt_width[font_num][char_num]
	
	- Requires a window to have been opened in Reaper
	
	- 'get_txt_width' and 'word_wrap' will automatically run this
	  if it hasn't been run already; it may be rather clunky to use
	  on demand depending on what your script is doing, so it's
	  typically better to run this immediately after initiliazing
	  the window and then have the width table ready to use.
]]--

GUI.init_txt_width = function ()

	_=dm and GUI.Msg("init_txt_width")

	GUI.txt_width = {}
	local arr
	for k in pairs(GUI.fonts) do
			
		GUI.font(k)
		GUI.txt_width[k] = {}
		arr = {}
		
		for i = 1, 255 do
			
			arr[i] = gfx.measurechar(i)
			
		end	
		
		GUI.txt_width[k] = arr
		
	end
	
end


-- Returns the total width (in pixels) for a given string and font
GUI.get_txt_width = function (str, font)
	
	if not GUI.txt_width then GUI.ini_txt_width() end 

	local widths = GUI.txt_width[font]
	local w = 0
	for i = 1, string.len(str) do

		w = w + widths[		string.byte(	string.sub(str, i, i)	) ]

	end

	return w

end


--[[	Wraps a string to fit a given width
	
	str		String. Can include line breaks/paragraphs; they should be preserved.
	font	Font preset number
	w		Pixel width
	indent	Number of spaces to indent the first line of each paragraph
			(The algorithm skips tab characters and leading spaces, so
			use this parameter instead)
	
	i.e.	Blah blah blah blah		-> indent = 2 ->	  Blah blah blah blah
			blah blah blah blah							blah blah blah blah

	
	pad		Indent wrapped lines by the first __ characters of the paragraph
			(For use with bullet points, etc)
			
	i.e.	- Blah blah blah blah	-> pad = 2 ->	- Blah blah blah blah
			blah blah blah blah				  	 	  blah blah blah blah
	
				
	This function expands on the "greedy" algorithm found here:
	https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap#Algorithm
				
]]--
GUI.word_wrap = function (str, font, w, indent, pad)
	
	_=dm and GUI.Msg("word wrap:\n\tfont "..tostring(font).."\n\twidth "..tostring(w).."\n\tindent "..tostring(indent))
	
	if not GUI.txt_width then GUI.ini_txt_width() end
	
	local ret_str = {}

	local w_left, w_word
	local space = GUI.txt_width[font][string.byte(" ")]
	
	local new_para = indent and string.rep(" ", indent) or 0
	
	local w_pad = pad and GUI.get_txt_width(	string.sub(str, 1, pad), font	) or 0
	local new_line = "\n"..string.rep(" ", math.floor(w_pad / space)	)
	
	
	for line in string.gmatch(str, "([^\n\r]*)[\n\r]*") do
		
		table.insert(ret_str, new_para)
		
		-- Check for leading spaces and tabs
		local leading, line = string.match(line, "^([%s\t]*)(.*)$")	
		if leading then table.insert(ret_str, leading) end
		
		w_left = w
		for word in string.gmatch(line,  "([^%s]+)") do
	
			-- Check for tab stops, since this function won't parse them properly
	
	
			w_word = GUI.get_txt_width(word, font)
			if (w_word + space) > w_left then
				
				table.insert(ret_str, new_line)
				w_left = w - w_word
				
			else
			
				w_left = w_left - (w_word + space)
				
			end
			
			table.insert(ret_str, word)
			table.insert(ret_str, " ")
			
		end
		
		table.insert(ret_str, "\n")
		
	end
	
	table.remove(ret_str, #ret_str)
	ret_str = table.concat(ret_str)
	
	return ret_str
			
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


-- Convert a hex color to 8-bit values r,g,b
GUI.hex2rgb = function (num)
	
	if string.sub(num, 1, 2) == "0x" then
		num = string.sub(num, 3)
	end

	local red = string.sub(num, 1, 2)
	local green = string.sub(num, 3, 4)
	local blue = string.sub(num, 5, 6)

	
	red = tonumber(red, 16) or 0
	green = tonumber(green, 16) or 0
	blue = tonumber(blue, 16) or 0

	return red, green, blue
	
end


-- Thanks to Heda for this one
GUI.num2rgb = function (num)
	
	r = num & 255
	g = (num >> 8) & 255
	b = (num >> 16) & 255
	
	return r, g, b
	
end


-- Convert rgb[a] to hsv[a]; useful for gradients
-- Provide the arguments as 0-1
GUI.rgb2hsv = function (r, g, b, a)
	
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local chroma = max - min
	
	-- Dividing by zero is never a good idea
	if chroma == 0 then
		return 0, 0, max, (a or 1)
	end
	
	local hue
	if max == r then
		hue = ((g - b) / chroma) % 6
	elseif max == g then
		hue = ((b - r) / chroma) + 2
	elseif max == b then
		hue = ((r - g) / chroma) + 4
	else
		hue = -1
	end
	
	if hue ~= -1 then hue = hue / 6 end
	
	local sat = (max ~= 0) 	and	((max - min) / max)
							or	0
							
	return hue, sat, max, (a or 1)
	
	
end

-- ...and back the other way
GUI.hsv2rgb = function (h, s, v, a)
	
	local chroma = v * s
	
	local hp = h * 6
	local x = chroma * (1 - math.abs(hp % 2 - 1))
	
	local r, g, b
	if hp <= 1 then
		r, g, b = chroma, x, 0
	elseif hp <= 2 then
		r, g, b = x, chroma, 0
	elseif hp <= 3 then
		r, g, b = 0, chroma, x
	elseif hp <= 4 then
		r, g, b = 0, x, chroma
	elseif hp <= 5 then
		r, g, b = x, 0, chroma
	elseif hp <= 6 then
		r, g, b = chroma, 0, x
	else
		r, g, b = 0, 0, 0
	end
	
	local min = v - chroma	
	
	return r + min, g + min, b + min, (a or 1)
	
end

--[[
	Returns the color for a given position on an HSV gradient between two colors

	col_a		Tables of {R, G, B[, A]}, values from 0-1
	col_b
	
	pos			Position along the gradient, 0 = col_a, 1 = col_b

]]--
GUI.gradient = function (col_a, col_b, pos)
	
	local col_a = {GUI.rgb2hsv(table.unpack(col_a))}
	local col_b = {GUI.rgb2hsv(table.unpack(col_b))}
	
	local h = math.abs(col_a[1] + (pos * (col_b[1] - col_a[1])))
	local s = math.abs(col_a[2] + (pos * (col_b[2] - col_a[2])))
	local v = math.abs(col_a[3] + (pos * (col_b[3] - col_a[3])))
	local a = (#col_a == 4) and (math.abs(col_a[4] + (pos * (col_b[4] - col_a[4])))) or 1
	
	return GUI.hsv2rgb(h, s, v, a)
	
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
	to Pi; that is, pi/4 rads would return as simply 0.25
]]--
GUI.cart2polar = function (x, y, ox, oy)
	
	local dx, dy = x - (ox or 0), y - (oy or 0)
	
	local angle = math.atan(dy, dx) / GUI.pi
	local r = math.sqrt(dx * dx + dy * dy)

	return angle, r
	
end


-- Are these coordinates inside the given element?
GUI.IsInside = function (elm, x, y)

	if not elm then return false end

	x, y = x or GUI.mouse.x, y or GUI.mouse.y

	local inside = 
			x >= elm.x and x < (elm.x + elm.w) and 
			y >= elm.y and y < (elm.y + elm.h)
		
	return inside
	
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
	
--[[
	
	Disabled until I can figure out the multi-monitor issue
	
	-- Make sure the window is entirely on-screen
	local l, t, r, b = x, y, x + w, y + h
	
	if l < 0 then x = 0 end
	if r > scr_w then x = (scr_w - w - 16) end
	if t < 0 then y = 0 end
	if b > scr_h then y = (scr_h - h - 40) end
]]--	
	
	return x, y	
	
end



	---- Z-layer blitting ----

-- On each draw loop, only layers that are set to true in this table
-- will be redrawn; if false, it will just copy them from the buffer
-- Set [0] = true to redraw everything.
GUI.redraw_z = {}



	---- Our main functions ----
	
-- Maintain a list of all GUI elements, sorted by their z order	
-- Also removes any elements with z = -1, for automatically
-- cleaning things up.
GUI.update_elms_list = function (init)
	
	local z_table = {}
	if init then 
		GUI.elms_list = {}
		GUI.z_max = 0 
	end

	for key, __ in pairs(GUI.elms) do

		local z = GUI.elms[key].z or 5

		-- Delete elements if the script asked to
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
	--gfx.clear = GUI.rgb2num(table.unpack(GUI.colors.wnd_bg))
	gfx.clear = reaper.ColorToNative(table.unpack(GUI.colors.wnd_bg))
	
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
	GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y
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


	--GUI.mouse.down = false
	--GUI.mouse.r_down = false

--[[
	Update each element's state, starting from the top down.
	
	This is very important, so that lower elements don't
	"steal" the mouse.
	
	
	This function will also delete any elements that have their z set to -1

	Handy for something like Label:fade if you just want to remove
	the faded element entirely
	
	***Don't try to remove elements in the middle of the Update
	loop; use this instead to have them automatically cleaned up***	
	
]]--
	GUI.update_elms_list()
	
	-- We'll use this to shorten each elm's update loop if the user did something
	-- Slightly more efficient, and averts any bugs from false positives
	GUI.elm_updated = false

	for i = 0, GUI.z_max do
		if #GUI.elms_list[i] > 0 and not (GUI.elms_hide[i] or GUI.elms_freeze[i]) then
			for __, elm in pairs(GUI.elms_list[i]) do

				if elm then GUI.Update(GUI.elms[elm]) end
				--if GUI.elm_updated then break end
				
			end
		end
		
		--if GUI.elm_updated then break end
		
	end

	-- Just in case any user functions want to know...
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

	local w, h = gfx.w, gfx.h

	--[[
		Having everything draw to a single buffer is less efficient than having
		separate buffers per Z, but it gets around the problem of text looking shitty
		because it's been anti-aliased with a transparent background.
	]]--

	local need_redraw = false
	if GUI.redraw_z[0] then
		need_redraw = true
	else
		for z, b in pairs(GUI.redraw_z) do
			if b == true then need_redraw = true end
		end
	end

	if need_redraw then
		
		-- Clear the table before drawing so elements can force a redraw
		-- in their own :draw methods - for Label:fade(), particularly
		for z, v in pairs(GUI.redraw_z) do
			GUI.redraw_z[z] = nil
		end		
		
		gfx.dest = 0
		gfx.setimgdim(0, -1, -1)
		gfx.setimgdim(0, w, h)

		GUI.color("wnd_bg")
		gfx.rect(0, 0, w, h, 1)

		for i = GUI.z_max, 0, -1 do
			if #GUI.elms_list[i] > 0 and not GUI.elms_hide[i] then
				
				-- This stuff is for blitting individual z layers
				-- Disabled until I figure out a solution for the antialiased text issue
				
				--*if GUI.redraw_z[i] then
					
					-- Set this before we redraw, so that elms can call a redraw themselves
					-- e.g. Labels fading out
					--*GUI.redraw_z[i] = false

					--*gfx.setimgdim(i, -1, -1)
					--*gfx.setimgdim(i, w, h)
					--*gfx.dest = i
					for __, elm in pairs(GUI.elms_list[i]) do
						if not GUI.elms[elm] then GUI.Msg(elm.." doesn't exist?") end
						GUI.elms[elm]:draw()
					end

					--*gfx.dest = -1
				--*end
							
				-- --gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
				--*gfx.blit(i, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
			end
		end
		GUI.Draw_Version()		
		
	end
	gfx.dest = -1
	gfx.blit(0, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
	
	gfx.update()
	
end


--	See if the any of the given element's methods need to be called
GUI.Update = function (elm)
	
	local x, y = GUI.mouse.x, GUI.mouse.y
	local wheel = GUI.mouse.wheel
	local inside = GUI.IsInside(elm, x, y)
	
	local skip = elm:onupdate() or false
	
	if GUI.elm_updated then
		if elm.focus then
			elm.focus = false
			elm:lostfocus()
		end
		skip = true
	end


	if not skip then
		
		-- Left button
		if GUI.mouse.cap&1==1 then
			
			-- If it wasn't down already...
			if not GUI.mouse.last_down then


				-- Was a different element clicked?
				if not inside then 
					if elm.focus then
						elm.focus = false
						elm:lostfocus()
					end
					return 0
				else	
				
					-- Double clicked?
					if GUI.mouse.downtime and os.clock() - GUI.mouse.downtime < 0.10 then
	
						GUI.mouse.downtime = nil
						GUI.mouse.dbl_clicked = true
						elm:ondoubleclick()						
						
					elseif not GUI.mouse.dbl_clicked then
				
						elm.focus = true
						elm:onmousedown()						
					
					end
					
					GUI.mouse.down = true
					GUI.mouse.ox, GUI.mouse.oy = x, y
					GUI.elm_updated = true
					
				end
							
			-- 		Dragging? 									Did the mouse start out in this element?
			elseif (x ~= GUI.mouse.lx or y ~= GUI.mouse.ly) and GUI.IsInside(elm, GUI.mouse.ox, GUI.mouse.oy) then
			
				if elm.focus ~= false then 

					GUI.elm_updated = true
					elm:ondrag()
					
				end
			end

		-- If it was originally clicked in this element and has now been released
		elseif GUI.mouse.down and GUI.IsInside(elm, GUI.mouse.ox, GUI.mouse.oy) then
		
			-- We don't want to trigger an extra mouse-up after double clicking
			if not GUI.mouse.dbl_clicked then elm:onmouseup() end
			
			GUI.elm_updated = true
			GUI.mouse.down = false
			GUI.mouse.dbl_clicked = false
			GUI.mouse.ox, GUI.mouse.oy = -1, -1
			GUI.mouse.lx, GUI.mouse.ly = -1, -1
			GUI.mouse.downtime = os.clock()

		end
		
		
		-- Right button
		if GUI.mouse.cap&2==2 then
			
			-- If it wasn't down already...
			if not GUI.mouse.last_r_down then

				-- Was a different element clicked?
				if not inside then 
					--elm.focus = false
				else
		
						-- Double clicked?
					if GUI.mouse.r_downtime and os.clock() - GUI.mouse.r_downtime < 0.20 then
						
						GUI.mouse.r_downtime = nil
						GUI.mouse.r_dbl_clicked = true
						elm:onr_doubleclick()
						
					elseif not GUI.mouse.r_dbl_clicked then
			
						elm:onmouser_down()
						
					end
					
					GUI.mouse.r_down = true
					GUI.mouse.r_ox, GUI.mouse.r_oy = x, y
					GUI.elm_updated = true
				
				end
				
		
			-- 		Dragging? 									Did the mouse start out in this element?
			elseif (x ~= GUI.mouse.r_lx or y ~= GUI.mouse.r_ly) and GUI.IsInside(elm, GUI.mouse.r_ox, GUI.mouse.r_oy) then
			
				if elm.focus ~= false then 

					elm:onr_drag()
					GUI.elm_updated = true

				end

			end

		-- If it was originally clicked in this element and has now been released
		elseif GUI.mouse.r_down and GUI.IsInside(elm, GUI.mouse.r_ox, GUI.mouse.r_oy) then 
		
			if not GUI.mouse.r_dbl_clicked then elm:onmouser_up() end

			GUI.elm_updated = true
			GUI.mouse.r_down = false
			GUI.mouse.r_dbl_clicked = false
			GUI.mouse.r_ox, GUI.mouse.r_oy = -1, -1
			GUI.mouse.r_lx, GUI.mouse.r_ly = -1, -1
			GUI.mouse.r_downtime = os.clock()

		end



		-- Middle button
		if GUI.mouse.cap&64==64 then
			
			
			-- If it wasn't down already...
			if not GUI.mouse.last_m_down then


				-- Was a different element clicked?
				if not inside then 

				else	
					-- Double clicked?
					if GUI.mouse.m_downtime and os.clock() - GUI.mouse.m_downtime < 0.20 then

						GUI.mouse.m_downtime = nil
						GUI.mouse.m_dbl_clicked = true
						elm:onm_doubleclick()

					else
					
						elm:onmousem_down()					

					end				

					GUI.mouse.m_down = true
					GUI.mouse.m_ox, GUI.mouse.m_oy = x, y
					GUI.elm_updated = true

				end
				

			
			-- 		Dragging? 									Did the mouse start out in this element?
			elseif (x ~= GUI.mouse.m_lx or y ~= GUI.mouse.m_ly) and GUI.IsInside(elm, GUI.mouse.m_ox, GUI.mouse.m_oy) then
			
				if elm.focus ~= false then 
					
					elm:onm_drag()
					GUI.elm_updated = true
					
				end

			end

		-- If it was originally clicked in this element and has now been released
		elseif GUI.mouse.m_down and GUI.IsInside(elm, GUI.mouse.m_ox, GUI.mouse.m_oy) then
		
			if not GUI.mouse.m_dbl_clicked then elm:onmousem_up() end
			
			GUI.elm_updated = true
			GUI.mouse.m_down = false
			GUI.mouse.m_dbl_clicked = false
			GUI.mouse.m_ox, GUI.mouse.m_oy = -1, -1
			GUI.mouse.m_lx, GUI.mouse.m_ly = -1, -1
			GUI.mouse.m_downtime = os.clock()

		end


	end
	
		
	
	-- If the mouse is hovering over the element
	if inside and not GUI.mouse.down and not GUI.mouse.r_down then
		elm:onmouseover()
		--GUI.elm_updated = true
		elm.mouseover = true
	else
		elm.mouseover = false
		--elm.hovering = false
	end
	
	
	-- If the mousewheel's state has changed
	if inside and GUI.mouse.wheel ~= GUI.mouse.lwheel then
		
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
	
	GUI.font("version")
	GUI.color("txt")
	
	local str_w, str_h = gfx.measurestr(str)
	
	--gfx.x = GUI.w - str_w - 4
	--gfx.y = GUI.h - str_h - 4
	gfx.x = gfx.w - str_w - 6
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

-- Updates the current tooltip, if necessary
function GUI.Element:onmouseover()
	
	if self.tooltip and not GUI.tooltip_elm then 
		GUI.tooltip_elm = self 
	end

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

function GUI.Element:onmousem_down() end
function GUI.Element:onmousem_up() end
function GUI.Element:onm_doubleclick() end
function GUI.Element:onm_drag() end

function GUI.Element:onwheel() end
function GUI.Element:ontype() end
function GUI.Element:onupdate() end
function GUI.Element:lostfocus() end


--[[
	All classes will use this as their template, so that
	elements are initialized with every method available.
	
	To create a new class, just use:
	
		-- Creates a new child of GUI.Element
		GUI.my_class = GUI.Element:new()
		
		--							Whatever parameters you want
		function GUI.my_class:new(param_a, param_b, param_c, param_d)
		
			-- Every class object is really just a big table
			local class = {}
			
			-- Store the parameters this object was created with
			class.param_a = param_a
			class.param_b = param_b
			class.param_c = param_c
			class.param_d = param_d
		
			-- Force a redraw for this object's layer, since presumably we want to see it
			GUI.redraw_z[z] = true
		
			-- More class stuff. Roughly, it's just telling the new object to use GUI.my_class
			-- as a reference for anything it needs, which in turn will use GUI.Element as
			-- its own reference.
			
			setmetatable(class, self)
			self.__index = self
			
			-- Return the new child object
			return class
		
		end
	
	
	Methods are added by:
	
		function GUI.my_class:fade()
	
			blah blah blah
			
		end
		
	
	- All classes need their methods explicitly written; GUI.Element does absolutely nothing
	  except keep the script from crashing when it goes to look for a method you didn't add.
	
	- All of the methods listed for GUI.Element will be called when appropriate on each loop
	  of GUI.Update. Any methods that aren't listed there can be called on their own as a
	  function. To fade a label, for instance:
	  
		my_label:fade(2, 3, 10)
		
]]--




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
	GUI.redraw_z[z] = true

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
	GUI.redraw_z[self.z] = true
	
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
		
		GUI.redraw_z[self.z] = true
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
		GUI.redraw_z[self.z] = true
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
function GUI.Slider:new(z, x, y, w, caption, min, max, steps, default, dir, ticks)
	
	local Slider = {}
	Slider.type = "Slider"
	
	Slider.z = z
	GUI.redraw_z[z] = true

	Slider.x, Slider.y = x, y
	Slider.w, Slider.h = table.unpack(dir == "h" and {w, 8} or {8, w})
	
	Slider.dir = dir
	if dir == "v" then
		min, max, default = max, min, steps - default
		
	end

	Slider.caption = caption
	--Slider.output = {}
	
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
	local radius = self.r or 8


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
			
			-- If the user has given us two colors to make a gradient with
			if self.col_fill_a then
				
				-- Make a gradient, 
				local col_a = GUI.colors[self.col_fill_a]
				local col_b = GUI.colors[self.col_fill_b]
				local grad_step = curstep / steps
	
				local r, g, b, a = GUI.gradient(col_a, col_b, grad_step)
	
				gfx.set(r, g, b, a)
									
			else
				GUI.color(self.col_fill or "elm_fill")
			end
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
			GUI.font(self.font_a or 3)
			
			local str_w, str_h = gfx.measurestr(self.caption)
			
			gfx.x = x + (w - str_w) / 2
			gfx.y = not self.swap 	and	y - h - str_h
									or	y + h + h


			GUI.shadow(self.caption, self.col_a or "txt", "shadow")
		end
		
		-- Draw ticks + highlighted labels if specified	
		-- Draw slider value otherwise 
		
		local output = self.retval

		if self.output then
			local t = type(self.output)

			if t == "string" or t == "number" then
				output = self.output
			elseif t == "table" then
				output = self.output[curstep]
			elseif t == "function" then
				output = self.output(self)
			end
		end
		
		-- Avoid any crashes from weird user data
		output = tostring(output)
	
		--local output = self.output[curstep] or self.retval

		if output ~= "" then
			
			GUI.color(self.col_b or "txt")
			GUI.font(self.font_b or 4)
			
			local str_w, str_h = gfx.measurestr(output)
			gfx.x = x + (w - str_w) / 2
			gfx.y = not self.swap	and	y + h + h
									or y - h - str_h
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
				local grad_step = curstep / steps
	
				local r, g, b, a = GUI.gradient(col_a, col_b, grad_step)
	
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
			GUI.font(self.font_a or 3)
			
			local str_w, str_h = gfx.measurestr(self.caption)

			gfx.x = x + (w - str_w) / 2
			gfx.y = not self.swap 	and	y - h - str_h
									or	y + h + w

			GUI.shadow(self.caption, self.col_a or "txt", "shadow")
		end
		
		-- Draw ticks + highlighted labels if specified	
		-- Draw slider value otherwise 

		local output = self.retval

		if self.output then
			local t = type(self.output)

			if t == "string" or t == "number" then
				output = self.output
			elseif t == "table" then
				output = self.output[curstep]
			elseif t == "function" then
				output = self.output(self)				
			end
		end
		
		if output ~= "" then
			
			GUI.color(self.col_b or "txt")
			GUI.font(self.font_b or 4)
		
			local str_w, str_h = gfx.measurestr(output)
			gfx.x = x + (w - str_w) / 2
			gfx.y = not swap 	and	y + h + w
								or	y - h - str_h
								
			gfx.drawstr(output)
		end
	end
	
end


-- Slider - Get/set value
function GUI.Slider:val(newval)

	if newval then
		self.curstep = newval --(self.dir == "h" and self.min or self.max)
		self.curval = self.curstep / self.steps
		self.retval = GUI.round((((self.max - self.min) / self.steps) * self.curstep) + self.min)
		--self.retval = newval
		GUI.redraw_z[self.z] = true
	else
		return self.curstep --(self.dir == "h" and self.min or self.max)
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
	
	GUI.redraw_z[self.z] = true
	
end


-- Slider - Dragging
function GUI.Slider:ondrag()

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
	
	GUI.redraw_z[self.z] = true
	
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

	GUI.redraw_z[self.z] = true

end


-- Slider - Doubleclick
function GUI.Slider:ondoubleclick()
	
	local steps = self.steps
	local min = self.min
	
	self.curstep = self.default
	self.curval = self.curstep / steps
	self.retval = GUI.round(((self.max - min) / steps) * self.curstep + min)
	
	GUI.redraw_z[self.z] = true
	
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
	GUI.redraw_z[z] = true

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
function GUI.Range:val(newvals)
	
	if newvals then
		retval_a = newvals[1]
		retval_b = newvals[2]
		
		if retval_a > retval_b then
			retval_a, retval_b = retval_b, retval_a
		end
		
		self.curstep_a = retval_a - self.min
		self.curstep_b = retval_b - self.min
		self.curval_a = self.curstep_a / self.steps
		self.curval_b = self.curstep_b / self.steps
		self.retval_a = GUI.round((((self.max - self.min) / self.steps) * self.curstep_a) + self.min)		
		self.retval_b = GUI.round((((self.max - self.min) / self.steps) * self.curstep_b) + self.min)		
		
		GUI.redraw_z[self.z] = true
	
	else
		
		return self.curstep_a + self.min, self.curstep_b + self.min
		
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
	
	GUI.redraw_z[self.z] = true	
	
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

	GUI.redraw_z[self.z] = true

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

	GUI.redraw_z[self.z] = true

end


function GUI.Range:ondoubleclick()
	
--[[
	self.curstep = self.default
	self.curval = self.curstep / self.steps
	self.retval = GUI.round(((self.max - self.min) / self.steps) * self.curstep + self.min)
	
	GUI.redraw_z[self.z] = true
]]--

	local steps = self.steps
	local min, max = self.min, self.max

	self.curstep_a, self.curstep_b = self.default_a, self.default_b
	self.curval_a, self.curval_b = self.curstep_a / steps, self.curstep_b / steps
	self.retval_a = GUI.round(((max - min) / steps) * self.curstep_a + min)
	self.retval_b = GUI.round(((max - min) / steps) * self.curstep_b + min)
	
	GUI.redraw_z[self.z] = true
	
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
	GUI.redraw_z[z] = true	
	
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

		GUI.redraw_z[self.z] = true

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

	GUI.redraw_z[self.z] = true

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

	GUI.redraw_z[self.z] = true

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
	GUI.redraw_z[z] = true	
	
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
	
	opt_lst.shadow = true
	
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
	if self.frame then
		GUI.color("elm_frame")
		gfx.rect(x, y, w, h, 0)
	end
	

	-- Draw the caption

	GUI.font(2)
	
	local str_w, str_h = gfx.measurestr(self.caption)
	self.capheight = str_h

	gfx.x = x + (w - str_w) / 2
	gfx.y = y
	
	GUI.shadow(self.caption, "txt", "shadow")
	
	GUI.font(self.font or 3)

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
		--GUI.color("txt")
		local str_w, str_h = gfx.measurestr(self.optarray[i])
		
		gfx.x = x + 4 * radius
		gfx.y = cur_y + (optheight - str_h) / 2
		if self.shadow then
			GUI.shadow(self.optarray[i], "txt", "shadow")
		else
			GUI.color("txt")
			gfx.drawstr(self.optarray[i])
		end
		
		cur_y = cur_y + optheight

		
	end
	
end


-- Radio - Get/set value
function GUI.Radio:val(newval)
	
	if newval then
		self.retval = newval
		self.state = newval
		GUI.redraw_z[self.z] = true		
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

	GUI.redraw_z[self.z] = true

end


-- Radio - Mouse up
function GUI.Radio:onmouseup()
		
	-- Set the new option, or revert to the original if the cursor isn't inside the list anymore
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		self.retval = self.state
	else
		self.state = self.retval	
	end

	GUI.redraw_z[self.z] = true

end


-- Radio - Dragging
function GUI.Radio:ondrag() 

	self:onmousedown()

	GUI.redraw_z[self.z] = true

end


-- Radio - Mousewheel
function GUI.Radio:onwheel()
	
	self.state = self.state - GUI.mouse.inc
	
	if self.state < 1 then self.state = 1 end
	if self.state > self.numopts then self.state = self.numopts end
	
	self.retval = self.state

	GUI.redraw_z[self.z] = true

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
function GUI.Checklist:new(z, x, y, w, h, caption, opts, dir, pad)
	
	local chk = {}
	chk.type = "Checklist"
	
	chk.z = z
	GUI.redraw_z[z] = true	
	
	chk.x, chk.y = x, y
	
	-- constant for the square size
	chk.chk_w = 20

	chk.caption = caption
	
	chk.dir = dir
	
	chk.pad = pad

	chk.f_color = "elm_fill"
	
	chk.shadow = true

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
	
	-- Work out the total size of the checklist now that we have the number of options

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
	
	if self.frame then
		
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
	
		
			if self.numopts == 1 or self.shadow then
				GUI.shadow(self.optarray[i], "txt", "shadow")
			else
				GUI.color("txt")
				gfx.drawstr(self.optarray[i])
			end
		end
		
	end
	
end


-- Checklist - Get/set value. Returns a table of boolean values for each option.
function GUI.Checklist:val(newvals)
	
	if newvals then 
		
		if type(newvals) == "boolean" then
			self.optsel[1] = newvals
		elseif type(newvals) == "table" then
			for i = 1, self.numopts do
				self.optsel[i] = newvals[i]
			end
		end
		GUI.redraw_z[self.z] = true	
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

	GUI.redraw_z[self.z] = true
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
	GUI.redraw_z[z] = true	
	
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
	GUI.redraw_z[self.z] = true

end


-- Button - Mouse up.
function GUI.Button:onmouseup() 
	
	self.state = 0
	
	-- If the mouse was released on the button, run func
	if GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
		
		self.func(table.unpack(self.params))
		
	end
	GUI.redraw_z[self.z] = true

end

function GUI.Button:ondoubleclick()
	
	self.state = 0
	
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
	GUI.redraw_z[z] = true	
	
	txt.x, txt.y, txt.w, txt.h = x, y, w, h

	txt.caption = caption
	txt.pad = pad
	
	txt.shadow = true
	
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
	GUI.font(self.font_A or 3)
	local str_w, str_h = gfx.measurestr(caption)
	gfx.x = x - str_w - pad
	gfx.y = y + (h - str_h) / 2
	if self.shadow then 
		GUI.shadow(caption, "txt", "shadow") 
	else
		GUI.color(self.color or "txt")
		gfx.drawstr(caption)
	end
	
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
	GUI.font(self.font_B or 4)
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
		if self.show_caret then
			
			local caret_x = x + pad + gfx.measurestr(string.sub(text, 0, caret))

			GUI.color("txt")
			gfx.rect(caret_x, y + 4, 2, h - 8)
			
		end
		
	--GUI.redraw_z[self.z] = true
		
	end
	
end


-- Textbox - Get/set value
function GUI.Textbox:val(newval)
	
	if newval then
		self.retval = newval
		GUI.redraw_z[self.z] = true		
	else
		return self.retval
	end
end


-- Textbox - Lost focus
function GUI.Textbox:lostfocus()

	GUI.redraw_z[self.z] = true
	
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
		GUI.redraw_z[self.z] = true
	end
	
end


-- Textbox - Double-click.
function GUI.Textbox:ondoubleclick()
	
	local len = string.len(self.retval)
	self.caret, self.sel = len, -len
	GUI.redraw_z[self.z] = true
end


-- Textbox - Mouse drag.
function GUI.Textbox:ondrag()
	
	self.sel = self:getcaret() - self.caret
	GUI.redraw_z[self.z] = true	
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
		

	if 	   char	== GUI.chars.LEFT then
		if caret > 0 then self.caret = caret - 1 end

	elseif char	== GUI.chars.RIGHT then
		if caret < string.len(text) then self.caret = caret + 1 end
	
	elseif char == GUI.chars.BACKSPACE then
		if string.len(text) > 0 and self.sel == 0 and caret > 0 then
			text = string.sub(text, 1, caret - 1)..(string.sub(text, caret + 1))
			self.caret = caret - 1
		end
		
	elseif char == GUI.chars.DELETE then
		if string.len(text) > 0 and self.sel == 0 then
				text = string.sub(text, 1, caret)..(string.sub(text, caret + 2))
		end
		
	elseif char == GUI.chars.RETURN then
		self.focus = false
		self:lostfocus()
		text = self.retval
		
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
	GUI.redraw_z[self.z] = true	
end


-- Textbox - On Update (for making it blink)
function GUI.Textbox:onupdate()
	
	if self.focus then
	
		if self.blink == 0 then
			self.show_caret = true
			GUI.redraw_z[self.z] = true
		elseif self.blink == math.floor(GUI.txt_blink_rate / 2) then
			self.show_caret = false
			GUI.redraw_z[self.z] = true
		end
		self.blink = (self.blink + 1) % GUI.txt_blink_rate

	end
	
end





--[[	MenuBox class
	
	---- User parameters ----
z				Element depth, used for hiding and disabling layers. 1 is the highest.
x, y, w, h		Coordinates of top-left corner, width, overall height *including caption*
caption			Title / question
opts			String separated by commas, just like for GetUserInputs().
				ex: "Alice,Bob,Charlie,Denise,Edward"
				
				Empty fields ("i.e. Alice,,Charlie") will show a separator, but will still
				be counted toward the number of options and the value returned when the
				menu is clicked.
				
				e.g. ("Alice,,Charlie") --> clicks 'Charlie' --> returns 3
				
pad				Padding between the caption and the box
	
]]--
GUI.Menubox = GUI.Element:new()
function GUI.Menubox:new(z, x, y, w, h, caption, opts, pad)
	
	local menu = {}
	menu.type = "Menubox"
	
	menu.z = z
	GUI.redraw_z[z] = true	
	
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
	local text = (type(self.optarray[val]) == "table")
					and self.optarray[val][1] 
					or self.optarray[val]

	local focus = self.focus
	

	-- Draw the caption
	GUI.font(self.font or 3)
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
	
	if self.output then text = self.output(text) end

	str_w, str_h = gfx.measurestr(text)
	gfx.x = x + 4
	gfx.y = y + (h - str_h) / 2
	gfx.drawstr(text)
	
end


-- Menubox - Get/set value
function GUI.Menubox:val(newval)
	
	if newval then
		self.retval = newval
		GUI.redraw_z[self.z] = true		
	else
		return math.floor(self.retval)
	end
	
end


-- Menubox - Mouse up
function GUI.Menubox:onmouseup()

	local menu_str = ""
	local str_arr = {}
	
	-- The menu doesn't count separators in the returned number,
	-- so we'll do it here
	local sep_arr = {}
	
	for i = 1, self.numopts do
		
		local str = type(self.optarray[i]) == "table"	and tostring(self.optarray[i][1])
														or	tostring(self.optarray[i])

		-- Check for separators/submenus
		if str == "" or string.sub(str, 1, 1) == ">" then table.insert(sep_arr, i) end

		-- Check off the currently-selected option		
		if i == self.retval then str = "!" .. str end

		table.insert( str_arr, str )
		table.insert( str_arr, "|" )

	end
	
	menu_str = table.concat( str_arr )
	
	menu_str = string.sub(menu_str, 1, string.len(menu_str) - 1)

	gfx.x, gfx.y = GUI.mouse.x, GUI.mouse.y
	
	local curopt = gfx.showmenu(menu_str)
	
	if #sep_arr > 0 then
		for i = 1, #sep_arr do
			if curopt >= sep_arr[i] then
				curopt = curopt + 1
			else
				break
			end
		end
	end
	
	if curopt ~= 0 then self.retval = curopt end

	self.focus = false
	
	GUI.redraw_z[self.z] = true	
end


-- Menubox - Mouse down
-- This is only so that the box will light up
function GUI.Menubox:onmousedown()
	GUI.redraw_z[self.z] = true
end

-- Menubox - Mousewheel
function GUI.Menubox:onwheel()
	
	local curopt = self.retval - GUI.mouse.inc
	local inc = (GUI.mouse.inc > 0) and 1 or -1

	-- Check for illegal values, separators, and submenus
	while true do
		
		if curopt < 1 then 
			curopt = 1 
			inc = 1
		elseif curopt > self.numopts then 
			curopt = self.numopts 
			inc = -1
		end	

		if self.optarray[curopt] == "" or string.sub( self.optarray[curopt], 1, 1 ) == ">" then 
			curopt = curopt - inc

		else
		
			-- All good, let's move on
			break
		end
		
	end
	

	
	self.retval = curopt
	
	GUI.redraw_z[self.z] = true	
end


--[[	Frame class
	
	
]]--
GUI.Frame = GUI.Element:new()
function GUI.Frame:new(z, x, y, w, h, shadow, fill, color, round)
	
	local Frame = {}
	Frame.type = "Frame"
	
	Frame.z = z
	GUI.redraw_z[z] = true	
	
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
	


--[[	TxtFrame class
	
	
]]--
GUI.TxtFrame = GUI.Element:new()
function GUI.TxtFrame:new(z, x, y, w, h, text, font, col_txt, pad, shadow, fill, color, round)
	
	local TxtFrame = {}
	TxtFrame.type = "TxtFrame"
	
	TxtFrame.z = z
	GUI.redraw_z[z] = true	
	
	TxtFrame.x, TxtFrame.y, TxtFrame.w, TxtFrame.h = x, y, w, h
	
	TxtFrame.retval = text
	TxtFrame.font = font or 4
	TxtFrame.col_txt = col_txt or "txt"
	TxtFrame.pad = pad or 0	
	
	TxtFrame.shadow = shadow
	TxtFrame.fill = fill or false
	TxtFrame.color = color or "elm_frame"
	TxtFrame.round = round or 0
	TxtFrame.thick = thick or 0
	
	
	setmetatable(TxtFrame, self)
	self.__index = self
	return TxtFrame
	
end


function GUI.TxtFrame:val(newval)

	if newval then
		self.retval = newval
		GUI.redraw_z[self.z] = true
	else
		return self.retval
	end

end


function GUI.TxtFrame:draw()
	
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

	if self.retval then
		
		local text = self.retval
		
		GUI.font(self.font)
		GUI.color(self.col_txt)
		
		gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
		gfx.drawstr(text)		
		
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
	GUI.redraw_z[z] = true	
	
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


function GUI.Tabframe:val(newval)
	
	if newval then
		self.state = newval
		self.retval = self.state

		self:update_sets()
		GUI.redraw_z[self.z] = true
	else
		return self.state
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
	
	local x, y, w, h = self.x + 16, self.y + 2, self.btn_w, self.btn_h
	local pad = self.pad
	local font = self.font_B
	local dir = self.dir
	local state = self.state
	local optarray = self.optarray

	GUI.color("elm_bg")
	gfx.rect(x - 16, y, gfx.w, h, true)
			
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
	gfx.rect(self.x, self.y + h, gfx.w, 6, true)


	
end


-- Tabframe - Mouse down.
function GUI.Tabframe:onmousedown()

	local adj = (self.dir == "h") and 0.5*self.h or 0.5*self.w
	--See which option it's on
	local mouseopt = (self.dir == "h") and ((GUI.mouse.x - (self.x + adj)) / self.w) or ((GUI.mouse.y - self.y) / self.h)
	--local adj_y = self.y + self.capheight + self.pad
	--local adj_h = self.h - self.capheight - self.pad
	--local mouseopt = (GUI.mouse.y - adj_y) / adj_h
		
	mouseopt = GUI.clamp((math.floor(mouseopt * self.numopts) + 1), 1, self.numopts)

	self.state = mouseopt

	GUI.redraw_z[self.z] = true
	
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
	GUI.redraw_z[self.z] = true	
end


-- Tabframe - Dragging
function GUI.Tabframe:ondrag() 

	self:onmousedown()
	GUI.redraw_z[self.z] = true
end


-- Tabframe - Mousewheel
function GUI.Tabframe:onwheel()

	self.state = self.state + (dir == "h" and GUI.mouse.inc or -GUI.mouse.inc)
	
	if self.state < 1 then self.state = 1 end
	if self.state > self.numopts then self.state = self.numopts end
	
	self.retval = self.state
	self:update_sets()
	GUI.redraw_z[self.z] = true
end





-- Make our table full of functions available to the parent script
return GUI

end
GUI = GUI_table()

----------------------------------------------------------------
----------------------------To here-----------------------------
----------------------------------------------------------------

---- End of file: Lokasenna_GUI library beta 8.lua ----

---- End of libraries ----

_=dm and GUI.Msg(script_path)

-- For the context boxes
GUI.fonts[5] = {"Calibri", 15}

-- For the current tab
GUI.fonts[6] = {"Calibri", 18, "b"}

-- For the radial menu
GUI.fonts[7] = {"Calibri", 16, "b"}		-- Normal buttons
GUI.fonts[8] = {"Calibri", 16, "bu"}	-- Menus
GUI.fonts[9] = {"Calibri", 14}			-- Submenu preview

-- Script version in RM
GUI.fonts[10] = {"Calibri", 14, "i"}

local script_version = "2.7.3"

local settings_file_name = (script_path or "") .. "Lokasenna_Radial Menu - user settings.txt"
local example_file_name  = (script_path or "") .. "Lokasenna_Radial Menu - example settings.txt"

-- If there's no saved settings, i.e. first run, and we can't find the example menus, open in Setup mode
if not (setup or reaper.file_exists(settings_file_name) or reaper.file_exists(example_file_name) ) then 
	reaper.ShowMessageBox("Couldn't find any saved settings. Opening in Setup mode.", "No settings found", 0)
	setup = true
end

-- It's much more efficient to put the trig functions in local variables if we're going
-- to be using them a lot.
local sin, cos, tan, asin, acos, atan, sqrt = math.sin, math.cos, math.tan, math.asin, math.acos, math.atan, math.sqrt

local pi = 3.1416

local ox, oy, frm_w

local cur_depth, last_depth, cur_btn = 0, 0, -2
local base_depth, prev_depths = 0, {}

local redraw_menu = true

-- Current menu option, angle + radius from ox, oy
local mouse_mnu = -2
local mouse_angle, mouse_r, mouse_lr = 0, 0, 0

-- Width (in rads) of each button in the current menu
local mnu_adj = 0

-- For processing swipes
local track_swipe, stopped = false, nil

-- Was the window recently reopened by swiping?
local swipe_retrigger = 0


-- For smart buttons
local smart_act, armed = "", -2


-- For key binds
local bound_key, bound_act, bound_mnu



local startup = true

local key_down = 0
local key_down_arr = {}

local hvr_time = 0

--local ra, rb, rc, rd = 50, 60, 64, 160

local win_pos_str = "At the mouse cursor,In its previous location"
local mouse_mode_str = "Just run the action,Return to the base menu,Close the menu"
local key_mode_str = "Close the menu,Run the highlighted action and close the menu,Keep the menu open"




	---- Documentation ----

local thread_URL = [[http://forum.cockos.com/showthread.php?t=186637]]
local donate_URL = [[https://www.paypal.me/Lokasenna]]



local settings_help_str = [=[--[[
		Settings for Lokasenna_Radial Menu.lua
	
		This file is written as a Lua table, and must use the appropriate 
	syntax with regard to tables, indices, keys, strings, etc, etc. If
	you run Radial Menu and get an error loading the menu, it either
	couldn't find this file or you've got some incorrect Lua in it.

	A few general notes:

	- Due to quirks with the function that loads these settings into 
	the script, all indices must include square brackets and/or quotation 
	marks rather than being left bare, i.e. 

					[3]				not		3
					["col_main"]	not		col_main
	
	
	- Colors can be specified per button, per menu, or globally (see
	table index [-1]). Buttons with no colors specified will use their
	menu's settings, menus will use the global settings.
	
	- When a button is assigned to an action that's toggled On, the button
	  will light up; if the mouse is hovering or clicked on it, the toggle 
	  color will be blended with the hover or background color, respectively.
	
	- Menus are numbered starting from 0, and menu numbers do NOT need to
	  be contiguous - that is, 1 2 3 4 9 11 15 20 25 is fine, so feel free
	  to organize your menus by number however you want.
	
	- Buttons are numbered starting from 0, and button numbers DO need to
	  be contiguous.
	  
	- You can add a button in the center of the ring by giving it the
	  number [-1]
	  
	
	  


	Menu #:
	[0] = {	
	
		(There's no limit to the number of menus you can have)
		
		["alias"] = "blah",			A name to use for this menu so you don't have
									to remember menu numbers. Displayed in the
									menu list, and can be used in button actions
									and context boxes. (See below)
	
		["col_main"] = {			Normal button color for buttons in this menu
			[1] = 0.0,				R
			[2] = 1.0,				G	(values are from 0-1)
			[3] = 1.0,				B
			
		["col_tog"] = {				Toggled color, for use with
			...						i.e. "Options: Toggle metronome"
			
		["col_hvr"] = {				Mouse-over color
			...
			
		["col_bg"] = {				Background color
			...
		
	
	
		Button #:
		[0] = {
		
			(Maximum of 16 buttons per menu)
		
			Button settings:
			
			["lbl"] = "cool",			The button's label
			
										| or ; will wrap the text to a new line,
										i.e. "Multi|line;text"
			
			["act"] = "menu 1",			Action to perform / menu to open. 
			
										Valid commands are...
										
										Action IDs:											
										40364	
											
										Script/extension actions:
										_SWS_AWMPLAYTOG
										_RS2bf8e77e958d48b42c7d7b585790ee0427a96a7e
										
											Note: Because the MIDI Editor uses its own
											action list, when running MIDI actions you
											may need to enter them as 'midi 40364' to
											keep Reaper from getting confused.
										
										Open a menu:
										menu 20		(opens menu 20)
										menu stuff	(opens the menu with alias 'stuff')
										
										back		Return to the previous menu
										base		Return to the original menu
													(either menu 0 or the specified menu
													for a given Reaper context)
													
										quit		Close the script
										
										
										Special commands:
										
										midi 12345	Send an action to the current MIDI
													editor rather than the main window
					
										xN 12345	Perform the action N times each time
													the button is clicked.
										
													e.g.	x3 40001
													
													will insert three new tracks each
													time the button is clicked
													
													
													
										repeat N "12345"	Repeats the action every N
												 '12345'	seconds while the mouse button
															is held down.
												 
													e.g.	repeat 0.5 "40001"
													
													will insert a new track every 0.5 seconds
													
										The special commands can be combined, in (I think)
										any order:
										
										midi x3 12345		Perform MIDI action 12345 three times
										
										repeat 0.5 "x3 12345"	Perform action 12345 three times,
																every 0.5 seconds.
																
										
										
													
													
					
					

					
										
										
	
			["col_main"] = {			Normal button color
				[1] = 0.0,				R
				[2] = 1.0,				G	(values are from 0-1)
				[3] = 1.0,				B
				
			["col_tog"] = {				Toggled color, for use with
				...						i.e. "Options: Toggle metronome"
				
			["col_hvr"] = {				Mouse-over color
				...
				
				
				
	Global settings are stored in index [-1]:
	[-1] = {
	
		["close_time"] = 600,		How long to keep the window open (in ms) on 
									startup	if no key is being held down. Going
									lower than 600ms will probably cause the menu 
									to keep opening and closing.
	
	
									Global color settings:
		["col_main"] = {			Normal button color for buttons in this menu
			[1] = 0.0,				R
			[2] = 1.0,				G	(values are from 0-1)
			[3] = 1.0,				B
			
		["col_tog"] = {				Toggled color, for use with
			...						i.e. "Options: Toggle metronome"
			
		["col_hvr"] = {				Mouse-over color
			...
			
		["col_bg"] = {				Background color
			...
			
		["contexts"] = {			What menu to open on startup for a given mouse
			["mcp|empty"] = 10,		context. Contexts can be assigned with menu 
									numbers or aliases, i.e.
										20
										stuff
									
									If a particular context isn't given a menu, 
									it will	look up one 'level' at a time until
									it finds a match.
									
									Example:									
									The menu was opened with the mouse cursor over 
									an empty area of a track in the Arrange view.
									The script will look for:
										["arrange|track|empty"]
									then:
										["arrange|track"]
									then:
										["arrange"]
									
									If there's still no match, it will open menu 0.				
									(see the Setup script's Context tab for a list
									of available contexts)
									
		["fonts"] = {				Font settings
		
			[1] = 	{				1 - Normal buttons
									2 - Menus
									3 - Preview text
									
				"Calibri", 			Font face. See the note below.
				
				16, 				Size
				
				"b"					Flags. Just a string listing:
										b	bold
										i	italics
										u	underline
										
									The order doesn't matter, i.e. this would be
									perfectly fine: "iub"
									
										
									Important: Font names are really picky, and will
									default back to Arial if you get them wrong. The
									Setup script provides a green/red light for each
									font to let you know if it's correct or not.
									
									Unfortunately, the names are often not what you
									see when using them in Office, etc...
									
									To get a font's name in Windows:
									1. Find the .ttf file in your Windows\Fonts folder
									2. Right-click it, select Properties
									3. Select the Details tab
									4. The first field, "Name", is what you want to
									   be using here.
									   
									Mac users - I have no idea. 
									   
									   
									I know, it's stupid.
				
			
		
		["hvr_click"] = false,		Boolean - hover over a button to 'click' it
		["hvr_time"] = 200,			Hover time for ^^^ (in ms)
		
		
		["key_binds"] = {			Key bind settings
		
			["enabled"] = true,		Boolean - enables the assigned key binds
		
			["hints"] =	true,		Boolean - display key binds outside the menu ring
			
			["last_num"] = 1,		Last menu size selected in the setup script (1-13)
		
			[4] =	{				Menu size for each set of bindings. (4-16)
			
				[1] = "r",			Key bind for the given button number.
				
										-1	=	Center button
										1	=	Always the button facing right
		
		
		["key_mode"] = 1,			What to do when the shortcut key is released
									(1-3, see the options in the Setup script)
									
		["last_tab"] = 1,			The last tab that was active in the Setup script
									
		["mouse_mode"] = 1,			What to do when the mouse is clicked
									(1-3, see the options in the Setup script)
									
									
		["num_btns"] = 8,			Number of buttons for new menus to start with
		
		["preview"] = true,			Whether or not to preview a menu's buttons when
									hovering the mouse over it.
									
		
									Button radiuses/target areas:
		["ra"] = 48,				Center button
		["rb"] = 60,				Currently unused
		["rc"] = 116,				Inside of the button ring
		["rd"] = 192,				Outside of the button ring
		["re"] = 192,				Threshold for tracking Swipes
		
									Note that the preview labels when hovering over
									a menu are drawn with a radius of (rc - ra), so
									adjusting these will affect the labels as well.
		
		["swipe"] = {				Parameters for the Swiping feature:
		
			["accel"] = 65,			Start sensitivity
			["actions"]	= true,		Whether Swipes can trigger actions, or just menus
			["decel"] = 10,			Stop sensitivity
			["enabled"] = true,		Whether Swiping mode is active or not
			["menu"] = 0,			What menu to use for Swipe actions...
			["mode"] = 1,		...if this is set to 2. Setting it to 1 will always
									use the current menu
			["stop"] = 20,			Stop time for Swipes, in milliseconds
			
		
]]--
]=]


local help_pages = {
	


	{"Radial Menu",
		
[[- Assign the Radial Menu script to a key shortcut, hold down the key to bring up the menu, and release it to close the menu again. While the menu is open, left-clicking inside the window will run the highlighted action or open a submenu.
 
    (Some key shortcuts may not play nicely with the script, causing the window 
    to flicker open and closed. Please let me know in the forum thread)
 
- When hovering over a button assigned to a submenu, that menu's buttons are 'previewed' below the current ones.
 
- To back out of a menu, click any of the outer corners, or in the center of the ring if the current menu has no button there.
 
- Certain Reaper actions will steal 'focus' from the script window and cause it to close prematurely. I'm working on it.

]]},



	{"", ""},



	{"Button commands p1",
	
[[Action IDs:
    12345, _SWS_AWMPLAYTOG, _RS1a8cae1f4c60d0e5d5d90bc96eda9d83050eb214
    (Use 'midi 12345' to specify commands from the MIDI editor's action list)
  
Accessing submenus, via menu numbers or aliases:
    menu 20, menu stuff
 
Return to the previous menu:
    back
 	
Return to the base menu (0 by default, or the specified menu for a given context):
    base
  	
Exit the script:
    quit
]]},


	
	{"Button commands p2",

[[Perform an action multiple times per button-click:
    x3 12345
 
Repeat an action at a specified interval (in seconds) while the mouse button is held down:
    repeat 0.5 '12345'
 
Commands can also be combined:	
    repeat 0.5 'x3 midi 12345'
    (Every 0.5 seconds, send command 12345 to the MIDI editor three times)

]]},



	{"", ""},


	{">Tabs", ""},

	{"Menu",
		
[[- Menus may have anywhere from one to sixteen buttons, with an optional button in the center of the ring. Each menu can have its own color settings, or use the colors set in the Global tab.
 
- They can also be given an alias for buttons and contexts to reference rather than having to remember menu numbers.
 
- Actions to open specific menus can be exported and added to Reaper's Action List.
 
- Shift-click buttons in the radial menu at left to edit them. Like menus, they can each have their own colors, or they can use the parent menu's colors; if the menu has no colors assigned, buttons will likewise grab their colors from the Global settings.
  
- To paste an action ID, use the Paste button; scripts don't have a way to access your operating system's clipboard.

]]},



	{"Context", 
[[    Important: Context functions require the SWS extension for Reaper to be installed.
 
- By default, Radial Menu will always open menu 0 at startup. This tab allows you to specify different menus to open based on which Reaper area the mouse cursor is over - i.e. one set of actions for tracks and another for media items.
  
- Any contexts left blank will look at the 'level' above them for a match, and the level above that, eventually defaulting back to 0.
 
- Contexts can be assigned via menu numbers or aliases. 
 
- Double-clicking any of the text boxes will jump to that menu.
 
- To find the context for a Reaper element, hover the mouse over it, making sure this window is in focus, and press F1.
	
]]},



	{"Swiping",
		
[[- The basic Radial Menu wasn't fast enough for you? Try this. Swiping lets you trigger menus and actions via mouse movements, in the same way as answering a call on your mobile phone.
 	
- When Swiping is enabled, quickly move the mouse out from the center of the Radial Menu window; the option you swiped over will be 'clicked'. If a submenu is opened via Swiping, the script window will re-center itself on your mouse cursor, allowing very fast navigation through your menus.
 
 
- Start sensitivity: Lower values will require you to move the mouse faster to track a Swipe; higher values will start Swiping even with slow movement.
 
- Stop sensitivity: How much the mouse needs to slow down to be considered "stopped", triggering the Swipe action. Lower vaues will require your cursor to be almost completely stopped, higher values will only need you to slow down a little.
 
- Stop time: How long the mouse needs to be stopped, as determined by the 'Stop sensitivity' setting, before triggering the action.
 
- Swiping threshold: Defines a 'safe zone' in which Swiping won't be tracked, e.g. so you can use the menu buttons normally without accidentally triggering a Swipe.
 
- You may need to fine-tune all four sliders together to find a Swipe behavior that feels right for you.
		
]]},



	{"Global",
		
[[- Any menus that don't have their own colors specified will look here, as will buttons in those menus don't have colors of their own.
 
- Sizes and target areas for the radial menu can be adjusted here. Be aware that the 'preview' labels drawn when hovering over a menu are centered between the red and yellow rings, so some combinations of settings may not look very good.
 
- The font controls should be mostly self-explanatory. One thing - the little green (or red) lights are there to tell if you what you've typed is a font. 
 
- NOTE: Fonts may not use the same name you'd see in Microsoft Office, etc. It's dependent on metadata in the font file itself - on Windows, right-click a .ttf file, choose Properties, and select the Details tab - the Name field is what you want to be using here. Mac users... I have no idea.
 
 
- If you wish, Radial Menu can also have keyboard keys assigned to "click" each button in a menu.
 
- Bindings are assigned separately for each possible menu size, since you may want to use a different set of keys with a menu of four buttons versus sixteen.
 
- Key binds can be displayed outside the menu ring, for those of us with faulty memories.
 
- NOTE: Key binds should not be expected to play nicely with 'repeat' actions. Key binds WILL, however, repeat normal actions on their own when the key is held down.
 
 
]]},



	{"Options",
		
[[- The various settings here may not all work with each other.
 	
- Likewise, some of Reaper's actions may not play nicely with your settings here; particularly, anything that opens a window or otherwise takes 'focus' away from the script. It's a Reaper issue, unfortunately.
 
- Settings are saved to 'Lokasenna_Radial Menu settings.txt' in the same folder as this script. Feel free to edit it, but make sure it's written with proper Lua syntax. The settings file also has further documentation for most parameters.
]]},	
	
}


local function init_help_pages()
	
	_=dm and Msg(">init_help_pages")
	
	local w = GUI.elms.frm_help.w - 2*GUI.elms.frm_help.pad
	
	local str_arr = {}
	
	for k, v in ipairs(help_pages) do
		
		-- Add this page's title to the list
		table.insert(str_arr, v[1])	
	
		-- Wrap all of the pages to fit in the frame	
		help_pages[k][2] = GUI.word_wrap(v[2], 4, w, 0, 2)	
	
	end
	
	--table.insert(str_arr, 3, "")
	
	-- Update the Help menu
	GUI.elms.mnu_help.optarray = str_arr
	GUI.elms.mnu_help.numopts = #str_arr
	
	_=dm and Msg("<init_help_pages")
	
end
	
	

local mnu_arr = {}

-- The default settings and menus
local def_mnu_arr = {
	
	-- Using index -1 for random settings so that 'for i = 0, #mnu_arr'
	-- loops won't even see it
	[-1] = {
		["close_time"] = 600,		
		["col_main"] = {0.753, 0.753, 0.753},
		["col_hvr"] = {0.878, 0.878, 0.878},
		["col_tog"] = {0, 0.753, 0},
		["col_bg"] = {0.2, 0.2, 0.2},
		["contexts"] = {},
		["fonts"] = {
						[1] = 	{	-- Normal button labels
									"Calibri", 
									16, 
									"b"
								},
						[2] = 	{	-- Menu labels
									"Calibri", 
									16, 
									"bu"
								},	
						[3] = 	{	-- Preview text
									"Calibri", 
									14
								},		
					},
		["hvr_click"] = false,
		["hvr_time"] = 200,		
		["key_binds"] = {
							enabled = false,
							hints = false,
							last_num = 8,
							[4] = {},
							[5] = {},
							[6] = {},
							[7] = {},
							[8] = {},
							[9] = {},
							[10] = {},
							[11] = {},
							[12] = {},
							[13] = {},
							[14] = {},
							[15] = {},
							[16] = {},							
						},
		["key_mode"] = 1,
		["last_pos"] = {0,0},
		["last_tab"] = 1,
		["mouse_mode"] = 1,
		["num_btns"] = 8,		
		["preview"] = true,
		["ra"] = 48,
		["rb"] = 60,
		["rc"] = 116,
		["rd"] = 192,
		["re"] = 192,
		["swipe"] = {
						accel = 65,
						actions = false,
						decel = 10,
						stop = 20,
						menu_mode = 1,
						menu = 0,
					},
		["win_pos"] = 1,
	},
	-- Base level
	[0] = {
		-- Submenu titles 
		[0] = { lbl = "Empty", act = ""},
		[1] = { lbl = "Empty", act = ""},
		[2] = { lbl = "Empty", act = ""},
		[3] = { lbl = "Empty", act = ""},
		[4] = { lbl = "Empty", act = ""},
		[5] = { lbl = "Empty", act = ""},
		[6] = { lbl = "Empty", act = ""},
		[7] = { lbl = "Empty", act = ""},
	}		
}




-- All of our context text boxes' contents
local context_arr = setup and {
	{lbl = "TCP", 			con = "tcp", 								head = 1},
	{lbl = "Track", 		con = "tcp|track", 							head = 2},
	{lbl = "Envelope", 		con = "tcp|envelope", 						head = 2},
	{lbl = "Empty", 		con = "tcp|empty", 							head = 2},
	{lbl = ""},
	{lbl = "MCP", 			con = "mcp", 								head = 1},
	{lbl = "Track",			con = "mcp|track",							head = 2},
	{lbl = "Empty",			con = "mcp|empty", 							head = 2},
	{lbl = ""},
	{lbl = "Ruler", 		con = "ruler", 								head = 1},
	{lbl = "Region lane", 	con = "ruler|region_lane", 					head = 2},
	{lbl = "Marker lane", 	con = "ruler|marker_lane", 					head = 2},
	{lbl = "Tempo lane", 	con = "ruler|tempo_lane", 					head = 2},
	{lbl = "Timeline", 		con = "ruler|timeline", 					head = 2},

	{lbl = "Arrange", 		con = "arrange", 							head = 1},
	{lbl = "Track", 		con = "arrange|track",						head = 2},
	{lbl = "Empty", 		con = "arrange|track|empty", 				head = 3},
	{lbl = "Item", 			con = "arrange|track|item",					head = 3},
	-- The API function currently won't return this context properly:
	--{lbl = "Stretch Marker",con = "arrange|track|item_stretch_marker", 	head = 3},
	{lbl = "Env. Point",	con = "arrange|track|env_point",			head = 3},
	{lbl = "Env. Segment",	con = "arrange|track|env_segment",			head = 3},
	{lbl = "Envelope",		con = "arrange|envelope",					head = 2},
	{lbl = "Empty", 		con = "arrange|envelope|empty",				head = 3},
	{lbl = "Env. Point",	con = "arrange|envelope|env_point",			head = 3},
	{lbl = "Env. Segment",	con = "arrange|envelope|env_segment",		head = 3},
	{lbl = "Empty", 		con = "arrange|empty", 						head = 2},

	{lbl = "Transport", 	con = "transport", 							head = 1},
	{lbl = ""},
	{lbl = "MIDI Ed.",		con = "midi_editor",						head = 1},
	{lbl = "Ruler", 		con = "midi_editor|ruler",					head = 2},
	{lbl = "Piano Roll",	con = "midi_editor|piano",					head = 2},
	{lbl = "Notes",			con = "midi_editor|notes",					head = 2},
	{lbl = "CC Lane",		con = "midi_editor|cc_lane",				head = 2},
	{lbl = "CC Selector",	con = "midi_editor|cc_lane|cc_selector",	head = 3},
	{lbl = "CC Lane",		con = "midi_editor|cc_lane|cc_lane",		head = 3},

}



--[[	
local depth_arr = {}
local function new_depth(depth)
	
	table.insert(depth_arr, cur_depth)
	return depth
	
end
local function last_depth()
	
	local depth = depth_arr[#depth_arr]
	if depth == 0 then
		depth_arr = {base_depth}
	else
		table.remove(depth_arr, #depth_arr)
	end
	
	return depth
	
end
]]--


-- Create a new button in the specified position and menu
local function init_btn(i, j, lbl)
	
	_=dm and Msg("init button "..tostring(i)..", menu "..tostring(j))
	
	mnu_arr[i][j] = { ["lbl"] = lbl.." "..j, ["act"] = "" }
	
end


-- Create a blank submenu
local function init_menu(i, num_btns, alias)
	
	if mnu_arr[i] then
		reaper.ShowMessageBox("Menu "..tostring(i).." already exists.", "Whoops", 0)
		return 0
	elseif i < 0 then
		reaper.ShowMessageBox("Menus may only use positive numbers.", "Whoops", 0)
		if cur_depth == i then cur_depth = 0 end
		return 0
	end
	
	local num_btns = num_btns or mnu_arr[-1].num_btns
	local lbl = alias or ("menu "..i)
	
	_=dm and Msg("init menu: "..tostring(i).."  "..tostring(num_btns)..tostring(alias).."  ")
	
	mnu_arr[i] = {}
	

	if alias then 
		_=dm and Msg("\talias: "..tostring(alias))
		mnu_arr[i].alias = alias 
	end
	
	mnu_arr[i][-1] = {	lbl = "Back",
						act = "back" }
	
	for j = 0, (num_btns - 1) do

		init_btn(i, j, lbl)
	
	end
end



--[[
	Adapted from a post on Stack Overflow:http://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions

	- Changed ' ' indents to a full tab
	- Table indices are given []s and ""s where appropriate; Lua was
	  refusing to read the output as a table without them
	- Combined type calls for Number and Boolean since they can both use tostring()

]]--
local function serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep("\t", depth)

	if name then 
		tmp = tmp .. "[" .. 
		((type(name) == "string") and ('"'..name..'"') or name)
		.. "] = " 
	end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in GUI.kpairs(val, "full") do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep("\t", depth) .. "}"
    elseif type(val) == "number" or type(val) == "boolean" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    else
        tmp = tmp .. "\"[unserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end


-- Save the current menu settings to a text file
-- (Same name and path as the script)
local function save_menu(export)
	
	local file_name = settings_file_name
	
	if export then
		
		local ret, user_file = reaper.GetUserInputs("Export settings", 1, 
			"Export to ...this script's folder...".. GUI.file_sep .. "____.txt' :,extrawidth=64",
			"my settings")
		
		if ret then
			file_name = script_path .. GUI.file_sep .. user_file..".txt"
		else
			return 0
		end

	end

	if not file_name then return 0 end
	
	local file, err = io.open(file_name, "w+") or nil
	if not file then 
		reaper.ShowMessageBox("Couldn't open the file.\nError: "..tostring(err), "Whoops", 0)
		return 0 
	end

	local str = settings_help_str .. "\n\nreturn "..serializeTable(mnu_arr)
	
	file:write(str)
	
	io.close(file)
	
end



-- Load the settings file, or browse for a new one
local function load_menu(browse)

	_=dm and Msg(">load_menu")

	local file_name = reaper.file_exists(settings_file_name) and settings_file_name or example_file_name
	
	--local load_settings
	if browse then
		_=dm and Msg("\tprompting for a file")
		local ret, user_file = reaper.GetUserFileNameForRead("", "Import menus...", ".txt" )
		if ret then 
			file_name = user_file
			--load_settings = reaper.ShowMessageBox("Import this file's global settings as well?", "Import settings?", 3)
		end
	
		-- If the user hit Cancel in either of the dialogs
		--if not ret or load_settings == 2 then return 0 end
	
	end
	
	
	_=dm and Msg("\topening "..tostring(file_name))

	local file, err
	if reaper.file_exists(file_name) then
		file, err = io.open(file_name, "r") or nil
	end
		
	if file then
		
		local arr

		_=dm and Msg("\tparsing saved menus")

		local str = file:read("*all")
		
		if str then	arr, err = load(str) end
		if not err then 
			_=dm and Msg("\tparsed menu; checking for missing values\n")
			
			local ret = browse and reaper.ShowMessageBox("Would you like to keep your existing global settings and options?", "Keep global settings?", 3)
			local set_arr
			
			if ret == 2 then
				return 0
				
			elseif ret == 6 then
				set_arr = mnu_arr[-1]
				set_arr.contexts = {}
				set_arr.swipe.menu = 0
				
				update_context_elms()
				update_key_elms()
				
			end

			
			arr = arr()
			
			-- Check for any missing settings in [-1] and copy them from the defaults
			arr[-1] = GUI.table_copy(def_mnu_arr[-1], arr[-1], 1)
			
			-- Copy the final table over to mnu_arr
			mnu_arr = arr
			if set_arr then mnu_arr[-1] = set_arr end
			if browse then 	mnu_arr[-1].last_tab = 5 end
			
		else
			reaper.ShowMessageBox("Error parsing menu file:\n"..tostring(err), "Invalid menu file", 0)
			return 0
		end

		io.close()
	else
		
		if not setup then
			reaper.ShowMessageBox("\tError opening menu file:\n\t"..tostring(err).."\n\nIf this is your first time using Radial Menu,\nyou'll need to run the Setup script first.", "Menu file not found", 0)
			return 0
		else
			-- Submenus for all of the default menu items
			mnu_arr = def_mnu_arr
		end
	end	

	_=dm and Msg("<load_menu")

end




-- Print out the contents of mnu_arr, for debugging and shit
local function spit_table()

	Msg( serializeTable(mnu_arr) )

end



-- Creates a separate script that loads Radial Menu with a specific menu
local function mnu_shortcut()

	local mnu, alias = cur_depth, mnu_arr[cur_depth].alias
	local file_name = 	script_path 
					..	"Lokasenna_Radial Menu - Open menu "
					..	mnu 
					.. 	(alias and (" - " .. alias) or "") 
					..	".lua"

	local str1 = "-- This script was generated by Lokasenna_Radial Menu.lua\n"
	local str2 = "open_depth = "..mnu.."\n"
	
	local str3 = 
[=[local script_path = debug.getinfo(1,'S').source:match[[^@?(.*[\/])[^\/]-$]]
dofile(script_path .. "Lokasenna_Radial Menu.lua")]=]
	
	local file_str = string.len(file_name) > 48 	and ("..."..string.sub(file_name, -45))
													or	file_name
	local file, err = io.open(file_name, "w+")
	
	if not file then
		reaper.ShowMessageBox(	  	"Couldn't create script:\n"
								..	file_str
								..	"\nError: "..tostring(err), "Whoops", 0)
		return 0
	else
	
		file:write(str1 .. str2 .. str3)
		io.close()
		
		reaper.AddRemoveReaScript( true, 0, file_name, true )		
		
		reaper.ShowMessageBox("Created script, and added it to the Action List.\n\n"..file_str, "Yay!", 0)
		
	end

end




local function check_alias(str)

	if str == "" or str == nil then return false end

	_=dm and Msg("\tlooking up alias '"..tostring(str).."'")

	for i, v in pairs(mnu_arr) do
		
		if mnu_arr[i].alias and mnu_arr[i].alias == str then	
			_=dm and Msg("\tfound menu: "..tostring(i))
			return tonumber(i)
		end
		
		
	end
	
	_=dm and Msg("\tno alias found")
	return false
	
end



-- Get the mouse context from Reaper and parse it into context_arr's format
local function get_context_str()
	
	local wnd, seg, det = reaper.BR_GetMouseCursorContext()
			
	local str = (not wnd or wnd == "unknown")
				and ""
				or wnd .. 	((not seg or seg == "")
							and ""
							or "|" .. seg ..	(( not det or det == "" )
												and ""
												or "|" .. det 
												)
							)	
	
	return str
	
end


-- Find the appropriate menu for the current mouse context
local function get_context_mnu()
	
	_=dm and Msg("<get_context_mnu")
	
	local str = GUI.SWS_exists and get_context_str() or ""
		
	-- See if there's an exact match; if there isn't, trim off the last value and try again
	while str do
		_=dm and Msg("\tlooking for context: '"..tostring(str).."'")
		if mnu_arr[-1].contexts[str] then
			_=dm and Msg("\tfound context at "..str)
			local depth = mnu_arr[-1].contexts[str]
			depth = tonumber(depth) or check_alias(depth)
			_=dm and Msg(tostring(depth))
			if depth and depth > 0 then
				base_depth = depth
				break
			end
		end
		str = string.match(str, "(.*)|[^|]*$")
		
	end
	
	-- Show the user what context is being used
	if str then 
		--GUI.elms.lbl_context = GUI.Label:new(1,	8, -20, "Context: "..str, false, 4) 
		GUI.name = "Context:  "..string.gsub(str, "|", ", ")
	end
	
	cur_depth = base_depth
	_=dm and Msg("\tsettled on depth "..base_depth)
	_=dm and Msg("<get_context_mnu")
	
end

-- Highlight the text box for the current mouse context
local function get_context_txt()
	
	_=dm and Msg(">get_context_txt")
	
	if not GUI.SWS_exists then
		
		reaper.ShowMessageBox("Context functions require the SWS extension for Reaper to be installed.", "SWS not found", 0)
		return 0
		
	end
	
	local str = get_context_str()
			
	_=dm and Msg("\tgot context str: "..tostring(str))

	if str and str ~= "" then

		for k, v in pairs(context_arr) do

			if v.con == str then
				GUI.elms["txt_context_"..k].focus = true
			elseif v.lbl ~= "" then
				GUI.elms["txt_context_"..k].focus = false
			end
			
		end		
		
	end
	
	GUI.redraw_z[6] = true	
		
	_=dm and Msg("<get_context_txt")	
		
end



-- Parse and run the current action
local function run_act(act, midi)

	_=dm and Msg(">run_act")
	_=dm and Msg("running action: "..tostring(act))

	-- Blank?
	if act == "" then
		
		return 0
		--last_depth = 0
		--cur_depth = 0
	
	
	
	-- Our various special commands
	elseif act == "back" then
	
		
		_=dm and Msg("\tresetting to base depth")
		cur_depth = #prev_depths > 0 and table.remove(prev_depths) or base_depth
		if setup then  end
		cur_btn = -2
		redraw_menu = true
		
		
	elseif act == "base" then
	
		run_act("menu "..tostring(base_depth))
	
	
	elseif act == "quit" then
	
		_=dm and Msg("\tuser action asked to quit")
		GUI.quit = true
		return 0
		
	
	elseif string.match(act, "^midi") then
	
		run_act( string.sub(act, 6), true)
		return 0
	
	
	elseif string.match(act, "^smart") then
	
		-- Toggle the current button "armed"
		-- Changing menus will also disarm
		
		smart_act = act
		
		
	elseif string.match(act, "^x%d") then
	
		local num, act = string.match(act, "^x(%d+) ([^ ]+)")
		num = tonumber(num)
		
		if num and act then
			
			for i = 1, num do
				run_act(act, midi)
			end
			
		end
		

	-- Is it a menu?
	elseif string.match(act, "^menu") then
					
		local num = string.sub(act, 6)
		
		_=dm and Msg("\topening menu "..tostring(num))
		
		new_depth = tonumber(num) or check_alias(num)
		
		if new_depth then
			
			if new_depth == base_depth then
				prev_depths = {}
			else
				table.insert(prev_depths, cur_depth)
			end
			
			cur_depth = new_depth
			--if setup then  end
			cur_btn = -2
			
			armed = -2
			smart_act = ""
			
			redraw_menu = true
			
		else
		
			reaper.ShowMessageBox("Menu '"..tostring(num).."' doesn't seem to exist.", "Whoops", 0)
			
		end	
	
	
	-- It's not a special command, so it must be a plain ol' action
	else

		if string.sub(act, 1, 1) == "_" then act = reaper.NamedCommandLookup(act) end
		
		-- Just some error checking because Lua occasionally 
		-- throws a fit about numbers that are strings
		act = tonumber(act)
		
		_=dm and Msg("sending action to Reaper: "..tostring(act))
		
		if act and act > 0 then 
			
			if not midi then
				reaper.Main_OnCommand(act, 0) 
			else
				local wnd = reaper.MIDIEditor_GetActive()
				if wnd then reaper.MIDIEditor_OnCommand(wnd, act) end
			end
			
			if not setup then
				
				if mnu_arr[-1].mouse_mode == 2 then
					run_act("back")
					redraw_menu = true
				elseif mnu_arr[-1].mouse_mode == 3 then
					GUI.quit = true
				end

			end
		end
	end	

	_=dm and Msg("\tcur_depth is now "..tostring(cur_depth))
	_=dm and Msg("<run_act")	
	
end



-- Figure out an appropriate text color for a given background
-- Adapted from WT's 'colorsmart' macro in the Default 5.0 theme
local function colorsmart(bg)
--[[
set luma      + + * 0.299 [trackcolor_r] * 0.587 [trackcolor_g] * 0.114 [trackcolor_b]
	=	0.299 * r	+	0.587 * g	+	0.114 * b

]]--
	local r, g, b = table.unpack(bg)
	local luma = 0.299 * r + 0.587 * g + 0.114 * b

	-- I love this ternary structure so, so much
	return (luma > 0.4) 	and ((luma > 0.9) and 	{0, 0, 0}
											  or	{0.1, 0.1, 0.1}
								)
							or  ((luma > 0.1) and	{0.9, 0.9, 0.9}
											  or	{1, 1, 1}
								)
end


-- Automate the process of looking for color values so I don't
-- have to keep typing it out every time
local function get_color(key, i)
	
	local col

	if key == "hvr_tog" or key == "bg_tog" then
		
		_=dm and Msg("getting hover/toggle colors @ "..i)
		
		local col_str = (key == "hvr_tog") and "col_hvr" or "col_bg"
		
		local col_a, col_b = get_color(col_str, i), get_color("col_tog", i)
		_=dm and Msg("col_a = "..table.concat(col_a, ", "))
		_=dm and Msg("col_b = "..table.concat(col_b, ", "))
		
		_=dm and Msg("got colors, getting gradient")
		
		col = {GUI.gradient(col_a, col_b, 0.5)}

		_=dm and Msg("grad rgb = "..table.concat(col, ", "))

	else
		
		if mnu_arr[cur_depth][i] and mnu_arr[cur_depth][i][key] then
			col = mnu_arr[cur_depth][i][key]
		elseif mnu_arr[cur_depth][key] then
			col = mnu_arr[cur_depth][key]
		else
			col = mnu_arr[-1][key]
		end
	end

	return col

end




-- Update the "Working on menu" box's menu list
local function update_mnu_menu()
	
	_=dm and Msg(">update_mnu_menu")
	
	local arr = {}

	_=dm and Msg("\tadding menus to arr")

	local str
	for k, v in pairs(mnu_arr) do
		
		if k >= 0 then
			
			if mnu_arr[k].alias then
				str = k.." - "..mnu_arr[k].alias
			else
				str = k
			end
			table.insert(arr, str)
			
			_=dm and Msg("\t\t"..#arr.." = "..arr[#arr])
			
		end
	end
	
	_=dm and Msg("\tmade arr")
	
	table.sort(arr, GUI.full_sort)
	
	-- Make a note of which entry is the current menu
	-- so we can set it afterward
	
	_=dm and Msg("\tlooking for current depth")
	
	local val
	for k, v in pairs(arr) do
		_=dm and Msg("\t\t"..tostring(k).." = "..tostring(v))
		if tonumber(string.match(v, "^(%d+)")) == cur_depth then
			_=dm and Msg("\tfound val "..tostring(v).." at pos "..tostring(k))
			val = k
			break
		end
	end
	
	GUI.elms.mnu_menu.optarray = arr
	GUI.elms.mnu_menu.numopts = #arr
	--GUI.Val("mnu_menu", tonumber(val))
	GUI.elms.mnu_menu.retval = tonumber(val)
	
	_=dm and Msg("<update_mnu_menu")

end



-- Update global/misc settings from the values in mnu_arr
local function update_glbl_settings()
	
	_=dm and Msg(">update_glbl_settings")

	-- Swipe tab stuff
	GUI.Val("chk_swipe", {mnu_arr[-1].swipe.enabled})
	GUI.elms.frm_no_swipe.z = mnu_arr[-1].swipe.enabled and 20 or 17
	GUI.Val("sldr_accel", mnu_arr[-1].swipe.accel)
	GUI.Val("sldr_decel", mnu_arr[-1].swipe.decel)
	GUI.Val("sldr_stop", mnu_arr[-1].swipe.stop / 5 - 1)
	GUI.Val("opt_swipe_mode", mnu_arr[-1].swipe.mode)
	GUI.Val("txt_swipe_menu", mnu_arr[-1].swipe.menu)
	GUI.Val("chk_swipe_acts", {mnu_arr[-1].swipe.actions})



	GUI.elms.frm_col_g_btn.col_user = mnu_arr[-1].col_main
	GUI.elms.frm_col_g_hvr.col_user = mnu_arr[-1].col_hvr
	GUI.elms.frm_col_g_tog.col_user = mnu_arr[-1].col_tog
	GUI.elms.frm_col_g_bg.col_user = mnu_arr[-1].col_bg

	GUI.Val("sldr_num_btns", mnu_arr[-1].num_btns - GUI.elms.sldr_num_btns.min)
	GUI.Val("chk_preview", mnu_arr[-1].preview)
	
	
	GUI.Val("txt_font_A", mnu_arr[-1].fonts[1][1])
	GUI.Val("txt_font_B", mnu_arr[-1].fonts[2][1])
	GUI.Val("txt_font_C", mnu_arr[-1].fonts[3][1])
	
	GUI.Val("txt_size_A", mnu_arr[-1].fonts[1][2])
	GUI.Val("txt_size_B", mnu_arr[-1].fonts[2][2])	
	GUI.Val("txt_size_C", mnu_arr[-1].fonts[3][2])
	
	local fA, fB, fC =	mnu_arr[-1].fonts[1][3] or "",
						mnu_arr[-1].fonts[2][3] or "",
						mnu_arr[-1].fonts[3][3] or ""
						
					
	GUI.Val("chk_flags_A", 	{	not not string.match(fA, "b"),
								not not string.match(fA, "i"),
								not not string.match(fA, "u")
								}
	)
	GUI.Val("chk_flags_B", 	{	not not string.match(fB, "b"),
								not not string.match(fB, "i"),
								not not string.match(fB, "u")
								}
	)
	GUI.Val("chk_flags_C", 	{	not not string.match(fC, "b"),
								not not string.match(fC, "i"),
								not not string.match(fC, "u")
								}
	)
	
	
	GUI.Val("chk_keys", mnu_arr[-1].key_binds.enabled)
	GUI.Val("chk_hints", mnu_arr[-1].key_binds.hints)
	
	local num = mnu_arr[-1].key_binds.last_num
	GUI.Val("mnu_keys", num)	

	GUI.Val("tabs", mnu_arr[-1].last_tab)

	GUI.Val("opt_win_pos", mnu_arr[-1].win_pos)
	GUI.Val("opt_mouse_mode", mnu_arr[-1].mouse_mode)
	GUI.Val("opt_key_mode", mnu_arr[-1].key_mode)
	GUI.Val("chk_misc_opts", {mnu_arr[-1].hvr_click})
	GUI.Val("txt_hvr_time", mnu_arr[-1].hvr_time)
	GUI.Val("txt_close_time", mnu_arr[-1].close_time)


	GUI.redraw_z[GUI.elms.frm_col_g_btn.z] = true
	
	redraw_menu = true

	_=dm and Msg("<update_glbl_settings")

	
end


-- Update menu settings from the values in mnu_arr
local function update_mnu_settings()
	
	_=dm and Msg("updating menu settings, cur_depth = "..tostring(cur_depth))
	
	if not mnu_arr[cur_depth] then 
		init_menu(cur_depth) 
		update_mnu_menu()
	end
	
	GUI.Val("txt_alias", mnu_arr[cur_depth].alias or "")
	
	local c_main, c_hvr, c_tog, c_bg
	
	c_main = get_color("col_main", -2)
	c_hvr = get_color("col_hvr", -2)
	c_tog = get_color("col_tog", -2)
	c_bg = get_color("col_bg", -2)
	
	GUI.elms.frm_col_m_btn.col_user = c_main
	GUI.elms.frm_col_m_hvr.col_user = c_hvr
	GUI.elms.frm_col_m_tog.col_user = c_tog
	GUI.elms.frm_col_m_bg.col_user = c_bg
	
	GUI.Val("chk_center", ({not not mnu_arr[cur_depth][-1]}))
	
	
	-- See if this is the menu assigned to swiping
	local swipe = mnu_arr[-1].swipe.menu
	if  	mnu_arr[-1].swipe.enabled 
		and cur_depth == (tonumber(swipe) or check_alias(swipe)) 
		and GUI.Val("opt_swipe_mode") == 2 
		then
		
		GUI.elms.frm_swipe_menu.z = 22
		GUI.elms.lbl_swipe_menu.z = 22
			
		
	else
	
		GUI.elms.frm_swipe_menu.z = 20
		GUI.elms.lbl_swipe_menu.z = 20
	
	end
	
	redraw_menu = true

	GUI.redraw_z[GUI.elms.frm_col_m_btn.z] = true
	
	_=dm and Msg("done updating menu settings")
	
end


-- Update the current button settings from the values in mnu_arr
local function update_btn_settings()
	
	_=dm and Msg("updating button settings, cur_btn = "..tostring(cur_btn))
	
	local lbl, act, c_main, c_hvr, c_tog
	if cur_btn ~= -2 then
		lbl = mnu_arr[cur_depth][cur_btn].lbl or ""
		act = mnu_arr[cur_depth][cur_btn].act or ""
		r_act = mnu_arr[cur_depth][cur_btn].r_act or ""
		m_act = mnu_arr[cur_depth][cur_btn].m_act or ""
		c_main = get_color("col_main", cur_btn)
		c_hvr = get_color("col_hvr", cur_btn)
		c_tog = get_color("col_tog", cur_btn)
		GUI.elms.frm_no_btn.z = 20
	else
		lbl = ""
		act = ""
		c_main = "elm_frame"
		c_hvr  = "elm_frame"
		c_tog  = "elm_frame"
		GUI.elms.frm_no_btn.z = 3
	end
	
	GUI.Val("txt_btn_lbl", lbl)
	GUI.Val("txt_btn_act", act)
	GUI.Val("txt_btn_r_act", r_act)
	GUI.Val("txt_btn_m_act", m_act)
	GUI.elms.frm_col_b_btn.col_user = c_main
	GUI.elms.frm_col_b_hvr.col_user = c_hvr
	GUI.elms.frm_col_b_tog.col_user = c_tog
	GUI.redraw_z[GUI.elms.frm_col_b_btn.z] = true
	
	redraw_menu = true
	
	_=dm and Msg("done updating button settings")
		
end



-- Clear all the menu settings
local function clear_menu()
	
	local ret = reaper.ShowMessageBox("Would you like to keep your existing global settings and options?", "Keep global settings?", 3)
	
	if ret == 2 then
		return 0
	else
		if ret == 6 then
			local set_arr = mnu_arr[-1]
			mnu_arr = def_mnu_arr
			mnu_arr[-1] = set_arr
			mnu_arr[-1].contexts = {}
			mnu_arr[-1].swipe.menu = 0
			
		elseif ret == 7 then
			mnu_arr = def_mnu_arr
			
		end

		cur_depth = 0
		last_depth = 0
		cur_btn = -2
	
		update_glbl_settings()
		update_mnu_settings()
		update_mnu_menu()
		update_btn_settings()
		update_context_elms()
		update_key_elms()
		
	end
	
end




-- Reset the global colors
local function reset_glbl_colors()
	
	mnu_arr[-1].col_bg = def_mnu_arr[-1].col_bg
	mnu_arr[-1].col_main = def_mnu_arr[-1].col_main
	mnu_arr[-1].col_tog = def_mnu_arr[-1].col_tog
	mnu_arr[-1].col_hvr = def_mnu_arr[-1].col_hvr
	
	update_glbl_settings()
	update_mnu_settings()
	update_btn_settings()
	
	
end


-- Clear the menu's custom colors so get_color will use the globals
local function use_global_colors()
	
	mnu_arr[cur_depth].col_main = nil
	mnu_arr[cur_depth].col_hvr = nil
	mnu_arr[cur_depth].col_tog = nil	
	mnu_arr[cur_depth].col_bg = nil
	
	update_mnu_settings()
	
end


-- Clear the button's custom colors so get_color will use the menu
local function use_menu_colors()
	
	mnu_arr[cur_depth][cur_btn].col_main = nil
	mnu_arr[cur_depth][cur_btn].col_hvr = nil
	mnu_arr[cur_depth][cur_btn].col_tog = nil
	
	update_btn_settings()
	
end


-- Since we can't access the clipboard directly, this provides a space
-- for the user to paste action IDs into the script
local function paste_act(btn)
	-- retval, retvals_csv reaper.GetUserInputs( title, num_inputs, captions_csv, retvals_csv )
	local ret, act = reaper.GetUserInputs("Copy/paste actions", 1, "Copy/paste actions here:,extrawidth=128", ( mnu_arr[cur_depth][cur_btn][btn] or "" ) )
	
	if ret then
		mnu_arr[cur_depth][cur_btn][btn] = act
		update_btn_settings()
	end
	
end


-- Open the settings file in an external editor
local function open_txt()
	
	GUI.open_file(settings_file_name)
	
end


-- Add and delete menus
local function add_menu()
	
	_=dm and Msg("Adding menu")
	
	
	-- Find the first blank menu
	local i, def_num = 0
	while not def_num do
		
		if not mnu_arr[i] then
			def_num = i
			break
		end
		
		i = i + 1
		
	end
	
	
	local ret, vals = reaper.GetUserInputs("Add a new menu", 3, "Add menu number:,Alias:,Number of buttons:", (def_num or "")..",,"..mnu_arr[-1].num_btns)
	
	_=dm and Msg("\tCSV: "..tostring(vals))
	
	local num, alias, btns = string.match(vals, "([^,]+),([^,]*),([^,]+)")
	num, btns = tonumber(num), tonumber(btns)
	if alias == "" then alias = nil end
	
	_=dm and Msg("\tParsed as: Menu "..tostring(num)..", Alias: "..tostring(alias)..", Buttons: "..tostring(btns))

	if ret and num and btns then
		cur_depth = num
		init_menu(tonumber(num), tonumber(btns), alias)

		
		cur_btn = -2
		update_mnu_menu()
		update_mnu_settings()
		update_btn_settings()
	end
	
	
end

local function del_menu()
	
	_=dm and Msg("deleting menu "..tostring(cur_depth))
	
	if cur_depth == 0 then return 0 end
	
	local arr = {}
	local act
	
	for k, v in pairs(mnu_arr) do
		
		if k >= 0 then
			table.insert(arr, k)
			
			-- Look for any buttons that were assigned to this menu and clear them
			for i = -1, #mnu_arr[k] do
				
				if mnu_arr[k][i] and mnu_arr[k][i].act then
					act = mnu_arr[k][i].act
				
					if string.match(act, "menu "..cur_depth) 
						or	(mnu_arr[cur_depth].alias and string.match(act, "menu "..mnu_arr[cur_depth].alias) ) then
					
						_=dm and Msg("\tclearing button "..tostring(i).." in menu "..tostring(k))
						mnu_arr[k][i].act = ""						
					end
				end				
			end			
		end
	end
	
	table.sort(arr, GUI.full_sort)
	
	-- Now that we have a list, the current menu can go away
	mnu_arr[cur_depth] = nil
	cur_btn = -2
	
	_=dm and Msg("\tgetting new menu value")
	
	-- Find the menu number below this one
	local val
	for k, v in pairs(arr) do
		if v == cur_depth then
			_=dm and Msg("\t\tfound "..v.." at pos "..k)
			cur_depth = arr[k - 1] or 0
			_=dm and Msg("\t\tnew depth = "..tostring(cur_depth))
			break
		end
	end
	
	_=dm and Msg("finished deleting, updating settings")
	
	update_mnu_menu()
	update_mnu_settings()
	update_btn_settings()	
	
end


-- Add and remove buttons to the current menu
local function remove_btn(cur)
	
	_=dm and Msg("deleting a button")
	
	if cur and cur_btn == -1 then
		
		mnu_arr[cur_depth][-1] = nil
		GUI.Val("chk_center", {false})
		cur_btn = -2
		
	elseif #mnu_arr[cur_depth] > 0 then
	
		local num = cur and cur_btn or #mnu_arr[cur_depth]
		local new_arr, arr_num, arr_hash = {}, {}, {}
		
		_=dm and Msg("\tcreating temporary array")


		-- Separate the table by key into nums and hash
		for k, v in pairs(mnu_arr[cur_depth]) do
			if tonumber(k) then
				arr_num[tonumber(k)] = v
			else
				arr_hash[k] = v
			end
		end
		
		-- Remove the button
		arr_num[num] = nil
		
		
		local k = -1
		
		for i = -1, #mnu_arr[cur_depth] do
			
			if arr_num[i] then
				new_arr[k] = arr_num[i]
				k = k + 1
			end
			
		end
		
		-- Throw the hash values back in
		for k, v in pairs(arr_hash) do
			
			new_arr[k] = v
			
		end
		
		
		mnu_arr[cur_depth] = new_arr
		
		cur_btn = -2

--[[		
		if #mnu_arr[cur_depth] > 0 then
			if cur_btn == #mnu_arr[cur_depth] then cur_btn = -2 end
			table.remove(mnu_arr[cur_depth], #mnu_arr[cur_depth])
			update_btn_settings()
			GUI.redraw_z[0] = true
		end
]]--		
	end
	
	update_btn_settings()
	GUI.redraw_z[0] = true
	
end

local function add_btn()
	
	--GUI.Msg(cur_depth.." | "..#mnu_arr[cur_depth].." | "..mnu_arr[cur_depth].lbl)
	if #mnu_arr[cur_depth] < 15 then
		init_btn(cur_depth, #mnu_arr[cur_depth] + 1, "btn")	
		update_btn_settings()
		GUI.redraw_z[0] = true
	end
end


local function move_btn(dir)
	
	if cur_btn < 0 then return 0 end
	
	local btn = mnu_arr[cur_depth][cur_btn]
	local swap_num = (cur_btn + dir) % (#mnu_arr[cur_depth] + 1)
	local swap_btn = mnu_arr[cur_depth][swap_num]
	
	mnu_arr[cur_depth][cur_btn] = swap_btn
	mnu_arr[cur_depth][swap_num] = btn
	
	
	cur_btn = swap_num	
	update_btn_settings()

end



-- Reload the menu file (or a new one) and update all settings
local function refresh_menu(new)
	

	load_menu(new)
	
	cur_depth = 0
	cur_btn = -2
	
	update_mnu_menu()
	update_glbl_settings()
	update_mnu_settings()
	update_btn_settings()
	
end



-- Center/justify/etc any specific elms that need it
local function align_elms()
	
	
	GUI.font( GUI.elms.lbl_f_font.font )
	
	local str = GUI.elms.lbl_f_font.retval
	local str_w, str_h = gfx.measurestr(str)
	
	GUI.elms.lbl_f_font.x = GUI.elms.txt_font_A.x + (GUI.elms.txt_font_A.w - str_w) / 2
	
	str = GUI.elms.lbl_f_size.retval
	str_w, str_h = gfx.measurestr(str)
	
	GUI.elms.lbl_f_size.x = GUI.elms.txt_size_A.x + (GUI.elms.txt_size_A.w - str_w) / 2	
	
	
end



local function check_bind()
	
	local char = string.char(GUI.char)
	
	bound_key, bound_act, bound_mnu = nil, nil, nil
	
	local num = #mnu_arr[cur_depth] + 1
	
	for k, v in pairs(mnu_arr[-1].key_binds[num]) do
		
		if char == v then
			
			--bound_key = GUI.char
			--bound_act = mnu_arr[cur_depth][k >= 0 and (k - 1) or k].act

			--GUI.Msg("detected: "..tostring(k))

			k = k >= 0 and (k - 1) or k

			bound_mnu = {k, reaper.time_precise(), mnu_arr[cur_depth][k] and mnu_arr[cur_depth][k].act or ""}

			--GUI.Msg("detect key bind: "..char.." -> act = "..table.concat(bound_mnu, ", "))

			redraw_menu = true
			GUI.redraw_z[GUI.elms.frm_radial.z] = true 
			
			return true
			
		end		
		
	end
	
	
	-- Return true if we found a keybind to use
	--return bound_key
	
end



local function check_key()

	_=dm and Msg(">check_key")
	
	-- For debugging
	local mod_str = ""
	
	
	-- For visually showing a button "click" with key binds
	if bound_mnu and (reaper.time_precise() - bound_mnu[2] > 0.05) then
		
		run_act(bound_mnu[3])
		
		bound_mnu = nil
		GUI.redraw_z[GUI.elms.frm_radial.z] = true
	end
	
	
	if mnu_arr[-1].key_mode ~= 3 then
		
		_=dm and Msg("\tChecking the shortcut key")
		
		if startup then
			
			_=dm and Msg("\tStartup, looking for key...")
			
			key_down = GUI.char
			
			if key_down ~= 0 then
						
				--[[
					
					(I have no idea if the same values apply on a Mac)
					
					Need to narrow the range to the normal keyboard ASCII values:
					
					ASCII 'a' = 97
					ASCII 'z' = 122
					
					1-26		Ctrl+			char + 96
					65-90		Shift/Caps+		char + 32
					257-282		Ctrl+Alt+		char - 160
					321-346		Alt+			char - 224

					gfx.mouse_cap values:
					
					4	Ctrl
					8	Shift
					16	Alt
					32	Win
					
					For Ctrl+4 or Ctrl+}... I have no fucking clue short of individually
					checking every possibility.

				]]--	
				
				local cap = GUI.mouse.cap
				local adj = 0
				if cap & 4 == 4 then			
					if not (cap & 16 == 16) then
						mod_str = "Ctrl"
						adj = adj + 96			-- Ctrl
					else				
						mod_str = "Ctrl Alt"
						adj = adj - 160			-- Ctrl+Alt
					end
					--	No change				-- Ctrl+Shift
					
				elseif (cap & 16 == 16) then
					mod_str = "Alt"
					adj = adj - 224				-- Alt
					
					--  No change				-- Alt+Shift
					
				elseif cap & 8 == 8 or (key_down >= 65 and key_down <= 90) then		
					mod_str = "Shift/Caps"
					adj = adj + 32				-- Shift / Caps
				end
		
				hold_char = math.floor(key_down + adj)
				_=dm and Msg("\tDetected: "..mod_str.." "..hold_char)
				
				startup = false
				GUI.elms.lbl_startup.z = 20
				GUI.redraw_z[GUI.elms.frm_radial.z] = true
				
			elseif not up_time then
				up_time = reaper.time_precise()
			end
			
		else
			
			-- Running logic
		
			key_down = gfx.getchar(hold_char)
			if key_down ~= 0 then
				_=dm and Msg("\tKey "..tostring(hold_char).." is still down (ret:"..tostring(key_down)..")")
			else
				_=dm and Msg("\tKey "..tostring(hold_char).." is no longer down")
			end

			if GUI.char ~= 0 and GUI.char ~= hold_char and mnu_arr[-1].key_binds.enabled then check_bind() end

			-- Alternate logic that works with ~ or foreign keys, but gets pretty glitchy
		--[[
			table.insert(key_down_arr, math.floor(GUI.char))
			if #key_down_arr > 5 then table.remove(key_down_arr, 1) end
			
			key_down = 0			
			for i = 1, #key_down_arr do
				if key_down_arr[i] == hold_char then
					key_down = 1
					break
				end
			end
		]]--
		end	
		
	-- We're in "keep the window open" mode
	elseif GUI.char > 0 then 

		-- If any key was pressed, close the window

		_=dm and Msg("\tKey mode = 3 and a key was pressed; closing the window.")		

		
		if mnu_arr[-1].key_binds.enabled then GUI.quit = not check_bind() end

	end

	_=dm and Msg("<check_key")

end




local function get_mouse_mnu(swipe)
	
	local mouse_mnu
	local mnu_adj = not swipe and mnu_adj or  2 / (#mnu_arr[swipe] + 1) 
	
	-- Figure out where the mouse is
	-- On the center button?
	if not swipe and mouse_r < mnu_arr[-1].ra and mnu_arr[cur_depth][-1] then
		mouse_mnu = -1
	
	-- Outside the ring, either way?
	-- Ignore '>' cases if we're swiping, since that will frequently be outside the ring
	elseif (not swipe and mouse_r > mnu_arr[-1].rd + 80) or mouse_r < 32 then
		mouse_mnu = -2
	
	-- Must be over a button then
	else
	
		if mouse_angle < 0 then mouse_angle = mouse_angle + 2 end
		mouse_mnu = math.floor(mouse_angle / mnu_adj + 0.5)
		if mouse_mnu == (#mnu_arr[swipe or cur_depth] + 1) then mouse_mnu = 0 end		
	
	end	
	
	return mouse_mnu
	
end



local function check_swipe()
	
	_=dm and Msg(">check_swipe")
	
	local x, y, lx, ly = GUI.mouse.x, GUI.mouse.y, GUI.mouse.lx, GUI.mouse.ly
	
	-- Converting these from human-readable to what we want here
	local accel = 100 - mnu_arr[-1].swipe.accel
	local stop = 0.001 * mnu_arr[-1].swipe.stop	
	
	
	--local diff = sqrt( (x - lx)^2 + (y - ly)^2 )
	local diff = mouse_r - mouse_lr
	
	-- Moving fast enough to start tracking a swipe?
	if diff > accel then track_swipe = true end

	if track_swipe then
		
		stopped = (diff <= mnu_arr[-1].swipe.decel) and (stopped or reaper.time_precise()) or nil

		local mnu = mnu_arr[-1].swipe.mode == 2 and	( 	   tonumber(mnu_arr[-1].swipe.menu) 
													or 	check_alias(mnu_arr[-1].swipe.menu) )
												or	cur_depth


		
		local btn = get_mouse_mnu(mnu)
		
		if stopped and swipe_retrigger == 0 and mnu >= 0 and (reaper.time_precise() - stopped > stop) then
			
			_=dm and Msg("\tpicked up a gesture:\tmenu "..tostring(mnu)..", button "..tostring(btn))
			
			--[[
				act =
						mode 1:		current menu --> get_mouse_mnu()
						mode 2:		swipe menu --> get_mouse_mnu(mnu)
				
				
				
			]]--
			
			local act = mnu_arr[mnu][btn].act
			
							
			if string.sub(tostring(act), 1, 4) == "menu" then

				_=dm and Msg("\topening "..tostring(act))

				run_act(act)
					
				local x, y = reaper.GetMousePosition()
				x, y = x - (frm_w / 2) - 8, y - (frm_w / 2) - 32
				
				gfx.quit()
				gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
				
			elseif mnu_arr[-1].swipe.actions then
			
				_=dm and Msg("\trunning action: ")
			
				run_act(act)	
			
			end
			
			GUI.redraw_z[1] = true
			
			swipe_retrigger = 2
			
			stopped = nil
			track_swipe = false
	
		end
	
	end
	
	_=dm and Msg("<check_swipe")
	
end



--[[	Update all of our mouse-related stuff
	
	- Angle, radius, current menu button
	- See if we need to check for swipes
	- See if we need to run the hover timer, or if the hover timer has run out	
	
]]--
local function check_mouse()
	
	_=dm and Msg(">check_mouse")
	
	-- Get the mouse position
	mouse_lr = mouse_r
	mouse_angle, mouse_r = GUI.cart2polar(GUI.mouse.x, GUI.mouse.y, ox, oy)
	
	local prev_mnu = mouse_mnu
	mouse_mnu = get_mouse_mnu()

	
	if not setup and mnu_arr[-1].swipe.enabled and not GUI.mouse.down and not GUI.mouse.r_down and mouse_r > mnu_arr[-1].re then check_swipe() end
	
	

	-- If we're over a new option, reset the hover timer
	if prev_mnu ~= mouse_mnu then
		
		_=dm and Msg("\tmouse is now over button "..tostring(mouse_mnu))
		
		if not setup and mnu_arr[-1].hvr_click  then
			_=dm and Msg("hovering")
			hvr_time = reaper.time_precise()
		end
		
		opt_clicked = false
		
		GUI.redraw_z[GUI.elms.frm_radial.z] = true 
	
	-- If the hover time has run out, click the current option
	elseif not setup and hvr_time and mnu_arr[-1].hvr_click and (reaper.time_precise() - hvr_time) > (mnu_arr[-1].hvr_time / 1000) then
		if mnu_arr[cur_depth][mouse_mnu] then
			_=dm and Msg("hovered long enough, clicking")
			run_act(mnu_arr[cur_depth][mouse_mnu].act)
			GUI.redraw_z[GUI.elms.frm_radial.z] = true
			hvr_time = nil
		end
	end
	
	_=dm and Msg("<check_mouse")
	
end



local function check_repeat()
	
	_=dm and Msg(">check_repeat")
	
	local t = reaper.time_precise()

	_=dm and Msg("\tt = "..GUI.round(t, 3).."\t[3] = "..GUI.round(repeat_act[3], 3))
	_=dm and Msg("\tdiff = "..GUI.round( t - repeat_act[3], 3).."\t[1] = "..GUI.round(repeat_act[1], 3))

	if	GUI.mouse.cap & repeat_act[4] == repeat_act[4] 	then	
		if( t - repeat_act[3] > repeat_act[1] ) then
		
			_=dm and Msg("\trepeating action "..tostring(repeat_act[2]) )
		
			run_act(repeat_act[2])	
			repeat_act[3] = t
		
		end
	else
		repeat_act = false
	end
		
	_=dm and Msg("<check_repeat")
end




-- Sees if a font named 'font' exists on this system
-- Returns true/false
local function validate_font(font)
	
	if type(font) ~= "string" then return false end
	
	gfx.setfont(1, font, 10)
	
	local __, ret_font = gfx.getfont()
	
	return font == ret_font	
	
end



-- Erase the key bindings for the currently-selected menu size
local function clear_binds()

	local num = GUI.Val("mnu_keys") + 3
	
	for i = -1, num do
		if i ~= 0 then
			mnu_arr[-1].key_binds[num][i] = nil
		end
	end		
	
	update_key_elms()
	update_glbl_settings()

end


-- Copy the current menu size's bindings to all higher/lower menus
local function prop_binds(dir)
	
	local num = GUI.Val("mnu_keys") + 3
	local a, b = num + dir, (dir > 0 and 16 or 4)
	
	--if a > b then a, b = b, a end
	
	for i = a, b, dir do
			
		for j = 1, i do
			
			mnu_arr[-1].key_binds[i][j] = mnu_arr[-1].key_binds[num][j] or ""
			
		end
		
		mnu_arr[-1].key_binds[i][-1] = mnu_arr[-1].key_binds[num][-1] or ""
		
	end	
	

end




--[[	GUI Elements and Parameters

	Tabframe	z	x y w h 	caption		tabs	pad
	Frame		z	x y w h		[shadow		fill	color	round]
	Label		z	x y			caption		shadow	font
	Button		z	x y w h 	caption		func	...
	Radio		z	x y w h 	caption 	opts	pad
	Checklist	z	x y 		caption 	opts	dir		pad
	Knob		z	x y w		caption 	min 	max		steps	default		ticks
	Slider		z	x y w		caption 	min 	max 	steps 	default		dir		ticks
	Range		z	x y w		caption		min		max		steps 	default_a 	default_b
	Textbox		z	x y w h		caption		pad
	Menubox		z	x y w h 	caption		opts	pad

	Tabframe z_sets are defined like so:

	GUI.elms.tabs_blah:update_sets(
		{
				   __ z levels shown on that tab
		  __ tab  /
		 /		  |
		 |		  v
		 v     
		[1] = {2, 3, 4}, 
		[2] = {5, 6, 7}, 
		[3] = {8, 9, 10},
		}
	)
	
]]--


-- Values to reference elms off of

local line_x = 432

-- Bottom of tabs
local line_y0 = 22

-- Menu tab's separator
local line_y1 = 192

-- Global tab's separators
local line_y2 = 128
local line_y4 = line_y2 + 112
local line_y5 = line_y4 + 132

-- Swipe tab's separator
local line_y3 = 54

local line_y_tt = 608

local ref1 = {x = 490, y = line_y0 + 40, w = 270, h = 68}	-- Menu color settings
local ref2 = {x = 490, y = line_y1 + 66, w = 270, h = 68}	-- Button color settings
local ref3 = {x = 490, y = line_y0 + 16, w = 270, h = 68}	-- Global color settings

local ref4 = {x = 808, y = line_y0 + 16, w = 192, h = 20, adj = 26}	-- Options buttons

local ref5 = {x = 512, y = line_y4 + 48}					-- Font settings

local ref6 = {x = 458, y = line_y0 + 500}					-- Misc. opts

GUI.elms = not setup and {

	frm_radial = GUI.Frame:new(			2,	0, 0, 400, 400, false, true, "elm_bg", 0),
	lbl_version = GUI.Label:new(		1,	6, 0, "Script version: "..script_version, 0, 10),
	lbl_startup = GUI.Label:new(		20,	6, 4, "Detecting action key...", 0, 10),
	
}
or
{



	---- General elements z = 21+
	
	tabs = GUI.Tabframe:new(			24,	432, 0, 56, 22, "", "Menu,Context,Swiping,Global,Options,Help", 8),	
	
	frm_radial = GUI.Frame:new(			23,	0, 0, 432, line_y_tt, false, true, "elm_bg", 0),
	
	frm_line_x = GUI.Frame:new(			22,	line_x, 0, 4, line_y_tt, true, true),
	
	frm_line_tt = GUI.Frame:new(		21, 0, line_y_tt, 1024, 4, true, true),
	



	---- Hidden layers z = 20 ----
	
	lbl_tooltip = GUI.Label:new(		20, 386, 0, "tooltip", 0, 4),
	frm_rad_overlay = GUI.Frame:new(	20, 0, 0, 432, line_y_tt, false, true, "shadow", 0),

	frm_swipe_menu = GUI.Frame:new(		20, 0, 0, 432, line_y_tt, false, true, "magenta", 0),
	lbl_swipe_menu = GUI.Label:new(		20, 0, 0, "This menu is assigned to Swipe actions", 0, 2),

	---- Menus tab  z = 2,3,4 ----

	-- Menu settings
	mnu_menu = GUI.Menubox:new(			4,	704, line_y0 + 8, 64, 20, "Current menu:", "0,1,2,3,4", 4),
	txt_alias = GUI.Textbox:new(		4,	840, line_y0 + 8, 96, 20, "Alias:", 4),
	btn_add_menu = GUI.Button:new(		4,	464, line_y0 + 8, 48, 20, "Add", add_menu),
	btn_del_menu = GUI.Button:new(		4,	520, line_y0 + 8, 48, 20, "Delete", del_menu),

	lbl_num_m_btns = GUI.Label:new(		4,	ref1.x - 32, ref1.y + 96, "Number of buttons:", 1, 3),
	num_m_btns_rem = GUI.Button:new(	4,	ref1.x + 80, ref1.y + 94, 24, 20, "-", remove_btn),
	num_m_btns_add = GUI.Button:new(	4,	ref1.x + 108, ref1.y + 94, 24, 20, "+", add_btn),

	chk_center = GUI.Checklist:new(		4,	ref1.x + 176, ref1.y + 95, 0, 0, "", "Center button", "v", 0),

	btn_shortcut = GUI.Button:new(		4,	840, ref1.y + 96, 144, 20, "Create shortcut script", mnu_shortcut),

	-- Menu colors
	frm_ref1 = dm and GUI.Frame:new(	4,	ref1.x,	ref1.y, ref1.w, ref1.h, false, false, "magenta", 0),

	lbl_col_m_btn = GUI.Label:new(		4,  ref1.x, 		ref1.y + 2, 	"Button color:", 1, 3),
	frm_col_m_btn = GUI.Frame:new(		4,	ref1.x + 82, 	ref1.y, 		20, 20, true, true, "elm_frame", 0),
	lbl_col_m_hvr = GUI.Label:new(		4,	ref1.x - 26, 	ref1.y + 24, 	"Mouseover color:", 1, 3),
	frm_col_m_hvr = GUI.Frame:new(		4,	ref1.x + 82, 	ref1.y + 22, 	20, 20, true, true, "elm_frame", 0),
	lbl_col_m_tog = GUI.Label:new(		4,	ref1.x + 168, 	ref1.y + 2, 	"Toggled color:", 1, 3),
	frm_col_m_tog = GUI.Frame:new(		4,	ref1.x + 250, 	ref1.y, 		20, 20, true, true, "elm_frame", 0),	
	lbl_col_m_bg = GUI.Label:new(		4,	ref1.x + 144, 	ref1.y + 24, 	"Background color:", 1, 3),
	frm_col_m_bg = GUI.Frame:new(		4,	ref1.x + 250, 	ref1.y + 22, 	20, 20, true, true, "elm_frame", 0),

	btn_use_global = GUI.Button:new(	4,	ref1.x + 78,	ref1.y + 48, 	128, 20, "Use global colors", use_global_colors),
	

	-- Button settings
	frm_line_y1 = GUI.Frame:new(		2,	436, line_y1, 600, 4, true, true),
	frm_no_btn = GUI.Frame:new(			3,	436, line_y1, 600, line_y_tt - line_y1, false, true, "faded", 0),
	
	lbl_cur_btn = GUI.Label:new(		4,	448, line_y1 + 8, "Current button:", 1, 2),

	--lbl_btn_move = GUI.Label:new(		4,	632, line_y1 + 12, "Move:", 0, 3),
	btn_btn_left = GUI.Button:new(		4,	632, line_y1 + 10, 32, 20, "↓", move_btn, -1),
	btn_btn_del = GUI.Button:new(		4,	672, line_y1 + 10, 64, 20, "Delete", remove_btn, true),
	btn_btn_right = GUI.Button:new(		4,	744, line_y1 + 10, 32, 20, "↑", move_btn, 1),
	
	txt_btn_lbl = GUI.Textbox:new(		4,	496, line_y1 + 40, 288, 20, "Label:", 4),	
	
	frm_ref2 = dm and GUI.Frame:new(	4,	ref2.x,	ref2.y, ref2.w, ref2.h, false, false, "magenta", 0),
	
	lbl_col_b_btn = GUI.Label:new(		4,	ref2.x, 			ref2.y + 2, 	"Button color:", 1, 3),
	frm_col_b_btn = GUI.Frame:new(		4,	ref2.x + 82, 		ref2.y, 		20, 20, true, true, "elm_frame", 0),
	lbl_col_b_hvr = GUI.Label:new(		4,	ref2.x - 26, 		ref2.y + 24, 	"Mouseover color:", 1, 3),
	frm_col_b_hvr = GUI.Frame:new(		4,	ref2.x + 82, 		ref2.y + 22, 	20, 20, true, true, "elm_frame", 0),		
	lbl_col_b_tog = GUI.Label:new(		4,	ref2.x + 168, 		ref2.y + 2, 	"Toggled color:", 1, 3),
	frm_col_b_tog = GUI.Frame:new(		4,	ref2.x + 250, 		ref2.y, 		20, 20, true, true, "elm_frame", 0),		
	
	btn_use_mnu = GUI.Button:new(		4,	ref2.x + 78, 		ref2.y + 48, 	128, 20, "Use menu colors", use_menu_colors),

	lbl_btn_acts = GUI.Label:new(		4,	448, line_y1 + 134, "Actions:", 1, 2),

	txt_btn_act = GUI.Textbox:new(		4,	496, line_y1 + 160, 440, 20, "Left:", 4),
	btn_paste = GUI.Button:new(			4,	944, line_y1 + 160, 56, 20, "Paste", paste_act, "act"),	

	txt_btn_r_act = GUI.Textbox:new(	4,	496, line_y1 + 186, 440, 20, "Right:", 4),
	btn_r_paste = GUI.Button:new(		4,	944, line_y1 + 186, 56, 20, "Paste", paste_act, "r_act"),	

	txt_btn_m_act = GUI.Textbox:new(	4,	496, line_y1 + 212, 440, 20, "Middle:", 4),
	btn_m_paste = GUI.Button:new(		4,	944, line_y1 + 212, 56, 20, "Paste", paste_act, "m_act"),		
	
	
	
	---- Context tab z = 5,6,7 ----
	
		-- Populated at run-time --





	---- Swipe tab z = 17,18,19 ----
	
	
	chk_swipe = GUI.Checklist:new(		18, 444, line_y0 + 6, 0, 0, "", "Swiping enabled", "v", 0),


	frm_line_swipe = GUI.Frame:new(		17,	436, line_y3, 600, 4, true, true),
	frm_no_swipe = GUI.Frame:new(		17, 436, line_y3 + 4, 600, line_y_tt - line_y0 - 34, false, true, "faded", 0),
	
	sldr_accel = GUI.Slider:new(		18,	452, line_y3 + 40, 96, "Start sensitivity", 0, 100, 100, 65, "h"),
	sldr_decel = GUI.Slider:new(		18,	580, line_y3 + 40, 96, "Stop sensitivity", 0, 100, 100, 10, "h"),
	sldr_stop = GUI.Slider:new(			18, 708, line_y3 + 40, 96, "Stop time", 5, 100, 19, 3, "h"),
	sldr_re = GUI.Slider:new(			18,	836, line_y3 + 40, 96, "Swiping threshold", 32, 192, 160, 160, "h"),

	frm_r1 = GUI.Frame:new(				20,	828, line_y3, 112, 80, false, false, nil, 0),

	opt_swipe_mode = GUI.Radio:new(		19,	464, line_y3 + 96, 192, 80, "Swiping uses actions from:", "The active menu, ", 4),
	txt_swipe_menu = GUI.Textbox:new(	18,	542, line_y3 + 150, 96, 20, "Menu:", 4),
	
	chk_swipe_acts = GUI.Checklist:new(	18, 464, line_y3 + 192, nil, nil, "", "Swiping can trigger actions", "v", 4),

	
	

	---- Global tab z = 8,9,10 ----
	
	frm_ref3 = dm and GUI.Frame:new(	9,	ref3.x,	ref3.y, ref3.w, ref3.h, false, false, "magenta", 0),
	
	lbl_col_g_btn = GUI.Label:new(		9,  ref3.x, 		ref3.y + 2, 	"Button color:", 1, 3),
	frm_col_g_btn = GUI.Frame:new(		9,	ref3.x + 82, 	ref3.y, 		20, 20, true, true, "elm_frame", 0),
	lbl_col_g_hvr = GUI.Label:new(		9,	ref3.x - 26, 	ref3.y + 24, 	"Mouseover color:", 1, 3),
	frm_col_g_hvr = GUI.Frame:new(		9,	ref3.x + 82, 	ref3.y + 22, 	20, 20, true, true, "elm_frame", 0),
	lbl_col_g_tog = GUI.Label:new(		9,	ref3.x + 168, 	ref3.y + 2, 	"Toggled color:", 1, 3),
	frm_col_g_tog = GUI.Frame:new(		9,	ref3.x + 250, 	ref3.y, 20, 	20, true, true, "elm_frame", 0),
	lbl_col_g_bg = GUI.Label:new(		9,	ref3.x + 144, 	ref3.y + 24, 	"Background color:", 1, 3),
	frm_col_g_bg = GUI.Frame:new(		9,	ref3.x + 250, 	ref3.y + 22, 	20, 20, true, true, "elm_frame", 0),
	
	btn_def_glbl = GUI.Button:new(		9,	ref3.x + 78, ref3.y + 48, 128, 20, "Reset global colors", reset_glbl_colors),

	chk_preview = GUI.Checklist:new(	9,	816, line_y0 + 17, nil, nil, "", "Show submenu preview", "v", 4),

	sldr_num_btns = GUI.Slider:new(		9,	848, line_y0 + 52, 96, "", 4, 16, 12, 4, "h"),
	

	-- Radius sliders --
	frm_line_y2 = GUI.Frame:new(		9,	436, line_y2, 600, 4, true, true),
	
	
	lbl_radii = GUI.Label:new(			9,	448, line_y2 + 8, "Radii and target areas:", 1, 2),

	frm_r2 = GUI.Frame:new(				20,	432, line_y2, 600, 112, false, false, "wnd_bg", 0),

	sldr_ra = GUI.Slider:new(			9,	464, line_y2 + 64, 96, "Center button", 16, 96, 80, 32, "h"),
	sldr_rc = GUI.Slider:new(			9,	592, line_y2 + 64, 96, "Inside of ring", 64, 160, 96, 52, "h"),
	sldr_rd = GUI.Slider:new(			9,	720, line_y2 + 64, 96, "Outside of ring", 128, 192, 64, 64, "h"),

	sldr_rb = GUI.Slider:new(			20,	464, line_y2 + 64, 96, "Nothing yet", 20, 128, 108, 40, "h"),


	-- Font settings --
	frm_line_y4 = GUI.Frame:new(		8, 436, line_y4, 600, 4, true, true),

	lbl_fonts = GUI.Label:new(			9,	448, line_y4 + 8, "Fonts:", 1, 2),

	lbl_f_font = GUI.Label:new(			9,	ref5.x, ref5.y - 20, "Font", 1, 3),
	lbl_f_size = GUI.Label:new(			9,	ref5.x + 130, ref5.y - 20, "Size", 1, 3),
	
	txt_font_A = GUI.Textbox:new(		9,	ref5.x, ref5.y, 200, 20, "Main:", 4),
	txt_font_B = GUI.Textbox:new(		9,	ref5.x, ref5.y + 26, 200, 20, "Menus:", 4),
	txt_font_C = GUI.Textbox:new(		9,	ref5.x, ref5.y + 52, 200, 20, "Preview:", 4),
	
	frm_val_fonts = GUI.Frame:new(		9,	ref5.x + 202, ref5.y, 14, 72),
	
	txt_size_A = GUI.Textbox:new(		9,	ref5.x + 216, ref5.y, 28, 20, "", 4),
	txt_size_B = GUI.Textbox:new(		9,	ref5.x + 216, ref5.y + 26, 28, 20, "", 4),
	txt_size_C = GUI.Textbox:new(		9,	ref5.x + 216, ref5.y + 52, 28, 20, "", 4),	
	
	chk_flags_A = GUI.Checklist:new(	9,	ref5.x + 246, ref5.y, nil, nil, "", "B,I,U", "h", 2),
	chk_flags_B = GUI.Checklist:new(	9,	ref5.x + 246, ref5.y + 26, nil, nil, "", " , , ", "h", 2),
	chk_flags_C = GUI.Checklist:new(	9,	ref5.x + 246, ref5.y + 52, nil, nil, "", " , , ", "h", 2),


	-- Key bind settings --
	frm_line_y5 = GUI.Frame:new(		8, 436, line_y5, 600, 4, true, true),

	lbl_keys = GUI.Label:new(			9,	448, line_y5 + 8, "Key binds:", 1, 2),
	


	chk_keys = GUI.Checklist:new(		9,	464, line_y5 + 40, nil, nil, "", "Key binds enabled", "v", 4),
	chk_hints = GUI.Checklist:new(		9,	464, line_y5 + 64, nil, nil, "", "Show key binding hints", "v", 4),	
	mnu_keys = GUI.Menubox:new(			9,	576, line_y5 + 96, 48, 20, "Number of buttons:", "4,5,6,7,8,9,10,11,12,13,14,15,16", 4),

	
	btn_keys_clear = GUI.Button:new(	9,	464, line_y5 + 130, 160, 20, "Clear binds for this size", clear_binds),
	
	lbl_keys_prop = GUI.Label:new(		9,	464, line_y5 + 160, "Propagate binds:", 1, 3),
	btn_keys_pr_dn = GUI.Button:new(	9,	560, line_y5 + 158, 32, 20, "↓", prop_binds, -1),
	btn_keys_pr_up = GUI.Button:new(	9,	596, line_y5 + 158, 32, 20, "↑", prop_binds, 1),

	frm_keys_bg = GUI.Frame:new(		9,	0, 0, 0, 0, false, true, "red", 0),
	-- array of textboxes created at runtime




	---- Options tab z = 11,12,13

	--mnu_g_shape = GUI.Menubox:new(		12,	500, line_y0 + 96, 64, 20, "Button shape:", "Circle,Square,Arc", 4),	
	
	opt_win_pos = GUI.Radio:new(		12,	448, line_y0 + 16, 336, 74, "Open the Radial Menu window:", win_pos_str, 4),
	opt_mouse_mode = GUI.Radio:new(		12, 448, line_y0 + 122, 336, 96, "When running an action:", mouse_mode_str, 4),	
	opt_key_mode = GUI.Radio:new(		12,	448, line_y0 + 254, 336, 96, "When the shortcut key is released:", key_mode_str, 4),
	

	
	chk_misc_opts = GUI.Checklist:new(	12, ref6.x, ref6.y, 336, 108, "", "Hover over an option to 'click' it →", "v", 4),
	txt_hvr_time = GUI.Textbox:new(		12, ref6.x + 270, ref6.y, 48, 20, "(ms):", 4),
	txt_close_time = GUI.Textbox:new(	12, ref6.x + 270, ref6.y + 48, 48, 20, "If no key is detected, close the window after (ms):", 4),
	
	btn_clear_mnu = GUI.Button:new(		12,	ref4.x, ref4.y, ref4.w, ref4.h, "Clear settings", clear_menu),
	btn_load_txt = GUI.Button:new(		12,	ref4.x, ref4.y + 2*ref4.adj, ref4.w, ref4.h, "Import settings...", refresh_menu, true),
	btn_save_txt = GUI.Button:new(		12, ref4.x, ref4.y + 3*ref4.adj, ref4.w, ref4.h, "Export settings...", save_menu, true),	
	btn_open_txt = GUI.Button:new(		12,	ref4.x, ref4.y + 5*ref4.adj, ref4.w, ref4.h, "Open settings in text editor", open_txt),
	btn_refresh_txt = GUI.Button:new(	12,	ref4.x, ref4.y + 6*ref4.adj, ref4.w, ref4.h, "Refresh from settings file", refresh_menu),

	--btn_save_txt = GUI.Button:new(		12,	500, line_y0 + 270, 192, 22, "Export user settings...", save_menu, true),
	btn_spit_table = GUI.Button:new(	12,	ref4.x, ref4.y + 8*ref4.adj, ref4.w, ref4.h, "Show saved data (for debugging)", spit_table),
	
	
	
	
	---- Help tab z = 14,15,16 ----
	
	lbl_ver = GUI.Label:new(			15, 448, line_y0 + 8, "Script version: "..script_version, 1, 3),
	mnu_help = GUI.Menubox:new(			15, 648, line_y0 + 6, 160, 20, "", "", 4),
	btn_thread = GUI.Button:new(		15,	832, line_y0 + 5, 96, 20, "Forum thread", GUI.open_file, thread_URL),
	btn_donate = GUI.Button:new(		15,	936, line_y0 + 5, 72, 20, "Donate", GUI.open_file, donate_URL),	
	
	line_help = GUI.Frame:new(			15, 436, line_y0 + 32, 600, 4, true, true),
	frm_help = GUI.TxtFrame:new(		16, 436, line_y0 + 36, 588, line_y_tt - (line_y0 + 36), "help stuff", 4, "txt", 8, false, false, "wnd_bg", 0),
	

}







GUI.elms.frm_radial.state = false
GUI.elms.frm_radial.font = 6







-- Draw an arc-shaped section of a ring
local function draw_ring_section(angle_c, width, r_in, r_out, ox, oy, pad, fill, color)
	
	local angle_a, angle_b = (angle_c - 0.5 + pad) * width, (angle_c + 0.5 - pad) * width
	
	local ax1, ay1 = GUI.polar2cart(angle_a, r_in, ox, oy)
	local ax2, ay2 = GUI.polar2cart(angle_a, r_out - 1, ox, oy)
	local bx1, by1 = GUI.polar2cart(angle_b, r_in, ox, oy)
	local bx2, by2 = GUI.polar2cart(angle_b, r_out - 1, ox, oy)	

	if color then GUI.color(color) end
	
	-- gfx.arc doesn't use the right reference angle,
	-- so we have to add 0.5 rads to correct it
	angle_a = (angle_a + 0.5) * pi
	angle_b = (angle_b + 0.5) * pi
	
	gfx.arc(ox, oy, r_in, angle_a, angle_b, 1)
	gfx.arc(ox, oy, r_out, angle_a, angle_b, 1)	
	
	-- gfx.arc won't completely fill the space, so we need
	-- to trick it by drawing arcs less than a pixel apart
	--
	-- 0.4 is the highest you can go before the issue is
	-- visible, from what I can tell.
	if fill then
		for j = r_in, r_out, 0.3 do
			gfx.arc(ox, oy, j, angle_a, angle_b, 1)
		end
	else
		gfx.line(ax1, ay1, ax2, ay2, 1)
		gfx.line(bx1, by1, bx2, by2, 1)
	end
end



-- All of the menu drawing happens here
function GUI.elms.frm_radial:draw_base_menu()
	
	_=dm and Msg(">draw_base_menu")
	
	local ra, rb, rc, rd = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd
	
	-- In case I ever restore the menu rotation
	local k = 0

	local color

	-- Update the button width while we're here
	mnu_adj = 2 / (#mnu_arr[cur_depth] + 1)	

	gfx.dest = 50
	gfx.setimgdim(50, -1, -1)
	gfx.setimgdim(50, frm_w, (setup and self.h or gfx.h) )
	
	_=dm and Msg("\tfrm_w = "..tostring(frm_w))
	
	_=dm and Msg("\tdrawing background")
	
	GUI.color( get_color("col_bg", -2) )
	gfx.rect(self.x, self.y, self.w, (setup and self.h or gfx.h), true)	
	
	for i = -1, #mnu_arr[cur_depth] do
		
		_=dm and Msg("\tdrawing button "..tostring(i))
		
		color = get_color("col_main", i)
		_=dm and Msg("\t\t"..table.unpack(color))
		
		if i ~= -1 then
			draw_ring_section(i + k, mnu_adj, rc, rd, ox, oy, 0, true, color)
		elseif mnu_arr[cur_depth][-1] then
			GUI.color(color)
			gfx.circle(ox, oy, ra - 4, true, 1)
		end

	end	
	
	gfx.dest = -1
	
	_=dm and Msg("<draw_base_menu")
	
end

function GUI.elms.frm_radial:draw()
	
	local ra, rb, rc, rd = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd
	local colors = {}


	_=dm and Msg(">frm_radial:draw")

	gfx.x, gfx.y = 0, 0
	gfx.blit(50, 1, 0)

	-- For rotating the menu, i.e. putting button 0 under the mouse when the menu opens
	-- Currently broken, so we're not using it.
	local k = 0
	
	local redraw

	-- Draw the menu options
	for i = -1, #mnu_arr[cur_depth] do
--[[
		local i = (mouse_mnu and i >= 0) 
				and (i + mouse_mnu + 1) % (#mnu_arr[cur_depth] + 1) 
				or i
]]--
		if mnu_arr[cur_depth][i] then

			local opt = mnu_arr[cur_depth][i]
			
			local color = "col_main"
			local r_adj = 0
			
			if i == mouse_mnu then
			-- For rotating the menu
			--if (((i + k) % (#mnu_arr[cur_depth] + 1)) == self.mouse_mnu) then

				r_adj = 4
				color = self.state and "col_bg" or "col_hvr"
			
			elseif bound_mnu and i == bound_mnu[1] then

				color = "col_bg"
			
			end
			
			if string.sub(opt.act, 1, 4) ~= "menu" and opt.act ~= "" then

				local act = opt.act
				if string.sub(act, 1, 1) == "_" then
					act = reaper.NamedCommandLookup(act)
				end
				act = tonumber(act)

				local state = ((act and act > 0) and reaper.GetToggleCommandState(act)) or nil
				
				-- Use a blend of hover/bg and the toggle color, when necessary
				if state == 1 then
					
					color = ((color == "col_hvr") and "hvr_tog")
						or	((color == "col_bg") and "bg_tog")
						or	"col_tog"
						
				end

			end 
			
			redraw = color ~= "col_main"
			
			color = get_color(color, i)


			-- We only need to redraw if the button isn't using its base color
			if redraw then

				_=dm and Msg("\t\tredrawing "..tostring(i))
				if i ~= -1 then
					draw_ring_section(i + k, mnu_adj, rc - r_adj, rd + r_adj, ox, oy, 0, true, color)
				else
					GUI.color(color)
					gfx.circle(ox, oy, ra - 4 + r_adj, true, 1)
				end
				
			end
			
			
			-- Draw an extra segment on the outside of the current button
			if i == cur_btn then
				if i ~= -1 then
					draw_ring_section(i + k, mnu_adj, rd + 6, rd + 14, ox, oy, 0, true, get_color("col_hvr", -2))
				else
					GUI.color(get_color("col_hvr", -1))
					for j = 0, 8, 0.4 do
						gfx.circle(ox, oy, ra + j, false, 1)
					end
				end			
			end			
			
			
			
			
			--GUI.font(self.font)
			colors[i] = colorsmart(color)

		end
	end
	


	-- If we're hovering over a button assigned to a menu, grab its children
	-- Getting this now because some of the main labels may need to be adjusted
	local mnu_children
	if 		mnu_arr[-1].preview
		and	mnu_arr[cur_depth][mouse_mnu] 
		and mnu_arr[cur_depth][mouse_mnu].act 
		then
		
		local act = mnu_arr[cur_depth][mouse_mnu].act
		if string.match(act, "^menu") then
			act = string.sub(act, 6)
			mnu_children = tonumber(act) or check_alias(act)

		end
	end




	
	-- Draw all of the labels
	
	_=dm and Msg("\tdrawing labels")
	GUI.font( mnu_arr[-1].fonts[1] )
	
	local str, str_w, str_h, cx, cy, w, h, j
	for i = -1, #mnu_arr[cur_depth] do
		
		if mnu_arr[cur_depth][i] then
			
			if string.sub(mnu_arr[cur_depth][i].act, 1, 4) == "menu" then
				GUI.font( mnu_arr[-1].fonts[2] )
			end
			
			str = string.gsub(mnu_arr[cur_depth][i].lbl, "[|;]", "\n")
			str_w, str_h = gfx.measurestr(str)
			
			cx, cy = table.unpack((i ~= -1) 
						and	{GUI.polar2cart((i + k) * mnu_adj, rc + (rd - rc) / 2, ox, oy)}
						or	{ox, oy}
						)
			GUI.color(colors[i] or "black")
			
			j = 0
			for s in string.gmatch(str.."\n", "([^\r\n]*)[\r\n]") do
				
				w, h = gfx.measurestr(s)
				gfx.x = cx - w / 2
				gfx.y = cy - str_h / 2 + j * h
				gfx.drawstr(s)
				j = j + 1
			end	
			
			GUI.font( mnu_arr[-1].fonts[1] )
			
		end
	end
	


	-- Draw the preview labels, if necessary

	if mnu_children and mnu_arr[mnu_children] then
		
		_=dm and Msg("\tmnu_children = "..tostring(mnu_children))	
		
		local adj = 2 / (#mnu_arr[mnu_children] + 1)
		local r = ra + (rc - ra) / 2
		
		GUI.font( mnu_arr[-1].fonts[3] )
		--GUI.color(colorsmart(get_color(	(mnu_arr[mnu_children][-1] and "col_main" or "col_bg"), -2)))
		GUI.color(colorsmart(get_color(	(mnu_arr[cur_depth][-1] and "col_main" or "col_bg"), -2)))
		
		local str, str_w, str_h, cx, cy, j, w, h
		
		for i = -1, #mnu_arr[mnu_children] do
			
			if i == 0 then GUI.color(colorsmart(get_color("col_bg", -2))) end
			
			if mnu_arr[mnu_children][i] then
				str = string.gsub(mnu_arr[mnu_children][i].lbl, "|", "\n")
				str_w, str_h = gfx.measurestr(str)
				
				cx, cy = table.unpack((i ~= -1) 
							and	{GUI.polar2cart((i + k) * adj, r, ox, oy)}
							or	{ox, oy + (mnu_arr[cur_depth][-1] and gfx.texth or 0)}
							)
				j = 0
				for s in string.gmatch(str.."\n", "([^\r\n]*)[\r\n]") do
				
					w, h = gfx.measurestr(s)
					gfx.x = cx - w / 2
					gfx.y = cy - str_h / 2 + j * h
					gfx.drawstr(s)
					j = j + 1
				end	
			end
		end
	end



	-- Draw key binding hints if necessary
	if mnu_arr[-1].key_binds.enabled and mnu_arr[-1].key_binds.hints then
				
		GUI.font( 4 )
		local col = colorsmart( get_color( "col_bg", -2 ) )
		GUI.color( col )
		
		local str_w, str_h
		local cx, cy
		
		for i = -1, #mnu_arr[cur_depth] do
			
			--local j = (i >= 0) and (i + 1) or i
				
			local hint = (mnu_arr[-1].key_binds[#mnu_arr[cur_depth] + 1] and mnu_arr[-1].key_binds[#mnu_arr[cur_depth] + 1][(i >= 0 and (i + 1) or i)]) or nil
			
			if hint and hint ~= "" and i ~= cur_btn then
				
				-- Get center coords
				
				cx, cy = table.unpack((i ~= -1) 
							and	{GUI.polar2cart(i * mnu_adj, rd + 12, ox, oy)}
							or	{ox, oy - (mnu_arr[cur_depth][-1] and (ra + 8) or 0)}
							)				
				
				-- Measure and position string
				
				str_w, str_h = gfx.measurestr(hint)
				gfx.x, gfx.y = cx - str_w / 2, cy - str_h / 2
				
				gfx.drawstr(hint)
				
				
			end		
		
		end
		
	end



	_=dm and Msg("<frm_radial:draw")

end


-- When running Radial Menu itself, the mouse is updated on every loop
-- through Main(), below.
if setup then
	
	function GUI.elms.frm_radial:onmouseover() 

		check_mouse()
		
	end

end



function GUI.elms.frm_radial:btn_down(btn)
	
	if mouse_mnu == -2 then return 0 end
	
	self.state = true
	GUI.redraw_z[self.z] = true	
	
	local act = mnu_arr[cur_depth][mouse_mnu] 
				and (btn == 1 and mnu_arr[cur_depth][mouse_mnu].act)
				or	(btn == 2 and mnu_arr[cur_depth][mouse_mnu].r_act)
				or	(btn == 64 and mnu_arr[cur_depth][mouse_mnu].m_act)
				or	nil
				
	if not act then return 0 end
				
	if string.match( act, "^repeat" ) then
		
		_=dm and Msg("parsing repeat action: "..tostring(string.sub(act, 8)))
	--[[
	
			repeat 0.5 x3 12345
			       |->	
	
					^([^ ]+) +[\'\"](.*)[\'\"]$
	
	]]--
		repeat_act = 	not repeat_act 
						and { string.match( 
											string.sub(act, 8), "^([^ ]+) +[\'\"](.*)[\'\"]$") 
							}
			
		if repeat_act and #repeat_act == 2 then
			_=dm and Msg("\tgot: "..table.concat(repeat_act, ", ") )
			
			repeat_act[1] = tonumber(repeat_act[1])
			if not repeat_act[1] then
				_=dm and Msg("\ttime stamp wasn't a number")
				return 0
			end
			
			
			
			-- We need a time stamp for repeating the action
			repeat_act[3] = reaper.time_precise()
			
			-- We need to know what mouse button is being used
			--[[
			repeat_act[4] = ((GUI.mouse.cap & 1 == 1) and 1 )
						or	((GUI.mouse.cap & 2 == 2) and 2 )
						or	((GUI.mouse.cap & 64 == 64) and 64)
						or	nil
			]]--
			repeat_act[4] = btn
			
			-- Make sure it wasn't a hover or swipe "click"
			if not (repeat_act[1] and repeat_act[4]) then
				_=dm and Msg("\tno mouse buttons down")
				repeat_act = false
				return 0
			end
			
			_=dm and Msg("\tmouse state: "..tostring(repeat_act[4]))
			run_act(repeat_act[2])
			
		else
			_=dm and Msg("\tparsing failed")
			repeat_act = false
			return 0
		end

		_=dm and Msg("done with repeat action")
	
	end
	
	
end

function GUI.elms.frm_radial:onmousedown()
	self:btn_down(1)
end

function GUI.elms.frm_radial:onmouser_down()	
	self:btn_down(2)	
end

function GUI.elms.frm_radial:onmousem_down()
	self:btn_down(64)
end



function GUI.elms.frm_radial:btn_up(btn)
	
	
	opt_clicked = true
	repeat_act = false
	self.state = false	
	
	if setup and (GUI.mouse.cap & 8 == 8) then

		cur_btn = (mouse_mnu ~= -2) and mouse_mnu or -2
		GUI.Val("tabs", 1)
		update_btn_settings()
		GUI.redraw_z[self.z] = true		
		
		return 0
		
	end
	
	
	local mnu = mouse_mnu
	
	_=dm and Msg("clicked button "..tostring(mnu))
	
	-- Didn't click a button; reset to the base menu
	if mnu == -2 and cur_depth ~= 0 then
	
		_=dm and Msg("\tresetting to base depth")
		run_act( "back" )

	-- Clicked a button; parse the action
	elseif mnu_arr[cur_depth][mnu] then

		local act = mnu_arr[cur_depth][mouse_mnu] 
					and (btn == 1 and mnu_arr[cur_depth][mouse_mnu].act)
					or	(btn == 2 and mnu_arr[cur_depth][mouse_mnu].r_act)
					or	(btn == 64 and mnu_arr[cur_depth][mouse_mnu].m_act)
					or	nil
					
		if act then	run_act( act ) end
		
		
	end

	hvr_time = nil

	-- If we're running without a key being held down, reset the Quit timer
	if up_time then 
		_=dm and Msg("\tresetting up_time")
		up_time = reaper.time_precise() 
	end

	--GUI.Val("mnu_menu", cur_depth + 1)

	if setup then
		
		update_btn_settings()
		update_mnu_settings()
		update_mnu_menu()

	end

	GUI.redraw_z[self.z] = true
	
	
end


function GUI.elms.frm_radial:onmouseup()
	self:btn_up(1)
end

function GUI.elms.frm_radial:onmouser_up()
	self:btn_up(2)
end

function GUI.elms.frm_radial:onmousem_up()
	self:btn_up(64)
end

function GUI.elms.frm_radial:ondoubleclick()
	self:btn_up(1)
end

function GUI.elms.frm_radial:onr_doubleclick()
	self:btn_up(2)	
end

function GUI.elms.frm_radial:onm_doubleclick()
	self:btn_up(64)
end






---- Setup properties and methods ----

if setup then

	GUI.elms_hide = {[20] = true}
	GUI.elms_freeze = {[10] = true, [22] = true}
	
	GUI.elms.tabs:update_sets(
		{
		[1] = {2, 3, 4},
		[2] = {5, 6, 7},
		[4] = {8, 9, 10},
		[3] = {17, 18, 19},
		[5] = {11, 12, 13},
		[6] = {14, 15, 16},
		}
	)
	


	---- Tooltips ----

	function assign_tooltips()
		
		-- Trash variable, placeholder for assigning the same tooltip to multiple elements
		-- rather than having to type/copy/edit them multiple times
		local tip
			
		
		-- Menus tab --
		
		GUI.elms.btn_add_menu.tooltip = "Add a new menu"
		GUI.elms.btn_del_menu.tooltip = "Delete this menu"
		
		GUI.elms.mnu_menu.tooltip = "Select a menu to edit (new menus are created the first time you click the button assigned to them)"

		tip = "Swiping is currently set to use this menu"
		GUI.elms.frm_swipe_menu.tooltip = tip
		GUI.elms.lbl_swipe_menu.tooltip = tip
		
		GUI.elms.txt_alias.tooltip = "Assign an alias to this menu"
		
		tip = "The menu's normal button color"
		GUI.elms.lbl_col_m_btn.tooltip = tip
		GUI.elms.frm_col_m_btn.tooltip = tip
		
		tip = "The menu's mouse-over color"
		GUI.elms.lbl_col_m_hvr.tooltip = tip
		GUI.elms.frm_col_m_hvr.tooltip = tip

		tip = "The menu's 'this action is toggled on' color"
		GUI.elms.lbl_col_m_tog.tooltip = tip
		GUI.elms.frm_col_m_tog.tooltip = tip
		
		tip = "The menu's background color"
		GUI.elms.lbl_col_m_bg.tooltip = tip
		GUI.elms.frm_col_m_bg.tooltip = tip
		
		GUI.elms.btn_use_global.tooltip = "Use the global settings for this menu (won't override individual button colors)"
		
		tip = "Add or remove buttons from the current menu (16 buttons max)"
		GUI.elms.lbl_num_m_btns.tooltip = tip
		GUI.elms.num_m_btns_rem.tooltip = tip
		GUI.elms.num_m_btns_add.tooltip = tip
		
		GUI.elms.chk_center.tooltip = "Add an additional button in the center of this menu"
		
		GUI.elms.frm_no_btn.tooltip = "Shift-click a button in the radial menu to edit it"
		
		GUI.elms.btn_btn_left.tooltip = "Move this button counterclockwise"
		GUI.elms.btn_btn_right.tooltip = "Move this button clockwise"
		GUI.elms.btn_btn_del.tooltip = "Delete this button"
		
		
		tip = "The button's normal color"
		GUI.elms.lbl_col_b_btn.tooltip = tip
		GUI.elms.frm_col_b_btn.tooltip = tip
		
		tip = "The button's mouse-over color"
		GUI.elms.lbl_col_b_hvr.tooltip = tip
		GUI.elms.frm_col_b_hvr.tooltip = tip
		
		tip = "The button's 'this action is toggled on' color"
		GUI.elms.lbl_col_b_tog.tooltip = tip
		GUI.elms.frm_col_b_tog.tooltip = tip
		
		GUI.elms.btn_use_mnu.tooltip = "Use the menu's settings for this button"
		
		GUI.elms.txt_btn_lbl.tooltip = "What label to display for the button (Use '|' to wrap text to a new line)"
		
		tip = "What action to assign to this button (see 'Help' tab for extra commands)"
		GUI.elms.txt_btn_act.tooltip = tip
		GUI.elms.txt_btn_r_act.tooltip = tip
		GUI.elms.txt_btn_m_act.tooltip = tip
		tip = "Scripts can't access the clipboard, so use this to paste action IDs from Reaper"
		GUI.elms.btn_paste.tooltip = tip
		GUI.elms.btn_r_paste.tooltip = tip
		GUI.elms.btn_m_paste.tooltip = tip



		-- Context tab --
		-- Populated at runtime --
		
		

		-- Swiping tab --

		GUI.elms.chk_swipe.tooltip = "Enable/disable mouse swiping to 'click' buttons"
		
		GUI.elms.frm_no_swipe.tooltip = "Enable swiping to use these options"
		
		GUI.elms.sldr_accel.tooltip = "How easily the script will begin tracking a Swipe"
		GUI.elms.sldr_decel.tooltip = "How slow the mouse must be moving to be considered 'stopped'"
		GUI.elms.sldr_stop.tooltip = "How long the mouse must be stopped before triggering an action"
		GUI.elms.sldr_re.tooltip = "Swipes are only tracked if the mouse is outside this radius"
		
		GUI.elms.opt_swipe_mode.tooltip = "What set of actions to use for Swipes"
		GUI.elms.chk_swipe_acts.tooltip = "Allow Swiping to trigger Reaper actions, or only open menus?"



		-- Global tab --

		tip = "The normal button color"
		GUI.elms.lbl_col_g_btn.tooltip = tip
		GUI.elms.frm_col_g_btn.tooltip = tip
		
		tip = "Moused-over button color"
		GUI.elms.lbl_col_g_hvr.tooltip = tip
		GUI.elms.frm_col_g_hvr.tooltip = tip
		
		tip = "'This action is toggled on' button color"
		GUI.elms.lbl_col_g_tog.tooltip = tip
		GUI.elms.frm_col_g_tog.tooltip = tip
		
		tip = "Menu background color"
		GUI.elms.lbl_col_g_bg.tooltip = tip
		GUI.elms.frm_col_g_bg.tooltip = tip
		
		GUI.elms.chk_preview.tooltip = "When hovering over a menu, show a 'preview' of that menu's buttons"
		
		GUI.elms.sldr_num_btns.tooltip = "Number of buttons to add when first creating a new menu"
		
		GUI.elms.sldr_ra.tooltip = "The size of the center button - also the size of the 'dead zone' if the center button isn't shown"
		GUI.elms.sldr_rb.tooltip = "I'm sure I'll find a use for this one soon"
		GUI.elms.sldr_rc.tooltip = "The inner radius of the menu ring"
		GUI.elms.sldr_rd.tooltip = "The outer radius of the menu ring"
		
		GUI.elms.txt_font_A.tooltip = "What font to use for normal buttons"
		GUI.elms.txt_font_B.tooltip = "What font to use for menu buttons"
		GUI.elms.txt_font_C.tooltip = "What font to use for preview text"
		
		GUI.elms.txt_size_A.tooltip = "Font size for normal buttons"
		GUI.elms.txt_size_B.tooltip = "Font size for menu buttons"
		GUI.elms.txt_size_C.tooltip = "Font size for preview text"
		
		GUI.elms.frm_val_fonts.tooltip = "Indicates whether or not the given font name is valid"
		
		GUI.elms.chk_keys.tooltip = "Enables the use of keyboard keys to 'click' buttons"
		GUI.elms.chk_hints.tooltip = "Show key binds next to each menu button"
		GUI.elms.mnu_keys.tooltip = "What size of menu to assign key binds for"
		GUI.elms.btn_keys_clear.tooltip = "Clear all key binds for the current menu size"
		GUI.elms.btn_keys_pr_dn.tooltip = "Copy this size's key binds to all smaller sizes"
		GUI.elms.btn_keys_pr_up.tooltip = "Copy this size's key binds to all larger sizes"		
		
		
		
		
		-- Options tab --
		
		GUI.elms.opt_win_pos.tooltip = "Where to open the Radial Menu window"
		GUI.elms.opt_mouse_mode.tooltip = "What to do when an action is clicked"		
		GUI.elms.opt_key_mode.tooltip = "What to do when the script's shortcut key is released"

		
		GUI.elms.btn_open_txt.tooltip = "Open the settings file in the system's text editor"
		GUI.elms.btn_refresh_txt.tooltip = "Refresh menus and settings from the settings file"
		GUI.elms.btn_load_txt.tooltip = "Load menus and settings from another file"
		GUI.elms.btn_save_txt.tooltip = "Save menus and settings to a separate file"
		GUI.elms.btn_spit_table.tooltip = "Display the current menus and settings in Reaper's console (may take a few seconds)"
		
		
		
		-- Help tab --
		GUI.elms.btn_thread.tooltip = "Open the official Reaper forum thread for this script"
		GUI.elms.btn_donate.tooltip = "Open a PayPal donation link for the script's author"


	end


	-- Update the tooltip label
	-- Use force = [tooltip_idx] to, duh, force that tooltip to display
	function update_tooltip(force)

		if GUI.tooltip_elm or force then
			--GUI.Msg("step 1")
			if force or GUI.IsInside(GUI.tooltip_elm, GUI.mouse.x, GUI.mouse.y) then
				--GUI.Msg("step 2")
				if GUI.elms.lbl_tooltip.z == 20 or GUI.elms.lbl_tooltip.fade_arr or force then
					
					GUI.elms.lbl_tooltip.fade_arr = nil
					
					GUI.font(4)
					local str = force or GUI.tooltip_elm.tooltip  --tooltips[force or GUI.tooltip_elm.tooltip]
					local str_w, str_h = gfx.measurestr(str)
					
					GUI.elms.lbl_tooltip.x = (GUI.w - str_w) / 2
					GUI.elms.lbl_tooltip.y = line_y_tt + (30 - str_h) / 2 + 4
					
					GUI.Val("lbl_tooltip", str)
					GUI.elms.lbl_tooltip.z = 1
				
				end
			elseif not GUI.mouse.down then
				
				--GUI.elms.lbl_tooltip.z = 18
				GUI.elms.lbl_tooltip:fade(2, 1, 20)
				GUI.tooltip_elm = nil	
				--GUI.Msg("setting nil")
				
			end
		end
		
		GUI.forcetooltip = nil
		
	end






	---- Context text boxes

	-- Make a whole bunch of text boxes for the context tab
	--							z	x	 y				w	h	pad
	local txt_con_template = {	6,	504, line_y0 + 16, 80, 20, 4}
	
	function update_context_elms(init)
		

		
		if init then
			
			_=dm and Msg(">init context elms")
			
			local z, x, y, w, h, pad = table.unpack(txt_con_template)
			local x_adj, y_adj = 0, 24
			local col_adj = 0
			
			
			local function txt_update(self)
				
				_=dm and Msg("updating context "..context_arr[self.i].con)
				_=dm and Msg("\tuser entered "..self.retval)
				
				GUI.Textbox.lostfocus(self)
				
				if not self.retval or self.retval == "" then
					--self.retval = mnu_arr[-1].contexts[ context_arr[self.i].con ] or ""
					self.retval = ""
					mnu_arr[-1].contexts[ context_arr[self.i].con ] = ""
					
				elseif tonumber(self.retval) and tonumber(self.retval) > 0 then
					_=dm and Msg("\tit's a number; assigning")
					mnu_arr[-1].contexts[ context_arr[self.i].con ] = tonumber(self.retval)
				elseif check_alias(self.retval) then
					_=dm and Msg("\tit's an alias; looking it up")
					mnu_arr[-1].contexts[ context_arr[self.i].con ] = self.retval
					
					_=dm and Msg("\tgot: "..check_alias(self.retval))

				end
				
			end
			
			local function txt_dbl(self)
				
				GUI.Textbox.ondoubleclick(self)
				
				local val = tonumber(self.retval) or check_alias(self.retval)
				
				if val then
					cur_depth = val
					cur_btn = -2
					update_mnu_menu()
					update_mnu_settings()	
					update_btn_settings()
					GUI.Val("tabs", 1)
				
				else
				
					reaper.ShowMessageBox("Menu '"..tostring(self.retval).."' doesn't seem to exist.", "Whoops", 0)
				
				end
				
				self.focus = false
				self:lostfocus()
				
			end
			
			local tip_str = "What menu to use when Radial Menu is opened for the context: '"
			
			local col_adj_x, col_adj_y = 196, 0
			
			for i = 1, #context_arr do
				
				local lbl = context_arr[i].lbl
				if lbl ~= "" then
					if context_arr[i].lbl == "Arrange" then 
						x_adj = col_adj_x
						col_adj_y = y_adj * -(i - 1)

					elseif context_arr[i].lbl == "Transport" then
						x_adj = col_adj_x * 2
						col_adj_y = y_adj * -(i - 1)
					end
					
					local name = "txt_context_"..i
					
					local y_adj = (i - 1) * y_adj
					local x_adj = x_adj + ((context_arr[i].head - 1) * 16)
					
					GUI.elms[name] = GUI.Textbox:new(z, x + x_adj, y + y_adj + col_adj_y, w, h, context_arr[i].lbl, pad)
					GUI.elms[name].i = i
					GUI.elms[name].font_A = 	((context_arr[i].head == 1) and 2)
											or	((context_arr[i].head == 2) and 3)
											or	((context_arr[i].head == 3) and 5)
					GUI.elms[name].font_B = 5
					GUI.elms[name].lostfocus = txt_update
					GUI.elms[name].ondoubleclick = txt_dbl
					GUI.elms[name].tooltip = tip_str..string.gsub(context_arr[i].con, "|", ", ").."'"
					
				end
			end
		
			_=dm and Msg("<init context elms")
		
		else

			_=dm and Msg(">update_context_elms")

			local arr = mnu_arr[-1].contexts
		
			-- Updating textboxes from the values in mnu_arr
			for i = 1, #context_arr do
				
				-- Skip over the entries we're using as spacers
				if context_arr[i].lbl ~= "" then
					
					local name = "txt_context_"..i
					local con = context_arr[GUI.elms[name].i].con
					local val = arr[con] or ""

					GUI.Val(name, val)
					
				end
				
			end
			
			_=dm and Msg("<update_context_elms")
		
		end	



	end



	---- Key binding text boxes

	local l = GUI.elms.mnu_keys.x + GUI.elms.mnu_keys.w
	local txt_key_template = {	8,	l + (1024 - l) / 2, line_y5 + (line_y_tt - line_y5) / 2, 20, 20}
	
	local r = 80
	local aspect = 1
	
	GUI.elms.frm_keys_bg.x, GUI.elms.frm_keys_bg.y = txt_key_template[2], txt_key_template[3]
	GUI.elms.frm_keys_bg.r = r
	
	function update_key_elms(init)
		
		_=dm and Msg(">init key bind elms")
		
		local z, x, y, w, h = table.unpack(txt_key_template)
		local x_adj, y_adj = 48, 24


		local function key_update(self)
			
			_=dm and Msg("updating key bind "..self.i)
			_=dm and Msg("\tuser entered "..self.retval)
			
			GUI.Textbox.lostfocus(self)
			
			if not self.retval or self.retval == "" then
				
				self.retval = ""
				mnu_arr[-1].key_binds[mnu_arr[-1].key_binds.last_num + 3][self.i] = ""
				
			else
				
				self.retval = string.sub(self.retval, 1, 1)
				mnu_arr[-1].key_binds[mnu_arr[-1].key_binds.last_num + 3][self.i] = self.retval

			end
			
		end
		
		
		local num = (mnu_arr[-1].key_binds.last_num or 5) + 3

		for i = -1, 16 do
			
			local name = "txt_key_"..i
			
			if i > num then
				
				if GUI.elms[name] then GUI.elms[name].z = -1 end
			
			elseif i ~= 0 then
			
				local cx, cy
				
				if i == -1 then
			
					cx, cy = x, y
			
				else

					local angle = ((i - 1) / num) * 2 * GUI.pi
				
					cx, cy = x + cos(angle) * r, y + sin(angle) * r * aspect
				
				end
				
				local x, y = cx - w / 2, cy - h / 2
				
				GUI.elms[name] = GUI.Textbox:new(z, x, y, w, h, "", 4)
				GUI.elms[name].i = i
				GUI.elms[name].lostfocus = key_update
				GUI.elms[name].tooltip = "Key bind to menu button "..i	
				
			end
			
		end
			
		
		local arr = mnu_arr[-1].key_binds
		
		-- Updating textboxes from the values in mnu_arr
		for i = -1, num do
			
			if i ~= 0 then
				GUI.Val("txt_key_"..i, arr[num][i] or "")
			end
			
		end		

		
	end

	
	assign_tooltips()
	update_context_elms(true)
	--update_key_elms(true)


	GUI.elms.tabs.font_A = 6

	GUI.elms.frm_radial.state = false
	--GUI.elms.frm_radial.font = 6

	GUI.elms.lbl_swipe_menu.color = "magenta"



	GUI.elms.mnu_menu.font = 2
	GUI.elms.mnu_menu.output = function(text)
		
		return string.match(text, "^(%d+)")
		
	end
		


	function GUI.elms.txt_alias:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth].alias = tostring(self.retval)
	
	end

	function GUI.elms.txt_alias:lostfocus()

		_=dm and Msg("updating menu "..tostring(cur_depth).."'s alias: "..tostring(self.retval))
		mnu_arr[cur_depth].alias = tostring(self.retval)
		
		update_mnu_menu()
		update_mnu_settings()

	end


	GUI.elms.sldr_num_btns.output = function (self)
		
		return "Create new menus with "..tostring(self.curstep + self.min).." buttons"
		
	end
	

	GUI.elms.sldr_ra.col_a = "red"
	GUI.elms.sldr_rb.col_a = "lime"
	GUI.elms.sldr_rc.col_a = "yellow"
	GUI.elms.sldr_rd.col_a = "cyan"
	GUI.elms.sldr_re.col_a = "magenta"

	local function rad_sldr_output(self)	
		return tostring(self.curstep + self.min) .. " px" 
	end
	GUI.elms.sldr_ra.output = rad_sldr_output
	GUI.elms.sldr_rb.output = rad_sldr_output
	GUI.elms.sldr_rc.output = rad_sldr_output
	GUI.elms.sldr_rd.output = rad_sldr_output
	GUI.elms.sldr_re.output = rad_sldr_output



	GUI.elms.sldr_accel.output = function(self)
		return self.retval.."%"
	end

	GUI.elms.sldr_decel.output = function(self)
		return self.retval.."%"
	end

	GUI.elms.sldr_stop.output = function(self)
		return (self.retval) .. " ms"
	end




	---- Method overrides ----


	-- Save settings every time the user changes the active tab
	function GUI.elms.tabs:update_sets()
		
		GUI.Tabframe.update_sets(self)
		mnu_arr[-1].last_tab = self.state
		save_menu()
		
	end



	function GUI.elms.frm_line_tt:draw()
		
		GUI.color("elm_bg")
		gfx.rect(0, GUI.elms.frm_line_tt.y, self.w, 32)
		GUI.Frame.draw(self)
		
	end



	-- Pink overlay when working on the Swipe menu
	-- Also centers the pink "Assigned to this menu" label
	function init_frm_swipe_menu()

		local gap = 12
		
		GUI.elms.frm_swipe_menu.gap = gap
		
		local w = frm_w - 2*gap

		gfx.dest = 101
		gfx.setimgdim(101, -1, -1)
		gfx.setimgdim(101, w, w)
		gfx.set(0, 0, 0, 1)
		
		gfx.circle(ox - gap, ox - gap, 192 + 4*gap, true, 1)


		gfx.dest = 100
		gfx.setimgdim(100, -1, -1)
		gfx.setimgdim(100, w, w)
		
		GUI.color("magenta")
		
		gfx.rect(0, 0, w, w)
		
		gfx_mode = 1
		gfx.blit(101, 1, 0)
		
		gfx.muladdrect(0, 0, w, w, 1, 1, 1, 0.5)

		gfx_mode = 0
		gfx.dest = -1	
		
		
		
		GUI.font(GUI.elms.lbl_swipe_menu.font)
		local str_w, str_h = gfx.measurestr(GUI.elms.lbl_swipe_menu.retval)
		GUI.elms.lbl_swipe_menu.x = (line_x - str_w) / 2
		GUI.elms.lbl_swipe_menu.y = ((oy - (w / 2)) - str_h) / 2
		
	end



	-- Draw the chosen color inside the frame
	function draw_col_frame(self)
		
		local x, y, w, h = self.x + 1, self.y + 1, self.w - 2, self.h - 2
		
		GUI.color(self.color)
		gfx.rect(x, y, w, h, true)	
		
		if self.col_user then
			--[[
			if type(self.col_user) ~= "table" then
				reaper.ShowMessageBox(
					"Got a bad color table when drawing the color frame at ("
					..tostring(self.x)
					..", "..tostring(self.y)
					..".\nself.col_user = "
					..tostring(self.col_user)
					.."\nDefaulting to gray for this element."
					,
					"Whoops", 0
				)
				self.col_user = {0.5, 0.5, 0.5}
			end
			]]--
			--gfx.set(table.unpack(self.col_user))
			
			GUI.color(self.col_user)
			gfx.rect(x + 1, y + 1, w - 2, h - 2, true)
		end
		
		GUI.color("black")
		gfx.rect(x, y, w, h, false)
		
	end	


	-- Pop up the OS color picker and assign the result to this frame
	function get_color_picker(self)
		
		local retval, colorOut = reaper.GR_SelectColor()
		
		if retval ~= 0 then
			
			--local r, g, b = GUI.num2rgb(colorOut)
			local r, g, b = reaper.ColorFromNative(colorOut)
			self.col_user = {r / 255, g / 255, b / 255}
			GUI.redraw_z[self.z] = true
			redraw_menu = true
			
		end
	end


	function update_rad_sldrs(sldr)
		
		local ra, rb, rc, rd, re = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd, mnu_arr[-1].re
		
		local gap = 4
		
		if sldr == "a" then
			
			ra = GUI.Val("sldr_ra") + GUI.elms.sldr_ra.min
			
			if rb - ra < gap then
				rb = ra + gap
			end
			
			if rc - rb < gap then
				rc = rb + gap
			end
			
			if rd - rc < gap then
				rd = rc + gap
			end
			
		elseif sldr == "b" then
		
			rb = GUI.Val("sldr_rb") + GUI.elms.sldr_rb.min
			
			if rb - ra < gap then
				ra = rb - gap
				
			else
				if rc - rb < gap then
					rc = rb + gap
				end
				
				if rd - rc < gap then
					rd = rc + gap
				end
			end

		elseif sldr == "c" then
		
			rc = GUI.Val("sldr_rc") + GUI.elms.sldr_rc.min
			if rc - rb < gap then
				
				rb = rc - gap

				if rb - ra < gap then
					ra = rb - gap
				end

			else
			
				if rd - rc < gap then
					rd = rc + gap
				end
			end
		
		elseif sldr == "d" then
		
			rd = GUI.Val("sldr_rd") + GUI.elms.sldr_rd.min
			if rd - rc < gap then
				rc = rd - gap
			end
			
			if rc - rb < gap then
				rb = rc - gap
			end
			
			if rb - ra < gap then
				ra = rb - gap
			end	

		end
		
		GUI.Val("sldr_ra", ra - GUI.elms.sldr_ra.min)
		GUI.Val("sldr_rb", rb - GUI.elms.sldr_rb.min)
		GUI.Val("sldr_rc", rc - GUI.elms.sldr_rc.min)
		GUI.Val("sldr_rd", rd - GUI.elms.sldr_rd.min)
		GUI.Val("sldr_re", re - GUI.elms.sldr_re.min)
		
		mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd = ra, rb, rc, rd
		
		redraw_menu = true
			
	end







	function GUI.elms.frm_swipe_menu:draw()
		
		local w, h = gfx.getimgdim(100)
		gfx.x, gfx.y = self.gap, self.gap + (oy - (frm_w / 2))
		gfx.mode = 1
	--gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs] )
		gfx.blit(100, 1, 0)
		
		gfx.mode = 0
		
	end



	-- Changing the current menu
	function GUI.elms.mnu_menu:val(newval)
		
		local retval = GUI.Menubox.val(self, newval)
		if newval then 
			
			cur_btn = -2
			update_mnu_settings()
			update_btn_settings()
		else
			return retval 
		end

	end
	function GUI.elms.mnu_menu:onmouseup()
		
		GUI.Menubox.onmouseup(self)

		cur_depth = tonumber(string.match(self.optarray[GUI.Val("mnu_menu")], "^(%d+)"))

		cur_btn = -2
		update_mnu_settings()	
		update_btn_settings()

		
	end
	function GUI.elms.mnu_menu:onwheel()
		
		GUI.Menubox.onwheel(self)
		cur_depth = tonumber(string.match(self.optarray[GUI.Val("mnu_menu")], "^(%d+)"))
		cur_btn = -2
		update_mnu_settings()
		update_btn_settings()
		
	end
	


	-- Color pickers --

	function GUI.elms.frm_col_m_btn:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)

	end
	function GUI.elms.frm_col_m_hvr:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_m_tog:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_m_bg:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_b_btn:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_b_hvr:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_b_tog:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_g_btn:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)

	end
	function GUI.elms.frm_col_g_hvr:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_g_tog:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end
	function GUI.elms.frm_col_g_bg:draw()
		
		GUI.Frame.draw(self)
		draw_col_frame(self)
		
	end



	-- Global colors
	function GUI.elms.frm_col_g_btn:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[-1].col_main = self.col_user
		update_mnu_settings()
		
	end
	function GUI.elms.frm_col_g_hvr:onmouseup() 

		get_color_picker(self) 
		mnu_arr[-1].col_hvr = self.col_user
		update_mnu_settings()		
		
	end
	function GUI.elms.frm_col_g_tog:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[-1].col_tog = self.col_user
		update_mnu_settings()		
		
	end
	function GUI.elms.frm_col_g_bg:onmouseup() 
		
		get_color_picker(self)
		mnu_arr[-1].col_bg = self.col_user
		update_mnu_settings()		

	end
	

	-- Menu colors
	function GUI.elms.frm_col_m_btn:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_main = self.col_user
		update_btn_settings()
		
	end
	function GUI.elms.frm_col_m_hvr:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_hvr = self.col_user
		update_btn_settings()		
		
	end
	function GUI.elms.frm_col_m_tog:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_tog = self.col_user
		update_btn_settings()		

	end
	function GUI.elms.frm_col_m_bg:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth].col_bg = self.col_user
		update_btn_settings()		

	end
	

	-- Button colors
	function GUI.elms.frm_col_b_btn:onmouseup()	
		
		get_color_picker(self) 
		mnu_arr[cur_depth][cur_btn].col_main = self.col_user
		
	end
	function GUI.elms.frm_col_b_hvr:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth][cur_btn].col_hvr = self.col_user

	end
	function GUI.elms.frm_col_b_tog:onmouseup() 
		
		get_color_picker(self) 
		mnu_arr[cur_depth][cur_btn].col_tog = self.col_user

	end




	-- Global "Number of buttons" slider
	function GUI.elms.sldr_num_btns:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].num_btns = self.curstep + self.min
		
	end
	function GUI.elms.sldr_num_btns:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].num_btns = self.curstep + self.min
		
	end
	function GUI.elms.sldr_num_btns:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].num_btns = self.curstep + self.min
		
	end



	function GUI.elms.chk_swipe:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].swipe.enabled = self.optsel[1]
		GUI.elms.frm_no_swipe.z = self.optsel[1] and 20 or 17
		
		update_mnu_settings()
		
	end

	-- Swipe sliders
	function GUI.elms.sldr_accel:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:onmousedown()
		
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].swipe.stop = self.retval
		
	end
	function GUI.elms.sldr_accel:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:ondrag()
		
		GUI.Slider.ondrag(self)
		mnu_arr[-1].swipe.stop = self.retval

	end
	function GUI.elms.sldr_accel:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:onwheel()
		
		GUI.Slider.onwheel(self)
		mnu_arr[-1].swipe.stop = self.retval

	end
	function GUI.elms.sldr_accel:ondoubleclick()
		
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].swipe.accel = self.retval
		
	end
	function GUI.elms.sldr_decel:ondoubleclick()
		
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].swipe.decel = self.retval

	end
	function GUI.elms.sldr_stop:ondoubleclick()
		
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].swipe.stop = self.retval
		
	end


	-- Swipe modes
	function GUI.elms.opt_swipe_mode:onmouseup()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].swipe.mode = self.retval
		update_mnu_settings()
		
	end

	function GUI.elms.opt_swipe_mode:onwheel()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].swipe.mode = self.retval	
		update_mnu_settings()
		
	end
	
	
	function GUI.elms.txt_swipe_menu:lostfocus()

		GUI.Textbox.lostfocus(self)
		
		_=dm and Msg("updating swipe menu")
		_=dm and Msg("\tuser entered "..self.retval)
		
		if not self.retval or self.retval == "" then
			self.retval = ""
			mnu_arr[-1].swipe.menu = ""
		
		elseif (tonumber(self.retval) and tonumber(self.retval) > 0) then
			_=dm and Msg("\tit's a number; assigning")
			mnu_arr[-1].swipe.menu = tonumber(self.retval)
		elseif check_alias(self.retval) then
			_=dm and Msg("\tit's an alias; looking it up")
			mnu_arr[-1].swipe.menu = self.retval
			
			_=dm and Msg("\tgot: "..check_alias(self.retval))
		else
			self.retval = mnu_arr[-1].swipe.menu or ""
		end	
		
		update_mnu_settings()
		
	end

	function GUI.elms.txt_swipe_menu:ondoubleclick()
		
		GUI.Textbox.ondoubleclick(self)
		
		local val = tonumber(self.retval) or check_alias(self.retval)
		
		if val then
			cur_depth = val
			cur_btn = -2
			update_mnu_menu()
			update_mnu_settings()	
			update_btn_settings()
			GUI.Val("tabs", 1)
			
		else
		
			reaper.ShowMessageBox("Menu '"..tostring(self.retval).."' doesn't seem to exist.", "Whoops", 0)
			
		end
		
		self.focus = false
		self:lostfocus()	
		
	end


	function GUI.elms.chk_swipe_acts:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].swipe.actions = self.optsel[1]
		
	end



	-- Radius overlay and sliders
	function GUI.elms.frm_rad_overlay:draw()
		
		GUI.Frame.draw(self)
		
		local ra, rb, rc, rd, re = mnu_arr[-1].ra, mnu_arr[-1].rb, mnu_arr[-1].rc, mnu_arr[-1].rd, mnu_arr[-1].re
		local swipe = GUI.elms.tabs.state == 3
		
		
		if not swipe then
			for i = -1.5, 1.5, 0.4 do
				GUI.color("red")
				gfx.circle(ox, oy, ra + i, false, 1)
				GUI.color("lime")
				--gfx.circle(ox, oy, rb + i, false, 1)
				GUI.color("yellow")
				gfx.circle(ox, oy, rc + i, false, 1)
				GUI.color("cyan")
				gfx.circle(ox, oy, rd + i, false, 1)
			end
		else
			for i = -1.5, 1.5, 0.4 do
				GUI.color("magenta")
				local adj = 0.1
				local angle
				for j = 0, 19 do
				
					angle = j * adj * pi
					gfx.arc(ox, oy, re + i, angle - 0.07, angle + 0.07)
					
				end
			end
		end
	end


	function GUI.elms.sldr_ra:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:onmousedown()
		GUI.Slider.onmousedown(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:onmousedown()
		GUI.Slider.onmousedown(self)
		mnu_arr[-1].re = self.curstep + self.min	
	end
	function GUI.elms.sldr_ra:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:ondrag()
		GUI.Slider.ondrag(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:ondrag()
		GUI.Slider.ondrag(self)
		mnu_arr[-1].re = self.curstep + self.min
	end
	function GUI.elms.sldr_ra:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:onwheel()
		GUI.Slider.onwheel(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:onwheel()
		GUI.Slider.onwheel(self)
		mnu_arr[-1].re = self.curstep + self.min
	end
	function GUI.elms.sldr_ra:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("a")	
	end
	function GUI.elms.sldr_rb:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("b")	
	end
	function GUI.elms.sldr_rc:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("c")	
	end
	function GUI.elms.sldr_rd:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		update_rad_sldrs("d")	
	end
	function GUI.elms.sldr_re:ondoubleclick()
		GUI.Slider.ondoubleclick(self)
		mnu_arr[-1].re = self.curstep + self.min
	end





	-- Update the current button's label/actions
	function GUI.elms.txt_btn_lbl:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth][cur_btn].lbl = self.retval
		
	end
	function GUI.elms.txt_btn_act:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth][cur_btn].act = self.retval
		
	end
	function GUI.elms.txt_btn_r_act:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth][cur_btn].r_act = self.retval
		
	end
	function GUI.elms.txt_btn_m_act:ontype()
		
		GUI.Textbox.ontype(self)
		mnu_arr[cur_depth][cur_btn].m_act = self.retval
		
	end

	function GUI.elms.chk_center:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		if self.optsel[1] then
			init_btn(cur_depth, -1, "center")
		else
			if cur_btn == -1 then cur_btn = -2 end
			mnu_arr[cur_depth][-1] = nil
		end
		
		update_btn_settings()
		GUI.redraw_z[0] = true
		
	end



	function GUI.elms.chk_preview:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].preview = self.optsel[1]
		
	end




	---- Font settings stuff ----

	function GUI.elms.frm_val_fonts:draw()

		--GUI.Frame.draw(self)
	
		local c1, c2, c3 = 	(validate_font( GUI.elms.txt_font_A.retval ) and "lime" or "red"),
							(validate_font( GUI.elms.txt_font_B.retval ) and "lime" or "red"),
							(validate_font( GUI.elms.txt_font_C.retval ) and "lime" or "red"),	
		
		
		GUI.font(4)
		
		local x, y = 	GUI.elms.txt_font_A.x + GUI.elms.txt_font_A.w + 4, 
						GUI.elms.txt_font_A.y + 4
	
		GUI.color(c1)
		gfx.circle(x, y, 2, true, true)
		
		GUI.color(c2)
		gfx.circle(x, y + 26, 2, true, true)
		
		GUI.color(c3)
		gfx.circle(x, y + 52, 2, true, true)
		
	end

	function GUI.elms.txt_font_A:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		
		if validate_font(self.retval) then
			mnu_arr[-1].fonts[1][1] = self.retval
		else
			self.retval = mnu_arr[-1].fonts[1][1]
		end		
		
	end

	function GUI.elms.txt_font_B:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		
		if validate_font(self.retval) then
			mnu_arr[-1].fonts[2][1] = self.retval
		else
			self.retval = mnu_arr[-1].fonts[2][1]
		end		
		
	end

	function GUI.elms.txt_font_C:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		
		if validate_font(self.retval) then
			mnu_arr[-1].fonts[3][1] = self.retval
		else
			self.retval = mnu_arr[-1].fonts[3][1]
		end		
		
	end

	function GUI.elms.txt_size_A:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		
		self.retval = tonumber(self.retval)
		
		if self.retval then
			mnu_arr[-1].fonts[1][2] = self.retval
		else
			self.retval = mnu_arr[-1].fonts[1][2]
		end
		
	end

	function GUI.elms.txt_size_B:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		
		self.retval = tonumber(self.retval)
		
		if self.retval then
			mnu_arr[-1].fonts[2][2] = self.retval
		else
			self.retval = mnu_arr[-1].fonts[2][2]
		end
		
	end

	function GUI.elms.txt_size_C:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		
		self.retval = tonumber(self.retval)
		
		if self.retval then
			mnu_arr[-1].fonts[3][2] = self.retval
		else
			self.retval = mnu_arr[-1].fonts[3][2]
		end
		
	end
	
	function GUI.elms.chk_flags_A:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		
		mnu_arr[-1].fonts[1][3] = 	(self.optsel[1] and "b" or "")
								..	(self.optsel[2] and "i" or "")
								..	(self.optsel[3] and "u" or "")
								
	end
	
	function GUI.elms.chk_flags_B:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		
		mnu_arr[-1].fonts[2][3] = 	(self.optsel[1] and "b" or "")
								..	(self.optsel[2] and "i" or "")
								..	(self.optsel[3] and "u" or "")
								
	end
	
	function GUI.elms.chk_flags_C:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		
		mnu_arr[-1].fonts[3][3] = 	(self.optsel[1] and "b" or "")
								..	(self.optsel[2] and "i" or "")
								..	(self.optsel[3] and "u" or "")
								
	end
	
	
	---- Key binding stuff
	
	function GUI.elms.chk_keys:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].key_binds.enabled = self.optsel[1]
		
	end	
	
	function GUI.elms.mnu_keys:onwheel()

		GUI.Menubox.onwheel(self)
		mnu_arr[-1].key_binds.last_num = tonumber(self.retval)
		update_key_elms(true)
	
	end

	function GUI.elms.mnu_keys:onmouseup()
	
		GUI.Menubox.onmouseup(self)
		mnu_arr[-1].key_binds.last_num = tonumber(self.retval)
		update_key_elms(true)
		
	end

	function GUI.elms.chk_hints:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].key_binds.hints = self.optsel[1]
		
	end


	function GUI.elms.frm_keys_bg:draw()
		
		local x, y, r = self.x - 1, self.y - 1, self.r
		local pad = 20
		--[[
		GUI.color("shadow")
		for i = 1, GUI.shadow_dist do
			gfx.circle(x + i, y + i, r + pad, true, true)
		end
		]]--
		GUI.color( "tab_bg" )
		
		gfx.circle(x, y, r + pad, true, true)
		
		--GUI.color({0, 0, 0, 0.8})
		GUI.color( "elm_frame" )
		
		gfx.circle(x, y, r + pad, false, true)
		
		
	end


	---- Options ----


	function GUI.elms.opt_win_pos:onmouseup()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].win_pos = self.retval
		
	end
	
	function GUI.elms.opt_win_pos:onwheel()
		
		GUI.Radio.onwheel(self)
		mnu_arr[-1].win_pos = self.retval
		
	end



	function GUI.elms.opt_mouse_mode:onmouseup()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].mouse_mode = self.retval

	end
	function GUI.elms.opt_mouse_mode:onwheel()
		
		GUI.Radio.onwheel(self)
		mnu_arr[-1].mouse_mode = self.retval
		
	end




	function GUI.elms.opt_key_mode:onmouseup()
		
		GUI.Radio.onmouseup(self)
		mnu_arr[-1].key_mode = self.retval
		
	end
	function GUI.elms.opt_key_mode:onwheel()
		
		GUI.Radio.onwheel(self)
		mnu_arr[-1].key_mode = self.retval
		
	end




	function GUI.elms.chk_misc_opts:onmouseup()
		
		GUI.Checklist.onmouseup(self)
		mnu_arr[-1].hvr_click = table.unpack(GUI.Val("chk_misc_opts"))
		--GUI.Val("chk_misc_opts", {mnu_arr[-1].misc_opts[1], mnu_arr[-1].misc_opts[2]})
		--GUI.Val("txt_hvr_time", mnu_arr[-1].misc_opts[3])
		
	end

	function GUI.elms.txt_hvr_time:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		local val = tonumber(self.retval)
		if val and val > 0 then

			mnu_arr[-1].hvr_time = val
		else
			self.retval = mnu_arr[-1].hvr_time
		end
		
	end

	function GUI.elms.txt_close_time:lostfocus()
		
		GUI.Textbox.lostfocus(self)
		local val = tonumber(self.retval)
			
		if val and val > 0 then

			val = math.max(val, 1)
			mnu_arr[-1].close_time = val
			self.retval = val
		else
			self.retval = mnu_arr[-1].close_time
		end
		
	end



	---- Help ----

	function GUI.elms.mnu_help:onwheel()
		
		GUI.Menubox.onwheel(self)
		GUI.Val("frm_help", help_pages[math.floor(self.retval)][2])
		
	end
	function GUI.elms.frm_help:onwheel() GUI.elms.mnu_help:onwheel() end
	function GUI.elms.mnu_help:onmouseup()
		
		GUI.Menubox.onmouseup(self)
		GUI.Val("frm_help", help_pages[math.floor(self.retval)][2])
		
	end
	function GUI.elms.frm_help:onmouseup() GUI.elms.mnu_help:onmouseup() end






end






-- Make sure we've got a menu file to work with
if load_menu() == 0 then return 0 end

-- Setup: Init things that need to have menus/settings loaded
if setup then
	
	update_mnu_menu()
	update_glbl_settings()
	update_mnu_settings()
	update_btn_settings()
	update_context_elms()
	update_key_elms()
	update_rad_sldrs()

	reaper.atexit(save_menu)	

else


	if open_depth then	
		-- If Radial Menu was called from a shortcut script, use that for a base depth
		base_depth = open_depth
		cur_depth = open_depth
	else
		-- This needs to happen prior to the window being opened; it takes over the cursor
		get_context_mnu() 
	end

end




if not mnu_arr[cur_depth] then init_menu(cur_depth) end

frm_w = not setup								-- Add some padding if key_binding hints are enabled
					and (2 * mnu_arr[-1].rd + ((mnu_arr[-1].key_binds.enabled and mnu_arr[-1].key_binds.hints) and 24 or 0)) + 16 
					or 432
ox = frm_w / 2
oy = setup and line_y_tt / 2 or ox

-- Window parameters
if not setup then
	
	GUI.name = GUI.name or "Radial Menu"
	
	GUI.w, GUI.h = frm_w, frm_w + 16

	if mnu_arr[-1].win_pos == 1 then
		GUI.x, GUI.y = -8, -32
		GUI.anchor, GUI.corner = "mouse", "C"
	else
		GUI.x, GUI.y = table.unpack( mnu_arr[-1].last_pos or {0,0} )
		
		local function store_pos()
			
			local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
			mnu_arr[-1].last_pos = {x,y}
			save_menu()
			
		end
		
		reaper.atexit(store_pos)
		
	end
	
	GUI.elms.frm_radial.w, GUI.elms.frm_radial.h = GUI.w, GUI.h
	
	--Display the startup mode indicator if in "hold the key down" mode
	
	if mnu_arr[-1].key_mode == 1 or mnu_arr[-1].key_mode == 2 then GUI.elms.lbl_startup.z = 1 end
	
else

	GUI.name = "Radial Menu Setup"
	GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 1024, 640
	GUI.anchor, GUI.corner = "screen", "C"
	

end




_=dm and Msg("Opening GUI window")

GUI.Init()


-- Init things that need the window open
if setup then
		
	-- Format the Help tab's text so it fits
	-- Needs the window open so it can use gfx functions
	GUI.init_txt_width()
	init_help_pages()
	GUI.Val("frm_help", help_pages[1][2])
	
	-- For any elms that need adjusting
	align_elms()

	init_frm_swipe_menu()
	

else

	GUI.font(GUI.elms.lbl_version.font)
	GUI.elms.lbl_version.y = GUI.h - gfx.texth - 4

end

_=dm and Msg("Starting main GUI loop")


-- Main Radial Menu loop

local function Main()
	
	-- Prevent the user from resizing the window
	if GUI.resized then
		local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
		gfx.quit()
		gfx.init(GUI.name, GUI.w, GUI.h, 0, x, y)
		GUI.redraw_z[0] = true
	end	
	
	
	if repeat_act then check_repeat() end
	

	-- Radial Menu script loop
	if not setup then
			
		-- Main logic for the shortcut key
		
		check_key()
		

		-- Update the mouse position/angle/option/tc
		check_mouse()


		-- Check for smart tool stuff
		if armed > -2 and gfx.getchar(GUI.SPACE) > 0 then
			Msg("running smart action: "..tostring(smart_act))
			run_act(smart_act)
		end


		local diff = up_time and (reaper.time_precise() - up_time) or 0

		--[[	See if any of our numerous conditions for running the script are valid

		- Setup mode?
		- Shortcut key down?
		- Startup mode and the timer hasn't run out?
		- Running in "just leave the window open" mode?

		]]--	  

		if (setup or key_down ~= 0 or swipe_retrigger > 0 or (startup and diff < (mnu_arr[-1].close_time * 0.001)) or mnu_arr[-1].key_mode == 3) and not GUI.quit then
			-- _=dm and Msg("\tnot quitting")
			-- Do nothing, keep the window open
			if swipe_retrigger > 0 then swipe_retrigger = swipe_retrigger - 1 end
			
		elseif mnu_arr[-1].key_mode == 2 then
			_=dm and Msg("\trunning action and quitting")
			
			-- Perform the highlighted action and close the window
			if mouse_mnu > -2 and not (opt_clicked and mnu_arr[-1].hvr_click) then 
				run_act(mnu_arr[cur_depth][mouse_mnu].act) 
			end
			GUI.quit = true
		else
			_=dm and Msg("\tquitting")
			

			GUI.quit = true
		end

	
	
	-- Setup script loop
	else
		
		
		update_tooltip(GUI.forcetooltip)
		
		
		-- See if the user asked to display a context
		if GUI.elms.tabs.state == 2 and GUI.char == GUI.chars.F1 then get_context_txt() end

		
		-- See if we need to draw the radius overlay
		if  (	GUI.elms.tabs.state == 4 and 	(	GUI.IsInside(GUI.elms.frm_r2) 
												or 
												   (GUI.mouse.ox and GUI.IsInside(GUI.elms.frm_r2, GUI.mouse.ox, GUI.mouse.oy)) 
												)
			)
		or	(	GUI.elms.tabs.state == 3 and
				mnu_arr[-1].swipe.enabled and	(	GUI.IsInside(GUI.elms.frm_r1)
												or 
													(GUI.mouse.ox and GUI.IsInside(GUI.elms.frm_r1, GUI.mouse.ox, GUI.mouse.oy)) 
												or
													swiping
												)						
			)
		then
						
			local z = GUI.elms.frm_line_x.z
			
			if GUI.elms.frm_rad_overlay.z == 20 then
				GUI.elms.frm_rad_overlay.z = z
				GUI.redraw_z[z] = true
			end

		elseif GUI.elms.frm_rad_overlay.z ~= 20 then
		
			GUI.elms.frm_rad_overlay.z = 20
			GUI.redraw_z[20] = true

		end
	
	
	end
	
	
	-- Do we need to redraw the buffered copy of the menu?
	-- (Placing this last so subfunctions are always able
	-- to force a redraw properly
	if redraw_menu then
		
		GUI.elms.frm_radial:draw_base_menu()
		redraw_menu = false
		
	end	
	
	
	_=dm and Msg("----")
	
end


GUI.func = Main
GUI.freq = 0

GUI.Main()

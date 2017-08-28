--[[
Description: Theory Helper
Version: 1.40
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Fix: Note velocity being sent as 128.
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Provides a variety of music theory tools:
	
		Scales
		- Search for scales with particular notes
		
		Chords
		- Provides a list of legal chords for a given key/scale
		
		Harmony
		- Harmonize any scale automatically, with the option to
		  customize results
Extensions: SWS/S&M 2.8.3
--]]

-- Licensed under the GNU GPL v3


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
					if GUI.mouse.downtime and reaper.time_precise() - GUI.mouse.downtime < 0.10 then
	
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
			GUI.mouse.downtime = reaper.time_precise()

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
					if GUI.mouse.r_downtime and reaper.time_precise() - GUI.mouse.r_downtime < 0.20 then
						
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
			GUI.mouse.r_downtime = reaper.time_precise()

		end



		-- Middle button
		if GUI.mouse.cap&64==64 then
			
			
			-- If it wasn't down already...
			if not GUI.mouse.last_m_down then


				-- Was a different element clicked?
				if not inside then 

				else	
					-- Double clicked?
					if GUI.mouse.m_downtime and reaper.time_precise() - GUI.mouse.m_downtime < 0.20 then

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
			GUI.mouse.m_downtime = reaper.time_precise()

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
	
--[[	
	
	-- This appears to be redundant. Not sure if something in Reaper changed,
	-- or what... I could swear it used to be important. Whatever.
	
	if #sep_arr > 0 then
		for i = 1, #sep_arr do
			if curopt >= sep_arr[i] then
				curopt = curopt + 1
			else
				break
			end
		end
	end
]]--

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
	
	-- Avert a crash if there aren't at least two items in the menu
	if not self.optarray[2] then return end
	
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

		local opt = type(self.optarray[curopt]) == "table" and self.optarray[curopt][1] or self.optarray[curopt]

		if opt == "" or string.sub( opt, 1, 1 ) == ">" then 
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

	self.state = GUI.round(self.state + (dir == "h" and GUI.mouse.inc or -GUI.mouse.inc))
	
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


if not GUI.SWS_exists() then return 0 end

GUI.name = "Lokasenna's Theory Helper"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 600, 400
GUI.anchor, GUI.corner = "mouse", "C"


GUI.fonts[1] = {"Calibri", 32}
GUI.fonts[2] = {"Calibri", 20}
GUI.fonts[3] = {"Calibri", 16}
GUI.fonts[4] = {"Calibri", 16}

-- For track monitoring warning
GUI.fonts[5] = {"Calibri", 18, "bi"}

-- For the reascale label
GUI.fonts[6] = {"Calibri", 18, "b"}

-- For non-scale tones in the Harmony tab
GUI.fonts[7] = {"Calibri", 14}


-- An alternate color for the harmony sliders to fade to
GUI.colors.elm_fill_red = {192, 64, 64, 255}




----------------------------------------
-------------Global stuff---------------
----------------------------------------
local root_arr = {[0] = "C","C#/Db","D","D#/Eb","E","F","F#/Gb","G","G#/Ab","A","A#/Bb","B"}
local oct_str = "9,8,7,6,5,4,3,2,1,0"

local reascale_arr = {{["pre"] = 0, ["name"] = "Major", ["scale"] = {0, 2, 4, 5, 7, 9, 11}, ["size"] = 7}}
local mnu_scale_arr = {[0] = 0, 0, 0}
local reascale_path = ""

local result_arr = {}
local last_range = {}

local cur_wnd = reaper.MIDIEditor_GetActive()
if not cur_wnd then
	reaper.ShowMessageBox( "This script needs an active MIDI editor.", "No MIDI editor found", 0)
	return 0
end
local cur_take = reaper.MIDIEditor_GetTake(cur_wnd)
local snap = reaper.MIDIEditor_GetSetting_int(cur_wnd, "snap_enabled")

-- Are we snapping to the MIDI editor?
local synced = false

-- MIDI defaults
local chan = 0

-- Timestamps for turning notes on and off
local notes_pending = {}
local notes_timing = {}

-- For displaying the warning label
-- Setting to true just it gets checked/drawn on startup
local track_was_armed = true


-- Variables for all of our chord/scale shit
local key = 0
local key_new = 0
local scale_num = 1
local scale = ""
local scale_size = 0
local scale_name = ""
local scale_arr = {}


-- Global value for the divider line so everything else can reference from it
local line_x = 200
local line_y = 22


-- In case we need it?
local ini_file = reaper.get_ini_file()


-- Documentation for the help screen
local help_str =
[[    Some very rough documentation...
 
Scale tab:
    Choose notes in the lower set of boxes to search for scales that include them.
 	
Chord tab:
    Click on buttons to preview
    Shift-click to insert chords
    Double-click any empty space to clear highlighted chords
 	
Harmony tab:
    Right-click on a slider to preview the root + harmonized note
	
	]]

local thread_URL = [[http://forum.cockos.com/showthread.php?t=185358]]
local donate_URL = [[https://www.paypal.me/Lokasenna]]


-- All of our tooltips
local tooltips = {
	[0] = "placeholder for scale recipe",
	[1]  = "To preview notes the track must be armed, monitoring, and receiving input from the VMK (or All Inputs)",
	[2]  = "Kill all MIDI notes being played at the moment",
	[3]  = "Only include search results with at least __ notes, but at most __ notes",
	[4]  = "Play through the current scale (using the MIDI editor's note length)",
	[5]  = "Relative modes of the current scale        Right-click to adjust the scale search instead",
	[6]  = "Parallel modes of the current scale        Right-click to adjust the scale search instead",
	[7]  = "Apply the currently-selected search result",
	[8]  = "Any scales in the current .reascale that fit the notes chosen below",
	[9]  = "Select notes to search for scales that would include them",
	[10] = "Copy the current search result down to the search bar",
	[11] = "Double-click to clear the highlighted chords",
	[12] = "Which set of chords to use:  Basic intervals, triads/tetrads for the diatonic scales, or a slightly extended list",
	[13] = "Which MIDI octave to preview/insert notes in",
	[14] = "Play chords as chords, or ascending/descending arpeggios? (using the MIDI editor's note length",
	[15] = "'Smart': Won't use passing tones for harmonies            'Literal': Will use all notes in the scale",
	[16] = "Apply these settings to the sliders",
	[17] = "Use the slider settings to create harmonized copies of all selected notes",
	[18] = "Play through all selected notes with harmonies",
	[19] = "The current .reascale file",
	[20] = "Use the MIDI editor's current scale? (Requires that Key Snap be active in the MIDI editor)",
	[21] = "MIDI velocity to use for previewing notes",
	[22] = "MIDI octave to use for previewing notes",
	[23] = "Clear all saved settings for this script (this will also exit the script)",
	
}






----------------------------------------
----------Chord Helper stuff------------
----------------------------------------
local notes_str = "5,4,3,2"
local inv_str = "2,1,0"

local chords_str = "Intervals,Basic,More"
local chords_arr = { 
	{
		-- Intervals
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
		-- Basic
		A_maj =		{0, 4, 7},
		B_maj7 =	{0, 4, 7, 11},
		C_min =		{0, 3, 7},
		D_min7 =	{0, 3, 7, 10},
		E__7 =		{0, 4, 7, 10},
		F_dim =		{0, 3, 6},
		G_m7b5 =	{0, 3, 6, 10},
		
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
		H_m7b5 = 	{0, 3, 6, 10},		
		I_aug = 	{0, 4, 8},		
		J_sus2 =	{0, 2, 7},
		K_sus4 =	{0, 5, 7},		
		L_sus9 =	{0, 7, 14},
		M_add9 = 	{0, 4, 7, 14},
	},
}

local chord_set = 1

-- We'll store the current scale's chords here		
local chords_legal = {}

-- Base values for the button array
local btn_template = {line_x + 16, line_y + 102, 48, 20}
local btn_space_h = 8
local btn_space_v = 6

-- Highlight for last-clicked chords
local high_template = {false, false, "elm_fill", 11}

-- Number of buttons in the longest row, for adjusting lbl_clickplay
local most_chords = 0


-- Minimum width for the window = 7 chord buttons + the left panel + a bit
local min_w = (btn_template[3] + btn_space_h) * 7 + 22 + line_x


----------------------------------------
------Anything that needs to be---------
----------forward-declared--------------
----------------------------------------
local search_scales


----------------------------------------
-------------Harmony stuff--------------
----------------------------------------

local harm_arr = {}

-- Center points are 11 for diatonic, 12 for chromatic
local harm_deg_arr = {

	{
		{"up an eleventh", 11},
		{"up a tenth", 10},
		{"up a ninth", 9},
		{"up an eighth", 8},
		{"up a seventh", 7},
		{"up a sixth", 6},
		{"up a fifth", 5},
		{"up a fourth", 4},
		{"up a third", 3},
		{"up a second", 2},
		{"--------", 0},
		{"down a second", -2},
		{"down a third", -3},
		{"down a fourth", -4},
		{"down a fifth", -5},
		{"down a sixth", -6},
		{"down a seventh", -7},
		{"down an eighth", -8},
		{"down a ninth", -9},
		{"down a tenth", -10},
		{"down an eleventh", -11},
	},
	{
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
		{"--------", 0},
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
	},
}


----------------------------------------
------------Global Functions------------
----------------------------------------

-- Clear all current and pending notes
local function notes_off()
	notes_pending = {}
	reaper.Main_OnCommand(40345, 0)
end



local function save_ext()
	
	local name = GUI.name
	
	reaper.SetExtState(name, "current key", key, 1)
	reaper.SetExtState(name, "current scale", scale_num, 1)
		
	reaper.SetExtState(name, "current reascale", reascale_path, 1)
	
	reaper.SetExtState(name, "last tab", GUI.Val("tabs"), 1)
	reaper.SetExtState(name, "MIDI velocity", GUI.Val("sldr_velocity"), 1)
	reaper.SetExtState(name, "MIDI octave", GUI.Val("mnu_octave"), 1)
	
	
	reaper.SetExtState(name, "search size", table.concat({GUI.Val("rng_size")}, ","), 1)
	
	local arr = GUI.Val("chk_search")
	local str = ""
	for i = 1, 12 do
		str = str..(arr[i] and "1" or "0")
	end

	reaper.SetExtState(name, "scale search", str, 1)
	
	reaper.SetExtState(name, "chord set", GUI.Val("mnu_chord_set"), 1)
	reaper.SetExtState(name, "arpeggio", GUI.Val("mnu_chord_arp"), 1)
	
	str = ""
	for i = 0, 11 do
		str = str..","..GUI.Val("sldr_harm_"..i)
	end
	reaper.SetExtState(GUI.name, "harmony sliders", str, 1)

	reaper.SetExtState(GUI.name, "harmony type", GUI.Val("mnu_harm_type"), 1)	
	reaper.SetExtState(GUI.name, "harmony degree", GUI.Val("mnu_harm_deg"), 1)
	
	reaper.SetExtState(GUI.name, "sync with editor", tostring(GUI.Val("chk_follow")[1]), 1)
	
	--reaper.SetExtState(GUI.name, "", , 1)	
	
end


local function load_ext()
	
	local name = GUI.name
	
	key_new = tonumber(reaper.GetExtState(GUI.name, "current key")) or key_new
	scale_num = tonumber(reaper.GetExtState(GUI.name, "current scale")) or scale_num
	reascale_path = reaper.GetExtState(GUI.name, "current reascale") or reascale_path
	
	if not (key_new and scale_num and reascale_path) then return end
			
	GUI.Val("tabs", tonumber(reaper.GetExtState(name, "last tab")))
	
	GUI.Val("sldr_velocity", tonumber(reaper.GetExtState(name, "MIDI velocity")))
	GUI.Val("mnu_octave", tonumber(reaper.GetExtState(name, "MIDI octave")))
	
	local size_a, size_b = string.match(reaper.GetExtState(name, "search size"), "(%d+),(%d+)")

	if size_a and size_b then GUI.Val("rng_size", {tonumber(size_a), tonumber(size_b)}) end
	
	local search = reaper.GetExtState(name, "scale search")

	local arr = {}
	for i = 1, 12 do
		
		local val = string.sub(search, i, i)
		
		arr[i] = (val == "1") and true or false
		
	end
	GUI.Val("chk_search", arr)
	
	GUI.Val("mnu_chord_set", tonumber(reaper.GetExtState(name, "chord set")))
	GUI.Val("mnu_chord_arp", tonumber(reaper.GetExtState(name, "arpeggio")))
	
	local harm_sldrs = reaper.GetExtState(name, "harmony sliders")
	local i = 0
	for val in string.gmatch(harm_sldrs, "[-]*%d+") do

		GUI.Val("sldr_harm_"..i, tonumber(val))
		i = i + 1
	
	end
	
	GUI.Val("mnu_harm_type", tonumber(reaper.GetExtState(name, "harmony type")))

	local sync = reaper.GetExtState(name, "sync with editor")
	GUI.Val("chk_follow", {(sync == "true" and true or false)})

end


local function clear_ext()
	
	local name = GUI.name

	reaper.DeleteExtState(name, "current key", 1)	
	reaper.DeleteExtState(name, "current scale", 1)	
	reaper.DeleteExtState(name, "current reascale", 1)
	reaper.DeleteExtState(name, "last tab", 1)
	reaper.DeleteExtState(name, "MIDI velocity", 1)
	reaper.DeleteExtState(name, "MIDI octave", 1)
	reaper.DeleteExtState(name, "search size", 1)
	reaper.DeleteExtState(name, "scale search", 1)
	reaper.DeleteExtState(name, "chord set", 1)
	reaper.DeleteExtState(name, "arpeggio", 1)
	reaper.DeleteExtState(name, "harmony sliders", 1)
	reaper.DeleteExtState(name, "harmony type", 1)
	reaper.DeleteExtState(name, "harmony degree", 1)
	reaper.DeleteExtState(name, "sync with editor", 1)
	
	GUI.quit = true
	
	-- Tell the .atexit function to bypass save_ext()
	cleared = true
	
end


local function play_MIDI_note(note, velocity, channel, t_start, t_end)
	
	-- If only a note was passed, use some default values
	if not velocity then
		--GUI.Msg("note "..note..", filling in values")
		local QN_length = 60 / reaper.Master_GetTempo()		
		local grid_len, __, note_len = reaper.MIDI_GetGrid(cur_take)
		local len_QN = (note_len ~= 0) and note_len or grid_len
		local user_vel = GUI.Val("sldr_velocity")
		local vel = user_vel > 0 and user_vel or reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_vel") 
		local time = reaper.time_precise()
		--GUI.Msg("vel = "..vel.."  chan = "..chan.."  t = "..time)
		table.insert(notes_pending, {note, vel, chan, time, time + (QN_length * len_QN)})
		--GUI.Msg(table.concat(notes_pending[#notes_pending], " | "))
	else
		table.insert(notes_pending, {note, velocity, channel, t_start, t_end})
	end
	
end


-- Keep track of MIDI notes that are ready to be played or stopped
local function update_MIDI_queue()
	
	-- Check if any pending notes are ready
	local time = reaper.time_precise()
	for idx, val in pairs(notes_pending) do
		--GUI.Msg(val[2])
		if time >= val[4] then
			--GUI.Msg(note.." is ready.  -  "..stamp[1].."  "..(time + stamp[2]))
			
			reaper.StuffMIDIMessage(0, 0x90 + val[3], val[1], val[2])
			notes_timing[val[1]] = val[5]
			notes_pending[idx] = nil
			
		end
	end
		
	-- Check if any active notes are finished
	for note, stamp in pairs(notes_timing) do
		if time >= stamp then
			reaper.StuffMIDIMessage(0, 0x80 + chan, note, 127)
			notes_timing[note] = nil
		
		end
	end
end


-- Let the user know if we're unable to preview notes
local function check_track_armed()
	
	local cur_track = reaper.GetMediaItemTake_Track(cur_take)
	local input = reaper.GetMediaTrackInfo_Value(cur_track, "I_RECINPUT")
	local arm = reaper.GetMediaTrackInfo_Value(cur_track, "I_RECARM")
	local monitor = reaper.GetMediaTrackInfo_Value(cur_track, "I_RECMON")
	
	--GUI.Msg("input = "..input)
	local input_ok = (input >= 6080 and input <= 6096)
					 or
					 (input >= 6112 and input <= 6128)
	
	local track_armed = input_ok and arm == 1 and monitor > 0

	if track_armed and not track_was_armed then 
		GUI.elms.lbl_warning.z = 18 
		GUI.redraw_z[1] = true

	elseif track_was_armed and not track_armed then
		GUI.elms.lbl_warning.z = 1
		GUI.redraw_z[1] = true
	end

	track_was_armed = track_armed
end


--[[	Convert a .reascale string to our array format
	'pass' = true will only parse the first instance of a given scale degree
	i.e. "Blues"           100304450070  --> 100304050070
	Used for 'smart' harmonies so they only harmonize to proper scale tones
]]--
local function convert_reascale(scale, pass)
	
	if not scale or type(scale) == "boolean" then return {0}, 1 end
	
	-- Size = number of non-zero values in the scale
	local __, size = string.gsub(scale, "[^0]", "")
	
	--GUI.Msg(scale)
	
	local scale_arr = {[0] = 0}
	for i = 1, size do

		scale_arr[i] = string.find(scale, "[^0]", scale_arr[i-1] + 1)

	end


	if pass then 
	
		local omit = {}
		for i = size, 1, -1 do
			
			local pos = string.find(scale, "[^0]", scale_arr[i-1] + 1)
			local val = string.sub(scale, pos, pos)
			if omit[val] then table.remove(scale_arr, omit[val]) end
			omit[val] = i
			
		end
	
		size = #scale_arr 
	end
	
	for i = 1, size do
		-- Span three octaves so we can still use extended chords on the 7th degree
		scale_arr[i + size] = scale_arr[i] + 12
		scale_arr[i + (2 * size)] = scale_arr[i] + 24		
	end


	
	-- Adjust the values so that root = 0
	for i = 1, #scale_arr do
		scale_arr[i] = scale_arr[i] - 1
	end
	
	return scale_arr, size
	
end


-- Browse for a new .reascale, parse it, and save it
local function get_reascale(startup)

	local file, err
	if startup then
		file, err = io.open(reascale_path)
		if not file then
			--GUI.Msg("error: "..tostring(err))
			--GUI.Msg("checking .ini")
			__, reascale_path = reaper.BR_Win32_GetPrivateProfileString("reaper", "reascale_fn", "", ini_file)
			--GUI.Msg("got: "..tostring(reascale_path))
			file, err = io.open(reascale_path)
		end
	end
	
	if not startup or not file then
		--GUI.Msg("error: "..tostring(err))
		--GUI.Msg("asking user")
		__, reascale_path = reaper.GetUserFileNameForRead("", "Choose a .reascale file", ".reascale")
		--GUI.Msg("got: "..tostring(reascale_path))
		file, err = io.open(reascale_path)
	end
	
	if file then
		
		-- For our label, trim the path down to just a file name
		local slash_index = string.find(reascale_path, "[/\\][^/\\]*$")
		local file_name = string.sub(reascale_path, slash_index + 1)
		GUI.Val("lbl_reascale", file_name)
		
		reascale_arr = {}
		
		local i = 1
		
		for line in file:lines() do
		
			local line_pre, line_name, line_scale, line_size
			
			-- We don't care about commented lines
			if line:sub(1, 1) ~= "#" then
			
				line_pre = line:match("^(-?%d+)") or ""
				line_name = line:match("\"(.+)\"") or ""
				
				-- End-of-line doesn't always work on Mac
				--str_scale = line:match("%d*$") or ""
				str_scale = line:match("\".+\"%s*(%d+)") or ""
				
				line_scale, line_size = convert_reascale(str_scale)
				pass_scale, pass_size = convert_reascale(str_scale, true)
			
				--GUI.Msg("Norm size = "..line_size.." | "..table.concat(line_scale, " "))
				--GUI.Msg("Pass size = "..pass_size.." | "..table.concat(pass_scale, " "))
			
				if line_pre ~= "" then
					reascale_arr[i] = {["pre"] = tonumber(line_pre), ["name"] = line_name, ["scale"] = line_scale, ["size"] = line_size, ["pscale"] = pass_scale, ["psize"] = pass_size}
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

		if not startup then 
			scale_num = 1 
		else
			scale_num = GUI.clamp(scale_num, 1, #reascale_arr)
		end	
		
		search_scales()
	
	else
	
		reaper.ShowMessageBox( "This script needs a .reascale file to work with.\n\nError: "..tostring(err), "No .reascale found", 0)
		GUI.quit = true
	
	end	
	
end


-- See if the .reascale has any scales that are a mode of the current one
-- up (dir = 1) or down (dir = -1)
-- (key_trans = true) will shift the key as well, i.e. relative modes
local function find_modes(dir, key_trans)
	
	
	local shift = GUI.mouse.cap&8==8
	
	-- Apply mode stuff to the main key/scale
	if not shift then
	
		
		if most_chords == 0 then return 0 end
		
		-- Get current scale pattern
		local temp_scale = {table.unpack(scale_arr, 1, scale_size)}

		-- Shift key to next degree as per dir
		if key_trans then
			local key_adj = dir > 0 and temp_scale[2] or temp_scale[scale_size]
			key_new = (key_new + key_adj) % 12
		end
		
		-- Cycle the scale values in an appropriate direction
		if dir == 1 then

			table.insert(temp_scale, temp_scale[1] + 12)
			table.remove(temp_scale, 1)
			
		else	
		
			table.insert(temp_scale, 1, temp_scale[scale_size] - 12)
			table.remove(temp_scale, scale_size + 1)
				
		end
			
		-- Zero out the scale values w.r.t the new root
		local scale_adj = temp_scale[1]
		for deg, val in pairs(temp_scale) do
			temp_scale[deg] = val - scale_adj		
		end
		

		-- Search reascale_arr for a matching pattern	
		local scale_found = false
		local temp_concat = table.concat(temp_scale, " ")

		for num, arr in ipairs(reascale_arr) do
			--GUI.Msg(num)
			
			if arr.size == scale_size then
				local temp_arr = {table.unpack(arr.scale, 1, scale_size)}
				local arr_concat = table.concat(temp_arr, " ")
				--GUI.Msg(arr_concat)
				if table.concat(temp_arr, " ") == temp_concat then
					--GUI.Msg("num = "..num.." | "..table.concat(temp_arr, " "))
					scale_found = num
					--GUI.Msg("found "..arr.name)
					break
				end
			end
		end
		
		if scale_found then
			scale_num = scale_found
		else

			local arr = reascale_arr[scale_num]
			local name = arr.name
			
			-- If it was already a synthetic scale, just add to the existing prefix
			local suff = arr.suff and (dir + arr.suff) or dir
		
			-- Fill out two extra octaves of the scale, for extended chords
			for i = 1, scale_size do

				-- Span three octaves so we can still use extended chords on the 7th degree
				temp_scale[i + scale_size] = temp_scale[i] + 12
				temp_scale[i + (2 * scale_size)] = temp_scale[i] + 24
				
			end
			
			table.insert(reascale_arr, {["pre"] = "", ["name"] = name, ["scale"] = temp_scale, ["size"] = scale_size, ["suff"] = suff})

			scale_num = #reascale_arr
			-- Add this scale to the end of the menu
			-- Rework at some point to insert next to the original scale?
			--GUI.elms.mnu_scale.optarray = mnu_scale_arr
			--GUI.elms.mnu_scale.numopts = #mnu_scale_arr
			
		end
	
	end
end


-- Play the current scale as an arpeggio. Up (dir = 1) or down (dir = -1)
local function play_scale(dir)
	
	if dir ~= 1 and dir ~= -1 then return 0 end
	
	-- Get note offset for key and octave
	local offset = ( (GUI.elms.mnu_octave.numopts - GUI.Val("mnu_octave") + 1) * 12) + key	
	
	chan = reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_chan")
	
	local user_vel = GUI.Val("sldr_velocity")
	vel = user_vel > 0 and user_vel or reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_vel") 	

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
	
	local time = reaper.time_precise()
	local len = len_QN * QN_length
	
	for key, note in pairs(scale_arr) do
		
		note = offset + note
		
		local time_adj = (arp_start - 1 ) * len_QN * QN_length
		--GUI.Msg("arp = "..arp.." | "..note.." | "..arp_start.." | "..time_adj)
		
		play_MIDI_note(note, vel, chan, time + time_adj, time + time_adj + len)
		--notes_pending[note] = {reaper.time_precise() + time_adj, (len_QN * QN_length)}
		--GUI.Msg("pending note "..note.." @ "..(reaper.time_precise() + time_adj))
		
		arp_start = arp_start + dir
		
	end
	
	
end


-- Update the tooltip label
-- Use force = [tooltip_idx] to, duh, force that tooltip to display
local function update_tooltip(force)

 	if GUI.tooltip_elm or force then
		--GUI.Msg("step 1")
		if force or GUI.IsInside(GUI.tooltip_elm, GUI.mouse.x, GUI.mouse.y) then
			--GUI.Msg("step 2")
			if GUI.elms.lbl_tooltip.z == 18 or GUI.elms.lbl_tooltip.fade_arr or force then
				
				GUI.elms.lbl_tooltip.fade_arr = nil
				
				GUI.font(4)
				local str = tooltips[force or GUI.tooltip_elm.tooltip]
				local str_w, __ = gfx.measurestr(str)
				
				GUI.elms.lbl_tooltip.x = (gfx.w - str_w) / 2
				
				GUI.Val("lbl_tooltip", str)
				GUI.elms.lbl_tooltip.z = 4
			
			end
		elseif not GUI.mouse.down then
			
			--GUI.elms.lbl_tooltip.z = 18
			GUI.elms.lbl_tooltip:fade(2, 4, 18)
			GUI.tooltip_elm = nil	
			--GUI.Msg("setting nil")
			
		end
	end
	
	GUI.forcetooltip = nil
	
end



----------------------------------------
------------Chord Functions-------------
----------------------------------------







----------------------------------------
------------Scale Functions-------------
----------------------------------------

local function update_result_chk()
	
	local reascale_idx, result_scale, result_str
	
	if #result_arr > 0 then
	
		reascale_idx = result_arr[GUI.Val("mnu_result")][2]
		result_scale = reascale_arr[reascale_idx]
		result_str = table.concat(result_scale.scale, " ")

	else
	
		result_str = ""
	
	end
		
	for i = 2, 12 do
		
		if string.find(result_str, " "..(i - 1).." ") then
			GUI.elms.chk_result.optsel[i] = true
		else
			GUI.elms.chk_result.optsel[i] = false
		end
		
	end
	
	GUI.elms.chk_result.optsel[1] = true
	
	
end


--local function search_scales()
search_scales = function()

	-- Get a temporary
	local chk_arr = GUI.Val("chk_search")
	local min, max = GUI.Val("rng_size")
	if min > max then min, max = max, min end

	local search_arr = {}
	
	for i = 1, #chk_arr do
		
		if chk_arr[i] then
			table.insert(search_arr, i - 1)
		end
		
	end
	

	result_arr = {}
	
	for i = 1, #reascale_arr do
		
		local reascale_str = table.concat(reascale_arr[i].scale, " ")
		local matches = true
		

		-- Respect the user's settings for scale sizes
		if reascale_arr[i].size >= min and reascale_arr[i].size <= max then
		
			for j = 2, #search_arr do
				
				--GUI.Msg("checking for "..search_arr[j])
				
				if string.find(reascale_str, " "..search_arr[j].." ") then 
					--GUI.Msg("found "..search_arr[j].." in "..reascale_str)
				
				else
					matches = false 
				end
			
			end
			
			if matches then 		
				
				table.insert(result_arr, {reascale_arr[i].name, i})
				
				--GUI.Msg("found "..reascale_arr[i].name.."!")
				--GUI.Msg("scale = "..table.concat(reascale_arr[i].scale, " "))

			end
			
		end
	end

	--GUI.Msg(#result_arr.." matches")
	
	-- Update the number of results
	local str = #result_arr.." matches:"
	GUI.elms.lbl_result.retval = str


	-- Update the menu of results
	local menu_arr = {}
	if #result_arr > 0 then
		for i = 1, #result_arr do
			table.insert(menu_arr, result_arr[i][1])
			GUI.elms.mnu_result.optarray = menu_arr
			GUI.elms.mnu_result.numopts = #menu_arr
		end
	else
		GUI.elms.mnu_result.optarray = {""}
		GUI.elms.mnu_result.numopts = 0
	end
	
	GUI.Val("mnu_result", 1)
	
	update_result_chk()

	
end


local function search_modes(dir, key_trans)
	
		
	local arr = GUI.Val("chk_search")
	local new_root

	if dir == 1 then
	
		for i = 2, 12 do
			if arr[i] == true then
				new_root = i
				--GUI.Msg("new root = "..i)
				break
			end
		end

		if not new_root then return 0 end

		for i = 1, new_root - 1 do
			
			table.insert(arr, arr[1])
			table.remove(arr, 1)
			
		end
		
	else

		for i = 12, 2, -1 do
			if arr[i] == true then
				new_root = i
				--GUI.Msg("new root = "..i)
				break
			end
		end
		
		if not new_root then return 0 end
		
		for i = 1, 13 - new_root do
			
			table.insert(arr, 1, arr[#arr])
			table.remove(arr, #arr)

		end
		
	end

	if key_trans then
		key_new = (key + new_root - 1) % 12
	end

	for i = 1, 12 do
		GUI.elms.chk_search.optsel[i] = arr[i]
	end

	search_scales()

	
end


local function set_result()
	
	if #result_arr < 1 then
		
		reaper.ShowMessageBox("There are no results for the current search.", "Whoops", 0)
		return
		
	end
	
	scale_num = result_arr[GUI.Val("mnu_result")][2]
	
end


local function copy_result()
	
	for i = 2, 12 do
		GUI.elms.chk_search.optsel[i] = GUI.elms.chk_result.optsel[i]
	end
	
	search_scales()
	
end



----------------------------------------
-----------Harmony Functions------------
----------------------------------------

local function update_harm_arr()
	
	harm_arr = {}
	
	local scale_str = table.concat(reascale_arr[scale_num], " ", 1, size)
	
	for i = 0, 11 do
		
		local pitch_class = (key + i) % 12
		local root_lbl = root_arr[pitch_class]
		local root_dia = string.find(scale_str, " "..pitch_class.." ")
		
		--local harm_lbl = root_arr[
		
		
		
		harm_arr[i] = {}
	
	
	end
	
end

local sldr_template = {	12,		"v", "", -11, 11, 22, 11}

function GUI.Slider:sldr_update_tooltip()

		local root = root_arr[(key + self.i) % 12]
		--local val = 11 - GUI.Val("sldr_harm_"..self.i)
		local val = 11 - self.curstep
		--local harm = val > 0 and root_arr[(key + self.i + val + 12) % 12] or root	
		--local harm = val ~= 0 and root_arr[(key + i + val + 12) % 12] or ""
		self.harm = root_arr[(key + self.i + val + 12) % 12]
		tooltips["sldr_harm_"..self.i] = "Harmonizing "..root.." as "..self.harm.." ("..(val > 0 and "+" or "")..val.." semitones)"	
		update_tooltip(self.tooltip)
		
		-- Force a redraw of the background labels while we're at it
		GUI.redraw_z[13] = true
			
end	


local function init_harm_sldrs()

	-- Clear the existing sliders
	-- ***Should probably save current values beforehand or something***
	for key, value in pairs(GUI.elms) do
		if string.find(key, "sldr_harm") then
			GUI.elms[key] = nil
		end
	end



	local x, y, w, h = GUI.elms.frm_harm_bg.x, GUI.elms.frm_harm_bg.y, GUI.elms.frm_harm_bg.w, GUI.elms.frm_harm_bg.h
	
	local x_adj = w / 11
	
	local z, dir, cap, min, max, steps, def = table.unpack(sldr_template)
	
		
	-- Append all of its methods to update the tooltip
	function sldr_mousedown(self)

		GUI.Slider.onmousedown(self)
		self:sldr_update_tooltip()

	end	
	
	function sldr_drag(self)
		
		GUI.Slider.ondrag(self)
		self:sldr_update_tooltip()
		
	end
	
	function sldr_wheel(self)
		
		GUI.Slider.onwheel(self)
		self:sldr_update_tooltip()
		
	end
	
	function sldr_r_up(self)
		--play_MIDI_note(note, vel, chan, t_start, t_end)
		local offset = ((GUI.elms.mnu_octave.numopts - GUI.Val("mnu_octave") + 1) * 12) + key + self.i		
		play_MIDI_note(offset)

		play_MIDI_note(offset + self.retval)

	end
	
	function sldr_val(self, newval)
		
		local retval = GUI.Slider.val(self, newval)
		if newval then 
			self:sldr_update_tooltip() 
		else
			return retval 
		end
		
	end
	
	
	for i = 0, 11 do
		-- Adjust for the width of the slider so it's properly centered
		-- 						  -v-
		local ix = x + i * x_adj - 4
		local elm = "sldr_harm_"..i
----z, x, y, w, caption, min, max, steps, default, dir, ticks)
		GUI.elms[elm] = GUI.Slider:new(z,	ix, y, h, cap, min, max, steps, def, dir)
		GUI.elms[elm].i = i
		GUI.elms[elm].output = ""
		GUI.elms[elm].tooltip = elm
		GUI.elms[elm].col_fill_a = "elm_fill"
		GUI.elms[elm].col_fill_b = "elm_fill_red"
		
		GUI.elms[elm].onmousedown = sldr_mousedown
		GUI.elms[elm].ondrag = sldr_drag
		GUI.elms[elm].onwheel = sldr_wheel
		GUI.elms[elm].onmouser_up = sldr_r_up
		GUI.elms[elm].val = sldr_val
		
		local root = root_arr[(key + i) % 12]
		tooltips[elm] = "Harmonizing "..root.." as "..root.." (0 semitones)"	
	
	end
	
end


function update_mnu_harm_deg()
	
	local val = GUI.Val("mnu_harm_type")
	local arr = {}
	
	local size = (val == 1) and reascale_arr[scale_num].psize or reascale_arr[scale_num].size
	
	if val < 3 then
		arr = {table.unpack(harm_deg_arr[1], 11 - size + 1, 11 + size - 1)}
		
	else

		arr = harm_deg_arr[2]
	end
	
	GUI.elms.mnu_harm_deg.optarray = arr
	GUI.elms.mnu_harm_deg.numopts = #arr
	GUI.Val("mnu_harm_deg", (val < 3 and size or 12))
	
end


--[[	Returns an appropriate harmony based on the current scale_arr, a given
		MIDI note (or pitch class, with C=0), degree of harmony (i.e. +5 = up a fifth),
		and optional preference for skipping over passing tones (D# in an A Minor Blues)
		
		Call with 'pass' = true to use the current reascale's no-passing-tone version, o
		for smart harmonizing
]]--
local function harmonize_note(MIDI_note, deg, pass)	
	
	-- Subtract "key" so the rest of the math can just work with a scale root of 0
	local pitch_class = (MIDI_note + 12 - key) % 12
	local deg_o
	
	local arr = not pass and scale_arr or reascale_arr[scale_num].pscale	
	local size = not pass and scale_size or reascale_arr[scale_num].psize
	
	-- Intervals are written one more than the actual gap
	-- i.e. a fifth is four scale degrees up
	deg = deg > 0 and deg - 1 or deg + 1
	
	
	for j = 1, size do
		if pitch_class == arr[j] then
			deg_o = j
			break
		end
	end

	
	if deg_o then

		local deg_new = deg_o + deg
		local oct_adj = deg > 0 
				and (math.modf((deg_new - 1) / size)) 
				or (math.modf(deg_new / size))
		if deg_new < 1 then
			oct_adj = oct_adj - 1
		end
		
		-- Convert the degree to a value within the scale
		deg_new =  (deg_new - 1) % size + 1
		
		local note_adj = arr[deg_new] - arr[deg_o] + 12 * oct_adj
		
		return MIDI_note + note_adj
	
	else return -1
	
	end	
	
end



function set_harm_sldrs()
	
	local type = GUI.Val("mnu_harm_type")
	local deg_set = type < 3 and 1 or 2
	local deg = GUI.elms.mnu_harm_deg.optarray[GUI.Val("mnu_harm_deg")][2]
	
	local sldr
	
	local pass = (type == 1)
	
	for i = 0, 11 do
		
		sldr = "sldr_harm_"..i
		
		-- Chromatic
		if type == 3 then
			
			--GUI.Msg(deg)
			GUI.Val(sldr, 11 - deg)

		else
				
			local note = harmonize_note(key + i + 24, deg, pass)
			local val = note ~= -1
						and 11 - ((note - i + 24) % 12) 
							+ (deg < 0 and 12 or 0)
						or 11
	
			GUI.Val(sldr, val)
		end
		
		--GUI.elms[sldr]:sldr_update_tooltip()
		
	end	
	
end


function get_sel_notes()
	
	local sel_notes = {}

	local cur_note = -2
	while cur_note ~= -1 do
		
		cur_note = reaper.MIDI_EnumSelNotes(cur_take, cur_note)
		if cur_note == -1 then break end
		cur_arr = {reaper.MIDI_GetNote(cur_take, cur_note)}
		table.remove(cur_arr, 1)
		table.insert(sel_notes, cur_arr)
		
	end

	return sel_notes
	
end


-- Duplicate all of the selected notes, using the harmony sliders
-- to determine the new notes' pitches.
function harm_sel_notes()
	
	local sel_notes = get_sel_notes()	
	
	reaper.Undo_BeginBlock()
	
	if #sel_notes == 0 then
		reaper.ShowMessageBox("Couldn't find any selected notes.", "whoops", 0)
		return
	end
	
	reaper.MIDI_SelectAll(cur_take, false)
	
	for i = 1, #sel_notes do
	
		local pitch = sel_notes[i][6] 
		local new_pitch = pitch + 11 - GUI.Val("sldr_harm_"..((pitch + 12) % 12))
		
		if new_pitch ~= pitch then
			local sel, mute, start, _end, chan, pitch, vel = table.unpack(sel_notes[i])
			reaper.MIDI_InsertNote(cur_take, sel, mute, start, _end, chan, new_pitch, vel, true)
		end
	end
	
	reaper.MIDI_Sort(cur_take)
	
	reaper.Undo_EndBlock("Harmonize selected notes", -1)
end


function prev_sel_notes()
	
	-- Get all selected notes
	local sel_notes = get_sel_notes()
	local add_notes = {}

	if #sel_notes == 0 then
		reaper.ShowMessageBox("Couldn't find any selected notes.", "whoops", 0)
		return
	end

	for i = 1, #sel_notes do
	
		local pitch = sel_notes[i][6] 
		local new_pitch = pitch + GUI.Val("sldr_harm_"..((pitch + 12) % 12))
		
		if new_pitch ~= pitch then
			local sel, mute, start, _end, chan, pitch, vel = table.unpack(sel_notes[i])
			table.insert(sel_notes, {sel, mute, start, _end, chan, new_pitch, vel})
		end
	end	

	-- Use first note's start time as a 0 reference
	local ref_ppq = sel_notes[1][3]
	local ref_time = reaper.MIDI_GetProjTimeFromPPQPos(cur_take, ref_ppq)

	local time = reaper.time_precise()

	for i = 1, #sel_notes do
		local __, __, start, _end, chan, note, vel = table.unpack(sel_notes[i])
		-- Convert start and end to time
		local start_time = reaper.MIDI_GetProjTimeFromPPQPos(cur_take, start) - ref_time + time
		local end_time = reaper.MIDI_GetProjTimeFromPPQPos(cur_take, _end) - ref_time + time

		play_MIDI_note(note, vel, chan, start_time, end_time)
	end
	
end


----------------------------------------
--------------GUI Elements--------------
----------------------------------------

--[[	Classes and parameters
	(see comments in LS GUI.lua for more thorough documentation)

	Tabframe	z	x y w h caption		tabs	pad
	Frame		z	x y w h[shadow		fill	color	round]
	Label		z	x y		caption		shadow	font
	Button		z	x y w h caption		func	...
	Radio		z	x y w h caption 	opts	pad
	Checklist	z	x y w h caption 	opts	dir		pad
	Knob		z	x y w	caption 	min 	max		steps	default		ticks
	Slider		z	x y w	caption 	min 	max 	steps 	default		dir		ticks

	Range		z	x y w	caption		min		max		steps 	default_a 	default_b
	Textbox		z	x y w h	caption		pad
	Menubox		z	x y w h caption		opts	pad



	z_sets are defined like so:

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

GUI.elms = {

	---- Global ----


	tabs = GUI.Tabframe:new(			19, 0, 0, 64, line_y, "", "Scales,Chords,Harmony,Options,Help", 8),

	lbl_warning = GUI.Label:new(		18, 416, 2, "Unable to preview notes", 0, 5),
	lbl_tooltip = GUI.Label:new(		18, 0, line_y + 50, "", 0, 4),
	
	frm_h1 = GUI.Frame:new(				4,	0, line_y + 44, 2000, 2, true, true),
	frm_h2 = GUI.Frame:new(				5,	0, line_y + 70, 2000, 2, true, true),
	frm_v = GUI.Frame:new(				3,	line_x, line_y + 72, 2, 2000, true, true),	
	
	frm_tooltip = GUI.Frame:new(		5,	0, line_y + 46, 2000, 24, false, true, "elm_bg", 0),	
	
	--lbl_construction = GUI.Label:new(	3,	300, line_y + 6, "---under construction---", 1, 1),
	
	---- General scale stuff, s.b.v on tabs 1,2,3 ----

	lbl_key = GUI.Label:new(			5,	16, line_y + 6, "C", true, 1),
	lbl_scale = GUI.Label:new(			5,	48, line_y + 6, "blah", true, 1),
	mnu_key = GUI.Menubox:new(			5,	0, -24, 0, 0, "", "C,C#/Db,D,D#/Eb,E,F,F#/Gb,G,G#/Ab,A,A#/Bb,B", 0),
	mnu_scale = GUI.Menubox:new(		5,	0, -24, 0, 0, "", "-no scale-", 0),

	
	---- Tab 1: Scales ----
	
	rng_size = GUI.Range:new(			9,	32, line_y + 105, line_x - 64, "Limit size of results to:", 3, 12, 9, 2, 9),


	lbl_play_scale = GUI.Label:new(		9,	63, line_y + 228, "Preview scale", 1, 3),
	btn_play_up = GUI.Button:new(		9,	152, line_y + 226, 20, 20, "↑", play_scale, 1),
	btn_play_dn = GUI.Button:new(		9,	28, line_y + 226, 20, 20, "↓", play_scale, -1),
	
	lbl_modes_key = GUI.Label:new(		9,	59, line_y + 312, "Relative modes", 1, 3),
	btn_modes_key_dn = GUI.Button:new(	9,	28, line_y + 310, 20, 20, "↓", find_modes, -1, true),
	btn_modes_key_up = GUI.Button:new(	9,	152, line_y + 310, 20, 20, "↑", find_modes, 1, true),
	
	lbl_modes_scale = GUI.Label:new(	9,	59, line_y + 338, "Parallel modes", 1, 3),
	btn_modes_scale_dn = GUI.Button:new(9,	28, line_y + 336, 20, 20, "↓", find_modes, -1),
	btn_modes_scale_up = GUI.Button:new(9,	152, line_y + 336, 20, 20, "↑", find_modes, 1),		


	
	btn_set = GUI.Button:new(			9,	line_x + 64, line_y + 86, 64, 20, "↑   Set   ↑", set_result),
	
	frm_result = GUI.Frame:new(			10, line_x + 10, line_y + 120, 394, 88, false, true, "tab_bg", 4),
	lbl_result = GUI.Label:new(			9,	line_x + 22, line_y + 128, "0 matches:", 1, 2),
	mnu_result = GUI.Menubox:new(		9,	line_x + 128, line_y + 129, 256, 20, "", "scale A,scale B,scale C", 4),
	chk_result = GUI.Checklist:new(		9,	line_x + 22, line_y + 178, nil, nil, "", table.concat(root_arr, ",", 0), "h", 12),

	frm_search = GUI.Frame:new(			10, line_x + 10, line_y + 254, 394, 86, false, true, "tab_bg", 4),
	lbl_search = GUI.Label:new(			9,	line_x + 22, line_y + 260, "Search:", 1, 2),
	chk_search = GUI.Checklist:new(		9,	line_x + 22, line_y + 310, nil, nil, "", table.concat(root_arr, ",", 0), "h", 12),
	
	btn_copy = GUI.Button:new(			9,	line_x + 64, line_y + 220, 64, 20, "↓ Copy ↓", copy_result),



	---- Tab 2: Chords ----

	bg = GUI.Frame:new(					8,	0, line_y, GUI.w, GUI.h, false, false, "none", 0),

	mnu_chord_set =	GUI.Menubox:new(	7,	88, line_y + 96, 100, 20, "Chord Set:", chords_str, 4),
	mnu_chord_arp =	GUI.Menubox:new(   	7,	88, line_y + 148, 100, 20, "Arpeggio:", "None,Ascending,Descending", 4),
	
	--mnu_num_notes = GUI.Menubox:new(	84, 48, 128, 20, "Notes", notes_str, 4),
	--mnu_inversion =	GUI.Menubox:new(	88, 220, 100, 20, "Inversion", inv_str, 4),

	
	
	---- Tab 3: Harmony ----

	frm_harm_bg = GUI.Frame:new(		13, line_x + 40, line_y + 96, 352, 304, false, false, "wnd_bg", 4),

	--lbl_harm_harm = GUI.Label:new(		11, line_x + 168, line_y + 80, "Harmony", 1, 2),
	--lbl_harm_root = GUI.Label:new(		11, line_x + 184, line_y + 376, "Root", 1, 2),

	
	--mnu_behavior = GUI.Menubox:new(		11, 128, line_y + 88, 64, 20, "
	mnu_harm_type = GUI.Menubox:new(	12, 48, line_y + 88, 140, 20, "Type:", "Diatonic (smart),Diatonic (literal),Chromatic", 4),	
	mnu_harm_deg = GUI.Menubox:new(		12, 12, line_y + 114, 176, 20, "", "", 4),	
	--mnu_harm_oct = GUI.Menubox:new(		12, 64, line_y + 140, 128, 20, "Octave:", "+2,+1,-,-1,-2", 4),	
	btn_harm_set = GUI.Button:new(		12,	64, line_y + 166, 72, 20, "Set  →", set_harm_sldrs),
	
	btn_harm_sel_notes = GUI.Button:new(12,	16, line_y + 220, 168, 20, "Harmonize selected notes", harm_sel_notes),
	
	btn_prev_sel_notes = GUI.Button:new(12, 16, line_y + 246, 168, 20, "Preview w/ selected notes", prev_sel_notes),
	
	
	
	
		
	---- Tab 4: Options ----

	lbl_reascale = GUI.Label:new(		15,	16, line_y + 82, "( no .reascale loaded )", 0, 6),
	chk_follow =	GUI.Checklist:new(	15,	20, line_y + 128, nil, nil, "", "Use MIDI editor's key snap scale\n       (Disables some options)", "v", 0),

	lbl_velocity = GUI.Label:new(		15,	28, line_y + 192, "Velocity:", 1, 3),
	sldr_velocity = GUI.Slider:new(		15,	83, line_y + 196, 92, "", 0, 127, 127, 1, "h"),


	mnu_octave = GUI.Menubox:new(		15,	72, line_y + 242, 48, 20, "Octave:", oct_str, 4),

	btn_notes_off = GUI.Button:new(		15,	48, line_y + 348, 96, 20, "All notes off", notes_off),	
	
	btn_clear_ext = GUI.Button:new(		15, 48, line_y + 316, 96, 20, "Clear settings", clear_ext),

	--btn_test_fade = GUI.Button:new(		15,	8, line_y + 400, 96, 32, "Fade test", fade_label),
	--lbl_test_fade = GUI.Label:new(		18,	200, 200, "Fading...", 0, 1),


	---- Tab 5: Help ----

	--frm_help_bg = GUI.Frame:new(		4,	0, 0, 2000, 2000, false, true, "shadow", 0),
	--frm_help_wnd = GUI.Frame:new(		3,	32, 32, 448, 256, true, true, "wnd_bg", 4),
	lbl_help = GUI.Label:new(			17,	44, 40, "Lokasenna's Theory Helper  -  Documentation", 0, 2),
	lbl_help_str = GUI.Label:new(		17,	40, 68, help_str, 0, 3),
	--frm_help_over = GUI.Frame:new(		1,	0, 0, 2000, 2000, false, false, "none", 0),
	
	
	btn_thread = GUI.Button:new(		17,	48, 360, 96, 22, "Forum thread", GUI.open_file, thread_URL),
	btn_donate = GUI.Button:new(		17,	160, 360, 80, 22, "Donate", GUI.open_file, donate_URL),	
	
}

-- Make ourselves a bunch of sliders, the easy way
init_harm_sldrs()	

-- For the note label bar in the Harmony tab; freezing lets us 
-- work with the sliders beneath it instead
--GUI.elms_freeze = {[11] = true}

-- Use z = 18 to hide something, f.e. the "unable to preview" warning.
GUI.elms_hide = {[18] = true}

-- z-layers will be active for any set they're listed in
GUI.elms.tabs:update_sets(
	{
	[1] = {3, 	4, 5, 6,	9, 10},
	[2] = {3,	4, 5, 6,	7, 8},
	[3] = {3, 	4, 5, 6,	11, 12, 13},
	[4] = {		4, 5, 6,	15, 16},
	[5] = {					17},
	}
)

----------------------------------------
-------------Initial Values-------------
----------------------------------------

--GUI.Val("mnu_num_notes", 3)
--GUI.Val("mnu_inversion", 3)
GUI.Val("mnu_octave", 6)
GUI.Val("mnu_chord_set", 3)
GUI.Val("sldr_velocity", 127)

GUI.elms.tabs.font_A = 6

GUI.elms.lbl_warning.color = "red"

--GUI.elms.lbl_construction.color = "elm_fill"


GUI.elms.chk_search.optsel[1] = true

GUI.elms.chk_result.f_color = "txt"
GUI.elms.chk_result.font = 3
GUI.elms.chk_search.font = 3

GUI.elms.btn_modes_key_up.r_func, GUI.elms.btn_modes_key_up.r_params = search_modes, {1, true}
GUI.elms.btn_modes_key_dn.r_func, GUI.elms.btn_modes_key_dn.r_params = search_modes, {-1, true}
GUI.elms.btn_modes_scale_up.r_func, GUI.elms.btn_modes_scale_up.r_params = search_modes, {1}
GUI.elms.btn_modes_scale_dn.r_func, GUI.elms.btn_modes_scale_dn.r_params = search_modes, {-1}

GUI.Val("mnu_harm_type", 3)
update_mnu_harm_deg()
GUI.Val("mnu_harm_deg", 12)


----------------------------------------
--------Assign Element Tooltips---------
----------------------------------------

GUI.elms.lbl_key.tooltip = 0
GUI.elms.lbl_scale.tooltip = 0

GUI.elms.lbl_warning.tooltip = 1

GUI.elms.btn_notes_off.tooltip = 2

GUI.elms.rng_size.tooltip = 3

GUI.elms.lbl_play_scale.tooltip = 4
GUI.elms.btn_play_up.tooltip = 4
GUI.elms.btn_play_dn.tooltip = 4

GUI.elms.lbl_modes_key.tooltip = 5
GUI.elms.btn_modes_key_dn.tooltip = 5
GUI.elms.btn_modes_key_up.tooltip= 5

GUI.elms.lbl_modes_scale.tooltip = 6
GUI.elms.btn_modes_scale_dn.tooltip = 6
GUI.elms.btn_modes_scale_up.tooltip = 6

GUI.elms.btn_set.tooltip = 7

GUI.elms.frm_result.tooltip = 8
GUI.elms.lbl_result.tooltip = 8
GUI.elms.mnu_result.tooltip = 8
GUI.elms.chk_result.tooltip = 8

GUI.elms.frm_search.tooltip = 9
GUI.elms.lbl_search.tooltip = 9
GUI.elms.chk_search.tooltip = 9

GUI.elms.btn_copy.tooltip = 10

--GUI.elms.bg.tooltip = 11
GUI.elms.mnu_chord_set.tooltip = 12
GUI.elms.mnu_octave.tooltip = 13
GUI.elms.mnu_chord_arp.tooltip = 14

GUI.elms.mnu_harm_type.tooltip = 15
GUI.elms.mnu_harm_deg.tooltip = 15
GUI.elms.btn_harm_set.tooltip = 16

GUI.elms.btn_harm_sel_notes.tooltip = 17
GUI.elms.btn_prev_sel_notes.tooltip = 18

GUI.elms.lbl_reascale.tooltip = 19
GUI.elms.chk_follow.tooltip = 20
GUI.elms.sldr_velocity.tooltip = 21
GUI.elms.mnu_octave.tooltip = 22
GUI.elms.btn_clear_ext.tooltip = 23


----------------------------------------
------------Method Overrides------------
----------------------------------------


-- Clear all chord highlights
function GUI.elms.bg:ondoubleclick()

	for key, val in pairs(GUI.elms) do
		if string.find(key, "high_") then
			GUI.elms[key].z = -1
		end
	end	

end


-- Redirecting label clicks to a hidden dropdown menu
-- (Just a lazy way of giving the label more functionality)

function GUI.elms.lbl_key:onmouseup() 
	
	if GUI.Val("chk_follow")[1] == true and keysnap == 1 then return end
		
	GUI.elms.mnu_key:onmouseup()
	
	-- Array indexes don't like being given a decimal value	
	key_new = math.floor(GUI.elms.mnu_key.retval) - 1

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


-- Keep the user from interacting with search results directly
function GUI.elms.chk_result:onmouseup() return 0 end



function GUI.elms.chk_search:onmouseup()
	
	GUI.Checklist.onmouseup(self)
	
	-- We always want to have the root
	self.optsel[1] = true
	
	search_scales()
end

function GUI.elms.mnu_result:onmouseup()
	GUI.Menubox.onmouseup(self)
	update_result_chk()
end

function GUI.elms.mnu_result:onwheel()
	GUI.Menubox.onwheel(self)
	update_result_chk()
end



-- If the first Harmony menu is changed, update the options for the second one
function GUI.elms.mnu_harm_type:onmouseup()
	
	GUI.Menubox.onmouseup(self)
	update_mnu_harm_deg()
	
end

function GUI.elms.mnu_harm_type:onwheel()
	
	GUI.Menubox.onwheel(self)
	update_mnu_harm_deg()
	
end


-- Rewriting frm_harm_bg's :Draw method to give us
-- the background grid and labels
function GUI.elms.frm_harm_bg:draw()
		
	GUI.Frame.draw(self)
	
	local x, y, w, h = self.x, self.y, self.w, self.h
	-- Compensate for sliders being drawn slightly shorter
	--								-v-
	local x_adj, y_adj = w / 11, (h - 8) / 22
	
	local harm_arr = harm_arr
	
	for i = 0, 22 do

	-- Compensate for sliders being drawn slightly shorter
	--									-v-
		local ix, iy = x + i * x_adj, y + 4 + i * y_adj
		
		-- Draw a gridline at y + (i * y_adj)
		GUI.color("elm_frame")
		gfx.line(x, iy, x + w, iy)
		
	
		GUI.color("txt")
		-- Draw a semitone label on the left
		GUI.font(4)
		local str_w, str_h = gfx.measurestr(11 - i)
		gfx.x, gfx.y = x - str_w - 12, iy - str_h / 2
		gfx.drawstr(11 - i)		
		
		if i <= 11 then
			
			-- Draw a scale degree at x + (i * x_adj)
			GUI.font(3)
			local root = root_arr[(key + i) % 12]
			str_w, str_h = gfx.measurestr(root)
			gfx.x, gfx.y = ix - str_w / 2, y + h + 4
			gfx.drawstr(root)
			
			-- Draw a harmony degree at x + (i * x_adj)

			GUI.font(3)

			local val = 11 - GUI.Val("sldr_harm_"..i)
			--GUI.Msg("sldr "..i.." val = "..val)
			local harm = val ~= 0 and root_arr[(key + i + val + 12) % 12] or ""
			str_w, str_h = gfx.measurestr(harm)
			gfx.x, gfx.y = ix - str_w / 2, y - str_h - 4
			gfx.drawstr(harm)
		
		end
	end
	
	
end


function GUI.elms.frm_harm_bg:get_sldr(ox)
	
	local sldr = (((ox or GUI.mouse.x) - self.x) / self.w )
	sldr = math.floor(sldr * 11 + 0.5)
	return "sldr_harm_"..sldr
	
end


-- Getting frm_harm_bg to pass any mouse stuff on to the nearest slider
function GUI.elms.frm_harm_bg:onmousedown()

	GUI.elms[self:get_sldr()]:onmousedown()

end

function GUI.elms.frm_harm_bg:ondrag()
	
	GUI.elms[self:get_sldr(GUI.mouse.ox)]:ondrag()
	
end

function GUI.elms.frm_harm_bg:onwheel()
	
	GUI.elms[self:get_sldr()]:onwheel()
	
end

function GUI.elms.frm_harm_bg:onmouseover()
	
	local sldr = self:get_sldr()
	GUI.elms[sldr]:onmouseover()
	GUI.forcetooltip = sldr
	--GUI.forcetooltip = true

end

function GUI.elms.frm_harm_bg:onmouser_up()

	GUI.elms[self:get_sldr()]:onmouser_up()
	
end

----------------------------------------
------More Chord Helper Functions-------
----------------------------------------

-- For the button array
-- On click, play/insert the chord's notes
local function btn_click(deg, chord, btn) 
	
	-- If Shift+click then insert notes
	-- If normal click then play notes

	local btn = GUI.elms[btn]
	local high = {table.unpack(high_template)}
	local high_name = "high_"..deg

	-- Update this column's last-clicked chord highlight
	GUI.elms[high_name] = GUI.Frame:new(8, btn.x - 3, btn.y - 3, btn.w + 6, btn.h + 6, high[1], high[2], high[3], high[4])
	
	_=dm and Msg("high_name = "..tostring(high_name))

	
	-- Get cursor position
	local cursor_pos = reaper.GetCursorPosition()
	local cursor_ppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, cursor_pos)
	local cursor_QN = reaper.MIDI_GetProjQNFromPPQPos(cur_take, cursor_ppq)

	-- Get note length ***IN QN***
	local grid_len, __, note_len = reaper.MIDI_GetGrid(cur_take)
	local len_QN = (note_len ~= 0) and note_len or grid_len
	
	local end_ppq = reaper.MIDI_GetPPQPosFromProjQN(cur_take, cursor_QN + len_QN)
	
	local len_ppq = end_ppq - cursor_ppq
	
	-- Get note offset for key and octave
	local offset = ( (GUI.elms.mnu_octave.numopts - GUI.Val("mnu_octave") + 1) * 12) + key
	chan = reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_chan")
	
	local user_vel = GUI.Val("sldr_velocity")
	vel = user_vel > 0 and user_vel or reaper.MIDIEditor_GetSetting_int(cur_wnd, "default_note_vel") 
	
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
	if shift then 
		reaper.MIDI_SelectAll(cur_take, 0)
		reaper.Undo_BeginBlock()	
	end
	
	local time = reaper.time_precise()
	
	for name, note in ipairs(chords_legal[deg][chord]) do

		note = offset + scale_arr[deg] + note
		
		if shift then
			local note_ppq_a, note_ppq_b = cursor_ppq, end_ppq
			if arp_dir ~= 0 then
				note_ppq_a = note_ppq_a + (arp_start * len_ppq)
				note_ppq_b = note_ppq_b + (arp_start * len_ppq)
			end	
				
			--local note_ppq_a = arp_dir == 0 and cursor_ppq or	(cursor_ppq + (arp_start * len_ppq))
			--local note_ppq_b = arp_dir == 0 and end_ppq or		(note_ppq_a + len_ppq)
			reaper.MIDI_InsertNote(cur_take, 1, 0, note_ppq_a, note_ppq_b, chan, note, vel, 1)
			
		end
		
		local len = len_QN * QN_length
		local time_adj = arp_start * len
		arp_start = arp_start + arp_dir
		--GUI.Msg("arp = "..arp.." | "..note.." | "..arp_start.." | "..time_adj)
		play_MIDI_note(note, vel, chan, time + time_adj, time + time_adj + len)		
		--notes_pending[note] = {reaper.time_precise() + time_adj, (len_QN * QN_length)}
		
	end
	
	reaper.MIDI_Sort(cur_take)
	
	-- Move the cursor over if we inserted notes/arps
	if shift then 
		local num_nudge = arp == 1 and 1 or #chords_legal[deg][chord]
		local amt_nudge = num_nudge * len_QN / 4
		reaper.ApplyNudge(0, 0, 6, 15, amt_nudge, 0, 0) 
		reaper.Undo_EndBlock("Inserted notes from Chord Helper", -1)		
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
	
	tooltips.btn_arr = {}
	
	-- Create new buttons
	local x, y, w, h, func = table.unpack(btn_template)
	
	for i = 1, scale_size do
		
		local x_offset = (w + btn_space_h) * (i - 1)
	
		-- Create a label for the column
		GUI.font(2)

		local lbl_caption = root_arr[(scale_arr[i] + key) % 12]
		local lbl_w, lbl_h = gfx.measurestr(lbl_caption)
		local lbl_x = x + x_offset + ((w - lbl_w) / 2)				
		
		GUI.elms["lbl_chords_"..i] = GUI.Label:new(7, lbl_x, y - lbl_h - 4, lbl_caption, 1, 2)
		
		local row = 1
		local num_chords = 0
		
		for name, __ in GUI.kpairs(chords_legal[i]) do
			
			local caption = string.match(name, "%u_+(.+)")
			
			local y_offset = (h + btn_space_v) * (row - 1)
			row = row + 1
			
			local btn_name = "btn_chords_"..i.."_"..name
			
			GUI.elms[btn_name] = GUI.Button:new(7, x + x_offset, y + y_offset, w, h, caption, btn_click, i, name, btn_name)
			
			
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
			
			tooltips[btn_name] = tip_str..tip_str2
			
			GUI.elms[btn_name].tooltip = btn_name


			num_chords = num_chords + 1
			
		end
		
		most_chords = math.max(num_chords,most_chords)

	end

	if most_chords == 0 then
		GUI.elms.lbl_no_chords = GUI.Label:new(7, line_x + 48, 150, " -- no legal chords -- ", 0, 3)
	end	
	
end







----------------------------------------
---------More Harmony Functions---------
----------------------------------------



----------------------------------------
---------------The Big One--------------
----------------------------------------

local function Main()
	
	
	-- See if the MIDI editor is still open
	if not reaper.MIDIEditor_GetActive() then
		GUI.quit = true
	end

	if GUI.quit == true then return 0 end

	update_MIDI_queue()

	check_track_armed()

	update_tooltip(GUI.forcetooltip)

	-- Update the Velocity slider's value readout if necessary
	GUI.elms.sldr_velocity.output = GUI.Val("sldr_velocity") == 0 and "Use editor's velocity" or nil


	-- Scale tab - Has the scale size slider been changed?
	local cur_range_A, cur_range_B = GUI.Val("rng_size")
	if cur_range_A ~= last_range_A or cur_range_B ~= last_range_B then
		last_range_A = cur_range_A
		last_range_B = cur_range_B

		search_scales()
	end

		
	-- See if the key, scale, or chord set have changed
	local cur_key, cur_name, cur_scale, cur_size, cur_chords = "", "", "", "", GUI.Val("mnu_chord_set")
	
	keysnap = reaper.MIDIEditor_GetSetting_int(cur_wnd, "scale_enabled")
	local cur_synced = (GUI.Val("chk_follow")[1] == true and keysnap == 1)
	
	if cur_synced then
		__, cur_key, __, cur_name = reaper.MIDI_GetScale(cur_take, 0, 0, "")
		__, scale_str = reaper.MIDIEditor_GetSetting_str(cur_wnd, "scale", "")
		cur_scale, cur_size = convert_reascale(scale_str)
	else
		cur_key = key_new
		--GUI.Msg(scale_num.." / "..#reascale_arr)
		if scale_num > #reascale_arr then scale_num = 1 end
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
	
	
	if key ~= cur_key 
	or table.concat(scale_arr, " ") ~= table.concat(cur_scale, " ") 
	or chords ~= cur_chords then
		
		key = cur_key
		scale_name = cur_name
		chords = cur_chords

		if synced then
			scale_arr, scale_size = cur_scale, cur_size
			-- scale_arr, scale_size = convert_reascale(cur_scale)
		else
			scale_arr, scale_size = reascale_arr[scale_num].scale, reascale_arr[scale_num].size
		end

		-- Clear last-clicked highlights
		for key, value in pairs(GUI.elms) do
			if string.find(key, "high_") then
				GUI.elms[key] = nil
			end
		end

		-- Grabbing this a little early because the tooltip needs it
		local suff = reascale_arr[scale_num].suff	
		
		-- Update the key/scale label's caption and tooltip
		GUI.Val("lbl_key", root_arr[key])
		GUI.Val("lbl_scale", scale_name)
		
		-- The note labels in the Scale tab while we're at it
		for i = 1, 12 do
			GUI.elms.chk_result.optarray[i] = root_arr[(key + (i - 1)) % 12]
			GUI.elms.chk_search.optarray[i] = root_arr[(key + (i - 1)) % 12]
		end

		-- Keep our list of scale tones, passing tones, etc up to date
		update_harm_arr()

		-- Adjust the scale label and suffix to follow the key label's width
		GUI.font(GUI.elms.lbl_key.font)
		GUI.elms.lbl_key.w, GUI.elms.lbl_key.h = gfx.measurestr(GUI.Val("lbl_key").." ")	
		GUI.elms.lbl_scale.x = GUI.elms.lbl_key.x + GUI.elms.lbl_key.w
		GUI.elms.lbl_scale.w, GUI.elms.lbl_scale.h = gfx.measurestr(GUI.Val("lbl_scale"))

		if suff then
			if suff > 0 then suff = "+"..suff end
			local x, y = GUI.elms.lbl_scale.x + GUI.elms.lbl_scale.w + 4, GUI.elms.lbl_scale.y
			GUI.elms.scale_suff = GUI.Label:new(5, x, y, suff, 0, 2)
		else
			GUI.elms.scale_suff = nil
		end
	
		tooltips[0] = root_arr[key].." "..scale_name..(GUI.Val("scale_suff") or "").." scale:  R "..table.concat(scale_arr, " ", 2, scale_size)	
		

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
					for j = 1, #scale_arr do
						
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
			GUI.redraw_z[0] = true
			GUI.cur_w, GUI.cur_h = new_w, new_h
			
			GUI.resized = true
		end
	end




	-- If the mouse is over the key, scale, or reascale labels,
	-- highlight it so they can tell it's clickable
	-- This should be wrapped into Label:draw using self.mouseover and adding a col_A, col_B
	local x, y = GUI.mouse.x, GUI.mouse.y
	if not synced then
		
		GUI.elms.lbl_key.color = "txt"
		GUI.elms.lbl_scale.color = "txt"
		GUI.elms.lbl_reascale.color = "txt"
		
		GUI.elms.lbl_key.shadow = 0
		GUI.elms.lbl_scale.shadow = 0
		GUI.elms.lbl_reascale.shadow = 0
		
		if not GUI.elms_hide[GUI.elms.lbl_key.z] then
			if GUI.IsInside(GUI.elms.lbl_key, x, y) then
				GUI.elms.lbl_key.color = "white"
				GUI.elms.lbl_key.shadow = 1
			elseif GUI.IsInside(GUI.elms.lbl_scale, x, y) then
				GUI.elms.lbl_scale.color = "white"
				GUI.elms.lbl_scale.shadow = 1
			end
		elseif GUI.IsInside(GUI.elms.lbl_reascale, x, y) then
			GUI.elms.lbl_reascale.color = "white"
			GUI.elms.lbl_reascale.shadow = 1
		end
	end
	
	-- See if the window has been resized by the user
	-- Duplicating code from the "scale was changed" structure, there must be a better way
	if GUI.resized then
		
		local min_h_a = btn_template[2] + (most_chords * (btn_template[4] + btn_space_v)) + 26
		local min_h_b = GUI.elms.frm_harm_bg.y + GUI.elms.frm_harm_bg.h + 48
		
		local min_h = math.max(min_h_a, min_h_b)
		
		if GUI.cur_w < min_w or GUI.cur_h < min_h then
			local new_w = math.max(GUI.cur_w, min_w)
			local new_h = math.max(GUI.cur_h, min_h)
			local __,x,y,w,h = gfx.dock(-1,0,0,0,0)
			gfx.quit()
			gfx.init(GUI.name, new_w, new_h, 0, x, y)
			GUI.redraw_z[0] = true
		end
		
		GUI.elms.bg.w, GUI.elms.bg.h = gfx.w, gfx.h
		
	
		--[[
		Reset mouse variables
		Without this, the window is reset before the mouse registers as Up,
		so all mouse commands get frozen until the UI is stretched to put
		chk_follow back where it was and the mouse is clicked on it.
		]]--
		GUI.mouse.down = false
		GUI.mouse.ox, GUI.mouse.oy = -1, -1
		GUI.mouse.lx, GUI.mouse.ly = -1, -1
		GUI.mouse.uptime = reaper.time_precise()
				

		-- Center the instruction and no-chord labels below the buttons
		if GUI.elms.lbl_no_chords then
			
			local str = GUI.Val("lbl_no_chords")
			GUI.font(GUI.elms.lbl_no_chords.font)
			local str_w, str_h = gfx.measurestr(str)
			
			GUI.elms.lbl_no_chords.x = (GUI.cur_w - line_x - str_w) / 2 + line_x 
			GUI.elms.lbl_no_chords.y = btn_template[2] + btn_space_v + 6

		end
		
	end
	
end


----------------------------------------
-------------Run the script-------------
----------------------------------------

--GUI.Msg(GUI.tooltip_elm.tooltip)


GUI.Init()


-- Initialize a few things
load_ext()

GUI.elms.tabs:update_sets()

get_reascale(1)

if GUI.quit then return end

search_scales()

update_mnu_harm_deg()
GUI.Val("mnu_harm_deg", tonumber(reaper.GetExtState(GUI.name, "harmony degree")))
	
GUI.elms.lbl_tooltip.z = 18

GUI.func = Main
GUI.freq = 0

reaper.atexit(function ()
	
	-- All notes off
	notes_off()

	-- Save whatever information we want before we quit...
	if not cleared then save_ext() end

end)

GUI.Main()

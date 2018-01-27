--@description ausbaxter_Render item columns
--@version 1.1
--@author ausbaxter
--@about
--    # Render Item Columns
--
--    This package provides a gui interface to render columns of selected items. Has optional tail length, rename capabilities, and its also possible to add regions based on item columns.
--    GUI created using Lokasenna's GUI 2.0. https://forum.cockos.com/showthread.php?t=177772
--@provides
--    ausbaxter_Render item columns.lua
--@changelog
--  Handle bad item selection for in-place rendering
--  Folder structure is maintained when using in-place rendering
--  + Initial release

local section = "\n\n"
local Doc = "Render Item Columns by Austin Baxter" .. section 

      .. "Choose your desired channel format for rendered items in the channel format drop down.\n" 
      .. "If in need of an fx tail, enter in the desired number of seconds to render after each columns end point\n"
      .. "You can enter in a name in the name field. The rendered items will be renamed with '_n' with n being the column number."
      .. section 
      
      .. "-----Routing Options-----" .. section
      
      .. "Allows you to preserve routing beyond Master/Parent send of your selected items ensuring all paths are rendered." .. section
      
      .. "'In-Place'" .. "\n\t"
      ..    "Renders selected items together including any track fx.\n"
      
      .. "'Through Folder'" .. "\n\t"  
      ..    "Renders selected items together through a folder of your choosing." .. "\n\t"
      ..        "Note: You should select only one track whos a common parent to all selected items.\n"
      
      .. "'Through (Pre)Master'" .. "\n\t"
      ..    "Renders selected items out a newly created Pre-master bus. Unfortunately Reaper does not allow programmatic rendering through the master "
      ..    "track so be aware that any master track fx will not be applied." .. section
      
      .. "-----Show/Hide and Commit Regions-----" .. section
      .. "Allows you to visibly see the regions that will be rendered, so easy to check if the output is what you desire." .. "\n\n"
      .. "'Commit' will alternatively let you commit those displayed regions to the project.\n They will no longer be associate RIC." .. "\n\n"
      .. "Thanks for checking out Render Item Columns, and I hope you find it as useful as I have!"

--Lokasenna_GUI 2.0 Core.lua

----------------------------------------------------------------
------------------Copy everything from here---------------------
----------------------------------------------------------------

local function GUI_table ()

local GUI = {}

GUI.version = "1.0"


-- Print stuff to the Reaper console. For debugging purposes.
GUI.Msg = function (str)
  reaper.ShowConsoleMsg(tostring(str).."\n")
end


--[[     Use when working with file paths if you need to add your own /s
    (Borrowed from X-Raym)     
]]--
GUI.file_sep = string.match(reaper.GetOS(), "Win") and "\\" or "/"


--Also might need to know this
GUI.SWS_exists = reaper.APIExists("BR_Win32_GetPrivateProfileString")




  ---- Keyboard constants ----
  
GUI.chars = {
  
  ESCAPE          = 27,
  SPACE          = 32,
  BACKSPACE     = 8,
  HOME          = 1752132965,
  END               = 6647396,
  INSERT          = 6909555,
  DELETE          = 6579564,
  RETURN          = 13,
  UP               = 30064,
  DOWN          = 1685026670,
  LEFT          = 1818584692,
  RIGHT          = 1919379572,
  
  F1               = 26161,
  F2               = 26162,
  F3               = 26163,
  F4               = 26164,
  F5               = 26165,
  F6               = 26166,
  F7               = 26167,
  F8               = 26168,
  F9               = 26169,
  F10               = 6697264,
  F11               = 6697265,
  F12               = 6697266

}
  
--[[     Font and color presets
  
  Can be set using the accompanying functions GUI.font
  and GUI.color. i.e.
  
  GUI.font(2)                    applies the Header preset
  GUI.color("elm_fill")     applies the Element Fill color preset
  
  Colors are converted from 0-255 to 0-1 when GUI.Init() runs,
  so if you need to access the values directly at any point be
  aware of which format you're getting in return.
    
]]--
GUI.fonts = {
  
        -- Font, size, bold/italics/underline
        --                     ^ One string: "b", "iu", etc.
        {"Calibri", 32},     -- 1. Title
        {"Calibri", 20},     -- 2. Header
        {"Calibri", 16},     -- 3. Label
        {"Calibri", 16},     -- 4. Value
  version =      {"Calibri", 12, "i"},
  
}


GUI.colors = {
  
  -- Element colors
  wnd_bg = {64, 64, 64, 255},               -- Window BG
  tab_bg = {56, 56, 56, 255},               -- Tabs BG
  elm_bg = {48, 48, 48, 255},               -- Element BG
  elm_frame = {96, 96, 96, 255},          -- Element Frame
  elm_fill = {64, 192, 64, 255},          -- Element Fill
  elm_outline = {32, 32, 32, 255},     -- Element Outline
  txt = {192, 192, 192, 255},               -- Text
  
  shadow = {0, 0, 0, 48},                    -- Element Shadows
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


--[[     Apply a font preset
  
  fnt               Font preset number
        or
        A preset table -> GUI.font({"Arial", 10, "i"})
  
]]--
GUI.font = function (fnt)
  
  local font, size, str = table.unpack( type(fnt) == "table" and fnt or GUI.fonts[fnt])
  
  -- Different OSes use different font sizes, for some reason
  -- This should give a roughly equal size on Mac
  if string.find(reaper.GetOS(), "OSX") then
    size = math.floor(size * 0.8)
  end
  
  -- Cheers to Justin and Schwa for this
  local flags = 0
  if str then
    for i = 1, str:len() do 
      flags = flags * 256 + string.byte(str, i) 
    end      
  end
  
  gfx.setfont(1, font, size, flags)

end


--[[     Apply a color preset
  
  col               Color preset string -> "elm_fill"
        or
        Color table -> {1, 0.5, 0.5[, 1]}
                R  G    B  [  A]
]]--               
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


--[[     Draw a background rectangle for the given string
  
  A solid background is necessary for blitting z layers
  on their own; antialiased text with a transparent background
  looks like complete shit. This function draws a rectangle 2px
  larger than your text on all sides.
  
  Call with your position, font, and color already set:
  
  gfx.x, gfx.y = self.x, self.y
  GUI.font(self.font)
  GUI.color(self.col)
  
  GUI.text_bg(self.text)
  
  gfx.drawstr(self.text)
  
  Also accepts an optional background color:
  GUI.text_bg(self.text, "elm_bg")
  
]]--
GUI.text_bg = function (str, col)
  
  local x, y = gfx.x, gfx.y
  local r, g, b, a = gfx.r, gfx.g, gfx.b, gfx.a
  
  col = col or "wnd_bg"
  
  GUI.color(col)
  
  local w, h = gfx.measurestr(str)
  w, h = w + 4, h + 4
    
  gfx.rect(gfx.x - 2, gfx.y - 2, w, h, true)
  
  gfx.x, gfx.y = x, y
  
  gfx.set(r, g, b, a)     
  
end



  ---- General functions ----
    



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
        --_=dm and GUI.Msg(string.rep("\t", depth).."base:\t"..tostring(k))
        new[k] = GUI.table_copy(v, base[k], depth)
      else
        new[k] = GUI.table_copy(v, nil, depth)
      end
      
    else
      if not base or (base and new[k] == nil) then 
        --_=dm and GUI.Msg(string.rep("\t", depth).."added:\t"..tostring(k).." = "..tostring(v))          
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



--      Sorting function adapted from: http://lua-users.org/wiki/SortedIteration
GUI.full_sort = function (op1, op2)

  -- Sort strings that begin with a number as if they were numbers,
  -- i.e. so that 12 > "6 apples"
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
  
  Call with f = "full" to use the full sorting function above, or
  use f to provide your own sorting function as per pairs() and ipairs()
  
]]--
GUI.kpairs = function (t, f)


  if f == "full" then
    f = GUI.full_sort
  end

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




  ---- Text functions ----


--[[     Prepares a table of character widths
  
  Iterates through all of the GUI.fonts[] presets, storing the widths
  of every printable ASCII character in a table. 
  
  Accessable via:          GUI.txt_width[font_num][char_num]
  
  - Requires a window to have been opened in Reaper
  
  - 'get_txt_width' and 'word_wrap' will automatically run this
    if it hasn't been run already; it may be rather clunky to use
    on demand depending on what your script is doing, so it's
    probably better to run this immediately after initiliazing
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

    w = w + widths[          string.byte(     string.sub(str, i, i)     ) ]

  end

  return w

end


--[[     Returns 'str' wrapped to fit a given pixel width
  
  str          String. Can include line breaks/paragraphs; they should be preserved.
  font     Font preset number
  w          Pixel width
  indent     Number of spaces to indent the first line of each paragraph
      (The algorithm skips tab characters and leading spaces, so
      use this parameter instead)
  
  i.e.     Blah blah blah blah          -> indent = 2 ->       Blah blah blah blah
      blah blah blah blah                                   blah blah blah blah

  
  pad          Indent wrapped lines by the first __ characters of the paragraph
      (For use with bullet points, etc)
      
  i.e.     - Blah blah blah blah     -> pad = 2 ->     - Blah blah blah blah
      blah blah blah blah                                   blah blah blah blah
  
        
  This function expands on the "greedy" algorithm found here:
  https://en.wikipedia.org/wiki/Line_wrap_and_word_wrap#Algorithm
        
]]--
GUI.word_wrap = function (str, font, w, indent, pad)
  
  _=dm and GUI.Msg("word wrap:\n\tfont "..tostring(font).."\n\twidth "..tostring(w).."\n\tindent "..tostring(indent))
  
  if not GUI.txt_width then GUI.init_txt_width() end
  
  local ret_str = {}

  local w_left, w_word
  local space = GUI.txt_width[font][string.byte(" ")]
  
  local new_para = indent and string.rep(" ", indent) or 0
  
  local w_pad = pad and GUI.get_txt_width(     string.sub(str, 1, pad), font     ) or 0
  local new_line = "\n"..string.rep(" ", math.floor(w_pad / space)     )
  
  
  for line in string.gmatch(str, "([^\n\r]*)[\n\r]*") do
    
    table.insert(ret_str, new_para)
    
    -- Check for leading spaces and tabs
    local leading, line = string.match(line, "^([%s\t]*)(.*)$")     
    if leading then table.insert(ret_str, leading) end
    
    w_left = w
    for word in string.gmatch(line,  "([^%s]+)") do
  
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


-- Convert a hex color RRGGBB to 8-bit values R, G, B
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


-- Convert rgb[a] to hsv[a]; useful for gradients
-- Arguments/returns are given as 0-1
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
  
  local sat = (max ~= 0)      and     ((max - min) / max)
              or     0
              
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
  Returns the color for a given position on an HSV gradient 
  between two color presets

  col_a          Tables of {R, G, B[, A]}, values from 0-1
  col_b
  
  pos               Position along the gradient, 0 = col_a, 1 = col_b
  
  returns          r, g, b, a

]]--
GUI.gradient = function (col_a, col_b, pos)
  
  local col_a = {GUI.rgb2hsv( table.unpack( type(col_a) == "table" and col_a or GUI.colors(col_a) )) }
  local col_b = {GUI.rgb2hsv( table.unpack( type(col_b) == "table" and col_b or GUI.colors(col_b) )) }
  
  local h = math.abs(col_a[1] + (pos * (col_b[1] - col_a[1])))
  local s = math.abs(col_a[2] + (pos * (col_b[2] - col_a[2])))
  local v = math.abs(col_a[3] + (pos * (col_b[3] - col_a[3])))
  local a = (#col_a == 4) and (math.abs(col_a[4] + (pos * (col_b[4] - col_a[4])))) or 1
  
  return GUI.hsv2rgb(h, s, v, a)
  
end


-- Round a number to the nearest integer (or optional decimal places)
GUI.round = function (num, places)

  if not places then
    return num > 0 and math.floor(num + 0.5) or math.ceil(num - 0.5)
  else
    places = 10^places
    return num > 0 and math.floor(num * places + 0.5) or math.ceil(num * places - 0.5) / places
  end
  
end

-- Make sure val is between min and max
GUI.clamp = function (num, min, max)
  if min > max then min, max = max, min end
  return math.min(math.max(num, min), max)
end


-- Odds are you don't need much precision
-- If you do, just specify GUI.pi = math.pi() in your code
GUI.pi = 3.14159


-- Improved roundrect() function with fill, adapted from mwe's EEL example.
GUI.roundrect = function (x, y, w, h, r, antialias, fill)
  
  local aa = antialias or 1
  fill = fill or 0
  
  if fill == 0 or false then
    gfx.roundrect(x, y, w, h, r, aa)
  else
  
    if h >= 2 * r then
      
      -- Corners
      gfx.circle(x + r, y + r, r, 1, aa)               -- top-left
      gfx.circle(x + w - r, y + r, r, 1, aa)          -- top-right
      gfx.circle(x + w - r, y + h - r, r , 1, aa)     -- bottom-right
      gfx.circle(x + r, y + h - r, r, 1, aa)          -- bottom-left
      
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
    table.insert(coords, coords[1])
    table.insert(coords, coords[2])
  
    -- Draw a line from each pair of coords to the next pair.
    for i = 1, #coords - 2, 2 do               
        
      gfx.line(coords[i], coords[i+1], coords[i+2], coords[i+3])
    
    end          
  
  end
  
end


--[[ 
  Takes an angle in radians (omit Pi) and a radius, returns x, y
  Will return coordinates relative to an origin of (0,0), or absolute
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


--[[
  We'll use this to let elements have their own graphics buffers
  to do whatever they want in. 
  
  num     =     How many buffers you want, or 1 if not specified.
  
  Returns a table of buffers, or just a buffer number if num = 1
  
  i.e.
  
  -- Assign this element's buffer
  function GUI.my_element:new(.......)
  
     ...new stuff...
     
     my_element.buffers = GUI.GetBuffer(4)
     -- or
     my_element.buffer = GUI.GetBuffer()
    
  end
  
  -- Draw to the buffer
  function GUI.my_element:init()
    
    gfx.dest = self.buffers[1]
    -- or
    gfx.dest = self.buffer
    ...draw stuff...
  
  end
  
  -- Copy from the buffer
  function GUI.my_element:draw()
    gfx.blit(self.buffers[1], 1, 0)
    -- or
    gfx.blit(self.buffer, 1, 0)
  end
  
]]--

-- Any used buffers will be marked as True here
GUI.buffers = {}

-- When deleting elements, their buffer numbers
-- will be added here for easy access.
GUI.freed_buffers = {}

GUI.GetBuffer = function (num)
  
  local ret = {}
  local prev
  
  for i = 1, (num or 1) do
    
    if #GUI.freed_buffers > 0 then
      
      ret[i] = table.remove(GUI.freed_buffers)
      
    else
    
      for j = (not prev and 1023 or prev - 1), 0, -1 do
      
        if not GUI.buffers[j] then
          ret[i] = j
          GUI.buffers[j] = true
          break
        end
        
      end
      
    end
    
  end

  return (#ret == 1) and ret[1] or ret

end

-- Elements should pass their buffer (or buffer table) to this
-- when being deleted
GUI.FreeBuffer = function (num)
  
  if type(num) == "number" then
    table.insert(GUI.freed_buffers, num)
  else
    for k, v in pairs(num) do
      table.insert(GUI.freed_buffers, v)
    end
  end     
  
end





-- Are these coordinates inside the given element?
-- If no coords are given, will use the mouse cursor
GUI.IsInside = function (elm, x, y)

  if not elm then return false end

  local x, y = x or GUI.mouse.x, y or GUI.mouse.y

  return     (     x >= (elm.x or 0) and x < ((elm.x or 0) + (elm.w or 0)) and 
        y >= (elm.y or 0) and y < ((elm.y or 0) + (elm.h or 0))     )
  
end



--[[
Returns x,y coordinates for a window with the specified anchor position

If no anchor is specified, it will default to the top-left corner of the screen.
  x,y          offset coordinates from the anchor position
  w,h          window dimensions
  anchor     "screen" or "mouse"
  corner     "TL"
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
      TL =      {0,                     0},
      T =          {(aw - w) / 2,           0},
      TR =      {(aw - w) - 16,          0},
      R =          {(aw - w) - 16,          (ah - h) / 2},
      BR =      {(aw - w) - 16,          (ah - h) - 40},
      B =          {(aw - w) / 2,           (ah - h) - 40},
      BL =      {0,                     (ah - h) - 40},
      L =           {0,                     (ah - h) / 2},
      C =           {(aw - w) / 2,          (ah - h) / 2},
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

--[[
-- Display the GUI version number
-- Set GUI.version = 0 to hide this
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
]]--




  ---- Z-layer blitting ----

-- On each draw loop, only layers that are set to true in this table
-- will be redrawn; if false, it will just copy them from the buffer
-- Set [0] = true to redraw everything.
GUI.redraw_z = {}



  ---- Our main functions ----

-- All child elements are stored here
GUI.elms = {}


-- Maintain a list of all GUI elements, sorted by their z order     
-- Also removes any elements with z = -1, for automatically
-- cleaning things up.
GUI.elms_list = {}
GUI.z_max = 0
GUI.update_elms_list = function (init)
  
  local z_table = {}

  for key, __ in pairs(GUI.elms) do

    local z = GUI.elms[key].z or 5

    -- Delete elements if the script asked to
    if z == -1 then
      
      GUI.elms[key]:ondelete()
      GUI.elms[key] = nil
      
    else

      if z_table[z] then
        table.insert(z_table[z], key)

      else
        z_table[z] = {key}

      end
    
    end
    
    if init then 
      
      GUI.elms[key]:init()
      GUI.z_max = math.max(z, GUI.z_max)

    end
  end

  for i = 0, GUI.z_max do
    if not z_table[i] then z_table[i] = {} end
  end

  GUI.elms_list = z_table
  
end

GUI.elms_hide = {}
GUI.elms_freeze = {}


GUI.Init = function ()
  
  
  -- Create the window
  gfx.clear = reaper.ColorToNative(table.unpack(GUI.colors.wnd_bg))
  
  if not GUI.x then GUI.x = 0 end
  if not GUI.y then GUI.y = 0 end
  if not GUI.w then GUI.w = 640 end
  if not GUI.h then GUI.h = 480 end

  if GUI.anchor and GUI.corner then
    GUI.x, GUI.y = GUI.get_window_pos(GUI.x, GUI.y, GUI.w, GUI.h, GUI.anchor, GUI.corner)
  end
    
  gfx.init(GUI.name, GUI.w, GUI.h, GUI.dock or 0, GUI.x, GUI.y)
  
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
    wheel = 0,
    lwheel = 0
    
  }
    
  -- Convert color presets from 0..255 to 0..1
  for i, col in pairs(GUI.colors) do
    col[1], col[2], col[3], col[4] = col[1] / 255, col[2] / 255, col[3] / 255, col[4] / 255
  end
  
  -- Initialize the tables for our z-order functions
  GUI.update_elms_list(true)     
  
  if GUI.Exit then reaper.atexit(GUI.Exit) end
  
  GUI.gfx_open = true

end


GUI.Main = function ()
  
  -- Update mouse and keyboard state, window dimensions
  GUI.mouse.lx, GUI.mouse.ly = GUI.mouse.x, GUI.mouse.y
  GUI.mouse.x, GUI.mouse.y = gfx.mouse_x, gfx.mouse_y
  GUI.mouse.wheel = gfx.mouse_wheel
  GUI.mouse.cap = gfx.mouse_cap
  GUI.char = gfx.getchar() 
  GUI.modCtrl = gfx.mouse_cap&4==4
  GUI.modShift = gfx.mouse_cap&8==8
  GUI.modAlt = gfx.mouse_cap&16==16
  
  if GUI.cur_w ~= gfx.w or GUI.cur_h ~= gfx.h then
    GUI.cur_w, GUI.cur_h = gfx.w, gfx.h
    GUI.resized = true
  else
    GUI.resized = false
  end
  
  --     (Escape key)     (Window closed)          (User function says to close)
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
    
    local new_time = os.time()
    if new_time - GUI.last_time >= (GUI.freq or 1) then
      GUI.func()
      GUI.last_time = new_time
    
    end
  end
  
  -- Redraw all of the elements, starting from the bottom up.
  GUI.update_elms_list()

  --local w, h = gfx.w, gfx.h
  local w, h = GUI.w, GUI.h

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
      if b == true then 
        need_redraw = true 
        break
      end
    end
  end

  if need_redraw then
    
    -- All of the layers will be drawn to their own buffer (dest = z), then
    -- composited in buffer 0. This allows buffer 0 to be blitted as a whole
    -- when none of the layers need to be redrawn.
    
    gfx.dest = 0
    gfx.setimgdim(0, -1, -1)
    gfx.setimgdim(0, w, h)

    GUI.color("wnd_bg")
    gfx.rect(0, 0, w, h, 1)

    for i = GUI.z_max, 0, -1 do
      if #GUI.elms_list[i] > 0 and not GUI.elms_hide[i] then
        
        if GUI.redraw_z[i] then
          
          -- Set this before we redraw, so that elms can call a redraw from
          -- their own :draw method. e.g. Labels fading out
          GUI.redraw_z[i] = false

          gfx.setimgdim(i, -1, -1)
          gfx.setimgdim(i, w, h)
          gfx.dest = i
          
          for __, elm in pairs(GUI.elms_list[i]) do
            if not GUI.elms[elm] then GUI.Msg(elm.." doesn't exist?") end
            GUI.elms[elm]:draw()
          end

          gfx.dest = 0
        end
              
        gfx.blit(i, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
      end
    end
    --GUI.Draw_Version()          
    
  end
  gfx.dest = -1
  gfx.blit(0, 1, 0, 0, 0, w, h, 0, 0, w, h, 0, 0)
  
  gfx.update()
  
end


--     See if the any of the given element's methods need to be called
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
              
      --           Dragging?                                              Did the mouse start out in this element?
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
        
    
      --           Dragging?                                              Did the mouse start out in this element?
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
        

      
      --           Dragging?                                              Did the mouse start out in this element?
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



--[[     Return or change an element's value
  
  For use with external user functions. Returns the given element's current 
  value or, if specified, sets a new one.     Changing values with this is often 
  preferable to setting them directly, as most :val methods will also update 
  some internal parameters and redraw the element when called.
]]--
GUI.Val = function (elm, newval)

  if not GUI.elms[elm] then return nil end
  
  if newval then
    GUI.elms[elm]:val(newval)
  else
    return GUI.elms[elm]:val()
  end

end



-- Wrapper for creating new elements, allows them to know their own name
-- If called after the script window has opened, will also run their :init
-- method.
GUI.New = function (name, elm, ...)
  
  if not GUI[elm] then
    reaper.ShowMessageBox("Unable to create element '"..tostring(name).."'.\nClass '"..tostring(elm).."'isn't available.", "GUI Error", 0)
    GUI.quit = true
    return 0
  end
  
  GUI.elms[name] = GUI[elm]:new(name, ...)     
  if GUI.gfx_open then GUI.elms[name]:init() end
  
  return GUI.elms[name]--get object (added by Ausbaxter)
  
end




--[[
  All classes will use this as their template, so that
  elements are initialized with every method available.
]]--
GUI.Element = {}
function GUI.Element:new(name)
  
  local elm = {}
  if name then elm.name = name end
  
  setmetatable(elm, self)
  self.__index = self
  return elm
  
end

-- Called a) when the script window is first opened
--             b) when any element is created via GUI.New after that
-- i.e. Elements can draw themselves to a buffer once on :init()
-- and then just blit/rotate/etc as needed afterward
function GUI.Element:init() end

-- Called on every update loop, unless the element is hidden or frozen
function GUI.Element:onupdate() end

-- Called when the element is deleted by GUI.update_elms_list()
-- Use it for freeing up buffers, or anything else memorywise that this
-- element was doing
function GUI.Element:ondelete() end

-- Set or return the element's value
-- Can be useful for something like a Slider that doesn't have the same
-- value internally as what it's displaying
function GUI.Element:val() end

-- Updates the current tooltip, if necessary
function GUI.Element:onmouseover()
  
  if self.tooltip and not GUI.tooltip_elm then 
    GUI.tooltip_elm = self 
  end

end



-- Only called once; won't repeat if the button is held
function GUI.Element:onmousedown() end

function GUI.Element:onmouseup() end
function GUI.Element:ondoubleclick() end

-- Will continue being called even if you drag outside the element
function GUI.Element:ondrag() end

-- Right-click equivalents
function GUI.Element:onmouser_down() end
function GUI.Element:onmouser_up() end
function GUI.Element:onr_doubleclick() end
function GUI.Element:onr_drag() end

-- Middle-click equivalents
function GUI.Element:onmousem_down() end
function GUI.Element:onmousem_up() end
function GUI.Element:onm_doubleclick() end
function GUI.Element:onm_drag() end


function GUI.Element:onwheel() end
function GUI.Element:ontype() end



-- For elements like a Textbox that need to keep track of their
-- focus state; use this to e.g. store the text somewhere else
-- when the user clicks out of the box.
function GUI.Element:lostfocus() end




--[[
  To create a new class, just use:
  
    -- Creates a new child of GUI.Element
    GUI.My_Class = GUI.Element:new()
    
    --                         The element's name, i.e. "lbl_version"
    --                                   The element's z layer
    --                                             Coords and size
    --                                                            Whatever other parameters you want
    function GUI.My_Class:new(name, z [, x, y, w, h, param_a, param_b, param_c, param_d])
    
      -- Every class object is really just a big table
      local class = {}
      
      -- These are the only parameters that are strictly necessary
      class.name = name
      class.z = z

      -- However, if you want your class to use any of the methods,
      -- you'll need x, y, w, and h:
      class.x = x
      class.y = y
      class.w = w
      class.h = h

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
  
  
  To create an object of class My_Class:
  GUI.New("my_element", "My_Class", z, x, y, w, h......)     
  
  
  
  Methods are added by:
  
    function GUI.My_Class:fade()
  
      blah blah blah
      
    end
    
  Methods can be modified at run-time like so:
  
    
    function GUI.elms.my_button:draw()
      GUI.Button.draw(self)                    -- Include the original method
      ...do other stuff...
    end
    
    - The original method call ^ isn't necessary; methods can be rewritten from scratch if
      you'd like. It can also be called before, after, or in the middle of your function.
    
    - If it *isn't* used, you'll need to include
        GUI.redraw_z[self.z] = true
      in order for the element to be redrawn when that method is called.
    
  
  - All of the methods listed for GUI.Element will be called when appropriate on each loop
    of GUI.Update. Any methods that aren't listed there can be called on their own as a
    function. To fade a label, for instance:
    
    my_label:fade(2, 3, 10)
    
]]--







-- Make our table full of functions available to the parent script
return GUI

end
GUI = GUI_table()

----------------------------------------------------------------
----------------------------To here-----------------------------
----------------------------------------------------------------


---------------------------------------End 'Core.lua'-------------------------------------------------------



---------------------------------------'Button.lua'---------------------------------------------------------

--[[  Lokasenna_GUI - Button class 
  
  (Adapted from eugen2777's simple GUI template.)
  
  ---- User parameters ----

  (name, z, x, y, w, h, caption, func[, ...])

Required:
z        Element depth, used for hiding and disabling layers. 1 is the highest.
x, y      Coordinates of top-left corner
w, h      Button size
caption      Label
func      Function to perform when clicked

Optional:
...        Any parameters to pass to that function, separated by commas as they
        would be if calling the function directly.


Additional:
r_func      Function to perform when right-clicked
r_params    If provided, any parameters to pass to that function
font      Button label's font
col_txt      Button label's color

col_fill    Button color. 
        *** If you change this, call :init() afterward ***


Extra methods:
exec      Force a button-click, i.e. for allowing buttons to have a hotkey:
          [Y]es  [N]o  [C]ancel
          
        Params:
        r      Boolean, optional. r = true will run the button's
              right-click action instead

]]--

if not GUI then
  reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
  missing_lib = true
  return 0
end


-- Button - New
GUI.Button = GUI.Element:new()
function GUI.Button:new(name, z, x, y, w, h, caption, func, ...)

  local Button = {}
  
  Button.name = name
  Button.type = "Button"
  
  Button.z = z
  GUI.redraw_z[z] = true  
  
  Button.x, Button.y, Button.w, Button.h = x, y, w, h

  Button.caption = caption
  
  Button.font = 3
  Button.col_txt = "txt"
  Button.col_fill = "elm_frame"
  
  Button.func = func or function () end
  Button.params = {...}
  
  Button.state = 0

  setmetatable(Button, self)
  self.__index = self
  return Button

end


function GUI.Button:init()
  
  self.buff = self.buff or GUI.GetBuffer()
  
  gfx.dest = self.buff
  gfx.setimgdim(self.buff, -1, -1)
  gfx.setimgdim(self.buff, 2*self.w + 4, self.h + 2)
  
  GUI.color(self.col_fill)
  GUI.roundrect(1, 1, self.w, self.h, 4, 1, 1)
  GUI.color("elm_outline")
  GUI.roundrect(1, 1, self.w, self.h, 4, 1, 0)
  
  
  local r, g, b, a = table.unpack(GUI.colors["shadow"])
  gfx.set(r, g, b, 1)
  GUI.roundrect(self.w + 2, 1, self.w, self.h, 4, 1, 1)
  gfx.muladdrect(self.w + 2, 1, self.w + 2, self.h + 2, 1, 1, 1, a, 0, 0, 0, 0 )
  
  
end


function GUI.Button:ondelete()
  
  GUI.FreeBuffer(self.buff)
  
end



-- Button - Draw.
function GUI.Button:draw()
  
  local x, y, w, h = self.x, self.y, self.w, self.h
  local state = self.state
    
  
  -- Draw the shadow if not pressed
  if state == 0 then
    
    for i = 1, GUI.shadow_dist do
      
      gfx.blit(self.buff, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)
      
    end

  end
  
  gfx.blit(self.buff, 1, 0, 0, 0, w + 2, h + 2, x + 2 * state - 1, y + 2 * state - 1)   
  
  -- Draw the caption
  GUI.color(self.col_txt)
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



-------------------------------------'End Button.lua'-------------------------------------------------------


-------------------------------------'Start Menubox.lua'-------------------------------------------------------

--[[     Lokasenna_GUI - MenuBox class
  
  ---- User parameters ----
  
  (name, z, x, y, w, h, caption, opts)
  
Required:
z                    Element depth, used for hiding and disabling layers. 1 is the highest.
x, y               Coordinates of top-left corner
w, h
caption               Label displayed to the left of the menu box
opts               Comma-separated string of options. As with gfx.showmenu, there are
        a few special symbols that can be added at the beginning of an option:
        
          # : grayed out
          > : this menu item shows a submenu
          < : last item in the current submenu
          An empty field will appear as a separator in the menu.
          
        
        
Optional:
pad                    Padding between the label and the box


Additional:
bg                    Color to be drawn underneath the label. Defaults to "wnd_bg"
font_a               Font for the menu's label
font_b               Font for the menu's current value


Extra methods:



GUI.Val()          Returns the current menu option, numbered from 1. Numbering does include
        separators and submenus:
        
          New                         1
          --                         
          Open                    3
          Save                    4
          --                         
          Recent     >     a.txt     7
                b.txt     8
                c.txt     9
          --
          Options                    11
          Quit                    12
                    
GUI.Val(new)     Sets the current menu option, numbered as above.


]]--

if not GUI then
  reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
  missing_lib = true
  return 0
end



GUI.Menubox = GUI.Element:new()
function GUI.Menubox:new(name, z, x, y, w, h, caption, opts)
  
  local menu = {}
  
  menu.name = name
  menu.type = "Menubox"
  
  menu.z = z
  GUI.redraw_z[z] = true     
  
  menu.x, menu.y, menu.w, menu.h = x, y, w, h

  menu.caption = caption
  menu.bg = "wnd_bg"
  
  menu.font_a = 3
  menu.font_b = 4
  
  menu.col_cap = "txt"
  menu.col_txt = "txt"
  
  menu.pad = pad or 4
  
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


function GUI.Menubox:init()
  
  local w, h = self.w, self.h
  
  self.buff = GUI.GetBuffer()
  
  gfx.dest = self.buff
  gfx.setimgdim(self.buff, -1, -1)
  gfx.setimgdim(self.buff, 2*w + 4, 2*h + 4)
  
  local r, g, b, a = table.unpack(GUI.colors["shadow"])
  gfx.set(r, g, b, 1)
  gfx.rect(w + 3, 1, w, h, 1)
  gfx.muladdrect(w + 3, 1, w + 2, h + 2, 1, 1, 1, a, 0, 0, 0, 0 )
  
  GUI.color("elm_bg")
  gfx.rect(1, 1, w, h)
  gfx.rect(1, w + 3, w, h)
  
  GUI.color("elm_frame")
  gfx.rect(1, 1, w, h, 0)
  gfx.rect(1 + w - h, 1, h, h, 1)
  
  GUI.color("elm_fill")
  gfx.rect(1, h + 3, w, h, 0)
  gfx.rect(2, h + 4, w - 2, h - 2, 0)
  gfx.rect(1 + w - h, h + 3, h, h, 1)
  
  GUI.color("elm_bg")
  
  -- Triangle size
  local r = 5
  local rh = 2 * r / 5
  
  local ox = (1 + w - h) + h / 2
  local oy = 1 + h / 2 - (r / 2)

  local Ax, Ay = GUI.polar2cart(1/2, r, ox, oy)
  local Bx, By = GUI.polar2cart(0, r, ox, oy)
  local Cx, Cy = GUI.polar2cart(1, r, ox, oy)
  
  GUI.triangle(1, Ax, Ay, Bx, By, Cx, Cy)
  
  oy = oy + h + 2
  
  Ax, Ay = GUI.polar2cart(1/2, r, ox, oy)
  Bx, By = GUI.polar2cart(0, r, ox, oy)
  Cx, Cy = GUI.polar2cart(1, r, ox, oy)     
  
  GUI.triangle(1, Ax, Ay, Bx, By, Cx, Cy)     

end




-- Menubox - Draw
function GUI.Menubox:draw()     
  
  local x, y, w, h = self.x, self.y, self.w, self.h
  
  local caption = self.caption
  local val = self.retval
  local text = self.optarray[val]

  local focus = self.focus
  

  -- Draw the caption
  GUI.font(self.font_a)
  local str_w, str_h = gfx.measurestr(caption)
  gfx.x = x - str_w - self.pad
  gfx.y = y + (h - str_h) / 2
  GUI.text_bg(caption, self.bg)
  GUI.shadow(caption, self.col_cap, "shadow")
  
  for i = 1, GUI.shadow_dist do
    gfx.blit(self.buff, 1, 0, w + 2, 0, w + 2, h + 2, x + i - 1, y + i - 1)     
  end
  
  
  gfx.blit(self.buff, 1, 0, 0, (focus and (h + 2) or 0) , w + 2, h + 2, x - 1, y - 1)      
  
  
  --[[
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
  ]]--

  -- Draw the text
  GUI.font(self.font_b)
  GUI.color(self.col_txt)
  
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
    
    -- Check off the currently-selected option
    if i == self.retval then menu_str = menu_str .. "!" end


    if type(self.optarray[i]) == "table" then
      table.insert( str_arr, tostring(self.optarray[i][1]) )
    else
      table.insert( str_arr, tostring(self.optarray[i]) )
    end

    if str_arr[#str_arr] == ""
    or string.sub(str_arr[#str_arr], 1, 1) == ">" then 
      table.insert(sep_arr, i) 
    end

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
  
  -- Avert a crash if there aren't at least two items in the menu
  if not self.optarray[2] then return end     
  
  local curopt = GUI.round(self.retval - GUI.mouse.inc)
  local inc = GUI.round((GUI.mouse.inc > 0) and 1 or -1)

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



-------------------------------------'End Menubox.lua'-------------------------------------------------------



-------------------------------------'Start Label.lua'-------------------------------------------------------

--[[  Lokasenna_GUI - Label class.

  ---- User parameters ----
  
  (name, z, x, y, caption[, shadow, font, color, bg])
  
Required:
z        Element depth, used for hiding and disabling layers. 1 is the highest.
x, y      Coordinates of top-left corner
caption      Label text

Optional:
shadow      Boolean. Draw a shadow?
font      Which of the GUI's font values to use
color      Use one of the GUI.colors keys to override the standard text color
bg        Color to be drawn underneath the label. Defaults to "wnd_bg"

Additional:
w, h      These are set when the Label is initially drawn, and updated any
        time the label's text is changed via GUI.Val().

Extra methods:
fade      Allows a label to fade out and disappear. Nice for briefly displaying
        a status message like "Saved to disk..."

        Params:
        len      Length of the fade, in seconds
        z_new    z layer to move the label to when called
              i.e. popping up a tooltip
        z_end    z layer to move the label to when finished
              i.e. putting the tooltip label back in a
              frozen layer until you need it again
              
              Set to -1 to have the label deleted instead
        
        curve    Optional. Sets the "shape" of the fade.
              
              1   will produce a linear fade
              >1  will keep the text at full-strength longer,
                but with a sharper fade at the end
              <1  will drop off very steeply
              
              Defaults to 3 if not specified
              
        Note: While fading, the label's z layer will be redrawn on every
        update loop, which may affect CPU usage for scripts with many elements
                
]]--

if not GUI then
  reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
  missing_lib = true
  return 0
end


-- Label - New
GUI.Label = GUI.Element:new()
function GUI.Label:new(name, z, x, y, caption, shadow, font, color, bg)
  
  local label = {}  
  
  label.name = name
  
  label.type = "Label"
  
  label.z = z
  GUI.redraw_z[z] = true

  label.x, label.y = x, y
  
  label.w, label.h = 0, 0
  
  label.retval = caption
  
  label.shadow = shadow or false
  label.font = font or 2
  
  label.color = color or "txt"
  label.bg = bg or "wnd_bg"
  
  setmetatable(label, self)
    self.__index = self 
    return label
  
end


function GUI.Label:fade(len, z_new, z_end, curve)
  
  self.z = z_new
  self.fade_arr = { len, z_end, reaper.time_precise(), curve or 3 }
  GUI.redraw_z[self.z] = true
  
end


-- Label - Draw
function GUI.Label:draw()
  
  local x, y = self.x, self.y
    
  GUI.font(self.font)
  GUI.color(self.color)
  
  if self.fade_arr then
    
    -- Seconds for fade effect, roughly
    local fade_len = self.fade_arr[1]
    
    local diff = (reaper.time_precise() - self.fade_arr[3]) / fade_len
    diff = math.floor(diff * 100) / 100
    diff = diff^(self.fade_arr[4])
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

  GUI.text_bg(self.retval, self.bg)

  if self.h == 0 then  
    self.w, self.h = gfx.measurestr(self.retval)
  end
  
  if self.shadow then  
    GUI.shadow(self.retval, self.color, "shadow")
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



-------------------------------------'End Label.lua'-------------------------------------------------------



------------------------------------'Start Frame.lua'-------------------------------------------------------

--[[  Lokasenna_GUI - Frame class
  
  ---- User parameters ----

  (name, z, x, y, w, h[, shadow, fill, color, round])

Required:
z        Element depth, used for hiding and disabling layers. 1 is the highest.
x, y      Coordinates of top-left corner
w, h      Frame size

Optional:
shadow      Boolean. Draw a shadow beneath the frame?  Defaults to False.
fill      Boolean. Fill in the frame?  Defaults to False.
color      Frame (and fill) color.  Defaults to "elm_frame".
round      Radius of the frame's corners. Defaults to 0.

Additional:
text      Text to be written inside the frame. Will automatically be wrapped
        to fit self.w - 2*self.pad.
txt_indent    Number of spaces to indent the first line of each paragraph
txt_pad      Number of spaces to indent wrapped lines (to match up with bullet
        points, etc)
pad        Padding between the frame's edges and text. Defaults to 0.        
bg        Color to be drawn underneath the text. Defaults to "wnd_bg",
        but will use the frame's fill color instead if Fill = True
font      Text font. Defaults to preset 4.
col_txt      Text color. Defaults to "txt".


Extra methods:


GUI.Val()    Returns the frame's text.
GUI.Val(new)  Sets the frame's text and formats it to fit within the frame, as above.

  
  
]]--

if not GUI then
  reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
  missing_lib = true
  return 0
end



GUI.Frame = GUI.Element:new()
function GUI.Frame:new(name, z, x, y, w, h, shadow, fill, color, round)
  
  local Frame = {}
  Frame.name = name
  Frame.type = "Frame"
  
  Frame.z = z
  GUI.redraw_z[z] = true  
  
  Frame.x, Frame.y, Frame.w, Frame.h = x, y, w, h
  
  Frame.shadow = shadow or false
  Frame.fill = fill or false
  Frame.color = color or "elm_frame"
  Frame.round = 0
  
  Frame.text = ""
  Frame.txt_indent = 0
  Frame.txt_pad = 0
  Frame.bg = "wnd_bg"
  Frame.font = 4
  Frame.col_txt = "txt"
  Frame.pad = 4
  
  
  setmetatable(Frame, self)
  self.__index = self
  return Frame
  
end


function GUI.Frame:init()
  
  if self.text ~= "" then
    self.text = GUI.word_wrap(self.text, self.font, self.w - 2*self.pad, self.txt_indent, self.txt_pad)
  end
  
end


function GUI.Frame:draw()
  
  if self.color == "none" then return 0 end
  
  local x, y, w, h = self.x, self.y, self.w, self.h
  local dist = GUI.shadow_dist
  local fill = self.fill
  local round = self.round
  local shadow = self.shadow
  
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
  
  if self.text then
    
    GUI.font(self.font)
    GUI.color(self.col_txt)
    
    gfx.x, gfx.y = self.x + self.pad, self.y + self.pad
    if not fill then GUI.text_bg(self.text, self.bg) end
    gfx.drawstr(self.text)    
    
  end  

end

function GUI.Frame:val(new)

  if new then
    self.text = GUI.word_wrap(new, self.font, self.w - 2*self.pad, self.txt_indent, self.txt_pad)
    GUI.redraw_z[self.z] = true
  else
    return self.text
  end

end



-------------------------------------'End Frame.lua'-------------------------------------------------------



-------------------------------------'Start Textbox.lua'-----------------------------------------------------

--[[     Lokasenna_GUI - Textbox class
  
  ---- User parameters ----

  (name, z, x, y, w, h[, caption, pad])

Required:
z                    Element depth, used for hiding and disabling layers. 1 is the highest.
x, y               Coordinates of top-left corner
w, h               Width and height of the textbox

Optional:
caption               Label shown to the left of the textbox
pad                    Padding between the label and the textbox


Additional:
bg                    Color to be drawn underneath the label. Defaults to "wnd_bg"
shadow               Boolean. Draw a shadow beneath the label?
color               Text color
font_a               Label font
font_b               Text font

focus               Whether the textbox is "in focus" or not, allowing users to type.
        This setting is automatically updated, so you shouldn't need to
        change it yourself in most cases.
        

Extra methods:


GUI.Val()          Returns self.optsel as a table of boolean values for each option. Indexed from 1.
GUI.Val(new)     Accepts a table of boolean values for each option. Indexed from 1.


]]--

if not GUI then
  reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
  missing_lib = true
  return 0
end

-- Textbox - New
GUI.Textbox = GUI.Element:new()
function GUI.Textbox:new(name, z, x, y, w, h, caption, pad)
  
  local txt = {}
  
  txt.name = name
  txt.type = "Textbox"
  
  txt.z = z
  GUI.redraw_z[z] = true     
  
  txt.x, txt.y, txt.w, txt.h = x, y, w, h

  txt.caption = caption or ""
  txt.pad = pad or 4
  
  txt.shadow = true
  txt.bg = "wnd_bg"
  txt.color = "txt"
  
  txt.font_a = 3
  txt.font_b = 4
  
  txt.caret = 0
  txt.sel = 0
  txt.blink = 0
  txt.retval = ""
  txt.focus = false
  
  txt.on_enter = nil
  
  setmetatable(txt, self)
  self.__index = self
  return txt

end


function GUI.Textbox:init()
  
  local x, y, w, h = self.x, self.y, self.w, self.h
  
  self.buff = GUI.GetBuffer()
  
  gfx.dest = self.buff
  gfx.setimgdim(self.buff, -1, -1)
  gfx.setimgdim(self.buff, 2*w, h)
  
  GUI.color("elm_bg")
  gfx.rect(0, 0, 2*w, h, 1)
  
  GUI.color("elm_frame")
  gfx.rect(0, 0, w, h, 0)
  
  GUI.color("elm_fill")
  gfx.rect(w, 0, w, h, 0)
  gfx.rect(w + 1, 1, w - 2, h - 2, 0)
  
  
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
  GUI.font(self.font_a)
  local str_w, str_h = gfx.measurestr(caption)
  gfx.x = x - str_w - pad
  gfx.y = y + (h - str_h) / 2
  GUI.text_bg(caption, self.bg)
  
  if self.shadow then 
    GUI.shadow(caption, self.color, "shadow") 
  else
    GUI.color(self.color)
    gfx.drawstr(caption)
  end
  
  -- Draw the textbox frame, and make it brighter if focused.
--[[     
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
]]--

  gfx.blit(self.buff, 1, 0, (focus and w or 0), 0, w, h, x, y)

  -- Draw the text
  GUI.color(self.color)
  GUI.font(self.font_b)
  str_w, str_h = gfx.measurestr(text)
  gfx.x = x + pad
  gfx.y = y + (h - str_h) / 2
  gfx.drawstr(text)
  
  
  
  -- Is any text selected?
  if focus then
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

    -- Show the editing caret for half of the blink cycle
    if self.show_caret then
      
      local caret_x = x + pad + gfx.measurestr(string.sub(text, 0, caret))

      GUI.color("txt")
      gfx.rect(caret_x, y + 4, 2, h - 8)
      
    end
    
  GUI.redraw_z[self.z] = true
  
  else --not in focus, user can call a function on focus loss 
    if self.on_enter then
      self.on_enter()
    end  
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
  GUI.font(self.font_b)
  
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
    
  if char == GUI.chars.LEFT and GUI.modShift == true then
    if caret > 0 then
      local len = string.len(self.retval)
      self.caret = caret - 1
      reaper.ShowConsoleMsg(self.caret .. " " .. self.sel .. "\n")
    end
    --reaper.ShowConsoleMsg(tostring("trig"))
  
  elseif char == 118 and GUI.modCtrl == true then
    reaper.ShowConsoleMsg("Paste")
            
  elseif char          == GUI.chars.LEFT then
    if caret > 0 then self.caret = caret - 1 end

  elseif char     == GUI.chars.RIGHT then
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
  elseif char >= 32 and char <= 255 and maxlen == false then

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




-------------------------------------'End Textbox.lua'-------------------------------------------------------

---------------------------------------Error Handler--------------------------------------------------------
local msg_rst_trig 
function ErrorMsg(msg)
    GUI.Val("frm_feedback", msg)
    msg_rst_trig = true
end


--------------------------------------Class Definitions-----------------------------------------------------

local Item = {}
Item.__index = Item

setmetatable(Item, {
    __call = function (cls, ...)
      return cls.New(...)
    end,
})

function Item.New(item, i_start, i_end, m_state) --stores reaper item, start and end values
    local self = setmetatable({}, Item)
    self.item = item
    self.s = i_start
    self.e = i_end
    self.m_state = m_state
    return self
end

local Region = {}
Region.__index = Region

setmetatable(Region, {
    __call = function (cls, ...)
      return cls.New(...)
    end,
})

function Region.New(index, r_start, r_end)
    local self = setmetatable({}, Region)
    self.index = index
    self.r_start = r_start
    self.r_end = r_end
    return self
end


-------------------------------------------Constants-------------------------------------------------------
local mono = 41721
local stereo = 41719
local multi = 41720
local cmd_id                                                                                                       --for render type
local in_place = 1
local folder = 2
local master = 3
local preview_nm = "RIC Preview"
local default_nm = "Column Render"
-----------------------------------------Region Preview----------------------------------------------------
local preview_switch = false
local preview_rgns ={}
----------------------------------------Version Display----------------------------------------------------
local clock_trigger = true
local version_switch = 1
local ver = "v1.1 "
local date = "01/26/18"
local author = "by ausbaxter"
local gui = "GUI library by lokasenna"
--------------------------------------------Script---------------------------------------------------------
function msg(m)
    reaper.ShowConsoleMsg(tostring(m))
end


function Initialize()
    item_count = reaper.CountSelectedMediaItems()
    media_items = {}                                                                                             --sorted selected media item list
    item_columns = {}
    track_count = reaper.CountTracks(0) - 1
    media_tracks = {}
    parent_tk_check = {}
    render_track = nil
    dest_track = nil
    folder_is_child = true
    R = math.random(255)
    G = math.random(255)
    B = math.random(255)
    color = (R + 256 * G + 65536 * B)|16777216                                                                                      --check for "f" mode
    ts_start, ts_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
end

function UpdateFdbk(msg)
    reaper.ShowConsoleMsg(GUI.Val("frm_feedback"))
end

function ParseCSVLine (line,sep)                                                                                   --csv parser snippet

    local res = {}
    local pos = 1
    local sep = sep or ','
    while true do 
        local c = string.sub(line,pos,pos)
        if (c == "") then break
        else  
            local startp,endp = string.find(line,sep,pos)                                                          --no quotes used, just look for the first separator
            if (startp) then 
                table.insert(res,string.sub(line,pos,startp-1))
                pos = endp + 1
            else
                table.insert(res,string.sub(line,pos))                                                             --no separator found -> use rest of string and terminate
                break
            end 
        end
    end
    return res
    
end

function GetInput() --need to get gui for sure
  
    local valid_string = true
    
    name = GUI.elms.txt_name.retval
    
    offset = GUI.elms.txt_tail.retval
    --[[if string.find(offset, "%d+") == nil then 
        valid_string = false
    end]]
     
    local channel_opt = GUI.elms.mnu_chan_format.retval
    if channel_opt == 1 then
        cmd_id = mono
    elseif channel_opt == 2 then
        cmd_id = stereo
    elseif channel_opt == 3 then
        cmd_id = multi
    end
    
    local render_opt = GUI.elms.mnu_route_opts.retval
    if render_opt == 1 then
        routing = in_place
    elseif render_opt == 2 then
        routing = folder
    elseif render_opt == 3 then
        routing = master
    end
    
    return valid_string
    
end

function GetItemPosition(item)

    local s = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
    local e = s + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    return s, e
  
end

function InsertTrackIntoTable(t, this_track, check)

    local track_found = false
    for i, track in ipairs(t) do                                                                       --check if trying to add repeated track
        if this_track == track[1] then
            track_found = true
            break 
        end
    end
    if track_found == false then
        local track_index = reaper.GetMediaTrackInfo_Value(this_track, "IP_TRACKNUMBER") - 1
        table.insert(t, {this_track, track_index})
    end

end

function InsertIntoTable(t, this_elem)
    local elem_found = false
    for i, elem in ipairs(t) do                                                                       --check if trying to add repeated track
        if this_elem == elem then
            elem_found = true
            break 
        end
    end
    if elem_found == false then
        table.insert(t, this_elem)
    end
end

function GetSelectedMediaItemsAndTracks()
    all_muted = true
    in_place_bad = false
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local s, e = GetItemPosition(item)
        local m = reaper.GetMediaItemInfo_Value(item, "B_MUTE")
        if m == 0 then
            all_muted = false
        end
        table.insert(media_items, Item(item, s, e, m))
        
        local track = reaper.GetMediaItem_Track(item)

        local p_track = tostring(reaper.GetParentTrack(track))
        InsertIntoTable(parent_tk_check, p_track)

        InsertTrackIntoTable(media_tracks, track)
    end
    if #parent_tk_check > 1 then --checks if in-place is possible
        in_place_bad = true
    end 
    table.sort(media_items, function(a,b) return a.s < b.s end)

end

function FindFirstValidItem(idx)
    for i = idx, item_count do                                                                                   --make sure first item in column is unmuted
        local item_check = media_items[idx]
        if item_check.m_state == 1 then
            idx = i+1
            item_check = media_items[idx]
        else
            return item_check , idx
        end
    end
end

function GetItemColumns()                                                                                        --making into a grammar
  
  local end_compare = 0.0
  local item_index = 1
  local column = {}
  local first_item = true
  while item_index <= item_count do
      local in_column = true
      while in_column and item_index <= item_count do
          
          if first_item then                                                                                     --first item in column
              item, item_index = FindFirstValidItem(item_index)
              table.insert(column,item)
              end_compare = item.e
              first_item = false
          else
              local item = media_items[item_index]
              local start_compare = item.s
              if item.m_state == 1 then
              elseif start_compare < end_compare then --item is within column
                  table.insert(column,item)
                  if item.e > end_compare then
                      end_compare = item.e
                  end           
              else                                                                                               --item is start of next column
                end_compare = item.e         
                in_column = false
                item, item_index = FindFirstValidItem(item_index)
                table.insert(item_columns, column)
                column = {}                                                                                      --new empty column
                table.insert(column,item)
              end
          end            
          item_index = item_index + 1
      end     
  end
  table.insert(item_columns, column)                                                                             --insert final column into table 
end

function CreateParentTrack(otk_index)
 
  reaper.InsertTrackAtIndex(otk_index, false)
  track = reaper.GetTrack(0, otk_index)
  reaper.TrackList_AdjustWindows(false)
  table.insert(media_tracks, {track, otk_index - 1})
  table.sort(media_tracks, function(a,b) return a[2]<b[2]end)
  return track
  
end

function CreateFolderHierarchy()

    last_track = nil
    for i, tk_table in ipairs(media_tracks) do
        track = tk_table[1]
        if i == 1 then
            reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", 1)
            reaper.SetOnlyTrackSelected(track)  
        end
        last_track = track
        last_track_depth = reaper.GetMediaTrackInfo_Value(last_track,"I_FOLDERDEPTH")
        local x, nm = reaper.GetSetMediaTrackInfo_String(track,"P_NAME","",false)
    end 
    reaper.SetMediaTrackInfo_Value(last_track, "I_FOLDERDEPTH", -2)
  
end

function MSetup()                                                                                               --render through master setup
    
    local otk_index = nil
    local tk = reaper.GetMediaItem_Track(media_items[1].item)
    local has_parent = true
    while has_parent do
        local parent_tk = reaper.GetParentTrack(tk)
        if parent_tk == nil then
            has_parent = false
            otk_index = reaper.GetMediaTrackInfo_Value(tk, "IP_TRACKNUMBER") - 1
        end
        tk = parent_tk
    end
    
    reaper.InsertTrackAtIndex(0,false)
    render_track = reaper.GetTrack(0,0)
    reaper.SetMediaTrackInfo_Value(reaper.GetTrack(0,track_count), "I_FOLDERDEPTH", -1)
    reaper.SetMediaTrackInfo_Value(render_track, "I_FOLDERDEPTH", 1)
    dest_track = render_track

end

function IsChild(render_track)

    for i, item in ipairs(media_items) do
        local child = reaper.MediaItemDescendsFromTrack(item.item, render_track)
        if child < 2 then      
            return false
        end  
    end
    return true
    
end

function FSetup()                                                                                              --render through folder setup
    
    local otk_index = nil
    local tk_count = reaper.CountSelectedTracks(0)
    
    local sel_tk = reaper.GetSelectedTrack(0,0)
    if sel_tk == nil then 
        ErrorMsg("Must select a folder to render through.")
        return false 
    end
    
    local is_folder = reaper.GetMediaTrackInfo_Value(sel_tk, "I_FOLDERDEPTH")
    if is_folder ~= 1 then 
       ErrorMsg("Selected Track is not a folder.") 
        return false 
    end
    
    if tk_count > 1 then 
        ErrorMsg("When rendering through folders must select only one track to render through") 
        return false 
    end
    otk_index = reaper.GetMediaTrackInfo_Value(sel_tk, "IP_TRACKNUMBER") - 1
    render_track = reaper.GetTrack(0,otk_index)
    
    if IsChild(render_track) == false then 
        ErrorMsg("Not all selected items are children of selected folder") 
        return false 
    end
    reaper.InsertTrackAtIndex(otk_index,false)
    dest_track = reaper.GetTrack(0,otk_index)
    
    return true

end

function DefaultSetup()                                                                                       --render only selected items setup

    local tk = media_tracks[1][1]

    otk_index = reaper.GetMediaTrackInfo_Value(tk, "IP_TRACKNUMBER") - 1
    render_track = CreateParentTrack(otk_index)
    dest_track = render_track
    CreateFolderHierarchy()
    
end

function CreateOutputTrack(routing)                                                                           --creates new track before track with selected items OR parent track

    if routing == master then                                                             --render through master
        MSetup()
    elseif routing == folder then                                                         --render through selected folder
        if not FSetup() then return false end
    elseif routing == in_place then                                                        --render items only
        if in_place_bad then
            ErrorMsg("Items are not in the same folder depth.")
            return false
        else
            DefaultSetup()
        end
    end
    
    reaper.GetSetMediaTrackInfo_String(dest_track, "P_NAME", "Column Render", true)
    
    return true
    
end

function GetLoopTimeSelection(item_columns, column)

    local c_start = 0.0
    local c_end = 0.0
              
    for i, item in ipairs(item_columns[column]) do
        if c_start == 0.0 then                                                                                --init with first item's start and end
            c_start = item.s 
            c_end = item.e
        else
            if item.e > c_end then                                                                            --update item end
                c_end = item.e
            end
        end          
    end
    
    return c_start, c_end
                
end

function MuteColumns(state, i)

    for j, m_column in ipairs(item_columns) do
        if j ~= i then 
            for k, item in ipairs(m_column) do
                if state == 1 and item.m_state == 0 then                                                    --only mute unmuted items
                    reaper.SetMediaItemInfo_Value(item.item, "B_MUTE", state)
                elseif state == 0 and item.m_state == 0 then                                                --only unmute originally muted items
                    reaper.SetMediaItemInfo_Value(item.item, "B_MUTE", state)
                end
            end
        end
    end
  
end

function SoloTracks(state)

    for i, tk in ipairs(media_tracks) do
        reaper.SetMediaTrackInfo_Value(tk[1], "I_SOLO", state)                                              -- 0 unsolo, 1 solo, 2 sip 
    end

end

function HandleUnselectedItemsWithinColumnBounds(c_start, c_end, mute_state)

    local unwanted_item_overlaps = {}
    for i, tk in ipairs(media_tracks) do
        for j = 0, reaper.CountTrackMediaItems(tk[1]) - 1 do
            local item = reaper.GetTrackMediaItem(tk[1], j)
            local i_start, i_end = GetItemPosition(item)
            
            if not(i_end <= c_start or i_start >= c_end) then
                if reaper.GetMediaItemInfo_Value(item, "B_UISEL") == 0 then
                    reaper.SetMediaItemInfo_Value(item, "B_MUTE", mute_state)
                end
            end
        end
    end

end

function RenderColumns()                                                                                    --render loop
    
    SoloTracks(1)
    reaper.SetOnlyTrackSelected(render_track)
    local render_index = reaper.GetMediaTrackInfo_Value(render_track, "IP_TRACKNUMBER") - 1
    reaper.SetMediaTrackInfo_Value(render_track, "B_MUTE", 0)
    local current_column
    
    for i, column in ipairs(item_columns) do
        current_column = i
        MuteColumns(1, i)                                                                                   --set other columns to muted
        local c_start, c_end = GetLoopTimeSelection(item_columns, i)
        reaper.GetSet_LoopTimeRange(true, false, c_start, c_end + offset, true)
        HandleUnselectedItemsWithinColumnBounds(c_start, c_end, 1)                                          --mute unselected items in same column if track is a source track.
        reaper.Main_OnCommand(cmd_id, 0)
        
        local current_index = reaper.GetMediaTrackInfo_Value(render_track, "IP_TRACKNUMBER") - 1
        
        --Msg("Render Index: " .. render_index .. "\tCurrent Index: " .. current_index)
        
        if  render_index == current_index then
            HandleUnselectedItemsWithinColumnBounds(c_start, c_end, 0)                                          --unmute those previously unselected items.
            reaper.SetOnlyTrackSelected(render_track)
            reaper.SetMediaTrackInfo_Value(render_track, "B_MUTE", 0)                                           --make sure render track is unmuted
            MuteColumns(0, i)
            SoloTracks(0)                                   
            return false, i - 1
        end
        
        HandleUnselectedItemsWithinColumnBounds(c_start, c_end, 0)                                          --unmute those previously unselected items.
        reaper.SetOnlyTrackSelected(render_track)
        reaper.SetMediaTrackInfo_Value(render_track, "B_MUTE", 0)                                           --make sure render track is unmuted
        MuteColumns(0, i)
        render_index = render_index + 1                                                                               --restore other columns to unmuted.
    end
    
    SoloTracks(0)
    return true, current_column
end

function FormatName(item , num)

    local count
    local sep = "_"
    local new_name
    
    if #item_columns > 99 then count = string.format("%03d", num)                                           --format item number with leading zeros
    elseif #item_columns < 99 and #item_columns > 1 then count = string.format("%02d", num)
    elseif #item_columns == 1 then count = "" sep = "" end
    
    if name ~= "" then --create new item name
        new_name = name .. sep .. count
    else
        new_name = "Column Render" .. sep .. count
    end
      reaper.GetSetMediaItemTakeInfo_String(reaper.GetTake(item,0), "P_NAME", new_name, 1)
end

function MoveRenderedItemsToTrack(gd_render, num_complete)
    index = reaper.GetMediaTrackInfo_Value(render_track, "IP_TRACKNUMBER") - 1
    --Msg("Index of Render Track (move): " .. index .. "\n")
    local columns
    
    if gd_render then
        columns = #item_columns
    else
        columns = num_complete
    end
    
    --msg("Number of columns: " .. columns)
    
    for i = 1, num_complete do                                                                               --move items to one track
        local track = reaper.GetTrack(0, index - i)
        local item = reaper.GetTrackMediaItem(track, 0)
        --if item ~= nil then --prevents null ref if user cancels render
            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
            reaper.UpdateItemInProject(item)
            reaper.MoveMediaItemToTrack(item, dest_track)
            reaper.SetMediaItemSelected(item, 1)
            FormatName(item, num_complete + 1 - i)
        --end
            if track ~= dest_track then
                reaper.DeleteTrack(track)
            end
    end
    
end

function CleanUp(num_complete)                                                                                          --restore time selection, and folder structure. Mute source items
  reaper.SetMediaTrackInfo_Value(dest_track, "I_FOLDERDEPTH", 0)
  if last_track ~= nil then  reaper.SetMediaTrackInfo_Value(last_track, "I_FOLDERDEPTH", last_track_depth) end
  reaper.GetSet_LoopTimeRange(true, false, ts_start, ts_end, false)
  
  for i, column in ipairs(item_columns) do
      for j, item in ipairs(column) do
          reaper.SetMediaItemInfo_Value(item.item, "B_MUTE", 1)
          reaper.SetMediaItemInfo_Value(item.item, "B_UISEL", 0)
          reaper.SetMediaItemInfo_Value(item.item, "I_CUSTOMCOLOR", color)
          reaper.UpdateItemInProject(item.item)
      end
      if num_complete ~= nil and i == num_complete then                                                                 --only mute completed columns
          return
      end
  end
end

function Render()
    Initialize()
    if item_count == 0 then ErrorMsg("Must have 1 or more media items selected.")
    else 
        reaper.Undo_BeginBlock()
        local valid = GetInput()
        if valid then
            GetSelectedMediaItemsAndTracks()
            if not all_muted then
                GetItemColumns()
                reaper.PreventUIRefresh(1)
                if CreateOutputTrack(routing) then
                
                    local gd_render, num_complete = RenderColumns()
                    MoveRenderedItemsToTrack(gd_render,num_complete)
                    CleanUp(num_complete)
                    if preview_rgns ~= nil then
                        DeleteRegions()
                        GUI.elms.btn_commit_regions.col_txt = "gray" 
                    end
                    GUI.Val("txt_name", "") --reset name field
                    reaper.UpdateArrange()
                    ErrorMsg("Render Success!")
                   
                end
            else
                ErrorMsg("All selected media items are muted.")
            end
        end
    end
    reaper.Undo_EndBlock("Render Item Columns", 0)
end

function DeleteRegions()
    for i, rgn in ipairs(preview_rgns)do
        reaper.DeleteProjectMarker(0, rgn.index, true)
    end
    preview_rgns = {}
    reaper.UpdateArrange()
    preview_switch = false
    GUI.elms.btn_show_regions.caption = "Show"
end

function UpdateRegionPreview()
    local val = GUI.Val("txt_tail")
    if not string.find(tostring(val), "%d+") then 
        GUI.Val("txt_tail", 0) 
        val = 0  
    end
    if preview_switch then
        offset = val
        for i, rgn in ipairs(preview_rgns)do
            count = string.format("%02d", i)
            reaper.SetProjectMarker(rgn.index, true, rgn.r_start, rgn.r_end + offset, preview_nm .. "_" .. count)
        end
    end
end

function RegionPreview()
local valid = GetInput()
if valid then
    if not preview_switch then
        GetItemColumns()
        for i, column in ipairs(item_columns) do
            local c_start, c_end = GetLoopTimeSelection(item_columns, i)
            local idx = reaper.AddProjectMarker(0, true, c_start, c_end, "", 0)
            reaper.SetProjectMarker3(0, idx, true, c_start, c_end + offset, "", color)
            table.insert(preview_rgns, Region(idx,c_start, c_end))
        end
        preview_switch = true
        GUI.elms.btn_show_regions.caption = "Hide"
    else
        DeleteRegions()
    end       
end
end

function ShowRegions()
    reaper.Undo_BeginBlock()
    Initialize()
    GetSelectedMediaItemsAndTracks()
    if item_count == 0 then 
        ErrorMsg("Must have 1 or more media items selected.")
    elseif all_muted then
        ErrorMsg("All selected media items are muted.")
    else
        if preview_switch == false then
            RegionPreview()
            GUI.elms.btn_commit_regions.col_txt = "txt"
        else 
            GUI.elms.btn_commit_regions.col_txt = "gray"
            DeleteRegions()
        end
    end
    reaper.Undo_EndBlock("Show/Hide RIC Preview Regions",4)
end

function CommitRegions()
    reaper.Undo_BeginBlock()
    Initialize()
    if GetInput() then
        if name == "" then name = "RIC Committed Region" end
        local count
        local sep = "_"
        for i, rgn in ipairs(preview_rgns)do
            count = string.format("%02d", i)
            reaper.SetProjectMarker(rgn.index, true, rgn.r_start, rgn.r_end + offset, name .. sep .. count)
        end
        preview_rgns ={} --reset preview regions
        preview_switch = false
        GUI.elms.btn_show_regions.caption = "Show"
        GUI.elms.btn_commit_regions.col_txt = "gray"
    end
    reaper.Undo_EndBlock("Commit Preview To Regions",-1)
end

function ShowDoc()
    reaper.ShowConsoleMsg(Doc)
end

--clock for updating plug info
function Info_Cycle()   
    if clock_trigger then
        ic_time = os.time()
        if version_switch == 1 then
            GUI.Val("lbl_auth", ver .. date)
        elseif version_switch == 2 then 
            GUI.Val("lbl_auth", author)
        elseif version_switch == 3 then
            GUI.Val("lbl_auth", gui)
            version_switch = 0
        end
        clock_trigger = false
        version_switch = version_switch + 1
    end
    if os.time() > ic_time + 4 then
        
        clock_trigger = true
    end
end
msg_time = 0
--clock for hiding error msg
function Msg_Reset()
    if msg_rst_trig then
        msg_time = os.time()
        msg_rst_trig = false
    end
    if os.time() > msg_time + 4 then
        GUI.Val("frm_feedback","")
    end
    if os.time() > msg_time + 1 then
        GUI.elms.frm_f1.color = "gray"
    end
end

function UI_Update()
        Info_Cycle()
        Msg_Reset()
end




GUI.name = "Render Item Columns"
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 370, 245
GUI.anchor, GUI.corner = "mouse", "C"
GUI.shadow_dist = 2

--[[     

  New elements are created by:
  
  GUI.New(name, class, params)
  
  and can then have their parameters accessed via:
  
  GUI.elms.name.param
  
  ex:
  
  GUI.New("my_new_label", "Label", 1, 32, 32, "This is my label")
  GUI.elms.my_new_label.color = "magenta"
  GUI.elms.my_new_label.font = 1
  
  
    Classes and parameters
  
  Button          name,      z,      x,      y,      w,      h, caption, func[, ...]
  Checklist     name,      z,      x,      y,      w,      h, caption, opts[, dir, pad]
  Frame          name,      z,      x,      y,      w,      h[, shadow, fill, color, round]
  Knob          name,      z,      x,      y,      w,      caption, min, max, steps, default[, vals]     
  Label          name,      z,      x,      y,          caption[, shadow, font, color, bg]
  Menubox          name,      z,      x,      y,      w,      h, caption, opts
  Radio          name,      z,      x,      y,      w,      h, caption, opts[, dir, pad]
  Slider          name,      z,      x,      y,      w,      caption, min, max, steps, handles[, dir]
  Tabs          name,      z,      x,      y,           tab_w, tab_h, opts[, pad]
  Textbox          name,      z,      x,      y,      w,      h[, caption, pad]

  
]]--
--          name                  type             z    x       y     w   h  captions           [options]
GUI.New("frm_f1",                "Frame",          3, 10,     12,  350, 185)
GUI.elms.frm_f1.shadow = true
GUI.elms.frm_f1.fill = false
GUI.elms.frm_f1.color = "gray"

GUI.New("mnu_chan_format",     "Menubox",          1, 165,     25,  150, 20, "Channel Format:", "Mono,Stereo,Multichannel")
GUI.elms.mnu_chan_format.pad = 20

GUI.New("mnu_route_opts",            "Menubox",    1, 165,     57,  150, 20, "Routing Option:", "In-Place,Through Folder,Through (Pre)Master")
GUI.elms.mnu_route_opts.pad = 20

GUI.New("txt_tail",            "Textbox",          1, 165,     89,   72, 20, "")
GUI.elms.txt_tail.retval = 0
GUI.elms.txt_tail.on_enter = UpdateRegionPreview
GUI.New("lbl_tail",              "Label",          1,  55,     90,           "Tail Length (sec):",    1,        3)

GUI.New("txt_name",            "Textbox",          1, 165,    121,  150, 20, "")
GUI.New("lbl_name",              "Label",          1,  70,    122,           "Render Name:",    1,        3)

GUI.New("lbl_auth",              "Label",          4,   12,    230,           "",    1,        "version")


GUI.New("btn_render",           "Button",          1, 125,    153,  120, 24, "Render", Render)
GUI.New("btn_show_regions",     "Button",          1,  40,    157,   80, 16, "Show", ShowRegions)
GUI.New("btn_commit_regions",   "Button",          1, 250,    157,  80, 16, "Commit", CommitRegions)
GUI.elms.btn_commit_regions.col_txt = "gray"

GUI.New("btn_show_doc",         "Button",          1, 320,    208,  35, 13, "Doc", ShowDoc)
GUI.elms.btn_show_doc.shadow = 0
GUI.elms.btn_show_doc.col_fill = "wnd_bg"

GUI.New("frm_feedback",          "Frame",          2, 12,     205,  346, 22)
GUI.New("frm_fdbk_frame",        "Frame",          3, 10,     203,  350, 25)
GUI.elms.frm_feedback.font = 4
GUI.elms.frm_feedback.fill = true
GUI.elms.frm_feedback.color = "elm_bg"

GUI.Init()
GUI.freq = 0
GUI.func = UI_Update
GUI.Main()

reaper.atexit(function() DeleteRegions() end)

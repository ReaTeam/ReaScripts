-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local Color = {}
Color.__index = Color

local KNOWN_LOOKUP = {
    aqua = "#00ffff",
    azure = "#f0ffff",
    beige = "#f5f5dc",
    bisque = "#ffe4c4",
    blue = "#0000ff",
    brown = "#a52a2a",
    coral = "#ff7f50",
    crimson = "#dc143c",
    cyan = "#00ffff",
    darkred = "#8b0000",
    dimgray = "#696969",
    dimgrey = "#696969",
    gold = "#ffd700",
    gray = "#808080",
    green = "#008000",
    grey = "#808080",
    hotpink = "#ff69b4",
    indigo = "#4b0082",
    ivory = "#fffff0",
    khaki = "#f0e68c",
    lime = "#00ff00",
    linen = "#faf0e6",
    maroon = "#800000",
    navy = "#000080",
    oldlace = "#fdf5e6",
    olive = "#808000",
    orange = "#ffa500",
    orchid = "#da70d6",
    peru = "#cd853f",
    pink = "#ffc0cb",
    plum = "#dda0dd",
    purple = "#800080",
    red = "#ff0000",
    salmon = "#fa8072",
    sienna = "#a0522d",
    silver = "#c0c0c0",
    skyblue = "#87ceeb",
    snow = "#fffafa",
    tan = "#d2b48c",
    teal = "#008080",
    thistle = "#d8bfd8",
    tomato = "#ff6347",
    violet = "#ee82ee",
    wheat = "#f5deb3",
    white = "#ffffff"
}

local function rgb2hsv( r, g, b )
	local M, m = math.max( r, g, b ), math.min( r, g, b )
	local C = M - m
	local K = 1.0/(6.0 * C)
	local h = 0.0
	if C ~= 0.0 then
		if M == r then     h = ((g - b) * K) % 1.0
		elseif M == g then h = (b - r) * K + 1.0/3.0
		else               h = (r - g) * K + 2.0/3.0
		end
	end
	return h, M == 0.0 and 0.0 or C / M, M
end

local function hsv2rgb( h, s, v )
	local C = v * s
	local m = v - C
	local r, g, b = m, m, m
	if h == h then
		local h_ = (h % 1.0) * 6
		local X = C * (1 - math.abs(h_ % 2 - 1))
		C, X = C + m, X + m
		if     h_ < 1 then r, g, b = C, X, m
		elseif h_ < 2 then r, g, b = X, C, m
		elseif h_ < 3 then r, g, b = m, C, X
		elseif h_ < 4 then r, g, b = m, X, C
		elseif h_ < 5 then r, g, b = X, m, C
		else               r, g, b = C, m, X
		end
	end
	return r, g, b
end

-- Taken from HSX, public domain
local function rgb2hsl( r, g, b )
	local M, m = math.max( r, g, b ), math.min( r, g, b )
	local C = M - m
	local K = 1.0 / (6*C)
	local h = 0
	if C ~= 0 then
		if M == r then     h = ((g - b) * K) % 1.0
		elseif M == g then h = (b - r) * K + 1.0/3.0
		else               h = (r - g) * K + 2.0/3.0
		end
	end
	local l = 0.5 * (M + m)
	local s = 0
	if l > 0 and l < 1 then
		s = C / (1-math.abs(l + l - 1))
	end
	return h, s, l
end

-- Taken from HSX, public domain
local function hsl2rgb( h, s, l )
	local C = ( 1 - math.abs( l + l - 1 ))*s
	local m = l - 0.5*C
	local r, g, b = m, m, m
	if h == h then
		local h_ = (h % 1.0) * 6.0
		local X = C * (1 - math.abs(h_ % 2 - 1))
		C, X = C + m, X + m
		if     h_ < 1 then r, g, b = C, X, m
		elseif h_ < 2 then r, g, b = X, C, m
		elseif h_ < 3 then r, g, b = m, C, X
		elseif h_ < 4 then r, g, b = m, X, C
		elseif h_ < 5 then r, g, b = X, m, C
		else               r, g, b = C, m, X
		end
	end
	return r, g, b
end

local function _parse(hex)

  if type(hex) == "number" then
    -- Assume it's RGB
    return (hex & 0xFF0000) >> 16, (hex & 0xFF00) >> 8, (hex & 0xFF), nil
  end

  local col = KNOWN_LOOKUP[hex]
  if col then hex = col end

  hex = hex:gsub("^%#", "")

  local r,g,b,a = hex:match("^(%x%x)(%x%x)(%x%x)$")
  if r then
      r,g,b,a = tonumber(r,16), tonumber(g,16), tonumber(b,16), nil
  else
    a,r,g,b = hex:match("^(%x%x)(%x%x)(%x%x)(%x%x)$")

    if a then
        r,g,b,a = tonumber(r,16), tonumber(g,16), tonumber(b,16), tonumber(a,16)
    else
        error("Wrong format")
    end
  end

  return r,g,b,a
end

function Color:new(r_or_string_or_rgb_int,g,b,a)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(r_or_string_or_rgb_int,g,b,a)
    return instance
end

function Color:new_from_iargb(argb)
  return Color:new( (argb & 0x00FF0000) >> 16, (argb & 0x0000FF00) >> 8, (argb & 0x000000FF), (argb & 0xFF000000) >> 24)
end

function Color:new_from_irgba(rgba)
  return Color:new((rgba & 0xFF000000) >> 24, (rgba & 0x00FF0000) >> 16, (rgba & 0x0000FF00) >> 8, (rgba & 0x000000FF))
end

function Color:validateComponent(name, presence)
  local val = self[name]

  if presence and not val then error("Missing " .. name .. " component") end

  if val then
    if val < 0    then val = 0 end
    if val > 255  then val = 255 end

    self[name] = math.floor(val + 0.5)
  end
end

function Color:_initialize(r,g,b,a)

  if r ~= nil and g == nil and b == nil and a == nil then
    r,g,b,a = _parse(r)
  end

  self.r = r
  self.g = g
  self.b = b
  self.a = a
  self:validateComponent('r', true)
  self:validateComponent('g', true)
  self:validateComponent('b', true)
  self:validateComponent('a', false)
end

function Color:hasAlpha()
  return not (self.a == nil)
end

function Color:opacity()
  return (self:hasAlpha()) and (self.a/255.0) or (1.0)
end

function Color:setOpacity(opacity)
  self.a = opacity * 255
  self:validateComponent('a', true)
end

function Color:hsl()
    return rgb2hsl(self.r/255.0, self.g/255.0, self.b/255.0)
end
function Color:hsv()
    return rgb2hsv(self.r/255.0, self.g/255.0, self.b/255.0)
end

function Color:setHsl(h,s,l)
    local r,g,b = hsl2rgb(h,s,l)
    self.r, self.g, self.b = math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end
function Color:setHsv(h,s,l)
    local r,g,b = hsv2rgb(h,s,l)
    self.r, self.g, self.b = math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

function Color:css_rgb()
  return string.format("#%02X%02X%02X", self.r, self.g, self.b)
end

function Color:css_argb()
  return string.format("#%%02X02X%02X%02X", self.a, self.r, self.g, self.b)
end

function Color:to_irgb()
  return (self.r << 16) | (self.g << 8) | (self.b << 0)
end

function Color:to_iargb()
  return ((self.a or 255) << 24) | self:to_irgb()
end

function Color:to_irgba()
  return (self:to_irgb() << 8) | ((self.a or 255) << 0)
end

function Color.irgba(str)
  return Color.parse(str):to_irgba()
end

function Color.irgb(str)
  return Color.parse(str):to_irgb()
end

function Color.iargb(str)
  return Color.parse(str):to_iargb()
end

function Color.parse(hex)
  local r,g,b,a = _parse(hex)
  return Color:new(r,g,b,a)
end

return Color

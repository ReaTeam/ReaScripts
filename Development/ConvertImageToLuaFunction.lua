--[[
Description: Convert Image To Lua Function
Author: pandabot
License: MIT
Version: 1.0
Donate: https://paypal.me/benjohnson2001
Link: https://forum.cockos.com/member.php?u=127396
About: 
    Reaper tool that converts image to Lua source code for drawing images pixel by pixel

    Note: requires SWS extensions

    1. select png image
    2. source code is put into system clipboard
--]]


-- get image path

local userComplied, imagePath = reaper.GetUserFileNameForRead("", "select image file", "png")

if not userComplied then
	return
end

-- get image dimensions

local imageIndex = 0
gfx.loadimg(imageIndex, imagePath)
local width, height = gfx.getimgdim(imageIndex)

-- get pixel information

Pixel = {}
Pixel.__index = Pixel

function Pixel:new(x, y, r, g, b)

  local self = {}
  setmetatable(self, Pixel)

  self.x = x
  self.y = y
  self.r = r
  self.g = g
  self.b = b

  return self
end

local function openWindow(width, height)

	local width = width
	local height = height
	local dockState = 0
	local x = 0
	local y = 0
	gfx.init("", width, height, dockState, x, y)
end

function loadImage()

	local imageIndex = 0
	gfx.loadimg(imageIndex, imagePath)
	gfx.blit(imageIndex, 1.0, 0.0)
end

openWindow(width, height)
loadImage()

pixels = {}

for x = 1, width do

	for y = 1, height do

		gfx.x = x
		gfx.y = y
		local r, g, b = gfx.getpixel()

		table.insert(pixels, Pixel:new(x, y, r, g, b))
	end
end

-- print source code

local output = {}
table.insert(output, "function drawImage()\n")

table.insert(output, "    local xOffset = gfx.x")
table.insert(output, "    local yOffset = gfx.y")

for i = 1, #pixels do

  local pixel = pixels[i]

	table.insert(output, "    gfx.x = " .. pixel.x .. " + xOffset")
	table.insert(output, "    gfx.y = " .. pixel.y .. " + yOffset")
	table.insert(output, "    gfx.setpixel(" .. pixel.r .. ", " .. pixel.g .. ", " .. pixel.b .. ")")
end

table.insert(output, "end")

reaper.CF_SetClipboard(table.concat(output, "\n"))
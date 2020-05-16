-- @description GU-on Editing Scripts
-- @author GU-on
-- @version 1.0

--[[
 * ReaScript Name: GU-on_Item Fader
 * Author: GU-on
 * Licence: GPL v3
 * REAPER: 6.10
 * Version: 1.1
 * Requires Scythe Library
--]]
 
--[[
 * Changelog:
 * v1.1 (2020-05-16)
	+ Added fade in functionality
	+ Added snap offset functionality
 * v1.0 (2020-05-15)
	+ Initial Release
--]]

local libPath = reaper.GetExtState("Scythe v3", "libPath")
if not libPath or libPath == "" then
    reaper.MB("Couldn't load the Scythe library. Please install 'Scythe library v3' from ReaPack, then run 'Script: Scythe_Set v3 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(libPath .. "scythe.lua")()
local GUI = require("gui.core")
local Table = require("public.table")

local window

------------------------------------
-------- Functions  ----------------
------------------------------------

local function SetFades(fade_in, fade_out, relative_fadein, fadeout_ignores_snap)

	selected_items_count = reaper.CountSelectedMediaItems(0)
	
  	for i = 0, selected_items_count-1  do
		-- GET ITEMS
		item = reaper.GetSelectedMediaItem(0, i)

		-- GET INFOS
		item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
		item_snap = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
		
		fadein_len = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
		fadeout_len = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
		
		-- SET INFOS
		if relative_fadein then
			reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", item_snap * fade_in)
		else
			reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", (item_len) * fade_in)
		end
		
		if fadeout_ignores_snap then
			reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", item_len * fade_out) 
		else
			reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", (item_len - item_snap) * fade_out)
		end

	end
end

local function ButtonClick()
	-- Retrieve Fade Slider Values 
	local slider_val = GUI.Val("FadeSlider")
	local fade_in = ((slider_val[1]) / 100)
	local fade_out = ((100 - slider_val[2]) / 100)
	-- Retrieve Snap Offset Toggle Box Values
	local checkbox_val = GUI.Val("SnapOffsetCheck")
	local relative_fadein = checkbox_val[1]
	local fadeout_ignores_snap = checkbox_val[2]
	
	reaper.Undo_BeginBlock()
  
	SetFades(fade_in, fade_out, relative_fadein, fadeout_ignores_snap)

	reaper.Undo_EndBlock("Typical script options", 0)
	  
	reaper.UpdateArrange()

	Scythe.quit = true
 
end

function UpdateFadeCaption()
	local fadeInLabel = GUI.findElementByName("FadeInLabel") 
	local fadeOutLabel = GUI.findElementByName("FadeOutLabel")
	
	local slider_val = GUI.Val("FadeSlider")
	
	fadeInLabel.retval = tostring(slider_val[1]) .. " %"
	fadeOutLabel.retval = tostring(100 - slider_val[2]) .. " %"
end

------------------------------------
-------- Window settings -----------
------------------------------------


window = GUI.createWindow({
  name = "Apply relative fades to items",
  x = 0,
  y = 0,
  w = 768,
  h = 128,
  anchor = "screen",
  corner = "C",
})


------------------------------------
-------- GUI Elements --------------
------------------------------------


local layer = GUI.createLayer({name = "Layer1"})

layer:addElements( GUI.createElements(
  {
    name = "FadeSlider",
    type = "Slider",
    z = 11,
    x = 64,
    y = 48,
    w = 384,
    caption = "Fade Amount",
	showValues = false,
    min = 0,
    max = 100,
    defaults = {0, 100},
    inc = 1,
    dir = "h",
	afterMouseDown = UpdateFadeCaption,
    afterMouseUp = UpdateFadeCaption,
    afterDoubleClick = UpdateFadeCaption,
    afterDrag = UpdateFadeCaption,
    afterWheel = UpdateFadeCaption
  },
  {
    name = "ButtonExecute",
    type = "Button",
    x = 191,
    y = 80,
    w = 128,
    h = 24,
    caption = "Go!",
    func = ButtonClick
  },
  {
	name = "FadeInLabel",
	type = "Textbox",
	x = 40,
	y = 19,
	w = 55,
	retval = "0 %",
	caption = ""
  },
  {
	name = "FadeOutLabel",
	type = "Textbox",
	x = 416,
	y = 19,
	w = 55,
	retval = "0 %",
	caption = ""
  },
  {
	name = "SnapOffsetCheck",
	type =	"Checklist",
	x = 512,
	y = 20,
	w = 128,
	h = 128,
	pad = 10,
	frame = false;
	caption = "Options",
	options = {"Fade in relative to snap offset", "Fade out ignores snap offset"}
  }
))

window:addLayers(layer)
window:open()

GUI.Main()

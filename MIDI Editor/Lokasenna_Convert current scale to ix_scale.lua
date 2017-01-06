--[[
Description: Convert current scale to ix_scale
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
	Converts the MIDI editor's current key snap scale into a .txt file
	for use in the IX MIDI effects included with Reaper. Output files are
	saved in the Reaper\Data\ix_scales folder.
Extensions:
--]]

local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end


local cur_wnd = reaper.MIDIEditor_GetActive()
if not cur_wnd then
	reaper.ShowMessageBox( "This script needs an active MIDI editor.", "No MIDI editor found", 0)
	return -1
end

local cur_take = reaper.MIDIEditor_GetTake(cur_wnd)

-- Parse the scale string into something useful
-- Size = number of non-zero values in the scale
local __, __, __, scale_name = reaper.MIDI_GetScale(cur_take, 0, 0, "")
local __, scale_str = reaper.MIDIEditor_GetSetting_str(cur_wnd, "scale", "")
local __, size = string.gsub(scale_str, "[^0]", "")
	
scale_arr = {[0] = 0}
for i = 1, size do
	scale_arr[i] = string.find(scale_str, "[^0]", scale_arr[i-1] + 1)
end

-- Adjust the values so that root = 0
for i = 1, size do
	scale_arr[i] = scale_arr[i] - 1
end

local base_path = reaper.GetResourcePath().."\\Data\\ix_scales\\"
local file_name = base_path..scale_name..".txt"

local file = io.open(file_name, "w+") or nil

if file then
	for i = 1, #scale_arr - 1 do
		file:write(scale_arr[i].."\n")
	end
	file:write(scale_arr[#scale_arr])
end
file:close()

reaper.ShowMessageBox("Saved "..file_name, "Scale converted!", 0)

-- Licensed under the GNU GPL v3
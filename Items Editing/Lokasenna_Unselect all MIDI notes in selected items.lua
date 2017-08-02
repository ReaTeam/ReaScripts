--[[
Description: Unselect all MIDI notes in selected items
Version: 1.01
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
--]]

-- Licensed under the GNU GPL v3

local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end

reaper.Undo_BeginBlock()

local num_items = reaper.CountSelectedMediaItems(0)

for i = 0, num_items - 1 do
	
	local item = reaper.GetSelectedMediaItem(0, i)
	local take = reaper.GetActiveTake(item)
	
	if reaper.TakeIsMIDI(take) then 
		reaper.MIDI_SelectAll(take, 0)
	end
	
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("Unselect all MIDI notes in selected items", -1)

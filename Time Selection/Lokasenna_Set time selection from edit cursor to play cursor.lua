--[[
Description: Set time selection from edit cursor to play cursor
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Creates a time selection between the edit cursor and play cursor
	
	Will snap to grid if snap is enabled, and will follow grid
	visibility changes (different zoom levels, etc)
--]]

-- Licensed under the GNU GPL v3

local pos_a = reaper.GetCursorPosition()
local pos_b = reaper.SnapToGrid( 0, reaper.GetPlayPosition() )

if pos_a > pos_b then pos_a, pos_b = pos_b, pos_a end

reaper.GetSet_LoopTimeRange( true, false, pos_a, pos_b, false )
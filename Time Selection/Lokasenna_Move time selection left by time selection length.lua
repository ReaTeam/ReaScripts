--[[
Description: Move time selection left by time selection length
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
--]]

-- Licensed under the GNU GPL v3

local pos_a, pos_b = reaper.GetSet_LoopTimeRange( false, false, 0, 0, false )

if not (pos_a and pos_b) then return end

pos_b = pos_a - (pos_b - pos_a)

reaper.GetSet_LoopTimeRange( true, false, pos_b, pos_a, false )
--[[
Description: Move edit cursor to start of first item in selected tracks
Version: 1.0.2
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Fix: Crash if no items in the selected tracks
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
Extensions:
--]]

-- Licensed under the GNU GPL v3

reaper.Undo_BeginBlock()

local num_tracks = reaper.CountSelectedTracks( 0 )

local times = {}
for i = 0, num_tracks - 1 do

	local tr = reaper.GetSelectedTrack( 0, i )
	local item = reaper.GetTrackMediaItem( tr, 0 )

	table.insert(times, reaper.GetMediaItemInfo_Value( item, "D_POSITION" ) )

end

if #times == 0 then return end
table.sort(times)

reaper.ApplyNudge( 0, 1, 6, 1, times[1], false, 0 )

reaper.Undo_EndBlock("Move cursor to start of first item in selected tracks", 0)

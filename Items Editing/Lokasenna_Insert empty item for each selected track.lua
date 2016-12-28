--[[
Description: Insert empty item for each selected track
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Performs the action "insert empty item" on each selected track.
--]]

-- Licensed under the GNU GPL v3

reaper.Undo_BeginBlock()

local num_tracks = reaper.CountSelectedTracks(0)
local track_arr = {}

for i = 0, (num_tracks - 1) do
	local track = reaper.GetSelectedTrack(0, 0)
	track_arr[i] = track
	-- set first sel. track as last touched
	reaper.Main_OnCommand(40914, 0)
		-- insert empty item (on last touched)
	reaper.Main_OnCommand(40142, 0)
	reaper.SetTrackSelected(track, false)
end

for i = 0, #track_arr do
	reaper.SetTrackSelected(track_arr[i], true)
end

reaper.Undo_EndBlock("Insert empty item for each selected track", 0)
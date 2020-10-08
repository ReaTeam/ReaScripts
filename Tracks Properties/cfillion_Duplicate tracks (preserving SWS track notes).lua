-- @description Duplicate tracks (preserving SWS track notes)
-- @author cfillion
-- @version 1.0
-- @link
--   cfillion.ca https://cfillion.ca
--   Request thread https://github.com/reaper-oss/sws/issues/1415
-- @donation https://paypal.me/cfillion

local notes = {}

for i = 0, reaper.CountSelectedTracks(nil) - 1 do
  local track = reaper.GetSelectedTrack(nil, i)
  notes[i] = reaper.NF_GetSWSTrackNotes(track)
end

reaper.Main_OnCommand(40062, 0) -- Track: Duplicate tracks

for i = 0, reaper.CountSelectedTracks(nil) - 1 do
  local track = reaper.GetSelectedTrack(nil, i)
  reaper.NF_SetSWSTrackNotes(track, notes[i])
end

-- @description Enable track playback offset for selected tracks (Samples)
-- @author Edgemeal
-- @version 1.00
-- @donation Donate https://www.paypal.me/Edgemeal

reaper.Undo_BeginBlock()
local trackcount = reaper.CountSelectedTracks()
for i = 0, trackcount-1 do
  local track = reaper.GetSelectedTrack(0, i)
  reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", 2)
end
reaper.Undo_EndBlock('Enable track playback offset for selected tracks (Samples)', -1)

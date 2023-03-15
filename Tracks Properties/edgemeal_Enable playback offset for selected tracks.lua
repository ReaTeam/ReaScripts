-- @description Enable track playback offset for selected tracks
-- @author Edgemeal
-- @version 1.00
-- @link Forum https://forum.cockos.com/showthread.php?t=243019
-- @donation Donate https://www.paypal.me/Edgemeal

reaper.Undo_BeginBlock()
local trackcount = reaper.CountSelectedTracks()
for i = 0, trackcount-1 do
  local track = reaper.GetSelectedTrack(0, i)
  local val = reaper.GetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG")
  if val&1 ~= 0 then
    reaper.SetMediaTrackInfo_Value(track, "I_PLAY_OFFSET_FLAG", val&(~1))
  end
end
reaper.Undo_EndBlock('Enable playback offset for selected tracks', -1)

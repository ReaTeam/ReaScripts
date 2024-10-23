-- @description Remove muted track sends from selected tracks
-- @author Edgemeal
-- @version 1.0
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=239747
-- @donation Donate https://www.paypal.me/Edgemeal

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
local track_count = reaper.CountSelectedTracks(0)
for i = 0, track_count-1 do
  track = reaper.GetSelectedTrack(0,i)
  local send_cnt = reaper.GetTrackNumSends(track, 0)
  for send_index = send_cnt-1,0,-1 do
    local muted = reaper.GetTrackSendInfo_Value(track, 0, send_index, "B_MUTE")
    if muted == 1 then reaper.RemoveTrackSend(track, 0, send_index) end
  end
end
reaper.Undo_EndBlock('Remove muted track sends from selected tracks', -1)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

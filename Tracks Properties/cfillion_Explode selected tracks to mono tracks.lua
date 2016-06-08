-- Explode selected tracks to mono tracks for REAPER v5.16+
-- http://forum.cockos.com/showthread.php?p=1647321
-- @version 1.1
-- @author cfillion

local tracks = reaper.CountSelectedTracks(0)

if tracks < 1 then
  reaper.ShowMessageBox("Select some tracks and retry.", "Selection is empty!", 0)
  return
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

for trackIndex=0,tracks-1 do
  local parent = reaper.GetSelectedTrack(0, trackIndex)
  local chans = reaper.GetMediaTrackInfo_Value(parent, "I_NCHAN")
  local trackId = reaper.GetMediaTrackInfo_Value(parent, "IP_TRACKNUMBER")
  local _, name = reaper.GetSetMediaTrackInfo_String(parent, "P_NAME", "", false)

  reaper.SetMediaTrackInfo_Value(parent, "B_MAINSEND", 0)

  for chanIndex=0,chans-1 do
    local insertIndex = trackId + chanIndex
    reaper.InsertTrackAtIndex(insertIndex, true)
    track = reaper.GetTrack(0, insertIndex)

    local send = reaper.CreateTrackSend(parent, track)
    reaper.SetTrackSendInfo_Value(parent, 0, send, "I_SRCCHAN", chanIndex | 1024)
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME",
      string.format("Ch. %d - %s", chanIndex + 1, name), true)
  end
end

reaper.Undo_EndBlock("Explode selected tracks to mono tracks", 1)

reaper.PreventUIRefresh(-1)
reaper.TrackList_AdjustWindows(false)

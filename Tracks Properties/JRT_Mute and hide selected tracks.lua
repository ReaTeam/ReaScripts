-- @description Mute and hide selected tracks
-- @author JRTaylorMusic
-- @version 1.0

function Main()
  count_sel_tracks = reaper.CountSelectedTracks(0)
  for i = 0, count_sel_tracks - 1 do
    local track = reaper.GetSelectedTrack(0,i)
    local mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
    if mute == 0 then mute = 1 else mute = 0 end
    reaper.SetMediaTrackInfo_Value(track, "B_MUTE",1)
    reaper.SetMediaTrackInfo_Value(track,'B_SHOWINMIXER',0);
    reaper.SetMediaTrackInfo_Value(track,'B_SHOWINTCP',0);
  end
  reaper.UpdateArrange()
end
-- See if there is items selected
count_sel_tracks = reaper.CountSelectedTracks(0)

if count_sel_tracks > 0 then

  reaper.PreventUIRefresh(1)

  reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

  Main()

  reaper.Undo_EndBlock("JRT_Mute and Hide Selected Tracks", -1) -- End of the undo block. Leave it at the bottom of your main function.

  reaper.TrackList_AdjustWindows(false)

  reaper.UpdateArrange()

  reaper.PreventUIRefresh(-1)

end

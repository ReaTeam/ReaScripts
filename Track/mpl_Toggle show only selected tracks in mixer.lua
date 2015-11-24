function is_tracks_hidden()
  if reaper.CountTracks(0) ~= nil then
    for i = 1, reaper.CountTracks(0) do
      tr = reaper.GetTrack(0, i-1)
      if tr ~= nil then
        vis_mcp = reaper.GetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER')
        if vis_mcp == 0 then return true end
      end
    end
  end
  return false
end

if is_tracks_hidden() and reaper.CountTracks(0) ~= nil then -- if something hidden
  for i = 1, reaper.CountTracks(0) do
    tr = reaper.GetTrack(0, i-1)
    if tr ~= nil then reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER',1) end
  end
  reaper.TrackList_AdjustWindows(false)
 else
  for i = 1, reaper.CountTracks(0) do
    tr = reaper.GetTrack(0, i-1)    
    if reaper.IsTrackSelected(tr) then 
      reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER',1)
     else
      reaper.SetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER',0)
    end
  end
  reaper.TrackList_AdjustWindows(false)
end

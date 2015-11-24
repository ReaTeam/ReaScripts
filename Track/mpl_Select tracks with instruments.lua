-- Select tracks with instruments

c_tracks = reaper.CountTracks(0)
if c_tracks ~= nil then
  for i =1, c_tracks do
    tr = reaper.GetTrack(0,i-1)
    if tr ~= nil then
      id = reaper.TrackFX_GetInstrument(tr)
      if id ~= -1 then
        reaper.SetMediaTrackInfo_Value(tr, 'I_SELECTED', 1)
       else
        reaper.SetMediaTrackInfo_Value(tr, 'I_SELECTED', 0)
      end
    end
  end
end

script_title = "Solo track with opened FX chain"
reaper.Undo_BeginBlock()

counttrack = reaper.CountTracks(0)
if counttrack  ~= nil then
  for i=1, counttrack do
    tr = reaper.GetTrack(0,i-1)
    if tr ~= nil then 
      if reaper.TrackFX_GetChainVisible(tr) >= 0 then 
        reaper.SetMediaTrackInfo_Value(tr, 'I_SOLO', 1)
       else
        reaper.SetMediaTrackInfo_Value(tr, 'B_MUTE', 0)
        reaper.SetMediaTrackInfo_Value(tr, 'I_SOLO', 0)
      end
    end
  end
end

reaper.Undo_EndBlock(script_title, 0)

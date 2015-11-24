  script_title = "Trim master fader to 0dB"
  reaper.Undo_BeginBlock()
  
  track = reaper.GetMasterTrack(0)
      if track ~= nil then
        peak = reaper.Track_GetPeakInfo(track, 1)
        if peak > 1 then
          vol = reaper.GetMediaTrackInfo_Value(track, 'D_VOL')
          reaper.SetMediaTrackInfo_Value(track, 'D_VOL',vol-(peak-1))
        end
      end
  
  reaper.UpdateArrange()
  
  
  reaper.Undo_EndBlock(script_title,0)

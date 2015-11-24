_, _, _ = reaper.BR_GetMouseCursorContext()
track = reaper.BR_GetMouseCursorContext_Track()
if track ~= nil then  
  if reaper.GetMediaTrackInfo_Value(track, 'I_RECARM') == 0 then
    reaper.ClearAllRecArmed()
    reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',1)
   else
    reaper.ClearAllRecArmed()
    reaper.SetMediaTrackInfo_Value(track, 'I_RECARM',0)
  end  
end

-- @noindex


function SendTempo()
  currentPos = reaper.GetPlayPosition()
  ta1, ta2, ta3, ta4, newTempo, ta5, ta6, ta7 = reaper.GetTempoTimeSigMarker(0, reaper.FindTempoTimeSigMarker(0,currentPos))
  reaper.SetExtState("Fanciest","CurrentTempo",tostring(newTempo), false)
end

SendTempo()

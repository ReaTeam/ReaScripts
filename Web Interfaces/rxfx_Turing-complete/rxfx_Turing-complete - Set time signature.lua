-- @noindex


function TimeSig()
  currentPos = reaper.GetPlayPosition()
  tempoString = reaper.GetExtState("Fanciest","TempoSet")
  if tempoString == "" then
    ta1, ta2, ta3, ta4, newTempo, ta5, ta6, ta7 = reaper.GetTempoTimeSigMarker(0, reaper.FindTempoTimeSigMarker(0,currentPos))
  else
    newTempo = tonumber(tempoString)
  end
  
  timeSigString = reaper.GetExtState("Fanciest","TimeSigSet")
  if timeSigString == "" then
    ta1, ta2, ta3, ta4, ta5, newTimeSigNum, newTimeSigDenom, ta7 = reaper.GetTempoTimeSigMarker(0, reaper.FindTempoTimeSigMarker(0,currentPos))
  else
    newTimeSigNum,newTimeSigDenom = timeSigString:match("(.+):(.+)")
    newTimeSigNum,newTimeSigDenom = tonumber(newTimeSigNum),tonumber(newTimeSigDenom)
  end
  --reaper.ShowConsoleMsg(reaper.FindTempoTimeSigMarker(0,5))
  reaper.SetTempoTimeSigMarker(0, reaper.FindTempoTimeSigMarker(0,currentPos), 0, -1, -1, newTempo, newTimeSigNum, newTimeSigDenom, false)
  reaper.DeleteExtState("Fanciest","TempoSet",false)
  reaper.DeleteExtState("Fanciest","TimeSigSet",false)
end

TimeSig()

-- @noindex


function Track_Cycle_RecordState()
--reaper.ShowConsoleMsg(reaper.GetExtState("Fanciest", "TrackRename"))
ToCycle = tonumber(reaper.GetExtState("Fanciest","TrackRecordCycle"))
Track = reaper.GetTrack(0, ToCycle-1)
if reaper.GetMediaTrackInfo_Value(Track, "I_RECARM") == 0 then
  reaper.SetMediaTrackInfo_Value(Track, "I_RECARM", 1)
  reaper.SetMediaTrackInfo_Value(Track, "I_RECINPUT", 0)
  reaper.SetExtState("Fanciest","RecCycleSuccess","chan1",false)
else
  if reaper.GetMediaTrackInfo_Value(Track, "I_RECINPUT") == 0 then
    reaper.SetMediaTrackInfo_Value(Track, "I_RECINPUT", 1)
    reaper.SetExtState("Fanciest","RecCycleSuccess","chan2",false)
  else
    reaper.SetMediaTrackInfo_Value(Track, "I_RECARM", 0)
    reaper.SetExtState("Fanciest","RecCycleSuccess","off",false)
  end
end
reaper.DeleteExtState("Fanciest","TrackRecordCycle",true)
end

Track_Cycle_RecordState()

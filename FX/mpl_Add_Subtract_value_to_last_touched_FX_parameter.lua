script_title = "Add / Subtract value to last touched FX parameter"
value = 0.01

reaper.Undo_BeginBlock()
retval, trackid, fxid, paramid = reaper.GetLastTouchedFX()
if retval ~= nil then
  track = reaper.GetTrack(0, trackid-1)
  if track ~= nil then
    value0 = reaper.TrackFX_GetParamNormalized(track, fxid, paramid)
    newval = value0 + value
    reaper.TrackFX_SetParamNormalized(track, fxid, paramid, newval) 
  end  
end
reaper.Undo_EndBlock(script_title, 1)

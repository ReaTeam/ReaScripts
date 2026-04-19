-- @noindex


function SendTempo()
  newTempo = reaper.Master_GetTempo()
  reaper.SetExtState("Fanciest","CurrentTempo",tostring(newTempo), false)
end

SendTempo()
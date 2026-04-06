-- @noindex


function Rename_From_ExtState()
--reaper.ShowConsoleMsg(reaper.GetExtState("Fanciest", "TrackRename"))
NewName = reaper.GetExtState("Fanciest","TrackRename")
Track = reaper.GetSelectedTrack(0, 0)
reaper.GetSetMediaTrackInfo_String(Track, "P_NAME", NewName, true)
reaper.DeleteExtState("Fanciest","TrackRename",true)
end

Rename_From_ExtState()

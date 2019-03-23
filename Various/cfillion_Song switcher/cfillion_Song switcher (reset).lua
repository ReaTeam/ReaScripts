-- @noindex

reaper.defer(function() -- no undo point
  reaper.SetExtState('cfillion_song_switcher', 'reset', 'true', false)
end)

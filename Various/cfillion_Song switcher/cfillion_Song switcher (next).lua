-- @noindex

-- This script is part of cfillion_Song switcher.lua
reaper.defer(function() -- no undo point
  reaper.SetExtState('cfillion_song_switcher', 'relative_move', '1', false)
end)

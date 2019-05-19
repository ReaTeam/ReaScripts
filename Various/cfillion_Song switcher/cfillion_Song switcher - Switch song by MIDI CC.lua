-- @noindex

-- This script is part of cfillion_Song switcher.lua
local is_new_value, filename, sectionID, cmdID, mode, resolution, value = reaper.get_action_context()
local signal = 'relative_move'

if mode == 0 then signal = 'absolute_move' end

reaper.SetExtState('cfillion_song_switcher', signal, value, false)
reaper.defer(function() end) -- no undo point

-- @noindex

-- This script is part of cfillion_Song switcher.lua

local CC, ABS_MODE = {}, 0
local script_name = select(2, reaper.get_action_context()):match('([^/\\_]+)%.lua$')
local action_name = script_name:match(' %- (.-)$')
local action = ({
  ['Reset data'             ] = {'reset',           'true'},
  ['Switch to queued song'  ] = {'activate_queued', 'true'},
  ['Switch to previous song'] = {'relative_move',     '-1'},
  ['Switch to next song'    ] = {'relative_move',      '1'},
  ['Queue previous song'    ] = {'relative_queue',    '-1'},
  ['Queue next song'        ] = {'relative_queue',     '1'},
  ['Switch song by MIDI CC' ] = {CC, 'absolute_move',  'relative_move' },
  ['Queue song by MIDI CC'  ] = {CC, 'absolute_queue', 'relative_queue'},
})[action_name]
if not action then error(('unknown action "%s"'):format(action_name or script_name)) end

if action[1] == CC then
  local is_new_value, filename, sectionID, cmdID, mode, resolution, value = reaper.get_action_context()
  action = { action[mode == ABS_MODE and 2 or 3], tostring(value) }
end

reaper.SetExtState('cfillion_song_switcher', action[1], action[2], false)
reaper.defer(function() end) -- no undo point

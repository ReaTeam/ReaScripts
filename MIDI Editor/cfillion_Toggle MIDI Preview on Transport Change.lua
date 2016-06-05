-- Name: Toggle MIDI Preview on Transport Change.lua
-- Author: cfillion
-- Version: 1.1
-- Changelog:
--   Fixed preview toggling when reopening the midi editor
--
-- Send patches at <https://github.com/cfillion/reascripts>.
--
-- http://forum.cockos.com/showthread.php?t=169896

local TOGGLE_CMD, last_state, do_toggle = 40041, false, false

function main_loop()
  local state = reaper.GetPlayState() == 1

  if do_toggle and reaper.MIDIEditor_GetActive() then
    reaper.MIDIEditor_LastFocused_OnCommand(TOGGLE_CMD, 0)
    do_toggle = false
  end

  if state ~= last_state then
    do_toggle = not do_toggle
    last_state = state
  end

  reaper.defer(main_loop)
end

reaper.defer(main_loop)

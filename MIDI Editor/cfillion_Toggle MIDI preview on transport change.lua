-- @description Toggle MIDI preview on transport change
-- @author cfillion
-- @version 1.1.1
-- @changelog Register the script in the main section too
-- @provides [main=main,midi_editor] .
-- @link
--   https://cfillion.tk
--   Forum Thread http://forum.cockos.com/showthread.php?t=169896
-- @donation https://www.paypal.me/cfillion

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

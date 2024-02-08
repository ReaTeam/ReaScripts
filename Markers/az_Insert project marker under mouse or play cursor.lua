-- @description Insert project marker under mouse or play cursor
-- @author AZ
-- @version 1.0
-- @provides
--   [main=main,midi_editor] .
--   [main=main,midi_editor] az_Insert project marker under mouse or play cursor/az_Insert project marker and edit it under mouse or play cursor.lua
-- @link Forum thread https://forum.cockos.com/showthread.php?t=288069
-- @donation Donate via PayPal https://www.paypal.me/AZsound
-- @about
--   SWS is required
--
--   This script brings usability of project markers closer to the take markers.
--
--   If mouse placed in arrange -  use mouse position for marker, else use edit or play cursor position.

function ins_proj_marker()
window, segment, details = reaper.BR_GetMouseCursorContext()

if window == "arrange" or window == "midi_editor" then
  pos =  reaper.BR_GetMouseCursorContext_Position()

  if window == "midi_editor" then
    if segment == "unknown"or segment == "notes"or segment == "cc_lane" then
    reaper.AddProjectMarker2( 0, false, pos, 0, "", -1, 0 )
    else
    reaper.Main_OnCommandEx(  reaper.NamedCommandLookup( "_S&M_INS_MARKER_PLAY" ), 0, 0 )
    end
  else
    reaper.AddProjectMarker2( 0, false, pos, 0, "", -1, 0 )
  end
else
  reaper.Main_OnCommandEx(  reaper.NamedCommandLookup( "_S&M_INS_MARKER_PLAY" ), 0, 0 )
end

end



reaper.Undo_BeginBlock2( 0 )
ins_proj_marker()
reaper.Undo_EndBlock2( 0, "Insert project marker", -1 )

-- @description Play from mouse cursor with 2 sec shift (move edit cursor)
-- @author AZ
-- @version 1.0
-- @provides [main=main,midi_editor,midi_inlineeditor] .


mouse_pos = reaper.BR_PositionAtMouseCursor( true )

if mouse_pos > -1 then
  reaper.SetEditCurPos2( 0, mouse_pos -2, true, true )
  reaper.Main_OnCommandEx(1007, 0, 0)
end
reaper.defer(function() end)

-- @noindex

function ins_marker_mouse()
reaper.Main_OnCommandEx( 40513, 0, 0 )  --View: Move edit cursor to mouse cursor
reaper.Main_OnCommandEx( 40171, 0, 0 )  --Insert and/or edit marker at current position
reaper.SetEditCurPos2( 0, edit_cur_pos, false, false )
end

----------
----------

function ins_marker_play()
reaper.Main_OnCommandEx( 40434, 0, 0 )  --View: Move edit cursor to play cursor
reaper.Main_OnCommandEx( 40171, 0, 0 )  --Insert and/or edit marker at current position
reaper.SetEditCurPos2( 0, edit_cur_pos, false, false )
end

-------------------------------
-------------------------------

function ins_proj_marker()
edit_cur_pos = reaper.GetCursorPositionEx( 0 )
window, segment, details = reaper.BR_GetMouseCursorContext()

if window == "arrange" or window == "midi_editor" then
  pos =  reaper.BR_GetMouseCursorContext_Position()

  if window == "midi_editor" then
    if segment == "unknown"or segment == "notes"or segment == "cc_lane" then
    ins_marker_mouse()
    else
    ins_marker_play()
    end
  else
    ins_marker_mouse()
  end
else
  ins_marker_play()
end

end



reaper.Undo_BeginBlock2( 0 )
reaper.PreventUIRefresh( 1 )
ins_proj_marker()
reaper.PreventUIRefresh( -1 )
reaper.Undo_EndBlock2( 0, "Insert project marker", -1 )

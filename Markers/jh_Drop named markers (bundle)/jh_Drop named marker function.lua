-- @noindex

function Insert_Marker_Custom_Name(name)
  reaper.Undo_BeginBlock()
  cursor_pos = reaper.GetCursorPosition()
  play_pos = reaper.GetPlayPosition()
  marker_index, num_markersOut, num_regionsOut = reaper.CountProjectMarkers( 0 )
  reaper.AddProjectMarker( 0, 0, play_pos, 0, name, marker_index+1 )
  reaper.Undo_EndBlock("Insert_Marker_Custom_Name", 0)
  reaper.UpdateArrange()
end

-- @description Insert Start/End markers to Time Selection for Subprojects
-- @author Ugurcan Orcun
-- @version 1.0
-- @about Automatically inserts =START and =END to each side of time selection. Rendering Subprojects obey these two markers.

reaper.Undo_BeginBlock()
marker_start, marker_end = reaper.GetSet_LoopTimeRange(false, true, 0, 0, 0)

if marker_start < marker_end then
  reaper.AddProjectMarker(0, false, marker_start, 0, "=START", -1)
  reaper.AddProjectMarker(0, false, marker_end, 0, "=END", -1)
end

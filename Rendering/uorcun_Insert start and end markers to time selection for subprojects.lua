-- @description Insert =START and =END markers to time selection for subprojects
-- @author Ugurcan Orcun
-- @version 1.1
-- @changelog Script now first removes existing =START and =END markers to avoid confusion
-- @about Automatically inserts =START and =END markers to each side of time selection. Rendering Subprojects obey these two markers.

reaper.Undo_BeginBlock()
marker_start, marker_end = reaper.GetSet_LoopTimeRange(false, true, 0, 0, 0)

--Remove existing markers
for i = reaper.CountProjectMarkers(0), 0, -1 do
  a, b, c, d, name, index = reaper.EnumProjectMarkers2(0,i)
  if (name == "=START") or (name == "=END") then
    reaper.DeleteProjectMarkerByIndex(0, i)
  end
end

--Add new markers
if marker_start < marker_end then
  reaper.AddProjectMarker(0, false, marker_start, 0, "=START", -1)
  reaper.AddProjectMarker(0, false, marker_end, 0, "=END", -1)
end

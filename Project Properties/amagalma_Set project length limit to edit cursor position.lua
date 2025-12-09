-- @description Set project length limit to edit cursor position
-- @author amagalma
-- @version 1.02
-- @changelog - if mouse cursor hovers above timeline/ruler then set that position (snapped to grid)
-- @about - requires SWS extensions


if reaper.APIExists("SNM_SetDoubleConfigVar") then
  local wnd, seg, det = reaper.BR_GetMouseCursorContext()
  local position = (wnd == "ruler" and seg == "timeline" ) and 
                    reaper.SnapToGrid( 0, reaper.BR_GetMouseCursorContext_Position()) or
                    reaper.GetCursorPosition()
  reaper.SNM_SetDoubleConfigVar("projmaxlen", position)
  if reaper.SNM_GetIntConfigVar("projmaxlenuse", "-1234") ~= 1 then
    reaper.SNM_SetIntConfigVar("projmaxlenuse", 1)
  end
  reaper.UpdateTimeline()
else
  reaper.MB("Please, install SWS Extensions and run again.", "SWS Extensions are not installed!", 0)
end
reaper.defer(function() end)

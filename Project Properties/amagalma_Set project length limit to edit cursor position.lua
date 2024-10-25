-- @description Set project length limit to edit cursor position
-- @author amagalma
-- @version 1.01
-- @changelog - enable project limit, if not already enabled
-- @about - requires SWS extensions


if reaper.APIExists("SNM_SetDoubleConfigVar") then
  reaper.SNM_SetDoubleConfigVar("projmaxlen", reaper.GetCursorPosition())
  if reaper.SNM_GetIntConfigVar("projmaxlenuse", "-1234") ~= 1 then
    reaper.SNM_SetIntConfigVar("projmaxlenuse", 1)
  end
  reaper.UpdateTimeline()
else
  reaper.MB("Please, install SWS Extensions and run again.", "SWS Extensions are not installed!", 0)
end
reaper.defer(function() end)

-- @description Set project length limit to edit cursor position
-- @author amagalma
-- @version 1.00

if reaper.APIExists("SNM_SetDoubleConfigVar") then
  reaper.SNM_SetDoubleConfigVar("projmaxlen", reaper.GetCursorPosition())
  reaper.UpdateTimeline()
else
  reaper.MB("Please, install SWS Extensions and run again.", "SWS Extensions are not installed!", 0)
end
reaper.defer(function() end)

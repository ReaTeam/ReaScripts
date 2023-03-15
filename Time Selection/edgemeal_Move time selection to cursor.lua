-- @description Move time selection to cursor
-- @author Edgemeal
-- @version 1.0
-- @link Forum https://forum.cockos.com/showthread.php?p=2190109
-- @donation Donate https://www.paypal.me/Edgemeal

function Main()
  local start_time, end_time = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if start_time == end_time then return end
  local length = end_time-start_time
  local cursor = reaper.GetCursorPosition()
  reaper.GetSet_LoopTimeRange(true, false, cursor, cursor+length, false)
end

Main()
reaper.defer(function () end)
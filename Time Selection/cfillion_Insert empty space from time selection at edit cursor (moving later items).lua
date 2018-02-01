-- @description Insert empty space from time selection at edit cursor (moving later items)
-- @version 1.0
-- @author cfillion
-- @links
--   cfillion.ca https://cfillion.ca/
--   Request Post https://forum.cockos.com/showthread.php?p=1942464
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Insert+empty+space+from+time+selection+at+edit+cursor
-- @about
--   This is a wrapper around the native action "Time selection: Insert empty
--   space at time selection (moving later items)". Empty space is inserted at
--   edit cursor instead of at the start of the time selection.

local tstart, tend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

reaper.PreventUIRefresh(1)

local curPos = reaper.GetCursorPosition()
reaper.GetSet_LoopTimeRange(true, false, curPos, curPos + (tend - tstart), false)
reaper.Main_OnCommand(40200, 0) -- Time selection: Insert empty space at time selection (moving later items)
reaper.GetSet_LoopTimeRange(true, false, tstart, tend, false)

reaper.PreventUIRefresh(-1)

-- @description Set measure 1 to current edit cursor position (rounded)
-- @author BenjyO
-- @version 1.0
-- @changelog Initial release
-- @link https://forum.cockos.com/member.php?u=39350
-- @about
--   ### Set measure 1 to current edit cursor position (rounded)
--   - The script sets measure 1 to current edit cursor position and rounds it up or down (rounds ap at measure half-point). It works the same as the option in Project settings.
--   - Requires SWS extension to run

function Main()
	local cursor_pos = reaper.GetCursorPositionEx(0)
	local retval, measures, cml = reaper.TimeMap2_timeToBeats(0, cursor_pos)
	local measure_pos = measures + (retval / cml)
	local floor = math.floor(measure_pos)
	local ceil = math.ceil(measure_pos)
	local floor_diff = measure_pos - floor
	local ceil_diff = ceil - measure_pos
	if ceil_diff <= floor_diff then
		rounded_measure = ceil
	else
		rounded_measure = floor
	end	
	reaper.SNM_SetIntConfigVar("projmeasoffs", -rounded_measure)
end

local sws_exist = reaper.APIExists("SNM_SetIntConfigVar")
if sws_exist then
	Main()
	reaper.UpdateTimeline()
else
	reaper.ShowConsoleMsg("This script requires the SWS extension for REAPER. Please install it and try again.")
end

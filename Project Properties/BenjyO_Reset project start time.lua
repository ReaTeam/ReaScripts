-- @description Reset project start time
-- @author BenjyO
-- @version 1.0
-- @changelog Initial release
-- @link https://forum.cockos.com/member.php?u=39350
-- @about
--   ### Reset project start time
--   - The script sets 0:00 time to start of project. It works the same as the option in Project settings.
--   - Requires SWS extension to run.

local sws_exist = reaper.APIExists("SNM_SetDoubleConfigVar")
if sws_exist then
	reaper.SNM_SetDoubleConfigVar("projtimeoffs", 0)
	reaper.UpdateTimeline()
else
	reaper.ShowConsoleMsg("This script requires the SWS extension for REAPER. Please install it and try again.")
end

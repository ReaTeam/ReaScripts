-- @description Set timecode at edit cursor
-- @version 1.0
-- @author cfillion
-- @links
--   cfillion.ca https://cfillion.ca
--   Request Thread https://forum.cockos.com/showthread.php?t=202578
-- @screenshot https://i.imgur.com/uly6oy5.gif
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

assert(reaper.SNM_GetDoubleConfigVar, "SWS is required to use this script")

local curpos = reaper.GetCursorPosition()
local timecode = reaper.format_timestr_pos(curpos, '', 0)
local ok, csv = reaper.GetUserInputs(SCRIPT_NAME, 1, "Timecode,extrawidth=50", timecode)

if not ok then
  reaper.defer(function() end)
  return
end

timecode = reaper.parse_timestr(csv)

reaper.SNM_SetDoubleConfigVar('projtimeoffs', timecode - curpos)
reaper.UpdateTimeline()

-- @description Set timecode at edit cursor
-- @author cfillion
-- @version 1.2
-- @changelog Add a "set to 0" action
-- @provides
--   .
--   [main] . > cfillion_Set timecode at edit cursor (seconds).lua
--   [main] . > cfillion_Set timecode at edit cursor (frames).lua
--   [main] . > cfillion_Set timecode at edit cursor (set to 0).lua
-- @link
--   cfillion.ca https://cfillion.ca
--   Request Thread https://forum.cockos.com/showthread.php?t=202578
-- @screenshot https://i.imgur.com/uly6oy5.gif
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

local MODE = ({
  ['time'    ] =  0,
  ['seconds' ] =  3,
  ['frames'  ] =  5,
  ['set to 0'] = -1,
})[SCRIPT_NAME:match('%(([^%)]+)%)') or 'time']

assert(MODE, "Internal error: unknown timecode format")
assert(reaper.SNM_GetDoubleConfigVar, "SWS is required to use this script")

local curpos = reaper.GetCursorPosition()
local timecode = 0

if MODE >= 0 then
  timecode = reaper.format_timestr_pos(curpos, '', MODE)
  local ok, csv = reaper.GetUserInputs(SCRIPT_NAME, 1, "Timecode,extrawidth=50", timecode)

  if not ok then
    reaper.defer(function() end)
    return
  end

  timecode = reaper.parse_timestr_len(csv, 0, MODE)
end

reaper.SNM_SetDoubleConfigVar('projtimeoffs', timecode - curpos)
reaper.UpdateTimeline()

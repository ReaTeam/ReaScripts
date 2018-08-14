-- @description Delete last marker left of the play or edit cursor
-- @version 1.0
-- @author cfillion
-- @website cfillion.ca https://cfillion.ca
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Delete+last+marker+left+of+the+play+or+edit+cursor

local UNDO_STATE_MISCCFG = 8
local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

local function position()
  if reaper.GetPlayState() & 1 == 0 then
    return reaper.GetCursorPosition()
  else
    return reaper.GetPlayPosition2()
  end
end

local marker = reaper.GetLastMarkerAndCurRegion(0, position())

if marker > -1 then
  reaper.Undo_BeginBlock()
  reaper.DeleteProjectMarkerByIndex(0, marker)
  reaper.Undo_EndBlock(SCRIPT_NAME, UNDO_STATE_MISCCFG)
else
  reaper.defer(function() end) -- no undo point
end

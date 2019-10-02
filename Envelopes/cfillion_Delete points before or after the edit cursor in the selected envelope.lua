-- @description Delete points before or after the edit cursor in the selected envelope
-- @author cfillion
-- @version 1.0
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD
-- @metapackage
-- @provides
--   [main] . > cfillion_Delete points before the edit cursor in the selected envelope.lua
--   [main] . > cfillion_Delete points after the edit cursor in the selected envelope.lua

local UNDO_STATE_TRACKCFG = 1

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local before = scriptName:match('before')

reaper.Undo_BeginBlock();

(function()
  local env = reaper.GetSelectedEnvelope(0)
  if not env then return end

  local timeStart, timeEnd

  if before then
    timeStart, timeEnd = 0, reaper.GetCursorPosition()
  else
    local lastPoint = reaper.CountEnvelopePoints(env) - 1
    timeStart = reaper.GetCursorPosition()
    timeEnd = ({reaper.GetEnvelopePoint(env, lastPoint)})[2] + 1
  end

  reaper.DeleteEnvelopePointRange(env, timeStart, timeEnd)
  reaper.UpdateArrange()
end)()

reaper.Undo_EndBlock(scriptName, UNDO_STATE_TRACKCFG)

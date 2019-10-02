-- @description Delete points outside of the time selection in selected envelope
-- @author cfillion
-- @version 1.0
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

local UNDO_STATE_TRACKCFG = 1

reaper.Undo_BeginBlock();

(function()
  local env = reaper.GetSelectedEnvelope(0)
  if not env then return end

  local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if timeSelStart == timeSelEnd then return end

  reaper.DeleteEnvelopePointRange(env, 0, timeSelStart)

  local lastPoint = reaper.CountEnvelopePoints(env) - 1
  lastPointTime = ({reaper.GetEnvelopePoint(env, lastPoint)})[2]
  reaper.DeleteEnvelopePointRange(env, timeSelEnd, lastPointTime + 1)

  reaper.UpdateArrange()
end)()

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
reaper.Undo_EndBlock(scriptName, UNDO_STATE_TRACKCFG)

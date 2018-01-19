-- @description Move right edge of selected automation items to end of time selection
-- @version 1.0
-- @author cfillion
-- @link cfillion.ca https://cfillion.ca
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Move+right+edge+of+selected+automation+items+to+end+of+time+selection

local UNDO_STATE_TRACKCFG = 1

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

reaper.defer(function() end)

local tstart, tend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if tstart == tend then return end

local env = reaper.GetSelectedEnvelope(0)
if not env then return end

local bucket = {}

for i=0,reaper.CountAutomationItems(env)-1 do
  local selected = 1 == reaper.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, false)
  local startTime = reaper.GetSetAutomationItemInfo(env, i, 'D_POSITION', 0, false)
  local length = reaper.GetSetAutomationItemInfo(env, i, 'D_LENGTH', 0, false)

  if selected and startTime < tend then
    table.insert(bucket, {id=i, len=tend - startTime})
  end
end

if #bucket < 1 then return end

reaper.Undo_BeginBlock()

for _,ai in ipairs(bucket) do
  reaper.GetSetAutomationItemInfo(env, ai.id, 'D_LENGTH', ai.len, true)
end

reaper.Undo_EndBlock(script_name, UNDO_STATE_TRACKCFG)

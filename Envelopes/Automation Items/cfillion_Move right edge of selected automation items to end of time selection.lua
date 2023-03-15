-- @description Move left/right edge of selected automation items to start/end of time selection
-- @author cfillion
-- @version 1.1.1
-- @changelog Don't move envelope points along with the left edge
-- @provides
--   .
--   [main] . > cfillion_Move left edge of selected automation items to start of time selection.lua
-- @link cfillion.ca https://cfillion.ca
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Move+right+edge+of+selected+automation+items+to+end+of+time+selection

local UNDO_STATE_TRACKCFG = 1

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local right_edge = script_name:match('right edge')

reaper.defer(function() end)

local tstart, tend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if tstart == tend then return end

local env = reaper.GetSelectedTrackEnvelope(nil)
if not env then return end

local bucket = {}

for i=0,reaper.CountAutomationItems(env)-1 do
  local selected = 1 == reaper.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, false)
  local startTime = reaper.GetSetAutomationItemInfo(env, i, 'D_POSITION', 0, false)
  local length = reaper.GetSetAutomationItemInfo(env, i, 'D_LENGTH', 0, false)

  if selected and startTime < tend then
    if right_edge then
      table.insert(bucket, {id=i, len=tend - startTime})
    else
      local offset = startTime - tstart
      table.insert(bucket, {id=i, pos=tstart, len=length + offset, shift=offset})
    end
  end
end

if #bucket < 1 then return end

reaper.Undo_BeginBlock()

for _,ai in ipairs(bucket) do
  if ai.pos then
    reaper.GetSetAutomationItemInfo(env, ai.id, 'D_POSITION', ai.pos, true)
  end

  reaper.GetSetAutomationItemInfo(env, ai.id, 'D_LENGTH', ai.len, true)

  if ai.shift then
    local off = reaper.GetSetAutomationItemInfo(env, ai.id, 'D_STARTOFFS', 0, false)
    reaper.GetSetAutomationItemInfo(env, ai.id, 'D_STARTOFFS', off - ai.shift, true)
  end
end

reaper.Undo_EndBlock(script_name, UNDO_STATE_TRACKCFG)

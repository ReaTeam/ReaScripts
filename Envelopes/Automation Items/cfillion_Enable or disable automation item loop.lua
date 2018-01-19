-- @description Enable or disable automation item loop
-- @version 1.0
-- @author cfillion
-- @link cfillion.ca https://cfillion.ca
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Enable+or+disable+automation+item+loop
-- @provides
--   . > cfillion_Enable automation item loop.lua
--   . > cfillion_Disable automation item loop.lua

local UNDO_STATE_TRACKCFG = 1

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local newLoop = script_name:match('Enable') and 1 or 0

reaper.defer(function() end)

local env = reaper.GetSelectedTrackEnvelope(0)
if not env then return end

local bucket = {}

for i=0,reaper.CountAutomationItems(env)-1 do
  local selected = 1 == reaper.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, false)
  local looped = 0 ~= reaper.GetSetAutomationItemInfo(env, i, 'D_LOOPSRC', 0, false)

  if selected and looped ~= newLoop then
    table.insert(bucket, {id=i, loop=newLoop})
  end
end

if #bucket < 1 then return end

reaper.Undo_BeginBlock()

for _,ai in ipairs(bucket) do
  reaper.GetSetAutomationItemInfo(env, ai.id, 'D_LOOPSRC', ai.loop, true)
end

reaper.Undo_EndBlock(script_name, UNDO_STATE_TRACKCFG)

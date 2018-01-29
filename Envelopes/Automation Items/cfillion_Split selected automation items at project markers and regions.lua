-- @description Split selected automation items at markers and/or regions
-- @version 1.0
-- @author cfillion
-- @links cfillion.ca https://cfillion.ca
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD
-- @provides
--   . > cfillion_Split selected automation items at markers and regions.lua
--   . > cfillion_Split selected automation items at markers.lua
--   . > cfillion_Split selected automation items at regions.lua

local UNDO_STATE_TRACKCFG = 1
local SCRIPT_NAME = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

function testType(isrgn)
  return SCRIPT_NAME:match(isrgn and 'region' or 'marker')
end

function intersectSplits(env, from, to)
  local splits = {}

  for _, point in ipairs(splitPoints) do
    if point > from and point < to then
      table.insert(splits, point)
    end
  end

  return #splits > 0 and splits
end

splitPoints = (function()
  local points, marker = {}, {0}

  repeat
    -- integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber
    marker = {reaper.EnumProjectMarkers(marker[1])}

    if testType(marker[2]) then
      table.insert(points, marker[3])

      if marker[2] then
        table.insert(points, marker[4])
      end
    end
  until marker[1] == 0

  -- sorting to ensure region end points won't be before an earlier marker
  table.sort(points)

  return points
end)()

local bucket = {}

for ti=0,reaper.CountTracks(0)-1 do
  local track = reaper.GetTrack(0, ti)

  for ei=0,reaper.CountTrackEnvelopes(track)-1 do
    local env = reaper.GetTrackEnvelope(track, ei)

    for ai=0,reaper.CountAutomationItems(env)-1 do
      local selected = 1 == reaper.GetSetAutomationItemInfo(env, ai, 'D_UISEL', 0, false)
      local startTime = reaper.GetSetAutomationItemInfo(env, ai, 'D_POSITION', 0, false)
      local length = reaper.GetSetAutomationItemInfo(env, ai, 'D_LENGTH', 0, false)

      local splits = selected and intersectSplits(env, startTime, startTime+length)

      if splits then
        table.insert(bucket, {env=env, id=ai, pos=startTime, len=length, splits=splits})
      end
    end
  end
end

if #bucket < 1 then
  reaper.defer(function() end)
end

reaper.Undo_BeginBlock()

local reselect = {}

for _, ai in ipairs(bucket) do
  local poolId = reaper.GetSetAutomationItemInfo(ai.env, ai.id, 'D_POOL_ID', 0, false)
  table.insert(reselect, ai)

  for id, point in ipairs(ai.splits) do
    local length = (ai.splits[id+1] or (ai.pos+ai.len)) - point
    local offset = point - ai.pos

    if id == 1 then
      reaper.GetSetAutomationItemInfo(ai.env, ai.id, 'D_LENGTH', offset, true)
    end

    local newId = reaper.InsertAutomationItem(ai.env, poolId, point, length)
    reaper.GetSetAutomationItemInfo(ai.env, newId, 'D_STARTOFFS', offset, true)

    table.insert(reselect, {env=ai.env, id=newId})
  end
end

for _, ai in ipairs(reselect) do
  reaper.GetSetAutomationItemInfo(ai.env, ai.id, 'D_UISEL', 1, true)
end

reaper.Undo_EndBlock(SCRIPT_NAME, UNDO_STATE_TRACKCFG)

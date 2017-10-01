-- @description Automation item selection bundle (10 actions)
-- @version 1.0
-- @author cfillion
-- @provides
--   [main] . > cfillion_Select and move to next automation item.lua
--   [main] . > cfillion_Select and move to next automation item in pool.lua
--   [main] . > cfillion_Select and move to previous automation item.lua
--   [main] . > cfillion_Select and move to previous automation item in pool.lua
--   [main] . > cfillion_Add next automation item to selection.lua
--   [main] . > cfillion_Add next automation item in pool to selection.lua
--   [main] . > cfillion_Add previous automation item to selection.lua
--   [main] . > cfillion_Add previous automation item in pool to selection.lua
--   [main] . > cfillion_Select all automation items.lua
--   [main] . > cfillion_Select all automation items in pool.lua
-- @about
--   # Automation item selection bundle
--
--   This package provides in total 10 actions for selecting automation items in
--   the selected envelope lane. See the Contents tab for the list and for the
--   exact name of the actions.
--
--   - Actions for selecting and moving to the next or previous AIs
--   - Actions for preserving the current selection
--   - Actions for cycling through the AIs in the selected pool
--   - Actions for selecting all AIs or all AIs in the selected pool

local UNDO_STATE_TRACKCFG = 1

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

local poolMode = name:match('pool')
local addToSelMode = name:match('Add.+to selection')
local prevMode = name:match('previous')
local entireBucketMode = name:match('all')

-- local poolMode = false
-- local addToSelMode = false
-- local prevMode = false
-- local entireBucketMode = false

local env = reaper.GetSelectedEnvelope(0)
if not env then
  reaper.defer(function() end)
  return
end

local count = reaper.CountAutomationItems(env)
if count < 1 then
  reaper.defer(function() end)
  return
end

local buckets = {}
local currentSel, currentBucket = {}, 0

for i=0,count-1 do
  local selected = 1 == reaper.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, false)
  local bucketId = 0
  local startTime = reaper.GetSetAutomationItemInfo(env, i, 'D_POSITION', 0, false)

  if poolMode then
    bucketId = reaper.GetSetAutomationItemInfo(env, i, 'D_POOL_ID', 0, false)
  end
  
  if selected and poolMode and currentBucket == 0 then
    currentBucket = bucketId
  end

  if selected then
    table.insert(currentSel, i)
  end

  if not selected or entireBucketMode then
    local ai = {id=i, pos=startTime}

    if buckets[bucketId] then
      table.insert(buckets[bucketId], ai)
    else
      buckets[bucketId] = {ai}
    end
  end
end

local bucket = buckets[currentBucket] or {}
if #bucket == 0 then
  reaper.defer(function() end)
  return
end

local target

-- fallback target
if prevMode then
  target = #bucket
else
  target = 1
end

-- find next or previous target
if #currentSel > 0 and not entireBucketMode then
  if prevMode then
    local firstSel = currentSel[1]
        
    for ri=0,#bucket-1 do
      local bid = #bucket - ri
      if bucket[bid].id < firstSel then
        target = bid
        break
      end
    end
  else
    local lastSel = currentSel[#currentSel]
    
    for i,ai in ipairs(bucket) do
      if ai.id > lastSel then
        target = i
        break
      end
    end
  end
end

reaper.Undo_BeginBlock()

if not addToSelMode then
  for _,ai in ipairs(currentSel) do
    reaper.GetSetAutomationItemInfo(env, ai, 'D_UISEL', 0, true)
  end
  
  if not entireBucketMode then
    reaper.SetEditCurPos(bucket[target].pos, true, false)
  end
end

if entireBucketMode then
  for _,ai in ipairs(bucket) do
    reaper.GetSetAutomationItemInfo(env, ai.id, 'D_UISEL', 1, true)
  end
else
  reaper.GetSetAutomationItemInfo(env, bucket[target].id, 'D_UISEL', 1, true)
end

reaper.Undo_EndBlock(name, UNDO_STATE_TRACKCFG)

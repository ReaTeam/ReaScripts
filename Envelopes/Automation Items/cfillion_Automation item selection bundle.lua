-- @description Automation item selection bundle
-- @version 1.1
-- @changelog
--   Add actions for unselecting all automations items (+ in pool)
--   Add actions selecting/adding to selection the automation item under edit and mouse cursor
-- @author cfillion
-- @provides
--   . > cfillion_Select and move to next automation item.lua
--   . > cfillion_Select and move to next automation item in pool.lua
--   . > cfillion_Select and move to previous automation item.lua
--   . > cfillion_Select and move to previous automation item in pool.lua
--
--   . > cfillion_Add next automation item to selection.lua
--   . > cfillion_Add next automation item in pool to selection.lua
--   . > cfillion_Add previous automation item to selection.lua
--   . > cfillion_Add previous automation item in pool to selection.lua
--   . > cfillion_Add all automation items under edit cursor to selection.lua
--   . > cfillion_Add all automation items under mouse cursor to selection.lua
--
--   . > cfillion_Select all automation items.lua
--   . > cfillion_Select all automation items in pool.lua
--   . > cfillion_Select all automation items under edit cursor.lua
--   . > cfillion_Select all automation items under mouse cursor.lua
--
--   . > cfillion_Unselect all automation items.lua
--   . > cfillion_Unselect all automation items in pool.lua
--   . > cfillion_Unselect all automation items under edit cursor.lua
--   . > cfillion_Unselect all automation items under mouse cursor.lua
-- @about
--   # Automation item selection bundle
--
--   This package provides a total of 18 actions for selecting or unselecting
--   automation items in the selected envelope lane. See the Contents tab for
--   the list and for the exact name of the actions.
--
--   - Actions for selecting and moving to the next or previous AIs
--   - Actions for preserving the current selection
--   - Actions for cycling through the AIs in the selected pool
--   - Actions for selecting or unselecting all AIs, AIs in the selected pool,
--   under the edit cursor and under the mouse cursor
-- @link
--   cfillion's website https://cfillion.ca
--   Original request https://github.com/reaper-oss/sws/issues/899
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Automation+item+selection+bundle

local UNDO_STATE_TRACKCFG = 1

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

local moveMode = name:match('move to')
local poolMode = name:match('pool')
local addToSelMode = name:match('Add.+to selection')
local prevMode = name:match('previous')
local entireBucketMode = name:match('all')
local unselectMode = name:match('Unselect')
local editCursorMode = name:match('under edit cursor')
local mouseCursorMode = name:match('under mouse cursor')

function testCursorPosition(env, startTime, endTime)
  local curPos

  if editCursorMode then
    curPos = reaper.GetCursorPosition()
  elseif mouseCursorMode then
    reaper.BR_GetMouseCursorContext()
    if reaper.BR_GetMouseCursorContext_Envelope() == env then
      curPos = reaper.BR_GetMouseCursorContext_Position()
    else
      return false
    end
  else
    return true
  end

  return startTime <= curPos and endTime >= curPos
end

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
  local length = reaper.GetSetAutomationItemInfo(env, i, 'D_LENGTH', 0, false)
  local underCursor = testCursorPosition(env, startTime, startTime + length)

  if poolMode then
    bucketId = reaper.GetSetAutomationItemInfo(env, i, 'D_POOL_ID', 0, false)
  end
  
  if selected and poolMode and currentBucket == 0 then
    currentBucket = bucketId
  end

  if selected then
    table.insert(currentSel, i)
  end

  if (not selected or entireBucketMode or unselectMode) and underCursor then
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

if not addToSelMode and not unselectMode then
  for _,ai in ipairs(currentSel) do
    reaper.GetSetAutomationItemInfo(env, ai, 'D_UISEL', 0, true)
  end
  
  if moveMode then
    reaper.SetEditCurPos(bucket[target].pos, true, false)
  end
end

local sel = unselectMode and 0 or 1

if entireBucketMode then
  for _,ai in ipairs(bucket) do
    reaper.GetSetAutomationItemInfo(env, ai.id, 'D_UISEL', sel, true)
  end
else
  reaper.GetSetAutomationItemInfo(env, bucket[target].id, 'D_UISEL', sel, true)
end

reaper.Undo_EndBlock(name, UNDO_STATE_TRACKCFG)

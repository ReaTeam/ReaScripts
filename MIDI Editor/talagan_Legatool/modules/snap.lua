-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of Legatool
-- LARGELY RE-ADAPTED from One Small Step snap logic

local D = {
  QN_TOLERANCE = 0.0001
}

local function moveComparatorHelper(v, cursor, best, direction, mode)

  -- mode could be "TIME", "PPQ", "QN"

  if direction > 0 then
    if (v > cursor) and ((best == nil) or (v < best)) then
      best = v
    end
  else
    if (v < cursor) and ((best == nil) or (v > best)) then
      best = v
    end
  end

  return best
end

-- This gives a new value for bestjumptime, aligned on the given the grid (item or project)
local function gridSnapHelper(type, direction, cursorTime, cursorQN, bestJumpTime, take, itemStartTime, itemEndTime)

  local grid_len, swing, swingmode = nil , nil, nil

  if type == "ITEM" then
    grid_len, swing, _  = reaper.MIDI_GetGrid(take)
  else
    _, grid_len, swingmode, swing = reaper.GetSetProjectGrid(0, false)
    grid_len = grid_len * 4 -- put back in QN
    if swingmode ~= 1 then
      swing = 0
    end
  end

  local cursorBars                      = reaper.TimeMap_QNToMeasures(0, cursorQN) - 1
  local _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorBars)

  if cursorBars > 0 and direction < 0 and math.abs(cursorQN - measureStartQN) < D.QN_TOLERANCE then
    -- Cursor is aligned on the beginning of a measure but we're going back.
    -- Work with the precedent measure.
    cursorBars = cursorBars - 1
    _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorBars)
  end

  -- Start with window, and slide
  -- The odd/even logic is for handling the swing

  local parity      = 1

  local oddOffset   = grid_len * (1 + swing * 0.5)
  local evenOffset  = grid_len * (1 - swing * 0.5)

  local prec = measureStartQN
  local next = prec + ((parity == 1) and (oddOffset) or (evenOffset))

  while next < (cursorQN - D.QN_TOLERANCE) do
    parity = parity ~ 1
    prec = next
    next = prec + ((parity == 1) and (oddOffset) or (evenOffset))
  end

  if math.abs(cursorQN - next) < D.QN_TOLERANCE then
    parity  = parity ~ 1
    next    = next + ((parity == 1) and (oddOffset) or (evenOffset))
  end

  local precTime = reaper.TimeMap2_QNToTime(0, prec)
  local nextTime = reaper.TimeMap2_QNToTime(0, next)
  local msTime   = reaper.TimeMap2_QNToTime(0, measureStartQN)
  local meTime   = reaper.TimeMap2_QNToTime(0, measureEndQN)

  -- Only add these times if they belong to the item (outside, consider there's no grid)
  if type == "PROJECT" or (precTime >= itemStartTime and precTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(precTime, cursorTime, bestJumpTime, direction, "TIME")
  end
  if type == "PROJECT" or (nextTime >= itemStartTime and nextTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(nextTime, cursorTime, bestJumpTime, direction, "TIME")
  end
  if type == "PROJECT" or  (msTime >= itemStartTime and msTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(msTime,   cursorTime, bestJumpTime, direction, "TIME")
  end
  if type == "PROJECT" or  (meTime >= itemStartTime and meTime <= itemEndTime) then
    bestJumpTime = moveComparatorHelper(meTime,   cursorTime, bestJumpTime, direction, "TIME")
  end

  return bestJumpTime
end


-- Resolves the next snap point.
-- Track can be nil (won't happen)
local function nextSnap(take, direction, reftime)

  local cursorTime      = reftime -- I don't want to rename everything ...
  local cursorQN        = reaper.TimeMap2_timeToQN(0, cursorTime)
  local bestJumpTime    = nil
  local maxTime         = 0
  local mediaItem       = reaper.GetMediaItemTake_Item(take)
  local itemStartTime   = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local itemEndTime     = itemStartTime + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")

  if itemEndTime > maxTime then
    maxTime = itemEndTime
  end

  -- A few conditions to avoid exploring the item if not needed
  if (direction > 0) then
    if (itemEndTime < cursorTime) or ((bestJumpTime ~= nil) and (bestJumpTime < itemStartTime)) then
      goto finish
    end
  else
    if (itemStartTime > cursorTime) or ((bestJumpTime ~= nil) and (bestJumpTime > itemEndTime)) then
      goto finish
    end
  end

  -- Test item boundaries
  bestJumpTime = moveComparatorHelper(itemStartTime,  cursorTime, bestJumpTime, direction, "TIME")
  bestJumpTime = moveComparatorHelper(itemEndTime,    cursorTime, bestJumpTime, direction, "TIME")

  -- Then try to find better snap in item
  bestJumpTime = gridSnapHelper("ITEM", direction, cursorTime, cursorQN, bestJumpTime, take, itemStartTime, itemEndTime)

  ::finish::

  return {
    time = bestJumpTime,
    ppq  = bestJumpTime and reaper.MIDI_GetPPQPosFromProjTime(take, bestJumpTime),
    qn   = bestJumpTime and reaper.TimeMap2_timeToQN(0, bestJumpTime)
  }
end

return {
  nextSnap            = nextSnap
}

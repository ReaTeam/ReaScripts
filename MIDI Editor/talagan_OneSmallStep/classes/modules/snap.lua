-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local S = require "modules/settings"
local N = require "modules/notes"
local D = require "modules/defines"

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
local function nextSnap(track, direction, reftime, options)

  local cursorTime      = reftime -- I don't want to rename everything ...
  local cursorQN        = reaper.TimeMap2_timeToQN(0, cursorTime)
  local bestJumpTime    = nil
  local maxTime         = 0

  -- If one of these options is on, we need to do a full dig of items
  local snapItemThings  = options.itemGrid or options.itemBounds or options.noteStart or options.noteEnd

  if snapItemThings and track then

    -- Force Item Bounds when we have item grid on, that's usefule outside items
    if options.itemGrid then
      options.itemBounds = true
    end

    local itemCount     = reaper.CountTrackMediaItems(track)
    local ii            = 0

    -- For optimization, we should randomize the order of iteration over the items
    while ii < itemCount do
      local mediaItem        = reaper.GetTrackMediaItem(track, ii)

      local itemStartTime    = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
      local itemEndTime      = itemStartTime + reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")

      if itemEndTime > maxTime then
        maxTime = itemEndTime
      end

      -- A few conditions to avoid exploring the item if not needed
      if (direction > 0) then
        if (itemEndTime < cursorTime) or ((bestJumpTime ~= nil) and (bestJumpTime < itemStartTime)) then
          goto nextitem
        end
      else
        if (itemStartTime > cursorTime) or ((bestJumpTime ~= nil) and (bestJumpTime > itemEndTime)) then
          goto nextitem
        end
      end

      if options.itemBounds then
        bestJumpTime = moveComparatorHelper(itemStartTime,  cursorTime, bestJumpTime, direction, "TIME")
        bestJumpTime = moveComparatorHelper(itemEndTime,    cursorTime, bestJumpTime, direction, "TIME")
      end

      if options.noteStart or options.noteEnd or options.itemGrid then
        local takeCount = reaper.GetMediaItemNumTakes(mediaItem)
        local ti        = 0

        while ti < takeCount do

          local take            = reaper.GetMediaItemTake(mediaItem, ti)

          local itemStartPPQ    = reaper.MIDI_GetPPQPosFromProjTime(take, itemStartTime)
          local itemEndPPQ      = reaper.MIDI_GetPPQPosFromProjTime(take, itemEndTime)
          local cursorPPQ       = reaper.MIDI_GetPPQPosFromProjTime(take, cursorTime)
          local bestJumpPPQ     = nil

          if options.noteStart or options.noteEnd then
            local _, notecnt, _, _ = reaper.MIDI_CountEvts(take)
            local ni = 0

            while (ni < notecnt) do
              local n = N.GetNote(take, ni)

              if options.noteStart then
                bestJumpPPQ = moveComparatorHelper(n.startPPQ, cursorPPQ, bestJumpPPQ, direction, "PPQ")
              end

              if options.noteEnd then
                bestJumpPPQ = moveComparatorHelper(n.endPPQ, cursorPPQ, bestJumpPPQ, direction, "PPQ")
              end

              ni = ni+1
            end -- end note iteration

            if bestJumpPPQ then
              -- Found a snap note inside item, convert back to time and compare to already found bestJumpTime
              local bjt    = reaper.TimeMap2_QNToTime(0, reaper.MIDI_GetProjQNFromPPQPos(take, bestJumpPPQ))
              bestJumpTime = moveComparatorHelper(bjt, cursorTime, bestJumpTime, direction, "TIME")
            end
          end

          if options.itemGrid then
            bestJumpTime = gridSnapHelper("ITEM", direction, cursorTime, cursorQN, bestJumpTime, take, itemStartTime, itemEndTime)
          end

          ti = ti + 1
        end -- end take iteration

      end

      ::nextitem::
      ii = ii+1
    end -- end item iteration
  end -- end options.enabled

  if options.projectGrid then
    -- SWS version of BR_GetNextGrid has a bug, use my own implementation
    bestJumpTime = gridSnapHelper("PROJECT", direction, cursorTime, cursorQN, bestJumpTime)
  end

  -- Add track boundaries
  if options.projectBounds then
    bestJumpTime = moveComparatorHelper(0,        cursorTime, bestJumpTime, direction, "TIME")
    bestJumpTime = moveComparatorHelper(maxTime,  cursorTime, bestJumpTime, direction, "TIME")

    if not bestJumpTime then
      -- No boundaries worked? The cursor is one of them.
      bestJumpTime = cursorTime
    end
  end

  return {
    time = bestJumpTime,
    qn   = bestJumpTime and reaper.TimeMap2_timeToQN(0, bestJumpTime)
  }
end

local function snapOptions()
  return {
    -- Item related
    noteStart     = S.getSetting("SnapNotes"),
    noteEnd       = S.getSetting("SnapNotes"),
    itemGrid      = S.getSetting("SnapItemGrid"),
    itemBounds    = S.getSetting("SnapItemBounds"),
    -- Larger
    projectGrid   = S.getSetting("SnapProjectGrid"),
    projectBounds = true
  }
end

local function nextSnapFromCursor(track, direction)
  return nextSnap(track, direction, reaper.GetCursorPosition(), snapOptions())
end

return {
  nextSnap            = nextSnap,
  nextSnapFromCursor  = nextSnapFromCursor
}

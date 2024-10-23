-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local D = require "modules/defines"
local S = require "modules/settings"

local function bool2sign(b)
  return ((b == true) and (1) or (-1))
end

local function PPQIsAfterPPQ(ppq1, ppq2, strict)
  return ppq1 > (ppq2 + bool2sign(strict) * D.PPQ_TOLERANCE)
end
local function PPQIsBeforePPQ(ppq1, ppq2, strict)
  return ppq1 < (ppq2 - bool2sign(strict) * D.PPQ_TOLERANCE)
end
local function PPQIsOnPPQ(ppq1, ppq2)
  return math.abs(ppq1 - ppq2) < D.PPQ_TOLERANCE
end

local function noteStartsAfterPPQ(note, limit, strict)
  return PPQIsAfterPPQ(note.startPPQ, limit, strict)
end
local function noteStartsBeforePPQ(note, limit, strict)
  return PPQIsBeforePPQ(note.startPPQ, limit, strict)
end
local function noteStartsOnPPQ(note, limit)
  return PPQIsOnPPQ(note.startPPQ, limit)
end

local function noteEndsAfterPPQ(note, limit, strict)
  return PPQIsAfterPPQ(note.endPPQ, limit, strict)
end
local function noteEndsBeforePPQ(note, limit, strict)
  return PPQIsBeforePPQ(note.endPPQ, limit, strict)
end
local function noteEndsOnPPQ(note, limit)
  return PPQIsOnPPQ(note.endPPQ, limit)
end

local function noteStartsInWindowPPQ(note, left, right, strict)
  local a = noteStartsAfterPPQ(note, left, strict)
  local e = noteStartsBeforePPQ(note, right, strict)

  return a and e
end
local function noteEndsInWindowPPQ(note, left, right, strict)
  local a = noteEndsAfterPPQ(note, left, strict)
  local e = noteEndsBeforePPQ(note, right, strict)

  return a and e
end

local function noteContainsPPQ(note, ppq, strict)
  local a = noteStartsBeforePPQ(note, ppq, strict)
  local e = noteEndsAfterPPQ(note, ppq, strict)

  return a and e
end

local function PPQRound(ppq)
  return math.floor(ppq + 0.5) -- Compensate floating errors
end

-- This converts the note length in PPQ from the QN value
-- For rounding reasons it's very important to work in PPQ
-- During the whole processes
local function NoteLenQN2PPQ(take, note_len_qn)
  local mediaItem       = reaper.GetMediaItemTake_Item(take)
  local itemStartTime   = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local itemStartPPQ    = reaper.MIDI_GetPPQPosFromProjTime(take, itemStartTime)
  local itemStartQN     = reaper.TimeMap2_timeToQN(0, itemStartTime)
  local itemPlusNoteQN  = itemStartQN + note_len_qn
  local itemPlusNotePPQ = reaper.MIDI_GetPPQPosFromProjQN(take, itemPlusNoteQN)
  local ret             = itemPlusNotePPQ - itemStartPPQ

  return PPQRound(ret)
end

local function TimeRoundBasedOnPPQ(take, time)
  local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, time)
  return reaper.MIDI_GetProjTimeFromPPQPos(take, PPQRound(ppq))
end


local function swingNoteLenQN(measureStartQN, posQN, noteLenQN, swing)
  local elapsedDoubleBeats  = (posQN - measureStartQN)/(2*noteLenQN)
  -- Hack, it may happen that the cursor is just before the measure start
  if elapsedDoubleBeats < 0 then
    elapsedDoubleBeats = 0
  end

  local eaten           = elapsedDoubleBeats - math.floor(elapsedDoubleBeats)
  local qn_tolerance    = 0.01 -- Beware, this should be a bit tolerant since the swing is not aligned on PPQs

  if eaten > 1 - qn_tolerance/noteLenQN then
    -- Hack : cursor may be very close to next double beat.
    eaten = 0
  end

  local onbeat              = (1 + swing * 0.5)
  local offbeat             = (1 - swing * 0.5)
  local onbeatlimit         = onbeat - (qn_tolerance / noteLenQN)

  if (2 * eaten) < onbeatlimit  then
    return (noteLenQN * onbeat)
  else
    return (noteLenQN * offbeat)
  end
end

local function ResolveNoteLenQN(take)

  local nlm                             = S.getNoteLenParamSource()

  local cursorTime                      = reaper.GetCursorPosition()
  local cursorQN                        = reaper.TimeMap2_timeToQN(0, cursorTime)

  local cursorMes                       = reaper.TimeMap_QNToMeasures(0, cursorQN)
  local _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorMes - 1)

  if math.abs(cursorQN - measureEndQN) < D.QN_TOLERANCE then
    -- We're on the measure end, advance 1 measure
    cursorMes = cursorMes + 1
    _, measureStartQN, measureEndQN = reaper.TimeMap_GetMeasureInfo(0, cursorMes - 1)
  end

  if nlm == D.NoteLenParamSource.OSS then
    return S.getNoteLenQN() * S.getNoteLenModifierFactor()
  elseif nlm == D.NoteLenParamSource.ProjectGrid then

    local _, division, swingmode, swing   = reaper.GetSetProjectGrid(0, false)
    local noteLenQN                       = division * 4
    local multFactor                      = S.getNoteLenQN()

    local baselen = 1
    if swingmode == 0 then
      -- No swing
      baselen = noteLenQN
    elseif swingmode == 3 then
      -- Project Grid is set to "measure"
      baselen = (measureEndQN - measureStartQN)
    else
      -- Swing
      if multFactor > 1 then
        baselen = noteLenQN
      else
        baselen = swingNoteLenQN(measureStartQN, cursorQN, noteLenQN, swing)
      end
    end

    return baselen * S.getNoteLenQN() * S.getNoteLenModifierFactor()

  else
    local gridLenQN, swing, noteLenQN = reaper.MIDI_GetGrid(take);
    local multFactor = S.getNoteLenQN()

    if noteLenQN == 0 then
      noteLenQN = gridLenQN
    end

    local baselen = 1
    if swing == 0 then
      baselen = noteLenQN
    else
      -- Swing
      if multFactor > 1 then
        baselen = noteLenQN
      else
        baselen = swingNoteLenQN(measureStartQN, cursorQN, noteLenQN, swing)
      end
    end

    return baselen * S.getNoteLenQN() * S.getNoteLenModifierFactor()
  end
end

local function ResolveNoteLenPPQ(take)
  return NoteLenQN2PPQ(take, ResolveNoteLenQN(take))
end


local function KeepEditCursorOnScreen()
  local start_time, end_time = reaper.GetSet_ArrangeView2(0, false, 0, 0, 0, 0)
  local cursor_time = reaper.GetCursorPosition()
  local diff_time = end_time - start_time
  local bound     = 0.05
  local alpha     = 0.25

  if cursor_time < start_time + bound * diff_time then
    reaper.GetSet_ArrangeView2(0, true, 0, 0, cursor_time - diff_time * alpha, cursor_time + diff_time * (1 - alpha))
  end

  if cursor_time > end_time - bound * diff_time then
    reaper.GetSet_ArrangeView2(0, true, 0, 0, cursor_time - diff_time * (1-alpha), cursor_time + diff_time * alpha)
  end
end

local function MediaItemContainsCursor(mediaItem, CursorPos)
  local pos       = reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION")
  local len       = reaper.GetMediaItemInfo_Value(mediaItem, "D_LENGTH")

  local left  = pos - D.TIME_TOLERANCE;
  local right = pos + len + D.TIME_TOLERANCE;

  -- Only keep items that contain the cursor pos
  return (CursorPos >= left) and (CursorPos <= right);
end

return {
  PPQRound = PPQRound,

  PPQIsAfterPPQ         = PPQIsAfterPPQ,
  PPQIsBeforePPQ        = PPQIsBeforePPQ,
  PPQIsOnPPQ            = PPQIsOnPPQ,

  noteStartsAfterPPQ    = noteStartsAfterPPQ,
  noteStartsBeforePPQ   = noteStartsBeforePPQ,
  noteStartsOnPPQ       = noteStartsOnPPQ,
  noteStartsInWindowPPQ = noteStartsInWindowPPQ,

  noteEndsAfterPPQ      = noteEndsAfterPPQ,
  noteEndsBeforePPQ     = noteEndsBeforePPQ,
  noteEndsOnPPQ         = noteEndsOnPPQ,
  noteEndsInWindowPPQ   = noteEndsInWindowPPQ,
  noteContainsPPQ       = noteContainsPPQ,

  TimeRoundBasedOnPPQ   = TimeRoundBasedOnPPQ,

  ResolveNoteLenPPQ     = ResolveNoteLenPPQ,

  KeepEditCursorOnScreen = KeepEditCursorOnScreen,
  MediaItemContainsCursor = MediaItemContainsCursor
}

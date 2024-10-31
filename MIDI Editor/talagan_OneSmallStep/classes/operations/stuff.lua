-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local T   = require "modules/time"
local S   = require "modules/settings"
local D   = require "modules/defines"
local N   = require "modules/notes"
local MK  = require "modules/markers"
local ART = require "modules/articulations"

local GEN = require "operations/generic"
local MU  = require "lib/MIDIUtils"

local USE_MU = true

local function getStuffingBaseLength(take, markerPPQ, cursorPPQ)

  local _, notecnt, _, _  = N.CountEvts(take, USE_MU)

  local ret = nil

  -- First, examine in priority notes beginning before the region or at start of the region
  local ni = 0
  while ni < notecnt do
    local n = N.GetNote(take, ni)

    if T.noteStartsBeforePPQ(n, markerPPQ, false) and T.noteEndsBeforePPQ(n, cursorPPQ, false) then
      local reflen = n.endPPQ - markerPPQ
      if not ret or reflen > ret then
        ret = reflen
      end
    end

    ni = ni + 1
  end

  if ret then
    return ret
  end

  -- Then examine notes starting and ending in the window
  local firstone = nil
  local ni = 0
  while ni < notecnt do
    local n = N.GetNote(take, ni, USE_MU)

    if T.noteStartsAfterPPQ(n, markerPPQ, false) and T.noteEndsBeforePPQ(n, cursorPPQ, false) then
      if not firstone or n.startPPQ < firstone.startPPQ then
        firstone = n
      end
    end

    ni = ni + 1
  end

  if firstone then
    return firstone.endPPQ - firstone.startPPQ
  end

  return 0
end

local function Stuff(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local c         = GEN.BuildForwardContext(km, track, take)
  local newMaxQN  = c.advanceQN

  if c.markerTime >= c.cursorTime then
    -- Not possible
    return
  end

  reaper.Undo_BeginBlock();

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  local sbl               = getStuffingBaseLength(take, c.markerPPQ, c.cursorPPQ) * S.getNoteLenQN() * S.getNoteLenModifierFactor()
  local compFactor        = (c.cursorPPQ - c.markerPPQ) / (sbl + (c.cursorPPQ - c.markerPPQ))
  local extPPQ            = sbl * compFactor

  local _comp = function(ppq)
    if sbl == 0 then
      return c.markerPPQ
    else
      return T.PPQRound(c.markerPPQ + compFactor * (ppq - c.markerPPQ))
    end
  end

  local _isNoteHeld = function(pitch, chan)
    for nhi = 1, #notes_to_extend do
      local nex = notes_to_extend[nhi]
      if nex.chan == chan and nex.pitch == pitch then
        return true, nhi
      end
    end
    return false, -1
  end

  local _, notecnt, _, _  = reaper.MIDI_CountEvts(take)
  local ni = 0
  while (ni < notecnt) do

    -- Examine each note in item
    local n = N.GetNote(take, ni)

    if T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
      --
      --     M     C
      --     |     |
      --     |     | ====
      --     |     |
      --
    elseif T.noteStartsAfterPPQ(n, c.markerPPQ, false) then
      if T.noteEndsBeforePPQ(n, c.cursorPPQ, false) then
        --
        --     M     C
        --     |     |
        --     | === |
        --     |     |
        --
        local isheld, hidx = _isNoteHeld(n.pitch, n.chan)
        local offset       = 0
        if isheld and T.noteEndsOnPPQ(n, c.cursorPPQ) then
          table.remove(notes_to_extend, hidx)
          offset = extPPQ
        end

        N.SetNewNoteBounds(n, take, _comp(n.startPPQ), _comp(n.endPPQ) + offset)
        N.MUCommitNote(take, n)

        c.counts.ext = c.counts.ext + 1
      else
        --
        --     M     C
        --     |     |
        --     |   ==|===
        --     |     |
        --
        N.SetNewNoteBounds(n, take, _comp(n.startPPQ), n.endPPQ)
        N.MUCommitNote(take, n)

        c.counts.ext = c.counts.ext + 1
      end
    else
      if T.noteEndsAfterPPQ(n, c.cursorPPQ, false) then
        --
        --     M     C
        --     |     |
        --   ==|=====|===
        --     |     |
        --
      elseif T.noteEndsAfterPPQ(n, c.markerPPQ, true) then
        --
        --     C     A
        --     |     |
        --   ==|===  |
        --     |     |
        --
        N.SetNewNoteBounds(n, take, n.startPPQ, _comp(n.endPPQ))
        N.MUCommitNote(take, n)

        c.counts.ext = c.counts.ext + 1
      else
        --
        --     C     A
        --     |     |
        -- === |     |
        --     |     |
        --
      end
    end

    ni = ni + 1;
  end

  -- We've extended what we could, other candidates should be added
  -- Concat notes_to_extend that haven't been used to notes_to_add
  for i=1,#notes_to_extend do
    notes_to_add[#notes_to_add+1] = notes_to_extend[i]
  end

  for i=1,#notes_to_add do
    local newn = N.BuildFromManager(notes_to_add[i], c.take, _comp(c.cursorPPQ), c.cursorPPQ)

    N.MUCommitNote(take, newn)

    c.counts.add = c.counts.add + 1
  end

  -- Pass nil as jump time, we don't want to jump in stuff mode
  GEN.ForwardOperationFinish(c, nil, newMaxQN)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(1, c.counts),-1);
end


local function getStuffingBackLength(take, markerPPQ, cursorPPQ)
  local ret   = cursorPPQ - markerPPQ
  local found = false

  local _, notecnt, _, _  = N.CountEvts(take, USE_MU)
  local ni = 0

  -- Look for notes ending on the and starting in the window
  while ni < notecnt do
    local n = N.GetNote(take, ni)

    if T.noteStartsAfterPPQ(n, markerPPQ, false) and T.noteEndsBeforePPQ(n, cursorPPQ, false)  then
      if T.noteEndsOnPPQ(n, cursorPPQ) then
        found     = true
        local nl  = n.endPPQ - n.startPPQ
        if nl < ret then
          ret = nl
        end
      end
    end

    ni = ni + 1
  end

  if found then
    return ret
  end

  ni = 0
  while ni < notecnt do
    local n = N.GetNote(take, ni)

    if T.noteStartsAfterPPQ(n, markerPPQ, false) and T.noteEndsBeforePPQ(n, cursorPPQ, false)  then
      found     = true
      local nl  = cursorPPQ - n.endPPQ
      if nl < ret then
        ret = nl
      end
    end
    ni = ni + 1
  end

  if found then
    return ret
  end

  return 0
end

local function StuffBack(km, track, take, notes_to_shorten, triggered_by_key_event)

  notes_to_shorten    = {}

  local c = GEN.BuildBackwardContext(km, track, take, true)

  -- If we're at the start of an item don't move things
  if math.abs(c.itemStartPPQ - c.cursorPPQ) < D.PPQ_TOLERANCE then
    return
  end

  if c.markerTime >= c.rewindTime then
    -- Not possible
    return
  end

  local sbl               = getStuffingBackLength(take, c.markerPPQ, c.cursorPPQ)
  local strFactor         = (c.cursorPPQ - c.markerPPQ) / (c.cursorPPQ - c.markerPPQ - sbl)

  local _stretch = function(ppq)
    if sbl == 0 then
      return c.cursorPPQ
    else
      return T.PPQRound(c.markerPPQ + strFactor * (ppq - c.markerPPQ))
    end
  end

  reaper.Undo_BeginBlock();

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  local _, notecnt, _, _  = N.CountEvts(take, USE_MU)
  local ni = 0
  while (ni < notecnt) do

    -- Examine each note in item
    local n = N.GetNote(take, ni, USE_MU);

    if T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
      --
      --     M     C
      --     |     |
      --     |     | ====
      --     |     |
      --
      -- Move the note back
    elseif T.noteStartsAfterPPQ(n, c.markerPPQ, false) then
      if T.noteEndsBeforePPQ(n, c.cursorPPQ, false) then
        --
        --     M     C
        --     |     |
        --     | === |
        --     |     |
        --
        if T.PPQIsAfterPPQ(_stretch(n.startPPQ), c.cursorPPQ, false) then
          MU.MIDI_DeleteNote(take, n.index)

          c.counts.rem = c.counts.rem + 1
        else
          N.SetNewNoteBounds(n, take, _stretch(n.startPPQ), _stretch(n.endPPQ))
          N.MUCommitNote(take, n)

          c.counts.ext = c.counts.ext + 1
        end
      else
        --
        --     M     C
        --     |     |
        --     |   ==|===
        --     |     |
        --
        N.SetNewNoteBounds(n, take, _stretch(n.startPPQ), n.endPPQ)
        N.MUCommitNote(take, n)

        c.counts.ext = c.counts.ext + 1
      end
    else
      if T.noteEndsAfterPPQ(n, c.cursorPPQ, false) then
        --
        --     M     C
        --     |     |
        --   ==|=====|===
        --     |     |
        --
      elseif T.noteEndsAfterPPQ(n, c.markerPPQ, true) then
        --
        --     M     C
        --     |     |
        --   ==|===  |
        --     |     |
        --
        N.SetNewNoteBounds(n, take, n.startPPQ, _stretch(n.endPPQ))
        N.MUCommitNote(take, n)

        c.counts.ext = c.counts.ext + 1
      else
        -- Leave untouched
        --
        --     M     C
        --     |     |
        -- === |     |
        --     |     |
        --
      end
    end

    ni = ni + 1;
  end

  GEN.BackwardOperationFinish(c, nil)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts),-1);
end

return {
  Stuff     = Stuff,
  StuffBack = StuffBack
}

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local T   = require "modules/time"
local D   = require "modules/defines"
local N   = require "modules/notes"
local MK  = require "modules/markers"
local ART = require "modules/articulations"

local MU  = require "lib/MIDIUtils"
local GEN = require "operations/generic"

local USE_MU = true

local function Stretch(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  notes_to_add    = {}
  notes_to_extend = {}

  local c = GEN.BuildForwardContext(km, track, take)

  local newMaxQN  = c.advanceQN

  if c.markerTime >= c.cursorTime then
    -- Not possible
    return
  end

  local stretchFactor = (c.advanceTime - c.markerTime)/(c.cursorTime - c.markerTime)

  local _stretch = function(ppq)
    return c.markerPPQ + stretchFactor * (ppq - c.markerPPQ)
  end

  reaper.Undo_BeginBlock();

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  local _, notecnt, _, _  = N.CountEvts(take, USE_MU)

  -- Erase forward
  local ni                = 0;
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
      N.SetNewNoteBounds(n, take, n.startPPQ + c.noteLenPPQ, n.endPPQ + c.noteLenPPQ)
      N.MUCommitNote(c.take, n)

      c.counts.ext = c.counts.ext + 1
    elseif T.noteStartsAfterPPQ(n, c.markerPPQ, false) then
      if T.noteEndsBeforePPQ(n, c.cursorPPQ, false) then
        --
        --     M     C
        --     |     |
        --     | === |
        --     |     |
        --
        N.SetNewNoteBounds(n, take, _stretch(n.startPPQ), _stretch(n.endPPQ))
        N.MUCommitNote(c.take, n)

        c.counts.ext = c.counts.ext + 1
      else
        --
        --     M     C
        --     |     |
        --     |   ==|===
        --     |     |
        --
        N.SetNewNoteBounds(n, take, _stretch(n.startPPQ), n.endPPQ + c.noteLenPPQ)
        N.MUCommitNote(c.take, n)

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
        N.SetNewNoteBounds(n, take, n.startPPQ, n.endPPQ + c.noteLenPPQ)
        N.MUCommitNote(c.take, n)

        c.counts.ext = c.counts.ext + 1
      elseif T.noteEndsAfterPPQ(n, c.markerPPQ, true) then
        -- Note ending should be erased
        --
        --     C     A
        --     |     |
        --   ==|===  |
        --     |     |
        --
        N.SetNewNoteBounds(n, take, n.startPPQ, _stretch(n.endPPQ))
        N.MUCommitNote(c.take, n)

        c.counts.ext = c.counts.ext + 1
      else
        -- Leave untouched
        --
        --     C     A
        --     |     |
        -- === |     |
        --     |     |
        --
      end
    end

    if n.endQN > newMaxQN then
      newMaxQN = n.endQN
    end

    ni = ni + 1;
  end

  GEN.ForwardOperationFinish(c, c.advanceTime, newMaxQN)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts), -1)
end

function StretchBack(km, track, take, notes_to_shorten, triggered_by_key_event)

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

  -- Compress
  local compFactor = (c.rewindTime - c.markerTime)/(c.cursorTime - c.markerTime)

  local _comp = function(ppq)
    return c.markerPPQ + compFactor * (ppq - c.markerPPQ)
  end

  reaper.Undo_BeginBlock();

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  local _, notecnt, _, _  = N.CountEvts(take, USE_MU)

  local ni = 0;
  while (ni < notecnt) do

    -- Examine each note in item
    local n = N.GetNote(take, ni);

    if T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
      --
      --     M     C
      --     |     |
      --     |     | ====
      --     |     |
      --
      -- Move the note back
      N.SetNewNoteBounds(n, take, n.startPPQ - c.noteLenPPQ, n.endPPQ - c.noteLenPPQ)
      N.MUCommitNote(c.take, n)

      c.counts.mv           = c.counts.mv + 1
    elseif T.noteStartsAfterPPQ(n, c.markerPPQ, false) then
      if T.noteEndsBeforePPQ(n, c.cursorPPQ, false) then
        --
        --     M     C
        --     |     |
        --     | === |
        --     |     |
        --
        N.SetNewNoteBounds(n, take, _comp(n.startPPQ), _comp(n.endPPQ))
        N.MUCommitNote(c.take, n)

        c.counts.sh           = c.counts.sh + 1
        c.counts.mv           = c.counts.mv + 1
      else
        --
        --     M     C
        --     |     |
        --     |   ==|===
        --     |     |
        --
        N.SetNewNoteBounds(n, take, _comp(n.startPPQ), n.endPPQ - c.noteLenPPQ)
        N.MUCommitNote(c.take, n)

        c.counts.sh           = c.counts.sh + 1
        c.counts.mv           = c.counts.mv + 1
      end
    else
      if T.noteEndsAfterPPQ(n, c.cursorPPQ, false) then
        --
        --     M     C
        --     |     |
        --   ==|=====|===
        --     |     |
        --
        N.SetNewNoteBounds(n, take, n.startPPQ, n.endPPQ - c.noteLenPPQ)
        N.MUCommitNote(c.take, n)

        c.counts.sh         = c.counts.sh + 1
      elseif T.noteEndsAfterPPQ(n, c.markerPPQ, true) then
        --
        --     M     C
        --     |     |
        --   ==|===  |
        --     |     |
        --
        N.SetNewNoteBounds(n, take, n.startPPQ, _comp(n.endPPQ))
        N.MUCommitNote(c.take, n)

        c.counts.sh         = c.counts.sh + 1
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

  GEN.BackwardOperationFinish(c, c.rewindTime)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts), -1)
end

return {
  Stretch     = Stretch,
  StretchBack = StretchBack
}


-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local T   = require "modules/time"
local S   = require "modules/settings"
local D   = require "modules/defines"
local N   = require "modules/notes"
local ART = require "modules/articulations"

local GEN = require "operations/generic"
local MU  = require "lib/MIDIUtils"

local USE_MU = true

-- Commits the currently held notes into the take
local function Replace(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local c = GEN.BuildForwardContext(km, track, take)

  local newMaxQN  = c.advanceQN

  reaper.Undo_BeginBlock()

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  local _, notecnt, _, _  = N.CountEvts(take, USE_MU)

  -- Erase forward
  local ni = 0;
  while (ni < notecnt) do

    -- Examine each note in item
    local n = N.GetNote(take, ni, USE_MU)

    if T.noteStartsAfterPPQ(n, c.advancePPQ, false) then
      -- Note is not in the erasing window
      --
      --     C     A
      --     |     |-
      --     |     | ====
      --     |     |-
      --
    elseif T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
      if T.noteEndsBeforePPQ(n, c.advancePPQ, false) then
        -- Note should be suppressed
        --
        --     C     A
        --     |-   -|
        --     | === |
        --     |-   -|
        --
        MU.MIDI_DeleteNote(take, n.index)
      else
        -- The note should be shortened (removing tail).
        -- Since its start will change, it should be removed and reinserted (see reaper's API doc)
        --
        --     C     A
        --     |-   -|
        --     |   ==|===
        --     |-   -|
        --
        N.SetNewNoteBounds(n, take, c.advancePPQ, n.endPPQ)
        N.MUCommitNote(c.take, n)

        c.counts.sh = c.counts.sh + 1
        c.counts.mv = c.counts.mv + 1
      end
    else
      if T.noteEndsAfterPPQ(n, c.advancePPQ, false) then
        -- We should make a hole. Shorten (or erase) left part. Shorten (or erase) right part
        --
        --     C     A
        --     |     |
        --   ==|=====|===
        --     |     |
        --
        if T.noteStartsOnPPQ(n, c.cursorPPQ) then
          -- Case already handled above, I think ... because note starts after C and ends after A
          -- This part should probably be removed for clarity

          -- The start changes, remove and reinsert
          N.SetNewNoteBounds(n, take, c.advancePPQ, n.endPPQ)
          N.MUCommitNote(c.take, n)

          c.counts.sh = c.counts.sh + 1
          c.counts.mv = c.counts.mv + 1
        else
          -- Clone note
          local newn = N.CloneNote(n)

          -- Shorten the note
          N.SetNewNoteBounds(n, take, n.startPPQ, c.cursorPPQ)
          N.MUCommitNote(c.take, n)

          c.counts.sh         = c.counts.sh + 1

          if not T.noteEndsOnPPQ(newn, c.advancePPQ) then
            -- Add new note
            N.SetNewNoteBounds(newn, take, c.advancePPQ, newn.endPPQ)
            N.MUCommitNote(c.take, newn)

            c.counts.add        = c.counts.add + 1
          end
        end

      elseif T.noteEndsAfterPPQ(n, c.cursorPPQ, true) then
        -- Note ending should be erased
        --
        --     C     A
        --     |-    |
        --   ==|===  |
        --     |-    |
        --
        N.SetNewNoteBounds(n, take, n.startPPQ, c.cursorPPQ);
        N.MUCommitNote(c.take, n)

        c.counts.sh         = c.counts.sh + 1
      else
        -- Leave untouched
        --
        --     C     A
        --     |-    |
        -- === |     |
        --     |-    |
        --
      end

    end

    ni = ni + 1;
  end

  GEN.AddAndExtendNotes(c, notes_to_add, notes_to_extend)
  GEN.ForwardOperationFinish(c, c.advanceTime, newMaxQN)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(1, c.counts), -1)
end

local function ReplaceBack(km, track, take, notes_to_shorten, triggered_by_key_event)

  -- For now, just force a full erase
  notes_to_shorten = {}

  if triggered_by_key_event and not S.AllowKeyEventNavigation() then
    -- Don't allow erasing when triggered by key
    return
  end

  local c = GEN.BuildBackwardContext(km, track, take, true)

  -- If we're at the start of an item don't delete things
  if math.abs(c.itemStartPPQ - c.cursorPPQ) < D.PPQ_TOLERANCE then
    return
  end

  reaper.Undo_BeginBlock();

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  GEN.GenericDelete(c, notes_to_shorten, false, false)
  GEN.BackwardOperationFinish(c, c.rewindTime)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts), -1)
end

return {
  Replace     = Replace,
  ReplaceBack = ReplaceBack
}


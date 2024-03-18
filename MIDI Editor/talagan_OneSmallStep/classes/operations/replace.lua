-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local T   = require "modules/time"
local S   = require "modules/settings"
local D   = require "modules/defines"
local N   = require "modules/notes"

local GEN = require "operations/generic"

-- Commits the currently held notes into the take
local function Replace(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local c = GEN.BuildForwardContext(km, track, take)

  local newMaxQN  = c.advanceQN

  reaper.Undo_BeginBlock();

  -- Erase forward
  local _, notecnt, _, _ = reaper.MIDI_CountEvts(take)

  local ni = 0;
  while (ni < notecnt) do

    -- Examine each note in item
    local n = N.GetNote(take, ni)

    if T.noteStartsAfterPPQ(n, c.advancePPQ, false) then
      -- Note is not in the erasing window
      --
      --     C     A
      --     |     |
      --     |     | ====
      --     |     |
      --
    elseif T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
      if T.noteEndsBeforePPQ(n, c.advancePPQ, false) then
        -- Note should be suppressed
        --
        --     C     A
        --     |     |
        --     | === |
        --     |     |
        --
        c.torem[#c.torem+1] = n
        c.counts.rem        = c.counts.rem + 1
      else
        -- The note should be shortened (removing tail).
        -- Since its start will change, it should be removed and reinserted (see reaper's API doc)
        --
        --     RC    A
        --     |     |
        --     |   ==|===
        --     |     |
        --
        N.SetNewNoteBounds(n, take, c.advancePPQ, n.endPPQ)

        c.torem[#c.torem+1]   = n
        c.toadd[#c.toadd+1]   = n

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
          -- The start changes, remove and reinsert
          N.SetNewNoteBounds(n, take, c.advancePPQ, n.endPPQ)

          c.torem[#c.torem+1]   = n
          c.toadd[#c.toadd+1]   = n

          c.counts.sh = c.counts.sh + 1
          c.counts.mv = c.counts.mv + 1
        else
          -- Copy note
          local newn = {}
          for k,v in pairs(n) do
            newn[k] = v
          end

          -- Shorten the note
          N.SetNewNoteBounds(n, take, n.startPPQ, c.cursorPPQ)

          c.tomod[#c.tomod+1] = n
          c.counts.sh         = c.counts.sh + 1

          if not T.noteEndsOnPPQ(newn, c.advancePPQ) then
            -- Add new note
            N.SetNewNoteBounds(newn, take, c.advancePPQ, newn.endPPQ);
            c.toadd[#c.toadd+1] = newn
            c.counts.add        = c.counts.add + 1
          end
        end

      elseif T.noteEndsAfterPPQ(n, c.cursorPPQ, true) then
        -- Note ending should be erased
        --
        --     C     A
        --     |     |
        --   ==|===  |
        --     |     |
        --
        N.SetNewNoteBounds(n, take, n.startPPQ, c.cursorPPQ);
        c.tomod[#c.tomod+1] = n
        c.counts.sh         = c.counts.sh + 1
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

    ni = ni + 1;
  end

  GEN.AddAndExtendNotes(c, notes_to_add, notes_to_extend)
  GEN.ForwardOperationFinish(c, c.advanceTime, newMaxQN)

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

  GEN.GenericDelete(c, notes_to_shorten)
  GEN.BackwardOperationFinish(c, c.rewindTime)

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts), -1)
end

return {
  Replace = Replace,
  ReplaceBack = ReplaceBack
}


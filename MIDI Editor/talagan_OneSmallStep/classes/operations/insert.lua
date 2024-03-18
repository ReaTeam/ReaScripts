-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local T   = require "modules/time"
local S   = require "modules/settings"
local D   = require "modules/defines"
local N   = require "modules/notes"

local GEN = require "operations/generic"

local function Insert(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local c         = GEN.BuildForwardContext(km, track, take)

  local newMaxQN  = c.advanceQN

  reaper.Undo_BeginBlock();

  -- First, move some notes
  local _, notecnt, _, _ = reaper.MIDI_CountEvts(take)
  local ni = 0

  -- Shift notes
  while (ni < notecnt) do
    local n = N.GetNote(take, ni);

    if T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
      -- Move the note
      N.SetNewNoteBounds(n, take, n.startPPQ + c.noteLenPPQ, n.endPPQ + c.noteLenPPQ)

      if n.endQN > newMaxQN then
        newMaxQN = n.endQN
      end

      -- It should be removed and readded, because the start position changes
      c.torem[#c.torem + 1] = n
      c.toadd[#c.toadd + 1] = n

      c.counts.mv = c.counts.mv + 1
    end

    ni = ni + 1
  end

  GEN.AddAndExtendNotes(c, notes_to_add, notes_to_extend)
  GEN.ForwardOperationFinish(c, c.advanceTime, newMaxQN)

  reaper.Undo_EndBlock(GEN.OperationSummary(1, c.counts), -1)
end


local function InsertBack(km, track, take, notes_to_shorten, triggered_by_key_event)

  -- For now, just force a full erase
  notes_to_shorten = {}

  if triggered_by_key_event and not S.AllowKeyEventNavigation() then
    -- Don't allow erasing when triggered by key
    return
  end

  local c = GEN.BuildBackwardContext(km, track, take, true)

  -- If we're at the start of an item don't move things
  if math.abs(c.itemStartPPQ - c.cursorPPQ) < D.PPQ_TOLERANCE then
    return
  end

  reaper.Undo_BeginBlock();

  GEN.GenericDelete(c,notes_to_shorten, false, true)
  GEN.BackwardOperationFinish(c, c.rewindTime)

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts), -1)
end

return {
  Insert = Insert,
  InsertBack = InsertBack
}



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

local function NoteMatchesOneOf(note, note_bunch)
  local matchingNote = nil
  for _, nn in ipairs(note_bunch) do
    if nn.pitch == note.pitch then
      matchingNote = nn
      break
    end
  end
  return matchingNote
end

local function Insert(km, track, take, new_notes, held_notes, triggered_by_key_event)

  local c         = GEN.BuildForwardContext(km, track, take)

  local newMaxQN  = c.advanceQN

  reaper.Undo_BeginBlock();

  -- First, move some notes
  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  local _, notecnt, _, _  = N.CountEvts(take, USE_MU)
  local ni = 0

  -- Shift notes
  while (ni < notecnt) do
    local n = N.GetNote(take, ni, USE_MU)

    if T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
      -- Push the note back
      N.SetNewNoteBounds(n, take, n.startPPQ + c.noteLenPPQ, n.endPPQ + c.noteLenPPQ)
      N.MUCommitNote(c.take, n)

      c.counts.mv = c.counts.mv + 1

      if n.endQN > newMaxQN then
        newMaxQN = n.endQN
      end
    elseif T.noteContainsPPQ(n, c.cursorPPQ, true) then
      -- This is a complex case. We may cut, leave untouch, extend from the interior, or cut + add

      -- Does a new/held note matches this note ?
      local nn        = NoteMatchesOneOf(n, new_notes)
      local hn        = NoteMatchesOneOf(n, held_notes)
      local hasMatch  = (nn ~= nil) or (hn ~= nil)

      local behavior = S.getSetting("InsertModeInMiddleOfNonMatchingNotesBehaviour")

      if hasMatch then
        -- There's a match
        behavior = S.getSetting("InsertModeInMiddleOfMatchingNotesBehaviour")
      end

      if behavior == D.MiddleInsertBehavior.LeaveUntouched then
      elseif behavior == D.MiddleInsertBehavior.Cut or behavior == D.MiddleInsertBehavior.CutAndAdd then
        -- First, clone the note
        local en = N.CloneNote(n)

        -- Keep left part, shorten existing note
        N.SetNewNoteBounds(n, take, n.startPPQ, c.cursorPPQ)
        N.MUCommitNote(c.take, n)
        c.counts.sh = c.counts.sh + 1

        -- Create right part
        N.SetNewNoteBounds(en, take, c.advancePPQ, en.endPPQ + c.noteLenPPQ)
        N.MUCommitNote(c.take, en)
        c.counts.add = c.counts.add + 1

        if behavior == D.MiddleInsertBehavior.CutAndAdd then
          -- Fill the new gap
          local an = N.BuildFromManager(nn or hn, take, c.cursorPPQ, c.advancePPQ)
          N.MUCommitNote(take, an)
          c.counts.add = c.counts.add + 1
        end
      elseif behavior == D.MiddleInsertBehavior.Extend then
        N.SetNewNoteBounds(n, take, n.startPPQ, n.endPPQ + c.noteLenPPQ)
        N.MUCommitNote(take, n)
        c.counts.ext = c.counts.ext + 1
        if n.endQN > newMaxQN then
          newMaxQN = n.endQN
        end
      end

      if hasMatch then
        -- This event has been treated, it will not add a new note in the add loop
        -- Beware, this flag will be set during the whole life of the note as long
        -- as there's activity on it (until it is released)
        if nn then nn.dont_add = true end
      end
    end

    ni = ni + 1
  end

  GEN.AddAndExtendNotes(c, new_notes, held_notes)
  GEN.ForwardOperationFinish(c, c.advanceTime, newMaxQN)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

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

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  GEN.GenericDelete(c,notes_to_shorten, false, true)
  GEN.BackwardOperationFinish(c, c.rewindTime)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts), -1)
end

return {
  Insert = Insert,
  InsertBack = InsertBack
}



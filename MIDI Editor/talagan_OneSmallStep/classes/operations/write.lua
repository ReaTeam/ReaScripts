-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local T   = require "modules/time"
local S   = require "modules/settings"
local D   = require "modules/defines"
local AT  = require "modules/action_triggers"
local ART = require "modules/articulations"

local MU  = require "lib/MIDIUtils"
local GEN = require "operations/generic"

local USE_MU = true

-- Commits the currently held notes into the take
local function Write(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)
  local c         = GEN.BuildForwardContext(km, track, take)

  local newMaxQN  = c.advanceQN

  reaper.Undo_BeginBlock();

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  GEN.AddAndExtendNotes(c, notes_to_add, notes_to_extend)
  GEN.ForwardOperationFinish(c, c.advanceTime, newMaxQN)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(1, c.counts), -1);
end


local blockRewindRef = nil

local function WriteBack(km, track, take, notes_to_shorten, triggered_by_key_event)

  local c = GEN.BuildBackwardContext(km, track, take)

  if c.rewindTime < c.itemStartTime then
    c.rewindTime = c.itemStartTime
  end

  -- If we're at the start of an item don't move things
  if math.abs(c.itemStartPPQ - c.cursorPPQ) < D.PPQ_TOLERANCE then
    return
  end

  reaper.Undo_BeginBlock();

  MU.MIDI_InitializeTake(take)
  MU.MIDI_OpenWriteTransaction(take)

  GEN.GenericDelete(c, notes_to_shorten, true, false)

  local blockRewind           = false
  local triggeredByBackAction = AT.hasBackwardActionTrigger()
  local pedalStart            = km:keyActivityForTrack(track).pedal.first_ts
  local hadCandidates         = (#notes_to_shorten > 0)
  local failedToErase         = (hadCandidates and (c.counts.sh + c.counts.rem == 0))

  if (not triggeredByBackAction) then
    -- We block the rewind in certain conditions (when erasing failed, and when during this pedal session, the erasing was blocked)

    local cond1             = S.getSetting("DoNotRewindOnStepBackIfNothingErased") and failedToErase
    local cond2             = (not hadCandidates) and (pedalStart == blockRewindRef)

    blockRewind = cond1 or cond2
  end

  local jumpTime = nil
  if blockRewind then
    blockRewindRef = pedalStart
  else
    if (not hadCandidates) or (not failedToErase) then
      jumpTime = c.rewindTime
    end
  end

  GEN.BackwardOperationFinish(c, jumpTime)

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(-1, c.counts), -1)
end

return {
  Write = Write,
  WriteBack = WriteBack
}


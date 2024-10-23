-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local SNP = require "modules/snap"
local T   = require "modules/time"
local S   = require "modules/settings"
local N   = require "modules/notes"
local D   = require "modules/defines"
local ART = require "modules/articulations"

local GEN = require "operations/generic"
local MU  = require "lib/MIDIUtils"

local USE_MU = true

-- Trying to disable overlapping note correction ...
-- Well it does not work. When the autocorrection is reenabled
-- It will destroy notes that overlap
-- We'll trigger it off and not reenable it
local autoOverlap = nil
local function PushAutoCorrectOverlapOption()
  autoOverlap = reaper.GetToggleCommandStateEx(32060, 40681)
  if autoOverlap == 1 then
    local ret = reaper.MIDIEditor_LastFocused_OnCommand(40681, false) -- toggle off
  end
end

local function PopAutoCorrectOverlapOption()
  if autoOverlap == 1 then
    --  reaper.MIDIEditor_LastFocused_OnCommand(40681, false) -- toggle back on
  end
end

local function Repitch(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local c                         = GEN.BuildForwardContext(km, track, take)

  c.aggregationTime               = c.cursorTime + S.getSetting("RepitchModeAggregationTime")
  c.aggregationPPQ                = reaper.MIDI_GetPPQPosFromProjTime(take, c.aggregationTime)

  local affects                   = S.getSetting("RepitchModeAffects")
  local useNewVelocities          = (affects == D.RepitchModeAffects.VelocitiesOnly) or (affects == D.RepitchModeAffects.PitchesAndVelocities)
  local useNewPitches             = (affects == D.RepitchModeAffects.PitchesOnly)    or (affects == D.RepitchModeAffects.PitchesAndVelocities)

  reaper.Undo_BeginBlock()

  MU.MIDI_InitializeTake(take)
  local _, notecnt, _, _ = N.CountEvts(take, USE_MU)

  -- Since we repitch, there's no notion of holding notes
  for _, v in pairs(notes_to_extend) do
    notes_to_add[#notes_to_add+1] = v
  end

  notes_to_extend = {}

  -- Use tomod to memorize notes that are in the window
  local ni = 0
  while (ni < notecnt) do
    local n = N.GetNote(take, ni, USE_MU)

    if T.noteStartsInWindowPPQ(n, c.cursorPPQ, c.aggregationPPQ, false) then
      c.tomod[#c.tomod + 1] = n
    end

    ni = ni + 1
  end

  local shouldJump  = true
  local jumpRefPPQ  = c.cursorPPQ

  if #c.tomod == 0 or #notes_to_add == 0 then
    -- Just jump
  else
    if (#c.tomod ~= #notes_to_add) then
      shouldJump = false
    else
      -- Apply mote modifications

      -- Sort notes to modify by pitch
      table.sort(c.tomod, function(n1, n2)
        return n1.pitch < n2.pitch
      end)

      -- Sort notes to add by pitch
      table.sort(notes_to_add, function(n1, n2)
        return n1.pitch < n2.pitch
      end)

      PushAutoCorrectOverlapOption()
      MU.MIDI_OpenWriteTransaction(take)

      for k, n in ipairs(c.tomod) do
        local newvel   = nil
        local newpitch = nil

        if useNewVelocities then
          newvel = notes_to_add[k].vel
        end
        if useNewPitches then
          newpitch = notes_to_add[k].pitch
        end

        MU.MIDI_SetNote(take, n.index, nil, nil, nil, nil, nil, newpitch, newvel, nil)

        if n.startPPQ > jumpRefPPQ then
          jumpRefPPQ = n.startPPQ
        end
      end

      MU.MIDI_CommitWriteTransaction(take)
    end

    reaper.UpdateItemInProject(c.mediaItem)
    reaper.MarkTrackItemsDirty(track, c.mediaItem)

    PopAutoCorrectOverlapOption()
  end

  if shouldJump then
    local jumpRefTime = reaper.MIDI_GetProjTimeFromPPQPos(take, jumpRefPPQ)
    local jumpTimeSnp = SNP.nextSnap(track, 1, jumpRefTime, {enabled = true, noteStart = true})
    local jumpTime    = (jumpTimeSnp and jumpTimeSnp.time)

    if not jumpTime then
      -- If it fails, try with not ends
      jumpTime  = SNP.nextSnap(track, 1, jumpRefTime, {enabled = true, noteEnd = true})
      jumpTime  = (jumpTime and jumpTime.time)
    end

    if not jumpTime then
      -- If it still fails, use the item end time
      jumpTime = c.itemEndTime
    end

    reaper.SetEditCurPos(jumpTime, false, false)

    if S.getSetting("AutoScrollArrangeView") then
      T.KeepEditCursorOnScreen()
    end
  end

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(1, c.counts), -1)
end

local function RepitchBack(km, track, take, notes_to_add, notes_to_extend, triggered_by_key_event)

  local c = GEN.BuildBackwardContext(km, track, take)

  reaper.Undo_BeginBlock();

  local jumpTime    = SNP.nextSnap(track, -1, c.cursorTime, {enabled = true, noteStart = true})
  jumpTime          = (jumpTime and jumpTime.time) or c.itemStartTime

  if not jumpTime then
    jumpTime  = c.itemStartTime
  end

  reaper.SetEditCurPos(jumpTime, false, false)

  if S.getSetting("AutoScrollArrangeView") then
    T.KeepEditCursorOnScreen()
  end

  ART.UpdateArticulationTextEventsIfNeeded(track, take);

  reaper.Undo_EndBlock(GEN.OperationSummary(1, c.counts), -1)
end

return {
  Repitch = Repitch,
  RepitchBack = RepitchBack
}

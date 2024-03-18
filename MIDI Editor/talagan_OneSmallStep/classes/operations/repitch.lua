-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local SNP = require "modules/snap"
local T   = require "modules/time"
local S   = require "modules/settings"
local N   = require "modules/notes"

local GEN = require "operations/generic"

local MU  = require "lib/MIDIUtils"

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
  local useNewVelocities          = (affects == "Velocities only") or (affects == "Pitches + Velocities")
  local useNewPitches             = (affects == "Pitches only")    or (affects == "Pitches + Velocities")

  local useMidiUtils              = true

  local _, notecnt, _, _          = N.CountEvts(take, useMidiUtils)

  reaper.Undo_BeginBlock()

  if useMidiUtils then
    MU.MIDI_InitializeTake(take)
  end

  -- Since we repitch, there's no notion of holding notes
  for _, v in pairs(notes_to_extend) do
    notes_to_add[#notes_to_add+1] = v
  end

  notes_to_extend = {}

  local ni = 0
  while (ni < notecnt) do
    local n = N.GetNote(take, ni, useMidiUtils)

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

      if useMidiUtils then
        PushAutoCorrectOverlapOption()
        MU.MIDI_OpenWriteTransaction(take)
      end

      for k, n in ipairs(c.tomod) do
        local newvel   = nil
        local newpitch = nil

        if useNewVelocities then
          newvel = notes_to_add[k].vel
        end
        if useNewPitches then
          newpitch = notes_to_add[k].pitch
        end

        if useMidiUtils then
          MU.MIDI_SetNote(take, n.index, nil, nil, nil, nil, nil, newpitch, newvel, nil)
        else
          reaper.MIDI_SetNote(take, n.index, nil, nil, nil, nil, nil, newpitch, newvel, false)
        end

        if n.startPPQ > jumpRefPPQ then
          jumpRefPPQ = n.startPPQ
        end
      end

      if useMidiUtils then
        MU.MIDI_CommitWriteTransaction(take)
      end
    end

    if not useMidiUtils then
      reaper.MIDI_Sort(take)
    end

    reaper.UpdateItemInProject(c.mediaItem)
    reaper.MarkTrackItemsDirty(track, c.mediaItem)

    if useMidiUtils then
      PopAutoCorrectOverlapOption()
    end

  end

  if shouldJump then
    local jumpRefTime = reaper.MIDI_GetProjTimeFromPPQPos(take, jumpRefPPQ)
    local jumpTime  = SNP.nextSnap(track, 1, jumpRefTime, {enabled = true, noteStart = true})
    jumpTime        = (jumpTime and jumpTime.time)

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

  reaper.Undo_EndBlock(GEN.OperationSummary(1, c.counts), -1)
end

return {
  Repitch = Repitch,
  RepitchBack = RepitchBack
}

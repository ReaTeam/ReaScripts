-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

local S   = require "modules/settings"
local T   = require "modules/time"
local N   = require "modules/notes"
local MK  = require "modules/markers"

local MU  = require "lib/MIDIUtils"

local USE_MU = true

local function BuildContext(km, track, take)
  local c = {}

  c.km                            = km
  c.track                         = track
  c.take                          = take
  c.mediaItem                     = reaper.GetMediaItemTake_Item(take)

  c.counts                        = { sh = 0, ext = 0, rem = 0, mv = 0, add = 0 }
  c.toadd, c.tomod, c.torem       = {}, {}, {}

  c.noteLenPPQ                    = T.ResolveNoteLenPPQ(take)

  c.cursorTime                    = reaper.GetCursorPosition()
  c.cursorQN                      = reaper.TimeMap2_timeToQN(0, c.cursorTime)
  c.cursorPPQ                     = reaper.MIDI_GetPPQPosFromProjTime(take, c.cursorTime)

  c.itemDuration                  = reaper.GetMediaItemInfo_Value(c.mediaItem, "D_LENGTH")

  c.itemStartTime                 = reaper.GetMediaItemInfo_Value(c.mediaItem, "D_POSITION")
  c.imemStartQN                   = reaper.TimeMap2_timeToQN(0, c.itemStartTime)
  c.itemStartPPQ                  = reaper.MIDI_GetPPQPosFromProjTime(take, c.itemStartTime)

  c.itemEndTime                   = c.itemStartTime + c.itemDuration
  c.itemEndQN                     = reaper.TimeMap2_timeToQN(0, c.itemEndTime)
  c.itemEndPPQ                    = reaper.MIDI_GetPPQPosFromProjTime(take, c.itemEndTime)

  local mkw = nil
  mkw, c.markerTime               = MK.findOperationMarker()
  if mkw then
    c.markerQN                    = reaper.TimeMap2_timeToQN(0, c.markerTime)
    c.markerPPQ                   = reaper.MIDI_GetPPQPosFromProjTime(take, c.markerTime)
  end

  return c
end

local function BuildForwardContext(km, track, take)
  local c         = BuildContext(km, track, take)

  c.advancePPQ    = c.cursorPPQ + c.noteLenPPQ
  c.advanceTime   = reaper.MIDI_GetProjTimeFromPPQPos(take, c.advancePPQ)
  c.advanceQN     = reaper.TimeMap2_timeToQN(0, c.advanceTime)

  return c
end

local function BuildBackwardContext(km, track, take, shouldClampRewindTime)
  local c         = BuildContext(km, track, take)

  c.rewindTime    = reaper.MIDI_GetProjTimeFromPPQPos(take, c.cursorPPQ - c.noteLenPPQ)

  if shouldClampRewindTime and (c.rewindTime < c.itemStartTime) then
    c.rewindTime = c.itemStartTime
  end

  c.rewindQN      = reaper.TimeMap2_timeToQN(0, c.rewindTime)
  c.rewindPPQ     = reaper.MIDI_GetPPQPosFromProjTime(take, c.rewindTime)

  return c
end

local function ForwardOperationFinish(c, jumpTime, newMaxQN)

  MU.MIDI_CommitWriteTransaction(c.take)

  reaper.UpdateItemInProject(c.mediaItem)

  -- Grow the midi item if needed
  local itemStartTime = reaper.GetMediaItemInfo_Value(c.mediaItem, "D_POSITION")
  local itemLength    = reaper.GetMediaItemInfo_Value(c.mediaItem, "D_LENGTH")
  local itemEndTime   = itemStartTime + itemLength;
  local newMaxTime    = reaper.TimeMap2_QNToTime(0, newMaxQN)

  if(itemEndTime >= newMaxTime) then
    -- Cool, the item is big enough
  else
    local itemStartQN = reaper.TimeMap2_timeToQN(0, itemStartTime)
    local itemEndQN   = reaper.TimeMap2_timeToQN(0, newMaxTime)

    reaper.MIDI_SetItemExtents(c.mediaItem, itemStartQN, itemEndQN)
    reaper.UpdateItemInProject(c.mediaItem)
  end

  -- Mark item as dirty
  reaper.MarkTrackItemsDirty(c.track, c.mediaItem)

  if jumpTime then
    reaper.SetEditCurPos(T.TimeRoundBasedOnPPQ(c.take, jumpTime), false, false);
    if S.getSetting("AutoScrollArrangeView") then
      T.KeepEditCursorOnScreen()
    end
  end
end

local function BackwardOperationFinish(c, jumpTime)

  MU.MIDI_CommitWriteTransaction(c.take)

  reaper.UpdateItemInProject(c.mediaItem)
  reaper.MarkTrackItemsDirty(c.track, c.mediaItem)

  if jumpTime then
    reaper.SetEditCurPos(T.TimeRoundBasedOnPPQ(c.take, jumpTime), false, false)
    if S.getSetting("AutoScrollArrangeView") then
      T.KeepEditCursorOnScreen()
    end
  end
end

local function GenericDelete(c, notes_to_shorten, selectiveErase, shiftMode)

  local _, notecnt, _, _  = N.CountEvts(c.take, USE_MU)
  local ni = 0;
  while (ni < notecnt) do

    -- Examine each note in item
    local n = N.GetNote(c.take, ni, USE_MU)

    local targetable = false

    if selectiveErase then
      for _, shnote in pairs(notes_to_shorten) do
        if n.chan == shnote.chan and n.pitch == shnote.pitch then
          targetable = true
          break
        end
      end
    else
      targetable = true
    end

    if targetable then
      if T.noteStartsAfterPPQ(n, c.cursorPPQ, false) then
        -- Note should be moved back or left untouched (if in cursor mode or not)
        --
        --     R     C
        --     |     |
        --     |     | ====
        --     |     |
        --
        if shiftMode then
          -- Move the note back
          N.SetNewNoteBounds(n, c.take, n.startPPQ - c.noteLenPPQ, n.endPPQ - c.noteLenPPQ)
          N.MUCommitNote(c.take, n)

          c.counts.mv           = c.counts.mv + 1
        end
      elseif T.noteStartsAfterPPQ(n, c.rewindPPQ, false) then
        if T.noteEndsBeforePPQ(n, c.cursorPPQ, false) then
          -- Note should be suppressed
          --
          --     R     C
          --     |     |
          --     | === |
          --     |     |
          --
          MU.MIDI_DeleteNote(c.take, n.index)

          c.counts.rem        = c.counts.rem + 1
        else
          -- The note should be shortened (removing tail).
          -- Since its start will change, it should be removed and reinserted (see reaper's API doc)
          --
          --     R     C
          --     |     |
          --     |   ==|===
          --     |     |
          --
          local offset = (shiftMode) and (- c.noteLenPPQ) or (0)
          N.SetNewNoteBounds(n, c.take, c.cursorPPQ + offset, n.endPPQ + offset)
          N.MUCommitNote(c.take, n)

          c.counts.sh = c.counts.sh + 1
          c.counts.mv = c.counts.mv + 1
        end
      else
        if T.noteEndsAfterPPQ(n, c.cursorPPQ, false) then
          -- Note should be cut.
          --
          --     R     C
          --     |     |
          --   ==|=====|===
          --     |     |
          --
          if shiftMode or T.noteEndsOnPPQ(n, c.cursorPPQ) then
            N.SetNewNoteBounds(n, c.take, n.startPPQ, n.endPPQ - c.noteLenPPQ)
            N.MUCommitNote(c.take, n)

            c.counts.sh         = c.counts.sh + 1
          else
            -- Create a hole in the note. Clone note
            local newn = N.CloneNote(n)

            -- Shorted remaining note
            N.SetNewNoteBounds(n, c.take, n.startPPQ, c.rewindPPQ);
            N.MUCommitNote(c.take, n)

            c.counts.sh         = c.counts.sh + 1

            -- Add new note
            N.SetNewNoteBounds(newn, c.take, c.cursorPPQ, newn.endPPQ);
            N.MUCommitNote(c.take, newn)

            c.counts.add        = c.counts.add + 1
          end

        elseif T.noteEndsAfterPPQ(n, c.rewindPPQ, true) then
          -- Note ending should be erased
          --
          --     R     C
          --     |     |
          --   ==|===  |
          --     |     |
          --
          N.SetNewNoteBounds(n, c.take, n.startPPQ, c.rewindPPQ)
          N.MUCommitNote(c.take, n)

          c.counts.sh         = c.counts.sh + 1
        else
          -- Leave untouched
          --
          --     R     C
          --     |     |
          -- === |     |
          --     |     |
          --
        end
      end
    end

    ni = ni + 1;
  end
end


-- This function is used by the write/insert/replace modes
local function AddAndExtendNotes(c, notes_to_add, notes_to_extend)

  -- Then add some other notes
  for _, v in ipairs(notes_to_add) do

    if not v.dont_add then
      local newn = N.BuildFromManager(v, c.take, c.cursorPPQ, c.advancePPQ)
      N.MUCommitNote(c.take, newn)
      c.counts.add = c.counts.add + 1
    end
  end

  -- Then extend notes
  if #notes_to_extend > 0 then
    local _, notecnt, _, _  = N.CountEvts(c.take, USE_MU)

    for _, exnote in pairs(notes_to_extend) do
        -- Search for a note that could be extended (matches all conditions)
        local ni    = 0
        local found = false

        while (ni < notecnt) do
          local n = N.GetNote(c.take, ni, USE_MU)

          -- Extend the note if found
          if T.noteEndsOnPPQ(n, c.cursorPPQ) and (n.chan == exnote.chan) and (n.pitch == exnote.pitch) then

            N.SetNewNoteBounds(n, c.take, n.startPPQ, c.advancePPQ)
            N.MUCommitNote(c.take, n)

            c.counts.ext = c.counts.ext + 1
            found = true
          end

          ni = ni + 1
        end

        if not found and not exnote.dont_add then
          -- Could not find a note to extend... create one !
          local newn = N.BuildFromManager(exnote, c.take, c.cursorPPQ, c.advancePPQ)
          N.MUCommitNote(c.take, newn)

          c.counts.add = c.counts.add + 1
        end
      end
    end
end

local function OperationSummary(direction, counts)
  local description = {}

  if counts.sh + counts.add + counts.rem + counts.sh + counts.ext == 0 then
    if direction > 0 then
      description[#description+1] = "advanced"
    else
      description[#description+1] = "stepped back"
    end
  end
  if counts.add > 0 then
    description[#description+1] = "added " .. counts.add .. " notes"
  end
  if counts.rem > 0 then
    description[#description+1] = "removed " .. counts.rem .. " notes"
  end
  if counts.mv > 0 then
    description[#description+1] = "moved " .. counts.mv .. " notes"
  end
  if counts.sh > 0 then
    description[#description+1] = "shortened " .. counts.sh .. " notes"
  end
  if counts.ext > 0 then
    description[#description+1] = "extended " .. counts.ext .. " notes"
  end

  return "One Small Step: " .. table.concat(description, ", ")
end


return {
  BuildForwardContext     = BuildForwardContext,
  BuildBackwardContext    = BuildBackwardContext,
  OperationSummary        = OperationSummary,
  ForwardOperationFinish  = ForwardOperationFinish,
  BackwardOperationFinish = BackwardOperationFinish,
  GenericDelete           = GenericDelete,

  AddAndExtendNotes       = AddAndExtendNotes
}

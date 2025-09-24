-- @description Move and stretch selected notes to fit time selection
-- @author BIXI DOX & ChatGPT
-- @version 1.0
-- @changelog + Initial release, this is my kingdom come...
-- @about
--   Pretty straight forward feature with proper undo/redo handling... 
--
--   I've been testing this script for hours, Just because I use ChatGPT doesn't mean I don't know how to code, He's there to suggest me ideas and I wanted to credit him for that.

-- Get active MIDI editor and take
local editor = reaper.MIDIEditor_GetActive()
if not editor then return end
local take = reaper.MIDIEditor_GetTake(editor)
if not take or not reaper.TakeIsMIDI(take) then return end

-- Get time selection
local timeStart, timeEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
if timeStart == timeEnd then
  -- reaper.MB("No time selection set!", "Error", 0)
  return
end

-- Count events
local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
------------------------------------------------------

-- Find earliest start and latest end among selected notes
local firstNote, lastNote = nil, nil
for i = 0, noteCount-1 do
  local retval, sel, _, startppq, endppq = reaper.MIDI_GetNote(take, i)
  if sel then
    if not firstNote or startppq < firstNote then firstNote = startppq end
    if not lastNote or endppq > lastNote then lastNote = endppq end
  end
end

if not firstNote or not lastNote or firstNote == lastNote then
  -- reaper.MB("No valid selected notes to stretch!", "Error", 0)
  return
end

-- Convert time selection to PPQ
local ppqStart = reaper.MIDI_GetPPQPosFromProjTime(take, timeStart)
local ppqEnd   = reaper.MIDI_GetPPQPosFromProjTime(take, timeEnd)

-- Compute scaling factor
local factor = (ppqEnd - ppqStart) / (lastNote - firstNote)


--[--[----[----[----[----[----[----[----[----[----[----[----[----[----[----[----[----[----[--
  -- Run it!
-- Begin undo block
local proj = 0
reaper.Undo_BeginBlock2(proj)
reaper.PreventUIRefresh(1)

-- Apply new positions
for i = 0, noteCount-1 do
  local retval, sel, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
  if sel then
    local newStart = ppqStart + (startppq - firstNote) * factor
    local newEnd   = ppqStart + (endppq - firstNote) * factor
    -----------------------------------------------------------------------------------------


    -- round to nearest integer PPQ
    newStart = math.floor(newStart + 0.5)
    newEnd   = math.floor(newEnd + 0.5)
    ------------------------------------
    reaper.MIDI_SetNote(take, i, sel, muted, newStart, newEnd, chan, pitch, vel, true)
  end
end

-- Commit changes
reaper.MIDI_Sort(take)
reaper.MarkTrackItemsDirty(
  reaper.GetMediaItemTake_Track(take),
  reaper.GetMediaItemTake_Item(take)
)
-- Makes sure that the changes are being marked in the Undo/Redo history, without these, it won't create any points
-- Causing a lack of undo/redo points issue.

-- End undo block
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(proj, "Stretch selected MIDI notes to fit time selection", -1)
--[--[----[----[----[----[----[----[----[----[----[----[----[----[----[----[----[----[----[--


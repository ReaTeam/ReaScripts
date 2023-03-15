-- @description Smart split MIDI item
-- @author solger
-- @version 2.0
-- @changelog
--   + Keep MIDI Editor open or closed afterwards depending on its status before 
--   + Some minor code optimizations
-- @metapackage
-- @provides
--   [main] . > solger_Smart split MIDI item (trim shorter note parts at cursor).lua
--   [main] . > solger_Smart split MIDI item (trim left note parts at cursor).lua
--   [main] . > solger_Smart split MIDI item (trim right note parts at cursor).lua
-- @about
--   These scripts split a MIDI item and trim the (shorter, left or right) note parts at the cursor position.
--   The threshold of the note part length which should be trimmed can be adjusted in each script.
--   By default all notes under the cursor are trimmed.
--
--   Also big thanks to Stevie and me2beats for some code snippets and ideas
--   and to cfillion for the support to get the first version ready for ReaPack.
--
--   Make sure to check out their repositories and scripts, as well :)

---------------------------------------------------------------------------
-- noteLength: 0.25 = sixteenth note | 0.5 = eighth note | 1 = quarter note
---------------------------------------------------------------------------
-- noteMultiplier: 0 = no threshold (all selected notes are trimmed)
--------------------------------------------------------------------
local noteLength = 0.25
local noteMultiplier = 0
----------------------------------------------
-- trimThreshold = noteLength * noteMultiplier
-------------------------------------------------
local trimThreshold = noteLength * noteMultiplier
-------------------------------------------------

local r = reaper
local scriptName = ({r.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local trimMode = ({
  shorter = 1,
  left    = 2,
  right   = 3,
})[scriptName:match('%(trim (.+) note parts at cursor%)$')]
assert(trimMode, 'invalid filename')
-------------------------------------------------
local function Deselect(take, noteIndex)
  r.MIDI_DisableSort(take)
  r.MIDI_SetNote(take, noteIndex, false, nil, nil, nil, nil, nil, nil, nil)
  r.MIDI_Sort(take)
end

local function Select(take, noteIndex)
  r.MIDI_DisableSort(take)
  r.MIDI_SetNote(take, noteIndex, true, nil, nil, nil, nil, nil, nil, nil)
  r.MIDI_Sort(take)
end

local function TrimLeftPart(take, noteIndex, cursorPPQ, startPPQ, trimThreshold)
  if trimThreshold > 0 and r.MIDI_GetProjQNFromPPQPos(take, cursorPPQ - startPPQ) > trimThreshold then
    Deselect(take, noteIndex)
  end
  r.MIDIEditor_LastFocused_OnCommand(40790, 0) -- Edit: Trim left edge of note to edit cursor
end

local function TrimRightPart(take, noteIndex, cursorPPQ, endPPQ, trimThreshold)
  if trimThreshold > 0 and r.MIDI_GetProjQNFromPPQPos(take, endPPQ - cursorPPQ) > trimThreshold then
    Deselect(take, noteIndex)
  end
  r.MIDIEditor_LastFocused_OnCommand(40791, 0) -- Edit: Trim right edge of note to edit cursor
end

local function TrimShorterPart(take, noteIndex, muted, cursorPPQ, startPPQ, endPPQ, channel, pitch, velocity, trimThreshold)
  local partLeft = cursorPPQ - startPPQ
  local partRight = endPPQ - cursorPPQ

  if startPPQ < cursorPPQ and endPPQ > cursorPPQ then
    r.MIDI_SetNote(take, noteIndex, nil, nil, nil, nil, nil, nil, nil)
    if partLeft < partRight then
      -- left part is shorter
      if trimThreshold == 0 or r.MIDI_GetProjQNFromPPQPos(take, partLeft) <= trimThreshold then
        r.MIDI_InsertNote(take, 0, muted, cursorPPQ, endPPQ, channel, pitch, velocity, 0)
      else
        Deselect(take, noteIndex)
      end
    else
      -- right part is shorter
      if trimThreshold == 0 or r.MIDI_GetProjQNFromPPQPos(take, partRight) <= trimThreshold then
        r.MIDI_InsertNote(take, 0, muted, startPPQ, cursorPPQ, channel, pitch, velocity, 0)
      else
        Deselect(take, noteIndex)
      end
    end
  end
end

local closeMEafterwards = false
if not r.MIDIEditor_GetActive() then
  r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
  closeMEafterwards = true
end

local currentTake = r.MIDIEditor_GetTake(r.MIDIEditor_GetActive())
if not currentTake then return end

local _, noteCount = r.MIDI_CountEvts(currentTake)
if noteCount == 0 then return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local selectedItem = r.GetSelectedMediaItem(0, 0)
if selectedItem == nil then
  r.ShowMessageBox("Please select a MIDI item", "Error", 0)
  return
else
  for t = 0, r.CountTakes(selectedItem)-1 do
    local take = r.GetTake(selectedItem, t)
    if r.TakeIsMIDI(take) then
      local editCursorPPQ = r.MIDI_GetPPQPosFromProjTime(take, r.GetCursorPosition())
      local notes, _, _ = r.MIDI_CountEvts(take)
      for n = 0, notes - 1 do
        local _, _, _, startPPQ, endPPQ, _, _, _ = r.MIDI_GetNote(take, n)
        if startPPQ < editCursorPPQ and endPPQ > editCursorPPQ then
          Select(take, n)
        else
          Deselect(take, n)
        end
      end
    end
  end

  r.UpdateArrange()

  local correctOverlappingNotes
  if r.GetToggleCommandStateEx(32060, 40681) == 1 then
    r.MIDIEditor_LastFocused_OnCommand(40681, 0) -- Options: Correct overlapping notes while editing
    correctOverlappingNotes = 1
  end

  for currentNote = noteCount-1, 0, -1 do
    local _, selected, muted, startPPQ, endPPQ, channel, pitch, velocity = r.MIDI_GetNote(currentTake, currentNote)
    if selected then
      local cursorPPQ = math.floor(r.MIDI_GetPPQPosFromProjTime(currentTake, r.GetCursorPosition()) + 0.5)
      if trimMode == 1 then
        TrimShorterPart(currentTake, currentNote, muted, cursorPPQ, startPPQ, endPPQ, channel, pitch, velocity, trimThreshold)
      elseif trimMode == 2 then
        TrimLeftPart(currentTake, currentNote, cursorPPQ, startPPQ, trimThreshold)
      elseif trimMode == 3 then
        TrimRightPart(currentTake, currentNote, cursorPPQ, endPPQ, trimThreshold)
      end
    end
  end
end

if correctOverlappingNotes then r.MIDIEditor_LastFocused_OnCommand(40681, 0) end
if trimMode == 1 then
  r.MIDIEditor_LastFocused_OnCommand(40002, 0) -- EDIT: Delete notes
else
  r.MIDIEditor_LastFocused_OnCommand(40214, 0) -- Edit: Unselect all
end

if closeMEafterwards then
  r.MIDIEditor_OnCommand(r.MIDIEditor_GetActive(), 40794) -- View: Toggle show MIDI editor windows
end

r.Main_OnCommand(40757, 0) -- Item: Split items at edit cursor (no change selection)
r.PreventUIRefresh(-1)
r.Undo_EndBlock(scriptName, 1)

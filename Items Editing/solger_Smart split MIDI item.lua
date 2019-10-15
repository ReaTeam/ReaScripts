-- @description Smart split MIDI item
-- @author solger
-- @version 1.0
-- @changelog First version
-- @metapackage
-- @provides
--   [main] . > solger_Smart split MIDI item (trim shorter note parts at cursor).lua
--   [main] . > solger_Smart split MIDI item (trim left note parts at cursor).lua
--   [main] . > solger_Smart split MIDI item (trim right note parts at cursor).lua
-- @about
--   These scripts split a MIDI item and trim the (shorter, left or right) note parts at the cursor position. The threshold of the note part length which should be trimmed can be adjusted in each script (by default all notes under the cursor are trimmed).
--
--   Also big thanks to Stevie and me2beats for some code snippets and ideas :)  
--   So make sure to check out their repositories, as well.

---------------------------------------------------------------------------
-- noteLength: 0.25 = sixteenth note | 0.5 = eighth note | 1 = quarter note
---------------------------------------------------------------------------
-- multiplier: 0 = no threshold (all selected notes are trimmed)
----------------------------------------------------------------
local noteLength = 0.25
local noteMultiplier = 0
------------------------------------------
-- trimThreshold = noteLength * multiplier
-------------------------------------------------
local trimThreshold = noteLength * noteMultiplier
-------------------------------------------------
local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local trimMode = ({
  shorter = 1,
  left    = 2,
  right   = 3,
})[scriptName:match('%(trim (.+) note parts at cursor%)$')]
assert(trimMode, 'invalid filename')
-------------------------------------------------

local r = reaper

function TrimLeftPart(take, i, cursorPPQ, startPPQ, trimThreshold)
  if trimThreshold > 0 and r.MIDI_GetProjQNFromPPQPos(take, cursorPPQ - startPPQ) > trimThreshold then
    r.MIDI_SetNote(take, i, false, nil, nil, nil, nil, nil, nil, true)
  end
  reaper.MIDIEditor_LastFocused_OnCommand(40790, 0) -- Edit: Trim left edge of note to edit cursor
end

function TrimRightPart(take, i, cursorPPQ, endPPQ, trimThreshold)
  if trimThreshold > 0 and r.MIDI_GetProjQNFromPPQPos(take, endPPQ - cursorPPQ) > trimThreshold then
    r.MIDI_SetNote(take, i, false, nil, nil, nil, nil, nil, nil, true)
  end
  reaper.MIDIEditor_LastFocused_OnCommand(40791, 0) -- Edit: Trim right edge of note to edit cursor
end

function TrimShorterPart(take, i, muted, cursorPPQ, startPPQ, endPPQ, channel, pitch, velocity, trimThreshold)
  local partLeft = cursorPPQ - startPPQ
  local partRight = endPPQ - cursorPPQ

  if startPPQ < cursorPPQ and endPPQ > cursorPPQ then
    r.MIDI_SetNote(take, i, nil, nil, nil, nil, nil, nil, nil)
    if partLeft < partRight then
      -- left part is shorter
      if trimThreshold == 0 or r.MIDI_GetProjQNFromPPQPos(take, partLeft) <= trimThreshold then
        r.MIDI_InsertNote(take, 0, muted, cursorPPQ, endPPQ, channel, pitch, velocity, 0)
      else
        r.MIDI_SetNote(take, i, false, nil, nil, nil, nil, nil, nil, true)
      end
    else
      -- right part is shorter
      if trimThreshold == 0 or r.MIDI_GetProjQNFromPPQPos(take, partRight) <= trimThreshold then
        r.MIDI_InsertNote(take, 0, muted, startPPQ, cursorPPQ, channel, pitch, velocity, 0)
      else
        r.MIDI_SetNote(take, i, false, nil, nil, nil, nil, nil, nil, true)
      end
    end
  end
end

r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)

local currentTake = r.MIDIEditor_GetTake(r.MIDIEditor_GetActive())
if not currentTake then return end

local _, noteCount = r.MIDI_CountEvts(currentTake)
if noteCount == 0 then return end

reaper.Undo_BeginBlock()
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
          r.MIDI_SetNote(take, n, true, nil, nil, nil, nil, nil, nil, true)
        else
          r.MIDI_SetNote(take, n, false, nil, nil, nil, nil, nil, nil, true)
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

  for i = noteCount-1, 0, -1 do
    local _, selected, muted, startPPQ, endPPQ, channel, pitch, velocity = r.MIDI_GetNote(currentTake, i)
    if selected then
      local cursorPPQ = math.floor(r.MIDI_GetPPQPosFromProjTime(currentTake, r.GetCursorPosition()) + 0.5)
      if trimMode == 1 then
        TrimShorterPart(currentTake, i, muted, cursorPPQ, startPPQ, endPPQ, channel, pitch, velocity, trimThreshold)
      elseif trimMode == 2 then
        TrimLeftPart(currentTake, i, cursorPPQ, startPPQ, trimThreshold)
      elseif trimMode == 3 then
        TrimRightPart(currentTake, i, cursorPPQ, endPPQ, trimThreshold)
      end
    end
  end
end

if correctOverlappingNotes then r.MIDIEditor_LastFocused_OnCommand(40681,0) end
if trimMode == 1 then
  r.MIDIEditor_LastFocused_OnCommand(40002, 0) -- EDIT: Delete notes
else
  r.MIDIEditor_LastFocused_OnCommand(40214, 0) -- Edit: Unselect all
end

r.Main_OnCommand(40757, 0) -- Item: Split items at edit cursor (no change selection)
r.PreventUIRefresh(-1)
reaper.Undo_EndBlock(scriptName, 1)

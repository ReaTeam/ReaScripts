-- @description Smart split MIDI item (trim right note parts at cursor)
-- @author solger
-- @version 1.0
-- @changelog First version
-- @about
--   This script splits a MIDI item and trims the right note parts at the cursor position. The threshold of the right note part length which should be trimmed can be adjusted in the script.
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
local r = reaper
r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)

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
    local _, selected, _, _, noteEndPPQ, _, _, _ = r.MIDI_GetNote(currentTake, i)
    if selected then
      local cursorPPQ = math.floor(r.MIDI_GetPPQPosFromProjTime(currentTake, r.GetCursorPosition()) + 0.5)
        if trimThreshold > 0 and r.MIDI_GetProjQNFromPPQPos(currentTake, noteEndPPQ - cursorPPQ) > trimThreshold then
          r.MIDI_SetNote(currentTake, i, false, nil, nil, nil, nil, nil, nil, true)
        end
      end
    end

  reaper.MIDIEditor_LastFocused_OnCommand(40791, 0) -- Edit: Trim right edge of note to edit cursor
  if correctOverlappingNotes then r.MIDIEditor_LastFocused_OnCommand(40681, 0) end
  r.MIDIEditor_LastFocused_OnCommand(40214, 0) -- Edit: Unselect all
  r.Main_OnCommand(40757, 0) -- Item: Split items at edit cursor (no change selection)
end

r.PreventUIRefresh(-1)
r.Undo_EndBlock('Smart split MIDI item (trim right note parts at cursor)', -1)

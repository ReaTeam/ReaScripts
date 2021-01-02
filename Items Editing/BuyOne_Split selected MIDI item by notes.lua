-- @description Split selected MIDI item by notes
-- @author BuyOne
-- @version 1.0
-- @about To be run from Arrange. The notes must not overlap, or they will be corrected if confirmed by the user.
-- @website
--    Author Profile https://forum.cockos.com/member.php?u=134058
--    Idea source    https://reddit.com/r/Reaper/comments/js4ipe/split_midi_items_into_their_individual_notes/

-- Licence: WTFPL

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.Main_OnCommand(41173,0) -- Item navigation: Move cursor to start of items
local item = reaper.GetSelectedMediaItem(0,0)
	if not item then reaper.MB("No selected items.","ERROR",0) return end

local take = reaper.GetActiveTake(item)
reaper.Main_OnCommand(40153,0)  -- Item: Open in built-in MIDI editor (set default behavior in preferences)
local hwnd = reaper.MIDIEditor_GetActive()
local retval, notecnt, _, _ = reaper.MIDI_CountEvts(take)

local check = true -- condition to trigger error message only once during check for overlapping notes in a poliphonic melody

::RESTART::

reaper.Main_OnCommand(40153,0)  -- Item: Open in built-in MIDI editor (set default behavior in preferences)
local hwnd = reaper.MIDIEditor_GetActive()

reaper.MIDIEditor_OnCommand(hwnd,40659) -- Correct overlapping notes (of the same pitch)

-- Correct overlapping notes of different pitches using the same method as the above action employs, that is preserving start positions
local i = 0
	while i < notecnt do
	local retval, _, _, _, end_pos, _, _, _ = reaper.MIDI_GetNote(take, i)
	local retval, _, _, start_pos, _, _, _, _ = reaper.MIDI_GetNote(take, i+1)
		if end_pos > start_pos and check then break end
		if start_pos ~= 0 then -- to prevent setting last note end_pos to 0 since there's no next note to derive start_pos from
		reaper.MIDI_SetNote(take, i, selectedIn, mutedIn, startppqposIn, start_pos, chanIn, pitchIn, velIn, noSortIn)
		end
	i = i + 1
	end

	reaper.MIDI_Sort(take)

-- Display prompt if notes overlap
	if i < notecnt then
	reaper.MIDIEditor_OnCommand(hwnd,2) -- File: Close window (so that it doesn't stay in the background of the error message)
	resp = reaper.MB('      There\'re overlapping notes.\n\n        Should they all be fixed?\n\n  Start positions will be preserved.','PROMPT',4)
		if resp == 6 then check = nil goto RESTART
		else return end
	end


reaper.MIDIEditor_OnCommand(hwnd,40036) -- View: Go to start of file
reaper.MIDIEditor_OnCommand(hwnd,40214) -- Edit: Unselect all

local i = 0
	while i < notecnt do
	reaper.MIDIEditor_OnCommand(hwnd,40425) -- Select note nearest to the edit cursor
	reaper.MIDIEditor_OnCommand(hwnd,40413) -- Navigate: Select next note
	reaper.MIDIEditor_OnCommand(hwnd,40440) -- Navigate: Move edit cursor to start of selected events
	reaper.Main_OnCommand(40759,0) -- Item: Split items at edit cursor (select right)
	i = i + 1
	end

reaper.MIDIEditor_OnCommand(hwnd,2) -- File: Close window


reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Split selected MIDI item by notes",-1)

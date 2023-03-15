--[[
ReaScript name: Split selected MIDI item at every note or chord
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Improved reliability in different situations
	   #Added support for chords
	   #Updated the script name to be more descriptive
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
Screenshot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Split%20selected%20MIDI%20item%20at%20every%20note%20or%20chord.gif
About: 	Splits selected MIDI item at every note or chord start.

	To be run from Arrange. The notes must not overlap,
	or they will be corrected if confirmed by the user.
	If declined the script won't run.

	Supports both melodic and harmony parts. The length
	is only preserved for notes and chords which don't
	overlap notes/chords which follow them.

	Chord notes whose start times differ will be treated
	as overlapping notes and chord structure won't be
	preserved if notes correction is applied.

	Demo: https://raw.githubusercontent.com/Buy-One/screenshots/main/Split%20selected%20MIDI%20item%20at%20every%20note%20or%20chord.gif
]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------
-- To enable insert any aplhanumeric character between
-- the quotation marks

-- If enabled, each split MIDI item slice will become an independent
-- item, otherwise they will simply be a trimmed version 
-- of the original item still containing all the other notes
GLUE_SLICES = "1"

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function ACT(comm_id, midi) -- midi is boolean
local act = midi and r.MIDIEditor_LastFocused_OnCommand(comm_id, false) -- islistviewcommand false
or r.Main_OnCommand(comm_id, 0)
end

r.PreventUIRefresh(1)

ACT(41173) -- Item navigation: Move cursor to start of items
local item = r.GetSelectedMediaItem(0,0)
	if not item then r.MB('No selected items.','ERROR',0) return r.defer(function() do return end end) end

local take = r.GetActiveTake(item)
local retval, notecnt, _, _ = r.MIDI_CountEvts(take)

-- Find if there're any overlapping notes
local i = 0
	while i < notecnt do
	local retval, _, _, start_pos1, end_pos, _, _, _ = r.MIDI_GetNote(take, i)
	local retval, _, _, start_pos2, _, _, _, _ = r.MIDI_GetNote(take, i+1)
		if start_pos1 < start_pos2 and end_pos > start_pos2 and start_pos2 ~= 0 then break end -- -- start_pos1 < start_pos2 to ignore simultaneous chord notes, start_pos ~= 0 to ignore a non-existing note index beyond the note count whose start_pos will be 0
	i = i + 1
	end


r.Undo_BeginBlock()

-- Display prompt if notes overlap
	if i < notecnt then
	ACT(2, true) -- File: Close window (so that it doesn't stay in the background of the error message)
	resp = r.MB('      There\'re overlapping notes.\n\n        Should they all be fixed?\n\n  Start positions will be preserved.','PROMPT',4)
		if resp == 6 then
		-- Correct overlapping notes preserving start positions
		local i = 0
		local chord_notes_t = {}
			while i < notecnt do
			local retval, _, _, start_pos1, end_pos, _, _, _ = r.MIDI_GetNote(take, i)
			local retval, _, _, start_pos2, _, _, _, _ = r.MIDI_GetNote(take, i+1)
			if start_pos1 == start_pos2 then -- collect all notes statring simultaneously (chord notes)
			chord_notes_t[i], chord_notes_t[i+1] = 1, 1 -- dummy values
			elseif start_pos1 < start_pos2 and end_pos > start_pos2 and start_pos2 ~= 0 then -- as soon as an overlapping note  which starts later (the closest one) is found // start_pos1 < start_pos2 to ignore simultaneous chord notes, start_pos ~= 0 to ignore a non-existing note index beyond the note count whose start_pos will be 0 thereby preventing setting the last note end_pos to 0
				if next(chord_notes_t) then -- if the table isn't empty, i.e. there're chord notes starting simultaneously
					for note_idx in pairs(chord_notes_t) do -- correct them (trim down to the start of the closest overlapping note)
					r.MIDI_SetNote(take, note_idx, selectedIn, mutedIn, startppqposIn, start_pos2, chanIn, pitchIn, velIn, true) -- noSortIn
					end
				r.MIDI_Sort(take)
				chord_notes_t = {}
				else -- if no chord notes, simply correct the current note
				r.MIDI_SetNote(take, i, selectedIn, mutedIn, startppqposIn, start_pos2, chanIn, pitchIn, velIn, true) -- noSortIn
				end
			end
			i = i + 1
			end
		r.MIDI_Sort(take)
		else return r.defer(function() do return end end) end
	end


ACT(40153) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
ACT(40036, true) -- View: Go to start of file
ACT(40214, true) -- Edit: Unselect all


function find_first_next_note(take, start_pos) -- the first which stars later than the given one which allows ignoring chord notes in case they start simultaneously
local retval, notecnt, _, _ = r.MIDI_CountEvts(take)
local i = 0
	while i < notecnt do
	local retval, _, _, start_pos_next, _, _, _, _ = r.MIDI_GetNote(take, i)
		if start_pos_next > start_pos then return start_pos_next end
	i = i+1
	end
end

GLUE_SLICES = #GLUE_SLICES:gsub(' ','') > 0
local cur_pos = r.GetCursorPosition() -- store pos at the start of the file to restore view after gluing because for some reason it makes the timeline scroll

local i = 0
	while i < notecnt do -- using original note count
	local item = r.GetSelectedMediaItem(0,0) -- get the next slice pointer
	local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local take = r.GetActiveTake(item) -- get the next slice take pointer
	local idx = GLUE_SLICES and 0 or i -- if split slices aren't glued index 0 will still refer to the 1st note of the original item because the slice will be a trimmed copy of the original and contain all its notes, hence index based on the original item must be used to get each subsequent note
	local retval, _, _, start_pos, _, _, _, _ = r.MIDI_GetNote(take, idx) -- accounting for cases where the very 1st note start is later than the item start so the cursor has to move to the very 1st note to perform the split
	local proj_start_pos = r.MIDI_GetProjTimeFromPPQPos(take, start_pos)
		if proj_start_pos == item_pos then -- in all other cases where the 1st note of each subsequent split is alighned with the split item start, get the next, 2nd note, to move the cursor to
		local start_pos_next = find_first_next_note(take, start_pos)
		proj_start_pos = start_pos_next and r.MIDI_GetProjTimeFromPPQPos(take, start_pos_next) -- start_pos_next can be nil if the last note has been reached since there'll be no next
		end
		if proj_start_pos then -- can be nil if the last note has been reached since there'll be no next
		r.SetEditCurPos(proj_start_pos, false, false) -- moveview, seekplay false
		ACT(40759) -- Item: Split items at edit cursor (select right)
		local glue = GLUE_SLICES and ACT(42432) -- Item: Glue items
		end
	i = i + 1
	end

ACT(2, true) -- File: Close window

local restore = GLUE_SLICES and r.SetEditCurPos(cur_pos, true, false) -- moveview true, seekplay false

r.PreventUIRefresh(-1)
r.Undo_EndBlock("Split selected MIDI item at every note or chord",-1)






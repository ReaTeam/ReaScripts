--[[
ReaScript name: Split selected MIDI item at every note or chord
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.2
Changelog: 1.2 	#Made the script compatible with preference 
		Preferences -> Media -> MIDI -> Allow trim of MIDI items when splitting
		added in REAPER build 6.74
		#Prevented unnecessary zooming if MIDI Editor is open
		at the moment of the script execution
		#Prevented closure of the MIDI Editor if it was open initially
		#Included option to split even if notes at different pitches overlap
		#Re-organized the code
		#Updated GLUE_SLICES setting description
		#Updated 'About' text to reflect the new functionality
 	 1.1	#Improved reliability in different situations
		#Added support for chords
		#Updated the script name to be more descriptive
Licence: WTFPL
REAPER: at least v5.962
Provides: [main=main,midi_editor] .
Screenshot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Split%20selected%20MIDI%20item%20at%20every%20note%20or%20chord.gif
About: 	Splits selected MIDI item at every note or chord start.

	Supports both melodic and harmony parts.

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
-- of the original item still containing all other notes;
-- applicable to REAPER builds older than 6.74 and newer builds
-- where Preferences -> Media -> MIDI -> Allow trim of MIDI items when splitting
-- preference is disabled, if the preference is enabled 
-- splits become independent by default with no need of gluing
GLUE_SLICES = ""

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function ACT(comm_ID, midi) -- midi is boolean
local comm_ID = comm_ID and r.NamedCommandLookup(comm_ID)
local act = comm_ID and comm_ID ~= 0 and (midi and r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
or not midi and r.Main_OnCommand(comm_ID, 0)) -- not midi cond is required because even if midi var is true the previous expression produces falsehood because the MIDIEditor_LastFocused_OnCommand() function doesn't return anything // only if valid command_ID
end


function MIDIEditor_GetActiveAndVisible()
-- solution to the problem described at https://forum.cockos.com/showthread.php?t=278871
local ME = r.MIDIEditor_GetActive()
local dockermode_idx, floating = r.DockIsChildOfDock(ME) -- floating is true regardless of the floating docker visibility
local dock_pos = r.DockGetPosition(dockermode_idx) -- -1=not found, 0=bottom, 1=left, 2=top, 3=right, 4=floating
-- OR
-- local floating = dock_pos == 4 -- another way to evaluate if docker is floating
-- the MIDI Editor is either not docked or docked in an open docker attached to the main window
	if ME and (dockermode_idx == -1 or dockermode_idx > -1 and not floating
	and r.GetToggleCommandStateEx(0,40279) == 1) -- View: Show docker
	then return ME, dock_pos
-- the MIDI Editor is docked in an open floating docker
	elseif ME and floating then
		-- INSTEAD OF THE LOOP below the following function can be used
		local ret, val = r.get_config_var_string('dockermode'..dockermode_idx)
			if val == '32768' then -- OR val ~= '98304' // open floating docker OR not closed floating docker
			return ME, 4
			end
		--[[ OR
		for line in io.lines(r.get_ini_file()) do
			if line:match('dockermode'..dockermode_idx)
			and line:match('32768') -- open floating docker
			-- OR
			-- and not line:match('98304') -- not closed floating docker
			then return ME, 4 -- here dock_pos will always be floating i.e. 4
			end
		end
		--]]
	end
end


function Extract_reaper_ini_val(key) -- the arg must be string
local ret, val = r.get_config_var_string(key)
return val
end


function find_first_next_note(take, start_pos) -- the first which starts later than the given one which allows ignoring chord notes in case they start simultaneously
local retval, notecnt, _, _ = r.MIDI_CountEvts(take)
local i = 0
	while i < notecnt do
	local retval, _, _, start_pos_next, _, _, _, _ = r.MIDI_GetNote(take, i)
		if start_pos_next > start_pos then return start_pos_next end
	i = i+1
	end
end



r.PreventUIRefresh(1)

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
	local resp = r.MB('\t   There\'re overlapping notes.\n\n\t     Should they all be fixed?\n\n\tStart positions will be preserved.'
	..'\n\n\t If not, some slices may end up\n\n\t      containing several notes.','PROMPT',3)
		if resp == 2 then return r.defer(function() do return end end) -- cacelled by the user
		elseif resp == 6 then -- user assented
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
		end
	end


local ME_vis = MIDIEditor_GetActiveAndVisible() -- when the script is executed while the MIDI Editor is already open, triggering the following action may result in zooming MIDI Editor to content and changing the original zoom amount, so use this var to condition the following action as well as preventing its closuse at the end of the routine
	if not ME_vis then
	ACT(40153) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
	end
ACT(40036, true) -- View: Go to start of file
ACT(40214, true) -- Edit: Unselect all

local trimmidionsplit = Extract_reaper_ini_val('trimmidionsplit')
GLUE_SLICES = #GLUE_SLICES:gsub(' ','') > 0 and (#trimmidionsplit == 0 or trimmidionsplit == '0') -- validating against the preference 'Preferences -> Media -> MIDI -> Allow trim of MIDI items when splitting' added circa 6.74 which if enabled (and it's enabled by default) makes all splits unique by default with no need of gluing; the evaluation be true if it doesn't exist or enabled (bits 1 or 5), in which case gluing will make sense
local cur_pos = r.GetCursorPosition() -- store pos at the start of the file to restore view after gluing because for some reason it makes the timeline scroll

ACT(41173) -- Item navigation: Move cursor to start of items

local i = 0
	while i < notecnt do -- using original note count
	local item = r.GetSelectedMediaItem(0,0) -- get the next slice pointer
	local item_pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local take = r.GetActiveTake(item) -- get the next slice take pointer
	local idx = (GLUE_SLICES or trimmidionsplit > '0') and 0 or i -- if split slices aren't glued index 0 will still refer to the 1st note of the original item because the slice will be a trimmed copy of the original and contain all its notes, hence index based on the original item must be used to get each subsequent note // when 'Preferences -> Media -> MIDI -> Allow trim of MIDI items when splitting' is enabled (bits 1 or 5) all splits become unique by default which affects index assignment here so must be treated like in case of gluing // elational operators work with single alphanumeric characters as well
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

	if not ME_vis then -- do not close ME if it was open initially
	ACT(2, true) -- File: Close window
	end

local restore = GLUE_SLICES and r.SetEditCurPos(cur_pos, true, false) -- moveview true, seekplay false


r.PreventUIRefresh(-1)
r.Undo_EndBlock("Split selected MIDI item at every note or chord",-1)






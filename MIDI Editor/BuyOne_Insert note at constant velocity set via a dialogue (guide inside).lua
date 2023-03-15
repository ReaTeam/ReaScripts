--[[
ReaScript name: Insert note at constant velocity set via a dialogue
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.4
Changelog: 
	#Fixed unnecessary scrolling when the scroll bar was shifted all the way to the right
Provides: [main=midi_editor] .
Screenshot: https://git.io/J0pdP
Licence: WTFPL
REAPER: at least v5.962
About:

	#### GUIDE

	Meant as an alternative to the native *'Edit: Insert note at mouse cursor'*
	action which inserts a note at the velocity of the last selected note or
	at the velocity set by clicking on the Piano roll graphic keyboard with
	no way to define a constant velocity to which each new note will be set.

	The script is basically the same as the following custom action:

	ACT 3 32060 "26f61be727877d41933795baf400dadf" "Custom: Insert note at velocity 100 (assign to double click in MIDI piano roll mouse modifiers) -- scalable" 40214 40001 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40463 40463 40463 40463 40463 40463 40463 40463 40463 40463 40464

	but with extra features.

	Unlike with left drag, the length of inserted note is dictated by the setting
	in the *'Notes:'* menu at the bottom of the Piano roll so it equals to the 
	length of current grid division.

	Since the note is inserted at mouse cursor strictly speaking clicking isn't required.

	However if assigned to 'double click' context at *'Preferences -> Mouse modifiers -> 
	MIDI Editor piano roll'*, and you don't want the cursor to move when a note 
	is inserted (default behavior) then make sure that in the parallel slot 
	or one with at least one same modifier under the 'left click' context there's 
	no action (Behavior) which moves the edit cursor, otherwise the first click 
	out of the two will change the edit cursor position.  
	If this can't be ensured, then run it independently of the mouse click,
	that is via a shortcut assigned to the sctript in the Action list.

	▓ ▪ INITIAL VELOCITY

	Initial velocity to which notes inserted with this script will be set to
	is controlled by the user modifiable INIT_VELOCITY parameter in the
	USER SETTINGS below. It is constant until changed via the dialogue.

	▓ ▪ DIALOGUE

	In order to set velocity for all new notes to anything other than INIT_VELOCITY,
	move the mouse cursor away from the Piano roll (e.g. place it above Piano roll
	graphic keyboard or the main toolbar or the bottom part) and run the script.
	In the dialogue which will pop up key in the new velocity value and click 'OK'.
	In order to reset the operational velocity back to the INIT_VELOCITY value
	enter 0 in the dialogue field.

	The velocity value set via the dialogue is stored in the project file.
	If the project file wasn't saved after using the dialogue, in the next
	session the script will start out with INIT_VELOCITY.

	▓ ▪ MODIFIER

	You can set selected notes to the new velocity specified in the dialogue
	by adding any alphabetic character after the velocity value. Select notes
	before calling the dialogue as it blocks the UI.

	If the dialogue is called from inside a floating MIDI Editor window, the window
	will lose focus and will have to be put back into it with a mouse click.
	Until then the script won't run if called with a shortcut.
	
	The script isn't designed to work with MIDI Inline editor.
	
	▓ ▪ IGNORE_MARGINS
	
	This setting prevents REAPER action 'Edit: Insert note at mouse cursor', which
	is used in this script, from inserting a note when the mouse cursor is outside
	of the active Piano roll area on the left (excluding the graphic keyboard) or right 
	(essentially outside of the item bounds) because it may trigger the dialogue 
	when it's uncalled for.  
	This comes at a small price of the edit cursor slightly jolting every time a note 
	is inserted in the active Piano roll area and inability to extend the item by 
	inserting a note outside of its bounds while 'Loop item source' option is OFF.
	
	If you find edit cursor jerks annoying you can disable this setting but then
	try to avoid running the script when the mouse cursor is outside of the active 
	Paino roll area on the left (excluding the graphic keyboard) or right.
	
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- INIT_VELOCITY must have a value, otherwise the script will throw an error
-- Values outside of 1-127 range will be clamped to the closest valid value

INIT_VELOCITY = 100

-- To enable insert any alphanumeric character between the quotation marks.

IGNORE_MARGINS = "1"
-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')


function ACT(ID, ME)
-- ID - string or integer
	if ID then
	local ID = r.NamedCommandLookup(ID) -- works with srings and integers
		if not ME then r.Main_OnCommand(ID, 0)
		else
		r.MIDIEditor_LastFocused_OnCommand(ID, false) -- islistviewcommand is false
	--	r.MIDIEditor_OnCommand(ME, ID)
		end
	end
end


function Get_Note_Under_Mouse(midi_take, hwnd) -- returns note index or nil if no note under mouse cursor
r.PreventUIRefresh(1)
r.Undo_BeginBlock() -- to prevent creation of undo point by 'Edit: Split notes at mouse cursor'
local retval, notecntA, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(midi_take)
local props_t = {} 
	for i = 0, notecntA-1 do -- collect current notes properties
	local retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(midi_take, i)
	props_t[#props_t+1] = {startppq, endppq, pitch}
	end
local snap = r.GetToggleCommandStateEx(32060, 1014) == 1 -- View: Toggle snap to grid
local off = snap and r.MIDIEditor_OnCommand(hwnd, 1014) -- disable snap
r.MIDIEditor_OnCommand(hwnd, 40052)	-- Edit: Split notes at mouse cursor
local on = snap and r.MIDIEditor_OnCommand(hwnd, 1014) -- re-enable snap
local retval, notecntB, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(midi_take) -- re-count after split
local idx, fin, note
	if notecntB > notecntA then -- some note was split
		for i = 0, notecntB-1  do
		retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(midi_take, i)
		local v = props_t[i+1] -- +1 since table index is 1-based while note count is 0-based; the 1st part of the note will keep the note original index after split and after restoration
			if v and startppq == v[1] and endppq ~= v[2] and pitch == v[3] then 
			idx, fin, note = i, endppq, pitch end
			if idx and startppq == fin and pitch == note then -- locate the 2nd part of the split note
			r.MIDI_DeleteNote(midi_take, i) -- delete the 2nd part
			r.MIDI_SetNote(midi_take, idx, x, x, x, endppq, x, x, x, false) -- restore the note original length // selected, muted, startppq, chan, pitch, vel all nil, noSort false because only one note is affected
			return idx end			
		end
	end
r.PreventUIRefresh(-1)
r.Undo_EndBlock('',-1) -- to prevent creation of undo point by 'Edit: Split notes at mouse cursor'
end


local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)


	if Get_Note_Under_Mouse(take, ME) then return r.defer(function() end) end -- abort if note under mouse to prevent creation of overlapped notes because these get streched when set with MIDI_SetNote()
	-- https://forum.cockos.com/showthread.php?t=159848
	-- https://forum.cockos.com/showthread.php?t=195709 


	if #IGNORE_MARGINS:gsub(' ','') > 0 then

	-- Prevent note insert if mouse cursor is outside of the active Paino roll area (outside of item bounds) when 'Loop item source' option is ON for the active MIDI item; the reason is that it's inserted by 'Edit: Insert note at mouse cursor' action used in the script apparently treating the outside area as the looped iteration of the item; if 'Loop item source' option is OFF this action inserts the new note outside of the current item bounds having extended the item to accommodate the note; the downside of this routine will be inability to extend the MIDI item by inserting a note outside of its bounds when 'Loop item source' option is OFF

	r.PreventUIRefresh(1)
	local stored_edit_cur_pos = r.GetCursorPosition()
	local item = r.GetMediaItemTake_Item(take)
	ACT(40443, ME) -- View: Move edit cursor to mouse cursor
	local edit_cur_pos = r.GetCursorPosition()
	local item_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')
	local item_end = item_start + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
	r.SetEditCurPos(stored_edit_cur_pos, 0, 0) -- restore edit cursor pos; moveview is 0, seekplay is 0
		if edit_cur_pos >= item_end or edit_cur_pos <= item_start then
		return end
	r.PreventUIRefresh(-1)
	end


local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

r.SetExtState(cmd_ID..scr_name, 'note count', notecnt, false) -- persist is false; update note count before the main routine rather than after it to account for notes deleted and added by means other than this script in which case their count isn't updated in the extended state here, whereas if the extended state were set after the main routine it would cause the 'dialogue' routine to be skipped (due to the real world and stored counts inequality) without any note available for feeding to the function in the 'set velocity' routine because no note was inserted and is selected and ultimately causing the MIDI_SetNote() function to throw an error

local sel_note_t = {}

	for i = 0, notecnt-1 do -- store selected notes to allow user to set them to the new velocity via the dialogue; must be done before the new note is inserted because immediately prior to that the rest of the notes are all deselected so the newly inserted one is the only one selected which allows getting hold of it for velocity setting
	local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i)
		if sel then sel_note_t[#sel_note_t+1] = {i, startpos, pitch} end -- store index for selection restoration and setting velocities to multiple notes; startpos and pitch to restore note selection when inserting a note
	end


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

r.MIDI_SelectAll(take, 0) -- select is 0, i.e. unselect all // can't be moved to 'set velocity' routine since there will be no convenient way to get hold of the newly inserted note (unless it's the very last in the sequence along the timeline which isn't guaranteed); deselection of all current notes leaves the newly inserted note the only one selected and easy to get hold of
ACT(40001, ME) -- Edit: Insert note at mouse cursor

local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take) -- count after 'insert' action to find out if a note was inserted; if it wasn't then the cursor is outside of the Piano roll which is a condition to trigger the 'dialogue' routine

local old_notecnt = r.GetExtState(cmd_ID..scr_name, 'note count') -- note count before calling the note 'insert' action
local retval, velocity = r.GetProjExtState(0, cmd_ID..scr_name, 'velocity')

local INIT_VELOCITY = INIT_VELOCITY < 1 and 1 or INIT_VELOCITY > 127 and 127 or INIT_VELOCITY -- clamp values to the standard range


	if notecnt == 0 or notecnt == tonumber(old_notecnt) then -- call the dialogue to set new default velocity if note count is no different from the last count stored as extended state, meaning the cursor isn't over the piano roll when the script is called and so no new note has been added hence no change in the count
		for _, t in ipairs(sel_note_t) do -- reselect stored selected notes, if any, after they've been deselected above
		r.MIDI_SetNote(take, t[1], true, x, x, x, x, x, x, true) -- idx is t[1], selectedIn - true, mutedIn, startppqposIn, endppqposIn,, chanIn, velIn are nil, noSortIn true because multi
		end
	r.MIDI_Sort(take)
	::RETRY::
	local retval, output = r.GetUserInputs('Set default velocity (0 to reset)',1,'New default velocity (1 - 127):,extrawidth=20','')
	local output = output:gsub(' ','')
		if not retval or #output == 0 then return end
	local vel, modifier = output:match('^%d+'), output:match('%a+$')
		if vel and tonumber(vel) >= 0 and tonumber(vel) <= 127 then -- call the dialogue
		local vel = vel == '0' and '' or vel -- set to new velocity or restore the INIT_VELOCITY by deleting the velocity value from the key
		r.SetProjExtState(0, cmd_ID..scr_name, 'velocity', vel)
		else resp = r.MB('\t  I n v a l i d   e n t r y.\n\nMust be whole number in the range 1 - 127.\n\n        Type in 0 to reset to initial velocity\n\n         set in the script USER SETTINGS.', 'ERROR', 5)
			if resp == 4 then goto RETRY
			else return end
		end
		if modifier then -- apply velocity to selected notes
			if #sel_note_t == 0 then r.MB('       No selected notes.\n\nThe velocity has been set.', 'PROMPT',0) return
			else
			local vel = vel == '0' and INIT_VELOCITY or vel
				for _, t in ipairs(sel_note_t) do -- apply user chosen velocity to selected notes
				r.MIDI_SetNote(take, t[1], true, x, x, x, x, x, vel, true) -- set velocity; idx is t[1], selectedIn - true, mutedIn, startppqposIn, endppqposIn both, chanIn are nil, noSortIn true because multiple notes
				end
			r.MIDI_Sort(take)
			end -- sel_note_cnt cond end
		undo = 'Set selected notes to velocity '..vel
		else return
		end -- modifier cond end
	else -- set velocity to the inserted note
		for i = 0, notecnt-1 do -- get index of the inserted note which is selected by default and the only one selected since the rest have been deselected above
		local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i)
			if sel then idx = i break end
		end
	local vel = #velocity ~= 0 and velocity or INIT_VELOCITY -- if no default velocity as project extended state use the one from the USER SETTINGS
	r.MIDI_SetNote(take, idx, true, false, x, x, x, x, vel, false) -- set velocity; selectedIn - true, mutedIn - false, startppqposIn, endppqposIn, chanIn are nil, noSortIn - false since only one note prams are set
	undo = 'Insert note at velocity '..vel
		for i = 0, notecnt-1 do
		local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i)
			for _, t in ipairs(sel_note_t) do
				if startpos == t[2] and pitch == t[3] then r.MIDI_SetNote(take, i, true, mute, startpos, endpos, chan, pitch, vel, false) -- noSortIn - false since only one note prams are set
				end
			end
		end
	r.MIDI_Sort(take)
	end


-- a trick shared by juliansader; here it's used to make 'modifier' routine undo point register with the Undo_Begin/EndBlock() functions; Undo_OnStateChange() works too but with it the action 'Edit: Insert note at mouse cursor' creates one extra undo point in the 'insert' routine, therefore Undo_Begin/EndBlock() functions must stay
-- https://forum.cockos.com/showpost.php?p=1925555
local item = r.GetMediaItemTake_Item(take)
r.SetMediaItemSelected(item, false)
r.SetMediaItemSelected(item, true)

r.Undo_EndBlock(undo, -1)
r.PreventUIRefresh(-1)







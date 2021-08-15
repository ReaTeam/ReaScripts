--[[
ReaScript name: Insert note at constant velocity
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main=midi_editor] .
About:

	Meant as an alternative to the default note insert action which inserts a note 
	at the velocity of the last selected note with no way to define a constant 
	velocity to which each new note will be set.
	
	If assigned to 'double click' context at Preferences -> MIDI Editor piano roll, 
	make sure that in the parallel slot under the 'left click' context there's no 
	action (behavior) which moves the edit cursor, otherwise the first click out 
	of the two will change the edit cursor position.  
	If this can't be ensured, then run it independently of the mouse click, that 
	is via a shortcut assigned to the sctript in the Action list.
	
	BASICALLY SAME AS THE FOLLOWING CUSTOM ACTION

	ACT 3 32060 "26f61be727877d41933795baf400dadf" "Custom: Insert note at velocity 100 (assign to double click in MIDI piano roll mouse modifiers) -- scalable" 40214 40001 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40463 40463 40463 40463 40463 40463 40463 40463 40463 40463 40464

	but easier to manage the target velocity.

Licence: WTFPL
REAPER: at least v5.962

]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- VELOCITY must have a value, otherwise the script will throw an error

VELOCITY = 100

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function ACT(ID, ME)
	if ID then --ID = tostring(ID)
	local ID = r.NamedCommandLookup(ID)
		if not ME then r.Main_OnCommand(ID, 0)
		else
		r.MIDIEditor_LastFocused_OnCommand(ID, false) -- islistviewcommand is false	
		end
	end	
end


local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

r.MIDI_SelectAll(r.MIDIEditor_GetTake(ME), 0) -- select is 0, i.e. unselect all
ACT(40001, ME) -- Edit: Insert note at mouse cursor
local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

	for i = 0, notecnt-1 do -- get index of the inserted note which is selected by default
	local retval, sel, mute, startpos, endpos, chan, pitch, vel = r.MIDI_GetNote(take, i)
		if sel then idx = i break end
	end
	
r.MIDI_SetNote(take, idx, true, false, -1, -1, 0, -1, VELOCITY, false) -- set velocity; selectedIn - true, mutedIn - false, startppqposIn and endppqposIn both -1, chanIn - 0, noSortIn - false


r.Undo_EndBlock('Insert note at velocity '..VELOCITY, -1)
r.PreventUIRefresh(-1)
	




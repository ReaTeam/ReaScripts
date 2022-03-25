--[[
ReaScript name: Insert note at constant velocity depending on dummy toggle scripts
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Screenshot: https://raw.githubusercontent.com/Buy-One/screenshots/main/Insert%20note%20at%20constant%20velocity%20depending%20on%20dummy%20toggle%20scripts.gif
Version: 1.0
Changelog: Initial release
Provides: [main=midi_editor,midi_inlineeditor] .
Licence: WTFPL
REAPER: at least v5.962
About:
	Meant as an alternative to the default note insert action which inserts a note 
	at the velocity of the last selected note with no way to define a constant 
	velocity to which each new note will be set.  
	
	For proper functionality the script depends on 'Exclusive dummy toggles (12 scripts)' 
	script set which can be installed via ReaPack as well.  
	Velocity of a note inserted with this script is conditoned on the ON toggle state
	of one of such exclusive dummy toggle scripts.  
	For setup refer to the USER SETTINGS below.  
	If 'Exclusive dummy toggles (12 scripts)' set isn't installed this script defaults
	to velocity value of 100.  
	
	Since the script uses 'Edit: Insert note at mouse cursor' action, it obeys Grid if
	'Snap to grid' option is enabled.  
	Since a note is inserted at mouse cursor, strictly speaking clicking isn't necessary.

	However if assigned to 'double click' context at Preferences -> MIDI Editor piano roll, 
	and you don't want the cursor to move when a note is inserted (default behavior) 
	then make sure that in the parallel slot or one with at least one same modifier 
	under the 'left click' context there's no action (behavior) which moves the 
	edit cursor, otherwise the first click out of the two will change the edit 
	cursor position.  
	If this can't be ensured, then run it independently of the mouse click, that 
	is via a shortcut assigned to the script in the Action list.
	
	SCREENSHOT:  
	https://raw.githubusercontent.com/Buy-One/screenshots/main/Insert%20note%20at%20constant%20velocity%20depending%20on%20dummy%20toggle%20scripts.gif	
	
	The script behavior can be replicated with an SWS Cycle action which executes MIDI Editor
	custom actions depending on the state of dummy toggle scripts. As a blueprint for such custom
	actions the following code can be used (you can import it into the MIDI Editor section 
	of the Action list as a .ReaperKeyMap file):  
	ACT 3 32060 "26f61be727877d41933795baf400dadf" "Custom: Insert note at velocity 100 -- scalable" 40214 40001 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40465 40463 40463 40463 40463 40463 40463 40463 40463 40463 40463 40464 40659

	Create as many such custom actions as velocity presets you need by modifying this blueprint
	custom action to produce the required velocity value and then in the MIDI Editor section 
	of the Cycle action editor construct a Cycle action as follows:   
	
	IF      If next action is ON  
			Script: BuyOne_Exclusive dummy toggle 1.lua  
			Custom: Insert note at velocity A  
	ENDIF	End of conditional statement  
	IF      If next action is ON  
			Script: BuyOne_Exclusive dummy toggle 2.lua  
			Custom: Insert note at velocity B  
	ENDIF	End of conditional statement  
	IF      If next action is ON  
			Script: BuyOne_Exclusive dummy toggle 3.lua  
			Custom: Insert note at velocity C  
	ENDIF	End of conditional statement  
	
	and so on repeating the IF - ENDIF block as many times as needed.
	
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Between the quotation marks insert velocity values you'd like
-- to associate with each of 10 dummy toggle scripts,
-- since the toggle states of these scripts are mutually exclusive,
-- meaning when one is ON the rest are OFF, only one velocity preset
-- will be available at a time, which is what we want;
-- not all slots have to be filled out, only those which correspond
-- to the dummy toggle sctipts you're going to use to switch the presets;
-- if a preset corresponding to a dummy toggle script which is currently ON
-- happens to be empty OR no script whose state is ON has been found
-- the script will fall back on velocity 100;
-- velocity value which exceeds 127 (the maximum) will be clamped to 127;
-- this list can be expanded in case you create new dummy toggle scripts
-- by way of duplicating any of the existing ones and changing the number
-- in its name to a unique one;

PRESET1 = ""
PRESET2 = ""
PRESET3 = ""
PRESET4 = ""
PRESET5 = ""
PRESET6 = ""
PRESET7 = ""
PRESET8 = ""
PRESET9 = ""
PRESET10 = ""

-- If dummy toggle script set has been divided into several subsets
-- where all scripts in a subset are associated with specific user defined
-- letter of English alphabet in its USER SETTINGS, enter between
-- the quotation marks the letter associated with a subset whose scripts
-- you want to use for switching velocity presets;
-- if this setting is not enabled the active velocity preset will correspond
-- to the first (in ascending order) dummy toggle script whose state
-- is found to be ON;
-- if the setting is enabled but no matching subsets were found among dummy
-- toggle scripts, the velocity will fall back on 100.

SUBSET = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function ACT(ID, ME)
	if ID then
	local ID = r.NamedCommandLookup(ID)
		if not ME then r.Main_OnCommand(ID, 0)
		else
		r.MIDIEditor_LastFocused_OnCommand(ID, false) -- islistviewcommand is false
	--	r.MIDIEditor_OnCommand(ME, ID)
		end
	end
end

function Get_Dummy_Toggle_Script_Idx(SUBSET) -- collect all dummy toggle scripts in the same section and of the same subset as the current script to be able to set their state to OFF when the state of the current script is ON
local sep = r.GetResourcePath():match('[\\/]')
local res_path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]') -- path with separator
local cont
local f = io.open(res_path..'reaper-kb.ini', 'r')
	if f then -- if file available, just in case
	cont = f:read('*a')
	f:close()
	end
local is_scr, idx, scr_path, ON, subset
	if cont and cont ~= '' then
		for line in cont:gmatch('[^\n\r]*') do -- parse reaper-kb.ini code
		cmd_ID, idx, scr_path = line:match('SCR %d+ 32060 (.+) "Custom: .+_Exclusive dummy toggle (%d+)%.lua" "(.+)"')
			if cmd_ID then
			is_scr = 1
			local is_ON = r.GetToggleCommandStateEx(32060, r.NamedCommandLookup('_'..cmd_ID)) == 1 -- converting to integer
				if is_ON then ON = 1 end
				if #SUBSET > 0 then -- if the script is pointed at a subset of dummy toggle scripts, get subset assignment of each dummy toggle script in the MIDI Editor section
				local f = io.open(res_path..'Scripts'..sep..scr_path, 'r') -- get dummy toggle script code
				local cont = f:read('*a')
				f:close()
				subset = cont:match('\nMIDI_Ed = "(.-)"')
					if subset == SUBSET and is_ON then break
					end
				elseif is_ON then break
				end
			end
		end
	end
return is_scr, idx and tonumber(idx), ON, subset == SUBSET
end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper(), x, y, true) -- topmost true
end


SUBSET = SUBSET:gsub(' ',''):match('%a?') -- only first letter, in case several are entered, or none
local PRESET_T = {PRESET1, PRESET2, PRESET3, PRESET4,
PRESET5, PRESET6, PRESET7, PRESET8, PRESET9, PRESET10}
local is_scr, scr_idx, is_ON, subset = Get_Dummy_Toggle_Script_Idx(SUBSET)


-- Concatenate error messages
local ending = 'defaulting to 100.  \n\n '

	if not is_scr then -- dummy toggle scripts aren't installed
	err = '\n\n   no exclusive dummy toggle script  \n\n      was found. '..ending
	elseif not scr_idx and not is_ON then -- dummy toggle scripts are installed but no ON toggle state (either before they've been used or after startup without using startup actions)
	err = '\n\n   no dummy toggle script with "ON" state  \n\n'..string.rep(' ',10)..' was found. '..ending
	elseif not scr_idx and not subset then -- if there're no matches to the specified subset among the dummy toggle scripts
	err = '\n\n   no scripts of subset "'..SUBSET..'"  were found  \n\n'..string.rep(' ',18)..ending
	elseif scr_idx and (not tonumber(PRESET_T[scr_idx]) or tonumber(PRESET_T[scr_idx]) == 0) then -- if user vel value is invalid, zero or negative
	err = '\n\n   invalid velocity setting in PRESET'..scr_idx..'  \n\n'..string.rep(' ',18)..ending
	end

	if err then Error_Tooltip(err) end


local vel = scr_idx and #PRESET_T[scr_idx] > 0 and tonumber(PRESET_T[scr_idx]) or 100 -- if preset value is malformed or not set, or subset letter isn't found in scripts, fall back on 100
local vel = vel < 0 and math.floor(vel*-1) or vel == 0 and 100 or vel > 127 and 127 or math.floor(vel) -- if velocity is negative, convert to positive and truncate down to the whole part in case it's decimal, in case it's zero or a decimal value with the whole part being zero or the value exceeds 128 fall back on 100 or 127 respectively, else truncate down to the whole part in case decimal

local ME = r.MIDIEditor_GetActive()

r.PreventUIRefresh(1) -- doesn't prevent brief display of note velocity changes
r.Undo_BeginBlock() -- doesn't prevent adding an intermediary undo point 'MIDI Editor: Select events'

ACT(40214, ME) -- Edit: Unselect all
ACT(40001, ME) -- Edit: Insert note at mouse cursor

local midi_take = r.MIDIEditor_GetTake(ME)
local note_idx = r.MIDI_EnumSelNotes(midi_take, -1) -- -1 to get first selected note as the function returns index of the note following index used as the 2nd argument
r.MIDI_SetNote(midi_take, note_idx, true, false, x, x, x, x, vel, false) -- selectedIn true, mutedIn false, startppqposIn, endppqposIn, chanIn, pitchIn, velIn are all nil, noSortIn false

ACT(40659, ME) -- Correct overlapping notes


r.Undo_EndBlock('Insert note at velocity '..vel, -1)
r.PreventUIRefresh(-1)





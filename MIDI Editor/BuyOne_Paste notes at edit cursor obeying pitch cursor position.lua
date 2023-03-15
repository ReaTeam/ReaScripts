--[[
ReaScript name: Paste notes at edit cursor obeying pitch cursor position
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: The default paste action pastes notes at the same pitch(es).  
       The script provides an alternative.  
       Combined with the action 'View: Move edit cursor to mouse cursor'
       within a custom action can be used to paste notes at mouse cursor.  
       1. Copy selected notes
       2. Select the destination pitch by clicking on a key in the MIDI Editor graphic keyboard
       3. Run the script

       See USER SETTINGS
]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- To enable any of the following settings, place any QWERTY
-- character between the quotation marks.

-- Enable this setting so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

-- If enabled, the lowermost pasted note will always end up
-- at the destination pitch
LOWERMOST_LEADS = ""

-- If enabled while LOWERMOST_LEADS setting is not enabled,
-- the uppemost pasted note will always end up
-- at the destination pitch
UPPERMOST_LEADS = ""

-- If neither LOWERMOST_LEADS nor UPPERMOST_LEADS setting
-- is enabled, when pasting to a pitch above the uppermost 
-- selected note event the uppermost pasted event will end up 
-- at the destination pitch, when pasting to a pitch lower 
-- than the lowermost selected note event or to a pitch between 
-- the lowermost and the uppemost selected note events 
-- the lowermost pasted event will end up at the destination pitch

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper

function Script_Not_Enabled(ENABLE_SCRIPT)
	if #ENABLE_SCRIPT:gsub(' ','') == 0 then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)
	return true
	end
end

	if Script_Not_Enabled(ENABLE_SCRIPT) then return r.defer(function() do return end end) end


function Force_MIDI_Undo_Point(take)
-- a trick shared by juliansader to force MIDI API to register undo point; Undo_OnStateChange() works too but with native actions it may create extra undo points, therefore Undo_Begin/EndBlock() functions must stay
-- https://forum.cockos.com/showpost.php?p=1925555
local item = r.GetMediaItemTake_Item(take)
local is_item_sel = r.IsMediaItemSelected(item)
r.SetMediaItemSelected(item, not is_item_sel)
r.SetMediaItemSelected(item, is_item_sel)
end


LOWERMOST_LEADS = #LOWERMOST_LEADS:gsub(' ','') > 0
UPPERMOST_LEADS = #UPPERMOST_LEADS:gsub(' ','') > 0


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)

local retval, notecnt_init, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

r.MIDIEditor_LastFocused_OnCommand(40011, false) -- islistviewcommand false // Edit: Paste

local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

	if notecnt_init == notecnt then return r.defer(function() do return end end) end -- abort if nothing has been pasted
	
local i = -1
local highest, lowest = 0, 127 -- reversed to get full range
	repeat
	local note_idx = r.MIDI_EnumSelNotes(take, i)
	local retval, sel, muted, startppqpos, endppqpos, chan, pitch, vel = r.MIDI_GetNote(take, note_idx)
		if note_idx > -1 then -- valid selected note, when no more selected notes note_idx is -1
		highest = pitch > highest and pitch or highest
		lowest = pitch < lowest and pitch or lowest
		end
	i = i+1
	until note_idx == -1

local active_pitch = r.MIDIEditor_GetSetting_int(ME, 'active_note_row')
	if LOWERMOST_LEADS then
	dist = lowest - active_pitch
	elseif UPPERMOST_LEADS then
	dist = highest - active_pitch
	else
	dist = active_pitch > lowest and active_pitch < highest and lowest - active_pitch
	or highest < active_pitch and highest - active_pitch or lowest > active_pitch and lowest - active_pitch or 0
	end

local cmd
	for i=1, math.abs(dist) do
		if dist == 0 then break
		elseif dist > 0 then cmd = 40178 -- Edit: Move notes down one semitone
		elseif dist < 0 then cmd = 40177 -- Edit: Move notes up one semitone
		end
	r.MIDIEditor_LastFocused_OnCommand(cmd, false) -- islistviewcommand false
	end


Force_MIDI_Undo_Point(take)

r.Undo_EndBlock('Paste notes obeying pitch cursor position', -1)
r.PreventUIRefresh(-1)


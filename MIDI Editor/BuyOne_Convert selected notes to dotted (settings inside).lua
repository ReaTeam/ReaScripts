--[[
ReaScript name: Convert selected notes do dotted
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: Converts all selected notes to dotted notes
Provides: [main=midi_editor,midi_inlineeditor] .
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any QWERTY alphanumeric character between
-- the quotation marks.

-- Round a note to the closest musical division if its duration doesn't 
-- conform to any straight note;
-- if not enabled, a note of any length will be extended by 50% as if
-- it were regular straight note
ROUND_NOTE_DURATION = "" 

-- If converted notes of different pitches which weren't initially overlapping
-- end up overlapping each other as a result, nudge next one forward
CORRECT_OVERLAPPING_DIFF_PITCH = ""

-- Correct overlapping notes of the same pitch
-- whether selected or not
CORRECT_OVERLAPPING_SAME_PITCH = ""

-- If a note is already dotted, don't extend any further;
-- only relevant for notes with standard musical length
PREVENT_EXT_BEYOND_DOTTED = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function are_notes_selected(take)
local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
	for i = 0, notecnt-1 do
	local retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)
		if sel then return true end
	end
end


function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- topmost true
end


function validate(sett) -- validate setting, can be either a non-empty string or a number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end


function is_dotted(num) -- find if a note is already dotted, arg is duration in QN
--local t = {0.03125, 0.0625, 0.125, 0.25, 0.5, 1, 2, 4, 8} -- 1/128, 1/64, 1/32, 1/16, 1/8, 1/4, 1/2, 1, 2 // if using raw QN value num/1.5
local t = {0.5, 1, 2, 4, 8, 16, 32, 64, 128} -- 2 whole notes, whole, breve, crotchet, eighth, sixteenth etc // if converting raw QN value to fraction of a quarter note: 4/(num/1.5)
local num = 4/(num/1.5)
	for _, div in ipairs(t) do
		if num == div then return true end
	end
end


function round_note(num)
-- round note duration down or up to the closest straight musical division
--local t = {0.03125, 0.0625, 0.125, 0.25, 0.5, 1, 2, 4, 8} -- 1/128, 1/64, 1/32, 1/16, 1/8, 1/4, 1/2, 1, 2 // if using  raw QN value
local t = {0.5, 1, 2, 4, 8, 16, 32, 64, 128} -- 2 whole notes, whole, breve, crotchet, eighth, sixteenth etc // if converting raw QN value to fraction of a quarter note: 4/num, the return value must then be converted back to raw QN: 4/retval
	for k, div in ipairs(t) do
		if num == div then return div end
	local nxt = t[k+1]
		if nxt and num > div and num < nxt then
			if num - div < nxt - num then
			return div
			else return nxt
			end
		elseif k == 1 and num < div
		or k == #t and num > div
		then return div
		end		
	end	
end


r.PreventUIRefresh(1) -- barely helps with MIDI Inline editor

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()

	if sect_ID == 32062 then -- MIDI Inline editor
	r.Main_OnCommand(40153,0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)	
	end
	
local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)

	if not are_notes_selected(take) then
	Error_Tooltip(' \n\n no selected notes \n\n ')
	return r.defer(function() do return end end) end

local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)

ROUND_NOTE_DURATION = validate(ROUND_NOTE_DURATION)
CORRECT_OVERLAPPING_DIFF_PITCH = validate(CORRECT_OVERLAPPING_DIFF_PITCH)
CORRECT_OVERLAPPING_SAME_PITCH = validate(CORRECT_OVERLAPPING_SAME_PITCH)
PREVENT_EXT_BEYOND_DOTTED = validate(PREVENT_EXT_BEYOND_DOTTED)

r.Undo_BeginBlock()

	for i = 0, notecnt-1 do
	local retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i)	
	local startQN = r.MIDI_GetProjQNFromPPQPos(take, startppq)
	local noteQN_dur = r.MIDI_GetProjQNFromPPQPos(take, endppq) - startQN	
			if sel and (PREVENT_EXT_BEYOND_DOTTED and not is_dotted(noteQN_dur) or not PREVENT_EXT_BEYOND_DOTTED) then
			if ROUND_NOTE_DURATION then
			noteQN_dur = 4 / round_note(4/noteQN_dur)
			end
		local noteQN_dur_new = noteQN_dur*1.5 -- without rounding doesn't take into account musical length of the note and simply lengthens it by 50%
		local endQN_new = startQN + noteQN_dur_new
		local endppq_new = r.MIDI_GetPPQPosFromProjQN(take, endQN_new)
		local overlap_pre = endppq_prev and endppq_prev > startppq
		local overlap_post = startppq_new and startppq_new > startppq
		local startppq, endppq_new = table.unpack(not overlap_pre and overlap_post and {startppq_new, endppq_new + startppq_new - startppq} or {startppq, endppq_new}) -- depending on CORRECT_OVERLAPPING_DIFF_PITCH setting
		r.MIDI_SetNote(take, i, x, x, startppq, endppq_new, x, x, x, true) -- noSortIn true	
			if CORRECT_OVERLAPPING_DIFF_PITCH then -- store for the next cycle
			startppq_new = endppq_new
			endppq_prev = endppq
			end 
		end
	end

r.MIDI_Sort(take)

	if CORRECT_OVERLAPPING_SAME_PITCH then
	r.MIDIEditor_LastFocused_OnCommand(40659, false) -- Correct overlapping notes // islistviewcommand false
	end

r.Undo_EndBlock('Convert selected notes to dotted', 1)

	if sect_ID == 32062 then -- MIDI Inline editor
	r.MIDIEditor_LastFocused_OnCommand(2, false) -- File: Close window
	end

r.PreventUIRefresh(-1) -- barely helps with MIDI Inline editor


-- @noindex

--[[

* ReaScript Name: BuyOne_Move pitch cursor to the note ending at edit cursor.lua
* Description: Meant to complement native MIDI Editor actions for use in custom actions
* Instructions:
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Demo:
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M
* Changelog:
	+ v1.0 	Initial release

* Notes: 
-- If end times of several notes are identical like in a chord for example, pitch cursor moves to the highest note
-- In combination with the native actions 'Navigate: Select next/previous note' and 'Navigate: Move edit cursor to end of selected events' can be used to set pitch cursor to next/previous note

]]


function Msg(param)
reaper.ShowConsoleMsg(tostring(param).."\n")
end


local r = reaper

local hwnd = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(hwnd)

local retval, notecnt, _, _ = r.MIDI_CountEvts(take)

	if notecnt == 0 then r.MB('No notes in the MIDI item.','ERROR',0) return end

	if notecnt > 0 then
		for i = 0, notecnt-1 do
		local retval, sel, _, startpos, endpos, _, pitch, _ = r.MIDI_GetNote(take, i)
			if r.MIDI_GetProjTimeFromPPQPos(take, endpos) == reaper.GetCursorPosition() then
			r.MIDIEditor_SetSetting_int(hwnd, 'active_note_row', pitch) break end
		end
	r.Undo_BeginBlock()
	r.Undo_EndBlock(select(2,r.get_action_context()):match('([^\\/]+)%.%w+'),-1) -- pitch cursor movements don't create undo points so this is just to display some text in the Undo bar
	end




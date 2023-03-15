-- @noindex

--[[

* ReaScript Name: BuyOne_Move pitch cursor to the note nearest to or under edit cursor.lua
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
Note priority:
-- 1. When edit cursor is located between adjacent notes or they're equally distanced from it, the highest note to the right has priority
-- 2. To the left of edit cursor and directly under it if several notes have identical sart times the lowest one has priority. If their end times are identical but start times differ, priority has the note with the latest start time.
-- The note proirity in stacked notes directly under the edit cursor is simply a design choice, it could be different with the highest note having priority

]]


function Msg(param)
reaper.ShowConsoleMsg(tostring(param).."\n")
end


local r = reaper

local hwnd = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(hwnd)

local retval, notecnt, _, _ = r.MIDI_CountEvts(take)

--r.MIDI_SetNote(take, 4, true, mutedIn, startppqposIn, endppqposIn, chanIn, pitchIn, velIn, noSortIn)

	if notecnt == 0 then r.MB('No notes in the MIDI item.','ERROR',0) return end

	if notecnt > 0 then
	local t = {}
		for i = 0, notecnt-1 do
		local retval, sel, _, startpos, endpos, _, pitch, _ = r.MIDI_GetNote(take, i)
		local start_time = r.MIDI_GetProjTimeFromPPQPos(take, startpos)
		local end_time = r.MIDI_GetProjTimeFromPPQPos(take, endpos)
		local prev_note_end_time = r.MIDI_GetProjTimeFromPPQPos(take, select(5,r.MIDI_GetNote(take, i-1)))
		local curs_pos = reaper.GetCursorPosition()

		--[[
		-- Version in which when notes are stacked under the edit cursor the highest one has priority
			if end_time <= curs_pos then t[#t+1] = pitch -- all notes to the left of cursor
			elseif (start_time < curs_pos and end_time > curs_pos) or curs_pos - prev_note_end_time >= start_time - curs_pos then t[#t+1] = pitch break end
		]]
			if end_time <= curs_pos or (start_time < curs_pos and end_time > curs_pos) then t[#t+1] = pitch -- all notes to the left of cursor or under it
			elseif curs_pos - prev_note_end_time >= start_time - curs_pos then t[#t+1] = pitch break end
		end
	r.MIDIEditor_SetSetting_int(hwnd, 'active_note_row', t[#t])
	r.Undo_BeginBlock()
	r.Undo_EndBlock(select(2,r.get_action_context()):match('([^\\/]+)%.%w+'),-1) -- pitch cursor movements don't create undo points so this is just to display some text in the Undo bar
	end




-- @noindex

--[[

* ReaScript Name: BuyOne_Move edit and pitch cursors to the previous note relative to edit cursor.lua
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

* Notes: If there's a note at or under the edit cursor, the edit cursor moves to the end of the closest note to the left along with the pitch cursor

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
	reaper.PreventUIRefresh(1)
		for i = notecnt-1, 0, -1 do
		local retval, sel, _, startpos, endpos, _, pitch, _ = r.MIDI_GetNote(take, i)
		local end_time = r.MIDI_GetProjTimeFromPPQPos(take, endpos)
			if end_time < reaper.GetCursorPosition() then
			reaper.SetEditCurPos(end_time, false, false)
			r.MIDIEditor_SetSetting_int(hwnd, 'active_note_row', pitch) break end
		end
	reaper.PreventUIRefresh(-1)
	r.Undo_BeginBlock()
	r.Undo_EndBlock(select(2,r.get_action_context()):match('([^\\/]+)%.%w+'),-1) -- pitch cursor movements don't create undo points, edit cursor movements only create undo points when 'cursor position' option is checked in 'Include selection:' setting at Preferences -> General -> Undo settings, otherwise this is just to display some text in the Undo bar
	end





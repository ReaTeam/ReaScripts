-- @noindex

--[[

* ReaScript Name: BuyOne_Select only notes at pitch cursor.lua
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

* Notes: Works exclusively, other selected notes get deselected.

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
	reaper.Undo_BeginBlock()
	local pitch_curs_pos = r.MIDIEditor_GetSetting_int(hwnd, 'active_note_row')
		for i = 0, notecnt-1 do
		local retval, sel, _, startpos, endpos, _, pitch, _ = r.MIDI_GetNote(take, i)
			if pitch == pitch_curs_pos then r.MIDI_SetNote(take, i, true, muted, startpos, endpos, chan, pitch, vel,true) 
			else r.MIDI_SetNote(take, i, false, muted, startpos, endpos, chan, pitch, vel, true) 
			end
		end
	r.MIDI_Sort(take)
	r.MarkTrackItemsDirty(r.GetMediaItemTake_Track(take), r.GetMediaItemTake_Item(take))
	r.Undo_EndBlock(select(2,r.get_action_context()):match('([^\\/]+)%.%w+'),-1)
	end
	




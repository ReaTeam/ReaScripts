--[[
  * ReaScript Name: Delete note under mouse cursor
  * Description: Deletes the note your cursor is hovering over (Largely copied from a script by X-Raym)
  * Instructions:
  * Screenshot: 
  * Notes: 
  * Category: 
  * Author: Lokasenna
  * Author URI:
  * Licence: GPL v3
  * Forum Thread: 
  * Forum Thread URL:
  * Version: 1.0
  * REAPER:
  * Extensions: SWS
]]


-- For debugging purposes, prints a message to the Reaper console
function Msg(message)
	
	reaper.ShowConsoleMsg(tostring(message).."\n")
	
end



function Main()
	
	reaper.Undo_BeginBlock()
	
	cur_editor = reaper.MIDIEditor_GetActive()
	cur_take = reaper.MIDIEditor_GetTake(cur_editor)

	__, __, __ = reaper.BR_GetMouseCursorContext()
	__, noteRow, __, __, __ = reaper.BR_GetMouseCursorContext_MIDI()
	
	mouse_time = reaper.BR_GetMouseCursorContext_Position()
	mouse_ppq_pos = reaper.MIDI_GetPPQPosFromProjTime(cur_take, mouse_time)
	
	notes, __, __ = reaper.MIDI_CountEvts(cur_take)

	-- loop through every note in the current MIDI editor to see whether they're under the cursor
	for i = 0, notes - 1 do
		
		__, __, __, start_note, end_note, __, pitch, __ = reaper.MIDI_GetNote(cur_take, i)
		
		if start_note < mouse_ppq_pos and end_note > mouse_ppq_pos and noteRow == pitch then 
			reaper.MIDI_DeleteNote(cur_take, i)
			break
		end
	end

	reaper.Undo_EndBlock("LS Delete note under mouse cursor", -1)
	
	
end

Main()

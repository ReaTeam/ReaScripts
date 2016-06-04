--[[
  * ReaScript Name: Set selected note lengths at least X
  * Description:
  * Instructions: Prompts for the user to type in a note length (i.e. 1 /4 ), and then sets
  *               all selected notes to be at least that long.
  *               For something like a dotted eighth, you would type 1.5/8 and so on.
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

-- Print stuff to the Reaper console, for debugging purposes
function Msg(message)
	
	reaper.ShowConsoleMsg(tostring(message).."\n")
	
end

-- Takes a fraction string and returns the decimal equivalent
function frac2dec(frac)
	
	
	local frac_arr = {string.match(frac, "([^/]+)/([^/]+)")}
	local num, den = frac_arr[1], frac_arr[2]
	
	return num / den
	
end



function Main()
	
	reaper.Undo_BeginBlock()
	
	-- Prompt for note length
	local __, user_len = reaper.GetUserInputs("Note length?", 1, "Set note lengths to at least:", "")
	--user_len = tonumber(user_len)
	
	user_len = frac2dec(user_len)
	
	-- Loop through all notes to see if they're selected or not
	local cur_editor = reaper.MIDIEditor_GetActive()
	local cur_take = reaper.MIDIEditor_GetTake(cur_editor)
	local __, num_notes, __, __ = reaper.MIDI_CountEvts(cur_take)
	local fng_take = reaper.FNG_AllocMidiTake(cur_take)
	for i = 0 , (num_notes - 1) do
		
		local cur_note = reaper.FNG_GetMidiNote(fng_take, i)
		local sel = reaper.FNG_GetMidiNoteIntProperty(cur_note, "SELECTED")
		if sel == 1 then
			
			-- Get a few values measured in PPQ
			local noteppq = reaper.FNG_GetMidiNoteIntProperty(cur_note, "POSITION")
			local lenppq = reaper.FNG_GetMidiNoteIntProperty(cur_note, "LENGTH")
			local startppq = reaper.MIDI_GetPPQPos_StartOfMeasure(cur_take, noteppq)
			local endppq = reaper.MIDI_GetPPQPos_EndOfMeasure(cur_take, noteppq)
			
			-- Convert to beats
			minppq = (endppq - startppq) * user_len
			
			-- Check the length and change it if necessary
			if lenppq < minppq then
				reaper.FNG_SetMidiNoteIntProperty(cur_note, "LENGTH", minppq)
			end

		end
		
	end
	
	reaper.FNG_FreeMidiTake(fng_take)
	
	reaper.Undo_EndBlock("LS Set selected note lengths to at least X", -1)
	
end


Main()
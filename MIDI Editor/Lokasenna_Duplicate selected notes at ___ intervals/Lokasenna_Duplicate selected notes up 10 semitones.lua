--[[
Description: Duplicate selected notes up 10 semitones
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
Extensions: 
--]]

-- Licensed under the GNU GPL v3

local interval = 10
	
local cur_wnd = reaper.MIDIEditor_GetActive()
if not cur_wnd then
	reaper.ShowMessageBox( "This script needs an active MIDI editor.", "No MIDI editor found", 0)
	return 0
end
local cur_take = reaper.MIDIEditor_GetTake(cur_wnd)
	
reaper.Undo_BeginBlock()

-- Get all of the selected notes
local sel_notes = {}

local cur_note = -2
local note_val
while cur_note ~= -1 do

	cur_note = reaper.MIDI_EnumSelNotes(cur_take, cur_note)
	if cur_note == -1 then break end
	cur_arr = {reaper.MIDI_GetNote(cur_take, cur_note)}
	table.remove(cur_arr, 1)
	table.insert(sel_notes, cur_arr)

end

reaper.MIDI_SelectAll(cur_take, false)

-- For each note in the array, add interval and duplicate
for i = 1, #sel_notes do
	sel_notes[i][6] = sel_notes[i][6] + interval
local sel, mute, start, _end, chan, pitch, vel = table.unpack(sel_notes[i])
	reaper.MIDI_InsertNote(cur_take, sel, mute, start, _end, chan, pitch, vel, true)
end

reaper.MIDI_Sort(cur_take)

reaper.Undo_EndBlock("Duplicate selected notes at "..interval.." semitones", -1)

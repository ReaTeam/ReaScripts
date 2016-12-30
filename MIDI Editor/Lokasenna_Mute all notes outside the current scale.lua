--[[
Description: Mute all notes outside the current scale
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Initial release
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
	Compares all MIDI notes in the active take with the current key + scale, muting any that aren't "legal".
--]]

-- Licensed under the GNU GPL v3

-- For debugging
local function Msg(str)
	reaper.ShowConsoleMsg(tostring(str).."\n")
end

-- Parse key/scale into a table of legal notes
local function convert_reascale(scale)
	
	if type(scale) ~= "string" then return nil, 0 end
	--Msg(scale)
	
	-- Size = number of non-zero values in the scale
	local __, size = string.gsub(scale, "[^0]", "")
		
	local scale_arr = {[0] = 0}
	for i = 1, size do

		scale_arr[i] = string.find(scale, "[^0]", scale_arr[i-1] + 1)
		
	end
	
	-- Adjust the values so that root = 0
	for i = 1, #scale_arr do
		scale_arr[i] = scale_arr[i] - 1
	end
	
	return scale_arr, size
	
end



-- Get current key and scale
local cur_wnd = reaper.MIDIEditor_GetActive()
if not cur_wnd then
	reaper.ShowMessageBox( "This script needs an active MIDI editor.", "No MIDI editor found", 0)
	return 0
end

-- Is snapping enabled?
local snap = reaper.MIDIEditor_GetSetting_int(cur_wnd, "scale_enabled")
if snap == 0 then
	reaper.ShowMessageBox( "Key snapping must be enabled for this script to do anything.", "No scale found", 0)
	return 0
end

local cur_take = reaper.MIDIEditor_GetTake(cur_wnd)
local __, key, __, __ = reaper.MIDI_GetScale(cur_take, 0, 0, "")
local __, scale_str = reaper.MIDIEditor_GetSetting_str(cur_wnd, "scale", "")
local scale_arr, scale_size = convert_reascale(scale_str)

for i = 1, #scale_arr do
	scale_arr[i] = (scale_arr[i] + key) % 12
end

--Msg("key = "..key.."  scale = "..table.concat(scale_arr, " "))


reaper.MIDI_SelectAll(cur_take, 1)		
		
-- Get all selected notes
local sel_notes = {}
local function get_sel_notes()
	
	local cur_note = -2
	local note_val
	while cur_note ~= -1 do
		
		cur_note = reaper.MIDI_EnumSelNotes(cur_take, cur_note)
		__, __, __, __, __, __, note_val, __ = reaper.MIDI_GetNote(cur_take, cur_note)
		if cur_note == -1 then break end
		table.insert(sel_notes, {["idx"] = cur_note, ["num"] = note_val})
		--Msg("inserted "..note_val.." at pos "..#sel_notes)
		
	end
	
end
get_sel_notes()

reaper.Undo_BeginBlock()

-- For each selected note, see if note % 12 is legal
local function are_notes_legal()
	
	-- run backwards so deleting notes doesn't fuck things up?
	for i = #sel_notes, 1, -1 do
		
		local legal = false
		--Msg("comparing "..sel_notes[i].num.." as "..(sel_notes[i].num + 12) % 12)
		for j = 1, #scale_arr do

			if (sel_notes[i].num + 12) % 12 == scale_arr[j] then 
				legal = true 
				break
			end
		end
		-- reaper.MIDI_SetNote( take, noteidx, selectedInOptional, mutedInOptional, startppqposInOptional, endppqposInOptional, chanInOptional, pitchInOptional, velInOptional, noSortInOptional )		
		--Msg("note #"..sel_notes[i].num.." | legal = "..tostring(legal))
		if not legal then reaper.MIDI_SetNote(cur_take, sel_notes[i].idx, nil, true, nil, nil, nil, nil, nil, true) end

	end
	
	reaper.MIDI_Sort(cur_take)
	
end
are_notes_legal()

reaper.MIDI_SelectAll(cur_take, 0)	
reaper.Undo_EndBlock("Mute all notes outside the current scale", -1)
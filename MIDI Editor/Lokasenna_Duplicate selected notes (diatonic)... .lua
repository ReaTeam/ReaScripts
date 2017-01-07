--[[
Description: Duplicate selected notes (diatonic)...
Version: 1.3.1
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Bug fix; it was always using C as the scale's root
Links:
Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Duplicates the selected notes up or down a specified interval, diatonically
Extensions: 
--]]

-- Licensed under the GNU GPL v3

--!!REQUIRES START
--!!REQUIRE "Lokasenna_GUI library beta 6.lua"

-- Grab all of the functions and classes from our GUI library
local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
GUI = loadfile(script_path .. "Lokasenna_GUI Library beta 6.lua")

if not GUI then
	reaper.ShowMessageBox( "Library not found", "Library not found", 0)
	return 0
end

GUI()

--!!REQUIRES END

GUI.name = "Duplicate selected notes (diatonic)..."
GUI.x, GUI.y, GUI.w, GUI.h = -48, 0, 250, 56
GUI.anchor, GUI.corner = "mouse", "C"


local deg = 1

local interval_arr = {
	{"up an eleventh", 11},
	{"up a tenth", 10},
	{"up a ninth", 9},
	{"up an eighth", 8},
	{"up a seventh", 7},
	{"up a sixth", 6},
	{"up a fifth", 5},
	{"up a fourth", 4},
	{"up a third", 3},
	{"up a second", 2},
	{" ", 0},
	{"down a second", -2},
	{"down a third", -3},
	{"down a fourth", -4},
	{"down a fifth", -5},
	{"down a sixth", -6},
	{"down a seventh", -7},
	{"down an eighth", -8},
	{"down a ninth", -9},
	{"down a tenth", -10},
	{"down an eleventh", -11},
}

local interval_str = interval_arr[1][1]
for i = 2, #interval_arr do
	interval_str = interval_str..","..interval_arr[i][1]
end

local root_arr = {[0] = "C","C#/Db","D","D#/Eb","E","F","F#/Gb","G","G#/Ab","A","A#/Bb","B"}

local scale_arr = {}
local chrom_notes = {}

local size, deg, key = 0, 0, 0

local cur_wnd, cur_take

-- Are we in "waiting for the user to press Go" mode, or
-- "working through the list of nondiatonic notes" mode?
local chrom_mode = false
local last_num_chroms = 0

local up_arrow = "[↑]"
local dn_arrow = "[↓]"

-- For storing the original position while we jump around
local cursor_pos

	
local function harmonize_note(MIDI_note)	
	
	-- Subtract "key" so the rest of the math can just work with a scale root of 0
	local pitch_class = (MIDI_note + 12 - key) % 12
	local deg_o
	
	for j = 1, size do
		if pitch_class == scale_arr[j] then
			deg_o = j
			break
		end
	end

	
	if deg_o then
	
		local deg_new = deg_o + deg
		local oct_adj = deg > 0 and (math.modf((deg_new - 1) / size)) or (math.modf(deg_new / size))
		if deg_new < 1 then
			oct_adj = oct_adj - 1
		end
		
		-- Convert the degree to a value within the scale
		deg_new =  (deg_new - 1) % size + 1
		
		local note_adj = scale_arr[deg_new] - scale_arr[deg_o] + 12 * oct_adj
		
		return MIDI_note + note_adj
	
	else return -1
	
	end
	
	
end


local function chrom_toggle(chrom)
	
	GUI.elms_hide[5] = chrom
	GUI.elms_hide[3] = not chrom
	
	chrom_mode = chrom
	
end


local function dup_notes()
	
	cur_wnd = reaper.MIDIEditor_GetActive()
	if not cur_wnd then
		reaper.ShowMessageBox( "This script needs an active MIDI editor.", "No MIDI editor found", 0)
		return 0
	end
	cur_take = reaper.MIDIEditor_GetTake(cur_wnd)
	local val = interval_arr[GUI.Val("mnu_intervals")][2]
	
	cursor_pos = reaper.GetCursorPosition()
	
	__, key, __, __ = reaper.MIDI_GetScale(cur_take, 0, 0, "")
	local __, scale_str = reaper.MIDIEditor_GetSetting_str(cur_wnd, "scale", "")
	__, size = string.gsub(scale_str, "[^0]", "")
		
	-- Parse the menu text to get a scale degree
	deg = math.floor(tonumber(val) or 0) or nil

	if not deg or deg == -1 or deg == 1 then
		return 0
	else

		reaper.Undo_BeginBlock()
		
		chrom_notes = {}

		-- Parse the scale string into something useful
		-- Size = number of non-zero values in the scale
		local __, scale_str = reaper.MIDIEditor_GetSetting_str(cur_wnd, "scale", "")

		__, size = string.gsub(scale_str, "[^0]", "")
			
		scale_arr = {[0] = 0}
		for i = 1, size do
			scale_arr[i] = string.find(scale_str, "[^0]", scale_arr[i-1] + 1)
		end
		
		-- Adjust the values so that root = 0
		for i = 1, size do
			scale_arr[i] = scale_arr[i] - 1
		end

		-- Intervals are written one more than the actual gap
		-- i.e. a fifth is four scale degrees up
		deg = deg > 0 and deg - 1 or deg + 1
		
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
		
		
		-- For each note in the array, calculate a pitch offset and duplicate it
		for i = 1, #sel_notes do
			
			-- Offsetting for the Key
			local new_note = harmonize_note(sel_notes[i][6])
			
			if new_note ~= -1 then
				sel_notes[i][6] = new_note
							
				local sel, mute, start, _end, chan, pitch, vel = table.unpack(sel_notes[i])
				reaper.MIDI_InsertNote(cur_take, sel, mute, start, _end, chan, pitch, vel, true)
			
			else
				table.insert(chrom_notes, sel_notes[i])
			end
		end
		
		reaper.MIDI_Sort(cur_take)
		
		reaper.Undo_EndBlock("Duplicate selected notes "..interval_arr[GUI.Val("mnu_intervals")][1].." diatonically", -1)
		
	end	
end	


local function get_harm_opts(cur_note)
	
	-- Subtract "key" so the math can be based on a root of 0
	cur_note = (cur_note + 12 - key) % 12

	local note_up, note_dn
	for i = 1, #scale_arr do
		
		if scale_arr[i] > cur_note then
			note_dn = scale_arr[i-1]
			note_up = scale_arr[i]
			
			break
		end
	end
	
	if not note_dn then note_dn = scale_arr[#scale_arr] end
	if not note_up then note_up = 12 end
	
	local adj_up = note_up - cur_note
	local adj_dn = note_dn - cur_note
		
	return adj_dn, adj_up		
	
end


local function chrom_harm(new_note)
	
	if new_note ~= -1 then
		
		chrom_notes[1][6] = new_note
		
		local sel, mute, start, _end, chan, pitch, vel = table.unpack(chrom_notes[1])
		reaper.MIDI_InsertNote(cur_take, sel, mute, start, _end, chan, pitch, vel, true)
		
		table.remove(chrom_notes, 1)		

	end

end

local function chrom_skip()
	if #chrom_notes > 0 then table.remove(chrom_notes, 1) end
end

local function goto_chrom()
	

	
end



GUI.elms = {
	lbl_duplicate = GUI.Label:new(		5,	8, 4, "Duplicate selected notes", 0, 4),
	mnu_intervals = GUI.Menubox:new(	5,	60, 4, 140, 18, "", interval_str, 4), 
	btn_go = GUI.Button:new(			5,	4, 28, 80, 20, "Go", dup_notes),
	lbl_semitones = GUI.Label:new(		5,	4, 4, "diatonically.", 1, 4),
	
	lbl_num_chrom = GUI.Label:new(		3,	8, 4, "", 1, 4),
	btn_harm_dn = GUI.Button:new(		3,	0, 28, 80, 20, "↓", chrom_harm, -1),	
	btn_harm_up = GUI.Button:new(		3,	0, 28, 80, 20, "↑", chrom_harm, 1),
	btn_skip = GUI.Button:new(			3,  0, 28, 80, 20, "[S]kip", chrom_skip),	

}

GUI.elms_hide = {[3] = true}

GUI.Val("mnu_intervals", 11)




local function Main()
	
	if #chrom_notes > 0 and not chrom_mode then chrom_toggle(true) end
	
	if chrom_mode then
		
		if #chrom_notes == 0 then 
			chrom_toggle(false) 
			
			-- Jump back to where the user was originally
			reaper.SetEditCurPos2(0, cursor_pos, true, true)
			
			return 0
		end
		
		local cur_num_chroms = #chrom_notes
		
		if cur_num_chroms == 0 then
			return 0
		elseif cur_num_chroms ~= last_num_chroms then
			last_num_chroms = cur_num_chroms
			
			local cur_note = chrom_notes[1][6]

			-- Get the two harmony choices as MIDI note numbers
			local adj_dn, adj_up = get_harm_opts(cur_note)
			local note_dn, note_up = harmonize_note(cur_note + adj_dn), harmonize_note(cur_note + adj_up)

			-- The two buttons will now pass their MIDI note to the insert function
			GUI.elms.btn_harm_up.params = {note_up}
			GUI.elms.btn_harm_dn.params = {note_dn}

			GUI.elms.btn_harm_up.caption = up_arrow..root_arr[(note_up + 12) % 12]
			GUI.elms.btn_harm_dn.caption = dn_arrow..root_arr[(note_dn + 12) % 12]
			
			-- Update time stamp label for the current note
			local start_ppq = chrom_notes[1][3]
			
			local time_str = reaper.MIDI_GetProjTimeFromPPQPos(cur_take, start_ppq)
			local beats_str, bars_str = reaper.TimeMap2_timeToBeats(0, time_str)
			
			
			local h = math.modf(time_str / 3600)
			local m = math.modf((time_str - h * 3600) / 60)
			local s = time_str - h * 3600 - m * 60
			
			time_str = string.format("%d:%02d:%2.3f", h, m, s)

			local bars_str = bars_str + 1
			local beats_str = math.floor(beats_str * 100) / 100 + 1
			
			local name_cur = root_arr[(cur_note + 12) % 12]
			
			local name_str = "Harmonize "..name_cur.." at beat "..bars_str.."."..beats_str.." / "..time_str.."s as:"
			GUI.Val("lbl_num_chrom", name_str)
			
			-- Jump to the current note so we can see the context
			local time = reaper.MIDI_GetProjTimeFromPPQPos(cur_take, chrom_notes[1][3] )
			reaper.SetEditCurPos2(0, time, true, true)

		end
		
		-- See if the user pressed one of our hotkeys
		local char = GUI.char
		if 		char == GUI.chars.UP 	then GUI.elms.btn_harm_up:exec()
		elseif	char == GUI.chars.DOWN 	then GUI.elms.btn_harm_dn:exec()
		elseif	char == string.byte("s") then GUI.elms.btn_skip:exec()
		elseif	char == string.byte("g") then GUI.elms.btn_goto:exec()
		end
		
		
	end	
end


GUI.version = nil
GUI.Init()

GUI.font(4)
local str_w_a, __ = gfx.measurestr(GUI.Val("lbl_duplicate"))
local str_w_b, __ = gfx.measurestr(GUI.Val("lbl_semitones"))
local __, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)

GUI.elms.mnu_intervals.x = 8 + str_w_a + 4
GUI.elms.lbl_semitones.x = GUI.elms.mnu_intervals.x + GUI.elms.mnu_intervals.w + 4
local new_w = GUI.elms.lbl_semitones.x + str_w_b + 4

GUI.elms.btn_go.x = (new_w - GUI.elms.btn_go.w) / 2
GUI.elms.btn_harm_up.x = GUI.elms.btn_go.x
GUI.elms.btn_skip.x = GUI.elms.btn_harm_up.x + GUI.elms.btn_harm_up.w + 4
GUI.elms.btn_harm_dn.x = GUI.elms.btn_harm_up.x - GUI.elms.btn_harm_dn.w - 4


gfx.quit()
gfx.init(GUI.name, new_w, h, 0, x, y)
GUI.cur_w = new_w

GUI.func = Main
GUI.freq = 0

GUI.Main()

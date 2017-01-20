--[[
Description: Fill selected MIDI item with notes...
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Forum Thread _________________________
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Allows you to quickly add a large quantity of notes to a MIDI item.
	Could be used, for example, to add a steady hi-hat pattern.
Extensions:
--]]

-- Licensed under the GNU GPL v3

--!!REQUIRES START
--!!REQUIRE "Lokasenna_GUI library beta 7.lua"

-- Grab all of the functions and classes from our GUI library
local info = debug.getinfo(1,'S');
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
GUI = loadfile(script_path .. "Libraries\\Lokasenna_GUI Library beta 7.lua")

if not GUI then
	reaper.ShowMessageBox( "Library not found", "Library not found", 0)
	return 0
end

GUI()

--!!REQUIRES END

GUI.name = "Fill MIDI item with..."
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 256, 148
GUI.anchor, GUI.corner = "mouse", "C"


local len_arr = {
	"1",
	"1/2",
	"1/4",
	"1/8",
	"1/16",
	"1/32",
	"1/64",
}
local len_str = table.concat(len_arr, ",")

local beat_arr = {
	"4",
	"3",
	"2",
	"1",
	"1/2",
	"1/4",
	"1/8",
	"1/16",
	"1/32",
	"1/64",	
}
local beat_str = table.concat(beat_arr, ",")

local function fill_item()
	
	-- Get the current take
	local cur_item = reaper.GetSelectedMediaItem(0, 0)
	if not cur_item then
		reaper.ShowMessageBox( "Select a MIDI item first.", "No item", 0)
		return 0
	end

	local cur_take = reaper.GetActiveTake(cur_item) 
	
	-- Get the take's start and end PPQ
	local start_time = reaper.GetMediaItemInfo_Value(cur_item, "D_POSITION")
	--GUI.Msg("start time = "..tostring(start_time))
	local end_time = start_time + reaper.GetMediaItemInfo_Value(cur_item, "D_LENGTH")
	--GUI.Msg("end time = "..tostring(end_time))
	
	--local start_ppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, start_time)
	local start_ppq = 0
	--GUI.Msg("start ppq = "..tostring(start_ppq))
	local end_ppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, end_time)
	
	-- Figure out the length of a note in PPQ
	
--[[
	local end_ppq = reaper.MIDI_GetPPQPosFromProjQN(cur_take, cursor_QN + len_QN)
	
	local len_ppq = end_ppq - cursor_ppq	
]]--
	
	local len = load("return "..len_arr[GUI.Val("mnu_length")])
	len = len()
	
	local len_QN = len * 4 -- <- convert to QN
	local start_QN = reaper.TimeMap_timeToQN(start_time)
	local len_time = reaper.TimeMap_QNToTime(start_QN + len_QN)
	local len_ppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, len_time) - start_ppq
	
	-- Figure out the adjustment in PPQ
	local adj_QN = load("return "..beat_arr[GUI.Val("mnu_offset")])() * 4 -- <-- convert to QN
	local adj_time = reaper.TimeMap_QNToTime(start_QN + adj_QN)
	local adj_ppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, adj_time) - start_ppq
	
	
	local note_num = tonumber(GUI.Val("txt_note"))
	
	local cur_ppq = start_ppq
	while cur_ppq < end_ppq do
		-- reaper.MIDI_InsertNote( take, selected, muted, startppqpos, endppqpos, chan, pitch, vel, noSortInOptional )
		reaper.MIDI_InsertNote(cur_take, false, false, cur_ppq, cur_ppq + len_ppq, 0, note_num, 127, true)	
		cur_ppq = cur_ppq + adj_ppq
	end
	
	reaper.MIDI_Sort(cur_take)
	-- cur_ppq = item start ppq
	-- while cur_ppq < item end ppq do
		-- insert note #__ @ cur_ppq
		-- reaper.ApplyNudge( project, nudgeflag, nudgewhat, nudgeunits, value, reverse, copies )
			
	
end

GUI.elms = {
	
	mnu_length = GUI.Menubox:new(	1,	152, 16, 64, 20, "Note length:", len_str, 8),
	mnu_offset = GUI.Menubox:new(	1,	152, 42, 64, 20, "Every __ bars:", beat_str, 8),
	txt_note = GUI.Textbox:new(		1,	152, 68, 64, 20, "Note number:", 8),
	
	btn_go = GUI.Button:new(		1,	96, 98, 64, 20, "Go!", fill_item),
	
}
GUI.Val("mnu_length", 4)
GUI.Val("mnu_offset", 6)
GUI.Val("txt_note", 35)


GUI.Init()
GUI.Main()
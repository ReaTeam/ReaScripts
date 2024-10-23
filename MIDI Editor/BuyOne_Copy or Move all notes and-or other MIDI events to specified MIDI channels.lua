--[[
ReaScript name: Copy or Move all notes and/or other MIDI events to specified MIDI channels
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Added warning when MIDI channel filter is not enabled
Licence: WTFPL
REAPER: at least v5.962
About: 	The script copies/moves all notes and/or CC events to user specified MIDI channels.  
	If in the target MIDI channel there're already events for a particular CC message  
	or the piano roll already contains notes, these will be replaced by those being 
	copied or moved.  

	1. Run the script  
	2. In the 1st input field list target MIDI channel numbers space separated 
	or specify range as X - X (inverted range is supported, e.g. 13 - 4)  
	3. In the 2nd and/or 3d input fields enter letter M or m if you wish the events 
	to be moved or any other character if you want them copied  
	4. Click OK  

	Besides strictly CC events also supported are Pitch bend, Program change 
	and Channel pressure events.

	CAVEATS

	To be aware that Bezier curve in Pitch bend envelope may very slightly change
	in the target MIDI channel after copying/moving. However this is not a consistent 
	behavior. https://forum.cockos.com/showthread.php?t=273173

]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function validate_output(string)
local string = string:gsub(' ','')
return #string > 0 and string ~= ',,'
end


function validate(string)
return #string:gsub(' ','') > 0
end


function get_index_from_range_or_list(str, num) -- str is a string containing range 'X-X' or list 'X X X X' of numerals, the type of separator doesn't matter
local min, max = str:match('(%d+)%s*%-%s*(%d+)') -- the syntax is X-X // range
	if (min and max)
	and (num >= min+0 and max+0 >= num or num >= max+0 and min+0 >= num) -- range // +0 converts string to number to match num data type // allows reversed ranges, e.g. 10 - 1
	then return true
	elseif str:match('%f[%d]'..num..'%f[%D]') then return true -- list
--[[ OR
	elseif str:match(num) then -- list
		for w in str:gmatch('%d+') do -- without the loop parts of composite numbers will produce truth as well in str:match(num), i.e. 16 will be true 3 times as 1, 6 and 16 // the loop allows respecting separators
			if tonumber(w) == num then return true end
		end
	]]
	end
end


function Store_Insert_Notes_OR_Evts(ME, take, t, move, chanIn, events) -- move is boolean, chanIn is channel for note/event setting, events is boolean to handle envelope events rather than notes
local ME = not ME and r.MIDIEditor_GetActive() or ME
local take = not take and r.MIDIEditor_GetTake(ME) or take
local Get, Delete, Insert = table.unpack(not events and {r.MIDI_GetNote, r.MIDI_DeleteNote, r.MIDI_InsertNote} or {r.MIDI_GetCC, r.MIDI_DeleteCC, r.MIDI_InsertCC})
-- !!!! Get, Delete, Insert, GeCCShape functions only target event in the current MIDI channel if Channel filter is enabled !!!!!
-- local chanIn = not chanIn and r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') or chanIn -- 0-15
	if not t then
	local t = {}
	local idx = 0
		repeat
		local retval, shape, beztension = table.unpack(events and {r.MIDI_GetCCShape(take, idx)} or {})
		t[#t+1] = {Get(take, idx)} --{table.unpack(data, 1, 8), shape, beztension}
		table.insert(t[#t], shape); table.insert(t[#t], beztension)
		local retval = t[#t][1]
			if idx == 0 and not retval then t = {} break end -- if no notes/events at all, resetting the table which would otherwise contain 1 field and produce false positive
		idx = idx+1
		until not retval
		if move then -- delete from the source channel
		r.MIDI_DisableSort(take)
			for i = #t,1,-1 do
			Delete(take, i-1)
			end
		r.MIDI_Sort(take)
		end
	return t
	else -- insert
	-- Count content in the current channel to use in reversed loop below for the sake of deletion
	local count = 0
		repeat
		local retval, sel, muted, ppqpos, endppq, chan, pitch, vel = Get(take, count) -- here only retval matters
			if not retval then break end
		count = count+1
		until not retval
	-- Delete content from the target channel
	r.MIDI_DisableSort(take)
	local idx = count-1 -- in reverse due to deletion, -1 because the count ends up being 1-based
		repeat
		Delete(take, idx)
		idx = idx-1
		until idx < 0
	r.MIDI_Sort(take)
		-- Insert notes or events in the target channel
		for k, data in ipairs(t) do
		local retval, sel, muted, ppqpos, a, chan, b, c, shape, beztension = table.unpack(data, 1, 10) -- for note it's retval, sel, muted, startppqpos, endppqpos, chan, pitch, vel; for CC events it's retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3, shape, beztension
			if retval then -- the last retval will be nil since one invalid event is stored at the end of the store loop
			Insert(take, sel, muted, ppqpos, a, chanIn, b, c, true) -- chanIn comes from the function argument, noSortIn true
				if events then
				r.MIDI_SetCCShape(take, k-1, shape, beztension, true) -- noSortIn true
				end
			end
		end
	r.MIDI_Sort(take)
	end

end


function ACT(comm_ID)
r.MIDIEditor_LastFocused_OnCommand(r.NamedCommandLookup(comm_ID), false) -- islistviewcommand false
end


local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)


local filter_on
	for i = 40218, 40233 do -- ID range of actions 'Channel: Show only channel X' which select a channel in the filter and enable the filter
		if r.GetToggleCommandStateEx(32060, i) == 1 then filter_on = 1 break end
	end
	if not filter_on then
	local s = ' '
	local resp = r.MB(s:rep(8)..'It appears that the MIDI channel filter is not enabled.\n\n\t'..s:rep(5)..'This means that if there\'re events\n\n\t'..s:rep(12)..'in multiple MIDI channels\n\n'..s:rep(6)..'they all will be copied/moved to the target channels.\n\n\t'..s:rep(12)..'Do you wish to proceed?', 'WARNING', 4)
		if resp == 7 then return r.defer(function() do return end end) end
	end


local notes_t = Store_Insert_Notes_OR_Evts(ME, take, t, move, chanIn, events) -- events false // store
local evts_t = Store_Insert_Notes_OR_Evts(ME, take, t, move, chanIn, true) -- events true // store

	if #notes_t + #evts_t == 0 then
	r.MB('In the current channel there\'re no MIDI events\n\n\t  compatible with the script.', 'ERROR', 0)
	return r.defer(function() do return end end) end



::RETRY::

local retval, output = r.GetUserInputs('USER INPUT (Tab - next field, Shift+Tab - previous)', 3, 'MIDI channels: 2 - 5 or 2 3 4 5,Notes M/m - move; any - copy,Events: M/m - move; any - copy, extrawidth=150', autofill or '') -- in practice any non-numeric char can serve as a separator
	if not retval or not validate_output(output) then return r.defer(function() do return end end) end

local channels, notes, events = output:match('([%d%s%-]+),(.*),(.*)')

local ch_t = {}

	if channels then
		for i = 1, 16 do -- 16 MIDI channels
			if get_index_from_range_or_list(channels, i) then
			ch_t[#ch_t+1] = i
			end
		end
	end


local cur_chan = r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') -- 0-15

local err = not channels and 'No target MIDI channels have been specified.'
or #ch_t == 0 and 'No valid target MIDI channel has been specified.' -- when channels is no nil
or #ch_t == 1 and ch_t[1]-1 == cur_chan and 'The target MIDI channel is the same as the current one.' -- -1 to conform to 0-based system used in cur_chan value
or not validate(notes) and not validate(events) and 'No content has been marked for processing.'
or validate(notes) and not validate(events) and #notes_t == 0 and 'No notes in the current channel.'
or validate(events) and not validate(notes) and #evts_t == 0 and 'No MIDI events in the current channel.'

	if err then
	local resp = r.MB(err, 'ERROR', 5)
		if resp == 4 then autofill = move and move..output or output goto RETRY
		else return r.defer(function() do return end end)
		end
	end


local notes_move = notes:match('%f[%a][Mm]+%f[%A]')
local notes = validate(notes)-- and not notes_move

local events_move = events:match('%f[%a][Mm]+%f[%A]')
local events = validate(events)-- and not events_move


local cur_ch_comm_ID = 40218 + cur_chan -- 40218 is 'Channel: Show only channel 01' // construct initial channel action command ID

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local del = notes_move and Store_Insert_Notes_OR_Evts(ME, take, t, notes_move, chanIn, false) -- t, chanIn, events are false // delete notes from the source channel
local del = events_move and Store_Insert_Notes_OR_Evts(ME, take, t, events_move, chanIn, true) -- t, chanIn are false, events true // delete events from the source channel


	for _, ch in ipairs(ch_t) do
		if ch-1 ~= cur_chan then -- ignoring current MIDI channel; ch-1 to conform to 0-based system used in cur_chan value
		local comm_ID = cur_ch_comm_ID + (ch-1 - cur_chan)
		ACT(comm_ID) -- 'Channel: Show only channel N'
			if #notes_t > 0 and notes then Store_Insert_Notes_OR_Evts(ME, take, notes_t, notes_move, ch-1, false) end -- events false // insert
			if #evts_t > 0 and events then Store_Insert_Notes_OR_Evts(ME, take, evts_t, events_move, ch-1, true) end -- events true // insert
		end
	end


r.PreventUIRefresh(-1)

local undo1 = #notes_t > 0 and #evts_t > 0 and notes and events and (notes_move and events_move and 'Move' or not notes_move and not events_move and 'Copy')
local undo1 = undo1 and undo1..' all notes and MIDI events ' or ''
local undo2 = #undo1 == 0 and #notes_t > 0 and notes and (notes_move and 'Move' or 'Copy')..' all notes ' or ''
local undo3 = #undo1 == 0 and #evts_t > 0 and events and (events_move and 'Move' or 'Copy')..' all events ' or ''


-- a trick shared by juliansader to force MIDI API to register undo point; Undo_OnStateChange() works too but with native actions it may create extra undo points
-- https://forum.cockos.com/showpost.php?p=1925555
local item = r.GetMediaItemTake_Item(take)
local is_item_sel = r.IsMediaItemSelected(item)
r.SetMediaItemSelected(item, not is_item_sel) -- unset
r.SetMediaItemSelected(item, is_item_sel) -- restore

r.Undo_EndBlock(undo1..undo2..undo3..'to specified MIDI channels', -1)




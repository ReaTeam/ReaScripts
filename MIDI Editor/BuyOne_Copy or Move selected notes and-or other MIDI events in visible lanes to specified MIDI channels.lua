--[[
ReaScript name: Copy or Move selected notes and/or other MIDI events in visible lanes to specified MIDI channels
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Added a verification mechanism to ensure that only one MIDI channel is selected
Licence: WTFPL
REAPER: at least v5.962
About: 	The script copies/moves selected notes and/or selected CC events in visible lanes
	to user specified MIDI channels. If the target lane in another MIDI channel already
	contains events or piano roll already contains notes, these will be replaced by those 
	being copied or moved.  

	If several CC lanes are open, selected events in 14 bit CC lanes will be ignored, 
	therefore if you need them affected by the sctipt be sure to switch 14 bit
	lanes to their 7 bit counterparts.  

	1. Select MIDI notes and/or other MIDI events  
	2. Run the script  
	3. In the input field list target MIDI channel numbers space separated or specify range as X - X
	(inverted range is supported, e.g. 13 - 4)  
	4. Precede the list/range with the letter M or m if you wish the events to be moved rather than copied  
	5. Click OK  

	If there're several visible lanes and only one of them contains selected events 
	be sure to make it the last clicked by clicking it so that the events are  
	copied/moved to the lane of the same message type in other MIDI channels.

	Besides strictly CC events also supported are Pitch bend, Program change 
	and Channel pressure events.
]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function ACT(comm_ID)
r.MIDIEditor_LastFocused_OnCommand(r.NamedCommandLookup(comm_ID), false) -- islistviewcommand false
end

function validate(string)
return #string:gsub(' ','') > 0
end

function Re_Store_Selected_CCEvents(ME, take, t, deselect_before_restore) -- deselect_before_restore is boolean
-- !!!! will work EVEN IF events were deleted or added in the interim FOR ALL MIDI CHANNELS
-- clicking within one MIDI channel doesn't affect event selection in other MIDI channels
-- deleting selected events in one MIDI channel with action doesn't affect selected events in other MIDI channels; in the same MIDI channels selected events are deleted regardless of their lane visibility
-- with the mouse CC events can only be selected in one lane, the selection is exclusive just like track automation envelope nodes unless Shift is held down, marque selection or Ctrl+A are used
local ME = not ME and r.MIDIEditor_GetActive() or ME
local take = not take and r.MIDIEditor_GetTake(ME) or take
local cur_chan = r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') -- 0-15
local cur_ch_comm_ID = 40218 + cur_chan -- 40218 is 'Channel: Show only channel 01' // will be used to restore current channel after traversing all

	if not t then
	r.PreventUIRefresh(1)
	local t = {}
		for ch = 0, 15 do
		local comm_ID = 40218 + ch -- construct command ID for the next action 'Channel: Show only channel N'; starting from 1
		r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false // select MIDI channel
		local evt_idx = 0
			repeat
			local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx)
				if sel then
				t[#t+1] = {retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3, evt_idx} -- store and deselect
				r.MIDI_SetCC(take, evt_idx, false, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn false, noSortIn true // deselect
				end
			evt_idx = evt_idx+1
			until not retval
		r.MIDI_Sort(take)
		end
	--	r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation
	r.MIDIEditor_LastFocused_OnCommand(cur_ch_comm_ID, false) -- islistviewcommand false // restore original channel
	r.PreventUIRefresh(-1)
	return t
	else
	r.PreventUIRefresh(1)
--	r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation
		if deselect_before_restore then
			for ch = 0, 15 do
			local comm_ID = 40218 + ch -- construct command ID for the next action 'Channel: Show only channel N'; starting from 1
			r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false // select MIDI channel
			local evt_idx = 0
				repeat -- deselect all
				local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- just to use retval to stop the loop // probably MIDI_SetCC() boolean return value could be used instead
				r.MIDI_SetCC(take, evt_idx, false, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn false, noSortIn true // deselect
				evt_idx = evt_idx+1
				until not retval
			r.MIDI_Sort(take)
			end
		end
		for ch = 0, 15 do
		local comm_ID = 40218 + ch -- construct command ID for the next action 'Channel: Show only channel N'; starting from 1
		r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false // select MIDI channel
		local evt_idx = 0
			repeat
			local evt_data = {r.MIDI_GetCC(take, evt_idx)}
			local restore
				for _, evt_data_stored in ipairs(t) do
				local match = 0
					for i = 3, 8 do -- extract and compare values one by one; only 6 values are relevant, 3 - 8, i.e. muted, ppqpos, chanmsg, chan, msg2, msg3
					local val1 = table.unpack(evt_data, i, i) -- the 3d argument isn't really necessary since even when multiple values are returned starting from index up to the end, only the first one is stored
					local val2 = table.unpack(evt_data_stored, i, i)
						if val1 == val2 then match = match+1 end
					end
					if match == 6 then restore = 1 break end -- 6 return values match
				end
				if restore then -- restore
				local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = table.unpack(evt_data) -- if only selection and event count changed these values aren't needed
				r.MIDI_SetCC(take, evt_idx, true, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn, noSortIn true
				end
			evt_idx = evt_idx+1
			until not evt_data[1] -- retval
		r.MIDI_Sort(take)
		end
	r.MIDIEditor_LastFocused_OnCommand(cur_ch_comm_ID, false) -- islistviewcommand false // restore original channel
	r.PreventUIRefresh(-1)
	end

end


function Get_Currently_Visible_CC_Lanes(ME, take) -- must be preceded and followed by Re_Store_Selected_CCEvents() because it changes selection
-- lanes of 14-bit CC messages aren't supported because the action 40802 'Edit: Select all CC events in time selection (in all visible CC lanes)' doesn't select their events, it only does if their 7-bit lane is open
local ME = not ME and r.MIDIEditor_GetActive() or ME
local take = not take and r.MIDIEditor_GetTake(ME) or take
local item = r.GetMediaItemTake_Item(take)
local pos = r.GetMediaItemInfo_Value(item, 'D_POSITION')
local fin = pos + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
local time_st, time_end = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, allowautoseek false // store
r.GetSet_LoopTimeRange(true, false, pos, fin, false) -- isSet true, isLoop, allowautoseek false // create time sel
r.PreventUIRefresh(1)
--r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation

-- DESELECTION OF ALL IS HANDLED BY Re_Store_Selected_CCEvents() instead of the above action

r.MIDIEditor_LastFocused_OnCommand(40802, false) -- islistviewcommand false // Edit: Select all CC events in time selection (in all visible CC lanes) -- DOESN'T AFFECT non-CC events BUT IGNORES visible 14 bit lanes // EXCLUSIVE, i.e. deselects all other CC events
-- https://forum.cockos.com/showthread.php?t=272887
local i = -1 -- start with -1 since MIDI_EnumSelCC returns idx of the next event hence will actually start from 0
local t = {}
	repeat
	local idx = r.MIDI_EnumSelCC(take, i)
		if idx > -1 then
		local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, idx) -- point indices are based on their time position hence points with sequential indices will likely belong to different CC envelopes
		local stored
			for _, cc in ipairs(t) do
				if cc == msg2 or cc == chanmsg then stored = 1 break end
			end
			if not stored then t[#t+1] = chanmsg == 176 and msg2 or chanmsg end -- only collect unique numbers of CC messages (chanmsg = 176) for which msg2 value represents CC#, or non-CC messages which have channel data (chanmsg is not 176) for which msg2 value doesn't represent CC#; chanmsg = Pitch bend - 224, Program - 192, Channel pressure - 208, Poly aftertouch - 160
		end
	i = i+1
	until idx == -1
--[[ ALSO WORKS
local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
	for i = 0, ccevtcnt-1 do
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, i) -- point indices are based on their time position hence points with sequential indices will likely belong to different CC envelopes
		for _, cc in ipairs(t) do
			if cc == msg2 or cc == chanmsg then stored = 1 break end
		end
		if not stored then t[#t+1] = chanmsg == 176 and msg2 or chanmsg end -- only collect unique numbers of CC messages (chanmsg = 176) for which msg2 value represents CC#, or non-CC messages which have channel data (chanmsg is not 176) for which msg2 value doesn't represent CC#; chanmsg = Pitch bend - 224, Program - 192, Channel pressure - 208, Poly aftertouch - 160
		end
	end
--]]

--r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation

-- DESELECTION OF ALL IS HANDLED BY Re_Store_Selected_CCEvents() instead of the above action

r.GetSet_LoopTimeRange(true, false, time_st, time_end, false) -- isSet true, isLoop, allowautoseek false // restore
r.PreventUIRefresh(-1)
table.sort(t)
return t

end


function get_index_from_range_or_list(output, num) -- output is a string containing range 'X-X' or list 'X X X X' of numerals, the type of separator doesn't matter
local min, max = output:match('(%d+)%s*%-%s*(%d+)') -- the syntax is X-X // range
	if (min and max)
	and (num >= min+0 and max+0 >= num or num >= max+0 and min+0 >= num) -- range // +0 converts string to number to match num data type // allows reversed ranges, e.g. 10 - 1
	then return true
	elseif output:match('%f[%d]'..num..'%f[%D]') then return true -- list
--[[ OR
	elseif output:match(num) then -- list
		for w in output:gmatch('%d+') do -- without the loop parts of composite numbers will produce truth as well in output:match(num), i.e. 16 will be true 3 times as 1, 6 and 16 // the loop allows respecting separators
			if tonumber(w) == num then return true end
		end
	]]
	end
end

-- https://forums.cockos.com/showthread.php?p=2377732
-- text/notation events and SysEx don't have channel info so don't need pasting/moving

r.PreventUIRefresh(1)

local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)

-- MIDIEditor_GetSetting_int(ME, 'default_note_chan') used inside Re_Store_Selected_CCEvents() is unreliable in getting the current channel because when 'All Channels' or 'Multichannel' option is selected in the Channel filter it still returns the last active channel which may not be the channel the user intends to use as the source but which will be selected by Re_Store_Selected_CCEvents() restore routine and if such channel has no events the script will throw an error message about absence of valid selected events, hence the need to make the user select the channel explicitly; restoring the channel selection to 'All Channels' in this case will not look consistent if the user initially had channel selected

local filter_on
	for i = 40218, 40233 do -- ID range of actions 'Channel: Show only channel X' which select a channel in the filter and enable the filter
		if r.GetToggleCommandStateEx(32060, i) == 1 then filter_on = 1 break end
	end
	if not filter_on then
	local s = ' '
	r.MB(s:rep(10)..'The script only supports one source channel.\n\n   It appears that the MIDI channel filter is not enabled.\n\n\t'..s:rep(6)..'For the script to work reliably\n\n  please select the MIDI channel in the filter and enable it.', 'ALERT', 0)
	return r.defer(function() do return end end) end

local sel_evts_t = Re_Store_Selected_CCEvents(ME, take, t) -- store & deselect all so that currently visible lanes can be easily identified through selection of their events inside Get_Currently_Visible_CC_Lanes()

local vis_lanes_t = Get_Currently_Visible_CC_Lanes(ME, take)

Re_Store_Selected_CCEvents(ME, take, sel_evts_t, true) -- deselect_before_restore is true // restore all since 'Edit: Select all CC events in time selection (in all visible CC lanes)' used inside Get_Currently_Visible_CC_Lanes() deselects all CC events in hidden CC lanes

local notes_selected = r.MIDI_EnumSelNotes(take, -1) > -1 -- 1st selected note in current MIDI channel
local ccevt_selected = r.MIDI_EnumSelCC(take, -1) > -1 -- 1st selected CC event // in current MIDI channel but across all CC lanes
local autom_lane = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane') -- last clicked if several lanes are displayed, otherwise currently visible lane
local lanes_err = 'No valid selected events in visible lanes.'
	if not notes_selected then
	local err
		if #vis_lanes_t == 0 then -- no valid CC lane
			if autom_lane == 512 -- velocity
			or autom_lane == 519 -- off velocity
			or autom_lane == 517 -- text events
			or autom_lane == 518 -- SysEx
			or autom_lane == 517 -- text events
			or autom_lane == 520 -- notation events
			or autom_lane == 522 -- media item lane
			then err = '     Channel data is irrelevant\n\nto events in the current lane(s).'
			elseif autom_lane >= 256 and autom_lane <= 287 then
			err = string.rep(' ', 12)..'14 bit CC lanes aren\'t supported.\n\nSwitch to the corresponding 7 bit lane and retry.'
			end
		elseif #vis_lanes_t == 1 and not ccevt_selected then -- 1 valid CC lane // no selected events across all CC lanes and hence in the visible one as well
		err = lanes_err
		end
		if err then r.MB(err, 'ERROR', 0)
		return r.defer(function() do return end end) end
	end


-- Find if there're selected events in at least one visible CC lane (out of several)
local evt_idx = 0
local sel_cnt = 0
	repeat -- deselect all
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- just to use retval to stop the loop
		for _, cc in ipairs(vis_lanes_t) do
			if sel and (chanmsg == 176 and cc == msg2 or chanmsg == cc) then sel_cnt = sel_cnt+1 break end -- for non-CC messages (chanmsg =/= 176) their chanmsg value is stored since it's unique while their msg2 value doesn't refer to the CC#
		end
		if sel_cnt > 0 then break end -- exit if at least one found
	evt_idx = evt_idx+1
	until not retval

	if sel_cnt == 0 and not notes_selected then
	r.MB(lanes_err, 'ERROR', 0)
	return r.defer(function() do return end end) end


Re_Store_Selected_CCEvents(ME, take) -- deselect all


-- Only re-select originally selected events in the visible lanes
local cur_chan = r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') -- 0-15

	for _, sel_evts_data in ipairs(sel_evts_t) do
	local chmsg, chan, msg2 = sel_evts_data[5], sel_evts_data[6], sel_evts_data[7]
		if chan == cur_chan then
			for _, cc in ipairs(vis_lanes_t) do
				if chmsg == 176 and cc == msg2 -- CC message, chanmsg = 176
				or chmsg == cc then -- non-CC message (chanmsg =/= 176) which has channel data, such as Pitch, Channel pressure, ProgramChange and for which chanmsg value is stored instead since it's unique while their msg2 value doesn't refer to the CC#
				local evt_idx = sel_evts_data[9]
				r.MIDI_SetCC(take, evt_idx, true, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn, noSortIn true
				end
			end
		end
	end
r.MIDI_Sort(take)


::RETRY::

local retval, output = r.GetUserInputs('List target MIDI channels 1-16 (space separated or range X - X)', 1, 'Precede with M or m to move, extrawidth=150', autofill or '') -- in practice any non-numeric char can serve as a separator
	if not retval or not validate(output) then return r.defer(function() do return end end) end
 -- r.GetUserInputs('USER SETTINGS', 2, 'Notes (1) or CC (2),Channels (space separated), extrawidth=100', autofill or '')
	--	if not retval or output:gsub(' ','') == ',' then return r.defer(function() do return end end) end

local move, channels = output:match('%s*([Mm]+)(.+)')
local output = not move and output or channels

local ch_t = {}

	for i = 1, 16 do -- 16 MIDI channels
		if get_index_from_range_or_list(output, i) then
		ch_t[#ch_t+1] = i
		end
	end


	if #ch_t == 0 or #ch_t == 1 and ch_t[1]-1 == cur_chan -- -1 to conform to 0-based system used in cur_chan value
	then
	local err = #ch_t == 0 and 'No valid target MIDI channel has been specified.' or 'The target MIDI channel is the same as the current one.'
	local resp = r.MB(err, 'ERROR', 5)
		if resp == 4 then autofill = move and move..output or output goto RETRY
		else return r.defer(function() do return end end)
		end
	end

local cur_ch_comm_ID = 40218 + cur_chan -- 40218 is 'Channel: Show only channel 01'

r.Undo_BeginBlock()

	if not notes_selected then -- when notes aren't copied with MIDI automation because of not being selected or being non-existent, insert a temporary guide note to ensure that pasted CC envelopes relative position is preserved because setting the edit cursor to the 1st selected CC envelope point before pasting or at the start of the item and pasting with action 'Edit: Paste preserving position in measure' for some reason doesn't work or doesn't work consistently, it might work for the 1st cycle of the loop below and not work for the rest // when notes are copied with MIDI automation running 'Edit: Paste preserving position in measure' from the item start works always
	r.MIDI_InsertNote(take, true, true, 0, 1, cur_chan, 0, 1, false) -- selected, muted true, startppqpos 0, endppqpos 1, pitch 0, vel 1, noSortIn false
	r.MIDI_Sort(take)
	end

function delete_temp_note(take) -- only works for the active MIDI channel because of MIDI_GetNote()
local noteidx = 0
	repeat
	local retval, sel, muted, ppqpos, endppq, chan, pitch, vel = r.MIDI_GetNote(take, noteidx)
		if sel and muted and ppqpos == 0 and endppq == 1 and pitch == 0 and vel == 1 then
		r.MIDI_DeleteNote(take, noteidx) break
		end
	noteidx = noteidx+1
	until not retval
r.MIDI_Sort(take)
end

function get_visible_lanes_with_selected_events(take, vis_lanes_t)
-- Find numbers of the message types of visible lanes with selected events
local lanes_with_sel_evts_t = {}
local evt_idx = 0
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx)
		if sel then
			for _, cc in ipairs(vis_lanes_t) do
				if chanmsg == 176 and cc == msg2 -- CC message, chanmsg = 176
				or chanmsg == cc then -- non-CC message (chanmsg =/= 176) which has channel data, such as Pitch, Channel pressure, ProgramChange and for which chanmsg value is stored instead since it's unique while their msg2 value doesn't refer to the CC#
				local stored
					for _, cc2 in ipairs(lanes_with_sel_evts_t) do
						if cc == cc2 then stored = true break end
					end
					if not stored then
					local len = #lanes_with_sel_evts_t+1
					lanes_with_sel_evts_t[len] = chanmsg == 176 and msg2 or chanmsg -- only collect unique numbers of CC messages (chanmsg = 176) for which msg2 value represents CC#, or non-CC messages which have channel data (chanmsg is not 176) for which msg2 value doesn't represent CC#; chanmsg = Pitch bend - 224, Program - 192, Channel pressure - 208, Poly aftertouch - 160
					end
				end
			end
		end
	evt_idx = evt_idx+1
	until not retval
return lanes_with_sel_evts_t
end


function delete_evts_from_target_lanes(take, lanes_with_sel_evts_t) -- before pasting/moving in case there's old automation to prevent mixing/garbling
-- Count events in the current channel to use in reversed loop below for the sake of deletion
local count = 0
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, count)
		if not retval then break end
	count = count+1
	until not retval
-- Delete events from target lanes, if any
r.MIDI_DisableSort(take)
local evt_idx = count-1 -- in reverse due to deletion, -1 because the count ends up being 1-based
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx)
		if not retval then break end
		for _, cc in ipairs(lanes_with_sel_evts_t) do
			if chanmsg == 176 and cc == msg2 -- CC message, chanmsg = 176
			or chanmsg == cc then -- non-CC message (chanmsg =/= 176) which has channel data, such as Pitch, Channel pressure, ProgramChange and for which chanmsg value is stored instead since it's unique while their msg2 value doesn't refer to the CC#
			r.MIDI_DeleteCC(take, evt_idx)
			end
		end
	evt_idx = evt_idx-1
	until not retval
r.MIDI_Sort(take)
end


function delete_notes_in_MIDI_channel(take) -- to delete in the target MIDI channels
-- Count notes in the current channel to use in reversed loop below for the sake of deletion
local count = 0
	repeat
	local retval, sel, muted, ppqpos, endppq, chan, pitch, vel = r.MIDI_GetNote(take, count)
		if not retval then break end
	count = count+1
	until not retval
r.MIDI_DisableSort(take)
local note_idx = count-1 -- in reverse due to deletion, -1 because the count ends up being 1-based
	repeat
	r.MIDI_DeleteNote(take, note_idx)
	note_idx = note_idx-1
	until note_idx < 0
r.MIDI_Sort(take)
end


local lanes_with_sel_evts_t = get_visible_lanes_with_selected_events(take, vis_lanes_t)


	if move then
	ACT(40012) -- Edit: Cut // doesn't work in ternary expression
	else
	ACT(40010) -- Edit: Copy
	end

	if not notes_selected then delete_temp_note(take) end -- delete from the source channel

	for _, ch in ipairs(ch_t) do
		if ch-1 ~= cur_chan then -- ignoring current MIDI channel
		local comm_ID = cur_ch_comm_ID + (ch-1 - cur_chan) -- ch-1 to conform to 0-based system used in cur_chan value
		ACT(comm_ID) -- 'Channel: Show only channel N'
		delete_evts_from_target_lanes(take, lanes_with_sel_evts_t)
			if notes_selected then delete_notes_in_MIDI_channel(take) end
		ACT(40036) -- View: Go to start of file
		ACT(40429) -- Edit: Paste preserving position in measure
			if not notes_selected then delete_temp_note(take) end -- delete from each channel after pasting/moving content
		end
	end


Re_Store_Selected_CCEvents(ME, take, sel_evts_t, false) -- deselect_before_restore false

r.PreventUIRefresh(-1)

r.Undo_EndBlock((move and 'Move' or 'Paste')..' notes and/or other MIDI events to specified MIDI channels', -1)



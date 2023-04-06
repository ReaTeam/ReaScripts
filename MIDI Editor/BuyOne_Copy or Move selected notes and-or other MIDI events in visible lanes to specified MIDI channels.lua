--[[
ReaScript name: Copy or Move selected notes and/or other MIDI events in visible lanes to specified MIDI channels
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 2.0
Changelog: #Overhauled the code to allow copying and moving selected events from multiple channels
Licence: WTFPL
REAPER: at least v5.962
About: 	The script copies/moves selected notes and/or selected CC events in visible lanes
	to user specified MIDI channels. If the target lane in another MIDI channel already
	contains events or piano roll already contains notes, these will be replaced by those 
	being copied or moved.  

	If several CC lanes are open, selected events in 14 bit CC lanes will be ignored, 
	therefore if you need them affected by the sctipt be sure to switch 14-bit
	lanes to their 7-bit counterparts.  

	1. Select MIDI notes and/or other MIDI events  
	2. Run the script  
	3. In the input field list target MIDI channel numbers space separated or specify range as X - X  
	(inverted range is supported, e.g. 13 - 4)  
	4. Precede the list/range with the letter M or m if you wish the events to be moved rather than copied  
	5. Click OK  

	If there're several visible lanes and only one of them contains selected events 
	be sure to make it the last clicked by clicking it so that the events are  
	copied/moved to the lane of the same message type in other MIDI channels.  

	Besides strictly CC events also supported are Pitch bend, Program change and Channel pressure events.
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

function Re_Store_Selected_CCEvents1(ME, take, t, deselect_before_restore) -- deselect_before_restore is boolean
-- !!!! will work EVEN IF events were deleted or added in the interim FOR ALL MIDI CHANNELS
-- if channel filter is enabled per channel clicking within one MIDI channel doesn't affect event selection in other MIDI channels
-- if channel filter is enabled per channel deleting selected events in one MIDI channel with action doesn't affect selected events in other MIDI channels; in the same MIDI channels selected events are deleted regardless of their lane visibility
-- with the mouse CC events can only be selected in one lane, the selection is exclusive just like track automation envelope nodes unless Shift is held down, marque selection or Ctrl+A are used
local ME = not ME and r.MIDIEditor_GetActive() or ME
local take = not take and r.MIDIEditor_GetTake(ME) or take
local cur_chan = r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') -- 0-15 // returns last channel when channel filter is set to 'All Channels' or 'Multichannel'
local cur_ch_comm_ID = 40218 + cur_chan -- 40218 is 'Channel: Show only channel 01' // will be used to restore current channel after traversing all regardless of whether channel filter is enabled

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
				t[#t+1] = {retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3, evt_idx} -- store and deselect // evt_idx is stored to be able to reselect events in the visible lanes after using Get_Currently_Visible_CC_Lanes()
				r.MIDI_SetCC(take, evt_idx, false, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn false, noSortIn true // deselect
				end
			evt_idx = evt_idx+1
			until not retval
		r.MIDI_Sort(take)
		end
	--	r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation
	r.MIDIEditor_LastFocused_OnCommand(cur_ch_comm_ID, false) -- islistviewcommand false // restore original channel
	r.PreventUIRefresh(-1)
	return t, cur_chan
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


function Re_Store_Selected_CCEvents2(ME, take, t, deselect_before_restore) -- deselect_before_restore is boolean
-- !!!! will work EVEN IF events were deleted or added in the interim BUT FOR THE CURRENTLY ACTIVE MIDI CHANNELS IF THE MIDI FILTER IS ENABLED
-- if channel filter is enabled per channel clicking within one MIDI channel doesn't affect event selection in other MIDI channels
-- if channel filter is enabled per channel deleting selected events in one MIDI channel with action doesn't affect selected events in other MIDI channels; in the same MIDI channels selected events are deleted regardless of their lane visibility
-- with the mouse CC events can only be selected in one lane, the selection is exclusive just like track automation envelope nodes unless Shift is held down, marque selection or Ctrl+A are used
local ME = not ME and r.MIDIEditor_GetActive() or ME
local take = not take and r.MIDIEditor_GetTake(ME) or take

	if not t then
	local t, evt_idx = {}, 0
		repeat
		local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- only targets events in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for events from current channel // if looking for all events use Clear_Restore_MIDI_Channel_Filter() to disable filter if enabled and re-enable afterwards
			if sel then
			t[#t+1] = {retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3, evt_idx} -- store and deselect // evt_idx is stored to be able to reselect events in the visible lanes with Only_Select_Evnts_In_Visble_CC_Lanes() after using Get_Currently_Visible_CC_Lanes()
			r.MIDI_SetCC(take, evt_idx, false, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn false, noSortIn true // deselect
			end
		evt_idx = evt_idx+1
		until not retval
	r.MIDI_Sort(take)
--	r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation
	return t
	else
--	r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation
		if deselect_before_restore then
		local evt_idx = 0
			repeat -- deselect all
			local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- just to use retval to stop the loop // probably MIDI_SetCC() boolean return value could be used instead //  only targets events in the current MIDI channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for events from current channel // if looking for all events use Clear_Restore_MIDI_Channel_Filter() to disable filter if enabled and re-enable afterwards
			r.MIDI_SetCC(take, evt_idx, false, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn false, noSortIn true // deselect
			evt_idx = evt_idx+1
			until not retval
		r.MIDI_Sort(take)
		end
	r.MIDI_Sort(take)
	local evt_idx = 0
		repeat
		local evt_data = {r.MIDI_GetCC(take, evt_idx)} -- only targets events in the current MIDI channel if Channel filter is enabled
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
end


function Get_Currently_Active_Chan_And_Filter_State(ME, take)
-- returns number of currently active channel if channel filter is enabled or multiple active channels if multichannel mode is enabled
-- if filter isn't enabled and no multichannel mode, the returned table will be empty and the filter state will be nil
-- MIDI Ed actions toggle state can only be evaluated when ME is open
local is_open = ME or r.MIDIEditor_GetActive() -- check if MIDI Editor is open
-- OR
-- local is_open = ME or r.GetToggleCommandStateEx(32060, 40218) > -1
local open = not is_open and r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
local ME = r.MIDIEditor_GetActive()
local take = not take and r.MIDIEditor_GetTake(ME) or take
local act_ch_t, filter_state = {}

	for i = 40218, 40233 do -- ID range of actions 'Channel: Show only channel X' which select a channel in the filter and enable the filter
		if r.GetToggleCommandStateEx(32060, i) == 1 then
		filter_state = i-40217 break end -- currently active channel 1-based
	end

	for i = 40643, 40658 do -- ID range of actions 'Channel: Toggle channel X' which activate the Multichannel mode and aren't mutually exclusive
		if r.GetToggleCommandStateEx(32060, i) == 1 then
		act_ch_t[#act_ch_t+1] = i-40642 -- store 1-based ch #
		end
	end

	if not is_open then r.MIDIEditor_LastFocused_OnCommand(2, false) end -- File: Close window; islistviewcommand false

-- the table is empty and filter_state is false when the filter isn't enabled and some channel is selected in its drop-down menu or when All channels option is enabled regardless of filter actual state
-- the table contains a single channel and filter_state is assigned a channel number when the filter is enabled and a single channel is exclusively displayed by being selected in the filter drop-down menu
-- the table contains several channels and filter_state is true when Multichannel mode is enabled
-- so basically this function cannot detect a single channel selected in the filter when the filter is OFF
return act_ch_t, filter_state

end



function Get_Currently_Visible_CC_Lanes(ME, take) -- -- WITH EVENTS ONLY, must be preceded and followed by Re_Store_Selected_CCEvents() because it changes selection
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

r.MIDIEditor_LastFocused_OnCommand(40802, false) -- islistviewcommand false // Edit: Select all CC events in time selection (in all visible CC lanes) -- DOESN'T AFFECT non-CC events BUT IGNORES visible 14-bit lanes // EXCLUSIVE, i.e. deselects all other CC events
-- https://forum.cockos.com/showthread.php?t=272887
local idx = -1 -- start with -1 since MIDI_EnumSelCC returns idx of the next event hence will actually start from 0
local evt_t, ch_t = {}, {}
	repeat
	idx = r.MIDI_EnumSelCC(take, idx)
		if idx > -1 then
		local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, idx) -- point indices are based on their time position hence points with sequential indices will likely belong to different CC envelopes
		local stored
			for _, cc in ipairs(evt_t) do
			-- when 'Bank/Program select' (chanmsg 176 but no dedicated lane number) event is created it automatically creates events also in Program and Bank select 00 and 32 lanes, and if those weren't deleted manually when 'Bank/Program select' event is selected the number of selected events is tripled because they're also selected in lanes 00/32 Bank select MSB/SLB and Program as well, so excessive count should be avoided; this also ensures that bank/program events in all 4 lanes (Program, Bank/program select, 00/32 Bank select MSB/LSB) can be re-selected independently, same below, honestly cannot understand how it works
				if cc == 192 and chanmsg == 176 and (msg2 == 0 or msg2 == 32)
				or cc == msg2 or cc == chanmsg then stored = 1 break end
			end
			if not stored then
			-- only collect unique numbers of CC messages (chanmsg = 176) for which msg2 value represents CC#, or non-CC messages which have channel data (chanmsg is not 176) for which msg2 value doesn't represent CC#; chanmsg = Pitch bend - 224, Program - 192, Channel pressure - 208, Poly aftertouch - 160
			local cc = chanmsg == 176 and (msg2 == 0 or msg2 == 32) and 192 or chanmsg == 176 and msg2 or chanmsg
			evt_t[#evt_t+1] = cc
			end
		local stored
			for _, ch in ipairs(ch_t) do
				if ch == chan then stored = 1 break end
			end
			if not stored then ch_t[#ch_t+1] = chan end
		end
	until idx == -1

	--r.MIDIEditor_LastFocused_OnCommand(40671, false) -- islistviewcommand false // Unselect all CC events -- IN FACT DESELECTS EVEN non-CC events such as text and notation

-- DESELECTION OF ALL IS HANDLED BY Re_Store_Selected_CCEvents() instead of the above action

r.GetSet_LoopTimeRange(true, false, time_st, time_end, false) -- isSet true, isLoop, allowautoseek false // restore
r.PreventUIRefresh(-1)

table.sort(evt_t)
return evt_t

end


function get_visible_lanes_with_selected_events(take, vis_lanes_t)
-- Find numbers of the message types of visible lanes with selected events
-- vis_lanes_t arg stems from Get_Currently_Visible_CC_Lanes() function
local lanes_with_sel_evts_t, ch_t = {}, {}
local evt_idx = 0
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx)
		if sel then
			for _, cc in ipairs(vis_lanes_t) do
				if cc == 192 and chanmsg == 176 and (msg2 == 0 or msg2 == 32) -- this ensures that bank/program events in all 4 lanes (Program, Bank/program select, 00/32 Bank select MSB/LSB) can be re-selected, same below, honestly cannot understand how it works
				or chanmsg == 176 and cc == msg2 -- CC message, chanmsg = 176
				or chanmsg == cc then -- non-CC message (chanmsg =/= 176) which has channel data, such as Pitch, Channel pressure, ProgramChange and for which chanmsg value is stored instead since it's unique while their msg2 value doesn't refer to the CC#
				local stored
					for _, cc2 in ipairs(lanes_with_sel_evts_t) do
						if cc == cc2 then stored = true break end
					end
					if not stored then
					-- only collect unique numbers of CC messages (chanmsg = 176) for which msg2 value represents CC#, or non-CC messages which have channel data (chanmsg is not 176) for which msg2 value doesn't represent CC#; chanmsg = Pitch bend - 224, Program - 192, Channel pressure - 208, Poly aftertouch - 160
					local len = #lanes_with_sel_evts_t+1
					local cc = chanmsg == 176 and (msg2 == 0 or msg2 == 32) and 192 or chanmsg == 176 and msg2 or chanmsg
					lanes_with_sel_evts_t[len] = cc
					end
				local stored
					for _, ch in ipairs(ch_t) do
						if ch == chan then stored = 1 break end
					end
					if not stored then ch_t[#ch_t+1] = chan end
				end
			end
		end
	evt_idx = evt_idx+1
	until not retval

return lanes_with_sel_evts_t, ch_t

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

local filter_on
	for i = 40218, 40233 do -- ID range of actions 'Channel: Show only channel X' which select a channel in the filter and enable the filter
		if r.GetToggleCommandStateEx(32060, i) == 1 then filter_on = i-40217 break end -- storing currently active channel 1-based
	end

local Re_Store_Selected_CCEvents = filter_on and Re_Store_Selected_CCEvents1 or Re_Store_Selected_CCEvents2 -- select function depending on the channel filter state, if it's NOT enabled Re_Store_Selected_CCEvents1() function won't be able to restore the initial filter state after the main routine, hence the 2nd version of the function must be used, but if it is enabled, collecting selected events across all MIDI channels is only possible with its 1st version which at the end of the routine will also ensure that the filter remains enabled

local sel_evts_t = Re_Store_Selected_CCEvents(ME, take, t) -- store all selected events including in non-visble lanes if any & deselect all so that currently visible lanes can be easily identified through selection of their events inside Get_Currently_Visible_CC_Lanes()

local vis_lanes_t = Get_Currently_Visible_CC_Lanes(ME, take) -- the function doesn't detect lanes with no events (because there's nothing to select by the action used) and 14-bit lanes (because their events aren't selected by the action used) hence their events aren't supported // for lane numbers VELLANE chunk token can be used instead
local evt_ch_t, filter_state = Get_Currently_Active_Chan_And_Filter_State(ME, take)
local evt_ch_t = #evt_ch_t > 0 and evt_ch_t or {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16} -- if table is empty all channels are active, in which case use all channels for restoration of user selection

Re_Store_Selected_CCEvents(ME, take, sel_evts_t, true) -- deselect_before_restore is true // restore all since 'Edit: Select all CC events in time selection (in all visible CC lanes)' used inside Get_Currently_Visible_CC_Lanes() deselects all CC events in hidden CC lanes

local lanes_with_sel_evts_t, ch_t = get_visible_lanes_with_selected_events(take, vis_lanes_t) -- ch_t contains channels of selected events to be used in evaluation against user input

local last_clicked_lane = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane')

local s = ' ' -- will be used elsewhere as well

	if #lanes_with_sel_evts_t == 1 then -- since copying is done with an action last clicked lane matters because it's targeted by the action
	local lane = lanes_with_sel_evts_t[1]
		if last_clicked_lane == 513 and lane ~= 224 -- pitch
		or (last_clicked_lane == 514 or last_clicked_lane == 516 or last_clicked_lane == 0 or last_clicked_lane == 32) and lane ~= 192 -- program change | bank/program select | 00 Program change MSB & LSB, all 4 are stored under code 192
		or last_clicked_lane == 515 and lane ~= 208 -- channel pressure
		or (last_clicked_lane < 513 and last_clicked_lane ~= 0 and last_clicked_lane ~= 32 or last_clicked_lane > 516) and last_clicked_lane ~= lane then
		r.MB('    There\'re no selected events in the last clicked lane.\n\n'..s:rep(17)..'This will result in selected events\n\n'..s:rep(6)..'being pasted to a lane different from the original.\n\n'..s:rep(6)..'Please click a lane with selected events and retry.\n\nIf the last clicked lane is 14-bit and has selected events\n\n'..s:rep(10)..'switch to the regular lane so it\'s recognized.', 'ERROR', 0)
		return r.defer(function() do return end end)
		end
	end

local notes_selected
local i = 0
	repeat -- run till the end to count selected notes
	local retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(take, i) -- targets all channels or only active so separate evaluation against each channel isn't necessary
		if not retval then break end
	i = i+1 -- placed after break so that total note count is exact
		if sel then	notes_selected = 1
		local stored
			for _, ch in ipairs(ch_t) do -- store note channels in addition to event channels
				if chan == ch then stored = 1 break end
			end
			if not stored then ch_t[#ch_t+1] = chan end
		end
	until not retval

local note_cnt = i -- in active channels

local ccevt_selected
local ccevt_cnt = 0
local i = 0
	repeat -- run till the end to count selected events
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, i) -- targets all channels or only active so separate evaluation against each channel isn't necessary
		if not retval then break end
	i = i+1 -- placed after break so that total event count is exact
		for _, cc in ipairs(vis_lanes_t) do
			if cc == 192 and chanmsg == 176 and (msg2 == 0 or msg2 == 32) -- all 4 lanes (Program, Bank/program select, 00 Bank select MSB, 32 Bank select LSB) are stored under code 192 to ensure their events re-selection below
			or chanmsg == 176 and cc == msg2 or chanmsg == cc then  -- for non-CC messages (chanmsg =/= 176) their chanmsg value is stored in the table since it's unique while their msg2 value doesn't refer to the CC#
			ccevt_cnt = ccevt_cnt+1 -- in visible lanes
				if sel then ccevt_selected = 1 end
			end
		end
	until not retval

local notes_mess = 'No selected notes.'
local vis_lanes_mess = ' Visible lane type isn\'t supported or no events.\n\n     If there\'re selected events in 14-bit lanes\n\nswitch to main lanes so that they\'re recognized.'
local err = note_cnt > 0 and not notes_selected and #vis_lanes_t == 0 and notes_mess..' '..vis_lanes_mess or note_cnt == 0 and #vis_lanes_t == 0 and vis_lanes_mess or note_cnt+ccevt_cnt == 0 and 'No valid selected events in the active MIDI channels.' or note_cnt > 0 and ccevt_cnt == 0 and not notes_selected and notes_mess or note_cnt == 0 and ccevt_cnt > 0 and not ccevt_selected and (' '):rep(18)..'No valid selected events.\n\n     If there\'re selected events in 14-bit lanes\n\nswitch to main lanes so that they\'re recognized.' or not notes_selected and not ccevt_selected and 'No selected events.'

	if err then r.MB(err, 'ERROR', 0) return r.defer(function() do return end end) end


Re_Store_Selected_CCEvents(ME, take) -- deselect all

-- Only re-select originally selected events in the visible lanes; notes don't need to be selected exclusively in the active channels because inactive channels are ignored; search by index isn't reliable as they change after sorting, so all return values must be collated to find originally selected events bar selected status value because at this stage the event won't be selected; this loop basically searches for current indices of the stored events so they can be re-selected

local i = 0
	repeat
	local evt_data = {r.MIDI_GetCC(take, i)}
		for _, sel_evts_data in ipairs(sel_evts_t) do

		local match_cnt = 0
			for i = 3, 8 do
			match_cnt = evt_data[i] == sel_evts_data[i] and match_cnt+1 or match_cnt
			end

			if match_cnt == 6 then -- original event found in sel_evts_t table
			local chmsg, chan, msg2 = table.unpack(sel_evts_data,5,7)

			-- now determine if the original event belongs to one of the visible lanes, 14-bit lane events aren't supported
			local evt_match
				for _, cc in ipairs(vis_lanes_t) do
					if cc == 192 and chmsg == 176 and (msg2 == 0 or msg2 == 32) -- all 4 lanes (Program, Bank/program select, 00/32 Bank select MSB/LSB) are stored under code 192 to ensure their events re-selection
					or chmsg == 176 and cc == msg2 -- CC message, chanmsg = 176
					or chmsg == cc then -- non-CC message (chanmsg =/= 176) which has channel data, such as Pitch, Channel pressure, ProgramChange and for which chanmsg value is stored instead since it's unique while their msg2 value doesn't refer to the CC#
					evt_match = 1
					break end
				end
			-- when channel filter is enabled per channel or multichannel mode is enabled, belonging to one of the visible lanes isn't enough because the channel an event belongs to may not be visible
				if evt_match then
					for _, ch in ipairs(evt_ch_t) do
						if chan == ch-1 then -- ch-1 because channels are stored by Get_Currently_Active_Chan_And_Filter_State() using 1-based count
				--[[ OR
					for _, ch in ipairs(ch_t) do -- using table returned by get_visible_lanes_with_selected_events()
					if chan == ch then
					]]
						r.MIDI_SetCC(take, i, true, mutedIn, ppqposIn, chanmsgIn, chanIn, msg2In, msg3In, true) -- selectedIn, noSortIn true
						break end
					end
				end
			break end
		end
	i = i+1
	until not evt_data[1]

r.MIDI_Sort(take)


::RETRY::

local retval, output = r.GetUserInputs('List target MIDI channels 1-16 (space separated or range X - X)', 1, 'Precede with M or m to move, extrawidth=150', autofill or '') -- in practice any non-numeric char can serve as a separator
	if not retval or not validate(output) then return r.defer(function() do return end end) end

local move, channels = output:match('%s*([Mm]+)(.+)')
local output = not move and output or channels

-- Collect user specified channels
local user_ch_t = {}
	for i = 1, 16 do -- 16 MIDI channels
		if get_index_from_range_or_list(output, i) then
		user_ch_t[#user_ch_t+1] = i
		end
	end

-- Determine if user specified channels match currently active channels
local ch_match = 0
	for _, ch1 in ipairs(user_ch_t) do
		for _, ch2 in ipairs(ch_t) do
			if ch1-1 == ch2 then ch_match = ch_match+1 end -- -1 to conform to 0-based channel count used by the API
		end
	end


local err = #user_ch_t == 0	and 'No valid target MIDI channel has been specified.'
local err = not err and (--#user_ch_t <= #ch_t and
ch_match == #user_ch_t and 'The target MIDI channels are the same\n\nas those the selected events belong to.' or ch_match > 0 and 'Matches found between target MIDI channels\n\n     and those the selected events belong to.\n\n'..s:rep(3)..'Should the matching channels be excluded?') or err

	if err then
	local title = err:match('%?') and 'PROMPT' or 'ERROR'
	local typ = err:match('%?') and 3 or 5
	resp = r.MB(err, title, typ)
		if resp == 4 then autofill = move and move..output or output goto RETRY
		elseif resp == 2 then return r.defer(function() do return end end)
		end
	end

-- Exclude current channels from user channel table
	if resp == 6 then
		for i = #user_ch_t, 1, -1 do
		local ch = user_ch_t[i]
			for _, chan in ipairs(ch_t) do
				if chan == ch-1 then table.remove(user_ch_t,i) break end -- -1 to conform to 0-based channel count used by the API
			end
		end
	end


r.Undo_BeginBlock()

	if not notes_selected then -- when notes aren't copied with MIDI automation because of not being selected or being non-existent, insert a temporary guide note to ensure that pasted CC envelopes relative position is preserved because setting the edit cursor to the 1st selected CC envelope point before pasting or at the start of the item and pasting with action 'Edit: Paste preserving position in measure' for some reason doesn't work or doesn't work consistently, it might work for the 1st cycle of the loop below and not work for the rest // when notes are copied with MIDI automation running 'Edit: Paste preserving position in measure' from the item start works always
	r.MIDI_InsertNote(take, true, true, 0, 1, ch_t[1], 0, 1, false) -- selected, muted true, startppqpos 0, endppqpos 1, pitch 0, vel 1, noSortIn false // if multiple channels are active it's enough to insert such guide note in any of them
	r.MIDI_Sort(take)
	end


function delete_temp_note(take) -- only works for the active MIDI channel because of MIDI_GetNote()
r.MIDI_DisableSort(take)
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


function delete_notes_in_MIDI_channel(take)
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

	if move then
	ACT(40012) -- Edit: Cut // doesn't work in ternary expression
	else
	ACT(40010) -- Edit: Copy
	end

	if not notes_selected then delete_temp_note(take) end -- delete from the source channel (or 1st source channel if many are active) after cutting/copying

	for _, ch in ipairs(user_ch_t) do
		local comm_ID = 40218 + ch-1 -- -1 since 40218 already corresponds to the 1st channel, otherwise 40217 (Channel: Show all channels) could be used as a starting ID
		ACT(comm_ID) -- 'Channel: Show only channel N'
		delete_evts_from_target_lanes(take, lanes_with_sel_evts_t)
			if notes_selected then delete_notes_in_MIDI_channel(take) end
		ACT(40036) -- View: Go to start of file
		ACT(40429) -- Edit: Paste preserving position in measure
			if not notes_selected then delete_temp_note(take) end -- delete from each channel after pasting/moving content
	end


Re_Store_Selected_CCEvents1(ME, take, sel_evts_t, false) -- deselect_before_restore false // here Re_Store_Selected_CCEvents1() function must be used because the script ends up enabling the MIDI filter for the target channels and while the channel filter is enabled it's only possible to affect (in this case restore selection) other channels by cycling through them with this function, Re_Store_Selected_CCEvents2() only affects channel currently selected in the channel filter

r.PreventUIRefresh(-1)

r.Undo_EndBlock((move and 'Move' or 'Paste')..' notes and/or other MIDI events to specified MIDI channels', -1)




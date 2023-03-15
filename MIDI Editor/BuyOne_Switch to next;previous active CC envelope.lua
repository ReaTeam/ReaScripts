--[[
ReaScript name: Switch to next/previous active CC envelope
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Metapackage: true
Provides: . > BuyOne_Switch to next active CC envelope.lua
	  . > BuyOne_Switch to previous active CC envelope.lua
About: 	Works for the last clicked CC lane if several are open.

	If next/previous active CC envelope is already open in
	another visible lane, in the active lane it's skipped. 

	If all active envelopes are already open in visible lanes
	no switching occurs.

	Also supports Pitch bend, Channel pressure and Program change
	envelopes.  
	Ignores Velocity, Off Velocity, Text events, Notation enents 
	and SySex lanes.  
	CC00-31 14 bit CC lanes currently aren't supported either.
]]


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('.+[\\/](.+)') -- whole script name without path
	if scr_name:match(' next ') then nxt = 1
	elseif scr_name:match(' previous ') then prev = 1
	end


function CC_Evts_Exist(take)
local evt_idx = 0
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- Velocity / Off Velocity / Text events / Notation enents / SySex lanes are ignored
		if retval then return retval end -- as soon as a selected event is found
	evt_idx = evt_idx + 1
	until not retval
end



local ME = r.MIDIEditor_GetActive()
local take = r.MIDIEditor_GetTake(ME)

local err = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane') == -1 and '\tlast clicked cc lane \n\n'..string.rep(' ', 10)..' was\'t found. \n\n click at least one cc lane.' -- happens when a lane was closed
or not CC_Evts_Exist(take) and 'no active cc envelopes'

	if err then
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip(('\n\n '..err..' \n\n '):upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
	return r.defer(function() do return end end) end


function ACT(comm_ID, midi) -- midi is boolean
local act = midi and r.MIDIEditor_LastFocused_OnCommand(r.NamedCommandLookup(comm_ID), false) -- islistviewcommand false
or r.Main_OnCommand(r.NamedCommandLookup(comm_ID), 0)
end


function is_CC_Env_active(ME, take) -- whether there're events
local cur_CC_lane = r.MIDIEditor_GetSetting_int(ME, 'last_clicked_cc_lane') -- last clicked if several lanes are displayed, otherwise currently visible lane
local cur_CC_lane = cur_CC_lane == 513 and 224 or cur_CC_lane == 515 and 208 or cur_CC_lane == 514 and 192 or cur_CC_lane -- converting  MIDIEditor_GetSetting_int() function return values to MIDI_GetCC() chanmsg return value: pitch bend, channel pressure, program change, regular CC
local evt_idx = 0
	repeat
	local retval, sel, muted, ppqpos, chanmsg, chan, msg2, msg3 = r.MIDI_GetCC(take, evt_idx) -- Velocity / Off Velocity / Text events / Notation enents / SySex lanes are ignored
		if retval then
			if chanmsg == 176 and msg2 == cur_CC_lane then return msg2  -- -- CC message, chanmsg = 176 // as soon as event is found in the current lane
			elseif chanmsg == cur_CC_lane then -- non-CC message (chanmsg =/= 176)
			return chanmsg == 192 and 'Program change' or chanmsg == 208 and 'Channel pressure' or chanmsg == 224 and 'Pitch bend'
			end
		end
	evt_idx = evt_idx + 1
	until not retval
end


function Switch_2_Next_Prev_Active_CCLane(ME, take, lane_cnt, nxt, prev)
local i = 0
	repeat
	local comm_ID = nxt and 40234 or prev and 40235
	-- both actions skip envelopes already open in other visible lanes
	-- 40235 -- CC: Previous CC lane // after the 1st lane (Velocity) returns to 119, , ignoring 14 bit lanes; only switches to 14 lanes if one such lane is already open // 14 bit lanes contain the same envelopes as their 7 bit counterparts
	-- 40234 -- CC: Next CC lane // after the last 7 bit lane (119) returns to the 1st (Velocity), ignoring 14 bit lanes; only switches to 14 lanes if one such lane is already open
	ACT(comm_ID, 0) -- 0 here is a boolean to activate MIDI function
	local CC = is_CC_Env_active(ME, take)
		if CC then return CC end
	i = i+1
	until CC or i == lane_cnt -- 129 is the number of lanes between Velocity and 119, the actions 'CC: Next/Previous CC lane' switch to every available lane, not just CC
end


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local CC = Switch_2_Next_Prev_Active_CCLane(ME, take, 129, nxt, prev)

-- a trick shared by juliansader to force MIDI API to register undo point; Undo_OnStateChange() works too but with native actions it may create extra undo points, therefore Undo_Begin/EndBlock() functions must stay
-- https://forum.cockos.com/showpost.php?p=1925555
local item = r.GetMediaItemTake_Item(take)
local is_item_sel = r.IsMediaItemSelected(item)
r.SetMediaItemSelected(item, not is_item_sel) -- unset
r.SetMediaItemSelected(item, is_item_sel) -- restore


r.Undo_EndBlock('Switch to '..(tonumber(CC) and 'CC'..CC or CC)..' lane', -1)
r.PreventUIRefresh(-1)




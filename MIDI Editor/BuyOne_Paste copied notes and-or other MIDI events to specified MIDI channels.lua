--[[
ReaScript name: Paste copied notes and/or other MIDI events to specified MIDI channels
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	1. Copy selected MIDI notes and/or other MIDI events
        2. Run the script
        3. List target MIDI channel numbers in the input field
        4. Click OK
]]

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function ACT(comm_ID)
r.MIDIEditor_LastFocused_OnCommand(comm_ID, false) -- islistviewcommand false
end

function validate(string)
return #string:gsub(' ','') > 0
end

::RETRY::

local retval, output = r.GetUserInputs('List target MID channels', 1, 'Channels (space separated), extrawidth=100', autofill or '')
	if not retval or not validate(output) then return r.defer(function() do return end end) end
	
	local ch_t = {}	
	for ch in output:gmatch('%d+') do
	ch_t[#ch_t+1] = tonumber(ch)
	end
	
local ME = r.MIDIEditor_GetActive()
local cur_chan = r.MIDIEditor_GetSetting_int(ME, 'default_note_chan') -- 0-15
	
	if #ch_t == 0 or #ch_t == 1 and ch_t[1]-1 == cur_chan -- -1 to conform to 0-based system used in cur_chan value
	then
	local err = #ch_t == 0 and 'No target MIDI channel has been specified.' or 'The target MIDI channel is the same as the current one.'
	local resp = r.MB(err, 'ERROR', 5)
		if resp == 4 then autofill = output goto RETRY
		else return r.defer(function() do return end end) 
		end	
	end
	
local cur_ch_comm_ID = 40218 + cur_chan -- 40218 is 'Channel: Show only channel 01'


r.Undo_BeginBlock()

r.PreventUIRefresh(1)

	for _, ch in ipairs(ch_t) do
		if ch-1 ~= cur_chan then -- ignoring current MIDI channel
		local comm_ID = cur_ch_comm_ID + (ch-1 - cur_chan) -- ch-1 to conform to 0-based system used in cur_chan value
		ACT(comm_ID) -- 'Channel: Show only channel N'
		ACT(40036) -- View: Go to start of file
		ACT(40429) -- Edit: Paste preserving position in measure
	end
	end

r.PreventUIRefresh(-1)

r.Undo_EndBlock('Paste notes and/or other MIDI events to specified MIDI channels', -1)














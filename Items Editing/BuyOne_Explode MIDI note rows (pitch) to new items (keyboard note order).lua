--[[
ReaScript name: Explode MIDI note rows (pitch) to new items (keyboard note order)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	The native action 'Item: Explode MIDI note rows (pitch) to new items'
        explodes note rows from the low to the high and in the tracklist
        the exploded items end up in the order inverse to the vertical note order on
        the keyboard, which seems counterintuitive, so the script is an alternative.  
        https://forum.cockos.com/showthread.php?t=276685
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable the setting place any alphanumeric character between
-- the quotation marks.

-- The native action creates child tracks
-- under the track with the exploded item,
-- enable to keep this folder structure;
-- if empty, the tracks with exploded items will be
-- converted to regular tracks
KEEP_FOLDER_STRUCTURE = "1"

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end

function Find_And_Get_New_Tracks(t)
	if not t then
	local t = {}
		for i = 0, r.GetNumTracks()-1 do
		t[r.GetTrack(0,i)] = '' -- dummy field
		end
	return t
	elseif t then
	local t2 = {}
		for i = 0, r.GetNumTracks()-1 do
		local tr = r.GetTrack(0,i)
			if not t[tr] then -- track wasn't stored so is new
			t2[#t2+1] = {tr=tr, idx=i}
			end
		end
	return #t2 > 0 and t2
	end
end

local item = r.GetSelectedMediaItem(0,0)
local act_take = r.GetActiveTake(item)
local is_midi = r.TakeIsMIDI(act_take)
r.PreventUIRefresh(1)
local open = is_midi and r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
local hwnd = r.MIDIEditor_GetActive()
local midi_take = r.MIDIEditor_GetTake(hwnd)
local retval, notecnt, ccevtcnt, textsyxevtcnt = table.unpack(is_midi and {r.MIDI_CountEvts(midi_take)} or {})
r.MIDIEditor_LastFocused_OnCommand(2, false) -- File: Close window; islistviewcommand false
local mess = not item and 'no selected item' or not is_midi and 'the take isn\'t MIDI' or notecnt == 0 and 'no notes in the midi take'
	if mess then Error_Tooltip('\n\n '..mess..' \n\n') return end

r.Undo_BeginBlock()
r.PreventUIRefresh(1)

local t = Find_And_Get_New_Tracks()
r.Main_OnCommand(40920, 0) -- Item: Explode MIDI note rows (pitch) to new items
local t = Find_And_Get_New_Tracks(t)

KEEP_FOLDER_STRUCTURE = #KEEP_FOLDER_STRUCTURE:gsub(' ','') > 0

	if t then
	local makePrevFolder = KEEP_FOLDER_STRUCTURE and 2 or 0 -- if beforeTrackIdx follows last track in folder or a normal one
	local ref_idx = t[#t].idx+1 -- track which immediately follows the last new track
	local decrement = 0
		for _, props in ipairs(t) do
		r.SetOnlyTrackSelected(props.tr)
		r.ReorderSelectedTracks(ref_idx-decrement, makePrevFolder) -- beforeTrackIdx is ref_idx-decrement
		decrement = decrement+1 -- at each cycle decrease beforeTrackIdx because each track will have to be placed before the previous and travel less places
		end
	r.Undo_EndBlock('Explode MIDI note rows (pitch) to new items (keyboard note order)',-1)
	r.PreventUIRefresh(-1)
	end



--[[
ReaScript name: Explode multichannel MIDI to new one-channel items obeying keyboard note order
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	Alternative to the native action  
		'Item: Explode multichannel MIDI or audio to new one-channel items' 
		for MIDI items.  
        The script re-orders tracks with exploded items according to the highest
		note in each MIDI channel in an attempt to mimic vertical order
		of parts in piano roll since MIDI channel is usually applied to notes 
		of the same part occupying specific range in the piano roll. 
		Of course performances with mixed MIDI channel assignment will give mixed
		results. 
		The MIDI item must be selected and take active in multi-take items.
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
KEEP_FOLDER = "1"

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

function Clear_Restore_MIDI_Channel_Filter(enabled_ID, is_open) -- must be applied to selected MIDI item
-- when Channel filter is enabled Get/Set functions only target events in the current channel
-- which may be undesirable if working with all events
-- run twice: 1) to open if not open and clear filter if enabled 2) to close if wasn't open initially and to restore filter if was enabled

-- Conditioning is reversed the 1st part will be activated after the 2nd when the function is run twice

	if enabled_ID then -- has been opened
	r.MIDIEditor_LastFocused_OnCommand(enabled_ID, false) -- islistviewcommand false // Re-enable filter
		if not is_open then r.MIDIEditor_LastFocused_OnCommand(2, false) end -- File: Close window;  islistviewcommand false // close if wasn't initially open
	else
	-- for the MIDI Editor action GetToggleCommandStateEx() only works if its open
	local is_open = r.MIDIEditor_GetActive() -- check if MIDI Editor is open
	local open = not is_open and r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor (set default behavior in preferences)
	local enabled_ID
		for i = 18, 33 do
			if r.GetToggleCommandStateEx(32060, 40200+i) == 1 -- ID range of actions which enable channel filter is 40218 - 40233 Channel: Show only channel X
			then enabled_ID = 40200+i break end
		end
		if enabled_ID then
		r.MIDIEditor_LastFocused_OnCommand(40217, false) -- Channel: Show all channels // islistviewcommand false // DISABLE FILTER || actions Channel: Toggle channel X could be evaluated instead, their ID range is 40643 - 40658
		return enabled_ID, is_open
		elseif not is_open then r.MIDIEditor_LastFocused_OnCommand(2, false) -- File: Close window;  islistviewcommand false // close if wasn't initially open and filter wasn't enabled otherwise will stay open until the 2nd run to re-enable the filter
		end
	end
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
		local tr_item = r.GetTrackMediaItem(tr,0) -- exploded items are the only ones of their tracks
			if tr_item then
			local take = r.GetActiveTake(r.GetTrackMediaItem(tr,0))
			local retval, notecnt, ccevtcnt, textsyxevtcnt = r.MIDI_CountEvts(take)
			local retval, name = r.GetTrackName(tr)
				if not t[tr] and name:match('chan') and notecnt > 0 then -- track wasn't stored so is new; it references channel # because meta-events are exploded as well and items contain notes because empty items with MIDI automation are exploded as well and they will disrupt re-ordering
				t2[#t2+1] = {tr=tr, idx=i}
				end
			end
		end
	return #t2 > 0 and t2
	end
end


local item = r.GetSelectedMediaItem(0,0)
local act_take = item and r.GetActiveTake(item)
local is_midi = act_take and r.TakeIsMIDI(act_take)
local retval, notecnt, ccevtcnt, textsyxevtcnt = table.unpack(is_midi and {r.MIDI_CountEvts(act_take)} or {})
local mess = not item and 'no selected item' or not is_midi and 'the take isn\'t MIDI' or notecnt == 0 and 'no notes in the midi take'
  if mess then Error_Tooltip('\n\n '..mess..' \n\n') return r.defer(function() do return end end) end

r.PreventUIRefresh(-1)

-- when MIDI channel filter is enabled in the MIDI take it won't be possile to get all the note data because MIDI_GetNote() in this case only targets notes in the current channel, check if this is the case and if so disable the filter temporarily
local enabled_ID, is_open = Clear_Restore_MIDI_Channel_Filter()

local t = {pitch=-1, chan=17} -- we'll sort for the highest pitch and the lowest channel number
local note_t = {t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t}
local channel = -1
	for i = 0, notecnt-1 do -- collect current notes properties
	local retval, sel, muted, startppq, endppq, chan, pitch, vel = r.MIDI_GetNote(act_take, i) -- only targets notes in the currently active channel if Channel filter is enabled, if looking for genuine false or 0 values must be validated with retval which is only true for notes from current channel
	channel = chan > channel and channel+1 or channel -- if channel ends up being 0 after loop all notes belong to the same MIDI channel so nothing to explode // they also will if Channel filter is enabled in the MIDI editor but this case if handled with Clear_Restore_MIDI_Channel_Filter() above
		if pitch > note_t[chan+1].pitch then -- +1 since chan value is 0-based
		note_t[chan+1] = {pitch=pitch, chan=chan+1}
		end
	end

	if channel == 0 then
	mess = '   all notes belong to the same \n\n MIDI channel, nothing to explode'
	Error_Tooltip('\n\n '..mess..' \n\n') return r.defer(function() do return end end) end

	if enabled_ID then Clear_Restore_MIDI_Channel_Filter(enabled_ID, is_open) end

r.Undo_BeginBlock()

local track_t = Find_And_Get_New_Tracks() -- store current
r.Main_OnCommand(40894, 0) -- Item: Explode multichannel audio or MIDI to new one-channel items
local track_t = Find_And_Get_New_Tracks(track_t) -- find and get new

table.sort(note_t, function(a,b) return a.chan < b.chan end) -- first sort by channel from low to high to mimic exploded track order

	for k, props in ipairs(track_t) do -- associate tracks with MIDI channels
--Msg(props_t[k].chan)
	local ch = note_t[k].chan ~= 17 and note_t[k].chan or -1 -- replace 17 with -1 to simplify double looping below
	track_t[k] = {tr=props.tr, idx=props.idx, chan=ch}
	end

table.sort(note_t, function(a,b) return a.pitch > b.pitch end) -- sort by pitch from high to low

local beforeTrackIdx = track_t[1].idx -- index of the first exploded track
local increment = 0
-- at each loop cycle the found track is moved up replacing the 1st track, then the 2nd and so on, and since as tracks accrue the index of the last moved track increases relative to the initial beforeTrackIdx value, it's adjusted with increment var
	for k1, note_props in ipairs(note_t) do -- tr_props.idx field isn't used because during loop indices change
	local ch1 = note_props.chan
		for k2, tr_props in ipairs(track_t) do
		local ch2 = tr_props.chan
		local tr = tr_props.tr
			if ch1 == ch2 then
			r.SetOnlyTrackSelected(tr)
			r.ReorderSelectedTracks(beforeTrackIdx+increment, 0) -- makePrevFolder arg for some reason doesn't work here, folder structure is maintained with makePrevFolder being 0 as well, probably because no track preceding beforeTrackIdx+increment happens to be the last in the folder, so taken another approach below
			increment = increment+1
			break end
		end
	end



	if #KEEP_FOLDER:gsub(' ','') == 0 then

	local first_tr = r.CSurf_TrackFromID(beforeTrackIdx, false) -- mcpView false // beforeTrackIdx refers to the 0-based index of the first exploded track, but this function inderprets index as 1-based (actual) and returns the folder parent track, the track the original item is on
	r.SetMediaTrackInfo_Value(first_tr, 'I_FOLDERDEPTH', 0) -- 0 normal

		for i = beforeTrackIdx, r.CountTracks(0)-1 do -- find and dismantle the last track in the folder // beforeTrackIdx+#track_t cannot be used because track with exploded items without notes aren't stored in the table so its length may be smaller than the actual number of exloded tracks
		local tr = r.GetTrack(0,i)
			if r.GetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH') < 0 then -- last track in the folder
			r.SetMediaTrackInfo_Value(tr, 'I_FOLDERDEPTH', 0) -- 0 normal
			break end
		end

	end

r.Undo_EndBlock('Explode multichannel MIDI to new one-channel items obeying keyboard note order',-1)
r.PreventUIRefresh(-1)





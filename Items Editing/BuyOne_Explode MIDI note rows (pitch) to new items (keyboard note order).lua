--[[
ReaScript name: Explode MIDI note rows (pitch) to new items (keyboard note order)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Added a setting to allow re-using tracks created in previous explosions
Licence: WTFPL
REAPER: at least v5.962
About: 	The native action 'Item: Explode MIDI note rows (pitch) to new items'
        explodes note rows from the low to the high and in the tracklist
        the exploded items end up in the order inverse to the vertical note order on
        the keyboard, which seems counterintuitive, so the script is an alternative.  
        https://forum.cockos.com/showthread.php?t=276685 
		
	The MIDI item must be selected and take be active in multi-take items.
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable the setting place any alphanumeric character between
-- the quotation marks.

-- The native action
-- 'Item: Explode MIDI note rows (pitch) to new items'
-- used by the script creates child tracks
-- under the track with the source MIDI item;
-- enable to keep this folder structure;
-- if empty, this folder structure will be dismantled;
-- the setting also applies when REUSE_TRACKS setting
-- is enabled below, if KEEP_FOLDER setting is enabled
-- and there was no folder after previous explosion(s),
-- it will be created, if KEEP_FOLDER setting is disabled
-- and there was a folder after previous explosion(s),
-- it will be dismantled
KEEP_FOLDER = "1"

-- Enable to place the newly created items
-- on tracks from previous explosions, if any,
-- PROVIDED the note names are retained in track labels
-- and their note names match
REUSE_TRACKS = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function sort_notes_by_name(t, wantReverse) -- wantReverse is boolean
local pat = '[%-%d]+'
table.sort(t, function(a,b) return a:match(pat) < b:match(pat) end) -- sort by octave
local oct = -10 -- a value lower than the lowest octave number to be able to detect the 1st lowest and so forth
local table_len = #t -- to be used in removing all separate note fields

-- STEP 1
	for _, v in ipairs(t) do -- store notes belonging to every octave in a separate nested table
	local str = type(v) == 'string' -- could be table because nested tables are being added during the loop
	-- outwitting sorting algo used below to make it place sharps later and flats earlier in the sequence, otherwise sharps are sorted to earlier slots because '#' precedes numerals in the character list while 'b' comes after numerals, numeral matter because in the note name they denote octave, so G#1 will precede G1 and E1 will precede Eb1
	local v = str and v:gsub('#','z') -- z follows numerals
	local v = str and v:gsub('b','!') -- ! precedes numerals
		if str and v:match(pat) > oct..'' then -- create a nested table and store first note name
		t[#t+1] = {v}
		oct = v:match(pat)
		elseif str and v:match(pat) == oct..'' then -- keep adding note names to the nested table while the octave is the same
		local len = #t[#t]
		t[#t][len+1] = v
		else break -- all strings have been removed, no point to continue
		end
	end

	for i = table_len, 1, -1 do -- remove all separate note fields
	table.remove(t,i)
	end

-- STEP 2
local table_len = #t -- to be used in removing all nested tables, there're fewer fields at this stage because their number is based on octaves
	for k, v in ipairs(t) do -- sort each octave alphabetically
		if type(v) == 'table' then -- could be string because note names are being added during the loop
		table.sort(v) -- sort nested table
			for i = 1, #v do
			local note = v[i]
				if note:match('A') or note:match('B') then -- move these notes to the end of the list
				v[#v+1] = note
				v[i] = '' -- mark for deletion, deletion during the loop ruins the table but moving and deleting while iterating in reverse doesn't produce the accurate result, A ends up following B because it follows it in reversed loop
				end
			end
			for i = #v,1,-1 do -- delete A and B placeholder fields if any
				if v[i] == '' then table.remove(v,i) end
			end

			for _, v in ipairs(v) do -- place nested table fields back to the main table in separate fields
			local v = v:gsub('z','#') -- restoring sharps and flats
			local v = v:gsub('!','b')
			t[#t+1] = v
			end
		else break -- all tables have been removed, no point to continue
		end
	end

-- STEP 3
	for i = table_len, 1, -1 do -- remove all nested tables
	table.remove(t,i)
	end

	if wantReverse then
		--[[ reverse table
		for i = #t,1,-1 do
		t[#t+1] = t[i]
		table.remove(t,i)
		end
		--]]
		--[-[ OR
		for k, v in ipairs(t) do
			if k > #t/2 then break end -- only run half the table length (rounded down half if the length is an odd number), otherwise the order will be restored
		local i = k-1
		t[k] = t[#t-i]
		t[#t-i] = v
		end
		--]]
	end

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

function Find_And_Get_New_Items(t)
	if not t then
	local t = {}
		for i = 0, r.CountMediaItems(0)-1 do
		t[r.GetMediaItem(0,i)] = '' -- dummy field
		end
	return t
	elseif t then
	local t2 = {}
		for i = 0, r.CountMediaItems(0)-1 do
		local itm = r.GetMediaItem(0,i)
			if not t[itm] then -- track wasn't stored so is new
			t2[#t2+1] = itm
			end
		end
	return #t2 > 0 and t2
	end
end


local item = r.GetSelectedMediaItem(0,0)
local act_take = item and r.GetActiveTake(item)
local is_midi = act_take and r.TakeIsMIDI(act_take)
local retval, notecnt, ccevtcnt, textsyxevtcnt = table.unpack(is_midi and {r.MIDI_CountEvts(act_take)} or {})

-- GENERATE ERROR MESSAGES

REUSE_TRACKS = #REUSE_TRACKS:gsub(' ','') > 0
local previosly_exploded
local s = ' '
local mess = not item and 'no selected item' or not is_midi and 'the take isn\'t MIDI' or notecnt == 0 and 'no notes in the midi take'

	if not mess then
	local patt = '%[[A-G]+[#b%-]*[0-9]+%]'
		for i = 0, r.CountSelectedMediaItems(0)-1 do
		local itm = r.GetSelectedMediaItem(0,i)
		local itm_tr = r.GetMediaItemTrack(itm)
		local ret, tr_name = r.GetTrackName(itm_tr)
			if tr_name:match(patt) then
			mess = '  Selected items are sitting\n\n'..s:rep(9)..'on tracks labeled\n\n'..s:rep(10)..'with note names.\n\n     The result of exploding\n\n'..s:rep(12)..'will be messy.\n\n'..s:rep(10)..'Moving the items\n\n to other tracks is advisable.' -- the native action will append new note names to the labels of the tracks from previous explosion(s) which is what is meant by 'messy'
			break end
			if REUSE_TRACKS then -- only relevant because in this case the items will be moved to tracks from previous explosion and may overlap items from previous explosion
			local itm_st = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
			local itm_end = itm_st + r.GetMediaItemInfo_Value(itm, 'D_LENGTH')
				for i = 0, r.GetNumTracks()-1 do -- traverse tracks looking for those created in previous explosions
				local tr = r.GetTrack(0,i)
				local ret, tr_name = r.GetTrackName(tr)
					if tr_name:match(patt) then
					previosly_exploded = not previosly_exploded and tr or previosly_exploded -- store first track from previous explosion
						for i = 0, r.GetTrackNumMediaItems(tr)-1 do -- traverse previously exploded items on such tracks
						local tr_itm = r.GetTrackMediaItem(tr,i)
						local tr_itm_st = r.GetMediaItemInfo_Value(tr_itm, 'D_POSITION')
						local tr_itm_end = tr_itm_st + r.GetMediaItemInfo_Value(tr_itm, 'D_LENGTH')
							if itm_st == tr_itm_st and itm_end == tr_itm_end

							or itm_st <= tr_itm_st and itm_end > tr_itm_st
							or itm_st < tr_itm_end and itm_end >= tr_itm_end
						--[[ OR
							if itm_st >= tr_itm_st and itm_st < tr_itm_end
							or itm_end > tr_itm_st and itm_end <= tr_itm_end
							]]
							then
							mess = 'After exploding selected items\n\n  will end up overlapping items\n\n'..s:rep(6)..'from previous exploding.\n\n'..s:rep(5)..'It\'s recommended to shift\n\n their position on the time line.'
							break end
						end
						if mess then break end
					end
				end
			end
		end
	end

	if mess then Error_Tooltip('\n\n '..mess..' \n\n') return r.defer(function() do return end end) end


-- START MAIN ROUTINE

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

KEEP_FOLDER = #KEEP_FOLDER:gsub(' ','') > 0

local tr_t = Find_And_Get_New_Tracks() -- store current
local itm_t = Find_And_Get_New_Items() -- store current

-- Simplify folder handling by always exploding from the track
-- immediately preceding the first one from previous explosion, if any
local sel_itm_tr_t = {}
local latest_itm_tr -- will be used for folder parent creation at the end of the routine if there happens to be none while KEEP_FOLDER setting is enabled
local start = math.huge*-1
	for i = 0, r.CountSelectedMediaItems(0)-1 do
	local itm = r.GetSelectedMediaItem(0,i)
	local itm_tr = r.GetMediaItemTrack(itm)
	local itm_start = r.GetMediaItemInfo_Value(itm, 'D_POSITION')
		if itm_start > start then latest_itm_tr = itm_tr; start = itm_start end -- find a selected item which is the farthest on the time line
	sel_itm_tr_t[#sel_itm_tr_t+1] = {itm=itm, tr=itm_tr}
	end

local trim_behind_ON = r.GetToggleCommandStateEx(0,41117) == 1 -- Options: Trim content behind media items when editing // since items will be moved to the 'launch' track below which may contain other items at the same position on the time line, ensure that this option is temporarily turned off to pevent trimming other items just in case EVEN THOUGH IT SEEMS TO ONLY HAVE EFFECT WHEN MOVING ITEMS WITH THE MOUSE

	if previosly_exploded and r.GetParentTrack(previosly_exploded) -- r.GetTrackDepth(previosly_exploded) > 0
	then
	local disable = trim_behind_ON and r.Main_OnCommand(41117,0) -- Options: Trim content behind media items when editing // set to OFF
	 -- move selected items to the track immediately preceding the first one from previous explosion
	local prev_tr_idx = r.CSurf_TrackToID(previosly_exploded, false)-1 -- mpcView false
	local prev_tr = r.CSurf_TrackFromID(prev_tr_idx, false) -- mpcView false
		for i = 0, r.CountSelectedMediaItems(0)-1 do
		r.MoveMediaItemToTrack(r.GetSelectedMediaItem(0,i), prev_tr)
		end
	-- flatten previously created folder, if any, when KEEP_FOLDER isn't enabled, folder from current explosion won't be created either
	local parent = r.GetParentTrack(previosly_exploded)
		if not KEEP_FOLDER and parent then r.SetMediaTrackInfo_Value(parent, 'I_FOLDERDEPTH', 0) end
	else -- move all selected items to the track of the first one so that all are exploded from the same track
	local dest_tr = sel_itm_tr_t[1].tr
		for _, data in ipairs(sel_itm_tr_t) do
		r.MoveMediaItemToTrack(data.itm, dest_tr)
		end
	end


r.Main_OnCommand(40920, 0) -- Item: Explode MIDI note rows (pitch) to new items

	-- restore selected items original location in case moved
	for _, data in ipairs(sel_itm_tr_t) do
	r.MoveMediaItemToTrack(data.itm, data.tr)
	end

local re_enable = trim_behind_ON and r.GetToggleCommandStateEx(0,41117) == 0 and r.Main_OnCommand(41117,0) -- Options: Trim content behind media items when editing // if was disabled above

local tr_t = Find_And_Get_New_Tracks(tr_t) -- find and get new (exploded)
local itm_t = Find_And_Get_New_Items(itm_t) -- find and get new (exploded)

	if tr_t then
	local makePrevFolder = KEEP_FOLDER and 2 or 0 -- if beforeTrackIdx follows last track in folder or a normal one
	local ref_idx = tr_t[#tr_t].idx+1 -- track which immediately follows the last new track, works even if there's none
	local decrement = 0
		for _, props in ipairs(tr_t) do
		r.SetOnlyTrackSelected(props.tr)
		r.ReorderSelectedTracks(ref_idx-decrement, makePrevFolder) -- beforeTrackIdx is ref_idx-decrement
		decrement = decrement+1 -- at each cycle decrease beforeTrackIdx because each track will have to be placed before the previous and travel less places
		end

-- accidentals notation REAPER uses for exploded item is Db, Eb, F#, G#, Bb
		if REUSE_TRACKS and previosly_exploded then

		r.PreventUIRefresh(1)

			-- Move newly exploded items to pre-existing tracks, if any, and their note names match
			for k, itm in pairs(itm_t) do
			local take = r.GetActiveTake(itm)
			local ret, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false) -- setNewValue false
			local note_itm = take_name:match('.+(%[.+%])') or take_name:match('%[.+%]') -- original take already did or didn't have a name
				for i = r.CountTracks(0)-1,0,-1 do -- in reverse since tracks will be getting deleted
				local tr = r.GetTrack(0,i)
				-- exclude tracks just created in search for any previously created for a particular note
				local tr_match
					for _, data in ipairs(tr_t) do
						if tr == data.tr then tr_match = 1 break end
					end
					if not tr_match then -- if not one of the tracks just created
					local ret, tr_name = r.GetTrackName(tr)
					local note_tr = tr_name:match('%[.+%]') -- only tracks which labeled with a note name in square brackets
						if note_itm == note_tr then
						local itm_tr = r.GetMediaItemTrack(itm)
						r.MoveMediaItemToTrack(itm, tr) -- no position adjustment is necessary
						break end
					end
				end
			end

			-- Delete newly created tracks which have ended up empty due to item movement, deletion within item loop above is inconvenient since after moving one item other items may still be on the track if several items were exploded at once
			for _, data in ipairs(tr_t) do
				if r.GetTrackNumMediaItems(data.tr) == 0 then r.DeleteTrack(data.tr) end
			end

		-- Now some newly created tracks may not fit within the existing sequence as a result of track deletion because they've been left above tracks from previous exploding provided the MIDI item sat at the same source track, and all the more so if there was a gap between the original source track and the latest one

		local note_names_t = {}
			for i = #tr_t,1,-1 do -- in reverse to be able to remove data of the newly created tracks deleted in the loop above
			local tr = tr_t[i].tr
				if r.ValidatePtr(tr, 'MediaTrack*') then -- wasn't deleted
				local ret, tr_name = r.GetTrackName(tr)
				note_names_t[#note_names_t+1] = tr_name
				else
				table.remove(tr_t,i) -- remove data of deleted tracks
				end
			end

			-- add to the table of just created tracks pre-existing tracks labeled with note names
			for i = 0, r.CountTracks(0)-1 do
			local tr = r.GetTrack(0,i)
			local stored
				for _, data in ipairs(tr_t) do
					if tr == data.tr then stored = 1 break end
				end
				if not stored then -- excluding tracks just created
				local ret, tr_name = r.GetTrackName(tr)
				local note_name = tr_name:match('%[.+%]') -- only note name in square brackets
					if note_name then tr_t[#tr_t+1] = {tr=tr, idx=i} -- index will be used for sorting
					note_names_t[#note_names_t+1] = note_name -- add name to the names table
					end
				end
			end

	table.sort(tr_t, function(a,b) return a.idx < b.idx end) -- sort tracks with note names by index to be able to find the last below
	sort_notes_by_name(note_names_t, wantReverse) -- wantReverse is false // the resulting order is from lowest to highest

		local ref_idx = tr_t[1].idx -- first labeled track
		local tr_first, tr_last
			for i = #note_names_t,1,-1 do
			local note = note_names_t[i]
				for _, data in ipairs(tr_t) do
				local ret, tr_name = r.GetTrackName(data.tr)
					if note == tr_name:match('%[.+%]') then
					r.SetOnlyTrackSelected(data.tr, true) -- selected true
					r.ReorderSelectedTracks(ref_idx, makePrevFolder) -- beforeTrackIdx is ref_idx
					--	if not KEEP_FOLDER then r.SetMediaTrackInfo_Value(data.tr, 'I_FOLDERDEPTH', 0) end
					ref_idx = ref_idx+1
					tr_first = i == #note_names_t and data.tr or tr_first -- only assign once
					tr_last = i == 1 and data.tr -- only assign at the end of the loop
					end
				end
			end
			if KEEP_FOLDER then
				if not r.GetParentTrack(tr_first) then -- if after sorting the tracks didn't end up as children under parent which may happen if there wasn't folder to begin with and the uppermost track from previous explosion didn't have to be moved
				r.SetOnlyTrackSelected(latest_itm_tr, true) -- selected true
				r.ReorderSelectedTracks(r.CSurf_TrackToID(tr_first, false)-1, 0) -- mcpView false
				r.SetMediaTrackInfo_Value(latest_itm_tr, 'I_FOLDERDEPTH', 1) -- make parent
				end
			r.SetMediaTrackInfo_Value(tr_last, 'I_FOLDERDEPTH', -1)  -- -1 is last in the folder of a single level; ensure that if KEEP_FOLDER setting is enabled, the folder is created after sotring if it didn't exist before, setting a track to be a parent isn't enough
			end


	r.PreventUIRefresh(-1)

	end -- REUSE_TRACKS block end

	r.Undo_EndBlock('Explode MIDI note rows (pitch) to new items (keyboard note order)',-1)
	r.PreventUIRefresh(-1)

	end




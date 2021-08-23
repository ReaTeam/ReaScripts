--[[
ReaScript name: Render each item in place separately
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main] .
About:

	#### G U I D E

	The script functions in 2 modes enabled with TRACKS_OR_ITEMS option in the USER SETTINGS below:  
	A) rendering each item separately B) rendering track stems

	▓ ▪ When TRACKS_OR_ITEMS option is set to 'items'

	Selected items are rendered when there's:  
	A) 1 selected item and no selected tracks  
	B) 1 selected track and more than 1 selected item, in which case only items are considered  
	C) more than 1 selected item and more than 1 selected track, a hybrid selection

	All items on selected tracks are rendered when there's:  
	A) 1 selected track and no selected items  
	B) 1 selected item and more than 1 selected tracks, in which case only tracks are considered  
	C) more than 1 selected track and more than 1 selected item, a hybrid selection

	If all selected items sit on selected tracks even if they don't comprise all items on such tracks,
	the selected tracks will be considered and not the selected items hence all items on such tracks
	will be rendered.

	If there's exactly 1 selected track and 1 selected item a prompt appears.

	The setup prevents rendering 1 item along with several tracks as well as 1 track along with several
	items to safeguard against accidental rendering since normally at least 1 item and 1 track are always
	selected.

	In order to still be able to render exactly 1 item along with several tracks (i.e. all items on
	several tracks), add to item selection another item on any such track thereby making the selection
	hybrid which is supported. Such other selected item on selected track won't affect the result since
	as mentioned above as long as track is selected all its items will be rendered regardless of whether
	any of them is selected or not.

	Conversely, to render exactly 1 track (i.e. all items on such track) along with a bunch of selected
	items elsewhere, add all items on such track to selection.

	Selected tracks with no items are ignored. Folders are rendered provided their parent track has selected
	empty items which encompass part of the folder contents.

	UNITE option in the USER SETTINGS below allows rendering cross-faded/overlapping or contiguous items
	as one item. For this to work all items which are meant to be rendered as one must be selected.

	After rendering source items are muted. If all items on a track were rendered, then source track is muted.
	
	Rendered item inherits the name of the source item to which 'PRE/POST' indication is appended; united
	item inherits name of the first of the several source items out of which it's comprised. If the source
	item doesn't have a name the rendered item is named 'RENDERED PRE/POST'.

	Render track inherits color of the source track and name of the source track (if any) to which
	'RENDERED pre/post' indication is appended.


	▓ ▪ When TRACKS_OR_ITEMS option is set to 'tracks'

	A track is rendered to a solid stem regardless of whether the track or its items are selected.

	Selected tracks with no items are ignored unless the're folder parents. Thus folders are rendered to full
	stems regardless of whether their parent track has any empty items. Folder parent track itself obviously
	must not have media items on it.
	
	After rendering the source track is muted.

	Rendered item is named with the source track name (if any), to which 'RENDERED PRE/POST' indication
	is appended.

	Render track inherits color of the source track and name of the source track (if any) to which
	'RENDERED pre/post' indication is appended (same as in 'items' mode).

	!!! DISCLAIMER: Full track stems REAPER renders natively much more efficiently with the actions:  
	*Track: Render tracks to mono/stereo/multichannel [post-fader] stem tracks (and mute originals)*  
	so this setting, although fully functional, is of little use, has been kept for completeness.


	▓ GLOBAL OPTIONS (affecting objects in both abovelisted modes)

	▪▪ TAIL

	TAIL is designed to allow rendering tail of track time domain effects (reverb/delay).

	If TAIL value isn't set or the setting is malformed it is ignored and instead the setting
	*'Default tail length: .. ms render tails when: Rendering stems for time selection via action'*
	at *'Preferences -> Audio -> Rendering'* will have effect if enabled.  
	If it's set and properly formatted and the said setting in REAPER Preferences is enabled as well
	their time values will be combined.

	In TRACKS_OR_ITEMS 'items' mode in order to render long tail of the very last item on the track,
	set the target value in seconds in the TAIL option. If gaps between other items happen to be shorter,
	their tails will only extend up to the next item. If there's no gap between items, tail isn't rendered.

	Take FX tail length setting at  
	*'Preferences -> Media -> Tail length when using Apply FX to items/Take FX tail length'*
	isn't relevant for rendering with this script. To preserve tail, TAIL option in the USER SETTINGS
	or *'Default tail length: .. ms render tails when: Rendering stems for time selection via action'*
	setting at *'Preferences -> Audio -> Rendering'* must be used.

	▪▪ MANAGE_SRC_TRACK

	MANAGE_SRC_TRACK option allows hiding from both TCP and MCP or deleting the source track after rendering.  
	Its setting only applies to a source track when either all of its individual items were rendered or the
	entire track was rendered to a single stem.


	▓ SOME USEFUL INFO

	Whether time domain take FX of one item are cut off by the next item depends on REAPER settings.  
	The behavior can be set to 'Items always mix' in 'Item mix behavior' menu EITHER in the next media item
	*'Media Item Properties'* dialogue (default shortcut F2) OR globally for project at
	*'Project settings -> Advanced tab'*.

	If time domain effects used in FX chains of items overlap it's pereferable to render full track stems
	instead of separate items.

	Rendering file format is defined at *'Project settings -> Media tab -> Format for Apply, Glue, Freeze etc'*.

	As already mentioned, REAPER rendering settings can be found at *'Preferences -> Audio -> Rendering'*.   
	If *'Limit Apply FX/render stems to real time'* setting is ON and all items on the track are being rendered,
	soloing the source track mutes playback of all items on the track bar the very first one while rendering
	which may be helpful.

	Something to be aware of is that when rendering is aborted with 'Cancel' button in the render dialogue
	the files whose rendering has been completed by that point aren't deleted and are kept in the folder
	at the render path even though they may not appear as items in REAPER.


	Licence: WTFPL
	REAPER: at least v5.962

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Pre-fader prints take properties, track FX and their automation, track
--   playback offset, pre-FX volume, pan, width and volume trim automation,
--   doesn't print track TCP volume, pan, width, mute settings and
--   their automation
-- Post-fader prints all of the above
-- FX returns aren't printed, instead sends and receives are retained in
--   the render track
-- Insert appropriate setting between the quotation marks.
-- Try to not leave empty spaces.
-- Fall-back settings in case the entry is malformed or not set:
-- TRACKS_OR_ITEMS - items; FADER - post; CHAN - stereo; MANAGE - no action

local TRACKS_OR_ITEMS = "items" -- tracks or items // empty = items
local FADER = "post" -- pre or post // empty = post
local CHAN = "stereo" -- mono, stereo or multi // empty = stereo
local TAIL = "" -- include delay|reverb tail // number in seconds (fractionals are supported) or leave empty
local UNITE = "1" -- render cross-faded|overlapping or contiguous items as one // any alphanumeric character or leave empty
local MANAGE_SRC_TRACK = "" -- hide, del or leave empty // only if all items on track were rendered

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap)
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

local function no_undo() end


local function ACT(comm_ID) -- both string and integer work
r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end

local sett = {
		pre = {
		mono = 41721, -- Track: Render selected area of tracks to mono stem tracks (and mute originals)
		stereo = 41719, -- Track: Render selected area of tracks to stereo stem tracks (and mute originals)
		multi = 41720 -- Track: Render selected area of tracks to multichannel stem tracks (and mute originals)
		},
		post = {
		mono = 41718, -- Track: Render selected area of tracks to mono post-fader stem tracks (and mute originals)
		stereo = 41716, -- Track: Render selected area of tracks to stereo post-fader stem tracks (and mute originals)
		multi = 41717 -- Track: Render selected area of tracks to multichannel post-fader stem tracks (and mute originals)
		},
		{'', -- no action
		hide = 41593, -- Track: Hide tracks in TCP and mixer
		del = 40005 -- Track: Remove tracks
		}
	}


local TAIL = tonumber(TAIL)
local TAIL = TAIL and TAIL < 0 and TAIL*-1 or TAIL -- avoid negative values
local UNITE = UNITE:gsub(' ', '') ~= ''
-- get rid of empty spaces if any
local FADER = FADER:gsub(' ','')
local CHAN = CHAN:gsub(' ','')
local MANAGE_SRC_TRACK = MANAGE_SRC_TRACK:gsub(' ','')
-- define fallback settings in case user entry is incorrect
local FADER = (not (FADER == 'pre' or FADER == 'post') or #FADER == 0) and 'post' or FADER -- fallback is post
local CHAN = (not (CHAN == 'mono' or CHAN == 'stereo' or CHAN == 'multi') or #CHAN == 0) and 'stereo' or CHAN -- fallback is stereo
local MANAGE_SRC_TRACK = (not (MANAGE_SRC_TRACK == 'hide' or MANAGE_SRC_TRACK == 'del') or #MANAGE_SRC_TRACK == 0) and 1 or MANAGE_SRC_TRACK -- fallback is no action
local TRACKS_OR_ITEMS = (not (TRACKS_OR_ITEMS == 'items' or TRACKS_OR_ITEMS == 'tracks') or #TRACKS_OR_ITEMS == 0) and 'items' or TRACKS_OR_ITEMS


local function StoreSelectedObjects()

-- Store selected items
local sel_itms_cnt = r.CountSelectedMediaItems(0)
local itm_sel_t = {}
	if sel_itms_cnt > 0 then
	local i = 0
		while i < sel_itms_cnt do
		itm_sel_t[#itm_sel_t+1] = r.GetSelectedMediaItem(0,i)
		i = i+1
		end
	end

-- Store selected tracks
local sel_trk_cnt = reaper.CountSelectedTracks2(0,1) -- plus Master
local trk_sel_t = {}
	if sel_trk_cnt > 0 then
	local i = 0
		while i < sel_trk_cnt do
		trk_sel_t[#trk_sel_t+1] = r.GetSelectedTrack2(0,i,1) -- plus Master
		i = i+1
		end
	end
return itm_sel_t, trk_sel_t
end


local function RestoreSavedSelectedObjects(itm_sel_t, trk_sel_t)
-- selection state is restored if objects both were and weren't selected

r.Main_OnCommand(40289,0) -- Item: Unselect all items
	if #itm_sel_t > 0 then
	local i = 0
		while i < #itm_sel_t do
		r.SetMediaItemSelected(itm_sel_t[i+1],1)
		i = i + 1
		end
	end

r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
r.SetTrackSelected(r.GetMasterTrack(0),0) -- unselect Master
	if #trk_sel_t > 0 then
		for _,v in next, trk_sel_t do
		r.SetTrackSelected(v,1)
		end
	end

r.UpdateArrange()
r.TrackList_AdjustWindows(0)
end


local function count_track_sel_items(tr, tr_itm_cnt)
local counter = 0
	for i = 0, tr_itm_cnt-1 do
	local item = r.GetTrackMediaItem(tr, i)
		if r.IsMediaItemSelected(item) then counter = counter+1 end
	end
	return counter
end


local sel_trk_cnt = r.CountSelectedTracks(0)
local sel_itm_cnt = r.CountSelectedMediaItems(0)

	if sel_itm_cnt + sel_trk_cnt == 0 then err = 'No selected objects.'
	elseif sel_trk_cnt > 0 and sel_itm_cnt == 0 then -- count items on selected tracks
	local itm_cnt = 0
	local fldr_cnt = 0
		for i = 0, r.CountSelectedTracks(0)-1 do
		local tr = r.GetSelectedTrack(0,i)
		itm_cnt = itm_cnt + r.CountTrackMediaItems(tr)
		fldr_cnt = ({r.GetTrackState(tr)})[2]&1 == 1 and fldr_cnt + 1 or fldr_cnt
		end
		if itm_cnt == 0 and TRACKS_OR_ITEMS ~= 'tracks' then err = 'No items on selected tracks.'
		elseif itm_cnt + fldr_cnt == 0 and TRACKS_OR_ITEMS == 'tracks' then err = '    No items on selected tracks\n\nand no selected track is a folder.'
		end
	end
	if err then r.MB(err,'ERROR',0) return r.defer(no_undo) end

	if sel_itm_cnt == 1 and sel_trk_cnt == 1 and TRACKS_OR_ITEMS ~= 'tracks' then
	resp = r.MB('  Exactly one item and one track are selected.\n\n "YES\" - to render item   \"NO\" - to render track.\n\n    If you wish to render both, click  \"CANCEL\"\n\n         and select all items on selected track.','PROMPT',3)
		if resp == 2 then return r.defer(no_undo) end
	end


local items, tracks = StoreSelectedObjects()


local only_itms = sel_trk_cnt < 2 and sel_itm_cnt > 1 or sel_trk_cnt == 0 and sel_itm_cnt >= 1
local only_trks = sel_itm_cnt < 2 and sel_trk_cnt > 1 or sel_itm_cnt == 0 and sel_trk_cnt >= 1
local hybrid_sel = sel_itm_cnt >= 2 and sel_trk_cnt >= 2
local items_cond = only_itms or hybrid_sel or resp == 6 or TRACKS_OR_ITEMS == 'tracks'
local tracks_cond = only_trks or hybrid_sel or resp == 7 or TRACKS_OR_ITEMS == 'tracks'


local function Get_Folder_Rightmost_Item_RightEdge(tr)

local is_folder = ({r.GetTrackState(tr)})[2]&1 == 1
local par_tr_depth = r.GetTrackDepth(tr)
local idx = r.CSurf_TrackToID(tr, false)
local rightmost_itm_r_edge = 0
	if is_folder then
		for i = idx, r.CountTracks(0)-1 do
		local tr = r.GetTrack(0,i) -- next track after folder parent/1st child track
		local tr_depth = r.GetTrackDepth(tr)
			if tr_depth <= par_tr_depth or tr_depth == 0 then break end -- either the same or higher nested level within higher level folder or a regular track (outside of the folder)
		local tr_item_cnt = r.CountTrackMediaItems(tr)
			if tr_item_cnt > 0 then
			local tr_last_itm = r.GetTrackMediaItem(tr, r.CountTrackMediaItems(tr)-1)
			local tr_last_itm_r_edge = r.GetMediaItemInfo_Value(tr_last_itm, 'D_POSITION') + r.GetMediaItemInfo_Value(tr_last_itm, 'D_LENGTH')
			rightmost_itm_r_edge = tr_last_itm_r_edge > rightmost_itm_r_edge and tr_last_itm_r_edge or rightmost_itm_r_edge
			end
		end
	end

return rightmost_itm_r_edge

end

local t = {}

	for i = 0, r.CSurf_NumTracks(false)-1 do -- mcpView is false
	local tr = r.GetTrack(0,i)
	local track_sel = r.IsTrackSelected(tr)
	local is_folder = ({r.GetTrackState(tr)})[2]&1 == 1
	local tr_itm_cnt = r.CountTrackMediaItems(tr)
	local tr_sel_itm_cnt = count_track_sel_items(tr, tr_itm_cnt)
		if track_sel and (tr_itm_cnt > 0 or is_folder) and tracks_cond -- to avoid creating an empty track nested table skip selected track with no selected items unless either other tracks are selected or no items are selected or dialogue response equals 7 (render track), i.e. only consider selected track if there're either other tracks selected or no items selected (covered by only_trks and hybrid_sel conditions) or dialogue response equals 7 (render track); do not store tracks with no items unless they're folders which is relevant for when TRACKS_OR_ITEMS is set to 'tracks'
		or tr_sel_itm_cnt > 0 and items_cond -- same rationale, only allow creating nested table when either besides track selected items other items are selected or no tracks are selected or dialogue response equals 6 or TRACKS_OR_ITEMS is set to 'tracks'
		then
		t[tr] = {} -- save tracks as pointers since their index will change as render tracks are created
		t[tr].tr_mute = false
			if tr_itm_cnt == tr_sel_itm_cnt or only_trks or resp == 7 or hybrid_sel and track_sel then
			t[tr].tr_mute = true -- to evaluate later for muting track if all or none of its items are selected
			end
			for j = 0, tr_itm_cnt-1 do
			local item = r.GetTrackMediaItem(tr, j)
			local item_sel = r.IsMediaItemSelected(item)
				if track_sel and tracks_cond then -- collect all track items if track is selected under the listed conditions
				t[tr][#t[tr]+1] = j -- could be a dummy value as index suffices
				elseif item_sel and items_cond then -- collect all selected items on track if it itself is not selected under the listed conditions
				t[tr][#t[tr]+1] = j -- same
				end
			end
		end
	end


	

------ MAIN ROUTINE START ------


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local rend_trks_t = {}

	for k, v in pairs(t) do -- traverse tracks
	local counter = 0 -- to conditon deletion of redundant render tracks within items render loop below
	ACT(40297) -- Track: Unselect all tracks // not really necessary
	r.SetOnlyTrackSelected(k)
	local _, tr_name = r.GetTrackName(k)
	local tr_itm_cnt = r.CountTrackMediaItems(k)
	local is_folder = ({r.GetTrackState(k)})[2]&1 == 1
	local tr_name = tr_name:match('Track %d*') and '' or tr_name..' - ' -- if generic name because the track isn't named, discard
	local color = r.GetMediaTrackInfo_Value(k, 'I_CUSTOMCOLOR')
		-- RENDER FULL TRACK STEMS --
		if TRACKS_OR_ITEMS == 'tracks' then
		r.SetOnlyTrackSelected(k)
		local tr_itm_cnt = r.CountTrackMediaItems(k)
		-- use the same actions and only extend time selection if TAIL
		ACT(40289) -- Item: Unselect all items
		ACT(40421) -- Item: Select all items in track
		ACT(40290) -- Time selection: Set time selection to items
		local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- GET // isSet, isLoop, start, end, allowautoseek
		local fin = is_folder and Get_Folder_Rightmost_Item_RightEdge(k) or fin -- if folder, extend time selection to the right edge of the last item therein
		local start, fin = r.GetSet_LoopTimeRange(true, false, 0, fin, false) -- SET
			if TAIL then
			r.GetSet_LoopTimeRange(true, false, start, fin + TAIL, false) -- extend time selection by TAIL value
			end
		ACT(sett[FADER][CHAN])
		------------ Abort when aborted by the user --------------
		if r.IsTrackSelected(k) then -- when render is aborted by the user via render dialogue the source track stays selected which is used as condition to stop the script, otherwise when rendering runs its course completely render track ends up being selected
		ACT(40635) -- Time selection: Remove time selection
		RestoreSavedSelectedObjects(items, tracks)
		return r.defer(no_undo) end
		----------------------------------------------------------
		-- store render track irrespective of its selection
		rend_tr = r.CSurf_TrackToID(r.GetSelectedTrack(0,0), false) -- global to be used below in item naming routine
		rend_tr = r.GetTrack(0, rend_tr-1)
		r.GetSetMediaItemTakeInfo_String(r.GetActiveTake(r.GetTrackMediaItem(rend_tr,0)), 'P_NAME', tr_name..'RENDERED '..FADER:upper(), 1) -- rename rendered item
		else -- TRACKS_OR_ITEMS is set to 'items' or empty
		local take_name_t = {}
			-- RENDER ITEMS --
			for key, it_idx in ipairs(v) do -- traverse track items
			local unite
				if key ~= 'tr_mute'	then
				ACT(40289) -- Item: Unselect all items
				local item = r.GetTrackMediaItem(k, it_idx)
				local take = r.GetActiveTake(item)
				local take_name = take and select(2,r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', 0)) or 'RENDERED' -- GET
				take_name_t[#take_name_t+1] = take_name
				r.SetMediaItemSelected(item, true)
				ACT(40290) -- Time selection: Set time selection to items
				-------------------------------------------------------------------
					if UNITE then -- render cross-faded/overlapping or contiguous selected items together
					local item = r.GetTrackMediaItem(k, it_idx)
					local next_itm = v[key+1] and r.GetTrackMediaItem(k, v[key+1]) -- safeguard against error in cases where only single item is selected and UNITE is ON in which case the table will only contain a single item entry
					local r_edge = r.GetMediaItemInfo_Value(item, 'D_POSITION') + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
					local pos_next = next_itm and r.GetMediaItemInfo_Value(next_itm, 'D_POSITION') or r_edge + 1 -- the 'or' alternative is there to prevent next 'if' conditions being true in case next item is not contiguous/cross-faded/overlapping with the first one
						if r_edge == pos_next or r_edge > pos_next then -- if contiguous or cross-faded/overlapping
						r.SetMediaItemSelected(next_itm, true) -- select the 2nd of items to be rendered together
						ACT(40290) -- Time selection: Set time selection to items
						unite = 1 -- set true for evaluation below
						end
					end
				-------------------------------------------------------------------
					if TAIL then -- extend time selection rightwards to the nearest item
					local next_itm = unite and r.GetTrackMediaItem(k, it_idx+2) or not unite and r.GetTrackMediaItem(k, it_idx+1) -- if unite skip to 1 item ahead else go to the next
					local pos_next = next_itm and r.GetMediaItemInfo_Value(next_itm, 'D_POSITION') -- get pos of the next item
					local start, fin = r.GetSet_LoopTimeRange(false, false, 0, 0, false) -- isSet, isLoop, start, end, allowautoseek // item time selection params
					local fin_new = pos_next and fin + TAIL >= pos_next and pos_next or fin + TAIL -- if last item extend time sel by 8 sec
					r.GetSet_LoopTimeRange(true, false, start, fin_new, false)
					end
				ACT(sett[FADER][CHAN]) -- Track: Render selected area of tracks to [depends on user settings] stem tracks (and mute originals) // item selection sticks, track selection changes to the one with rendered item placed above the original
					------------ Abort when aborted by the user --------------
					if r.IsTrackSelected(k) then -- when render is aborted by the user via render dialogue the source track stays selected which is used as condition to stop the script, otherwise when rendering runs its course completely render track ends up being selected
					ACT(40635) -- Time selection: Remove time selection
					RestoreSavedSelectedObjects(items, tracks)
					return r.defer(no_undo) end
					----------------------------------------------------------
					if counter == 0 then -- name render track after the source track, only the 1st one which becomes the only one as all subsequent are deleted
					-- store render track irrespective of its selection
					rend_tr = r.CSurf_TrackToID(r.GetSelectedTrack(0,0), false) -- global to be used below in item naming routine
					rend_tr = r.GetTrack(0, rend_tr-1)
					local tr_name = tr_name:match('Track %d*') and '' or tr_name..' - ' -- if generic name because the track isn't named, discard
					end
					if not t[k].tr_mute then
					r.SetMediaItemInfo_Value(item, 'B_MUTE', 1) -- mute individual source item instead of the source track if not all track items are rendered
					local mute = unite and r.SetMediaItemInfo_Value(r.GetTrackMediaItem(k, v[key+1]), 'B_MUTE', 1) -- mute adjacent item rendered along with the previous
					end
					if counter > 0 then -- move each rendered item after the 1st to the same render track and delete secondary render track
					ACT(40289) -- Item: Unselect all items
					ACT(40718) -- Item: Select all items on selected tracks in current time selection
					ACT(40117) -- Item edit: Move items/envelope points up one track/a bit
					ACT(40005) -- Track: Remove tracks
					end
				r.SetOnlyTrackSelected(k) -- re-select source track
				ACT(40731) -- Track: Unmute tracks // to coninue rendering other items
				counter = counter + 1
				local rem = unite and v[key+1] and table.remove(v, key+1) -- remove from the table an adjacent item rendered along with the previous
				local rem = unite and take_name_t[key+1] and table.remove(take_name_t, key+1) -- mirror the removal in the item names table
				end -- key ~= 'tr_mute' cond end
			-- name rendered items after the originals
				for i = 0, r.CountTrackMediaItems(rend_tr)-1 do
				local item = r.GetTrackMediaItem(rend_tr, i)
				local take = r.GetActiveTake(item)
				local set = take_name_t[i+1] and r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', take_name_t[i+1]..' '..FADER:upper(), 1) -- rename rendered item
				end

			end -- render item loop end

		end -- TRACKS OR ITEMS cond end

	-- name and color render track
	r.GetSetMediaTrackInfo_String(rend_tr, 'P_NAME', tr_name..'RENDERED '..FADER, 1) -- name render track
	r.SetMediaTrackInfo_Value(rend_tr, 'I_CUSTOMCOLOR', color) -- inherit color from the source track

	rend_trks_t[#rend_trks_t+1] = rend_tr -- store pointers of render tracks

		if TRACKS_OR_ITEMS ~= 'tracks' and t[k].tr_mute and not is_folder -- last cond is to ignore muting selected source track when TRACKS_OR_ITEMS is set to items and the track is a folder, because in this case it's not rendered
		or TRACKS_OR_ITEMS == 'tracks' then
		r.SetMediaTrackInfo_Value(k, 'B_MUTE', 1)
		r.SetOnlyTrackSelected(k)
		ACT(sett[1][MANAGE_SRC_TRACK]) -- hide or delete track or leave as is
		end
	end

ACT(40635) -- Time selection: Remove time selection

-- get render path
local rend_itm = r.GetTrackMediaItem(rend_trks_t[1], 0)
local rend_path = r.GetMediaSourceFileName(r.GetMediaItemTake_Source(r.GetActiveTake(rend_itm)), ''):match('^(.+[\\/])')

local proj_name = r.GetProjectName(0, ''):match('^(.+)%.%w+$') -- get rid of .RPP extension in the name

-- get index (the greatest) of the last rendered file whose name pattern follows the one set in this script (track name (if any)_rendered-index.extension)
local index = 0
local i = 0
	repeat
	local f = r.EnumerateFiles(rend_path, i)
	local f_idx = f and f:match('.*rendered%-(%d*)%.%w+$')
	local f_idx = tonumber(f_idx)
		if f_idx and f_idx > index then index = f_idx end
	i = i + 1
	until not f or f == ''

local index = index + 1 -- increment

	-- rename rendered media files // REAPER ONLY MAINTAINS NUMBERING OF RENDERED ITEM FILES IF THEY FOLLOW SPECIFIC PATTERN (project name_stems_track name (if any)-00X.extension), IF THE FILES ARE RENAMED THE NUMBERING RESETS AND YOU END UP OVEWRITING EARLIER RENAMED FILES BEARING THE SAME NUMBERS AS NEW RENDERED FILES // within the main rendering loop this routine glitches sometimes producing items with extended section as the one which happens after extending item with loop source turned off and no active section, therefore had to be made extraneous
	for _, v in ipairs(rend_trks_t) do
	local _, tr_name = r.GetTrackName(v)
	local tr_name = tr_name:match('^(.-)[%-%s]*RENDERED')
		for i = 0, r.CountTrackMediaItems(v)-1 do
		local item = r.GetTrackMediaItem(v, i)
		-- seems that placing this sequence here insetead of immediately before os.rename()
		-- helps avoiding renaming glitch where due to failure items are left empty without sources
		-- while the rendered files which weren't renamed are locked as if opened in REAPER
		-- if the ussue re-emerges it's worth trying to set items off- and back online in separate loops
		ACT(40289) -- Item: Unselect all items
		r.SetMediaItemSelected(item, true)
		ACT(40440) -- Item: Set selected media temporarily offline
		------------------------------------------------------
		local take = r.GetActiveTake(item)
		local old_fn = r.GetMediaSourceFileName(r.GetMediaItemTake_Source(take), '')
		local f_path, f_name = old_fn:match('^(.+[\\/])([^\\/]+)$') -- isolate file path and name
		local tr_name = #tr_name > 0 and tr_name..'_' or ''
		local f_idx = tostring(index)
		local f_idx = #f_idx == 1 and '-00'..f_idx or #f_idx == 2 and '-0'..f_idx or '-'..f_idx  -- add leading zeros
		local new_fn = f_path..tr_name..'rendered'..f_idx..f_name:match('%.%w+$') -- last is extension
		local ok, message = os.rename(old_fn, new_fn)
		local new_src = r.PCM_Source_CreateFromFile(new_fn)
		r.SetMediaItemTake_Source(take, new_src) -- assign the renamed file as a source
		ACT(40439) -- Item: Set selected media online
		index = index + 1
		local ok, message = #r.GetPeakFileName(f_path..f_name, '') > 0 and os.remove(r.GetPeakFileName(f_path..f_name, '')) -- remove lingering peak files with old file names; may leave lone non-deleted peak files if placed in the middle of the routine, could be because the source file is valid until renamed
		end
	end


-- concatenate undo point name
local undo = 'Render selected '
local undo = (only_itms and TRACKS_OR_ITEMS ~= 'tracks') and undo..'items' or (hybrid_sel and TRACKS_OR_ITEMS ~= 'tracks') and undo..'items and tracks' or undo..'tracks'


r.Undo_EndBlock(undo, -1)
r.PreventUIRefresh(-1)





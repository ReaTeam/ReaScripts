--[[
ReaScript name: Ripple edit per track when selected item length changes
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.2
Changelog: #Added a tooltip warning when script is started without Ripple per track being enabled.	    
Licence: WTFPL
REAPER: at least v5.962
Screenshots: https://git.io/JSTkE
About:	An enhancement to 'Ripple edit per track' mode. 
		As such only works when this mode is enabled. 
		Makes all items following the one whose length 
		is being changed move just like what regular 
		Ripple edit does when selected items are shifted. 
		This functionality exists in ProTools' 'Shuffle' 
		edit mode: https://youtu.be/O_jZujPzxyI?t=161  

		The script demo: https://git.io/JSTkE  
		
		The item whose length is being changed MUST BE SELECTED, 
		otherwise no change occurs in items positioning unless 
		RETROSPECTIVE_RIPPLE_EDIT option is enabled in the USER SETTINGS.

		Envelopes and automation items are moved just as they 
		are in regular Ripple edit mode as long as the option 
		'Move envelope points with media items and razor edits' 
		is enabled in REAPER and MOVE_AUTOMATION setting is enabled 
		in the USER SETTINGS below.

		The behavior this scripts attempts to reproduce can also 
		be achieved with custom actions the code of which is provided 
		at the bottom of this file, with the only difference that the 
		resolution of item length change is to the closest grid line, 
		but it can be changed to pixels by replacing the actions 
		'View: Move cursor rigt/left to grid division' with 
		'View: Move cursor right/left one/8 pixels'.
		
		While the script is running, only 1 media item can be selected
		at a time. If several media items are selected, all but the 1st 
		one are auto-deselected. To be able to select multiple items 
		either stop the script or disable 'Ripple edit per track'.
		
		When the script is stopped the first time, in the 'ReaScript
		task control dialogue' tick 'Remember my answer for this script'
		checkbox and click 'Terminate instances'.

		CAVEATS:

		Do not drag the right edge fast because the data won't 
		be processed as fast and item positions will end up being 
		messed up.

		Avoid dragging item right edge over following items.

		It may be difficult to control the pace/amount of the media item length 
		change done by dragging its left edge when grid is enabled. In the 
		script a short lag is introduced to mitigate this behavior but 
		it's not perfect, so the media item may end up somewhat overextended 
		or overshortened.

		If the media item inadvertently becomes deselected while its length 
		is being changed by dragging its left edge, ripple edit will only 
		take effect after the item is re-selected and only if it's 
		the first one to be selected provided RETROSPECTIVE_RIPPLE_EDIT option 
		is enabled. If another item is selected instead, items positions 
		won't update.   
		Which is in line with the general functionality RETROSPECTIVE_RIPPLE_EDIT
		is designed to provide (for details see USER SETTINGS).

		Minimum length of an automation item within the edited media item 
		boundaries is 101 ms. Shorter automation items are auto-deleted.

		Automation item(s) and the media item(s) cannot be selected 
		at the same time. To be able to select automation item(s) on the track 
		de-select all media items.
		
		When undoing multiple undo points left by this script you may encounter
		overlapping automation items. This is an intermediary stage which gets
		saved in the undo history in between the action start and end points. 
		Simply continue undoing.
				
		Since by this script splitting a media item is treated as its length change
		resulting in shift of the automation and media items located downstream, 
		in order to split without affecting objects pisitioning you may use a custom 
		action in which the split action (there're quite a few) is wrapped between 
		two Ripple edit actions like so:   
		Set ripple editing off   
		-- Split action --   
		Set ripple editing per-track  
		
		Alternatively manually turn off Ripple edit mode before splitting.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting other than LEFT_EDGE_CHANGE_LAG insert any alphanumeric
-- character between the quotation marks, to disable - remove everything from
-- between the quotation marks.

-- 1)
-- Ripple edit when item length changes on the right (right edge is dragged)
RIGHT_EDGE_CHANGE = "1"

-- 2)
-- Ripple edit when item length changes on the left (left edge is dragged)
-- it's advised to drag left edge by discrete rather than continuous movements
-- each time waiting until item position is updated, which takes a split second;
-- for a more precise change, have grid enabled and zoomed in and let go of the
-- media item left edge as soon as the next/previous grid line is reached;
-- the media item is likely to be overextended or overshortened by additional grid
-- division if its left edge is held longer;
-- be aware that with snapping disabled to move left edge by small increments
-- a mouse modifier should still be applied to override snapping because it doesn't
-- get disabled completely as of build 6.41:
-- https://forum.cockos.com/showthread.php?p=2491452#post2491452
LEFT_EDGE_CHANGE = "1"

-- 3)
-- see CAVEATS section in the About tag above;
-- meaningful values are in hundreds of milliseconds,
-- values in between hundreds aren't likely to make a noticeable difference;
-- 300 seems to be the smallest reasonable value;
-- if no value between the quotation marks, defaults to 300 ms
LEFT_EDGE_CHANGE_LAG = "300"

-- 4)
-- Ripple edit AFTER selecting the item whose length has changed,
-- (see demo at the link provided in the 'Screenshots' tag above);
-- could be useful to avoid the risk of disturbing items alignment while
-- dragging and of overextending or overshortening the item by dragging
-- its LEFT edge;
-- to use do the following:
-- A) deselect ALL items B) change the item's length C) re-select the item;
-- in this case ripple edit occurs in one go instead of being incremental and gradual;
-- !!!!!! for this to work the edited item must be the last selected before
-- deselecting all and the first one selected afterwards; !!!!!!
-- while this option is ON, to prevent ripple taking effect after changing the
-- length of the item, select another item instead and only then select the one
-- which has been edited;
-- If not enabled, items positioning will only update in real time and as long
-- as the item whose length is being changed remains selected
RETROSPECTIVE_RIPPLE_EDIT = "1"

-- 5)
-- Mainly relevant when LEFT_EDGE_CHANGE option is enabled above
-- because in this mode there's less control over the pace of media item length
-- change and a risk of its excessive shortening to the point of being
-- barely visible on the timeline;
-- the option sets media item minimum length to the grid division,
-- if it's enabled and you need the media item to get shorter than the current
-- grid allows, make the grid finer
PREVENT_EXTREME_SHORTENING = "1"

-- 6)
-- only relevant when the option
-- 'Move envelope points with media items and razor edits'
-- is enabled in REAPER, and if the said option is disabled,
-- automation won't move regardless of this setting;
-- if you run into glitches in movement of automation items when
-- snapping is enabled, undo, disable snapping and retry,
-- if edit is successful, re-enable snapping to continue;
-- when the media item is trimmed from the left, the autom item
-- aligned with its start may get shorter than its expected length
-- by under 1 ms
MOVE_AUTOMATION_ENVELOPES = "1"
MOVE_AUTOMATION_ITEMS = "1"

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


	if r.GetToggleCommandStateEx(0,41990) ~= 1 -- Toggle ripple editing per-track
	then
	local x, y = r.GetMousePosition()
	r.TrackCtl_SetToolTip(('\n\n           ripple edit per track is disabled.  \n\n the script will run but won\'t affect items  \n\n                until ripple edit is enabled. \n\n '):upper(), x, y, true) -- topmost	true
	end

-- removes spaces for settings evaluation
function is_set(sett) -- sett is a string
return #sett:gsub(' ','') > 0
end


function Grid_Div_Dur_In_Sec()
local retval, div, swingmode, swingamt = r.GetSetProjectGrid(0, false, 0, 0, 0) -- proj is 0, set is false, division, swingmode & swingamt are 0 (disabled for the purpose of fetching the data)
--local convers_t = {[0.015625] = 0.0625, [0.03125] = 0.125, [0.0625] = 0.25, [0.125] = 0.5, [0.25] = 1, [0.5] = 2, [1] = 4} -- number of quarter notes in grid division; conversion from div value
--return grid_div_time = 60/r.Master_GetTempo()*convers_t[div] -- duration of 1 grid division in sec
-- OR
return 60/r.Master_GetTempo()*div/0.25 -- duration of 1 grid division in sec; 0.25 corresponds to a quarter note as per GetSetProjectGrid()
end


function Store_Move_Automation(item, item_start, item_start_init, item_end, item_end_init, t)

	local function Delete_AutomItem(len, item, env, autoitem_idx)
	--	if len <= 0.1 then -- minimum length allowed when set programmatically or via input
	-- https://forum.cockos.com/showpost.php?p=2239082&postcount=9 thanks to X-Raym for the tip
		r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_UISEL', 1, true) -- value 1 (select), ise_set true
		r.Main_OnCommand(42086,0) -- Envelope: Delete automation items
	--	r.SetMediaItemSelected(item, true) -- re-select media item
	--	end
	end

	local function Split_AutomItem(item, item_start_init, env, autoitem_idx)
	r.PreventUIRefresh(1)
	local cur_pos = r.GetCursorPosition() -- store current edit cur pos
	r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_UISEL', 1, true) -- value 1 (select), ise_set true
	r.SetEditCurPos(item_start_init, false, false) -- restore edit cur pos // moveview & seekplay false
	r.Main_OnCommand(42087,0) -- Envelope: Split automation items
	r.GetSetAutomationItemInfo(env, autoitem_idx+1, 'D_UISEL', 0, true) -- unselect to prevent deletion when media item length is being changed // autoitem_idx+1 is righthand part of the split being a new autom item, value 0 (unselect), ise_set true
	r.SetEditCurPos(cur_pos, false, false) -- restore edit cur pos // moveview & seekplay false
	r.SetMediaItemSelected(item, true) -- re-select media item
	r.PreventUIRefresh(-1)
	end

	function UnTrim_AutomItem_LeftEdge(env, autoitem_idx, val) -- rather mimics trim by shifting contents, changing length and position
	-- val in sec, positive val trim [->, negative val untrim <-[
		if not env or not autoitem_idx or not val then return end
	local props = {['D_POSITION'] = 0, ['D_LENGTH'] = 0, ['D_STARTOFFS'] = 0, ['D_PLAYRATE'] = 0}
		for k in pairs(props) do
		props[k] = r.GetSetAutomationItemInfo(env, autoitem_idx, k, -1, false)
		end
		for k, v in pairs(props) do
			if props.D_LENGTH <= val then return end -- don't apply if AI is too short, otherwise it will keep changing position
			if k ~= 'D_PLAYRATE' then -- playrate is only required for startoffs calculation and shouldn't be set
			local val = k == 'D_LENGTH' and v-val
			or k == 'D_STARTOFFS' and v+val*props.D_PLAYRATE
			or v+val -- D_POSITION
			r.GetSetAutomationItemInfo(env, autoitem_idx, k, val, true)
			end
		end
	end

	local function Prevent_AutomItems_Overlap(env, autoitem_idx) -- current autom item props // prevents overlap between autom item being as long as the media item and the outside autom item attached to the media item right edge // NO OPTIMIZATION NEEDED, ONLY WORKS IN THIS CONFIG
		if not autoitem_idx then return end
	local pos = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', -1, false)
	local len = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', -1, false)
	local next_autoitem_pos = r.GetSetAutomationItemInfo(env, autoitem_idx+1, 'D_POSITION', -1, false) -- returns -1 if no next item
		if next_autoitem_pos > 0 and pos + len > next_autoitem_pos then
		r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len-(pos+len-next_autoitem_pos), true)
		end
	end

	if not t and item and item_end_init then -- COLLECT DATA // item and item_end_init is a safeguard against error when launching script with no items selected because then these vars are nil

	-- The table had to be indexed after the fact to prevent glitches in autom item handling by processing items outside of the edited item first; indices of tables with points under the edited item and outside of it had to be reversed after the fact to ensure accurate number of deleted points
	local env_t = {{},{},{},{}} -- collect env point and autom items // key 2 holds table of points at the edited item end and to the right
	env_t[1].item = {} -- collect envs with points under the edited item
	env_t[3].auto = {} -- collect envs with autom items at the edited item end and to the right
	env_t[4].autoItem = {} -- collect envs with autom items under the edited item
	local tr = r.GetMediaItemTrack(item)

		-- COLLECT TRACK ENVs
		for i = 0, r.CountTrackEnvelopes(tr)-1 do -- only counts active envelopes
		local env = r.GetTrackEnvelope(tr, i)
			if MOVE_AUTOMATION_ENVELOPES then -- points
			env_t[2][env] = {} -- dummy value, points outside of the media item don't need collecting
			env_t[1].item[env] = {}
				for i = 0, r.CountEnvelopePointsEx(env, -1)-1 do -- autoitem_idx is -1 (points only)
				local retval, time, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, i) -- autoitem_idx is -1
					if time >= item_start_init and time < item_end_init then
					local cnt = #env_t[1].item[env]
					env_t[1].item[env][cnt+1] = i -- TO AFFECT ENV POINTS BENEATH THE EDITED ITEM
					end
				end
			end
			if MOVE_AUTOMATION_ITEMS then -- autom items
			env_t[3].auto[env] = {} -- collect autom items at the edited item end and to the right
			env_t[4].autoItem[env] = {}
				for i = 0, r.CountAutomationItems(env)-1 do
				r.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, true) -- value 0 (unselect), ise_set true // prevent autom item deletion due to its being selected when media item length is changed
				local pos = r.GetSetAutomationItemInfo(env, i, 'D_POSITION', -1, false) -- value -1, is_set false
				local fin = pos + r.GetSetAutomationItemInfo(env, i, 'D_LENGTH', -1, false) -- value -1, is_set false
					if pos >= item_end_init then
					local cnt = #env_t[3].auto[env]
					env_t[3].auto[env][cnt+1] = i -- only collect autom items at the edited item right edge or to the right of it // item_end value only valid within an 'if' block, while outside of it, where it's being constantly updated being local, and where this function block runs, it's not, hence the use of the global item_end_init
					elseif pos < item_end_init and fin > item_start_init then
					local cnt = #env_t[4].autoItem[env]
					env_t[4].autoItem[env][cnt+1] = i -- TO AFFECT AUTOM ITEMS BENEATH THE EDITED ITEM
					end
				end
			end
		end
		-- COLLECT TRACK FX ENVs
		for fx_idx = 0, r.TrackFX_GetCount(tr)-1 do -- counts all envelopes, active or not, hence 'if env' cond below as inactive have no pointer and so are nil
			for parm_idx = 0, r.TrackFX_GetNumParams(tr, fx_idx)-1 do
			local env = r.GetFXEnvelope(tr, fx_idx, parm_idx, false) -- create is false
				if env then
					if MOVE_AUTOMATION_ENVELOPES then -- points
					env_t[2][env] = {} -- dummy value, points outside of the media item don't need collecting
					env_t[1].item[env] = {} -- collect points under the edited item
						for i = 0, r.CountEnvelopePointsEx(env, -1)-1 do -- autoitem_idx is -1 (points only)
						local retval, time, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, i) -- autoitem_idx is -1
							if time >= item_start_init and time < item_end_init then
							local cnt = #env_t[1].item[env]
							env_t[1].item[env][cnt+1] = i -- TO AFFECT ENV POINTS BENEATH THE EDITED ITEM
							end
						end
					end
					if MOVE_AUTOMATION_ITEMS then -- autom items
					env_t[3].auto[env] = {} -- collect autom items at the edited item end and to the right
					env_t[4].autoItem[env] = {}
						for i = 0, r.CountAutomationItems(env)-1 do
						r.GetSetAutomationItemInfo(env, i, 'D_UISEL', 0, true) -- value 0 (unselect), ise_set true // prevent autom item deletion due to its being selected when media item length is changed
						local pos = r.GetSetAutomationItemInfo(env, i, 'D_POSITION', -1, false) -- value -1, is_set false
						local fin = pos + r.GetSetAutomationItemInfo(env, i, 'D_LENGTH', -1, false) -- value -1, is_set false
							if pos >= item_end_init then
							local cnt = #env_t[3].auto[env]
							env_t[3].auto[env][cnt+1] = i -- only collect autom items at the edited item right edge or to the right of it // item_end value only valid within an 'if' block, while outside of it, where it's being constantly updated being local, and where this function block runs, it's not, hence the use of the global item_end_init
							elseif pos < item_end_init and fin > item_start_init then
							local cnt = #env_t[4].autoItem[env]
							env_t[4].autoItem[env][cnt+1] = i -- TO AFFECT AUTOM ITEMS BENEATH THE EDITED ITEM
							end
						end
					end
				end
			end
		end
	return env_t
	elseif t then -- SET POINTS/AUTOM ITEMS
	local diff = item_end ~= item_end_init and item_end - item_end_init or item_start ~= item_start_init and item_start_init - item_start -- item_end and item_start vars are only valid within an 'if' block where this function is used, while outside of it
		for k in ipairs(t) do
			-- MOVE ENV POINTS TO THE RIGHT OF THE EDITED ITEM
			if not t[k].item and not t[k].auto and not t[k].autoItem then -- remnant of the prev version, same as 'if k == 2'
				for env in pairs(t[2]) do
					for ptidx = r.CountEnvelopePointsEx(env, -1), 1, -1 do
					local retval, time, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, ptidx) -- autoitem_idx is -1
						if (item_start > item_start_init or item_end ~= item_end_init) and time >= item_end_init then -- excluding left edge untrim <-[ which is handled in the item envelopes loop below
						r.SetEnvelopePointEx(env, -1, ptidx, time+diff, val, shape, tens, false, true) -- autoitem_idx -1, sel false, noSortIn true
						end
					end
				r.Envelope_SortPointsEx(env, -1) -- autoitem_idx is -1
				end
			-- MOVE ENV POINTS BENEATH THE EDITED ITEM
			elseif t[k].item then -- remnant of the prev version, same as 'if k == 1'
				for env in pairs(t[1].item) do
					for i = #t[1].item[env], 1, -1 do
					local ptidx = t[1].item[env][i]
					local retval, time, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, ptidx) -- autoitem_idx is -1
						if item_start > item_start_init then -- trim left edge [->
						r.SetEnvelopePointEx(env, -1, ptidx, time+diff, val, shape, tens, false, true) -- move rightwards // autoitem_idx -1, sel false, noSortIn true
							if time+diff <= item_start_init then
							r.DeleteEnvelopePointEx(env, -1, ptidx) -- to prevent immediate deletion of the next point because it assumes the idx of the one which has just been deleted
							end
						elseif item_end <= time then -- trim right edge <-]
						r.DeleteEnvelopePointEx(env, -1, ptidx) -- autoitem_idx -1
						end
					end
					if item_start < item_start_init	then -- untrim left edge <-[
						for ptidx = r.CountEnvelopePointsEx(env, -1), 1, -1 do
						local retval, time, val, shape, tens, sel = r.GetEnvelopePointEx(env, -1, ptidx) -- autoitem_idx is -1
							if time >= item_start_init then
							r.SetEnvelopePointEx(env, -1, ptidx, time+diff, val, shape, tens, false, true)
							end
						end
					end
				r.Envelope_SortPointsEx(env, -1) -- autoitem_idx is -1
				end
			-- MOVE AUTOM ITEMS TO THE RIGHT OF THE EDITED ITEM
			elseif t[k].auto then -- remnant of the prev version, same as 'if k == 3'
				for env in pairs(t[3].auto) do	
					for i = #t[3].auto[env], 1, -1 do
					local autoitem_idx = t[3].auto[env][i]
					local pos = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', -1, false)
					r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', pos+diff, true) -- is_set true
					end
				end
			-- MOVE AUTOM ITEMS BENEATH THE EDITED ITEM
			elseif t[k].autoItem -- remnant of the prev version, same as 'if k == 4'
			then
				for env in pairs(t[4].autoItem) do
					for i = #t[4].autoItem[env], 1, -1 do
					local autoitem_idx = t[4].autoItem[env][i]
					local pos = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', -1, false) --  value -1, is_set false
					local len = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', -1, false) --  value -1, is_set false
					local fin = pos + len
						if len <= 0.1 then
						Delete_AutomItem(len, item, env, autoitem_idx) -- to prevent immediate deletion of the next autom item because it assumes the idx of the one which has just been deleted
						break -- when the above cond is 'len <= 0.1' prevents later autom items getting shorter and deleted because their indices change
						end
						
						if item_end < item_end_init then -- trim right edge <-] // if item_end == item_end_init then the length is changed at both trimming and untrimming
							if fin > item_end_init then -- autom item is partially under the edited media item
							local split_at_pos = item_end_init - pos >= .010 -- splitting with action is only possible at a distance of 10+ ms from the edge
							local split_at_fin = fin - item_end_init >= .010
								if not split_at_fin then -- fin is too close to the media item end
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+.01, true) -- extend by 10 ms so split is possible
								Split_AutomItem(item, item_end_init, env, autoitem_idx)
								Delete_AutomItem(len, item, env, autoitem_idx+1) -- delete the right part of the split
								local len = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', -1, false)
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+diff, true)
								else
									if not split_at_pos then -- pos is too close to the media item end
									UnTrim_AutomItem_LeftEdge(env, autoitem_idx, -0.01) -- extend by 10 ms so split is possible
									end
								Split_AutomItem(item, item_end_init, env, autoitem_idx)
								local len = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', -1, false) -- length of the lefthand split part
									if not split_at_pos or len+diff <= 0.1 then Delete_AutomItem(len, item, env, autoitem_idx) -- delete the left part of the split
									else
									r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+diff, true) -- + because the value is negative
									end
								local autoitem_idx = (not split_at_pos or len+diff <= 0.1) and autoitem_idx or autoitem_idx+1
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', item_end, true) -- adjust pos of righthand split part or autom item attached to the media item end by nudging leftwards because it tends to lag behind // was fixed item_end_init
								end
								if len+diff <= 0.1 then Delete_AutomItem(len+diff, item, env, autoitem_idx) break end -- probably redundant
							break
							
							elseif fin == item_end_init then
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+diff, true) -- shorten // is_set true
								if len+diff <= 0.1 then -- delete autom item shorter than 101 ms
								Delete_AutomItem(len+diff, item, env, autoitem_idx)
								break end
								
							elseif fin < item_end_init and not t[4].autoItem[env][i+1] and r.GetSetAutomationItemInfo(env, autoitem_idx+1, 'D_POSITION', -1, false) > 0 and r.GetSetAutomationItemInfo(env, autoitem_idx+1, 'D_POSITION', -1, false) < fin then -- prevent overlapping items when there's an off-grid gap between the last autom item under the edited media item and the 1st autom item outiside which starts at the media item end
							local overlap_diff = r.GetSetAutomationItemInfo(env, autoitem_idx+1, 'D_POSITION', -1, false) - fin -- previously next autom item pos was added diff before - fin
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+overlap_diff-0.001, true)	-- -0.001 to keep autom items slightly shorter to prevent noticeable overlap and overshortening (not sure it works)
								if len+diff <= 0.1 then
								Delete_AutomItem(len+diff, item, env, autoitem_idx)
								break end
							break end
							
						elseif item_end > item_end_init and fin > item_end_init then -- untrim right edge ]-> // autom item is partially under the edited media item
						local split_at_pos = item_end_init - pos >= .010 -- splitting with action is only possible at a distance of 10+ ms from the edge
						local split_at_fin = fin - item_end_init >= .010
							if not split_at_fin then -- fin is too close to the media item end
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+.01, true) -- extend by 10 ms so split is possible
							Split_AutomItem(item, item_end_init, env, autoitem_idx)
							Delete_AutomItem(len, item, env, autoitem_idx+1) -- delete the right part of the split
							else
								if not split_at_pos then -- pos is too close to the media item end
								UnTrim_AutomItem_LeftEdge(env, autoitem_idx, -0.01) -- extend by 10 ms so split is possible
								end
							Split_AutomItem(item, item_end_init, env, autoitem_idx)
								if not split_at_pos then Delete_AutomItem(len, item, env, autoitem_idx) end -- delete the left part of the split
							local item_end = r.GetMediaItemInfo_Value(item, 'D_POSITION') + r.GetMediaItemInfo_Value(item, 'D_LENGTH')
							local autoitem_idx = not split_at_pos and autoitem_idx or autoitem_idx+1
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', item_end, true) -- adjust by nudging rightwards because it tends to lag behind
							end
						break
						
						elseif item_start < item_start_init then -- untrim left edge <-[
							if pos >= item_start_init then -- move autom item rightwards
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', pos+diff, true)
							elseif pos < item_start_init then
							local split_at_pos = item_start_init - pos >= .010 -- splitting with action is only possible at a distance of 10+ ms from the edge
							local split_at_fin = fin - item_start_init >= .010
								if not split_at_fin then -- fin is too close to the media item start
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+.01, true) -- extend by 10 ms so split is possible
								Split_AutomItem(item, item_start_init, env, autoitem_idx)
								Delete_AutomItem(len, item, env, autoitem_idx+1) -- delete the right part of the split
								else
									if not split_at_pos then -- pos is too close to the media item start
									UnTrim_AutomItem_LeftEdge(env, autoitem_idx, -0.01) -- extend by 10 ms so split is possible
									end
								Split_AutomItem(item, item_start_init, env, autoitem_idx) -- split instead of extending the length and shifting the contents; and break below, otherwise lefthand part of the split gets deleted
									if not split_at_pos then Delete_AutomItem(len, item, env, autoitem_idx) end -- delete left part of the split
								local autoitem_idx = not split_at_pos and autoitem_idx or autoitem_idx+1 -- autoitem_idx+1 is autom item index after the split if left part wasn't deleted
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', item_start_init, true) -- align the righthand split path with the media item start because if the latter is off the grid the former might drift
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', item_start_init+diff, true) -- move the righthand split part
								end
							break -- prevents glitches of later autom items jumping ahead because their indices change
							end
							
						elseif item_start > item_start_init then -- trim left edge [->
							if pos == item_start_init then -- trim autom item (when trimming, the autom item may get shorter than its expected length by under 1 ms)
							local startoffs = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_STARTOFFS', -1, false)
							local playrate = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_PLAYRATE', -1, false)
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_STARTOFFS', startoffs-diff*playrate, true) -- diff is negative hence minus to add which shifts it leftwards
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+diff, true) -- here plus diff to subtract
							Prevent_AutomItems_Overlap(env, autoitem_idx)
							r.UpdateArrange()
								if len+diff <= 0.1 then Delete_AutomItem(len+diff, item, env, autoitem_idx) end
								
							elseif pos > item_start_init then -- advance autom item towards the media item start
							r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_POSITION', pos+diff, true) -- advance leftwards // is_set true
							Prevent_AutomItems_Overlap(env, autoitem_idx)
								if pos+diff < item_start_init then -- prevent overshoot past media item start; is likely to happen when the either media or autom item start is not on the grid
								local autom_itms_cnt = r.CountAutomationItems(env)
								Split_AutomItem(item, item_start_init, env, autoitem_idx)
								local del = r.CountAutomationItems(env) > autom_itms_cnt and Delete_AutomItem(len, item, env, autoitem_idx)
								end
								
							elseif pos < item_start_init then -- shorten autom item if it starts before the item
							local split_at_pos = item_start_init - pos >= .010 -- splitting with action is only possible at a distance of 10+ ms from the edge
							local split_at_fin = fin - item_start_init >= .010
								if not split_at_fin then -- fin is too close to the media item start
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len-(fin-item_start_init), true)
								else
									if not split_at_pos then -- pos is too close to the media item start
									UnTrim_AutomItem_LeftEdge(env, autoitem_idx, -0.01) -- extend by 10 ms so split is possible
									end
								Split_AutomItem(item, item_start_init, env, autoitem_idx) -- split instead of extending the length and shifting the contents; and break below, otherwise lefthand part of the split gets deleted
									if not split_at_pos then Delete_AutomItem(len, item, env, autoitem_idx) end -- delete left part of the split
								local autoitem_idx = not split_at_pos and autoitem_idx or autoitem_idx+1 -- autoitem_idx+1 is autom item index after the split if left part wasn't deleted
								local len = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', -1, false)
									if len+diff <= 0.1 then Delete_AutomItem(len, item, env, autoitem_idx) break end
								local startoffs = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_STARTOFFS', -1, false)
								local playrate = r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_PLAYRATE', -1, false)
								r.GetSetAutomationItemInfo(env, autoitem_idx+1, 'D_STARTOFFS', startoffs-diff*playrate, true) -- diff is negative hence minus to add which shifts it leftwards
								r.GetSetAutomationItemInfo(env, autoitem_idx, 'D_LENGTH', len+diff, true) -- here plus diff to subtract
								Prevent_AutomItems_Overlap(env, autoitem_idx)
								end
							end
						end -- autom item pos cond end
					end -- t.autoItem[env] loop end
				end -- t.autoItem loop end
			end -- 'autoItem' cond end
		end -- t loop end
	end -- t cond end

end



local item_start_init
local item_end_init
proj_state_cnt_init = 0
time_init = 0
add = 0

function RUN()

	if r.GetToggleCommandStateEx(0, 41990) == 1 -- Toggle ripple editing per-track
	then -- only run when Ripple edit per track is enabled

	local item = r.GetSelectedMediaItem(0,0)

	local move_automation_on = MOVE_AUTOMATION_ITEMS or MOVE_AUTOMATION_ENVELOPES and r.GetToggleCommandStateEx(0, 40070) == 1 -- Options: Move envelope points with media items and razor edits

	local env_t = move_automation_on and Store_Move_Automation(item, item_start, item_start_init, item_end, item_end_init) -- only run if the above option is enabled in REAPER, no t argument in the function so data collection condition is true // outside of 'item' condition below to collect envelopes data when no item is selected as well

		-- a mechanism to make items positions update immediately at item re-selection
		-- provided its length was changed by dragging its left edge while it was de-selected
		-- while RETROSPECTIVE_RIPPLE_EDIT is ON
		-- that is to make time difference condition used for real time editing necessarily true
		-- for this case through offsetting the time_init value by the necessary amount thereby
		-- eliminating the LAG
		if not r.GetSelectedMediaItem(0,0) then add = -10 end -- -10 is an arbitrary value which is sure to override the LAG value

		if item then
		
			-- Make sure only 1 item is selected
			if r.CountSelectedMediaItems(0) > 1 then r.SelectAllMediaItems(0,false) -- deselect all
			r.SetMediaItemSelected(item, true) -- re-select the 1st item
			end

		local item_start = r.GetMediaItemInfo_Value(item, 'D_POSITION')
		local item_len = r.GetMediaItemInfo_Value(item, 'D_LENGTH')
		local item_end = item_start + item_len
		local item_idx = r.GetMediaItemInfo_Value(item, 'IP_ITEMNUMBER')
		local grid_div_dur = Grid_Div_Dur_In_Sec() -- get grid division duration

			-- a mechanism to create a lag between change and its effect for item left edge changes
			-- because they occur too quickly and are likely to result in a change bigger than intended
			-- updates time stamp all the while change is being made
			-- when stopped the time stamp becomes fixed and so can be used as a stable reference point
			-- to condition update below
			-- it's still not perfect but better than without it
			if item_start ~= item_start_init and time_init == 0	then
			time_init = r.time_precise() + add -- update
			add = 0 -- reset
			end

			if item_len < grid_div_dur and PREVENT_EXTREME_SHORTENING then -- prevent item getting shorter than current grid division
				if item_end == item_end_init then -- if length has changed from the left
				r.ApplyNudge(0, 0, 1, 1, item_len - grid_div_dur, false, 0) -- 0 - curr proj, 0 nudge by value, 1 - left trim, 1 - nudgeunits sec, reverse false, copies 0 (ignored) // untrim left edge, negative value
				-- OR
				--r.ApplyNudge(0, 0, 1, 1, grid_div_dur - item_len, true, 0) -- 0 - curr proj, 0 nudge by value, 1 - left trim, 1 - nudgeunits sec, reverse true, copies 0 (ignored) // untrim left edge, positive value
				elseif item_start == item_start_init then -- if length has changed from the right
				r.ApplyNudge(0, 0, 3, 1, grid_div_dur - item_len, false, 0) -- 0 - curr proj, 0 nudge by value, 3 - right edge, 1 - nudgeunits sec, reverse false, copies 0 (ignored) // untrim right edge, positive value
				end
			elseif item_start ~= item_start_init and item_end ~= item_end_init then --- when the whole selected item has been moved or another item has been selected, just update; if moved, native Ripple edit will take care of the changes in Arrange; also sets initial init values
			item_start_init = item_start
			item_end_init = item_end
			elseif item_end ~= item_end_init and item_start == item_start_init  -- when only right edge pos has changed, move next item
			and RIGHT_EDGE_CHANGE
			then
			r.Undo_BeginBlock()
			local item_tr = r.GetMediaItemTrack(item)
				for i = item_idx+1, r.CountTrackMediaItems(item_tr)-1 do
				local item_next = r.GetTrackMediaItem(item_tr, i)
					if item_next then
					local item_next_pos = r.GetMediaItemInfo_Value(item_next, 'D_POSITION')
					r.SetMediaItemInfo_Value(item_next, 'D_POSITION', item_next_pos + item_end - item_end_init)
					end
				end
			local move = move_automation_on and Store_Move_Automation(item, item_start, item_start_init, item_end, item_end_init, env_t) -- only run if 'Move envelope points with media items and razor edits' is enabled in REAPER // shifts envelopes whether items to the right are present or not // can be placed witin 'if item_next' block above to prevent it
			item_end_init = item_end -- update stored value
			r.Undo_EndBlock('Item right edge change ripple', -1)
			elseif item_end == item_end_init and item_start ~= item_start_init
			and r.time_precise() - time_init >= LAG -- update with a lag after making a change
			and LEFT_EDGE_CHANGE
			then
			r.Undo_BeginBlock()
			r.SetMediaItemInfo_Value(item, 'D_POSITION', item_start_init)
			local item_tr = r.GetMediaItemTrack(item)
				for i = item_idx+1, r.CountTrackMediaItems(item_tr)-1 do
				local item_next = r.GetTrackMediaItem(item_tr, i)
					if item_next then
					local item_next_pos = r.GetMediaItemInfo_Value(item_next, 'D_POSITION')
					r.SetMediaItemInfo_Value(item_next, 'D_POSITION', item_next_pos + item_start_init - item_start)
					end
				end
			local move = move_automation_on and Store_Move_Automation(item, item_start, item_start_init, item_end, item_end_init, env_t) -- only run if Move envelope points with media items and razor edits is enabled in REAPER // shifts envelopes whether items to the right are present or not // can be placed witin 'if item_next' block above to prevent it
			-- item_start_init isn't updated because item initial start position doesn't change after being set above within 'item_start ~= item_start_init and item_end ~= item_end_init' condition block
			item_end_init = item_start_init + r.GetMediaItemInfo_Value(item, 'D_LENGTH') -- update stored value
			time_init = 0
			r.Undo_EndBlock('Item left edge change ripple', -1)
			-------------------------------------------------------------------------
			end
		elseif not RETROSPECTIVE_RIPPLE_EDIT then -- reset when no items selected
		item_start_init = nil
		item_end_init = nil
		end

	end -- item cond end

r.defer(RUN)
r.UpdateArrange()

end


RIGHT_EDGE_CHANGE = is_set(RIGHT_EDGE_CHANGE)
LEFT_EDGE_CHANGE = is_set(LEFT_EDGE_CHANGE)
RETROSPECTIVE_RIPPLE_EDIT = is_set(RETROSPECTIVE_RIPPLE_EDIT)
PREVENT_EXTREME_SHORTENING = is_set(PREVENT_EXTREME_SHORTENING)
MOVE_AUTOMATION_ENVELOPES = is_set(MOVE_AUTOMATION_ENVELOPES)
MOVE_AUTOMATION_ITEMS = is_set(MOVE_AUTOMATION_ITEMS)
LAG = #LEFT_EDGE_CHANGE_LAG:gsub(' ','') > 0 and LEFT_EDGE_CHANGE_LAG
LAG = LAG and tonumber(LAG)/1000 or .3

-- (re)setting toggle state and updating toolbar button
local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()

r.SetToggleCommandState(sect_ID, cmd_ID, 1)
r.RefreshToolbar(cmd_ID)


RUN()

r.atexit(function() r.SetToggleCommandState(sect_ID, cmd_ID, 0); r.RefreshToolbar(cmd_ID) end)


--[[ CUSTOM ACTIONS (see text in About tag above)

ACT 3 0 "91c7f176d06cee4ba9717a5ecebc5920" "Custom: Trim selected item left edge to grid and SHIFT FOLLOWING ITEMS LEFT on selected track (to use with Ripple per track)" 40528 40290 41173 40647 41305 40630 41205 40635
ACT 3 0 "47ab09fcc933f34c9f3fc2c5e7ab9016" "Custom: Trim selected item right edge to grid and SHIFT FOLLOWING ITEMS LEFT on selected track (to use with Ripple per track)" 40528 40290 41174 40646 41311 40698 40631 41311 40635 41173 40006 42398
ACT 3 0 "cf32f2dde91d94488cae4578b7d86d10" "Custom: Trim(Un) selected item left edge to grid and SHIFT FOLLOWING ITEMS RIGHT on selected track (to use with Ripple per track)" 40528 40290 41173 40646 41305 40630 41205 40635
ACT 3 0 "4bed15b5e04c4b43b16db06a54fd8215" "Custom: Trim(Un) selected item right edge to grid and SHIFT FOLLOWING ITEMS RIGHT on selected track (to use with Ripple per track)" 40528 41174 40625 40647 40626 41174 40142 41295 40037 40718 41174 40647 41311 40930 40038 40038 40718 40006 40037 40718 41174 40635

]]



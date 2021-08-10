--[[
ReaScript name: Create time selection between two marked points from the closest to cursor on the left
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main] .
About:

	####GUIDE

	- The script allows creating time selection between two marked points
	starting from the closest to the mouse/edit cursor on the left.

	- Marked points are positions on the timeline which in Arrange are marked with
	project/tempo markers, region/loop start/end points and in items are marked
	with take/stretch markers, transient guides and media cues. Loop points are only
	relevant when the option *Link loop points to time selection* is disabled at
	*Preferences -> Editing behavior*.

	- Admittedely to a region time selection can be set with the default shortcut
	of Ctrl/Cmd + click on the ruler under the region bar or by dragging, provided 
	snapping of selecton to markers is active in Snap settings, which is also true 
	for setting time selection between two project markers by dragging or clicking 
	if enabled in *Preferences -> Mouse modifiers -> Ruler -> double click*, but not 
	really to other marked ranges.

	- To create a time selection between two marked points of the same kind hold
	mouse cursor next to the first (start) point on its right side and call
	the script.

	- If you have multiple marked points next to each other, time selection will
	be created starting from the closest to the mouse cursor on the left.

	- If marked point start positions overlap time selection will be created
	between start and end points of the same kind which make the shortest range.

	- When mouse cursor is over a selected item, the marked points considered
	are those specific to the item. In items with multiple takes only active
	item take is considered.

	- Enabled **IGNORE_SELECTED** option in the USER SETTINGS below will instruct
	the script to ignore selected item under mouse cursor and only consider
	marked points specific to the Arrange.

	- In order to allow running the script from a menu or a toolbar button or
	generally in situations where mouse cursor is taken by another process
	and/or not hovering immediately over the Arrange, **EDIT_CURSOR** option is
	provided in the USER SETTINGS below.  
	When enabled, edit cursor position instead of mouse cursor's will determine
	the closest marked point.  
	With mouse cursor the script may still work if run from a floating toolbar
	button but the toolbar must float directly over the marked out range and be
	close enough to the intended start point.

	- Creating time selection between marked points of different kinds isn't
	supported.


Licence: WTFPL
REAPER: at least v5.962

]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable insert any alphanumeric character between the quotation marks.
-- Try to not leave empty spaces.

local IGNORE_SELECTED = "" -- ignore marked points in selected item under mouse cursor
local EDIT_CURSOR = "" -- enable when running via button or menu (mouse cursor isn't over Arrange)

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------



function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


function GetStartEndPoints(EDIT_CURSOR, take)

r.PreventUIRefresh(1)

local curs_pos

	if EDIT_CURSOR then -- edit cursor
	curs_pos = {r.GetCursorPosition()} -- table for consistency with mouse cursor position below
	else -- mouse cursor
	local x, y = r.GetMousePosition()
	local edit_curs_pos = r.GetCursorPosition() -- store edit cursor position to restore later
	r.Main_OnCommand(40514,0) -- View: Move edit cursor to mouse cursor (no snapping) // more seinsitive than with snapping
	curs_pos = {r.GetCursorPosition()} -- store mouse cursor position based on moved edit cursor pos
	r.SetEditCurPos(edit_curs_pos, 0, 0) -- restore edit curs pos; moveview and seekplay 0
	end

local t1 = {}
local t2 = {}

	if not take then -- item not selected
	-- collect project markers
	local i = 0
		repeat
		local retval, is_rgn, pos, rgn_end, name, mrk_idx = r.EnumProjectMarkers(i)
			if retval > 0 and not is_rgn then -- marker
			local j = i+1 -- continue from next marker
				repeat -- look for next marker skipping any regions standing in the way
				retval_next, is_rgn_next, pos_next, rgn_end, name, mrk_idx = r.EnumProjectMarkers(j)
				j = j+1
				until retval_next > 0 and not is_rgn_next or retval_next == 0
				if pos > curs_pos[1] then -- no markers to the left of cursor
				t2[#t2+1] = {pos, nil, {'PROJECT MARKERS', 'START'}} break
				elseif retval_next == 0 then -- no next marker and so no markers to the right of cursor
				t1[#t1+1] = {pos, nil, {'PROJECT MARKERS', 'END'}} break
				elseif pos <= curs_pos[1] and pos_next > curs_pos[1] then -- cursor is between two markers or at the marker on the left
				t1[#t1+1] = {pos, pos_next}
				break end
			end
		i = i + 1
		until retval == 0

	-- collect regions
	local i = 0 -- reinitialize
		repeat
		local retval, is_rgn, pos, rgn_end, name, mrk_idx = r.EnumProjectMarkers(i)
			if retval > 0 and is_rgn then
				if pos <= curs_pos[1] and rgn_end > curs_pos[1] then -- cursor is exactly between region start and end or at region start
				t1[#t1+1] = {pos, rgn_end} break
				elseif pos > curs_pos[1] then -- cursor is to the left of region start so no region points on the left
				t2[#t2+1] = {pos, nil, {'REGION', 'START'}} break
				elseif rgn_end <= curs_pos[1] then -- cursor is to the right of or at region end so no region points on the right
				t1[#t1+1] = {rgn_end, nil, {'REGION', 'END'}}
				end -- no break because every earlier region end pos will be less than the cursor pos which is not a reason to stop
			end
		i = i+1
		until retval == 0

	-- get loop points (if they're unlinked from time selection)
	local start, fin = r.GetSet_LoopTimeRange(0, 1, 0, 0, 0) -- isSet 0, isLoop 1, allowautoseek 0
		if start ~= fin then -- loop points actually are set, have diff positions
			if start <= curs_pos[1] and fin > curs_pos[1] -- cursor is exactly between loop start and end points or at loop start
			then
			t1[#t1+1] = {start, fin}
			elseif start > curs_pos[1] then -- cursor is to the left of the loop start so no loop points on the left
			t2[#t2+1] = {start, nil, {'LOOP', 'START'}}
			elseif fin <= curs_pos[1] then -- cursor is to the right of or at the loop end so no loop points on the right
			t1[#t1+1] = {fin, nil, {'LOOP', 'END'}}
			end
		end

	-- get tempo markers
	local i = 0
		repeat
		local retval, pos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = r.GetTempoTimeSigMarker(0, i) -- retval true or false
		local retval_next, pos_next, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = r.GetTempoTimeSigMarker(0, i+1)
			if retval and pos > curs_pos[1] then -- cursor is to the left of the 1st marker so no markers on the left
			t2[#t2+1] = {pos, nil, {'TEMPO MARKERS', 'START'}} break
			elseif retval and not retval_next then -- cursor is to the right of or at the last marker so no markers on the right; the 2nd cond wihtout retval would be true even if there're no markers
			t1[#t1+1] = {pos, nil, {'TEMPO MARKERS', 'END'}} break
			elseif retval then
				if pos <= curs_pos[1] and pos_next > curs_pos[1] then -- cursor is between two markers or at the marker on the left
				t1[#t1+1] = {pos, pos_next} break
				end
			end
		i = i+1
		until not retval

	else -- Item selected
	
	-- collect take markers
	local playrate = r.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE') -- affects take start offset & take marker pos
	local item_pos = r.GetMediaItemInfo_Value(r.GetMediaItemTake_Item(take), 'D_POSITION')
	local offset = r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')
	local i = 0
		repeat
		local retval, name, color = r.GetTakeMarker(take, i) -- retval = -1 or position in item source
		local pos = item_pos + (retval - offset)/playrate
		local retval_next, name, color = r.GetTakeMarker(take, i+1) -- next marker
		local pos_next = item_pos + (retval_next - offset)/playrate
			if retval > -1 and pos > curs_pos[1] then -- no markers or the very 1st marker is right of cursor
			t2[#t2+1] = {pos, nil, {'TAKE MARKERS', 'START'}} break
			elseif retval > -1 and retval_next == -1 then
			t1[#t1+1] = {pos, nil, {'TAKE MARKERS', 'END'}} break
			elseif pos <= curs_pos[1] and pos_next > curs_pos[1] then
			t1[#t1+1] = {pos, pos_next} break
			end
		i = i+1
		until retval == -1 -- if no markers; or until i == r.GetNumTakeMarkers(take)-1

	-- collect stretch markers
	local i = 0
		repeat
		local retval, pos, src_pos = r.GetTakeStretchMarker(take, i) -- retval == -1 or index
		local pos = item_pos + (pos - offset)/playrate
		local retval_next, pos_next, src_pos_next = r.GetTakeStretchMarker(take, i+1) -- next stretch marker
		local pos_next = item_pos + (pos_next - offset)/playrate
			if retval > -1 and pos > curs_pos[1] then
			t2[#t2+1] = {pos, nil, {'STRETCH MARKERS', 'START'}} break
			elseif retval > -1 and retval_next == -1 then
			t1[#t1+1] = {pos, nil, {'STRETCH MARKERS', 'END'}} break
			elseif pos <= curs_pos[1] and pos_next > curs_pos[1] then
			t1[#t1+1] = {pos, pos_next} break
			end
		i = i+1
		until retval == -1

	-- collect transient guides (markers)
	local retval, take_GUID = r.GetSetMediaItemTakeInfo_String(take, 'GUID', '', 0)
	local take_GUID = take_GUID:gsub('%-','%%%0') -- escape dashes
	local retval, chunk = r.GetItemStateChunk(r.GetMediaItemTake_Item(take), '', false)
	local sr, guides = chunk:match(take_GUID..'.-TMINFO (.+)\nTM (.-)\n') -- get guides sample rate data and list of distance values in samples
		if sr then -- there're transient guides in the take
		local guides_t = {}
		-- sample values for each next guide are counted from the previous guide apart from the first guide whose distance in samples is counted from the item start
			for guide in guides:gmatch('%d+') do
			local guide_distance = #guides_t == 0 and guide or guide + guides_t[#guides_t] -- collect absolute sample values combining all relative sample values up to a given guide from the item start bar the very first
			guides_t[#guides_t+1] = tonumber(guide_distance) -- the rest of calculations is done below instead because this table must contain pure sample values in order for the guide_distance calculation to be accurate
			end
		local sr = tonumber(sr) -- sample rate info from guides chunk
		local dur_per_spl = 1/sr -- 1 sample duration in sec at the given sample rate; 1 sec divided by sample rate value
			for k,v in ipairs(guides_t) do -- convert sample values to ms
			local pos = item_pos + (v*dur_per_spl - offset)/playrate  -- count absolute pos in the project on the time line
			local pos_next = guides_t[k+1] and item_pos + (guides_t[k+1]*dur_per_spl - offset)/playrate -- condition in case there's no next entry in the table ergo no next trans. guide
				if pos_next and pos <= curs_pos[1] and pos_next > curs_pos[1] then -- cursor is between two transient guides or at the guide on the left
				t1[#t1+1] = {pos, pos_next} break
				elseif pos > curs_pos[1] then -- cursor is to the left of the 1st trans. guide so no guides on the left
				t2[#t2+1] = {pos, nil, {'TRANSIENT GUIDES', 'START'}} break
				elseif not pos_next then -- cursor is to the right of or at the last trans. guide so no guides on the right
				t1[#t1+1] = {pos, nil, {'TRANSIENT GUIDES', 'END'}} break
				end
			end
		end

	-- media cues --
		if not r.APIExists('CF_EnumMediaSourceCues') then -- SWS ext isn't installed
		-- store current project markers and delete
		local function Store_Delete_Restore_Proj_Mark_Regions(t)
			if not t then -- store and delete
			local retval, num_markers, num_regions = r.CountProjectMarkers(0)
			local i = num_markers + num_regions-1 -- -1 isn't necessary, if there's no marker with the initial index no error occurs, just one extra loop cycle
			local mark_reg_t = {}
			repeat -- store and delete in decscending order
				local retval, is_rgn, pos, rgn_end, name, mrk_idx, color = r.EnumProjectMarkers3(0, i) -- mrk_id is the actual marker ID displayed in Arrange which may differ from retval
					if retval > 0 then
					local rgn_end = is_rgn and rgn_end
					mark_reg_t[#mark_reg_t+1] = {mrk_idx, pos, rgn_end, name, color}
					end
				-- the cond is needed to avoid deleting objects (markers/regions) with the same index ahead of time
				local del = not is_rgn and r.DeleteProjectMarker(0, mrk_idx, false) -- isrgn is false, markers only
				local del = is_rgn and r.DeleteProjectMarker(0, mrk_idx, true) -- isrgn is true, regions only
				i = i - 1
				until i == -1 or retval == 0 -- OR retval == 1 or retval == 0 -- until the iterator is less than the 1st marker/region index or until the 1st marker/region or until retval == 0 if no markers/regions marker/region
			return mark_reg_t
			else -- restore
				for _,v in ipairs(t) do
				local mrk_idx, pos, rgn_end, name, color = table.unpack(v) -- extra step for clarity
				-- the cond is needed to avoid inserting markers with region start point and regions with the end point being nil which will throw an error
				local marker = not rgn_end and r.AddProjectMarker2(0, false, pos, 0, name, mrk_idx, color) -- isrgn is false, markers only
				local region = rgn_end and r.AddProjectMarker2(0, true, pos, rgn_end, name, mrk_idx, color) -- isrgn is true, regions only
				end
			end
		end -- function end

		local mark_reg_t = Store_Delete_Restore_Proj_Mark_Regions()
		r.Main_OnCommand(40692,0) -- Item: Import item media cues as project markers // convert media cues to proj. markers -- CREATES UNDO POINT
		
		-- collect project markers/regions corresponding to media cues
		local i = 0
			repeat
			local retval, is_rgn, pos, rgn_end, name, mrk_idx = r.EnumProjectMarkers(i)
				if retval > 0 and not is_rgn then -- marker
				local j = i+1 -- continue from next marker
					repeat -- look for next marker skipping any regions standing in the way
					retval_next, is_rgn_next, pos_next, rgn_end, name, mrk_idx = r.EnumProjectMarkers(j)
					j = j+1
					until retval_next > 0 and not is_rgn_next or retval_next == 0
					if pos > curs_pos[1] then -- no markers to the left of cursor
					t2[#t2+1] = {pos, nil, {'MEDIA CUES MARKER', 'START'}} break
					elseif retval_next == 0 then -- no next marker and so no markers to the right of cursor
					t1[#t1+1] = {pos, nil, {'MEDIA CUES MARKER', 'END'}} break
					elseif pos <= curs_pos[1] and pos_next > curs_pos[1] -- cursor is between two markers or at the marker on the left
					then
					t1[#t1+1] = {pos, pos_next}
					break end
				end
			i = i + 1
			until retval == 0
		local i = 0
			repeat
			local retval, is_rgn, pos, rgn_end, name, mrk_idx = r.EnumProjectMarkers(i)
				if retval > 0 and is_rgn then
					if pos <= curs_pos[1] and rgn_end > curs_pos[1] then -- cursor is exactly between region start and end or at region start
					t1[#t1+1] = {pos, rgn_end} break
					elseif pos > curs_pos[1] then -- cursor is to the left of region start so no region points on the left
					t2[#t2+1] = {pos, nil, {'MEDIA CUES REGION', 'START'}} break
					elseif rgn_end <= curs_pos[1] then -- cursor is to the right of or at region end so no region points on the right
					t1[#t1+1] = {rgn_end, nil, {'MEDIA CUES REGION', 'END'}}
					end -- no break because every earlier region end pos will be less than the cursor pos which is not a reason to stop
				end
			i = i+1
			until retval == 0
		Store_Delete_Restore_Proj_Mark_Regions() -- delete markers/region media cues were converted to
		Store_Delete_Restore_Proj_Mark_Regions(mark_reg_t) -- restore original markers/regions
		else -- SWS ext is installed
		local src = r.GetMediaItemTake_Source(take)
		local i = 0
			repeat
			local retval, pos, rgn_end, is_rgn, name = r.CF_EnumMediaSourceCues(src, i) -- retval is index or 0
				if retval > 0 and not is_rgn then
				local pos = item_pos + (pos - offset)/playrate
				local j = i+1 -- continue from nex tmedia cues marker
					repeat -- look for next media cues marker skipping any regions standing in the way
					retval_next, pos_next, rgn_end_next, is_rgn_next, name = r.CF_EnumMediaSourceCues(src, j)
					j = j+1
					until retval_next > 0 and not is_rgn_next or retval_next == 0
				local pos_next = item_pos + (pos_next - offset)/playrate
					if pos > curs_pos[1] then -- no media cues marker to the left of cursor
					t2[#t2+1] = {pos, nil, {'MEDIA CUES MARKER', 'START'}} break
					elseif retval_next == 0 then -- no next media cues marker and so no media cue markers to the right of cursor
					t1[#t1+1] = {pos, nil, {'MEDIA CUES MARKER', 'END'}} break
					elseif pos <= curs_pos[1] and pos_next > curs_pos[1] -- cursor is between two media cues marker or at the media cues marker on the left
					then
					t1[#t1+1] = {pos, pos_next}
					break end
				end
			i = i + 1
			until retval == 0
		local i = 0
			repeat
			local retval, pos, rgn_end, is_rgn, name = r.CF_EnumMediaSourceCues(src, i) -- retval is index or 0
				if retval > 0 and is_rgn then
				local pos = item_pos + (pos - offset)/playrate
				local rgn_end = item_pos + (rgn_end - offset)/playrate
					if pos <= curs_pos[1] and rgn_end > curs_pos[1] then -- cursor is exactly between media cues region start and end or at media cues region start
					t1[#t1+1] = {pos, rgn_end} break
					elseif pos > curs_pos[1] then -- cursor is to the left of media cues region start so no media cue region points on the left
					t2[#t2+1] = {pos, nil, {'MEDIA CUES REGION', 'START'}} break
					elseif rgn_end <= curs_pos[1] then -- cursor is to the right of or at media cues region end so no media cue region points on the right
					t1[#t1+1] = {rgn_end, nil, {'MEDIA CUES REGION', 'END'}}
					end -- no break because every earlier media cues region end pos will be less than the cursor pos which is not a reason to stop
				end
			i = i + 1
			until retval == 0

		end -- API check cond. close

	end -- main take cond. close



local t = #t1 > 0 and t1 or t2 -- if there's at least one valid range or invalid range(s) to the right of cursor, select t1, else select t2 (invalid range to the left of cursor); two diff tables because in t1 the definitive value is the greatest (the closest to cursor on the left) while in t2 it's the smallest (the closest to cursor on the right); t2 is only for errors

table.sort(t, function(a, b) return a[1] < b[1] end) -- sort by 1st values in nested tables (indicating proximity to the cursor on the left); the sort function only sorts in descending order, therefore GetStartEndPoints() function returns the last table values (the greatest, in which the first value is the closest to the cursor on the left)

-- if there're overlapping start points some of which don't have a corresponding end point but whose values moved to the end of the table after sorting to be returned by the function, select another equally close start point which do have a corresponding end point
	for k,v in pairs(t) do
		if t[#t][1] == v[1] and not t[#t][2] and v[2] then
		t[#t][2] = v[2] break end
	end

-- if there're overlapping start points with different end points, select end point which is the closest to the start point by adding it as the 2nd value in the nested table holding time selection coordinates at the end of the main table
	for k,v in pairs(t) do
		if t[#t][1] == v[1] and v[2] and t[#t][2] > v[2] then
		t[#t][2] = v[2] end
	end

r.PreventUIRefresh(-1)

	if #t1 > 0 then -- create conditon for error message: if no start/end point, end point is nil; if no markers whatsoever everything is nil, so evaluating the start point in the Main routine outside of the function will suffice
	return t[#t][1], t[#t][2], t[#t][3] -- the definitive value is the greatest (at the end of the table after sorting), i.e. the closest to cursor on the left
	elseif #t2 > 0 then return t[1][1], t[1][2], t[1][3] -- the definitive value is the smallest (at the beginning of the table after sorting), i.e. the closest to cursor on the right
	end

end -- function end


local IGNORE_SELECTED = IGNORE_SELECTED:gsub(' ','') ~= ''
local EDIT_CURSOR = EDIT_CURSOR:gsub(' ','') ~= ''


local x, y = r.GetMousePosition()
local item, take = r.GetItemFromPoint(x, y, true) -- allow locked is true, the function returns both item and take pointers; only item is used below
local item = not item and not IGNORE_SELECTED and EDIT_CURSOR and r.GetSelectedMediaItem(0,0) or item -- if no item under mouse, get first selected if not ignored and if edit cursor pos is enabled in the SETTINGS


	if item and r.IsMediaItemSelected(item) then -- target selected item under mouse cursor/first selected item
	local take = r.GetActiveTake(item)
	start, fin, err = GetStartEndPoints(EDIT_CURSOR, take)
	else -- target timeline
	start, fin, err = GetStartEndPoints(EDIT_CURSOR)
	end

	if not start then r.TrackCtl_SetToolTip(('\n NO MARKER OBJECTS. \n '):gsub('','%0 '), x, y+10, true) return
	elseif not fin then r.TrackCtl_SetToolTip(('\n '..err[1]..': \n\n NO '..err[2]..' POINT. \n '):gsub('','%0 '), x, y+10, true) -- topmost true
	return end
	r.GetSet_LoopTimeRange(1, 0, start, fin, 0) -- isSet 1, isLoop 0, allowautoseek 0






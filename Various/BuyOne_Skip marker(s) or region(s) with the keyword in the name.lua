--[[
ReaScript name: Skip marker(s) or region(s) with the keyword in the name
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	During playback or recording the script makes the play cursor skip marker(s) 
	or region(s) containing in their name a keyword defined in the KEYWORD setting 
	in the USER SETTINGS. Once launched the script runs in the background.

	By default it skips markers, to switch to skipping regions enable USE_REGIONS 
	setting in the USER SETTINGS. Markers and regions can be re-ordered and
	renamed on the fly.

	USING MARKERS

	Place one marker with the name containing the KEYWORD before the segment 
	to be skipped and another one without the KEYWORD at the end of such segment. 
	As soon as the play cursor reaches the 1st marker it will jump to the 2nd one.  
	If in between there're any markers whose name also contains the KEYWORD 
	the segment which follow will be skipped as well. So the play cursor skips
	to the first marker which doesn't contain the KEYWORD in the name following 
	a marker which does.  

	Behavior of overlapping markers is determined by the one with the greatest
	displayed index.

	USING REGIONS

	Encompass with a region a timeline segment which needs to be skipped 
	and add the KEYWORD to its name.   
	Once the play cursor reaches the start of the region whose name contains 
	the KEYWORD it will jump to such region's end thereby skipping it. If there're 
	several such regions in a row with no gaps, the play cursor jumps to the end 
	of the last one which precedes a region without the KEYWORD in its name 
	or which is followed by a gap between regions or by the end of the project.  
	If the script is launched while the play cursor is within a region which 
	contains the KEYWORD in its name, such region won't be marked for skipping. 
	Only regions which lay ahead of the play cursor are detected for skipping.  

	If overlapping regions start and end at the same time their behavior 
	is determined by the one with the greatest displayed index; if they only end 
	at the same time their behavior is determined by the one with the earliest 
	start; if they start at the same time, their behavior is determined 
	by the longest one; if start and end times of overlapping regions don't
	coincide the one containing the KEYWORD takes precendence.
		
	RECORDING

	Recording will be done in segments. After skipping a marker or a region 
	a new segment will begin. The start time of the next segment will depend 
	on the pre-roll setting available in the Metronome configuration window. 
	If pre-roll isn't enabled the recording will start as soon as the play cursor 
	jumps to another marker or a region end.

	As far as recording is concerned the script does in essense what can be 
	done natively with 'Auto-punch selected items' feature https://youtu.be/bjb8G6jnkUo

	If the script is linked to a toolbar button the button will be lit while 
	it's running.

]]

------------------------------------------------------------------
-------------------------- USER SETTINGS -------------------------
------------------------------------------------------------------

-- Enable this setting by inserting any QWERTY character
-- between the quotation marks so the script can be used
-- then configure the settings below
ENABLE_SCRIPT = ""

-- Add this to the marker(s)/region(s) to be skipped;
-- the script is case insensitive to the keyword.
KEYWORD = "skip"

-- To enable the settings place any QWERTY character
-- between the quotation marks.
-- If empty markers are used
USE_REGIONS = ""

-------------------------------------------------------------------
----------------------- END OF USER SETTINGS ----------------------
-------------------------------------------------------------------


local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


function Script_Not_Enabled(ENABLE_SCRIPT)
	if #ENABLE_SCRIPT:gsub(' ','') == 0 then
	local emoji = [[
		_(ツ)_
		\_/|\_/
	]]
	r.MB('  Please enable the script in its USER SETTINGS.\n\nSelect it in the Action list and click "Edit action...".\n\n'..emoji, 'PROMPT', 0)
	return true
	end
end


function At_Exit_Wrapper(func, ...) -- wrapper for a 3d function with arguments for r.atexit()
-- thanks to Lokasenna, https://forums.cockos.com/showthread.php?t=218805 -- defer with args
-- his code didn't work because func(...) produced an error without there being elipsis
-- in function() as well, but gave direction
local t = {...}
return function() func(table.unpack(t)) end
end


function Re_Set_Toggle_State(sect_ID, cmd_ID, toggle_state) -- in deferred scripts can be used to set the toggle state on start and then with r.atexit and At_Exit_Wrapper() to reset it on script termination
r.SetToggleCommandState(sect_ID, cmd_ID, toggle_state)
r.RefreshToolbar(cmd_ID)
end

function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Get_First_MarkerOrRgn_After_Time(time, USE_REGIONS, KEYWORD) -- time in sec // accounting for all overlaps
local i, mrkr_idx, rgn_idx = 0, -1, -1 -- -1 to count as 0-based
local ret_idx, ret_pos, ret_name, ret_rgn_end
	repeat
	local retval, isrgn, pos, rgn_end, name, idx, color = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
	mrkr_idx = retval > 0 and not isrgn and mrkr_idx+1 or mrkr_idx -- this counting method is used to conform with the type of index expected by the GoToMarker() function
	rgn_idx = retval > 0 and isrgn and rgn_idx+1 or rgn_idx -- relic of the prev version because GoToRegion() was discarded
		if retval > 0 then
			if not USE_REGIONS and not isrgn then
				if not ret_pos and pos > time or ret_pos and pos == ret_pos then -- find 1st then look for overlaps
				ret_idx = mrkr_idx; ret_pos = pos; ret_name = name
				end
			elseif USE_REGIONS and isrgn then
				if not ret_pos and pos > time or ret_pos and pos == ret_pos and rgn_end >= ret_rgn_end then -- find 1st then look for overlaps // automatically respects the longest region
				ret_idx = rgn_idx; ret_pos = pos; ret_name = name; ret_rgn_end = rgn_end
				end
			end
		end
	i = i+1
	until retval == 0 -- until no more markers/regions

	if ret_name and ret_name:lower():match(Esc(KEYWORD)) then -- no overlaps or overlaps, the last of which contains the KEYWORD
	return ret_idx, ret_pos, ret_name, ret_rgn_end
	elseif ret_name then -- no overlaps and no KEYRORD or overlaps, the last of which doesn't contain the KEYWORD, search for next which does
	local ret_idx, ret_pos, ret_name, ret_rgn_end = Get_First_MarkerOrRgn_After_Time(ret_pos, USE_REGIONS, KEYWORD)
	return ret_idx, ret_pos, ret_name, ret_rgn_end
	end

end


function Find_Next_MrkrOrRgn_By_Name(ref_idx, ref_pos, USE_REGIONS, KEYWORD) -- or by the lack of elements in the name; ref_idx is 0-based // accounting for all overlaps

-- when markers are ovelapping and their lanes are collapsed, the displayed index
-- is that of the marker with the lowest index among the overlaping ones,
-- while the name is that of the marker with the highest index,
-- with overlapping regions the name and the index of the region with the greater index
-- covers the name and the index of the region with the smaller index,
-- since in this script the name defines the marker role we need to make sure that
-- the marker with the KEYWORD isn't overlapped by a marker with a greater index without the KEYWORD
-- because in this case the KEYWORD won't be visible and the marker must be treated as a regular one,
-- and that on the other hand a marker without the KEYWORD (the one to jump to) is not overlapped
-- by a marker with a greater index with the KEYWORD, because in this case the KEYWORD will be visible
-- and the marker will have to be treated as the skip trigger

	if not ref_idx then return end
local i, mrkr_idx, rgn_idx = 0, -1, -1 -- -1 to count as 0-based
local ret_idx, ret_pos, ret_name, ret_rgn_end
	repeat
	local retval, isrgn, pos, rgn_end, name, idx, color = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
	mrkr_idx = retval > 0 and not isrgn and mrkr_idx+1 or mrkr_idx -- this counting method is used to conform with the type of index expected by the GoToMarker() function
	rgn_idx = retval > 0 and isrgn and rgn_idx+1 or rgn_idx -- relic of the prev version because GoToRegion() was discarded
		if retval > 0 then
			if not USE_REGIONS and not isrgn then
				if not ret_pos and pos > ref_pos or ret_pos and pos == ret_pos then -- find 1st then look for overlaps
				ret_idx = mrkr_idx; ret_name = name; ret_pos = pos
			--	ref_time = ref_pos
				end
			elseif USE_REGIONS and isrgn then -- only search for continguous regions, for regions ref_pos is region end
				if pos <= ref_pos and rgn_end > ref_pos then
					if not ret_rgn_end or ret_rgn_end and rgn_end >= ret_rgn_end then -- find 1st then look for overlaps respecting the longest region
					ret_idx = rgn_idx; ret_name = name; ret_rgn_end = rgn_end;
					end

				end
			end
		end
	i = i+1
	until retval == 0 -- until no more markers/regions

	if not USE_REGIONS and ret_name then
		if not ret_name:lower():match(Esc(KEYWORD)) then -- no overlaps and no KEYWORD or overlaps, the last of which doesn't contain the KEYWORD, return because this one must be skipped to
		return ret_idx, ret_pos
		else -- no overlaps and KEYWORD or overlaps, the last of which contains the KEYWORD, search for the next until the one without the KEYWORD is found, because this one must be skipped over
		local ret_idx, ret_pos = Find_Next_MrkrOrRgn_By_Name(ret_idx, ret_pos, USE_REGIONS, KEYWORD)
		return ret_idx, ret_pos
		end
	elseif USE_REGIONS then
		if ret_name and ret_name:lower():match(Esc(KEYWORD)) then -- no overlaps and KEYWORD or overlaps, the last of which contains the KEYWORD, so is contigous, search for the next until a non-contiguous is found
		local ret_idx, ret_rgn_end = Find_Next_MrkrOrRgn_By_Name(ret_idx, ret_rgn_end, USE_REGIONS, KEYWORD)
		return ret_idx, ret_rgn_end
		else -- no overlaps and no KEYWORD or overlaps, the last of which doesn't contain the KEYWORD, return the same data which was fed in, because this region must not be skipped
		return ref_idx, ref_pos
		end
	end

end



function Monitor_MrkrsOrRgns(USE_REGIONS, ref_t)
local i, mrkr_idx, rgn_idx = 0, -1, -1 -- -1 to count as 0-based
	if not ref_t then
	local ref_t = {markrs={}, regns={}}
		repeat -- store markers and regions time properties
		local retval, isrgn, pos, rgn_end, name, idx, color = r.EnumProjectMarkers3(0, i) -- markers/regions are returned in the timeline order, if they fully overlap they're returned in the order of their displayed indices
		mrkr_idx = retval > 0 and not isrgn and mrkr_idx+1 or mrkr_idx -- this counting method is used to conform with the type of index expected by the GoToMarker() function
		rgn_idx = retval > 0 and isrgn and rgn_idx+1 or rgn_idx -- relic of the prev version because GoToRegion() was discarded
			if retval > 0 and not isrgn then
			ref_t.markrs[mrkr_idx] = ref_t.markrs[mrkr_idx] or {}
			ref_t.markrs[mrkr_idx].pos = pos; ref_t.markrs[mrkr_idx].name = name:lower():match(Esc(KEYWORD))
			elseif retval > 0 and isrgn then
			ref_t.regns[rgn_idx] = ref_t.regns[rgn_idx] or {}
			ref_t.regns[rgn_idx].pos = pos
			ref_t.regns[rgn_idx].rgn_end = rgn_end
			ref_t.regns[rgn_idx].name = name:lower():match(Esc(KEYWORD))
			end
		i = i+1
		until retval == 0
	return ref_t
	else
	repeat -- search for changes in markers and regions time properties
	local retval, isrgn, pos, rgn_end, name, idx, color = r.EnumProjectMarkers3(0, i)
	mrkr_idx = retval > 0 and not isrgn and mrkr_idx+1 or mrkr_idx -- this counting method is used to conform with the type of index expected by the GoToMarker() function
	rgn_idx = retval > 0 and isrgn and rgn_idx+1 or rgn_idx -- relic of the prev version because GoToRegion() was discarded
		if not USE_REGIONS and retval > 0 and not isrgn and ref_t.markrs[mrkr_idx] and (pos ~= ref_t.markrs[mrkr_idx].pos or name:lower():match(Esc(KEYWORD)) ~= ref_t.markrs[mrkr_idx].name)
		or USE_REGIONS and retval > 0 and isrgn and ref_t.regns[rgn_idx] and (pos ~= ref_t.regns[rgn_idx].pos or rgn_end ~= ref_t.regns[rgn_idx].rgn_end or name:lower():match(Esc(KEYWORD)) ~= ref_t.regns[rgn_idx].name)
		then
		return true
		end
	i = i+1
	until retval == 0
	end
end


USE_REGIONS = #USE_REGIONS:gsub(' ','') > 0
mrkr_idx, mrkr_pos, next_rgn_end = math.huge*-1, math.huge*-1, math.huge*-1 -- to get the routine going at the very start
local play_pos_init


function SKIP_MARKERS_OR_REGIONS()

local retval, mrkr_cnt, rgn_cnt = r.CountProjectMarkers(0)
local playback, recording = r.GetPlayState()&1 == 1, r.GetPlayState()&4 == 4
local count = not USE_REGIONS and mrkr_cnt or rgn_cnt

	if (playback or recording) and (not USE_REGIONS and mrkr_cnt > 1 or rgn_cnt > 0) then

	local play_pos = r.GetPlayPosition() -- GetPlayPosition2() is contantly being updated even without playback on // https://forum.cockos.com/showthread.php?t=273104

	ref_t = update and Monitor_MrkrsOrRgns(USE_REGIONS) or ref_t -- collect markers and regions time data, only update if there's change, otherwise updates constantly and change isn't detected; the function doesn't start right away since update is nil, first runs its another instance downstream, returns a table as update var which is true which then triggers this instance // allows reordering on the fly and maintaining correct functionality

		-- Update routine
		if mrkr_idx and mrkr_pos and mrkr_idx < count-1 and (not USE_REGIONS and skip and play_pos > mrkr_pos or USE_REGIONS and play_pos > next_rgn_end) or play_pos_init and play_pos < play_pos_init or update then -- after the last marker mrkr_pos and mrkr_idx will be nil hence must be evaluated to prevent error // only run once 1) after playhead crossed a marker or region end, marker/region start/name or region end changed; 2) before the last marker is reached or 3) when playhead is manually moved back; 'skip' var is required if markers are skipped after being passed, i.e. cond_t[2] is selected below, doesn't affect regions
		mrkr_idx, mrkr_pos, mrkr_name, rgn_end = Get_First_MarkerOrRgn_After_Time(play_pos, USE_REGIONS, KEYWORD) -- mrkr_idx, mrkr_pos, mrkr_name refer to region properties when USE_REGIONS is enabled
		next_mrkr_idx, next_rgn_end = Find_Next_MrkrOrRgn_By_Name(mrkr_idx, not USE_REGIONS and mrkr_pos or rgn_end, USE_REGIONS, KEYWORD) -- next_mrkr_idx, next_pos refer to region properties when USE_REGIONS is enabled
		play_pos_init = play_pos
		update = nil
		skip = nil -- reset, required if markers are skipped after being passed, i.e. cond_t[2] is selected below, doesn't affect regions
		end

local cond_t = {mrkr_pos and mrkr_pos > play_pos and mrkr_pos - play_pos <= 0.04, -- skip before marker/region start; 'mrkr_pos > play_pos' makes sure that skip only occurs when the marker is ahead of the playhead otherwise the playhead might get stuck at the last marker; 0.04 - the defer loop runs ca every 30 ms, so this value must be greater to be always detected
				mrkr_pos and play_pos >= mrkr_pos and play_pos - mrkr_pos <= 0.04} -- skip after marker/region end
local cond = cond_t[2] -- select 1 or 2		
		
		-- Skip routine
		if next_mrkr_idx and mrkr_name and mrkr_name:lower():match(Esc(KEYWORD)) and cond then
			if recording then r.CSurf_OnStop() end -- during recording playhead doesn't follow the edit cursor so it must be stopped
			if not USE_REGIONS then
			r.GoToMarker(0, next_mrkr_idx+1, true) -- use_timeline_order true; +1 because this function uses 1-based count whereas Get_First_MarkerOrRgn_After_Time() returns 0-based count // SetEditCurPos() could be used instead like it is used for regions below
			skip = true -- required if markers are skipped after being passed, i.e. cond_t[2] is selected above, doesn't affect regions
			else
			r.SetEditCurPos(next_rgn_end, true, true) -- moveview (only moves if the target is out of sight), seekplay true // r.GoToRegion() isn't suitable for this task due to the way it functions
			end
			if recording then r.CSurf_OnRecord() end -- resume recording
		end

		-- Check if marker/region positions changed
		update = Monitor_MrkrsOrRgns(USE_REGIONS, ref_t) -- search for changes in markers and regions time data; update is used as a condition in getting marker/region properties routine above // allows reordering on the fly and maintaining correct functionality

	end

r.defer(SKIP_MARKERS_OR_REGIONS)

end


	if Script_Not_Enabled(ENABLE_SCRIPT) then return r.defer(function() do return end end) end

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
Re_Set_Toggle_State(sect_ID, cmd_ID, 1)

KEYWORD = #KEYWORD:gsub(' ','') > 0 and KEYWORD:lower()

	if not KEYWORD then r.MB('The KEYWORD isn\'t defined', 'ERROR', 0) return r.defer(function() do return end end) end

SKIP_MARKERS_OR_REGIONS()

r.atexit(At_Exit_Wrapper(Re_Set_Toggle_State, sect_ID, cmd_ID, 0))





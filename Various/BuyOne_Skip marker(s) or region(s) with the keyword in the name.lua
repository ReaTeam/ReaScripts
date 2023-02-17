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
	setting in the USER SETTINGS.

	USING MARKERS

	Place one marker with the name containing the KEYWORD before the segment 
	to be skipped and another one without the KEYWORD at the end of such segment. 
	As soon as the play cursor reaches the 1st marker it will jump to the 2nd one.  
	If in between there're any markers whose name also contains the KEYWORD 
	the segment which follow will be skipped as well. So the play cursor skips
	to the first marker which doesn't contain the KEYWORD in the name following 
	a marker which does.

	USING REGIONS

	Encompass with a region a timeline segment which needs to be skipped 
	and add the KEYWORD to its name.   
	Once the play cursor reaches the start of the region whose name contains 
	the KEYWORD it will jump to such region's end thereby skipping it. If there're 
	several such regions in a row with no gaps, the play cursor jumps to the end 
	of the last one which precedes a region without the KEYWORD in its name 
	or the end of the project.  
	If the script is launched while the play cursor is within a region which 
	contains the KEYWORD in its name, such region won't be marked for skipping. 
	Only regions which lay ahead of the play cursor are detected for skipping.

	RECORDING

	Recording will be done in segments. After skipping a marker or a region 
	a new segment will begin. The start time of the next segment will depend 
	on the pre-roll setting available in the Metronome configuration window. 
	If pre-roll isn't enabled the recording will start as soon as the play cursor 
	jumps to another marker or a region end.

	It's not recommended to move markers and regions around or change regions 
	bounds during playback or recording because their data are only updated after 
	skipping. If they're moved beforehand the target point won't change and 
	the play cursor will end up at the location which may not correspond 
	to the new marker / region end position. If you do move them around, then 
	the script might need re-starting.

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


function Get_First_MarkerOrRgn_After_Time(time, USE_REGIONS) -- time in sec
local i, mrkr_idx, rgn_idx = 0, -1, -1 -- -1 to count as 0-based
	repeat
	local retval, isrgn, pos, rgn_end, name, idx, color = r.EnumProjectMarkers3(0, i)
	mrkr_idx = retval > 0 and not isrgn and mrkr_idx+1 or mrkr_idx
	rgn_idx = retval > 0 and isrgn and rgn_idx+1 or rgn_idx
		if retval > 0 then
			if pos > time and not USE_REGIONS and not isrgn then return mrkr_idx, pos, name
			elseif USE_REGIONS and isrgn and pos > time then return rgn_idx, pos, name, rgn_end -- playhead is before the region start
			end
		end
	i = i+1
	until retval == 0 -- until no more markers/regions
end


function Esc(str)
	if not str then return end -- prevents error
-- isolating the 1st return value so that if vars are initialized in a row outside of the function the next var isn't assigned the 2nd return value
local str = str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return str
end


function Find_Next_MrkrOrRgn_By_Name(ref_idx, ref_rgn_end, ref_name, USE_REGIONS) -- or by the lack of elements in the name; ref_idx is 0-based

local i, mrkr_idx, rgn_idx = 0, -1, -1 -- -1 to count as 0-based
local rgn_t = {}
	repeat
	local retval, isrgn, pos, rgn_end, name, idx, color = r.EnumProjectMarkers3(0, i)
	mrkr_idx = retval > 0 and not isrgn and mrkr_idx+1 or mrkr_idx
	rgn_idx = retval > 0 and isrgn and rgn_idx+1 or rgn_idx
		if retval > 0 then
			if not USE_REGIONS and not isrgn and ref_idx and mrkr_idx > ref_idx and not name:lower():match(Esc(ref_name)) then return mrkr_idx, pos
			elseif USE_REGIONS and isrgn and ref_idx and rgn_idx > ref_idx then
			local name_match = name:lower():match(Esc(ref_name))
				if pos > ref_rgn_end and rgn_idx-1 == ref_idx then return ref_idx, ref_rgn_end -- if there's a gap between the upcoming region with the KEYWORD in the name which will be evaluated in the skip routine, and the one which immediately follows, return the upcoming region end to resume playback/recording after it
				elseif next(rgn_t) and name_match and pos > rgn_t.rgn_end and rgn_idx-1 == rgn_t.rgn_idx then return rgn_t.rgn_idx, rgn_t.rgn_end -- if there's a gap between one of the regions with the KEYWORD which follow the upcoming region, return the data of the last one before the gap
				end
				if name_match then rgn_t.rgn_idx = rgn_idx; rgn_t.rgn_end = rgn_end -- continuously collect data of the last region whose name does contain the KEYWORD until the one whose name doesn't is found
				elseif next(rgn_t) then return rgn_t.rgn_idx, rgn_t.rgn_end -- return the data of the last region with the KEYWORD in the name once first region without the KEYWORD in the name is found, to move the edit cursor to the end of such last region
				end
			end
		end
	i = i+1
	until retval == 0 -- until no more markers/regions

return ref_idx, ref_rgn_end -- return upcoming region data fed in with the arguments if none of the conditions set in the routine were met, meaning the playhead will only skip the upcoming region

end


USE_REGIONS = #USE_REGIONS:gsub(' ','') > 0
mrkr_idx, mrkr_pos, rgn_end = math.huge*-1, math.huge*-1, math.huge*-1 -- to get the routine going at the very start
local play_pos_init

function SKIP_MARKERS_OR_REGIONS()

local retval, mrkr_cnt, rgn_cnt = r.CountProjectMarkers(0)
local playback, recording = r.GetPlayState()&1 == 1, r.GetPlayState()&4 == 4
local count = not USE_REGIONS and mrkr_cnt or rgn_cnt

	if (playback or recording) and (not USE_REGIONS and mrkr_cnt > 1 or rgn_cnt > 0) then

	local play_pos = r.GetPlayPosition() -- GetPlayPosition2() is contantly being updated even without playback on

		if mrkr_idx and mrkr_pos and mrkr_idx < count-1 and (play_pos > mrkr_pos or USE_REGIONS and play_pos > rgn_end) or play_pos_init and play_pos < play_pos_init then -- after the last marker mrkr_pos and mrkr_idx will be nil hence must be evaluated to prevent error // only run once 1) after playhead crossed a marker/region start or is located within the region in case playback/recording started when it was within the region, 2) before the last marker is reached or 3) when playhead is manually moved back
		mrkr_idx, mrkr_pos, mrkr_name, rgn_end = Get_First_MarkerOrRgn_After_Time(play_pos, USE_REGIONS) -- mrkr_idx, mrkr_pos, mrkr_name refer to region properties when USE REGIONS is enabled
		next_mrkr_idx, next_rgn_end = Find_Next_MrkrOrRgn_By_Name(mrkr_idx, rgn_end, KEYWORD, USE_REGIONS) -- next_mrkr_idx refer to region properties when USE REGIONS is enabled
		play_pos_init = play_pos
		end

		-- Skip routine
		if next_mrkr_idx and mrkr_name and mrkr_name:lower():match(Esc(KEYWORD)) and mrkr_pos > play_pos and mrkr_pos - play_pos <= 0.04 then -- mrkr_pos > play_pos makes sure that jump only occurs when the marker is ahead of the playhead otherwise the playhead might get stuck at the last marker; 0.04 - the defer loop runs ca every 30 ms, so this value must be greater to be always detected
			if recording then r.CSurf_OnStop() end -- during recording playhead doesn't follow the edit cursor so it must be stopped
			if not USE_REGIONS then r.GoToMarker(0, next_mrkr_idx+1, true) -- use_timeline_order true; +1 because this function uses 1-based count whereas Get_First_MarkerOrRgn_After_Time() returns 0-based count
			else
			r.SetEditCurPos(next_rgn_end, true, true) -- moveview, seekplay true // r.GoToRegion() isn't suitable for this task due to the way it functions
			end
			if recording then r.CSurf_OnRecord() end -- resume recording
		end
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



--[[
ReaScript name: Scroll named track into view in the Mixer
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M for best performance
About:
		As the name suggests, scrolls track with the name, specified
		in the USER SETTINGS into view in the Mixer.
		
		Although can be used by itself, originally was meant to enhance
		Mixer screensets by including in a roundabout way position 
		of certain tracks in the Mixer, because screensets don't store that 
		data with them. And especially with mix templates to quickly access
		different groups of tracks by track name.  
		SWS extension 'Find' tool can bring a track into view in the Mixer
		by name but it requires typing, exclusively selects the track, and
		the track is only placed in the leftmost position in the Mixer.
		
		With this script tracks can be scrolled to the leftmost, the rightmost 
		and central positions in the Mixer according to the POSITION setting.   
		When the Master track is visible in the Mixer the left- and the rightmost
		positions mean to the right and to the left of the Master track respectively.
		
			U S A G E   W I T H   S C R E E N S E T S
		
		1. In the TRACK_NAME setting specify the name of the track
		you want to be scrolled into view in the Mixer when a screenset
		is loaded.

		2. Create a custom action with the native screenset action
		and the script in it placed in the following order, e.g.:
			Screenset: Load window set #1  
			Scroll named track into view in the Mixer.lua

		3. Use such custom action to load the screenset.
		
		The screenset itself can be saved the regular way but loaded with 
		such custom action whenever you need specific track to be visible
		at the preferred position when the Mixer is opened or when you need 
		to bring the track back into view while the Mixer is already open.

		The script can be duplicated for each track which needs to be scrolled
		into view and then each script instance be included in a separate 
		custom action containing the same screenset action to be used 
		for loading a Mixer screenset while having the Mixer scroll to different 
		tracks. Which basically makes the screenset granular at a track position 
		level in the Mixer.

		If needed the screenset can be loaded directly with the script when
		its number is specified in the SCREENSET setting. Possible disadvantage
		is that the script becomes hard linked with the screenset number.

		It's recommended to have the SWS/S&M extension installed so that all
		3 track scroll positions are available regardless of the Mixer window size 
		and of its being docked. If not installed, only the leftmost position will
		be available regardless of the actual POSITION setting.
				
		CAVEATS

		The Mixer will not scroll track into the position defined in the USER SETTINGS
		if there're too few tracks or their combined MCPs are too narrow to allow 
		sufficient distance for scrolling.
		
		When the scroll position is the rightmost, one or more extra tracks (depending
		on their MCP width) may be revealed on the right side of the Mixer besides 
		the target track, because the visible tracks may not necessarily fit exactly 
		within the Mixer window. This is especially relevant for setups with mixed 
		MCP layouts due to difference in their widths.
		
		Mind that as of build 6.38 the Mixer window is global for all projects open in tabs,
		just the contents differ. Therefore changing Mixer scroll position in one such project
		will affect it across all open projects.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Insert target track name between the double square brackets,
-- e.g [[My track]]
-- Insert position value between the quotation marks, see legend.
-- Insert screenset number between the quotation marks, only if you intend
-- to use the script to load the screenset rather than combine it with native
-- 'Screenset: Load window set #...' action inside a custom action
-- In the custom action the script must FOLLOW the native action

TRACK_NAME = [[]] -- preferably unique in your project/mix template to avoid confusion
POSITION = "" -- C/c = center, R/r = rightmost, otherwise = leftmost
SCREENSET = "" -- 1 through 10

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function re_store_sel_trks(t)
	if not t then
	local sel_trk_cnt = reaper.CountSelectedTracks2(0,1) -- plus Master
	local trk_sel_t = {}
		if sel_trk_cnt > 0 then
		local i = sel_trk_cnt -- in reverse because of deselection
			while i > 0 do
			local tr = r.GetSelectedTrack2(0,i-1,true) -- plus Master
			trk_sel_t[#trk_sel_t+1] = tr
			r.SetTrackSelected(tr, 0) -- unselect each track
			i = i-1
			end
		end
	return trk_sel_t
	elseif t and #t > 0 then
	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	r.SetTrackSelected(r.GetMasterTrack(0),0) -- unselect Master
		for _,v in next, t do
		r.SetTrackSelected(v,1)
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	end
end

function space(n) -- number of repeats
return string.rep(' ',n)
end

function ACT(comm_ID) -- both string and integer work
r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end


function Scroll_Track_Into_View(targ_tr, loc) --  loc corresponds to POSITION var from the USER SETTINGS
-- Leftmost track left edge value in pixels is 0, values further to the left (out of sight) are negative, to the right - posititive
-- Being set with the function SetMixerScroll() the leftmost track is always displayed in full which may cause the rightmost track be partially shifted beyond the Mixer right edge or the Master track if it's displayed on the right side (because MCPs combined width doesn't fit within the Mixer window); this is mitigated by shifting the target track back leftwards which is a trade-off and may reveal one or more extra tracks on the right, depending on the width of the leftmost track

local sws = r.APIExists('BR_Win32_GetMainHwnd')
local mixer_hwnd = r.BR_Win32_GetMixerHwnd() -- used outside of BR_Win32_GetWindowRect since it returns two values
local dimens = sws and {r.BR_Win32_GetWindowRect(mixer_hwnd)} or {r.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)}

	if #dimens == 5 then table.remove(dimens, 1) end -- remove retval from BR's function

local loc = sws and loc or '' -- clamp position to the leftmost if no SWS extension because two other positions won't work anyway in floating and resized Mixer window
local targ_tr_w = r.GetMediaTrackInfo_Value(targ_tr, 'I_MCPW')
local master_vis = r.GetToggleCommandState(41209) == 1 -- Mixer: Master track visible

local pos = loc == 'C' and (dimens[3] - dimens[1])/2 or loc == 'R' and dimens[3] - dimens[1] or 0 -- center or right (accounting for reduced window size) or left

-- Since track layouts may have different width plus some may stop flush at the right edge but others may not a mechanism is employed to shift the position back to the left which may reveal additional tracks on the right depending on MCP widths
-- When target position is center or right but there're not enough tracks which come before the target track or their comdined width isn't enough to fill up the space between the left edge or the Master track and the target track, the target track will be placed only as far to the right as the conditions permit
-- When there're too few tracks or their combined MCPs width is too narrow no scrolling will take place

local master_w = master_vis and loc == 'R' and r.GetMediaTrackInfo_Value(r.GetMasterTrack(0), 'I_MCPW') or 0 -- account for the Master track when visible because it doesn't scroll; only when target scroll position is rightmost to avoid target track being partially visible at the program window right-hand edge or hide behind the Master when it's on the right side
r.SetMixerScroll(targ_tr) -- start out having placed the target track at the leftmost position, then move rightwards
local i = r.CSurf_TrackToID(targ_tr, true)-2 -- start looping from the track immediately preceding the target track
	while r.GetMediaTrackInfo_Value(targ_tr, 'I_MCPX') + targ_tr_w < pos - master_w do -- OR ... + master_w < pos -- loop until the right edge of the target track goes past the target scroll point defined with loc
	tr = r.GetTrack(0,i) -- must stay global to be evaluated outside of the loop
		if not tr then break end -- when all tracks preceding the target track have been traversed before target position has been reached due to the tracks being either too few or their combined MCPs being too narrow
	r.SetMixerScroll(tr)
	i = i - 1
	end
-- The loop exits with the X coordinate of the target track right edge being greater than the target scroll position; now correct it by bringing it back leftwards to the point immedialtely preceding the target scroll point, especially relevant for target position being rightmost in which case the track goes beyond the right edge of the window
	if tr ~= targ_tr -- or pos == 0; ignore target track when pos is 0 due to being leftmost so as to not compare the track to itself when it's already at the correct pos
	and r.GetMediaTrackInfo_Value(targ_tr, 'I_MCPX') + targ_tr_w + master_w - pos > 10 -- track right edge X coordinate is greater than the target scroll position by 10 px, 10 or less is acceptable since the MCP is mostly visible
	then return r.GetTrack(0,i+2) -- return the correcting track to bring the target track back to the left by one track // +2 because the shift is required by 1 track from the current, but before the loop exits i value gets reduced by 1 which corresponds to the one before the current
	else return r.GetTrack(0,i+1)
	end

end


function Set_Mixer_Scroll()
-- Inside a custom action alongside 'Screenset: Load window set #...' action the script manages to make the Mixer scroll but then reaper.ini settings appear to kick in and Mixer scroll reverts to position stored previously if it wasn't at the target track, this happens instantaneously and could only be noticed with 'Action: Wait X seconds' action placed last in the custom action sequence, so defer() is meant to override that by keeping the scroll pushed to the target track past the moment of reversal to reaper.ini (?) settings; this doesn't happen if a screenset is loaded via a script such as 'Screenset; Save-Load window set #n with Mixer scroll position'
r.SetMixerScroll(tr)
	if r.time_precise() - start < .100 then r.defer(Set_Mixer_Scroll) end
end


TRACK_NAME = #TRACK_NAME:gsub(' ','') > 0 and TRACK_NAME
SCREENSET = #SCREENSET:gsub(' ','') > 0 and tonumber(SCREENSET) and tonumber(SCREENSET) > 0 and tonumber(SCREENSET) < 11 and ({math.modf(tonumber(SCREENSET))})[2] == 0 and SCREENSET or #SCREENSET:gsub(' ','') > 0 and 'Invalid screenset number — "'..tostring(SCREENSET)..'"' or SCREENSET -- the last is empty setting


	if #SCREENSET > 2 then r.MB(SCREENSET, 'ERROR', 0) return r.defer(function() end) end

	-- L O A D ===============================================================================

	if TRACK_NAME or SCREENSET then

POSITION = POSITION:gsub(' ',''):upper() -- make case ignorant
POSITION = (POSITION:match('[CR]') or #POSITION == 0) and POSITION or '' -- leftmost is the fallback

	r.PreventUIRefresh(1) -- seems to have no affect

		if SCREENSET then
		local id = 404 -- 1st three digits of save/load screenset actions command IDs
		local t = {54, 55, 56, 57, 58, 59, 60, 61, 62, 63} -- Screenset: Load window set #.. actions
		local id = tostring(id)..tostring(t[tonumber(SCREENSET)]) -- concatenate full 'Screenset: Load window set #..' action command ID
		ACT(id) -- load screenset
		end

	-- When the option 'Scroll view when tracks activated' is enabled in the Mixer settings and the Mixer is initially closed, native SetMixerScroll() function only works when the target track is the last touched before Mixer gets to be open, otherwise the option needs to be temporarily disabled: METHODS II-abc and I-ab respectively below; with the said option ON SetMixerScroll() function only works if the Mixer is already open, target track doesn't have to be selected

		if TRACK_NAME then

		--[[-- METHOD I-a (temporarily disable the option)
		local on = r.GetToggleCommandStateEx(0, 40221) == 1 -- Mixer: Toggle scroll view when tracks activated
		local set_off = on and r.Main_OnCommand(40221,0) -- turn 'Scroll view when tracks activated' off
		]]

		local sel_trks_t = re_store_sel_trks() -- store sel tracks and unselect all	// METHOD II-a (make target track last touched)

			for i = 0, r.CountTracks(0)-1 do -- scroll view to the saved track
			tr = r.GetTrack(0,i) -- will be used outside of the loop and in the deferred Set_Mixer_Scroll() function if target track
			local name = tr and {r.GetTrackName(tr)} -- 2 return values
				if name and TRACK_NAME and name[2] == TRACK_NAME then
				tr = Scroll_Track_Into_View(tr, POSITION)
				--------------- METHOD II-b --------------
				r.SetOnlyTrackSelected(tr) -- OR r.SetTrackSelected(tr, 1) since all are deselected with the re_store_sel_trks() function
				ACT(40914) -- Track: Set first selected track as last touched track // the only way to make sure target track is the last touched is to deselect all, select the track and set it as last touched
				--]]----------------------------------------
				break end
			end

		start = r.time_precise()
		Set_Mixer_Scroll() -- deferred function

		--[[-- METHOD I-b
		local set_on = on and r.Main_OnCommand(40221,0) -- Mixer: Toggle scroll view when tracks activated // turn back on
		]]

		re_store_sel_trks(sel_trks_t) -- METHOD II-c

		end

	r.PreventUIRefresh(-1) -- seems to have no affect

	return r.defer(function() end) end

r.Undo_BeginBlock() -- to make r.defer(function() end) work otherwise either generic undo point is created or one is generated by the action 'Track: Set first selected track as last touched track'
r.Undo_EndBlock('', -1)






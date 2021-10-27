--[[
ReaScript name: Save-Load window set #1-10 with Mixer scroll position (10 scripts)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Extensions: SWS/S&M for best performance
Metapackage: true
Provides: 
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #1 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #2 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #3 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #4 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #5 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #6 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #7 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #8 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #9 with Mixer scroll position (guide inside).lua
		[main] . > Save-Load window set #1-10 with Mixer scroll position/Save-Load window set #10 with Mixer scroll position (guide inside).lua		
About:	
		To be used instead of native 'Screenset: Save/Load window set #[number]' actions
		in situations where track position in the Mixer is important. Position means
		the leftmost, center and the rightmost.   
		The script does both:  
		a) concurrently with saving the actual screenset stores the track 
		to be scrolled into view when the Mixer is opened with the screenset 
		whose number is included in the script name; and      
		b) loads the screenset scrolling the associated track into view.		
		
		To save a screenset with a track to be scrolled into view in the Mixer:  
		1) make sure that the track which is supposed to be scrolled into view 
		on opening has a name and it's unique to avoid confusion;   
		2) open the Mixer and either select the target track or make it 
		the leftmost;  
		3) open 'Screensets/Layout' window (is used to signal to the script 
		that saving needs to be performed, it's not stored in screensets);   
		4) run the script ('Screensets/Layout' window will auto-close);   
		5) 'Save Windows Screenset' dialogue will appear. 
		On Windows once you click save in the 'Save Windows Screenset' dialogue, 
		the chosen track name will be stored concurrenty with the screenset (re)saving. 
		If the dialogue is cancelled no storage occurs.   
		On MacOS and on Linux track name storage will have to be manually 
		confirmed or declined via a dialogue which will appear once 'Save Windows Screenset' 
		dialogue closes. That's because without access to MacOS or Linux i couldn't 
		devise the same way of track name storage as on Windows.
				
		To change track name associated with a screenset, load the screenset 
		and follow the abovelisted steps.  
		On Windows track name is only stored if the screenset itself 
		is re-saved even with no changes to it.   
		On MacOS and on Linux they can be stored independently thanks to the 
		additional dialogue, which turns out to be both the curse and the 
		blessing so to speak.
		
		When storing, selected track gets preference, when no track is selected 
		the script looks for the leftmost track in the Mixer.   
		If 'Screensets/Layout' window isn't open while the Mixer is open, the script 
		will work in screenset loading mode provided there's a stored track name.
				
		To determine the position to scroll the track to, the script evaluates the 
		track displayed name. By default without any tags in its name the track is 
		scrolled to the leftmost position. To change that precede the track displayed 
		name with a scroll tag in the following format: C/c> (center); R/r> (rightmost)
		e.g. "C> My track name"   
		The register of the characters doesn't matter hence both types are listed.
		To have the track scroll into view at the start of the Mixer (leftmost position)
		when its name is already tagged, it suffices to strip the scroll tag of the 
		letter, leaving only the greater '>' sign intact, e.g. "> My track name".
		
		To load the screenset and scroll into view a track whose name was stored,
		run the script.
		
		After saving the screenset using this script, if the need arises to modify 
		the screenset by changing Mixer dock state, window size, it can be done
		the usual way via the corresponding action or 'Screensets/Layouts window',
		but loaded this screenset must still be with this script.
		
		The script is linked to the track name, so if the stored name is applied 
		to a different track, it will become the one to be scrolled into view in the Mixer 
		when the screenset is loaded, provided the name isn't shared with any other track.
		
		It's recommended to have the SWS/S&M extension installed so that all
		3 track scroll positions are available regardless of the Mixer window size 
		and of its being docked. If not installed, only the leftmost position will
		be available regardless of the actual scroll tag in the track displayed name.
				
		CAVEATS
		
		If there're too few tracks on either end of the tracklist or their combined MCPs 
		are too narrow to allow sufficient distance for scrolling, the stored track will 
		be placed only as close to the target position as conditions permit.
		
		Generally the relative placement of a track at the center and on the right side 
		of the Mixer is accurate. But it still depends on the stored track and adjacent 
		tracks MCP width especially with a tracklist mixed in terms of MCP layouts. 
		Therefore at times some track may appear slightly off center or slightly to the 
		left of the right edge instead of being flush with it.   
		However in determining track placement its visibility is given top priority.
		At the leftmost position the track is always flush with the left edge of the 
		window or with the Master track simply because at this position REAPER doesn't 
		allow partial display of MCP.
		
		Mind that as of build 6.38 the Mixer window is global for all projects 
		open in tabs, just the contents differ. Therefore changing Mixer scroll 
		position in one such project will affect it across all open projects.
		
		* * *
		Check out also BuyOne_Scroll named track into view in the Mixer (guide inside).lua
		for a method of scrolling named track into view without hard linking between
		track name and screenset number.
		
]]



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

function Esc(str)
return str:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
end

function get_file_timestamp(full_file_path) -- time with seconds
local dir, file_name = full_file_path:match('(.+)[\\/](.+)') -- makes sure that dir doesn't end with separator
local dir = #dir == 3 and dir or '"'..dir..'"' -- when not root as root doesn't allow quotes
return r.ExecProcess('forfiles /P '..dir..' /M "'..file_name..'" /C "cmd /c echo @fdate @ftime"', 0):match('.+\n(.+)\n')
end

function Scroll_Track_Into_View(targ_tr, loc) -- loc corresponds to pos var from the main routine
-- Leftmost track left edge X value in pixels is 0, values further to the left (out of sight) are negative, to the right - posititive
-- Being set with the function SetMixerScroll() the leftmost track is always displayed in full which may cause the rightmost track be partially shifted beyond the Mixer right edge or the Master track if it's displayed on the right side (because MCPs combined width doesn't fit within the Mixer window); this is mitigated by shifting the target track back leftwards which is a trade-off and may reveal one or more extra tracks on the right, depending on the width of the leftmost track

local sws = r.APIExists('BR_Win32_GetMainHwnd')
local mixer_hwnd = r.BR_Win32_GetMixerHwnd() -- used outside of BR_Win32_GetWindowRect since it returns two values
local dimens = sws and {r.BR_Win32_GetWindowRect(mixer_hwnd)} or {r.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)}

	if #dimens == 5 then table.remove(dimens, 1) end -- remove retval from BR's function

local loc = sws and loc or '' -- clamp position to the leftmost if no SWS extension because two other positions won't work anyway in floating and resized Mixer window

local pos = loc == 'C' and (dimens[3] - dimens[1])/2 or loc == 'R' and dimens[3] - dimens[1] or 0 -- center or right (accounting for reduced window size) or left

-- Since track layouts may have different width plus some may stop flush at the right edge but others may not a mechanism is employed to shift the position back to the left which may reveal additional tracks on the right depending on MCP widths
-- When target position is center or right but there're not enough tracks which come before the target track or their comdined width isn't enough to fill up the space between the left edge or the Master track and the target track, the target track will be placed only as far to the right as the conditions permit
-- When there're too few tracks or their combined MCPs width is too narrow no scrolling will take place

local targ_tr_w = r.GetMediaTrackInfo_Value(targ_tr, 'I_MCPW')
local master_vis = r.GetToggleCommandState(41209) == 1 -- Mixer: Master track visible
local master_rt = r.GetToggleCommandState(40389) == 1 -- Mixer: Toggle show master track on right side
local master_w = (master_vis and not master_rt or master_vis and master_rt and loc == 'R') and r.GetMediaTrackInfo_Value(r.GetMasterTrack(0), 'I_MCPW') or 0 -- only account for the Master track when it's on the left side and when on the right side while loc is 'R' since in the latter case it doesn't affect leftmost and central positions

local targ_tr_x = r.GetMediaTrackInfo_Value(targ_tr, 'I_MCPX') + targ_tr_w -- targ_tr X on the right
local tr
local tr_x
local abs = math.abs
local i = r.CSurf_TrackToID(targ_tr, true)-2 -- start looping from the track immediately preceding the target track backwards
	repeat
	tr = r.GetTrack(0,i)
		tr_x = tr and r.GetMediaTrackInfo_Value(tr, 'I_MCPX') or 0
	i = i - 1
	until abs(tr_x - targ_tr_x) > pos - master_w or not tr -- accounting for negative X when tracks are beyond Master track on the left side or beyond the left edge and for cases when the target track is at zero point or when there're two few tracks which precede it (not tr)
	
-- The loop exits with the X coordinate of the target track right edge being greater than the target scroll position; now correct it by bringing it back leftwards to the point immedialtely preceding the target scroll point, especially relevant for target position being rightmost in which case the track goes beyond the right edge of the window
	
	if tr and (loc == 'R' and abs(tr_x - targ_tr_x) + master_w - pos > 5 -- targ track right edge X coordinate is greater than the position by 5 px, 5 or less is acceptable since the MCP is mostly visible, and 5 is optimal for MCP strips which are quite narrow
	or abs(tr_x - targ_tr_x) + master_w - pos > pos - abs(r.GetMediaTrackInfo_Value(r.GetTrack(0,i+2), 'I_MCPX') - targ_tr_x) - master_w) -- only correct if the resulting targ track right X will be closer to the position than the targ track right X obtained after the loop; why +2 see below // works for pos 0
	then return r.GetTrack(0,i+2) -- return the correcting track to bring the target track back to the left by one track // +2 because the shift is required by 1 track from the current after the loop, but before the loop exits i value gets reduced by 1 which corresponds to the one before the current and -2nd from the target track if position is 0
	elseif tr then return r.GetTrack(0,i+1)
	else return r.GetTrack(0,0)  -- when there're too few tracks or their MCPs are too narrow to scroll to the central or the rightmost position, scroll to the very 1st track to shift the target track as far as possible
	end

end


function Set_Mixer_Scroll()
-- When the screenset is opened script manages to make the Mixer scroll with the native SetMixerScroll() function alone but then reaper.ini settings appear to kick in and Mixer scroll reverts to position stored previously if it wasn't at the target track, this happens instantaneously and can only be noticed if the script is paused before exiting, so defer() is meant to override that by keeping the scroll pushed to the target track past the moment of reversal to reaper.ini (?) settings; this doesn't happen if a screenset is loaded via a script such as 'Screenset; Save-Load window set #n with Mixer scroll position'
r.SetMixerScroll(tr)
	if r.time_precise() - start < .100 then r.defer(Set_Mixer_Scroll) end
end


--- START MAIN ROUTINE


local id = 404 -- 1st three digits of save/load screenset actions command IDs
local context = {r.get_action_context()}
local scr_name = context[2]:match('[^\\/]+_(.+)%.lua$')
local set_num = tonumber(context[2]:match('[^\\/_].+#(%d+)')) -- get set # from script name

local stored_tr_name = r.GetExtState(scr_name, 'scroll_2_track')

local not_mixer = r.GetToggleCommandStateEx(0, 40078) == 0 -- View: Toggle mixer visible
local not_screenset = r.GetToggleCommandStateEx(0, 40422) == 0 -- View: Show screen/track/item sets window

	-- S A V E ==============================================================================

	if #stored_tr_name == 0 or (not not_mixer and not not_screenset) then -- no stored track or both Mixer and 'Screensets/Layouts' window are open

	----- PRELIMINARY CHECKS AND USER MESSAGES -----

	local part1 = space(7)..'In order to be able to save\n\na screenset with Mixer scroll position\n\n'
	local part2 = 'Should it be opened now?\n\n  (run the script again afterwards)'
	local mess = not_mixer and not_screenset -- View: Show screen/track/item sets window
	and part1..'both Mixer and "Screensets/Layouts"\n\n'..space(12)..'window must be open.\n\n'..space(6)..part2:gsub('it', 'they')
	or not_mixer and part1..space(10)..'the Mixer must be open.\n\n'..space(9)..part2
	or not_screenset and part1..space(10)..'"Screensets/Layouts"\n\n'..space(10)..'window must be open.\n\n'..space(7)..part2

	local tr = r.GetSelectedTrack(0,0) or r.GetMixerScroll()
	local tr_name = tr and {r.GetSetMediaTrackInfo_String(tr, 'P_NAME', '', false)} or {} -- r.GetTrackName(tr, '') returns 'Track #' when no name so is inconvenient here

	local mess = not mess and #tr_name[2]:gsub(' ','') == 0 and '\tEither first selected track\n\n   or the leftmost in the Mixer has no name.' or mess
		if not mess then -- find if there're identically named tracks, to throw a warning
			for i = 0, r.CountTracks(0)-1 do
			local some_tr = r.GetTrack(0,i)
			local name_t = some_tr and {r.GetTrackName(some_tr)} -- 2 return values
				if name_t and tr_name[2]:match('[%sCcRr>]*(.+)%s*') == name_t[2]:match('[%sCcRr>]*(.+)%s*') -- compare names ignoring scroll tag (e.g. >C) to prevent storing tracks named identically if scroll tag is disregarded
				and some_tr ~= tr then
				mess = 'Track #'..tostring(i+1)..' has the same name as the chosen track.\n\n\tMake sure the name is unique.' break end
			end
		end

		if mess then resp = r.MB(mess, 'Screenset save ERROR', mess:match('open') and 4 or 0)
			if resp == 6 then
				if mess:match('both') or not_mixer then ACT(40078) end -- View: Toggle mixer visible
				if mess:match('both') or not_screenset then ACT(40422) end -- View: Show screen/track/item sets window
			end
		return r.defer(function() end) end

	----- SAVING ROUTINE -----

	local off = r.GetToggleCommandStateEx(0, 40422) == 1 and r.Main_OnCommand(40422, 0) -- View: Show screen/track/item sets window // close screensets window

	local f_path = r.GetResourcePath()..r.GetResourcePath():match('[\\/]')..'reaper-screensets.ini'
	local screenset_timestamp = get_file_timestamp(f_path) -- check reaper-screensets.ini current timestamp in order to compare downstream to condition storing track name in extended state depending on whether screenset was updated accounting for cases when screenset save dialogue was aborted; mainly relevant for the first ever storing track name

	local t = {74, 75, 76, 77, 78, 79, 80, 81, 82, 83} -- Screenset: Save window set #.. action

	local id = tostring(id)..tostring(t[set_num]) -- concatenate full 'Screenset: Save window set #..' action command ID

	r.Main_OnCommand(id, 0) -- Screenset: Save window set #..

	local win = r.GetOS():match('Win')
	local tr_name = tr_name[2]:match('[%sCcRr>]*(.+)%s*') -- strip away the scroll tag for storing

		if not win then resp = r.MB('Wish to store the track name "'..tr_name..'" ?','MacOS and Linux User Prompt', 1) end

		if win and get_file_timestamp(f_path) ~= screenset_timestamp -- on Win only save ext state when screenset was saved instead of being canceled which will reflect in reaper-screenset.ini timestamp
		or not win and resp == 1 -- confirmed manually by a MacOS or Linux user
		then r.SetExtState(scr_name, 'scroll_2_track', tr_name, true) -- persist is true
		end

	-- L O A D ===============================================================================

	elseif #stored_tr_name > 0 then

	r.PreventUIRefresh(1) -- seems to have no affect

	local t = {54, 55, 56, 57, 58, 59, 60, 61, 62, 63} -- Screenset: Load window set #.. actions

	-- LOAD SCREENSET WITH MIXER, the Mixer must first be opened for the scrolling routine to succeed
	local id = tostring(id)..tostring(t[set_num]) -- concatenate full 'Screenset: Load window set #..' action command ID
	ACT(id) -- load screenset

	-- When the option 'Scroll view when tracks activated' is enabled in the Mixer settings and the Mixer is initially closed, SetMixerScroll() function only works when the target track is the last touched before Mixer gets to be open, otherwise the option needs to be temporarily disabled: METHODS II-abc and I-ab respectively below; with the said option ON the function only works if the Mixer is open, target track doesn't have to be selected

	--[[ -- METHOD I-a (temporarily disable the option)
	local on = r.GetToggleCommandStateEx(0, 40221) == 1 -- Mixer: Toggle scroll view when tracks activated
	local set_off = on and r.Main_OnCommand(40221,0) -- turn 'Scroll view when tracks activated' off
	]]

	local sel_trks_t = re_store_sel_trks() -- store sel tracks and unselect all	// METHOD II-a
		for i = 0, r.CountTracks(0)-1 do -- scroll stored track into view
		tr = r.GetTrack(0,i) -- will be used outside of the loop and in the deferred Set_Mixer_Scroll() function if target track
		name_t = tr and {r.GetTrackName(tr)} -- 2 return values; global to be evaluated below
			if name_t and --name_t[2] == stored_tr_name
			stored_tr_name == name_t[2]:match('[%sCcRr>]*(.+)%s*') -- compare names ignoring scroll tag (e.g. C>) to allow respecting the track current scroll tag
			then local pos = name_t[2]:upper():match('%s*([CR])>') or '' -- fetch from displayed track name // if not center or rightmost it's leftmost
			tr = Scroll_Track_Into_View(tr, pos) -- keep global
			--------------- METHOD II-b --------------
			r.SetOnlyTrackSelected(tr) -- OR r.SetTrackSelected(tr, 1) since all are deselected with the re_store_sel_trks() function
			ACT(40914) -- Track: Set first selected track as last touched track // the only way to make sure target track is the last touched is to deselect all, select the track and set it as last touched
			------------------------------------------
		--	tr = Scroll_Track_Into_View2(tr, pos) -- can also be placed here
			break end
		end

		if stored_tr_name ~= name_t[2]:match('[%sCcRr>]*(.+)%s*') then re_store_sel_trks(sel_trks_t) return r.defer(function() end) end -- don't scroll the Mixer unnecessarily if track name wasn't found

	start = r.time_precise() -- to compare against inside the next function; must be global so the deferred function can access it
	Set_Mixer_Scroll() -- deferred function

	--[[ -- METHOD I-b
	local set_on = on and r.Main_OnCommand(40221,0) -- -- Mixer: Toggle scroll view when tracks activated // turn back on
	]]

	re_store_sel_trks(sel_trks_t) -- METHOD II-c

	r.PreventUIRefresh(-1) -- seems to have no affect

	return r.defer(function() end) end

r.Undo_BeginBlock() -- to make r.defer(function() end) work otherwise either generic undo point is created or one is generated by the action 'Track: Set first selected track as last touched track'
r.Undo_EndBlock('', -1)





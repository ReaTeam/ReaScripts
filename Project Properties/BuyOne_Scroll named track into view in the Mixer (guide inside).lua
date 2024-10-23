--[[
ReaScript name: Scroll named track into view in the Mixer
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.3
Changelog: #Fixed capture of MCP folder state
	   #Fixed logic of the search for the parent of a collapsed folder the target track is in
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

	When the target track is a child in a folder and the folder 
	is collapsed in the Mixer, the parent track will be scrolled into view
	instead. If the target track belongs to one of several nested folders 
	the parent track of the first collapsed folder (if any) to which it belongs 
	will be scrolled into view.   
	If the script happens to fail to determine whether or not the folder
	is collapsed, no scrolling occurs.

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

	SWS/S&M Extension

	It's recommended to have the SWS/S&M extension installed so that all
	3 track scroll positions are available regardless of the Mixer window width 
	and that child and parent tracks of collapsed folders are always recognized.    
	If not installed then worth being aware of the following:  
	A) in the docked Mixer, central and rightmost positions will only be respected 
	when the Mixer window is open to its full width,   
	if it shares the docker with other windows in split mode (but not in tabbed
	mode) and such other windows are visible any POSITION setting will be clamped 
	to the leftmost;   
	B) in the floating Mixer window only any POSITION setting will be clamped 
	to the leftmost;  
	C) if the MIDI Editor is docked in the same docker as the Mixer, visible or not,
	any POSITION setting will be clamped to the leftmost.  
	D) child target tracks or their folder parent tracks may go unrecognized 
	depeding on the number and size of inserted FX and number of items on the track;		

	BOTTOM LINE, absent the SWS/S&M extension use only leftmost position so the track
	is sure to scroll into view. It could have been hard coded but i opted out just
	to give the user some freedom of choice.

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

	* * *
	Check out also Save-Load window set with Mixer scroll position (10 scripts)
	for a method of scrolling named track into view with hard linking between 
	track name and screenset number.

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


function ACT(comm_ID) -- both string and integer work
r.Main_OnCommand(r.NamedCommandLookup(comm_ID),0)
end

function GetTrackChunk(obj) -- retval stems from r.GetFocusedFX(), value 0 is only considered at the pasting stage because in the copying stage it's error caught before the function
-- https://forum.cockos.com/showthread.php?t=193686
-- https://raw.githubusercontent.com/EUGEN27771/ReaScripts_Test/master/Functions/FXChain
-- https://github.com/EUGEN27771/ReaScripts/blob/master/Various/FXRack/Modules/FXChain.lua
		if not obj then return end
  -- Try standard function -----
	local ret, chunk = r.GetTrackStateChunk(obj, '', false) -- isundo = false
		if ret and chunk and #chunk > 4194303 and not r.APIExists('SNM_CreateFastString') then return 'abort'
		elseif ret and chunk and #chunk < 4194303 then return ret, chunk -- 4194303 bytes = (4096 kb * 1024 bytes) - 1 byte
		end
-- If chunk_size >= max_size, use wdl fast string --
	local fast_str = r.SNM_CreateFastString('')
		if r.SNM_GetSetObjectState(obj, fast_str, false, false) -- setnewvalue and wantminimalstate = false
		then chunk = r.SNM_GetFastString(fast_str)
		end
	r.SNM_DeleteFastString(fast_str)
		if chunk then return true, chunk end
end


function Find_Parent_Of_1st_Collapsed_Folder(targ_tr, GetTrackChunk)
-- returns parent track of a collapsed folder (if any) the target belongs to in order to scroll to it, because child track of a collapsed folder can't be scrolled to
-- r.GetMediaTrackInfo_Value(tr, 'B_SHOWINMIXER') doesn't indicate if it's under collapsed folder, only when it's explicitly hidden

local targ_tr_depth = r.GetTrackDepth(targ_tr)
	if targ_tr_depth == 0 then return targ_tr end -- if target track isn't a child
	
-- collect all parents of the track
local targ_tr_idx = r.CSurf_TrackToID(targ_tr, false)-1 -- mcpView false
local parent = r.GetParentTrack(targ_tr)
local parents_t = {}
local i = targ_tr_idx-1 -- start from previous track
	repeat
	local tr = r.GetTrack(0,i)
		if tr == parent then parents_t[#parents_t+1] = parent 
		parent = r.GetParentTrack(tr)
		end
	i = i - 1
	until r.GetTrackDepth(parent) == 0 -- uppermost parent found

	-- Find the leftmost parent of the collapsed folder the child belongs to, if any
	for i = #parents_t, 1, -1 do -- in reverse since parent tracks were stored from right to left; if the table is empty the loop won't start
	local tr = parents_t[i]
	local ret, chunk = GetTrackChunk(tr)
		if ret == 'abort' then return -- if parent track chunk is larger than 4.194303 Mb and no SWS extension to handle that to find out if it's collapsed
		elseif ret and chunk and chunk:match('BUSCOMP %d (%d)') == '1' -- collapsed
		then return tr
		end
	end
return targ_tr -- if no parent track of a collapsed folder was found
end


local wnd_ident_t = { -- to be used in Get_Mixer_Wnd_Dock_State() function
-- transport docked pos in the top or bottom dockers can't be ascertained
-- transport_dock=0 any time it's not docked at its reserved positions, which could be
-- floating or docked in any other docker
-- window 'dock=0' keys do not get updated if the window was undocked before a screenset where it's docked was (re)loaded which leads to false positives
-- The following key names are keys used in [REAPERdockpref] section
-- % escapes are included for use within string.match()
actions = {'%[actions%]', 'wnd_vis', 'dock'}, -- Show action list ('Actions')
--=============== 'Project Bay' // 8 actions // dosn't keep size ===============
projbay_0 = {'%[projbay_0%]', 'wnd_vis', 'dock'}, -- View: Show project bay window
projbay_1 = {'%[projbay_1%]', 'wnd_vis', 'dock'}, -- View: Show project bay window 2
projbay_2 = {'%[projbay_2%]', 'wnd_vis', 'dock'}, -- View: Show project bay window 3
projbay_3 = {'%[projbay_3%]', 'wnd_vis', 'dock'}, -- View: Show project bay window 4
projbay_4 = {'%[projbay_4%]', 'wnd_vis', 'dock'}, -- View: Show project bay window 5
projbay_5 = {'%[projbay_5%]', 'wnd_vis', 'dock'}, -- View: Show project bay window 6
projbay_6 = {'%[projbay_6%]', 'wnd_vis', 'dock'}, -- View: Show project bay window 7
projbay_7 = {'%[projbay_7%]', 'wnd_vis', 'dock'}, -- View: Show project bay window 8
--============================== Matrices ======================================
routing = {'routingwnd_vis', 'routing_dock'}, -- View: Show track grouping matrix window ('Grouping Matrix'); View: Show routing matrix window ('Routing Matrix'); View: Show track wiring diagram ('Track Wiring Diagram')
--===========================================================================
regmgr = {'%[regmgr%]', 'wnd_vis', 'dock'}, -- View: Show region/marker manager window ('Region/Marker Manager')
explorer = {'%[reaper_explorer%]', 'visible', 'docked'}, -- Media explorer: Show/hide media explorer ('Media Explorer')
trackmgr = {'%[trackmgr%]', 'wnd_vis', 'dock'}, -- View: Show track manager window ('Track Manager')
bigclock = {'%[bigclock%]', 'wnd_vis', 'dock'}, -- View: Show big clock window ('Big Clock')
video = {'%[reaper_video%]', 'visible', 'docked'}, -- Video: Show/hide video window ('Video Window')
perf = {'%[perf%]', 'wnd_vis', 'dock'}, -- View: Show performance meter window ('Performance Meter')
navigator = {'%[navigator%]', 'wnd_vis', 'dock'}, -- View: Show navigator window ('Navigator')
vkb = {'%[vkb%]', 'wnd_vis', 'dock'}, -- View: Show virtual MIDI keyboard ('Virtual MIDI Keyboard')
fadeedit = {'%[fadeedit%]', 'wnd_vis', 'dock'}, -- View: Show crossfade editor window ('Crossfade Editor')
undo = {'undownd_vis', 'undownd_dock'}, -- View: Show undo history window ('Undo History')
fxbrowser = {40271, 'fxadd_dock'}, -- View: Show FX browser window ('Add FX to Track #' or 'Add FX to: Item' or 'Browse FX') // fxadd_vis value doesn't change hence action to check visibility
itemprops = {'%[itemprops%]', 'wnd_vis', 'dock'}, -- Item properties: Toggle show media item/take properties ('Media Item Properties')
midiedit = {'%[midiedit%]', 'dock'}, -- there's no key for MIDI Editor visibility
--=========== TOOLBARS // don't keep size; the ident strings are provisional ==========
toolbar = {'toolbar', 'wnd_vis', 'dock'} -- Toolbar: Open/close toolbar X ('Toolbar X')
}


function Get_Mixer_Wnd_Dock_State(wnd_ident_t, wantDockPos) -- get Mixer dock state WHEN the SWS extension IS NOT INSTALLED to verify whether there're other windows sharing a docker with the Mixer in the split mode and so whether its full window width can be used; returns false if there's a window which shares a docker with the Mixer, otherwise true

-- dockermode of closed docked windows isn't updated, so when the Mixer doesn't share docker with any other windows
-- in the split mode at a given moment because these windows are closed, to ensure that its full width, obtained with
-- my_getViewport(), can be used, these closed windows visibility toggle state must be evaluated as well
-- a more reliable method would be to read screenset data

local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
local mixwnd_dock = r.GetToggleCommandStateEx(0, 40083) == 1 -- or cont:match('mixwnd_dock=1') -- Mixer: Toggle docking in docker // mixwnd_dock value is likely to not update when state changes hence alternative
local mixer_dockermode = cont:match('%[REAPERdockpref%].-%f[%a]mixer=[%d%.]-%s(%d+)\n') -- find mixer dockermode number // the frontier operator %f is needed to avoid false positive of 'mastermixer' which refers to the Master track
local mixer_dock_pos = cont:match('dockermode'..mixer_dockermode..'=(%d+)') -- get mixer docker position

	if wantDockPos then return mixer_dock_pos end -- if requested, return pos in case the entire docker is closed and not the Mixer window itself, to condition the rightmost position routine because in this case it won't work, but nevertheless will run because Mixer toggle state will still be OFF and hence true; plus if dockerpos is not 0 or 2 the rightmost position won't be needed anyway as without SWS extension in other docks and in floating window only the leftmost pos is honored; must come before the next condition so it's not blocked by it if the latter is true
	if not mixwnd_dock -- in floating Mixer window wihtout SWS extension only use leftmost position
	or (mixer_dock_pos ~= '0' and mixer_dock_pos ~= '2') -- if sits in side dockers, only use leftmost position because the Mixer window cannot have full width anyway
	then return false
	elseif mixwnd_dock and mixer_dockermode and (mixer_dock_pos == '0' or mixer_dock_pos == '2') -- bottom or top, where Mixer window can stretch to the full width of the main window
	then
	local temp = cont -- temp var to perform repeats count below without risking to affect the orig. data
	local _, reps = temp:gsub('dockermode','%0') -- get number of repeats
	local dockermode_t = {cont:match(string.rep('.-(dockermode%d+=%d)', reps))} -- collect all dockermode entries
	local adjacent_dockermode_t = {}
		for _, v in ipairs(dockermode_t) do -- collect dockermode indices of all windows which share the docker with the Mixer in the split mode
			if v:match('(%d+)=') ~= mixer_dockermode -- exclude mixer's own dockermode entry
			and v:match('=(%d)') == mixer_dock_pos then -- if positon is the same as that of Mixer which means the docker is split and causes change in Mixer window size
			adjacent_dockermode_t[#adjacent_dockermode_t+1] = v:match('(%d+)=')
			end
		end
		if #adjacent_dockermode_t > 0 then -- if there're dockermodes which share docker with the Mixer
		local REAPERdockpref = cont:match('%[REAPERdockpref%](.-)%[')
		local REAPERdockpref_t = {}
			for line in REAPERdockpref:gmatch('\n?(.-%s%d+)\n?') do -- extract all [REAPERdockpref] section entries
			REAPERdockpref_t[#REAPERdockpref_t+1] = line
			end
		local adjacent_wnd_t = {}
			for _, v1 in ipairs(adjacent_dockermode_t) do -- collect names of windows sitting in a split docker with the Mixer (having dockermode with the same position as that of the Mixer) whether visible or not
				for _, v2 in ipairs(REAPERdockpref_t) do
					if v1 == v2:match('.+%s(%d+)') then
					adjacent_wnd_t[#adjacent_wnd_t+1] = v2:match('(.+)=') end
				end
			end
			for _, v in ipairs(adjacent_wnd_t) do -- evaluate the collected windows visibility and dock state
			local t = wnd_ident_t[v] or wnd_ident_t[v:match('toolbar')] -- toolbar key is separate since in adjacent_wnd_t toolbar keys contain numbers and can't select the table nested inside wnd_ident_t directly; match to isolate 'toolbar' word specifically since the list may include SWS window identifiers
				if t and #t == 3 and t[1] ~= 'toolbar' then -- or if v ~= 'toolbar'; windows with a dedicated section in reaper.ini besides toolbars which are treated below // additional t truthfulness evaluation because if the adjacent_wnd_t list contains SWS window identifiers the t will be false
				local sect = cont:match(t[1]..'(.-)%[') or cont:match(t[1]..'(.-)$') -- capture section content either followed by another section or at the very end of the file
					if sect:match(t[2]..'=1') and sect:match(t[3]..'=1') then return false end
				elseif t and #t == 2 and tonumber(t[1]) then -- fxbrowser command ID and a key
					if r.GetToggleCommandStateEx(0, t[1]) == 1 and cont:match(t[2]..'=1') then return false end
				elseif t and #t == 2 and v == 'midiedit' then -- MIDI Editor, always returns false if docked in the same docker as the Mixer regardless of visibility because the latter cannot be ascertained from reaper.ini
					local sect = cont:match(t[1]..'(.-)%[') or cont:match(t[1]..'(.-)$') -- capture section content either followed by another section or at the very end of the file
						if sect:match(t[2]..'=1') then return false end
				elseif t and #t == 2 then -- windows without a dedicated section
					if cont:match(t[1]..'=1') and cont:match(t[2]..'=1') then
					return false end
				elseif t and t[1] == 'toolbar' then -- or if v == 'toolbar'
				local sect = cont:match('%['..v..'%](.-)%[') or cont:match('%['..v..'%](.-)$') -- capture section content either followed by another section or at the very end of the file
					if sect and sect:match(t[2]..'=1') and sect:match(t[3]..'=1') then return false end -- sect can be false if the stored toolbar has no section, in particular 'toolbar' (without a number) representing Arrange main toolbar
				end
			end
		end
	end
	
return true

end


function Scroll_Track_Into_View(targ_tr, loc, not_shared) -- loc corresponds to POSITION var from the USER SETTINGS; not_shared is return value of Get_Mixer_Wnd_Dock_State() function
-- Leftmost track left edge X value in pixels is 0, values further to the left (out of sight) are negative, to the right - posititive
-- Being set with the function SetMixerScroll() the leftmost track is always displayed in full which may cause the rightmost track be partially shifted beyond the Mixer right edge or the Master track if it's displayed on the right side (because MCPs combined width doesn't fit within the Mixer window); this is mitigated by shifting the target track back leftwards which is a trade-off and may reveal one or more extra tracks on the right, depending on the width of the leftmost track

local sws = r.APIExists('BR_Win32_GetMainHwnd')
local mixer_hwnd = r.BR_Win32_GetMixerHwnd() -- used outside of BR_Win32_GetWindowRect since it returns two values
local dimens = sws and {r.BR_Win32_GetWindowRect(mixer_hwnd)} or {r.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)} -- wantWorkArea true

	if #dimens == 5 then table.remove(dimens, 1) end -- remove retval from BR's function

local loc = (not sws and not_shared or sws) and loc or '' -- clamp position to the leftmost if no SWS extension and another window shares docker with the Mixer in the split mode

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
local i = r.CSurf_TrackToID(targ_tr, false)-2 -- mcpView is false; start looping from the track immediately preceding the target track backwards
	repeat
	tr = r.GetTrack(0,i)
		tr_x = tr and r.GetMediaTrackInfo_Value(tr, 'I_MCPX') or 0
	i = i - 1
	until abs(tr_x - targ_tr_x) > pos - master_w or not tr -- accounting for negative X when tracks are beyond Master track on the left side or beyond the left edge and for cases when the target track is at zero point or when there're too few tracks which precede it (not tr)

-- The loop exits with the X coordinate of the target track right edge being greater than the target scroll position; now correct it by bringing it back leftwards to the point immedialtely preceding the target scroll point, especially relevant for target position being rightmost in which case the track goes beyond the right edge of the window
	if tr and (loc == 'R' and abs(tr_x - targ_tr_x) + master_w - pos > 5 -- targ track right edge X coordinate is greater than the position by 5 px, 5 or less is acceptable since the MCP is mostly visible, and 5 is optimal for MCP strips which are quite narrow
	or abs(tr_x - targ_tr_x) + master_w - pos > pos - abs(r.GetMediaTrackInfo_Value(r.GetTrack(0,i+2), 'I_MCPX') - targ_tr_x) - master_w) -- only correct if the resulting targ track right X will be closer to the position than the targ track right X obtained after the loop; why +2 see below // works for pos 0
	then return r.GetTrack(0,i+2) -- return the correcting track to bring the target track back to the left by one track // +2 because the shift is required by 1 track from the current after the loop, but before the loop exits i value gets reduced by 1 which corresponds to the one before the current and -2nd from the target track if position is 0
	elseif tr then return r.GetTrack(0,i+1)
	else return r.GetTrack(0,0) -- when there're too few tracks or their MCPs are too narrow to scroll to the central or the rightmost position, scroll to the very 1st track to shift the target track as far as possible
	end

end


function Set_Mixer_Scroll()
-- Inside a custom action alongside 'Screenset: Load window set #...' action the script manages to make the Mixer scroll but then reaper.ini settings appear to kick in and Mixer scroll reverts to position stored previously if it wasn't at the target track, this happens instantaneously and could only be noticed with 'Action: Wait X seconds' action placed last in the custom action sequence, so defer() is meant to override that by keeping the scroll pushed to the target track past the moment of reversal to reaper.ini (?) settings; this doesn't happen if a screenset is loaded via a script such as 'Screenset; Save-Load window set #n with Mixer scroll position'
r.SetMixerScroll(tr)
	if r.time_precise() - start < .100 then r.defer(Set_Mixer_Scroll) end
end


function Tooltip() -- display a tooltip when the target track is inside a collapsed folder
--Msg(r.time_precise() - start)
--Msg(({r.GetTrackName(targ_tr)})[2], 'FOLDER NAME')
	if targ_tr then
	local ret, tr_name = r.GetTrackName(targ_tr)
		if tr_name ~= TRACK_NAME then -- parent of the folder the target track belongs to
		local parent_idx = r.CSurf_TrackToID(targ_tr, false) -- mcpView false
		r.TrackCtl_SetToolTip(string.format('\n\n   THE TARGET TRACK IS INSIDE THE FOLDER   \n\n  OF TRACK  " %s "  [#%s]  (s e l e c t e d )\n\n ', tr_name, parent_idx), math.floor((dimens[3]-dimens[1])/2), dimens[2]-50, true) -- math.floor to prevent fractional value which is invalid; topmost true
			if r.time_precise() - start < 2 then r.defer(Tooltip) end
		end
	end
end


local tr_cnt = r.CountTracks(0)
local some_tracks = tr_cnt > 0

TRACK_NAME = #TRACK_NAME:gsub(' ','') > 0 and TRACK_NAME
SCREENSET = #SCREENSET:gsub(' ','') > 0 and tonumber(SCREENSET) and tonumber(SCREENSET) > 0 and tonumber(SCREENSET) < 11 and ({math.modf(tonumber(SCREENSET))})[2] == 0 and SCREENSET or #SCREENSET:gsub(' ','') > 0 and 'Invalid screenset number — "'..tostring(SCREENSET)..'"' or SCREENSET -- the last is empty setting


	if #SCREENSET > 2 then r.MB(SCREENSET, 'ERROR', 0) return r.defer(function() end) end

	-- L O A D ===============================================================================

	if TRACK_NAME or SCREENSET then

POSITION = POSITION:gsub(' ',''):upper() -- make case ignorant
POSITION = (POSITION:match('[CR]') or #POSITION == 0) and POSITION or '' -- leftmost is the fallback

	r.PreventUIRefresh(1) -- seems to have no affect

		if TRACK_NAME and some_tracks then

		local sel_trks_t = re_store_sel_trks() -- store sel tracks and unselect all	// METHOD II-a (make target track last touched)

			for i = 0, tr_cnt-1 do -- scroll stored track into view
			targ_tr = r.GetTrack(0,i) -- will be used outside of the loop and in the deferred Set_Mixer_Scroll() function if target track
			name = targ_tr and {r.GetTrackName(targ_tr)} -- 2 return values; global to be evaluated below
				if name and TRACK_NAME and name[2] == TRACK_NAME then
				targ_tr = Find_Parent_Of_1st_Collapsed_Folder(targ_tr, GetTrackChunk) -- if the target track is a folder child grab its parent track instead if it's collapsed, because parent collapsed state prevents child track from being scrolled into view
					if not targ_tr then re_store_sel_trks(sel_trks_t) return r.defer(function() end) end -- one of parent track chunks was larger than 4.194303 Mb and no SWS extension to handle that to find out if it's collapsed, therefore abort scrolling entirely
				r.SetOnlyTrackSelected(targ_tr) -- OR r.SetTrackSelected(targ_tr, 1) since all are deselected with the re_store_sel_trks() function
				ACT(40914) -- Track: Set first selected track as last touched track // the only way to make sure target track is the last touched is to deselect all, select the track and set it as last touched
				break end
			end

		-- Check if 'Scroll view when tracks activated' is enabled and if not, temporarily enable it to allow scrolling target track into view on the right side after making it last touched; under this option when a track is out of sight on the left side of the Mixer it scrolls to the left edge, if it's out of sight on the right side it scrolls to the right edge; all this is meant to ensure the track is visible on the right side when the screenset is loaded with the script (when loaded from a custom action it works properly) after switching from another project tab while the Mixer is closed, otherwise the scrolling craps out; it's done by making the Mixer scroll the track into view after making it last touched and enabling 'Scroll view when tracks activated' option if not enabled, and then exiting the routine before it reaches the main Scroll_Track_Into_View() function because by that point the track should already be at the right (in both senses) spot; after switching from another project tab under the described conditions the leftmost position works, the central position is slightly off but not critically and the track is still in plain view, only the rightmost position is problematic
		mixer_closed = r.GetToggleCommandStateEx(0, 40078) == 0 -- View: Toggle mixer visible // closed before loading screenset
		off = r.GetToggleCommandStateEx(0, 40221) == 0 -- Mixer: Toggle scroll view when tracks activated
			if name[2] == TRACK_NAME then -- target track was found
			local on = mixer_closed and off and r.Main_OnCommand(40221,0) -- Mixer: Toggle scroll view when tracks activated
			end
			
		end
				
		local is_dock_closed = mixer_closed and Get_Mixer_Wnd_Dock_State(wnd_ident_t, true):match('6553') -- wantDockPos is true // rightmost position routine below meant to place track on the right side of the Mixer when it's initially closed doesn't work if the entire docker is hidden and not just the Mixer window (whose toggle state becomes OFF in this case as well and makes the routine condition true), so this is meant to counterbalance mixer_closed condition and prevent the routine from running when the condition is true and proceed to the main rouitne which can handle the situation; placed before loading a screenset because after that the dock position will get updated and won't indicate dock being hidden any longer

		if SCREENSET then
		local id = 404 -- 1st three digits of save/load screenset actions command IDs
		local t = {54, 55, 56, 57, 58, 59, 60, 61, 62, 63} -- Screenset: Load window set #.. actions
		local id = tostring(id)..tostring(t[tonumber(SCREENSET)]) -- concatenate full 'Screenset: Load window set #..' action command ID
		ACT(id) -- load screenset
		end
		
		if some_tracks then
		-- get Mixer window dimensions
		local sws = r.APIExists('BR_Win32_GetMainHwnd')
		local mixer_hwnd = r.BR_Win32_GetMixerHwnd() -- used outside of BR_Win32_GetWindowRect since it returns two values
		dimens = sws and {r.BR_Win32_GetWindowRect(mixer_hwnd)} or {r.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true)} -- global for deferred Tooltip()
			if #dimens == 5 then table.remove(dimens, 1) end -- remove retval from BR's function		

			local docked = r.GetToggleCommandStateEx(0, 40083) == 1 -- Mixer: Toggle docking in docker
			local not_shared = Get_Mixer_Wnd_Dock_State(wnd_ident_t) -- whether the Mixer shares docker with other windows in the split mode to condition rightmost routine below only allowing it to run when the condition is true and otherwise skipping to the main routine when the position is clamped to the leftmost; that's for the sake of consistency, so that when there's dock sharing the position is always clamped to the leftmost whether the Mixer is initially closed or open
			
			local off = mixer_closed and off and r.Main_OnCommand(40221,0) -- Mixer: Toggle scroll view when tracks activated // restore disabled state of 'Scroll view when tracks activated' if it was turned off initially
			
			local is_orig_track = ({r.GetTrackName(targ_tr)})[2] == TRACK_NAME -- as opposed to a parent track of the folder to which the target track belongs
			local mixer_open = r.GetToggleCommandStateEx(0, 40078) == 1 -- View: Toggle mixer visible

			if name[2] ~= TRACK_NAME -- don't scroll the Mixer unnecessarily if track name wasn't found, because the above loops exits with the targ_tr being the last track which end up being scrolled to
			then re_store_sel_trks(sel_trks_t) return r.defer(function() end)
			elseif not is_dock_closed -- if the dock the Mixer is in is closed, this routine won't work, skip to proceed to the main routine
			and (not sws and docked and not_shared or sws) -- when no SWS, only run if the Mixer is docked and not sharing dock with other windows, otherwise skip to proceed to the main routine and there clamp any positon to the leftmost (when the dock is shared or when the Mixer is floating without SWS full width of the Mixer window cannot be assured)
			and POSITION == 'R' and mixer_closed and r.GetMediaTrackInfo_Value(targ_tr, 'I_MCPX')+r.GetMediaTrackInfo_Value(targ_tr, 'I_MCPW') > dimens[3] -- exit the routine when POSITION is the rightmost, the Mixer was initially closed and ONLY if the track X positon is greater than the Mixer width which means the Mixer has auto-scrolled it into view at the right edge as a result of the above routine, otherwise when the routine continues the track may end up on the left side because if it was to the left of the 0 point on the X axis, being last touched it will be scrolled into view at the left edge instead; when switching from another project tab with the Mixer closed this condition will be always true since in this case the Mixer scroll position is reset (at least when it's opened via API with a screenset, that's what the data indicates) and starts from the 1st track therefore target track position in this case will always be to the right of the 0 point on the X axis (which corresponds to the Mixer left edge or to the right edge of the Master track shown on the left side) and likely greater than the Mixer width therefore it will be scrolled into view at the right edge according to the settings; if the target track happens to be too close to the start or to the end of the tracklist in the Mixer so there's no room for scrolling, then further scrolling isn't needed anyway; if these conditions aren't met the routine can continue and the track will be scrolled to the designated spot
			then
			local restore = is_orig_track and re_store_sel_trks(sel_trks_t) -- only restore track selection if orig. track, keep selected if parent track as visual feedback
			start = r.time_precise() -- to compare against inside the next function; must be global
			local displ = not is_orig_track and mixer_open and Tooltip() -- inform user under what folder the target track is found if the folder is collapsed // only when the Mixer is open
			return r.defer(function() end) end


		tr = Scroll_Track_Into_View(targ_tr, POSITION, not_shared) -- tr must be global for Set_Mixer_Scroll() to work in deferred mode
		start = r.time_precise() -- to compare against inside the next function; must be global
		Set_Mixer_Scroll() -- deferred function

		local restore = is_orig_track and re_store_sel_trks(sel_trks_t) -- only restore track selection if orig. track, keep selected if parent track as visual feedback
		local displ = not is_orig_track and mixer_open and Tooltip() -- inform user under what folder the target track is found if the folder is collapsed // only when the Mixer is open

		end

	r.PreventUIRefresh(-1) -- seems to have no affect
	
		if not some_tracks then r.MB('No tracks in the project.','ERROR',0) return r.defer(function() end) end

	return r.defer(function() end) end

r.Undo_BeginBlock() -- to make r.defer(function() end) work otherwise either generic undo point is created or one is generated by the action 'Track: Set first selected track as last touched track'
r.Undo_EndBlock('', -1)






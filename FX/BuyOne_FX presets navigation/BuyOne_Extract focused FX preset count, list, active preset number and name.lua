-- @noindex

--[[

* ReaScript name: BuyOne_Extract focused FX preset count, list, active preset number and name.lua
* Author: BuyOne
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Version: 1.1
* Forum Thread:
* Demo:
* REAPER: at least v5.962
* Changelog:
	+ v1.0 	Initial release
	+ v1.1 	Added a list of presets to the presets info displayed in ReaConsole
		Worked around a REAPER API problem of not differentiating between identically named user and built-in presets
=========================================================================

A preset name can be easily copied by selecting the preset, clicking
the '+' button on the FX panel and selecting 'Rename preset...' option.
But its number must be counted.

The script is intended to simplify the task.

The format is:

/////////////////////////////////////////////////////////
preset_count::current_preset_number::current_preset_name
========================================
(preset list)
preset_number preset_name
/////////////////////////////////////////////////////////

The data is displayed in the ReaConsole. If all the data can't fit within 
the Console due to the long preset list, it will be displayed in an empty
item notes on a new track inserted at the end of the current track list.

Video prosessor presets are supposed to be supported since REAPER build 6.26.

]]


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

local resp = r.MB('The script will now go through all the presets\n\n\tto list them in the Console.\n\n     For this it will be switching them 1 by 1.\n\n    If your current plugin settings aren\'t saved\n\n\t'..string.rep(' ',6)..'they it will be lost.\n\n     Want to abort to save the settings first?','WARNING',4)
	if resp == 6 then r.defer(function() do return end end) return end

local function GetMonFXProps() -- get mon fx accounting for floating window, reaper.GetFocusedFX() doesn't detect mon fx in builds prior to 6.20

	local master_tr = r.GetMasterTrack(0)
	local src_mon_fx_idx = r.TrackFX_GetRecChainVisible(master_tr) -- returns positive value even when open and not in focus
	local is_mon_fx_float = false
		if src_mon_fx_idx < 0 then -- fx chain closed or no focused fx -- if this condition is removed floated fx gets priority
			for i = 0, r.TrackFX_GetRecCount(master_tr) do
				if r.TrackFX_GetFloatingWindow(master_tr, 0x1000000+i) then
				src_mon_fx_idx = i; is_mon_fx_float = true break end
			end
		end
	return src_mon_fx_idx, is_mon_fx_float
end


function Re_Store_Selected_Objects(t1,t2) -- when storing the arguments aren't needed

r.PreventUIRefresh(1)

local t1, t2 = t1, t2

	if not t1 then
	-- Store selected items
	local sel_itms_cnt = r.CountSelectedMediaItems(0)
		if sel_itms_cnt > 0 then
		t1 = {}
		local i = sel_itms_cnt-1
			while i >= 0 do -- in reverse due to deselection
			local item = r.GetSelectedMediaItem(0,i)
			t1[#t1+1] = item
		--	r.SetMediaItemSelected(item, false) -- selected false; deselect item // OPTIONAL
			i = i - 1
			end
		end
	elseif t1 and #t1 > 0 then -- Restore selected items
--	r.Main_OnCommand(40289,0) -- Item: Unselect all items
--	OR
	r.SelectAllMediaItems(0, false) -- selected false
		for _, item in ipairs(t1) do
		r.SetMediaItemSelected(item, true) -- selected true
		end
	r.UpdateArrange()
	end

	if not t2 then
	-- Store selected tracks
	local sel_trk_cnt = reaper.CountSelectedTracks2(0,true) -- plus Master, wantmaster true
		if sel_trk_cnt > 0 then
		t2 = {}
		local i = sel_trk_cnt-1
			while i >= 0 do -- in reverse due to deselection
			local tr = r.GetSelectedTrack2(0,i,true) -- plus Master, wantmaster true
		--	r.SetTrackSelected(tr, false) -- selected false; deselect track // OPTIONAL
			t2[#t2+1] = tr
			i = i - 1
			end
		end
	elseif t2 and #t2 > 0 then -- restore selected tracks
	r.Main_OnCommand(40297,0) -- Track: Unselect all tracks
	r.SetTrackSelected(r.GetMasterTrack(0), false) -- unselect Master
	-- OR
	-- r.SetOnlyTrackSelected(t2[1])
		for _, tr in ipairs(t2) do
		r.SetTrackSelected(tr, true) -- selected true
		end
	r.UpdateArrange()
	r.TrackList_AdjustWindows(0)
	end

r.PreventUIRefresh(-1)

return t1, t2

end


local retval, track_num, item_num, fx_num = r.GetFocusedFX()
local src_mon_fx_idx = GetMonFXProps() -- get Monitor FX

		if retval == 0 and src_mon_fx_idx < 0 then r.MB('No FX is in focus.','ERROR',0) r.defer(function() end) return end

local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack()
local take_num = retval == 2 and fx_num>>16
local take = retval == 2 and r.GetMediaItemTake(r.GetTrackMediaItem(tr, item_num), take_num)
local fx_num = (retval == 2 and fx_num >= 65536) and fx_num & 0xFFFF or fx_num -- take fx index
local mon_fx = retval == 0 and src_mon_fx_idx >= 0
local fx_num = mon_fx and src_mon_fx_idx + 0x1000000 or fx_num -- mon fx index


local track, item = retval == 1 or mon_fx, retval == 2
local obj = track and tr or item and take

-- Check if focused FX has any presets
local t = track and {r.TrackFX_GetPresetIndex(obj, fx_num)} or item and {r.TakeFX_GetPresetIndex(obj, fx_num)} or {}
-- unpack doesn't work directly inside the ternary expression
local _, pres_cnt = table.unpack(t)

	if pres_cnt == 0 then resp = r.MB('The FX has no presets.','PROMPT',0) return r.defer(function() do return end end) end

local count = track and ({r.TrackFX_GetPresetIndex(obj, fx_num)})[2] or item and ({r.TakeFX_GetPresetIndex(obj, fx_num)})[2]
local pres_num = track and r.TrackFX_GetPresetIndex(obj, fx_num) or item and r.TakeFX_GetPresetIndex(obj, fx_num) -- if there's another preset with identical name the value will be the index of the earliest of them in the list, which is a bug of  Track/TakeFX_GetPresetIndex() function https://forum.cockos.com/showthread.php?t=270990
local unchanged, pres_name = table.unpack(track and {r.TrackFX_GetPreset(obj, fx_num, '')} or item and {r.TakeFX_GetPreset(obj, fx_num, '')}) -- unchanged return value is buggy and can't be relied upon, always returned as true  https://forum.cockos.com/showthread.php?t=270988
local pres_name = pres_name:match('.+[\\/](.+)%.vstpreset') or pres_name -- stripping path and extension off a vst3 preset name

r.PreventUIRefresh(1)

local get_preset, nav_presets, set_preset = table.unpack(track and {r.TrackFX_GetPreset, r.TrackFX_NavigatePresets, r.TrackFX_SetPresetByIndex} or item and {r.TakeFX_GetPreset, r.TakeFX_NavigatePresets, r.TakeFX_SetPresetByIndex})
local pres_names_lst = {}

-- IF THERE'S A USER PRESET NAMED AS A BUILT-IN PRESET THE r.Track/TakeFX_NavigatePresets() FUNCTION FAULTERS WHEN A DUPLICATE IS FOUND AND AUTO-SWITCHES TO THE IDENTICALLY NAMED PRESET WITH SMALLER INDEX (earlier in the list) to continue the loop from there, it also seems to act strangely with vst bult-in programs, returning index -1 which is an error as per Track/TakeFX_GetPresetIndex() function, and if the last of those is active before the loop starts it can't be restored afterwards as index -1 is invalid; r.Track/TakeFX_SetPresetByIndex() isn't affected by these problems // https://forum.cockos.com/showthread.php?t=270990

local mess_box_trig

	for i = 0, count-1 do
	set_preset(obj, fx_num, i)
	local retval, name = get_preset(obj, fx_num, '')
		if not mess_box_trig and name:match('%.vstpreset') then resp = r.MB('\tThe preset list contains vst3 presets.\n\n\t       If you use custom preset list\n\n\tin my other preset navigation scripts\n\nwith INDEX_BASED_PRESET_SWITCH setting NOT enabled\n\n      you may want to have vst3 presets full paths listed\n\n\t         so they can be switched to.', 'PROMPT', 4) -- needed since to switch to vst3 presets by name Track/TakeFX_SetPreset() function requires its path
			if resp == 6 then by_name = true end
		mess_box_trig = 1 -- to prevent recurrent pop-ups during the loop
		end
	pres_names_lst[#pres_names_lst+1] = (i+1)..' '..(by_name and name or not by_name and (name:match('.+[\\/](.+)%.vstpreset') or name)) -- stripping path and extension off a vst3 preset name if presets won't be switched by name
	end

set_preset(obj, fx_num, pres_num) -- restore originally selected preset by index; if 'No preset' was active before the above loop, it won't be reasored since it's index is out of 0-based range and what will end up being selected after the loop which stored preset names is the very last preset

	-- Find if there're presets with identical names to include a warning due to the bug of Track/TakeFX_NavigatePresets() and Track/TakeFX_GetPresetIndex() described above
local duplicate
	for k1, preset_1 in ipairs(pres_names_lst) do
		for k2, preset_2 in ipairs(pres_names_lst) do
			if preset_1 == preset_2 and k1 ~= k2 then duplicate = 1 break end
		end
		if duplicate then break end
	end

local warning = duplicate and '!!!! WARNING !!! The preset list contains presets with identical names which will cause glitch if navigated with scripts due to REAPER API bug --> https://forum.cockos.com/showthread.php?t=270990 \r\n\r\n' or ''
local output = count..'::'..(pres_num+1)..'::'..(#pres_name > 0 and pres_name or pres_names_lst[#pres_names_lst])..'\r\n\r\n'..string.rep('=',60)..'\r\n\r\n'..warning..table.concat(pres_names_lst,'\r\n') -- +1 since the count is 0 based; if statring out from 'No preset' it won't be restored since it's index is out of 0-based range and what will end up being selected after the loop which stored preset names is the very last preset // for the item notes to recognize line breaks they must be replaced with '\r\n' if the string wasn't previously formatted in the notes field https://forum.cockos.com/showthread.php?t=214861#2

	if #output > 16380 then -- console output maximum length is 16,382 (almost 16,384) bytes, https://forum.cockos.com/showthread.php?t=216979, display the output in an empty item notes
	local sel_itms_t, sel_trk_t = Re_Store_Selected_Objects() -- store
	local cur_pos = r.GetCursorPosition() -- store
	r.InsertTrackAtIndex(r.GetNumTracks(), false) -- wantDefaults false
	r.SetOnlyTrackSelected(r.GetTrack(0,r.GetNumTracks()-1)) -- select the newly inserted track
	r.SetEditCurPos(-3600, true, false) -- moveview true, seekplay false // move to -3600 or -1 hour mark in case project time start is negative, will surely move cursor to the very project start to reveal the notes item
	r.SelectAllMediaItems(0, false) -- selected false // deselect all
	r.Main_OnCommand(40142,0) -- Insert empty item
	local item = r.GetSelectedMediaItem(0,0)
	r.GetSetMediaItemInfo_String(item, 'P_NOTES', output, true) -- setNewValue true
	-- Open the empty item notes
	r.SetMediaItemSelected(r.GetSelectedMediaItem(0,0),true) -- selected true
	r.Main_OnCommand(40850,0) -- Item: Show notes for items...
	Re_Store_Selected_Objects(sel_itms_t, sel_trk_t) -- restore originally selected objects
	r.SetEditCurPos(cur_pos, false, false) -- moveview, seekplay false; restore position
	else
	r.ShowConsoleMsg(output, r.ClearConsole())
	end


r.PreventUIRefresh(-1)

do r.defer(function() do return end end) return end




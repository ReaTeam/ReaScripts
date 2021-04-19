-- @noindex

--[[

* ReaScript name: BuyOne_Dedicated FX presets backwards switcher (FX ID dependent) (guide inside).lua
* Author: BuyOne
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Version: 1.0
* Forum Thread:
* Demo:
* REAPER: at least v5.962
* Changelog:
	+ v1.0 	Initial release

--############################## G U I D E #####################################

The script allows cycling in a backward direction through presets of one FX linked
to the script.

Start by opening an FX in its FX chain or floating window, append the TAG defined
in the USER SETTINGS below to the name of such focused FX in the FX chain and run
the script.

The message will inform you that the link has been created.

!!! IMPORTANT !!! The TAG must be be followed by a space if it's appeneded to the
beginning of the FX name (e.g. 'TAG My plugin'), preceded by space at the end of
the name (e.g. 'My plugin TAG') or bordered by spaces in the middle of the name
(e.g. 'My TAG plugin').

After that the script can be used exclusively to switch presets in this FX
only, regardless of the FX focus status.

The link is created per project and in order to be able to continue to affect the
same FX with the script in future sessions you'll have to save the project.

To unlink the script from an FX simply remove the TAG from the FX name. On the next
script run a message will inform you that the link has been cleared. After that you
may need to save the project so the link isn't restored in the next session.

	## VIDEO PROCESSOR PLUGIN

Video prosessor is supposed to be supported since REAPER build 6.26 in which its preset
navigation via API was introduced.

To add the TAG to the Video processor name, insert it in the very first line of its
preset code (the first commented out line), e.g. '//PC De-interlace track/item' where
PC is the TAG and hit Ctrl(Command)+S. Be aware that after that the TAG will be burnt
into the code and will be displayed in the Video processor instance name each time the
preset is loaded. You can however delete it and again save the preset.

The link between the script and the FX is based on the FX ID therefore it won't be
broken up if the FX position is changed within the FX chain or if it's moved to another
object with Alt(Option)+Left drag.

!!! WARNING !!! Preset change creates an undo point unless it's a Monitor FX

If after closing the FX UI you happen to forget which FX it was, you can look up
its details in the undo point its preset change creates in the REAPER Undo log
accessible from the main menu panel or via action 'View: Show undo history window'.

	## MULTIPLE INSTANCES

The script can be duplicated as many times as there're FX needing a dedicated preset
switcher and each of its copy can be applied to a different FX. The TAG can everywhere
be the same since it's not the defining factor in the validity of the link between
the two. It rather helps to keep track of plugins which have a dedicated preset switcher
and to tell the script when the link should be cleared (when the TAG is removed).
That's the main difference of this script from
BuyOne_Dedicated FX presets forward switcher (TAG dependent)(guide inside).lua

	## AUTOMATING

It also can be automated with SWS/S&M extension action markers provided this option
is turned on in the extension settings at Extensions -> SWS Options -> Marker actions
accessible from the main menu or directly with 'SWS: Enable marker actions' or
'SWS: Toggle marker actions enable' action in the Action list.

The action marker name must adhere to the following format:

!_RSceeb8ead418881000e42adc04b33bd67d04e3d79 6
OR
!_RSceeb8ead418881000e42adc04b33bd67d04e3d79 My preset name

Where:
'_RSceeb8ead418881000e42adc04b33bd67d04e3d79' is this script command ID or a command ID
of a custom/cycle action featuring this script, which can be copied from their right
click context menu in the Action list with 'Copy selected action command ID' option.
Will be different in your installation.
'6' is the preset number in the FX preset list
'My preset name' is the preset actual name

The action marker name must end with either the preset number or the preset name.

Although the preset number must be counted, its name can be easily copied by selecting
the preset, clicking the '+' button on the FX panel and selecting 'Rename preset...'
option. Alternatively you could use
BuyOne_Extract focused FX preset count, active preset number and name.lua script.

If preset number or preset name featuring in the action marker aren't found in
the FX preset list or are left out of the action marker name, previous preset is selected.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Place any alphanumeric character or a combination thereof without spaces
-- between the double square brackets next to it.

TAG = [[PC]]

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

local _,scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')

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


function EvaluateTAG(fx_name,TAG)
local tag = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return fx_name:match('^('..tag..')%s') or fx_name:match('%s('..tag..')%s') or fx_name:match('%s('..tag..')$') or fx_name:match(tag)
end


local TAG = TAG:gsub('[%s]','') -- remove empty spaces

	if TAG == '' then r.MB('  The TAG has not been set\n\nin the script USER SETTINGS.','ERROR',0) r.defer(function() end) return end

local ret, fx_GUID = r.GetProjExtState(0, scr_name, 'PRESET_SWITCHER_DATA')

	if ret == 0 then -- 0 when either value or key is deleted or non-existent

	local retval, track_num, item_num, fx_num = r.GetFocusedFX()
	local src_mon_fx_idx = GetMonFXProps() -- get Monitor FX

		if retval == 0 and src_mon_fx_idx < 0 then r.MB('No linked FX and no FX is in focus.','ERROR',0) r.defer(function() end) return end -- on the very 1st run in a session, when no focused fx and no data has been stored

	local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack()
	local take_num = retval == 2 and fx_num>>16
	local take = retval == 2 and r.GetMediaItemTake(r.GetTrackMediaItem(tr, item_num), take_num)
	local fx_num = (retval == 2 and fx_num >= 65536) and fx_num & 0xFFFF or fx_num -- take fx index
	local mon_fx = retval == 0 and src_mon_fx_idx >= 0
	local fx_num = mon_fx and src_mon_fx_idx + 0x1000000 or fx_num -- mon fx index

	-- Find if focused fx name contains the TAG
	local fx_name = (retval == 1 or mon_fx) and select(2,r.TrackFX_GetFXName(tr,fx_num,'')) or select(2,r.TakeFX_GetFXName(take,fx_num,''))
	local tag = EvaluateTAG(fx_name,TAG)

		if not tag then r.MB('         The link wasn\'t created\n\n   since the tag 【'..TAG..'】 hadn\'t been\n\nappended to the focused FX name.','INFO',0) r.defer(function() end) return end -- clear project ext state if no tag

	-- Check if focused FX has any presets
	local t = (retval == 1 or mon_fx) and {r.TrackFX_GetPresetIndex(tr, fx_num)} or (retval == 2 and {r.TakeFX_GetPresetIndex(take, fx_num)} or {})
	-- unpack doesn't work directly inside the ternary expression
	local _, pres_cnt = table.unpack(t)

		if pres_cnt == 0 then resp = r.MB('         The FX has no presets.\n\n      Would you like to proceed\n\n   with the link creation anyway?','PROMPT',4)
			if resp == 7 then r.defer(function() end) return end
		end

	-- Collect data to be saved as ext state and save the state
	local obj_type = (mon_fx or retval == 1 and fx_num >= 16777216) and 11 or (retval == 1 and 10 or (retval == 2 and 2))
	local fx_GUID = (retval == 1 or mon_fx) and r.TrackFX_GetFXGUID(tr,fx_num) or r.TakeFX_GetFXGUID(take,fx_num)

	local state = r.SetProjExtState(0, scr_name, 'PRESET_SWITCHER_DATA', fx_GUID)

		if state and state > 0 then resp = r.MB('\t   The link has been created.\n\n\tTo keep it for future sessions\n\n\t  the project must be saved.\n\n          "YES" - just Save   "NO" - Save As...\n\n            or save later at your convenience.','PROMPT',3)
			if resp ~= 2 then mode = resp == 7 -- false if 6
			r.Main_SaveProject(0, mode)
			else end
		r.defer(function() end) return end

	end


function GetPreset(cmd_ID)

local play_state = r.GetPlayState()
	if r.GetToggleCommandStateEx(0, r.NamedCommandLookup('_SWSMA_TOGGLE')) == 1 -- SWS: Toggle marker actions enable
	and (play_state & 1 == 1 -- playing
	or play_state & 4 == 4) -- recording
	then
	local cmd_ID = r.ReverseNamedCommandLookup(cmd_ID)
	local play_pos = r.GetPlayPosition()
	local mrk_idx, reg_idx = reaper.GetLastMarkerAndCurRegion(0, play_pos)
	local retval, isrgn, mrk_pos, rgnend, mrk_name, mrk_num = reaper.EnumProjectMarkers(mrk_idx)
	local preset = mrk_name:match('!.*%s(.*)$')
	return type(tonumber(preset)) == 'number' and tonumber(preset) or preset -- either index or name
	end

end


-- these functions are used for convenient breaking out from a nested loop with return and to cut down redundancy

function NavigateTrackFXPresets(tr, fx_type, fx_cnt, fx_GUID, TAG, preset)

	if fx_cnt > 0 then
		for i = 0, fx_cnt-1 do
		local fx_num = obj_type == '10' and i or i+0x1000000
		local fx_guid = r.TrackFX_GetFXGUID(tr, fx_num)
		local _, fx_name = r.TrackFX_GetFXName(tr, fx_num,'')
		local tag = EvaluateTAG(fx_name,TAG)
			if fx_guid == fx_GUID and tag then
			local _, preset_cnt = r.TrackFX_GetPresetIndex(tr, fx_num)
				if preset_cnt == 0 then tag = 'no presets' return tag
				else
				local pres = (preset and type(preset) == 'number' and preset <= preset_cnt) and r.TrackFX_SetPresetByIndex(tr, fx_num, preset-1) -- if index, -1 since count starts from zero
				or (preset and r.TrackFX_SetPreset(tr, fx_num, preset) -- if name
				or r.TrackFX_NavigatePresets(tr, fx_num, -1)) -- -1 = backwards
				_, tr_name = r.GetTrackName(tr)
				_, pres_name = r.TrackFX_GetPreset(tr, fx_num, '') -- for undo caption
				return tag, tr_name, fx_name, fx_num, pres_name end -- except the tag the values are meant for undo caption, fx_num for being able to distingush between main and input/mon fx
			end
		end
	end

end

function NavigateTakeFXPresets(fx_GUID, TAG, preset)

	if r.CountMediaItems(0) > 0 then
		for i = 0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
		local take_cnt = r.CountTakes(item)
			for i = 0, take_cnt-1 do
			local take = r.GetTake(item,i)
				if r.TakeFX_GetCount(take) > 0 then
					for j = 0, r.TakeFX_GetCount(take)-1 do
					local fx_guid = r.TakeFX_GetFXGUID(take,j)
					local _, fx_name = r.TakeFX_GetFXName(take,j,'')
					local tag = EvaluateTAG(fx_name,TAG)
						if fx_guid == fx_GUID and tag then
						local _, preset_cnt = r.TakeFX_GetPresetIndex(take, j)
							if preset_cnt == 0 then tag = 'no presets' return tag
							else
							local pres = (preset and type(preset) == 'number' and preset <= preset_cnt) and r.TakeFX_SetPresetByIndex(take, j, preset-1) -- if index, -1 since count starts from zero
							or (preset and r.TakeFX_SetPreset(take, j, preset) -- if name
							or r.TakeFX_NavigatePresets(take, j, -1)) -- -1 = backwards
							_, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false)
							_, pres_name = r.TakeFX_GetPreset(take, j, '') -- for undo caption
							return tag, take_name, fx_name, take_cnt, i, pres_name end -- except the tag the values are meant for undo caption, 'i' = take_num
						end
					end
				end
			end
		end
	end

end

local preset = GetPreset(cmd_ID)

	-- Traverse tracks main fx chains
	for i = -1, r.CSurf_NumTracks(true)-1 do -- start from -1 to accommodate Master track
	local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
	local fx_cnt = r.TrackFX_GetCount(tr)
	tag, tr_name, fx_name, fx_num, pres_name = NavigateTrackFXPresets(tr, 1, fx_cnt, fx_GUID, TAG, preset) -- for undo caption, except the tag value, 1 is fx_type value
		if tag then break end
	end
	if not tag then -- Traverse tracks input fx chains/Master track monitor fx chain
		for i = -1, r.CSurf_NumTracks(true)-1 do -- start from -1 to accommodate Master track
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
		local fx_cnt = r.TrackFX_GetRecCount(tr)
		tag, tr_name, fx_name, fx_num, pres_name = NavigateTrackFXPresets(tr, 2, fx_cnt, fx_GUID, TAG, preset) -- for undo caption, except the tag value, 2 is fx_type value
			if tag then break end
		end
	end
	if not tag then -- Traverse take fx chains
	tag, take_name, fx_name, take_cnt, take_num, pres_name = NavigateTakeFXPresets(fx_GUID, TAG, preset)
	end

	-- when aborted inside the function due to lack of presets
	if tag == 'no presets' then resp = r.MB('            The FX has no presets.\n\nWould you like to clear the link now?','PROMPT',4)
		if resp == 6 then tag = nil
		else r.defer(function() end) return end
	end

	 -- Clear the link while conditioning the prompt by presense of ext state data in the proj. file
	if not tag then
	local proj_f = r.GetProjectPath('')..(r.GetOS():sub(1,3) == 'Win' and '\\' or '/')..r.GetProjectName(0, '')
	local f = io.open(proj_f, 'r')
	local proj_f = f:read('*a')
	f:close()

	local saved = proj_f:match('PRESET_SWITCHER_DATA%s(.-)\n') -- check if link data was already saved
	local mess = saved and '\t    The link has been cleared.\n\n    To prevent its restoration in the next session\n\n\t  the project must be saved.\n\n          "YES" - just Save   "NO" - Save As...\n\n            or save later at your convenience.' or 'The link has been cleared.'
	local mode = saved and 3 or 0

	r.SetProjExtState(0, scr_name, '', '') resp = r.MB(mess,'PROMPT',mode) -- clear project ext state if no tag
		if resp ~= 2 then
		local mode = resp == 6 and false or (resp == 7 and true)
			if resp ~= 1 then r.Main_SaveProject(0, mode) end -- only if ext state data was saved in the proj. file
		else end
	r.defer(function() end) return
	end

	-- Concatenate undo caption
	local src_name = (fx_num and fx_num >= 16777216 and tr_name == 'MASTER') and 'in Monitor FX chain' or (take_cnt and take_cnt > 1 and 'in take '..tostring(take_num+1)..' of item \''..take_name..'\'' or (take_cnt and take_cnt == 1 and 'in item \''..take_name..'\'' or ((tr_name and tr_name == 'MASTER') and 'on Master track' or (tr_name and 'on '..tr_name))))
	local fx_name = fx_name:match(':%s(.*)%s.-%(') or fx_name -- strip out plugin type prefix and dev name in parentheses in any

	r.Undo_BeginBlock() -- placed here to prevent 'ReaScript:Run' message in the Undo menu bar at return on script errors or prompts, which doesn't impede the actual undo point creation since it's created by Track/TakeFX_NavigatePresets() anyway
	r.Undo_EndBlock('Set '..fx_name..' preset to: \''..pres_name..'\' '..src_name,-1) -- Track/TakeFX_NavigatePresets() function creates an undo point by design which can't be avoided, for Monitor FX no undo point can be created



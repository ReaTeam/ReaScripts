-- @noindex

--[[

* ReaScript name: BuyOne_Dedicated FX presets backwards switcher (TAG dependent) (guide inside).lua
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

To create a link append the TAG defined in the USER SETTINGS below to the name of
such focused FX in the FX chain and run the script.

!!! IMPORTANT !!! The TAG must be be followed by a space if it's appeneded to the
beginning of the FX name (e.g. 'TAG My plugin'), preceded by space at the end of
the name (e.g. 'My plugin TAG') or bordered by spaces in the middle of the name
(e.g. 'My TAG plugin').

After that the script can be used exclusively to switch presets in this FX
only, regardless of the FX focus status.

To unlink the script from an FX simply remove the TAG from the FX name.

!!! WARNING !!! Preset change creates an undo point unless it's a Monitor FX

If after closing the FX UI you happen to forget which FX it was, you can look up
its details in the undo point its preset change creates in the REAPER Undo log
accessible from the main menu panel or via action 'View: Show undo history window'.

	## VIDEO PROCESSOR PLUGIN

Video prosessor is supported since REAPER build 6.26 in which its preset navigation via 
API was introduced.

HOWEVER Video processor instances in the FX chain are named after the selected preset.
When the TAG is applied the name is effectively replaced with the custom one and no longer 
updated to reflect the currently selected preset.


	## MULTIPLE INSTANCES

The script can be duplicated as many times as there're FX needing a dedicated preset
switcher and each of its copy can be used with a different FX, PROVIDED IT HAS A UNIQUE
TAG, since the TAG is the defining factor in the validity of the link between the two.
If more than one FX have the same TAG the script will target the one with the lesser
index, that is the one it will find first searching from the beginning of the project.
That's the main difference of this script from
BuyOne_Dedicated FX presets forward switcher (FX ID dependent)(guide inside).lua

	## AUTOMATING

It also can be automated with SWS/S&M extension action markers provided this option is
turned on in the extension settings at Extensions -> SWS Options -> Marker actions from
the main menu or directly with 'SWS: Enable marker actions' or 'SWS: Toggle marker actions
enable' action in the Action list.

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
ACTION = [[1]]

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

local _,scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('([^\\/]+)%.%w+')


local TAG = TAG:gsub('[%s]','') -- remove empty spaces
local ACTION = ACTION:gsub('[%s]','') ~= ''

	if TAG == '' then r.MB('  The TAG has not been set\n\nin the script USER SETTINGS.','ERROR',0) r.defer(function() end) return end

	if r.CSurf_NumTracks(true) + r.CountMediaItems(0) == 0 then r.MB('No tracks or items in the project.','ERROR',0) r.defer(function() end) return end


function EvaluateTAG(fx_name,TAG)
local tag = TAG:gsub('[%(%)%+%-%[%]%.%^%$%*%?%%]','%%%0')
return fx_name:match('^('..tag..')%s') or fx_name:match('%s('..tag..')%s') or fx_name:match('%s('..tag..')$') or fx_name:match(tag)
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

function NavigateTrackFXPresets(tr, fx_type, fx_cnt, TAG, preset)

	if fx_cnt > 0 then
		for i = 0, fx_cnt-1 do
		local fx_num = fx_type == 1 and i or i+0x1000000
		local _, fx_name = r.TrackFX_GetFXName(tr, fx_num,'')
		local _, tr_name = r.GetTrackName(tr)
		local tag = EvaluateTAG(fx_name,TAG)
			if tag then
			local _, preset_cnt = r.TrackFX_GetPresetIndex(tr, fx_num)
				if preset_cnt == 0 then tag = 'no presets'
				else
				local pres = (preset and type(preset) == 'number' and preset <= preset_cnt) and r.TrackFX_SetPresetByIndex(tr, fx_num, preset-1) -- if index, -1 since count starts from zero
				or (preset and r.TrackFX_SetPreset(tr, fx_num, preset) -- if name
				or r.TrackFX_NavigatePresets(tr, fx_num, -1)) -- -1 = backwards
				_, pres_name = r.TrackFX_GetPreset(tr, fx_num, '') -- for undo caption
				end
			return tag, tr_name, fx_name, fx_num, pres_name end -- except the tag the values are meant for undo caption, fx_num for being able to distingush between main and input/mon fx
		end
	end
end

function NavigateTakeFXPresets(TAG, preset)

	if r.CountMediaItems(0) > 0 then
		for i = 0, r.CountMediaItems(0)-1 do
		local item = r.GetMediaItem(0,i)
		local take_cnt = r.CountTakes(item)
			for i = 0, take_cnt-1 do
			local take = r.GetTake(item,i)
				if r.TakeFX_GetCount(take) > 0 then
					for j = 0, r.TakeFX_GetCount(take)-1 do
					local _, fx_name = r.TakeFX_GetFXName(take,j,'')
					local _, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false)
					local tag = EvaluateTAG(fx_name,TAG)
						if tag then
						local _, preset_cnt = r.TakeFX_GetPresetIndex(take, j)
							if preset_cnt == 0 then tag = 'no presets'
							else
							local pres = (preset and type(preset) == 'number' and preset <= preset_cnt) and r.TakeFX_SetPresetByIndex(take, j, preset-1) -- if index, -1 since count starts from zero
							or (preset and r.TakeFX_SetPreset(take, j, preset) -- if name
							or r.TakeFX_NavigatePresets(take, j, -1)) -- -1 = backwards
							_, pres_name = r.TakeFX_GetPreset(take, j, '') -- for undo caption
							end
						return tag, take_name, fx_name, take_cnt, i, pres_name end -- except the tag the values are meant for undo caption, 'i' = take_num
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
	tag, tr_name, fx_name, fx_num, pres_name = NavigateTrackFXPresets(tr, 1, fx_cnt, TAG, preset) -- for undo caption, except the tag value, 1 is fx_type value
		if tag then break end
	end
	if not tag then -- Traverse tracks input fx chains/Master track monitor fx chain
		for i = -1, r.CSurf_NumTracks(true)-1 do -- start from -1 to accommodate Master track
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
		local fx_cnt = r.TrackFX_GetRecCount(tr)
		tag, tr_name, fx_name, fx_num, pres_name = NavigateTrackFXPresets(tr, 2, fx_cnt, TAG, preset) -- for undo caption, except the tag value, 2 is fx_type value
			if tag then break end
		end
	end
	if not tag then -- Traverse take fx chains
	tag, take_name, fx_name, take_cnt, take_num, pres_name = NavigateTakeFXPresets(TAG, preset)
	end

	if not tag then r.MB('Either there\'s no FX tagged with 【'..TAG..'】\n\n      or there\'re no FX in the project.', 'ERROR', 0) r.defer(function() end) return end

	-- Concatenate undo caption
	local src_name = (fx_num and fx_num >= 16777216 and tr_name == 'MASTER') and 'in Monitor FX chain' or (take_cnt and take_cnt > 1 and 'in take '..tostring(take_num+1)..' of item \''..take_name..'\'' or (take_cnt and take_cnt == 1 and 'in item \''..take_name..'\'' or ((tr_name and tr_name == 'MASTER') and 'on Master track' or (tr_name and 'on '..tr_name))))
	local fx_name = fx_name:match(':%s(.*)%s.-%(') or fx_name -- strip out plugin type prefix and dev name in parentheses in any

	-- when aborted inside the function due to lack of presets
	if tag == 'no presets' then resp = r.MB(fx_name..' '..src_name..' has no presets.','ERROR',0) r.defer(function() end) return end

	r.Undo_BeginBlock() -- placed here to prevent 'ReaScript:Run' message in the Undo menu bar at return on script error, which doesn't impede the actual undo point creation since it's created by Track/TakeFX_NavigatePresets() anyway
	r.Undo_EndBlock('Set '..fx_name..' preset to: \''..pres_name..'\' '..src_name,-1) -- Track/TakeFX_NavigatePresets() function creates an undo point by design which can't be avoided, for Monitor FX no undo point can be created




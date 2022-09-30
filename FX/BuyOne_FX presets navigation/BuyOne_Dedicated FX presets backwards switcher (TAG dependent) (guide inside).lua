-- @noindex

--[[

* ReaScript name: BuyOne_Dedicated FX presets backwards switcher (TAG dependent) (guide inside).lua
* Author: BuyOne
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Version: 1.1
* Forum Thread:
* Demo:
* REAPER: at least v5.962
* Changelog:
	+ v1.0 	Initial release
	+ v1.1	Added option for using custom preset lists for selective cycling

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

The script can work with a custom preset list allowing cycling through a selection
of presets rather than the entire list, see CUSTOM_PRESET_LIST setting
in the USER SETTINGS below.

!!! WARNING !!!

Preset change creates an undo point unless it's a Monitor FX

If after closing the FX UI you happen to forget which FX it was, you can look up
its details in the undo point its preset change creates in the REAPER Undo log
accessible from the main menu panel or via action 'View: Show undo history window'.

If, when you apply the script to a focused FX with the TAG, the presets don't change
there's an earlier (with a smaller project wide index) track or take with the same TAG 
which IS affected by the script.

If in the preset list, either full or custom, there're presets with identical names
the script will glitch due to REAPER API bug https://forum.cockos.com/showthread.php?t=270990
and won't allow cycling through all presets in the list


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
If more than one track and/or take FX have the same TAG the script will target track FX
first then targetting the FX with the lesser index, that is the one it will find first
searching from the beginning of the project and starting with tracks.
That's the main difference of this script from
BuyOne_Dedicated FX presets backwards switcher (FX ID dependent)(guide inside).lua

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
'BuyOne_Extract focused FX preset count, list, active preset number and name.lua' script.

If preset number or preset name featured in the action marker aren't found in
the FX preset list or are left out of the action marker name, previous preset is selected.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Place any alphanumeric character or a combination thereof without spaces
-- between the double square brackets next to it.
TAG = [[PC]]

-- Only relevant if the setting CUSTOM_PRESET_LIST 
-- is enabled below;
-- if the current setting is enabled, preset names 
-- are immaterial, only their numbers matter,
-- this allows changing names of the presets from the custom list
-- and using the custom preset list to cycle through 
-- presets of other plugins provided their preset lists 
-- are long enough to include at least some of the preset 
-- numbers featured in the custom list,
-- BUT creating new presets for the original plugin may throw 
-- off the configured preset sequence if the plugin preset list is re-ordered;
-- conversely, if not enabled the custom preset list will 
-- be pretty much tied to a single plugin whose preset names 
-- will match it and creating new presets won't affect the functionality;
-- to enable place any alphanumeric character between the quotation marks
INDEX_BASED_PRESET_SWITCH = ""

-- Replace the text between the double square brackets
-- with the list of presets obtained using
-- 'BuyOne_Extract focused FX preset count, list, active preset number and name.lua' script
-- and select presets for cycling by prefixing their number in the list with +, e.g:
-- +34 MY_PRESET_1
-- 35 MY_PRESET_2
-- +36 MY_PRESET_3
-- adding the entire extracted list isn't necessary
-- as long as the entries which are added are marked with +;
-- the script can be used with any plugin whose preset NUMBERS
-- match those in the custom list regardless of their names,
-- if you want it to work exclusively with the plugin the list
-- originally belongs to, let me know;
-- it's a good idea to write down what plugin on which track/item
-- is linked to the script or wrap the script in a custom action
-- having included the plugin data in the custom action name,
-- in the latter case the custom action command ID can be used
-- in action markers to trigger the script
CUSTOM_PRESET_LIST = 
[[

R E P L A C E  T H I S  T E X T

]]

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

	if TAG == '' then r.MB('  The TAG has not been set\n\nin the script USER SETTINGS.','ERROR',0) r.defer(function() end) return end

	if r.CSurf_NumTracks(true) + r.CountMediaItems(0) == 0 then r.MB('No tracks or items in the project.','ERROR',0) r.defer(function() end) return end


function Construct_Custom_Preset_Array(CUSTOM_PRESET_LIST, INDEX_BASED_PRESET_SWITCH)
-- if the array is index based, the custom list can be used with presets
-- of any plugin as long as their indices match those in the array;
-- in order to limit the custom list to specific plugin
-- its name can be included as the 2nd field, e.g.
-- t[#t+1] = {idx-1, line:match('%d (.+)')}
-- to be then evaluated against the currently or next selected preset inside Switch_FX_Preset() function
-- eventually was emplemented differently
local t = {}
	for line in CUSTOM_PRESET_LIST:gmatch('[^\n]+') do
		if line and line:match('^%s*%+') then
		local value = INDEX_BASED_PRESET_SWITCH and tonumber(line:match('^%s*%+%s*(%d+)'))
		or not INDEX_BASED_PRESET_SWITCH and line:match('^%s*%+%s*(%d+ .+)') -- preset name
			if value then t[#t+1] = value end
		end
	end
return t
end


function Switch_FX_Preset(obj, fx_idx, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH, forward)

local tr, take = r.ValidatePtr(obj, 'MediaTrack*'), r.ValidatePtr(obj, 'MediaItem_Take*')
local get_pres_idx, get_pres_name, set_preset, navigate_presets = table.unpack(tr and {r.TrackFX_GetPresetIndex, r.TrackFX_GetPreset, INDEX_BASED_PRESET_SWITCH and r.TrackFX_SetPresetByIndex or r.TrackFX_SetPreset, r.TrackFX_NavigatePresets} or take and {r.TakeFX_GetPresetIndex, r.TakeFX_GetPreset, INDEX_BASED_PRESET_SWITCH and r.TakeFX_SetPresetByIndex or r.TakeFX_SetPreset, r.TakeFX_NavigatePresets})
local cur_pres_idx, pres_cnt = get_pres_idx(obj, fx_idx) -- only needed if set_preset() function is used below
local retval, cur_pres_name = get_pres_name(obj, fx_idx, '')

	local function select_value(value, INDEX_BASED_PRESET_SWITCH)
	return INDEX_BASED_PRESET_SWITCH and value-1 or value:match('^%d+ (.+)') -- -1 since the listed indices count is 1-based
	end
	
	if (not cust_pres_list_t or cust_pres_list_t and #cust_pres_list_t == 0) and pres_cnt > 0 then
		if cur_pres_idx == pres_cnt then -- 'No preset' is selected, in which case these values are equal (the index is out of the 0-based range), start from the beginning or the end of the list, navigate_presets() for some reason starts from the 2nd preset
		set_preset(obj, fx_idx, forward and 0 or pres_cnt-1)
		else -- navigate as normal
		navigate_presets(obj, fx_idx, forward and 1 or -1)
		end
	elseif cust_pres_list_t and #cust_pres_list_t > 1 then
		for k, pres_idx_name in ipairs(cust_pres_list_t) do -- search for the current preset idx in the table the select one from the next table slot
			if INDEX_BASED_PRESET_SWITCH and pres_idx_name-1 == cur_pres_idx -- -1 since the listed indices count is 1-based
			or not INDEX_BASED_PRESET_SWITCH and cur_pres_name == pres_idx_name:match('^%d+ (.+)') then
			local next_pres_idx_name = forward and cust_pres_list_t[k+1] or not forward and cust_pres_list_t[k-1]
			local next_pres_idx_name = forward and not next_pres_idx_name and cust_pres_list_t[1] or not forward and not next_pres_idx_name and cust_pres_list_t[#cust_pres_list_t] or next_pres_idx_name -- next_pres_idx being nil means that the value is out of the table's range hence the count needs to be wrapped around
			set_preset(obj, fx_idx, select_value(next_pres_idx_name, INDEX_BASED_PRESET_SWITCH))
			break
			elseif cur_pres_idx == pres_cnt then -- OR cur_pres_name == '' // if the plugin started out with 'No preset' selected in which case these values are equal (the index is out of the 0-based range), custom list routines won't work
			local new_pres_idx_name = forward and cust_pres_list_t[1] or not forward and cust_pres_list_t[#cust_pres_list_t] -- start from the 1st if forward and from the last if backwards
			set_preset(obj, fx_idx, select_value(new_pres_idx_name, INDEX_BASED_PRESET_SWITCH))
			break
			else -- if on the first main loop cycle custom list preset is diff from the active custom list preset or a preset not from the custom list is currently active, select first preset from the list which is greater or smaller than the index of the current preset depending on the cycling direction
				local function return_idx(value, INDEX_BASED_PRESET_SWITCH)
				return INDEX_BASED_PRESET_SWITCH and value or value:match('%d+')
				end
			local exit
			local start, fin, dir = table.unpack(forward and {1, #cust_pres_list_t, 1} or {#cust_pres_list_t, 1, -1})
				for idx = start, fin, dir do
				local pres_idx_name = cust_pres_list_t[idx]
				local pres_idx = tonumber(return_idx(pres_idx_name, INDEX_BASED_PRESET_SWITCH))-1 -- either name based or index based list // -1 since the listed indices count is 1-based
				local pres_idx_name = forward and (cur_pres_idx > tonumber(return_idx(cust_pres_list_t[#cust_pres_list_t], INDEX_BASED_PRESET_SWITCH))-1 and cust_pres_list_t[1] or pres_idx > cur_pres_idx and pres_idx_name)
				or not forward and (cur_pres_idx < tonumber(return_idx(cust_pres_list_t[1], INDEX_BASED_PRESET_SWITCH))-1 and cust_pres_list_t[#cust_pres_list_t] or pres_idx < cur_pres_idx and pres_idx_name) -- accounting for when active preset index is greater or smaller than the index of the first and the last presets in the custom list, which covers the very 1st and the very last presets // -1 since the listed indices count is 1-based
					if pres_idx_name then
					set_preset(obj, fx_idx, select_value(pres_idx_name, INDEX_BASED_PRESET_SWITCH))
					exit = 1
					break end
				end
				if exit then break end -- exit the main loop
			end
		end
	end

end


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
	local preset = mrk_name:match('!.-%s+(.+)$') -- accounting for mulitple leading empty spaces
	local preset = preset:match('.+[%w%p]') -- trimming trailing empty space if any
	return type(tonumber(preset)) == 'number' and tonumber(preset) or preset -- either index or name
	end

end


-- these functions are used for convenient breaking out from a nested loop with return and to cut down redundancy

function NavigateTrackFXPresets(tr, fx_type, fx_cnt, TAG, preset, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH)

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
				local pres = preset and type(preset) == 'number' and preset <= preset_cnt and r.TrackFX_SetPresetByIndex(tr, fx_num, preset-1) -- if preset index is used in an action marker // -1 since count starts from zero
				or preset and r.TrackFX_SetPreset(tr, fx_num, preset) -- if preset name is used in an action marker
				or Switch_FX_Preset(tr, fx_num, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH, false) -- if the script is run manually // forward false
				_, pres_name = r.TrackFX_GetPreset(tr, fx_num, '') -- for undo caption
				end
			return tag, tr_name, fx_name, fx_num, pres_name end -- except the tag the values are meant for undo caption, fx_num for being able to distingush between main and input/mon fx
		end
	end
end


function NavigateTakeFXPresets(TAG, preset, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH)

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
							local pres = preset and type(preset) == 'number' and preset <= preset_cnt and r.TakeFX_SetPresetByIndex(take, j, preset-1) -- if preset index is used in an action marker // -1 since count starts from zero
							or preset and r.TakeFX_SetPreset(take, j, preset) -- if preset name is used in an action marker
							or Switch_FX_Preset(take, j, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH, false) -- if the script is run manually // forward false
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

local INDEX_BASED_PRESET_SWITCH = INDEX_BASED_PRESET_SWITCH:gsub('[%s]','') ~= ''

local cust_pres_list_t = Construct_Custom_Preset_Array(CUSTOM_PRESET_LIST, INDEX_BASED_PRESET_SWITCH)

	-- Traverse tracks main fx chains
	for i = -1, r.CSurf_NumTracks(true)-1 do -- start from -1 to accommodate Master track
	local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
	local fx_cnt = r.TrackFX_GetCount(tr)
	tag, tr_name, fx_name, fx_num, pres_name = NavigateTrackFXPresets(tr, 1, fx_cnt, TAG, preset, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH) -- for undo caption, except the tag value, 1 is fx_type value
		if tag then break end
	end
	if not tag then -- Traverse tracks input fx chains/Master track monitor fx chain
		for i = -1, r.CSurf_NumTracks(true)-1 do -- start from -1 to accommodate Master track
		local tr = r.GetTrack(0,i) or r.GetMasterTrack(0)
		local fx_cnt = r.TrackFX_GetRecCount(tr)
		tag, tr_name, fx_name, fx_num, pres_name = NavigateTrackFXPresets(tr, 2, fx_cnt, TAG, preset, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH) -- for undo caption, except the tag value, 2 is fx_type value
			if tag then break end
		end
	end
	if not tag then -- Traverse take fx chains
	tag, take_name, fx_name, take_cnt, take_num, pres_name = NavigateTakeFXPresets(TAG, preset, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH)
	end

	if not tag then r.MB('Either there\'s no FX tagged with 【'..TAG..'】\n\n      or there\'re no FX in the project.', 'ERROR', 0) r.defer(function() end) return end

	-- Concatenate undo caption
	local src_name = (fx_num and fx_num >= 16777216 and tr_name == 'MASTER') and 'in Monitor FX chain' or (take_cnt and take_cnt > 1 and 'in take '..tostring(take_num+1)..' of item \''..take_name..'\'' or (take_cnt and take_cnt == 1 and 'in item \''..take_name..'\'' or ((tr_name and tr_name == 'MASTER') and 'on Master track' or (tr_name and 'on '..tr_name))))
	local fx_name = fx_name:match(':%s(.*)%s.-%(') or fx_name -- strip out plugin type prefix and dev name in parentheses in any

	-- when aborted inside the function due to lack of presets
	if tag == 'no presets' then resp = r.MB(fx_name..' '..src_name..' has no presets.','ERROR',0) r.defer(function() end) return end

	r.Undo_BeginBlock() -- placed here to prevent 'ReaScript:Run' message in the Undo menu bar at return on script error, which doesn't impede the actual undo point creation since it's created by Track/TakeFX_NavigatePresets() anyway
	r.Undo_EndBlock('Set '..fx_name..' preset to: \''..pres_name..'\' '..src_name,-1) -- Track/TakeFX_NavigatePresets() function creates an undo point by design which can't be avoided, for Monitor FX no undo point can be created




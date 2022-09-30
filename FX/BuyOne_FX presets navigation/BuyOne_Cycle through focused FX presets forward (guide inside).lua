-- @noindex

--[[

* ReaScript name: BuyOne_Cycle through focused FX presets forward (guide inside).lua
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

The script allows cycling through presets of the last focused FX in a forward
direction.

Start by opening an FX in its FX chain or floating window and run the script.

After the first application of the script to a focused FX the FX UI can be closed.

The script keeps targeting the last focused FX until another FX comes into focus
which is by opening such another FX UI in its FX chain or floating window and
running the script at least once.

By enabling SWITCH_BY_OBJ_SEL option in the USER SETTINGS below it's possible to
make the script switch to another FX only when the object (item or track) such
another FX belongs to is explicitly selected. Until such explicit selection is made
the script will stick to the previously focused FX even when another FX gets the focus.

While SWITCH_BY_OBJ_SEL option is ON, to switch the script to an FX focused in another
take of an item select any take, to switch it to a focused Monitor FX select the
Master track.

The script can work with a custom preset list allowing cycling through a selection
of presets rather than the entire list, see CUSTOM_PRESET_LIST setting
in the USER SETTINGS below.

!!! WARNING !!!

Preset change creates an undo point unless it's a Monitor FX

If after closing the FX UI you happened to forget which FX it was, you can look up
its details in the undo point its preset change creates in the REAPER Undo log
accessible from the main menu panel or via action 'View: Show undo history window'.

If in the preset list, either full or custom, there're presets with identical names
the script will glitch due to REAPER API bug https://forum.cockos.com/showthread.php?t=270990
and won't allow cycling through all presets in the list

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable the settings SWITCH_BY_OBJ_SEL and/or INDEX_BASED_PRESET_SWITCH
-- place any alphanumeric character between the quotation marks next to it.
-- Conversely, to disable it remove the character.
-- Try to not leave empty spaces.

-- See explanation in the GUIDE above
SWITCH_BY_OBJ_SEL = ""

--------------------------------------------------------
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
-- will match it and creating new presets won't affect the functionality
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
-- the order doesn't matter as long as the numbers are there;
-- the script can be used with any plugin whose preset NUMBERS
-- match those in the custom list regardless of their names,
-- if you want it to work exclusively with the plugin the list
-- originally belongs to, let me know;
-- it's a good idea to write down what plugin the list belongs to
-- or wrap the script in a custom action having included the plugin
-- name in the custom action name
CUSTOM_PRESET_LIST =
[[

R E P L A C E  T H I S  T E X T

]]

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
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


local SWITCH_BY_OBJ_SEL = SWITCH_BY_OBJ_SEL:gsub('[%s]','') ~= ''
local INDEX_BASED_PRESET_SWITCH = INDEX_BASED_PRESET_SWITCH:gsub('[%s]','') ~= ''

local retval, track_num, item_num, fx_num = r.GetFocusedFX()
local src_mon_fx_idx = GetMonFXProps() -- get Monitor FX
local state = r.GetExtState(scr_name, cmd_ID)

	if retval == 0 and src_mon_fx_idx < 0 and state == '' then r.MB('     No FX is in focus.','ERROR',0) r.defer(function() end) return end -- on the very 1st run in a session, when no focused fx and no data has been stored

local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack()
local item = r.GetTrackMediaItem(tr, item_num)
local mon_fx = retval == 0 and src_mon_fx_idx >= 0
local no_focused_fx = retval == 0 and src_mon_fx_idx < 0


	if state == '' and no_focused_fx then
	r.MB('     No FX is in focus.','ERROR',0) r.defer(function() end) return
	elseif state == '' or state ~= table.concat({r.GetFocusedFX()},';')..';'..tostring(src_mon_fx_idx)
	and not no_focused_fx -- update ext state if return values change, ignoring state when no fx chain is in focus to keep the last saved values and cycle through presets with last focused fx closed
	and ((SWITCH_BY_OBJ_SEL and ((retval == 1 or mon_fx) and r.IsTrackSelected(tr)) or (retval == 2 and r.IsMediaItemSelected(item))) or not SWITCH_BY_OBJ_SEL)
	then
	r.SetExtState(scr_name, cmd_ID, retval..';'..track_num..';'..item_num..';'..fx_num..';'..src_mon_fx_idx, false)
	end

local array = {r.GetExtState(scr_name, cmd_ID):match('(.-);(.-);(.-);(.-);(.-)$')}

		for k,v in next, array do
		array[k] = tonumber(v)
		end

local retval, track_num, item_num, fx_num, src_mon_fx_idx = table.unpack(array)


local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack()
local take_num = retval == 2 and fx_num>>16 -- for undo point
local take = retval == 2 and r.GetMediaItemTake(r.GetTrackMediaItem(tr, item_num), take_num)
local take_cnt = retval == 2 and r.CountTakes(r.GetTrackMediaItem(tr, item_num)) -- for undo point
local fx_num = (retval == 2 and fx_num >= 65536) and fx_num & 0xFFFF or fx_num -- take fx index
local mon_fx = retval == 0 and src_mon_fx_idx >= 0
local fx_num = mon_fx and src_mon_fx_idx + 0x1000000 or fx_num -- mon fx index

local t = (retval == 1 or mon_fx) and {r.TrackFX_GetPresetIndex(tr, fx_num)} or (retval == 2 and {r.TakeFX_GetPresetIndex(take, fx_num)} or {})
-- unpack doesn't work directly inside the ternary expression
local ret, pres_cnt = table.unpack(t)

	if pres_cnt == 0 then r.MB('No presets in the last focused FX.','ERROR',0) r.defer(function() end) return end

	if pres_cnt > 0 then

	local cust_pres_list_t = Construct_Custom_Preset_Array(CUSTOM_PRESET_LIST, INDEX_BASED_PRESET_SWITCH)

	r.Undo_BeginBlock()
		if retval == 1 or mon_fx then
		Switch_FX_Preset(tr, fx_num, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH, true) -- forward true
		 _, fx_name = r.TrackFX_GetFXName(tr, fx_num, '') -- for undo caption
		_, pres_name = r.TrackFX_GetPreset(tr, fx_num, '') -- for undo caption
		elseif retval == 2 then
		Switch_FX_Preset(take, fx_num, cust_pres_list_t, INDEX_BASED_PRESET_SWITCH, true) -- forward true
		_, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false)
		_, fx_name = r.TakeFX_GetFXName(take, fx_num, '') -- for undo caption
		_, pres_name = r.TakeFX_GetPreset(take, fx_num, '') -- for undo caption
		end

	local _, tr_name = r.GetTrackName(tr)
	local src_name = mon_fx and 'in Monitor FX chain' or ((take and take_cnt > 1) and 'in take '..tostring(take_num+1)..' of item \''..take_name..'\'' or ((take and take_cnt == 1) and 'in item \''..take_name..'\'' or (tr_name == 'MASTER' and 'on Master track' or 'on '..tr_name))) -- for undo caption
	local fx_name = fx_name:match(':%s(.*)%s.-%(') or fx_name -- strip out plugin type prefix and dev name in parentheses in any

	r.Undo_EndBlock('Set '..fx_name..' preset to: \''..pres_name..'\' '..src_name,-1) -- Track/TakeFX_NavigatePresets() function creates an undo point by design which can't be avoided, for Monitor FX no undo point can be created

	end





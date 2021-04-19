-- @noindex

--[[

* ReaScript name: BuyOne_Cycle through focused FX presets forward (guide inside).lua
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

!!! WARNING !!! Preset change creates an undo point unless it's a Monitor FX

If after closing the FX UI you happened to forget which FX it was, you can look up
its details in the undo point its preset change creates in the REAPER Undo log
accessible from the main menu panel or via action 'View: Show undo history window'.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable the option place any alphanumeric character between the quotation
-- marks next to it.
-- Conversely, to disable it remove the character.
-- Try to not leave empty spaces.

SWITCH_BY_OBJ_SEL = ""

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


local SWITCH_BY_OBJ_SEL = SWITCH_BY_OBJ_SEL:gsub('[%s]','') ~= ''

local retval, track_num, item_num, fx_num = r.GetFocusedFX()
local src_mon_fx_idx = GetMonFXProps() -- get Monitor FX
local state = r.GetExtState(scr_name, cmd_ID)

	if retval == 0 and src_mon_fx_idx < 0 and state == '' then r.MB('     No FX is in focus.','ERROR',0) r.defer(function() end) return end -- on the very 1st run in a session, when no focused fx and no data has been stored

local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack()
local item = r.GetTrackMediaItem(tr, item_num)
local mon_fx = retval == 0 and src_mon_fx_idx >= 0
local no_focused_fx = retval == 0 and src_mon_fx_idx < 0


Msg(item and r.IsMediaItemSelected(item))

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

	r.Undo_BeginBlock()
		if retval == 1 or mon_fx then
		r.TrackFX_NavigatePresets(tr, fx_num, 1)
		 _, fx_name = r.TrackFX_GetFXName(tr, fx_num, '') -- for undo caption
		_, pres_name = r.TrackFX_GetPreset(tr, fx_num, '') -- for undo caption
		elseif retval == 2 then
		r.TakeFX_NavigatePresets(take, fx_num, 1)
		_, take_name = r.GetSetMediaItemTakeInfo_String(take, 'P_NAME', '', false)
		_, fx_name = r.TakeFX_GetFXName(take, fx_num, '') -- for undo caption
		_, pres_name = r.TakeFX_GetPreset(take, fx_num, '') -- for undo caption
		end

	local _, tr_name = r.GetTrackName(tr)
	local src_name = mon_fx and 'in Monitor FX chain' or ((take and take_cnt > 1) and 'in take '..tostring(take_num+1)..' of item \''..take_name..'\'' or ((take and take_cnt == 1) and 'in item \''..take_name..'\'' or (tr_name == 'MASTER' and 'on Master track' or 'on '..tr_name))) -- for undo caption
	local fx_name = fx_name:match(':%s(.*)%s.-%(') or fx_name -- strip out plugin type prefix and dev name in parentheses in any

	r.Undo_EndBlock('Set '..fx_name..' preset to: \''..pres_name..'\' '..src_name,-1) -- Track/TakeFX_NavigatePresets() function creates an undo point by design which can't be avoided, for Monitor FX no undo point can be created

	end



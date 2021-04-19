-- @noindex

--[[

* ReaScript name: BuyOne_Extract focused FX preset count, active preset number and name.lua
* Author: BuyOne
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Version: 1.0
* Forum Thread:
* Demo:
* REAPER: at least v5.962
* Changelog:
	+ v1.0 	Initial release

=========================================================================

A preset name can be easily copied by selecting the preset, clicking 
the '+' button on the FX panel and selecting 'Rename preset...' option.
But its number must be counted.

The script is intended to simplify the task.

The format is: 
preset count::preset number::preset name

Video prosessor presets are supposed to be supported since REAPER build 6.26.

]]


function Msg(param)
reaper.ShowConsoleMsg(tostring(param)..'\n')
end

local r = reaper

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


local retval, track_num, item_num, fx_num = r.GetFocusedFX()
local src_mon_fx_idx = GetMonFXProps() -- get Monitor FX
	
		if retval == 0 and src_mon_fx_idx < 0 then r.MB('No FX is in focus.','ERROR',0) r.defer(function() end) return end

local tr = r.GetTrack(0,track_num-1) or r.GetMasterTrack()
local take_num = retval == 2 and fx_num>>16
local take = retval == 2 and r.GetMediaItemTake(r.GetTrackMediaItem(tr, item_num), take_num)
local fx_num = (retval == 2 and fx_num >= 65536) and fx_num & 0xFFFF or fx_num -- take fx index
local mon_fx = retval == 0 and src_mon_fx_idx >= 0
local fx_num = mon_fx and src_mon_fx_idx + 0x1000000 or fx_num -- mon fx index
	

-- Check if focused FX has any presets
local t = (retval == 1 or mon_fx) and {r.TrackFX_GetPresetIndex(tr, fx_num)} or (retval == 2 and {r.TakeFX_GetPresetIndex(take, fx_num)} or {})
-- unpack doesn't work directly inside the ternary expression
local _, pres_cnt = table.unpack(t)

	if pres_cnt == 0 then resp = r.MB('The FX has no presets.','PROMPT',0) r.defer(function() end) return end


local count = (retval == 1 or mon_fx) and ({r.TrackFX_GetPresetIndex(tr, fx_num)})[2] or (retval == 2 and ({r.TakeFX_GetPresetIndex(take, fx_num)})[2])
local pres_num = (retval == 1 or mon_fx) and r.TrackFX_GetPresetIndex(tr, fx_num) or (retval == 2 and r.TakeFX_GetPresetIndex(take, fx_num))
local pres_name = (retval == 1 or mon_fx) and ({r.TrackFX_GetPreset(tr, fx_num, '')})[2] or (retval == 2 and 
({r.TakeFX_GetPreset(take, fx_num, '')})[2])

	r.ShowConsoleMsg(tostring(count)..'::'..tostring(pres_num+1)..'::'..pres_name, r.ClearConsole()) -- +1 since the count is 0 based

do r.defer(function() end) return end



	
	
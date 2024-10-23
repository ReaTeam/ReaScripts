--[[
ReaScript name: Toggle (Un)Bypass input FX for selected tracks (27 scripts for various permutations)
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
About: 	To complement similar actions of the SWS extension for the track main FX chain.   
	Supports Monitoring FX if the Master track is selected.  
	If slots with greater number are required, duplicate the sctipt which
	performs the desired action and change the FX slot number in its name.    	
	Toggle scripts affecting all input FX on selected tracks target each FX
	individually so their state is reversed independently of the other FX state.
Metapackage: true
Provides: . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 1 bypass for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 2 bypass for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 3 bypass for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX 4 bypass for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 1 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 2 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 3 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX 4 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 1 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 2 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 3 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX 4 for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 1) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 2) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 3) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Toggle input FX bypass (except 4) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 1) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 2) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 3) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Bypass input FX (except 4) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 1) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 2) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 3) for selected tracks.lua
          . > BuyOne_Toggle (Un)Bypass input FX for selected tracks/BuyOne_Unbypass input FX (except 4) for selected tracks.lua
]]



function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper

function Error_Tooltip(text)
local x, y = r.GetMousePosition()
r.TrackCtl_SetToolTip(text:upper():gsub('.','%0 '), x, y, true) -- spaced out // topmost true
end

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('.+[\\/](.+)%.lua') -- whole script name without path and extension

local fx_idx = scr_name:match('input FX (%d+)') or scr_name:match('%(except (%d+)%)')
local except = scr_name:match('%(except %d+%)')
local toggle = scr_name:match('Toggle input FX')
local unbypass = scr_name:match('Unbypass input FX')
local bypass = scr_name:match('Bypass input FX')
local fx_idx = fx_idx and 0x1000000+tonumber(fx_idx)-1

local tr_cnt = r.CountSelectedTracks2(0, true) -- wantmaster true

local err = tr_cnt == 0 or not toggle and not unbypass and not bypass

	if err then
	Error_Tooltip(tr_cnt == 0 and '\n\n no selected tracks \n\n' or not toggle and not unbypass and '\n\n invalid script name \n\n')
	return r.defer(function() do return end end) end


r.PreventUIRefresh(1)
r.Undo_BeginBlock()

local fx_cnt = 0

	for i = 0, tr_cnt-1 do -- wantmaster true
	local tr = r.GetSelectedTrack(0,i) or r.GetMasterTrack(0)
		if except then
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			fx_cnt = fx_cnt+1
				if i+0x1000000 ~= fx_idx then
				local state = toggle and not r.TrackFX_GetEnabled(tr, i+0x1000000) or unbypass and true or false
				r.TrackFX_SetEnabled(tr, i+0x1000000, state)
				end
			end
		elseif fx_idx then
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
				 if i+0x1000000 == fx_idx then found = 1 break end
			end
			if tr_cnt == 1 and not found then Error_Tooltip('\n\n no fx in slot '..(fx_idx-0x1000000+1)..' \n\n') return r.defer(function() do return end end) end
		local state = toggle and not r.TrackFX_GetEnabled(tr, fx_idx) or unbypass and true or false -- 'not' is meant to flip the state
		r.TrackFX_SetEnabled(tr, fx_idx, state)
		else -- all fx
			for i = 0, r.TrackFX_GetRecCount(tr)-1 do
			fx_cnt = fx_cnt+1
			local state = toggle and not r.TrackFX_GetEnabled(tr, i+0x1000000) or unbypass and true or false
			r.TrackFX_SetEnabled(tr, i+0x1000000, state)
			end
		end
	end

	if fx_cnt == 0 then
	Error_Tooltip('\n\n no input fx in selected tracks \n\n')
	return r.defer(function() do return end end) end

r.Undo_EndBlock(scr_name, -1)
r.PreventUIRefresh(-1)






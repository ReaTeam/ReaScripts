--[[
ReaScript name: Update FX chain at object selection when one FX window at a time enabled
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Licence: WTFPL
REAPER: at least v5.962
Screenshots: https://git.io/JXjO6
About:
		Meant to be used only when the option "Only allow one FX chain window open at a time" 
		is enabled at Preferences -> Plug-ins in a global FX chain kind of setup.  
		Normally when option "Only allow one FX chain window open at a time" is enabled, 
		to update currently open FX chain window with another FX chain, FX button must be 
		clicked on the TCP or on the item.  
		This script makes this a bit simpler by allowing to update the window with object 
		selection, which requires less precision than clicking the tiny FX buttons,
		besides ensuring that the FX chain is readily accessible.  
   		Only selection with a mouse click is currently supported.  
		For best experience FX chain window should be docked, but the updating will work 
		just as good with a floating FX chain window.   
		To use it in a docker it's sufficient to dock any FX chain window, the rest will
		stay docked automatically.   
		Take FX chain is always loaded at item selection. The type of track FX chain to be
		loaded at track selection is determined by the USER SETTING below, but you'll still 
		be able to load track FX chain of the other type normally by clicking FX button 
		of the corresponding track.  
		With a click on FX button the currently open FX chain window can be temporarily
		closed until another object is selected.   
		Empty FX chains aren't loaded.

		CAVEATS: FX chain window always becomes focused when updated, which means that if 
		it's docked in a tabbed docker and not active (hidden) it will become active, 
		and if floating it will come in front of other windows.  
		When FX chain changes in a docker it flickers because one is closed and another
		is opened. This is REAPER's behavior which can't be controlled with a script.

]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------

-- 1 - track input FX chain (incl. Monitoring FX chain when Master track is selected)
-- otherwise track main FX chain (incl. Master track FX chain) -- default

TRACK_FX_CHAIN = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

local r = reaper


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

function space(n) -- number of repeats
return string.rep(' ',n)
end

function Check_reaper_ini(key) -- the args must be strings
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
return cont:match(key..'=(%d+)')
end

-- Thanks to mespotine for figuring out config variables
-- https://github.com/mespotine/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt

	if Check_reaper_ini('fxfloat_focus')&2 == 0 then r.MB(space(6)..'The script only makes sense when option\n\n"Only allow one FX chain window open at a time"\n\n'..space(9)..'is enabled at Preferences -> Plug-ins', 'ERROR',0)
  return r.defer(function() if not bla then  return end end) end

input_ch = tonumber(TRACK_FX_CHAIN) == 1
main_ch = not input_ch

local init_tr
local init_take
local init_ctx

function UPDATE_FX_CHAIN()

local sel_tr = (main_ch or input_ch) and r.GetSelectedTrack2(0,0, true) -- wantmaster true
local tr_name = sel_tr and {r.GetTrackName(sel_tr)} -- returns 2 values hence table
local item = r.GetSelectedMediaItem(0,0)
local act_take = item and r.GetActiveTake(item)
local cur_ctx = r.GetCursorContext()

	if sel_tr and (sel_tr ~= init_tr or cur_ctx ~= init_ctx) and cur_ctx == 0 then
	-- curs context makes sure FX chain is only updated when the object is clicked,
	-- unaffected by change in selection performed with actions and API; same for items below;
	-- comparison with init_ctx makes sure that if object selection didn't change while FX chain window content
	-- changed due to clicking objects of other type, another click on such selected object will make its FX chain load
		if main_ch and r.TrackFX_GetCount(sel_tr) > 0 then
		local upd = tr_name[2] == 'MASTER' and r.Main_OnCommand(40846,0) -- Track: View FX chain for master track
		or r.Main_OnCommand(40291,0) -- Track: View FX chain for current/last touched track
		elseif r.TrackFX_GetRecCount(sel_tr) > 0 then
		local upd = tr_name[2] == 'MASTER' and r.Main_OnCommand(41882,0) -- View: Show monitoring FX chain
		or r.Main_OnCommand(40844,0) -- Track: View input FX chain for current/last touched track
		end
	init_tr = sel_tr
	init_ctx = cur_ctx
	end
	if act_take and (act_take ~= init_take or cur_ctx ~= init_ctx) and r.TakeFX_GetCount(act_take) > 0 and cur_ctx == 1
	then
	r.Main_OnCommand(40638,0) -- Item: Show FX chain for item take
	init_take = act_take
	init_ctx = cur_ctx
	end

r.defer(UPDATE_FX_CHAIN)

end


UPDATE_FX_CHAIN()






--[[
ReaScript name: Update FX chain at object selection when one FX window at a time enabled
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.2
Changelog: 	#Added option to prevent updating a docked FX chain when the docker is closed
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
		For best experience FX chain window should be docked, but the updating will work 
		just as good with a floating FX chain window.  
		To use it in a docker it's usually sufficient to dock any FX chain window, 
		the rest will stay docked automatically, yet sometimes adjustment of a few
		individual FX windows may be required.   
		Active take FX chain is always loaded at item selection. The type of track FX chain 
		to be loaded at track selection is determined by the USER SETTING below, but 
		you'll still be able to load track FX chain of the other type normally by clicking 
		FX button of the corresponding track.  
		The currently open FX chain window can be temporarily closed with a click on FX button
		or a by closing its tab in the docker, until another object is selected.   
		Clicking FX button is also a way to re-open a closed FX chain of the same selected 
		object besides having it deselected and selected again.  
		Out of several selected objects only the first one is honored.   
		Empty FX chains aren't loaded as well as track FX chain of the type disabled 
		in the USER SETTINGS.

		CAVEATS
		
		FX chain window always becomes focused when updated, which means that if 
		it's docked and open but not active (hidden) in a tabbed docker it will 
		become active (visible), if it's docked in a closed docker the docker will
		open, and if it's floating it will come in front of other windows.
		
		When FX chain changes in a docker it flickers because one is closed and another
		is opened. This is REAPER's behavior which can't be controlled with a script.
		
		The FX chain of the last selected track which stays selected, can be re-opened 
		with a click on the TCP after the FX chain was replaced with take FX chain, 
		however not vice versa. In order to re-open take FX chain of the last selected 
		item/active take after it was replaced with a track FX chain such item must be
		deselected and selected again.
		
]]

-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable settings insert any alphanumeric character between the quotes

-- If enabled - track input FX chain is loaded
-- (incl. Monitoring FX chain when Master track is selected)
-- otherwise track main FX chain (incl. Master track FX chain) -- default
TRACK_FX_CHAIN = ""

-- To be able to also load take FX chain on item selection,
-- only active take FX chain in a multi-take item can be loaded
TAKE_FX_CHAIN = "1"

-- If enabled, FX chain window can be updated by change in selection performed
-- by means other than mouse click
CHANGE_IN_SELECTION_CHANGES_FOCUS = ""

-- To only have FX chain updated when the docker is open,
-- meant to prevent opening and updating a docked FX chain window
-- when the docker is closed
-- will affect floating FX chain window as well
-- so only useful when one is docked
ONLY_WHEN_DOCKER_OPEN = ""

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

function Check_reaper_ini(key) -- the arg must be a string
local f = io.open(r.get_ini_file(),'r')
local cont = f:read('a*')
f:close()
return cont:match(key..'=(%d+)')
end

-- Thanks to mespotine for figuring out config variables
-- https://github.com/mespotine/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt

	if Check_reaper_ini('fxfloat_focus')&2 == 0 then r.MB(space(6)..'The script only makes sense when option\n\n"Only allow one FX chain window open at a time"\n\n'..space(9)..'is enabled at Preferences -> Plug-ins', 'ERROR',0)
    return r.defer(function() if not bla then  return end end) end

main_ch = #TRACK_FX_CHAIN:gsub(' ','') == 0
take_ch = #TAKE_FX_CHAIN:gsub(' ','') > 0
change_focus = #CHANGE_IN_SELECTION_CHANGES_FOCUS:gsub(' ','') > 0

local init_tr
local init_take = r.GetSelectedMediaItem(0,0) and r.GetActiveTake(r.GetSelectedMediaItem(0,0)) -- ensures that track selection gets priority and there's no competition between track and take fx chains of selected objects when the script is launched because act_take ~= init_take condition won't be true
local init_ctx


function UPDATE_FX_CHAIN()

local DOCKER_STATE = #ONLY_WHEN_DOCKER_OPEN:gsub(' ','') > 0 and r.GetToggleCommandStateEx(0,40279) == 1 -- View: Show docker
or #ONLY_WHEN_DOCKER_OPEN:gsub(' ','') == 0

local sel_tr = r.GetSelectedTrack2(0,0, true) -- wantmaster true
local tr_name = sel_tr and {r.GetTrackName(sel_tr)} -- returns 2 values hence table
local item = r.GetSelectedMediaItem(0,0)
local act_take = item and r.GetActiveTake(item)
local curr_ctx = r.GetCursorContext()
local curr_ctx = change_focus and sel_tr ~= init_tr and r.SetCursorContext(0)
or change_focus and act_take ~= init_take and r.SetCursorContext(1) or curr_ctx

	if sel_tr and (sel_tr ~= init_tr or curr_ctx ~= init_ctx) and curr_ctx == 0 -- curr_ctx ~= init_ctx makes sure track and take fx chains can be switched even if object selection hasn't changed
	then
	local master, track -- specifically declared, otherwise empty fx chains get opened, because the vars become global and don't depend on the below condition any longer
		if main_ch and r.TrackFX_GetCount(sel_tr) > 0 then
		master, track = 40846, 40291 -- Track: View FX chain for master track /  Track: View FX chain for current/last touched track
		elseif r.TrackFX_GetRecCount(sel_tr) > 0 then
		master, track = 41882, 40844 -- View: Show monitoring FX chain / Track: View input FX chain for current/last touched track
		end
	local upd = master and tr_name[2] == 'MASTER' and r.Main_OnCommand(master,0) or track and r.Main_OnCommand(track,0)
	init_tr = sel_tr
	init_ctx = curr_ctx
	end
	if take_ch and act_take and act_take ~= init_take and r.TakeFX_GetCount(act_take) > 0 and curr_ctx == 1 -- curr_ctx ~= init_ctx condition isn't used so take FX chain doesn't compete with track FX chain completely preventing it from loading in tabbed dock layout
	then
	r.Main_OnCommand(40638,0) -- Item: Show FX chain for item take
	init_take = act_take
	init_ctx = curr_ctx
	end

	if r.CountSelectedMediaItems(0) == 0 then init_take = nil end -- reset, ensures that FX chain of the last selected item can be re-opened after the item was deselected and selected again
	--[needed when curr_ctx ~= init_ctx isn't used as a condition to switch to take fx chain since it's commented out in the track fx chain selection routine to prevent auto-switching to take fx chain in tabbed docker layout]
	if r.CountSelectedTracks(0) == 0 then init_tr = nil end -- reset, ensures that FX chain of the last selected track can be re-opened after the track was deselected and selected again

r.defer(UPDATE_FX_CHAIN)

end

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
-- Set toggle state and update toolbar button
r.SetToggleCommandState(sect_ID, cmd_ID, 1)
r.RefreshToolbar(cmd_ID)

UPDATE_FX_CHAIN()

-- Reset toggle state and update toolbar button
r.atexit(function() r.SetToggleCommandState(sect_ID, cmd_ID, 0); r.RefreshToolbar(cmd_ID) end)





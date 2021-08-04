--[[
ReaScript name: Toggle bypass;offline state of all FX in a focused;selected item;take + visual indication
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main] .
About:

	####GUIDE

	▓ ♦ Some background (can be skipped)

	— The track FX button has an option of bypassing the entire FX chain in which case
	the button changes its color to indicate the FX chain state. However not the take
	FX button.

	Natively bypass of all FX in a take FX chain can be toggled by manually selecting
	all FX in the chain and running Ctrl/Cmd + B or with SWS extension actions:
	SWS/S&M: Bypass all take FX for selected items  
	SWS/S&M: Unbypass all take FX for selected items  
	SWS/S&M: Toggle all take FX bypass for selected items

	Toggling all take FX off- and online can be performed with the native actions:  
	Items: Set all take FX offline for selected media items  
	Items: Set all take FX online for selected media items  
	or, again, with SWS extension actions:  
	SWS/S&M: Set all take FX offline for selected items  
	SWS/S&M: Set all take FX online for selected items  
	SWS/S&M: Toggle all take FX online/offline for selected items

	But none does both automatic and selective, on take level, toggling with visual
	feedback of the toggle state. So this script was meant to fill this gap.


	▓ ♦ THE NITTY GRITTY

	— To indicate that FX are bypassed or set offline a take marker with descriptive
	comment is being placed at the very beginning of the item/take.  
	Since the indicator marker is placed at the very beginning of the item/take it
	will end up being hidden if the item is trimmed from the start or being shifted
	further from the beginning if previously trimmed item was extended (not stretched)
	leftwards. After the state is toggled twice the marker will be re-added at the
	new item/take start.

	— The script can be called in the following ways:

	1)  by placing the mouse cursor over the item or its FX chain window and calling
	the script with a shortcut assigned to it;  
	2) by assigning it to Item mouse modifiers under *Preferences -> Mouse modifiers*
	and actually clicking the item to call it; 

	=► SELECTED

	If **SELECTED** option is enabled in the USER SETTINGS below script can be called:

	3) from a menu;
	4) from a toolbar;
	5) from the Action list (which is much less practicable)

	that is when there's no item under mouse cursor.

	All five methods can work in parallel.

	Be aware that mouse cursor takes precedence over selection therefore when **SELECTED** option
	is enabled and the script is run via a keyboard shortcut, if you wish to toggle FX on
	selected item(s) make sure there's no item under mouse cursor otherwise FX in the item/take
	currently under mouse cursor will be targeted.

	When take FX chain is open the script targets its FX even if the FX chain window is not
	in focus as long as there's no item under mouse cursor. In order to be able to shift
	the focus of the script from the open take FX chain window to selected items to target
	them when **SELECTED** option is ON, click anywhere within the Arrange canvas and use the
	technique described above. To return the focus to the open FX chain window, click it.

	=► ALL_TAKES

	When enabled while **SELECTED** option is active the state of FX in all takes of selected
	items is toggled. Otherwise it's only toggled in the active takes.

	=► OFF_ON_LINE

	By default the script toggles FX bypass. This option switches it to toggling FX offline
	and back online.

	=► HEX_COLOR

	Allows setting custom color for indicator take marker. If not set or malformed REAPER
	default take marker color is used.

	
Licence: WTFPL
REAPER: at least v6.09

]]
---------------------------------------------------------------------------------------------------------------
----------------------------------------------- USER SETTINGS -------------------------------------------------
---------------------------------------------------------------------------------------------------------------
-- To enable insert any alphanumeric character between the quotation marks.
-- Try to not leave empty spaces.

local SELECTED = ""			-- apply to selected item(s) / active take of selected item(s) if not under mouse cursor
local ALL_TAKES = ""		-- toggle FX state in all selected item takes; if disabled only active take is considered
local OFF_ON_LINE = ""		-- set off-/online instead of (un)bypassing
local HEX_COLOR = "#000"	-- in HEX format: number sign + 6 or 3 digits; if not set or malformed REAPER default color is used

---------------------------------------------------------------------------------------------------------------
------------------------------------------- END OF USER SETTINGS ----------------------------------------------
---------------------------------------------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end

local r = reaper


local function GET_TOGGLE_STATE(sel_item, ALL_TAKES)
-- to check if states of fx in multiple selected items are in sync

-- evaluation of the actual marker name against two of its possible variants is designed
-- to disallow toggling miltiple selected items when fx therein have different
-- kind of toggle state set, i.e. bypass vs offline
local name1 = ('FX  BYPASSED'):gsub('.', '%0 ')
local name2 = ('FX  OFFLINE'):gsub('.', '%0 ')

local off_state_bypass_cnt = 0 -- bypassed
local off_state_offline_cnt = 0 -- offline
local on_state_cnt = 0

local take_cnt = r.CountTakes(sel_item)
local fin = ALL_TAKES and take_cnt or 1  -- 1 is to account for -1 in the loop
local take_with_fx_cnt = 0

	for i = 0, fin-1 do
	local take = fin > 1 and r.GetTake(sel_item, i) or r.GetActiveTake(sel_item)
	local fx_cnt = r.TakeFX_GetCount(take)
		if fx_cnt > 0 then take_with_fx_cnt = take_with_fx_cnt + 1
		local marker
		local mrk_cnt = r.GetNumTakeMarkers(take)
			local i = 0
			repeat
			retval, mrk_name, color = r.GetTakeMarker(take, i)
				if retval > -1 and mrk_name == name1 then off_state_bypass_cnt = off_state_bypass_cnt + 1; marker = true; break -- 'bypass' state indicator marker
				elseif retval > -1 and mrk_name == name2 then off_state_offline_cnt = off_state_offline_cnt + 1; marker = true; break -- 'offline' state indicator marker
				end
			i = i + 1
			until i == mrk_cnt-1 -- if markers
			or i == mrk_cnt+1 -- if no markers
			if not marker then on_state_cnt = on_state_cnt + 1 end
		end
	end


return on_state_cnt, off_state_bypass_cnt, off_state_offline_cnt, take_with_fx_cnt

end


function no_undo() end


function hex2rgb(HEX_COLOR)
-- https://gist.github.com/jasonbradley/4357406
    local hex = HEX_COLOR:sub(2) -- strip out # sign
    return tonumber('0x'..hex:sub(1,2)), tonumber('0x'..hex:sub(3,4)), tonumber('0x'..hex:sub(5,6))
end


function timed_tooltip(tooltip, x, y, time)
-- sticks for the duration of time if the script is run from a floating toolbar button
-- so it's overrides button own tooltip which interferes

local _ = r.TrackCtl_SetToolTip

local lt, top, rt, bot = r.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true) -- screen dimensions; wantWorkArea is true

	if r.GetCursorContext() == -1 -- when a floating toolbar button is pressed
	or r.GetCursorContext() > -1 and (x <= 200 or rt - x <= 200 or y <= 200 or bot - y <= 200) -- when docked or Main toolbar button is pressed, affects also calling the script from menu and via a shortcut in other areas (Mixer/TCP bottom, ruler, focused toolbar/window); won't work if the program window is shrunk
	then
	_(tooltip, x, y+10, true) -- initial display; topmost true
	local t = os.clock()
		repeat -- freezes UI so the tooltip sticks
		until os.clock() - t > time -- greater > sign instead of == because the exact time stamp might not get caught due to speed and the floating point value
	--[[ OR
		while os.clock() - t <= time do -- alternative
		end
		]]
	else _(tooltip, x, y+10, true) -- topmost is true
	end

end


local x, y = r.GetMousePosition()

	if tonumber(r.GetAppVersion():match('(.+)/')) < 6.09 then
	r.TrackCtl_SetToolTip('\n     THE SCRIPT REQUIRES\n\n  REAPER v6.09 AND ABOVE  \n ', x, y+10, true) -- topmost true
	return end -- 'ReaScript:Run' caption is displayed in the menu bar but no actual undo point is created because Undo_BeginBlock() isn't yet initialized, here and elsewhere

local SELECTED = SELECTED:gsub(' ', '') ~= ''
local ALL_TAKES = ALL_TAKES:gsub(' ', '') ~= ''
local OFF_ON_LINE = OFF_ON_LINE:gsub(' ', '') ~= ''
local name = OFF_ON_LINE and 'FX  OFFLINE' or 'FX  BYPASSED' -- marker comment
local name = name:gsub('.', '%0 ') -- space out text
local HEX_COLOR = (not HEX_COLOR or type(HEX_COLOR) ~= 'string' or HEX_COLOR == '' or #HEX_COLOR < 4 or #HEX_COLOR > 7) and '0' or HEX_COLOR
local HEX_COLOR = #HEX_COLOR == 4 and HEX_COLOR:gsub('%w','%0%0') or HEX_COLOR -- expand to 7 characters (duplicate each digit) if 4 to use in the next function
local R,G,B = hex2rgb(HEX_COLOR) -- R because r is already taken by reaper, the rest is for consistency
local color = R and r.ColorToNative(R,G,B)|0x1000000 or 0 -- if no custom color, fall back on default set at 'Theme development: Show theme tweak/configuration window -> Media item take marker'

local item, take = r.GetItemFromPoint(x, y, true) -- allow locked is true, the function returns both item and take pointers

	if not take then retval, track, item, fx_idx = r.GetFocusedFX() -- if not under mouse, look for take FX chain
	take = retval == 2 and r.GetTake(r.GetTrackMediaItem(r.GetTrack(0,track-1), item), fx_idx>>16)
		if take and r.GetCursorContext() == 1 then take = nil end -- to shift focus from open FX chain to selected items when SELECTED option is ON
	end

---- WEED OUT ERROR STATES ----

	if take and r.TakeFX_GetCount(take) == 0 then
	local take_cnt = r.CountTakes(item)
	r.TrackCtl_SetToolTip('\n   NO FX IN THE FOCUSED '..(take_cnt > 1 and 'TAKE' or 'ITEM')..'.   \n ', x, y+10, true) -- topmost true
	return
	elseif not take and SELECTED then
		if r.CountSelectedMediaItems(0) == 0 then
		timed_tooltip('\n   NO SELECTED ITEMS.  \n ', x, y, 0.7) return
		else
		local itm_cnt = r.CountSelectedMediaItems(0)
		local fx_cnt = 0
			for i = 0, itm_cnt-1 do
			local item = r.GetSelectedMediaItem(0,i)
			local take_cnt = r.CountTakes(item)
			local fin = ALL_TAKES and take_cnt > 1 and take_cnt or 1 -- 1 is to account for -1 in the loop
				for i = 0, fin-1 do
				local take = fin > 1 and r.GetTake(item, i) or r.GetActiveTake(item)
				fx_cnt = fx_cnt + r.TakeFX_GetCount(take)
				end
			end
			if fx_cnt == 0 then
			local tooltip = ALL_TAKES and '\n       NO FX IN TAKES   \n\n    OF SELECTED ITEMS.   \n ' or '\n   NO FX IN THE ACTIVE TAKES   \n\n        OF SELECTED ITEMS.   \n '
			timed_tooltip(tooltip, x, y, 1.5)
			return end
		-- prevent mix of toggle states and types of toggle state in takes of and selected items which do have fx
		local ON_state_cnt, OFF_state_bypass_cnt, OFF_state_offline_cnt, TAKE_with_fx_cnt = 0, 0, 0, 0
			for i = 0, itm_cnt-1 do
			local item = r.GetSelectedMediaItem(0,i)
			local on_state_cnt, off_state_bypass_cnt, off_state_offline_cnt, take_with_fx_cnt = GET_TOGGLE_STATE(item, ALL_TAKES)
				if ALL_TAKES then -- discrepancies between takes of at least one selected item
					if on_state_cnt * off_state_bypass_cnt * off_state_offline_cnt ~= 0
					or on_state_cnt * off_state_bypass_cnt ~= 0 and on_state_cnt + off_state_bypass_cnt == take_with_fx_cnt
					or on_state_cnt * off_state_offline_cnt ~= 0 and on_state_cnt + off_state_offline_cnt == take_with_fx_cnt
					or off_state_bypass_cnt * off_state_offline_cnt ~= 0 and off_state_bypass_cnt * off_state_offline_cnt == take_with_fx_cnt
					then timed_tooltip('\n  THE STATES OF FX IN TAKES OF SELECTED ITEMS  \n\n    ARE NOT IN SYNC OR THEIR TYPES ARE MIXED. \n\n\t      ADJUST YOUR SELECTION. \n ', x, y, 3.3)
					return end
				end
			ON_state_cnt = ON_state_cnt + on_state_cnt
			OFF_state_bypass_cnt = OFF_state_bypass_cnt + off_state_bypass_cnt
			OFF_state_offline_cnt = OFF_state_offline_cnt + off_state_offline_cnt
			TAKE_with_fx_cnt = TAKE_with_fx_cnt + take_with_fx_cnt
			end
			if ALL_TAKES then -- discrepancies between several selected items
				if ON_state_cnt * OFF_state_bypass_cnt * OFF_state_offline_cnt ~= 0
				or ON_state_cnt * OFF_state_bypass_cnt ~= 0 and ON_state_cnt + OFF_state_bypass_cnt == TAKE_with_fx_cnt
				or ON_state_cnt * OFF_state_offline_cnt ~= 0 and ON_state_cnt + OFF_state_offline_cnt == TAKE_with_fx_cnt
				or OFF_state_bypass_cnt * OFF_state_offline_cnt ~= 0 and OFF_state_bypass_cnt + OFF_state_offline_cnt == TAKE_with_fx_cnt
				then timed_tooltip('\n          THE STATES OF FX IN SELECTED ITEMS  \n\n   ARE NOT IN SYNC OR THEIR TYPES ARE MIXED.  \n\n\t      ADJUST YOUR SELECTION. \n ', x, y, 3.3)
				return end
			end
		local tooltip = OFF_state_bypass_cnt * OFF_state_offline_cnt * ON_state_cnt ~= 0 and '\n    THE FX IN SELECTED ITEMS HAVE DIFFERENT TYPES   \n\n            OF TOGGLE STATE AND ARE NOT IN SYNC.\n\n\t          ADJUST YOUR SELECTION.\n ' or OFF_state_bypass_cnt * OFF_state_offline_cnt ~= 0 and OFF_state_bypass_cnt + OFF_state_offline_cnt == itm_cnt and '\n   THE FX IN SELECTED ITEMS HAVE DIFFERENT TYPES   \n\n       OF TOGGLE STATE. ADJUST YOUR SELECTION. \n ' or ((ON_state_cnt * OFF_state_bypass_cnt ~= 0 and ON_state_cnt + OFF_state_bypass_cnt == itm_cnt) or (ON_state_cnt * OFF_state_offline_cnt ~= 0 and ON_state_cnt + OFF_state_offline_cnt == itm_cnt)) and '\n        THE STATES OF FX IN SELECTED ITEMS  \n\n   ARE NOT IN SYNC. ADJUST YOUR SELECTION.  \n '
			if tooltip then	timed_tooltip(tooltip, x, y, 3.3) return end
		end -- media items count > 0 cond end
	elseif not take and not SELECTED then return end -- not SELECTED and no item under mouse cursor



local function TOGGLE(take, OFF_ON_LINE, fx_cnt, color, name)

local mrk_cnt = r.GetNumTakeMarkers(take)

-- evaluation of the actual marker name against two of its possible variants is designed
-- to allow toggling a different fx state of item/take fx which currently have another type of state changed
-- i.e. to set bypassed fx offline and vice versa when OFF_ON_LINE setting has changed

local name1 = ('FX  BYPASSED'):gsub('.', '%0 ')
local name2 = ('FX  OFFLINE'):gsub('.', '%0 ')

local i = 0
local marker
	repeat -- delete indicator markers if any
	retval, mrk_name, mrk_color = r.GetTakeMarker(take, i)
		if retval > -1 and (mrk_name == name1 or mrk_name == name2) then r.DeleteTakeMarker(take, i); marker = true; break end
	i = i + 1
	until i == mrk_cnt-1 -- if markers
	or i == mrk_cnt+1 -- if no markers

	if (not marker or marker and mrk_name ~= name) and fx_cnt > 0 then r.SetTakeMarker(take, -1, name, r.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS'), color) end -- add, srcposIn = GetMediaItemTakeInfo_Value(), optional number colorIn = 0 // add marker

local bool = (not marker or marker and mrk_name ~= name) and 0 or 1 -- value for TakeFX_SetEnabled(); no marker - bypass/offline, marker - unbypass/online

	for i = 0, r.TakeFX_GetCount(take)-1 do
		if marker and mrk_name == name1 and OFF_ON_LINE then r.TakeFX_SetEnabled(take, i, 1) -- unbypass before setting offline
		elseif marker and mrk_name == name2 and not OFF_ON_LINE then r.TakeFX_SetOffline(take, i, 0) -- set online before bypassing
		end
	-- in the following order; if used in sequence and TakeFX_SetEnabled() precedes TakeFX_SetOffline() fx aren't unbypassed, probably because on offline fx unbypass doesn't work
	local set = OFF_ON_LINE and r.TakeFX_SetOffline(take, i, bool~1) -- bitwise NOT to invert the boolean value
	r.TakeFX_SetEnabled(take, i, bool) -- 0 bypass, 1 unbypass
	end

return bool

end


----------- MAIN ROUTINE -----------

r.PreventUIRefresh(1)
r.Undo_BeginBlock()

	if take then
	retval = TOGGLE(take, OFF_ON_LINE, r.TakeFX_GetCount(take), color, name)
	undo = retval == -1 and OFF_ON_LINE and 'Set %s offline %s' or retval > -1 and OFF_ON_LINE and 'Set %s online %s' or retval == -1 and 'Bypass %s %s' or retval > -1 and 'Unbypass %s %s'
	undo = undo:format('FX', 'in take under mouse cursor')
	else
		for i = 0, r.CountSelectedMediaItems(0)-1 do
		local item = r.GetSelectedMediaItem(0,i)
		local take_cnt = r.CountTakes(item)
		local fin = ALL_TAKES and take_cnt > 1 and take_cnt or 1 -- 1 is to account for -1 in the loop
			for i = 0, fin-1 do
			local take = fin > 1 and r.GetTake(item, i) or r.GetActiveTake(item)
			bool = TOGGLE(take, OFF_ON_LINE, r.TakeFX_GetCount(take), color, name)
			end
		end
	undo = bool == 0 and OFF_ON_LINE and 'Set %s offline %s' or bool == 1 and OFF_ON_LINE and 'Set %s online %s' or bool == 0 and 'Bypass %s %s' or bool == 1 and 'Unbypass %s %s'
	undo = undo:format('FX', 'in '..(ALL_TAKES and 'all' or 'active')..' takes of selected items')
	end



r.Undo_EndBlock(undo, -1)
r.PreventUIRefresh(-1)





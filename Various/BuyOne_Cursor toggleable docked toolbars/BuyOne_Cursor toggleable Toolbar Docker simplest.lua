-- @noindex

--[[

* ReaScript Name: BuyOne_Cursor toggleable Toolbar Docker simplest.lua
* Description: Meant to free up screen real estate when toolbars are not in active use
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Demo: https://raw.githubusercontent.com/Buy-One/screenshots/main/Cursor%20toggleable%20Toolbar%20Docker%20simplest.gif
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M
* Changelog:
	+ v1.0 	Initial release

Originally idea by Reno.thestraws https://forum.cockos.com/showthread.php?t=219502

Instructions:
-- This script only toggles the Toolbar Docker. The set of the toolbars availabe in it and its position relative to the main window are to be determined by user at his/her discretion through the use of corresponding menus in Arrange.
-- 'open' and 'close' variables  in the Main() function hold cursor coordinates to govern sensitivity of the main window to mouse hover at 4 Toolbar Docker positions, the default values were optimal on my system, you can adapt them to yours as needed.
-- When terminating the script and getting 'ReaScript task control' dialogue you may tick 'Remember my answer for this script' checkbox and click 'Terminate instances'. Next time the script will be terminated without invoking the dialogue.
-- If you'd like the script to autostart upon REAPER/project load, add it to the SWS Extension 'Start actions'.

-- You may also check out the following scripts for alternative setups:
-- BuyOne_Cursor toggleable Toolbar Docker (settings inside).lua
-- BuyOne_Cursor toggleable Toolbar Docker simpler (settings inside).lua
-- BuyOne_Cursor toggleable sidebars (settings inside).lua
-- BuyOne_Cursor toggleable toolbar at top of main window.lua

]]

local r = reaper

local function TOGGLE(ID, status)
	local state = r.GetToggleCommandStateEx(0, ID) -- Toolbar: Show/hide toolbar docker
		if state ~= status then
		r.Main_OnCommand(ID, 0) end
end

local function get_ini_cont()
	local path = r.get_ini_file() -- get reaper.ini full path
	local f = io.open(path, 'r') -- load reaper.ini for parsing
	local f_cont = f:read('*a') -- read the entire content
	io.close(f)
	return f_cont
end

local f_cont = get_ini_cont()

-- Get Arrange window size from reaper.ini (wnd_w=1372	wnd_h=740)
-- thanks to Claudiohbsantos and Mespotine https://forums.cockos.com/showthread.php?t=203785
local wnd_w = f_cont:match('(wnd_w=%d*)'); local wnd_w = tonumber(wnd_w:match('=(%d*)'))
local wnd_h = f_cont:match('(wnd_h=%d*)'); local wnd_h = tonumber(wnd_h:match('=(%d*)'))


local function Main()

local dockerpos = get_ini_cont():match('dockermode15=(%d*)')

	local x,y = r.GetMousePosition()
		if dockerpos == '65537' or dockerpos == '1' then open = 10; close = 120 -- left
			if x >= 0 and x < open then status = 1
			TOGGLE(41084, status) -- Toolbar: Show/hide toolbar docker
			elseif x > close then status = 0
			TOGGLE(41084, status)
			end
		elseif dockerpos == '65539' or dockerpos == '3' then open = 20; close = 120 -- right
			if x < wnd_w and x > wnd_w - open then status = 1
			TOGGLE(41084, status)
			elseif x < wnd_w - close then status = 0
			TOGGLE(41084, status)
			end
		elseif dockerpos == '65538' or dockerpos == '2' then open = 80; close = 150 -- top
			if y >= 0 and y < open then status = 1
			TOGGLE(41084, status)
			elseif y > close then status = 0
			TOGGLE(41084, status)
			end
		elseif dockerpos == '65536' or dockerpos == '0' then open = 20; close = 120 -- bottom
			if y < wnd_h and y > wnd_h - open then status = 1
			TOGGLE(41084, status)
			elseif y < wnd_h - close then status = 0
			TOGGLE(41084, status)
			end
		end
	r.defer(Main)
end

Main()


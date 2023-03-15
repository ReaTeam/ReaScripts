-- @noindex

--[[

* ReaScript Name: BuyOne_Cursor toggleable toolbar at top of main window.lua
* Description: Meant to free up screen real estate when the toolbar is not in active use
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Demo: https://raw.githubusercontent.com/Buy-One/screenshots/main/Cursor%20toggleable%20toolbar%20at%20top%20of%20main%20window.gif
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M
* Changelog:
	+ v1.0 	Initial release

Originally idea by Reno.thestraws https://forum.cockos.com/showthread.php?t=219502

Instructions:
-- This script toggles whatever toolbar which is pinned to the Top docker with 'At top of main window' option of  'Position toolbar' right click context menu. This docker comes in addition to the regular top docker and the dedicated Toolbar Docker. Therefore running this script with any of the 3 versions of 'BuyOne_Cursor toggleable Toolbar Docker' script in which the Toolbar Docker is attached to the main window at the top allows having a kind of two storey cursor toggleable toolbar provided the toolbar sitting at the top of the main window isn't pinned to the Toolbar Docker as well.
-- When terminating the script and getting 'ReaScript task control' dialogue you may tick 'Remember my answer for this script' checkbox and click 'Terminate instances'. Next time the script will be terminated without invoking the dialogue.
-- If you'd like the script to autostart upon REAPER/project load, add it to the SWS Extension 'Start actions'.

You may also check out the following scripts for alternative setups:
-- BuyOne_Cursor toggleable sidebars (settings inside).lua
-- BuyOne_Cursor toggleable Toolbar Docker (settings inside).lua
-- BuyOne_Cursor toggleable Toolbar Docker simpler (settings inside).lua
-- BuyOne_Cursor toggleable Toolbar Docker simplest.lua

]]

local r = reaper

local function TOGGLE(status)
	local state = r.GetToggleCommandStateEx(0, 41297) -- Toolbar: Show/hide toolbar at top of main window
		if state ~= status then
		r.Main_OnCommand(41297, 0) end
end

local function Main()
	local x,y = r.GetMousePosition()
			if y >= 0 and y < 150 then status = 1 -- you may change the value 150 as needed to better suit your screen properties
			TOGGLE(status)
			elseif y > 150 then status = 0
			TOGGLE(status)
			end
	r.defer(Main)
end

Main()



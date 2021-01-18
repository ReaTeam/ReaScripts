-- @noindex

--[[

* ReaScript Name: BuyOne_Cursor toggleable sidebars (settings inside).lua
* Description: Meant to free up screen real estate when toolbars are not in active use
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Demo: https://raw.githubusercontent.com/Buy-One/screenshots/main/Cursor%20toggleable%20Toolbar%20Docker.gif
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M
* Changelog:
	+ v1.0 	Initial release

Originally idea by Reno.thestraws https://forum.cockos.com/showthread.php?t=219502

]]

---------------- USER SETTINGS SECTION -----------------

-- To attach Toolbar Docker to main window in one of the 4 positions insert any alphanumeric character between the quotes next to position variables: Lt, Top, Rt, Bot. If all are empty the Toolbar Docker will float and open when mouse cursor hovers over the spot where it floats, which is probably not what you'd want.
-- '_open' and '_close' variables hold cursor coordinates to govern sensitivity of the main window to mouse hover at 4 Toolbar Docker positions, the default values were optimal on my system, you can adapt them to yours as needed.
-- When terminating the script and getting 'ReaScript task control' dialogue you may tick 'Remember my answer for this script' checkbox and click 'Terminate instances'. Next time the script will be terminated without invoking the dialogue.
-- Running this script with Top docker positon enabled in parallel with BuyOne_Cursor toggleable toolbar at top of main window.lua allows having a kind of two storey cursor toggleable toolbar at the Top provided the toolbar sitting at top of the main window isn't featured in the Toolbar Docker.
-- You may also check out the following scripts for alternative setups:
-- BuyOne_Cursor toggleable Toolbar Docker (settings inside).lua
-- BuyOne_Cursor toggleable Toolbar Docker simplest.lua
-- BuyOne_Cursor toggleable sidebars (settings inside).lua
-- BuyOne_Cursor toggleable toolbar at top of main window.lua

-- position
local Lt = "" -- any alphanumeric character
-- cursor coordinates
local Lt_open = "10" -- in pixels, the greater the number the more sensitive
local Lt_close = "120"-- in pixels, the smaller the number the more sensitive

-- position
local Top = "1"
-- cursor coordinates
local Top_open = "80"
local Top_close = "150"

-- position
local Rt = ""
-- cursor coordinates
local Rt_open = "20"
local Rt_close = "120"

-- position
local Bot = ""
-- cursor coordinates
local Bot_open = "20"
local Bot_close = "120"

------------- END OF USER SETTINGS SECTION ------------

local r = reaper

-- SWS Extension check
if not r.APIExists('BR_Win32_GetPrivateProfileString') then reaper.ClearConsole()
r.ShowConsoleMsg('Get the SWS/S&M extension at\nhttps://www.sws-extension.org/')
r.MB('This script requires the SWS/S&M extension.\n\n If it\'s installed then it needs to be updated.','API CHECK', 0)
return end

local pos_t = {Lt,Top,Rt,Bot}

-- Generate error messages
local counter = 0
	for _,v in next, pos_t do
		if v ~= '' then counter = counter + 1 end
	end
	if counter == 0 then r.MB('No Docker position has been set.','ERROR',0) return end
	if counter > 1 then r.MB('More than one Docker position have been set.','ERROR',0) return end

	for k,v in next, pos_t do
		if v ~= '' then
			if k == 1 then inset = Lt_open ~= '' and Lt_close ~= '' or 'Left'
			elseif k == 2 then inset = Top_open ~= '' and Top_close ~= '' or 'Top'
			elseif k == 3 then inset = Rt_open ~= '' and Rt_close ~= '' or 'Right'
			elseif k == 4 then inset = Bot_open ~= '' and Bot_close ~= '' or 'Bottom' 
			end
		end
	end
	if type(inset) == 'string' then r.MB('             '..inset..' Docker position\n\ncursor coordinates are incomplete.', 'ERROR',0) return end
	

local path = r.get_ini_file() -- get reaper.ini full path
local f = io.open(path, 'r') -- load reaper.ini for parsing
local f_cont = f:read('*a') -- read the entire content
io.close(f)

local dockerpos = f_cont:match('dockermode15=(%d*)')
local config_on = Lt ~= '' and dockerpos == '65537' or (Top ~= '' and dockerpos == '65538' or (Rt ~= '' and dockerpos == '65539' or (Bot ~= '' and dockerpos == '65536')))
	
local dockerpos = Lt ~= '' and '65537' or (Top ~= '' and '65538' or (Rt ~= '' and '65539' or (Bot ~= '' and '65536')))
r.BR_Win32_WritePrivateProfileString('REAPER', 'dockermode15', dockerpos, path)

	-- Prompt to re-launch to re-activate the Settings
	if not config_on then resp = r.MB('   Since the last run of the script settings have changed.\n\nThe script must be re-initialized and won\'t work otherwise.\n\n    REAPER will now quit and will have to be re-launched.\n\n     After restart run the script again unless it\'s included\n\n\tin the SWS extension Startup actions.\n\n          YOU MAY WANT TO SAVE PROJECT FIRST.','PROMPT',1)
		if resp == 1 then r.Main_OnCommand(40004, 0) -- File: Quit REAPER
		else return end
	end

local function TOGGLE(ID, status)
	local state = r.GetToggleCommandStateEx(0, ID) -- Toolbar: Show/hide toolbar docker
		if state ~= status then
		r.Main_OnCommand(ID, 0) end
end

-- Get Arrange window size from reaper.ini
-- thanks to Claudiohbsantos and Mespotine https://forums.cockos.com/showthread.php?t=203785
local wnd_w = f_cont:match('(wnd_w=%d*)'); local wnd_w = tonumber(wnd_w:match('=(%d*)'))
local wnd_h = f_cont:match('(wnd_h=%d*)'); local wnd_h = tonumber(wnd_h:match('=(%d*)'))


-- Convert user string variables to integers
	if Lt ~= '' then open = tonumber(Lt_open); close = tonumber(Lt_close)
	elseif Top ~= '' then open = tonumber(Top_open); close = tonumber(Top_close)
	elseif Rt ~= '' then open = tonumber(Rt_open); close = tonumber(Rt_close)
	elseif Bot ~= '' then open = tonumber(Bot_open); close = tonumber(Bot_close) end


local function Main()
	local x,y = r.GetMousePosition()
		if Lt ~= '' then
			if x >= 0 and x < open then status = 1
			TOGGLE(41084, status) -- Toolbar: Show/hide toolbar docker
			elseif x > close then status = 0
			TOGGLE(41084, status)
			end
		elseif Rt ~= '' then
			if x < wnd_w and x > wnd_w - open then status = 1
			TOGGLE(41084, status)
			elseif x < wnd_w - close then status = 0
			TOGGLE(41084, status)
			end
		elseif Top ~= '' then
			if y >= 0 and y < open then status = 1
			TOGGLE(41084, status)
			elseif y > close then status = 0
			TOGGLE(41084, status)
			end
		elseif Bot ~= '' then
			if y < wnd_h and y > wnd_h - open then status = 1
			TOGGLE(41084, status)
			elseif y < wnd_h - close then status = 0
			TOGGLE(41084, status)
			end
		end
	r.defer(Main)
end

Main()



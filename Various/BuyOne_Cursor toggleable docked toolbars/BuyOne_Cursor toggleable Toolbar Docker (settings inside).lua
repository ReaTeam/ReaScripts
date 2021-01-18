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

-- Insert between the quotes the number of the Toolbar to be used, e.g. "1", there're 16 in total.
-- To use MIDI Toolbars (in Arrange view) append 'm' to the toolbar number, e.g. "1m", there're 8 in total.
-- MIDI toolbars can be used in Arrange when MIDI Editor it open.
-- To attach Toolbar Docker to the main window in one of the 4 positions insert any alphanumeric character between the quotes next to position variables: Lt, Top, Rt, Bot. If all are empty the Toolbar Docker will float and open when mouse cursor hovers over the spot where it floats, which is probably not what you'd want.
-- '_open' and '_close' variables hold cursor coordinates to govern sensitivity of the main window to mouse hover at 4 Toolbar Docker positions, the default values were optimal on my system, you can adapt them to yours as needed.
-- The order in which toolbars are positioned in the docker is a tricky thing to manage via a script. So you may need to reorder them manually by dragging, prefereably without accidentally detaching them from the docker because it may necessiate a restart.
-- When terminating the script and getting 'ReaScript task control' dialogue you may tick 'Remember my answer for this script' checkbox and click 'Terminate instances'. Next time the script will be terminated without invoking the dialogue.
-- With this script the set of toolbars available in the docker is fixed being determined by the user settings and is restored at every script restart.
-- If you prefer populating the docker with toolbars as needed without having the script dictate the set of toolbars available in the docker, then use scripts 
-- BuyOne_Cursor toggleable Toolbar Docker simpler (settings inside).lua OR 
-- BuyOne_Cursor toggleable Toolbar Docker simplest.lua
-- Running this script with Top docker positon enabled in parallel with BuyOne_Cursor toggleable toolbar at top of main window.lua allows having a kind of two storey cursor toggleable toolbar at the Top provided the toolbar sitting at the top of the main window isn't featured in the settings in this script.
-- If you'd like the script to autostart upon REAPER/project load, add it to the SWS Extension 'Start actions'.
-- You may also check out the following scripts for alternative setups:
-- BuyOne_Cursor toggleable sidebars (settings inside).lua
-- BuyOne_Cursor toggleable toolbar at top of main window.lua

local Tb_1 = "" -- 1 through 16 and 1m through 8m
local Tb_2 = ""
local Tb_3 = ""
local Tb_4 = ""
local Tb_5 = ""
local Tb_6 = ""
local Tb_7 = ""
local Tb_8 = ""
local Tb_9 = ""
local Tb_10 = ""
local Tb_11 = ""
local Tb_12 = ""
local Tb_13 = ""
local Tb_14 = ""
local Tb_15 = ""
local Tb_16 = ""
local Tb_17 = ""
local Tb_18 = ""
local Tb_19 = ""
local Tb_20 = ""
local Tb_21 = ""
local Tb_22 = ""
local Tb_23 = ""
local Tb_24 = ""

-- position
local Lt = "1" -- any alphanumeric character
-- cursor coordinates
local Lt_open = "10" -- in pixels, the greater the number the more sensitive
local Lt_close = "120"-- in pixels, the smaller the number the more sensitive

-- position
local Top = ""
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


-- open/close toolbar action command IDs table
local act_t = {41679,41680,41681,41682,41683,41684,41685,41686,41936,41937,41938,41939,41940,41941,41942,41943,
				42651, -- Main toolbar (unused, can't be toggled by action, toggle state is registered in wnd_vis= in reaper.ini)
				-- MIDI toolbars:
				41676, -- MIDI piano roll toolbar (unused, not clear how it's supposed to work in Arrange)
				41687,41688,41689,41690,41944,41945,41946,41947}


local toolbar_t = {Tb_1,Tb_2,Tb_3,Tb_4,Tb_5,Tb_6,Tb_7,Tb_8,Tb_9,Tb_10,Tb_11,Tb_12,Tb_13,Tb_14,Tb_15,Tb_16,Tb_17,Tb_18,Tb_19,Tb_20,Tb_21,Tb_22,Tb_23,Tb_24}

local pos_t = {Lt,Top,Rt,Bot}

-- Generate error messages
local counter = 0
	for _,v in next, pos_t do
		if v ~= '' then counter = counter + 1 end
	end
	if counter == 0 then r.MB('No Docker position has been set.','ERROR',0) return end
	if counter > 1 then r.MB('More than one Docker position have been set.','ERROR',0) return end

local err_t = {}
local counter = 0

	for _,v in next, toolbar_t do
		if (v:match('^%d+') and tonumber(v) and tonumber(v) > 16) or (not v:match('^%d+') and v:match('.*') ~= '')
		then err_t[#err_t+1] = v:match('.*')
		elseif (v:match('^%d*m') and tonumber(v:match('^%d*')) and tonumber(v:match('^%d*')) > 8) or (not v:match('^%dm') and not v:match('^%d*$') and v:match('.*') ~= '')
		then err_t[#err_t+1] = 'midi '..v:match('.*')
		end
	if v == '' then counter = counter + 1 end
	end
	local err_mess = counter == 24 and 'No toolbars have been set.' or (#err_t > 0 and '        Incorrect toolbar number(s):\n\n    '..table.concat(err_t,', ')..'\n\n   There\'re only 16 regular toolbars\n\n         and only 8 MIDI toolbars.')
	if err_mess then r.MB(err_mess,'ERROR',0) return end


local function Counter(v1,err_t) -- counts toolbar ids repeats for error message
	local cnt = 0
		for _,v3 in next, err_t do
			if v3 == v1 then cnt = cnt + 1 end
		end
	return cnt
end

	for k1,v1 in next, toolbar_t do
		for k2,v2 in next, toolbar_t do
			if k1~=k2 and v1 ~= '' and v1==v2 then -- to avoid comparing v to itself and comparing empty strings
				if Counter(v1,err_t)== 0 then err_t[#err_t+1] = v1 end -- only add if the id is unique
			end
		end
	end
	if #err_t > 0 then r.MB('Toolbars used more than once:\n\n'..table.concat(err_t2,', '), 'ERROR',0)
	return end

	for k,v in next, pos_t do
		if k == 1 and v ~= '' then inset = Lt_open ~= '' and Lt_close ~= '' or 'Left'
		elseif k == 2 and v ~= '' then inset = Top_open ~= '' and Top_close ~= '' or 'Top'
		elseif k == 3 and v ~= '' then inset = Rt_open ~= '' and Rt_close ~= '' or 'Right'
		elseif k == 4 and v ~= '' then inset = Bot_open ~= '' and Bot_close ~= '' or 'Bottom'
		end
	end
	if type(inset) == 'string' then r.MB('             '..inset..' Docker position\n\ncursor coordinates are incomplete.', 'ERROR',0) return end


-- Convert Toolbar string values to integers

-- 1. convert user MIDI toolbar values to key numbers of the act_t table to trigger actions in the Main() function
	for k,v in next, toolbar_t do
		if v:match('^%dm') then v = v:match('%d')
			if v == '1' then v = 19
		--	elseif v == '0' then v = 18 -- MIDI piano roll toolbar (unused, incompatible with the script design)
			elseif v == '2' then v = 20
			elseif v == '3' then v = 21
			elseif v == '4' then v = 22
			elseif v == '5' then v = 23
			elseif v == '6' then v = 24
			elseif v == '7' then v = 25
			elseif v == '8' then v = 26
			end
	--	elseif v:match('^%d+') == '0' then v = 17 -- Main toolbar (unused, incompatible with the script design)
		elseif v ~= '' then v = tonumber(v) -- to avoid conversion of empty strings to nil which will break the table for table.unpack() at step 2.
		end
		toolbar_t[k] = v
	end

-- 2. reassign values to user variables
local Tb_1,Tb_2,Tb_3,Tb_4,Tb_5,Tb_6,Tb_7,Tb_8,Tb_9,Tb_10,Tb_11,Tb_12,Tb_13,Tb_14,Tb_15,Tb_16,Tb_17,Tb_18,Tb_19,Tb_20,
Tb_21,Tb_22,Tb_23,Tb_24 = table.unpack(toolbar_t)

-- 3. convert all possible empty strings inherited from step 1 to nils
Tb_1 = tonumber(Tb_1); Tb_2 = tonumber(Tb_2); Tb_3 = tonumber(Tb_3); Tb_4 = tonumber(Tb_4); Tb_5 = tonumber(Tb_5); Tb_6 = tonumber(Tb_6); Tb_7 = tonumber(Tb_7); Tb_8 = tonumber(Tb_8); Tb_9 = tonumber(Tb_9); Tb_10 = tonumber(Tb_10)
Tb_11 = tonumber(Tb_11); Tb_12 = tonumber(Tb_12); Tb_13 = tonumber(Tb_13); Tb_14 = tonumber(Tb_14); Tb_15 = tonumber(Tb_15); Tb_16 = tonumber(Tb_16); Tb_17 = tonumber(Tb_17); Tb_18 = tonumber(Tb_18); Tb_19 = tonumber(Tb_19); Tb_20 = tonumber(Tb_20); Tb_21 = tonumber(Tb_21); Tb_22 = tonumber(Tb_22); Tb_23 = tonumber(Tb_23); Tb_24 = tonumber(Tb_24)

-- all 3 steps above could have been done with just table.pack() and table.unpack(), retaining nils as values after unpacking, if only i understood how table.pack() works


local function Conv_tlbr_nums(v) -- convert from the numbering system used by REAPER to that employed in this script and implied in the act_t table
	if v == '1' then v = 1
	elseif v == '2' then v = 2
	elseif v == '3' then v = 3
	elseif v == '4' then v = 4
	elseif v == '5' then v = 5
	elseif v == '6' then v = 6
	elseif v == '7' then v = 7
	elseif v == '8' then v = 8
	elseif v == '17' then v = 9
	elseif v == '18' then v = 10
	elseif v == '19' then v = 11
	elseif v == '20' then v = 12
	elseif v == '21' then v = 13
	elseif v == '22' then v = 14
	elseif v == '23' then v = 15
	elseif v == '24' then v = 16
--	elseif v == '13' then v = 17 -- Main toolbar (unused, incompatible with the script design)
--	elseif v == '14' then v = 18 -- MIDI piano roll toolbar (unused, incompatible with the script design)
	elseif v == '9' then v = 19 -- MIDI 1
	elseif v == '10' then v = 20 -- MIDI 2
	elseif v == '11' then v = 21 -- MIDI 3
	elseif v == '12' then v = 22 -- MIDI 4
	elseif v == '25' then v = 23 -- MIDI 5
	elseif v == '26' then v = 24 -- MIDI 6
	elseif v == '27' then v = 25 -- MIDI 7
	elseif v == '28' then v = 26 -- MIDI 8
	end

	return v
end


local function Conv_tlbr_vals(v) -- convert from the numbering system employed in the script and implied in the act_t table to the system used by REAPER in reaper.ini (for use with toolbar_t)
	if v == 1 then v = '1'
	elseif v == 2 then v = '2'
	elseif v == 3 then v = '3'
	elseif v == 4 then v = '4'
	elseif v == 5 then v = '5'
	elseif v == 6 then v = '6'
	elseif v == 7 then v = '7'
	elseif v == 8 then v = '8'
	elseif v == 9 then v = '17'
	elseif v == 10 then v = '18'
	elseif v == 11 then v = '19'
	elseif v == 12 then v = '20'
	elseif v == 13 then v = '21'
	elseif v == 14 then v = '22'
	elseif v == 15 then v = '23'
	elseif v == 16 then v = '24'
--	elseif v == 17 then v = '13' -- Main toolbar (unused, incompatible with the script design)
--	elseif v == 18 then v = '14' -- MIDI piano roll toolbar (unused, incompatible with the script design)
	elseif v == 19 then v = '9' -- MIDI 1
	elseif v == 20 then v = '10' -- MIDI 2
	elseif v == 21 then v = '11' -- MIDI 3
	elseif v == 22 then v = '12' -- MIDI 4
	elseif v == 23 then v = '25' -- MIDI 5
	elseif v == 24 then v = '26' -- MIDI 6
	elseif v == 25 then v = '27' -- MIDI 7
	elseif v == 26 then v = '28' -- MIDI 8
	end

	return v
end


local path = r.get_ini_file() -- get reaper.ini full path
local f = io.open(path, 'r') -- load reaper.ini for parsing
local f_cont = f:read('*a') -- read the entire content
io.close(f)

-- Remove renumbering values from reaper.ini added when Main toolbar is opened separately or MIDI piano roll toolbar is opened in Arrange hijacking other toolbar values, rendeing them inaccessible via code, renumbering other toolbars and messing up the user settings
local renum = false
	for line in io.lines(path) do
	local tb_num = line:match('^toolbar:(%d+)=%d+$')
	if tb_num then renum = true
	r.BR_Win32_WritePrivateProfileString('REAPER', 'toolbar:'..tb_num, '', path) end
	end


-- Close toolbars attached to Toolbar Docker which are unused in this script
local leftovers_cnt = 0 -- evaluated below in the re-launch message routine
	for line in io.lines(path) do
	local targ_tb = line:match('^toolbar:%d*=[%-%d%.]*%s15') -- find if a toolbar is assigned Toolbar Docker dockermode (15)
		if targ_tb then
		local targ_tb_num = targ_tb:match('^toolbar:(%d*)=') -- get its number
		local val = Conv_tlbr_nums(targ_tb_num) -- convert to the numbering system used in this script for the sake of comparison with the settings
		-- find out if its number matches toolbar numbers used in this script
			for _,tb in next, toolbar_t do
				exists = val == tb
				if exists then break end
			end
			if not exists then leftovers_cnt = leftovers_cnt + 1
			r.BR_Win32_WritePrivateProfileString('toolbar:'..targ_tb_num, 'wnd_vis', '0', path) -- hide
			r.BR_Win32_WritePrivateProfileString('toolbar:'..targ_tb_num, 'dock', '0', path) -- undock
			r.BR_Win32_WritePrivateProfileString('REAPERdockpref', 'toolbar:'..targ_tb_num, '0.50000000 16', path) -- completely exclude the removed toolbars from configuration, otherwise they keep popping up in the docker
			end
		end
	end


-- Evaluate defaults to re-launch if necessary

local defaults_on = true
	for i = 1, #toolbar_t do
	local v = toolbar_t[i] -- for brevity
		if v ~= '' then v = Conv_tlbr_vals(v) -- convert to the numbering system used by REAPER
		-- Evaluate if defaults are intact in reaper.ini to condition 'Quit Reaper' action below, single discrepancy is enough
		local _, dock = r.BR_Win32_GetPrivateProfileString('toolbar:'..v, 'dock', '', path)
		local _, wnd_vis = r.BR_Win32_GetPrivateProfileString('toolbar:'..v, 'wnd_vis', '', path)
		local _, dockermode = r.BR_Win32_GetPrivateProfileString('REAPERdockpref', 'toolbar:'..v, '', path)
		local dockermode = dockermode:match('[%-%d%.]*%s(%d*)')
			if dockermode then
			_, dockerpos = r.BR_Win32_GetPrivateProfileString('REAPER', 'dockermode'..dockermode, '', path)
			-- OR
			-- dockerpos = reaper.DockGetPosition(tonumber(dockermode))
			end
			if Lt ~= '' then defaults_on = dock == '1' and wnd_vis == '1' and dockermode == '15' and (dockerpos == '1' or dockerpos == '65537') -- = hidden
			elseif Top ~= '' then defaults_on = dock == '1' and wnd_vis == '1' and dockermode == '15' and (dockerpos == '2' or dockerpos == '65538') -- = hidden
			elseif Rt ~= '' then defaults_on = dock == '1' and wnd_vis == '1' and dockermode == '15' and (dockerpos == '3' or dockerpos == '65539') -- = hidden
			elseif Bot ~= '' then defaults_on = dock == '1' and wnd_vis == '1' and dockermode == '15' and (dockerpos == '0' or dockerpos == '65536') -- = hidden
			end
		end
			if not defaults_on then break end -- to call prompt for re-launch
	end

	-- Prompt to re-launch to re-activate the Settings
	if renum or leftovers_cnt > 0 or not defaults_on then resp = r.MB('   Since the last run of the script settings have changed.\n\nThe script must be re-initialized and won\'t work otherwise.\n\n    REAPER will now quit and will have to be re-launched.\n\n     After restart run the script again unless it\'s included\n\n\tin the SWS extension Startup actions.\n\n          YOU MAY WANT TO SAVE PROJECT FIRST.','PROMPT',1)
		if resp == 1 then r.Main_OnCommand(40004, 0) -- File: Quit REAPER
		else return end
	end


-- Set values in reaper.ini

	for i = 1, #toolbar_t do
	local v = toolbar_t[i] -- for brevity
		if v ~= '' then v = Conv_tlbr_vals(v) -- if not an empty string which has been retained in the table after conversion at step 1 above
		r.BR_Win32_WritePrivateProfileString('toolbar:'..v, 'dock', '1', path) -- enable docking of the given toolbar
		r.BR_Win32_WritePrivateProfileString('toolbar:'..v, 'wnd_vis', '1', path) -- enable visibility of the given toolbar
		-- set the 'dockermode' number the toolbar will be assigned to, zero based
		r.BR_Win32_WritePrivateProfileString('REAPERdockpref', 'toolbar:'..v, '0.50000000 15', path)
			-- assign docker position to dockermode per Toolbar Docker position predefined in the toolbar_t table (table starts from left, REAPER counts from bottom), set to hidden to avoid display upon REAPER's launch
			if Lt ~= '' then dockerpos = '65537' -- left hidden
			elseif Top ~= '' then dockerpos = '65538' -- top
			elseif Rt ~= '' then dockerpos = '65539' -- right hidden
			elseif Bot ~= '' then dockerpos = '65536' -- bottom hidden
			end
			r.BR_Win32_WritePrivateProfileString('REAPER', 'dockermode15', dockerpos, path)
		end
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

	if defaults_on then -- only run if settings are correct
	Main() end



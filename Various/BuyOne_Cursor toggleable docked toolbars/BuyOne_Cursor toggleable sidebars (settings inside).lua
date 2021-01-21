-- @noindex

--[[

* ReaScript Name: BuyOne_Cursor toggleable sidebars (settings inside).lua
* Description: Meant to free up screen real estate when toolbars are not in active use
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Demo: https://raw.githubusercontent.com/Buy-One/screenshots/main/Cursor%20toggleable%20sidebars.gif
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M
* Changelog:
	+ v1.0 	Initial release

Originally idea by Reno.thestraws https://forum.cockos.com/showthread.php?t=219502

]]

---------------- USER SETTINGS SECTION -----------------

-- Insert between the quotes the number of the Toolbar to be used, e.g. "1", there're 16 in total.
-- To use MIDI Toolbars append 'm' to the toolbar number, e.g. "1m", there're 8 in total.
-- MIDI toolbars can be used in Arrange when MIDI Editor is open.
-- Not all placeholders should be filled unless you want to use all 4 sidebars and 2 toolbars per each one.
-- By default if 2 toolbars are enabled per sidebar they sit in a split docker.
-- If you wish to have them tabbed instead, insert any alphanumeric character between the quotes next to the variables: Lt_tabbed, Top_tabbed, Rt_tabbed, Bot_tabbed.
-- The default (split docker) layout is preferable because in a tabbed layout you may find active state reverting to the 1st tab (the bottommost in vertical dockers and the leftmost in horizontal ones) when mouse cursor swipes over the program main window edge thus re-intializing the toolbars opening. This behavior may be mitigated by reduction of '_open' sensitivity (see below) or by shrinking a tiny bit the main window on the side of the affected toolbar.
-- '_open' and '_close' variables hold cursor coordinates to govern sensitivity of the main window to mouse hover at 4 docker positions, the default values were optimal on my system, you can adapt them to yours as needed.
-- When a toolbar is removed from the settings it will be undocked and hidden unless it was the only toolbar in the docker in which case it's only hidden.
-- When terminating the script and getting 'ReaScript task control' dialogue you may tick 'Remember my answer for this script' checkbox and click 'Terminate instances'. Next time the script will be terminated without invoking the dialogue.
-- If you'd like the script to autostart upon REAPER/project load, add it to the SWS Extension 'Start actions'.

-- LIMITATIONS:
-- I. In tabbed layout tab selection isn't saved, active state defaults to the 1st tab when re-opened.
-- II. If the main window is shrunk significantly, toolbars sitting on the side which doesn't reach the full extent of the screen cannot be conveniently opened since the cursor coordinates are relative to full screen dimensions.
-- III. It's not recommended to open MIDI piano roll toolbar in Arrage since it may break the toolbar layout. If it's opened nonetheless, on the next script launch a user will be presented with a prompt to restart.

-- You may also check out the following scripts for alternative setups:
-- BuyOne_Cursor toggleable Toolbar Docker (settings inside).lua
-- BuyOne_Cursor toggleable Toolbar Docker simpler (settings inside).lua
-- BuyOne_Cursor toggleable Toolbar Docker simplest.lua
-- BuyOne_Cursor toggleable toolbar at top of main window.lua

----- LEFT ----------
local Lt_1 = "" -- 1 through 16 and 1m through 8m
local Lt_2 = ""
local Lt_tabbed = "" -- any alphanumeric character, to display toolbars in the docker in tabbed layout rather than split
-- cursor coordinates
local Lt_open = "10" -- in pixels, the greater the number the more sensitive
local Lt_close = "120" -- in pixels, the smaller the number the more sensitive

------ TOP ----------
local Top_1 = ""
local Top_2 = ""
local Top_tabbed = ""
-- cursor coordinates
local Top_open = "80"
local Top_close = "130"

----- RIGHT ---------
local Rt_1 = ""
local Rt_2 = ""
local Rt_tabbed = ""
-- cursor coordinates
local Rt_open = "20"
local Rt_close = "120"

---- BOTTOM ---------
local Bot_1 = ""
local Bot_2 = ""
local Bot_tabbed = ""
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
				42651, -- Main toolbar (unused)
				-- MIDI toolbars:
				41676, -- MIDI piano roll toolbar (unused)
				41687,41688,41689,41690,41944,41945,41946,41947}

local toolbar_t = {Lt_1,Lt_2,Top_1,Top_2,Rt_1,Rt_2,Bot_1,Bot_2}

-- Generate error messages
local err_t1 = {}
local counter = 0
	for _,v in next, toolbar_t do
		if (v:match('^%d+') and tonumber(v) and tonumber(v) > 16) or (not v:match('^%d+') and v:match('.*') ~= '')
		then err_t1[#err_t1+1] = v:match('.*')
		elseif (v:match('^%d*m') and tonumber(v:match('^%d*')) and tonumber(v:match('^%d*')) > 8) or (not v:match('^%dm') and not v:match('^%d*$') and v:match('.*') ~= '')
		then err_t1[#err_t1+1] = 'midi '..v:match('.*')
		end
	if v == '' then counter = counter + 1 end
	end
	local err_mess = counter == 8 and ' No toolbars have been set. To configure open the file\n\n'..select(2,reaper.get_action_context()):match('[^\\/]+%.lua') or (#err_t1 > 0 and '        Incorrect toolbar number(s):\n\n    '..table.concat(err_t1,', ')..'\n\n   There\'re only 16 regular toolbars\n\n         and only 8 MIDI toolbars.')
	if err_mess then r.MB(err_mess,'ERROR',0) return end

local function Counter(v1,err_t) -- counts toolbar ids repeats for error message
	local cnt = 0
		for _,v3 in next, err_t do
			if v3 == v1 then cnt = cnt + 1 end
		end
	return cnt
end

local err_t2 = {}
	for k1,v1 in next, toolbar_t do
		for k2,v2 in next, toolbar_t do
			if k1~=k2 and v1 ~= '' and v1==v2 then -- to avoid comparing v to itself and comparing empty strings
				if k2 == k1 + 1 and math.fmod(k2,2) == 0 then -- same docker toolbars, the 2nd toolbar placeholder is even number
					if Counter(v1,err_t1) == 0 then err_t1[#err_t1+1] = v1 end -- only add if the id is unique
				elseif k2 - k1 > 1 or math.fmod(k2,2) ~= 0 then -- different docker toolbars
					if Counter(v1,err_t2) == 0 then err_t2[#err_t2+1] = v1 end -- only add if the id is unique
				end
			end
		end
	end
	if #err_t1 + #err_t2 > 0 then
	err_mess1 = #err_t1 > 0 and 'Toolbars, selected for the same docker more than once:\n\n'..table.concat(err_t1,', ') or '' -- not a critical error, if happens, only one toolbar is shown
	err_mess2 = #err_t2 > 0 and 'Toolbars, selected for different dockers at the same time:\n\n'..table.concat(err_t2,', ') or '' -- without the trap if happens, constantly triggers re-launch prompt
	local line_break = (err_mess1 ~= '' and err_mess2  ~= '') and '\n\n' or ''
	r.MB(err_mess1..line_break..err_mess2, 'ERROR',0)
	return end

	for k,v in next, toolbar_t do
	local cond = v ~= '' or toolbar_t[k+1] ~= ''
		if k == 1 and cond then inset = Lt_open ~= '' and Lt_close ~= '' or 'Left'
		elseif k == 3 and cond then inset = Top_open ~= '' and Top_close ~= '' or 'Top'
		elseif k == 5 and cond then inset = Rt_open ~= '' and Rt_close ~= '' or 'Right'
		elseif k == 7 and cond then inset = Bot_open ~= '' and Bot_close ~= '' or 'Bottom' end
		if type(inset) == 'string' then
		r.MB(inset..' docker cursor cordinates are incomplete.', 'ERROR',0) return end
	end


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
		elseif v ~= '' then v = tonumber(v) -- to avoid conversion of empty strings to nil which will break the table for table.unpack() below
		end
		toolbar_t[k] = v
	end

-- 2. reassign values to user variables
local Lt_1,Lt_2,Top_1,Top_2,Rt_1,Rt_2,Bot_1,Bot_2 = table.unpack(toolbar_t)

-- 3. convert all possible empty strings inherited from step 1 to nils
local Lt_1 = tonumber(Lt_1)
local Lt_2 = tonumber(Lt_2)
local Top_1 = tonumber(Top_1)
local Top_2 = tonumber(Top_2)
local Rt_1 = tonumber(Rt_1)
local Rt_2 = tonumber(Rt_2)
local Bot_1 = tonumber(Bot_1)
local Bot_2 = tonumber(Bot_2)

-- all 3 steps above could have been done with just table.pack() and table.unpack(), including nils as table values, if only i understood how table.pack() works


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


-- Close and undock all docked toolbars which are sitting in the dockers activated in the user settings and are not the user selected ones
local leftovers_cnt = 0
	for line in io.lines(path) do
	-- find numbers of each toolbar registered in reaper.ini
	local tb_num = line:match('^toolbar:(%d*)=[%-%d%.]*%s%d*$')
		-- extract dockermode associated with the toolbar number
		if tb_num then dockermode = f_cont:match('toolbar:'..tb_num..'=[%-%d%.]*%s(%d*)')
		-- find dockerpos associated with the found dockermode
		local dockerpos = f_cont:match('dockermode'..dockermode..'=(%d*)')
		-- determine if the docker mode of a given toolbar matches position set it the user settings
			for k,v in next, toolbar_t do
				if v ~= '' then -- to keep docked but hidden the only toolbar in the docker after its removal from the settings, it remains hidden simply because it's the final toggle state in the defer loop. can't devise a reliable way to undock it because its dockerdpos can't be evaluated against empty fields of a docker in the user settings, when it's evaluated by disabling v ~= '' condition other static dockers end up being closed because all dockers are targeted, not only those which clash with the user settings as is the case in the current loop
				pos = (k == 1 or k == 2) and '1' or ((k == 3 or k == 4) and '2' or ((k == 5 or k == 6) and '3'
				or ((k == 7 or k == 8) and '0'))) end
				if dockerpos == pos then -- if an open toolbar sits in the docker activated in the user settings
			-- get the toolbar number taking into account renumbering, to convert to the numbering system used in the script and evaluate against the settings
				local tb_num = Conv_tlbr_nums(tb_num) -- convert to the numbering system used in the script and in the table act_t
					-- undock any docked toolbars sitting in the docker activated in the user settings which are not the user selected ones, if such are found re-launch prompt will be triggered via the 'leftovers_cnt' counter
					-- the loop is meant to avoid undocking legitimate toolbars because in this routine their code is evaluated as well
					local counter = 0
					for k,v in next, toolbar_t do
						if v == tb_num then counter = counter + 1 end
					end
					if counter == 0 then -- if the found toolbar is not used in the settings
						if select(2,r.BR_Win32_GetPrivateProfileString('toolbar:'..Conv_tlbr_vals(tb_num), 'dock', '', path)) == '1' then
						leftovers_cnt = leftovers_cnt + 1
						r.BR_Win32_WritePrivateProfileString('toolbar:'..Conv_tlbr_vals(tb_num), 'dock', '0', path) -- undock having converted to REAPER numbering system
							if r.GetToggleCommandStateEx(0, act_t[tb_num]) == 1 then
							r.Main_OnCommand(act_t[tb_num], 0) end -- close toolbar
						end
					end
				end
			end
		end
	end


-- Evaluate defaults to re-launch if necessary

local defaults_on = true
	for i = 1, #toolbar_t do
	local v = toolbar_t[i] -- for brevity
		if  v ~= '' then v = Conv_tlbr_vals(v) -- convert to the numbering system used by REAPER
		-- evaluate if defaults are intact in reaper.ini to condition 'Quit Reaper' action below, single discrepancy is enough
		local _, dock = r.BR_Win32_GetPrivateProfileString('toolbar:'..v, 'dock', '', path)
		local _, dockermode = r.BR_Win32_GetPrivateProfileString('REAPERdockpref', 'toolbar:'..v, '', path)
		local dockermode = dockermode:match('[%-%d%.]*%s(%d*)')
			if dockermode then
			_, dockerpos = r.BR_Win32_GetPrivateProfileString('REAPER', 'dockermode'..dockermode, '', path)
			-- OR
			-- dockerpos = reaper.DockGetPosition(tonumber(dockermode))
			end
		-- the integers are positions of toolbars predefined in the User Settings Section above and reflected in the toolbar_t table, in tabbed layout dockermodes are 2 units apart so as to not clash with each other when one is in a split layout
			if i == 1 or i == 2 then
				if Lt_tabbed == '' then defaults_on = dock == '1' and dockerpos == '1' and  (dockermode == '0' or dockermode == '1')
				else defaults_on = dock == '1' and dockerpos == '1' and dockermode == '0' end
			elseif i == 3 or i == 4 then
				if Top_tabbed == '' then defaults_on = dock == '1' and dockerpos == '2' and (dockermode == '2' or dockermode == '3')
				else defaults_on = dock == '1' and dockerpos == '2' and dockermode == '2' end
			elseif i == 5 or i == 6 then
				if Rt_tabbed == '' then defaults_on = dock == '1' and dockerpos == '3' and (dockermode == '4' or dockermode == '5')
				else defaults_on = dock == '1' and dockerpos == '3' and dockermode == '4' end
			elseif i == 7 or i == 8 then
				if Bot_tabbed == '' then defaults_on = dock == '1' and dockerpos == '0' and (dockermode == '6' or dockermode == '7')
				else defaults_on = dock == '1' and dockerpos == '0' and dockermode == '6' end
			end
		end

		if not defaults_on then break end -- to call prompt for re-launch

	end


	-- Prompt to re-launch to re-activate the Settings
	if renum or leftovers_cnt > 0 or not defaults_on or r.HasExtState('+','+') then resp = r.MB('   Since the last run of the script settings have changed.\n\nThe script must be re-initialized and won\'t work otherwise.\n\n    REAPER will now quit and will have to be re-launched.\n\n     After restart run the script again unless it\'s included\n\n\tin the SWS extension Startup actions.\n\n          YOU MAY WANT TO SAVE PROJECT FIRST.','PROMPT',1)
		if resp == 1 then r.Main_OnCommand(40004, 0) -- File: Quit REAPER
		else r.SetExtState('+', '+', '', false) -- to make re-launch prompt trigger persistent, to guarantee that removed toolbars are undocked as well a re-launch is required
		return end
	end


-- Set values in reaper.ini
	for i = 1, #toolbar_t do
	local v = toolbar_t[i] -- for brevity
		if v ~= '' then v = Conv_tlbr_vals(v) -- if not an empty string which has been retained in the table after conversion at step 1 above
		r.BR_Win32_WritePrivateProfileString('toolbar:'..v, 'dock', '1', path) -- enable docking for the given toolbar
		r.BR_Win32_WritePrivateProfileString('toolbar:'..v, 'wnd_vis', '0', path) -- hide so they're not visible on re-launch
			-- set the 'dockermode' number the toolbar will be assigned to, zero based
			if Lt_tabbed ~= '' and (i == 1 or i == 2) then dockermode = '0'
			elseif Top_tabbed ~= '' and (i == 3 or i == 4) then dockermode = '2'
			elseif Rt_tabbed ~= '' and (i == 5 or i == 6) then dockermode = '4'
			elseif Bot_tabbed ~= '' and (i == 7 or i == 8) then dockermode = '6'
			else dockermode = tostring(i - 1)
			end
			r.BR_Win32_WritePrivateProfileString('REAPERdockpref', 'toolbar:'..v, '0.50000000 '..dockermode, path)
			-- assign docker position to dockermode per toolbar position predefined in the toolbar_t table (table starts from left, REAPER counts from bottom)
			if i == 1 or i == 2 then dockerpos = '1' -- left
			elseif i == 3 or i == 4 then dockerpos = '2' -- top
			elseif i == 5 or i == 6 then dockerpos = '3' -- right
			elseif i == 7 or i == 8 then dockerpos = '0' -- bottom
			end
			r.BR_Win32_WritePrivateProfileString('REAPER', 'dockermode'..dockermode, dockerpos, path)
		end
	end


local function TOGGLE(Toolbar, ID, status)
	if Toolbar then
	local state = r.GetToggleCommandStateEx(0, ID)
		if state ~= status then
		r.Main_OnCommand(ID, 0) end
	end
end


-- Get Arrange window size from reaper.ini
-- thanks to Claudiohbsantos and Mespotine https://forums.cockos.com/showthread.php?t=203785
local wnd_w = f_cont:match('(wnd_w=%d*)'); local wnd_w = tonumber(wnd_w:match('=(%d*)'))
local wnd_h = f_cont:match('(wnd_h=%d*)'); local wnd_h = tonumber(wnd_h:match('=(%d*)'))


-- Convert user string variables to integers
local Lt_open = tonumber(Lt_open)
local Lt_close = tonumber(Lt_close)
local Top_open = tonumber(Top_open)
local Top_close = tonumber(Top_close)
local Rt_open = tonumber(Rt_open)
local Rt_close = tonumber(Rt_close)
local Bot_open = tonumber(Bot_open)
local Bot_close = tonumber(Bot_close)


local function Main()
	local x,y = r.GetMousePosition()
		 -- LEFT
		if Lt_1 or Lt_2 then
			if x >= 0 and x < Lt_open then status = 1
			TOGGLE(Lt_2, act_t[Lt_2], status)
			TOGGLE(Lt_1, act_t[Lt_1], status) -- last to open and so be active by default in tabbed layout is the first in the user settings list, here and below (might not apply to MIDI toolbars)
			elseif x > Lt_close then status = 0
			TOGGLE(Lt_1, act_t[Lt_1], status)
			TOGGLE(Lt_2, act_t[Lt_2], status)
			end
		end
		-- TOP
		if Top_1 or Top_2 then
			if y >= 0 and y < Top_open then status = 1
			TOGGLE(Top_2, act_t[Top_2], status)
			TOGGLE(Top_1, act_t[Top_1], status)
			elseif y > Top_close then status = 0
			TOGGLE(Top_1, act_t[Top_1], status)
			TOGGLE(Top_2, act_t[Top_2], status)
			end
		end
		if Rt_1 or Rt_2 or Bot_1 or Bot_2 then
		-- RIGHT
			if x < wnd_w and x > wnd_w - Rt_open then status = 1
			TOGGLE(Rt_2, act_t[Rt_2], status)
			TOGGLE(Rt_1, act_t[Rt_1], status)
			elseif x < wnd_w - Rt_close then status = 0
			TOGGLE(Rt_1, act_t[Rt_1], status)
			TOGGLE(Rt_2, act_t[Rt_2], status)
			end
		-- BOTTOM
			if y < wnd_h and y > wnd_h - Bot_open then status = 1
			TOGGLE(Bot_2, act_t[Bot_2], status)
			TOGGLE(Bot_1, act_t[Bot_1], status)
			elseif y < wnd_h - Bot_close then status = 0
			TOGGLE(Bot_1, act_t[Bot_1], status)
			TOGGLE(Bot_2, act_t[Bot_2], status)
			end
		end
	r.defer(Main)
end

	if defaults_on then -- only run if settings are correct
	Main() end




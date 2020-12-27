-- @description Convert custom action to LUA ReaScript
-- @author BuyOne
-- @version 1.0
-- @about Converts a custom action by its command ID to LUA ReaScript

--[[

* ReaScript Name: BuyOne_Convert custom action to LUA ReaScript.lua
* Description: in the name
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M
* Changelog:
	+ v1.1 	Added support for ancillary actions often used within custom action:
		Action: Wait X seconds before next action
		Action: Prompt to continue (only valid within custom actions)
		Action: Set action loop start (only valid within custom actions)
		Action: Prompt to go to action loop start (only valid within custom actions)
	+ v1.0 	Initial release

]]

---------------- USER SETTINGS SECTION -----------------

-- To use a .ReaperKeyMap file for parsing insert its name with extension in between the quotes, e.g. myFile.ReaperKeyMap.
-- It MUST reside in the \KeMaps subdirectory of the REAPER program directory (aka resource path)
-- Read HELP for further details

local ReaperKeyMap = ""

------------- END OF USER SETTINGS SECTION ------------

local HELP = [=[

Limitations:

1. Only parses (unpacks) nested custom actions 1 level deep, the rest are converted to code using their extracted command IDs.

2. Doesn't export or parse SWS cycle actions only saving command IDs of those which are happen to be included in custom actions. This is also true for ReaScripts included in custom actions.

The exported script will malfunction if such nested custom or SWS cycle actions or ReaScripts become anavilable.

***********************************

The default location for export is Scripts sub-directory in the REAPER project directory unless another folder is specified. If the specified folder doesn't exist it will be created. The last specified folder name is remembered and will be displayed in the corresponding field of the dialogue on the next script run during REAPER session.

If you wish to convert an external custom action provided in a .ReaperKeyMap file, you can specify this file name in the USER SETTINGS of this script and then run it.

]=]

local r = reaper

-- API Check
	if not r.APIExists("CF_GetCommandText") then r.ClearConsole()
	r.ShowConsoleMsg("Get the SWS/S&M extension at\nhttps://www.sws-extension.org/")
	r.MB("This script requires the SWS/S&M extension.\n\n If it's installed then it needs to be updated.","API CHECK", 0)
	return end

::RETRY::

local comment = 'to run the exported script from Arrange view'
local subdir = r.GetExtState(select(2,r.get_action_context()):match('[^\\/]+%.%w+'), 'dir_field')
	if subdir == '' then subdir = 'existing or new; or leave as it is or empty' end

local retval, input = r.GetUserInputs('Submit custom action (type h in the 1st field for help)',3,'Custom action command ID:,For MIDI Editor (type char. a):,Specify folder under \\Scripts:,extrawidth=150',','..comment..','..subdir)

	if retval == false or input == input:match('^(,.+)') -- empty 1st field
	then return end

local midi_from_arrange = input:match(',([^,]+),')
local subdir = input:match(',([^,]+)$')
	if not subdir then subdir = '' end
r.SetExtState(select(2,r.get_action_context()):match('[^\\/]+%.%w+'), 'dir_field', subdir, false)
local input = input:match('([^,]+),')

	if input:match('(h)') then r.ClearConsole() r.ShowConsoleMsg(HELP) goto RETRY end -- clear console to prevent adding up text on repeated submission of q

	if input:len() < 32 then mess = 'Doesn\'t look like a custom action command ID.'
	elseif input:match('(_?RS[%w]+)') then mess = 'The command ID belongs to a ReaScript.'
	else mess = nil end

	if mess then
	resp = r.MB(mess,'ERROR',5)
		if resp == 4 then goto RETRY else return end
	end

-- Get custom action code as it appears in the target file

-- Concatenate OS specific path separators
local input = input:gsub('_','')
local path = r.GetResourcePath()
	if r.GetOS() == 'Win32' or r.GetOS() == 'Win64' then sep = '\\'
	else sep = '/' end -- OS evaluation is nicked from X-Raym
	-- OR
	-- sep = reaper.GetOS():match('Win') and '\\' or '/' -- nicked from amagalma


-- Switch to user specified .ReaperKeyMap file
local targ_file = 'reaper-kb.ini'

	if ReaperKeyMap and ReaperKeyMap ~= '' then -- check if the file exists
		for f in io.popen('dir \"'..path..sep..'KeyMaps'..sep..ReaperKeyMap..'\" /b'):lines() do -- r.MB(f,'',0)
			if f == ReaperKeyMap then break end
		end
		if not f then resp = r.MB('    '..ReaperKeyMap..' file\n\n            was\'t found.\n\n   Switching to '..targ_file,'WARNING',1)
			if resp == 2 then return end
		else targ_file = 'KeyMaps'..sep..ReaperKeyMap end
	end


	for line in io.lines(path..sep..targ_file) do
		if line:match('\"('..input..')\"') then
		code = line	break end
	end

	if not code then r.MB('The specified command ID wasn\'t found.','ERROR',0) return end

	if code:match('%s(32062)%s') then r.MB('This is an Inline MIDI Editor custom action.\n\n  These are unfortunately not supported.\n\n                          ¯\\_(ツ)_/¯','ERROR',0) return end


	-- Concatenate the path
	if subdir ~= '' and subdir ~= 'existing or new; or leave as it is or empty' then
	subdir = string.gsub(subdir:gsub('[\\/:*?\"<>|]', ''), '([%s]+)', ' ') -- remove illegal characters \/:*?"<>|, then remove extra spaces left behind
	-- check if such directory already exists and if not, create
		for dir in io.popen('dir \"'..path..sep..'Scripts\" /b'):lines() do
			if dir == subdir then exists = true break end
		end
		if not exists then os.execute('mkdir \"'..path..sep..'Scripts'..sep..subdir..'\"')
		end
	f_path = path..sep..'Scripts'..sep..subdir
	subdir_txt = '\\'..subdir -- for the concluding message in the end
	else f_path = path..sep..'Scripts'; subdir_txt = '' end


local _, end_idx, cust_act_name = code:find(':%s*(.+)\"') -- get end index of cust. action name end in its code

local cust_act_name = string.gsub(cust_act_name:gsub('[\\/:*?\"<>|]', ''), '([%s]+)', ' ') -- first remove illegal characters \/:*?"<>|, then remove extra spaces left behind

local f_name = cust_act_name

	-- Truncate cust. action name if exceeds the OS limit for file name
	if cust_act_name:len() > 255 then
	local trunc_t = {}
		for w in cust_act_name:gmatch('(.)') do -- split name by characters
		trunc_t[#trunc_t+1] = w
		end

	f_name = ''
		for i = 1, 237 do -- reassemble accounting for additional file name elements 255 - 18
		f_name = f_name..trunc_t[i]
		end

	r.MB('The name of the custom action has been\n\ntruncated to conform to OS limitations\n\n                 on file name length.','WARNING',0)
	end

-- Separate custom action individual action IDs from its name
local _, _, actions = code:find('([_%d%a&%s%.%-]+)',end_idx+2) -- separate custom action individual action IDs from its name: pos = name end index + quotation mark + space
-- OR
-- local actions = select(3,code:find('([_%d%a&%s%.%-]+)',end_idx+2))


-- Save action IDs 1 by 1 to a table
local inset1, inset2 = '',''
local actions_t = {}
	for w in actions:gmatch('([^%s]+)') do
		if w:match('^(_RS%w+)') then reascript = true inset1 = '      The custom action uses ReaScripts.\n\n' end
		if w:match('_S&M_CYCLACTION_') then cycle_action = true inset2 = 'The custom action uses SWS cycle actions.\n\n' end
		-- Nested custom action
		if w:match('^(_[%d%l]+)') and not w:match('_S&M_CYCLACTION_') then
			for line in io.lines(path..sep..targ_file) do
			local w = w:gsub('_','')
				if line:match('\"('..w..')\"') then
				nest_code = line break end
			end
		local _, end_idx, cust_act_name = nest_code:find(':%s*(.+)\"') -- get index of cust. action name end in its code
		local _, _, actions = nest_code:find('([_%d%a&%s%.%-]+)',end_idx+2) -- separate custom action individual action IDs from its name: pos = name end index + quotation mark + space
			for w in actions:gmatch('([^%s]+)') do
			actions_t[#actions_t+1] = w
			end
		else actions_t[#actions_t+1] = w end
	end

	if reascript or cycle_action then r.MB(inset1..inset2..'             If they become unavailable\n\n      the exported script will malfunction.','WARNING',0) end


-- Initialize code for ancillary actions
local cont_action = '\nr.PreventUIRefresh(-1)\n\tlocal resp = r.MB(\'Continue running the script?\',\'Script paused\',1)\n\tif resp == 2 then return end\n\nr.PreventUIRefresh(1)\n' -- 2000 Action: Prompt to continue (only valid within custom actions)
local set_loop_start = '\nr.PreventUIRefresh(-1)\n\n\trepeat\n\nr.PreventUIRefresh(1)\n' -- 2001 Action: Set action loop start (only valid within custom actions)
local go_loop_start = '\nr.PreventUIRefresh(-1)\n\n\tlocal resp = r.MB(\'Loop the script from step 1?\',\'Script paused\',1)\n\tuntil resp == 2\n\nr.PreventUIRefresh(1)\n' -- 2002 Action: Prompt to go to action loop start (only valid within custom actions)
local function wait(v) -- 2008 - 2012 Action: Wait X seconds before next action
	if v == '2008' then sec = '0.1'
	elseif v == '2009' then sec = '0.5'
	elseif v == '2010' then sec = '1'
	elseif v == '2011' then sec = '5'
	elseif v == '2012' then sec = '10' end
	local wait = '\nr.PreventUIRefresh(-1)\n\nlocal time_stamp = r.time_precise()\n\n\trepeat\n\tlocal cur_time = r.time_precise()\n\tuntil cur_time - time_stamp == '..sec..'\n\nr.PreventUIRefresh(1)'
	return wait
end


-- Concatenate actions code
local code_t = {}
	for _,v in next, actions_t do
	local func = v:match('(_.+)') and 'r.NamedCommandLookup(\"'..v..'\")' or v	-- either SWS/S&M or native
	local id = r.NamedCommandLookup(v) -- works for native actions as well
	local sect_midi = code:match('%s(3206[01])%s')
	local sect_media_main = code:match('%s(32063)%s') or '0'
		if sect_midi then
			if v == "2000" then str = cont_action
			elseif v == "2001" then str = set_loop_start; repeat_loop = v -- any value so it's not nil
			elseif v == "2002" then str = go_loop_start;
				-- Insert repeat at the very start of action sequence if loop start wasn't set explicitly by 2001
				if not repeat_loop then table.insert(code_t, 1, set_loop_start) end
			else str = 'r.MIDIEditor_OnCommand(hwnd,'..func..') -- '..r.CF_GetCommandText(tonumber(sect_midi), id) -- thanks to cfillion https://forum.cockos.com/showthread.php?t=186732
			end
		else
			if v == "2000" then str = cont_action
			elseif v == "2001" then str = set_loop_start; repeat_loop = v -- any value so it's not nil
			elseif v == "2002" then str = go_loop_start;
				-- Insert repeat at the very start of action sequence if loop start wasn't set explicitly by 2001
				if not repeat_loop then table.insert(code_t, 1, set_loop_start) end
			elseif tonumber(v) > 2007 and tonumber(v) < 2013 and sect_media_main == '0' then str = wait(v)
			else str = 'r.Main_OnCommand('..func..',0) -- '..r.CF_GetCommandText(tonumber(sect_media_main), id) end
		end
	code_t[#code_t+1] = str
	end


-- Concatenate prefix, comments and addiditional code
local pref, inset1, inset2, inset3 = '','','',''
local sect_code = code:match('%s(3206%d)%s')
	if sect_code == '32060' then pref = 'MIDI Ed_'
	elseif sect_code == '32061' then pref = 'MIDI EvL_'
	elseif sect_code == '32063' then pref = 'Media Ex_'
	else pref = 'Main_' end


	if midi_from_arrange == 'a' and (sect_code == '32060' or sect_code == '32061') then inset1, inset2, inset3, pref = '\n-- Import into the Main section of the Action list and run from Arrange.', 'r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor\n\nlocal hwnd = r.MIDIEditor_GetActive()\n\n','\n\nr.MIDIEditor_OnCommand(hwnd,2) -- File: Close window', pref..'from Arrange_'
	else
		if sect_code == '32060' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Editor and/or MIDI Event list editor'; loc = 'inside '..sect_name -- loc is separate because it uses previously initialized variable
		elseif sect_code == '32061' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Event list editor and/or MIDI Editor'; loc = 'inside '..sect_name
		elseif sect_code == '32063' then sect_name = 'Media Explorer'; loc = 'inside '..sect_name
		else sect_name = 'Main'; loc = 'Arrange'
		end
	inset1 = '\n-- Import into the '..sect_name..' section of the Action list and run from '..loc..'.'
	end


-- Concatenate LUA file code
local output = '-- Converted from a custom action \"Custom: '..cust_act_name..'\"'..inset1..'\n\n\nlocal r = reaper\n\nr.PreventUIRefresh(1)\nr.Undo_BeginBlock();\n\n'..inset2..table.concat(code_t,'\n')..inset3..'\n\nr.Undo_EndBlock(\"'..cust_act_name..'\",-1)\nr.PreventUIRefresh(-1)\n\n\n'

local f = io.open(f_path..sep..pref..'CA_'..f_name..'.lua','w')
local result,_,_ = f:write(output)
f:close()

local mess, head, mode = table.unpack(result and {'       File has been created successfully\n\n      and placed in the \\Scripts'..subdir_txt..'  folder\n\n       of the REAPER program directory.\n\nWould you like to open the subfolder now?', 'SUCCESS', 4} or {'File creation has failed.', 'FAILURE', 0}) -- idiom source https://stackoverflow.com/questions/25362528/lua-ternary-operator-multiple-variables

local resp = r.MB(mess,head,mode)

local command = sep == '\\' and 'explorer ' or 'open '

	if resp == 6 then os.execute(command..f_path) end



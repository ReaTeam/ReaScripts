-- @noindex

--[[

* ReaScript Name: BuyOne_Convert custom action to Lua ReaScript.lua
* Description: in the name
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread:
* Version: 1.2
* REAPER: at least v5.962
* Extensions: SWS/S&M
* Changelog:
	+ v1.2	As a safety measure added option to select specific Action list section, might be superfluous;
		Help updated accordingly;
		Other minor usability tweaks and error proofing;
	+ v1.1 	Added support for ancillary actions often used within custom actions:
		Action: Wait X seconds before next action;
		Action: Prompt to continue (only valid within custom actions);
		Action: Set action loop start (only valid within custom actions);
		Action: Prompt to go to action loop start (only valid within custom actions);
	+ v1.0 	Initial release

]]

---------------- USER SETTINGS SECTION -----------------

-- To use a .ReaperKeyMap file for parsing insert its name with extension in between the quotes, e.g. myFile.ReaperKeyMap.
-- It MUST reside in the \KeMaps subdirectory of the REAPER program directory (aka resource path)
-- See HELP for further details

local ReaperKeyMap = ""

------------- END OF USER SETTINGS SECTION ------------

local HELP = [[

Limitations:

1. Only parses (unpacks) nested custom actions 1 level deep, the rest are converted to code using their extracted command IDs.

2. Doesn't export or parse SWS cycle actions only saving command IDs of those which are happen to be included in custom actions. This is also true for ReaScripts included in custom actions.

The exported script will malfunction if such nested custom or SWS cycle actions or ReaScripts become unavilable.

3. Inline MIDI Editor custom actions are not supported.

***********************************

Specifying section might be needed since custom actions in different sections can have the same command ID. It's an extremely rare case but in theory it's not impossible. If you're sure that no command ID is shared between different Action list sections, ignore this setting leaving the field blank or containing the default comment. After export you can check if the actions listed in the resulting script do correspond to those which feature in the custom action.

Action list Section codes for field 2 of the dialogue

Main section (including Main (alt recording)) = 1
MIDI Editor section = 2
MIDI Event list editor section = 3
Media Explorer section = 4

The default location for export is Scripts sub-directory in the REAPER project directory unless another folder is specified. If the specified folder doesn't exist it will be created. The last specified folder name is remembered and will be displayed in the corresponding field of the dialogue on the next script run during REAPER session.

If you wish to convert an external custom action provided in a .ReaperKeyMap file, you can specify this file name in the USER SETTINGS of this script and then run it.

]]

local r = reaper

-- API Check
	if not r.APIExists("CF_GetCommandText") then r.ClearConsole()
	r.ShowConsoleMsg("Get the SWS/S&M extension at\nhttps://www.sws-extension.org/")
	r.MB("This script requires the SWS/S&M extension.\n\n If it's installed then it needs to be updated.","API CHECK", 0)
	return end

local script_name = select(2,r.get_action_context()):match('[^\\/]+%.%w+')

::RETRY::

local comment1 = 'type h in the 1st field for help'
local comment2 = 'to run the exported script from Arrange view'
local subdir = r.GetExtState(script_name, 'dir_field')
	if subdir == '' then subdir = 'existing or new; or leave as it is or empty' end
local comm_id = r.GetExtState(script_name, 'comm_id')

local retval, input = r.GetUserInputs('Submit custom action (type h in the 1st field for help)',4,'Custom action command ID:,Acton list section:,For MIDI Editor (type char. a):,Specify folder under \\Scripts:,extrawidth=150',''..comm_id..','..comment1..','..comment2..','..subdir)

r.DeleteExtState(script_name, 'comm_id', true)

local input = input:gsub('^[%s]*','') -- remove leading spaces from the 1st field

	if retval == false or input == input:match('^(,.+)') -- empty 1st field or only containing spaces
	then return end

local comm_id = input:match('^([^,]+),')

	if comm_id:match('^%s*[Hh]+%s*$') then r.ClearConsole() r.ShowConsoleMsg(HELP) goto RETRY end -- clear console to prevent adding up text on repeated submission of h

local section, midi_from_arrange = input:match(',([^,]*),([^,]*),')

	if section == '1' then section = '0'
	elseif section == '2' then section = '32060'
	elseif section == '3' then section = '32061'
	elseif section == '4' then section = '32063'
	elseif section == comment1 then section = ''
	elseif section ~= '' then resp = reaper.MB('Incorrect section selection. If unsure, click Retry\n\n         and type \'h\' in the 1st field for help.','ERROR... '..section,5)
		if resp == 4 then r.SetExtState(script_name, 'comm_id', comm_id, false) goto RETRY
		else return end
	end

local subdir = input:match(',([^,]+)$')
	if not subdir then subdir = '' end
local subdir = subdir:gsub('[\\/:*?\"<>|]', '') -- remove illegal characters \/:*?"<>|
r.SetExtState(script_name, 'dir_field', subdir, false)


	if comm_id:len() < 32 then mess = 'Doesn\'t look like a custom action command ID.'
	elseif comm_id:match('(_?RS[%w]+)') then mess = 'The command ID belongs to a ReaScript.'
	else mess = nil end
	if mess then resp = r.MB(mess,'ERROR... '..comm_id,5)
		if resp == 4 then goto RETRY else return end
	end


-- Get custom action code as it appears in the target file
local comm_id = comm_id:gsub('_','')


-- Concatenate OS specific path separators
local path = r.GetResourcePath()
	if r.GetOS() == 'Win32' or r.GetOS() == 'Win64' then sep = '\\'
	else sep = '/' end -- OS evaluation is nicked from X-Raym
	-- OR
	-- sep = reaper.GetOS():match('Win') and '\\' or '/' -- nicked from amagalma


-- Switch to user specified .ReaperKeyMap file
local targ_file = 'reaper-kb.ini'

	if ReaperKeyMap and ReaperKeyMap ~= '' then -- check if the file exists
	local i = 0
		repeat f = r.EnumerateFiles(path..sep..'KeyMaps'..sep, i)
			if f == ReaperKeyMap then break end
		i = i + 1
		until not f
		if not f then resp = r.MB('    '..ReaperKeyMap..' file\n\n            was\'t found.\n\n      Switching to '..targ_file,'WARNING',1)
			if resp == 2 then return end
		else targ_file = 'KeyMaps'..sep..ReaperKeyMap end
	end

	for line in io.lines(path..sep..targ_file) do
		if section == '' then cond = line:match('\"('..comm_id..')\"')
		else cond = line:match('%s('..section..'%s\"'..comm_id..'\")%s') end
		if cond then code = line break end
	end

	if not code then
	local t = {[0] = '1',[32060] = '2',[32061] = '3',[32063] = '4'} -- back convert just to display in the error message
	local caption = section ~= '' and t[tonumber(section)] or ''
	local inset = section ~= '' and '\n\n       in the specified Action list section.' or '.'
	local resp = r.MB('The submitted command ID wasn\'t found'..inset,'ERROR... '..caption,5)
		if resp == 4 then r.SetExtState(script_name, 'comm_id', comm_id, false) goto RETRY
		else return end
	end


	if code:match('%s(32062)%s\"'..comm_id..'') then r.MB('This is an Inline MIDI Editor custom action.\n\n  These are unfortunately not supported.\n\n                          ¯\\_(ツ)_/¯','ERROR',0) return end


-- Concatenate the path
	if subdir ~= '' and subdir ~= 'existing or new; or leave as it is or empty' then
	-- check if such directory already exists and if not, create
		local i = 0
			repeat dir = r.EnumerateSubdirectories(path..sep..'Scripts'..sep, i)
				if dir == subdir then break end
			i = i + 1
			until not dir
		if not dir then r.RecursiveCreateDirectory(path..sep..'Scripts'..sep..subdir, 0) -- should return 0 on failure but i prefer explicit confirmation below
		-- check if the directory has been created
		local t_point = r.time_precise() -- wait for .5 a sec until the function cache is cleared, otherwise the created dir isn't registered
		repeat until r.time_precise() - t_point > 0.5
		local i = 0
			repeat dir = r.EnumerateSubdirectories(path..sep..'Scripts'..sep, i)
				if dir == subdir then break end
			i = i + 1
			until not dir
		end
		if dir then f_path = path..sep..'Scripts'..sep..subdir
		subdir_txt = '\\'..subdir -- for the concluding message in the end
		else f_path = path..sep..'Scripts'; subdir_txt = ''
		r.MB('      Folder creation has failed.\n\nThe exported files will be placed\n\n       in the\\Scripts  directory.','WARNING',0)
		end
	else f_path = path..sep..'Scripts'; subdir_txt = '' end


local _, end_idx, cust_act_name = code:find(':%s*(.+)\"') -- get end index of cust. action name end in its code

local f_name = cust_act_name:gsub('[\\/:*?\"<>|]', '') -- remove illegal characters \/:*?"<>|

	-- Truncate cust. action name if exceeds the OS limit for file name
	if #f_name > 255 then f_name = f_name:sub(1, 230) -- accounting for additional file name elements 255 - 25
	reaper.MB('The name of the custom action has been\n\ntruncated to conform to OS limitations\n\n                 on file name length.','WARNING',0)
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
		if w:match('^(_[%d%l]+)') and not w:match('_S&M_CYCLACTION_') then --('([^_%u%-%.&]%d+%l+)')
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

	if reascript or cycle_action then r.MB(inset1..inset2..'            If they become unavailable\n\n      the exported script will malfunction.','WARNING',0) end


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
	local sect_midi = code:match('%s(3206[01])%s\"'..comm_id..'')
	local sect_media_main = code:match('%s(32063)%s\"'..comm_id..'') or '0' -- 0 covers Main (alt rec) as well since it contains the same actions as the Main
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
			elseif tonumber(v) and (tonumber(v) > 2007 and tonumber(v) < 2013) and sect_media_main == '0' then str = wait(v)
			else str = 'r.Main_OnCommand('..func..',0) -- '..r.CF_GetCommandText(tonumber(sect_media_main), id) end
		end
	code_t[#code_t+1] = str
	end


-- Concatenate prefix, comments and addiditional code
local pref, inset1, inset2, inset3 = '','','',''
local sect_code = code:match('%s(3206%d)%s\"'..comm_id..'')
	if sect_code == '32060' then pref = 'MIDI Ed_'
	elseif sect_code == '32061' then pref = 'MIDI EvL_'
	elseif sect_code == '32063' then pref = 'Media Ex_'
	else pref = 'Main_' end


	if midi_from_arrange == 'a' and (sect_code == '32060' or sect_code == '32061') then inset1, inset2, inset3, pref = '\n-- Import into the Main section of the Action list and run from Arrange.', 'r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor\n\nlocal hwnd = r.MIDIEditor_GetActive()\n\n','\n\nr.MIDIEditor_OnCommand(hwnd,2) -- File: Close window', pref..'from Arrange_'
	else
		if sect_code == '32060' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Editor and/or MIDI Event list editor'; loc = 'inside '..sect_name -- loc is separate because it uses previously initialized variable
		elseif sect_code == '32061' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Event list editor and/or MIDI Editor'; loc = 'inside '..sect_name
		elseif sect_code == '32063' then sect_name = 'Media Explorer'; loc = 'inside '..sect_name
		else sect_name = 'Main / Main (alt recording)'; loc = 'Arrange'
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

	if resp == 6 then r.CF_ShellExecute(f_path) end






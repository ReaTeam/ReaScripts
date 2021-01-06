-- @noindex

--[[

* ReaScript Name: BuyOne_Convert custom actions in batch to Lua ReaScripts or dump as Lua code.lua
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
	+ v1.2	Added support for Main (alt recording) section;
		Minor error proofing;
	+ v1.1 	Correction of typos in comments;
		Added support for ancillary actions often used within custom actions:
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

I. FLAGS SUMMARY

1 - To convert/dump Main (incl. Main (alt recording)) and Media Explorer sections custom actions

2 - To convert/dump MIDI Editor and MIDI Event List Editor sections custom actions

3 - Convert custom actions of the specified types (1, 2 or both) to individual Lua scripts

4 - Dump custom actions of the specified types as a plain txt file containing their Lua code

5 - In syntax allowing to run MIDI Editor custom actions from Arrange

The flags are meant to be combined into a numeric code in ascending order.

All available combinations:

13 - Only Main and Media Explorer sections custom actions as individual Lua scripts
14 - Only Main and Media Explorer sections custom actions as plain txt dump file
23 - Only MIDI Editor and MIDI Event List Editor sections custom actions as individual Lua scripts
235 - Only MIDI Editor and MIDI Event List Editor sections custom actions as individual Lua scripts for use from Arrange
24 - Only MIDI Editor and MIDI Event List Editor sections custom actions as plain txt dump file
245 - Only MIDI Editor and MIDI Event List Editor sections custom actions as plain txt dump file with code for use from Arrange
123 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as individual Lua scripts
1235 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as individual Lua scripts, MIDI Editor/MIDI Event List Editor custom actions for use from Arrange
124 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as plain txt dump file
1245 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as plain txt dump file, MIDI Editor/MIDI Event List Editor custom actions for use from Arrange


II. SPECS

Main flag includes Media Explorer custom actions. MIDI flag includes both MIDI Editor and MIDI Event list custom actions.

Custom actions are only parsed (unpacked) one nested custom action deep. Anything deeper is saved as a command ID, meaning the resulting script will malfunction if that custom action becomes unavilable. But since all custom actions are converted their command IDs can be substituted manually with the corresponding code.

Other scripts and SWS cycle actions included in custom actions are also only saved as their command IDs so their subsequent removal will affect the script functionality.

Text dump files created earlier get overwritten after user confirmation, Lua files with the same name created earlier get overwritten tacitly by default.

Inline MIDI Editor custom actions are unfortunately not supported and won't be exported since there's to my knowledge no simple way to auto-convert them to a script.

The default location for export is Scripts sub-directory in the REAPER project directory unless another folder is specified. If the specified folder doesn't exist it will be created. The last specified folder name is remembered and will be displayed in the corresponding field of the dialogue on the next script run during REAPER session.

If you wish to only batch convert specific actions, you can either use another script 'Convert filtered custom actions to Lua ReaScripts or dump as Lua code.lua' or use REAPER's Action list filter to find them, export them as a .ReaperKeyMap file into the \KeyMap sub-directory of the REAPER project directory, specify its name in the USER SETTINGS of this script and run it.
Mind that in this case the caveat of lost nested custom actions mentioned above applies.

]]

local r = reaper

-- API Check
	if not r.APIExists("CF_GetCommandText") then
	reaper.ShowConsoleMsg("Get the SWS/S&M extension at\nhttps://www.sws-extension.org/")
	reaper.MB("This script requires the SWS/S&M extension.\n\n If it's installed then it needs to be updated.","API CHECK", 0)
	return end

local script_name = select(2,r.get_action_context()):match('[^\\/]+%.%w+')

local err_mess = '           Malformed code.\n\n      If not sure, click Retry\n\nand type \'h\' in the upper field.'

::RETRY::

local subdir = r.GetExtState(script_name, 'dir_field')
	if subdir == '' then subdir = 'existing or new; or leave as it is or empty' end

local legend = '3 - Lua scripts; 4 - 1 txt file; 5 - MIDI from Arrange'

local retval, input = r.GetUserInputs('Convert or dump custom actions (type h in the 1st field for help)',3,'Type digits (type h for help):,Specify folder under \\Scripts:,Legend: 1 - Main; 2 - MIDI;  -->,extrawidth=170',','..subdir..','..legend..'')

local input = input:gsub('^[%s]*','') -- remove leading spaces from the 1st field

	if retval == false or input:match('^([1-5]*),') == '' -- Cancel or OK with empty field or only containing spaces
	then return end

	if input:match('^([%sHh]*),') then r.ClearConsole() r.ShowConsoleMsg(HELP) goto RETRY end -- clear console to prevent adding up text on repeated submission of h

local subdir = input:match(',(.+),')
	if not subdir then subdir = '' end
local subdir = subdir:gsub('[\\/:*?\"<>|]', '') -- remove illegal characters \/:*?"<>|
r.SetExtState(script_name, 'dir_field', subdir, false)

local input = input:match('^([1-5]*),')
	if not input then input = '' end -- to avoid error in concatenating message below

	if input == '' or input:len() < 2 or input:len() > 4 then resp = r.MB(err_mess,'ERROR...'..input or '',5) -- displays entered flags if they fall within the range but are too few or too numerous than needed
		if resp == 4 then goto RETRY
		else return end
	end

-- Construct user entered flags table, making sure that there're at least 1 or 2
local flags_t = {}
local flags_cntr = 0
local tbl_len_cntr = 0
	for w in input:gmatch('(%d)') do
		if w == '1' or w == '2' then flags_cntr = flags_cntr + 1 end
	flags_t[tonumber(w)] = '' -- a dummy value
	tbl_len_cntr = tbl_len_cntr + 1
	end


-- Prevent inconsistent flags
	if flags_cntr == 0 or (flags_t[1] and flags_t[2] and tbl_len_cntr == 2) or (flags_t[1] and flags_t[5] and not flags_t[2]) or (flags_t[3] and flags_t[4]) then resp = reaper.MB(err_mess,'ERROR... '..input,5)
		if resp == 4 then goto RETRY else return end
	end


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
		if not f then resp = r.MB('    '..ReaperKeyMap..' file\n\n            was\'t found.\n\n   Switching to '..targ_file,'WARNING',1)
			if resp == 2 then return end
		else targ_file = 'KeyMaps'..sep..ReaperKeyMap end
	end


-- Construct a table of individual custom actons strings
local lines_t = {}
	for line in io.lines(path..sep..targ_file) do
		if line:match('^ACT') then -- exclude categories besides actions
			if flags_t[1] and (line:match('%s(0)%s\"') or line:match('%s(100)%s\"') or line:match('%s(32063)%s\"')) then lines_t[#lines_t+1] = line
			elseif flags_t[2] and line:match('%s(3206[01])%s\"') then lines_t[#lines_t+1] = line end
		end
	end

	-- Sort custom action strings numerically and alphabetically by the first character in the custom action name
	-- 1. Split each code string in two so that the 2nd one starts with the custom action name, and construct a temp. table where each nested table contains two parts of the custom action string
	local tmp_t = {}
		for k,v in next, lines_t do
		tmp_t[k] = {}
		tmp_t[k][1] = v:match('(.+Custom: )'); tmp_t[k][2] = v:match('Custom: (.+)')
		end
	-- 2. Sort the nested tables by the 2nd key value
	table.sort(tmp_t, function(a,b) return a[2] < b[2] end)
	-- 3. Re-initialize the original table in a sorted order, joining the split stings back together
	local lines_t = {}
	for k,v in next, tmp_t do
	lines_t[k] = table.concat(v)
	end


-- Re-order the table by sections: Main, Media Explorer, MIDI Editor, MIDI Events list

-- Construct a temp. table in the pre-define order of the Action list section codes
local captures_t = {'0','100','32063','32060','32061'}
local tmp_t = {}
	for _, sect in ipairs(captures_t) do
		-- Bring custom actions from the same section together, moving their table values in a predefined order of section codes to a temporary table
		for _,str in next, lines_t do
		if str:match('%s('..sect..')%s\"') then tmp_t[#tmp_t+1] = str end
		end
	end


local lines_t = tmp_t
local tmp_t = nil

--if converting to individual Lua files
local resp = flags_t[3] and r.MB('There\'re '..tostring(#lines_t)..' custom actions to export.','INFO',1)
		if resp == 2 then return end


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


-- Concatenate a txt dump file extension and name
	if flags_t[1] and flags_t[2] then inset = 'Main & MIDI '
	elseif flags_t[1] then inset = 'Main '
	elseif flags_t[2] then inset = 'MIDI ' end
	if flags_t[1] and flags_t[2] and flags_t[5] then inset = 'Main & MIDI from Arrange '
	elseif flags_t[5] then inset = 'MIDI from Arrange ' end

local pref, f_name, ext = '', inset..tostring(#lines_t)..' custom actions LUA dump', '.txt' -- name pattern for individual LUA files is concatenated inside the MAIN LOOP since it depends on each custom action properties


-- Check if there's already a txt dump file in the target directory and ovewrite if confirmed by the user
	if flags_t[4] then
	local i = 0
		repeat f = r.EnumerateFiles(f_path..sep, i)
			if f == f_name..ext then break end
		i = i + 1
		until not f
		if f == f_name..ext then resp = r.MB('    The \\Scripts'..subdir_txt..'  folder already contains\n\n   a dump file for selected custom actions.\n\n    \"OK\" to overwrite     \"Cancel\" to abort.','PROMPT',1)
			if resp == 1 then
			local file = io.open(f_path..sep..f, 'w')
			file:write(''); file:close()
			else return end
		end
	end


-- MAIN LOOP

	for k,line in next, lines_t do
	local _, end_idx, cust_act_name = line:find(':%s*(.+)\"') -- get end index of cust. action name end in its code

	-- Concatenate a Lua file prefix, name and extension
	if flags_t[3] then -- if converting to individual Lua files
	f_name = cust_act_name:gsub('[\\/:*?\"<>|]', '') -- remove illegal characters \/:*?"<>|
	pref, ext = 'CA_', '.lua'
	local sect_code = line:match('%s(3206%d)%s\"')
		if sect_code == '32060' then
			if flags_t[5] then pref = 'MIDI Ed.from Arr_'..pref
			else pref = 'MIDI Ed_'..pref end
		elseif sect_code == '32061' then
			if flags_t[5] then pref = 'MIDI EvL.from Arr_'..pref
			else pref = 'MIDI EvL_'..pref end
		elseif sect_code == '32063' then pref = 'Media Ex_'..pref
		else pref = 'Main_'..pref end
		-- Truncate cust. action name if exceeds the OS limit for file name
		if #f_name > 255 then f_name = f_name:sub(1, 230) end -- accounting for additional file name elements 255 - 25
	end


	-- Separate custom action individual action IDs from its name: pos = name end index + quotation mark + space
	local _, _, actions = line:find('([_%d%a&%s%.%-]+)',end_idx+2)
	-- OR
	-- local actions = select(3,code:find('([_%d%a&%s%.%-]+)',end_idx+2))


	-- Save action IDs 1 by 1 to a table
	local actions_t = {}
		for w in actions:gmatch('([^%s]+)') do
			-- If nested custom action
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
		local sect_midi = line:match('%s(3206[01])%s\"')
		local sect_media_main = line:match('%s(32063)%s\"') or '0' -- 0 covers Main (alt rec) as well since it contains the same actions as the Main
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


	-- Concatenate comments and addiditional code
	local inset1, inset2, inset3 = '','',''
	local sect_code = line:match('%s(3206%d)%s\"')

		if flags_t[5] and (sect_code == '32060' or sect_code == '32061') then inset1, inset2, inset3 = '\n-- Import into the Main section of the Action list and run from Arrange.', 'r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor\n\nlocal hwnd = r.MIDIEditor_GetActive()\n\n','\n\nr.MIDIEditor_OnCommand(hwnd,2) -- File: Close window'
		else
			if sect_code == '32060' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Editor and/or MIDI Event list editor'; loc = 'inside '..sect_name -- loc is separate because it uses previously initialized variable
			elseif sect_code == '32061' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Event list editor and/or MIDI Editor'; loc = 'inside '..sect_name
			elseif sect_code == '32063' then sect_name = 'Media Explorer'; loc = 'inside '..sect_name
			else sect_name = 'Main / Main (alt recording)'; loc = 'Arrange'
			end
		inset1 = '\n-- Import into the '..sect_name..' section of the Action list and run from '..loc..'.'
		end


	-- Concatenate one LUA file code
	local output = '-- Converted from a custom action \"Custom: '..cust_act_name..'\"'..inset1..'\n\n\nlocal r = reaper\n\nreaper.PreventUIRefresh(1)\nreaper.Undo_BeginBlock();\n\n'..inset2..table.concat(code_t,'\n')..inset3..'\n\nreaper.Undo_EndBlock(\"'..cust_act_name..'\",-1)\nreaper.PreventUIRefresh(-1)\n\n\n'


	-- Write having selected mode
	local mode = flags_t[3] and 'w' or 'a' -- 'a' alone would suffice but this is a safety measure to avoid appending code to already exported LUA files with the same name, so LUA files are overwritten, TXT files are appended to during the loop, identically named TXT files are dealt with in the 'Check if there's already a txt dump file..' routine above
	local f = io.open(f_path..sep..pref..f_name..ext, mode)
	local result,_,_ = f:write(output)
	f:close()

	end -- end of MAIN LOOP


local inset = flags_t[3] and  '     Files have ' or  '       File has ' -- individual LUA files or dump txt file

local resp = r.MB(inset..'been created successfully\n\n      and placed in the \\Scripts'..subdir_txt..'  folder\n\n       of the REAPER program directory.\n\nWould you like to open the subfolder now?', "SUCCESS", 4)

	if resp == 6 then r.CF_ShellExecute(f_path) end





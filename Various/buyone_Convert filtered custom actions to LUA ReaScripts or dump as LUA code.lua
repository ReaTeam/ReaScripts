-- @description Convert filtered custom actions to LUA ReaScripts or dump as LUA code
-- @author BuyOne
-- @version 1.0

--[[

* ReaScript Name: BuyOne_Convert filtered custom actions to LUA ReaScripts or dump as LUA code.lua
* Description: in the name
* Instructions: included
* Author: Buy One
* Author URL: https://forum.cockos.com/member.php?u=134058
* Licence: WTFPL
* Forum Thread: 
* Version: 1.0
* REAPER: at least v5.962
* Extensions: SWS/S&M

]]

---------------- USER SETTINGS SECTION -----------------

-- To use a .ReaperKeyMap file for parsing insert its name with extension in between the quotes, e.g. myFile.ReaperKeyMap.
-- It MUST reside in the \KeMaps subdirectory of the REAPER program directory (aka resource path)
-- Read HELP for further details

local ReaperKeyMap = ""

------------- END OF USER SETTINGS SECTION ------------

local HELP = [=[

I. SEARCH SYNTAX

Search terms are words and phrases in all LATIN ALPHABET characters EXCEPT COMMA, delimited by semicolon ';'.

	E.g. one;two;3 and four;five;six before 7

These target words and phrases in custom action names.

The search is geared towards words in alphanumeric characters, is case insensitive and is exact by default. For semi-fuzzy search which will target also sequences longer than the given search term (including numeric and punctuation characters) up until the first space, use + as operator as the last character in the search term.

	E.g. act+ will include custom action names containing act+, acts, action, active, actual etc.

Semi-fuzzy search operator is only supported as the last character in the search term so phrases can only be extended by the length of their last word/number. On the flipside exact search for strings ending with + isn't possible.

Boolean 'and' search is realized with = operator. Use it between search terms (save for phrases) without spaces when you need several search terms to feature in a custom action name.

	E.g. one=2=three

Boolean 'or' search can be fashioned by combining regular syntax with boolean 'and'

	E.g. one;2;three;one=2=three

If search terms are provided the search for matches in custom action names is performed in sections of the Action list selected in the next field with flags. If the search field only contains the default text or is empty ALL custom actions will be exported according to the settings in the next field.


II. FLAGS SUMMARY

1 - To convert/dump Main and Media Explorer sections custom actions

2 - To convert/dump MIDI Editor and MIDI Event List Editor sections custom actions

3 - Convert custom actions of the specified types (1, 2 or both) to individual LUA scripts

4 - Dump custom actions of the specified types as a plain txt file containing their LUA code

5 - In syntax allowing to run MIDI Editor custom actions from Arrange

The flags are meant to be combined into a numeric code in ascending order.

All available combinations:

13 - Only Main and Media Explorer sections custom actions as individual LUA scripts
14 - Only Main and Media Explorer sections custom actions as plain txt dump file
23 - Only MIDI Editor and MIDI Event List Editor sections custom actions as individual LUA scripts
235 - Only MIDI Editor and MIDI Event List Editor sections custom actions as individual LUA scripts for use from Arrange
24 - Only MIDI Editor and MIDI Event List Editor sections custom actions as plain txt dump file
245 - Only MIDI Editor and MIDI Event List Editor sections custom actions as plain txt dump file with code for use from Arrange
123 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as individual LUA scripts
1235 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as individual LUA scripts, MIDI Editor/MIDI Event List Editor custom actions for use from Arrange
124 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as plain txt dump file
1245 - Both Main/Media Explorer and MIDI Editor/MIDI Event List Editor sections custom actions as plain txt dump file, MIDI Editor/MIDI Event List Editor custom actions for use from Arrange


III. SPECIFICS

Main flag includes Media Explorer custom actions. MIDI flag includes both MIDI Editor and MIDI Event list custom actions.

Custom actions are only parsed (unpacked) one nested custom action deep. Anything deeper is saved as a command ID, meaning the resulting script will malfunction if that custom action becomes anavilable. If all custom actions are converted their command IDs can be substituted manually with the corresponding code.

Other scripts and SWS cycle actions included in custom actions are also only saved as their command IDs so their subsequent removal will affect the script functionality.

Text dump files created earlier get overwritten after user confirmation, LUA files with the same name created earlier get overwritten tacitly by default.

Inline MIDI Editor custom actions are unfortunately not supported and won't be exported since there's to my knowledge no simple way to auto-convert them to a script.

The default location for export is Scripts sub-directory in the REAPER project directory unless another folder is specified. If the specified folder doesn't exist it will be created. The last specified folder name is remembered and will be displayed in the corresponding field of the dialogue on the next script run during REAPER session.

If search results aren't satisfactory, especially when your custom action names aren't in Latin script, you can use REAPER's Action list filter to find actions, export them as a .ReaperKeyMap file into the \KeyMap sub-directory of the REAPER project directory, specify its name in the USER SETTINGS of this script and run the latter without providing search terms. Alternatively you can dispose with the search, convert all custom actions from a specific section and then use a text processor filter facilities. Names of custom actions are exported with the code.

]=]

local r = reaper

-- API Check
	if not r.APIExists("CF_GetCommandText") then
	reaper.ShowConsoleMsg("Get the SWS/S&M extension at\nhttps://www.sws-extension.org/")
	reaper.MB("This script requires the SWS/S&M extension.\n\n If it's installed then it needs to be updated.","API CHECK", 0)
	return end


local script_name = select(2,r.get_action_context()):match('[^\\/]+%.%w+')

local err_mess = '           Malformed code.\n\n      If not sure, click Retry\n\nand type \'h\' in the upper field.'

::RETRY::

local search_terms_inset = r.GetExtState(script_name, 'search_field')
	if search_terms_inset == '' then search_terms_inset = 'if as is or empty then flags in the next field decide' end

local subdir = r.GetExtState(script_name, 'dir_field')
	if subdir == '' then subdir = 'existing or new; or leave as it is or empty' end

local legend = '3 - LUA scripts; 4 - 1 txt file; 5 - MIDI from Arrange'

local retval, input = r.GetUserInputs('Filter & convert or dump custom actions (type h in the 1st field for help)',4,'Search terms (delimited by ; ):,Type digits from legend below:,Specify folder under \\Scripts:,Legend: 1 - Main; 2 - MIDI;  -->,extrawidth=190', search_terms_inset..',,'..subdir..','..legend..'')

reaper.DeleteExtState(script_name, 'search_field', true) -- delete so that the same search terms aren't autofill the dialogue on next run

local search_terms, flags, subdir = input:match('([^,]*),([^,]*),([^,]*)') -- supports empty fields
	if search_terms == search_terms_inset then search_terms = '' end

	if retval == false then return end -- Cancel

	if search_terms:match('^[%sHh]-$') then r.ClearConsole() r.ShowConsoleMsg(HELP) goto RETRY end -- clear console to prevent adding up text on repeated submission of h

local flags = flags:match('.*')
	if flags == '' then return end -- if OK with empty field

	if (flags ~= '' and flags ~= flags:match('([1-5]*)')) or flags:len() < 2 or flags:len() > 4 then resp = r.MB(err_mess,'ERROR...'..flags,5)
		if resp == 4 then goto RETRY
		else return end
	end

r.SetExtState(select(2,r.get_action_context()):match('[^\\/]+%.%w+'), 'dir_field', subdir, false) -- will be either empty or user specified

-- Construct search terms table
local s_terms_t = {}
	if search_terms ~= '' then
		for w in search_terms:gmatch('([^;][%w%p%s][^;]*)') do --([^;][%w%p%+%-][^;]*)
		s_terms_t[#s_terms_t+1] = w
		end
	end

	-- Present user with their search terms for confirmation or correction
	if #s_terms_t ~= 0 then resp = r.MB('Your search terms are:\n\n'..table.concat(s_terms_t,'\n')..'\n\n\"NO\" to go back and emend.','PROMPT',3)
		if resp == 7 then r.SetExtState(script_name, 'search_field', table.concat(s_terms_t,';'), false) goto RETRY
		elseif resp == 2 then return end
	else resp = r.MB('Invalid symbols or language in the search.\n\n                 If not sure, click Retry\n\n          and type \'h\' in the upper field.','ERROR... '..search_terms,5)
		if resp == 4 then r.SetExtState(script_name, 'search_field', search_terms, false) goto RETRY
		else return end
	end


-- Construct user entered flags table, making sure that there're at least 1 or 2
local flags_t = {}
local flags_cntr = 0
local tbl_len_cntr = 0
	for w in flags:gmatch('(%d)') do
		if w == '1' or w == '2' then flags_cntr = flags_cntr + 1 end
	flags_t[tonumber(w)] = '' -- a dummy value
	tbl_len_cntr = tbl_len_cntr + 1
	end


-- Prevent inconsistent flags
	if flags_cntr == 0 or (flags_t[1] and flags_t[2] and tbl_len_cntr == 2) or (flags_t[1] and flags_t[5] and not flags_t[2]) or (flags_t[3] and flags_t[4]) then resp = reaper.MB(err_mess,'ERROR... '..flags,5)
		if resp == 4 then r.SetExtState(script_name, 'search_field', search_terms, false) goto RETRY
		else return end
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
		for f in io.popen('dir \"'..path..sep..'KeyMaps'..sep..ReaperKeyMap..'\" /b'):lines() do
			if f == ReaperKeyMap then break end
		end
		if not f then resp = r.MB('    '..ReaperKeyMap..' file\n\n            was\'t found.\n\n   Switching to '..targ_file,'WARNING',1)
			if resp == 2 then return end
		else targ_file = 'KeyMaps'..sep..ReaperKeyMap end
	end


-- Construct a table of individual custom actons strings
local lines_t = {}
	for line in io.lines(path..sep..targ_file) do
		if line:match('^ACT') then -- exclude categories besides actions
		local name = string.lower(line:match(':%s*(.+)\"')) -- custom action name in lower case
			if #s_terms_t ~= 0 then t = s_terms_t
			else t = {''} end -- a dummy table to allow the routine go through if no search terms were specified

			local function OR(src, str) -- for the sake of shorthand in evaluation below
				local pattern = str:match('+') and str..'[%w%p]*' or '%f[%w]('..str..')%f[%W]' -- semi-fuzzy with + opetator or exact search
				if pattern == '%f[%w]('..str..')%f[%W]' and str:match('=') then -- if boolean 'and' search with '=' operator
					for w in str:gmatch('%w*') do
						if w == src:match('%f[%w]('..w..')%f[%W]') then str = true
						else str = false break end
					end
				else str = src:match(pattern)
					if #s_terms_t == 0 then str = '' end -- when str is nil since no search terms were specified, not using nil as a condition because it's a valid result when search terms had been supplied but no matches were found
				end
				return str
			end -- func. OR(src, str) end

			for i = 1, #t do
			local v = t[i]:lower() -- search term in lower case
				if flags_t[1] and OR(name,v) and (line:match('%s(0)%s') or line:match('%s(32063)%s')) then lines_t[#lines_t+1] = line
				elseif flags_t[2] and OR(name,v) and line:match('%s(3206[01])%s') then lines_t[#lines_t+1] = line
				end
			end
		end
	end

	if #lines_t == 0 then r.MB('     N o  m a t c h e s.\n\n          ¯\\_(ツ)_/¯','INFO',0) return end

	-- Wade out duplicates stemming from the same custom action name satisfying several search terms, much simpler than preventing duplicates in the table construction loop above
	for k1,v1 in next, lines_t do
		for k2,v2 in next, lines_t do
			if v2 == v1 and k1 ~= k2 then table.remove(lines_t,k2) end
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

-- Construct a temp. table in the pre-defined order of the Action list section codes
local captures_t = {'0','32063','32060','32061'}
local tmp_t = {}
	for _, sect in ipairs(captures_t) do
		--reorder(lines_t, tmp_t, v)
		-- Bring custom actions from the same section together, moving their table values in a predefined order of section codes to a temporary table
		for _,str in next, lines_t do
		if str:match('%s('..sect..')%s') then tmp_t[#tmp_t+1] = str end
		end
	end

local lines_t = tmp_t
local tmp_t = nil

	--if converting to individual LUA files
local resp = flags_t[3] and r.MB('There\'re '..tostring(#lines_t)..' custom actions to export.','INFO',1)
		if resp == 2 then return end


-- Concatenate the path
	if subdir ~= '' and subdir ~= 'existing or new; or leave as it is or empty' then
	-- check if such directory already exists and if not, create
		for dir in io.popen('dir \"'..path..sep..'Scripts\" /ad'):lines() do
			if dir == subdir then exists = true break end
		end
		if not exists then os.execute('mkdir \"'..path..sep..'Scripts'..sep..subdir..'\"')
		end
	f_path = path..sep..'Scripts'..sep..subdir
	subdir_txt = '\\'..subdir -- for the prompt and concluding message in the end
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
		for f in io.popen('dir \"'..f_path..sep..'\" /b'):lines() do
			if f == f_name..ext then resp = r.MB('    The \\Scripts'..subdir_txt..'  folder already contains\n\n   a dump file for selected custom actions.\n\n    \"OK\" to overwrite     \"Cancel\" to abort.','PROMPT',1)
				if resp == 1 then
				local file = io.open(f_path..sep..f, 'w')
				file:write(''); file:close()
				else return end
			end
		end
	end


-- MAIN LOOP

	for k,line in next, lines_t do
	local _, end_idx, cust_act_name = line:find(':%s*(.+)\"') -- get end index of cust. action name end in its code

	-- Separate custom action individual action IDs from its name: pos = name end index + quotation mark + space
	local _, _, actions = line:find('([_%d%a&%s%.%-]+)',end_idx+2)
	-- OR
	-- local actions = select(3,code:find('([_%d%a&%s%.%-]+)',end_idx+2))

	-- Concatenate a LUA file prefix, name and extension
	if flags_t[3] then -- if converting to individual LUA files
	f_name = string.gsub(cust_act_name:gsub('[\\/:*?\"<>|]', ''), '([%s]+)', ' ') -- remove illegal characters \/:*?"<>|, then remove extra spaces left behind
	pref, ext = 'CA_', '.lua'
	local sect_code = line:match('%s(3206%d)%s')
		if sect_code == '32060' then
			if flags_t[5] then pref = 'MIDI Ed.from Arr_'..pref
			else pref = 'MIDI Ed_'..pref end
		elseif sect_code == '32061' then
			if flags_t[5] then pref = 'MIDI EvL.from Arr_'..pref
			else pref = 'MIDI EvL_'..pref end
		elseif sect_code == '32063' then pref = 'Media Ex_'..pref
		else pref = 'Main_'..pref end
		-- Truncate cust. action name if exceeds the OS limit for file name
		if cust_act_name:len() > 255 then
		local trunc_t = {}
			for w in cust_act_name:gmatch('(.)') do -- split name by characters
			trunc_t[#trunc_t+1] = w
			end
		f_name = ''
			for i = 1, 230 do -- reassemble accounting for additional file name elements 255 - 25
			f_name = f_name..trunc_t[i]
			end
		end
	end

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


	-- Concatenate actions code
	local code_t = {}
		for _,v in next, actions_t do
		local func = v:match('(_.+)') and 'r.NamedCommandLookup(\"'..v..'\")' or v	-- either SWS/S&M or native
		local id = r.NamedCommandLookup(v) -- works for native actions as well
		local sect_midi = line:match('%s(3206[01])%s')
		local sect_media_main = line:match('%s(32063)%s') or '0'
		--reaper.MB(v:match('%s(32063)%s'),"",0)
			if sect_midi then str = 'r.MIDIEditor_OnCommand(hwnd,'..func..') -- '..r.CF_GetCommandText(tonumber(sect_midi), id) -- thanks to cfillion https://forum.cockos.com/showthread.php?t=186732
			else str = 'r.Main_OnCommand('..func..',0) -- '..r.CF_GetCommandText(tonumber(sect_media_main), id) end
		code_t[#code_t+1] = str
		end


	-- Concatenate comments and addiditional code
	local inset1, inset2, inset3 = '','',''
	local sect_code = line:match('%s(3206%d)%s')

		if flags_t[5] and (sect_code == '32060' or sect_code == '32061') then inset1, inset2, inset3 = '\n-- Import into the Main section of the Action list and run from Arrange.', 'r.Main_OnCommand(40153, 0) -- Item: Open in built-in MIDI editor\n\nlocal hwnd = r.MIDIEditor_GetActive()\n\n','\n\nr.MIDIEditor_OnCommand(hwnd,2) -- File: Close window'
		else
			if sect_code == '32060' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Editor and/or MIDI Event list editor'; loc = 'inside '..sect_name -- loc is separate because it uses previously initialized variable
			elseif sect_code == '32061' then inset2, sect_name = 'local hwnd = r.MIDIEditor_GetActive()\n\n', 'MIDI Event list editor and/or MIDI Editor'; loc = 'inside '..sect_name
			elseif sect_code == '32063' then sect_name = 'Media Explorer'; loc = 'inside '..sect_name
			else sect_name = 'Main'; loc = 'Arrange'
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

local command = sep == '\\' and 'explorer ' or 'open ' -- Win or Mac

	if resp == 6 then os.execute(command..f_path) end







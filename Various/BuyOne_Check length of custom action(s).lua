-- @description Check length of custom action(s)
-- @author BuyOne
-- @website https://forum.cockos.com/member.php?u=134058
-- @version 1.0
-- @about Monitors specified or all custom actions length for exceeding the limit of 1023 bytes which results in their truncaction.

---------------- USER SETTINGS SECTION -----------------

-- Here you can define the time inverval for periodic checks
-- of the submitted custom action length. Specify time IN SECONDS between the quotes,
-- e.g. "60"
-- If empty the time interval defaults to 10 sec.

local FREQ = ""

------------- END OF USER SETTINGS SECTION ------------

local HELP = [[

A Quick Guide

To check length of an individual custom action fill out the first field with its command ID, click OK.
To check length of all custom actions simply click OK.
To monitor length of either individual or of all custom actions continuously, additionally fill out the last field with any symbol.

For details read on.

The script works in two modes, individual and global. Individual is for checking length of specific custom actions, global is for checking all custom actions for exessive length, optionally per Action list section.

'Custom action command ID' field

Meant for submitting a command ID of a custom action whose length must be checked or monitored. If the field is left containing the default comment or blank the script will work in global mode.


'Action list section' field

In individual mode specifying section might be needed since custom actions in different sections technically can have the same command ID. It's an extremely rare almost improbable case but in theory it's not impossible. If you're sure that no command ID is shared between different Action list sections, ignore this setting leaving the field blank or containing the default comment.
When running the script in global mode specifying Action list section will limit the scope of custom actions to check. Several Action list section codes from the list below can be entered. To have the script scan custom actions in all Action list sectons leave this field in its default state or blank.

Action list Section codes for field 2 of the dialogue:

Main section (including Main (alt recording)) = 1
MIDI Editor section = 2
MIDI Event list editor section = 3
Media Explorer section = 4
Inline MIDI Editor = 5

'Monitor constantly (any symbol)' field

If the field is left blank the script runs only once. To check custom action(s) length you'll have to explicitly run the script every time. In individual mode you always get feedback about the submitted custom action length. In global mode however if there're no custom actions whose length is over the limit then nothing happens, otherwise their details are displayed in the ReaScript console which pops up.

To make the script monitor custom actions length constantly in any mode, type any symbol in this field.

To be able to minitor length of several custom actions in parallel in individual mode, launch the script once again by double clicking on its entry in the Action list, using Run button in the Action list, pressing a button on a toolbar or using a keyboard shortcut and in the ReaScript task control dialogue click 'New instance' button.

It's not recommended to tick 'Remember my answer' checkbox in the ReaScript task control dialogue unless you're absolutely positive you'll never need to run the script in another mode. Undoing this will be laborious and you won't be able to easily terminate several running instances if this will be the mode you had saved.

The default time interval at which the script will periodically check custom action(s) length and display the result in the ReaScript console is 10 seconds. Another interval value can be specified in the User settings section above (at the beginning of the script). The console gets auto-cleared every 5 min.

Individual and global modes, though not explicitly indicated in the ReaScript console output to conserve space, can be distinguished by following features:
* Individual mode - time stamp is on the line above the custom action name and there's no 'Section' parameter.
* Global mode - time stamp is on the same line as the custom action name and there's 'Section' parameter in the output.

Worth being aware that although a custom action whose length exceeds the limit will be truncated in the Action list, in the actual reaper-kb.ini file its code will remain intact which technically allows restoration of the lost actions by their command IDs.

]]

local r = reaper

-- API Check
	if not r.APIExists("CF_GetCommandText") then r.ClearConsole()
	r.ShowConsoleMsg("Get the SWS/S&M extension at\nhttps://www.sws-extension.org/")
	r.MB("This script requires the SWS/S&M extension.\n\n If it's installed then it needs to be updated.","API CHECK", 0)
	return end

local script_name = select(2,r.get_action_context()):match('[^\\/]+%.%w+')

::RETRY::

local comm_id = r.GetExtState(script_name, 'comm_id')
	if comm_id == '' then comm_id = 'or leave as it is or blank if global mode' end
local section = r.GetExtState(script_name, 'section')
	if section == '' then section = 'or leave as it is or blank' end

local retval, input = r.GetUserInputs('Check custom action length (type \'h\' in the 1st field for help)',3,'Custom action command ID:,Acton list section:,Monitor constantly (any symbol):,extrawidth=130',''..comm_id..','..section..'')

r.DeleteExtState(script_name, 'comm_id', true)
r.DeleteExtState(script_name, 'section', true)

	if retval == false then return end

local comm_id, section, defer = input:match('([^,]*),([^,]*),([^,]*)')

local defer = defer:gsub('%s*','') -- if space tab entry

	if comm_id:match('or leave as it is or blank if global mode') then comm_id = ''
	elseif comm_id:match('^%s*[Hh]+%s*$') then r.ClearConsole() r.ShowConsoleMsg(HELP) goto RETRY -- clear console to prevent adding up text on repeated submission of h
	else comm_id = comm_id:gsub('[_%s]*','') -- remove space tab entry and unerscore if custom action ID
	end

	if section:match('or leave as it is or blank') then section = ''
	else section = section:gsub('%s*','') -- if space tab entry
	end

	if comm_id ~= '' and #comm_id < 32 then mess = 'Doesn\'t look like a custom action command ID.\n\n             Make sure it\'s provided in full.'
	elseif comm_id:match('(_?RS[%w]+)') then mess = 'The command ID belongs to a ReaScript.'
	else mess = nil end
	if mess then resp = r.MB(mess,'ERROR',5)
		if resp == 4 then r.SetExtState(script_name, 'section', section, false) goto RETRY
		else return end
	end


local sect_t = {}
	if section:match('[^%a%p%s]+') then -- if only digits, to allow selection of specific sections in global mode
		for w in section:gmatch('%d') do
			if w == '1' then w = '0'
			elseif w == '2' then w = '32060'
			elseif w == '3' then w = '32061'
			elseif w == '4' then w = '32063'
			elseif w == '5' then w = '32062'
			end
		sect_t[#sect_t+1] = w
		end
	elseif section ~= '' then resp = reaper.MB('Incorrect section selection. If unsure, click Retry\n\n         and type \'h\' in the 1st field for help.','ERROR... '..section,5)
		if resp == 4 then r.SetExtState(script_name, 'comm_id', comm_id, false) goto RETRY
		else return end
	end


-- Concatenate OS specific path separators
local path = r.GetResourcePath()
	if r.GetOS() == 'Win32' or r.GetOS() == 'Win64' then sep = '\\'
	else sep = '/' end -- OS evaluation is nicked from X-Raym
	-- OR
	-- sep = reaper.GetOS():match('Win') and '\\' or '/' -- nicked from amagalma

local targ_file = path..sep..'reaper-kb.ini'

local function Check_single_action()
	for line in io.lines(targ_file) do
		if #sect_t == 0 then cond = line:match('\"('..comm_id..')\"')
		else cond = line:match('%s('..sect_t[1]..'%s\"'..comm_id..'\")%s') end
		if sect_t[1] == '0' and not cond then cond = line:match('%s(100%s\"'..comm_id..'\")%s') end -- account for Main (alt recording) section
		if cond then code = line break end
	end
	return code
end


local function Check_all_actions()
	local t = {}
		for line in io.lines(targ_file) do
			if #sect_t == 0 then loop = #sect_t+1
			else loop = #sect_t end
			for i = 1, loop do
				if not sect_t[i] then cond = line:match('ACT')
				else cond = line:match('ACT %d* '..sect_t[i]..' \"') end
				if sect_t[i] == '0' and not cond then cond = line:match('ACT %d* 100 \"') end -- account for Main (alt recording) section

				if cond then cust_act_name = line:match(':%s*(.+)\"'); sect = line:match('ACT %d (%d*) \"')

					if sect == '0' then sect = 'Main' elseif sect == '100' then sect = 'Main (alt recording)' elseif sect == '32060' then sect = 'MIDI Editor' elseif sect == '32061' then sect = 'MIDI Event List' elseif sect == '32062' then sect = 'MIDI Inline Editor' elseif sect == '32063' then sect = 'Media Explorer' end

					if #line > 1023 then t[#t+1] = 'Custom action: "'..cust_act_name..'"\nSection: '..sect..'\nIn excess: '..tostring(#line - 1023)..' bytes\nComment: after REAPER restarts it will be truncated\n\n'
					end

				end -- cond condition end
			end -- 2nd (sect_t) loop end
		end -- 1st (targ_file) loop end
	return t
end


	if comm_id ~= '' then code = Check_single_action()
		if comm_id ~= '' and not code then
		local t = {[0] = '1',[32060] = '2',[32061] = '3',[32063] = '4',[32062] = '5'} -- back convert just to display in the error message
		local caption = #sect_t ~= 0 and t[tonumber(sect_t[1])] or ''
		local inset = #sect_t ~= 0 and '\n\n       in the specified Action list section.' or '.'
		local resp = r.MB('The submitted command ID wasn\'t found'..inset,'ERROR... '..caption,5)
			if resp == 4 then
				if section ~= '' then r.SetExtState(script_name, 'comm_id', comm_id, false) end
				goto RETRY
			else return end
		end
	else t = Check_all_actions() end


	if defer == '' then
		-- if monitoring single action(s)
		if code then
			if #code > 1023 then result, mess = 'EMERGENCY', '            The custom action length limit\n\n          has been exceeded by '..tostring(#code - 1023)..' bytes.\n\n   After REAPER restarts it will be truncated.\n\n   Its code in reaper-kb.ini file remains intact.'
			elseif #code == 1023 then result, mess = 'WARNING', '  The custom action length limit has been reached.\n\n    Addition of new actions will result in truncation\n\n      of the custom action after REAPER restarts.'
			else result, mess = 'LOOKS GOOD', '   The custom action length\n\n is '..tostring(1023 - #code)..' bytes short of the limit.' end
		r.MB(mess,result,0)
		-- if monitoring all actions
		elseif #t ~= 0 then r.ClearConsole() -- to only print to ReaSript console when defer is not selected
		r.ShowConsoleMsg(table.concat(t,'')) end
	end


function Displ_mess(code) -- to be used in Monitor_code() function when monitoring single action(s)
	local cust_act_name = code:match(':%s*(.+)\"')
	local mess = #code > 1023 and '('..os.date('%X')..')\nCustom action: "'..cust_act_name..'"\nStatus: EMERGENCY\nIn excess: '..tostring(#code - 1023)..' bytes\nComment: after REAPER restarts it will be truncated\n\n'
	or (#code == 1023 and '('..os.date('%X')..')\nCustom action: \"'..cust_act_name..'\"\nStatus: WARNING\nIn excess: NO, length limit reached\nComment: addition of new actions will result in truncation after REAPER restarts\n\n'
	or '('..os.date('%X')..')\nCustom action: \"'..cust_act_name..'\"\nStatus: LOOKS GOOD\nIn excess: NO, '..tostring(1023 - #code)..' bytes short of the limit\n\n')
	return mess
end


local function Monitor_code()
	local cur_time = os.time() -- thanks to schwa https://forums.cockos.com/showpost.php?p=1591089&postcount=14
	local FREQ = FREQ ~= '' and tonumber(FREQ) or 10
	if cur_time - time_stamp == FREQ then time_stamp = cur_time
		if comm_id ~= '' then code = Check_single_action(); mess = Displ_mess(code)
		else t = Check_all_actions()
		mess = #t ~= 0 and '('..os.date('%X')..') '..table.concat(t,'('..os.date('%X')..') ') or '('..os.date('%X')..')\n\n'
		end
		if select(2, math.modf((os.time() - clear_cons)/300)) == 0 then r.ClearConsole() end -- when the difference can be divided by 300 without remainder which means exactly 300 sec or 5 min
	r.ShowConsoleMsg(mess)
	end
	r.defer(Monitor_code)
end


	if defer ~= '' then
		-- To make the console message displayed immediately once defer has started
		if code then r.ShowConsoleMsg(Displ_mess(code))
		else displ = #t ~= 0 and '('..os.date('%X')..') '..table.concat(t,'('..os.date('%X')..') ') or '('..os.date('%X')..')\n\n'
		r.ClearConsole() r.ShowConsoleMsg(displ)
		end
	time_stamp, clear_cons = os.time(), os.time()
	Monitor_code()
	end




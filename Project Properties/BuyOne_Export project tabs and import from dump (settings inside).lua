--[[
ReaScript name: Export project tabs and import from dump
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: # Made exported tabs count reflect actual number
	   # Some other cosmetic changes
Provides: [main] .
Licence: WTFPL
REAPER: at least v5.962
About:
	Exports a list of open project tabs which then can be imported.  
	After the script had been written a realization came that the SWS extension
	already has this facility. Its advantage is that it has file browser which
	allows selecting location on the disk manually for file saving.  
	The advantage of the script is that it doesn't open blank tabs for invalid
	project entries plus allows temporarily preventing certain projects from
	loading. Well, i had to come up with something to justify the effort. 
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- Projects without project files aren't exported. To be exported they need
-- to be saved first.
-- Imported project tabs are opened after the last open tab.
-- The exported file name is 'REAPER Project tabs dump.txt'.
-- Entries can be deleted from the dump file if not all saved projects have
-- to be loaded. Gaps in numbering and empty lines are OK. Instead of being
-- deleted they can be commented out with semicolon e.g.
-- ;project1=C:\My projects\My project.RPP
-- Between double square quotes insert path to a folder where you wish
-- to have your project tab dumps exported, e.g. [[C:\My path\]]
-- If empty or malformed, REAPER resource path will be used.
-- To access it go to Options -> Show REAPER resource path in explorer/finder
-- or run this action from the Action list

local DUMP_PATH = [[]]
-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------


function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper

local sep = r.GetOS():match('Win') and '\\' or '/'
local resource_path = r.GetResourcePath()..sep
local DUMP_PATH = not DUMP_PATH:match('.+[\\/]%s*$') and DUMP_PATH:match('^%s*(.-)%s*$')..sep or DUMP_PATH:match('^%s*(.+'..sep..')%s*$') -- add last separator if none and remove leading/trailing spaces; when no custom path the variable ends up being equal to the separator



function Dir_Exists(path)

local _, mess = io.open(path:sub(1,-2)) -- to return 1 (valid) last separator must be removed
local result = mess:match('Permission denied') and 1 -- dir exists
or mess:match('No such file or directory') and 2
or mess:match('Invalid argument') and 3 -- -- leading and/or trailing spaces in the path

return result

end


function EXPORT(DUMP_PATH)

local _, scr_name, sect_ID, cmd_ID, _,_,_ = r.get_action_context()
local scr_name = scr_name:match('.+[\\/](.+)') -- with extension

local name = 'REAPER Project tabs dump.txt'
local dump_fn = DUMP_PATH and Dir_Exists(DUMP_PATH) == 1 and DUMP_PATH..name or resource_path..name

local i = 0
local content = ''
local valid_tabs_cnt = 0
	repeat
	local retval, projfn = r.EnumProjects(i)
	content = retval and #projfn > 0 and content..'proj'..i..'='..projfn..'\n' or content -- line break after the line, if before then the first entry won't be captured by string.match() in the 'import' loop below; only projects with file names are exported, that is to the exclusion of open but never saved ones
	valid_tabs_cnt = retval and #projfn > 0 and valid_tabs_cnt + 1 or valid_tabs_cnt
	i = i+1
	until not retval
	if #content == 0 then r.MB('No saved projects to export.','ERROR',0) return end

local extra_content = 'TO BE USED IN REAPER WITH THE SCRIPT:\n'..scr_name..'\n\n'..'Entries can be deleted if not all saved projects have to be loaded. Gaps in numbering and empty lines are OK.\nInstead of being deleted they can be commented out with semicolon at the very beginning, e.g. ;projX=project file path.\nTo change loading order the keys can be renumbered.\n\n'..string.rep('***',40)

local f = io.open(dump_fn,'w')
local write = f:write(extra_content..'\n\n\n'..content)
f:close()

local fallback_on_default_path = DUMP_PATH ~= sep and DUMP_PATH ~= dump_fn:sub(1,-#name-1)

return (r.file_exists(dump_fn) and '    A dump of '..valid_tabs_cnt..' project tabs\n\n    was created successfully'..(fallback_on_default_path and '\n\n    at REAPER resource path.' or '.')..'\n\nOnly projects with project files\n\n'..string.rep(' ',13)..'were exported.' or 'Dump creation failed.') -- to display message outside of function thereby preventing creation of a generic undo point

end


function IMPORT(DUMP_PATH)

local dir = DUMP_PATH and Dir_Exists(DUMP_PATH) == 1 and DUMP_PATH or resource_path

local retval, fn = r.GetUserFileNameForRead(dir, 'SELECT PROJECT TABS DUMP FILE', '.txt')
	if not retval then return end -- file browser closed with 'Cancel'

local f = io.open(fn,'r')
local content = f:read('*a')
f:close()

local i = 0
	repeat -- to get last project tab
	local retval, projfn = r.EnumProjects(i)
	i = retval and i+1 or i
	until not retval


-- find greatest key number to be used in dump import loop as a condition for exit instead of 'not projfn' which is meant to allow gaps in project keys numbering in case some saved projects are deleted from the list by the user
local greatest_key = {}

	for num in content:gmatch('[^;]proj(%d*)=') do -- semicolon signifies a commented out entry which are skipped
		if #num > 0 then greatest_key[#greatest_key+1] = tonumber(num) end
	end

	if #greatest_key == 0 then r.MB('No valid projects were found\n\n    in the selected dump file.','ERROR',0) return end


table.sort(greatest_key) -- the last value holds the greatest key number; the table length equals the number of loadable projects disregarding commented out keys

local act_proj = r.EnumProjects(-1) -- store proj open in the active tab, pointer only, to restore if all prjects fail to load
r.SelectProjectInstance(r.EnumProjects(i)) -- select last open project tab, pass retval of the last project index from the loop above

local i = 0
local inval_file_cnt = 0
	repeat -- import
	local projfn = content:match('[^;]proj'..i..'=(.-)\n') -- skipping commented out entries
		if projfn and r.file_exists(projfn) then
		r.Main_OnCommand(40859,0) -- New project tab
		r.Main_openProject(projfn)
		end
	inval_file_cnt = projfn and not r.file_exists(projfn) and inval_file_cnt+1 or inval_file_cnt
	i = i+1
	until i > greatest_key[#greatest_key] -- after sorting, last table field holds the greatest value; after all keys have been traversed the iterator will be greater than the greatest key


local restore_tab = inval_file_cnt == #greatest_key and r.SelectProjectInstance(act_proj) -- reopen the tab which had been originally open (but was switched to the last one for dump loading) in case invalid project count equals total project count disregarding commented out projects an so no project was loaded

return inval_file_cnt > 0 and inval_file_cnt..'  projects out of '..#greatest_key..' failed to load\n\n             due to invalid link.'

end


r.PreventUIRefresh(1)

local resp = r.MB('\"YES\" — to export project tabs.\n\nWill overwrite existing dump file if any.\nTo keep it, click \"NO\", access it and create\na backup copy named differently or rename it.\nThen run again and click \"YES\".\n\n"NO\" — to import project tabs.\n\n','CHOOSE ACTION', 3)
	if resp == 6 then mess = EXPORT(DUMP_PATH)
	elseif resp == 7 then mess = IMPORT(DUMP_PATH)
	end

r.PreventUIRefresh(-1)

	-- taken outside of function and after 'prevent refresh' to prevent undo point creation and to display the message after the last project has loaded
	if mess then r.MB(mess,'ERROR',0) return r.defer(function() end) end




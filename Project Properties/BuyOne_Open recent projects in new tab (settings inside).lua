--[[
ReaScript name: Open recent projects in new tab
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.2
Changelog: #Added support for display of project title instead 
	   of project path or file name, if set in Project settings -> Notes
Licence: WTFPL
REAPER: at least v5.962
About: 
	An alternative to REAPER's native 'Recent projects menu' capable 
	of opening recent projects in a new tab, desisgned before a
	native option was added in build 6.43:   
	
	+ Projects: hold shift to open recent project in new project tab   
	
	Can still be used if holding shift isn't viable for some reason.
	
	Also allows opening in another tab an instance of an already open
	project which the native option doesn't allow.  
	https://forum.cockos.com/showthread.php?t=265300
	
	However unlike in the native menu, if project file or path are 
	no longer valid, its entry cannot be cleared from the script menu 
	and will be listed as long as it's present in reaper.ini file.   
	To compensate for this a setting VALID_PROJECTS_ONLY has been added
	to the USER SETTINGS

]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To enable a setting insert any QWERTY alphanumeric character between
-- the quotation marks.

-- Enable to have the menu only display project file names instead of paths;
-- the feature is supported natively since build 6.57;
-- the max number of projects in the recent project list still depends 
-- on the setting at:  
-- Preferences -> General -> Maximum projects in recent project list:

PROJECT_NAMES_ONLY = ""

-- Enable to make the list display titles of projects set at:
-- File -> Project settings... -> Notes -> Title;
-- only relevant if PROJECT_NAMES_ONLY setting is enabled;
-- if a project has no title its file name is displayed instead;
-- the feature is supported natively since build 6.57.

PROJECT_TITLES = ""


-- Enable to have the menu only list valid (loadable) projects
-- since the script doesn't allow removing invalid entries from the list
-- as long as they're present in reaper.ini file.

VALID_PROJECTS_ONLY = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper


function validate_sett(sett) -- can be either a non-empty string or a number
return type(sett) == 'string' and #sett:gsub(' ','') > 0 or type(sett) == 'number'
end

function get_proj_title(projpath)

	local function get_from_file(projpath)
	local f = io.open(projpath,'r')
	local cont = f:read('a*')
	f:close()
	return cont:match('TITLE "?(.-)"?\n') -- quotation marks only if there're spaces in the title
	end
	
local proj_title, retval

local i = 0
	repeat
	local ret, projfn = r.EnumProjects(i) -- find if the project is open in a tab
		if projfn == projpath then retval = ret break end	
	i = i+1
	until not ret
	if retval then -- the project is open in a tab
		if tonumber(r.GetAppVersion():match('(.+)/')) >= 6.43 then -- if can be retrieved via API regardless of being saved to the project file // API for getting title was added in 6.43
		retval, proj_title = r.GetSetProjectInfo_String(retval, 'PROJECT_TITLE', '', false) -- is_set false // retval is a proj pointer, not an index
		else -- retrieve from file which in theory may be different from the latest title in case the project hasn't been saved
		proj_title = get_from_file(projpath)
		end
	else
	proj_title = get_from_file(projpath)
	end
	
	return proj_title and proj_title:match('[%w]+') and proj_title -- if there're any alphanumeric chars // proj_title can be nil when extracted from .RPP file because without the title there's no TITLE key, if returned by the API function it's an empty string, when getting, retval is useless because it's always true unless the attribute, i.e. 'PROJECT_TITLE', is an empty string or invalid 
	
end


VALID_PROJECTS_ONLY = validate_sett(VALID_PROJECTS_ONLY)

-- collect recent project paths
local t = {}
	for line in io.lines(r.get_ini_file()) do
		if line == '[Recent]' then found = true
		elseif found and line:match('%[.-%]') and line ~= '[Recent]' then -- next section
		break end
		if found and line ~= '[Recent]' then -- collect paths excluding the section name
		local projpath = line:gsub('recent%d+=','') -- or line:match('=(.+)') // strip away the key
			if VALID_PROJECTS_ONLY and r.file_exists(projpath) then
			t[#t+1] = projpath
			elseif not VALID_PROJECTS_ONLY then
			t[#t+1] = projpath
			end
		end
	end


PROJECT_NAMES_ONLY = validate_sett(PROJECT_NAMES_ONLY)
PROJECT_TITLES = validate_sett(PROJECT_TITLES)

local _, projfn = r.EnumProjects(-1) -- OR r.GetProjectPath('')..r.GetProjectPath(''):match('[\\/]')..r.GetProjectName(0,'')


local recent_proj_t = {}
local menu_t = {}
	for i = #t,1,-1 do -- in reaper.ini recent projects are listed in descending order, thus table should be reordered
	recent_proj_t[#recent_proj_t+1] = t[i] == projfn and '!'..t[i] or t[i] -- adding checkmark to the menu item of the currently open project
		if PROJECT_NAMES_ONLY then
		local name = PROJECT_TITLES and get_proj_title(t[i]) or t[i]:match('.+[\\/](.-)%.[RrPp]+') -- if not title, strip away path and extension
		menu_t[#menu_t+1] = t[i] == projfn and '!'..name or name -- adding checkmark to the menu item of the currently open project
		end
	end

	
local menu_t = #menu_t == 0 and recent_proj_t or menu_t -- if PROJECT_NAMES_ONLY is not ON, display full paths in the menu


gfx.init('', 1, 1)

gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y

local output = gfx.showmenu(table.concat(menu_t, '|'))

local projfn = output > 0 and recent_proj_t[output]:match('!?(.+)') -- remove ! signifying checkmark of an open project in case such project is selected for loading

	if projfn and r.file_exists(projfn) then
	r.Main_OnCommand(40859,0) -- New project tab
	r.Main_openProject(projfn)
	elseif projfn then r.MB('The file is not available at the stored path\n\n'..recent_proj_t[output],'ERROR',0)
	return r.defer(function() do return end end) end -- prevent generic undo point in case the above error message is displayed

gfx.quit()





--[[
ReaScript name: Open recent projects in new tab
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.1
Changelog: #Fixed bug preventing loading in a new tab an already open project
		   #Improved undo point handling when error
		   #Added a setting to only list valid projects
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

-- Enable to have the menu only list valid (loadable) projects
VALID_PROJECTS_ONLY = ""

-- Enable to have the menu only display project names without the path
-- and the extension;
-- the max number of projects in the recent project list still depends on
-- the setting at Preferences -> General -> Maximum projects in recent project list:
-- the script doesn't allow removing invalid entries from the list.

PROJECT_NAMES_ONLY = ""

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


-- in reaper.ini recent projects are listed in descending order, thus table should be reordered

PROJECT_NAMES_ONLY = validate_sett(PROJECT_NAMES_ONLY)

local _, projfn = r.EnumProjects(-1) -- OR r.GetProjectPath('')..r.GetProjectPath(''):match('[\\/]')..r.GetProjectName(0,'')

local recent_proj_t = {}
local menu_t = {}
	for i = #t,1,-1 do
	recent_proj_t[#recent_proj_t+1] = t[i] == projfn and '!'..t[i] or t[i] -- adding checkmark to the menu item of the currently open project
		if PROJECT_NAMES_ONLY then
		local name = t[i]:match('.+[\\/](.-)%.[RrPp]+') -- strip away path and extension
		menu_t[#menu_t+1] = t[i] == projfn and '!'..name or name -- adding checkmark to the menu item of the currently open project
		end
	end

local menu_t = #menu_t == 0 and recent_proj_t or menu_t -- if PROJECT_NAMES_ONLY is not ON, display full paths in the menu


Msg(#recent_proj_t)

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





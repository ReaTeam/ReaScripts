--[[
ReaScript name: Open recent projects in new tab
Author: BuyOne
Website: https://forum.cockos.com/member.php?u=134058
Version: 1.0
Changelog: Initial release
Provides: [main] .
Licence: WTFPL
REAPER: at least v5.962
About: 
	An alternative to REAPER's native 'Recent projects menu' capable 
	of opening recent projects in a new tab, which in my opinion should 
	be a native feature and has been requested a couple of times:
	https://forum.cockos.com/showthread.php?t=113259 (2012)
	https://forum.cockos.com/showthread.php?t=249615 (2021)
	
]]
-----------------------------------------------------------------------------
------------------------------ USER SETTINGS --------------------------------
-----------------------------------------------------------------------------
-- To have the menu display only project names without the path 
-- and the extension, insert any alphanumeric characted between 
-- the quotation marks.
-- The max number of projects in the recent project list still depends on 
-- the setting at Preferences -> General -> Maximum projects in recent project list:
-- The script doesn't allow removing invalid entries from the list.

PROJECT_NAMES_ONLY = ""

-----------------------------------------------------------------------------
-------------------------- END OF USER SETTINGS -----------------------------
-----------------------------------------------------------------------------

function Msg(param, cap) -- caption second or none
local cap = cap and type(cap) == 'string' and #cap > 0 and cap..' = ' or ''
reaper.ShowConsoleMsg(cap..tostring(param)..'\n')
end


local r = reaper

-- collect recent project paths
local t = {}
local found
	for line in io.lines(r.get_ini_file()) do
		if line == '[Recent]' then found = true 
		elseif -- next section
		found and line:match('%[.-%]') and line ~= '[Recent]' then break end 
		if found and line ~= '[Recent]' then -- collect paths excluding the section name
		t[#t+1] = line:gsub('recent%d+=','') end -- or line:match('=(.+)') // strip away the key		
	end
	
-- in reaper.ini recent projects are listed in descending order, thus table should be reordered

local _, projfn = r.EnumProjects(-1) -- OR r.GetProjectPath('')..r.GetProjectPath(''):match('[\\/]')..r.GetProjectName(0,'')
local PROJECT_NAMES_ONLY = type(PROJECT_NAMES_ONLY) == 'string' and #PROJECT_NAMES_ONLY:gsub(' ','') > 0 or type(PROJECT_NAMES_ONLY) == 'number' -- can be either a non-empty string or a number

local recent_proj_t = {}
local menu_t = {}
	for i = #t,1,-1 do
	recent_proj_t[#recent_proj_t+1] = t[i] == projfn and '!'..t[i] or t[i] -- adding checkmark to the path of the currently open project
		if PROJECT_NAMES_ONLY then
		local name = t[i]:match('.+[\\/](.-)%.[RrPp]+') -- strip away path and extension
		menu_t[#menu_t+1] = t[i] == projfn and '!'..name or name -- adding checkmark to the name of the currently open project
		end
	end

local menu_t = #menu_t == 0 and recent_proj_t or menu_t -- if PROJECT_NAMES_ONLY is not ON, display full paths in the menu


gfx.init('', 1, 1)

gfx.x = gfx.mouse_x
gfx.y = gfx.mouse_y

local output = gfx.showmenu(table.concat(menu_t, '|'))

	if output > 0 and r.file_exists(recent_proj_t[output]) then 
	r.Main_OnCommand(40859,0) -- New project tab
	r.Main_openProject(recent_proj_t[output])
	elseif output > 0 then r.MB('The file is not available at the stored path\n\n'..recent_proj_t[output],'ERROR',0)
	return r.defer(function() end) end -- prevent generic undo point in case the above error message is displayed
	
gfx.quit()
	
	
	
	
	

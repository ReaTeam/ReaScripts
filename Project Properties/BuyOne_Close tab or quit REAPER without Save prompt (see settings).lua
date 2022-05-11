--[[
ReaScript Name: Close tab or quit REAPER without Save prompt
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
About: 	Use instead of the native actions whenever you like to exit  
	without dealing with the project save prompt.  
		
	By default if there're more than 1 project tab open - only 
	closes current tab without the save prompt. If only 1 project 
	tab is open - quits REAPER without the save prompt.  
	To be able to close multiple tabs without the save prompt 
	enable MULTITAB in the USER SETTINGS.

	The script will only work if DUMMY_PROJECT_PATH setting in 
	USER SETTINGS is configured.
]]

-----------------------------------------------------------------
------------------- U S E R  S E T T I N G S --------------------
-----------------------------------------------------------------

-- Dummy project path must be a full path to a valid .RPP file, 
-- such as an empty project, which is preferable, e.g.
-- C:\REAPER\ProjectTemplates\my_dummy_project.RPP
-- it can point at whatever location on your hard drive as long 
-- as it's valid;
-- insert between the double square brackets.

DUMMY_PROJECT_PATH = [[]]


-- To enable the following settings, insert any alphanumeric QWERTY
-- character between the quotation marks;
-- if MULTITAB is enabled, closes all tabs but doesn't quit REAPER,
-- so you end up with an empty project;
-- if MULTITAB_QUIT is enabled while MULTITAB is ON, quits REAPER
-- after closing all tabs.

MULTITAB = ""
MULTITAB_QUIT = "" -- only relevant when MULTITAB is enabled

-----------------------------------------------------------------
-------------- E N D  O F  U S E R  S E T T I N G S -------------
-----------------------------------------------------------------

	if not reaper.file_exists(DUMMY_PROJECT_PATH) then
	local x, y = reaper.GetMousePosition()
	reaper.TrackCtl_SetToolTip(('\n\n        invalid path \n\n  to the dummy project  \n\n '):upper():gsub('.','%0 '), x, y, true) -- topmost true
	return reaper.defer(function() do return end end) end


function CLOSE()
reaper.Main_openProject('noprompt:'..DUMMY_PROJECT_PATH)
reaper.Main_OnCommand(40860, 0) -- Close current project tab
end

MULTITAB = #MULTITAB:gsub(' ','') > 0
MULTITAB_QUIT = #MULTITAB_QUIT:gsub(' ','') > 0

	if MULTITAB then
	
	-- Get proj count
	local proj_cnt = 0
		repeat
		local proj = reaper.EnumProjects(proj_cnt)
		proj_cnt = proj_cnt+1
		until not proj

		for i = 1, proj_cnt-1 do -- -1 since the proj_cnt var ends up greater by 1 than the actual proj count due to being incremented before the loop is exited
		CLOSE()
		end

		if MULTITAB_QUIT then
		reaper.Main_OnCommand(40004, 0) -- File: Quit REAPER
		end

	else

	local is_single_tab = not reaper.EnumProjects(1)

	CLOSE()

		if is_single_tab -- no 2nd project // meaning only one tab is open
		then
		reaper.Main_OnCommand(40004, 0) -- File: Quit REAPER
		end

	end

	
	
	

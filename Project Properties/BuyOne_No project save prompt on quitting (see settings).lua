--[[
ReaScript Name: No project save prompt on quitting
Author: BuyOne
Version: 1.0
Changelog: Initial release
Author URL: https://forum.cockos.com/member.php?u=134058
Licence: WTFPL
REAPER: at least v5.962
About: 	If there're more than 1 project tab open - only closes current tab 
		    without save prompt. If only 1 project tab is open - quits REAPER 
		    without save prompt.   
		    The script will only work if DUMMY_PROJECT_PATH setting in 
		    USER SETTINGS is configured.
]]

-----------------------------------------------------------------
-------------------- U S E R  S E T T I N G S -------------------
-----------------------------------------------------------------

-- Dummy project path must point at a valid .RPP file, e.g. empty 
-- project, which is preferable;
-- insert between the double square brackets.

DUMMY_PROJECT_PATH = [[C:\Users\ME\Desktop\Chords\dummy project.RPP]] 

-----------------------------------------------------------------
--------------- E N D  O F  U S E R  S E T T I N G S ------------
-----------------------------------------------------------------

	if not reaper.file_exists(DUMMY_PROJECT_PATH) then 
	local x, y = reaper.GetMousePosition()
	reaper.TrackCtl_SetToolTip(('\n\n        invalid path \n\n  to the dummy project  \n\n '):upper():gsub('.','%0 '), x, y, true) -- topmost true
	return reaper.defer(function() do return end end) end

local is_single_tab = not reaper.EnumProjects(1)
	
reaper.Main_openProject('noprompt:'..DUMMY_PROJECT_PATH)
reaper.Main_OnCommand(40860, 0) -- Close current project tab

	if is_single_tab -- no 2nd project // meaning only one tab is open
	then
	reaper.Main_OnCommand(40004, 0) -- File: Quit REAPER
	end
	
	
	

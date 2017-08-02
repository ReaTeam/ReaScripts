--[[
Description: Open Reaper folder
Version: 1.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Opens the folder containing Reaper's executable file.
Extensions:
Provides:
--]]

-- Licensed under the GNU GPL v3

local path = reaper.GetExePath()
local OS = reaper.GetOS()

if OS == "OSX32" or OS == "OSX64" then
    os.execute('open "" "' .. path .. '"')
else
    os.execute('start "" "' .. path .. '"')
end
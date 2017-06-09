--[[
Description: Run Lua script in debug mode
Version: 1.1.1
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Name change for consistency
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Lets users open a compatible .lua script in debug mode, to assist
	in diagnosing errors, crashes, etc.
	
	Script developers: Your script just needs to check if the global
	variable 'debug_mode' is true:
	
	(near the top of your script)
	if debug_mode then
		...set appropriate debug flags, etc...
	end
	
Extensions:
--]]

-- Licensed under the GNU GPL v3

debug_mode = true
local ret, debug_file = reaper.GetUserFileNameForRead("", "Choose a ReaScript", ".lua")
if not ret or not debug_file then return 0 end
local debug_name = string.match(debug_file, "[\\/]([^\\/]*)$")
reaper.SetExtState("Lokasenna_Debug mode", "last", debug_file, true)
reaper.ShowConsoleMsg("Running '"..tostring(debug_name).."' in debug mode...\n")
dofile(debug_file)

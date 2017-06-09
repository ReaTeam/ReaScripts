--[[
Description: Run last Lua script in debug mode
Version: 1.1.1
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
	Name change for consistency
Links:
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About: 
	Gets the last script that was run via 'Run Lua script in debug mode'
	and attempts to open it in debug mode again; a replacement for Reaper's
	native action 'ReaScript: Run last ReaScript (EEL or Lua)', since
	scripts can't get that filename from REAPER.ini directly.	
	
	Script developers: Your script just needs to check if the global
	variable 'debug_mode' is true:
	
	(near the top of your script)
	if debug_mode then
		...set appropriate debug flags, etc...
	end
	
Extensions: SWS/S&M 2.8.3
--]]

-- Licensed under the GNU GPL v3

local debug_file = reaper.GetExtState("Lokasenna_Debug mode", "last")

if not debug_file or debug_file == "" then 
	reaper.ShowMessageBox( "Open a script with 'Lokasenna_Run Lua script in debug mode.lua' first.", "No script found", 0)
	return 0
elseif string.match(debug_file, "in debug mode") then 
	return 0
end

debug_mode = true
local debug_name = string.match(debug_file, "[\\/]([^\\/]*)$")
reaper.ShowConsoleMsg("Running '"..tostring(debug_name).."' in debug mode...\n")
dofile(debug_file)

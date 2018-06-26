--[[
Description: Lokasenna_GUI v2
Version: 2.9.0
Author: Lokasenna
Donation: https://paypal.me/Lokasenna
Changelog:
    First stable release
Links:
    Forum Thread https://forum.cockos.com/showthread.php?t=177772
	Lokasenna's Website http://forum.cockos.com/member.php?u=10417
About:
    Provides a framework allowing Lua scripts to use a graphical interface, since Reaper
    has no ability to do so natively.
    
    IMPORTANT: After installing this package, you must tell Reaper
    where to find the library.
    
    - In the Action List: 
      "ReaScript: Run reaScript (EEL, lua, or python)..."
    - Find the script folder in Reaper's resource path. On Windows:
      REAPER\Scripts\ReaTeam Scripts\Development\Lokasenna_GUI v2\Library
    - Run "Set Lokasenna_GUI v2 library path.lua"
    - Done!
Provides:
    [nomain] Lokasenna_GUI v2/Library/*.*
    [nomain] Lokasenna_GUI v2/Library/**/*.*
Metapackage: true
    
--]]

-- Licensed under the GNU GPL v3
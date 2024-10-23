--[[
    Description: Refresh current theme
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Reloads the current Reaper theme

    Donation: https://www.paypal.me/Lokasenna
]]--

local themePath = reaper.GetLastColorThemeFile()
reaper.OpenColorThemeFile(themePath)
reaper.UpdateArrange()
reaper.UpdateTimeline()

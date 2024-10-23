--[[
ReaScript name: js_Panic - Stop all keystroke intercepts by scripts.lua
Version: 1.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
]]

--[[
  Changelog:
  * v1.00 (2019-05-05)
    + Initial release.
]]

for i = 1, 256 do
    OK = reaper.JS_VKeys_Intercept(-1, -1)
    if OK == 0 then break end
end
if not (OK == 0) then reaper.MB("Some strange error occured, and the intercepts could not be stopped...", "ERROR", 0) end

--[[
ReaScript name: js_Mouse editing - Draw basic LFO curves in real time.lua
Version: 4.00
Author: juliansader
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
]] 

--[[
  Changelog:
  * v4.00 (2019-02-09)
    + Deprecation notice.
]]

reaper.MB([[This script is deprecated and has been replaced by "js_Mouse editing - Draw LFO".
  
Similar to the other new Mouse editing scripts, the new Draw LFO script can detect mouse input itself, 
and therefore no longer requires a helper script for mousewheel control.
  
Other mouse controls:
  * Left-click terminates the script.
  * Right-click toggles chasing start values.
  * As before, mousewheel scrolls through the various LFO shapes.
  
]], "Deprecation notice", 0)

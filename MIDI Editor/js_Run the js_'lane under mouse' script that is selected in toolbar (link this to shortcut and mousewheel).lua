--[[
ReaScript name: js_Run the js_'lane under mouse' script that is selected in toolbar (link this to shortcut and mousewheel).lua
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

reaper.MB([[This script is deprecated, and has been replaced by "js_Mouse editing - Run script that is armed in toolbar".

All scripts that are controlled by the mouse have been renamed as the "js_Mouse editing" scripts, 
and no longer require any helper script for mousewheel control, since they can detect mouse input themselves.
]], "Deprecation notice", 0)

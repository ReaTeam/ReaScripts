--[[
ReaScript name: js_Compress or expand selected CC or velocity events using mousewheel.lua
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

reaper.MB([[This script has been replaced by "js_Mouse editing - Stretch and Compress".

The new "Mouse editing" scripts require the js_ReaScriptAPI extension, and offer several improvements, including:

* No helper scripts required for mousewheel control: 
The new scripts can detect mouse input themselves.

* Fewer scripts and fewer shortcuts: 
Since the new scripts can detect mouse input, each script can be multi-functional, and middle-click and right-click are used to switch between different modes. 
For example, the single new script, "js_Mouse editing - Stretch and Compress", combines and replaces both the "Stretch" and "Compress" scripts.

* New editing features: 
The compression/expansion curve is now adjustable:
  ~ Middle-click switches between a sine curve and a linear/power curve.
  ~ Right-click switches between 1-sided and symmetrical compression.
  ~ Mousewheel adjusts the steepness of the curve.
  
Remember to read the description and instructions for each script!  
(The first page of the "MIDI editor tools" forum thread also provides a general overview of the new scripts.)
]], "Deprecation notice", 0)

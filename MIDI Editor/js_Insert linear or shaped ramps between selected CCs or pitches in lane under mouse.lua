--[[
ReaScript name: js_Insert linear or shaped ramps between selected CCs or pitches in lane under mouse.lua
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

reaper.MB([[This script has been replaced by "js_Mouse editing - Connect nodes".
  
The new "Mouse editing" scripts require the js_ReaScriptAPI extension, and offer several improvements:

* No helper scripts required for mousewheel control: 
The new scripts can detect mouse input themselves.

* Fewer scripts and fewer shortcuts: 
Since the new scripts can detect mouse input, each script can be multi-functional, 
and middle-click and right-click are used to switch between different modes. 
For example, a single new script, "js_Mouse editing - Draw ramp", combines and replaces four old scripts: 
"Draw linear or curved ramps in real time", "Draw linear or curved ramps in real time, chasing start values", "Draw sine curve in real time" and "Draw sine curve in real time, chasing start values".

* New editing features:
1) The "Connect nodes" script offers a new mode, BÉZIER, in which the script tries to find the smoothest curve to connect the nodes.
2) The mousewheel can be used to change the MIDI channel of the inserted CCs.
3) If the MIDI editor is set to "Edit only the active MIDI channel", the script will only select nodes that are in the active channel.
  
These channel features are very useful for keeping the ramps and the nodes in separate channels, so that the nodes can easily be re-selected and edited.
]], "Deprecation notice", 0)

--[[
ReaScript name: js_Options - Toggle skip redundant events when inserting CCs.lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
About:
  # Description
  
  When inserting CCs via scripts such as 
    * js_Draw linear or curved ramps in real time
    * js_Insert linear or shaped ramps between selected CCs or pitches in lane under mouse
    * js_LFO Tool
  the user can choose whether redundant events (i.e. events with the same value as the preceding event)
  should be skipped.
  
  This script toggles the behavior of the above-mentioned scripts. 
  
  (In previous versions of these scripts, the user had to edit the script file's USER AREA 
  in order to change the behavior of the scripts.  This is no longer necessary.)
]]
 
--[[
  Changelog:
  * v0.90 (2018-04-21)
    + Initial beta release
]]

-- "Trick" to prevent creation of Undo point
reaper.defer(function() end)

-- Get current state, and toggle (anything other than "false" gets toggled to 0)
if reaper.GetExtState("js_Mouse actions", "skipRedundantCCs") == "false" then 
    newStateString, newStateInteger = "true", 1 
else
    newStateString, newStateInteger = "false", 0
end

-- Toggle state shown in Actions list
_, _, sectionID, commandID, _, _, _ = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, commandID, newStateInteger)

-- Toggle toolbar button, if any
reaper.RefreshToolbar2(sectionID, commandID)

-- Update ExtState for other scripts to read
reaper.SetExtState("js_Mouse actions", "skipRedundantCCs", newStateString, true) -- Remember state for next session
reaper.SetExtState("LFO generator", "skipRedundantCCs", newStateString, true) -- Also update LFO Tool

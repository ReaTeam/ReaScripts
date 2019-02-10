--[[
ReaScript name: js_Mouse editing - Run script that is armed in toolbar.lua
Version: 2.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script allows multiple "Mouse editing" scripts to be run from a single (keyboard or mousewheel) shortcut.
  
  The shortcut that is linked to this script will toggle start/stop any "Mouse editing" script that is armed in the toolbar.
  
  
  TOOLBAR ARMING
   
  Since the functioning of "Mouse editing" scripts depends on initial mouse position 
  (similar to REAPER's own mouse modifier actions, or actions such as "Insert note at mouse cursor"), 
  these scripts cannot be run by mouse-clicking a toolbar button or the Actions list.  
  
  This problem is solved by "arming" toolbar buttons for delayed execution after moving the mouse into position:
    
    
    REAPER's NATIVE TOOLBAR ARMING:
    
    REAPER natively provides a "toolbar arming" feature: right-click a toolbar button to arm its linked action
    (the button will light up with an alternative color), and then left-click to run the action 
    after moving the mouse into position over the piano roll.
    
    There are two niggles with this feature, though: 
    
    1) Left-drag is very sensitive: If the mouse is even slightly moved while left-clicking,
        the left-drag mouse modifier action will be run instead of the armed toolbar action; 

    2) Multiple clicks: The user has to right-click the toolbar (or press Esc) to disarm the toolbar and use left-click normally again,
        then right-click the toolbar again to use the script. 
        
        
    ALTERNATIVE TOOLBAR ARMING:
    
    The "Mouse editing" scripts therefore offer an alternative "toolbar arming" solution:  
    
    1) Link the "js_Mouse editing - Run the script that is armed in toolbar" script to a keyboard or mousewheel (or both) shortcut.
    
    2) Link the individual Mouse editing scripts (such as "Draw ramp", "Warp", etc) to toolbar buttons. (No need to link them each to a shortcut.)
        
      (In other words, the Run script is linked to a shortcut, while the individual Mouse editing scripts are linked to toolbar buttons.)
    
    3) If the mouse is positioned over a toolbar or over the Actions list when the Mouse editing script starts 
        (or, actually, anywhere else outside the MIDI piano roll and CC lanes), the script will arm itself 
        and its button will light up with the normal "activated" color.
    
    4) When the "js_Run..." script is executed with its shortcut, it will run the armed Mouse editing script.
    
    By using this feature, each "Mouse editing" script does need not be linked to its own shortcut key.  Instead, only the 
      accompanying "js_Run..." script needs to be linked to a shortcut.
   

]]

--[[
 Changelog:
  * v1.0 (2016-07-03)
    + Initial release.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
  v1.10 (2017-01-16)
    + Header updated to ReaPack 1.1 format.
  v1.20 (2017-01-30)
    + The mousewheel modifier that is linked to this script can now control any js "under mouse" script, even if that script was called from its own keyboard shortcut.
  v1.21 (2017-12-21)
    + Broadcast first mousewheel movement to linked scripts.
  v2.00 (2019-02-08)
    + Updated for ReaScriptAPI extension.
    + Mousewheel shortcut starts/stops scripts, instead of controlling CC curves.
]]

status = reaper.GetExtState("js_Mouse actions", "Status") or ""

-- Script already running?  Terminate.
if status ~= "" then
    reaper.SetExtState("js_Mouse actions", "Status", "Must quit", false)
    return

-- No script running?  Start new one.
else
    armedCommandID = tonumber(reaper.GetExtState("js_Mouse actions", "Armed commandID"))
    if armedCommandID then
    
        _, _, sectionID = reaper.get_action_context()
    
        -- Make sure previous actions' buttons are dimmed.
        prevCommandIDs = reaper.GetExtState("js_Mouse actions", "Previous commandIDs") or ""
        for prevID in prevCommandIDs:gmatch("%d+") do
            if tonumber(prevID) ~= armedCommandID then
                reaper.SetToggleCommandState(sectionID, prevID, 0)
                reaper.RefreshToolbar2(sectionID, prevID)
            end
        end
            
        runOK = reaper.MIDIEditor_LastFocused_OnCommand(armedCommandID, false)
        -- Did anything go wrong when calling the armed commandID?
        if not runOK then
            reaper.DeleteExtState("js_Mouse actions", "Status", true)
        end
    end
end

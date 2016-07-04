--[[
 * ReaScript Name: js_Run the js_'lane under mouse' script that is selected in toolbar (link this script to shortcut and mousewheel).lua
 * Description: This script helps to improve the UI by allowing js_ MIDI editing functions to be selected via toolbar buttons, 
 *                  similar to FL Studio and other DAWs.
 *              Any js_ script that edits the 'lane under mouse' and that has been linked to a toolbar button can be 
 *                  run using a single keyboard shortcut that has been linked to this script 
 *                  -- therefore no more need to remember a different shortcut for each script.
 *              This script currently works with the following js_ MIDI editing scripts:
 *                  ~ Stretch 
 *                  ~ Tilt
 *                  ~ Compress or expand
 *                  ~ 1-sided warp (accelerate)
 *                  ~ 2-sided warp (and stretch)
 *                  ~ Draw linear or curved ramp in real time
 *                  ~ Draw linear or curved ramp in real time (chasing start values)
 *                  ~ Draw sine curve in real time
 *                  ~ Draw sine curve in real time (chasing start values)
 *                  ~ Split notes
 *                  ~ Split selected notes
 *                  ~ Remove redundancies (in lane under mouse)
 *              Any user-customized variants of these scripts can also be added to the toolbar.
 *              NOTE: The scripts listed above are those that work with events in the lane under mouse.
 *                    Since the mouse needs to be positioned over the MIDI editor's CC lanes or notes area for these 
 *                        scripts to work, they cannot be run directly from toolbar buttons.
 *                    Scripts that work with events in the last-clicked lane (such as variants the LFO Tool or the 
 *                        Remove Redundancies script) can be run directly from the toolbar.
 *
 * Instructions:  This script must be linked to a keyboard shortcut (such as "S") as well as a mousewheel shortcut (such as Ctrl+mousewheel).
 *                This script should not be linked to a toolbar button.
 *                The js_ MIDI functions listed above should each be linked to a toolbar button.  (They can also
 *                    be linked to their own keyboard shortcuts, but this is not necessary.)
 *                To run the selected js_ MIDI function: 
 *                    1) click its button, which will light up, 
 *                    2) move the mouse to its position in the CC lane or notes area, and 
 *                    3) press the shortcut key for this "Run the js_..." script.
 *
 *                Note: Since this script is a user script, the way it responds to shortcut keys and 
 *                    mouse buttons is opposite to that of REAPER's built-in mouse actions 
 *                    with mouse modifiers:  To run the script, press the shortcut key *once* 
 *                    to start the script and then move the mouse *without* pressing any 
 *                    mouse buttons.  Press the shortcut key again once to stop the script.  
 *                (The first time that the script is stopped, REAPER will pop up a dialog box 
 *                    asking whether to terminate or restart the script.  Select "Terminate"
 *                    and "Remember my answer for this script".)
 *
 *                WARNING: As with any script that involves moving or stretching notes, the user should
 *                         take care that there are no overlapping notes, both when starting and when
 *                         terminating the script, since such notes may lead to various artefacts.
 *
 * 
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread:
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 1.0
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]

--[[
 Changelog:
 * v1.0 (2016-07-03)
    + Initial release.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
]]

-------------------------------------------
function loop_trackMousewheelAndExitState()
    status = reaper.GetExtState("js_Mouse actions", "Status")
    if status == "" or status == nil or status == "Quitting" or status == "Must quit" then 
        return
    end
    
    isNew,_,_,_,_,_,val = reaper.get_action_context()
    if isNew == true then
        reaper.SetExtState("js_Mouse actions", "Mousewheel", tostring(val), false)
    end
    
    reaper.defer(loop_trackMousewheelAndExitState)
end

---------------
function exit()
    reaper.SetExtState("js_Mouse actions", "Status", "Must quit", false)
end

---------------------------------------------------------
-- Here the code execution starts
---------------------------------------------------------
-- function main()

_, _, sectionID, _, _, _, _ = reaper.get_action_context()
if sectionID == nil or sectionID == -1 then return end

editor = reaper.MIDIEditor_GetActive()
if editor == nil then return end

-- Have any js_MIDI script been selected?
if reaper.HasExtState("js_Mouse actions", "Armed commandID") == false then return end

-- Test whether the stored commandID is usable
armedCommandID = tonumber(reaper.GetExtState("js_Mouse actions", "Armed commandID"))
if type(armedCommandID) ~= "number" or armedCommandID%1 ~= 0 then
    reaper.DeleteExtState("js_Mouse actions", "Armed commandID", true)
    return
end

-- Check whether the commandIDs of any previously selected js_MIDI scripts have been stored,
--    and make sure that their toolbar buttons have been deactivated.
-- (This step is not actually necessary, since the js_MIDI scripts themselves also
--    deactivate these buttons.   
if reaper.HasExtState("js_Mouse actions", "Previous commandIDs") then
    prevCommandIDs = reaper.GetExtState("js_Mouse actions", "Previous commandIDs")
    if type(prevCommandIDs) ~= "string" then
        reaper.DeleteExtState("js_Mouse actions", "Previous commandIDs", true)
    else
        tablePrevIDs = {}
        prevSeparatorPos = 0
        repeat
            nextSeparatorPos = prevCommandIDs:find("|", prevSeparatorPos+1)
            if nextSeparatorPos ~= nil then
                prevID = prevCommandIDs:sub(prevSeparatorPos+1, nextSeparatorPos-1)
                if type(prevID) == "number" and prevID%1 == 0 and prevID ~= armedCommandID then
                    table.insert(tablePrevIDs, prevID) 
                end
                prevSeparatorPos = nextSeparatorPos
            end
        until nextSeparatorPos == nil
        for i = 1, #tablePrevIDs do
            reaper.SetToggleCommandState(sectionID, prevID, 0)
            reaper.RefreshToolbar2(sectionID, prevID)
        end
    end
end

-- Set the ExtStates to inform any js_MIDI script that it is running,
--    and reset the mousewheel ExtState.
reaper.SetExtState("js_Mouse actions", "Status", "Calling armed", false)
reaper.SetExtState("js_Mouse actions", "Mousewheel", "0", false)

retval = reaper.MIDIEditor_LastFocused_OnCommand(armedCommandID, false)
-- Did anything go wrong when calling the armed commandID?
if retval ~= true then
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    reaper.DeleteExtState("js_Mouse actions", "Mousewheel", true)
    -- reaper.DeleteExtState("js_Mouse actions", "Armed commandID", true)
    return(false)
else
    reaper.atexit(exit)
    loop_trackMousewheelAndExitState()
end

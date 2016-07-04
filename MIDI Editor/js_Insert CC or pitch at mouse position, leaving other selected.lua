--[[
 * ReaScript Name:  js_Insert CC or pitch at mouse position, leaving other selected.lua
 * Description:  A simple script to insert a CC events, while leaving other events selected.
 *               Strangely, current (v5.20) versions of REAPER does not offer any mouse modifiers 
 *                   for inserting CC events while keeping already-selected events selected.  
 *                   (Compare the "Insert note, leaving other notes selected" mouse action for notes.)
 *               If snapping to grid is enabled in the MIDI editor, the event will be inserted 
 *                   at the closest grid position *before* the mouse position.
 *               Useful for inserting a series of CC 'nodes' at precise grid positions, 
 *                   which can then be linked by linear ramps.
 *               The script does not yet take swing into account when calculating grid positions.
 *
 * Instructions:  There are two ways in which this script can be run:  
 *                  1) First, the script can be linked to its own shortcut key.
 *                  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",
 *                        can each be linked to a toolbar button.  
 *                     In this case, each script need not be linked to its own shortcut key.  Instead, only the 
 *                        accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
 *                        script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
 *                     Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
 *                        and this selected (armed) script can then be run by using the shortcut for the 
 *                        aforementioned "js_Run..." script.
 *                     For further instructions - please refer to the "js_Run..." script. 
 * 
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 2.0
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]

--[[
 Changelog:
 * v1.0 (2016-05-05)
    + Initial Release
 * v1.1 (2016-05-18)
    + Added compatibility with SWS versions other than 2.8.3 (still compatible with v2.8.3) 
 * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
]]

-- USER AREA
-- Setting that the user can customize 
 
-- End of USER AREA

local _, editor, take, details, mouseLane, mouseTime, mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, 
          mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, floorGridQN, floorGridPPQ, destPPQpos, 
          events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
          tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos, stretchFactor, newPPQpos
    
-----------------------------------------------------------------------------------------------
-- Set this script as the armed command that will be called by "js_Run the js action..." script
function setAsNewArmedToolbarAction()

    local tablePrevIDs, prevCommandIDs, prevSeparatorPos, nextSeparatorPos, prevID
    
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1 then
        return(false)
    end
    
    tablePrevIDs = {}
    
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
    
    if reaper.HasExtState("js_Mouse actions", "Previous commandIDs") then
        prevCommandIDs = reaper.GetExtState("js_Mouse actions", "Previous commandIDs")
        if type(prevCommandIDs) ~= "string" then
            reaper.DeleteExtState("js_Mouse actions", "Previous commandIDs", true)
        else
            prevSeparatorPos = 0
            repeat
                nextSeparatorPos = prevCommandIDs:find("|", prevSeparatorPos+1)
                if nextSeparatorPos ~= nil then
                    prevID = tonumber(prevCommandIDs:sub(prevSeparatorPos+1, nextSeparatorPos-1))
                    -- Is the stored number a valid (integer) commandID, and not own ID?
                    if type(prevID) == "number" and prevID%1 == 0 and prevID ~= ownCommandID then
                        table.insert(tablePrevIDs, prevID)
                    end
                    prevSeparatorPos = nextSeparatorPos
                end
            until nextSeparatorPos == nil
            for i = 1, #tablePrevIDs do
                reaper.SetToggleCommandState(sectionID, tablePrevIDs[i], 0)
                reaper.RefreshToolbar2(sectionID, tablePrevIDs[i])
            end
        end
    end
    
    prevCommandIDs = tostring(ownCommandID) .. "|"
    for i = 1, #tablePrevIDs do
        prevCommandIDs = prevCommandIDs .. tostring(tablePrevIDs[i]) .. "|"
    end
    reaper.SetExtState("js_Mouse actions", "Previous commandIDs", prevCommandIDs, false)
    
    reaper.SetExtState("js_Mouse actions", "Armed commandID", tostring(ownCommandID), false)
end

--------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------
-- function main()

function avoidUndo() -- Avoid automatic creation of undo point
end
reaper.defer(avoidUndo)

reaper.DeleteExtState("js_Mouse actions", "Status", true)

-- function should only run if mouse is in a CC lane 
-- Mouse must be positioned in CC lane
editor = reaper.MIDIEditor_GetActive()
if editor == nil then return(0) end

window, segment, details = reaper.BR_GetMouseCursorContext()
-- If window == "unknown", assume to be called from floating toolbar
-- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
    setAsNewArmedToolbarAction()
    return(0) 
elseif details ~= "cc_lane" then 
    return(0) 
end

take = reaper.MIDIEditor_GetTake(editor)
if take == nil then return(0) end

-- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI"
-- https://github.com/Jeff0S/sws/issues/783
-- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
_, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
if SWS283 ~= SWS283again then
    reaper.ShowConsoleMsg("Error: Could not determine compatible SWS version")
    return(0)
end

if SWS283 == true then
    _, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, _, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
end

if mouseCCvalue == -1 then return(0) end     

reaper.Undo_BeginBlock()

--------------------------------------------------------------------
-- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
-- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
-- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
--
-- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc      
mouseTime = reaper.BR_GetMouseCursorContext_Position()
mouseSnapGrid = reaper.SnapToGrid(0, mouseTime)
mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)

------------------------------------------------------------------------------------
-- If snapping is enabled, get the PPQ position of closest grid BEFORE mouse position
if (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1) then
    -- If snap is enabled, we must go through several steps to find the closest grid position
    --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
    -- !! Note that this script does not take swing into account when calculating the grid
    -- First, calculate this take's PPQ:
    startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
    PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
    -- Calculate position of grid immediately before mouse position
    QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
    mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQpos) -- Mouse position in quarter notes
    floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
    insertPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN)    
else 
    -- Otherwise, destination PPQ is exact mouse position
    insertPPQpos = mousePPQpos
end -- "snap_enabled"
      
selected = true
muted = false
channel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
if 0 <= mouseLane and mouseLane <= 127 then -- First, test if 7-bit CC (which has no LSB
    reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 176, channel, mouseLane, mouseCCvalue)
elseif mouseLane == 0x203 then  -- channel pressure
    reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 13<<4, channel, mouseCCvalue, 0)       
elseif 256 <= mouseLane and mouseLane <= 287 then -- 14-bit CC's MSB
    MSB = mouseCCvalue>>7
    LSB = mouseCCvalue&127
    reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 176, channel, mouseLane-256, MSB)
    reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 176, channel, mouseLane-224, LSB) 
elseif mouseLane == 0x201 then -- pitchwheel
    MSB = mouseCCvalue>>7
    LSB = mouseCCvalue&127        
    reaper.MIDI_InsertCC(take, selected, muted, insertPPQpos, 224, channel, LSB, MSB)
end
    
reaper.MIDI_Sort(take)
reaper.Undo_EndBlock("Insert CC, leaving others selected", -1)

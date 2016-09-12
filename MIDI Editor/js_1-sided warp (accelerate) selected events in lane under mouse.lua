--[[
 * ReaScript Name:  js_1-sided warp (accelerate) selected events in lane under mouse.lua
 * Description:  A simple script for warping the positions of MIDI events.
 *               The script only affects events in the MIDI editor lane under the mouse cursor.
 *               NB: Useful for changing a linear ramp into a parabolic (or other power) curve.
 *               NB: Useful for accelerating a series of evenly spaced notes.
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
 *                To use, 1) select MIDI events to be warped,  
 *                        2) position mouse in lane, 
 *                        3) press shortcut key, and
 *                        4) move mouse left or right to warp to the corresponding side.
 *                        5) To exit, move mouse out of CC lane, or press shortcut key again.
 *
 *                Note: Since this function is a user script, the way it responds to shortcut keys and 
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
 * v1.0 (2016-05-15)
    + Initial Release
 * v1.1 (2016-05-18)
    + Added compatibility with SWS versions other than 2.8.3 (still compatible with v2.8.3)
 * v1.11 (2016-05-29)
    + If linked to a menu button, script will toggle button state to indicate activation/termination
 * v1.12 (2016-06-18)
    + Added a warning about overlapping notes in the instructions, as well as a safety check in the code.
 * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
]]

local editor, take, window, segment, details, test, newDetails,
      mouseLane, mouseStartTime, mouseStartPPQpos,
      eventIndex, eventType, eventPPQpos, msg1, msg2, msg, 
      newPPQpos, mouseDirection, mouseMovement, mouseNewPPQpos, newMouseLane,
      firstPPQpos, lastPPQpos, eventsPPQrange
    
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

---------------------------------------------------------------------------
-- Finally, here is the warping function that will be looped by 'deferring'

function loop_warp()

    -- To control this script, the mouse only needs to move horizontally, so 
    --    to provide an easy way to terminate the script, it will terminate if the
    --    mouse is moved out of the CC lane
    _, _, newDetails = reaper.BR_GetMouseCursorContext()
    if newDetails ~= "cc_lane" then
        return(0)
    end
    
    if SWS283 == true then
        _, _, newMouseLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, _, _, newMouseLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end
    if newMouseLane ~= mouseLane or ccLaneVal == -1 then
        return(0)
    end
    
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
    
    mouseNewTime = reaper.BR_GetMouseCursorContext_Position()
    mouseNewPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseNewTime)
    
    -- The warping uses a power function, and the power variable is determined
    --     by calculating to what power 0.5 must be raised to reach the 
    --     mouse's deviation to the left or right fro its starting PPQ position. 
    -- The PPQ range of the selected events is used as reference to calculate
    --     magnitude of mouse movement.
    -- Why use absolute value?  Since power<1 gives a nicer, more 'musical looking'
    --     shape than power>1.
    mouseDirection = mouseNewPPQpos-mouseStartPPQpos -- Positive if moved to right, negative if moved to left
    mouseMovement = 0.5 + math.abs(mouseDirection/eventsPPQrange)
    -- Prevent warping too much, so that all CCs don't end up in a solid block
    if mouseMovement > 0.99 then mouseMovement = 0.99 end
    power = math.log(mouseMovement, 0.5)
      
    for i=1, #events do
        if not (events[i].PPQ == firstPPQpos or events[i].PPQ == lastPPQpos) then -- endpoints do not change position, so need not be warped
                
            if mouseDirection == 0 then
                newPPQpos = events[i].PPQ
            elseif mouseDirection < 0 then
                newPPQpos = math.floor(lastPPQpos - (((lastPPQpos - events[i].PPQ)/eventsPPQrange)^power)*eventsPPQrange + 0.5)
            else -- mouseDirection > 0
                newPPQpos = math.floor(firstPPQpos + (((events[i].PPQ - firstPPQpos)/eventsPPQrange)^power)*eventsPPQrange + 0.5)
            end
            
            if mouseLane == 0x205 or mouseLane == 0x206 then
                reaper.MIDI_SetTextSysexEvt(take, events[i].index, nil, nil, newPPQpos, nil, events[i].msg, true)
            else    
                reaper.MIDI_SetEvt(take, events[i].index, nil, nil, newPPQpos, events[i].msg, true) -- Strange: according to the documentation, msg is optional
            end
            
        end -- if not (events[i].PPQ == firstPPQpos or events[i].PPQ == lastPPQpos)
    end
            
    -- Loop the function continuously
    reaper.defer(loop_warp)

end -- function loop_warp()

-----------------------------------------------------------------------

function exit()
    reaper.MIDI_Sort(take)
    
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 
        and (prevToggleState == 0 or prevToggleState == 1) 
        then
        reaper.SetToggleCommandState(sectionID, cmdID, prevToggleState)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
        
    if mouseLane == 0x206 then
        undoString = "1-sided warp (accelerate) MIDI events: Sysex"
    elseif mouseLane == 0x205 then
        undoString = "1-sided warp (accelerate) MIDI events: Text events"
    elseif 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
        undoString = "1-sided warp (accelerate) MIDI events: 7 bit CC, lane ".. tostring(mouseLane)
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        undoString = "1-sided warp (accelerate) MIDI events: 14 bit CC, lanes ".. tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224)
    elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or off-velocity
        undoString = "1-sided warp (accelerate) MIDI events: Notes"
    elseif mouseLane == 0x201 then -- pitch
        undoString = "1-sided warp (accelerate) MIDI events: Pitchwheel"
    elseif mouseLane == 0x202 then -- program select
        undoString = "1-sided warp (accelerate) MIDI events: Program Select"
    elseif mouseLane == 0x203 then -- channel pressure (after-touch)
        undoString = "1-sided warp (accelerate) MIDI events: Channel Pressure"
    elseif mouseLane == 0x204 then -- Bank/Program select - Program select
        undoString = "1-sided warp (accelerate) MIDI events: Bank/Program Select"
    else              
        undoString = "1-sided warp (accelerate) MIDI events"
    end -- if mouseLane ==
    
    reaper.Undo_OnStateChange(undoString, -1)
end

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

-- Trick to prevent REAPER from automatically creating an undo point
function avoidUndo()
end
reaper.defer(avoidUndo)

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
    _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
end

mouseStartTime = reaper.BR_GetMouseCursorContext_Position()
mouseStartPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseStartTime)

--------------------------------------------------------------------
-- Find events in mouse lane.
-- sysex and text events are weird, so use different "Get" function

-- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
-- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
-- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"

reaper.MIDI_Sort(take)

events = {} -- All selected events in lane will be stored in an array
firstPPQpos = math.huge
lastPPQpos = 0

if mouseLane == 0x206 or mouseLane == 0x205 -- sysex and text events
    then
    eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, -1)
    while(eventIndex ~= -1) do
        _, _, _, eventPPQpos, eventType, msg = reaper.MIDI_GetTextSysexEvt(take, eventIndex)
        if (mouseLane == 0x206 and eventType == -1) -- only sysex
        or (mouseLane == 0x205 and eventType ~= -1) -- only text events
            then
            table.insert(events, {index = eventIndex, 
                                  PPQ = eventPPQpos, 
                                  msg = msg, 
                                  type = 0xF})
            if eventPPQpos < firstPPQpos then firstPPQpos = eventPPQpos end
            if eventPPQpos > lastPPQpos then lastPPQpos = eventPPQpos end           
        end
        eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, eventIndex)
    end

else  -- all other event types that are not sysex or text

    eventIndex = reaper.MIDI_EnumSelEvts(take, -1)
    while(eventIndex ~= -1) do   
        _, _, _, eventPPQpos, msg = reaper.MIDI_GetEvt(take, eventIndex, true, true, 0, "")
        msg1=tonumber(string.byte(msg:sub(1,1)))
        msg2=tonumber(string.byte(msg:sub(2,2)))
        eventType = msg1>>4

        -- Now, select only event types that correspond to mouseLane:
        if (0 <= mouseLane and mouseLane <= 127 -- CC, 7 bit (single lane)
            and msg2 == mouseLane and eventType == 11)
        or (256 <= mouseLane and mouseLane <= 287 -- CC, 14 bit (double lane)
            and (msg2 == mouseLane-256 or msg2 == mouseLane-224) and eventType ==11) -- event can be from either MSB or LSB lane
        or ((mouseLane == 0x200 or mouseLane == 0x207) -- Velocity or off-velocity
            and (eventType == 9 or eventType == 8)) -- note on or note off
        or (mouseLane == 0x201 and eventType == 14) -- pitch
        or (mouseLane == 0x202 and eventType == 12) -- program select
        or (mouseLane == 0x203 and eventType == 13) -- channel pressure (after-touch)
        or (mouseLane == 0x204 and eventType == 12) -- Bank/Program select - Program select
        or (mouseLane == 0x204 and eventType == 11 and msg2 == 0) -- Bank/Program select - Bank select MSB
        or (mouseLane == 0x204 and eventType == 11 and msg2 == 32) -- Bank/Program select - Bank select LSB
        then
            table.insert(events, {index = eventIndex, 
                                  PPQ = eventPPQpos, 
                                  msg = msg, 
                                  type = eventType})
            if eventPPQpos < firstPPQpos then firstPPQpos = eventPPQpos end
            if eventPPQpos > lastPPQpos then lastPPQpos = eventPPQpos end
        end
        eventIndex = reaper.MIDI_EnumSelEvts(take, eventIndex)
    end
end    

--------------------------------------------------------------
-- If only two event are selected, there is nothing to warp
if (#events < 3)
or (256 <= mouseLane and mouseLane <= 287 and #events < 6)
or (mouseLane == 0x204 and #events < 6)
or ((mouseLane == 0x200 or mouseLane == 0x207) and #events < 6)
    then return(0) 
end

-------------------------------------------------------------------------
-- Now we know there are events in the table, so the range can be defined
eventsPPQrange = lastPPQpos - firstPPQpos
if eventsPPQrange == 0 then return(0) end

---------------------------------------------------------------------------
-- If notes, do safety tests to check for overlapping notes
-- These tests will only detect overlapping notes among the selected notes,
--    and will not detect overlaps with UNselected notes.
if mouseLane == 0x200 or mouseLane == 0x207 then
    --First, test whether there are overlapping notes in REAPER's internal representation of the notes
    local tableEndPPQs = {}
    local noteIndex = reaper.MIDI_EnumSelNotes(take, -1)
    while (noteIndex ~= -1) do
        local _, _, _, startppqposOut, endppqposOut, chanOut, pitchOut, _ = reaper.MIDI_GetNote(take, noteIndex)
        if tableEndPPQs[chanOut*128 + pitchOut] == nil then
            tableEndPPQs[chanOut*128 + pitchOut] = endppqposOut
        else
            if startppqposOut < tableEndPPQs[chanOut*128 + pitchOut] then
                reaper.ShowConsoleMsg("\n\nERROR:\nThe selected notes appear to include overlapping notes. The script will unfortunately not work with such notes.")
                return(0)
            else
                tableEndPPQs[chanOut*128 + pitchOut] = endppqposOut
            end
        end
        noteIndex = reaper.MIDI_EnumSelNotes(take, noteIndex)
    end
    
    -- Now test whether there are an equal number of note-ons and note-offs
    local count = 0
    for i = 1, #events do
        if events[i].type == 8 then count = count + 1
        elseif events[i].type == 9 then count = count - 1
        end
    end
    if count ~= 0 then 
        reaper.ShowConsoleMsg("\n\nERROR:\nThere appears to be an unequal number of note-ons and note-offs among the selected notes. The script will unfortunately not work with such notes.")
        return(0)
    end
end

reaper.atexit(exit)

_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end
        
loop_warp()

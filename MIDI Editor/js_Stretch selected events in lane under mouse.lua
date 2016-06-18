--[[
 * ReaScript Name:  Stretch selected events in lane under mouse
 * Description:  A simple script for stretching MIDI events in the MIDI editor  
 *               The script only affects events in the MIDI editor lane that is under the mouse cursor.
 *               If snap to grid is enabled, the rightmost event will snap to grid.
 * Instructions:  The script must be linked to a shortcut key.  
 *                To use, 1) select MIDI events to be stretched,  
 *                        2) position mouse in the lane at the position to which the 
 *                              rightmost event should be stretched, 
 *                        3) press shortcut key, and
 *                        4) move mouse left or right to change the extent of stretching.
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
 * Version: 1.12
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]
 

--[[
 Changelog:
 * v1.0 (2015-05-14)
    + Initial Release
 * v1.1 (2016-05-18)
    + Added compatibility with SWS versions other than 2.8.3 (still compatible with v2.8.3)
    + CCs can be inverted by stretching to left of range, but not notes
 * v1.11 (2016-05-29)
    + If linked to a menu button, script will toggle button state to indicate activation/termination
 * v1.12 (2016-06-18)
    + Added a warning about overlapping notes in the instructions, as well as a safety check in the code.
]]

----------------------------------------------------------------------
-- The function that tracks mouse movement and that will be 'deferred'
function loop_stretchEvents()
    local currentDetails, currentMouseLane, mouseTime, mousePPQpos, mouseQNpos, floorGridQN, destPPQpos,
          newPPQpos, stretchFactor

    -- If the mouse moves out of the original CC lane, the function exits
    _, _, currentDetails = reaper.BR_GetMouseCursorContext()
    if currentDetails ~= "cc_lane" then return(0) end
    
    if SWS283 == true then
        _, _, currentMouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, _, _, currentMouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end
    if currentMouseLane ~= mouseLane then return(0) end
    
    -- Next step is to determine the destination position to which the rightmost CC event should be stretched
    -- If snap is enabled, events will stretch to grid, otherwise to exact mouse position    
    mouseTime = reaper.BR_GetMouseCursorContext_Position()
    mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
    
    if(reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1) then
        -- If snap is enabled, we must go through several steps to find the closest grid position
        --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
        -- !! Note that this script does not take swing into account when calculating the grid
        QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
        mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQpos) -- Mouse position in quarter notes
        floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
        destPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) -- Snap enabled, so destination PPQ falls on grid 
    
    -- Otherwise, destination PPQ is exact mouse position
    else 
        destPPQpos = mousePPQpos
    end
    
    -- Except if stretching notes, in which case note-on and note-off cannot be switched around:
    if destPPQpos <= firstPPQpos+#events and (mouseLane == 0x200 or mouseLane == 0x207) then
        destPPQpos = lastPPQpos
    end
        
    stretchFactor = (destPPQpos-firstPPQpos)/eventsPPQrange
    
    for i=1, #events do
        newPPQpos = math.floor(firstPPQpos + (events[i].PPQ - firstPPQpos)*stretchFactor + 0.5) -- add 0.5 to simulate rounding
        if mouseLane == 0x205 or mouseLane == 0x206 then
            reaper.MIDI_SetTextSysexEvt(take, events[i].index, nil, nil, newPPQpos, nil, events[i].msg, true)
        else    
            reaper.MIDI_SetEvt(take, events[i].index, nil, nil, newPPQpos, events[i].msg, true) -- Strange: according to the documentation, msg is optional
        end
    end
    
    reaper.runloop(loop_stretchEvents)
    
end -- function loop_stretchEvents()

------------------------------
-- Called when function exists
function exit()    
    reaper.MIDI_Sort(take)
    
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
        
    if mouseLane == 0x206 then
        undoString = "Stretch events in single lane: Sysex"
    elseif mouseLane == 0x205 then
        undoString = "Stretch events in single lane: Text events"
    elseif 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
        undoString = "Stretch events in single lane: 7 bit CC, lane ".. tostring(mouseLane)
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        undoString = "Stretch events in single lane: 14 bit CC, lanes ".. tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224)
    elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or off-velocity
        undoString = "Stretch events in single lane: Notes"
    elseif mouseLane == 0x201 then -- pitch
        undoString = "Stretch events in single lane: Pitchwheel"
    elseif mouseLane == 0x202 then -- program select
        undoString = "Stretch events in single lane: Program Select"
    elseif mouseLane == 0x203 then -- channel pressure (after-touch)
        undoString = "Stretch events in single lane: Channel Pressure"
    elseif mouseLane == 0x204 then -- Bank/Program select - Program select
        undoString = "Stretch events in single lane: Bank/Program Select"
    else              
        undoString = "Stretch events in single lane"
    end -- if mouseLane ==
    
    reaper.Undo_OnStateChange(undoString, -1)
end

-----------------------------------------------------------------------------------------------------------
--[[function main() 
    local _, editor, take, details, mouseLane, QNperGrid, mouseQNpos, 
          events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
          tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos,
    ]]      
    
    function avoidUndo()
    end
    reaper.defer(avoidUndo)
    
    -- Mouse must be positioned in CC lane
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then return(0) end
    take = reaper.MIDIEditor_GetTake(editor)
    if take == nil then return(0) end
    window, segment, details = reaper.BR_GetMouseCursorContext()
    if details ~= "cc_lane" then return(0) end
    
    -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI()"
    -- https://github.com/Jeff0S/sws/issues/783
    -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
    _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
    if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
    if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
    if SWS283 ~= SWS283again then
        reaper.ShowConsoleMsg("\n\nERROR:\nCould not determine compatible SWS version.")
        return(0)
    end
    
    if SWS283 == true then
        _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end

    -- Now stuff start to happen so toggle toolbar button (if any) and define atexit
    _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    reaper.atexit(exit)    
    reaper.MIDI_Sort(take)
    
    --------------------------------------------------------------------
    -- Find selected events in mouse lane.
    -- sysex and text events are weird, so use different "Get" function
    --
    -- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
    -- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
    -- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
    --
    -- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc
    
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
            eventType = msg1>>4 -- eventType is CC (11), pitch (14), etc...
    
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
    -- If only one event is selected, there is nothing to stretch!
    if (#events < 2)
    or (256 <= mouseLane and mouseLane <= 287 and #events < 4)
    or (mouseLane == 0x204 and #events < 4)
        then return(0) end
    
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
    
    ---------------------------------------------------
    -- Finally, call the function that will be deferred
    loop_stretchEvents()
    
--end -- end main()


-----------------
-- Run the script
--main()
      

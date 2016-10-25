--[[
ReaScript name:  js_Stretch selected events in lane under mouse.lua
Version: 2.10
Author: juliansader
Screenshot: http://stash.reaper.fm/27594/Stretch%20selected%20events%20in%20lane%20under%20mouse%20-%20Copy.gif
Website: http://forum.cockos.com/showthread.php?t=176878
Extensions: SWS/S&M 2.8.3 or later
About:
  # Description
  A script for stretching MIDI events in the MIDI editor.
  The script only affects events in the MIDI editor lane that is under the mouse cursor.
  If snap to grid is enabled, the rightmost event will snap to grid.

  # Instructions
  There are two ways in which this script can be run:  
  
  * First, the script can be linked to its own shortcut key.
  
  * Second, this script, together with other "js_" scripts that edit the "lane under mouse",
     can each be linked to a toolbar button.  
    In this case, each script need not be linked to its own shortcut key.  Instead, only the 
     accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
     script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
    Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
     and this selected (armed) script can then be run by using the shortcut for the 
     aforementioned "js_Run..." script.
    For further instructions - please refer to the "js_Run..." script. 
  
   To use, 1) Select the MIDI events to be stretched,  
           2) Position the mouse in the CC lane (or in the notes area or velocity lane in the case of notes)
           3) To stretch events on the left (using the rightmost event as anchor), position the mouse to left of the 
              midpoint of the events' time range.  
              To stretch events on the right, position the mouse to the right of the midpoint of the events' time range.
           4) Press the shortcut key.
           5) Move mouse left or right to change the extent of stretching.
           6) To exit, move mouse out of CC lane, or press shortcut key again.
  
   Note: Since this function is a user script, the way it responds to shortcut keys and 
       mouse buttons is opposite to that of REAPER's built-in mouse actions 
       with mouse modifiers:  To run the script, press the shortcut key *once* 
       to start the script and then move the mouse *without* pressing any 
       mouse buttons.  Press the shortcut key again once to stop the script. 
        
   (The first time that the script is stopped, REAPER will pop up a dialog box 
       asking whether to terminate or restart the script.  Select "Terminate"
       and "Remember my answer for this script".)
  
  # Warning
  As with any script that involves moving or stretching notes, the user should
  take care that there are no overlapping notes, both when starting and when
  terminating the script, since such notes may lead to various artefacts.
  
  The script can be set to perform a safety check for overlapping notes. 
  To activate the safety check, set the doCheckNoteOverlaps variable to "true" in the script's USER AREA.
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
 * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
 * v2.10 (2016-10-24)
    + Header and "About" info updated to ReaPack 1.1 format.
    + Notes can now be reversed, similar to CCs.
    + New feature: Events can now be stretched either from the left or from the right.
]]

-- USER AREA
-- Settings that the user can customize

doCheckNoteOverlaps = false -- True or false. Overlapping notes are not compatible with ReaScripts. Should the script check for such overlaps before continuing?

-- End of USER AREA

----------------------------------------------------------------------
-- The function that tracks mouse movement and that will be 'deferred'
function loop_stretchEvents()
    local currentDetails, currentSegment, currentMouseLane, mouseTime, mousePPQpos, mouseQNpos, floorGridQN, destPPQpos,
          newPPQ, newPPQstart, newPPQend, stretchFactor

    -- If the mouse moves out of the original CC lane or notes area, the function exits
    _, currentSegment, currentDetails = reaper.BR_GetMouseCursorContext()
    if not (currentSegment == "notes" or currentDetails == "cc_lane") then return(0) end
    
    if SWS283 == true then
        _, _, currentMouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, _, _, currentMouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end
    if laneType == "notes" then
        if not (currentSegment == "notes" or currentMouseLane == 0x200 or currentMouseLane == 0x207) then
            return(0)
        end
    else -- CC or textSysex
        if currentMouseLane ~= mouseLane then 
            return(0) 
        end
    end
    
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end   
    
    -- Next step is to determine the destination position to which the CC events should be stretched
    -- If snap is enabled, events will stretch to grid, otherwise to exact mouse position    
    mouseTime = reaper.BR_GetMouseCursorContext_Position()
    mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
    
    if reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled") == 1 then
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
    
    -- "left" and "right" anchor use slightly different formulas, so split code
    if anchor == "left" then
            
        stretchFactor = (destPPQpos-firstPPQpos)/eventsPPQrange
        
        for i=1, #events do
            if laneType == "CC" then
                newPPQ = math.floor(firstPPQpos + (events[i].PPQ - firstPPQpos)*stretchFactor + 0.5) -- add 0.5 to simulate rounding
                reaper.MIDI_SetCC(take, events[i].index, nil, nil, newPPQ, nil, nil, nil, nil, true)
            elseif laneType == "notes" then
                newPPQstart = math.floor(firstPPQpos + (events[i].PPQstart - firstPPQpos)*stretchFactor + 0.5)
                newPPQend = math.floor(firstPPQpos + (events[i].PPQend - firstPPQpos)*stretchFactor + 0.5)
                if newPPQstart > newPPQend then newPPQstart, newPPQend = newPPQend, newPPQstart end
                reaper.MIDI_SetNote(take, events[i].index, nil, nil, newPPQstart, newPPQend, nil, nil, nil, true)
            else -- if laneType == "textSysex" then
                newPPQ = math.floor(firstPPQpos + (events[i].PPQ - firstPPQpos)*stretchFactor + 0.5)
                reaper.MIDI_SetTextSysexEvt(take, events[i].index, nil, nil, newPPQ, nil, "", true)
            end
        end
        
    else -- anchor == "right"
            
        stretchFactor = (lastPPQpos-destPPQpos)/eventsPPQrange
        
        for i=1, #events do
            if laneType == "CC" then
                newPPQ = math.floor(lastPPQpos - (lastPPQpos - events[i].PPQ)*stretchFactor + 0.5) -- add 0.5 to simulate rounding
                reaper.MIDI_SetCC(take, events[i].index, nil, nil, newPPQ, nil, nil, nil, nil, true)
            elseif laneType == "notes" then
                newPPQstart = math.floor(lastPPQpos - (lastPPQpos - events[i].PPQstart)*stretchFactor + 0.5)
                newPPQend = math.floor(lastPPQpos - (lastPPQpos - events[i].PPQend)*stretchFactor + 0.5)
                if newPPQstart > newPPQend then newPPQstart, newPPQend = newPPQend, newPPQstart end
                reaper.MIDI_SetNote(take, events[i].index, nil, nil, newPPQstart, newPPQend, nil, nil, nil, true)
            else -- if laneType == "textSysex" then
                newPPQ = math.floor(lastPPQpos - (lastPPQpos - events[i].PPQ)*stretchFactor + 0.5)
                reaper.MIDI_SetTextSysexEvt(take, events[i].index, nil, nil, newPPQ, nil, "", true)
            end
        end
        
    end
        
    reaper.runloop(loop_stretchEvents)
    
end -- function loop_stretchEvents()

------------------------------
-- Called when function exists
function exit()    

    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 
        and (prevToggleState == 0 or prevToggleState == 1) 
        then
        reaper.SetToggleCommandState(sectionID, cmdID, prevToggleState)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
        
    reaper.MIDI_Sort(take)
            
    if laneType == "notes" then
        undoString = "Stretch events: Notes"
    elseif mouseLane == 0x206 then
        undoString = "Stretch events in single lane: Sysex"
    elseif mouseLane == 0x205 then
        undoString = "Stretch events in single lane: Text events"
    elseif 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
        undoString = "Stretch events in single lane: 7 bit CC, lane ".. tostring(mouseLane)
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        undoString = "Stretch events in single lane: 14 bit CC, lanes ".. tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224)
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

-----------------------------------------------------------------------------------------------------------
--[[function main() 
    local _, editor, take, details, mouseLane, QNperGrid, mouseQNpos, 
          events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
          tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos,
    ]]      
    
    -- The following lines prevent REAPER from automatically creating an undo point.
    function avoidUndo()
    end
    reaper.defer(avoidUndo)
    
    -----------------------------------------------------------------------------------------------------------------------------
    -- This script can be called in (at least) three ways: 
    --    either by clicking on a linked toolbar button, or by pressing a keyboard shortcut, or by calling the script from 
    --    another script via the reaper.MIDIEditor_OnCommand function.
    --
    --  * In case of toolbar button, the script will not actually start stretching events, but will instead arm itself as the 
    --    script that will be called by the js_Run the js_'lane under mouse' script.
    --  * In case of keyboard shortcut or MIDIEditor_OnCommand (and if the mosue is correctly positioned over a suitable CC lane, 
    --    the script will start stretching the events.
    
    -- Is there an active MIDI editor?
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then return(0) end
     
    -- If window == "unknown", assume to be called from floating toolbar.
    -- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar.
    -- Otherwise, if not called from a toolbar button, check whether mouse is over CC lane or notes area.  If not, simply quit.
    window, segment, details = reaper.BR_GetMouseCursorContext()
    if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
        setAsNewArmedToolbarAction()
        return(0) 
    elseif not (segment == "notes" or details == "cc_lane") then 
        return(0) 
    end
    -- Now we know the mouse is either over a CC lane or the notes area, so the script can continue.
    
    -- GetTake is buggy and sometimes returns an invalid, deleted take, so must validate take. 
    take = reaper.MIDIEditor_GetTake(editor)
    if not reaper.ValidatePtr(take, "MediaItem_Take*") then return(0) end
    
    --------------------------------------------------------------------------------------
    -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI"
    -- https://github.com/Jeff0S/sws/issues/783
    -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
    _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
    if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
    if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
    if SWS283 ~= SWS283again then
        reaper.ShowMessageBox("Could not determine compatible SWS version.", "ERROR", 0)
        return(0)
    end
    
    if SWS283 == true then
        _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end
    
    --------------------------------------------------------------------------------------------------------
    -- Overlapping notes are note compatible with ReaScripts (particularly not with the MIDI_Sort function),
    --    and may lead to artefacts such as extended notes.
    -- Therefore do a safety check BEFORE running MIDI_Sort.
    if doCheckNoteOverlaps == true then
    
        tableEndPPQs = {} -- note ends PPQ
        for channel = 0, 15 do
            tableEndPPQs[channel] = {}
            for pitch = 0, 127 do
                tableEndPPQs[channel][pitch] = -math.huge
            end
        end
        
        countOK, numNotes, _, _ = reaper.MIDI_CountEvts(take)
        for i = 0, numNotes-1 do
            noteOK, _, _, noteStartPPQ, noteEndPPQ, channel, pitch, _ = reaper.MIDI_GetNote(take, i)
            if not noteOK then
                reaper.ShowMessageBox("The active take appears to contain unsorted notes. \n\n.Please run an action such as 'Remove overlapping notes' before continuing.", "ERROR", 0)
                return(0)
            elseif tableEndPPQs[channel][pitch] > noteStartPPQ then
                reaper.ShowMessageBox("The active take appears to contain overlapping or unsorted notes. \n\nReaScripts are not compatible with overlapping notes. \n\nPlease run an action such as 'Remove overlapping notes' before continuing.", "ERROR", 0)
                return(0)
            else 
                tableEndPPQs[channel][pitch] = noteEndPPQ
            end
        end
    end
    
    --------------------------------------------------------------------------------
    -- Now stuff start to happen so toggle toolbar button (if any) and define atexit
    _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    reaper.atexit(exit)    
    
    reaper.MIDI_Sort(take)
    
    --------------------------------------------------------------------
    -- Find selected events in mouse lane.
    --
    -- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
    -- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
    -- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
    --
    -- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc
    
    events = {} -- All selected events in lane will be stored in an array
    firstPPQpos = math.huge
    lastPPQpos = -math.huge
        
    if details == "cc_lane" and (mouseLane == 0x206 or mouseLane == 0x205) then -- sysex and text events
        
        laneType = "textSysex"
        
        eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, -1)
        while(eventIndex ~= -1) do
            sysexOK, _, _, eventPPQpos, eventType, _ = reaper.MIDI_GetTextSysexEvt(take, eventIndex)
            if sysexOK then
                if (mouseLane == 0x206 and eventType == -1) -- only sysex
                or (mouseLane == 0x205 and eventType ~= -1 and eventType ~= 15) -- only text events, but exclude REAPER's proprietary notation events
                    then
                    table.insert(events, {index = eventIndex,
                                          PPQ = eventPPQpos})
                    if eventPPQpos < firstPPQpos then firstPPQpos = eventPPQpos end
                    if eventPPQpos > lastPPQpos then lastPPQpos = eventPPQpos end           
            end end
            eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, eventIndex)
        end
     
    elseif segment == "notes" or (details == "cc_lane" and (mouseLane == 0x200 or mouseLane == 0x207)) then -- Notes area, Velocity lane or Off-velocity lane
        
        laneType = "notes"
        
        noteIndex = reaper.MIDI_EnumSelNotes(take, -1)
        while(noteIndex ~= -1) do
            noteOK, _, _, noteStartPPQ, noteEndPPQ, _, _, _ = reaper.MIDI_GetNote(take, noteIndex)
            if noteOK then
                table.insert(events, {index = noteIndex,
                                      PPQstart = noteStartPPQ,
                                      PPQend = noteEndPPQ})
                if noteStartPPQ < firstPPQpos then firstPPQpos = noteStartPPQ end
                if noteEndPPQ > lastPPQpos then lastPPQpos = noteEndPPQ end  
            end
            noteIndex = reaper.MIDI_EnumSelNotes(take, noteIndex)
        end      
      
    elseif details == "cc_lane" and type(mouseLane) == "number" then -- all other event types that are not sysex or text
    
        laneType = "CC"
        
        ccIndex = reaper.MIDI_EnumSelCC(take, -1)
        while(ccIndex ~= -1) do
        
            ccOK, _, _, ccPPQpos, chanmsg, _, msg2, _ = reaper.MIDI_GetCC(take, ccIndex)
            eventType = chanmsg>>4 -- eventType is CC (11), pitch (14), etc...
    
            -- Now, select only event types that correspond to mouseLane:
            if ccOK then
                if (0 <= mouseLane and mouseLane <= 127 -- CC, 7 bit (single lane)
                    and msg2 == mouseLane and eventType == 11)
                or (256 <= mouseLane and mouseLane <= 287 -- CC, 14 bit (double lane)
                    and (msg2 == mouseLane-256 or msg2 == mouseLane-224) and eventType == 11) -- event can be from either MSB or LSB lane
                --or ((mouseLane == 0x200 or mouseLane == 0x207) -- Velocity or off-velocity
                --    and (eventType == 9 or eventType == 8)) -- note on or note off
                or (mouseLane == 0x201 and eventType == 14) -- pitch
                or (mouseLane == 0x202 and eventType == 12) -- program select
                or (mouseLane == 0x203 and eventType == 13) -- channel pressure (after-touch)
                or (mouseLane == 0x204 and eventType == 12) -- Bank/Program select - Program select
                or (mouseLane == 0x204 and eventType == 11 and msg2 == 0) -- Bank/Program select - Bank select MSB
                or (mouseLane == 0x204 and eventType == 11 and msg2 == 32) -- Bank/Program select - Bank select LSB
                then
                    table.insert(events, {index = ccIndex,
                                          PPQ = ccPPQpos})
                    if ccPPQpos < firstPPQpos then firstPPQpos = ccPPQpos end
                    if ccPPQpos > lastPPQpos then lastPPQpos = ccPPQpos end                           
            end end
            ccIndex = reaper.MIDI_EnumSelCC(take, ccIndex)
        end
        
    else
        return(0)
    end 
    
    --------------------------------------------------------------
    -- If only one event is selected, there is nothing to stretch!
    if (laneType == "notes" and #events == 0)
    or (laneType == "CC" and #events < 2)
    or (laneType == "CC" and (256 <= mouseLane and mouseLane <= 287) and #events < 4) -- 14bit CCs consist of two events each
    or (laneType == "textSysex" and #events < 2)
        then return(0) 
    end
    
    -------------------------------------------------------------------------
    -- Now we know there are events in the table, so the range can be defined
    -- If the range is 0, cannot stretch
    eventsPPQrange = lastPPQpos - firstPPQpos
    if eventsPPQrange <= 0 then return(0) end    
    
    -----------------------------------------------------------------------------
    -- Now check whether events will be stretched form the right or from the left
    mouseTime = reaper.BR_GetMouseCursorContext_Position()
    mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)    
    if mousePPQpos >= (lastPPQpos + firstPPQpos)/2 then 
        anchor = "left"
    else
        anchor = "right"
    end    
        
    ---------------------------------------------------
    -- Finally, call the function that will be deferred
    loop_stretchEvents()
    
--end -- end main()


-----------------
-- Run the script
--main()
      

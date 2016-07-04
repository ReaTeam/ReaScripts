--[[
 * ReaScript Name:  js_Tilt selected CCs or velocities to mouse position.lua
 * Description:  A simple script for linear tilting of selected events in the lane under mouse.  
 *               The endpoint events are tilted to the exact value of the mouse position,
 *                  so the script is useful for precise positioning of ramps and other CC shapes.
 *               The script only affects events in the MIDI editor lane that is under the mouse cursor.
 *               The script can be used in 7-bit CC lanes, 14-bit CC lanes, velocity, pitchwheel and channel pressure.
 *
 * Instructions: There are two ways in which this script can be run:  
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
 *                To use, 1) select MIDI events to be tilted,  
 *                        2) position mouse in lane, 
 *                        3) press shortcut key, and
 *                        4) move mouse up or down to change tilting position.
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
 * v1.12 (2016-06-19)
    + Script safely quits if time range of selected events is zero.
 * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
]]    

function tilt14bitCC()    

    local tempTableLSB, tempTableMSB, tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, mousePPQpos, newValue
        
    -- All selected events in the MSB and LSB lanes will be stored in 
    --     separate temporary tables.  These tables will then be searched to
    --     find the LSB and MSB events that fall on the same ppq, 
    --     which means that they combine to form one 14-bit CC event.
    tempTableLSB = {}
    tempTableMSB = {}
    tableCC = {}
        
    eventIndex = reaper.MIDI_EnumSelCC(take, -1)
    
    while(eventIndex ~= -1) do
        _, _, _, ppqpos, chanmsg, _, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 11 and  msg2 == mouseLane-256 then -- 14bit MSB
            table.insert(tempTableMSB, {index = eventIndex, 
                                        PPQ = ppqpos, 
                                        value = msg3})
        elseif (chanmsg>>4) == 11 and msg2 == mouseLane-224 then -- 14bit LSB
            table.insert(tempTableLSB, {index = eventIndex, 
                                        PPQ = ppqpos, 
                                        value = msg3})
        end
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    -- Now, find the LSB and MSB events that fall on the same ppq
    for l = 1, #tempTableLSB do
        for m = 1, #tempTableMSB do
            if tempTableLSB[l].PPQ == tempTableMSB[m].PPQ then
                table.insert(tableCC, {
                             PPQ = tempTableLSB[l].PPQ,
                             MSBindex = tempTableMSB[m].index,
                             LSBindex = tempTableLSB[l].index,
                             value = tempTableMSB[m].value*128 + tempTableLSB[l].value
                             })
            end -- if
        end -- #tempTableMSB
    end -- #tempTableLSB
    
    if #tableCC == 0 then return(0) end
    
    -- Find the first and last events, since these will determine the angle of tilting
    --     (I do not know to what extent scripts can trust "MIDI_Sort", so I prefer to do this manually
    first = 1
    last = 1
    firstPPQ = tableCC[first].PPQ
    lastPPQ  = tableCC[last].PPQ
    for i = 2, #tableCC do
        if tableCC[i].PPQ < firstPPQ then 
            firstPPQ = tableCC[i].PPQ
            first = i
        elseif tableCC[i].PPQ > lastPPQ then 
            lastPPQ = tableCC[i].PPQ
            last = i
        end
    end
    PPQrange = lastPPQ - firstPPQ
    if PPQrange == 0 then return(0) end
    
    --------------------------------------------------------------------
    
    function tilt14bitCC_loop()
    
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if window ~= "midi_editor" then return(0) end
        
        if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
        
        if SWS283 == true then
            _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end
        mouseTime = reaper.BR_GetMouseCursorContext_Position()
        mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
        
        if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1 then
            if mousePPQpos > (firstPPQ + lastPPQ)/2 then -- tilt righthand side
                difference = ccLaneVal - tableCC[last].value
                for i = 1, #tableCC do
                    newValue14bit = math.floor(tableCC[i].value + difference*(tableCC[i].PPQ-firstPPQ)/PPQrange + 0.5)
                    newValue14bit = math.min(newValue14bit, 16383)
                    newValue14bit = math.max(newValue14bit, 0)
                    reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue14bit>>7, true)
                    reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue14bit&127, true)
                end
            else -- tilt lefthand side
                difference = ccLaneVal - tableCC[first].value
                for i = 1, #tableCC do
                    newValue14bit = math.floor(tableCC[i].value + difference*(lastPPQ-tableCC[i].PPQ)/PPQrange + 0.5)
                    newValue14bit = math.min(newValue14bit, 16383)
                    newValue14bit = math.max(newValue14bit, 0)
                    reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue14bit>>7, true)
                    reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue14bit&127, true)
                end       
            end
        end --if details == "cclane" and ccLane == mouseLane and ccLaneVal ~= -1
        
        reaper.defer(tilt14bitCC_loop) 
        
    end -- function tilt14bitCC
    
    -- Call the subroutine that will be 'deferred'
    tilt14bitCC_loop()
    
end

--------------------------------------------------------------------

function tilt7bitCC()  

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, mousePPQpos, newValue
          
    tableCC = {}
        
    eventIndex = reaper.MIDI_EnumSelCC(take, -1)
    while(eventIndex ~= -1) do
        _, _, _, ppqpos, chanmsg, _, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 11 and msg2 == mouseLane then
            table.insert(tableCC, {index = eventIndex, 
                                 PPQ = ppqpos, 
                                 value = msg3})    
        end
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    if #tableCC == 0 then return(0) end

    first = 1
    last = 1
    firstPPQ = tableCC[first].PPQ
    lastPPQ  = tableCC[last].PPQ
    for i = 2, #tableCC do
        if tableCC[i].PPQ < firstPPQ then 
            firstPPQ = tableCC[i].PPQ
            first = i
        elseif tableCC[i].PPQ > lastPPQ then 
            lastPPQ = tableCC[i].PPQ
            last = i
        end
    end        
    PPQrange = lastPPQ - firstPPQ    
    if PPQrange == 0 then return(0) end  
    
    --------------------------------------------------------------------
    
    function tilt7bitCC_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if window ~= "midi_editor" then return(0) end
        
        if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
        
        if SWS283 == true then
            _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end
        mouseTime = reaper.BR_GetMouseCursorContext_Position()
        mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
        
        if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1 then
            if mousePPQpos > (firstPPQ + lastPPQ)/2 then -- tilt righthand side    
                difference = ccLaneVal - tableCC[last].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(tableCC[i].PPQ-firstPPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 127)
                    newValue = math.max(newValue, 0)
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end
            else -- tilt lefthand side
                difference = ccLaneVal - tableCC[first].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(lastPPQ-tableCC[i].PPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 127)
                    newValue = math.max(newValue, 0)
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end  
            end
        end -- if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1
        
        reaper.defer(tilt7bitCC_loop)
            
    end -- function tilt7bitCC_loop
    
    tilt7bitCC_loop()
              
end -- function tilt7bitCC

--------------------------------------------------------------------

function tiltChanPressure() 
    
    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, mousePPQpos, newValue
        
    tableCC = {}
        
    eventIndex = reaper.MIDI_EnumSelCC(take, -1)
    while(eventIndex ~= -1) do
        _, _, _, ppqpos, chanmsg, _, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 13 then
            table.insert(tableCC, {index = eventIndex, 
                                 PPQ = ppqpos, 
                                 value = msg2})    
        end
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    if #tableCC == 0 then return(0) end

    first = 1
    last = 1
    firstPPQ = tableCC[first].PPQ
    lastPPQ  = tableCC[last].PPQ
    for i = 2, #tableCC do
        if tableCC[i].PPQ < firstPPQ then 
            firstPPQ = tableCC[i].PPQ
            first = i
        elseif tableCC[i].PPQ > lastPPQ then 
            lastPPQ = tableCC[i].PPQ
            last = i
        end
    end        
    PPQrange = lastPPQ - firstPPQ    
    if PPQrange == 0 then return(0) end
   
    --------------------------------------------------------------------
    
    function tiltChanPressure_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if window ~= "midi_editor" then return(0) end
        
        if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
        
        if SWS283 == true then
            _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end
        
        mouseTime = reaper.BR_GetMouseCursorContext_Position()
        mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
        
        if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1 then
            if mousePPQpos > (firstPPQ + lastPPQ)/2 then -- tilt righthand side    
                difference = ccLaneVal - tableCC[last].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(tableCC[i].PPQ-firstPPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 127)
                    newValue = math.max(newValue, 0)
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, 0, true)
                end
            else -- tilt lefthand side
                difference = ccLaneVal - tableCC[first].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(lastPPQ-tableCC[i].PPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 127)
                    newValue = math.max(newValue, 0)
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, 0, true)
                end  
            end
        end -- if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1
        
        reaper.defer(tiltChanPressure_loop)
            
    end -- function tiltChanPressure_loop
    
    tiltChanPressure_loop()
              
end -- function tiltChanPressure

--------------------------------------------------------------------

function tiltPitch()    

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, mousePPQpos, newValue
    
    tableCC = {}
        
    eventIndex = reaper.MIDI_EnumSelCC(take, -1)
    while(eventIndex ~= -1) do
        _, _, _, ppqpos, chanmsg, _, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 14 then
            table.insert(tableCC, {index = eventIndex, 
                                      PPQ = ppqpos, 
                                      value = (msg3*128) + msg2})     
        end
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    if #tableCC == 0 then return(0) end

    first = 1
    last = 1
    firstPPQ = tableCC[first].PPQ
    lastPPQ  = tableCC[last].PPQ
    for i = 2, #tableCC do
        if tableCC[i].PPQ < firstPPQ then 
            firstPPQ = tableCC[i].PPQ
            first = i
        elseif tableCC[i].PPQ > lastPPQ then 
            lastPPQ = tableCC[i].PPQ
            last = i
        end
    end            
    PPQrange = lastPPQ - firstPPQ
    if PPQrange == 0 then return(0) end
    
    --------------------------------------------------------------------
    
    function tiltPitch_loop()
                 
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if window ~= "midi_editor" then return(0) end
        
        if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
        
        if SWS283 == true then
            _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end
        
        mouseTime = reaper.BR_GetMouseCursorContext_Position()
        mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
    
        if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1 then
            if mousePPQpos > (firstPPQ + lastPPQ)/2 then -- tilt righthand side    
                difference = ccLaneVal - tableCC[last].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(tableCC[i].PPQ-firstPPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 16383)
                    newValue = math.max(newValue, 0)
                    newMSB = newValue>>7
                    newLSB = newValue&127
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newLSB, newMSB, true)
                end
            else -- tilt lefthand side
                difference = ccLaneVal - tableCC[first].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(lastPPQ-tableCC[i].PPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 16383)
                    newValue = math.max(newValue, 0)
                    newMSB = newValue>>7
                    newLSB = newValue&127
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newLSB, newMSB, true)
                end   
            end
            
        end -- if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1
      
        reaper.defer(tiltPitch_loop)
    
    end -- function tiltPitch_loop
    
    tiltPitch_loop()
    
end -- function tiltPitch

--------------------------------------------------------------------

function tiltVelocity()  

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, mousePPQpos, newValue
  
    tableCC = {}
        
    eventIndex = reaper.MIDI_EnumSelNotes(take, -1)
    while(eventIndex ~= -1) do
        _, _, _, startppq, _, _, _, vel = reaper.MIDI_GetNote(take, eventIndex)
        table.insert(tableCC, {index = eventIndex, 
                             PPQ = startppq, 
                             value = vel})   
        eventIndex = reaper.MIDI_EnumSelNotes(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    if #tableCC == 0 then return(0) end

    first = 1
    last = 1
    firstPPQ = tableCC[first].PPQ
    lastPPQ  = tableCC[last].PPQ
    for i = 2, #tableCC do
        if tableCC[i].PPQ < firstPPQ then 
            firstPPQ = tableCC[i].PPQ
            first = i
        elseif tableCC[i].PPQ > lastPPQ then 
            lastPPQ = tableCC[i].PPQ
            last = i
        end
    end        
    PPQrange = lastPPQ - firstPPQ  
    if PPQrange == 0 then return(0) end 
   
    --------------------------------------------------------------------
    
    function tiltVelocity_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if window ~= "midi_editor" then return(0) end
        
        if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
        
        if SWS283 == true then
            _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end

        mouseTime = reaper.BR_GetMouseCursorContext_Position()
        mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
        
        if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1 then
            if mousePPQpos > (firstPPQ + lastPPQ)/2 then -- tilt righthand side    
                difference = ccLaneVal - tableCC[last].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(tableCC[i].PPQ-firstPPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 127)
                    newValue = math.max(newValue, 1) -- Zero velocity = Note Off, so minimum is 1
                    reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end
            else -- tilt lefthand side
                difference = ccLaneVal - tableCC[first].value
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + difference*(lastPPQ-tableCC[i].PPQ)/PPQrange + 0.5)
                    newValue = math.min(newValue, 127)
                    newValue = math.max(newValue, 1) -- Zero velocity = Note Off, so minimum is 1
                    reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end  
            end
        end -- if details == "cc_lane" and ccLane == mouseLane and ccLaneVal ~= -1
        
        reaper.defer(tiltVelocity_loop)
            
    end -- function tiltVelocity_loop
    
    tiltVelocity_loop()
              
end -- function tiltVelocity

--------------------------------------------------------------------

function exit()
    reaper.MIDI_Sort(take)
    
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 
        and (prevToggleState == 0 or prevToggleState == 1) 
        then
        reaper.SetToggleCommandState(sectionID, cmdID, prevToggleState)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
            
    if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
        reaper.Undo_OnStateChange("Tilt selected 7-bit CC events in lane ".. mouseLane, -1)
    elseif mouseLane == 0x203 then -- Channel pressure
        reaper.Undo_OnStateChange("Tilt selected channel pressure events", -1)
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        reaper.Undo_OnStateChange("Tilt selected 14 bit CC events in lanes ".. 
                                  tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224))
    elseif mouseLane == 0x201 then
        reaper.Undo_OnStateChange("Tilt selected pitchbend events", -1)
    elseif mouseLane == 0x200 or mouseLane == 0x207 then
        reaper.Undo_OnStateChange("Tilt selected velocities", -1)
    end
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

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()    
    
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
    reaper.ShowConsoleMsg("\n\nERROR:\nCould not determine compatible SWS version.")
    return(0)
end

if SWS283 == true then
    _, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, _, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
end

--------------------------------------------------------------------
-- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
-- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
-- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
--
-- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc
    
-- Now stuff start to happen so toggle toolbar button (if any) and define atexit
_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end
    
reaper.atexit(exit)

-- Since 7bit CC, 14bit CC, channel pressure, velocity and pitch all 
--     require somewhat different tweaks, the code is simpler to read 
--     if divided into separate functions.    
if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
    tilt7bitCC()
elseif mouseLane == 0x203 then -- Channel pressure
    tiltChanPressure()
elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
    tilt14bitCC()
elseif mouseLane == 0x201 then
    tiltPitch()
elseif mouseLane == 0x200 or mouseLane == 0x207 then
    tiltVelocity()
else
    return(0)    
end

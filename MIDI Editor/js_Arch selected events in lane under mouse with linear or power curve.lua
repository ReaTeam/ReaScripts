--[[
 * ReaScript Name:  js_Arch selected events in lane under mouse with linear or power curve.lua
 * Description:  Arch selected CCs or velocities in lane under mouse towards mouse position, using a linear or power curve.
 *               The shape of the curve can be changed with the mousewheel.
 * Instructions:  There are two ways in which this script can be run:  
 *                  1) First, the script can be linked to its own shortcut key (such as "Ctrl+C"), in which case
 *                      it must also be linked to a mousewheel shortcut (such as Ctrl+mousewheel).
 *                      The script can be started using either of these shortcuts,
 *                         but can only be quit using keyboard shortcut (or by moving the mouse out of the MIDI editor)
 *.
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
 *                The position of the mouse determines the position to which the MIDI events are arched.
 *                The mousewheel controls the shape of the curve (from linear to parabolic and other power curves). 
 *
 *                Note: Since this function is a user script, the way it responds to shortcut keys and 
 *                    mouse buttons is opposite to that of REAPER's built-in mouse actions 
 *                    with mouse modifiers:  To run the script, press the shortcut key *once* 
 *                    to start the script and then move the mouse or mousewheel *without* pressing any 
 *                    mouse buttons.  Press the shortcut key again once to stop the script.  
 *                (The first time that the script is stopped, REAPER will pop up a dialog box 
 *                    asking whether to terminate or restart the script.  Select "Terminate"
 *                    and "Remember my answer for this script".)
 *
 *                The user can customize the speed and resolution of arching by 
 *                    changing the "archResolution" variable.
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
 * v1.0 (2016-07-08)
    + Initial Release
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
]]

-- USER AREA:
-- Settings that the user can customize
    
    -- The speed/resolution of archingion using mousewheel. 
    --    Lower values imply finer resolution but slower speed.
    --    Usable values are 0.01 ... 0.1.
    archResolution = 0.02

-- End of USER AREA


--------------------------------------------------------------------

function arch()  

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, newMousePPQpos, newValue, 
          newMouseCCvalue, newMouseLane          

    tableCC = {}
    
    if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
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
        
    elseif mouseLane == 0x203 then -- Channel pressure
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
        
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        -- All selected events in the MSB and LSB lanes will be stored in 
        --     separate temporary tables.  These tables will then be searched to
        --     find the LSB and MSB events that fall on the same ppq, 
        --     which means that they combine to form one 14-bit CC event.
        local tempTableLSB = {}
        local tempTableMSB = {}
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
                    table.insert(tableCC, {PPQ = tempTableLSB[l].PPQ,
                                           MSBindex = tempTableMSB[m].index,
                                           LSBindex = tempTableLSB[l].index,
                                           value = tempTableMSB[m].value*128 + tempTableLSB[l].value
                                 })
                end -- if
            end -- #tempTableMSB
        end -- #tempTableLSB
        
    elseif mouseLane == 0x201 then -- Pitch
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
            
    elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or Off-velocity
        eventIndex = reaper.MIDI_EnumSelNotes(take, -1)
        while(eventIndex ~= -1) do
            _, _, _, startppq, _, _, _, vel = reaper.MIDI_GetNote(take, eventIndex)
            table.insert(tableCC, {index = eventIndex, 
                                 PPQ = startppq, 
                                 value = vel})   
            eventIndex = reaper.MIDI_EnumSelNotes(take, eventIndex)            
        end -- while(eventIndex ~= -1)  
                         
    end
    
    if #tableCC <= 2 then return(0) end
    
    local function sortPPQ(a, b)
        if a.PPQ < b.PPQ then return true end
    end

    table.sort(tableCC, sortPPQ)

    if tableCC[#tableCC].PPQ == tableCC[1].PPQ then return(0) end
        
    --------------------------------------------------------------------
    
    function arch_loop()
        local _, details, newMousePPQpos, newMouseLane, is_new, val, scriptVal
      
        _, _, details = reaper.BR_GetMouseCursorContext()
        if details ~= "cc_lane" then return(0) end

        if SWS283 == true then
            _, _, newMouseLane, newMouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, _, newMouseLane, newMouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end
        
        if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
        
        newMousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())              
        
        is_new,_,_,_,_,_,val = reaper.get_action_context()
            if not is_new then val = 0 end
        scriptVal = tonumber(reaper.GetExtState("js_Mouse actions", "Mousewheel"))
            if scriptVal == nil then scriptVal = 0 end
        reaper.SetExtState("js_Mouse actions", "Mousewheel", "0", false)
        
        -- Only do something if mouse position or mousewheel has changed, but mouse is still in original CC lane
        if (is_new or scriptVal ~= 0 -- mousewheel has been moved
            or newMousePPQpos ~= prevMousePPQpos or newMouseCCvalue ~= prevMouseCCvalue) -- mouse has moved
            and not (newMouseLane ~= mouseLane or newMouseCCvalue == -1) -- don't do anything if moved out of CC lane
            then
            
            prevMousePPQpos = newMousePPQpos
            prevMouseCCvalue = newMouseCCvalue
            
            -- Apply mousewheel movement - be careful that power does not reach 0.
            if scriptVal > 0                     then wheel = wheel * (1+archResolution)
            elseif scriptVal < 0 and wheel > 0.1 then wheel = wheel / (1+archResolution)
            elseif val > 0                       then wheel = wheel * (1+archResolution)
            elseif val < 0 and wheel > 0.1       then wheel = wheel / (1+archResolution)
            end

            local firstPPQ = tableCC[1].PPQ
            local lastPPQ = tableCC[#tableCC].PPQ
            local ceilIndex
            local floorIndex
            local apexHeight
            
            if firstPPQ < newMousePPQpos and newMousePPQpos < lastPPQ then
                -- Use binary search to find event closest to left of mouse.        
                ceilIndex = #tableCC -- eventually the event at this index will be at or just to the right of the mouse
                floorIndex = 1
                while (ceilIndex-floorIndex)>1 do
                    middleIndex = (ceilIndex+floorIndex)//2 -- middle index
                    if tableCC[middleIndex].PPQ > newMousePPQpos then
                        ceilIndex = middleIndex
                    else
                        floorIndex = middleIndex
                    end     
                end -- while (ceilIndex-floorIndex)>1
                
                if tableCC[ceilIndex].PPQ == tableCC[floorIndex].PPQ then -- This should never occur, but just to make sure
                    apexHeight = newMouseCCvalue - tableCC[ceilIndex].PPQ
                else -- Take weighted average between values of ceil and floor CCs
                    apexHeight = newMouseCCvalue 
                                  - tableCC[floorIndex].value 
                                  + (tableCC[ceilIndex].value - tableCC[floorIndex].value)
                                  *(newMousePPQpos - tableCC[floorIndex].PPQ)/(tableCC[ceilIndex].PPQ - tableCC[floorIndex].PPQ)
                end
                                  
            elseif newMousePPQpos <= firstPPQ then
                apexHeight = newMouseCCvalue - tableCC[1].value
                ceilIndex = 1
            else -- newMousePPQpos >= lastPPQ
                apexHeight = newMouseCCvalue - tableCC[#tableCC].value
                floorIndex = #tableCC
            end              
            
            local leftPPQrange = newMousePPQpos - firstPPQ
            local rightPPQrange = lastPPQ - newMousePPQpos 

            local newValue 
            
            if wheel >= 1 then -- A power > 1 gives a more musical shape, therefore
                if newMousePPQpos > firstPPQ then      
                    for i = 1, floorIndex do
                        newValue = tableCC[i].value + apexHeight*(((tableCC[i].PPQ - firstPPQ)/leftPPQrange)^wheel)
                        
                        if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                        elseif mouseLane == 0x203 then -- Channel pressure
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, nil, true)
                        elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue>>7, true)
                            reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue&127, true)
                        elseif mouseLane == 0x201 then -- Pitch
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue&127, newValue>>7, true)
                        elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or Off-velocity
                            newValue = math.max(1, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)                    
                        end
                    end
                end
                
                if newMousePPQpos < lastPPQ then                
                    for i = ceilIndex, #tableCC do
                        newValue = tableCC[i].value + apexHeight*(((lastPPQ - tableCC[i].PPQ)/rightPPQrange)^wheel)
                        
                        if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                        elseif mouseLane == 0x203 then -- Channel pressure
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, nil, true)
                        elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue>>7, true)
                            reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue&127, true)
                        elseif mouseLane == 0x201 then -- Pitch
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue&127, newValue>>7, true)
                        elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or Off-velocity
                            newValue = math.max(1, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)                    
                        end               
                    end
                end
                
            else
                local inverseWheel = 1.0/wheel
                
                if newMousePPQpos > firstPPQ then
                    for i = 1, floorIndex do
                        newValue = tableCC[i].value + apexHeight - apexHeight*(((newMousePPQpos - tableCC[i].PPQ)/leftPPQrange)^inverseWheel)
                        
                        if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                        elseif mouseLane == 0x203 then -- Channel pressure
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, nil, true)
                        elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue>>7, true)
                            reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue&127, true)
                        elseif mouseLane == 0x201 then -- Pitch
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue&127, newValue>>7, true)
                        elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or Off-velocity
                            newValue = math.max(1, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)                    
                        end
                    end
                end
                
                if newMousePPQpos < lastPPQ then
                    for i = ceilIndex, #tableCC do
                        newValue = tableCC[i].value + apexHeight - apexHeight*(((tableCC[i].PPQ - newMousePPQpos)/rightPPQrange)^inverseWheel)
                        
                        if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                        elseif mouseLane == 0x203 then -- Channel pressure
                            newValue = math.max(0, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, nil, true)
                        elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue>>7, true)
                            reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue&127, true)
                        elseif mouseLane == 0x201 then -- Pitch
                            newValue = math.max(0, math.min(16383, math.floor(newValue+0.5)))
                            reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue&127, newValue>>7, true)
                        elseif mouseLane == 0x200 or mouseLane == 0x207 then -- Velocity or Off-velocity
                            newValue = math.max(1, math.min(127, math.floor(newValue+0.5)))
                            reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)                    
                        end                
                    end
                end
            end
            
        end -- if something changed
        
        reaper.defer(arch_loop)
            
    end -- function arch_loop
    
    -- Call the subroutine that will be 'deferred'
    -- Reset the mousewheel before calling
    is_new,_,_,_,_,_,val = reaper.get_action_context()
    wheel = 1 -- A factor of 1 means no change
    arch_loop()
              
end -- function arch

--------------------------------------------------------------------


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
        reaper.Undo_OnStateChange("Arch selected 7-bit CC events in lane ".. mouseLane, -1)
    elseif mouseLane == 0x203 then -- Channel pressure
        reaper.Undo_OnStateChange("Arch selected channel pressure events", -1)
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        reaper.Undo_OnStateChange("Arch selected 14 bit CC events in lanes ".. 
                                  tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224))
    elseif mouseLane == 0x201 then
        reaper.Undo_OnStateChange("Arch selected pitchbend events", -1)
    elseif mouseLane == 0x200 or mouseLane == 0x207 then
        reaper.Undo_OnStateChange("Arch selected velocities", -1)
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
    reaper.ShowConsoleMsg("Error: Could not determine compatible SWS version")
    return(0)
end

-- Function should only run if mouse is in a CC lane
-- atexit has not yet been defined, so if function exists here,
--     it will skip atexit. s
if SWS283 == true then
    _, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, _, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
end
if mouseCCvalue == -1 then return(0) end 

mouseTime = reaper.BR_GetMouseCursorContext_Position() 
mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
   

--------------------------------------------------------------------
-- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
-- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
-- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
--
-- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc
    
_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end
    
reaper.atexit(exit)

archResolution = math.max(0.01, math.min(0.1, archResolution))
    

-- This script works in 7-bit CC lanes, 14-bit CC, pitch, channel pressure and velocity
if (0 <= mouseLane and mouseLane <= 127) -- CC, 7 bit (single lane)
    or mouseLane == 0x203 -- Channel pressure
    or (256 <= mouseLane and mouseLane <= 287) -- CC, 14 bit (double lane)
    or mouseLane == 0x201 -- pitchwheel
    or (mouseLane == 0x200 or mouseLane == 0x207) -- Velocity or off-velocity
    then
    arch()
else
    return(0)    
end


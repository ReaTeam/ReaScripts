--[[
 * ReaScript Name:  Tilt selected events in lane under mouse to mouse position
 * Description:  A simple script for linear tilting of selected events.  
 *               The script only affects events in the MIDI editor lane that is under the mouse cursor.
 *               The script can be used in 7-bit CC lanes, 14-bit CC lanes, velocity, pitchwheel and channel pressure.
 * Instructions:  
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
 * v1.0 (2016-05-15)
    + Initial Release
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
    
    --------------------------------------------------------------------
    
    function tilt14bitCC_loop()
    
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
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
    
    --------------------------------------------------------------------
    
    function tilt7bitCC_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
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
   
    --------------------------------------------------------------------
    
    function tiltChanPressure_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
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
    
    --------------------------------------------------------------------
    
    function tiltPitch_loop()
                 
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
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
   
    --------------------------------------------------------------------
    
    function tiltVelocity_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, ccLane, ccLaneVal, _ = reaper.BR_GetMouseCursorContext_MIDI()
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

--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
    
editor = reaper.MIDIEditor_GetActive()
if editor == nil then return(0) end
take = reaper.MIDIEditor_GetTake(editor)
if take == nil then return(0) end
_, _, details = reaper.BR_GetMouseCursorContext()
if details ~= "cc_lane" then return(0) end 
_, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()

--------------------------------------------------------------------
-- mouseLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
-- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
-- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
--
-- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc
    
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

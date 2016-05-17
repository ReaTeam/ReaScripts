--[[
 * ReaScript Name:  Compress or expand CC or velocity using mousewheel
 * Description:  Compress or expand CC or velocity using mousewheel
 * Instructions:  The script must be linked to TWO shortcuts: 
 *                1) a keyboard shortcut (such as Alt+C)
 *                2) a mousewheel shortcut (such as Alt+Mousewheel)
 *                The script can be started using either of these shortcuts,
 *                    but can only be quit using keyboard shortcut 
 *                    (or by moving the mouse out of the MIDI editor)
 *
 *                If the mouse is positioned within the time range of the selected
 *                    events, all the events are compressed together.  
 *                If the mouse is positioned outside this range, events closest
 *                    to the mouse position (in time) are compressed more.
 *
 *                The vertical position of the mouse determines the value
 *                    to of from which the MIDI events are compressed or expanded.
 *                The mousewheel controls the extent of compression
 *                    or expansion.
 *                The shape of the compression is changed (from linear to 
 *                    parabolic) by moving the mouse left or right.  
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
 * v1.0 (2016-05-15)
    + Initial Release
]]

     

function compress14bitCC()    

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, newMouseTime, newMousePPQpos, newValue, 
          prevMousePPQpos, prevMouseCCvalue, newMouseCCvalue, newMouseLane
                  
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
    
    function compress14bitCC_loop()
    
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, newMouseLane, newMouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
        newMouseTime = reaper.BR_GetMouseCursorContext_Position()
        newMousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, newMouseTime)              
        is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
        
        if details ~= "cc_lane" then return(0) end

        -- Only do something if mouse position or mousewheel has changed, but mouse is still in original CC lane
        if (is_new or newMousePPQpos ~= prevMousePPQpos or newMouseCCvalue ~= prevMouseCCvalue)
        and not (newMouseLane ~= mouseLane or newMouseCCvalue == -1) then
        
            prevMousePPQpos = newMousePPQpos
            prevMouseCCvalue = newMouseCCvalue
            
            if val > 0 then wheel = wheel + 0.1
            elseif val < 0 then wheel = wheel - 0.1
            end
            wheel = math.max(wheel, -1) -- A factor of -1 means fully compressed.  Expansion can go to infinity.

            -- Why use absolute value and then later distinguish between neg and pos mouseMovement?  
            --     Since power < 1 gives a nicer shape.
            mouseMovement = (newMousePPQpos-mousePPQpos)/PPQrange
            warp = math.log(0.5, math.max(0.01, math.min(0.99, 0.5+math.abs(mouseMovement))))
            
            if mousePPQpos > lastPPQ then -- compress righthand side    
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)
                    else 
                        factor = -wheel*(1 - ((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 16383))
                    reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue>>7, true)
                    reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue&127, true)                end
            elseif mousePPQpos < firstPPQ then -- compress lefthand side
                difference = newMouseCCvalue - tableCC[first].value
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(1 - ((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)                    
                    else 
                        factor = -wheel*(((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 16383))
                    reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue>>7, true)
                    reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue&127, true)
                end  
            else -- compress everything together
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*(-wheel) + 0.5)
                    newValue = math.max(0, math.min(newValue, 16383))
                    reaper.MIDI_SetCC(take, tableCC[i].MSBindex, nil, nil, nil, nil, nil, nil, newValue>>7, true)
                    reaper.MIDI_SetCC(take, tableCC[i].LSBindex, nil, nil, nil, nil, nil, nil, newValue&127, true)                end  
            end
            
        end -- if something changed         
        reaper.defer(compress14bitCC_loop) 
        
    end -- function compress14bitCC
    
    -- Call the subroutine that will be 'deferred'
    wheel = 0 -- A factor of 0 means no change
    compress14bitCC_loop()
    
end -- function compress14bitCC

--------------------------------------------------------------------

function compress7bitCC()  

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, newMouseTime, newMousePPQpos, newValue, 
          prevMousePPQpos, prevMouseCCvalue, newMouseCCvalue, newMouseLane
          
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
    
    function compress7bitCC_loop()
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, newMouseLane, newMouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
        newMouseTime = reaper.BR_GetMouseCursorContext_Position()
        newMousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, newMouseTime)              
        is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
        
        if details ~= "cc_lane" then return(0) end

        -- Only do something if mouse position or mousewheel has changed, but mouse is still in original CC lane
        if (is_new or newMousePPQpos ~= prevMousePPQpos or newMouseCCvalue ~= prevMouseCCvalue)
        and not (newMouseLane ~= mouseLane or newMouseCCvalue == -1) then
        
            prevMousePPQpos = newMousePPQpos
            prevMouseCCvalue = newMouseCCvalue
            
            if val > 0 then wheel = wheel + 0.1
            elseif val < 0 then wheel = wheel - 0.1
            end
            wheel = math.max(wheel, -1) -- A factor of -1 means fully compressed.  Expansion can go to infinity.

            -- Why use absolute value and then later distinguish between neg and pos mouseMovement?  
            --     Since power < 1 gives a nicer shape.
            mouseMovement = (newMousePPQpos-mousePPQpos)/PPQrange
            warp = math.log(0.5, math.max(0.01, math.min(0.99, 0.5+math.abs(mouseMovement))))
            
            if mousePPQpos > lastPPQ then -- compress righthand side    
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)
                    else 
                        factor = -wheel*(1 - ((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 127))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end
            elseif mousePPQpos < firstPPQ then -- compress lefthand side
                difference = newMouseCCvalue - tableCC[first].value
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(1 - ((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)                    
                    else 
                        factor = -wheel*(((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 127))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end  
            else -- compress everything together
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*(-wheel) + 0.5)
                    newValue = math.max(0, math.min(newValue, 127))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end  
            end
            
        end -- if something changed
        reaper.defer(compress7bitCC_loop)
            
    end -- function compress7bitCC_loop
    
    -- Call the subroutine that will be 'deferred'
    wheel = 0 -- A factor of 0 means no change
    compress7bitCC_loop()
              
end -- function compress7bitCC_setup

--------------------------------------------------------------------

function compressChanPressure() 
    
    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, newMouseTime, newMousePPQpos, newValue, 
          prevMousePPQpos, prevMouseCCvalue, newMouseCCvalue, newMouseLane
          
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
    
    prevMousePPQpos = mousePPQpos
   
    --------------------------------------------------------------------
    
    function compressChanPressure_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, newMouseLane, newMouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
        newMouseTime = reaper.BR_GetMouseCursorContext_Position()
        newMousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, newMouseTime)              
        is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
        
        if details ~= "cc_lane" then return(0) end

        -- Only do something if mouse position or mousewheel has changed, but mouse is still in original CC lane
        if (is_new or newMousePPQpos ~= prevMousePPQpos or newMouseCCvalue ~= prevMouseCCvalue)
        and not (newMouseLane ~= mouseLane or newMouseCCvalue == -1) then
        
            prevMousePPQpos = newMousePPQpos
            prevMouseCCvalue = newMouseCCvalue
            
            if val > 0 then wheel = wheel + 0.1
            elseif val < 0 then wheel = wheel - 0.1
            end
            wheel = math.max(wheel, -1) -- A factor of -1 means fully compressed.  Expansion can go to infinity.

            -- Why use absolute value and then later distinguish between neg and pos mouseMovement?  
            --     Since power < 1 gives a nicer shape.
            mouseMovement = (newMousePPQpos-mousePPQpos)/PPQrange
            warp = math.log(0.5, math.max(0.01, math.min(0.99, 0.5+math.abs(mouseMovement))))
            
            if mousePPQpos > lastPPQ then -- compress righthand side    
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)
                    else 
                        factor = -wheel*(1 - ((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 127))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, nil, true)
                end
            elseif mousePPQpos < firstPPQ then -- compress lefthand side
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(1 - ((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)                    
                    else 
                        factor = -wheel*(((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 127))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, nil, true)
                end  
            else -- compress everything together
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*(-wheel) + 0.5)
                    newValue = math.max(0, math.min(newValue, 127))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue, nil, true)
                end  
            end

        end -- if something changed
        reaper.defer(compressChanPressure_loop)
            
    end -- function compressChanPressure_loop

    -- Call the subroutine that will be 'deferred' 
    wheel = 0 -- A factor of 0 means no change
    compressChanPressure_loop()
              
end -- function compressChanPressure

--------------------------------------------------------------------

function compressPitch()    

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, newMouseTime, newMousePPQpos, newValue, 
          prevMousePPQpos, prevMouseCCvalue, newMouseCCvalue, newMouseLane
              
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
    
    function compressPitch_loop()
                 
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, newMouseLane, newMouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
        newMouseTime = reaper.BR_GetMouseCursorContext_Position()
        newMousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, newMouseTime)              
        is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
        
        if details ~= "cc_lane" then return(0) end

        -- Only do something if mouse position or mousewheel has changed, but mouse is still in original CC lane
        if (is_new or newMousePPQpos ~= prevMousePPQpos or newMouseCCvalue ~= prevMouseCCvalue)
        and not (newMouseLane ~= mouseLane or newMouseCCvalue == -1) then
        
            prevMousePPQpos = newMousePPQpos
            prevMouseCCvalue = newMouseCCvalue
            
            if val > 0 then wheel = wheel + 0.1
            elseif val < 0 then wheel = wheel - 0.1
            end
            wheel = math.max(wheel, -1) -- A factor of -1 means fully compressed.  Expansion can go to infinity.

            -- Why use absolute value and then later distinguish between neg and pos mouseMovement?  
            --     Since power < 1 gives a nicer shape.
            mouseMovement = (newMousePPQpos-mousePPQpos)/PPQrange
            warp = math.log(0.5, math.max(0.01, math.min(0.99, 0.5+math.abs(mouseMovement))))
            
            if mousePPQpos > lastPPQ then -- compress righthand side    
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)
                    else 
                        factor = -wheel*(1 - ((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 16383))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue&127, newValue>>7, true)
                end
            elseif mousePPQpos < firstPPQ then -- compress lefthand side
                difference = newMouseCCvalue - tableCC[first].value
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(1 - ((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)                    
                    else 
                        factor = -wheel*(((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(0, math.min(newValue, 16383))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue&127, newValue>>7, true)
                end  
            else -- compress everything together
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*(-wheel) + 0.5)
                    newValue = math.max(0, math.min(newValue, 16383))
                    reaper.MIDI_SetCC(take, tableCC[i].index, nil, nil, nil, nil, nil, newValue&127, newValue>>7, true)
                end  
            end
            
        end -- if something changed        
        
        reaper.defer(compressPitch_loop)
    
    end -- function compressPitch_loop
    
    wheel = 0 -- A factor of 0 means no change
    compressPitch_loop()
    
end -- function compressPitch

--------------------------------------------------------------------

function compressVelocity()  

    local tableCC, eventIndex, first, last, firstPPQ, lastPPQ, PPQrange, newMouseTime, newMousePPQpos, newValue, 
          prevMousePPQpos, prevMouseCCvalue, newMouseCCvalue, newMouseLane  
          
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
    
    function compressVelocity_loop()
                
        window, segment, details = reaper.BR_GetMouseCursorContext()
        _, _, newMouseLane, newMouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
        newMouseTime = reaper.BR_GetMouseCursorContext_Position()
        newMousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, newMouseTime)              
        is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
        
        if details ~= "cc_lane" then return(0) end

        -- Only do something if mouse position or mousewheel has changed, but mouse is still in original CC lane
        if (is_new or newMousePPQpos ~= prevMousePPQpos or newMouseCCvalue ~= prevMouseCCvalue)
        and not (newMouseLane ~= mouseLane or newMouseCCvalue == -1) then
        
            prevMousePPQpos = newMousePPQpos
            prevMouseCCvalue = newMouseCCvalue
            
            if val > 0 then wheel = wheel + 0.1
            elseif val < 0 then wheel = wheel - 0.1
            end
            wheel = math.max(wheel, -1) -- A factor of -1 means fully compressed.  Expansion can go to infinity.

            -- Why use absolute value and then later distinguish between neg and pos mouseMovement?  
            --     Since power < 1 gives a nicer shape.
            mouseMovement = (newMousePPQpos-mousePPQpos)/PPQrange
            warp = math.log(0.5, math.max(0.01, math.min(0.99, 0.5+math.abs(mouseMovement))))
            
            -- A note velocity of 0 means "note off", so unlike CCs, velocity uses a minimum of 1
            if mousePPQpos > lastPPQ then -- compress righthand side    
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)
                    else 
                        factor = -wheel*(1 - ((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(1, math.min(newValue, 127))
                    reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end
            elseif mousePPQpos < firstPPQ then -- compress lefthand side
                difference = newMouseCCvalue - tableCC[first].value
                for i = 1, #tableCC do
                    if mouseMovement >= 0 then
                        factor = -wheel*(1 - ((tableCC[i].PPQ - firstPPQ)/PPQrange)^warp)                    
                    else 
                        factor = -wheel*(((lastPPQ - tableCC[i].PPQ)/PPQrange)^warp)
                    end
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*factor + 0.5)
                    newValue = math.max(1, math.min(newValue, 127))
                    reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end  
            else -- compress everything together
                for i = 1, #tableCC do
                    newValue = math.floor(tableCC[i].value + (newMouseCCvalue-tableCC[i].value)*(-wheel) + 0.5)
                    newValue = math.max(1, math.min(newValue, 127))
                    reaper.MIDI_SetNote(take, tableCC[i].index, nil, nil, nil, nil, nil, nil, newValue, true)
                end  
            end
            
        end -- if something changed
        reaper.defer(compressVelocity_loop)
            
    end -- function compressVelocity_loop
    
    -- Call the subroutine that will be 'deferred' 
    wheel = 0 -- A factor of 0 means no change
    compressVelocity_loop()
              
end -- function compressVelocity

--------------------------------------------------------------------

function exit()
    reaper.MIDI_Sort(take)
    if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
        reaper.Undo_OnStateChange("Compress selected 7-bit CC events in lane ".. mouseLane, -1)
    elseif mouseLane == 0x203 then -- Channel pressure
        reaper.Undo_OnStateChange("Compress selected channel pressure events", -1)
    elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
        reaper.Undo_OnStateChange("Compress selected 14 bit CC events in lanes ".. 
                                  tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224))
    elseif mouseLane == 0x201 then
        reaper.Undo_OnStateChange("Compress selected pitchbend events", -1)
    elseif mouseLane == 0x200 or mouseLane == 0x207 then
        reaper.Undo_OnStateChange("Compress selected velocities", -1)
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
_, _, mouseLane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()     
mouseTime = reaper.BR_GetMouseCursorContext_Position() 
mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, mouseTime)
-- Function should only run if mouse is in a CC lane
-- atexit has not yet been defined, so if function exists here,
--     it will skip atexit.    
if details ~= "cc_lane" or take == nil or mouseCCvalue == -1 then return(0) end 

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
    compress7bitCC()
elseif mouseLane == 0x203 then -- Channel pressure
    compressChanPressure()
elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
    compress14bitCC()
elseif mouseLane == 0x201 then
    compressPitch()
elseif mouseLane == 0x200 or mouseLane == 0x207 then
    compressVelocity()
else
    return(0)    
end

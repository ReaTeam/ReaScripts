--[[
 * ReaScript Name:  js_Insert linear or shaped ramps between selected CCs or pitches in lane under mouse.lua
 * Description:   Useful for quickly adding ramps between 'nodes'.
 *                Useful for smoothing transitions between CCs that were drawn at low resolution.
 *
 *                The script starts with a dialog box in which the user can set:
 *                - the CC density, 
 *                - the shape of the ramp (as a linear or power function),
 *                - whether the new events should be selected, and
 *                - whether redundant events (that would duplicate the value of previous event) should be skipped.
 *                (Any extraneous CCs/pitchbend between selected events are deleted)
 *
 * Instructions:  For faster one-click execution, skip the dialog box by setting "showDialogBox" to "false" in the USER AREA.
 *                The default ramp properties can also be defined in the USER AREA.
 *                Combine with warping script to easily insert all kinds of weird shapes.
 *
 *                There are two ways in which this script can be run:  
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
 * v1.0 (2016-05-15)
    + Initial Release.
 * v1.1 (2016-05-18)
    + Added compatibility with SWS versions other than 2.8.3 (still compatible with v2.8.3).
 * v1.11 (2016-05-29)
    + Script does not fail when "Zoom dependent" CC density is selected in Preferences.
 * v1.12 (2016-06-08)
    + New options in USER AREA to define default shape and/or to skip dialog box.
    + More extensive error messages.
 * v1.13 (2016-06-13)
    + New shape, "sine".
 * v1.14 (2016-06-13)
    + Fixed deletion bug when inserting 14bit CC ramps.
 * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
]] 

-- USER AREA
-- (Settings that the user can customize)

showDialogBox = true -- Should the dialog box be skipped and default values used?  true or false.

verbose = true -- Should error messages be shown in REAPER's console?  true or false.

-- Default values for ramp shape:
shape = "sine" -- Shape of the ramp.  Either "sine", or a number>0 for a power curve (1 implies linear).
skipRedundantCCs = true -- Should redundant CCs be skipped?  true or false.
newCCsAreSelected = true -- Should the newly inserted CCs be selected?  true or false.

-- NOTE: The script uses the default CC density set in REAPER's Preferences -> MIDI editor -> Events per quarter note when drawing in CC lanes 


-- End of USER AREA
--------------------------------------------------------------------

  
--------------------------------------------------------------------

function drawRamp7bitCC()  
          
    -- All the selected events in the target lane will be stored in this table
    --    so that their properties can be accessed quicker, and so that they 
    --    can be re-inserted and selected after drawing the ramp.
    local tableCC = {}
        
    local eventIndex = reaper.MIDI_EnumSelCC(take, -1)
    local startChannel = false
    while(eventIndex ~= -1) do
        _, _, mute, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 11 and msg2 == mouseLane then
            if startChannel ~= false and startChannel ~= chan then
                reaper.ShowConsoleMsg("Error: All selected events should be in the same channel")
                return(0)
            else
            startChannel = chan
            table.insert(tableCC, {index = eventIndex, 
                                   PPQ = ppqpos, 
                                   value = msg3,
                                   muted = mute}) 
            end -- if startChannel ~= false and startChannel ~= chan
        end -- if (chanmsg>>4) == 11 and msg2 == mouseLane
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    -- If no selected events in lane
    if #tableCC == 0 then return(0) end 

    -- Function to sort the table of events 
    -- (in case REAPER's MIDI_Sort is not reliable.
    function sortPPQ(a, b)
        if a.PPQ < b.PPQ then return true else return false end
    end  
    table.sort(tableCC, sortPPQ)
    
    ---------------------------------------------
    -- Delete all events between selected events, 
    -- but only if same type, channel and lane
    reaper.MIDI_Sort(take)
    _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)
    for i = ccevtcnt-1, 0, -1 do     
        _, _, _, ppqpos, chanmsg, chan, msg2, _ = reaper.MIDI_GetCC(take, i)
        if ppqpos < tableCC[1].PPQ then break -- Once below range of selected events, no need to search further
        elseif ppqpos <= tableCC[#tableCC].PPQ
            and chan == startChannel -- same channel
            and msg2 == mouseLane -- in lane
            and chanmsg>>4 == 11 -- eventType is CC
            then
                reaper.MIDI_DeleteCC(take, i)
        end -- elseif
    end -- for i = ccevtcnt-1, 0, -1
    
    ----------------------------------------------------------------------------
    -- The main function that iterates through selected events and inserts ramps
    for i = 1, #tableCC-1 do

        if tableCC[i].PPQ ~= tableCC[i+1].PPQ then -- This is very weird, but can sometimes happen
        
            -- Calculate PPQ position of next grid beyond selected event
            eventQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, tableCC[i].PPQ)
            nextGridQN = QNgrid*math.ceil(eventQNpos/QNgrid)
            nextGridPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, nextGridQN) 
                  
            -- Insert the ramp of events
            prevCCvalue = tableCC[i].value
            for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid do
                -- REAPER will insert CCs on (rounded) integer PPQ values,
                --     so insertValue must be calculated at round(p).
                -- But lua does not have round function, so...
                local pRound = math.floor(p+0.5)
                
                -- New CCs should not be inserted at PPQ positions of selected nodes, otherwise the nodes may be overwritten.
                if pRound > tableCC[i].PPQ and pRound < tableCC[i+1].PPQ then
                    -- Calculate the interpolated CC values
                    if type(shape) == "number" then
                        weight = ((pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ))^shape
                    else -- shape == "sine"
                        weight = (1 - math.cos(math.pi*(pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ)))/2
                    end
                    insertValue = math.floor(tableCC[i].value + (tableCC[i+1].value - tableCC[i].value)*weight + 0.5)
                    -- If redundant, skip insertion
                    if not (skipRedundantCCs == true and insertValue == prevCCvalue) then
                        reaper.MIDI_InsertCC(take, newCCsAreSelected, tableCC[i].muted, pRound, 11<<4, startChannel, mouseLane, insertValue)
                        prevCCvalue = insertValue
                    end
                end
                        
            end -- for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid
    
        end -- if tableCC[i].PPQ ~= tableCC[i+1].PPQ
            
    end -- for i = 1, #tableCC-1
  
    -- And finally, re-insert the original selected events
    for i = 1, #tableCC do
        reaper.MIDI_InsertCC(take, true, tableCC[i].muted, tableCC[i].PPQ, 176, startChannel, mouseLane, tableCC[i].value)
    end  
               
end -- function drawRamp7bitCC
------------------------------


--------------------------------------------------------------------

function drawRampChanPressure()  
          
    local tableCC = {}
        
    local eventIndex = reaper.MIDI_EnumSelCC(take, -1)
    local startChannel = false
    while(eventIndex ~= -1) do
        _, _, mute, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 13 then -- MIDI event type = channel pressure
            if startChannel ~= false and startChannel ~= chan then
                reaper.ShowConsoleMsg("Error: All selected events should be in the same channel")
                return(0)
            else
            startChannel = chan
            table.insert(tableCC, {index = eventIndex, 
                                   PPQ = ppqpos, 
                                   value = msg2,
                                   muted = mute}) 
            end -- if startChannel ~= false and startChannel ~= chan
        end -- if (chanmsg>>4) == 13
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    -- If no selected events in lane
    if #tableCC == 0 then return(0) end 

    -- Function to sort the table of events 
    -- (in case REAPER's MIDI_Sort is not reliable.
    function sortPPQ(a, b)
        if a.PPQ < b.PPQ then return true else return false end
    end  
    table.sort(tableCC, sortPPQ)
    
    ---------------------------------------------
    -- Delete all events between selected events, 
    -- but only if same type, channel and lane
    reaper.MIDI_Sort(take)
    _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)
    for i = ccevtcnt-1, 0, -1 do     
        _, _, _, ppqpos, chanmsg, chan, msg2, _ = reaper.MIDI_GetCC(take, i)
        if ppqpos < tableCC[1].PPQ then break -- Once below range of selected events, no need to search further
        elseif ppqpos <= tableCC[#tableCC].PPQ
            and chan == startChannel -- same channel
            and chanmsg>>4 == 13 -- eventType is Channel Pressure
            then
                reaper.MIDI_DeleteCC(take, i)
        end -- elseif
    end -- for i = ccevtcnt-1, 0, -1
    
    ----------------------------------------------------------------------------
    -- The main function that iterates through selected events and inserts ramps
    for i = 1, #tableCC-1 do

        if tableCC[i].PPQ ~= tableCC[i+1].PPQ then -- This is very weird, but can sometimes happen
        
            -- Calculate PPQ position of next grid beyond selected event
            eventQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, tableCC[i].PPQ)
            nextGridQN = QNgrid*math.ceil(eventQNpos/QNgrid)
            nextGridPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, nextGridQN) 
                  
            -- Insert the ramp of events
            prevCCvalue = tableCC[i].value
            for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid do
                -- REAPER will insert CCs on (rounded) integer PPQ values,
                --     so insertValue must be calculated at round(p).
                -- But lua does not have round function, so...
                local pRound = math.floor(p+0.5)

                -- New CCs should not be inserted at PPQ positions of selected nodes, otherwise the nodes may be overwritten.
                if pRound > tableCC[i].PPQ and pRound < tableCC[i+1].PPQ then
                    -- Calculate the interpolated CC values
                    if type(shape) == "number" then
                        weight = ((pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ))^shape
                    else -- shape == "sine"
                        weight = (1 - math.cos(math.pi*(pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ)))/2
                    end
                    insertValue = math.floor(tableCC[i].value + (tableCC[i+1].value - tableCC[i].value)*weight + 0.5)
                    
                    -- If redundant, skip insertion
                    if not (skipRedundantCCs == true and insertValue == prevCCvalue) then
                        reaper.MIDI_InsertCC(take, newCCsAreSelected, tableCC[i].muted, pRound, 13<<4, startChannel, insertValue, 0)
                        prevCCvalue = insertValue
                    end
                end
                        
            end -- for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid

        end -- if tableCC[i].PPQ ~= tableCC[i+1].PPQ
        
    end -- for i = 1, #tableCC-1
  
    -- And finally, re-insert the original selected events
    for i = 1, #tableCC do
        reaper.MIDI_InsertCC(take, true, tableCC[i].muted, tableCC[i].PPQ, 13<<4, startChannel, tableCC[i].value, 0)
    end  
               
end -- function drawRampChanPressure
------------------------------------


--------------------------------------------------------------------

function drawRampPitch()  
          
    local tableCC = {}
        
    local eventIndex = reaper.MIDI_EnumSelCC(take, -1)
    local startChannel = false
    while(eventIndex ~= -1) do
        _, _, mute, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 14 then
            if startChannel ~= false and startChannel ~= chan then
                reaper.ShowConsoleMsg("Error: All selected events should be in the same channel")
                return(0)
            else
            startChannel = chan
            table.insert(tableCC, {index = eventIndex, 
                                   PPQ = ppqpos, 
                                   value = msg3*128 + msg2,
                                   muted = mute}) 
            end -- if startChannel ~= false and startChannel ~= chan
        end -- if (chanmsg>>4) == 11 and msg2 == mouseLane
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    -- If no selected events in lane
    if #tableCC == 0 then return(0) end 

    -- Function to sort the table of events 
    -- (in case REAPER's MIDI_Sort is not reliable.
    function sortPPQ(a, b)
        if a.PPQ < b.PPQ then return true else return false end
    end  
    table.sort(tableCC, sortPPQ)
    
    ---------------------------------------------
    -- Delete all events between selected events, 
    -- but only if same type, channel and lane
    reaper.MIDI_Sort(take)
    _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)
    for i = ccevtcnt-1, 0, -1 do     
        _, _, _, ppqpos, chanmsg, chan, _, _ = reaper.MIDI_GetCC(take, i)
        if ppqpos < tableCC[1].PPQ then break -- Once below range of selected events, no need to search further
        elseif ppqpos <= tableCC[#tableCC].PPQ
            and chan == startChannel -- same channel
            and chanmsg>>4 == 14 -- eventType is pitchwheel
            then
                reaper.MIDI_DeleteCC(take, i)
        end -- elseif
    end -- for i = ccevtcnt-1, 0, -1
    
    ----------------------------------------------------------------------------
    -- The main function that iterates through selected events and inserts ramps
    for i = 1, #tableCC-1 do

        if tableCC[i].PPQ ~= tableCC[i+1].PPQ then -- This is very weird, but can sometimes happen
            -- Calculate PPQ position of next grid beyond selected event
            eventQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, tableCC[i].PPQ)
            nextGridQN = QNgrid*math.ceil(eventQNpos/QNgrid)
            nextGridPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, nextGridQN) 
                  
            -- Insert the ramp of events
            prevCCvalue = tableCC[i].value
            for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid do
                -- REAPER will insert CCs on (rounded) integer PPQ values,
                --     so insertValue must be calculated at round(p).
                -- But lua does not have round function, so...
                local pRound = math.floor(p+0.5)
                
                -- New CCs should not be inserted at PPQ positions of selected nodes, otherwise the nodes may be overwritten.
                if pRound > tableCC[i].PPQ and pRound < tableCC[i+1].PPQ then
                    -- Calculate the interpolated CC values
                    if type(shape) == "number" then
                        weight = ((pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ))^shape
                    else -- shape == "sine"
                        weight = (1 - math.cos(math.pi*(pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ)))/2
                    end
                    insertValue = math.floor(tableCC[i].value + (tableCC[i+1].value - tableCC[i].value)*weight + 0.5)
                    
                    -- If redundant, skip insertion
                    if not (skipRedundantCCs == true and insertValue == prevCCvalue) then
                        reaper.MIDI_InsertCC(take, newCCsAreSelected, tableCC[i].muted, pRound, 14<<4, startChannel, insertValue&127, insertValue>>7)
                        prevCCvalue = insertValue
                    end
                end
                              
            end -- for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid
        
        end -- if tableCC[i].PPQ ~= tableCC[i+1].PPQ
            
    end -- for i = 1, #tableCC-1
  
    -- And finally, re-insert the original selected events
    for i = 1, #tableCC do
        reaper.MIDI_InsertCC(take, true, tableCC[i].muted, tableCC[i].PPQ, 14<<4, startChannel, (tableCC[i].value)&127, (tableCC[i].value)>>7)
    end  
               
end -- function drawRampPitch
------------------------------


--------------------------------------------------------------------

function drawRamp14bitCC()  
                  
    -- All selected events in the MSB and LSB lanes will be stored in 
    --     separate temporary tables.  These tables will then be searched to
    --     find the LSB and MSB events that fall on the same ppq, 
    --     which means that they combine to form one 14-bit CC event.
    local tempTableLSB = {}
    local tempTableMSB = {}
    local tableCC = {}
        
    local eventIndex = reaper.MIDI_EnumSelCC(take, -1)
  
    while(eventIndex ~= -1) do
        _, _, mute, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, eventIndex)
        if (chanmsg>>4) == 11 and  msg2 == mouseLane-256 then -- 14bit MSB
            table.insert(tempTableMSB, {index = eventIndex, 
                                        PPQ = ppqpos, 
                                        value = msg3,
                                        channel = chan,
                                        muted = mute})
        elseif (chanmsg>>4) == 11 and msg2 == mouseLane-224 then -- 14bit LSB
            table.insert(tempTableLSB, {index = eventIndex, 
                                        PPQ = ppqpos, 
                                        value = msg3,
                                        channel = chan})
        end
        eventIndex = reaper.MIDI_EnumSelCC(take, eventIndex)            
    end -- while(eventIndex ~= -1)
    
    -- Now, find the LSB and MSB events that fall on the same ppq
    startChannel = false
    for l = 1, #tempTableLSB do
        for m = 1, #tempTableMSB do
            if tempTableLSB[l].PPQ == tempTableMSB[m].PPQ and tempTableLSB[l].channel == tempTableMSB[m].channel then
                if startChannel ~= false and startChannel ~= tempTableLSB[l].channel then
                    reaper.ShowConsoleMsg("Error: All selected events should be in the same channel")
                    return(0)
                else
                startChannel = tempTableLSB[l].channel
                table.insert(tableCC, {
                             PPQ = tempTableLSB[l].PPQ,
                             MSBindex = tempTableMSB[m].index,
                             LSBindex = tempTableLSB[l].index,
                             value = tempTableMSB[m].value*128 + tempTableLSB[l].value,
                             muted = tempTableMSB[m].muted})
                end -- if startChannel ~= false and startChannel ~= tempTableLSB[l].channel
            end -- if tempTableLSB[l].PPQ == tempTableMSB[m].PPQ
        end -- #tempTableMSB
    end -- #tempTableLSB
    
    -- If no selected events in lane
    if #tableCC == 0 then return(0) end 

    -- Function to sort the table of events 
    -- (in case REAPER's MIDI_Sort is not reliable.
    function sortPPQ(a, b)
        if a.PPQ < b.PPQ then return true else return false end
    end  
    table.sort(tableCC, sortPPQ)
    
    ---------------------------------------------
    -- Delete all events between selected events, 
    -- but only if same type, channel and lane
    reaper.MIDI_Sort(take)
    _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)
    for i = ccevtcnt-1, 0, -1 do     
        _, _, _, ppqpos, chanmsg, chan, msg2, _ = reaper.MIDI_GetCC(take, i)
        if ppqpos < tableCC[1].PPQ then break -- Once below range of selected events, no need to search further
        elseif ppqpos <= tableCC[#tableCC].PPQ
            and chan == startChannel -- same channel
            and (msg2 == mouseLane-256 or msg2 == mouseLane-224) -- in either MSB or LSB lane
            and chanmsg>>4 == 11 -- eventType is CC
            then
                reaper.MIDI_DeleteCC(take, i)
        end -- elseif
    end -- for i = ccevtcnt-1, 0, -1
  
    ----------------------------------------------------------------------------
    -- The main function that iterates through selected events and inserts ramps
    for i = 1, #tableCC-1 do
        
        if tableCC[i].PPQ ~= tableCC[i+1].PPQ then -- This is very weird, but can sometimes happen
            -- Calculate PPQ position of next grid beyond selected event
            eventQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, tableCC[i].PPQ)
            nextGridQN = QNgrid*math.ceil(eventQNpos/QNgrid)
            nextGridPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, nextGridQN) 
                  
            -- Insert the ramp of events
            prevCCvalue = tableCC[i].value
            for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid do
                -- REAPER will insert CCs on (rounded) integer PPQ values,
                --     so insertValue must be calculated at round(p).
                -- But lua does not have round function, so...
                local pRound = math.floor(p+0.5)
                
                -- New CCs should not be inserted at PPQ positions of selected nodes, otherwise the nodes may be overwritten.
                if pRound > tableCC[i].PPQ and pRound < tableCC[i+1].PPQ then
                    -- Calculate the interpolated CC values
                    if type(shape) == "number" then
                        weight = ((pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ))^shape
                    else -- shape == "sine"
                        weight = (1 - math.cos(math.pi*(pRound - tableCC[i].PPQ) / (tableCC[i+1].PPQ - tableCC[i].PPQ)))/2
                    end
                    insertValue = math.floor(tableCC[i].value + (tableCC[i+1].value - tableCC[i].value)*weight + 0.5)
                    
                    -- If redundant, skip insertion
                    if not (skipRedundantCCs == true and insertValue == prevCCvalue) then
                        reaper.MIDI_InsertCC(take, newCCsAreSelected, tableCC[i].muted, pRound, 11<<4, startChannel, mouseLane-256, insertValue>>7)
                        reaper.MIDI_InsertCC(take, newCCsAreSelected, tableCC[i].muted, pRound, 11<<4, startChannel, mouseLane-224, insertValue&127)
                        prevCCvalue = insertValue
                    end
                end
                        
            end -- for p = nextGridPPQ, tableCC[i+1].PPQ, PPgrid
    
        end -- if tableCC[i].PPQ ~= tableCC[i+1].PPQ
        
    end -- for i = 1, #tableCC-1
  
    -- And finally, re-insert the original selected events
    for i = 1, #tableCC do
        reaper.MIDI_InsertCC(take, true, tableCC[i].muted, tableCC[i].PPQ, 11<<4, startChannel, mouseLane-256, (tableCC[i].value)>>7)
        reaper.MIDI_InsertCC(take, true, tableCC[i].muted, tableCC[i].PPQ, 11<<4, startChannel, mouseLane-224, (tableCC[i].value)&127)
   end  
               
end -- function drawRamp14bitCC
-------------------------------


-------------------------------
function showErrorMsg(errorMsg)
    if verbose == true and type(errorMsg) == "string" then
        reaper.ShowConsoleMsg("\n\nERROR:\n" 
                              .. errorMsg 
                              .. "\n\n"
                              .. "(To prevent future error messages, set 'verbose' to 'false' in the USER AREA near the beginning of the script.)"
                              .. "\n\n")
    end
end -- showErrorMsg(errorMsg)

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

---------------------------------------------------------------------
-- Here the code execustion starts
---------------------------------------------------------------------
-- function main()

-- Trying a trick to prevent creation of new undo state 
--     if code does not reach own Undo_BeginBlock
function noUndo()
end
reaper.defer(noUndo)

reaper.DeleteExtState("js_Mouse actions", "Status", true)

-- Test whether user customizable variables are usable
if type(verbose) ~= "boolean" then 
    reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'verbose' must be either 'true' of 'false'.\n") return(false) end
if (shape ~= "sine" and type(shape) ~= "number") or (type(shape)=="number" and shape <= 0) then 
    reaper.ShowConsoleMsg('\n\nERROR: \nThe setting "shape" must either be "sine" or a number larger than 0.\n') return(false) end
if type(skipRedundantCCs) ~= "boolean" then 
    reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'skipRedundantCCs' must be either 'true' of 'false'.\n") return(false) end
if type(newCCsAreSelected) ~= "boolean" then
    reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'newCCsAreSelected' must be either 'true' of 'false'.\n") return(false) end
if type(showDialogBox) ~= "boolean" then
    reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'showDialogBox' must be either 'true' of 'false'.\n") return(false) end
    

-- Test whether mouse is in MIDI editor
--[[editor = reaper.MIDIEditor_GetActive()
if editor == nil then showErrorMsg("No active MIDI editor found.") return(false) end
take = reaper.MIDIEditor_GetTake(editor)
if take == nil then showErrorMsg("No active take found in MIDI editor.") return(false) end
_, _, details = reaper.BR_GetMouseCursorContext()
if details ~= "cc_lane" and details ~= "cc_selector" then showErrorMsg("The mouse should be positioned over a CC lane in a MIDI editor.")
    return(false) end
]]
editor = reaper.MIDIEditor_GetActive()
if editor == nil then return(0) end

window, segment, details = reaper.BR_GetMouseCursorContext()
-- If window == "unknown", assume to be called from floating toolbar
-- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
    setAsNewArmedToolbarAction()
    return(0) 
elseif details ~= "cc_lane" then 
    showErrorMsg("The mouse should be positioned over a CC lane in a MIDI editor.")
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
    reaper.ShowConsoleMsg("ERROR: \nCould not determine compatible SWS version.\n")
    return(false)
end

if SWS283 == true then
    _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, _, _, mouseLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
end

-- If mouse is not in lane that can be ramped, no need to ask user inputs,
--     so quit right here
if 0 <= mouseLane and mouseLane <= 127 then
    laneString = "CC lane " .. tostring(mouseLane)
elseif 256 <= mouseLane and mouseLane <= 287 then
    laneString = "14-bit CC lanes " .. tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224)
elseif mouseLane == 0x203 then
    laneString = "Channel pressure"
elseif mouseLane == 0x201 then
    laneString = "Pitchwheel"
else 
    showErrorMsg("The mouse should be positioned over a CC lane in which ramps can be drawn: 7-bit CC, 14-bit CC, pitchwheel or channel pressure.")
    return(false) 
end
      
density = reaper.SNM_GetIntConfigVar("midiCCdensity", 64) -- Get the default grid resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
density = math.floor(math.max(4, math.min(128, math.abs(density))))


-------------------------------------------------------------
-- Get user inputs
-- If user inputs are not needed each time the script is run,
--     simply comment out this section.
if showDialogBox == true then

    descriptionsCSVstring = "Events per QN (integer>0):,Shape (sine or number>0):,Skip redundant CCs? (y/n),New CCs selected? (y/n)"
    if skipRedundantCCs then skipStr = "y" else skipStr = "n" end
    if newCCsAreSelected then newSelStr = "y" else newSelStr = "n" end
    defaultsCSVstring = tostring(density) .. "," .. tostring(shape) .. "," .. skipStr .. "," .. newSelStr
    
    -- Repeat getUserInputs until we get usable inputs
    gotUserInputs = false
    while gotUserInputs == false do
        retval, userInputsCSV = reaper.GetUserInputs("Insert ramps: ".. laneString, 4, descriptionsCSVstring, defaultsCSVstring)
        if retval == false then
            return(0)
        else
            density, shape, skipRedundantCCs, newCCsAreSelected = userInputsCSV:match("([^,]+),([^,]+),([^,]+),([^,]+)")
            
            gotUserInputs = true -- temporary, will be changed to false if anything is wrong
            
            density = tonumber(density) 
            if density == nil then gotUserInputs = false
            elseif density ~= math.floor(density) or density <= 0 then gotUserInputs = false 
            end
            
            if shape ~= "sine" then
                shape = tonumber(shape)
                if shape == nil then gotUserInputs = false 
                elseif shape <= 0 then gotUserInputs = false 
                end
            end
            
            if skipRedundantCCs == "y" or skipRedundantCCs == "Y" then skipRedundantCCs = true
            elseif skipRedundantCCs == "n" or skipRedundantCCs == "N" then skipRedundantCCs = false
            else gotUserInputs = false
            end
            
            if newCCsAreSelected == "y" or newCCsAreSelected == "Y" then newCCsAreSelected = true
            elseif newCCsAreSelected == "n" or newCCsAreSelected == "N" then newCCsAreSelected = false
            else gotUserInputs = false
            end 
            
        end -- if retval == 
        
    end -- while gotUserInputs == false

end -- if showDialogBox == true

-- End of user inputs section
-----------------------------

-- Calculate this take's PP and PPQ per grid density
startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
PPgrid = PPQ/density -- PPQ per event
QNgrid = 1/density -- Quarter notes per event
       
-- Since 7bit CC, 14bit CC, channel pressure, velocity and pitch all 
--     require somewhat different tweaks, the code is simpler to read 
--     if divided into separate functions.    
        
if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
    drawRamp7bitCC()
elseif mouseLane == 0x203 then -- Channel pressure
    drawRampChanPressure()
elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
    drawRamp14bitCC()
elseif mouseLane == 0x201 then
    drawRampPitch()
end

reaper.MIDI_Sort(take)
reaper.Undo_OnStateChange("Insert ramps between selected events: " .. laneString)

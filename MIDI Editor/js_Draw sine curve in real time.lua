--[[
 * ReaScript Name:  js_Draw sine curve in real time.lua
 * Description: Draw sine-shapedcurve of CC and pitchwheel events in real time.
 *              An improvement over REAPER's built-in "Linear ramp CC events" mouse action:
 *               1) If snap to grid is enabled in the MIDI editor, the endpoints of the 
 *                  ramp will snap to grid, allowing precise positioning of the ramp 
 *                  (allowing, for example, the insertion of a pitch riser at the
 *                  exact position of a note).
 *               2) By using the mousewheel, the shape of the ramp can be changed from 
 *                  linear to curved (allowing the easy insertion of parablic shapes).
 *               3) The script can optionally chase existing CC values, instead of 
 *                  starting at the mouse's vertical position.  This ensures that
 *                  CC values change smoothly. 
 *               4) The script inserts new CCs, instead of only editing existing CCs.  (CCs
 *                  are inserted at the density set in Preferences -> MIDI editor -> "Events 
 *                  per quarter note when drawing in CC lanes".)
 *               5) The script does not change or delete existing events until execution ends,  
 *                  so there are no 'overshoot remnants' if the mouse movement overshoots 
 *                  the target endpoint.
 *               6) The events in the newly inserted ramp are automatically selected and other
 *                  events are deselected, which allows immediate further shaping of the ramp
 *                  (using, for example, the 2-sided warp (and stretch) script).
 * Instructions:  There are two ways in which this script can be run:  
 *                  1) First, the script can be linked to its own shortcut key.  In this case, 
 *                        optionally, if drawing curved shapes are required, the script can 
 *                        also be linked to a mousewheel shortcut (alternatively, use the 
 *                        "1-sided warp (accelerate)" script after drawing the ramp.
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
 *                To enable chasing of existing CC values, set the "doBackChase" and/or
 *                    "doForwardChase" parameters in the USER AREA at the beginning of the script to "true".
 *
 *                Since this function is a user script, the way it responds to shortcut keys and 
 *                    mouse buttons is opposite to that of REAPER's built-in mouse actions 
 *                    with mouse modifiers:  To run the script, press the shortcut key *once* 
 *                    to start the script and then move the mouse or mousewheel *without* 
 *                    pressing any mouse buttons.  Press the shortcut key again once to 
 *                    stop the script.  
 *                (The first time that the script is stopped, REAPER will pop up a dialog box 
 *                    asking whether to terminate or restart the script.  Select "Terminate"
 *                    and "Remember my answer for this script".)
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
    + Improved speed and responsiveness
 * v1.11 (2016-05-29)
    + Script does not fail when "Zoom dependent" CC density is selected in Preferences
    + If linked to a menu button, script will toggle button state to indicate activation/termination
 * v1.12 (2016-06-02)
    + Few tweaks to improve appearance of real-time ramp when using very low CC density
 * v2.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
]] 

 -- USER AREA
     -- Quality of real-time drawing of ramp.  Set to <1 for weak computer with small screen, 
     --    and up to 4 for supercomputer with huge screen.  Default = 1.
     quality = 1
     
     -- It may be aid workflow if this script is saved in two different versions, each with 
     --    a shortcut key.  In one version, chasing is set to true (for smooth ramping), while
     --    in the other it is set to false (for exact positioning at mouse position).  Remember
     --    that ramp endpoints can also easily be re-positioned using the Tilt script.
     doBackChase = false
     doForwardChase = false
     
     deleteOnlyDrawChannel = true
 
 -----------------------------------------------------------------
 -- Constants and variables
 local CC7BIT = 0
 local CC14BIT = 1
 local PITCH = 2
 local CHANPRESSURE = 3
 
 local wheel = 0
 local tableIndices = {}
 local tableIndicesLSB = {}
 local qualityCCs = math.floor(math.max(0.1, math.min(4, quality))*1024)
 local usedPPQs = {}
 local usedPPQsTableHasBeenSetup = false
  
 
 -----------------------------------------------------------------------------      
 -- General note:
 -- REAPER's InsertCC functions 1) overwrites and delets existing CCs, 
 --    2) changes indices of existing CCs, 3) does not return the index of
 --    the newly inserted event, and 4) is very slow.  Therefore, this script 
 --    will not draw the ramp in real time by continuously *inserting* new CCs.  
 -- Instead, it inserts a lot of CCs right at the start, and then continuously
 --    *morphs* these existing CCs using the SetCC function, which does not 
 --    have the aforementioned disadvantages.  
 -- Whenever more CCs are needed, these are inserted as a bunch.
     
     
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


 -----------------------------------------------------------
 -- The function that will be 'deferred' to run continuously
 function loop_trackMouseMovement()
 
     -- If the mouse moves out of the CC lane area, the script terminates
     -- (And, apparently, BR_GetMouseCursorContext must always precede the other context calls)
     window, _, details = reaper.BR_GetMouseCursorContext()  
     if details ~= "cc_lane" then return(0) end
     
     if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
         
     if SWS283 == true then
         _, _, mouseCClane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
     else 
         _, _, _, mouseCClane, mouseCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
     end
   
     -- If the mouse merely moves out of the original CC lane, do nothing and wait for mouse to return    
     if details == "cc_lane" and mouseCClane == mouseLane and mouseCCvalue ~= -1 then 
     
         lastMouseCCvalue = mouseCCvalue
         lastMouseLane = mouse
         -- mouseTime = reaper.BR_GetMouseCursorContext_Position() 
         
         -- Has mousewheel been moved?     
         is_new,_,_,_,_,_,val = reaper.get_action_context()
             if not is_new then val = 0 end
         scriptVal = tonumber(reaper.GetExtState("js_Mouse actions", "Mousewheel"))
             if scriptVal == nil then scriptVal = 0 end
         reaper.SetExtState("js_Mouse actions", "Mousewheel", "0", false)
        
         if scriptVal > 0 then wheel = wheel - 0.2
         elseif scriptVal < 0 then wheel = wheel + 0.2
         elseif val > 0 then wheel = wheel - 0.2
         elseif val < 0 then wheel = wheel + 0.2
         end     
 
         mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())    
         if isSnapEnabled then
             -- If snap is enabled, we must go through several steps to find the closest grid position
             --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
             -- !! Note that this script does not take swing into account when calculating the grid
             -- User may change grid value while Action is running, so get value again
             QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
             mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQpos) -- Mouse position in quarter notes
             floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
             endpointTwoPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN)                    
         -- Otherwise, destination PPQ is exact mouse position
         else 
             endpointTwoPPQpos = mousePPQpos
         end -- if isSnapEnabled
         
         -- The 1st endpoint event 'chases' existing CC values
         if endpointTwoPPQpos < startingPPQpos then
             endpointOneValue = nextValue
         else
             endpointOneValue = lastValue
         end
         
         -- Are there enough CCs to draw each 'CC density grid' in the ramp?
         --     "-4" because there must be enough CCs to draw ramp on grid as well as endpoints that are not on grid,
         --     and enough to ensure that when rounding to grid, does not skip any grid.
         if (math.abs(endpointTwoPPQpos - startingPPQpos) > (#tableIndices-4) * PPperCC) and #tableIndices < qualityCCs then            
             insertNewCCs(density*4)
         end
                 
         -- Insert endpoint 2 at mouse position
         if laneType == CC7BIT then
             reaper.MIDI_SetCC(take, tableIndices[#tableIndices], nil, nil, endpointTwoPPQpos, nil, nil, nil, mouseCCvalue, true)
         elseif laneType == PITCH then
             reaper.MIDI_SetCC(take, tableIndices[#tableIndices], nil, nil, endpointTwoPPQpos, nil, nil, mouseCCvalue&127, mouseCCvalue>>7, true)
         elseif laneType == CHANPRESSURE then
             reaper.MIDI_SetCC(take, tableIndices[#tableIndices], nil, nil, endpointTwoPPQpos, nil, nil, mouseCCvalue, 0, true)
         else -- laneType == CC14BIT
             reaper.MIDI_SetCC(take, tableIndices[#tableIndices], nil, nil, endpointTwoPPQpos, nil, nil, nil, mouseCCvalue>>7, true)
             reaper.MIDI_SetCC(take, tableIndicesLSB[#tableIndicesLSB], nil, nil, endpointTwoPPQpos, nil, nil, nil, mouseCCvalue&127, true)
         end            
 
         -- Insert endpoint 1 and starting position
         if laneType == CC7BIT then
             reaper.MIDI_SetCC(take, tableIndices[1], nil, nil, startingPPQpos, nil, nil, nil, endpointOneValue, true)
         elseif laneType == PITCH then
             reaper.MIDI_SetCC(take, tableIndices[1], nil, nil, startingPPQpos, nil, nil, endpointOneValue&127, endpointOneValue>>7, true)
         elseif laneType == CHANPRESSURE then
             reaper.MIDI_SetCC(take, tableIndices[1], nil, nil, startingPPQpos, nil, nil, endpointOneValue, 0, true)
         else -- laneType == CC14BIT
             reaper.MIDI_SetCC(take, tableIndices[1], nil, nil, startingPPQpos, nil, nil, nil, endpointOneValue>>7, true)
             reaper.MIDI_SetCC(take, tableIndicesLSB[1], nil, nil, startingPPQpos, nil, nil, nil, endpointOneValue&127, true)
         end
  
         -- Now *move* the rest of the events to their new positions and values
         PPQrange = endpointTwoPPQpos - startingPPQpos
         PPQrangeAbs = math.abs(PPQrange)
         for i = 2, #tableIndices-1 do
             -- If PPQrange == 0, don't need to calculate anything (and beware of 0 denominator)
             if PPQrange == 0 then
                 insertPPQpos = startingPPQpos
                 insertValue = endpointOneValue
             else
                 -- Use (i-2)/(#tableIndices-3) to ensure that this weight factor runs from 0 to 1.
                 insertPPQpos = startingPPQpos + (endpointTwoPPQpos-startingPPQpos)*(i-2)/(#tableIndices-3)
                 -- Now round to nearest 'CC density grid' to the left
                 insertPPQpos = math.floor(firstCCPPQposInTake + ((insertPPQpos - firstCCPPQposInTake)//PPperCC)*PPperCC + 0.5)
                 -- Because the internal events snap to CC density grid while the endpoint do not necessarily snap to grid,
                 --    it is possible for an internal event to move outside the range of the endpoints, unless this is prevented
                 if math.abs(insertPPQpos-startingPPQpos) > PPQrangeAbs or math.abs(insertPPQpos-endpointTwoPPQpos) > PPQrangeAbs then
                     insertPPQpos = startingPPQpos
                 end
 
                 if wheel >= 0 then 
                     insertValue = math.floor(endpointOneValue + (mouseCCvalue-endpointOneValue)*(  (0.5*(1 - math.cos(math.pi*(insertPPQpos-startingPPQpos)/PPQrange)))^(1+wheel)  ) + 0.5)
                 else 
                     insertValue = math.floor(mouseCCvalue + (endpointOneValue-mouseCCvalue)*(  (0.5*(1 - math.cos(math.pi*(endpointTwoPPQpos-insertPPQpos)/PPQrange)))^(1-wheel)  ) + 0.5)
                 end
             end
             if insertValue > mouseCCvalue and insertValue > endpointOneValue then insertValue = math.max(mouseCCvalue, endpointOneValue) end
             if insertValue < mouseCCvalue and insertValue < endpointOneValue then insertValue = math.min(mouseCCvalue, endpointOneValue) end
             
             if laneType == CC7BIT then
                 reaper.MIDI_SetCC(take, tableIndices[i], nil, nil, insertPPQpos, nil, nil, nil, insertValue, true)
             elseif laneType == PITCH then
                 reaper.MIDI_SetCC(take, tableIndices[i], nil, nil, insertPPQpos, nil, nil, insertValue&127, insertValue>>7, true)
             elseif laneType == CHANPRESSURE then
                 reaper.MIDI_SetCC(take, tableIndices[i], nil, nil, insertPPQpos, nil, nil, insertValue, 0, true)
             else -- laneType == CC14BIT
                 reaper.MIDI_SetCC(take, tableIndices[i], nil, nil, insertPPQpos, nil, nil, nil, insertValue>>7, true)
                 reaper.MIDI_SetCC(take, tableIndicesLSB[i], nil, nil, insertPPQpos, nil, nil, nil, insertValue&127, true)
             end
 
 
         end
     end -- if details == "cc_lane" and mouseCClane == mouseLane and mouseCCvalue ~= -1
     
     -- Continuously loop the function
     reaper.runloop(loop_trackMouseMovement)
 
 end -- loop_trackMouseMovement()
 
 -------------------------------------------
 
 --------------------------------------------------------------------------
 function exit()
 
     -- Before exiting, must draw the final version of the ramp
     -- This will be performed by functions based on the script
     --    "Draw linear or shaped ramps between selected events in lane under mouse".        
            
     drawFinalRamp()
     
     reaper.DeleteExtState("js_Mouse actions", "Status", true)
     
     if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 
         and (prevToggleState == 0 or prevToggleState == 1) 
         then
         reaper.SetToggleCommandState(sectionID, cmdID, prevToggleState)
         reaper.RefreshToolbar2(sectionID, cmdID)
     end
                 
     if wheel == 0 then shapeStr = "linear" else shapeStr = "curved" end
     
     if laneType == CC7BIT then
         reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in 7-bit CC lane ".. mouseLane, -1)
     elseif laneType == CHANPRESSURE then
         reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in channel pressure lane", -1)
     elseif laneType == CC14BIT then
         reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in 14 bit CC lanes ".. 
                                   tostring(mouseLane-256) .. "/" .. tostring(mouseLane-224))
     elseif laneType == PITCH then
         reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in pitchwheel lane", -1)
     end
     
     --reaper.MIDI_Sort(take)
 
 end -- function exit()
 
 ------------------------------------------------
 
 function insertNewCCs(num)
     
     --------------------------------------------------------------------------------------
     -- To ensure that the newly inserted events do not delete any existing events,
     --    the following loop records the PPQ positions at which events are already 
     --    inserted in the take.
     -- To keep the code simple, it doesn't check what type of event it is, and
     --    simply records ALL used PPQ positions, until it has found enough open PPQ
     --    positions.
     
     -- The first time this function is executed, the following loop will set up a table with used PPQs
     --    Later, new events will be inserted in-between the used PPQs, before being moved into the ramp
     if usedPPQsTableHasBeenSetup ~= true then
         usedPPQsTableHasBeenSetup = true
         countPPQsBetween = 0 -- how many available PPQs are in-between the used PPQs?
         --usedPPQs = nil -- Clean up previous table
         --usedPPQs = {}
         usedPPQs[0] = -1
         i = 0 
         while (i < ccevtcnt and countPPQsBetween < qualityCCs) do -- qualityCCs is the maximum events used to draw ramp
             _, _, _, ppqpos, _, _, _, _ = reaper.MIDI_GetCC(take, i)
             if ppqpos ~= usedPPQs[#usedPPQs] then
                 table.insert(usedPPQs, ppqpos)
                 countPPQsBetween = countPPQsBetween + ppqpos - usedPPQs[#usedPPQs-1] - 1
             end
             i = i + 1
         end -- while
     end
         
     -- Move existing selected events in ramp back to 'pool position' at 
     --     beginning of take where they started out       
     c = 1
     insertPPQ = 0
     while (c <= #tableIndices) do
         isPPQused = false
         for i = 1, #usedPPQs do
             if usedPPQs[i] == insertPPQ then isPPQused = true end
         end
         if isPPQused == false then
             if laneType ~= CC14BIT then
                 reaper.MIDI_SetCC(take, tableIndices[c], true, nil, insertPPQ, nil, nil, nil, 0, true)
             else -- laneType == CC14BIT
                 reaper.MIDI_SetCC(take, tableIndices[c], true, nil, insertPPQ, nil, nil, nil, 0, true)
                 reaper.MIDI_SetCC(take, tableIndicesLSB[c], true, nil, insertPPQ, nil, nil, nil, 0, true)
             end
             c = c + 1
         end
         insertPPQ = insertPPQ + 1
     end
     
     reaper.MIDI_Sort(take)
     _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)      
     
     if reaper.BR_GetMidiSourceLenPPQ(take) < (num + #tableIndices + #usedPPQs) then 
         reaper.ShowConsoleMsg("Oops, the MIDI item is either too short or too crowded to draw proper ramps")
         return(0) 
     end
 
         
     ---------------------------------------------------------------------------------------------
     -- Insert the events that will later be 'stretched' to draw the ramp.
     -- Since REAPER does not return the index of a newly inserted event, the code must later find
     --     the indices by searching the (only) selected events in the take
     numToInsert = math.min(qualityCCs-#tableIndices, num)
     countInserted = 0
     while (countInserted < numToInsert) do
         isPPQused = false
         for i = 1, #usedPPQs do
             if usedPPQs[i] == insertPPQ then isPPQused = true end
         end
         if isPPQused == false then
             if laneType == CC7BIT then
                 reaper.MIDI_InsertCC(take, true, false, insertPPQ, 176, defaultChannel, mouseLane, 0) -- 0 value so that less intrusively visible-
             elseif laneType == PITCH then
                 reaper.MIDI_InsertCC(take, true, false, insertPPQ, 224, defaultChannel, 0, 0)
             elseif laneType == CHANPRESSURE then
                 reaper.MIDI_InsertCC(take, true, false, insertPPQ, 208, defaultChannel, 0, 0)
             else -- laneType == CC14BIT
                 reaper.MIDI_InsertCC(take, true, false, insertPPQ, 176, defaultChannel, mouseLane-256, 0)
                 reaper.MIDI_InsertCC(take, true, false, insertPPQ, 176, defaultChannel, mouseLane-224, 0)
             end
 
             countInserted = countInserted + 1
         end
         insertPPQ = insertPPQ + 1
     end
 
     --------------------------------------------------------------------------------------------------
     -- Get REAPER's event indices for the newly inserted events - as well as existing selected events)
     tableIndices = nil
     tableIndicesLSB = nil
     tableIndices = {}
     tableIndicesLSB = {}
 
     if laneType ~= CC14BIT then -- Since the events in the ramp are the only selected ones in take, no need to check event types
         selCCindex = reaper.MIDI_EnumSelCC(take, -1)
         while (selCCindex ~= -1) do
             --_, _, _, _, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, selCCindex)
             --if (laneType == CC7BIT and chanmsg == 176 and msg2 == mouseLane)
             --or (laneType == PITCH and chanmsg == 224)
             --or (laneType == CHANPRESSURE and chanmsg == 208) then
                 table.insert(tableIndices, selCCindex)
             --end
             selCCindex = reaper.MIDI_EnumSelCC(take, selCCindex)
         end
     else -- When 14-bit CC, must distinguish between MSB and LSB events
         selCCindex = reaper.MIDI_EnumSelCC(take, -1)
         while (selCCindex ~= -1) do
             _, _, _, _, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, selCCindex)
             if msg2 == mouseLane-256 then
                 table.insert(tableIndices, selCCindex)
             else
                 table.insert(tableIndicesLSB, selCCindex)
             end
             selCCindex = reaper.MIDI_EnumSelCC(take, selCCindex)
         end
     end
 
 end -- function insertNewCCs(num)
 
 --------------------------------------------------------------------------------
 
 function drawFinalRamp()  
 
     -- Stretching and overwriting lots of CCs can confuse REAPER's event indices
     -- It seems that a single "InsertCC" resets everything.
     if laneType == CC7BIT then
         reaper.MIDI_InsertCC(take, true, false, startingPPQpos, 176, defaultChannel, mouseLane, endpointOneValue)
     elseif laneType == PITCH then
         reaper.MIDI_InsertCC(take, true, false, startingPPQpos, 224, defaultChannel, endpointOneValue&127, endpointOneValue>>7)
     elseif laneType == CHANPRESSURE then
         reaper.MIDI_InsertCC(take, true, false, startingPPQpos, 208, defaultChannel, endpointOneValue, 0)
     else -- laneType == CC14BIT
         reaper.MIDI_InsertCC(take, true, false, startingPPQpos, 176, defaultChannel, mouseLane-256, endpointOneValue>>7)
         reaper.MIDI_InsertCC(take, true, false, startingPPQpos, 176, defaultChannel, mouseLane-224, endpointOneValue&127)
     end
     
     -- If PPQ range == 0, no need to draw or delete anything else
     if startingPPQpos ~= endpointTwoPPQpos then
 
         -- The new ramp must overwrite existing events - but only if same type, channel and lane
         -- The scripts goes through several steps to make this process as quick as possible
         
         -- First, get endpoints in correct order
         if startingPPQpos < endpointTwoPPQpos then
             leftPPQ = startingPPQpos; rightPPQ = endpointTwoPPQpos; leftValue = endpointOneValue; rightValue = lastMouseCCvalue
         else -- backwards
             leftPPQ = endpointTwoPPQpos; rightPPQ = startingPPQpos; leftValue = lastMouseCCvalue; rightValue = endpointOneValue
             wheel = -wheel
         end
         
         -- Use binary search to find event close to rightmost edge of ramp
         reaper.MIDI_Sort(take)
         _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)        
         rightIndex = ccevtcnt-1
         leftIndex = 0
         while (rightIndex-leftIndex)>1 do
             middleIndex = math.ceil((rightIndex+leftIndex)/2)
             _, _, _, middlePPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, middleIndex)
             if middlePPQpos > rightPPQ then
                 rightIndex = middleIndex
             else -- middlePPQpos <= startingPPQpos
                 leftIndex = middleIndex
             end     
         end -- while (rightIndex-leftIndex)>1
         
         -- Now remove events original events between the two endpoints.  In an attempt
         --    to improve speed, since deletion is a very slow function and SetCC is faster, 
         --    the script does not delete the original events - it merely "SetCC" all of 
         --    them to the value and position of the rightmost endpoint.  Thereby changing 
         --    them into correct ramp CCs (and leaving clean-up to a later time).
         -- The newly drawn events are of course distinguished by being selected, and they
         --    are left untouched.  In fact, when the final ramp will be drawn, new 
         --    events need not be inserted on PPQ positions where the real-time ramp has 
         --    already inserted events, so these PPQ positions are stored in a table.
         local tablePPQs = {}
         for i = rightIndex, 0, -1 do   
             _, selected, _, ppqpos, chanmsg, chan, msg2, _ = reaper.MIDI_GetCC(take, i)
             if ppqpos < leftPPQ then
                 break -- Once below range of selected events, no need to search further
             elseif selected == true then
                 tablePPQs[ppqpos] = true
             elseif ppqpos <= rightPPQ -- and not selected
                 and (deleteOnlyDrawChannel == false or (deleteOnlyDrawChannel == true and chan == defaultChannel)) -- same channel
                 then
                 if (laneType == CC7BIT and chanmsg == 176 and msg2 == mouseLane) then
                     reaper.MIDI_SetCC(take, i, true, false, rightPPQ, nil, defaultChannel, nil, rightValue, true)
                     --reaper.MIDI_DeleteCC(take, i)
                 elseif (laneType == PITCH and chanmsg == 224) then
                     reaper.MIDI_SetCC(take, i, true, false, rightPPQ, nil, defaultChannel, rightValue&127, rightValue>>7, true)
                     --reaper.MIDI_DeleteCC(take, i)
                 elseif (laneType == CHANPRESSURE and chanmsg == 208) then
                     reaper.MIDI_SetCC(take, i, true, false, rightPPQ, nil, defaultChannel, rightValue, 0, true)
                     --reaper.MIDI_DeleteCC(take, i)
                 elseif (laneType == CC14BIT and chanmsg == 176 and msg2 == mouseLane-256) then
                     reaper.MIDI_SetCC(take, i, true, false, rightPPQ, nil, defaultChannel, nil, rightValue>>7, true)
                     --reaper.MIDI_DeleteCC(take, i)
                 elseif (laneType == CC14BIT and chanmsg == 176 and msg2 == mouseLane-224) then
                     reaper.MIDI_SetCC(take, i, true, false, rightPPQ, nil, defaultChannel, nil, rightValue&127, true)
                     --reaper.MIDI_DeleteCC(take, i)
                 end
             end -- elseif
         end -- for i = ccevtcnt-1, 0, -1
         
         -- Get first insert position at CC density 'grid'
         leftQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, leftPPQ)
         firstCCinsertPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*(math.ceil(leftQNpos/QNperCC)))
         firstCCinsertPPQposAlt = math.floor(firstCCPPQposInTake + ((leftPPQ - firstCCPPQposInTake)//PPperCC)*PPperCC + 0.5)
     
         PPQrange = rightPPQ - leftPPQ
         for p = firstCCinsertPPQpos, rightPPQ, PPperCC do
             insertPPQpos = math.floor(p + 0.5)
             if tablePPQs[insertPPQpos] == nil then -- if event has already been inserted during real-time drawing, can skip slow InsertCC steps
               
                 if wheel >= 0 then 
                     insertValue = math.floor(leftValue + (rightValue-leftValue)*(  (0.5*(1 - math.cos(math.pi*(insertPPQpos-leftPPQ)/PPQrange)))^(1+wheel)  ) + 0.5)
                 else 
                     insertValue = math.floor(rightValue + (leftValue-rightValue)*(  (0.5*(1 - math.cos(math.pi*(rightPPQ-insertPPQpos)/PPQrange)))^(1-wheel)  ) + 0.5)
                 end
                 if insertValue > leftValue and insertValue > rightValue then insertValue = math.max(leftValue, rightValue) end
                 if insertValue < leftValue and insertValue < rightValue then insertValue = math.min(leftValue, rightValue) end
                 
                 if laneType == CC7BIT then
                     reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, defaultChannel, mouseLane, insertValue)
                 elseif laneType == PITCH then
                     reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 224, defaultChannel, insertValue&127, insertValue>>7)
                 elseif laneType == CHANPRESSURE then
                     reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 208, defaultChannel, insertValue, 0)
                 else -- laneType == CC14BIT
                     reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, defaultChannel, mouseLane-256, insertValue>>7)
                     reaper.MIDI_InsertCC(take, true, false, insertPPQpos, 176, defaultChannel, mouseLane-224, insertValue&127)
                 end
             end -- if tablePPQs[insertPPQpos] == nil
         end
 
         -- Insert endpoint 2 at mouse position
         if tablePPQs[endpointTwoPPQpos] == nil then
             if laneType == CC7BIT then
                 reaper.MIDI_InsertCC(take, true, false, endpointTwoPPQpos, 176, defaultChannel, mouseLane, lastMouseCCvalue)
             elseif laneType == PITCH then
                 reaper.MIDI_InsertCC(take, true, false, endpointTwoPPQpos, 224, defaultChannel, lastMouseCCvalue&127, lastMouseCCvalue>>7)
             elseif laneType == CHANPRESSURE then
                 reaper.MIDI_InsertCC(take, true, false, endpointTwoPPQpos, 208, defaultChannel, lastMouseCCvalue, 0)
             else -- laneType == CC14BIT
                 reaper.MIDI_InsertCC(take, true, false, endpointTwoPPQpos, 176, defaultChannel, mouseLane-256, lastMouseCCvalue>>7)
                 reaper.MIDI_InsertCC(take, true, false, endpointTwoPPQpos, 176, defaultChannel, mouseLane-224, lastMouseCCvalue&127)
             end
         end
         
     end -- if startingPPQpos ~= endpointTwoPPQpos     
                
 end -- function drawFinalRamp
 
 
 -----------------------------------------------
 -- The main function
 
 function main()
 
 --[[local _, editor, take, details, mouseLane, mouseTime, mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, 
           mousePPQpos, startQN, PPQ, QNperGrid, mouseQNpos, floorGridQN, floorGridPPQ, destPPQpos, 
           events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
           tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos, stretchFactor, newPPQpos
     ]] 
     ---------------------------------------------------------------------
     -- function should only run if mouse is in a CC lane in a MIDI editor
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
          
     -- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
     --     require somewhat different tweaks, these must often be 
     --     distinguished.   
     if 0 <= mouseLane and mouseLane <= 127 then -- CC, 7 bit (single lane)
         laneType = CC7BIT
     elseif mouseLane == 0x203 then -- Channel pressure
         laneType = CHANPRESSURE
     elseif 256 <= mouseLane and mouseLane <= 287 then -- CC, 14 bit (double lane)
         laneType = CC14BIT
     elseif mouseLane == 0x201 then
         laneType = PITCH
     else -- not a lane type in which a ramp can be drawn (sysex, velocity etc).
         return(0)
     end
 
     -- OK, it seems like this script will do something, so toggle button (if any) and define atexit with its Undo statements
    _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end

     reaper.atexit(exit)
     
     ------------------------------------------------------------------------
     -- Deselect all events in one shot.  Much faster than doing this via Lua
     reaper.MIDI_SelectAll(take, false)
     
     reaper.MIDI_Sort(take)
     defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
     
     
     ------------------------------------------------------------------------------
     -- Get the starting position of the ramp.  Must check whether snap is enabled.
     mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
     isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1)
     startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
     PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
 
     if isSnapEnabled then
         -- If snap is enabled, we must go through several steps to find the closest grid position
         --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
         -- !! Note that this script does not take swing into account when calculating the grid
         -- First, calculate this take's PPQ:
         -- Calculate position of grid immediately before mouse position
         QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
         mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQpos) -- Mouse position in quarter notes
         floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
         startingPPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN)    
     else 
         -- Otherwise, destination PPQ is exact mouse position
         startingPPQpos = mousePPQpos
     end  
 
     -----------------------------------------------------------------------
     -- While we are busy with grid, get CC density 'grid' values
     -- First, Get the default grid resolution as set in Preferences -> 
     --    MIDI editor -> "Events per quarter note when drawing in CC lanes"
     density = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
     density = math.floor(math.max(4, math.min(128, math.abs(density)))) -- If user selected "Zoom dependent", density<0
     PPperCC = PPQ/density
     QNperCC = 1/density
     firstCCPPQposInTake = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*(math.ceil(startQN/QNperCC)))
   
     -----------------------------------------------------------------------------
     -- Set up the default CC values
     --     (used if chasing is disable, or if no CC event is found during 'chase'
     lastValue = mouseCCvalue
     nextValue = mouseCCvalue     
  
     -----------------------------------------------------------------------------------
     -- It can be very slow to search through all events from 0 to end, trying to find
     --    the CC values to chase.  The following section therefore uses a binary search 
     --    algorithm to quickly find CC events close to the mouse position.
     _, _, ccevtcnt, _ = reaper.MIDI_CountEvts(take)
     if ccevtcnt == 0 then
         doForwardChase = false
         doBackChase = false
     else
         _, _, _, leftmostPPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, 0)
         _, _, _, rightmostPPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, ccevtcnt-1)
     end
         
     -- Determine index from which to start forward chase 
     if doForwardChase == true then
        
         if leftmostPPQpos >= startingPPQpos then
             chaseForwardStartIndex = 0
         elseif rightmostPPQpos < startingPPQpos then
             doForwardChase = false
         else
             leftIndex = 0
             rightIndex = ccevtcnt - 1
             while (rightIndex-leftIndex)>1 do
                 middleIndex = math.floor((rightIndex+leftIndex)/2)
                 _, _, _, middlePPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, middleIndex)
                 if middlePPQpos < startingPPQpos then
                     leftIndex = middleIndex
                 else 
                     rightIndex = middleIndex
                 end
             end -- while
             chaseForwardStartIndex = rightIndex
         end  
     end -- Determine index from which to start forward chase
 
     -- Do forward chase   
     if doForwardChase == true then
         f = chaseForwardStartIndex
         chaseForwardFound = false
         chaseMSBfound = false
         chaseLSBfound = false
         while (f < ccevtcnt and chaseForwardFound == false) do
             _, _, _, ppqpos, chanmsg, _, msg2, msg3 = reaper.MIDI_GetCC(take, f)
         
             if laneType == CC7BIT and chanmsg == 176 and msg2 == mouseLane then
                nextValue = msg3
                chaseForwardFound = true 
             
             --[[
             -- Chasing can be slow if there is no LSB and the search therefore iterates through every event.
             -- It may therefore be quicker to only look for MSB.            
             elseif laneType == CC14BIT and chanmsg == 176 and msg2 == mouseLane-256 then
                 nextValue = msg3<<7
                 chaseForwardFound = true 
             ]]
                   
             elseif laneType == CC14BIT then
                 if chanmsg == 176 and msg2 == mouseLane-256 and chaseMSBfound == false then
                     nextMSB = msg3
                     nextValue = msg3<<7 -- If no LSB is found, this MSB will be used as chased value
                     chaseMSBfound = true
                 elseif chanmsg == 176 and msg2 == mouseLane-224 and chaseLSBfound == false then
                     nextLSB = msg3
                     chaseLSBfound = true
                 end
                 if chaseMSBfound == true and chaseLSBfound == true then 
                     nextValue = (nextMSB<<7) + nextLSB
                     chaseForwardFound = true 
                 end
             
             elseif laneType == PITCH and chanmsg == 224 then
                 nextValue = (msg3<<7) + msg2
                 chaseForwardFound = true
             
             elseif laneType == CHANPRESSURE and chanmsg == 208 then
                 nextValue = msg2
                 chaseForwardFound = true   
                                  
             end -- if ... <= mouseLane and mouseLane <= ... and msg2 == ...
 
             f = f + 1
         end -- while (i < ccevtcnt and chaseForwardFound == false)
 
     end -- if doForwardChase == true
  
     -- Determine index from which to start back chase
     if doBackChase == true then
         if rightmostPPQpos <= startingPPQpos then
             chaseBackStartIndex = ccevtcnt-1
         elseif leftmostPPQpos > startingPPQpos then
             doBackChase = false
         else
             leftIndex = 0
             rightIndex = ccevtcnt - 1
             while (rightIndex-leftIndex)>1 do
                 middleIndex = math.ceil((rightIndex+leftIndex)/2)
                 _, _, _, middlePPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, middleIndex)
                 if middlePPQpos > startingPPQpos then
                     rightIndex = middleIndex
                 else -- middlePPQpos <= startingPPQpos
                     leftIndex = middleIndex
                 end     
             end -- while
             chaseBackStartIndex = leftIndex   
         end
     end -- Determine index from which to start back chase
 
     -- Do back chase
     if doBackChase == true then  
         b = chaseBackStartIndex
         chaseBackFound = false
         chaseMSBfound = false
         chaseLSBfound = false
         while (b >= 0 and chaseBackFound == false) do
             _, _, _, ppqpos, chanmsg, _, msg2, msg3 = reaper.MIDI_GetCC(take, b)
         
             if laneType == CC7BIT and chanmsg==176 and msg2 == mouseLane then
                 lastValue = msg3
                 chaseBackFound = true
 
             --[[  
             -- Chasing can be slow if there is no LSB and the search therefore iterates through every event.
             -- It may therefore be quicker to only look for MSB.
             elseif laneType == CC14BIT and chanmsg == 176 and msg2 == mouseLane-256 then
                 lastValue = msg3<<7
                 chaseBackFound = true             
             ]]             
 
             elseif laneType == CC14BIT then
                 if chanmsg==176 and msg2 == mouseLane-256 and chaseMSBfound == false then
                     lastValue = msg3<<7 -- If no LSB is found, this MSB will be used as chased value
                     lastMSB = msg3
                     chaseMSBfound = true
                 elseif chanmsg==176 and msg2 == mouseLane-224 and chaseLSBfound == false then
                     lastLSB = msg3
                     chaseLSBfound = true
                 end
                 if chaseMSBfound == true and chaseLSBfound == true then 
                     lastValue = (lastMSB<<7) + lastLSB
                     chaseBackFound = true 
                 end
                   
             elseif laneType == PITCH and chanmsg == 224 then
                 lastValue = (msg3<<7) + msg2
                 chaseBackFound = true
             
             elseif laneType == CHANPRESSURE and chanmsg == 208 then
                 lastValue = msg2
                 chaseBackFound = true                
                  
             end -- if ... <= mouseLane and mouseLane <= ... and msg2 == ...
 
             b = b - 1
         end -- while (i >= 0 and chaseBackFound == false)
     end -- if doBackChase == true 
     
     endpointOneValue = nextValue -- start off with this value
 
     -------------------------------------------------------------------------
     -- Start off with a pool of the CCs with which to draw the ramp
     -- Unfortunately, InsertCC is very slow, and ithe Action feels very 
     --    unresponsive if the entire pool of CCs are inserted in one go.
     -- Therefore, start with just enough CCs for one half note, and later
     --    the deferred function will add more CCs as needed.
     insertNewCCs(1+density*2) --(density*2)*math.ceil(128/(density*2))) 
 
     -- Reset the mousewheel movement before starting the defer loop
     --   otherwise ramp will not start with default shape
     is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
     
     ------------------------------------------------
     -- Start tracking mouse movement with endpoint 2
     loop_trackMouseMovement()
  
 end -- function main
 
 ----------------------------------------------------------
 -- Start code execution
 -- Start with a trick to avoid automatically creating undo 
 --      states if nothing actually happened
 -- Undo_OnStateChange will only be used if reaper.atexit(exit) has been executed
 function avoidUndo()
 end
 reaper.defer(avoidUndo)
 
 
 main()

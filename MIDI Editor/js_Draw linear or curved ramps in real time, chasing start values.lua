--[[
ReaScript name: js_Draw linear or curved ramps in real time, chasing start values.lua
Version: 3.00
Author: juliansader
Screenshot: http://stash.reaper.fm/27627/Draw%20linear%20or%20curved%20ramps%20in%20real%20time%2C%20chasing%20start%20values%20-%20Copy.gif
Website: http://forum.cockos.com/showthread.php?t=176878
Extensions:  SWS/S&M 2.8.3 or later
About:
  # Description
  Draw linear or curved ramps of CC and pitchwheel events in real time, chasing start values.
             
  An improvement over REAPER's built-in "Linear ramp CC events" mouse action:
  
  * If snap to grid is enabled in the MIDI editor, the endpoints of the 
     ramp will snap to grid, allowing precise positioning of the ramp 
     (allowing, for example, the insertion of a pitch riser at the
     exact position of a note).
  
  * By using the mousewheel, the shape of the ramp can be changed from 
     linear to curved (allowing the easy insertion of parablic shapes).
  
  * The script can optionally chase existing CC values, instead of 
     starting at the mouse's vertical position.  This ensures that
     CC values change smoothly. 
  
  * The script inserts new CCs, instead of only editing existing CCs.  (CCs
     are inserted at the density set in Preferences -> MIDI editor -> "Events 
     per quarter note when drawing in CC lanes".)
  
  * The script does not change or delete existing events until execution 
     ends, so there are no 'overshoot remnants' if the mouse movement overshoots 
     the target endpoint.
  
  * The events in the newly inserted ramp are automatically selected and other
     events are deselected, which allows immediate further shaping of the ramp
     (using, for example, the 2-sided warp (and stretch) script).
     
  * The script can optionally skip redundant CCs (that is, CCs with the same 
     value as the preceding CC).

  # Instructions
  There are two ways in which this script can be run:  
  
  * First, the script can be linked to its own shortcut key.  In this case, 
      optionally, if drawing curved shapes are required, the script can 
      also be linked to a mousewheel shortcut (alternatively, use the 
      "1-sided warp (accelerate)" script after drawing the ramp.

  * Second, this script, together with other "js_" scripts that edit the "lane under mouse",
      can each be linked to a toolbar button.  
      In this case, each script need not be linked to its own shortcut key.  Instead, only the 
        accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
        script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
      Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
        and this selected (armed) script can then be run by using the shortcut for the 
        aforementioned "js_Run..." script.
     For further instructions - please refer to the "js_Run..." script.                 

  To enable/disable chasing of existing CC values, set the "doBackChase" and/or
   "doForwardChase" parameters in the USER AREA at the beginning of the script to "false".
   
  To enable/disable skipping of redundant CCs, set the "skipRedundant" parameter
    in the USER AREA.
  
  To enable/disable deselection of all MIDI before drawing, set the "deselectAllBeforeDrawing"
    parameter in the USER AREA.
 
  Since this function is a user script, the way it responds to shortcut keys and 
    mouse buttons is opposite to that of REAPER's built-in mouse actions 
    with mouse modifiers:  To run the script, press the shortcut key *once* 
    to start the script and then move the mouse or mousewheel *without* 
    pressing any mouse buttons.  Press the shortcut key again once to 
    stop the script.  

  (The first time that the script is stopped, REAPER will pop up a dialog box 
    asking whether to terminate or restart the script.  Select "Terminate"
    and "Remember my answer for this script".)
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
  * v2.10 (2016-10-23)
    + Header updated to ReaPack v1.1 format.
    + Chasing will only match CCs in active channel.
  * v3.00 (2016-11-18)
    + Option to skip redundant events.
    + IMPROVED, NEAR-NATIVE SPEED!  (Especially in items with >100000 MIDI events.)
]]

-- USER AREA
    -- It may be aid workflow if this script is saved in two different versions, each with 
    --    a shortcut key.  In one version, chasing is set to true (for smooth ramping), while
    --    in the other it is set to false (for exact positioning at mouse position).  Remember
    --    that ramp endpoints can also easily be re-positioned using the Tilt script.
    doBackChase = true
    doForwardChase = true
    
    skipRedundant = true
    deleteOnlyDrawChannel = true
    deselectAllBeforeDrawing = true -- Deselect all MIDI in take before drawing. Allows easy editing of only the new ramp after drawing.

-----------------------------------------------------------------
-- Constants and variables
local laneType
local CC7BIT = 0
local CC14BIT = 1
local PITCH = 2
local CHANPRESSURE = 3

local wheel = 0 

local chunkFirstPart = ""
local thisTakeMIDIchunk = "" 

local tableLine = {}
local lineLeftPPQpos, lineLeftValue, lineRightPPQpos, lineRightValue, lineEndPPQpos --= 0,0,0,0,0
local originalOffset

local mouseStartCCvalue, mouseStartLane, lineStartPPQpos
local take, QNperGrid, PPQ, QNstart

-----------------------------------------------------------------------------      
-- General note:
-- REAPER's InsertCC functions 1) overwrites and deletes existing CCs, 
--    2) changes indices of existing CCs, 3) does not return the index of
--    the newly inserted event, and 4) is very slow.  Therefore, this script 
--    will not use REAPER's own API to draw the line.  
-- Instead, it will directly access the item's MIDI state chunk state data.    
    
-----------------------------------------------------------
-- The function that will be 'deferred' to run continuously
local function loop_trackMouseMovement()

    -- If the mouse moves out of the CC lane area, the script terminates
    -- (And, apparently, BR_GetMouseCursorContext must always precede the other context calls)
    window, _, details = reaper.BR_GetMouseCursorContext()  
    if details ~= "cc_lane" then return(0) end
    
    -- The js_Run... script can communicate with and control the other js_ scripts via ExtState
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
        
    -- Get new mouse (vertical) position
    if SWS283 == true then 
        _, _, mouseNewCClane, mouseNewCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else -- SWS287
        _, _, _, mouseNewCClane, mouseNewCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end    
  
    -- Only proceed if the mouse is in original CC lane. Otherwise, do nothing and wait for mouse to return    
    if mouseNewCClane == mouseStartLane and mouseNewCCvalue ~= -1 then 
    
        local sf = string.format
        local ti = table.insert
        local mf = math.floor
        
        local mouseStartLane = mouseStartLane
        local skipRedundant = skipRedundant
        local PPperCC = PPperCC
    
        lastMouseCCvalue = mouseNewCCvalue
        lastMouseLane = mouseNewCClane
        -- mouseTime = reaper.BR_GetMouseCursorContext_Position()         
        
        -- Has mousewheel been moved?     
        -- The script can detect mousewheel in two ways: either by being linked directly to a mousewheel mouse modifier,
        --     or via the js_Run... script that can run and control the other js_ scripts.
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

        -- Get mouse new PPQ (horizontal) position
        local mousePPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
        if isSnapEnabled then
            -- If snap is enabled, we must go through several steps to find the closest grid position
            --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
            -- !! Note that this script does not take swing into account when calculating the grid
            -- User may change grid value while Action is running, so get value again
            -- QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
            local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQpos) -- Mouse position in quarter notes
            local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
            lineEndPPQpos = mf(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
        -- Otherwise, destination PPQ is exact mouse position
        else 
            lineEndPPQpos = mf(mousePPQpos + 0.5)
        end -- if isSnapEnabled
        
        -- The line's startpoint event 'chases' existing CC values
        if lineEndPPQpos < lineStartPPQpos then
            lineStartValue = nextChasedValue 
        else
            lineStartValue = lastChasedValue
        end
        
        -- Prefer to draw the line from left to right, so check whether mouse is to left or right of starting point
        local mouseToRight
        if lineEndPPQpos >= lineStartPPQpos then
            mouseToRight = true
            lineLeftPPQpos = lineStartPPQpos
            lineLeftValue  = lineStartValue
            lineRightPPQpos = lineEndPPQpos
            lineRightValue  = mouseNewCCvalue
        else 
            mouseToRight = false
            lineLeftPPQpos = lineEndPPQpos
            lineLeftValue  = mouseNewCCvalue
            lineRightPPQpos = lineStartPPQpos
            lineRightValue  = lineStartValue
        end    
                
        -- Clean previous tableLine
        tableLine = {}
        local lastPPQpos = 0
        local offset = 0
        local defaultChannelX = string.format("%1x", defaultChannel)
        
        
        -- Insert the leftmost endpoint (which is not necessarily a grid position)
        if laneType == CC7BIT then
            ti(tableLine, sf("\ne %i b%s %02x %02x", lineLeftPPQpos, defaultChannelX, mouseStartLane, lineLeftValue))
        elseif laneType == PITCH then
            ti(tableLine, sf("\ne %i e%s %02x %02x", lineLeftPPQpos, defaultChannelX, lineLeftValue&127, lineLeftValue>>7))
        elseif laneType == CHANPRESSURE then
            ti(tableLine, sf("\ne %i d%s %02x %02x", lineLeftPPQpos, defaultChannelX, lineLeftValue, 0))
        else -- laneType == CC14BIT
            ti(tableLine, sf("\ne %i b%s %02x %02x", lineLeftPPQpos, defaultChannelX, mouseStartLane-256, lineLeftValue>>7))
            ti(tableLine, sf("\ne %i b%s %02x %02x", 0,              defaultChannelX, mouseStartLane-224, lineLeftValue&127))
        end
        local lastValue = lineLeftValue
        local lastPPQpos = lineLeftPPQpos
        
        
        -- Now insert all the CCs in-between the endpoints.  These positions will follow the "midiCCdensity" setting (which 
        --    is usually much finer than the editor's "grid" setting.
        -- First, find next PPQ position at which CCs will be inserted.  
        local nextCCdensityPPQpos = PPperCC * math.ceil((lineLeftPPQpos+1)/PPperCC)
        
        local PPQrange = lineRightPPQpos - lineLeftPPQpos
        local insertValue = 0      
        
        for insertPPQpos = nextCCdensityPPQpos, lineRightPPQpos-1, PPperCC do
            -- These four options ensure the the curve propely follows mouse movement
            if wheel >= 0 and mouseToRight then
                insertValue = mf(lineLeftValue + (lineRightValue-lineLeftValue)*(((insertPPQpos-lineLeftPPQpos)/(PPQrange))^(1+wheel)) + 0.5)
            elseif wheel >= 0 and not mouseToRight then
                insertValue = mf(lineRightValue + (lineLeftValue-lineRightValue)*(((lineRightPPQpos-insertPPQpos)/(PPQrange))^(1+wheel)) + 0.5)
            elseif mouseToRight then
                insertValue = mf(lineRightValue + (lineLeftValue-lineRightValue)*(((insertPPQpos-lineRightPPQpos)/(-PPQrange))^(1-wheel)) + 0.5)
            else
                insertValue = mf(lineLeftValue + (lineRightValue-lineLeftValue)*(((lineLeftPPQpos-insertPPQpos)/(-PPQrange))^(1-wheel)) + 0.5) 
            end
            
            if insertValue ~= lastValue or skipRedundant == false then
                if laneType == CC7BIT then
                    ti(tableLine, sf("\ne %i b%s %02x %02x", insertPPQpos-lastPPQpos, defaultChannelX, mouseStartLane, insertValue))
                elseif laneType == PITCH then
                    ti(tableLine, sf("\ne %i e%s %02x %02x", insertPPQpos-lastPPQpos, defaultChannelX, insertValue&127, insertValue>>7))
                elseif laneType == CHANPRESSURE then
                    ti(tableLine, sf("\ne %i d%s %02x %02x", insertPPQpos-lastPPQpos, defaultChannelX, insertValue, 0))
                else -- laneType == CC14BIT
                    ti(tableLine, sf("\ne %i b%s %02x %02x", insertPPQpos-lastPPQpos, defaultChannelX, mouseStartLane-256, insertValue>>7))
                    ti(tableLine, sf("\ne %i b%s %02x %02x", 0,                       defaultChannelX, mouseStartLane-224, insertValue&127))
                end
                lastValue = insertValue
                lastPPQpos = insertPPQpos
            end 
        end
        
        
        -- Insert the rightmost endpoint
        if laneType == CC7BIT then
            ti(tableLine, sf("\ne %i b%s %02x %02x", lineRightPPQpos-lastPPQpos, defaultChannelX, mouseStartLane, lineRightValue))
        elseif laneType == PITCH then
            ti(tableLine, sf("\ne %i e%s %02x %02x", lineRightPPQpos-lastPPQpos, defaultChannelX, lineRightValue&127, lineRightValue>>7))
        elseif laneType == CHANPRESSURE then
            ti(tableLine, sf("\ne %i d%s %02x %02x", lineRightPPQpos-lastPPQpos, defaultChannelX, lineRightValue, 0))
        else -- laneType == CC14BIT
            ti(tableLine, sf("\ne %i b%s %02x %02x", lineRightPPQpos-lastPPQpos, defaultChannelX, mouseStartLane-256, lineRightValue>>77))
            ti(tableLine, sf("\ne %i b%s %02x %02x", 0,                          defaultChannelX, mouseStartLane-224, lineRightValue&127))
        end 
        
        
        -- Update the original first MIDI event's offset relative to the new events
        local originalMIDInewOffset = originalOffset-lineRightPPQpos
        if originalMIDInewOffset < 0 then originalMIDInewOffset = 4294967296 + originalMIDInewOffset end
        --table.insert(tableLine, "") -- to ensure that a "\n" is added at the end
                
        -- DRUMROLL... write the line into the MIDI chunk
        -- This also updates the offset of the original first MIDI event
        reaper.SetItemStateChunk(item, chunkFirstPart
                                    .. table.concat(tableLine) 
                                    .. thisTakeMIDIchunk:gsub("%d+", string.format("%i", originalMIDInewOffset), 1)
                                    , false)
        
    end -- if details == "cc_lane" and mouseNewCClane == mouseStartLane and mouseNewCCvalue ~= -1
        
    -- Continuously loop the function
    reaper.runloop(loop_trackMouseMovement)

end -- loop_trackMouseMovement()

-------------------------------------------

----------------------------------------------------------------------------
function exit()

    -- Before exiting, delete existing CCs in the line's range (and channel)  
    deleteExistingCCsInRange()
    
    -- Communicate with the js_Run.. script that this script is exiting
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    -- Deactivate toolbar button (if it has been toggled)
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 
        and (prevToggleState == 0 or prevToggleState == 1) 
        then
        reaper.SetToggleCommandState(sectionID, cmdID, prevToggleState)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    -- Should MIDI_Sort be run?  It may affect overlapping notes
    reaper.MIDI_Sort(take) 
                
    -- Write nice, informative Undo strings
    if wheel == 0 then shapeStr = "linear" else shapeStr = "curved" end
    if laneType == CC7BIT then
        reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in 7-bit CC lane ".. mouseStartLane, -1)
    elseif laneType == CHANPRESSURE then
        reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in channel pressure lane", -1)
    elseif laneType == CC14BIT then
        reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in 14 bit CC lanes ".. 
                                  tostring(mouseStartLane-256) .. "/" .. tostring(mouseStartLane-224))
    elseif laneType == PITCH then
        reaper.Undo_OnStateChange("Draw ("..shapeStr..") ramp in pitchwheel lane", -1)
    end   

end -- function exit

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

function deleteExistingCCsInRange()  
    
    -- If PPQ range == 0, no need to draw or delete anything else
    if lineStartPPQpos ~= lineEndPPQpos then

        -- The new ramp must overwrite existing events - but only if same type, channel and lane
        -- These deletions must be limited to the active take's MIDI (not any other take in the item)
        --    so must first find the endpoint of the active take's MIDI chunk.
        -- REAPER's MIDI takes all (are supposed to) end with an All-Notes-Off message, "E offset B0 7B 00".
        -- This line tries to find such a message (and that is not followed by another MIDI event)
        posAllNotesOff, _ = thisTakeMIDIchunk:find("\n[eE] %d+ [Bb]0 7[Bb] 00\n[^<xXeE]")
        if posAllNotesOff == nil then 
            reaper.ShowMessageBox("No end-of-take MIDI message found.\n\nSkipping deletion of events.", "ERROR", 0)
            return
        end        
        
        -- Define lots of local variables for the function that gsub will call to check every event and delete
        --    the overlapping ones.
        local offsetChange = 0 -- This variable will be used by the deleteOrUpdateOffset
        local newOffset = 0
        local countRedundancies = 0
        local runningPPQpos = lineRightPPQpos
        local defaultUpper = string.format("%1X", defaultChannel)
        local defaultLower = string.format("%1x", defaultChannel)
        local offset, eventType, channel, msg2, msg3
        local laneStrUpper, laneStrLower, laneStrUpperLSB, laneStrLowerLSB
        if laneType == CC7BIT then 
            laneStrUpper = string.format("%02X", mouseStartLane) 
            laneStrLower = string.format("%02x", mouseStartLane) 
        elseif laneType == CC14BIT then
            laneStrUpper = string.format("%02X", mouseStartLane-256) 
            laneStrLower = string.format("%02x", mouseStartLane-256) 
            laneStrUpperLSB = string.format("%02X", mouseStartLane-224) 
            laneStrLowerLSB = string.format("%02x", mouseStartLane-224)
        end
        --------------------------------------------------------------------------
        local function gsubHelperDelete(line, selType, offset, message)
        
            doDelete = false -- Will be changed if event must be deleted
            
            offset    = tonumber(offset, 10)
            if offset > 4294967296/2 then offset = offset - 4294967296 end -- Offsets are stored as unsigned 32bit integers
                        
            runningPPQpos = runningPPQpos + offset
            
            if runningPPQpos >= lineLeftPPQpos and runningPPQpos <= lineRightPPQpos then
            
                if selType == "E" or selType == "e" then
                    eventType, channel, msg2, msg3 = message:match("(%x)(%x) (%x%x) (%x%x)")
                elseif selType == "x" or selType == "X" then
                    eventType, channel, msg2, msg3 = message:match("%d+ (%x)(%x) (%x%x) (%x%x)")
                else -- sysex
                    goto skipChecks
                end

                -- If cannot parse, just return and skip                
                if (not eventType) or (not channel) or (not msg2) or (not msg3) then
                    goto skipChecks
                end
                
                if laneType == CC7BIT then
                    if (eventType == "b" or eventType == "B") 
                    and (deleteOnlyDrawChannel and (channel == defaultUpper or channel == defaultLower))
                    and (msg2 == laneStrUpper or msg2 == laneStrLower)
                    then
                        doDelete = true
                    end
                elseif laneType == PITCH then
                    if (eventType == "e" or eventType == "E") 
                    and (deleteOnlyDrawChannel and (channel == defaultUpper or channel == defaultLower))
                    then
                        doDelete = true
                    end
                elseif laneType == CHANPRESSURE then
                    if (eventType == "d" or eventType == "d") 
                    and (deleteOnlyDrawChannel and (channel == defaultUpper or channel == defaultLower))
                    then
                        doDelete = true
                    end
                else -- laneType == CC14BIT
                    if (eventType == "b" or eventType == "B") 
                    and (deleteOnlyDrawChannel and (channel == defaultUpper or channel == defaultLower))
                    and (msg2 == laneStrUpper or msg2 == laneStrLower or msg2 == laneStrUpperLSB or msg2 == laneStrLowerLSB)
                    then
                        doDelete = true
                    end
                end 
                
            end -- if runningPPQpos >= lineLeftPPQpos and runningPPQpos <= lineRightPPQpos
                
            ::skipChecks::
            if doDelete == true then
                offsetChange = offsetChange + offset
                return("")
            else        
                newOffset = offset + offsetChange
                offsetChange = 0
                if newOffset < 0 then newOffset = 4294967296 + newOffset end
                return line:gsub("%d+", newOffset, 1)
            end
            
        end -- function gsubHelperDelete
        --------------------------------
        
        
        -------------------------------------------------------------------------------------
        -- Update the original first MIDI event's relative offset, and then search using gsub
        local originalMIDInewOffset = originalOffset-lineRightPPQpos
        if originalMIDInewOffset < 0 then originalMIDInewOffset = 4294967296 + originalMIDInewOffset end
        reaper.SetItemStateChunk(item, chunkFirstPart
                                    .. table.concat(tableLine) 
                                    .. thisTakeMIDIchunk:sub(1,posAllNotesOff)
                                                        :gsub("%d+", string.format("%i", originalMIDInewOffset), 1)
                                                        :gsub("(\n(<?[xXeE])m? (%d+) ([%-% %x]+))", gsubHelperDelete) 
                                    .. thisTakeMIDIchunk:sub(posAllNotesOff+1)
                                    , false)
                                            
    end -- if lineStartPPQpos ~= lineEndPPQpos     
               
end -- function deleteExistingCCsInRange

-----------------------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------------------------------
--#####################################################################################################
-------------------------------------------------------------------------------------------------------
-- Here execution starts!
-- function main()

--[[local _, editor, window, segment, details, 
      mouseTime, mousePPQpos, startQN, mouseQNpos, 
      mousePPQpos, startQN, mouseQNpos, floorGridQN, floorGridPPQ, destPPQpos, 
      events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
      tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos, stretchFactor, newPPQpos]]

----------------------------------------------------------------------------------------------
-- Start with a trick to avoid automatically creating undo states if nothing actually happened
-- Undo_OnStateChange will only be used if reaper.atexit(exit) has been executed
function avoidUndo()
end
reaper.defer(avoidUndo)

    
-----------------------------------------------------------
-- The following sections checks the position of the mouse:
-- If the script is called from a toolbar, it arms the script as the default js_Run function, but does not run the script further
-- If the mouse is positioned over a CC lane, the script is run.
window, segment, details = reaper.BR_GetMouseCursorContext()
-- If window == "unknown", assume to be called from floating toolbar
-- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
    setAsNewArmedToolbarAction()
    return(0) 
elseif details ~= "cc_lane" then 
    reaper.ShowMessageBox("Mouse is not positioned in a MIDI editor.", "ERROR", 0)
    return(false) 
end
        

----------------------------------------------------------------------        
-- Test whether a MIDI editor and an active take are in fact available
editor = reaper.MIDIEditor_GetActive()
if editor == nil then 
    reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0)
    return(false)
end
take = reaper.MIDIEditor_GetTake(editor)
if not reaper.ValidatePtr(take, "MediaItem_Take*") then 
    reaper.ShowMessageBox("No active take in MIDI editor.", "ERROR", 0)
    return(false)
end


--------------------------------------------------------------------------------------
-- Get the mouse starting (vertical) value and CC lane.
--
-- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI"
-- https://github.com/Jeff0S/sws/issues/783
-- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
_, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
if SWS283 ~= SWS283again then
    reaper.ShowMessageBox("Could not determine compatible SWS version.", "ERROR", 0)
    return(false)
end

if SWS283 == true then
    _, _, mouseStartLane, mouseStartCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, _, _, mouseStartLane, mouseStartCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
end 
     
-- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
--     require somewhat different tweaks, these must often be 
--     distinguished.   
if 0 <= mouseStartLane and mouseStartLane <= 127 then -- CC, 7 bit (single lane)
    laneType = CC7BIT
elseif mouseStartLane == 0x203 then -- Channel pressure
    laneType = CHANPRESSURE
elseif 256 <= mouseStartLane and mouseStartLane <= 287 then -- CC, 14 bit (double lane)
    laneType = CC14BIT
elseif mouseStartLane == 0x201 then
    laneType = PITCH
else -- not a lane type in which a ramp can be drawn (sysex, velocity etc).
    return(0)
end


-----------------------------------------------------------------------------
-- OK, it seems like this script will do something, so toggle button (if any) 
--    and define atexit with its Undo statements
_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

reaper.atexit(exit)


--------------------------------------------------------------------------------------------
-- REAPER's native function for deselection is even faster than writing to MIDI state chunk.
if deselectAllBeforeDrawing then reaper.MIDI_SelectAll(take, false) end


-------------------------------------------------------------------
-- Events will be inserted in the active channel of the active take
defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")


-----------------------------------------------------------------------------------------------
-- Get the starting PPQ (horizontal) position of the ramp.  Must check whether snap is enabled.
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
    lineStartPPQpos = math.floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
else 
    -- Otherwise, destination PPQ is exact mouse position
    lineStartPPQpos = math.floor(mousePPQpos + 0.5)
end  


-----------------------------------------------------------------------
-- While we are busy with grid, get CC density 'grid' values
-- First, Get the default grid resolution as set in Preferences -> 
--    MIDI editor -> "Events per quarter note when drawing in CC lanes"
CCdensity = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
CCdensity = math.floor(math.max(4, math.min(128, math.abs(CCdensity)))) -- If user selected "Zoom dependent", density<0
PPperCC = math.floor((PPQ/CCdensity) + 0.5)
QNperCC = 1/CCdensity
firstCCPPQposInTake = reaper.MIDI_GetPPQPosFromProjQN(take, QNperCC*(math.ceil(startQN/QNperCC)))


-----------------------------------------------------------------------------
-- Set up the default CC values
--     (used if chasing is disable, or if no CC event is found during 'chase'
lastChasedValue = mouseStartCCvalue
nextChasedValue = mouseStartCCvalue     


-----------------------------------------------------------------------------------
-- It can be very slow to search through all events from 0 to end, trying to find
--    the CC values to chase.  The following section therefore uses a binary search 
--    algorithm to quickly find CC events close to the mouse position.
if doForwardChase or doBackChase then

    reaper.MIDI_Sort(take)

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
       
        if leftmostPPQpos >= lineStartPPQpos then
            chaseForwardStartIndex = 0
        elseif rightmostPPQpos < lineStartPPQpos then
            doForwardChase = false
        else
            leftIndex = 0
            rightIndex = ccevtcnt - 1
            while (rightIndex-leftIndex)>1 do
                middleIndex = math.floor((rightIndex+leftIndex)/2)
                _, _, _, middlePPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, middleIndex)
                if middlePPQpos < lineStartPPQpos then
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
            _, _, _, ppqpos, chanmsg, channel, msg2, msg3 = reaper.MIDI_GetCC(take, f)
        
            if channel == defaultChannel then -- ignore CCs in other channels
                   
                if laneType == CC7BIT and chanmsg == 176 and msg2 == mouseStartLane then
                   nextChasedValue = msg3
                   chaseForwardFound = true 
                
                --[[
                -- Chasing can be slow if there is no LSB and the search therefore iterates through every event.
                -- It may therefore be quicker to only look for MSB.            
                elseif laneType == CC14BIT and chanmsg == 176 and msg2 == mouseStartLane-256 then
                    nextChasedValue = msg3<<7
                    chaseForwardFound = true 
                ]]
                      
                elseif laneType == CC14BIT then
                    if chanmsg == 176 and msg2 == mouseStartLane-256 and chaseMSBfound == false then
                        nextMSB = msg3
                        nextChasedValue = msg3<<7 -- If no LSB is found, this MSB will be used as chased value
                        chaseMSBfound = true
                    elseif chanmsg == 176 and msg2 == mouseStartLane-224 and chaseLSBfound == false then
                        nextLSB = msg3
                        chaseLSBfound = true
                    end
                    if chaseMSBfound == true and chaseLSBfound == true then 
                        nextChasedValue = (nextMSB<<7) + nextLSB
                        chaseForwardFound = true 
                    end
                
                elseif laneType == PITCH and chanmsg == 224 then
                    nextChasedValue = (msg3<<7) + msg2
                    chaseForwardFound = true
                
                elseif laneType == CHANPRESSURE and chanmsg == 208 then
                    nextChasedValue = msg2
                    chaseForwardFound = true   
                                     
                end -- if ... <= mouseStartLane and mouseStartLane <= ... and msg2 == ...
    
            end -- if channel == defaultChannel
            
            f = f + 1
        end -- while (i < ccevtcnt and chaseForwardFound == false)
    
    end -- if doForwardChase == true
    
    -- Determine index from which to start back chase
    if doBackChase == true then
        if rightmostPPQpos <= lineStartPPQpos then
            chaseBackStartIndex = ccevtcnt-1
        elseif leftmostPPQpos > lineStartPPQpos then
            doBackChase = false
        else
            leftIndex = 0
            rightIndex = ccevtcnt - 1
            while (rightIndex-leftIndex)>1 do
                middleIndex = math.ceil((rightIndex+leftIndex)/2)
                _, _, _, middlePPQpos, _, _, _, _ = reaper.MIDI_GetCC(take, middleIndex)
                if middlePPQpos > lineStartPPQpos then
                    rightIndex = middleIndex
                else -- middlePPQpos <= lineStartPPQpos
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
            _, _, _, ppqpos, chanmsg, channel, msg2, msg3 = reaper.MIDI_GetCC(take, b)
        
            if channel == defaultChannel then -- ignore CCs in other channels
            
                if laneType == CC7BIT and chanmsg==176 and msg2 == mouseStartLane then
                    lastChasedValue = msg3
                    chaseBackFound = true
    
                --[[  
                -- Chasing can be slow if there is no LSB and the search therefore iterates through every event.
                -- It may therefore be quicker to only look for MSB.
                elseif laneType == CC14BIT and chanmsg == 176 and msg2 == mouseStartLane-256 then
                    lastChasedValue = msg3<<7
                    chaseBackFound = true             
                ]]             
    
                elseif laneType == CC14BIT then
                    if chanmsg==176 and msg2 == mouseStartLane-256 and chaseMSBfound == false then
                        lastChasedValue = msg3<<7 -- If no LSB is found, this MSB will be used as chased value
                        lastMSB = msg3
                        chaseMSBfound = true
                    elseif chanmsg==176 and msg2 == mouseStartLane-224 and chaseLSBfound == false then
                        lastLSB = msg3
                        chaseLSBfound = true
                    end
                    if chaseMSBfound == true and chaseLSBfound == true then 
                        lastChasedValue = (lastMSB<<7) + lastLSB
                        chaseBackFound = true 
                    end
                      
                elseif laneType == PITCH and chanmsg == 224 then
                    lastChasedValue = (msg3<<7) + msg2
                    chaseBackFound = true
                
                elseif laneType == CHANPRESSURE and chanmsg == 208 then
                    lastChasedValue = msg2
                    chaseBackFound = true                
                     
                end -- if ... <= mouseStartLane and mouseStartLane <= ... and msg2 == ...
    
            end -- if channel == defaultChannel
            
            b = b - 1
        end -- while (i >= 0 and chaseBackFound == false)
    end -- if doBackChase == true 

end -- if doForwardChase or doBackChase

lineStartValue = nextChasedValue -- start off with this value


----------------------------------------------------------------------------------------------
-- Time to load the MIDI state chunk!
-- This script does not use the standard MIDI API functions such as MIDI_InsertCC, since these
--    functions are far too slow when dealing with thousands of events.
-- Instead, this script will directly edit the raw MIDI data in the take's "state chunk".
-- More info on the formats can be found at 

local guidString, gotChunkOK, chunkStr, _, posTakeGUID, posAllNotesOff, posTakeMIDIend, posFirstStandardEvent, 
      posFirstExtendedEvent, posFirstSysex, posFirstMIDIevent

-- All the MIDI data of all the takes in the item is stored within the "state chunk"
item = reaper.GetMediaItemTake_Item(take)
gotChunkOK, chunkStr = reaper.GetItemStateChunk(item, "", false)
if not gotChunkOK then
    reaper.ShowMessageBox("Could not access the item's state chunk.", "ERROR", 0)
    return
end

-- Use the take's GUID to find the beginning of the take's data within the state chunk of the entire item
guidString = reaper.BR_GetMediaItemTakeGUID(take)
_, posTakeGUID = chunkStr:find(guidString, 1, true)
if type(posTakeGUID) ~= "number" then
    reaper.ShowMessageBox("Could not find the take's GUID string within the state chunk.", "ERROR", 0)
    return
end

-- Now find the very first MIDI message in the take's chunk.  This can be in standard format, extended format, of sysex format
-- REAPER's MIDI takes all (are supposed to) end with an All-Notes-Off message, "E offset B0 7B 00", so at least one
--    MIDI message with standard format must be found.
posFirstStandardEvent = chunkStr:find("\n[eE]m? %-?%d+ %x%x %x%x %x%x[%-% %d]-\n", posTakeGUID)
if posFirstStandardEvent == nil then 
    reaper.ShowMessageBox("Could not find any MIDI data in chunk!", "ERROR", 0)
    return end
posFirstSysex         = chunkStr:sub(1,posFirstStandardEvent+2):find("\n<[xX]m? %-?%d+ %-?%d+.->\n[<xXeE]", posTakeGUID)
if posFirstSysex == nil then posFirstSysex = posFirstStandardEvent end
posFirstExtendedEvent = chunkStr:sub(1,posFirstSysex+2):find("\n[xX]m? %-?%d+ %-?%d+ %x%x %x%x %x%x[%-% %d]-\n", posTakeGUID)
if posFirstExtendedEvent == nil then posFirstExtendedEvent = posFirstSysex end
posFirstMIDIevent = math.min(posFirstStandardEvent, posFirstExtendedEvent, posFirstSysex)

-- The new events will be inserted in front of the existing MIDI data in the chunk.
-- So we must divide the chunk at precisely the start of the MIDI data.
chunkFirstPart = chunkStr:sub(1, posFirstMIDIevent-1)
thisTakeMIDIchunk = chunkStr:sub(posFirstMIDIevent)
--local chunkLastPart = chunkStr:sub(posTakeMIDIend)

-- The offset of the first original MIDI event will have to be updated for the new events.  Therefore store
--    the original value.  Remember that offsets are stored as unsigned 32bit integers.
originalOffset = tonumber(thisTakeMIDIchunk:match("(%-?%d+)"))
if originalOffset > 2147483647 then originalOffset = originalOffset - 4294967296 end -- 2147483647 = 2^31-1


-------------------------------------------------------------

-------------------------------------------------------------
-- Finally, start running the loop!
-- (But first, reset the mousewheel movement.)
is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()

loop_trackMouseMovement()

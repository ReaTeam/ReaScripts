--[[
ReaScript name: js_Draw sine curve in real time, chasing start values.lua
Version: 3.10
Author: juliansader
Screenshot: http://stash.reaper.fm/27627/Draw%20linear%20or%20curved%20ramps%20in%20real%20time%2C%20chasing%20start%20values%20-%20Copy.gif
Website: http://forum.cockos.com/showthread.php?t=176878
REAPER version: v5.30 or later
Extensions: SWS/S&M 2.8.3 or later
About:
  # Description
  Draw sine or warped sine ramps of CC and pitchwheel events in real time, chasing start values.
             
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
     events in the same lane are deselected, which allows immediate further shaping
     of the ramp (using, for example, the warping or arching scripts).
     
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

  To enable/disable chasing of existing CC values, set the "doChase" parameter in the 
      USER AREA at the beginning of the script to "false".
   
  To enable/disable skipping of redundant CCs, set the "skipRedundant" parameter.
  
  To enable/disable deselection of other CCs in the same lane as the new ramp (and in the active take), 
      set the "deselectEverythingInLane" parameter.  This allows easy editing of only the new 
      ramp after drawing.
      
  As an alternative to deselecting only in the target lane, all MIDI in all editable takes can be deselected
      before drawing, by setting the deselectAllBeforeDrawing parameter.
 
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
  * v3.01 (2016-11-19)
    + Script works with takes in which first MIDI message is sysex.
  * v3.10 (2016-12-10)
    + Improved speed, using new API functions of REAPER v5.30. 
]]

----------------------------------------
-- USER AREA
-- Settings that the user can customize.

    -- It may aid workflow if this script is saved in two different versions, each with 
    --    a shortcut key.  In one version, chasing is set to true (for smooth ramping), while
    --    in the other it is set to false (for exact positioning at mouse position).  Remember
    --    that ramp endpoints can also easily be re-positioned using the Tilt script.
    doChase = true -- True or false
    
    skipRedundant = true -- True or false
    deleteOnlyDrawChannel = true -- True or false
    deselectEverythingInLane = true -- True or false: Deselect all CCs in the same lane as the new ramp (and in active take). 
    deselectAllBeforeDrawing = false -- True or false: Deselect all events in all editable takes before drawing
    
-- End of USER AREA


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

-- General note:
-- REAPER's MIDI API functions such as InsertCC and SetCC are very slow if the active take contains 
--    hundreds of thousands of MIDI events.  
-- Therefore, this script will not use these functions, and will instead directly access the item's 
--    raw MIDI stream via new functions that were introduced in v5.30: GetAllEvts and SetAllEvts.

-- Notes re sorting:
-- MIDI_Sort is not only slow, but also endlessly buggy (http://forum.cockos.com/showthread.php?t=184459
--    is one of many threads).  It is expecially dangerous if there are any overlapping notes.
-- It is actually faster to check for unsorted data during parsing.
-- This script will therefore try to avoid MIDI_Sort.  Since MIDI is supposed to be sorted,
--    no sorting will be done when the script starts, unless unsorted data is detected during parsing.
-- When the script exists, instead of using MIDI_Sort to integrate the new events into the original 
--    MIDI data, the script will call the action "Invert selection" (twice) using OnCommand.  
--    This should induce the MIDI editor to sort the MIDI data.

-- The MIDI data will be stored in the string MIDIstring.  While drawing, in each cycle a string with 
--    new events will be concatenated in front of MIDIstring, and loaded into REAPER as the new state chunk.
-- The offset of the first event will be stored separately - not in MIDIstring - since this offset 
--    will need to be updated in each cycle relative to the PPQ positions of the edited events.
local MIDIstring
local originalOffset
local MIDIstringSub5 -- MIDIstring without the first 4 byte of the original offset

-- As the MIDI events of the ramp are calculated, each event wil be assmebled into a short string and stored in the tableLine table.   
local tableLine = {}
 
-- Starting values and position of mouse 
-- mouseOrigCClane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local window, segment, details -- given by the SWS function reaper.BR_GetMouseCursorContext()
local laneIsCC7BIT    = false
local laneIsCC14BIT   = false
local laneIsPITCH     = false
local laneIsCHPRESS   = false
--local laneIsPROGRAM   = false
--local laneIsVELOCITY  = false
--local laneIsPIANOROLL = false 
--local laneIsSYSEX     = false -- not used in this script
--local laneIsTEXT      = false
local laneMin, laneMax -- The minimum and maximum values in the target lane
local mouseOrigCClane, mouseOrigCCvalue, mouseOrigPPQpos, mouseOrigPitch
local gridOrigPPQpos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)
local isInline -- Is the user using the inline MIDI editor?  (The inline editor does not have access to OnCommand.)

-- If doChase is false, or if no pre-existing CCs are found, these will be the same as mouseOrigCCvalue
local lastChasedValue -- value of closest CC to the left
local nextChasedValue -- value of closest CC to the right

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCClane, mouseNewCCvalue, mouseNewPPQpos, mouseNewPitch
local gridNewPPQpos 
local mouseWheel = 0 -- Track mousewheel movement

-- The CCs will be inserted into the MIDI string from left to right (not necessarily from gridOrig to gridNew)
local lineLeftPPQpos, lineLeftValue, lineRightPPQpos, lineRightValue

-- REAPER preferences and settings that will affect the drawing of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-to-grid is enabled in the editor
local defaultChannel -- In case new MIDI events will be inserted, what is the default channel?
local CCdensity -- grid resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
local PPperCC -- ticks per CC ** not necessarily an integer **
local PPQ -- ticks per quarter note

-- The crucial function BR_GetMouseCursorContext gets slower and slower as the number of events in the take increases.
-- Therefore, the active take will be emptied *before* calling the function, using MIDI_SetAllEvts.
local AllNotesOffString -- = string.pack("i4Bi4BBB", itemLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
local itemLengthTicks

-- Some internal stuff that will be used to set up everything
local _, take, editor, QNperGrid

-- I am not sure that defining these functions as local really helps to spred up the script...
local s_unpack = string.unpack
local s_pack   = string.pack
local m_floor  = math.floor
--local t_insert = table.insert -- using myTable[c]=X is much faster than table.insert(myTable, X)

  

--#############################################################################################
-----------------------------------------------------------------------------------------------
-- The function that will be 'deferred' to run continuously
-- Note that the greatest part of execution time is taken up by two functions:
--    * reaper.BR_GetMouseCursorContext(), which must unfortunately unavoidably be called before 
--           reaper.BR_GetMouseCursorContext_MIDI(), and which (surprisingly) gets much slower as the 
--           number of MIDI events in the take increases.
--    * reaper.SetAllEvts.
-- The Lua script parts of this function - unless it has to calculate millions of events per cycle -
--    make up only a small fraction of the execution time.
local function loop_trackMouseMovement()

    -------------------------------------------------------------------------------------------
    -- The js_Run... script can communicate with and control the other js_ scripts via ExtState
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
   
    -------------------------------------------
    -- Track the new mouse (vertical) position.
    -- (Apparently, BR_GetMouseCursorContext must always precede the other BR_ context calls)
    -- ***** Trick: BR_GetMouse... gets slower and slower as the number of events in the take increases.
    --              Therefore, clean the take *before* calling the function!
    reaper.MIDI_SetAllEvts(take, AllNotesOffString)
    window, segment, details = reaper.BR_GetMouseCursorContext()  
    if SWS283 == true then 
        _, mouseNewPitch, mouseNewCClane, mouseNewCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else -- SWS287
        _, _, mouseNewPitch, mouseNewCClane, mouseNewCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end
    
    ----------------------------------------------------------------------------------
    -- What must the script do if the mouse moves out of the original CC lane area?
    -- Per default, the script will terminate.  This is an easy way to ensure that 
    --    the script does not continue to run indefinitely without the user realising.
    if laneIsPIANOROLL then
        if not (segment == "notes") then 
            return 
        end
    elseif mouseNewCClane ~= mouseOrigCClane then
        return
    end
    
    ---------------------------------------------------------------
    -- So the script continues...  Declare some local variables etc
    if (not laneIsPIANOROLL) and mouseNewCCvalue == -1 then mouseNewCCvalue = laneMax end -- If -1, it means that the mouse is over the separator above the lane.    

    -----------------------------        
    -- Has mousewheel been moved?     
    -- The script can detect mousewheel in two ways: 
    --    * by being linked directly to a mousewheel mouse modifier (return mousewheel movement with reaper.get_action_context)
    --    * or via the js_Run... script that can run and control the other js_ scripts (return movement via ExtState)
    is_new, _, _, _, _, _, moved = reaper.get_action_context()
    if not is_new then -- then try getting from script
        moved = tonumber(reaper.GetExtState("js_Mouse actions", "Mousewheel"))
        if moved == nil then moved = 0 end
    end
    reaper.SetExtState("js_Mouse actions", "Mousewheel", "0", false) -- Reset after getting update
    if moved > 0 then mouseWheel = mouseWheel + 0.2
    elseif moved < 0 then mouseWheel = mouseWheel - 0.2
    end
    
    ------------------------------------------
    -- Get mouse new PPQ (horizontal) position
    mouseNewPPQpos = math.max(0, math.min(itemLengthTicks-1, math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5)))
    if isSnapEnabled then
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseNewPPQpos) -- Mouse position in quarter notes
        local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
        gridNewPPQpos = math.floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
    -- Otherwise, destination PPQ is exact mouse position
    else 
        gridNewPPQpos = mouseNewPPQpos
    end -- if isSnapEnabled
        
    -----------------------------------------------------------
    -- Prefer to draw the line from left to right, so check whether mouse is to left or right of starting point
    -- The line's startpoint event 'chases' existing CC values.
    local mouseToRight
    if gridNewPPQpos >= gridOrigPPQpos then
        mouseToRight = true
        lineLeftPPQpos = gridOrigPPQpos
        lineLeftValue  = lastChasedValue
        lineRightPPQpos = gridNewPPQpos
        lineRightValue  = mouseNewCCvalue
    else 
        mouseToRight = false
        lineLeftPPQpos = gridNewPPQpos
        lineLeftValue  = mouseNewCCvalue
        lineRightPPQpos = gridOrigPPQpos
        lineRightValue  = nextChasedValue
    end    
            
    -----------------------------------------------------------------------------------
    -- Clean previous tableLine.  All the new MIDI events will be stored in this table, 
    --    and later concatenated into a single string.
    tableLine = {}
    local lastPPQpos = 0
    local offset = 0    
    local c = 0 -- Count index in tableLine - This is faster than using table.insert or even #table+1

    -- Insert the leftmost endpoint (which is not necessarily a grid position)
    if laneIsCC7BIT then
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", lineLeftPPQpos, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane, lineLeftValue)
    elseif laneIsPITCH then
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", lineLeftPPQpos, 1, 3, 0xE0 | defaultChannel, lineLeftValue&127, lineLeftValue>>7)
    elseif laneIsCHPRESS then
        c = c + 1
        tableLine[c] = s_pack("i4BI4BB",  lineLeftPPQpos, 1, 2, 0xD0 | defaultChannel, lineLeftValue)
    else -- laneIsCC14BIT
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", lineLeftPPQpos, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-256, lineLeftValue>>7)
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", 0             , 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-224, lineLeftValue&127)
    end
    local lastValue = lineLeftValue
    local lastPPQpos = lineLeftPPQpos
    
    
    -- Now insert all the CCs in-between the endpoints.  These positions will follow the "midiCCdensity" setting (which 
    --    is usually much finer than the editor's "grid" setting.
    -- First, find next PPQ position at which CCs will be inserted.  
    local nextCCdensityPPQpos = PPperCC * math.ceil((lineLeftPPQpos+1)/PPperCC)
    
    local m_cos = math.cos
    local m_pi  = math.pi
    local PPQrange   = lineRightPPQpos - lineLeftPPQpos
    local valueRange = lineRightValue - lineLeftValue
    local insertValue = 0      
    
    for PPQpos = nextCCdensityPPQpos, lineRightPPQpos-1, PPperCC do
        insertPPQpos = m_floor(PPQpos + 0.5) -- PPperCC is not necessarily an integer
        -- Power < 0 and > 0 gives different shapes, so these two options select the one that looks (to me) most musical 
        if mouseWheel >= 0 then
            insertValue = lineLeftValue + valueRange*(  (0.5*(1 - m_cos(m_pi*(insertPPQpos-lineLeftPPQpos)/PPQrange)))^(1+mouseWheel) )
        else
            insertValue = lineRightValue - valueRange*(  (0.5*(1 - m_cos(m_pi*(lineRightPPQpos-insertPPQpos)/PPQrange)))^(1-mouseWheel)  )
        end
        insertValue = m_floor(insertValue + 0.5)     
            
        if insertValue ~= lastValue or skipRedundant == false then
            if laneIsCC7BIT then
                c = c + 1
                tableLine[c] = s_pack("i4BI4BBB", insertPPQpos-lastPPQpos, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane, insertValue)
            elseif laneIsPITCH then
                c = c + 1
                tableLine[c] = s_pack("i4BI4BBB", insertPPQpos-lastPPQpos, 1, 3, 0xE0 | defaultChannel, insertValue&127, insertValue>>7)
            elseif laneIsCHPRESS then
                c = c + 1
                tableLine[c] = s_pack("i4BI4BB",  insertPPQpos-lastPPQpos, 1, 2, 0xD0 | defaultChannel, insertValue)
            else -- laneIsCC14BIT
                c = c + 1
                tableLine[c] = s_pack("i4BI4BBB", insertPPQpos-lastPPQpos, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-256, insertValue>>7)
                c = c + 1
                tableLine[c] = s_pack("i4BI4BBB", 0                      , 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-224, insertValue&127)
            end
            lastValue = insertValue
            lastPPQpos = insertPPQpos
        end 
    end
    
    
    -- Insert the rightmost endpoint
    if laneIsCC7BIT then
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", lineRightPPQpos-lastPPQpos, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane, lineRightValue)
    elseif laneIsPITCH then
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", lineRightPPQpos-lastPPQpos, 1, 3, 0xE0 | defaultChannel, lineRightValue&127, lineRightValue>>7)
    elseif laneIsCHPRESS then
        c = c + 1
        tableLine[c] = s_pack("i4BI4BB",  lineRightPPQpos-lastPPQpos, 1, 2, 0xD0 | defaultChannel, lineRightValue)
    else -- laneIsCC14BIT
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", lineRightPPQpos-lastPPQpos, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-256, lineRightValue>>7)
        c = c + 1
        tableLine[c] = s_pack("i4BI4BBB", 0                      , 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-224, lineRightValue&127)
    end    

                                
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    -- This also updates the offset of the first event in MIDIstringSub5 relative to the PPQ position of the last event in tableRawMIDI
    local newOrigOffset = originalOffset-lineRightPPQpos
    reaper.MIDI_SetAllEvts(take, table.concat(tableLine)
                                  .. string.pack("i4", newOrigOffset)
                                  .. MIDIstringSub5)
    
    if isInline then reaper.UpdateArrange() end
    
    
    ---------------------------------------        
    -- Continuously loop the function
    reaper.runloop(loop_trackMouseMovement)

end -- loop_trackMouseMovement()

-------------------------------------------

----------------------------------------------------------------------------
function onexit()
    
    -- Calls to native actions such as "Invert selection" via OnCommand must be placed
    --    within explicit undo blocks, otherwise they will create their own undo points.
    -- Strangely, in the current v5.30, undo blocks are interrupted as soon as the 
    --    atexit-defined function is called.  *This is probably a bug.*  
    -- Therefore must start a new undo block within this onexit function.  Fortunately, 
    --    this undo point seems to undo the entire defered script, not only the stuff that
    --    happens within this onexit function.
    reaper.Undo_BeginBlock()
    
    -- Before exiting, delete existing CCs in the line's range (and channel)
    -- Remember that the loop function may quit after clearing the active take.  The delete function 
    --    will also ensure that the MIDI is re-uploaded into the active take.
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
    
    -- MIDI_Sort is buggy when dealing with overlapping notes, 
    --    causing infinitely extended notes or zero-length notes.
    -- Even explicitly calling "Correct overlapping notes" before sorting does not avoid all bugs.
    -- Calling "Invert selection" twice is a much more reliable way to sort MIDI.   
    if isInline then
        reaper.MIDI_Sort(take)
    else
        reaper.MIDIEditor_OnCommand(editor, 40501) -- Invert selection in active take
        reaper.MIDIEditor_OnCommand(editor, 40501) -- Invert back to original selection
    end
                    
    -- Write nice, informative Undo strings
    if mouseWheel == 0 then shapeStr = "sine" else shapeStr = "warped sine" end
    if laneIsCC7BIT then
        reaper.Undo_EndBlock("Draw ("..shapeStr..") ramp in 7-bit CC lane ".. mouseOrigCClane, 4)
    elseif laneIsCHPRESS then
        reaper.Undo_EndBlock("Draw ("..shapeStr..") ramp in channel pressure lane", 4)
    elseif laneIsCC14BIT then
        reaper.Undo_EndBlock("Draw ("..shapeStr..") ramp in 14 bit CC lanes ".. 
                                  tostring(mouseOrigCClane-256) .. "/" .. tostring(mouseOrigCClane-224), 4)
    elseif laneIsPITCH then
        reaper.Undo_EndBlock("Draw ("..shapeStr..") ramp in pitchwheel lane", 4)
    end   

end -- function onexit

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

function deleteExistingCCsInRange()  
            
    -- The MIDI strings of non-targeted events will temnporarily be stored in a table, tableRemainingEvents[],
    --    and once all MIDI data have been parsed, this table (which excludes the strings of targeted events)
    --    will be concatenated to replace the original chunkLastPart.
    -- The targeted events will therefore have been extracted from the MIDI string.
    local tableRemainingEvents = {}     

    local newOffset = 0
    local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local lastRemainPPQpos = 0
    local prevPos, nextPos, unchangedPos = 1, 1, 1
    local r = 0 -- Count index in tableRemainingEvents - This is faster than using table.insert or even #table+1        
    
    --------------------------------------------------------------------------------------------------
    -- Iterate through all the (original) MIDI in the take, searching for events to delete or deselect
    while nextPos <= MIDIlen do
       
        local offset, flags, msg
        local mustDelete  = false
        local mustDeselect = false
        
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
        
        -- A little check if parsing is still OK
        if flags&252 ~= 0 then -- 252 = binary 11111100.
            reaper.ShowMessageBox("The MIDI data uses an unknown format that could not be parsed.  No events will be deleted."
                                  .. "\n\nPlease report the problem in the thread http://forum.cockos.com/showthread.php?t=176878:"
                                  .. "\nFlags = " .. string.char(flags)
                                  .. "\nMessage = " .. msg
                                  , "ERROR", 0)
            return false
        end
        
        -- runningPPQpos must be updated for all events, even if not selected etc
        runningPPQpos = runningPPQpos + offset
                                            
        -- If event within line PPQ range, check whether must delete
        if runningPPQpos >= lineLeftPPQpos and runningPPQpos <= lineRightPPQpos then
            if msg:byte(1) & 0x0F == defaultChannel or deleteOnlyDrawChannel == false then
                local eventType = msg:byte(1)>>4
                local msg2      = msg:byte(2)
                if laneIsCC7BIT then if eventType == 11 and msg2 == mouseOrigCClane then mustDelete = true end
                elseif laneIsPITCH then if eventType == 14 then mustDelete = true end
                elseif laneIsCC14BIT then if eventType == 11 and (msg2 == mouseOrigCClane-224 or msg2 == mouseOrigCClane-256) then mustDelete = true end
                elseif laneIsCHPRESS then if eventType == 13 then mustDelete = true end
                end
            end
        end
        
        -- Even if outside PPQ range, must still deselect if in lane
        if deselectEverythingInLane == true and flags&1 == 1 and not mustDelete then -- Only necessary to deselect if not already mustDelete
            local eventType = msg:byte(1)>>4
            local msg2      = msg:byte(2)
            if laneIsCC7BIT then if eventType == 11 and msg2 == mouseOrigCClane then mustDeselect = true end
            elseif laneIsPITCH then if eventType == 14 then mustDeselect = true end
            elseif laneIsCC14BIT then if eventType == 11 and (msg2 == mouseOrigCClane-224 or msg2 == mouseOrigCClane-256) then mustDeselect = true end
            elseif laneIsCHPRESS then if eventType == 13 then mustDeselect = true end
            end
        end
        
        -------------------------------------------------------------------------------------
        -- This section will try to speed up parsing by not inserting each event individually
        --    into the table.  Unchanged events will be copied as larger blocks.
        -- This does make things a bit complicated, unfortunately...
        if mustDelete then
            -- The chain of unchanged events is broken, so write to tableRemainingEvents, if necessary
            if unchangedPos < prevPos then
                r = r + 1
                tableRemainingEvents[r] = MIDIstring:sub(unchangedPos, prevPos-1)
            end
            unchangedPos = nextPos
            mustUpdateNextOffset = true
        elseif mustDeselect then
            -- The chain of unchanged events is broken, so write to tableRemainingEvents, if necessary
            if unchangedPos < prevPos then
                r = r + 1
                tableRemainingEvents[r] = MIDIstring:sub(unchangedPos, prevPos-1)
            end
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQpos - lastRemainPPQpos, flags&0xFE, msg)
            lastRemainPPQpos = runningPPQpos
            unchangedPos = nextPos
            mustUpdateNextOffset = false
        elseif mustUpdateNextOffset then
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQpos-lastRemainPPQpos, flags, msg)
            lastRemainPPQpos = runningPPQpos
            unchangedPos = nextPos
            mustUpdateNextOffset = false
        else
            lastRemainPPQpos = runningPPQpos
        end
        
    end -- while nextPos <= MIDIlen   
    
    -- Insert all remaining unchanged events
    r = r + 1
    tableRemainingEvents[r] = MIDIstring:sub(unchangedPos) 
    
    -------------------------------------------------------------
    -- Update first remaining event's offset relative to new ramp
    local newOffset = s_unpack("i4", tableRemainingEvents[1]) - lineRightPPQpos
    tableRemainingEvents[1] = s_pack("i4", newOffset) .. tableRemainingEvents[1]:sub(5)

    ------------------------
    -- Upload into the take!
    reaper.MIDI_SetAllEvts(take, table.concat(tableLine) .. table.concat(tableRemainingEvents))                                                                    
               
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


--#####################################################################################################
-------------------------------------------------------------------------------------------------------
-- Here execution starts!
-- function main()

-- Start with a trick to avoid automatically creating undo states if nothing actually happened
-- Undo_OnStateChange will only be used if reaper.atexit(onexit) has been executed
function avoidUndo()
end
reaper.defer(avoidUndo)


----------------------------------------------------------------------------
-- Check whether SWS is available, as well as the required version of REAPER
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.30 or higher.", "ERROR", 0)
    return(false) 
elseif not reaper.APIExists("BR_GetMouseCursorContext") then
    reaper.ShowMessageBox("This script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
    return(false) 
end   


-----------------------------------------------------------
-- The following sections checks the position of the mouse:
-- If the script is called from a toolbar, it arms the script as the default js_Run function, but does not run the script further
-- If the mouse is positioned over a CC lane, the script is run.
window, segment, details = reaper.BR_GetMouseCursorContext()
-- If window == "unknown", assume to be called from floating toolbar
-- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
    setAsNewArmedToolbarAction()
    return(true) 
elseif not(details == "cc_lane") then 
    reaper.ShowMessageBox("Mouse is not correctly positioned.\n\n"
                          .. "This script draws a ramp in the CC lane that is under the mouse, "
                          .. "so the mouse should be positioned over a CC lane of an active MIDI editor.", "ERROR", 0)
    return(false) 
else
    -- Communicate with the js_Run.. script that a script is running
    reaper.SetExtState("js_Mouse actions", "Status", "Running", false)
end


-----------------------------------------------------------------------------------------
-- We know that the mouse is positioned over a MIDI editor.  Check whether inline or not.
-- Also get the mouse starting (vertical) value and CC lane.
-- mouseOrigPitch: note row or piano key under mouse cursor (0-127)
-- mouseOrigCClane: CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
--    0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
--    0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)
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
    isInline, mouseOrigPitch, mouseOrigCClane, mouseOrigCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, isInline, mouseOrigPitch, mouseOrigCClane, mouseOrigCCvalue, _ = reaper.BR_GetMouseCursorContext_MIDI()
end 

    
----------------------------------------------------------        
-- Get active take and item (MIDI editor or inline editor)
if isInline then
    take = reaper.BR_GetMouseCursorContext_Take()
else
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then 
        reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0)
        return(false)
    end
    take = reaper.MIDIEditor_GetTake(editor)
end
if not reaper.ValidatePtr(take, "MediaItem_Take*") then 
    reaper.ShowMessageBox("Could not find an active take in the MIDI editor.", "ERROR", 0)
    return(false)
end


---------------------------------------------------------
-- Get item length so that mouse movement can be limited, 
--    and so that take can be cleared using SetAllEvts
local item = reaper.GetMediaItemTake_Item(take)
itemLengthTicks  = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH"))+0.5)
AllNotesOffString = string.pack("i4Bi4BBB", itemLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)


-------------------------------------------------------------
-- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
--     require somewhat different tweaks, these must often be 
--     distinguished.   
if 0 <= mouseOrigCClane and mouseOrigCClane <= 127 then -- CC, 7 bit (single lane)
    laneIsCC7BIT = true
    laneMax = 127
    laneMin = 0
elseif mouseOrigCClane == 0x203 then -- Channel pressure
    laneIsCHPRESS = true
    laneMax = 127
    laneMin = 0
elseif 256 <= mouseOrigCClane and mouseOrigCClane <= 287 then -- CC, 14 bit (double lane)
    laneIsCC14BIT = true
    laneMax = 16383
    laneMin = 0
elseif mouseOrigCClane == 0x201 then
    laneIsPITCH = true
    laneMax = 16383
    laneMin = 0
else -- not a lane type in which script can be used.
    reaper.ShowMessageBox("This script will only work in the following MIDI lanes: \n * 7-bit CC, \n * 14-bit CC, \n * Pitch, or\n * Channel Pressure.", "ERROR", 0)
    return(0)
end


-------------------------------------------------------------------
-- Events will be inserted in the active channel of the active take
defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")


-----------------------------------------------------------------------------------------------
-- Get the starting PPQ (horizontal) position of the ramp.  Must check whether snap is enabled.
mouseOrigPPQpos = math.max(0, reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()))

isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1)
local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
if isSnapEnabled then
    -- If snap is enabled, we must go through several steps to find the closest grid position
    --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
    -- !! Note that this script does not take swing into account when calculating the grid
    -- First, calculate this take's PPQ:
    -- Calculate position of grid immediately before mouse position
    QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
    local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseOrigPPQpos) -- Mouse position in quarter notes
    local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
    gridOrigPPQpos = math.floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
else 
    -- Otherwise, destination PPQ is exact mouse position
    gridOrigPPQpos = math.floor(mouseOrigPPQpos + 0.5)
end  


-----------------------------------------------------------------------
-- While we are busy with grid, get CC density 'grid' values
-- First, Get the default grid resolution as set in Preferences -> 
--    MIDI editor -> "Events per quarter note when drawing in CC lanes"
CCdensity = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
CCdensity = math.floor(math.max(4, math.min(128, math.abs(CCdensity)))) -- If user selected "Zoom dependent", density<0
PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
PPperCC = PPQ/CCdensity -- Not necessarily an integer!


------------------------------------
-- Deselect all MIDI before drawing?  
-- Note that this will create an additional undo point
if deselectAllBeforeDrawing then
    reaper.MIDIEditor_OnCommand(editor, 40214) -- Edit: Unselect all (in all editable takes)
end


---------------------------------------------------------------------------------------
-- Unlike the scripts that edit and change existing events, this scripts does not need
--    to do any parsing before starting drawing.
-- Parsing (and deletion) will be performed at the end, in the onexit function.
gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
if gotAllOK then
    MIDIlen = MIDIstring:len()
    originalOffset = string.unpack("i4", MIDIstring, 1)
    MIDIstringSub5 = MIDIstring:sub(5)
else -- if not gotAllOK
    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
    return false 
end


--------------------------------------------------------------------
-- Set up the starting CC values, doing chasing if necessary.
-- By default (if not doChase, or if no pre-existing CCs are found),
--    use mouse starting values.
lastChasedValue = mouseOrigCCvalue
nextChasedValue = mouseOrigCCvalue     

if doChase then
    local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local nextPos = 1
    local offset, flags, msg
        
    -- Iterate through all the (original) MIDI in the take, searching for events closest to gridOrigPPQpos
    -- MOTE: This function assumes that the MIDI is sorted.  This should almost always be true, unless there 
    --    is a bug, or a previous script has neglected to re-sort the data.
    -- Even a tiny edit in the MIDI editor induced the editor to sort the MIDI.
    -- By assuming that the MIDI is sorted, the script avoids having to call the buggy MIDI_sort function or 
    --    the slow 2x Invert Selection actions, and also avoids making any edits to the take at this point.
    while nextPos <= MIDIlen do
        
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, nextPos)
        
        -- A little check if parsing is still OK
        if flags&252 ~= 0 then -- 252 = binary 11111100.
            reaper.ShowMessageBox("The MIDI data uses an unknown format that could not be parsed.  No events will be deleted."
                                  .. "\n\nPlease report the problem in the thread http://forum.cockos.com/showthread.php?t=176878:"
                                  .. "\nFlags = " .. string.char(flags)
                                  .. "\nMessage = " .. msg
                                  , "ERROR", 0)
            return false
        end
        
        -- For backward chase, CC must be *before* gridOrigPPQpos
        -- For forward chase, CC can be after *or at* gridOrigPPQpos
        runningPPQpos = runningPPQpos + offset
        if msg:len() >= 2 then
            if runningPPQpos < gridOrigPPQpos then
                local msg1 = msg:byte(1)
                if msg1&0xF == defaultChannel then
                    local eventType = msg1>>4 
                    local msg2      = msg:byte(2)
                    if laneIsCC7BIT then 
                        if eventType == 11 and msg2 == mouseOrigCClane then 
                            lastChasedValue = msg:byte(3) 
                        end
                    elseif laneIsPITCH then 
                        if eventType == 14 then 
                            lastChasedValue = ((msg:byte(3))<<7) | msg2 
                        end
                    elseif laneIsCC14BIT then 
                        if eventType == 11 and msg2 == mouseOrigCClane-256 then 
                            lastChasedValue = msg:byte(3)<<7 
                        end -- Ignore LSB?
                    elseif laneIsCHPRESS then 
                        if eventType == 13 then 
                            lastChasedValue = msg2 
                        end
                    end
                end
            else 
                local msg1 = msg:byte(1)
                if msg1&0xF == defaultChannel then
                    local eventType = msg1>>4
                    local msg2      = msg:byte(2)
                    if laneIsCC7BIT then if eventType == 11 and msg2 == mouseOrigCClane then
                        nextChasedValue = msg:byte(3)
                        break
                        end
                    elseif laneIsPITCH then if eventType == 14 then
                        nextChasedValue = ((msg:byte(3))<<7) | msg2
                        break
                        end
                    elseif laneIsCC14BIT then if eventType == 11 and msg2 == mouseOrigCClane-256 then -- Ignore LSB?
                        nextChasedValue = msg:byte(3)<<7
                        break
                        end
                    elseif laneIsCHPRESS then if eventType == 13 then
                        nextChasedValue = msg2
                        break
                        end
                    end
                end
            end 
        end -- if msg:len() >= 2
    end -- while nextPos <= MIDIlen    
end -- if doChase

-- Give the variables values, in case the deferred drawing function quits before completing a single loop
gridNewPPQpos   = gridOrigPPQpos
lineLeftPPQpos  = gridOrigPPQpos
lineRightPPQpos = gridOrigPPQpos
lineLeftValue   = lastChasedValue
lineRightValue  = lastChasedValue


----------------------------------------------------------------------------------
-- OK, all tests passed, and the script wil now start making changes to the take, 
--    so toggle toolbar button (if any) and define atexit with its Undo statements
_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

reaper.atexit(onexit)


-------------------------------------------------------------
-- Finally, start running the loop!
-- (But first, reset the mousewheel movement.)
is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()

loop_trackMouseMovement()

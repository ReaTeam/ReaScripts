--[[
ReaScript name: js_Draw linear or curved ramps in real time, chasing start values.lua
Version: 3.30
Author: juliansader
Screenshot: http://stash.reaper.fm/27627/Draw%20linear%20or%20curved%20ramps%20in%20real%20time%2C%20chasing%20start%20values%20-%20Copy.gif
Website: http://forum.cockos.com/showthread.php?t=176878
REAPER version: v5.32 or later
Extensions: SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  Draw linear or curved ramps of CC and pitchwheel events in real time (chasing start values).
               
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


  # INSTRUCTIONS
  
  This script requires:
  * a keyboard shortcut to start the script, as well as
  * a mousewheel modifier to control the shape of the ramp.
    
  
  KEYBOARD SHORTCUT
  
  There are two ways in which the script can be started via a keyboard shortcut:  
  
  1) First, the script can be linked to its own easy-to-remember shortcut key, such as "Ctrl+tab" for chase+ramp.  
      (Using the standard steps of linking any REAPER action to a shortcut key.)
    
  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",
          can each be linked to a toolbar button.  
     - In this case, each script does not need to be linked to its own shortcut key.  
     - Instead, only the master control script, with the long name 
          "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
       needs to be linked to a keyboard shortcut.
     - Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
          and this selected (armed) script can then be run by using the shortcut for the 
          aforementioned "js_Run..." script.
     - For further instructions - please refer to the "js_Run..." script.      
  
  Note: Since this function is a user script, the way it responds to shortcut keys and 
    mouse buttons is opposite to that of REAPER's built-in mouse actions 
    with mouse modifiers:  To run the script, press the shortcut key *once* 
    to start the script and then move the mouse *without* pressing any 
    mouse buttons.  Press the shortcut key again once to stop the script.  
      
  (The first time that the script is stopped, REAPER will pop up a dialog box 
    asking whether to terminate or restart the script.  Select "Terminate"
    and "Remember my answer for this script".)
  
  
  MOUSEWHEEL MODIFIER
  
  A mousewheel modifier is a combination such as Ctrl+mousewheel, that can be assigned to an
  Action, similar to how keyboard shortcuts are assigned.
  
  As is the case with keyboard shortcuts, the script can either be controlled via its own
  mousewheel modifier, or via the mousewheel modifier that is linked to the "js_Run..." control script.
  
  Linking each script to its own mousewheel modifier is not ideal, since it would mean that the user 
  must remember several modifier combinations, one for each script.  (Mousewheel modifiers such as 
  Ctrl+Shift+mousewheel are more difficult to remember than keyboard shortcuts such as "tab".)
  
  An easier option is to link a single mousewheel+modifier shortcut to the "js_Run..." script, 
  and this single mousewheel+modifier can then be used to control any of the other "lane under mouse" scripts. 
  
  NOTE: The mousewheel modifier that is assigned to the "js_Run..." script can be used to control 
      the other scripts, including the Draw ramps scripts, even if these scripts
      were started from their own keyboard shortcuts.      
              
  
  USER CUSTOMIZABLE PARAMETERS
  
  To enable/disable chasing of existing CC values, set the "doChase" parameter in the 
      USER AREA at the beginning of the script to "false".
      
  To disable snap-to-grid altogether, irrespective of the MIDI editor's snap setting, 
      set "neverSnapToGrid" to "true".
      
  The default ramp shape can be changed from linear to any power curve, by changing the 
      "defaultShapePower" parameter.  To set the default shape to parabolic, use 2 or 0.5.
   
  To enable/disable skipping of redundant CCs, set the "skipRedundant" parameter.
  
  To enable/disable deselection of other CCs in the same lane as the new ramp (and in the active take), 
      set the "deselectEverythingInLane" parameter.  This allows easy editing of only the new 
      ramp after drawing.
      
  
  PERFORMANCE TIPS
  
  * The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and editable takes. If the MIDI editor is slow, try reducing the number of editable and visible tracks.
      
  * If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin. 
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
  * v3.11 (2017-01-09)
    + Updated for REAPER v.5.32.
    + Ramps are drawn in front of other selected events in lane.
    + Script works in looped takes.
    + Script works in inline editor, but can only draw in channel 1.
  * v3.20 (2017-01-21)
    + Allow drawing of ramp from a starting position on lane divider.
    + New option "neverSnapToGrid".
    + New option "defaultShapePower".
  * v3.21 (2017-01-30)
    + Improved reset of toolbar button.
  * v3.22 (2017-03-13)
    + Temporary workaround for 'disappearing CCs' bug in MIDI editor.
    + In Tempo track, insert CCs (tempos) at MIDI editor grid spacing.    
  * v3.23 (2017-03-14)
    + Fix chasing bug that was introduced yesterday.      
  * v3.24 (2017-03-18)
    + More extensive instructions in header.
  * v3.30 (2017-07-23)
    + Mouse cursor changes to indicate that script is running.     
]]

----------------------------------------
-- USER AREA
-- Settings that the user can customize.

    -- It may aid workflow if this script is saved in two different versions, each with 
    --    a shortcut key.  In one version, chasing is set to true (for smooth ramping), while
    --    in the other it is set to false (for exact positioning at mouse position).  Remember
    --    that ramp endpoints can also easily be re-positioned using the Tilt script.
    local doChase = true -- True or false
    
    -- Should the script follow the MIDI editor's snap-to-grid setting, or should the
    --    script ignore the snap-to-grid setting and never snap to the grid?
    local neverSnapToGrid = false -- true or false
    
    -- The shape of the ramp can be adjusted with the mousewheel while the script is running.
    --    (And, of course, the shape can also be adjusted afterwards, using the Warp scripts.)
    -- A third option is to set the default shape here:  Use defaultShapePower = 1 for linear,
    --    2 for 'slow start' parabolic, and 0.5 for 'fast start' parabolic, etc.
    local defaultShapePower = 1 -- A non-negative number
    
    local skipRedundant = true -- true or false: Do not draw redundant events.
    local deleteOnlyDrawChannel = true -- true or false: 
    local deselectEverythingInLane = false -- true or false: Deselect all CCs in the same lane as the new ramp (and in active take). 
    
-- End of USER AREA


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

-- General note:
-- REAPER's MIDI API functions such as InsertCC and SetCC are very slow if the active take contains 
--    hundreds of thousands of MIDI events.  
-- Therefore, this script will not use these functions, and will instead directly access the item's 
--    raw MIDI stream via new functions that were introduced in v5.30: GetAllEvts and SetAllEvts.

-- The MIDI data will be stored in the string MIDIstring.  While drawing, in each cycle a string with 
--    new events will be concatenated *in front* of the original MIDI data, and loaded into REAPER 
--    as the new MIDI data.
-- In v3.11, the new MIDI was concatenated at the *end*, to ensure that the line's events are drawn 
--    in front of the take's original MIDI events.  However, this failed due to the bug described in
--    http://forum.cockos.com/showthread.php?t=189343.
-- This script will therefore 1) concatenated the new MIDI in front, to ensure that the CCs don't
--    disappear, and 2) all CCs in the target lane will *temporarily* be deselected while drawing.

-- The offset of the first event will be stored separately - not in MIDIstring - since this offset 
--    will need to be updated in each cycle relative to the PPQ positions of the edited events.
local MIDIstring
local originalOffset
local MIDIstringSub5 -- MIDIstring without the first 4 byte of the original offset, and with all CCs in target lane deselected.

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
local mouseOrigCClane, mouseOrigCCvalue, mouseOrigPPQpos, mouseOrigPitch, mouseOrigCClaneID
local snappedOrigPPQpos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)
local isInline -- Is the user using the inline MIDI editor?  (The inline editor does not have access to OnCommand.)

-- If doChase is false, or if no pre-existing CCs are found, these will be the same as mouseOrigCCvalue
local lastChasedValue -- value of closest CC to the left
local nextChasedValue -- value of closest CC to the right

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCClane, mouseNewCCvalue, mouseNewPPQpos, mouseNewPitch, mouseNewCClaneID
local snappedNewPPQpos 
local mouseWheel = defaultShapePower -- Track mousewheel movement

-- The CCs will be inserted into the MIDI string from left to right
local lineLeftPPQpos, lineLeftValue, lineRightPPQpos, lineRightValue

-- REAPER preferences and settings that will affect the drawing of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-to-grid is enabled in the editor
local defaultChannel -- In case new MIDI events will be inserted, what is the default channel?
local CCdensity -- CC resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"

-- Variables that will be used to calculate the CC spacing
local PPperCC -- ticks per CC ** not necessarily an integer **
local PPQ -- ticks per quarter note
local firstCCinTakePPQpos -- CC spacing should not be calculated from PPQpos = 0, since take may not start on grid.

-- The crucial function BR_GetMouseCursorContext gets slower and slower as the number of events in the take increases.
-- Therefore, the active take will be emptied *before* calling the function, using MIDI_SetAllEvts.
local sourceLengthTicks -- = reaper.BR_GetMidiSourceLenPPQ(take)
local AllNotesOffMsg = string.char(0xB0, 0x7B, 0x00)
local AllNotesOffString -- = string.pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
local loopStartPPQpos -- Start of loop iteration under mouse
--local takeIsCleared = false --Flag to record whether the take has been cleared (and must therefore be uploaded again before quitting)

-- Some internal stuff that will be used to set up everything
local _, item, take, editor, isInline, QNperGrid

-- I am not sure that defining these functions as local really helps to spred up the script...
local s_unpack = string.unpack
local s_pack   = string.pack
local m_floor  = math.floor
local m_cos = math.cos
local m_pi  = math.pi
--local t_insert = table.insert -- using myTable[c]=X is much faster than table.insert(myTable, X)

-- User preferences that can be customized in the js_MIDI editing preferences script
local mustDrawCustomCursor


--#############################################################################################
-----------------------------------------------------------------------------------------------
-- The function that will be 'deferred' to run continuously
-- There are three bottlenecks that impede the speed of this function:
--    Minor: reaper.BR_GetMouseCursorContext(), which must unfortunately unavoidably be called before 
--           reaper.BR_GetMouseCursorContext_MIDI(), and which (surprisingly) gets much slower as the 
--           number of MIDI events in the take increases.
--           ** This script will therefore apply a nifty trick to speed up this function:  using
--           MIDI_SetAllEvts, the take will be cleared of all MIDI before running BR_...! **
--    Minor: MIDI_SetAllEvts (when filled with hundreds of thousands of events) is not fast - but is 
--           infinitely better than the standard API functions such as MIDI_SetCC.
--    Major: Updating the MIDI editor between defer cycles is by far the slowest part of the whole process.
--           The more events in visible and editable takes, the slower the updating.  MIDI_SetAllEvts
--           seems to get slowed down more than REAPER's native Actions such as Invert Selection.
--           If, in the future, the REAPER API provides a way to toggle take visibility in the editor,
--           it may be helpful to temporarily make all non-active takes invisible. 
-- The Lua script parts of this function - even if it calculates thousands of events per cycle,
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
    --takeIsCleared = true       
    reaper.MIDI_SetAllEvts(take, AllNotesOffString)
    -- Tooltip position is changed immediately before getting mouse cursor context, to prevent cursor from being above tooltip.
    if mustDrawCustomCursor then
        local mouseXpos, mouseYpos = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(" ∕ ", mouseXpos+7, mouseYpos+8, true)
    end
    window, segment, details = reaper.BR_GetMouseCursorContext()  
    if SWS283 == true then 
        _, mouseNewPitch, mouseNewCClane, mouseNewCCvalue, mouseNewCClaneID = reaper.BR_GetMouseCursorContext_MIDI()
    else -- SWS287
        _, _, mouseNewPitch, mouseNewCClane, mouseNewCCvalue, mouseNewCClaneID = reaper.BR_GetMouseCursorContext_MIDI()
    end
    
    ----------------------------------------------------------------------------------
    -- What must the script do if the mouse moves out of the original CC lane area?
    -- Per default, the script will terminate.  This is an easy way to ensure that 
    --    the script does not continue to run indefinitely without the user realising.
    -- However, if mouse crosses the top or bottom, the script must make sure that 
    --    maximum or minimum values are not skipped, so in these cases the script 
    --    will complete the function before quitting.
    if laneIsPIANOROLL then
        if not (segment == "notes") then 
            return 
        end
    elseif segment == "notes" 
        or (details == "cc_lane" and mouseNewCClaneID < mouseOrigCClaneID and mouseNewCClaneID >= 0) 
        then
        mouseNewCCvalue = laneMax
        mustQuitAfterDrawingOnceMore = true
    elseif details == "cc_lane" and mouseNewCClaneID > mouseOrigCClaneID then
        mouseNewCCvalue = laneMin
        mustQuitAfterDrawingOnceMore = true        
    elseif mouseNewCClane ~= mouseOrigCClane then
        return
    elseif mouseNewCCvalue == -1 then 
        mouseNewCCvalue = laneMax -- If -1, it means that the mouse is over the separator above the lane.
    end
    
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
    if moved > 0 then mouseWheel = mouseWheel * 1.1
    elseif moved < 0 then mouseWheel = mouseWheel / 1.1
    end
    --[[if moved > 0 then mouseWheel = mouseWheel + 0.2
    elseif moved < 0 then mouseWheel = mouseWheel - 0.2
    end]]
    
    ------------------------------------------
    -- Get mouse new PPQ (horizontal) position
    -- (And prevent mouse line from extending beyond item boundaries.)
    mouseNewPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
    mouseNewPPQpos = mouseNewPPQpos - loopStartPPQpos
    if mouseNewPPQpos < 0 then mouseNewPPQpos = 0
    elseif mouseNewPPQpos > sourceLengthTicks-1 then mouseNewPPQpos = sourceLengthTicks-1
    else mouseNewPPQpos = m_floor(mouseNewPPQpos + 0.5)
    end
    
    if neverSnapToGrid then
        snappedNewPPQpos = mouseNewPPQpos
    else
        if isInline then
            local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, mouseNewPPQpos)
            local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
            snappedNewPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos) + 0.5)
        elseif isSnapEnabled then
            local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseNewPPQpos) -- Mouse position in quarter notes
            local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
            snappedNewPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
        -- Otherwise, destination PPQ is exact mouse position
        else 
            snappedNewPPQpos = mouseNewPPQpos
        end -- if isSnapEnabled
    end
        
    -----------------------------------------------------------
    -- Prefer to draw the line from left to right, so check whether mouse is to left or right of starting point
    -- The line's startpoint event 'chases' existing CC values.
    if snappedNewPPQpos >= snappedOrigPPQpos then
        mouseToRight = true
        lineLeftPPQpos = snappedOrigPPQpos
        lineLeftValue  = lastChasedValue
        lineRightPPQpos = snappedNewPPQpos
        lineRightValue  = mouseNewCCvalue
    else 
        mouseToRight = false
        lineLeftPPQpos = snappedNewPPQpos
        lineLeftValue  = mouseNewCCvalue
        lineRightPPQpos = snappedOrigPPQpos
        lineRightValue  = nextChasedValue
    end    
            
    -----------------------------------------------------------------------------------
    -- Clean previous tableLine.  All the new MIDI events will be stored in this table, 
    --    and later concatenated into a single string.
    tableLine = {}
    local c = 0 -- Count index in tableLine - This is faster than using table.insert or even #table+1
    
    -- The MIDI data of the line will be inserted AFTER the existing MIDI, so the starting
    --    PPQ position from which to calculate offsets is lastOrigMIDIPPQpos.
    local lastPPQpos = 0

    if lineLeftPPQpos ~= lineRightPPQpos then
    
        -- Insert the leftmost endpoint (which is not necessarily a grid position)
        local offset = lineLeftPPQpos-lastPPQpos
        if laneIsCC7BIT then
            c = c + 1
            tableLine[c] = s_pack("i4BI4BBB", offset, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane, lineLeftValue)
        elseif laneIsPITCH then
            c = c + 1
            tableLine[c] = s_pack("i4BI4BBB", offset, 1, 3, 0xE0 | defaultChannel, lineLeftValue&127, lineLeftValue>>7)
        elseif laneIsCHPRESS then
            c = c + 1
            tableLine[c] = s_pack("i4BI4BB",  offset, 1, 2, 0xD0 | defaultChannel, lineLeftValue)
        else -- laneIsCC14BIT
            c = c + 1
            tableLine[c] = s_pack("i4BI4BBB", offset, 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-256, lineLeftValue>>7)
            c = c + 1
            tableLine[c] = s_pack("i4BI4BBB", 0             , 1, 3, 0xB0 | defaultChannel, mouseOrigCClane-224, lineLeftValue&127)
        end
        local lastValue = lineLeftValue
        lastPPQpos = lineLeftPPQpos
        
        
        -- Now insert all the CCs in-between the endpoints.  These positions will follow the "midiCCdensity" setting (which 
        --    is usually much finer than the editor's "grid" setting.
        -- First, find next PPQ position at which CCs will be inserted.  
        local nextCCdensityPPQpos = firstCCinTakePPQpos + PPperCC * math.ceil((lineLeftPPQpos+1-firstCCinTakePPQpos)/PPperCC)
        
        local PPQrange = lineRightPPQpos - lineLeftPPQpos
        local valueRange = lineRightValue - lineLeftValue
        local power, insertValue, mouseWheelLargerThanOne
        if mouseWheel >= 1 then 
            mouseWheelLargerThanOne = true -- I expect that accessing local boolean variables are faster than comparing numbers
            power = mouseWheel 
        else 
            power = 1/mouseWheel 
        end
        
        for PPQpos = nextCCdensityPPQpos, lineRightPPQpos-1, PPperCC do
            insertPPQpos = m_floor(PPQpos + 0.5)
            -- Powers <1 and >1 give different shapes, so these two options select the one that looks (to me) most musical 
            if mouseWheelLargerThanOne then
                insertValue = m_floor(lineLeftValue + (valueRange)*(((insertPPQpos-lineLeftPPQpos)/(PPQrange))^(power)) + 0.5)
            else
                insertValue = m_floor(lineRightValue - (valueRange)*(((lineRightPPQpos-insertPPQpos)/(PPQrange))^(power)) + 0.5)
            end
            
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
    
    end -- if lineLeftPPQpos ~= lineRightPPQpos
    
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

    ------------------------------------------------------------------------------------------------
    -- These drawing scripts will parse the MIDI before quitting in order to delete overlapping CCs,
    --    so do not need to upload into take if going to quit.   
    if mustQuitAfterDrawingOnceMore then return end
                                
    ------------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI string!  
    local newOrigOffset = originalOffset-lineRightPPQpos
    reaper.MIDI_SetAllEvts(take, table.concat(tableLine)
                                .. string.pack("i4", newOrigOffset)
                                .. MIDIstringSub5)    
    if isInline then reaper.UpdateArrange() end
    
    ---------------------------------------------------------
    -- Continuously loop the function - if don't need to quit
    reaper.runloop(loop_trackMouseMovement)
        
end -- loop_trackMouseMovement()

-------------------------------------------

----------------------------------------------------------------------------
function onexit()
    
    -- Remove tooltip 'custom cursor'
    reaper.TrackCtl_SetToolTip("", 0, 0, true)
    
    -- Before exiting, delete existing CCs in the line's range (and channel)
    -- Remember that the loop function may quit after clearing the active take.  The delete function 
    --    will also ensure that the MIDI is re-uploaded into the active take.
    deleteExistingCCsInRange()
    
    -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
    --    causing infinitely extended notes or zero-length notes.
    -- Fortunately, these bugs were seemingly all fixed in v5.32.
    reaper.MIDI_Sort(take)
    
    -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        reaper.MIDI_SetAllEvts(take, MIDIstring) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
    end
        
    if isInline then reaper.UpdateArrange() end  
    
    -- Communicate with the js_Run.. script that this script is exiting
    reaper.DeleteExtState("js_Mouse actions", "Status", true)
    
    -- Deactivate toolbar button (if it has been toggled)
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 
        and type(prevToggleState) == "number"         
        then
        reaper.SetToggleCommandState(sectionID, cmdID, prevToggleState)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
              
    -- Write nice, informative Undo strings
    if mouseWheel == 0 then shapeStr = "linear" else shapeStr = "curved" end
    if laneIsCC7BIT then 
        undoString = "Draw "..shapeStr.." ramp in 7-bit CC lane ".. mouseOrigCClane
    elseif laneIsCHPRESS then
        undoString = "Draw "..shapeStr.." ramp in channel pressure lane"
    elseif laneIsCC14BIT then
        undoString = "Draw "..shapeStr.." ramp in 14 bit CC lanes ".. 
                                  tostring(mouseOrigCClane-256) .. "/" .. tostring(mouseOrigCClane-224)
    elseif laneIsPITCH then
       undoString = "Draw "..shapeStr.." ramp in pitchwheel lane"
    end   
    -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
    --    in the undo point to changes in this specific item.
    reaper.Undo_OnStateChange_Item(0, undoString, item)

end -- function onexit

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

function deleteExistingCCsInRange()  
            
    -- The MIDI strings of non-deleted events will temnporarily be stored in a table, tableRemainingEvents[],
    --    and once all MIDI data have been parsed, this table (which excludes the strings of targeted events)
    --    will be concatenated to replace the original MIDIstring.
    -- The targeted events will therefore have been extracted from the MIDI string.
    local tableRemainingEvents = {}     
    local r = 0 -- Count index in tableRemainingEvents - This is faster than using table.insert or even #table+1 

    local newOffset = 0
    local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
    local lastRemainPPQpos = 0 -- PPQ position of last event that was *not* targeted, and therefore stored in tableRemainingEvents.
    local prevPos, nextPos, unchangedPos = 1, 1, 1 -- Keep record of position within MIDIstring. unchangedPos is position from which unchanged events van be copied in bulk.
    local mustUpdateNextOffset -- If an event has bee deleted from the MIDI stream, the offset of the next remaining event must be updated.
    
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
    tableLine[1] = s_pack("i4", lineLeftPPQpos) .. tableLine[1]:sub(5)
    local remainOffset = s_unpack("i4", tableRemainingEvents[1])
    tableRemainingEvents[1] = s_pack("i4", remainOffset-lineRightPPQpos) .. tableRemainingEvents[1]:sub(5)

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


---------------------------------------------------------
-- Check whether the user-customizable values are usable.
if not (type(neverSnapToGrid) == "boolean") then 
    reaper.ShowMessageBox('The parameter "neverSnapToGrid" may only take on the boolean values "true" or "false".', "ERROR", 0)
    return false 
elseif not (type(doChase) == "boolean") then
    reaper.ShowMessageBox('The parameter "doChase" may only take on the boolean values "true" or "false".', "ERROR", 0)
    return false    
elseif not (type(skipRedundant) == "boolean") then 
    reaper.ShowMessageBox('The parameter "skipRedundant" may only take on the boolean values "true" or "false".', "ERROR", 0)
    return false
elseif not (type(deleteOnlyDrawChannel) == "boolean") then 
    reaper.ShowMessageBox('The parameter "deleteOnlyDrawChannel" may only take on the boolean values "true" or "false".', "ERROR", 0)
    return false
elseif not (type(deselectEverythingInLane) == "boolean") then 
    reaper.ShowMessageBox('The parameter "deselectEverythingInLane" may only take on the boolean values "true" or "false".', "ERROR", 0)
    return false
elseif not (type(defaultShapePower) == "number" and defaultShapePower > 0) then
    reaper.ShowMessageBox('The parameter "defaultShapePower" must be a number, and must be larger than 0.', "ERROR", 0)
    return false       
end            
    

-----------------------------------------------------------------------------
-- Check whether SWS is available, as well as the required version of REAPER.
version = tonumber(reaper.GetAppVersion():match("(%d+%.%d+)"))
if version == nil or version < 5.32 then
    reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                          .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                          , "ERROR", 0)
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
    isInline, mouseOrigPitch, mouseOrigCClane, mouseOrigCCvalue, mouseOrigCClaneID = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, isInline, mouseOrigPitch, mouseOrigCClane, mouseOrigCCvalue, mouseOrigCClaneID = reaper.BR_GetMouseCursorContext_MIDI()
end 
-- If the mouse starts on the divider between lanes, the ramp must be drawn from either the maximum
--    or minimum value of the lane.  The lane is undetermined, however, so the script must loop till user moves mouse into a lane.
-- To optimize responsiveness, the script will do some other stuff before re-visiting the mouse position.

    
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
item = reaper.GetMediaItemTake_Item(take)
if not reaper.ValidatePtr(item, "MediaItem*") then 
    reaper.ShowMessageBox("Could not determine the item to which the active take belongs.", "ERROR", 0)
    return(false)
end


-------------------------------------------------------------------
-- Events will be inserted in the active channel of the active take
if isInline then
    defaultChannel = 0 -- Current versions of REAPER do not provide API access to inline editor defaults channel.
else
    defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
end


------------------------------------------------------------------------------------
-- If the CCs are being drawn in the "Tempo" track, CCs will be inserted at the MIDI 
--    editor's grid spacing.
-- In all other cases, CCs density will follow the setting in
-- Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes".
local track = reaper.GetMediaItemTake_Track(take)
local trackNameOK, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)

if trackName == "Tempo" then
    local QNperCC = reaper.MIDI_GetGrid(take)
    CCdensity = math.floor((1/QNperCC) + 0.5)
else
    CCdensity = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
    CCdensity = m_floor(math.max(4, math.min(128, math.abs(CCdensity)))) -- If user selected "Zoom dependent", density<0
end
local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
PPperCC = PPQ/CCdensity -- Not necessarily an integer!
firstCCinTakePPQpos = reaper.MIDI_GetPPQPosFromProjQN(take, math.ceil(startQN*CCdensity)/CCdensity)


---------------------------------------------------------------------------------------
-- Unlike the scripts that edit and change existing events, this scripts does not need
--    to do any parsing before starting drawing.
-- Parsing (and deletion) will be performed at the end, in the onexit function.
gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
if gotAllOK then
    MIDIlen = MIDIstring:len()
    originalOffset = string.unpack("i4", MIDIstring, 1)
    --MIDIstringSub5 = MIDIstring:sub(5) -- In new version that deselects CCs in target lane before drawing, MIDIstringSub5 will be defined later, after deselection
else -- if not gotAllOK
    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
    return false 
end


---------------------------------------------------------------------------------
-- Get last PPQ position of take.
-- 1) The MIDI events of the line will be inserted at the end of the MIDI string,
--    so the PPQ offsets must be calculated from the last PPQ position in take.

-- 2) The crucial BR_GetMouseCursorContext function gets slower and slower 
--    as the number of events in the take increases.
-- Therefore, this script will speed up the function by 'clearing' the 
--    take of all MIDI *before* calling the function!
-- To do so, MIDI_SetAllEvts will be run with no events except the
--    All-Notes-Off message that should always terminate the MIDI stream, 
--    and which marks the position of the end of the MIDI source.
-- Instead of parsing the entire MIDI stream to get the final PPQ position,
--    simply get the source length.

-- 3) In addition, the source length will be saved and checked again at the end of
--    the script, to check that no inadvertent shifts in PPQ position happened.
sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)
AllNotesOffString = s_pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
MIDIstringWithoutNotesOff = MIDIstring:sub(1, -13)
lastOrigMIDIPPQpos = sourceLengthTicks - s_unpack("i4", MIDIstring, -12)


-----------------------------------------------------------------------------------------------
-- Get the starting PPQ (horizontal) position of the ramp.  Must check whether snap is enabled.
-- Also, contract to position within item, and then divide by source length to get position
--    within first loop iteration.
mouseOrigPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
local itemLengthTicks = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH"))+0.5)
mouseOrigPPQpos = math.max(0, math.min(itemLengthTicks-1, mouseOrigPPQpos)) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off, so subtract 1.
loopStartPPQpos = (mouseOrigPPQpos // sourceLengthTicks) * sourceLengthTicks
mouseOrigPPQpos = mouseOrigPPQpos - loopStartPPQpos
mouseOrigPPQpos = m_floor(mouseOrigPPQpos + 0.5)

if isInline then
    isSnapEnabled = false
else
    isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1)
end

if neverSnapToGrid then
    snappedOrigPPQpos = mouseOrigPPQpos
else
    if isInline then
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, mouseOrigPPQpos)
        local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
        snappedOrigPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos) + 0.5)
    elseif isSnapEnabled then
        -- If snap is enabled, we must go through several steps to find the closest grid position
        --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
        -- !! Note that this script does not take swing into account when calculating the grid
        -- First, calculate this take's PPQ:
        -- Calculate position of grid immediately before mouse position
        QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseOrigPPQpos) -- Mouse position in quarter notes
        local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
        snappedOrigPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
    else 
        -- Otherwise, destination PPQ is exact mouse position
        snappedOrigPPQpos = mouseOrigPPQpos
    end 
end


----------------------------------------------------------------------------------------------------------
-- Returning to the CC lane...
-- As mentioned above, if the mouse starts on the divider between lanes, the lane is undetermined, 
--    so the script must loop till the user moves the mouse into a lane.
-- To optimize responsiveness, the script has done some other stuff before re-visiting the mouse position.
if mouseOrigCCvalue == -1 then
    mouseStartedOnLaneDivider = true
    repeat
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if SWS283 == true then
            isInline, mouseOrigPitch, mouseOrigCClane, mouseOrigCCvalue, mouseOrigCClaneID = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, isInline, mouseOrigPitch, mouseOrigCClane, mouseOrigCCvalue, mouseOrigCClaneID = reaper.BR_GetMouseCursorContext_MIDI()
        end  
    until details ~= "cc_lane" or mouseOrigCCvalue ~= -1
end
if details ~= "cc_lane" then return end

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

-- If mouse started on divider between lanes, ensure that ramp will be drawn from either max or min value of lane. 
if mouseStartedOnLaneDivider then
    if mouseOrigCCvalue > (laneMax + laneMin)/2 then
        mouseOrigCCvalue = laneMax
    else 
        mouseOrigCCvalue = laneMin
    end
end


----------------------------------------------------------------------------
-- Parse MIDI string and chase starting values.

-- Unfortunately, there are two problems that this script has to circumvent:
-- 1) If the new MIDI is concatenated to the front of MIDIstring, selected events
--    that are later in the string, will overwrite the line's CC bars.
-- 2) If the new MIDI is concatenated to the end of MIDIstring, the MIDI editor
--    may forget to the draw these CCs, if earlier CCs that are earlier in the
--    stream go offscreen.  http://forum.cockos.com/showthread.php?t=189343
-- This script will therefore do the following:
--    The new MIDI will be concatenated in front, but all CCs in the target lane
--    will temporarily be deselected.

-- Since the entire MIDI string must in any case be parsed here, in order to 
--    deselect, lastChasedValue and nextChasedValue will also be calculated.
-- If doChase == false, they will eventually be replaced by mouseOrigCCvalue.

-- By default (if not doChase, or if no pre-existing CCs are found),
--    use mouse starting values.    
-- 14-bit CC must determine both MSB and LSB.  If no LSB is found, simply use 0 as default.
local lastChasedMSB, nextChasedMSB
local lastChasedLSB, nextChasedLSB

-- The script will speed up execution by not inserting each event individually into tableEvents as they are parsed.
--    Instead, only changed (i.e. deselected) events will be re-packed and inserted individually, while unchanged events
--    will be inserted as bulk blocks of unchanged sub-strings.
local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
local prevPos, nextPos, unchangedPos = 1, 1, 1 -- unchangedPos is starting position of block of unchanged MIDI.
local offset, flags, msg
local mustDeselect
local tableEvents = {} -- All events will be stored in this table until they are concatened again
local t = 0 -- Count index in table.  It is faster to use tableEvents[t] = ... than table.insert(...
    
-- Iterate through all the (original) MIDI in the take, searching for events closest to snappedOrigPPQpos
-- MOTE: This function assumes that the MIDI is sorted.  This should almost always be true, unless there 
--    is a bug, or a previous script has neglected to re-sort the data.
-- Even a tiny edit in the MIDI editor induced the editor to sort the MIDI.
-- By assuming that the MIDI is sorted, the script avoids having to call the slow MIDI_sort function, 
--    and also avoids making any edits to the take at this point.
while nextPos <= MIDIlen do

    prevPos = nextPos    
    offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, nextPos)
        
    mustDeselect = false
    -- For backward chase, CC must be *before* snappedOrigPPQpos
    -- For forward chase, CC can be after *or at* snappedOrigPPQpos
    runningPPQpos = runningPPQpos + offset
    if msg:len() >= 2 then
        local msg1 = msg:byte(1)
        local msg2 = msg:byte(2)
        if laneIsCC7BIT then 
            if msg1>>4 == 11 and msg2 == mouseOrigCClane then 
                if flags&1 == 1 then mustDeselect = true end
                if msg1&0x0F  == defaultChannel then
                    if runningPPQpos < snappedOrigPPQpos then lastChasedValue = msg:byte(3) 
                    elseif not nextChasedValue then nextChasedValue = msg:byte(3)
                    end
                end
            end
        elseif laneIsPITCH then 
            if msg1>>4 == 14 then 
                if flags&1 == 1 then mustDeselect = true end
                if msg1&0x0F == defaultChannel then
                    if runningPPQpos < snappedOrigPPQpos then lastChasedValue = ((msg:byte(3))<<7) | msg2 
                    elseif not nextChasedValue then nextChasedValue = ((msg:byte(3))<<7) | msg2 
                    end
                end
            end
        elseif laneIsCC14BIT then -- Should the script ignore LSB?
            if msg1>>4 == 11 then
                if msg2 == mouseOrigCClane-256 then 
                    if flags&1 == 1 then mustDeselect = true end
                    if msg1&0x0F == defaultChannel then
                        if runningPPQpos < snappedOrigPPQpos then lastChasedMSB = msg:byte(3)
                        elseif not nextChasedMSB then nextChasedMSB = msg:byte(3)
                        end
                    end
                elseif msg2 == mouseOrigCClane-224 then 
                    if flags&1 == 1 then mustDeselect = true end
                    if msg1&0x0F == defaultChannel then
                        if runningPPQpos < snappedOrigPPQpos then lastChasedLSB = msg:byte(3)
                        elseif not nextChasedLSB then nextChasedLSB = msg:byte(3)
                        end
                    end
                end
            end
        elseif laneIsCHPRESS then 
            if msg1>>4 == 13 then 
                if flags&1 == 1 then mustDeselect = true end
                if msg1&0x0F == defaultChannel then
                    if runningPPQpos < snappedOrigPPQpos then lastChasedValue = msg2 
                    elseif not nextChasedValue then nextChasedValue = msg2 
                    end
                end
            end
        end
    end -- if msg:len() >= 2
    
    if mustDeselect then
        if unchangedPos < prevPos then
            t = t + 1
            tableEvents[t] = MIDIstring:sub(unchangedPos, prevPos-1)
        end
        t = t + 1
        tableEvents[t] = s_pack("i4Bs4", offset, flags&0xFE, msg)
        unchangedPos = nextPos
    end 
    
end -- while nextPos <= MIDIlen    

-- Iteration complete.  Write the last block of remaining events to table.
--t = t + 1
--tableEvents[t] = MIDIstring:sub(unchangedPos)
--MIDIstringSub5 = table.concat(tableEvents):sub(5)
MIDIstringSub5 = (table.concat(tableEvents) .. MIDIstring:sub(unchangedPos)):sub(5)

-- Finalize chased values, and combine 14-bit CC chased values, if necessary
if not doChase then
    lastChasedValue = mouseOrigCCvalue
    nextChasedValue = mouseOrigCCvalue
else
    if laneIsCC14BIT then
        if not lastChasedLSB then lastChasedLSB = 0 end
        if not nextChasedLSB then nextChasedLSB = 0 end
        if lastChasedMSB then lastChasedValue = (lastChasedMSB<<7) + lastChasedLSB end
        if nextChasedMSB then nextChasedValue = (nextChasedMSB<<7) + nextChasedLSB end
    end
    if not lastChasedValue then lastChasedValue = mouseOrigCCvalue end
    if not nextChasedValue then nextChasedValue = mouseOrigCCvalue end
end
  

----------------------------------------------------------
-- Give values to variables that will be used in onexit(), 
-- in case the deferred drawing function quits before completing a single loop
snappedNewPPQpos = snappedOrigPPQpos
lineLeftPPQpos  = snappedOrigPPQpos 
lineRightPPQpos = snappedOrigPPQpos
lineLeftValue   = lastChasedValue
lineRightValue  = lastChasedValue

---------------------------------------------------------------------------
-- Must the mouse cursor be changed to indicate that the script is running?
-- Currently, the script must 'fake' a custom cursor by drawing a tooltip behind the mouse cursor.
-- Problem: due to the unnecessary sluggishness of the MIDI editor, the tooltip may lag behind the cursor, 
--    and this may appear inelegant to the user.
if reaper.GetExtState("js_Mouse actions", "Draw custom cursor") == "false" then
    mustDrawCustomCursor = false
else
    mustDrawCustomCursor = true
end

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

--[[
ReaScript name:  js_Stretch selected events in lane under mouse.lua
Version: 3.41
Author: juliansader
Screenshot: http://stash.reaper.fm/27594/Stretch%20selected%20events%20in%20lane%20under%20mouse%20-%20Copy.gif
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION
  
  A script for stretching MIDI events in the MIDI editor.
  
  The script can either stretch event positions (horizontally) or values (vertically), depending on the mouse position.
  
  The script only affects events in the MIDI editor lane that is under the mouse cursor.
  
  If snap to grid is enabled, the stretch position will snap to grid.


  # INSTRUCTIONS
  
  To use, 
  1) Select the MIDI events to be stretched,  
  2) Position the mouse over the CC lane of the events to be stretched 
        * In the case of notes, position the mous eover either the Velocity lane, or the "notes area" of the piano roll.
        * To stretch ALL selected events in all lanes together, position the mouse over a lane divider.
  3) To stretch the leftmost events (using the rightmost event as anchor), position the mouse to left of the events' time range.  
        * To stretch events on the right, position the mouse to the right of the events' time range.
        * To stretch the topmost/bottom event values vertically, position mouse closer to the middle of the time range, and to the top/bottom of the lane.
  4) Press the shortcut key.
  5) Move mouse left or right if stretching horizontally, or up or down if stretching vertically.
  6) To flip events, scroll the mousewheel. (If stretching horizontally, flips event positions; if vertically, flips values.)
  6) To exit, move mouse out of CC lane, or press shortcut key again.
          
  
  This script therefore requires:
  * a keyboard shortcut to start the script, as well as
  * a mousewheel modifier to flip events.
    
  
  KEYBOARD SHORTCUT
        
  There are two ways in which this script can be run:  
  
  1) First, the script can be linked to its own easy-to-remember shortcut key, such as "1".  
      (Using the standard steps of linking any REAPER action to a shortcut key.)

  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",
      can each be linked to a toolbar button.  
      * In this case, each script need not be linked to its own shortcut key.  Instead, only the 
        accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
        script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
      * Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
        and this selected (armed) script can then be run by using the shortcut for the 
        aforementioned "js_Run..." script.
      * For further instructions - please refer to the "js_Run..." script.                 
 
  Since this function is a user script, the way it responds to shortcut keys and 
    mouse buttons is opposite to that of REAPER's built-in mouse actions 
    with mouse modifiers:  To run the script, press the shortcut key *once* 
    to start the script and then move the mouse or mousewheel *without* 
    pressing any mouse buttons.  Press the shortcut key again once to 
    stop the script.  

  (The first time that the script is stopped, REAPER will pop up a dialog box 
    asking whether to terminate or restart the script.  Select "Terminate"
    and "Remember my answer for this script".)   
    
    
  MOUSEWHEEL CONTROL
   
  A mousewheel modifier is a combination such as Ctrl+mousewheel, that can be assigned to an
  Action, similar to how keyboard shortcuts are assigned.  
  
  Linking each script to its own mousewheel modifier is not ideal, since it would mean that the user 
  must remember several modifier combinations, one for each script.  (Mousewheel modifiers such as 
  Ctrl+Shift+mousewheel are more difficult to remember than keyboard shortcuts such as "A".)
  
  An easier option is to link a single mousewheel+modifier shortcut to one of the following scripts, 
  which will then broadcast mousewheel movement to any js script that is running:
  
  * js_Run the js_'lane under mouse' script that is selected in toolbar
  * js_Mousewheel - Control js MIDI editing script (if one is running), otherwise scroll up or down
  * js_Mousewheel - Control js MIDI editing script (if one is running), otherwise zoom horizontally
  
  By using the scripts, a single mousewheel+modifier (or even mousewheel without any modifier) can control any of the other mouse editing scripts. 
      
   
  PERFORMANCE TIPS
  
  * The responsiveness of the MIDI editor is significantly influenced by the total number of events in 
      the visible and editable takes. If the MIDI editor is slow, try reducing the number of editable and visible tracks.
      
  * If the MIDI editor gets slow and jerky when a certain VST plugin is loaded, 
      check for graphics driver incompatibility by disabling graphics acceleration in the plugin.
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
  * v3.00 (2016-12-19)
    + Depending on mouse position, can now also stretch event values vertically.
    + Script will also run in inline MIDI editor.
    + Vastly improved speed, especially when working in items with hundreds of thousands of events.
    + Requires REAPER v5.30 or later.
  * v3.10 (2016-12-30)
    + Updated for REAPER v5.32.
    + Script works in looped takes.
  * v3.11 (2017-01-30)
    + Improved reset of toolbar button.
  * v3.12 (2017-03-18)
    + More extensive instructions in header.
  * v3.20 (2017-07-23)
    + Mouse cursor changes to indicate that script is running.    
  * v3.21 (2017-12-14)
    + Tweak mouse cursor icon.
  * v3.30 (2018-03-29)
    + Stretch all selected events in all lanes, if mouse starting position is over lane divider.
  * v3.31 (2018-03-29)
    + Display notification about new feature.
  * v3.40 (2018-05-26)
    + Mousewheel flips events.
  * v3.41 (2018-05-29)
    + Return focus to MIDI editor after arming button in floating toolbar.
]]

---------------------------------------
-- USER AREA
-- Settings that the user can customize

    -- If the starting position of the mouse is within this distance (as a fraction of total time range of selected events) 
    --    of the right or left edge of the time range, the script will will stretch left/right, otherwise top/bottom
    -- Useful values are between 0 and 0.5.
    edgeSize = 0.2
    
    -- If CC events are stretched left or right until they overlap other CCs in the same lane (and same channel), 
    --    should the pre-existing CCs be deleted?
    mustDeleteOverlappingCCs = true
    
-- End of USER AREA


-- ################################################################################################
---------------------------------------------------------------------------------------------------
-- CONSTANTS AND VARIABLES (that modders may find useful)

--[[ General notes:

Speed:
REAPER's MIDI API functions such as InsertCC and SetCC are very slow if the active take contains 
    hundreds of thousands of MIDI events.  
Therefore, this script will not use these functions, and will instead directly access the item's 
    raw MIDI stream via new functions that were introduced in v5.30: GetAllEvts and SetAllEvts.
Parsing of the MIDI stream can be relatively straightforward, but to improve speed even
    further, this script will use several 'tricks', which will unfortunately also make the 
    parsing function, parseAndExtractTargetMIDI, quite complicated.

Sorting:
Prior to v5.32, sorting of MIDI events, either by MIDI_Sort or by other functions such as MIDI_SetNote
    (with sort=true) was endlessly buggy (http://forum.cockos.com/showthread.php?t=184459
    is one of many threads).  In particular, it often mutated overlapping notes or unsorted notes into
    infinitely extende notes.
Finally, in v5.32, these bugs were (seemingly) all fixed.  This new version of the script will therefore
    use the MIDI_Sort function (instead of calling a MIDI editor action via OnCommand to induce sorting).

However, sorting is still relatively slow, so since MIDI will under normal circumstances already be 
    sorted when the script is run (the MIDI editor automatically sorts the data whenever any small edit
    is made), MIDI_Sort will not automatically be called when the script starts.  Instead, offsets will 
    be checked during parsing, and if any negative offsets are detected, MIDI_Sort will be called.
    It is actually faster to check for unsorted data during parsing.
]]

-- The original raw MIDI data will be stored in the MIDIstring string.  While parsing the string, 
--    targeted events (the ones that will be edited) will be removed from the string.
-- The offset of the first event will be stored separately - not in MIDIstring - since this offset 
--    will need to be updated in each cycle relative to the PPQ positions of the edited events.
local MIDIstring -- The original raw MIDI
local remainMIDIstring -- The MIDI that remained after extracting selected events in the target lane
local remainMIDIstringSub5 -- The MIDI that remained, except the very first offset
local remainOffset -- The very first offset of the remaining events
local newRemainOffset -- At each cycle, the very first offset must be updated relative to the edited MIDI. NOTE: In scripts that do not change the positions of events, this will not actually be necessary.

-- When the info of the targeted events is extracted, the info will be stored in several tables.
-- The order of events in the tables will reflect the order of events in the original MIDI, except note-offs, 
--    which will be replaced by note lengths, and notation text events, which will also be stored in a separate table
--    at the same indices as the corresponding notes.
local tableMsg = {}
local tableMsgLSB = {}
local tableMsgNoteOffs = {}
local tableValues = {} -- CC values, 14bit CC combined values, note velocities
local tablePPQs = {}
local tableChannels = {}
local tableFlags = {}
local tableFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
local tablePitches = {} -- This table will only be filled if laneIsVELOCITY or laneIsPIANOROLL
local tableNoteLengths = {}
local tableNotation = {} -- Will only contain entries at those indices where the notes have notation

-- The original value and PPQ ranges of selected events in the target lane will be summarized in:
local origValueMin, origValueMax, origValueRange, origValueLeftmost, origValueRightmost
local origPPQleftmost, origPPQrightmost, origPPQrange
local includeNoteOffsInPPQrange = true -- ***** Should origPPQrange and origPPQrightmost take note-offs into account? Set this flag to true for scripts that stretch or warp note lengths. *****

-- As the edited MIDI events' new values are calculated, each event wil be assmebled into a short string and stored in the tableEditedMIDI table.
-- When the calculations are done, the entire table will be concatenated into a single string, then inserted 
--    at the beginning of MIDIstring (while updating the relative offset of the first event in MIDIstring, 
--    and loaded into REAPER as the new state chunk.
local tableEditedMIDI = {}

-- Starting values and position of mouse 
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local window, segment, details -- given by the SWS function reaper.BR_GetMouseCursorContext()
local laneIsCC7BIT    = false
local laneIsCC14BIT   = false
local laneIsPITCH     = false
local laneIsPROGRAM   = false
local laneIsBANKPROG  = false
local laneIsCHPRESS   = false
local laneIsVELOCITY  = false
local laneIsOFFVEL    = false
local laneIsPIANOROLL = false
local laneIsNOTES     = false -- Includes laneIsPIANOROLL, laneIsVELOCITY and laneIsOFFVEL
local laneIsSYSEX     = false
local laneIsTEXT      = false
local laneIsALL       = false
local laneMin, laneMax -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQpos, mouseOrigPitch, mouseOrigCCLaneID
local gridOrigPPQpos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- Stretch direction, based on initial mouse position
local stretchLEFT   = false
local stretchRIGHT  = false
local stretchTOP    = false
local stretchBOTTOM = false

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQpos, mouseNewPitch, mouseNewCCLaneID
local gridNewPPQpos 
local mouseWheel = 0 -- Track mousewheel movement.  ***** This default value may change, depending on the script and formulae used. *****

-- REAPER preferences and settings that will affect the drawing of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-togrid is enabled in the editor
local defaultChannel -- In case new MIDI events will be inserted, what is the default channel?
local CCdensity -- grid resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
local PPperCC -- ticks per CC ** not necessarily an integer **
local PPQ -- ticks per quarter note

-- The crucial function BR_GetMouseCursorContext gets slower and slower as the number of events in the take increases.
-- Therefore, this script will speed up the function by 'clearing' the take of all MIDI *before* calling the function!
-- To do so, MIDI_SetAllEvts will be run with no events except the All-Notes-Off message that should always terminate 
--    the MIDI stream, and which marks the position of the end of the MIDI source.
-- In addition, the source length when the script begins will be checked against the source length when the script ends,
--    to ensure that the script did not inadvertently shift the positions of non-target events.
local AllNotesOffString -- = string.pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
local sourceLengthTicks -- = reaper.BR_GetMidiSourceLenPPQ(take)
local loopStartPPQpos -- Start of loop iteration under mouse
local takeIsCleared = false --Flag to record whether the take has been cleared (and must therefore be uploaded again before quitting)

-- The functions MIDI_SetAllEvts and BR_GetMouseCursorContext (both of which will be called
--    in each iteration of this script) get considerably slowed down by extra data in non-active takes.
-- (Presumably, both have to deal with the full MIDI chunk.)
-- To speed these function up, the non-active takes will therefore temporarily be cleared of all MIDI data.
-- The MIDI data will be stored in this table and restored when the script exists.
local tOtherTakes = {}

-- Some internal stuff that will be used to set up everything
local _, item, take, editor, isInline

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local t_insert = table.insert -- myTable[i] = X is actually much faster than t_insert(myTable, X)
local m_floor  = math.floor

-- User preferences that can be customized in the js_MIDI editing preferences script
local mustDrawCustomCursor = true
local clearNonActiveTakes  = true
local flipped = false
local prevFlipTime = reaper.time_precise()

  
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
local function trackMouseAndDrawMIDI()

    -------------------------------------------------------------------------------------------
    -- The js_Run... script can communicate with and control the other js_ scripts via ExtState
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(false) end
   
    -------------------------------------------
    -- Track the new mouse (vertical) position.
    -- (Apparently, BR_GetMouseCursorContext must always precede the other BR_ context calls)
    -- ***** Trick: BR_GetMouse... gets slower and slower as the number of events in the take increases.
    --              Therefore, clean the take *before* calling the function!
    takeIsCleared = true
    reaper.MIDI_SetAllEvts(take, AllNotesOffString)
    -- Tooltip position is changed immediately before getting mouse cursor context, to prevent cursor from being above tooltip.
    if mustDrawCustomCursor then
        local mouseXpos, mouseYpos = reaper.GetMousePosition()
        if stretchLEFT or stretchRIGHT then
            reaper.TrackCtl_SetToolTip(" ↔", mouseXpos+7, mouseYpos+8, true)
        else
            reaper.TrackCtl_SetToolTip(" ↕", mouseXpos+7, mouseYpos+8, true) 
        end
    end
    window, segment, details = reaper.BR_GetMouseCursorContext()  
    _, _, mouseNewPitch, mouseNewCCLane, mouseNewCCValue, mouseNewCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
    
    ----------------------------------------------------------------------------------
    -- What must the script do if the mouse moves out of the original CC lane area?
    -- Per default, the script will terminate.  This is an easy way to ensure that 
    --    the script does not continue to run indefinitely without the user realising.
    -- However, if mouse crosses the top or bottom, the script must make sure that 
    --    maximum or minimum values are not skipped, so in these cases the script 
    --    will complete the function before quitting.
    if laneIsPIANOROLL then
        if not (segment == "notes") then 
            return false
        end
    elseif laneIsALL then
        if not (segment == "notes" or details == "cc_lane") then
            return false
        end
    elseif segment == "notes" 
        or (details == "cc_lane" and mouseNewCCLaneID < mouseOrigCCLaneID and mouseNewCCLaneID >= 0) 
        then
        mouseNewCCValue = laneMax
        mustQuitAfterDrawingOnceMore = true
    elseif details == "cc_lane" and mouseNewCCLaneID > mouseOrigCCLaneID then
        mouseNewCCValue = laneMin
        mustQuitAfterDrawingOnceMore = true        
    elseif mouseNewCCLane ~= mouseOrigCCLane then
        return false
    elseif mouseNewCCValue == -1 then 
        mouseNewCCValue = laneMax -- If -1, it means that the mouse is over the separator above the lane.
    end
    
    -----------------------------        
    -- Has mousewheel been moved?     
    -- The script can detect mousewheel in two ways: 
    --    * by being linked directly to a mousewheel mouse modifier (return mousewheel movement with reaper.get_action_context)
    --    * or via the js_Run... script that can run and control the other js_ scripts (return movement via ExtState)
    -- Stretching doesn't follow mousewheel, so this part is commented out.
    is_new, _, _, _, _, _, moved = reaper.get_action_context()
    if not is_new then -- then try getting from script
        moved = tonumber(reaper.GetExtState("js_Mouse actions", "Mousewheel")) or 0
    end
    reaper.SetExtState("js_Mouse actions", "Mousewheel", "0", false) -- Reset after getting update
    if moved ~= 0 then 
        local nowTime = reaper.time_precise() 
        if nowTime > prevFlipTime + 0.5 then -- Prevent multiple flips when using notebook trackpad
            flipped = not flipped
            prevFlipTime = nowTime
        end
    end
    
    ------------------------------------------
    -- Get mouse new PPQ (horizontal) position
    if stretchLEFT or stretchRIGHT then
        -- Prevent stretching beyond item boudaries.
        mouseNewPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
        mouseNewPPQpos = mouseNewPPQpos - loopStartPPQpos
        if mouseNewPPQpos < 0 then mouseNewPPQpos = 0
        elseif mouseNewPPQpos > sourceLengthTicks-1 then mouseNewPPQpos = sourceLengthTicks-1
        else mouseNewPPQpos = math.floor(mouseNewPPQpos + 0.5)
        end
        
        -- Snap to grid, if enabled
        if isInline then
            local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, mouseNewPPQpos)
            local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
            gridNewPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos) + 0.5)
        elseif isSnapEnabled then
            local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseNewPPQpos) -- Mouse position in quarter notes
            local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
            gridNewPPQpos = math.floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
        -- Otherwise, destination PPQ is exact mouse position
        else 
            gridNewPPQpos = mouseNewPPQpos
        end -- if isSnapEnabled
    end

    ---------------------------------------------------------------
    -- Calculate the new raw MIDI data, and write the tableEditedMIDI!
    ---------------------------------------------------------------- THIS IS THE PART THAT CAN EASILY BE MODDED !! ------------------------
    tableEditedMIDI = {} -- Clean previous tableEditedMIDI 
    local c = 0 -- Count index inside tableEditedMIDI - strangely, this is faster than using table.insert or even #tableEditedMIDI+1
    
    local lastPPQpos = 0
        
    if stretchRIGHT then
        
        local stretchFactor = (gridNewPPQpos-origPPQleftmost)/origPPQrange
                        
        -- Safer to keep offsets positive, so check whether events are being reversed
        -- In addtion, avoid drawing multiple events on the same PPQ position
        local startIndex, endIndex, step, newPPQpos, newNoteOffPPQpos, newNoteLength

        if (stretchFactor >= 0 and not flipped) or (stretchFactor < 0 and flipped) then startIndex, endIndex, step = 1, #tablePPQs, 1 -- Step forward
        else startIndex, endIndex, step = #tablePPQs, 1, -1 -- Step backward (forward in PPQ)
        end
            
        for i = startIndex, endIndex, step do
        
            local flippedPPQpos = flipped and (origPPQleftmost + origPPQrightmost - tablePPQs[i]) or tablePPQs[i]
            newPPQpos = m_floor(origPPQleftmost + stretchFactor*(flippedPPQpos - origPPQleftmost) + 0.5)                    
            offset = newPPQpos - lastPPQpos                   
            lastPPQpos = newPPQpos 
            
            -- Remember that notes and 14bit CCs contain more than one event per tablePPQs entry
            
            if tableNoteLengths[i] then -- note event
            
                local flippedNoteOffPPQpos = flipped and (origPPQleftmost + origPPQrightmost - (tablePPQs[i]+tableNoteLengths[i])) 
                                                     or (tablePPQs[i]+tableNoteLengths[i])
                newNoteOffPPQpos = m_floor(origPPQleftmost + stretchFactor*(flippedNoteOffPPQpos - origPPQleftmost) + 0.5)
                -- If reversing notes, make sure that note-on is positioned before note-off
                if newNoteOffPPQpos < newPPQpos then 
                    newPPQpos, newNoteOffPPQpos = newNoteOffPPQpos, newPPQpos
                    newNoteLength = newNoteOffPPQpos - newPPQpos
                    offset = offset - newNoteLength -- (newNoteOffPPQpos - newPPQpos)
                else
                    newNoteLength = newNoteOffPPQpos - newPPQpos
                    lastPPQpos = lastPPQpos + newNoteLength
                end                
                -- Insert note-on
                c = c + 1 
                tableEditedMIDI[c] = s_pack("i4Bs4", offset, tableFlags[i], tableMsg[i])    
                -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                if tableNotation[i] then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", 0, tableFlags[i]&0xFE, tableNotation[i])
                end  
                -- Insert note-off
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4Bs4", newNoteLength, tableFlags[i], tableMsgNoteOffs[i])
                                    
            else           
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4Bs4", offset, tableFlags[i], tableMsg[i])
                
                if tableMsgLSB[i] then -- Only if laneIs14BIT then tableMsgLSB will contain entries 
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", 0, tableFlagsLSB[i], tableMsgLSB[i])
                end
            end
        end  
                    
    elseif stretchLEFT then
    
        local stretchFactor = (origPPQrightmost - gridNewPPQpos)/origPPQrange
                        
        -- Safer to keep offsets positive, so check whether events are being reversed
        -- In addtion, avoid drawing multiple events on the same PPQ position
        local startIndex, endIndex, step, newPPQpos, newNoteOffPPQpos, newNoteLength
        
        if (stretchFactor >= 0 and not flipped) or (stretchFactor < 0 and flipped) then startIndex, endIndex, step = 1, #tablePPQs, 1 
        else startIndex, endIndex, step = #tablePPQs, 1, -1
        end
                    
        for i = startIndex, endIndex, step do        
        
            local flippedPPQpos = flipped and (origPPQleftmost + origPPQrightmost - tablePPQs[i]) or tablePPQs[i]
            newPPQpos = m_floor(origPPQrightmost - stretchFactor*(origPPQrightmost - flippedPPQpos) + 0.5)
            offset = newPPQpos - lastPPQpos
            lastPPQpos = newPPQpos
            
            -- Remember that notes and 14bit CCs contain more than one event per tablePPQs entry
            
            if tableNoteLengths[i] then -- note event
            
                local flippedNoteOffPPQpos = flipped and (origPPQleftmost + origPPQrightmost - (tablePPQs[i]+tableNoteLengths[i])) 
                                                     or (tablePPQs[i]+tableNoteLengths[i])
                newNoteOffPPQpos = m_floor(origPPQrightmost - stretchFactor*(origPPQrightmost - flippedNoteOffPPQpos) + 0.5)
                -- If reversing notes, make sure that note-on is positioned before note-off
                if newNoteOffPPQpos < newPPQpos then 
                    newPPQpos, newNoteOffPPQpos = newNoteOffPPQpos, newPPQpos
                    newNoteLength = newNoteOffPPQpos - newPPQpos
                    offset = offset - newNoteLength -- (newNoteOffPPQpos - newPPQpos)
                else
                    newNoteLength = newNoteOffPPQpos - newPPQpos
                    lastPPQpos = lastPPQpos + newNoteLength
                end
                -- Insert note-on
                c = c + 1 
                tableEditedMIDI[c] = s_pack("i4Bs4", offset, tableFlags[i], tableMsg[i])    
                -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                if tableNotation[i] then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", 0, tableFlags[i]&0xFE, tableNotation[i])
                end     
                -- Insert note-off
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4Bs4", newNoteLength, tableFlags[i], tableMsgNoteOffs[i])
                
            else
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4Bs4", offset, tableFlags[i], tableMsg[i])
                
                if tableMsgLSB[i] then -- Only if laneIs14BIT then tableMsgLSB will contain entries 
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", 0, tableFlagsLSB[i], tableMsgLSB[i])
                end
            end 
        end
    
    elseif stretchTOP then
    
        local stretchFactor = (mouseNewCCValue - origValueMin)/origValueRange
        local newValue
            
        for i = 1, #tablePPQs do
        
            local flippedValue = flipped and (origValueMin + origValueMax - tableValues[i]) or tableValues[i]
            newValue = m_floor(origValueMin + stretchFactor*(flippedValue - origValueMin) + 0.5)
            if newValue > laneMax then newValue = laneMax elseif newValue < laneMin then laneValue = laneMin end
            
            offset = tablePPQs[i] - lastPPQpos
            
            lastPPQpos = tablePPQs[i]
            
            if laneIsCC7BIT then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0xB0 | tableChannels[i], mouseOrigCCLane, newValue)
            elseif laneIsPITCH then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0xE0 | tableChannels[i], newValue&127, newValue>>7)
            elseif laneIsCHPRESS then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tableFlags[i], 2, 0xD0 | tableChannels[i], newValue) -- NB Channel Pressure uses only 2 bytes!
            elseif laneIsCC14BIT then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i],    3, 0xB0 | tableChannels[i], mouseOrigCCLane-256, newValue>>7)
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", 0,      tableFlagsLSB[i], 3, 0xB0 | tableChannels[i], mouseOrigCCLane-224, newValue&127)
            elseif laneIsNOTES then
                -- Insert note-on
                c = c + 1 
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0x90 | tableChannels[i], tablePitches[i], newValue)          
                -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                if tableNotation[i] then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", 0, tableFlags[i]&0xFE, tableNotation[i])
                end
                -- Insert note-off
                c = c + 1 
                tableEditedMIDI[c] = s_pack("i4Bs4", tableNoteLengths[i], tableFlags[i], tableMsgNoteOffs[i])
                lastPPQpos = lastPPQpos + tableNoteLengths[i]
            elseif laneIsPROGRAM then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tableFlags[i], 2, 0xC0 | tableChannels[i], newValue) -- NB Program Select uses only 2 bytes!
            end 
        end
    
    elseif stretchBOTTOM then
    
        local stretchFactor = (origValueMax - mouseNewCCValue)/origValueRange
        local newValue
            
        for i = 1, #tablePPQs do
            
            local flippedValue = flipped and (origValueMin + origValueMax - tableValues[i]) or tableValues[i]
            newValue = m_floor(origValueMax - stretchFactor*(origValueMax - flippedValue) + 0.5)
            if newValue > laneMax then newValue = laneMax elseif newValue < laneMin then laneValue = laneMin end
            
            offset = tablePPQs[i] - lastPPQpos
            
            lastPPQpos = tablePPQs[i]
            
            if laneIsCC7BIT then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0xB0 | tableChannels[i], mouseOrigCCLane, newValue)
            elseif laneIsPITCH then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0xE0 | tableChannels[i], newValue&127, newValue>>7)
            elseif laneIsCHPRESS then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tableFlags[i], 2, 0xD0 | tableChannels[i], newValue) -- NB Channel Pressure uses only 2 bytes!
            elseif laneIsCC14BIT then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i],    3, 0xB0 | tableChannels[i], mouseOrigCCLane-256, newValue>>7)
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BBB", 0,      tableFlagsLSB[i], 3, 0xB0 | tableChannels[i], mouseOrigCCLane-224, newValue&127)
            elseif laneIsNOTES then
                -- Insert note-on
                c = c + 1 
                tableEditedMIDI[c] = s_pack("i4BI4BBB", offset, tableFlags[i], 3, 0x90 | tableChannels[i], tablePitches[i], newValue)         
                -- Since REAPER v5.32, notation (if it exists) must always be inserted *after* its note
                if tableNotation[i] then
                    c = c + 1
                    tableEditedMIDI[c] = s_pack("i4Bs4", 0, tableFlags[i]&0xFE, tableNotation[i])
                end
                -- Insert note-off
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4Bs4", tableNoteLengths[i], tableFlags[i], tableMsgNoteOffs[i])
                lastPPQpos = lastPPQpos + tableNoteLengths[i]
            elseif laneIsPROGRAM then
                c = c + 1
                tableEditedMIDI[c] = s_pack("i4BI4BB",  offset, tableFlags[i], 2, 0xC0 | tableChannels[i], newValue) -- NB Program Select uses only 2 bytes!
            end 
        end
    end
               
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    -- This also updates the offset of the first event in MIDIstring relative to the PPQ position of the last event in tableEditedMIDI
    newRemainOffset = remainOffset-lastPPQpos

    reaper.MIDI_SetAllEvts(take, table.concat(tableEditedMIDI)
                                  .. string.pack("i4", newRemainOffset)
                                  .. remainMIDIstringSub5)
    takeIsCleared = false   
    if isInline then reaper.UpdateItemInProject(item) end

    if mustQuitAfterDrawingOnceMore then return false else return true end
    
end -- trackMouseAndDrawMIDI()


--#######################################################################################
-----------------------------------------------------------------------------------------
function loop_pcall()
    -- Since new versions of the script temporarily clear all MIDI from non-active takes, 
    --    it is important to ensure that, if things go wrong, the script can restore the cleared takes
    --    (otherwise the user may not notice the missing MIDI util it is too late).
    -- Therefore use pcall to call the main trackMouseAndDrawMIDI function.
    local errorFree, mustContinue = pcall(trackMouseAndDrawMIDI)
    
    -- Continuously loop the function - if don't need to quit
    if not errorFree then
        reaper.MB("Error while tracking mouse movement.\n\nOriginal MIDI data will be restored.\n\n", "ERROR", 0)
        reaper.MIDI_SetAllEvts(take, MIDIstring)
        takeIsCleared = false
        return
    elseif not mustContinue then 
        return
    else 
        reaper.runloop(loop_pcall)
    end
end


--############################################################################################
----------------------------------------------------------------------------------------------
function onexit() 
    
    -- Remove tooltip 'custom cursor'
    reaper.TrackCtl_SetToolTip("", 0, 0, true)
    
    -- For safety, the very first step that must be performed when quitting,
    --    is to restore all MIDI to the cleared non-active takes.
    for otherTake, otherMIDI in pairs(tOtherTakes) do
        reaper.MIDI_SetAllEvts(otherTake, otherMIDI)
    end 
    
    if mustDeleteOverlappingCCs 
    and (stretchRIGHT or stretchLEFT)
    and not laneIsNOTES -- (laneIsALL or laneIsCC7BIT or laneIsCC14BIT or laneIsCHPRESS or laneIsPITCH or laneIsPROGRAM or laneIsTEXT or laneIsSYSEX) 
    then
        deleteOverlappingCCs()
    end
    
    -- Remember that the active take was cleared before calling BR_GetMouseCursorContext
    --    So may need to upload MIDI again.
    -- In the stretch script, unlike most of the other scripts, the MIDI may be changed after
    --    entering onexit, so upload edited MIDI even if takeIsCleared = false.
    reaper.MIDI_SetAllEvts(take, table.concat(tableEditedMIDI)
                                  .. s_pack("i4", newRemainOffset)
                                  .. remainMIDIstringSub5)   
                                  
    --[[Archive: Since v5.32, MIDI_Sort will be fixed, so no need to use workarounds
                  such as calling the "Invert selection" action.
                                      
    -- Calls to native actions such as "Invert selection" via OnCommand must be placed
    --    within explicit undo blocks, otherwise they will create their own undo points.
    -- Strangely, in the current v5.30, undo blocks are interrupted as soon as the 
    --    atexit-defined function is called.  *This is probably a bug.*  
    -- Therefore must start a new undo block within this onexit function.  Fortunately, 
    --    this undo point seems to undo the entire defered script, not only the stuff that
    --    happens within this onexit function.
    reaper.Undo_BeginBlock2(0)    
    
    -- MIDI_Sort is buggy when dealing with overlapping notes, 
    --    causing infinitely extended notes or zero-length notes.
    -- Even explicitly calling "Correct overlapping notes" before sorting does not avoid all bugs.
    -- Calling "Invert selection" twice is a much more reliable way to sort MIDI.   
    if isInline then
        reaper.MIDI_Sort(take)
        reaper.UpdateArrange()
    else
        reaper.MIDIEditor_OnCommand(editor, 40501) -- Invert selection in active take
        reaper.MIDIEditor_OnCommand(editor, 40501) -- Invert back to original selection
    end
    ]]
    
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
    if (stretchLEFT or stretchRIGHT) then
        if laneIsCC7BIT then
            undoString = "Stretch positions of 7-bit CC events in lane ".. tostring(mouseOrigCCLane)
        elseif laneIsCHPRESS then
            undoString = "Stretch positions of channel pressure events"
        elseif laneIsCC14BIT then
            undoString = "Stretch positions of 14 bit-CC events in lanes ".. 
                                      tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
        elseif laneIsPITCH then
            undoString = "Stretch positions of pitchwheel events"
        elseif laneIsNOTES then
            undoString = "Stretch positions and lengths of notes"
        elseif laneIsTEXT then
            undoString = "Stretch positions of text events"
        elseif laneIsSYSEX then
            undoString = "Stretch positions of sysex events"
        elseif laneIsPROGRAM then
            undoString = "Stretch positions of program select events"
        elseif laneIsBANKPROG then
            undoString = "Stretch positions of bank/program select events"
        else
            undoString = "Stretch event positions"
        end 
    else -- stretchTOP or stretchBOTTOM
        if laneIsCC7BIT then
            undoString = "Stretch values of 7-bit CC events in lane ".. tostring(mouseOrigCCLane)
        elseif laneIsCHPRESS then
            undoString = "Stretch values of channel pressure events"
        elseif laneIsCC14BIT then
            undoString = "Stretch values of 14 bit-CC events in lanes "
                          .. tostring(mouseOrigCCLane-256) .. "/" .. tostring(mouseOrigCCLane-224)
        elseif laneIsPITCH then
            undoString = "Stretch values of pitchwheel events"
        elseif laneIsVELOCITY then
            undoString = "Stretch velocities of notes"
        elseif laneIsPROGRAM then
            undoString = "Stretch values of program select events"
        else
            undoString = "Stretch event values"
        end   
    end
    -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
    --    in the undo point to changes in this specific item.
    reaper.Undo_OnStateChange_Item(0, undoString, item)
    
end -- function onexit


--####################################################################################
--------------------------------------------------------------------------------------
function deleteOverlappingCCs()
    
    if laneIsNOTES then --not (laneIsPITCH or laneIsCC7BIT or laneIsCC14BIT or laneIsCHPRESS or laneIsPROGRAM or laneIsTEXT or laneIsSYSEX or laneIsALL) then
        return
    end
    
    -- Construct table with min and max PPQ positions for each event type.
    -- Deletion will be type-channel-, and lane-specific.
    -- Get final positions of edited events by parsing tableEditedMIDI.
    local tableMinMax = {}
    local runningPPQpos = 0 -- position while parsing edited events
    local eventIsOtherCC = {[0xC] = true, [0xD] = true, [0xE] = true}
    for i = 1, #tableEditedMIDI do
        runningPPQpos = runningPPQpos + s_unpack("i4", tableEditedMIDI[i], 1)
        local msg = tableEditedMIDI[i]:sub(10,11)
        local statusByte = msg:byte(1)
        local eventType = statusByte and statusByte>>4
        local eventID -- Will get value if event is type that ust be deleted if overlapped, such as CC or pitch.  NOT notes or text/sysex.
        if eventType == 0xB then -- Standard CC
            eventID = msg -- contains type, channel and CC lane
        elseif eventIsOtherCC[eventType] then -- Other CC types (pitch etc)
            eventID = msg:byte(1) -- contains type and channel 
        elseif statusByte == 0xFF then -- text events
            if msg:byte(2) ~= 0x0F then -- excluding REAPER's notation events
                eventID = msg
            end
        elseif eventType == 0xF then -- sysex (excluding 0xFF text events)
            eventID = msg:byte(1)
        end
        if eventID then
            if tableMinMax[eventID] then
                if runningPPQpos < tableMinMax[eventID].min then tableMinMax[eventID].min = runningPPQpos end
                if runningPPQpos > tableMinMax[eventID].max then tableMinMax[eventID].max = runningPPQpos end
            else
                tableMinMax[eventID] = {min = runningPPQpos, max = runningPPQpos}
            end
        end
    end
    
    local lastStretchedPPQpos = runningPPQpos -- Rest of unedited events must be offset relative to last PPQ position in edited events.
    
    -- Now search through the remainMIDIstring.
    local tableRemainingEvents = {}
    local r = 0
    local runningPPQpos = 0
    local lastRemainPPQpos = 0 -- Will be used to update offset of event directly after deleted event.
    local prevPos, nextPos, unchangedPos = 1, 1, 1
    local offset, flags, msg
    
    local MIDIlen = remainMIDIstring:len()
    while nextPos < MIDIlen do
    
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", remainMIDIstring, nextPos)
        runningPPQpos = runningPPQpos + offset
        
        local mustDelete = false
        
        local statusByte = msg:byte(1)
        local eventType = statusByte and statusByte>>4
        local eventID -- Will get value if event is type that ust be deleted if overlapped, such as CC or pitch.  NOT notes or text/sysex.
        if eventType == 0xB then -- Standard CC
            eventID = msg:sub(1,2) -- contains type, channel and CC lane
        elseif eventIsOtherCC[eventType] then -- Other CC types (pitch etc)
            eventID = msg:byte(1) -- contains type and channel 
        elseif eventType == 0xF and not (statusByte == 0xFF) then -- sysex
            eventID = msg:byte(1)
        elseif statusByte == 0xFF and not (msg:byte(2) == 0x0F) then -- text events, excluding notation
            eventID = msg:sub(1,2)
        end
        if eventID and tableMinMax[eventID] then -- does this event type occur in selected events?
            if (runningPPQpos >= tableMinMax[eventID].min and runningPPQpos <= tableMinMax[eventID].max) then 
                mustDelete = true
            end
        end
        
        -- Remove to-be-deleted events and update remaining events' offsets
        if mustDelete then
            -- The chain of unchanged events is broken, so write to tableRemainingEvents
            if unchangedPos < prevPos then
                r = r + 1
                tableRemainingEvents[r] = remainMIDIstring:sub(unchangedPos, prevPos-1)
            end
            unchangedPos = nextPos
            mustUpdateNextOffset = true
        elseif mustUpdateNextOffset then
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQpos-lastRemainPPQpos, flags, msg)
            lastRemainPPQpos = runningPPQpos
            unchangedPos = nextPos
            mustUpdateNextOffset = false
        else
            lastRemainPPQpos = runningPPQpos
        end

    end -- while    
    
    -- Now insert all the events to the right of the targets as one bulk
    if unchangedPos < MIDIlen then
        r = r + 1
        tableRemainingEvents[r] = remainMIDIstring:sub(unchangedPos)
    end
      
    -------------------------------------------------------------
    -- Update first remaining event's offset relative to new ramp
    newRemainOffset = s_unpack("i4", tableRemainingEvents[1]) - lastStretchedPPQpos
    remainMIDIstringSub5 = table.concat(tableRemainingEvents):sub(5)

    ------------------------
    -- Upload into the take!
    --reaper.MIDI_SetAllEvts(take, table.concat(tableEditedMIDI) .. s_pack("i4", newOffset) .. table.concat(tableRemainingEvents):sub(5))
end


--####################################################################################
--------------------------------------------------------------------------------------
function parseAndExtractTargetMIDI()  
    
    -- If unsorted MIDI is encountered, the function will try to correct it by calling 
    --    "Invert selection" twice, which should invoke the MIDI editor's built-in sorting
    --    algorithm.  This is more reliable than the buggy MIDI_Sort(take) API function.
    -- This will only be tried once, so use flag.
    local haveAlreadyCorrectedOverlaps = false
    
    -- Start again here if sorting was done.
    ::startAgain::

    -- REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
    --    MIDI_GetAllEvts and MIDI_SetAllEvts.
    gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    
    if gotAllOK then
    
        local MIDIlen = MIDIstring:len()
        
        -- These functions are fast, but require complicated parsing of the MIDI string.
        -- The following tables with temporarily store data while parsing:
        local tableNoteOns = {} -- Store note-on position and pitch while waiting for the next note-off, to calculate note length
        local tableTempNotation = {} -- Store notation text while waiting for a note-on with matching position, pitch and channel
        local tableCCMSB = {} -- While waiting for matching LSB of 14-bit CC
        local tableCCLSB = {} -- While waiting for matching MSB of 14-bit CC
        if laneIsNOTES or laneIsALL then
            for chan = 0, 15 do
                tableNoteOns[chan] = {}
                tableTempNotation[chan] = {}
                for pitch = 0, 127 do
                    tableNoteOns[chan][pitch] = {}
                    tableTempNotation[chan][pitch] = {} -- tableTempNotation[channel][pitch][PPQpos] = notation text message
                    for flags = 0, 3 do
                        tableNoteOns[chan][pitch][flags] = {} -- = {PPQpos, velocity} (note-off must match channel, pitch and flags)
                    end
                end
            end
        elseif laneIsCC14BIT then
            for chan = 0, 15 do
                tableCCMSB[chan] = {} -- tableCCMSB[channel][PPQpos] = MSBvalue
                tableCCLSB[chan] = {} -- tableCCLSB[channel][PPQpos] = LSBvalue
            end
        end
                
        -- The abstracted info of targeted MIDI events (that will be edited) will be will be stored in
        --    several new tables such as tablePPQs and tableValues.
        -- Clean up these tables in case starting again after sorting.
        tableMsg = {}
        tableMsgLSB = {}
        tableMsgNoteOffs = {}
        tableValues = {} -- CC values, 14bit CC combined values, note velocities
        tablePPQs = {}
        tableChannels = {}
        tableFlags = {}
        tableFlagsLSB = {} -- In the case of 14bit CCs, mute/select status of the MSB
        tablePitches = {} -- This table will only be filled if laneIsVELOCITY / laneIsPIANOROLL / laneIsOFFVEL / laneIsNOTES
        tableNoteLengths = {}
        tableNotation = {} -- Will only contain entries at those indices where the notes have notation
        
        -- The MIDI strings of non-targeted events will temnporarily be stored in a table, tableRemainingEvents[],
        --    and once all MIDI data have been parsed, this table (which excludes the strings of targeted events)
        --    will be concatenated into remainMIDIstring.
        local tableRemainingEvents = {}    
         
        local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, sp the actual PPQ positions must be calculated by iterating through all events and adding their offsets
        local lastRemainPPQpos = 0 -- PPQ position of last event that was *not* targeted, and therefore stored in tableRemainingEvents.
        local mustUpdateNextOffset
        local prevPos, nextPos, unchangedPos = 1, 1, 1 -- Keep record of position within MIDIstring. unchangedPos is position from which unchanged events van be copied in bulk.
        local c = 0 -- Count index inside tables - strangely, this is faster than using table.insert or even #table+1
        local r = 0 -- Count inside tableRemainingEvents
        local offset, flags, msg -- MIDI data that will be unpacked for each event
        
        --[[
        ---------------------------------------------------------------
        -- This loop will iterate through the MIDI data, event-by-event
        -- In the case of unselected events, only their offsets are relevant, in order to update runningPPQpos.
        -- Selected events will be checked in more detail, to find those in the target lane.
        --
        -- The exception is notation events: Notation 'text events' for selected noted are unfortunately not also selected. 
        --    So relevant notation text events can only be found by checking each and every notation event.
        -- If note positions are not changed, then do not need to extract notation, since MIDI_Sort will eventually put notes and notation together again.
        --
        -- Should this parser check for unsorted MIDI?  This would depend on the function of the script. 
        -- Scripts such as "Remove redundant CCs" will only work on sorted MIDI.  For others, sorting is not relevant.
        -- Note that even in sorted MIDI, the first event can have an negative offset if its position is to the left of the item start.
        -- As discussed in the introduction, MIDI sorting entails several problems.  This script will therefore avoid sorting until it exits, and
        --    will instead notify the user, in the rare case that unsorted MIDI is detected.  (Checking for negative offsets is also faster than unneccesary sorting.
            
        -- This function will try two main things to make execution faster:
        --    * First, an upper bound for positions of the targeted events in MIDIstring must be found. 
        --      If such an upper bound can be found, the parser does not need to parse beyond this point,
        --      and the remaining later part of MIDIstring can be stored as is.
        --    * Second, events that are not changed (i.e. not extracted or offset changed) will not be 
        --      inserted individually into tableRemainingEvents, using string.pack.  Instead, they will be 
        --      inserted as blocks of multiple events, copied directly from MIDIstring.  By so doing, the 
        --      number of table writes are lowered, the speed of table.concat is improved, and string.sub
        --      can be used instead of string.pack.
        
        -----------------------------------------------------------------------------------------------------
        -- To get an upper limit for the positions of targeted events in MIDIstring, string.find will be used
        --    to find the posision of the last targeted event in MIDIstring (NB, the *string* posision, not 
        --    the PPQ position.  string.find will search backwards from the end of MIDIstring, using Lua's 
        --    string patterns to ensure that all possible targeted events would be matched.  
        --    (It is possible, though unlikely, that a non-targeted events might also be matched, but this is 
        --    not a problem, since it would simply raise the upper limit.  Parsing would be a bit slower, 
        --    but since all targeted events would still be included in below the upper limit, parsing will 
        --    still be accurate.
        
        -- But what happens if one of the characters in the MIDI string is a "magic character"
        --    of Lua's string patterns?  The magic characters are: ^$()%.[]*+-?)
        -- The byte values for these characters are:
        -- % = 0x25
        -- . = 0x2e
        -- ^ = 0x5e
        -- ? = 0x3f
        -- [ = 0x5b 
        -- ] = 0x5d
        -- + = 0x2b
        -- - = 0x2d
        -- ) = 0x29
        -- ( = 0x28
        -- Fortunately, these byte values fall outside the range of (most of the) values in the match string:
        --    * MIDI status bytes > 0x80
        --    * Message lengths <= 3
        -- The only problem is msg2 (MIDI byte 2), which can range from 0 to 0xEF.
        -- These bytes must therefore be compared to the above list, and prefixed with a "%" where necessary. gsub will be used.
        -- (It is probably only strictly necessary to prefix % to "%" and ".", but won't hurt to prefix to all of the above.)
        ]]
        local matchStrReversed, firstTargetPosReversed = "", 0
        --[[if laneIsBANKPROG then
        
            local MIDIrev = MIDIstring:reverse()
            local matchProgStrRev = table.concat({"[",string.char(0xC0),"-",string.char(0xCF),"]",
                                                      string.pack("I4", 2):reverse(),
                                                  "[",string.char(0x01, 0x03),"]"})
            local msg2string = string.char(0, 32):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0")
            local matchBankStrRev = table.concat({"[",msg2string,"]",
                                                  "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                      string.pack("I4", 3):reverse(),
                                                  "[",string.char(0x01, 0x03),"]"})
            firstTargetPosReversedProg = MIDIrev:find(matchProgStrRev)
            firstTargetPosReversedBank = MIDIrev:find(matchBankStrRev)
            if firstTargetPosReversedProg and firstTargetPosReversedBank then 
                firstTargetPosReversed = math.min(MIDIlen-firstTargetPosReversedProg, MIDIlen-firstTargetPosReversedBank)
            elseif firstTargetPosReversedProg then firstTargetPosReversed = firstTargetPosReversedProg
            elseif firstTargetPosReversedBank then firstTargetPosReversed = firstTargetPosReversedBank
            end
                  
        else ]]
        if laneIsALL then
            lastTargetStrPos = MIDIlen-12
        else
            if laneIsCC7BIT then
                local msg2string = string.char(mouseOrigCCLane):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0") -- Replace magic characters.
                matchStrReversed = table.concat({"[",msg2string,"]",
                                                       "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                           string.pack("I4", 3):reverse(),
                                                       "[",string.char(0x01, 0x03),"]"})    
            elseif laneIsPITCH then
                matchStrReversed = table.concat({"[",string.char(0xE0),"-",string.char(0xEF),"]",
                                                           string.pack("I4", 3):reverse(),
                                                       "[",string.char(0x01, 0x03),"]"})
            elseif laneIsNOTES then
                matchStrReversed = table.concat({"[",string.char(0x80),"-",string.char(0x9F),"]", -- Note-offs and note-ons in all channels.
                                                           string.pack("I4", 3):reverse(),
                                                       "[",string.char(0x01, 0x03),"]"})
            elseif laneIsCHPRESS then
                matchStrReversed = table.concat({"[",string.char(0xD0),"-",string.char(0xDF),"]",
                                                           string.pack("I4", 2):reverse(),
                                                       "[",string.char(0x01, 0x03),"]"})                                      
            elseif laneIsCC14BIT then
                local MSBlane = mouseOrigCCLane - 256
                local LSBlane = mouseOrigCCLane - 224
                local msg2string = string.char(MSBlane, LSBlane):gsub("[%(%)%.%%%+%-%*%?%[%]%^]", "%%%0")
                matchStrReversed = table.concat({"[",msg2string,"]",
                                                       "[",string.char(0xB0),"-",string.char(0xBF),"]", 
                                                           string.pack("I4", 3):reverse(),
                                                       "[",string.char(0x01, 0x03),"]"})  
            elseif laneIsSYSEX then
                matchStrReversed = table.concat({string.char(0xF0), 
                                                       "....",
                                                       "[",string.char(0x01, 0x03),"]"})
            elseif laneIsTEXT then
                matchStrReversed = table.concat({"[",string.char(0x01),"-",string.char(0x09),"]",
                                                            string.char(0xFF), 
                                                            "....",
                                                       "[", string.char(0x01, 0x03),"]"})                                                 
            elseif laneIsPROGRAM then
                matchStrReversed = table.concat({"[",string.char(0xC0),"-",string.char(0xCF),"]",
                                                           string.pack("I4", 2):reverse(),
                                                       "[",string.char(0x01, 0x03),"]"})               
            end
        
            ----
            firstTargetPosReversed = MIDIstring:reverse():find(matchStrReversed) -- Search backwards by using reversed string. 
        
            if firstTargetPosReversed then 
                lastTargetStrPos = MIDIlen - firstTargetPosReversed 
            else -- Found no targeted events
                lastTargetStrPos = 0
            end    
        end
        
        ---------------------------------------------------------------------------------------------
        -- OK, got an upper limit.  Now iterate through MIDIstring, until the upper limit is reached.
        while nextPos < lastTargetStrPos do
           
            local mustExtract = false
            local offset, flags, msg
            
            prevPos = nextPos
            offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
          
            -- Check flag as simple test if parsing is still going OK
            if flags&252 ~= 0 then -- 252 = binary 11111100.
                reaper.ShowMessageBox("The MIDI data uses an unknown format that could not be parsed."
                                      .. "\n\nPlease report the problem in the thread http://forum.cockos.com/showthread.php?t=176878:"
                                      .. "\nFlags = " .. string.format("%02x", flags)
                                      , "ERROR", 0)
                return false
            end
            
            -- Check for unsorted MIDI
            if offset < 0 and prevPos > 1 then   
                -- The bugs in MIDI_Sort have been fixed in REAPER v5.32, so it should be save to use this function.
                if not haveAlreadyCorrectedOverlaps then
                    reaper.MIDI_Sort(take)
                    haveAlreadyCorrectedOverlaps = true
                    goto startAgain
                else -- haveAlreadyCorrectedOverlaps == true
                    reaper.ShowMessageBox("Unsorted MIDI data has been detected."
                                          .. "\n\nThe script has tried to sort the data, but was unsuccessful."
                                          .. "\n\nSorting of the MIDI can usually be induced by any simple editing action, such as selecting a note."
                                          , "ERROR", 0)
                    return false
                end
            end                        
            
            runningPPQpos = runningPPQpos + offset

            -- Only analyze *selected* events - as well as notation text events (which are always unselected)
            if flags&1 == 1 and #msg >= 2 then -- bit 1: selected
                --[[local eventType = (msg:byte(1))>>4
                local channel   = (msg:byte(1))&0xF
                local msg2      = msg:byte(2)
                local msg3      = msg:byte(3)
                    ]]
                
                -- When stretching ALL events, note events (note-ons, note-offs and notation) must be separated from CCs,
                --    since these may have to be reversed.
                -- Note that notes and CCs will use the same tablePPQs, tableMsg and tableFlags, but only notes will use tableNotesLengths, tableNotations etc.
                -- The note tables will therefore only contain entries at certain keys, not every key from 1 to #tablePPQs
                if laneIsALL 
                then
                      -- Note-offs
                      if ((msg:byte(1))>>4 == 8 or (msg:byte(3) == 0 and (msg:byte(1))>>4 == 9))
                      then
                          local channel = msg:byte(1)&0x0F
                          local msg2 = msg:byte(2)
                          -- Check whether there was a note-on on this channel and pitch.
                          if not tableNoteOns[channel][msg2][flags].index then
                              reaper.ShowMessageBox("There appears to be orphan note-offs (probably caused by overlapping notes or unsorted MIDI data) in the active takes."
                                                    .. "\n\nIn particular, at position " 
                                                    .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, runningPPQpos), "", 1)
                                                    .. "\n\nPlease remove these before retrying the script."
                                                    .. "\n\n"
                                                    , "ERROR", 0)
                              return false
                          else
                              mustExtract = true
                              tableNoteLengths[tableNoteOns[channel][msg2][flags].index] = runningPPQpos - tableNoteOns[channel][msg2][flags].PPQ
                              tableMsgNoteOffs[tableNoteOns[channel][msg2][flags].index] = msg
                              tableNoteOns[channel][msg2][flags] = {} -- Reset this channel and pitch
                          end
                                                                      
                      -- Note-Ons
                      elseif (msg:byte(1))>>4 == 9 -- and msg3 > 0
                      then
                          local channel = msg:byte(1)&0x0F
                          local msg2 = msg:byte(2)
                          if tableNoteOns[channel][msg2][flags].index then
                              reaper.ShowMessageBox("There appears to be overlapping notes among the selected notes."
                                                    .. "\n\nIn particular, at position " 
                                                    .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, runningPPQpos), "", 1)
                                                    .. "\n\nThe action 'Correct overlapping notes' can be used to correct overlapping notes in the active take."
                                                    , "ERROR", 0)
                              return false
                          else
                              mustExtract = true
                              c = c + 1
                              tableMsg[c] = msg
                              tablePPQs[c] = runningPPQpos
                              tableFlags[c] = flags
                              -- Check whether any notation text events have been stored for this unique PPQ, channel and pitch
                              tableNotation[c] = tableTempNotation[channel][msg2][runningPPQpos]
                              -- Store the index and PPQ position of this note-on with a unique key, so that later note-offs can find their matching note-on
                              tableNoteOns[channel][msg2][flags] = {PPQ = runningPPQpos, index = c}
                          end  
                          
                      -- Other CCs  
                      else
                          mustExtract = true
                          c = c + 1
                          tableMsg[c] = msg
                          tablePPQs[c] = runningPPQpos
                          tableFlags[c] = flags
                      end
                      
                      
                
                elseif laneIsCC7BIT then if msg:byte(2) == mouseOrigCCLane and (msg:byte(1))>>4 == 11
                then
                    mustExtract = true
                    c = c + 1 
                    tableValues[c] = msg:byte(3)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags
                    tableMsg[c] = msg
                    end 
                                    
                elseif laneIsPITCH then if (msg:byte(1))>>4 == 14
                then
                    mustExtract = true 
                    c = c + 1
                    tableValues[c] = (msg:byte(3)<<7) + msg:byte(2)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags 
                    tableMsg[c] = msg        
                    end                           
                                        
                elseif laneIsCC14BIT then 
                    if msg:byte(2) == mouseOrigCCLane-224 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the LSB lane
                    then
                        mustExtract = true
                        local channel = msg:byte(1)&0x0F
                        -- Has a corresponding LSB value already been saved?  If so, combine and save in tableValues.
                        if tableCCMSB[channel][runningPPQpos] then
                            c = c + 1
                            tableValues[c] = (((tableCCMSB[channel][runningPPQpos].message):byte(3))<<7) + msg:byte(3)
                            tablePPQs[c] = runningPPQpos
                            tableFlags[c] = tableCCMSB[channel][runningPPQpos].flags -- The MSB determines muting
                            tableFlagsLSB[c] = flags
                            tableChannels[c] = channel
                            tableMsg[c] = tableCCMSB[channel][runningPPQpos].message
                            tableMsgLSB[c] = msg
                            tableCCMSB[channel][runningPPQpos] = nil -- delete record
                        else
                            tableCCLSB[channel][runningPPQpos] = {message = msg, flags = flags}
                        end
                            
                    elseif msg:byte(2) == mouseOrigCCLane-256 and (msg:byte(1))>>4 == 11 -- 14bit CC, only the MSB lane
                    then
                        mustExtract = true
                        local channel = msg:byte(1)&0x0F
                        -- Has a corresponding LSB value already been saved?  If so, combine and save in tableValues.
                        if tableCCLSB[channel][runningPPQpos] then
                            c = c + 1
                            tableValues[c] = (msg:byte(3)<<7) + (tableCCLSB[channel][runningPPQpos].message):byte(3)
                            tablePPQs[c] = runningPPQpos
                            tableFlags[c] = flags
                            tableChannels[c] = channel
                            tableFlagsLSB[c] = tableCCLSB[channel][runningPPQpos].flags
                            tableMsg[c] = msg
                            tableMsgLSB[c] = tableCCLSB[channel][runningPPQpos].message
                            tableCCLSB[channel][runningPPQpos] = nil -- delete record
                        else
                            tableCCMSB[channel][runningPPQpos] = {message = msg, flags = flags}
                        end
                    end
                  
                -- Note-Offs
                elseif laneIsNOTES then 
                    if ((msg:byte(1))>>4 == 8 or (msg:byte(3) == 0 and (msg:byte(1))>>4 == 9))
                    then
                        local channel = msg:byte(1)&0x0F
                        local msg2 = msg:byte(2)
                        -- Check whether there was a note-on on this channel and pitch.
                        if not tableNoteOns[channel][msg2][flags].index then
                            reaper.ShowMessageBox("There appears to be orphan note-offs (probably caused by overlapping notes or unsorted MIDI data) in the active takes."
                                                  .. "\n\nIn particular, at position " 
                                                  .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, runningPPQpos), "", 1)
                                                  .. "\n\nPlease remove these before retrying the script."
                                                  .. "\n\n"
                                                  , "ERROR", 0)
                            return false
                        else
                            mustExtract = true
                            tableNoteLengths[tableNoteOns[channel][msg2][flags].index] = runningPPQpos - tableNoteOns[channel][msg2][flags].PPQ
                            tableMsgNoteOffs[tableNoteOns[channel][msg2][flags].index] = msg
                            tableNoteOns[channel][msg2][flags] = {} -- Reset this channel and pitch
                        end
                                                                    
                    -- Note-Ons
                    elseif (msg:byte(1))>>4 == 9 -- and msg3 > 0
                    then
                        local channel = msg:byte(1)&0x0F
                        local msg2 = msg:byte(2)
                        if tableNoteOns[channel][msg2][flags].index then
                            reaper.ShowMessageBox("There appears to be overlapping notes among the selected notes."
                                                  .. "\n\nIn particular, at position " 
                                                  .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(take, runningPPQpos), "", 1)
                                                  .. "\n\nThe action 'Correct overlapping notes' can be used to correct overlapping notes in the active take."
                                                  , "ERROR", 0)
                            return false
                        else
                            mustExtract = true
                            c = c + 1
                            tableMsg[c] = msg
                            tableValues[c] = msg:byte(3)
                            tablePPQs[c] = runningPPQpos
                            tablePitches[c] = msg2
                            tableChannels[c] = channel
                            tableFlags[c] = flags
                            -- Check whether any notation text events have been stored for this unique PPQ, channel and pitch
                            tableNotation[c] = tableTempNotation[channel][msg2][runningPPQpos]
                            -- Store the index and PPQ position of this note-on with a unique key, so that later note-offs can find their matching note-on
                            tableNoteOns[channel][msg2][flags] = {PPQ = runningPPQpos, index = c}
                        end  
                    end
  
                    
                elseif laneIsPROGRAM then if (msg:byte(1))>>4 == 12
                then
                    mustExtract = true
                    c = c + 1
                    tableValues[c] = msg:byte(2)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags
                    tableMsg[c] = msg
                    end
                    
                elseif laneIsCHPRESS then if (msg:byte(1))>>4 == 13
                then
                    mustExtract = true
                    c = c + 1
                    tableValues[c] = msg:byte(2)
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags
                    tableMsg[c] = msg
                    end
                    
                elseif laneIsBANKPROG then if ((msg:byte(1))>>4 == 12 or ((msg:byte(1))>>4 == 11 and (msg:byte(2) == 0 or msg:byte(2) == 32)))
                then
                    mustExtract = true
                    c = c + 1
                    tablePPQs[c] = runningPPQpos
                    tableChannels[c] = msg:byte(1)&0x0F
                    tableFlags[c] = flags
                    tableMsg[c] = msg
                    end
                             
                elseif laneIsTEXT then if msg:byte(1) == 0xFF and not (msg:byte(2) == 0x0F) -- text event (0xFF), excluding notation type (0x0F)
                then
                    mustExtract = true
                    c = c + 1
                    tablePPQs[c] = runningPPQpos
                    tableFlags[c] = flags
                    tableMsg[c] = msg
                    end
                                        
                elseif laneIsSYSEX then if (msg:byte(1))>>4 == 0xF and not (msg:byte(1) == 0xFF) then -- Selected sysex event (text events with 0xFF as first byte have already been excluded)
                    mustExtract = true
                    c = c + 1
                    tablePPQs[c] = runningPPQpos
                    tableFlags[c] = flags
                    tableMsg[c] = msg
                    end
                end  
                
            end -- if laneIsCC7BIT / CC14BIT / PITCH etc
                
            -- Check notation text events
            if (laneIsNOTES or laneIsALL)
            and msg:byte(1) == 0xFF -- MIDI text event
            and msg:byte(2) == 0x0F -- REAPER's MIDI text event type
            then
                -- REAPER v5.32 changed the order of note-ons and notation events. So must search backwards as well as forward.
                local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ") 
                if notationChannel then
                    notationChannel = tonumber(notationChannel)
                    notationPitch   = tonumber(notationPitch)
                    -- First, backwards through notes that have already been parsed.
                    for i = #tablePPQs, 1, -1 do
                        if tablePPQs[i] ~= runningPPQpos then 
                            break -- Go on to forward search
                        else
                            if tableMsg[i]:byte(1) == 0x90 | notationChannel
                            and tableMsg[i]:byte(2) == notationPitch
                            then
                                tableNotation[i] = msg
                                mustExtract = true
                                goto completedNotationSearch
                            end
                        end
                    end
                    -- Search forward through following events, looking for a selected note that match the channel and pitch
                    local evPos = nextPos -- Start search at position of nmext event in MIDI string
                    local evOffset, evFlags, evMsg
                    repeat -- repeat until an offset is found > 0
                        evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                        if evOffset == 0 then 
                            if evFlags&1 == 1 -- Only match *selected* events
                            and evMsg:byte(1) == 0x90 | notationChannel -- Match note-ons and channel
                            and evMsg:byte(2) == notationPitch -- Match pitch
                            and evMsg:byte(3) ~= 0 -- Note-ons with velocity == 0 are actually note-offs
                            then
                                -- Store this notation text with unique key so that future selected notes can find their matching notation
                                tableTempNotation[notationChannel][notationPitch][runningPPQpos] = msg
                                mustExtract = true
                                goto completedNotationSearch
                            end
                        end
                    until evOffset ~= 0
                    ::completedNotationSearch::
                end   
            end
            
                            
            --------------------------------------------------------------------------
            -- So what must be done with the MIDI event?  Stored as non-targeted event 
            --    in tableRemainingEvents?  Or update offset?
            if mustExtract then
                -- The chain of unchanged events is broken, so write to tableRemainingEvents
                if unchangedPos < prevPos then
                    r = r + 1
                    tableRemainingEvents[r] = MIDIstring:sub(unchangedPos, prevPos-1)
                end
                unchangedPos = nextPos
                mustUpdateNextOffset = true
            elseif mustUpdateNextOffset then
                r = r + 1
                tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQpos-lastRemainPPQpos, flags, msg)
                lastRemainPPQpos = runningPPQpos
                unchangedPos = nextPos
                mustUpdateNextOffset = false
            else
                lastRemainPPQpos = runningPPQpos
            end
    
        end -- while    
        
        
        -- Now insert all the events to the right of the targets as one bulk
        if mustUpdateNextOffset then
            offset = s_unpack("i4", MIDIstring, nextPos)
            runningPPQpos = runningPPQpos + offset
            r = r + 1
            tableRemainingEvents[r] = s_pack("i4", runningPPQpos - lastRemainPPQpos) .. MIDIstring:sub(nextPos+4) 
        else
            r = r + 1
            tableRemainingEvents[r] = MIDIstring:sub(unchangedPos) 
        end
        
        ----------------------------------------------------------------------------
        -- The entire MIDI string has been parsed.  Now check that everything is OK. 
        --[[ Last entry is perhaps empty?
        local lastEvent = tableRemainingEvents[#tableRemainingEvents]:sub(-12)
        if tableRemainingEvents[#tableRemainingEvents]:byte(-2) ~= 0x7B
        or (tableRemainingEvents[#tableRemainingEvents]:byte(-3))&0xF0 ~= 0xB0
        then
            reaper.ShowMessageBox("No All-Notes-Off MIDI message was found at the end of the take."
                                  .. "\n\nThis may indicate a parsing error in script, or an error in the take."
                                  , "ERROR", 0)
            return false
        end ]]          
        
        if #tablePPQs == 0 then -- Nothing to extract, so don't need to concatenate tableRemainingEvents
            remainOffset = s_unpack("i4", MIDIstring, 1)
            remainMIDIstring = MIDIstring
            remainMIDIstringSub5 = MIDIstring:sub(5)
            return true 
        end         

        -- Now check that the number of LSB and MSB events were nicely balanced. If they are, these tables should be empty
        if laneIsCC14BIT then
            for chan = 0, 15 do
                for key, value in pairs(tableCCLSB[chan]) do
                    reaper.ShowMessageBox("There appears to be selected CCs in the LSB lane that do not have corresponding CCs in the MSB lane."
                                          .. "\n\nThe script does not know whether these CCs should be included in the edits, so please deselect these before retrying the script.", "ERROR", 0)
                    return false
                end
                for key, value in pairs(tableCCMSB[chan]) do
                    reaper.ShowMessageBox("There appears to be selected CCs in the MSB lane that do not have corresponding CCs in the LSB lane."
                                          .. "\n\nThe script does not know whether these CCs should be included in the edits, so please deselect these before retrying the script.", "ERROR", 0)
                    return false
                end
            end
        end    
            
        -- Check that every note-on had a corresponding note-off
        if (laneIsNOTES) and #tableNoteLengths ~= #tableValues then
            reaper.ShowMessageBox("There appears to be an imbalanced number of note-ons and note-offs.", "ERROR", 0)
            return false 
        end
        
        -- Calculate original PPQ ranges and extremes
        -- * THIS ASSUMES THAT THE MIDI DATA IS SORTED *
        if includeNoteOffsInPPQrange and (laneIsNOTES or laneIsALL) then
            origPPQleftmost  = tablePPQs[1]
            origPPQrightmost = tablePPQs[#tablePPQs] -- temporary
            local noteEndPPQ
            for i = 1, #tablePPQs do
                if tableNoteLengths[i] then -- laneIsALL event is a note
                    noteEndPPQ = tablePPQs[i] + tableNoteLengths[i]
                    if noteEndPPQ > origPPQrightmost then origPPQrightmost = noteEndPPQ end
                end
            end
            origPPQrange = origPPQrightmost - origPPQleftmost
        else
            origPPQleftmost  = tablePPQs[1]
            origPPQrightmost = tablePPQs[#tablePPQs]
            origPPQrange     = origPPQrightmost - origPPQleftmost
        end
        
        -- Calculate original event value ranges and extremes
        if laneIsTEXT or laneIsSYSEX or laneIsBANKPROG or laneIsALL then
            origValueRange = -1
        else
            origValueMin = math.huge
            origValueMax = -math.huge
            for i = 1, #tableValues do
                if tableValues[i] < origValueMin then origValueMin = tableValues[i] end
                if tableValues[i] > origValueMax then origValueMax = tableValues[i] end
            end
            origValueRange     = origValueMax - origValueMin
            origValueLeftmost  = tableValues[1]
            origValueRightmost = tableValues[#tableValues]
        end
                    
        
        ------------------------
        -- Fiinally, return true
        -- When concatenating tableRemainingEvents, leave out the first remaining event's offset (first 4 bytes), 
        --    since this offset will be updated relative to the edited events' positions during each cycle.
        -- (The edited events will be inserted in the string before all the remaining events.)
        remainMIDIstring = table.concat(tableRemainingEvents)
        remainMIDIstringSub5 = remainMIDIstring:sub(5)
        remainOffset = s_unpack("i4", remainMIDIstring, 1)
        return true
        
    else -- if not gotAllOK
        reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data.", "ERROR", 0)
        return false 
    end

end


--#############################################################################################
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
                        t_insert(tablePrevIDs, prevID)
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

function main()    

    -- Start with a trick to avoid automatically creating undo states if nothing actually happened
    -- Undo_OnStateChange will only be used if reaper.atexit(onexit) has been executed
    reaper.defer(function() end)    
    
    ----------------------------------------------------------------------------
    -- Check whether SWS is available, as well as the required version of REAPER
    if not reaper.APIExists("MIDI_GetAllEvts") then
        reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                              .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                              , "ERROR", 0)
        return(false) 
    elseif not reaper.APIExists("SN_FocusMIDIEditor") then
        reaper.ShowMessageBox("This script requires an up-to-date version of the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        return(false) 
    end   
    
    -------------------------------------------
    -- Display notifications about new features
    local lastTipVersion = tonumber(reaper.GetExtState("js_Stretch", "Last tip version")) or 0
    if lastTipVersion < 3.30 then
        reaper.MB("The Stretch script can now stretch all selected events in all lanes together."
                  .. "\n\nTo stretch all lanes together, position the mouse over a lane divider when starting the script."
                  .. "\n\nTo stretch only a single lane separately, position the mouse inside the CC lane (or notes area)."
                  .. "\n\nWhen stretching all lanes together, stretching can only be horizontal (i.e. event positions), not vertically (event values)."
                  .. "\n\n(This message will only be displayed once).", 
                  "New feature notification: v3.30", 0)
        reaper.SetExtState("js_Stretch", "Last tip version", "3.30", true)
        displayedNotification = true
    end
    if lastTipVersion < 3.40 then
        reaper.MB("Moving the mousewheel flips the events being stretched."
                  .. "\n\n(This message will only be displayed once).", 
                  "New feature notification: v3.40", 0)
        reaper.SetExtState("js_Stretch", "Last tip version", "3.40", true)
        displayedNotification = true
    end
    if displayedNotification then return(false) end -- If inline editor, will in any case lose focus when clicking in message box window.
    
    -----------------------------------------------------------
    -- The following sections checks the position of the mouse:
    -- If the script is called from a toolbar, it arms the script as the default js_Run function, but does not run the script further
    -- If the mouse is positioned over a CC lane, the script is run.
    window, segment, details = reaper.BR_GetMouseCursorContext()
    -- If window == "unknown", assume to be called from floating toolbar
    -- If window == "midi_editor" and segment == "unknown", assume to be called from MIDI editor toolbar
    if window == "unknown" or (window == "midi_editor" and segment == "unknown") then
        setAsNewArmedToolbarAction()
        return(false) 
    elseif not(segment == "notes" or segment == "ruler" or details == "cc_lane") then 
        reaper.ShowMessageBox("Mouse is not correctly positioned.\n\n"
                              .. "This script edits the MIDI events in the part of the MIDI editor that is under the mouse, "
                              .. "so the mouse should be positioned over either a CC lane or the notes area of an active MIDI editor.", "ERROR", 0)
        return(false) 
    else
        -- Communicate with the js_Run.. script that a script is running
        reaper.SetExtState("js_Mouse actions", "Status", "Running", false)
    end
    
    -----------------------------------------------------------------------------------------
    -- We know that the mouse is positioned over a MIDI editor.  Check whether inline or not.
    -- Also get the mouse starting (vertical) value and CC lane.
    -- mouseOrigPitch: note row or piano key under mouse cursor (0-127)
    -- mouseOrigCCLane: CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
    --    0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
    --    0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)
    --
    -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI"
    -- No retval is returned: https://github.com/Jeff0S/sws/issues/783
    -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
    editor, isInline, mouseOrigPitch, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()

    if isInline then
        take = reaper.BR_GetMouseCursorContext_Take()
    else
        if editor == nil then 
            reaper.ShowMessageBox("Could not detect a MIDI editor under the mouse.", "ERROR", 0)
            return(false)
        else
            take = reaper.MIDIEditor_GetTake(editor)
        end
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
    
    -------------------------------------------------------------
    -- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
    --     require somewhat different tweaks, these must often be 
    --     distinguished.   
    if details == "cc_lane" and mouseOrigCCValue == -1 then
        laneIsALL = true
    elseif segment == "notes" then
        laneIsPIANOROLL, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 0
    elseif 0 <= mouseOrigCCLane and mouseOrigCCLane <= 127 then -- CC, 7 bit (single lane)
        laneIsCC7BIT = true
        laneMax = 127
        laneMin = 0
    elseif mouseOrigCCLane == 0x200 then
        laneIsVELOCITY, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 1    
    elseif mouseOrigCCLane == 0x201 then
        laneIsPITCH = true
        laneMax = 16383
        laneMin = 0
    elseif mouseOrigCCLane == 0x202 then
        laneIsPROGRAM = true
        laneMax = 127
        laneMin = 0
    elseif mouseOrigCCLane == 0x203 then
        laneIsCHPRESS = true
        laneMax = 127
        laneMin = 0
    elseif mouseOrigCCLane == 0x204 then
        laneIsBANKPROG = true
        laneMax = 127
        laneMin = 0
    elseif 256 <= mouseOrigCCLane and mouseOrigCCLane <= 287 then -- CC, 14 bit (double lane)
        laneIsCC14BIT = true
        laneMax = 16383
        laneMin = 0
    elseif mouseOrigCCLane == 0x205 then
        laneIsTEXT = true
    elseif mouseOrigCCLane == 0x206 then
        laneIsSYSEX = true
    elseif mouseOrigCCLane == 0x207 then
        laneIsOFFVEL, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 0
    else -- not a lane type in which script can be used.
        reaper.ShowMessageBox(--[['When starting a "lane under mouse" script, the mouse must be positioned over one of these lanes:'
                              .. "\n* 7-bit CC, \n* 14-bit CC, \n* Velocity, \n* Channel Pressure, \n* Pitch, \n* Program select,\n* Bank/Program,\n* Text or Sysex,"
                              .. "\nor in the 'notes area' of the piano roll."]]
                              "Mouse is not correctly positioned."
                              .. "\n\nThis script edits the MIDI events in the part of the MIDI editor that is under the mouse, "
                              .. "so the mouse should be positioned over either \n* a CC lane, or \n* the notes area \nof an active MIDI editor."
                              .. "\n\nTo stretch all selected events in all lanes together, position the mouse over a lane divider."
                              , "ERROR", 0)
        return(false)
    end
    
    --[[ Not relevant to this script
    -------------------------------------------------------------------
    -- Events will be inserted in the active channel of the active take
    if isInline then
        defaultChannel = 0
    else
        defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
    end
    
    
    -----------------------------------------------------------------------
    -- CCs will be inserted at the density set in Preferences -> 
    --    MIDI editor -> "Events per quarter note when drawing in CC lanes"
    CCdensity = reaper.SNM_GetIntConfigVar("midiCCdensity", 32)
    CCdensity = math.floor(math.max(4, math.min(128, math.abs(CCdensity)))) -- If user selected "Zoom dependent", density<0
    local startQN = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
    PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, startQN+1)
    PPperCC = PPQ/CCdensity -- Not necessarily an integer!
    ]]
    
    ---------------------------------------------------------------------------------------
    -- Time to process the MIDI of the take!
    -- As mentioned above, this script does not use the standard MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands 
    --    of events.
    if not parseAndExtractTargetMIDI() then
        --reaper.Undo_OnStateChange_Item(0, "FAILED: Stretch selected events in lane under mouse", item)
        return(false)
    end
    
    if #tablePPQs == 0 or (#tablePPQs == 1 and not tableNoteLengths[1]) then -- Single notes can be stretched, but not single CCs
        reaper.ShowMessageBox("Could not find a sufficient number of selected events in the target lane.", "ERROR", 0)
        return(false)
    end
    
    
    -----------------------------------------------------------------------
    -- The crucial BR_GetMouseCursorContext function gets slower and slower 
    --    as the number of events in the take increases.
    -- Therefore, this script will speed up the function by 'clearing' the 
    --    take of all MIDI *before* calling the function!
    -- To do so, MIDI_SetAllEvts will be run with no events except the
    --    All-Notes-Off message that should always terminate the MIDI stream, 
    --    and which marks the position of the end of the MIDI source.
    -- Instead of parsing the entire MIDI stream to get the final PPQ position,
    --    simply get the source length.
    -- (Since the MIDI may get sorted in the parseAndExtractTargetMIDI function,
    --    getting the source length has been postponed till now.)
    -- In addition, the source length will be saved and checked again at the end of
    --    the script, to check that no inadvertent shifts in PPQ position happened.
    sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)
    AllNotesOffString = string.pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
    
    
    -----------------------------------------------------------------------------------------------
    -- Get the starting PPQ (horizontal) position of the ramp.  Must check whether snap is enabled.
    -- Also, contract to position within item, and then divide by source length to get position
    --    within first loop iteration.
    mouseOrigPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5)
    local itemLengthTicks = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH"))+0.5)
    mouseOrigPPQpos = math.max(0, math.min(itemLengthTicks-1, mouseOrigPPQpos)) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    loopStartPPQpos = (mouseOrigPPQpos // sourceLengthTicks) * sourceLengthTicks
    mouseOrigPPQpos = mouseOrigPPQpos - loopStartPPQpos
    
    if isInline then
        isSnapEnabled = false
    else
        isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1)
    end
    if isInline then
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, mouseOrigPPQpos)
        local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
        gridOrigPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos) + 0.5)
    elseif isSnapEnabled then
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
    
    
    --------------------------------------------------------
    -- Determine in which direction events will be stretched
    edgeSize = math.max(0, math.min(0.5, edgeSize))
    -- these can only be stretch horizontally    
    if origPPQrange > 0 and (origValueRange == 0 or (laneIsALL or laneIsSYSEX or laneIsTEXT or laneIsPIANOROLL or laneIsOFFVEL or laneIsBANKPROG)) then
        if mouseOrigPPQpos > origPPQleftmost + 0.5*origPPQrange then stretchRIGHT = true
        else stretchLEFT = true
        end
    -- only stretch vertically (origPPQrange == 0 may happen if several notes in a chord are selected)
    elseif not (laneIsSYSEX or laneIsTEXT or laneIsPIANOROLL or laneIsOFFVEL or laneIsBANKPROG) and origValueRange > 0 and origPPQrange == 0 then  
        if mouseOrigCCValue > origValueMin + 0.5*origValueRange then stretchTOP = true
        else stretchBOTTOM = true
        end
    elseif origValueRange > 0 and origPPQrange > 0 then
        if mouseOrigPPQpos > origPPQrightmost - edgeSize*origPPQrange then stretchRIGHT = true
        elseif mouseOrigPPQpos < origPPQleftmost + edgeSize*origPPQrange then stretchLEFT = true
        elseif mouseOrigCCValue > origValueMin + 0.5*origValueRange then stretchTOP = true
        else stretchBOTTOM = true
        end
    else
        reaper.ShowMessageBox("Could not find a sufficient number of selected events with different values and/or PPQ positions in the target lane.", "ERROR", 0)
        return(false)
    end
    
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
    
    ---------------------------------------------------------------------------
    -- OK, tests passed, and it seems like this script will do something, 
    --    so toggle button (if any) and define atexit with its Undo statements,
    --    before making any changes to the MIDI.
    reaper.atexit(onexit)
    
    _, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
        reaper.SetToggleCommandState(sectionID, cmdID, 1)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    -------------------------------------------------------------------------------------------
    -- The functions MIDI_SetAllEvts and BR_GetMouseCursorContext (both of which will be called
    --    in each iteration of this script) get considerably slowed down by extra data in non-active takes.
    -- (Presumably, both have to deal with the full MIDI chunk.)
    -- To speed these function up, the non-active takes will therefore temporarily be cleared of all MIDI data.
    -- The MIDI data will be returned when the script exists.
    if not (reaper.GetExtState("js_Mouse actions", "Clear non-active takes") == "false") then
        for t = 0, reaper.CountTakes(item)-1 do
            local otherTake = reaper.GetTake(item, t)
            if otherTake ~= take then --and reaper.TakeIsMIDI(otherTake) then
                -- In rare circumstances, source length may differ between takes, if user changed loop points of individual takes.
                local otherSourceLen = reaper.BR_GetMidiSourceLenPPQ(otherTake)
                if otherSourceLen > 0 then -- If not a MIDI take, will return -1
                    local gotMIDIOK, otherTakeMIDI = reaper.MIDI_GetAllEvts(otherTake, "")
                    if gotMIDIOK then
                        tOtherTakes[otherTake] = otherTakeMIDI
                        otherSourceLen = math.floor(otherSourceLen)
                        reaper.MIDI_SetAllEvts(otherTake, string.pack("i4Bi4BBB", otherSourceLen, 0, 3, 0xB0, 0x7B, 0x00))
                    end
                end
            end
        end
    end
    
    -------------------------------------------------------------
    -- Finally, start running the loop!
    -- (But first, reset the mousewheel movement.)
    is_new,name,sec,cmd,rel,res,val = reaper.get_action_context()
    
    loop_pcall()

end -- main


--------------------------------------------------
--------------------------------------------------
mainOK = main()
if mainOK == false then
    if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
    reaper.DeleteExtState("js_Mouse actions", "Status", true)    
end

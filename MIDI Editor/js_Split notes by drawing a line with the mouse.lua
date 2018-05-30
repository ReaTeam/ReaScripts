--[[
ReaScript Name:  js_Split notes by drawing a line with the mouse.lua
Version: 2.12
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: http://stash.reaper.fm/27951/Split%20notes%20by%20drawing%20line%20with%20mouse.gif
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION  
  
  Split (slice) multiple notes by drawing a "cutting line" with the mouse in the MIDI editor or inline piano roll.
  
  Notes that intersect the cutting line will be split at the position of intersection.               
  
  If snap-to-grid is enabled, the notes will be split at the grid.


  # INSTRUCTIONS 
  
  To use, position mouse in the 'notes' area of the piano roll, press the shortcut key once, and then move the mouse to draw the cutting line.  

  There are two ways in which this script can be run:  
     
  1) First, the script can be linked to its own shortcut key.
     
  2) Second, this script, together with other "js_" scripts that edit the "lane under mouse",
           can each be linked to a toolbar button.  

     - In this case, each script need not be linked to its own shortcut key.  Instead, only the 
           accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
           script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).

     - Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
           and this selected (armed) script can then be run by using the shortcut for the 
           aforementioned "js_Run..." script.

     - For further instructions - please refer to the "js_Run..." script. 

   In the script's USER AREA (near the beginning of the script), the user can customize:
   * The thickness of the cutting line
   * Whether all notes or only selected notes should be split.

   Note: Since this function is a user script, the way it responds to shortcut keys and 
       mouse buttons is opposite to that of REAPER's built-in mouse actions 
       with mouse modifiers:  To run the script, press the shortcut key *once* 
       to start the script and then move the mouse *without* pressing any 
       mouse buttons.  Press the shortcut key again once to stop the script.  
  
   (The first time that the script is stopped, REAPER will pop up a dialog box 
       asking whether to terminate or restart the script.  Select "Terminate"
       and "Remember my answer for this script".)
]]
 
--[[
  Changelog:
  * v0.9 (2016-06-24)
    + Initial beta release. (Bugs may be encountered.)
  * v0.91 (2016-06-25)
    + A few tweaks.
  * v0.92 (2016-06-26)
    + Beta 3: Fixed "Could not find gap" bug.
  * v0.93 (2016-06-27)
    + Implemented workaround for bug in MIDI_SetNote().
    + WARNING: The script is still in beta, and may be unstable.
  * v1.0 (2016-07-04)
    + All the "lane under mouse" js_ scripts can now be linked to toolbar buttons and run using a single shortcut.
    + Description and instructions are included inside script - please read with REAPER's built-in script editor.
  * v2.00 (2016-12-15)
    + Improved speed, particularly in takes with many thousands of MIDI events.
    + Script will work in inline editor.
    + Script will work in looped takes.
    + REAPER v5.32 or later is required.
  * v2.01 (2017-01-30)
    + Improved handling of overlapping notes.
  * v2.02 (2017-01-30)
    + Improved reset of toolbar button.
  * v2.10 (2017-07-23)
    + Mouse cursor changes to indicate that script is running.    
  * v2.11 (2018-04-15)
    + Automatically install script in MIDI Inline Editor section.
  * v2.12 (2018-05-29)
    + Return focus to MIDI editor after arming button in floating toolbar.
]]

-- USER AREA
-- Settings that the user can customize

-- Thickness of the cutting line, in pixels, that the script will try to achieve.
-- Hi-res screens may require thinker lines.
-- Since REAPER's current API does not provide a function to get the exact zoom level, the line thickness will only be approximate.
thicknessPixels = 5

-- Should the script only slice selected notes, or should it slice any note
--    that intersects with the cutting line?
onlySliceSelectedNotes = false -- true or false

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
--    new events will be concatenated to the *end* of the original MIDI data, and loaded into REAPER 
--    as the new MIDI data.
-- By concatenating at the end, the script will ensure that the line's events are drawn in front of the take's original MIDI events.
-- The new events must therefore be inserted between the original MIDI data and the All-Notes-Off 
--    message that terminates all of REAPER's MIDI takes and that determines the source length.
local MIDIstring
local MIDIstringWithoutNotesOff -- MIDIstring without the final All-Notes-Off message
local lastOrigMIDIPPQpos -- PPQ position of the last MIDI event before the All-Notes-Off message

-- As the MIDI events of the ramp are calculated, each event wil be assmebled into a short string and stored in the tableLine table.   
local tableLine = {}

-- The PPQ position at which cuts should be made, using [pitch] as key
local tableCutPPQpos = {} -- tableCutPPQs[pitch]

-- Starting values and position of mouse 
-- mouseOrigCCLane: (CC0-127 = 7-bit CC, 0x100|(0-31) = 14-bit CC, 0x200 = velocity, 0x201 = pitch, 
--    0x202=program, 0x203=channel pressure, 0x204=bank/program select, 
--    0x205=text, 0x206=sysex, 0x207=off velocity)
local window, segment, details -- given by the SWS function reaper.BR_GetMouseCursorContext()
--[[Not relevant to this script
local laneIsCC7BIT    = false
local laneIsCC14BIT   = false
local laneIsPITCH     = false
local laneIsCHPRESS   = false
local laneIsPROGRAM   = false
local laneIsVELOCITY  = false
local laneIsPIANOROLL = false 
local laneIsSYSEX     = false -- not used in this script
local laneIsTEXT      = false
local laneMin, laneMax -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue ]]
local mouseOrigPPQpos, mouseOrigPitch
--local gridOrigPPQpos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)
local isInline -- Is the user using the inline MIDI editor?  (The inline editor does not have access to OnCommand.)

-- In order to draw a line with an appropriate thickness, the script will in each loop compare the movement in pixels with 
--    the movement in ticks, to try to deduce a zoom lovel.
local mouseOrigX, mouseOrigY
local mouseMaxMovedX, mouseMaxMovedPPQ = 0, 0
local zoomEstimateTicksPerPixels = (5*960*4)/1400 -- This is just a starting guess, based on screen 1400 pixels wide, and a zoomn level of 5 measures per editor.

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQpos, mouseNewPitch
local gridNewPPQpos 
local mouseWheel = 0 -- Track mousewheel movement

-- REAPER preferences and settings that will affect the drawing of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-to-grid is enabled in the editor
local defaultChannel -- In case new MIDI events will be inserted, what is the default channel?
--local CCdensity -- grid resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
--local PPperCC -- ticks per CC ** not necessarily an integer **
--local PPQ -- ticks per quarter note

-- The crucial function BR_GetMouseCursorContext gets slower and slower as the number of events in the take increases.
-- Therefore, the active take will be emptied *before* calling the function, using MIDI_SetAllEvts.
local sourceLengthTicks -- = reaper.BR_GetMidiSourceLenPPQ(take)
local AllNotesOffMsg = string.char(0xB0, 0x7B, 0x00)
local AllNotesOffString -- = s_pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)

-- The script works in looped takes, so to get the actual PPQ position of the mouse,
--    it must be correctd by subtracting the start PPQ position of the loop.
local loopStartPPQpos -- Start of loop iteration under mouse

-- Some internal stuff that will be used to set up everything
local _, item, take, editor, isInline, QNperGrid

-- I am not sure that defining these functions as local really helps to spred up the script...
local s_unpack = string.unpack
local s_pack   = string.pack
local m_floor  = math.floor
  
-- User preferences that can be set via other scripts
local mustDrawCustomCursor = not (reaper.GetExtState("js_Mouse actions", "Draw custom cursor") == "false")


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
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(false) end
   
    -------------------------------------------------
    -- Check if mouse is still insid ethe notes area.
    -- (Apparently, BR_GetMouseCursorContext must always precede the other BR_ context calls)
    -- ***** Trick: BR_GetMouse... gets slower and slower as the number of events in the take increases.
    --              Therefore, clean the take *before* calling the function!
    -- To improve accuracy, the pizel position and the PPQ position must be retrieved as close in time to each other as possible.
    reaper.MIDI_SetAllEvts(take, AllNotesOffString)
    mouseNewX, mouseNewY = reaper.GetMousePosition()
    -- Tooltip position is changed immediately before getting mouse cursor context, to prevent cursor from being above tooltip.
    if mustDrawCustomCursor then
        reaper.TrackCtl_SetToolTip("-∕-", mouseNewX+7, mouseNewY+8, true)
    end
    window, segment, details = reaper.BR_GetMouseCursorContext()  
    
    ----------------------------------------------------------------------------------
    -- What must the script do if the mouse moves out of the original CC lane area?
    -- Per default, the script will terminate.  This is an easy way to ensure that 
    --    the script does not continue to run indefinitely without the user realising.
    if segment ~= "notes" then 
        return(0)
    end   
    
    -------------------------------------------------------------------------------------
    -- Try to estimate zoom level.  (Before correcting the PPQ position for looped takes.
    -- Hopefully REAPER will soon offer an API function to return this value.
    if mouseNewX < mouseOrigX then mouseAbsMovedX = mouseOrigX-mouseNewX else mouseAbsMovedX = mouseNewX-mouseOrigX end -- Get absolutre value
    if mouseAbsMovedX > mouseMaxMovedX then  -- The maximum movement is likely to give the best estimate of the zoom level
        mouseMaxMovedX = mouseAbsMovedX
        if mouseNewPPQpos < mouseOrigPPQpos then mouseAbsMovedPPQ = mouseOrigPPQpos - mouseNewPPQpos else mouseAbsMovedPPQ = mouseNewPPQpos - mouseOrigPPQpos end -- Absolute value
        --if mouseAbsMovedPPQ > mouseMaxMovedPPQ then mouseMaxMovedPPQ = mouseAbsMovedPPQ end
        --if mouseMaxMovedX > 0 then
            zoomEstimateTicksPerPixels = mouseAbsMovedPPQ/mouseAbsMovedX
        --end
    end
    
    -------------------------------------------
    -- Track the new mouse (vertical) position.
    _, _, mouseNewPitch, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    if mouseNewPitch > 127 then mouseNewPitch = 127 end
    if mouseNewPitch < 0 then mouseNewPitch = 0 end
            
    ---------------------------------------
    -- Get loop-correctd mouse PPQ position
    -- (And prevent mouse line from extending beyond item boundaries.)
    mouseNewPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
    mouseNewPPQpos = mouseNewPPQpos - loopStartPPQpos
    if mouseNewPPQpos < 0 then mouseNewPPQpos = 0
    elseif mouseNewPPQpos > sourceLengthTicks-1 then mouseNewPPQpos = sourceLengthTicks-1
    else mouseNewPPQpos = m_floor(mouseNewPPQpos + 0.5)
    end
    
    --------------------------------------------------------------
    -- Draw the line
      
        
    -- Make sure that thickness is an even number, so that middle of note can fall on cut PPQ position.
    -- Make sure that note length is not 0.
    -- Make sure that note length is never weirdly long (which may happen if user scrolss MIDI editor while script is running, thereby chanig mouseNewPPQpos without changing X position).
    local thicknessPPQ = math.ceil(thicknessPixels*zoomEstimateTicksPerPixels/2) * 2
    if thicknessPPQ < 2 then thicknessPPQ = 2 end
    if thicknessPPQ > 480 then thicknessPPQ = 480 end
    
    -- Clear the table of line MIDI event
    local tableLineMIDI = {}
    local t = 0 -- -- Count index in tableLine - This is faster than using table.insert or even #table+1
    local lastPPQpos = lastOrigMIDIPPQpos
    tableCutPPQpos = {} -- The PPQ position at which cuts should be made, using [pitch] as key (NOT local)
    
    if mouseNewPitch == mouseOrigPitch then -- Separate code for this case since denominator=0, and should not insert second note at mouse position.
        local ppq = mouseOrigPPQpos
        if isInline then
            local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq)
            local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
            ppq = reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos)
        elseif isSnapEnabled then --and pitch ~= mouseOrigPitch and pitch ~= mouseNewPitch then
            -- Note that the line snaps to closest grid, not the floor grid
            local QNpos = reaper.MIDI_GetProjQNFromPPQPos(take, ppq)
            local roundGridQN = math.floor(QNpos/QNperGrid + 0.5)*QNperGrid
            ppq = reaper.MIDI_GetPPQPosFromProjQN(take, roundGridQN) 
        end
        ppq = math.floor(ppq + 0.5)
        tableCutPPQpos[mouseOrigPitch] = ppq
        t = t + 1
        tableLineMIDI[t] = s_pack("i4Bi4BBB", (ppq-thicknessPPQ/2)-lastPPQpos, 3, 3, 0x90|defaultChannel, mouseOrigPitch, 1)
        t = t + 1
        tableLineMIDI[t] = s_pack("i4Bi4BBB", thicknessPPQ, 3, 3, 0x80|defaultChannel, mouseOrigPitch, 0)
        lastPPQpos = ppq + thicknessPPQ/2
    else
        if mouseOrigPitch <= mouseNewPitch then step = 1 else step = -1 end
        for pitch = mouseOrigPitch, mouseNewPitch, step do
            local ppq = mouseOrigPPQpos + (mouseNewPPQpos-mouseOrigPPQpos)*(pitch-mouseOrigPitch)/(mouseNewPitch-mouseOrigPitch)
            if isInline then
                local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq)
                local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
                ppq = reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos)
            elseif isSnapEnabled then --and pitch ~= mouseOrigPitch and pitch ~= mouseNewPitch then             
                -- Note that the line snaps to closest grid, not the floor grid
                local QNpos = reaper.MIDI_GetProjQNFromPPQPos(take, ppq)
                local roundGridQN = math.floor(QNpos/QNperGrid + 0.5)*QNperGrid
                ppq = reaper.MIDI_GetPPQPosFromProjQN(take, roundGridQN) 
            end
            ppq = math.floor(ppq + 0.5)
            tableCutPPQpos[pitch] = ppq
            t = t + 1
            tableLineMIDI[t] = s_pack("i4Bi4BBB", (ppq-thicknessPPQ/2)-lastPPQpos, 3, 3, 0x90|defaultChannel, pitch, 1)
            t = t + 1
            tableLineMIDI[t] = s_pack("i4Bi4BBB", thicknessPPQ, 3, 3, 0x80|defaultChannel, pitch, 0)
            lastPPQpos = ppq + thicknessPPQ/2
        end
    end   
                                
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    -- This also updates the offset of the first event in MIDIstringSub5 relative to the PPQ position of the last event in tableRawMIDI
    --local newOrigOffset = originalOffset-lineRightPPQpos
    reaper.MIDI_SetAllEvts(take, MIDIstringWithoutNotesOff
                                .. table.concat(tableLineMIDI)
                                .. s_pack("i4Bs4", sourceLengthTicks - lastPPQpos, 0, AllNotesOffMsg))
    
    if isInline then reaper.UpdateItemInProject(item) end
    
    ---------------------------------------        
    -- Continuously loop the function
    reaper.runloop(loop_trackMouseMovement)

end -- loop_trackMouseMovement()

-------------------------------------------

--##########################################################################
----------------------------------------------------------------------------
function onexit()
    
    -- Remove tooltip 'custom cursor'
    reaper.TrackCtl_SetToolTip("", 0, 0, true)
    
    ---------------------------------------------------
    -- Now that the script exits, the cuts can be made.
    
    -- To find each note-ons matching note-off, the info of note-ons will temporarily be stored in tableNoteOns.
    local tableNoteOns = {} 
    for flags = 0, 3 do
        tableNoteOns[flags] = {}
        for chan = 0, 15 do
            tableNoteOns[flags][chan] = {} -- tableNoteOns[flags][channel][pitch] = {PPQpos, msg}
        end
    end
    
    -- All the parsed and cut MIDI events will be stored in tableEvents
    local tableEvents = {}
    local t = 0
    
    local stringPos = 1 -- Position in MIDIstring while parsing
    local runningPPQpos = 0 -- PPQ position of event parsed
    local MIDIlen = MIDIstring:len()
    while stringPos < MIDIlen do
        local hasAlreadyInsertedEvent = false
        local offset, flags, msg
        offset, flags, msg, stringPos = s_unpack("i4Bs4", MIDIstring, stringPos)
        runningPPQpos = runningPPQpos + offset
        if flags&1 == 1 or not onlySliceSelectedNotes then
            if msg:len() == 3 then
                eventType = msg:byte(1)>>4
                if eventType == 9 and not (msg:byte(3) == 0) then
                    local channel = msg:byte(1)&0x0F
                    local pitch   = msg:byte(2)
                    if tableNoteOns[flags][channel][pitch] then
                        reaper.MIDI_SetAllEvts(take, MIDIstring) -- Restore original MIDI                    
                        reaper.ShowMessageBox("The script has encountered overlapping notes."
                                              .. "\n\nSuch notes are not technically legal MIDI data, and their lengths can not be parsed.", "ERROR", 0)
                        undoString = "FAILED: Split notes by drawing a line with the mouse"
                        goto skipSetNewEvts
                    else
                        tableNoteOns[flags][channel][pitch] = {notePPQ = runningPPQpos, noteMsg = msg}
                    end
                elseif eventType == 8 or (eventType == 9 and msg:byte(3) == 0) then
                    local channel = msg:byte(1)&0x0F
                    local pitch   = msg:byte(2)
                    if tableNoteOns[flags][channel][pitch] then -- Is there a matching note-on waiting?
                        if tableCutPPQpos[pitch] then -- Does this pitch fall within the cutting line's pitch range?
                            if tableCutPPQpos[pitch] > tableNoteOns[flags][channel][pitch].notePPQ and tableCutPPQpos[pitch] < runningPPQpos then
                                t = t + 1
                                tableEvents[t] = s_pack("i4Bs4", offset - runningPPQpos + tableCutPPQpos[pitch], flags, msg)
                                t = t + 1
                                tableEvents[t] = s_pack("i4Bs4", 0, flags, tableNoteOns[flags][channel][pitch].noteMsg)
                                t = t + 1
                                tableEvents[t] = s_pack("i4Bs4", runningPPQpos - tableCutPPQpos[pitch], flags, msg)                               
                                hasAlreadyInsertedEvent = true
                            end
                        end
                    end
                    tableNoteOns[flags][channel][pitch] = nil
                end
            end -- if msg:len() == 3 
        end -- if flags&1 == 1 or not onlySliceSelectedNotes
        if not hasAlreadyInsertedEvent then
            t = t + 1
            tableEvents[t] = s_pack("i4Bs4", offset, flags, msg)
        end                  
    end

    reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
    
    -- MIDI_Sort used to be buggy when dealing with overlapping or unsorted notes,
    --    causing infinitely extended notes or zero-length notes.
    -- Fortunately, these bugs were seemingly all fixed in v5.32.
    reaper.MIDI_Sort(take)
        
    -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        undoString = "FAILED: Split notes by drawing a line with the mouse"
        reaper.MIDI_SetAllEvts(take, MIDIstring) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
    else
        undoString = "Split notes by drawing a line with the mouse"
    end
        
    ------------------
    ::skipSetNewEvts::
    
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
                
    -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
    --    in the undo point to changes in this specific item.
    reaper.Undo_OnStateChange_Item(0, undoString, item)

end -- function onexit


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


--############################################################################################
----------------------------------------------------------------------------------------------
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
    elseif not(segment == "notes") then 
        reaper.ShowMessageBox("Mouse is not correctly positioned.\n\n"
                              .. "The mouse should be positioned over a the 'notes area' of an active MIDI editor.", "ERROR", 0)
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
    
    
    -------------------------------------------------------------------
    -- Events will be inserted in the active channel of the active take
    if isInline then
        defaultChannel = 0
    else
        defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
    end
    
    
    ---------------------------------------------------------------------------------------
    -- Unlike the scripts that edit and change existing events, this scripts does not need
    --    to do any parsing before starting drawing.
    -- Parsing (and deletion) will be performed at the end, in the onexit function.
    gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    if not gotAllOK then
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
    
    
    ------------------------------------------------------------------------------------------
    -- The starting X pixel position will later be used to estimate the ticks/pixel xoom level
    mouseOrigX, mouseOrigY = reaper.GetMousePosition()
    
    
    -----------------------------------------------------------------------------------------------
    -- Get the starting PPQ (horizontal) position of the ramp.  Must check whether snap is enabled.
    -- Also, contract to position within item, and then divide by source length to get position
    --    within first loop iteration.
    mouseOrigPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5)
    local itemLengthTicks = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH"))+0.5)
    mouseOrigPPQpos = math.max(0, math.min(itemLengthTicks-1, mouseOrigPPQpos)) -- I prefer not to draw any event on the same PPQ position as the All-Notes-Off
    loopStartPPQpos = (mouseOrigPPQpos // sourceLengthTicks) * sourceLengthTicks
    mouseOrigPPQpos = mouseOrigPPQpos - loopStartPPQpos
    
    
    -----------------------------------------------------------------------------
    -- If snap is enabled, each cut position will be snapped to the closest grid.
    if isInline then
        isSnapEnabled = false
    else
        isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")==1)
        QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
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

end -- main()

--------------------------------------------------
--------------------------------------------------
mainOK = main()
if mainOK == false then
    if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
    reaper.DeleteExtState("js_Mouse actions", "Status", true)    
end

--[[
ReaScript name: js_Mouse editing - Swipe select events in lane under mouse.lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # Description  
  
  Select events in the lane under the mouse by simply swiping the mouse.  
  
  All events within the horizontal (time) range of mouse movement will be selected.
  
  The mouse does not need to touch the CC bars.)
]]
 
--[[
  Changelog:
  * v0.90 (2018-06-11)
    + Initial beta release
]]


-- ################################################################################################
---------------------------------------------------------------------------------------------------

-- Since this script will not delete events r change their positions, the target events will not be 
--    extracted from the MIDI string.  Instead, the positions (in the MIDI string) of the status flags 
--    of all the target events will be stored in tables, and if the selection status changes,
--    the flags will be updated in-place.  
local MIDIString -- The raw MIDI data will be stored in the string.
local tStrPos = {} -- tStrPos stores positions (inside MIDIString) of flag bytes of events in target lane
local tTicks  = {} -- PPQ position of each event in target lane
local tFlags  = {}
local tSelected = {} -- Updated selection status.  If already selected in previous loop, no need to update in subsequent loops.
 
-- Starting values and position of mouse 
-- Not all of these lanes will be used by all scripts.
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
local laneMin, laneMax -- The minimum and maximum values in the target lane
local mouseOrigCCLane, mouseOrigCCValue, mouseOrigPPQpos, mouseOrigPitch, mouseOrigCCLaneID
--local gridOrigPPQpos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- Tracking the new value and position of the mouse while the script is running
local mouseNewCCLane, mouseNewCCValue, mouseNewPPQpos, mouseNewPitch, mouseNewCCLaneID
local mouseLeftmostPPQpos, mouseRightmostPPQpos -- Range of mouse movement
--local gridNewPPQpos 
--local mouseWheel = 1 -- Track mousewheel movement.  ***** This default value may change, depending on the script and formulae used. *****

-- REAPER preferences and settings that will affect the drawing of new events in take
local isSnapEnabled -- Will be changed to true if snap-togrid is enabled in the editor
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
local sourceLengthTicks -- = reaper.BR_GetMidiSourceLenPPQ(take)
local AllNotesOffString -- = string.pack("i4Bi4BBB", sourceLengthTicks, 0, 3, 0xB0, 0x7B, 0x00)
local loopStartPPQpos -- Start of loop iteration under mouse
local takeIsCleared = false --Flag to record whether the take has been cleared (and must therefore be uploaded again before quitting)

-- Some internal stuff that will be used to set up everything
local _, item, take, editor, isInline

-- I am not sure that declaring functions local really helps to speed things up...
local s_unpack = string.unpack
local s_pack   = string.pack
local t_insert = table.insert -- myTable[i] = X is actually much faster than t_insert(myTable, X)
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

    -------------------------------------------
    -- Track the new mouse (vertical) position.
    -- (Apparently, BR_GetMouseCursorContext must always precede the other BR_ context calls)
    -- ***** Trick: BR_GetMouse... gets slower and slower as the number of events in the take increases.
    --              Therefore, clean the take *before* calling the function!
    takeIsCleared = true    
    reaper.MIDI_SetAllEvts(take, AllNotesOffString)
    
    -- Tooltip position is changed immediately before getting mouse cursor context, to prevent cursor from being above tooltip.
    if mustDrawCustomCursor then
        local mouseNewXpos, mouseNewYpos = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(" □", mouseNewXpos+7, mouseNewYpos+8, true)
    end
    window, segment, details = reaper.BR_GetMouseCursorContext()  
    _, _, _, mouseNewCCLane = reaper.BR_GetMouseCursorContext_MIDI()
        -- Script will automatically quit if mouse moves out of original CC lane
        if mouseNewCCLane ~= mouseOrigCCLane or details ~= "cc_lane" then return(false) end
    
    ------------------------------------------
    -- Get mouse new PPQ (horizontal) position
    mouseNewPPQpos = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position())
    mouseNewPPQpos = mouseNewPPQpos - loopStartPPQpos
    
    if not isSnapEnabled then
        snappedNewPPQpos = mouseNewPPQpos
    elseif isInline then
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, mouseNewPPQpos)
        local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
        snappedNewPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos) + 0.5)
    else
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseNewPPQpos) -- Mouse position in quarter notes
        local roundedGridQN = math.floor((mouseQNpos/QNperGrid)+0.5)*QNperGrid -- last grid before mouse position
        snappedNewPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjQN(take, roundedGridQN) + 0.5)
    end
    
    if snappedNewPPQpos < mouseLeftmostPPQpos then mouseLeftmostPPQpos = snappedNewPPQpos end
    if snappedNewPPQpos > mouseRightmostPPQpos then mouseRightmostPPQpos = snappedNewPPQpos end
    
    -- Does mouse range overlap with target events?
    if tTicks[1] <= mouseRightmostPPQpos and tTicks[#tTicks] >= mouseLeftmostPPQpos then   
        
          -- Do a quick binary search to find event close to left edge of mouse movement
          l, r = 1, #tTicks
          while r-l > 1 do
              m = ((l+r)>>1)
              if tTicks[m] <= mouseLeftmostPPQpos then l = m else r = m end
          end
  
          -- Change the UNselected events that are within the mouse movement range.
          -- Lua doesn't have string functions to change specific chars, so must divide MIDIString into table. table.concat is much faster than ..
          local tMIDI = {}
          local lastStrPos = 0
          for i = 1, #tTicks do
              -- Events precisely at rightmost edge of mouse movement will not be selected, to ensure that all selected events fall *within* the time selection
              --    (and will therefore be co-selected with notes that were drawn on the grid).
              if tTicks[i] >= mouseRightmostPPQpos and tTicks[i] ~= mouseLeftmostPPQpos then
                  break
              elseif not tSelected[i] and tTicks[i] >= mouseLeftmostPPQpos then
                  tMIDI[#tMIDI+1] = MIDIString:sub(lastStrPos+1, tStrPos[i]-1)
                  tMIDI[#tMIDI+1] = string.pack("B", tFlags[i]|1)
                  lastStrPos = tStrPos[i]
              end
          end
          
          tMIDI[#tMIDI+1] = MIDIString:sub(lastStrPos+1, nil)
          
          MIDIString = table.concat(tMIDI)
    end
       
    -----------------------------------------------------------
    -- DRUMROLL... write the edited events into the MIDI chunk!
    reaper.MIDI_SetAllEvts(take, MIDIString)
    takeIsCleared = false    
    if isInline then reaper.UpdateItemInProject(item) end
    
    reaper.defer(loop_trackMouseMovement)
    
end -- loop_trackMouseMovement()


--############################################################################################
----------------------------------------------------------------------------------------------
function onexit()
    
    -- Remove tooltip 'custom cursor'
    reaper.TrackCtl_SetToolTip("", 0, 0, true)
    
    -- Remember that the take was cleared before calling BR_GetMouseCursorContext
    --    So upload MIDI again.
    if takeIsCleared then
        reaper.MIDI_SetAllEvts(take, MIDIString)
    end
           
    -- No need to call MIDI_Sort since this script does not alter MIDI order
    --reaper.MIDI_Sort(take)  
    
    -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        --reaper.MIDI_SetAllEvts(take, MIDIString) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              --.. "\n\nThe original MIDI data will be restored to the take."
                              , "ERROR", 0)
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
                
    -- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
    --    in the undo point to changes in this specific item.
    reaper.Undo_OnStateChange_Item(0, "Select events", item)
    
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


------------------------------------------------------------------------------------------
-- In order to handle 14-bit CCs as two separate tilts of the MSB and LSB 7-bit CC lanes, 
--    the tilt function is separated into a function with different mouseOrigCClane values.
function findPositionsOfFlagsWithinMIDIString()

    local i = 0 -- index inside tTicks and other tables
    local pos, prevPos = 1, 1 -- Positions inside MIDI string
    local ticks = 0 -- Running PPQ position of events while parsing
    local offset, flags, msg
    local rememberEvent
    
    while pos < #MIDIString do
        rememberEvent = false
        offset, flags, msg, pos = string.unpack("i4Bs4", MIDIString, pos)
        ticks = ticks + offset
        if #msg ~= 0 and flags&1 ~= 1 then -- ignore empty messages (without status bytes) and already-selected events
            if laneIsCC7BIT then 
                if (msg:byte(1))>>4 == 11 and msg:byte(2) == mouseOrigCCLane then
                    rememberEvent = true
                end
            elseif laneIsCC14BIT then
                if (msg:byte(1))>>4 == 11 and (msg:byte(2) == mouseOrigCClane-256 or msg:byte(2) == mouseOrigCClane-224) then
                    rememberEvent = true
                end
            elseif laneIsPITCH then
                if (msg:byte(1))>>4 == 14 then
                    rememberEvent = true
                end
            elseif laneIsPROGRAM then 
                if (msg:byte(1))>>4 == 12 then
                    rememberEvent = true
                end
            elseif laneIsBANKPROG then
                if ((msg:byte(1))>>4 == 12 or ((msg:byte(1))>>4 == 11 and (msg:byte(2) == 0 or msg:byte(2) == 32))) then
                    rememberEvent = true
                end
            elseif laneIsSYSEX then
                if (msg:byte(1))>>4 == 0xF and not (msg:byte(1) == 0xFF) then 
                    rememberEvent = true 
                end
            elseif laneIsTEXT then
                if msg:byte(1) == 0xFF and not (msg:byte(2) == 0x0F) then
                    rememberEvent = true
                end
            end
        end
        if rememberEvent then
            i = i + 1
            tStrPos[i] = pos - #msg - 5 -- Position of flags' byte inside MIDI
            tTicks[i]  = ticks
            tFlags[i]  = flags
            tSelected[i] = false -- Will be changed while script is running
        end
    end
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
        reaper.ShowMessageBox("This script requires an up-to-date versions of the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        return(false) 
    end   
    
    ----------------------------------------------------
    -- Get original mouse position in pixel coordinates.
    mouseXorig, mouseYorig = reaper.GetMousePosition()
    
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
    elseif not(details == "cc_lane") then 
        reaper.ShowMessageBox("Mouse is not correctly positioned.\n\n"
                              .. "This script selects events in the CC lane that is under the mouse, "
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
    
    -------------------------------------------------------------
    -- Since 7bit CC, 14bit CC, channel pressure, and pitch all 
    --     require somewhat different tweaks, these must often be 
    --     distinguished.   
    --[[if segment == "notes" then
        laneIsPIANOROLL, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 0
    else]]if 0 <= mouseOrigCCLane and mouseOrigCCLane <= 127 then -- CC, 7 bit (single lane)
        laneIsCC7BIT = true
        laneMax = 127
        laneMin = 0
    --[[elseif mouseOrigCCLane == 0x200 then
        laneIsVELOCITY, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 1 ]]   
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
    --[[elseif mouseOrigCCLane == 0x207 then
        laneIsOFFVEL, laneIsNOTES = true, true
        laneMax = 127
        laneMin = 0]]
    else -- not a lane type in which script can be used.
        reaper.ShowMessageBox("This script does not yet work on notes, velocities or notation."
                              , "ERROR", 0)
        return(false)
    end
    
    ---------------------------------------------------------------------------------------
    -- Time to process the MIDI of the take!
    -- As mentioned above, this script does not use the standard MIDI API functions such as 
    --    MIDI_InsertCC, since these functions are far too slow when dealing with thousands 
    --    of events.
    MIDIOK, MIDIString = reaper.MIDI_GetAllEvts(take, "")
        if not MIDIOK then reaper.MB("Error while loading MIDI", "ERROR", 0) return(false) end
    findPositionsOfFlagsWithinMIDIString()
        if #tTicks == 0 then return(true) end -- No unselected events in target lane?
    
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
        isSnapEnabled = (reaper.GetToggleCommandStateEx(0, 1157) == 1)
        -- Even is snapping is disabled, need PPperGrid and QNperGrid for LFO length
        local _, gridDividedByFour = reaper.GetSetProjectGrid(0, false)
        QNperGrid = gridDividedByFour*4
    else
        isSnapEnabled = (reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled") == 1)
        QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
    end
    
    if isSnapEnabled == false then
        snappedOrigPPQpos = mouseOrigPPQpos
    elseif isInline then
        local timePos = reaper.MIDI_GetProjTimeFromPPQPos(take, mouseOrigPPQpos)
        local snappedTimePos = reaper.SnapToGrid(0, timePos) -- If snap-to-grid is not enabled, will return timePos unchanged
        snappedOrigPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjTime(take, snappedTimePos) + 0.5)
    else
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseOrigPPQpos) -- Mouse position in quarter notes
        local roundedGridQN = math.floor((mouseQNpos/QNperGrid)+0.5)*QNperGrid -- last grid before mouse position
        snappedOrigPPQpos = m_floor(reaper.MIDI_GetPPQPosFromProjQN(take, roundedGridQN) + 0.5)
    end 
    
    mouseLeftmostPPQpos, mouseRightmostPPQpos = snappedOrigPPQpos, snappedOrigPPQpos
    
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

--[[
ReaScript name:  js_Move all selected events in active take together with mouse.lua
Version: 0.90
Author: juliansader
Screenshot: http://stash.reaper.fm/29102/Move%20events%20to%20mouse%20position.gif
Website: http://forum.cockos.com/showthread.php?t=184629
REAPER: v5.30 or later
Extensions: SWS/S&M 2.8.3 or later
About:
  # Description
  A script for moving all selected events (in active take) together. The events will follow mouse movement.
  
  If snap-to-grad is enabled in the MIDI editor, the events will be moved to the closest grid position to the left.

  # Instructions             
  There are two ways in which this script can be run:  
  
  * First, the script can be linked to its own shortcut key.
  
  * Second, this script, together with other "js_" scripts that edit the "lane under mouse",
     can each be linked to a toolbar button.  
    In this case, each script need not be linked to its own shortcut key.  Instead, only the 
     accompanying "js_Run the js_'lane under mouse' script that is selected in toolbar.lua"
     script needs to be linked to a keyboard shortcut (as well as a mousewheel shortcut).
    Clicking the toolbar button will 'arm' the linked script (and the button will light up), 
     and this selected (armed) script can then be run by using the shortcut for the 
     aforementioned "js_Run..." script.
    For further instructions - please refer to the "js_Run..." script.
  
   Note: Since this function is a user script, the way it responds to shortcut keys and 
       mouse buttons is opposite to that of REAPER's built-in mouse actions 
       with mouse modifiers:  To run the script, press the shortcut key *once* 
       to start the script and then move the mouse *without* pressing any 
       mouse buttons.  Press the shortcut key again once to stop the script. 
        
   (The first time that the script is stopped, REAPER will pop up a dialog box 
       asking whether to terminate or restart the script.  Select "Terminate"
       and "Remember my answer for this script".)
  
  # Warning
  The script will run in the inline MIDI editor, but if there are any overlapping notes in the take,
  these may transform into extended notes.  
]]

--[[
 Changelog:
  * v0.90 (2016-12-16)
    + Initial beta release
]]

---------------------------------------
-- USER AREA
-- Settings that the user can customize

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
-- When the script exits, instead of using MIDI_Sort, the action "Invert selection" will be called 
--    (twice) using OnCommand.  This should induce the MIDI editor to sort the MIDI data.
--    (In the case of the inline editor, OnCommand is unfortunately not evailable, so MIDI_Sort must be used.)

-- The raw MIDI data will be stored in two long strings: remainMIDIstring will contain the data
--    of the non-selected events left behind, and selectdMIDIstring will contain the data of
--    the selected, extracted events (together with notation text events of selected notes).
-- In each cycle of the deferred function, these strings will be concatenated in order to assemble all the 
--    MIDI in the take.
-- Since neither the relative offsets (nor any other data) of the events in each string will change 
--    while the events move along with the mouse, there is no need to store each of the event separately in a table.
-- In each string, the only event offset that will change, is the offset of the very first events:
--    The first event in selectedMIDIstring will be updated to follow the mouse, and the first
--    event in remainMIDIstring will be updated relative to the last PPO position of the events in selectedMIDIstring.
-- The offset of the first event in each string will therefore be stored separately - not in the string - 
--    since this offset will need to be updated in each cycle.
local MIDIstring
local remainMIDIstring 
local remainOffset
local selectedMIDIstring
local selectedMIDIPPQrange
 
-- Starting values and position of mouse 
local window, segment, details -- given by the SWS function reaper.BR_GetMouseCursorContext()
local gridOrigPPQpos -- If snap-to-grid is enabled, these will give the closest grid PPQ to the left. (Swing is not implemented.)

-- Tracking the new value and position of the mouse while the script is running
local mouseNewPPQpos
local gridNewPPQpos 

-- REAPER preferences and settings that will affect the drawing of new events in take
local isSnapEnabled = false -- Will be changed to true if snap-togrid is enabled in the editor

-- Some internal stuff that will be used to set up everything
local _, take, editor, isInline

  
--#############################################################################################
-----------------------------------------------------------------------------------------------
-- The function that will be 'deferred' to run continuously
-- There are two bottlenecks that impede the speed of this function:
--    Minor: reaper.BR_GetMouseCursorContext(), which must unfortunately unavoidably be called before 
--           reaper.BR_GetMouseCursorContext_MIDI(), and which (surprisingly) gets much slower as the 
--           number of MIDI events in the take increases.
--    Major: reaper.SetItemState, which is much slower than even GetMouseCursorContext.
-- The Lua script parts of this function - even if it calculates thousands of events per cycle,
--    make up only a small fraction of the execution time,
local function loop_trackMouseMovement()

    -------------------------------------------------------------------------------------------
    -- The js_Run... script can communicate with and control the other js_ scripts via ExtState
    if reaper.GetExtState("js_Mouse actions", "Status") == "Must quit" then return(0) end
   
    ---------------------------------------------------------------------------------
    -- What must the script do if the mouse moves out of the notes are or CC lanes?
    -- Per default, the script will terminate.  This is an easy way to ensure that 
    --    the script does not continue to run indefinitely without the user realising.    
    window, segment, details = reaper.BR_GetMouseCursorContext() 
    if not (segment == "notes" or details == "cc_lane") then
        return
    end
            
    --------------------------------------------------------------
    -- Get mouse new PPQ (horizontal) position
    -- Prevent selected events from being moved out of item range.
    mouseNewPPQpos = math.max(0, math.min(AllNotesOffPPQpos-selectedMIDIPPQrange-1, math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5)))
    if isSnapEnabled then
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseNewPPQpos) -- Mouse position in quarter notes
        local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
        gridNewPPQpos = math.floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
    -- Otherwise, destination PPQ is exact mouse position
    else 
        gridNewPPQpos = mouseNewPPQpos
    end -- if isSnapEnabled

    ---------------------------------------------------------------
    -- Calculate the new raw MIDI data, and write the tableRawMIDI!
    -- Actually, this script is so simple that nothing needs to be calculated.
    --    Only the offsets of the first event in each string needs to be updated.
    reaper.MIDI_SetAllEvts(take, string.pack("i4", gridNewPPQpos)
                              .. selectedMIDIstring
                              .. string.pack("i4", remainOffset - (gridNewPPQpos + selectedMIDIPPQrange))
                              .. remainMIDIstring)
  
    if isInline then reaper.UpdateArrange() end

    ---------------------------------------
    -- Continuously loop the function
    reaper.runloop(loop_trackMouseMovement)

end -- loop_trackMouseMovement()


--############################################################################################
----------------------------------------------------------------------------------------------
function exit()
    
    -- Calls to native actions such as "Invert selection" via OnCommand must be placed
    --    within explicit undo blocks, otherwise they will create their own undo points.
    -- Strangely, in the current v5.30, undo blocks are interrupted as soon as the 
    --    atexit-defined function is called.  *This is probably a bug.*  
    -- Therefore must start a new undo block within this exit function.  Fortunately, 
    --    this undo point seems to undo the entire defered script, not only the stuff that
    --    happens within this exit function.
    reaper.Undo_BeginBlock()
    
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
                
    -- End undo block
    reaper.Undo_EndBlock("Move selected events in active take", -1)
       
end -- function exit



--####################################################################################
--------------------------------------------------------------------------------------
-- This loop will iterate through the MIDI data, event-by-event.
--
-- Only selected events will be extracted.  The exception is notation events: Notation 'text events' for selected noted are unfortunately not also selected. 
--    So relevant notation text events can only be found by checking each and every notation event.
--
-- Should this parser check for unsorted MIDI?  This would depend on the function of the script. 
-- Scripts such as "Remove redundant CCs" will only work on sorted MIDI.  For others, sorting is not relevant.
-- Note that even in sorted MIDI, the first event can have an negative offset if its position is to the left of the item start.
-- As discussed in the introduction, MIDI sorting entails several problems.  This script will therefore avoid sorting until it exits, and
--    will instead notify the user, in the rare case that unsorted MIDI is deteced.  (Checking for negative offsets is also faster than unneccesary sorting.)
--
-- The parser will try to make execution faster by not inserting events that are not changed 
--      (i.e. not extracted or offset changed) individually into tableRemainingEvents, using string.pack.  
--      Instead, they will be inserted as blocks of multiple events, copied directly from MIDIstring.  
--      By so doing, the number of table writes are lowered, the speed of table.concat is improved, and string.sub
--      can be used instead of string.pack.

function parseAndExtractTargetMIDI()  
    
    -- REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
    --    MIDI_GetAllEvts and MIDI_SetAllEvts.
    gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    
    if gotAllOK then 
        
        -- The short MIDI strings of events will temnporarily be stored in tables,
        --    and once all MIDI data have been parsed, each table will be 
        --    will be concatenated, thereby dividing the original MIDIstring into two.
        local tableRemainingEvents = {}    
        local tableExtractedEvents = {}
        local r, e = 0, 0 -- Indices within tables.  Inserting into myTable[index] is much faster than using table.insert(myTable).
         
        local runningPPQpos = 0 -- The MIDI string only provides the relative offsets of each event, so the actual PPQ positions must be calculated by iterating through all events and adding their offsets
        local lastExtractedPPQpos = 0
        local lastRemainPPQpos = 0
        selectedMIDIPPQrange = 0 -- global variable
        
        -- I am not sure that declaring functions local really helps to speed things up...
        local s_unpack = string.unpack
        local s_pack   = string.pack
        
        local prevPos, nextPos, unchangedPos = 1, 1, 1 -- Keep record of position within MIDIstring. unchangedPos is position from which unchanged events van be copied in bulk.
        
        ----------------------------------------------------------------
        
        local MIDIlen = MIDIstring:len()   
        
        while nextPos <= MIDIlen do
           
            local mustExtract = false
            local offset, flags, msg
            
            prevPos = nextPos
            offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)            
          
            ----------------------------------------------------------
            -- Perform a few basic checks if parsing is still going OK
            if not flags or flags|3 ~= 3 then -- flags can only be 00000001, 00000010 or 00000011
                reaper.ShowMessageBox("The MIDI data uses an unknown format that could not be parsed."
                                      .. "\n\nPlease report the problem in the thread http://forum.cockos.com/showthread.php?t=176878:"
                                      .. "\nFlags = " .. string.format("%02x", flags)
                                      , "ERROR", 0)
                return false
            end            
            
            -- Check for unsorted MIDI.  First event in take can have negative offset, even if sorted, if earlier than start of item.
            if offset < 0 and not (#tableRemainingEvents == 0 and #tablePPQs == 0) then   
                reaper.ShowMessageBox("Unsorted MIDI data has been detected."
                                      .. "\n\nThe script has tried to sort the data, but was unsuccessful."
                                      .. "\n\nSorting of the MIDI can usually be induced by any simple editing action, such as selecting a note."
                                      , "ERROR", 0)
                return false
            end                            

            -- Tests OK, so can update PPQ position
            runningPPQpos = runningPPQpos + offset
            
            -----------------------------------------------------------------------------------------------------
            -- Now find selected event to extract - as well as notation text events (which are always unselected)
            if flags&1 == 1 then -- bit 1: selected
                mustExtract = true
                
            -- Check notation text events
            elseif msg:byte(1) == 0xFF -- MIDI text event
            and msg:byte(2) == 0x0F -- REAPER's MIDI text event type
            then
                -- Search through following events, looking for a selected note that match the channel and pitch
                local notationChannel, notationPitch = msg:match("NOTE (%d+) (%d+) ") 
                if notationChannel then
                    notationChannel = tonumber(notationChannel)
                    notationPitch   = tonumber(notationPitch)
                            
                    local evPos = nextPos -- Start search at position of nmext event in MIDI string
                    local evOffset, evFlags, evMsg
                    repeat -- repeat until an offset is found > 0
                        evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                        if evOffset == 0 then 
                            if evFlags&1 == 1 -- Only match *selected* events
                            and evMsg:byte(1) >> 4  == 9 -- Only match notes
                            and evMsg:byte(1) & 0xF == notationChannel -- Match channel
                            and evMsg:byte(2)       == notationPitch -- Match pitch
                            then
                                -- Matching *selected* note found - so extract this notation event
                                mustExtract = true
                                break
                            end
                        end
                    until evOffset ~= 0
                end   
            end
                            
            -------------------------------------------------------------
            -- Store events in tables (with updated offsets if necessary)
            if mustExtract then
                -- The chain of unchanged remaining events is broken, so write to tableRemainingEvents
                if unchangedPos < prevPos then
                    r = r + 1
                    tableRemainingEvents[r] = MIDIstring:sub(unchangedPos, prevPos-1)
                end
                unchangedPos = nextPos
                mustUpdateNextOffset = true
                -- And write extracted event to tableExtractedEvents
                e = e + 1
                tableExtractedEvents[e] = s_pack("i4Bs4", runningPPQpos - lastExtractedPPQpos, flags, msg)
                selectedMIDIPPQrange = selectedMIDIPPQrange + (runningPPQpos - lastExtractedPPQpos)
                lastExtractedPPQpos = runningPPQpos
                
            -- The offset of a remaining event only needs to be changed if it follows an extracted event.
            elseif mustUpdateNextOffset then
                r = r + 1
                tableRemainingEvents[r] = s_pack("i4Bs4", runningPPQpos-lastRemainPPQpos, flags, msg)
                lastRemainPPQpos = runningPPQpos
                unchangedPos = nextPos
                mustUpdateNextOffset = false
                
            -- If remaining events that is preceded by other remaining events, postpone writing to table
            else
                --
                lastRemainPPQpos = runningPPQpos
            end
                
        end -- while    
            
        -- Reached end of MIDIstring. Write the last remaining events to table
        if unchangedPos < MIDIlen then
            r = r + 1
            tableRemainingEvents[r] = MIDIstring:sub(unchangedPos)
        end
             
        ----------------------------------------------------------------------------------
        -- The entire MIDI string has been parsed.  Now check again that everything is OK. 
        if #tableExtractedEvents == 0 then 
            reaper.ShowMessageBox("Could not find any selected event in the active take.", "ERROR", 0)
            return false
        end -- No selected events, so script can simply quit.
        
        -- Check whether MIDI properly ends in All-Notes-Off message
        local lastEvent = tableRemainingEvents[#tableRemainingEvents]:sub(-12)
        if tableRemainingEvents[#tableRemainingEvents]:byte(-2) ~= 0x7B
        or (tableRemainingEvents[#tableRemainingEvents]:byte(-3))&0xF0 ~= 0xB0
        then
            reaper.ShowMessageBox("No All-Notes-Off MIDI message was found at the end of the take."
                                  .. "\n\nThis may indicate a parsing error in script, or an error in the take."
                                  , "ERROR", 0)
            return false
        end            
        
        ----------------------------------------------------
        -- Fiinally, concatenate the table, and return true.
        -- When concatenating tables, leave out the first remaining event's offset (first 4 bytes), 
        --    since this offset will be updated relative to the edited events' positions during each cycle.
        -- (The edited events will be inserted in the string before all the remaining events.)
        AllNotesOffPPQpos = runningPPQpos -- Will be used to prevent events from being moved out of item range. 
        
        remainMIDIstring = table.concat(tableRemainingEvents):sub(5)
        remainOffset = s_unpack("i4", tableRemainingEvents[1])
        selectedMIDIstring = table.concat(tableExtractedEvents):sub(5)
        selectedMIDIPPQrange = selectedMIDIPPQrange - s_unpack("i4", tableExtractedEvents[1])
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
-- Undo_OnStateChange will only be used if reaper.atexit(exit) has been executed
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
elseif not(segment == "notes" or details == "cc_lane") then 
    reaper.ShowMessageBox("Mouse is not correctly positioned.\n\n"
                          .. "This selected events will follow the position of the mouse, "
                          .. "so the mouse should be positioned over either a CC lane or the notes area of an active MIDI editor.", "ERROR", 0)
    return(false) 
end

-----------------------------------------------------------------------------------------
-- We know that the mouse is positioned over a MIDI editor.  Check whether inline or not.
-- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI"
-- https://github.com/Jeff0S/sws/issues/783
-- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
_, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
if SWS283 ~= SWS283again then
    reaper.ShowMessageBox("Could not determine compatible SWS version.", "ERROR", 0)
    return(false)
end--

if SWS283 == true then
    isInline, _, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, isInline, _, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
end 
    
-------------------------------------------------        
-- Get active take (MIDI editor or inline editor)
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

---------------------------------------------------------------------------
-- OK, tests passed, and it seems like this script will do something, 
--    so toggle button (if any) and define atexit with its Undo statements,
--    before making any changes to the MIDI.
reaper.atexit(exit)

_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    prevToggleState = reaper.GetToggleCommandStateEx(sectionID, cmdID)
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

-------------------------------------------------------------------------------
-- MIDI_Sort is buggy when dealing with overlapping notes, 
--    causing infinitely extended notes or zero-length notes.
-- Therefore explicitly call action "Correct overlapping notes" before sorting.
--    (Note that this action only affects the active take in the editor.)
-- However, native actions that are called with OnCommand create their own undo points, 
--    unless they are within explicit undo blocks bookended by Undo_BeginBlock and Undo_EndBlock.
-- And there is yet another problem: exiting via an atexit-defined function such as this script's
--    "exit" function interrupts all undo blocks.  Therefore native actions should rather
--    note be called before entering the exit function.
-- This script will therefore NOT sort the MIDI, and will instead check for negative offsets
--    while parsing.  (This is in any case faster than unneccesary sorting.)
--reaper.MIDIEditor_OnCommand(editor, 40659) -- Correct overlapping notes
--reaper.MIDI_Sort(take)

------------------------------------------------------------------------------------------------
-- Get the starting PPQ (horizontal) position of the mouse.  Must check whether snap is enabled.
mouseOrigPPQpos = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5) -- Round to avoid fractional ticks
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
    local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mouseOrigPPQpos) -- Mouse position in quarter notes
    local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
    gridOrigPPQpos = math.floor(reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) + 0.5)
else 
    -- Otherwise, destination PPQ is exact mouse position
    gridOrigPPQpos = mouseOrigPPQpos
end   

---------------------------------------------------------------------------------------
-- Time to process the MIDI of the take!
-- As mentioned above, this script does not use the standard MIDI API functions such as 
--    MIDI_InsertCC, since these functions are far too slow when dealing with thousands 
--    of events.
if not parseAndExtractTargetMIDI() then
    return(false) -- parseAndExtractTargetMIDI will display its own error messages, so no need to do that here.
end


-------------------------------------------------------------
-- Finally, start running the loop!
loop_trackMouseMovement()

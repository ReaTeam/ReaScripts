--[[
 * ReaScript Name:  Fit all selected events to time selection
 * Description:  Move and stretch all selected events (notes, sysex, pitchwheel, CCs etc - not limited to
 *                    any CC lane) to fit precisely into time selection.
 *
 * Instructions:  The script can be linked to a shortcut key or a menu button, or it can be included in the 
 *                    CC lane context menu.
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
 * v1.0 (2016-06-11)
    + Initial Release
]]

-- USER AREA --------------------------
-- Settings that the user can customize

    verbose = true -- Should error messages be shown? "true" or "false"

-- End of USER AREA -------------------


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
-----------------------------


-----------------------------------------------------------------------------------------------------------
--[[function main() 
    -- Define variables as local to improve speed.
    -- However, this script is rather quick and simple, so probably not necessary.
    -- Keeping variables global makes debugging easier.
    local window, segment, editor, take, timeSelectStart, timeSelectEnd, 
          eventsStartPPQ, eventsEndPPQ, notesEndPPQ, stretchFactor
    ]]      
    
    -- Trick to prevent REAPER from automatically creating an undo point
    function avoidUndo()
    end
    reaper.defer(avoidUndo)
    
    -- Test whether user settings are usable
    if not (type(verbose) == "boolean")
        then reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'verbose' must be either 'true' of 'false'.\n") 
        return(false) 
    end
    
    -- The must be an active MIDI editor and take
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil 
        then showErrorMsg("No active MIDI editor found.") return(false) end
    take = reaper.MIDIEditor_GetTake(editor)
    if take == nil 
        then showErrorMsg("No active take found in MIDI editor.") return(false) end

    -- Is there a usable time selection?
    timeSelectStart, timeSelectEnd = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)  
    if type(timeSelectStart) ~= "number"
        or type(timeSelectEnd) ~= "number"
        or timeSelectEnd<=timeSelectStart 
        or reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectStart) < 0
        or reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectEnd) < 0
        then 
        showErrorMsg("A time range must be selected (within the active item's own time range).")
        return(false) 
    else 
        destStartPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectStart)
        destEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectEnd) -- May be changed later if rightmost event is not a note
    end  
    
    --------------------------------------------------------------------
    -- First, the script must find all selected events, so that the time range of these
    --    events can be determined.
    -- Then iterarate through all these events for a second time, this time
    --    moving them to their new positions.
    
    reaper.MIDI_Sort(take)
    
    tableSysex = {} -- All selected events in lane will be stored in arrays
    tableCCs = {}
    tableNotes = {}
    eventsStartPPQ = math.huge
    eventsEndPPQ = 0
    notesEndPPQ = 0
    
    -- Find all selected notes
    i = reaper.MIDI_EnumSelNotes(take, -1)
    while(i ~= -1) do
        _, _, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(take, i)
        table.insert(tableNotes, {index = i, startPPQ = startppqpos, endPPQ = endppqpos})
        if startppqpos < eventsStartPPQ then eventsStartPPQ = startppqpos end
        if endppqpos > notesEndPPQ then notesEndPPQ = endppqpos end 
        i = reaper.MIDI_EnumSelNotes(take, i)
    end
    
    -- sysex and text events
    i = reaper.MIDI_EnumSelTextSysexEvts(take, -1)
    while(i ~= -1) do
        _, _, _, ppqpos, _, msg = reaper.MIDI_GetTextSysexEvt(take, i)
        table.insert(tableSysex, {index = i, ppqpos = ppqpos, msg = msg})
        if ppqpos < eventsStartPPQ then eventsStartPPQ = ppqpos end
        if ppqpos > eventsEndPPQ then eventsEndPPQ = ppqpos end
        i = reaper.MIDI_EnumSelTextSysexEvts(take, i)
    end
        
    -- all other event types that are not sysex or text
    i = reaper.MIDI_EnumSelCC(take, -1)
    while(i ~= -1) do    
        _, _, _, ppqpos, _, _, _, _ = reaper.MIDI_GetCC(take, i) 
        table.insert(tableCCs, {index = i, ppqpos = ppqpos})
        if ppqpos < eventsStartPPQ then eventsStartPPQ = ppqpos end
        if ppqpos > eventsEndPPQ then eventsEndPPQ = ppqpos end
        i = reaper.MIDI_EnumSelCC(take, i)         
    end
    
    ------------------------------------------------------------------------------------------------
    -- If the rightmost selected event is a CC or sysex, not a note, the events must be stretched to 
    --     destEndPPQ - 1 to ensure that all events fall inside the time selection.
    -- (Events that fall on the exact PPQ of the time selection endpoint actually falls outside the
    --     time selection.)
    -- If the rightmost event is a note, the note end will fall exactly on destEndPPQ. 
    if eventsEndPPQ >= notesEndPPQ then destEndPPQ = destEndPPQ-1 end
    eventsEndPPQ = math.max(eventsEndPPQ, notesEndPPQ)                         
        
    if #tableNotes == 0 and #tableSysex == 0 and #tableCCs == 0 then
        return(0)
    elseif eventsEndPPQ < eventsStartPPQ then -- Probably no selected events
        showErrorMsg("Could not determine time range of selected events.")
        return(false)
    elseif eventsEndPPQ == eventsStartPPQ then
        stretchFactor = 1 -- Value doesn't really matter, as long as it is not infinite
    else 
        stretchFactor = (destEndPPQ - destStartPPQ) / (eventsEndPPQ - eventsStartPPQ)
    end 
        
    --------------------------------------------------------------------
    -- OK, tests done so things will start to happen.  Start undo block.
    reaper.Undo_BeginBlock()            
    
    --------------------------------------------
    -- Move and stretch events to time selection
    for i = 1, #tableNotes do
        reaper.MIDI_SetNote(take, tableNotes[i].index, nil, nil, destStartPPQ + stretchFactor*(tableNotes[i].startPPQ - eventsStartPPQ), destStartPPQ + stretchFactor*(tableNotes[i].endPPQ - eventsStartPPQ), nil, nil, nil, true)
    end
    
    for i = 1, #tableCCs do
        reaper.MIDI_SetCC(take, tableCCs[i].index, nil, nil, destStartPPQ + stretchFactor*(tableCCs[i].ppqpos - eventsStartPPQ), nil, nil, nil, nil, true)    
    end
    
    for i = 1, #tableSysex do
        reaper.MIDI_SetTextSysexEvt(take, tableSysex[i].index, nil, nil, destStartPPQ + stretchFactor*(tableSysex[i].ppqpos - eventsStartPPQ), nil, tableSysex[i].msg, true)    
    end

    -------------------
    -- End and clean-up
    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock("Fit all selected events to time selection", -1)

--end -- end main()

-----------------
-- Run the script
--main()
      

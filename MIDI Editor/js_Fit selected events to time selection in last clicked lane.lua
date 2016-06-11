--[[
 * ReaScript Name:  Fit selected events in last clicked lane to time selection
 * Description:  Move and stretch selected events (notes, CCs, pitchwheel, sysex, etc) to fit precisely into time selection.
 *               The script only affects events in the MIDI editor lane that has been clicked last.
 * Instructions:  The script can be linked to a shortcut key or a menu button, or it can be included in the 
 *                    CC lane context menu.
 *                In the script's USER AREA (below the Changelog), the user can customize the following settings:
 *                    - lane_to_use: "last clicked" or "under mouse"
 *                    - move_rightmost_event_to: "next-to-last PPQ", "closest CC grid", "exact PPQ"
 *                    - verbose: "true" or "false" to show error messages when, for example, there are no selected events.
 *
 *                In the case of notes, the rightmost note's "note off" event will be moved to the exact time point 
 *                    of the end of the time selection.  In the case of other events however, moving the rightmost 
 *                    event to the exact endpoint will mean that event actually falls outside the time selection.  The 
 *                    script therefore offers three alternatives: 
 *                    - "exact PPQ": move the rightmost event to the exact PPQ of the time selection endpoint, which 
 *                                   means that the event will fall outside the time selection.
 *                    - "next-to-last PPQ": move the rightmost event to the very last PPQ *inside* the time selection.
 *                    - "closest CC grid": move the rightmost event to the closest PPQ inside the time selection 
 *                                         that falls on the grid set in REAPER's
 *                                         Preferences -> MIDI editor -> Events per quarter note when drawing in CC lanes.
 *
 *                Note that the "Stretch events" script can be used to further tweak the positions of the events.
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
    
    move_rightmost_event_to = "next-to-last PPQ" -- "closest CC grid", "exact PPQ" or "next-to-last PPQ"
    lane_to_use = "last clicked" -- "last clicked" or "under mouse"
    verbose = true -- "true" or "false"

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
    local window, segment, editor, take, details, targetLane, QNperGrid, mouseQNpos, 
          events, count, eventIndex, eventPPQpos, msg, msg1, msg2, eventType,
          tempFirstPPQ, tempLastPPQ, firstPPQpos, lastPPQpos, density,
          timeSelectStart, timeSelectEnd, destEndPPQ, destStartPPQ,
          eventsStartPPQ, eventsEndPPQ
    ]]      
    
    -- Trick to prevent REAPER from automatically creating an undo point
    function avoidUndo()
    end
    reaper.defer(avoidUndo)
    
    -- Test whether user settings are usable
    if not (type(verbose) == "boolean")
        then reaper.ShowConsoleMsg("\n\nERROR: \nThe setting 'verbose' must be either 'true' of 'false'.\n") return(false) end
    if not (lane_to_use == "last clicked" or lane_to_use == "under mouse")  
        then reaper.ShowConsoleMsg('\n\nERROR: \nThe setting "lane_to_use" must be either "last clicked" or "under mouse".\n') return(false) end
    if not (move_rightmost_event_to == "closest CC grid" or move_rightmost_event_to == "exact PPQ" or move_rightmost_event_to == "next-to-last PPQ")  
        then reaper.ShowConsoleMsg('\n\nERROR: \nThe setting "move_rightmost_event_to" must be either "closest CC grid", "exact PPQ" or "next-to-last PPQ".\n') return(false) end
    
    -- Mouse must be positioned in MIDI editor
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
        destEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectEnd) -- May be changed later by "move_rightmost_event_to" setting
    end
            
    -- Get target lane 
    if lane_to_use == "under mouse" then
    
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if lane_to_use == "under mouse" and not (details == "cc_lane" or details == "cc_selector" or segment == "notes") 
            then showErrorMsg('If lane_to_use == "under mouse", the mouse must be positioned over a CC lane or over the piano roll of an active MIDI editor.') return(false) 
        end
        
        if details == "cc_lane" or details == "cc_selector" then 
            -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI()"
            -- https://github.com/Jeff0S/sws/issues/783
            -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
            _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
            if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
            if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
            if SWS283 ~= SWS283again then
                reaper.ShowConsoleMsg("\n\nERROR:\nCould not determine compatible SWS version.\n\n")
                return(false)
            end
            
            if SWS283 == true then
                _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
            else 
                _, _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
            end
        end
        
    else -- lane_to_use == "last clicked"
        targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane") 
    end

    -- Assume that if target CC lane could not be determined, the intended target is notes 
    -- Alternatively:    
    --  then showErrorMsg("The target lane could not be determined.") return(false) end 
    if type(targetLane) ~= "number" or targetLane < 0 or targetLane > 0x207 then 
        targetLane = -1 
        segment = "notes" 
    end  
           
    
    --------------------------------------------------------------------
    -- Find selected events in target lane.
    -- sysex and text events are weird, so use different "Get" function
    --
    -- targetLane = "CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 
    -- 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 
    -- 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity)"
    --
    -- eventType is the MIDI event type: 11=CC, 14=pitchbend, etc
    
    reaper.MIDI_Sort(take)
    
    events = {} -- All selected events in lane will be stored in an array
    eventsStartPPQ = math.huge
    eventsEndPPQ = 0
    
    -- Note events can actually be found using MIDI_GetEvt, but this script will use MIDI_GetNote in case
    --    the latter is more reliable
    if segment == "notes" or targetLane == 0x200 or targetLane == 0x207 then -- Velocity, off-velocity, or piano roll
    
        noteIndex = reaper.MIDI_EnumSelNotes(take, -1)
        while(noteIndex ~= -1) do
            
            _, _, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(take, noteIndex)
            table.insert(events, {index = noteIndex,
                                  PPQstart = startppqpos,
                                  PPQend = endppqpos})
            if startppqpos < eventsStartPPQ then eventsStartPPQ = startppqpos end
            if endppqpos > eventsEndPPQ then eventsEndPPQ = endppqpos end     
            
            noteIndex = reaper.MIDI_EnumSelNotes(take, noteIndex)
        end
    
    elseif targetLane == 0x206 or targetLane == 0x205 then -- sysex and text events
        
        eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, -1)
        while(eventIndex ~= -1) do
            _, _, _, eventPPQpos, eventType, msg = reaper.MIDI_GetTextSysexEvt(take, eventIndex)
            if (targetLane == 0x206 and eventType == -1) -- only sysex
            or (targetLane == 0x205 and eventType ~= -1) -- only text events
                then
                table.insert(events, {index = eventIndex,
                                      PPQ = eventPPQpos,
                                      msg = msg,
                                      type = 0xF})
                if eventPPQpos < eventsStartPPQ then eventsStartPPQ = eventPPQpos end
                if eventPPQpos > eventsEndPPQ then eventsEndPPQ = eventPPQpos end
            end
            eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, eventIndex)
        end
        
    else  -- all other event types that are not sysex or text
    
        eventIndex = reaper.MIDI_EnumSelEvts(take, -1)
        while(eventIndex ~= -1) do
        
            _, _, _, eventPPQpos, msg = reaper.MIDI_GetEvt(take, eventIndex, true, true, 0, "")
            msg1=tonumber(string.byte(msg:sub(1,1)))
            msg2=tonumber(string.byte(msg:sub(2,2)))
            eventType = msg1>>4 -- eventType is CC (11), pitch (14), etc...
    
            -- Now, select only event types that correspond to targetLane:
            if (0 <= targetLane and targetLane <= 127 -- CC, 7 bit (single lane)
                and msg2 == targetLane and eventType == 11)
            or (256 <= targetLane and targetLane <= 287 -- CC, 14 bit (double lane)
                and (msg2 == targetLane-256 or msg2 == targetLane-224) and eventType ==11) -- event can be from either MSB or LSB lane
            --or ((targetLane == 0x200 or targetLane == 0x207) -- Velocity or off-velocity
            --    and (eventType == 9 or eventType == 8)) -- note on or note off
            or (targetLane == 0x201 and eventType == 14) -- pitch
            or (targetLane == 0x202 and eventType == 12) -- program select
            or (targetLane == 0x203 and eventType == 13) -- channel pressure (after-touch)
            or (targetLane == 0x204 and eventType == 12) -- Bank/Program select - Program select
            or (targetLane == 0x204 and eventType == 11 and msg2 == 0) -- Bank/Program select - Bank select MSB
            or (targetLane == 0x204 and eventType == 11 and msg2 == 32) -- Bank/Program select - Bank select LSB
            then
                table.insert(events, {index = eventIndex,
                                      PPQ = eventPPQpos,
                                      --QN = reaper.MIDI_GetProjQNFromPPQPos(take, eventPPQpos),
                                      msg = msg,
                                      type = eventType})
                if eventPPQpos < eventsStartPPQ then eventsStartPPQ = eventPPQpos end
                if eventPPQpos > eventsEndPPQ then eventsEndPPQ = eventPPQpos end
            end
            eventIndex = reaper.MIDI_EnumSelEvts(take, eventIndex)
        end
    end        
    
    --------------------------------------------------------------------------------------------------------
    -- If move_rightmost_event_to == "closest CC grid", we must go through several steps to find the closest 
    --     grid position immediately before (to the left of) the time selection endpoint.
    if not (segment == "notes" or targetLane == 0x200 or targetLane == 0x207) -- NOT velocity or off-velocity
        and move_rightmost_event_to == "closest CC grid"
        then
        density = math.abs(reaper.SNM_GetIntConfigVar("midiCCdensity", 64)) -- Get the default grid resolution as set in Preferences -> MIDI editor -> "Events per quarter note when drawing in CC lanes"
        --density = math.floor(math.max(4, math.min(128, math.abs(density))))
        destEndPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, math.floor(density*reaper.MIDI_GetProjQNFromPPQPos(take, destEndPPQ-1))/density)
    elseif not (segment == "notes" or targetLane == 0x200 or targetLane == 0x207) -- NOT velocity or off-velocity
        and move_rightmost_event_to == "next-to-last PPQ"
        then
        destEndPPQ = destEndPPQ-1
    end                          
    
    if destEndPPQ <= destStartPPQ then
        reaper.showErrorMsg("Time selection is too short.")
        return(false)
    end  
    
    -----------------------------------------------------------------------------------
    -- Do the selected events have a usable time range?  Then can define stretch factor
    if (#events == 0) then 
        showErrorMsg("No selected events found in target lane.")
        return(false) 
    end
    
    if eventsEndPPQ < eventsStartPPQ then
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
    if targetLane == 0x205 or targetLane == 0x206 then
        for i = 1, #events do
            reaper.MIDI_SetTextSysexEvt(take, events[i].index, nil, nil, destStartPPQ + stretchFactor*(events[i].PPQ-eventsStartPPQ), nil, events[i].msg, true)
        end
    elseif targetLane == 0x200 or targetLane == 0x207 or segment == "notes" then
        for i = 1, #events do
            reaper.MIDI_SetNote(take, events[i].index, nil, nil, destStartPPQ + stretchFactor*(events[i].PPQstart-eventsStartPPQ), destStartPPQ + stretchFactor*(events[i].PPQend-eventsStartPPQ), nil, nil, nil, true)
        end
    else
        for i = 1, #events do
            reaper.MIDI_SetEvt(take, events[i].index, nil, nil, destStartPPQ + stretchFactor*(events[i].PPQ-eventsStartPPQ), events[i].msg, true)
        end
    end

    reaper.MIDI_Sort(take)

    -- End and clean-up
    if segment == "notes" or targetLane == 0x200 or targetLane == 0x207 then -- Velocity or off-velocity
        undoString = "Fit events to time selection: Notes"
    elseif type(targetLane) ~= "number" then 
        undoString = "Fit events to time selection"
    elseif targetLane == 0x206 then
        undoString = "Fit events to time selection: Sysex"
    elseif targetLane == 0x205 then
        undoString = "Fit events to time selection: Text events"
    elseif 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
        undoString = "Fit events to time selection: 7 bit CC, lane ".. tostring(targetLane)
    elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
        undoString = "Fit events to time selection: 14 bit CC, lanes ".. tostring(targetLane-256) .. "/" .. tostring(targetLane-224)
    elseif targetLane == 0x201 then -- pitch
        undoString = "Fit events to time selection: Pitchwheel"
    elseif targetLane == 0x202 then -- program select
        undoString = "Fit events to time selection: Program Select"
    elseif targetLane == 0x203 then -- channel pressure (after-touch)
        undoString = "Fit events to time selection: Channel Pressure"
    elseif targetLane == 0x204 then -- Bank/Program select - Program select
        undoString = "Fit events to time selection: Bank/Program Select"
    else              
        undoString = "Fit events to time selection"
    end -- if targetLane ==
    
    reaper.Undo_EndBlock(undoString, -1)

--end -- end main()

-----------------
-- Run the script
--main()
      

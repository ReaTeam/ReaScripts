--[[
 * ReaScript Name:  Set time selection to selected events in last clicked lane
 * Description:  Set time selection to selected events in last clicked lane.
 * Instructions:   The script can be linked to a shortcut key or a menu button, or it can be included in the 
 *                    CC lane context menu.
 *                In the script's USER AREA (below the Changelog), the user can customize the following settings:
 *                    - lane_to_use: "last clicked" or "under mouse".
 *                    - set_time_end_to: "exact PPQ" or "next PPQ".
 *                    - verbose: "true" or "false" to show error messages when, for example, there are no selected events.
 *                In the case of notes, the endpoint of the time selection will be set to the exact PPQ of the rightmost 
 *                    note's "note off". 
 *                In the case of other events however, moving the time selection endpoint to the exact PPQ of the 
 *                    rightmost event will mean that that event actually falls outside the time selection.  The 
 *                    script therefore offers two alternatives: 
 *                    - "exact PPQ": move the time selection endpoint to the exact PPQ of the rightmost event, which 
 *                                   means that the event will fall outside the time selection.
 *                    - "next PPQ": move the time selection endpoint to the last event's PPQ + 1.  This gives the tightest 
 *                                  positioning of the time selection around the events.
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
    
    set_time_end_to = "next PPQ" -- "exact PPQ" or "next PPQ"
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
    if not (set_time_end_to == "exact PPQ" or set_time_end_to == "next PPQ")  
        then reaper.ShowConsoleMsg('\n\nERROR: \nThe setting "set_time_end_to" must be either "exact PPQ" or "next PPQ"\n') return(false) end
    
    -- Mouse must be positioned in MIDI editor
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil 
        then showErrorMsg("No active MIDI editor found.") return(false) end
    take = reaper.MIDIEditor_GetTake(editor)
    if take == nil 
        then showErrorMsg("No active take found in MIDI editor.") return(false) end
            
    -- Get target lane 
    if lane_to_use == "under mouse" then
    
        window, segment, details = reaper.BR_GetMouseCursorContext()
        if not (details == "cc_lane" or details == "cc_selector" or segment == "notes") 
            then showErrorMsg('If lane_to_use == "under mouse", the mouse must be positioned over a CC lane or over the piano roll of an active MIDI editor.') 
            return(false) 
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
    
    -- reaper.MIDI_Sort(take)
    
    -- events = {} -- All selected events in lane will be stored in an array
    eventsStartPPQ = math.huge
    eventsEndPPQ = 0
    countEvents = 0
    
    -- Note events can actually be found using MIDI_GetEvt, but this script will use MIDI_GetNote in case
    --    the latter is more reliable
    if segment == "notes" or targetLane == 0x200 or targetLane == 0x207 then -- Velocity, off-velocity, or piano roll
    
        noteIndex = reaper.MIDI_EnumSelNotes(take, -1)
        while(noteIndex ~= -1) do
            
            _, _, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(take, noteIndex)
            --[[table.insert(events, {index = noteIndex,
                                  PPQstart = startppqpos,
                                  PPQend = endppqpos})
            ]]
            if startppqpos < eventsStartPPQ then eventsStartPPQ = startppqpos end
            if endppqpos > eventsEndPPQ then eventsEndPPQ = endppqpos end  
            countEvents = countEvents + 1   
            
            noteIndex = reaper.MIDI_EnumSelNotes(take, noteIndex)
        end
    
    elseif targetLane == 0x206 or targetLane == 0x205 then -- sysex and text events
        
        eventIndex = reaper.MIDI_EnumSelTextSysexEvts(take, -1)
        while(eventIndex ~= -1) do
            _, _, _, eventPPQpos, eventType, msg = reaper.MIDI_GetTextSysexEvt(take, eventIndex)
            if (targetLane == 0x206 and eventType == -1) -- only sysex
            or (targetLane == 0x205 and eventType ~= -1) -- only text events
                then
                --[[table.insert(events, {index = eventIndex,
                                      PPQ = eventPPQpos,
                                      msg = msg,
                                      type = 0xF})
                ]]
                if eventPPQpos < eventsStartPPQ then eventsStartPPQ = eventPPQpos end
                if eventPPQpos > eventsEndPPQ then eventsEndPPQ = eventPPQpos end
                countEvents = countEvents + 1  
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
                --[[table.insert(events, {index = eventIndex,
                                      PPQ = eventPPQpos,
                                      --QN = reaper.MIDI_GetProjQNFromPPQPos(take, eventPPQpos),
                                      msg = msg,
                                      type = eventType})
                ]]
                if eventPPQpos < eventsStartPPQ then eventsStartPPQ = eventPPQpos end
                if eventPPQpos > eventsEndPPQ then eventsEndPPQ = eventPPQpos end
                countEvents = countEvents + 1  
            end
            eventIndex = reaper.MIDI_EnumSelEvts(take, eventIndex)
        end
    end        
    
    if countEvents == 0 then
        if segment == "notes" or targetLane == 0x200 or targetLane == 0x207 then -- Velocity or off-velocity
            showErrorMsg("No selected events found in target lane: Notes.")
        elseif type(targetLane) ~= "number" then 
            showErrorMsg("No selected events found in target lane.")
        elseif targetLane == 0x206 then
            showErrorMsg("No selected events found in target lane: Sysex.")
        elseif targetLane == 0x205 then
            showErrorMsg("No selected events found in target lane: Text events.")
        elseif 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
            showErrorMsg("No selected events found in target lane: 7 bit CC, lane ".. tostring(targetLane) ..".")
        elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
            showErrorMsg("No selected events found in target lane: 14 bit CC, lanes ".. tostring(targetLane-256) .. "/" .. tostring(targetLane-224) ..".")
        elseif targetLane == 0x201 then -- pitch
            showErrorMsg("No selected events found in target lane: Pitchwheel.")
        elseif targetLane == 0x202 then -- program select
            showErrorMsg("No selected events found in target lane: Program Select.")
        elseif targetLane == 0x203 then -- channel pressure (after-touch)
            showErrorMsg("No selected events found in target lane: Channel Pressure.")
        elseif targetLane == 0x204 then -- Bank/Program select - Program select
            showErrorMsg("No selected events found in target lane: Bank/Program Select.")
        else
            showErrorMsg("No selected events found in target lane")
        end
        return(false) 
    end
    
    --------------------------------------------------------------------------------------------
    -- If set_time_end_to == "next PPQ" and target events are NOT notes, add one PPQ to endpoint 
    --     grid position immediately before (to the left of) the time selection endpoint.
    if not (segment == "notes" or targetLane == 0x200 or targetLane == 0x207) -- NOT velocity or off-velocity
        and set_time_end_to == "next PPQ"
        then
        eventsEndPPQ = eventsEndPPQ + 1
    end                          
                
    --------------------------------------------------------------------
    -- OK, tests done so things will start to happen.  Start undo block.
    reaper.Undo_BeginBlock()            
    
    local timeSelStart = reaper.MIDI_GetProjTimeFromPPQPos(take, eventsStartPPQ)
    local timeSelEnd = reaper.MIDI_GetProjTimeFromPPQPos(take, eventsEndPPQ)
    
    reaper.GetSet_LoopTimeRange2(0, true, false, timeSelStart, timeSelEnd, true)

    -- End and clean-up
    if segment == "notes" or targetLane == 0x200 or targetLane == 0x207 then -- Velocity or off-velocity
        undoString = "Set time selection to selected events: Notes"
    elseif type(targetLane) ~= "number" then 
        undoString = "Set time selection to selected events"
    elseif targetLane == 0x206 then
        undoString = "Set time selection to selected events: Sysex"
    elseif targetLane == 0x205 then
        undoString = "Set time selection to selected events: Text events"
    elseif 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
        undoString = "Set time selection to selected events: 7 bit CC, lane ".. tostring(targetLane)
    elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
        undoString = "Set time selection to selected events: 14 bit CC, lanes ".. tostring(targetLane-256) .. "/" .. tostring(targetLane-224)
    elseif targetLane == 0x201 then -- pitch
        undoString = "Set time selection to selected events: Pitchwheel"
    elseif targetLane == 0x202 then -- program select
        undoString = "Set time selection to selected events: Program Select"
    elseif targetLane == 0x203 then -- channel pressure (after-touch)
        undoString = "Set time selection to selected events: Channel Pressure"
    elseif targetLane == 0x204 then -- Bank/Program select - Program select
        undoString = "Set time selection to selected events: Bank/Program Select"
    else              
        undoString = "Set time selection to selected events"
    end -- if targetLane ==
    
    reaper.Undo_EndBlock(undoString, -1)

--end -- end main()

-----------------
-- Run the script
--main()
      

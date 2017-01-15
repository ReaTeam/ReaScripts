--[[
ReaScript name:  js_Fit all selected events to time selection in last clicked lane.lua
Version: 2.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
REAPER version: 5.32 or later
Donation: https://www.paypal.me/juliansader
About:
  # Description
  
  Move and stretch selected events in the last clicked lane (notes, sysex, pitchwheel, CCs etc) to fit precisely into time selection.
  
  # Instructions
  
  The script can be linked to a shortcut key or toolbar button, or it can be included in the CC lane context menu.
]]

--[[
 Changelog:
  * v1.0 (2016-06-11)
    + Initial Release
  * v2.00 (2017-01-10)
    + Much faster execution when working in large tracks with hundreds of thousands of MIDI events.
    + Script will work in looped takes.
    + Requires REAPER v5.32 or later.
]]


-- USER AREA --------------------------
-- Settings that the user can customize
    
    lane_to_use = "last clicked" -- "all", "last clicked" or "under mouse"

-- End of USER AREA -------------------


-----------------------------------------------------------------------------------------------------------
--[[function main() 
    -- Define variables as local to improve speed.
    -- However, this script is rather quick and simple, so probably not necessary.
    -- Keeping variables global makes debugging easier.
    
    local window, segment, editor, take, timeSelectStart, timeSelectEnd, 
          eventsStartPPQ, eventsEndPPQ, notesEndPPQ, stretchFactor    
    ]]
    -- Simply calling the defer function is a 'trick' to prevent REAPER from automatically creating an undo point
    function avoidUndo()
    end
    reaper.defer(avoidUndo)
    
    --------------------------------------------------------
    -- Check whether required version of REAPER is available
    version = tonumber(reaper.GetAppVersion():match("(%d+%.%d+)"))
    if version == nil or version < 5.32 then
        reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                              .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                              , "ERROR", 0)
        return(false) 
    end

    
    ------------------------------------
    -- Find editor, active take and item
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil 
        then reaper.ShowMessageBox("No active MIDI editor found.", "ERROR", 0) 
        return(false) 
    end
    take = reaper.MIDIEditor_GetTake(editor)
    if take == nil 
        then reaper.ShowMessageBox("No active take found in MIDI editor.", "ERROR", 0) 
        return(false) 
    end
    item = reaper.GetMediaItemTake_Item(take)
    if not reaper.ValidatePtr(item, "MediaItem*") then 
        reaper.ShowMessageBox("Could not determine the item to which the active take belongs.", "ERROR", 0)
        return(false)
    end
    
    
    -------------------------------
    -- Determine the target lane(s)
    if lane_to_use == "all" then
        laneIsALL = true    
    else
        if lane_to_use == "under mouse" then
        
            if not reaper.APIExists("BR_GetMouseCursorContext") then
                reaper.ShowMessageBox('To use the "under mouse" option, this script requires the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.', "ERROR", 0)
                return(false) 
            end
            
            window, segment, details = reaper.BR_GetMouseCursorContext()
            if not (segment == "notes" or details == "cc_lane") then
                reaper.ShowMessageBox('Mouse is not correctly positioned.\n\nIf the "lane_to_use" parameter is set to "under mouse", the mouse must be positioned over either a CC lane or the notes area of a MIDI editor', "ERROR", 0)
                return(false) 
            end
            -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI()"
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
                _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
            else 
                _, _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
            end        
                    
        elseif lane_to_use == "last clicked" then
            targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane") 
            if targetLane == -1 then
                reaper.ShowMessageBox('Could not determine the last clicked CC lane', "ERROR", 0)
                return(false) 
            end
            
        else
            reaper.ShowMessageBox('The setting "lane_to_use" must be either "all", "last clicked" or "under mouse".', "ERROR", 0) 
            return(false)
        end
        
        -- Change targetLane into a more readable format
        if segment == "notes" then
            laneIsPIANOROLL, laneIsNOTES = true, true
        elseif 0 <= targetLane and targetLane <= 127 then -- CC, 7 bit (single lane)
            laneIsCC7BIT = true
        elseif targetLane == 0x200 then
            laneIsVELOCITY, laneIsNOTES = true, true   
        elseif targetLane == 0x201 then
            laneIsPITCH = true
        elseif targetLane == 0x202 then
            laneIsPROGRAM = true
        elseif targetLane == 0x203 then
            laneIsCHPRESS = true
        elseif targetLane == 0x204 then
            laneIsBANKPROG = true
        elseif 256 <= targetLane and targetLane <= 287 then -- CC, 14 bit (double lane)
            laneIsCC14BIT = true
        elseif targetLane == 0x205 then
            laneIsTEXT = true
        elseif targetLane == 0x206 then
            laneIsSYSEX = true
        elseif targetLane == 0x207 then
            laneIsOFFVEL, laneIsNOTES = true, true
        else -- not a lane type in which script can be used.
            reaper.ShowMessageBox('In the "This script will work in the following MIDI lanes: \n* 7-bit CC, \n* 14-bit CC, \n* Velocity, \n* Channel Pressure, \n* Pitch, \n* Program select,\n* Bank/Program,\n* Text or Sysex,\n* or in the "notes area" of the piano roll.', "ERROR", 0)
            return(0)
        end        
    end
    
    
    ------------------------------------------------------------------------------
    -- The source length will be saved and checked again at the end of the script, 
    --    to check that no inadvertent shifts in PPQ position happened.
    sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)


    ------------------------------------
    -- Is there a usable time selection?
    timeSelectStart, timeSelectEnd = reaper.GetSet_LoopTimeRange(false, false, 0.0, 0.0, false)  
    if type(timeSelectStart) ~= "number"
        or type(timeSelectEnd) ~= "number"
        or timeSelectEnd<=timeSelectStart 
        then 
        reaper.ShowMessageBox("A time range must be selected (within the active item's own time range).", "ERROR", 0)
        return(false) 
    end
    -- Find PPQ positions of time selection and calculate corrected values (relative to first iteration) if take is looped
    destPPQstart_Uncorrected = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectStart)
    destPPQend_Uncorrected = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelectEnd) -- May be changed later if rightmost event is not a note
    PPQofLoopStart = (destPPQstart_Uncorrected//sourceLengthTicks)*sourceLengthTicks
    if not (PPQofLoopStart == ((destPPQend_Uncorrected-1)//sourceLengthTicks)*sourceLengthTicks) then
        reaper.ShowMessageBox("The selected time range fall within a single loop iteration.", "ERROR", 0)
        return(false) 
    end
    local destPPQstart = math.ceil(destPPQstart_Uncorrected - PPQofLoopStart)
    destPPQend_Unrounded = destPPQend_Uncorrected - PPQofLoopStart -- destPPQend will be rounded later
    
    
    --------------------------------------------------------------------------------------------
    -- Now, find all targeted selected events, extract their info and determine their PPQ range.    
    reaper.MIDI_Sort(take)
    
    local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    
    -- The info of selected events will be stored in these tables until theu are re-assembled at their new positions
    local tableMsg = {}
    local tablePPQs = {}
    local tableFlags = {}
    
    -- The remaining events and the newly assembled events will be stored in these table
    local tableRemainingEvents = {}
    
    -- The moved events will be re-assembled in this table
    local tableMovedEvents = {}
    
    -- Indices inside tables
    local r = 0
    local t = 0
    
    local MIDIlen = MIDIstring:len()
    local stringPos = 1
    local runningPPQpos = 0    
    local lastNoteOffPPQpos = -math.huge
    
    while stringPos < MIDIlen do
    
        local mustExtract = false
        local offset, flags, msg
        offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
        runningPPQpos = runningPPQpos + offset
        
        -- Find selected events in the target lane(s)
        if flags&1 == 1 then
            if laneIsALL then
                mustExtract = true
            elseif msg:len() > 1 then
                if laneIsCC7BIT       then if msg:byte(1)>>4 == 11 and msg:byte(2) == targetLane then mustExtract = true end
                elseif laneIsPITCH    then if msg:byte(1)>>4 == 14 then mustExtract = true end
                elseif laneIsCC14BIT  then if msg:byte(1)>>4 == 11 and (msg:byte(2) == targetLane-224 or msg:byte(2) == targetLane-256) then mustExtract = true end
                elseif laneIsNOTES    then if msg:byte(1)>>4 == 8 or msg:byte(1)>>4 == 9 then mustExtract = true end
                elseif laneIsPROGRAM  then if msg:byte(1)>>4 == 12 then mustExtract = true end
                elseif laneIsCHPRESS  then if msg:byte(1)>>4 == 13 then mustExtract = true end
                elseif laneIsBANKPROG then if msg:byte(1)>>4 == 12 or (msg:byte(1)>>4 == 11 and (msg:byte(2) == 0 or msg:byte(2) == 32)) then mustExtract = true end
                elseif laneIsTEXT     then if msg:byte(1)    == 0xFF and not (msg2 == 0x0F) then mustExtract = true end
                elseif laneIsSYSEX    then if msg:byte(1)>>4 == 0xF and not (msg:byte(1) == 0xFF) then mustExtract = true end
                end
            end            
        end
        
        -- Notation events are unfortunately not selected, even if the matching note-on is selected
        if (laneIsALL or laneIsNOTES)
        and msg:byte(1) == 0xFF -- MIDI text event
        and msg:byte(2) == 0x0F -- REAPER's notation event type
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
                            mustExtract = true
                            goto completedNotationSearch
                        end
                    end
                end
                -- Search forward through following events, looking for a selected note that match the channel and pitch
                -- (Probably not necessary in v5.32 or later, but just in case...)
                local evPos = nextPos -- Start search at position of nmext event in MIDI string
                local evOffset, evFlags, evMsg
                repeat -- repeat until an offset is found > 0
                    evOffset, evFlags, evMsg, evPos = string.unpack("i4Bs4", MIDIstring, evPos)
                    if evOffset == 0 then 
                        if evFlags&1 == 1 -- Only match *selected* events
                        and evMsg:byte(1) == 0x90 | notationChannel -- Match note-ons and channel
                        and evMsg:byte(2) == notationPitch -- Match pitch
                        and evMsg:byte(3) ~= 0 -- Note-ons with velocity == 0 are actually note-offs
                        then
                            mustExtract = true
                            goto completedNotationSearch
                        end
                    end
                until evOffset ~= 0
                ::completedNotationSearch::
            end   
        end 
        
        if mustExtract then
            -- Store this event's info
            t = t + 1
            tableMsg[t] = msg
            tablePPQs[t] = runningPPQpos
            tableFlags[t] = flags
            -- Replace with empty event (which simply changes offset)
            r = r + 1
            tableRemainingEvents[r] = string.pack("i4Bs4", offset, flags, "")
        else
            r = r + 1
            tableRemainingEvents[r] = string.pack("i4Bs4", offset, flags, msg)
        end
        
    end
    
    
    -----------------------
    -- Determine PPQ ranges
    if #tablePPQs == 0 then return end
    
    local eventsPPQstart = tablePPQs[1]
    local eventsPPQrange = tablePPQs[#tablePPQs] - eventsPPQstart
    
    
    ------------------------------------------------------------------------------------------------
    -- If the rightmost selected event is a CC or sysex, not a note, the events must be stretched to 
    --     destPPQend - 1 to ensure that all events fall inside the time selection.
    -- (Events that fall on the exact PPQ of the time selection endpoint actually falls outside the
    --     time selection.)
    -- If the rightmost event is a note, the note end will fall exactly on destPPQend. 
    -- Take into account however, that the time selection does not necessarily fall exactly on a PPQ position.
    for i = #tablePPQs, 1, -1 do
        if tablePPQs[i] < tablePPQs[#tablePPQs] then 
            break
        elseif not (tableMsg[i]:len() == 3 and (tableMsg[i]:byte(1)>>4 == 8 or (tableMsg[i]:byte(1) == 9 and tableMsg[i]:byte(3) == 0))) then
            selectedEventsEndIncludesSomethingElseThanNoteOff = true
        end
    end
    if selectedEventsEndIncludesSomethingElseThanNoteOff then destPPQend = math.ceil(destPPQend_Unrounded-1) else destPPQend = math.floor(destPPQend_Unrounded) end
    
    
    -----------------------------------------------------------------------
    -- Calculate the factor by which the event positions will be stretched.
    local stretchFactor
    if eventsPPQrange == 0 then
        stretchFactor = 1 -- Value doesn't really matter, as long as it is not infinite
    else 
        stretchFactor = (destPPQend - destPPQstart) / eventsPPQrange 
    end 
    
    
    -----------------------------------------------------------------------         
    -- Re-assemble the selected events into a table with their new offsets.
    local lastPPQpos = 0
    for i = 1, #tablePPQs do
        local newPPQpos = math.floor(destPPQstart + (tablePPQs[i]-eventsPPQstart)*stretchFactor + 0.5)
        tableMovedEvents[i] = string.pack("i4Bs4", newPPQpos-lastPPQpos, tableFlags[i], tableMsg[i])
        lastPPQpos = newPPQpos
    end
    
    
    ----------------------------------------------------------------------------------------------
    -- Upload everything into the take, using an empty event to "reset" offset between the tables.
    reaper.MIDI_SetAllEvts(take, table.concat(tableMovedEvents)
                                 .. string.pack("i4Bs4", -lastPPQpos, 0, "")
                                 .. table.concat(tableRemainingEvents))
    
    reaper.MIDI_Sort(take)
    
    
    ---------------------------------------------------------------------------------------
    -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
    if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(take)) then
        reaper.MIDI_SetAllEvts(take, MIDIstring) -- Restore original MIDI
        reaper.ShowMessageBox("The script has detected inadvertent shifts in the PPQ positions of unedited events."
                              .. "\n\nThis may be due to a bug in the script, or in the MIDI API functions."
                              .. "\n\nPlease report the bug in the following forum thread:"
                              .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                              .. "\n\nThe original MIDI data will be restored to the take.", "ERROR", 0)
    end


    -------------------
    -- End and clean-up
    reaper.Undo_OnStateChange_Item(0, "Fit all selected events to time selection in lane under mouse", item)

--end -- end main()

-----------------
-- Run the script
--main()
      

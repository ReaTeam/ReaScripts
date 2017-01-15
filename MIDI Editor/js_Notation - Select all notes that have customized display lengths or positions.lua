--[[
Reascript name: js_Notation - Select all notes that have customized display lengths or positions.lua
Version: 2.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
REAPER version: 5.30
Donation: https://www.paypal.me/juliansader
About:
  # Description
  Selects all notes IN ALL TRACKS that have customized notation display lengths or positions.
  
  If only notes in the active take need to be selected, a faster version of this script is
  "js_Notation - Select all notes (in active take) that have customized display lengths or positions.lua"
]]

--[[
Changelog:
  * v1.0 (2016-08-15)
    + Initial beta release
  * v2.00 (2016-12-12)
    + Faster execution, using REAPER v5.30's new API functions.
  * v2.10 (2017-01-09)
    + Updated for REAPER v5.32's new notation specifications
]]

-----------------------------------------------------------------
--function main() 

------------------------------------------------------------
-- Check whether the required version of REAPER is available
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This version of the script requires REAPER v5.30 or higher."
                          .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                          , "ERROR", 0)
    return(false) 
end

reaper.Undo_BeginBlock2(0)

local s_unpack = string.unpack
local s_pack   = string.pack

----------------------------------------------------------------------
-- First, iterate through all items and takes in the entire project
--    and deselect all MIDI event in all take *except* the active take    
numItems = reaper.CountMediaItems(0)
for i=0, numItems-1 do 

    curItem = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, curItem, "MediaItem*") then 
    
        numTakes = reaper.CountTakes(curItem)  
        for t=0, numTakes-1 do 
        
            curTake = reaper.GetTake(curItem, t)    
            if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake) then
                
                -- Deselect all events in one shot.
                reaper.MIDI_SelectAll(curTake, false)    
                
                -- This script does not use the standard MIDI API functions such as MIDI_SetCC, since these
                --    functions are far too slow when dealing with thousands of events.
                -- Instead, REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
                --    MIDI_GetAllEvts and MIDI_SetAllEvts.
                local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(curTake, "")
                
                if gotAllOK then
                
                    -- Quick check whether there are any notation events in take.
                    local lastNotationPos = MIDIstring:reverse():find(" ETON")
                    if lastNotationPos then
                    
                        -- Source length will be used to check that there were no inadvertent shifts in the PPQ positions of unedited events.
                        sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(curTake)
                    
                        local MIDIlen = MIDIstring:len()
                        lastNotationPos = MIDIlen - lastNotationPos + 1 
                        
                        -- To find notes with notation info, the MIDI data must unfortunately be parsed twice: 
                        --    first to get all the notation events, and then to select the notes.
                        -- Since REAPER version v5.32, notation events are stored *after* their matching note-ons,
                        --    which makes parsing more difficult, since notation must be parsed before note-ons
                        --    can be matched.
                    
                        -- The following tables with temporarily store data while parsing:
                        local tableNoteOns = {} -- Store last selected note-on' channel and pitch in order to capture the first following note-off.
                        local tableNotation = {} -- Store channel, pitch and PPQ position of any notation info, in order to capture the matching note-on.
                        for chan = 0, 15 do
                            tableNoteOns[chan] = {}
                            tableNotation[chan] = {}
                            for pitch = 0, 127 do
                                tableNotation[chan][pitch] = {}
                            end
                        end
                        
                        -- Count notation events and matching notes, to check whether each notation has a note, 
                        --    and whether any selection changes have been made to the take's MIDI.
                        local numNotation, numNotes = 0, 0 
                        
                        -- First parsing, looking for notation events.
                        local nextPos, runningPPQpos = 1, 0
                        
                        while nextPos < lastNotationPos do
                            local offset, flags, msg
                            offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, nextPos)
                            runningPPQpos = runningPPQpos + offset
                            if msg:byte(1) == 0xFF -- MIDI text event
                            and msg:byte(2) == 0x0F -- REAPER's MIDI text event type
                            -- !!!!! These lines can be modded to create variants of the script that will select notes with specific types of notation info.
                            and (msg:find("disp_pos") or msg:find("disp_len"))
                            --and msg:find("articulation")                         
                            --and msg:find("ornament")
                            --etc... 
                            then
                                -- Keep a record of existence of notation for this channel, pitch and PPQ position.
                                local channel, pitch = msg:match("NOTE (%d+) (%d+) ") 
                                if channel then
                                    tableNotation[tonumber(channel)][tonumber(pitch)][runningPPQpos] = true
                                    numNotation = numNotation + 1
                                end
                            end  
                        end                        
                        
                        -- Now parse again, looking for matching notes.
                        local tableEvents = {} -- All events will be stored in this table until they are concatened again
                        local t = 0 -- Count index in table.  It is faster to use tableEvents[t] = ... than table.insert(...
                        
                        -- The script will speed up execution by not inserting each event individually into tableEvents as they are parsed.
                        --    Instead, only changed (i.e. deselected) events will be re-packed and inserted individually, while unchanged events
                        --    will be inserted as bulk blocks of unchanged sub-strings.
                        local nextPos, prevPos, unchangedPos = 1, 1, 1 -- unchangedPos is starting position of block of unchanged MIDI.
                        local runningPPQpos = 0
                        
                        while nextPos <= MIDIlen do
                        
                            local mustSelect = false
                               
                            local offset, flags, msg
                            prevPos = nextPos
                            offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, nextPos)
                            runningPPQpos = runningPPQpos + offset
                            
                            local msg1 = msg:byte(1)
                            
                            -- Skip events with zero length
                            if msg1 then
                            
                                local eventType = msg1>>4
                                
                                -- Note-Ons
                                if eventType == 9 and msg:byte(3) ~= 0
                                then
                                    local channel = msg1&0x0F
                                    local pitch   = msg:byte(2)
                                    -- Is there already an active note-on on this channel and pitch?  If so, it is an overlap.
                                    if tableNoteOns[channel][pitch] then
                                        local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                                        reaper.ShowMessageBox("There appears to be overlapping notes among the notes with notation. Such notes cannot be parsed by this script."
                                                              .. "\n\nIn particular, at position " 
                                                              .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(curTake, runningPPQpos), "", 1)
                                                              .. " in the take: \n  '"
                                                              .. reaper.GetTakeName(curTake)
                                                              .. "'\nin the track: \n  '"
                                                              .. trackName
                                                              .. "'\n\nThe action 'Correct overlapping notes' can be used to correct overlapping notes in the MIDI editor."
                                                              , "ERROR", 0)
                                        reaper.Undo_EndBlock2(0, "INCOMPLETE: Select all notes that have customized display lengths or positions", -1)
                                        return false
                                    -- Is there notation matching this note's channel, pitch and PPQ position?
                                    elseif tableNotation[channel][pitch][runningPPQpos]
                                    then
                                        mustSelect = true
                                        numNotes = numNotes + 1
                                        tableNotation[channel][pitch][runningPPQpos] = nil -- Remove record
                                        -- Keep record of this note-on, so that next note-off on this channel and pitch can also be selected.
                                        tableNoteOns[channel][pitch] = true       
                                    end
                                    
                                -- Note-Offs
                                elseif (eventType == 8 or (msg:byte(3) == 0 and eventType == 9))
                                then
                                    local channel = msg1&0x0F
                                    local pitch   = msg:byte(2)
                                    -- Was there a note-off on this channel and pitch?
                                    if tableNoteOns[channel][pitch] 
                                    then
                                        mustSelect = true
                                        -- Delete record, so that next note-on doesn't think it is an overlap.
                                        tableNoteOns[channel][pitch] = nil
                                    end                                                                        
      
                                end
                                
                            end -- if msg1 exists
                                
                            ---------------------------------
                            -- Insert events into tableEvents
                            -- If the event is not changed,                             
                            if mustSelect then
                                if unchangedPos < prevPos then
                                    t = t + 1
                                    tableEvents[t] = MIDIstring:sub(unchangedPos, prevPos-1)
                                end
                                t = t + 1
                                tableEvents[t] = s_pack("i4Bs4", offset, flags|1, msg)
                                unchangedPos = nextPos
                            end        
                        end
                        
                        -- Iterated through entire MIDIstring. Write last remaining unchanged event to table.
                        t = t + 1
                        tableEvents[t] = MIDIstring:sub(unchangedPos)
                        
                        -----------------------------------------------------------------
                        -- Check whether any notation event did not have a matching note. 
                        -- This would probably indicate unsorted MIDI.
                        -- pairs will only return values if there are any undeleted notation events left in tableNotation
                        if numNotation ~= numNotes then
                            local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                            reaper.ShowMessageBox('The script found notation events without matching notes in the following take:\n  "'
                                                  .. reaper.GetTakeName(curTake)
                                                  .. '"\nin the track: \n  "'
                                                  .. trackName
                                                  .. '"\n\nThis may be the result of improperly sorted MIDI data. Usually, any small edit such as selecting a note '
                                                  .. "will induce the MIDI editor to sort the data - but look out for inadvertent changes to overlapping notes."
                                                  , "ERROR", 0)
                            reaper.Undo_EndBlock2(0, "INCOMPLETE: Select all notes that have customized display lengths or positions", -1)
                            return false
                        end
                        
                        ----------------------------------------------------------------------------------------------
                        -- Everything OK?  And were any change smade?  If so, write edited MIDI data back into take.
                        -- Note that this script does NOT sort the MIDI, since it does not change the order of events.
                        if numNotes > 0 then
                            reaper.MIDI_SetAllEvts(curTake, table.concat(tableEvents))
                            -- Check that there were no inadvertent shifts in the PPQ positions of unedited events.
                            if not (sourceLengthTicks == reaper.BR_GetMidiSourceLenPPQ(curTake)) then
                                reaper.MIDI_SetAllEvts(curTake, MIDIstring) -- Restore original MIDI
                                local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                                reaper.ShowMessageBox('The script has detected inadvertent shifts in the PPQ positions of unedited events in the following take:\n  "'
                                                      .. reaper.GetTakeName(curTake)
                                                      .. '"\nin the track: \n  "'
                                                      .. trackName
                                                      .. '"\n\nThis may be due to a bug in the script, or in the MIDI API functions.'
                                                      .. "\n\nPlease report the bug in the following forum thread:"
                                                      .. "\nhttp://forum.cockos.com/showthread.php?t=176878"
                                                      .. "\n\nThe original MIDI data will be restored to the take."
                                                      , "ERROR", 0)
                                reaper.Undo_EndBlock2(0, "INCOMPLETE: Select all notes that have customized display lengths or positions", -1)
                                return false
                            end
                        end
                        
                    end -- if MIDIstring:find("NOTE ")
                    
                else
                    local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                    reaper.ShowMessageBox('MIDI_GetAllEvts could not load the raw MIDI data of the following take:\n  "'
                                          .. reaper.GetTakeName(curTake)
                                          .. '"\nin the track: \n  "'
                                          .. trackName .. '"'
                                          , "ERROR", 0)
                    reaper.Undo_EndBlock2(0, "INCOMPLETE: Select all notes that have customized display lengths or positions", -1)
                    return false
                    
                end -- if gotAllOK       
            end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake)
        end -- for t=0, numTakes-1
    end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
end -- for i=0, numItems-1 

reaper.Undo_EndBlock2(0, "Select all notes that have customized display lengths or positions", -1)

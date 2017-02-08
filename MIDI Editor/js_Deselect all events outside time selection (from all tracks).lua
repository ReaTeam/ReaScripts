--[[
ReaScript name: js_Deselect all MIDI events outside time selection (from all tracks).lua
Version: 2.01
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: http://stash.reaper.fm/27595/Deselect%20all%20MIDI%20events%20outside%20time%20selection%20%28from%20all%20tracks%29%20-%20Copy.gif
Donation: https://www.paypal.me/juliansader
REAPER version: 5.30 or later
Extensions required: -
]]
 
--[[
 Changelog:
  * v1.0 (2015-05-14)
    + Initial Release
  * v1.01 (2015-06-06)
    + CC events at rightmost PPQ of time selection are deselected
  * v1.10 (2016-08-15)
    + Trying to create header that is compatible with ReaPack 1.1
  * v1.11 (2016-08-15)
    + Trying to create header that is compatible with ReaPack 1.1
  * v2.00 (2016-12-24)
    + Much faster execution.
    + Requires REAPER v5.30.
  * v2.01 (2017-02-08)
    + Parse muted notes that overlap with non-muted notes.
]]


-----------------------------------------------------------------
--function main() 

if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.30 or higher.", "ERROR", 0)
    return(false) 
end

local s_unpack = string.unpack
local s_pack   = string.pack

timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

reaper.Undo_BeginBlock2(0)

numItems = reaper.CountMediaItems(0)
for i=0, numItems-1 do 

    curItem = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, curItem, "MediaItem*") then 
    
        local itemStartTime = reaper.GetMediaItemInfo_Value(curItem, "D_POSITION")
        local itemEndTime   = itemStartTime + reaper.GetMediaItemInfo_Value(curItem, "D_LENGTH")
    
        numTakes = reaper.CountTakes(curItem)  
        for t=0, numTakes-1 do 
        
            curTake = reaper.GetTake(curItem, t)    
            if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake) then 
            
                if itemStartTime >= timeSelEnd or itemEndTime <= timeSelStart then
                    reaper.MIDI_SelectAll(curTake, false)
                    
                else
                    local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(curTake, "")
                    if not gotAllOK then
                        local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                        reaper.ShowMessageBox("The script could not load the raw MIDI data of the following take:"
                                              .. reaper.GetTakeName(curTake)
                                              .. "'\nin the track: \n  '"
                                              .. trackName
                                              , "ERROR", 0)
                        reaper.Undo_EndBlock2(0, "INCOMPLETE: Deselect all MIDI events outside time selection (from all tracks)", -1)
                        return false
                    else                 
    
                        local timeSelStartPPQinTake = reaper.MIDI_GetPPQPosFromProjTime(curTake, timeSelStart)
                        local timeSelEndPPQinTake = reaper.MIDI_GetPPQPosFromProjTime(curTake, timeSelEnd) 
                               
                        local tableEvents = {} -- All events will be stored in this table until they are concatened again
                        local t = 0 -- Count index in table.  It is faster to use tableEvents[t] = ... than table.insert(...
                        
                        local countDeselects = 0
                        
                        -- Notes are problematic, since the decision whether to deselect a note-on can only be made once the position of
                        --    the matching note-off is known.  Similarly, the decision whether to deselect a note-off depends on the 
                        --    position of the preceding note-on.
                        -- This table will be used to store the decision of whether the note-on has been deselected, for each channel and pitch.
                        --    If true, then the next matching note-off must also be deselected.
                        --    If false, then remain selected.
                        --    If nil, then there is no running note (i.e. no preceding note-on that has ot already been matched to a note-off).
                        local tableDeselectNextNoteOff = {} 
                        for flags = 0, 3 do
                            tableDeselectNextNoteOff[flags] = {}
                            for chan = 0, 15 do
                                tableDeselectNextNoteOff[flags][chan] = {}
                            end
                        end
                                     
                        -- The script will speed up execution by not inserting each event individually into tableEvents as they are parsed.
                        --    Instead, only changed (i.e. deselected) events will be re-packed and inserted individually, while unchanged events
                        --    will be inserted as bulk blocks of unchanged sub-strings.
                        local nextPos, prevPos, unchangedPos = 1, 1, 1 -- unchangedPos is starting position of block of unchanged MIDI.
                        local runningPPQpos = 0
                        
                        -- This script should make as little change as possible to the take, so no sorting will be done.
                        -- The script must therefore itarate through all evennts, and cannot quit as soon as an event 
                        --    with PPQ position > timeSelEndPPQinTake is reached.
                        local MIDIlen = MIDIstring:len()
                        while nextPos < MIDIlen do
                        
                            local mustDeselect = false
                            local offset, flags, msg
                            
                            prevPos = nextPos
                            offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
                            if offset < 0 then
                                local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                                reaper.ShowMessageBox('The script encountered improperly sorted MIDI data at the following position:\n   '
                                                      .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(curTake, runningPPQpos), "", 1)
                                                      .. '\nin the take:\n   "'
                                                      .. reaper.GetTakeName(curTake)
                                                      .. '"\nin the track:\n   "'
                                                      .. trackName
                                                      .. '"\n\nUsually, making any edit to the take in the MIDI editor, even simply selecting a note, will induce the editor to re-sort the MIDI data - '
                                                      .. 'but look out for inadvertent changes to overlapping notes.'
                                                      , "ERROR", 0)
                                reaper.Undo_EndBlock2(0, "INCOMPLETE: Deselect all MIDI events outside time selection (from all tracks)", -1)
                                return false
                            end
                            
                            runningPPQpos = runningPPQpos + offset
                            
                            if flags&1 == 1 then -- First bit in flags is selection status

                                local eventType = msg:byte(1)>>4
                                                                    
                                -- Note-offs
                                if eventType == 8 or (msg:byte(3) == 0 and eventType == 9) then
                                    local channel = msg:byte(1)&0x0F
                                    local pitch   = msg:byte(2)
                                    -- Was there a deselected note-on on this channel and pitch?
                                    if tableDeselectNextNoteOff[flags][channel][pitch] then
                                        mustDeselect = true
                                    end
                                    -- Delete record, so that next note-on doesn't think it is an overlap.
                                    tableDeselectNextNoteOff[flags][channel][pitch] = nil
                                    
                                -- Note-ons
                                elseif eventType == 9 then -- and msg:byte(3) > 0
                                    local channel = msg:byte(1)&0x0F
                                    local pitch   = msg:byte(2)
                                    
                                    -- Check for note overlaps.  nil implies that no running note on this channel and pitch
                                    if tableDeselectNextNoteOff[flags][channel][pitch] ~= nil then
                                        local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                                        reaper.ShowMessageBox('There appears to be overlapping notes among the selected notes. The lengths of such notes cannot be unambiguously determined by the script.'
                                                              .. '\n\nIn particular, at position:\n   '
                                                              .. reaper.format_timestr_pos(reaper.MIDI_GetProjTimeFromPPQPos(curTake, runningPPQpos), "", 1)
                                                              .. '\nin the take: \n   "'
                                                              .. reaper.GetTakeName(curTake)
                                                              .. '"\nin the track: \n   "'
                                                              .. trackName
                                                              .. '"\n\nThe action "Correct overlapping notes" can be used to correct overlapping notes in the MIDI editor.'
                                                              , "ERROR", 0)
                                        reaper.Undo_EndBlock2(0, "INCOMPLETE: Deselect all MIDI events outside time selection (from all tracks)", -1)
                                        return false
                                    end
                                    
                                    -- False means that the next matching selected note-off should not be deselected
                                    tableDeselectNextNoteOff[flags][channel][pitch] = false -- Temporary - must still search ahead
                                    
                                    -- Now check whether this note should be deselected
                                    if runningPPQpos >= timeSelEndPPQinTake then
                                        mustDeselect = true
                                        tableDeselectNextNoteOff[flags][channel][pitch] = true
                                        
                                    elseif runningPPQpos < timeSelStartPPQinTake then
                                        -- Search ahead in MIDI data, looking for a matching note-off so that note length can be determined.
                                        local matchChannelPitchNoteOff = string.char(0x80 | channel, pitch) 
                                        local matchChannelPitchNoteOn  = msg:sub(1,2)
                                        local evPos = nextPos -- Start search at position of next event in MIDI string
                                        local evPPQpos = runningPPQpos
                                        local evOffset, evFlags, evMsg
                                        
                                        repeat
                                            evOffset, evFlags, evMsg, evPos = s_unpack("i4Bs4", MIDIstring, evPos)
                                            -- Don't mind negative offsets of overlapping notes here - the other parts of the script will eventually detect them
                                            evPPQpos = evPPQpos + evOffset
                                            if evFlags == flags
                                            and (evMsg:sub(1,2) == matchChannelPitchNoteOff or (evMsg:sub(1,2) == matchChannelPitchNoteOn and evMsg:byte(3) == 0))
                                            then
                                                if evPPQpos <= timeSelStartPPQinTake then
                                                    mustDeselect = true
                                                    tableDeselectNextNoteOff[flags][channel][pitch] = true
                                                end
                                                
                                                -- If reached Note-off, whether mustDeselect or not, break out of loop
                                                break
                                            end
                                        until evPos >= MIDIlen-12 -- If reached MIDIlen, then the note is an extended, infinite note                                                                      
                                    end                            
                                                                        
                                -- All other event types
                                else
                                    if runningPPQpos < timeSelStartPPQinTake or runningPPQpos >= timeSelEndPPQinTake then
                                        mustDeselect = true
                                    end
                                end                                
                                
                            end -- if flags&1 == 1
                            
                            -- Now write the parsed events to tableEvents
                            if mustDeselect then
                                countDeselects = countDeselects + 1
                                if unchangedPos < prevPos then
                                    t = t + 1
                                    tableEvents[t] = MIDIstring:sub(unchangedPos, prevPos-1)
                                end
                                t = t + 1
                                tableEvents[t] = s_pack("i4Bs4", offset, flags&0xFE, msg)
                                unchangedPos = nextPos
                            end  
                            
                        end -- while nextPos < MIDIlen               
                        
                        -- Iteration complete.  Write the last block of remaining events to table.
                        t = t + 1
                        tableEvents[t] = MIDIstring:sub(unchangedPos)
                        
                        -------------------------------------
                        -- And write edited MIDI data to take
                        if countDeselects > 0 then
                            local newMIDIstring = table.concat(tableEvents)
                            if newMIDIstring:len() == MIDIlen then
                                reaper.MIDI_SetAllEvts(curTake, newMIDIstring)
                            else
                                local trackName, _ = reaper.GetTrackState(reaper.GetMediaItemTake_Track(curTake))
                                reaper.ShowMessageBox('Undefined error parsing the raw MIDI data of the following take:\n   "'
                                                      .. reaper.GetTakeName(curTake)
                                                      .. '"\nin the track:\n   "'
                                                      .. trackName .. '"'
                                                      , "ERROR", 0)
                                reaper.Undo_EndBlock2(0, "INCOMPLETE: Deselect all MIDI events outside time selection (from all tracks)", -1)
                                return false
                            end     
                        end
                        
                    end -- if gotAllOK
                end -- if itemStartTime >= timeSelEnd or itemEndTime <= timeSelStart
            end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake)
        end -- for t=0, numTakes-1
    end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
end -- for i=0, numItems-1

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Deselect all MIDI events outside time selection (from all tracks)", -1)

--main()

--[[
ReaScript name: js_Edit - Insert chased CCs at edit cursor in selected MIDI items.lua
Verion: 0.90
Author: juliansader
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script inserts CCs with chased values in all *used* channels and lanes of selected MIDI items.
  
  It is particularly useful before splitting items at the edit cursor, to ensure that the new items on the right will start playback with the same CC values as before splitting.

  (Note: In calculating the chased values, muted events are ignored.)
  
  # WARNING
  
  This script may cause changes to overlapping notes.  (However, splitting items will in any case cause the same changes.)
  Users should always be wary of overlapping notes, since these are not admissable according to the MIDI standards,
      and are often changed in unpredictable ways by scripts and native MIDI editing functions.
]]

--[[
Changelog:
  v0.90 (2017-07-05)
    * Initial beta release.
]]


---------------------------------------------
---------------------------------------------

local cursorTimePos = reaper.GetCursorPositionEx(0)

---------------

function insertChasedCCs()
    -- Loop through all selected items
    for i = 0, reaper.CountSelectedMediaItems(0)-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if reaper.ValidatePtr2(0, item, "MediaItem*") then
            local itemStartTimePos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local itemEndTimePos   = itemStartTimePos + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            if itemStartTimePos < cursorTimePos-0.000001 and itemEndTimePos > cursorTimePos+0.000001 then -- Take into account round error, to make sure that really overlap.
        
                -- Loop through all takes within each selected item
                for t = 0, reaper.CountTakes(item)-1 do
                    local take = reaper.GetTake(item, t)
                    if reaper.ValidatePtr2(0, take, "MediaItemTake*") and reaper.TakeIsMIDI(take) then
                    
                        local MIDIOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
                        
                        if not MIDIOK then 
                            local trackNumber = string.format("%i", tostring(reaper.GetMediaTrackInfo_Value(reaper.GetMediaItemTrack(item), "IP_TRACKNUMBER")))
                            reaper.MB("Error retrieving MIDI from item in track ".. trackNumber,  "ERROR", 0)
                            return
                        else
                        
                            local cursorPPQpos = math.ceil(reaper.MIDI_GetPPQPosFromProjTime(take, cursorTimePos)) -- use "ceil" to ensure that CCs are inserting *after* split point
                        
                            -- Set up tables in which the running values will be stored
                            local tLastCC = {} -- table with last values for each CC type and channel
                            local tLastPitch = {}
                            local tLastChanPress = {}
                            local tLastProgram = {}
                            for chan = 0, 15 do -- Some of the table will require subtables for CC lane, or MSB vs LSB.
                                tLastCC[chan] = {}
                                for lane = 0, 255 do
                                    tLastCC[chan][lane] = {lastPPQpos = -math.huge}
                                end
                                tLastProgram[chan]   = {lastPPQpos = -math.huge}
                                tLastChanPress[chan] = {lastPPQpos = -math.huge}
                                tLastPitch[chan]     = {lastPPQpos = -math.huge}
                            end 
                            
                            local MIDIlen = MIDIstring:len()
                            local runningPPQpos = 0
                            local stringPos     = 1 -- Position in MIDIstring while parsing
                            local offset, flags, msg
                            -- This script will not call MIDI_Sort. Instead, it will insert the new CCs precisely before the first event beyond cursorPPQpos
                            local foundFirstBeyond, insertPosInString, beforeInsertPPQ, afterInsertPPQ = false, nil, nil, nil 
                            
                            while stringPos < MIDIlen do
                                offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
                                runningPPQpos = runningPPQpos + offset
                                if foundFirstBeyond == false and runningPPQpos >= cursorPPQpos then
                                    foundFirstBeyond = true
                                    insertPosInString = stringPos - msg:len() - 9 -- Length of one event in MIDIstring
                                    beforeInsertPPQ = runningPPQpos - offset
                                    afterInsertPPQ  = runningPPQpos
                                end
        
                                if runningPPQpos <= cursorPPQpos and flags&2 ~= 2 and msg ~= "" then -- ignore muted CCs and empty events
                                    local chanmsg = msg:byte(1)&0xF0
                                    local chan    = msg:byte(1)&0x0F
                                    if chanmsg == 0xB0 then -- CC
                                        local lane = msg:byte(2)
                                        if runningPPQpos > tLastCC[chan][lane].lastPPQpos then
                                            tLastCC[chan][lane] = {lastPPQpos = runningPPQpos, value = msg:byte(3)}
                                        end
                                    elseif chanmsg == 0xC0 then -- Program select
                                        if runningPPQpos > tLastProgram[chan].lastPPQpos then
                                            tLastProgram[chan] = {lastPPQpos = runningPPQpos, value = msg:byte(2)}
                                        end
                                    elseif chanmsg == 0xD0 then -- Channel pressure
                                        if runningPPQpos > tLastChanPress[chan].lastPPQpos then
                                            tLastChanPress[chan] = {lastPPQpos = runningPPQpos, value = msg:byte(2)}
                                        end                        
                                    elseif chanmsg == 0xE0 then -- Pitch
                                        if runningPPQpos > tLastPitch[chan].lastPPQpos then
                                            tLastPitch[chan] = {lastPPQpos = runningPPQpos, value = msg:byte(3)<<7 | msg:byte(2)}
                                        end                         
                                    end
                                end
                            end
                            
                            -- If not foundFirstBeyond, then the cursor was beyond even the All-Notes-Off message at the end of the take
                            if foundFirstBeyond then
                            
                                local tMIDI = {}
                                tMIDI[1] = MIDIstring:sub(1, insertPosInString-1)
                                tMIDI[2] = string.pack("i4Bs4", cursorPPQpos - beforeInsertPPQ, 0, "")
                            
                                for chan = 0, 15 do
                                    for lane = 0, 255 do
                                        if tLastCC[chan][lane].value and tLastCC[chan][lane].lastPPQpos < cursorPPQpos then
                                            --reaper.MIDI_InsertCC(take, false, false, cursorPPQpos, 0xB0, chan, lane, tLastCC[chan][lane].value)
                                            tMIDI[#tMIDI+1] = string.pack("i4Bi4BBB", 0, 0, 3, 0xB0 | chan, lane, tLastCC[chan][lane].value)
                                        end
                                    end
                                    if tLastProgram[chan].value and tLastProgram[chan].lastPPQpos < cursorPPQpos then
                                        --reaper.MIDI_InsertCC(take, false, false, cursorPPQpos, 0xC0, chan, tLastProgram[chan].value, 0)
                                        tMIDI[#tMIDI+1] = string.pack("i4Bi4BB", 0, 0, 2, 0xC0 | chan, tLastProgram[chan].value)
                                    end
                                    if tLastChanPress[chan].value and tLastChanPress[chan].lastPPQpos < cursorPPQpos then
                                        --reaper.MIDI_InsertCC(take, false, false, cursorPPQpos, 0xD0, chan, tLastChanPress[chan].value, 0)
                                        tMIDI[#tMIDI+1] = string.pack("i4Bi4BB", 0, 0, 2, 0xD0 | chan, tLastChanPress[chan].value)
                                    end                    
                                    if tLastPitch[chan].value and tLastPitch[chan].lastPPQpos < cursorPPQpos then
                                        --reaper.MIDI_InsertCC(take, false, false, cursorPPQpos, 0xE0, chan, (tLastPitch[chan].value)&0x7F, (tLastPitch[chan].value)>>7)
                                        tMIDI[#tMIDI+1] = string.pack("i4Bi4BBB", 0, 0, 3, 0xE0 | chan, (tLastPitch[chan].value)&0x7F, (tLastPitch[chan].value)>>7)
                                    end            
                                end      
                                
                                tMIDI[#tMIDI+1] = string.pack("i4", afterInsertPPQ - cursorPPQpos)
                                tMIDI[#tMIDI+1] = MIDIstring:sub(insertPosInString+4,nil)
                                
                                reaper.MIDI_SetAllEvts(take, table.concat(tMIDI))
                            
                            end -- if foundFirstBeyond
                                  
                        end -- if not MIDIOK
                    end -- for t = 0, reaper.CountTakes(item)-1 do
                end -- 
            end -- if itemStartTimePos < cursorTimePos and itemEndTimePos > cursorTimePos
        end -- if reaper.ValidatePtr2(0, item, "MediaItem*")
    end -- for i = 0, reaper.CountSelectedMediaItems(0)-1
end

reaper.PreventUIRefresh(1)
insertChasedCCs()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_OnStateChange2(0, "Insert chased CCs at edit cursor in selected MIDI items")

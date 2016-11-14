--[[
ReaScript Name: Notation - Select all notes that have customized display lengths or positions
Version: 1.0
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=172782&page=25
REAPER version: v5.20
Extensions required: -
]]

--[[
 Changelog:
 * v1.0 (2016-08-15)
    + Initial beta release
]]

-----------------------------------------------------------------
--function main() 

numItems = reaper.CountMediaItems(0)
for i=0, numItems-1 do 

    curItem = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, curItem, "MediaItem*") then 
    
        numTakes = reaper.CountTakes(curItem)  
        for t=0, numTakes-1 do 
        
            curTake = reaper.GetTake(curItem, t)    
            if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake) then 
               
                reaper.MIDI_SelectAll(curTake, false)
                local tableNotation = {}
                
                _, countNotes, _, countTextSysex = reaper.MIDI_CountEvts(curTake)
                for eventIndex = 0, countTextSysex-1 do
                    local textOK, _, _, textPpq, textType, textMsg = reaper.MIDI_GetTextSysexEvt(curTake, eventIndex, true, false, 0, 0, "")
                    if textOK and textType == 15 and (textMsg:find("disp_len") ~= nil or textMsg:find("disp_pos") ~= nil) then
                        channelStr, pitchStr = textMsg:match("NOTE ([%d]+) ([%d]+)")
                        if channelStr ~= nil and pitchStr ~= nil then
                            -- The following converts the ppq, pitch and channel into a unique index number
                            tableNotation[(textPpq<<12) + ((tonumber(pitchStr))<<8) + tonumber(channelStr)] = true
                        end
                    end   
                end
                
                for noteIndex = 0, countNotes-1 do
                    local noteOK, _, _, noteStart, _, noteChannel, notePitch, _ = reaper.MIDI_GetNote(curTake, noteIndex)
                    if noteOK and tableNotation[(noteStart<<12) + (notePitch<<8) + noteChannel] then
                        reaper.MIDI_SetNote(curTake, noteIndex, true, nil, nil, nil, nil, nil, nil, true)
                    end
                end 
              
            end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake)
        end -- for t=0, numTakes-1
    end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
end -- for i=0, numItems-1

reaper.Undo_OnStateChange("Select all notes that have customized display lengths or positions")


--main()

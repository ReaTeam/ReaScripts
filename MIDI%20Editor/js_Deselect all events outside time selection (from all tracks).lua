--[[
ReaScript Name:  Deselect all MIDI events outside time selection (from all tracks) 
Version: 1.10
Author: juliansader
Licence: GPL v3
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: http://stash.reaper.fm/27595/Deselect%20all%20MIDI%20events%20outside%20time%20selection%20%28from%20all%20tracks%29%20-%20Copy.gif
REAPER version: 5.20
Extensions required: -
]]
 
--[[
 Changelog:
 * v1.0 (2015-05-14)
    + Initial Release
 * v1.01 (2015-06-06)
    + CC events at rightmost PPQ of time selection are deselected
 * v1.10 (2016-08-15)
    + Header compatible with ReaPack 1.1
]]

-----------------------------------------------------------------
--function main() 

timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

numItems = reaper.CountMediaItems(0)
for i=0, numItems-1 do 

    curItem = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, curItem, "MediaItem*") then 
    
        numTakes = reaper.CountTakes(curItem)  
        for t=0, numTakes-1 do 
        
            curTake = reaper.GetTake(curItem, t)    
            if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake) then 
              
                --reaper.MIDI_Sort(curTake) -- Would it be faster to sort beforehand?
                --Then can break out of loop as soon as event is to the right of the time selection
                timeSelStartppq = reaper.MIDI_GetPPQPosFromProjTime(curTake, timeSelStart)
                timeSelEndppq = reaper.MIDI_GetPPQPosFromProjTime(curTake, timeSelEnd) 
                  
                --------------------------------------------------------------------
                -- Save in table all selected events that fall within time selection
                --     so that they can be re-selected later after deselecting all
                local tableNotes = {}
                e = reaper.MIDI_EnumSelNotes(curTake, -1)  -- note event index
                while (e ~= -1) do
                    _, _, _, startppq, endppq, _, _, _ = reaper.MIDI_GetNote(curTake, e)
                    if (startppq >= timeSelStartppq or endppq > timeSelStartppq) -- beware of notes with 0 length
                    and startppq < timeSelEndppq then
                        table.insert(tableNotes, e)
                    end
                    e = reaper.MIDI_EnumSelNotes(curTake, e)
                end            
                
                local tableCCs = {}
                e = reaper.MIDI_EnumSelCC(curTake, -1)
                while (e ~= -1) do
                    _, _, _, ppqpos, _, _, _, _ = reaper.MIDI_GetCC(curTake, e)
                    if ppqpos >= timeSelStartppq and ppqpos < timeSelEndppq then
                       table.insert(tableCCs, e)
                    end
                    e = reaper.MIDI_EnumSelCC(curTake, e)
                end
                
                local tableSysex = {}
                e = reaper.MIDI_EnumSelTextSysexEvts(curTake, -1)
                while (e ~= -1) do
                    -- Documentation is incorrect: MIDI_SetTextSysexEvt requires msg, so store msgOut
                    _, _, _, ppqpos, _, msgOut = reaper.MIDI_GetTextSysexEvt(curTake, e)
                    if ppqpos >= timeSelStartppq and ppqpos < timeSelEndppq then
                        table.insert(tableSysex, {index = e, msg = msgOut})
                    end
                    e = reaper.MIDI_EnumSelTextSysexEvts(curTake, e)
                end
                
                
                ------------------------------------------------------------------------
                -- Deselect all events in one shot.  Much faster than doing this via Lua
                reaper.MIDI_SelectAll(curTake, false)
                
                 
                -----------------------------------------------------
                -- And finally, re-select the event in time selection
                for e = 1, #tableNotes do
                    reaper.MIDI_SetNote(curTake, tableNotes[e], true, nil, nil, nil, nil, nil, nil, true)
                end
                
                for e = 1, #tableCCs do
                    reaper.MIDI_SetCC(curTake, tableCCs[e], true, nil, nil, nil, nil, nil, nil, true)
                end
                
                for e = 1, #tableSysex do
                    reaper.MIDI_SetTextSysexEvt(curTake, tableSysex[e].index, true, nil, nil, nil, tableSysex[e].msg, true)
                end
               
              
            end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake)
        end -- for t=0, numTakes-1
    end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
end -- for i=0, numItems-1

reaper.Undo_OnStateChange("Deselect events outside time selection from ALL tracks")


--main()

--[[
 * ReaScript Name:  Deselect all MIDI events outside time selection (from all tracks)
 * Description:  
 * Instructions:  
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 1.01
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]
 

--[[
 Changelog:
 * v1.0 (2015-05-14)
    + Initial Release
 * v1.01 (2015-06-06)
    + CC events at rightmost PPQ of time selection are deselected
]]

--[[function deselect() 
  local(cur_take, i, notes, ccs, sysex, sel, muted, startppq, endppq, ppqpos,
        chan, pitch, vel, chanmsg, msg, msg2, msg3, type, 
        timesel_start, timesel_end, start_ppq, end_ppq, nr_items, nr_takes, t, e, cur_item)
( ]]

  timesel_start, timesel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
  nr_items = reaper.CountMediaItems(0)

  for i=0, nr_items-1 do
    cur_item = reaper.GetMediaItem(0, i)
    nr_takes = reaper.CountTakes(cur_item)

    for t=0, nr_takes-1 do
      cur_take = reaper.GetTake(cur_item, t)
      
      if(reaper.TakeIsMIDI(cur_take)) then
        
        --reaper.MIDI_Sort(cur_take) -- Would it be faster to sort beforehand?
        timesel_startppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, timesel_start);
        timesel_endppq = reaper.MIDI_GetPPQPosFromProjTime(cur_take, timesel_end);    
          
        ------------------------------------------------------------------
        -- Save all selected events in take in tables, 
        --     so that they can be re-selected later after deselecting all
        tableNotes = {}
        --beyondEnd = false
        e = reaper.MIDI_EnumSelNotes(cur_take, -1)  -- note event index
        while (e ~= -1) do -- and beyondEnd == false) do 
            _, _, _, startppq, endppq, _, _, _ = reaper.MIDI_GetNote(cur_take, e)
            if (endppq > timesel_startppq) then
                if (startppq < timesel_endppq) then
                    table.insert(tableNotes, e)
                --else
                --    beyondEnd = true
                end
            end
            e = reaper.MIDI_EnumSelNotes(cur_take, e)
        end            
        
        tableCCs = {}
        --beyondEnd = false
        e = reaper.MIDI_EnumSelCC(cur_take, -1)
        while (e ~= -1) do -- and beyondEnd == false) do
            _, _, _, ppqpos, _, _, _, _ = reaper.MIDI_GetCC(cur_take, e)
            if (ppqpos >= timesel_startppq) then
                if (ppqpos < timesel_endppq) then
                    table.insert(tableCCs, e)
                --else
                --    beyondEnd = true
                end
            end
            e = reaper.MIDI_EnumSelCC(cur_take, e)
        end
        
        tableSysex = {}
        --beyondEnd = false
        e = reaper.MIDI_EnumSelTextSysexEvts(cur_take, -1)
        while (e ~= -1) do -- and beyondEnd == false) do
            -- Documentation is incorrect: MIDI_SetTextSysexEvt requires msg
            _, _, _, ppqpos, _, msg = reaper.MIDI_GetTextSysexEvt(cur_take, e)
            if (ppqpos >= timesel_startppq) then
                if (ppqpos < timesel_endppq) then
                    table.insert(tableSysex, {index = e, msg = msg})
                    --else
                    --    beyondEnd = true
                end
            end
            e = reaper.MIDI_EnumSelTextSysexEvts(cur_take, e)
        end
        
        
        ------------------------------------------------------------------------
        -- Deselect all events in one shot.  Much faster than doing this via Lua
        reaper.MIDI_SelectAll(cur_take, false)
        
         
        -----------------------------------------------------
        -- And finally, re-select the event in time selection
        for e = 1, #tableNotes do
            reaper.MIDI_SetNote(cur_take, tableNotes[e], true, nil, nil, nil, nil, nil, nil, true)
        end
        
        for e = 1, #tableCCs do
            reaper.MIDI_SetCC(cur_take, tableCCs[e], true, nil, nil, nil, nil, nil, nil, true)
        end
        
        for e = 1, #tableSysex do
            reaper.MIDI_SetTextSysexEvt(cur_take, tableSysex[e].index, true, nil, nil, nil, tableSysex[e].msg, true)
        end
         
        
      end -- TakeIsMIDI    
    
      t = t + 1;
    end -- loop(nr_takes,
  
    i = i + 1;    
  end -- loop(nr_items,
  
  reaper.Undo_OnStateChange("Deselect events outside time selection from ALL items");


--deselect();

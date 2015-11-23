script_title = "Fit selected midi takes to their notes"
reaper.Undo_BeginBlock()

  itemcount = reaper.CountSelectedMediaItems(0)
  if itemcount ~= nil then
    for i =1, itemcount do
      item = reaper.GetSelectedMediaItem(0,i-1)
      if item ~= nil then
        item_pos = reaper.GetMediaItemInfo_Value(item,'D_POSITION')
        item_len = reaper.GetMediaItemInfo_Value(item,'D_LENGTH')
        take = reaper.GetActiveTake(item) 
        if take ~= nil then
          retval, notecnt = reaper.MIDI_CountEvts(take)
          if notecnt ~= nil then
            -- get min/max values
            max_ppq = 0
            min_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, item_pos + item_len)            
            notes_t = {}
            for j = 1, notecnt do
              retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, j-1)
              notes_subt = {selected, muted, startppqpos, endppqpos, chan, pitch, vel}
              table.insert(notes_t, notes_subt)
              max_ppq = math.max(max_ppq, endppqpos)  
              min_ppq = math.min(min_ppq, startppqpos)
            end
            
            -- move notes to item start
            if notes_t ~= nil then
              for k = 1, #notes_t do
                note_subt = notes_t[k]
                reaper.MIDI_SetNote(take, k-1, note_subt[1], note_subt[2], note_subt[3]-min_ppq, note_subt[4]-min_ppq, note_subt[5], note_subt[6], note_subt[7], true)
              end
            end            
            reaper.MIDI_Sort(take)
            d_time = reaper.MIDI_GetProjTimeFromPPQPos(take, min_ppq) - item_pos
            len_ret = reaper.MIDI_GetProjTimeFromPPQPos(take, max_ppq - min_ppq) - item_pos
          end
        end
        -- crop item
        reaper.SetMediaItemInfo_Value(item,'D_POSITION',item_pos + d_time)
        reaper.SetMediaItemInfo_Value(item,'D_LENGTH',len_ret)
        reaper.UpdateItemInProject(item)
      end      
    end
  end  
   
reaper.Undo_EndBlock(script_title, 0)   

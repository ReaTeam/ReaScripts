script_title = "Duplicate selected notes"
-- Alternative to internal duplicate action which is buggy especially with multichannel midi

reaper.Undo_BeginBlock()

notes_2_copy_t = {}  
notes_2_copy_subt = {}
act_editor = reaper.MIDIEditor_GetActive()
if act_editor ~= nil then
  take = reaper.MIDIEditor_GetTake(act_editor)
  if take ~= nil then
    item = reaper.GetMediaItemTake_Item(take)
    item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    channel = reaper.MIDIEditor_GetSetting_int(act_editor, "default_note_chan")
    retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
    if notecnt ~= nil then
      startppqpos_min = reaper.MIDI_GetPPQPosFromProjTime(take, item_len+item_pos)
      endppqpos_max = 0
      for i = 1, notecnt do
        retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i-1)
        if selected == true and chan == channel then          
          notes_2_copy_subt = {selected, muted, startppqpos, endppqpos, chan, pitch, vel}          
          table.insert(notes_2_copy_t, notes_2_copy_subt)          
          startppqpos_min = math.min(startppqpos_min, startppqpos)
          endppqpos_max = math.max(endppqpos_max, endppqpos)
        end
      end
    end  
      
    delta = endppqpos_max - startppqpos_min    
    
    if notecnt ~= nil then       
      for i = 1, notecnt do      
        retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i-1)
        reaper.MIDI_SetNote(take, i-1, false, muted, startppqpos, endppqpos, chan, pitch, vel, false)
      end    
    end
    
    if notes_2_copy_t ~= nil then
      for i = 1, #notes_2_copy_t do
        notes_2_copy_subt = notes_2_copy_t[i]
        reaper.MIDI_InsertNote(take, true, notes_2_copy_subt[2], notes_2_copy_subt[3]+delta, notes_2_copy_subt[4]+delta, 
                             notes_2_copy_subt[5], notes_2_copy_subt[6], notes_2_copy_subt[7], false)
      end    
    end
    reaper.MIDI_Sort(take)    
  end  
end
if item ~= nil then
  reaper.UpdateItemInProject(item)
end  
reaper.UpdateArrange()

reaper.Undo_EndBlock(script_title, 0)
 

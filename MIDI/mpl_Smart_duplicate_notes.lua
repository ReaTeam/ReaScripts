script_title = "Smart duplicate notes"

reaper.Undo_BeginBlock()

midi_editor = reaper.MIDIEditor_GetActive()
if midi_editor ~= nil then
  take = reaper.MIDIEditor_GetTake(midi_editor)
  if take ~= nil then  
    item = reaper.GetMediaItemTake_Item(take)
    item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    
    FNG_take = reaper.FNG_AllocMidiTake(take)
    -- store selected notes to table    
    notecnt = reaper.FNG_CountMidiNotes(FNG_take)
    if notecnt ~= nil then
      notes_2_copy_t = {}
      end_note_ppq_all = 0
      for i=1, notecnt do
        FNG_note = reaper.FNG_GetMidiNote(FNG_take, i-1)
        FNG_note_sel = reaper.FNG_GetMidiNoteIntProperty(FNG_note,"SELECTED")
        FNG_note_mute = reaper.FNG_GetMidiNoteIntProperty(FNG_note,"MUTED")
        FNG_note_pos = reaper.FNG_GetMidiNoteIntProperty(FNG_note,"POSITION")
        FNG_note_len = reaper.FNG_GetMidiNoteIntProperty(FNG_note,"LENGTH")
        FNG_note_chan = reaper.FNG_GetMidiNoteIntProperty(FNG_note,"CHANNEL")
        FNG_note_pitch = reaper.FNG_GetMidiNoteIntProperty(FNG_note,"PITCH")
        FNG_note_vel = reaper.FNG_GetMidiNoteIntProperty(FNG_note,"VELOCITY")
        if FNG_note_sel == 1 then          
          table.insert(notes_2_copy_t, {FNG_note_mute, FNG_note_pos,FNG_note_len,FNG_note_chan, FNG_note_pitch, FNG_note_vel})
        end
        end_note_ppq_all = math.max(end_note_ppq_all,FNG_note_pos+FNG_note_len)
      end
    end 
    
    -- search for limits / difference    
    if notes_2_copy_t ~= nil then    
      min_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, item_pos+item_len)
      max_ppq = 0
      for i=1, #notes_2_copy_t do        
        notes_2_copy_subt = notes_2_copy_t[i]
        min_ppq = math.min(notes_2_copy_subt[2], min_ppq)
        max_ppq = math.max(notes_2_copy_subt[2]+notes_2_copy_subt[3], max_ppq)
      end
    end
    ppq_dif = max_ppq - min_ppq    
    time_dif = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq_dif) - item_pos
    retval, measures, cml = reaper.TimeMap2_timeToBeats(0, time_dif)
    time_of_measure = reaper.TimeMap2_beatsToTime(0, 0, 1)
    measure_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, time_of_measure+ item_pos)
    adjust_ppq = measure_ppq * (measures+1)
    end_note_ppq = math.max(max_ppq + adjust_ppq, end_note_ppq_all)
    end_note_ppq_time = reaper.MIDI_GetProjTimeFromPPQPos(take, end_note_ppq)  - item_pos
        
    -- deselect other notes --
    notecnt = reaper.FNG_CountMidiNotes(FNG_take)
    if notecnt ~= nil then      
      for i=1, notecnt do
        FNG_note = reaper.FNG_GetMidiNote(FNG_take, i-1)
        reaper.FNG_SetMidiNoteIntProperty(FNG_note, "SELECTED", 0)
      end
    end       
    reaper.FNG_FreeMidiTake(FNG_take) 
        -- LEAVE --
    --------------------------------------------------------------
      
    -- adjust item edges  
    if notes_2_copy_t ~= nil then    
      
      if end_note_ppq_time > item_len then
        reaper.ApplyNudge(0, 0, 3, 16, measures+1, false, 1)          
      end  
      reaper.UpdateItemInProject(item)    
    end    
    
    --------------------------------------------------------------
        -- ALLOC --        
    take = reaper.MIDIEditor_GetTake(midi_editor)    
    FNG_take1 = reaper.FNG_AllocMidiTake(take)  
    -- insert notes from table ---
    if notes_2_copy_t ~= nil then
      for i = 1, #notes_2_copy_t do
        notes_2_copy_subt = notes_2_copy_t[i]        
        FNG_note1 = reaper.FNG_AddMidiNote(FNG_take1)
        --1FNG_note_mute, 2FNG_note_pos,3FNG_note_len,4FNG_note_chan, 5FNG_note_pitch, 6FNG_note_vel  
        reaper.FNG_SetMidiNoteIntProperty(FNG_note1, "SELECTED", 1)
        reaper.FNG_SetMidiNoteIntProperty(FNG_note1, "MUTED", notes_2_copy_subt[1])
        reaper.FNG_SetMidiNoteIntProperty(FNG_note1, "POSITION", notes_2_copy_subt[2]+adjust_ppq )
        reaper.FNG_SetMidiNoteIntProperty(FNG_note1, "LENGTH", notes_2_copy_subt[3])
        reaper.FNG_SetMidiNoteIntProperty(FNG_note1, "CHANNEL", notes_2_copy_subt[4])
        reaper.FNG_SetMidiNoteIntProperty(FNG_note1, "PITCH", notes_2_copy_subt[5])
        reaper.FNG_SetMidiNoteIntProperty(FNG_note1, "VELOCITY", notes_2_copy_subt[6])
      end 
    end   
    reaper.FNG_FreeMidiTake(FNG_take)    
  end --take ~= nil  
end

reaper.UpdateArrange()
reaper.Undo_EndBlock(script_title, 0)

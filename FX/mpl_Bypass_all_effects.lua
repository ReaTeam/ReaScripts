  script_title = "Bypass all effects"
  reaper.Undo_BeginBlock()
  
  counttracks = reaper.CountTracks(0)
  if counttracks  ~= nil then
    for i = 1, counttracks do
      tr = reaper.GetTrack(0,i-1)
      if tr ~= nil then
        instr_id = reaper.TrackFX_GetInstrument(tr)-1
        if instr_id == nil then instr_id = -1 end
        fxcount = reaper.TrackFX_GetCount(tr)
        if fxcount ~= nil then
          for j = 1, fxcount do
            if j-1 == instr_id then
              reaper.TrackFX_SetEnabled(tr, j-1, true)
             else
              reaper.TrackFX_SetEnabled(tr, j-1, false)
            end
          end
        end        
      end
    end
  end
  
  tr= reaper.GetMasterTrack(0)
    instr_id = reaper.TrackFX_GetInstrument(tr)-1
    if instr_id == nil then instr_id = -1 end
      fxcount = reaper.TrackFX_GetCount(tr)
      if fxcount ~= nil then
        for j = 1, fxcount do
          if j-1 == instr_id then
            reaper.TrackFX_SetEnabled(tr, j-1, true)
           else
            reaper.TrackFX_SetEnabled(tr, j-1, false)
          end
        end
    end  
    
  reaper.Undo_EndBlock(script_title, 0)

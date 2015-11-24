script_title = "Paste notes to selected item"
reaper.Undo_BeginBlock()

count = reaper.GetExtState("Buffer", "count")   
if count ~= nil and count ~= "" then
  item = reaper.GetSelectedMediaItem(0, 0)
  if item ~= nil then
    take = reaper.GetActiveTake(item)
    if take ~= nil then
      if reaper.TakeIsMIDI(take) == true then 
        for i = 1, count do
          selected_s = reaper.GetExtState(i, "selected_s") 
          reaper.DeleteExtState(i, "selected_s", false)
          if selected_s == "1" then selected = true else selected = false end
          
          muted_s = reaper.GetExtState(i, "muted_s") 
          reaper.DeleteExtState (i, "muted_s", false)
          if muted_s == "1" then muted = true else muted = false end
          
          startppqpos_s = reaper.GetExtState(i, "startppqpos_s") startppqpos = tonumber(startppqpos_s) reaper.DeleteExtState (i, "startppqpos_s", false)
          endppqpos_s = reaper.GetExtState(i, "endppqpos_s") endppqpos = tonumber(endppqpos_s) reaper.DeleteExtState (i, "endppqpos_s", false)
          chan_s = reaper.GetExtState(i, "chan_s") chan = tonumber(chan_s) reaper.DeleteExtState (i, "chan_s", false)
          pitch_s = reaper.GetExtState(i, "pitch_s") pitch = tonumber(pitch_s) reaper.DeleteExtState (i, "pitch_s", false)
          vel_s = reaper.GetExtState(i, "vel_s") vel = tonumber(vel_s) reaper.DeleteExtState (i, "vel_s", false)
          reaper.MIDI_InsertNote(take, selected, muted, startppqpos, endppqpos, chan, pitch, vel)
        end
      end
    end      
  end
end
reaper.DeleteExtState("Buffer", "count", false)
reaper.UpdateArrange()

reaper.Undo_EndBlock(script_title, 0)

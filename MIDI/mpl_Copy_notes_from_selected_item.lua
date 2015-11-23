script_title = "Copy notes from selected item"
reaper.Undo_BeginBlock()

item = reaper.GetSelectedMediaItem(0, 0)
if item ~= nil then
  take = reaper.GetActiveTake(item)
  if take ~= nil then
    if reaper.TakeIsMIDI(take) == true then      
      retval, notecnt, ccevtcnt, textsyxevtcnt = reaper.MIDI_CountEvts(take)
      if notecnt ~= nil then
        reaper.SetExtState("Buffer", "count", notecnt, false)
        for i = 1, notecnt do
          retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i-1)
          if retval == true then
            startppqpos_s, endppqpos_s, chan_s, pitch_s, vel_s =             
            tostring(startppqpos), tostring(endppqpos), tostring(chan), tostring(pitch), tostring(vel)
            if selected == true then selected_s = "1" else selected_s = "0" end
            if muted == true then muted_s = "1" else muted_s = "0" end
            reaper.SetExtState(i, "selected_s", selected_s, false)
            reaper.SetExtState(i, "muted_s", muted_s, false)
            reaper.SetExtState(i, "startppqpos_s", startppqpos_s, false)
            reaper.SetExtState(i, "endppqpos_s", endppqpos_s, false)
            reaper.SetExtState(i, "chan_s", chan_s, false)
            reaper.SetExtState(i, "pitch_s", pitch_s, false)
            reaper.SetExtState(i, "vel_s", vel_s, false)
          end 
        end
      end      
    end  
  end
end  

reaper.Undo_EndBlock(script_title, 0)
 

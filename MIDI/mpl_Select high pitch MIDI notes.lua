item = reaper.GetSelectedMediaItem(0, 0)
if item ~= nil then
  take = reaper.GetActiveTake(item)
  if take ~= nil then
    retval, notecntOut, ccevtcntOut, textsyxevtcntOut = reaper.MIDI_CountEvts(take)
    if retval ~= nil then
      pitchOutmax = 0
      for i = 1, notecntOut, 1 do
        retval, selectedOut, mutedOut, startppqposOut, endppqposOut, chanOut, pitchOut, velOut = reaper.MIDI_GetNote(take, i-1)
        pitchOutmax = math.max(pitchOut, pitchOutmax)
      end
      for i = 1, notecntOut, 1 do
        retval, selectedOut, mutedOut, startppqposOut, endppqposOut, chanOut, pitchOut, velOut = reaper.MIDI_GetNote(take, i-1)
        if pitchOut ~= pitchOutmax then 
          reaper.MIDI_SetNote(take, i-1, false)
         else
          reaper.MIDI_SetNote(take, i-1, true)
        end      
      end
    end
  end
end

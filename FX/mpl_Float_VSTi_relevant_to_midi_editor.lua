script_title = 'Show VSTi relevant to MIDI Editor'

reaper.Undo_BeginBlock()
act_editor = reaper.MIDIEditor_GetActive()
if act_editor ~= nil then
  take = reaper.MIDIEditor_GetTake(act_editor)
  if take ~= nil then
    take_track = reaper.GetMediaItemTake_Track(take)
    vsti_id = reaper.TrackFX_GetInstrument(take_track)
    if vsti_id ~= nil then 
      reaper.TrackFX_Show(take_track, vsti_id, 3) -- float
    end
    repeat
      parent_track = reaper.GetParentTrack(take_track)
      if parent_track ~= nil then
        vsti_id = reaper.TrackFX_GetInstrument(parent_track)
        if vsti_id ~= nil then 
          reaper.TrackFX_Show(parent_track, vsti_id, 3) -- float
        end
        take_track = parent_track
      end
    until parent_track == nil    
  end
end

reaper.Undo_EndBlock(script_title, 1)

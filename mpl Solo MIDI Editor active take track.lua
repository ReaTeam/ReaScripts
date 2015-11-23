script_title = 'Solo MIDI Editor active take track '

reaper.Undo_BeginBlock()
act_editor = reaper.MIDIEditor_GetActive()
if act_editor ~= nil then
  take = reaper.MIDIEditor_GetTake(act_editor)
  if take ~= nil then    
    take_track = reaper.GetMediaItemTake_Track(take)
    is_solo = reaper.GetMediaTrackInfo_Value(take_track, 'I_SOLO')
    
    if is_solo == 1 then reaper.SetMediaTrackInfo_Value(take_track, 'I_SOLO',0)
                    else reaper.Main_OnCommand(40340,0) reaper.SetMediaTrackInfo_Value(take_track, 'I_SOLO',1) end
    repeat
      parent_track = reaper.GetParentTrack(take_track)
      if parent_track ~= nil then
        reaper.SetMediaTrackInfo_Value(parent_track, 'I_SOLO',math.abs(is_solo-1))
        take_track = parent_track
      end
    until parent_track == nil    
  end
end

reaper.Undo_EndBlock(script_title, 1)

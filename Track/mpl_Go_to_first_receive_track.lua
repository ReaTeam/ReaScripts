 script_title = "Go to first receive track"
 reaper.Undo_BeginBlock()

receive_id = 1

tr = reaper.GetSelectedTrack(0,0)
if tr~= nil then  
  receive_tr = reaper.BR_GetMediaTrackSendInfo_Track(tr, -1, receive_id-1, 0)
  if receive_tr ~= nil then 
    reaper.Main_OnCommand(40297,0) -- unselect all
    reaper.SetTrackSelected(receive_tr, true) 
    reaper.SetMixerScroll(receive_tr)
    reaper.Main_OnCommand(40913,0) -- arrange view to selected send  
  end
end

reaper.Undo_EndBlock(script_title,0)


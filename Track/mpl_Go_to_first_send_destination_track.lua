 script_title = "Go to first send destination track"
 reaper.Undo_BeginBlock()

send_id = 1

tr = reaper.GetSelectedTrack(0,0)
if tr~= nil then  
  send_tr = reaper.BR_GetMediaTrackSendInfo_Track(tr, 0, send_id-1, 1)
  if send_tr ~= nil then 
    reaper.Main_OnCommand(40297,0) -- unselect all
    reaper.SetTrackSelected(send_tr, true) 
    reaper.SetMixerScroll(send_tr)
    reaper.Main_OnCommand(40913,0) -- arrange view to selected send  
  end
end

reaper.Undo_EndBlock(script_title,0)

_,_,_ = reaper.BR_GetMouseCursorContext()
item = reaper.BR_GetMouseCursorContext_Item()
track = reaper.BR_GetMouseCursorContext_Track()
if item~=nil then reaper.DeleteTrackMediaItem(track, item) reaper.UpdateArrange() end

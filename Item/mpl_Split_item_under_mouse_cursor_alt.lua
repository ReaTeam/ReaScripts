-- Always split only item under mouse cursor (without snap)

window, segment, details = reaper.BR_GetMouseCursorContext()
if details == "item" then 
  item = reaper.BR_GetMouseCursorContext_Item()
  position = reaper.BR_GetMouseCursorContext_Position()
  reaper.SplitMediaItem(item, position)
end  
reaper.UpdateArrange()

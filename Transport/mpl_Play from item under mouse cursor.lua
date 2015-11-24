_, _, _ = reaper.BR_GetMouseCursorContext()
item = reaper.BR_GetMouseCursorContext_Item()
if item ~= nil then
  pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  reaper.SetEditCurPos2(0, pos, true, true)
  reaper.CSurf_OnPlay()
end

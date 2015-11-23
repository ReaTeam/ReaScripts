script_title = "mpl Save locked items"

-- for use ONLY with "mpl Restore locked items"
reaper.Undo_BeginBlock()

itemcount = reaper.CountMediaItems(0)
if itemcount ~= nil then
  for i = 1, itemcount do
    item = reaper.GetMediaItem(0, i-1)
    if item ~= nil then
      is_lock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
      if is_lock == 1 then     
        track = reaper.GetMediaItemTrack(item)
        track_guid = reaper.BR_GetMediaTrackGUID(track)        
        retval, statechunk = reaper.GetItemStateChunk(item, "")
        tostring(track_guid)
        tostring(statechunk)
        reaper.SetProjExtState(0, "LOCKCHUNKS", track_guid, statechunk)
      end
    end
  end  
end

reaper.Undo_EndBlock(script_title, 0)

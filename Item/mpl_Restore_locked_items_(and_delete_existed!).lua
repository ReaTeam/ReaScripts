script_title = "mpl Restore locked items (and delete existed!)"

-- for use ONLY with "mpl Save locked items"
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

itemcount = reaper.CountMediaItems(0)
if itemcount ~= nil then
  items_to_delete_t = {}
  for i = 1, itemcount do
    item = reaper.GetMediaItem(0, i-1)
    if item ~= nil then 
      track = reaper.GetMediaItemTrack(item)
      track_guid = reaper.BR_GetMediaTrackGUID(track)       
      is_lock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
      if is_lock == 1 then   
        item_guid = reaper.BR_GetMediaItemGUID(item)
        table.insert(items_to_delete_t, {track_guid, item_guid})
      end
    end
  end
  
  for i = 1, #items_to_delete_t do
    temp_subt = items_to_delete_t[i]
    track = reaper.BR_GetMediaTrackByGUID(0, temp_subt[1])
    item = reaper.BR_GetMediaItemByGUID(0, temp_subt[2])
    reaper.DeleteTrackMediaItem(track, item)
  end  
end
        
for i = 1, 1000 do 
  retval, guid, itemchunk = reaper.EnumProjExtState(0, "LOCKCHUNKS", i-1)
  track = reaper.BR_GetMediaTrackByGUID(0, guid)
  if track ~= nil then
    retval1, trackchunk = reaper.GetTrackStateChunk(track, "")
    newchunk = trackchunk:sub(0, trackchunk:len()-2)..itemchunk..">".."\n"    
    reaper.SetTrackStateChunk(track, newchunk)
  end  
  if retval == false then break end
end

reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock(script_title, 0)

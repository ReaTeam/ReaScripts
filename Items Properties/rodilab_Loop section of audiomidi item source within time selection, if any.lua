-- @description Loop section of audio/midi item source within time selection, if any
-- @author Rodilab
-- @version 1.1
-- @changelog Remove console message
-- @about
--   Loop section of audio/midi item source within time selection, if any
--   Trim/Fit items to time selection if any, padding with silence. Then, loop section of audio/midi item source.
--
--   by Rodrigo Diaz (aka Rodilab)

function SliceItemOnPlace(item)
  reaper.GetSet_LoopTimeRange(true,true,item_in-1,item_out+1,false)
  reaper.Main_OnCommand(41385, 0) -- Item: Fit items to time selection, padding with silence if needed
  local new_item = reaper.SplitMediaItem(item, item_out)
  reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(new_item), new_item)
  new_item = reaper.SplitMediaItem(item, item_in)
  reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
  reaper.GetSet_LoopTimeRange(true,true,time_sel_start,time_sel_end,false)
  return new_item
end

function GetItemInfos(item)
  local item_in = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local item_out = item_in + length
  return item_in, length, item_out
end

count = reaper.CountSelectedMediaItems(0)

if count > 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange(false,false,0,0,false)

  -- Save selected item GUID list
  local new_items_list = {}
  local itemGUID_list = {}
  for i=0, count-1 do
    table.insert(itemGUID_list, reaper.BR_GetMediaItemGUID(reaper.GetSelectedMediaItem(0, i)))
  end

  for i, sGUID in ipairs(itemGUID_list) do
    local item = reaper.BR_GetMediaItemByGUID(0, sGUID)
    local take = reaper.GetActiveTake(item)
    local source = reaper.GetMediaItemTake_Source(take)
    reaper.SelectAllMediaItems(0, false)
    reaper.SetMediaItemSelected(item, true)

    item_in, length, item_out = GetItemInfos(item)
    local time_sel = time_sel_end - time_sel_start > 0 and 
          ((time_sel_start >= item_in and time_sel_start <= item_out) or 
          (time_sel_end   >= item_in and time_sel_end   <= item_out) or
          (item_in >= time_sel_start and item_in <= time_sel_end))

    if reaper.GetMediaSourceType(source, '') == 'MIDI' then
      reaper.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 0)

      if time_sel then
        reaper.Main_OnCommand(40508, 0) -- Item: Trim items to selected area
        item = reaper.GetSelectedMediaItem(0, 0)
        item_in, length, item_out = GetItemInfos(item)
        item = SliceItemOnPlace(item)

        if item_out < time_sel_end then
          length = length+(time_sel_end-item_out)
          item_out = item_in+length
          reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', length)
          item = SliceItemOnPlace(item)
        end

        reaper.Main_OnCommand(41385, 0) -- Item: Fit items to time selection, padding with silence if needed
        item = SliceItemOnPlace(item)
      end

      reaper.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 1)
    else
      if time_sel then
        reaper.Main_OnCommand(41385, 0) -- Item: Fit items to time selection, padding with silence if needed
      end
      reaper.SetMediaItemInfo_Value(item, 'B_LOOPSRC', 1)
      local rv, offs, len, rev = reaper.PCM_Source_GetSectionInfo(source)
      if rv then
        reaper.Main_OnCommand(40547, 0) -- Item properties: Loop section of audio item source
      end
      reaper.Main_OnCommand(40547, 0) -- Item properties: Loop section of audio item source
    end
    table.insert(new_items_list, item)
  end

  reaper.SelectAllMediaItems(0, false)
  for i, item in ipairs(new_items_list) do
    reaper.SetMediaItemSelected(item, true)
  end

  reaper.Undo_EndBlock("Loop section of audio/midi item source",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

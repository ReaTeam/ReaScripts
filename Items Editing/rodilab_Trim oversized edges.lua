-- @description Trim oversized edges
-- @author Rodilab
-- @version 1.2
-- @about
--   Trim item edges that exceed the length of the source media file.
--
--   by Rodrigo Diaz (aka Rodilab)

local count = reaper.CountSelectedMediaItems(0)

if count > 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Save items in a list
  local item_list = {}
  for i=0, count-1 do
    item_list[i+1] = reaper.GetSelectedMediaItem(0,i)
  end

  local init_cursor = reaper.GetCursorPosition()

  for i, item in ipairs(item_list) do
    local take =  reaper.GetActiveTake(item)
    if take then
      local source = reaper.GetMediaItemTake_Source(take)
      local samplerate = reaper.GetMediaSourceSampleRate(source)
      if samplerate > 0 then
        local position = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
        local playrate = reaper.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE")
        local startoffs = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")/playrate
        local source_length, lengthIsQN = reaper.GetMediaSourceLength(source)
        if lengthIsQN == true then
          source_length = reaper.TimeMap_QNToTime(source_length)
        end
        source_length = source_length/playrate

        reaper.SelectAllMediaItems(0,false)
        reaper.SetMediaItemSelected(item,true)

        if startoffs < 0 then
          -- Trim left edge to cursor
          cursor = reaper.GetCursorPosition()
          reaper.MoveEditCursor(position-startoffs-cursor,false)
          reaper.Main_OnCommand(41305,0)
        end

        if length+startoffs > source_length then
          -- Trim right edge to cursor
          cursor = reaper.GetCursorPosition()
          reaper.MoveEditCursor(position - startoffs + source_length - cursor,false)
          reaper.Main_OnCommand(41311,0)
        end
      end
    end
  end

  -- Restore EditCursor position
  reaper.SetEditCurPos(init_cursor,false,false)

  -- Restore selection
  reaper.SelectAllMediaItems(0,false)
  for i, item in ipairs(item_list) do
    reaper.SetMediaItemSelected(item,true)
  end

  reaper.Undo_EndBlock("Trim oversized edges",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

-- @description Render whole items in new take
-- @author Rodilab
-- @version 1.0
-- @about
--   Rend selected items in new takes to apply take FX.
--   Rendering applies to the entire source file, in order to enlarge items length later.
--   By Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock(0)

--Save all selected items in a list
count = reaper.CountSelectedMediaItems(0)
item_list={}
for i=0, count-1 do
  item = reaper.GetSelectedMediaItem(0, i)
  item_list[i] = item
end

--Render each item, one by one
for i=0, count-1 do

  --Select only one item
  reaper.SelectAllMediaItems(0,0)
  reaper.SetMediaItemSelected(item_list[i],1)

  -- Get item infos
  item = reaper.GetSelectedMediaItem(0,0)
  length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
  take = reaper.GetActiveTake(item)
  startoffs = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")
  source = reaper.GetMediaItemTake_Source(take)
  source_length, lengthIsQN = reaper.GetMediaSourceLength(source)
  if lengthIsQN == true then
    source_length = reaper.TimeMap_QNToTime(source_length)
  end

  -- Set lenght to source
  reaper.SetMediaItemInfo_Value(item,"D_LENGTH",source_length )
  reaper.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS", 0 )

  -- Render item in new take
  reaper.Main_OnCommand(41999,0)

  -- Trim item
  reaper.SetMediaItemInfo_Value(item,"D_LENGTH",length)
  reaper.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS",startoffs)
  take = reaper.GetActiveTake(item)
  reaper.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS",startoffs)

end

reaper.Undo_EndBlock("Render whole items in new take",0)

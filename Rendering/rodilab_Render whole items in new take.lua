-- @description Render whole items in new take
-- @author Rodilab
-- @version 1.1
-- @changelog Works only with audio sources.  Forbidden midi sources.
-- @about
--   Rend selected items in new takes to apply take FX.
--   Rendering applies to the entire source file, in order to enlarge items length later.
--   Works only with audio sources (no MIDI).
--   By Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock(0)

--Save all selected items in a list
local count = reaper.CountSelectedMediaItems(0)
local item_list={}
for i=0, count-1 do
  item_list[i] = reaper.GetSelectedMediaItem(0,i)
end

--Render each item, one by one
for i=0, count-1 do

  --Select only one item
  reaper.SelectAllMediaItems(0,0)
  reaper.SetMediaItemSelected(item_list[i],1)

  -- Get item infos
  local item = reaper.GetSelectedMediaItem(0,0)
  local length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
  local take = reaper.GetActiveTake(item)
  local startoffs = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")
  local playrate = reaper.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE")
  local source = reaper.GetMediaItemTake_Source(take)
  local source_length, lengthIsQN = reaper.GetMediaSourceLength(source)
  if lengthIsQN == true then
    source_length = reaper.TimeMap_QNToTime(source_length)
  end
  source_length = source_length/playrate
  local samplerate =  reaper.GetMediaSourceSampleRate(source)

  -- If source is audio file (no midi)
  if samplerate > 0 then
    -- Set lenght to source
    reaper.SetMediaItemInfo_Value(item,"D_LENGTH",source_length )
    reaper.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS", 0 )

    -- Render item in new take
    reaper.Main_OnCommand(41999,0)

    -- Trim item
    reaper.SetMediaItemInfo_Value(item,"D_LENGTH",length)
    reaper.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS",startoffs)
    take = reaper.GetActiveTake(item)
    reaper.SetMediaItemTakeInfo_Value(take,"D_STARTOFFS",startoffs/playrate)
  end
end

reaper.Undo_EndBlock("Render whole items in new take",0)

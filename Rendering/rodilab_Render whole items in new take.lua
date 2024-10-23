-- @description Render whole items in new take
-- @author Rodilab
-- @version 1.3
-- @changelog Update : New script in this package to preserve the Take Name
-- @provides [main] rodilab_Render whole items in new take/rodilab_Render whole items in new take (preserve take name).lua
-- @about
--   Rend selected items in new takes to apply take FX.
--   Rendering applies to the entire source file, in order to enlarge items length later.
--   Works only with audio sources (no MIDI).
--   A second script is available in this package to preserve the take name.
--
--   by Rodrigo Diaz (aka Rodilab)

local count = reaper.CountSelectedMediaItems(0)

if count > 0 then
  reaper.Undo_BeginBlock(0)
  reaper.PreventUIRefresh(1)

  --Save all selected items in a list
  local item_list={}
  for i=0, count-1 do
    item_list[i+1] = reaper.GetSelectedMediaItem(0,i)
  end

  --Render each item, one by one
  for i, item in ipairs(item_list) do

    --Select only one item
    reaper.SelectAllMediaItems(0,0)
    reaper.SetMediaItemSelected(item,1)

    -- Get item infos
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

  -- Restore selection
  reaper.SelectAllMediaItems(0,0)
  for i, item in ipairs(item_list) do
    reaper.SetMediaItemSelected(item,1)
  end

  reaper.Undo_EndBlock("Render whole items in new take",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

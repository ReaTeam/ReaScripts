-- @description Implode mono items into stereo item
-- @author Rodilab
-- @version 1.0
-- @about
--   Searches for matches between the selected mono items, and implode them into stereo items.
--   - To match, items source must be mono audio files and items must have the same position, length, startoffs, source length, samplerate and playrate.
--   - To implode item, a new stereo source file is rendered. But the rendering is done on the whole source file, beyond the item edges.
--   - If several items with the same source file are imploded at the same time,  then only one stereo file is rendered and applied to these items (avoids duplicates).
--   - All parameters, FX and automations of the first item are kept.
--
--   by Rodrigo Diaz (aka Rodilab)

reaper.Undo_BeginBlock()

-- Count selected items
count = reaper.CountSelectedMediaItems(0)

-- if at least two items are selected
if count > 1 then

  -- Save selected items in a list
  local item_list = {}
  for i=0, count-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    item_list[i] = item
  end

  -- Initialise errors var
  local match = 0
  local final_count = count

  -- List of source files and glued new files
  local list_source_1 = {}
  local list_source_2 = {}
  local list_source_new = {}

  -- For each item in first track
  for i=0, count-1 do
    local item_1 = item_list[i]

    if item_1 ~= nil then
      local track_1 = reaper.GetMediaItemInfo_Value(item_1,"P_TRACK")
      local position_1 = reaper.GetMediaItemInfo_Value(item_1,"D_POSITION")
      local length_1 = reaper.GetMediaItemInfo_Value(item_1,"D_LENGTH")

      local take_1 =  reaper.GetActiveTake(item_1)
      local startoffs_1 =  reaper.GetMediaItemTakeInfo_Value(take_1,"D_STARTOFFS")
      local playrate_1 =  reaper.GetMediaItemTakeInfo_Value(take_1,"D_PLAYRATE")
      local source_1 =  reaper.GetMediaItemTake_Source(take_1)
      local source_name_1 = reaper.GetMediaSourceFileName(source_1,"")
      local source_length_1, lengthIsQN_1 = reaper.GetMediaSourceLength(source_1)
      if lengthIsQN_1 == true then
            source_length_1 = reaper.TimeMap_QNToTime(source_length_1)
          end
      local source_channels_1 =  reaper.GetMediaSourceNumChannels(source_1)
      local samplerate_1 =  reaper.GetMediaSourceSampleRate(source_1)

      -- Compare with next selected items
      local j=i+1
      while j < count do

        local item_2 = item_list[j]
        if item_2 ~= nil then
          local track_2 = reaper.GetMediaItemInfo_Value(item_2,"P_TRACK")
          local position_2 = reaper.GetMediaItemInfo_Value(item_2,"D_POSITION")
          local length_2 = reaper.GetMediaItemInfo_Value(item_2,"D_LENGTH")
          local take_2 =  reaper.GetActiveTake(item_2)
          local startoffs_2 = reaper.GetMediaItemTakeInfo_Value(take_2,"D_STARTOFFS")
          local playrate_2 = reaper.GetMediaItemTakeInfo_Value(take_2,"D_PLAYRATE")
          local source_2 = reaper.GetMediaItemTake_Source(take_2)
          local source_name_2 = reaper.GetMediaSourceFileName(source_2,"")
          local source_length_2, lengthIsQN_2 = reaper.GetMediaSourceLength(source_2)
          if lengthIsQN_2 == true then
            source_length_2 = reaper.TimeMap_QNToTime(source_length_2)
          end
          local source_channels_2 = reaper.GetMediaSourceNumChannels(source_2)
          local samplerate_2 =  reaper.GetMediaSourceSampleRate(source_2)

          if  source_channels_1 == 1 and
              source_channels_2 == 1 and
              position_1 == position_2 and
              length_1 == length_2 and
              source_length_1 == source_length_2 and
              startoffs_1 == startoffs_2 and
              playrate_1 == playrate_2 and
              samplerate_1 == samplerate_2 and
              samplerate_1 ~= 0 then

            -- Search if these source files have already been glued
            local index
            local valeur
            local PCM_exist
            for index, valeur in ipairs(list_source_1) do --loop through the table--
              if valeur == source_name_1 and list_source_2[index] == source_name_2 then
                PCM_exist = index
                break
              else
                PCM_exist = nil
              end
            end

            -- If not already glued : move, pan and glue
            if PCM_exist == nil then
              -- Create new empty items
              local new_item_left = reaper.AddMediaItemToTrack(track_1)
              local new_item_right = reaper.AddMediaItemToTrack(track_1)
              reaper.SetMediaItemInfo_Value(new_item_left,"D_LENGTH",source_length_1)
              reaper.SetMediaItemInfo_Value(new_item_right,"D_LENGTH",source_length_1)
              reaper.AddTakeToMediaItem(new_item_left)
              reaper.AddTakeToMediaItem(new_item_right)
              local new_take_left = reaper.GetMediaItemTake(new_item_left,0)
              local new_take_right = reaper.GetMediaItemTake(new_item_right,0)
              -- Set source
              reaper.SetMediaItemTake_Source(new_take_left,source_1)
              reaper.SetMediaItemTake_Source(new_take_right,source_2)
              -- Pan
              reaper.SetMediaItemTakeInfo_Value(new_take_left,"D_PAN",-1)
              reaper.SetMediaItemTakeInfo_Value(new_take_right,"D_PAN",1)

              -- Select only this both new items
              reaper.SelectAllMediaItems(0,0)
              reaper.SetMediaItemSelected(new_item_left,1)
              reaper.SetMediaItemSelected(new_item_right,1)

              -- Item mix behavior always play
              reaper.Main_OnCommand(40919,0)

              -- Glue items
              reaper.Main_OnCommand(41588,0)

              -- Get new stereo source PCM
              local new_stereo_item = reaper.GetSelectedMediaItem(0,0)
              local new_stereo_take = reaper.GetActiveTake(new_stereo_item)
              local new_stereo_source_PCM = reaper.GetMediaItemTake_Source(new_stereo_take)

              -- Change source PCM on first item
              reaper.SetMediaItemTake_Source(take_1,new_stereo_source_PCM)
              reaper.SetMediaItemTakeInfo_Value(take_1,"D_PAN",0)

              -- Save source on a list
              table.insert(list_source_1, source_name_1)
              table.insert(list_source_2, source_name_2)
              table.insert(list_source_new, reaper.GetMediaItemTake_Source(take_1))

              -- Delete other items
              reaper.DeleteTrackMediaItem(track_2,item_2)
              reaper.DeleteTrackMediaItem(track_1,new_stereo_item)

            -- If already glued, only change source and delete second item
            else
              reaper.SetMediaItemTake_Source(take_1,list_source_new[PCM_exist])
              reaper.DeleteTrackMediaItem(track_2,item_2)
            end

            -- Update error infos
            item_list[j] = nil
            match = match + 1
            final_count = final_count - 1

            break
          end

        end
        j = j+1
      end
    end
  end

  if match < final_count then
    match = tostring(final_count-match)
    reaper.ShowMessageBox(match.." items didn't match. \nItems source must be mono audio files. And items must have the same position, length, startoffs, playrate, source length and samplerate.", "Error: Combine mono items into stereo item", 0 )
  end

end

reaper.Undo_EndBlock("Combine mono items into stereo item",0)

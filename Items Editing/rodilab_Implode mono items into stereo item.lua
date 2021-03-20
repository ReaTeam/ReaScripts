-- @description Implode mono items into stereo item
-- @author Rodilab
-- @version 1.2
-- @about
--   Searches for matches between the selected mono items, and implode them into stereo items.
--   - To match, items source must be mono audio files and items must have the same position, length, startoffs, source length, samplerate and playrate.
--   - To implode item, a new stereo source file is rendered. But the rendering is done on the whole source file, beyond the item edges.
--   - If several items with the same source file are imploded at the same time,  then only one stereo file is rendered and applied to these items (avoids duplicates).
--   - All parameters, FX and automations of the first item are kept.
--
--   by Rodrigo Diaz (aka Rodilab)

-- Function : Get real take channel number (depends on source and chanmode)
local function real_chans(take,source)
  local take_chanmode = reaper.GetMediaItemTakeInfo_Value(take,"I_CHANMODE")
  local source_chan =  reaper.GetMediaSourceNumChannels(source)
  local take_chan = 0
  if source_chan > 1 and take_chanmode < 2 then
    take_chan = source_chan
  elseif source_chan > 1 and take_chanmode > 66 then
    take_chan = 2
  else
    take_chan = 1
  end
  return take_chan,take_chanmode
end

local function main ()
  -- Count selected items
  local count = reaper.CountSelectedMediaItems(0)

  -- if at least two items are selected
  if count > 1 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    -- Save selected items in a list
    local item_list = {}
    for i=0, count-1 do
      item_list[i] = reaper.GetSelectedMediaItem(0,i)
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
      if item_1 then
        local take_1 =  reaper.GetActiveTake(item_1)
        if take_1 then
          local source_1 =  reaper.GetMediaItemTake_Source(take_1)
          local samplerate_1 =  reaper.GetMediaSourceSampleRate(source_1)
          if samplerate_1 > 0 then
            local track_1 = reaper.GetMediaItemInfo_Value(item_1,"P_TRACK")
            local position_1 = reaper.GetMediaItemInfo_Value(item_1,"D_POSITION")
            local length_1 = reaper.GetMediaItemInfo_Value(item_1,"D_LENGTH")
            local startoffs_1 =  reaper.GetMediaItemTakeInfo_Value(take_1,"D_STARTOFFS")
            local playrate_1 =  reaper.GetMediaItemTakeInfo_Value(take_1,"D_PLAYRATE")
            local source_name_1 = reaper.GetMediaSourceFileName(source_1,"")
            local source_length_1, lengthIsQN_1 = reaper.GetMediaSourceLength(source_1)
            if lengthIsQN_1 == true then
              source_length_1 = reaper.TimeMap_QNToTime(source_length_1)
            end
            local source_channels_1 = reaper.GetMediaSourceNumChannels(source_1)
            local take_chan_1,take_chanmode_1 = real_chans(take_1,source_1)
            local diff = (1/samplerate_1)/2

            -- Compare with next selected items
            local j=i+1
            while j < count do
              local item_2 = item_list[j]
              if item_2 then
                local take_2 =  reaper.GetActiveTake(item_2)
                if take_2 then
                  local source_2 = reaper.GetMediaItemTake_Source(take_2)
                  local samplerate_2 =  reaper.GetMediaSourceSampleRate(source_2)
                  if samplerate_2 > 0 then
                    local track_2 = reaper.GetMediaItemInfo_Value(item_2,"P_TRACK")
                    local position_2 = reaper.GetMediaItemInfo_Value(item_2,"D_POSITION")
                    local length_2 = reaper.GetMediaItemInfo_Value(item_2,"D_LENGTH")
                    local startoffs_2 = reaper.GetMediaItemTakeInfo_Value(take_2,"D_STARTOFFS")
                    local playrate_2 = reaper.GetMediaItemTakeInfo_Value(take_2,"D_PLAYRATE")
                    local source_name_2 = reaper.GetMediaSourceFileName(source_2,"")
                    local source_length_2, lengthIsQN_2 = reaper.GetMediaSourceLength(source_2)
                    if lengthIsQN_2 == true then
                      source_length_2 = reaper.TimeMap_QNToTime(source_length_2)
                    end
                    local source_channels_2 = reaper.GetMediaSourceNumChannels(source_2)
                    local take_chan_2,take_chanmode_2 = real_chans(take_2,source_2)

                    -- Compare items info values (half sample diff tolerance)
                    if  take_chan_1 == 1 and
                        take_chan_2 == 1 and
                        samplerate_1 == samplerate_2 and
                        position_1 - position_2 > -diff and position_1 - position_2 < diff and
                        length_1 - length_2 > -diff and length_1 - length_2 < diff and
                        source_length_1 - source_length_2 > -diff and source_length_1 - source_length_2 < 1e-5 and
                        startoffs_1 - startoffs_2 > -diff and startoffs_1 - startoffs_2 < diff and
                        playrate_1 - playrate_2 > -diff and playrate_1 - playrate_2 < diff then

                      -- If same source and chanmode can be changed to stereo
                      if  source_name_1 == source_name_2 and
                          take_chanmode_1 >= 3 and take_chanmode_1 <= 66 and
                          take_chanmode_1 == take_chanmode_2 - 1 then
                        -- Change chanmode in stereo
                        reaper.SetMediaItemTakeInfo_Value(take_1,"I_CHANMODE",take_chanmode_1+64)
                        -- Delete other items
                        reaper.DeleteTrackMediaItem(track_2,item_2)
                      else
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
                        if not PCM_exist then
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
                          -- Set chanmode
                          reaper.SetMediaItemTakeInfo_Value(new_take_left,"I_CHANMODE",take_chanmode_1)
                          reaper.SetMediaItemTakeInfo_Value(new_take_right,"I_CHANMODE",take_chanmode_2)
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
                          reaper.SetMediaItemTakeInfo_Value(take_1,"I_CHANMODE",0)
                          reaper.SetMediaItemTakeInfo_Value(take_1,"D_PAN",0)

                          -- Save source on a list
                          if source_name_1 ~= source_name_2  and source_channels_1 == 1 and source_channels_2 == 1 then
                            table.insert(list_source_1, source_name_1)
                            table.insert(list_source_2, source_name_2)
                            table.insert(list_source_new, reaper.GetMediaItemTake_Source(take_1))
                          end

                          -- Delete other items
                          reaper.DeleteTrackMediaItem(track_2,item_2)
                          reaper.DeleteTrackMediaItem(track_1,new_stereo_item)

                        -- If already glued, only change source and delete second item
                        else
                          reaper.SetMediaItemTake_Source(take_1,list_source_new[PCM_exist])
                          reaper.SetMediaItemTakeInfo_Value(take_1,"I_CHANMODE",0)
                          reaper.SetMediaItemTakeInfo_Value(take_1,"D_PAN",0)
                          reaper.DeleteTrackMediaItem(track_2,item_2)
                        end
                      end

                      -- Update error infos
                      item_list[j] = nil
                      match = match + 1
                      final_count = final_count - 1

                      break
                    end -- End compare for match
                  end -- End if samplerate_2 > 0
                end -- End if take_2 isset
              end -- End if item_2 isset
              j = j+1
            end -- End while j
          end -- End if samplerate_1 > 0
        end -- End if take_1 isset
      end -- End if item_1 isset
    end -- End for each item

    -- Restore selection
    reaper.SelectAllMediaItems(0,0)
    for i=0, count-1 do
      local item = item_list[i]
      if item then
        reaper.SetMediaItemSelected(item,1)
      end
    end

    reaper.Undo_EndBlock("Implode mono items into stereo item",0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()

    if match < final_count then
      match = tostring(final_count-match)
      reaper.ShowMessageBox(match.." items didn't match. \nItems source must be mono audio files. And items must have the same position, length, startoffs, playrate, source length and samplerate.", "Error: Combine mono items into stereo item", 0 )
    end
  end
end

main()

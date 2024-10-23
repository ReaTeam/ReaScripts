-- @noindex

local count = reaper.CountSelectedMediaItems(0)

if count > 0 then
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Save items and auto-fades infos on lists
  local item_list = {}
  local fadein_auto_list = {}
  local fadeout_auto_list = {}
  for i=0, count-1 do
    local item = reaper.GetSelectedMediaItem(0,i)
    item_list[i] = item
    fadein_auto_list[i] = reaper.GetMediaItemInfo_Value(item,"D_FADEINLEN_AUTO")
    fadeout_auto_list[i] = reaper.GetMediaItemInfo_Value(item,"D_FADEOUTLEN_AUTO")
  end

  -- Enable auto-fades option
  if reaper.GetToggleCommandState(40041) == 0 then
    reaper.Main_OnCommand(40041,0)
    fade_option = false
  else
    fade_option = true
  end

  -- Move selected items and envelopes right
  reaper.Main_OnCommand(40119,0)

  for i=0, count-1 do
    local item = item_list[i]
    -- Check autofades length after move
    local new_fadein_auto = reaper.GetMediaItemInfo_Value(item,"D_FADEINLEN_AUTO")
    local new_fadeout_auto = reaper.GetMediaItemInfo_Value(item,"D_FADEOUTLEN_AUTO")

    -- If any autofades changes
    if fadeout_auto_list[i] ~= new_fadeout_auto or fadein_auto_list[i] ~= new_fadein_auto then
      -- Get item infos
      local position = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
      local length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
      local track = reaper.GetMediaItem_Track(item)
      local count_track = reaper.CountTrackMediaItems(track)
      local item_IP = reaper.GetMediaItemInfo_Value(item,"IP_ITEMNUMBER")

      -- If fadeout_auto length change
      if fadeout_auto_list[i] ~= new_fadeout_auto then

        -- Select all next overlap items on track
        reaper.SelectAllMediaItems(0,0)
        local j = item_IP + 1
        local next_item = reaper.GetTrackMediaItem(track,j)
        local next_position = reaper.GetMediaItemInfo_Value(next_item,"D_POSITION")
        local next_length = reaper.GetMediaItemInfo_Value(next_item,"D_LENGTH")
        while j < count_track and next_position < position + length do
          if next_position + next_length > position + length then
            reaper.SetMediaItemSelected(next_item,true)
          end
          j = j + 1
          if j < count_track then
            next_item = reaper.GetTrackMediaItem(track,j)
            next_position = reaper.GetMediaItemInfo_Value(next_item,"D_POSITION")
            next_length = reaper.GetMediaItemInfo_Value(next_item,"D_LENGTH")
          end
        end
        -- Trim left edges
        reaper.Main_OnCommand(40226,0)

        -- Set old fadeout_auto length
        reaper.SetMediaItemInfo_Value(item,"D_FADEOUTLEN_AUTO",fadeout_auto_list[i])
      end

      -- If fadein_auto length change
      if fadein_auto_list[i] ~= new_fadein_auto then

        -- Select all previous overlap items on track
        reaper.SelectAllMediaItems(0,0)
        local j = item_IP - 1
        local previous_item = reaper.GetTrackMediaItem(track,j)
        local previous_position = reaper.GetMediaItemInfo_Value(previous_item,"D_POSITION")
        local previous_length = reaper.GetMediaItemInfo_Value(previous_item,"D_LENGTH")
        while j >= 0 and previous_position + previous_length > position do
          if previous_position + previous_length > position  and previous_position < position then
            reaper.SetMediaItemSelected(previous_item,true)
          end
          j = j - 1
          if j >= 0 then
            previous_item = reaper.GetTrackMediaItem(track,j)
            previous_position = reaper.GetMediaItemInfo_Value(previous_item,"D_POSITION")
            previous_length = reaper.GetMediaItemInfo_Value(previous_item,"D_LENGTH")
          end
        end
        -- Grow right edges
        reaper.Main_OnCommand(40228,0)

        -- Set old fadeout_auto length
        reaper.SetMediaItemInfo_Value(item,"D_FADEINLEN_AUTO",fadein_auto_list[i])
      end
    end
  end

  -- Recorver selection
  reaper.SelectAllMediaItems(0,0)
  for i=0, count-1 do
    item = item_list[i]
    reaper.SetMediaItemSelected(item,true)
  end

  -- Recover autofade option state
  if fade_option == false then
    reaper.Main_OnCommand(40041,0)
  end

  reaper.Undo_EndBlock("Move items right, preserving crossfade lengths",0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

-- @description Create a single region with name and tail length from selected items
-- @author Eddie Pacheco
-- @version 1.0
-- @about
--   # Create a single region with name and tail length from selected items
--
--   - LUA script by Eddie Pacheco 23-January-2020
--   - Modification of LUA script by SPK77 "Create regions (with tail) from selected items" 13-Sept-2015: http://forum.cockos.com/member.php?u=49553
--   - User is prompted to enter a valid non-negative numerical tail length in seconds
--   - User is prompted to enter a name for the created region


-- Prompt user to enter region tail length in seconds
function tail_length_prompt_box(title)
  local ret, retvals = reaper.GetUserInputs(title, 1, "Set tail length in seconds:", "1.0")
  if ret then
    return retvals
  end
  return ret
end

-- Prompt user to enter name for created region
function region_name_prompt_box(title)
  local ret, retvals = reaper.GetUserInputs(title, 1, "Enter region name:, extrawidth=250", "")
  if ret then
    return retvals
  end
  return ret
end

--[[
  * Validate tail length data submitted by user:
  * It must be possible to convert the tail length string to a number.
  * The number entered must be >= 0 in order to add tail length to the region.
  ]]
function verify_tail_length_data(tail_length)
  local data_type = tonumber(tail_length)
  if data_type ~= nil then
    if tonumber(tail_length) >= 0 then
      return true
      end
  else
    return false
  end
end

function create_region(reg_start, reg_end, name)
  local index = reaper.AddProjectMarker2(0, true, reg_start, reg_end, name, -1, 0)
end

function main()
  local item_count = reaper.CountSelectedMediaItems(0)
  local first_item = reaper.GetSelectedMediaItem(0, 0)
  local region_start_pos = reaper.GetMediaItemInfo_Value(first_item, "D_POSITION")
  local region_end_pos = 0

  if item_count == 0 then
    return
  end

  local tail_len = tail_length_prompt_box("Set tail length:")
  if not tail_len then
    return
  end

  local region_name = region_name_prompt_box("Enter region name:")
  if not region_name then
    return
  end

  for i = 1, reaper.CountSelectedMediaItems(0) do
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local item_end = item_pos + item_len

      -- The end pos of the region is the end pos of the item furthest down the timeline in the selection
      if region_end_pos < item_end then
        region_end_pos = item_end
      end
    end
  end

  -- Check to make sure we can convert the user input string to a number data type
  local tail_length_is_number = verify_tail_length_data(tail_len)

  if tail_length_is_number == true then
    create_region(region_start_pos, region_end_pos + tail_len, region_name)
  else
    reaper.ShowConsoleMsg("Please enter a non-negative number!")
  end

  reaper.Undo_OnStateChangeEx("Create single region with tail length from selected items", -1, -1)

end

reaper.defer(main)

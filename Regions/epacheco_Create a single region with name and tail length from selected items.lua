-- @description Create single region with tail length from selected items
-- @author Eddie Pacheco
-- @version 1.2
-- @changelog Decoupled several methods from main function. Updated nomenclature.
-- @about
--   # Create a single region with name and tail length from selected items
--
--   - LUA script by Eddie Pacheco. Udpated 17-January-2022.
--   - Modification of LUA script by SPK77 "Create regions (with tail) from selected items" 13-Sept-2015: http://forum.cockos.com/member.php?u=49553
--   - User is prompted to enter a valid non-negative numerical tail length in seconds
--   - User is prompted to enter a name for the created region

function region_data_prompt_box()
  local time_entered, region_name_entered = "", ""
  local b_valid_time_entered, entered_time_value = reaper.GetUserInputs( time_entered, 1, "Set region tail length in seconds:", "1.0" )

  if b_valid_time_entered then
    local b_valid_name_entered, entered_name_value = reaper.GetUserInputs( region_name_entered, 1, "Enter region name:, extrawidth=250", "" )
    if b_valid_name_entered then
      return entered_time_value, entered_name_value
    end
  end

  return b_valid_time_entered, b_valid_name_entered
end

function set_region_start_end_points( region_start_pos, region_end_pos )
  for i = 1, reaper.CountSelectedMediaItems( 0 ) do
    local media_item = reaper.GetSelectedMediaItem( 0, i-1 )
    if media_item ~= nil then
      local media_item_start_pos = reaper.GetMediaItemInfo_Value( media_item, "D_POSITION" )
      local media_item_length = reaper.GetMediaItemInfo_Value( media_item, "D_LENGTH" )
      local media_item_end_pos = media_item_start_pos + media_item_length

      if region_start_pos >= media_item_start_pos then
        region_start_pos = media_item_start_pos
      end

      if region_end_pos < media_item_end_pos then
        region_end_pos = media_item_end_pos
      end
    end
  end

  return region_start_pos, region_end_pos
end

function non_negative_number_check( tail_length_number )
  if tail_length_number ~= nil then
    if tail_length_number >= 0 then
      return true
    else
      return false
    end
  else
    return false
  end
end

function create_region( region_start_point, region_end_point, region_name )
  reaper.AddProjectMarker2( 0, true, region_start_point, region_end_point, region_name, -1, 0 )
end

function main()
  local media_item_quantity = reaper.CountSelectedMediaItems( 0 )
  if media_item_quantity == 0 then
    reaper.ShowConsoleMsg( "Please select one or more media items before running script." )
    return
  end

  local first_media_item = reaper.GetSelectedMediaItem( 0, 0 )
  local selected_media_start_pos = reaper.GetMediaItemInfo_Value( first_media_item, "D_POSITION" )
  local selected_media_end_pos = 0
  local b_tail_length_is_non_negative_number = false

  local new_region_tail_length_string, new_region_name = region_data_prompt_box()
  if new_region_tail_length_string == false then
    return
  end

  local new_region_start_pos, new_region_end_pos = set_region_start_end_points( selected_media_start_pos, selected_media_end_pos )

  local new_region_tail_length_number = tonumber( new_region_tail_length_string )

  b_tail_length_is_non_negative_number = non_negative_number_check( new_region_tail_length_number )
  if b_tail_length_is_non_negative_number then
    create_region( new_region_start_pos, new_region_end_pos + new_region_tail_length_number, new_region_name )
  else
    reaper.ShowConsoleMsg( "Please enter a non-negative number for the desired region tail length." )
  end

  reaper.Undo_OnStateChangeEx( "Create single region with tail length from selected items", -1, -1 )
end

reaper.defer( main )

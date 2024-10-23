-- @description Create single region with name prompt from selected items
-- @author Brunetton
-- @version 1
-- @changelog Decoupled several methods from main function. Updated nomenclature.
-- @about
--   # Create a single region with name prompt from selected items
--
--   - LUA script by Eddie Pacheco. Udpated 25-Fev-2022 by Bruno Duyé
--   - Modification of LUA script by SPK77 "Create regions (with tail) from selected items" 13-Sept-2015: http://forum.cockos.com/member.php?u=49553
--   - User is prompted to enter a name for the created region

function region_name_prompt_box()
  local region_name_entered = ""

  local b_valid_name_entered, entered_name_value = reaper.GetUserInputs( region_name_entered, 1, "Enter region name:, extrawidth=250", "" )
  if b_valid_name_entered then
    return entered_name_value
  else
    return false
  end

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
  local new_region_name = region_name_prompt_box()
  if new_region_name then
    local new_region_start_pos, new_region_end_pos = set_region_start_end_points( selected_media_start_pos, selected_media_end_pos )

    --   Region creation
    create_region( new_region_start_pos, new_region_end_pos, new_region_name )

    reaper.Undo_OnStateChangeEx( "Create single region from selected items", -1, -1 )
  end
end

reaper.defer( main )

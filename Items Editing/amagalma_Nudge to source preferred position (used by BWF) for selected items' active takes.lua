-- @description amagalma_Take: Nudge to source preferred position (used by BWF) for selected items' active takes
-- @author amagalma
-- @version 1.0
-- @about
--   # Nudges the active takes of the selected items to their source preferred position (used by BWF) without changing the items length and position
--   - Smart undo creation

----------------------------------------------------------------------------------------------

local reaper = reaper

function bwf_source_preferred_position(take) -- based on "PL9 - BWF Metadata Tool beta03.eel"
  if take and not reaper.TakeIsMIDI( take ) then
    local filenamebuf = reaper.GetMediaSourceFileName( reaper.GetMediaItemTake_Source( take ), "" )
    local file = io.open(filenamebuf, "rb")
    file:seek("cur", 4) -- riff_header
    local file_size_buf = file:read(4)
    local cur_pos = 8
    local file_size = string.unpack("I", file_size_buf, 1)
    local wave_header = file:read(4)
    cur_pos = cur_pos + 4
    if string.lower(wave_header) == "wave" then
      local bwf_data_found, bext_data_chunk = 0
      while (bwf_data_found == 0 and cur_pos < file_size) do
        local chunk_header = file:read(4)
        local chunk_size_buf = file:read(4)
        local chunk_size = string.unpack("I", chunk_size_buf, 1)
        cur_pos = cur_pos + 8
        if chunk_header ~= "bext" then
          file:seek("cur", chunk_size)
          cur_pos = cur_pos + chunk_size
        else -- bext found
          local chunk_data_buf = file:read(chunk_size)
          cur_pos = cur_pos + chunk_size
          bext_data_chunk = chunk_data_buf
          bwf_data_found = 1
        end      
      end
      if bwf_data_found == 1 then
        local bext_TimeRefLow = string.unpack("I", string.sub(bext_data_chunk, 339, 342))
        local bext_TimeRefHigh = string.unpack("I", string.sub(bext_data_chunk, 343, 346))
        -- return bext time offset / source preferred position in seconds
        return ((bext_TimeRefHigh * 4294967295) + bext_TimeRefLow)/reaper.GetMediaSourceSampleRate(reaper.GetMediaItemTake_Source(take))
      end
    end
    io.close(file)
  end
end

----------------------------------------------------------------------------------------------

local item_cnt = reaper.CountSelectedMediaItems( 0 )
local changed_items = false
if item_cnt > 0 then
  reaper.PreventUIRefresh( 1 )
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    local take = reaper.GetActiveTake( item )
    local bwf_pos = bwf_source_preferred_position(take)
    if take and bwf_pos then
      -- get source start position
      local item_pos = reaper.GetMediaItemInfo_Value( reaper.GetMediaItemTake_Item( take ), "D_POSITION" )
      local start_in_source = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
      local source_pos = item_pos - start_in_source
      if bwf_pos ~= source_pos then
        start_in_source = reaper.GetMediaItemTakeInfo_Value( take, "D_STARTOFFS" )
        item_pos = reaper.GetMediaItemInfo_Value( reaper.GetMediaItemTake_Item( take ), "D_POSITION" )
        reaper.SetMediaItemTakeInfo_Value( take, "D_STARTOFFS", start_in_source+source_pos-bwf_pos )
        changed_items = true
      end
    end
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end
-- Smart Undo Creation
if changed_items then
  reaper.Undo_OnStateChange( "Take: Nudge to source preferred position (used by BWF)" )
else
  reaper.MB( "Either all takes are already at their source preferred position, or they lack this kind of info." , "No items were changed", 0 )
  reaper.defer(function() end) -- No undo
end

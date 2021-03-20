-- @description Move items to synchronize with the TimeRef of the first selected item (BWF metadata)
-- @author Rodilab
-- @version 1.0
-- @about
--   Move all selected items (except the first one) to synchronize their TimeRef metadata with the TimeRef metadata of the first selected item.
--
--   by Rodrigo Diaz (aka Rodilab)

local function get_timeref(item)
  local take = reaper.GetActiveTake(item)
  if take then
    local source = reaper.GetMediaItemTake_Source(take)
    if reaper.GetMediaSourceType(source,"") == "WAVE" then
      local position = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
      local samplerate = reaper.GetMediaSourceSampleRate(source)
      local _, timeref = reaper.GetMediaFileMetadata(source,"BWF:TimeReference")
      if samplerate > 0 and timeref ~= "" then
        local startoffs = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")
        local real_timeref = timeref + startoffs
        local ref_offset = position - real_timeref
        return real_timeref, ref_offset
      end -- if samplerate and timeref
      error_1 = error_1 + 1
    end -- if source is WAVE
    error_1 = error_1 + 1
  end -- if take
  error_1 = error_1 + 1
end

local function main()
  local first_item = reaper.GetSelectedMediaItem(0,0)
  local _,ref_offset = get_timeref(first_item)
  if ref_offset then
    for i=1, count-1 do
      local item = reaper.GetSelectedMediaItem(0,i)
      local timeref,_ = get_timeref(item)
      if timeref then
        local new_position = timeref + ref_offset
        -- Move item
        if new_position >= 0 then
          reaper.SetMediaItemInfo_Value(item,"D_POSITION",new_position)
        else
          error_2 = error_2 + 1
        end
      end -- if real_timeref
    end -- for other items
  end -- if ref_offset
end

local function error_box()
  if error_1 + error_2 > 0 then
    local error_message = ""
    if error_1 > 0 then
      error_message = error_1.." items do not have the TimeReference matadatas for this action\n"
    end
    if error_2 > 0 then
      error_message = error_2.." items cannot be moved because the new position would be before the start of the project."
    end
    reaper.ShowMessageBox(error_message,script_name,0)
  end
end

error_1 = 0
error_2 = 0
script_name = "Move items to synchonize with the TimeRef of the first selected item"
count = reaper.CountSelectedMediaItems(0)
if count > 1 then
  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()
  main()
  reaper.Undo_EndBlock(script_name,0)
  reaper.PreventUIRefresh(-1)
  gfx.update()
  error_box()
end

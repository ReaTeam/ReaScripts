-- @description amagalma_Smart Crossfade
-- @author amagalma
-- @version 1.0
-- @about
--   # Crossfades selected items
--
--   - If items are adjacent then it creates a 10ms crossfade on the left side of the items' touch point
--   - If items overlap then it creates a crossfade at the overlapping area
--   - If there is a time selection covering part of both items, then it crossfades at the time selection area
--   - Can be used with as many items in different tracks as you like
--   - Smart undo point creation (only if there has been at least one crossfade)
--   - Requires SWS extensions

local reaper = reaper

crossfaded = false -- to be used for undo point creation
local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt > 1 then
  local selstart, selend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  for i = 1, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  local previousitem = reaper.GetSelectedMediaItem(0, i-1)
    -- check if item and previous item are on the same track
    if reaper.GetMediaItem_Track(item) == reaper.GetMediaItem_Track(previousitem) then
      local secondstart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local secondend = secondstart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local firststart = reaper.GetMediaItemInfo_Value(previousitem, "D_POSITION")
      local firstend = firststart + reaper.GetMediaItemInfo_Value(previousitem, "D_LENGTH")
      if firstend < secondstart then -- items do not touch
        --do nothing
      else
        crossfaded = true
        -- time selection exists and covers parts of both items
        if selstart ~= selend and selend >= secondstart and selstart <= firstend then
          local timesel = selend - selstart
          reaper.BR_SetItemEdges(previousitem, firststart, selend)
          reaper.BR_SetItemEdges(item, selstart, secondend)
          reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", timesel)
          reaper.SetMediaItemInfo_Value(previousitem, "D_FADEOUTLEN", timesel)
        else
          if firstend == secondstart then -- items are adjacent
            reaper.BR_SetItemEdges(item, secondstart - 0.01, secondend)
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0.01)
            reaper.SetMediaItemInfo_Value(previousitem, "D_FADEOUTLEN", 0.01)
          elseif firstend > secondstart then -- items are overlapping
            local overlap = firstend - secondstart
            reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", overlap)
            reaper.SetMediaItemInfo_Value(previousitem, "D_FADEOUTLEN", overlap)
          end  
        end
      end
    end  
  end
end

-- Undo point creation --
if not crossfaded then
  function NoUndoPoint() end
  reaper.defer(NoUndoPoint)
else
  reaper.Undo_OnStateChange("Smart Crossfade selected items")
  reaper.UpdateArrange()
end

-- @description amagalma_Smart Crossfade
-- @author amagalma
-- @version 1.21
-- @about
--   # Crossfades selected items
--
--   - If items are adjacent then it creates a 10ms crossfade on the left side of the items' touch point
--   - If items overlap then it creates a crossfade at the overlapping area
--   - If there is a time selection covering part of both items, then it crossfades at the time selection area
--   - Can be used with as many items in different tracks as you like
--   - Smart undo point creation (only if there has been at least one crossfade)
--   - You can set in the script if you want to keep the time selection or remove it
--   - You can set in the script if you want to keep selected the previously selected items or not

--[[
 * Changelog:
 * v1.21 (2017-09-04)
  + default crossfade shape: equal power
--]]


----------------------------------- USER SETTINGS -------------------------------------------------
                                                                                                 --
local keep_selected  = 1 -- Set to 1 if you want to keep the items selected (else unselect all)  --
local remove_timesel = 1 -- Set to 1 if you want to remove the time selection (else keep it)     --
                                                                                                 --
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------

local reaper = reaper
local sel_item = {}
local selstart, selend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local item_cnt = reaper.CountSelectedMediaItems(0)
local crossfaded = false -- to be used for undo point creation

---------------------------------------------------------------------------------------------------

local function FadeIn(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", 7)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", 0)
end

local function FadeOut(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", 7)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", 0)
end

---------------------------------------------------------------------------------------------------

if item_cnt > 1 then
  reaper.PreventUIRefresh(1)
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem(0, 0)
    sel_item[#sel_item+1] = item
    reaper.SetMediaItemSelected(item, false)
  end
  for i = 2, #sel_item do
    local item = sel_item[i]
    local previousitem = sel_item[i-1]
    -- check if item and previous item are on the same track
    if reaper.GetMediaItem_Track(item) == reaper.GetMediaItem_Track(previousitem) then
      local secondstart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      local firststart = reaper.GetMediaItemInfo_Value(previousitem, "D_POSITION")
      local firstend = firststart + reaper.GetMediaItemInfo_Value(previousitem, "D_LENGTH")
      if firstend < secondstart then -- items do not touch
        -- do nothing
      else
        crossfaded = true
        -- time selection exists and covers parts of both items
        if selstart ~= selend and selend >= secondstart and selstart <= firstend then
          timeselexists = 1
          local timesel = selend - selstart
          -- previous item
          reaper.SetMediaItemSelected(previousitem, true)
          reaper.ApplyNudge(0, 1, 3, 1, selend, 0, 0)
          FadeOut(previousitem, timesel)
          reaper.SetMediaItemSelected(previousitem, false)
          -- item
          reaper.SetMediaItemSelected(item, true)
          reaper.ApplyNudge(0, 1, 1, 1, selstart, 0, 0)
          FadeIn(item, timesel)
          reaper.SetMediaItemSelected(item, false)
        else
          if firstend == secondstart then -- items are adjacent
            reaper.SetMediaItemSelected(item, true)
            reaper.ApplyNudge(0, 1, 1, 1, secondstart - 0.01, 0, 0)
            FadeIn(item, 0.01)
            reaper.SetMediaItemSelected(item, false)
            FadeOut(previousitem, 0.01)        
          elseif firstend > secondstart then -- items are overlapping
            local overlap = firstend - secondstart
            FadeIn(item, overlap)
            FadeOut(previousitem, overlap)
          end  
        end
      end
    end  
  end
  reaper.PreventUIRefresh(-1)
end

-- Undo point creation ----------------------------------------------------------------------------
if crossfaded == false then
  function NoUndoPoint() end
  reaper.defer(NoUndoPoint)
else
  if keep_selected == 1 then -- keep selected the previously selected items
    for i = 1, #sel_item do
      reaper.SetMediaItemSelected(sel_item[i], true)
    end
  end
  if remove_timesel == 1 and timeselexists == 1 then -- remove time selection
    reaper.GetSet_LoopTimeRange(true, false, selstart, selstart, false)
  end
  reaper.Undo_OnStateChange("Smart Crossfade selected items")
  reaper.UpdateArrange()
end

-- @description amagalma_Smart Crossfade
-- @author amagalma
-- @version 1.26
-- @about
--   # Crossfades selected items
--
--   - If items are adjacent then it creates a crossfade (length defined by user) on the left side of the items' touch point
--   - If items overlap then it creates a crossfade at the overlapping area
--   - If there is a time selection covering part of both items, then it crossfades at the time selection area
--   - Can be used with as many items in different tracks as you like
--   - Smart undo point creation (only if there has been at least one change)
--   - You can set inside the script if you want to keep the time selection or remove it
--   - You can set inside the script if you want to keep selected the previously selected items or not
--   - Default crossfade length is set inside the script

--[[
 * Changelog:
 * v1.26 (2017-09-04)
  + undo point creation invludes time selection if it was requested to be removed after crossfading
--]]


----------------------------------- USER SETTINGS -------------------------------------------------
                                                                                                 --
local keep_selected  = 1 -- Set to 1 if you want to keep the items selected (else unselect all)  --
local remove_timesel = 1 -- Set to 1 if you want to remove the time selection (else keep it)     --
local xfadetime = 10 -- Set here default crossfade time in milliseconds                          --
                                                                                                 --
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------

local reaper = reaper
local sel_item = {}
local selstart, selend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local item_cnt = reaper.CountSelectedMediaItems(0)
local change = false -- to be used for undo point creation
local timeselexists, timesel_removed

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

local function FadeInOK(item, value)
  local ok = false
  if reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN") == value and
     reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE") == 7 and
     reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR") == 0
  then
    ok = true
  end
  return ok
end

local function FadeOutOK(item, value)
  local ok = false
  if reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN") == value and
     reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE") == 7 and
     reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR") == 0
  then
    ok = true
  end
  return ok
end

---------------------------------------------------------------------------------------------------

xfadetime = xfadetime*0.001
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
        -- time selection exists and covers parts of both items
        if selstart ~= selend and selend > secondstart and selstart < firstend then
          timeselexists = 1
          local timesel = selend - selstart
          if FadeInOK(item, timesel) == false or FadeOutOK(previousitem, timesel) == false then
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
            change = true
          end
        else
          if firstend == secondstart then -- items are adjacent
            if FadeInOK(item, xfadetime) == false or FadeOutOK(previousitem, xfadetime) == false then
              reaper.SetMediaItemSelected(item, true)
              reaper.ApplyNudge(0, 1, 1, 1, secondstart - xfadetime, 0, 0)
              FadeIn(item, xfadetime)
              reaper.SetMediaItemSelected(item, false)
              FadeOut(previousitem, xfadetime)
              change = true
            end       
          elseif firstend > secondstart then -- items are overlapping
            local overlap = firstend - secondstart
            if FadeInOK(item, overlap) == false or FadeOutOK(previousitem, overlap) == false then
              FadeIn(item, overlap)
              FadeOut(previousitem, overlap)
              change = true
            end
          end
        end
      end
    end
  end
  reaper.PreventUIRefresh(-1)
end

-- Undo point creation ----------------------------------------------------------------------------
if change == false then
  function NoUndoPoint() end
  reaper.defer(NoUndoPoint)
else
  if keep_selected == 1 then -- keep selected the previously selected items
    reaper.PreventUIRefresh(1)
    for i = 1, #sel_item do
      reaper.SetMediaItemSelected(sel_item[i], true)
    end
    reaper.PreventUIRefresh(-1)
  end
  if remove_timesel == 1 and timeselexists == 1 then -- remove time selection
    reaper.GetSet_LoopTimeRange(true, false, selstart, selstart, false)
    timesel_removed = 1
  end
  if timesel_removed == 1 then
    reaper.Undo_OnStateChangeEx("Smart Crossfade selected items", 4|8, -1)
  else
    reaper.Undo_OnStateChange("Smart Crossfade selected items")
  end
  reaper.UpdateArrange()
end

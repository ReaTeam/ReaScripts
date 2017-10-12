-- @description amagalma_Smart Crossfade
-- @author amagalma
-- @version 1.36
-- @about
--   # Crossfades selected items
--
--   - If items are adjacent then it creates a crossfade (length defined by user) on the left side of the items' touch point
--   - If items overlap then it creates a crossfade at the overlapping area
--   - If there is a time selection covering part of both items, then it crossfades at the time selection area (items do not have to touch necessarily)
--   - Can be used with as many items in different tracks as you like
--   - Smart undo point creation (only if there has been at least one change)
--   - You can set inside the script if you want to keep the time selection or remove it
--   - You can set inside the script if you want to keep selected the previously selected items or not
--   - Default crossfade length is set inside the script

--[[
 * Changelog:
 * v1.36 (2017-10-12)
  + small fix (again) when dealing with adjacent items
--]]


----------------------------------- USER SETTINGS -------------------------------------------------
                                                                                                 --
local keep_selected  = 1 -- Set to 1 if you want to keep the items selected (else unselect all)  --
local remove_timesel = 1 -- Set to 1 if you want to remove the time selection (else keep it)     --
local xfadetime = 10 -- Set here default crossfade time in milliseconds                          --
                                                                                                 --
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------

local reaper, math = reaper, math
local sel_item = {}
local selstart, selend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
local item_cnt = reaper.CountSelectedMediaItems(0)
local change = false -- to be used for undo point creation
local timeselexists, timesel_removed
local debug = false

---------------------------------------------------------------------------------------------------

local function FadeIn(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEINSHAPE", 7)
  reaper.SetMediaItemInfo_Value(item, "D_FADEINDIR", 0)
end

local function FadeOut(item, value)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", value)
  reaper.SetMediaItemInfo_Value(item, "C_FADEOUTSHAPE", 7)
  reaper.SetMediaItemInfo_Value(item, "D_FADEOUTDIR", 0)
end

local function FadeInOK(item, value)
  local ok = false
  if math.abs(reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN") - value) <= 0.001 and
     reaper.GetMediaItemInfo_Value(item, "C_FADEINSHAPE") == 7 and
     reaper.GetMediaItemInfo_Value(item, "D_FADEINDIR") == 0 and
     reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO") == 0
  then
    ok = true
  end
  return ok
end

local function FadeOutOK(item, value)
  local ok = false
  if math.abs(reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN") - value) <= 0.001 and
     reaper.GetMediaItemInfo_Value(item, "C_FADEOUTSHAPE") == 7 and
     reaper.GetMediaItemInfo_Value(item, "D_FADEOUTDIR") == 0 and
     reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO") == 0
  then
    ok = true
  end
  return ok
end

local function CrossfadeOK(item, previousitem, secondstart, firstend, xfadetime)
  local ok = false
  local prev_fadelen = reaper.GetMediaItemInfo_Value(previousitem, "D_FADEOUTLEN")
  local next_fadelen = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
  if prev_fadelen > 0 and next_fadelen == prev_fadelen and
     math.abs((firstend - prev_fadelen) - secondstart) <= 0.001
  then
    ok = true
  end
  return ok
end

---------------------------------------------------------------------------------------------------

xfadetime = xfadetime*0.001
if item_cnt > 1 then
  reaper.PreventUIRefresh(1)
  local trimstate = reaper.GetToggleCommandStateEx( 0, 41117) -- get Options: Toggle trim behind items state
  if trimstate == 1 then
    reaper.Main_OnCommand(41121, 0) -- Options: Disable trim behind items when editing
  end
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
      local secondend = secondstart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      local firststart = reaper.GetMediaItemInfo_Value(previousitem, "D_POSITION")
      local firstend = firststart + reaper.GetMediaItemInfo_Value(previousitem, "D_LENGTH")
      if firstend < secondstart - xfadetime and (selstart == selend or (firstend < selstart and secondstart > selend)) then
        -- items do not touch and there is no time selection covering parts of both items
        -- do nothing
        if debug then reaper.ShowConsoleMsg("not touch\n") end
      elseif firststart < secondstart and firstend > secondend then
        -- one item encloses the other
        -- do nothing
        if debug then reaper.ShowConsoleMsg("enclosure\n") end
      elseif selstart ~= selend and selend >= secondstart and selend <= secondend and selstart <= firstend and selstart >= firststart then
        -- time selection exists and covers parts of both items
        if debug then reaper.ShowConsoleMsg("inside time selection\n") end
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
      elseif secondstart >= firstend and secondstart <= firstend + xfadetime
        then -- items are adjacent (or there is a gap smaller or equal to the crossfade time)
        if debug then reaper.ShowConsoleMsg("adjacent\n") end
        if CrossfadeOK(item, previousitem, secondstart, firstend, xfadetime) == false then
          -- previous item (ensure it ends exactly at the start of the next item)
          reaper.SetMediaItemSelected(previousitem, true)
          reaper.ApplyNudge(0, 1, 3, 1, secondstart, 0, 0)
          FadeOut(previousitem, xfadetime)
          reaper.SetMediaItemSelected(previousitem, false)
          -- item
          reaper.SetMediaItemSelected(item, true)
          reaper.ApplyNudge(0, 1, 1, 1, secondstart - xfadetime, 0, 0)
          FadeIn(item, xfadetime)
          reaper.SetMediaItemSelected(item, false)
          change = true
        end
      elseif firstend > secondstart then -- items are overlapping
        local overlap = firstend - secondstart
        if debug then reaper.ShowConsoleMsg("overlap\n") end
        if FadeInOK(item, overlap) == false or FadeOutOK(previousitem, overlap) == false then
          FadeIn(item, overlap)
          FadeOut(previousitem, overlap)
          change = true
        end
      end
    end
  end
  if trimstate == 1 then
    reaper.Main_OnCommand(41120,0) -- Re-enable trim behind items (if it was enabled)
  end
end

-- Undo point creation ----------------------------------------------------------------------------
if change == false then
  -- do not loose item selection
  for i = 1, #sel_item do
    reaper.SetMediaItemSelected(sel_item[i], true)
  end
  reaper.PreventUIRefresh(-1)
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
    timesel_removed = 1
  end
  if timesel_removed == 1 then
    reaper.Undo_OnStateChangeEx("Smart Crossfade selected items", 4|8, -1)
  else
    reaper.Undo_OnStateChange("Smart Crossfade selected items")
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

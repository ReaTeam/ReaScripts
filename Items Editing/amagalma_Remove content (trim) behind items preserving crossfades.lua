-- @description amagalma_Remove content (trim) behind items preserving crossfades
-- @author amagalma
-- @version 1.0
-- @about
--   # Removes content behind selected items only if there is not a crossfade
--   - Undo point is created ony if something changed

-- @link: https://forum.cockos.com/showthread.php?p=1886294#post1886294

---------------------------------------------------------------------------------------

local reaper = reaper
local Selected_items = {}
local ToDelete = {}

---------------------------------------------------------------------------------------

function M(v)
  reaper.ShowConsoleMsg(tostring(v).."\n")
end

---------------------------------------------------------------------------------------

function Store_SelItems()
  local sel_item_cnt = reaper.CountSelectedMediaItems( 0 )
  if sel_item_cnt > 0 then
    -- Store selected items
    for i = 0, sel_item_cnt do
      local selitem = reaper.GetSelectedMediaItem( 0, i )
      Selected_items[#Selected_items+1] = selitem
    end
  end
end

---------------------------------------------------------------------------------------

Store_SelItems()
reaper.PreventUIRefresh( 1 )
-- Unselect selected items (Needed for ApplyNudge!!!)
for i = 1, #Selected_items do
  reaper.SetMediaItemSelected(Selected_items[i], false)
end
local create_undo = false
-- iterate selected items
for i = 1, #Selected_items do
  local Start = reaper.GetMediaItemInfo_Value( Selected_items[i], "D_POSITION" )
  local End = Start + reaper.GetMediaItemInfo_Value( Selected_items[i], "D_LENGTH" )
  local in_len = reaper.GetMediaItemInfo_Value( Selected_items[i], "D_FADEINLEN" )
  local in_time = Start + in_len
  local out_len = reaper.GetMediaItemInfo_Value( Selected_items[i], "D_FADEOUTLEN" )
  local out_time = End - out_len
  -- check all unselected items in track against selected item
  local track = reaper.GetMediaItem_Track( Selected_items[i] )
  local track_items_cnt = reaper.CountTrackMediaItems( track )
  for j = 0, track_items_cnt-1 do
    local item_ch = reaper.GetTrackMediaItem( track, j )
    local chStart = reaper.GetMediaItemInfo_Value( item_ch, "D_POSITION" )
    local chEnd = chStart + reaper.GetMediaItemInfo_Value( item_ch, "D_LENGTH" )
    local selected_ch = reaper.IsMediaItemSelected( item_ch )
    local in_len_ch = reaper.GetMediaItemInfo_Value( item_ch, "D_FADEINLEN" )
    local in_time_ch = chStart + in_len_ch
    local out_len_ch = reaper.GetMediaItemInfo_Value( item_ch, "D_FADEOUTLEN" )
    local out_time_ch = chEnd - out_len_ch
    -- do not compare item with itself, compare only with unselected items
    if item_ch ~= Selected_items[i] and not selected_ch then
      ---- Cases: ----
      -- checked item is contained
      if chStart >= Start and chEnd <= End then
        --M("checked item is contained")
        -- Store items in table for deletion after item iteration finishes
        ToDelete[#ToDelete+1] = {track = track, item = item_ch}
        create_undo = true
      -- checked item touches item's End and there is no crossfade
      elseif (in_len_ch ~= out_len or out_len == 0)and out_time >= in_time_ch and
              chStart >= Start and chStart < End and chEnd > End then
        --M("checked item touches item's End")
        reaper.SetMediaItemSelected(item_ch, true)
        reaper.ApplyNudge(0, 1, 1, 1, End, false, 0)
        reaper.SetMediaItemSelected(item_ch, false)
        -- remove fade in of trimmed item
        if out_time > in_time_ch and out_len > 0 and in_len_ch > 0 then
          reaper.SetMediaItemInfo_Value( item_ch, "D_FADEINLEN", 0 )
        end
        create_undo = true
      -- checked item touches item's Start and there is no crossfade
      elseif (out_len_ch ~= in_len or in_len == 0) and in_time <= out_time_ch and
              chEnd > Start and chEnd <= End and chStart < Start then
        --M("checked item touches item's Start")
        reaper.SetMediaItemSelected(item_ch, true)
        reaper.ApplyNudge(0, 1, 3, 1, Start, false, 0)
        reaper.SetMediaItemSelected(item_ch, false)
        -- remove fade out of trimmed item
        if in_time < out_time_ch and in_len > 0 and out_len_ch > 0 then
          reaper.SetMediaItemInfo_Value( item_ch, "D_FADEOUTLEN", 0 )
        end
        create_undo = true
      -- checked item encloses selected item
      elseif chStart < Start and chEnd > End then
        --M("checked item encloses selected item")
        local new_item = reaper.SplitMediaItem( item_ch, Start )
        reaper.SetMediaItemSelected(new_item, true)
        reaper.ApplyNudge(0, 1, 1, 1, End, false, 0)
        reaper.SetMediaItemSelected(new_item, false)
        create_undo = true
      -- checked item has nothing to do with selected item
      else
        --M("checked item has nothing to do with selected item")
        -- do nothing
      end
      ----------------
    end
  end
end

-- Delete items if needed --------------------------------
if #ToDelete > 0 then
  for i = 1, #ToDelete do
    reaper.DeleteTrackMediaItem( ToDelete[i].track, ToDelete[i].item )
  end
end

-- Re-select previously selected items -------------------
for i = 1, #Selected_items do
  reaper.SetMediaItemSelected(Selected_items[i], true)
end
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

-- Create undo only if at least one item has changed -----
if create_undo then
  reaper.Undo_OnStateChange2( 0, "Remove content (trim) behind items preserving crossfades" )
end

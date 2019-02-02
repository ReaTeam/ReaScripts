-- @description Remove visible content (trim) behind items
-- @author amagalma
-- @version 1.03
-- @about
--   # Removes content behind selected items only if the edit is visible in the arrange view
--   - No edits are done if they are not visible in the arrange view

-- @link: https://forum.cockos.com/showthread.php?p=1886294#post1886294

--[[
 Changelog:
 * v1.03 (2017-09-19)
  + when an item to be trimmed has a fade in/out, fade is removed after trimming
--]]

---------------------------------------------------------------------------------------

local reaper = reaper
local Selected_items = {}
local Sel_item_GUID = {}
local ToDelete = {}

---------------------------------------------------------------------------------------

local debug = 0
function M(v)
  if debug == 1 then
    reaper.ShowConsoleMsg(tostring(v).."\n")
  end
end

---------------------------------------------------------------------------------------

function Store_SelItems()
  local sel_item_cnt = reaper.CountSelectedMediaItems( 0 )
  if sel_item_cnt > 0 then
    -- Store selected items
    for i = 0, sel_item_cnt-1 do
      local selitem = reaper.GetSelectedMediaItem( 0, i )
      Selected_items[#Selected_items+1] = selitem
      local GUID = reaper.BR_GetMediaItemGUID( selitem )
      Sel_item_GUID[GUID] = true
    end
  end
end

---------------------------------------------------------------------------------------

Store_SelItems()
local Arrange_start, Arrange_end = reaper.GetSet_ArrangeView2( 0, false, 0, 0)
reaper.PreventUIRefresh( 1 )
local trimstate = reaper.GetToggleCommandStateEx( 0, 41117) -- get Options: Toggle trim behind items state
if trimstate == 1 then
  reaper.Main_OnCommand(41121, 0) -- Options: Disable trim behind items when editing
end
-- Unselect selected items (Needed for ApplyNudge!!!)
for i = 1, #Selected_items do
  reaper.SetMediaItemSelected(Selected_items[i], false)
end
local create_undo = false
-- iterate selected items
for i = 1, #Selected_items do
  --check if selected item's start is in view
  local StartIn, EndIn = false, false
  local Start = reaper.GetMediaItemInfo_Value( Selected_items[i], "D_POSITION" )
  local End = Start + reaper.GetMediaItemInfo_Value( Selected_items[i], "D_LENGTH" )
  local in_len = reaper.GetMediaItemInfo_Value( Selected_items[i], "D_FADEINLEN" )
  local in_time = Start + in_len
  local out_len = reaper.GetMediaItemInfo_Value( Selected_items[i], "D_FADEOUTLEN" )
  local out_time = End - out_len
  if Start > Arrange_start and Start < Arrange_end then
  StartIn = true
  end
  --check if selected item's end is in view
  if End > Arrange_start and End < Arrange_end then
  EndIn = true
  end
  -- check all items in track against selected item if sel item's Start and/or End is in view
  if StartIn or EndIn then
    local track = reaper.GetMediaItem_Track( Selected_items[i] )
    local track_items_cnt = reaper.CountTrackMediaItems( track )
    for j = 0, track_items_cnt-1 do
      local item_ch = reaper.GetTrackMediaItem( track, j )
      local chStart = reaper.GetMediaItemInfo_Value( item_ch, "D_POSITION" )
      local chEnd = chStart + reaper.GetMediaItemInfo_Value( item_ch, "D_LENGTH" )
      local selected_ch = Sel_item_GUID[reaper.BR_GetMediaItemGUID( item_ch )] or false
      -- do not compare item with itself, compare only with unselected items
      if item_ch ~= Selected_items[i] and not selected_ch then
        local in_len_ch = reaper.GetMediaItemInfo_Value( item_ch, "D_FADEINLEN" )
        local in_time_ch = chStart + in_len_ch
        local out_len_ch = reaper.GetMediaItemInfo_Value( item_ch, "D_FADEOUTLEN" )
        local out_time_ch = chEnd - out_len_ch     
        ---- Cases: ----
        -- checked item is contained
        if chStart >= Start and chEnd <= End then
          M("checked item is contained")
          -- Store items in table for deletion after item iteration finishes
          ToDelete[#ToDelete+1] = {track = track, item = item_ch}
          create_undo = true
        -- checked item touches item's End
        elseif EndIn and chStart >= Start and chStart < End and chEnd > End then
          M("checked item touches item's End")
          reaper.SetMediaItemSelected(item_ch, true)
          reaper.ApplyNudge(0, 1, 1, 1, End, false, 0)
          reaper.SetMediaItemSelected(item_ch, false)
          -- remove fade in of trimmed item
          reaper.SetMediaItemInfo_Value( item_ch, "D_FADEINLEN", 0 )
          create_undo = true
        -- checked item touches item's Start
        elseif StartIn and chEnd > Start and chEnd <= End and chStart < Start then
          M("checked item touches item's Start")
          reaper.SetMediaItemSelected(item_ch, true)
          reaper.ApplyNudge(0, 1, 3, 1, Start, false, 0)
          reaper.SetMediaItemSelected(item_ch, false)
          -- remove fade out of trimmed item
          reaper.SetMediaItemInfo_Value( item_ch, "D_FADEOUTLEN", 0 )
          create_undo = true
        -- checked item encloses selected item
        elseif chStart < Start and chEnd > End then
          M("checked item encloses selected item")
          local new_item = reaper.SplitMediaItem( item_ch, Start )
          reaper.SetMediaItemSelected(new_item, true)
          reaper.ApplyNudge(0, 1, 1, 1, End, false, 0)
          reaper.SetMediaItemSelected(new_item, false)
          create_undo = true
        -- checked item has nothing to do with selected item
        else
          M("checked item has nothing to do with selected item")
          -- do nothing
        end
        ----------------
      end
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
if trimstate == 1 then
  reaper.Main_OnCommand(41120,0) -- Re-enable trim behind items (if it was enabled)
end
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

-- Create undo only if at least one item has changed -----
if create_undo then
  reaper.Undo_OnStateChange2( 0, "Remove visible content (trim) behind items" )
end

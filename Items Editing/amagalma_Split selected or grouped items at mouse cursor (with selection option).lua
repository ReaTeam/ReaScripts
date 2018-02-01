-- @description amagalma_Split selected or grouped items at mouse cursor (with selection option)
-- @author amagalma
-- @version 1.0
-- @about
--   # Splits item under mouse cursor and selected items or grouped items (if none selected at mouse position)
--   - You can specify in the script if you want a change of selection by selecting left or right slpit items or not
--   - Smart undo point creation

--[[
 * Changelog:
 * v1.0 (2017-11-15)
  + replaces "amagalma_Split under mouse cursor (grouped items too) with selection option.lua"
--]]

----------------------------------------------------------------------------------------

local reaper = reaper
local items = {}
local split_selected, do_grouped = false, false

---------------------------- USER SETTINGS -------------------------------------
                                                                              --
local Selection = 0 -- enter 0: no change, 1: select left, 2: select right    --
                                                                              --
--------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

local item, pos = reaper.BR_ItemAtMouseCursor()
if item then
  items[1] = item
  -- find all items to be split
  local item_cnt = reaper.CountSelectedMediaItems( 0 )
  if item_cnt > 0 then -- find all relevant selected items
    for i = 0, item_cnt - 1 do
      local it = reaper.GetSelectedMediaItem( 0, i )
      local Start = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
      local End = Start + reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
      if it ~= item and Start < pos and pos < End then
        items[#items+1] = it
      end
    end
    if #items == 1 then 
      do_grouped = true
    else
      split_selected = true
    end
  end
  if item_cnt <= 1 or do_grouped then -- find all relevant grouped items
    local group = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
    item_cnt = reaper.CountMediaItems(0)
    for i = 0, item_cnt - 1 do
      local it = reaper.GetMediaItem(0, i)
      local group_it = reaper.GetMediaItemInfo_Value(it, "I_GROUPID")
      local Start = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
      local End = Start + reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
      if it ~= item and Start < pos and End > pos and group ~= 0 and group_it == group then
        items[#items+1] = it
      end
    end
  end
  --  split items
  reaper.PreventUIRefresh(1)
  local new_items = {}
  for i = 1 , #items do
    new_items[i] = reaper.SplitMediaItem( items[i], pos )
  end
  -- do selection
  if Selection == 1 then -- select left items
    for i = 1, #items do
      reaper.SetMediaItemSelected( items[i], true )
      reaper.SetMediaItemSelected( new_items[i], false )
    end
  elseif Selection == 2 then -- select right items
    for i = 1, #items do
      reaper.SetMediaItemSelected( items[i], false )
      reaper.SetMediaItemSelected( new_items[i], true )
    end
  end 
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
end

-- Undo Point Creation -----------------------------------------------------------------

if #items == 1 then
  reaper.Undo_OnStateChange( "Split item under mouse cursor" )
elseif split_selected then
  reaper.Undo_OnStateChange( "Split selected items at mouse cursor position" )
elseif not split_selected and #items > 1 then
  reaper.Undo_OnStateChange( "Split grouped items at mouse cursor position" )
else
  reaper.defer(function () end)
end

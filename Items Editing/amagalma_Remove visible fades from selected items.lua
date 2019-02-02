-- @description Remove visible fades from selected items
-- @author amagalma
-- @version 1.0
-- @about
--   # Removes fades from selected items only if they are visible in the arrange view
--   - No edits are done if they are not visible in the arrange view
--   - Undo point is created only if there has been a change

-- @link: https://forum.cockos.com/showthread.php?p=1886294#post1886294

---------------------------------------------------------------------------------------

local reaper = reaper
local Selected_items = {}
local create_undo = false

---------------------------------------------------------------------------------------

function Store_SelItems()
  local sel_item_cnt = reaper.CountSelectedMediaItems( 0 )
  if sel_item_cnt > 0 then
    -- Store selected items
    for i = 0, sel_item_cnt-1 do
      local selitem = reaper.GetSelectedMediaItem( 0, i )
      Selected_items[#Selected_items+1] = selitem
    end
  end
end

---------------------------------------------------------------------------------------

Store_SelItems()
if #Selected_items > 0 then
  local Arrange_start, Arrange_end = reaper.GetSet_ArrangeView2( 0, false, 0, 0)
  reaper.PreventUIRefresh( 1 )
  -- iterate selected items
  for i = 1, #Selected_items do
    local Start = reaper.GetMediaItemInfo_Value( Selected_items[i], "D_POSITION" )
    local End = Start + reaper.GetMediaItemInfo_Value( Selected_items[i], "D_LENGTH" )
    -- remove fade-in if visible
    if Start > Arrange_start and Start < Arrange_end then
      reaper.SetMediaItemInfo_Value( Selected_items[i], "D_FADEINLEN", 0 )
      reaper.SetMediaItemInfo_Value( Selected_items[i], "D_FADEINLEN_AUTO", -1 )
      create_undo = true
    end
    -- remove fade-out if visible
    if End > Arrange_start and End < Arrange_end then
      reaper.SetMediaItemInfo_Value( Selected_items[i], "D_FADEOUTLEN", 0 )
      reaper.SetMediaItemInfo_Value( Selected_items[i], "D_FADEOUTLEN_AUTO", -1 )
      create_undo = true
    end
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end

-- Create undo only if at least one item has changed -----
if create_undo then
  reaper.Undo_OnStateChange2( 0, "Remove visible fades from selected items" )
else
  reaper.defer(function () end)
end

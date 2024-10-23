-- @description Fill space between selected items with empty items
-- @author amagalma
-- @version 1.00
-- @link https://forum.cockos.com/showthread.php?t=248298
-- @donation https://www.paypal.me/amagalma
-- @about
--   #Fills the space between the selected items with empty items
--
--   Inside the script you can set if:
--   - the newly inserted items will be the only selected items
--   - the newly inserted items will have an empty take or be really empty items


-- USER SETTINGS ---------------------------------------------

-- to select only the newly inserted items set to true:
local select_new_items = false -- true/false

-- if true then newly inserted items have an empty take
local new_items_have_empty_take = false -- true/false

--------------------------------------------------------------


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt < 2 then return end

local prev_item = reaper.GetSelectedMediaItem( 0, 0 )
local prev_track = reaper.GetMediaItemTrack( prev_item )

local cnt = 0
local added = 0
local new_items = {}

for i = 0, item_cnt - 1 do
  cnt = cnt + 1
  local item = reaper.GetSelectedMediaItem( 0, i )
  local track = reaper.GetMediaItemTrack( item )
  if track == prev_track then
    if cnt > 1 then
      local st = reaper.GetMediaItemInfo_Value( prev_item, "D_POSITION") + reaper.GetMediaItemInfo_Value( prev_item, "D_LENGTH")
      local cur_st = reaper.GetMediaItemInfo_Value( item, "D_POSITION")
      if cur_st > st then
        local len = cur_st - st
        local new_item = reaper.AddMediaItemToTrack( track )
        reaper.SetMediaItemInfo_Value( new_item, "D_POSITION", st )
        reaper.SetMediaItemInfo_Value( new_item, "D_LENGTH", len )
        added = added + 1
        new_items[added] = new_item
      end
    end
  else
    prev_track = track
    cnt = 1
  end
  prev_item = item
end

if added > 0 then
  if select_new_items then
    for i = item_cnt - 1, 0, -1  do
      reaper.SetMediaItemSelected( reaper.GetSelectedMediaItem( 0, i ), false )
    end
    for i = 1, added do
      reaper.SetMediaItemSelected( new_items[i], true )
      if new_items_have_empty_take then
        reaper.AddTakeToMediaItem( new_items[i] )
      end
    end
  end
  reaper.Undo_OnStateChange( "Added ".. added .." empty item" ..
                          (added == 1 and "" or "s") .. " between selected items" )
else
  reaper.defer(function() end)
end

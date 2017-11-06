-- @description amagalma_Split under mouse cursor (grouped items too) with selection option
-- @author amagalma
-- @version 1.0
-- @about
--   # Splits item under mouse cursor and grouped or selected items
--   - You can specify in the script if you want a change of selection by selecting left or right slpit items or not

----------------------------------------------------------------------------------------

local reaper = reaper

---------------------------- USER SETTINGS -------------------------------------
                                                                              --
local Selection = 0 -- enter 0: no change, 1: select left, 2: select right    --
                                                                              --
--------------------------------------------------------------------------------

----------------------------------------------------------------------------------------

local item, pos = reaper.BR_ItemAtMouseCursor()
if item then
  reaper.PreventUIRefresh(1)
  -- split item under mouse
  local item_right = reaper.SplitMediaItem( item, pos )
  if Selection == 1 then
    if reaper.IsMediaItemSelected( item ) then
      reaper.SetMediaItemSelected( item_right, false )
    end
    reaper.SetMediaItemSelected( item, true )
  elseif Selection == 2 then
    if reaper.IsMediaItemSelected( item ) then
      reaper.SetMediaItemSelected( item, false )
    end
    reaper.SetMediaItemSelected( item_right, true )
  end
  -- split selected items
  local sel_item_cnt = reaper.CountSelectedMediaItems(0)
  for i = 0, sel_item_cnt-1 do
    local it = reaper.GetSelectedMediaItem(0, i)
    local it_right = reaper.SplitMediaItem( it, pos )
    if it_right and Selection == 1 then
      reaper.SetMediaItemSelected( it, true )
      reaper.SetMediaItemSelected( it_right, false )
    elseif it_right and Selection == 2 then
      reaper.SetMediaItemSelected( it_right, true )
      reaper.SetMediaItemSelected( it, false )
    end
  end
  -- split non selected grouped items
  local group = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
  if group ~= 0 then
    local item_cnt = reaper.CountMediaItems(0)
    for i = 0, item_cnt-1 do
      local it = reaper.GetMediaItem(0, i)
      if not reaper.IsMediaItemSelected( it ) then
        local it_right = reaper.SplitMediaItem( it, pos )
        if it_right and Selection == 1 then
          reaper.SetMediaItemSelected( it, true )
        elseif it_right and Selection == 2 then
          reaper.SetMediaItemSelected( it_right, true )
        end
      end
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange( "Split item(s) under mouse cursor" )
else
  reaper.defer(function () end)
end

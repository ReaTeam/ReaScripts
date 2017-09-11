-- @description amagalma_Implode shorter items as takes of one longer item on the same track
-- @author amagalma
-- @version 1.0
-- @about
--   # Implodes shorter items as takes of one longer item, maintaining splits and item colors
--   - All items must be on the same track
--   - Works for one long item and as many as you want shorter items to be embeded

-----------------------------------------------------------------------------------

local reaper = reaper
local items = {}
local lengths = {}
local ok

-----------------------------------------------------------------------------------

function maxkey(t)
  local key, max = 1, t[1]
  for k, v in ipairs(t) do
    if t[k] > max then
      key, max = k, v
    end
  end
  return key
end

-----------------------------------------------------------------------------------

local item_cnt = reaper.CountSelectedMediaItems(0)
-- store items, their length and their track for comparison
for i = 0, item_cnt-1 do
  local item =  reaper.GetSelectedMediaItem( 0, i )
  local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH" )
  items[i+1] = item
  lengths[i+1] = length
  if reaper.GetMediaItem_Track( item ) == reaper.GetMediaItem_Track( items[1] ) then
    ok = true
  else
    reaper.MB( "Selected items should be on the same track!", "Sorry, cannot run action :(", 0 )
    ok = false
    break
  end
end

-----------------------------------------------------------------------------------

if ok and item_cnt > 1 then
  local longest = maxkey(lengths)
  local longstart = reaper.GetMediaItemInfo_Value(items[longest], "D_POSITION" )
  local longend = longstart + lengths[longest]
  reaper.PreventUIRefresh( 1 )
  reaper.Undo_BeginBlock()
  for i = 1, #items do
    if items[i] ~= items[longest] then
      local shortstart = reaper.GetMediaItemInfo_Value(items[i], "D_POSITION" )
      local shortend = shortstart + reaper.GetMediaItemInfo_Value(items[i], "D_LENGTH" )
      local shortcolor =  reaper.GetDisplayedMediaItemColor( items[i] )
      if shortstart >= longstart and shortend <= longend then
        reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
        items[0] = items[longest]
        items[longest] = reaper.SplitMediaItem( items[longest], shortstart )
        items[0] = items[longest]
        items[longest] = reaper.SplitMediaItem( items[longest], shortend )
        reaper.SetMediaItemSelected(items[i], true )
        reaper.SetMediaItemSelected(items[0], true )
        reaper.Main_OnCommand(40543,0) -- Take: Implode items on same track into takes
        local newitem = reaper.GetSelectedMediaItem( 0, 0 )
        local lasttake =  reaper.GetMediaItemTake( newitem, reaper.CountTakes( newitem ) -1 )
        reaper.SetMediaItemTakeInfo_Value( lasttake, "I_CUSTOMCOLOR", shortcolor )
      end
    end
  end
  reaper.Main_OnCommand(40289,0) -- Item: Unselect all items
  reaper.Undo_EndBlock( "Implode items on same track into takes (embed shorter into longer)", 4|8 )
  reaper.PreventUIRefresh( -1 )
end

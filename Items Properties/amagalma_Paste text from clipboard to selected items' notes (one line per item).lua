-- @description Paste text from clipboard to selected items' notes (one line per item)
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma
-- @about Each selected item gets one line from the text in the clipboard. Helpful when using it with lyrics on empty items.


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return reaper.defer(function() end) end

local clip = reaper.CF_GetClipboard()
if clip == "" then return reaper.defer(function() end) end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh( 1 )
local l = 0
for line in clip:gmatch("[^\n]*") do
  local item = reaper.GetSelectedMediaItem( 0 , l )
  if item then
    reaper.GetSetMediaItemInfo_String( item, "P_NOTES", line, true )
    l = l + 1
  else
    break
  end
end
reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock( "Paste clipboard text to selected items", 4)

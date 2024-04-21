-- @description Convert empty items with notes to dedicated video processor item named after the notes
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then
  return reaper.defer(function() end)
end

local function ConvertEmptyItem( item )
  if reaper.GetActiveTake( item ) then return end
  local ok, notes = reaper.GetSetMediaItemInfo_String( item, "P_NOTES", "", false )
  if ok and notes ~= "" then
    local ok2, chunk = reaper.GetItemStateChunk( item, "", false )
    if ok2 then
      chunk = chunk:match("(.+)<NOTES.+") .. 'NAME "' .. notes ..
[["
FADEFLAG 1
VOLPAN 1 0 1 -1
SOFFS 0
PLAYRATE 1 1 0 -1 0 0.0025
CHANMODE 0
GUID ]] .. reaper.genGuid() .. [[

<SOURCE VIDEOEFFECT
<CODE
>
CODEPARM 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
>
>]]
      reaper.SetItemStateChunk( item, chunk, false )
    end
  end
end

----------

reaper.PreventUIRefresh( 1 )

for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0 , i )
  ConvertEmptyItem( item )
end

reaper.PreventUIRefresh( -1 )
reaper.Undo_OnStateChangeEx( "Convert empty items", 4, -1 )

-- @description Select all items in track that have exactly the same video processors as the selected item (unselect original item)
-- @author amagalma
-- @version 1.01
-- @changelog Support dedicated video processor items
-- @donation https://www.paypal.me/amagalma
-- @about Same action as the similarly named, but unselects the originally selected item


local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt ~= 1 then
  reaper.MB( "Please, choose just one item.", "Can't continue..", 0 )
  return
end


local function GetVideoFX( item )
  if not reaper.GetActiveTake( item ) then return 0, "" end
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local video_fx, v = {}, 0
  local src = chunk:match("<SOURCE VIDEOEFFECT.-CODEPARM .->")
  if src then
    v = v + 1
    video_fx[v] = src
  end
  for code in chunk:gmatch("<VIDEO_EFFECT.-CODEPARM .->") do
    v = v + 1
    video_fx[v] = code
  end
  return v, table.concat(video_fx, "\n")
end


local item = reaper.GetSelectedMediaItem( 0, 0 )
local fx_num, code = GetVideoFX( item )

if fx_num == 0 or code == "" then
  reaper.MB( "This item has no video processors.", "Can't continue..", 0 )
  return
end


reaper.PreventUIRefresh( 1 )

local track = reaper.GetMediaItemTrack( item )

for i = 0, reaper.CountTrackMediaItems( track )-1 do
  local tr_item = reaper.GetTrackMediaItem( track, i )
  if tr_item ~= item then
    local _, tr_code = GetVideoFX( tr_item )
    reaper.SetMediaItemSelected( tr_item, tr_code == code )
  end
end

reaper.SetMediaItemSelected( item, false )

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_OnStateChange( "Select items with same video processors (unselect original)" )

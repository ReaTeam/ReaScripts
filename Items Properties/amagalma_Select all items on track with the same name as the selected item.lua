-- @description Select all items on track with the same name as the selected item
-- @author amagalma
-- @version 1.00
-- @donation https://www.paypal.me/amagalma

local item_cnt = reaper.CountSelectedMediaItems( 0 )
if item_cnt == 0 then return end

local names_cnt = 0
local tracks, tr_cnt = {}, 0

for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local take = reaper.GetActiveTake( item )
  local name = reaper.GetTakeName( take )
  if name ~= "" then
    names_cnt = names_cnt + 1
    local track = reaper.GetMediaItemTrack( item )
    if not tracks[track] then
      tr_cnt = tr_cnt + 1
      tracks[track] = {}
    end
    if not tracks[track][name] then
      tracks[track][name] = true
    end
  end
end

if tr_cnt == 0 or names_cnt == 0 then return end

reaper.Undo_BeginBlock2( 0 )
reaper.PreventUIRefresh( 1 )
reaper.SelectAllMediaItems( 0, false )

for track, names in pairs(tracks) do
  for i = 0, reaper.CountTrackMediaItems( track )-1 do
    local it = reaper.GetTrackMediaItem( track, i )
    local tk = reaper.GetActiveTake( it )
    local nm = reaper.GetTakeName( tk )
    if names[nm] then reaper.SetMediaItemSelected( it, true ) end
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock2( 0, "Select items with the same name", 4 )

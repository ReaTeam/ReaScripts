-- @description Crossfade any overlapping items (even on different tracks)
-- @author amagalma
-- @version 1.1
-- @changelog fixed corner cases
-- @link https://forum.cockos.com/showthread.php?t=241104
-- @screenshot https://i.ibb.co/D7vyWhP/amagalma-Crossfade-any-overlapping-items-even-on-different-tracks.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Works like native "Item: Crossfade any overlapping items" but works on items that are on different tracks too.
--
--   Undo is created only if something changed.


local function eq( a, b )
  if math.abs(a - b) < 0.00001 then return true end
  return false
end

local items = {}
local item_cnt = reaper.CountSelectedMediaItems(0)
if item_cnt == 0 then
  return
end

for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local track = reaper.GetMediaItem_Track( item )
  local i_st = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local i_en = i_st + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  items[i+1] = {
    it = item,
    tr = track,
    st = i_st,
    en = i_en
  }
end

local undo = false
reaper.PreventUIRefresh( 1 )

table.sort(items, function(a,b)
  if eq(a.st, b.st) then
    return a.en < b.en
  else
    return a.st < b.st
  end
end)

for i = 1, #items-1 do
  local n = i + 1
  local overlap = items[i].en - items[n].st
  local enclosed = items[i].en - items[n].en
  if overlap > 0 and enclosed < 0 then
    local dif_track = items[i].tr ~= items[n].tr
    local fadein = dif_track and "D_FADEINLEN" or "D_FADEINLEN_AUTO"
    local fadeout = dif_track and "D_FADEOUTLEN" or "D_FADEOUTLEN_AUTO"
    reaper.SetMediaItemInfo_Value( items[i].it, fadeout, overlap )
    reaper.SetMediaItemInfo_Value( items[n].it, fadein, overlap )
    undo = true
  end
end

table.sort(items, function(a,b)
  if eq(a.en, b.en) then
    return a.st > b.st
  else
    return a.en > b.en
  end
end)

for i = 1, #items-1 do
  local n = i + 1
  local overlap = items[n].en - items[i].st
  local enclosed = items[n].st - items[i].st
  if overlap > 0 and enclosed < 0 then
    local dif_track = items[i].tr ~= items[n].tr
    local fadein = dif_track and "D_FADEINLEN" or "D_FADEINLEN_AUTO"
    local fadeout = dif_track and "D_FADEOUTLEN" or "D_FADEOUTLEN_AUTO"
    reaper.SetMediaItemInfo_Value( items[i].it, fadein, overlap )
    reaper.SetMediaItemInfo_Value( items[n].it, fadeout, overlap )
    undo = true
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()

if undo then
  reaper.Undo_OnStateChange2( 0, "Crossfade any overlapping items (even on different tracks)")
else
  reaper.defer(function() end)
end

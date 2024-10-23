-- @description Implode items across tracks into takes (keep splits)
-- @author amagalma
-- @version 1.05
-- @link https://forum.cockos.com/showthread.php?t=153354
-- @screenshot https://i.ibb.co/NYr9RbQ/Implode-items-across-tracks-into-takes.gif
-- @donation https://www.paypal.me/amagalma
-- @about Just like the native "Take: Implode items across tracks into takes" action but it keeps the splits


local item_cnt = reaper.CountSelectedMediaItems( 0 )
-- Do not proceed if no selected items
if item_cnt == 0 then return end

-- Get items' and tracks' info and make enumerate cuts
local first_track = reaper.GetMediaItem_Track( reaper.GetSelectedMediaItem( 0, 0 ) )
local track_counter = first_track
local track_id = 1
local tracks = {[1] = first_track}
local items = {}
local cuts = {}
for i = 0, item_cnt-1 do
  local item = reaper.GetSelectedMediaItem( 0, i )
  local st = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local len = reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  local en = st + len
  local parent = reaper.GetMediaItem_Track( item )
  if parent ~= track_counter then
    track_counter = parent
    track_id = track_id + 1
    tracks[track_id] = parent
  end
  items[i+1] = {item, st, en, track_id, parent, len}
  if not cuts[st] then
    cuts[st] = true
  end
  if not cuts[en] then
    cuts[en] = true
  end
end

-- Sort cuts by time
local t = {}
local c = 0
for position in pairs(cuts) do
  c = c + 1
  t[c] = position
end
cuts, t = t, nil
table.sort(cuts, function(a,b) return a < b end)

-- Do not proceed if not more than one track
if #tracks < 2 then return end


reaper.Undo_BeginBlock2( 0 )
reaper.PreventUIRefresh( 1 )

-- Split the items
local i = 1
while true do
  local name = reaper.GetTakeName( reaper.GetActiveTake( items[i][1] ) )
  for j = 1, #cuts do
    local new_item = reaper.SplitMediaItem( items[i][1], cuts[j] )
    if new_item then
      items[i][3] = cuts[j]
      items[#items+1] = {new_item, cuts[j], items[i][3], items[i][4],
                                              items[i][5], items[i][6]}
    end
  end
  i = i + 1
  if not items[i] then break end
end

-- Group items according to cuts
local groups = {}
for i = 1, #items do
  if not groups[items[i][2]] then
    groups[items[i][2]] = {}
  end
  groups[items[i][2]][items[i][4]] = items[i]
end

reaper.Main_OnCommand(40438, 0) -- Implode items across tracks into takes

-- Move all items to top track
for i = 0, reaper.CountSelectedMediaItems( 0 ) - 1 do
  local item = reaper.GetSelectedMediaItem( 0, i)
  local track = reaper.GetMediaItem_Track( item )
  if track ~= first_track then
    reaper.MoveMediaItemToTrack( item, first_track )
  end
end

reaper.PreventUIRefresh( -1 )
reaper.UpdateArrange()
reaper.Undo_EndBlock2( 0, "Implode items across tracks into takes, keep splits", 4 )

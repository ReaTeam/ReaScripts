-- @description Move edit cursor to next dubious or missing items crossfade on selected tracks
-- @author amagalma
-- @version 2.00
-- @changelog Complete re-write for better speed and fixed lanes support
-- @link https://forum.cockos.com/showthread.php?t=241010
-- @donation https://www.paypal.com/paypalme/amagalma
-- @about
--   - Moves the edit cursor to the next dubious or missing crossfade between two items on the selected tracks.
--   - Dubious crossfade is considered one whose duration is not the same as the overlap between the two items.
--   - A crossfade is considered missing if two items are adjacent or there is a very small gap between them and they do not crossfade.
--   - All playing fixed item lanes are taken into consideration
--   - The two items are automatically selected
--   - You can set inside the script the maximum gap duration between two "adjacent" items for them to be considered as requiring a crossfade. Default value is 100ms.

----------------------------------------------------------------------------------

-- SET HERE maximum allowed gap between items to be considered as "adjacent" (in seconds)
local max_gap = 0.1

----------------------------------------------------------------------------------

local track_cnt = reaper.CountSelectedTracks( 0 )
if track_cnt == 0 then 
  reaper.MB("Please, select one or more tracks.", "No track is selected!", 0)
  return reaper.defer(function () end)
end

local cur_pos = reaper.GetCursorPosition()
local bad_fade, bf_cnt = {}, 0
local abs = math.abs

----------------------------------------------------------------------------------

local function eq( a, b )
  return abs(a - b) < 0.00001
end

local function AddBadFade( prev_item, item )
  bf_cnt = bf_cnt + 1
  bad_fade[bf_cnt] = {
  items = { [prev_item.ptr] = true, [item.ptr] = true },
  time = item.start
  }
end

local function IsDubiousIntersection( prev_item, item )
  local overlap = prev_item.ending - item.start
  if overlap > 0.00001 then
  -- items overlap
    item.fadein = reaper.GetMediaItemInfo_Value( item.ptr, "D_FADEINLEN_AUTO" )
    if item.fadein == 0 then
      item.fadein = reaper.GetMediaItemInfo_Value( item.ptr, "D_FADEINLEN" )
    end
    prev_item.fadeout = reaper.GetMediaItemInfo_Value( prev_item.ptr, "D_FADEOUTLEN_AUTO" )
    if prev_item.fadeout == 0 then
      prev_item.fadeout = reaper.GetMediaItemInfo_Value( prev_item.ptr, "D_FADEOUTLEN" )
    end
    if (not eq(item.fadein, overlap)) or (not eq(prev_item.fadeout, overlap)) then
      AddBadFade( prev_item, item )
      return true
    end
  elseif abs(overlap) <= max_gap then
  -- items are less than max_space apart
    AddBadFade( prev_item, item )
    return true
  end
end


local function GetNextDubiousIntersection( track, wanted_lanes )
  -- wanted_lanes: leave unspecified to search in all fixed lanes
  local item_cnt = reaper.CountTrackMediaItems( track )
  if item_cnt == 0 then return end
  local lanes_to_search = {}
  if type(wanted_lanes) == "number" then
    lanes_to_search[wanted_lanes] = true
  else
    lanes_to_search = -1
  end
  local previous_item_in_lane = {}
  for it = 0, item_cnt-1 do
    local ptr = reaper.GetTrackMediaItem( track, it )
    local item = {
      ptr = ptr,
      lane = reaper.GetMediaItemInfo_Value( ptr, "I_FIXEDLANE" ),
      start = reaper.GetMediaItemInfo_Value( ptr, "D_POSITION" )
    }
    if item.start > cur_pos and previous_item_in_lane[item.lane] then
      if IsDubiousIntersection( previous_item_in_lane[item.lane], item ) then
        break
      end
    end
    if lanes_to_search == -1 or lanes_to_search[item.lane] then
      item.ending = item.start + reaper.GetMediaItemInfo_Value( item.ptr, "D_LENGTH" )
      previous_item_in_lane[item.lane] = item
    end
  end
end

----------------------------------------------------------------------------------

for tr = 0, track_cnt-1 do
  local track = reaper.GetSelectedTrack( 0, tr )
  local lane_cnt = reaper.GetMediaTrackInfo_Value( track, "I_NUMFIXEDLANES" )
  local wanted_lanes
  if lane_cnt > 1 then
    if reaper.GetMediaTrackInfo_Value( track, "C_ALLLANESPLAY" ) == 2 then
      wanted_lanes = {}
      for i = 0, lane_cnt-1 do
        local state = reaper.GetMediaTrackInfo_Value( track, string.format("C_LANEPLAYS:%i",i) )
        if state == 1 then
          wanted_lanes = i
          break
        elseif state == 2 then
          wanted_lanes[i] = true
        end
      end
    end
  end
  GetNextDubiousIntersection( track, wanted_lanes )
end

if bf_cnt > 1 then
  table.sort( bad_fade, function( a, b )
    if eq( a.time, b.time ) then
      for item in pairs(b.items) do
        a.items[item] = true
      end
      return true
    else
      return a.time < b.time
    end
  end)
end

if bad_fade[1] then
  reaper.PreventUIRefresh( 1 )
  reaper.SetEditCurPos( bad_fade[1].time, true, false )
  reaper.SelectAllMediaItems( 0, false )
  for item in pairs(bad_fade[1].items) do
    reaper.SetMediaItemSelected( item, true )
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
  reaper.Undo_OnStateChange( "Move to next dubious item intersection" )
else  
  return reaper.defer(function() end)
end

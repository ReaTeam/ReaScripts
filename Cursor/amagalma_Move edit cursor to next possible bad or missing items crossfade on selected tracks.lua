-- @description Move edit cursor to next possible bad or missing items crossfade on selected tracks
-- @author amagalma
-- @version 1.06
-- @changelog Automatic crossfades should get priority over manual ones
-- @link https://forum.cockos.com/showthread.php?t=241010
-- @donation https://www.paypal.com/paypalme/amagalma
-- @about
--   - Moves the edit cursor to the next possible bad or missing crossfade between two items on the selected tracks.
--   - A possible bad crossfade is considered one whose duration is not the same as the overlap between the two items.
--   - A crossfade is considered missing if two items are adjacent or there is a very small gap between them and they do not crossfade.
--   - You can set inside the script the maximum gap duration between two "adjacent" items for them to be considered as requiring a crossfade. Default value is 100ms.

---------------------------------------------------------------

-- SET HERE maximum space between "adjacent" items that should be checked for crossfades (in seconds)
local max_space = 0.1

---------------------------------------------------------------

local track_cnt = reaper.CountSelectedTracks( 0 )
if track_cnt == 0 then 
  reaper.MB("Please, select a track.", "No track is selected!", 0)
  return reaper.defer(function () end)
end

local function eq( a, b )
  if math.abs(a - b) < 0.00001 then return true end
  return false
end

local GetVal = reaper.GetMediaItemInfo_Value

local cur_pos = reaper.GetCursorPosition()
local bad_fade = {}
local bf = 0

for tr = 0, track_cnt-1 do
  local track = reaper.GetSelectedTrack( 0, tr )
  local item_cnt = reaper.CountTrackMediaItems( track )
  if item_cnt > 1 then
    for it = 0, item_cnt-2 do
      local item = reaper.GetTrackMediaItem( track, it )
      local item_end = GetVal( item, "D_POSITION" ) + GetVal( item, "D_LENGTH" )
      local next_item = reaper.GetTrackMediaItem( track, it+1 )
      local next_item_start = GetVal( next_item, "D_POSITION" )
      local overlap = item_end - next_item_start
      if overlap <= 0 and overlap >= -max_space then
      -- items are less than max_space apart
        bf = bf + 1
        bad_fade[bf] = item_end
      elseif overlap > 0 then
      -- items overlap
        local next_item_fadein = GetVal( next_item, "D_FADEINLEN_AUTO" )
        if eq(next_item_fadein, 0) then
          next_item_fadein = GetVal( next_item, "D_FADEINLEN" )
        end
        local item_fadeout = GetVal( item, "D_FADEOUTLEN_AUTO" )
        if eq(item_fadeout, 0) then
          item_fadeout = GetVal( item, "D_FADEOUTLEN" )
        end
        if (not eq(next_item_fadein, overlap)) or (not eq(item_fadeout, overlap)) then
          bf = bf + 1
          bad_fade[bf] = next_item_start
        end
      end
    end
  else
    reaper.MB("Please, select a track with more than one item.", "Not enough items!", 0)
    return reaper.defer(function () end)
  end
end

-- Move edit cursor
if #bad_fade > 0 then
  table.sort(bad_fade)
  for i = 1, #bad_fade do
    if bad_fade[i] > cur_pos then
      reaper.SetEditCurPos( bad_fade[i], true, false )
      break
    end
  end
else
  reaper.MB("No problematic or missing crossfades.", "All OK!", 0)
end
reaper.defer(function () end)

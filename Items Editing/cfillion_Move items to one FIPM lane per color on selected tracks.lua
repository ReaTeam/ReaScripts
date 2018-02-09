-- @description Move items to one FIPM lane per color on selected tracks
-- @version 1.0
-- @author cfillion
-- @website
--   cfillion.ca https://cfillion.ca
--   Request Post https://forum.cockos.com/showthread.php?p=1951990
-- @screenshot https://i.imgur.com/uGN9Qy5.gif
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD
-- @about
--   This script moves every items in the selected tracks to different FIPM lanes
--   according to the item's color.

local scriptName = ({reaper.get_action_context()})[2]:match('([^/\\_]+)%.lua$')

function normalize(color)
  -- ensure OS-independent color encoding (so that the lane order is always the same)
  local r, g, b = reaper.ColorFromNative(color)
  return r<<16 | g<<8 | b
end

function makeLanes(items)
  local colors = {}
  for color, _ in pairs(items) do
    table.insert(colors, color)
  end
  table.sort(colors)

  local lanes = {}
  for _, color in ipairs(colors) do
    table.insert(lanes, items[color])
  end
  return lanes
end

local bucket = {}

for ti=0,reaper.CountSelectedTracks(0)-1 do
  local track = reaper.GetSelectedTrack(0, ti)
  local items = {}

  if reaper.GetMediaTrackInfo_Value(track, 'B_FREEMODE') ~= 1 then
    reaper.SetMediaTrackInfo_Value(track, 'B_FREEMODE', 1)
  end

  for ii=0,reaper.CountTrackMediaItems(track)-1 do
    local item = reaper.GetTrackMediaItem(track, ii)
    local color = normalize(reaper.GetMediaItemInfo_Value(item, 'I_CUSTOMCOLOR'))

    if not items[color] then
      items[color] = {}
    end

    table.insert(items[color], item)
  end

  local lanes = makeLanes(items)
  if #lanes > 0 then
    table.insert(bucket, lanes)
  end
end

if #bucket < 1 then
  reaper.defer(function() end)
  return
end

reaper.Undo_BeginBlock()

for _, lanes in ipairs(bucket) do
  local h = 1 / #lanes

  for lane, items in ipairs(lanes) do
    for _, item in ipairs(items) do
      reaper.SetMediaItemInfo_Value(item, 'F_FREEMODE_Y', h * (lane - 1))
      reaper.SetMediaItemInfo_Value(item, 'F_FREEMODE_H', h)
    end
  end
end

reaper.UpdateTimeline()
reaper.Undo_EndBlock(scriptName, -1)

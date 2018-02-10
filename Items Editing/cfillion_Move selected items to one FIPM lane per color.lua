-- @description Move selected items to one FIPM lane per color
-- @version 1.0
-- @author cfillion
-- @website
--   cfillion.ca https://cfillion.ca
--   Request Post https://forum.cockos.com/showthread.php?p=1951990
-- @screenshot https://i.imgur.com/uGN9Qy5.gif
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD
-- @provides
--   .
--   . > cfillion_Move selected items to one FIPM lane per color (preserve height).lua
-- @about
--   This script moves selected items to different FIPM lanes according to the its color.

local scriptName = ({reaper.get_action_context()})[2]:match('([^/\\_]+)%.lua$')
local preserveHeight = scriptName:match('preserve')

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

local tracks = {}

for ii=0,reaper.CountSelectedMediaItems(0)-1 do
  local item = reaper.GetSelectedMediaItem(0, ii)
  local track = reaper.GetMediaItemTrack(item)

  if not tracks[track] then
    tracks[track] = {}

    if reaper.GetMediaTrackInfo_Value(track, 'B_FREEMODE') ~= 1 then
      reaper.SetMediaTrackInfo_Value(track, 'B_FREEMODE', 1)
    end
  end

  local color = normalize(reaper.GetMediaItemInfo_Value(item, 'I_CUSTOMCOLOR'))

  if not tracks[track][color] then
    tracks[track][color] = {}
  end

  table.insert(tracks[track][color], item)
end

local bucket = {}

for _, items in pairs(tracks) do
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
  local laneHeight = 1 / #lanes
  local y = 0

  for lane, items in ipairs(lanes) do
    for _, item in ipairs(items) do
      reaper.SetMediaItemInfo_Value(item, 'F_FREEMODE_Y', y)

      if not preserveHeight then
        reaper.SetMediaItemInfo_Value(item, 'F_FREEMODE_H', laneHeight)
      end
    end

    if preserveHeight then
      local largest = 0

      for _, item in ipairs(items) do
        largest = math.max(largest, reaper.GetMediaItemInfo_Value(item, 'F_FREEMODE_H'))
      end

      y = y + largest
    else
      y = laneHeight * lane
    end
  end
end

reaper.UpdateTimeline()
reaper.Undo_EndBlock(scriptName, -1)

-- @description Normalize peaks display gain
-- @version 1.0
-- @author cfillion
-- @website cfillion.ca https://cfillion.ca
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Normalize+peaks+display+gian
-- @screenshot https://i.imgur.com/UA2iB5m.gif
-- @metapackage
-- @provides
--   [main] . > cfillion_Normalize peaks display gain (scan all items).lua
--   [main] . > cfillion_Normalize peaks display gain (scan selected items).lua
--   [main] . > cfillion_Normalize peaks display gain (scan selected tracks).lua
-- @about
--   This package provides actions to automatically adjust the per-project
--   peaks display gain setting depending on the item contents.
--
--   It can scan every items in the project, items on selected tracks, or only
--   selected items.

local function find(t, e)
  for k, v in ipairs(t) do
    if v == e then return k end
  end

  return nil
end

-- arguments: the getter function followed by the arguments it takes
-- x is replaced with the index of the thing to get
local x = {}
local function iteratize(...)
  local args = {...}
  a = args
  local func = table.remove(args, 1)
  local indexPos = assert(find(args, x), 'cannot find x in the iterator arguments')

  local i = -1
  return function()
    i = i + 1
    args[indexPos] = i
    return func(table.unpack(args))
  end
end

local getItem = {
  ['all items']=iteratize(reaper.GetMediaItem, 0, x),
  ['selected items']=iteratize(reaper.GetSelectedMediaItem, 0, x),
  ['selected tracks']=(function()
    local selTrackIter = iteratize(reaper.GetSelectedTrack, 0, x)
    local track, itemIter

    local function nextTrack()
      track = selTrackIter()
      itemIter = track and iteratize(reaper.GetTrackMediaItem, track, x)
    end

    nextTrack()

    return function()
      while track do
        local item = itemIter()

        if item then
          return item
        else
          nextTrack()
        end
      end
    end
  end)(),
}

-- config vars can't be undone so don't create a useless undo point...
reaper.defer(function() end)

local mode, gainFactor = ({reaper.get_action_context()})[2]:match("%(scan (.-)%)%.lua$")

for item in getItem[mode] do
  local maxPeak = -reaper.NF_GetMediaItemMaxPeak(item)
  local itemFactor = 10 ^ (maxPeak / 20)

  if not gainFactor or gainFactor > itemFactor then
    gainFactor = itemFactor
  end
end

if gainFactor then
  gainFactor = math.max(1, gainFactor)
  reaper.SNM_SetDoubleConfigVar('projpeaksgain', gainFactor)
  reaper.UpdateArrange()
end

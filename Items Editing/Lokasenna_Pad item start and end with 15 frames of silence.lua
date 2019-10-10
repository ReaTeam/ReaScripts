--[[
    Description: Pad item start and end with 15 frames of silence
    Version: 1.0.0
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Initial Release
    Links:
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:

    Donation: https://www.paypal.me/Lokasenna
]]--

local function getFrameLength()
  local rate = reaper.TimeMap_curFrameRate(0)
  return 1/rate
end

local function getSelectedItems()
  local items = {}

  local idx = 0
  while true do
    local item = reaper.GetSelectedMediaItem(0, idx)
    if not item then break end

    items[#items + 1] = item
    idx = idx + 1
  end

  return items
end

local function selectOnlyItems(items)
  reaper.SelectAllMediaItems(0, false)

  for _, item in pairs(items) do
    reaper.SetMediaItemSelected(item, true)
  end
end

local function createItem(track, position, length)
  local item = reaper.AddMediaItemToTrack(track)
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", position)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", length)

  return item
end


local function Main()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  local padLength = 15 * getFrameLength()

  local selectedItems = getSelectedItems()
  if #selectedItems == 0 then return end

  local itemsOut = {}

  for _, item in pairs(selectedItems) do
    -- Clear the selection
    reaper.SelectAllMediaItems(0, false)

    local track = reaper.GetMediaItem_Track(item)
    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local itemEnd = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") + itemStart

    local itemPre = createItem(track, itemStart - padLength, padLength)
    local itemPost = createItem(track, itemEnd, padLength)

    -- Glue them
    reaper.SetMediaItemSelected(item, true)
    reaper.SetMediaItemSelected(itemPre, true)
    reaper.SetMediaItemSelected(itemPost, true)
    reaper.Main_OnCommand(41588, 0)

    itemsOut[#itemsOut + 1] = reaper.GetSelectedMediaItem(0, 0)
  end

  selectOnlyItems(itemsOut)

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Pad items with 15 frames of silence", -1)
end

Main()

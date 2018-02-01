-- @description Set item end to cursor and resize trailing MIDI notes
-- @author cfillion
-- @version 1.0.1
-- @changelog Avoid creating zero-length items when cursor is at the item's start
-- @website
--   cfillion.ca https://cfillion.ca/
--   Request Thread https://forum.cockos.com/showthread.php?t=199045
-- @donate https://www.paypal.me/cfillion
-- @about
--   Similar to the native "Item: Set item end to cursor" action except for these differences:
--
--   - MIDI takes are resized
--   - Note touching the item end are resized

function extendMIDI(take, from, to)
  local index = 0

  from = reaper.MIDI_GetPPQPosFromProjTime(take, from)
  to = reaper.MIDI_GetPPQPosFromProjTime(take, to)

  while true do
    local retval, _, _, startppqpos, endppqpos = reaper.MIDI_GetNote(take, index)
    if not retval then break end

    if startppqpos <= from and endppqpos >= from then
      reaper.MIDI_SetNote(take, index, nil, nil, nil, to)
    end

    index = index + 1
  end

  reaper.MIDI_Sort(take)
end

function extendItem(item, to)
  local start = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local from = start + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local resized = false

  if start >= to then return end

  for takeIndex = 0, reaper.CountTakes(item) - 1 do
    local take = reaper.GetMediaItemTake(item, takeIndex)

    if reaper.TakeIsMIDI(take) then
      if not resized then
        reaper.MIDI_SetItemExtents(item,
          reaper.TimeMap_timeToQN(start), reaper.TimeMap_timeToQN(to))
        resized = true
      end

      extendMIDI(take, from, to)
    end
  end

  if not resized then
    -- item is not a MIDI item
    local newLen = to - start
    reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', newLen)
  end
end

local selItems = reaper.CountSelectedMediaItems(0)
local cursorPos = reaper.GetCursorPosition()

if selItems < 1 then
  reaper.defer(function() end) -- disable implicit undo point
  return
end

reaper.Undo_BeginBlock()

for itemIndex = 0, selItems - 1 do
  local item = reaper.GetSelectedMediaItem(0, itemIndex)
  extendItem(item, cursorPos)
end

local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")
local UNDO_STATE_ITEMS = 4 -- track items
reaper.Undo_EndBlock(name, UNDO_STATE_ITEMS)

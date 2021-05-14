-- @description Select the item with highest or lowest pitch
-- @author cfillion
-- @version 1.0.1
-- @changelog Don't crash when there are no items in the current project
-- @metapackage
-- @provides
--   [main] . > cfillion_Select the item with highest pitch.lua
--   [main] . > cfillion_Select the item with lowest pitch.lua
-- @link Request thread https://forum.cockos.com/showpost.php?p=2442421
-- @donation https://reapack.com/donate
-- @about Installs two actions for selecting only the item with highest/lowest pitch. Other items are unselected.

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

local compare = script_name:find('highest') and
  function(a, b) return a > b end or
  function(a, b) return a < b end

local item_count, get_item = reaper.CountSelectedMediaItems(nil)
if item_count > 0 then
  get_item = reaper.GetSelectedMediaItem
else
  item_count = reaper.CountMediaItems(nil)
  get_item = reaper.GetMediaItem
end

local items, winner = {}
for i = 0, item_count - 1 do
  local item = get_item(nil, i)
  local take = reaper.GetActiveTake(item)
  local pitch = reaper.GetMediaItemTakeInfo_Value(take, 'D_PITCH')
  if not winner or compare(pitch, winner.pitch) then
    winner = { item=item, pitch=pitch }
  end
  table.insert(items, item)
end

reaper.Undo_BeginBlock()

if winner then
  for _, item in ipairs(items) do
    if item ~= winner.item then
      reaper.SetMediaItemSelected(item, false)
    end
  end

  reaper.SetMediaItemSelected(winner.item, true)
end

reaper.UpdateArrange()
reaper.Undo_EndBlock(script_name, 0)

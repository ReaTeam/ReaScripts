-- @description Group selected items vertically (optionally color randomly each group)
-- @author amagalma
-- @version 1.1
-- @changelog
--   - Items whose position is less than 1ms apart get aligned
--   - Smart undo creation
--   - Maximized speed
--   - Changed name description
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Groups selected items in different tracks vertically if they are aligned and optionally randomly colors each group
--
--   - You can specify in the script if you want each group to be randomly colored
--   - Items whose position is less than 1ms apart get aligned
--   - Smart undo creation


--------------------- USER SETTINGS ----------------------
--                                                      --
-- Set to 1 if you want random colors or 0 if you don't --
--                                                      --
-------------------------                               --
local RandomColors = 0 --                               --
-------------------------                               --
----------------------------------------------------------


----------------------------------------------------------------------------------

if reaper.CountSelectedMediaItems(0) == 0 then return end

local undo = false
local positions = {}
local giveColor = RandomColors == 1

local random = math.random
local floor = math.floor

local function RandomColor()
  return reaper.ColorToNative( random(255), random(255), random(255) )
end


-- Get info
local MaxGroupID = 0
for i = 0, reaper.CountMediaItems(0) - 1 do
  local item = reaper.GetMediaItem(0, i)
  local item_group_id = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
  if item_group_id > MaxGroupID then
    MaxGroupID = item_group_id
  end
  if reaper.IsMediaItemSelected( item ) then
    local pos = floor(reaper.GetMediaItemInfo_Value(item, "D_POSITION")*1000 + 0.5)*0.001
    if not positions[pos] then positions[pos] = {{}, 0} end
    positions[pos][2] = positions[pos][2] + 1
    positions[pos][1][positions[pos][2]] = item
  end
end

-- Do the thing
reaper.PreventUIRefresh(1)
for _, t in pairs(positions) do
  if t[2] ~= 1 then
    MaxGroupID = MaxGroupID + 1
    local color
    if giveColor then
      color = RandomColor()
    end
    if not undo then undo = true end
    for i = 1, t[2] do
      local item = t[1][i]
      reaper.SetMediaItemInfo_Value(item, "I_GROUPID", MaxGroupID)
      if color then
        reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color|0x1000000)
      end
    end
  end
end
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

-- Undo if required
if undo then
  reaper.Undo_OnStateChange("Group selected items vertically")
else
  reaper.defer(function() end)
end

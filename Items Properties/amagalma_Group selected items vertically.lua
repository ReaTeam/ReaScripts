-- @description Group selected items vertically (optionally color randomly each group)
-- @author amagalma
-- @version 1.3
-- @changelog
--   - You can specify in the script how much two values can differ when they are being compared for equality (default: round to ms)
--   - You can specify in the script if you want item ends to coincide too, for items to be grouped (default: yes, reverted to v1.0 behavior)
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Groups selected items in different tracks vertically, if they are aligned, and optionally colors randomly each group
--
--   - You can specify in the script if you want each group to be colored randomly (default: no)
--   - You can specify in the script if you want item ends to coincide too, for items to be grouped (default: yes)
--   - You can specify in the script how much two values can differ when they are being compared for equality (default: round to ms)
--   - Smart undo creation

--------------------- USER SETTINGS ---------------------------

-- Set to 1 if you want random colors or 0 if you don't
  local RandomColors = 0

-- If set to 1 then for items to group their ends must coincide
  local item_ends_must_coincide = 1

--[[ 
  Sets the amount of rounding between two compared values
  before they get compared for equality.
  0 = round to seconds, 1 = round to 1/10 of a second
  2 = round to 1/100 of a second, 3 = round to 1/1000 etc
  Range of valid values: 0-7 
--]]
  local strictness_of_equality = 3

---------------------------------------------------------------


----------------------------------------------------------------------------------

if reaper.CountSelectedMediaItems(0) == 0 then return end

local undo = false
local positions = {}
local giveColor = RandomColors == 1
local item_ends_must_coincide = item_ends_must_coincide == 1
if strictness_of_equality < 0 then
  strictness_of_equality = 0
elseif strictness_of_equality > 7 then
  strictness_of_equality = 7
end
local mult = 10^strictness_of_equality
local div = 10^(-strictness_of_equality)

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
    local pos = floor(reaper.GetMediaItemInfo_Value(item, "D_POSITION")*mult + 0.5)*div
    if item_ends_must_coincide then
      local len = floor(reaper.GetMediaItemInfo_Value(item, "D_LENGTH")*mult + 0.5)*div
      pos = pos .. len
    end
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

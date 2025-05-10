-- @description Toggle Group
-- @author Grayson Solis
-- @version 1.0
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes
-- @about
--   TOGGLE GROUPING BEHAVIOR:
--
--   If you select:
--       - All ungrouped items → it groups them together.
--       - All grouped items (same group or not) → it ungroups them.
--       - A mix of grouped and ungrouped items → it adds the ungrouped ones to the existing group.



----------------------------------------------------------------------------------------
-- BEGIN UNDO BLOCK
----------------------------------------------------------------------------------------

reaper.Undo_BeginBlock()

----------------------------------------------------------------------------------------
-- GET SELECTED ITEMS AND CHECK GROUP STATUS
----------------------------------------------------------------------------------------

local sel_count = reaper.CountSelectedMediaItems(0)
if sel_count == 0 then return end  -- Exit if nothing is selected

local group_id = nil              -- Will store the first found group ID
local has_grouped = false         -- True if any item is already grouped
local has_ungrouped = false       -- True if any item is not grouped

for i = 0, sel_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local id = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")

    if id > 0 then
        has_grouped = true
        group_id = group_id or id  -- Store the first group ID found
    else
        has_ungrouped = true
    end
end

----------------------------------------------------------------------------------------
-- HANDLE GROUPING LOGIC BASED ON SELECTION STATE
----------------------------------------------------------------------------------------

-- CASE 1: Mix of grouped and ungrouped items → Add ungrouped items to the group
if has_grouped and has_ungrouped then
    for i = 0, sel_count - 1 do
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "I_GROUPID", group_id)
    end

-- CASE 2: All items are grouped → Ungroup them
elseif has_grouped and not has_ungrouped then
    for i = 0, sel_count - 1 do
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "I_GROUPID", 0)
    end

-- CASE 3: All items are ungrouped → Group them with a new ID
else
    local new_id = reaper.GetProjectStateChangeCount(0) + 1
    for i = 0, sel_count - 1 do
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "I_GROUPID", new_id)
    end
end

----------------------------------------------------------------------------------------
-- FINALIZE
----------------------------------------------------------------------------------------

reaper.UpdateArrange()
reaper.Undo_EndBlock("Toggle Grouping", -1)


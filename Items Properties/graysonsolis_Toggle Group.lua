-- @description Toggle Group
-- @author Grayson Solis
-- @version 1.0
-- @screenshot Example: https://imgur.com/flmEK6P
-- @about
--   TOGGLE GROUPING BEHAVIOR:
--
--   If you select:
--       - All ungrouped items -> it groups them together.
--       - All grouped items (same group or not) -> it ungroups them.
--       - A mix of grouped and ungrouped items -> it adds the ungrouped ones to the existing group.

reaper.Undo_BeginBlock()

local sel_count = reaper.CountSelectedMediaItems(0)
if sel_count == 0 then return end 

local group_id = nil             
local has_grouped = false        
local has_ungrouped = false   

for i = 0, sel_count - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local id = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")

    if id > 0 then
        has_grouped = true
        group_id = group_id or id
    else
        has_ungrouped = true
    end
end

if has_grouped and has_ungrouped then
    for i = 0, sel_count - 1 do
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "I_GROUPID", group_id)
    end

elseif has_grouped and not has_ungrouped then
    for i = 0, sel_count - 1 do
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "I_GROUPID", 0)
    end

else
    local new_id = reaper.GetProjectStateChangeCount(0) + 1
    for i = 0, sel_count - 1 do
        reaper.SetMediaItemInfo_Value(reaper.GetSelectedMediaItem(0, i), "I_GROUPID", new_id)
    end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Toggle Grouping", -1)


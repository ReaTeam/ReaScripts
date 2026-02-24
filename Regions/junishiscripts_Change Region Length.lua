-- @description Change Region Length
-- @author Junishi Scripts
-- @version 1.0
-- @about
--   This REAPER Lua script allows you to **extend or shorten the length of regions** within the currently selected time range by a user-specified number of seconds.  
--   It is especially useful for batch editing multiple regions without manually adjusting each one.
--
--   ### Features
--   - Simple GUI input to enter the number of seconds (positive to extend, negative to shorten)
--   - Only affects regions entirely within the current time selection
--   - Automatically skips regions that would become zero or negative in length
--
--   ### Usage
--   1. Select a time range in REAPER where the target regions are located.
--   2. Run the script.
--   3. Enter the number of seconds to extend or shorten.
--   4. The script adjusts the length of all regions within the selected time range accordingly.

-- @description My Script
-- @version 1.0
-- @author 1496jun
-- @changelog
--   Initial release
-- @provides
--   [main] Scripts/ChangeRegionLength.lua




-- Prompt user to input seconds in GUI
local ret, user_input = reaper.GetUserInputs("Change Region Length", 1, "Seconds to extend/shorten (e.g. 2, -1.5)", "")

if not ret then return end

local delta = tonumber(user_input)
if not delta then
    reaper.ShowMessageBox("Invalid number input.", "Error", 0)
    return
end

-- Begin undo block
reaper.Undo_BeginBlock()

-- Get time selection
local timeSelStart, timeSelEnd = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

-- Scan project markers and regions
local numMarkers, numRegions = reaper.CountProjectMarkers(0)

local count_changed = 0

for i = 0, numMarkers + numRegions - 1 do
    local retval, isrgn, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
    if isrgn and pos >= timeSelStart and rgnend <= timeSelEnd then
        local newEnd = rgnend + delta
        if newEnd > pos then
            reaper.SetProjectMarkerByIndex(0, i, true, pos, newEnd, markrgnindexnumber, name, color)
            count_changed = count_changed + 1
        else
            reaper.ShowMessageBox("Skipped region due to non-positive length: " .. name, "Warning", 0)
        end
    end
end

reaper.Undo_EndBlock("Changed Region Lengths (" .. count_changed .. " modified)", -1)
reaper.UpdateArrange()


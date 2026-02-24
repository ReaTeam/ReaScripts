-- @description Update region start to playhead position by ID
-- @author Edson Del Santoro
-- @version 1.2
-- @changelog v1.2 Update region start to playhead position by ID
-- @about
--   # Update region start to playhead position by ID
--
--   --   # Update region start to playhead position by ID
--   --   This script updates the start time of a region specified by its ID (as shown in the Region/Marker Manager). 
--   --   It keeps the region's end time intact and adjusts only the start.
--
--   1. Set the playhead to the start position that you want.
--   2. Execute this script.
--   3. Enter the Region ID that you want to update Start timming.
--
--   That's it.


SCRIPT_NAME = "Update region start to playhead position by ID"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable) .. "\n")
end

-- Get playhead position
playhead_position = reaper.GetCursorPosition()

-- Get total number of markers and regions
retval, num_markers, num_regions = reaper.CountProjectMarkers(0)

if num_regions == 0 then
  reaper.ShowMessageBox("No regions found in the project.", SCRIPT_NAME, 0)
  return
end

-- Ask the user for the ID of the region to update
retval, user_input = reaper.GetUserInputs(SCRIPT_NAME, 1, "Enter Region ID (as shown in Region/Marker Manager):", "")
if not retval or user_input == "" then return end

region_id = tonumber(user_input)

if region_id == nil or region_id < 0 then
  reaper.ShowMessageBox("Invalid Region ID. Please enter a valid number.", SCRIPT_NAME, 0)
  return
end

-- Find the region with the matching ID
selected_region = nil
for i = 0, num_markers + num_regions - 1 do
  retval, isrgn, rgn_start, rgn_end, rgn_name, rgn_index = reaper.EnumProjectMarkers(i)
  
  if isrgn and rgn_index == region_id then
    selected_region = {rgn_start = rgn_start, rgn_end = rgn_end, rgn_name = rgn_name, rgn_index = rgn_index, region_marker_index = i}
    break
  end
end

if selected_region == nil then
  reaper.ShowMessageBox("No region found with ID " .. region_id .. ". Please check the Region/Marker Manager.", SCRIPT_NAME, 0)
  return
end

-- Update region start time
new_start = playhead_position
rgn_end = selected_region.rgn_end
region_marker_index = selected_region.region_marker_index
rgn_name = selected_region.rgn_name

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

reaper.SetProjectMarkerByIndex(0, region_marker_index, true, new_start, rgn_end, selected_region.rgn_index, rgn_name, 0)

-- End undo-block
reaper.Undo_EndBlock2(0, SCRIPT_NAME, -1)

reaper.UpdateArrange()
reaper.ShowMessageBox("Region '" .. rgn_name .. "' (ID " .. region_id .. ") start updated to playhead position.", SCRIPT_NAME, 0)

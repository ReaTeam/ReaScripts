-- @description Export Track names to Channel List CSV
-- @author wikylepedia
-- @version 1.0
-- @changelog Initial upload, hope it's useful to others!
-- @provides [main=main,mediaexplorer] .
-- @about
--   # wikylepedia's Export Track names to Channel List CSV
--
--   A simple little script to export the channels you've named in REAPER to a CSV file, to help create pre-production technical documentation such as a rider for immersive live events or spatial audio mix downs.
--
--   Created in support of the LISO240 Digital Production Implementation course at dBs Institute

-- Get the current project
local proj_index = 0
local proj = reaper.EnumProjects(proj_index)

-- Get project name and path
local retval, project_name = reaper.GetSetProjectInfo_String(proj, "PROJECT_NAME", "", false)
local proj_path = reaper.GetProjectPath("")

-- Check if we have a valid project path
if proj_path == "" then
  reaper.ShowMessageBox("Please save your project first.", "Error", 0)
  return
end

-- Extract the directory from the project path
local dir_path = proj_path:match("(.*[/\\])")

-- Use a default name if project_name is empty
if project_name == "" then
  project_name = "Untitled_Project"
else
  -- Remove file extension from project name if present
  project_name = project_name:gsub("%.rpp$", "")
end

-- Create the CSV file path with project name and "track_names" appended
local file_name = project_name .. "channel_list.csv"
local file_path = dir_path .. file_name

-- Open the file for writing
local file = io.open(file_path, "w")
if not file then
  reaper.ShowMessageBox("Unable to open file for writing. Check permissions.", "Error", 0)
  return
end

-- Write CSV headers
file:write("Track Number,Track Name\n")

-- Loop through all tracks in the project
for i = 0, reaper.CountTracks(0) - 1 do
  local track = reaper.GetTrack(0, i)
  local _, track_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
  
  -- Write track number and name to the CSV file
  file:write((i + 1) .. "," .. '"' .. (track_name or "") .. '"' .. "\n")
end

-- Close the file
file:close()

-- Notify user of success
reaper.ShowMessageBox("Track names exported successfully to:\n" .. file_path, "Success", 0)


-- @description Select All Tracks (Ignore Collapsed State)
-- @author Grayson Solis
-- @version 1.0
-- @provides . > graysonsolis_Select all tracks (ignore collapsed state).lua
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes
-- @about
--   This script selects all tracks in the current REAPER, even collapsed ones
--
--   ----------------------------------------------------------------------------------------
--   USE CASE
--   ----------------------------------------------------------------------------------------
--   This is extremely useful when:
--   - You want to apply a global operation (like changing track heights, coloring, grouping).
--   - You need to ensure all tracks are selected for custom scripts or extensions.
--   - You are building macros and want to select all tracks without visually disrupting your workflow.
--
--   Particularly helpful when editing large projects with many tracks — it selects everything
--   without causing visible lag in the UI.
--
--   ----------------------------------------------------------------------------------------
--   BEHAVIOR
--   ----------------------------------------------------------------------------------------
--   - Disables UI refresh to avoid performance issues.
--   - Loops through all tracks and selects them one-by-one.
--   - Restores UI refresh afterward.



----------------------------------------------------------------------------------------
-- MAIN OPERATION
----------------------------------------------------------------------------------------

reaper.PreventUIRefresh(1)  -- Freeze UI to prevent redraw lag

for i = 0, reaper.CountTracks(0) - 1 do
  local tr = reaper.GetTrack(0, i)
  reaper.SetTrackSelected(tr, true)  -- Select each track
end

reaper.PreventUIRefresh(-1) -- Restore UI redraw

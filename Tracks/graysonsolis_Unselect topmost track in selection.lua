-- @description Unselect Topmost Track in Selection
-- @author Grayson Solis
-- @version 1.0
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes
-- @about
--   This script will unselect the topmost (first) track from the current selection,
--   but only if more than one track is selected.
--
--   ----------------------------------------------------------------------------------------
--   USE CASE
--   ----------------------------------------------------------------------------------------
--   When you want to quickly exclude the parent or top-most track from a multi-track
--   selection (e.g., apply actions only to child tracks), run this to unselect the
--   first track automatically.
--
--   ----------------------------------------------------------------------------------------
--   BEHAVIOR
--   ----------------------------------------------------------------------------------------
--   - Checks if more than one track is selected.
--   - If so, identifies the topmost (index 0) selected track.
--   - Deselects that track.


----------------------------------------------------------------------------------------
-- MAIN SCRIPT
----------------------------------------------------------------------------------------

-- Only proceed if more than one track is selected
if reaper.CountSelectedTracks(0) > 1 then
    -- Get the first selected track (topmost)
    local topmostTrack = reaper.GetSelectedTrack(0, 0)
    -- Deselect it
    reaper.SetTrackSelected(topmostTrack, false)
end

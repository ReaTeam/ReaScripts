-- @description Unselect Topmost Track in Selection
-- @author Grayson Solis
-- @version 1.0
-- @about
--   - Checks if more than one track is selected.
--   - If so, identifies the topmost (index 0) selected track.
--   - Deselects that track.

-- Only proceed if more than one track is selected
if reaper.CountSelectedTracks(0) > 1 then
    -- Get the first selected track (topmost)
    local topmostTrack = reaper.GetSelectedTrack(0, 0)
    -- Deselect it
    reaper.SetTrackSelected(topmostTrack, false)
end

-- @description Unselect Topmost Track in Selection
-- @author Grayson Solis
-- @version 1.0
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes


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

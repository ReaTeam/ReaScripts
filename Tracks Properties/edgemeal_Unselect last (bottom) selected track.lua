-- @description Unselect last (bottom) selected track
-- @author Edgemeal
-- @version 1.0
-- @link Forum Thread https://forum.cockos.com/showpost.php?p=2337148&postcount=2108
-- @donation Donate https://www.paypal.me/Edgemeal

local num_tracks = reaper.CountSelectedTracks(0)
if num_tracks > 0 then
  reaper.SetTrackSelected(reaper.GetSelectedTrack(0, num_tracks-1), false)
  reaper.TrackList_AdjustWindows(false)
end
reaper.defer(function () end)

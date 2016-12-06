-- @description Toggle track FX bypass by name
-- @version 1.0
-- @author cfillion
-- @link http://forum.cockos.com/showthread.php?t=184623
-- @screenshot
--   Basic Usage http://i.imgur.com/ryIg1j9.gif
--   Undo Points https://i.imgur.com/dtNwlsn.png
-- @about
--   # Toggle track FX bypass by name
--
--   This script asks for a string to match against all track FX in the current
--   project. The search is case insensitive. Bypass is toggled for all matching
--   FXs. Undo points are consolidated into one.

local ok, filter = reaper.GetUserInputs("Toggle track FX bypass by name", 1,
  "Toggle track FX bypass matching:,extrawidth=100", "")

if not ok or filter:len() < 1 then
  reaper.defer(function() end) -- no undo point if nothing to do
  return
end

filter = filter:lower()

reaper.Undo_BeginBlock()

for ti=0,reaper.CountTracks()-1 do
  local track = reaper.GetTrack(0, ti)

  for fi=0,reaper.TrackFX_GetCount(track)-1 do
    local _, fxname = reaper.TrackFX_GetFXName(track, fi, '')
    if fxname:lower():find(filter) then
      reaper.TrackFX_SetEnabled(track, fi,
        not reaper.TrackFX_GetEnabled(track, fi))
    end
  end
end

reaper.Undo_EndBlock(
  string.format("Toggle track FX bypass matching '%s'", filter), -1)

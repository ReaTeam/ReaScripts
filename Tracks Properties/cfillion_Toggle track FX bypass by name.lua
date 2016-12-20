-- @description Toggle track FX bypass by name
-- @version 1.1
-- @changelog Add track filter feature (by name or selection)
-- @author cfillion
-- @link http://forum.cockos.com/showthread.php?t=184623
-- @screenshot
--   Basic Usage https://i.imgur.com/jVgwbi3.gif
--   Undo Points https://i.imgur.com/dtNwlsn.png
-- @about
--   # Toggle track FX bypass by name
--
--   This script asks for a string to match against all track FX in the current
--   project. The search is case insensitive. Bypass is toggled for all matching
--   FXs. Undo points are consolidated into one.

if not reaper.GetTrackName then
  -- for REAPER prior to v5.30 (native GetTrackName returns "Track N" when it's empty)
  function reaper.GetTrackName(track, _)
    return reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
  end
end

function matchTrack(track, filter)
  if filter == '/selected' then
    return reaper.IsTrackSelected(track)
  else
    local _, name = reaper.GetTrackName(track, '')
    return name:lower():find(filter)
  end
end

local defaultTrackFilter = ''
if reaper.CountSelectedTracks() > 0 then
  defaultTrackFilter = '/selected'
end

local ok, csv = reaper.GetUserInputs("Toggle track FX bypass by name", 2,
  "Toggle track FX bypass matching:,On tracks (name or /selected):,extrawidth=100",
  ',' .. defaultTrackFilter)

if not ok or csv:len() < 1 then
  reaper.defer(function() end) -- no undo point if nothing to do
  return
end

local fx_filter, track_filter = csv:match("^(.*),(.*)$")
fx_filter, track_filter = fx_filter:lower(), track_filter:lower()

reaper.Undo_BeginBlock()

for ti=0,reaper.CountTracks()-1 do
  local track = reaper.GetTrack(0, ti)

  if matchTrack(track, track_filter) then
    for fi=0,reaper.TrackFX_GetCount(track)-1 do
      local _, fx_name = reaper.TrackFX_GetFXName(track, fi, '')
      if fx_name:lower():find(fx_filter) then
        reaper.TrackFX_SetEnabled(track, fi,
          not reaper.TrackFX_GetEnabled(track, fi))
      end
    end
  end
end

reaper.Undo_EndBlock(
  string.format("Toggle track FX bypass matching '%s'", fx_filter), -1)

-- @description Bypass all input FX for selected tracks
-- @version 1.0
-- @author cfillion
-- @link http://forum.cockos.com/showthread.php?t=185229

reaper.Undo_BeginBlock()

for ti=0,reaper.CountSelectedTracks()-1 do
  local track = reaper.GetSelectedTrack(0, ti)
  for fi=0,reaper.TrackFX_GetRecCount(track) do
    fi = fi + 0x1000000
    reaper.TrackFX_SetEnabled(track, fi,
      not reaper.TrackFX_GetEnabled(track, fi))
  end
end

reaper.Undo_EndBlock('Bypass all input FX for selected tracks', -1)

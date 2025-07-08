-- @description List FX parameter indices
-- @author Grayson Solis
-- @version 1.0
-- @about
--   Prints each FX on the first selected track along with all of its parameter indices.
--
--   Directions:
--     1) Select a track in REAPER.
--     2) Run this script.
--     3) Open the ReaScript Console (View → Show Console) to see the output.

local track = reaper.GetSelectedTrack(0, 0)
if not track then
  reaper.ShowMessageBox(
    "Error: No track selected.\nPlease select a track and run again.",
    "No Track Selected",
    0
  )
  return
end

reaper.ClearConsole()
local _, trackName = reaper.GetTrackName(track, "")
reaper.ShowConsoleMsg("FX parameter indices for track: " .. trackName .. "\n\n")

local fxCount = reaper.TrackFX_GetCount(track)
if fxCount == 0 then
  reaper.ShowConsoleMsg("  (No FX found on this track.)\n")
  return
end

for fx_idx = 0, fxCount - 1 do
  local _, fxName = reaper.TrackFX_GetFXName(track, fx_idx, "")
  fxName = fxName or "(Unknown FX name)"
  reaper.ShowConsoleMsg(string.format("FX #%d: \"%s\"\n", fx_idx, fxName))

  local paramCount = reaper.TrackFX_GetNumParams(track, fx_idx)
  if paramCount == 0 then
    reaper.ShowConsoleMsg("  (No parameters for this FX)\n\n")
  else
    for param_idx = 0, paramCount - 1 do
      local _, paramName = reaper.TrackFX_GetParamName(track, fx_idx, param_idx, "")
      paramName = paramName or "(Unknown param name)"
      reaper.ShowConsoleMsg(
        string.format("    Param %d  →  \"%s\"\n", param_idx, paramName)
      )
    end
    reaper.ShowConsoleMsg("\n")
  end
end

reaper.ShowConsoleMsg("→ End of list.\n")

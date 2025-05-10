-- @description Monitor On when Midi Instrument Loaded
-- @author Grayson Solis
-- @version 1.0
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes
-- @about
--   This script automatically enables input monitoring (Record Monitoring ON) for all tracks
--   that contain virtual instruments. It runs continuously and updates in real-time as tracks
--   are added or modified.
--
--   Make this a global startup action! I highly recommend checking out Amely Suncrolls global startup actions.
--
--   ----------------------------------------------------------------------------------------
--   USE CASE
--   ----------------------------------------------------------------------------------------
--   Ensures any track with a VSTi is always
--   audible without manually enabling monitoring.
--
--   ----------------------------------------------------------------------------------------
--   BEHAVIOR
--   ----------------------------------------------------------------------------------------
--   - Continuously checks all tracks in the project.
--   - If a track contains an instrument plugin and monitoring is OFF:
--       - Turns monitoring ON automatically.
--   - Skips tracks without instrument FX.
--   - Runs in a loop using reaper.defer().


----------------------------------------------------------------------------------------
-- MAIN FUNCTION
----------------------------------------------------------------------------------------

function check_monitor()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)

    -- Check if the track has an instrument plugin
    if reaper.TrackFX_GetInstrument(tr) ~= -1 then

      -- If monitoring is not enabled, enable it
      if reaper.GetMediaTrackInfo_Value(tr, "I_RECMON") ~= 1 then
        reaper.SetMediaTrackInfo_Value(tr, "I_RECMON", 1)
      end
    end
  end

  -- Continue running in the background
  reaper.defer(check_monitor)
end

----------------------------------------------------------------------------------------
-- START SCRIPT LOOP
----------------------------------------------------------------------------------------

check_monitor()

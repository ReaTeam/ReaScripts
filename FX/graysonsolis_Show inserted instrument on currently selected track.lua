-- @description Show Inserted Instrument on Currently Selected Track
-- @author Grayson Solis
-- @version 1.0
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes
-- @about
--   This script attempts to open the instrument plugin window (floating) on the currently selected track.
--   If no instrument is found or its window doesn't open, it falls back to opening the regular FX chain window.
--
--   ----------------------------------------------------------------------------------------
--   USE CASE
--   ----------------------------------------------------------------------------------------
--   Useful when:
--   - You want a one-click way to always pull up the main sound source on a selected track.
--   - You're working with virtual instruments (VSTi) and need fast access to tweak synths, samplers, etc.
--
--
--   Note: Assign this to a double click mouse modifier for the track! 
--   - For me, I double click the track and it opens an instrument for me to pick when its empty, and gives me access to the current instrument when I double click!
--
--   ----------------------------------------------------------------------------------------
--   BEHAVIOR
--   ----------------------------------------------------------------------------------------
--   - Uses a specific custom command (e.g. from SWS or FX Organizer) to open an instrument’s floating window.
--   - If the command fails to detect the instrument window, it opens the normal FX chain window instead.
--   - Automatically handles cases where no track is selected, displaying a user-friendly error message.
--
--   Note: Replace the custom command ID with the correct one for your system or extension.


----------------------------------------------------------------------------------------
-- GET SELECTED TRACK
----------------------------------------------------------------------------------------

local track = reaper.GetSelectedTrack(0, 0)

if track then
  ----------------------------------------------------------------------------------------
  -- INSTRUMENT FLOAT WINDOW LOGIC
  ----------------------------------------------------------------------------------------

  local fxCount = reaper.TrackFX_GetCount(track)
  local floatingWindowOpened = false
  local instrumentCommandID = reaper.NamedCommandLookup('_RScd7a8ee199006214f53cef679139702356791f76') -- Custom action

  -- Try to open the instrument float window
  reaper.Main_OnCommand(instrumentCommandID, 0)

  -- Wait and check if window was actually opened
  reaper.defer(function()
    for i = 0, fxCount - 1 do
      local isInstrument = reaper.TrackFX_GetInstrument(track, i)
      if isInstrument then
        floatingWindowOpened = true
        break
      end
    end

    ----------------------------------------------------------------------------------------
    -- FALLBACK: OPEN FX CHAIN WINDOW
    ----------------------------------------------------------------------------------------

    if not floatingWindowOpened then
      reaper.Main_OnCommand(40271, 0)  -- Open FX chain window if no instrument window
    end
  end)

else
  ----------------------------------------------------------------------------------------
  -- HANDLE NO TRACK SELECTED
  ----------------------------------------------------------------------------------------

  reaper.ShowMessageBox("No track selected. Please select a track and try again.", "Error", 0)
end

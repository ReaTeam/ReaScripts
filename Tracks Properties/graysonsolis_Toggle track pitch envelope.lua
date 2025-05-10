-- @description Toggle Track Pitch Envelope
-- @author Grayson Solis
-- @version 1.0
-- @link https://graysonsolis.com
-- @donation https://paypal.me/GrayTunes
-- @about
--   This optimized script toggles the Shift (cents) envelope lane for ReaPitch on the selected
--   track at lightning speed. It silently adds ReaPitch if missing, hides its FX chain, and
--   efficiently updates the envelope chunk in a single pass.
--
--   ----------------------------------------------------------------------------------------
--   USE CASE
--   ----------------------------------------------------------------------------------------
--   Ideal when performing rapid pitch automation edits in sound design or music production.
--   With this script bound to a key, you can instantly show or hide the cents-shift envelope
--   without any UI interruptions.
--
--   ----------------------------------------------------------------------------------------
--   BEHAVIOR
--   ----------------------------------------------------------------------------------------
--   • Freezes UI refresh to eliminate flicker  
--   • Begins an undo block for single-step reversal  
--   • Silently adds or finds ReaPitch (no FX window)  
--   • Automatically shows envelope when newly added, otherwise toggles visibility  
--   • Updates ACT, VIS, ARM, LANEHEIGHT, DEFSHAPE flags in one chunk operation  
--   • Refreshes arrange view and unfreezes UI


----------------------------------------------------------------------------------------
-- BEGIN SCRIPT
----------------------------------------------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

-- 1. Get selected track or exit silently
local track = reaper.GetSelectedTrack(0, 0)
if not track then
  reaper.PreventUIRefresh(0)
  return
end

----------------------------------------------------------------------------------------
-- REAPITCH FX SETUP
----------------------------------------------------------------------------------------
-- TrackFX_GetCount before adding to detect new addition
local before = reaper.TrackFX_GetCount(track)

-- Silently add/find ReaPitch (Cockos)
local fx_idx = reaper.TrackFX_AddByName(track, "ReaPitch (Cockos)", false, 0)
if fx_idx < 0 then
  fx_idx = reaper.TrackFX_AddByName(track, "ReaPitch (Cockos)", false, 1)
end
if fx_idx < 0 then
  reaper.ShowMessageBox("Could not add/find ReaPitch.", "Error", 0)
  reaper.PreventUIRefresh(0)
  return
end

-- Always hide its FX chain (silent)
reaper.TrackFX_Show(track, fx_idx, 2)

-- Determine if the FX was just added
local added = (reaper.TrackFX_GetCount(track) > before)
--[[
----------------------------------------------------------------------------------------
-- ENVELOPE ACCESS
----------------------------------------------------------------------------------------

CUSTOMIZATION TIP

To allow user selection of a different ReaPitch parameter envelope, change the value
of the `param` variable below to one of the following:

    0:  Wet
    1:  Dry
    2:  1: Enabled
    3:  1: Shift (full range)
    4:  1: Shift (cents)         <-- current default
    5:  1: Shift (semitones)
    6:  1: Shift (oct)
    7:  1: Formant adjust (full range)
    8:  1: Formant adjust (cents)
    9:  1: Formant adjust (semitones)
    10: 1: Volume
    11: 1: Pan
    12: Bypass
    13: Wet
    14: Delta

For example, to toggle the envelope for "Shift (semitones)", set:

    local param = 5
]]

---
local param = 4  -- Shift (cents) YOU CAN CHANGE THIS!!!!
local env = reaper.GetFXEnvelope(track, fx_idx, param, true)
if not env then
  reaper.ShowMessageBox("Failed to access envelope.", "Error", 0)
  reaper.PreventUIRefresh(0)
  return
end

-- Read the envelope chunk once
local ok, chunk = reaper.GetEnvelopeStateChunk(env, "", false)
if not ok then
  reaper.ShowMessageBox("Failed to read envelope.", "Error", 0)
  reaper.PreventUIRefresh(0)
  return
end

----------------------------------------------------------------------------------------
-- TOGGLE LOGIC
----------------------------------------------------------------------------------------
local show
if added then
  -- Newly added FX → always show envelope
  show = true
else
  -- Existing FX → toggle based on current VIS flags
  local v1,v2,v3 = chunk:match("VIS (%d+) (%d+) (%d+)")
  show = not (v1 == "1" and v2 == "1" and v3 == "1")
end

----------------------------------------------------------------------------------------
-- UPDATE CHUNK FLAGS (ONE-PASS)
----------------------------------------------------------------------------------------
chunk = chunk
  :gsub("ACT %d+",         "ACT " .. (show and 1 or 0))
  :gsub("VIS %d+ %d+ %d+", "VIS " .. (show and "1 1 1" or "0 0 0"))
  :gsub("ARM %d+",         "ARM " .. (show and 1 or 0))
  :gsub("LANEHEIGHT %d+",  "LANEHEIGHT " .. (show and 15 or 0))
  :gsub("DEFSHAPE %d+",    "DEFSHAPE 0")

-- Apply and refresh
reaper.SetEnvelopeStateChunk(env, chunk, false)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

----------------------------------------------------------------------------------------
-- END SCRIPT
----------------------------------------------------------------------------------------
reaper.Undo_EndBlock("Toggle ReaPitch Shift (cents) Envelope", 0)
reaper.PreventUIRefresh(0)

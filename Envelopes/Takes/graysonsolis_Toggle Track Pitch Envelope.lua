-- @description Toggle Track Pitch Envelope
-- @author Grayson Solis
-- @version 1.0
-- @about
--   Toggles Shift (cents) envelope lane for ReaPitch on selected track. Adds ReaPitch if missing. Similar to the "volume" or "pan" default track envelopes.
--   The parameter used can be toggled by editing the lines below!

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local track = reaper.GetSelectedTrack(0, 0)
if not track then
  reaper.PreventUIRefresh(0)
  return
end

local before = reaper.TrackFX_GetCount(track)

local fx_idx = reaper.TrackFX_AddByName(track, "ReaPitch (Cockos)", false, 0)
if fx_idx < 0 then
  fx_idx = reaper.TrackFX_AddByName(track, "ReaPitch (Cockos)", false, 1)
end
if fx_idx < 0 then
  reaper.ShowMessageBox("Could not add/find ReaPitch.", "Error", 0)
  reaper.PreventUIRefresh(0)
  return
end

reaper.TrackFX_Show(track, fx_idx, 2)

local added = (reaper.TrackFX_GetCount(track) > before)

--[[

CUSTOMIZATION TIP
To select a different ReaPitch parameter envelope, change the value
of the `param` variable below to one of the following:

     0:  Wet
     1:  Dry
     2:  Enabled
     3:  Shift (full range)
     4:  Shift (cents)         <-- current default
     5:  Shift (semitones)
     6:  Shift (oct)
     7:  Formant adjust (full range)
     8:  Formant adjust (cents)
     9:  Formant adjust (semitones)
     10: Volume
     11: Pan
     12: Bypass
     13: Wet
     14: Delta

 For example, to toggle the envelope for "Shift (semitones)", set:
 
     local param = 5
     
--]]

local param = 3  -- Shift (cents) YOU CAN CHANGE THIS!!!!

local env = reaper.GetFXEnvelope(track, fx_idx, param, true)
if not env then
  reaper.ShowMessageBox("Failed to access envelope.", "Error", 0)
  reaper.PreventUIRefresh(0)
  return
end

local ok, chunk = reaper.GetEnvelopeStateChunk(env, "", false)
if not ok then
  reaper.ShowMessageBox("Failed to read envelope.", "Error", 0)
  reaper.PreventUIRefresh(0)
  return
end


local show
if added then
  show = true
else
  local v1,v2,v3 = chunk:match("VIS (%d+) (%d+) (%d+)")
  show = not (v1 == "1" and v2 == "1" and v3 == "1")
end

chunk = chunk
  :gsub("ACT %d+",         "ACT " .. (show and 1 or 0))
  :gsub("VIS %d+ %d+ %d+", "VIS " .. (show and "1 1 1" or "0 0 0"))
  :gsub("ARM %d+",         "ARM " .. (show and 1 or 0))
  :gsub("DEFSHAPE %d+",    "DEFSHAPE 0")

reaper.SetEnvelopeStateChunk(env, chunk, false)
reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Toggle ReaPitch Shift (cents) Envelope (default height)", 0)
reaper.PreventUIRefresh(0)


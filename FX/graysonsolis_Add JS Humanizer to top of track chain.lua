-- @description Add JS Humanizer to top of track chain
-- @author Grayson Solis
-- @version 1.0
-- @about Inserts the built-in JS humanizer at slot 1 on the selected track’s FX chain.
-- @website https://graysonsolis.com
-- @donations https://paypal.me/GrayTunes?country.x=US&locale.x=en_US

local tr = reaper.GetSelectedTrack(0, 0)
if not tr then return end

reaper.Undo_BeginBlock()
  -- add the JS humanizer to the TRACK FX chain (recFX = false), always at end (pos = -1)
  local fx = reaper.TrackFX_AddByName(
    tr,
    "JS: MIDI Velocity and Timing Humanizer",
    false,  -- false = normal FX chain (not Input FX)
    -1      -- -1 = always add new instance at end
  )
  if fx >= 0 then
    -- move it into slot 0 (top of chain), shifting others down
    reaper.TrackFX_CopyToTrack(tr, fx, tr, 0, true)
  end
reaper.Undo_EndBlock("Add JS MIDI Velocity and Timing Humanizer to top", -1)

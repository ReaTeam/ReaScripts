-- @description Track Monitor On and Change to MIDI input when VST Loaded
-- @author Grayson Solis
-- @version 1.0
-- @screenshot Example https://imgur.com/TDio9Pd
-- @about
--   Automatically enables input monitoring (Record Monitoring ON) for all tracks
--   that contain virtual instruments. It runs continuously and updates in real-time as tracks
--   are added or modified. Also makes input mode MIDI. To change input mode, delete virtual instrument from track.
--
--   Make this a global startup action! I highly recommend checking out Amely Suncrolls global startup actions.

local last_time = reaper.time_precise()

local MIDI_FLAG    = 4096
local ALL_CHANNELS = 0          
local ALL_PHYSICAL = 63 << 5   
local midiAllInput = MIDI_FLAG + ALL_CHANNELS + ALL_PHYSICAL

function check_monitor()
  local current_time = reaper.time_precise()
  if current_time - last_time < 0.05 then
    reaper.defer(check_monitor)
    return
  end
  last_time = current_time

  local trackCount = reaper.CountTracks(0)
  for i = 0, trackCount - 1 do
    local tr = reaper.GetTrack(0, i)

    local inst = reaper.TrackFX_GetInstrument(tr)
    if inst ~= -1 then

      local recmon = reaper.GetMediaTrackInfo_Value(tr, "I_RECMON")
      if recmon ~= 1 then
        reaper.SetMediaTrackInfo_Value(tr, "I_RECMON", 1)
      end

      local currentInput = reaper.GetMediaTrackInfo_Value(tr, "I_RECINPUT")
      if currentInput ~= midiAllInput then
        reaper.SetMediaTrackInfo_Value(tr, "I_RECINPUT", midiAllInput)
      end

    end
  end

  reaper.defer(check_monitor)
end

check_monitor()


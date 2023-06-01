-- @description Adjust selected tracks volume
-- @author AB
-- @version 1.0
-- @about
--   This script enables you to adjust (substract/add) the volume of the selected track(s) in decibels (dB).
--   If you'd like to use it by double-clicking on a mixer track panel. Follow these steps:
--   1. Go to Preferences.
--   2. Select Mouse Modifiers.
--   3. Navigate to Mixer Control Panel.
--   4. Locate the Double Click option.
--   5. Set this script as the "Default Action".
--   6. Now you can adjust the volume of the selected track(s) by double-clicking on the mixer track.

function db2lin(db)
  return 10 ^ (db / 20)
end

function main()
  
  local numSelectedTracks = reaper.CountSelectedTracks(0)
  
  if numSelectedTracks <= 0 then
      reaper.ShowMessageBox("No Track/s Selected", "Info", 0)
     return
  end
  
  -- Get User Input
  local userPrompt = "Volume adjustment in dB (-+):"
  local _, userInput = reaper.GetUserInputs("Volume Adjustment", 1, userPrompt, "0")
  
  -- Check if the user canceled the input
  if userInput == false then
    return
  end
  
  -- Parse the user input as a number
  local trackVolDb = tonumber(userInput)
  
  -- Check if the user input is valid
  if trackVolDb == nil then
      reaper.ShowMessageBox("Not a valid number. Please use a db value", "Info", 0)
    return
  end
  
  -- Convert from dB to linear
  local trackVolLin = db2lin(trackVolDb)
  local faderMaxVal = db2lin(12)
  
  for i = 0, numSelectedTracks - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    local currentVol = reaper.GetMediaTrackInfo_Value(track, "D_VOL")
    local newVol = currentVol * trackVolLin
    if newVol >= faderMaxVal then
      newVol = faderMaxVal
    elseif newVol <= 0 then
      newVol = 0
    end
    reaper.SetMediaTrackInfo_Value(track, "D_VOL", newVol)
  end
end
--------------------------------------------------------------------
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

main()

reaper.Undo_EndBlock("AB - Adjust Selected Tracks Volume.lua", -1)
reaper.PreventUIRefresh(-1)
--------------------------------------------------------------------

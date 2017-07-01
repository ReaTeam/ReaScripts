--[[
ReaScript name: js_Time selection - Insert empty beats at time selection (moving later items).lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=191210
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script is a "beats version" of REAPER's native action "Time selection: Insert empty space at time selection (moving later items)".

  REAPER's action inserts empty space that is equal to *time* duration of the time selection. 
  If the time selection is not an exact multiple of beats (calculated in the tempo preceding the insert point), 
      all later events (including tempo changes) will necessarily shift away from their beat positions.
  
  This script insert empty space equal to the number of *beats* in the time selection.
  Later events will therefore remain on the beat.
  
  WARNING: This script is NOT compatible with linear tempo changes. 
  The tempo change that precedes the time selection should be square, as should the tempo map's default point shape.
]]

--[[
  Changelog:
  * v0.90 (2017-06-30)
    + Initial beta release
]]

timeStart, timeEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
if type(timeStart) ~= "number" or type(timeEnd) ~= "number" or timeStart >= timeEnd then 
    return 
end

-- Convert time selection into number of beats
beatStart = reaper.TimeMap2_timeToQN(0, timeStart)
beatEnd   = reaper.TimeMap2_timeToQN(0, timeEnd)

-- REAPER's "Insert space" action will move tempo change that falls exactly on timeStart.  
-- So subtract 0.01 from timeStart to find tempo *before* timeStart.
_, _, tempoAtTimeStart = reaper.TimeMap_GetTimeSigAtTime(0, timeStart-0.01)

lastTempoMarkerIndex = reaper.FindTempoTimeSigMarker(0, timeStart-0.01)
if lastTempoMarkerIndex ~= -1 then
    OK, _, _, _, _, _, _, lineartempo = reaper.GetTempoTimeSigMarker(0, lastTempoMarkerIndex)
    if OK and lineartempo then
        reaper.MB("This last tempo change before the time selection should not be linear", "ERROR", 0)
        return
    end
end

newTimeEnd = timeStart + (beatEnd-beatStart) * (60.00/tempoAtTimeStart)

reaper.Undo_BeginBlock2(0)
_, _ = reaper.GetSet_LoopTimeRange2(0, true, false, timeStart, newTimeEnd, true)
reaper.Main_OnCommandEx(40200, -1, 0) -- Time selection: Insert empty space at time selection (moving later items)
reaper.Undo_EndBlock2(0, "Insert empty beats in selection", -1)

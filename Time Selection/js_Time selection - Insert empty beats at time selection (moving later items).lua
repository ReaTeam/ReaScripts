--[[
ReaScript name: js_Time selection - Insert empty beats at time selection (moving later items).lua
Version: 0.93
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=191210
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script is a "beats version" of REAPER's native action "Time selection: Insert empty space at time selection (moving later items)".

  REAPER's action inserts empty space that is equal to *time* duration of the time selection. 
  If the time selection is not an exact multiple of beats (calculated in the tempo preceding the insert point), 
      all later events (including tempo changes) will necessarily shift away from their beat positions.
  
  This script insert empty space equal to the number of *beats* in the time selection
  (in the tempo preceding the time selection).
  Later events will therefore remain on the beat.
  
  WARNING: This script is not fully compatible with linear tempo changes. 
  The tempo change that precedes the time selection should be square, as should the tempo map's default point shape.
]]

--[[
  Changelog:
  * v0.90 (2017-06-30)
    + Initial beta release.
  * v0.91 (2017-06-30)
    + Changed the header Description a little.
  * v0.92 (2017-07-02)
    + Workaround for "Add edge points" bug in REAPER that deletes timesig markers at insertion point.
  * v0.93 (2017-07-03)
    + Workaround for "Add edge points" bug in REAPER that deletes timesig markers at insertion point.
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
timesigNumAtTimeStart, timesigDenomAtTimeStart, tempoAtTimeStart = reaper.TimeMap_GetTimeSigAtTime(0, timeStart-0.001)

prevTempoMarkerIndex = reaper.FindTempoTimeSigMarker(0, timeStart-0.001)
if prevTempoMarkerIndex ~= -1 then
    prevOK, _, _, _, _, prevTimesig_num, prevTimesig_denom, prevLineartempo = reaper.GetTempoTimeSigMarker(0, prevTempoMarkerIndex)
    if prevOK and prevLineartempo then
        reaper.MB("This last tempo change before the time selection should not be linear", "ERROR", 0)
        return
    end
end

-- Current versions of REAPER has a bug in the "Insert empty space" action, 
--    which destroys pre-existing *timesig* markers at the insertion point,
--    if "Options: Add edge points when ripple editing or inserting time" is ON.
-- The pre-existing timesig marker is overwritten by the edge node.
-- This script will therefore deactive the option before inserting time.
--[[
stateInsertEdgePoints = reaper.GetToggleCommandStateEx(0, 40649) -- Options: Add edge points when ripple editing or inserting time
if stateInsertEdgePoints == 1 then
    reaper.Main_OnCommandEx(40649, -1, 0)
end
]]
-- Make doubly sure, by finding and later re-inserting any timesig change at start
startTempoMarkerIndex = reaper.FindTempoTimeSigMarker(0, timeStart+0.001)
if startTempoMarkerIndex ~= prevTempoMarkerIndex then
    startOK, startTimePos, _, _, startBPM, startTimesig_num, startTimesig_denom, startLineartempo = reaper.GetTempoTimeSigMarker(0, startTempoMarkerIndex)
end


newTimeEnd = timeStart + (beatEnd-beatStart) * (60.00/tempoAtTimeStart)

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)

_, _ = reaper.GetSet_LoopTimeRange2(0, true, false, timeStart, newTimeEnd, true)
reaper.Main_OnCommandEx(40200, -1, 0) -- Time selection: Insert empty space at time selection (moving later items)

-- Replace the edge node that may have destroyed pre-existing timesig markers.
if startOK then
    buggyIndex = reaper.FindTempoTimeSigMarker(0, newTimeEnd + 0.01)
    if buggyIndex ~= -1 then
        local buggyOK, buggyTimePos, buggyMeasurePos, buggyBeatPos, buggyBPM, buggyTimesig_num, buggyTimesig_denom, buggyLineartempo = reaper.GetTempoTimeSigMarker(0, buggyIndex)
        if buggyOK and buggyTimePos > newTimeEnd - 0.01 then
            reaper.SetTempoTimeSigMarker(0, buggyIndex, newTimeEnd, -1, -1, startBPM, startTimesig_num, startTimesig_denom, startLineartempo)
            changedMarker = true
        end
    end
    -- If "Insert empty space" completely removed the marker at start
    if not changedMarker then
        reaper.SetTempoTimeSigMarker(0, -1, newTimeEnd, -1, -1, startBPM, startTimesig_num, startTimesig_denom, startLineartempo)
    end
end

-- Toggle state back on
if stateInsertEdgePoints == 1 then
    reaper.Main_OnCommandEx(40649, -1, 0)
end

reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock2(0, "Insert empty beats in selection", -1)

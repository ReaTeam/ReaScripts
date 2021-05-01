--[[
ReaScript name: js_Stretch tempo markers to edit cursor.lua
Version: 0.90
Changelog:
  + BETA release
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=193258
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script helps with aligning tempo markers to hitpoints in media.
  
  If the tempo is constant, REAPER's native action "Create measure from time selection (new time signature)" works fine to align measures with hitpoints.  
  
  However, if the tempo is variable -- for example if the tempo curve was drawn freehand -- REAPER does not have a suitable native action for preserving the tempo curves while aligning with hitpoints.
  
  This script modifies the bpm of selected markers so that the rightmost selected marker falls exactly on the edit cursor position.  (The leftmost selected marker stays in position.)
  
  Gradual tempo changes can be stretched, with one limitation: the marker immediately preceding the selected ones as well as the second-to-last selected marker must be square.
  
  NB: Before running the script, the use must set the timebases for items and markers as required.
]]

editTime = reaper.GetCursorPositionEx(0)
    
currentTimebase = reaper.SNM_GetIntConfigVar("tempoenvtimelock", -100)
if currentTimebase == -100 then reaper.MB("Error getting current timebase.", "ERROR", 0) return end

-- Find selected markers and their time range.
-- The GetTempoTimeSigMarker function doesn't return selected status, so must parse the envelope chunk.
--[[
Tempo chunk point fields: 
TIMEPOS, BPM, shape, timesig0isNone, selected, flags, unknown2, unknown3Str, unknown4, metronome

Flags:
Allow partial = 4
NOT set tempo = 2
Set metronome = 8
Set timesig = 1
]]
masterTrack = reaper.GetMasterTrack(0)
if not reaper.ValidatePtr2(0, masterTrack, "MediaTrack*") then reaper.MB("The script could not find a master track.\n\nPlease report this bug.", "ERROR", 0) return end
tempoEnv    = reaper.GetTrackEnvelopeByName(masterTrack, "Tempo map")
if not reaper.ValidatePtr2(0, tempoEnv, "TrackEnvelope*") then reaper.MB("The script could not find the tempo envelope.\n\nPlease report this bug.", "ERROR", 0) return end
reaper.Envelope_SortPoints(tempoEnv)
chunkOK, chunk = reaper.GetEnvelopeStateChunk(tempoEnv, "", false)
if not chunkOK then reaper.MB("The script could not load the state chunk of the tempo envelope.\n\nPlease report this bug.", "ERROR", 0) return end

tT = {} -- Remember selected merkers. If selected, tT[t] will be true
t = -1
TIME, BPM, SHAPE, REST, SELECTED, NEWBPM = 1, 2, 3, 4, 5, 6
for point in chunk:gmatch("\nPT %S+ [^\n]+") do
    t = t + 1
    tT[t] = {point:match("\nPT (%S+) (%S+) (%S+)(.*)")} --  timeStr, bpmStr, shapeStr, restStr
    if (point:match("\nPT %S+ %S+ %S+ %S+ (%S+)") == "1") then -- Selected
        if firstSelected and tT[t-1] and not tT[t-1][SELECTED] then
            reaper.MB("There should not be any UNselected tempo markers between the selected ones.", "ERROR", 0) return
        end
        tT[t][SELECTED] = true
        firstSelected = firstSelected or t
        lastSelected = t
        rightTime = tonumber(tT[t][TIME])
        leftTime = leftTime or rightTime
    end
end
if not firstSelected then
    reaper.MB("No selected tempo markers found.", "ERROR", 0) return
elseif (leftTime >= rightTime) then
    reaper.MB("Two or more tempo markers at distinct time positions should be selected.", "ERROR", 0) return
elseif leftTime >= editTime then
    reaper.MB("The edit cursor should be to the right of the leftmost selected marker.", "ERROR", 0) return
elseif tT[firstSelected-1] and tT[firstSelected-1][SHAPE] == "0" then
    reaper.MB("Unfortunately, this script will not work if the marker immediately preceding the selected ones is linear (gradual).", "ERROR", 0) return
elseif tT[lastSelected-1][SHAPE] == "0" then
    reaper.MB("Unfortunately, this script will not work if the marker immediately preceding the second-to-last selected marker is linear (gradual).", "ERROR", 0) return
elseif currentTimebase == 0 and tT[lastSelected+1] and tonumber(tT[lastSelected+1][TIME]) < editTime then
    reaper.MB("Stretching the selected tempo markers will overlap existing unselected markers.\n\nPerhaps the tempo timebase should be set to beats?", "ERROR", 0) return
end

-- Check if changes would lead to invalid BPM
stretch = (rightTime-leftTime)/(editTime-leftTime)
for t = firstSelected, lastSelected-1 do
    local newBpm = tonumber(tT[t][BPM])*stretch
    if newBpm < 20 or 280 < newBpm then
        reaper.MB("Too extreme bpm: "..string.format("%.5f", newBpm), "ERROR", 0) return
    else
        tT[t][NEWBPM] = tostring(newBpm)
    end
end

-- gsub helper function to construct new chunk with updated tempo markers.
-- Why not do this with the native SetTempoTimeSigMarker functions?  Because these mess up timesig markers, even if "allow partial measure" is enabled.
-- NB: As noted below, even the chunk method doesn't work properly.  The trick is to apply at least one SetTempoTimeSigMarker *after* uploading the chunk, which will trigger timeline update.
t = -1 -- Count markers while parsing with gsub.
local function gsubHelper(p)
    t = t + 1
    local time = tonumber(tT[t][TIME])
    if firstSelected <= t and t < lastSelected then
        local newTime = leftTime + (time-leftTime)/stretch
        return string.format"\nPT "..tostring(newTime).." "..tT[t][NEWBPM].." "..tT[t][SHAPE]..tT[t][REST]
    elseif t == lastSelected then
        beatsTimebaseShift = editTime - time -- If timebase = beats, ALL subsequent markers will shift this same timelength.
        return "\nPT "..tostring(editTime).." "..tT[t][BPM].." "..tT[t][SHAPE]..tT[t][REST]
    elseif currentTimebase == 1 and t > lastSelected then -- If timebase is time, don't change any points after selected ones
        local newTime = time + beatsTimebaseShift
        return "\nPT "..tostring(newTime).." "..tT[t][BPM].." "..tT[t][SHAPE]..tT[t][REST]
    end
end
chunk = chunk:gsub("\nPT %S+ [^\n]+", gsubHelper)

-- All tests done. Start editing!
reaper.Undo_BeginBlock2(0)
reaper.SetEnvelopeStateChunk(tempoEnv, chunk, false)
-- REAPER does not update properly after setting tempo chunk.  Must edit at least one maker via SetTempoTimeSigMarker function.
tempoOK, time, measures, beats, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, 0)
if not tempoOK then
    reaper.MB("The tempo envelope might not have updated correctly.\n\nAn update can usually be triggered by click-dragging any tempo marker.", "ERROR", 0)
end
reaper.SetTempoTimeSigMarker(0, 0, time, -1, -1, bpm, timesig_num, timesig_denom, lineartempo)

-- Reset edit cursor to original position
reaper.ApplyNudge(0, 1, 6, 1, editTime, false, 0)
reaper.UpdateTimeline()

reaper.Undo_EndBlock2(0, "Stretch tempo markers", 0)

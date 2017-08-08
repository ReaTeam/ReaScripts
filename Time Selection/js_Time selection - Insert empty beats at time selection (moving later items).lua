--[[
ReaScript name: js_Time selection - Insert empty beats at time selection (moving later items).lua
Version: 0.96
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=191210
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script is a "beats version" of REAPER's native action "Time selection: Insert empty space at time selection (moving later items)".
  The number of selected beats is precisely replicated in the empty space.

  REAPER's action inserts empty space that is equal to *time* duration of the time selection. 
  If the time selection is not an exact multiple of beats (calculated in the tempo preceding the insert point), 
      all later events (including tempo changes) will necessarily shift away from their beat positions.
  
  # Tempo map
  This script duplicates the tempo envelope into the empty space, which has the result of inserting the exact number of selected *beats* 
  in the time selection. Later events will therefore remain on the grid.
  
  # Insert position
  The script can insert the empty beats/space on either the left of the right of the time selection, 
  depending position of the edit cursor relative to the time selection.
  
  # Locked items
  The script will also detect locked items and can optionally protect such items against moving or splitting.
  
  # MIDI items
  MIDI items will *not* be split. Instead, the MIDI will be shifted *inside* the item. The script can therefore be used in the MIDI editor
  
  # Timebase
  The user does not need to make any changes to the timebase before or after running the script. Items will be moved as if Timebase=Time
  for all tracks, items and envelopes.
  
  # WARNING
  The script may require several seconds to parse large projects (and, in particular, large MIDI items).
]]

--[[
  Changelog:
  * v0.90 (2017-06-30)
    + Initial beta release as "js_Time selection - Insert empty beats at time selection (moving later items).lua".
  * v0.95 (2017-08-06)
    + MIDI items are not split. Instead MIDI is shifted inside item. Script is threfore useful in MIDI editor.
    + Tempo envelope is duplicated into empty space, so that inserted space is equal to selected time as well as selected beats.
    + Compatible with linear tempo changes.
    + User does not need to make any changes to timebase before or after running script.
    + Locked items can be protected against moving or splitting.
    + Empty space can be inserted either to the left or right of time selection (determined by edit cursor position).
  * v0.96 (2017-08-07)
    + MIDI notes that extend into but not beyond time selection, will not be extended.
]]

if not reaper.APIExists("SNM_CreateFastString") then
    reaper.MB("The script requires the SWS/SNM extension.\n\nThe extension can be downloaded from www.sws-extension.com.", "ERROR", 1) 
    return 
end

local tLockedItemPositions, tMIDIItemPositions, tTracks, tNames
local LOCK, LINEAR, SQUARE = 6, 0, 1


---------------------
---------------------
-- Get time selection
local spaceTimeStart, spaceTimeEnd = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
if type(spaceTimeStart) ~= "number" or type(spaceTimeEnd) ~= "number" or spaceTimeStart >= spaceTimeEnd then 
    return
end
local spaceLength = spaceTimeEnd - spaceTimeStart
local beatsSinceMeasureStart, measures, _, _, _ = reaper.TimeMap2_timeToBeats(0, spaceTimeStart+0.00000001)
if measures and beatsSinceMeasureStart < 0.000001 then
    spaceStartsAtMeasure = true
end
local beatsSinceMeasureStart, measures, _, _, _ = reaper.TimeMap2_timeToBeats(0, spaceTimeEnd+0.00000001)
if measures and beatsSinceMeasureStart < 0.000001 then
    spaceEndsAtMeasure = true
end


--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Parse tempo envelope to determine bpm at insertion point, and whether edge points need to be inserted
-- First, get tempo envelope chunk
local masterTrack = reaper.GetMasterTrack(0)
if not reaper.ValidatePtr2(0, masterTrack, "MediaTrack*") then reaper.MB("The script could not find a master track.\n\nPlease report this bug.", "ERROR", 1) return end
local tempoEnv    = reaper.GetTrackEnvelopeByName(masterTrack, "Tempo map")
if not reaper.ValidatePtr2(0, tempoEnv, "TrackEnvelope*") then reaper.MB("The script could not find the tempo envelope.\n\nPlease report this bug.", "ERROR", 1) return end
reaper.Envelope_SortPoints(tempoEnv)
local chunkOK, tempoChunk = reaper.GetEnvelopeStateChunk(tempoEnv, "", false)
if not chunkOK then reaper.MB("The script could not load the state chunk of the tempo envelope.\n\nPlease report this bug.", "ERROR", 1) return end

-- Temporarily remove point strings from chunk and store them in a table, where they can be more easily manipulated
local tPoints = {}
local function gsubRemoveHelper(point)
    tPoints[#tPoints+1] = point
    return "@@@@@@@@@@" -- Placeholder string so that edited points can easily be replaced
end 
local tempoChunk = tempoChunk:gsub("\nPT [%d%.]+ [%d%.]+ %d[^\n]*", gsubRemoveHelper)

-- Parse points to find tempo/timesig values at timeStart and timeEnd. The parsing uses project default timesig/tempo as starting values.
local LINEAR, SQUARE = 0, 1
local lastPos = 0
local projectBPM, projectTimesig_num    = reaper.GetProjectTimeSignature2(0)
local lastBPM, startBPM                 = projectBPM, projectBPM
local lastTimesig_num, startTimesig_num = projectTimesig_num, projectTimesig_num
local lastTimesig_denom, startTimesig_denom = 4, 4
local lastShape, startShape             = SQUARE, SQUARE
local lastMetronome, startMetronome     = "", ""

-- While parsing, each point's string will be stored in table tPoints, so that can later more easily be manipulated.
for index, point in ipairs(tPoints) do  
    local timePos, bpm, shape, rest = point:match("\nPT ([%d%.]+) ([%d%.]+) (%d)([^\n]*)")
    timePos, bpm, shape = tonumber(timePos), tonumber(bpm), tonumber(shape)
    local timesig, metronome = rest:match("^ (%d%d%d%d%d+) %d %d([^\n]*)")
    local timesig_num, timesig_denom
    if timesig then 
        timesig = tonumber(timesig)
        if timesig then 
            timesig_num, timesig_denom = timesig&0xFFFF, timesig>>16
            if not (timesig_num > 0 and timesig_denom > 0) then timesig, timesig_num, timesig_denom = nil, nil, nil 
    end end end
    --if metronome == "" then metronome = nil end
            
    if timePos > spaceTimeStart-0.00000001 and timePos < spaceTimeStart+0.00000001 then
        -- There may be multiple tempo points at the same start time point. The script must get the *last* relevant values.
        gotFirstMarkerPastStart = true
        --if timePos < spaceTimeStart+0.00000001 then
        pointAtStartStr = point
        indexAtStart = index
        gotMarkerAtStart = true
        startShape = shape
        startBPM = bpm
        if timesig then
            gotTimesigAtStart, startTimesig_num, startTimesig_denom = true, timesig_num, timesig_denom
        else
            startTimesig_num, startTimesig_denom = lastTimesig_num, lastTimesig_denom 
        end
        if metronome == "" or not metronome then
            startMetronome = lastMetronome
        else
            startMetronome = metronome
        end
    end
    
    if not gotFirstMarkerPastStart and timePos > spaceTimeStart+0.00000001 then
        gotFirstMarkerPastStart = true
        startShape = lastShape
        startMetronome = lastMetronome
        if lastShape == LINEAR then --and lastBPM ~= bpm then
            startBPM = lastBPM + (bpm-lastBPM)*(spaceTimeStart-lastPos)/(timePos-lastPos)
        else
            startBPM = lastBPM
        end
        gotTimesigAtStart, startTimesig_num, startTimesig_denom = false, lastTimesig_num, lastTimesig_denom
    end
    
    if not gotFirstMarkerPastEnd and timePos > spaceTimeEnd-0.00000001 then
        gotFirstMarkerPastEnd = true
        endShape = lastShape
        endTimesig_num, endTimesig_denom = lastTimesig_num, lastTimesig_denom
        endMetronome = lastMetronome
        if endShape == LINEAR then
            if timePos < spaceTimeEnd+0.00000001 then
                endBPM = bpm
            else
                endBPM = lastBPM + (bpm-lastBPM)*(spaceTimeEnd-lastPos)/(timePos-lastPos)
            end
        else
            endBPM = lastBPM
        end
    end
    
    lastShape = shape
    lastPos   = timePos
    lastBPM   = bpm
    if timesig then 
        lastTimesig_num, lastTimesig_denom = timesig_num, timesig_denom
    end
    if metronome and metronome ~= "" then
        lastMetronome = metronome
    end
end    
if not gotFirstMarkerPastEnd then
    endBPM = lastBPM
    endShape = lastShape
    endTimesig_num, endTimesig_denom = lastTimesig_num, lastTimesig_denom
    endMetronome = lastMetronome
end    

-- Divide the points into those that stay in their original time position, and those that are shifted.
-- The points between (not inclusive) spaceTimeStart and spaceTimeEnd will be duplicated by assigning them
--    stay as well as Points right at the juncture will be replaced 
--    (at spaceTimeEnd of the points that stay, and spaceTimeStart of the points that will be shifted/duplicated).
local tPointsStay = {}
local tPointsShifted = {}
local tPointsJuncture = {}
for p = 1, #tPoints do
    local timePosStr, restStr = tPoints[p]:match("^\nPT ([%d%.]+)(.*)")
    local timePos = tonumber(timePosStr)
    if timePos < spaceTimeEnd-0.00000001 then
        table.insert(tPointsStay, tPoints[p])
    end
    if timePos > spaceTimeStart+0.00000001 then
        table.insert(tPointsShifted, "\nPT " .. tostring(timePos+spaceLength) .. restStr)
    end    
end

-- Now insert script-calculated points at the juncture
if math.floor(endBPM*1000000 + 0.5) ~= math.floor(startBPM*1000000 + 0.5) and endShape == LINEAR then
    table.insert(tPointsJuncture, "\nPT " .. tostring(spaceTimeEnd) .. " " .. tostring(endBPM) .. " " .. string.format("%i", startShape))
end

if spaceStartsAtMeasure and (
    not spaceEndsAtMeasure 
    or (startTimesig_num ~= endTimesig_num or startTimesig_denom ~= endTimesig_denom or startMetronome ~= endMetronome)) then
    table.insert(tPointsJuncture, "\nPT " .. tostring(spaceTimeEnd) .. " " 
                                          .. tostring(startBPM) .. " " 
                                          .. string.format("%i", startShape) .. " " 
                                          .. string.format("%i", (startTimesig_denom<<16) | (startTimesig_num)) .. " " 
                                          .. "0" .. " "
                                          .. "5" -- 1=New measure / timesig + 4=Allow partial measure
                                          .. startMetronome)
elseif endBPM ~= startBPM or startShape ~= endShape then
    table.insert(tPointsJuncture, "\nPT " .. tostring(spaceTimeEnd) .. " " 
                                          .. tostring(startBPM) .. " " 
                                          .. string.format("%i", startShape))
end
        

-- If the space starts at a measure start, everything to the right should be aligned with measures.
--    If not, make sure that first timesig after insertion points is set to "Allow partial measure".
if not spaceStartsAtMeasure then
    for p = 1, #tPointsShifted do
        local stuff, flags, otherStuff = tPointsShifted[p]:match("(\nPT [%d%.]+ [%d%.]+ %d %d%d%d%d%d+ %d )(%d)(.*)")
        if flags then
            flags = tonumber(flags)
            flags = flags|4 -- 4 => allow partial measures
            tPointsShifted[p] = stuff .. string.format("%i", flags) .. otherStuff
            break
end end end

-- Construct the new tempo chunk!  (Will be uploaded into master track after running "Insert empty space" action.)
tempoChunk = tempoChunk:gsub("@@@@@@@@@@+", table.concat(tPointsStay) ..  table.concat(tPointsJuncture) .. table.concat(tPointsShifted), 1)



--------------------------
--------------------------
reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)


------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Must the empty space e inserted to the left or right of the time selection?
-- Use position of edit cursor the decide.
local editCursorPosition = reaper.GetCursorPositionEx(0)
if editCursorPosition > (spaceTimeStart+spaceTimeEnd)/2 then
    spaceTimeStart, spaceTimeEnd = spaceTimeEnd, spaceTimeEnd+spaceLength
    reaper.GetSet_LoopTimeRange2(0, true, false, spaceTimeStart, spaceTimeEnd, false)
end


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
-- Now for the timebase stuff.  Set timebase = Time for Project envelopes, all tracks and all items
-- Get project timebase settings, so that can be reset later.
projectTimebaseTime     = reaper.GetToggleCommandStateEx(0, reaper.NamedCommandLookup("_SWS_AWTBASETIME"))
projectTimebaseBeatsAll = reaper.GetToggleCommandStateEx(0, reaper.NamedCommandLookup("_SWS_AWTBASEBEATALL"))
projectTimebaseBeatsPos = reaper.GetToggleCommandStateEx(0, reaper.NamedCommandLookup("_SWS_AWTBASEBEATPOS"))
if projectTimebaseTime == 0 then
    reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_SWS_AWTBASETIME"), -1, 0) -- Toggle once to set ON
end
-- The track state chunk will be divided into 1) track header and 2) item-sized parts, in order to find each track and item's BEAT and NAME parameters
-- Each track and item's original timebase will be stored a new name, since item names are propagated to split child items, and the original timebase
--    can therefore be recovered after inserting empty space.
-- The original names will be stored in tNames.
local tTracks = {}
local tNames  = {}
for t = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, t)
    if not reaper.ValidatePtr2(0, track, "MediaTrack*") then
        reaper.MB("Could not get valid pointer to track " .. tostring(t+1) .. ".", "ERROR", 1)
        return
    else
        tTracks[track] = {}
        -- REAPER's native chunk function truncates long chunks!  Therefore must use SNM's SWS function.
        --local okChunk, chunk = reaper.GetTrackStateChunk(track, "", false)
        local fastStr = reaper.SNM_CreateFastString("")
        local okChunk = reaper.SNM_GetSetObjectState(track, fastStr, false, false)
        local chunk = reaper.SNM_GetFastString(fastStr)
        reaper.SNM_DeleteFastString(fastStr)
        if not okChunk then
            reaper.MB("Could not load state chunk of track " .. tostring(t+1) .. ".", "ERROR", 1)
            return
        elseif not chunk:sub(chunk:len()-10):reverse():match("^%s*>") then
            reaper.MB("Could not load state chunk of track " .. tostring(t+1) .. "."
                   .. "\n\nThe state chunk ends with unexpected characters:\n" .. chunk:sub(chunk:len()-10)
                   .. "\n\nChunk length = " .. tostring(chunk:len()), "ERROR", 1)
            return
        else
            local prevPos, nextpos = 0, nil
            repeat
                nextPos = chunk:find("\n<ITEM\n", prevPos+4)
                table.insert(tTracks[track], chunk:sub(prevPos+1, nextPos))
                if not tTracks[track][#tTracks[track]]:match("\nNAME ") then
                    reaper.MB("Could not parse state chunk of track " .. tostring(t+1) .. ': No "NAME" field found.', "ERROR", 1)
                    return
                end
                prevPos = nextPos
            until nextPos == nil
            for i = 1, #tTracks[track] do
                table.insert(tNames, tTracks[track][i]:match("\nNAME (.-)\n"))
                local timebase = tTracks[track][i]:match("\nBEAT ([%d%-]+)\n")
                if timebase then
                    tTracks[track][i] = tTracks[track][i]:gsub("\nNAME .-\n", "\nNAME \"timebase" .. timebase .. "@@@@@:" .. tostring(#tNames) .. "\"\n")
                    tTracks[track][i] = tTracks[track][i]:gsub("\nBEAT ([%d%-]+)\n", "\nBEAT 0\n", 1)
                else
                    -- If item does not have timebase info, insert new BEATS field
                    tTracks[track][i] = tTracks[track][i]:gsub("\nNAME .-\n", "\nNAME \"timebase9@@@@@:" .. tostring(#tNames) .. "\"\n" .. "BEAT 0\n")
end end end end end

for track, parts in pairs(tTracks) do
  -- Apparently, the native SET chunk function works fine with large chunks
    local setOK = reaper.SetTrackStateChunk(track, table.concat(parts), false)
    --[[local chunk = reaper.SNM_CreateFastString(table.concat(parts))
    local setOK = reaper.SNM_GetSetObjectState(track, chunk, true, false)]]
    if not setOK then
        reaper.MB("Could not set the state chunk of all tracks.", "ERROR", 1)
        tryToUndo = true
        goto quit
end end


--------------------------------------------------
--------------------------------------------------
-- Handle locked items - based on script by spk77:
--    "spk77_Insert empty space at time selection (prevent moving locked items).eel"
tLockedItemPositions = {} 
tMIDIItemPositions = {}
for i = 0, reaper.CountMediaItems(0)-1 do
    local item = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, item, "MediaItem*") then
        local itemLocked = ((reaper.GetMediaItemInfo_Value(item, "C_LOCK"))&1 == 1)
        local itemStart  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEnd    = itemStart + itemLength
        
        if not hasAskedAboutLockedItemsYet and itemLocked and itemEnd > spaceTimeStart then
            hasAskedAboutLockedItemsYet = true
            userLockChoice = reaper.MB("The project contains locked items that may be moved or split when inserting empty space."
                                      .. "\n\nShould these locked items be protected against changes?", "WARNING", 3)
            if userLockChoice == 2 then -- CANCEL
                tryToUndo = true
                goto quit 
            elseif userLockChoice == 7 then -- NO
                break
            end
        end
        
        if userLockChoice == LOCK and itemLocked and itemEnd > spaceTimeStart then
            tLockedItemPositions[item] = itemStart
            if itemStart < spaceTimeStart then
                local setPosOK = reaper.SetMediaItemPosition(item, spaceTimeEnd, false)
                if not setPosOK then
                    reaper.MB("The script could not protect the positions of all locked items.", "ERROR", 1)
                    tryToUndo = true
                    goto quit
                end
            end
        -- Check if MIDI that may be split
        else
            if itemStart < spaceTimeStart and itemEnd > spaceTimeStart then -- only bother with items that overlap and will therefore be split
                for t = 0, reaper.CountTakes(item)-1 do
                    local take = reaper.GetTake(item, t)
                    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) then
                        tMIDIItemPositions[item] = {position = itemStart, length = itemLength}
                        local setPosOK = reaper.SetMediaItemPosition(item, spaceTimeEnd, false)
                        if not setPosOK then
                            reaper.MB("The script could not protect the positions of all MIDI items.", "ERROR", 1)
                            tryToUndo = true
                            goto quit
end end end end end end end


-------------------------------------------------------------------------
-------------------------------------------------------------------------
-- The big step that everything else revolves around! Insert empty space!
reaper.Main_OnCommandEx(40200, -1, 0) -- Time selection: Insert empty space at time selection (moving later items)


-----------------------------------------------
-----------------------------------------------
-- Upload tempo envelope with duplicated points
do -- goto doesn't like jumping past declaration of local variables, so let's try hiding stuff within a do-end block
    local setChunkOK = reaper.SetEnvelopeStateChunk(tempoEnv, tempoChunk, true)
    if not setChunkOK then
        reaper.MB("ERROR", "Could not update tempo markers", 1)
        tryToUndo = true
        goto quit
    end
    local firstOK, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, 0)
    if firstOK then
        reaper.SetTempoTimeSigMarker(0, 0, timepos, -1, -1, bpm, timesig_num, timesig_denom, lineartempo)
    end
    reaper.UpdateTimeline()
end


--------------------------------------------
--------------------------------------------
-- Repair original positions of locked items
for item, position in pairs(tLockedItemPositions) do
    local setPosOK = reaper.SetMediaItemPosition(item, position, false)
    if not setPosOK then
        reaper.MB("The script could not protect the positions of all locked items.", "ERROR", 1)
        tryToUndo = true
        goto quit
    end
end


--------------------------------------------
--------------------------------------------
-- Restore original track and item timebases
tTracks = {}
for t = 0, reaper.CountTracks(0)-1 do
    local track = reaper.GetTrack(0, t)
    if reaper.ValidatePtr2(0, track, "MediaTrack*") then
        tTracks[track] = {}
        --local okChunk, chunk = reaper.GetTrackStateChunk(track, "", false)
        local fastStr = reaper.SNM_CreateFastString("")
        local okChunk = reaper.SNM_GetSetObjectState(track, fastStr, false, false)
        local chunk = reaper.SNM_GetFastString(fastStr)
        if not okChunk then
            reaper.MB("Could not load the state chunk of track " .. tostring(t+1) .. ".", "ERROR", 1)
            tryToUndo = true
            goto quit
        elseif not chunk:sub(chunk:len()-10):reverse():match("^%s*>") then
            reaper.MB("Could not load state chunk of track " .. tostring(t+1) .. "."
                   .. "\n\nThe state chunk ends with unexpected characters:\n" .. chunk:sub(chunk:len()-10)
                   .. "\n\nChunk length = " .. tostring(chunk:len()), "ERROR", 1)
            tryToUndo = true
            goto quit
        else
            local prevPos = 0
            repeat
                nextPos = chunk:find("\n<ITEM\n", prevPos+4)
                table.insert(tTracks[track], chunk:sub(prevPos+1, nextPos))
                prevPos = nextPos
            until nextPos == nil
            for i = 1, #tTracks[track] do
                local function gsubName(index)
                    return tNames[tonumber(index)]
                end
                local timebase, index = tTracks[track][i]:match("timebase([%d%-]+)@@@@@:(%d+)")
                index = tonumber(index)
                if timebase == "9" then
                    tTracks[track][i] = tTracks[track][i]:gsub("\nNAME [^\n]-timebase[%d%-]+@@@@@:%d+.-\n", "\nNAME " .. tNames[index] .. "\n") --\nNAME \"temptimebase" .. timebase .. "@@@@@@@@@@%1\"\n", 1)
                    tTracks[track][i] = tTracks[track][i]:gsub("\nBEAT 0[%d]-\n", "\n", 1)
                elseif timebase then
                    tTracks[track][i] = tTracks[track][i]:gsub("\nNAME [^\n]-timebase[%d%-]+@@@@@:%d+.-\n", "\nNAME " .. tNames[index] .. "\n") --\nNAME \"temptimebase" .. timebase .. "@@@@@@@@@@%1\"\n", 1)
                    tTracks[track][i] = tTracks[track][i]:gsub("\nBEAT 0[%d]-\n", "\nBEAT " .. timebase .. "\n", 1)
                end                   
            end
            local setOK = reaper.SetTrackStateChunk(track, table.concat(tTracks[track]), false)
            --[[local chunk = reaper.SNM_CreateFastString(table.concat(tTracks[track]))
            local setOK = reaper.SNM_GetSetObjectState(track, chunk, true, false)]]
            if not setOK then
                reaper.MB("Could not set the state chunk of all tracks.", "ERROR", 1)
                tryToUndo = true
                goto quit
            end
        end
    end
end

if projectTimebaseBeatsAll == 1 then
    reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_SWS_AWTBASEBEATALL"), -1, 0)
elseif projectTimebaseBeatsPos == 1 then
    reaper.Main_OnCommandEx(reaper.NamedCommandLookup("_SWS_AWTBASEBEATPOS"), -1, 0)
end


--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
-- Repair original positions of MIDI items, and insert space without splitting, by shifting all MIDI after insertion point
-- Notes that start
for item, values in pairs(tMIDIItemPositions) do
    local setPosOK = reaper.SetMediaItemPosition(item, values.position, false)
    if not setPosOK then
        reaper.MB("The script could not protect the positions of all MIDI items.", "ERROR", 1)
        tryToUndo = true
        goto quit
    end
    local setLengthOK = reaper.SetMediaItemLength(item, values.length+spaceLength, false)
    if not setLengthOK then
        reaper.MB("The script could not change the lengths of all MIDI items.", "ERROR", 1)
        tryToUndo = true
        goto quit
    end    
    
    for t = 0, reaper.CountTakes(item)-1 do
        local take = reaper.GetTake(item, t)
        if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) then
            reaper.MIDI_Sort(take)
            local spacePPQstart = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, spaceTimeStart)+0.5) -- These PPQ values may contain fractions
            local spacePPQend   = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, spaceTimeEnd)+0.5)
            local spacePPQlength = spacePPQend - spacePPQstart
            local MIDIOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
            if not MIDIOK then
                reaper.MB("The script could not load the raw MIDI data of all MIDI items.", "ERROR", 1)
                tryToUndo = true
                goto quit
            else
                local MIDIlen = MIDIstring:len()
                local runningPPQpos = 0
                local prevStrPos, nextStrPos = 1, 1 -- positions inside MIDIstring while parsing
                local tNotes, tNoteOffs, tOtherMIDI = {}, {}, {}
                local lastStringPosOfFirstPart, lastPPQinFirstPart, lastNoteOffPPQ = 0, 0, 0
                local extractNoteOff = nil
                
                local offset, flags, msg, nextStrPos = string.unpack("i4Bs4", MIDIstring, prevStrPos)
                local runningPPQpos = offset
                if runningPPQpos > spacePPQend then goto beyondSpace
                elseif runningPPQpos >= spacePPQstart then goto withinSpace
                end
                
                ::beforeSpaceStart::
                    if msg:len() == 3 then
                        local msg1, msg2, msg3 = msg:byte(1,3)
                        eventType = msg1>>4
                        if eventType == 9 and msg3 ~= 0 then
                            local index = (msg2<<11) | ((msg1&0x0F)<<4) | flags
                            if tNotes[index] == nil then tNotes[index] = 1 else tNotes[index] = tNotes[index] + 1 end
                        elseif eventType == 9 or eventType == 8 then
                            local index = (msg2<<11) | ((msg1&0x0F)<<4) | flags
                            if tNotes[index] == 1 then tNotes[index] = nil else tNotes[index] = tNotes[index] - 1 end
                        end
                    end
                    if nextStrPos >= MIDIlen then
                        goto noNeedToChangeMIDI
                    else
                        prevStrPos = nextStrPos
                        offset, flags, msg, nextStrPos = string.unpack("i4Bs4", MIDIstring, prevStrPos)
                        runningPPQpos = runningPPQpos + offset
                        if runningPPQpos < spacePPQstart then 
                            goto beforeSpaceStart
                        elseif runningPPQpos <= spacePPQend and next(tNotes) ~= nil then
                            lastStringPosOfFirstPart = prevStrPos-1
                            lastPPQinFirstPart       = runningPPQpos - offset
                            lastNoteOffPPQ = lastPPQinFirstPart
                            goto withinSpace
                        else -- runningPPQpos > spacePPQend
                            lastStringPosOfFirstPart = prevStrPos-1
                            goto beyondSpace
                            --newMIDIstring = MIDIstring:sub(1,prevStrPos-1) .. string.pack("i4Bs4", offset+spacePPQlength, flags, msg) .. 
                        end
                    end
                        
                ::withinSpace::
                    -- If past spacePPQstart, extract note-offs for active notes so that they don't get extended 
                    --    - but only if the notes are short enough that note-offs fall within the time selection.  
                    extractNoteOff = nil             
                    if msg:len() == 3 then
                        local msg1, msg2, msg3 = msg:byte(1,3)
                        eventType = msg1>>4
                        if eventType == 8 or (eventType == 9 and msg3 == 0) then
                            local index = (msg2<<11) | ((msg1&0x0F)<<4) | flags
                            if tNotes[index] ~= nil then 
                                extractNoteOff = true
                                if tNotes[index] == 1 then tNotes[index] = nil
                                else tNotes[index] = tNotes[index] - 1
                    end end end end
                    if extractNoteOff then
                        table.insert(tNoteOffs, string.pack("i4Bs4", runningPPQpos - lastNoteOffPPQ, flags, msg))
                        lastNoteOffPPQ = runningPPQpos
                        table.insert(tOtherMIDI, string.pack("i4Bs4", offset, 0, "")) -- replace note-off events in main string with empty events
                    else
                        table.insert(tOtherMIDI, string.pack("i4Bs4", offset, flags, msg))
                    end
                    prevStrPos = nextStrPos
                    if nextStrPos >= MIDIlen or next(tNotes) == nil then
                        goto beyondSpace
                    else
                        offset, flags, msg, nextStrPos = string.unpack("i4Bs4", MIDIstring, prevStrPos)
                        runningPPQpos = runningPPQpos + offset
                        if runningPPQpos <= spacePPQend then 
                            goto withinSpace
                        else -- runningPPQpos > spacePPQend
                            goto beyondSpace
                        end
                    end
                      
                ::beyondSpace::  
                    local newMIDIstring = MIDIstring:sub(1,lastStringPosOfFirstPart) 
                                .. table.concat(tNoteOffs) 
                                .. string.pack("i4Bs4", lastPPQinFirstPart-lastNoteOffPPQ+spacePPQlength, 0, "") 
                                .. table.concat(tOtherMIDI) 
                                .. MIDIstring:sub(prevStrPos)
                    local setMIDIOK = reaper.MIDI_SetAllEvts(take, newMIDIstring)
                    if not setMIDIOK then
                        reaper.MB("The script could not edit the raw MIDI data of all MIDI items.", "ERROR", 1)
                        tryToUndo = true
                        goto quit
                    end
                    
                ::noNeedToChangeMIDI::
                
end end end end


---------------------------
---------------------------
-- Quit
::quit::
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Insert empty beats in selection", -1)

if tryToUndo then
    if reaper.Undo_CanUndo2(0) == "Insert empty beats in selection" then
        couldUndo = reaper.Undo_DoUndo2(0)
        if couldUndo == 0 then
            reaper.MB("Could not undo changes.  Please undo manually.", "ERROR", 1)
        end
    end
end

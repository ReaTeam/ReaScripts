-- @description ReaLoop Arranged Live Looper
-- @author ilovemedia
-- @version 1.0
-- @about
--   # ReaLoop: Arranged Live Looper
--
--   ## Main Features
--     * Hands-free live looping
--     * Supports both MIDI and audio
--     * Auto-punch on each live recording item
--     * Repeat live recording sections wherever you want, even on other tracks with different parameters or instruments.
--     * Automatically select tracks using markers
--
--     ## Prepare your template for live looping
--     * Regardless of whether the track is audio or MIDI, create empty MIDI placeholder items (Insert → New MIDI Item) for both recording and playback/loop areas.
--     * Format the `Take Name` attribute of these placeholder items:
--        - Add `live`  to the end to designate the item as a LIVE recording slot.
--        - Add `loop` to the end to designate the item as a PLAYBACK/LOOP slot.
--     * Place project markers directly on the timeline where you want ReaLoop to arm the next instrument track. Name the marker identically to the track name.
--    * For examples and tutorials, visit https://ilovemedia.es/looper-reaper/
--
--    ## Track Modifiers
--    * **Manual Fades (for audio tracks):** Prepend `manual` to your track name (e.g. "manual drums"). ReaLoop will NOT apply automatic 5 ms click-fades to audio loops on this track, leaving fades to your discretion. 
--     * **Monitor Only:** Prepend `monitor` to your track name (e.g. "monitor vocals"). The script will disable recording on this track while keeping input monitoring enabled, so you can jam freely while still hearing the input.

-- ======================================================================
--  TOGGLE (allows an on/off button in the REAPER toolbar)
-- ======================================================================
if reaper.set_action_options then reaper.set_action_options(1) end
local _, _, sectionID, cmdID = reaper.get_action_context()


-- ======================================================================
-- CONFIGURATION  (edit these to match your project conventions)
-- ======================================================================
local config = {
    recordName      = "live",   -- keyword at end of take name → recording item (e.g. "piano live")
    playbackName    = "loop",   -- keyword at end of take name → playback item  (e.g. "piano loop")
    monitorName     = "monitor",-- keyword at start of track name → record disable & monitor input only
    manualFadeName  = "manual", -- keyword at start of track name → do not apply auto-fades
    audioCrossfade  = 0.005,    -- seconds (5ms) miniscule fade to avoid clicks in audio loops
    markerLookahead = 0.1,      -- seconds before a cross-track marker to pre-switch tracks.
                                -- This pre-arms the next track so REAPER's autopunch can start
                                -- at sample accuracy.  Piano1 loses the last markerLookahead
                                -- seconds of its recording (trade-off, tune as needed).
    redColor        = reaper.ColorToNative(255, 0, 0) | 0x1000000,
    greenColor      = reaper.ColorToNative(0, 255, 0) | 0x1000000,
}


-- ======================================================================
-- STATE  (all mutable script state in one place — no loose globals)
-- ======================================================================
-- Pre-lowercase config strings at parsing time to avoid doing it per-frame.
config.recordName   = config.recordName:lower()
config.playbackName = config.playbackName:lower()
config.monitorName  = config.monitorName:lower()
config.manualFadeName = config.manualFadeName:lower()

local state = {
    prevTrack            = nil,   -- track selected in the previous cycle
    punchStarted         = false, -- true while the script considers us inside a punch
    isMIDI               = false, -- true if the current track has a MIDI input
    lastMarker           = "",    -- last marker name reacted to (cache to avoid repeating)
    snap                 = nil,   -- {pos, len, track, item} of the current record item
    ghostCleanupUntil    = 0,     -- real-time timestamp when cleaning should stop
    ghostCleanupTrack    = nil,   -- track to clean until the timer expires
    lastMIDIData         = nil,   -- caches MIDI data to skip redundant UI updates
    midiUpdateCounter    = 0,     -- throttles MIDI mirroring (cycles)
    trackCache           = {},    -- O(1) marker to track lookup
    targetLoopItems      = {},    -- Cached loop items for MirrorMIDI
    hasPlayed            = false, -- tracked to auto-kill on STOP
    capturedSourceItem   = nil,   -- temporarily holds the recorded item during cross-track switch
}


-- ======================================================================
-- UTILITIES
-- ======================================================================

-- Returns the active take name of an item, or "" if there is no active take.
local function GetItemName(item)
    if not item or not reaper.ValidatePtr(item, "MediaItem*") then return "" end
    local take = reaper.GetActiveTake(item)
    return take and reaper.GetTakeName(take) or ""
end

-- Returns true if the given track has a MIDI input.
-- I_RECINPUT >= 4096 covers all virtual and hardware MIDI inputs in REAPER.
-- (v1.0 used a whitelisted audio-input array — less reliable with multi-I/O interfaces.)
local function TrackIsMIDI(track)
    return reaper.GetMediaTrackInfo_Value(track, "I_RECINPUT") >= 4096
end

-- Returns the current position of the playhead (or edit cursor when stopped).
local function GetPlayPos()
    if reaper.GetPlayState() == 0 then
        return reaper.GetCursorPosition()
    end
    return reaper.GetPlayPosition()
end


-- ======================================================================
-- COLORS & LOOP-SOURCE SETUP
-- ======================================================================

-- Colors all "live" items red (no looping) and all "loop" items green (looping).
-- Called once on startup and again after each recording pass.
local function ApplyInitialSetup()
    local liveLengths = {}
    for i = 0, reaper.CountMediaItems(0) - 1 do
        local item = reaper.GetMediaItem(0, i)
        local name = GetItemName(item):lower()
        if name:find(config.recordName) then
            local baseName = name:gsub(config.recordName, "")
            local currentLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            
            -- Use the max length to filter out tiny remnants created by REAPER auto-splits
            if not liveLengths[baseName] or currentLen > liveLengths[baseName] then
                liveLengths[baseName] = currentLen
            end
            
            reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", config.redColor)
            reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 0)
            
            -- Apply fade to live item if the track is not MIDI and not manual
            local liveTrack = reaper.GetMediaItem_Track(item)
            if liveTrack then
                local liveApplyFade = true
                if TrackIsMIDI(liveTrack) then
                    liveApplyFade = false
                else
                    local _, ltrName = reaper.GetSetMediaTrackInfo_String(liveTrack, "P_NAME", "", false)
                    if ltrName:lower():find(config.manualFadeName, 1, true) == 1 then
                        liveApplyFade = false
                    end
                end
                if liveApplyFade then
                    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", config.audioCrossfade)
                    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", config.audioCrossfade)
                end
            end
        end
    end

    for i = reaper.CountMediaItems(0) - 1, 0, -1 do
        local item = reaper.GetMediaItem(0, i)
        local name = GetItemName(item):lower()
        if name:find(config.playbackName) then
            local baseName = name:gsub(config.playbackName, "")
            local iLen = liveLengths[baseName]
            
            local applyFade = true
            local track = reaper.GetMediaItem_Track(item)
            if track then
                if TrackIsMIDI(track) then
                    applyFade = false
                else
                    local _, trName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                    if trName:lower():find(config.manualFadeName, 1, true) == 1 then
                        applyFade = false
                    end
                end
            end
            
            if iLen then
                local pLen = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                if pLen > iLen + 0.001 then
                    local iPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    local currentItem = item
                    local splitPos = iPos + iLen
                    local pieces = { currentItem }
                    
                    while splitPos < iPos + pLen - 0.001 do
                        local newItem = reaper.SplitMediaItem(currentItem, splitPos)
                        if not newItem then break end
                        table.insert(pieces, newItem)
                        currentItem = newItem
                        splitPos = splitPos + iLen
                    end
                    
                    for _, piece in ipairs(pieces) do
                        reaper.SetMediaItemInfo_Value(piece, "I_CUSTOMCOLOR", config.greenColor)
                        reaper.SetMediaItemInfo_Value(piece, "B_LOOPSRC", 1)
                        if applyFade then
                            reaper.SetMediaItemInfo_Value(piece, "D_FADEINLEN", config.audioCrossfade)
                            reaper.SetMediaItemInfo_Value(piece, "D_FADEOUTLEN", config.audioCrossfade)
                        end
                        reaper.UpdateItemInProject(piece)
                    end
                else
                    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", config.greenColor)
                    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 1)
                    if applyFade then
                        reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", config.audioCrossfade)
                        reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", config.audioCrossfade)
                    end
                end
            else
                reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", config.greenColor)
                reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 1)
            end
        end
    end
end

-- Builds an O(1) dictionary mapping track names to track pointers, avoiding
-- looping through the entire project every time a marker is read at 30Hz.
local function RebuildTrackCache()
    state.trackCache = {}
    for i = 0, reaper.CountTracks(0) - 1 do
        local tr = reaper.GetTrack(0, i)
        local _, trName = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
        local lowerName = trName:lower()
        state.trackCache[lowerName] = tr
        
        -- Support for marker aliases (e.g. "voice" targets "manual voice")
        local startWord = lowerName:find(config.manualFadeName, 1, true)
        if startWord == 1 then
            local aliasName = lowerName:sub(#config.manualFadeName + 1)
            -- Trim leading space to correctly match standard markers
            aliasName = aliasName:match("^%s*(.-)$")
            if aliasName and aliasName ~= "" then
                state.trackCache[aliasName] = tr
            end
        end
    end
end


-- ======================================================================
-- TRACK ARM & MONITORING
-- ======================================================================
-- Track arming is fully handled by REAPER's "Automatic record-arm when track is selected".
-- Ghost-take prevention relies on CleanGhostAudioItems (post-recording cleanup).


-- ======================================================================
-- TIME SELECTION & SNAP
-- ======================================================================

-- Finds the current or next "live" item on the track (relative to playPos),
-- sets the autopunch time selection, and stores a "snap" with its metadata.
local function SyncTimeSelection(track, playPos)
    if not track then return end

    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item  = reaper.GetTrackMediaItem(track, i)
        local name  = GetItemName(item):lower()

        if name:find(config.recordName) then
            local iStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local iEnd   = iStart + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")

            -- Accept this item if the playhead hasn't passed it yet:
            -- either the item starts at/after the playhead, or we're inside it.
            if iStart >= playPos or (playPos > iStart and playPos < iEnd) then
                state.snap = { pos = iStart, len = iEnd - iStart, track = track, item = item }
                reaper.GetSet_LoopTimeRange(true, false, iStart, iEnd, false)
                reaper.UpdateArrange()
                return
            end
        end
    end

    -- No valid record item found ahead → clear everything.
    reaper.GetSet_LoopTimeRange(true, false, 0, 0, false)
    state.snap = nil
end


-- ======================================================================
-- MIDI: real-time mirror and post-recording chord fix
-- ======================================================================

-- Copies the current MIDI content of the record item to pre-cached "loop" target items.
-- Throttled to ~15fps with a dirty-flag to avoid massive API overhead during real-time preview.
local function MirrorMIDI(forceUpdate)
    if not state.snap then return end
    local recordItem = state.snap.item
    if not recordItem or not reaper.ValidatePtr(recordItem, "MediaItem*") then return end

    local recTake = reaper.GetActiveTake(recordItem)
    if not recTake then return end

    -- Throttle real-time visual updates to ~15-20 Hz instead of 60 Hz
    if not forceUpdate then
        state.midiUpdateCounter = (state.midiUpdateCounter + 1) % 3
        if state.midiUpdateCounter ~= 0 then return end
    end

    local _, midiData = reaper.MIDI_GetAllEvts(recTake, "")
    
    -- Dirty flag: avoid massive UI redraws and API allocations if events didn't actually change
    if state.lastMIDIData == midiData and not forceUpdate then return end
    state.lastMIDIData = midiData

    for _, it in ipairs(state.targetLoopItems) do
        if reaper.ValidatePtr(it, "MediaItem*") then
            local pTake = reaper.GetActiveTake(it)
            if pTake then
                reaper.MIDI_SetAllEvts(pTake, midiData)
                reaper.SetMediaItemInfo_Value(it, "B_LOOPSRC", 1)
                reaper.UpdateItemInProject(it)
            end
        end
    end
end

-- After MIDI punch-out: truncates any notes that extend beyond the punch-out point,
-- then enables B_LOOPSRC so the item loops correctly.
-- Without this, REAPER's "Chase MIDI note-ons" engine would re-trigger held notes
-- when the playhead crosses into the newly unmuted playback items.
local function ChordRescueMIDI()
    if not state.snap then return end
    local item = state.snap.item
    if not item or not reaper.ValidatePtr(item, "MediaItem*") then return end

    local take = reaper.GetActiveTake(item)
    if not take or not reaper.TakeIsMIDI(take) then return end

    -- Truncate hanging notes exactly at the point recording stopped (the marker).
    -- This explicitly closes notes before the item boundary, preventing REAPER's
    -- "Chase MIDI note-ons" engine from synthesizing ghost attacks when playhead 
    -- seamlessly crosses into the newly unmuted playback items.
    local trunc_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, GetPlayPos())
    local _, noteCount = reaper.MIDI_CountEvts(take)
    for i = 0, noteCount - 1 do
        local r, sel, mut, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        if r and endppq > trunc_ppq then
            -- Avoid making notes backwards if startppq is somehow placed past playPos
            local new_end = math.max(startppq, trunc_ppq)
            reaper.MIDI_SetNote(take, i, sel, mut, startppq, new_end, chan, pitch, vel, true)
        end
    end

    reaper.MIDI_Sort(take)
    reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", 1)
end


-- ======================================================================
-- AUDIO: crop, glue, and mirror to playback items
-- ======================================================================

-- After audio punch-out: gets the newly recorded item (REAPER selects it automatically
-- when recording stops), crops it, glues it within the original time selection, then
-- mirrors its PCM source to all matching "loop" items.
-- Using GetSelectedMediaItem (same as v1.0) avoids confusing the audio item with the
-- MIDI placeholder that sits at the same position on the track.
local function FinalizeAudio(capturedSourceItem)
    if not state.snap then return end

    local iStart = state.snap.pos
    local iLen   = state.snap.len

    -- Use the explicitly captured sourceItem if provided (cross-track switch),
    -- otherwise fall back to REAPER's current selection (normal punch-out).
    local sourceItem = capturedSourceItem or reaper.GetSelectedMediaItem(0, 0)
    if not sourceItem then return end

    -- Determine if auto-fades should be applied.
    local applyFade = true
    local sourceTrack = reaper.GetMediaItem_Track(sourceItem)
    if sourceTrack then
        local _, trName = reaper.GetSetMediaTrackInfo_String(sourceTrack, "P_NAME", "", false)
        if trName:lower():find(config.manualFadeName, 1, true) == 1 then
            applyFade = false
        end
    end
    
    -- Capture the ACTUAL recorded audio length before crop/glue destroys it.
    -- If recording was cut short by a cross-track lookahead switch, sourceLen < iLen.
    local sourceLen = reaper.GetMediaItemInfo_Value(sourceItem, "D_LENGTH")

    -- Apply a pre-glue fade-out to the sourceItem. Since the item's length still
    -- matches the actual audio content, D_FADEOUTLEN fades the REAL audio endpoint.
    -- This fade gets BAKED into the WAV when the subsequent glue renders a new file.
    -- Use a slightly larger fade (4x the boundary fade) for effective anti-click.
    if applyFade then
        reaper.SetMediaItemInfo_Value(sourceItem, "D_FADEINLEN", config.audioCrossfade)
        reaper.SetMediaItemInfo_Value(sourceItem, "D_FADEOUTLEN", config.audioCrossfade * 4)
    end

    -- Remember the original take name from the FIRST take (before crop removes extra takes).
    local firstTake  = reaper.GetTake(sourceItem, 0)
    local takeName   = firstTake and reaper.GetTakeName(firstTake) or ""

    -- Rename the active take to preserve the name through crop+glue.
    local activeTake = reaper.GetActiveTake(sourceItem)
    if activeTake and takeName ~= "" then
        reaper.GetSetMediaItemTakeInfo_String(activeTake, "P_NAME", takeName, true)
    end

    -- Ensure the sourceItem is selected (it may not be if captured during cross-track switch).
    reaper.SelectAllMediaItems(0, false)
    reaper.SetMediaItemSelected(sourceItem, true)

    -- Crop to active take
    reaper.Main_OnCommand(40131, 0)                                -- Crop to active take

    reaper.GetSet_LoopTimeRange(true, false, iStart, iStart + iLen, false)
    reaper.Main_OnCommand(42432, 0)                                -- Glue items within time selection

    -- REAPER's 'Glue within time selection' splits items and notoriously leaves the 
    -- outside remnant snippets selected! We must explicitly find the glued body.
    local glued = nil
    for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        local pos  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        -- The actual glued item starts EXACTLY at iStart
        if math.abs(pos - iStart) < 0.05 then
            glued = item
            break
        end
    end

    if not glued then return end

    -- Apply name and color to the glued item.
    local gluedTake = reaper.GetActiveTake(glued)
    if gluedTake then
        if takeName ~= "" then
            reaper.GetSetMediaItemTakeInfo_String(gluedTake, "P_NAME", takeName, true)
        end
        reaper.SetMediaItemTakeInfo_Value(gluedTake, "I_CUSTOMCOLOR", config.redColor)
    end
    reaper.SetMediaItemInfo_Value(glued, "I_CUSTOMCOLOR", config.redColor)
    reaper.SetMediaItemInfo_Value(glued, "B_LOOPSRC", 0)

    local gluedTrack = reaper.GetMediaItem_Track(glued)
    if gluedTrack then
        -- Pass 1: Selection-based cleanup for glue remnants.
        reaper.SetMediaItemSelected(glued, false)
        for i = reaper.CountSelectedMediaItems(0) - 1, 0, -1 do
            local remnant = reaper.GetSelectedMediaItem(0, i)
            if reaper.GetMediaItem_Track(remnant) == gluedTrack then
                reaper.DeleteTrackMediaItem(gluedTrack, remnant)
            end
        end
        reaper.SetMediaItemSelected(glued, true)
        
        -- Pass 2: Sweep orphaned micro-items on this track.
        -- Any item < 1 second is a fragment (legitimate items are always several seconds).
        for i = reaper.CountTrackMediaItems(gluedTrack) - 1, 0, -1 do
            local trackItem = reaper.GetTrackMediaItem(gluedTrack, i)
            if trackItem ~= glued then
                local itemLen = reaper.GetMediaItemInfo_Value(trackItem, "D_LENGTH")
                if itemLen < 1.0 then
                    reaper.DeleteTrackMediaItem(gluedTrack, trackItem)
                end
            end
        end
    end
    
    -- Standard 5ms item-level fades for loop boundary clicks (on the final item).
    if applyFade and glued then
        reaper.SetMediaItemInfo_Value(glued, "D_FADEINLEN", config.audioCrossfade)
        reaper.SetMediaItemInfo_Value(glued, "D_FADEOUTLEN", config.audioCrossfade)
    end

    -- Mirror PCM source to all matching "loop" items.
    local sourcePCM  = gluedTake and reaper.GetMediaItemTake_Source(gluedTake) or nil
    local baseName   = takeName:lower():gsub(config.recordName, "")
    local targetName = baseName .. config.playbackName

    for i = 0, reaper.CountMediaItems(0) - 1 do
        local it = reaper.GetMediaItem(0, i)
        if GetItemName(it):lower() == targetName then
            local pTake = reaper.GetActiveTake(it) or reaper.AddMediaItemTake(it)
            if sourcePCM then reaper.SetMediaItemTake_Source(pTake, sourcePCM) end
            reaper.SetMediaItemInfo_Value(it, "B_LOOPSRC", 1)
            reaper.SetMediaItemInfo_Value(it, "I_CUSTOMCOLOR", config.greenColor)
            
            if applyFade then
                reaper.SetMediaItemInfo_Value(it, "D_FADEINLEN", config.audioCrossfade)
                reaper.SetMediaItemInfo_Value(it, "D_FADEOUTLEN", config.audioCrossfade)
            end
            
            reaper.UpdateItemInProject(it)
        end
    end

    reaper.SelectAllMediaItems(0, false)
    reaper.UpdateArrange()

    -- Update snap to point to the finalized item.
    if state.snap then state.snap.item = glued end
end


-- ======================================================================
-- GHOST-TAKE CLEANUP  (audio safety net)
-- ======================================================================

-- Removes audio items on the track whose takes don't match "live" or "loop".
-- Scheduled with a precise 1.5s real-time timeout after each audio punch-out to reliably
-- catch anything REAPER creates asynchronously, regardless of GUI frame rates.
local function CleanGhostAudioItems(track)
    if not track or not reaper.ValidatePtr(track, "MediaTrack*") then return end
    local changed = false
    for i = reaper.CountTrackMediaItems(track) - 1, 0, -1 do
        local it       = reaper.GetTrackMediaItem(track, i)
        local numTakes = reaper.GetMediaItemNumTakes(it)
        local hasLegit = false

        for t = 0, numTakes - 1 do
            local tk = reaper.GetMediaItemTake(it, t)
            if tk then
                local n = reaper.GetTakeName(tk):lower()
                if n:find(config.recordName) or n:find(config.playbackName) then
                    hasLegit = true
                    break
                end
            end
        end

        if not hasLegit then
            reaper.DeleteTrackMediaItem(track, it)
            changed = true
        end
    end
    if changed then reaper.UpdateArrange() end
end


-- ======================================================================
-- EVENT HANDLERS
-- ======================================================================

-- Called once when the selected track changes.
-- Track arming is handled by REAPER's auto-arm; we only manage the punch zone here.
local function OnTrackChanged(newTrack)
    -- Determine input type FIRST — other decisions depend on it.
    state.isMIDI = TrackIsMIDI(newTrack)

    -- Update the punch zone to the current/next "live" item on this track.
    SyncTimeSelection(newTrack, GetPlayPos())

    -- If playback is running but NOT recording yet, start recording.
    -- This covers: initial start, and restart after audio FinalizeAudio stopped it.
    -- When already recording (MIDI cross-track), recording continues uninterrupted.
    if reaper.GetPlayState() == 1 then
        reaper.Main_OnCommand(1013, 0)  -- Transport: Start/stop recording
    end
end

-- Called when recording enters the punch zone.
local function OnPunchIn()
    if state.isMIDI then
        state.lastMIDIData = nil -- reset dirty flag for new item
        
        -- Cache target loop items ONCE when recording starts
        state.targetLoopItems = {}
        if state.snap and state.snap.item then
            local baseName   = GetItemName(state.snap.item):lower():gsub(config.recordName, "")
            local targetName = baseName .. config.playbackName
            for i = 0, reaper.CountMediaItems(0) - 1 do
                local it = reaper.GetMediaItem(0, i)
                if GetItemName(it):lower() == targetName then
                    table.insert(state.targetLoopItems, it)
                end
            end
        end
        
        MirrorMIDI(true)         -- start live MIDI preview
    end
end

-- Processes the recorded data for the track that was just punched out.
-- Does NOT stop/start recording — the caller handles timing to minimize the gap.
local function OnPunchOut()
    if state.isMIDI then
        ChordRescueMIDI()    -- truncate hanging notes at the punch-out point
        MirrorMIDI(true)     -- final push to playback items
    else
        FinalizeAudio(state.capturedSourceItem)    -- crop → glue → mirror to "loop" items

        -- Schedule ghost cleanup for the next 1.5 real-time seconds.
        if state.snap and state.snap.track then
            state.ghostCleanupTrack    = state.snap.track
            state.ghostCleanupUntil    = reaper.time_precise() + 1.5
        end
    end
    ApplyInitialSetup()
end


-- ======================================================================
-- MAIN LOOP
-- Single defer loop replaces v1.0's three parallel loops (CheckMarkers,
-- CheckTrackSelectionChange, CheckRecording).  All checks run in sequence
-- on every cycle — same behavior, lower overhead, no inter-loop timing issues.
-- ======================================================================
local function Main()
    if reaper.GetToggleCommandStateEx(sectionID, cmdID) <= 0 then return end

    local playState = reaper.GetPlayState()
    if playState > 0 then
        state.hasPlayed = true
    elseif state.hasPlayed and playState == 0 then
        return -- Auto-kill script gracefully (triggers atexit) when playback is stopped
    end

    local playPos = GetPlayPos()

    -- ── 1. Real-time Ghost Cleanup ──────────────────────────────────────
    if state.ghostCleanupTrack then
        if reaper.time_precise() < state.ghostCleanupUntil then
            CleanGhostAudioItems(state.ghostCleanupTrack)
        else
            state.ghostCleanupTrack = nil
        end
    end

    -- ── 2. Marker check + lookahead ──────────────────────────────────────────
    -- Check the marker at playPos AND at (playPos + markerLookahead).
    -- If the look-ahead reveals an upcoming track-change marker, pre-select
    -- that track NOW (using O(1) state.trackCache lookup) so REAPER arms it before the boundary.
    local mIdx         = reaper.GetLastMarkerAndCurRegion(0, playPos)
    local lookaheadIdx = reaper.GetLastMarkerAndCurRegion(0, playPos + config.markerLookahead)
    local checkIdx = (lookaheadIdx ~= mIdx and lookaheadIdx >= 0) and lookaheadIdx or mIdx
    if checkIdx >= 0 then
        local _, isRgn, _, _, mName = reaper.EnumProjectMarkers(checkIdx)
        if not isRgn and mName and mName ~= "" and mName:lower() ~= state.lastMarker then
            local tr = state.trackCache[mName:lower()]
            if tr and reaper.ValidatePtr(tr, "MediaTrack*") then
                reaper.SetOnlyTrackSelected(tr)
                state.lastMarker = mName:lower()
            end
        end
    end

    -- ── 3. Track selection change ────────────────────────────────────────
    local currentTrack = reaper.GetSelectedTrack(0, 0)
    if currentTrack and currentTrack ~= state.prevTrack then
        if state.punchStarted then
            -- CROSS-TRACK SWITCH while recording.
            -- Minimize the gap via a transactional triple-safeguard:
            -- STOP → Validate → Set TS & START → Validate → Process old data.
            -- This prevents asynchronous toggle-glitches from corrupting the internal state.
            state.punchStarted = false
            local oldSnap   = state.snap
            local oldIsMIDI = state.isMIDI

            -- 1. Stop recording (finalizes the current take)
            if reaper.GetPlayState() & 4 == 4 then
                reaper.Main_OnCommand(1013, 0)
            end

            -- CRITICAL: Capture the just-recorded item on the OLD track NOW,
            -- while REAPER still has it selected.
            local capturedSource = nil
            local oldTrack = oldSnap and oldSnap.track or nil
            if oldTrack then
                for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
                    local item = reaper.GetSelectedMediaItem(0, i)
                    if reaper.GetMediaItem_Track(item) == oldTrack then
                        capturedSource = item
                        break
                    end
                end
            end
            if not capturedSource then
                capturedSource = reaper.GetSelectedMediaItem(0, 0)
            end

            -- Verify it actually stopped before proceeding
            if reaper.GetPlayState() & 4 == 0 then
                -- 2. Immediately set up and start recording on the new track
                state.isMIDI = TrackIsMIDI(currentTrack)
                SyncTimeSelection(currentTrack, GetPlayPos())
                
                if reaper.GetPlayState() == 1 then
                    reaper.Main_OnCommand(1013, 0)
                end

                -- Verify it actually started before processing the old data
                if reaper.GetPlayState() & 4 == 4 then
                    -- 3. Now process the old track's data
                    local newSnap = state.snap
                    state.snap   = oldSnap
                    state.isMIDI = oldIsMIDI
                    state.capturedSourceItem = capturedSource
                    OnPunchOut()  -- processes old data, doesn't touch recording
                    state.capturedSourceItem = nil
                    state.snap   = newSnap
                    state.isMIDI = TrackIsMIDI(currentTrack)
                end
                
                -- State fully safely synced, track successfully switched
                state.prevTrack = currentTrack
            else
                -- Play state did not sync in this block frame.
                -- Revert punchStarted so we try again next cycle,
                -- and DO NOT update prevTrack so this block re-triggers next loop.
                state.punchStarted = true
            end
        else
            -- Track changed while NOT recording — normal setup.
            OnTrackChanged(currentTrack)
            state.prevTrack = currentTrack
        end
    end

    -- ── 4. Punch state machine ───────────────────────────────────────────
    local isRecording = (playState & 4 == 4)
    local _, endSel   = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    if isRecording and playPos < endSel then
        -- Inside punch zone while recording.
        if not state.punchStarted then
            state.punchStarted = true
            OnPunchIn()
        end
        -- Real-time MIDI mirror: push data every cycle so the loop item stays in sync.
        if state.isMIDI then MirrorMIDI() end

    elseif state.punchStarted then
        -- Was punching on the same track, now outside zone or stopped.
        state.punchStarted = false
        -- Stop recording and restart for same-track adjacent items.
        if reaper.GetPlayState() & 4 == 4 then
            reaper.Main_OnCommand(1013, 0)
        end
        OnPunchOut()
        SyncTimeSelection(reaper.GetSelectedTrack(0, 0), GetPlayPos())
        if reaper.GetPlayState() == 1 and state.snap then
            reaper.Main_OnCommand(1013, 0)
        end
    end

    reaper.defer(Main)
end


-- ======================================================================
-- SCRIPT START
-- ======================================================================
reaper.atexit(function()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
    reaper.GetSet_LoopTimeRange(true, false, 0, 0, false)
end)

reaper.SetToggleCommandState(sectionID, cmdID, 1)
reaper.RefreshToolbar2(sectionID, cmdID)
reaper.Main_OnCommand(40076, 0)      -- Record mode: Time Selection Auto-Punch

-- Configure track record states at startup
for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, trName = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    
    -- "Monitor" tracks get input-only configuration
    if trName:lower():find(config.monitorName, 1, true) == 1 then
        reaper.SetMediaTrackInfo_Value(tr, "B_AUTO_RECARM", 0) -- Disable auto-arm on selection
        reaper.SetMediaTrackInfo_Value(tr, "I_RECMODE", 2)   -- Record: disable (input monitoring only)
        reaper.SetMediaTrackInfo_Value(tr, "I_RECMON", 1)    -- Monitor Input ON
        reaper.SetMediaTrackInfo_Value(tr, "I_RECARM", 1)    -- Arm track so monitoring works continuously
    else
        reaper.SetMediaTrackInfo_Value(tr, "B_AUTO_RECARM", 1) -- Enable auto-arm for normal tracks
        -- Set MIDI instrument tracks to "Record: MIDI overdub" mode automatically
        if TrackIsMIDI(tr) then
            reaper.SetMediaTrackInfo_Value(tr, "I_RECMODE", 7) -- Record: MIDI overdub
        end
    end
end

RebuildTrackCache()
ApplyInitialSetup()

-- Initialize state for the currently selected track (if any).
local initTrack = reaper.GetSelectedTrack(0, 0)
if initTrack then
    state.isMIDI    = TrackIsMIDI(initTrack)
    state.prevTrack = initTrack
    -- Track arming handled by REAPER's auto-arm on selection.
    SyncTimeSelection(initTrack, GetPlayPos())
end

Main()

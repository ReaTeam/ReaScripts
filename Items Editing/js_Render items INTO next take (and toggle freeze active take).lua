--[[
ReaScript name: js_Render items INTO next take (toggle freeze active take).lua
Version: 0.91
Author: juliansader
Screenshot: https://stash.reaper.fm/32789/REAPER%20-%20Render%20take%20INTO%20next%20take%2C%20set%20FX%20offline.gif
Website: https://forum.cockos.com/showthread.php?t=202505
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION

  This script employs REAPER's multi-take capabilities to achieve multi-step freezing of items, 
      as well as easy editing and re-rendering of frozen items.
  
  Each take can represent a step in the editing process, e.g.
       MIDI (with VSTi's as Take FX) -> audio (with Take Envelopes) -> audio (with stretch markers) -> etc
  
  * Edits can be made to first MIDI take, and re-rendered as new audio into the subsequent takes, without losing any of the audio edits in later takes.
  
  * Take FX, particularly VSTi samplers that require lots of memory, can be set offline after rendering the MIDI.
  
  
  # DETAILS
  
  * The active take is rendered *into* the next take, replacing the next take's source without altering the next take's FX, stretch markers or envelopes.
  
  * Before rendering, the active take's offline Take FX are set online; and after rendering, online Take FX are set offline.  (Track FX are ignored during rendering.)

  * The script automatically renders to the same source type as the next take: either MIDI, mono audio or multi-channel audio.
  
  * If any of the selected items cannot be rendered (for example if the active take is the last take), it will be deselected. 
]] 

--[[
  Changelog:
  * v0.90 (2018-09-14)
    + Initial beta release.
  * v0.91 (2018-09-14)
    + Stretch marker warning message.
]]

reaper.Undo_BeginBlock2(0)
reaper.PreventUIRefresh(1)
--
-- REAPER's API doesn't have "render" functions, so must use Actions.  Different Actions may be used on different items, so 
--    must store IDs of all selected item, then deselect them all and re-select one-by-one.
-- Items that don't have next takes (i.e. render "into" is not applicable, will be deselected after the script).
-- Also store IDs of all tracks that contain selected items, so that their FX can be bypassed.
local tItems  = {}
local tTracks  = {}

for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item  = reaper.GetSelectedMediaItem(0, i)
    local track = reaper.GetMediaItem_Track(item)
    tItems[item] = true --{active = active, activeNum = activeNum}
    tTracks[track] = {track = true} 
end  
    
reaper.SelectAllMediaItems(0, false)

-- Toggle bypass of track FX, and remember which were enabled
for track, tFX in pairs(tTracks) do
    for f = 0, reaper.TrackFX_GetCount(track)-1 do
        if reaper.TrackFX_GetEnabled(track, f) then
            reaper.TrackFX_SetEnabled(track, f, false)
            tFX[#tFX+1] = f
        end
    end
end


-- Iterate through all selected items, render into next take
for item in pairs(tItems) do

    local activeTake = reaper.GetActiveTake(item) 
    local activeNum = reaper.GetMediaItemTakeInfo_Value(activeTake, "IP_TAKENUMBER")
    
    -- If active take is last take, i.e. no "next" take, skip this item and leave unselected
    if activeNum >= reaper.CountTakes(item)-1 then
        tItems[item] = nil
    else
    
        local nextTake   = reaper.GetTake(item, 1 + activeNum) -- Next take in sequence
        local nextSource = reaper.GetMediaItemTake_Source(nextTake)
        local nextOffset = reaper.GetMediaItemTakeInfo_Value(nextTake, "D_STARTOFFS") 
        
        -- REAPER offers several "Appply FX to new take" actions. Must find action that will give same source type as next take's
        local command
        if reaper.TakeIsMIDI(nextTake) then
            command = 40436
        else
            local nextChannels = reaper.GetMediaSourceNumChannels(nextSource)
            if nextChannels == 1 then
                command = 40361
            elseif nextChannels > 1 then
                command = 41993
            end
        end
        
        -- Is it posisble for number of channels to be 0?
        if not command then
            tItems[item] = nil
        else
        
            -- The newly rendered take should be last in sequemce, but to make absolutely sure,
            --    store all original take IDs, so that can be compared after render.
            local tTakes = {}
            for t = 0, reaper.CountTakes(item)-1 do
                tTakes[reaper.GetTake(item, t)] = true
            end
            
            -- Stretch markers prevent changing take offset.  So store and temporarily delete.
            local tStretch = {}
            local numStretchMarkers = reaper.GetTakeNumStretchMarkers(nextTake)
            for s = 0, numStretchMarkers-1 do
                local OK, pos, srcpos = reaper.GetTakeStretchMarker(nextTake, s)
                if OK then 
                    slope = reaper.GetTakeStretchMarkerSlope(nextTake, s)
                    tStretch[#tStretch+1] = {pos = pos, srcpos = srcpos, slope = slope}
                else
                    stretchError = true
                end
            end
            local numDeleted = reaper.DeleteTakeStretchMarkers(nextTake, 0, numStretchMarkers)
                if not (numDeleted == numStretchMarkers) then stretchError = true end
        
            -- Set all *offline* Take FX of active take online (ignore bypassed FX)
            for f = 0, reaper.TakeFX_GetCount(activeTake)-1 do
                if reaper.TakeFX_GetOffline(activeTake, f) then
                    reaper.TakeFX_SetOffline(activeTake, f, false)
                    reaper.TakeFX_SetEnabled(activeTake, f, true)
                end
            end
            
            -- APPLY COMMAND TO RENDER!
            reaper.SetMediaItemSelected(item, true)
            reaper.Main_OnCommandEx(command, 0, 0) -- Item: Apply track/take FX to items
            
            -- Set Take FX offline again.  (Ignore bypassed FX.)
            for f = 0, reaper.TakeFX_GetCount(activeTake)-1 do
                if reaper.TakeFX_GetEnabled(activeTake, f) then
                    reaper.TakeFX_SetOffline(activeTake, f, true)
                end
            end
            
            -- New take is supposed to be last in sequence, but is this always true?  Find new take.
            local newTake
            local newNum
            local newSource   
            for t = 0, reaper.CountTakes(item)-1 do
                local take = reaper.GetTake(item, t)
                if not tTakes[take] then 
                    newTake = take 
                    newNum = t 
                    break 
                end
            end
                     
            -- Move newTake's source into nextTake.  
            --    NB: Must swap, otherwise REAPER will crash.
            --    NB: Must perform in this sequence, otherwise nextTake cannot be opened in MIDI editor - don't know why?
            -- A rendered take has same start position as item, so STARTOFFS must be 0.
            if newTake then
                newSource = reaper.GetMediaItemTake_Source(newTake)
                reaper.SetMediaItemTake_Source(newTake, nextSource)
                reaper.SetMediaItemTake_Source(nextTake, newSource)
                reaper.SetMediaItemTakeInfo_Value(nextTake, "D_STARTOFFS", 0)
                
                reaper.SetActiveTake(newTake)
                reaper.Main_OnCommandEx(40129, 0, 0) -- Take: Delete active take from items
                reaper.SetActiveTake(nextTake)   
                
            end
            
            -- Restore stretch markers
            -- Since the new source has same start position as the item (offset of 0), 
            --    the first stretch marker (which is not stretched at the left), must have the equal pos and srcpos
            --    (positions relative to item start and source start).
            -- Thus all srcpos must be adjusted with (- tStretch[1].srcpos + tStretch[1].pos)
            for s = 1, #tStretch do
                local newSourcePos = tStretch[s].srcpos - tStretch[1].srcpos + tStretch[1].pos
                local index = reaper.SetTakeStretchMarker(nextTake, -1, tStretch[s].pos, newSourcePos) ---nextOffset)
                if index ~= -1 then
                    reaper.SetTakeStretchMarkerSlope(nextTake, index, tStretch[s].slope)
                else
                    stretchError = true
                end
            end
        end
        reaper.SetMediaItemSelected(item, false)  
    end
end
    

-- Re-select all items
for item in pairs(tItems) do
    reaper.SetMediaItemSelected(item, true)
end


-- Toggle bypass of track FX to original state
for track, tFX in pairs(tTracks) do
    for f = 1, #tFX do
        reaper.TrackFX_SetEnabled(track, tFX[f], true)
    end
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()

if stretchError then
    reaper.MB("Some stretch markers may have been misplaced or deleted", "WARNING", 0)
end

reaper.Undo_EndBlock2(0, "Render items into next take", -1)


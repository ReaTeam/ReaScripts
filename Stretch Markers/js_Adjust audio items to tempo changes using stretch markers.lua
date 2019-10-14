--[[
ReaScript name: js_Adjust audio items to tempo changes using stretch markers.lua
Version: 0.90
Author: juliansader
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  Ajdusts audio items to tempo changes and playback rates, using stretch markers.
  
  If the selected item already contains stretch markers, for example at transients, the existing markers will be adjusted to tempo changes.
  
  If the item does not yet contain any stretch markers, new markers will be added below each tempo change, 
      and the slope of each stretch marker will follow linear tempo changes.
  
  Playback rates other than 1 will also be converted to stretch markers.
]] 

--[[
  Changelog:
  * v0.90 (2019-10-13)
    + Initial beta release
]]

userAnswer = nil
YES, NO = 6, 7

for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    
    item = reaper.GetSelectedMediaItem(0, i)
    take = reaper.GetActiveTake(item)
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and not reaper.TakeIsMIDI(take) then
    
        rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE") 
        offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        itemStart  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        itemEnd = itemStart+itemLength
        itemStretchedLength = itemLength*rate
        _, _, _, beatsStart = reaper.TimeMap2_timeToBeats(0, itemStart)
        _, _, _, beatsEnd   = reaper.TimeMap2_timeToBeats(0, itemEnd)
        beatsLength = beatsEnd-beatsStart
        srcposStart, srcposEnd = nil, nil
        
        -- If existing stretch markers, only add new ones at the edges (if necessary).
        if reaper.GetTakeNumStretchMarkers(take) > 0 then
        
            t = {}
            for s = 0, reaper.GetTakeNumStretchMarkers(take)-1 do
                index, timePos, sourcePos = reaper.GetTakeStretchMarker(take, s)
                if -0.000001 < timePos and timePos < 0.000001 then
                    timePos = itemStart
                    srcposStart = sourcePos
                elseif itemStretchedLength-0.000001 < timePos and timePos < itemStretchedLength+0.000001 then
                    timePos = itemLength*rate
                    srcposEnd = sourcePos
                end
                t[s] = {index = index, sourcePos = sourcePos, timePos = timePos}
            end
            
            -- How to get source position at end of item?  
            -- Only way that I know, is to add a stretch marker at time and then read its source position.
            if not srcposStart then 
                reaper.SetTakeStretchMarker(take, -1, 0)
                _, _, srcposStart = reaper.GetTakeStretchMarker(take, -1, 0)
                t[#t+1] = {sourcePos = srcposStart}
            end
            if not srcposEnd then
                reaper.SetTakeStretchMarker(take, -1, itemStretchedLength)
                _, _, srcposEnd = reaper.GetTakeStretchMarker(take, -1, itemStretchedLength)
                t[#t+1] = {sourcePos = srcposEnd}
            end
            sourceVisLength = srcposEnd-srcposStart
            
            table.sort(t, function(a, b) return (a.sourcePos < b.sourcePos) end)
            
            -- To prevent the stretch markers from overlapping and messing up indexing while iterating through them all, 
            --    delete everything and re-insert one by one.
            reaper.DeleteTakeStretchMarkers(take, 0, reaper.GetTakeNumStretchMarkers(take))
            setOK = reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1)
            
            -- Re-inserting the stretch markers is quite short and simple.
            for s = 0, #t do
                t[s].frac = ((t[s].sourcePos-srcposStart)/sourceVisLength)
                t[s].time = reaper.TimeMap2_beatsToTime(0, beatsStart + beatsLength*t[s].frac)
                reaper.SetTakeStretchMarker(take, -1, t[s].time-itemStart, t[s].sourcePos)
            end
            
            -- Must apply slopes *after* all stretch markers have been added, since doesn't work if no later marker yet.
            for s = 0, #t-1 do 
                if t[s].linear and t[s].index > -1 then
                    local r = t[s+1].bpm / t[s].bpm -- API function uses different value for slope than in arrange view UI.  Formula seems to be: (1+slope)/(1-slope) = bpmRight/bpmLeft
                    t[s].slope = (r-1)/(r+1)
                    reaper.SetTakeStretchMarkerSlope(take, t[s].index, t[s].slope)
                end
            end
            for s = 0, #t-1 do
                local indexLeft  = reaper.FindTempoTimeSigMarker(0, t[s].time+0.0000001)
                local indexRight = reaper.FindTempoTimeSigMarker(0, t[s+1].time-0.0000001)
                if indexRight-indexLeft <= 1 and indexLeft ~= -1 then
                    _, _, _, _, _, _, _, linearLeft = reaper.GetTempoTimeSigMarker(0, indexLeft)
                    _, _, _, _, _, _, _, linearRight = reaper.GetTempoTimeSigMarker(0, indexRight)
                    if linearLeft and linearRight then
                        if not userAnswer then
                            userAnswer = reaper.ShowMessageBox("Linear tempo changes have been detected.\n\nShould sloped stretch markers be used?\n\n(NB: downward slopes may cause pre-echo artefacts.)", "Adjust audio to tempo changes", 4)
                        end
                        if userAnswer == YES then
                            _, _, bpmLeft  = reaper.TimeMap_GetTimeSigAtTime(0, t[s].time)
                            _, _, bpmRight = reaper.TimeMap_GetTimeSigAtTime(0, t[s+1].time-0.00000001)
                            local r = bpmRight / bpmLeft -- API function uses different value for slope than in arrange view UI.  Formula seems to be: (1+slope)/(1-slope) = bpmRight/bpmLeft
                            t[s].slope = (r-1)/(r+1)
                            reaper.SetTakeStretchMarkerSlope(take, s, t[s].slope)
                        end
                    end
                end
            end
        
        -- No stretch markers? Insert stretch markers below each tempo change.
        else
        
            -- How to get source position at end of item?  
            -- Only way that I know, is to add a stretch marker at time and then read its source position.
            reaper.SetTakeStretchMarker(take, -1, 0)
            _, _, srcposStart = reaper.GetTakeStretchMarker(take, -1, 0)
            reaper.SetTakeStretchMarker(take, -1, itemStretchedLength)
            _, _, srcposEnd = reaper.GetTakeStretchMarker(take, -1, itemStretchedLength)
            sourceVisLength = srcposEnd-srcposStart
            
            -- Prepare take for new stretch markers
            reaper.DeleteTakeStretchMarkers(take, 0, reaper.GetTakeNumStretchMarkers(take))
            setOK = reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", 1)
            
            -- Info of tempo markers and stretch markers will be stored in the same table, since they will be inserted on same time positions.
            t = {}
            -- If no tempo marker at item start, interpolate
            indexStart = reaper.FindTempoTimeSigMarker(0, itemStart+0.00000001)
            _, timepos, _, beatpos, bpm, _, _, linear = reaper.GetTempoTimeSigMarker(0, indexStart)
            if timepos >= itemStart then
                t[0] = {bpm = bpm, linear = linear, time = itemStart, beats = beatsStart}
            else
                _, _, bpm = reaper.TimeMap_GetTimeSigAtTime(0, itemStart)
                t[0] = {bpm = bpm, linear = linear, time = itemStart, beats = beatsStart}
            end
            indexEnd   = reaper.FindTempoTimeSigMarker(0, itemEnd)
            for s = indexStart+1, indexEnd do
                _, timepos, _, _, bpm, _, _, linear = reaper.GetTempoTimeSigMarker(0, s)
                _, _, _, beatpos = reaper.TimeMap2_timeToBeats(0, timepos)
                t[#t+1] = {time = timepos, bpm = bpm, linear = linear, beats = beatpos}
            end
            -- If no tempo marker at item END, interpolate
            if t[#t].time < itemEnd-0.00000001 then
                _, _, bpm = reaper.TimeMap_GetTimeSigAtTime(0, itemEnd)
                t[#t+1] = {bpm = bpm, time = itemEnd, beats = beatsEnd}
            end
            
            -- Insert stretch markers
            for s = 0, #t do
                t[s].index = reaper.SetTakeStretchMarker(take, -1, t[s].time-itemStart, srcposStart + sourceVisLength*(t[s].beats-beatsStart)/beatsLength)
            end
            -- Must apply slopes *after* all stretch markers have been added, since doesn't work if no later marker yet.
            for s = 0, #t-1 do 
                if t[s].linear and t[s].index > -1 then
                    if not userAnswer then
                        userAnswer = reaper.ShowMessageBox("Linear tempo changes have been detected.\n\nShould sloped stretch markers be used?\n\n(NB: downward slopes may cause pre-echo artefacts.)", "Adjust audio to tempo changes", 4)
                    end
                    if userAnswer == YES then
                        local r = t[s+1].bpm / t[s].bpm -- API function uses different value for slope than in arrange view UI.  Formula seems to be: (1+slope)/(1-slope) = bpmRight/bpmLeft
                        t[s].slope = (r-1)/(r+1)
                        reaper.SetTakeStretchMarkerSlope(take, t[s].index, t[s].slope)
                    end
                end
            end
        end
    
        reaper.UpdateItemInProject(item)
    
    end -- if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and not reaper.TakeIsMIDI(take)
    
end

reaper.Undo_OnStateChange2(0, "Adjust audio items to tempo changes")

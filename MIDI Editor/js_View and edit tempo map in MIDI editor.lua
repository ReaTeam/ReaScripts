--[[
ReaScript name: js_View and edit tempo map in MIDI editor.lua
Version: 0.90
Author: juliansader
Screenshot: http://stash.reaper.fm/30160/Script%20-%20View%20and%20edit%20tempo%20map%20in%20MIDI%20editor.gif
Website: http://forum.cockos.com/showthread.php?t=189334
REAPER: v5.32 or later
Extensions:  SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
About:
  # Description
  
  A Lua script for viewing and editing the tempo map in the MIDI editor.
  
  The tempo map is displayed in a CC lane, and any edits in the CC lane are mirrored in the tempo map.    


  # Instructions
  
  Create a track names "Tempo" and insert a single MIDI take in the track.  
    * (The take should cover the time span of the tempo map that will be viewed/edited.)
  
  Optionally, rename the CC lane to "Tempo" or any other suitable name.
    * (The actions and menu items to rename CC lanes are somewhat misleadingly named, and only refer to "Note names".
    In the MIDI editor, make the Tempo track active, then go to File -> Note names -> Load note names from file.
    The file only needs to contain a single line, such as "CC31 Tempo".)
    
  The default CC lane is the 14-bit 31/63 lane, but alternative lanes can be selected by the user in the script's user area.
  
  Run the script.  
    * (The script can be linked to a toolbar button, which will indicate the activation status of the script.)
  
  Once the script is running, if any changes are made directly to the Master track's tempo envelope, 
    (within the take's time span), the script will deactivate.  
    When the script is re-activated, the new changes can be re-copied into the Tempo track.

  Note: This script is not compatible with linear tempo changes. However, this is not a grave disadvantage, since
     * linear tempo changes are somewhat buggy in current versions of REAPER ~v5.35, and
     * SWS's tempo map actions also require square tempo changes.

  The first time that the script is stopped, REAPER will pop up a dialog box 
    asking whether to terminate or restart the script.  Select "Terminate"
    and "Remember my answer for this script".)   
]] 

--[[
  Changelog:
  * v0.90 (2017-03-13)
    + Initial beta release
]]


-- USER AREA
-- Settings that the user can customize

    -- The script will use the 14-bit CC lane that corresponds to the following MSB lane.
    -- This number should be between 0 and 31, inclusive.
    -- Default is 31 (which corresponds to the 31/63 14-bit CC lane.)
    ccLaneToUse = 31
    
-- End of USER AREA





-- ################################################################################################
---------------------------------------------------------------------------------------------------





local itemTimeStart, itemTimeLength, itemTimeEnd, itemTimeLengthTruncated
local countMustQuitCycles = 0
local MSBlane = ccLaneToUse
local LSBlane = ccLaneToUse + 32
local track, item, take, hash, prevHash, gotHashOK


-----------------
function onexit()
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
end


--------------------
function deferLoop()
    
    -- Don't update tempo map while scripts such as "js_Draw linear or curved ramps in real time" are running.
    --    Only update when they are completed.
    -- (Otherwise, it would slow these scripts down a lot.)
    -- When the scripts are telling each other to quit, give them a few cycles to complete their onexit functions.
    local jsExtState = reaper.GetExtState("js_Mouse actions", "Status") 
    if jsExtState == "Must quit" then 
        if countMustQuitCycles < 3 then 
            countMustQuitCycles = countMustQuitCycles + 1
            goto skipLoop
        end
    else
        countMustQuitCycles = 0
        if jsExtState ~= "" then goto skipLoop end
    end
    
    -- Check whether any changes have been made directly to arrange view's tempo map, NOT via MIDI Tempo track.
    -- Any changes that affect the tempo within the timespan of the MIDI item, should change the item's length,
    --    as measured in seconds.
    -- Sometimes, when tempo mape changes are made *outside* the item, REAPER's calculation of the item length 
    --    may still vary by a minute fraction of a second.  The script therefore uses a truncated value.
    --    
    if itemTimeLengthTruncated ~= math.floor(reaper.GetMediaItemInfo_Value(item, "D_LENGTH")*2048) then return end
    
    -- Only need to update tempo map if changes were made to the MIDI Tempo track, so check hash for changes.
    gotHashOK, hash = reaper.MIDI_GetHash(take, false, "")
    if hash ~= prevHash then
      
        prevHash = hash
    
        -- Should any undo block be started here?  No, since the CC drawing actions will create their own undo points.
        
        
        -- The simplest method to copy CC changes in the tempo map, may be to delete all existing tempo changes
        --    (within the time span if the MIDI Tempo track's take), and then insert everything again.  
        -- This will be rather slow, unfortunately.
        -- Instead, this script will step through all existing tempo changes (within the time span) and
        -- only change or delete those tempos that have been edited in the Tempo track's CCs.
        
        reaper.MIDI_Sort(take)
        
        -- Get all the CCs in the target lane, and combine MSB and LSB values.
        local _, _, numCCs, _ = reaper.MIDI_CountEvts(take)
        local tablePPQ = {} -- PPQ positions of each 14-bit CC
        local tableMSB = {}
        local tableLSB = {}
        local tableBPM = {} -- BPM for each CC.
        local t = 0 -- index in tables. myTable[t] = X is much faster than table.insert(myTable, X).

        for c = 0, numCCs-1 do
            local gotCCOK, _, _, ppqpos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, c)
            if gotCCOK then
                -- Be careful to avoid MSB CCs that do not have corrsponding LSB partners, and vice versa.
                if ppqpos ~= tablePPQ[t] then
                    if (tableMSB[t] and tableLSB[t]) or t == 0 then
                        t = t + 1
                    else
                        tableMSB[t] = nil
                        tableLSB[t] = nil
                    end
                    tablePPQ[t] = ppqpos
                end
                if msg2 == MSBlane then
                    tableMSB[t] = msg3
                elseif msg2 == LSBlane then
                    tableLSB[t] = msg3
                end
            end                
        end
        -- Make sure the last CCs have partners.
        if not (tableMSB[#tablePPQ] and tableLSB[#tablePPQ]) then
            tableMSB[#tablePPQ] = nil
            tableLSB[#tablePPQ] = nil
            tablePPQ[#tablePPQ] = nil
        end
      
        -- Calculate BPM for each CC.
        for i = 1, #tablePPQ do
            -- REAPER rounds the BPM to nearest 1/1000
            tableBPM[i] = (math.floor(0.5 + 1000 * (40 + ((tableLSB[i] + (tableMSB[i]<<7)) / 16383.0) * 240)))/1000
        end

      
        -- Find the tempo change close to start of item.
        -- REAPER *usually* uses a default BPM of 120 if no tempo map has been specified yet.
        -- NOTE: I do not know how to get the Project BPM (in Project settings) via script.
        local tempoIndexBeforeItem = reaper.FindTempoTimeSigMarker(0, itemTimeStart-0.001)
        if tempoIndexBeforeItem == -1 then -- No tempo change before start of item.
            tableBPM[0] = 120
        else
            gotTempoOK, _, _, _, tableBPM[0], _, _, _ = reaper.GetTempoTimeSigMarker(0, tempoIndexBeforeItem)
            if not gotTempoOK then tableBPM[0] = 120 end
        end
        
        local tempoIndex = tempoIndexBeforeItem + 1 -- First tempo change inside (or beyond) item.
        
        -- The loop below will step through each tempo change, until it reaches numTempos.
        -- If any new tempo changes are inserted, numTempo will be incremented.  Similarly for deleted tempo changes.
        local numTempos = reaper.CountTempoTimeSigMarkers(0) 
        
        -- Artificial starting values that fall before item start. 
        tablePPQ[0] = -1 
        local ccTimePos = itemTimeStart - 0.001
        local prevTime

        for cc = 1, #tableMSB do
            
            prevTime = ccTimePos            
            
            local hasInsertedTempoMarker = false
            local count = 0 -- Emergency check to ensure that bugs do not cause loop to loop forever.
            repeat
                count = count + 1
                if tempoIndex >= numTempos then
                    ccTimePos = reaper.MIDI_GetProjTimeFromPPQPos(take, tablePPQ[cc])
                    reaper.SetTempoTimeSigMarker(0, -1, ccTimePos, -1, -1, tableBPM[cc], 0, 0, false)
                    numTempos = numTempos + 1
                    tempoIndex = tempoIndex + 1
                    hasInsertedTempoMarker = true
                else                        
                    local gotTempoOK, tempoTimePos, _, _, tempoBPM, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, tempoIndex)
                    if not gotTempoOK then
                        tempoIndex = tempoIndex + 1
                    else
                        tempoPPQpos = math.floor(0.5 + reaper.MIDI_GetPPQPosFromProjTime(take, tempoTimePos))
                        if tempoPPQpos <= tablePPQ[cc-1] then
                            tempoIndex = tempoIndex + 1
                        elseif tempoPPQpos > tablePPQ[cc-1] and tempoPPQpos < tablePPQ[cc] then
                            if timesig_num == 0 then
                                reaper.DeleteTempoTimeSigMarker(0, tempoIndex)
                                numTempos = numTempos - 1
                            else -- tempo marker is also time signature change
                                if tempoBPM ~= tableBPM[cc-1] then -- must BPM change?  If yes, update.
                                    reaper.SetTempoTimeSigMarker(0, tempoIndex, tempoTimePos, -1, -1, tableBPM[cc-1], timesig_num, timesig_denom, false)
                                --else
                                --   same BPM, so don't need to update
                                end
                                tempoIndex = tempoIndex + 1
                            end
                        elseif tempoPPQpos == tablePPQ[cc] then
                            if tempoBPM ~= tableBPM[cc] then
                                reaper.SetTempoTimeSigMarker(0, tempoIndex, tempoTimePos, -1, -1, tableBPM[cc], timesig_num, timesig_denom, false)
                            -- else
                            --    same BPM, so don't need to update.
                            end
                            ccTimePos = tempoTimePos -- not entirely accurate, but good enough for tick resolution
                            tempoIndex = tempoIndex + 1
                            hasInsertedTempoMarker = true
                        elseif tempoPPQpos > tablePPQ[cc] then
                            ccTimePos = reaper.MIDI_GetProjTimeFromPPQPos(take, tablePPQ[cc])
                            reaper.SetTempoTimeSigMarker(0, -1, ccTimePos, -1, -1, tableBPM[cc], 0, 0, false)
                            numTempos = numTempos + 1
                            tempoIndex = tempoIndex + 1
                            hasInsertedTempoMarker = true
                        end
                    end
                end                        
            until hasInsertedTempoMarker == true or count == 50
          
        end -- for c = 0, 0 do --numCCs-1 do
        
        
        -- Clean up to right of CCs.
        -- ccTimePos still contain the values of the last CC in the take.
        local lastTempoIndex = reaper.FindTempoTimeSigMarker(0, reaper.MIDI_GetProjTimeFromPPQPos(take, sourceLengthTicks))
        for j = lastTempoIndex, 0, -1 do
            local gotTempoOK, tempoTimePos, _, _, tempoBPM, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, j)
            if gotTempoOK then
                if tempoTimePos <= ccTimePos then
                    break
                elseif timesig_num ~= 0 then
                    if tableBPM[#tableBPM] ~= tempoBPM then
                        reaper.SetTempoTimeSigMarker(0, j, tempoTimePos, -1, -1, tableBPM[#tableBPM], timesig_num, timesig_denom, false)
                    end
                else
                    reaper.DeleteTempoTimeSigMarker(0, j)     
                end
            end
        end
        
        -- reaper.UpdateArrange() does not update the ruler/timeline
        reaper.UpdateTimeline()
        
        -- Get new irem length
        --itemTimeStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        itemTimeLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        itemTimeLengthTruncated = math.floor(itemTimeLength*2048)
        
    end    
    
    ::skipLoop::
    reaper.defer(deferLoop)
end




--#################################################################
-------------------------------------------------------------------
-- function main()
-- Here execution starts


-----------------------------------------------------
-- Check that required version of REAPER is available
version = tonumber(reaper.GetAppVersion():match("(%d+%.%d+)"))
if version == nil or version < 5.32 then
    reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                          .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                          , "ERROR", 0)
    return(false) 
end   

--------------------------------
-- Check that CC lane is useable
if math.floor(ccLaneToUse) ~= ccLaneToUse or ccLaneToUse < 0 or ccLaneToUse > 31 then
    reaper.ShowMessageBox("The 'ccLaneToUse' parameter should be an integer between 0 and 31, inclusive.", "ERROR", 0)
    return(false)
end

----------------------------
-- Find suitable Tempo track
for trackIndex = 0, reaper.CountTracks(0)-1 do
    track = reaper.GetTrack(0, trackIndex)
    retval, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
    if retval and trackName == "Tempo" then
        item = reaper.GetTrackMediaItem(track, 0)
        if reaper.ValidatePtr2(0, item, "MediaItem*") then
            take = reaper.GetTake(item, 0)
            if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) then 
                gotTempoTrack = true
                break
            end
        end
    end
end

if not gotTempoTrack then 
    reaper.ShowMessageBox("Could not find a suitable Tempo track."
                          .. "\n\nThe tempo track should be named 'Tempo', and should only contain a single MIDI take."
                          , "ERROR", 0)
    return(false)
end


------------------------------------------------------------------
-- Get item length etc, which will later be used to detect changes
--    in the tempo map
-- Sometimes, when tempo mape changes are made *outside* the item, 
--    REAPER's calculation of the item length may still vary by a 
--    trillionth of a second.  The script therefore uses a truncated value.
itemTimeStart  = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
itemTimeLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
itemTimeLengthTruncated = math.floor(itemTimeLength * 2048)
itemTimeEnd   = itemTimeStart + itemTimeLength
sourceLengthTicks = reaper.BR_GetMidiSourceLenPPQ(take)


------------------------------------------------------------
-- Must existing tempo changes be copied to the Tempo track?
local userChoice = reaper.ShowMessageBox("Should existing tempo changes (in the Master track's tempo map) be copied to the MIDI Tempo track?"
                                          .. "\n\nNotes for new users:"
                                          .. "\n\n * Copying the existing tempo changes will replace all CCs in the MIDI Tempo track."
                                          .. "\n\n * The tempo changes will be copied into 14-bit CC lane " .. MSBlane .. "/" .. LSBlane .. ".  "
                                          .. "The user can customize the lane number in the script's user area, near the beginning of the script."
                                          .. "\n\n * Once the script is running, if any changes are made directly to the Master track's tempo envelope "
                                          .. "(within the take's time span), the script will deactivate.  When the script is re-activated, the new changes can be copied into the Tempo track."
                                          , "", 4)

if userChoice == 6 then -- Not "No", i.e. "Yes" or Esc.

    reaper.Undo_BeginBlock2(0)    
    
    -- Before making any changes to the Tenmpo track, get all tempo changes and check that all are square.
    local tableExistingTempos = {}
    for t = 0, reaper.CountTempoTimeSigMarkers(0)-1 do
        local retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, t)
        if timepos >= itemTimeStart and timepos < itemTimeEnd then
            if lineartempo then
                reaper.ShowMessageBox("This script is not compatible with linear tempo changes."
                                      .. "\n\nThis is not a big disadvantage, since:"
                                      .. "\n\n * linear tempo changes are somewhat buggy, and "
                                      .. "\n\n * SWS's tempo map actions also prefer square tempo changes.", "ERROR", 0)
                return
            else
                table.insert(tableExistingTempos, {bpm = bpm, timepos = timepos})
            end
        end
    end
    
    -- Write tempo changes into Tempo track take.
    local tableRawMIDI = {}
    local runningPPQpos, prevPPQpos = 0, 0
    for t = 1, #tableExistingTempos do
        runningPPQpos  = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, tableExistingTempos[t].timepos) + 0.5)
        local CCvalue = math.floor((16383.0 * (tableExistingTempos[t].bpm - 40) / 240) + 0.5)
        tableRawMIDI[(t<<1)-1]   = string.pack("i4Bi4BBB", runningPPQpos - prevPPQpos, 1, 3, 0xB0, MSBlane, CCvalue>>7)
        tableRawMIDI[t<<1] = string.pack("i4Bi4BBB", 0, 1, 3, 0xB0, LSBlane, CCvalue&127)
        prevPPQpos = runningPPQpos
    end
    
    tableRawMIDI[#tableRawMIDI+1] = string.pack("i4Bi4BBB", sourceLengthTicks-runningPPQpos, 0, 3, 0xB0, 0x7B, 0x00)
    reaper.MIDI_SetAllEvts(take, table.concat(tableRawMIDI))
    
    -- The take's MIDI hash will be checked during each loop cycle, to check whether the user made any edits to the Tempo track.
    gotHashOK, prevHash = reaper.MIDI_GetHash(take, false, "")
    
    reaper.Undo_EndBlock2(0, "Copy existing tempo changes to tempo MIDI track", -1)
    
end


------------------------------------------------------------------------
-- All tests completed, scripts may continue, so activate toolbar button
--    and define atexit function.
_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end  

reaper.atexit(onexit)


------------------
-- Start the loop!
reaper.defer(deferLoop)



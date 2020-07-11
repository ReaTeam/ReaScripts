--[[
ReaScript name: js_Track FX grouping.lua
Version: 0.90
Author: juliansader
Donation: https://www.paypal.me/juliansader
Provides: [main=main] .
About:
  # DESCRIPTION
  
  Provides grouping of Track FX.
  
  When the script starts, it will detect tracks that are grouped by VCA.  It will then continue running in the background, 
      and any changes to the Track FX of grouped tracks will be propagated to similarly named FX in other tracks in the same VCA group.
      
  The script can detect (and propagate) changes that are made directly in the FX GUI, and also values that are being recorded to track envelopes of FX parameters.
  
  If the envelope of a Track FX parameter is in Read mode, it will override ReaScript-provided values, so changes cannot be propagated to such parameters.
  
  Propagated values are relative to the original values of each FX.  
      For example, if a parameter in an FX in track 1 has an original value of 10 when the script starts, 
      and the same parameter in an FX in track 2 has an original value of 5, 
      the script will move the track 2 FX to 2.5 when the users moves the track 1 FX to 5.
      
  The script is only active while REAPER's own Track Grouping is enabled.  
      If Track Grouping is disabled and re-enabled, the script will re-load all FX parameters values.
  
  While the script is running, it will try to detect any changes to track grouping and to FX chains, such as adding FX or copying FX chains.
  Unfortunately, this is not always reliable.  For example, if a track is removed from a group and then added back immediately, 
      the script will not realize that the track has been added back again.
      When the script does detect changes, it will pop up a tooltip next to the mouse, stating that Track FX grouping has been updated.
      If no tooltip pops up, the user should restart the script or disable/re-enable Track Grouping.
  
  Some changes to FX parameters cannot (yet) be detected, for example removal of ReaEQ bands.
]] 

--[[
  Changelog:
  * v0.90 (2020-07-10)
    + Initial BETA release.
]]


local INF = math.huge
local ONLY_NEW = true
local OVERRIDE_OLD = false 

local tGroups = {} -- Group# => {tracks}
local tParamVals = {} -- GUID => {param} => values -- Original param values, so that relative movement can be calculated from original ratios.
local tTrackFX = {} -- track => {FX GUIDs} -- Each track is mapped to GUIDs of all its Track FX


local tooltipTime = 0
local tooltipText = ""
----------------------
function Tooltip(text)
    if text then -- New tooltip text
        tooltipTime = reaper.time_precise()
        tooltipText = text
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(tooltipText, x+10, y+10, true)
        reaper.defer(Tooltip)
    elseif reaper.time_precise() < tooltipTime+1 then
        local x, y = reaper.GetMousePosition()
        reaper.TrackCtl_SetToolTip(tooltipText, x+10, y+10, true)
        reaper.defer(Tooltip)
    else
        reaper.TrackCtl_SetToolTip("", 0, 0, false)
        return
    end
end


---------------------------------------------------
function GetFXParamValues(track, fx, guid, onlyNew)
    if not tTrackFX[track] then tTrackFX[track] = {numFX = reaper.TrackFX_GetCount(track)} end
    tTrackFX[track][guid] = true
    
    if not (onlyNew and tParamVals[guid]) then
        tParamVals[guid] = {}
        for param = 0, reaper.TrackFX_GetNumParams(track, fx)-1 do
            local val = reaper.TrackFX_GetParamNormalized(track, fx, param)
            --if val < 0.0000001 then val = 0 end
            tParamVals[guid][param] = val
        end
    end
end


--------------------------------------------
function GetAllTrackFXParams(track, onlyNew)
    
    --[[ First, remove all old FX data
    if tTrackFX[track] then
        for guid in pairs(tTrackFX[track]) do
            tParamVals[guid] = nil
        end
    end]]
    -- Add all current FX
    tTrackFX[track] = {numFX = reaper.TrackFX_GetCount(track)}
    for fx = 0, tTrackFX[track].numFX-1 do
        local guid = reaper.TrackFX_GetFXGUID(track, fx)
        GetFXParamValues(track, fx, guid, onlyNew)
    end
end


local tFuncs = {reaper.GetSetTrackGroupMembership, reaper.GetSetTrackGroupMembershipHigh}
local tFlags = {"VOLUME_VCA_FOLLOW", "VOLUME_VCA_LEAD"} -- This script does not distinguish between lead and follower -- all are grouped together
-----------------------------------
function LoadGroupedTracks(onlyNew)
    tGroups = {} 
    tTrackFX = {} -- track => FX GUIDs
    if not onlyNew then tParamVals = {} end -- Clear all previous values
    for t = -1, reaper.CountTracks(0)-1 do
        local track = reaper.GetTrack(0, t)
        if track and reaper.ValidatePtr2(0, track, "MediaTrack*") then
            for _, flag in ipairs(tFlags) do
                local bitmapLow = reaper.GetSetTrackGroupMembership(track, flag, 0, 0)
                if bitmapLow ~= 0 then
                    for group = 1, 32 do
                        if bitmapLow&1 == 1 then
                            if not tGroups[group] then tGroups[group] = {} end
                            tGroups[group][track] = true
                            if not tTrackFX[track] then GetAllTrackFXParams(track, onlyNew) end
                        end
                        bitmapLow = bitmapLow>>1
                    end
                end
                local bitmapHigh = reaper.GetSetTrackGroupMembershipHigh(track, flag, 0, 0)
                if bitmapHigh ~= 0 then
                    for group = 33, 64 do
                        if bitmapHigh&1 == 1 then
                            if not tGroups[group] then tGroups[group] = {} end
                            tGroups[group][track] = true
                            if not tTrackFX[track] then GetAllTrackFXParams(track, onlyNew) end
                        end
                        bitmapHigh = bitmapHigh>>1
                    end
                end
            end
        end
    end
end


local prevUndo = nil -- to check if undo text has changed
local groupingActive = false -- to check if Track grouping state has changed
-- REAPER (sometimes) records params that were set via API as LastTouched, which the script will then recognize as different from prevVal/prevFX, 
--    and try to re-propagate (to originally touched FX, too).  So, to avoid ad infinitum re-propagation, store previous cycle's values here, to check for *real* changes.
local tDoneVals = {} -- FX GUIDs and params that were changed in last (active) cycle.
----------------------------
function loop()
    local gotError = false
    
    -- Don't do anything while REAPER's Track Grouping is disabled
    local prevGroupingActive = groupingActive
    groupingActive = (reaper.GetToggleCommandState(40771) == 1)
    if groupingActive then
    
        -- When re-enabling Track Grouping (or when script starts up), load all FX and param relative values
        if not prevGroupingActive then
            LoadGroupedTracks(OVERRIDE_OLD)
        end
        
        -- Have FX chains been changed?
        local undo = reaper.Undo_CanUndo2(0)
        if undo ~= prevUndo then
            prevUndo = undo
            local tr = undo:match("FX: Track (%d+)") -- Reaplce FX, Add FX, etc
            if tr then 
                track = reaper.GetTrack(0, tonumber(tr-1))
                if tTrackFX[track] then
                    GetAllTrackFXParams(track, ONLY_NEW)
                    Tooltip("Track FX grouping: UPDATED")
                end
            elseif undo == "Move FX" or undo == "Copy FX" or undo:match("Close FX chain") then -- Does not provide track number, unfortunately
                for track, tbl in pairs(tTrackFX) do
                    if tbl.numFX ~= reaper.TrackFX_GetCount(track) then
                        GetAllTrackFXParams(track, ONLY_NEW)
                        Tooltip("Track FX grouping: UPDATED")
                    end
                end
            elseif undo:match("Change track group membership") then
                Tooltip("Track FX grouping: UPDATED")
                LoadGroupedTracks(ONLY_NEW) -- Get new groups, but keep original param ratios
            end
            
        -- Check if FX param has been changed
        else
            local gotOK, tr, fx, param = reaper.GetLastTouchedFX() -- WARNING! TRACK NUMBER RETURNED BY THIS FUNCTION IS NOT 0-BASED !!!!!!
            if gotOK and tr&0x110000 == 0 and fx&0x11000000 == 0 then -- Skip Item FX and Track Record FX
                local track = reaper.GetTrack(0, tr-1)
                if tTrackFX[track] then
                    local val = reaper.TrackFX_GetParamNormalized(track, fx, param)
                    if val == val then -- Avoid undefined val
                        if val ~= prevVal or param ~= prevParam or fx ~= prevFx or track ~= prevTrack then
                            prevTrack, prevFx, prevParam, prevVal = track, fx, param, val
                            local guid = reaper.TrackFX_GetFXGUID(track, fx)
                            -- Double check that 
                            if not (tDoneVals and tDoneVals[guid] and tDoneVals[guid][param] == val) then
                                tDoneVals = {[guid] = {[param] = val}}
                                if not tParamVals[guid] then
                                    GetFXParamValues(track, fx, guid, OVERRIDE_OLD)
                                end
                                -- if original value, reset other FX too (this test also solves 0/0 indefinite ratios, if original value = 0)
                                local rel = (val == tParamVals[guid][param]) and 1 or val/tParamVals[guid][param] 
                                local nameOK, name = reaper.TrackFX_GetFXName(track, fx, "")
                                if not nameOK then
                                    reaper.MB("Could not determine the name of the FX that is being edited.\n\nThe Track FX grouping script will now terminate.", "ERROR", 0)
                                    gotError = true
                                else
                                    local tDoneTracks = {} -- If a track is a member of multiple groups, don't do twice, so store completed tracks here.
                                    for g, tTracks in pairs(tGroups) do
                                        if tTracks[track] then
                                            for track2 in pairs(tTracks) do
                                                if not tDoneTracks[track2] then
                                                    tDoneTracks[track2] = true
                                                    for fx2 = 0, reaper.TrackFX_GetCount(track2)-1 do
                                                        local name2OK, name2 = reaper.TrackFX_GetFXName(track2, fx2, "")
                                                        if name2OK and name == name2 then
                                                            local guid2 = reaper.TrackFX_GetFXGUID(track2, fx2)
                                                            if guid2 and guid2 ~= guid then
                                                                if not tParamVals[guid2] then
                                                                    GetFXParamValues(track2, fx2, guid2, OVERRIDE_OLD)
                                                                end
                                                                local val2
                                                                -- Params that started out the same should remain the same. Particularly if both were 0, and 0/1 toggle params
                                                                if tParamVals[guid2][param] == tParamVals[guid][param] then
                                                                    val2 = val
                                                                -- If val was originally 0, rel == INF.  Also works on toggle params
                                                                elseif rel == INF then 
                                                                    val2 = 1
                                                                -- Get new param value, keeping *original* ratio
                                                                else 
                                                                    val2 = tParamVals[guid2][param]*rel
                                                                    if val2 > 1 then val2 = 1 elseif val2 < 0 then val2 = 0 end
                                                              
                                                                end
                                                                reaper.TrackFX_SetParamNormalized(track2, fx2, param, val2)
                                                                tDoneVals[guid2] = {[param] = val2}
    end end end end end end end end end end end end end end end 

    if not gotError then reaper.defer(loop) end
end


-----------------
function AtExit()
    if sectionID and cmdID then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    reaper.TrackCtl_SetToolTip("", 0, 0, false)
end


---------------
function Main()
    reaper.atexit(AtExit)
    
    -- Don't need to load grouped tracks now -- the Loop function will do it
    
    -- Activate toolbar button, if any
    _,_, sectionID, cmdID = reaper.get_action_context()
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
    
    reaper.defer(loop)
end

Main()

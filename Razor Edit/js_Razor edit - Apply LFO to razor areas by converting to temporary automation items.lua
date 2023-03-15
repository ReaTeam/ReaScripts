--[[
ReaScript name: js_Razor edit - Apply LFO to razor areas by converting to temporary automation items.lua
Version: 1.00
Changelog:
  + Initial release.
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=241604
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION

  This script enables application of REAPER's native LFO Tool to razor areas.
  
  The script converts the razor areas to AIs, opens the LFO window, and then converts the AIs back to plain automation as soon as the LFO window is closed.
  
  NOTE: The script does not currently work on razor areas that are created within existing AIs.
]]

reaper.Undo_BeginBlock2(0)

tAIs = {}
pool = nil
tRazors = {}
tEnvBypass = {}
title = reaper.LocalizeString("Automation Item Properties", "common", 0)
bypassAll = (reaper.GetToggleCommandState(42213) == 1)

function ConvertRazorsToAIs()
    for t = 0, reaper.CountTracks(0)-1 do
        local track = reaper.GetTrack(0, t)
        local tGuidEnv = {} 
        for e = 0, reaper.CountTrackEnvelopes(track)-1 do
            local env = reaper.GetTrackEnvelope(track, e)
            local chunkOK, chunk = reaper.GetEnvelopeStateChunk(env, "", false)
            local guid = chunk:match("\nEGUID ({.-})")
            if guid then 
                tGuidEnv[guid] = env
                local envOptions = tonumber(chunk:match("\nACT %S+ (%S+)") or "0") or 0
                if envOptions ~= -1 and envOptions&4 == 4 then
                    tEnvBypass[env] = true
                end
                --[[local guidOK, guid = reaper.GetSetEnvelopeInfo_String(env, "GUID", "", false)
                if guidOK and guid then
                    tGuidEnv[guid] = env
                end]]
                for ai = 0, reaper.CountAutomationItems(env)-1 do
                    reaper.GetSetAutomationItemInfo(env, ai, "D_UISEL", 0, true) -- Deselect all existing AIs
                end
            end
        end
        
        razorOK, razorStr = reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", false)
        if razorOK and #razorStr ~= 0 then
            tRazors[track] = razorStr
            reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", "", true)
            for left, right, guid in razorStr:gmatch([[([%d%.]+) ([%d%.]+) "([^"]+)"]]) do
                if guid and tGuidEnv[guid] then
                    local left, right = tonumber(left), tonumber(right)
                    local length = right-left
                    origLen = origLen or length -- Will only be calculated for first razor selection found
                    local playrate = origLen/length 
                    local env = tGuidEnv[guid]
                    local ai = reaper.InsertAutomationItem(env, pool or -1, left, length)
                    -- WARNING! InsertAutomationItem may return false index, so must search manually. Assume that only new AI will be selected.
                    for ai = 0, reaper.CountAutomationItems(env)-1 do
                        if reaper.GetSetAutomationItemInfo(env, ai, "D_UISEL", 0, false) ~= 0 then
                            tAIs[#tAIs+1] = {env = env, ai = ai} -- for setting selected later
                            reaper.GetSetAutomationItemInfo(env, ai, "D_PLAYRATE", playrate, true)
                            if not pool then pool = reaper.GetSetAutomationItemInfo(env, ai, "D_POOL_ID", 0, false) end
                            reaper.Main_OnCommand(42221, 0) -- Do not connect to underlying envelope
                            break
                        end
                    end
                    
                end
            end
        end
    end
end


function atexit()
    -- AIs in envelopes that bypass the underlying envelope will not be deleted.
    -- Otherwise, select them and delete, preserving points.
    for _, t in ipairs(tAIs) do
        if bypassAll or tEnvBypass[t.env] then -- Bypass this envelope?
            reaper.GetSetAutomationItemInfo(t.env, t.ai, "D_UISEL", 0, true)
        else
            reaper.GetSetAutomationItemInfo(t.env, t.ai, "D_UISEL", 1, true)
        end
    end
    reaper.Main_OnCommand(42088, 0) -- Delete AIs, preserve points
    -- Re-select all remaining new AIs
    for _, t in ipairs(tAIs) do
        if bypassAll or tEnvBypass[t.env] then -- Bypass this envelope?
            reaper.GetSetAutomationItemInfo(t.env, t.ai, "D_UISEL", 1, true)
        end
    end
    -- Restore razor selections
    for track, razorStr in pairs(tRazors) do
        reaper.GetSetMediaTrackInfo_String(track, "P_RAZOREDITS", razorStr, true)
    end
end


function defer()
    -- Wait for Properties window to close before exiting script
    if not AIPropertiesWindow then
        AIPropertiesWindow = reaper.JS_Window_FindTop(title, true)
        reaper.defer(defer)
    elseif reaper.JS_Window_FindTop(title, true) then
        reaper.defer(defer)
    else
        return
    end
end

reaper.atexit(atexit)

ConvertRazorsToAIs()
if next(tRazors) then 
    reaper.Main_OnCommand(42090, 0) -- Envelope: Automation item properties...
    defer() -- Wait for Properties window to close before exiting script
end

reaper.UpdateArrange()
reaper.Undo_EndBlock2(0, "Apply LFO to razor areas", 0)


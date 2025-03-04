-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

-- Thanks @amagalma for this implementation !
-- https://forum.cockos.com/showthread.php?p=2274097
local function GetMIDIEditorHBounds(me)
    if not me then return end

    local midiview  = reaper.JS_Window_FindChildByID( me, 0x3E9 )
    local _, width  = reaper.JS_Window_GetClientSize( midiview )
    local take      = reaper.MIDIEditor_GetTake( me )
    local guid      = reaper.BR_GetMediaItemTakeGUID( take )
    local item      = reaper.GetMediaItemTake_Item( take )
    local _, chunk  = reaper.GetItemStateChunk( item, "", false )

    local guidfound, editviewfound = false, false
    local leftmost_tick, hzoom, timebase

    -- Look for the good GUID (an item may have multiple takes, we need to find the right one)
    for line in chunk:gmatch("[^\n]+") do

        -- Detect good GUID
        if line == "GUID " .. guid then
            guidfound = true
        end

        if (not editviewfound) and guidfound then
            -- Get horizontal zoom factor (parameter 2)
            if line:find("CFGEDITVIEW ") then
                local i = 0
                for w in line:gmatch("%S+") do
                    if i == 1 then leftmost_tick    = tonumber(w) end
                    if i == 2 then hzoom            = tonumber(w); break; end
                    i = i + 1
                end
                editviewfound = true
            end
        end
        if editviewfound then
            -- Get timebase (parameter 19)
            if line:find("CFGEDIT ") then
                local i = 0
                for w in line:gmatch("%S+") do
                    if i == 19 then timebase = tonumber(w); break; end
                    i = i + 1
                end
                break
            end
        end
    end

    -- width = width - 1

    -- Width should be corrected for more accuracy
    local start_time = reaper.MIDI_GetProjTimeFromPPQPos(take, math.floor(0.5 + (leftmost_tick or 0)))
    local end_time   = nil

    if timebase == 0 or timebase == 4 then
        end_time = reaper.MIDI_GetProjTimeFromPPQPos( take, leftmost_tick + width * 1.0/hzoom)
    else
        end_time = start_time + width * 1.0/hzoom
    end

    local ret_zoom = width/(end_time - start_time)
    return start_time, end_time, ret_zoom
end

local function SetMIDIEditorBounds(me, start_time, end_time)
    -- Save current time selection
    local cts, cte = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

    reaper.MIDIEditor_OnCommand(me, 40726)

    local diff = end_time - start_time

    -- we need to reduce the range, so that margins added by REAPER for the "zoom on loop" action will be compensated
    -- This heuristic is a bit sloppy but impossible to do the very exact thing
    local lpos = start_time + (diff / 34.34)
    local rpos = end_time   - (diff / 36.4)

    -- Set temp time sel
    reaper.GetSet_LoopTimeRange(true, false, lpos, rpos, false)

    -- Zoom on temp time sel
    reaper.MIDIEditor_OnCommand(me, 40726)

    -- Restore current time selection
    reaper.GetSet_LoopTimeRange(true, false, cts, cte, false)
end

return {
    GetBounds = GetMIDIEditorHBounds,
    SetBounds = SetMIDIEditorBounds
}

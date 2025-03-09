-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local D     = require "modules/defines"
local CHUNK = require "modules/chunk"

local function ToFrac(num)
    local W = math.floor(num)
    local F = num - W
    local pn, n, N = 0, 1, 0
    local pd, d, D = 1, 0, 0
    local x, err, q, Q
    repeat
        x = x and 1 / (x - q) or F
        q, Q = math.floor(x), math.floor(x + 0.5)
        pn, n, N = n, q*n + pn, Q*n + pn
        pd, d, D = d, q*d + pd, Q*d + pd
        err = F - N/D
    until math.abs(err) < 1e-15
    return N + D*W, D, err
end

local function FromString(str)
    local p, q = str:match("(.+)/(.+)")
    local res = 1
    if p then
        p = tonumber(p)
        q = tonumber(q)
        res = p*1.0/q
    else
        res = tonumber(str) or 1
    end    -- body
    return res
end

local function ToString(val)
    local p, q, err = ToFrac(val)
    local str = "" .. p .. "/" .. q
    if q == 1 then str = "" .. p end
    return str
end

-- The default MIDI_GetGrid function does not give the state of the swing / grid type
-- Implement our own one, this is a nightmare
local function GetMIDIEditorGrid(mec)
    local take = mec.take
    local item = mec.item

    if not take then return  0.25,  'straight', 0 end

    local grid_type = 'straight'

    if      (reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, D.ACTION_ME_SET_GRID_TYPE_TO_TRIPLET) == 1)  then grid_type = 'triplet'
    elseif  (reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, D.ACTION_ME_SET_GRID_TYPE_TO_DOTTED) == 1)   then grid_type = 'dotted'
    elseif  (reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, D.ACTION_ME_SET_GRID_SIZE_TO_SWING) == 1)    then grid_type = 'swing'
    end

    -- Get the swing from the track chunk
    local chunk = CHUNK.getItemChunk(item) or ''
    local swing_val = 0.0
    for line in chunk:gmatch("[^\n]+") do
        if line:find("CFGEDIT ") then
            local i = 0
            for w in line:gmatch("%S+") do
                if i == 26 then swing_val = tonumber(w) or 0; break; end
                i = i + 1
            end
            break
        end
    end

    local base_val, _, _  = reaper.MIDI_GetGrid(take)

    -- convert to wholes
    base_val = base_val * 0.25

    -- Apply back potential modifiers so they do not appear in the base value
    if grid_type == 'triplet' then base_val = base_val * 3/2 end
    if grid_type == 'dotted'  then base_val = base_val * 2/3 end

    return base_val, grid_type, swing_val
end


-- Inspired from Archie's
local function SetMIDIEditorGrid(mec, val, grid_type, swing_val)
    local me = mec.me

    -- Get me params to have fallback values
    local me_grid, me_grid_type, me_swing = GetMIDIEditorGrid(mec)

    val       = val       or me_grid
    grid_type = grid_type or me_grid_type
    swing_val = swing_val or me_swing

    reaper.PreventUIRefresh(42)

    -- Get full global grid info
    local _, g_grid, g_swing_on, g_swing  = reaper.GetSetProjectGrid(0, false)
    local is_me_copying_arrange = reaper.GetToggleCommandState(D.ACTION_MAIN_USE_SAME_GRID_IN_ME_AND_ARRANGE)

    -- Set the project swing, so that can be copied transferred to the ME
    reaper.GetSetProjectGrid(0, true, nil, 1, swing_val)
    if is_me_copying_arrange == 1 then
        -- Be sure that the params are validated
        reaper.Main_OnCommand(D.ACTION_MAIN_USE_SAME_GRID_IN_ME_AND_ARRANGE, 0) -- off
        reaper.Main_OnCommand(D.ACTION_MAIN_USE_SAME_GRID_IN_ME_AND_ARRANGE, 0) -- on : triggers copy
        reaper.GetSetProjectGrid(0, true, nil, g_swing_on, swing_val)
        reaper.Main_OnCommand(D.ACTION_MAIN_USE_SAME_GRID_IN_ME_AND_ARRANGE, 0) -- off
        reaper.Main_OnCommand(D.ACTION_MAIN_USE_SAME_GRID_IN_ME_AND_ARRANGE, 0) -- on : triggers copy
    else
        -- Trigger the copy from Grid > ME
        reaper.Main_OnCommand(D.ACTION_MAIN_USE_SAME_GRID_IN_ME_AND_ARRANGE, 0)
        -- Second call : disable copy
        reaper.Main_OnCommand(D.ACTION_MAIN_USE_SAME_GRID_IN_ME_AND_ARRANGE, 0)
        -- restore project swing
        reaper.GetSetProjectGrid(0, true, nil, g_swing_on, g_swing)
    end


    -- Apply modifiers to the base value
    if grid_type == 'dotted'  then val = val * 3/2 end
    if grid_type == 'triplet' then val = val * 2/3 end

    -- The order is important, as reaper may override the grid type in the next call (ex : 3/2 straight will be resolved as 1/1 + dotted)
    reaper.SetMIDIEditorGrid(0, val)

    -- Set the type at the end (order is important)
    if      grid_type == 'straight' then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_GRID_TYPE_TO_STRAIGHT)
    elseif  grid_type == 'triplet'  then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_GRID_TYPE_TO_TRIPLET)
    elseif  grid_type == 'dotted'   then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_GRID_TYPE_TO_DOTTED)
    elseif  grid_type == 'swing'    then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_GRID_SIZE_TO_SWING)
    end

    reaper.PreventUIRefresh(-42)
end

local function GetColoringType(mec)
    local take = mec.take
    local item = mec.item

    if not take then return 'track' end

    local coloring_mode = 'track'
    local chunk = CHUNK.getItemChunk(item) or ''
    local color_mode = 0
    for line in chunk:gmatch("[^\n]+") do
        if line:find("CFGEDIT ") then
            local i = 0
            for w in line:gmatch("%S+") do
                if i == 20 then color_mode = tonumber(w) or 0; break; end
                i = i + 1
            end
            break
        end
    end

    if color_mode == 0 then coloring_mode = 'velocity' end
    if color_mode == 1 then coloring_mode = 'channel' end
    if color_mode == 2 then coloring_mode = 'pitch' end
    if color_mode == 3 then coloring_mode = 'source' end
    if color_mode == 4 then coloring_mode = 'track' end
    if color_mode == 5 then coloring_mode = 'media_item' end
    if color_mode == 6 then coloring_mode = 'voice' end

    return coloring_mode
end

local function SetColoringType(mec, type)
    local me = mec.me
    if      type == 'velocity'  then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_COLORING_VELOCITY)
    elseif  type == 'channel'   then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_COLORING_CHANNEL)
    elseif  type == 'pitch'     then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_COLORING_PITCH)
    elseif  type == 'source'    then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_COLORING_SOURCE)
    elseif  type == 'track'     then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_COLORING_TRACK)
    elseif  type == 'media_item' then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_COLORING_MEDIA_ITEM)
    elseif  type == 'voice'     then reaper.MIDIEditor_OnCommand(me, D.ACTION_ME_SET_COLORING_VOICE)
    end
end

return {
    ToFrac                  = ToFrac,
    FromString              = FromString,
    ToString                = ToString,
    GetMIDIEditorGrid       = GetMIDIEditorGrid,
    SetMIDIEditorGrid       = SetMIDIEditorGrid,
    GetColoringType            = GetColoringType,
    SetColoringType            = SetColoringType
}

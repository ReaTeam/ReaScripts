-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

-- Vellane regex : num, height, inline_height, zoom_offset, zoom_factor
VELLANE_REGEX = "\n%s*VELLANE (-?[.0-9]+) (-?[.0-9]+) (-?[.0-9]+) (-?[.0-9]+) (-?[.0-9]+)([^\n]*)"
SRCCOLOR_REGEX = "\n%s*SRCCOLOR[^\n]*"

local function totalHeight(vellanes)
    local vh = 0
    for _, vl in ipairs(vellanes.entries) do
        vh = vh + vl.height
    end
    return vh
end

-- Retreave all vellanes and insertion point/range from chunk.
local function readVellanesFromChunk(chunk)
    local ret       = {}
    local entries   = {}

    local sp, ep, np = nil, nil, nil
    while true do
        sp, ep = string.find(chunk, VELLANE_REGEX, np)
        if not ret.start_pos then
            ret.start_pos = sp
        end

        if sp then
            print(sp)
            ret.end_pos         = ep
            np                  = ep + 1
            local vl            = string.sub(chunk, sp, ep)
            local num, height, inline_ed_height, zoom_offset, zoom_factor, lead = vl.match(vl, VELLANE_REGEX)

            entries[#entries+1] = {
                num=tonumber(num),
                height=tonumber(height),
                inline_ed_height=tonumber(inline_ed_height),
                zoom_offset=tonumber(zoom_offset),
                zoom_factor=tonumber(zoom_factor),
                lead=lead
            }
        else
            break
        end
    end

    if not ret.start_pos then
        -- No vellane, use fallback strategy (usually does not happen except for empty track + item that were never edited)
        sp, ep = string.find(chunk, SRCCOLOR_REGEX, nil)
        ret.start_pos   = ep + 1
        ret.end_pos     = ret.start_pos
    end

    ret.chunk   = chunk
    ret.entries = entries

    return ret
end

local function newVirginVellane(num)
    return {
        num = num,
        height = 30,
        inline_ed_height = 10,
        zoom_offset = 0,
        zoom_factor = 1,
        lead = ''
    }
end

-- Reinsert modified vellanes at the right place.
local function applyNewVellanes(item_vellane_ctx)

    local entries   = item_vellane_ctx.entries
    local chunk     = item_vellane_ctx.chunk

    local vellane_count = 0
    local subchunk = ""
    for _, entry in pairs(entries) do
        local height    = entry.height or 30
        local ieh       = entry.inline_ed_height or 10
        local zo        = entry.zoom_offset or 0
        local zf        = entry.zoom_factor or 1
        local lead      = entry.lead or ''

        subchunk = subchunk .. "\nVELLANE " .. entry.num .. " " .. height .. " " .. ieh .. " " .. zo .. " " .. zf .. " " .. lead
        vellane_count = vellane_count + 1
    end
    subchunk = subchunk .. "\n" -- for safety

    if vellane_count == 0 then
        -- Reaper is picky on this. We should have at least one vellane.
        -- Add velocity with height 0
        subchunk = "\nVELLANE -1 0 0 0 1\n"
    end

    item_vellane_ctx.chunk = string.sub(chunk, 1, item_vellane_ctx.start_pos-1) .. subchunk .. string.sub(chunk, item_vellane_ctx.end_pos+1, -1)
end


return {
    totalHeight            = totalHeight,
    readVellanesFromChunk  = readVellanesFromChunk,
    applyNewVellanes       = applyNewVellanes,
    newVirginVellane       = newVirginVellane
}

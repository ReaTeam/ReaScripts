-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

-- Vellane regex : num, height, inline_height, zoom_offset, zoom_factor
VELLANE_REGEX = "VELLANE (-?[.0-9]+) (-?[.0-9]+) (-?[.0-9]+) (-?[.0-9]+) (-?[.0-9]+)([^\n]*)"

local function totalHeight(vellanes)
    local vh = 0
    for _, vl in ipairs(vellanes.entries) do
        vh = vh + vl.height
    end
    return vh
end

-- Retreave all vellanes and insertion point/range from chunk.
local function readVellanesFromChunk(chunk, take)

    if not take then return { chunk = chunk, entries = {} } end

    local info_by_take = {}

    local li        = 0
    local curguid   = nil
    local tag       = nil
    local stack     = {}

    for line in chunk:gmatch("%s*([^\n\r]*)[\r\n]?") do

        li = li + 1

        tag = line:match("^<([^%s]+)")
        if tag then
          stack[#stack+1] = tag
        end

        if line:match("^>") then
          stack[#stack] = nil
        end

        if (#stack == 1) then
          -- Detect good GUID
          local guid = line:match("^GUID ([^%s]+)")
          if guid then
            curguid = guid
            info_by_take[curguid] = { entries = {}, cfgeditview = ""}
          end
        end

        if (#stack == 2) then
            local num, height, inline_ed_height, zoom_offset, zoom_factor, lead = line:match(VELLANE_REGEX)
            if num then
                local entries = info_by_take[curguid].entries
                entries[#entries+1] = {
                    num=tonumber(num),
                    height=tonumber(height),
                    inline_ed_height=tonumber(inline_ed_height),
                    zoom_offset=tonumber(zoom_offset),
                    zoom_factor=tonumber(zoom_factor),
                    lead=lead,
                    li=li
                }
            end

            local s1, s2 = line:match('CFGEDITVIEW [^%s]+ [^%s]+ ([^%s]+) ([^%s]+) [^\n]+')
            if s1 then
                info_by_take[curguid].piano_roll_top = 127 - tonumber(s1)
                info_by_take[curguid].piano_roll_hbt = tonumber(s2)
            end
        end
    end

    local  take_guid = reaper.BR_GetMediaItemTakeGUID(take)

    return {
        chunk             = chunk,
        piano_roll_top    = info_by_take[take_guid].piano_roll_top or 127,
        piano_roll_hbt    = info_by_take[take_guid].piano_roll_hbt or 10,
        entries           = info_by_take[take_guid].entries or {}
    }
end

-- Reinsert modified vellanes at the right place.
local function applyNewVellanes(item_vellane_ctx, take)

    if not take then return end

    local take_guid = reaper.BR_GetMediaItemTakeGUID(take)

    local entries   = item_vellane_ctx.entries
    local chunk     = item_vellane_ctx.chunk

    local li        = 0
    local curguid   = nil
    local tag       = nil
    local stack     = {}

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

    local new_chunk = ""

    for line in chunk:gmatch("%s*([^\n\r]*)[\r\n]?") do

        li                  = li + 1

        local keepline      = true

        tag = line:match("^<([^%s]+)")
        if tag then
          stack[#stack+1] = tag
        end

        if line:match("^>") then
          stack[#stack] = nil
        end

        if (#stack == 1) then
          -- Detect good GUID
          local guid = line:match("^GUID ([^%s]+)")
          if guid then
            curguid = guid
          end
        end

        if (#stack == 2) and (curguid == take_guid) then
            if line:match("^VELLANE") then
                keepline = false
            end
            if line:match("^SRCCOLOR") then
                -- Insert vellanes before srccolor
                new_chunk = new_chunk .. subchunk
            end
        end

        if keepline then
            new_chunk = new_chunk .. line .. "\n"
        end
    end

    -- Replace the old chunk
    item_vellane_ctx.chunk = new_chunk
end


return {
    totalHeight            = totalHeight,
    readVellanesFromChunk  = readVellanesFromChunk,
    applyNewVellanes       = applyNewVellanes
}

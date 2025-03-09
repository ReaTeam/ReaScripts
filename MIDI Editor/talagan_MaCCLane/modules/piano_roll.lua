-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local UTILS     = require "modules/utils"
local VELLANE   = require "modules/vellane"

---------------------

-- Context class for caching some operations and pointers like item/take/chunk

local PRCtx = {}
PRCtx.__index = PRCtx

function PRCtx:new (me)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(me)
    return instance
end

function PRCtx:_initialize(me)
    local take = reaper.MIDIEditor_GetTake(me)
    if not take then return end

    local item = reaper.GetMediaItemTake_Item(take)
    if not item then return end

    self.me   = me
    self.take = take
    self.item = item
    self.rcc  = 0
    self.ok   = true
end

function PRCtx:readChunk()
    _, self.chunk = reaper.GetItemStateChunk(self.item, "", false)
--    self.chunk = CHUNK.getItemChunk(self.item) --
    self.rcc   = self.rcc + 1
end

-----------------

-- cached_chunk may be nil, it will be read from the me's active take then
local function pianoRollHeight(me, ctx)
    if not ctx      then ctx = PRCtx:new(me) end
    if not ctx.ok   then return nil, nil end

    if ctx.height then return ctx.height end

    ctx:readChunk()
    local vellanes  = VELLANE.readVellanesFromChunk(ctx.chunk)
    local h         = 0
    local hwnd      = UTILS.JS_FindMidiEditorSysListView32(me)

    if not hwnd then
        error("Something nasty happened ! No SysListView32 child window in midi editor !")
    end

    h = h + UTILS.JS_Window_GetBounds(hwnd).h
    h = h - 16 -- bottom scrollbar
    h = h - 65 -- Time header
    h = h - VELLANE.totalHeight(vellanes)

    -- Reaper prevents the piano roll from being resized under 10px.
    -- If so, the vellanes are resized, not the PR.
    if h < 10 then h = 10 end

    ctx.height = h
    return h
end

-- cached_chunk may be nil, it will be read from the me's active take then
local function pianoRollRange(me, ctx)

    if not ctx      then ctx = PRCtx:new(me) end
    if not ctx.ok   then return nil, nil end

    -- The first call will ensure that there's a chunk
    local totalHeight   = pianoRollHeight(me, ctx)
    local topnote       = 127 -- Top note
    local h12           = 10  -- Height of one octava / 12

    -- TODO !!! MAtch the current me's active take !
    -- This only works atm if the take is the only one in the item !
    for s1, s2 in ctx.chunk:gmatch 'CFGEDITVIEW [^%s]+ [^%s]+ ([^%s]+) ([^%s]+) [^\n]+\n' do
        topnote = 127 - tonumber(s1)
        h12     = tonumber(s2) or 10
    end

    if topnote > 127 then topnote = 127 end

    local notespan   = totalHeight / h12
    local bottomnote = math.floor(topnote - notespan + 1)

    if bottomnote < 0   then bottomnote = 0 end

    return bottomnote, topnote
end

-- Use a stregy to minimize the number of chunk processing
local function _incrementalZoom(me, ctx, bottom, top)
    local wanted_zoom       = top - bottom
    local cbot, ctop        = pianoRollRange(me, ctx)
    local current_zoom      = ctop - cbot

    local diff              = wanted_zoom - current_zoom
    local new_diff          = diff
    local last_diff         = diff
    local action            = 40112
    local security  = 0

    -- reaper.ShowConsoleMsg("=====n")
    -- reaper.ShowConsoleMsg("Wanted zoom : " .. bottom .. " " .. MIDI.noteName(bottom) .. " " .. top .. " " .. MIDI.noteName(top) .. "\n")
    -- reaper.ShowConsoleMsg("Cur zoom : " .. cbot .. " " .. MIDI.noteName(cbot) .. " " .. ctop .. " " .. MIDI.noteName(ctop) .. "\n")
    -- reaper.ShowConsoleMsg("-----\n")
    local step      = 16

    while step >= 0.5 do
        -- reaper.ShowConsoleMsg("Step : " .. step .. "\n")

        action = (diff > 0) and (40112) or (40111) -- zoom out / zoom in

        -- If the sign is not reversed, the zooming is not sufficient
        -- We want to converge to reach zero (new_diff == 0)
        while diff * new_diff > 0 do

            local stop = math.max(step, 1)
            for _ = 1, stop do
                reaper.MIDIEditor_OnCommand(me, action)
                security = security + 1
            end

            if security > 100 then break end

            -- Force chunk refresh, we need it to get the obtained range
            ctx:readChunk()
            cbot, ctop    = pianoRollRange(me, ctx)
            current_zoom  = ctop - cbot

            new_diff      = wanted_zoom - current_zoom
        end

        if security > 100 then break end

        -- reaper.ShowConsoleMsg("Cur zoom : " .. cbot .. " " .. MIDI.noteName(cbot) .. " " .. ctop .. " " .. MIDI.noteName(ctop) .. "\n")
        -- reaper.ShowConsoleMsg("Diff " .. diff .. " new diff " .. new_diff .. " (sec : " .. security .. " )\n")

        -- The direction has changed. Go backward, and divide the step by 2.
        last_diff = diff
        diff      = new_diff
        step      = step/2

        --reaper.ShowConsoleMsg("" .. cbot .. " " .. ctop .. " (" .. diff .. ")\n" )
    end

    if (last_diff < 0 and diff > 0) then
        -- Precedent step state was better
       -- reaper.ShowConsoleMsg("Undoing.")
        reaper.MIDIEditor_OnCommand(me, (action == 40112) and 40111 or 40112)
    end

    return cbot, ctop
end

-- Use a stregy to minimize the number of chunk processing
local function _incrementalPan(me, ctx, bottom, top)
    local cbot, ctop        = pianoRollRange(me, ctx)
    local step              = 16
    local security          = 0
    local mid               = 0.5 * (bottom + top)
    local cmid              = 0.5 * (cbot + ctop)
    local diff              = cmid - mid
    local new_diff          = diff
    local last_diff         = diff
    local action            = 40139

    while step >= 0.5 do

        action = (diff > 0) and (40139) or (40138) -- scroll up / down

        -- If the sign is not reversed, the zooming is not sufficient
        -- We want to converge to reach zero (new_diff == 0)
        while diff * new_diff > 0 do

            local stop = math.max(step, 1)
            for _ = 1, stop do
                reaper.MIDIEditor_OnCommand(me, action)
                security = security + 1
            end

            if security > 100 then break end

            -- Force chunk refresh, we need it to get the obtained range
            ctx:readChunk()
            cbot, ctop    = pianoRollRange(me, ctx)
            cmid          = (cbot + ctop)/2
            new_diff      = cmid - mid
        end

        if security > 100 then break end

        -- The direction has changed. Go backward, and divide the step by 2.
        last_diff = diff
        diff = new_diff
        step = step/2
    end

    if math.abs(last_diff) < math.abs(diff) then
        -- Precedent step state was better
        -- reaper.ShowConsoleMsg("Undoing.")
        reaper.MIDIEditor_OnCommand(me, (action == 40139) and 40138 or 40139)
    end
end

local function setPianoRollRange(me, bottom, top)
    local ctx = PRCtx:new(me)

    if not ctx.ok  then return end
    if top < bottom then top, bottom = bottom, top end
    if bottom < 0   then bottom = 0 end
    if top > 127    then top = 127 end

    -- Get active row. We use it for zooming / paning because reaper actions are centered on it.
    -- We'll change it now and then restore it at the end
    local activerow = reaper.MIDIEditor_GetSetting_int(me, "active_note_row");

    reaper.PreventUIRefresh(1)
    reaper.MIDIEditor_SetSetting_int(me, "active_note_row", math.floor(bottom + top + 0.5))

    -- Do the ping pong twice, because we sometimes get some problems
    -- On boundaries etc .. neeed to think of a better implementation
    _incrementalZoom(me, ctx, bottom, top)
    _incrementalPan(me, ctx, bottom, top)
    _incrementalZoom(me, ctx, bottom, top)
    _incrementalPan(me, ctx, bottom, top)

    reaper.MIDIEditor_SetSetting_int(me, "active_note_row", activerow)
    reaper.PreventUIRefresh(-1)
end

return {
    height      = pianoRollHeight,
    range       = pianoRollRange,
    setRange    = setPianoRollRange,
}

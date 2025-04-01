-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local D               = require "modules/defines"

local MACCLContext    = require "modules/context"

local EXT             = require "ext/dependencies"
local DOCKING_LIB     = require (EXT.DOCKING_TOOLS_PATH)

local GRID            = require "modules/grid"
local UTILS           = require "modules/utils"
local PIANOROLL       = require "modules/piano_roll"
local CHUNK           = require "modules/chunk"
local VELLANE         = require "modules/vellane"
local PITCHSNAP       = require "modules/pitch_snap"
local TIMELINE        = require "modules/timeline"

local TabParams       = require "modules/tab_params"

-- Sanitizers for every module.

local function _SanitizeDocking(params)
    params.docking                             = params.docking or {}
    params.docking.mode                        = TabParams.DockingMode:sanitize(params.docking.mode, 'bypass')

    params.docking.if_docked                   = params.docking.if_docked or {}
    params.docking.if_docked.mode              = TabParams.IfDockedMode:sanitize(params.docking.if_docked.mode, 'bypass')
    params.docking.if_docked.size              = params.docking.if_docked.size or 500

    params.docking.if_windowed                 = params.docking.if_windowed or {}
    params.docking.if_windowed.mode            = TabParams.IfWindowedMode:sanitize(params.docking.if_windowed.mode, 'bypass')
    params.docking.if_windowed.coords          = params.docking.if_windowed.coords or { x=0, y=0, w=800, h=600 }
end

local function _SanitizeTimeWindow(params)
    params.time_window                         = params.time_window or {}

    params.time_window.positioning             = params.time_window.positioning or {}
    params.time_window.positioning.mode        = TabParams.TimeWindowPosMode:sanitize(params.time_window.positioning.mode, 'bypass')
    params.time_window.positioning.anchoring   = TabParams.TimeWindowAnchoring:sanitize(params.time_window.positioning.anchoring, 'left')
    params.time_window.positioning.position    = params.time_window.positioning.position or '0'

    params.time_window.sizing                  = params.time_window.sizing or {}
    params.time_window.sizing.mode             = TabParams.TimeWindowSizingMode:sanitize(params.time_window.sizing.mode, 'bypass')
    params.time_window.sizing.size             = params.time_window.sizing.size or '1'
end

local function _SanitizeCCLanes(params)
    params.cc_lanes                            = params.cc_lanes          or {}
    params.cc_lanes.mode                       = TabParams.CCLaneMode:sanitize(params.cc_lanes.mode, 'bypass')
    params.cc_lanes.entries                    = params.cc_lanes.entries  or {}

    for i,v in pairs(params.cc_lanes.entries) do
        v.height                                    = v.height or 0
        v.inline_ed_height                          = v.inline_ed_height or 0
        v.zoom_factor                               = v.zoom_factor or 1
        v.zoom_offset                               = v.zoom_offset or 0
    end
end

local function _SanitizePianoRoll(params)
    params.piano_roll                          = params.piano_roll or {}
    params.piano_roll.mode                     = TabParams.PianoRollMode:sanitize(params.piano_roll.mode, 'bypass')
    params.piano_roll.low_note                 = params.piano_roll.low_note or 0
    params.piano_roll.high_note                = params.piano_roll.high_note or 127
    params.piano_roll.fit_time_scope           = TabParams.PianoRollFitTimeScope:sanitize(params.piano_roll.fit_time_scope , 'visible')
    params.piano_roll.fit_owner_scope          = TabParams.PianoRollFitOwnerScope:sanitize(params.piano_roll.fit_owner_scope , 'track')
    params.piano_roll.fit_chan_scope           = params.piano_roll.fit_chan_scope or -2
end

local function _SanitizeMIDIChans(params)
   params.midi_chans                          = params.midi_chans or {}
   params.midi_chans.mode                     = TabParams.MidiChanMode:sanitize(params.midi_chans.mode, 'bypass')
   params.midi_chans.bits                     = params.midi_chans.bits or 0
   params.midi_chans.current                  = params.midi_chans.current or 'bypass' -- 'bypass' or number. It's not an enum.
end

local function _SanitizeActions(params)
    params.actions                             = params.actions or {}
    params.actions.mode                        = TabParams.ActionMode:sanitize(params.actions.mode, 'bypass')
    params.actions.entries                     = params.actions.entries or {}

    for i,v in pairs(params.actions.entries) do
        v.section                                   = v.section or 'midi_editor'
        v.id                                        = v.id or 0
        v.when                                      = TabParams.ActionWhen:sanitize(v.when, 'after')
    end
end

local function _SanitizeGrid(params)
    params.grid                                = params.grid or {}
    params.grid.mode                           = TabParams.GridMode:sanitize(params.grid.mode, 'bypass')
    params.grid.val                            = params.grid.val      or '' -- save as string
    params.grid.type                           = TabParams.GridType:sanitize(params.grid.type, 'straight')
    params.grid.swing                          = params.grid.swing    or 0  -- save as number
end

local function _SanitizeColoring(params)
    params.coloring                            = params.coloring or {}
    params.coloring.mode                       = TabParams.MEColoringMode:sanitize(params.coloring.mode, 'bypass')
    params.coloring.type                       = TabParams.MEColoringType:sanitize(params.coloring.type, 'track')
end

local function _SanitizeAll(params)
    _SanitizeDocking(params)
    _SanitizeTimeWindow(params)
    _SanitizeCCLanes(params)
    _SanitizePianoRoll(params)
    _SanitizeMIDIChans(params)
    _SanitizeActions(params)
    _SanitizeGrid(params)
    _SanitizeColoring(params)
end

local function Sanitize(tab)
    local params = tab.params

    params.title                               = params.title or "???"

    params.role                                = params.role or ''
    params.priority                            = params.priority or 0

    params.force_record_flag                   = params.force_record_flag or 0

    params.color                               = params.color or {}
    params.color.mode                          = TabParams.ColorMode:sanitize(params.color.mode, 'bypass')
    params.color.color                         = params.color.color or 0xFFFFFFFF

    params.margin                              = params.margin or {}
    params.margin.mode                         = TabParams.MarginMode:sanitize(params.margin.mode, 'bypass')
    params.margin.margin                       = params.margin.margin or 10

    _SanitizeAll(tab.params)
    _SanitizeAll(tab.state)
end

local function ReadTimeWindowPositioning(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)

    if not mec.take then return end

    local start_time, end_time, zoom = TIMELINE.GetBounds(mec.me)

    if not start_time then return end

    local duration = end_time - start_time

    _SanitizeTimeWindow(params)

    -- Force format to be in seconds using ":"
    params.time_window.positioning.position = ":" .. start_time

    if params.time_window.positioning.anchoring == 'center' then
        params.time_window.positioning.position = ":" .. (start_time + 0.5 * duration)
    end
    if params.time_window.positioning.anchoring == 'right' then
        params.time_window.positioning.position = ":" .. (end_time)
    end
end

local function ReadTimeWindowSizing(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)

    if not mec.take then return end

    local start_time, end_time, zoom = TIMELINE.GetBounds(mec.me)

    if not start_time then return end

    local duration = end_time - start_time

    _SanitizeTimeWindow(params)

    params.time_window.sizing.size           = ':' .. duration
end

local function ReadGrid(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)

    if not mec.take then return end

    local val, type, swing = GRID.GetMIDIEditorGrid(mec)

    local p, q, err = GRID.ToFrac(val)
    local str = "" .. p .. "/" .. q
    if q == 1 then str = "" .. p end

    _SanitizeGrid(params)
    params.grid.val      = str
    params.grid.type     = type
    params.grid.swing    = math.floor(swing * 100)
end

local function ReadDockingMode(tab, is_state)
    local params    = (is_state) and (tab.state) or (tab.params)

    _SanitizeDocking(params)
    local is_docked     = (reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, D.ACTION_ME_SET_DOCKED) == 1)

    if is_docked then   params.docking.mode = 'docked'
    else                params.docking.mode = 'windowed'
    end
end

local function ReadDockHeight(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)
    local bounds    = UTILS.JS_Window_GetBounds(mec.me, false)

    _SanitizeDocking(params)
    params.docking.if_docked.size = bounds.h + 20 -- For the bottom tab bar
end

local function ReadWindowBounds(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)
    local bounds    = UTILS.JS_Window_GetBounds(mec.me, true)

    _SanitizeDocking(params)
    params.docking.if_windowed.coords.x = bounds.l
    params.docking.if_windowed.coords.y = bounds.b
    params.docking.if_windowed.coords.w = bounds.w
    params.docking.if_windowed.coords.h = bounds.h
end

local function ReadCurrentPianoRollLowNote(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)

    _SanitizePianoRoll(params)
    local l, h = PIANOROLL.range(mec.me)
    if l and h then
        params.piano_roll.low_note  = l
    end
end

local function ReadCurrentPianoRollHighNote(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)

    _SanitizePianoRoll(params)
    local l, h = PIANOROLL.range(mec.me)
    if l and h then
        params.piano_roll.high_note  = h
    end
end

local function ReadMidiChans(tab, is_state)
    local params    = (is_state) and (tab.state) or (tab.params)

    _SanitizeMIDIChans(params)
    params.midi_chans.bits  = tab:getActiveChanBits()
end

local function ReadCurrentMidiChan(tab, is_state)
    local params    = (is_state) and (tab.state) or (tab.params)

    _SanitizeMIDIChans(params)
    params.midi_chans.current = reaper.MIDIEditor_GetSetting_int(tab.mec.me, 'default_note_chan')
end

local function ReadColoring(tab, is_state)
    local mec       = tab.mec
    local params    = (is_state) and (tab.state) or (tab.params)

    if not mec.take then return end

    _SanitizeColoring(params)
    params.coloring.type = GRID.GetColoringType(mec)
end


-- Don't forget to call .entries on both dst and src table
local function PatchVellaneEntries(dst_table, src_table, mode)
    if mode == 'replace' then
        for k, v in pairs(dst_table) do dst_table[k] = nil end
        for k, v in pairs(src_table) do
            dst_table[#dst_table+1] = v
        end
    elseif mode == 'add_missing' then
        local lookup = {}
        for k, v in pairs(dst_table) do lookup[v.num] = v end
        for k, v in pairs(src_table) do
            local existing_entry = lookup[v.num]
            if not existing_entry then
                -- Add missing entry
                dst_table[#dst_table+1] = v
            end
        end
    elseif mode == 'merge' then
        local lookup = {}
        for k, v in pairs(dst_table) do lookup[v.num] = v end
        for k, v in pairs(src_table) do
            local existing_entry = lookup[v.num]
            if not existing_entry then
                -- Add missing entry
                dst_table[#dst_table+1] = v
            else
                -- Remplace all values in existing entry
                for kk, vv in pairs(v) do
                    existing_entry[kk] = vv
                end
            end
        end
    end
end

local function NewVirginVellane(num)
    return {
        num = num,
        height = 30,
        inline_ed_height = 10,
        zoom_offset = 0,
        zoom_factor = 1,
        lead = ''
    }
end

-- Format :
-- { entries: table, start_pos, end_pos, chunk }
local function ReadVellanes(tab)
    local mec       = tab.mec

    local ichunk    = CHUNK.getItemChunk(mec.item)
    local vellanes  = VELLANE.readVellanesFromChunk(ichunk, mec.take)

    for _, e in ipairs(vellanes.entries) do
        if e.num == 128 then
            local tchunk = CHUNK.getTrackChunk(mec.track)
            e.snap = PITCHSNAP.hasPitchBendSnap(tchunk)
            break
        end
    end
    return vellanes
end

local function SetFullRecord(tab)
    local p = tab.params

    p.force_record_flag                 = 1

    p.docking.mode                      = 'record'
    p.docking.if_docked.mode            = 'record'
    p.docking.if_windowed.mode          = 'record'

    p.time_window.positioning.mode      = 'record'
    p.time_window.sizing.mode           = 'record'

    p.grid.mode                         = 'record'
    p.coloring.mode                     = 'record'

    p.midi_chans.current                = 'record'
    p.midi_chans.mode                   = 'record'

    p.piano_roll.mode                   = 'record'

    p.cc_lanes.mode                     = 'record'
end

----------------------------

-- State saving

local function SnapShotVellanes(tab)
    local params   = tab.state
    _SanitizeCCLanes(params)

    local vellanes = ReadVellanes(tab)
    PatchVellaneEntries(params.cc_lanes.entries, vellanes.entries, 'replace')
end
local function SnapShotDockingMode(tab)
    ReadDockingMode(tab, true)
end
local function SnapShotTimeWindowPositioning(tab)
    ReadTimeWindowPositioning(tab, true)
end
local function SnapShotTimeWindowSizing(tab)
    ReadTimeWindowSizing(tab, true)
end
local function SnapShotDockHeight(tab)
    ReadDockHeight(tab,true)
end
local function SnapShotWindowBounds(tab)
    ReadWindowBounds(tab,true)
end
local function SnapShotPianoRoll(tab)
    ReadCurrentPianoRollHighNote(tab, true)
    ReadCurrentPianoRollLowNote(tab, true)
end
local function SnapShotCurrentMidiChan(tab)
    ReadCurrentMidiChan(tab, true)
end
local function SnapShotMidiChans(tab)
    ReadMidiChans(tab, true)
end
local function SnapShotGrid(tab)
    ReadGrid(tab, true)
end
local function SnapShotColoring(tab)
    ReadColoring(tab, true)
end

----

local function SnapShotAll(tab)
    SnapShotDockingMode(tab)
    SnapShotDockHeight(tab)
    SnapShotWindowBounds(tab)

    SnapShotTimeWindowPositioning(tab)
    SnapShotTimeWindowSizing(tab)

    SnapShotVellanes(tab)

    SnapShotPianoRoll(tab)

    SnapShotCurrentMidiChan(tab)
    SnapShotMidiChans(tab)

    SnapShotColoring(tab)
    SnapShotGrid(tab)
end

-----------

local function ApplyLayouting(tab)
    local mec           = tab.mec
    local params        = tab.params
    local is_docked     = (reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, D.ACTION_ME_SET_DOCKED) == 1)

    if tab.params.docking.mode == 'record' then
        params = tab.state
    end

    if params.docking.mode == 'docked' then
        if not is_docked then
            reaper.MIDIEditor_OnCommand(mec.me,  D.ACTION_ME_SET_DOCKED)
        end
    elseif params.docking.mode == 'windowed' then
        if is_docked then
            reaper.MIDIEditor_OnCommand(mec.me,  D.ACTION_ME_SET_DOCKED)
        end
    end

    -- Second sub-module
    is_docked  = (reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, D.ACTION_ME_SET_DOCKED) == 1)
    if is_docked then
        local mode = tab.params.docking.if_docked.mode
        local dock = DOCKING_LIB.findDockThatContainsWindow(mec.me)
        if mode == 'maximize' then
            DOCKING_LIB.resizeDock(dock, 'max')
        elseif mode == 'minimize' then
            DOCKING_LIB.resizeDock(dock, 'min')
        elseif (mode == 'custom') or (mode == 'record') then
            local size = tab.params.docking.if_docked.size
            if mode == 'record' then
                size = tab.state.docking.if_docked.size
            end

            if size ~= 'min' and size ~= 'max' and not tonumber(size) then
            else
                DOCKING_LIB.resizeDock(dock, size)
            end
        end
    end

    -- Third sub-module
    local is_windowed = not is_docked
    if is_windowed then
        local mode = tab.params.docking.if_windowed.mode
        if mode == 'custom' or mode == 'record' then
            local coords = tab.params.docking.if_windowed.coords
            if mode == 'record' then
                coords = tab.state.docking.if_windowed.coords
            end

            if MACCLContext.is_windows or MACCLContext.is_linux then
                local truey = coords.y - coords.h
                reaper.JS_Window_SetPosition(tab.mec.me, coords.x, truey, coords.w, coords.h)
            else
                reaper.JS_Window_SetPosition(tab.mec.me, coords.x, coords.y, coords.w, coords.h)
            end
        end
    end
end

local function ApplyMidiChans(tab)
    local mec = tab.mec

    -- First Submodule
    if tab.params.midi_chans.current == 'bypass' then
        -- Do nothing
    else
        local params = tab.params
        if tab.params.midi_chans.current == 'record' then
            params = tab.state
        end
        -- "Set channel for new events on channel X"
        reaper.MIDIEditor_OnCommand(mec.me, 40482 + params.midi_chans.current)
    end

    -- Second submodule
    local mode = tab.params.midi_chans.mode
    if (mode == 'custom') or (mode == 'record') then
        -- Show all channels : this clears all bits and set the "all" flag
        -- we can then set things individually
        reaper.MIDIEditor_OnCommand(mec.me, D.ACTION_SHOW_ALL_MIDI_CHANS)

        -- Then untoggle those that should not be here
        for i=0, 15 do
            local bits = tab.params.midi_chans.bits
            if mode == 'record' then
                bits = tab.state.midi_chans.bits
            end

            local is_chan_available = not ((bits & (1 << i)) == 0)
            if is_chan_available then
                reaper.MIDIEditor_OnCommand(mec.me, D.ACTION_TOGGLE_MIDI_CHAN + i) -- i starts at 0 so it's ok
            end
        end
    end
end

local function ApplyGrid(tab)
    local mec = tab.mec
    local gparams = tab.params.grid

    if gparams.mode == "bypass" then return end
    if gparams.mode == "record" then gparams = tab.state.grid end

    local gv        = GRID.FromString(gparams.val)
    local swing     = gparams.swing / 100.0

    GRID.SetMIDIEditorGrid(mec, gv, gparams.type, swing)
end

local function ApplyColoring(tab)
    local mec = tab.mec
    local gparams = tab.params.coloring

    if gparams.mode == "bypass" then return end
    if gparams.mode == "record" then gparams = tab.state.coloring end

    GRID.SetColoringType(mec, gparams.type)
end

local function ApplyPianoRoll(tab)
    local mec  = tab.mec
    local mode = tab.params.piano_roll.mode

    if mode == 'custom' or mode == 'record' then

        local pr = tab.params.piano_roll
        if mode == 'record' then pr = tab.state.piano_roll end

        PIANOROLL.setRange(mec.me, pr.low_note, pr.high_note)

    elseif mode == 'fit' then

        local me_start, me_end, _ = TIMELINE.GetBounds(mec.me)
        local h                   = nil
        local l                   = nil
        local chan_bits           = tab:getActiveChanBits()

        local function noteOk(take, muted, start, stop, chan)
            local muteok = (not muted)
            local posok  = true

            local chanok = false

            if tab.params.piano_roll.fit_chan_scope == -1 then        -- All chans
                chanok = true
            elseif tab.params.piano_roll.fit_chan_scope == -2 then  -- All VISIBLE chans
                -- Chans are numbered from 0 to 15 and stored as such in chan_bits
                chanok = (chan_bits & (1 << chan) ~= 0)
            else
                -- Individual chan. Beware, fit_chan_scope stores chans from 1 to 16
                chanok = (chan == tab.params.piano_roll.fit_chan_scope)
            end

            if tab.params.piano_roll.fit_time_scope == 'visible' then
                start = reaper.MIDI_GetProjTimeFromPPQPos(take, start)
                stop  = reaper.MIDI_GetProjTimeFromPPQPos(take, stop)
                posok = (start >= me_start and start <= me_end) or (stop >= me_start and stop <= me_end) or (start <= me_start and stop >= me_end)
            end

            return muteok and posok and chanok
        end

        local function itemElligible(item)
            if tab.params.piano_roll.fit_time_scope == 'everywhere' then return true end
            local ts = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
            local te = ts + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
            return (ts >= me_start and ts <= me_end) or (te >= me_start and te <= me_end) or (ts <= me_start and te >= me_end)
        end

        local function processTake(take)
            local i = 0
            while true do
                local b, _, muted, start, stop, chan, pitch, _ = reaper.MIDI_GetNote(take, i)
                if (not b) then break end

                if noteOk(take, muted, start, stop, chan) then
                    if (not h) or (pitch > h) then h = pitch end
                    if (not l) or (pitch < l) then l = pitch end
                end
                i = i + 1
            end
        end

        if tab.params.piano_roll.fit_owner_scope == 'take' then
            if itemElligible(mec.item) then
                processTake(mec.take)
            end
        elseif tab.params.piano_roll.fit_owner_scope == 'track' then
            -- Iterate over track > all items > all takes
            local it_count = reaper.CountTrackMediaItems(mec.track)
            for i=0, it_count-1 do
                local item = reaper.GetTrackMediaItem(mec.track, i)
                if itemElligible(item) then
                    local tk_count = reaper.CountTakes(item)
                    for ti=0, tk_count-1 do
                        local take = reaper.GetTake(item, ti)
                        processTake(take)
                    end
                end
            end
        elseif tab.params.piano_roll.fit_owner_scope == 'takes' then
            -- Iterate over all tracks > all items > all takes
            local i = 0
            while true do
                local take = reaper.MIDIEditor_EnumTakes(mec.me, i, false)
                if not take then break end

                local item = reaper.GetMediaItemTake_Item(take)

                -- Check bounds
                if itemElligible(item) then
                    processTake(take)
                end

                i = i + 1
            end
        end

        if h and l then PIANOROLL.setRange(mec.me, l - 1, h + 1) end
    end
end

local function ApplyTimeline(tab)
    local mec       = tab.mec
    local tparams   = tab.params.time_window
    local tparams_s = tab.state.time_window

    local pmode    = tparams.positioning.mode
    local smode    = tparams.sizing.mode

    -- Skip if bypass
    if (pmode == 'bypass' and smode == 'bypass') then return end

    local start_time, end_time  = TIMELINE.GetBounds(mec.me)
    local duration              = end_time - start_time

    local ref_offset            = start_time or 0
    local anchoring             = tparams.positioning.anchoring

    if pmode == 'custom' or pmode == 'record' then
        local position = tparams.positioning.position
        if pmode == 'record' then
            position = tparams_s.positioning.position
        end

        ref_offset  = reaper.parse_timestr_pos(position, -1)
    else
        -- Bypass mode, get the correct reference
        if anchoring == 'left'   then ref_offset = start_time + 0               end
        if anchoring == 'center' then ref_offset = start_time + 0.5 * duration  end
        if anchoring == 'right'  then ref_offset = start_time + duration        end
    end

    if smode == 'custom' or smode == 'record' then
        local size = tparams.sizing.size
        if smode == 'record' then
            size = tparams_s.sizing.size
        end

        duration = reaper.parse_timestr_len(size, ref_offset, -1)
    end

    if anchoring == 'left' then
        start_time  = ref_offset
        end_time    = start_time + duration
    elseif anchoring == 'center' then
        start_time  = ref_offset - duration * 0.5
        end_time    = ref_offset + duration * 0.5
    elseif anchoring == 'right' then
        start_time = ref_offset - duration
        end_time   = ref_offset
    end

    TIMELINE.SetBounds(mec.me, start_time, end_time)
end

-- Use VELLANE.readVellanesFromChunk to get the current context for an item's chunk
local function patchVellaneEntriesForItem(item_vellane_ctx, new_entries, take)
    local existing_entries  = item_vellane_ctx.entries

    -- TODO : Better logic (here we simply replace all stuff ...)
    item_vellane_ctx.entries = new_entries
end

local function ApplyCCLanes(tab)
    local mec  = tab.mec
    local mode = tab.params.cc_lanes.mode

    if not (mode == 'custom' or mode == 'record') then return end

    local item_chunk    = CHUNK.getItemChunk(mec.item)
    local vellane_ctx   = VELLANE.readVellanesFromChunk(item_chunk, mec.take)

    local entries = tab.params.cc_lanes.entries
    if mode == 'record' then entries = tab.state.cc_lanes.entries end

    -- Data patching
    patchVellaneEntriesForItem(vellane_ctx, entries, mec.take)

    -- Data applying to chunk
    VELLANE.applyNewVellanes(vellane_ctx, mec.take)

    -- Replace chunk
    reaper.SetItemStateChunk(mec.item, vellane_ctx.chunk, false)

    -- Set snap for pitch bend if asked
    for _, v in ipairs(vellane_ctx.entries) do
        -- Set snap for pitch bend
        if v.num == 128 then
            local tchunk = CHUNK.getTrackChunk(mec.track)
            if tchunk then
                local b, e, semi_tone, p2, trail = tchunk:find("MIDIEDITOR (%d+) (%d+)([^\n]*)")
                if b then
                    local starting = tchunk:sub(1,b-1)
                    local ending   = tchunk:sub(e+1, #tchunk)
                    --local torep    = tchunk:sub(b,e)
                    local rep      = "MIDIEDITOR " .. semi_tone .. " " .. ((v.snap == true) and (1) or (0)) .. trail
                    tchunk = starting .. rep .. ending
                    reaper.SetTrackStateChunk(mec.track, tchunk)
                else
                    -- The MIDIEDITOR line does not exist ... create it
                    -- Put it immediately on second line of the track
                    local idx = tchunk:find("\n")
                    if idx then
                        local starting = tchunk:sub(1, idx - 1)
                        local ending   = tchunk:sub(idx+1, #tchunk)
                        tchunk = starting .. "\nMIDIEDITOR 1 " .. ((v.snap == true) and (1) or (0)) .. "\n" .. ending
                        reaper.SetTrackStateChunk(mec.track, tchunk)
                    end
                end
            end
            break
        end
    end
end

-----------

return {
    Sanitize                        = Sanitize,

    ReadGrid                        = ReadGrid,
    ReadDockHeight                  = ReadDockHeight,
    ReadWindowBounds                = ReadWindowBounds,
    ReadCurrentPianoRollLowNote     = ReadCurrentPianoRollLowNote,
    ReadCurrentPianoRollHighNote    = ReadCurrentPianoRollHighNote,
    ReadMidiChans                   = ReadMidiChans,
    ReadColoring                    = ReadColoring,
    ReadVellanes                    = ReadVellanes,
    ReadTimeWindowPositioning       = ReadTimeWindowPositioning,
    ReadTimeWindowSizing            = ReadTimeWindowSizing,

    SetFullRecord                   = SetFullRecord,

    SnapShotAll                     = SnapShotAll,
    SnapShotGrid                    = SnapShotGrid,
    SnapShotDockHeight              = SnapShotDockHeight,
    SnapShotWindowBounds            = SnapShotWindowBounds,
    SnapShotPianoRoll               = SnapShotPianoRoll,
    SnapShotMidiChans               = SnapShotMidiChans,
    SnapShotColoring                = SnapShotColoring,
    SnapShotVellanes                = SnapShotVellanes,
    SnapShotDockingMode             = SnapShotDockingMode,
    SnapShotTimeWindowPositioning   = SnapShotTimeWindowPositioning,
    SnapShotTimeWindowSizing        = SnapShotTimeWindowSizing,

    ApplyLayouting                  = ApplyLayouting,
    ApplyMidiChans                  = ApplyMidiChans,
    ApplyGrid                       = ApplyGrid,
    ApplyColoring                   = ApplyColoring,
    ApplyPianoRoll                  = ApplyPianoRoll,
    ApplyTimeline                   = ApplyTimeline,
    ApplyCCLanes                    = ApplyCCLanes,

    PatchVellaneEntries             = PatchVellaneEntries,
    NewVirginVellane                = NewVirginVellane
}

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local UTILS           = require "modules/utils"
local MACCLContext    = require "modules/context"
local TabParams       = require "modules/tab_params"
local CHUNK           = require "modules/chunk"
local VELLANE         = require "modules/vellane"
local CCLANELIST      = require "modules/cc_lane_list"
local MIDI            = require "modules/midi"
local TIMELINE        = require "modules/timeline"
local GRID            = require "modules/grid"
local PITCHSNAP       = require "modules/pitch_snap"

local ComboSearch     = require "classes/combo_search"
local Tab             = require "classes/tab"
local GlobalScopeRepo = require "classes/global_scope_repo"

local ImGui           = MACCLContext.ImGui

local function EllipsedText(ctx, text, max_width)
    local w, _ = ImGui.CalcTextSize(ctx, text)
    if w < max_width then return text end

    local len = utf8.len(text)

    local l   = 1
    local h   = len

    local tl  = UTILS.utf8sub(text, 1, l) .. "..."
    local lw  = ImGui.CalcTextSize(ctx, tl)

    if lw > max_width then return tl end

    local th  = UTILS.utf8sub(text, 1, h) .. "..."
    local hw  = ImGui.CalcTextSize(ctx, th)

    while h - l > 1 do
        local m = math.floor((h+l) * 0.5)
        local tm = UTILS.utf8sub(text, 1, m) .. "..."
        local mw = ImGui.CalcTextSize(ctx, tm)
        if mw > max_width then
            -- Too big.
            h  = m
            th = tm
            hw = mw
        else
            l  = m
            tl = tm
            lw = mw
        end
    end

    if hw > max_width then return tl end

    return th
end

local function PushRedStyle(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,         0xAA0000FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,  0xFF0000FF)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,   0xCC0000FF)
end
local function PushCyanStyle(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,         0x4296FAC7)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,  0x4296FAA0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,   0x4296FAFF)
end
local function PushGreenStyle(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,         0x42FA66A0)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,  0x42FA66C7)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,   0x42FA66FF)
end

local function MoveCursorY(ctx, off)
    ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) + off)
end

local function TT(ctx, str)
    if ImGui.IsItemHovered(ctx, ImGui.HoveredFlags_DelayNormal) then
        ImGui.SetTooltip(ctx, str)
    end
end

local function PopRedStyle(ctx)    ImGui.PopStyleColor(ctx, 3) end
local function PopCyanStyle(ctx)   ImGui.PopStyleColor(ctx, 3) end
local function PopGreenStyle(ctx)  ImGui.PopStyleColor(ctx, 3) end

local function ReadButton(ctx, id, callback)
    PushCyanStyle(ctx)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
    local img = MACCLContext.GetImage("read")
    if img and ImGui.ImageButton(ctx, id, img, 19, 19) then
        callback()
    end
    ImGui.PopStyleVar(ctx)
    PopCyanStyle(ctx)
    TT(ctx, "Get value(s) from current's MIDI Editor state")
end


local function ClippedSeparatorText(ctx, str, width)
    if width < 0 then
        ImGui.SeparatorText(ctx, str)
    else
        local cx, cy = ImGui.GetCursorScreenPos(ctx)
        -- Hack for separator text that whant to use the full window width
        ImGui.PushClipRect(ctx, cx, cy, cx+width, cy+40, false)
        ImGui.SeparatorText(ctx, str)
        ImGui.PopClipRect(ctx)
    end
end

------------------

local TabEditor = {}
TabEditor.__index = TabEditor

TabEditor.registry = {}

function TabEditor:new (mec, tab)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()
    -- Make a copy of the tab, that we can edit directly
    instance.mec = mec
    instance.tab = UTILS.deepcopy(tab)
    return instance
end

function TabEditor:_initialize()
end

function TabEditor.ownerTypeToRadio(ot)
    if ot == Tab.Types.GLOBAL then
        return 0
    elseif ot == Tab.Types.PROJECT then
        return 1
    elseif ot == Tab.Types.TRACK then
        return 2
    elseif ot == Tab.Types.ITEM then
        return 3
    end

    return -1
end

-- This will try to detect a window height change
-- And keep the tab editor at the same y position, from the BOTTOM
function TabEditor:gfxAutoMove()
    local ctx = MACCLContext.ImGuiContext
    local wx, wy = ImGui.GetWindowPos(ctx)
    local ww, wh = ImGui.GetWindowSize(ctx)

    if self.last_window_bounds and self.draw_count > 1 and not (wh == self.last_window_bounds.h) then
        wy = self.last_window_bounds.y + self.last_window_bounds.h - wh
        -- If the height changes, try to keep the same y bottom. Unfortunately, this will glitch during 1 frame
        -- Since the window is already drawn at this stage
        ImGui.SetWindowPos(ctx, wx, wy)
    end

    self.last_window_bounds = {x=wx,y=wy,h=wh,w=ww}
end

function TabEditor:comboLeftLabel(ctx, text, is_first_on_line)
    -- Buch of corrections for creating left align labels ...
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + 1)
    ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) + 3 * (is_first_on_line and 1 or -1))
    ImGui.Text(ctx,text)
    ImGui.SameLine(ctx)
    MoveCursorY(ctx, -3)
end

function TabEditor:gfxModeCombobox(ctx, text, mode_enum, params, is_first, mode_field_name, width)

    self:comboLeftLabel(ctx, text, is_first)

    local selectableLabel = function (mode_name)
        return (mode_enum:humanize(mode_name) or '') .. "##mode_" .. mode_name
    end

    local mode = params[mode_field_name or 'mode']

    ImGui.SetNextItemWidth(ctx, width or 100)
    if ImGui.BeginCombo(ctx, "##mode", selectableLabel(mode)) then
        for i,v in ipairs(mode_enum.defs) do
            local is_selected = (mode == v.name)

            if ImGui.Selectable(ctx, selectableLabel(v.name), is_selected) then
                params[mode_field_name or 'mode'] = v.name
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
            end
        end

        ImGui.EndCombo(ctx)
    end

    return params[mode_field_name or 'mode']
end

function TabEditor:currentChanComboBox(ctx, params)
    local selectableLabel = function (chan)
        if chan == 'bypass' then return 'Bypass##current_chan_bypass' end
        return 'Chan ' .. (chan + 1) .. '##current_chan_' .. (chan + 1)
    end

    self:comboLeftLabel(ctx, 'Current', true)

    ImGui.SetNextItemWidth(ctx, 100)
    local mode = params.current
    if ImGui.BeginCombo(ctx, "##current_chan_combo", selectableLabel(mode)) then
        for i=-1, 15 do
            local s             = (i == -1 and 'bypass' or i)
            local is_selected   = (s == mode)

            if ImGui.Selectable(ctx, selectableLabel(s), is_selected) then
                params.current = s
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
            end
        end

        ImGui.EndCombo(ctx)
    end

    return params.current
end

function TabEditor:fitChanScopeComboBox(ctx, params)
    local selectableLabel = function (chan)
        if chan == -2 then return 'All visible chans##all_visible_chans' end
        if chan == -1 then return 'All chans##all_chans' end
        return 'Chan ' .. (chan + 1) .. '##chan_' .. (chan + 1)
    end

    self:comboLeftLabel(ctx, 'Chan Scope', true)

    ImGui.SetNextItemWidth(ctx, 175)
    local mode = params.fit_chan_scope
    if ImGui.BeginCombo(ctx, "##chan_scope_combo", selectableLabel(mode)) then
        for i=-2, 15 do
            local is_selected  = (i == mode)

            if ImGui.Selectable(ctx, selectableLabel(i), is_selected) then
                params.fit_chan_scope = i
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
            end
        end

        ImGui.EndCombo(ctx)
    end

    return params.fit_chan_scope
end


-- To be used in the action table, already scoped per row with PushID/PopID
function TabEditor:actionSectionComboBox(ctx, entry)
    local selectableLabel = function (section_name)
        return '' .. TabParams.ActionSection:humanize(section_name) .. '##section_' .. section_name
    end

    ImGui.SetNextItemWidth(ctx, 110)
    if ImGui.BeginCombo(ctx, "##section_combo", selectableLabel(entry.section)) then
        for i,v in ipairs(TabParams.ActionSection.defs) do
            local section_name = v.name
            local is_selected  = (section_name == entry.section)

            if ImGui.Selectable(ctx, selectableLabel(section_name), is_selected) then
                entry.section = section_name
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
            end
        end
        ImGui.EndCombo(ctx)
    end
    return entry.section
end

function TabEditor:actionWhenCombo(ctx, entry)
    local selectableLabel = function (name)
        return '' .. TabParams.ActionWhen:humanize(name) .. '##action_when_' .. name
    end

    ImGui.SetNextItemWidth(ctx, 70)
    if ImGui.BeginCombo(ctx, "##action_when", selectableLabel(entry.when)) then
        for i,v in ipairs(TabParams.ActionWhen.defs) do
            local name          = v.name
            local is_selected   = (name == entry.when)

            if ImGui.Selectable(ctx, selectableLabel(name), is_selected) then
                entry.when = name
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
            end
        end
        ImGui.EndCombo(ctx)
    end
    return entry.when
end

function TabEditor:genericEnumComboBox(ctx, params, field, enum, local_id, width)
    local selectableLabel = function (name)
        return '' .. enum:humanize(name) .. '##' .. local_id .. '_' .. name
    end

    ImGui.SetNextItemWidth(ctx, width)
    if ImGui.BeginCombo(ctx, "##" .. local_id, selectableLabel(params[field])) then
        for i,v in ipairs(enum.defs) do
            local name          = v.name
            local is_selected   = (name == params[field])

            if ImGui.Selectable(ctx, selectableLabel(name), is_selected) then
                params[field] = name
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
            end
        end
        ImGui.EndCombo(ctx)
    end
    return params[field]
end


function TabEditor:gfxOwnerSection()
    local mec           = self.mec
    local tab           = self.tab
    local ctx           = MACCLContext.ImGuiContext

    local is_new_record = tab.new_record -- Use this denormalize flag in the context of the function as it can change on save

    ImGui.SeparatorText(ctx, 'Owned by')

    if is_new_record then
        local meinfo    = mec:editorInfo()
        local ot        = TabEditor.ownerTypeToRadio(tab.owner_type)
        local p, v

        ImGui.BeginGroup(ctx)
        if true then -- indent
            p, v = ImGui.RadioButtonEx(ctx, 'Global', ot, 0)
            if p then tab:setOwner(GlobalScopeRepo.instance()) end

            p, v = ImGui.RadioButtonEx(ctx, 'Project', ot, 1)
            if p then tab:setOwner(nil) end
        end
        ImGui.EndGroup(ctx)

        ImGui.SameLine(ctx, 150)

        ImGui.BeginGroup(ctx)
        if true then
            if meinfo.track then
                p, v = ImGui.RadioButtonEx(ctx, 'Track (' .. meinfo.track_name .. ')' ,  ot, 2)
                if p then tab:setOwner(meinfo.track) end
            end

            if meinfo.item then
                p, v = ImGui.RadioButtonEx(ctx, 'Item (' .. meinfo.take_name ..')',  ot, 3)
                if p then tab:setOwner(meinfo.item) end
            end
        end
        ImGui.EndGroup(ctx)
    else
        ImGui.Text(ctx, tab:ownerInfo().desc)
    end
end

function TabEditor:gfxDockingSection()
    local mec               = self.mec
    local tab               = self.tab
    local ctx               = MACCLContext.ImGuiContext
    local meinfo            = mec:editorInfo()

    local params    = tab.params.docking

    ImGui.BeginGroup(ctx)
    ClippedSeparatorText(ctx, "Docking Mode", 140)
    ImGui.PushID(ctx, "docking_mode_section")
    self:gfxModeCombobox(ctx, "Mode", TabParams.DockingMode, params, true, nil, nil)
    ImGui.PopID(ctx)
    ImGui.EndGroup(ctx)

    ImGui.SameLine(ctx)

    ImGui.PushID(ctx, "if_docked_section")
    params = tab.params.docking.if_docked
    ImGui.BeginGroup(ctx)
    ClippedSeparatorText(ctx, "Size if docked", 140)
    self:gfxModeCombobox(ctx, "Mode", TabParams.IfDockedMode, params, true, nil, nil)

    if params.mode == 'custom' then
        self:comboLeftLabel(ctx, 'Size', true)

        ImGui.SetNextItemWidth(ctx, 64)
        _, params.size = ImGui.InputText(ctx, "##size", params.size) -- May be min, max, number or nothing (bypass)

        ImGui.SameLine(ctx)
        MoveCursorY(ctx, -3)
        ReadButton(ctx, "##read_button", function()
            tab:readDockHeight()
        end)
    end
    ImGui.EndGroup(ctx)
    ImGui.PopID(ctx)

    ImGui.SameLine(ctx)

    ImGui.PushID(ctx, "if_windowed_section")
    params = tab.params.docking.if_windowed
    ImGui.BeginGroup(ctx)
    ImGui.SeparatorText(ctx, "Dimensions if windowed")
    self:gfxModeCombobox(ctx, "Mode", TabParams.IfWindowedMode, params, true, nil, nil)

    if params.mode == 'custom' then

        self:comboLeftLabel(ctx, "X", true)

        ImGui.SetNextItemWidth(ctx, 40)
        _, params.coords.x = ImGui.InputText(ctx, "##x", params.coords.x) -- May be empty (bypass)
        ImGui.SameLine(ctx)

        self:comboLeftLabel(ctx, "Y", false)
        ImGui.SetNextItemWidth(ctx, 40)
        _, params.coords.y = ImGui.InputText(ctx, "##y", params.coords.y) -- May be empty (bypass)
        ImGui.SameLine(ctx)

        self:comboLeftLabel(ctx, "W", false)
        ImGui.SetNextItemWidth(ctx, 40)
        _, params.coords.w = ImGui.InputText(ctx, "##w", params.coords.w) -- May be empty (bypass)
        ImGui.SameLine(ctx)

        self:comboLeftLabel(ctx, "X", false)
        ImGui.SetNextItemWidth(ctx, 40)
        _, params.coords.h = ImGui.InputText(ctx, "##h", params.coords.h) -- May be empty (bypass)

        ImGui.SameLine(ctx); MoveCursorY(ctx, -3)
        ReadButton(ctx, "##read_button", function()
            tab:readWindowBounds()
        end)
    end

    ImGui.EndGroup(ctx)
    ImGui.PopID(ctx)
end

function TabEditor:patchVellaneEntries(dst_table, src_table, mode)
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

function TabEditor:getVellanes(meinfo)
    local ichunk    = CHUNK.getItemChunk(meinfo.item)
    local vellanes  = VELLANE.readVellanesFromChunk(ichunk, meinfo.take)

    for _, e in ipairs(vellanes.entries) do
        if e.num == 128 then
            local tchunk = CHUNK.getTrackChunk(meinfo.track)
            e.snap = PITCHSNAP.hasPitchBendSnap(tchunk)
        end
    end
    return vellanes
end

function TabEditor:readCCLanePopup()
    local mec           = self.mec
    local tab           = self.tab
    local ctx           = MACCLContext.ImGuiContext
    local meinfo        = mec:editorInfo()
    local cc_lane_params    = tab.params.cc_lanes
    local entries       = cc_lane_params.entries

    if ImGui.BeginPopup(ctx, "get_cc_lane_popup" ) then

        ImGui.PushID(ctx, "cc_lanes_from_editor")
        ImGui.MenuItem(ctx, "From editor ...", "", false, false)
        if ImGui.MenuItem(ctx, "Displayed CC lanes (Add missing)") then
            if meinfo.item then
                local vellanes = self:getVellanes(meinfo)
                self:patchVellaneEntries(entries, vellanes.entries, 'add_missing')
            end
        end
        if ImGui.MenuItem(ctx, "Displayed CC lanes (Merge)") then
            if meinfo.item then
                local vellanes = self:getVellanes(meinfo)
                self:patchVellaneEntries(entries, vellanes.entries, 'merge')
            end
        end
        if ImGui.MenuItem(ctx, "Displayed CC lanes (Replace)") then
            if meinfo.item then
                local vellanes = self:getVellanes(meinfo)
                self:patchVellaneEntries(entries, vellanes.entries, 'replace')
            end
        end
        ImGui.PopID(ctx)

        ImGui.Separator(ctx)

        local function crawlTakeForEvents(take, lookup)
            local ci = 0
            while true do
                local b, sel, mut, pos, chanmsg, chan, msg2, msg3 = reaper.MIDI_GetCC(take, ci)
                if not b then break end
                local mtype = ((chanmsg & 0xF0) >> 4)
                if mtype == 0xB then -- CC
                    lookup[msg2] = true
                elseif mtype == 0xC then-- PC
                    lookup[129] = true
                    lookup[131] = true
                elseif mtype == 0xE then
                    lookup[128] = true
                end
                ci = ci + 1
            end
        end

        ImGui.PushID(ctx, "cc_lanes_from_track")
        ImGui.MenuItem(ctx, "From active take's track ...", "", false, false)
        if ImGui.MenuItem(ctx, "Used CC lanes (Add missing)") then
            -- Iterate over track > all items > all takes
            local cc_lookup = {}
            local it_count = reaper.CountTrackMediaItems(mec.track)
            for i=0, it_count-1 do
                local item = reaper.GetTrackMediaItem(mec.track, i)
                local tk_count = reaper.CountTakes(item)
                for ti=0, tk_count-1 do
                    local take = reaper.GetTake(item, ti)
                    crawlTakeForEvents(take, cc_lookup)
                end
            end
            local new_potential_entries = {}
            for cc_lane, _ in pairs(cc_lookup) do
                new_potential_entries[#new_potential_entries+1] = VELLANE.newVirginVellane(cc_lane)
            end
            self:patchVellaneEntries(entries, new_potential_entries, 'add_missing')
        end
        ImGui.PopID(ctx)

        ImGui.Separator(ctx)

        ImGui.PushID(ctx, "cc_lanes_from_item")
        ImGui.MenuItem(ctx, "From active take ...", "", false, false)
        if ImGui.MenuItem(ctx, "Used CC lanes (Add missing)") then
            local cc_lookup = {}
            crawlTakeForEvents(mec.take, cc_lookup)
            local new_potential_entries = {}
            for cc_lane, _ in pairs(cc_lookup) do
                new_potential_entries[#new_potential_entries+1] = VELLANE.newVirginVellane(cc_lane)
            end
            self:patchVellaneEntries(entries, new_potential_entries, 'add_missing')
        end
        ImGui.PopID(ctx)

        ImGui.EndPopup(ctx)
    end
end

function TabEditor:ccLaneComboBox(ctx, cc_lane_num, cc_lane_entry)

    local entry_label           = function(e)
        return e.text .. "##cc_lane_combo_entry_" .. e.num
    end

    local mec                   = self.mec
    local v                     = cc_lane_entry
    local selected_entry        = CCLANELIST.comboEntry(v.num, mec)
    local selected_lane_txt     = entry_label(selected_entry)

    if not self.cc_lane_search_ctx then self.cc_lane_search_ctx = {} end
    if not self.cc_lane_search_ctx[cc_lane_num] then self.cc_lane_search_ctx[cc_lane_num] = ComboSearch:new() end

    local combosearch = self.cc_lane_search_ctx[cc_lane_num]

    ImGui.SetNextItemWidth(ctx,230)
    if ImGui.BeginCombo(ctx, "##cc_lane_combo", selected_lane_txt, ImGui.ComboFlags_HeightLarge) then

        local cb = CCLANELIST.comboForMec(mec)

        local searchfunc = function(user_input)
            local match_num = user_input:match("^%d+$")

            if match_num then
                local ccnum = tonumber(match_num)
                if ccnum >= -1 and ccnum <= 127 then
                    for li, lv in ipairs(cb) do
                        if ccnum == lv.num then return li end
                    end
                end
            end

            for li, lv in ipairs(cb) do
                if lv.text:lower():match(user_input:lower()) then
                    return li
                end
            end

            return nil
        end

        local val = combosearch:apply(ctx, searchfunc)
        if val then v.num = cb[val].num end

        for cbi, cbv in ipairs(cb) do
            local is_selected = false
            if combosearch.num then
                if combosearch.num == cbi then
                    is_selected = true
                end
            else
                is_selected = (cbv.num == v.num)
            end

            local label = entry_label(cbv)
            if ImGui.Selectable(ctx, label, is_selected) then
                v.num = cbv.num
            end

            if is_selected then
                ImGui.SetItemDefaultFocus(ctx)
                combosearch:scrollUpdate(ctx, cbi)
            end

            TT(ctx, "REAPER's lane number : " .. cbv.num)
        end

        ImGui.EndCombo(ctx)
    else
        combosearch:clear()
    end
end


function TabEditor:gfxCCLaneSection()
    local mec               = self.mec
    local tab               = self.tab
    local ctx               = MACCLContext.ImGuiContext
    local meinfo            = mec:editorInfo()

    local ROW_HEIGHT        = 18

    local cc_lane_params    = tab.params.cc_lanes
    local mode              = cc_lane_params.mode
    local entries           = cc_lane_params.entries

    ImGui.SeparatorText(ctx, 'CC Lanes')

    ImGui.PushID(ctx, "cc_lane_section")

    mode = self:gfxModeCombobox(ctx, "Mode", TabParams.CCLaneMode, cc_lane_params, true, nil, nil)

    if mode == 'custom' then
        -- TableFlsgs_NoHostExtendX
        if ImGui.BeginTable(ctx, '##cc_lane_test', 8, ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg | ImGui.TableFlags_NoHostExtendX) then

            ImGui.TableSetupColumn(ctx, ' - ',      ImGui.TableColumnFlags_WidthFixed,  0, 0) -- Grip for drag/drop
            ImGui.TableSetupColumn(ctx, 'CC Lane',  ImGui.TableColumnFlags_WidthFixed,  0, 1)
            ImGui.TableSetupColumn(ctx, 'Height',   ImGui.TableColumnFlags_WidthFixed,  0, 2)
            ImGui.TableSetupColumn(ctx, 'IEHeight', ImGui.TableColumnFlags_WidthFixed,  0, 3)
            ImGui.TableSetupColumn(ctx, 'Zoom',     ImGui.TableColumnFlags_WidthFixed,  0, 4)
            ImGui.TableSetupColumn(ctx, 'VOff',     ImGui.TableColumnFlags_WidthFixed,  0, 5)
            ImGui.TableSetupColumn(ctx, ' S',        ImGui.TableColumnFlags_WidthFixed,  0, 6)
            ImGui.TableSetupColumn(ctx, '',         ImGui.TableColumnFlags_WidthFixed,  0, 7) -- Del

            -- Using full syntax for table headers to allow tooltiping
            ImGui.PushTabStop(ctx, false)
            for ci = 0, 7, 1 do
                ImGui.TableNextColumn(ctx);
                local cname = ImGui.TableGetColumnName(ctx, ci)
                ImGui.TableHeader(ctx, cname);
                if ci == 0 then
                    TT(ctx, "Handle to drag and drop the lane and change the order")
                elseif ci == 3 then
                    TT(ctx, "Inline Editor CC Lane Height")
                elseif ci == 4 then
                    TT(ctx, "Zoom factor for the CC lane (>1)")
                elseif ci == 5 then
                    TT(ctx, "Vertical offset of the lane when zoomed (between 0 - top and 1 - bottom)")-- body
                elseif ci == 6 then
                    TT(ctx, "Pitch snap (only applies to pitch bend CC)")
                end
            end
            ImGui.PopTabStop(ctx)

            local has_active     = false

            local should_delete_entry = nil
            for n, v in ipairs(entries) do

                ImGui.TableNextColumn(ctx)

                -----
                -- COLUMN 1 : is a selectable that spans the whole table width to allow drag and drops.

                ImGui.PushTabStop(ctx, false)
                if ImGui.Selectable(ctx, " " .. utf8.char(0x85) .. "##grip", false, ImGui.SelectableFlags_SpanAllColumns | ImGui.SelectableFlags_AllowOverlap, 0, ROW_HEIGHT) then
                end -- .. utf8.char(0x95) ..
                ImGui.PopTabStop(ctx)

                -- Handle drag and rop
                local active    = ImGui.IsItemActive(ctx)
                local hovered   = ImGui.IsItemHovered(ctx)

                if active then has_active = true end

                if active and hovered and not self.dragged_cc_lane_index then
                    self.dragged_cc_lane_index = n
                end

                if active and hovered and not (n == self.dragged_cc_lane_index) then
                    entries[n]                          = entries[self.dragged_cc_lane_index]
                    entries[self.dragged_cc_lane_index] = v
                    self.dragged_cc_lane_index          = n
                end

                ---------------------------------
                -- Column 2 : CC LANE Num
                -- This should be done after the first column because we want all first cells to have the same ID for the drag and drop to work.
                ImGui.PushID(ctx, "cc_lane_entry_" .. n)
                ImGui.TableNextColumn(ctx);
                self:ccLaneComboBox(ctx, n, v)

                ---------------------------------
                -- Column 3 : Height
                ImGui.TableNextColumn(ctx)
                ImGui.SetNextItemWidth(ctx, 50)

                local inb, inv

                inb, inv = ImGui.InputText(ctx, '##height_' .. n, "" .. v.height , ImGui.InputTextFlags_CharsDecimal)
                if inb then
                    v.height = tonumber(inv) or 0
                    if v.height < 0 then v.height = 0 end
                end

                ---------------------------------
                -- Column 4 : Height
                ImGui.TableNextColumn(ctx)
                ImGui.SetNextItemWidth(ctx, 55)

                inb, inv = ImGui.InputText(ctx, '##ie_height_' .. n, "" .. v.inline_ed_height , ImGui.InputTextFlags_CharsDecimal)
                if inb then
                    v.inline_ed_height = tonumber(inv) or 0
                    if v.inline_ed_height < 0 then v.inline_ed_height = 0 end
                end

                ---------------------------------
                -- Column 5 : Zoom
                ImGui.TableNextColumn(ctx)
                ImGui.SetNextItemWidth(ctx, 55)

                inb, inv = ImGui.InputText(ctx, '##zoom_factor_' .. n, "" .. v.zoom_factor , ImGui.InputTextFlags_CharsDecimal)
                if inb then
                    v.zoom_factor = tonumber(inv) or 0
                    if v.zoom_factor < 1  then v.zoom_factor = 1  end
                    if v.zoom_factor > 10 then v.zoom_factor = 10 end
                end

                ---------------------------------
                -- Column 6 : Zoom off
                ImGui.TableNextColumn(ctx)
                ImGui.SetNextItemWidth(ctx, 55)

                inb, inv = ImGui.InputText(ctx, '##zoom_offset_' .. n, "" .. v.zoom_offset , ImGui.InputTextFlags_CharsDecimal)
                if inb then
                    v.zoom_offset = tonumber(inv) or 0
                    if v.zoom_offset < 0 then v.zoom_offset = 0 end
                    if v.zoom_offset > 1 then v.zoom_offset = 1 end
                end

                ---------------------------------
                -- Column 7 : Snap
                ImGui.TableNextColumn(ctx);

                if v.num == 128 then
                    inb, inv = ImGui.Checkbox(ctx, '', (v.snap == true))
                    if inb then
                        v.snap = inv
                    end
                end

                ---------------------------------
                -- Column 8 : DEL
                ImGui.TableNextColumn(ctx);
                PushRedStyle(ctx)
                if ImGui.Button(ctx, "Del##del_" .. n) then
                    should_delete_entry = n
                end
                PopRedStyle(ctx)

                if not (n==#entries) then
                    ImGui.TableNextRow(ctx,ImGui.TableRowFlags_None)
                end

                ImGui.PopID(ctx)
            end

            if not has_active then
                self.dragged_cc_lane_index = nil
            end

            ImGui.EndTable(ctx)

            if should_delete_entry then
                table.remove(entries, should_delete_entry)
            end
        end

        PushCyanStyle(ctx)
        if ImGui.Button(ctx, " + ##cc_lane_add") then
            entries[#entries+1] = VELLANE.newVirginVellane(1)
        end
        PopCyanStyle(ctx)

        ImGui.SameLine(ctx)

        ReadButton(ctx, "##get", function()
            ImGui.OpenPopup(ctx, "get_cc_lane_popup")
        end)

        self:readCCLanePopup()
    end

    ImGui.PopID(ctx)
end

function TabEditor:gfxActionSection()
    local mec               = self.mec
    local tab               = self.tab
    local ctx               = MACCLContext.ImGuiContext
    local meinfo            = mec:editorInfo()

    local ROW_HEIGHT        = 18

    local params            = tab.params.actions
    local mode              = params.mode
    local entries           = params.entries

    ImGui.SeparatorText(ctx, 'Execute actions')
    ImGui.PushID(ctx, "action_section")
    mode = self:gfxModeCombobox(ctx, "Mode", TabParams.ActionMode, params, true, nil, nil)

    if mode == 'custom' then
        if ImGui.BeginTable(ctx, '##entries', 6, ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg | ImGui.TableFlags_NoHostExtendX) then

            ImGui.TableSetupColumn(ctx, ' - ',      ImGui.TableColumnFlags_WidthFixed,      0, 0) -- Grip for drag/drop
            ImGui.TableSetupColumn(ctx, 'When',     ImGui.TableColumnFlags_WidthFixed,      0, 1)
            ImGui.TableSetupColumn(ctx, 'Section',  ImGui.TableColumnFlags_WidthFixed,      0, 2)
            ImGui.TableSetupColumn(ctx, 'ID',       ImGui.TableColumnFlags_WidthFixed,      0, 3)
            ImGui.TableSetupColumn(ctx, 'Desc',     ImGui.TableColumnFlags_WidthFixed,      0, 4)
            ImGui.TableSetupColumn(ctx, '',         ImGui.TableColumnFlags_WidthFixed,      0, 5) -- Del

            -- Using full syntax for table headers to allow tooltiping
            ImGui.PushTabStop(ctx, false)
            for ci = 0, 5, 1 do
                ImGui.TableNextColumn(ctx);
                local cname = ImGui.TableGetColumnName(ctx, ci)
                ImGui.TableHeader(ctx, cname)

            end
            ImGui.PopTabStop(ctx)

            local has_active     = false

            local should_delete_entry = nil
            for n, entry in ipairs(entries) do

                ---------- DRAG/DROP COLUMN is a selectable that spans the whole table width to allow drag and drops.
                ImGui.TableNextColumn(ctx)

                ImGui.PushTabStop(ctx, false)
                if ImGui.Selectable(ctx, " " .. utf8.char(0x85) .. "##grip", false, ImGui.SelectableFlags_SpanAllColumns | ImGui.SelectableFlags_AllowOverlap, 0, ROW_HEIGHT) then
                end
                ImGui.PopTabStop(ctx)

                -- Handle drag and rop
                local active    = ImGui.IsItemActive(ctx)
                local hovered   = ImGui.IsItemHovered(ctx)

                if active then has_active = true end

                if active and hovered and not self.dragged_action then
                    self.dragged_action = n
                end

                if active and hovered and not (n == self.dragged_action) then
                    entries[n]                   = entries[self.dragged_action]
                    entries[self.dragged_action] = entry
                    self.dragged_action          = n
                end

                local inb, inv
                -- This should be done after the first column, because they need to have the same ID for the drag and drop to work
                ImGui.PushID(ctx, "action_entry_" .. n)

                ---------- COLUMN WHEN
                ImGui.TableNextColumn(ctx)
                self:actionWhenCombo(ctx, entry)

                ---------- COLUMN SECTION
                ImGui.TableNextColumn(ctx)
                self:actionSectionComboBox(ctx, entry)

                ---------- COLUMN ID
                ImGui.TableNextColumn(ctx)
                ImGui.SetNextItemWidth(ctx, 150)
                inb, inv = ImGui.InputText(ctx, '##action_id', '' .. entry.id)
                if inb then
                    entry.id = inv
                end

                ---------- COLUMN DESC
                ImGui.TableNextColumn(ctx)
                local text  = "?"
                local id    = reaper.NamedCommandLookup(entry.id)
                if id then text = reaper.kbd_getTextFromCmd(id, TabParams.ActionSection:entryByName(entry.section).v) end
                ImGui.Text(ctx, EllipsedText(ctx, text, 400))

                ---------- COLUMN DELETE
                ImGui.TableNextColumn(ctx)
                PushRedStyle(ctx)
                if ImGui.Button(ctx, "Del##del_" .. n) then
                    should_delete_entry = n
                end
                PopRedStyle(ctx)

                if not (n==#entries) then
                    ImGui.TableNextRow(ctx,ImGui.TableRowFlags_None)
                end
                ImGui.PopID(ctx)
            end

            if not has_active then
                self.dragged_action = nil
            end

            ImGui.EndTable(ctx)

            if should_delete_entry then
                table.remove(entries, should_delete_entry)
            end
        end

        PushCyanStyle(ctx)
        if ImGui.Button(ctx, " + ##add_new_entry") then
            entries[#entries+1] = {
                id      = 0,
                section = 'midi_editor',
                when    = 'after'
            }
        end
        PopCyanStyle(ctx)
    end

    ImGui.PopID(ctx)
end

function TabEditor:gfxPianoRollSection()

    local mec               = self.mec
    local tab               = self.tab
    local ctx               = MACCLContext.ImGuiContext
    local meinfo            = mec:editorInfo()
    local params            = tab.params.piano_roll
    local mode              = params.mode

    ImGui.BeginGroup(ctx)
    local headerw = 137
    if mode == 'custom' then headerw = 200 end
    if mode == 'fit' then headerw = 260 end
    ClippedSeparatorText(ctx, "Piano Roll", headerw)
    ImGui.PushID(ctx, "piano_roll_section")

    mode = self:gfxModeCombobox(ctx, "Mode", TabParams.PianoRollMode, params, true, nil, nil)

    if mode == 'custom' then
        if ImGui.BeginTable(ctx, '##conf', 4, ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg | ImGui.TableFlags_NoHostExtendX) then

            ImGui.TableSetupColumn(ctx, '',   ImGui.TableColumnFlags_WidthFixed,  0, 0)
            ImGui.TableSetupColumn(ctx, '',   ImGui.TableColumnFlags_WidthFixed,  0, 1)
            ImGui.TableSetupColumn(ctx, '',   ImGui.TableColumnFlags_WidthFixed,  0, 2)
            ImGui.TableSetupColumn(ctx, '',   ImGui.TableColumnFlags_WidthFixed,  0, 3)

            -- Using full syntax for table headers to allow tooltiping
            ImGui.PushTabStop(ctx, false)
            ImGui.TableNextColumn(ctx)
            MoveCursorY(ctx, 3)
            ImGui.TableHeader(ctx, 'High Note')
            TT(ctx, "Value of the highest MIDI Note of the Piano Roll");
            ImGui.PopTabStop(ctx)

            ImGui.TableNextColumn(ctx)
            ImGui.SetNextItemWidth(ctx, 50)

            local inb, inv = ImGui.InputText(ctx, '##high_note', "" .. params.high_note, ImGui.InputTextFlags_CharsDecimal)

            if inb then
                params.high_note = math.floor(tonumber(inv) or 0)
                if params.high_note < 0 then params.high_note = 0 end
                if params.high_note > 127 then params.high_note = 127 end
            end

            ImGui.TableNextColumn(ctx)
            ImGui.Text(ctx, MIDI.noteName(params.high_note))


            ImGui.TableNextColumn(ctx)
            ReadButton(ctx, "##get_high", function()
                tab:readCurrentPianoRollHighNote()
            end)

            ImGui.PushTabStop(ctx, false)
            ImGui.TableNextColumn(ctx)
            MoveCursorY(ctx, 3)
            ImGui.TableHeader(ctx, 'Low Note')
            TT(ctx, "Value of the lowest MIDI Note of the Piano Roll");
            ImGui.PopTabStop(ctx)

            ImGui.TableNextColumn(ctx)
            ImGui.SetNextItemWidth(ctx, 50)

            local inb, inv = ImGui.InputText(ctx, '##low_note', "" .. params.low_note, ImGui.InputTextFlags_CharsDecimal)
            if inb then
                params.low_note = math.floor(tonumber(inv) or 0)
                if params.low_note < 0 then params.low_note = 0 end
                if params.low_note > 127 then params.low_note = 127 end
            end

            ImGui.TableNextColumn(ctx)
            ImGui.SetNextItemWidth(ctx, 30)

            ImGui.Text(ctx, MIDI.noteName(params.low_note))

            ImGui.TableNextColumn(ctx)
            ReadButton(ctx, "##get_low", function()
                tab:readCurrentPianoRollLowNote()
            end)

            ImGui.EndTable(ctx)
        end
    elseif mode == 'fit' then
        ImGui.PushID(ctx, "fit_time_scope")
        self:gfxModeCombobox(ctx, "Time Scope ", TabParams.PianoRollFitTimeScope, params, true, 'fit_time_scope', 175)
        ImGui.PopID(ctx)

        ImGui.PushID(ctx, "fit_owner_scope")
        self:gfxModeCombobox(ctx, "Owner Scope", TabParams.PianoRollFitOwnerScope, params, true, 'fit_owner_scope', 175)
        ImGui.PopID(ctx)

        ImGui.PushID(ctx, "fit_chan_scope")
        self:fitChanScopeComboBox(ctx, params)
        ImGui.PopID(ctx)
    end

    ImGui.PopID(ctx)
    ImGui.EndGroup(ctx)
end

function TabEditor:gfxMidiChanSection()

    local mec               = self.mec
    local tab               = self.tab
    local ctx               = MACCLContext.ImGuiContext
    local meinfo            = mec:editorInfo()

    ImGui.PushID(ctx, "midi_chan_section")

    local params    = tab.params.midi_chans
    local mode      = params.mode

    self:currentChanComboBox(ctx, params)

    ImGui.SameLine(ctx)

    mode = self:gfxModeCombobox(ctx, "Active", TabParams.MidiChanMode, params, false)

    if mode == 'custom' then
        ImGui.PushStyleVar(ctx, ImGui.StyleVar_CellPadding, 1, 2)
        if ImGui.BeginTable(ctx, '##conf', 17, ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg | ImGui.TableFlags_NoHostExtendX) then

            for i=1, 16 do
                ImGui.TableSetupColumn(ctx, 'chan ' .. i , ImGui.TableColumnFlags_WidthFixed,  0, i-1)
            end
            ImGui.TableSetupColumn(ctx, 'read_col', ImGui.TableColumnFlags_WidthFixed,  0, 17)

            for i=1, 16 do
                -- Hugly hacks to have header label centered
                ImGui.TableNextColumn(ctx)
                ImGui.PushTabStop(ctx, false)
                local xx = ImGui.GetCursorPosX(ctx)
                local yy = ImGui.GetCursorPosY(ctx)
                ImGui.TableHeader(ctx, '')
                ImGui.SameLine(ctx,0)
                ImGui.Dummy(ctx,0,19)
                ImGui.SameLine(ctx,0)
                local htxt = "" .. i
                local ww, hh = ImGui.CalcTextSize(ctx, htxt)
                ImGui.SetCursorPosX(ctx, xx + (20 - ww)/2 )
                ImGui.SetCursorPosY(ctx, yy + (19 - hh)/2 )
                ImGui.Text(ctx, htxt)
                ImGui.PopTabStop(ctx)
            end
            --
            ImGui.TableNextColumn(ctx)
            ImGui.TableHeader(ctx, '')

            for i=1, 16 do
                ImGui.TableNextColumn(ctx)
                local v, b = ImGui.Checkbox(ctx, '##' .. 'cb_chan' ..i, (params.bits & (1 << (i-1)) ~= 0))
                if v then
                    -- Set the bit
                    params.bits = params.bits | (1 << (i-1))
                    if not b then
                        -- Clear the bit
                        params.bits = params.bits & (~(1 << (i-1)))
                    end
                end
            end

            ImGui.TableNextColumn(ctx)
            ReadButton(ctx, "##read_midi_chans_button", function()
                tab:readMidiChans()
            end)

            ImGui.EndTable(ctx)
        end
        ImGui.PopStyleVar(ctx)
    end

    ImGui.PopID(ctx)
end

function TabEditor:gfxTimeLineSection()
    local mec       = self.mec
    local ctx       = MACCLContext.ImGuiContext
    local tab       = self.tab
    local sparams   = tab.params.time_window
    local b,v

    ImGui.PushID(ctx, "timeline_tab_params")

    ImGui.BeginGroup(ctx)
    ImGui.PushID(ctx, "timeline_position")
    if true then
        local params = sparams.positioning
        ClippedSeparatorText(ctx, "Time position",140)

        self:gfxModeCombobox(ctx, "Mode", TabParams.TimeWindowPosMode, params, true, nil, nil)
        if params.mode == 'custom' then
            self:comboLeftLabel(ctx, "Time", true)
            ImGui.SetNextItemWidth(ctx, 80)
            b, v = ImGui.InputText(ctx, "", params.position or '')
            if b then
                params.position = v
            end
            local respos = reaper.parse_timestr_pos(params.position, -1)
            TT(ctx, "Enter a time position using Reaper's format.\n\z
                     This may be expressed:\n\n   - in measures :    M.B.fraction\n   - as a time :      [hh:mm]:ss\n\nCurrently resolved as :\n\n   " .. respos .. " seconds" )
        end
    end
    ImGui.PopID(ctx)
    ImGui.EndGroup(ctx)

    ImGui.SameLine(ctx)

    ImGui.BeginGroup(ctx)
    ImGui.PushID(ctx, "timeline_window")
    if true then
        local params = sparams.sizing

        local hsize = (sparams.positioning.mode == 'bypass' and sparams.sizing.mode == 'bypass') and (-1) or (155)
        ClippedSeparatorText(ctx, "Time window size", hsize)

        self:gfxModeCombobox(ctx, "Mode", TabParams.TimeWindowSizingMode, params, true, nil, nil)
        if params.mode == 'custom' then
            self:comboLeftLabel(ctx, "Duration", true)
            ImGui.SetNextItemWidth(ctx, 50)
            b, v = ImGui.InputText(ctx, "", params.size or '')
            if b then
                params.size = v
            end

            local offset = 0.0
            if sparams.positioning.mode == 'custom' then
                offset = reaper.parse_timestr_pos(sparams.positioning.position, -1)
            else
                local start_time, _ = TIMELINE.GetBounds(mec.me)
                offset = start_time or 0
            end

            local respos = reaper.parse_timestr_len(params.size, offset, -1)
            TT(ctx, "Enter a duration using Reaper's format.\n\z
            This may be expressed:\n\n   - in measures :    M.B.fraction\n   - as a time :      [hh:mm]:ss\n\nCurrently resolved as :\n\n   " .. respos .. " seconds, using offset : " .. offset .. " seconds" )
        end
    end
    ImGui.PopID(ctx)
    ImGui.EndGroup(ctx)

    if sparams.positioning.mode == 'custom' or sparams.sizing.mode == 'custom' then
        ImGui.SameLine(ctx)
        ImGui.BeginGroup(ctx)
        ImGui.PushID(ctx, "timeline_anchoring")
        if true then
            ImGui.SeparatorText(ctx, "Time ref")
            self:comboLeftLabel(ctx, "Anchor", true)
            self:genericEnumComboBox(ctx, sparams.positioning, 'anchoring', TabParams.TimeWindowAnchoring, 'anchoring', 70)
        end
        ImGui.PopID(ctx)
        ImGui.EndGroup(ctx)
    end

    ImGui.PopID(ctx)
end

function TabEditor:gfxFirstLine()
    local ctx               = MACCLContext.ImGuiContext

    ImGui.PushID(ctx, "generic_tab_params")

    ImGui.BeginGroup(ctx)
    if true then -- for indentation & readability
        self:comboLeftLabel(ctx, "Name", true)

        ImGui.SetNextItemWidth(ctx, 150)
        _, self.tab.params.title = ImGui.InputText(ctx, "##te_name", self.tab.params.title)
        TT(ctx, "This is what appears on the tab. You can also use the name to call this tab with an action 'by name'.")

        if self.draw_count <= 1 then
            -- On first draw, focus the tab name
            ImGui.SetItemDefaultFocus(ctx)
            ImGui.SetKeyboardFocusHere(ctx, -1)
        end

        if self.draw_count == 2 then
            ImGui.SetWindowFocus(ctx)
        end

        if ImGui.IsItemFocused(ctx) then
            if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) then
                ImGui.SetKeyboardFocusHere(ctx, 0)
            end
        end

        ImGui.Dummy(ctx, 1, 1)

        self:comboLeftLabel(ctx, "Role", false)
        ImGui.SetNextItemWidth(ctx, 150)
        _, self.tab.params.role = ImGui.InputText(ctx, "##te_role", self.tab.params.role)
        TT(ctx, "Enter a role here if you want to be able to call this tab with an action 'by role'.\n\nUseful if you want to have a similar behaviour across different tracks\nhaving the same 'role' but differing configs. They will be unified under the same 'role'\nand callable with the same shortcut, but you're still free to use different names.")
    end
    ImGui.EndGroup(ctx)

    ImGui.SameLine(ctx)

    ImGui.BeginGroup(ctx)
    if true then -- for indentation & readability
        ImGui.PushID(ctx, "color_mode")
        ImGui.SetNextItemWidth(ctx, 50)
        local cparams = self.tab.params.color
        self:gfxModeCombobox(ctx, "Color ", TabParams.ColorMode, cparams, false)
        if cparams.mode == 'overload' then
            ImGui.SameLine(ctx); MoveCursorY(ctx, -3)
            local b, v = ImGui.ColorEdit3(ctx, '', cparams.color, ImGui.ColorEditFlags_NoInputs)
            if b then
                cparams.color = v
            end
        end
        ImGui.PopID(ctx)

        ImGui.Dummy(ctx, 1, 1)

        ImGui.PushID(ctx, "margin_mode")
        ImGui.SetNextItemWidth(ctx, 50)
        local mparams = self.tab.params.margin
        self:gfxModeCombobox(ctx, "Margin", TabParams.MarginMode, mparams, false)
        if mparams.mode == 'overload' then
            ImGui.SetNextItemWidth(ctx, 30)
            ImGui.SameLine(ctx); MoveCursorY(ctx, -3)
            local b, v = ImGui.InputText(ctx, "##margin", "" .. (mparams.margin), ImGui.InputTextFlags_CharsDecimal)
            if b then
                mparams.margin = tonumber(v) or 0
            end
        end
        ImGui.PopID(ctx)
    end
    ImGui.EndGroup(ctx)

    ImGui.SameLine(ctx)

    ImGui.BeginGroup(ctx)
    if true then -- for indentation &
        self:comboLeftLabel(ctx, "Priority", false)
        ImGui.SetNextItemWidth(ctx, 50)
        local b, v = ImGui.InputText(ctx, "##te_prio", "" .. (self.tab.params.priority), ImGui.InputTextFlags_CharsDecimal)
        if b then
            self.tab.params.priority = tonumber(v) or 0
        end
    end
    ImGui.EndGroup(ctx)

    ImGui.PopID(ctx)
end

function TabEditor:gfxOtherParamsSection()
    local mec       = self.mec
    local ctx       = MACCLContext.ImGuiContext
    local b, v

    ImGui.PushID(ctx, "other_params_section")

    ImGui.BeginGroup(ctx)
    if true then
        ImGui.PushID(ctx, "coloring_params")

        local cparams = self.tab.params.coloring
        ClippedSeparatorText(ctx, "Coloring", cparams.mode == 'custom' and 165 or 140)
        self:gfxModeCombobox(ctx, 'Mode', TabParams.MEColoringMode, cparams, true, "mode", 100)

        if cparams.mode == 'custom' then
            self:comboLeftLabel(ctx, 'Type', true)
            self:genericEnumComboBox(ctx, cparams, "type", TabParams.MEColoringType, "##coloring_type", 100)

            ImGui.SameLine(ctx); MoveCursorY(ctx, -3)
            ReadButton(ctx, '##R', function()
                if not mec.take then return end

                cparams.type = GRID.GetColoringType(mec)
            end)
        end
        ImGui.PopID(ctx)
    end
    ImGui.EndGroup(ctx)

    ImGui.SameLine(ctx)

    ImGui.BeginGroup(ctx)
    if true then
        ImGui.PushID(ctx, "grid_params")
        local cparams   = self.tab.params.grid
        ClippedSeparatorText(ctx, "Grid", -1)
        self:gfxModeCombobox(ctx, 'Mode', TabParams.GridMode, cparams, true, "mode", 100)
        if cparams.mode == 'custom' then
            self:comboLeftLabel(ctx, 'Val ', true)
            ImGui.SetNextItemWidth(ctx, 70)
            b, v = ImGui.InputText(ctx, '##gridval', cparams.val)
            if b then
                cparams.val = v
            end

            TT(ctx, "Enter a fraction or a floating number.\n\z
                        This is the fraction of a whole used as the base for the grid.\n\z
                        \n\z
                        Currently resolved as : " .. GRID.ToString(GRID.FromString(cparams.val)))

            ----------

            ImGui.SameLine(ctx)
            self:comboLeftLabel(ctx, 'Type', false)
            ImGui.SameLine(ctx)
            MoveCursorY(ctx, -3)
            self:genericEnumComboBox(ctx, cparams, 'type', TabParams.GridType, '##grid_type', 80)

            -------------

            if cparams.type == "swing" then
                ImGui.SameLine(ctx); MoveCursorY(ctx, -3)
                ImGui.SetNextItemWidth(ctx, 70)
                b, v = ImGui.SliderInt(ctx, '##swingval', cparams.swing, -100, 100)
                if b then
                    cparams.swing = v
                end
                if ImGui.IsItemClicked(ctx, ImGui.MouseButton_Right) then
                    cparams.swing = 0
                end

                TT(ctx, "" .. cparams.swing)
            end

            ImGui.SameLine(ctx); MoveCursorY(ctx, -3)
            ReadButton(ctx, '##R', function()
                if not mec.take then return end

                local val, type, swing = GRID.GetMIDIEditorGrid(mec)

                local p, q, err = GRID.ToFrac(val)
                local str = "" .. p .. "/" .. q
                if q == 1 then str = "" .. p end

                cparams.val      = str
                cparams.type     = type
                cparams.swing    = math.floor(swing * 100)
            end)
        end
        ImGui.PopID(ctx)
    end
    ImGui.EndGroup(ctx)

    ImGui.PopID(ctx)
end


function TabEditor:gfx()

    local ctx           = MACCLContext.ImGuiContext

    if not ctx then return end -- Ouch

    local mec           = self.mec
    local tab           = self.tab -- Shortcut
    local uuid          = tab:UUID()
    local is_new_record = tab.new_record -- Use this denormalize flag in the context of the function as it can change on save

    if not uuid then
        error("Developer error. Using a tab editor on a tab without a UUID")
    end

    if not self.draw_count then
        self.draw_count = 0
        -- We need to convert global screen coordinates to ImGui's system (because natively, they can be flipped on macos)
        local imx, imy = ImGui.PointConvertNative(ctx, self.tab.last_draw_global_x, self.tab.last_draw_global_y)
        ImGui.SetNextWindowPos(ctx, imx, imy - 5, 0, 0, 1) -- Bottom left corner of the window aligned on top left corner of the tab
    else
        self.draw_count = self.draw_count + 1
    end

    -- Flags : never save the window settings in the ini file. Since the title is dependent of the UUID, this would totally spam it
    ImGui.PushID(ctx, "tab_editor_" .. uuid)

    local title = (is_new_record and 'Creating tab : ' or 'Editing tab : ')
    title = title .. self.tab.params.title .. '###te_window' .. uuid

    --
    local visible, open = ImGui.Begin(ctx, title, true, ImGui.WindowFlags_AlwaysAutoResize | ImGui.WindowFlags_NoSavedSettings | ImGui.WindowFlags_NoDocking)

    if visible then

        self:gfxFirstLine()

        self:gfxOwnerSection()
        self:gfxDockingSection()
        self:gfxTimeLineSection()
        self:gfxCCLaneSection()
        self:gfxPianoRollSection()
        ImGui.SameLine(ctx, 0)
        ImGui.BeginGroup(ctx)
        ImGui.SeparatorText(ctx, "MIDI Channels")
        self:gfxMidiChanSection()
        ImGui.EndGroup(ctx)

        self:gfxOtherParamsSection()

        self:gfxActionSection()

        ImGui.SeparatorText(ctx, '')

        PushGreenStyle(ctx)
        if ImGui.Button(ctx, "Save") then
            self.tab:save()
            open = false -- Get rid of it, we won't redraw, so it will be garbage collected
        end
        PopGreenStyle(ctx)

        ImGui.SameLine(ctx)

        PushRedStyle(ctx)
        if not is_new_record then
            local now = reaper.time_precise()
            if not self.confirm_timeout or self.confirm_timeout < now then
                ImGui.SameLine(ctx, ImGui.GetWindowWidth(ctx) - 58)
                if ImGui.Button(ctx, "Delete") then
                    self.confirm_timeout = now + 3
                end
            else
                ImGui.SameLine(ctx, ImGui.GetWindowWidth(ctx) - 93)
                if ImGui.Button(ctx, "Confirm (" .. math.ceil(self.confirm_timeout - now - 0.0001) .. ")") then
                    open = false -- Get rid of it, we won't redraw, so it will be garbage collected
                    self.tab:destroy()
                end
            end
        end
        PopRedStyle(ctx)

        self:gfxAutoMove()

        ImGui.End(ctx)
    end
    ImGui.PopID(ctx)

    if not open then
        -- Remove from manager
        TabEditor.registry[self.tab:UUID()] = nil
    end
end

-- Class functions

function TabEditor.openOnTab(mec, tab)
    local editor = TabEditor.registry[tab:UUID()]
    if editor then return editor end

    editor = TabEditor:new(mec, tab)
    TabEditor.registry[tab:UUID()] = editor
end

function TabEditor.processAll()
    for uuid, editor in pairs(TabEditor.registry) do
        editor:gfx()
    end
end

function TabEditor.needsImGuiContext()
    -- Need a context if a at least one editor
    for uuid, editor in pairs(TabEditor.registry) do
        return true
    end
    return false
end

function TabEditor.hasEditorForNewTabOpen(mec)
    for uuid, editor in pairs(TabEditor.registry) do
        if editor.tab.new_record and editor.mec == mec then
            return true, editor
        end
    end
    return false, nil
end

return TabEditor

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local S               = require "modules/settings"
local D               = require "modules/defines"

local UTILS           = require "modules/utils"
local MACCLContext    = require "modules/context"

local TabState        = require "modules/tab_state"

local MOD             = require "modules/modifiers"

local Tab = {}
Tab.__index = Tab

Tab.Types = {
    TRACK     = "track",
    ITEM      = "item",
    PROJECT   = "project",
    GLOBAL    = "global",
    PLUS_TAB  = "__add_tab__"
}

function Tab:new(mec, owner, params, state)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(mec, owner, params, state)
    return instance
end

function Tab:_initialize(mec, owner, params, state)
    if not mec then error("Developer error ! Creating tab without a ME context") end

    self.mec = mec

    self:setOwner(owner)

    -- Ensure that we don't go gardening into someone else's territory
    params              = UTILS.deepcopy(params)
    state               = UTILS.deepcopy(state)

    self.new_record     = true
    self.uuid           = UTILS.drawUUID()
    self.params         = params or { title = "New Tab" }
    self.state          = state or {}

    self:_sanitize()

    self:undirty()
end

function Tab:clone(keep_uuid)
    local t = Tab:new(self.mec, self.owner, self.params, self.state)

    t.last_draw_global_x = self.last_draw_global_x
    t.last_draw_global_y = self.last_draw_global_y

    if keep_uuid then
        t.uuid = self.uuid
    end
    return t
end

-- Make sure a tab is initialized correctly
-- This function is always call when creating a new tab
-- Or loading it from a serialized description
-- So all backward compatibility should be handled here
-- As well as default value assignments
function Tab:_sanitize()
    TabState.Sanitize(self)
end

function Tab:hasOneSubmoduleInRecordMode()
    return (self.params.grid.mode == 'record') or
        (self.params.docking.mode == 'record') or
            (self.params.docking.if_docked.mode == 'record') or
            (self.params.docking.if_windowed.mode == 'record') or
        (self.params.time_window.positioning.mode == 'record') or
        (self.params.time_window.sizing.mode == 'record') or
        (self.params.cc_lanes.mode == 'record') or
        (self.params.piano_roll.mode == 'record') or
        (self.params.midi_chans.mode == 'record') or
        (self.params.coloring.mode == 'record') or
        (self.params.midi_chans.current == 'record')
end

function Tab:resolveStateFull()
    self.is_statefull = self:hasOneSubmoduleInRecordMode() or (self.params.force_record_flag == 1)
end

-- Mark the record as non dirty
-- Used after save to acknowledge pending states as real states
function Tab:undirty()
    self.owner_before_save      = self.owner
    self.owner_type_before_save = self.owner_type

    -- Denormalize some states
    self:resolveStateFull()
end

function Tab:UUID()
    return self.uuid
end

function Tab:callableByAction()
    return true
end

function Tab:deletable()
    return true
end

function Tab:exportable()
    return true
end

function Tab:setOwner(entity)
    if (entity == nil) or (entity == 0) then
        self.owner      = nil
        self.owner_type = Tab.Types.PROJECT
    elseif reaper.ValidatePtr(entity, "MediaItem*") then
        self.owner      = entity
        self.owner_type = Tab.Types.ITEM
    elseif reaper.ValidatePtr(entity, 'MediaTrack*') then
        self.owner      = entity
        self.owner_type = Tab.Types.TRACK
    elseif entity.isGlobalScopeRepo and entity:isGlobalScopeRepo() then
        self.owner      = entity
        self.owner_type = Tab.Types.GLOBAL
    else
        error("Trying to set wrong owner to tab")
    end
end

function Tab:isOwnerStillValid()
    if self.owner_type == Tab.Types.GLOBAL  then return true end
    if self.owner_type == Tab.Types.PROJECT then return true end
    if self.owner_type == Tab.Types.ITEM    then return reaper.ValidatePtr(self.owner, "MediaItem*") end
    if self.owner_type == Tab.Types.TRACK   then return reaper.ValidatePtr(self.owner, "MediaTrack*") end

    return false
end

function Tab:ownerInfo()

    if self.owner_type == Tab.Types.PROJECT then
        return {
            type = self.owner_type,
            desc = "Project"
        }
    elseif self.owner_type == Tab.Types.GLOBAL then
        return {
            type = self.owner_type,
            desc = "Global"
        }
    elseif self.owner_type == Tab.Types.ITEM    then
        local track = reaper.GetMediaItemTrack(self.owner)
        local _, tname = reaper.GetTrackName(track)
        -- TODO : Items don't have names !
        return {
            type = self.owner_type,
            desc = "Project > Track " .. tname .. " > Item"
        }
    elseif self.owner_type == Tab.Types.TRACK   then
        local track     = self.owner
        local _, tname  = reaper.GetTrackName(track)
        return {
            type = self.owner_type,
            desc = "Project > Track " .. tname
        }
    end

    return nil
end

function Tab:afterSave(options)
    options = options or {}

    local was_new = self.new_record

    self.new_record              = false
    self:undirty()

    -- mec should be passed as option since the mec is only set on first draw ...
    -- That's a bit dirty
    if was_new then
        self.mec:onStateFullTabActivation(self, {force_reload=true})
    end
    -- We need this option to avoid race conditions
    if not options.skip_full_tab_reload then
        MACCLContext.lastTabSavedAt  = reaper.time_precise()
    end
end

function Tab:removeFromOwner(owner_type, owner)
    local all_owner_tabs = Serializing.loadTabsFromEntity(self.mec, owner_type, owner)
    all_owner_tabs[self:UUID()] = nil
    Serializing.saveTabsToEntitity(owner_type, owner, all_owner_tabs)
end

function Tab:isStateFull()
    if self.is_statefull == nil then
        self:resolveStateFull()
    end
    return self.is_statefull
end

function Tab:isActive()
    return (self.active == true)
end

function Tab:save(options)
    -- Maybe we should do more than fail silently
    if not self:isOwnerStillValid() then return { success=false, errors={"Tab's owner is not valid anymore"}} end

    -- TODO : Validate ?

    -- If owner is changing, it should be removed from precedent owner !
    if not (self.owner_before_save == self.owner) then
        self:removeFromOwner(self.owner_type_before_save, self.owner_before_save)
    end

    -- Needs to be refreshed and up to date for next condition evaluation
    self:resolveStateFull()

    -- Before first save, snapshot
    if self:isStateFull() and (self.new_record or self:isActive()) then
        TabState.SnapShotAll(self)
    end

    -- Perform read/modify/write on owner
    local all_owner_tabs                = Serializing.loadTabsFromEntity(self.mec, self.owner_type, self.owner)
    all_owner_tabs[self:UUID()]         = { uuid=self:UUID(), params=self.params, state=self.state }
    Serializing.saveTabsToEntitity(self.owner_type, self.owner, all_owner_tabs)

    self:afterSave(options)

    return { success=true, errors={} }
end

function Tab:destroy()
    -- Maybe we should do more than fail silently
    if not self:isOwnerStillValid() then return { success=false, errors={"Tab's owner does not valid anymore"}} end

    local all_owner_tabs = Serializing.loadTabsFromEntity(self.mec, self.owner_type, self.owner)
    all_owner_tabs[self:UUID()] = nil
    Serializing.saveTabsToEntitity(self.owner_type, self.owner, all_owner_tabs)

    self:afterSave()

    return { success=true, errors={} }
end

function Tab:duplicate()
    local tab = self
    local newtab    = Tab:new(tab.mec, tab.owner, tab.params, tab.state)
    local name      = newtab.params.title

    local s,f = name:match("(.*)(%d+)$")
    if not s then
        s = name .. " "
        f = 1
    else
        f = tonumber(f)
    end
    while true do
        f = f + 1
        local t = tab.mec:findTabByName(s .. f)
        if not t then break end
    end

    newtab.params.title         = s .. f
    newtab.last_draw_global_x   = tab.last_draw_global_x
    newtab.last_draw_global_y   = tab.last_draw_global_y
    newtab:save()
end

function Tab:textWidth()
    -- Memoize the tab width to avoid recaclulations
    if not (self._last_text_for_metrics) or not (self._last_text_for_metrics == self.params.title) then
        -- Could observe the same bug as FTC in lilchordbox with JS_LICE_MeasureText
        -- Thanks @FeedTheCat for the workaround

        self._last_text_for_metrics = self.params.title

        local use_gfx = true
        if use_gfx then
            -- gfx.setfont(1, MACCLContext.FONT_FACE, MACCLContext.FONT_SIZE)
            self._precalc_text_width = gfx.measurestr(self._last_text_for_metrics)
        else
            local tw, th  = reaper.JS_LICE_MeasureText(self._last_text_for_metrics)
            self._precalc_text_width = tw
        end
    end

    return self._precalc_text_width
end

function Tab:width()
    local margin = S.getSetting("TabMargin")
    if self.params.margin.mode == 'overload' then
        margin = self.params.margin.margin
    end
    return 2 * margin + self:textWidth()
end

function Tab:height()
    return MACCLContext.TABBAR_HEIGHT
end

function Tab:textHeight()
    local fs = S.getSetting("FontSize")
    if     fs == 8  then return 10
    elseif fs == 9  then return 11
    elseif fs == 10 then return 13
    elseif fs == 11 then return 13
    elseif fs == 12 then return 14
    elseif fs == 13 then return 15
    elseif fs == 14 then return 17
    end
end

function Tab:luma(col)
    return  0.299 * ((col & 0x00FF0000) >> 16) +
            0.587 * ((col & 0x0000FF00) >> 8) +
            0.114 * ((col & 0x000000FF))
end

function Tab:colors(mec, is_hovered, is_active)

    -- sanim goes from 0 to 1
    local sanim = 0
    if self.highlight_until then
        local xanim = (reaper.time_precise() - self.last_clicked_at) / (self.highlight_until - self.last_clicked_at)
        if xanim > 1 then xanim = 1 end
        sanim = 0.5 * (1 + math.sin(4 * math.pi * xanim - math.pi / 2))
    end

    local alpha = 0.5

    if is_active then
        alpha = 0.9
    end

    if is_hovered then alpha = 1.0 end
    alpha = alpha + (sanim * 0.5)

    if alpha > 1 then alpha = 1 end

    local tab_type  = self.owner_type
    local tabcol    = 0xFFFFFFFF -- reaper.GetThemeColor("docker_unselface") | 0xFF000000

    if self.params.color.mode == 'overload' then
        tabcol = self.params.color.color | 0xFF000000
    else
        if tab_type == Tab.Types.TRACK then
            local  take = reaper.MIDIEditor_GetTake(mec.me)
            if take then
                local track   = reaper.GetMediaItemTake_Track(take)
                local natcol  = reaper.GetTrackColor(track)
                local r,g,b   = reaper.ColorFromNative(natcol)
                tabcol = 0xFF000000 | (r << 16) | (g << 8) | b
            end
        elseif tab_type == Tab.Types.ITEM then
            local  take = reaper.MIDIEditor_GetTake(mec.me)
            if take then
                local item    = reaper.GetMediaItemTake_Item(take)
                local natcol  = reaper.GetMediaItemInfo_Value(item, "I_CUSTOMCOLOR")
                local r,g,b   = reaper.ColorFromNative(natcol)
                tabcol = 0xFF000000 | (r << 16) | (g << 8) | b
            end
        elseif tab_type == Tab.Types.GLOBAL then
            tabcol = S.getSetting("ColorForGlobalTabs") | 0xFF000000
        elseif tab_type == Tab.Types.PROJECT then
            tabcol = S.getSetting("ColorForProjectTabs") | 0xFF000000
        elseif tab_type == Tab.Types.PLUS_TAB then
            tabcol = 0xFFFFFFFF
        else
            -- Project or __special__
        end
    end

    local luma   = self:luma(tabcol)

    local fontcol       = (luma > 127) and 0xFF000000 or 0xFFFFFFFF
    local fontcol_inv   = (luma > 127) and 0xFFFFFFFF or 0xFF000000

    return tabcol, alpha, fontcol, fontcol_inv
end

function Tab:isRound()
    return false
end

function Tab:pointIntab(_x, _y)
    local mec = self.mec

    if not mec          then return false end
    if not self.last_x  then return false end
    if not self.last_y  then return false end
    if not mec.xpos     then return false end

    local xinwin = self.last_x + mec.xpos
    local yinwin = self.last_y + mec.ypos

    local fullh   = self:height()
    local fullw   = self:width()

    _x = _x + mec.scrollOffset

    return (_x >= xinwin) and
    (_x <= xinwin + fullw - 1) and
    (_y >= yinwin) and
    (_y <= yinwin + fullh - 1)
end

function Tab:update(mec, x)
    self.mec      = mec
    self.last_x   = x
    self.last_y   = 0

    self.fullh   = self:height()
    self.fullw   = self:width()
end

function Tab:fillTriangle(color, alpha, crop, which_one)

    local mec     = self.mec
    local fullw   = self.fullw
    local fullh   = self.fullh

    if which_one == 4 then -- BOTTOM LEFT
        reaper.JS_LICE_FillTriangle(mec.bitmap,
            self.last_x         , self.last_y + fullh - 1,
            self.last_x + crop  , self.last_y + fullh - 1,
            self.last_x         , self.last_y + fullh - crop -1,
            color, alpha, "COPY")
    elseif which_one == 1 then -- TOP LEFT
        reaper.JS_LICE_FillTriangle(mec.bitmap,
            self.last_x         , self.last_y,
            self.last_x + crop  , self.last_y,
            self.last_x         , self.last_y + crop,
            color, alpha, "COPY")
    elseif which_one == 2 then -- TOP RIGHT
        reaper.JS_LICE_FillTriangle(mec.bitmap,
            self.last_x + fullw - 1 - crop  , self.last_y,
            self.last_x + fullw - 1         , self.last_y,
            self.last_x + fullw - 1         , self.last_y + crop,
            color, alpha, "COPY")
    elseif which_one == 3 then -- BOTTOM RIGHT
        reaper.JS_LICE_FillTriangle(mec.bitmap,
            self.last_x + fullw - 1 - crop  , self.last_y + fullh - 1,
            self.last_x + fullw - 1         , self.last_y + fullh - 1,
            self.last_x + fullw - 1         , self.last_y + fullh - crop - 1,
            color, alpha, "COPY")
    end
end

function Tab:drawRect(color, x, y, w, h)
    local mec     = self.mec

    reaper.JS_LICE_Line(mec.bitmap, x,          y,          x + w - 1,  y,          color, 1, "COPY", false)
    reaper.JS_LICE_Line(mec.bitmap, x + w - 1,  y,          x + w - 1,  y + h - 1,  color, 1, "COPY", false)
    reaper.JS_LICE_Line(mec.bitmap, x + w - 1,  y + h - 1,  x,          y + h - 1,  color, 1, "COPY", false)
    reaper.JS_LICE_Line(mec.bitmap, x,          y + h - 1,  x,          y,          color, 1, "COPY", false)
end

function Tab:draw(mec, x)
    self:update(mec, x)

    local mec     = self.mec
    local text    = self.params.title

    local th      = self:textHeight()
    local tw      = self:textWidth()

    local fullw   = self.fullw
    local fullh   = self.fullh

    -- Position for drawing text
    local tx, ty  = self.last_x + math.floor(0.5 * (fullw - tw)), math.floor( (fullh - th) * 0.5 + 0.5)

    local tlen    = #text
    local font    = MACCLContext.LiceFont()
    if not font then error("Deveoper error : no font here !!") end

    self.last_draw_global_x, self.last_draw_global_y = reaper.JS_Window_ClientToScreen(mec.me, self.last_x + mec.xpos - mec.scrollOffset, self.last_y + mec.ypos)

    local is_hovering             = self:pointIntab(mec.mouse_x, mec.mouse_y)
    local is_active               = self:isActive()

    local tabcol, alpha, fontcol, fontcol_inv  = self:colors(mec, is_hovering, is_active)

    if self:isRound() then
        local rad = math.floor(fullw/2)
        reaper.JS_LICE_FillCircle(mec.bitmap, self.last_x + rad,  self.last_y + rad,  rad - 2, tabcol, alpha, "COPY", false)
    else
        reaper.JS_LICE_FillRect(mec.bitmap,   self.last_x,        self.last_y,        fullw, fullh, tabcol, alpha, "COPY")
    end

    if self:isStateFull() then
        local crop          = S.getSetting("RecTabIndicatorSize")

        local set           = S.getSetting("ActiveRecTabIndicatorColor")
        local alpha         = (set & 0xFF)
        local rgb           = (set >> 8)
        local active_col    = rgb | (alpha << 24)

        local set           = S.getSetting("InactiveRecTabIndicatorColor")
        local alpha         = (set & 0xFF)
        local rgb           = (set >> 8)
        local inactive_col  = rgb | (alpha << 24)

        if self:isActive() then
            self:drawRect(active_col, self.last_x, self.last_y, fullw, fullh)
        end

        self:fillTriangle(mec.bgcol, 1, crop+2, 1) -- mec.bgcol

        if self:isActive() then
            reaper.JS_LICE_Line(mec.bitmap, self.last_x, self.last_y + crop + 3, self.last_x + crop + 3,  self.last_y, active_col, 1, "COPY", false)
            self:fillTriangle(active_col, 1, crop, 1)
        else
            self:fillTriangle(inactive_col, 1, crop, 1)
        end
    end

    -- Font color
    reaper.JS_LICE_SetFontColor(font, fontcol)

    -- It looks like rawtext needs a bit more latitude than what is given ... empiric values for w/h
    reaper.JS_LICE_DrawText(mec.bitmap, font, text, tlen , tx, ty, tx+tw+5, ty+th*2)


    local is_duplicate_candidate    = (is_hovering and self:deletable() and MOD.WinControlMacCmdIsDown())
    local is_delete_candidate       = (is_hovering and self:deletable() and MOD.ShiftIsDown())

    if is_delete_candidate then
        self:drawRect(0xFF000000 | 0xFF0000, self.last_x, self.last_y, fullw, fullh)
        self:drawRect(0xFF000000 | 0xFF0000, self.last_x+1, self.last_y+1, fullw-2, fullh-2)
        self:drawRect(0xFF000000 | 0x000000, self.last_x+2, self.last_y+2, fullw-4, fullh-4)
    elseif is_duplicate_candidate then
        self:drawRect(0xFF000000 | 0x00FF00, self.last_x, self.last_y, fullw, fullh)
        self:drawRect(0xFF000000 | 0x00FF00, self.last_x+1, self.last_y+1, fullw-2, fullh-2)
        self:drawRect(0xFF000000 | 0x000000, self.last_x+2, self.last_y+2, fullw-4, fullh-4)
    end

    if self.highlight_until and self.highlight_until < reaper.time_precise() then
        self.highlight_until = nil
    end

    -- Handle left click
    local pc = mec.pending_left_click
    if pc and self:pointIntab(mec.pending_left_click.x, mec.pending_left_click.y) then
        pc.handled = true
        self:onLeftClick(mec, {delete=is_delete_candidate, duplicate=is_duplicate_candidate})
    end

    -- Handle right click
    local prc = mec.pending_right_click
    if prc and self:pointIntab(mec.pending_right_click.x, mec.pending_right_click.y) then
        prc.handled = true
        self:onRightClick(mec, mec.pending_right_click.x, mec.pending_right_click.y)
    end

    return fullw
end

function Tab:_executeActions(when)
    local mec = self.mec
    for _, entry in ipairs(self.params.actions.entries) do
        if entry.when == when then
            local id    = reaper.NamedCommandLookup(entry.id)
            if id then
                if entry.section == 'main' then
                    reaper.Main_OnCommand(id, 0)
                else
                    reaper.MIDIEditor_OnCommand(mec.me, id)
                end
            end
        end
    end
end

function Tab:_protectedLeftClick(mec, click_params)
    click_params = click_params or {}

    if click_params.highlight then
        self.highlight_until = reaper.time_precise() + click_params.highlight
    end
    self.last_clicked_at = reaper.time_precise()

    -- Start by executing pre-actions
    if self.params.actions.mode == 'custom' then
        self:_executeActions('before')
    end

    -- Order is important
    TabState.ApplyLayouting(self)
    TabState.ApplyTimeline(self)
    TabState.ApplyCCLanes(self)
    TabState.ApplyMidiChans(self)
    TabState.ApplyPianoRoll(self)
    TabState.ApplyGrid(self)
    TabState.ApplyColoring(self)

    -- Execute post-actions
    if self.params.actions.mode == 'custom' then
        self:_executeActions('after')
    end
end

function Tab:setActive(b)
    -- Prevent setting active non statefull tabs
    if b and not self:isStateFull() then b = false end

    self.active = b
end

function Tab:onLeftClick(mec, click_params)
    -- Don't remember why the next line ??
    if not mec.item then return end

    if click_params.delete then
        self:destroy()
    elseif click_params.duplicate then
        self:duplicate()
    else
        if self:isStateFull() then
            mec:onStateFullTabActivation(self)
        end

        local b, err = pcall(Tab._protectedLeftClick, self, mec, click_params)
        if not b then
            -- Unfortunately, pcall is not sufficient if the crash happens inside Main_OnCommand
            -- The problem is that subssequent calls to reaper.defer will fail, so afterwards
            -- MaCCLane will quit silently and I don't have a solution yet
            reaper.MB("Something nasty happend with this tab. Please check the console for more info", "Ouch !", 0)
            reaper.ShowConsoleMsg(err .. '\n\nTrace :\n\n' .. debug.traceback())
        end
    end
end

function Tab:onRightClick(mec, x, y)
    --  mec:openTabEditorOn(self)
    mec:openTabContextMenuOn(self)
end

function Tab:getActiveChanBits()
    local ACTION_TOGGLE_MIDI_CHAN = 40643
    local bits = 0
    for i=0, 15 do
        local res = reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, ACTION_TOGGLE_MIDI_CHAN + i) -- i starts at 0 so it's ok
        if res == 1 then                      -- Set the bit
            bits = bits | (1 << (i))
        end
    end

    -- Reaper does not allow to have zero active chans.
    if bits == 0 then
        bits = 0xFFFF
    end

    return bits
end

function Tab:setFullRecord()
    TabState.SetFullRecord(self)
end

----------------------

function Tab.ownerTypePriority(type)
    if type == Tab.Types.GLOBAL then
        return 0
    elseif type == Tab.Types.PROJECT then
        return 1
    elseif type == Tab.Types.TRACK then
        return 2
    elseif type == Tab.Types.ITEM then
        return 3
    else
        return 42
    end
end

function Tab.alphabeticalCompare(t1, t2)
    -- Alphabetically
    local n1 = t1.params.title:lower()
    local n2 = t2.params.title:lower()
    if n1 == n2 then return t1.uuid < t2.uuid end
    return n1 < n2
end

function Tab.sort_pti_prio(tabs)
    return table.sort(tabs, function(t1, t2)
        if t1.owner_type == t2.owner_type then
            if t1.params.priority == t2.params.priority then
                -- Alphabetically
                return Tab.alphabeticalCompare(t1, t2)
            else
                -- Priority
                return t1.params.priority < t2.params.priority
            end
        else
            -- Tab type
            return Tab.ownerTypePriority(t1.owner_type) < Tab.ownerTypePriority(t2.owner_type)
        end
    end)
end

function Tab.sort_pti_alpha(tabs)
    return table.sort(tabs, function(t1, t2)
        if t1.owner_type == t2.owner_type then
            if t1.params.title:lower() == t2.params.title:lower() then
                -- Priority
                return t1.params.priority < t2.params.priority
            else
                -- Alphabetically
                return Tab.alphabeticalCompare(t1, t2)
            end
        else
            -- Tab type
            return Tab.ownerTypePriority(t1.owner_type) < Tab.ownerTypePriority(t2.owner_type)
        end
    end)
end

function Tab.sort_mixed_prio(tabs)
    return table.sort(tabs, function(t1, t2)
        if t1.params.priority == t2.params.priority then
            -- Alphabetically
            return Tab.alphabeticalCompare(t1, t2)
        else
            -- Priority
            return t1.params.priority < t2.params.priority
        end
    end)
end

function Tab.sort_mixed_alpha(tabs)
    return table.sort(tabs, function(t1, t2)
        if t1.params.title:lower() == t2.params.title:lower() then
            -- Priority
            return t1.params.priority < t2.params.priority
        else
            -- Alphabetically
            return Tab.alphabeticalCompare(t1, t2)
        end
    end)
end


function Tab.sort(tabs)
    local strat = S.getSetting("SortStrategy")

    if strat == 'mixed_prio' then
        return Tab.sort_mixed_prio(tabs)
    elseif strat == 'mixed_alpha' then
        return Tab.sort_mixed_alpha(tabs)
    elseif strat == 'pti_alpha' then
        return Tab.sort_pti_alpha(tabs)
    elseif strat == 'pti_prio' then
        return Tab.sort_pti_prio(tabs)
    else
        -- Case default ???
        return Tab.sort_pti_prio(tabs)
    end

end

return Tab

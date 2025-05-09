-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local UTILS           = require "modules/utils"
local Serializing     = require "modules/serializing"

local MACCLContext    = require "modules/context"

local Tab             = require "classes/tab"
local AddTabTab       = require "classes/add_tab_tab"
local TabEditor       = require "classes/tab_editor"
local TabPopupMenu    = require "classes/tab_popup_menu"
local GlobalScopeRepo = require "classes/global_scope_repo"

local TabState        = require "modules/tab_state"

local MOD             = require "modules/modifiers"

local S               = require "modules/settings"
local D               = require "modules/defines"

local MaccLaneContextLookupPerME = {}

local MEContext     = {}
MEContext.__index   = MEContext

function MEContext:new(me)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(me)
    return instance
end

function MEContext:createBitmap(w,h)
    self.bitmap        = reaper.JS_LICE_CreateBitmap(true, w, h)
    self.db_bitmap     = reaper.JS_LICE_CreateBitmap(true, w, h)
end

function MEContext:resizeBitmap(w,h)
    if not self.bitmap then return end

    reaper.JS_LICE_Resize(self.bitmap, w, h)
    reaper.JS_LICE_Resize(self.db_bitmap, w, h)
end

function MEContext:destroyBitmap()
    if not self.bitmap then return end

    reaper.JS_LICE_DestroyBitmap(self.bitmap)
    reaper.JS_LICE_DestroyBitmap(self.db_bitmap)
end

function MEContext:_initialize(me)
    local address     = reaper.JS_Window_AddressFromHandle(me)
    local mec         = self

    mec.me            = me
    mec.address       = address

    mec.scrollOffset  = 0

    -- Precaculate the MIDI Editor bounds
    mec.mebounds      = UTILS.JS_Window_GetBounds(me)

    -- Color combo box
    mec.cbl           = reaper.JS_Window_FindChildByID(me, 1146)
    -- Track combobox
    mec.cbr           = reaper.JS_Window_FindChildByID(me, 1007)

    -- Use a width of 1. The bitmap will be resized before being used
    self:createBitmap(1, MACCLContext.TABBAR_HEIGHT)

    mec.mouse_x = -1
    mec.mouse_y = -1

    -- We need hover/click/scroll
    reaper.JS_WindowMessage_Intercept(me, "WM_LBUTTONUP",  false)
    reaper.JS_WindowMessage_Intercept(me, "WM_RBUTTONUP",  false)
    reaper.JS_WindowMessage_Intercept(me, "WM_MOUSEWHEEL", false)
    -- In case of failure because already interecepted force
    reaper.JS_WindowMessage_PassThrough(me, "WM_LBUTTONUP",  false)
    reaper.JS_WindowMessage_PassThrough(me, "WM_RBUTTONUP",  false)
    reaper.JS_WindowMessage_PassThrough(me, "WM_MOUSEWHEEL", false)

    -- Save mec in lookup
    MaccLaneContextLookupPerME[address]   = mec

    return mec
end

function MEContext:hasPendingMouseEvents()
    if self.pending_left_click   then return true end
    if self.pending_right_click  then return true end
    if self.pending_mouse_wheel  then return true end
    return false
end

function MEContext:hasPendingTabAnimations()
    local now  = nil
    local tabs = self:tabs()

    for _, tab in ipairs(tabs) do
        if tab.highlight_until then
            return true
        end
    end
    return false
end

function MEContext:hasPendingDrawOperations()
    if self.has_pending_redraw then
        return true
    end
    return self:hasPendingTabAnimations()
end

-- Returns the viewport metrics
-- I.E. the zone where the widget will sit
function MEContext:getViewportMetrics()
    local margin      = S.getSetting("WidgetMargin")
    local b1          = UTILS.JS_Window_GetBounds(self.cbl)
    local b2          = UTILS.JS_Window_GetBounds(self.cbr)

    local lb1x, lb1y  = UTILS.screenCoordinatesToLocal(self.mebounds, b1.r, b1.b)
    local lb2x, lb2y  = UTILS.screenCoordinatesToLocal(self.mebounds, b2.l, b2.b)

    local x = lb1x + margin
    local w = lb2x - margin - x

    return x, w
end

function MEContext:isHovered()
    local mec = self
    return  (mec.mouse_x >= mec.xpos) and
            (mec.mouse_x <  mec.xpos + mec.w) and
            (mec.mouse_y >= mec.ypos) and
            (mec.mouse_y <  mec.ypos + mec.h)
end

function MEContext:hoveredTab()
    local tabs = self:tabs()
    local xp = 0
    for i, t in ipairs(tabs) do
        if t:pointIntab(self.mouse_x, self.mouse_y) then
            return t
        end
    end
    return nil
end

function MEContext:pollMouseEvent(click_event_name, wm_event_name)
    local mec = self

    local pending_attribute         = 'pending_' .. click_event_name
    local pending_time_attribute    = click_event_name .. '_time'

    -- pending_left_click,   left_click_time
    -- pending_right_click,  right_click_time
    -- pending_mouse_wheel,  mouse_wheel_time

    mec[pending_attribute] = nil

    local b, pt, time, wpl, wph, lpl, lph = reaper.JS_WindowMessage_Peek(mec.me, wm_event_name)

    local event_is_new = not (time == mec[pending_time_attribute]) and not(time == 0) and not(MACCLContext.frame_time - time > 3.0) -- Avoid peeking old messages when relaunching in debug

    if event_is_new then
        mec[pending_time_attribute] = time

        if mec.hovered then
            -- Intercept message and save for subsequent code
            mec[pending_attribute] = { time = time, x = lpl, y = lph, p1 = wpl, p2 = wph }
        else
            -- Not for us ! Repost message
            reaper.JS_WindowMessage_Post(mec.me, wm_event_name, wpl, wph, lpl, lph)
        end
    end
end

function MEContext:mouseEventLoop()
    local mec = self

    if not mec.w then return end -- mec needs to be fully initialized to handle mouse events

    -- Handle mouse move
    local mx, my        = UTILS.screenCoordinatesToLocal(mec.mebounds, MACCLContext.last_mouse_x, MACCLContext.last_mouse_y)
    mec.mouse_x         = mx
    mec.mouse_y         = mec.mebounds.h - my

    -- Calculate if the mouse is hovering the MaccLane's widget
    local last_hovered   = mec.hovered
    mec.hovered          = mec:isHovered()
    if not (mec.hovered == last_hovered) then
        mec.has_hover_change = true
    end

    -- Watch keyboard modifiers
    local shift_down = MOD.ShiftIsDown()
    if not (mec.shift_down == shift_down) then
        mec.has_modifier_change = true
    end
    mec.shift_down = shift_down

    local win_ctrl_mac_cmd_down = MOD.WinControlMacCmdIsDown()
    if not (mec.win_ctrl_mac_cmd_down == win_ctrl_mac_cmd_down) then
        mec.has_modifier_change = true
    end
    mec.win_ctrl_mac_cmd_down = win_ctrl_mac_cmd_down

    local win_alt_mac_option_down = MOD.WinAltMacOptionIsDown()
    if not (mec.win_alt_mac_option_down == win_alt_mac_option_down) then
        mec.has_modifier_change = true
    end
    mec.win_alt_mac_option_down = win_alt_mac_option_down

    mec:pollMouseEvent('left_click',  'WM_LBUTTONUP')
    mec:pollMouseEvent('right_click', 'WM_RBUTTONUP')
    mec:pollMouseEvent('mouse_wheel', 'WM_MOUSEWHEEL')
end

-- Peek mouse events. This is done every frame to be reactive.
-- Subsequent code will have to react to pending events
function MEContext:inputEventLoop()
    local mec = self

    -- Every frame, update current take/item/track for this me
    local metrack = nil
    local meitem  = nil
    local meproj  = nil
    local metake  = reaper.MIDIEditor_GetTake(mec.me)

    if not (mec.take == metake) then
        if metake then
            meitem   = reaper.GetMediaItemTake_Item(metake)
            metrack  = reaper.GetMediaItemTake_Track(metake)
            meproj   = reaper.GetItemProjectContext(meitem)
        end

        -- Edited target changed (or was not set precedently)
        -- Tabs will change, load them
        mec.take  = metake
        mec.item  = meitem
        mec.track = metrack
        mec.proj  = meproj
        mec.pending_take_change = true
    end

    if mec.proj then
        local master_track = reaper.GetMasterTrack(mec.proj)
        local b, undo_hash = reaper.GetSetMediaTrackInfo_String(master_track, "P_EXT:MACCLANE_UNDO" , "", false)
        if not (undo_hash == mec.undo_hash) then
            mec.undo_hash = undo_hash
            mec.pending_take_change = true
        end
    end

    -- Watch layout changes
    local ks_state = reaper.GetToggleCommandStateEx(D.SECTION_MIDI_EDITOR, D.ACTION_ME_TOGGLE_KEY_SNAP)
    if not (mec.ks_state == ks_state) then
        -- This will force a redraw
        mec.pending_layout_change = true
        mec.ks_state = ks_state
    end

    -- Every frame handle mouse events
    mec:mouseEventLoop()
end

function MEContext:editorInfo()
    local mec           = self
    local take          = reaper.MIDIEditor_GetTake(mec.me)
    local track         = nil
    local item          = nil
    local track_name    = ''
    local take_name     = ''
    if take then
        track = reaper.GetMediaItemTake_Track(take)
        item  = reaper.GetMediaItemTake_Item(take)
        _, track_name = reaper.GetTrackName(track)
        take_name = reaper.GetTakeName(take)
    end
    return {
        take        = take,
        track       = track,
        item        = item,
        track_name  = track_name,
        take_name   = take_name
    }
end

function MEContext:loadTabs()

    local activeTab = self:activeTab()

    local item, track = nil, nil
    local take = reaper.MIDIEditor_GetTake(self.me)
    if take then
        item  = reaper.GetMediaItemTake_Item(take)
        track = reaper.GetMediaItemTake_Track(take)
    end

    local gtabs = Serializing.loadTabsFromEntity(self, Tab.Types.GLOBAL, GlobalScopeRepo.instance())
    local ptabs = Serializing.loadTabsFromEntity(self, Tab.Types.PROJECT, nil)
    local ttabs = Serializing.loadTabsFromEntity(self, Tab.Types.TRACK, track)
    local itabs = Serializing.loadTabsFromEntity(self, Tab.Types.ITEM, item)

    -- Build up and array (instead of stored lookups) so that we can apply sorting
    self._tabs = {}
    for uuid, t in pairs(gtabs) do
        self._tabs[#self._tabs+1] = t
    end
    for uuid, t in pairs(ptabs) do
        self._tabs[#self._tabs+1] = t
    end
    for uuid, t in pairs(ttabs) do
        self._tabs[#self._tabs+1] = t
    end
    for uuid, t in pairs(itabs) do
        self._tabs[#self._tabs+1] = t
    end

    Tab.sort(self._tabs)

    for _, t in ipairs(self._tabs) do
        -- Restore active state if the tab survives to reload
        if activeTab then
            if t.uuid == activeTab.uuid then
                if t:isStateFull() then -- this may have changed during reload
                    t:setActive(true)
                end
            end
        end
    end

    self._tabs[#self._tabs+1] = AddTabTab:new(self)

    self.lastTabLoad          = MACCLContext.lastTabSavedAt
end

function MEContext:tabs(options)
    options = options or {}

    if (not self._tabs) or options.force_reload then
        self:loadTabs()
    end

    return self._tabs
end

function MEContext:findTabByName(name)
    local tabs = self:tabs()
    for _, t in ipairs(tabs) do
        if name == t.params.title then
            return t
        end
    end
    return nil
end

function MEContext:getContentWidth()
    local spacing = S.getSetting("TabSpacing")
    local w = 0
    local tabs = self:tabs()
    for i, tab in ipairs(tabs) do
        w = w + tab:width()
        if not (i == #tabs) then
            w = w + spacing
        end
    end
    return w
end

function MEContext:redraw()
    local mec     = self
    local me      = mec.me

    -- Not ready, don't draw
    if not mec.bitmap then return end

    local bgcol   	= reaper.GetThemeColor("col_main_bg")
	local r,g,b 	= reaper.ColorFromNative(bgcol)

    self.bgcol 		= 0xFF000000 | (r << 16) | (g << 8) | b

    local w = reaper.JS_LICE_GetWidth(mec.bitmap)
    local h = reaper.JS_LICE_GetHeight(mec.bitmap)

    -- Cleanup full BG
    reaper.JS_LICE_FillRect(mec.bitmap, 0, 0, w, h, self.bgcol, 1, "COPY")

    if reaper.MIDIEditor_GetMode(self.me) == 1 then
        -- Don't draw tabs in list view mode
    else
        local spacing = S.getSetting("TabSpacing")
        -- Draw tabs
        local tabs = self:tabs()

        local xp = 0
        for i, t in ipairs(tabs) do
            xp = xp + t:draw(self, xp)
            xp = xp + spacing
        end
    end

    -- Insert MAGIC Pixel
    reaper.JS_LICE_PutPixel(mec.bitmap, w-1, 0, MACCLContext.MACCLANE_MAGIC_PIXEL, 1, "COPY")

    -- Double buffering
    reaper.JS_LICE_Blit(mec.db_bitmap, 0, 0, mec.bitmap, 0, 0, reaper.JS_LICE_GetWidth(mec.db_bitmap), reaper.JS_LICE_GetHeight(mec.db_bitmap), 1, "COPY")

    -- Invalidate the viewport zone
    reaper.JS_Window_InvalidateRect(me, mec.xpos, mec.ypos, mec.xpos + mec.w, mec.ypos + mec.h, true)
end

function MEContext:onScroll()

    -- Divider for the value returned by the scroll event
    local scroll_div     = 10.0
    local scroll_max_pix = 40

    local mec   = self
    local pc    = mec.pending_mouse_wheel

    local off   = pc.p2
    local sign  = (pc.p2 < 0 and -1 or 1)
    off = off * sign
    off = off / scroll_div

    -- Limit the scrolling to 5 pix per event
    off = math.floor(0.5 + math.min(scroll_max_pix, math.max(off, 1)))
    off = off * sign

    mec.scrollOffset = mec.scrollOffset + off

    pc.handled = true
end

-- Tests if tabs have some changes that need a complete reload from the project/track/item
-- This will recalculate the local tab cache for the MEContext and trigger a redraw
-- This may happen
-- if the current active take changes (completely different context)
-- Or when the global settings ask for it (on change - maybe it's a bit overkill, a simple redraw would be enough in most cases)
-- Or when tabs where never loaded (lastTabLoad date is nil)
-- Or when there was a tab save / delete
function MEContext:tabsNeedReload()
    return self.pending_take_change or self.pending_settings_change or not self.lastTabLoad or not (MACCLContext.lastTabSavedAt == self.lastTabLoad)
end

function MEContext:activeTab()
    local tabs = self._tabs

    if not tabs then return end

    for _, t in ipairs(tabs) do
        if t:isStateFull() and t:isActive() then return t end
    end
    return nil
end

function MEContext:update(is_fresh)
    -- Update is called often, but not nesserarly every frame (the upper layer decides of the pace)
    local mec = self
    local me  = mec.me

    if not me then return end

    local shouldRecomposite     = is_fresh

    -- Reload tabs if there was a change
    if self:tabsNeedReload() then
        self:loadTabs()
        shouldRecomposite               = true
        self.pending_take_change        = false
        self.pending_settings_change    = false
    end

    if mec.pending_layout_change then
        shouldRecomposite = true
        mec.pending_layout_change = false
    end

    -- Update once mebounds for this frame (it is costy)
    local mebounds   = UTILS.JS_Window_GetBounds(me)

    mec.bounds_changed  =   not (mebounds.h == mec.mebounds.h) or
                            not (mebounds.w == mec.mebounds.w) or
                            not (mebounds.l == mec.mebounds.l) or
                            not (mebounds.t == mec.mebounds.t)

    mec.mebounds       = mebounds

    -- This is the most time consuming function but we need it
    -- Since the UI may change from a frame to another
    local viewport_x, viewport_w    = mec:getViewportMetrics()

    -- Get the viewport wanted size and see if we need a resize
    local wantedx                   = viewport_x
    local wantedw                   = viewport_w
    local wantedh                   = MACCLContext.TABBAR_HEIGHT

    -- Create a size "key" for the current midi editor size, to compare to the
    -- current one, and update our drawing conditions (bitmap size/compositing) if it has changed
    local mekey                     = mebounds.w .. "x" .. mebounds.h
    local mekey2                    = wantedx .. "x" .. wantedw

    if wantedw < 0 then
        wantedw = 0
    end

    -- Also, get the content width
    local contentw      = self:getContentWidth()
    local wanted_bmw    = (contentw < viewport_w) and (viewport_w) or contentw

    -- Check that our bitmap size is correct, if not resize
    local bmw = reaper.JS_LICE_GetWidth(mec.bitmap)
    if not (wanted_bmw == bmw) then
        self:resizeBitmap(wanted_bmw, wantedh)
        shouldRecomposite = true
    end

    local me_view_mode = reaper.MIDIEditor_GetMode(self.me)
    if not (me_view_mode == self.last_redraw_me_view_mode) then
        shouldRecomposite = true
    end

    -- MIDI Editor has been resized or Something happened that changed the ME layout
    if not(mec.mekey == mekey) or not(mec.mekey2 == mekey2)  then
        shouldRecomposite = true
    end

    -- Scroll logic
     -- Handle mouse scroll
    local curoffset = mec.scrollOffset
    if mec.pending_mouse_wheel then
        mec:onScroll()
    end
    -- Enough room in the widget ? scroll not needed
    if contentw < viewport_w then mec.scrollOffset = 0 end
    -- Cannot scroll beyond the max
    if mec.scrollOffset + viewport_w > contentw then
        mec.scrollOffset = contentw - viewport_w
    end
    -- Scroll is negative ? not possible
    if mec.scrollOffset < 0 then mec.scrollOffset = 0 end
    -- Scrolled ? -> need recomposite
    if not (curoffset == mec.scrollOffset) then
        shouldRecomposite = true
    end

    -- Scroll offset is recalculated. Update the tabs
    local last_hovered_tab      = mec.hovered_tab
    mec.hovered_tab             = mec:hoveredTab()
    mec.has_tab_hover_change    = not (last_hovered_tab == mec.hovered_tab)

    if shouldRecomposite then
        local x         = wantedx
        local y         = mebounds.h - 5 - wantedh

		if MACCLContext.is_windows then
			y = y + 1 -- Widgets are not exactly the same size between OSes
		end

        mec.mekey   = mekey
        mec.mekey2  = mekey2

        mec.xpos    = x
        mec.ypos    = y
        mec.w       = wantedw
        mec.h       = wantedh
        mec.last_redraw_me_view_mode = me_view_mode

        -- Composite our bitmap with our viewport. Handle scroll offset.
        reaper.JS_Composite(me, mec.xpos, mec.ypos, mec.w, mec.h, mec.db_bitmap, mec.scrollOffset, 0, wantedw, wantedh, true)
    end

    local shouldRedraw = shouldRecomposite

    -- Force a redraw on all those conditions :
    if mec.has_modifier_change or mec.has_tab_hover_change or mec.has_pending_redraw or mec.bounds_changed or MACCLContext.force_redraw or  mec:hasPendingMouseEvents() or mec:hasPendingDrawOperations() then
        mec.has_pending_redraw = false
        shouldRedraw = true
    end

    if shouldRedraw then
        mec:redraw()
    end

    -- We stack mouse events during draw operation and handle them after the draw operation
    -- To make the draw operations as short as possible.
    if mec.pending_left_click and mec.pending_left_click.handled and mec.pending_left_click.tab then
        mec.pending_left_click.tab:onLeftClick(mec, mec.pending_left_click.params)
        mec.pending_left_click.tab = nil
    end

    if mec.pending_right_click and mec.pending_right_click.handled and mec.pending_right_click.tab then
        mec.pending_right_click.tab:onRightClick(mec, mec.pending_right_click.params)
        mec.pending_right_click.tab = nil
    end
end

function MEContext:openTabEditorOn(tab)
    TabEditor.openOnTab(tab)
end

function MEContext:openTabContextMenuOn(tab)
    TabPopupMenu.openOnTab(tab)
end

function MEContext:onStateFullTabActivation(tab, options)
    options = options or {}
    local tabs = self:tabs({force_reload=options.force_reload})

    if tab:isStateFull() then
        for i, t in ipairs(tabs) do
            if not (t.uuid == tab.uuid) then
                if t:isStateFull() and t:isActive() then
                    -- The tab is being quit, snapshot state
                    TabState.SnapShotAll(t)
                    t:save({skip_full_tab_reload=true})
                end
                t:setActive(false)
            else
                t:setActive(true)
            end
        end
    end

    self.has_pending_redraw = true
end

function MEContext:openEditorForNewTab(plus_tab, options)
    options = options or {}

    local open, editor = TabEditor.hasEditorForNewTabOpen(self)
    if open then
        editor.draw_count = 1 -- This will force focus on the tab editor's window
        return
    end

    local meinfo                = self:editorInfo()

    local newtab                = Tab:new(self)
    newtab.last_draw_global_x   = plus_tab.last_draw_global_x
    newtab.last_draw_global_y   = plus_tab.last_draw_global_y

    -- Initialize owner
    local owner_type = S.getSetting("DefaultOwnerTypeForNewTab")

    if (owner_type == Tab.Types.GLOBAL) then
        newtab:setOwner(GlobalScopeRepo.instance())
    elseif (owner_type == Tab.Types.TRACK) and meinfo.track then
        newtab:setOwner(meinfo.track)
    elseif (owner_type == Tab.Types.ITEM) and meinfo.item then
        newtab:setOwner(meinfo.item)
    else
        newtab:setOwner(nil)
    end

    if not options.full_bypass and not options.full_record then
        local p = S.getSetting("DefaultTemplateForPlusButton")

        if p == "*full_bypass" then
            options.full_bypass = true
        elseif p == "*full_record" then
            options.full_record = true
        else
            local valid, json = Serializing.loadTabTemplate(p)
            if not valid then
                options.full_bypass = true
            else
                local template = json.tabs[1]
                newtab.params = template.params
            end
        end
    end

    if options.full_record then
        newtab:setFullRecord()
    end
    if options.full_bypass then
        newtab:setFullBypass()
    end


    self:openTabEditorOn(newtab)
end


-- Call this in atexit to do some cleanup on the associated midi editor
function MEContext:implode()
    self:destroyBitmap()

    -- stop blocking messages because we won't be here to repost !
    -- We don't want to use
    --    reaper.JS_WindowMessage_Release( windowHWND, messages )
    -- Because we may break other plugins that use them when exiting :(
    reaper.JS_WindowMessage_PassThrough(self.me, "WM_LBUTTONUP",  true)
    reaper.JS_WindowMessage_PassThrough(self.me, "WM_RBUTTONUP",  true)
    reaper.JS_WindowMessage_PassThrough(self.me, "WM_MOUSEWHEEL", true)
end

function MEContext:isStillValid()
    return reaper.ValidatePtr(self.me, "HWND")
end

function MEContext:setPendingSettingsChange(b)
    self.pending_settings_change = b
end

---------------------

function MEContext.all()
    return MaccLaneContextLookupPerME
end

function MEContext.getContextForME(me)
    local address = reaper.JS_Window_AddressFromHandle(me)
    return MaccLaneContextLookupPerME[address]
end

function MEContext.createForME(me)
    return MEContext:new(me)
end

-- Remove obsolete MIDI editors from our tracking list
function MEContext.cleanupObsolete()
    local torem = {}
    for addr, mec in pairs(MaccLaneContextLookupPerME) do
        if mec:isStillValid() then
            -- Editor is still valid
        else
            torem[addr] = true
        end
    end

    for addr, b in pairs(torem) do
        MaccLaneContextLookupPerME[addr]:implode()
        MaccLaneContextLookupPerME[addr] = nil
    end
end

function MEContext.getCreateOrUpdate(me)
    if not me then return end

    local mec       = MEContext.getContextForME(me)
    local is_fresh  = false

    if not mec then
        mec = MEContext:new(me)
        is_fresh = true
    end

    mec:update(is_fresh)
end

function MEContext.notifySettingsChange()
    for _, mec in pairs(MaccLaneContextLookupPerME) do
        mec:setPendingSettingsChange(true)
    end
end

function MEContext.summary()
    local s = ""
    for addr, mec in pairs(MaccLaneContextLookupPerME) do
        s = s .. "" .. addr .. " : " .. (mec._tabs and #mec._tabs or "nil") .. "\n"
        for _, t in ipairs(mec._tabs) do
            s = s .. t.uuid .. " " .. (t:isActive() and "active" or "inactive") .. "\n"
        end
    end
    return s
end

return MEContext

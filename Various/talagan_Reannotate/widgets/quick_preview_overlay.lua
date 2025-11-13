-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local AppContext        = require "classes/app_context"
local ImGui             = require "ext/imgui"
local ImGuiMd           = require "reaimgui_markdown"
local Notes             = require "classes/notes"

local NoteEditor        = require "widgets/note_editor"
local SettingsEditor    = require "widgets/settings_editor"
local OverlayCanvas     = require "widgets/overlay_canvas"

local S                 = require "modules/settings"

local reaper_ext        = require "modules/reaper_ext"


local OS                            = reaper.GetOS()
local is_windows                    = OS:match('Win')
local is_macos                      = OS:match('OSX') or OS:match('macOS')
local is_linux                      = OS:match('Other')

local function GetScreen(x, y)
    local scr = {}
    scr.l, scr.t, scr.r, scr.b = reaper.JS_Window_GetViewportFromRect(x, y, x, y, false)
    scr.w = scr.r - scr.l
    scr.h = math.abs(scr.t - scr.b)
    return scr
end

local QuickPreviewOverlay = {}
QuickPreviewOverlay.__index = QuickPreviewOverlay

-- Force fonts to arial
QuickPreviewOverlay.markdownStyle = {
    default     = { font_family = "Arial", font_size = 13, base_color = "#CCCCCC", bold_color = "white", autopad = 5 },

    h1          = { font_family = "Arial", font_size = 23, padding_left = 0,  padding_top = 3, padding_bottom = 5, line_spacing = 0, base_color = "#288efa", bold_color = "#288efa" },
    h2          = { font_family = "Arial", font_size = 21, padding_left = 5,  padding_top = 3, padding_bottom = 5, line_spacing = 0, base_color = "#4da3ff", bold_color = "#4da3ff" },
    h3          = { font_family = "Arial", font_size = 19, padding_left = 10, padding_top = 3, padding_bottom = 4, line_spacing = 0, base_color = "#65acf7", bold_color = "#65acf7" },
    h4          = { font_family = "Arial", font_size = 17, padding_left = 15, padding_top = 3, padding_bottom = 3, line_spacing = 0, base_color = "#85c0ff", bold_color = "#85c0ff" },
    h5          = { font_family = "Arial", font_size = 15, padding_left = 20, padding_top = 3, padding_bottom = 3, line_spacing = 0, base_color = "#9ecdff", bold_color = "#9ecdff" },

    paragraph   = { font_family = "Arial", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 0, padding_in_blockquote = 6 },
    list        = { font_family = "Arial", font_size = 13, padding_left = 40, padding_top = 5, padding_bottom = 7, line_spacing = 0, padding_indent = 5 },

    table       = { font_family = "Arial", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 0 },

    code        = { font_family = "monospace",  font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7,  line_spacing = 4, padding_in_blockquote = 6 },
    blockquote  = { font_family = "Arial", font_size = 13, padding_left = 0,  padding_top = 5, padding_bottom = 10, line_spacing = 2, padding_indent = 10 },

    link        = { base_color = "orange", bold_color = "tomato"},

    separator   = { padding_top = 3, padding_bottom = 7 }
}

function QuickPreviewOverlay:new()
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()

    return instance
end

function QuickPreviewOverlay:_initialize()
    self.visible_things  = {}
    self.filter_str = ''
end

function QuickPreviewOverlay:timeToPixels(app_ctx, time)
    return math.floor((time - app_ctx.av.start_time) * reaper.GetHZoomLevel() * app_ctx.av.dpi)
end

function QuickPreviewOverlay:getItemYBounds(track, item)
    -- Get the item's Y position in pixels within the Arrange view
    local app_ctx       = AppContext.instance()
    local track_y       = reaper.GetMediaTrackInfo_Value(track, "I_TCPY") * app_ctx.av.dpi
    local item_y_offset = reaper.GetMediaItemInfo_Value(item, "I_LASTY")  * app_ctx.av.dpi
    local item_h        = reaper.GetMediaItemInfo_Value(item, "I_LASTH")  * app_ctx.av.dpi

    return math.floor(track_y + item_y_offset + 0.5), math.floor(item_h + 0.5)
end

function QuickPreviewOverlay:IsInReaper()
    local app_ctx = AppContext.instance()
    local fg = reaper.JS_Window_GetForeground()
    if is_macos then
        return fg ~= nil
    else
        if fg == app_ctx.mv.hwnd then return true end
        if reaper.JS_Window_IsChild(app_ctx.mv.hwnd, fg) then return true end
        if self.note_editor and fg == self.note_editor.hwnd then return true end
        if self.settings_editor and fg == self.settings_editor.hwnd then return true end

        return false
    end
end

function QuickPreviewOverlay:buildEditContextForThing(object, type, track_num, parent_widget_name, pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom)

    local app_ctx   = AppContext.instance()

    local parent = app_ctx.av

    if parent_widget_name == 'arrange' then
        parent = app_ctx.av
    elseif parent_widget_name == 'tcp' then
        parent = app_ctx.tcp
    elseif parent_widget_name == 'mcp' then
        parent = (track_num == -1) and app_ctx.mcp_master or app_ctx.mcp_other
    elseif parent_widget_name == 'time_ruler' then
        parent = app_ctx.time_ruler
    end

    local name = ""
    if type == 'track' then
        local _, tname = reaper.GetTrackName(object)
        name = tname
    elseif type == 'item' then
        local take = reaper.GetActiveTake(object)
        if take then
            name = reaper.GetTakeName(take)
        end
    elseif type == "env" then
        local _, ename = reaper.GetEnvelopeName(object)
        name = ename
    elseif type == "project" then
        name = "Project"
    end

    local notes                 = Notes:new(object)

    return {
        -- Basic info
        object      = object,
        type        = type,
        name        = name,
        -- Parent info
        parent      = parent,
        widget      = parent_widget_name,
        -- Position and size of the hint rect
        pos_x       = pos_x_pixels,
        pos_y       = pos_y_pixels,
        width       = len_x_pixels,
        height      = len_y_pixels,
        clamped_left    = clamped_left,
        clamped_right   = clamped_right,
        clamped_top     = clamped_top,
        clamped_bottom  = clamped_bottom,
        -- Annotation info
        notes       = notes,
        -- Track num
        track_num   = track_num + 1
    }
end

function QuickPreviewOverlay:updateVisibleThings()

    local app_ctx   = AppContext.instance()
    local avi       = app_ctx.av
    local tcp       = app_ctx.tcp

    self.visible_things = {} -- Reset visible items list

    -- Get total number of tracks
    local track_count = reaper.CountTracks(0)

    local function block_clamp(minx, miny, w, h, limitx, limity, low_limit_x, low_limit_y)
        local maxx = minx + w
        local maxy = miny + h

        local clamped_left      = false
        local clamped_right     = false
        local clamped_top       = false
        local clamped_bottom    = false

        low_limit_x = low_limit_x or 0
        low_limit_y = low_limit_y or 0

        if minx < low_limit_x then
            minx           = low_limit_x
            clamped_left   = true
        end
        if miny < low_limit_y   then
            miny            = low_limit_y
            clamped_top     = true
        end

        if maxx > limitx then
            maxx           = limitx
            clamped_right  = true
        end
        if maxy > limity then
            maxy            = limity
            clamped_bottom  = true
        end

        w = maxx - minx
        h = maxy - miny

        return minx, miny, w, h, clamped_left, clamped_right, clamped_top, clamped_bottom
    end

    -- Iterate through tracks
    for i = -1, track_count - 1 do
        local is_master         = (i==-1)
        local track             = is_master and reaper.GetMasterTrack(0) or reaper.GetTrack(0, i)
        local _, tname          = reaper.GetTrackName(track)
        local track_height      = reaper.GetMediaTrackInfo_Value(track, "I_TCPH") * app_ctx.av.dpi
        local track_top         = reaper.GetMediaTrackInfo_Value(track, "I_TCPY") * app_ctx.av.dpi
        local track_bottom      = track_top + track_height
        local track_is_pinned   = reaper_ext.IsTrackPinned(track)
        local hlimit            = track_is_pinned and 0 or avi.pinned_height
        local tcp_entry         = nil

        local track_is_visible_in_tcp = reaper_ext.IsTrackVisibleInTcp(track, is_master)

        -- Loop on track envelopes
        if track_is_visible_in_tcp then
            local ei = 0
            while true do
                local envelope = reaper.GetTrackEnvelope(track, ei)
                if not envelope then break end

                if reaper_ext.IsEnvelopeVisible(envelope) then
                    local env_top     = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPY") * app_ctx.av.dpi + track_top
                    local env_height  = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPH") * app_ctx.av.dpi
                    local env_bottom  = env_top + env_height

                    if env_height > 0 and ((env_top >= hlimit and env_top <= avi.h) or (env_bottom >= hlimit and env_bottom <= avi.h)) then

                        local pos_x_pixels = 0
                        local len_x_pixels = tcp.w
                        local pos_y_pixels, len_y_pixels = env_top, env_height
                        local clamped_left, clamped_right, clamped_top, clamped_bottom = false, false, false, false

                        pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, tcp.w, tcp.h, 0, hlimit)

                        local env_entry = self:buildEditContextForThing(envelope, "env", i, "tcp", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom)

                        table.insert(self.visible_things, env_entry)
                    end
                end

                ei = ei + 1
            end
        end

        -- Loop on items. Process item only if visible.
        if track_is_visible_in_tcp and track_height > 0 and ((track_top >= hlimit and track_top <= avi.h) or (track_bottom >= hlimit and track_bottom <= avi.h)) then

            local pos_x_pixels = 0
            local len_x_pixels = tcp.w
            local pos_y_pixels, len_y_pixels = track_top, track_height
            local clamped_left, clamped_right, clamped_top, clamped_bottom = false, false, false, false

            pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, tcp.w, tcp.h, 0, hlimit)

            tcp_entry = self:buildEditContextForThing(track, "track", i, "tcp", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom)

            table.insert(self.visible_things, tcp_entry)

            -- Now process items
            local item_count = reaper.CountTrackMediaItems(track)

            for j = 0, item_count - 1 do
                local item                  = reaper.GetTrackMediaItem(track, j)
                local item_is_visible       = not reaper_ext.IsItemInHiddenFixedLane(item)
                if item_is_visible then
                    local item_pos              = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                    local item_len              = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                    local item_end              = item_pos + item_len

                    -- Get Arrange view time range
                    local start_time, end_time = avi.start_time, avi.end_time
                    if start_time == end_time then
                        start_time, end_time = reaper.GetPlayPosition(), reaper.GetProjectLength(0)
                    end

                    -- Check if item is visible
                    if item_end >= start_time and item_pos <= end_time then
                        local pos_x_pixels = self:timeToPixels(app_ctx, item_pos)
                        local len_x_pixels = math.floor(item_len * reaper.GetHZoomLevel() * app_ctx.av.dpi + 0.5)
                        local pos_y_pixels, len_y_pixels = self:getItemYBounds(track, item)
                        local clamped_left, clamped_right, clamped_top, clamped_bottom = false, false, false, false

                        pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, avi.w, avi.h, 0, hlimit)

                        table.insert(self.visible_things, self:buildEditContextForThing(item, "item", i, "arrange", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom))
                    end
                end
            end
        end

        local track_is_visible_in_mcp = reaper_ext.IsTrackVisibleInMcp(track, is_master)

        -- Handle track in mcp
        local mcp = (i==-1) and app_ctx.mcp_master or app_ctx.mcp_other
        if track_is_visible_in_mcp and mcp.hwnd and reaper.JS_Window_IsVisible(mcp.hwnd) then

            local mcp_track_left                = reaper.GetMediaTrackInfo_Value(track, "I_MCPX") * mcp.dpi
            local mcp_track_width               = reaper.GetMediaTrackInfo_Value(track, "I_MCPW") * mcp.dpi
            local mcp_full_track_top            = reaper.GetMediaTrackInfo_Value(track, "I_MCPY") * mcp.dpi
            local mcp_full_track_height         = reaper.GetMediaTrackInfo_Value(track, "I_MCPH") * mcp.dpi
            local mcp_track_height              = mcp_full_track_height -- - space_for_fx_and_send
            local mcp_track_top                 = mcp_full_track_top -- + space_for_fx_and_send
            local pos_x_pixels                  = mcp_track_left
            local len_x_pixels                  = mcp_track_width
            local pos_y_pixels, len_y_pixels    = mcp_track_top, mcp_track_height
            local clamped_left, clamped_right, clamped_top, clamped_bottom = false, false, false, false

            pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, mcp.w, mcp.h, 0, 0)

            if pos_x_pixels >= 0 and len_x_pixels > 2 and pos_x_pixels + len_x_pixels <= mcp.w then
                local mcp_entry = self:buildEditContextForThing(track, "track", i, "mcp", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right, clamped_top, clamped_bottom)
                table.insert(self.visible_things, mcp_entry)
                if tcp_entry then
                    mcp_entry.tcp_entry = tcp_entry
                    tcp_entry.mcp_entry = mcp_entry
                end
            end
        end
    end

    if app_ctx.time_ruler.hwnd and reaper.JS_Window_IsVisible(app_ctx.time_ruler.hwnd) then
        local pos_x_pixels = app_ctx.time_ruler.x
        local pos_y_pixels = app_ctx.time_ruler.y
        local len_x_pixels = app_ctx.time_ruler.w
        local len_y_pixels = app_ctx.time_ruler.h
        local proj         = reaper.EnumProjects(-1)
        local proj_entry, _ = self:buildEditContextForThing(proj, "project", -1, "time_ruler", 0, 0, len_x_pixels, len_y_pixels, false, false, false, false)
        table.insert(self.visible_things, proj_entry)
    end

    for _, thing in ipairs(self.visible_things) do
        self:applySearchToThing(thing)
    end
end

function QuickPreviewOverlay:title()
    return "Reannotate Quick Preview"
end


function QuickPreviewOverlay:applySearchToThing(thing)
    thing.search_results    = {}

    local case_sensitive = false
    local search_str     = self.filter_str

    if not case_sensitive then
        search_str = search_str:lower()
    end

    for i=0, Notes.MAX_SLOTS - 1 do
        local slot      = i
        local slotNotes = thing.notes:slotText(slot)

        if not case_sensitive then
            slotNotes = slotNotes:lower()
        end

        if self.filter_str == '' then
            thing.search_results[slot+1] = true
        else
            thing.search_results[slot+1] = slotNotes:match(search_str)
        end
    end
end

function QuickPreviewOverlay:minimizeTopWindowsAtLaunch()
    local app_ctx = AppContext.instance()

    self.minimized_windows = {}
    if false then
        local c, l = reaper.JS_Window_ListAllTop()
        for token in string.gmatch(l, "[^,]+") do
            local subhwnd = reaper.JS_Window_HandleFromAddress(token)
            if not subhwnd then return end

            if subhwnd ~= app_ctx.mv.hwnd and subhwnd ~= self.hwnd and reaper.JS_Window_IsVisible(subhwnd) then

                local owner = reaper.JS_Window_GetRelated(subhwnd, "OWNER")

                local is_minimized = (reaper.JS_Window_GetLong(subhwnd, "STYLE") & 0x20000000 ~= 0)
                local is_mixer     = (reaper.JS_Window_GetTitle(subhwnd) == "Mixer")

                if not is_minimized and reaper.JS_Window_GetTitle(owner) == reaper.JS_Window_GetTitle(app_ctx.mv.hwnd) and not is_mixer then
                    reaper.JS_Window_Show(subhwnd, "SHOWMINIMIZED")
                    self.minimized_windows[#self.minimized_windows+1] = subhwnd
                end
            end
        end
    end
end

function QuickPreviewOverlay:restoreMinimizedWindowsAtExit()
    for _, win in ipairs(self.minimized_windows) do
        reaper.JS_Window_Show(win, "SHOWNOACTIVATE")
    end
end

function QuickPreviewOverlay:ZOrderSwap()
    local app_ctx = AppContext.instance()
    if self.canvases then
        for _, canvas in ipairs(self.canvases) do
            local parent_hwnd = canvas:parentWindowInfo().hwnd

            -- Using the swap those guys technique
            reaper.JS_Window_SetZOrder(canvas.hwnd, "INSERTAFTER", parent_hwnd)
            reaper.JS_Window_SetZOrder(parent_hwnd, "INSERTAFTER", canvas.hwnd)

            if is_windows then
                reaper.JS_Window_SetForeground(canvas.hwnd)
            end
        end
    end
end

function QuickPreviewOverlay:ensureZOrder()
    local app_ctx = AppContext.instance()
    local ctx = app_ctx.imgui_ctx
    local t = reaper.time_precise()

    if S.getSetting("UseProfiler") then
        return
    end

    if (not self.was_in_reaper) and (self:IsInReaper()) then
        -- Returning into reaper. Give focus to editor if there's one open
        if self.note_editor then
            reaper.JS_Window_SetForeground(self.note_editor.hwnd)
        end

        -- Set main window as foreground.
        reaper.JS_Window_SetForeground(app_ctx.mv.hwnd)

        self:ZOrderSwap()

        if self.note_editor then
            app_ctx:flog("Foregrounding note editor ...")
            reaper.JS_Window_SetForeground(self.note_editor.hwnd)
            self.note_editor:GrabFocus()
        end
    else
        if self:IsInReaper() then
            if is_windows and self.note_editor and self.note_editor.draw_count == 0 then
                -- This is necessary under windows. The editor focus scrambles the
                -- Floating mixer's z order.
                self:ZOrderSwap()
            end
            if (not self.note_editor) and (not self.settings_window) and (self.canvases) then
                local fhwnd = reaper.JS_Window_GetFocus()

                -- If we don't have a note editor, then the overlay should always have focus in the imgui context
                -- local one_canvas_has_focus = (reaper.JS_Window_GetClassName(fhwnd) == "reaper_imgui_context")

                if fhwnd == reaper.GetMainHwnd() then
                    reaper.JS_Window_SetForeground(self.canvases[1].hwnd)
                    self.canvases[1]:GrabFocus()
                end
            end
        end
    end
end

function QuickPreviewOverlay:currentTooltipSizeForThing(thing)
    if self.note_editor then
        return thing.notes:tooltipSize(self.note_editor.edited_slot or 0)
    end

    local slot = (thing == self.pinned_thing) and (thing.capture_slot) or (thing.hovered_slot)

    if slot == -1 then
        return Notes.defaultTooltipSize()
    end

    return thing.notes:tooltipSize(slot or 0)
end


function QuickPreviewOverlay:tooltipAdvisedPositionForThing(thing, mouse_x, mouse_y)
    local w, h      = self:currentTooltipSizeForThing(thing)
    local screen    = GetScreen(mouse_x, mouse_y)

    local x = mouse_x + 20
    local y = mouse_y + 20

    if mouse_x + 20 + w > screen.w then
        x = screen.w - w
    end

    if mouse_y + 20 + h > screen.h then
        y = screen.h - h
    end

    return { x = x, y = y }
end

function QuickPreviewOverlay:editorAdvisedPositionAndSizeForThing(thing, mouse_x, mouse_y)
    local screen    = GetScreen(mouse_x, mouse_y)
    local ttpos     = self:tooltipAdvisedPositionForThing(thing, mouse_x, mouse_y)
    local ttw, tth  = self:currentTooltipSizeForThing(thing)

    local w = ttw
    local h = tth

    if w < 550 then
        w = 550
    end

    if h < 200 then
        h = 200
    end

    local x = ttpos.x - w
    if x < 0 then
        x = ttpos.x + ttw
    end

    local y = ttpos.y
    if y + h > screen.h then
        y = screen.h - h
    end

    return { x = x, y = y, w = w, h = h}
end

function QuickPreviewOverlay:tooltipAdvisedPositionForEditedThingAndSlot(thing, slot, editor, mx, my)
    local screen            = GetScreen(mx, my)
    local edx,edy,edw,edh   = editor.x,editor.y,editor.w,editor.h
    local ttw, tth          = self:currentTooltipSizeForThing(thing)

    -- Detect if current tooltip is on the left or right, and stay left or right
    local is_left = thing.capture_xy and thing.capture_xy.x < edx

    local x = thing.capture_xy.x
    local y = thing.capture_xy.y

    if is_left then
        x = edx - ttw
        if x < 0 then
            x = edx + edw
        end
    else
        x = edx + edw
        if x + ttw > screen.w then
            x = edx - ttw
        end
    end

    y = edy
    if y + tth > screen.h then
        y = screen.h - tth
    end
    return { x = x, y = y }
end

function QuickPreviewOverlay:drawTooltip()
    local app_ctx   = AppContext.instance()
    local ctx       = app_ctx.imgui_ctx
    local mx, my    = ImGui.GetMousePos(ctx)
    local tt_pos    = {x = mx + 20, y = my + 20}
    local hovered_thing = self.hovered_thing
    local pinned_thing  = self.pinned_thing

    local thing_to_tooltip = (self.note_editor and self.note_editor.edited_thing) or (pinned_thing) or (hovered_thing)

    if thing_to_tooltip then
        if not self.mdwidget then
            -- This will lag a bit. Do it on first capture.
            self.mdwidget  = ImGuiMd:new(ctx, "markdown_widget_1", { wrap = true, autopad = true, skip_last_whitespace = true }, QuickPreviewOverlay.markdownStyle )
        end

        local slot_to_tooltip   = ((self.note_editor) and (self.note_editor.edited_slot)) or (pinned_thing and pinned_thing.capture_slot) or (thing_to_tooltip.hovered_slot)
        local tttext            = (slot_to_tooltip == -1) and (thing_to_tooltip.no_notes_message) or (thing_to_tooltip.notes:slotText(slot_to_tooltip))
        if tttext == "" or tttext == nil then
            tttext = "`:grey:No " .. thing_to_tooltip.type .. " notes for the `_:grey:" .. Notes.SlotLabel(slot_to_tooltip):lower() .. "_ `:grey:category`"
        end

        self.mdwidget:setText(tttext)

        ImGui.SetNextWindowBgAlpha(ctx, 1)

        if self.note_editor or pinned_thing then
            -- If there's a note editor, fix the position
            tt_pos = thing_to_tooltip.capture_xy
        else
            tt_pos = self:tooltipAdvisedPositionForThing(thing_to_tooltip, mx, my)
        end

        local ttw, tth     = self:currentTooltipSizeForThing(thing_to_tooltip)

        -- First draw, force coordinates and size
        if self.tt_draw_count == 0 then
            ImGui.SetNextWindowPos(ctx,     tt_pos.x, tt_pos.y)
            ImGui.SetNextWindowSize(ctx,    ttw, tth)
        end

        if ImGui.Begin(ctx, "Reannotate Notes (Tooltip)", true, ImGui.WindowFlags_NoFocusOnAppearing | ImGui.WindowFlags_NoTitleBar | ImGui.WindowFlags_TopMost | ImGui.WindowFlags_NoSavedSettings) then
            local cur_x, cur_y  = ImGui.GetWindowPos(ctx)
            local cur_w, cur_h  = ImGui.GetWindowSize(ctx)
            local draw_list     = ImGui.GetWindowDrawList(ctx)

            self.mdwidget:render(ctx)

            -- If there was an interaction this frame, we need to patch the content of nte
            local interaction = self.mdwidget.interaction
            if interaction then
                local before    = tttext.sub(tttext, 1, interaction.start_offset - 1)
                local after     = tttext.sub(tttext, interaction.start_offset + interaction.length)
                tttext          = before .. interaction.replacement_string .. after

                thing_to_tooltip.notes:setSlotText(slot_to_tooltip, tttext)
                thing_to_tooltip.notes:commit()
            end

            -- Border. Tooltip is shown when edited or hoevered
            if (self.note_editor) or (not thing_to_tooltip.notes:isBlank() and ( thing_to_tooltip.hovered_slot ~= -1)) then
                ImGui.DrawList_AddRect(draw_list, cur_x + 1, cur_y + 1, cur_x + cur_w - 1, cur_y + cur_h - 1, Notes.SlotColor(slot_to_tooltip) << 8 | 0xFF, 0, 0, 2)
            end

            -- Resiszers
            if self.note_editor then
                local triangle_size = 13
                ImGui.DrawList_AddTriangleFilled(draw_list, cur_x, cur_y + cur_h, cur_x + triangle_size, cur_y + cur_h, cur_x, cur_y + cur_h - triangle_size, Notes.SlotColor(slot_to_tooltip) << 8 | 0xFF)
                ImGui.DrawList_AddTriangleFilled(draw_list, cur_x + cur_w, cur_y + cur_h, cur_x + cur_w, cur_y + cur_h - triangle_size, cur_x + cur_w - triangle_size, cur_y + cur_h, Notes.SlotColor(slot_to_tooltip) << 8 | 0xFF)
            end

            if self.note_editor and ImGui.IsMouseDoubleClicked(ctx, ImGui.MouseButton_Left) and ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootAndChildWindows) and self.mdwidget.max_x and self.mdwidget.max_y then
                local target_h = self.mdwidget.max_y + 20
                local target_w = self.mdwidget.max_x + 20
                cur_h = target_h -- frame
                if target_w < ttw then
                    cur_w = target_w
                end

                self.tt_draw_count = -1
            end

            -- Save new sizes to items/tracks when resized
            if self.note_editor and ((cur_w ~= ttw) or (cur_h ~= tth)) then
                thing_to_tooltip.notes:setTooltipSize(self.note_editor.edited_slot, cur_w, cur_h)
                thing_to_tooltip.notes:commit()

                -- Alternate entry (tcp/mcp clone) should be refreshed
                local alternate_entry = thing_to_tooltip.mcp_entry or thing_to_tooltip.tcp_entry
                if alternate_entry then
                    alternate_entry.notes:pull()
                end
            end

            if ImGui.IsWindowFocused(ctx) and self.note_editor and not ImGui.IsMouseDown(ctx, ImGui.MouseButton_Left) then
                -- If we have a valid note editor and we're not resizing the tooltip, the note editor should always have focus
                self.note_editor:GrabFocus()
            end

            ImGui.End(ctx)

            self.tt_draw_count = (self.tt_draw_count or 0) + 1
        end
    else
        self.tt_draw_count = 0
    end
end

function QuickPreviewOverlay:draw()
    local app_ctx  = AppContext.instance()
    local ctx      = app_ctx.imgui_ctx
    local mx, my   = reaper.GetMousePosition()
    mx, my = ImGui.PointConvertNative(ctx, mx, my)

    ImGui.PushFont(ctx, app_ctx.arial_font, 12)

    self.draw_count = self.draw_count or 0

    if self.draw_count == 0 then
        self:minimizeTopWindowsAtLaunch()
        self.canvases = {}
        if app_ctx.mcp_window.is_top then
            -- Undocked MCP, create two canvases
            self.canvases[#self.canvases+1] = OverlayCanvas:new(self, OverlayCanvas.TYPES.REAPER_MAIN_ALONE)
            self.canvases[#self.canvases+1] = OverlayCanvas:new(self, OverlayCanvas.TYPES.REAPER_MIXER_ALONE)
        else
            -- Docked MCP, create only one canvas
            self.canvases[#self.canvases+1] = OverlayCanvas:new(self, OverlayCanvas.TYPES.REAPER_MAIN_AND_MIXER)
        end
    end

    -- Reset frame status variables
    self.hovered_thing_this_frame   = nil
    self.captured_click             = false
    self.captured_right_click       = false

    for _, canvas in ipairs(self.canvases) do
        -- This may capture hover and click
        canvas:draw(self)
    end

    if not self.hovered_thing_this_frame then
        self.hovered_thing = nil
    end

    if self.pinned_thing then
        if self.note_editor then
            self.pinned_thing = nil
        else
            local ppos   = self.pinned_thing.capture_xy
            local pw, ph = self:currentTooltipSizeForThing(self.pinned_thing)
            if (mx < ppos.x - 30) or (mx > ppos.x + pw) or (my < ppos.y - 30) or (my > ppos.y + ph) then
                self.pinned_thing = nil
            end
        end
    end

    self:drawTooltip()

    if self.hovered_thing and self.captured_click then
        -- Save the click point for fixing the position
        self.hovered_thing.capture_xy    = self:tooltipAdvisedPositionForThing(self.hovered_thing, mx, my)
        self.hovered_thing.capture_slot  = self.hovered_thing.hovered_slot

        self.tt_draw_count = 0

        self.note_editor = NoteEditor:new()
        self.note_editor:setEditedThing(self.hovered_thing)
        self.note_editor:setEditedSlot(self.hovered_thing.hovered_slot == -1 and 1 or self.hovered_thing.hovered_slot)
        local ne_metrics = self:editorAdvisedPositionAndSizeForThing(self.hovered_thing, mx, my)
        self.note_editor:setPosition(ne_metrics.x, ne_metrics.y)
        self.note_editor:setSize(ne_metrics.w, ne_metrics.h)
        self.note_editor:GrabFocus()

        self.note_editor.slot_edit_change_callback = function()
            -- We may need to reposition the tooltip since it's changed
            self.note_editor.edited_thing.capture_xy = self:tooltipAdvisedPositionForEditedThingAndSlot(self.note_editor.edited_thing, self.note_editor.edited_slot, self.note_editor, mx, my)
            -- Reset draw counter for tooltip to take position change into account
            self.tt_draw_count = 0
        end

        self.note_editor.slot_commit_callback = function()
            for _, thing in ipairs(self.visible_things) do
                self:applySearchToThing(thing)
            end
        end
    end

    if self.hovered_thing and self.captured_right_click then
        self.note_editor                 = nil
        self.hovered_thing.capture_xy    = self:tooltipAdvisedPositionForThing(self.hovered_thing, mx, my)
        self.hovered_thing.capture_slot  = self.hovered_thing.hovered_slot
        self.pinned_thing                = self.hovered_thing
        self.tt_draw_count = 0
    end

    if self.hovered_thing and not self.note_editor then
        -- Reset tooltip draw count so that the tooltip is not fixed
        self.tt_draw_count = 0
    end

    if not self.hovered_thing and self.captured_click then
        -- Clicked on something which is not overable : remove editor
        self.note_editor = nil
    end

    if self.note_editor and self.note_editor.open then
        self.note_editor:draw()
    else
        self.note_editor = nil
    end

    if self.settings_window and self.settings_window.open then
        self.settings_window:draw()
    else
        self.settings_window = nil
    end

    self:ensureZOrder()

    if self.draw_count > 0 then
        -- Update "in reaper" state
        self.was_in_reaper = (self:IsInReaper())
    end

    -- Update draw count
    self.draw_count = self.draw_count + 1

    if app_ctx.want_quit then
        -- Restore windows before exiting
        self:restoreMinimizedWindowsAtExit()
        reaper.JS_Window_SetFocus(app_ctx.mv.hwnd)
        reaper.JS_Window_SetForeground(app_ctx.mv.hwnd)
       -- reaper.ShowConsoleMsg("BOOM")
    end

    ImGui.PopFont(ctx)
end

return QuickPreviewOverlay

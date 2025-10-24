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

    h1          = { font_family = "Arial", font_size = 23, padding_left = 0,  padding_top = 3, padding_bottom = 5, line_spacing = 5, base_color = "#288efa", bold_color = "#288efa" },
    h2          = { font_family = "Arial", font_size = 21, padding_left = 5,  padding_top = 3, padding_bottom = 5, line_spacing = 5, base_color = "#4da3ff", bold_color = "#4da3ff" },
    h3          = { font_family = "Arial", font_size = 19, padding_left = 10, padding_top = 3, padding_bottom = 4, line_spacing = 5, base_color = "#65acf7", bold_color = "#65acf7" },
    h4          = { font_family = "Arial", font_size = 17, padding_left = 15, padding_top = 3, padding_bottom = 3, line_spacing = 5, base_color = "#85c0ff", bold_color = "#85c0ff" },
    h5          = { font_family = "Arial", font_size = 15, padding_left = 20, padding_top = 3, padding_bottom = 3, line_spacing = 5, base_color = "#9ecdff", bold_color = "#9ecdff" },

    paragraph   = { font_family = "Arial", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 3, padding_in_blockquote = 6 },
    table       = { font_family = "Arial", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 3 },

    code        = { font_family = "monospace",  font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7,  line_spacing = 3, padding_in_blockquote = 6 },

    blockquote  = { font_family = "Arial", font_size = 13, padding_left = 0,  padding_top = 5, padding_bottom = 10, line_spacing = 3, padding_indent = 10 },
    list        = { font_family = "Arial", font_size = 13, padding_left = 40, padding_top = 5, padding_bottom = 7,  line_spacing = 3, padding_indent = 5 },
    link        = { font_family = "Arial", font_size = 13, base_color = "orange", bold_color = "tomato"},

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
end

function QuickPreviewOverlay:timeToPixels(app_ctx, time)
    return math.floor((time - app_ctx.av.start_time) * reaper.GetHZoomLevel())
end

function QuickPreviewOverlay:getItemYBounds(track, item)
    -- Get the item's Y position in pixels within the Arrange view
    local track_y       = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
    local item_y_offset = reaper.GetMediaItemInfo_Value(item, "I_LASTY")
    local item_h        = reaper.GetMediaItemInfo_Value(item, "I_LASTH")

    return math.floor(track_y + item_y_offset + 0.5), math.floor(item_h + 0.5)
end

function QuickPreviewOverlay:IsInReaper()
    local fg = reaper.JS_Window_GetForeground()
    if is_macos then
        return fg ~= nil
    else
        local mainhwnd = reaper.GetMainHwnd()
        return fg == mainhwnd or reaper.JS_Window_IsChild(mainhwnd, fg) or (self.note_editor and fg == self.note_editor.hwnd) or (self.settings_editor and fg == self.settings_editor.hwnd) or (self.hwnd == fg)
    end
end

function QuickPreviewOverlay:buildEditContextForThing(object, type, track_num, parent_widget_name, pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right)

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
        clamped_left = clamped_left,
        clamped_right = clamped_right,
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

    local function block_clamp(minx, miny, w, h, limitx, limity, low_limit_y)
        local maxx = minx + w
        local maxy = miny + h

        local clamped_left = false
        local clamped_right = false
        if minx < 0 then
            minx = 0
            clamped_left = true
        end
        if maxx > limitx then
            maxx = limitx
            clamped_right = true
        end

        low_limit_y = low_limit_y or 0

        if miny < low_limit_y   then miny = low_limit_y end
        if maxy > limity        then maxy = limity      end

        w = maxx - minx
        h = maxy - miny

        return minx, miny, w, h, clamped_left, clamped_right
    end

    -- Iterate through tracks
    for i = -1, track_count - 1 do
        local is_master         = (i==-1)
        local track             = is_master and reaper.GetMasterTrack(0) or reaper.GetTrack(0, i)
        local _, tname          = reaper.GetTrackName(track)
        local track_height      = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
        local track_top         = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
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
                    local env_top     = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPY") + track_top
                    local env_height  = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPH")
                    local env_bottom  = env_top + env_height

                    if env_height > 0 and ((env_top >= hlimit and env_top <= avi.h) or (env_bottom >= hlimit and env_bottom <= avi.h)) then

                        local pos_x_pixels = 0
                        local len_x_pixels = tcp.w
                        local pos_y_pixels, len_y_pixels = env_top, env_height
                        local clamped_left, clamped_right = false, false

                        pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, tcp.w, tcp.h, hlimit)

                        local env_entry = self:buildEditContextForThing(envelope, "env", i, "tcp", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right)

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
            local clamped_left, clamped_right = false, false

            pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, tcp.w, tcp.h, hlimit)

            tcp_entry = self:buildEditContextForThing(track, "track", i, "tcp", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right)

            table.insert(self.visible_things, tcp_entry)

            -- Now process items
            local item_count = reaper.CountTrackMediaItems(track)

            for j = 0, item_count - 1 do
                local item          = reaper.GetTrackMediaItem(track, j)
                local item_pos      = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
                local item_len      = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
                local item_end      = item_pos + item_len

                -- Get Arrange view time range
                local start_time, end_time = avi.start_time, avi.end_time
                if start_time == end_time then
                    start_time, end_time = reaper.GetPlayPosition(), reaper.GetProjectLength(0)
                end

                -- Check if item is visible
                if item_end >= start_time and item_pos <= end_time then
                    local pos_x_pixels = self:timeToPixels(app_ctx, item_pos)
                    local len_x_pixels = math.floor(item_len * reaper.GetHZoomLevel()+0.5)
                    local pos_y_pixels, len_y_pixels = self:getItemYBounds(track, item)
                    local clamped_left, clamped_right = false, false

                    pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, avi.w, avi.h, hlimit)

                    table.insert(self.visible_things, self:buildEditContextForThing(item, "item", i, "arrange", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right))
                end
            end
        end

        local track_is_visible_in_mcp = reaper_ext.IsTrackVisibleInMcp(track, is_master)

        -- Handle track in mcp
        local mcp = (i==-1) and app_ctx.mcp_master or app_ctx.mcp_other
        if track_is_visible_in_mcp and mcp.hwnd and reaper.JS_Window_IsVisible(mcp.hwnd) then

            local mcp_track_left                = reaper.GetMediaTrackInfo_Value(track, "I_MCPX")
            local mcp_track_width               = reaper.GetMediaTrackInfo_Value(track, "I_MCPW")
            local mcp_full_track_top            = reaper.GetMediaTrackInfo_Value(track, "I_MCPY")
            local mcp_full_track_height         = reaper.GetMediaTrackInfo_Value(track, "I_MCPH")
            local mcp_track_height              = mcp_full_track_height -- - space_for_fx_and_send
            local mcp_track_top                 = mcp_full_track_top -- + space_for_fx_and_send
            local pos_x_pixels                  = mcp_track_left
            local len_x_pixels                  = mcp_track_width
            local pos_y_pixels, len_y_pixels    = mcp_track_top, mcp_track_height
            local clamped_left, clamped_right   = false, false

            pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right = block_clamp(pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, mcp.w, mcp.h)

            if pos_x_pixels >= 0 and len_x_pixels > 2 and pos_x_pixels + len_x_pixels <= mcp.w then
                local mcp_entry = self:buildEditContextForThing(track, "track", i, "mcp", pos_x_pixels, pos_y_pixels, len_x_pixels, len_y_pixels, clamped_left, clamped_right)
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
        local proj_entry, _ = self:buildEditContextForThing(proj, "project", -1, "time_ruler", 0, 0, len_x_pixels, len_y_pixels, false, false)
        table.insert(self.visible_things, proj_entry)
    end

    for _, thing in ipairs(self.visible_things) do
        self:applySearchToThing(thing)
    end
end

function QuickPreviewOverlay:title()
    return "Reannotate Quick Preview"
end

function QuickPreviewOverlay:ensureHwnd()
    if not self.hwnd then
        -- Retrieve hwn on instanciation
        self.hwnd = reaper.JS_Window_Find(self:title(), true)
        self.parent_hwnd = reaper.JS_Window_GetParent(self.hwnd)
        reaper.JS_WindowMessage_Intercept(self.hwnd, "WM_MOUSEWHEEL", false)
        reaper.JS_WindowMessage_Intercept(self.hwnd, "WM_MOUSEHWHEEL", false)
    end
end

function QuickPreviewOverlay:forwardEvent(event)
    local app_ctx = AppContext:instance()

    self.last_peeked_message_times = self.last_peeked_message_times or {}

    local message_is_new = true

    while message_is_new do
        local b, pt, time, wpl, wph, lpl, lph = reaper.JS_WindowMessage_Peek(self.hwnd, event)

        message_is_new = not (time == self.last_peeked_message_times[event]) and not(time == 0) and not(reaper.time_precise() - time > 3.0) -- Avoid peeking old messages when relaunching in debug
        if message_is_new then
            local mx, my = reaper.GetMousePosition()
            mx, my = ImGui.PointConvertNative(app_ctx.imgui_ctx, mx, my)
            local target = reaper.GetMainHwnd()

            -- TODO : ATM mcp layout changes are not detected so this will scroll the MCP but tracks will be at the wrong place
            if reaper.JS_Window_IsVisible(app_ctx.mcp_other.hwnd) and
            (app_ctx.mcp_other.x <= mx and mx <= app_ctx.mcp_other.x + app_ctx.mcp_other.w) and
            (app_ctx.mcp_other.y <= my and my <= app_ctx.mcp_other.y + app_ctx.mcp_other.h) then
                target = app_ctx.mcp_other.hwnd
            end

            reaper.JS_WindowMessage_Post(target, event, wpl, wph, lpl, lph)
            self.last_peeked_message_times[event] = time
        end
    end
end

function QuickPreviewOverlay:forwardMouseWheelEvents()
    self:forwardEvent("WM_MOUSEWHEEL")
    self:forwardEvent("WM_MOUSEHWHEEL")
end

function QuickPreviewOverlay:minimizeTopWindowsAtLaunch()
    local app_ctx = AppContext.instance()

    self.minimized_windows = {}
    local c, l = reaper.JS_Window_ListAllTop()
    for token in string.gmatch(l, "[^,]+") do
        local subhwnd = reaper.JS_Window_HandleFromAddress(token)
        if not subhwnd then return end

        if subhwnd ~= app_ctx.mv.hwnd and subhwnd ~= self.hwnd and reaper.JS_Window_IsVisible(subhwnd) then

            local owner = reaper.JS_Window_GetRelated(subhwnd, "OWNER")

            local is_minimized = (reaper.JS_Window_GetLong(subhwnd, "STYLE") & 0x20000000 ~= 0)
            if not is_minimized and reaper.JS_Window_GetTitle(owner) == reaper.JS_Window_GetTitle(app_ctx.mv.hwnd) then
                reaper.JS_Window_Show(subhwnd, "SHOWMINIMIZED")
                self.minimized_windows[#self.minimized_windows+1] = subhwnd
            end
        end
    end
end

function QuickPreviewOverlay:restoreMinimizedWindowsAtExit()
    for _, win in ipairs(self.minimized_windows) do
        reaper.JS_Window_Show(win, "SHOWNOACTIVATE")
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

        -- Set our overlay as foreground
        reaper.JS_Window_SetForeground(self.hwnd)

        if self.note_editor then
            app_ctx:flog("Foregrounding note editor ...")
            reaper.JS_Window_SetForeground(self.note_editor.hwnd)
            self.note_editor:GrabFocus()
        end

    else
        if not self.note_editor and not self.settings_window then
            -- If we don't have a note editor, then the overlay should always have focus in the imgui context
            if self:IsInReaper() and not ImGui.IsWindowFocused(ctx) then
                ImGui.SetWindowFocus(ctx)
                reaper.JS_Window_SetFocus(self.hwnd)
                app_ctx:flog("Overlay grabs focus")
            end
        end
    end
end

function QuickPreviewOverlay:garbageCollectNoteEditor()
    -- Ensure note editor is deleted if not used anymore
    if self.note_editor and not self.note_editor.show_editor then
        self.note_editor = nil
        AppContext:instance():flog("Garbage collected note editor")
    end
end

function QuickPreviewOverlay:currentTooltipSizeForThing(thing)
    if thing.hovered_slot == -1 then
        return Notes.defaultTooltipSize()
    end

    return thing.notes:tooltipSize(thing.hovered_slot or 0)
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

function QuickPreviewOverlay:applySearchToThing(thing)
    thing.search_results    = {}
    self.filter_str         = self.filter_str or ''

    for i=0, Notes.MAX_SLOTS - 1 do
        local slot      = i
        local slotNotes = thing.notes:slot(slot)

        if self.filter_str == '' then
            thing.search_results[slot+1] = true
        else
            thing.search_results[slot+1] = slotNotes:match(self.filter_str)
        end
    end
end

function QuickPreviewOverlay:drawQuickSettings()
    local app_ctx           = AppContext.instance()
    local ctx               = app_ctx.imgui_ctx
    local draw_list         = ImGui.GetWindowDrawList(ctx)
    local mx, my            = ImGui.GetMousePos(ctx)
    local is_clicked        = ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left)
    local margin_t          = 8
    local margin_l          = 8
    local spacing           = 4
    local mid_spacing       = spacing*0.5
    local r                 = 9.5
    local d                 = 2 * r
    local header_l          = 60
    local wpos_x, wpos_y    = ImGui.GetWindowPos(ctx)

    local sinalpha          = (0xFF - 0x40 + math.floor(0x40 * math.sin(reaper.time_precise()*10)))

    ImGui.DrawList_AddRectFilled(draw_list, app_ctx.main_toolbar.x, app_ctx.main_toolbar.y, app_ctx.main_toolbar.x + app_ctx.main_toolbar.w, app_ctx.main_toolbar.y + app_ctx.main_toolbar.h, 0x202020E0, 5)
    ImGui.DrawList_AddRect      (draw_list, app_ctx.main_toolbar.x, app_ctx.main_toolbar.y, app_ctx.main_toolbar.x + app_ctx.main_toolbar.w, app_ctx.main_toolbar.y + app_ctx.main_toolbar.h, 0xA0A0A0FF, 5)

    for i=0, Notes.MAX_SLOTS - 1 do
        local slot          = (i == Notes.MAX_SLOTS - 1) and (0) or (i+1)
        local color         = (Notes.SlotColor(slot) << 8) | 0xFF
        local l             = app_ctx.main_toolbar.x + (i * (2 * r + spacing)) + header_l + margin_l
        local t             = app_ctx.main_toolbar.y + margin_t
        local hovered       = (l - mid_spacing <= mx) and (mx <= l + mid_spacing + d) and (t - mid_spacing <= my) and (my <= t + mid_spacing + d)


        if app_ctx.enabled_category_filters[slot+1] then
            local fcol = color & 0xFFFFFF00 | 0x80
            if hovered then
                fcol = (color & 0xFFFFFF00) | sinalpha
            end
            ImGui.DrawList_AddRectFilled(draw_list, l, t, l + d, t + d, fcol, 1, 0)
        end
        ImGui.DrawList_AddRect(draw_list, l, t, l + d, t + d, color, 1, 0, 1)

        if hovered then
            ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 3, 1)
            ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, color )
            ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0x000000FF)
            ImGui.SetTooltip(ctx, Notes.SlotLabel(slot))
            ImGui.PopStyleColor(ctx, 2)
            ImGui.PopStyleVar(ctx)
        end

        if is_clicked and hovered then
            app_ctx.enabled_category_filters[slot+1] = not app_ctx.enabled_category_filters[slot+1]
        end
    end

    ImGui.PushFont(ctx, app_ctx.arial_font, 12)
    ImGui.DrawList_AddText(draw_list, app_ctx.main_toolbar.x + margin_l, app_ctx.main_toolbar.y + margin_t + 3, 0xA0A0A0FF, "Filter")
    ImGui.PopFont(ctx)

    local px, py = ImGui.GetWindowPos(ctx)
    ImGui.SetCursorPos(ctx, app_ctx.main_toolbar.x - px + 260, app_ctx.main_toolbar.y - py + margin_t )
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 2)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    if ImGui.Button(ctx, "All") then
        for i=0, Notes.MAX_SLOTS - 1 do
            local slot          = (i == Notes.MAX_SLOTS - 1) and (0) or (i+1)
            app_ctx.enabled_category_filters[slot+1] = true
        end
    end
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 3, 3)
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "None") then
        for i=0, Notes.MAX_SLOTS - 1 do
            local slot          = (i == Notes.MAX_SLOTS - 1) and (0) or (i+1)
            app_ctx.enabled_category_filters[slot+1] = false
        end
    end
    ImGui.PopStyleVar(ctx, 3)

    -- Search label
    ImGui.PushFont(ctx, app_ctx.arial_font, 12)
    ImGui.DrawList_AddText(draw_list, app_ctx.main_toolbar.x + margin_l, app_ctx.main_toolbar.y + margin_t + 27, 0xA0A0A0FF, "Search")
    ImGui.PopFont(ctx)


    ImGui.SetCursorPos(ctx, app_ctx.main_toolbar.x - wpos_x + margin_l + header_l, ImGui.GetCursorPosY(ctx) + 3)
    self.filter_str = self.filter_str or ""
    ImGui.SetNextItemWidth(ctx, 218) --math.min(220, app_ctx.main_toolbar.w - margin_l * 2 - header_l))
    local b, v      = ImGui.InputText(ctx, "##search_input", self.filter_str, ImGui.InputTextFlags_NoHorizontalScroll | ImGui.InputTextFlags_AutoSelectAll | ImGui.InputTextFlags_ParseEmptyRefVal )
    if b then
        self.filter_str = v
        for ti, thing in ipairs(self.visible_things) do
            self:applySearchToThing(thing)
        end
    end
    if self.filter_str == "" then
        local sx, sy    = ImGui.GetItemRectMin(ctx)
        ImGui.DrawList_AddText(draw_list, sx + 5, sy + 1, 0xA0A0A0FF, "Terms ...")
    end

    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + 4)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 1, 1)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    if ImGui.ImageButton(ctx, "##settings_button", app_ctx:getImage("settings"), 17, 17) then
        ImGui.SameLine(ctx)
        if self.settings_window then
            self.settings_window = nil
        else
            self.settings_window = SettingsEditor:new()
            self.settings_window:setPosition(wpos_x + ImGui.GetCursorPosX(ctx) + 5, wpos_y + ImGui.GetCursorPosY(ctx) )
        end
    end
    if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, "Settings")
    end
    ImGui.PopStyleVar(ctx, 2)

    local align             = 320
    local remaining_space   = app_ctx.main_toolbar.w - align

    local font_size = math.floor(remaining_space * 26/180.0 + 0.5)
    if font_size > 26 then font_size = 26 end
    if font_size < 16 then font_size = 16 end

    ImGui.PushFont(ctx, app_ctx.arial_font_italic, font_size)
    local rw, rh = ImGui.CalcTextSize(ctx, "Reannotate")

    if rw + font_size < remaining_space then
        -- Enough room to draw logo
        local spacing = 0.5 * (remaining_space - rw)
        local xpos = align + spacing
        if spacing > font_size then
            -- If space is big, align right, else center
            xpos = app_ctx.main_toolbar.w - font_size - rw
        end
        ImGui.DrawList_AddText(draw_list, app_ctx.main_toolbar.x + xpos, app_ctx.main_toolbar.y + (app_ctx.main_toolbar.h - rh) * 0.5, 0xA0A0A0FF, "Reannotate")
    end
    ImGui.PopFont(ctx)
end

function QuickPreviewOverlay:drawVisibleThing(thing, hovered_thing)
    local app_ctx   = AppContext.instance()
    local ctx       = app_ctx.imgui_ctx
    local sinalpha  = (0x50 + math.floor(0x40 * math.sin((reaper.time_precise() - (self.blink_start_time or 0))*10)))
    local sin2alpha  = (0x50 + math.floor(0x40 * math.sin((reaper.time_precise() - (self.blink_start_time or 0))*20)))
    local draw_list = ImGui.GetWindowDrawList(ctx)

    -- The following method allows to work on an entry which is present in the MCP and TCP at the same time
    local hovered   = hovered_thing and hovered_thing.object == thing.object
    local edited    = self.note_editor and self.note_editor.edit_context.object == thing.object

    if not hovered then
        -- reset hovered slot
        thing.hovered_slot = nil
    end

    -- Calculate the number of divisions
    local divisions             = 0
    local has_notes_to_show     = false
    local no_notes_message      = ""
    for i=0, Notes.MAX_SLOTS do
        local slot_notes        = thing.notes:slot(i)
        local is_slot_enabled   = app_ctx.enabled_category_filters[i + 1]
        local the_slot_matches_the_search  = (thing.search_results[i + 1])
        if slot_notes and slot_notes ~= "" and is_slot_enabled and the_slot_matches_the_search then
            divisions         = divisions + 1
            has_notes_to_show = true
        end
    end

    -- We should always show one division, even no note is shown
    if divisions == 0 then
        divisions = 1
        if thing.notes:isBlank() then
            no_notes_message = "`:grey:No " .. thing.type .. " notes`"
        else
            no_notes_message = "`:grey:All notes hidden`"
        end
    end

    local mx, my    = ImGui.GetMousePos(ctx)
    local xs        = thing.pos_x + thing.parent.x
    local ys        = thing.pos_y + thing.parent.y
    local ww        = thing.width
    local hh        = thing.height

    local hdivide   = (thing.widget == "arrange") or (thing.widget == "tcp") or (thing.widget == "time_ruler")
    local step      = (hdivide) and (ww * 1.0 / divisions) or (hh * 1.0 / divisions)

    local div = -1
    for i=0, Notes.MAX_SLOTS-1 do
        -- We change the slot span order (1,2,3... and then 0)
        local is_no_note_slot   = (i==0 and not has_notes_to_show)

        local slot              = (i==Notes.MAX_SLOTS - 1) and (0) or (i+1)
        local is_slot_enabled   = (is_no_note_slot or app_ctx.enabled_category_filters[slot + 1])

        local slot_notes        = (is_no_note_slot and no_notes_message or thing.notes:slot(slot))
        local the_slot_matches_the_search  = (thing.search_results[slot+1])

        -- The empty slot is always visible
        local is_slot_visible   = (is_no_note_slot) or (slot_notes and slot_notes ~= "" and is_slot_enabled and the_slot_matches_the_search)

        if is_slot_visible then
            div = div + 1
            -- Calculate this the first time we need it this frame
            -- It should be calculated after the hover, we need the right date

            local base_color_no_note    = 0x00000000 --0x90909000
            local border_width          = 1
            local triangle_size         = math.min(10, hdivide and step or ww, hdivide and hh or step)
            local bg_color              = base_color_no_note | 0x30
            local border_color          = base_color_no_note | 0xF0

            if not is_no_note_slot then
                border_width = 2

                local base_color_with_note  = Notes.SlotColor(slot) << 8 --0xFF007000
                bg_color     = base_color_with_note | 0x30
                border_color = base_color_with_note | 0xF0
            end

            local x1 = (hdivide) and (xs + (div) * step) or (xs)
            local y1 = (hdivide) and (ys) or (ys + (div) * step)
            local x2 = ((hdivide) and (x1 + step) or (x1 + ww))
            local y2 = ((hdivide) and (y1 + hh) or (y1 + step))

            if hovered then
                -- Hovering this slot
                if (x1 <= mx and mx <= x2 and y1 <= my and my <= y2) then
                    if not is_no_note_slot then
                        thing.hovered_slot = slot
                        if thing.mcp_entry then
                            thing.mcp_entry.hovered_slot = thing.hovered_slot
                        elseif thing.tcp_entry then
                            thing.tcp_entry.hovered_slot = thing.hovered_slot
                        end
                    else
                        -- This is dangerous, but don't really have the choice with the current model :/
                        thing.hovered_slot = -1
                        thing.no_notes_message = no_notes_message
                    end
                end
            end

            local it_s_the_edited_slot                              = (edited and self.note_editor.edited_slot == slot)
            local there_s_no_editor_open_but_the_slot_is_hovered    = (not self.note_editor and hovered and thing.hovered_slot == slot)
            local hovering_something_that_cant_have_notes           = (hovered and is_no_note_slot)

            if it_s_the_edited_slot or there_s_no_editor_open_but_the_slot_is_hovered or hovering_something_that_cant_have_notes then
                bg_color        = (bg_color & 0xFFFFFF00) | sinalpha
                border_color    = (border_color & 0xFFFFFF00) | (sinalpha + 0x60)
            end

            -- Background color.
            ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x2, y2, bg_color, 0, 0)

            if hdivide then
                -- Left border
                if div == 0 and not thing.clamped_left then
                    ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x1 + border_width, y2, border_color, 0, 0)
                end
                -- Right border
                if div == divisions - 1 and not thing.clamped_right then
                    ImGui.DrawList_AddRectFilled(draw_list, x2 - border_width, y1, x2, y2, border_color, 0, 0)
                end
                -- Top and bottom borders
                ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x2, y1 + border_width, border_color, 0, 0)
                ImGui.DrawList_AddRectFilled(draw_list, x1, y2 - border_width, x2, y2, border_color, 0, 0)
            else
                if div == 0 then
                    ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x2, y1 + border_width, border_color, 0, 0)
                end
                if div == divisions - 1 then
                    ImGui.DrawList_AddRectFilled(draw_list, x1, y2 - border_width, x2, y2, border_color, 0, 0)
                end
                ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x1 + border_width, y2, border_color, 0, 0)
                ImGui.DrawList_AddRectFilled(draw_list, x2 - border_width, y1, x2, y2, border_color, 0, 0)
            end

            if not is_no_note_slot then
                -- Label part
                ImGui.PushFont(ctx, app_ctx.arial_font, 10)
                local label     = Notes.SlotLabel(slot)
                local lw, lh    = ImGui.CalcTextSize(ctx, label)
                local padding_h   = 4
                local padding_v   = 3
                local margin    = 5
                local available_width   = x2 - x1 - 2 * margin - 2 * padding_h

                if lh + 2 * padding_v + 2 * margin < y2 - y1 then
                    local text_w = nil
                    local text   = nil
                    if available_width > lw then
                        text = label
                        text_w = lw
                    else
                        local initial = label:sub(1,1)
                        local llw, llh  = ImGui.CalcTextSize(ctx, initial)
                        if available_width > llw then
                            text = initial
                            text_w = llw
                        end
                    end
                    if text then
                        local rx    = x2 - margin - 2 * padding_h - text_w
                        local ry    = y1 + margin
                        local rx_r  = x2 - margin
                        local rx_b  = y1 + margin + lh + 2 * padding_v
                        ImGui.DrawList_AddRectFilled(draw_list, rx, ry, rx_r, rx_b, bg_color | 0xFF, 2)
                        ImGui.DrawList_AddRect(draw_list,       rx, ry, rx_r, rx_b, 0x000000FF, 2)
                        ImGui.DrawList_AddText(draw_list, x2 - margin - padding_h - text_w, y1 + margin + padding_v, 0x000000FF, text)
                    end
                end
                ImGui.PopFont(ctx)

                -- Post-it triangles
                if not (div == 0 and thing.clamped_left) then
                    ImGui.DrawList_AddTriangleFilled(draw_list, x1, y1, x1 + triangle_size, y1, x1, y1 + triangle_size, border_color)
                    ImGui.DrawList_AddTriangleFilled(draw_list, x1, y2, x1, y2 - triangle_size, x1 + triangle_size, y2, border_color)
                end

                if not (div == divisions -1 and thing.clamped_right) then
                    ImGui.DrawList_AddTriangleFilled(draw_list, x2 - triangle_size, y1, x2, y1, x2, y1 + triangle_size, border_color)
                    ImGui.DrawList_AddTriangleFilled(draw_list, x2, y2, x2 - triangle_size, y2, x2, y2 - triangle_size, border_color)
                end
            end
        end
    end
end

function QuickPreviewOverlay:drawTooltip(hovered_thing)
    local app_ctx   = AppContext.instance()
    local ctx       = app_ctx.imgui_ctx
    local mx, my    = ImGui.GetMousePos(ctx)
    local tt_pos    = {x = mx + 20, y = my + 20}

    local thing_to_tooltip = (self.note_editor and self.note_editor.edit_context) or (hovered_thing)

    if thing_to_tooltip then
        if not self.mdwidget then
            -- This will lag a bit. Do it on first capture.
            self.mdwidget  = ImGuiMd:new(ctx, "markdown_widget_1", { wrap = true, autopad = true, skip_last_whitespace = true }, QuickPreviewOverlay.markdownStyle )
        end

        local slot_to_tooltip   = ((self.note_editor) and (self.note_editor.edited_slot)) or (thing_to_tooltip.hovered_slot)
        local tttext            = (slot_to_tooltip == -1) and (thing_to_tooltip.no_notes_message) or (thing_to_tooltip.notes:slot(slot_to_tooltip))
        if tttext == "" or tttext == nil then
            tttext = "`:grey:No " .. thing_to_tooltip.type .. " notes for the `_:grey:" .. Notes.SlotLabel(slot_to_tooltip):lower() .. "_ `:grey:category`"
        end

        self.mdwidget:setText(tttext)

        ImGui.SetNextWindowBgAlpha(ctx, 1)

        if self.note_editor then
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

            -- Save new sizes to items/tracks

            if ((cur_w ~= ttw) or (cur_h ~= tth)) and self.note_editor then
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
    local app_ctx = AppContext.instance()

    local ctx = app_ctx.imgui_ctx
    local mvi = app_ctx.mv

    -- Set ImGui window size and position to match Main view ... maybe we should remove the top bar on macos
    ImGui.SetNextWindowSize(ctx, mvi.w, mvi.h)
    ImGui.SetNextWindowPos(ctx, mvi.x, mvi.y)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowBorderSize, 0)
    ImGui.SetNextWindowBgAlpha(ctx, 0.4 * math.sin(math.pi * 0.5 * math.min(reaper.time_precise() - app_ctx.launch_context.launch_time,  0.3)/0.3))

    -- Begin ImGui frame with visible background for debugging
    local succ, is_open = ImGui.Begin(ctx, self:title() , nil,
        ImGui.WindowFlags_NoTitleBar |
        ImGui.WindowFlags_NoScrollWithMouse |
        ImGui.WindowFlags_NoScrollbar |
        ImGui.WindowFlags_NoResize |
        ImGui.WindowFlags_NoNav |
        ImGui.WindowFlags_NoNavInputs |
        ImGui.WindowFlags_NoMove |
        ImGui.WindowFlags_NoDocking |
        ImGui.WindowFlags_NoDecoration)

    ImGui.PopStyleVar(ctx)

    local hovered_thing     = nil
    local captured_click    = false
    local mx, my            = ImGui.GetMousePos(ctx)

    self.draw_count         = self.draw_count or 0

    if self.draw_count == 0 then
        self:minimizeTopWindowsAtLaunch()
    end

    if succ then

        self:ensureHwnd()
        self:garbageCollectNoteEditor()
        self:ensureZOrder()
        self:forwardMouseWheelEvents()

        -- Handle overlay events. This should be done first, because escape will quit any item
        if ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootWindow) and ImGui.IsWindowFocused(ctx) and not(ImGui.IsAnyItemActive(ctx)) then
            if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) or (app_ctx.shortcut_was_released_once and app_ctx.launch_context:isShortcutStillPressed()) then
                app_ctx.want_quit = true
            end
        end

        -- Black background, for alpha see above
        ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0x000000FF)

        self:drawQuickSettings()

        -- Set draw list to Arrange view
        local draw_list = ImGui.GetWindowDrawList(ctx)

        -- First pass to detect hovered thing
        for _, thing in ipairs(self.visible_things) do
            local x1        = thing.pos_x + thing.parent.x
            local y1        = thing.pos_y + thing.parent.y
            local x2        = x1 + thing.width
            local y2        = y1 + thing.height
            local hovered   = x1 <= mx and mx <= x2 and y1 <= my and my <= y2
            if hovered and ImGui.IsWindowHovered(ctx) then
                hovered_thing = thing
                self.blink_start_time = self.blink_start_time or reaper.time_precise()
            end
        end

        -- Draw border + bg
        for _, thing in ipairs(self.visible_things) do
            self:drawVisibleThing(thing, hovered_thing)
        end

        if hovered_thing and (hovered_thing ~= self.last_hovered_thing or hovered_thing.hovered_slot ~= self.last_hovered_slot) then
            --self.blink_start_time = nil
        end

        self:drawTooltip(hovered_thing)

        if ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootWindow) and ImGui.IsMouseClicked(ctx,0,false) then
            captured_click = true
        end

        ImGui.PopStyleColor(ctx)
        ImGui.End(ctx)

        self.last_hovered_thing = hovered_thing
        self.last_hovered_slot  = hovered_thing and hovered_thing.hovered_slot
    else
        -- Emergency exit
        app_ctx.want_quit = true
    end

    if hovered_thing and captured_click then
        -- Save the click point for fixing the position
        hovered_thing.capture_xy    = self:tooltipAdvisedPositionForThing(hovered_thing, mx, my)
        hovered_thing.capture_slot  = hovered_thing.hovered_slot

        self.tt_draw_count = 0

        self.note_editor = NoteEditor:new()
        self.note_editor:setEditContext(hovered_thing)
        local ne_metrics = self:editorAdvisedPositionAndSizeForThing(hovered_thing, mx, my)
        self.note_editor:setPosition(ne_metrics.x, ne_metrics.y)
        self.note_editor:setSize(ne_metrics.w, ne_metrics.h)
        self.note_editor:setEditedSlot(hovered_thing.hovered_slot == -1 and 1 or hovered_thing.hovered_slot)

        self.note_editor.slot_edit_change_callback = function()
            -- We may need to reposition the tooltip since it's changed
            hovered_thing.capture_xy = self:tooltipAdvisedPositionForEditedThingAndSlot(hovered_thing, self.note_editor.edited_slot, self.note_editor, mx, my)
            -- Reset draw counter for tooltip to take position change into account
            self.tt_draw_count = 0
        end

        self.note_editor.slot_commit_callback = function()
            for _, thing in ipairs(self.visible_things) do
                self:applySearchToThing(thing)
            end
        end
    end

    if hovered_thing and not self.note_editor then
        -- Reset tooltip draw count so that the tooltip is not fixed
        self.tt_draw_count = 0
    end

    if not hovered_thing and captured_click then
        -- Clicked on something which is not overable : remove editor
        self.note_editor = nil
    end

    if self.note_editor and self.note_editor.show_editor then
        self.note_editor:draw()
    end

    if self.settings_window and self.settings_window.open then
        self.settings_window:draw()
    else
        self.settings_window = nil
    end

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
    end
end

return QuickPreviewOverlay

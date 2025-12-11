-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui             = require "ext/imgui"
local AppContext        = require "classes/app_context"
local D                 = require "modules/defines"
local PS                = require "modules/project_settings"
local ImGuiMd           = require "reaimgui_markdown"
local ImGuiMdAst        = require "reaimgui_markdown/markdown-ast"
local ImGuiMdText       = require "reaimgui_markdown/markdown-text"

local OverlayCanvas = {}
OverlayCanvas.__index = OverlayCanvas

OverlayCanvas.TYPES = {
    REAPER_MAIN_ALONE = 0,
    REAPER_MIXER_ALONE = 1,
    REAPER_MAIN_AND_MIXER = 2
}

function OverlayCanvas:new(parent_overlay, type)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(parent_overlay, type)
    return instance
end

function OverlayCanvas:_initialize(parent_overlay, type)
    self.parent_overlay = parent_overlay
    self.type           = type
end

function OverlayCanvas:isMain()
    return (self.type == OverlayCanvas.TYPES.REAPER_MAIN_ALONE) or (self.type == OverlayCanvas.TYPES.REAPER_MAIN_AND_MIXER)
end

function OverlayCanvas:parentWindowInfo()
    local app_ctx = AppContext.instance()
    if self:isMain() then
        return app_ctx.mv
    else
        return app_ctx.mcp_window
    end
end

function OverlayCanvas:title()
    if self:isMain() then
        return "Reannotate Quick Preview MAIN"
    else
        return "Reannotate Quick Preview MIXER"
    end
end

function OverlayCanvas:ensureHwnd()
    if not self.hwnd then
        -- Retrieve hwn on instanciation
        self.hwnd           = reaper.JS_Window_Find(self:title(), true)
        self.parent_hwnd    = reaper.JS_Window_GetParent(self.hwnd)
        reaper.JS_WindowMessage_Intercept(self.hwnd, "WM_MOUSEWHEEL", false)
        reaper.JS_WindowMessage_Intercept(self.hwnd, "WM_MOUSEHWHEEL", false)
    end
end


function OverlayCanvas:forwardEvent(event)
    local app_ctx = AppContext:instance()

    self.last_peeked_message_times = self.last_peeked_message_times or {}

    local message_is_new = true

    while message_is_new do
        local b, pt, time, wpl, wph, lpl, lph = reaper.JS_WindowMessage_Peek(self.hwnd, event)

        message_is_new = not (time == self.last_peeked_message_times[event]) and not(time == 0) and not(reaper.time_precise() - time > 3.0) -- Avoid peeking old messages when relaunching in debug
        if message_is_new then
            local target = self:parentWindowInfo().hwnd
            local mx, my = reaper.GetMousePosition()
            mx, my = ImGui.PointConvertNative(app_ctx.imgui_ctx, mx, my)

            -- TODO : ATM mcp layout changes are not detected so this will scroll the MCP but tracks will be at the wrong place
            if reaper.JS_Window_IsVisible(app_ctx.mcp_other.hwnd) and
            (app_ctx.mcp_other.x <= mx and mx <= app_ctx.mcp_other.x + app_ctx.mcp_other.w) and
            (app_ctx.mcp_other.y <= my and my <= app_ctx.mcp_other.y + app_ctx.mcp_other.h) then
                target = app_ctx.mcp_other.hwnd
            end

            ---@diagnostic disable-next-line: param-type-mismatch
            reaper.JS_WindowMessage_Send(target, event, wpl, wph, lpl, lph)
            self.last_peeked_message_times[event] = time
        end
    end
end

function OverlayCanvas:forwardMouseWheelEvents()
    self:forwardEvent("WM_MOUSEWHEEL")
    self:forwardEvent("WM_MOUSEHWHEEL")
end


function OverlayCanvas:drawQuickSettings()
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

    ---@diagnostic disable-next-line: redundant-parameter
    ImGui.PushFont(ctx, app_ctx.arial_font, 12)

    ImGui.DrawList_AddRectFilled(draw_list, app_ctx.main_toolbar.x, app_ctx.main_toolbar.y, app_ctx.main_toolbar.x + app_ctx.main_toolbar.w, app_ctx.main_toolbar.y + app_ctx.main_toolbar.h, 0x202020E0, 5)
    ImGui.DrawList_AddRect      (draw_list, app_ctx.main_toolbar.x, app_ctx.main_toolbar.y, app_ctx.main_toolbar.x + app_ctx.main_toolbar.w, app_ctx.main_toolbar.y + app_ctx.main_toolbar.h, 0xA0A0A0FF, 5)

    for i=0, D.MAX_SLOTS - 1 do
        local slot          = (i == D.MAX_SLOTS - 1) and (0) or (i+1)
        local color         = (D.SlotColor(slot) << 8) | 0xFF
        local l             = app_ctx.main_toolbar.x + (i * (2 * r + spacing)) + header_l + margin_l
        local t             = app_ctx.main_toolbar.y + margin_t
        local hovered       = (l - mid_spacing <= mx) and (mx <= l + mid_spacing + d) and (t - mid_spacing <= my) and (my <= t + mid_spacing + d) and ImGui.IsWindowHovered(ctx)

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
            ImGui.SetTooltip(ctx, PS.SlotLabel(slot))
            ImGui.PopStyleColor(ctx, 2)
            ImGui.PopStyleVar(ctx)
        end

        if is_clicked and hovered then
            app_ctx.enabled_category_filters[slot+1] = not app_ctx.enabled_category_filters[slot+1]
        end
    end

    ImGui.DrawList_AddText(draw_list, app_ctx.main_toolbar.x + margin_l, app_ctx.main_toolbar.y + margin_t + 3, 0xA0A0A0FF, "Filter")

    local px, py = ImGui.GetWindowPos(ctx)
    ImGui.SetCursorPos(ctx, app_ctx.main_toolbar.x - px + 260, app_ctx.main_toolbar.y - py + margin_t)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 3)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    if ImGui.Button(ctx, "All") then
        for i=0, D.MAX_SLOTS - 1 do
            local slot          = (i == D.MAX_SLOTS - 1) and (0) or (i+1)
            app_ctx.enabled_category_filters[slot+1] = true
        end
    end
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 3, 3)
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, "None") then
        for i=0, D.MAX_SLOTS - 1 do
            local slot          = (i == D.MAX_SLOTS - 1) and (0) or (i+1)
            app_ctx.enabled_category_filters[slot+1] = false
        end
    end
    ImGui.PopStyleVar(ctx, 3)

    -- Search label
    ImGui.DrawList_AddText(draw_list, app_ctx.main_toolbar.x + margin_l, app_ctx.main_toolbar.y + margin_t + 27, 0xA0A0A0FF, "Search")

    -- Search input
    ImGui.SetCursorPos(ctx, app_ctx.main_toolbar.x - wpos_x + margin_l + header_l, ImGui.GetCursorPosY(ctx) + 3)
    ImGui.SetNextItemWidth(ctx, 227) --math.min(220, app_ctx.main_toolbar.w - margin_l * 2 - header_l))
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 4, 2)
    local b, v = ImGui.InputTextWithHint(ctx, "##search_input", "Terms...", self.parent_overlay.filter_str,  ImGui.InputTextFlags_NoHorizontalScroll | ImGui.InputTextFlags_AutoSelectAll | ImGui.InputTextFlags_ParseEmptyRefVal )
    if b then
        self.parent_overlay.filter_str = v
        self.parent_overlay:applySearch(true)
    end
    ImGui.PopStyleVar(ctx)

    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + 2)

    -- Settings button
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 1, 1)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    if ImGui.ImageButton(ctx, "##settings_button", app_ctx:getImage("settings"), 16, 16) then
        ImGui.SameLine(ctx)
        self.parent_overlay:toggleSettingsWindow(wpos_x, wpos_y)
    end

    if ImGui.IsItemHovered(ctx) then
        ImGui.SetTooltip(ctx, "Settings")
    end

    ImGui.PopStyleVar(ctx, 2)
    ImGui.PopFont(ctx)

    -- LOGO LOGIC
    local align             = 320
    local remaining_space   = app_ctx.main_toolbar.w - align

    local font_size = math.floor(remaining_space * 26/180.0 + 0.5)
    if font_size > 26 then font_size = 26 end
    if font_size < 16 then font_size = 16 end

    ---@diagnostic disable-next-line: redundant-parameter
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

function OverlayCanvas:thingBelongsToThisCanvas(thing)
    if self.type == OverlayCanvas.TYPES.REAPER_MAIN_AND_MIXER then
        return true
    elseif self.type == OverlayCanvas.TYPES.REAPER_MIXER_ALONE then
        return thing.widget == "mcp"
    else
        return thing.widget ~= "mcp"
    end
end

function OverlayCanvas:stickerSize()
    return PS.RetrieveProjectStickerSize()
end

function OverlayCanvas:renderThingSlotPoster(thing, slot, ctx, draw_list, x1, x2, y1, y2)
    if slot == -1 then return end

    local type = thing.notes:resolvedSlotPosterType(slot)

    if type == D.POSTER_TYPES.NO_POSTER then return end

    local h    = y2 - y1
    local vpad = (h > 40) and 5 or math.floor( math.max(h - 20) / 4.0)
    local hpad = 5
    local poster_w = x2-x1-2*hpad
    local poster_h = y2-y1-2*vpad

    if poster_w <= 0 or poster_h <= 0 then return end

    local window_flags = ImGui.WindowFlags_NoBackground |
        ImGui.WindowFlags_NoScrollbar |
        ImGui.WindowFlags_NoDecoration |
        ImGui.WindowFlags_NoDocking |
        ImGui.WindowFlags_NoFocusOnAppearing |
        ImGui.WindowFlags_NoInputs |
        ImGui.WindowFlags_NoSavedSettings |
        ImGui.WindowFlags_NoMove

    ImGui.SetCursorScreenPos(ctx, x1 + hpad, y1 + vpad)
    if ImGui.BeginChild(ctx, "thing_poster_wrapper_" .. thing.rand .. "_" .. slot, poster_w, poster_h, ImGui.ChildFlags_None, window_flags) then
        ImGui.SetCursorPos(ctx, 0, 0)

        if not thing.cache.posters then
            thing.cache.posters = {}
        end

        -- Create cache or reset it if needed
        if not thing.cache.posters[slot] or thing.cache.posters[slot].last_type ~= type then
            thing.cache.posters[slot] = { plain = nil, mdwidget = nil, last_type = type }
        end

        local cache         = thing.cache.posters[slot]
        local is_plain_text = (type == D.POSTER_TYPES.CUSTOM_PLAIN_POSTER or type == D.POSTER_TYPES.NOTE_RENDERERED_AS_PLAIN_POSTER)
        local use_note_text = (type == D.POSTER_TYPES.NOTE_RENDERERED_AS_PLAIN_POSTER or type == D.POSTER_TYPES.NOTE_RENDERERED_AS_MARKDOWN_POSTER)

        if is_plain_text  then
            if not cache.plain then
                local tttext    = (use_note_text and thing.notes:slotText(slot) or thing.notes:slotCustomPoster(slot)) or ''
                cache.plain = ImGuiMdText.ASTToPlainText( ImGuiMdAst(tttext), {newlines=true})
            end
            ImGui.Text(ctx, cache.plain)
        else
            if not cache.mdwidget then
                local tttext    = (use_note_text and thing.notes:slotText(slot) or thing.notes:slotCustomPoster(slot)) or ''
                cache.mdwidget = ImGuiMd:new(ctx, "thing_md_widget_" .. thing.rand .. "_" .. slot, {wrap = false, skip_last_whitespace = true, autopad = true, additional_window_flags = ImGui.WindowFlags_NoSavedSettings | ImGui.WindowFlags_NoFocusOnAppearing | ImGui.WindowFlags_NoInputs | ImGui.WindowFlags_NoScrollbar }, PS.RetrieveProjectMarkdownStyle() )
                cache.mdwidget:setText(tttext)
            end
            cache.mdwidget:render(ctx)
        end
        ImGui.EndChild(ctx)
    end
end

function OverlayCanvas:renderThingSlotStickers(thing, slot, ctx, x1, x2, y1, y2)
    local slot_stickers = thing.notes:slotStickers(slot)

    if #slot_stickers > 0 then

        -- RENDER STICKERS
        local hmargin       = 5
        local vmargin       = 5
        local vpad          = 4
        local hpad          = 3
        local font_size     = self.sticker_size

        -- Reduce margins and the font size if not enough vertical space
        if y2 - y1 < font_size + 10 + 2 * vmargin then
            vmargin = 0.5 * ((y2 - y1) - font_size - 10)
            if vmargin < 0 then
                vmargin = 0
                font_size = font_size - 2
            end
        end

        local num_on_line = 0
        local cursor_x, cursor_y = x2 - hmargin, y1 + vmargin -- Align top right

        ImGui.SetCursorScreenPos(ctx, x1, y1)
        local window_flags =  ImGui.WindowFlags_NoBackground |
            ImGui.WindowFlags_NoScrollbar |
            ImGui.WindowFlags_NoDecoration |
            ImGui.WindowFlags_NoDocking |
            ImGui.WindowFlags_NoFocusOnAppearing |
            ImGui.WindowFlags_NoInputs |
            ImGui.WindowFlags_NoSavedSettings |
            ImGui.WindowFlags_NoMove

        -- Use a child for receiving all stickers, this will allow clipping and using standard ImGui directives
        if ImGui.BeginChild(ctx, "stickers_for_thing_" .. thing.rand .. "_" .. slot, x2-x1, y2-y1, ImGui.ChildFlags_None, window_flags) then
            ImGui.SetCursorPos(ctx, 0, 0)
            local draw_list = ImGui.GetWindowDrawList(ctx)
            ImGui.DrawList_PushClipRect(draw_list, x1 + 3, y1 + 3, x2 + 3, y2 - 3)
            for _, sticker in ipairs(slot_stickers) do
                local metrics = sticker:PreRender(ctx, font_size)

                local available_width = cursor_x - (x1 + hmargin)
                if num_on_line ~= 0 and (available_width < metrics.width) then
                    cursor_x = x2 - hmargin
                    cursor_y = cursor_y + metrics.height + vpad
                    num_on_line = 0
                end

                sticker:Render(ctx, metrics, cursor_x - metrics.width, cursor_y)
                cursor_x = cursor_x - metrics.width - hpad
                num_on_line = num_on_line + 1
            end
            -- Force ImGui to extend bounds
            ImGui.DrawList_PopClipRect(draw_list)
            ImGui.Dummy(ctx,0,0)

            ImGui.EndChild(ctx)
        end
    end
end

function OverlayCanvas:drawVisibleThing(thing)
    local app_ctx           = AppContext.instance()
    local parent_overlay    = self.parent_overlay
    local note_editor       = parent_overlay.note_editor
    local ctx               = app_ctx.imgui_ctx
    local sinalpha          = (0x50 + math.floor(0x40 * math.sin((reaper.time_precise())*10)))
    local draw_list         = ImGui.GetWindowDrawList(ctx)

    -- The following method allows to work on an entry which is present in the MCP and TCP at the same time
    local hovered           = parent_overlay.hovered_thing and parent_overlay.hovered_thing.object == thing.object
    local edited            = note_editor and note_editor.edited_thing.object == thing.object

    if not hovered then
        -- reset hovered slot
        thing.hovered_slot = nil
    end

    -- Calculate the number of divisions
    local divisions             = 0
    local has_notes_to_show     = false
    for i=0, D.MAX_SLOTS - 1 do
        local is_slot_blank                 = thing.notes:isSlotBlank(i)
        local is_slot_enabled               = app_ctx.enabled_category_filters[i + 1]
        local the_slot_matches_the_search   = (thing.cache.search_results[i + 1])
        if (not is_slot_blank) and is_slot_enabled and the_slot_matches_the_search then
            divisions         = divisions + 1
            has_notes_to_show = true
        end
    end

    -- We should always show one division, even no note is shown
    if divisions == 0 then
        divisions = 1
    end

    local mx, my    = ImGui.GetMousePos(ctx)
    local xs        = thing.pos_x + thing.parent.x
    local ys        = thing.pos_y + thing.parent.y
    local ww        = thing.width
    local hh        = thing.height

    local hdivide   = (thing.widget == "arrange") or (thing.widget == "tcp") or (thing.widget == "time_ruler") or (thing.widget == "transport")
    local step      = (hdivide) and (ww * 1.0 / divisions) or (hh * 1.0 / divisions)

    local div = -1
    for i=0, D.MAX_SLOTS-1 do
        -- We change the slot span order (1,2,3... and then 0)
        local is_no_note_slot               = (i==0 and not has_notes_to_show)

        local slot                          = (i==D.MAX_SLOTS - 1) and (0) or (i+1)
        local is_slot_enabled               = (is_no_note_slot or app_ctx.enabled_category_filters[slot + 1])

        local the_slot_matches_the_search   = (thing.cache.search_results[slot+1])

        -- The empty slot is always visible
        local is_slot_visible   = (is_no_note_slot) or (not thing.notes:isSlotBlank(slot) and is_slot_enabled and the_slot_matches_the_search)

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

                local base_color_with_note  = D.SlotColor(slot) << 8 --0xFF007000
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
                        local no_notes_message = ""

                        if thing.notes:isBlank() then
                            no_notes_message = "`:grey:No " .. thing.cache.type .. " notes`"
                        else
                            no_notes_message = "`:grey:All notes hidden`"
                        end

                        -- This is dangerous, but don't really have the choice with the current model :/
                        thing.hovered_slot = -1
                        thing.no_notes_message = no_notes_message
                    end
                end
            end

            local it_s_the_edited_slot                              = (edited and note_editor.edited_slot == slot)
            local there_s_no_editor_open_but_the_slot_is_hovered    = (not note_editor and hovered and thing.hovered_slot == slot)
            local hovering_something_that_cant_have_notes           = (hovered and is_no_note_slot)

            if it_s_the_edited_slot or there_s_no_editor_open_but_the_slot_is_hovered or hovering_something_that_cant_have_notes then
                bg_color        = (bg_color & 0xFFFFFF00) | sinalpha
                border_color    = (border_color & 0xFFFFFF00) | (sinalpha + 0x60)
            end

            -- Background color.
            ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x2, y2, bg_color, 0, 0)

            if not is_no_note_slot then
                self:renderThingSlotPoster(thing, slot, ctx, draw_list, x1, x2, y1, y2)
            end

            -- Borders and triangles
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
                if not thing.clamped_top then
                    ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x2, y1 + border_width, border_color, 0, 0)
                end
                if not thing.clamped_bottom then
                    ImGui.DrawList_AddRectFilled(draw_list, x1, y2 - border_width, x2, y2, border_color, 0, 0)
                end
            else
                if div == 0 and not thing.clamped_top then
                    ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x2, y1 + border_width, border_color, 0, 0)
                end
                if div == divisions - 1 and not thing.clamped_bottom then
                    ImGui.DrawList_AddRectFilled(draw_list, x1, y2 - border_width, x2, y2, border_color, 0, 0)
                end
                ImGui.DrawList_AddRectFilled(draw_list, x1, y1, x1 + border_width, y2, border_color, 0, 0)
                ImGui.DrawList_AddRectFilled(draw_list, x2 - border_width, y1, x2, y2, border_color, 0, 0)
            end

            if not is_no_note_slot then
                self:renderThingSlotStickers(thing, slot, ctx, x1, x2, y1, y2)

                -- Post-it triangles
                if not (div == 0 and thing.clamped_left) then
                    local ts = triangle_size * ((div == 0) and 1 or 0.7)
                    ImGui.DrawList_AddTriangleFilled(draw_list, x1, y1, x1 + ts, y1, x1, y1 + ts, border_color)
                    ImGui.DrawList_AddTriangleFilled(draw_list, x1, y2, x1, y2 - ts, x1 + ts, y2, border_color)
                end

                if not (div == divisions - 1 and thing.clamped_right) then
                    local ts = triangle_size * ((div == divisions - 1) and 1 or 0.7)
                    ImGui.DrawList_AddTriangleFilled(draw_list, x2 - ts, y1, x2, y1, x2, y1 + ts, border_color)
                    ImGui.DrawList_AddTriangleFilled(draw_list, x2, y2, x2 - ts, y2, x2, y2 - ts, border_color)
                end
            end
        end
    end
end

function OverlayCanvas:GrabFocus()
    self.grab_focus = true
end

function OverlayCanvas:draw()
    local parent_overlay = self.parent_overlay
    local visible_things = parent_overlay.visible_things

    local app_ctx        = AppContext.instance()
    local ctx            = app_ctx.imgui_ctx
    local mx, my         = ImGui.GetMousePos(ctx)

    -- Retrive every frame
    self.sticker_size    = self:stickerSize()

    self.draw_count      = self.draw_count or 0
    self.has_focus       = false

    local parent_win = self:parentWindowInfo()

    ImGui.SetNextWindowSize(ctx, parent_win.w, parent_win.h)
    ImGui.SetNextWindowPos(ctx, parent_win.x, parent_win.y)
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
    ImGui.WindowFlags_NoDecoration |
    ImGui.WindowFlags_NoSavedSettings)

    ImGui.PopStyleVar(ctx)

    if succ then

        local draw_list      = ImGui.GetWindowDrawList(ctx)

        if self.grab_focus then
            ImGui.SetWindowFocus(ctx)
            self.grab_focus = false
        end

        self:ensureHwnd()
        self:forwardMouseWheelEvents()

        if ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootWindow) and not(ImGui.IsAnyItemActive(ctx)) then --  and ImGui.IsWindowFocused(ctx)
            if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape, false) or (app_ctx.shortcut_was_released_once and app_ctx.launch_context:isShortcutStillPressed()) then
                app_ctx.want_quit = true
            end
        end

        -- Black background, for alpha see above
        ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0x000000FF)

        if self:isMain() then
            self:drawQuickSettings()
        end

        for _, thing in ipairs(visible_things) do
            if self:thingBelongsToThisCanvas(thing) then
                local x1        = thing.pos_x + thing.parent.x
                local y1        = thing.pos_y + thing.parent.y
                local x2        = x1 + thing.width
                local y2        = y1 + thing.height
                local hovered   = x1 <= mx and mx <= x2 and y1 <= my and my <= y2
                if hovered and ImGui.IsWindowHovered(ctx) then
                    parent_overlay.hovered_thing_this_frame = thing
                    parent_overlay.hovered_thing            = thing
                end
            end
        end

        -- Draw border + bg
        for _, thing in ipairs(visible_things) do
            if self:thingBelongsToThisCanvas(thing) then
                self:drawVisibleThing(thing)
            end
        end

        if ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootWindow) then
            if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left,false) then
                parent_overlay.captured_click = true
            end
            if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right,false) then
                parent_overlay.captured_right_click = true
            end
        end

        ImGui.PopStyleColor(ctx)
        ImGui.End(ctx)

    else
        -- Emergency exit
        app_ctx.want_quit = true
    end

    -- Update draw count
    self.draw_count = self.draw_count + 1
end


return OverlayCanvas

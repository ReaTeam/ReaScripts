-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui             = require "ext/imgui"
local AppContext        = require "classes/app_context"
local Notes             = require "classes/notes"
local SettingsEditor    = require "widgets/settings_editor"

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
    local visible_things    = self.parent_overlay.visible_things

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

    ImGui.SetNextItemWidth(ctx, 218) --math.min(220, app_ctx.main_toolbar.w - margin_l * 2 - header_l))
    local b, v      = ImGui.InputText(ctx, "##search_input", self.parent_overlay.filter_str, ImGui.InputTextFlags_NoHorizontalScroll | ImGui.InputTextFlags_AutoSelectAll | ImGui.InputTextFlags_ParseEmptyRefVal )
    if b then
        self.parent_overlay.filter_str = v
        for ti, thing in ipairs(visible_things) do
            self.parent_overlay:applySearchToThing(thing)
        end
    end
    if self.parent_overlay.filter_str == "" then
        local sx, sy    = ImGui.GetItemRectMin(ctx)
        ImGui.DrawList_AddText(draw_list, sx + 5, sy + 1, 0xA0A0A0FF, "Terms ...")
    end

    ImGui.SameLine(ctx)
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + 4)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 1, 1)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 2)
    if ImGui.ImageButton(ctx, "##settings_button", app_ctx:getImage("settings"), 17, 17) then
        ImGui.SameLine(ctx)
        if app_ctx.settings_window then
            self.parent_overlay.settings_window = nil
        else
            self.parent_overlay.settings_window = SettingsEditor:new()
            self.parent_overlay.settings_window:setPosition(wpos_x + ImGui.GetCursorPosX(ctx) + 5, wpos_y + ImGui.GetCursorPosY(ctx) )
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

function OverlayCanvas:thingBelongsToThisCanvas(thing)
    if self.type == OverlayCanvas.TYPES.REAPER_MAIN_AND_MIXER then
        return true
    elseif self.type == OverlayCanvas.TYPES.REAPER_MIXER_ALONE then
        return thing.widget == "mcp"
    else
        return thing.widget ~= "mcp"
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

            local it_s_the_edited_slot                              = (edited and note_editor.edited_slot == slot)
            local there_s_no_editor_open_but_the_slot_is_hovered    = (not note_editor and hovered and thing.hovered_slot == slot)
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

function OverlayCanvas:GrabFocus()
    self.grab_focus = true
end


function OverlayCanvas:draw()
    local parent_overlay = self.parent_overlay
    local visible_things = parent_overlay.visible_things

    local app_ctx        = AppContext.instance()
    local ctx            = app_ctx.imgui_ctx
    local mx, my         = ImGui.GetMousePos(ctx)

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
        ImGui.WindowFlags_NoDecoration
    )

    ImGui.PopStyleVar(ctx)

    if succ then

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

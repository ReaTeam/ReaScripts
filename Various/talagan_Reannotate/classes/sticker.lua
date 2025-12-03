-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui         = require "ext/imgui"
local JSON          = require "ext/json"
local AppContext    = require "classes/app_context"
local EmojImGui     = require "emojimgui"
local Color         = require "classes/color"
local D             = require "modules/defines"

local Sticker = {}
Sticker.Types = {
    SPECIAL   = 0,
    STANDARD  = 1
}

-- String format: "type:detail"
-- type == 0, detail = category|checkboxes
-- type == 1, detail = icon_string:text
--            icon_string = font:char (font = nothing|0|1)

Sticker.__index = Sticker

function Sticker:new(packed_code, notes, slot)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(packed_code, notes, slot)
    return instance
end

function Sticker:_initialize(packed_code, notes, slot)
    local ret       = self:_parseHelper(packed_code)

    local fname = "OpenMoji"
    if ret.icon_font == 1 then fname = "TweMoji" end

    self.type       = ret.type
    self.icon       = EmojImGui.Asset.CharInfo(fname, ret.icon) -- May be nil
    self.text       = ret.text

    self:attachToNotesAndSlot(notes, slot)
end

function Sticker:attachToNotesAndSlot(notes, slot)
    self.notes      = notes
    self.slot       = slot

    self.color      = slot and (D.SlotColor(slot) << 8 | 0xFF) or 0xA0A000FF
    self.text_color = 0x000000FF
end

function Sticker:_parseHelper(str)

    local function next_token(s)
        local colon_pos   = s:find(":")
        local token       = s:sub(1, colon_pos - 1)
        local rest        = s:sub(colon_pos + 1)
        return token, rest
    end

    local token, rest = next_token(str)
    local type = tonumber(token)

    if type == Sticker.Types.SPECIAL then
        local text = rest
        local icon = nil
        local font = nil

        if text == 'checkboxes' then
            font = 1
            icon = "2611"
        end

        return {
            type = type,
            text = rest,
            icon = icon,
            icon_font = font
        }
    elseif type == Sticker.Types.STANDARD then
        token, rest       = next_token(rest)
        local font        = tonumber(token)
        token, rest       = next_token(rest)

        return {
            type      = type,
            icon_font = font,
            icon      = token,
            text      = rest
        }
    end
end

function Sticker:textToRender()
    local text = self.text
    if self.type == Sticker.Types.SPECIAL then
        if text == 'category' then
            text = (self.slot) and (D.SlotLabel(self.slot)) or ("???")
        elseif text == "checkboxes" then
            if not self.notes then
                text = "? / ?"
            else
                local counts = self.notes:slotCheckboxCache(self.slot)
                counts.c = counts.c or 0
                counts.t = counts.t or 0
                text = "" .. counts.c .. " / " .. counts.t
            end
        end
    end

    return text
end

function Sticker:iconToRender()
    if not self.icon then return nil end

    if self.type == Sticker.Types.SPECIAL and self.text == 'checkboxes' then
        local counts = self.notes:slotCheckboxCache(self.slot)
        counts.c = counts.c or 0
        counts.t = counts.t or 0
        return EmojImGui.Asset.CharInfo(self.icon.font_name, (counts.c == counts.t) and ("2705") or ((counts.c == 0) and "2714" or "2611") ).utf8
    end

    return self.icon.utf8
end


function Sticker:isSpecial()
    return self.type == Sticker.Types.SPECIAL
end

function Sticker:hasIcon()
    return not (self.icon == nil)
end

function Sticker:hasText()
    return not (self.text == '' or self.text == nil)
end

function Sticker:isEmpty()
    return (not self:hasIcon()) and (not self:hasText())
end

function Sticker:computeIconBackgroundColor(base_color_rgba, alpha)
    local c         = Color:new(base_color_rgba >> 8)
    local h,s,l     = c:hsl()
    c:setHsl(h, s * 0.6, 0.15 + 0.15 * alpha)
    return (c:to_irgba() & 0xFFFFFFFF)
end

function Sticker:computeTextBackgroundColor(base_color_rgba, alpha)
    local c     = Color:new(base_color_rgba >> 8)
    local h,s,l = c:hsl()
    l = math.min(1, l * 1.1 + alpha * 0.2 * l)
    c:setHsl(h,s, l)
    return (c:to_irgba() & 0xFFFFFFFF)
end

function Sticker:renderBackground(draw_list, render_params)
    local istop     = render_params.metrics.icon_stop
    local min_x     = render_params.metrics.min_x
    local min_y     = render_params.metrics.min_y
    local max_x     = render_params.metrics.max_x
    local max_y     = render_params.metrics.max_y
    local v_pad     = render_params.metrics.v_pad
    local has_text  = self:hasText()

    local alpha         = 0
    local icon_bg_color = 0
    local text_bg_color = 0

    if render_params.metrics.hovered then
        alpha   = math.sin(reaper.time_precise()*10)
        icon_bg_color = self:computeIconBackgroundColor(render_params.color, alpha)
        text_bg_color = self:computeTextBackgroundColor(render_params.color, alpha)
    else
        -- USe a cache because this will be recomputed a lot and it costs a lot
        Sticker.icon_bg_color_cache = Sticker.icon_bg_color_cache or {}
        Sticker.icon_bg_color_cache[render_params.color] = Sticker.icon_bg_color_cache[render_params.color] or self:computeIconBackgroundColor(render_params.color, 0)
        icon_bg_color = Sticker.icon_bg_color_cache[render_params.color]

        Sticker.text_bg_color_cache = Sticker.text_bg_color_cache or {}
        Sticker.text_bg_color_cache[render_params.color] = Sticker.text_bg_color_cache[render_params.color] or self:computeTextBackgroundColor(render_params.color, 0)
        text_bg_color = Sticker.text_bg_color_cache[render_params.color]
    end

    if self.icon then
        -- Icon Background
        ImGui.DrawList_AddRectFilled(draw_list, min_x, min_y - v_pad, max_x, max_y + v_pad, icon_bg_color, 2)

        if has_text then
            -- Use istop - 1 it's a dirty centering correction
            ImGui.DrawList_PushClipRect (draw_list, min_x + istop - 1, min_y - v_pad, max_x, max_y + v_pad, true)
        end
    end

    -- Flashing background
    if has_text then
        ImGui.DrawList_AddRectFilled  (draw_list, min_x, min_y - v_pad, max_x, max_y + v_pad, text_bg_color, 2)
    end

    if self.icon then
        if has_text then
            ImGui.DrawList_PopClipRect(draw_list)
        end
    end
end

function Sticker:renderForeground(draw_list, render_params)
    local istop     = render_params.metrics.icon_stop
    local min_x     = render_params.metrics.min_x
    local min_y     = render_params.metrics.min_y
    local max_x     = render_params.metrics.max_x
    local max_y     = render_params.metrics.max_y
    local v_pad     = render_params.metrics.v_pad
    local has_text  = self:hasText()

    local function _fullBorder(color)
        ImGui.DrawList_AddRect(draw_list, min_x, min_y - v_pad, max_x, max_y + v_pad, color, 1, 0, 1)
    end

    if self.icon then
        if has_text then
            _fullBorder(render_params.color)
        else
            _fullBorder(render_params.color)
        end
    else
        _fullBorder(render_params.color)
    end
end


-- First call to calculate metrics
-- Second call to draw
function Sticker:_renderPass(ctx, font_size, should_render, render_params)

    local sticker           = self

    local app_ctx           = AppContext.instance()
    local draw_list         = ImGui.GetWindowDrawList(ctx)

    local has_text          = self:hasText()
    local icon_font_size    = font_size + 0.5

    local icon_text_spacing = font_size / 4.0 + 0.5
    local h_pad             = math.floor(font_size / 2   + 0.5)
    local v_pad             = font_size/20.0
    local sticker_spacing   = 1 * font_size - 2

---@diagnostic disable-next-line: redundant-parameter
    ImGui.PushFont(ctx, app_ctx.arial_font, font_size)
    local base_text_height  = ImGui.GetTextLineHeightWithSpacing(ctx)
    local widget_height     = base_text_height + 2 * v_pad
    ImGui.PopFont(ctx)

    local metrics           = nil

    -- Those params should only be used in render mode
    local min_x, min_y      = 0, 0
    local max_x, max_y      = 0, 0
    local istop             = 0

    if should_render then
        metrics         = render_params.metrics
        min_x, min_y    = render_params.xstart, render_params.ystart
        max_x, max_y    = min_x + metrics.width, min_y + metrics.height
        metrics.min_x   = min_x
        metrics.min_y   = min_y
        metrics.max_x   = max_x
        metrics.max_y   = max_y

        local mx, my = ImGui.GetMousePos(ctx)
        if ImGui.IsWindowHovered(ctx) and (min_x <= mx and mx <= max_x and min_y <= my and my <= max_y) then
            metrics.hovered = true
        end
    end

    local xcursor = 0

    -- Rendering of icons or texts helper
    local  _textPass = function(_font, _font_size, _txt)
---@diagnostic disable-next-line: redundant-parameter
        ImGui.PushFont(ctx, _font, _font_size)
        local www, hhh    = ImGui.CalcTextSize(ctx, _txt)
        local diff_height = (hhh - base_text_height)

        if should_render then
            ImGui.DrawList_AddText(draw_list, min_x + xcursor, min_y + v_pad - diff_height * 0.5, render_params.text_color, _txt)
        end

        xcursor = xcursor + www
        ImGui.PopFont(ctx)
    end

    if should_render then
        self:renderBackground(draw_list, render_params)
    end

    if sticker.icon then
        local font = EmojImGui.Asset.Font(ctx, sticker.icon.font_name)
        xcursor = xcursor + icon_text_spacing
        -- Draw the icon
        _textPass(font, icon_font_size, self:iconToRender())
        xcursor = xcursor + icon_text_spacing
        istop   = xcursor

        if has_text then
            xcursor = xcursor + icon_text_spacing
        end
    else
        xcursor = xcursor + h_pad
    end

    -- Render / Measure main text
    if has_text then
        _textPass(app_ctx.arial_font, font_size, sticker:textToRender())
        xcursor = xcursor + h_pad
    end

    local widget_width  = xcursor
    local max_x, max_y  = min_x + widget_width, min_y + widget_height

    if should_render then
        self:renderForeground(draw_list, render_params)
    end

    if should_render then
        ImGui.SetCursorScreenPos(ctx, max_x, min_y)
    end

    if should_render then
---@diagnostic disable-next-line: need-check-nil
        return metrics.hovered
    else
        -- Return metrics
        return {
            width       = widget_width,
            height      = widget_height,
            spacing     = sticker_spacing,
            icon_stop   = istop,
            v_pad       = v_pad,
            h_pad       = h_pad,
            font_size   = font_size
        }
    end
end

-- Should be called to calculate the widget metrics, that will be passed to render
function Sticker:PreRender(ctx, font_size)
    return self:_renderPass(ctx, font_size, false)
end

-- Render. Call pre-render to get metrics.
function Sticker:Render(ctx, pre_render_metrics, xstart, ystart)
    return self:_renderPass(ctx, pre_render_metrics.font_size, true, { metrics = pre_render_metrics, xstart = xstart, ystart = ystart, color = self.color, text_color = self.text_color } )
end

function Sticker:pack()
    if self.type == Sticker.Types.SPECIAL then
        return "" .. self.type .. ":" .. self.text
    else
        local icon_str = ":"
        if self.icon then
            local fid = (self.icon.font_name == "TweMoji") and 1 or 0
            icon_str = "" .. fid .. ":" .. self.icon.id
        end

        return "" .. self.type .. ":" .. icon_str .. ":" .. self.text
    end
end

function Sticker.NormalizeCollection(coll, remove_specials)
    local lookup = {}
    local valid  = {}
    local lib    = coll

    lib = lib or {}

    for _, sticker in ipairs(lib) do
        -- Remove empty stickers and special stickers
        if not sticker:isEmpty() and not (sticker:isSpecial() and remove_specials) then
            -- Remove duplicated stickers
            local sid = sticker:pack()
            if not lookup[sid] then
                lookup[sid]     = sticker
                valid[#valid+1] = sticker
            end
        end
    end

    table.sort(valid, function(sticker1, sticker2)
        if sticker1.type == Sticker.Types.SPECIAL then
            if sticker2.type == Sticker.Types.SPECIAL then
                return sticker1.text < sticker2.text
            else
                return true
            end
        elseif sticker2.type == Sticker.Types.SPECIAL then
            return false
        else
            if not sticker1:hasText() then
                if not sticker2:hasText() then
                    -- Compare icon strings
                    return sticker1.icon.id < sticker2.icon.id
                else
                    return true
                end
            elseif not sticker2:hasText() then
                return false
            else
                -- Everyone has text
                return string.lower(sticker1.text) < string.lower(sticker2.text)
            end
        end
    end)

    return valid
end

function Sticker.NormalizeLibrary(lib)
    return Sticker.NormalizeCollection(lib, true)
end

function Sticker.UnpackCollection(collection, notes, slot)
    local slot_stickers_unpacked = {}
    for _, stick in ipairs(collection) do
        slot_stickers_unpacked[#slot_stickers_unpacked+1] = Sticker:new(stick, notes, slot)
    end
    slot_stickers_unpacked = Sticker.NormalizeCollection(slot_stickers_unpacked, false)
    return slot_stickers_unpacked
end

function Sticker.PackCollection(collection)
    local packed = {}
    for _, sticker in ipairs(collection) do
        packed[#packed+1] = sticker:pack()
    end
    return packed
end

function Sticker.Library(notes, slot)
    local lib_str = reaper.GetExtState("Reannotate", "StickerLibrary")
    local ret = nil

    pcall(function()
        ret = JSON.decode(lib_str)
    end)
    ret = ret or {}

    local stickers = {}
    for _, sl in ipairs(ret) do
        local s = nil
        -- Safe unserialize...
        pcall(function() s = Sticker:new(sl, notes, slot) end)
        if s then
            stickers[#stickers+1] = s
        end
    end

    return Sticker.NormalizeLibrary(stickers)
end

function Sticker.StoreLibrary(lib)
    local packed = Sticker.PackCollection(Sticker.NormalizeLibrary(lib))

    local lib_str = JSON.encode(packed)
    reaper.SetExtState("Reannotate", "StickerLibrary", lib_str, true)

    return lib
end



return Sticker

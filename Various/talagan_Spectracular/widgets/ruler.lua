-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"
local T     = require "widgets/theme"

local RulerWidget = {}
RulerWidget.__index = RulerWidget

-- sample_rate is the sample rate of the signal to anayse
function RulerWidget:new(mw)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(mw)
    return instance
end

function RulerWidget:_initialize(mw)
    self.mw = mw
end

function RulerWidget:setSpectrumContext(spectrum_context)
    self.sc = spectrum_context
end

function RulerWidget:setCanvas(x,y,w,h)
    self.canvas_pos_changed    = not (self.x == x and self.y == y)
    self.canvas_size_changed   = not (self.w == w and self.h == h)
    self.canvas_changed        = self.canvas_pos_changed or self.canvas_size_changed

    self.x = x
    self.y = y
    self.w = w
    self.h = h
end

function RulerWidget:containsPoint(mx, my)
    return mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
end

function RulerWidget:startClipping(draw_list)
    ImGui.DrawList_PushClipRect(draw_list,  self.x, self.y, self.x + self.w, self.y + self.h, true)
end

function RulerWidget:stopClipping(draw_list)
    ImGui.DrawList_PopClipRect(draw_list)
end

function RulerWidget:draw(ctx)
    local draw_list = ImGui.GetWindowDrawList(ctx)
    local mx, my    = ImGui.GetMousePos(ctx)

    self:startClipping(draw_list)
    ImGui.DrawList_AddRectFilled(draw_list,  self.x, self.y, self.x + self.w, self.y + self.h, T.RULER_BG)
    ImGui.DrawList_AddLine(draw_list,        self.x, self.y + self.h -1 , self.x + self.w, self.y + self.h - 1 , T.RMSE_BORDER)

    local time  = self.mw.spectrograph_widget:xToTime(mx)
    local txt   = reaper.format_timestr_pos(time, '', 1)

    local tw, _ = ImGui.CalcTextSize(ctx, txt)

    if self.align_right == nil then self.align_right = true end

    local mgx   = 5

    if not self.align_right then
        if mx - mgx - tw < self.x then
            self.align_right = true
        end
    else
        if mx + mgx + tw > self.x + self.w then
            self.align_right = false
        end
    end
    local posx = mx + mgx
    if not self.align_right then posx = mx - mgx - tw end


    ImGui.DrawList_AddText(draw_list, posx, self.y + 2, T.H_CURSOR, txt)

    self:stopClipping(draw_list)

    if self:containsPoint(mx, my) then
        self.overrides_mouse_cursor = ImGui.MouseCursor_None
    else
        self.overrides_mouse_cursor = nil
    end

    self.canvas_changed = false
    self.canvas_pos_changed = false
    self.canvas_size_changed = false
end

function RulerWidget:onGridTickDraw(spectrograph, draw_list, t)
    if not t.is_measure then return end
    local xp = spectrograph:timeToX(t.time)
    if xp < 0 or xp > self.x + self.w then return end

    self:startClipping(draw_list)
    ImGui.DrawList_AddText(draw_list, xp + 5 , self.y + 3, T.NOTE_GRID_C, "" .. t.measure_num)
    self:stopClipping(draw_list)
end

return RulerWidget

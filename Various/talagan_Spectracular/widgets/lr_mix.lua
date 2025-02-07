-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"
local T     = require "widgets/theme"
local S     = require "modules/settings"
local UTILS = require "modules/utils"

local LRMix = {}
LRMix.__index = LRMix

-- sample_rate is the sample rate of the signal to anayse
function LRMix:new(mw)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(mw)
    return instance
end

function LRMix:_initialize(mw)
    self.mw = mw
    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0
end

function LRMix:isEnabled()
    return (self.mw.sc.chan_count == 2)
end

function LRMix:containsPoint(mx, my)
    if not (self:isEnabled()) then return false end

    return (mx >= self.x) and (mx <= self.x + self.w) and (my >= self.y)and (my <= self.y + self.h)
end

function LRMix:calculateBounds()
    local spec      = self.mw.spectrograph_widget

    self.w  = 80
    self.h  = 20

    local rmargin = 30

    self.x = spec.x + spec.w - rmargin - self.w
    self.y = spec.y + spec.h - self.h - 2
end

function LRMix:draw(ctx)
    local draw_list = ImGui.GetWindowDrawList(ctx)
    local mx, my    = ImGui.GetMousePos(ctx)

    if not (self:isEnabled()) then return end

    self:calculateBounds()

    ImGui.DrawList_AddRectFilled(draw_list, self.x, self.y, self.x + self.w, self.y + self.h, T.DRAWER_BG)
    ImGui.DrawList_AddText(draw_list, self.x+4,         self.y+3, T.SLICE_CURVE_L, "L")
    ImGui.DrawList_AddText(draw_list, self.x+self.w-10, self.y+3, T.SLICE_CURVE_R, "R")

    -- The following mouse handler should be called before draw to have  instantaneous draw feedback
    if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Right) then
        if self:containsPoint(mx,my) then
            S.instance_params.lr_balance = 0.5
            self.mw:setLRBalance(S.instance_params.lr_balance)
        end
    end

    local sx = self.x + 20
    local ex = self.x + self.w - 20
    local midx = sx + S.instance_params.lr_balance * (ex - sx)
    local cw = 3
    local cp = 4

    local cl = midx - cw
    local cr = midx + cw
    local ct = self.y + self.h - cp
    local cb = self.y + cp

    ImGui.DrawList_AddLine(draw_list, sx, self.y + self.h * 0.5, midx, self.y + self.h * 0.5, T.SLICE_CURVE_L)
    ImGui.DrawList_AddLine(draw_list, midx, self.y + self.h * 0.5, ex, self.y + self.h * 0.5, T.SLICE_CURVE_R)
    ImGui.DrawList_AddRectFilled(draw_list, cl, ct, cr, cb, T.LR_MIX_BUTTON )

    -- Left click
    if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
        if self:containsPoint(mx, my) then
            if mx < sx then mx = sx end
            if mx > ex then mx = ex end
            S.instance_params.lr_balance = (mx - sx) * 1.0 / (ex - sx)
            self.dragged = {
                mx = mx,
                my = my
            }
        end
    end

    if ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left) and self.dragged then
        if mx < sx then mx = sx end
        if mx > ex then mx = ex end
        S.instance_params.lr_balance = (mx - sx) * 1.0 / (ex - sx)
    end

    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then
        if self.dragged then
            -- Validate modification
            self.mw:setLRBalance(S.instance_params.lr_balance)
        end
        self.dragged = nil
    end

    if UTILS.isMouseStalled(1.0) and self:containsPoint(mx,my) then
        ImGui.SetTooltip(ctx, "Click/Drag to change the mix between L/R channels\n\nRight click to reset to mid.")
    end
end

return LRMix

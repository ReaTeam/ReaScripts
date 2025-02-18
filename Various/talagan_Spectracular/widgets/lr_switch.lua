-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"
local T     = require "widgets/theme"
local S     = require "modules/settings"
local UTILS = require "modules/utils"

local LRSwitch = {}
LRSwitch.__index = LRSwitch

-- sample_rate is the sample rate of the signal to anayse
function LRSwitch:new(mw)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(mw)
    return instance
end

function LRSwitch:_initialize(mw)
    self.mw = mw
    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0
end

function LRSwitch:containsPoint(mx, my)
    return mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
end

function LRSwitch:chanModeColors()
    local bgl = UTILS.colToBgCol(T.SLICE_CURVE_L, 1, 1)
    local bgr = UTILS.colToBgCol(T.SLICE_CURVE_R, 1, 1)

    if S.instance_params.chan_mode == 1 then
        return bgl, bgl
    elseif S.instance_params.chan_mode == 2 then
        return bgr, bgr
    end
    return bgl, bgr
end

function LRSwitch:chanModeText()
    local ret = "LR"
    if S.instance_params.chan_mode == 1 then
        ret = "L"
    elseif S.instance_params.chan_mode  == 2 then
        ret = "R"
    end
    return ret
end

function LRSwitch:draw(ctx)
    local draw_list = ImGui.GetWindowDrawList(ctx)

    local sac = self.mw.sc

    if sac.chan_count == 1 then
        S.instance_params.chan_mode = 0
        return
    end

    self.w = 36
    self.h = 14
    self.x = self.mw.rmse_widget.x + self.mw.rmse_widget.w - self.w - 31
    self.y = self.mw.rmse_widget.y + self.mw.rmse_widget.h - 20

    local lcol, rcol       = self:chanModeColors()
    local text             = self:chanModeText()
    local tw, th           = ImGui.CalcTextSize(ctx, text)
    local mx, my           = ImGui.GetMousePos(ctx)

    ImGui.DrawList_AddRectFilledMultiColor(draw_list, self.x, self.y, self.x + self.w, self.y + self.h, lcol, rcol, rcol, lcol)
    ImGui.DrawList_AddText(draw_list, self.x + self.w / 2 - tw / 2, self.y + self.h/2 - th / 2, 0x000000FF, text)

    if self:containsPoint(mx, my) then
        self.mw.rmse_widget.overrides_mouse_cursor = ImGui.MouseCursor_Hand

        if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then

            S.instance_params.chan_mode = S.instance_params.chan_mode + 1
            if S.instance_params.chan_mode > sac.chan_count then
                S.instance_params.chan_mode = 0
            end

            -- Disabling this behaviour (sync LR mix with LR switch)
            -- S.instance_params.lr_balance = (S.instance_params.chan_mode == 0) and (0.5) or (S.instance_params.chan_mode - 1)
            -- self.mw:setLRBalance(S.instance_params.lr_balance)
        end
        if UTILS.isMouseStalled(1.0) then
            ImGui.SetTooltip(ctx, "Click to change channel mode for curves")
        end
    end
end

return LRSwitch
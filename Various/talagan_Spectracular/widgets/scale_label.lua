-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"
local T     = require "widgets/theme"
local S     = require "modules/settings"
local UTILS = require "modules/utils"

local ScaleLabel = {}
ScaleLabel.__index = ScaleLabel

-- sample_rate is the sample rate of the signal to anayse
function ScaleLabel:new(parent_widget, data_type, chan, min_or_max)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(parent_widget, data_type, chan, min_or_max)
    return instance
end

function ScaleLabel:_initialize(parent_widget, data_type, chan, min_or_max)
    self.parent_widget  = parent_widget
    self.data_type      = data_type
    self.chan           = chan
    self.min_or_max     = min_or_max
end

function ScaleLabel:calcGeometry(ctx)

    local px, py         = 1, 1 -- padding
    local mgx, mgy       = 2, 3 -- margin

    -- Geometry is calculated from the parent rmse widget
    local text           = self:text()
    local rw             = self.parent_widget
    local chan_mode      = S.instance_params.chan_mode
    local top_align      = self:resolveTopAlign()
    local right_align    = self.data_type == "rmse"
    local sac            = rw.mw.sc
    local sh             = math.floor(0.5 * rw.h)

    self.tw, self.th     = ImGui.CalcTextSize(ctx, text)
    self.px, self.py     = px, py

    self.w              = 2 * px + self.tw
    self.h              = 2 * py + self.th

    -- X corner
    self.x = 0
    if right_align then
        self.x = rw.x + rw.w - mgx - self.w - 1
    else
        self.x = rw.x + mgx
    end

    -- Y corner
    self.y = 0
    if sac.chan_count == 1 or (sac.chan_count == 2) and (chan_mode ~= 0) then
        -- Mono, or stereo but in single channel mode
        self.y = (top_align) and (rw.y + mgy) or (rw.y + rw.h - mgy - self.h - 1)
    else
        local offy  = (self.chan - 1) * sh
        self.y = ((top_align) and (rw.y + mgy) or (rw.y + sh - mgy - self.h - 1)) + offy
    end
end

function ScaleLabel:containsPoint(mx,my)
    return (mx >= self.x) and (my >= self.y) and (mx <= self.x + self.w) and (my <= self.y + self.h)
end

function ScaleLabel:val()
    if self.data_type == "rmse" then
        if self.min_or_max == "min" then
            return S.instance_params.rms_dbmin
        else
            return S.instance_params.rms_dbmax
        end
    else
        if self.min_or_max == "min" then
            return S.instance_params.dbmin
        else
            return S.instance_params.dbmax
        end
    end
end

function ScaleLabel:setVal(v)
    if self.data_type == "rmse" then
        if self.min_or_max == "min" then
            S.instance_params.rms_dbmin = v
            S.setSetting("RMSDbMin", v)
        else
            S.instance_params.rms_dbmax = v
            S.setSetting("RMSDbMax", v)
        end
        self.parent_widget.mw:setRMSDbBounds(S.instance_params.rms_dbmin, S.instance_params.rms_dbmax)
    else
        if self.min_or_max == "min" then
            S.instance_params.dbmin = v
            S.setSetting("DbMin", v)
        else
            S.instance_params.dbmax = v
            S.setSetting("DbMax", v)
        end
        self.parent_widget.mw:setDbBounds(S.instance_params.dbmin, S.instance_params.dbmax)
    end
end


function ScaleLabel:text()
    if self.should_reset_after_draw then
        return "" .. self:defaultVal()
    end

    if self.drag_val then
        return "" .. self.drag_val
    end

    return "" .. self:val()
end

function ScaleLabel:resolveTopAlign()
    local rw             = self.parent_widget
    local sac            = rw.mw.sc
    local chan_mode      = S.instance_params.chan_mode

    if sac.chan_count == 1 then
        -- Mono
        return self.min_or_max == "max"
    end

    if sac.chan_count == 2 then
        -- Stereo
        if chan_mode == 0 then
            -- All
            if self.chan == 1 then return self.min_or_max == "max" end
            if self.chan == 2 then return self.min_or_max == "min" end
        else
            -- Single chan
            return self.min_or_max == "max"
        end
    end

    return false
end

function ScaleLabel:color()
    return (self.chan == 1) and (T.SLICE_CURVE_L) or (T.SLICE_CURVE_R)
end

function ScaleLabel:handleMouseEvents(ctx)
    local rw             = self.parent_widget
    local mx, my         = ImGui.GetMousePos(ctx)
    local inside         = self:containsPoint(mx, my)

    if inside then
        rw.is_hovering_a_label = true
        rw.overrides_mouse_cursor = ImGui.MouseCursor_Arrow
        --if UTILS.modifierKeyIsDown() then
            if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
                rw.overrides_mouse_cursor = ImGui.MouseCursor_ResizeNS
                rw.dragged = {
                    mx = mx,
                    my = my,
                    new_mx = mx,
                    new_my = my,
                    val = self:val(),
                    target_mode = "db_adjust",
                    target = self
                }
            end
        --end
        if UTILS.isMouseStalled(1.0) then
            local tt = "Click+Drag to modify the "

            if self.data_type == "rmse" then
                tt = tt .. "RMSE curve"
            else
                tt = tt .. "frequency profiles"
            end

            if self.min_or_max == "min" then
                tt = tt .. " minimum limit"
            else
                tt = tt .. " maximum limit"
            end

            tt = tt .. "\n\nRight click to reset to default value"

            if self.data_type == "freq" then
                tt = tt .. "\n\nThis also affects the color scale of the spectrograph"
            end

            ImGui.SetTooltip(ctx, tt)
        end
    end

    if inside and ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Right) then
        self.should_reset_after_draw = true
    end

    if rw.dragged and rw.dragged.target_mode == "db_adjust" then
        rw.overrides_mouse_cursor = ImGui.MouseCursor_ResizeNS
        if rw.dragged.target == self then
            rw.dragged.new_mx = mx
            rw.dragged.new_my = my
            rw.dragged.target:onAdjustLevel()
        end
    end

    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then
        if rw.dragged and rw.dragged.target and rw.dragged.target_mode == "db_adjust" then
            rw.dragged.target:onFinishAdjustingLevel()
        end

        rw.dragged = nil
    end

    if not rw.dragged then
        self.drag_val = nil
    end
end

function ScaleLabel:isReversed()
    local rw             = self.parent_widget
    local sac            = rw.sc
    local chan_mode      = S.instance_params.chan_mode
    return (chan_mode == 0) and (sac.chan_count == 2) and (self.chan == 2)
end

function ScaleLabel:draw(ctx, draw_list)

    local chan_mode      = S.instance_params.chan_mode

    if chan_mode ~= 0 and chan_mode ~= self.chan then
        return
    end

    self.should_reset_after_draw = false

    local mx, my    = ImGui.GetMousePos(ctx)
    local col       = self:color()

    self:calcGeometry(ctx)

    self:handleMouseEvents(ctx)

    if self.should_reset_after_draw then
        -- The reset click will change the text and thus the geometry of the label
        self:calcGeometry(ctx)
    end

    local bgcol = T.DRAWER_BG
    if(self.drag_val) then
        bgcol = UTILS.colToBgCol(col, 1.0, 0.3)
    elseif self:containsPoint(mx, my) then
        bgcol = UTILS.colToBgCol(col, 1.0, 0.6)
    end

    -- Draw
    ImGui.DrawList_AddRectFilled(draw_list, self.x, self.y, self.x + self.w, self.y + self.h, bgcol)
    ImGui.DrawList_AddText(draw_list, self.x + self.px, self.y + self.py, col, self:text())

    if self.should_reset_after_draw then
        self:setVal(self:defaultVal())
    end
end


function ScaleLabel:maxVal()
    if self.min_or_max == "min" then
        if self.data_type == "rmse" then
            return S.instance_params.rms_dbmax
        else
            return S.instance_params.dbmax
        end
    end
    return 6
end

function ScaleLabel:minVal()
    if self.min_or_max == "max" then
        if self.data_type == "rmse" then
            return S.instance_params.rms_dbmin
        else
            return S.instance_params.dbmin
        end
    end
    return -90
end

function ScaleLabel:defaultVal()
    if self.min_or_max == "max" then return 0 end

    return -45
end

function ScaleLabel:onAdjustLevel()
    local rw = self.parent_widget

    if not rw.dragged or not rw.dragged.target == self then return end

    local dy = rw.dragged.my - rw.dragged.new_my
    local sign = (self:isReversed()) and -1 or 1
    self.drag_val = self:val() + sign * dy / 2

    self.drag_val = math.floor(0.5 + math.min(self.drag_val, self:maxVal()))
    self.drag_val = math.floor(0.5 + math.max(self.drag_val, self:minVal()))
end

function ScaleLabel:onFinishAdjustingLevel()
    self:setVal(self.drag_val)
end

return ScaleLabel
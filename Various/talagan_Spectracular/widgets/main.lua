-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"

local UTILS                     = require "modules/utils"

local SpectrographWidget        = require "widgets/spectrograph"
local RmseWidget                = require "widgets/rmse"
local TicksOverlay              = require "widgets/ticks_overlay"
local RulerWidget               = require "widgets/ruler"
local LRSwitch                  = require "widgets/lr_switch"

local MainWidget = {}
MainWidget.__index = MainWidget

-- sample_rate is the sample rate of the signal to anayse
function MainWidget:new()
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()
    return instance
end

function MainWidget:_initialize()

    if not self.spectrograph_widget  then self.spectrograph_widget = SpectrographWidget:new(self) end
    if not self.rmse_widget          then self.rmse_widget         = RmseWidget:new(self)         end
    if not self.ticks_overlay        then self.ticks_overlay       = TicksOverlay:new(self)       end
    if not self.ruler_widget         then self.ruler_widget        = RulerWidget:new(self)        end
    if not self.lr_switch            then self.lr_switch           = LRSwitch:new(self)           end
    self.rmse_height = 160

    self:setCanvas(0,0,0,0)
    self:setDbBounds(-90, 6)
    self:setLRBalance(0.5)

    self.mvzoom = 1
    self.mvoff  = 0
end

function MainWidget:setRmseHeight(rmse_height)
    self.rmse_height = rmse_height
    self:setCanvas(self.x, self.y, self.w, self.h)
end

function MainWidget:setCanvas(x,y,w,h)
    self.canvas_pos_changed    = not (self.x == x and self.y == y)
    self.canvas_size_changed   = not (self.w == w and self.h == h)
    self.canvas_changed        = self.canvas_pos_changed or self.canvas_size_changed

    self.x = x
    self.y = y
    self.w = w
    self.h = h

    local rmse_height           = self.rmse_height
    local ruler_height          = 20
    local header_height         = rmse_height + ruler_height
    local spectrograph_height   = self.h - header_height
    local tick_overlay_height   = self.h

    -- The layout is subject to change, update the spectrograph's canvas
    self.rmse_widget:setCanvas           (x, y,                    w, rmse_height)
    self.ruler_widget:setCanvas          (x, y + rmse_height,      w, ruler_height)
    self.spectrograph_widget:setCanvas   (x, y + header_height,    w, spectrograph_height)
    self.ticks_overlay:setCanvas         (x, y,                    w, tick_overlay_height)
end

function MainWidget:setSpectrumContext(spectrum_context)
    self.sc = spectrum_context

    self.rmse_widget:setSpectrumContext(spectrum_context)
    self.spectrograph_widget:setSpectrumContext(spectrum_context)
    self.ruler_widget:setSpectrumContext(spectrum_context)
    self.ticks_overlay:setSpectrumContext(spectrum_context)
end

function MainWidget:spectrumContext()
    return self.sc
end

function MainWidget:setDbBounds(dbmin, dbmax)
    self.spectrograph_widget:setDbBounds(dbmin, dbmax)
end

function MainWidget:setRMSDbBounds(dbmin, dbmax)
    self.spectrograph_widget:setRMSDbBounds(dbmin, dbmax)
end

function MainWidget:setLRBalance(bal)
    self.lr_balance = bal

    self.spectrograph_widget:setLRBalance(bal)
end

function MainWidget:containsPoint(mx, my)
    return mx >= self.x and mx < self.x + self.w and my >= self.y and my < self.y + self.h
end

function MainWidget:prehemptsMouse()
    return not (self.drag_info == nil)
end

function MainWidget:draw(ctx)
    local sac = self:spectrumContext()
    if not sac then return end

    local mx, my = ImGui.GetMousePos(ctx)

    if self:containsPoint(mx,my) then
        local is_on_drawer_resizer = self.spectrograph_widget:containsPoint(mx,my) and
            (mx >= self.spectrograph_widget.x + self.spectrograph_widget.w - self.spectrograph_widget.drawer_width - 5) and
            (mx <= self.spectrograph_widget.x + self.spectrograph_widget.w - self.spectrograph_widget.drawer_width + 5)

        if is_on_drawer_resizer then
            if UTILS.modifierKeyIsDown() then
                self.overrides_mouse_cursor = ImGui.MouseCursor_ResizeEW
                if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left)  then
                    self.drag_info = {
                        x           = mx,
                        y           = my,
                        operation   = "drawer_resize"
                    }
                end
            end
        else
            self.overrides_mouse_cursor = nil
        end

        if self.ruler_widget:containsPoint(mx,my) then
            if UTILS.modifierKeyIsDown() then
                self.overrides_mouse_cursor = ImGui.MouseCursor_ResizeNS
                if ImGui.IsMouseClicked(ctx, ImGui.MouseButton_Left) then
                    self.drag_info = {
                        x           = mx,
                        y           = my,
                        rmse_height = self.rmse_height,
                        operation   = "rmse_widget_resize"
                    }
                end
            end
        end
    end

    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) then
        self.drag_info = nil
    end

    if ImGui.IsMouseDragging(ctx, ImGui.MouseButton_Left) then
        if self.drag_info then
            if self.drag_info.operation == "drawer_resize" then
                local new_drawer_size = self.x + self.w - mx
                if new_drawer_size < 50             then new_drawer_size = 50 end
                if new_drawer_size > (self.w - 50)  then new_drawer_size = (self.w - 50) end
                self.spectrograph_widget:setDrawerWidth(new_drawer_size)
            elseif self.drag_info.operation == "rmse_widget_resize" then
                local dy                    = self.drag_info.y - my
                local new_rmse_widget_size  = self.drag_info.rmse_height - dy

                if new_rmse_widget_size < 100               then new_rmse_widget_size = 100 end
                if new_rmse_widget_size > (self.h - 100)    then new_rmse_widget_size = (self.h - 100) end
                self:setRmseHeight(new_rmse_widget_size)
            end

        end
    end

    self.spectrograph_widget:draw    (ctx)
    self.rmse_widget:draw            (ctx)
    self.ruler_widget:draw           (ctx)
    self.ticks_overlay:draw          (ctx)

    -- Other overlays to draw
    self.spectrograph_widget:drawProfileLines(ctx)
    self.spectrograph_widget:drawTooltip(ctx)
    self.ticks_overlay:drawReaperCursors(ctx)
    self.rmse_widget:drawTopLayer(ctx)
    self.lr_switch:draw(ctx)
    self.spectrograph_widget:drawLRMix(ctx)

    self.rmse_widget:endOfDraw(ctx)
    self.spectrograph_widget:endOfDraw(ctx)
    self.ticks_overlay:endOfDraw(ctx)

    local cursor = self.overrides_mouse_cursor or self.spectrograph_widget.overrides_mouse_cursor or
        self.rmse_widget.overrides_mouse_cursor or
        self.ticks_overlay.overrides_mouse_cursor or
        self.ruler_widget.overrides_mouse_cursor

    if cursor then
        ImGui.SetMouseCursor(ctx, cursor)
    else
        ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Arrow)
    end

    self.canvas_changed = false
    self.canvas_pos_changed = false
    self.canvas_size_changed = false
end


return MainWidget

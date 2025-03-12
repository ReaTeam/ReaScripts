-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"

local UTILS             = require "modules/utils"
local S                 = require "modules/settings"

local T                 = require "widgets/theme"
local ScaleLabel        = require "widgets/scale_label"
local SpectrographTimeProfile = require "widgets/profiles/spectrograph_time_profile"

local RmseWidget = {}
RmseWidget.__index = RmseWidget

-- sample_rate is the sample rate of the signal to anayse
function RmseWidget:new(mw)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(mw)
    return instance
end

function RmseWidget:_initialize(mw)
    self:setCanvas(0,0,0,0)

    self.mw         = mw

    self.mvzoom     = 1
    self.mvoff      = 0
end

function RmseWidget:setSpectrumContext(spectrum_context)
    self.sc = spectrum_context
end

function RmseWidget:spectrumContext()
    return self.sc
end

function RmseWidget:setCanvas(x,y,w,h)
    self.canvas_pos_changed    = not (self.x == x and self.y == y)
    self.canvas_size_changed   = not (self.w == w and self.h == h)
    self.canvas_changed        = self.canvas_pos_changed or self.canvas_size_changed

    self.x = x
    self.y = y
    self.w = w
    self.h = h
end

function RmseWidget:chanMode()
    return S.instance_params.chan_mode
end

function RmseWidget:containsPoint(mx, my)
    return  (mx >= self.x) and (mx <= self.x + self.w) and (my >= self.y) and (my <= self.y + self.h)
end

function RmseWidget:drawButton(ctx, text, corner_x, corner_y, width, pad_x, pad_y, align_right, align_bottom, col, bg_col, bg_col2, callback, rcallback)
    local draw_list = ImGui.GetWindowDrawList(ctx)
    local mx, my    = ImGui.GetMousePos(ctx)

    local tw, th    = ImGui.CalcTextSize(ctx, text)

    local ww = width
    local xx = corner_x
    local yy = corner_y
    local px = pad_x
    local py = pad_y

    if align_right then
        xx = xx - ww - 2 * px
    end

    if align_bottom then
        yy = yy - 2 * py - th
    end

    local xxx = xx + 2 * px + ww
    local yyy = yy + 2 * py + th

    local hv = (mx >= xx) and (mx <= xxx) and (my >= yy) and (my <= yyy)

    if hv then
        self.overrides_mouse_cursor = ImGui.MouseCursor_Hand

        if UTILS.isMouseStalled(1.0) then
            local tt = "Click to show/hide the associated curve"
            if not align_right then tt = tt .. "\n\nRight click to remove this profile" end
            ImGui.SetTooltip(ctx, tt)
        end
    end

    -- Draw small interactive label
    if bg_col2 then
        ImGui.DrawList_AddRectFilledMultiColor(draw_list, xx, yy, xxx, yyy, bg_col, bg_col2, bg_col2, bg_col)
    else
        ImGui.DrawList_AddRectFilled(draw_list, xx, yy, xxx, yyy, bg_col)
    end

    if col then
        ImGui.DrawList_AddRect(draw_list, xx, yy, xxx, yyy, col)
    end
    ImGui.DrawList_AddText(draw_list, xx + px + ww/2 - tw/2, yy + py, col or 0x000000FF, text)

    -- Mouse interaction with small label
    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Left) and hv and callback then
       callback()
    end

    if ImGui.IsMouseReleased(ctx, ImGui.MouseButton_Right) and hv and rcallback then
        rcallback()
    end
end

function RmseWidget:getLabelPlacingInfo(ctx)
    if self.label_placing_info then return self.label_placing_info end

    local sac   = self.mw.spectrograph_widget.sc
    local _, th = ImGui.CalcTextSize(ctx, "Toto")

    local ww = 90 -- Mono
    if sac.chan_count == 2 then ww = 170 end -- Stereo
    if sac.chan_count > 2  then ww = 100 + sac.chan_count * 150 end -- Probably wrong, TODO when doing multi chan > 2

    self.label_placing_info = {
        yt      = 3,     -- Placing info for the veil
        xt      = 26,    -- H margin for the the veil (slip the scale)

        bw      = 26,    -- Button width

        veil_w  = ww,

        px      = 5,     -- Horizontal padding for the label
        py      = 1,     -- Vertical padding for the label

        iv      = 2,     -- Vertical spacing between labels
        th      = th     -- Text height inside labels
    }
    return self.label_placing_info
end

function RmseWidget:drawTimeProfileLabel(ctx, profile, stacki)
    local s             = profile

    if stacki >= 0 then
        local pf            = self:getLabelPlacingInfo(ctx)
        local align_right   = s.type == SpectrographTimeProfile.Types.RMSE
        local align_bottom  = false
        if align_right then  stacki = stacki + 1 end

        local cx            = (not align_right) and (self.x + pf.xt + 5) or (self.x + self.w - pf.xt - 5)
        local cy            = self.y + pf.yt + ( (stacki-1) * (pf.th + 2 * pf.py + pf.iv) )
        local text          = s:label()
        local bgcol         = (s.enabled) and UTILS.colToBgCol(s.color, 0.5, 0.9) or (T.TOOLTIP_BG)
        local col           = s.color
        local cb            = function() s.enabled = not s.enabled end
        local rcb           = function()
            local torem = nil
            for pi, p in ipairs(self.mw.spectrograph_widget.extracted_profiles) do
                if p == profile then
                    torem = pi
                    break
                end
            end
            if torem then table.remove(self.mw.spectrograph_widget.extracted_profiles, torem) end
        end

        self:drawButton(ctx, text, cx, cy, pf.bw, pf.px, pf.py, align_right, align_bottom, col, bgcol, nil, cb, rcb)
    end
end

function RmseWidget:drawTimeProfileCurve(ctx, profile, line_width)
    local draw_list     = ImGui.GetWindowDrawList(ctx)
    local s             = profile

    if s.enabled then
        -- Draw all channels
        for ci, draw_curve in pairs(s.draw_curves) do
            if (self:chanMode() == 0) or (self:chanMode() == ci)then
                ImGui.DrawList_AddPolyline(draw_list, draw_curve , s.color, 0, line_width)
            end
        end
    end
end

function RmseWidget:drawTimeProfileCurves(ctx)
    local spectrograph  = self.mw.spectrograph_widget

    -- RMSE Curve
    spectrograph.rmse_draw_profile:buildDrawCurves(self.x, self.y+1, self.w, self.h-2, self:chanMode())
    self:drawTimeProfileCurve(ctx, spectrograph.rmse_draw_profile, 1)

    -- Cursor Note profile ; draw before other ones to avoid glitching when pinning curve
    if spectrograph.want_draw_cursor_profile then
        -- Always refresh the color of the cursor profile (because it may change due to profile pinning / deleting)
        spectrograph.cursor_draw_profile:setColorIdx(spectrograph:firstAvailableProfileColorIdx())
        spectrograph.cursor_draw_profile:buildDrawCurves(self.x, self.y+1, self.w, self.h-2, self:chanMode())
        self:drawTimeProfileCurve(ctx, spectrograph.cursor_draw_profile, 2)
    end

    -- Extracted profiles curves
    for i, s in pairs(spectrograph.extracted_profiles) do
        s:buildDrawCurves(self.x, self.y+1, self.w, self.h-2, self:chanMode())
        self:drawTimeProfileCurve(ctx, s, 2)
    end
end

function RmseWidget:shouldShowDbInfo(ctx)
    local mx, my        = ImGui.GetMousePos(ctx)

    --return self:containsPoint(mx,my)
    return self.mw:containsPoint(mx,my)
end

function RmseWidget:drawVeils(ctx)
    local spectrograph  = self.mw.spectrograph_widget
    local draw_list     = ImGui.GetWindowDrawList(ctx)
    local pf            = self:getLabelPlacingInfo(ctx)

    if self:shouldShowDbInfo(ctx) then
        local pcount = #spectrograph.extracted_profiles
        if spectrograph.want_draw_cursor_profile then
            pcount = pcount + 1
        end

        local hh = pf.yt + ( (pcount) * (pf.th + 2 * pf.py + pf.iv) )

        -- Left veil
        ImGui.DrawList_AddRectFilled(draw_list,
            self.x + 1 + pf.xt,
            self.y + 1,
            self.x + pf.xt + 1 + pf.veil_w,
            self.y + math.min(self.h - 2, hh),
            T.DRAWER_BG)

        -- Right veil
        ImGui.DrawList_AddRectFilled(draw_list,
            self.x + self.w - 26 - pf.veil_w - 2 * pf.px,
            self.y + 1,
            self.x + self.w - 26,
            self.y + pf.yt + pf.th + 2 * pf.py + pf.iv,
            T.DRAWER_BG)
    end
end

function RmseWidget:drawTimeProfileDbInfo(ctx, draw_list, sac, time, s, si)
    local pf            = self:getLabelPlacingInfo(ctx)
    local align_right   = (si == 0)
    local mx, my        = ImGui.GetMousePos(ctx)

    if not align_right then
        si = si - 1
    end

    local iv            = pf.iv
    local px, py        = pf.px, pf.py
    local th            = pf.th
    local xcur          = (align_right) and (self.x + self.w - 26 - pf.veil_w) or (self.x + pf.xt + 50) -- Add 50 for the label
    local cy            = self.y + 3 + ( si * (th + 2 * py + iv) ) + py

    for ci=1, sac.chan_count do
        local v = 0

        if s.type == SpectrographTimeProfile.Types.NOTE then    v = sac:getValueAt(ci, s.note_num, time)
        else                                                    v = sac:getRmseValueAt(ci, time)
        end

        if sac.chan_count == 2 then
            if ci == 1 then ImGui.DrawList_AddText(draw_list, xcur, cy, T.SLICE_CURVE_L, "L") end
            if ci == 2 then ImGui.DrawList_AddText(draw_list, xcur, cy, T.SLICE_CURVE_R, "R") end

            xcur = xcur + 14
        end

        local dbtx = UTILS.dbValToString(v)
        ImGui.DrawList_AddText(draw_list, xcur, cy, s.color, dbtx)
        xcur = xcur + 38

        if not (ci == sac.chan_count) then
            ImGui.DrawList_AddText(draw_list, xcur, cy, 0xC0C0C0FF,  "|")
            xcur = xcur + 10
        end
    end
end

function RmseWidget:drawTimeProfileDbInfos(ctx)
    local spectrograph  = self.mw.spectrograph_widget
    local sac           = spectrograph.sc
    local draw_list     = ImGui.GetWindowDrawList(ctx)
    local mx, my        = ImGui.GetMousePos(ctx)

    -- Mouse cursor
    if self:shouldShowDbInfo(ctx) then
        local time          = spectrograph:xToTime(mx)

        if time > self.mw.sc.signal.start and time < self.mw.sc.signal.stop then
            -- Db info for the RMSE
            if spectrograph.want_draw_cursor_profile or self:containsPoint(mx, my) then
                self:drawTimeProfileDbInfo(ctx, draw_list, sac, time, spectrograph.rmse_draw_profile, 0)
            end

            -- DB info for the extracted_profiles
            for i, s in pairs(spectrograph.extracted_profiles) do
                self:drawTimeProfileDbInfo(ctx, draw_list, sac, time, s, i)
            end
        end

        -- DB info for the cursor
        if spectrograph.want_draw_cursor_profile then
            self:drawTimeProfileDbInfo(ctx, draw_list, sac, time, spectrograph.cursor_draw_profile, #spectrograph.extracted_profiles + 1)
        end
    end
end

function RmseWidget:drawTimeProfileLabels(ctx)
    local spectrograph  = self.mw.spectrograph_widget

    self:drawTimeProfileLabel(ctx, spectrograph.rmse_draw_profile, 0)

    for i, s in pairs(spectrograph.extracted_profiles) do
        self:drawTimeProfileLabel(ctx, s, i)
    end

    if spectrograph.want_draw_cursor_profile then
        self:drawTimeProfileLabel(ctx, spectrograph.cursor_draw_profile, #spectrograph.extracted_profiles + 1)
    end
end

function RmseWidget:draw(ctx)
    local sac           = self:spectrumContext()

    if not sac then return end

    local draw_list     = ImGui.GetWindowDrawList(ctx)

    local mx, my        = ImGui.GetMousePos(ctx)

    -- Background
    ImGui.DrawList_AddRectFilled(draw_list, self.x, self.y, self.x + self.w, self.y + self.h, T.RMSE_BG)
    -- Borders
    ImGui.DrawList_AddRect(draw_list,       self.x, self.y, self.x + self.w, self.y + self.h, T.RMSE_BORDER)

    -- Horizontal lines
    if self:chanMode() == 0 then
        local chan_height = math.floor(self.h * 1.0 / sac.chan_count)
        for i=1, sac.chan_count - 1 do
            ImGui.DrawList_AddLine(draw_list, self.x, self.y + chan_height, self.x + self.w, self.y + chan_height, T.NOTE_GRID_C)
        end
    end

    -- Do this first, because labels may override this
    self.overrides_mouse_cursor = self:containsPoint(mx, my) and ImGui.MouseCursor_None or nil

    self:drawTimeProfileCurves(ctx)

    if self:containsPoint(mx,my) then
        -- Horizontal line cursor
        ImGui.DrawList_AddLine(draw_list, self.x, my, self.x + self.w, my, T.RMSE_H_CURSOR)
    end
end

function RmseWidget:buildScaleLabelsIfNeeded()
    if not self.scaleLabels then
        self.scaleLabels = {}
        for ci=1, self.sc.chan_count do
            self.scaleLabels[#self.scaleLabels+1] = ScaleLabel:new(self, "rmse", ci, "min")
            self.scaleLabels[#self.scaleLabels+1] = ScaleLabel:new(self, "rmse", ci, "max")
            self.scaleLabels[#self.scaleLabels+1] = ScaleLabel:new(self, "freq", ci, "min")
            self.scaleLabels[#self.scaleLabels+1] = ScaleLabel:new(self, "freq", ci, "max")
        end
    end
end

function RmseWidget:drawScales(ctx)
    local spectrograph  = self.mw.spectrograph_widget
    local sac           = spectrograph.sc
    local draw_list     = ImGui.GetWindowDrawList(ctx)

    if sac.chan_count > 2 then return end -- TODO

    self.is_hovering_a_label = false
    self:buildScaleLabelsIfNeeded()
    for _, scale in ipairs(self.scaleLabels) do
        scale:draw(ctx, draw_list)
    end
end

function RmseWidget:drawTopLayer(ctx)
    self:drawVeils(ctx)
    self:drawTimeProfileLabels(ctx)
    self:drawScales(ctx)
    self:drawTimeProfileDbInfos(ctx)
end

function RmseWidget:endOfDraw(ctx)
    self.canvas_changed         = false
    self.canvas_pos_changed     = false
    self.canvas_size_changed    = false
end

return RmseWidget

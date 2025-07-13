-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- This class handles all vertical bars (time ticks : measure, beats)

local MIN_WIDTH_FOR_BEATS    = 6
local MIN_WIDTH_FOR_MEASURES = 12

local ImGui = require "ext/imgui"
local T = require "widgets/theme"

local TicksOverlay = {}
TicksOverlay.__index = TicksOverlay

-- sample_rate is the sample rate of the signal to anayse
function TicksOverlay:new(mw)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(mw)
    return instance
end

function TicksOverlay:_initialize(mw)
    self.mw = mw
end

function TicksOverlay:setSpectrumContext(spectrum_context)
    self.sc = spectrum_context
end

function TicksOverlay:spectrumContext()
    return self.sc
end

function TicksOverlay:setCanvas(x, y, w, h)
    self.canvas_pos_changed = not (self.x == x and self.y == y)
    self.canvas_size_changed = not (self.w == w and self.h == h)
    self.canvas_changed = self.canvas_pos_changed or self.canvas_size_changed

    self.x = x
    self.y = y
    self.w = w
    self.h = h
end

function TicksOverlay:containsPoint(mx, my)
    return mx >= self.x and mx <= self.x + self.w and my >= self.y and my <= self.y + self.h
end

function TicksOverlay:drawTick(spectrograph, draw_list, time, color, thickness)
    local xp = spectrograph:timeToX(time)

    -- Tick is not in the displayed window
    if xp < self.x or xp > self.x + self.w then
        return
    end

    ImGui.DrawList_AddLine(draw_list, xp, self.y, xp, self.y + self.h, color, thickness or 1.0)
end

function TicksOverlay:drawGrid(ctx)
    local draw_list = ImGui.GetWindowDrawList(ctx)

    local spectrograph = self.mw.spectrograph_widget
    local ruler = self.mw.ruler_widget

    local ticks = {}

    local view_bounds = spectrograph:viewBounds()

    local _, grid_w, swing, _           = reaper.GetSetProjectGrid(0, false)
    local qns                           = reaper.TimeMap_timeToQN(view_bounds.time_start)
    local meas_num, meas_qns, meas_qne  = reaper.TimeMap_QNToMeasures(0, qns)
    local tick_qn                       = meas_qns
    local tick_time                     = reaper.TimeMap_QNToTime(tick_qn or 0)
    local second_tick_time              = reaper.TimeMap_QNToTime((tick_qn or 0) + 1)
    local endmeas_tick_time             = reaper.TimeMap_QNToTime(meas_qne or 0)

    local tick_pix_width                = spectrograph:timeToX(second_tick_time)  - spectrograph:timeToX(tick_time)
    local meas_pix_width                = spectrograph:timeToX(endmeas_tick_time) - spectrograph:timeToX(tick_time)

    local show_beats                    = (tick_pix_width >= MIN_WIDTH_FOR_BEATS)
    local show_all_measures             = (meas_pix_width >= MIN_WIDTH_FOR_MEASURES)

    local grid_qn = grid_w * 4

    while meas_num and tick_time <= view_bounds.time_stop do
        ticks[#ticks + 1] = {time = tick_time, is_measure = (tick_qn == meas_qns), measure_num = meas_num, odd = ( (meas_num % 2) == 1) }

        tick_qn = tick_qn + grid_qn -- Todo : handle swing
        tick_time = reaper.TimeMap_QNToTime(tick_qn)

        local new_meas_qns
        meas_num, new_meas_qns, _ = reaper.TimeMap_QNToMeasures(0, tick_qn)

        if not (new_meas_qns == meas_qns) then
            -- Measure change
            meas_qns = new_meas_qns
            tick_qn = meas_qns
            tick_time = reaper.TimeMap_QNToTime(tick_qn or 0)
        end
    end

    for _, t in ipairs(ticks) do
        if (t.is_measure and (t.odd or show_all_measures)) or show_beats then
            self:drawTick(spectrograph, draw_list, t.time, (t.is_measure and T.TICK_MEASURE or T.TICK_GRID))
            ruler:onGridTickDraw(spectrograph, draw_list, t)
        end
    end
end

function TicksOverlay:drawCursor(ctx, draw_list)
    local sac = self:spectrumContext()
    if not sac then
        return
    end

    local spectrograph = self.mw.spectrograph_widget
    local mx, my = ImGui.GetMousePos(ctx)

    -- If the user is hovering the zone, show some indications
    if
        self:containsPoint(mx, my) and not spectrograph.lr_mix_widget:containsPoint(mx, my) and
            not self.mw.rmse_widget.dragged and
            not self.mw.rmse_widget.is_hovering_a_label
     then
        local mt = spectrograph:xToTime(mx)

        local l = mt - sac:fftHalfWindowDurationForOctava(sac.low_octava)
        local r = mt + sac:fftHalfWindowDurationForOctava(sac.low_octava)

        -- Draw yellow transparent zone to indicate the size of the FFT
        ImGui.DrawList_AddRectFilled(
            draw_list,
            spectrograph:timeToX(l),
            self.y,
            spectrograph:timeToX(r),
            self.y + self.h,
            T.FFT_WINDOW_BG
        )
        self:drawTick(spectrograph, draw_list, mt, T.V_CURSOR, 1)
    end
end

function TicksOverlay:draw(ctx)
    local sac = self:spectrumContext()
    if not sac then
        return
    end

    local draw_list = ImGui.GetWindowDrawList(ctx)

    self:drawGrid(ctx)
    self:drawCursor(ctx, draw_list)
end

function TicksOverlay:endOfDraw(ctx)
    self.canvas_changed = false
    self.canvas_pos_changed = false
    self.canvas_size_changed = false
end

function TicksOverlay:drawReaperCursors(ctx)
    local sac = self:spectrumContext()
    if not sac then
        return
    end

    local spectrograph = self.mw.spectrograph_widget
    local draw_list = ImGui.GetWindowDrawList(ctx)

    -- Reaper's play cursor
    if reaper.GetPlayState() == 1 then
        local p = reaper.GetPlayPosition()
        self:drawTick(spectrograph, draw_list, p, T.PLAY_CURSOR, 2.0)
    end

    -- Reaper's edit cursor
    self:drawTick(spectrograph, draw_list, reaper.GetCursorPosition(), T.EDIT_CURSOR, 2.0)
end

return TicksOverlay

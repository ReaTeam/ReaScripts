-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local T     = require "widgets/theme"
local DSP   = require "modules/dsp"

local FrequencySliceProfile = {}
FrequencySliceProfile.__index = FrequencySliceProfile

FrequencySliceProfile.color_index = 0
FrequencySliceProfile.color_max   = #T.SPECTRO_PROFILES

function FrequencySliceProfile:new(spectrograph, color, type)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(spectrograph, color, type)
    return instance
end

function FrequencySliceProfile:_initialize(spectrograph, color)
    self.color          = color
    self.spectrograph   = spectrograph
    self.data_lines     = {}
    self.draw_curves    = {}
    self.enabled        = true
end

function FrequencySliceProfile:spectrumContext()
    return self.spectrograph.sc
end

function FrequencySliceProfile:buildDataFromTime(time)
    if not time then return end

    self.time = time

    local sac = self:spectrumContext()

    if not (sac.chan_count == #self.data_lines) then self.data_lines = {} end
    for i=1, sac.chan_count do
        self.data_lines[i] = DSP.ensure_array_size(self.data_lines[i], sac.slice_size)
        sac:extractSliceProfile(i, time, self.data_lines[i])
    end

    -- Update timestamp to prevent bounces
    self.data_calc = reaper.time_precise()
end


function FrequencySliceProfile:rebuildData()
    self:buildDataFromTime(self.time)
end

function FrequencySliceProfile:buildDrawCurves(x, y, w, h, drawer_w)
    local sp  = self.spectrograph
    local sac = self:spectrumContext()

    local point_count   = h

    local vp_v_t           = sp.vp_v_t
    local vp_v_b           = sp.vp_v_b

    local zoom_has_changed            = not (vp_v_t == self.last_vp_v_t)  or not (vp_v_b == self.last_vp_v_b)
    local position_has_changed        = not (x == self.last_x)      or not (y == self.last_y)
    local size_has_changed            = not (w == self.last_w)      or not (h == self.last_h)
    local data_has_changed            = not (self.last_data == self.data_calc)
    local db_bounds_have_changed      = not (self.last_dbmin == sp.dbmin) or not (self.last_dbmax == sp.dbmax)

    -- Avoid rebuilding draw points if stalled
    if  not position_has_changed and not zoom_has_changed and not size_has_changed and not data_has_changed and not db_bounds_have_changed then
        return
    end

    if      position_has_changed and not zoom_has_changed and not size_has_changed and not data_has_changed and not db_bounds_have_changed then
        -- Only the position has changed. It's just a translation we can do this fast.
        -- Still necessary, because ImGUI drawlist does not handle relative coordinates ...
        for chan=1, sac.chan_count do
            local diffx = x - self.last_x
            local diffy = y - self.last_y
            DSP.array_op_add_xy(self.draw_curves[chan], diffx, diffy)
        end
    else

        self.slice_buf_src_x = DSP.ensure_array_size(self.slice_buf_src_x, sac.slice_size, function(a)
            DSP.array_fill_01(a)
        end)

        -- Temporaty buffers
        self.slice_buf          = DSP.ensure_array_size(self.slice_buf,         point_count)
        self.slice_buf_dst_x    = DSP.ensure_array_size(self.slice_buf_dst_x,   point_count)

        -- Now, build all sub-curves (1 per channel)
        for chan=1, sac.chan_count do
            local data_line = self.data_lines[chan]

            self.draw_curves[chan] = DSP.ensure_array_size(self.draw_curves[chan], point_count * 2)

            -- Resample and normalize values
            DSP.array_fill_equally(self.slice_buf_dst_x, 1 - vp_v_t, 1 - vp_v_b)
            DSP.resample_curve(self.slice_buf_src_x, data_line, self.slice_buf_dst_x, self.slice_buf, false, "akima")
            DSP.array_op_normalize_min_max(self.slice_buf, sp.dbmin, sp.dbmax)

            -- Put in pixel domain
            DSP.array_op_mult(self.slice_buf, -drawer_w)
            DSP.array_op_add(self.slice_buf, x + w)

            -- Build pixel axis 0,1 -> 0,H
            DSP.array_fill_01(self.slice_buf_dst_x)
            DSP.array_op_mult(self.slice_buf_dst_x, - h)
            DSP.array_op_add(self.slice_buf_dst_x,  h + y)

            DSP.array_interleave(self.draw_curves[chan], self.slice_buf, self.slice_buf_dst_x)
        end
    end

    self.last_x     = x
    self.last_y     = y
    self.last_w     = w
    self.last_h     = h
    self.last_dbmin = sp.dbmin
    self.last_dbmax = sp.dbmax
    self.last_vp_v_t   = vp_v_t
    self.last_vp_v_b   = vp_v_b
    self.last_data  = self.data_calc
end

return FrequencySliceProfile

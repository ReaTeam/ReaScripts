-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local T     = require "widgets/theme"
local DSP   = require "modules/dsp"
local MIDI  = require "modules/midi"

local SpectrographTimeProfile = {}
SpectrographTimeProfile.__index = SpectrographTimeProfile

SpectrographTimeProfile.Types = {
    NOTE = 0,
    RMSE = 1,
}

function SpectrographTimeProfile:new(spectrograph, color_idx, type)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(spectrograph, color_idx, type)
    return instance
end

function SpectrographTimeProfile:_initialize(spectrograph, color_idx, type)
    self.type           = type or SpectrographTimeProfile.Types.NOTE
    self.spectrograph   = spectrograph
    self:setColorIdx(color_idx)
    self.enabled        = true
    self.data_lines     = {}
    self.draw_curves    = {}
end

function SpectrographTimeProfile:spectrumContext()
    return self.spectrograph.sc
end

function SpectrographTimeProfile:setColorIdx(color_idx)
    self.color_idx      = color_idx

    if color_idx == -1 then self.color = T.RMSE_CURVE  end
    if color_idx == 0  then self.color = T.SLICE_CURVE end
    if color_idx > 0   then
        self.color = T.SPECTRO_PROFILES[ ((color_idx-1) % #T.SPECTRO_PROFILES) + 1 ]
    end
end

function  SpectrographTimeProfile:label()
    if self.type == SpectrographTimeProfile.Types.NOTE then
        return MIDI.noteName(self.note_num)
    else
        return "RMSE"
    end
end

function SpectrographTimeProfile:buildDataFromNote(note_num)
    assert(self.type == SpectrographTimeProfile.Types.NOTE, "Developer error : non-note profile")

    if not note_num then return end

    self.note_num  = note_num

    local sac = self:spectrumContext()

    -- Handle multi channel profiles
    if not (sac.chan_count == #self.data_lines) then self.data_lines = {} end
    for i=1, sac.chan_count do
        self.data_lines[i] = DSP.ensure_array_size(self.data_lines[i], sac.slice_count)
        sac:extractNoteProfile(i, note_num, self.data_lines[i])
    end

    -- Update timestamp to prevent bounces
    self.data_calc = reaper.time_precise()

end

function SpectrographTimeProfile:buildDataFromRMS()
    assert(self.type == SpectrographTimeProfile.Types.RMSE, "Developer error : non-RMS profile")

    local sac = self:spectrumContext()

    if not (sac.chan_count == #self.data_lines) then self.data_lines = {} end
    for i=1, sac.chan_count do
        self.data_lines[i] = DSP.ensure_array_size(self.data_lines[i], sac.slice_count)
        sac:extractRmseProfile(i, self.data_lines[i])
    end

    self.data_calc = reaper.time_precise()
end

function SpectrographTimeProfile:rebuildData()
    if self.type == SpectrographTimeProfile.Types.RMSE then
        self:buildDataFromRMS()
    else
        self:buildDataFromNote(self.note_num)
    end
end

function SpectrographTimeProfile:buildDrawCurves(x, y, w, h, chan_mode)
    local sp            = self.spectrograph
    local sac           = self:spectrumContext()

    local point_count   = w

    local vp_u_l = sp.vp_u_l
    local vp_u_r = sp.vp_u_r

    local mode_changeed               = not (chan_mode == self.last_chan_mode)
    local horizontal_zoom_has_changed = not (vp_u_l == self.last_vp_u_l)  or not (vp_u_r == self.last_vp_u_r)
    local position_has_changed        = not (x == self.last_x)      or not (y == self.last_y)
    local size_has_changed            = not (w == self.last_w)      or not (h == self.last_h)
    local data_has_changed            = not (self.last_data == self.data_calc)

    local frq_db_bounds_have_changed  = not (self.last_dbmin == sp.dbmin) or not (self.last_dbmax == sp.dbmax)
    local rms_db_bounds_have_changed  = not (self.last_rms_dbmin == sp.rms_dbmin) or not (self.last_rms_dbmax == sp.rms_dbmax)
    local db_bounds_have_changed      = frq_db_bounds_have_changed
    if self.type == SpectrographTimeProfile.Types.RMSE then db_bounds_have_changed = rms_db_bounds_have_changed end

    -- Avoid rebuilding draw points if stalled
    if  not position_has_changed and not mode_changeed and not horizontal_zoom_has_changed and not size_has_changed and not data_has_changed and not db_bounds_have_changed then
        return
    end

    if      position_has_changed and not mode_changeed and not horizontal_zoom_has_changed and not size_has_changed and not data_has_changed and not db_bounds_have_changed then
        -- Only the position has changed. It's just a translation we can do this fast.
        -- Still necessary, because ImGUI drawlist does not handle relative coordinates ...
        for chan=1, sac.chan_count do
            local diffx = x - self.last_x
            local diffy = y - self.last_y
            DSP.array_op_add_xy(self.draw_curves[chan], diffx, diffy)
        end
    else

        -- Reset draw curves if the number does not correspond to what we had
        if not (sac.chan_count == #self.draw_curves) then self.draw_curves = {} end

        -- SRC X : use u scale from 0 to 1
        self.profile_buf_src_x  = DSP.ensure_array_size(self.profile_buf_src_x, #self.data_lines[1], function(a)
            DSP.array_fill_01_intervals(a)
        end)

        -- Temporary buffers
        self.draw_points_x      = DSP.ensure_array_size(self.draw_points_x, point_count)
        self.draw_points_y      = DSP.ensure_array_size(self.draw_points_y, point_count)

        -- If we're not in "all" mode, draw only one channel so it will take full height
        local chan_y_height     = (chan_mode == 0) and (math.floor(h * 1.0 / sac.chan_count)) or (h)

        for chan=1, sac.chan_count do
            local data_line = self.data_lines[chan]

            -- DST X
            self.draw_curves[chan] = DSP.ensure_array_size(self.draw_curves[chan],     point_count * 2)

            local ustart = sp.vp_u_l
            local uend   = sp.vp_u_r

            -- Build the time proportion for X axis (from ustart to uend)
            DSP.array_fill_01(self.draw_points_x)
            DSP.array_op_mult(self.draw_points_x, uend - ustart)
            DSP.array_op_add (self.draw_points_x, ustart)

            -- Interpolate
            DSP.resample_curve(self.profile_buf_src_x, data_line, self.draw_points_x, self.draw_points_y, false, "akima")

            -- Put y values in the graph domain
            if self.type == SpectrographTimeProfile.Types.NOTE then
                DSP.array_op_normalize_min_max(self.draw_points_y, sp.dbmin, sp.dbmax)
            else
                DSP.array_op_normalize_min_max(self.draw_points_y, sp.rms_dbmin, sp.rms_dbmax)
            end

            -- This is where we're going to map this to the widget y coordinates
            if (chan % 2 == 1) or (chan == chan_mode) then
                local ochan = (chan == chan_mode) and (1) or (chan)
                DSP.array_op_mult(self.draw_points_y,   -chan_y_height)
                DSP.array_op_add(self.draw_points_y, y + ochan * chan_y_height)
            else
                DSP.array_op_mult(self.draw_points_y,    chan_y_height)
                DSP.array_op_add(self.draw_points_y, y + (chan - 1) * chan_y_height)
            end

            -- Rebuild X values in the pixel domain
            DSP.array_fill_0n(self.draw_points_x) -- of size point_count
            -- Translate to graph domain
            DSP.array_op_add(self.draw_points_x, x)

            -- Ready-to-use graph coordinates
            DSP.array_interleave(self.draw_curves[chan], self.draw_points_x, self.draw_points_y)
        end
    end

    self.last_chan_mode  = chan_mode
    self.last_x     = x
    self.last_y     = y
    self.last_w     = w
    self.last_h     = h
    self.last_dbmin = sp.dbmin
    self.last_dbmax = sp.dbmax
    self.last_rms_dbmin = sp.rms_dbmin
    self.last_rms_dbmax = sp.rms_dbmax
    self.last_vp_u_l   = vp_u_l
    self.last_vp_u_r   = vp_u_r
    self.last_data  = self.data_calc
end

return SpectrographTimeProfile

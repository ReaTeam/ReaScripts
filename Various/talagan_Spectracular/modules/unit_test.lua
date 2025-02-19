-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local DSP_UT = require "unit_tests/dsp"

local function launch()

    if false then
        DSP_UT.resample()
    end

    DSP_UT.interleave_deinterleave()
    DSP_UT.hann_window()
end

return {
    launch = launch
}

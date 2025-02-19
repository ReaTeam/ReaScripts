-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local DSP = require "modules/dsp"
local CSV = require "modules/csv"

local function array_comp_dump(array, array_ref)
    for i=1, #array do
        reaper.ShowConsoleMsg("" .. array[i] .. " vs " .. array_ref[i] .. "\n")
    end
end

local function assert_float(val, vref, err)
    if math.abs(val - vref) > 0.0000000001 then
        error(err)
    end
end

local function assert_float_array(arr, arr_ref, err)
    for i=1, #arr do
        assert_float(arr[i], arr_ref[i], "At index " .. i .. " : " .. arr[i] .. " vs " .. arr_ref[i] .. " : " .. err)
    end
end

-- This one is not really a unit test as it needs manual interaction ...
local function resample()

    local function test_func(x) return math.sin(10*x) + math.sin(13*x) end

    -- Testing interval
    local x_min         = -0.25
    local x_max         = 1.5

    -- Initial data
    local point_count   = 20
    local rand_xs       = reaper.new_array(point_count)

    -- First, generate random points that will be our known "keyframes"
    -- Add bounds
    rand_xs[1]              = x_min
    rand_xs[point_count]    = x_max

    -- Draw random points within x interval
    for i=2, point_count-1 do
        rand_xs[i] = x_min + math.random() * (x_max - x_min)
    end

    local sorted_xs = rand_xs.table()
    table.sort(sorted_xs)

    local xs = reaper.new_array(sorted_xs)
    local ys = reaper.new_array(#sorted_xs)
    for i=1, point_count do
        ys[i] = test_func(xs[i])
    end

    local xd = reaper.new_array(50)
    local yd = reaper.new_array(50)

    -- First test : resample the curve evenly, ask for 50 points instead of 20
    DSP.resample_curve(xs, ys, xd, yd, true, "akima")
    CSV.dump2("/Users/ben/Downloads/resample_test_1_original_data_20_points.csv",    xs, ys)
    CSV.dump2("/Users/ben/Downloads/resample_test_2_oversampled_data_50_points.csv",  xd, yd)

    -- Second test : deduce some custom intermediary points from the extrapoloated curve
    local dst_x = reaper.new_array(6)
    local dst_y = reaper.new_array(#dst_x)
    dst_x[1] = -0.1
    dst_x[2] = 0.03
    dst_x[3] = 0.27
    dst_x[4] = 0.53
    dst_x[5] = 0.78
    dst_x[6] = 1.12
    DSP.resample_curve(xs, ys, dst_x, dst_y, false, "akima")
    CSV.dump2("/Users/ben/Downloads/resample_test_3_deduced_values_for_custom_positions.csv",  dst_x, dst_y)

    -- The 50 point deduced curve should almost contain both the original data and the custom positions.
end

local function interleave_deinterleave()

    local intl = reaper.new_array(6)
    intl[1] = 1
    intl[2] = 11
    intl[3] = 2
    intl[4] = 22
    intl[5] = 3
    intl[6] = 33

    local deint1 = reaper.new_array(3)
    local deint2 = reaper.new_array(3)

    DSP.array_deinterleave(intl, deint1, deint2)

    local success = (deint1[1] == 1) and (deint1[2] == 2) and (deint1[3] == 3) and (deint2[1] == 11) and (deint2[2] == 22) and (deint2[3] == 33)

    if not success then
        error("Deinterleave function is not working !!")
    end

    intl.clear()

    DSP.array_interleave(intl, deint1, deint2)

    local success = (intl[1] == 1) and (intl[3] == 2) and (intl[5] == 3) and (intl[2] == 11) and (intl[4] == 22) and (intl[6] == 33)

    if not success then
        error("Interleave function is not working !!")
    end

end

local function hann_window()
    local test_array = reaper.new_array(20)
    test_array.clear(1);

    DSP.window_hann(test_array, 6, 10)
    local res = {1, 1, 1, 1, 1, 0, 0.11697777844051, 0.41317591116653, 0.75, 0.96984631039295, 0.96984631039295, 0.75, 0.41317591116653, 0.11697777844051, 0, 1, 1, 1, 1, 1}

    assert_float_array(test_array, res, "Hann test failed. ")
end

return {
    resample                  = resample,
    interleave_deinterleave   = interleave_deinterleave,
    hann_window               = hann_window,
}

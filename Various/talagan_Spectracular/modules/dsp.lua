-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- Get the current path for adressing DSP scripts
local lib_file_path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]

local ImGui  = require "ext/imgui"

local ctx    = nil
local function setImGuiContext(c) ctx = c end

-- Cache for compiled functions
local compiled_function_repository = {}

------- Pseudo Malloc (for emulating EEL memory maps) ---------

Malloc = {}
Malloc.__index = Malloc
function Malloc:new()
    local instance = {}
    setmetatable(instance, self)
    instance.ptr = 0
    return instance
end
function Malloc:alloc(sz)
    local pos   = self.ptr
    self.ptr    = self.ptr + sz
    return pos
end

---------------------- EEL Array helpers -----------------------

local function Function_SetValue_ArrayAt(func, name, values, address)
    ImGui.Function_SetValue(func, name, address)
    ImGui.Function_SetValue_Array(func, name, values)
end

local function getOrCompileFunction(function_name)
    local func = compiled_function_repository[function_name]
    if func then return func end

    local path = lib_file_path .. "dsp/" .. function_name .. ".eel"

    local file = io.open(path, "rb")
    if not file then
        error("Could not open inlined dsp EEL File '" .. path .. "'." )
    end

    local code = file:read("a")
    file:close()

    func = ImGui.CreateFunctionFromEEL(code)
    compiled_function_repository[function_name]  = func

    if ctx then
        ImGui.Attach(ctx, func)
    end

    return func
end

---------------------- reaper array helper -----------------------

local function ensure_array_size(array, size, build_callback)
    if not array or not (#array == size) then
        array = reaper.new_array(size)
        if build_callback then
            build_callback(array)
        end
    end
    return array
end

-------------------- EEL : basic array operations -----------------

local OP_ADD        = 0;
local OP_MULT       = 1;
local OP_SQRT       = 2;
local OP_NORMALIZE  = 3;
local OP_CLAMP      = 4;
local OP_NORMALIZE_MIN_MAX = 5;
local OP_ADD_XY     = 6;

local function array_op(op, array, param1, param2)
    local func = getOrCompileFunction("array_op")

    ImGui.Function_SetValue(func, "_OP",        op)
    ImGui.Function_SetValue(func, "_SIZE",      #array)
    ImGui.Function_SetValue(func, "_PARAM1",    param1 or 0)
    ImGui.Function_SetValue(func, "_PARAM2",    param2 or 0)
    Function_SetValue_ArrayAt(func, "_ARRAY",   array, 0)

    ImGui.Function_Execute(func)

    ImGui.Function_GetValue_Array(func, "_ARRAY", array)
end


--- Adds a factor to every element of the array
--- @param array reaper.array array to modify
--- @param factor number factor to be added
local function array_op_add(array, factor)
    array_op(OP_ADD, array, factor)
end
local function array_op_mult(array, factor)
    array_op(OP_MULT, array, factor)
end
local function array_op_sqrt(array)
    array_op(OP_SQRT, array)
end
local function array_op_normalize(array)
    array_op(OP_NORMALIZE, array)
end
local function array_op_clamp(array, min, max)
    assert(not(min == nil), "min is nil")
    assert(not(max == nil), "max is nil")

    array_op(OP_CLAMP, array, min, max)
end
-- Normalize between 0 and 1, with given input min,max.
local function array_op_normalize_min_max(array, min, max)
    assert(not(min == nil), "min is nil")
    assert(not(max == nil), "max is nil")

    array_op(OP_NORMALIZE_MIN_MAX, array, min, max)
end
local function array_op_add_xy(array, xdiff, ydiff)
    array_op(OP_ADD_XY, array, xdiff, ydiff)
end

-------------------------

local FILL_01           = 0;
local FILL_0N           = 1;
local FILL_BIN_FREQS    = 2;
local FILL_EQUALLY      = 3;
local FILL_01_INTERVALS = 4;

local function array_fill(fill_mode, array, param1, param2)
    local func = getOrCompileFunction("array_fill")

    ImGui.Function_SetValue(func,   "_OP",   fill_mode)
    ImGui.Function_SetValue(func,   "_SIZE", #array)
    ImGui.Function_SetValue(func,   "_PARAM1",  param1 or 0)
    ImGui.Function_SetValue(func,   "_PARAM2",  param2 or 0)

    Function_SetValue_ArrayAt(func, "_ARRAY", array, 0)

    ImGui.Function_Execute(func)

    ImGui.Function_GetValue_Array(func, "_ARRAY",    array)

    return array
end

local function array_fill_01(array)
    return array_fill(FILL_01, array)
end
local function array_fill_0n(array)
    return array_fill(FILL_0N, array)
end
-- Fill an X array for fft bins with corresponding frequencies.
local function array_fill_bin_freqs(array, bin_fwidth)
    return array_fill(FILL_BIN_FREQS, array, bin_fwidth)
end
local function array_fill_equally(array, first_val, last_val)
    return array_fill(FILL_EQUALLY, array, first_val, last_val)
end
local function array_fill_01_intervals(array)
    return array_fill(FILL_01_INTERVALS, array)
end

-------------------------

local WINDOW_HANN = 0;
local WINDOW_RECT = 1;

-- Beware, this function modifies the input samples.
-- Window start is an index given in the samples_array, so it uses lua index norm (which is +1, that's why we remove 1 before going EEL)
local function sig_window(window_type, samples_array, window_start, window_size)

    -- TODO : Check window size and window start coherency
    local func = getOrCompileFunction("fft_window")

    ImGui.Function_SetValue(func, "_WINDOW_TYPE",      window_type)
    ImGui.Function_SetValue(func, "_WINDOW_START",     window_start - 1)
    ImGui.Function_SetValue(func, "_WINDOW_SIZE",      window_size)
    ImGui.Function_SetValue(func, "_SIZE",             #samples_array)

    -- Hann coeffs are mapped first, then the samples,
    -- so put all samples after the coeffs.
    Function_SetValue_ArrayAt(func, "_SAMPLES",        samples_array, window_size)

    ImGui.Function_Execute(func)
    ImGui.Function_GetValue_Array(func, "_SAMPLES",    samples_array)

    local sig_energy    = ImGui.Function_GetValue(func, "_ENERGY")
    local max_energy    = ImGui.Function_GetValue(func, "_MAX_ENERGY")

    return sig_energy, max_energy
end

local function window_hann(samples_array, window_start, window_size)
    return sig_window(WINDOW_HANN, samples_array, window_start, window_size)
end
local function window_rect(samples_array, window_start, window_size)
    return sig_window(WINDOW_RECT, samples_array, window_start, window_size)
end

-------------------

-- Interleave / Deinterleave. Playing with variable arguments ...

local CHAN_INTERLEAVE     = 0
local CHAN_DEINTERLEAVE   = 1

local function array_interleave(dst_array, ...)
    local number_of_arrays = select('#', ... )

    if number_of_arrays < 1 then
        error('Should have at least one array to interleave')
    end

    local first = select(1, ...)
    local size  = #first
    for i=2, number_of_arrays do
        local arr = select(i, ...)
        if not size == #arr then
            error("Array 1 and " .. i .. "should be of the same size")
        end
    end

    if not (#dst_array == number_of_arrays * size) then
        error("DST Array size should be equal to the sum of the sizes of the src arrays")
    end

    local func = getOrCompileFunction("array_interleave")

    ImGui.Function_SetValue(func, "_OP",         CHAN_INTERLEAVE)
    ImGui.Function_SetValue(func, "_SIZE",       size)
    ImGui.Function_SetValue(func, "_CHAN_COUNT", number_of_arrays)

    ImGui.Function_SetValue(func, "_SRC", 0)
    ImGui.Function_SetValue(func, "_DST", size * number_of_arrays)

    for i=1, number_of_arrays do
        -- Put all arrays sequencially in function memory
        local arr = select(i, ...)
        ImGui.Function_SetValue(func, "_SRC_PTR", (i-1) * size)
        ImGui.Function_SetValue_Array(func, "_SRC_PTR", arr)
    end

    ImGui.Function_Execute(func)

    ImGui.Function_GetValue_Array(func, "_DST", dst_array)
end

local function array_deinterleave(src_array, ...)
    local number_of_arrays = select('#', ... )

    if number_of_arrays < 1 then
        error('Should have at least one array to interleave')
    end

    local first = select(1, ...)
    local size  = #first
    for i=2, number_of_arrays do
        local arr = select(i, ...)
        if not size == #arr then
            error("Array 1 and " .. i .. "should be of the same size")
        end
    end

    if not (#src_array == number_of_arrays * size) then
        error("SRC Array size should be equal to the sum of the sizes of the dst arrays")
    end

    local func = getOrCompileFunction("array_interleave")

    local dst_addr = size * number_of_arrays

    ImGui.Function_SetValue(func, "_OP",         CHAN_DEINTERLEAVE)
    ImGui.Function_SetValue(func, "_SIZE",       size)
    ImGui.Function_SetValue(func, "_CHAN_COUNT", number_of_arrays)

    ImGui.Function_SetValue(func, "_SRC", 0)
    ImGui.Function_SetValue(func, "_DST", dst_addr)

    ImGui.Function_SetValue_Array(func, "_SRC", src_array)

    ImGui.Function_Execute(func)

    for i=1, number_of_arrays do
        local arr = select(i, ...)
        ImGui.Function_SetValue(func, "_DST_PTR", dst_addr + (i-1) * size)
        ImGui.Function_GetValue_Array(func, "_DST_PTR", arr)
    end
end

-------------------

local function fft_to_fft_bins(fft_samples, fft_bins)
    if not (2 * #fft_bins == #fft_samples) then
        error("Egy buffer should be exactly half of the FFT buffer")
    end

    local func = getOrCompileFunction("fft_to_fft_bins")

    ImGui.Function_SetValue(func, "_FFT_SIZE",          #fft_samples)

    Function_SetValue_ArrayAt(func, "_FFT_SAMPLES",     fft_samples,     0)
    ImGui.Function_SetValue(func,   "_FFT_BINS",                         #fft_samples)

    ImGui.Function_Execute(func)
    ImGui.Function_GetValue_Array(func, "_FFT_BINS",    fft_bins)

    return ImGui.Function_GetValue(func, "_ENERGY")
end

local function fft_bins_to_db(fft_bins, ref_energy, floor_db)
    local func = getOrCompileFunction("fft_bins_to_db")

    ImGui.Function_SetValue(func, "_FFT_BIN_COUNT",   #fft_bins)
    ImGui.Function_SetValue(func, "_REF_ENERGY",     ref_energy)
    ImGui.Function_SetValue(func, "_FLOOR_DB",       floor_db)

    Function_SetValue_ArrayAt(func, "_FFT_BINS",     fft_bins,     0)

    ImGui.Function_Execute(func)
    ImGui.Function_GetValue_Array(func, "_FFT_BINS", fft_bins)
end

-- Returns the RMS for the samples window
local function rmse(samples)
    local func = getOrCompileFunction("rmse")

    ImGui.Function_SetValue(func, "_SIZE",          #samples)

    Function_SetValue_ArrayAt(func, "_SAMPLES",     samples,     0)

    ImGui.Function_Execute(func)

    return ImGui.Function_GetValue(func, "_RMSE")
end


-------------------------------- RESAMPLING -----------------------------------------

-- Magic resampling function using cubic splines.
--
-- src_x, src_y should contain reference points.
--     dst_x doesn't need to be evenly spaced
--     but it needs to be ordered
--
-- dst_x, dst_y are the result of the ressampling
--      they should be prepared arrays of the same size
--      dst_x may be filled by the developer or, if build_dst_x_evenly is true,
--      it will be filled automatically from src_x.first to src_x.last
--
-- src_x may be nil :
--      Points are then considered to be spaced equally (between 0 and 1)
--      dst_x should be nil too for coherency
--      dst_y should be not nil, and dst size will be deduced from #dst_y
--
-- Returns : the new coordinates
--      - dst_x
--      - dst_y

local function resample_curve(src_x, src_y, dst_x, dst_y, build_dst_x_evenly, method)
    local no_src = false

    --TODO : WARNING : Apply a low pass filter before resampling to avoid aliasing effects !!!

    if src_x == nil then
        if not build_dst_x_evenly then
            error("Src X is nil, thus, build_dst_x_evenly must be true")
        end
        if not (dst_x == nil) then
            error("Src X is nil, for coherency, Dst X should be nil too")
        end
        no_src = true
    else
        if not (#src_x == #src_y) then
            error("Src X and Src Y should have the same size (these are x,y pairs !!)")
        end

        if not(#dst_x == #dst_y) then
            error("Dst X and Dst Y should have the same size (these are x,y pairs !!)")
        end
    end

    -- Use non nil arrays for deducing sizes
    local src_size = #src_y
    local dst_size = #dst_y

    local func_name = 'resampler_akima'

    if method == 'cubic' then
        func_name = 'resampler_cubic'
    elseif method == 'linear' then
        func_name = 'resampler_linear'
    end

    local func = getOrCompileFunction(func_name)

    ImGui.Function_SetValue(func, "_BUILD_EVEN_SAMPLES", build_dst_x_evenly and 1 or 0)
    ImGui.Function_SetValue(func, "_NO_SRC",             no_src and 1 or 0)

    ImGui.Function_SetValue(func, "_SRC_SIZE", src_size)
    ImGui.Function_SetValue(func, "_DST_SIZE", dst_size)

    local m = Malloc:new()
    if src_x == nil then
        -- There's no array, so allocate space but don't copy data.
        ImGui.Function_SetValue(func, "_SRC_X", m:alloc(src_size))
    else
        Function_SetValue_ArrayAt(func, "_SRC_X", src_x, m:alloc(src_size))
    end
    Function_SetValue_ArrayAt(func, "_SRC_Y",     src_y, m:alloc(src_size))

    if dst_x == nil then
        -- There's no array, so allocate space but don't copy data.
        ImGui.Function_SetValue(func, "_DST_X", m:alloc(dst_size))
    else
        Function_SetValue_ArrayAt(func, "_DST_X", dst_x, m:alloc(dst_size))
    end
    Function_SetValue_ArrayAt(func, "_DST_Y",     dst_y, m:alloc(dst_size))

    ImGui.Function_Execute(func)

    if not (dst_x == nil) then
        ImGui.Function_GetValue_Array(func, "_DST_X", dst_x)
    end

    ImGui.Function_GetValue_Array(func, "_DST_Y", dst_y)

    return dst_x, dst_y
end

--------------------- PROFILE / SLICE extractors from spectrogram data/matrix ---------------------

EXTRACT_PROFILE = 0
EXTRACT_SLICE   = 1

local function analysis_data_extract(extract_type, data_buf, extract_buf, slice_count, slice_size, extract_num)

    if not (#data_buf ==  slice_count * slice_size) then
        error("Developer error : size mismatch (data)")
    end

    if extract_type == EXTRACT_PROFILE and not(#extract_buf == slice_count) then
        error("Developer error : size mismatch (profile)")
    end

    if extract_type == EXTRACT_SLICE and not(#extract_buf == slice_size) then
        error("Developer error : size mismatch (slice)")
    end

    local func = getOrCompileFunction("analysis_data_extractor")

    ImGui.Function_SetValue(func, "_OP",            extract_type)
    ImGui.Function_SetValue(func, "_SLICE_SIZE",    slice_size)
    ImGui.Function_SetValue(func, "_SLICE_COUNT",   slice_count)
    ImGui.Function_SetValue(func, "_PARAM1",        extract_num)

    Function_SetValue_ArrayAt(func, "_DATA",        data_buf, 0)
    ImGui.Function_SetValue  (func, "_EXTRACT",     #data_buf)

    ImGui.Function_Execute(func)

    ImGui.Function_GetValue_Array(func, "_EXTRACT", extract_buf)
end
-- slice_num is 0 based index
local function analysis_data_extract_slice(data_buf, slice_buf, slice_count, slice_size, slice_num)
    analysis_data_extract(EXTRACT_SLICE, data_buf, slice_buf, slice_count, slice_size, slice_num)
end
-- profile_num is 0 based index
local function analysis_data_extract_profile(data_buf, profile_buf, slice_count, slice_size, profile_num)
    analysis_data_extract(EXTRACT_PROFILE, data_buf, profile_buf, slice_count, slice_size, profile_num)
end

local function analysis_data_to_rgb_array(spectrograms, coeffs, rgb_result, db_min, db_max, slice_size, format)
    local func = getOrCompileFunction("analysis_data_to_rgb_array")

    local spectro_count = #spectrograms
    local spectro_size  = #rgb_result

    for i, spectro_data in pairs(spectrograms) do
        assert(#spectro_data == spectro_size, "Pixel buffer size is not not of the size of the spectrograms")
    end
    assert(#coeffs == #spectrograms, "There should be one coeff per spectrogram")

    ImGui.Function_SetValue(func, "_SPECTRO_COUNT", spectro_count)
    ImGui.Function_SetValue(func, "_SPECTRO_SIZE",  spectro_size)

    ImGui.Function_SetValue(func, "_DB_MIN",  db_min)
    ImGui.Function_SetValue(func, "_DB_MAX",  db_max)

    ImGui.Function_SetValue(func, "_SLICE_SIZE",    slice_size)
    ImGui.Function_SetValue(func, "_FORMAT",        format)

    local m = Malloc:new()

    ImGui.Function_SetValue  (func, "_PIXELS",              m:alloc(#rgb_result))
    ImGui.Function_SetValue  (func, "_DATA",                m.ptr)

    -- Write all spectrograph data consecutively
    for i, spectro_data in pairs(spectrograms) do
        Function_SetValue_ArrayAt(func, "_DATA_PTR", spectro_data, m:alloc(spectro_size))
    end

    Function_SetValue_ArrayAt(func, "_COEFFS", coeffs,      m:alloc(#coeffs))

    ImGui.Function_Execute(func)

    ImGui.Function_GetValue_Array(func, "_PIXELS", rgb_result)
end

----------------------------------------------------------------

return {
    setImGuiContext                 = setImGuiContext,

    ensure_array_size               = ensure_array_size,

    array_op_add                    = array_op_add,
    array_op_mult                   = array_op_mult,
    array_op_sqrt                   = array_op_sqrt,
    array_op_clamp                  = array_op_clamp,
    array_op_normalize              = array_op_normalize,
    array_op_normalize_min_max      = array_op_normalize_min_max,
    array_op_add_xy                 = array_op_add_xy,

    array_fill_01                   = array_fill_01,
    array_fill_0n                   = array_fill_0n,
    array_fill_bin_freqs            = array_fill_bin_freqs,
    array_fill_equally              = array_fill_equally,
    array_fill_01_intervals         = array_fill_01_intervals,

    array_interleave                = array_interleave,
    array_deinterleave              = array_deinterleave,

    window_hann                     = window_hann,
    window_rect                     = window_rect,

    rmse                            = rmse,

    fft_to_fft_bins                 = fft_to_fft_bins,
    fft_bins_to_db                  = fft_bins_to_db,

    resample_curve                  = resample_curve,

    analysis_data_to_rgb_array      = analysis_data_to_rgb_array,
    analysis_data_extract_profile   = analysis_data_extract_profile,
    analysis_data_extract_slice     = analysis_data_extract_slice
}

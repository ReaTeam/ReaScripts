-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local MIDI      = require "modules/midi"
local DSP       = require "modules/dsp"
local LOG       = require "modules/log"
local S         = require "modules/settings"
local RENDER    = require "modules/render"
local CSV       = require "modules/csv"

local Spectrogram    = require "classes/spectrogram"
local SampleAccessor = require "classes/sample_accessor"

-- Main analysing code

---------------------------------

--[[
local octava_settings = {
[-1] = { full_width = 16384 , eff_width = 16384},
[0]  = { full_width =  8192 , eff_width =  8192},
[1]  = { full_width =  8192 , eff_width =  8192},
[2]  = { full_width =  8192 , eff_width =  8192},
[3]  = { full_width =  8192 , eff_width =  8192},
[4]  = { full_width =  8192 , eff_width =  8192},
[5]  = { full_width =  8192 , eff_width =  8192},
[6]  = { full_width =  8192 , eff_width =  8192},
[7]  = { full_width =  8192 , eff_width =  8192},
[8]  = { full_width =  8192 , eff_width =  8192},
}
]]

local UI_REFRESH_INTERVAL_SECONDS = 0.05

---------------------------------

local SpectrumAnalysisContext = {}
SpectrumAnalysisContext.__index = SpectrumAnalysisContext

-- sample_rate is the sample rate of the signal to anayse
function SpectrumAnalysisContext:new(params)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(params)
    return instance
end

function SpectrumAnalysisContext:_initialize(params)
    self.params = params
end

function SpectrumAnalysisContext:_buildAndRender()
    local params = self.params

    -- First, perform the right rendering
    local source_ctx = RENDER.render({
        channel_mode        = S.instance_params.channel_mode,
        ts                  = self.params.ts,
        te                  = self.params.te,
        time_resolution_ms  = self.params.time_resolution_ms,
        tracks              = self.params.tracks
    })

    if not source_ctx.success then
        self.error              = source_ctx.err
        self.analysis_finished  = true
        return
    end

    self.signal                 = source_ctx
    self.tracks                 = source_ctx.tracks
    self.sample_rate            = source_ctx.sample_rate
    self.chan_count             = source_ctx.chan_count

    self.fft_size               = params.fft_size

    self.slice_step             = math.floor((params.time_resolution_ms / 1000.0) * source_ctx.sample_rate)
    self.slice_step_duration    = 1.0 * self.slice_step / self.sample_rate

    self.low_octava             = params.low_octava
    self.high_octava            = params.high_octava

    self.low_note               = MIDI.noteNumber(self.low_octava  - 1, 11)
    self.high_note              = MIDI.noteNumber(self.high_octava + 1,  0)

    -- Build buffers for each octava
    self.fft_params             = self:_buildFFTParamsAndBuffers()

    -- Count the number of slices we will have, and adjust the sample count so that last slice falls on an full count of samples
    self:_countSlices()
    -- Build buffers for slice analysis : energy per quarter of note
    self:_calcSliceSizeAndBuildNoteBuffers()
    -- Build result data buffers
    self:_buildSpectrogramBuffers()

    self.sample_accessor        = SampleAccessor:new(self)
end


function SpectrumAnalysisContext:_countSlices()
    local signal        = self.signal

    self.frame_count    = self.signal.frame_count

    -- We're going to trim the signal so that the number of samples is a multiple of slice_step
    -- (Remove extra samples at the end)
    local kept_slices  = math.floor(self.frame_count / self.slice_step)
    if kept_slices == 0 then
        self.signal_too_short = true
        error("Signal is too short : todo handle this case a better way")
        return
    end

    -- Recalculate the sample count
    self.slice_count    = kept_slices
    self.frame_count    = self.slice_count * self.slice_step

    -- Update the signal end time after triming
    signal.stop         = signal.start + (self.frame_count / signal.sample_rate)
end

function SpectrumAnalysisContext:_buildFFTParamsAndBuffers()

    local samplerate                        = self.sample_rate * 1.0
    local sample_count                      = self.fft_size
    local zero_padding_sample_count         = math.floor(self.fft_size * self.params.zero_padding_percent / 100.0)
    local effective_window_sample_count     = sample_count - zero_padding_sample_count

    -- Number of bins in the FFT. Remember we're using fft_real so we need to divide by 2
    local bin_count         = sample_count/2
    -- Bandwidth of an FFT bin
    local bin_fwidth        = samplerate / sample_count

    -- Pre-allocate some buffers
    local sample_buf            = reaper.new_array(sample_count)
    local fft_bin_buf           = reaper.new_array(bin_count)
    local bin_freq_buf          = reaper.new_array(bin_count)

    -- There's not the same number of bins in the low octavas and in the high octava, due to the logarithmic nature of the freq/note scale
    -- The resolution is better in low frequencies, and there will be more bins there.
    DSP.array_fill_bin_freqs(bin_freq_buf, bin_fwidth)

    return {
        buf                             = sample_buf,
        -- Buffer for all bin energies
        fft_bin_buf                     = fft_bin_buf,
        -- Buffer for all central frequencies of bins
        bin_freq_buf                    = bin_freq_buf,
        -- Number of bins, and frequency width of a bin
        bin_count                       = bin_count,
        bin_fwidth                      = bin_fwidth,

        -- Parameters for keeping or throwing bins away when building the final curve
        full_window_sample_count        = sample_count,
        full_window_duration            = sample_count / samplerate,

        effective_window_sample_count   = effective_window_sample_count,
        effective_window_duration       = effective_window_sample_count / samplerate,

        -- indication for the zero-padding
        padding_size                    = sample_count - effective_window_sample_count,
    }
end

-- Buffers to process FFT results
function SpectrumAnalysisContext:_calcSliceSizeAndBuildNoteBuffers()
    local range = self:noteRange()

    -- Use 5 frequencies per semitone
    self.semi_tone_slices = 5

    -- Add 1 to complete the loop, because we want to convert this into a BMP
    -- And we want a boudnary on the first and last pixels vertically
    local number_of_wanted_frequencies = (range.note_count - 1) * self.semi_tone_slices + 1

    self.note_freq_buf          = reaper.new_array(number_of_wanted_frequencies)
    self.note_freq_energy_buf   = reaper.new_array(number_of_wanted_frequencies)

    local note_interval = 1.0/self.semi_tone_slices
    local note_num      = self.low_note
    local ni            = 0

    while ni < number_of_wanted_frequencies do
        self.note_freq_buf[ni+1]    = MIDI.noteToFrequency(note_num)
        ni                          = ni + 1
        note_num                    = note_num + note_interval -- Quarter of tones
    end

    self.slice_size = #self.note_freq_buf
end

function SpectrumAnalysisContext:_buildSpectrogramBuffers()
    self.spectrograms = {}
    self.rmse         = {}

    for ci=1, self.chan_count do
        -- Build spectrogram and rmse for each channel
        self.spectrograms[ci]    = Spectrogram:new(self, ci)
        self.rmse[ci]            = reaper.new_array(self.slice_count)
    end
end

function SpectrumAnalysisContext:resumeAnalysis()

    self.analysis_chunk_start = reaper.time_precise()

    while self.progress.si < self.slice_count do
        -- Get the center of our slice : add one semi-slice
        local frame_offset = math.floor( (0.5 + self.progress.si) * self.slice_step )

        for ci=1, self.chan_count do

            -- Read samples, put in buffer, apply hann window
            self:_prepareFFT(ci, frame_offset)
            -- Do the fft, energy processing, and store data
            self:_performFFT()
            -- Normalize the result
            self:_normalizeFFT()
            -- Interpolate for notes instead of frequencies
            DSP.resample_curve(self.fft_params.bin_freq_buf, self.fft_params.fft_bin_buf, self.note_freq_buf, self.note_freq_energy_buf, false, "akima")

            -- Copy into slices the content of the new energies for this slice, at the offset of the slice
            self.spectrograms[ci]:saveSlice(self.note_freq_energy_buf, self.progress.si)
            -- Calculate the RMSE for this slice
            self.rmse[ci][self.progress.si + 1] = self:_performRMSE(ci, frame_offset)
        end

        self.progress.si    = self.progress.si + 1

        if (reaper.time_precise() - self.analysis_chunk_start) > UI_REFRESH_INTERVAL_SECONDS then
            -- Interrupt the calculation to let reaper do other stuff
            return false
        end
    end

    -- Destroy the audio accessor open on the rendered file
    reaper.DestroyAudioAccessor(self.signal.audio_accessor)
    -- Destroy the audio file
    os.remove(self.signal.file_name)
    -- Mark as finished
    self.analysis_finished = true

    LOG.debug("---\n")
    LOG.debug("Energy conservation successfull tests : " .. self.energy_conservation_test_success .. " / " .. self.energy_conservation_test_count .. "\n")
    LOG.debug("---\n")
end


function SpectrumAnalysisContext:analyze()
    if not self.progress then
        -- First call to analyse
        -- Initialize state vars so that we can pause/resume the analysis
        self.analysis_finished                  = false

        self.energy_conservation_test_count     = 0
        self.energy_conservation_test_success   = 0

        self.progress    = {}
        self.progress.si = 0

        self:_buildAndRender()

        self.render_finished = true
    end

    if self.analysis_finished then return end

    self:resumeAnalysis()
end


function SpectrumAnalysisContext:getProgress()
    local prog = 0.1

    if not self.render_finished then return prog, math.floor(prog * 100) .. " % - Rendering..." end
    if self.analysis_finished   then return 1,  "100 % - Finished" end

    prog = prog + (1-prog) * self.progress.si / ( 1.0 * self.slice_count)

    return prog, math.floor(prog * 100) .. " % - Processing..."
end


function SpectrumAnalysisContext:noteRange()
    return {
        low_octava      = self.low_octava,
        high_octava     = self.high_octava,

        low_note        = self.low_note,
        high_note       = self.high_note,

        note_count      = self.high_note - self.low_note + 1,
        octava_count    = self.high_octava - self.low_octava + 1,
    }
end

function SpectrumAnalysisContext:_performRMSE(chan_num, offset_center)
    local win = self.params.rms_window -- ???
    local left_src_sample = math.floor(offset_center - 0.5 * win)
    -- Make sure we're ok on the left
    if left_src_sample < 0 then left_src_sample = 0 end
    local right_src_sample = math.floor(offset_center + 0.5 * win)
    -- Make sure we're ok on the right
    if right_src_sample > self.frame_count - 1 then right_src_sample = self.frame_count - 1 end
    -- Number of samples kept due to potential border problems
    local win_sample_count = right_src_sample - left_src_sample

    local src_offset = left_src_sample

    -- The array size may change on boundaries but it's not a big deal
    self.rmse_buf = DSP.ensure_array_size(self.rmse_buf, win_sample_count)

    -- Get the samples into our temporary buffer
    self.sample_accessor:getSamples(src_offset, win_sample_count, chan_num, self.rmse_buf, 0)

    return DSP.rmse(self.rmse_buf)
end

-- Offset center is the offset of the central sample in the big sample serie (zeroes - samples - center - samples - zeroes)
function SpectrumAnalysisContext:_prepareFFT(chan_num, offset_center)

    local fft_params = self.fft_params

    -- Clear the buffer so that it's zeroed
    fft_params.buf.clear()

    local win             = fft_params.effective_window_sample_count
    local left_src_sample = math.floor(offset_center - 0.5 * win)

    -- Make sure we're ok on the left
    if left_src_sample < 0 then left_src_sample = 0 end

    local right_src_sample = math.floor(offset_center + 0.5 * win)

    -- Make sure we're ok on the right
    if right_src_sample > self.frame_count - 1 then right_src_sample = self.frame_count - 1 end

    -- Number of samples kept due to potential border problems
    local win_sample_count = right_src_sample - left_src_sample

    local dst_offset = math.floor(0.5 * (fft_params.full_window_sample_count - win_sample_count))
    local src_offset = left_src_sample

    if src_offset < 0 then
        error("Wrong use of the FFT !! Trying to get samples before the start of the sample serie.")
    end

    -- Get the samples into our temporary buffer
    self.sample_accessor:getSamples(src_offset, win_sample_count, chan_num, self.fft_params.buf, dst_offset)

    fft_params.applied_window_sample_count  = win_sample_count
    fft_params.max_energy                   = win_sample_count

    local apply_windowing = true
    if apply_windowing then
        -- Apply window on the full sample range
        -- Max energy is the energy of a maximum signal to which we apply the window
        fft_params.sig_energy, fft_params.max_energy = DSP.window_hann(fft_params.buf, dst_offset + 1, win_sample_count)
    else
        fft_params.sig_energy, fft_params.max_energy = DSP.window_rect(fft_params.buf, dst_offset + 1, win_sample_count)
    end
end

function SpectrumAnalysisContext:_performFFT()
    local fft_params = self.fft_params

    fft_params.buf.fft_real(#fft_params.buf, true)

    -- Calculate FFT energies per bin + their sum
    fft_params.fft_energy = DSP.fft_to_fft_bins(fft_params.buf, fft_params.fft_bin_buf)

    self.energy_conservation_test_count = self.energy_conservation_test_count + 1;

    if math.abs(fft_params.fft_energy - fft_params.sig_energy)/fft_params.fft_energy > 0.05 then
        LOG.debug("Energy not conserved !! : FFT E vs BUF E : " .. fft_params.fft_energy .. " / " .. fft_params.sig_energy ..  " (FFT Size : " .. fft_params.full_window_sample_count .. ")\n")
    else
        self.energy_conservation_test_success = self.energy_conservation_test_success + 1;
    end
end

function SpectrumAnalysisContext:_normalizeFFT()
    -- Convert FFT bins to decibels and apply normalization

    -- fft_size                         : size of the window / total number of samples in time window
    -- applied_window_sample_count      : number of effective samples in time window (zero-padding /boundaries applied)
    -- max_energy                       : max possible energy after window is applied (all samples at 1)

    --              <--- applied -->
    --                 _________
    -- |           |__/         \__|          |

    local fft_params = self.fft_params

    -- Normalize the results by applying various corrections.
    local db_correction_6         = 0.25
    -- Size of the fft window
    local standard_normalisation  = fft_params.full_window_sample_count
    -- Number of samples really used / fft size proportion (zero pad)
    local zero_pad_normalisation  = fft_params.applied_window_sample_count / fft_params.full_window_sample_count
    -- Windowing factor : when using a window the signal is modified, and thus the energy. Apply inverse correction.
    local windowing_normalisation = fft_params.max_energy/fft_params.applied_window_sample_count

    zero_pad_normalisation        = zero_pad_normalisation * zero_pad_normalisation

    local full_normalisation      = db_correction_6 * zero_pad_normalisation * standard_normalisation * windowing_normalisation

    DSP.fft_bins_to_db(fft_params.fft_bin_buf, full_normalisation, -90)
end


function SpectrumAnalysisContext:fftHalfWindowDurationForOctava(octava)
    local samples = self.fft_params.effective_window_sample_count * 0.5
    return samples / self.sample_rate
end

-- Data index accessor for note_num
function SpectrumAnalysisContext:profileNumForNoteNum(note_num)
    if note_num < self.low_note   then note_num = self.low_note  end
    if note_num > self.high_note  then note_num = self.high_note end

    local note_offset = (note_num - self.low_note) / (self.high_note - self.low_note)

    return math.floor( 0.5 + note_offset * (#self.note_freq_buf-1) )
end

-- Data index accessor for time
function SpectrumAnalysisContext:sliceNumForTime(time)
    if time < self.signal.start then time = self.signal.start end
    if time > self.signal.stop  then time = self.signal.stop end

    return math.floor(0.5 + (self.slice_count - 1) * (time - self.signal.start) / (self.signal.stop - self.signal.start))
end

function SpectrumAnalysisContext:sampleNumForTime(time)
    if time < self.signal.start then time = self.signal.start end
    if time > self.signal.stop  then time = self.signal.stop end

    return math.floor(0.5 + self.signal.sample_rate * (time - self.signal.start))
end

function SpectrumAnalysisContext:extractNoteProfile(chan_num, note_num, profile_buf)
    if not profile_buf then error("Developer error : should pass a valid reaper_array") end

    profile_buf = DSP.ensure_array_size(profile_buf, self.slice_count)
    local profile_num = self:profileNumForNoteNum(note_num)
    self.spectrograms[chan_num]:extractNoteProfile(profile_buf, profile_num)
end

function SpectrumAnalysisContext:extractSliceProfile(chan_num, time, profile_buf)
    if not profile_buf then error("Developer error : should pass a valid reaper_array") end

    profile_buf = DSP.ensure_array_size(profile_buf, self.slice_size)
    local slice_num = self:sliceNumForTime(time)
    self.spectrograms[chan_num]:extractSlice(profile_buf, slice_num)
end

function SpectrumAnalysisContext:extractRmseProfile(chan_num, profile_buf)
    local rmse = self.rmse[chan_num]

    if not profile_buf then error("Developer error : should pass a valid reaper_array") end
    profile_buf = DSP.ensure_array_size(profile_buf, #rmse)
    profile_buf.copy(rmse)
end

function SpectrumAnalysisContext:getRmseValueAt(chan_num, time)
    local slice_num = self:sliceNumForTime(time)

    return self.rmse[chan_num][slice_num+1]
end

function SpectrumAnalysisContext:getValueAt(chan_num, note_num, time)
    local slice_num   = self:sliceNumForTime(time)
    local profile_num = self:profileNumForNoteNum(note_num)

    return self.spectrograms[chan_num]:getValueForSliceAndProfile(slice_num, profile_num)
end

return SpectrumAnalysisContext

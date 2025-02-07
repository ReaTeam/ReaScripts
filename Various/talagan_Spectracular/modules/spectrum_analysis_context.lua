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
    local render_ret = RENDER.render({
        channel_mode = S.instance_params.channel_mode,
        ts           = self.params.ts,
        te           = self.params.te,
        tracks       = self.params.tracks
    })

    if not render_ret.success then
        self.error              = render_ret.err
        self.analysis_finished  = true

        return
    end

    local signal                = render_ret

    self.tracks                 = render_ret.tracks
    self.signal                 = signal
    self.sample_rate            = signal.sample_rate
    self.chan_count             = signal.chan_count

    self.fft_size               = params.fft_size

    self.slice_step             = (params.time_resolution_ms / 1000.0) * signal.sample_rate
    self.slice_step_duration    = 1.0 * self.slice_step / self.sample_rate

    self.low_octava             = params.low_octava
    self.high_octava            = params.high_octava

    self.low_note               = MIDI.noteNumber(self.low_octava  - 1, 11)
    self.high_note              = MIDI.noteNumber(self.high_octava + 1,  0)

    -- Build buffers for each octava
    self.fft_params             = self:_buildFFTParamsAndBuffers()

    -- Trim the signal if it does not fall on the good number of samples
    self:_trimSignalAndCountSlices()

    -- Build buffers for slice analysis : energy per quarter of note
    self:_buildNoteBuffers()

    -- Build result data buffers
    self:_buildResultDataBuffers()
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

function SpectrumAnalysisContext:_buildFFTParamsAndBuffers()

    local samplerate                        = self.sample_rate * 1.0
    local sample_count                      = self.fft_size
    local effective_window_sample_count     = self.fft_size

    -- Number of bins in the FFT. Remember we're using fft_real so we need to divide by 2
    local bin_count         = sample_count/2
    -- Bandwidth of an FFT bin
    local bin_fwidth        = samplerate / sample_count

    -- Pre-allocate some buffers
    local buf           = reaper.new_array(sample_count)
    local fft_bin_buf   = reaper.new_array(bin_count)
    local bin_freq_buf  = reaper.new_array(bin_count)

    -- There's not the same number of bins in the low octavas and in the high octava, due to the logarithmic nature of the freq/note scale
    -- The resolution is better in low frequencies, and there will be more bins there.
    DSP.array_fill_bin_freqs(bin_freq_buf, bin_fwidth)

    return {
        -- Buffer for the samples, to perform the fft
        buf                             = buf,
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
function SpectrumAnalysisContext:_buildNoteBuffers()
    local range = self:noteRange()

    -- Use 5 frequencies per semitone
    local semi_tone_slices = 5

    -- Add 1 to complete the loop
    local number_of_wanted_frequencies = range.note_count * semi_tone_slices + 1

    self.note_freq_buf          = reaper.new_array(number_of_wanted_frequencies)
    self.note_freq_energy_buf   = reaper.new_array(number_of_wanted_frequencies)

    -- Assemble frequency array from various octavi
    local ni        = 0

    local note_interval = 1.0/semi_tone_slices

    local note_num  = self.low_note
    while ni < number_of_wanted_frequencies do
        self.note_freq_buf[ni+1]    = MIDI.noteToFrequency(note_num)
        ni                          = ni + 1
        note_num                    = note_num + note_interval -- Quarter of tones
    end

    self.slice_size = #self.note_freq_buf
end

function SpectrumAnalysisContext:_buildResultDataBuffers()

    -- Our total point matrix : N slices x M frequences
    -- Store the full data in these buffers
    self.spectrograms = {}
    self.rmse         = {}

    for i=1, self.chan_count do
        -- Build spectrogram and rmse for this channel
        self.spectrograms[i]    = reaper.new_array(self.slice_count * self.slice_size)
        self.rmse[i]            = reaper.new_array(self.sample_count)
    end
end

function SpectrumAnalysisContext:_trimSignalAndCountSlices()
    local signal        = self.signal
    local c1_samples    = signal.samples[1]

    self.sample_count   = #c1_samples

    -- We're going to trim the signal so that the number of samples is a multiple of slice_step
    -- (Remove extra samples at the end)
    local kept_slices  = math.floor(self.sample_count / self.slice_step)
    if kept_slices == 0 then
        self.signal_too_short = true
        error("Signal is too short : todo handle this case a better way")
        return
    end

    self.slice_count  = kept_slices
    self.sample_count = self.slice_count * self.slice_step

    -- Trim all channels
    for ci, samples in pairs(signal.samples) do
        samples.resize(self.sample_count)
    end

    -- Update the signal end time after triming
    signal.stop     = signal.start + (self.sample_count / signal.sample_rate)
end



-- Offset center is the offset of the central sample in the big sample serie (zeroes - samples - center - samples - zeroes)
function SpectrumAnalysisContext:_prepareFFT(fft_params, samples, offset_center)

    -- Clear the buffer so that it's zeroed
    fft_params.buf.clear()

    local hwin            = fft_params.effective_window_sample_count
    local left_src_sample = math.floor(offset_center - 0.5 * hwin)

    -- Make sure we're ok on the left
    if left_src_sample < 0 then left_src_sample = 0 end

    local right_src_sample = math.floor(offset_center + 0.5 * hwin)

    -- Make sure we're ok on the right
    if right_src_sample > #samples - 1 then right_src_sample = #samples - 1 end

    -- Number of samples kept due to potential border problems
    local win_sample_count = right_src_sample - left_src_sample

    local dst_offset = math.floor(0.5 * (fft_params.full_window_sample_count - win_sample_count))
    local src_offset = left_src_sample

    if src_offset < 0 then
        error("Wrong use of the FFT !! Trying to get samples before the start of the sample serie.")
    end

    -- Beware, indices start at 1 for reaper arrays like lua tables
    fft_params.buf.copy(samples, src_offset+1, win_sample_count, dst_offset + 1)

    fft_params.windowing_energy_factor  = 1.0
    fft_params.max_energy               = win_sample_count

    local apply_windowing = true
    if apply_windowing then
        -- Apply window on the full sample range
        fft_params.sig_energy, fft_params.max_energy = DSP.window_hann(fft_params.buf, dst_offset + 1, win_sample_count)
    else
        fft_params.sig_energy, fft_params.max_energy = DSP.window_rect(fft_params.buf, dst_offset + 1, win_sample_count)
    end
end

function SpectrumAnalysisContext:_performFFT(fft_params)

    fft_params.buf.fft_real(#fft_params.buf, true)

    -- Calculate FFT energies per bin + their sum
    fft_params.fft_energy = DSP.fft_to_fft_bins(fft_params.buf, fft_params.fft_bin_buf)

    self.energy_conservation_test_count = self.energy_conservation_test_count + 1;

    if math.abs(fft_params.fft_energy - fft_params.sig_energy)/fft_params.fft_energy > 0.05 then
        LOG.debug("Energy not conserved !! : FFT E vs BUF E : " .. fft_params.fft_energy .. " / " .. fft_params.sig_energy ..  " (FFT Size : " .. fft_params.full_window_sample_count .. ")\n")
    else
        self.energy_conservation_test_success = self.energy_conservation_test_success + 1;
    end

    -- Convert FFT bins to decibels
    DSP.fft_bins_to_db(fft_params.fft_bin_buf, fft_params.max_energy/4.0, -90)
end

function SpectrumAnalysisContext:buildSpectrogram(samples, spectro)

    while self.progress.si < self.slice_count do

        -- Get the center of our slice
        local offset = math.floor( (0.5 + self.progress.si) * self.slice_step )
        -- Read samples, put in buffer, apply hann window
        self:_prepareFFT(self.fft_params, samples, offset)
        -- Do the fft, energy processing, and store data
        self:_performFFT(self.fft_params)

        -- Interpolate for notes instead of frequencies
        DSP.resample_curve(self.fft_params.bin_freq_buf, self.fft_params.fft_bin_buf, self.note_freq_buf, self.note_freq_energy_buf, false, "akima")

        -- Copy into slices the content of the new energies for this slice, at the offset of the slice
        spectro.copy(self.note_freq_energy_buf, 1, #self.note_freq_energy_buf, self.progress.si  * self.slice_size + 1)

        -- At this point, FFTs have been made and energy_bins are available for all octavi.
        -- Now interpolate, and build spectrum.

        self.progress.si  = self.progress.si  + 1

        if (reaper.time_precise() - self.analysis_chunk_start) > UI_REFRESH_INTERVAL_SECONDS then
            -- Interrupt the calculation to let reaper do other stuff
            return false
        end
    end

    -- Not interrupted
    return true
end

function SpectrumAnalysisContext:resumeAnalysis()

    self.analysis_chunk_start = reaper.time_precise()

    while self.progress.ci < self.chan_count do
        -- Loop on each channel
        local lci     = self.progress.ci + 1
        local samples = self.signal.samples[lci]
        local spectro = self.spectrograms[lci]
        local rmse    = self.rmse[lci]

        if not self:buildSpectrogram(samples, spectro) then
            -- Spectrograph building was interupted because taking too much time.
            -- Will be resumed.
            return false
        end

        -- RMSE cannot be interrupted so go ahead
        DSP.rmse(samples, rmse, S.instance_params.rms_window)

        -- Advance
        self.progress.ci  = self.progress.ci  + 1
        self.progress.si  = 0
    end

    self.analysis_finished = true

    -- Use average window of 1024 samples for the RMSE. For a signal at 48khz.,
    -- This is basically at window of 20ms which is the period of a 50hz sin (~G0)

    LOG.debug("---\n")
    LOG.debug("Energy conservation successfull tests : " .. self.energy_conservation_test_success .. " / " .. self.energy_conservation_test_count .. "\n")
    LOG.debug("---\n")
end

function SpectrumAnalysisContext:getProgress()
    local prog = 0.1

    if not self.render_finished then return prog, math.floor(prog * 100) .. " % - Rendering..." end
    if self.analysis_finished   then return 1,  "100 % - Finished" end

    local steps = self.slice_count * self.chan_count * 1.0

    prog = prog + (1-prog) * (self.slice_count * self.progress.ci + self.progress.si) / steps

    return prog, math.floor(prog * 100) .. " % - Processing..."
end

function SpectrumAnalysisContext:analyze()
    if not self.progress then
        -- First call to analyse
        -- Initialize state vars so that we can pause/resume the analysis
        self.analysis_finished                  = false

        self.energy_conservation_test_count     = 0
        self.energy_conservation_test_success   = 0

        self.progress    = {}
        self.progress.ci = 0
        self.progress.si = 0

        self:_buildAndRender()
        self.render_finished = true
    end

    if self.analysis_finished then return end

    self:resumeAnalysis()
end

function SpectrumAnalysisContext:fftHalfWindowDurationForOctava(octava)
    local samples = self.fft_params.effective_window_sample_count * 0.5
    return samples / self.sample_rate
end

-- Data index accessor for note_num
function SpectrumAnalysisContext:profileNumForNoteNum(note_num)
    if note_num < self.low_note      then note_num = self.low_note end
    if note_num > self.high_note + 1 then note_num = self.high_note + 1 end

    local note_offset = (note_num - self.low_note) / (self.high_note + 1 - self.low_note)

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
    DSP.analysis_data_extract_profile(self.spectrograms[chan_num], profile_buf, self.slice_count, self.slice_size, profile_num)
end
function SpectrumAnalysisContext:extractSliceProfile(chan_num, time, profile_buf)
    if not profile_buf then error("Developer error : should pass a valid reaper_array") end

    profile_buf = DSP.ensure_array_size(profile_buf, self.slice_size)
    local slice_num = self:sliceNumForTime(time)
    DSP.analysis_data_extract_slice(self.spectrograms[chan_num], profile_buf, self.slice_count, self.slice_size, slice_num)
end

function SpectrumAnalysisContext:extractRmseProfile(chan_num, profile_buf)
    local rmse = self.rmse[chan_num]

    if not profile_buf then error("Developer error : should pass a valid reaper_array") end
    profile_buf = DSP.ensure_array_size(profile_buf, #rmse)
    profile_buf.copy(rmse)
end

function SpectrumAnalysisContext:getRmseValueAt(chan_num, time)
    local sample_num = self:sampleNumForTime(time)

    return self.rmse[chan_num][sample_num]
end

function SpectrumAnalysisContext:getValueAt(chan_num, note_num, time)
    local profile_num = self:profileNumForNoteNum(note_num)
    local slice_num   = self:sliceNumForTime(time)

    return self.spectrograms[chan_num][slice_num * self.slice_size + profile_num + 1] -- Add 1, it's a reaper array !
end

return SpectrumAnalysisContext
-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- A class to pull some samples from a Source
-- With pre-buffering

local DSP       = require "modules/dsp"
local CSV       = require "modules/csv"

SampleAccessor = {}
SampleAccessor.__index = SampleAccessor

-- sample_rate is the sample rate of the signal to anayse
function SampleAccessor:new(spectrum_analysis_context)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(spectrum_analysis_context)
    return instance
end

function SampleAccessor:_initialize(spectrum_analysis_context)
    self.sac            = spectrum_analysis_context
    self.aa             = spectrum_analysis_context.signal.audio_accessor
    self.chan_count     = self.sac.chan_count
    self.sample_rate    = self.sac.sample_rate

    -- Use 1 second buffers because it's easier to use the API and be sure we're aligned !
    self.block_dur      = 1 -- Use integer value (seconds) !!
    self.block_size     = self.sample_rate * self.block_dur

    -- Read buffers
    self.rbuf            = DSP.ensure_array_size(self.rbuf, self.chan_count * self.block_size)
    self.rbufs           = {}
    for i=1, self.chan_count do
        self.rbufs[i] = DSP.ensure_array_size(self.rbufs[i], self.block_size)
    end

    -- Mem buffers (double size)
    self.bufs           = {}
    for i=1, self.chan_count do
        self.bufs[i] = DSP.ensure_array_size(self.bufs[i], 2 * self.block_size)
    end

    self.time_offset    = 0
    self.sample_offset  = 0
    --
    self:_readBack()
    self:_readFront()
end

function SampleAccessor:_read(time_offset)
    -- Read in rbuf
    local succ = reaper.GetAudioAccessorSamples(self.aa, self.sac.sample_rate, self.sac.chan_count, time_offset, self.block_size, self.rbuf)
    -- Deinterleave in rbufs
    DSP.array_deinterleave(self.rbuf, table.unpack(self.rbufs))
end

-- [ BACK | FRONT ]

function SampleAccessor:_dump(front_not_back)
    local bs            = self.block_size
    local dst_offset    = (front_not_back) and (bs + 1) or (1)
    for i=1, self.chan_count do
        -- Copy new samples into second half
        self.bufs[i].copy(self.rbufs[i], 1, bs, dst_offset)
    end
end

function SampleAccessor:_readFront()
    self:_read(self.time_offset + self.block_dur)
    self:_dump(true)
end

function SampleAccessor:_readBack()
    self:_read(self.time_offset)
    self:_dump(false)
end

function SampleAccessor:_shiftMem()
    local bs = self.block_size
    for i=1, self.chan_count do
        -- Copy second half into first half
        self.bufs[i].copy(self.bufs[i], bs + 1, bs, 1)
    end
end

function SampleAccessor:_advanceAndRead()
    self.time_offset    = self.time_offset      + self.block_dur
    self.sample_offset  = self.sample_offset    + self.block_size

    self:_shiftMem()
    self:_readFront()
end

--- For the following function, indices are zero-based
--- @param dst reaper.array
function SampleAccessor:getSamples(sample_num, sample_count, chan_num, dst, dst_offset)
    if sample_num < self.sample_offset then
        error("Developer error, trying to read before the accessor's beginning")
    end

    -- Advance till the wanted window end falls into our current read window
    while sample_num + sample_count > self.sample_offset + 2 * self.block_size do
        self:_advanceAndRead()
    end

    -- Get the samples
    dst.copy(self.bufs[chan_num], sample_num - self.sample_offset + 1, sample_count, dst_offset + 1)
end

return SampleAccessor

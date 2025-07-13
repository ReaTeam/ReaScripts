-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local SpectrogramChunk = require "classes/spectrogram_chunk"

-- Don't go beyond a certain amount of data to avoid breaking REAPER's limits (array size and EEL func memory)
local MAX_CHUNK_POINT_SIZE = 524288

local Spectrogram = {}
Spectrogram.__index = Spectrogram

-- A spectrogram is mono-channel, so we pass the chan_num as reference

-- sample_rate is the sample rate of the signal to anayse
function Spectrogram:new(spectrum_analysis_context, chan_num)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(spectrum_analysis_context, chan_num)
    return instance
end

function Spectrogram:_initialize(spectrum_analysis_context, chan_num)
    self.chan_num           = chan_num
    self.sac                = spectrum_analysis_context

    -- Number of slices that can be put in one chunk
    self.chunk_slice_count  = math.floor(MAX_CHUNK_POINT_SIZE / (self.sac.slice_size))
    -- Number of chunks to store the whole spectrogram (last one may be incomplete)
    self.chunk_count        = math.ceil( (1.0 * self.sac.slice_count) / self.chunk_slice_count)

    -- Chunks of data. Data is chunked because we're limited by the size of Reaper arrays and EEL func memory size
    self.chunks  = {}
    for chki=1, self.chunk_count do
        self.chunks[chki] = SpectrogramChunk:new(self, chki - 1)
    end
end

function Spectrogram:sliceInfo(slice_num)
    local chunk_num         = math.floor(slice_num / self.chunk_slice_count)
    local chunk_slice_num   = slice_num % self.chunk_slice_count

    return {
        chunk_num       = chunk_num,
        chunk_slice_num = chunk_slice_num,
    }
end

function Spectrogram:saveSlice(slice_buf, slice_num)
    local sinfo = self:sliceInfo(slice_num)
    self.chunks[sinfo.chunk_num+1]:saveSlice(slice_buf, sinfo.chunk_slice_num)
end

function Spectrogram:extractSlice(slice_buf, slice_num)
    local sinfo = self:sliceInfo(slice_num)
    self.chunks[sinfo.chunk_num+1]:extractSlice(slice_buf, sinfo.chunk_slice_num)
end

function Spectrogram:extractNoteProfile(profile_buf, profile_num)
    for chki=1, self.chunk_count do
        -- Reconstitute full profile from segments
        self.chunks[chki]:extractNoteProfileSegment(profile_buf, profile_num)
    end
end

function Spectrogram:getValueForSliceAndProfile(slice_num, profile_num)
    local sinfo = self:sliceInfo(slice_num)
    return self.chunks[sinfo.chunk_num+1].data[sinfo.chunk_slice_num * self.sac.slice_size + profile_num + 1]
end

return Spectrogram

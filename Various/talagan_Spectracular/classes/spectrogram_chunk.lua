-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- This is a spectrogram chunk.
-- Due to reaper's limitations (size of arrays and memory of EEL functions)
-- spectrograms are chunked

local DSP   = require "modules/dsp"

local SpectrogramChunk = {}
SpectrogramChunk.__index = SpectrogramChunk

-- sample_rate is the sample rate of the signal to anayse
function SpectrogramChunk:new(spectrogram, chunk_num)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(spectrogram, chunk_num)
    return instance
end

function SpectrogramChunk:_initialize(spectrogram, chunk_num)
    self.spectrogram        = spectrogram
    self.sac                = spectrogram.sac
    self.chan_num           = spectrogram.chan_num
    self.chunk_num          = chunk_num

    self.first_slice_offset = chunk_num * spectrogram.chunk_slice_count
    self.slice_count        = (self.first_slice_offset + spectrogram.chunk_slice_count < self.sac.slice_count)
        and (spectrogram.chunk_slice_count)
        or (self.sac.slice_count - self.first_slice_offset)

    self.data_size          = self.slice_count * self.sac.slice_size

    self.data               = DSP.ensure_array_size(self.data, self.data_size)
end

function SpectrogramChunk:saveSlice(slice_buf, slice_sub_num)
    self.data.copy(slice_buf, 1, self.sac.slice_size, slice_sub_num * self.sac.slice_size + 1)
end

function SpectrogramChunk:extractSlice(slice_buf, slice_sub_num)
    slice_buf.copy(self.data, slice_sub_num * self.sac.slice_size + 1, self.sac.slice_size, 1)
end

-- Data is saved with consecutive slices, but a profile is a temporal "cut" so it takes one sample from each slice
-- To de-interleave a profile, we use an EEL function
function SpectrogramChunk:extractNoteProfileSegment(profile_buf, profile_num)
    self.note_extract_buf = DSP.ensure_array_size(self.note_extract_buf, self.slice_count)
    DSP.analysis_data_extract_profile(self.data, self.note_extract_buf, self.slice_count, self.sac.slice_size, profile_num)

    -- Copy the segment to the full profile buf
    profile_buf.copy(self.note_extract_buf, 1, self.slice_count, self.first_slice_offset+1)
end

return SpectrogramChunk

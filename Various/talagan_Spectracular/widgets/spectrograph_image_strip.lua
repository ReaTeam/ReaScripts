-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- This class creates an "Image Strip", which is a serie of images that can be put side by side as textures
-- To show the complete spectrograph of an analysis
-- This class is needed because the max texture size in ImGui is 8192, so we have to "chunk" the rendering into
-- multiple textures. They will be then put at the right place in the spectrograph viewport.

local ImGui = require "ext/imgui"
local DSP   = require "modules/dsp"

local SpectrographImageStrip = {}
SpectrographImageStrip.__index = SpectrographImageStrip

local MAX_SIZE = 8192

-- ctx : imgui ctx so that we can attach ImGui images
-- spectrum_analysis_context : access to the analysis data

function SpectrographImageStrip:new(ctx)
    local instance = {}
    setmetatable(instance, self)
    self:_initialize()
    return instance
end

function SpectrographImageStrip:_initialize()
    self.images = {}
end

function SpectrographImageStrip:update(ctx, spectrum_analysis_context, lr_balance, dbmin, dbmax)
    self.ctx    = ctx
    self.sac    = spectrum_analysis_context
    self:createOrResizeImages()
    self:fillImages(lr_balance, dbmin, dbmax)
end

function SpectrographImageStrip:createOrResizeImages()

    local ctx       = self.ctx
    local width     = self.sac.slice_count
    local height    = self.sac.slice_size

    -- Reuse our images if everything fits
    if width == self.width and height == self.height then return end

    -- Get rid of the old images, the strip is resized.
    self:detach(ctx)
    self.images = {}

    -- Use channel 1's spectogram as reference for the chunk size
    local ref_spectro = self.sac.spectrograms[1]
    local chunk_width = ref_spectro.chunk_slice_count

    -- We want to use only multiples of chunk width for images
    -- Because our EEL function that fills images with chunks is only
    -- able to take full chunks, not partials with offsets
    local max_width   = chunk_width * math.floor(MAX_SIZE/chunk_width)

    -- Index pixels counting from 0... grrrr lua
    local l = 0
    while l < width do
        -- r is the index of the last pixel (so, included in the image)
        local r = l + max_width - 1

        if r > width - 1 then r = width - 1 end

        local imw = r - l + 1
        local imh = height

        local imgui_image = ImGui.CreateImageFromSize(imw, imh)
        ImGui.Attach(ctx, imgui_image)

        self.images[#self.images+1] = {
            image               = imgui_image,
            w                   = imw,
            h                   = imh,
            pl                  = l,     -- Left boundary in the pixel scale        |_|_|_|_|_|
            pr                  = r + 1, -- Right boundary in the pixel scale       L         R
            ul                  = l/width,
            ur                  = (r + 1)/width
        }

        l = r + 1
    end

    self.width  = width
    self.height = height
end

function SpectrographImageStrip:fillImages(lr_balance, dbmin, dbmax)
    local sac           = self.sac
    local spectrograms  = sac.spectrograms

    -- Chan coeffs for the mix
    local coeffs = reaper.new_array(sac.chan_count)
    if sac.chan_count >= 2 then
        coeffs[1] = lr_balance
        coeffs[2] = 1 - lr_balance
    else
        coeffs[1] = 1
    end

    -- Use channel 1 spectrogram as reference (they all have the same structure across channels)
    local ref_spectro       = spectrograms[1]

    local IMGUI_FORMAT      = 1

    -- Image iterator
    local function new_iterator(i)
        return {
            index  = i,
            image  = self.images[i],
            cursor = 0
        }
    end

    -- Start on first image
    local iterator = new_iterator(1)

    local function iterate_image()
        local i = (iterator and iterator.index or 0)
        return new_iterator(i+1)
    end

    local function accumulate_in_iterator(chunk_width)
        iterator.cursor = iterator.cursor + chunk_width

        return (iterator.cursor >= iterator.image.w)
    end

    -- The aim is to fill all images with chunks
    -- Loop on all chunks of the spectro
    for chunki=1, ref_spectro.chunk_count do
        local ref_chunk = ref_spectro.chunks[chunki]

        -- Create or reuse temporary RGB buffer
        self.rgb_buf = DSP.ensure_array_size(self.rgb_buf, ref_chunk.data_size)

        -- Build multi-channel chunk
        -- We're going to mix all channels using our coeffs
        local spectro_chunk_datas = {}
        for chani = 1, sac.chan_count do
            spectro_chunk_datas[chani] = spectrograms[chani].chunks[chunki].data
        end

        -- Convert chunk data to RGB
        DSP.analysis_data_to_rgb_array(spectro_chunk_datas, coeffs, self.rgb_buf, dbmin, dbmax, sac.slice_size, IMGUI_FORMAT)

        -- Blit RGB array in the current image
        -- Chunks are indexed globally, with their offsets in slices (or pixels)
        -- So their relative index inside the image should be calculated by substracting image.pl
        local t1 = reaper.time_precise()
        ImGui.Image_SetPixels_Array(iterator.image.image, ref_chunk.first_slice_offset - iterator.image.pl, 0, ref_chunk.slice_count, sac.slice_size, self.rgb_buf)
        local t2 = reaper.time_precise()

        if accumulate_in_iterator(ref_chunk.slice_count) then
            iterator = iterate_image()
        end
    end

    --self:exportToTga()
end

function SpectrographImageStrip:detach(ctx)
    for _, img in ipairs(self.images) do
        ImGui.Detach(ctx, img.image)
    end
    self.images = {}
end

function SpectrographImageStrip:exportToTga()
    local CHUNK_SIZE = 1024 * 1024 -- 1 MB memory footprint

    local t1 = reaper.time_precise()
    for _, img in ipairs(self.images) do
        local file_path     = "/Users/ben/Downloads/toto-" .. _ .. ".tga"
        local file          = assert(io.open(file_path, "wb"))
        local buffer        = reaper.new_array(img.w * img.h)
        ImGui.Image_GetPixels_Array(img.image, 0, 0, img.w, img.h, buffer)

        -- En-tête TGA (18 octets)
        file:write(string.char(
            0,      -- ID length
            0,      -- Color map type
            2,      -- Image type: uncompressed true-color
            0, 0,   -- Color map origin
            0, 0,   -- Color map length
            0,      -- Color map depth
            0, 0,   -- X-origin
            0, 0,   -- Y-origin
            img.w % 256, math.floor(img.w / 256),
            img.h % 256, math.floor(img.h / 256),
            32,     -- Bits per pixel
            40       -- Image descriptor (alpha bits), top left corner reversed
        ))

        local chunk = {}
        local chunk_size = 0

        local flush_chunk = function()
            if chunk_size > 0 then
                file:write(table.concat(chunk))
                chunk = {}
                chunk_size = 0
            end
        end

        for i = 1, #buffer do
            local color = buffer[i]
            local r = (color >> 24) & 0xFF
            local g = (color >> 16) & 0xFF
            local b = (color >> 8)  & 0xFF
            local a = color & 0xFF

            local pixel_data = string.char(b, g, r, a)
            chunk[#chunk + 1] = pixel_data
            chunk_size = chunk_size + 4

            if chunk_size >= CHUNK_SIZE then
                flush_chunk()
            end
        end

        flush_chunk()
        file:close()
    end
    local t2 = reaper.time_precise()

    reaper.ShowConsoleMsg("Dump :" .. (t2 - t1) .. "\n")
end

return SpectrographImageStrip

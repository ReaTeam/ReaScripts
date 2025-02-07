-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- A few midi helpers

local function midiNoteToFrequency(n)
    return 440 * 2^( (n-69)/12 )
end

-- Midi note number. octava_num goes from -1 to 9
local function midiNoteNumber(ocatava_num, index_0_11)
    -- A4 -> 69
    return (ocatava_num + 1) * 12 + index_0_11
end

local note_names = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
local function noteName(note_num)
    local n  = math.floor(note_num + 0.5) -- use round if floating
    local nn = (n % 12)
    local o  = math.floor(n/12) - 1
    return "" .. note_names[nn+1] .. "" .. o
end

return {
    noteNumber      = midiNoteNumber,
    noteToFrequency = midiNoteToFrequency,
    noteName        = noteName
}

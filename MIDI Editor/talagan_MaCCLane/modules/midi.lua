-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local note_names = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }
local function noteName(note_num)
    local n  = math.floor(note_num + 0.5) -- use round if floating
    local nn = (n % 12)
    local o  = math.floor(n/12) - 1
    return "" .. note_names[nn+1] .. "" .. o
end

return {
    noteName = noteName
}
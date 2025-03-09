-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local function hasPitchBendSnap(track_chunk)
    local snap = 0
    for line in track_chunk:gmatch("[^\n]+") do
        if line:find("MIDIEDITOR ") then
            local i = 0
            for w in line:gmatch("%S+") do
                if i == 2 then snap = tonumber(w) or 0; break; end
                i = i + 1
            end
            break
        end
    end
    return (snap == 1)
end

return {
    hasPitchBendSnap = hasPitchBendSnap
}

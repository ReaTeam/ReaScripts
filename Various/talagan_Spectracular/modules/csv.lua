-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

-- Helper debug dump functions
local function file_dumper(file_name, count, func)
    local file = io.open(file_name, "wb")
    if not file then return end

    for i=1, count do
        file:write(func(i))
    end

    file:close()
end

local function dump(file_name, values)
    file_dumper(file_name, #values, function(i) return "" .. values[i] .. "\n" end)
end

local function dump2(file_name, xvalues, yvalues)
    file_dumper(file_name, #xvalues, function(i) return "" .. xvalues[i] .. "," .. yvalues[i] .. "\n" end)
end

return {
    dump = dump,
    dump2 = dump2
}

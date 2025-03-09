-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local UTILS = require "modules/utils"

local Enum = {}
Enum.__index = Enum

function Enum:new(defs)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(UTILS.deepcopy(defs))
    return instance
end

function Enum:_initialize(defs)
    local v          = 0
    self.defs        = defs
    self.v_lookup    = {}
    self.n_lookup    = {}
    for _, def in ipairs(defs) do
        if not def.name  then error("Enum value is missing 'name' field") end
        if not def.human then error("Enum value is missing 'human' field") end

        if def.v then
            v = def.v
        else
            v = v + 1
            def.v = v
        end

        if self.v_lookup[v] then
            error("Enum value '" .. v .. "' is already present")
        end

        if self.n_lookup[def.name] then
            error("Enum entry name '" .. def.name .. "' is already present")
        end

        self.v_lookup[def.v]    = def
        self.n_lookup[def.name] = def
    end
end

function Enum:humanize(name)
    return self.n_lookup[name].human
end

function Enum:vhumanize(v)
    return self.v_lookup[v].human
end

function Enum:entryByName(name)
    return self.n_lookup[name]
end

function Enum:entryByValue(v)
    return self.v_lookup[v]
end

function Enum:sanitize(name, default_name)
    if not self.n_lookup[default_name] then error("Developer error ! Entry '" .. default_name .. "' does not exist in enum.") end
    if not self.n_lookup[name] then return default_name end
    return name
end

return Enum

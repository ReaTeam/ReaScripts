-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local S         = require "modules/settings"
local JSON      = require "lib/json"

local pattern   = "by (%l+) (.*)%.lua"

function EnqueueAction(action)
    local by_what, ident = action:match(pattern)
    if by_what then
        if by_what == 'role' then 
            S.setSetting("QueuedAction", JSON.encode({ role=ident , type = 'role' }))
        elseif by_what == 'name' then 
            S.setSetting("QueuedAction", JSON.encode({ name=ident , type = 'name' }))
        elseif by_what == 'number' then
        ident = tonumber(ident)
        if ident then
            S.setSetting("QueuedAction", JSON.encode({ number=ident , type = 'number' }))
        end
        end
    end
end

return {
    EnqueueAction = EnqueueAction
}
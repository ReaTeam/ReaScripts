-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .. "classes/" .. "?.lua;".. package.path
local S           = require "modules/settings"

local _,fname,_,_,_,_,v,ctxs = reaper.get_action_context()
local param                  = fname:match("%- %(([^%s]*)%)%.lua$");

if (param == "MIDI") and (ctxs:match("^midi:")) then
    local vcount = 7
    local mn = math.floor(0.5 + (v / 127.0) * (vcount-1)) + 1

    if(mn == 1)     then param = "1_64"
    elseif(mn == 2) then param = "1_32"
    elseif(mn == 3) then param = "1_16"
    elseif(mn == 4) then param = "1_8"
    elseif(mn == 5) then param = "1_4"
    elseif(mn == 6) then param = "1_2"
    else                 param = "1"
    end

    S.setNoteLen(param)
end


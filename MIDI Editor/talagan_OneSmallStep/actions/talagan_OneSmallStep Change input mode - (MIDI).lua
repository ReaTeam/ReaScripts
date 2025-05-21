-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of One Small Step

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .. "classes/" .. "?.lua;".. package.path

local S           = require "modules/settings"
local D           = require "modules/defines"

local _,fname,_,_,_,_,v,ctxs = reaper.get_action_context()
local param                  = fname:match("%- %(([^%s]*)%)%.lua$");

if (param == "MIDI") and (ctxs:match("^midi:")) then
    local vcount    = 3
    local mn        = math.floor(0.5 + (v / 127.0) * (vcount-1)) + 1

    if(mn == 1)     then param = "KeyboardPress"
    elseif(mn == 2) then param = "Punch"
    else                 param = "KeyboardRelease"
    end

    S.setInputMode(D.InputMode[param])
end



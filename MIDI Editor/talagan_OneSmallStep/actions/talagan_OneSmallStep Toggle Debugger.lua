-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description Enables/Disables debugging with mobdebug

package.path      = debug.getinfo(1,"S").source:match[[^@?(.*[\/])actions[\/][^\/]-$]] .. "classes/" .. "?.lua;".. package.path

local S           = require "modules/settings"

local don = S.getSetting("UseDebugger")
don = not don

S.setSetting("UseDebugger", don)

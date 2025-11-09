-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of EmojImGui

-- This file is main API entry point and should be the only one to require

local Asset     = require "emojimgui/modules/assets"
local Picker    = require "emojimgui/widgets/picker"

return {
    Asset   = Asset,
    Picker  = Picker
}

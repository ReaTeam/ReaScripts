-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Legatool

local S                             = require "modules/settings"

-- Private pointers
local OS                            = reaper.GetOS()
local is_windows                    = OS:match('Win')
local is_macos                      = OS:match('OSX') or OS:match('macOS')
local is_linux                      = OS:match('Other')

local full_context = {
    is_windows                  = is_windows,
    is_macos                    = is_macos,
    is_linux                    = is_linux,
}

return full_context

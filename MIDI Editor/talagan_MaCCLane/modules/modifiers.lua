-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local os                            = reaper.GetOS()
local is_windows                    = os:match('Win')
local is_macos                      = os:match('OSX') or os:match('macOS')
local is_linux                      = os:match('Other')

    -- return (reaper.JS_VKeys_GetState(launchTime):byte(17) == 1)

    -- Control (Windows) or Command (macOS) key (1 << 2) == 4
    -- Shift key : (1 << 3) == 8
    -- Alt (Windows) or Option (macOS) key (1 << 4) == 16
    -- Windows (Windows) or Control (macOS) key : (1 << 5) == 32

local function ShiftIsDown()
    return (reaper.JS_Mouse_GetState(1<<3) ~= 0)
end

local function WinControlMacCmdIsDown()
    return (reaper.JS_Mouse_GetState(1<<2) ~= 0)
end


return {
    ShiftIsDown             = ShiftIsDown,
    WinControlMacCmdIsDown  = WinControlMacCmdIsDown
}

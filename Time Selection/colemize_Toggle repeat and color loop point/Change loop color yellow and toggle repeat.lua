-- @noindex

--[[
    Cole Mize Studios
    REAPER Script: Toggle Repeat + Loop-Point Timeline Background
    Created by: Cole Mize
    Version: 1.0

    Description:
    Toggles REAPER's Repeat function and changes the loop-point
    timeline background color based on the Repeat state.

    Repeat ON  = Yellow/Orange (255, 194, 30)
    Repeat OFF = White         (255, 255, 255)
--]]

local REPEAT_COMMAND = 1068

-- Toggle REAPER Repeat
reaper.Main_OnCommand(REPEAT_COMMAND, 0)

-- Get the NEW repeat state
local repeat_state = reaper.GetToggleCommandState(REPEAT_COMMAND)

local r, g, b

if repeat_state == 1 then
    -- Repeat ON = Yellow/Orange
    r = 255
    g = 194
    b = 30
else
    -- Repeat OFF = White
    r = 255
    g = 255
    b = 255
end

-- Convert RGB to REAPER native color
local color = reaper.ColorToNative(r, g, b)

-- Timeline background (in loop points)
reaper.SetThemeColor("col_tl_bgsel2", color, 0)

-- Refresh REAPER
reaper.UpdateArrange()
reaper.UpdateTimeline()

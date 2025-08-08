-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Spectracular

local ImGui = require "ext/imgui"

local launchTime = reaper.time_precise()

local function dbValToString(dbval)
    return (dbval and string.format("%.1f", dbval) or "?"):gsub("%.0+$", "")
end

local function splitRGBA(rgba)
    return ((rgba & 0xFF000000) >> 24) / 255.0, ((rgba & 0xFF0000) >> 16) / 255.0, ((rgba & 0xFF00) >> 8) / 255.0, rgba & 0xFF
end

local function assembleRGBA(r,g,b,a)
    return ((math.floor(r * 255) & 0xFF) << 24) | ((math.floor(g * 255) & 0xFF) << 16) | ((math.floor(b * 255) & 0xFF) << 8) | a
end

local function benchmark(cb, should_print)
    local t1 = reaper.time_precise()
    cb()
    local t2 = reaper.time_precise();
    if should_print then
        reaper.ShowConsoleMsg("Ellapsed : " .. (t2 - t1) .. " seconds\n")
    end
    return t2 - t1
end

local function colToBgCol(rgba, lumfac, alpha)
    local bg_col     = rgba
    local r,g,b,a    = splitRGBA(rgba)
    local h,s,v      = ImGui.ColorConvertRGBtoHSV(r, g, b)

    v                = v * lumfac
    r,g,b            = ImGui.ColorConvertHSVtoRGB(h, s, v)
    a                = math.floor(alpha * 255) & 0xFF

    bg_col           =  assembleRGBA(r,g,b,a)
    return bg_col
end

local function colLerp(rgba1, rgba2, alpha)
    local r1,g1,b1,a1   = splitRGBA(rgba1)
    local r2,g2,b2,a2   = splitRGBA(rgba2)

    local h1,s1,v1      = ImGui.ColorConvertRGBtoHSV(r1,g1,b1)
    local h2,s2,v2      = ImGui.ColorConvertRGBtoHSV(r2,g2,b2)

    local r,g,b         = ImGui.ColorConvertHSVtoRGB(h1 + alpha * (h2 - h1), s1 + alpha * (s2 - s1), v1 + alpha * (v2 - v1))
    local a             = a1 + alpha * (a2 - a1)

    return assembleRGBA(r,g,b,a)
end

local function modifierKeyIsDown()
    -- return (reaper.JS_VKeys_GetState(launchTime):byte(17) == 1)

    -- Control (Windows) or Command (macOS) key (1 << 2) == 4
    -- Shift key : (1 << 3) == 8
    -- Alt (Windows) or Option (macOS) key (1 << 4) == 16
    -- Windows (Windows) or Control (macOS) key : (1 << 5) == 32

    return (reaper.JS_Mouse_GetState(1<<2) ~= 0)
end

-----------------

local msx = -1
local msy = -1
local mst = reaper.time_precise() + 100000000

local function mouseStallUpdate(ctx)
    local mx, my = ImGui.GetMousePos(ctx)
    if mx == msx and my == msy then return end

    msx = mx
    msy = my
    mst = reaper.time_precise()
end

local function isMouseStalled(thresh)
    return (reaper.time_precise() - mst > thresh)
end

-------------

return {
    modifierKeyIsDown = modifierKeyIsDown,
    dbValToString = dbValToString,
    mouseStallUpdate = mouseStallUpdate,
    isMouseStalled = isMouseStalled,

    colToBgCol = colToBgCol,
    colLerp = colLerp,

    benchmark = benchmark
}

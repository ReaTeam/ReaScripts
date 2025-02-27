-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local ImGui                         = require 'imgui' '0.9.3'

local os                            = reaper.GetOS()
local is_windows                    = os:match('Win')
local is_macos                      = os:match('OSX') or os:match('macOS')
local is_linux                      = os:match('Other')

local FONT_FACE = 'Arial'
local FONT_SIZE = is_windows and 12 or 11

-- The only way to configure a lice font is to use a gdi font ...
local gdi_font  = reaper.JS_GDI_CreateFont(FONT_SIZE, 0, 0, false, false, false, FONT_FACE)
local lice_font = reaper.JS_LICE_CreateFont()
reaper.JS_LICE_SetFontFromGDI(lice_font, gdi_font, '')

-- The the same font in GFX so that we can perform correct text measurements
gfx.setfont(1, FONT_FACE , FONT_SIZE)

return {
    ImGui                       = ImGui,

    FONT_FACE                   = FONT_FACE,
    FONT_SIZE                   = FONT_SIZE,

    TABBAR_HEIGHT               = 19,
    MACCLANE_MAGIC_PIXEL        = 0x01573462,

    last_mouse_x                = nil,
    last_mouse_y                = nil,
    last_redraw                 = nil,

    lice_font                   = lice_font,
    gdi_font                    = gdi_font,

    is_windows                  = is_windows,
    is_macos                    = is_macos,
    is_linux                    = is_linux,

    notifySettingsChange        = function() end
}

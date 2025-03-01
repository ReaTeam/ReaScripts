-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of MaCCLane

local S                             = require "modules/settings"

local ImGui                         = require 'imgui' '0.9.3'

-- Private pointers
local images    = {}
local gdi_font  = nil
local lice_font = nil

local os                            = reaper.GetOS()
local is_windows                    = os:match('Win')
local is_macos                      = os:match('OSX') or os:match('macOS')
local is_linux                      = os:match('Other')

local FONT_FACE                     = 'Arial'

local full_context = {
    ImGui                       = ImGui,

    FONT_FACE                   = FONT_FACE,

    TABBAR_HEIGHT               = 19,
    MACCLANE_MAGIC_PIXEL        = 0x01573462,

    last_mouse_x                = nil,
    last_mouse_y                = nil,
    last_redraw                 = nil,

    is_windows                  = is_windows,
    is_macos                    = is_macos,
    is_linux                    = is_linux,

    notifySettingsChange        = function() end
}

local function GetImage(image_name)
  if not full_context.ImGuiContext then return end
  local ctx = full_context.ImGuiContext
  if (not images[image_name]) or (not ImGui.ValidatePtr(images[image_name], 'ImGui_Image*')) then
    local bin = require("images/" .. image_name)
    images[image_name] = ImGui.CreateImageFromMem(bin)
    ImGui.Attach(ctx, images[image_name])
  end
  return images[image_name]
end

local function EnsureImGuiCtx()
    if not full_context.ImGuiContext then
        full_context.ImGuiContext = ImGui.CreateContext('MaCCLane', ImGui.ConfigFlags_NavEnableKeyboard)
    end
end

local function DropImGuiCtx()
    full_context.ImGuiContext = nil
    images = {}
end

local function destroyFont()
    if lice_font then reaper.JS_LICE_DestroyFont(lice_font) end
    if gdi_font  then reaper.JS_GDI_DeleteObject(gdi_font) end
end

local function recreateFont(size)
    destroyFont()
    gdi_font  = reaper.JS_GDI_CreateFont(size, 0, 0, false, false, false, FONT_FACE)
    lice_font = reaper.JS_LICE_CreateFont()
    reaper.JS_LICE_SetFontFromGDI(lice_font, gdi_font, '')
    gfx.setfont(1, FONT_FACE , size)
end

local function LiceFont()
    return lice_font
end

local function GDIFont()
    return gdi_font
end

recreateFont(S.getSetting("FontSize"))

-- Keep the font pointers private, and export methods
full_context.LiceFont        = LiceFont
full_context.GDIFont         = GDIFont
full_context.recreateFont    = recreateFont
full_context.destroyFont     = destroyFont

full_context.EnsureImGuiCtx  = EnsureImGuiCtx
full_context.DropImGuiCtx    = DropImGuiCtx
full_context.GetImage        = GetImage

return full_context
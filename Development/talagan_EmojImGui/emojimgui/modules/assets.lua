-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of EmojImGui

---@diagnostic disable: unused-function, need-check-nil
local JSON          = require "emojimgui/ext/json"
local ImGui         = require "emojimgui/ext/imgui"

local asset_path    = (debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]]):gsub("/emojimgui/modules/?$","") .. "/assets/build/"

-- Font registry with relative paths
local FONT_REGISTRY = {
    OpenMoji = {
        json = "/openmoji-spec.json",
        lua  = "/openmoji-spec.lua",
        ttf  = "/OpenMoji-color-glyf_colr_0-patched.ttf",
        advised_background_color = 0x9EB8FFFF
    },
    TweMoji = {
        json = "/twemoji-spec.json",
        lua  = "/twemoji-spec.lua",
        ttf  = "/TweMoji-color-glyf_colr_0-patched.ttf",
        advised_background_color = 0x00000000
    }
}

local function SetPath(ap)
    asset_path = ap
end

local function Path()
    return asset_path
end

local function FontInfo(font_name)
    local info = FONT_REGISTRY[font_name]
    if not info then
        error("Font '" .. font_name .. "' is not handled by the Library !")
    end
    return info
end

local function FontSpec(font_name)
    local info = FontInfo(font_name)

    if not info.loaded_spec then

        local success, result = false, nil
        if false then
            local path = Path() .. info.json
            local file = io.open(path, "r")

            if not file then
                error("Error: cannot open '" .. path .. "'\n")
                return
            end

            local content = file:read("*all")
            file:close()

            success, result = pcall(function()
                return JSON.decode(content) or nil
            end)

            if not success or not result then
                reaper.ShowConsoleMsg("Error: cannot parse JSON spec for font " .. font_name .. "\n")
                return
            end
        else
            -- Fast lua loading
            local path = Path() .. info.lua
            result = dofile(path)
            if not result then
                reaper.ShowConsoleMsg("Error: cannot parse LUA spec for font " .. font_name .. "\n")
                return
            end
        end

        info.loaded_spec = {}
        info.loaded_spec.groups = result.groups

        -- Process icon data
        local icon_dict = {}

        local function normalizeIconTags(icon)
            local tags = {}
            if icon.t then
                for tag in icon.t:gmatch("%S+") do
                    tag = tag:lower()
                    tags[#tags+1] = tag
                end
            end
            icon.t = tags
        end

        for _, group in ipairs(result.groups) do
            for _, subgroup in ipairs(group.s or {}) do
                for _, icon in ipairs(subgroup.c or {}) do
                    -- Build UTF-8 character
                    icon.utf8 = utf8.char(icon.p)
                    icon_dict[icon.x] = icon
                    normalizeIconTags(icon)

                    -- Process variants (skin tones)
                    if icon.v then
                        for _, variant in ipairs(icon.v) do
                            variant.utf8            = utf8.char(variant.p)
                            icon_dict[variant.x]    = variant
                            normalizeIconTags(variant)
                        end

                        -- Force skin tone to 0 if icon has variants
                        if #icon.v > 0 then
                            icon.k = 0
                        end
                    end
                end
            end
        end
        info.loaded_spec.icon_dict                  = icon_dict
        info.loaded_spec.advised_background_color   = info.advised_background_color
    end

    return info.loaded_spec
end

local function Font(ctx, font_name)
    local info = FontInfo(font_name)

    if not info.loaded_fonts then info.loaded_fonts = {} end
    if not info.loaded_fonts[ctx] then
        local path = Path() .. info.ttf
        local font = ImGui.CreateFontFromFile(path)
        if font then
            info.loaded_fonts[ctx] = font
            ImGui.Attach(ctx, font)
        else
            error("Cannot load font '" .. path .. "'\n")
        end
    end

    return info.loaded_fonts[ctx]
end

local function CharInfo(font_name, char_id)
    local spec = FontSpec(font_name)
    local icon = spec.icon_dict[char_id]
    if not icon then return nil end

    return {
        id          = icon.x,
        label       = icon.l,
        codepoint   = icon.p,
        utf8        = icon.utf8,
        font_name   = icon.current_font_name
    }
end

return {
    Path        = Path,
    SetPath     = SetPath,
    FontSpec    = FontSpec,
    Font        = Font,
    CharInfo    = CharInfo
}

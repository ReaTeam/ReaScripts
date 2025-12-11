-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- This is the core widget's logic

local ImGui         = require "reaimgui_markdown/ext/imgui"
local ParseMarkdown = require "reaimgui_markdown/markdown-ast"
local ImGuiMdCore   = require "reaimgui_markdown/markdown-imgui"

local function deepMerge(t1, t2)
    for k,v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                deepMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local ReaImGuiMd = {}

ReaImGuiMd.__index = ReaImGuiMd
function ReaImGuiMd:new(ctx, id, options, style)
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize(ctx, id, options, style)
    return instance
end

-- Possible options
-------------------
--  wrap (true | false)
--  autopad (true | false)
--  horizontal_scrollbar (true | false)
--  skip_last_whitespace (true | false)
--  width (0 == auto, use remaining)
--  height (0 == auto, use remaining)
function ReaImGuiMd:_initialize(ctx, id, options, partial_style)
    self.id         = id
    self.options    = { wrap = true, horizontal_scrollbar = true , width = 0, height = 0, additional_window_flags = 0 }
    self.style      = deepCopy(ImGuiMdCore.DEFAULT_STYLE)
    self:setText("")

    self:setPartialStyle(partial_style)
    self:setOptions(options)
    self:_createFontsIfNeeded(ctx)
end

function ReaImGuiMd:setPartialStyle(style)
    deepMerge(self.style, style)
end

function ReaImGuiMd:setStyle(style)
    self.style = deepCopy(style)
end

function ReaImGuiMd:setOptions(options)
    deepMerge(self.options, options)
end

function ReaImGuiMd:updateCtx(ctx)
    self:_createFontsIfNeeded(ctx)
end

local font_repository = {} -- ctx -> font_name -> font
function ReaImGuiMd:_createFontsIfNeeded(ctx)

    if not font_repository[ctx] then
        font_repository[ctx] = {}
    end

    local fr = font_repository[ctx]

    -- Else recreate all fonts in the new context
    local style = self.style

    for class_name, _ in pairs(ImGuiMdCore.DEFAULT_STYLE) do
        -- 0 is for normal text, 1 for h1, 2 for h2, etc
        local fontfam   = style[class_name].font_family

        if fontfam and not fr[fontfam] then
            local font = {
                normal      = ImGui.CreateFont(fontfam),
                bold        = ImGui.CreateFont(fontfam, ImGui.FontFlags_Bold),
                italic      = ImGui.CreateFont(fontfam, ImGui.FontFlags_Italic),
                bolditalic  = ImGui.CreateFont(fontfam, ImGui.FontFlags_Italic | ImGui.FontFlags_Bold),
            }

            ImGui.Attach(ctx, font.normal)
            ImGui.Attach(ctx, font.bold)
            ImGui.Attach(ctx, font.italic)
            ImGui.Attach(ctx, font.bolditalic)

            fr[fontfam] = font
        end
    end

    -- Remember font ctx
    self.font_ctx = ctx
end


function ReaImGuiMd:setText(text)
    if text == self.text then return end

    self.text = text
    self.ast  = ParseMarkdown(self.text)
end

function ReaImGuiMd:render(ctx)
    if ctx ~= self.font_ctx then
        error("Developer error : ImGui's context has changed but you forgot to update ReaImGuiMd fonts !")
    end

    local window_flags = 0 | self.options.additional_window_flags
    local child_flags  = 0

    if self.options.horizontal_scrollbar then
       window_flags = window_flags | ImGui.WindowFlags_HorizontalScrollbar
    end

    if ImGui.BeginChild(ctx, "##" .. self.id, self.options.width, self.options.height, child_flags, window_flags) then
        self.max_x, self.max_y, self.interaction = ImGuiMdCore.ASTToImgui(ctx, self.ast, font_repository[ctx], self.style, self.options)
        ImGui.EndChild(ctx)
    end

    return self.max_x, self.max_y, self.interaction
end

return ReaImGuiMd

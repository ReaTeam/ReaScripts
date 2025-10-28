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

local function deepCopy(t2)
    return deepMerge({}, t2)
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
    self.options    = { wrap = true, horizontal_scrollbar = true , width = 0, height = 0 }
    self.style      = deepCopy(ImGuiMdCore.DEFAULT_STYLE)
    self.text       = ""
    self.ast        = {}

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

function ReaImGuiMd:_createFontsIfNeeded(ctx)

    self.font_ctx  = nil

    if self.fonts and self.ctx == self.font_ctx then return end

    local fonts = {}
    local style = self.style

    for class_name, _ in pairs(ImGuiMdCore.DEFAULT_STYLE) do
        -- 0 is for normal text, 1 for h1, 2 for h2, etc
        local fontfam   = style[class_name].font_family

        if fontfam and not fonts[fontfam] then
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

            fonts[fontfam] = font
        end
    end

    self.fonts    = fonts
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

    local window_flags = 0
    local child_flags  = 0

    if self.options.horizontal_scrollbar then
       window_flags = window_flags | ImGui.WindowFlags_HorizontalScrollbar
    end

    if ImGui.BeginChild(ctx, "##" .. self.id, self.options.width, self.options.height, child_flags, window_flags) then
        self.max_x, self.max_y, self.interaction = ImGuiMdCore.ASTToImgui(ctx, self.ast, self.fonts, self.style, self.options)
        ImGui.EndChild(ctx)
    end

    return self.max_x, self.max_y, self.interaction
end

return ReaImGuiMd

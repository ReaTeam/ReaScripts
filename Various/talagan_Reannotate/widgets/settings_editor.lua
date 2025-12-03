-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local ImGui         = require "ext/imgui"
local AppContext    = require "classes/app_context"
local Color         = require "classes/color"
local Sticker       = require "classes/sticker"
local Notes         = require "classes/notes"
local S             = require "modules/settings"
local D             = require "modules/defines"

local ImGuiMd       = require "reaimgui_markdown"

local SettingsEditor = {}
SettingsEditor.__index = SettingsEditor

function SettingsEditor:new()
    local instance = {}
    setmetatable(instance, self)
    instance:_initialize()
    return instance
end

function SettingsEditor:_initialize()
    self.draw_count             = 0
    self.open                   = true

    self.new_project_markdown_style   = self:retrieveNewProjectMarkdownStyle()
    self.cur_project_markdown_style   = self:retrieveCurProjectMarkdownStyle()

    self.new_project_sticker_size     = S.getSetting("NewProjectStickerSize")
    self.cur_project_sticker_size     = D.RetrieveProjectStickerSize()

    self.mdwidget_new_proj  = ImGuiMd:new(AppContext:instance().imgui_ctx, "markdown_widget_new_proj", { wrap = true, autopad = true, skip_last_whitespace = true }, self.new_project_markdown_style )
    self.mdwidget_cur_proj  = ImGuiMd:new(AppContext:instance().imgui_ctx, "markdown_widget_cur_proj", { wrap = true, autopad = true, skip_last_whitespace = true }, self.cur_project_markdown_style )
end

function SettingsEditor:retrieveNewProjectMarkdownStyle()
    return D.deepCopy(S.getSetting("NewProjectMarkdown"))
end

function SettingsEditor:retrieveCurProjectMarkdownStyle()
    return D.deepCopy(D.RetrieveProjectMarkdownStyle())
end

function SettingsEditor:setPosition(pos_x, pos_y)
    self.pos = { x = pos_x, y = pos_y}
end

function SettingsEditor:categoryNamesTable()
    local app_ctx   = AppContext:instance()
    local ctx       = app_ctx.imgui_ctx

    if ImGui.BeginTable(ctx, "aaaa##table", 3, 0) then
        ImGui.TableSetupColumn(ctx, "")
        ImGui.TableSetupColumn(ctx, "New Project")
        ImGui.TableSetupColumn(ctx, "Current Project")
        ImGui.TableHeadersRow(ctx)
        for i=0, D.MAX_SLOTS-1 do
            local slot = (i==D.MAX_SLOTS - 1) and (0) or (i+1)
            ImGui.TableNextRow(ctx)
            ImGui.TableNextColumn(ctx)

            ---@diagnostic disable-next-line: undefined-field
            ImGui.PushItemFlag(ctx, ImGui.ItemFlags_NoTabStop, true)
            ImGui.ColorEdit4(ctx, "##col_slot_" .. i, (D.SlotColor(slot) << 8) | 0xFF, ImGui.ColorEditFlags_NoPicker | ImGui.ColorEditFlags_NoDragDrop | ImGui.ColorEditFlags_NoInputs | ImGui.ColorEditFlags_NoBorder | ImGui.ColorEditFlags_NoTooltip)
            ---@diagnostic disable-next-line: undefined-field
            ImGui.PopItemFlag(ctx)

            --ImGui.Text(ctx,"y1")
            ImGui.TableNextColumn(ctx)
            ImGui.SetNextItemWidth(ctx, 150)
            if slot ~= 0 then
                local lab   = S.getSetting("SlotLabel_" .. slot)
                local b, v  = ImGui.InputText(ctx, "##new_proj_edit_slot_" .. i, lab)
                if b then
                    S.setSetting("SlotLabel_" .. slot, v)
                end
            else
                ImGui.Text(ctx, " " .. D.SlotLabel(slot))
            end
            ImGui.TableNextColumn(ctx)
            ImGui.SetNextItemWidth(ctx, 150)
            if slot ~= 0 then
                local b, v = ImGui.InputText(ctx, "##cur_proj_edit_slot_" .. i, D.SlotLabel(slot))
                if b then
                    D.SetSlotLabel(slot, v)
                end
            else
                ImGui.Text(ctx, " " .. D.SlotLabel(slot))
            end
        end
        ImGui.TableNextRow(ctx)
        ImGui.TableNextColumn(ctx)
        ImGui.TableNextColumn(ctx)
        if ImGui.Button(ctx, "Reset to defaults##reset_global_labels_to_defaults_button") then
            for i = 0, D.MAX_SLOTS-1 do
                S.resetSetting("SlotLabel_"..i)
            end
        end
        ImGui.TableNextColumn(ctx)
        if ImGui.Button(ctx, "Reset to defaults##reset_project_labels_to_defaults_button") then
            for i = 0, D.MAX_SLOTS-1 do
                D.SetSlotLabel(i, S.getSettingSpec("SlotLabel_"..i).default )
            end
        end

        ImGui.EndTable(ctx)
    end
end

function SettingsEditor:markdownTableHeaders()
    local app_ctx   = AppContext:instance()
    local ctx       = app_ctx.imgui_ctx

    ImGui.TableSetupColumn(ctx, "Style",            ImGui.TableColumnFlags_WidthFixed, 70)
    ImGui.TableSetupColumn(ctx, "Normal weight",    ImGui.TableColumnFlags_WidthFixed, 16)
    ImGui.TableSetupColumn(ctx, "Bold Weight",      ImGui.TableColumnFlags_WidthFixed, 16)
    ImGui.TableSetupColumn(ctx, "Size",             ImGui.TableColumnFlags_WidthFixed, 50)
    ImGui.TableSetupColumn(ctx, "Pad Top",          ImGui.TableColumnFlags_WidthFixed, 50)
    ImGui.TableSetupColumn(ctx, "Pad Bot",          ImGui.TableColumnFlags_WidthFixed, 50)

    ImGui.TableNextRow(ctx, ImGui.TableRowFlags_Headers)
    ImGui.TableNextColumn(ctx); ImGui.TableHeader(ctx, "Style");    ImGui.SetItemTooltip(ctx, "Style Name")
    ImGui.TableNextColumn(ctx); ImGui.TableHeader(ctx, " N");        ImGui.SetItemTooltip(ctx, "Normal Weight Color")
    ImGui.TableNextColumn(ctx); ImGui.TableHeader(ctx, " B");        ImGui.SetItemTooltip(ctx, "Bold Color")
    ImGui.TableNextColumn(ctx); ImGui.TableHeader(ctx, "Size");     ImGui.SetItemTooltip(ctx, "Font Size")
    ImGui.TableNextColumn(ctx); ImGui.TableHeader(ctx, "Pad T");    ImGui.SetItemTooltip(ctx, "Padding Top")
    ImGui.TableNextColumn(ctx); ImGui.TableHeader(ctx, "Pad B");    ImGui.SetItemTooltip(ctx, "Padding Bottom")
end

function SettingsEditor:markdownRow(widget, style, entry_name)
    local app_ctx   = AppContext:instance()
    local ctx       = app_ctx.imgui_ctx
    local b, v      = false, ''

    local sub_style = style[entry_name]

    ImGui.PushID(ctx, "style_" .. entry_name)
    ImGui.TableNextRow(ctx)

    ImGui.TableNextColumn(ctx)
    ImGui.AlignTextToFramePadding(ctx)
    ImGui.Text(ctx, entry_name)

    local function _update_style()
        widget:setStyle(style)
        widget:setText("") -- Force recalculation of the ast
    end

    ImGui.TableNextColumn(ctx)
    if sub_style.base_color then
        b, v = ImGui.ColorEdit3(ctx, "##base_color", Color:new(sub_style.base_color):to_iargb(), ImGui.ColorEditFlags_NoLabel | ImGui.ColorEditFlags_NoSidePreview | ImGui.ColorEditFlags_NoInputs)
        if b then
            sub_style.base_color = Color:new_from_iargb(v):css_rgb()
            _update_style()
        end
    end

    ImGui.TableNextColumn(ctx)
    if sub_style.bold_color then
        b, v = ImGui.ColorEdit3(ctx, "##bold_color", Color:new(sub_style.bold_color):to_iargb(), ImGui.ColorEditFlags_NoLabel | ImGui.ColorEditFlags_NoSidePreview | ImGui.ColorEditFlags_NoInputs)
        if b then
            sub_style.bold_color = Color:new_from_iargb(v):css_rgb()
            _update_style()
        end
    end

    ImGui.TableNextColumn(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if sub_style.font_size then
        b, v = ImGui.SliderInt(ctx, "##font_size", sub_style.font_size, 8, 30)
        if b then
            sub_style.font_size = v
            _update_style()
        end
    end

    ImGui.TableNextColumn(ctx)
    ImGui.SetNextItemWidth(ctx, 50)
    if sub_style.padding_top then
        b, v = ImGui.SliderInt(ctx, "##pad_top", sub_style.padding_top, 0, 15)
        if b then
            sub_style.padding_top = v
            _update_style()
        end
    end

    ImGui.TableNextColumn(ctx)
    ImGui.SetNextItemWidth(ctx, 50)

    if sub_style.padding_bottom then
        b, v = ImGui.SliderInt(ctx, "##pad_bot", sub_style.padding_bottom, 0, 15)
        if b then
            sub_style.padding_bottom = v
            _update_style()
        end
    end

    ImGui.PopID(ctx)
end

function SettingsEditor:stickersStyleRow(sticker_size_get_callback, sticker_size_update_callback)
    local app_ctx   = AppContext:instance()
    local ctx       = app_ctx.imgui_ctx
    local b, v      = false, ''

    ImGui.PushID(ctx, "style_sticker")
    ImGui.TableNextRow(ctx)
    ImGui.TableNextRow(ctx)

    ImGui.TableNextColumn(ctx)
    ImGui.AlignTextToFramePadding(ctx)
    ImGui.Text(ctx, "stickers")

    ImGui.TableNextColumn(ctx) -- Color normal
    ImGui.TableNextColumn(ctx) -- Color bold
    ImGui.TableNextColumn(ctx) -- Font Size
    ImGui.SetNextItemWidth(ctx, 50)

    b, v = ImGui.SliderInt(ctx, "##font_size", sticker_size_get_callback(), 8, 20)
    if b then
        sticker_size_update_callback(v)
    end

    ImGui.TableNextColumn(ctx) -- padding top
    ImGui.TableNextColumn(ctx) -- padding bottom
    ImGui.PopID(ctx)
end

function SettingsEditor:markdownStyles(widget, style_container)
    self:markdownRow(widget, style_container, "default")
    self:markdownRow(widget, style_container, "link")
    self:markdownRow(widget, style_container, "paragraph")
    self:markdownRow(widget, style_container, "h1")
    self:markdownRow(widget, style_container, "h2")
    self:markdownRow(widget, style_container, "h3")
    self:markdownRow(widget, style_container, "h4")
    self:markdownRow(widget, style_container, "h5")
    self:markdownRow(widget, style_container, "list")
    self:markdownRow(widget, style_container, "table")
    self:markdownRow(widget, style_container, "blockquote")
    self:markdownRow(widget, style_container, "code")
end

local WIDGET_WIDTH  = 300
local PREVIEW_WIDTH = 350
local MD_EDITOR_HEIGHT = 400

local markdown_example = [[# H1 Title
## H2 Title
### H3 Title
#### H4 Title
##### H5 Title
Normal paragraph with **bold** and _italic_ text and a [link](https://reaper.fm). Normal paragraph with **bold** and _italic_ text and a [link](https://reaper.fm). Normal paragraph with **bold** and _italic_ text and a [link](https://reaper.fm). Normal paragraph with **bold** and _italic_ text and a [link](https://reaper.fm).
# Lists
* List item 1
* List item 2
  * Sub list item 1
  * ...
# Tables
| First Column | Second Column |
|-|-|
| Some **text** | A [link](https://reaper.fm) |
# Code
```
function hello_world()
  print("Hello World\n")
end
```
# Blocks
> Root block
>> Inner block
>>> Inner inner block
]]

function SettingsEditor:markdownTable()
    local app_ctx   = AppContext:instance()
    local ctx       = app_ctx.imgui_ctx

    ImGui.BeginGroup(ctx)
    ImGui.Selectable(ctx, "Stylesheet for new projects", true, 0, WIDGET_WIDTH + (self.preview_new_proj_markdown and PREVIEW_WIDTH + 4 or 0))

    if ImGui.BeginChild(ctx, "aaaa##table_markdown_new", WIDGET_WIDTH, MD_EDITOR_HEIGHT) then
        ImGui.PushID(ctx, "table_markdown_new_proj")
        if ImGui.BeginTable(ctx, "", 6, 0, WIDGET_WIDTH) then
            self:markdownTableHeaders()
            self:markdownStyles(self.mdwidget_new_proj, self.new_project_markdown_style)
            ImGui.TableNextRow(ctx)

            self:stickersStyleRow(function() return self.new_project_sticker_size end, function(v) self.new_project_sticker_size = v end)
            ImGui.EndTable(ctx)
        end

        -- BUTTONS
        ImGui.Dummy(ctx,1,10)
        local d = not (D.deepCompare(self:retrieveNewProjectMarkdownStyle(), self.new_project_markdown_style) and (S.getSetting("NewProjectStickerSize") == self.new_project_sticker_size))
        if d then ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFF0000FF) end
        if ImGui.Button(ctx, "Save and apply !") then
            S.setSetting("NewProjectMarkdown", self.new_project_markdown_style)
            S.setSetting("NewProjectStickerSize", self.new_project_sticker_size)
            if self.on_commit_new_project_style_callback then
                self.on_commit_new_project_style_callback(D.deepCopy(self.new_project_markdown_style))
            end
        end
        if d then ImGui.PopStyleColor(ctx) end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Preview") then
            local b = (self.preview_new_proj_markdown == true)
            self.preview_new_proj_markdown = not b
        end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Copy ->") then
            self.cur_project_markdown_style = D.deepCopy(self.new_project_markdown_style)
            self.cur_project_sticker_size = self.new_project_sticker_size
            self.mdwidget_cur_proj:setStyle(self.cur_project_markdown_style)
            self.mdwidget_cur_proj:setText("")
        end
        if ImGui.IsItemHovered(ctx) then
            ImGui.SetTooltip(ctx, "Copy these settings to Current Project panel")
        end
        ImGui.PopID(ctx)
        ImGui.EndChild(ctx)
    end

    if self.preview_new_proj_markdown then
        ImGui.SameLine(ctx)
        ImGui.BeginGroup(ctx)
        if ImGui.BeginChild(ctx, "##preview_left", PREVIEW_WIDTH, MD_EDITOR_HEIGHT) then
            self.mdwidget_new_proj:setText(markdown_example)
            self.mdwidget_new_proj:render(ctx)
            ImGui.EndChild(ctx)
        end

        ImGui.Dummy(ctx,0,0)
        local x, y    = ImGui.GetCursorScreenPos(ctx)
        local sticker = Sticker:new("1:1:1F60D:Sticker Test", Notes:new(nil, false), 1)
        local pr_res  = sticker:PreRender(ctx, self.new_project_sticker_size)
        sticker:Render(ctx, pr_res, x, y)
        ImGui.SetCursorScreenPos(ctx, x, y + pr_res.height)
        ImGui.Dummy(ctx, 0, 0)

        ImGui.EndGroup(ctx)
    end

    ImGui.EndGroup(ctx)

    -- Vertical separator
    ImGui.SameLine(ctx)
    local cx, cy = ImGui.GetCursorScreenPos(ctx)
    ImGui.DrawList_AddLine(ImGui.GetWindowDrawList(ctx), cx + 1, cy, cx + 1, cy + MD_EDITOR_HEIGHT + 20, 0x606060FF)
    ImGui.Dummy(ctx,3,MD_EDITOR_HEIGHT)
    ImGui.SameLine(ctx)

    ImGui.BeginGroup(ctx)
    ImGui.Selectable(ctx, "Stylesheet for current project", true, 0, WIDGET_WIDTH + (self.preview_cur_proj_markdown and PREVIEW_WIDTH + 4 or 0))

    if self.preview_cur_proj_markdown then
        ImGui.BeginGroup(ctx)
        if ImGui.BeginChild(ctx, "##preview_right", PREVIEW_WIDTH, MD_EDITOR_HEIGHT) then
            self.mdwidget_cur_proj:setText(markdown_example)
            self.mdwidget_cur_proj:render(ctx)
            ImGui.EndChild(ctx)
        end

        ImGui.Dummy(ctx,0,0)
        local x, y    = ImGui.GetCursorScreenPos(ctx)
        local sticker = Sticker:new("1:1:1F60D:Sticker Test", Notes:new(nil, false), 1)
        local pr_res  = sticker:PreRender(ctx, self.cur_project_sticker_size)
        sticker:Render(ctx, pr_res, x, y)
        ImGui.SetCursorScreenPos(ctx, x, y + pr_res.height)
        ImGui.Dummy(ctx, 0, 0)

        ImGui.EndGroup(ctx)
        ImGui.SameLine(ctx)
    end

    if ImGui.BeginChild(ctx, "bbbb##table_markdown_current", WIDGET_WIDTH, MD_EDITOR_HEIGHT) then
        ImGui.PushID(ctx, "table_markdown_cur_proj")
        if ImGui.BeginTable(ctx, "", 6, 0, WIDGET_WIDTH) then
            self:markdownTableHeaders()
            self:markdownStyles(self.mdwidget_cur_proj, self.cur_project_markdown_style)

            ImGui.TableNextRow(ctx)
            self:stickersStyleRow(function() return self.cur_project_sticker_size end, function(v) self.cur_project_sticker_size = v end)

            ImGui.EndTable(ctx)
        end

        -- BUTTONS
        ImGui.Dummy(ctx,1,10)
        if ImGui.Button(ctx, "<- Copy") then
            self.new_project_markdown_style = D.deepCopy(self.cur_project_markdown_style)
            self.new_project_sticker_size   = self.cur_project_sticker_size
            self.mdwidget_new_proj:setStyle(self.new_project_markdown_style)
            self.mdwidget_new_proj:setText("")
        end
        if ImGui.IsItemHovered(ctx) then
            ImGui.SetTooltip(ctx, "Copy these settings to New Project panel")
        end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Preview") then
            local b = (self.preview_cur_proj_markdown == true)
            self.preview_cur_proj_markdown = not b
        end
        ImGui.SameLine(ctx)
        local d = not ((D.deepCompare(self:retrieveCurProjectMarkdownStyle(), self.cur_project_markdown_style)) and (D.RetrieveProjectStickerSize() == self.cur_project_sticker_size))
        if d then ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0xFF0000FF) end
        if ImGui.Button(ctx, "Save and apply !") then
            D.CommitProjectMarkdownStyle(self.cur_project_markdown_style)
            D.CommitProjectStickerSize(self.cur_project_sticker_size)
            if self.on_commit_current_project_style_callback then
                self.on_commit_current_project_style_callback(D.deepCopy(self.cur_project_markdown_style))
            end
        end
        if d then ImGui.PopStyleColor(ctx) end

        ImGui.PopID(ctx)
        ImGui.EndChild(ctx)
    end
    ImGui.EndGroup(ctx)
end

function SettingsEditor:draw()
    local app_ctx   = AppContext:instance()
    local ctx       = app_ctx.imgui_ctx

    ImGui.PushFont(ctx, app_ctx.arial_font, S.getSetting("UIFontSize"))

    local b, open = ImGui.Begin(ctx, "Reannotate Settings##reannotate_settings_editor", true,
    ImGui.WindowFlags_AlwaysAutoResize |
    ImGui.WindowFlags_NoDocking |
    ImGui.WindowFlags_NoResize |
    ImGui.WindowFlags_TopMost |
    ImGui.WindowFlags_NoCollapse)

    -- Set initiial position
    if ImGui.IsWindowAppearing(ctx) and self.pos then
        ImGui.SetWindowPos(ctx, self.pos.x, self.pos.y)
    end

    -- Close window on escape
    if ImGui.IsWindowFocused(ctx) and ImGui.IsKeyChordPressed(ctx, ImGui.Key_Escape) then
        open = false
    end

    if b then
        if ImGui.BeginTabBar(ctx, "SettingsTab") then
            if ImGui.BeginTabItem(ctx, "Categories", false) then
                --    ImGui.TextWrapped(ctx, "You can rename categories here, for all new projets, or for the current project. Category names are used by the \"category\" special sticker, or when displaying counts and filters. This has no other role than letting you organize them to your will.")
                self:categoryNamesTable()
                ImGui.EndTabItem(ctx)
            end
            if ImGui.BeginTabItem(ctx, "Appearance", false) then
                --    ImGui.TextWrapped(ctx, "You can adjust markdown parameters for all new projects, or for the current project. Be careful, this changes the aspect of all existing tooltips, so their size will not fit their content anymore.")

                ImGui.SeparatorText(ctx, "General")
                local ui_font_size = S.getSetting("UIFontSize")
                local b, v = ImGui.SliderInt(ctx, "UI Font Size", ui_font_size, 8, 20)
                if b then
                    self.tmp_values = self.tmp_values or {}
                    self.tmp_values["UIFontSize"] = v
                end
                if ImGui.IsItemDeactivatedAfterEdit(ctx) and self.tmp_values["UIFontSize"]  then
                    S.setSetting("UIFontSize", self.tmp_values["UIFontSize"])
                    self.tmp_values["UIFontSize"] = nil
                end

                ImGui.SeparatorText(ctx, "Markdown")

                self:markdownTable()

                ImGui.EndTabItem(ctx)
            end
            ImGui.EndTabBar(ctx)
        end

        ImGui.End(ctx)
    end

    ImGui.PopFont(ctx)

    self.open       = open
    self.draw_count = self.draw_count + 1
end

return SettingsEditor

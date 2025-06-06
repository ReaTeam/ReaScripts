-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- ImGui generation from AST

local ImGui     = require "reaimgui_markdown/ext/imgui"

local Colors = {
    aqua = "#00ffff",
    azure = "#f0ffff",
    beige = "#f5f5dc",
    bisque = "#ffe4c4",
    blue = "#0000ff",
    brown = "#a52a2a",
    coral = "#ff7f50",
    crimson = "#dc143c",
    cyan = "#00ffff",
    darkred = "#8b0000",
    dimgray = "#696969",
    dimgrey = "#696969",
    gold = "#ffd700",
    gray = "#808080",
    green = "#008000",
    grey = "#808080",
    hotpink = "#ff69b4",
    indigo = "#4b0082",
    ivory = "#fffff0",
    khaki = "#f0e68c",
    lime = "#00ff00",
    linen = "#faf0e6",
    maroon = "#800000",
    navy = "#000080",
    oldlace = "#fdf5e6",
    olive = "#808000",
    orange = "#ffa500",
    orchid = "#da70d6",
    peru = "#cd853f",
    pink = "#ffc0cb",
    plum = "#dda0dd",
    purple = "#800080",
    red = "#ff0000",
    salmon = "#fa8072",
    sienna = "#a0522d",
    silver = "#c0c0c0",
    skyblue = "#87ceeb",
    snow = "#fffafa",
    tan = "#d2b48c",
    teal = "#008080",
    thistle = "#d8bfd8",
    tomato = "#ff6347",
    violet = "#ee82ee",
    wheat = "#f5deb3",
    white = "#ffffff"
}

local DEFAULT_COLOR = 0xCCCCCCFF

local DEFAULT_STYLE = {
    h1          = { font_family = "sans-serif", font_size = 23, padding_left = 0,  padding_top = 3, padding_bottom = 5, line_spacing = 5, color = "#288efa", bold_color = "#288efa" },
    h2          = { font_family = "sans-serif", font_size = 21, padding_left = 5,  padding_top = 3, padding_bottom = 5, line_spacing = 5, color = "#4da3ff", bold_color = "#4da3ff" },
    h3          = { font_family = "sans-serif", font_size = 19, padding_left = 10, padding_top = 3, padding_bottom = 4, line_spacing = 5, color = "#65acf7", bold_color = "#65acf7" },
    h4          = { font_family = "sans-serif", font_size = 17, padding_left = 15, padding_top = 3, padding_bottom = 3, line_spacing = 5, color = "#85c0ff", bold_color = "#85c0ff" },
    h5          = { font_family = "sans-serif", font_size = 15, padding_left = 20, padding_top = 3, padding_bottom = 3, line_spacing = 5, color = "#9ecdff", bold_color = "#9ecdff" },

    paragraph   = { font_family = "sans-serif", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 3, color = "#CCCCCC", bold_color = "white", padding_in_blockquote = 6 },
    code        = { font_family = "monospace",  font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 3, color = "#CCCCCC", bold_color = "white", padding_in_blockquote = 6 },
    table       = { font_family = "sans-serif", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7 },

    blockquote  = {                                             padding_left = 0,  padding_top = 5, padding_bottom = 10, line_spacing = 3, color = "#CCCCCC", bold_color = "white", padding_indent = 10 },
    list        = {                                             padding_left = 40, padding_top = 5, padding_bottom = 7,  line_spacing = 3, color = "#CCCCCC", bold_color = "white", padding_indent = 5 },
    link        = { color = "orange", hover_color = "tomato"}
}

local function is_white_space(char)
    return char == " " or char == "\t" -- or char == "\n" or char == "\r" or char == "\f" or char == "\v"
end

local function split_into_words_and_spaces(str)
    if not str or str == "" then
        return {}
    end

    local result = {}
    local i = 1
    local len = #str
    local punctuations = {["!"] = true, ["?"] = true, [":"] = true, [";"] = true, ["."] = true, [","] = true}

    while i <= len do
        local char = str:sub(i, i)
        if is_white_space(char) then
            table.insert(result, char)
            i = i + 1
        else
            local word = ""

            while i <= len and not is_white_space(char) do
                word = word .. char
                i = i + 1
                char = str:sub(i, i)
            end

            if i <= len and char == " " then
                local next_i    = i + 1
                local next_char = str:sub(next_i, next_i)

                if next_i <= len and punctuations[next_char] then
                    word = word .. " " .. next_char
                    i = next_i + 1
                end
            end
            table.insert(result, word)
        end
    end

    return result
end

local function ImGuiVDummy(ctx, vpad)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 0, 0)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 0)
    ImGui.Dummy(ctx, 1, vpad)
    ImGui.PopStyleVar(ctx)
    ImGui.PopStyleVar(ctx)
    ImGui.PopStyleVar(ctx)
end

-- HTML generation from AST
local function ASTToImgui(ctx, ast, fonts, style, options)

    if not fonts then return end

    options = options or {}

    local num_line       = 0
    local num_on_line    = 0
    local font_name      = "paragraph"
    local fs_stack       = {}
    local in_link        = false
    local indentation    = 0
    local base_txt_color = DEFAULT_COLOR
    local should_wrap    = options.wrap

    local nodes          = {}

    -- Placeholder for render_children with proper argument
    local render_children = function(children, level) return nil end

    local function resolve_color(color_name)
        local trans_color = Colors[color_name]
        trans_color       = trans_color or color_name

        if not trans_color then return DEFAULT_COLOR end

        if trans_color:match("^#") then
            trans_color = trans_color:sub(2,-1)
        end

        if not trans_color then return DEFAULT_COLOR end

        local numcol = tonumber(trans_color, 16)

        if not numcol then return DEFAULT_COLOR end

        return (numcol << 8) | 0xFF
    end

    local function push_fs(font_style, font_color)
        fs_stack[#fs_stack+1] = { style=font_style, color=font_color }
    end

    local function clear_fs()
        fs_stack = {}
    end

    local function pop_fs()
        table.remove(fs_stack, #fs_stack)
    end

    local function in_style(style)
        for _, v in ipairs(fs_stack) do
            if v.style == style then return true end
        end
        return false
    end

    local function in_italic()
        return in_style('italic')
    end

    local function in_bold()
        return in_style('bold')
    end

    local function overriden_color()
        for i=#fs_stack, 1, -1 do
            if fs_stack[i].color then return fs_stack[i].color end
        end
        return nil
    end

    local function push_font()
        local group = fonts[font_name]
        local f     = group.normal

        if in_bold() then
            base_txt_color = resolve_color(style[font_name].bold_color)

            if in_italic() then
                f = group.bolditalic
            else
                f = group.bold
            end
        else
            base_txt_color = resolve_color(style[font_name].color)

            if in_italic() then
                f = group.italic
            end
        end

        if in_link then
            base_txt_color = resolve_color(style["link"].color)
        end

        local ocol = overriden_color()
        if ocol then base_txt_color = ocol end

        ImGui.PushFont(ctx, f)
    end


    local function pop_font()
        base_txt_color = DEFAULT_COLOR
        ImGui.PopFont(ctx)
    end

    local function draw_word (word)
        local x, y      = ImGui.GetCursorScreenPos(ctx)

        if num_on_line == 0 then
        --   ImGui.AlignTextToFramePadding(ctx)
        end

        push_font()
        local color = base_txt_color
        ImGui.TextColored(ctx, color, word)
        pop_font()

        if in_link then
            if ImGui.IsItemHovered(ctx) then
                ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand)
            end
            if ImGui.IsItemClicked(ctx) then
                reaper.CF_ShellExecute(in_link)
            end
        end

        ImGui.SameLine(ctx)

        if in_link then
            local x2, y2      = ImGui.GetCursorScreenPos(ctx)
            local draw_list   = ImGui.GetWindowDrawList(ctx)
            local fsize       = style[font_name].font_size
            ImGui.DrawList_AddLine(draw_list, x, y+fsize, x2, y2+fsize, color, 1)
        end
    end

    local function wrap_text(node)

        -- Memoize the split to avoid recalculating each frame
        node.words = node.words or split_into_words_and_spaces(node.value)

        for i, word in ipairs(node.words) do
            local aw, ah    = ImGui.GetContentRegionAvail(ctx)
            local w, h      = ImGui.CalcTextSize(ctx, word)

            if w <= aw then
                -- The word fits, add it at the end
                draw_word(word)

                num_on_line = num_on_line + 1
            else
                if not is_white_space(word) then
                    -- Ignore wspaces when wrapping
                    if num_on_line ~= 0 then
                        -- wrap
                        ImGui.NewLine(ctx)
                    end

                    draw_word(word)

                    num_on_line = 1
                    num_line = num_line + 1
                end
            end
        end
    end

    -- Define render_node
    local function render_node(node, level)

        level = level or 1 -- Default to level 1 if not provided
        if node.type == "Document" then
            for _, child in ipairs(node.children) do
                render_node(child, level)
            end
        elseif node.type == "Header" then
            num_line    = num_line + 1
            num_on_line = 0
            indentation = 0
            clear_fs()

            local font_level = node.attributes.level

            if font_level < 1 then font_level = 1 end
            if font_level > 5 then font_level = 5 end

            font_name   = "h" ..font_level

            local hstyle = style[font_name]

            -- Add some vertical padding before
            ImGuiVDummy(ctx, hstyle.padding_top)

            ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + hstyle.padding_left)

            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, hstyle.line_spacing)
            push_font()
            render_children(node.children, level)
            pop_font()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            -- Add some vertical padding after
            ImGuiVDummy(ctx, hstyle.padding_bottom)


        elseif node.type == "Paragraph" then
            num_line    = num_line + 1
            num_on_line = 0
            font_name   = "paragraph"
            clear_fs()
            indentation = 1

            -- Add some vertical padding before
            ImGuiVDummy(ctx, ((node.parent_blockquote) and (style.paragraph.padding_in_blockquote) or (style.paragraph.padding_top)))

            -- Indent left, using cursor
            ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + style.paragraph.padding_left)

            -- Use a group to lock the x indentation
            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, style.paragraph.line_spacing)
            push_font()
            render_children(node.children, level)
            pop_font()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            -- Add some vertical padding after
            -- If we're in a blockquote, force symmetry
            ImGuiVDummy(ctx, ((node.parent_blockquote) and (style.paragraph.padding_in_blockquote) or (style.paragraph.padding_bottom)))

        elseif node.type == "Bold" then
            local col = nil
            if node.attributes.color then col = resolve_color(node.attributes.color) end

            push_fs('bold', col)
            render_children(node.children, level)
            pop_fs()


        elseif node.type == "Italic" then
            local col = nil
            if node.attributes.color then col = resolve_color(node.attributes.color) end

            push_fs('italic', col)
            render_children(node.children, level)
            pop_fs()


        elseif node.type == "Code" then
            local col = nil
            if node.attributes.color then col = resolve_color(node.attributes.color) end

            push_fs(nil, col)
            render_children(node.children, level)
            pop_fs()

        elseif node.type == "Text" then

            if should_wrap then
                wrap_text(node)
            else
                if num_on_line ~= 0 then ImGui.SameLine(ctx) end

                push_font()
                ImGui.TextColored(ctx, base_txt_color, node.value)
                pop_font()

                ImGui.SameLine(ctx)
                num_on_line = num_on_line + 1
            end

        elseif node.type == "Link" then
            in_link = node.attributes.url
            push_font()
            render_children(node.children, level)
            pop_font()
            in_link = false

        elseif node.type == "LineBreak" then

            font_name       = "paragraph"
            clear_fs()
            indentation     = 1
            num_on_line     = 0
            num_line        = num_line + 1

            ImGui.NewLine(ctx)

        elseif (node.type == "UnorderedList") or (node.type == "OrderedList") then

            if level > 1 then
                -- Special case for sub lists. They are added directly behind inlined elements
                -- So this is the only criteria that helps us to decide
                ImGui.NewLine(ctx)
            else
                ImGuiVDummy(ctx, style.list.padding_top)
            end

            num_line        = num_line + 1
            num_on_line     = 0
            font_name       = "paragraph"
            clear_fs()
            indentation = indentation + 1

            -- Advance cursor. We assume that the precedent block used NewLine.
            ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + ((level == 1) and (style.list.padding_left) or (style.list.padding_indent)) )

            ImGui.BeginGroup(ctx)
            render_children(node.children, level)
            ImGui.EndGroup(ctx)

            -- Avoid line return, the next list item will perform new line
            if level > 1 then
                ImGui.SameLine(ctx)
            else
                ImGuiVDummy(ctx, style.list.padding_bottom)
            end

            indentation = indentation - 1

        elseif node.type == "ListItem" then
            num_line        = num_line + 1
            num_on_line     = 0
            font_name       = "paragraph"
            clear_fs()

            if node.parent_list.type == "UnorderedList" then
                -- Render a bullet with the default font
                ImGui.PushFont(ctx, nil)
                ImGui.Text(ctx, "· ")
                ImGui.PopFont(ctx)
                num_on_line = 1
            else
                push_font()
                ImGui.Text(ctx, node.attributes.number .. ". ")
                pop_font()
                num_on_line = 1
            end

            push_font()
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, style.list.line_spacing)
            -- Since we've added bullet / numbering, go back to current line
            ImGui.SameLine(ctx)
            ImGui.BeginGroup(ctx)
            for _, child in ipairs(node.children) do
                render_node(child, level + 1)
            end
            ImGui.EndGroup(ctx)
            ImGui.PopStyleVar(ctx)
            pop_font()

        elseif node.type == "Blockquote" then
            num_line        = num_line + 1
            num_on_line     = 0
            font_name       = "paragraph"
            clear_fs()

            local bstyle = style.blockquote

            if level == 1 then
                -- Add some vertical padding before
                ImGuiVDummy(ctx, bstyle.padding_top)
            else
                ImGuiVDummy(ctx, style.paragraph.padding_in_blockquote)
            end

            -- Indent left, using cursor
            ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + ((level == 1) and (bstyle.padding_left) or (bstyle.padding_indent)))

            local x, y = ImGui.GetCursorScreenPos(ctx)

            -- Use a group to lock the x indentation
            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
            push_font()
            render_children(node.children, level + 1)
            pop_font()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            local x2, y2 = ImGui.GetCursorScreenPos(ctx)
            local draw_list = ImGui.GetWindowDrawList(ctx)
            x = x + style.paragraph.padding_left - 10
            ImGui.DrawList_AddRectFilled(draw_list, x, y, x + 4 , y2, 0x288efaFF)

            if level == 1 then
                -- Add some vertical padding before
                ImGuiVDummy(ctx, bstyle.padding_bottom)
            else
                ImGuiVDummy(ctx, style.paragraph.padding_in_blockquote)
            end

        elseif node.type == "CodeBlock" then

            num_line        = num_line + 1
            num_on_line     = 0
            font_name       = "code"
            clear_fs()

            ImGuiVDummy(ctx, style.code.padding_top)

            ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + style.code.padding_left)

            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
            push_font()
            ImGui.TextColored(ctx, resolve_color(style.code.color), node.value)
            pop_font()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            ImGuiVDummy(ctx, style.code.padding_bottom)

        elseif node.type == "Image" then
            font_name       = "paragraph"
            clear_fs()
            indentation     = 1
            num_on_line     = 0
            num_line        = num_line + 1

            push_font()
            ImGui.Text(ctx, "Images are not supported yet.")
            pop_font()

        elseif node.type == "Table" then
            font_name       = "paragraph"
            clear_fs()
            indentation     = 1
            num_on_line     = 0
            num_line        = num_line + 1

            local column_count = 1

            if node.children.headers and #node.children.headers > column_count then column_count = #node.children.headers end
            for _, row in ipairs(node.children.rows) do
                if #row > column_count then column_count = #row end
            end

            ImGuiVDummy(ctx, style.table.padding_top)

            ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + style.table.padding_left)

            ImGui.BeginGroup(ctx)
            push_font()
            if ImGui.BeginTable(ctx, "##table", column_count) then
                if node.children.headers and not node.attributes.headers_are_empty then
                    for _, header in ipairs(node.children.headers) do
                        ImGui.TableSetupColumn(ctx, header)
                    end
                    ImGui.TableHeadersRow(ctx)
                end

                for _, row in ipairs(node.children.rows) do
                    ImGui.TableNextRow(ctx)
                    for _, cell in ipairs(row) do
                        ImGui.TableNextColumn(ctx)
                        ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
                        render_children(cell, level)
                        ImGui.PopStyleVar(ctx)
                    end
                end
                ImGui.EndTable(ctx)
            end
            ImGui.EndGroup(ctx)
            pop_font()
            ImGuiVDummy(ctx, style.table.padding_bottom)
        end
        return nodes
    end

    -- Redefine render_children with proper implementation
    render_children = function(children, level)
        for _, child in ipairs(children) do
            render_node(child, level)
        end
    end

    render_node(ast, 1)
end

return {
    DEFAULT_STYLE   = DEFAULT_STYLE,
    ASTToImgui      = ASTToImgui
}

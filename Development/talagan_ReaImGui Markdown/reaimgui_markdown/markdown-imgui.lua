-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- ImGui generation from AST

local ImGui     = require "reaimgui_markdown/ext/imgui"
local AstToText = require "reaimgui_markdown/markdown-text"

local Colors = {
    aqua        = "#00ffff",
    azure       = "#f0ffff",
    beige       = "#f5f5dc",
    bisque      = "#ffe4c4",
    blue        = "#0000ff",
    brown       = "#a52a2a",
    coral       = "#ff7f50",
    crimson     = "#dc143c",
    cyan        = "#00ffff",
    darkred     = "#8b0000",
    dimgray     = "#696969",
    dimgrey     = "#696969",
    gold        = "#ffd700",
    gray        = "#808080",
    green       = "#008000",
    grey        = "#808080",
    hotpink     = "#ff69b4",
    indigo      = "#4b0082",
    ivory       = "#fffff0",
    khaki       = "#f0e68c",
    lime        = "#00ff00",
    linen       = "#faf0e6",
    maroon      = "#800000",
    navy        = "#000080",
    oldlace     = "#fdf5e6",
    olive       = "#808000",
    orange      = "#ffa500",
    orchid      = "#da70d6",
    peru        = "#cd853f",
    pink        = "#ffc0cb",
    plum        = "#dda0dd",
    purple      = "#800080",
    red         = "#ff0000",
    salmon      = "#fa8072",
    sienna      = "#a0522d",
    silver      = "#c0c0c0",
    skyblue     = "#87ceeb",
    snow        = "#fffafa",
    tan         = "#d2b48c",
    teal        = "#008080",
    thistle     = "#d8bfd8",
    tomato      = "#ff6347",
    violet      = "#ee82ee",
    wheat       = "#f5deb3",
    white       = "#ffffff"
}

local DEFAULT_COLOR = 0xCCCCCCFF

local DEFAULT_STYLE = {
    default     = { font_family = "Arial", font_size = 13, base_color = "#CCCCCC", bold_color = "white", autopad = 5 },

    h1          = { font_family = "Arial", font_size = 23, padding_left = 0,  padding_top = 3, padding_bottom = 5, line_spacing = 0, base_color = "#288efa", bold_color = "#288efa" },
    h2          = { font_family = "Arial", font_size = 21, padding_left = 5,  padding_top = 3, padding_bottom = 5, line_spacing = 0, base_color = "#4da3ff", bold_color = "#4da3ff" },
    h3          = { font_family = "Arial", font_size = 19, padding_left = 10, padding_top = 3, padding_bottom = 4, line_spacing = 0, base_color = "#65acf7", bold_color = "#65acf7" },
    h4          = { font_family = "Arial", font_size = 17, padding_left = 15, padding_top = 3, padding_bottom = 3, line_spacing = 0, base_color = "#85c0ff", bold_color = "#85c0ff" },
    h5          = { font_family = "Arial", font_size = 15, padding_left = 20, padding_top = 3, padding_bottom = 3, line_spacing = 0, base_color = "#9ecdff", bold_color = "#9ecdff" },

    paragraph   = { font_family = "Arial", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 0, padding_in_blockquote = 6 },
    list        = { font_family = "Arial", font_size = 13, padding_left = 40, padding_top = 5, padding_bottom = 7, line_spacing = 0, padding_indent = 5 },

    table       = { font_family = "Arial", font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7, line_spacing = 0 },

    code        = { font_family = "monospace",  font_size = 13, padding_left = 30, padding_top = 3, padding_bottom = 7,  line_spacing = 4, padding_in_blockquote = 6 },
    blockquote  = { font_family = "Arial", font_size = 13, padding_left = 0,  padding_top = 5, padding_bottom = 10, line_spacing = 2, padding_indent = 10 },

    link        = { base_color = "orange", bold_color = "tomato"},

    separator   = { padding_top = 3, padding_bottom = 7 }
}

local function is_white_space(char)
    return char == " " or char == "\t" -- or char == "\n" or char == "\r" or char == "\f" or char == "\v"
end

-- This splits a complete string into a sequence of "tokens" which are words
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

            -- Aggregate characters (letters or anything)
            while i <= len and not is_white_space(char) do
                word = word .. char
                i = i + 1
                char = str:sub(i, i)
            end

            -- Non-splittable spaces : for example "he says : yahoo"
            -- We keep "says :" as one word. Same for end of sentences : "He jumped !"
            -- where "jumped !" is one word
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

-- Handy Shortcut to add vertical padding
local function ImGuiVDummy(ctx, vpad)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
    ImGui.Dummy(ctx, 1, vpad)
    ImGui.PopStyleVar(ctx, 1)
end

-- Finds color from lookup and if not foound converts from string to 0xRRGGBBAA
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

-- HTML generation from AST
local function ASTToImgui(ctx, ast, fonts, style, options)

    if not fonts then return end

    options = options or {}

    -- Possible options
    --   options.wrap
    --   options.skip_last_whitespace
    --   options.autopad

    local precalc_last_node         = nil
    local rendered_last             = false
    local num_line                  = 0
    local num_on_line               = 0
    local in_link                   = nil
    local base_txt_color            = DEFAULT_COLOR
    local should_autopad            = options.autopad
    local should_wrap               = options.wrap
    local skip_last_whitespace      = options.skip_last_whitespace
    local h_stack                   = {} -- Used by autopad
    local interaction               = nil

    -- Placeholder for render_children
    local render_children = function(children, level) return nil end

    local function push_style(node)
        local group         = fonts[node.style.font_family]
        local f             = group[node.style.font_style]
        base_txt_color      = node.style.color

        ImGui.PushFont(ctx, f, node.style.font_size)
    end

    local function pop_style()
        base_txt_color = DEFAULT_COLOR
        ImGui.PopFont(ctx)
    end

    local function LaunchLink(link)
        if link.scheme == 'action' then
            reaper.Main_OnCommandEx(link.target, 0, 0)
        elseif link.scheme == 'time' then
            local respos = reaper.parse_timestr_pos(link.target, -1)
            reaper.SetEditCurPos(respos, true, true)
        else
            reaper.CF_ShellExecute(link.url)
        end
    end

    local function draw_word (node, word)
        local x, y = ImGui.GetCursorScreenPos(ctx)

        if num_on_line == 0 then
            ImGui.AlignTextToFramePadding(ctx)
        end

        local color = base_txt_color
        ImGui.TextColored(ctx, color, word)

        if in_link then
            if ImGui.IsItemHovered(ctx) then
                ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_Hand)
            end
            if ImGui.IsItemClicked(ctx) then
                LaunchLink(in_link)
            end
        end

        -- Stay ready for pushing another word behind this one
        ImGui.SameLine(ctx)

        -- Add underline if in link
        if in_link then
            local x2, y2      = ImGui.GetCursorScreenPos(ctx)
            local draw_list   = ImGui.GetWindowDrawList(ctx)
            local fsize       = node.style.font_size
            ImGui.DrawList_AddLine(draw_list, x, y+fsize*1.2, x2, y2+fsize*1.2, color, 1)
        end
    end

    local function nodeHasChild(node, candidate_node)
        for _, child in ipairs(node.children) do
            if child == candidate_node then return true end
            if nodeHasChild(child, candidate_node) then return true end
        end
        return false
    end

    local function ensureNodeWordSplit(node)
        if not node.words then
            -- Each node contains a sequence of "tokens", which are words, and spaces, with special treatement :
            -- Punctuation signs are attached to words when they are separated by a space (non-splittable space)
            -- We want to calculate this sequence once for all and memoize it to avoid recalculation.
            local words = split_into_words_and_spaces(node.value)
            node.words = {}
            for i, word in ipairs(words) do
                node.words[#node.words+1] = { word = word }
            end
        end
    end

    local function wrap_text(node)
        push_style(node)

        -- Make sure nodes are word-tokenized correctly
        ensureNodeWordSplit(node)

        local buffer    = ""
        local bufwid    = 0
        local aw        = nil

        local function newline()
            ImGui.NewLine(ctx)
            ImGui.AlignTextToFramePadding(ctx)

            num_line    = num_line + 1
            num_on_line = 0

            buffer      = ""
            bufwid      = 0
        end

        for i, word_entry in ipairs(node.words) do

            if word_entry.size == nil then
                -- The word size is also memoized.
                -- This is done using the current font, so can be only be done
                -- During rendering
                word_entry.size, _  = ImGui.CalcTextSize(ctx, word_entry.word)
            end

            local word      = word_entry.word
            local wsize     = word_entry.size

            if aw == nil then
                aw, _ = ImGui.GetContentRegionAvail(ctx)
            end

            if num_on_line == 0 and bufwid == 0 and is_white_space(word) then
                -- Just ignore white spaces on line starts
            else
                if (bufwid + wsize) < aw then
                    -- We can accumulate the word
                    buffer = buffer .. word
                    bufwid = bufwid + wsize
                else
                    if #buffer > 0 then
                        -- There's something in the buffer, dump it
                        draw_word(node, buffer)
                        newline()

                        if not is_white_space(word) then
                            buffer      = word
                            bufwid      = wsize
                            num_on_line = num_on_line + 1
                        end
                    else
                        if num_on_line > 0 then
                            -- We've reached the end of the line (the buffer was empty but it's possible, if this is the first word of a new sequence)
                            newline()
                            if not is_white_space(word) then
                                draw_word(node, word)
                                num_on_line = num_on_line + 1
                            end
                        else
                            -- There's nothing in the buffer, but the word alone does not fit.
                            -- Just draw the word, and go to the next line
                            draw_word(node, word)
                            newline()
                        end
                    end

                    aw, _ = ImGui.GetContentRegionAvail(ctx)
                end
            end
        end

        if bufwid > 0 then
            -- There's something in the buffer, dump it
            draw_word(node, buffer)
            num_on_line = num_on_line + 1
        end

        pop_style()
    end

    -- This is used as a basic "cascading" stylesheet, to override the current style (colors, font etc)
    local function local_style_name(node)
        if node.type == "Document" then
            return nil
        elseif node.type == "Header" then
            local font_level = node.attributes.level

            if font_level < 1 then font_level = 1 end
            if font_level > 5 then font_level = 5 end

            -- Dirty hack, we store the level here
            node.hlevel = font_level

            return  "h" ..font_level
        elseif node.type == "Paragraph" then
            if node.parent_blockquote then return "blockquote" end
            return "paragraph"
        elseif node.type == "Bold" then
            return nil
        elseif node.type == "Italic" then
            return nil
        elseif node.type == "Code" then
            return nil
        elseif node.type == "Text" then
            return nil
        elseif node.type == "Link" then
            return "link"
        elseif node.type == "LineBreak" then
            return "paragraph"
        elseif (node.type == "UnorderedList") or (node.type == "OrderedList") then
            return "list"
        elseif node.type == "ListItem" then
            return "list"
        elseif node.type == "Blockquote" then
            return "blockquote"
        elseif node.type == "CodeBlock" then
            return "code"
        elseif node.type == "Image" then
            return "paragraph"
        elseif node.type == "Table" then
            return "table"
        end
        return nil
    end

    -- Propagate fonts, colors and pre calculate metrics
    local function precalculate_style(parent_node, node)
        -- Advance the precalc_last_node pointer each time we explore a node, in the end it will be our last node
        precalc_last_node = node
        if not parent_node then
            local default_style = style["default"]
            node.style = {
                name        = default_style.name,
                font_family = default_style.font_family,
                font_style  = default_style.font_style or "normal",
                font_size   = default_style.font_size or 12,
                base_color  = resolve_color(default_style.base_color) or DEFAULT_COLOR,
                bold_color  = resolve_color(default_style.bold_color) or DEFAULT_COLOR
            }
        else
            node.style = {
                name        = parent_node.style.name,
                font_family = parent_node.style.font_family,
                font_style  = parent_node.style.font_style,
                font_size   = parent_node.style.font_size,
                base_color  = parent_node.style.base_color,
                bold_color  = parent_node.style.bold_color,
            }

            if node.type == "Bold" then
                if node.style.font_style == "normal" then node.style.font_style = "bold" end
                if node.style.font_style == "italic" then node.style.font_style = "bolditalic" end
            elseif node.type == "Italic" then
                if node.style.font_style == "normal" then node.style.font_style = "italic" end
                if node.style.font_style == "bold"   then node.style.font_style = "bolditalic" end
            end

            -- Check if we have a local style
            local style_name        = local_style_name(node)
            local local_style       = style[style_name]
            local overriden_color   = nil

            if local_style then
                node.style.name         = style_name
                node.style.font_family  = local_style.font_family or parent_node.style.font_family
                node.style.font_size    = local_style.font_size or parent_node.style.font_size

                if local_style.base_color then
                    local res = resolve_color(local_style.base_color)
                    if res then node.style.base_color = res end
                end

                if local_style.bold_color then
                    local res = resolve_color(local_style.bold_color)
                    if res then node.style.bold_color = res end
                end
            end

            if node.style.font_style == "normal" or node.style.font_style == "italic"   then node.style.color = node.style.base_color end
            if node.style.font_style == "bold" or node.style.font_style == "bolditalic" then node.style.color = node.style.bold_color end

            if node.attributes.color then
                overriden_color = node.attributes.color
            end

            if overriden_color then
                local res = resolve_color(overriden_color)
                if res then
                    node.style.base_color   = res
                    node.style.bold_color   = res
                    node.style.color        = res
                end
            end
        end

        if node.type ~= "Table" then
            for _, child in ipairs(node.children) do
                precalculate_style(node, child)
            end
        else
            for _, row in ipairs(node.children.rows) do
                for _, cell in ipairs(row) do
                    for _, child in ipairs(cell) do
                        precalculate_style(node, child)
                    end
                end
            end
        end
    end

    local function left_indent(node_style, level)
        local pad = node_style.padding_left

        if should_autopad then
            pad = #h_stack * style.default.autopad
        end

        -- This is a sub-indented block (like sublist...)
        -- The parent is already padded in a group, so we just need to sub-pad
        if node_style.padding_indent then
            if level ~= 1 then
                pad = node_style.padding_indent
            else
                if should_autopad then
                    pad = pad + node_style.padding_indent
                end
            end
        end

        return pad
    end

    local function IndentLeft(node_style, level)
        ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + left_indent(node_style, level))
    end

    -- Pointer to the last node encountered
    local last_node         = nil
    local max_x             = nil
    local max_y             = nil
    local win_x, win_y      = ImGui.GetWindowPos(ctx)
    local start_x, start_y  = win_x, win_y

    local function render_node(node, level)
        level = level or 1 -- Default to level 1 if not provided
        if node.type == "Document" then
            if not node.style then
                -- We need to calculate the node style for fast rendering later
                -- This is done only once, we instrument the ast and store everyting inside
                precalculate_style(nil, node)
                node.last_node = precalc_last_node
            end
            last_node = node.last_node

            for _, child in ipairs(node.children) do
                render_node(child, level)
            end
        elseif node.type == "Header" then

            num_line    = num_line + 1
            num_on_line = 0

            local nstyle        = style[node.style.name]

            while (#h_stack > 0) and (h_stack[#h_stack] >= node.hlevel) do
                -- Remove all superfluous levels from the stack
                h_stack[#h_stack] = nil
            end

            -- Add some vertical padding before
            ImGuiVDummy(ctx, nstyle.padding_top)
            IndentLeft(nstyle, level)

            ImGui.AlignTextToFramePadding(ctx)

            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, nstyle.line_spacing)
            push_style(node)
            render_children(node.children, level)
            pop_style()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            -- Add some vertical padding after
            if not (rendered_last and skip_last_whitespace) then
                ImGuiVDummy(ctx, nstyle.padding_bottom)
            end

            h_stack[#h_stack+1] = node.hlevel -- Add current level

        elseif node.type == "Paragraph" then
            num_line    = num_line + 1
            num_on_line = 0

            local nstyle = style.paragraph

            -- Add some vertical padding before
            ImGuiVDummy(ctx, ((node.parent_blockquote) and (nstyle.padding_in_blockquote) or (nstyle.padding_top)))

            -- Indent left, using cursor
            IndentLeft(nstyle, level)

            ImGui.AlignTextToFramePadding(ctx)

            -- Use a group to lock the x indentation
            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, nstyle.line_spacing)
            push_style(node)
            render_children(node.children, level)
            pop_style()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            -- Add some vertical padding after
            -- If we're in a blockquote, force symmetry
            if not (rendered_last and skip_last_whitespace) then
                ImGuiVDummy(ctx, ((node.parent_blockquote) and (nstyle.padding_in_blockquote) or (nstyle.padding_bottom)))
            end
        elseif node.type == "Bold" then
            render_children(node.children, level)
        elseif node.type == "Italic" then
            render_children(node.children, level)
        elseif node.type == "Code" then
            render_children(node.children, level)
        elseif node.type == "Span" then
            render_children(node.children, level)
        elseif node.type == "Separator" then
            ImGuiVDummy(ctx, style.separator.padding_top)
            ImGui.Separator(ctx)

            if not (rendered_last and skip_last_whitespace) then
                ImGuiVDummy(ctx, style.separator.padding_bottom)
            end
        elseif node.type == "Text" then

            if should_wrap then
                wrap_text(node)
            else
                if num_on_line ~= 0 then ImGui.SameLine(ctx) end

                push_style(node)
                ImGui.TextColored(ctx, base_txt_color, node.value)
                pop_style()

                ImGui.SameLine(ctx)
                num_on_line = num_on_line + 1
            end

        elseif node.type == "Link" then
            in_link = { url = node.attributes.url }
            in_link.scheme, in_link.target = node.attributes.url:match("^(.*)://(.*)")

            if in_link.scheme == 'action' then
                node.rand = node.rand or math.random()
                ImGui.BeginGroup(ctx)
                ImGui.Text(ctx, " ")
                ImGui.SameLine(ctx)

                -- Convert to integer
                in_link.target = tonumber(in_link.target) or reaper.NamedCommandLookup(in_link.target)
                in_link.state = (reaper.GetToggleCommandState(in_link.target) == 1)

                if in_link.state then ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x2088FFFF) end
                if ImGui.Button(ctx, AstToText.ASTToPlainText(node.children) .. "##" .. node.rand) then
                    LaunchLink(in_link)
                end
                if in_link.state then ImGui.PopStyleColor(ctx) end

                ImGui.SameLine(ctx)
                ImGui.Text(ctx, " ")
                ImGui.SameLine(ctx)
                ImGui.EndGroup(ctx)
                ImGui.SameLine(ctx)

                -- Since we used AstToPlainText, last_node detection is affected
                if nodeHasChild(node, last_node) then
                    rendered_last = true
                end
                num_on_line = num_on_line + 1
            else
                push_style(node)
                render_children(node.children, level)
                pop_style()
            end
            in_link = nil

        elseif node.type == "LineBreak" then

            num_on_line     = 0
            num_line        = num_line + 1

            ImGui.NewLine(ctx)
            ImGui.AlignTextToFramePadding(ctx)

        elseif (node.type == "UnorderedList") or (node.type == "OrderedList") then
            local nstyle = style.list

            num_on_line     = 0
            num_line        = num_line + 1

            if level > 1 then
                -- Special case for sub lists. They are added directly behind inlined elements
                -- So this is the only criteria that helps us to decide
                ImGui.NewLine(ctx)
            else
                ImGuiVDummy(ctx, nstyle.padding_top)
            end

            IndentLeft(nstyle, level)
            ImGui.AlignTextToFramePadding(ctx)

            ImGui.BeginGroup(ctx)
            render_children(node.children, level)
            ImGui.EndGroup(ctx)

            -- Avoid line return, the next list item will perform new line
            if level > 1 then
                ImGui.SameLine(ctx)
            else
                if not (rendered_last and skip_last_whitespace) then
                    ImGuiVDummy(ctx, nstyle.padding_bottom)
                end
            end

        elseif node.type == "ListItem" then
            local nstyle = style.list

            num_line        = num_line + 1
            num_on_line     = 0

            ImGui.AlignTextToFramePadding(ctx)

            if node.parent_list.type == "UnorderedList" then
                -- Render a bullet with the default font
                ImGui.PushFont(ctx, nil, style.default.font_size)
                ImGui.Text(ctx, "• ")
                ImGui.PopFont(ctx)
                num_on_line = 0
            else
                push_style(node)
                ImGui.Text(ctx, node.attributes.number .. ". ")
                pop_style()
                num_on_line = 0
            end

            push_style(node)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, nstyle.line_spacing)
            -- Since we've added bullet / numbering, go back to current line
            ImGui.SameLine(ctx)
            ImGui.BeginGroup(ctx)
            for _, child in ipairs(node.children) do
                render_node(child, level + 1)
            end
            ImGui.EndGroup(ctx)
            ImGui.PopStyleVar(ctx)
            pop_style()

        elseif node.type == "Blockquote" then
            local nstyle = style.blockquote

            num_line        = num_line + 1
            num_on_line     = 0

            if level == 1 then
                -- Add some vertical padding before
                ImGuiVDummy(ctx, nstyle.padding_top)
            else
                ImGuiVDummy(ctx, style.paragraph.padding_in_blockquote)
            end

            -- Indent left, using cursor
            IndentLeft(nstyle, level)
            ImGui.AlignTextToFramePadding(ctx)

            local x, y = ImGui.GetCursorScreenPos(ctx)

            -- Use a group to lock the x indentation
            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, 0)
            push_style(node)
            render_children(node.children, level + 1)
            pop_style()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            local x2, y2 = ImGui.GetCursorScreenPos(ctx)
            local draw_list = ImGui.GetWindowDrawList(ctx)
            x = x + left_indent(style.paragraph, 1) - 10
            ImGui.DrawList_AddRectFilled(draw_list, x, y, x + 4 , y2, 0x288efaFF)

            if level == 1 then
                -- Add some vertical padding after
                if not (rendered_last and skip_last_whitespace) then
                    ImGuiVDummy(ctx, nstyle.padding_bottom)
                end
            else
                ImGuiVDummy(ctx, style.paragraph.padding_in_blockquote)
            end

        elseif node.type == "CodeBlock" then
            local nstyle = style.code

            num_line        = num_line + 1
            num_on_line     = 0

            ImGuiVDummy(ctx, nstyle.padding_top)
            IndentLeft(nstyle, level)
            ImGui.AlignTextToFramePadding(ctx)

            ImGui.BeginGroup(ctx)
            ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 0, nstyle.line_spacing)
            push_style(node)
            for line in string.gmatch(node.value .. "\n", "(.-)\n") do
                ImGui.TextColored(ctx, resolve_color(nstyle.color), line)
            end
            pop_style()
            ImGui.PopStyleVar(ctx)
            ImGui.EndGroup(ctx)

            if not (rendered_last and skip_last_whitespace) then
                ImGuiVDummy(ctx, nstyle.padding_bottom)
            end
        elseif node.type == "Image" then

            num_on_line     = 0
            num_line        = num_line + 1

            push_style(node)
            ImGui.Text(ctx, "Images are not supported yet.")
            pop_style()

        elseif node.type == "Table" then
            local nstyle = style.table

            num_on_line     = 0
            num_line        = num_line + 1

            local column_count = 1

            if node.children.headers and #node.children.headers > column_count then column_count = #node.children.headers end
            for _, row in ipairs(node.children.rows) do
                if #row > column_count then column_count = #row end
            end

            ImGuiVDummy(ctx, nstyle.padding_top)
            IndentLeft(nstyle, level)
            ImGui.AlignTextToFramePadding(ctx)

            ImGui.BeginGroup(ctx)
            push_style(node)
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
            pop_style()

            if not (rendered_last and skip_last_whitespace) then
                ImGuiVDummy(ctx, nstyle.padding_bottom)
            end
        elseif node.type == "Checkbox" then
            node.rand = node.rand or math.random()

            if num_on_line == 0 then
                ImGui.AlignTextToFramePadding(ctx)
            end

            -- A bit of cooking to resize the checkbox
            ImGui.BeginGroup(ctx)
            local frameheight = ImGui.GetFrameHeight(ctx)
            push_style(node)
            ImGui.PushFont(ctx, node.style.font, node.style.font_size * 0.6)
            local frameheight2 = ImGui.GetFrameHeight(ctx) - 3
            ImGui.SetCursorPosY(ctx, ImGui.GetCursorPosY(ctx) + (frameheight - frameheight2) * 0.5)
            local b,v = ImGui.Checkbox(ctx, "##checkbox_" .. node.rand, node.attributes.checked)
            ImGui.PopFont(ctx)
            pop_style()
            ImGui.EndGroup(ctx)

            if b then
                local old_value = node.attributes.checked
                local new_value = not node.attributes.checked

                node.attributes.checked = new_value

                interaction = {
                    type                = "checkbox_clicked",
                    start_offset        = node.attributes.source_offset.start,
                    length              = node.attributes.source_offset.end_pos - node.attributes.source_offset.start + 1,
                    old_value           = old_value,
                    new_value           = node.attributes.checked,
                    replacement_string  = (node.attributes.checked) and ("[x]") or ("[ ]")
                }
            end
            ImGui.SameLine(ctx)
            num_on_line = num_on_line + 1
        else
            error("Unhandle node type " .. node.type)
        end

        local imax_x, imax_y = ImGui.GetItemRectMax(ctx)
        imax_x = imax_x - start_x
        imax_y = imax_y - start_y
        if not max_x or imax_x > max_x then max_x = imax_x end
        if not max_y or imax_y > max_y then max_y = imax_y end

        if (not rendered_last) and (last_node == node) then
            rendered_last = true
        end
    end

    -- Redefine render_children with proper implementation
    render_children = function(children, level)
        for _, child in ipairs(children) do
            render_node(child, level)
        end
    end

    render_node(ast, 1)

    return max_x, max_y, interaction
end

return {
    DEFAULT_STYLE   = DEFAULT_STYLE,
    ASTToImgui      = ASTToImgui
}

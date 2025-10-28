-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- This file is the Demo that comes with ReaImGui:Markdown

local use_profiler   = false
local use_debugger   = false
local do_unit_tests  = false

-----------------

local ACTION        = debug.getinfo(1,"S").source
local ACTION_DIR    = (ACTION:match[[^@?(.*[\/])[^\/]-$]]):gsub("talagan_ReaImGui Markdown/actions/$","/") -- Works both in dev and prod

package.path        = package.path .. ";" .. reaper.ImGui_GetBuiltinPath() .. '/?.lua'
package.path        = package.path .. ";" .. ACTION_DIR .. "talagan_ReaImGui Markdown/?.lua"

local ImGui         = require "reaimgui_markdown/ext/imgui"
local ImGuiMd       = require "reaimgui_markdown"

if use_profiler then
    local profiler       = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')

    ParseMarkdown  = require "reaimgui_markdown/markdown-ast"
    ImGuiMdCore    = require "reaimgui_markdown/markdown-imgui"

    reaper.defer = profiler.defer
    profiler.attachToWorld() -- after all functions have been defined
    profiler.run()
end

if use_debugger then
    reaper.ShowConsoleMsg("Beware, debugging is on. Loading VS debug extension ...")

    -- Use VSCode extension
    local vscode_ext_path = os.getenv("HOME") .. "/.vscode/extensions/"
    local p    = 0
    local sdir = ''
    while sdir do
        sdir = reaper.EnumerateSubdirectories(vscode_ext_path, p)
        if not sdir then
            reaper.ShowConsoleMsg(" failed *******.\n")
            break
        else
            if sdir:match("antoinebalaine%.reascript%-docs") then
                dofile(vscode_ext_path .. "/" .. sdir .. "/debugger/LoadDebug.lua")
                reaper.ShowConsoleMsg(" OK!\n")
                break
            end
        end
        p = p + 1
    end
end


if do_unit_tests then
    -- Reqiore stuff for the profiler to work.
    local UnitTest       = require "reaimgui_markdown/markdown-test"
    UnitTest()
end

-- We override Reaper's defer method for two reasons :
-- We want the full trace on errors
-- We want the debugger to pause on errors

local rdefer = reaper.defer
---@diagnostic disable-next-line: duplicate-set-field
reaper.defer = function(c)
    return rdefer(function() xpcall(c,
        function(err)
            reaper.ShowConsoleMsg(err .. '\n\n' .. debug.traceback())
        end)
    end)
end

local entry = [[
# This is a header level 1
## This is a header level 2
### This is a header level 3
#### This is a header level 4
##### This is a header level 5

This is a simple test with a long sentence, lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sollicitudin nisi vel mattis iaculis. Interdum et malesuada fames etc

This is a paragraph with italic and bold stuff, that is meant to test word wrapping for the different inlined styles _levels of headders_. This is a **very** long paragraph. Here is a small list.

- List entry 1
- List entry 2
- List entry 3

This is a second paragraph.
Only one line feed here.

- Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sollicitudin nisi vel mattis iaculis. Interdum et malesuada fames ac ante ipsum primis in faucibus. Nunc pharetra sagittis dui, in ullamcorper purus ornare rutrum. Morbi laoreet justo at libero dictum sodales. Suspendisse vestibulum sit amet metus nec luctus. Proin sit amet velit fringilla, venenatis libero non, sollicitudin metus. Pellentesque arcu purus, blandit consectetur turpis auctor, blandit consequat leo. Fusce vestibulum, metus quis tincidunt interdum, leo lorem luctus lectus, non interdum arcu libero eget eros.

- Integer ligula dolor, commodo ac nunc et, porta condimentum lacus. Nam gravida velit nibh, nec accumsan dolor sollicitudin eu. Aliquam sit amet congue tortor. Morbi sed auctor ante. Pellentesque in neque nec tortor faucibus commodo vitae eu nunc. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras eleifend, erat et luctus luctus, elit dui ultrices odio, imperdiet sagittis nibh metus sit amet arcu. Donec vitae iaculis tellus.

This paragraph tries to use UTF-8 stuff like this : "漢字" (chinese hanzi) or that : "éééé" "££££" but sometimes fail if the font does not support it.

## Emphasis

*This text will be italic*
_This will also be italic_

**This text will be bold**
__This will also be bold__

This $:#FFFF00:text$ **:green:uses** _:cyan:colors_.

_You **:#FF00FF:can** combine them_

## Lists
### Unordered

* Item 1
* Item 2
* Item 2a
* Item 2b with **bold** and `:pink:color`
    * Item 3a
    * Item 3b
        * wop 1
        * wop 2

### Ordered

1. Item 1
2. Item 2
3. Item 3
    1. Item 3a
    2. Item 3b
4. Item 4

## Images

![This is an alt text.](/image/sample.webp)

## Links

You are currently using [Reaper](https://reaper.fm/).

## Action Links

You can create special links to perform **time seek** in reaper.

  For example [Go to Measure 2](time://2.1) or [Go to position 45s for example](time://0:0:45)

You can also create reaper **action buttons**, here is a mini transport :

  [Stop](action://1016) [Pause](action://1008) [Play](action://1007) [Play/Stop](action://40044)

Or, maybe you want to [Launch another action](action://40605) ?

## Blockquotes

> Markdown is a **:red:lightweight markup language** with plain-text-formatting syntax, created in 2004 by John Gruber with Aaron Swartz.
>> Markdown is often used to format readme files, for writing messages in online discussion forums, and to create rich text using a plain text editor.
>>> Markdown is often used to format readme files, for writing messages in online discussion forums, and to create rich text using a plain text editor.

## Tables

| Left columns  | Right columns |
| ------------- |:-------------:|
| left foo      | right **:green:foo**     |
| left bar      | right bar     |
| left baz      | right baz     |

## Checkboxes

Checkboxes can be put in

- [ ] List items
- [ ] And other list items

Or just [ ] almost [ ] any [x] where ! [ ] [x] [ ] [ ] [x]

| Crazy  | Check | Boxes |
| ------------- |-------------|-|
| See [x] ? | [ ]  Here you go | [x] |

## Blocks of code

```
function publish(msg)
    reaper.ShowConsoleMsg(msg .. "\n")
end

local message = "Hello, reapers !"
publish(message)
```

## Separator

---

## Inline code

This library is **`:orange:powered`** by [ReaImGui](https://forum.cockos.com/showthread.php?t=250419).

]]

local ctx       = ImGui.CreateContext('ReaImGui:Markdown Demo')
local imgui_md  = ImGuiMd:new(ctx, "markdown_widget_1", { wrap = true, autopad = false, skip_last_whitespace = false, horizontal_scrollbar = true }, {} )

imgui_md:setText(entry)

local function loop()
    ImGui.SetNextWindowSize(ctx, 600, 800, ImGui.Cond_FirstUseEver)
    local ret, open = ImGui.Begin(ctx, "ReaImGui:Markdown Demo", true)
    if ret then

        local b,v

        -- Option header
        ImGui.BeginGroup(ctx)
            b, v = ImGui.Checkbox(ctx, "Line wrap", imgui_md.options.wrap)
            if b then imgui_md.options.wrap = v end
            ImGui.SameLine(ctx)
            b, v = ImGui.Checkbox(ctx, "Auto-Pad", imgui_md.options.autopad)
            if b then imgui_md.options.autopad = v end
            ImGui.SameLine(ctx)
            b, v = ImGui.Checkbox(ctx, "Horizontal Scrollbar", imgui_md.options.horizontal_scrollbar)
            if b then imgui_md.options.horizontal_scrollbar = v end
            ImGui.SameLine(ctx)
            b, v = ImGui.Checkbox(ctx, "Skip last whitespace", imgui_md.options.skip_last_whitespace)
            if b then imgui_md.options.skip_last_whitespace = v end
        ImGui.EndGroup(ctx)

        b, entry = ImGui.InputTextMultiline(ctx, "##mardown_input_1", entry,  ImGui.GetContentRegionAvail(ctx) , 200)
        if b then
            imgui_md:setText(entry)
        end

        -- The rendering returns some metrics info (max_x, max_y) in case you want to resize the container
        -- It may also return an interaction object, when the markdown triggers auto-edit events
        -- So that you can patch your original string and handle the event (currently only checkboxes are handled)
        local max_x, maxy, interaction = imgui_md:render(ctx)

        if interaction then
            local before    = entry.sub(entry, 1, interaction.start_offset - 1)
            local after     = entry.sub(entry, interaction.start_offset + interaction.length)
            entry = before .. interaction.replacement_string .. after
        end

        ImGui.End(ctx)
    end
    if open then
        reaper.defer(loop)
    end
end
reaper.defer(loop)

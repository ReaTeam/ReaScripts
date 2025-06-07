-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- This file is the Demo that comes with ReaImGui:Markdown

package.path    = reaper.ImGui_GetBuiltinPath() .. '/?.lua'

local use_dev_folder = false
local use_profiler   = false
local do_unit_tests  = false

-----------------

if not use_dev_folder then
    package.path    = package.path .. ";" .. (reaper.GetResourcePath() .. "/Scripts/ReaTeam Scripts/Development/talagan_ReaImGui Markdown") .. '/?.lua'
else
    package.path    = package.path .. ";" .. (reaper.GetResourcePath() .. "/Scripts/Talagan Dev/talagan_ReaImGui Markdown") .. '/?.lua'
end

local ImGui     = require "reaimgui_markdown/ext/imgui"
local ImGuiMd   = require "reaimgui_markdown"

if do_unit_tests then
    -- Reqiore stuff for the profiler to work.
    local UnitTest       = require "reaimgui_markdown/markdown-test"
    UnitTest()
end

if use_profiler then
    local profiler       = dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')

    ParseMarkdown  = require "reaimgui_markdown/markdown-ast"
    ImGuiMdCore    = require "reaimgui_markdown/markdown-imgui"

    reaper.defer = profiler.defer
    profiler.attachToWorld() -- after all functions have been defined
    profiler.run()
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

This `:#FFFF00:text` **:green:uses** _:cyan:colors_.

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
local imgui_md  = ImGuiMd:new(ctx, "markdown_widget_1", { wrap = true }, {} )

imgui_md:setText(entry)

local function loop()
    ImGui.SetNextWindowSize(ctx, 600, 800, ImGui.Cond_FirstUseEver)
    local ret, open = ImGui.Begin(ctx, "ReaImGui:Markdown Demo", true)

    if ret then

        local b

        b, entry = ImGui.InputTextMultiline(ctx, "##mardown_input_1", entry,  ImGui.GetContentRegionAvail(ctx) , 200)
        if b then
            imgui_md:setText(entry)
        end

        imgui_md:render(ctx)

        ImGui.End(ctx)
    end
    if open then
        reaper.defer(loop)
    end
end
reaper.defer(loop)

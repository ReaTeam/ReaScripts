-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- Unit Tests

local ParseMarkdown     = require "reaimgui_markdown/markdown-ast"
local ASTToHtml         = require "reaimgui_markdown/markdown-html"

local function dotest(entry, wanted_html)
  local ast   = ParseMarkdown(entry)
  local html  = ASTToHtml(ast)
  local cond  = (html == wanted_html)

  if not cond then
    reaper.ShowConsoleMsg("=====OBTAINED====\n")
    reaper.ShowConsoleMsg(html)
    reaper.ShowConsoleMsg("=================\n")
    reaper.ShowConsoleMsg("\n")

    error("Test failed\n")
  end

  return ast, html
end

local function test_bold_italic()
  dotest( "Bla bla **bli** blo _blu_ `inline code` toto ",
  "<p>Bla bla <strong>bli</strong> blo <em>blu</em> <code>inline code</code> toto </p>\n")
end

local function test_blockquotes()
  local entry =
[[
> One **test** hop _bli_
> One bis
>> Two
]]
  local wanted =
[[
<blockquote>
<p>One <strong>test</strong> hop <em>bli</em></p>
<p>One bis</p>
<blockquote>
<p>Two</p>
</blockquote>
</blockquote>
]]

  dotest(entry, wanted)
end

local function test_lists()
  local entry =
[[
1. Entry 1 **toto**
2. Entry 2 _bla bli_
   * Entry 1
   * Entry 2
       * Sub 1
       * Sub 2 _bla bli_
]]

  local wanted =
[[
<ol type="1">
<li>Entry 1 <strong>toto</strong></li>
<li>Entry 2 <em>bla bli</em><ul>
<li>Entry 1</li>
<li>Entry 2<ul>
<li>Sub 1</li>
<li>Sub 2 <em>bla bli</em></li>
</ul>
</li>
</ul>
</li>
</ol>
]]

  dotest(entry, wanted)
end


local function test_headers()
  local entry =
[[
# Test 1
## Test 2
]]

  local wanted =
[[
<h1>Test 1</h1>
<h2>Test 2</h2>
]]

  dotest(entry, wanted)
end

local function test_tables()
  local entry =
[[
| table one | table two |
|-----------|-----------|
| ceci **hop** | hip ble _blu_ blo |
]]

  local wanted =
[[
<table>
<thead>
<tr>
<th>table one</th>
<th>table two</th>
</tr>
</thead>
<tbody>
<tr>
<td>ceci <strong>hop</strong></td>
<td>hip ble <em>blu</em> blo</td>
</tr>
</tbody>
</table>
]]

  dotest(entry, wanted)
end

local function test_code()
  local entry =
[[
```
This is pure code **and this** should not try to do |clever|things|
```
]]

  local wanted =
[[
<pre><code>This is pure code **and this** should not try to do |clever|things|
</code></pre>
]]

  dotest(entry, wanted)
end

local function test_lists_2()
  local entry = [[
## Lists

### Unordered

* Item 1
* Item 2
* Item 2a
* Item 2b
    * Item 3a
    * Item 3b

### Ordered

1. Item 1
2. Item 2
3. Item 3
    1. Item 3a
    2. Item 3b
]]

  local wanted = [[
<h2>Lists</h2>
<h3>Unordered</h3>
<ul>
<li>Item 1</li>
<li>Item 2</li>
<li>Item 2a</li>
<li>Item 2b<ul>
<li>Item 3a</li>
<li>Item 3b</li>
</ul>
</li>
</ul>
<h3>Ordered</h3>
<ol type="1">
<li>Item 1</li>
<li>Item 2</li>
<li>Item 3<ol type="A">
<li>Item 3a</li>
<li>Item 3b</li>
</ol>
</li>
</ol>
]]

  dotest(entry, wanted)
end

local function test_tables_2()
  local entry = [[
## Blockquotes

## Tables

| Left columns  | Right columns |
| ------------- |:-------------:|
| left foo      | right foo     |
| left bar      | right bar     |
| left baz      | right baz     |

## Blocks of code

]]

  local wanted = [[
<h2>Blockquotes</h2>
<h2>Tables</h2>
<table>
<thead>
<tr>
<th>Left columns</th>
<th>Right columns</th>
</tr>
</thead>
<tbody>
<tr>
<td>left foo</td>
<td>right foo</td>
</tr>
<tr>
<td>left bar</td>
<td>right bar</td>
</tr>
<tr>
<td>left baz</td>
<td>right baz</td>
</tr>
</tbody>
</table>
<h2>Blocks of code</h2>
]]
  dotest(entry, wanted)
end


local function test_tables_no_header()
  local entry = [[
## Blockquotes

## Tables

| Left columns  | Right columns |
| ------------- |:-------------:|
| left foo      | right foo     |
| left bar      | right bar     |
| left baz      | right baz     |

## Blocks of code

]]
  local wanted = [[
<h2>Blockquotes</h2>
<h2>Tables</h2>
<table>
<thead>
<tr>
<th>Left columns</th>
<th>Right columns</th>
</tr>
</thead>
<tbody>
<tr>
<td>left foo</td>
<td>right foo</td>
</tr>
<tr>
<td>left bar</td>
<td>right bar</td>
</tr>
<tr>
<td>left baz</td>
<td>right baz</td>
</tr>
</tbody>
</table>
<h2>Blocks of code</h2>
]]
  dotest(entry, wanted)
end


local function gros_test()
  local entry = [[
# Markdown syntax guide

## Headers

# This is a Heading h1
## This is a Heading h2
##### This is a Heading **h5**

## Emphasis

*This text will be italic*
_This will also be italic_

**This text will be 漢字漢字 bold漢字**漢字
__This will also be bold__

_You ééé**:#FF0000:can** àçoi combine them_

## Lists

### Unordered

* Item 1
* Item 2
* Item 2a
* Item 2b
    * Item 3a
    * Item 3b 漢字

### Ordered

1. Item 1
2. Item 2
3. Item 3
    1. Item 3a
    2. Item 3b

## Images

![This is an alt text.](/image/sample.webp)

## Links

You may be using [Markdown Live Preview](https://markdownlivepreview.com/).

## Blockquotes

> Markdown is a lightweight markup language with plain-text-formatting syntax, created in 2004 by John Gruber with Aaron Swartz.
>
>> Markdown is often used to format readme files, for writing messages in online discussion forums, and to create rich text using a plain text editor.

## Tables

| Left columns  | Right columns |
| ------------- |:-------------:|
| left foo 漢字      | right foo     |
| left bar      | right bar     |
| left baz      | right baz     |

## Blocks 漢字 of code

```
let message = 'Hello world'; 漢字
alert(message);
```

## Inline code

This web site is using 漢字 `:blue:markedjs/marked 漢字`.

]]
end

local function perform_tests()

  test_bold_italic()
  test_blockquotes()

  test_lists()
  test_lists_2()
  test_headers()

  test_code()

  test_tables()
  test_tables_2()
  test_tables_no_header()

  --gros_test()

  reaper.ShowConsoleMsg("ALL TESTS PASSED\n")
end

return perform_tests

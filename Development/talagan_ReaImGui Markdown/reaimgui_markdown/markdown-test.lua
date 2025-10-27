-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- Unit Tests

local ParseMarkdown     = require "reaimgui_markdown/markdown-ast"
local ASTToHtml         = require "reaimgui_markdown/markdown-html"

local function dotest(entry, wanted_html, test_name)
  local ast   = ParseMarkdown(entry)
  local html  = ASTToHtml(ast)
  local cond  = (html == wanted_html)

  if not cond then
    reaper.ShowConsoleMsg("=====OBTAINED====\n")
    reaper.ShowConsoleMsg(html)
    reaper.ShowConsoleMsg("=====WANTED=====\n")
    reaper.ShowConsoleMsg(wanted_html)
    reaper.ShowConsoleMsg("=================\n")
    reaper.ShowConsoleMsg("\n")

    test_name = test_name or "unknown name"
    error("Test failed (" .. test_name  .. ")\n")
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

local functional_tests = {

  -- ==========================================================================
  -- 1. BASIC INLINE FORMATTING
  -- ==========================================================================
  {
    name = "Basic inline formatting",
    input = [[This is **bold with asterisks** here

This is __bold with underscores__ here

This is *italic with asterisk* here

This is _italic with underscore_ here

This is ***bold and italic*** text

This is `inline code` here]],
    expected_html = [[<p>This is <strong>bold with asterisks</strong> here</p>
<p>This is <strong>bold with underscores</strong> here</p>
<p>This is <em>italic with asterisk</em> here</p>
<p>This is <em>italic with underscore</em> here</p>
<p>This is <strong><em>bold and italic</em></strong> text</p>
<p>This is <code>inline code</code> here</p>
]]
  },

  -- ==========================================================================
  -- 2. NESTED INLINE FORMATTING
  -- ==========================================================================
  {
    name = "Nested inline formatting",
    input = [[_This is **bold inside italic**_

**This is *italic inside bold***

**Bold with _italic_ and `code`**]],
    expected_html = [[<p><em>This is <strong>bold inside italic</strong></em></p>
<p><strong>This is <em>italic inside bold</em></strong></p>
<p><strong>Bold with <em>italic</em> and <code>code</code></strong></p>
]]
  },

  -- ==========================================================================
  -- 3. LINKS AND IMAGES
  -- ==========================================================================
  {
    name = "Links and images",
    input = [[Click [here](https://example.com)

[**Bold link**](https://example.com)

**Bold with [link](https://example.com) inside**

![Alt text](https://example.com/image.png)

[![Image](img.png)](https://example.com)]],
    expected_html = [[<p>Click <a href="https://example.com">here</a></p>
<p><a href="https://example.com"><strong>Bold link</strong></a></p>
<p><strong>Bold with <a href="https://example.com">link</a> inside</strong></p>
<p><img src="https://example.com/image.png" alt="Alt text"></p>
<p><a href="https://example.com"><img src="img.png" alt="Image"></a></p>
]]
  },

  -- ==========================================================================
  -- 4. CHECKBOXES
  -- ==========================================================================

  {
    name = "Checkboxes",
    input = [[This is [ ] unchecked

This is [x] checked lowercase

This is [X] checked uppercase

This is [-] partial

**Bold with [x] checkbox**

[Link with [x] checkbox](url)

[ ] First [x] Second [ ] Third]],
    expected_html = [[<p>This is <input type="checkbox"> unchecked</p>
<p>This is <input type="checkbox" checked> checked lowercase</p>
<p>This is <input type="checkbox" checked> checked uppercase</p>
<p>This is <input type="checkbox" indeterminate> partial</p>
<p><strong>Bold with <input type="checkbox" checked> checkbox</strong></p>
<p><a href="url">Link with <input type="checkbox" checked> checkbox</a></p>
<p><input type="checkbox"> First <input type="checkbox" checked> Second <input type="checkbox"> Third</p>
]]
  },

  -- ==========================================================================
  -- 5. SPAN WITH COLORS
  -- ==========================================================================
  {
    name = "Span with colors",
    input = [[$:red:Red text$

$Plain span$

$:blue:**Bold blue**$

**Bold with $:green:green$ inside**

$:red:Red [ ] checkbox$]],
    expected_html = [[<p><span style="color: red">Red text</span></p>
<p><span>Plain span</span></p>
<p><span style="color: blue"><strong>Bold blue</strong></span></p>
<p><strong>Bold with <span style="color: green">green</span> inside</strong></p>
<p><span style="color: red">Red <input type="checkbox"> checkbox</span></p>
]]
  },

  -- ==========================================================================
  -- 6. ESCAPED CHARACTERS
  -- ==========================================================================
  {
    name = "Escaped characters",
    input = [[This is \*not italic\*

This is \_not italic\_

This is \`not code\`

This is \[x\] not a checkbox

This is \$not a span\$

This is \\ a backslash

This is \\*italic* text]],
    expected_html = [[<p>This is *not italic*</p>
<p>This is _not italic_</p>
<p>This is `not code`</p>
<p>This is [x] not a checkbox</p>
<p>This is $not a span$</p>
<p>This is \ a backslash</p>
<p>This is \<em>italic</em> text</p>
]]
  },

  -- ==========================================================================
  -- 7. HEADERS
  -- ==========================================================================
  {
    name = "Headers",
    input = [[# Header 1

###### Header 6

## Header with **bold**

### Header with [ ] checkbox

# [Link header](url)]],
    expected_html = [[<h1>Header 1</h1>
<h6>Header 6</h6>
<h2>Header with <strong>bold</strong></h2>
<h3>Header with <input type="checkbox"> checkbox</h3>
<h1><a href="url">Link header</a></h1>
]]
  },

  -- ==========================================================================
  -- 8. LISTS
  -- ==========================================================================
  {
    name = "Lists",
    input = [[- Item 1
- Item 2
- Item 3

1. First
2. Second
3. Third

- [ ] Todo 1
- [x] Todo 2
- [ ] Todo 3

- **Bold item**
- Normal item

- Item 1
  - Nested 1
  - Nested 2
- Item 2

1. First
  - Nested bullet
  - Another
2. Second]],
    expected_html = [[<ul>
<li>Item 1</li>
<li>Item 2</li>
<li>Item 3</li>
</ul>
<ol type="1">
<li>First</li>
<li>Second</li>
<li>Third</li>
</ol>
<ul>
<li><input type="checkbox"> Todo 1</li>
<li><input type="checkbox" checked> Todo 2</li>
<li><input type="checkbox"> Todo 3</li>
</ul>
<ul>
<li><strong>Bold item</strong></li>
<li>Normal item</li>
</ul>
<ul>
<li>Item 1<ul>
<li>Nested 1</li>
<li>Nested 2</li>
</ul>
</li>
<li>Item 2</li>
</ul>
<ol type="1">
<li>First<ul>
<li>Nested bullet</li>
<li>Another</li>
</ul>
</li>
<li>Second</li>
</ol>
]]
  },

  -- ==========================================================================
  -- 9. BLOCKQUOTES
  -- ==========================================================================
  {
    name = "Blockquotes",
    input = [[> This is a quote

> Quote with **bold** text

> Quote with [x] checkbox

> Line 1
> Line 2
> Line 3

> Level 1
>> Level 2
>>> Level 3]],
    expected_html = [[<blockquote>
<p>This is a quote</p>
</blockquote>
<blockquote>
<p>Quote with <strong>bold</strong> text</p>
</blockquote>
<blockquote>
<p>Quote with <input type="checkbox" checked> checkbox</p>
</blockquote>
<blockquote>
<p>Line 1</p>
<p>Line 2</p>
<p>Line 3</p>
</blockquote>
<blockquote>
<p>Level 1</p>
<blockquote>
<p>Level 2</p>
<blockquote>
<p>Level 3</p>
</blockquote>
</blockquote>
</blockquote>
]]
  },

  -- ==========================================================================
  -- 10. CODE BLOCKS
  -- ==========================================================================
  {
    name = "Code blocks",
    input = [[```
code line 1
code line 2
```
```
**not bold**
[x] not checkbox
```]],
    expected_html = [[<pre><code>code line 1
code line 2
</code></pre>
<pre><code>**not bold**
[x] not checkbox
</code></pre>
]]
  },

  -- ==========================================================================
  -- 11. TABLES
  -- ==========================================================================
  {
    name = "Tables",
    input = [[| Header 1 | Header 2 |
|----------|----------|
| Cell 1   | Cell 2   |

| **Bold** | Normal |
|----------|--------|
| Cell 1   | Cell 2 |

| Task | Status |
|------|--------|
| Task 1 | [x] |
| Task 2 | [ ] |

| Cell 1 | Cell 2 |
| Cell 3 | Cell 4 |]],
    expected_html = [[<table>
<thead>
<tr>
<th>Header 1</th>
<th>Header 2</th>
</tr>
</thead>
<tbody>
<tr>
<td>Cell 1</td>
<td>Cell 2</td>
</tr>
</tbody>
</table>
<table>
<thead>
<tr>
<th>**Bold**</th>
<th>Normal</th>
</tr>
</thead>
<tbody>
<tr>
<td>Cell 1</td>
<td>Cell 2</td>
</tr>
</tbody>
</table>
<table>
<thead>
<tr>
<th>Task</th>
<th>Status</th>
</tr>
</thead>
<tbody>
<tr>
<td>Task 1</td>
<td><input type="checkbox" checked></td>
</tr>
<tr>
<td>Task 2</td>
<td><input type="checkbox"></td>
</tr>
</tbody>
</table>
<table>
<tbody>
<tr>
<td>Cell 1</td>
<td>Cell 2</td>
</tr>
<tr>
<td>Cell 3</td>
<td>Cell 4</td>
</tr>
</tbody>
</table>
]]
  },

  -- ==========================================================================
  -- 12. PARAGRAPHS AND LINE BREAKS
  -- ==========================================================================
  {
    name = "Paragraphs and line breaks",
    input = [[This is a paragraph.

Line 1
Line 2
Line 3

Paragraph 1

Paragraph 2

Paragraph 3]],
    expected_html = [[<p>This is a paragraph.</p>
<p>Line 1<br>
Line 2<br>
Line 3</p>
<p>Paragraph 1</p>
<p>Paragraph 2</p>
<p>Paragraph 3</p>
]]
  },

  -- ==========================================================================
  -- 13. HORIZONTAL RULES
  -- ==========================================================================
  {
    name = "Horizontal rules",
    input = [[Text before

---

Text after]],
    expected_html = [[<p>Text before</p>
<hr>
<p>Text after</p>
]]
  },


  -- ==========================================================================
  -- 14. EDGE CASES
  -- ==========================================================================
  {
    name = "Edge cases",
    input = [[This is **not closed

This is *not closed

This is `not closed

This is $not closed

**Bold with *mismatched* markers**

[x](url) is link, [x] is checkbox

 - ]],
    expected_html = [[<p>This is **not closed</p>
<p>This is *not closed</p>
<p>This is `not closed</p>
<p>This is $not closed</p>
<p><strong>Bold with <em>mismatched</em> markers</strong></p>
<p><a href="url">x</a> is link, <input type="checkbox" checked> is checkbox</p>
]]
  },
  {
    name = "Empty stuff case",
    input = "****  ____ `` $$ [ ]",
    expected_html = [[<p>****  ____ <code></code> <span></span> <input type="checkbox"></p>
]]
  },
  {
    name = "Forum beurk",
    input = "__*a*____*b*__",
    expected_html = "<p><strong><em>a</em></strong><strong><em>b</em></strong></p>\n"
  },


  -- ==========================================================================
  -- 15. COMPLEX COMBINATIONS
  -- ==========================================================================
  {
    name = "Complex combinations",
    input = [[Text with **bold**, *italic*, `code`, [link](url), ![img](pic.png), [x] checkbox, and $:red:colored$

**Bold with _italic and `code` and $:blue:color$_**

- **[Bold link](url)** with [x] checkbox
- $:red:Colored$ with *italic*

> Quote with **bold**, [link](url), [x] checkbox, and $:green:color$]],
    expected_html = [[<p>Text with <strong>bold</strong>, <em>italic</em>, <code>code</code>, <a href="url">link</a>, <img src="pic.png" alt="img">, <input type="checkbox" checked> checkbox, and <span style="color: red">colored</span></p>
<p><strong>Bold with <em>italic and <code>code</code> and <span style="color: blue">color</span></em></strong></p>
<ul>
<li><strong><a href="url">Bold link</a></strong> with <input type="checkbox" checked> checkbox</li>
<li><span style="color: red">Colored</span> with <em>italic</em></li>
</ul>
<blockquote>
<p>Quote with <strong>bold</strong>, <a href="url">link</a>, <input type="checkbox" checked> checkbox, and <span style="color: green">color</span></p>
</blockquote>
]]
  },

  -- ==========================================================================
  -- 16. COLOR IN EXISTING ELEMENTS (backward compatibility)
  -- ==========================================================================
  {
    name = "Color in existing elements",
    input = [[`code`

**:red:Bold red**

*:blue:Italic blue*]],
    expected_html = [[<p><code>code</code></p>
<p><strong style="color: red">Bold red</strong></p>
<p><em style="color: blue">Italic blue</em></p>
]]
  },

}



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

  for _, test in ipairs(functional_tests) do
    dotest(test.input, test.expected_html, test.name)
  end

  --gros_test()

  reaper.ShowConsoleMsg("ALL TESTS PASSED\n")
end

return perform_tests

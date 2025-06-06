-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- A mega dirty AST Markdown Parser in Lua
-- Not optimized and needs review but does the job

local RX_ORDERED_LIST     = "^%s*%d+%.%s+"
local RX_UNORDERED_LIST   = "^%s*[-*+]%s+"
local RX_LINEITEM_CONTENT = "^%s*[-*+%d]+%.?%s+(.-)$"
local RX_HEADER           = "^#+ "
local RX_HEADER_CONTENT   = "^#+%s+(.-)$"
local RX_TABLE_LINE       = "^%s*|.*|%s*$"
local RX_CODEBLOCK        = "^```"
local RX_BLOCKQUOTE       = "^>%s*"

local function new_node(type, value, children, attributes)
  return { type = type, value = value or "", children = children or {}, attributes = attributes or {} }
end

local function trim(str)
  return str:match("^%s*(.-)%s*$") or ""
end

local function magiclines(s)
  if s:sub(-1)~="\n" then s=s.."\n" end
  return s:gmatch("(.-)\n")
end

local function eatcolor(content, attributes)
  -- Check for :color: at the start
  local color = content:match("^:([^:]+):")
  if color then
    attributes.color = color
    content = content:sub(#color + 3) -- Remove :color:
  end

  return content
end

-- Parse inline formatting (bold, italic, code)
local function parse_inline(text)
  local nodes = {}
  local i = 1
  local len = #text
  local buffer = ""

  while i <= len do
    local char      = text:sub(i, i)
    local next_char = text:sub(i + 1, i + 1)

    if char == "`" and text:sub(i - 1, i - 1) ~= "\\" then

      -- Inline code
      if buffer ~= "" then
        -- End of current buffer, add new node
        table.insert(nodes, new_node("Text", buffer))
        buffer = ""
      end

      -- Eat everything inside the
      local j = i + 1
      local content = ""
      local attributes = {}
      local found_closing = false
      while j <= len do
        if text:sub(j, j) == "`" and text:sub(j - 1, j - 1) ~= "\\" then

          -- Read color if present
          content = eatcolor(content, attributes)

          table.insert(nodes, new_node("Code", nil, { new_node("Text", content) }, attributes))
          i = j + 1
          found_closing = true
          break
        end
        content = content .. text:sub(j, j)
        j = j + 1
      end

      if not found_closing then
        buffer = buffer .. "`" .. content
        i = j
      end

    elseif (char == "*" or char == "_") and (next_char == "*" or next_char == "_") then
      -- Bold (** or __)
      if buffer ~= "" then
        table.insert(nodes, new_node("Text", buffer))
        buffer = ""
      end

      local marker = char .. next_char
      local j = i + 2
      local content = ""
      local attributes = {}
      local found_closing = false
      while j <= len do
        if text:sub(j, j + 1) == marker then
          -- Read color if present
          content = eatcolor(content, attributes)

          table.insert(nodes, new_node("Bold", nil, parse_inline(content), attributes))
          i = j + 2
          found_closing = true
          break
        end
        content = content .. text:sub(j, j)
        j = j + 1
      end

      if not found_closing then
        buffer = buffer .. marker .. content
        i = j
      end

    elseif (char == "*" or char == "_") and text:sub(i - 1, i - 1) ~= "\\" then
      -- Italic, * or _
      if buffer ~= "" then
        table.insert(nodes, new_node("Text", buffer))
        buffer = ""
      end

      local marker = char
      local j = i + 1
      local content = ""
      local attributes = {}
      local found_closing = false
      while j <= len do
        if text:sub(j, j) == marker and text:sub(j - 1, j - 1) ~= "\\" then
          -- Read color if present
          content = eatcolor(content, attributes)

          table.insert(nodes, new_node("Italic", nil, parse_inline(content), attributes))
          i = j + 1
          found_closing = true
          break
        end
        content = content .. text:sub(j, j)
        j = j + 1
      end

      if not found_closing then
        buffer = buffer .. marker .. content
        i = j
      end

    else
      buffer = buffer .. char
      i = i + 1
    end
  end

  -- There's some remaining stuff...
  if buffer ~= "" then
    table.insert(nodes, new_node("Text", buffer))
  end

  return nodes
end

-- Parse links and images
local function parse_links_and_images(text)
  local nodes = {}
  local i = 1
  local len = #text
  local buffer = ""

  while i <= len do
    local char = text:sub(i, i)
    if char == "!" and text:sub(i + 1, i + 1) == "[" then
      -- Image
      if buffer ~= "" then
        for _, node in ipairs(parse_inline(buffer)) do
          table.insert(nodes, node)
        end
        buffer = ""
      end

      local j = i + 2
      local alt_start = j
      while j <= len and text:sub(j, j) ~= "]" do
        j = j + 1
      end
      if j <= len and text:sub(j + 1, j + 1) == "(" then
        local alt = text:sub(alt_start, j - 1)
        local k = j + 2
        local url_start = k
        while k <= len and text:sub(k, k) ~= ")" do
          k = k + 1
        end
        if k <= len then
          local url = text:sub(url_start, k - 1)
          table.insert(nodes, new_node("Image", nil, nil, { alt = alt, url = url }))
          i = k + 1
        else
          buffer = buffer .. text:sub(i, j)
          i = j + 1
        end
      else
        buffer = buffer .. text:sub(i, j)
        i = j + 1
      end
    elseif char == "[" then
      -- Link
      if buffer ~= "" then
        for _, node in ipairs(parse_inline(buffer)) do
          table.insert(nodes, node)
        end
        buffer = ""
      end
      local j = i + 1
      local text_start = j
      while j <= len and text:sub(j, j) ~= "]" do
        j = j + 1
      end
      if j <= len and text:sub(j + 1, j + 1) == "(" then
        local link_text = text:sub(text_start, j - 1)
        local k = j + 2
        local url_start = k
        while k <= len and text:sub(k, k) ~= ")" do
          k = k + 1
        end
        if k <= len then
          local url = text:sub(url_start, k - 1)
          table.insert(nodes, new_node("Link", nil, parse_inline(link_text), { url = url }))
          i = k + 1
        else
          buffer = buffer .. text:sub(i, j)
          i = j + 1
        end
      else
        buffer = buffer .. text:sub(i, j)
        i = j + 1
      end
    else
      buffer = buffer .. char
      i = i + 1
    end
  end

  if buffer ~= "" then
    for _, node in ipairs(parse_inline(buffer)) do
      table.insert(nodes, node)
    end
  end
  return nodes
end

-- Parse a blockquote block recursively
local function parse_blockquote(lines, start_idx, max_lines)
  local blockquotes = {}
  local i = start_idx

  while i <= max_lines do
    local line = lines[i]
    local blkm = line:match("^>+")

    local quote_level = blkm and #blkm or 0
    if quote_level == 0 then
      break
    end

    local content = line:match("^>+[%s]*(.-)$")
    local current_level = quote_level
    local blockquote = new_node("Blockquote", nil, {}, { level = current_level })

    -- Collect content for the current blockquote
    local children = {}
    if content ~= "" then
      local pnode = new_node("Paragraph", nil, parse_links_and_images(content))
      pnode.parent_blockquote = blockquote
      table.insert(children, pnode)
    end

    -- Check for subsequent lines
    local j = i + 1
    while j <= max_lines do
      local next_line = lines[j]
      local next_blkm = next_line:match("^>+")

      local next_level = next_blkm and #next_blkm or 0
      if next_level == 0 then
        i = j
        break
      end

      if next_level > current_level then
        -- Start a nested blockquote
        local nested_result, new_i = parse_blockquote(lines, j, max_lines)
        for _, nested_blockquote in ipairs(nested_result) do
          table.insert(children, nested_blockquote)
        end
        j = new_i
      elseif next_level == current_level then
        -- Same level, add as another paragraph
        local next_content = next_line:match("^>+[%s]*(.-)$")
        if next_content ~= "" then
          local pnode = new_node("Paragraph", nil, parse_links_and_images(next_content))
          pnode.parent_blockquote = blockquote
          table.insert(children, pnode)
        end
        j = j + 1
      else
        -- Lower level, end current blockquote
        i = j
        break
      end
    end
    i = j

    if #children > 0 then
      blockquote.children = children
      table.insert(blockquotes, blockquote)
    end
  end

  return blockquotes, i
end

-- Parse a list block recursively
local function parse_list(lines, start_idx, max_lines, base_indent)
  local lists = {}
  local i = start_idx

  while i <= max_lines do
    local line = lines[i]
    local blkm = line:match("^%s*")
    local indent = blkm and #blkm or 0

    if indent < base_indent or not (line:match(RX_UNORDERED_LIST) or line:match(RX_ORDERED_LIST)) then
      break
    end

    local is_ordered = line:match(RX_ORDERED_LIST) ~= nil
    local list_type = is_ordered and "OrderedList" or "UnorderedList"
    local content = line:match(RX_LINEITEM_CONTENT)
    local current_list = new_node(list_type, nil, {})
    local current_indent = indent
    local item_number = 1

    -- Add the first list item
    local current_item = new_node("ListItem", nil, parse_links_and_images(content), { number = item_number })
    table.insert(current_list.children, current_item)
    current_item.parent_list = current_list
    i = i + 1

    -- Check for subsequent lines
    while i <= max_lines do
      local next_line = lines[i]
      local next_blkm = next_line:match("^%s*")
      local next_indent = next_blkm and #next_blkm or 0

      local is_list_item = next_line:match(RX_UNORDERED_LIST) or next_line:match(RX_ORDERED_LIST)

      if next_indent >= current_indent + 2 and next_indent <= current_indent + 4 and is_list_item then
        -- Nested list
        local nested_lists, new_i = parse_list(lines, i, max_lines, current_indent + 2)
        for _, nested_list in ipairs(nested_lists) do
          table.insert(current_item.children, nested_list)
        end
        i = new_i
      elseif next_indent == current_indent and is_list_item then
        -- Same level list item
        item_number = item_number + 1
        local next_content = next_line:match(RX_LINEITEM_CONTENT)
        current_item = new_node("ListItem", nil, parse_links_and_images(next_content), { number = item_number })
        table.insert(current_list.children, current_item)
        current_item.parent_list = current_list
        i = i + 1
      else
        break
      end
    end

    table.insert(lists, current_list)
  end

  return lists, i
end

-- Main parser function
local function ParseMarkdown(markdown)
  local lines = {}
  for line in magiclines(markdown) do
    table.insert(lines, line)
  end

  local ast = { type = "Document", children = {} }
  local i = 1
  local in_code_block = false
  local in_table = false
  local table_headers = {}
  local expected_columns = 0
  local raw_rows = {}

  local function finalize_table()
    if in_table and (#raw_rows > 0 or #table_headers > 0) then

      -- We store a special flag to check if there are headers or not for this table
      local parsed_headers = {}
      local headers_are_empty = true
      for j = 1, expected_columns do
        local header_content = table_headers[j] or ""
        table.insert(parsed_headers, header_content)
        if header_content ~= "" then headers_are_empty = false end
      end

      -- Now add rows to the table
      local parsed_rows = {}
      for _, raw_row in ipairs(raw_rows) do
        local row = {}
        for j = 1, expected_columns do
          local cell_content = raw_row[j] or ""
          table.insert(row, parse_links_and_images(cell_content))
        end
        if #row > 0 then
          table.insert(parsed_rows, row)
        end
      end

      -- Create the table root node
      table.insert(ast.children, new_node("Table", nil, { headers = parsed_headers, rows = parsed_rows }, { headers_are_empty = headers_are_empty}))
    end
    in_table = false
    table_headers = {}
    raw_rows = {}
    expected_columns = 0
  end

  while i <= #lines do
    local line = lines[i]
    local trimmed_line = trim(line)

    -- Code block
    if trimmed_line:match(RX_CODEBLOCK) then
      finalize_table()
      if in_code_block then
        in_code_block = false
      else
        in_code_block = true
        table.insert(ast.children, new_node("CodeBlock", ""))
      end
      i = i + 1
    elseif in_code_block then
      ast.children[#ast.children].value = ast.children[#ast.children].value .. line .. "\n"
      i = i + 1
      -- Headers
    elseif trimmed_line:match(RX_HEADER) then
      finalize_table()
      local level = #trimmed_line:match("^#+")
      if level <= 6 then
        local content = trimmed_line:match(RX_HEADER_CONTENT)
        table.insert(ast.children, new_node("Header", nil, parse_inline(content), { level = level }))
      end
      i = i + 1
      -- Blockquote
    elseif trimmed_line:match(RX_BLOCKQUOTE) then
      finalize_table()
      local blockquotes, new_i = parse_blockquote(lines, i, #lines)
      for _, blockquote in ipairs(blockquotes) do
        table.insert(ast.children, blockquote)
      end
      i = new_i
      -- Lists
    elseif trimmed_line:match(RX_UNORDERED_LIST) or trimmed_line:match(RX_ORDERED_LIST) then
      finalize_table()
      local lists, new_i = parse_list(lines, i, #lines, 0)
      for _, list in ipairs(lists) do
        table.insert(ast.children, list)
      end
      i = new_i
      -- Table
    elseif trimmed_line:match(RX_TABLE_LINE) then

      local cells = {}
      for cell in line:gmatch("[^|]+") do
        local trimmed = trim(cell)
        table.insert(cells, trimmed)
      end

      if cells[1] == "" then table.remove(cells, 1) end
      if cells[#cells] == "" then table.remove(cells) end

      if not in_table then
        in_table = true
        table_headers = {}
        raw_rows = {}
        expected_columns = #cells
      end

      if #cells > 0 then
        local is_separator = true
        for _, cell in ipairs(cells) do
          if not cell:match("^[-:]+%s*$") then
            is_separator = false
            break
          end
        end
        if is_separator then
          if #raw_rows > 0 then
            table_headers = raw_rows[#raw_rows]
            raw_rows = {}
          end
        else
          table.insert(raw_rows, cells)
        end
      end
      i = i + 1
    elseif line == "" then
      i = i + 1
    else
      -- Paragraph
      finalize_table()
      -- Collect all consecutive lines (non-empty or with spaces/tabs) for a single paragraph
      local paragraph_nodes = {}
      local j = i
      while j <= #lines and not (lines[j] == "" or lines[j]:match(RX_CODEBLOCK) or lines[j]:match(RX_HEADER) or lines[j]:match(RX_BLOCKQUOTE) or lines[j]:match(RX_UNORDERED_LIST) or lines[j]:match(RX_ORDERED_LIST) or lines[j]:match(RX_TABLE_LINE)) do
        if j > i then
          table.insert(paragraph_nodes, new_node("LineBreak"))
        end
        for _, node in ipairs(parse_links_and_images(lines[j])) do
          table.insert(paragraph_nodes, node)
        end
        j = j + 1
      end
      if j == i then
        for _, node in ipairs(parse_links_and_images(lines[j])) do
          table.insert(paragraph_nodes, node)
        end
        j = j + 1
      end
      table.insert(ast.children, new_node("Paragraph", nil, paragraph_nodes))
      -- Skip any empty lines after the paragraph
      while j <= #lines and lines[j] == "" do
        j = j + 1
      end
      i = j
    end
  end

  finalize_table()
  return ast
end

return ParseMarkdown

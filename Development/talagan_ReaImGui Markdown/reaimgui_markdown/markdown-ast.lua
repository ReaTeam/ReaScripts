-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- ============================================================================
-- CONSTANTS & PATTERNS
-- ============================================================================

local RX_ORDERED_LIST     = "^%s*%d+%.%s+"
local RX_UNORDERED_LIST   = "^%s*[-*+]%s+"
local RX_LINEITEM_CONTENT = "^%s*[-*+%d]+%.?%s+(.-)$"
local RX_HEADER           = "^#+ "
local RX_HEADER_CONTENT   = "^#+%s+(.-)$"
local RX_TABLE_LINE       = "^%s*|.*|%s*$"
local RX_CODEBLOCK        = "^```"
local RX_BLOCKQUOTE       = "^>%s*"
local RX_SEPARATOR        = "^%-%-%-+"

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function new_node(type, value, children, attributes)
  return {
    type = type,
    value = value or "",
    children = children or {},
    attributes = attributes or {}
  }
end

local function trim(str)
  return str:match("^%s*(.-)%s*$") or ""
end

local function magiclines(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

-- Calculate absolute position from line number and column
local function calculate_offset(lines, line_num, col)
  local offset = 0
  for i = 1, line_num - 1 do
    offset = offset + #lines[i] + 1  -- +1 for newline
  end
  return offset + col
end

-- ============================================================================
-- INLINE PARSING - RECURSIVE WITH OFFSET TRACKING
-- ============================================================================

-- Check if we're at an escaped character
local function is_escaped(text, pos)
  if pos <= 1 then return false end
  local backslash_count = 0
  local p = pos - 1
  while p >= 1 and text:sub(p, p) == "\\" do
    backslash_count = backslash_count + 1
    p = p - 1
  end
  return backslash_count % 2 == 1
end

-- Try to match a pattern at position i (returns match length or nil)
local function try_match(text, i, pattern)
  if is_escaped(text, i) then return nil end
  local match = text:sub(i):match("^" .. pattern)
  return match and #match or nil
end

-- Parse color prefix :color: and return color + remaining content
local function extract_color(content)
  local color = content:match("^:([^:]+):")
  if color then
    content = content:sub(#color + 3)  -- Remove :color:
    return color, content
  end
  return nil, content
end

-- Main inline parser - recursive with context
local function parse_inline(text, base_offset)
  base_offset = base_offset or 0
  local nodes = {}
  local i = 1
  local len = #text
  local buffer = ""
  local buffer_start = base_offset + 1

  local function flush_buffer()
    if buffer ~= "" then
      table.insert(nodes, new_node("Text", buffer, nil, {
        source_offset = { start = buffer_start, end_pos = base_offset + i - 1 }
      }))
      buffer = ""
      buffer_start = base_offset + i
    end
  end

  while i <= len do
    local char = text:sub(i, i)
    local remaining = text:sub(i)

    -- ========================================================================
    -- PRIORITY 0: ESCAPED CHARACTERS
    -- ========================================================================
    if char == "\\" and i < len and not is_escaped(text, i) then
      -- Add the next character to buffer without the backslash
      buffer = buffer .. text:sub(i + 1, i + 1)
      i = i + 2
      goto continue
    end

    -- ========================================================================
    -- PRIORITY 1: CODE (highest - content not parsed)
    -- ========================================================================
    if char == "`" and not is_escaped(text, i) then
      flush_buffer()

      local j = i + 1
      local content = ""
      local found = false

      while j <= len do
        if text:sub(j, j) == "`" and not is_escaped(text, j) then
          local color, clean_content = extract_color(content)
          table.insert(nodes, new_node("Code", nil, {
            new_node("Text", clean_content)
          }, {
            color = color,
            source_offset = { start = base_offset + i, end_pos = base_offset + j }
          }))
          i = j + 1
          found = true
          break
        end
        content = content .. text:sub(j, j)
        j = j + 1
      end

      if not found then
        buffer = buffer .. "`"
        -- Don't update buffer_start, keep accumulating
        i = i + 1
      end

    -- ========================================================================
    -- PRIORITY 2: IMAGE (and clickable image)
    -- ========================================================================
    elseif char == "!" and text:sub(i + 1, i + 1) == "[" and not is_escaped(text, i) then
      flush_buffer()

      -- Find the closing ] for alt text
      local j = i + 2
      local bracket_depth = 1
      while j <= len and bracket_depth > 0 do
        if text:sub(j, j) == "[" and not is_escaped(text, j) then
          bracket_depth = bracket_depth + 1
        elseif text:sub(j, j) == "]" and not is_escaped(text, j) then
          bracket_depth = bracket_depth - 1
        end
        if bracket_depth > 0 then
          j = j + 1
        end
      end

      if j <= len and text:sub(j + 1, j + 1) == "(" then
        local alt = text:sub(i + 2, j - 1)
        local k = j + 2
        local paren_depth = 1

        -- Find the closing ) for image URL, handling nested parentheses
        while k <= len and paren_depth > 0 do
          if text:sub(k, k) == "(" and not is_escaped(text, k) then
            paren_depth = paren_depth + 1
          elseif text:sub(k, k) == ")" and not is_escaped(text, k) then
            paren_depth = paren_depth - 1
          end
          if paren_depth > 0 then
            k = k + 1
          end
        end

        if k <= len then
          local img_url = text:sub(j + 2, k - 1)

          -- Check if this image is inside a link: ![...](...)](link_url)
          if text:sub(k + 1, k + 2) == "](" then
            local m = k + 3
            local link_paren_depth = 1

            -- Find the closing ) for link URL
            while m <= len and link_paren_depth > 0 do
              if text:sub(m, m) == "(" and not is_escaped(text, m) then
                link_paren_depth = link_paren_depth + 1
              elseif text:sub(m, m) == ")" and not is_escaped(text, m) then
                link_paren_depth = link_paren_depth - 1
              end
              if link_paren_depth > 0 then
                m = m + 1
              end
            end

            if m <= len then
              local link_url = text:sub(k + 3, m - 1)
              -- Create a Link containing an Image
              table.insert(nodes, new_node("Link", nil, {
                new_node("Image", nil, nil, {
                  alt = alt,
                  url = img_url,
                })
              }, {
                url = link_url,
                source_offset = { start = base_offset + i, end_pos = base_offset + m }
              }))
              i = m + 1
            else
              -- Just an image, not a clickable one
              table.insert(nodes, new_node("Image", nil, nil, {
                alt = alt,
                url = img_url,
                source_offset = { start = base_offset + i, end_pos = base_offset + k }
              }))
              i = k + 1
            end
          else
            -- Just an image
            table.insert(nodes, new_node("Image", nil, nil, {
              alt = alt,
              url = img_url,
              source_offset = { start = base_offset + i, end_pos = base_offset + k }
            }))
            i = k + 1
          end
        else
          buffer = buffer .. text:sub(i, j)
          buffer_start = base_offset + i
          i = j + 1
        end
      else
        buffer = buffer .. text:sub(i, j)
        buffer_start = base_offset + i
        i = j + 1
      end

    -- ========================================================================
    -- PRIORITY 3: LINK (before checkbox to avoid [x](url) conflict)
    -- ========================================================================
    elseif char == "[" and not is_escaped(text, i) then
      -- Check if it's a checkbox pattern
      local checkbox_match = text:sub(i):match("^%[([xX%- ])%]")

      -- If it looks like a checkbox, check if it's followed by ( for a link
      if checkbox_match and text:sub(i + 3, i + 3) == "(" then
        -- It's actually a link like [x](url), not a checkbox
        -- Fall through to link parsing below
        checkbox_match = nil
      end

      if checkbox_match then
        -- It's a checkbox, handle it directly here
        flush_buffer()

        local state = checkbox_match
        local checked = (state == "x" or state == "X")
        local partial = (state == "-")

        table.insert(nodes, new_node("Checkbox", nil, nil, {
          checked = checked,
          partial = partial,
          source_offset = { start = base_offset + i, end_pos = base_offset + i + 2 }
        }))
        i = i + 3
      else
        -- It's a link
        flush_buffer()

        local j = i + 1
        local bracket_depth = 1

        -- Find the closing ] for link text, handling nested brackets
        while j <= len and bracket_depth > 0 do
          if text:sub(j, j) == "[" and not is_escaped(text, j) then
            bracket_depth = bracket_depth + 1
          elseif text:sub(j, j) == "]" and not is_escaped(text, j) then
            bracket_depth = bracket_depth - 1
          end
          if bracket_depth > 0 then
            j = j + 1
          end
        end

        if j <= len and text:sub(j + 1, j + 1) == "(" then
          local link_text = text:sub(i + 1, j - 1)
          local k = j + 2
          local paren_depth = 1

          -- Find the closing ) for link URL, handling nested parentheses
          while k <= len and paren_depth > 0 do
            if text:sub(k, k) == "(" and not is_escaped(text, k) then
              paren_depth = paren_depth + 1
            elseif text:sub(k, k) == ")" and not is_escaped(text, k) then
              paren_depth = paren_depth - 1
            end
            if paren_depth > 0 then
              k = k + 1
            end
          end

          if k <= len then
            local url = text:sub(j + 2, k - 1)
            table.insert(nodes, new_node("Link", nil,
              parse_inline(link_text, base_offset + i),
              {
                url = url,
                source_offset = { start = base_offset + i, end_pos = base_offset + k }
              }
            ))
            i = k + 1
          else
            buffer = buffer .. text:sub(i, j)
            buffer_start = base_offset + i
            i = j + 1
          end
        else
           buffer = buffer .. text:sub(i, j)
          buffer_start = base_offset + i
          i = j + 1
        end
      end

    -- ========================================================================
    -- PRIORITY 5: BOLD+ITALIC (*** or ___) or BOLD (** or __)
    -- ========================================================================
    elseif (char == "*" or char == "_") and text:sub(i + 1, i + 1) == char
           and not is_escaped(text, i) then
      flush_buffer()

      -- Check if it's *** (bold+italic) or just ** (bold)
      local is_bold_italic = text:sub(i + 2, i + 2) == char

      if is_bold_italic then
        -- Handle *** or ___
        local marker = char .. char .. char
        local j = i + 3
        local content = ""
        local found = false

        while j <= len do
          if text:sub(j, j + 2) == marker and not is_escaped(text, j) then
            local color, clean_content = extract_color(content)
            -- Create Bold containing Italic
            table.insert(nodes, new_node("Bold", nil, {
              new_node("Italic", nil, parse_inline(clean_content, base_offset + i + 3), {
                color = color,
              })
            }, {
              source_offset = { start = base_offset + i, end_pos = base_offset + j + 2 }
            }))
            i = j + 3
            found = true
            break
          end
          content = content .. text:sub(j, j)
          j = j + 1
        end

        if not found then
          buffer = buffer .. marker
          i = i + 3  -- *** = 3 characters
        end
      else
        -- Handle ** or __
        local marker = char .. char
        local j = i + 2
        local content = ""
        local found = false

        while j <= len do
          if text:sub(j, j + 1) == marker and not is_escaped(text, j) then
            -- Make sure it's not part of *** (check the char after **)
            local next_char = text:sub(j + 2, j + 2)
            -- If followed by the same char, check if it's *** (reject) or **** (accept first **)
            if next_char == char then
              local after_next = text:sub(j + 3, j + 3)
              -- If it's *** (exactly 3), reject. If it's **** (4+), accept.
              if after_next ~= char then
                -- It's exactly ***, reject this match
                content = content .. text:sub(j, j)
                j = j + 1
                goto continue_bold_search
              end
              -- It's ****, accept the first **
            end

            local color, clean_content = extract_color(content)
            table.insert(nodes, new_node("Bold", nil,
              parse_inline(clean_content, base_offset + i + 2),
              {
                color = color,
                source_offset = { start = base_offset + i, end_pos = base_offset + j + 1 }
              }
            ))
            i = j + 2
            found = true
            break
          end
          content = content .. text:sub(j, j)
          j = j + 1
          ::continue_bold_search::
        end

        if not found then
          buffer = buffer .. marker
          i = i + 2  -- ** = 2 characters
        end
      end

    -- ========================================================================
    -- PRIORITY 6: ITALIC (* or _)
    -- ========================================================================
    elseif (char == "*" or char == "_") and not is_escaped(text, i) then
      flush_buffer()

      local marker = char
      local j = i + 1
      local content = ""
      local found = false

      while j <= len do
        if text:sub(j, j) == marker and not is_escaped(text, j) then
          local color, clean_content = extract_color(content)
          table.insert(nodes, new_node("Italic", nil,
            parse_inline(clean_content, base_offset + i + 1),
            {
              color = color,
              source_offset = { start = base_offset + i, end_pos = base_offset + j }
            }
          ))
          i = j + 1
          found = true
          break
        end
        content = content .. text:sub(j, j)
        j = j + 1
      end

      if not found then
        buffer = buffer .. marker
        i = i + 1
      end

    -- ========================================================================
    -- PRIORITY 7: SPAN ($:color:text$ or $text$)
    -- ========================================================================
    elseif char == "$" and not is_escaped(text, i) then
      flush_buffer()

      local j = i + 1
      local content = ""
      local found = false

      while j <= len do
        if text:sub(j, j) == "$" and not is_escaped(text, j) then
          local color, clean_content = extract_color(content)
          table.insert(nodes, new_node("Span", nil,
            parse_inline(clean_content, base_offset + i + 1),
            {
              color = color,
              source_offset = { start = base_offset + i, end_pos = base_offset + j }
            }
          ))
          i = j + 1
          found = true
          break
        end
        content = content .. text:sub(j, j)
        j = j + 1
      end

      if not found then
        buffer = buffer .. "$"
        i = i + 1
      end

    -- ========================================================================
    -- DEFAULT: Regular text
    -- ========================================================================
    else
      buffer = buffer .. char
      i = i + 1
    end

    ::continue::
  end

  flush_buffer()
  return nodes
end

-- ============================================================================
-- BLOCK PARSING - BLOCKQUOTES
-- ============================================================================

local function parse_blockquote(lines, start_idx, max_lines, source_text)
  local blockquotes = {}
  local i = start_idx

  while i <= max_lines do
    local line = lines[i]
    local blkm = line:match("^>+")
    local quote_level = blkm and #blkm or 0

    if quote_level == 0 then break end

    local content = line:match("^>+[%s]*(.-)$")
    local current_level = quote_level
    local blockquote = new_node("Blockquote", nil, {}, { level = current_level })
    local children = {}

    if content ~= "" then
      local offset = calculate_offset(lines, i, quote_level + 1)
      local pnode = new_node("Paragraph", nil, parse_inline(content, offset))
      pnode.parent_blockquote = blockquote
      table.insert(children, pnode)
    end

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
        local nested_result, new_i = parse_blockquote(lines, j, max_lines, source_text)
        for _, nested_blockquote in ipairs(nested_result) do
          table.insert(children, nested_blockquote)
        end
        j = new_i
      elseif next_level == current_level then
        local next_content = next_line:match("^>+[%s]*(.-)$")
        if next_content ~= "" then
          local offset = calculate_offset(lines, j, next_level + 1)
          local pnode = new_node("Paragraph", nil, parse_inline(next_content, offset))
          pnode.parent_blockquote = blockquote
          table.insert(children, pnode)
        end
        j = j + 1
      else
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

-- ============================================================================
-- BLOCK PARSING - LISTS
-- ============================================================================

local function parse_list(lines, start_idx, max_lines, base_indent, source_text)
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

    -- If no content, skip this line (malformed list item)
    if not content then
      break
    end

    local current_list = new_node(list_type, nil, {})
    local current_indent = indent
    local item_number = 1

    -- Calculate offset for first item
    local marker_end = line:find(content, 1, true)
    local offset = marker_end and calculate_offset(lines, i, marker_end - 1) or calculate_offset(lines, i, indent)
    local current_item = new_node("ListItem", nil, parse_inline(content, offset), { number = item_number })
    current_item.parent_list = current_list
    table.insert(current_list.children, current_item)
    i = i + 1

    while i <= max_lines do
      local next_line = lines[i]
      local next_blkm = next_line:match("^%s*")
      local next_indent = next_blkm and #next_blkm or 0
      local is_list_item = next_line:match(RX_UNORDERED_LIST) or next_line:match(RX_ORDERED_LIST)

      if next_indent >= current_indent + 2 and next_indent <= current_indent + 4 and is_list_item then
        local nested_lists, new_i = parse_list(lines, i, max_lines, current_indent + 2, source_text)
        for _, nested_list in ipairs(nested_lists) do
          table.insert(current_item.children, nested_list)
        end
        i = new_i
      elseif next_indent == current_indent and is_list_item then
        item_number = item_number + 1
        local next_content = next_line:match(RX_LINEITEM_CONTENT)
        local next_marker_end = next_line:find(next_content, 1, true)
        local next_offset = calculate_offset(lines, i, next_marker_end - 1)
        current_item = new_node("ListItem", nil, parse_inline(next_content, next_offset), { number = item_number })
        current_item.parent_list = current_list
        table.insert(current_list.children, current_item)
        i = i + 1
      else
        break
      end
    end

    table.insert(lists, current_list)
  end

  return lists, i
end

-- ============================================================================
-- MAIN PARSER
-- ============================================================================

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
      local parsed_headers = {}
      local headers_are_empty = true

      for j = 1, expected_columns do
        local header_content = table_headers[j] or ""
        table.insert(parsed_headers, header_content)
        if header_content ~= "" then headers_are_empty = false end
      end

      local parsed_rows = {}
      for row_idx, raw_row in ipairs(raw_rows) do
        local row = {}
        for j = 1, expected_columns do
          local cell_content = raw_row[j] or ""
          local offset = calculate_offset(lines, i - #raw_rows + row_idx - 1, 1)
          table.insert(row, parse_inline(cell_content, offset))
        end
        if #row > 0 then
          table.insert(parsed_rows, row)
        end
      end

      table.insert(ast.children, new_node("Table", nil,
        { headers = parsed_headers, rows = parsed_rows },
        { headers_are_empty = headers_are_empty }
      ))
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
        local offset = calculate_offset(lines, i, level + 1)
        table.insert(ast.children, new_node("Header", nil, parse_inline(content, offset), { level = level }))
      end
      i = i + 1
    -- Blockquote
    elseif trimmed_line:match(RX_BLOCKQUOTE) then
      finalize_table()
      local blockquotes, new_i = parse_blockquote(lines, i, #lines, markdown)
      for _, blockquote in ipairs(blockquotes) do
        table.insert(ast.children, blockquote)
      end
      i = new_i
    -- Lists
    elseif trimmed_line:match(RX_UNORDERED_LIST) or trimmed_line:match(RX_ORDERED_LIST) then
      finalize_table()
      local lists, new_i = parse_list(lines, i, #lines, 0, markdown)
      for _, list in ipairs(lists) do
        table.insert(ast.children, list)
      end
      -- If parse_list didn't advance (malformed list), skip this line
      if new_i == i then
        i = i + 1
      else
        i = new_i
      end
    -- Table
    elseif trimmed_line:match(RX_TABLE_LINE) then
      local cells = {}
      for cell in line:gmatch("[^|]+") do
        table.insert(cells, trim(cell))
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
    elseif trimmed_line:match(RX_SEPARATOR) then
      finalize_table()
      table.insert(ast.children, new_node("Separator"))
      i = i + 1
    elseif line == "" then
      finalize_table()
      i = i + 1
    else
      -- Paragraph
      finalize_table()
      local paragraph_lines = {}
      local j = i

      while j <= #lines do
        local check_line = lines[j]
        if check_line == "" or
           check_line:match(RX_SEPARATOR) or
           check_line:match(RX_CODEBLOCK) or
           check_line:match(RX_HEADER) or
           check_line:match(RX_BLOCKQUOTE) or
           check_line:match(RX_UNORDERED_LIST) or
           check_line:match(RX_ORDERED_LIST) or
           check_line:match(RX_TABLE_LINE) then
          break
        end
        table.insert(paragraph_lines, check_line)
        j = j + 1
      end

      if #paragraph_lines > 0 then
        local paragraph_nodes = {}
        for idx, pline in ipairs(paragraph_lines) do
          if idx > 1 then
            table.insert(paragraph_nodes, new_node("LineBreak"))
          end
          local offset = calculate_offset(lines, i + idx - 1, 0)
          for _, node in ipairs(parse_inline(pline, offset)) do
            table.insert(paragraph_nodes, node)
          end
        end
        table.insert(ast.children, new_node("Paragraph", nil, paragraph_nodes))
      end

      -- Failsafe: if we didn't advance, skip the problematic line
      if j == i then
        i = i + 1
      else
        i = j
      end
    end
  end

  finalize_table()
  return ast
end

return ParseMarkdown
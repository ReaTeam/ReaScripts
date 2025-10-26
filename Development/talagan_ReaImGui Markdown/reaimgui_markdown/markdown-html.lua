-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- HTML generation from AST

local function ASTToHtml(ast)
  local render_children = function(children, level) return "" end

  local function render_node(node, level)
    level = level or 1
    if node.type == "Document" then
      local html = ""
      for _, child in ipairs(node.children) do
        html = html .. render_node(child, level)
      end
      return html
    elseif node.type == "Header" then
      return "<h" .. node.attributes.level .. ">" .. render_children(node.children, level) .. "</h" .. node.attributes.level .. ">\n"
    elseif node.type == "Paragraph" then
      return "<p>" .. render_children(node.children, level) .. "</p>\n"
    elseif node.type == "Bold" then
      local style = node.attributes.color and ' style="color: ' .. node.attributes.color .. '"' or ""
      return "<strong" .. style .. ">" .. render_children(node.children, level) .. "</strong>"
    elseif node.type == "Italic" then
      local style = node.attributes.color and ' style="color: ' .. node.attributes.color .. '"' or ""
      return "<em" .. style .. ">" .. render_children(node.children, level) .. "</em>"
    elseif node.type == "Code" then
      local style = node.attributes.color and ' style="color: ' .. node.attributes.color .. '"' or ""
      return "<code" .. style .. ">" .. render_children(node.children, level) .. "</code>"
    elseif node.type == "Text" then
      return node.value
    elseif node.type == "Span" then
      local style = node.attributes.color and ' style="color: ' .. node.attributes.color .. '"' or ""
      return "<span" .. style .. ">" .. render_children(node.children, level) .. "</span>"
    elseif node.type == "Link" then
      return '<a href="' .. node.attributes.url .. '">' .. render_children(node.children, level) .. '</a>'
    elseif node.type == "Image" then
      return '<img src="' .. node.attributes.url .. '" alt="' .. node.attributes.alt .. '">'
    elseif node.type == "LineBreak" then
      return "<br>\n"
    elseif node.type == "Separator" then
      return "<hr>\n"
    elseif node.type == "UnorderedList" then
      local html = "<ul>\n"
      for _, child in ipairs(node.children) do
        html = html .. "<li>" .. render_children(child.children, level) .. "</li>\n"
      end
      return html .. "</ul>\n"
    elseif node.type == "OrderedList" then
      local list_type
      if level == 1 then
        list_type = "1"
      elseif level == 2 then
        list_type = "A"
      elseif level == 3 then
        list_type = "I"
      elseif level == 4 then
        list_type = "a"
      else
        list_type = "i"
      end
      local html = '<ol type="' .. list_type .. '">\n'
      for _, child in ipairs(node.children) do
        html = html .. "<li>" .. render_children(child.children, level + 1) .. "</li>\n"
      end
      return html .. "</ol>\n"
    elseif node.type == "ListItem" then
      local html = ""
      for _, child in ipairs(node.children) do
        html = html .. render_node(child, level)
      end
      return html
    elseif node.type == "Blockquote" then
      local html = "<blockquote>\n"
      html = html .. render_children(node.children, level) .. "</blockquote>\n"
      return html
    elseif node.type == "CodeBlock" then
      return "<pre><code>" .. node.value .. "</code></pre>\n"
    elseif node.type == "Table" then
      local html = "<table>\n"
      if node.children.headers and not node.attributes.headers_are_empty then
        html = html .. "<thead>\n<tr>\n"
        for _, header in ipairs(node.children.headers) do
          html = html .. "<th>" .. (header or "") .. "</th>\n"
        end
        html = html .. "</tr>\n</thead>\n"
      end
      html = html .. "<tbody>\n"
      for _, row in ipairs(node.children.rows) do
        html = html .. "<tr>\n"
        for _, cell in ipairs(row) do
          html = html .. "<td>" .. render_children(cell, level) .. "</td>\n"
        end
        html = html .. "</tr>\n"
      end
      return html .. "</tbody>\n</table>\n"
    elseif node.type == "Checkbox" then
      local html = ''
      html = html .. "<input type=\"checkbox\""
      if node.attributes.checked then
        html = html .. " checked"
      elseif node.attributes.partial then
        html = html .. " indeterminate"
      end

      html = html .. ">"
      return html
    else
      error("Unhandle type " .. node.type)
    end
    return ""
  end

  render_children = function(children, level)
    local html = ""
    for _, child in ipairs(children) do
      html = html .. render_node(child, level)
    end
    return html
  end

  return render_node(ast, 1)
end

return ASTToHtml

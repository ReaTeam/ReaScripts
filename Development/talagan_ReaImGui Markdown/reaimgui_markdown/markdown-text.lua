-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- Text generation from AST, this is for inspecting and debugging

local function render_node_inpect(obj, indent, visited, lines)
  indent = indent or 0
  visited = visited or {}
  lines = lines or {}

  local function add_line(str)
    table.insert(lines, string.rep("  ", indent) .. str)
  end

  local function format_value(val)
    if type(val) == "string" then
      return '"' .. val:gsub('"', '\\"') .. '"'
    elseif type(val) == "nil" then
      return "nil"
    elseif type(val) == "boolean" or type(val) == "number" then
      return tostring(val)
    else
      return "<" .. type(val) .. ">"
    end
  end

  if type(obj) == "table" then
    if visited[obj] then
      add_line("{ <cycle> }")
      return lines
    end
    visited[obj] = true

    if next(obj) == nil then
      add_line("{}")
      return lines
    end

    add_line("{")

    -- Inspect by key / value, gather numeric and str keys separately
    local num_keys = {}
    local str_keys = {}
    for k, _ in pairs(obj) do
      if type(k) == "number" then
        table.insert(num_keys, k)
      elseif type(k) == "string" then
        table.insert(str_keys, k)
      end
    end
    table.sort(num_keys, function(a, b) return a < b end)
    table.sort(str_keys)

    local non_tables = {}
    local sub_tables = {}

    for _, k in ipairs(num_keys) do
      if type(obj[k]) == "table" then
        table.insert(sub_tables, { key = k, is_number = true })
      else
        table.insert(non_tables, { key = k, is_number = true })
      end
    end

    for _, k in ipairs(str_keys) do
      if type(obj[k]) == "table" then
        table.insert(sub_tables, { key = k, is_number = false })
      else
        table.insert(non_tables, { key = k, is_number = false })
      end
    end

    for _, item in ipairs(non_tables) do
      local key_str = item.is_number and tostring(item.key) or item.key
      local formatted = format_value(obj[item.key])
      if formatted then
        add_line(key_str .. " = " .. formatted)
      end
    end

    for _, item in ipairs(sub_tables) do
      local key_str = item.is_number and tostring(item.key) or item.key
      add_line(key_str .. " = ")
      render_node_inpect(obj[item.key], indent + 1, visited, lines)
    end

    add_line("}")
  else
    local formatted = format_value(obj)
    if formatted then
      add_line(formatted)
    end
  end

  return table.concat(lines, "\n")
end

local function ASTInspect(obj, indent)
  return render_node_inpect(obj,indent,{},{})
end


local function ASTToPlainText(nodes)
  if not nodes then
    return ""
  end

  -- Single node
  if nodes.type then
    nodes = {nodes}
  end

  local result = {}

  local function traverse(node)
    if node.type == "Text" then
      table.insert(result, node.value)

    elseif node.type == "Image" then
      table.insert(result, node.attributes.alt or "")

    elseif node.type == "Checkbox" then
      if node.attributes.checked then
        table.insert(result, "[x]")
      elseif node.attributes.partial then
        table.insert(result, "[-]")
      else
        table.insert(result, "[ ]")
      end

    elseif node.children then
      for _, child in ipairs(node.children) do
        traverse(child)
      end
    end
  end

  for _, node in ipairs(nodes) do
    traverse(node)
  end

  return table.concat(result, "")
end


return {
  ASTInspect      = ASTInspect,
  ASTToPlainText  = ASTToPlainText
}

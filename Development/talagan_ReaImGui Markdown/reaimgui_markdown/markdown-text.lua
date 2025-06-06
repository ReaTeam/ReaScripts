-- @noindex
-- @author Ben Talagan Babut
-- @license MIT
-- @about This is a part of ReaImGui:Markdown

-- Text generation from AST, this is for inspecting and debugging

local function ASTToText(obj, indent, visited, lines)
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

    -- Vérifier si la table est vide
    if next(obj) == nil then
      add_line("{}")
      return lines
    end

    add_line("{")

    -- Collecter et trier les clés
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

    -- Traiter les clés numériques
    for _, k in ipairs(num_keys) do
      if type(obj[k]) == "table" then
        table.insert(sub_tables, { key = k, is_number = true })
      else
        table.insert(non_tables, { key = k, is_number = true })
      end
    end

    -- Traiter les clés chaînes
    for _, k in ipairs(str_keys) do
      if type(obj[k]) == "table" then
        table.insert(sub_tables, { key = k, is_number = false })
      else
        table.insert(non_tables, { key = k, is_number = false })
      end
    end

    -- Afficher les non-tables
    for _, item in ipairs(non_tables) do
      local key_str = item.is_number and tostring(item.key) or item.key
      local formatted = format_value(obj[item.key])
      if formatted then
        add_line(key_str .. " = " .. formatted)
      end
    end

    -- Afficher les sous-tables
    for _, item in ipairs(sub_tables) do
      local key_str = item.is_number and tostring(item.key) or item.key
      add_line(key_str .. " = ")
      ASTToText(obj[item.key], indent + 1, visited, lines)
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

return ASTToText

-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

-- Used to count checkboxes in a markdown text

local ParseMarkdown = require "reaimgui_markdown/markdown-ast"

local CheckboxHelper = {}

local function CountCheckboxes(nodes, counts)
  if not nodes then
    return
  end

  -- It's a single node
  if nodes.type then
    nodes = {nodes}
  end

  local function traverse(node)
    if node.type == "Text" then
    elseif node.type == "Image" then
    elseif node.type == "Checkbox" then
      if node.attributes.checked then
        counts.c = counts.c + 1
      end
      counts.t = counts.t + 1
    elseif node.children then
      for _, child in ipairs(node.children) do
        traverse(child)
      end
      -- For tables, children is a lookup not an array
      if node.children.rows then
        for _, row in ipairs(node.children.rows) do
          for _, cell in ipairs(row) do
            for _, cell_child in ipairs(cell) do
              traverse(cell_child)
            end
          end
        end
      end
    end
  end

  for _, node in ipairs(nodes) do
    traverse(node)
  end
end

CheckboxHelper.CountCheckboxes = function(markdown)
    local ast = ParseMarkdown(markdown)
    local counts = {c= 0, t=0}
    CountCheckboxes(ast, counts)
    return counts
end

return CheckboxHelper

--[[
 * ReaScript Name: RPP Parser
 * Author: mrlimbic, X-Raym, acendan
 * Link: ReaTeam/ReaScripts https://github.com/ReaTeam/ReaScripts
 * Licence: GPL v3
 * REAPER: 5.0
 * Version: 2.0
--]]

--[[
 * Changelog:
 * v2.0 (2020-02-22)
  + Initial Release
--]]

-----------------------------------------------------------
-- Utilities - Functions
-----------------------------------------------------------

-- Is the character a white space or a new line or a tab
local function IsWhiteSpace(c)
  return c == ' ' or c == '\t' or c == '\n'
end

-- remove trailing and leading whitespace from string.
local function Trim(s) -- from PiL2 20.4
  return s:gsub("^%s*(.-)%s*$", "%1")
end

-- Use this to determine if Node or Chunk now - not isTag
local function IsInstanceOf(subject, super)
  super = tostring(super)
  local mt = getmetatable(subject)

  while true do
    if mt == nil then return false end
    if tostring(mt) == super then return true end

    mt = getmetatable(mt)
  end
end

local function SplitMultilinesStrToTab(str)
  local t = {}
  local i = 0
  for line in str:gmatch("[^\n]*") do
      i = i + 1
      if line ~= "" then -- remove empty lines
        t[i] = line
      end
  end
  return t
end

-----------------------------------------------------------
------------------------------ End of Utilities - Functions
-----------------------------------------------------------

-----------------------------------------------------------
-- RToken - Meta-Class
-----------------------------------------------------------

RToken = { token = nil }

function RToken:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function RToken:getString()
  return self.token -- Not useful but consistent
end

function RToken:getNumber()
  return tonumber(self.token)
end

function RToken:getBoolean() -- in reaper terms boolean is a string "0" or "1"
  return self.token ~= "0"
end

function RToken:setString(token)
  self.token = tostring(token) -- We force string- yes always stored as string
end

function RToken:setNumber(token) -- NOTE: Maybe check for decimal numbers
  self.token = tostring(token)
end

function RToken:setBoolean(b)
  if b then self.token = "1" else self.token = "0" end
end

function RToken:toSafeString(s)
  -- check param contains no quotes
  -- if needs quotes then surround with correct quotes
  -- NOTE: if quotes are present but not needed, they will be deleted - why? Reaper surrounds with different type of quote in that instance i.e "MyQuoted" -> '"MyQuoted"'
  -- i.e. You may name your track "Scary" Noise -> '"Scary" Noise' -- it's weird but reaper does it - check in an RPP - You can use quotes in names - if a certain quote is present it uses an extra quote that isn't present
  if not s or s:len() == 0 then
    return "\"\"" -- Empty string must be quoted
  elseif s:find(" ") then
    -- We must quote in weird ways if has spaces
    if s:find("\"") then
      if s:find("'") then
        s = s:gsub("`", "'")
        return "`" .. s .. "`"
      else
        return "'" .. s .. "'"
      end
    else
      return "\"" .. s .. "\""
    end

  else      --
    return s -- param unchanged - no spaces or quotes required
  end
end

-----------------------------------------------------------
-------------------------------- End of RToken - Meta-Class
-----------------------------------------------------------

-----------------------------------------------------------
-- Tokenizer - Function
-----------------------------------------------------------

local function Tokenize(line)
  local index = 0
  local tokens = {}
  while index <= line:len() do

    local buff = ''
    local c = ''

    -- ignore white space
    while index <= line:len() do
      c = line:sub(index, index)
      if not IsWhiteSpace(c) then
        break
      end
      index = index + 1
    end

    -- Check if next character a quote
    c = line:sub(index, index)
    local quote = false
    local quoteChar = 0
    if c == '\'' or c == '"' or c == '`' then
      quote = true
      quoteChar = c
    else
      buff = buff .. c
    end
    index = index + 1

    -- read till quote or whitespace
    while index <= line:len() do

      c = line:sub(index, index)
      index = index + 1 -- fixed increment

      if quote then
        if c == quoteChar then
          break
        else
          buff = buff .. c
        end
      else
        if IsWhiteSpace(c) then
          break
        else
          buff = buff .. c
        end
      end

    end
    -- at this point buff is the next token
    table.insert(tokens, RToken:new{token = buff})
  end

  return tokens
end

-----------------------------------------------------------
------------------------------- End of Tokenizer - Function
-----------------------------------------------------------

-----------------------------------------------------------
-- RNode - Meta-Class
-----------------------------------------------------------

RNode = { parent = nil, line = nil}

function RNode:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  if o.parent then o.parent:addNode(o) end
  return o
end

function RNode:getTokens()
  if not self.tokens then
    -- Lazy load tokens if not already done
    self.tokens = Tokenize(self.line) -- now one line easier to read
  end
  return self.tokens -- it only exists if we query or modify a node - it override line -- the writer will want to use these if they exist
end

-- get a token if it exists otherwise nil
function RNode:getToken(index)
  local tokens = self:getTokens() -- Needs to be lazy loaded -- Tokens always exists
  return tokens[index] -- this will be nil if index doesn't exist
end

function RNode:getName()
  local token = self:getToken(1) -- Get first token of line
  return token:getString()
end

function RNode:getParam(index)
  return self:getToken(index + 1)
end

function RNode:getTokensAsLine()
  local tab = {}
  for i, token in ipairs( self:getTokens() ) do
    table.insert(tab, token:toSafeString(token:getString()))
  end
  return table.concat(tab, " ")
end

function RNode:remove()
  if self.parent then
    table.remove(self.parent.children, self.parent:indexOf(self))
  end
  self = nil
  return nil
end

-----------------------------------------------------------
--------------------------------- End of RNode - Meta-Class
-----------------------------------------------------------

-----------------------------------------------------------
-- RChunk - Child-Class
-----------------------------------------------------------

RChunk = RNode:new{}

function RChunk:findFirstNodeByName(name, start_index, end_index)
  if not self.children then return false end
  for i, child in ipairs(self.children) do
    if (not start_index or i >= start_index) and (not end_index or i <= end_index) then
      if child:getName() == name then
        return child
      end
    end
  end
end

function RChunk:findFirstChunkByName(name, start_index, end_index)
  for i, child in ipairs(self.children) do
    if (not start_index or i >= start_index) and (not end_index or i <= end_index) then
      if IsInstanceOf(child, RChunk) then
        if child:getName() == name then
          return child
        end
      end
    end
  end
  return false
end

function RChunk:findAllNodesByFilter(filter, start_index, end_index)
  local out = {}
  -- finds child tags that match the filter function
  for i, child in pairs(self.children) do
    if (not start_index or i >= start_index) and (not end_index or i <= end_index) then
      if filter(child) then -- This looks wrong - filter should check each child
        -- filter accepted this node so add to results
        table.insert(out, child)
      end
    end
  end
  return out
end

function RChunk:findAllChunksByFilter(filter, out, start_index, end_index) -- give this an empty table for out to fill when calling
  out = out or {}
  -- finds child tags that match the filter function
  for i, child in pairs(self.children) do
    if (not start_index or i >= start_index) and (not end_index or i <= end_index) then
      if IsInstanceOf(child, RChunk) then
        if filter(child) then -- This looks wrong - filter should check each child
          -- filter accepted this node so add to results
          table.insert(out, child)
        end
      end
    end
  end
  return out
end

function RChunk:findAllNodesByName(name, start_index, end_index)
  local filter = function(node)
    return node:getName() == name
  end
  return self:findAllNodesByFilter(filter, nil, start_index, end_index)
end

function RChunk:findAllChunksByName(name, start_index, end_index) -- find child chunk with specified name (non recursive)
  local filter = function(node)
    return node:getName() == name
  end
  return self:findAllChunksByFilter(filter, nil, start_index, end_index)
end

function RChunk:indexOf(node)
  for i, v in pairs(self.children) do
    if node == v then
      return i
    end
  end
  return false
end

function RChunk:getTextNotes()
  local tab = {}
  for i, child in ipairs(self.children) do
    tab[i] = child.line:sub(2) -- remove |
  end
  return table.concat( tab,"\n" )
end

function RChunk:setTextNotes(str)
  local tab = SplitMultilinesStrToTab(str)
  self.children = {} -- reset children
  for i, line in ipairs( tab ) do
    AddRNode(self, "|" .. line)
  end
  return self.children
end

function RChunk:addNode(node)
  if not self.children then self.children = {} end
  node.parent = self
  table.insert(self.children, node)
  return node
end

function RChunk:removeNode(node)
  for i, v in pairs(self.children) do
    if node == v then
      table.remove(self.children, node)
      node.parent = nil
      return true
    end
  end
  return false
end

function RChunk:StripGUID()
    -- Reset all GUID to let REAPER generates new ones
  local node_GUID = self:findFirstChunkByName("GUID")
  if node_GUID then node_GUID:remove() end
  local node_IGUID = self:findFirstChunkByName("IGUID")
  if node_IGUID then node_IGUID:remove() end
  local node_TRACKID = self:findFirstChunkByName("TRACKID")
  if node_TRACKID then node_TRACKID:remove() end
  -- TODO Support even more GUID types like markers
end

function RChunk:copy(parent)
  local chunk = ReadRPPChunk( StringifyRPPNode(self) )
  if not parent then parent = self.parent end
  return parent:addNode(chunk)
end
-----------------------------------------------------------
------------------------------- End of RChunk - Child-Class
-----------------------------------------------------------

-----------------------------------------------------------
-- ReadRPP - Functions
-----------------------------------------------------------

-- Read RPP file
function ReadRPP(filename)
  -- File check
  local file_found=io.open(filename, "r")
  if not file_found then
    return false, filename .. " ... Error - File Not Found"
  end

  local lines = {}
  local i = 1
  for line in io.lines (filename) do
    lines[i] = line
    i = i + 1
  end
  io.close(file_found)
  return ReadRPPChunk(lines)
end

-- Read a table of lines RPP
function ReadRPPChunk(input) -- Returns an RChunk with children
  local root = nil -- when it finds first chunk that is the root
  local chunk = nil -- we got a local chunk
  local parent = nil
  local lines = nil

  -- Prepare input lines as table
  if type(input) == "table" then
    lines = input
  else -- split input muliline str as table
    lines = SplitMultilinesStrToTab(input)
  end

  for i, line in ipairs(lines) do -- look
    line = Trim(line) -- ignore surrounding white space

    local first = line:sub(1, 1)
    -- Is this line a node or a chunk?
    if first == "<" then
      -- Open new chunk with current as parent
      chunk = RChunk:new{children = {}, parent = parent, line = line:sub(2)}

      parent = chunk
      if not root then
        root = chunk -- this root chunk should always end up being <PROJECT ...
      end

    elseif first == ">" then
      -- Close current chunk - back up a level to grand parent
      parent = parent.parent

    else
      -- If parent is null here then we don't have a root chunk so probably not a reaper project
      if not parent then
        return false, "Cannot add new node to nil parent" .. line
      end

      -- Anything else is a normal node line - add it to current parent
      local node = RNode:new{ parent = parent, line = line}

    end
  end
  return root
end

-----------------------------------------------------------
-------------------------------- End of ReadRPP - Functions
-----------------------------------------------------------

-----------------------------------------------------------
-- CreateRPP - Functions
-----------------------------------------------------------

-- Create a RPP from scratch.
-- You need to write it to file after you have added the chunk you want.
function CreateRPP(version, system, time) -- Extra parameter could be added
  if not version then version = "0.1" end
  if not system then system = "6.21/win64" end
  if not time then time = os.time() end
  return CreateRChunk({"REAPER_PROJECT", version, system, time})
end

function CreateRTokens(tab)
  local tokens = {}
  for i, str in ipairs(tab) do
    table.insert(tokens, RToken:new({token = tostring(str)}))
  end
  return tokens
end

function CreateRChunk(tab) -- Table of string
  return RChunk:new({tokens = CreateRTokens(tab)})
end

function CreateRNode(var) -- Table or String
  local node
  if type(var) == "table" then
    node = RNode:new({tokens = CreateRTokens(var)})
  else
    node = RNode:new({line = var})
  end
  return node
end

function AddRChunk(parent, tab)
  local chunk = CreateRChunk(tab)
  return parent:addNode(chunk)
end

function AddRNode(parent, tab)
  local node = CreateRNode(tab)
  return parent:addNode(node)
end

function AddRToken(node, tab)
  local tokens = CreateRToken(tab)
  node.tokens = tokens
  return tokens
end

-----------------------------------------------------------
------------------------------ End of CreateRPP - Functions
-----------------------------------------------------------

-----------------------------------------------------------
-- WriteRPP - Functions
-----------------------------------------------------------

-- Indentations table to save performance. 10 is limit, more should be not needed.
local indentations = {}
indentations[0] = ""
for i = 1, 10 do
  indentations[i] = indentations[i-1] .. "  "
end

-- Stringify a Chunk
function TableRPPNode(node, indent, tab)

  if not tab then tab = {} end
  if not indent then indent = 0 end

  table.insert(tab, indentations[indent] ) -- this must not write a new line

  if IsInstanceOf(node, RChunk) then
    table.insert(tab, "<") -- Open chunk
  end

  if node.tokens then
    table.insert(tab, node:getTokensAsLine())
  else
    -- No tokens so assume wasn't modified and use original line again
    table.insert(tab, node.line)
  end

  table.insert(tab, "\n")

  if IsInstanceOf(node, RChunk) then
    -- Write children
    if node.children then
      for i, child in ipairs(node.children) do
        TableRPPNode(child, indent + 1, tab)
      end
    end

    -- End chunk line
    table.insert(tab, indentations[indent] )
    table.insert(tab, ">\n")
  end

  return tab
end

function StringifyRPPNode(node)
  return table.concat(TableRPPNode(node))
end

--- Create write a .rpp from root node
function WriteRPP(filename, root)
  if not filename then
    return false, "No file name"
  end
  if not root then
    return false, "No chunk passed"
  end
  local str = StringifyRPPNode(root)
  local file = io.open(filename, "w")
  if file then
    file:write(str)
    file:close()
    return true
  else
    return false, "Writing to file failed\n" .. filename
  end
end

-----------------------------------------------------------
------------------------------- End of WriteRPP - Functions
-----------------------------------------------------------

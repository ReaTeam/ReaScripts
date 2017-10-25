-- @description amagalma_Find custom action or script name by its ID
-- @author amagalma
-- @version 1.0
-- @about
--   # Searches in your reaper-kb.ini file to find the action name of the provided ID

-------------------------------------------------------------------------------------

local reaper = reaper
local t = {}
local path = reaper.GetResourcePath()
local separ = string.match(reaper.GetOS(), "Win") and "\\" or "/"
local file = io.open (path .. separ .. "reaper-kb.ini")
for line in file:lines() do
  local words = {}
  for word in line:gmatch(".- ") do
    words[#words+1] = word
  end
  local id = words[4]:gsub('"', "")
  id = id:match("^%s*(.-)%s*$") -- strip spaces
  local rest = ""
  for i = #words, 5, -1 do
    rest = words[i] .. rest
  end
  local name = rest:match('".+"')
  t[id] = name
end
file:close()
local ok, id = reaper.GetUserInputs( "Find name of custom action/script by its Command ID", 1, "Enter Command ID: , extrawidth=120", "")
if ok then
  id = id:match("^%s*(.-)%s*$") -- strip spaces
  if id:find("_.+") then id = id:sub(2) end -- strip leading _
  if t[id] then
    local name = (t[id]:gsub('"', "")):match("^%s*(.-)%s*$")
    reaper.MB( name .. "\n(name copied to clipboard)", "Action name is:", 0 )
    reaper.CF_SetClipboard( name )
  else
    reaper.MB( "Could not find it!\n Either you have mistyped or this is a native/SWS action.", "Sorry! :(", 0 )
  end
end
reaper.defer(function () end )

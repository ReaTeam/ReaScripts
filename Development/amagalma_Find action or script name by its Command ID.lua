-- @description amagalma_Find action or script name by its Command ID
-- @author amagalma
-- @version 2.0
-- @about
--   # Returns the action/script name of the given ID
-- @changelog
--  # Uses new CF_GetCommandText function. No need to write action list into txt file any more.

-------------------------------------------------------------------------------------

local reaper = reaper

local function esc(s)
  local matches =
  {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
  }
  return (s:gsub(".", matches))
end

-------------------------------------------------------------------------------------
local ok, retval = reaper.GetUserInputs( "Find name of action/script by its Command ID", 2, "Enter Command ID: ,Section: (1:Main / 2:MIDI Editor),extrawidth=120", ",1" )
local command, section = string.match(esc(retval), "(.+),(.+)")
section = tonumber(section)
if ok and (section == 1 or section == 2) then
  local action = reaper.CF_GetCommandText( section, reaper.NamedCommandLookup( command ) )
  reaper.CF_SetClipboard( action )
  reaper.MB( action .. "\n\n(Text copied to clipboard)", "Action name is:", 0 )
end
reaper.defer(function () end )

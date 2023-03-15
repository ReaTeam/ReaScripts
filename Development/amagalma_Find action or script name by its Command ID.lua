-- @description Find action or script name by its Command ID
-- @author amagalma
-- @version 2.01
-- @changelog - Uses new kbd_getTextFromCmd API, if available
-- @donation https://www.paypal.me/amagalma
-- @link https://forum.cockos.com/showthread.php?t=197714
-- @about
--   # Returns the action/script name of the given ID


-------------------------------------------------------------------------------------

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
  local action
  if reaper.APIExists( "kbd_getTextFromCmd" ) then
    action = reaper.kbd_getTextFromCmd( reaper.NamedCommandLookup( command ), section == 1 and 0 or 32060 )
  else
    action = reaper.CF_GetCommandText( section, reaper.NamedCommandLookup( command ) )
  end
  if action ~= "" then
    reaper.CF_SetClipboard( action )
    reaper.MB( action .. "\n\n(Text copied to clipboard)", "Action name is:", 0 )
  else
    reaper.MB( action .. "Could not find the requested action in the requested section!", "Sorry...", 0 )
  end
end
reaper.defer(function () end )

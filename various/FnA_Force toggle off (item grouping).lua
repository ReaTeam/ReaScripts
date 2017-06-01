--[[
 * ReaScript Name: FnA_Force toggle off (item grouping).lua
 * Description: see title
 * Instructions: You can edit Command_ID string in quotes to force other Toggle actions from Action List.
 * Author: FnA
 * Licence: GPL v3
 * Forum Thread: somewhat indirectly: De-select last selected item
 * Forum Thread URI: http://forum.cockos.com/showthread.php?t=191368
 * REAPER: 5.40
 * Extensions: None unless you use on SWS toggles
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2017-05-26)
  + Initial Release
--]]

--Paste Command ID from action list between quotes:
local Command_ID = "1156"

---------------------------------------------------
local r = reaper

local x = tonumber(Command_ID)
if x then
  if r.GetToggleCommandState(x) == 1 then
    r.Main_OnCommand(x, 0)
  end
else
  local x = r.NamedCommandLookup(Command_ID)
  if r.GetToggleCommandState(x, 0) == 1 then
    r.Main_OnCommand(x, 0)
  end
end

function noundo() end
r.defer(noundo)

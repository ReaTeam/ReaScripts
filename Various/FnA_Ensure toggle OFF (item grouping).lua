-- Description: Ensure toggle OFF (item grouping)
-- Version: 1.0
-- Author: FnA
-- Changelog: Initial release
-- Link: Forum Thread (somewhat indirectly) http://forum.cockos.com/showthread.php?t=191368
-- About:
--   An example of a script which toggles a Toggle action (having an ON/OFF "State" in the Action List)
--   only if the action is ON, thus either setting it OFF, or leaving it OFF. Generally for use in custom actions.

-- User Variables ---------------------------------
-- Paste Command ID from Action List between quotes:
local Command_ID = "1156"
-- End of User Variables --------------------------

local r = reaper
local x = tonumber(Command_ID)
if x then -- REAPER factory actions
  if r.GetToggleCommandState(x) == 1 then
    r.Main_OnCommand(x, 0)
  end
else -- SWS actions
  local x = r.NamedCommandLookup(Command_ID)
  if r.GetToggleCommandState(x, 0) == 1 then
    r.Main_OnCommand(x, 0)
  end
end

function noundo() end
r.defer(noundo)

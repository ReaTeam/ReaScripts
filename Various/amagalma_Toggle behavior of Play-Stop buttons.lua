-- @description Toggle behavior of play/stop buttons
-- @author amagalma
-- @version 1.0
-- @about
--   # Toggles behavior of Play-Stop actions between amagalma's custom or Reaper's default
--
--   - To be used in conjunction with my "Transport (with memory - no undo)" scripts

-------------------------------------------------------------------------------------------

local reaper = reaper

local cmdID = reaper.NamedCommandLookup("_RS4b332fb0ea338b4991de7e2e9cd81032d79647da")
local script_state = reaper.GetToggleCommandStateEx(0,cmdID)

if script_state < 1 then 
  script_state = 1
else
  script_state = 0
end

reaper.SetToggleCommandState(0,cmdID, script_state)
reaper.RefreshToolbar2(0,cmdID)

-- No undo point
function NoUndoPoint() end reaper.defer(NoUndoPoint)

-- @description amagalma_Transport Play-Stop (with memory - no undo)
-- @author amagalma
-- @version 1.1
-- @about
--   # Plays or Stops and stores starting or ending position
--
--   - To be used in conjunction with my other "Transport (with memory - no undo)" scripts
--   - if "amagalma_Toggle behavior of Play-Stop buttons" is enabled then Stop leaves the cursor at last play cursor position
--   - if disabled then edit cursor stays at the start point (Reaper's default)

--[[
 Changelog:
 * v1.1 (2017-09-25)
  + when resuming play after pause, cursor position is saved in memory as new starting point
  + different behavior depending on "amagalma_Toggle behavior of Play-Stop buttons" state
--]]

--------------------------------------------------------------------------------------------

local reaper = reaper

function NoUndoPoint() end 

local playstate = reaper.GetPlayState()
if playstate > 0 then
  -- check "amagalma_Toggle behavior of Play-Stop buttons" state
  local cmdID = reaper.NamedCommandLookup("_RS4b332fb0ea338b4991de7e2e9cd81032d79647da")
  local script_state = reaper.GetToggleCommandStateEx(0,cmdID)
  if script_state == 1 then
    reaper.Main_OnCommand(40434, 0) --View: Move edit cursor to play cursor
    reaper.Main_OnCommand(1016, 0) --Transport: Stop
    local pos = reaper.GetCursorPosition()
    reaper.SetExtState("Play-Stop with memory", "Position2", tostring(pos), 0)
  else
    local pos =  reaper.GetPlayPosition()
    reaper.Main_OnCommand(1016, 0) --Transport: Stop
    reaper.SetExtState("Play-Stop with memory", "Position2", tostring(pos), 0)
  end
else
  local pos = reaper.GetCursorPosition()
  reaper.SetExtState("Play-Stop with memory", "Position", tostring(pos), 0)
  reaper.Main_OnCommand(1007, 0) -- Transport: Play
end
reaper.defer(NoUndoPoint)

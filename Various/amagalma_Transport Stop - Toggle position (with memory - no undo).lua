-- @description amagalma_Transport Stop - Toggle position (with memory - no undo)
-- @author amagalma
-- @version 1.1
-- @about
--   # Stops and toggles between starting and ending position.
--
--   - To be used in conjunction with my other "Transport (with memory - no undo)" scripts

--------------------------------------------------------------------------------------------

local reaper = reaper
local math = math

function NoUndoPoint() end

function round(num)
  return math.floor(num * 10^3 + 0.5) / 10^3
end

local playstate = reaper.GetPlayState()
if playstate > 0 then
  reaper.Main_OnCommand(40434, 0); --View: Move edit cursor to play cursor
  reaper.Main_OnCommand(1016, 0); --Transport: Stop
  local pos = reaper.GetCursorPosition()
  reaper.SetExtState("Play-Stop with memory", "Position2", tostring(pos), 0)
else
  local pos = reaper.GetCursorPosition()
  local HasState = reaper.HasExtState("Play-Stop with memory", "Position")
  local HasState2 = reaper.HasExtState("Play-Stop with memory", "Position2")
  if HasState2 and HasState then
    local pos1 = tonumber(reaper.GetExtState("Play-Stop with memory", "Position"))
    local pos2 = tonumber(reaper.GetExtState("Play-Stop with memory", "Position2"))
    if round(pos) == round(pos2) then reaper.SetEditCurPos(pos1, 1, 1 )
    elseif round(pos) == round(pos1) then reaper.SetEditCurPos(pos2, 1, 1 )
    end
  else
    reaper.SetExtState("Play-Stop with memory", "Position", tostring(pos), 0)
    reaper.SetExtState("Play-Stop with memory", "Position2", tostring(pos), 0)
  end
end
reaper.defer(NoUndoPoint)

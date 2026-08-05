-- @noindex

-- Global Variables --
cursorPos = reaper.GetCursorPosition(0);
ips = reaper.TimeMap_curFrameRate(0);
sMax = 1/ips;
----------------------------------------------------------------------------------
function MoveCursorOnRight()
  reaper.MoveEditCursor(sMax, 0);
end
----------------------------------------------------------------------------------
-- Action --
MoveCursorOnRight();

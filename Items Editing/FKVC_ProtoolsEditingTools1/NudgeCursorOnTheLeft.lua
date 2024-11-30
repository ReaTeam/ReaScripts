-- @noindex

-- Global Variables --
cursorPos = reaper.GetCursorPosition(0);
ips = reaper.TimeMap_curFrameRate(0);
sMax = -1/ips;
----------------------------------------------------------------------------------
function MoveCursorOnLeft()
  reaper.MoveEditCursor(sMax, 0);
end
----------------------------------------------------------------------------------
-- Action --
MoveCursorOnLeft();

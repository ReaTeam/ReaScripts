-- @noindex

-- Global variables --

item = reaper.GetSelectedMediaItem(0,0);
itemLength = reaper.GetMediaItemInfo_Value(item,"D_LENGTH");
itemPosition = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
cursorPosition = reaper.GetCursorPosition();
refreshUI = true;

----------------------------------------------------------------------
function Reverse()
  reaper.Main_OnCommand(41051,0);
end
----------------------------------------------------------------------
function Cut()

  local refrshUI = false;
  reaper.SetMediaItemLength(item, right, refreshUI);
end
----------------------------------------------------------------------
function MoveToCursor()

  reaper.SetMediaItemPosition(item, cursorPosition, refreshUI);
end
----------------------------------------------------------------------
function Operations()
  itemEnd = itemPosition + itemLength;
  right = itemEnd - cursorPosition;
end
----------------------------------------------------------------------
-- Main Function --

function CutLeft()

  reaper.Undo_BeginBlock()
  Operations();
  Reverse();
  Cut();
  Reverse();
  MoveToCursor();
  reaper.Undo_EndBlock("Cut Left",0)
end
----------------------------------------------------------------------
-- Action --

CutLeft();

-- @noindex

-- Global variables --

item = reaper.GetSelectedMediaItem(0,0);
itemPosition = reaper.GetMediaItemInfo_Value(item,"D_POSITION");
cursorPosition = reaper.GetCursorPosition();
refreshUI = true;

----------------------------------------------------------------------------------------------------------------------
function Operations()

  itemStart = itemPosition;
  left = cursorPosition - itemStart;

end

function Cut()

  local refrshUI = false;
  reaper.SetMediaItemLength(item, left, refreshUI); -- resize the item to the length of "left" by cutting "right".

end
----------------------------------------------------------------------------------------------------------------------
-- Main Function --

function CutRight()

  Operations();
  Cut();

end

----------------------------------------------------------------------------------------------------------------------
-- Action --

CutRight();

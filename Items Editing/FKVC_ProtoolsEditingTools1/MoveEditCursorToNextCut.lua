-- @noindex

-- Global Variables --

cursorPos = reaper.GetCursorPosition(0);
currentTrack = reaper.GetSelectedTrack(0,0);

i = 0;
t = 0;

iMax = reaper.CountTrackMediaItems(currentTrack);
iLast = iMax - 1;

----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToStartOfFirstItem()

  reaper.SetEditCurPos(firstItemStart, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToStartOfItem()

  reaper.SetEditCurPos(nextItemStart, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToEndOfItem()

  reaper.SetEditCurPos(iEnd, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToEndOfLastItem()

  reaper.SetEditCurPos(lastItemEnd, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function SelectNextItem()

  reaper.SetMediaItemSelected(nextItem, 1);

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function SelectFirstItem()

  reaper.SetMediaItemSelected(firstItem, 1);

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function UnselectAllItems()

  reaper.SelectAllMediaItems(0,0);

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveEditCursorToNextCut()

  if iMax == 0
  then return
  end

  for i = 0, iMax do

    firstItem = reaper.GetTrackMediaItem(currentTrack,0)
    firstItemStart = reaper.GetMediaItemInfo_Value(firstItem, "D_POSITION")

    if cursorPos < firstItemStart

      then

        MoveCursorToStartOfFirstItem()
        SelectFirstItem()

      else

        currentItem = reaper.GetTrackMediaItem(currentTrack,i);
        iStart = reaper.GetMediaItemInfo_Value(currentItem,"D_POSITION");
        iLength = reaper.GetMediaItemInfo_Value(currentItem,"D_LENGTH");
        iEnd = iStart + iLength;

        n = i + 1;
        nextItem = reaper.GetTrackMediaItem(currentTrack,n);

        if n ~= iMax
          then nextItemStart = reaper.GetMediaItemInfo_Value(nextItem,"D_POSITION");
        end

        lastItem = reaper.GetTrackMediaItem(currentTrack,iLast);
        lastItemStart = reaper.GetMediaItemInfo_Value(lastItem,"D_POSITION");
        lastItemLength = reaper.GetMediaItemInfo_Value(lastItem,"D_LENGTH");
        lastItemEnd = lastItemStart + lastItemLength;

        if cursorPos >= iStart and cursorPos < iEnd
          then
            if nextItemStart == iEnd
              then
                UnselectAllItems();
                SelectNextItem();
                MoveCursorToEndOfItem();
                break
              else
                MoveCursorToEndOfItem();
                break
            end
        end

        if iMax > 1
          then
            if cursorPos < nextItemStart and cursorPos >= iEnd
              then
                UnselectAllItems();
                SelectNextItem();
                MoveCursorToStartOfItem();
                SelectNextItem();
                break
              end
          else return
        end

        if cursorPos >= lastItemEnd
          then break
        end

    end

  end

end

----------------------------------------------------------------------------------------------------------------------------------------------------
-- Action --
MoveEditCursorToNextCut();


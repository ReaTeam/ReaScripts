-- @noindex

-- Global Variables --

cursorPos = reaper.GetCursorPosition(0);
currentTrack = reaper.GetSelectedTrack(0,0);

i = 0;
t = 0;

iMax = reaper.CountTrackMediaItems(currentTrack);
iLast = iMax-1;

----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToStartOfFirstItem()

  reaper.SetEditCurPos(firstItemStart, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToStartOfItem()

  reaper.SetEditCurPos(iStart, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToEndOfPreviousItem()

  reaper.SetEditCurPos(previousItemEnd, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function MoveCursorToEndOfLastItem()

  reaper.SetEditCurPos(lastItemEnd, moveview == true, seekplay == true)

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function SelectPreviousItem()

    reaper.SetMediaItemSelected(previousItem, 1);

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function SelectLastItem()

  reaper.SetMediaItemSelected(lastItem, 1);

end
----------------------------------------------------------------------------------------------------------------------------------------------------
function UnselectAllItems()

  reaper.SelectAllMediaItems(0,0);

end
----------------------------------------------------------------------------------------------------------------------------------------------------
-- Main Function --

function MoveEditCursorToNextCut()

  if iMax == 0
  then return
  end

  for i = 0, iLast do

    firstItem = reaper.GetTrackMediaItem(currentTrack,0)
    firstItemStart = reaper.GetMediaItemInfo_Value(firstItem, "D_POSITION")

    if cursorPos <= firstItemStart

      then break

      else if cursorPos > firstItemStart

            then

              currentItem = reaper.GetTrackMediaItem(currentTrack,i);
              iStart = reaper.GetMediaItemInfo_Value(currentItem,"D_POSITION");
              iLength = reaper.GetMediaItemInfo_Value(currentItem,"D_LENGTH");
              iEnd = iStart + iLength;

              p = i-1;
              previousItem = reaper.GetTrackMediaItem(currentTrack,p);

              if p ~= -1
                then
                  previousItemStart = reaper.GetMediaItemInfo_Value(previousItem,"D_POSITION");
                  previousItemLength = reaper.GetMediaItemInfo_Value(previousItem,"D_LENGTH");
                  previousItemEnd = previousItemStart + previousItemLength;
                else previousItem = firstItem;
              end

              lastItem = reaper.GetTrackMediaItem(currentTrack,iLast);
              lastItemStart = reaper.GetMediaItemInfo_Value(lastItem,"D_POSITION");
              lastItemLength = reaper.GetMediaItemInfo_Value(lastItem,"D_LENGTH");
              lastItemEnd = lastItemStart + lastItemLength;

              if cursorPos > iStart and cursorPos <= iEnd
                then
                  if iStart == previousItemEnd
                    then
                      UnselectAllItems();
                      SelectPreviousItem();
                      MoveCursorToStartOfItem();
                      break
                    else
                      MoveCursorToStartOfItem();
                      break
                  end
              end

              if cursorPos <= iStart and cursorPos > previousItemEnd
                then
                  UnselectAllItems();
                  SelectPreviousItem();
                  MoveCursorToEndOfPreviousItem();
                  break
              end

              if cursorPos > lastItemEnd
                then
                  MoveCursorToEndOfLastItem()
                  SelectLastItem()
              end
          end
    end
  end
end

----------------------------------------------------------------------------------------------------------------------------------------------------
-- Action --

MoveEditCursorToNextCut();

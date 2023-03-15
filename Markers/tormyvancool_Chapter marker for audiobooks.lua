-- @description Chapter marker for audiobooks (ID3 Metatag "CHAP=Chapter_Title")
-- @author Tormy Van Cool
-- @version 1.0
-- @screenshot Example: ChapterMarker.lua in action https://i.imgur.com/aEZhqwv.gif
-- @about
--   # Chapter Marker for Audiobooks
--
--   It adds  ID3 Metatag "CHAP=Chapter_Title_by_the_User" by a pop up that asks to the user, the title of each chapter.
--   Then it adds the marker with the correct tag at the mouse position
--
--   Key features:
--   - Asks for the title of each chapter by a pop up field
--   - It can be used very effectively as Armed Action
--   - It add the prefix "CHAP=" to any title inserted by the user, avoiding sintaxis errors
--   - When metadata is used, rendering an MP3, "CHAP=" is automatically added

retval, InputString=reaper.GetUserInputs("Name", 1, "Chapter Title", "")
if retval==false then return end
InputString=InputString:upper()
reaper.Undo_BeginBlock()
local name = "CHAP="..InputString
local color = reaper.ColorToNative(180,60,50)|0x1000000
local _, num_markers, _ = reaper.CountProjectMarkers(0)
local cursor_pos = reaper.GetCursorPosition()
reaper.AddProjectMarker2(0, 0, cursor_pos, 0, name, num_markers+1, color)
reaper.Undo_EndBlock("Insert marker", -1)

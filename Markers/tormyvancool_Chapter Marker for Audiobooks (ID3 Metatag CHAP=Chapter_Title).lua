-- @description Chapter Marker for Audiobooks (ID3 Metatag "CHAP=Chapter_Title")
-- @author Tormy Van Cool
-- @version 1.1
-- @changelog
--   Horizontally enhanced text fields for better visibility
--   Creation of  an "append"-type "PROJECT_NAME.AudioBookSideCar.txt" file into the Project Folder containing:
--   - Start of the chapter from the beginning of the AudioBook file, in hh:mm:ss format
--   - Chapters titles
--   Better renamed the Main Window
--   Better renamed the Undo action
-- @screenshot Example: ChapterMarker.lua in action https://i.imgur.com/omZPwan.gif
-- @about
--   #Chapter Marker for Audiobooks
--
--   It adds ID3 Metatag "CHAP=Chapter_Title_by_the_User" by a pop up that asks to the user, the title of each chapter. Then it adds the marker with the correct tag at the mouse position
--
--   Key features:
--   - Asks for the title of each chapter by a pop up field
--   - It can be used very effectively as Armed Action
--   - It add the prefix "CHAP=" to any title inserted by the user, avoiding sintaxis errors
--   - When metadata is used, rendering an MP3, "CHAP=" is automatically added
--   - It creates a "PROJECT_NAME" AudioBook SideCar file (append TXT type) in the project folder, containing time references in hh:mm:ss format and chapters' title separated by a pipe character "|"

-- Made by Tormy Van Cool (BR) Feb 01 2021
retval, InputString=reaper.GetUserInputs("AUDIOBOOK: CHAPTERS", 1, "Chapter Title,extrawidth=400", "")
if retval==false then return end
InputString=InputString:upper()
reaper.Undo_BeginBlock()
local name = "CHAP="..InputString
local color = reaper.ColorToNative(180,60,50)|0x1000000
local _, num_markers, _ = reaper.CountProjectMarkers(0)
local cursor_pos = reaper.GetCursorPosition()
reaper.AddProjectMarker2(0, 0, cursor_pos, 0, name, num_markers+1, color)
reaper.Undo_EndBlock("AUDIOBOOK Insert marker", -1)

local pj_name=reaper.GetProjectName(0, "")
local pj_path = reaper.GetProjectPathEx(0 , '' ):gsub("(.*)\\.*$","%1")
pj_name = string.gsub(string.gsub(pj_name, ".rpp", ""), ".RPP", "")..'.AudioBookSideCar.txt'

function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
end

cursor_pos = SecondsToClock(cursor_pos)
SideCar = io.open(pj_path..'\\'..pj_name, "a")
SideCar_ = cursor_pos..'|'..InputString
SideCar:write( SideCar_.."\n" )
SideCar:close()

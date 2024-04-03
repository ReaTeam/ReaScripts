-- @description Chapter marker for audiobooks (ID3 Metatag "CHAP=Chapter_Title")
-- @author Tormy Van Cool
-- @version 2.3
-- @screenshot Example: ChapterMarker.lua in action https://github.com/tormyvancool/TormyVanCool_ReaPack_Scripts/ChapterMarker.gif
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
-- ver. 1.0 Made by Tormy Van Cool (BR) Feb 01 2021
--------------------------------------------------------------------
-- Script Initialization
--------------------------------------------------------------------
reaper.Undo_BeginBlock()
chap = "CHAP="
pipe = "|"
LF = "\n"
extension = ".txt"
UltraschallLua = "/UserPlugins/ultraschall_api.lua"

--------------------------------------------------------------------
-- Functions declaration
--------------------------------------------------------------------
function file_exists(name) -- Checks if mandatory library is installed
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function ChapRid(chappy, seed, subs) -- Get rid of the "CHAP=" ID3 Tag or other stuff to prevent any error by user
  local ridchap
  if subs == nil then subs = "" end
  if chappy == nil then return end
  ridchap = string.gsub (chappy, seed,  subs)
  return ridchap
end

function SecondsToClock(seconds) -- Turns seconds into the format: "hh:mm:ss"
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

function Round(seed, precision)
  local roundup = math.floor(seed * precision) / precision
  return roundup
end

--------------------------------------------------------------------
-- Loads the mandatory library
--------------------------------------------------------------------
if file_exists(reaper.GetResourcePath().."/UserPlugins/ultraschall_api.lua") == false then 
    local v = [[
              ULTRASCHALL Library should be installed.
              Copy the follwing link
            
              https://github.com/Ultraschall/ultraschall-lua-api-for-reaper/raw/master/ultraschall_api_index.xml
             
              into:
            
              Extensions > ReaPack > Import repositories...
            
              install it and activate it by runinng:
            
              Actions > Script: ultraschall_Add_Developertools_To_Reaper.lua > Run/Close
              ]]
  
    reaper.MB(v,'ATTENTION',0)
    return
  else
    dofile(reaper.GetResourcePath()..UltraschallLua)
end


--------------------------------------------------------------------
-- Checks whehether the project is saved
--------------------------------------------------------------------
ProjectName = reaper.GetProjectName( 0, "" )
if ProjectName == "" then 
  reaper.MB("Save the Project, first!",'WARNING',0)
  return
end


--------------------------------------------------------------------
-- Get the marker position, extract the ID, POSITION and NAME
-- it assign these to a more human readable variables
-- If "markerNAME" is nil, then it assigns a null string
-- to prevent errors
--------------------------------------------------------------------
marker = ultraschall.GetMarkerByTime(reaper.GetCursorPosition(0))
function Split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end
markerData = Split(marker, LF)
markerID = markerData[1]
markerPOS = markerData[2]
markerNAME = markerData[3]
if markerNAME == nil then 
    markerNAME = ""
    flag = false
  else
    flag = true
end



--------------------------------------------------------------------
-- Asks to user to insert the chapter title
-- In case it's already present, the user can easily modify it
-- if not present, thus it's a new marker, the field is just empty
-- and the user shoudl fill it in
-- The field is mandatory
--------------------------------------------------------------------
if string.match(ChapRid( markerNAME, chap), pipe..'(.*)') == nil then
  InputVariable = ChapRid( markerNAME, chap)
else
  InputVariable = string.match(ChapRid( markerNAME, chap), pipe..'(.*)') 
end

repeat
  retval, InputString=reaper.GetUserInputs("AUDIOBOOK: CHAPTERS", 1, "Chapter Title,extrawidth=400", InputVariable)
  if InputString == "" then
   if reaper.MB("The field is empty!", "WARNING",5) == 2 then return end
  end
until InputString ~= ""

if retval==false then return end
InputString = ChapRid(ChapRid(ChapRid(InputString, chap), pipe), '-', ' ') -- No reserved characters can be written
InputString=InputString:upper() -- all letters turned in capitals


--------------------------------------------------------------------
-- Marker and related variable, construction
--------------------------------------------------------------------
local color = reaper.ColorToNative(180,60,50)|0x1000000
local _, num_markers, _ = reaper.CountProjectMarkers(0)
local cursor_pos = reaper.GetCursorPosition()
local roundup = Round(cursor_pos,100)
local name = chap..roundup..pipe..InputString
local tagName = chap..InputString
if flag == false then
  reaper.AddProjectMarker2(0, 0, cursor_pos, 0, tagName, num_markers+1, color)
  else
  reaper.DeleteProjectMarker(0, markerID, 0)
  reaper.AddProjectMarker2(0, 0, cursor_pos, 0, tagName, markerID, color)
end

local pj_name=reaper.GetProjectName(0, "")
local pj_path = reaper.GetProjectPathEx(0 , '' ):gsub("(.*)\\.*$","%1")
pj_name = string.gsub(string.gsub(pj_name, ".rpp", ""), ".RPP", "")..extension


cursor_pos = SecondsToClock(cursor_pos)
SideCar = io.open(pj_path..'\\'..pj_name, "w")


--------------------------------------------------------------------
-- Estabilshes how many markers/regions are located into the project
--------------------------------------------------------------------
numMarkers = 0

repeat
  mkr = reaper.EnumProjectMarkers(numMarkers)
  numMarkers = numMarkers+1
until mkr == 0

i = 0

while i < numMarkers-1 do
  local ret, isrgn, pos, rgnend, OldName, markrgnindexnumber = reaper.EnumProjectMarkers(i)
  if string.match(OldName, chap) then
   --local SideCar_ = SecondsToClock(pos)..pipe..ChapRid(name, chap)..LF
   local SideCar_ = ChapRid(OldName, chap)
   SideCar_ = ChapRid(Round(pos,10)..pipe..SideCar_, pipe, ',1,"')..'"'..LF
   SideCar:write( SideCar_ )
  end
  i = i+1
end

--------------------------------------------------------------------
-- Closes file and returns feedback to user
--------------------------------------------------------------------
SideCar:close()

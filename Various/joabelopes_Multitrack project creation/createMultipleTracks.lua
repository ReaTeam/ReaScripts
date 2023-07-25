-- @noindex

--[[
# DESCRIPTION

Script to create and color multiple tracks at once, based on the text file "tracks.txt", created by the user.

The structure is simple: UPPERCASE names will be the track folders,
and the lowercases will be the elements of the folder.

The file name must to be "tracks.txt", and the content should be like this:

FOLDER_NAME
element_name
element_name

ANOTHER_FOLDER_NAME
  another_element_name
    another_element_name


All the spaces will be "removed" internally on the script, so identation doesn't matter.

Put the text file in your project folder, or in the Reaper default project folder (to work on new unsaved projects). 
Example:
C:\User\Documents\REAPER Media\


* Author: Joabe Lopes
* Github repo: https://github.com/joabeslopes/Reaper-scripts-multitrack-creation/
* Licence: GPL v3
* Extensions required: None
]]


-- split a big string into an array of strings, separated by the line breaks
function splitString(bigString)
  local stringArray = {}
  for str in string.gmatch(bigString, "[^\n]+") do
    table.insert(stringArray, str)
  end
  return stringArray
end

-- get the tracks.txt file inside the project folder
function getTracksFileProject()
  local path = reaper.GetProjectPath()
  if string.find(path, "^/.*") then -- probably Unix OS (Linux or MacOS)

    folder = io.popen('ls "'..path..'"', 'r'):read('*all')
    folderItems = splitString(folder)
    for f=1, #folderItems do
      if string.find(folderItems[f], "tracks%ptxt") then
        tracksTextfile = path.."/tracks.txt"
        return tracksTextfile
      end
    end

  elseif string.find(path, "^%u:.*") then -- probably Windows OS

    folder = io.popen('dir /b "'..path..'"', 'r'):read('*all')
    folderItems = splitString(folder)
    for f=1, #folderItems do
      if string.find(folderItems[f], "tracks%ptxt") then
        tracksTextfile = path.."\\tracks.txt"
        return tracksTextfile
      end
    end
  end

end

-- get the tracks.txt file inside the folder of this script
function getTracksFileScript()
  local path = debug.getinfo(2, "S").source:sub(2):match(".*[/\\]")
  if string.find(path, "^/.*") then -- probably Unix OS (Linux or MacOS)

    folder = io.popen('ls "'..path..'"', 'r'):read('*all')
    folderItems = splitString(folder)
    for f=1, #folderItems do
      if string.find(folderItems[f], "tracks%ptxt") then
        tracksTextfile = path.."tracks.txt"
        return tracksTextfile
      end
    end

  elseif string.find(path, "^%u:.*") then -- probably Windows OS

    folder = io.popen('dir /b "'..path..'"', 'r'):read('*all')
    folderItems = splitString(folder)
    for f=1, #folderItems do
      if string.find(folderItems[f], "tracks%ptxt") then
        tracksTextfile = path.."tracks.txt"
        return tracksTextfile
      end
    end
  end
  
end

-- read the content of the text file
function openTextFile(filePath)
  local fileContent = {}

    file = io.open(filePath, 'r'):read('*all')
    fileContent = splitString(file)
    io.open(filePath, 'r'):close()
    return fileContent

end


---------------------- Main function ----------------------

allTracks = nil

-- open the file
if getTracksFileProject() then
  allTracks = openTextFile(getTracksFileProject())
elseif getTracksFileScript() then
  allTracks = openTextFile(getTracksFileScript())
end

if allTracks then
  -- delete all the spaces
  for i = 1, #allTracks do
  if string.find(allTracks[i],"^%s*") then
    allTracks[i] = string.gsub(allTracks[i],"%s","")
  end
  end

  -- create all tracks and color them
  for i = 1, #allTracks do

  --create the tracks
  reaper.InsertTrackAtIndex(i-1, true)
  track = reaper.GetTrack(0,i-1)
  trackName = allTracks[i]
  reaper.GetSetMediaTrackInfo_String(track, "P_NAME", trackName, true)

  --color the folder tracks
  if string.find(trackName,"^%L") then
    for n = 100, math.random(150,200) do
          math.randomseed(os.time()..n..n)
          math.random(); math.random();
          r = math.random(0,255)
          g = math.random(0,255)
          b = math.random(0,255)
        end
        color = reaper.ColorToNative(r,g,b)
        reaper.SetTrackColor(track, color)
  end
  end

else
    reaper.ShowConsoleMsg("File \"tracks.txt\" not found.\nPlease create it on the project folder, or on the scripts folder")
end

-- @description Import UVR or X-Minus separations into comping lane structure
-- @author Kadda OK
-- @version 0.2
-- @changelog
--    - Now includes files in folders below the original FLAC's path as well as beside it.
--    - Item name parsing now compatible with stems downloaded from X-Minus
--    - Friendly item name for Mel-Roformer model from May 2024 UVR patch
-- @screenshot https://i.imgur.com/Boqw2CP.png
-- @about
--   # Import UVR Separations Into Comping Lanes
--
--   This script sets up for comping instrumental and/or vocal stems separated using Ultimate Vocal Remover or X-Minus (with the intent of mastering an instrumental & background-vocal version for use in karaoke, but could probably be useful in other scenarios as well). 
--
--   It is recommended to be bound to a toolbar button.
--
--   The script prompts for the .FLAC file of the original recording. 
--   It assumes that: 
--    - The separated stems are present as .FLAC files either beside that file in the same folder or in subfolders below that folder, and that 
--    - Their filenames contain their model names, in whatever parts are neither the original's name nor a parenthesized description of which stem they are. 
--      (In UVR, this is achieved by checking the `Model Test Mode` checkbox).
--
--   It considers any filenames containing `(Vocals)` to be vocal stems, and any containing `(*Instrumental*)` to be instrumental stems, with the exception of any that also have the string `(Vocals)` earlier in the filename, which it interprets as likely being a two-step separation to obtain only background vocals on their own stem.
--
--   It creates three tracks:
--    - An `Original` track, with the original file on it, which is muted. This is for reference.
--    - An `Instruments` track, with each `(Instrumental)` file on it in its own fixed lane for comping. 
--    - A `Vocals` track, with each `(Vocals)` file or `(Vocals)...(Instrumental)` file on it in its own fixed lane for comping.
--
--   Each item is given the name of the model as found in its filename, with the exception of `"Original"`, and any vocals-instrumental files which are named `"bgv only ({model names})"`.  (But I also cleaned up the names of some models I frequently use to be more pleasant though; YMMV.)
--
--   If you execute the script again, it will not prompt you for the original file again, but will instead use the `"Original"` item on the `"Original"` track, and should only add new lanes for any additional files that have been created since without disrupting any that are already present.
--
--   Colors are auto-assigned via a random seed based on the model name, so that the color of a given instrumental track will match the color of its corresponding vocal track.

debug = false -- enable or disable diagnostic messages to the console

-- Utility functions
function escapePattern(pattern)
    return pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

function concatenateTables(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function generateColorValues(inputString, offset)
    offset = offset or 0 -- Default offset is 0 if not provided
    
    local sum = 0
    for i = 1, #inputString do
        sum = sum + inputString:byte(i)
    end
    
    local seed = (sum + offset) % 256
    math.randomseed(seed)
    
    local r = math.random(0, 255)
    local g = math.random(0, 255)
    local b = math.random(0, 255)
    
    return r, g, b
end

-- Track and item manipulation functions
function findTrack(name)
    -- Iterate over all existing tracks
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        -- If a track with the same name is found, return it
        if trackName == name then
            return track
        end
    end
    -- If no track with the same name is found, return nil
    return nil
end

function createTrack(name, count, mute)
    local trackIdx = reaper.CountTracks(0) -- Get the index for the next track
    reaper.InsertTrackAtIndex(trackIdx, true)
    local track = reaper.GetTrack(0, trackIdx)
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
    if count > 1 then 
        reaper.SetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES", count)
        reaper.SetMediaTrackInfo_Value(track, "I_FREEMODE", 2)
        reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:0", 1)
    end
    if mute then reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1) end
    return track
end

function addItemToTrack(track, file, name, lane, position)
  if debug then 
    reaper.ShowConsoleMsg("AddItemToTrack: " .. name .. ", " .. lane .. "\n") 
  end
  -- Iterate over all items on the track
  for i = 0, reaper.CountTrackMediaItems(track) - 1 do
    local item = reaper.GetTrackMediaItem(track, i)
    local take = reaper.GetMediaItemTake(item, 0)
    local source = reaper.GetMediaItemTake_Source(take)
    local sourceFile = reaper.GetMediaSourceFileName(source, "")
    -- If an item with the same source file is found, return without adding a new item
    if sourceFile == file then
        if debug then 
          reaper.ShowConsoleMsg("  " .. name .. " exists at position " .. i .. "\n") 
        end
      return false
    end
  end

    -- If no item with the same source file is found, find the first empty lane
  local emptyLaneFound = false
  while not emptyLaneFound do
    local laneHasItems = false
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
      local item = reaper.GetTrackMediaItem(track, i)
      local itemLane = reaper.GetMediaItemInfo_Value(item, "I_FIXEDLANE")
      if itemLane == lane then
        laneHasItems = true
        break
      end
    end
    if laneHasItems then
      lane = lane + 1
    else
      emptyLaneFound = true
    end
  end
  
  -- Add the item to the track
  local item = reaper.AddMediaItemToTrack(track)

  -- put it in the right lane, but only if there are multiple lanes 
  -- (otherwise, single-lane tracks switch to lane mode when you set their only item's lane to 0)
  local numFixedLanes = reaper.GetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES")
  if lane > 0 or numFixedLanes > 1 then
    reaper.SetMediaItemInfo_Value(item, "I_FIXEDLANE", lane)
  end

  local take = reaper.AddTakeToMediaItem(item)
  local source = reaper.PCM_Source_CreateFromFile(file)
  local length, isQN = reaper.GetMediaSourceLength(source)

  if isQN then
    local posQN = reaper.TimeMap2_timeToQN(nil, position)
    length = reaper.TimeMap2_QNToTime(nil, posQN + length) - position
  end
  
  if name == nil then name = file end
  reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", name, true)

  reaper.SetMediaItemTake_Source(take, source)
  reaper.SetMediaItemInfo_Value(item, 'D_POSITION', position)
  reaper.SetMediaItemInfo_Value(item, 'D_LENGTH', length)
  if name ~= "Original" then
    local r, g, b = generateColorValues(name, 70) -- this number chosen by experimentation. sorry if the colors suck for you
    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", reaper.ColorToNative(r,g,b)|0x1000000)
  end
  reaper.UpdateArrange()
  return true
end

function importFiles(files, track)
    local addedFiles = {}
    for index, file in ipairs(files) do
        local wasAdded = addItemToTrack(track, file[1], file[2], index-1, 0)
        if wasAdded then
            table.insert(addedFiles, file[2])
        end
    end
    return addedFiles
end

-- File and path manipulation functions
function getModelNameLabelFromFile(pathToOriginalFile, fullPath)
    local processed = fullPath
    -- Extract the original file name without extension
    local originalFileName = pathToOriginalFile:match("([^\\/]*)%.%w+$")
    local escapedFileName = escapePattern(originalFileName)
    
    -- Find the index of the original file name within the full path
    local index = fullPath:find(escapedFileName)
    if index then
        processed = fullPath:sub(index + #originalFileName)
    end
    
    -- Remove specified strings
    processed = processed:gsub("%([^)]*Instrumental[^)]*%)", "")
    processed = processed:gsub("%(Vocals%)", "")
    processed = processed:gsub("model", "")
    
    -- Replace underscores with spaces and remove file extension
    processed = processed:gsub("_", " "):gsub("%.flac$", "")
    
    -- Clean up some stuff to my personal preferences
    processed = processed:gsub(escapePattern("MDX23C-8KFFT-InstVoc HQ"), "MDX23C")
    processed = processed:gsub("bs roformer ep 317 sdr 12.9755", "BS Roformer Viperx 1297")
    processed = processed:gsub("mel band roformer ep 3005 sdr 11.4360", "Mel Roformer Viperx 1143")
    
    -- Trim leading and trailing spaces
    processed = processed:match("^%s*(.-)%s*$")
    
    -- If processed starts with '(' and ends with ')', remove them
    if processed:sub(1, 1) == "(" and processed:sub(-1) == ")" then
        processed = processed:sub(2, -2)
    end

    return processed
end

local function searchFolder(pathToOriginalFile, folderPath, instrumentalFiles, vocalFiles, bgvFiles, fgvFiles)

    -- set up stuff if this is the first recursion
    instrumentalFiles = instrumentalFiles or {{pathToOriginalFile, "Original"}}
    vocalFiles = vocalFiles or {}
    bgvFiles = bgvFiles or {}
    fgvFiles = fgvFiles or {}
    folderPath = folderPath or string.match(pathToOriginalFile, "(.*)[/\\][^/\\]*$")
    
    -- loop over files in the path categorizing the FLACs
    local i = 0
    repeat
        local file = reaper.EnumerateFiles(folderPath, i)
        if file then
            local filePath = folderPath .. package.config:sub(1,1) .. file
            if file:match("%.flac$") then
                if file:match("%(Vocals%).-%(.*Instrumental.*%).*%.flac$") then
                    table.insert(bgvFiles, {filePath, "bgv only (" .. getModelNameLabelFromFile(pathToOriginalFile, filePath) .. ")"})
                elseif file:match("%(Vocals%).-%(Vocals%).*%.flac$") then
                    table.insert(fgvFiles, {filePath, "fgv only (" .. getModelNameLabelFromFile(pathToOriginalFile, filePath) .. ")"})
                elseif file:match("%(.*Instrumental.*%).*%.flac$") then
                    table.insert(instrumentalFiles, {filePath, getModelNameLabelFromFile(pathToOriginalFile, filePath)})
                elseif file:match("%(Vocals%).*%.flac$") then
                    table.insert(vocalFiles, {filePath, getModelNameLabelFromFile(pathToOriginalFile, filePath)})
                else
                    if debug then
                        reaper.ShowConsoleMsg("Unmatched file: " .. file .. "\n") 
                    end
                end
            end
        end
        i = i + 1
    until not file

    i = 0
    repeat
        local dir = reaper.EnumerateSubdirectories(folderPath, i)
        if dir then
            local dirPath = folderPath .. package.config:sub(1,1) .. dir
            searchFolder(pathToOriginalFile, dirPath, instrumentalFiles, vocalFiles, bgvFiles, fgvFiles)
        end
        i = i + 1
    until not dir

    return instrumentalFiles, vocalFiles, bgvFiles, fgvFiles
end


-- Main script starts here

-- Gather the initial state of the project so we can show a dialog later about what we did
local initialInstrumentalCount
local initialVocalCount
local originalTrack = findTrack("Original")
local originalTrackExisted = originalTrack ~= nil
local instrumentalTrack = findTrack("Instruments")
local instrumentalTrackExisted = instrumentalTrack ~= nil
if instrumentalTrack then
    initialInstrumentalCount = reaper.CountTrackMediaItems(instrumentalTrack)
end
local vocalTrack = findTrack("Vocals")
local vocalTrackExisted = vocalTrack ~= nil
if vocalTrack then
    initialVocalCount = reaper.CountTrackMediaItems(vocalTrack)
end

local pathToOriginalFile

-- if there's already an "Original" item on an "Original" track, we don't need to prompt the user to select a file
if originalTrack then
    for i = 0, reaper.CountTrackMediaItems(originalTrack) - 1 do
        local item = reaper.GetTrackMediaItem(originalTrack, i)
        local take = reaper.GetMediaItemTake(item, 0)
        local _, itemName = reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", false)
        -- If an item with the name "Original" is found, get its source file and use that as the path
        if itemName == "Original" then
            local source = reaper.GetMediaItemTake_Source(take)
            pathToOriginalFile = reaper.GetMediaSourceFileName(source, "")
            break
        end
    end
end

-- If no "Original" item was found, prompt the user to select a file
if pathToOriginalFile == nil then
    local retval
    retval, pathToOriginalFile = reaper.GetUserFileNameForRead("", "Select original recording", "FLAC") 
    if retval == 0 or pathToOriginalFile == nil then
        return
    end
end

-- The original file is always added to the "Original" track
local originalFiles = {{pathToOriginalFile, "Original"}}

-- Find and categorize the other FLAC files in the folder
local instrumentalFiles, vocalFiles, bgvFiles, fgvFiles = searchFolder(pathToOriginalFile)

if #originalFiles > 0 then
    if originalTrack == nil then
        originalTrack = createTrack("Original", 0, true)
    end
    importFiles(originalFiles, originalTrack)
end

local addedInstrumentalFiles = {}
if #instrumentalFiles > 0 then
    if instrumentalTrack == nil then
        instrumentalTrack = createTrack("Instruments", #instrumentalFiles, false)
    end
    addedInstrumentalFiles = importFiles(instrumentalFiles, instrumentalTrack)
    if #instrumentalFiles > 1 then
      reaper.SetMediaTrackInfo_Value(instrumentalTrack, "C_LANEPLAYS:1", 1)
    end
end

local addedVocalFiles = {}
local allVocals = concatenateTables(concatenateTables(vocalFiles, fgvFiles), bgvFiles)
if #allVocals > 0 then
    if vocalTrack == nil then
        vocalTrack = createTrack("Vocals", #allVocals, false)
    end
    addedVocalFiles = importFiles(allVocals, vocalTrack)
end

reaper.UpdateItemLanes()
reaper.UpdateArrange()

-- Display the changes to the user
local message = "Refreshed the project structure.\n"

if #addedInstrumentalFiles == 0 and #addedVocalFiles == 0 then
    message = message .. "\nNo new parts found."
else
    if #addedInstrumentalFiles > 0 then
        message = message .. "\nInstrumentals added: \n• " ..  table.concat(addedInstrumentalFiles, "\n• ")
    end

    if #addedVocalFiles > 0 then
        message = message .. "\n\nVocal parts added: \n• " .. table.concat(addedVocalFiles, "\n• ")
    end
end
reaper.ShowMessageBox(message, "Project Updated", 0)

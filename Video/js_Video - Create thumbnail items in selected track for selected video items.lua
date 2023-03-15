--[[
ReaScript name: js_Video - Create thumbnail items in selected track for selected video items
Version: 0.91
Changelog:
  + Accept decimal intervals such as 1/23.976
Author: juliansader
Website: https://forum.cockos.com/showthread.php?t=237293
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script creates thumbnail items for selected video items.  
  
  * The thumbnail items are created inside the selected destintaion track, which may be video items' own track, in which case the thumbnails will be drawn over the video items.
  
  * The items are created at regular spacing along the entire lengths of the video items. The script open a dialog window in which the user can specify the spacing.

  On Linux, ffmpeg needs to be installed, and on WindowsOS and macOS, an ffmpeg executable is required.
  
  High-resolution thumbnails require huge amounts of RAM, so the script can scale thumbnails down to any custom size, which can also be customized in the dialog window.


  REAPER does not currently offer the option of displaying thumbnails in video items.  This script is the first in a pair of scripts that are intended to remedy the shortcoming: 

  The second script in the pair is "js_Video - Automatically adjust size of thumbnail items when zooming", which turns static thumbnails into a repsonsive, auto-zooming thumbnail track.
]]

-- USER AREA: Default thumbnail size
--thumbnailHeight = 100 -- Size in pixels: Larger size => much higher RAM usage


-- GET DESTINATION TRACK
countTracks = reaper.CountSelectedTracks(0) 
if countTracks ~= 1 then
    reaper.MB((countTracks == 0 and "One" or "Only one") .. " destination track should be selected.", "ERROR", 0) return false
end
destTrack = reaper.GetSelectedTrack(0, 0)


-- FIND SELECTED VIDEO ITEMS
tVideos = {}
for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    local source = take and reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.GetMediaItemTake_Source(take)
    local sourceType = source and reaper.GetMediaSourceType(source, "")
        
    if sourceType == "VIDEO" then
        local path = reaper.GetMediaSourceFileName(source, ""):gsub("\\", "/")
        --if path:sub(-4,-4) ~= [[.]] then reaper.MB("Video file does not end with a 3-character extension:\n\n"..path, "ERROR", 0) return end
        local file = path:match("[^/]+$")
        local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        tVideos[#tVideos+1] = { item = item, take = take, itemLength = itemLength, offset = offset, source = source, path = path, file = file, itemStart = itemStart, itemEnd = itemEnd }
    end
end
if #tVideos == 0 then
    reaper.MB("No selected video items detected.", "ERROR", 0) return false
end


-- SETUP FFMPEG PATH
OS = reaper.GetOS()
if OS:match("Linux") then
    linuxRetval = reaper.ExecProcess([[ffmpeg -version]], 10000)
    if not linuxRetval or linuxRetval:sub(1,1) ~= "0" then
        reaper.MB("This script requires ffmpeg to be installed.", "ERROR", 0)
        return false
    else
        ffmpegPath = "ffmpeg"
    end
else
    -- First try to find path from mrlimbic's script
    ffmpegPath = ((reaper.GetExtState("scenedetect", "ffprobe", executable) or ""):gsub("\\", "/"):match(".*/") or "") .. (OS:match("Win") and "ffmpeg.exe" or "ffmpeg")
    --reaper.ShowConsoleMsg("\n"..ffmpegPath)
    if not reaper.file_exists(ffmpegPath) then
        ffmpegPath = reaper.GetExtState(0, "js_Thumbnails", "ffmpeg path") or ""
        if not reaper.file_exists(ffmpegPath) then
            ffmpegFolder = (reaper.GetResourcePath():gsub("\\", "/").."/"):gsub("//", "/")
            ffmpegPath   = ffmpegFolder .. (OS:match("Win") and "UserPlugins/ffmpeg.exe" or "UserPlugins/ffmpeg")
            while not reaper.file_exists(ffmpegPath) do
                if OS:match("OSX") and not shownFfmpegDialog then reaper.MB("In the following dialog window, please select the folder that contains the ffmpeg executable.", "Extract thumbnails", 0) shownFfmpegDialog = true end
                fOK, ffmpegFolder = reaper.JS_Dialog_BrowseForFolder("Please select the folder that contains the ffmpeg executable", ffmpegFolder)
                if not (fOK == 1) then return false end
                ffmpegPath = (ffmpegFolder.."/"):gsub("\\", "/"):gsub("//", "/") .. (OS:match("Win") and "ffmpeg.exe" or "ffmpeg")
                --reaper.ShowConsoleMsg(ffmpegPath)
            end
        end
    end
    reaper.SetExtState("js_Thumbnails", "ffmpeg path", ffmpegPath, true)
    ffmpegPath = [["]] .. ffmpegPath..[["]] -- This is actually only necessary for macOS, which requires "" if the path contains any spaces
end


-- SETUP PATH TO SAVE THUMBNAILS
saveFolder = ( { reaper.GetProjExtState(0, "js_Thumbnails", "Save folder") } )[2]
if not saveFolder or saveFolder == "" then saveFolder = reaper.GetProjectPathEx(0, "") end
if OS:match("OSX") and not shownSaveDialog then reaper.MB("In the following dialog window, please select the folder in which to save the thumbnails.", "Extract thumbnails", 0) shownSaveDialog = true end
fOK, saveFolder = reaper.JS_Dialog_BrowseForFolder("Please select the folder in which to save the thumbnails", saveFolder)
    if not (fOK == 1) then return false end
saveFolder = (saveFolder .."/"):gsub("\\", "/"):gsub("//", "/")
reaper.SetProjExtState(0, "js_Thumbnails", "Save folder", saveFolder)


-- GET USER INPUTS: SPACING AND THUMBNAIL SIZE
defaultHeightStr = string.format("%i", math.min(1080, math.max(10, (thumbnailHeight and tonumber(thumbnailHeight) or 100)))//1)
while not (thumbnailHeight and numer and denom) do
    inputOK, input = reaper.GetUserInputs("Thumbnail parameters", 2, "Thumbnail height (pixels),Interval (seconds)", defaultHeightStr..",1/2")
    if not inputOK then return false end
    thumbnailHeight, numerStr, denomStr = input:match("([^,]+),([^/]+)/*(.*)")
    thumbnailHeight = thumbnailHeight and tonumber(thumbnailHeight)
    numer = numerStr and tonumber(numerStr)
    denom = denomStr and tonumber(denomStr) or 1
end
thumbnailHeight = math.min(1080, math.max(10, thumbnailHeight//1))
thumbnailHeightStr = string.format("%i", thumbnailHeight)
if numer == numer//1 and denom == denom//1 then
    intervalStr = string.format("%i_%i", numer//1, denom//1)
    fpsCmdStr   = (numer==1) and string.format("%i", denom//1) or string.format("%i/%i", denom//1, numer//1)
else
    intervalStr = string.format("%s_%s", tostring(numer), tostring(denom))
    fpsCmdStr   = (numer==1) and tostring(denom) or tostring(denom/numer)
end
--numerStr = string.format("%i", numer)
--denomStr = string.format("%i", denom)
emptyItemLength = numer/denom


-- OK, GOT EVERYTHING WE NEED, NOW START MAKING CHANGES
reaper.Undo_BeginBlock2(0)


-- SET TRACK HEIGHT
reaper.SetMediaTrackInfo_Value(destTrack, "I_HEIGHTOVERRIDE", thumbnailHeight)


-- LOOP THROUGH ALL VIDEO ITEMS, AND EXTRACT THUMBNAILS
for cnt, vid in ipairs(tVideos) do
    reaper.PreventUIRefresh(1) -- MUCH faster when UI doesn't update for each new item
    imagePathBase = saveFolder..vid.file.."-"..thumbnailHeightStr.."p"..tonumber(vid.offset).."ms+" .. intervalStr .. "x" --numerStr.."_"..denomStr.."x"
    offsetStringForFile = tonumber(vid.offset)
    imagePath = imagePathBase..[[%05d.jpg]]
    command = ffmpegPath .. [[ -ss ]] .. string.format("%.3f", vid.offset) .. [[ -t ]] .. string.format("%.3f", vid.itemLength)
              .. [[ -i "]] .. vid.path ..[["]]
              .. [[ -q:v 1 -vf "scale=-1:]] .. thumbnailHeightStr 
              .. [[, fps=]]..fpsCmdStr..[["]] --denom..[[/]]..numer..[["]]
              .. [[ -sws_flags lanczos -start_number 0 ]] 
              .. [[ "]] .. imagePath .. [["]]
    reaper.ShowConsoleMsg("Starting extraction from video item #"..tostring(cnt).."."
                        .."\n\nApproximately "..string.format("%i", (vid.itemLength/emptyItemLength)//1).." jpg files will be created.  Progress can be tracked in real time by the files being created in the destination folder."
                        .."\n\nFFMPEG COMMAND:\n"..command)
    commandOK = reaper.ExecProcess(command, 0)
    reaper.ShowConsoleMsg("\n\nFFMPEG OUTPUT:\n"..commandOK)
    i = 0
    while reaper.file_exists(imagePathBase..string.format("%05i.jpg", i)) do
        local item = reaper.AddMediaItemToTrack(destTrack)
        reaper.SetMediaItemPosition(item, vid.itemStart+(i*numer)/denom, false) -- +i*emptyItemLength
        reaper.SetMediaItemLength(item, emptyItemLength, true)
        reaper.SetMediaItemSelected(item, true) -- !!!!!
        local chunkOK, chunk = reaper.GetItemStateChunk(item, "", false)
        if chunkOK then
            local chunkEntry = "RESOURCEFN \"" .. imagePathBase..string.format("%05i.jpg", i) .. "\"\nIMGRESOURCEFLAGS 1\n"
            chunk = chunk:gsub("\nRESOURCEFN[^\n]*", "")
            chunk = chunk:gsub("\nIMGRESOURCEFLAGS[^\n]*", "")
            chunk = chunk:gsub("(\nIID .-\n)", "%1" .. chunkEntry)
            reaper.SetItemStateChunk(item, chunk)
            reaper.GetSetMediaItemInfo_String(item, "P_EXT:js_Thumbnails", "js_Thumbnail", true)
        end
        i = i + 1
    end
    reaper.PreventUIRefresh(-1) -- Show new thumbnails for each video item
    reaper.ShowConsoleMsg("\n\nCreated "..tonumber(i).." thumbnail items.")
end

reaper.UpdateTimeline()

reaper.Undo_EndBlock2(0, "Create thumbnail items", -1)

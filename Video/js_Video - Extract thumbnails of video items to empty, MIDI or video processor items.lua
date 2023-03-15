--[[
ReaScript name: js_Video - Extract thumbnails of video items to empty, MIDI or video processor items
Version: 0.93
Author: juliansader
Website: https://forum.cockos.com/showthread.php?t=237293
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  This script extracts thumbnail images from selected video items, and displays the thumbnails in selected empty items, MIDI items or dedicated video processor.
  
  If multiple selected video items overlap a thumbnail item, a video item on the same track takes precedence, followed by video items in the closest parent folder, and lastly the video item in the highest (i.e. lowest-numbered) track.
  
  Thumbnail items can be added manually at hitpoints, or at any desired regular spacing, for example by creating a long empty item across the entire length of the video item and then splitting at the grid.
  
  Alternatively, empty items can be added by the script "mrlimbic_ffprobe scene detect.lua", which creates empty items at scene (or camera/line) cuts.
  
  On Linux, ffmpeg needs to be installed, and on WindowsOS and macOS, an ffmpeg executable is required.
  
  High-resolution thumbnails require huge amounts of RAM, so the script can scale thumbnails down to any custom size.  The default size can be specified in the script file's User Area.  
  If no default value is set, the script will ask the user to enter a custom value each time that the script runs.
]] 

--[[
  Changelog:
  * v0.90 (2020-05-22)
    + Initial beta release.
  * v0.91 (2020-05-29)
    + Immediately terminate if image extraction fails once, to avoid hanging with incompatible video sources.
  * v0.92 (2020-05-30)
    + Thumbnails use lower resolution, for vastly lower RAM usage.
  * v0.93 (2020-05-30)
    + Properly detect Linux.
]]

-- USER AREA: 

--thumbnailHeight = 100 -- Default thumbnail height in pixels. Larger size implies much higher RAM usage.


reaper.Undo_BeginBlock2(0)


-- FIND SELECTED EMPTY ITEMS AND VIDEO ITEMS
tEmpty = {}
tVideo = {}
tTracks = {}
for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local track = reaper.GetMediaItem_Track(item)
    local trackNum = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local take = reaper.GetActiveTake(item)
    local source = take and reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.GetMediaItemTake_Source(take)
    local sourceType = source and reaper.GetMediaSourceType(source, "")
        
    -- Thumbnail items (empty / MIDI video processor)
    if not take or sourceType == "MIDI" or sourceType == "VIDEOEFFECT" then 
        chunkOK, chunk = reaper.GetItemStateChunk(item, "", false) -- To insert image, must edit chunk
        if chunkOK then
            tEmpty[#tEmpty+1] = { item = item, chunk = chunk, itemStart = itemStart, track = track, trackNum = trackNum, insideFolder = (reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH") < 0) }
            tTracks[track] = true
        end
        
    -- Video items
    elseif sourceType == "VIDEO" then
        local path = reaper.GetMediaSourceFileName(source, ""):gsub("\\", "/")
        if path:sub(-4,-4) ~= [[.]] then reaper.MB("Video file does not end with a 3-character extension:\n\n"..path, "ERROR", 0) return end
        local file = path:match("[^/]+$")
        local offset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
        local itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local itemEnd    = itemStart+itemLength
        tVideo[#tVideo+1] = { item = item, chunk = chunk, take = take, track = track, trackNum = trackNum, offset = offset, source = source, path = path, file = file, itemStart = itemStart, itemEnd = itemEnd }
    end
end
if #tVideo == 0 and #tEmpty == 0 then 
    reaper.MB("No suitable video or thumbnail items detected amoung the selected items", "ERROR", 0) return false
elseif #tVideo == 0 then
    reaper.MB("No suitable video items detected amoung the selected items", "ERROR", 0) return false
elseif #tEmpty == 0 then
    reaper.MB("No suitable thumbnail items detected amoung the selected items.\n\nThumbnail items may be empty items, MIDI items, or dedicated video items.", "ERROR", 0) return false
end

reaper.ShowConsoleMsg("\n\n"..tostring(#tEmpty).." thumbnail items found.")
table.sort(tEmpty, function(a, b) return a.itemStart < b.itemStart end)
table.sort(tVideo, function(a, b) return a.itemStart < b.itemStart end)


-- SETUP FFMPEG PATH
OS = reaper.GetOS()
if OS:match("Other") then
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
                fOK, ffmpegFolder = reaper.JS_Dialog_BrowseForFolder("Please select the folder that contains the ffmpeg executable:", ffmpegFolder)
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
fOK, saveFolder = reaper.JS_Dialog_BrowseForFolder("Please select the folder in which to save the thumbnails:", saveFolder)
    if not (fOK == 1) then return false end
saveFolder = (saveFolder .."/"):gsub("\\", "/"):gsub("//", "/")
reaper.SetProjExtState(0, "js_Thumbnails", "Save folder", saveFolder)


-- GET THUMBNAIL SIZE
while not (type(thumbnailHeight) == "number") do
    qOK, thumbnailHeight = reaper.GetUserInputs("Thumbnail size", 1, "Height in pixels", "100")
    if not qOK then return false end
    thumbnailHeight = thumbnailHeight and tonumber(thumbnailHeight)
end
thumbnailHeight = math.min(1080, math.max(10, thumbnailHeight//1))
thumbnailHeightStr = string.format("%i", thumbnailHeight)


-- SET TRACK HEIGHTS
for track in pairs(tTracks) do
    reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", tonumber(thumbnailHeight))
end


-- LOOP THROUGH ALL EMPTY ITEMS, AND EXTRACT THUMBNAILS
reaper.ShowConsoleMsg("\n\nProcessing thumbnails:") --..string.format("\n(This may take about %i minutes.)", 1+#tEmpty*0.3//60))
countSuccess = 0
countNonOverlapping = 0
procTime = reaper.time_precise()
for cnt, e in ipairs(tEmpty) do
    
    -- Print progress report
    if cnt%25 == 0 then 
        local t = reaper.time_precise()
        reaper.ShowConsoleMsg("\n"..tostring(cnt).." processed: "..string.format("%.3f", (t-procTime)/25).."s per thumbnail.") 
        procTime = t
    end
    
    --Find video item that overlaps in time, and on same track or nearest track above
    local vid = nil -- Best video item
    for _, v in ipairs(tVideo) do
        if e.itemStart < v.itemStart then -- Video items are sorted, so if gone past no overlaps found
            break
        elseif e.itemStart < v.itemEnd then
            if v.trackNum == e.trackNum then
                vid = v
                break
            elseif not vid then -- First overlap found
                vid = v
            else
                local descendV = e.insideFolder and reaper.MediaItemDescendsFromTrack(e.item, v.track)
                local descendVid = e.insideFolder and reaper.MediaItemDescendsFromTrack(e.item, vid.track)
                if (descendV and not descendVid)
                or (descendV and descendVid and v.trackNum > vid.TrackNum) -- If in folder structure, use video closest
                or (not descendV and not descendVid and v.trackNum < vid.trackNum) then -- If not in folder structure, use highest
                    vid = v
    end end end end
    
    -- If overlapping video item found, can extract thumbnail!
    if not vid then
        countNonOverlapping = countNonOverlapping + 1
    else
        -- Convert time to useable string formats
        --    offsetStringForFile: unique ID for image file name: integer
        --    offsetStringForCommand: ffmpeg requires this format AFAIK: hh:mm:ss.ms
        offset = vid.offset + (e.itemStart-vid.itemStart) -- offset from source video start
        offsetStringForFile = string.format("%i", (0.5 + offset*1000)//1) 
        hours = offset//3600
            offset = offset%3600
        minutes = offset//60
            offset = offset%60
        seconds = offset//1
            offset = offset%1 -- - seconds
        millis = (0.5 + offset*1000)//1
        offsetStringForCommand = string.format("%i:%i:%i.%i", hours, minutes, seconds, millis) 
        imagePath = saveFolder .. vid.file .. " - " .. thumbnailHeightStr .. "p " .. offsetStringForFile .. "ms.jpg"
        -- If thumbnail has already been extracted, don't waste time doing again
        if not reaper.file_exists(imagePath) then
            command = ffmpegPath .. [[ -ss ]] .. offsetStringForCommand .. [[ -i "]] .. vid.path .. [[" -q:v 1 -frames:v 1 -vf scale=-1:]] .. thumbnailHeightStr .. [[ -sws_flags lanczos "]] ..imagePath .. [["]] -- q:v range from 2 (best) to 31 (worst)
            commandOK = reaper.ExecProcess(command, 10000) -- Unlike os.execute, this function doesn't open a terminal
            if not reaper.file_exists(imagePath) then
                failed = true
                reaper.ApplyNudge(0, 1, 6, 1, e.itemStart, false, 1)
                break
            end
        end
        -- Got file OK
        local chunkEntry = "RESOURCEFN \"" .. imagePath .. "\"\nIMGRESOURCEFLAGS 1\n"
        if not e.chunk:match(chunkEntry) then -- if this is already js_Thumbnail item with correct image, don't need to update
            e.chunk = e.chunk:gsub("\nRESOURCEFN[^\n]*", "") -- Else, remove existing image
            e.chunk = e.chunk:gsub("\nIMGRESOURCEFLAGS[^\n]*", "")
            e.chunk = e.chunk:gsub("(\nIID .-\n)", "%1" .. chunkEntry)
            reaper.SetItemStateChunk(e.item, e.chunk)
            reaper.GetSetMediaItemInfo_String(e.item, "P_EXT:js_Thumbnails", "js_Thumbnail", true)
            countSuccess = countSuccess + 1
end end end

reaper.UpdateTimeline()


-- SHOW FINAL RESULTS
--tWords = setmetatable({"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve"}, {__index = function(t, e) return string.format("%i", e) end} )
msg = (failed and (commandOK .. "\n\nScript terminated by failure to extract thumbnail at position: "..offsetStringForCommand.."\nThe edit cursor has been moved to this position, and the ffmpeg error message is above.") or "\n\nDone!")
      .."\n\nSuccessfully added: "..string.format("%i", countSuccess)
      .."\nNon-overlapping with video items: "..string.format("%i", countNonOverlapping)
reaper.ShowConsoleMsg(msg)


reaper.Undo_EndBlock2(0, "Extract thumbnails", -1)

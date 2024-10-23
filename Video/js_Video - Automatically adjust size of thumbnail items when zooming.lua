--[[
ReaScript name: js_Video - Automatically adjust size of thumbnail items when zooming
Version: 0.92
Author: juliansader
Website: https://forum.cockos.com/showthread.php?t=237293
Donation: https://www.paypal.me/juliansader
About:
  # DESCRIPTION
  
  REAPER does not currently offer the option of displaying thumbnails in video items.  
  
  Moreover, if thumbnails are extracted and displayed in static empty items, zooming in will result in messy tiling when the items' pixel widths become longer than the width of the thumbnails, 
      while zooming out will result in tiny, barely visible images when the item widths become shorter. 
  
  This script offers a workaround:  It runs in the background, and automatically adjusts the width of items containing thumbnail images to the approximate width of the images.
  
  All calculations are performed when zooming, not when scrolling, so the script doesn't interfere with playback or recording.
  
  The script will try to detect the optimal W/H ratio from the image in the first thumbnail item in each track.  Otherwise, a default 16:9 will be applied.
  
  
  # INSTRUCTIONS
  
  Before running, select all the items that must be auto-adjusted.  These may be enpty items, MIDI items, or dedicated video processor items.
  
  The script can be linked to a toolbar button, which will light up while the script is running.
]] 

--[[
  Changelog:
  * v0.90 (2020-05-27)
    + Initial beta release.
  * v0.91 (2020-05-29)
    + Automatically lock heights of thumbnail tracks.
  * v0.92 (2020-05-30)
    + Error message if js_ReaScriptAPI is not installed.
]]

if not reaper.JS_LICE_LoadJPG then
    reaper.MB([[This script requires an up-to-date version of the js_ReaScriptAPI extension, which can be installed via ReaPack]], [[ERROR]], 0)
    return false
end

local tItems = {}
for i = 0, reaper.CountSelectedMediaItems(0)-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    local take = reaper.GetActiveTake(item)
    local source = take and reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.GetMediaItemTake_Source(take)
    local sourceType = source and reaper.GetMediaSourceType(source, "")
        
    -- Thumbnail items (empty / MIDI video processor)
    if not take or sourceType == "MIDI" or sourceType == "VIDEOEFFECT" then 
        local track = reaper.GetMediaItem_Track(item)
        if not tItems[track] then 
            tItems[track] = { height = reaper.GetMediaTrackInfo_Value(track, "I_TCPH"),
                              ratio  = 0.9*16/9 }
            -- Try to obtain more accurate ratio from image file
            chunkOK, chunk = reaper.GetItemStateChunk(item, "", false)
            if chunkOK then
                image = chunk:match("RESOURCEFN \"([^\n\"]+)")
                if image then
                    bitmap = (image:match("%.[Pp][Nn][Gg]") and reaper.JS_LICE_LoadPNG(image)) 
                          or (image:match("%.[Jj][Pp][Gg]") and reaper.JS_LICE_LoadJPG(image))
                    if bitmap then
                        local w = reaper.JS_LICE_GetWidth(bitmap)
                        local h = reaper.JS_LICE_GetHeight(bitmap)
                        if w and h then
                            tItems[track].ratio = 0.9*w/h -- REAPER does not fill items fully from top to bottom with the thumbnail, so the item can be a little narrower
                        end
                        reaper.JS_LICE_DestroyBitmap(bitmap)
                    end
                end
            end
        end
        local t = tItems[track]
        t[#t+1] = { item = item, itemStart = reaper.GetMediaItemInfo_Value(item, "D_POSITION") }
    end
end
if not next(tItems) then return end -- No thumbnail items?


-- OK, got items so can go ahead.  Toggle toolbar button, if any.
_, _, sectionID, commandID = reaper.get_action_context()
if sectionID ~= nil and commandID ~= nil and sectionID ~= -1 and commandID ~= -1 then
    reaper.SetToggleCommandState(sectionID, commandID, 1)
    reaper.RefreshToolbar2(sectionID, commandID)
end   


-- Sort items for each track, and enable Free Item Positioning and Height lock
-- NOTE: API help says that I_HEIGHTOVERRIDE must be set before B_HEIGHTLOCK, but I'm not sure why.)
for track, items in pairs(tItems) do
    reaper.SetMediaTrackInfo_Value(track, "B_FREEMODE", 1)
    reaper.SetMediaTrackInfo_Value(track, "B_HEIGHTLOCK", 1)
    table.sort(items, function(a, b) return a.itemStart < b.itemStart end)
end
reaper.UpdateTimeline() -- Make sure Free Item Positioning is displayed


-- When exiting, toggle toolbar button
function exit()
    if sectionID ~= nil and commandID ~= nil and sectionID ~= -1 and commandID ~= -1 then
        reaper.SetToggleCommandState(sectionID, commandID, 0)
        reaper.RefreshToolbar2(sectionID, commandID)
    end 
end


prevZoom = math.huge
function update()
    zoom = reaper.GetHZoomLevel()
    zoomRatio = zoom/prevZoom
    prevZoom = zoom
    hasZoomed = (zoomRatio < 0.9999 or 1.0001 < zoomRatio)
    for track, items in pairs(tItems) do
        trackH = reaper.GetMediaTrackInfo_Value(track, "I_TCPH")
        if hasZoomed or trackH ~= items.height then
            items.height = trackH
            optimalItemTimeLength = (trackH*items.ratio)/zoom
            runningEnd = -math.huge
            for i, item in ipairs(items) do
               if item.itemStart >= runningEnd then
                    reaper.SetMediaItemInfo_Value(item.item, "D_LENGTH", optimalItemTimeLength)
                    reaper.SetMediaItemInfo_Value(item.item, "F_FREEMODE_H", 1)
                    runningEnd = item.itemStart + optimalItemTimeLength
                else
                    reaper.SetMediaItemInfo_Value(item.item, "D_LENGTH", 0.01)
                    reaper.SetMediaItemInfo_Value(item.item, "F_FREEMODE_H", 0.01)
                    reaper.SetMediaItemInfo_Value(item.item, "F_FREEMODE_Y", 0)
                end
            end
        end
    end
    return true
end

function loop()
    if pcall(update) then reaper.defer(loop) end
end

reaper.atexit(exit)

loop()

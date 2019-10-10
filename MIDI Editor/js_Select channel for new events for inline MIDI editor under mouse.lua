--[[
ReaScript name: js_Select MIDI channel for new events for inline MIDI editor under mouse.lua
Version: 1.00
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Extensions:  SWS/S&M 2.8.3 or later
Donation: https://www.paypal.me/juliansader
Provides: [main=main,midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION
  
  REAPER does not provide native actions to select the channel for new events for the Inline MIDI Editor.
  
  By default, the MIDI channel is linked to the last-used settings in the (full, not inline) MIDI editor, 
  for each item individually, and the user therefore has to open the full MIDI editor for each item, 
  in order to change the channel.
  
  This script provides a dropdown list from which the active MIDI channel can quickly be selected, 
  while working in the inline MIDI editor.
  
  
  Warnings:
  
  * In items with multiple MIDI takes, it is possible that the script does not determine the current channel and filter settings correctly.
  Changing the filter and channel will still work.
  
  * Inline MIDI editors easily lose focus, and keyboard shortcuts will then inadvertently pass through to the Main section.
  Click in the inline editor after changing channel to re-focus the editor. 
]] 

--[[
  Changelog:
  * v0.90 (2018-01-14)
    + Initial release
  * v0.91 (2018-01-14)
    + Small bug fix for items with filter off
  * v0.92 (2018-01-14)
    + New option to enable or disable event filter
  * v0.93 (2018-01-15)
    + If called from main MIDI editor, return focus to editor on exit
  * v1.00 (2019-02-01)
    + If ReaScriptAPI is installed, return focus to inline editor.
]]


-------------------------------------------------------------
-------------------------------------------------------------

reaper.defer(function()end) -- Don't automatically add undo point if error

function AtExit()
    -- The dropdown list removes focus from the Inline Editor, 
    --    so must try to return focus.  
    -- Current API cannot yet give focus to item not under mouse.)
    if foregroundWindow then reaper.JS_Window_SetForeground(foregroundWindow) end
    if focusWindow then reaper.JS_Window_SetFocus(focusWindow) end
    if isInline then
        reaper.JS_Mouse_SetPosition(mouseX, mouseY)
        reaper.Main_OnCommandEx(40911, -1, 0) -- Focus item under mouse cursor
    end
end



if not reaper.BR_ItemAtMouseCursor then
    reaper.MB("This script requires the SWS/S&M extension, which can be downloaded from\n\nwww.sws-extension.org", "ERROR", 0)
    return
elseif not (reaper.JS_Window_FindEx) then -- FindEx was added in v0.963
    reaper.MB("This script requires an up-to-date version of the js_ReaScriptAPI extension."
           .. "\n\nThe js_ReaScripAPI extension can be installed via ReaPack, or can be downloaded manually."
           .. "\n\nTo install via ReaPack, ensure that the ReaTeam/Extensions repository is enabled. "
           .. "This repository should be enabled by default in recent versions of ReaPack, but if not, "
           .. "the repository can be added using the URL that the script will copy to REAPER's Console."
           .. "\n\n(In REAPER's menu, go to Extensions -> ReaPack -> Import a repository.)"
           .. "\n\nTo install the extension manually, download the most recent version from Github, "
           .. "using the second URL copied to the console, and copy it to REAPER's UserPlugins directory."
            , "ERROR", 0)
    reaper.ShowConsoleMsg("\n\nURL to add ReaPack repository:\nhttps://github.com/ReaTeam/Extensions/raw/master/index.xml")
    reaper.ShowConsoleMsg("\n\nURL for direct download:\nhttps://github.com/juliansader/ReaExtensions")
    return
end
reaper.atexit(AtExit)

foregroundWindow = reaper.JS_Window_GetForeground()
focusWindow      = reaper.JS_Window_GetFocus()
mouseX, mouseY   = reaper.GetMousePosition()


-----------------------------------------------
-- Get the MIDI editor and take under the mouse
window, segment, details = reaper.BR_GetMouseCursorContext()
if window == "midi_editor" then
    editor, isInline = reaper.BR_GetMouseCursorContext_MIDI()
    if isInline then
        take = reaper.BR_GetMouseCursorContext_Take()
    elseif editor then
        take = reaper.MIDIEditor_GetTake(editor)
    end
end
if take and reaper.ValidatePtr2(0, take, "MediaItem_Take*") then
    item = reaper.GetMediaItemTake_Item(take)
end
if not (item and reaper.ValidatePtr2(0, item, "MediaItem*")) then 
    reaper.MB("Could not determine the editor and item under the mouse.", "ERROR", 0)
    return 
end


----------------------------------------------------------------
-- GetItemStateChunk was buggy, but was fixed in v5.9-something.  
local chunkOK, chunk = reaper.GetItemStateChunk(item, "", false)
if not chunkOK then 
    reaper.MB("Could not load state chuck of item under mouse", "ERROR", 0)
    return
end
-- Get the active take's part of the item's chunk.
-- In the item chunk, each take's data is separate, and in the same order as the take numbers.
takeNum = reaper.GetMediaItemTakeInfo_Value(take, "IP_TAKENUMBER")
takeChunkStartPos = 1
for t = 1, takeNum do
    takeChunkStartPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
    if not takeChunkStartPos then 
        reaper.MB("Could not find the active take's part of the item state chunk.", "ERROR", 0) 
        return false
    end
end
takeChunkEndPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
activeTakeChunk = chunk:sub(takeChunkStartPos, takeChunkEndPos)
      
      
----------------------------------
-- Find current channel and filter
channelStr = activeTakeChunk:match("\nCFGEDIT [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ (%d+) ")
channel = tonumber(channelStr)

filterStr, filterActive = activeTakeChunk:match("\nEVTFILTER (%d+) [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ ([01]) ")
filter = tonumber(filterStr)

if not (channel and channel >= 1 and channel <= 16 and filter and filterActive) then
    reaper.MB("The item under the mouse has not yet been opened in an inline MIDI editor", "ERROR", 0)
    return
end


----------------------------------------------
-- Got everything, so can start changing things
--reaper.Undo_BeginBlock2(0)

-- Assemble menu string
menuStr = "#Set channel for new events||Event filter||Edit only active channel||1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|"
menuStr = menuStr:gsub("|"..channelStr.."|", "|!"..channelStr.."|")
if filterActive == "1" then menuStr = menuStr:gsub("Event", "!Event") end
if filter ~= 0 then menuStr = menuStr:gsub("Edit", "!Edit") end

-- Get user inputs.  GUI does not look slick and 'native', so try to position dropdown menu OVER script GUI.
gfx.init("_Select_channel____", 0, 0, 0, mouseX-100, mouseY-50)
hwnd = reaper.JS_Window_Find("_Select_channel____", true)
if hwnd then reaper.JS_Window_SetOpacity(hwnd, "ALPHA", 0) end
gfx.x = -50
gfx.y = -300
userChoice = gfx.showmenu(menuStr)
gfx.quit()

--[[
Channel and filter fields must always be coordinated:
If filter is on, filter = 1 << (channel-1)

Channel = 1, filter OFF:
EVTFILTER 0 -1 -1 -1 -1 0 0 0 0 -1 -1 -1 -1 0 -1 0 -1 -1
CFGEDIT 1 1 0 0 0 0 1 1 1 1 1 1 -403 275 971 1051 0 0 0 1 0 0 0 0 0 0.5 0 0 1 64

Channel = 2, filter OFF:
EVTFILTER 0 -1 -1 -1 -1 1 0 0 0 -1 -1 -1 -1 0 -1 0 -1 -1
CFGEDIT 1 1 0 0 0 0 1 1 2 1 1 1 -225 513 1149 1289 0 0 0 1 0 0 0 0 0 0.5 0 0 1 64

Channel = 3, filter ON: 
EVTFILTER 4 -1 -1 -1 -1 2 0 0 0 -1 -1 -1 -1 0 -1 0 -1 -1
CFGEDIT 1 1 0 0 0 0 1 1 3 1 1 1 -265 433 1109 1209 0 0 0 1 0 0 0 0 0 0.5 0 0 1 64
]]
    
    
----------------
-- Toggle filter
if userChoice == 2 then -- toggle event filter
    newChannel = channel
    if filterActive == "0" then
        newFilterActive = "1"
        newFilter = 1<<(newChannel-1)
    else
        newFilterActive = "0"
        newFilter = filter
    end
elseif userChoice == 3 then -- toggle edit only active channel
    newChannel = channel
    newFilter = ((filter == 0) and (1<<(newChannel-1))) or 0   
    newFilterActive = filterActive                             
-- Change channel
elseif type(userChoice) == "number" and userChoice%1 == 0 and userChoice >= 3 and userChoice <= 18 then
    newChannel = userChoice-3
    newFilter = ((filter == 0) and 0) or (1<<(newChannel-1)) -- If filter is not active, don't activate  
    newFilterActive = filterActive                
-- Else, quit
else 
    return
end 


-----------------------------
-- Edit chunk (for ALL takes)
chunk = chunk:gsub("(\nCFGEDIT [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ )[%-%d]+ ", 
                   "%1" .. string.format("%i", newChannel) .. " ") -- CFGEDIT numbers channels 1-16
chunk = chunk:gsub("(\nEVTFILTER )[%-%d]+( [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ )[%-%d]+ [%-%d]+ ", 
                   "%1" .. string.format("%i", newFilter) .. 
                   "%2" .. string.format("%i", newChannel-1) .. " " ..
                   newFilterActive .. " ") -- EVTFILTER numbers channels 0-15
reaper.SetItemStateChunk(item, chunk, false)
reaper.UpdateItemInProject(item)


-- Undo_OnStateChange_Item is expected to be the fastest undo function, since it limits the info stored 
--    in the undo point to changes in this specific item.
--reaper.Undo_EndBlock2(0, "Select active MIDI channel", -1)
reaper.Undo_OnStateChange_Item(0, "Set active channel", item)

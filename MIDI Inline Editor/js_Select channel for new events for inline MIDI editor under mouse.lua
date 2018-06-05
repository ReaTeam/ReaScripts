--[[
ReaScript name: js_Select MIDI channel for new events for inline MIDI editor under mouse.lua
Version: 0.94
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
  * v0.94 (2018-05-18)
    + Fix setting new active channel 16.
]]


-------------------------------------------------------------
-------------------------------------------------------------

if not reaper.APIExists("BR_ItemAtMouseCursor") then
    reaper.MB("This script requires the SWS/S&M extension, which can be downloaded from\n\nwww.sws-extension.org", "ERROR", 0)
    return
end
item = reaper.BR_ItemAtMouseCursor()
if not reaper.ValidatePtr2(0, item, "MediaItem*") then -- Hidden feature: can also use script in full MIDI editor
    local window = reaper.BR_GetMouseCursorContext()
    if window == "midi_editor" then
        editor = reaper.MIDIEditor_GetActive() -- Not local, so that script can check whether called from main MIDI editor
        if editor then
            local take = reaper.MIDIEditor_GetTake(editor)
            if reaper.ValidatePtr2(0, take, "MediaItem_Take*") then
                item = reaper.GetMediaItemTake_Item(take) 
end end end end
if not reaper.ValidatePtr2(0, item, "MediaItem*") then return end


-------------------------------------------
-- REAPER's own GetItemStateChunk is buggy!  
-- Can't load large chunks!  So must use SWS's SNM_GetSetObjectState.
local fastStr = reaper.SNM_CreateFastString("")
local chunkOK = reaper.SNM_GetSetObjectState(item, fastStr, false, false)
if not chunkOK then 
    reaper.MB("Could not load state chuck of item under mouse", "ERROR", 0)
    return
end
chunk = reaper.SNM_GetFastString(fastStr)
reaper.SNM_DeleteFastString(fastStr)
      
      
----------------------------------
-- Find current channel and filter
channelStr = chunk:match("\nCFGEDIT [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ (%d+) ")
channel = tonumber(channelStr)

filterStr, filterActive = chunk:match("\nEVTFILTER (%d+) [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ ([01]) ")
filter = tonumber(filterStr)

if not (channel and channel >= 1 and channel <= 16 and filter and filterActive) then
    reaper.MB("The item under the mouse has not yet been opened in an inline MIDI editor", "ERROR", 0)
    return
end


----------------------------------------------
-- Got everything, so can start changing things
reaper.Undo_BeginBlock2(0)

-- Assemble menu string
menuStr = "#Set channel for new events||Event filter||Edit only active channel||1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|"
menuStr = menuStr:gsub("|"..channelStr.."|", "|!"..channelStr.."|")
if filterActive == "1" then menuStr = menuStr:gsub("Event", "!Event") end
if filter ~= 0 then menuStr = menuStr:gsub("Edit", "!Edit") end

-- Get user inputs.  GUI does not look slick and 'native', so try to position dropdown menu OVER script GUI.
x, y = reaper.GetMousePosition()
gfx.init("", 0, 0, 0, x-100, y-50)
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
elseif type(userChoice) == "number" and userChoice%1 == 0 and userChoice >= 3 and userChoice <= 19 then
    newChannel = userChoice-3
    newFilter = ((filter == 0) and 0) or (1<<(newChannel-1)) -- If filter is not active, don't activate  
    newFilterActive = filterActive                
-- Else, quit
else 
    return
end 


-----------------------------
-- Edit chunk (for all takes)
chunk = chunk:gsub("(\nCFGEDIT [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ )[%-%d]+ ", 
                   "%1" .. string.format("%i", newChannel) .. " ") -- CFGEDIT numbers channels 1-16
chunk = chunk:gsub("(\nEVTFILTER )[%-%d]+( [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ [%-%.%d]+ )[%-%d]+ [%-%d]+ ", 
                   "%1" .. string.format("%i", newFilter) .. 
                   "%2" .. string.format("%i", newChannel-1) .. " " ..
                   newFilterActive .. " ") -- EVTFILTER numbers channels 0-15
reaper.SetItemStateChunk(item, chunk, false)
reaper.UpdateItemInProject(item)


----------------------------------------------------------
-- The dropdown list removes focus from the Inline Editor, 
--    so must try to return focus.  
-- Current API cannot yet give focus to item not under mouse.)
if editor then
    if reaper.APIExists("SN_FocusMIDIEditor") then reaper.SN_FocusMIDIEditor() end
elseif item == reaper.BR_ItemAtMouseCursor() then
    reaper.Main_OnCommandEx(40911, -1, 0) -- Focus item under mouse cursor
end

reaper.Undo_EndBlock2(0, "Select active MIDI channel", -1)

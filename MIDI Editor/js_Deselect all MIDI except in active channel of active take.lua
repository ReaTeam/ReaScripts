--[[
ReaScript name: js_Deselect all MIDI except in active channel of active take.lua
Version: 2.10
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # DESCRIPTION
  
  When working with multi-channel MIDI items, it is often necessary to limit selection and editing to events in a single MIDI channel.
  
  Somme -- but not all -- of REAPER's native selection functions (such as right-drag marquee select) have been updated to select only 
      events in the MIDI editor's active channel, if a channel is selected in the editor's "Channel" dropdown list.
      
  In all other cases, this script can be used to deselect unwanted events.
  
  If the mouse is over an inline editor in the arrange view when the script is run (from a keyboard shortcut), the inline editor will affected.
  Otherwise, the script will affect the last-used MIDI editor.
  
  Sysex and meta events do not carry channel info, so will always be deselected.
  
  TIP: REAPER's inline editor does not provide a native function for selecting the active MIDI channel.  The script "js_Select channel for new events for MIDI editor under mouse.lua" can be used instead.
]]

--[[
  Changelog:
  * v0.90 (2016-11-16)
    + Initial beta release
  * v1.00 (2016-12-04)
    + Faster execution, using REAPER v5.30's new API functions.
  * v2.00 (2020-04-29)
    + Works in inline editor under mouse (and automatically installs in inline editor context).
  * v2.01 (2020-04-29)
    + Small improvement.
  * v2.10 (2020-05-15)
    + Fix MediaItem_Take expected error.
]]

----------------------------------------------------------------------------
--function main() 

-- This script will do the following:
--    1) Download the raw MIDI data of the active take, using MIDI_GetAllEvts, and edit this to deselect all except in the active channel
--    2) Deselect all events in all editable takes in the MIDI editor, using the built-in Action "Unselect all".  (This is much faster
--      than iterating through all takes and using ReaScript to deselect the events.
--    3) Upload the edited raw MIDI data of the active take, which re-selects those events that remained selected in step 1.

-- Little trick to prevent REAPER from automatically creating an undo point:
--    simply 'defer' any function.
--[[function preventUndo()
]]

reaper.defer(function() end)

-- Check whether the required version of REAPER is available
if not reaper.GetItemFromPoint then
    reaper.ShowMessageBox("This script requires REAPER v6.00 or higher.", "ERROR", 0)
    return false 
end
if not reaper.BR_IsMidiOpenInInlineEditor then
    reaper.ShowMessageBox("This script requires the SWS/S&M extension.", "ERROR", 0)
    return false 
end

-- Find MIDI take. If mouse is over arrange view item, then inline editor, else main editor
x, y = reaper.GetMousePosition()
activeItem, activeTake = reaper.GetItemFromPoint(x, y, false)
-- INLINE EDITOR
if activeTake then
    isInline = true
    if not (reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") and reaper.BR_IsMidiOpenInInlineEditor(activeTake)) then
        reaper.ShowMessageBox("No inline editor could be found under the mouse.", "ERROR", 0)
        return false
    end
    -- First, get the active take's part of the item's chunk.
    -- In the item chunk, each take's data is separate, and in the same order as the take numbers.
    local chunkOK, chunk = reaper.GetItemStateChunk(activeItem, "", false)
        if not chunkOK then 
            reaper.MB("Could not get the state chunk of the active item.", "ERROR", 0) 
            return false
        end
    local takeNum = reaper.GetMediaItemTakeInfo_Value(activeTake, "IP_TAKENUMBER")
    local takeChunkStartPos = 1
    for t = 1, takeNum do
        takeChunkStartPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
        if not takeChunkStartPos then 
            reaper.MB("Could not find the active take's part of the item state chunk.", "ERROR", 0) 
            return false
        end
    end
    local takeChunkEndPos = chunk:find("\nTAKE[^\n]-\nNAME", takeChunkStartPos+1)
    activeTakeChunk = chunk:sub(takeChunkStartPos, takeChunkEndPos)   
   
    activeChannel = activeTakeChunk:match("\nCFGEDIT %S+ %S+ %S+ %S+ %S+ %S+ %S+ %S+ (%S+)")
    if not activeChannel then 
        reaper.MB("Could not determine the active channel from the item state chunk.", "ERROR", 0) 
        return false
    end
    activeChannel = tonumber(activeChannel)-1 -- Chunk stores MIDI channel as 1-16 instead of 0-15
-- MIDI EDITOR
else
    editor = reaper.MIDIEditor_GetActive()
    if editor == nil then 
        reaper.ShowMessageBox("Could not find any active MIDI editors.", "ERROR", 0)
        return
    end
    -- Check whether an active take is available - note the GetTake is buggy and may return a non-nil but invalid pointer, so must check validity.
    activeTake = reaper.MIDIEditor_GetTake(editor)
    if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then 
        reaper.ShowMessageBox("Could not find any active take for the MIDI editor.", "ERROR", 0)
        return
    end
    activeChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
end
 
-- This script does not use the standard MIDI API functions such as MIDI_SetCC, since these
--    functions are far too slow when dealing with thousands of events.
-- Instead, REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
--    MIDI_GetAllEvts and MIDI_SetAllEvts.
local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(activeTake, "")

if not gotAllOK then
    
    reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data of the active take.", "ERROR", 0)
    return false 

else

    local MIDIlen = MIDIstring:len()
    
    local tableEvents = {} -- All events will be stored in this table until they are concatened again
    local t = 0 -- Count index in table.  It is faster to use tableEvents[t] = ... than table.insert(...
    local mustDeselect = false
    local s_unpack = string.unpack
    local s_pack   = string.pack
    
    -- The script will speed up execution by not inserting each event individually into tableEvents as they are parsed.
    --    Instead, only changed (i.e. deselected) events will be re-packed and inserted individually, while unchanged events
    --    will be inserted as bulk blocks of unchanged sub-strings.
    local nextPos, prevPos, unchangedPos = 1, 1, 1 -- unchangedPos is starting position of block of unchanged MIDI.
    
    while nextPos <= MIDIlen do
           
        local offset, flags, msg
        
        prevPos = nextPos
        offset, flags, msg, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos)
        
        mustDeselect = false
        if flags&1 == 1 then -- First bit in flags is selection status
            -- Sysex and meta events do not carry channel info, so will always be deselected
            -- No need to worrqy about selected notes with notation: REAPER's notation text events are always unselected, even if the corresponding note is selected.
            if (msg:byte(1))&0xF0 == 0xF0 then
                mustDeselect = true
            -- Non-sysex, non-meta events always include channel in lowest 'nibble' of status byte
            elseif (msg:byte(1))&0x0F ~= activeChannel then
                mustDeselect = true
            end
        end
        
        if mustDeselect then
            if unchangedPos < prevPos then
                t = t + 1
                tableEvents[t] = MIDIstring:sub(unchangedPos, prevPos-1)
            end
            t = t + 1
            tableEvents[t] = s_pack("i4Bs4", offset, flags&0xFE, msg)
            unchangedPos = nextPos
        end        
    end
    
    -- Ieration complete.  Write the last block of remaining events to table.
    t = t + 1
    tableEvents[t] = MIDIstring:sub(unchangedPos)
    
    -----------------------------------------------------------------------
    -- Finally, going to make changes to the project, so create undo block.
    reaper.Undo_BeginBlock2(0)
    -- Deselect all MIDI in editable takes
    if editor then reaper.MIDIEditor_OnCommand(editor, 40214) end -- Edit: Unselect all
    -- Upload new MIDI string into active take
    reaper.MIDI_SetAllEvts(activeTake, table.concat(tableEvents))
    -- Make sure inline editor is redrawn on screen
    if isInline then reaper.UpdateItemInProject(activeItem) end
    -- Use flag=4 to limit undo to items, which is much faster than unnecessarily including everything
    reaper.Undo_EndBlock2(0, "Deselect all MIDI except in active channel of active take", 4)
    
end



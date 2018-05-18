--[[
ReaScript name: js_Deselect all MIDI except in active channel of inline MIDI editor under mouse.lua
Version: 1.10
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: 
Donation: https://www.paypal.me/juliansader
]]

--[[
  Changelog:
  * v0.90 (2016-11-16)
    + Initial beta release
  * v1.00 (2016-12-04)
    + Faster execution, using REAPER v5.30's new API functions.
  * v1.10 (2018-05-18)
    + Installs and works in Inline MIDI Editor.
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
reaper.defer(function() end)

-- Check whether the required version of REAPER is available
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.30 or higher.", "ERROR", 0)
    return(false) 
end

-- Check whether a MIDI editor is under the mouse
window, segment, details = reaper.BR_GetMouseCursorContext()
if window ~= "midi_editor" then return end

editor, isInline = reaper.BR_GetMouseCursorContext_MIDI()

-------------------------------------------------
-- Find take and active channel
local activeChannel
local take
if isInline then
    take = reaper.BR_GetMouseCursorContext_Take()
        if not (reaper.ValidatePtr(take, "MediaItem_Take*") and reaper.BR_IsMidiOpenInInlineEditor(take)) then
            reaper.MB("Could not determine the take that is open in the inline MIDI editor under mouse.", "ERROR", 0) 
            return(false) 
        end
    -- Find active channel (quite complicated in case of inline editor)
    -- REAPER's own GetItemStateChunk is buggy!  
    -- Can't load large chunks!  So must use SWS's SNM_GetSetObjectState.
    local item = reaper.GetMediaItemTake_Item(take)
    local fastStr = reaper.SNM_CreateFastString("")
    local chunkOK = reaper.SNM_GetSetObjectState(item, fastStr, false, false)
        if not chunkOK then 
            reaper.MB("Could not load state chuck of item under mouse", "ERROR", 0)
            return
        end
    local chunk = reaper.SNM_GetFastString(fastStr)
    reaper.SNM_DeleteFastString(fastStr)
          
    local channelStr = chunk:match("\nCFGEDIT [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ [%-%d]+ (%d+) ")
    activeChannel = tonumber(channelStr) or 1 -- Use channel 1 as default
    activeChannel = activeChannel - 1 -- CFGEDIT uses channel numbers 1..16 instead of 0..15
    
else -- main MIDI editor

    take = reaper.MIDIEditor_GetTake(editor)
        if not reaper.ValidatePtr(take, "MediaItem_Take*") then
            reaper.MB("Could not determine the active take in the MIDI editor.", "ERROR", 0) 
            return(false) 
        end
    activeChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
end

-------------------------------------------------------------------------------------------
-- This script does not use the standard MIDI API functions such as MIDI_SetCC, since these
--    functions are far too slow when dealing with thousands of events.
-- Instead, REAPER v5.30 introduced new API functions for fast, mass edits of MIDI:
--    MIDI_GetAllEvts and MIDI_SetAllEvts.
local gotAllOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
    if not gotAllOK then
        reaper.ShowMessageBox("MIDI_GetAllEvts could not load the raw MIDI data of the active take.", "ERROR", 0)
        return false 
    end


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
        -- No need to worry about selected notes with notation: REAPER's notation text events are always unselected, even if the corresponding note is selected.
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
reaper.MIDI_SetAllEvts(take, table.concat(tableEvents))
-- Use flag=4 to limit undo to items, which is much faster than unnecessarily including everything
reaper.Undo_EndBlock2(0, "Deselect all MIDI except in active channel of active take", 4)



--[[
ReaScript name: js_Deselect all MIDI except in active channel of active take.lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
]]
 
--[[
  Changelog:
  * v0.90 (2016-11-16)
    + Initial beta release
]]

-----------------------------------------------------------------
--function main() 

editor = reaper.MIDIEditor_GetActive()
if editor == nil then 
    reaper.ShowMessageBox("Could not find any active MIDI editors.", "ERROR", 0)
    return
end

activeTake = reaper.MIDIEditor_GetTake(editor)
if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then 
    reaper.ShowMessageBox("Could not find any active take.", "ERROR", 0)
    return
end

activeItem = reaper.GetMediaItemTake_Item(activeTake)

reaper.Undo_BeginBlock()

----------------------------------------------------------------------
-- First, iterate through all items and takes in the entire project
--    and deselect all MIDI event in all take *except* the active take    
numItems = reaper.CountMediaItems(0)
for i=0, numItems-1 do 

    curItem = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, curItem, "MediaItem*") then 
    
        numTakes = reaper.CountTakes(curItem)  
        for t=0, numTakes-1 do 
        
            curTake = reaper.GetTake(curItem, t)    
            if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and not (curTake == activeTake) then -- Skip active take
                
                -- Deselect all events in one shot.
                reaper.MIDI_SelectAll(curTake, false)               
              
            end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake)
        end -- for t=0, numTakes-1
    end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
end -- for i=0, numItems-1

---------------------------------------------------------------------
-- OK, now time to selectively deselect events within the active take
-- This script does not use the standard MIDI API functions such as MIDI_SetCC, since these
--    functions are far too slow when dealing with thousands of events.
-- Instead, this script will directly edit the raw MIDI data in the take's "state chunk".
-- More info on the formats can be found at 

local guidString, gotChunkOK, chunkStr, _, posTakeGUID, posAllNotesOff, posTakeMIDIend, posFirstStandardEvent, 
      posFirstExtendedEvent, posFirstSysex, posFirstMIDIevent

guidString = reaper.BR_GetMediaItemTakeGUID(activeTake)

-- All the MIDI data of all the takes in the item is stored within the "state chunk"
gotChunkOK, chunkStr = reaper.GetItemStateChunk(activeItem, "", false)
if not gotChunkOK then
    reaper.ShowMessageBox("Could not access the item's state chunk.", "ERROR", 0)
    return
end

-- Use the take's GUID to find the beginning of the take's data within the state chunk of the entire item
_, posTakeGUID = chunkStr:find(guidString, 1, true)
if type(posTakeGUID) ~= "number" then
    reaper.ShowMessageBox("Could not find the take's GUID string within the state chunk.", "ERROR", 0)
    return
end

-- REAPER's MIDI takes all end with an All-Notes-Off message, E offset B0 7B 00.
-- This line tries to find such a message (that is not followed by another MIDI event)
posAllNotesOff, posTakeMIDIend = chunkStr:find("\n[eE] %d+ [Bb]0 7[Bb] 00\n[^<xXeE]", posTakeGUID)
if posTakeMIDIend == nil then 
    reaper.ShowMessageBox("No end-of-take MIDI message found.", "ERROR", 0)
    return
end

-- Now find the very first MIDI message in the take's chunk.  This can be in standard format, extended format, of sysex format
posFirstStandardEvent = chunkStr:find("\n[eE]m? %d+ %x%x %x%x %x%x[% %d]-\n", posTakeGUID)
posFirstExtendedEvent = chunkStr:find("\n[xX]m? %d+ %d+ %x%x %x%x %x%x[% %d]-\n", posTakeGUID)
posFirstSysex         = chunkStr:find("\n<[xX]m? %d+ %d+ .->\n[<xXeE]", posTakeGUID)
if not posFirstExtendedEvent then posFirstExtendedEvent = math.huge end
if not posFirstSysex then posFirstSysex = math.huge end
posFirstMIDIevent = math.min(posFirstStandardEvent, posFirstExtendedEvent, posFirstSysex)
if posFirstMIDIevent >= posAllNotesOff then 
    --reaper.ShowMessageBox("MIDI take is empty.", "ERROR", 0)
    -- MIDI take is empty, so nothing to deselect!
    return
end        

-- To make all the search faster (and to prevent possible bugs)
--    the item's state chunk will be divided into three parts, with the middle part
--    exclusively the take's raw MIDI.
local chunkFirstPart = chunkStr:sub(1, posFirstMIDIevent-1)
local thisTakeMIDIchunk = chunkStr:sub(posFirstMIDIevent, posTakeMIDIend-1)
local chunkLastPart = chunkStr:sub(posTakeMIDIend)

-- At long last, time to get the channel info and deselect
defaultChannel = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
defaultUpper = string.upper(string.format("%x", defaultChannel)) 
defaultLower = string.lower(string.format("%x", defaultChannel))

local matchStringStandard = "\ne(m? %d+ %x[^" 
                    .. string.upper(string.format("%x", defaultChannel)) 
                    .. string.lower(string.format("%x", defaultChannel))
                    .. "] %x%x %x%x)"
local matchStringExtended = "\nx(m? %d+ %d+ %x[^" 
                    .. string.upper(string.format("%x", defaultChannel)) 
                    .. string.lower(string.format("%x", defaultChannel))
                    .. "] %x%x %x%x)"

thisTakeMIDIchunk = thisTakeMIDIchunk:gsub(matchStringStandard, "\nE%1")
thisTakeMIDIchunk = thisTakeMIDIchunk:gsub(matchStringExtended, "\nX%1")

reaper.SetItemStateChunk(activeItem, chunkFirstPart .. thisTakeMIDIchunk .. chunkLastPart, false)

reaper.Undo_EndBlock("Deselect all MIDI except in active channel of active take", -1)

--[[
ReaScript name: js_Remove redundant CCs (from selected events in last clicked lane).lua
Version: 0.95
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Extensions: SWS/S&M 2.8.3 or 2.8.7
About:
  # Description
  Remove redundant events from 7-bit CC, pitchwheel or channel pressure lanes with a single click.

  # Instructions
  In the USER AREA of the script (below the changelog), the user can customize the following options:
  (It may be useful to link different versions of the script to different shortcuts.)
    
    - lanes_from_which_to_remove:  "all", "last clicked" or "under mouse"
    
    - ignore_LSB_from_14bit_CCs:  Ignore LSB when comparing pitchwheel events
    
    - only_analyze_selected:  Limit analysis and removal to selected events?
    
    - automatically_delete_muted_CCs: Muted CCs are inherently redundant
    
    - show_error_messages
  
  (* at present, the script does not work with 14-bit CC lanes)
]]

--[[
 Changelog:
  * v0.9 (2016-05-28)
    + Initial release.
  * v0.91 (2016-06-29)
    + The "Remove Redundant CCs" script has several settings that the user can customize in the script's USER AREA. This is a version of the script with the following settings:
    + CC LANE: CCs will be removed from the lane that is under the mouse at the time the script is called (not from the last clicked lane).
    + SELECTION: Only selected CCs will be analyzed. Unselected CCs will be ignored.
    + MUTED: Muted CCs will automatically be removed since they are inherently redundant.
    + 14BIT CC LSB: When analyzing pitchwheel events, the LSB will be ignored.
  * v0.95 (2016-11-16)
    + Header and About info updated for ReaPack 1.1 format.
    + IMPROVED SPEED!
]]

-- USER AREA:
-- (Settings that the user can customize)

lanes_from_which_to_remove = "last clicked" -- "all", "last clicked" or "under mouse"
ignore_LSB_from_14bit_CCs  = true -- Ignore LSB when comparing pitchwheel events
only_analyze_selected = true -- Limit analysis and removal to selected events?
automatically_delete_muted_CCs = true -- Muted CCs are inherently redundant
show_error_messages = true

-- ask_confirmation_before_deletion -- not used yet in this version

-- End of USER AREA
-----------------------------------------------------------------


-----------------------------------------------------------------
-- Function to show error messages if show_error_messages == true
function showErrorMsg(errorMsg)
    if show_error_messages == true and type(errorMsg) == "string" then
        reaper.ShowMessageBox(errorMsg 
                              .. "\n\n"
                              .. "(To suppress future non-critical error messages, set 'show_error_messages' to 'false' in the USER AREA near the beginning of the script.)",
                              "ERROR", 0)    
    end
end  


-----------------------------
-- Code execution starts here

-- Various constants
local CCmsg = 11
local PITCHmsg = 14
local CHANPRESSmsg = 13

local PITCHlane = 0x201
local CHANPRESSlane = 0x203

local editor, take, targetLane

-- Trying a trick to prevent creation of new undo state 
--     if code does not reach own Undo_BeginBlock
function noUndo()
end
reaper.defer(noUndo)

-- Test whether user customizable parameters are usable
if lanes_from_which_to_remove ~= "under mouse" 
and lanes_from_which_to_remove ~= "last clicked" 
and lanes_from_which_to_remove ~= "all" then
    reaper.ShowMessageBox('The setting lanes_from_which_to_remove can only take on the values "under mouse", "last clicked" or "all".', "ERROR", 0)
    return(false) end
if type(ignore_LSB_from_14bit_CCs) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'ignore_LSB_from_14bit_CCs' can only take on the values 'true' or 'false'.", "ERROR", 0)
    return(false) end
if type(only_analyze_selected) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'only_analyze_selected' can only take on the values 'true' or 'false'.", "ERROR", 0)
    return(false) end
if type(automatically_delete_muted_CCs) ~= "boolean" then
    reaper.ShowMessageBox("The setting 'automatically_delete_muted_CCs' can only take on the values 'true' or 'false'.", "ERROR", 0)
    return(false) end
if type(show_error_messages) ~= "boolean" then    
    reaper.ShowMessageBox("The setting 'show_error_messages' can only take on the values 'true' or 'false'.", "ERROR", 0)
    return(false) end    
    
-- Test whether a MIDI editor and an active take are in fact available
editor = reaper.MIDIEditor_GetActive()
if editor == nil then 
    showErrorMsg("No active MIDI editor found.")
    return(false)
end
take = reaper.MIDIEditor_GetTake(editor)
if take == nil then 
    showErrorMsg("No active take in MIDI editor.")
    return(false)
end

-- Try to get lane info
if lanes_from_which_to_remove == "last clicked" then

    targetLane = reaper.MIDIEditor_GetSetting_int(editor, "last_clicked_cc_lane")
    if targetLane == -1 then
        showErrorMsg("No clicked lane found in MIDI editor.\n\n"
                    .."(Hint: To remove CCs from the lane under the mouse instead of the last clicked lane, "
                    .."change the 'lanes_from_which_to_remove' setting in the USER AREA to 'under mouse'.)")
        return(false)
    elseif not ((0 <= targetLane and targetLane <= 127) or targetLane == PITCHlane or targetLane == CHANPRESSlane) then
        showErrorMsg("This script only works in 7-bit CC lanes, pitchwheel or channel pressure lanes."
                    .."(Note: The choice of method for removing redundancies from 14-bit CC lanes will depend on the user's intent: "
                    .."For example, LSB information can be removed by simply deleting the CCs in the LSB lane.)")
        return(false)
    end
    
elseif lanes_from_which_to_remove == "under mouse" then

    _, _, currentDetails = reaper.BR_GetMouseCursorContext()
    if not (currentDetails == "cc_lane" or currentDetails == "cc_selector") then 
        showErrorMsg("Mouse is not over a CC lane.\n\n"
                   .."(Hint: To remove CCs from the last clicked lane instead of the lane under the mouse, "
                   .."change the 'lanes_from_which_to_remove' setting in the USER AREA to 'last clicked'.)")
        return(false)
    end
    
    -- SWS version 2.8.3 has a bug in the crucial function "BR_GetMouseCursorContext_MIDI()"
    -- https://github.com/Jeff0S/sws/issues/783
    -- For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
    _, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
    if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
    if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
    if SWS283 ~= SWS283again then
        reaper.ShowConsoleMsg("\n\nERROR:\nCould not determine compatible SWS version.\n")
        return(false)
    end
    
    if SWS283 == true then
        _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, _, _, targetLane, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end
    
    if targetLane == -1 then
        showErrorMsg("Could not determine lane under mouse.")
        return(false)
    elseif not ((0 <= targetLane and targetLane <= 127) or targetLane == PITCHlane or targetLane == CHANPRESSlane) then
        showErrorMsg("This script only works in 7-bit CC lanes, pitchwheel or channel pressure lanes.\n\n"
                    .."(Note: The choice of method for removing redundancies from 14-bit CC lanes will depend on the user's intent: "
                    .."For example, LSB information can be removed by simply deleting the CCs in the LSB lane.)")
        return(false)
    end    
    
end


-- Tests done and everything seems OK, so script can go ahead.  Start Undo block before doing MIDI_Sort.
reaper.Undo_BeginBlock()


----------------------------------------------------------------------------------------------
-- OK, now time to delete events within the active take
-- This script does not use the standard MIDI API functions such as MIDI_DeleteCC, since these
--    functions are far too slow when dealing with thousands of events.
-- Instead, this script will directly edit the raw MIDI data in the take's "state chunk".
-- More info on the formats can be found at 

local guidString, gotChunkOK, chunkStr, _, posTakeGUID, posAllNotesOff, posTakeMIDIend, posFirstStandardEvent, 
      posFirstExtendedEvent, posFirstSysex, posFirstMIDIevent

-- To find redundancies, all the MIDI data must be in proper sequence
reaper.MIDI_Sort(take)

-- All the MIDI data of all the takes in the item is stored within the "state chunk"
item = reaper.GetMediaItemTake_Item(take)
gotChunkOK, chunkStr = reaper.GetItemStateChunk(item, "", false)
if not gotChunkOK then
    reaper.ShowMessageBox("Could not access the item's state chunk.", "ERROR", 0)
    return
end

-- Use the take's GUID to find the beginning of the take's data within the state chunk of the entire item
guidString = reaper.BR_GetMediaItemTakeGUID(take)
_, posTakeGUID = chunkStr:find(guidString, 1, true)
if type(posTakeGUID) ~= "number" then
    reaper.ShowMessageBox("Could not find the take's GUID string within the state chunk.", "ERROR", 0)
    return
end

-- REAPER's MIDI takes all end with an All-Notes-Off message, "E offset B0 7B 00".
-- This line tries to find such a message (that is not followed by another MIDI event)
posAllNotesOff, posTakeMIDIend = chunkStr:find("\n[eE] %d+ [Bb]0 7[Bb] 00\n[^<xXeE]", posTakeGUID)
if posTakeMIDIend == nil then 
    reaper.ShowMessageBox("No end-of-take MIDI message found.", "ERROR", 0)
    return
end

-- Now find the very first MIDI message in the take's chunk.  This can be in standard format, extended format, of sysex format
posFirstStandardEvent = chunkStr:find("\n[eE]m? %-?%d+ %x%x %x%x %x%x[%-% %d]-\n", posTakeGUID)
posFirstSysex         = chunkStr:sub(1,posFirstStandardEvent+2):find("\n<[xX]m? %-?%d+ %-?%d+.->\n[<xXeE]", posTakeGUID)
if posFirstSysex == nil then posFirstSysex = posFirstStandardEvent end
posFirstExtendedEvent = chunkStr:sub(1,posFirstSysex+2):find("\n[xX]m? %-?%d+ %-?%d+ %x%x %x%x %x%x[%-% %d]-\n", posTakeGUID)
if posFirstExtendedEvent == nil then posFirstExtendedEvent = posFirstSysex end
posFirstMIDIevent = math.min(posFirstStandardEvent, posFirstExtendedEvent, posFirstSysex)
if posFirstMIDIevent >= posAllNotesOff then 
    reaper.ShowMessageBox("MIDI take appears to be empty.", "ERROR", 0)
    -- MIDI take is empty, so nothing to deselect!
    return
end      

-- To make all the search faster (and to prevent possible bugs)
--    the item's state chunk will be divided into three parts, with the middle part
--    exclusively the take's raw MIDI.
local chunkFirstPart = chunkStr:sub(1, posFirstMIDIevent-1)
local thisTakeMIDIchunk = chunkStr:sub(posFirstMIDIevent, posTakeMIDIend-1)
local chunkLastPart = chunkStr:sub(posTakeMIDIend)


-----------------------------------------------------------------------------------
-- OK, got the raw MIDI data, now iterate through all MIDI.
-- This code uses the Lua function string.gsub to iterate through the MIDI events, 
--    and at each step the "substitute" function is called to check the MIDI event.  
-- If the event is redundant, it is deleted by simply substituting an empty string.
-- Also crucial is that the MIDI offsets must be correctly maintained: When a MIDI
--    event is deleted, its offset will be added to the next remaining event's
--    offset.


-- Initialize tables
local tableLast = {} -- table with last values for each CC type and channel
tableLast.pitch = {}
for c = 0, 15 do -- initialize channels for MSB and LSB
    tableLast.pitch[c] = {}
end
tableLast.chanpress = {}
tableLast.CC = {}
for i = 0, 127 do -- initialize lanes for channels
    tableLast.CC[i] = {}
end

offsetChange = 0 -- This variable will be used by the deleteOrUpdateOffset
countRedundancies = 0

--------------------------------------------------------------------------
local function deleteOrUpdateOffset(line, selType, muted, offset, message)

    local doDelete = false
    local eventType, channel, msg2, msg3

    if only_analyze_selected == true and (selType == "E" or selType == "X") then
        goto skipChecks 
    elseif selType == "e" or selType == "E" then
        eventType, channel, msg2, msg3 = message:match("(%x)(%x) (%x%x) (%x%x)")
    elseif selType == "x" or selType == "X" then
        eventType, channel, msg2, msg3 = message:match("%d+ (%x)(%x) (%x%x) (%x%x)")
    else -- Sysex
        goto skipChecks
    end    
        
    if muted == "m" then muted = true else muted = false end
    offset    = tonumber(offset, 10)
    eventType = tonumber(eventType, 16)
    channel   = tonumber(channel, 16)
    msg2      = tonumber(msg2, 16)
    msg3      = tonumber(msg3, 16)
    if (not offset) or (not eventType) or (not channel) or (not msg2) or (not msg3) then
        reaper.ShowMessageBox("Parsing of state chunk MIDI data failed.", "ERROR", 0)
        return false
    end
        
    if (lanes_from_which_to_remove == "all" and
       (eventType == CCmsg or eventType == PITCHmsg or eventType == CHANPRESSmsg))
    or (lanes_from_which_to_remove ~= "all" and 
       ( (targetLane == msg2 and eventType == CCmsg) 
         or (targetLane == PITCHlane and eventType == PITCHmsg)
         or (targetLane == CHANPRESSlane and eventType == CHANPRESSmsg)))
    then
        if muted == true and automatically_delete_muted_CCs == true then
            doDelete = true
            
        elseif eventType == PITCHmsg then 
            if (ignore_LSB_from_14bit_CCs == true and msg3 == tableLast.pitch[channel].MSB)
            or (ignore_LSB_from_14bit_CCs == false and msg3 == tableLast.pitch[channel].MSB and msg2 == tableLast.pitch[channel].LSB)
            then
                doDelete = true
            else
                tableLast.pitch[channel].MSB = msg3 
                tableLast.pitch[channel].LSB = msg2
            end
            
        elseif eventType == CHANPRESSmsg then
            if tableLast.chanpress[channel] == msg2 then
                doDelete = true
            else
                tableLast.chanpress[channel] = msg2
            end
            
        elseif eventType == CCmsg then
            if tableLast.CC[msg2][channel] == msg3 then
                doDelete = true
            else
                tableLast.CC[msg2][channel] = msg3
            end
            
        end
            
    end
        
    ::skipChecks::
    if doDelete == true then
        countRedundancies = countRedundancies + 1
        offsetChange = offsetChange + offset
        return("")
    else        
        newOffset = tostring(offset + offsetChange)
        offsetChange = 0
        return line:gsub("%d+", newOffset, 1)
    end
end -- function deleteOrUpdateOffset


------------------------------------------------------
-- This single line iterates through all the MIDI data
local thisTakeMIDIedited = thisTakeMIDIchunk:gsub("(\n(<?[xXeE])(m?) (%d+) ([%-% %x]+))", deleteOrUpdateOffset)
    

reaper.SetItemStateChunk(item, chunkFirstPart .. thisTakeMIDIedited .. chunkLastPart, false)


-------------------------------------------
if lanes_from_which_to_remove == "all" then
    reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from all lanes", -1)    
else -- lanes_from_which_to_remove ~= "all" then
    if (0 <= targetLane and targetLane <= 127) then
        reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from 7-bit CC lane " .. tostring(targetLane), -1) 
    elseif targetLane == PITCHlane then
        reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from pitchwheel lane", -1) 
    elseif targetLane == CHANPRESSlane then
        reaper.Undo_EndBlock("Removed ".. tostring(countRedundancies) .. " redundant events from channel pressure lane", -1)  
    end
end

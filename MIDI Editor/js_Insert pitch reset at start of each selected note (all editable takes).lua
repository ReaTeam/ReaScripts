--[[
ReaScript name: js_Insert pitch reset at start of each selected note (all editable takes).lua
Version: 0.90
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Donation: https://www.paypal.me/juliansader
Provides: [main=midi_editor,midi_inlineeditor] .
About:
  # Description  
  
  Inserts a pitch reset event at the start of each selected note.  
  
  If the mouse is over a main MIDI editor or inline MIDI editor, the editor under the mouse will be used.  
  Otherwise (for example, if the mouse is over the action list), the last-focused main MIDI editor will be used.
  
  NOTE: Unlike most scripts, this script works on all editable takes.
  
  WARNING: Getting all editable takes requires a tricky workaround. This script should therefore be regarded as a BETA release.
]]
 
--[[
  Changelog:
  * v0.90 (2018-06-17)
    + Initial BETA release.
]]


-----------------------------------------------------
function getAllEditableTakesWithSelectedNotes(editor)

    local tTakes = {}

    -- Iterate through all takes, getting their MIDI data
    for i=0, reaper.CountMediaItems(0)-1 do 
    
        local curItem = reaper.GetMediaItem(0, i)
        if reaper.ValidatePtr2(0, curItem, "MediaItem*") then 
         
            for t=0, reaper.CountTakes(curItem)-1 do 
            
                local curTake = reaper.GetTake(curItem, t)    
                if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake) then 
                
                    gotDataOK, tTakes[curTake] = reaper.MIDI_GetHash(curTake, true, "")
                    if not gotDataOK then tTakes[curTake] = nil end
                    
                end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake)
            end -- for t=0, numTakes-1
        end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
    end -- for i=0, numItems-1
    
    --------------------------------------------------------------------------------------------------------
    -- Now apply some native action that is guaranteed to change something in all (relevant) editable takes.
    -- (Remember that some actions are only applied to the active take, not to all editable ones.)
    -- For example, here I use "Delet notes" to find editable takes with selected notes.
    reaper.Undo_BeginBlock2(0)
    reaper.MIDIEditor_OnCommand(editor, 40002) -- Delete notes (all editable takes)
    reaper.Undo_EndBlock2(0, "Deleted some selected notes", 0) -- Undo is bit unreliable, but this point should only be created if something was actually deleted    
    
    ------------------------------------------------------------------------------
    -- Now iterate through all takes again, comparing their old and new MIDI data.
    for take, oldMIDIdata in pairs(tTakes) do
        local gotDataOK, newMIDIdata = reaper.MIDI_GetHash(take, true, "")
        --reaper.ShowConsoleMsg("\n\nO: " .. oldMIDIdata .. "\nN: " .. newMIDIdata)
        if newMIDIdata == oldMIDIdata then
            -- If no change in take's MIDI, delete from table
            tTakes[take] = nil
        end
    end
    
    --------------------------------------------------
    lastUndoString = reaper.Undo_CanUndo2(0)
    if lastUndoString == "Deleted some selected notes" then -- Found something to delete
        reaper.Undo_DoUndo2(0)
        return tTakes
    else
        if next(tTakes) then -- Got changed takes but can't undo!
            reaper.ShowMessageBox("Error while trying to find all editable takes.", "ERROR", 0)
        end
        return false
    end
    
    
end


------------------------------------------------------
function main()
  
    -- Check whether SWS is available, as well as the required version of REAPER
    if not reaper.APIExists("MIDI_GetAllEvts") then
        reaper.ShowMessageBox("This version of the script requires REAPER v5.32 or higher."
                              .. "\n\nOlder versions of the script will work in older versions of REAPER, but may be slow in takes with many thousands of events"
                              , "ERROR", 0)
        return(false)
    elseif not reaper.APIExists("SN_FocusMIDIEditor") then
        reaper.ShowMessageBox("This script requires an up-to-date versions of the SWS/S&M extension.\n\nThe SWS/S&M extension can be downloaded from www.sws-extension.org.", "ERROR", 0)
        return(false) 
    end  
    
    -- Use MIDI editor under mouse. otherwise active (main) MIDI editor
    window, segment, details = reaper.BR_GetMouseCursorContext()
    if window == "midi_editor" then
        editor, isInline, mouseOrigPitch, mouseOrigCCLane, mouseOrigCCValue, mouseOrigCCLaneID = reaper.BR_GetMouseCursorContext_MIDI()
    else
        editor = reaper.MIDIEditor_GetActive()
    end
    
    if not isInline and not editor then
        reaper.ShowMessageBox("Could not detect a MIDI editor under the mouse.", "ERROR", 0)
        return(false)
    end
    
    -- Get all editable takes
    if isInline then
        take = reaper.BR_GetMouseCursorContext_Take()
        if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) then
            tTakes = {}
            tTakes[take] = true
        end
    else
        tTakes = getAllEditableTakesWithSelectedNotes(editor) 
        if not (type(tTakes) == "table") then return end
    end
    
    -- Parse MIDI and insert pitches!
    reaper.Undo_BeginBlock2(0)
    for take, _ in pairs(tTakes) do
        --reaper.ShowConsoleMsg(tostring(take))
        local MIDIOK, MIDI = reaper.MIDI_GetAllEvts(take, "")
        if MIDIOK then
            local pos, lastPos, ticks, offset, flags, msg = 1, 0, 0
            local tMIDI = {}
            while pos < #MIDI do
                offset, flags, msg, pos = string.unpack("i4Bs4", MIDI, pos)
                ticks = ticks+offset
                if flags&1 == 1 and #msg >= 3 then
                    if msg:byte(1)>>4 == 9 and msg:byte(3) ~= 0 then
                        local channel = msg:byte(1)&0x0F
                        tMIDI[#tMIDI+1] = MIDI:sub(lastPos+1, pos-#msg-6)
                        lastPos = pos-#msg-6
                        tMIDI[#tMIDI+1] = string.pack("Bi4BBBi4", 0, 3, 0xE0|channel, 0, 64, 0) -- Pitch reset, using origianl note's offset, and add offset=0 for note
                    end
                end
            end
            tMIDI[#tMIDI+1] = MIDI:sub(lastPos+1, nil)
            reaper.MIDI_SetAllEvts(take, table.concat(tMIDI))
        end
    end
    reaper.Undo_EndBlock2(0, "Insert pitch reset", -1)
end

-----------------------------------------------------
--###################################################
reaper.defer(function() end) -- Start with a trick to avoid automatically creating undo states if nothing actually happened
main()

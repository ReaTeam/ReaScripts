--[[
ReaScript name: js_Notation - Set displayed length of selected notes to custom value.lua
Version: 1.20
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=172782&page=25
About:
  # Description
  Sets the displayed length of selected notes (in the MIDI editor's notation view) 
  to a value that the user can specify in a popup window.
  
  # Forum thread 
  http://forum.cockos.com/showthread.php?t=172782&page=25
]]

--[[
Changelog:
  * v1.11 (2016-08-15)
    + If display length is set equal to MIDI length, the MIDI editor will regard the note's length as non-customized.
    + Improved accuracy of length calculation.
    + Script's About info compatible with ReaPack 1.1.
  * v1.20 (2016-08-15)
    + Bug fix for compatibility with takes that do not start at 0.
]]

---------------------------------------------------------------
-- Returns the textsysex index of a given note's notation info.
-- If no notation info is found, returns -1.
function getTextIndexForNote(take, notePPQ, noteChannel, notePitch)

    reaper.MIDI_Sort(take)
    _, _, _, countTextSysex = reaper.MIDI_CountEvts(take)
    if countTextSysex > 0 then 
    
        -- Use binary search to find text event closest to the left of note's PPQ        
        local rightIndex = countTextSysex-1
        local leftIndex = 0
        local middleIndex
        while (rightIndex-leftIndex)>1 do
            middleIndex = math.ceil((rightIndex+leftIndex)/2)
            local textOK, _, _, textPPQ, _, _ = reaper.MIDI_GetTextSysexEvt(take, middleIndex, true, false, 0, 0, "")
            if textPPQ >= notePPQ then
                rightIndex = middleIndex
            else
                leftIndex = middleIndex
            end     
        end -- while (rightIndex-leftIndex)>1
        
        -- Now search through text events one by one
        for i = leftIndex, countTextSysex-1 do
            local textOK, _, _, textPPQ, type, msg = reaper.MIDI_GetTextSysexEvt(take, i, true, false, 0, 0, "")
            -- Assume that text events are order by PPQ position, so if beyond, no need to search further
            if textPPQ > notePPQ then 
                break
            elseif textPPQ == notePPQ and type == 15 then
                textChannel, textPitch = msg:match("NOTE ([%d]+) ([%d]+)")
                if noteChannel == tonumber(textChannel) and notePitch == tonumber(textPitch) then
                    return i, msg
                end
            end   
        end
    end
    
    -- Nothing was found
    return(-1)
end

--------------------------------------
-- Here the code execution starts
-- function main()
editor = reaper.MIDIEditor_GetActive()
if editor ~= nil then
    take = reaper.MIDIEditor_GetTake(editor)
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") then    
                       
        -- Get user-specified displayed note length
        repeat
            retval, input = reaper.GetUserInputs("Set displayed note length", 
                                                      1,
                                                      "Note length (1/8 =Eighth note)",
                                                      "1/8") 
            input = tonumber(input:match("1/([%d]+)"))
        until retval == false or (type(input) == "number" and input>0)
        
        if retval == false then return(0) end
        
        -- Got length, now script can continue 
        reaper.Undo_BeginBlock2(0)

        -- Weird, sometimes REAPER's PPQ is not 960.  So first get PPQ of take.
        local QNstart = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
        PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, QNstart + 1) - reaper.MIDI_GetPPQPosFromProjQN(take, QNstart)
        userLength = (4.0/input)*PPQ -- Desired length of displayed notes in ticks
                    
        i = -1
        repeat
            i = reaper.MIDI_EnumSelNotes(take, i)
            if i ~= -1 then
                noteOK, _, _, noteStartPPQ, noteEndPPQ, channel, pitch, _ = reaper.MIDI_GetNote(take, i)
                -- Based on experimentation, it seems that the value of the "disp_len" field (in the notation
                --    editor's text events) represents (change in length)/(quarter note).
                difference = userLength - (noteEndPPQ - noteStartPPQ)
                textForField = " disp_len " .. string.format("%.3f", tostring(difference/PPQ))
                
                notationIndex, msg = getTextIndexForNote(take, noteStartPPQ, channel, pitch)
                if notationIndex == -1 and difference ~= 0 then
                    -- If note does not yet have notation info, create new event.
                    -- If display length is equal to MIDI length, don't need to do anything.
                    reaper.MIDI_InsertTextSysexEvt(take, true, false, noteStartPPQ, 15, "NOTE "
                                                                                        ..tostring(channel)
                                                                                        .." "
                                                                                        ..tostring(pitch)
                                                                                        ..textForField)
                else
                    -- Remove existing length tweaks and add own
                    msg = msg:gsub(" disp_len [%-]*[%d]+.[%d]+", "")
                    if difference ~= 0 then
                        msg = msg .. textForField
                    end
                    reaper.MIDI_SetTextSysexEvt(take, notationIndex, nil, nil, nil, nil, msg, false)
                end
            end
        until i == -1
        
        reaper.Undo_EndBlock2(0, "Notation - Set displayed length of selected notes", -1)
    end
end

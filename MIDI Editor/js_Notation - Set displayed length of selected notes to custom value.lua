--[[
ReaScript name: js_Notation - Set displayed length of selected notes to custom value.lua
Version: 2.3
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=172782&page=25
Donation: https://www.paypal.me/juliansader
About:
  # Description
  Sets the displayed length of selected notes (in the MIDI editor's notation view) 
  to a value that the user can specify in a popup window.
  
  The script can also be used to restore note display lengths to their true MIDI lengths, 
  by simply leaving the input field empty.
  
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
  * v1.21 (2016-09-02)
    + Allow more complex note values such as "0.75" or "3/8".
  * v1.3 (2021-09-08)
    + Script works on notes with existing notation (workaround for bug in MIDI_SetTextSysexEvt).
  * v2.0 (2021-09-09)
    + Works on all editable takes.
  * v2.1 (2021-09-10)
    + Empty input resets existing display length edits.
  * v2.2 (2021-09-10)
    + Added a bit of help text.
  * v2.3 (2021-10-15)
    + Faster determination of editable takes. 
]]

---------------------------------------------------------------
-- Returns the textsysex index of a given note's notation info.
-- If no notation info is found, returns -1.
function getTextIndexForNote(take, notePPQ, noteChannel, notePitch)

    if tT[take].numTextSysex > 0 then 
    
        -- Use binary search to find text event closest to the left of note's PPQ        
        local rightIndex = tT[take].numTextSysex-1
        local leftIndex = 0
        local middleIndex
        while (rightIndex-leftIndex)>1 do
            middleIndex = (rightIndex+leftIndex)//2
            local textOK, _, _, textPPQ, _, _ = reaper.MIDI_GetTextSysexEvt(take, middleIndex, true, false, 0, 0, "")
            if textPPQ >= notePPQ then
                rightIndex = middleIndex
            else
                leftIndex = middleIndex
            end     
        end -- while (rightIndex-leftIndex)>1
        
        -- Now search through text events one by one
        for i = leftIndex, tT[take].numTextSysex-1 do
            local textOK, _, _, textPPQ, textType, msg = reaper.MIDI_GetTextSysexEvt(take, i, true, false, 0, 0, "")
            -- Assume that text events are order by PPQ position, so if beyond, no need to search further
            if textPPQ > notePPQ then 
                break
            elseif textPPQ == notePPQ and textType == 15 then
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
if not editor then return end

-- Find all editable takes with selected notes
tT = {} -- Takes to edit
if reaper.MIDIEditor_EnumTakes then -- New function in v6.36
    for i = 0, math.huge do
        local editTake = reaper.MIDIEditor_EnumTakes(editor, i, true)
        if not editTake then 
            break
        elseif reaper.ValidatePtr(editTake, "MediaItem_Take*") and reaper.TakeIsMIDI(editTake) then -- Bug in EnumTakes and GetTake that sometimes returns invalid take should be fixed, but make doubly sure
            tT[editTake] = {item = reaper.GetMediaItemTake_Item(editTake)}
        end
    end
else
    for i = 0, reaper.CountMediaItems(0)-1 do
        local item = reaper.GetMediaItem(0, i)
        local take = reaper.GetActiveTake(item)
        if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) and reaper.MIDI_EnumSelNotes(take, -1) ~= -1 then
            tT[take] = {item = item}
        end
    end
    reaper.Undo_BeginBlock2(0)
    reaper.MIDIEditor_OnCommand(editor, 40214, false)
    reaper.Undo_EndBlock2(0, "qwerty", 0)
    for take in next, tT do
        if reaper.MIDI_EnumSelNotes(take, -1) ~= -1 then tT[take] = nil end
    end
    if reaper.Undo_CanUndo2(0) == "qwerty" then reaper.Undo_DoUndo2(0) end
end

if not next(tT) then return end
                        
                        
-- Get user-specified displayed note length
repeat
    OKorCancel, inputStr = reaper.GetUserInputs("Set displayed note length", 
                                              1,
                                              "Note length (1/8 = Eighth note)",
                                              "1/8") 
    if OKorCancel == false then 
        return
    elseif inputStr == "" or inputStr == "-" or inputStr == " " or inputStr == [[/]] then
        input = 0
    elseif type(tonumber(inputStr)) == "number" and tonumber(inputStr) > 0 then -- numbers such as 1 or 0.5, without "/"
        input = tonumber(inputStr)
    else -- Otherwise, check if note is in format of "1/8"
        numerator, divisor = inputStr:match("([%.%d]+)/([%.%d]+)")
        numerator = numerator and tonumber(numerator)
        divisor = divisor and tonumber(divisor)
        if type(numerator) == "number" and type(divisor) == "number" and numerator ~= 0 and divisor ~= 0 then
            input = (1.0/divisor)*numerator -- Is this more accurate than (numerator/divisor) ??
            if input > 5 then input = nil end
        end
    end
until input
        

-- Start editing!
reaper.Undo_BeginBlock2(0)

for take in next, tT do 

    reaper.MIDI_Sort(take) -- For binary search, MIDI must be sorted
    reaper.MIDI_DisableSort(take)
    tT[take].numTextSysex = ({reaper.MIDI_CountEvts(take)})[4]
    
    -- Display edits require PPQ of take.
    local PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, reaper.MIDI_GetProjQNFromPPQPos(take, 0) + 1)
    local userLength = (4.0*PPQ)*input -- Desired length of displayed notes in ticks
                
    local i = -1
    ::getNextSelNote:: do
        i = reaper.MIDI_EnumSelNotes(take, i)
        if i ~= -1 then
            local noteOK, _, _, noteStartPPQ, noteEndPPQ, channel, pitch, _ = reaper.MIDI_GetNote(take, i)
            -- Based on experimentation, it seems that the value of the "disp_len" field (in the notation
            --    editor's text events) represents (change in length)/(quarter note).
            difference = (input == 0) and 0 or (userLength - (noteEndPPQ - noteStartPPQ))
            textForField = " disp_len " .. string.format("%.3f", tostring(difference/PPQ))
            
            notationIndex, msg = getTextIndexForNote(take, noteStartPPQ, channel, pitch)
            if notationIndex == -1 then
                if difference ~= 0 then
                    reaper.MIDI_InsertTextSysexEvt(take, false, false, noteStartPPQ, 15, "NOTE "
                                                                                        ..tostring(channel)
                                                                                        .." "
                                                                                        ..tostring(pitch)
                                                                                        ..textForField)
                end
            else
                -- Remove existing articulation and length tweaks 
                msg = msg:gsub(" disp_len [%-]*[%d]+.[%d]+", "")
                if difference ~= 0 then
                    msg = msg .. textForField
                end
                reaper.MIDI_SetTextSysexEvt(take, notationIndex, nil, nil, nil, 15, msg, true)
            end
            goto getNextSelNote
        end
    end

    reaper.MIDI_Sort(take)
    reaper.MarkTrackItemsDirty(reaper.GetMediaItemTake_Track(take), tT[take].item)
end

undoText = (input == 0) and "Notation - Reset display length" or ("Notation - Set display length to "..inputStr)
reaper.Undo_EndBlock2(0, undoText, -1)

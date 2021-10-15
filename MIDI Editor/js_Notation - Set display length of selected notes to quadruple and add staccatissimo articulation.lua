--[[
ReaScript name: js_Notation - Set display length of selected notes to quadruple and add staccatissimo articulation.lua
Version: 2.1
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=172782&page=25
Donation: https://www.paypal.me/juliansader
About:
  # Description
  This script sets the notation displayed lengths of selected notes to four times their MIDI lengths, and then
  adds staccatissimo articulations.
  
  The script is intended to help solve the problem of short notes (such as staccato or muted guitar notes) 
  that are notated with extraneous rests in-between.
  
  Simply increasing the displayed length of the notes (by using the built-in action "Nudge length display 
  offset right", for example) will remove the rests, but then the displayed lengths will not accurately 
  reflect the lengths of the underlying MIDI notes.
  
  This script therefore adds staccatissimo articulations to indicate that the lengths of the underlying MIDI notes 
  are actually a fourth of the displayed length. (The standard interpretation of staccatissimo articulations is 
  to shorten notes to approximately one fourth of the original lengths.)
  
  # Forum thread
  http://forum.cockos.com/showthread.php?t=172782&page=25
]]

--[[
Changelog:
  * v1.2 (2016-08-15)
    + Initial release (derived from the "Set display length to double..." script)
  * v1.3 (2021-09-08)
    + Script works on notes with existing notation (workaround for bug in MIDI_SetTextSysexEvt).
  * v2.0 (2021-09-09)
    + Works on all editable takes.
  * v2.1 (2021-10-15)
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
reaper.Undo_BeginBlock2(0)

for take in next, tT do 

    reaper.MIDI_Sort(take) -- For binary search, MIDI must be sorted
    reaper.MIDI_DisableSort(take)
    tT[take].numTextSysex = ({reaper.MIDI_CountEvts(take)})[4]
    
    -- Display edits require PPQ of take.
    local PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, reaper.MIDI_GetProjQNFromPPQPos(take, 0) + 1)
                
    local i = -1
    ::getNextSelNote:: do
        i = reaper.MIDI_EnumSelNotes(take, i)
        if i ~= -1 then
            local noteOK, _, _, noteStartPPQ, noteEndPPQ, channel, pitch, _ = reaper.MIDI_GetNote(take, i)
            -- Based on experimentation, it seems that the value of the "disp_len" field (in the notation
            --    editor's text events) represents (change in length)/(quarter note).
            local textForField = string.format("%.3f", tostring(  3.0*(noteEndPPQ - noteStartPPQ)/PPQ  ))
            
            local notationIndex, msg = getTextIndexForNote(take, noteStartPPQ, channel, pitch)
            if notationIndex == -1 then
                reaper.MIDI_InsertTextSysexEvt(take, false, false, noteStartPPQ, 15, "NOTE "
                                                                                    ..tostring(channel)
                                                                                    .." "
                                                                                    ..tostring(pitch)
                                                                                    .." "
                                                                                    .."articulation staccatissimo disp_len "
                                                                                    ..textForField) -- if noSort, new events are added at end of stream, so doesn't affect binary search using original numTextSysex
                                                                                    
            else
                -- Remove existing articulation and length tweaks 
                msg = msg:gsub(" articulation [%a]+", "")
                msg = msg:gsub(" disp_len [%-]*[%d]+.[%d]+", "")
                msg = msg .." articulation staccatissimo disp_len "..textForField
                reaper.MIDI_SetTextSysexEvt(take, notationIndex, nil, nil, nil, 15, msg, true)
            end
            goto getNextSelNote
        end
    end

    reaper.MIDI_Sort(take)
    reaper.MarkTrackItemsDirty(reaper.GetMediaItemTake_Track(take), tT[take].item)
end

reaper.Undo_EndBlock2(0, "Notation - Set display length to quadruple and add staccatissimo articulation", -1)

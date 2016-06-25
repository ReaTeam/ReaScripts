--[[
 * ReaScript Name:  js_Split notes by drawing a line with the mouse
 * Description:  Split (slice) multiple notes by drawing a "cutting line" with the mouse in the MIDI editor piano roll.
 *               Notes that intersect the cutting line will be split at the position of intersection.
 *               If snap-to-grid is enabled in the MIDI editor, the notes will be split at the grid.
 *
 * Instructions:  The script must be linked to a shortcut key.  
 *                To use, position mouse in the 'notes' area of the piano roll, press the shortcut key once,
 *                      and then move the mouse to draw the cutting line.  
 *
 *                In the script's USER AREA (near the beginning of the script), the user can customize:
 *                    - The thickness of the cutting line
 *                    - Whether all notes or only selected notes should be split.
 *
 *                Note: Since this function is a user script, the way it responds to shortcut keys and 
 *                    mouse buttons is opposite to that of REAPER's built-in mouse actions 
 *                    with mouse modifiers:  To run the script, press the shortcut key *once* 
 *                    to start the script and then move the mouse *without* pressing any 
 *                    mouse buttons.  Press the shortcut key again once to stop the script.  
 *                (The first time that the script is stopped, REAPER will pop up a dialog box 
 *                    asking whether to terminate or restart the script.  Select "Terminate"
 *                    and "Remember my answer for this script".)
 *
 *                WARNING: - As with any ReaScript that involves moving or stretching notes, the user should
 *                           take care that there are no overlapping notes, both when starting and when
 *                           terminating the script, since such notes may lead to various artefacts.
 *                         - Even if there are no obviously overlapping notes, artefacts may still be encountered
 *                           during the drawing of the cutting line. This will not affect the eventual slicing of the notes.
 *                         - Glueing the MIDI item often helps to sort out the notes that cause artefacts.
 * Screenshot: 
 * Notes: 
 * Category: 
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: 
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 0.9
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]
 
--[[
 Changelog:
 * v0.9 (2016-06-24)
    + Initial beta release. (Bugs may be encountered.)
]] 

-- USER AREA
-- Settings that the user can customize

thicknessPPQ = 120 -- Thickness of the cutting line, in PPQs.  Quarter note = 960.

-- Should the script only slice selected notes, or should it slice any note
--    that intersects with the cutting line?
onlySliceSelectedNotes = false -- true or false

-- Searching through all notes in the take to find those that intersect with the cutting line 
--    may take several moments.  The script therefore limits its search to notes that start within
--    the following distance from the cutting line, which should be at least as long as the longest 
--    note that may need to be spliced.
wholeNotesInLongestNote = 8

-- End of USER AREA


---------------------------------------------------------
---------------------------------------------------------

function cutNotesLoop() 
        
    _, segment, _ = reaper.BR_GetMouseCursorContext()
    if segment ~= "notes" then -- easy way to quit is to move mouse out of "notes" area
        return(0)
    else
        mousePPQ = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5)
        if SWS283 == true then
            _, mouseNoteRow, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
        else 
            _, _, mouseNoteRow, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
        end            
        
        if isSnapEnabled ==1 then
            -- If snap is enabled, we must go through several steps to find the closest grid position
            --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
            -- !! Note that this script does not take swing into account when calculating the grid
            --QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
            local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQ) -- Mouse position in quarter notes
            local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
            mousePPQ = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) -- Snap enabled, so destination PPQ falls on grid 
        -- Otherwise, destination PPQ is exact mouse position
        end
        
        local minRow, minRowPPQ, maxRow, maxRowPPQ
        if noteRowStart <= mouseNoteRow then
            minRow = noteRowStart
            minRowPPQ = mousePPQstart
            maxRow = mouseNoteRow
            maxRowPPQ = mousePPQ
        else
            maxRow = noteRowStart
            maxRowPPQ = mousePPQstart
            minRow = mouseNoteRow
            minRowPPQ = mousePPQ
        end
        
        for row = 0, 127 do
            if row >= minRow and row <= maxRow then
                local ppq = math.floor(mousePPQstart + (mousePPQ-mousePPQstart)*(row-noteRowStart)/(mouseNoteRow-noteRowStart) + 0.5)
                if isSnapEnabled ==1 and row ~= noteRowStart and row ~= mouseNoteRow then
                    local QNpos = reaper.MIDI_GetProjQNFromPPQPos(take, ppq)
                    local roundGridQN = math.floor(QNpos/QNperGrid + 0.5)*QNperGrid
                    ppq = reaper.MIDI_GetPPQPosFromProjQN(take, roundGridQN) 
                end
                reaper.MIDI_SetNote(take, tableLine[row].index, true, false, ppq, ppq+thicknessPPQ, defaultChan, row, 1, true)
                tableLine[row].startppqpos = ppq
            else
                reaper.MIDI_SetNote(take, tableLine[row].index, true, false, mousePPQstart, mousePPQstart+thicknessPPQ, defaultChan, noteRowStart, 1, true)
            end
        end
                                     
    end  
    
    reaper.defer(cutNotesLoop)
end
  
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- This function is called when the script terminates
-- It deletes the line of notes, and then slices any note that crossed the line
function exit()

    -- First, move the line of notes to their original gap position, where they can be deleted 
    --    without causing artefacts with overlapping notes
    for row = 0, 127 do
        reaper.MIDI_SetNote(take, tableLine[row].index, true, false, gapPPQstart, gapPPQstart+1, defaultChan, gapPitch, 1, true)
    end    
    
    -- Use binary search to find event close to rightmost edge of notes to be deleted
    reaper.MIDI_Sort(take)
    _, numNotes3, _, _ = reaper.MIDI_CountEvts(take)        
    local rightIndex = numNotes3-1
    local leftIndex = 0
    while (rightIndex-leftIndex)>1 do
        middleIndex = math.ceil((rightIndex+leftIndex)/2)
        local _, _, _, startppqpos, _, _, _, _ = reaper.MIDI_GetNote(take, middleIndex)
        if startppqpos > gapPPQstart+1 then
            rightIndex = middleIndex
        else -- middlePPQpos <= startingPPQpos
            leftIndex = middleIndex
        end     
    end -- while (rightIndex-leftIndex)>1
    
    i = rightIndex
    repeat
        _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        if selected == true
        and muted == false
        and startppqpos == gapPPQstart
        and (endppqpos == gapPPQstart+1 or endppqpos == gapPPQstart) -- Sometimes the stacked notes cut each other off
        and chan == defaultChan
        and pitch == gapPitch
        and vel == 1
        then
            reaper.MIDI_DeleteNote(take, i)
            numNotes3 = numNotes3 - 1
            -- i does not get decremented, to ensure that index stays to right of notes to be deleted, in case sorting changes indices
            i = math.min(i, numNotes3-1)
        else
            i = i - 1
        end
    until startppqpos < gapPPQstart or i == -1

    reaper.MIDI_Sort(take)
    _, numNotes4, _, _ = reaper.MIDI_CountEvts(take) 
    if numNotes4 ~= numNotes then
        reaper.ShowConsoleMsg("\n\nERROR:\nCould not delete all the notes that were used to draw the line.") 
        return(false) 
    end
    
    -- If the script was terminated by moving the mouse out of the piano roll notes area, don't do anything else besides removing the line notes
    if segment == "notes" then
        -- Now that the line note are deleted, the script must find all notes that crossed the line and that should therefore be sliced
        -- Use binary search to find event close to rightmost edge of line    
        local rightmostCutPPQ = math.max(mousePPQstart, mousePPQ)
        local rightIndex = numNotes4-1
        local leftIndex = 0
        while (rightIndex-leftIndex)>1 do
            middleIndex = math.ceil((rightIndex+leftIndex)/2)
            local _, _, _, startppqpos, _, _, _, _ = reaper.MIDI_GetNote(take, middleIndex)
            if startppqpos > rightmostCutPPQ then
                rightIndex = middleIndex
            else -- middlePPQpos <= startingPPQpos
                leftIndex = middleIndex
            end     
        end -- while (rightIndex-leftIndex)>1
        
        -- Find all the notes that cross the slice line, and
        --    store the info of the notes in a table, so that new notes can be inserted with the same pitch, channel, etc
        tableCut = {}
        leftIndex = reaper.MIDI_EnumSelNotes(take, -1)
        if onlySliceSelectedNotes == false or leftIndex < 0 then 
            leftIndex = 0
        end
        local minRow = math.min(noteRowStart, mouseNoteRow)
        local maxRow = math.max(noteRowStart, mouseNoteRow)
        local leftmostEdgePPQ = math.min(mousePPQstart, mousePPQ) - wholeNotesInLongestNote*3840 -- 3840=960*4=length of whole note in PPQs
        --local rightmostCutPPQ = math.max(mousePPQstart, mousePPQ) 
        
        for i = rightIndex, leftIndex, -1 do
            local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
            if pitch >= minRow and pitch <= maxRow 
            and (onlySliceSelectedNotes == false or (onlySliceSelectedNotes == true and selected == true)) 
            then
                local cutppqpos = tableLine[pitch].startppqpos -- + thicknessPPQ/2
                if endppqpos > cutppqpos and startppqpos < cutppqpos then
                    table.insert(tableCut, {index=i, 
                                            selected=selected, 
                                            muted=muted, 
                                            cutppqpos=cutppqpos,
                                            endppqpos=endppqpos, 
                                            chan=chan, 
                                            pitch=pitch, 
                                            vel=vel})
                    reaper.MIDI_SetNote(take, i, nil, nil, nil, cutppqpos, nil, nil, nil, true)
                end
            end
            if startppqpos < leftmostEdgePPQ then break end
        end
        
        -- Insert new notes (second part of each sliced note)
        for i = 1, #tableCut do
            reaper.MIDI_InsertNote(take, tableCut[i].selected, tableCut[i].muted, tableCut[i].cutppqpos, tableCut[i].endppqpos, tableCut[i].chan, tableCut[i].pitch, tableCut[i].vel, true)     
        end
        
    end -- if segment == "notes"      
    
    if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
        reaper.SetToggleCommandState(sectionID, cmdID, 0)
        reaper.RefreshToolbar2(sectionID, cmdID)
    end
    
    reaper.Undo_OnStateChange("Split notes by drawing a line with the mouse")
    
end

----------------------------------------------------------------------
----------------------------------------------------------------------
-- Here starts the execution of the script
-- function main()
function preventUndo()
end
reaper.defer(preventUndo)

-- First, do some tests to check whether the user settings are acceptable, and whether there is an active MIDI editor and notes to cut.
if type(thicknessPPQ) ~= "number" or thicknessPPQ <= 0 then
    reaper.ShowConsoleMsg("\n\nERROR:\nThe 'thicknessPPQ' setting should be a number larger than 0.")
    return(false)
elseif type(onlySliceSelectedNotes) ~= "boolean" then
    reaper.ShowConsoleMsg("\n\nERROR:\nThe 'onlySliceSelectedNotes' setting should be either true or false.")
    return(false)
end

editor = reaper.MIDIEditor_GetActive()
if editor == nil then return(0) end
take = reaper.MIDIEditor_GetTake(editor)
if take == nil then return(0) end
_, segment, _ = reaper.BR_GetMouseCursorContext()
if segment ~= "notes" then return(0) end

reaper.MIDI_Sort(take) -- First sort, hopefully to sort out overlapping and other illegal notes
_, numNotes, _, _ = reaper.MIDI_CountEvts(take)
if numNotes <= 0 then return(0) end

-- Get the starting position of the mouse
--[[ NOTE:
SWS version 2.8.3 has a bug in the crucial action "BR_GetMouseCursorContext_MIDI()"
https://github.com/Jeff0S/sws/issues/783
For compatibility with 2.8.3 as well as other versions, the following lines test the SWS version for compatibility
Supposed to be: identifier retval, boolean inlineEditorOut, number noteRowOut, number ccLaneOut, number ccLaneValOut, number ccLaneIdOut reaper.BR_GetMouseCursorContext_MIDI()
]]
_, testParam1, _, _, _, testParam2 = reaper.BR_GetMouseCursorContext_MIDI()
if type(testParam1) == "number" and testParam2 == nil then SWS283 = true else SWS283 = false end
if type(testParam1) == "boolean" and type(testParam2) == "number" then SWS283again = false else SWS283again = true end 
if SWS283 ~= SWS283again then
    reaper.ShowConsoleMsg("\n\nERROR:\nCould not determine compatible SWS version.")
    return(false)
end
if SWS283 == true then
    isInline, noteRowStart, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, isInline, noteRowStart, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
end
if isInline == true then return(0) end


-- OK, tests are completed.  
-- Now can specify atexit function, which will create an undo point when the function exits.
-- And toggle toolbar button (if any).
reaper.atexit(exit)

_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

--local mousePosStart = reaper.BR_GetMouseCursorContext_Position()
mousePPQstart = math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5)
isSnapEnabled = reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")
if isSnapEnabled==1 then
    -- If snap is enabled, we must go through several steps to find the closest grid position
    --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
    -- !! Note that this script does not take swing into account when calculating the grid
    QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
    local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQstart) -- Mouse position in quarter notes
    local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
    mousePPQstart = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) -- Snap enabled, so destination PPQ falls on grid 
-- Otherwise, destination PPQ is exact mouse position
end

-------------------------------------------------------------------------------------
-- Now the script must insert the notes that will later be moved into the line
-- Since inserting overlapping notes can lead to weird artefact, this script 
--    will try to find a gap somewhere where 128 notes can be inserted.
-- Once inserted, the notes can be moved into new positions without causing problems.
-- (This search doesn't bother with channels.)
reaper.MIDI_Sort(take)

local tableEnds = {} -- table of last note PPQ ends for each note pitch
for pitch = 0, 127 do
    tableEnds[pitch] = 0
end
minEnd = 0
minEndPitch = 64

for i = 0, numNotes-1 do
    minEnd = math.huge
    for pitch = 0, 127 do
        if tableEnds[pitch] < minEnd then
            minEnd = tableEnds[pitch]
            minEndPitch = pitch
        end
    end
    local _, _, _, startppqpos, endppqpos, chan, pitch, _ = reaper.MIDI_GetNote(take, i)
    if startppqpos - minEnd > 128 then
        gapFound = true
        gapPitch = minEndPitch
        gapPPQstart = minEnd
        break
    elseif endppqpos > tableEnds[pitch] then
        tableEnds[pitch] = endppqpos
    end
end

if gapFound ~= true then
    reaper.ShowConsoleMsg("\n\nERROR:\nCould not find a gap into which the notes could be inserted.") 
    return(false) 
end

-- Gap was found, now insert 128 notes (1 for each pitch) into the gap
defaultChan = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
for i = 0, 127 do
    retval = reaper.MIDI_InsertNote(take, true, false, gapPPQstart+i, gapPPQstart+i+1, defaultChan, gapPitch, 1, true)
    if retval == false then 
        reaper.ShowConsoleMsg("\n\nERROR:\nCould not insert notes with which to draw line.") 
        return(false) 
    end
end

reaper.MIDI_Sort(take)
_, numNotes2, _, _ = reaper.MIDI_CountEvts(take)
if numNotes2 ~= numNotes+128 then
    reaper.ShowConsoleMsg("\n\nERROR:\nNotes went missing after running MIDI_Sort")
    return(false)
end

-- Now must find the newly inserted notes' indices
-- The notes' indices as well as their starting PPQ positions (i.e. the cutting positions for each pitch) 
--    will be stored in the table tableLine.

-- Use binary search to find event close to newly inserted notes
rightIndex = numNotes2-1
leftIndex = 0
while (rightIndex-leftIndex)>1 do
    middleIndex = math.ceil((rightIndex+leftIndex)/2)
    local _, _, _, startppqpos, _, _, _, _ = reaper.MIDI_GetNote(take, middleIndex)
    if startppqpos > gapPPQstart+128 then
        rightIndex = middleIndex
    else -- middlePPQpos <= startingPPQpos
        leftIndex = middleIndex
    end     
end -- while (rightIndex-leftIndex)>1

tableLine = {}
local i = rightIndex
repeat
    local _, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if pitch == gapPitch
    and endppqpos == startppqpos+1
    and selected == true
    and muted == false 
    and chan == defaultChan
    and vel == 1
    then
        table.insert(tableLine, {index=i, startppqpos=startppqpos})
    end
    i = i - 1
until #tableLine == 128 or startppqpos < gapPPQstart or i == -1

if #tableLine ~= 128 then
    reaper.ShowConsoleMsg("\n\nERROR:\nCould not find all the notes after inserting into gap.")
    return(false)
end

-- REAPER's pitches stretch from 0 to 127, not 1 to 128, so adjust tableLine
tableLine[0] = tableLine[128]
tableLine[128] = nil

-- And finally, we have got the indices of 128 notes that will be moved around to form the line.  Can now call the loop.
cutNotesLoop()


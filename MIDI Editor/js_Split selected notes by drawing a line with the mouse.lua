--[[
 * ReaScript Name:  js_Split selected notes by drawing a line with the mouse.lua
 * Description:  Split (slice) multiple selected notes by drawing a "cutting line" with the mouse in the MIDI editor piano roll.
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
 * Version: 0.93
 * REAPER: 5.20
 * Extensions: SWS/S&M 2.8.3
]]
 
--[[
 Changelog:
 * v0.9 (2016-06-24)
    + Initial beta release. (Bugs may be encountered.)
 * v0.91 (2016-06-25)
    + A few tweaks.
 * v0.92 (2016-06-26)
    + Beta 3: Fixed "Could not find gap" bug.
 * v0.93 (2016-06-27)
    + Implemented workaround for bug in MIDI_SetNote().
    + WARNING: The script is still in beta, and may be unstable.
]] 

-- USER AREA
-- Settings that the user can customize

thicknessPPQ = 60 -- Thickness of the cutting line, in PPQs.  Quarter note = 960.

-- Should the script only slice selected notes, or should it slice any note
--    that intersects with the cutting line?
onlySliceSelectedNotes = true -- true or false

-- Searching through all notes in the take to find those that intersect with the cutting line 
--    may take several moments.  The script therefore limits its search to notes that start within
--    the following distance from the cutting line, which should be at least as long as the longest 
--    note that may need to be spliced.
wholeNotesInLongestNote = 8

-- End of USER AREA


--------------------------------------------------------------------------------
-- The function that gets 'deferred' and that draws the cutting line in realtime
--------------------------------------------------------------------------------
function cutNotesLoop() 
        
    -- easy way to quit is to move mouse out of "notes" area
    _, segment, _ = reaper.BR_GetMouseCursorContext()
    if segment ~= "notes" then 
        return(0)
    end
    
    -- Get the new mouse position
    mousePPQ = math.max(0, math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5))
    if SWS283 == true then
        _, mouseRow, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    else 
        _, _, mouseRow, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
    end            
    
    if isSnapEnabled ==1 then
        -- If snap is enabled, we must go through several steps to find the closest grid position
        --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
        -- !! Note that this script does not take swing into account when calculating the grid
        --QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
        local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, mousePPQ) -- Mouse position in quarter notes
        local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
        mousePPQ = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) -- Snap enabled, so destination PPQ falls on grid 
    -- Otherwise, PPQ is exact mouse position
    end
    
    -- Only re-draw line if mouse position has actually changed
    if mousePPQ ~= prevPPQ or mouseRow ~= prevRow then
        
        prevPPQ = mousePPQ
        prevRow = mouseRow
        
        local minRow, maxRow
        if startRow <= mouseRow then
            minRow = startRow
            maxRow = mouseRow
        else
            maxRow = startRow
            minRow = mouseRow
        end
        
        for row = 0, 127 do
            if row >= minRow and row <= maxRow and mouseRow ~= startRow then
                local ppq = math.floor(startPPQ + (mousePPQ-startPPQ)*(row-startRow)/(mouseRow-startRow) + 0.5)
                if isSnapEnabled ==1 and row ~= startRow and row ~= mouseRow then
                    -- Note that the line snaps to closest grid, not the floor grid
                    local QNpos = reaper.MIDI_GetProjQNFromPPQPos(take, ppq)
                    local roundGridQN = math.floor(QNpos/QNperGrid + 0.5)*QNperGrid
                    ppq = reaper.MIDI_GetPPQPosFromProjQN(take, roundGridQN) 
                end
                reaper.MIDI_SetNote(take, tableLine[row].index, true, false, ppq, ppq+thicknessPPQ, tableChans[row], row, 1, true)
                tableLine[row].startppqpos = ppq
            else
                reaper.MIDI_SetNote(take, tableLine[row].index, true, false, startPPQ, startPPQ+thicknessPPQ, tableChans[startRow], startRow, 1, true)
            end
        end
                                     
    end  
    
    reaper.defer(cutNotesLoop)
end
  

----------------------------------------------------------------------------------
-- This function is called when the script terminates
-- It deletes the line of notes, and then slices any note that intersects the line
----------------------------------------------------------------------------------
function exit()

    -- IF and only if the table of notes have been created, move them to their original gap position,
    --    where they can be deleted without causing artefacts with overlapping notes
    if type(tableLine) == "table" then
        for row = 0, #tableLine do
            if tableLine[row] ~= nil then
                reaper.MIDI_SetNote(take, tableLine[row].index, true, false, gapPPQstart+row, gapPPQstart+row+1, tableChans[gapPitch], gapPitch, 1, true) 
            end
        end    
    end
        
    -- Now, clean up any notes that may be in the gap
    -- Since the gap is assumed to be very near the start of the take, it is not necessary
    --    to use a binary search to find a 'seed' note close to gap.  Simply start at the beginning.
    reaper.MIDI_Sort(take)
    _, numNotesAfterMovingBack, _, _ = reaper.MIDI_CountEvts(take)
    
    i = 0
    isBeyond = false
    while i < numNotesAfterMovingBack and isBeyond == false do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
        if retval == false then
            i = i + 1
        elseif startppqpos > gapPPQstart+128 then
            isBeyond = true -- break
        elseif pitch == gapPitch -- Is it necessary to test all the other stuff?  There are not supposed to be any other notes in th gap
            --and selected == true
            --and muted == false
            and startppqpos >= gapPPQstart
            -- and startppqpos <= gapPPQstart+128
            -- and (endppqpos == gapPPQstart+1 ? -- 
            -- and chan == defaultChan
            --and vel == 1
            then
            reaper.MIDI_DeleteNote(take, i)
            numNotesAfterMovingBack = numNotesAfterMovingBack - 1
            -- Reset the index so that start again from left of new notes
            -- (just to make sure that there are no shenanigans when REAPER re-sort the indices after deletion)
            i = 0
        else
            i = i + 1
        end
    end
      
    reaper.MIDI_Sort(take)
    _, numNotesAfterDeletion, _, _ = reaper.MIDI_CountEvts(take) 
    if numNotesAfterDeletion ~= numNotes then
        reaper.ShowConsoleMsg("\n\nERROR:\nThe number of notes in the take appears to have changed. Possible causes include:"
                              .."\n\n  * Unexpected actions (such as mouse clicks) during execution of the script, which may change the numbering of the MIDI notes."
                              .."\n\n  * Unstable notes (most likely overlapping notes), which get re-configured when REAPER runs a ReaScript."
                              .."\n\n  * Bug in the reaper.MIDI_Sort function."
                              .."\n\nPlease check whether any extraneous notes remain near the start of the take, in pitch "
                              ..tostring(gapPitch)..".") 
    end
    
    -- If the script was terminated by moving the mouse out of the piano roll notes area, don't do anything else besides removing the line notes
    if segment=="notes" and type(tableLine)=="table" and mousePPQ~=nil and mouseRow~=nil then
        -- Now that the line note are deleted, the script must find all notes that crossed the line 
        --    and that should therefore be sliced.
        -- Use binary search to find event close to rightmost edge of line.
        local rightmostCutPPQ = math.max(startPPQ, mousePPQ)
        local rightIndex = numNotesAfterDeletion-1
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
        local minRow = math.min(startRow, mouseRow)
        local maxRow = math.max(startRow, mouseRow)
        local leftmostEdgePPQ = math.min(startPPQ, mousePPQ) - wholeNotesInLongestNote*3840 -- 3840=960*4=length of whole note in PPQs
        --local rightmostCutPPQ = math.max(startPPQ, mousePPQ) 
        
        for i = rightIndex, leftIndex, -1 do
            local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
            if retval == true
            and pitch >= minRow and pitch <= maxRow 
            and (onlySliceSelectedNotes == false or (onlySliceSelectedNotes == true and selected == true)) 
            then
                local cutppqpos = tableLine[pitch].startppqpos -- + thicknessPPQ/2
                if cutppqpos~=nil and endppqpos > cutppqpos and startppqpos < cutppqpos then
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
if numNotes < 0 then return(0) end

-----------------------------------------------------------------------------------
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
    isInline, startRow, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
else 
    _, isInline, startRow, _, _, _ = reaper.BR_GetMouseCursorContext_MIDI()
end
if isInline == true or startRow < 0 or startRow > 127 then return(0) end

startPPQ = math.max(0, math.floor(reaper.MIDI_GetPPQPosFromProjTime(take, reaper.BR_GetMouseCursorContext_Position()) + 0.5))
isSnapEnabled = reaper.MIDIEditor_GetSetting_int(editor, "snap_enabled")
if isSnapEnabled==1 then
    -- If snap is enabled, we must go through several steps to find the closest grid position
    --     immediately before (to the left of) the mouse position, aka the 'floor' grid.
    -- !! Note that this script does not take swing into account when calculating the grid
    QNperGrid, _, _ = reaper.MIDI_GetGrid(take) -- Quarter notes per grid
    local mouseQNpos = reaper.MIDI_GetProjQNFromPPQPos(take, startPPQ) -- Mouse position in quarter notes
    local floorGridQN = (mouseQNpos//QNperGrid)*QNperGrid -- last grid before mouse position
    startPPQ = reaper.MIDI_GetPPQPosFromProjQN(take, floorGridQN) -- Snap enabled, so destination PPQ falls on grid 
-- Otherwise, starting PPQ is exact mouse position
end

-- function findGapAndChannels()
------------------------------------------------------------------------------------------
-- Since inserting overlapping notes can lead to weird artefact, this script will instead
--    draw the 'cutting line' by first inserting 128 notes in a gap somewhere where 
--    there are no existing notes, before 
--    will try to find a gap somewhere where 128 notes can be inserted (1 for each pitch).
-- Once inserted, the notes can be moved into new positions without causing problems.
-- (This search doesn't bother with channels.)

-- reaper.MIDI_Sort(take) -- Sorting was already done above
local tableEnds = {} -- table of last note PPQ ends for each note pitch
for pitch = 0, 127 do
    tableEnds[pitch] = 0
end
minEnd = 0
minEndPitch = 0

-- There is a bug in MIDI_SetNote that causes notes close to the beginning of
--    a take to be extended if another note in the same channel is set to the same pitch.
--    This table will temporarily store the channels of such early notes, and will
--    then later store the 'safe' channel for each pitch.
tableChans = {} 

for i = 0, numNotes-1 do
    -- Find current pitch with minimum note end
    minEnd = math.huge
    for pitch = 0, 127 do
        if tableEnds[pitch] < minEnd then
            minEnd = tableEnds[pitch]
            minEndPitch = pitch
        end
    end

    local _, _, _, startppqpos, endppqpos, chan, pitch, _ = reaper.MIDI_GetNote(take, i)
    
    if type(tableChans[pitch]) ~= "table" then 
        tableChans[pitch] = {}
    end
    table.insert(tableChans[pitch], chan)
         
    -- Since MIDI is sorted by startppqpos, if any note is more than 128 PPQ away from minEnd, 
    --    minEndPitch's next note would also be farther away
    if startppqpos - minEnd > 128 then
        gapFound = true
        gapPitch = minEndPitch
        gapPPQstart = minEnd
        break
    elseif endppqpos > tableEnds[pitch] then
        tableEnds[pitch] = endppqpos
    end
    
end

if gapFound ~= true then -- This may happen, for example, if only one note in take and note starts at 0 
    -- So there is not a gap between minEnd and start of some note, but check whether there is a gap to end of take
    -- Does REAPER's MIDI items have a minimum length of 1/16 note?
    minEnd = math.huge
    for pitch = 0, 127 do
        if tableEnds[pitch] < minEnd then
            minEnd = tableEnds[pitch]
            minEndPitch = pitch
        end
    end
    
    source = reaper.GetMediaItemTake_Source(take)
    sourceLengthQN, lengthIsQN = reaper.GetMediaSourceLength(source)
    if type(lengthIsQN) ~= "boolean" then
        reaper.ShowConsoleMsg("\n\nERROR:\nCould not determine length of take.") 
        return(false)
    end
    if lengthIsQN == false then
        takeStartTime = reaper.MIDI_GetProjTimeFromPPQPos(take, 0)
        sourceLengthQN = reaper.MIDI_GetPPQPosFromProjTime(take, takeStartTime + sourceLengthQN)
    end
    if minEnd + 128 < sourceLengthQN * 960 then
        gapFound = true
        gapPitch = minEndPitch
        gapPPQstart = minEnd
    else
        reaper.ShowConsoleMsg("\n\nERROR:\nCould not find a gap into which the notes could be inserted.") 
        return(false) 
    end
end -- if gapFound ~= true

defaultChan = reaper.MIDIEditor_GetSetting_int(editor, "default_note_chan")
for i = 0, 127 do
    if type(tableChans[i]) ~= "table" then 
        tableChans[i] = defaultChan
    else
        canUseDefault = true
        for j = 0, #tableChans[i] do
            if tableChans[i][j] == defaultChan then canUseDefault = false end
        end
        
        if canUseDefault == true then
            tableChans[i] = defaultChan
        else
            -- Cannot use default, then search through all other channels for one to use
            for seekChannel = 0, 15 do
                canUseChannel = true
                for j = 0, #tableChans[i] do
                    if tableChans[i][j] == seekChannel then canUseChannel = false end
                end
                if canUseChannel == true then
                    tableChans[i] = seekChannel
                    break
                end
            end
        end
    end
end
for row, chan in pairs(tableChans) do
    if type(chan) ~= "number" then 
        reaper.ShowConsoleMsg("\n\nERROR:\nCould not set up the insert channels."
                              .."\n\nThis is likely due to an unusual occurrence of mulitple notes, at least one in each of the 16 MIDI channels, squashed together near the beginning of the take, all in pitch ".. tostring(row) ..".") 
        return(false) 
    end
end

-- end -- function findGapAndChannels()

------------------------------------------------------------------------------------------------------------------
-- The preliminaries and tests are now completed, and the script will now begin to make changes to the take.
-- However, atexit() will not yet be defined, since any errors at this stage should rather be dealt with manually.
------------------------------------------------------------------------------------------------------------------

-- Now the script must insert the notes that will later be moved into the line
-- Gap was found, now insert 128 notes (1 for each pitch) into the gap

for i = 0, 127 do
    retval = reaper.MIDI_InsertNote(take, true, false, gapPPQstart+i, gapPPQstart+i+1, tableChans[gapPitch], gapPitch, 1, true)
    if retval == false then 
        reaper.ShowConsoleMsg("\n\nERROR:\nFailure while calling reaper.MIDI_InsertNote.\n\n"
                              ..tostring(i).." note(s) have been moved to the beginning of the take, at pitch ".. tostring(gapPitch) .."."
                              .."\nPlease remove these manually.") 
        reaper.Undo_OnStateChange("Split notes: Failed") 
        return(false) 
    end
end

reaper.MIDI_Sort(take)
_, numNotesAfterInsertion, _, _ = reaper.MIDI_CountEvts(take)
if numNotesAfterInsertion ~= numNotes+128 then
    reaper.ShowConsoleMsg("\n\nERROR:\nThe number of notes in the take was changed incorrectly after inserting notes and calling MIDI_Sort."
                          .."\n\nThis is most likely caused by unstable notes (such as overlapping notes), which are incompatible with ReaScripts."
                          .."\n\nThe script will now quit, and has moved all newly inserted notes to the beginning of the take, in pitch "..tostring(gapPitch)
                          .." - please remove these manually")
    reaper.Undo_OnStateChange("Split notes: Failed")
    return(false)
end

-- Now must find the newly inserted notes' indices
-- The notes' indices as well as their starting PPQ positions (i.e. the cutting positions for each pitch) 
--    will be stored in the table tableLine.
tableLine = {}

for i = 0, numNotesAfterInsertion-1 do
    local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
    if retval == false then
        -- nothing
    elseif startppqpos > gapPPQstart+128 then 
        break
    elseif selected == true
    and muted == false 
    and startppqpos >= gapPPQstart
    and endppqpos == startppqpos+1
    and pitch == gapPitch
    and chan == tableChans[gapPitch]
    and vel == 1
    then
        table.insert(tableLine, {index=i, startppqpos=startppqpos})
    end
end
    
if #tableLine ~= 128 then
    reaper.ShowConsoleMsg("\n\nERROR:\nCould not find all new notes after insertion."
                          .."\n\nThis is most likely caused by unstable notes (such as overlapping notes), which are incompatible with ReaScripts."
                          .."\n\nThe script will now quit, and has moved all newly inserted notes to the beginning of the take, in pitch "..tostring(gapPitch)
                          .." - please remove these manually")
    reaper.Undo_OnStateChange("Split notes: Failed")    
    return(false)
end

-- REAPER's pitches stretch from 0 to 127, not 1 to 128, so adjust tableLine
--tableLine[0] = tableLine[128]
tableLine[0] = {}
tableLine[0].index = tableLine[128].index
tableLine[0].startppqpos = tableLine[128].startppqpos
tableLine[128] = nil

--------------------------------------------------------------------------------------------
-- OK, tests are completed.  
-- Now can specify atexit function, which will create an undo point when the function exits.
-- And toggle toolbar button (if any).
reaper.atexit(exit)

_, _, sectionID, cmdID, _, _, _ = reaper.get_action_context()
if sectionID ~= nil and cmdID ~= nil and sectionID ~= -1 and cmdID ~= -1 then
    reaper.SetToggleCommandState(sectionID, cmdID, 1)
    reaper.RefreshToolbar2(sectionID, cmdID)
end

-- And finally, we have got the indices of 128 notes that will be moved around to form the line.  Can now call the loop.
cutNotesLoop()


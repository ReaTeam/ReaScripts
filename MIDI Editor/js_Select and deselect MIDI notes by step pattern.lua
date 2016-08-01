--[[
 * ReaScript Name:  js_Select and deselect MIDI notes by step pattern.lua
 * Description: This script selects and deselects notes, based on a step pattern that the user can draw in a GUI.
 *              For example, the pattern can be drawn to select notes 1, 3 and 4 in a six-step pattern.
 *              The length of the pattern as well as the steps that will be selected/deselected are determined by the user.
 *              Notes that start within one grid length of each are regarded as one chord (or glissando), and will be selected/deselected together.
 *
 * Instructions: First, select the note on which the step pattern must be applied.  
 *              (Of course, some of these notes will be deselected by the script.)
 *              Then, run the script and draw the desired pattern - the note selection will be updated in real time.
 *              When you need to work with a new set of notes, simply click the "Load new set of notes" text.
 *              
 *              If no notes are selected when the script is started, or if the indices of the notes in the take change 
 *                  (for example, if notes are added to or deleted from the take), the script will dim out the step 
 *                  pattern display, and wait for the user to load a new set of notes.
 *
 *              HINTS: ~ This script works well with the "js_Deselect all notes outside time selection (from all 
 *                         takes).lua" script.  Use the piano roll keys to select all notes in a range of pitches, and
 *                         then run the Deselect script to limit the note selection to the time selection.
 *                     ~ If it seems that the script does not apply the correct pattern, check the MIDI editor's grid
 *                         setting. Most likely the grid length is longer than the distance between the notes' start
 *                         positions, so the script regards all these notes as a single chord or glissando.
 *                  
 * Screenshot: 
 * Notes: 
 * Category: MIDI editor
 * Author: juliansader
 * Licence: GPL v3
 * Forum Thread: Simple but useful MIDI editor tools: warp, stretch, deselect etc
 * Forum Thread URL: http://forum.cockos.com/showthread.php?t=176878
 * Version: 0.9
 * REAPER: 5.20
 * Extensions:
]]
 
--[[
 Changelog:
 * v0.9 (2016-08-01)
    + Initial beta release
]]


-- USER AREA
-- Settings that the user can customize

fontFace = "Ariel"
fontSize = 16
textColor = {1,1,1,0.7}
backgroundColor = {0.1, 0.1, 0.1, 1}
blockColor = {0.9, 0, 0.9, 0.4}

-- End of USER AREA


---------------------------------------------------------------------
---------------------------------------------------------------------

-- A few default values

MOUSE_LEFT_BUTTON = 1
borderWidth = 10
patternLength = 4
tablePattern = {}
tableNotes = {}


---------------
function exit()
    gfx.quit()
    
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
    
    reaper.Undo_OnStateChange("MIDI note pattern selector")
    
end -- function exit


-----------------------------
function setColor(colorTable)
    gfx.r = colorTable[1]
    gfx.g = colorTable[2]
    gfx.b = colorTable[3]
    gfx.a = colorTable[4]
end -- function setColor


------------------
function drawGUI()

    setColor(backgroundColor)
    gfx.rect(0, 0, gfx.w, gfx.h, true)
    
    -- If the note table is empty, the "Pattern length" text and steps are dimmed
    setColor(textColor)
    if type(tableNotes) ~= "table" or #tableNotes == 0 then gfx.a = gfx.a*0.5 end
    gfx.x = borderWidth
    gfx.y = borderWidth
    gfx.drawstr("Pattern length: ")
    gfx.drawstr(tostring(patternLength))
    
    gfx.line(borderWidth, borderWidth+strHeight, borderWidth+lineLengthGUI, borderWidth+strHeight)
    
    -- Draw the pattern steps - highlighted if step is selected
    gfx.y = borderWidth + strHeight*2
    for i = 1, patternLength do
        gfx.x = borderWidth + (i-1)*strWidth
        if tablePattern[i] == true then
            setColor(blockColor)
            if type(tableNotes) ~= "table" or #tableNotes == 0 then gfx.a = gfx.a*0.5 end
            gfx.rect(gfx.x, gfx.y, strWidth*2/3, strHeight)
        end
        setColor(textColor)
        if type(tableNotes) ~= "table" or #tableNotes == 0 then gfx.a = gfx.a*0.5 end
        gfx.drawstr(tostring(i))
    end
    
    -- Draw the "Load new set of notes" button
    setColor(textColor)
    gfx.y = borderWidth + strHeight*4
    gfx.x = gfx.w/2 - newNotesStrWidth/2
    gfx.drawstr("Load new set of notes")
    
    gfx.update()

end -- function drawGUI


----------------------------
function updateTableNotes()

    -- When a new set of notes is loaded, seems to be good place to add an Undo point
    reaper.Undo_OnStateChange("MIDI note pattern selector")
    
    -- Start with a blank table that will only be filled if any selected notes are available
    tableNotes = nil
    tableNotes = {}
    
    editor = reaper.MIDIEditor_GetActive()
    if editor ~= nil then 
        take = reaper.MIDIEditor_GetTake(editor)
        -- There is a bug in the GetTake function, which sometimes returns invalid, deleted takes
        if reaper.ValidatePtr2(0, take, "MediaItem_Take*") then
            reaper.MIDI_Sort(take)
            -- Get the number of notes that are in take at time that selected notes are loaded
            --    If this number changes, the selected notes will get UNloaded to prevent
            --    confusing changes in indices.
            _, noteCount, _, _ = reaper.MIDI_CountEvts(take)
            
            local i = reaper.MIDI_EnumSelNotes(take, -1)
            while i > -1 do
                local noteOK, _, _, startppq, _, _, _, _ = reaper.MIDI_GetNote(take, i)
                if noteOK then
                    table.insert(tableNotes, {ppq=startppq, index=i})
                end
                i = reaper.MIDI_EnumSelNotes(take, i)
            end
            
            local function sortppq(a,b)
                if a.ppq < b.ppq then return true end
            end
            
            table.sort(tableNotes, sortppq)
            --[[
            -- The following code finds notes within the time selection.
            --    The current version of this scripts uses another approach:
            --    It works with notes that are pre-selected by the user.
            timeSelStartTime, timeSelEndTime = reaper.GetSet_LoopTimeRange(false, false, 0, 0, true)
            if timeSelEndTime > timeSelStartTime then
            
                timeSelStartPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelStartTime)
                timeSelEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, timeSelEndTime)
                reaper.MIDI_Sort(take)
                countOK, noteCount, _, _ = reaper.MIDI_CountEvts(take)
                
                -- Use binary search to find note close to start of time selection
                rightIndex = noteCount-1
                leftIndex = 0
                while (rightIndex-leftIndex)>1 do
                    middleIndex = math.ceil((rightIndex+leftIndex)/2)
                    local _, _, _, startppq, _, _, _, _ = reaper.MIDI_GetNote(take, middleIndex)
                    if startppq >= timeSelStartPPQ then
                        rightIndex = middleIndex
                    else -- middlePPQpos <= startingPPQpos
                        leftIndex = middleIndex
                    end     
                end -- while (rightIndex-leftIndex)>1
                
                for i = leftIndex, noteCount-1 do
                    noteOK, _, _, startppq, endppq, _, _, _ = reaper.MIDI_GetNote(take, i)
                    if noteOK and startppq >= timeSelEndPPQ then
                        break
                    elseif noteOK and startppq >= timeSelStartPPQ then
                        table.insert(tableNotes, {ppq=startppq, index=i})
                    end
                end
                -- table.sort(tableNotes, sortppq)
            end
            ]]
        end
    end
end


------------------------------
function updateNoteSelectionInEditor()
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and type(tableNotes)=="table" then
    
        -- Notes that start within one grid length from each other are regarded as one chord
        gridQN, _, _ = reaper.MIDI_GetGrid(take)
        gridPPQ = gridQN * 960
        local step = 1
        for i = 1, #tableNotes do
            if i > 1 and (tableNotes[i].ppq > tableNotes[i-1].ppq + gridPPQ) then
                step = step + 1
                if step > patternLength then step = 1 end
            end
            reaper.MIDI_SetNote(take, tableNotes[i].index, tablePattern[step], nil, nil, nil, nil, nil, nil, true)
        end
    end
end


----------------------------
function loopNoteSelector()

    -- Quit script if GUI has been closed
    local char = gfx.getchar()
    if char<0 then return(0) end 
    
    -- Apparently gfx.update must be called in order to update gfx.x and other variables
    gfx.update()
    
    -- If no changes are found in rest of loop, don't bother doing enything
    local mustUpdateGUI = false
    local mustUpdateTableOfNotes = false
    local mustUpdateNoteSelectionInEditor = false
    
    -- If the indices of the target notes change, it will confuse the script.
    --    This code tries to check for such changes.
    local _, newNoteCount
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") then
        _, newNoteCount, _, _ = reaper.MIDI_CountEvts(take)
    else 
        newNoteCount = 0
    end  
    if newNoteCount == 0 or newNoteCount ~= noteCount then
        tableNotes = nil
        tableNotes = {}
        noteCount = newNoteCount
        mustUpdateGUI = true
    end
    
    -- If the GUI size changes, the "Load" button at the bottom must remain in the middle
    if gfx.w ~= prevGfxW or gfx.h ~= prevGfxH then
        mustUpdateGUI = true
        prevGfxW = gfx.w 
        prevGfxH = gfx.h
    end
   
    -- Has the editor, take, MIDI or time selection changed?  Then update table of notes
    
    
    -- Has the editor's grid changed?
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") then
        gridQN, _, _ = reaper.MIDI_GetGrid(take)
        if gridQN ~= prevGridQN then
            prevGridQN = gridQN
            mustUpdateNoteSelectionInEditor = true
        end
    end
    
    -- To improve speed and responsiveness, if mouse is outside GUI, script does nothing
    if not (gfx.mouse_x < 0 or gfx.mouse_x > gfx.w or gfx.mouse_y < 0 or gfx.mouse_y > gfx.h)
    and not (gfx.mouse_x == prevMouseX and gfx.mouse_y == prevMouseY and gfx.mouse_cap == prevMouseCap)
    then
        prevMouseX = gfx.mouse_x
        prevMouseY = gfx.mouse_y
        prevMouseCap = gfx.mouse_cap
        
        -- Is mouse on length line?
        if gfx.mouse_cap == MOUSE_LEFT_BUTTON 
        and gfx.mouse_y > borderWidth 
        and gfx.mouse_y < borderWidth + strHeight*2
        then
            patternLength = math.max(1, math.min(99, math.ceil((gfx.mouse_x - borderWidth)/strWidth)))
            lineLengthGUI = math.max(0, math.min(99*strWidth, gfx.mouse_x - borderWidth))
            mustUpdateGUI = true
            if patternLength ~= prevPatternLength then
                mustUpdateNoteSelectionInEditor = true
                prevPatternLength = patternLength
            end
        end
    
        -- Is mouse on pattern step numbers?
        if gfx.mouse_cap == MOUSE_LEFT_BUTTON 
        and gfx.mouse_y > borderWidth + strHeight*2 
        and gfx.mouse_y < borderWidth + strHeight*3 
        then
            clickedStep = math.max(1, math.min(99, math.ceil((gfx.mouse_x - borderWidth)/strWidth)))
            if clickedStep ~= prevClickedStep then
                prevClickedStep = clickedStep
                tablePattern[clickedStep] = not tablePattern[clickedStep]
                mustUpdateGUI = true
                mustUpdateNoteSelectionInEditor = true
            end
        else
            prevClickedStep = nil 
        end
        
        -- Is mouse on "Load new set of notes" button?
        -- loadButtonAlreadyClicked variable prevents button from being activated multiple times
        --    by single, long click
        if gfx.mouse_cap == MOUSE_LEFT_BUTTON 
        and gfx.mouse_y > borderWidth + strHeight*4
        and gfx.mouse_y < borderWidth + strHeight*5
        and gfx.mouse_x < gfx.w/2 + newNotesStrWidth/2
        and gfx.mouse_x > gfx.w/2 - newNotesStrWidth/2
        then
            if not (loadButtonAlreadyClicked == true) then
                mustUpdateTableOfNotes = true
                mustUpdateGUI = true
                mustUpdateNoteSelectionInEditor = true
            end
            loadButtonAlreadyClicked = true
        else
            loadButtonAlreadyClicked = false
        end
        
    end -- if mouse is inside GUI
    
    -- Updates must occur in the correct order
    if mustUpdateTableOfNotes then updateTableNotes() end
    
    if mustUpdateGUI then drawGUI() end 
    
    if mustUpdateNoteSelectionInEditor then updateNoteSelectionInEditor() end
    
    reaper.defer(loopNoteSelector)
end -- function loopNoteSelector


--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

reaper.atexit(exit)

_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end

-- Set default selection value as true, since works with pre-selected notes
for i = 1, 99 do
    tablePattern[i] = true
end

-- gfx.measurestr only returns correct value if a GUI is alreay open.  So quickly open a dummy GUI to font size.
gfx.init("Step pattern selector", 200, 400)
gfx.setfont(1, fontFace, fontSize, 'b')
strWidth, strHeight = gfx.measurestr("000")
newNotesStrWidth, _ = gfx.measurestr("Load new set of notes")
gfx.quit()

strHeight = strHeight + 3
lineLengthGUI = patternLength * strWidth

gfx.init("Step pattern selector", borderWidth*2 + strWidth*8, borderWidth*2 + strHeight*5)
gfx.setfont(1, fontFace, fontSize, 'b')
drawGUI()

updateTableNotes()

loopNoteSelector()

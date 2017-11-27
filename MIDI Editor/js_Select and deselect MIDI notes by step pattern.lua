--[[
ReaScript name: Select and deselect MIDI notes by step pattern
Version: 1.21
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=176878
Screenshot: http://stash.reaper.fm/30964/js_Select%20and%20deselect%20MIDI%20notes%20by%20step%20pattern%20-%20Measure%20divisions%20mode.gif
Extensions: SWS not required.
Donation: https://www.paypal.me/juliansader
About:
  # Description
  
  This script selects and deselects notes, based on a pattern that the user can draw in a GUI.
  
  For example, the pattern can be drawn to select notes 1, 3 and 4 in a six-step pattern.
  
  The length of the pattern as well as the steps that will be selected are determined by the user. (The maximum pattern length is 99 steps.)
  
  The script offers two modes: "Step pattern" and "Measure division", which can be toggled by clicking on the "Mode" text in the GUI.
  In "Measure division" mode, notes are selected and deselected based on their beat positions in the measure.
  
  In Step pattern mode, notes that start within one grid length of each other are regarded as one unit (e.g. chord or glissando), and will be selected/deselected together.


  # Instructions
  
  First, select the note on which the step pattern must be applied. (Of course, some of these notes will later be deselected by the script.)
  
  Then, run the script and draw the desired pattern - the note selection will be updated in real time.
  
  When you need to work with a new set of notes, simply click the "Load new set of notes" text.  
  
  If no notes are selected when the script is started, the script will dim out the step 
    pattern display, and wait for the user to load a new set of notes.
    
  To draw patterns that are longer than the initial size of the GUI, simply widen the GUI.
  
  To toggle between the two modes, "Step pattern" and "Measure division", simply click the "Mode" text at the top of the GUI.
  
  NEW IN VERSION 1.20:
  
  The user can freely edit CCs or velocities in the MIDI editor while a set of notes is loaded, 
    without having to reload the notes after editing.  
  
  If the pitches or positions of the loaded *notes* are edited in the MIDI editor, it may confuse the script, 
    but the script will try to add any *selected* and edited notes to the set of loaded, active notes.
    
  Therefore, if you change the pitch of some of the loaded notes, simply ensure that these notes are still selected when clicking in the GUI again, 
    and these edited notes will remain loaded.
      
  TIP: 
  
  This script works well with the "js_Deselect all notes outside time selection (from all 
      takes).lua" script.  Use the piano roll keys to select all notes in a range of pitches, and
      then run the Deselect script to limit the note selection to the time selection.
]]
 
--[[
  Changelog:
  * v0.9 (2016-08-01)
    + Initial beta release
  * v0.91 (2016-08-20)
    + Compatible with projects that use a PPQ different from 960
  * v0.95 (2016-10-25)
    + Updated header and "About" info to ReaPack 1.1 format.
    + Notes that start exactly one grid unit apart, are not regarded as one unit/chord/glissando.
  * v1.00 (2017-06-17)
    + Much faster execution in takes with large number of MIDI events, using new API of REAPER v5.32.
    + New mode: "Measure divisions", which selects notes based on beat positions in measure. 
  * v1.10 (2017-06-19)
    + GUI window will open at last-used position on screen.
  * v1.20 (2017-06-19)
    + Notes do not need to be reloaded after editing velocities or CCs in the MIDI editor.
  * v1.21 (2017-08-26)
    + Compatible with muted notes.
]]


-- USER AREA
-- Settings that the user can customize

local fontFace = "Ariel"
local fontSize = 16
local textColor = {1,1,1,0.7}
local backgroundColor = {0.1, 0.1, 0.1, 1}
local blockColor = {0.9, 0, 0.9, 0.4}

-- End of USER AREA


---------------------------------------------------------------------
---------------------------------------------------------------------

-- Some default values
local MOUSE_LEFT_BUTTON = 1
local borderWidth = 10
local patternLength = 4
local tPattern = {}
-- Set default selection values as true, since works with pre-selected notes
for i = 1, 99 do
    tPattern[i] = true
end
local mode = "Step pattern"
local notesAreLoaded = false

local tNoteOns = {} 

local tMIDI = {} 
local tSelNotes = {}
local take, editor, item, MIDIhash
local modeButtonTopY, modeButtonBottomY, lengthTopY, lengthBottomY, stepsTopY, stepsBottomY, loadButtonTopY, loadButtonBottomY


---------------
function exit()
    -- Find and store the last-used coordinates of the GUI window, so that it can be re-opened at the same position
    local docked, xPos, yPos, xWidth, yHeight = gfx.dock(-1, 0, 0, 0, 0)
    if docked == 0 and type(xPos) == "number" and type(yPos) == "number" then
        -- xPos and yPos should already be integers, but use math.floor just to make absolutely sure
        reaper.SetExtState("js_Step pattern", "Last coordinates", string.format("%i", math.floor(xPos+0.5)) .. "," .. string.format("%i", math.floor(yPos+0.5)), true)
    end
    gfx.quit()
    
    _, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
    if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
        reaper.SetToggleCommandState(sectionID, ownCommandID, 0)
        reaper.RefreshToolbar2(sectionID, ownCommandID)
    end
    
    reaper.Undo_OnStateChange2(0, "MIDI note pattern selector")
    
end -- function exit


-----------------------------------
local function setColor(colorTable)
    gfx.r = colorTable[1]
    gfx.g = colorTable[2]
    gfx.b = colorTable[3]
    gfx.a = colorTable[4]
end -- function setColor


------------------------
local function drawGUI()

    gfx.update()
    
    setColor(backgroundColor)
    gfx.rect(0, 0, gfx.w, gfx.h, true)
    
    -- If the note table is empty, the "Pattern length" text and steps are dimmed
    --if type(tSelNotes) ~= "table" or #tSelNotes == 0 then local dimSteps = true end
    
    -- Draw Mode button
    setColor(textColor)
    gfx.y = borderWidth
    if mode == "Step pattern" then
        gfx.x = gfx.w/2 - modeStepsStrWidth/2
        gfx.drawstr("Mode: Step Pattern")
    else
        gfx.x = gfx.w/2 - modeMeasureStrWidth/2
        gfx.drawstr("Mode: Measure divisions") 
    end
    
    -- Draw pattern length text
    setColor(textColor)
    if not notesAreLoaded then gfx.a = gfx.a*0.3 end
    gfx.x = borderWidth
    gfx.y = borderWidth + strHeight*2
    if mode == "Step pattern" then
        gfx.drawstr("Pattern length: ")
    else
        gfx.drawstr("Divisions: ")
    end
    gfx.drawstr(tostring(patternLength))
    
    -- Draw pattern length line
    gfx.line(borderWidth, borderWidth+strHeight*3, borderWidth+lineLengthGUI, borderWidth+strHeight*3)
    
    -- Draw the pattern steps - highlighted if step is selected
    gfx.y = borderWidth + strHeight*4
    for i = 1, patternLength do
        gfx.x = borderWidth + (i-1)*strWidth
        if tPattern[i] == true then
            setColor(blockColor)
            if not notesAreLoaded then gfx.a = gfx.a*0.3 end
            gfx.rect(gfx.x, gfx.y, strWidth*2/3, strHeight)
        end
        setColor(textColor)
        if not notesAreLoaded then gfx.a = gfx.a*0.3 end
        gfx.drawstr(tostring(i))
    end
    
    -- Draw the "Load new set of notes" button
    setColor(textColor)
    gfx.y = borderWidth + strHeight*6
    gfx.x = gfx.w/2 - newNotesStrWidth/2
    gfx.drawstr("Load new set of notes")

end -- function drawGUI


---------------------------------
local function reloadSameNotes()
-- This function (unlike loadNewSetOfNotes) does NOT only find selected notes.  Instead, it tries to find notes that match the starting positions of the
--    originally selected notes.
    
    -- The raw MIDI data will be stored in tMIDI, in correct sequence so that it can later be concatenated again by table.concat.
    -- The "flag" bytes of selected note-on and note-off events will be isolated and stored in separate entries, 
    --    so that they can easily be accessed directly later, to change the selection status of the notes.
    tMIDI = {} 
    -- Each entry in tSelNotes will be a table that contains the indices (in tMIDI) of the note-on and note-off events' flags.
    tSelNotes = {}
    local e, n = 0, 0 -- Indices in tables
    
    notesAreLoaded = false
    
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") then
           
        -- Since the notes will be navigated in sequence, the MIDI data must be sorted first.
        reaper.MIDI_Sort(take)
        
        _, MIDIhash = reaper.MIDI_GetHash(take, false, "")
        
        -- While parsing the MIDI string, the indices of the last note-ons for each channel/pitch/flag must be temporarily stored until a matching note-off is encountered. 
        for channel = 0, 15 do
            for pitch = 0, 127 do
                tNoteOns[channel][pitch].lastNoteOn = {}
            end
        end
        
        -- Get all MIDI data and then parse through it    
        local gotMIDIOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
        if gotMIDIOK then
            local stringPos, prevStringPos = 1, 1 -- Position inside MIDIstring while parsing
            local lastSavedStringPos = 0 -- Position of last byte in MIDIstring that was stored in tMIDI
            local runningPPQpos = 0
            local MIDIlen = MIDIstring:len() -- Don't parse the final 12 bytes, which provides REAPER's end-of-take All-Notes-Off message
            local offset, flags, msg
            
            while stringPos < MIDIlen do
                prevStringPos = stringPos
                offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
                runningPPQpos = runningPPQpos + offset       
                
                -- All events are stored in tMIDI
                    
                -- Note events will be stored in tNotes.  
                -- Each entry in tNotes is itself a table that contains the indices of two or three events in tMIDI:
                --    noteOnIndex, noteOffIndex, and (optional) notationIndex
                
                -- This function (unlike loadNewSetOfNotes does NOT only analyze selected notes.
                
                if msg ~= "" then -- Don't need to analyze empty events that simply change PPQ position
                    local eventType = msg:byte(1)>>4
                    
                    -- Find note-ons and note-offs
                    if eventType == 9 or eventType == 8 then                            
                        
                        local channel = msg:byte(1)&0x0F
                        local pitch   = msg:byte(2)
                        
                        -- Note-ons
                        if eventType == 9 and msg:byte(3) ~= 0 then
                            if tNoteOns[channel][pitch][runningPPQpos] -- A note at this position was selected originally
                            or flags&1 == 1 -- Or this note is newly selected.
                            then 
                                if tNoteOns[channel][pitch].lastNoteOn[flags] then
                                    reaper.ShowMessageBox("The script encountered overlapping notes.\n\nSuch notes are not valid MIDI, and can not be parsed.", "ERROR", 0)
                                    tMIDI = {}
                                    tSelNotes = {}
                                    return false
                                else
                                    e = e + 1
                                    tMIDI[e] = MIDIstring:sub(lastSavedStringPos+1, prevStringPos+3) -- up to and including offset
                                    e = e + 1
                                    tMIDI[e] = string.pack("B", flags)
                                    lastSavedStringPos = prevStringPos+4 -- Position of flags
                                    
                                    n = n + 1
                                    tSelNotes[n] = {noteOnIndex = e, ppqpos = runningPPQpos} -- Reference to flag's index
                                    -- The reloaded notes can simply reuse the original notes' measureDivision,
                                    --    but what will happen if the user has changed the time signature?
                                    -- So rather do the slow re-calculations.
                                    local startOfMeasure = reaper.MIDI_GetPPQPos_StartOfMeasure(take, runningPPQpos)
                                    local endOfMeasure = reaper.MIDI_GetPPQPos_EndOfMeasure(take, runningPPQpos+1)
                                    local measureDivision = (runningPPQpos - startOfMeasure) / (endOfMeasure - startOfMeasure)
                                    tSelNotes[n].measureDivision = measureDivision
                             
                                    tNoteOns[channel][pitch][runningPPQpos] = measureDivision -- Create an entry at this note's start position, so that can be reloaded.
                                    tNoteOns[channel][pitch].lastNoteOn[flags] = n -- Store the index of the running note-on, so that next matching note-off can be stored at same index.
                                end
                            end
                        -- Note-offs
                        else
                            local lastNoteOnIndex = tNoteOns[channel][pitch].lastNoteOn[flags] -- Is a matching note-on waiting?
                            if lastNoteOnIndex then
                                e = e + 1
                                tMIDI[e] = MIDIstring:sub(lastSavedStringPos+1, prevStringPos+3) -- up to and including offset
                                e = e + 1
                                tMIDI[e] = string.pack("B", flags)
                                lastSavedStringPos = prevStringPos+4 -- Position of flags
                                
                                tSelNotes[lastNoteOnIndex].noteOffIndex = e -- Reference to flag's index
                                tNoteOns[channel][pitch].lastNoteOn[flags] = nil
                            end
                        end 
                    end -- if eventType == 9 or eventType == 8
                end
            end -- while stringPos < MIDIlen
            
            -- Store all remaining MIDI data in tMIDI
            e = e + 1
            tMIDI[e] = MIDIstring:sub(lastSavedStringPos+1)            
            
        end -- if GotMIDIOK                      
    end -- if reaper.ValidatePtr2(0, take, "MediaItem_Take*")
    
    if #tSelNotes > 0 then
        notesAreLoaded = true
    end
end


---------------------------------
local function loadNewSetOfNotes()
    
    -- The raw MIDI data will be stored in tMIDI, in correct sequence so that it can later be concatenated again by table.concat.
    -- The "flag" bytes of selected note-on and note-off events will be isolated and stored in separate entries, 
    --    so that they can easily be accessed directly later, to change the selection status of the notes.
    tMIDI = {} 
    -- Each entry in tSelNotes will be a table that contains the indices (in tMIDI) of the note-on and note-off events' flags.
    tSelNotes = {}
    local e, n = 0, 0 -- Indices in tables
    
    notesAreLoaded = false
    
    editor = reaper.MIDIEditor_GetActive()
    if editor ~= nil then 
        take = reaper.MIDIEditor_GetTake(editor)
        -- There is a bug in the GetTake function, which sometimes returns invalid, deleted takes
        if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) then
        
            -- When a new set of notes is loaded, seems to be good place to add an Undo point
            item = reaper.GetMediaItemTake_Item(take)
            reaper.Undo_OnStateChange_Item(0, "MIDI note pattern selector", item)
       
            -- Since the notes will be navigated in sequence, the MIDI data must be sorted first.
            reaper.MIDI_Sort(take)
            
            _, MIDIhash = reaper.MIDI_GetHash(take, false, "")
            
            -- While parsing the MIDI string, the indices of the last note-ons for each channel/pitch/flag must be temporarily stored until a matching note-off is encountered. 
            tNoteOns = nil
            tNoteOns = {}
            for channel = 0, 15 do
                tNoteOns[channel] = {}
                for pitch = 0, 127 do
                    tNoteOns[channel][pitch] = {} 
                    tNoteOns[channel][pitch].lastNoteOn = {}
                end
            end
            
            -- Get all MIDI data and then parse through it    
            local gotMIDIOK, MIDIstring = reaper.MIDI_GetAllEvts(take, "")
            if gotMIDIOK then
                local stringPos, prevStringPos = 1, 1 -- Position inside MIDIstring while parsing
                local lastSavedStringPos = 0 -- Position of last byte in MIDIstring that was stored in tMIDI
                local runningPPQpos = 0
                local MIDIlen = MIDIstring:len() -- Don't parse the final 12 bytes, which provides REAPER's end-of-take All-Notes-Off message
                local offset, flags, msg
                
                while stringPos < MIDIlen do
                    prevStringPos = stringPos
                    offset, flags, msg, stringPos = string.unpack("i4Bs4", MIDIstring, stringPos)
                    runningPPQpos = runningPPQpos + offset       
                    
                    -- All events are stored in tMIDI
                        
                    -- Note events will be stored in tNotes.  
                    -- Each entry in tNotes is itself a table that contains the indices of two or three events in tMIDI:
                    --    noteOnIndex, noteOffIndex, and (optional) notationIndex
                    
                    if flags&1 == 1 -- Only analyze selected events
                    and msg ~= "" then -- Don't need to analyze empty events that simply change PPQ position
                        local eventType = msg:byte(1)>>4
                        
                        -- Find note-ons and note-offs
                        if eventType == 9 or eventType == 8 then
                            
                            e = e + 1
                            tMIDI[e] = MIDIstring:sub(lastSavedStringPos+1, prevStringPos+3) -- up to and including offset
                            e = e + 1
                            tMIDI[e] = string.pack("B", flags)
                            lastSavedStringPos = prevStringPos+4 -- Position of flags
                            
                            local channel = msg:byte(1)&0x0F
                            local pitch   = msg:byte(2)
                            
                            -- Note-ons
                            if eventType == 9 and msg:byte(3) ~= 0 then
                                if tNoteOns[channel][pitch].lastNoteOn[flags] then
                                    reaper.ShowMessageBox("The script encountered overlapping notes.\n\nSuch notes are not valid MIDI, and can not be parsed.", "ERROR", 0)
                                    tMIDI = {}
                                    tSelNotes = {}
                                    return false
                                else
                                    n = n + 1
                                    tSelNotes[n] = {noteOnIndex = e, ppqpos = runningPPQpos} -- Reference to flag's index
                                    local startOfMeasure = reaper.MIDI_GetPPQPos_StartOfMeasure(take, runningPPQpos)
                                    local endOfMeasure = reaper.MIDI_GetPPQPos_EndOfMeasure(take, runningPPQpos+1)
                                    local measureDivision = (runningPPQpos - startOfMeasure) / (endOfMeasure - startOfMeasure)
                                    tSelNotes[n].measureDivision = measureDivision
                             
                                    tNoteOns[channel][pitch][runningPPQpos] = measureDivision -- Create an entry at this note's start position, so that can be reloaded.
                                    tNoteOns[channel][pitch].lastNoteOn[flags] = n -- Store the index of the running note-on, so that next matching note-off can be stored at same index.
                                end
                                
                            -- Note-offs
                            else
                                local lastNoteOnIndex = tNoteOns[channel][pitch].lastNoteOn[flags]
                                if not lastNoteOnIndex then
                                    reaper.ShowMessageBox("The script encountered orphan note-offs that do not have corresponding note-ons.", "ERROR", 0)
                                    tMIDI = {}
                                    tSelNotes = {}
                                    return false
                                else
                                    tSelNotes[lastNoteOnIndex].noteOffIndex = e -- Reference to flag's index
                                    tNoteOns[channel][pitch].lastNoteOn[flags] = nil
                                end
                            end 
                        end -- if eventType == 9 or eventType == 8
                    end
                end -- while stringPos < MIDIlen
                
                -- Store all remaining MIDI data in tMIDI
                e = e + 1
                tMIDI[e] = MIDIstring:sub(lastSavedStringPos+1)                
                
            end -- if GotMIDIOK                      
        end -- if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take)
    end -- if editor ~= nil
    
    if #tSelNotes > 0 then
        notesAreLoaded = true
    end
end


--------------------------------------------
local function updateNoteSelectionInEditor()
    if reaper.ValidatePtr2(0, take, "MediaItem_Take*") and type(tSelNotes)=="table" and #tSelNotes > 0 then
    
        if mode == "Step pattern" then
            -- Sometimes a project's PPQ is not 960.  So first get PPQ of take.
            local QNstart = reaper.MIDI_GetProjQNFromPPQPos(take, 0)
            local PPQ = reaper.MIDI_GetPPQPosFromProjQN(take, QNstart + 1) - reaper.MIDI_GetPPQPosFromProjQN(take, QNstart)
            
            -- Notes that start within one grid length from each other are regarded as one chord
            gridQN, _, _ = reaper.MIDI_GetGrid(take)
            gridPPQ = gridQN * PPQ
            local step = 1
            for i = 1, #tSelNotes do
                if i > 1 and (tSelNotes[i].ppqpos >= tSelNotes[i-1].ppqpos + gridPPQ) then
                    step = step + 1
                    if step > patternLength then step = 1 end
                end
                if tPattern[step] then
                    tMIDI[  tSelNotes[i].noteOnIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOnIndex]) | 1)
                    tMIDI[  tSelNotes[i].noteOffIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOffIndex]) | 1)
                else
                    tMIDI[  tSelNotes[i].noteOnIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOnIndex]) & 0xFE)
                    tMIDI[  tSelNotes[i].noteOffIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOffIndex]) & 0xFE)
                end
            end
        
        else -- mode == "Measure divisions"
            local step
            for i = 1, #tSelNotes do
                step = math.floor(tSelNotes[i].measureDivision * patternLength) + 1
                if tPattern[step] then
                    tMIDI[  tSelNotes[i].noteOnIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOnIndex]) | 1)
                    tMIDI[  tSelNotes[i].noteOffIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOffIndex]) | 1)
                else
                    tMIDI[  tSelNotes[i].noteOnIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOnIndex]) & 0xFE)
                    tMIDI[  tSelNotes[i].noteOffIndex] = string.char(string.byte(tMIDI[  tSelNotes[i].noteOffIndex]) & 0xFE)
                end
            end
        end
        reaper.MIDI_SetAllEvts(take, table.concat(tMIDI))
        -- Update MIDI hash after uploading
        _, MIDIhash = reaper.MIDI_GetHash(take, false, "")
    end
end


---------------------------------
local function loopNoteSelector()

    -- Quit script if GUI has been closed
    local char = gfx.getchar()
    if char<0 then return(0) end 
    
    -- Apparently gfx.update must be called in order to update gfx.x and other variables
    gfx.update()
    
    -- If no changes are found in rest of loop, don't bother doing enything
    local mustUpdateGUI = false
    local mustLoadNewSetOfNotes = false
    local mustReloadSameNotes = false
    local mustUpdateNoteSelectionInEditor = false    
    
    -- Does the take still exist?  
    local takeIsStillValid = reaper.ValidatePtr2(0, take, "MediaItem_Take*")
    if not takeIsStillValid then
        notesAreLoaded = false
        tMIDI = {}
        tSelNotes = {}
        mustUpdateGUI = true
        -- Don't jump to updates from here.  Instead, wait for user to click on loadNewNotes.
    end
                    
    -- First, check for stuff that must be updated even if mouse is outside GUI:
    
    -- If the GUI size changes, the "Mode" and "Load" buttons at the bottom must remain in the middle
    if gfx.w ~= prevGfxW or gfx.h ~= prevGfxH then
        mustUpdateGUI = true
        prevGfxW = gfx.w 
        prevGfxH = gfx.h
        goto updates
    end    
    
    -- Has the editor's grid changed?
    if takeIsStillValid and notesAreLoaded then
        gridQN, _, _ = reaper.MIDI_GetGrid(take)
        if gridQN ~= prevGridQN then
            prevGridQN = gridQN
            mustUpdateNoteSelectionInEditor = true
            goto updates
        end
    end    
    
    -- Now, check for stuff that only need to be updated if the mouse is inside the GUI:
    
    -- Check whether mouse clicked on something inside GUI
    if (gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > 0 and gfx.mouse_y < gfx.h)
    and (gfx.mouse_x ~= prevMouseX or gfx.mouse_y ~= prevMouseY or gfx.mouse_cap ~= prevMouseCap)
    then
        prevMouseX = gfx.mouse_x
        prevMouseY = gfx.mouse_y
        prevMouseCap = gfx.mouse_cap        
        
        -- Has the MIDI inside the take changed?  If so, try to re-load the notes that were originally selected.
        -- Usually, this will happen when the mouse returns to the GUI after doing edits in the MIDI editor.
        if takeIsStillValid and notesAreLoaded then -- Are there any notes to reload?
            local _, currentHash = reaper.MIDI_GetHash(take, false, "") -- take has already been validated above
            if currentHash ~= MIDIhash then
                mustReloadSameNotes = true
                goto updates
            end
        end 
        
        -- Is mouse on "Mode" button?
        -- modeButtonAlreadyClicked variable prevents button from being activated multiple times
        --    by single, long click
        if gfx.mouse_cap == MOUSE_LEFT_BUTTON 
        and gfx.mouse_y > modeButtonTopY
        and gfx.mouse_y < modeButtonBottomY
        and gfx.mouse_x < gfx.w/2 + modeMeasureStrWidth/2
        and gfx.mouse_x > gfx.w/2 - modeMeasureStrWidth/2
        then
            if not (modeButtonAlreadyClicked == true) then
                if mode == "Step pattern" then 
                    mode = "Measure divisions"
                else
                    mode = "Step pattern"
                end
                mustUpdateGUI = true
                mustUpdateNoteSelectionInEditor = true
            end
            modeButtonAlreadyClicked = true
            goto updates
        else
            modeButtonAlreadyClicked = false
        end
        
        -- Is mouse on length line?
        if gfx.mouse_cap == MOUSE_LEFT_BUTTON 
        and gfx.mouse_y > lengthTopY
        and gfx.mouse_y < lengthBottomY
        then
            patternLength = math.max(1, math.min(99, math.ceil((gfx.mouse_x - borderWidth)/strWidth)))
            lineLengthGUI = math.max(0, math.min(99*strWidth, gfx.mouse_x - borderWidth))
            mustUpdateGUI = true
            if patternLength ~= prevPatternLength then
                mustUpdateNoteSelectionInEditor = true
                prevPatternLength = patternLength
            end
            goto updates
        end
    
        -- Is mouse on pattern step numbers?
        if gfx.mouse_cap == MOUSE_LEFT_BUTTON 
        and gfx.mouse_y > stepsTopY
        and gfx.mouse_y < stepsBottomY
        then
            clickedStep = math.max(1, math.min(99, math.ceil((gfx.mouse_x - borderWidth)/strWidth)))
            if clickedStep ~= prevClickedStep then
                prevClickedStep = clickedStep
                tPattern[clickedStep] = not tPattern[clickedStep]
                mustUpdateGUI = true
                mustUpdateNoteSelectionInEditor = true
            end
            goto updates
        else
            prevClickedStep = nil 
        end
        
        -- Is mouse on "Load new set of notes" button?
        -- loadButtonAlreadyClicked variable prevents button from being activated multiple times
        --    by single, long click
        if gfx.mouse_cap == MOUSE_LEFT_BUTTON 
        and gfx.mouse_y > loadButtonTopY
        and gfx.mouse_y < loadButtonBottomY
        and gfx.mouse_x < gfx.w/2 + newNotesStrWidth/2
        and gfx.mouse_x > gfx.w/2 - newNotesStrWidth/2
        then
            if not (loadButtonAlreadyClicked == true) then
                mustLoadNewSetOfNotes = true 
                mustUpdateGUI = true
                mustUpdateNoteSelectionInEditor = true
            end
            loadButtonAlreadyClicked = true
            goto updates
        else
            loadButtonAlreadyClicked = false
        end        
        
    end -- if mouse is inside GUI
    
    
    
    ::updates::
    -- Updates must occur in the correct order
    if mustLoadNewSetOfNotes then loadNewSetOfNotes() end 
    
    if mustReloadSameNotes then reloadSameNotes() end
    
    if mustUpdateGUI then drawGUI() end 
    
    if mustUpdateNoteSelectionInEditor then updateNoteSelectionInEditor() end
    
    reaper.defer(loopNoteSelector)
end -- function loopNoteSelector


--------------------------------------------------------------------
-- Here the code execution starts
--------------------------------------------------------------------
-- function main()

-- From v1.00 of this script, v5.32 or higher of REAPER is required
if not reaper.APIExists("MIDI_GetAllEvts") then
    reaper.ShowMessageBox("This script requires REAPER v5.32 or higher.", "ERROR", 0)
    return false 
end  


-------------------------------------------
-- Check whether startup tips must be shown
local startupTipsExtState = reaper.GetExtState("js_Step pattern", "Startup tips version")
if type(startupTipsExtState) == "string" then
    startupTipsVersion = tonumber(startupTipsExtState)
end
if type(startupTipsVersion) ~= "number" then
    startupTipsVersion = 0    
end
if startupTipsVersion < 1.00 then
    reaper.ShowMessageBox("GRID SETTINGS"
                          .. "\n\nIn step pattern mode, notes that start within one grid length of each other are regarded as one unit "
                          .. "(e.g. a chord or glissando), and will be selected/deselected together."
                          .. "\n\nIf it seems as if the script does not apply the correct pattern, check that the grid length is longer than the distance between the notes' start positions."
                          .. "\n\n"
                          .. "\n\nNUMBER OF STEPS"
                          .. "\n\nThe maximum number of steps is 99.  For such long patterns, you may need to widen the GUI window."   
                          , "Startup tips", 0)
    reaper.SetExtState("js_Step pattern", "Startup tips version", "1.00", true)
end
if startupTipsVersion < 1.20 then
    reaper.ShowMessageBox("NEW IN VERSION 1.20:"
                          .. "\n\nThe user can edit CCs or velocities in the MIDI editor while a set of notes is loaded, "
                          .. "without requiring that the notes be reloaded after editing."
                          .. "\n\n"
                          .. "If the pitches or positions of the loaded notes are edited in the MIDI editor, "
                          .. "it may confuse the script, but the script will try to add any *selected* and "
                          .. "edited notes to the set of loaded, active notes."   
                          .. "\n\n"
                          .. "Therefore, if you change the pitch of some of the loaded notes, simply ensure that these notes are still selected "
                          .. "when clicking in the GUI again, and these edited notes will remain loaded."
                          .. "\n\n"                  
                          .. "\n\n(These startup tips will only be displayed once.)"
                          , "Startup tips", 0)
    reaper.SetExtState("js_Step pattern", "Startup tips version", "1.20", true)
end


-----------------------------------------------------------------------
-- Function will continue, so define atexit, and toggle button (if any)
reaper.atexit(exit)

_, _, sectionID, ownCommandID, _, _, _ = reaper.get_action_context()
if not (sectionID == nil or ownCommandID == nil or sectionID == -1 or ownCommandID == -1) then
    reaper.SetToggleCommandState(sectionID, ownCommandID, 1)
    reaper.RefreshToolbar2(sectionID, ownCommandID)
end


-------------------------------------------------
-- Load starting set of notes, before drawing GUI
loadNewSetOfNotes()


---------------------------------------------------------------------
-- GUI stuff.
-- gfx.measurestr only returns correct value if a GUI is alreay open.  
-- So quickly open a dummy GUI to font size.
gfx.init("Note selector", 200, 400)
gfx.setfont(1, fontFace, fontSize, 'b')
strWidth, strHeight    = gfx.measurestr("000")
newNotesStrWidth, _    = gfx.measurestr("Load new set of notes")
modeMeasureStrWidth, _ = gfx.measurestr("Mode: Measure divisions")
modeStepsStrWidth, _   = gfx.measurestr("Mode: Step pattern")
gfx.quit()

strHeight = strHeight + 3
lineLengthGUI = patternLength * strWidth

modeButtonTopY    = borderWidth
modeButtonBottomY = borderWidth + strHeight
lengthTopY        = borderWidth + strHeight*2
lengthBottomY     = borderWidth + strHeight*3.5
stepsTopY         = borderWidth + strHeight*4
stepsBottomY      = borderWidth + strHeight*5
loadButtonTopY    = borderWidth + strHeight*6
loadButtonBottomY = borderWidth + strHeight*7

-- The GUI window will be opened at the last-used coordinates
local coordinatesExtState = reaper.GetExtState("js_Step pattern", "Last coordinates") -- Returns an empty string if the ExtState does not exist
xPos, yPos = coordinatesExtState:match("(%d+),(%d+)") -- Will be nil if cannot match
if xPos and yPos then
    gfx.init("Note selector", borderWidth*2 + strWidth*8, borderWidth*2 + strHeight*7, 0, tonumber(xPos), tonumber(yPos)) -- Interesting, this function can accept xPos and yPos strings, without tonumber
else
    gfx.init("Note selector", borderWidth*2 + strWidth*8, borderWidth*2 + strHeight*7, 0)
end
gfx.setfont(1, fontFace, fontSize, 'b')
drawGUI()


------------------
-- Start the loop!
loopNoteSelector()

--[[
ReaScript name: Notation - Set beaming of selected notes to custom rhythm (using grid as margin)
Version: 1.01
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=172782&page=25
REAPER version: v5.24
Extensions required: -
About:
  # Description
  This script allows the user to easily change the beaming of syncopated measures where the rhythm
  does not follow the prevailing time signature.
  
  # Instructions
  The script can correctly beam notes that are played slightly ahead of the beat.  To do so, 
  the user should set the MIDI editor's grid to reflect the amount of leeway:  A note that
  starts within one grid length ahead of the next beat will be beamed together with the 
  next beat -- but only if the larger part of the note's length falls in the next beat.
  
  NOTE: To properly format the notes, the user may to wish run the "Minimize ties" action 
  after this script.
  
  # WARNING
  REAPER versions prior to 5.24 have a bug in the "Beam notes together" action, which fails if 
  notes in both staves of the Grand staff are selected.
]]

--[[
  Changelog:
  * v1.0 (2016-08-20)
    + Initial beta release
  * v1.01 (2016-09-04)
    + Added "using grid as margin" in title to inform users of this option
    + (More details can be found in the script itself.)
]]

-- USER AREA
-- Setting that the user can customize

askUserRhythm = true -- Should the script ask user confirmation?
defaultRhythm = "3-3-2"

-- End of USER ARE

---------------------------------------------------------------------------------
-- Here the code execution starts
-- function main()

-- Skip undo point if the script doesn't create one itself
function skipUndo()
end
reaper.defer(skipUndo)

tableDivs = {}
tableNotes = {}

---------------------------------------------------------------------------------------
-- Get user rhythm and convert it into a table of (normalized) divisions of the measure
-- For example, 3-3-2 is converted into {0, 0.375, 0.75, 1)  
if askUserRhythm == false then
    userRhythm = defaultRhythm
    total = 0
    tableDivs = {}
    tableDivs[1] = 0 
    for div in userRhythm:gmatch("%d+") do
        div = tonumber(div)
        if div > 0 then
            total = total + div
            table.insert(tableDivs, total)
        end
    end
    if not (total > 0) then
        reaper.ShowConsoleMsg("\n\nERROR:\nThe default rhythm (as set in the USER AREA) should consist of a "
                              .."series of integers, with a separator between each integer."
                              .."\nFor Example: 3-3-2 or 1 2 2 2 1.")
        return(false)
    end
else
    repeat
        OKorCancel, userRhythm = reaper.GetUserInputs("Set beaming to custom rhythm",
                                                  1,
                                                  "Enter rhythm",
                                                  defaultRhythm)
        if OKorCancel == false then return(0) end
        
        total = 0
        tableDivs = {}
        tableDivs[1] = 0 
        for div in userRhythm:gmatch("%d+") do
            div = tonumber(div)
            if div > 0 then
                total = total + div
                table.insert(tableDivs, total)
            end
        end
    until total > 0
end

-- Normalize table entries
for i = 1, #tableDivs do
    tableDivs[i] = tableDivs[i]/total
end

--------------------------------------------------------------------------------------------
-- REAPER remembers individualized grid settings for each take.  Therefore, to 
--    get the most recent grid setting of MIDI editor, must get active take's.
-- (REAPER's GetTake is buggy, so the returned value is sometimes an invalid, deleted take.)
editor = reaper.MIDIEditor_GetActive()
activeTake = reaper.MIDIEditor_GetTake(editor)
if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then return(0) end
grid, _, _ = reaper.MIDI_GetGrid(activeTake)

-----------------------------------------------------------------------------
-- OK, we have got usable user inputs and at least one take in the editor, so
--    the script can start to make changes.
reaper.Undo_BeginBlock()

----------------------------------------------------------------------------
-- Now iterate through all MIDI takes, searching for selected notes
-- (It would have been much better if REAPER's API including a function
--    to iterate through only the editable items in a specified MIDI editor.
numItems = reaper.CountMediaItems(0)
for i=0, numItems-1 do 

    curItem = reaper.GetMediaItem(0, i)
    if reaper.ValidatePtr2(0, curItem, "MediaItem*") then 
    
        numTakes = reaper.CountTakes(curItem)  
        for t=0, numTakes-1 do 
        
            curTake = reaper.GetTake(curItem, t)    
            if reaper.ValidatePtr2(0, curTake, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake) then 
            
                -- Weird, sometimes REAPER's PPQ is not 960.  So first get PPQ of take.
                local QNstart = reaper.MIDI_GetProjQNFromPPQPos(curTake, 0)
                local PPQ = reaper.MIDI_GetPPQPosFromProjQN(curTake, QNstart + 1) - reaper.MIDI_GetPPQPosFromProjQN(curTake, QNstart)
                local gridPPQ = PPQ*grid               
                
                n = reaper.MIDI_EnumSelNotes(curTake, -1) -- note index
                -- Are there any selected notes in take?
                if n ~= -1 then 
                    tableNotes[curTake] = {}
                    for i = 1, #tableDivs-1 do
                        tableNotes[curTake][i] = {}
                    end
                    
                    repeat
                        local noteOK, _, _, noteStart, noteEnd, _, _, _ = reaper.MIDI_GetNote(curTake, n)
                        local measureStart = reaper.MIDI_GetPPQPos_StartOfMeasure(curTake, noteStart+1)
                        local measureEnd = reaper.MIDI_GetPPQPos_EndOfMeasure(curTake, noteStart+1)
                        local measureLen = measureEnd - measureStart
                        local noteLen = noteEnd - noteStart
                        
                        -------------------------------------------------------------------------------------
                        -- tableLeeway will store the division points (derived from the editor's grid) beyond 
                        --    which notes will be sorted into the next division, even though the note does
                        --    not start in that division, but only if the majority of the note's length falls 
                        --    into the next division.
                        tableDivs[0] = 0
                        tableLeeway = {}
                        for d = 0, #tableDivs-1 do
                            tableLeeway[d] = math.min(gridPPQ, measureLen*(tableDivs[d+1]-tableDivs[d])/2)
                        end
                        
                        for d = 1, #tableDivs-1 do
                            -- Note start in this division, and not close to nexct division
                            if (noteStart >= measureStart + tableDivs[d]*measureLen 
                                and noteStart < measureStart + tableDivs[d+1]*measureLen - tableLeeway[d])
                            -- Note starts close to next division, but most of note's length
                            --    falls within this division
                            or (noteStart >= measureStart + tableDivs[d+1]*measureLen - tableLeeway[d] 
                                and noteStart < measureStart + tableDivs[d+1]*measureLen
                                and noteLen/2 < measureStart + tableDivs[d+1]*measureLen - noteStart)
                            -- Note start before this division, but most of note's length falls
                            --    within this division
                            or (noteStart >= measureStart + tableDivs[d]*measureLen - tableLeeway[d-1] 
                                and noteStart < measureStart + tableDivs[d]*measureLen
                                and noteLen/2 >= measureStart + tableDivs[d]*measureLen - noteStart)
                            then
                                table.insert(tableNotes[curTake][d], n)
                            end
                        end
                        n = reaper.MIDI_EnumSelNotes(curTake, n)
                    until n == -1
                end
                reaper.MIDI_SelectAll(curTake, false)
                              
            end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(curTake)
        end -- for t=0, numTakes-1
    end -- if reaper.ValidatePtr2(0, curItem, "MediaItem*")
end -- for i=0, numItems-1

----------------------------------------------------------------------------
-- Select notes division-by-division and take-by-take
-- In REAPER v5.23, the "Beam notes together" action does not work correctly
--    if notes are selected in multiple tracks of staves simultaneously.
for take, tableDivs in pairs(tableNotes) do
    for div = 1, #tableDivs do
        for note = 1, #tableDivs[div] do
            reaper.MIDI_SetNote(take, tableDivs[div][note], true, nil, nil, nil, nil, nil, nil, false)
        end
        --reaper.GetUserInputs("",1,"","")
        reaper.MIDIEditor_OnCommand(editor, 41045) -- Beam notes together
        -- In REAPER v5.23, "Minimize ties" does not always work, since it is a toggle
        reaper.MIDIEditor_OnCommand(editor, 41749) -- Minimize ties
        reaper.MIDI_SelectAll(take, false) -- Clear selection
    end
end 

-----------------------------------------------------------------
-- And finally, re-select all notes that were originally selected
for take, tableDivs in pairs(tableNotes) do
    for div = 1, #tableDivs do
        for note = 1, #tableDivs[div] do
            reaper.MIDI_SetNote(take, tableDivs[div][note], true, nil, nil, nil, nil, nil, nil, false)
        end
    end
end

reaper.Undo_EndBlock("Set beaming to custom rhythm", -1)

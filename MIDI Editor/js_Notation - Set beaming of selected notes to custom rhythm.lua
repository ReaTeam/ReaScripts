--[[
ReaScript name: js_Notation - Set beaming of selected notes to custom rhythm.lua
Version: 1.25
Author: juliansader
Website: http://forum.cockos.com/showthread.php?t=172782&page=25
About:
  # Description
  This script allows the user to easily change the beaming of syncopated measures where the rhythm
  does not follow the prevailing time signature.
  
  # Instructions
  The script can correctly beam notes that are played slightly ahead of the beat.  The user can 
  set the margin of leeway in the dialog box:  A note that starts within one margin length ahead 
  of the next beat will be beamed together with the next beat -- but only if the larger part of 
  the note's length falls in the next beat.
  
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
  * v1.25 (2020-04-26)
    + Faster execution (though not yet optimal).
    + Applies to all editable takes, if editability follows selection.
    + Margin can be set in dialog box.
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
reaper.defer()

local tableDivs = {}
local tTakeNotes = {}

--------------------------------------------------------------------------------------------
-- REAPER remembers individualized grid settings for each take.  Therefore, to 
--    get the most recent grid setting of MIDI editor, must get active take's.
-- (REAPER's GetTake is buggy, so the returned value is sometimes an invalid, deleted take.)
editor = reaper.MIDIEditor_GetActive()
if not editor or reaper.MIDIEditor_GetMode(editor) == -1 then
    reaper.MB("Could not find an active MIDI Editor", "ERROR", 0)
    return
end
activeTake = reaper.MIDIEditor_GetTake(editor)
if not reaper.ValidatePtr2(0, activeTake, "MediaItem_Take*") then 
    reaper.MB("Could not determine the active take of the MIDI editor", "ERROR", 0)
    return 
end
activeItem = reaper.GetMediaItemTake_Item(activeTake)
grid, _, _ = reaper.MIDI_GetGrid(activeTake)


---------------------------------------------------------------------------------------------------
-- Get user rhythm and convert it into a table of (normalized, cumulative) divisions of the measure
-- For example, 3-3-2 is converted into {0, 0.375, 0.75, 1)  

-- The script can be edited to skip user input, and automatically apply the default beaming
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
-- Ask user input
else
    repeat
        OKorCancel, input = reaper.GetUserInputs("Set beaming to custom rhythm",
                                                  2,
                                                  "Rhythm,Margin (1/xxx)",
                                                  defaultRhythm..","..string.format("%i", 4//grid))
        if OKorCancel == false then return end
        
        total = 0
        comma = input:reverse():find(",")
        if comma and comma > 1 then
            grid   = tonumber(input:sub(-comma, nil):match("%d+") or "")
        
            rhythm = input:sub(1, -comma-1)
            tableDivs = {}
            tableDivs[1] = 0 
            for div in rhythm:gmatch("%d+") do
                div = tonumber(div)
                if div > 0 then
                    total = total + div
                    table.insert(tableDivs, total)
                end
            end
        end
    until grid and total > 0
    grid = 4/grid
end

-- Normalize table entries
for i = 1, #tableDivs do
    tableDivs[i] = tableDivs[i]/total
end


-----------------------------------------------------------------------------
-- OK, we have got usable user inputs and at least one take in the editor, so
--    the script can start to make changes.
reaper.Undo_BeginBlock()

---------------------------------------------------------------------
-- Unfortunately, REAPER's API does not include functions that return 
--    all the editable items in a specified MIDI editor.
-- If editability is linked to selection in arrange view, editable 
--    takes can be found as follows: 
local _, _, sectionID, commandID = reaper.get_action_context()
local midiSettingOK, midiSetting = reaper.get_config_var_string("midieditor") -- One MIDI editor per project?
if midiSettingOK and tonumber(midiSetting)&3 == 1
--and reaper.GetToggleCommandStateEx(sectionID, 40874) == 1 -- Options: Draw and edit CC events on all tracks
and reaper.GetToggleCommandStateEx(sectionID, 40892) == 1 -- Options: MIDI track list/media item lane selection is linked to visibility
and reaper.GetToggleCommandStateEx(sectionID, 40891) == 1 -- Options: MIDI track list/media item lane selection is linked to editability
then
    local allTracks = (reaper.GetToggleCommandStateEx(sectionID, 40901) == 0) -- Options: Avoid automatically setting MIDI items from other tracks editable
    for i = 0, reaper.CountSelectedMediaItems(0)-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        if item and reaper.ValidatePtr2(0, item, "MediaItem*") then
            local track = reaper.GetMediaItem_Track(item)
            if allTracks or track == activeTrack then
                local take = reaper.GetActiveTake(item)
                if take and reaper.ValidatePtr2(0, take, "MediaItem_Take*") and reaper.TakeIsMIDI(take) then                       
                    n = reaper.MIDI_EnumSelNotes(take, -1) -- note index
                    -- Are there any selected notes in take?
                    if reaper.MIDI_EnumSelNotes(take, -1) ~= -1 then     
                        tTakeNotes[take] = {}                                 
                    end -- if n ~= -1 then 
                end -- if reaper.ValidatePtr2(0, curItem, "MediaItem_Take*") and reaper.TakeIsMIDI(take)
            end -- if allTracks or track == activeTrack then
        end -- if item and item ~= activeItem and reaper.ValidatePtr2(0, item, "MediaItem*")
    end -- for i = 0, reaper.CountSelectedMediaItems(0)-1
end -- If multiple takes

for take in pairs(tTakeNotes) do    
                          
    local ppq = reaper.MIDI_GetPPQPosFromProjQN(take, reaper.MIDI_GetProjQNFromPPQPos(take, 0) + 1)
    local gridPPQ = ppq*grid 
    
    for i = 1, #tableDivs-1 do
        tTakeNotes[take][i] = {}
    end
    
    n = -1
    do ::GetNextSelNote::
        n = reaper.MIDI_EnumSelNotes(take, n)
        if n == -1 then goto GotAllSelNotes end
        
        local noteOK, _, _, noteStart, noteEnd, _, _, _ = reaper.MIDI_GetNote(take, n)
        local measureStart = reaper.MIDI_GetPPQPos_StartOfMeasure(take, noteStart+1)
        local measureEnd = reaper.MIDI_GetPPQPos_EndOfMeasure(take, noteStart+1)
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
                table.insert(tTakeNotes[take][d], n)
            end
        end
        goto GetNextSelNote
        
    ::GotAllSelNotes:: end
    
    reaper.MIDI_DisableSort(take)
    --reaper.MIDI_SelectAll(take, false)
end

----------------------------------------------------------------------------
-- Select notes division-by-division and take-by-take
-- In REAPER v5.23, the "Beam notes together" action does not work correctly
--    if notes are selected in multiple tracks of staves simultaneously.
for div = 1, #tableDivs-1 do
    for take, tDivNotes in pairs(tTakeNotes) do
        reaper.MIDI_SelectAll(take, false) -- Clear selection
        for _, index in ipairs(tDivNotes[div]) do
            reaper.MIDI_SetNote(take, index, true, nil, nil, nil, nil, nil, nil, true)
        end
    end
    --reaper.GetUserInputs("",1,"","")
    reaper.MIDIEditor_OnCommand(editor, 41045) -- Beam notes together
    -- In REAPER v5.23, "Minimize ties" does not always work, since it is a toggle
    reaper.MIDIEditor_OnCommand(editor, 41749) -- Minimize ties
end 

-----------------------------------------------------------------
-- And finally, re-select all notes that were originally selected
for take, tDivNotes in pairs(tTakeNotes) do 
    for _, tNotes in ipairs(tDivNotes) do
        for _, index in ipairs(tNotes) do
            reaper.MIDI_SetNote(take, index, true, nil, nil, nil, nil, nil, nil, true)
        end
    end
    reaper.MIDI_Sort(take)
end

for take, tDivNotes in pairs(tTakeNotes) do
  tTakeNotes[tostring(take)] = tTakeNotes[take]
end

reaper.Undo_EndBlock("Set beaming to custom rhythm", -1)

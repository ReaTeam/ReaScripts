-- @description ReaKS - Keyswitch Articulation Manager
-- @author Ugurcan Orcun
-- @version 0.3
-- @changelog Added CC Renaming Helper /n Settings now saved between sessions /n Added ReaStash link to find more note names /n Minor layout changes
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=288344
-- @about A small MIDI Editor tool for auto-inserting KeySwitch midi notes and managing note/cc names.

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8.7')

ActiveMidiEditor = nil
PreviousMidiEditor = nil
ActiveTake = nil
ActiveTrack = nil
Articulations = {}
CC = {}
ActivatedArticulations = {}

Setting_AutoupdateTextEvent = true
Setting_MaxColumns = 2

Modal_Settings = false

PPQ = reaper.SNM_GetIntConfigVar("miditicksperbeat", 960)

function SaveSettings()
    reaper.SetExtState("ReaKS", "Setting_AutoupdateTextEvent", tostring(Setting_AutoupdateTextEvent), true)
    reaper.SetExtState("ReaKS", "Setting_MaxColumns", tostring(Setting_MaxColumns), true)
end

function LoadSettings()
    local val
    val = reaper.GetExtState("ReaKS", "Setting_AutoupdateTextEvent")
    if val ~= "" then Setting_AutoupdateTextEvent = val == "true" end

    val = reaper.GetExtState("ReaKS", "Setting_MaxColumns")
    if val ~= "" then Setting_MaxColumns = tonumber(val) end    
end

function UpdateActiveTargets()
    ActiveMidiEditor = reaper.MIDIEditor_GetActive() or nil
    ActiveTake = reaper.MIDIEditor_GetTake(ActiveMidiEditor) or nil
    if ActiveTake ~= nil then ActiveTrack = reaper.GetMediaItemTake_Track(ActiveTake) end

    if ActiveTake ~= nil and ActiveTake ~= PreviousTake then
        Articulations = {}
        CC = {}
        RefreshGUI()
    end

    PreviousTake = ActiveTake
end

function UpdateTextEvents()
    if ActiveTake == nil then return end

    --Clear all text events first
    local _, _, _, TextSysexEventCount = reaper.MIDI_CountEvts(ActiveTake)
    for TextSysexEvent = TextSysexEventCount, 1, -1 do
        local _, _, _, _, eventType, _, _ = reaper.MIDI_GetTextSysexEvt(ActiveTake, TextSysexEvent - 1)
        if eventType == 1 then
            reaper.MIDI_DeleteTextSysexEvt(ActiveTake, TextSysexEvent - 1)
        end
    end

    --Insert a text event for each note event that's in the articulation list
    local _, noteCount = reaper.MIDI_CountEvts(ActiveTake)
    for noteID = 1, noteCount do
        local _, _, _, startppqpos, _, _, pitch, _ = reaper.MIDI_GetNote(ActiveTake, noteID - 1)
        if Articulations[pitch] ~= nil then
            reaper.MIDI_InsertTextSysexEvt(ActiveTake, false, false, startppqpos, 1, Articulations[pitch])
        end
    end
end

function LoadNoteNames()
    Articulations = {}
    CC = {}
    reaper.MIDIEditor_LastFocused_OnCommand(40409, false)    
    RefreshGUI()
end

function ParseNoteNamesFromTrack()
    if ActiveTake == nil then return end
    for i = 0, 127 do
        local notename = reaper.GetTrackMIDINoteNameEx(0, ActiveTrack, i, 0)
        if notename ~= nil then
            Articulations[i] = notename
        end
    end
end

function ParseCCNamesFromTrack()
    if ActiveTake == nil then return end
    for i = 128, 255 do
        local ccname = reaper.GetTrackMIDINoteNameEx(0, ActiveTrack, i, 0)
        if ccname ~= nil then
            CC[i] = ccname
        end
    end
end

function FocusToCCLane(i)
    reaper.BR_MIDI_CCLaneReplace(ActiveMidiEditor, 0, i)
end

function RenameAliasCCLane()
    reaper.MIDIEditor_LastFocused_OnCommand(40416, false)
    RefreshGUI()
end

function SaveNoteNames()
    reaper.MIDIEditor_LastFocused_OnCommand(40410, false)    
end

function ClearNoteNames()
    reaper.MIDIEditor_LastFocused_OnCommand(40412, false)
    Articulations = {}
    CC = {}
end

function ToggleNote(noteNumber)
    --Delete articulation if exists
    if(ActivatedArticulations[noteNumber]) then
        reaper.MIDI_DeleteNote(ActiveTake, ActivatedArticulations[noteNumber])
    else
        --Check if any midi notes are selected. Get earliest start time and latest end time if any selected notes.
        local _, noteCount = reaper.MIDI_CountEvts(ActiveTake)
        local earliestStartTime = math.huge
        local latestEndTime = 0

        if noteCount ~= 0 then
            for noteID = 1, noteCount do
                local _, selected, _, startppqpos, endppqpos, _, _, _ = reaper.MIDI_GetNote(ActiveTake, noteID - 1)
                if selected then
                    if startppqpos < earliestStartTime then earliestStartTime = startppqpos end
                    if endppqpos > latestEndTime then latestEndTime = endppqpos end
                end
            end
        end

        -- Start time -1 because giving time to Reaper to process the note
        if earliestStartTime == math.huge then
            --Add articulation to playhead position
            local playheadPosition = reaper.GetCursorPosition()
            local playheadPosition = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, playheadPosition)
            local length = playheadPosition + (reaper.MIDI_GetGrid(ActiveTake) * PPQ)
            reaper.MIDI_InsertNote(ActiveTake, false, false, playheadPosition - 1, length, 0, noteNumber, 100, false)
        else
            --Add articulation to selected notes
            reaper.MIDI_InsertNote(ActiveTake, false, false, earliestStartTime - 1, latestEndTime, 0, noteNumber, 100, false)
        end
    end

    if Setting_AutoupdateTextEvent then UpdateTextEvents() end
end

function GetActiveArticulationsAtPlayheadPosition()
    if ActiveTake == nil then return end

        ActivatedArticulations = {}
        local playheadPosition

        playheadPosition = reaper.GetPlayState() == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
        playheadPosition = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, playheadPosition)
        
        local _, noteCount = reaper.MIDI_CountEvts(ActiveTake)
        
        for noteID = 1, noteCount do
            local _, _, _, startppqpos, endppqpos, _, pitch, _ = reaper.MIDI_GetNote(ActiveTake, noteID - 1)
            if startppqpos <= playheadPosition and endppqpos >= playheadPosition then                
                if Articulations[pitch] ~= nil then
                        ActivatedArticulations[pitch] = noteID - 1
                end
            end
        end
end

function GetActiveArticulationsAtNoteSelection()
    if ActiveTake == nil then return end

    ActivatedArticulations = {}
    local earliestStartTime = math.huge
    local latestEndTime = 0

    local note = -2
	while note ~= -1 do
		note = reaper.MIDI_EnumSelNotes(ActiveTake, note)

        local _, _, _, startppqpos, endppqpos, _, pitch, _ = reaper.MIDI_GetNote(ActiveTake, note)
        if Articulations[pitch] ~= nil then
            if startppqpos < earliestStartTime then earliestStartTime = startppqpos end
            if endppqpos > latestEndTime then latestEndTime = endppqpos end 
        end
	end

    --check all notes if it's an Articulation and if it's in the selected time range. If so, add it to the ActivatedArticulations list.
    local midiNoteCount = reaper.FNG_CountMidiNotes(ActiveTake)

    for i = 0, midiNoteCount - 1 do
        local _, _, _, startppqpos, endppqpos, _, pitch, _ = reaper.MIDI_GetNote(ActiveTake, i)

        if startppqpos <= latestEndTime and endppqpos >= earliestStartTime then
            if Articulations[pitch] ~= nil then
                ActivatedArticulations[pitch] = i
            end
        end
    end
end

function RefreshGUI()
    UpdateTextEvents()
    ParseNoteNamesFromTrack()
    ParseCCNamesFromTrack()
end

-- UI Part
local ctx = reaper.ImGui_CreateContext('ReaKS')
local function loop()
    local visible, open = reaper.ImGui_Begin(ctx, 'ReaKS', true)    
    if visible then

        reaper.ImGui_BeginGroup(ctx)
        reaper.ImGui_SeparatorText(ctx, "Note Name Maps")
        if reaper.ImGui_Button(ctx, "Load") then LoadNoteNames() end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Save") then SaveNoteNames() end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Clear") then ClearNoteNames() end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Refresh") then RefreshGUI()end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, "Settings") then Modal_Settings = not Modal_Settings end
        reaper.ImGui_EndGroup(ctx)

        --TODO Make the settings modal
        if Modal_Settings then
            local val
            
            reaper.ImGui_BeginGroup(ctx)
            reaper.ImGui_SeparatorText(ctx, "Settings")

            if reaper.ImGui_Checkbox(ctx, "Autorefresh Text Events", Setting_AutoupdateTextEvent) then 
                Setting_AutoupdateTextEvent = not Setting_AutoupdateTextEvent 
                SaveSettings()
            end

            _, val = reaper.ImGui_SliderInt(ctx, "Max Rows", Setting_MaxColumns, 1, 10)
            if val ~= Setting_MaxColumns then
                Setting_MaxColumns = val
                SaveSettings()
            end

            if reaper.ImGui_Button(ctx, "Rename Last Clicked CC Lane") then RenameAliasCCLane() end
            if reaper.ImGui_Button(ctx, "Find More Note Names >>>") then reaper.CF_ShellExecute("https://stash.reaper.fm/tag/Key-Maps") end
            
            reaper.ImGui_EndGroup(ctx)
        end

        if ActiveTake == nil and Articulations ~= nil then
            reaper.ImGui_Text(ctx, "No active MIDI take is open in the MIDI editor.")
        else
            reaper.ImGui_SeparatorText(ctx, "Articulations")
            
            --TODO Make the table upside down
            reaper.ImGui_BeginTable(ctx, "Articulations", Setting_MaxColumns)
            
            for i = 0, 127 do
                if Articulations[i] ~= nil then
                    reaper.ImGui_TableNextColumn(ctx)
                    local articulation = Articulations[i]
                    if reaper.ImGui_Checkbox(ctx, articulation, ActivatedArticulations[i] ~= nil) then
                        ToggleNote(i)
                    end
                end
            end
            reaper.ImGui_EndTable(ctx)
        end

        if ActiveTake ~= nil and CC ~= nil then
            reaper.ImGui_SeparatorText(ctx, "Focus CC Lane")
            for i = 128, 255 do
                if CC[i] ~= nil then
                    if reaper.ImGui_Button(ctx, CC[i] .. " (CC" .. i - 128 .. ")") then FocusToCCLane(i-128) end
                end
            end
        end

        -- if reaper.ImGui_Button(ctx, "Test") then GetActiveArticulationsAtNoteSelection() end

        reaper.ImGui_End(ctx)
    end
    
    UpdateActiveTargets()
    GetActiveArticulationsAtPlayheadPosition()

    if open then
        reaper.defer(loop)
    end
end

LoadSettings()
reaper.defer(loop)
-- @description ReaKS - Keyswitch Articulation Manager
-- @author Ugurcan Orcun
-- @version 0.6
-- @changelog 
--  Updated styling
--  Changed CC pane layout
--  Added Velocity/Pitch focus buttons
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=288344
-- @about 
--  A small MIDI Editor tool for auto-inserting KeySwitch midi notes and managing note/cc names.
--  Find more info and example note name files at the forum thread.

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8.7')

ActiveMidiEditor = nil
PreviousMidiEditor = nil
ActiveTake = nil
ActiveTrack = nil
Articulations = {}
CC = {}
ActivatedArticulations = {}


EnumThemeColors = {
    A = 0x0c1017ff, -- Background
    B = 0x212226FF, -- Default
    C = 0xa4adceFF, -- Active
    D = 0x636672FF, -- Hovered    
    E = 0xa7a8abff, -- HeaderText
    F = 0xFFFFFFFF -- Text
}

FontTitle = reaper.ImGui_CreateFont('sans-serif', 24, reaper.ImGui_FontFlags_Italic())
Font = reaper.ImGui_CreateFont('sans-serif', 14)

ActiveTakeName = nil
ActiveTrackName = nil
ActiveTrackColor = 0xFFFFFFFF

Setting_AutoupdateTextEvent = true
Setting_MoveEditCursor = true
Setting_MaxColumns = 2
Setting_FontSizeMultiplier = 1

Modal_Settings = false

PPQ = reaper.SNM_GetIntConfigVar("miditicksperbeat", 960)

function SaveSettings()
    reaper.SetExtState("ReaKS", "Setting_AutoupdateTextEvent", tostring(Setting_AutoupdateTextEvent), true)
    reaper.SetExtState("ReaKS", "Setting_MaxColumns", tostring(Setting_MaxColumns), true)
    reaper.SetExtState("ReaKS", "Setting_MoveEditCursor", tostring(Setting_MoveEditCursor), true)
    reaper.SetExtState("ReaKS", "Setting_FontSizeMultiplier", tostring(Setting_MoveEditCursor), true)
end

function LoadSettings()
    local val
    val = reaper.GetExtState("ReaKS", "Setting_AutoupdateTextEvent")
    if val ~= "" then Setting_AutoupdateTextEvent = val == "true" end

    val = reaper.GetExtState("ReaKS", "Setting_MaxColumns")
    if val ~= "" then Setting_MaxColumns = tonumber(val) end    

    val = reaper.GetExtState("ReaKS", "Setting_MoveEditCursor")
    if val ~= "" then Setting_MoveEditCursor = val == "true" end

    val = reaper.GetExtState("ReaKS", "Setting_FontSizeMultiplier")
    if val ~= "" then Setting_FontSizeMultiplier = tonumber(val) end
end

function UpdateActiveTargets()
    ActiveMidiEditor = reaper.MIDIEditor_GetActive() or nil
    ActiveTake = reaper.MIDIEditor_GetTake(ActiveMidiEditor) or nil
    if ActiveTake ~= nil then ActiveTrack = reaper.GetMediaItemTake_Track(ActiveTake) end

    if ActiveTake ~= nil and ActiveTake ~= PreviousTake then
        Articulations = {}
        CC = {}
        RefreshGUI()

        ActiveTakeName = reaper.GetTakeName(ActiveTake)
        _, ActiveTrackName = reaper.GetTrackName(ActiveTrack)

        ActiveTrackColor = reaper.GetTrackColor(ActiveTrack)
        if ActiveTrackColor == 0 then ActiveTrackColor = 0xFFFFFFFF end

        local r, g, b = reaper.ColorFromNative(ActiveTrackColor)
        ActiveTrackColor = reaper.ImGui_ColorConvertDouble4ToU32(r/255, g/255, b/255, 1)
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

function SaveNoteNames()
    reaper.MIDIEditor_LastFocused_OnCommand(40410, false)    
end

function ClearNoteNames()
    reaper.MIDIEditor_LastFocused_OnCommand(40412, false)
    Articulations = {}
    CC = {}
end

function ParseNoteNamesFromTake()
    if ActiveTake == nil then return end

    Articulations = {}
    for i = 0, 127 do
        local notename = reaper.GetTrackMIDINoteNameEx(0, ActiveTrack, i, 0)
        if notename ~= nil then
            Articulations[i] = notename
        end
    end
end

function ParseCCNamesFromTake()
    if ActiveTake == nil then return end

    CC = {}
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

function ToggleNote(noteNumber)
    if(ActivatedArticulations[noteNumber]) then --Delete articulation if exists
        reaper.MIDI_DeleteNote(ActiveTake, ActivatedArticulations[noteNumber])
    else --Or insert articulation
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

        -- Start time offsetted by -1 ppq to activate the articulation before the note
        if earliestStartTime == math.huge then
            --Add articulation to playhead position
            local playheadPosition = reaper.GetCursorPosition()
            local playheadPosition = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, playheadPosition)
            local length = playheadPosition + (reaper.MIDI_GetGrid(ActiveTake) * PPQ)
            reaper.MIDI_InsertNote(ActiveTake, false, false, playheadPosition - 1, length, 0, noteNumber, 100, false)
        else
            --Add articulation to selected notes
            reaper.MIDI_InsertNote(ActiveTake, false, false, earliestStartTime - 1, latestEndTime, 0, noteNumber, 100, false)
            reaper.SetEditCurPos(reaper.MIDI_GetProjTimeFromPPQPos(ActiveTake, earliestStartTime), Setting_MoveEditCursor, false)
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

function RefreshGUI()
    UpdateTextEvents()
    ParseNoteNamesFromTake()
    ParseCCNamesFromTake()
end

function StylingStart(ctx)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), EnumThemeColors.A)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), EnumThemeColors.B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), EnumThemeColors.C)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), EnumThemeColors.D)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), EnumThemeColors.B)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgActive(), EnumThemeColors.C)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBgHovered(), EnumThemeColors.D)

    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), EnumThemeColors.F)

    reaper.ImGui_PushFont(ctx, Font)
end

function StylingEnd(ctx)
    reaper.ImGui_PopStyleColor(ctx, 8)
    reaper.ImGui_PopFont(ctx)
end

-- UI Part
local ctx = reaper.ImGui_CreateContext('ReaKS')
reaper.ImGui_Attach(ctx, Font)
reaper.ImGui_Attach(ctx, FontTitle)

local function loop()
    StylingStart(ctx)

    local visible, open = reaper.ImGui_Begin(ctx, 'ReaKS', true)    
    if visible then
        
        if (ActiveTakeName ~= nil and ActiveTrackName ~= nil) then
            reaper.ImGui_PushFont(ctx, FontTitle)
            reaper.ImGui_TextColored(ctx, ActiveTrackColor, ActiveTrackName .. " - " .. ActiveTakeName)
            reaper.ImGui_PopFont(ctx)
        end

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

            if reaper.ImGui_Checkbox(ctx, "Automove Cursor ", Setting_MoveEditCursor) then 
                Setting_MoveEditCursor = not Setting_MoveEditCursor 
                SaveSettings()
            end

            _, val = reaper.ImGui_SliderInt(ctx, "Max Rows", Setting_MaxColumns, 1, 10)
            if val ~= Setting_MaxColumns then
                Setting_MaxColumns = val
                SaveSettings()
            end

            if reaper.ImGui_Button(ctx, "Find More Note Names >>>") then reaper.CF_ShellExecute("https://stash.reaper.fm/tag/Key-Maps") end
            
            reaper.ImGui_EndGroup(ctx)
        end

        if ActiveTake == nil then
            reaper.ImGui_Separator(ctx)
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
 
        if ActiveTake ~= nil then
            reaper.ImGui_SeparatorText(ctx, "Focus to CC Lane")
            for i = 128, 255 do
                if CC[i] ~= nil then
                    reaper.ImGui_Text(ctx, CC[i] .. " (CC" .. i - 128 .. ")" )
                    reaper.ImGui_SameLine(ctx, reaper.ImGui_GetWindowWidth(ctx) - (reaper.ImGui_CalcTextSize(ctx, "Focus") * 2))
                    if reaper.ImGui_Button(ctx, "Focus##"..i) then FocusToCCLane(i-128) end
                end
            end

            reaper.ImGui_Text(ctx, "Velocity")
            reaper.ImGui_SameLine(ctx, reaper.ImGui_GetWindowWidth(ctx) - (reaper.ImGui_CalcTextSize(ctx, "Focus") * 2))
            if reaper.ImGui_Button(ctx, "Focus##velocity") then FocusToCCLane(512) end

            reaper.ImGui_Text(ctx, "Pitch")
            reaper.ImGui_SameLine(ctx, reaper.ImGui_GetWindowWidth(ctx) - (reaper.ImGui_CalcTextSize(ctx, "Focus") * 2))
            if reaper.ImGui_Button(ctx, "Focus##pitch") then FocusToCCLane(513) end

            if reaper.ImGui_Button(ctx, "Rename Last Clicked CC Lane...") then RenameAliasCCLane() end
        end

        StylingEnd(ctx)
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

-- @description ReaKS - Keyswitch Articulation Manager
-- @author Ugurcan Orcun
-- @version 1.3.0
-- @changelog 
--  - Added Chase mode: Set new KS length to start of the next KS or MIDI item's end
-- @links
--   Forum Thread https://forum.cockos.com/showthread.php?t=288344
--   Tutorials https://www.youtube.com/watch?v=lP9hRw_j0PY&list=PLJ5Z3ZQ-oB-yXcsq3MXi94QhYVcnlkhVy
-- @donation https://kabraxis.itch.io/reaks
-- @about 
--  A small MIDI Editor tool for auto-inserting KeySwitch midi notes and managing note/cc names.
--  Find more info and example note name files at the forum thread.
if not reaper.ImGui_GetBuiltinPath then
    return reaper.MB('ReaImGui is not installed or too old.', 'ReaKS', 0)
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'

ActiveMidiEditor = nil
PreviousMidiEditor = nil
ActiveTake = nil
ActiveItem = nil
ActiveTrack = nil
MIDIHash = nil
PreviousMIDIHash = nil
Articulations = {}
CC = {}
ActivatedKS = {}

function ThemeColorToImguiColor(themeColorName)
    local color = reaper.GetThemeColor(themeColorName, 0)
    local r, g, b = reaper.ColorFromNative(color)
    return ImGui.ColorConvertDouble4ToU32(r/255, g/255, b/255, 1)
end

EnumThemeColors = { -- fetch colors from Reaper theme
    A = ThemeColorToImguiColor("col_tracklistbg"), -- Background
    B = ThemeColorToImguiColor("col_tracklistbg") + 0x111111FF, -- Default Interactive
    C = ThemeColorToImguiColor("col_tracklistbg") + 0x444444FF, -- Clicked
    D = ThemeColorToImguiColor("col_tracklistbg") + 0x222222FF, -- Hovered    
    E = ThemeColorToImguiColor("col_tcp_text"), -- HeaderText
    F = 0xFFFFFFFF, -- Text
    G = ThemeColorToImguiColor("midi_editcurs") -- Active Articulation
}

InsertionModes = {
    "Single",
    "Multi"
}

FontTitle = ImGui.CreateFont('sans-serif', 24, ImGui.FontFlags_Italic)
Font = ImGui.CreateFont('sans-serif', 14)

ActiveTakeName = nil
ActiveTrackName = nil
ActiveTrackColor = 0xFFFFFFFF

Setting_AutoupdateTextEvent = true
Setting_ItemsPerColumn = 10
Setting_PPQOffset = -1
Setting_SendNoteWhenClicked = false
Setting_ChaseMode = false

Modal_Settings = false
Modal_NoteNameHelper = false

Injector_NotesList = ""
Injector_FirstNoteID = 36

PPQ = reaper.SNM_GetIntConfigVar("miditicksperbeat", 960)

function SaveSettings()
    reaper.SetExtState("ReaKS", "Setting_AutoupdateTextEvent", tostring(Setting_AutoupdateTextEvent), true)
    reaper.SetExtState("ReaKS", "Setting_ItemsPerColumn", tostring(Setting_ItemsPerColumn), true)
    reaper.SetExtState("ReaKS", "Setting_PPQOffset", tostring(Setting_PPQOffset), true)
    reaper.SetExtState("ReaKS", "Setting_SendNoteWhenClicked", tostring(Setting_SendNoteWhenClicked), true)
    reaper.SetExtState("ReaKS", "Setting_ChaseMode", tostring(Setting_ChaseMode), true)
end

function LoadSettings()
    local val
    val = reaper.GetExtState("ReaKS", "Setting_AutoupdateTextEvent")
    if val ~= "" then Setting_AutoupdateTextEvent = val == "true" end

    val = reaper.GetExtState("ReaKS", "Setting_ItemsPerColumn")
    if val ~= "" then Setting_ItemsPerColumn = tonumber(val) end

    val = reaper.GetExtState("ReaKS", "Setting_PPQOffset")
    if val ~= "" then Setting_PPQOffset = tonumber(val) end

    val = reaper.GetExtState("ReaKS", "Setting_SendNoteWhenClicked")
    if val ~= "" then Setting_SendNoteWhenClicked = val == "true" end

    val = reaper.GetExtState("ReaKS", "Setting_ChaseMode")
    if val ~= "" then Setting_ChaseMode = val == "true" end
end

function UpdateActiveTargets()
    ActiveMidiEditor = reaper.MIDIEditor_GetActive() or nil
    ActiveTake = reaper.MIDIEditor_GetTake(ActiveMidiEditor) or nil
    if ActiveTake ~= nil then ActiveTrack = reaper.GetMediaItemTake_Track(ActiveTake) end
    if ActiveTake ~= nil then ActiveItem = reaper.GetMediaItemTake_Item(ActiveTake) end

    if ActiveTake ~= nil and ActiveTake ~= PreviousTake then
        Articulations = {}
        CC = {}
        RefreshGUI()

        ActiveTakeName = reaper.GetTakeName(ActiveTake)
        _, ActiveTrackName = reaper.GetTrackName(ActiveTrack)

        ActiveTrackColor = reaper.GetTrackColor(ActiveTrack)
        if ActiveTrackColor == 0 then ActiveTrackColor = 0xFFFFFFFF end

        local r, g, b = reaper.ColorFromNative(ActiveTrackColor)
        ActiveTrackColor = ImGui.ColorConvertDouble4ToU32(r/255, g/255, b/255, 1)
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

function InjectNoteNames(noteNames, firstNoteID)
    if ActiveTake == nil then return end
    local noteNameTable = {}
    for noteName in string.gmatch(noteNames, "([^\n]+)") do
        table.insert(noteNameTable, noteName)
    end

    for i, noteName in ipairs(noteNameTable) do
        reaper.SetTrackMIDINoteNameEx(0, ActiveTrack, firstNoteID + i - 1, 0, noteName)
    end

    RefreshGUI()
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

function InsertKS(noteNumber, isShiftHeld)
    if ActiveTake == nil then return end

    local newKSStartPPQ, newKSEndPPQ

    local insertionRangeStart = math.huge
    local insertionRangeEnd = 0
    local selectionMode = false

    local MIDIItemEndPPQ = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, reaper.GetMediaItemInfo_Value(ActiveItem, "D_POSITION") + reaper.GetMediaItemInfo_Value(ActiveItem, "D_LENGTH"))

    local singleGridLength = reaper.MIDI_GetGrid(ActiveTake) * PPQ

    reaper.MIDI_DisableSort(ActiveTake)

    -- Find the earliest start time and latest end time of selected notes, if any
    if reaper.MIDI_EnumSelNotes(ActiveTake, -1) ~= -1 then
        selectionMode = true

        local selectedNoteIDX = -1
        selectedNoteIDX = reaper.MIDI_EnumSelNotes(ActiveTake, selectedNoteIDX)

        while selectedNoteIDX ~= -1 do
            local _, _, _, selectedNoteStartPPQ, selectedNoteEndPPQ = reaper.MIDI_GetNote(ActiveTake, selectedNoteIDX)         

            insertionRangeStart = math.min(insertionRangeStart, selectedNoteStartPPQ)
            insertionRangeEnd = math.max(insertionRangeEnd, selectedNoteEndPPQ)
            selectedNoteIDX = reaper.MIDI_EnumSelNotes(ActiveTake, selectedNoteIDX)
        end
    -- Find playhead and one exact grid length after it if no notes are selected
    else
        insertionRangeStart = reaper.GetCursorPosition()
        insertionRangeStart = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, insertionRangeStart)
        
        if Setting_ChaseMode then
            insertionRangeEnd = MIDIItemEndPPQ
        else 
            insertionRangeEnd = insertionRangeStart + singleGridLength
        end
    end

    newKSStartPPQ = insertionRangeStart + Setting_PPQOffset
    newKSEndPPQ = insertionRangeEnd + Setting_PPQOffset

    -- Operations on other KS notes
    local _, noteCount = reaper.MIDI_CountEvts(ActiveTake)        
    if not isShiftHeld then
        for noteID = noteCount, 0, -1 do
            local _, _, _, startPosPPQ, endPosPPQ, _, pitch, _ = reaper.MIDI_GetNote(ActiveTake, noteID)
            newKSStartPPQ = insertionRangeStart + Setting_PPQOffset
            newKSEndPPQ = insertionRangeEnd + Setting_PPQOffset

            -- Process overlapping notes
            if Articulations[pitch] then
                if startPosPPQ < newKSStartPPQ and endPosPPQ > newKSStartPPQ then reaper.MIDI_SetNote(ActiveTake, noteID, nil, nil, nil, newKSStartPPQ) end
                if startPosPPQ < newKSStartPPQ and endPosPPQ > newKSStartPPQ and endPosPPQ < newKSEndPPQ then reaper.MIDI_SetNote(ActiveTake, noteID, nil, nil, nil, newKSStartPPQ) end
                if startPosPPQ >= newKSStartPPQ and startPosPPQ < newKSEndPPQ and endPosPPQ > newKSEndPPQ then reaper.MIDI_SetNote(ActiveTake, noteID, nil, nil, newKSEndPPQ, nil) end
                if startPosPPQ >= newKSStartPPQ and endPosPPQ <= newKSEndPPQ then reaper.MIDI_DeleteNote(ActiveTake, noteID) end
            end
        end
    end

    reaper.Undo_BeginBlock()
    reaper.MarkTrackItemsDirty(ActiveTrack, ActiveItem)

    -- Insert the new KS note

    reaper.MIDI_InsertNote(ActiveTake, false, false, newKSStartPPQ, newKSEndPPQ, 0, noteNumber, 100, false)
    
    -- Move edit cursor to the end of the new note if no notes are selected
    if reaper.MIDI_EnumSelNotes(ActiveTake, -1) == -1 and not isShiftHeld then 
        local mouseMovePos = 0
        if Setting_ChaseMode then mouseMovePos = insertionRangeStart + singleGridLength else mouseMovePos = insertionRangeEnd end

        reaper.SetEditCurPos(reaper.MIDI_GetProjTimeFromPPQPos(ActiveTake, mouseMovePos), true, false) 
    end    

    -- Update text events if the setting is enabled
    if Setting_AutoupdateTextEvent then UpdateTextEvents() end

    reaper.Undo_EndBlock("Insert KS Note", -1)

    reaper.MIDI_Sort(ActiveTake)    
end

function SendMIDINote(noteNumber)
    --send a MIDI note to the virtual MIDI keyboard
    reaper.StuffMIDIMessage(0, 0x90, noteNumber, 100)

    --send note off
    reaper.StuffMIDIMessage(0, 0x80, noteNumber, 0)
end

function RemoveKS(noteNumber)
    if ActiveTake == nil then return end

    if ActivatedKS[noteNumber] ~= nil then
        reaper.MIDI_DeleteNote(ActiveTake, ActivatedKS[noteNumber])
    end    
end

function LengthenSelectedNotes(toLeft)
    if ActiveTake == nil then return end

    local selectedNoteIDX = -1
    local selectedNotes = {}

    selectedNoteIDX = reaper.MIDI_EnumSelNotes(ActiveTake, selectedNoteIDX)
    while selectedNoteIDX ~= -1 do
        table.insert(selectedNotes, selectedNoteIDX)
        selectedNoteIDX = reaper.MIDI_EnumSelNotes(ActiveTake, selectedNoteIDX)
    end

    reaper.Undo_BeginBlock()
    reaper.MarkTrackItemsDirty(ActiveTrack, ActiveItem)

    for _, noteID in pairs(selectedNotes) do
        local _, _, _, startPosPPQ, endPosPPQ, _, _, _ = reaper.MIDI_GetNote(ActiveTake, noteID)
        local moveAmount = PPQ / 32

        if toLeft then
            startPosPPQ = startPosPPQ - moveAmount
        else
            endPosPPQ = endPosPPQ + moveAmount
        end

        reaper.MIDI_SetNote(ActiveTake, noteID, nil, nil, startPosPPQ, endPosPPQ)
    end

    reaper.Undo_EndBlock("Lengthen Selected Notes", -1)
end

function GetActiveKSAtPlayheadPosition()
    if ActiveTake == nil then return end

    ActivatedKS = {}
    local playheadPosition

    playheadPosition = reaper.GetPlayState() == 1 and reaper.GetPlayPosition() or reaper.GetCursorPosition()
    playheadPosition = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, playheadPosition)
    
    local _, noteCount = reaper.MIDI_CountEvts(ActiveTake)
    
    for noteID = 1, noteCount do
        local _, _, _, startppqpos, endppqpos, _, pitch, _ = reaper.MIDI_GetNote(ActiveTake, noteID - 1)
        if startppqpos <= playheadPosition and endppqpos >= playheadPosition then                
            if Articulations[pitch] ~= nil then
                    ActivatedKS[pitch] = noteID - 1
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
    ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, EnumThemeColors.A)

    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ButtonTextAlign, 0, 0.5)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, EnumThemeColors.B)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, EnumThemeColors.C)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, EnumThemeColors.D)

    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, EnumThemeColors.B)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, EnumThemeColors.C)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, EnumThemeColors.D)

    ImGui.PushStyleColor(ctx, ImGui.Col_Text, EnumThemeColors.F)

    ImGui.PushStyleColor(ctx, ImGui.Col_Header, EnumThemeColors.B)
    ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, EnumThemeColors.C)
    ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered, EnumThemeColors.D)

    ImGui.PushStyleColor(ctx, ImGui.Col_CheckMark, EnumThemeColors.F)

    ImGui.PushFont(ctx, Font)
end

function StylingEnd(ctx)
    ImGui.PopStyleColor(ctx, 12)
    ImGui.PopStyleVar(ctx, 1)
    ImGui.PopFont(ctx)
end

-- UI Part
local ctx = ImGui.CreateContext('ReaKS')
ImGui.Attach(ctx, Font)
ImGui.Attach(ctx, FontTitle)

local function loop()
    StylingStart(ctx)

    local visible, open = ImGui.Begin(ctx, 'ReaKS', true)
    if visible then
               
        if (ActiveTakeName ~= nil and ActiveTrackName ~= nil) then
            ImGui.PushFont(ctx, FontTitle)
            ImGui.TextColored(ctx, ActiveTrackColor, ActiveTrackName .. ": " .. ActiveTakeName)
            ImGui.PopFont(ctx)
        end

        ImGui.BeginGroup(ctx)
        ImGui.SeparatorText(ctx, "Note Name Maps")
        if ImGui.Button(ctx, "Load") then LoadNoteNames() end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Save") then SaveNoteNames() end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Clear") then ClearNoteNames() end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Refresh") then RefreshGUI() end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Inject") then ImGui.OpenPopup(ctx, "Note Name Injector") end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Settings") then ImGui.OpenPopup(ctx, "Settings") end
        ImGui.SameLine(ctx)
        if ImGui.Button(ctx, "Help") then ImGui.OpenPopup(ctx, "Help") end
        ImGui.EndGroup(ctx)

        --TODO Make the settings modal
        if ImGui.BeginPopupModal(ctx, "Settings", true) then
            local val

            if ImGui.Checkbox(ctx, "Insert Text Events", Setting_AutoupdateTextEvent) then 
                Setting_AutoupdateTextEvent = not Setting_AutoupdateTextEvent 
                SaveSettings()
            end
            if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Automatically inserts text events for articulations that's visible on Arrange view. Use [Refresh] button after manual edits to update visuals.") end

            if ImGui.Checkbox(ctx, "Send MIDI Note", Setting_SendNoteWhenClicked) then 
                Setting_SendNoteWhenClicked = not Setting_SendNoteWhenClicked 
                SaveSettings()
            end
            if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Send a MIDI message when the KS button clicked. Good for previewing keyswitches.") end

            if ImGui.Checkbox(ctx, "Chase Mode", Setting_ChaseMode) then 
                Setting_ChaseMode = not Setting_ChaseMode 
                SaveSettings()
            end
            if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "When enabled, the KS note will be inserted until the end of the MIDI item.") end

            _, val = ImGui.SliderInt(ctx, "KS per Column", Setting_ItemsPerColumn, 1, 100)
            if val ~= Setting_ItemsPerColumn then
                Setting_ItemsPerColumn = val
                SaveSettings()
            end
            if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "How many KS buttons in a single column.") end

            _, val = ImGui.SliderInt(ctx, "New Note Offset", Setting_PPQOffset, -math.abs(PPQ/4), 0)  
            if val ~= Setting_PPQOffset then
                Setting_PPQOffset = val
                SaveSettings()
            end
            if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Negative offset for inserted KS note. Helps with triggering KS just before the note. Default is -1.") end

            ImGui.EndPopup(ctx)
        end

        if ImGui.BeginPopupModal(ctx, "Help", true) then
            ImGui.SeparatorText(ctx, "ReaKS - Key Switcher for REAPER")
            ImGui.Text(ctx, "Developed by Ugurcan Orcun (Kabraxis)")
            ImGui.Text(ctx, "Special thanks to cfillon for the ReaImGui library.")
            ImGui.Text(ctx, "This script is free to use and modify.")

            ImGui.SeparatorText(ctx, "How to Use")
            ImGui.Text(ctx, "Click: Smart Insert KS note at the selected notes or at playhead position (grid size)")
            ImGui.Text(ctx, "Shift-Click: Bypass Smart Insertion")
            ImGui.Text(ctx, "Alt-Click: Remove KS Note")
            ImGui.Text(ctx, "Ctrl-Click: Preview KeySwitch")

            ImGui.SeparatorText(ctx, "More Info")
            ImGui.Text(ctx, "Please visit the forum thread for more information.")
            if ImGui.Button(ctx, ">>> More Info (Forum Thread)", 200) then reaper.CF_ShellExecute("https://forum.cockos.com/showthread.php?t=288344") end
            ImGui.NewLine(ctx)
            ImGui.Text(ctx, "You can download note names from the links below.")
            if ImGui.Button(ctx, ">>> Download Note Names", 200) then reaper.CF_ShellExecute("https://kabraxis.itch.io/reaks") end
            if ImGui.Button(ctx, ">>> Download Community Note Names", 200) then reaper.CF_ShellExecute("https://stash.reaper.fm/tag/Key-Maps") end
            ImGui.EndPopup(ctx)
        end

        if ImGui.BeginPopupModal(ctx, "Note Name Injector", true) then
            _, Injector_NotesList = ImGui.InputTextMultiline(ctx, "Note Names", Injector_NotesList, 128, 256)
            ImGui.SetNextItemWidth(ctx, 128)
            _, Injector_FirstNoteID = ImGui.InputInt(ctx, "Starting Note ID", Injector_FirstNoteID)
            if ImGui.Button(ctx, "Inject!") then InjectNoteNames(Injector_NotesList, Injector_FirstNoteID) end
            ImGui.SameLine(ctx)
            if ImGui.Button(ctx, "Clear") then ClearNoteNames() end
            ImGui.EndPopup(ctx)
        end


        -- Articulations
        if ActiveTake == nil then
            ImGui.Separator(ctx)
            ImGui.Text(ctx, "No active MIDI take is open in the MIDI editor.")
        else
            if ImGui.CollapsingHeader(ctx, "Keyswitches", false) then
                local itemCount = 0
                ImGui.BeginGroup(ctx)

                for i = 0, 127 do
                    if Articulations[i] ~= nil then
                        local articulation = Articulations[i]

                        if ActivatedKS[i] ~= nil then ImGui.PushStyleColor(ctx, ImGui.Col_Button, EnumThemeColors.G) end

                        if ImGui.Button(ctx, articulation, 100) then
                            local isShiftHeld = ImGui.GetKeyMods(ctx) == ImGui.Mod_Shift
                            local isCtrlHeld = ImGui.GetKeyMods(ctx) == ImGui.Mod_Ctrl
                            local isAltHeld = ImGui.GetKeyMods(ctx) == ImGui.Mod_Alt
                            
                            if isCtrlHeld then 
                                SendMIDINote(i)
                            elseif isAltHeld then
                                RemoveKS(i)
                            else
                                InsertKS(i, isShiftHeld)                            
                                if Setting_SendNoteWhenClicked then SendMIDINote(i) end                                
                            end
                        end

                        if ActivatedKS[i] ~= nil then ImGui.PopStyleColor(ctx) end

                        itemCount = itemCount + 1
                        if itemCount % Setting_ItemsPerColumn == 0 then
                            ImGui.EndGroup(ctx)
                            ImGui.SameLine(ctx)
                            ImGui.BeginGroup(ctx) 
                        end
                    end
                end
                ImGui.EndGroup(ctx)
            end
        end 
        
        -- CC
        if ActiveTake ~= nil then
            if ImGui.CollapsingHeader(ctx, "CC Lanes", false) then
                for i = 128, 255 do
                    if CC[i] ~= nil then
                        ImGui.Text(ctx, CC[i] .. " (CC" .. i - 128 .. ")" )
                        ImGui.SameLine(ctx, ImGui.GetWindowWidth(ctx) - (ImGui.CalcTextSize(ctx, "Focus") * 2))
                        if ImGui.Button(ctx, "Focus##"..i) then FocusToCCLane(i-128) end
                    end
                end

                ImGui.Text(ctx, "Velocity")
                ImGui.SameLine(ctx, ImGui.GetWindowWidth(ctx) - (ImGui.CalcTextSize(ctx, "Focus") * 2))
                if ImGui.Button(ctx, "Focus##velocity") then FocusToCCLane(512) end

                ImGui.Text(ctx, "Pitch")
                ImGui.SameLine(ctx, ImGui.GetWindowWidth(ctx) - (ImGui.CalcTextSize(ctx, "Focus") * 2))
                if ImGui.Button(ctx, "Focus##pitch") then FocusToCCLane(513) end

                if ImGui.Button(ctx, "Rename Focused CC Lane") then RenameAliasCCLane() end
            end
        end

        -- MIDI Toolkit
        if ActiveTake ~= nil then
            if ImGui.CollapsingHeader(ctx, "MIDI Toolkit", false) then
                if ImGui.Button(ctx, "<+") then LengthenSelectedNotes(true) end
                if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Stretch selected note starts") end
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "+>") then LengthenSelectedNotes(false) end
                if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Lengthen selected note ends") end
                ImGui.SameLine(ctx)
                if ImGui.Button(ctx, "Quick Quantize") then reaper.MIDIEditor_LastFocused_OnCommand(40729, false) end
                if ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Conform selected notes to grid") end
            end
        end
        ImGui.End(ctx)        
    end

    StylingEnd(ctx)
    UpdateActiveTargets()
    GetActiveKSAtPlayheadPosition()

    if open then
        reaper.defer(loop)
    end
end

LoadSettings()
reaper.set_action_options(1)
reaper.defer(loop)

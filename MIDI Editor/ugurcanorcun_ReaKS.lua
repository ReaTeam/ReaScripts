-- @description ReaKS - Keyswitch Articulation Manager
-- @author Ugurcan Orcun
-- @version 0.9
-- @changelog 
--  ReaImGui Shim
--  Added 'Single' mode that tries to have only 1 KS active at a time.
--  (You still can switch to 'Multi' mode in 'Settings')
--  Colors now match your Reaper Theme's colors
--  Renamed 'Articulations' to 'KeySwitches' everywhere to lessen confusion
--  Ignoring KS midi notes as 'Selected'
--  Got rid of script termination popup
--  Fixed column order
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=288344
-- @about 
--  A small MIDI Editor tool for auto-inserting KeySwitch midi notes and managing note/cc names.
--  Find more info and example note name files at the forum thread.

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'

ActiveMidiEditor = nil
PreviousMidiEditor = nil
ActiveTake = nil
ActiveTrack = nil
Articulations = {}
CC = {}
ActivatedKS = {}

function ThemeColorToImguiColor(themeColorName)
    local color = reaper.GetThemeColor(themeColorName, 0)
    local r, g, b = reaper.ColorFromNative(color)
    return ImGui.ColorConvertDouble4ToU32(r/255, g/255, b/255, 1)
end

EnumThemeColors = { -- fetch colors from Reaper theme
    A = ThemeColorToImguiColor("midi_leftbg"), -- Background
    B = ThemeColorToImguiColor("midi_pkey2"), -- Default Interactive
    C = ThemeColorToImguiColor("midi_trackbg1"), -- Active
    D = ThemeColorToImguiColor("midi_trackbg2"), -- Hovered    
    E = ThemeColorToImguiColor("col_tcp_text"), -- HeaderText
    F = ThemeColorToImguiColor("midi_pkey1") -- Text
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
Setting_MoveEditCursor = true
Setting_MaxColumns = 2
Setting_ItemsPerColumn = 10
Setting_FontSizeMultiplier = 1
Setting_InsertionMode = InsertionModes.Multi

Modal_Settings = false
Modal_NoteNameHelper = false

Injector_NotesList = ""
Injector_FirstNoteID = 36

PPQ = reaper.SNM_GetIntConfigVar("miditicksperbeat", 960)

function SaveSettings()
    reaper.SetExtState("ReaKS", "Setting_AutoupdateTextEvent", tostring(Setting_AutoupdateTextEvent), true)
    reaper.SetExtState("ReaKS", "Setting_MaxColumns", tostring(Setting_MaxColumns), true) -- Depracated
    reaper.SetExtState("ReaKS", "Setting_ItemsPerColumn", tostring(Setting_ItemsPerColumn), true)
    reaper.SetExtState("ReaKS", "Setting_MoveEditCursor", tostring(Setting_MoveEditCursor), true)
    reaper.SetExtState("ReaKS", "Setting_FontSizeMultiplier", tostring(Setting_MoveEditCursor), true)
    reaper.SetExtState("ReaKS", "Setting_InsertionMode", Setting_InsertionMode, true)
end

function LoadSettings()
    local val
    val = reaper.GetExtState("ReaKS", "Setting_AutoupdateTextEvent")
    if val ~= "" then Setting_AutoupdateTextEvent = val == "true" end

    val = reaper.GetExtState("ReaKS", "Setting_MaxColumns")
    if val ~= "" then Setting_MaxColumns = tonumber(val) end

    val = reaper.GetExtState("ReaKS", "Setting_ItemsPerColumn")
    if val ~= "" then Setting_FontSizeMultiplier = tonumber(val) end

    val = reaper.GetExtState("ReaKS", "Setting_MoveEditCursor")
    if val ~= "" then Setting_MoveEditCursor = val == "true" end

    val = reaper.GetExtState("ReaKS", "Setting_FontSizeMultiplier")
    if val ~= "" then Setting_FontSizeMultiplier = tonumber(val) end

    val = reaper.GetExtState("ReaKS", "Setting_InsertionMode")
    if val ~= "" then Setting_InsertionMode = val end
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

function LinkParameterToCCLane()
    local _, trackidx, itemidx, takeidx, fxidx, parmidx = reaper.GetTouchedOrFocusedFX(0)
    local lastTouchedCCLane = reaper.MIDIEditor_GetSetting_int(ActiveMidiEditor, "last_touched_cc_lane")

    local track = reaper.GetTrack(0, trackidx)
    local parmid = "param."..parmidx.."plink"
    local value = ""
    reaper.TrackFX_SetNamedConfigParm(track, fxidx, parmid, value)
    -- get parameter's name

end

function InsertKS(noteNumber)
    --Check if any midi notes are selected. Get earliest start time and latest end time if any selected notes.
    local _, noteCount = reaper.MIDI_CountEvts(ActiveTake)
    local earliestStartTime = math.huge
    local latestEndTime = 0

    if noteCount ~= 0 then
        for noteID = 1, noteCount do
            local _, selected, _, startppqpos, endppqpos, _, pitch, _ = reaper.MIDI_GetNote(ActiveTake, noteID - 1)
            if selected and ActivatedKS[pitch] ~= nil then
                if startppqpos < earliestStartTime then earliestStartTime = startppqpos end
                if endppqpos > latestEndTime then latestEndTime = endppqpos end
            end
        end
    end

    -- Start time offsetted by -1 ppq to activate the articulation just before the note
    if earliestStartTime == math.huge then
        --Add articulation to playhead position
        local playheadPosition = reaper.GetCursorPosition()
        local playheadPosition = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, playheadPosition)
        local length = playheadPosition + (reaper.MIDI_GetGrid(ActiveTake) * PPQ)
        reaper.MIDI_InsertNote(ActiveTake, false, false, playheadPosition - 1, length, 0, noteNumber, 100, false)

        if Setting_MoveEditCursor then 
            reaper.SetEditCurPos(reaper.MIDI_GetProjTimeFromPPQPos(ActiveTake, length), Setting_MoveEditCursor, false)
        end
    else
        --Add articulation to selected notes
        reaper.MIDI_InsertNote(ActiveTake, false, false, earliestStartTime - 1, latestEndTime, 0, noteNumber, 100, false)
        reaper.SetEditCurPos(reaper.MIDI_GetProjTimeFromPPQPos(ActiveTake, earliestStartTime), Setting_MoveEditCursor, false)
    end

    if Setting_AutoupdateTextEvent then UpdateTextEvents() end
end

function ToggleKS(noteNumber)
    if(ActivatedKS[noteNumber]) then --Delete articulation if exists
        reaper.MIDI_DeleteNote(ActiveTake, ActivatedKS[noteNumber])
    else
        InsertKS(noteNumber)
    end
end

function SingleInsertKS(noteNumber)
    if ActiveTake == nil then return end

    local playheadPosition = reaper.GetCursorPosition()
    local playheadPosition = reaper.MIDI_GetPPQPosFromProjTime(ActiveTake, playheadPosition)

    for k, v in pairs(ActivatedKS) do
        local _, isSelected, isMuted, startppq, endppq  = reaper.MIDI_GetNote(ActiveTake, v)
        if startppq == playheadPosition or startppq == playheadPosition -1 then
            reaper.MIDI_DeleteNote(ActiveTake, v)
        elseif endppq >= playheadPosition then
            reaper.MIDI_SetNote(ActiveTake, v, isSelected, isMuted, startppq, playheadPosition)
        end
        reaper.MIDI_Sort(ActiveTake)
    end
    InsertKS(noteNumber)
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
            ImGui.TextColored(ctx, ActiveTrackColor, ActiveTrackName .. " - " .. ActiveTakeName)
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
        if ImGui.Button(ctx, "Settings") then Modal_Settings = not Modal_Settings end
        ImGui.EndGroup(ctx)

        --TODO Make the settings modal
        if Modal_Settings then
            local val
            
            ImGui.BeginGroup(ctx)
            ImGui.SeparatorText(ctx, "Settings")

            if ImGui.Checkbox(ctx, "Autorefresh Text Events", Setting_AutoupdateTextEvent) then 
                Setting_AutoupdateTextEvent = not Setting_AutoupdateTextEvent 
                SaveSettings()
            end

            if ImGui.Checkbox(ctx, "Automove Cursor ", Setting_MoveEditCursor) then 
                Setting_MoveEditCursor = not Setting_MoveEditCursor 
                SaveSettings()
            end

            if ImGui.BeginCombo(ctx, "Insertion Mode", Setting_InsertionMode) then
                for i, mode in ipairs(InsertionModes) do
                    local selected = Setting_InsertionMode == mode
                    if ImGui.Selectable(ctx, mode, selected) then
                        Setting_InsertionMode = mode
                        SaveSettings()
                    end
                end
                ImGui.EndCombo(ctx)
            end

            _, val = ImGui.SliderInt(ctx, "KS Rows", Setting_ItemsPerColumn, 1, 100)
            if val ~= Setting_ItemsPerColumn then
                Setting_ItemsPerColumn = val
                SaveSettings()
            end

            if ImGui.Button(ctx, "Find More Note Names >>>") then reaper.CF_ShellExecute("https://stash.reaper.fm/tag/Key-Maps") end

            ImGui.EndGroup(ctx)
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

                        if Setting_InsertionMode == "Multi" then
                            if ImGui.Checkbox(ctx, articulation, ActivatedKS[i] ~= nil) then
                                ToggleKS(i)
                            end                          
                        end

                        if Setting_InsertionMode == "Single" then
                            if ImGui.Button(ctx, articulation) then
                                SingleInsertKS(i)
                            end
                        end                        

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
                --if ImGui.Button(ctx, "!!! Link Touched Parameter to Focused CC Lane") then LinkParameterToCCLane() end
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
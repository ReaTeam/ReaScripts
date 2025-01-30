-- @description Floating Solo Toolbar
-- @author Neftovsky
-- @version 1.1
-- @about
--   Floating Solo Toolbar
--
--   - Creates a floating toolbar
--   - Links each button to a specific track in the project
--   - Toggles the solo state for a track in the project when a button is clicked
--   - Allows changing the names of tracks and buttons by right-clicking on the buttons
--   - Enables adding new buttons to the toolbar
--   - Saves settings, including button labels and track names
-- @requires
--   ReaImGui: API version 0.8 or later
-- @requires
--   REAPER 6.0 or later

app_vrs = tonumber(reaper.GetAppVersion():match('[%d%.]+'))
check_vrs = 6.0
if app_vrs < check_vrs then return reaper.MB('This script require REAPER '..check_vrs..'+','',0) end
local ImGui

if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
package.path =   reaper.ImGui_GetBuiltinPath() .. '/?.lua'
ImGui = require 'imgui' '0.9.3.2'
local imgui = reaper.ImGui_CreateContext("Floating Solo Toolbar")
local window_open = true

local toolbar_pos_x = 100
local toolbar_pos_y = 100
local default_button_color = 0x666666FF

local button_order = {"Rhythm", "VOC", "INSTR", "FX"}

local buttons = {
    Rhythm = {track_name = "Rhythm Bus", button_label = "RHYTHM"},
    VOC = {track_name = "Vocal Bus", button_label = "VOC"},
    INSTR = {track_name = "Instr Bus", button_label = "INSTR"},
    FX = {track_name = "Send Bus", button_label = "FX"}
}

local function TableToString(tbl)
    local function serialize(o)
        if type(o) == "number" then
            return tostring(o)
        elseif type(o) == "string" then
            return string.format("%q", o)
        elseif type(o) == "table" then
            local s = "{"
            for k, v in pairs(o) do
                s = s .. "[" .. serialize(k) .. "]=" .. serialize(v) .. ","
            end
            return s .. "}"
        else
            error("cannot serialize a " .. type(o))
        end
    end
    return serialize(tbl)
end

local function StringToTable(str)
    local func, err = load("return " .. str)
    if not func then
        reaper.ShowMessageBox("Error loading settings: " .. err, "Error", 0)
        return nil
    end
    return func()
end

local function LoadSettings()
    local settings_str = reaper.GetExtState("FloatingSoloToolbar", "Settings")
    if settings_str and settings_str ~= "" then
        local settings = StringToTable(settings_str)
        if type(settings) == "table" and settings.buttons and settings.order then
            buttons = settings.buttons
            button_order = settings.order
        end
    end
end

local function SaveSettings()
    local settings = {buttons = buttons, order = button_order}
    reaper.SetExtState("FloatingSoloToolbar", "Settings", TableToString(settings), true)
end

local function CheckSoloState(track_name)
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local _, current_track_name = reaper.GetTrackName(track)
        if current_track_name == track_name then
            local solo_state = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
            return solo_state > 0
        end
    end
    return false
end

local function ToggleSoloByTrackName(track_name)
    local track_count = reaper.CountTracks(0)
    for i = 0, track_count - 1 do
        local track = reaper.GetTrack(0, i)
        local _, current_track_name = reaper.GetTrackName(track)
        if current_track_name == track_name then
            local solo_state = reaper.GetMediaTrackInfo_Value(track, "I_SOLO")
            reaper.SetMediaTrackInfo_Value(track, "I_SOLO", solo_state > 0 and 0 or 2)
            return
        end
    end
    reaper.ShowMessageBox("Track '" .. track_name .. "' not found!", "Error", 0)
end

local function RenderButton(button_key)
    local button = buttons[button_key]
    if not button.button_label or button.button_label == "" then
        button.button_label = "Unnamed"
    end

    local soloed = CheckSoloState(button.track_name)
    reaper.ImGui_PushStyleColor(imgui, reaper.ImGui_Col_Button(), soloed and HSV(0.1, 0.8, 0.8) or default_button_color)

    if reaper.ImGui_Button(imgui, button.button_label .. "##" .. button_key) then
        if reaper.ImGui_IsMouseReleased(imgui, 0) then
            ToggleSoloByTrackName(button.track_name)
        end
    end
    reaper.ImGui_PopStyleColor(imgui)

    if reaper.ImGui_IsItemClicked(imgui, 1) then
        menu_popup_open = true
        selected_button_key = button_key
        button_name_buffer = button.button_label
        track_name_buffer = button.track_name
    end
end

local function AddButton()
    local new_button_key = "Unnamed" .. #button_order + 1
    buttons[new_button_key] = {track_name = "New Track", button_label = "New"}
    table.insert(button_order, new_button_key)
    SaveSettings()
end

local function RemoveButton()
    if #button_order > 0 then
        local button_to_remove = table.remove(button_order)
        buttons[button_to_remove] = nil
        SaveSettings()
    end
end

local function RenderMenuPopup()
    if menu_popup_open then
        reaper.ImGui_OpenPopup(imgui, "Menu")
    end

    if reaper.ImGui_BeginPopupModal(imgui, "Menu", true) then
        local changed_btn, new_button_name = reaper.ImGui_InputText(imgui, "Button Name", button_name_buffer, 256)
        if changed_btn then button_name_buffer = new_button_name end

        local changed_track, new_track_name = reaper.ImGui_InputText(imgui, "Track Name", track_name_buffer, 256)
        if changed_track then track_name_buffer = new_track_name end

        if reaper.ImGui_Button(imgui, "OK") then
            if selected_button_key then
                buttons[selected_button_key].button_label = button_name_buffer
                buttons[selected_button_key].track_name = track_name_buffer
                SaveSettings()
            end
            menu_popup_open = false
            reaper.ImGui_CloseCurrentPopup(imgui)
        end

        reaper.ImGui_SameLine(imgui)

        if reaper.ImGui_Button(imgui, "Cancel") then
            menu_popup_open = false
            reaper.ImGui_CloseCurrentPopup(imgui)
        end

        reaper.ImGui_Separator(imgui)

        if reaper.ImGui_Button(imgui, "+") then
            AddButton()
        end

        reaper.ImGui_SameLine(imgui)

        if reaper.ImGui_Button(imgui, "-") then
            RemoveButton()
        end

        reaper.ImGui_EndPopup(imgui)
    end
end

local window_flags = reaper.ImGui_WindowFlags_NoTitleBar()
                     | reaper.ImGui_WindowFlags_NoResize()
                     | reaper.ImGui_WindowFlags_NoScrollbar()
                     | reaper.ImGui_WindowFlags_NoCollapse()
                     | reaper.ImGui_WindowFlags_AlwaysAutoResize()
                     | reaper.ImGui_WindowFlags_NoBackground()
                     | reaper.ImGui_WindowFlags_NoDecoration()

local function Main()
    if window_open then
        reaper.ImGui_SetNextWindowPos(imgui, toolbar_pos_x, toolbar_pos_y, reaper.ImGui_Cond_FirstUseEver())
        local visible, open = reaper.ImGui_Begin(imgui, "Floating Solo Toolbar", true, window_flags)

        if visible then
            for _, key in ipairs(button_order) do
                RenderButton(key)
                reaper.ImGui_SameLine(imgui)
            end
            RenderMenuPopup()
            reaper.ImGui_End(imgui)
        end

        if not open then
            window_open = false
        end
    else
        return
    end

    reaper.defer(Main)
end

function HSV(h, s, v, a)
    local r, g, b = reaper.ImGui_ColorConvertHSVtoRGB(h, s, v)
    return reaper.ImGui_ColorConvertDouble4ToU32(r, g, b, a or 1.0)
end

LoadSettings()
Main()

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

app_vrs = tonumber(reaper.GetAppVersion():match('[%d%.]+'))
check_vrs = 6.0
if app_vrs < check_vrs then return reaper.MB('This script require REAPER '..check_vrs..'+','',0) end
local ImGui

if not reaper.ImGui_GetBuiltinPath then return reaper.MB('This script require ReaImGui extension','',0) end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
ImGui = require 'imgui' '0.9.3.2'

--------------------------------------------------------------------- 
  function encBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
      return ((data:gsub('.', function(x) 
          local r,b='',x:byte()
          for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
          return r;
      end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
          if (#x < 6) then return '' end
          local c=0
          for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
          return b:sub(c+1,c+1)
      end)..({ '', '==', '=' })[#data%3+1])
  end
--------------------------------------------------------------------- 
function decBase64(data) -- https://stackoverflow.com/questions/34618946/lua-base64-encode
  local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- You will need this for encoding/decoding
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end  

-- Глобальная переменная для контекста ImGui
local imgui = nil

-- Функция для создания или восстановления контекста ImGui
local function EnsureImGuiContext()
    if not imgui or not reaper.ImGui_ValidatePtr(imgui, 'ImGui_Context*') then
        imgui = reaper.ImGui_CreateContext("Floating Solo Toolbar")
        if not imgui then
            reaper.ShowMessageBox("Failed to create ImGui context!", "Error", 0)
            return false
        end
    end
    return true
end

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

local menu_popup_open = false
local selected_button_key = nil
local button_name_buffer = ""
local track_name_buffer = ""

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
        local settings = StringToTable(decBase64(settings_str))
        if type(settings) == "table" and settings.buttons and settings.order then
            buttons = settings.buttons
            button_order = settings.order
        end
    end
end

local function SaveSettings()
    local settings = {buttons = buttons, order = button_order}
    reaper.SetExtState("FloatingSoloToolbar", "Settings", encBase64(TableToString(settings)), true)
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
            if selected_button_key and buttons[selected_button_key] then
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
    -- Проверяем и восстанавливаем контекст ImGui
    if not EnsureImGuiContext() then
        return
    end

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

-- @noindex

-- @description Core library for Quad Cortex MIDI control
-- @author Bertrand C

local lib = {}

lib.SettingsFile = "Quad_Cortex_MIDI_Control.ini"
local info = debug.getinfo(1,'S')
lib.SettingsPath = info.source:match("@?(.*[\\/])") .. lib.SettingsFile

lib.Defaults = {
    MIDI_CHANNEL    = "1",
    MIDI_OUTPUT_ID  = "0",
    TRACK_NAME      = "Quad Cortex MIDI control",
    PRESET_PREFIX   = "#",
    SCENE_PREFIX    = "!S",
    AUTO_TUNER      = "false",
    AUTO_GIGVIEW    = "true",
    LOG_LEVEL       = "1"
}

lib.Config = {}
for k, v in pairs(lib.Defaults) do lib.Config[k] = v end

function lib.Log(message, level)
    level = level or 1
    local activeLevel = tonumber(lib.Config.LOG_LEVEL) or 1
    if level <= activeLevel then
        local prefix = (level == 2) and "[DEBUG] " or "[INFO] "
        reaper.ShowConsoleMsg(prefix .. tostring(message) .. "\n")
    end
end

function lib.PrintConfig()
    local currentLevel = tonumber(lib.Config.LOG_LEVEL) or 1
    if currentLevel >= 2 then
        lib.Log("--- Quad Cortex Configuration ---", 2)
        local keys = {"MIDI_CHANNEL", "MIDI_OUTPUT_ID", "TRACK_NAME", "PRESET_PREFIX", "SCENE_PREFIX", "AUTO_TUNER", "AUTO_GIGVIEW", "LOG_LEVEL"}
        for _, k in ipairs(keys) do
            lib.Log(string.format("%-18s = %s", k, tostring(lib.Config[k])), 2)
        end
        lib.Log("----------------------------------", 2)
    end
end

function lib.LoadSettings()
    local f = io.open(lib.SettingsPath, "r")
    if not f then return false end

    local fileContent = {}
    for line in f:lines() do
        local key, value = line:match("^%s*([%w_]+)%s*=%s*(.*)$")
        if key and value then
            fileContent[key] = value:match("^%s*(.-)%s*$")
        end
    end
    f:close()

    local keysFound = 0
    for k, _ in pairs(lib.Defaults) do
        if fileContent[k] ~= nil then
            lib.Config[k] = fileContent[k]
            keysFound = keysFound + 1
        end
    end

    if keysFound > 0 then
        lib.PrintConfig()
        return true
    end
    return false
end

function lib.SaveSettings(settingsTable)
    local f = io.open(lib.SettingsPath, "w")
    if f then
        local keys = {"MIDI_CHANNEL", "MIDI_OUTPUT_ID", "TRACK_NAME", "PRESET_PREFIX", "SCENE_PREFIX", "AUTO_TUNER", "AUTO_GIGVIEW", "LOG_LEVEL"}
        for _, k in ipairs(keys) do
            local val = tostring(settingsTable[k])
            f:write(string.format("%s=%s\n", k, val))
            lib.Config[k] = val -- Update session memory
        end
        f:close()
        lib.Log("Configuration saved.", 1)
        lib.PrintConfig()
        return true
    end
    return false
end

function lib.SetToolbarButtonState(enable)
    local _, _, section, cmd = reaper.get_action_context()
    reaper.SetToggleCommandState(section, cmd, enable or 0)
    reaper.RefreshToolbar2(section, cmd)
end

function lib.HandleExit()
    lib.SetToolbarButtonState(0)
    lib.Log("Engine Deactivated", 1)
end

function lib.SendMidi(status, d1, d2)
    local channel = tonumber(lib.Config.MIDI_CHANNEL) or 1
    reaper.StuffMIDIMessage(0, status + (channel - 1), d1, d2)
    lib.Log(string.format("MIDI Sent (channel %d) -> Status: 0x%X, D1: %d, D2: %d", channel, status, d1, d2), 2)
end

function lib.GetMidiOutputsList()
    local dev_list = "\n--- CURRENTLY AVAILABLE MIDI DEVICES ---\n"
    local num_outputs = reaper.GetNumMIDIOutputs()
    if num_outputs == 0 then return dev_list .. "(No MIDI outputs detected)\n" end

    for i = 0, num_outputs - 1 do
        local retval, name = reaper.GetMIDIOutputName(i, "")
        if retval then
            dev_list = dev_list .. string.format("ID %d : %s\n", i, name)
        end
    end
    dev_list = dev_list .. "----------------------------------------\n"
    return dev_list
end

function lib.EnsureControlTrack()
    local trackName = lib.Config.TRACK_NAME or lib.Defaults.TRACK_NAME
    local hwDeviceId = tonumber(lib.Config.MIDI_OUTPUT_ID) or -1

    if hwDeviceId >= 0 then
        local retval, name = reaper.GetMIDIOutputName(hwDeviceId, "")
        if not retval then
            reaper.ClearConsole()
            reaper.ShowConsoleMsg("ERROR: MIDI Device ID " .. hwDeviceId .. " is missing!\n")
            reaper.ShowConsoleMsg(lib.GetMidiOutputsList())

            local errorMsg = "The assigned MIDI Device (ID " .. hwDeviceId .. ") is not connected.\n\n" ..
                             "1. Check the Reaper Console for available IDs.\n" ..
                             "2. Run 'Quad_Cortex_MIDI_control_setup' to update your settings.\n\n" ..
                             "The script will now stop to prevent routing errors."

            reaper.MB(errorMsg, "QC MIDI Control - Hardware Error", 0)
            return false
        end
    end

    local targetTrack = nil
    for i = 0, reaper.CountTracks(0) - 1 do
        local track = reaper.GetTrack(0, i)
        local _, name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
        if name == trackName then targetTrack = track break end
    end
    if not targetTrack then
        reaper.InsertTrackAtIndex(0, true)
        targetTrack = reaper.GetTrack(0, 0)
        reaper.GetSetMediaTrackInfo_String(targetTrack, "P_NAME", trackName, true)
        lib.Log("Created MIDI Output Track: " .. trackName, 1)
    end

    local packedValue = (hwDeviceId >= 0) and ((hwDeviceId << 5) + 0) or -1
    reaper.SetMediaTrackInfo_Value(targetTrack, "I_MIDIHWOUT", packedValue)

    reaper.SetMediaTrackInfo_Value(targetTrack, "I_RECINPUT", 6080)
    reaper.SetMediaTrackInfo_Value(targetTrack, "I_RECARM", 1)
    reaper.SetMediaTrackInfo_Value(targetTrack, "I_RECMON", 1)
    reaper.SetMediaTrackInfo_Value(targetTrack, "I_RECMODE", 2)

    return true
end

function lib.CalculatePc(bank, letter)
    local letters = {A=0, B=1, C=2, D=3, E=4, F=5, G=6, H=7}
    return ((tonumber(bank) - 1) * 8) + (letters[letter:upper()] or 0)
end

function lib.EscapePattern(text)
    if type(text) ~= "string" then return "" end
    return text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
end

function lib.GetProjectState(pos)
    local count = reaper.CountProjectMarkers(0)
    local state = { pc = nil, pc_name = nil, cc = nil, cc_name = nil, scene_dur = 999999 }
    local p_prefix = lib.EscapePattern(lib.Config.PRESET_PREFIX)
    local s_prefix = lib.EscapePattern(lib.Config.SCENE_PREFIX)
    for i = 0, count - 1 do
        local _, is_rgn, r_start, r_end, r_name, _ = reaper.EnumProjectMarkers3(0, i)
        if is_rgn and pos >= r_start and pos <= r_end then
            local b, l = r_name:match(p_prefix .. "(%d+)([A-Ha-h])")
            if b and l then
                state.pc = lib.CalculatePc(b, l)
                state.pc_name = b .. l
            end
            local s = r_name:match(s_prefix .. "([A-Ha-h])")
            if s then
                local dur = r_end - r_start
                if dur < state.scene_dur then
                    state.scene_dur = dur
                    local smap = {A=0,B=1,C=2,D=3,E=4,F=5,G=6,H=7}
                    state.cc = s:match("%d") and (tonumber(s)-1) or smap[s:upper()]
                    state.cc_name = s:upper()
                end
            end
        end
    end
    return state
end

return lib

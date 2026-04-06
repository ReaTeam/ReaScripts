-- @noindex

-- @description Setup Wizard for Quad Cortex MIDI control
-- @author Bertrand C

local base_path = debug.getinfo(1).source:match("@?(.*[\\/])")
local lib = dofile(base_path .. "lib.lua")

function RunSetupWizard()
    lib.LoadSettings()
    local s = lib.Config

    local midi_list = lib.GetMidiOutputsList()
    reaper.ClearConsole()
    reaper.ShowConsoleMsg(midi_list)
    reaper.ShowConsoleMsg("\nLook at the list above to find your MIDI Hardware ID.\n")

    -- extrawidth=200 for better readability the dedicated track name that can be quite long
    local captions = "extrawidth=200,MIDI Channel (1-16),Hardware MIDI Out ID (see Console),Dedicated Track Name,Preset Prefix,Scene Prefix,Tuner on Stop? (y/n),GigView on Play? (y/n),Log Level (0-2)"

    local csv = string.format("%s,%s,%s,%s,%s,%s,%s,%s",
        s.MIDI_CHANNEL, s.MIDI_OUTPUT_ID, s.TRACK_NAME, s.PRESET_PREFIX, s.SCENE_PREFIX,
        (s.AUTO_TUNER == "true" and "y" or "n"), (s.AUTO_GIGVIEW == "true" and "y" or "n"), s.LOG_LEVEL)

    local retval, user_input = reaper.GetUserInputs("Quad Cortex Setup", 8, captions, csv)

    if retval then
        local ch, id, name, p_pre, p_sce, tuner, gig, log = user_input:match("([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*)")

        local updated = {
            MIDI_CHANNEL   = ch,
            MIDI_OUTPUT_ID = id,
            TRACK_NAME     = name:match("^%s*(.-)%s*$"),
            PRESET_PREFIX  = p_pre,
            SCENE_PREFIX   = p_sce,
            AUTO_TUNER     = (tuner:lower():find("y") or tuner:lower() == "true") and "true" or "false",
            AUTO_GIGVIEW   = (gig:lower():find("y") or gig:lower() == "true") and "true" or "false",
            LOG_LEVEL      = log
        }

        lib.SaveSettings(updated)

        local helpMsg = "Configuration saved successfully!\n\n" ..
                        "--- QUICK START ---\n" ..
                        "1. Right-click on any Toolbar > Customize toolbar...\n" ..
                        "2. Click 'Add...' and search for: Quad_Cortex_MIDI_control\n" ..
                        "3. Select it and click 'Select/Close'.\n\n" ..
                        "--- CHANGING SETTINGS ---\n" ..
                        "To modify your configuration later, simply run the setup action from the Action List:\n" ..
                        "Action: Quad_Cortex_MIDI_control_setup\n\n" ..
                        "The main button will light up when the synchronization is active."

        reaper.ShowMessageBox(helpMsg, "QC MIDI Control - Setup Complete", 0)

        lib.EnsureControlTrack()

        return true
    end
    return false
end

return RunSetupWizard()

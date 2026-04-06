-- @description Quad Cortex MIDI control
-- @author Bertrand C
-- @version 2.3.2
-- @changelog
--   - Fix reapack-index linked to wrong git commit
--   - README update with region combination name examples
--   - Add info after setup on how to add a toolbar button for easy access, or re-execute the setup wizard if needed.
--   - Add MIDI output ID validation in the setup wizard to prevent invalid entries.
--   - README update with clearer setup instructions and troubleshooting tips.
--   - Add info after first config on how to add a toolbar button for easy access, or re-execute the setup wizard if needed.
--   - Add setup to list action list (for easier access and reconfiguration)
--   - Fix folders to fix category detection with reapack-index
--   - Split from original Quad Cortex MIDI Control script to create a more modular and maintainable codebase.
--   - Added a setup wizard for first-time configuration.
--   - Improved logging and error handling.
--   - Automatically creates the MIDI output track if it doesn't exist.
-- @provides
--   [main] bertrandc_Quad Cortex MIDI control/bertrandc_Quad Cortex MIDI control (setup).lua
--   [nomain] bertrandc_Quad Cortex MIDI control/lib.lua
-- @about
--   # Quad Cortex MIDI control
--   Real-time MIDI control for Neural DSP Quad Cortex via Reaper Regions.
--   - Automates Presets using "#BankLetter" (e.g., #1A).
--   - Automates Scenes using "!Sx" (e.g., !S1 or !SA).
--   - Auto-activates Gig View on Play and Tuner on Stop (both can be toggled).
--   - **MIDI Clock Support**: Reaper will send tempo/clock to the Quad Cortex 
--     if "Send clock" is enabled for your MIDI output in Reaper's Preferences.
--
--   ## USAGE INSTRUCTIONS
--
--   1. AUTOMATIC INSTALLATION & SETUP
--      - Run this script. If it's the first time, the SETUP WIZARD will open.
--      - The script AUTOMATICALLY creates a dedicated MIDI track (Default: "Quad Cortex MIDI control").
--      - This track is pre-configured: Armed, Monitoring ON, and Record DISABLED (Mode 2).
--      - In the Wizard, select the correct MIDI Hardware Output ID for your QC.
--   ---
--   2. TEMPO & MIDI CLOCK SYNC
--      - To sync Tempo (BPM) to your QC: 
--      - Preferences > MIDI Devices > Double-click Output > Check "Send clock to this device".
--   ---
--   3. SYNC YOUR PRESETS AND SCENES
--      - PRESETS: Use "#BankLetter" format (e.g., "#1A", "#12C").
--      - SCENES:  Use "!SA" to "!SH" (Matches QC Footswitches A to H).
--   ---
--   4. LOG LEVELS
--      - Log Level 1 [INFO]: Preset/Scene changes and Transport status.
--      - Log Level 2 [DEBUG]: Full configuration details and file operations.

-- Main synchronization engine

local base_path = debug.getinfo(1).source:match("@?(.*[\\/])")
local lib = dofile(base_path .. "lib.lua")

-- --- INITIALIZATION ---
reaper.ClearConsole()

if not lib.LoadSettings() then
    lib.Log("First run or missing config. Launching Setup Wizard...", 1)
    local setup_success = dofile(base_path .. "bertrandc_Quad Cortex MIDI control/bertrandc_Quad Cortex MIDI control (setup).lua")
    if not setup_success then
        lib.SetToolbarButtonState(0)
        return
    end
    lib.LoadSettings()
end

if not lib.EnsureControlTrack() then
    lib.SetToolbarButtonState(0)
    return
end

lib.Log("Hardware Check: OK", 1)

local lastPlayState, lastPc, lastCc = -1, -1, -1

function MainLoop()
    local playState = reaper.GetPlayState()
    local playPos = (playState == 0) and reaper.GetCursorPosition() or reaper.GetPlayPosition()

    -- --- TRANSPORT HANDLING (Log Level 1) ---
    if playState == 1 and lastPlayState ~= 1 then
        local statusMsg = "Play"
        if lib.Config.AUTO_TUNER == "true" then
            lib.SendMidi(0xB0, 45, 0) -- Tuner OFF
            statusMsg = statusMsg .. " | Tuner: OFF"
        end
        if lib.Config.AUTO_GIGVIEW == "true" then
            lib.SendMidi(0xB0, 46, 127) -- GigView ON
            statusMsg = statusMsg .. " | GigView: ON"
        end
        lib.Log(statusMsg, 1)
        lastPc, lastCc = -1, -1

    elseif (playState == 0 or playState == 2) and lastPlayState == 1 then
        local statusMsg = (playState == 0) and "Stop" or "Pause"
        if lib.Config.AUTO_TUNER == "true" then
            lib.SendMidi(0xB0, 45, 127) -- Tuner ON
            statusMsg = statusMsg .. " | Tuner: ON"
        end
        lib.Log(statusMsg, 1)
    end

    -- --- REGION PROCESSING ---
    local current = lib.GetProjectState(playPos)

    if current.pc and current.pc ~= lastPc then
        lib.SendMidi(0xB0, 32, 1)
        lib.SendMidi(0xC0, current.pc, 0)
        lastPc, lastCc = current.pc, -1
        lib.Log("Preset Change -> " .. current.pc_name, 1)
    end

    if current.cc and current.cc ~= lastCc then
        lib.SendMidi(0xB0, 43, current.cc)
        lastCc = current.cc
        lib.Log("Scene Change -> Scene " .. current.cc_name, 1)
    end

    lastPlayState = playState
    reaper.defer(MainLoop)
end

-- --- EXECUTION ---
lib.SetToolbarButtonState(1)
reaper.atexit(lib.HandleExit)

lib.Log("Engine Active (MIDI Track: " .. lib.Config.TRACK_NAME .. ")", 1)
lib.Log("Note: Enable 'Send clock' in MIDI Prefs for Tempo Sync.", 1)

MainLoop()

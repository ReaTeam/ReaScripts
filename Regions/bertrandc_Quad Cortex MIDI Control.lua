-- @description Quad Cortex MIDI Control
-- @author Bertrand C
-- @version 1.0
-- @changelog Initial release
-- @provides . > QuadCortexMIDIControl.lua
-- @about
--   # Quad Cortex Midi Control 1.0
--   Real-time MIDI control for Neural DSP Quad Cortex via Reaper Regions.
--   - Automates Presets using "#BankLetter" (e.g., #1A).
--   - Automates Scenes using "!Sx" (e.g., !S1 or !SA).
--   - Auto-activates Gig View on Play and Tuner on Stop (both can be toggled).
--
--   ## USAGE INSTRUCTIONS
--
--   1. REAPER CONFIGURATION
--      - Create a track (e.g., "MIDI QC CTRL").
--      - Set Track Input to "MIDI > Virtual MIDI Keyboard > All Channels".
--      - Add a "MIDI Hardware Output" on this track to your MIDI device (WIDI / Interface).
--      - Record Arm and Input Monitoring must be ENABLED for the script to reach the QC.
--   ---
--   2. SYNC YOUR PRESETS AND SCENES
--      - Create Regions in Reaper named with the following tags:
--      - PRESETS: Use "#BankLetter" format (e.g., "#1A", "#12C").
--      - SCENES:  Use "!Sx" where x is 1-8 or A-H (e.g., "!S1", "!SA").
--      Note: Small "Scene" regions inside larger "Preset" regions are supported (Inheritance).
--   ---
--   3. TOOLBAR INTEGRATION
--      - Assign this script to a toolbar button. The button will light up when
--        active. To stop, click again and select "Terminate Instance".
--   ---
--   4. ADDITIONAL FEATURES
--      - PLAY: Automatically switches QC to "Gig View" and hides the Tuner.
--              Set AUTO_GIGVIEW to false to disable this behavior.
--      - STOP: Automatically activates the "Tuner" on the QC for silent breaks.
--              Set AUTO_TUNER to false to disable this behavior.

-- ============================================================================
-- CONFIGURATION & OPTIONS
-- ============================================================================
local MIDI_CHANNEL   = 1
local MIDI_OUTPUT_ID = 0

-- AUTOMATION OPTIONS
local AUTO_GIGVIEW   = true
local AUTO_TUNER     = true

-- LOG LEVEL (0: Silence, 1: Essential, 2: Full Debug)
local DEBUG_LEVEL    = 1

-- Initialize Toggle Button State
local _, _, sectionID, cmdID = reaper.get_action_context()
reaper.SetToggleCommandState(sectionID, cmdID, 1) 
reaper.RefreshToolbar2(sectionID, cmdID)

-- ============================================================================
-- MIDI & LOGGING FUNCTIONS
-- ============================================================================
function Log(msg, level)
    if (level or 1) <= DEBUG_LEVEL then 
        reaper.ShowConsoleMsg(tostring(msg) .. "\n") 
    end
end

function SendMIDI(status, data1, data2)
    local ch = MIDI_CHANNEL - 1
    reaper.StuffMIDIMessage(MIDI_OUTPUT_ID, status + ch, data1, data2)
end

function ConvertQCtoPC(bank, letter)
    local letters = {A=0, B=1, C=2, D=3, E=4, F=5, G=6, H=7}
    return ((tonumber(bank) - 1) * 8) + letters[letter:upper()]
end

-- ============================================================================
-- REGION ANALYSIS
-- ============================================================================
function GetQCStateAtPos(pos)
    local num_markers = reaper.CountProjectMarkers(0)
    local state = { preset = nil, scene = nil, scene_dur = 9999999 }

    for i = 0, num_markers - 1 do
        local _, isrgn, r_pos, r_end, r_name, _ = reaper.EnumProjectMarkers3(0, i)

        if isrgn and pos >= r_pos and pos <= r_end then
            local match_found = false

            local bank, letter = r_name:match("#(%d+)([A-Ha-h])")
            if bank and letter then
                state.preset = ConvertQCtoPC(bank, letter)
                state.preset_name = bank .. letter
                match_found = true
            end

            local scene_map = {A=0, B=1, C=2, D=3, E=4, F=5, G=6, H=7}
            local s_match = r_name:match("!S([A-H1-8a-h])")

            if s_match then
                local dur = r_end - r_pos
                if dur < state.scene_dur then
                    state.scene_dur = dur
                    if s_match:match("%d") then
                        state.scene = tonumber(s_match) - 1
                    else
                        state.scene = scene_map[s_match:upper()]
                    end
                    state.scene_name = s_match:upper()
                    match_found = true
                end
            end

            if not match_found then
                Log("   [DEBUG] Region ignored: " .. r_name, 2)
            end
        end
    end
    return state
end

-- ============================================================================
-- MAIN LOOP
-- ============================================================================
local last_play_state = -1
local last_sent_preset = -1
local last_sent_scene = -1
local last_debug_time = 0

function Main()
    local play_state = reaper.GetPlayState()
    local play_pos = (play_state == 0) and reaper.GetCursorPosition() or reaper.GetPlayPosition()

    if play_state == 1 and (last_play_state == 0 or last_play_state == 2 or last_play_state == -1) then
        Log("► PLAYING: GigView ON / Tuner OFF", 1)
        if AUTO_TUNER then SendMIDI(0xB0, 45, 0) end
        if AUTO_GIGVIEW then SendMIDI(0xB0, 46, 127) end
        last_sent_preset, last_sent_scene = -1, -1
    elseif (play_state == 0 or play_state == 2) and last_play_state == 1 then
        Log("■ STOPPED: Tuner ON", 1)
        if AUTO_TUNER then SendMIDI(0xB0, 45, 127) end
    end

    local current_time = reaper.time_precise()
    if DEBUG_LEVEL >= 2 and (current_time - last_debug_time > 1.0) then
        Log("[HEARTBEAT] Monitoring at " .. play_pos, 2)
        last_debug_time = current_time
    end

    local current = GetQCStateAtPos(play_pos)

    if current.preset and current.preset ~= last_sent_preset then
        Log("   >>> Target Preset: #" .. current.preset_name, 1)
        SendMIDI(0xB0, 32, 1)
        SendMIDI(0xC0, current.preset, 0)
        last_sent_preset = current.preset
        last_sent_scene = -1 
    end

    if current.scene and current.scene ~= last_sent_scene then
        Log("   >>> Target Scene: !S" .. current.scene_name, 1)
        SendMIDI(0xB0, 43, current.scene)
        last_sent_scene = current.scene
    end

    last_play_state = play_state
    reaper.defer(Main)
end

function OnExit()
    reaper.SetToggleCommandState(sectionID, cmdID, 0)
    reaper.RefreshToolbar2(sectionID, cmdID)
    Log("QC MIDI Control: DEACTIVATED", 1)
end

reaper.atexit(OnExit)
reaper.ClearConsole()
Log("QC MIDI Control 1.0 - Ready", 1)
Main()

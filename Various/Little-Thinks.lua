-- @description Little Thinks
-- @author AfonsoRek, Erick Martins
-- @version 1.0 Alpha
-- @screenshot Docked mode https://imgur.com/a/orR8xp4
-- @about
--   # Little Things — Launchpad Chop Engine
--
--   **Little Things** transforma qualquer trecho de áudio em um kit pronto para tocar no **Novation Launchpad**. Ele captura o áudio da sua track, fatia automaticamente e distribui as fatias nos pads — com as cores acesas no próprio Launchpad.
--
--   Disponível como **plugin (VST3 / AU / Standalone) com ARA 2** e como **script nativo para o REAPER**.
--
--   ---
--
--   ## ✨ Recursos
--
--   - 🎛️ **Captura instantânea via ARA 2** — carrega a timeline da track sem precisar renderizar (REAPER, Studio One, Logic Pro, Cubase).
--   - ⏺️ **Modo Play-to-Render** — para hosts sem ARA: arme, dê play e finalize.
--   - ✂️ **Fatiamento inteligente** — por transientes, grade de compassos ou divisão igualitária.
--   - 🟩 **8, 16, 32 ou 64 pads** — as fatias vão direto para o Launchpad.
--   - 🌈 **Feedback visual** — cada pad acende com a cor da sua fatia.
--   - 💾 **Presets de kits** (`.ltkit`) — salve e recarregue seus kits.
--
--   ---
--
--   ## 📦 Conteúdo
--
--   ```
--   Plugins/
--   ├── VST3/Little Things.vst3          # VST3 com ARA 2
--   ├── AU/Little Things.component       # Audio Unit (Logic Pro e outros)
--   └── Standalone/Little Things.app     # Aplicativo independente
--   REAPER Script/
--   ├── Little Things - Launchpad Chop Engine.lua   # Script ReaImGui
--   ├── LittleThings_MIDI_Bridge.jsfx               # Bridge MIDI
--   ├── Presets/                                    # Kits de exemplo
--   └── install_reaper.sh                           # Instalador para o REAPER
--   ```
--
--   ---
--
--   ## 🛠️ Instalação (macOS)
--
--   ### Plugins
--   Copie os arquivos para as pastas de plugins do usuário:
--
--   | Formato | Destino |
--   |---|---|
--   | `Little Things.vst3` | `~/Library/Audio/Plug-Ins/VST3/` |
--   | `Little Things.component` | `~/Library/Audio/Plug-Ins/Components/` |
--
--   Ou pelo Terminal, a partir desta pasta:
--
--   ```bash
--   mkdir -p ~/Library/Audio/Plug-Ins/{VST3,Components}
--   cp -R "Plugins/VST3/Little Things.vst3" ~/Library/Audio/Plug-Ins/VST3/
--   cp -R "Plugins/AU/Little Things.component" ~/Library/Audio/Plug-Ins/Components/
--   ```
--
--   Depois, reinicie sua DAW e faça um novo scan de plugins, se necessário.
--
--   > O app **Standalone** pode ser aberto direto, sem instalação.
--
--   ### Script do REAPER
--   Requer a extensão **[ReaImGui](https://github.com/cfillion/reaimgui)** (disponível via ReaPack).
--
--   ```bash
--   bash "REAPER Script/install_reaper.sh"
--   ```
--
--   Ou carregue o `.lua` manualmente em **Actions → Show action list → New action → Load ReaScript**.
--
--   ---
--
--   ## 🚀 Como usar
--
--   1. Conecte o **Launchpad MK3** via USB.
--   2. Adicione o plugin **Little Things** na track de áudio.
--   3. Capture o áudio:
--      - **Com ARA:** clique em **CAPTURAR TRACK (ARA 2)**.
--      - **Sem ARA:** clique em **ARM (PLAY TO RENDER)**, dê play na DAW e clique em **FINALIZAR RENDER**.
--   4. Escolha o modo de fatiamento (Transientes, Grade ou Igualitário).
--   5. Clique em **Cortar em 16 Pads** (ou 8, 32, 64).
--   6. Pronto — o Launchpad acende e já está pronto para tocar! 🎶
--
--   ---
--
--   ## 📋 Requisitos
--
--   - macOS
--   - Novation Launchpad MK3 (Mini / X / Pro)
--   - DAW com suporte a VST3 ou AU (ARA 2 opcional) — ou REAPER com ReaImGui
--
--   ---
--
--   ## 📄 Licença
--
--   Veja o arquivo [LICENSE](LICENSE).

-- @description Little Things - Launchpad Chop Engine
-- @author AfonsoRek, Erick Martins
-- @version 1.0alpha2
-- @changelog
--   - Companion files moved into the "Little Things" subfolder
--   - Bundled kit presets listed alongside user kits
--   - English UI labels
-- @link https://github.com/afonsorek/Little-Things
-- @screenshot Docked mode https://imgur.com/a/orR8xp4
-- @provides
--   [effect] Little Things/LittleThings_MIDI_Bridge.jsfx
--   Little Things/Presets/*.ltkit
-- @about
--   # Little Things - Launchpad Chop Engine
--
--   Turn any section of your REAPER timeline into a playable kit on a
--   **Novation Launchpad (MK3)**: capture the audio, slice it and spread the
--   slices across the pads, with matching colors lit on the hardware.
--
--   ## Features
--   - Send the selected timeline range to any pad
--   - Slice a range into 8, 16, 32 or 64 pads
--   - Gate, One-Shot and Loop modes, with choke groups
--   - Playback through auto-configured ReaSamplOmatic5000 instances
--   - Save and load kits (`.ltkit`)
--   - Real-time Launchpad LED sync
--
--   ## Requirements
--   - [ReaImGui](https://github.com/cfillion/reaimgui) (available via ReaPack)
--   - Novation Launchpad MK3 (optional, to play on hardware)

--------------------------------------------------------------------------------
-- CONFIG & CONSTANTS
--------------------------------------------------------------------------------

local SCRIPT_NAME = "Little Things - Launchpad Chop Engine"
local GRID_ROWS = 8
local GRID_COLS = 8
local NUM_PADS = GRID_ROWS * GRID_COLS
local RS5K_NAME = "ReaSamplOmatic5000"

-- MK3 Programmer Mode note mapping: Row 0 (top) = notes 81-88, Row 7 (bottom) = 11-18
local function mk3_note_for_pad(row, col)
  return (8 - row) * 10 + (col + 1)
end

local function mk3_note_for_scene(index)
  return (8 - index) * 10 + 9
end

local function mk3_cc_for_function(index)
  return 91 + index
end

-- Launchpad Color Palette (velocity -> 0xRRGGBBAA hex color for GUI display)
local PALETTE = {
  { vel = 0,  name = "Off",          hex = 0x22242DFF },
  { vel = 5,  name = "Bright Red",   hex = 0xFF2D55FF },
  { vel = 6,  name = "Red",          hex = 0xD62246FF },
  { vel = 7,  name = "Dim Red",      hex = 0x8E1630FF },
  { vel = 9,  name = "Orange",       hex = 0xFF9500FF },
  { vel = 10, name = "Warm Amber",   hex = 0xE07A00FF },
  { vel = 11, name = "Dim Amber",    hex = 0x945100FF },
  { vel = 13, name = "Yellow",       hex = 0xFFCC00FF },
  { vel = 14, name = "Soft Yellow",  hex = 0xD4A900FF },
  { vel = 17, name = "Lime",         hex = 0xA4E000FF },
  { vel = 21, name = "Bright Green", hex = 0x34C759FF },
  { vel = 22, name = "Green",        hex = 0x248A3DFF },
  { vel = 23, name = "Dim Green",    hex = 0x145224FF },
  { vel = 29, name = "Mint / Teal",  hex = 0x00C7BEFF },
  { vel = 33, name = "Light Cyan",   hex = 0x32ADE6FF },
  { vel = 37, name = "Cyan",         hex = 0x007AFFFF },
  { vel = 45, name = "Deep Blue",    hex = 0x1B58F4FF },
  { vel = 46, name = "Navy Blue",    hex = 0x133EADFF },
  { vel = 49, name = "Indigo",       hex = 0x5856D6FF },
  { vel = 53, name = "Violet",       hex = 0xAF52DEFF },
  { vel = 54, name = "Purple",       hex = 0x893CAEFF },
  { vel = 57, name = "Bright Pink",  hex = 0xFF3B8AFF },
  { vel = 58, name = "Rose",         hex = 0xD12D70FF },
  { vel = 3,  name = "White",        hex = 0xFFFFFFFF },
  { vel = 2,  name = "Silver",       hex = 0xC7C7CCFF },
  { vel = 1,  name = "Dim White",    hex = 0x636366FF },
}

local VEL_TO_COLOR = {}
local VEL_TO_NAME = {}
for _, c in ipairs(PALETTE) do
  VEL_TO_COLOR[c.vel] = c.hex
  VEL_TO_NAME[c.vel] = c.name
end

local function get_color_for_vel(vel)
  return VEL_TO_COLOR[vel] or 0x007AFFFF
end

local function get_name_for_vel(vel)
  return VEL_TO_NAME[vel] or ("Color " .. vel)
end

local function brighten_color(rgba, factor)
  local r = (rgba >> 24) & 0xFF
  local g = (rgba >> 16) & 0xFF
  local b = (rgba >> 8) & 0xFF
  local a = rgba & 0xFF
  r = math.min(255, math.floor(r * factor + 20))
  g = math.min(255, math.floor(g * factor + 20))
  b = math.min(255, math.floor(b * factor + 20))
  return (r << 24) | (g << 16) | (b << 8) | a
end

-- Playback modes: 1=Gate (stop on release), 2=One-Shot (plays through chop), 3=Loop
local MODES = { "Gate (Hold)", "One-Shot", "Loop" }
local MODE_ICONS = { "[Gate]", "[1-Shot]", "[Loop]" }

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

local pads = {}            -- Array of 64 pad configs
local selected_pad = 1     -- 1-indexed
local current_kit_name = "Soul Chops 01"
local master_volume = 1.0
local status_msg = "Ready - Select a timeline range and send to pad!"
local status_color_hex = 0x34C759FF

-- Chop options
local chop_division = 16
local chop_choke = true
local chop_palette = "Rainbow"
local auto_advance = true
local default_chop_mode = 2 -- 1 = Gate (Release stops), 2 = One-Shot
local auto_mute_source_track = true -- Mute source track after capture to prevent double playback

-- MIDI device state
local midi_out_device = -1
local midi_out_name = ""
local midi_in_device = -1
local midi_in_name = ""
local midi_connected = false
local available_midi_ins = {}
local available_midi_outs = {}
local note_to_pad = {}
local last_midi_seq = nil
local last_bridge_note = -1
local last_bridge_active = -1

-- Track reference for RS5K instances
local rs5k_track = nil
local rs5k_fx_indices = {}

-- Active pad notes currently sounding
local active_pad_notes = {} -- pad_idx -> start_time
local pressed_pads = {}

-- ReaImGui context & fonts
local ctx = nil
local font_main = nil
local font_small = nil
local font_header = nil
local imgui_ready = false

local function set_status(msg, color)
  status_msg = msg
  status_color_hex = color or 0x34C759FF
end

--------------------------------------------------------------------------------
-- PAD DATA STRUCTURE
--------------------------------------------------------------------------------

local function create_pad(row, col)
  return {
    row = row,
    col = col,
    label = string.format("Pad %d,%d", row + 1, col + 1),
    sample_path = "",
    start_offs = 0.0,
    end_offs = 1.0,
    color_vel = 0,
    mode = 2,        -- 1=Gate (Stop on release), 2=One-Shot, 3=Loop
    volume = 1.0,    -- 1.0 = 0.0 dB (Unity gain, exact recorded amplitude)
    velocity_sensitive = false, -- false = Full Level (100% volume at any hit velocity), true = dynamic touch
    pitch_semitones = 0, -- -12 to +12 semitones
    pitch_rate = 1.0,
    release_ms = 0.0, -- 0 ms (Zero fade-out / volume drop at end of clip)
    choke_group = 1,  -- Default to Choke Group 1 so chops cut each other
    midi_note = mk3_note_for_pad(row, col),
  }
end

local function init_pads()
  pads = {}
  note_to_pad = {}
  for r = 0, GRID_ROWS - 1 do
    for c = 0, GRID_COLS - 1 do
      local idx = r * GRID_COLS + c + 1
      pads[idx] = create_pad(r, c)
      note_to_pad[pads[idx].midi_note] = idx
    end
  end
end

--------------------------------------------------------------------------------
-- EXACT RS5K PARAMETER CONSTANTS & RESOLUTION
--------------------------------------------------------------------------------

local RS5K_P = {
  VOL = 0,
  PAN = 1,
  MIN_VOL = 2,
  NOTE_START = 3,
  NOTE_END = 4,
  PITCH_START = 5,
  PITCH_END = 6,
  MIDI_CHAN = 7,
  VOICES = 8,
  ATTACK = 9,
  RELEASE = 10,
  OBEY_OFF = 11,
  LOOP = 12,
  START_OFFS = 13,
  END_OFFS = 14,
  PITCH = 15,
  PITCHBEND = 16,
  MIN_VEL = 17,
  MAX_VEL = 18,
  PROB = 19,
  ROUND_ROBIN = 20,
  FILTER_NOTES = 21,
  XFADE_LOOP = 22,
  LOOP_START = 23,
  DECAY = 24,
}

local function is_rs5k_fx(name)
  if not name or name == "" then return false end
  local n = name:lower()
  return n:find("reasamplomatic") or n:find("%(rs5k%)") or n:find("rs5k")
end

local function configure_rs5k_instance(track, fx_idx, pad)
  if not track or not fx_idx or not pad then return end
  
  local note = pad.midi_note
  
  -- 1. Note range: Lock exclusively to pad MIDI note
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.NOTE_START, note / 127)
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.NOTE_END, note / 127)
  reaper.TrackFX_SetNamedConfigParm(track, fx_idx, "NOTE_START", tostring(note))
  reaper.TrackFX_SetNamedConfigParm(track, fx_idx, "NOTE_END", tostring(note))
  
  -- 2. Attack: 0.0 (Instant punch)
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.ATTACK, 0.0)
  
  -- 3. Release: 0.0 (Zero fade-out! Eliminates any volume drop at end of clip)
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.RELEASE, 0.0)
  
  -- 4. Decay: 1.0 (Maximum 15000ms, zero volume drop during playback)
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.DECAY, 1.0)
  
  -- 5. Loop: Off unless explicitly in Loop mode (mode == 3)
  local loop_val = (pad.mode == 3) and 1.0 or 0.0
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.LOOP, loop_val)
  
  -- 6. Obey note-offs:
  -- Mode 1 = Gate (1.0: Stop when pad released)
  -- Mode 2 = One-Shot (0.0: Play full chop through to end)
  -- Mode 3 = Loop (1.0: Loop while held)
  local obey_val = (pad.mode == 2) and 0.0 or 1.0
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.OBEY_OFF, obey_val)
  
  -- 7. Max voices: 0.0 (1 voice monophonic, cuts off on re-trigger)
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.VOICES, 0.0)
  
  -- 8. Slice boundaries:
  local s_start = math.max(0.0, math.min(1.0, pad.start_offs or 0.0))
  local s_end = math.max(s_start + 0.0001, math.min(1.0, pad.end_offs or 1.0))
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.START_OFFS, s_start)
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.END_OFFS, s_end)
  
  -- 9. Volume: Unity gain (0.50 = 0.0 dB in RS5K) scaled by pad volume and master volume
  local eff_vol = math.max(0.0, math.min(1.0, (pad.volume or 1.0) * master_volume))
  local eff_norm = eff_vol * 0.5
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.VOL, eff_norm)
  
  -- 10. Velocity Sensitivity (Param 2: Gain for minimum velocity)
  -- false (Default / Full Level): 1.0 (0.0 dB gain for all velocities, no volume drop on soft hits)
  -- true (Dynamic Touch): 0.0 (-inf dB gain for min velocity, dynamic velocity response)
  local min_vol_norm = pad.velocity_sensitive and 0.0 or 1.0
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.MIN_VOL, min_vol_norm)
  
  -- 11. Pitch: 0.50 center (neutral 0.00 semitones), range -12..+12 semitones
  local pitch_norm = math.max(0.0, math.min(1.0, 0.5 + ((pad.pitch_semitones or 0) / 160.0)))
  reaper.TrackFX_SetParamNormalized(track, fx_idx, RS5K_P.PITCH, pitch_norm)
  
  reaper.TrackFX_SetNamedConfigParm(track, fx_idx, "DONE", "")
end

--------------------------------------------------------------------------------
-- RS5K TRACK & AUDIO ENGINE ROUTING
--------------------------------------------------------------------------------

local function find_or_create_rs5k_track()
  for i = 0, reaper.CountTracks(0) - 1 do
    local tr = reaper.GetTrack(0, i)
    local _, name = reaper.GetTrackName(tr)
    if name == "LT Chops" then
      rs5k_track = tr
      return tr
    end
  end
  
  reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
  rs5k_track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
  reaper.GetSetMediaTrackInfo_String(rs5k_track, "P_NAME", "LT Chops", true)
  return rs5k_track
end

local function sync_rs5k_instances()
  if not rs5k_track then find_or_create_rs5k_track() end
  if not rs5k_track then return end
  
  local fx_count = reaper.TrackFX_GetCount(rs5k_track)
  
  -- Step 1: Group RS5K instances by pad MIDI note
  local pad_to_fx = {}
  for i = 0, fx_count - 1 do
    local _, name = reaper.TrackFX_GetFXName(rs5k_track, i)
    if is_rs5k_fx(name) then
      local note_norm = reaper.TrackFX_GetParamNormalized(rs5k_track, i, RS5K_P.NOTE_START)
      local note_start = math.floor(note_norm * 127 + 0.5)
      local pad_idx = note_to_pad[note_start]
      local ok, file_path = reaper.TrackFX_GetNamedConfigParm(rs5k_track, i, "FILE0")
      local has_file = (ok and file_path and file_path ~= "")
      
      local item = {
        fx_idx = i,
        name = name,
        note = note_start,
        pad_idx = pad_idx,
        has_file = has_file,
        file_path = (ok and file_path) or ""
      }
      if pad_idx then
        if not pad_to_fx[pad_idx] then pad_to_fx[pad_idx] = {} end
        table.insert(pad_to_fx[pad_idx], item)
      end
    end
  end
  
  -- Step 2: Delete duplicate RS5K instances for any pad (keep best one)
  local to_delete = {}
  for p = 1, NUM_PADS do
    local list = pad_to_fx[p]
    if list and #list > 1 then
      local best = list[1]
      for _, inst in ipairs(list) do
        if inst.has_file then best = inst end
      end
      for _, inst in ipairs(list) do
        if inst.fx_idx ~= best.fx_idx then
          table.insert(to_delete, inst.fx_idx)
        end
      end
    end
  end
  
  if #to_delete > 0 then
    table.sort(to_delete, function(a, b) return a > b end)
    for _, del_idx in ipairs(to_delete) do
      reaper.TrackFX_Delete(rs5k_track, del_idx)
    end
  end
  
  -- Step 3: Rescan and map cleanly
  rs5k_fx_indices = {}
  local assigned_fx = {}
  fx_count = reaper.TrackFX_GetCount(rs5k_track)
  
  for i = 0, fx_count - 1 do
    local _, name = reaper.TrackFX_GetFXName(rs5k_track, i)
    if is_rs5k_fx(name) then
      local note_norm = reaper.TrackFX_GetParamNormalized(rs5k_track, i, RS5K_P.NOTE_START)
      local note_start = math.floor(note_norm * 127 + 0.5)
      local pad_idx = note_to_pad[note_start]
      if pad_idx and not rs5k_fx_indices[pad_idx] then
        rs5k_fx_indices[pad_idx] = i
        assigned_fx[i] = true
        
        -- Sync loaded sample path and slice boundaries back into GUI pad
        local ok, file_path = reaper.TrackFX_GetNamedConfigParm(rs5k_track, i, "FILE0")
        if ok and file_path and file_path ~= "" then
          pads[pad_idx].sample_path = file_path
          pads[pad_idx].start_offs = reaper.TrackFX_GetParamNormalized(rs5k_track, i, RS5K_P.START_OFFS)
          pads[pad_idx].end_offs = reaper.TrackFX_GetParamNormalized(rs5k_track, i, RS5K_P.END_OFFS)
          local fname = file_path:match("([^/\\]+)$") or "Sample"
          fname = fname:gsub("%.wav$", ""):gsub("%.aif[f]?$", ""):gsub("%.mp3$", ""):gsub("%.flac$", "")
          pads[pad_idx].label = fname
        end
      end
    end
  end
  
  -- Step 4: Ensure all pads have an RS5K instance
  for p = 1, NUM_PADS do
    if not rs5k_fx_indices[p] then
      local found_idx = nil
      for i = 0, fx_count - 1 do
        local _, name = reaper.TrackFX_GetFXName(rs5k_track, i)
        if is_rs5k_fx(name) and not assigned_fx[i] then
          found_idx = i
          assigned_fx[i] = true
          break
        end
      end
      
      if not found_idx then
        found_idx = reaper.TrackFX_AddByName(rs5k_track, RS5K_NAME, false, -1)
        if found_idx and found_idx >= 0 then
          assigned_fx[found_idx] = true
        end
      end
      
      if found_idx and found_idx >= 0 then
        rs5k_fx_indices[p] = found_idx
        configure_rs5k_instance(rs5k_track, found_idx, pads[p])
        local has_sample = (pads[p].sample_path ~= nil and pads[p].sample_path ~= "")
        reaper.TrackFX_SetEnabled(rs5k_track, found_idx, has_sample)
      end
    end
  end
end

local function get_pad_fx_idx(pad_idx)
  if not pad_idx or pad_idx < 1 or pad_idx > NUM_PADS then return nil end
  if not rs5k_track then find_or_create_rs5k_track() end
  if not rs5k_track then return nil end
  
  local idx = rs5k_fx_indices[pad_idx]
  if idx and idx >= 0 and idx < reaper.TrackFX_GetCount(rs5k_track) then
    local _, name = reaper.TrackFX_GetFXName(rs5k_track, idx)
    if is_rs5k_fx(name) then return idx end
  end
  
  sync_rs5k_instances()
  return rs5k_fx_indices[pad_idx]
end

local function ensure_rs5k_track_ready()
  find_or_create_rs5k_track()
  
  -- 4096 + 2016 = All MIDI inputs, all channels (Virtual MIDI Keyboard + Launchpad)
  reaper.SetMediaTrackInfo_Value(rs5k_track, "I_RECINPUT", 4096 + 2016)
  reaper.SetMediaTrackInfo_Value(rs5k_track, "I_RECARM", 1)              -- Armed
  reaper.SetMediaTrackInfo_Value(rs5k_track, "I_RECMON", 1)              -- Monitor input ON
  reaper.SetMediaTrackInfo_Value(rs5k_track, "I_RECMODE", 2)             -- Record disable (monitoring only)
  reaper.SetMediaTrackInfo_Value(rs5k_track, "B_MAINSEND", 1)            -- Route to Master
  reaper.SetMediaTrackInfo_Value(rs5k_track, "B_MUTE", 0)                -- Unmuted
  reaper.SetMediaTrackInfo_Value(rs5k_track, "D_VOL", 1.0)               -- 0 dB
  
  sync_rs5k_instances()
end

local function load_sample_to_rs5k(pad_idx, file_path, start_offs, end_offs)
  ensure_rs5k_track_ready()
  
  local fx_idx = get_pad_fx_idx(pad_idx)
  if not fx_idx then return end
  
  start_offs = start_offs or 0.0
  end_offs = end_offs or 1.0
  
  -- Enable RS5K instance and load audio file
  reaper.TrackFX_SetEnabled(rs5k_track, fx_idx, true)
  reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "FILE0", file_path)
  reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "DONE", "")
  
  pads[pad_idx].sample_path = file_path
  pads[pad_idx].start_offs = start_offs
  pads[pad_idx].end_offs = end_offs
  pads[pad_idx].mode = default_chop_mode
  pads[pad_idx].volume = 1.0
  pads[pad_idx].velocity_sensitive = false
  pads[pad_idx].pitch_semitones = 0
  pads[pad_idx].release_ms = 0.0
  pads[pad_idx].choke_group = 1
  
  -- Configure all parameters accurately
  configure_rs5k_instance(rs5k_track, fx_idx, pads[pad_idx])
  
  if pads[pad_idx].label:match("^Pad %d+,%d+$") then
    local name = file_path:match("([^/\\]+)$") or "Sample"
    name = name:gsub("%.wav$", ""):gsub("%.aif[f]?$", ""):gsub("%.mp3$", ""):gsub("%.flac$", "")
    pads[pad_idx].label = name
  end
end

local function update_rs5k_volume(pad_idx)
  local fx_idx = get_pad_fx_idx(pad_idx)
  if not fx_idx or not rs5k_track then return end
  local pad = pads[pad_idx]
  local eff_vol = math.max(0.0, math.min(1.0, (pad.volume or 1.0) * master_volume))
  local eff_vol_norm = eff_vol * 0.5
  reaper.TrackFX_SetParamNormalized(rs5k_track, fx_idx, RS5K_P.VOL, eff_vol_norm)
end

local function update_rs5k_velocity_sensitivity(pad_idx)
  local fx_idx = get_pad_fx_idx(pad_idx)
  if not fx_idx or not rs5k_track then return end
  local pad = pads[pad_idx]
  local min_vol_norm = pad.velocity_sensitive and 0.0 or 1.0
  reaper.TrackFX_SetParamNormalized(rs5k_track, fx_idx, RS5K_P.MIN_VOL, min_vol_norm)
end

--------------------------------------------------------------------------------
-- MIDI I/O & LAUNCHPAD HARDWARE INTEGRATION
--------------------------------------------------------------------------------

local function score_launchpad_device(name)
  if not name or name == "" then return -1 end
  local n = name:lower()
  
  -- Match any Novation Launchpad model (including macOS CoreMIDI short names like LPMiniMK3, LPX, LPPro)
  local is_lp = n:find("launchpad") or n:find("lpmini") or n:find("lpx") or n:find("lppro")
  if not is_lp then return -1 end
  
  local score = 100
  
  -- Heavily downrank DAW / Live port!
  -- Novation Launchpads create 2 ports on macOS / Windows:
  -- 1) MIDI / Programmer port (handles note matrix, SysEx, LED lighting)
  -- 2) DAW port (for Ableton Live proprietary control surface scripts)
  if n:find("daw") or n:find("%s+da$") or n:find("%s+da%s+") then
    score = score - 80
  end
  
  -- Strongly favor MIDI / Programmer / Standalone port
  if n:find("midi") or n:find("%s+mi$") or n:find("%s+mi%s+") or n:find("standalone") or n:find("programmer") then
    score = score + 50
  end
  
  return score
end

local function refresh_midi_device_lists()
  available_midi_ins = {}
  available_midi_outs = {}
  
  local num_ins = reaper.GetNumMIDIInputs and reaper.GetNumMIDIInputs() or 32
  for i = 0, math.max(32, num_ins - 1) do
    local rv, name = reaper.GetMIDIInputName(i, "")
    if rv and name and name ~= "" then
      table.insert(available_midi_ins, { id = i, name = name, score = score_launchpad_device(name) })
    end
  end

  local num_outs = reaper.GetNumMIDIOutputs and reaper.GetNumMIDIOutputs() or 32
  for i = 0, math.max(32, num_outs - 1) do
    local rv, name = reaper.GetMIDIOutputName(i, "")
    if rv and name and name ~= "" then
      table.insert(available_midi_outs, { id = i, name = name, score = score_launchpad_device(name) })
    end
  end
end

local function set_launchpad_programmer_mode(out_dev)
  if out_dev < 0 then return end
  
  -- Send Novation Programmer Mode SysEx messages:
  -- Mini MK3:  F0 00 20 29 02 0D 0E 01 F7
  -- LPX:       F0 00 20 29 02 0C 0E 01 F7
  -- LPPro MK3: F0 00 20 29 02 0E 0E 01 F7
  -- LPPro MK1: F0 00 20 29 02 10 2C 03 F7
  -- MK2:       F0 00 20 29 02 18 22 00 F7
  local sysex_msgs = {
    { 0xF0, 0x00, 0x20, 0x29, 0x02, 0x0D, 0x0E, 0x01, 0xF7 },
    { 0xF0, 0x00, 0x20, 0x29, 0x02, 0x0C, 0x0E, 0x01, 0xF7 },
    { 0xF0, 0x00, 0x20, 0x29, 0x02, 0x0E, 0x0E, 0x01, 0xF7 },
    { 0xF0, 0x00, 0x20, 0x29, 0x02, 0x10, 0x2C, 0x03, 0xF7 },
    { 0xF0, 0x00, 0x20, 0x29, 0x02, 0x18, 0x22, 0x00, 0xF7 },
  }
  
  for _, bytes in ipairs(sysex_msgs) do
    local msg = ""
    for _, b in ipairs(bytes) do msg = msg .. string.char(b) end
    if reaper.SendMIDIMessageToHardware then
      reaper.SendMIDIMessageToHardware(out_dev, msg)
    end
  end
end

local function find_launchpad_devices()
  refresh_midi_device_lists()
  
  -- Find best output device
  local best_out_score = 0
  local best_out_id = -1
  local best_out_name = ""
  for _, dev in ipairs(available_midi_outs) do
    if dev.score > best_out_score then
      best_out_score = dev.score
      best_out_id = dev.id
      best_out_name = dev.name
    end
  end
  
  -- Find best input device
  local best_in_score = 0
  local best_in_id = -1
  local best_in_name = ""
  for _, dev in ipairs(available_midi_ins) do
    if dev.score > best_in_score then
      best_in_score = dev.score
      best_in_id = dev.id
      best_in_name = dev.name
    end
  end
  
  midi_out_device = best_out_id
  midi_out_name = best_out_name
  midi_in_device = best_in_id
  midi_in_name = best_in_name
  
  midi_connected = (midi_out_device >= 0)
  
  if midi_connected then
    set_launchpad_programmer_mode(midi_out_device)
  end
end

local function send_midi_note(note, velocity)
  if midi_out_device < 0 then return end
  local n = math.max(0, math.min(127, math.floor(note)))
  local v = math.max(0, math.min(127, math.floor(velocity)))
  
  -- 1. Send via StuffMIDIMessage (mode 16 + dev)
  reaper.StuffMIDIMessage(16 + midi_out_device, 0x90, n, v)
  
  -- 2. Direct hardware send if supported by REAPER
  if reaper.SendMIDIMessageToHardware then
    local raw = string.char(0x90, n & 0x7F, v & 0x7F)
    reaper.SendMIDIMessageToHardware(midi_out_device, raw)
  end
end

local function send_pad_color(pad_idx)
  local pad = pads[pad_idx]
  if not pad then return end
  local note = mk3_note_for_pad(pad.row, pad.col)
  send_midi_note(note, pad.color_vel)
end

local function send_all_pad_colors()
  for i = 1, NUM_PADS do
    send_pad_color(i)
  end
end

local function clear_all_leds()
  if midi_out_device < 0 then return end
  for r = 0, 7 do
    for c = 0, 7 do
      send_midi_note(mk3_note_for_pad(r, c), 0)
    end
  end
  -- Also clear top function buttons CC 91-98 and scene launch buttons
  for i = 1, 8 do
    local cc = mk3_cc_for_function(i)
    if reaper.StuffMIDIMessage then
      reaper.StuffMIDIMessage(16 + midi_out_device, 0xB0, cc, 0)
    end
    if reaper.SendMIDIMessageToHardware then
      reaper.SendMIDIMessageToHardware(midi_out_device, string.char(0xB0, cc, 0))
    end
    local scene_note = mk3_note_for_scene(i - 1)
    send_midi_note(scene_note, 0)
  end
end

local flash_timers = {}

local function flash_pad(pad_idx)
  local pad = pads[pad_idx]
  if not pad then return end
  send_midi_note(mk3_note_for_pad(pad.row, pad.col), 3) -- White flash
  flash_timers[pad_idx] = reaper.time_precise() + 0.15
end

local function choke_group_cut(triggering_pad_idx)
  local trig_pad = pads[triggering_pad_idx]
  if not trig_pad or not trig_pad.choke_group or trig_pad.choke_group == 0 then return end
  
  local grp = trig_pad.choke_group
  for i = 1, NUM_PADS do
    if i ~= triggering_pad_idx and pads[i].choke_group == grp then
      -- 1. Send Note-Off to the virtual MIDI keyboard bus
      reaper.StuffMIDIMessage(0, 0x80, pads[i].midi_note, 0)
      
      -- 2. Flush voice in RS5K immediately (works even in One-Shot mode where RS5K ignores note-offs)
      local fx_i = get_pad_fx_idx(i)
      if fx_i and rs5k_track then
        reaper.TrackFX_SetEnabled(rs5k_track, fx_i, false)
        reaper.TrackFX_SetEnabled(rs5k_track, fx_i, true)
      end
      
      -- 3. Reset visual and LED state
      if pressed_pads[i] then
        pressed_pads[i] = nil
        send_pad_color(i)
      end
      active_pad_notes[i] = nil
      flash_timers[i] = nil
    end
  end
end

local function trigger_pad_off(pad_idx)
  local pad = pads[pad_idx]
  if not pad then return end
  reaper.StuffMIDIMessage(0, 0x80, pad.midi_note, 0)
  pressed_pads[pad_idx] = nil
  active_pad_notes[pad_idx] = nil
end

local function trigger_pad_on(pad_idx)
  local pad = pads[pad_idx]
  if not pad then return end
  
  ensure_rs5k_track_ready()
  
  -- Choke cutoff: Immediately cut all other pads in the same choke group
  choke_group_cut(pad_idx)
  
  -- Retrigger: Note-Off then Note-On
  reaper.StuffMIDIMessage(0, 0x80, pad.midi_note, 0)
  reaper.StuffMIDIMessage(0, 0x90, pad.midi_note, 127)
  
  flash_pad(pad_idx)
  pressed_pads[pad_idx] = true
  active_pad_notes[pad_idx] = reaper.time_precise()
  set_status(string.format("Playing %s (Note %d)", pad.label, pad.midi_note))
end

local function stop_all_sounds()
  for i = 0, 127 do
    reaper.StuffMIDIMessage(0, 0x80, i, 0)
  end
  if rs5k_track then
    for i = 1, NUM_PADS do
      local fx_i = get_pad_fx_idx(i)
      if fx_i then
        reaper.TrackFX_SetEnabled(rs5k_track, fx_i, false)
        local has_samp = (pads[i].sample_path ~= nil and pads[i].sample_path ~= "")
        reaper.TrackFX_SetEnabled(rs5k_track, fx_i, has_samp)
      end
    end
  end
  pressed_pads = {}
  active_pad_notes = {}
  set_status("All sounds stopped", 0xFF2D55FF)
end

local function update_flash_timers()
  local now = reaper.time_precise()
  local to_remove = {}
  for pad_idx, restore_time in pairs(flash_timers) do
    if now >= restore_time then
      send_pad_color(pad_idx)
      pressed_pads[pad_idx] = nil
      table.insert(to_remove, pad_idx)
    end
  end
  for _, idx in ipairs(to_remove) do
    flash_timers[idx] = nil
  end
end

--------------------------------------------------------------------------------
-- JSFX BRIDGE & HARDWARE INPUT LISTENER
--------------------------------------------------------------------------------

local function find_or_add_jsfx_bridge()
  if not rs5k_track then return -1 end
  local fx_count = reaper.TrackFX_GetCount(rs5k_track)
  for i = 0, fx_count - 1 do
    local _, name = reaper.TrackFX_GetFXName(rs5k_track, i)
    if name and name:find("Launchpad MIDI Bridge") then
      return i
    end
  end
  return -1
end

local function poll_hardware_midi_input()
  -- 1. Query REAPER global recent MIDI events (instant hardware reaction)
  if reaper.MIDI_GetRecentInputEvent then
    for idx = 0, 8 do
      local seq, buf, ts, devIdx, projPos, projLoopCnt = reaper.MIDI_GetRecentInputEvent(idx)
      if not seq or seq == 0 then break end
      if last_midi_seq and seq == last_midi_seq then break end
      
      local in_dev = devIdx and (devIdx & 0xFFFF) or -1
      local is_match = (midi_in_device < 0) or (in_dev == midi_in_device) or (in_dev == (midi_in_device & 0xFFFF))
      
      if is_match and buf and #buf >= 3 then
        local b1 = string.byte(buf, 1)
        local b2 = string.byte(buf, 2)
        local b3 = string.byte(buf, 3)
        local msg_type = b1 & 0xF0
        
        local pad_idx = note_to_pad[b2]
        if not pad_idx and b2 >= 36 and b2 < 36 + NUM_PADS then
          pad_idx = b2 - 36 + 1
        end
        
        if pad_idx and pads[pad_idx] then
          if msg_type == 0x90 and b3 > 0 then
            selected_pad = pad_idx
            pressed_pads[pad_idx] = true
            flash_pad(pad_idx)
            choke_group_cut(pad_idx)
            set_status(string.format("Pad #%d (Note %d) [Hardware Trigger]", pad_idx, b2))
          elseif msg_type == 0x80 or (msg_type == 0x90 and b3 == 0) then
            pressed_pads[pad_idx] = nil
            send_pad_color(pad_idx)
          end
        end
      end
    end
    
    local top_seq = reaper.MIDI_GetRecentInputEvent(0)
    if top_seq and top_seq ~= 0 then
      last_midi_seq = top_seq
    end
  end
  
  -- 2. Query JSFX Bridge if present on LT Chops track
  if rs5k_track then
    local bridge_idx = find_or_add_jsfx_bridge()
    if bridge_idx and bridge_idx >= 0 then
      local n = math.floor(reaper.TrackFX_GetParam(rs5k_track, bridge_idx, 0) + 0.5)
      local v = math.floor(reaper.TrackFX_GetParam(rs5k_track, bridge_idx, 1) + 0.5)
      local a = math.floor(reaper.TrackFX_GetParam(rs5k_track, bridge_idx, 2) + 0.5)
      
      if n ~= last_bridge_note or a ~= last_bridge_active then
        last_bridge_note = n
        last_bridge_active = a
        local pad_idx = note_to_pad[n]
        if not pad_idx and n >= 36 and n < 36 + NUM_PADS then
          pad_idx = n - 36 + 1
        end
        if pad_idx and pads[pad_idx] then
          if a == 1 and v > 0 then
            selected_pad = pad_idx
            pressed_pads[pad_idx] = true
            flash_pad(pad_idx)
            choke_group_cut(pad_idx)
          else
            pressed_pads[pad_idx] = nil
            send_pad_color(pad_idx)
          end
        end
      end
    end
  end
end

--------------------------------------------------------------------------------
-- FILE SYSTEM & TRACK SOUND MANAGEMENT
--------------------------------------------------------------------------------

local function file_exists(path)
  if not path or path == "" then return false end
  local f = io.open(path, "rb")
  if f then
    f:close()
    return true
  end
  return false
end

local function copy_file(src, dst)
  local fin = io.open(src, "rb")
  if not fin then return false end
  local fout = io.open(dst, "wb")
  if not fout then fin:close() return false end
  fout:write(fin:read("*all"))
  fin:close()
  fout:close()
  return true
end

local function get_bounces_dir()
  local proj_path = reaper.GetProjectPath("")
  local dir = nil
  if proj_path and proj_path ~= "" then
    dir = proj_path .. "/LittleThings_Bounces"
  else
    dir = reaper.GetResourcePath() .. "/Scripts/LittleThings_Bounces"
  end
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
end

local function get_source_track()
  local tr = reaper.GetSelectedTrack(0, 0)
  if tr and tr ~= rs5k_track then
    local _, tn = reaper.GetTrackName(tr)
    if tn ~= "LT Chops" then return tr end
  end
  local it = reaper.GetSelectedMediaItem(0, 0)
  if it then
    local itr = reaper.GetMediaItem_Track(it)
    if itr and itr ~= rs5k_track then
      local _, tn = reaper.GetTrackName(itr)
      if tn ~= "LT Chops" then return itr end
    end
  end
  for i = 0, reaper.CountTracks(0) - 1 do
    local t = reaper.GetTrack(0, i)
    if t ~= rs5k_track then
      local _, tn = reaper.GetTrackName(t)
      if tn ~= "LT Chops" then return t end
    end
  end
  return nil
end

local function toggle_source_track_mute()
  local track = get_source_track()
  if not track then
    set_status("[!] No source track found to mute", 0xFF3B30FF)
    return
  end
  local cur_mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
  local new_mute = (cur_mute > 0.5) and 0 or 1
  reaper.SetMediaTrackInfo_Value(track, "B_MUTE", new_mute)
  local _, tr_name = reaper.GetTrackName(track)
  set_status(string.format("Source track [%s]: %s", tr_name, (new_mute == 1) and "MUTED" or "UNMUTED"), (new_mute == 1) and 0xFF9500FF or 0x34C759FF)
end

local function silence_selected_range_on_source_track()
  local track = get_source_track()
  if not track then
    set_status("[!] Select a source track first", 0xFF3B30FF)
    return
  end
  
  local _, tr_name = reaper.GetTrackName(track)
  local t_start, t_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if t_end <= t_start then
    local item = reaper.GetSelectedMediaItem(0, 0)
    if item then
      t_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      t_end = t_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    else
      set_status("[!] Select a time selection or item on the timeline", 0xFF3B30FF)
      return
    end
  end
  
  reaper.Undo_BeginBlock()
  local num_items = reaper.CountTrackMediaItems(track)
  local to_delete = {}
  
  for i = num_items - 1, 0, -1 do
    local it = reaper.GetTrackMediaItem(track, i)
    local ipos = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
    local ilen = reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
    local iend = ipos + ilen
    
    if ipos < t_end and iend > t_start then
      if iend > t_end and ipos < t_end then
        reaper.SplitMediaItem(it, t_end)
      end
      local mid_item = it
      if ipos < t_start then
        mid_item = reaper.SplitMediaItem(it, t_start)
      end
      if mid_item then
        table.insert(to_delete, mid_item)
      end
    end
  end
  
  for _, it in ipairs(to_delete) do
    reaper.DeleteTrackMediaItem(track, it)
  end
  
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Little Things: Silence Audio on Source Track", -1)
  
  set_status(string.format("[CUT] Audio cut/deleted from track [%s] (%.2fs - %.2fs)", tr_name, t_start, t_end), 0xFF3B30FF)
end

local function solo_lt_chops_track()
  if not rs5k_track then find_or_create_rs5k_track() end
  if not rs5k_track then return end
  local cur_solo = reaper.GetMediaTrackInfo_Value(rs5k_track, "I_SOLO")
  local new_solo = (cur_solo > 0.5) and 0 or 1
  reaper.SetMediaTrackInfo_Value(rs5k_track, "I_SOLO", new_solo)
  set_status(string.format("LT Chops track %s", (new_solo == 1) and "SOLOED" or "UN-SOLOED"), (new_solo == 1) and 0xFF9500FF or 0x34C759FF)
end

--------------------------------------------------------------------------------
-- INSTANT CHOP / RANGE CAPTURE (MIDI OR WAV)
--------------------------------------------------------------------------------

local function capture_timeline_range_audio()
  local t_start, t_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local has_time_sel = (t_end > t_start and (t_end - t_start) > 0.005)
  
  local track = get_source_track()
  local item = reaper.GetSelectedMediaItem(0, 0)
  
  if not track and item then
    track = reaper.GetMediaItem_Track(item)
    if track then reaper.SetOnlyTrackSelected(track) end
  end
  
  if not track then return nil, "No source track found in project" end
  
  reaper.SetOnlyTrackSelected(track)
  local _, tr_name = reaper.GetTrackName(track)
  
  if not has_time_sel then
    if item then
      t_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      t_end = t_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      reaper.GetSet_LoopTimeRange(true, false, t_start, t_end, false)
      has_time_sel = true
    else
      return nil, "Please make a time selection or select an item on the timeline"
    end
  end
  
  local range_dur = t_end - t_start
  if range_dur <= 0.005 then return nil, "Selected range is too short" end
  
  reaper.Undo_BeginBlock()
  
  local n_before = reaper.CountTracks(0)
  local orig_mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE")
  
  -- Render selected area of tracks to stereo post-fader stem tracks
  reaper.Main_OnCommand(41716, 0)
  
  local n_after = reaper.CountTracks(0)
  local wav_path = nil
  
  if n_after > n_before then
    local stem_track = nil
    for i = 0, n_after - 1 do
      local t = reaper.GetTrack(0, i)
      if t ~= track and t ~= rs5k_track then
        local _, name = reaper.GetTrackName(t)
        if name:lower():find("stem") then
          stem_track = t
          break
        end
      end
    end
    
    if not stem_track then stem_track = reaper.GetTrack(0, n_after - 1) end
    
    if stem_track then
      local stem_item = reaper.GetTrackMediaItem(stem_track, 0)
      if stem_item then
        local take = reaper.GetActiveTake(stem_item)
        if take then
          local src = reaper.GetMediaItemTake_Source(take)
          wav_path = reaper.GetMediaSourceFileName(src, "")
        end
      end
      reaper.DeleteTrack(stem_track)
    end
    
    -- Mute the source track so it doesn't double the chops
    if auto_mute_source_track then
      reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)
    else
      reaper.SetMediaTrackInfo_Value(track, "B_MUTE", orig_mute)
    end
  end
  
  reaper.Undo_EndBlock("Little Things: Capture Range", -1)
  
  -- Guarantee the file is permanently saved into LittleThings_Bounces directory
  if wav_path and wav_path ~= "" and file_exists(wav_path) then
    local bounces_dir = get_bounces_dir()
    local fname = wav_path:match("([^/\\]+)$") or string.format("Chop_%d.wav", os.time())
    local safe_path = bounces_dir .. "/" .. fname
    if wav_path ~= safe_path then
      if copy_file(wav_path, safe_path) then
        wav_path = safe_path
      end
    end
    return wav_path, range_dur, false
  end
  
  if item then
    local take = reaper.GetActiveTake(item)
    if take and not reaper.TakeIsMIDI(take) then
      local src = reaper.GetMediaItemTake_Source(take)
      local fpath = reaper.GetMediaSourceFileName(src, "")
      if fpath and fpath ~= "" and file_exists(fpath) then
        if auto_mute_source_track then
          reaper.SetMediaTrackInfo_Value(track, "B_MUTE", 1)
        end
        return fpath, range_dur, true
      end
    end
  end
  
  return nil, "Render failed: ensure selected track has audio or MIDI in this range"
end

local function send_range_to_selected_pad()
  local target_pad = selected_pad
  local wav_path, duration_or_err, is_sliced_source = capture_timeline_range_audio()
  
  if not wav_path then
    set_status("[!] " .. (duration_or_err or "Capture failed"), 0xFF3B30FF)
    return false
  end
  
  ensure_rs5k_track_ready()
  
  local start_offs = 0.0
  local end_offs = 1.0
  
  if is_sliced_source then
    local item = reaper.GetSelectedMediaItem(0, 0)
    local take = reaper.GetActiveTake(item)
    local s_offs = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local it_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local src_len = reaper.GetMediaSourceLength(reaper.GetMediaItemTake_Source(take))
    local t_start, t_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if t_end > t_start and src_len > 0 then
      local rel_start = math.max(0, t_start - it_pos)
      local rel_end = math.min(reaper.GetMediaItemInfo_Value(item, "D_LENGTH"), t_end - it_pos)
      start_offs = math.max(0, (s_offs + rel_start) / src_len)
      end_offs = math.min(1, (s_offs + rel_end) / src_len)
    end
  end
  
  pads[target_pad].mode = default_chop_mode
  pads[target_pad].volume = 1.0
  pads[target_pad].velocity_sensitive = false
  pads[target_pad].pitch_semitones = 0
  pads[target_pad].release_ms = 0.0
  pads[target_pad].choke_group = 1
  pads[target_pad].is_bounced = not is_sliced_source
  
  load_sample_to_rs5k(target_pad, wav_path, start_offs, end_offs)
  
  pads[target_pad].label = string.format("Chop %02d", target_pad)
  
  if pads[target_pad].color_vel == 0 then
    local palette_colors = { 9, 13, 21, 29, 37, 45, 53, 57 }
    pads[target_pad].color_vel = palette_colors[((target_pad - 1) % #palette_colors) + 1]
  end
  
  send_pad_color(target_pad)
  
  -- Play confirmation sound!
  trigger_pad_on(target_pad)
  
  local next_pad = target_pad
  if auto_advance then
    next_pad = (target_pad < NUM_PADS) and (target_pad + 1) or 1
    selected_pad = next_pad
  end
  
  set_status(string.format("[OK] Captured to Pad %d & playing! (Next: Pad %d)", target_pad, next_pad), 0x34C759FF)
  return true
end

local function chop_range_into_n_pads(num_chops)
  local wav_path, duration_or_err, is_sliced_source = capture_timeline_range_audio()
  
  if not wav_path then
    set_status("[!] " .. (duration_or_err or "Chop failed"), 0xFF3B30FF)
    return false
  end
  
  ensure_rs5k_track_ready()
  
  local count = math.min(num_chops, NUM_PADS)
  local palette_colors = { 9, 13, 21, 29, 37, 45, 53, 57 }
  
  reaper.Undo_BeginBlock()
  
  for i = 1, count do
    local slice_start = (i - 1) / count
    local slice_end = i / count
    
    pads[i].mode = default_chop_mode
    pads[i].volume = 1.0
    pads[i].velocity_sensitive = false
    pads[i].pitch_semitones = 0
    pads[i].release_ms = 0.0
    pads[i].choke_group = chop_choke and 1 or 0
    pads[i].color_vel = palette_colors[((i - 1) % #palette_colors) + 1]
    pads[i].is_bounced = not is_sliced_source
    
    load_sample_to_rs5k(i, wav_path, slice_start, slice_end)
    pads[i].label = string.format("Chop %02d", i)
  end
  
  reaper.Undo_EndBlock("Little Things: Chop Range", -1)
  
  send_all_pad_colors()
  trigger_pad_on(1)
  selected_pad = 1
  
  set_status(string.format("[OK] Sliced range into %d pads! Press pads to play.", count), 0x34C759FF)
  return true
end

local function get_timeline_display_text()
  local t_start, t_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  local has_time_sel = (t_end > t_start and (t_end - t_start) > 0.005)
  local track = reaper.GetSelectedTrack(0, 0)
  local item = reaper.GetSelectedMediaItem(0, 0)
  
  local tr_name = "Track"
  if track then
    local _, tn = reaper.GetTrackName(track)
    tr_name = tn
  elseif item then
    local it_tr = reaper.GetMediaItem_Track(item)
    local _, tn = reaper.GetTrackName(it_tr)
    tr_name = tn
  end
  
  if has_time_sel then
    return string.format("[TIME] Range: %.2fs - %.2fs (Len: %.2fs) on [%s]", t_start, t_end, t_end - t_start, tr_name), 0x007AFFFF
  elseif item then
    local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    local take = reaper.GetActiveTake(item)
    local name = take and reaper.GetTakeName(take) or "Item"
    return string.format("[ITEM] '%s' (%.2fs) on [%s] - Ready to chop", name, len, tr_name), 0xFF9500FF
  else
    return "[TIP] Select track & time range in REAPER, then click 'Send to Pad'", 0x8E8E93FF
  end
end

--------------------------------------------------------------------------------
-- PRESET / KIT MANAGEMENT
--------------------------------------------------------------------------------

local function get_kits_dir()
  local resource_path = reaper.GetResourcePath()
  local dir = resource_path .. "/Scripts/LittleThings_Kits"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
end

local function save_kit(name)
  local dir = get_kits_dir()
  local safe_name = name:gsub("[^%w_%-]", "_")
  local path = dir .. "/" .. safe_name .. ".ltkit"
  
  local f = io.open(path, "w")
  if not f then
    set_status("Error saving preset: permission denied", 0xFF3B30FF)
    return false
  end
  
  f:write("-- Little Things Kit\n")
  f:write("return {\n")
  f:write(string.format('  name = %q,\n', name))
  f:write(string.format('  master_volume = %.3f,\n', master_volume))
  f:write("  pads = {\n")
  
  for i = 1, NUM_PADS do
    local p = pads[i]
    f:write("    {\n")
    f:write(string.format('      row = %d, col = %d,\n', p.row, p.col))
    f:write(string.format('      label = %q,\n', p.label))
    f:write(string.format('      sample_path = %q,\n', p.sample_path))
    f:write(string.format('      start_offs = %.6f,\n', p.start_offs or 0.0))
    f:write(string.format('      end_offs = %.6f,\n', p.end_offs or 1.0))
    f:write(string.format('      release_ms = %.2f,\n', 0.0))
    f:write(string.format('      color_vel = %d,\n', p.color_vel))
    f:write(string.format('      mode = %d,\n', p.mode))
    f:write(string.format('      volume = %.3f,\n', p.volume or 1.0))
    f:write(string.format('      velocity_sensitive = %s,\n', p.velocity_sensitive and "true" or "false"))
    f:write(string.format('      pitch_semitones = %d,\n', p.pitch_semitones or 0))
    f:write(string.format('      pitch_rate = %.3f,\n', p.pitch_rate or 1.0))
    f:write(string.format('      choke_group = %d,\n', p.choke_group))
    f:write(string.format('      midi_note = %d,\n', p.midi_note))
    f:write("    },\n")
  end
  
  f:write("  }\n")
  f:write("}\n")
  f:close()
  
  current_kit_name = name
  set_status("[OK] Preset saved: " .. name, 0x34C759FF)
  return true
end

local function load_kit(path)
  local chunk = loadfile(path)
  if not chunk then
    set_status("Error loading preset file", 0xFF3B30FF)
    return false
  end
  
  local ok, data = pcall(chunk)
  if not ok or type(data) ~= "table" then
    set_status("Error: corrupt preset format", 0xFF3B30FF)
    return false
  end
  
  current_kit_name = data.name or "Loaded Kit"
  master_volume = data.master_volume or 1.0
  
  ensure_rs5k_track_ready()
  
  if data.pads then
    for i, p in ipairs(data.pads) do
      if i <= NUM_PADS and pads[i] then
        pads[i].label = p.label or pads[i].label
        pads[i].sample_path = p.sample_path or ""
        pads[i].start_offs = p.start_offs or 0.0
        pads[i].end_offs = p.end_offs or 1.0
        pads[i].release_ms = 0.0
        pads[i].color_vel = p.color_vel or 0
        pads[i].mode = p.mode or default_chop_mode
        pads[i].volume = p.volume or 1.0
        pads[i].velocity_sensitive = (p.velocity_sensitive == true)
        pads[i].pitch_semitones = p.pitch_semitones or 0
        pads[i].pitch_rate = p.pitch_rate or 1.0
        pads[i].choke_group = p.choke_group or 0
        
        local fx_i = get_pad_fx_idx(i)
        if pads[i].sample_path ~= "" then
          local p_path = pads[i].sample_path
          if not file_exists(p_path) then
            local fname = p_path:match("([^/\\]+)$")
            local b_dir = get_bounces_dir()
            local kit_dir = path:match("^(.*)[/\\]") or ""
            if fname and file_exists(b_dir .. "/" .. fname) then
              p_path = b_dir .. "/" .. fname
            elseif fname and kit_dir ~= "" and file_exists(kit_dir .. "/" .. fname) then
              p_path = kit_dir .. "/" .. fname
            end
          end
          if file_exists(p_path) then
            pads[i].sample_path = p_path
            load_sample_to_rs5k(i, pads[i].sample_path, pads[i].start_offs, pads[i].end_offs)
          else
            if rs5k_track and fx_i then
              reaper.TrackFX_SetEnabled(rs5k_track, fx_i, false)
              reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_i, "-FILE*", "")
              reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_i, "FILE0", "")
              reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_i, "DONE", "")
            end
          end
        else
          if rs5k_track and fx_i then
            reaper.TrackFX_SetEnabled(rs5k_track, fx_i, false)
            reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_i, "-FILE*", "")
            reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_i, "FILE0", "")
            reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_i, "DONE", "")
          end
        end
        update_rs5k_volume(i)
      end
    end
  end
  
  send_all_pad_colors()
  set_status("[OK] Loaded preset: " .. current_kit_name, 0x34C759FF)
  return true
end

-- Presets bundled with the script (installed by ReaPack via @provides)
local function get_bundled_presets_dir()
  local script_path = select(2, reaper.get_action_context())
  local script_dir = script_path and script_path:match("^(.*)[/\\]")
  return script_dir and (script_dir .. "/Little Things/Presets") or nil
end

local function list_kits()
  local kits = {}
  local seen = {}
  local dirs = { get_kits_dir(), get_bundled_presets_dir() }
  for _, dir in ipairs(dirs) do
    local i = 0
    repeat
      local file = reaper.EnumerateFiles(dir, i)
      if file then
        if file:match("%.ltkit$") and not seen[file] then
          seen[file] = true
          local name = file:gsub("%.ltkit$", ""):gsub("_", " ")
          table.insert(kits, { name = name, path = dir .. "/" .. file, filename = file })
        end
        i = i + 1
      end
    until not file
  end
  return kits
end

local function delete_pad_chop(pad_idx)
  local pad = pads[pad_idx]
  if not pad then return end
  local old_path = pad.sample_path
  local was_bounced = pad.is_bounced
  
  -- 1. Stop pad playback immediately
  trigger_pad_off(pad_idx)
  
  -- 2. Reset pad parameters
  pad.sample_path = ""
  pad.label = string.format("Pad %d,%d", pad.row + 1, pad.col + 1)
  pad.color_vel = 0
  pad.start_offs = 0.0
  pad.end_offs = 1.0
  pad.volume = 1.0
  pad.velocity_sensitive = false
  pad.pitch_semitones = 0
  pad.release_ms = 0.0
  pad.is_bounced = false
  
  -- 3. Completely disable and flush RS5K instance
  local fx_idx = get_pad_fx_idx(pad_idx)
  if rs5k_track and fx_idx then
    reaper.TrackFX_SetEnabled(rs5k_track, fx_idx, false)
    reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "-FILE*", "")
    reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "FILE0", "")
    reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "DONE", "")
  end
  
  -- 4. Turn off hardware LED immediately
  send_midi_note(pad.midi_note, 0)
  
  -- 5. Delete file on disk if it was a bounced chop and no other pad uses it
  if old_path and old_path ~= "" and was_bounced then
    local in_use_by_other = false
    for i = 1, NUM_PADS do
      if i ~= pad_idx and pads[i].sample_path == old_path then
        in_use_by_other = true
        break
      end
    end
    if not in_use_by_other then
      pcall(os.remove, old_path)
      pcall(os.remove, old_path .. ".reapeaks")
    end
  end
  set_status(string.format("[DEL] Deleted chop from Pad #%d", pad_idx), 0x8E8E93FF)
end

local function clear_all_pads()
  local paths_to_delete = {}
  for i = 1, NUM_PADS do
    if pads[i].is_bounced and pads[i].sample_path and pads[i].sample_path ~= "" then
      paths_to_delete[pads[i].sample_path] = true
    end
  end
  
  stop_all_sounds()
  
  init_pads()
  if rs5k_track then
    for i = 1, NUM_PADS do
      local fx_idx = rs5k_fx_indices[i]
      if fx_idx then
        reaper.TrackFX_SetEnabled(rs5k_track, fx_idx, false)
        reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "-FILE*", "")
        reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "FILE0", "")
        reaper.TrackFX_SetNamedConfigParm(rs5k_track, fx_idx, "DONE", "")
      end
    end
  end
  clear_all_leds()
  
  for p in pairs(paths_to_delete) do
    pcall(os.remove, p)
    pcall(os.remove, p .. ".reapeaks")
  end
  
  set_status("[DEL] Cleared all pads and deleted chops", 0x8E8E93FF)
end

--------------------------------------------------------------------------------
-- REAIMGUI INITIALIZATION
--------------------------------------------------------------------------------

local function init_imgui()
  if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox(
      "This script requires ReaImGui extension.\n\nInstall via ReaPack and restart REAPER.",
      "Little Things - Missing Dependency", 0)
    return false
  end
  
  ctx = reaper.ImGui_CreateContext(SCRIPT_NAME)
  font_main = reaper.ImGui_CreateFont("Arial", 0)
  font_small = reaper.ImGui_CreateFont("Arial", 0)
  font_header = reaper.ImGui_CreateFont("Arial", 0)
  
  reaper.ImGui_Attach(ctx, font_main)
  reaper.ImGui_Attach(ctx, font_small)
  reaper.ImGui_Attach(ctx, font_header)
  
  imgui_ready = true
  return true
end

--------------------------------------------------------------------------------
-- UI COMPONENTS
--------------------------------------------------------------------------------

-- Pad Button
local function draw_pad_button(pad_idx, size)
  local pad = pads[pad_idx]
  if not pad then return false end
  
  local is_selected = (pad_idx == selected_pad)
  local is_pressed = pressed_pads[pad_idx]
  
  local bg_color = get_color_for_vel(pad.color_vel)
  local imgui_bg = is_pressed and 0xFFFFFFFF or bg_color
  local hovered_bg = brighten_color(imgui_bg, 1.25)
  local active_bg = 0xFFFFFFFF
  
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), imgui_bg)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), hovered_bg)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), active_bg)
  
  if is_selected then
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFF9500FF)
    reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 2.5)
  end
  
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 4.0)
  
  local text_color = (pad.color_vel == 0) and 0x8E8E93FF or (is_pressed and 0x000000FF or 0xFFFFFFFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), text_color)
  
  local display_label = pad.label
  if #display_label > 10 then display_label = display_label:sub(1, 9) .. "..." end
  
  local has_sample_mark = (pad.sample_path ~= "") and "[+] " or ""
  local btn_label = string.format("%s%s\n#%d", has_sample_mark, display_label, pad_idx)
  local clicked = reaper.ImGui_Button(ctx, btn_label .. "##pad" .. pad_idx, size, size)
  
  -- Handle release when mouse is deactivated
  if reaper.ImGui_IsItemDeactivated(ctx) and pad.mode == 1 then
    trigger_pad_off(pad_idx)
  end
  
  local pop_colors = is_selected and 5 or 4
  local pop_vars = is_selected and 2 or 1
  reaper.ImGui_PopStyleColor(ctx, pop_colors)
  reaper.ImGui_PopStyleVar(ctx, pop_vars)
  
  if clicked then
    selected_pad = pad_idx
    trigger_pad_on(pad_idx)
  end
  
  -- Right-click popup
  if reaper.ImGui_IsItemClicked(ctx, reaper.ImGui_MouseButton_Right()) then
    selected_pad = pad_idx
    reaper.ImGui_OpenPopup(ctx, "pad_context_" .. pad_idx)
  end
  
  if reaper.ImGui_BeginPopup(ctx, "pad_context_" .. pad_idx) then
    if reaper.ImGui_MenuItem(ctx, "[SEND] Send Current Range to this Pad") then
      send_range_to_selected_pad()
    end
    if reaper.ImGui_MenuItem(ctx, "Load WAV Sample...") then
      local retval, file = reaper.GetUserFileNameForRead("", "Load Audio Sample", "*.wav;*.aif;*.aiff;*.mp3;*.flac")
      if retval then load_sample_to_rs5k(pad_idx, file) end
    end
    if reaper.ImGui_MenuItem(ctx, "[DEL] Delete Chop from Pad") then
      delete_pad_chop(pad_idx)
    end
    reaper.ImGui_EndPopup(ctx)
  end
  
  -- Drag-and-drop
  if reaper.ImGui_BeginDragDropTarget(ctx) then
    local rv, count = reaper.ImGui_AcceptDragDropPayloadFiles(ctx)
    if rv and count and count > 0 then
      local rv_file, file_path = reaper.ImGui_GetDragDropPayloadFile(ctx, 0)
      if rv_file and file_path and file_path ~= "" then
        load_sample_to_rs5k(pad_idx, file_path)
        selected_pad = pad_idx
        trigger_pad_on(pad_idx)
      end
    end
    reaper.ImGui_EndDragDropTarget(ctx)
  end
  
  return clicked
end

-- Inspector Panel
local function draw_inspector()
  local pad = pads[selected_pad]
  if not pad then return end
  
  reaper.ImGui_PushFont(ctx, font_header, 16)
  reaper.ImGui_TextColored(ctx, 0xFF9500FF, string.format("PAD #%d  (%d,%d)", selected_pad, pad.row + 1, pad.col + 1))
  reaper.ImGui_PopFont(ctx)
  
  reaper.ImGui_Spacing(ctx)
  
  -- Direct Capture to This Pad button
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x34C759FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x4CD964FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x248A3DFF)
  if reaper.ImGui_Button(ctx, string.format("[GRAB] Timeline Range to Pad #%d", selected_pad), -1, 32) then
    send_range_to_selected_pad()
  end
  reaper.ImGui_PopStyleColor(ctx, 3)
  
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Spacing(ctx)
  
  -- Label
  local rv_label, new_label = reaper.ImGui_InputText(ctx, "Label", pad.label)
  if rv_label then pad.label = new_label end
  
  reaper.ImGui_Spacing(ctx)
  
  -- Audio Sample & Slice Range
  reaper.ImGui_PushFont(ctx, font_small, 10)
  reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "AUDIO SAMPLE & SLICE RANGE")
  reaper.ImGui_PopFont(ctx)
  
  if pad.sample_path ~= "" then
    local filename = pad.sample_path:match("([^/\\]+)$") or pad.sample_path
    reaper.ImGui_TextColored(ctx, 0x34C759FF, "[WAV] " .. filename)
    
    local slice_pct_str = string.format("Slice: %.1f%% -> %.1f%%", (pad.start_offs or 0) * 100, (pad.end_offs or 1) * 100)
    reaper.ImGui_TextColored(ctx, 0x007AFFFF, slice_pct_str)
    
    local rv_s, new_s = reaper.ImGui_SliderDouble(ctx, "Start Offs", pad.start_offs or 0.0, 0.0, 1.0, "%.3f")
    if rv_s then
      pad.start_offs = new_s
      local fx_idx = get_pad_fx_idx(selected_pad)
      if fx_idx and rs5k_track then
        reaper.TrackFX_SetParamNormalized(rs5k_track, fx_idx, RS5K_P.START_OFFS, new_s)
      end
    end
    
    local rv_e, new_e = reaper.ImGui_SliderDouble(ctx, "End Offs", pad.end_offs or 1.0, 0.0, 1.0, "%.3f")
    if rv_e then
      pad.end_offs = new_e
      local fx_idx = get_pad_fx_idx(selected_pad)
      if fx_idx and rs5k_track then
        reaper.TrackFX_SetParamNormalized(rs5k_track, fx_idx, RS5K_P.END_OFFS, new_e)
      end
    end
  else
    reaper.ImGui_TextColored(ctx, 0x636366FF, "No sample loaded")
  end
  
  if reaper.ImGui_Button(ctx, "Load WAV File...", -1, 24) then
    local retval, file = reaper.GetUserFileNameForRead("", "Load Audio Sample", "*.wav;*.aif;*.aiff;*.mp3;*.flac")
    if retval then load_sample_to_rs5k(selected_pad, file) end
  end
  
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Spacing(ctx)
  
  -- Playback Mode (Gate vs One-Shot vs Loop)
  reaper.ImGui_PushFont(ctx, font_small, 10)
  reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "PLAYBACK MODE")
  reaper.ImGui_PopFont(ctx)
  
  for m = 1, #MODES do
    if m > 1 then reaper.ImGui_SameLine(ctx) end
    local is_active = (pad.mode == m)
    if is_active then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF9500FF) end
    if reaper.ImGui_Button(ctx, MODE_ICONS[m] .. " " .. MODES[m] .. "##mode" .. m) then
      pad.mode = m
      local fx_idx = get_pad_fx_idx(selected_pad)
      if fx_idx and rs5k_track then
        local obey_val = (m == 2) and 0.0 or 1.0
        local loop_val = (m == 3) and 1.0 or 0.0
        reaper.TrackFX_SetParamNormalized(rs5k_track, fx_idx, RS5K_P.OBEY_OFF, obey_val)
        reaper.TrackFX_SetParamNormalized(rs5k_track, fx_idx, RS5K_P.LOOP, loop_val)
      end
    end
    if is_active then reaper.ImGui_PopStyleColor(ctx) end
  end
  
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Spacing(ctx)
  
  -- Sound Parameters: Volume, Pitch, Velocity Sensitivity, Choke Group
  reaper.ImGui_PushFont(ctx, font_small, 10)
  reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "SOUND PARAMETERS")
  reaper.ImGui_PopFont(ctx)
  
  local rv_vol, new_vol = reaper.ImGui_SliderDouble(ctx, "Volume", pad.volume or 1.0, 0.0, 1.0, "%.0f%%")
  if rv_vol then
    pad.volume = new_vol
    update_rs5k_volume(selected_pad)
  end
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_SetTooltip(ctx, "Pad volume level (100% = 0.0 dB original track volume)")
  end
  
  local current_semi = math.floor((pad.pitch_semitones or 0) + 0.5)
  local rv_pitch, new_pitch = reaper.ImGui_SliderInt(ctx, "Pitch (Semitones)", current_semi, -12, 12, "%+d st")
  if rv_pitch then
    pad.pitch_semitones = new_pitch
    local fx_idx = get_pad_fx_idx(selected_pad)
    if fx_idx and rs5k_track then
      local norm = math.max(0.0, math.min(1.0, 0.5 + (new_pitch / 160.0)))
      reaper.TrackFX_SetParamNormalized(rs5k_track, fx_idx, RS5K_P.PITCH, norm)
    end
  end
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_SetTooltip(ctx, "Tune chop pitch up or down (-12 to +12 semitones)")
  end
  
  local rv_vel, new_vel = reaper.ImGui_Checkbox(ctx, "Dynamic Velocity (Finger Touch)", pad.velocity_sensitive or false)
  if rv_vel then
    pad.velocity_sensitive = new_vel
    update_rs5k_velocity_sensitivity(selected_pad)
  end
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_SetTooltip(ctx, "OFF (Default / Full Level): Chops play at 100% original recorded volume (0.0 dB).\nON: Chop volume scales dynamically with pad hit pressure.")
  end
  
  local rv_choke, new_choke = reaper.ImGui_SliderInt(ctx, "Choke Group", pad.choke_group or 0, 0, 4)
  if rv_choke then
    pad.choke_group = new_choke
  end
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_SetTooltip(ctx, "0 = Polyphonic (No choke)\n1-4 = Choke Group: Triggering any pad in this group immediately cuts off all other pads in the same group (works for both Launchpad hardware and UI)")
  end
  
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Spacing(ctx)
  
  -- Hardware LED Color
  reaper.ImGui_PushFont(ctx, font_small, 10)
  reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "HARDWARE LED COLOR")
  reaper.ImGui_PopFont(ctx)
  
  local current_color_name = get_name_for_vel(pad.color_vel)
  reaper.ImGui_TextColored(ctx, get_color_for_vel(pad.color_vel), "[*] " .. current_color_name)
  reaper.ImGui_Spacing(ctx)
  
  local col_count = 0
  for _, c in ipairs(PALETTE) do
    if col_count > 0 and col_count % 7 ~= 0 then reaper.ImGui_SameLine(ctx) end
    
    local imgui_c = c.hex
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), imgui_c)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), brighten_color(imgui_c, 1.2))
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0xFFFFFFFF)
    
    local is_sel = (pad.color_vel == c.vel)
    if is_sel then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Border(), 0xFFFFFFFF)
      reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameBorderSize(), 2.0)
    end
    
    local btn_text = is_sel and "[x]##cv" .. c.vel or "##cv" .. c.vel
    if reaper.ImGui_Button(ctx, btn_text, 28, 20) then
      pad.color_vel = c.vel
      send_pad_color(selected_pad)
    end
    
    if is_sel then
      reaper.ImGui_PopStyleColor(ctx)
      reaper.ImGui_PopStyleVar(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx, 3)
    
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, c.name .. " (vel " .. c.vel .. ")")
    end
    col_count = col_count + 1
  end
  
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Spacing(ctx)
  
  -- Big Test Trigger Button
  local test_color = get_color_for_vel(pad.color_vel)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), test_color)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), brighten_color(test_color, 1.25))
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0xFFFFFFFF)
  if reaper.ImGui_Button(ctx, "[>] PLAY PAD (TRIGGER)", -1, 34) then
    trigger_pad_on(selected_pad)
  end
  if reaper.ImGui_IsItemDeactivated(ctx) and pad.mode == 1 then
    trigger_pad_off(selected_pad)
  end
  reaper.ImGui_PopStyleColor(ctx, 3)
  
  reaper.ImGui_Spacing(ctx)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x3A2020FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x8B2020FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x501010FF)
  if reaper.ImGui_Button(ctx, "[DEL] Delete Chop from Pad", -1, 28) then
    delete_pad_chop(selected_pad)
  end
  if reaper.ImGui_IsItemHovered(ctx) then
    reaper.ImGui_SetTooltip(ctx, "Deletes the chop audio and resets this pad")
  end
  reaper.ImGui_PopStyleColor(ctx, 3)
end

-- Top Bar: Presets & Connectivity
local function draw_top_bar()
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x1A1B22FF)
  local child_border = reaper.ImGui_ChildFlags_Borders and reaper.ImGui_ChildFlags_Borders() or 1
  
  if reaper.ImGui_BeginChild(ctx, "topbar", -1, 46, child_border) then
    reaper.ImGui_PushFont(ctx, font_main, 13)
    
    -- Logo
    reaper.ImGui_TextColored(ctx, 0xFF9500FF, "[*]")
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushFont(ctx, font_header, 15)
    reaper.ImGui_Text(ctx, "Little Things")
    reaper.ImGui_PopFont(ctx)
    
    reaper.ImGui_SameLine(ctx, 0, 16)
    
    -- Preset Name Input
    reaper.ImGui_SetNextItemWidth(ctx, 130)
    local rv_name, new_name = reaper.ImGui_InputText(ctx, "##preset_name", current_kit_name)
    if rv_name then current_kit_name = new_name end
    
    reaper.ImGui_SameLine(ctx)
    
    -- Save Preset Button
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x007AFFFF)
    if reaper.ImGui_Button(ctx, "[SAVE]") then
      save_kit(current_kit_name)
    end
    reaper.ImGui_PopStyleColor(ctx)
    
    reaper.ImGui_SameLine(ctx)
    
    -- Load Preset Dropdown
    reaper.ImGui_SetNextItemWidth(ctx, 140)
    if reaper.ImGui_BeginCombo(ctx, "##preset_combo", "[KIT] " .. current_kit_name) then
      local kits = list_kits()
      for _, kit in ipairs(kits) do
        local is_active = (kit.name == current_kit_name)
        if reaper.ImGui_Selectable(ctx, kit.name, is_active) then
          load_kit(kit.path)
        end
      end
      reaper.ImGui_EndCombo(ctx)
    end
    
    reaper.ImGui_SameLine(ctx)
    
    -- Master Volume
    reaper.ImGui_SetNextItemWidth(ctx, 70)
    local rv_mv, new_mv = reaper.ImGui_SliderDouble(ctx, "Vol", master_volume, 0.0, 1.0, "%.0f%%")
    if rv_mv then
      master_volume = new_mv
      for i = 1, NUM_PADS do update_rs5k_volume(i) end
    end
    
    reaper.ImGui_SameLine(ctx, 0, 10)
    
    -- SOLO CHOPS button
    local chops_soloed = false
    if rs5k_track then
      chops_soloed = (reaper.GetMediaTrackInfo_Value(rs5k_track, "I_SOLO") > 0.5)
    end
    if chops_soloed then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF9500FF)
      if reaper.ImGui_Button(ctx, "[SOLO ON]##solochops") then
        solo_lt_chops_track()
      end
      reaper.ImGui_PopStyleColor(ctx)
    else
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x333644FF)
      if reaper.ImGui_Button(ctx, "[SOLO CHOPS]##solochops") then
        solo_lt_chops_track()
      end
      reaper.ImGui_PopStyleColor(ctx)
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Solos the LT Chops track, muting all other project tracks immediately")
    end
    
    reaper.ImGui_SameLine(ctx, 0, 12)
    
    -- Launchpad Hardware Status & Device Selector
    local status_color = midi_connected and 0x34C759FF or 0xFF9500FF
    reaper.ImGui_TextColored(ctx, status_color, "[*]")
    reaper.ImGui_SameLine(ctx)
    
    local dev_display_name = midi_connected and (midi_out_name ~= "" and midi_out_name or "Launchpad OK") or "No Launchpad"
    if #dev_display_name > 18 then dev_display_name = dev_display_name:sub(1, 17) .. ".." end
    
    if reaper.ImGui_Button(ctx, dev_display_name .. "##midisel") then
      reaper.ImGui_OpenPopup(ctx, "midi_device_popup")
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Click to view/select Launchpad MIDI In & Out devices or auto-detect")
    end
    
    if reaper.ImGui_BeginPopup(ctx, "midi_device_popup") then
      reaper.ImGui_TextColored(ctx, 0xFF9500FF, "MIDI HARDWARE CONFIG")
      reaper.ImGui_Separator(ctx)
      
      if reaper.ImGui_MenuItem(ctx, "[AUTO-DETECT] Scan for Launchpad") then
        find_launchpad_devices()
      end
      
      reaper.ImGui_Separator(ctx)
      reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "OUTPUT (LEDs & Programmer Mode):")
      for _, dev in ipairs(available_midi_outs) do
        local is_sel = (dev.id == midi_out_device)
        if reaper.ImGui_MenuItem(ctx, dev.name .. (is_sel and " (Active)" or ""), nil, is_sel) then
          midi_out_device = dev.id
          midi_out_name = dev.name
          midi_connected = (midi_out_device >= 0)
          set_launchpad_programmer_mode(midi_out_device)
        end
      end
      
      reaper.ImGui_Separator(ctx)
      reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "INPUT (Pads & Hardware):")
      for _, dev in ipairs(available_midi_ins) do
        local is_sel = (dev.id == midi_in_device)
        if reaper.ImGui_MenuItem(ctx, dev.name .. (is_sel and " (Active)" or ""), nil, is_sel) then
          midi_in_device = dev.id
          midi_in_name = dev.name
        end
      end
      
      reaper.ImGui_EndPopup(ctx)
    end
    
    reaper.ImGui_SameLine(ctx)
    
    -- Send SysEx Programmer Mode Button
    if reaper.ImGui_Button(ctx, "[PROG]") then
      set_launchpad_programmer_mode(midi_out_device)
      set_status("Sent Programmer Mode SysEx to Launchpad", 0x34C759FF)
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Forces Novation Launchpad into Programmer Mode via SysEx and refreshes LEDs")
    end
    
    reaper.ImGui_SameLine(ctx)
    if reaper.ImGui_Button(ctx, "[SYNC]") then
      send_all_pad_colors()
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Syncs all pad colors to physical Launchpad LEDs")
    end
    
    reaper.ImGui_SameLine(ctx)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF2D55FF)
    if reaper.ImGui_Button(ctx, "[STOP ALL]") then
      stop_all_sounds()
    end
    reaper.ImGui_PopStyleColor(ctx)
    
    reaper.ImGui_PopFont(ctx)
    reaper.ImGui_EndChild(ctx)
  end
  
  reaper.ImGui_PopStyleColor(ctx)
end

-- Hero Section: INSTANT TIMELINE CHOP & RANGE CAPTURE
local function draw_chop_bar()
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x1E202BFF)
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 4.0)
  
  local child_border = reaper.ImGui_ChildFlags_Borders and reaper.ImGui_ChildFlags_Borders() or 1
  if reaper.ImGui_BeginChild(ctx, "chop_bar", -1, 106, child_border) then
    -- Line 1: Live Timeline status & Source Track controls
    local status_text, status_col = get_timeline_display_text()
    
    reaper.ImGui_PushFont(ctx, font_small, 11)
    reaper.ImGui_TextColored(ctx, status_col, status_text)
    reaper.ImGui_PopFont(ctx)
    
    reaper.ImGui_SameLine(ctx, 0, 14)
    
    -- Feature: MUTE SOURCE TRACK Button
    local src_tr = get_source_track()
    local is_src_muted = src_tr and (reaper.GetMediaTrackInfo_Value(src_tr, "B_MUTE") > 0.5)
    if is_src_muted then
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF3B30FF)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFF5B50FF)
      if reaper.ImGui_Button(ctx, "[TRACK MUTED - CLICK TO UNMUTE]##srcmute", 210, 22) then
        toggle_source_track_mute()
      end
      reaper.ImGui_PopStyleColor(ctx, 2)
    else
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x333644FF)
      reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x44485CFF)
      if reaper.ImGui_Button(ctx, "[MUTE SOURCE TRACK]##srcmute", 160, 22) then
        toggle_source_track_mute()
      end
      reaper.ImGui_PopStyleColor(ctx, 2)
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Mutes or unmutes the source track so original audio does not clash with Launchpad chops")
    end
    
    reaper.ImGui_SameLine(ctx, 0, 10)
    
    -- Feature: Cut the selected range out of the source track
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x501010FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x8B2020FF)
    if reaper.ImGui_Button(ctx, "[CUT RANGE FROM TRACK]##cutaudio", 180, 22) then
      silence_selected_range_on_source_track()
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Splits and deletes the audio in the selected time range from the source track (clears the timeline section)")
    end
    reaper.ImGui_PopStyleColor(ctx, 2)
    
    reaper.ImGui_SameLine(ctx, 0, 12)
    
    local rv_am, new_am = reaper.ImGui_Checkbox(ctx, "Auto-Mute Source", auto_mute_source_track)
    if rv_am then auto_mute_source_track = new_am end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Automatically mutes the source track after capturing so only Launchpad chops are heard")
    end
    
    reaper.ImGui_SameLine(ctx, 0, 10)
    
    local rv_adv, new_adv = reaper.ImGui_Checkbox(ctx, "Auto-advance", auto_advance)
    if rv_adv then auto_advance = new_adv end
    
    reaper.ImGui_Spacing(ctx)
    
    -- Line 2: The Core Chop Actions
    -- Mode toggle: Gate (Hold to play) vs One-Shot
    reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "Mode:")
    reaper.ImGui_SameLine(ctx)
    local is_gate = (default_chop_mode == 1)
    if is_gate then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF9500FF) end
    if reaper.ImGui_Button(ctx, "Gate##defgate", 50, 28) then
      default_chop_mode = 1
    end
    if is_gate then reaper.ImGui_PopStyleColor(ctx) end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Gate: Pad stops sounding as soon as released")
    end
    
    reaper.ImGui_SameLine(ctx, 0, 4)
    local is_oneshot = (default_chop_mode == 2)
    if is_oneshot then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF9500FF) end
    if reaper.ImGui_Button(ctx, "1-Shot##defoneshot", 60, 28) then
      default_chop_mode = 2
    end
    if is_oneshot then reaper.ImGui_PopStyleColor(ctx) end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "One-Shot: Pad plays the entire chop and stops at the end")
    end
    
    reaper.ImGui_SameLine(ctx, 0, 14)
    
    -- 1. Big Send Range to Selected Pad Button
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x34C759FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0x4CD964FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0x248A3DFF)
    reaper.ImGui_PushFont(ctx, font_main, 13)
    
    local send_label = string.format("[SEND] RANGE TO PAD #%d", selected_pad)
    if reaper.ImGui_Button(ctx, send_label, 220, 28) then
      send_range_to_selected_pad()
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Captures the timeline range to Pad #" .. selected_pad .. " and triggers it!")
    end
    
    reaper.ImGui_PopFont(ctx)
    reaper.ImGui_PopStyleColor(ctx, 3)
    
    reaper.ImGui_SameLine(ctx, 0, 14)
    
    -- 2. Multi-slice button: Chop into N pads
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF9500FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), 0xFFA726FF)
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), 0xE65100FF)
    reaper.ImGui_PushFont(ctx, font_main, 13)
    
    local chop_n_label = string.format("[CHOP] Into %d Pads", chop_division)
    if reaper.ImGui_Button(ctx, chop_n_label, 160, 28) then
      chop_range_into_n_pads(chop_division)
    end
    if reaper.ImGui_IsItemHovered(ctx) then
      reaper.ImGui_SetTooltip(ctx, "Slices the timeline range into " .. chop_division .. " pads evenly across the Launchpad!")
    end
    
    reaper.ImGui_PopFont(ctx)
    reaper.ImGui_PopStyleColor(ctx, 3)
    
    reaper.ImGui_SameLine(ctx, 0, 6)
    
    -- Quick division selector
    local divisions = { 8, 16, 32, 64 }
    for _, div in ipairs(divisions) do
      local is_sel = (chop_division == div)
      if is_sel then reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0xFF9500FF) end
      if reaper.ImGui_Button(ctx, tostring(div) .. "##div" .. div, 30, 28) then
        chop_division = div
      end
      if is_sel then reaper.ImGui_PopStyleColor(ctx) end
      reaper.ImGui_SameLine(ctx, 0, 3)
    end
    
    reaper.ImGui_SameLine(ctx, 0, 10)
    
    -- Clear Pads button
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x333644FF)
    if reaper.ImGui_Button(ctx, "Clear All Pads", 100, 28) then
      clear_all_pads()
    end
    reaper.ImGui_PopStyleColor(ctx)
    
    reaper.ImGui_EndChild(ctx)
  end
  
  reaper.ImGui_PopStyleVar(ctx)
  reaper.ImGui_PopStyleColor(ctx)
end

--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------

local function main_loop()
  if not imgui_ready then return end
  
  update_flash_timers()
  poll_hardware_midi_input()
  
  local flags = reaper.ImGui_WindowFlags_NoCollapse()
  
  -- Dark theme (100% solid, fully opaque)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_WindowBg(), 0x121316FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBg(), 0x18191EFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_TitleBgActive(), 0x22242DFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_FrameBg(), 0x22242DFF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_SliderGrab(), 0xFF9500FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_CheckMark(), 0xFF9500FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_PopupBg(), 0x1A1B22FF)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Separator(), 0x2E303CFF)
  
  reaper.ImGui_PushFont(ctx, font_main, 13)
  
  reaper.ImGui_SetNextWindowBgAlpha(ctx, 1.0)
  reaper.ImGui_SetNextWindowSize(ctx, 1080, 800, reaper.ImGui_Cond_FirstUseEver())
  
  local visible, open = reaper.ImGui_Begin(ctx, SCRIPT_NAME, true, flags)
  
  if visible then
    draw_top_bar()
    reaper.ImGui_Spacing(ctx)
    
    draw_chop_bar()
    reaper.ImGui_Spacing(ctx)
    reaper.ImGui_Separator(ctx)
    reaper.ImGui_Spacing(ctx)
    
    local avail_w = reaper.ImGui_GetContentRegionAvail(ctx)
    local inspector_w = 310
    local grid_w = avail_w - inspector_w - 16
    
    local pad_spacing = 5
    local pad_size = math.floor((grid_w - pad_spacing * (GRID_COLS - 1)) / GRID_COLS)
    if pad_size < 40 then pad_size = 40 end
    if pad_size > 72 then pad_size = 72 end
    
    local child_border = reaper.ImGui_ChildFlags_Borders and reaper.ImGui_ChildFlags_Borders() or 1
    
    -- Left: Pad Grid
    if reaper.ImGui_BeginChild(ctx, "grid_panel", grid_w, -1, child_border) then
      reaper.ImGui_PushFont(ctx, font_small, 10)
      reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "LAUNCHPAD MINI MK3 - 8x8 PAD MATRIX")
      reaper.ImGui_PopFont(ctx)
      reaper.ImGui_Spacing(ctx)
      
      for r = 0, GRID_ROWS - 1 do
        for c = 0, GRID_COLS - 1 do
          local idx = r * GRID_COLS + c + 1
          if c > 0 then reaper.ImGui_SameLine(ctx, 0, pad_spacing) end
          draw_pad_button(idx, pad_size)
        end
      end
      
      reaper.ImGui_Spacing(ctx)
      
      -- Footer info & status
      reaper.ImGui_PushFont(ctx, font_small, 10)
      reaper.ImGui_TextColored(ctx, 0xFF9500FF, "[>]")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "Click pad to play")
      reaper.ImGui_SameLine(ctx, 0, 14)
      reaper.ImGui_TextColored(ctx, 0x007AFFFF, "[+]")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "Right-click or Drag-drop WAV")
      reaper.ImGui_SameLine(ctx, 0, 14)
      reaper.ImGui_TextColored(ctx, 0x34C759FF, "[*]")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_TextColored(ctx, 0x8E8E93FF, "Hardware LED Sync")
      reaper.ImGui_PopFont(ctx)
      
      reaper.ImGui_Spacing(ctx)
      
      -- Status message
      reaper.ImGui_PushFont(ctx, font_small, 10)
      reaper.ImGui_TextColored(ctx, 0x636366FF, "Status: ")
      reaper.ImGui_SameLine(ctx)
      reaper.ImGui_TextColored(ctx, status_color_hex, status_msg)
      reaper.ImGui_PopFont(ctx)
      
      reaper.ImGui_EndChild(ctx)
    end
    
    -- Right: Inspector Panel
    reaper.ImGui_SameLine(ctx, 0, 16)
    
    reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ChildBg(), 0x1A1B22FF)
    if reaper.ImGui_BeginChild(ctx, "inspector", inspector_w, -1, child_border) then
      draw_inspector()
      reaper.ImGui_EndChild(ctx)
    end
    reaper.ImGui_PopStyleColor(ctx)
    
    reaper.ImGui_End(ctx)
  end
  
  reaper.ImGui_PopFont(ctx)
  reaper.ImGui_PopStyleColor(ctx, 8)
  
  if open then
    reaper.defer(main_loop)
  else
    stop_all_sounds()
    clear_all_leds()
  end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function init()
  init_pads()
  find_launchpad_devices()
  if not init_imgui() then return end
  ensure_rs5k_track_ready()
  reaper.defer(main_loop)
end

init()

-- @description Setup Multi-Out VST
-- @author PatrickMartin
-- @version 1.0beta
-- @changelog
--   06/25/2019
--   Initial
-- @link Forum thread https://forum.cockos.com/showthread.php?p=2151021
-- @screenshot After https://imgur.com/a/DrX33aS
-- @about
--   ## Setup Multi-Out VST
--
--   ### Overview
--   This script adds a VST on a new track and then:
--   [list]
--   [*]Creates # of MIDI tracks you specify. Each track input is set to the MIDI device you specify, with each track configured to send data to the VST on a separate MIDI channel (1-16 and 16 for all tracks beyond #16)
--   [*]Creates same # of audio tracks, each configured to receive audio from the VST track on one of its stereo outputs (1/2, 3/4, 5/6, etc)
--   [*]Names the tracks according to abbreviations you specify, or using the full VST name if no abbreviations are specified
--   [*]Creates folder tracks for the MIDI and audio channels
--   [*]Colors the MIDI and audio tracks to RGB values you specify
--   [/list]
--
--
--   ### Dependencies
--   None
--
--   ### Configuration
--
--   ```
--   --name of the VST
--   --(use name only, i.e. "Omnisphere" not "VSTi: Omnisphere (Spectrasonics) (8 out)"
--   uc_vst_name = "Omnisphere"
--
--   --# of stereo outs on the VST
--   --This # of audio/MIDI track pairs will be created.
--   --  * each MIDI track will receive on all channels but send on only 1
--   --  * tracks above #16 will send on channel 16
--   --2X this # of channels will be created on the instrument track
--   uc_vst_stereo_outs = 8
--
--   --name of MIDI input device or nil to use all inputs
--   uc_MIDI_input_device_name = "masterkey 49"
--
--   --Optional: Color for MIDI tracks {R, G, B} or {}
--   uc_track_color_MIDI = {255, 204, 204}
--
--   --Optional: Color for audio tracks {R, G, B} or {}
--   uc_track_color_audio = {229, 255, 204}
--
--   --Optional: Track name abbreviations {audio, MIDI}
--   --Example: {"0S-Out", "OS_MID"} would name tracks as follows:
--   --  'OS-MID' for folder, 'OS-MID1', 'OS-MID2' ..., 'OS-Out1', 'OS-Out2', ... for child tracks
--   --Set to {} to use VST name
--   uc_track_name_abbreviations = {"O-Out", "O-MID"}
--   ```

-- API CONSTANTS ------------------------------------------------------------

c_msgbox_type_ok = 0
c_action_insert_virtual_inst_on_new_track = 40701
c_folder_depth_normal = 0
c_folder_depth_parent = 1
c_folder_depth_last_innermost = -1
c_folder_compact_normal = 0
c_folder_compact_small = 1
c_folder_compact_tiny = 2
c_track_fx_bypass = 0
c_track_fx_show_hidechain = 0
c_track_fx_show_showchain = 1
c_track_fx_show_hidefloating = 2
c_track_fx_show_showfloating = 0
c_fx_instantiate_if_none = 1
c_track_fx_enable = 1
c_track_armed = 1
c_track_unarmed = 0
c_track_recinput_midi = 4096
c_track_recinput_none = -1
c_track_recmode_none = 2
c_track_recmode_stereo_out = 2
c_track_recmode_midi = 4
c_track_recmode_stereo_out = 1
c_track_recmon_off = 0
c_track_recmon_normal = 1
c_track_recmon_tape = 2
c_send_category_send = 0
c_send_category_receive = -1
c_send_category_hardware = 1
c_send_rcv_all_channels = 0

CHANNEL_MASK = 31
INPUT_OFFSET = 5
INPUT_MASK = 2016
VIRTUAL_KEYBOARD = 62
ALL_INPUTS = 63
ALL_CHANNELS = 0

-------------------------------------------------------- END OF API CONSTANTS

-- GLOBAL VARIABLES ---------------------------------------------------------

gc_script_display_name = "Setup Multi-Out VST"
gv_MIDI_inputs = {}

----------------------------------------------------- END OF GLOBAL VARIABLES

-- USER CONFIG AREA ---------------------------------------------------------

console = false -- true/false: display debug messages in the console

--name of the VST 
--(use name only, i.e. "Omnisphere" not "VSTi: Omnisphere (Spectrasonics) (8 out)"
uc_vst_name = "Omnisphere"

--# of stereo outs on the VST
--This # of audio/MIDI track pairs will be created.
--  * each MIDI track will receive on all channels but send on only 1
--  * tracks above #16 will send on channel 16
--2X this # of channels will be created on the instrument track
uc_vst_stereo_outs = 8

--name of MIDI input device or nil to use first available device
uc_MIDI_input_device_name = "masterkey 49"

--Optional: Color for MIDI tracks {R, G, B} or {}
uc_track_color_MIDI = {255, 204, 204}

--Optional: Color for audio tracks {R, G, B} or {}
uc_track_color_audio = {229, 255, 204}

--Optional: Track name abbreviations {audio, MIDI}
--Example: {"0S-Out", "OS_MID"} would name tracks as follows:
--  OS-MID1, OS-MID2 ... OS-Out1, OS-Out2, ...
--Set to {} to use VST name 
uc_track_name_abbreviations = {"O-Out", "O-MID"}
----------------------------------------------------- END OF USER CONFIG AREA

--Extract channel and input values from I_RECINPUT value
function UNPACK_I_RECINPUT(value)
  local channel = value & CHANNEL_MASK
  local input = (value & INPUT_MASK) >> INPUT_OFFSET
  --Msg("UNPACK_I_RECINPUT: channel=" .. channel .. ", input=" .. input)
  return channel, input
end

--Pack channel and input into value for I_RECINPUT
function PACK_I_RECINPUT(channel, input)
  local ret = c_track_recinput_midi | ((input << INPUT_OFFSET) | channel)
  --Msg("PACK_I_RECINPUT(channel=" .. channel .. ", input=" .. input .. "): " ..ret)
  return ret
end

--returns table containing MIDI input indexes/names
function GetMIDIInputs()
  local ret = {}
  count = reaper.GetNumMIDIInputs()
  for i = 0, count - 1 do
    retval, device_name = reaper.GetMIDIInputName(i, '')
    --Msg("MIDI Input " .. i .. "=" .. device_name)
    ret[string.lower(device_name)] = i
  end
  return ret
end

--Adds VST to a track, returns track and fxid
function AddVST(vst_name, track, input_device, outputs)
  if not track then
    --create a new track for it
    track = CreateTrackAtEnd(vst_name)
  end  
  
  --Add VST
  local fxid = reaper.TrackFX_AddByName(track, vst_name, false, c_fx_instantiate_if_none)
  
  --Enable FX on the track
  reaper.TrackFX_SetEnabled(track, fxid, 1)
  
  --Set number of channels
  reaper.SetMediaTrackInfo_Value(track, "I_NCHAN", outputs * 2)
  
  --Set input to none
  reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", c_track_recinput_none)
  
  --Set rec mode for midi input
  reaper.SetMediaTrackInfo_Value(track, "I_RECMODE", c_track_recmode_midi)
  
  --Arm track
  --reaper.SetMediaTrackInfo_Value(track, "I_RECARM", c_track_armed)
  
  --Turn off master send
  reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 0)
  
  --Turn on record monitoring
  reaper.SetMediaTrackInfo_Value(track, "I_RECMON", c_track_recmon_normal)
 
  return track, fxid
end

--Creates new track at end of track list
function CreateTrackAtEnd(name)
  local next_idx = reaper.GetNumTracks()
  reaper.InsertTrackAtIndex(next_idx, true)
  local track = reaper.GetTrack(0, next_idx)
  reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
  return track
end

--Returns index of named MIDI input
function GetMIDIInputByName(name)
  --Normalize name to lower case
  name = string.lower(name)
  local ret = gv_MIDI_Inputs[name] or -1
  --Msg("GetMIDIInputByName(" .. name .. ")=".. ret)
  return ret
end

--Sets track input to MIDI device/channel
function SetTrackMIDIInput(track, input_name, channel)
  local input_idx = ALL_INPUTS

  --if input name was spcified
  if input_name then
    --Try to get the input index from the name
    input_idx = GetMIDIInputByName(input_name)
    if input_idx == -1 then    
      --default to input all inputs
      input_idx = ALL_INPUTS
    end
  end
  newval = PACK_I_RECINPUT(channel, input_idx)
  reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", newval)
end

function ConfigMIDISendTrack(send_track, rcv_track, rcv_channel, dest_channel, input_device)
  --Set MIDI input device for instrument track
  SetTrackMIDIInput(send_track, input_device, ALL_CHANNELS)
  
  --Set rec mode for midi input
  reaper.SetMediaTrackInfo_Value(send_track, "I_RECMODE", c_track_recmode_midi)
  
  --Turn on record monitoring
  reaper.SetMediaTrackInfo_Value(send_track, "I_RECMON", c_track_recmon_normal)
  
  --Add a send to the instrument track
  local send_idx = reaper.CreateTrackSend(send_track, rcv_track)
  
  --Set send and receive channels for the send
  local midi_flags = (dest_channel << 5) | rcv_channel;
  reaper.SetTrackSendInfo_Value(send_track, c_send_category_send, send_idx, "I_MIDIFLAGS", midi_flags)
end

function ConfigAudioReceiveTrack(vst_track, audio_track, index)
  --Add a send from the instrument track
  local send_idx = reaper.CreateTrackSend(vst_track, audio_track)
  --Send from appropriate stereo out on VST
  reaper.SetTrackSendInfo_Value(vst_track, c_send_category_send, send_idx, "I_SRCCHAN", index)
end

function CreateFolderTrack(name)
    --Insert track at end
    local count = reaper.GetNumTracks()
    reaper.InsertTrackAtIndex(count, false)
    --Get a reference to it
    local track = reaper.GetTrack(0, count)
    if track then
      --Set the name
      reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
      --Disable the input
      reaper.SetMediaTrackInfo_Value(track, "I_RECINPUT", c_track_recinput_none)
      --Rec mode none
      reaper.SetMediaTrackInfo_Value(track, "I_RECMODE ", c_track_recmode_none)
      --Make it a folder
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", c_folder_depth_parent)
    end
    return track
end

function CalcMIDIChannel(index)
  if (index + 1) > 16 then
    return 16
  else
    return (index + 1)
  end
end

function InsertTracks(vst_track, qty, create_folder, for_midi)
  local folder = nil
  
  --Set track color, if specified
  local track_color = nil
  if #uc_track_color_MIDI > 0 then
    track_color = for_midi and uc_track_color_MIDI or uc_track_color_audio
  end
  
  --Use track name abbrevations if provided, otherwise use name of VST
  local name = ""
  if #uc_track_name_abbreviations > 0 then
    name = for_midi and uc_track_name_abbreviations[2] or uc_track_name_abbreviations[1]
  else
    name = for_midi and uc_vst_name .. " MIDI" or uc_vst_name .. " Out"
  end
  
  if create_folder then
    folder = CreateFolderTrack(name)
    if track_color then
      SetTrackColor(folder, track_color)
    end
  end
  
  --Create tracks
  local next_idx = reaper.GetNumTracks()
  local next_stereo_out_idx = 0
  for i = 1, qty, 1 do
    --Insert track
    reaper.InsertTrackAtIndex(next_idx, true)
    
    --Get a reference to it
    local track = reaper.GetTrack(0, next_idx)
    
    --Set the track name
    local track_name = name .. "" .. i
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", track_name , true)    
    
    --Set track color, if specified
    if track_color then
      SetTrackColor(track, track_color)
    end
    
    --Configure for MIDI or audio
    if for_midi then
      --limit channel values to 1-16. if index > 16, we start over at 1
      local send_channel = CalcMIDIChannel(i)
      ConfigMIDISendTrack(track, vst_track, c_send_rcv_all_channels, send_channel, uc_MIDI_input_device_name)
    else
      --VST outs are stereo pairs, 0 = 1/2, 2=3/4, etc
      ConfigAudioReceiveTrack(vst_track, track, next_stereo_out_idx)
    end 
    
    --If we've created a folder and this is the last track
    if (create_folder and i == qty) then
      --Make it last in the folder
      reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", c_folder_depth_last_innermost)
    end
    
    --Set next insert index
    next_idx = reaper.GetNumTracks()
    --Set next stereo out index
    next_stereo_out_idx = next_stereo_out_idx + 2
  end
  return folder
end

-- Display a message in the console for debugging
function Msg(value)
  if console then
    reaper.ShowConsoleMsg(tostring(value) .. "\n")
  end
end

function SetFolderCompact(folder, compact)
  reaper.SetMediaTrackInfo_Value(folder, "I_FOLDERCOMPACT", compact)
end

function SetTrackColor(track, rgb)
  local color = reaper.ColorToNative(rgb[1], rgb[2], rgb[3])
  reaper.SetTrackColor(track, color)
end

function ValidateMIDIInput(name)
  if GetMIDIInputByName(name) == -1 then
    reaper.ShowMessageBox("Input '" .. name .. "' not found, defaulting to all inputs", gc_script_display_name, c_msgbox_type_ok)
  end
end

-- Main function
function main()
  --Build global table of MIDI inputs
  gv_MIDI_Inputs = GetMIDIInputs()
  
  --if MIDI input device specified, validate it
  ValidateMIDIInput(uc_MIDI_input_device_name)
  
  --Add VST on a new track
  vst_track, fxid = AddVST(uc_vst_name, nil, uc_MIDI_input_device_name, uc_vst_stereo_outs)
  
  if vst_track and fxid > -1 then
    --Insert MIDI tracks
    midi_folder = InsertTracks(vst_track, uc_vst_stereo_outs, true, true)
    
    --Insert stereo tracks
    audio_folder = InsertTracks(vst_track, uc_vst_stereo_outs, true, false)
    
    --Compact the folders
    if midi_folder then
      SetFolderCompact(midi_folder, c_folder_compact_tiny)
    end
    if audio_folder then
      SetFolderCompact(audio_folder, c_folder_compact_tiny)
    end
  else
    reaper.ShowMessageBox("Unable to create new instrument track", gc_script_display_name, c_msgbox_type_ok)
  end
end


-- INIT ---------------------------------------------------------------------

-- Here: your conditions to avoid triggering main without reason.

reaper.PreventUIRefresh(1)

reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

main()

reaper.Undo_EndBlock(gc_script_display_name, -1) -- End of the undo block. Leave it at the bottom of your main function.

reaper.UpdateArrange()

reaper.PreventUIRefresh(-1)
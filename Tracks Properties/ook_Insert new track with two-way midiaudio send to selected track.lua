-- @description Insert new track with two-way midi/audio send to selected track
-- @author ook
-- @version 0.1
-- @screenshot https://i.imgur.com/yblMNqN.gif
-- @about
--   # Insert new track with two-way midi/audio send to selected track
--
--   Mostly helpful to users of multi-instrument VSTs like Kontakt or EW PLAY.
--
--   **For this to work, you need to enable  Project Settings -> "Allow feedback in routing"**. Personally, I also disable *Master Send* on the multi-instrument track.
--
--   1. Select your Kontakt/multi-instrument track and execute this action. 
--   2. A new track is created
--   3. New track gets a new MIDI send to your multi-instrument
--   4. Multi-instrument track gets a new audio send to your new track
--
--   Except a few edge cases, now your new track will behave like it's actually hosting the instrument! You can put effects on it, create sends, etc. One limitation: you cannot folder these new tracks beneath the multi-instrument track due to the way feedback works in Reaper.

local TRACK_INFO_RECV_CATEGORY = -1
local TRACK_INFO_SEND_CATEGORY = 0
local TRACK_INFO_MIDIFLAGS_DISABLED = 4177951
local TRACK_INFO_MIDIFLAGS_ALL_CHANS = 0
local TRACK_INFO_AUDIO_SRC_DISABLED = -1
local REAPER_CURRENT_PROJECT = 0
local MESSAGE_BOX_OK = 0

function get_send_flags_dest(flags)
  return flags >> 5
end

function get_send_flags_src(flags)
  return flag & ((1 << 5) - 1) -- flag & 0x11111
end

function create_send_flags(src_chan, dest_chan)
  return (dest_chan << 5) | src_chan
end

function new_midi_send(src, dest)
  local dest_recv_count = reaper.GetTrackNumSends(dest, TRACK_INFO_RECV_CATEGORY)
  local dest_highest_midi_recv = 0
  for i = 0, (dest_recv_count - 1) do
    local midi_flags = reaper.GetTrackSendInfo_Value(dest, TRACK_INFO_RECV_CATEGORY, i, "I_MIDIFLAGS")
    if midi_flags == TRACK_INFO_MIDIFLAGS_DISABLED then
      goto continue
    end
    
    local midi_dest = get_send_flags_dest(midi_flags)
    if midi_dest > dest_highest_midi_recv then
      dest_highest_midi_recv = midi_dest
    end
    
    ::continue::
  end
  
  local midi_send = reaper.CreateTrackSend(src, dest)
  local new_midi_flags = create_send_flags(0, dest_highest_midi_recv + 1)
  reaper.SetTrackSendInfo_Value(src, TRACK_INFO_SEND_CATEGORY, midi_send, "I_MIDIFLAGS", new_midi_flags)
  reaper.SetTrackSendInfo_Value(src, TRACK_INFO_SEND_CATEGORY, midi_send, "I_SRCCHAN", TRACK_INFO_AUDIO_SRC_DISABLED)
  return midi_send
end

function new_audio_send(src, dest) 
  local src_send_count = reaper.GetTrackNumSends(src, TRACK_INFO_SEND_CATEGORY)
  local src_highest_audio_send = -2
  for i = 0, (src_send_count - 1) do
    local src_chan = reaper.GetTrackSendInfo_Value(src, TRACK_INFO_SEND_CATEGORY, i, "I_SRCCHAN")
    if src_chan == TRACK_INFO_AUDIO_SRC_DISABLED then
      goto continue
    end
    
    if src_chan > src_highest_audio_send then
      src_highest_audio_send = src_chan
    end
    
    ::continue::
  end
  
  local audio_send = reaper.CreateTrackSend(src, dest)
  local send_audio_src = src_highest_audio_send + 2
  reaper.SetTrackSendInfo_Value(src, TRACK_INFO_SEND_CATEGORY, audio_send, "I_SRCCHAN", send_audio_src)
  reaper.SetTrackSendInfo_Value(src, TRACK_INFO_SEND_CATEGORY, audio_send, "I_MIDIFLAGS", TRACK_INFO_MIDIFLAGS_DISABLED)
  return audio_send
end

function act(track) 
  reaper.InsertTrackAtIndex(reaper.GetNumTracks(), true)
  local new_track = reaper.GetTrack(REAPER_CURRENT_PROJECT, reaper.GetNumTracks() - 1)
  
  new_midi_send(new_track, track)
  new_audio_send(track, new_track)
end

local sel_track = reaper.GetSelectedTrack(REAPER_CURRENT_PROJECT, 0)
if sel_track then
  act(sel_track)
end

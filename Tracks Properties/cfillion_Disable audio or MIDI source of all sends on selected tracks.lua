-- @description Disable audio or MIDI source of all sends on selected tracks
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Disable audio source of all sends on selected tracks.lua
--   [main] . > cfillion_Disable MIDI source of all sends on selected tracks.lua
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

local UNDO_STATE_TRACKCFG = 1
local SENDS = 0

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local audio = script_name:match('audio')
local midi  = script_name:match('MIDI')
assert(audio or midi, 'invalid filename')

reaper.Undo_BeginBlock()

for ti = 0, reaper.CountSelectedTracks(0) - 1 do
  local track = reaper.GetSelectedTrack(0, ti)

  for si = 0, reaper.GetTrackNumSends(track, SENDS) - 1 do
    if audio then
      reaper.SetTrackSendInfo_Value(track, SENDS, si, 'I_SRCCHAN', -1)
    end

    if midi then
      local flags = reaper.GetTrackSendInfo_Value(track, SENDS, si, 'I_MIDIFLAGS')
      reaper.SetTrackSendInfo_Value(track, SENDS, si, 'I_MIDIFLAGS', flags | 0x1F)
    end
  end
end

reaper.Undo_EndBlock(script_name, UNDO_STATE_TRACKCFG)

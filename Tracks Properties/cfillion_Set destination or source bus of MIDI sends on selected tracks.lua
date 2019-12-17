-- @description Set destination or source bus of MIDI sends on selected tracks
-- @author cfillion
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 1.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 2.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 3.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 4.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 5.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 6.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 7.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 8.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 9.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 10.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 11.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 12.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 13.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 14.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 15.lua
--   [main] . > cfillion_Set destination of MIDI sends on selected tracks to bus 16.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 1.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 2.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 3.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 4.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 5.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 6.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 7.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 8.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 9.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 10.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 11.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 12.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 13.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 14.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 15.lua
--   [main] . > cfillion_Set source of MIDI sends on selected tracks to bus 16.lua
-- @donation https://paypal.me/cfillion

local CAT_SENDS = 0
local UNDO_STATE_TRACKCFG = 1

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local offset = scriptName:match('source') and 14 or 22
local mask = 0x1f << offset
local bus = tonumber(scriptName:match('bus (%d+)'))
assert(bus and bus >= 0 and bus <= 16, 'invalid filename')

local function selectedTracks()
  local i = -1
  return function()
    i = i + 1
    return reaper.GetSelectedTrack(0, i)
  end
end

reaper.Undo_BeginBlock()

for track in selectedTracks() do
  for send = 0, reaper.GetTrackNumSends(track, CAT_SENDS) - 1 do
    local flags = reaper.GetTrackSendInfo_Value(track, CAT_SENDS, send, 'I_MIDIFLAGS')
    flags = flags & ~mask
    flags = flags | (bus << offset)
    reaper.SetTrackSendInfo_Value(track, CAT_SENDS, send, 'I_MIDIFLAGS', flags)
  end
end

reaper.Undo_EndBlock(scriptName, UNDO_STATE_TRACKCFG)

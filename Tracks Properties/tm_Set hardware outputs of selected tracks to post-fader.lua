-- @description Set hardware outputs of selected tracks to post-fader
-- @author TM
-- @version 1.0
-- @donation https://www.paypal.me/cfillion
-- @about All credits go to cfillion for his original script and to nofish for helping me editing it.

local self = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')
local UNDO_STATE_TRACKCFG = 1
local HARDWARE_OUT = 1 -- > 0
local postfader=0
local prefx=1
local postfx=3

local seltracks = reaper.CountSelectedTracks()
if seltracks < 1 then return reaper.defer(function() end) end

reaper.Undo_BeginBlock()

for ti=0, seltracks-1 do
  local track = reaper.GetSelectedTrack(0, ti)
  for si=0, reaper.GetTrackNumSends(track, HARDWARE_OUT)-1 do
    reaper.SetTrackSendInfo_Value(track, 1, si, "I_SENDMODE", postfader)
  end
end

reaper.Undo_EndBlock(self, UNDO_STATE_TRACKCFG)

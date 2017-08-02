-- @description Remove hardware outputs of selected tracks
-- @version 1.0
-- @author cfillion
-- @website http://forum.cockos.com/showthread.php?t=189761
-- @donation https://www.paypal.me/cfillion

local self = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')
local UNDO_STATE_TRACKCFG = 1
local HARDWARE_OUT = 1 -- > 0

local seltracks = reaper.CountSelectedTracks()
if seltracks < 1 then return reaper.defer(function() end) end

reaper.Undo_BeginBlock()

for ti=0, seltracks-1 do
  local track = reaper.GetSelectedTrack(0, ti)
  for si=0, reaper.GetTrackNumSends(track, HARDWARE_OUT)-1 do
    reaper.RemoveTrackSend(track, HARDWARE_OUT, 0)
  end
end

reaper.Undo_EndBlock(self, UNDO_STATE_TRACKCFG)

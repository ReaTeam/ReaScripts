-- @description Remove hardware outputs of selected tracks
-- @author cfillion
-- @version 1.0.1
-- @changelog Optimize processing in projects with high track counts
-- @link http://forum.cockos.com/showthread.php?t=189761
-- @donation https://reapack.com/donate

local SCRIPT_NAME = select(2, reaper.get_action_context()):match('([^/\\_]+).lua$')
local UNDO_STATE_TRACKCFG = 1
local HARDWARE_OUT = 1 -- > 0

local seltracks = reaper.CountSelectedTracks()
if seltracks < 1 then return reaper.defer(function() end) end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

for ti = 0, seltracks - 1 do
  local track = reaper.GetSelectedTrack(nil, ti)
  for si = 0, reaper.GetTrackNumSends(track, HARDWARE_OUT) - 1 do
    reaper.RemoveTrackSend(track, HARDWARE_OUT, 0)
  end
end

reaper.Undo_EndBlock(SCRIPT_NAME, UNDO_STATE_TRACKCFG)
reaper.PreventUIRefresh(-1)

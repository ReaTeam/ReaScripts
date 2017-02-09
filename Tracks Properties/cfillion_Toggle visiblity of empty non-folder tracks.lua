-- @description Toggle visiblity of empty non-folder tracks
-- @version 1.0
-- @author cfillion
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=187651
-- @donation https://www.paypal.me/cfillion

local UNDO_STATE_TRACKCFG = 1
local empty_tracks, setVisible = {}, 0

for ti=0,reaper.CountTracks()-1  do
  local track = reaper.GetTrack(0, ti)

  local fx_count   = reaper.TrackFX_GetCount(track)
  local item_count = reaper.CountTrackMediaItems(track)
  local env_count  = reaper.CountTrackEnvelopes(track)
  local depth      = reaper.GetMediaTrackInfo_Value(track, "I_FOLDERDEPTH")
  local is_armed   = reaper.GetMediaTrackInfo_Value(track, "I_RECARM")

  if fx_count + item_count + env_count + math.max(depth, 0) + is_armed == 0 then
    local mcpVis = reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINMIXER')
    local tcpVis = reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINMIXER')
    if mcpVis + tcpVis == 0 then
      setVisible = 1
    end

    table.insert(empty_tracks, track)
  end
end

if #empty_tracks == 0 then return end

reaper.Undo_BeginBlock()

for i,track in ipairs(empty_tracks) do
  reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', setVisible)
  reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', setVisible)
end

local pointName = ({reaper.get_action_context()})[2]:match('([^/\\_]+).lua$')
reaper.Undo_EndBlock(pointName, UNDO_STATE_TRACKCFG)

reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

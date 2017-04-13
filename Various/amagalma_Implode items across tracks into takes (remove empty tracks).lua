-- @description amagalma_Script: Implode items across tracks into takes (remove empty tracks)
-- @author amagalma
-- @version 1.0
-- @about
--   # Script: Implodes items across tracks into takes, removes empty tracks and inherits their height
--

-- @link http://stash.reaper.fm/30479/amagalma_Implode%20items%20across%20tracks%20into%20takes%20%28remove%20empty%20tracks%29.gif


local reaper = reaper

function Main()
  reaper.Main_OnCommand(40297,0) -- Track: Unselect all tracks
  local item_cnt = reaper.CountSelectedMediaItems(0)
  if item_cnt > 0 then
    for i = 0, item_cnt-1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      reaper.SetTrackSelected(reaper.GetMediaItemTrack(item), true)
    end
    reaper.Main_OnCommand(40438, 0) -- Take: Implode items across tracks into takes
    local track_cnt = reaper.CountSelectedTracks(0)
    local total_h = 0
    for i = track_cnt-1, 0, -1  do
      local track = reaper.GetSelectedTrack(0, i)
      local tcp_h = reaper.GetMediaTrackInfo_Value(track, "I_WNDH")
      total_h = total_h + tcp_h
      if reaper.CountTrackMediaItems(track) == 0 then
        reaper.DeleteTrack(track)
      end
    end
      local track = reaper.GetSelectedTrack(0,0)
      reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", total_h)
  end
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
Main()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock("Implode items across tracks into takes (remove empty tracks)", -1)
reaper.TrackList_AdjustWindows(0)
reaper.UpdateArrange()

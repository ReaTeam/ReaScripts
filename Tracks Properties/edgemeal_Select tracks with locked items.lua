-- @description Select tracks with locked items
-- @author Edgemeal
-- @version 1.0
-- @link Forum https://forum.cockos.com/showthread.php?p=2209858
-- @donation Donate https://www.paypal.me/Edgemeal

reaper.Undo_BeginBlock(0)
reaper.PreventUIRefresh(1)
reaper.Main_OnCommand(40297, 0) -- Track: Unselect all tracks
local track_count = reaper.CountTracks()
for i = 0, track_count - 1 do
  local track = reaper.GetTrack(0, i)
  local item_count = reaper.CountTrackMediaItems(track)
  for j = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, j)
     if reaper.GetMediaItemInfo_Value(item, 'C_LOCK') == 1 then
      reaper.SetTrackSelected(track, true)
      break
    end
  end
end
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)
reaper.Undo_EndBlock('Select tracks with locked items', -1)
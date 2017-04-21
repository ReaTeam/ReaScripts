-- @version 1.0
-- @author Mordi
-- @changelog
--  This script will take the selected items' active take
--  and rename it to whatever the track it is on is called.
--
--  Made by Mordi, Dec 2016

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Print function
function print(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Loop through all selected items
for i = 0, reaper.CountSelectedMediaItems()-1 do
  
  -- Get item
  item = reaper.GetSelectedMediaItem(0, i)
  
  -- Get active take of item
  active_take = reaper.GetActiveTake(item)
    
  -- Get track
  track = reaper.GetMediaItem_Track(item)
  
  -- Get track name
  retval, track_name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', "", false)
  
  -- Apply new name
  reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', track_name, true)
end

-- End undo-block
reaper.Undo_EndBlock2(0,"Script: Set selected items active takes name to track name",-1)

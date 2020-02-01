-- @description Random track order for selected tracks
-- @author Will Develop
-- @version 1.0
-- @link
--   Forum thread https://forum.cockos.com/showthread.php?p=2237863
--   My Website https://will-records.tk/site/php/home.php
-- @about
--   # Random track order for selected tracks by Will Develop
--
--   ## INFO:
--
--   - ReaScript Name: Random track order for selected tracks
--   - Author: Will Develop 
--   - Website: https://www.will-records.tk
--   - REAPER: 6.02
--  
--   ## DESCRIPTION:
--
--   This script randomized the order for the selected tracks. Useful for Blind-Tests
--    
--   ## INTRODUCTION:
--      
--   1. Select the tracks.
--   2. Run the Script

 --Lua Shuffle-Function
function shuffle(array)
  for i = #array, 2, -1 do
    local j = math.random(i)
    array[i], array[j] = array[j], array[i]
  end
  return array
end



function main()

  --Count the selected tracks and create a array
  count_sel_tracks = reaper.CountSelectedTracks(0)
  track_number_array = {}
  -------------------------------------------------
  
  
  --Show this Error-Message, if no track selected
  if not reaper.GetSelectedTrack(0,0) then
    reaper.ReaScriptError("No tracks selected.")
  end
  ----------------------------------------------
  
  
  --Read the track data into the array
  for k = 1, count_sel_tracks, 1 do
  
    track =   reaper.GetSelectedTrack(0,k-1)
    ok,  track_number_array[k] = reaper.GetTrackStateChunk(track, "", 0, true) 
  end
  -------------------------------------------------------------------------------
  
  shuffle(track_number_array) --calls the shuffle function
  
  
  --Rearranged the tracks
  for x = 1,count_sel_tracks, 1 do
    track = reaper.GetSelectedTrack(0, x -1)
    reaper.SetTrackStateChunk(track, track_number_array[x], true)
  end
  
  track_number_array = {} --clear the array
  
  
end --end of the main-Function

main()

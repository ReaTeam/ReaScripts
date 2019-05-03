-- @description Insert new track (inherit color from parent)
-- @author Mordi
-- @version 1.0
-- @about
--   # Insert new track (inherit color from parent)
--
--   Uses reaper's native "Insert new track" action, and colors the new track based on its parent track. If the track has no parent, no color will be applied.

SCRIPT_NAME = "Insert new track (inherit color from parent)"

-- Message function
function Msg(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Add new track
reaper.Main_OnCommand(40001, 0)

-- Get number of selected tracks
selNum = reaper.CountSelectedTracks(0)

-- Loop through each selected track
for i = 1, selNum do

  -- Get selected track
  track = reaper.GetSelectedTrack(0, i-1)
  
  -- Get parent track
  parent = reaper.GetMediaTrackInfo_Value(track, "P_PARTRACK")
  
  -- Skip if track has no parent
  if parent ~= 0.0 then
    
    -- Get color from parent track
    color = reaper.GetTrackColor(parent)
      
    -- Apply color to selected track
    reaper.SetTrackColor(track, color)
    
  end
end

-- End undo-block
reaper.Undo_EndBlock2(0,SCRIPT_NAME,-1)

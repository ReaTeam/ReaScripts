-- @version 1.0
-- @author Mordi
-- @changelog
--  This script works the same way as the $namecount rendering wildcard.
--  It takes all selected takes and counts the ones that are named the same,
--  adding the increasing count to the take name.
--
--  It will be formatted like this: "takename_1"
--
--  Made by Mordi, Dec 2016

-- Begin undo-block
reaper.Undo_BeginBlock2(0)

-- Print function
function print(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Get number of selected items
item_count = reaper.CountSelectedMediaItems()

-- Create array used for storing take name
new_take_name = {}
for i = 0, item_count-1 do
  new_take_name[i] = ""
end

-- Loop through all selected items
for i = 0, item_count-1 do
  
  -- Get name of take
  take_name = reaper.GetTakeName(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i)))
  
  -- Reset counter variable
  count = 1
  
  -- Loop through all previous items
  for n = 0, i-1 do
  
    -- Check if take names match
    if take_name == reaper.GetTakeName(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, n))) then
      count = count + 1
    end
    
  end
  
  -- Store new name in array
  new_take_name[i] = take_name .. "_" .. tostring(count)
end

-- Loop through each item again
for i = 0, item_count-1 do
  
  -- Get active take
  active_take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))
  
  -- Apply new name
  reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', new_take_name[i], true)

end

-- End undo-block
reaper.Undo_EndBlock2(0,"Script: Add count of same-named takes to selected takes names",-1)

-- @description Namecount from x
-- @version 1.0
-- @author Mordi
-- @about
--  You have Fart 01.wav and Fart 02.wav in your sound effects folder, and now
--  you've recorded twenty new farts, so they will need to be counted from 03
--  to 22. Name your takes "Fart" and then use this script.
--
--  It will be formatted like this: "takename 99"
--
--  Made by Mordi, Aug 2018

-- Print function
function print(str)
  reaper.ShowConsoleMsg(tostring(str) .. "\n")
end

-- Get number of selected items
item_count = reaper.CountSelectedMediaItems()

if item_count == 0 then
  print("Namecount from x: No items selected.")
else
  -- Get x-value
  confirmed, x_str = reaper.GetUserInputs("Namecount from x", 1, "Enter number to count from.", "")
  x = tonumber(x_str)
  
  -- Check if input was cancelled
  if confirmed then
  
    -- Begin undo-block
    reaper.Undo_BeginBlock2(0)
    
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
      count = x
      
      -- Loop through all previous items
      for n = 0, i-1 do
      
        -- Check if take names match
        if take_name == reaper.GetTakeName(reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, n))) then
          count = count + 1
        end
        
      end
      
      -- Convert to 00 format
      if (count < 10) then
        str = "0" .. tostring(count)
      else
        str = tostring(count)
      end
      
      -- Store new name in array
      new_take_name[i] = take_name .. " " .. str
    end
    
    -- Loop through each item again
    for i = 0, item_count-1 do
      
      -- Get active take
      active_take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, i))
      
      -- Apply new name
      reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', new_take_name[i], true)
    
    end
    
    -- End undo-block
    reaper.Undo_EndBlock2(0,"Script: Add count from x to selected items active takes names",-1)
    
  end
  
end

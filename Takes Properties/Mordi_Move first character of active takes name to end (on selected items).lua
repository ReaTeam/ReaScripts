-- @description Move first character of active takes name to end (on selected items)
-- @version 1.0
-- @author Mordi
-- @about
--  This script will take the first character in the name of
--  the active take of the selected items and move it to the end
--  of the name.
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
  
  -- Get name of take
  take_name = reaper.GetTakeName(active_take)
  
  -- Generate new name
  new_name = string.sub(take_name, 2) .. string.sub(take_name, 1, 1)
  
  -- Apply new name
  reaper.GetSetMediaItemTakeInfo_String(active_take, 'P_NAME', new_name, true)
  
  -- Print some info
  --print(take_name .. " - New name -> " .. new_name)
end

-- End undo-block
reaper.Undo_EndBlock2(0,"Script: Move first character of take name to end",-1)

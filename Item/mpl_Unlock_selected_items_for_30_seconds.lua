-- Michael Pilyavskiy: Unlock Selected Items for 30 seconds

time = 30 -- time in seconds you need for pause

function unlock_item() -- store item_t table
 item_t = {} -- table for selected items
 itemcount = reaper.CountSelectedMediaItems(0)
 if itemcount ~= nil then
  for i = 1, itemcount,1 do
   item = reaper.GetSelectedMediaItem(0, i-1)
   if item ~= nil then   
    reaper.SetMediaItemInfo_Value(item, "C_LOCK", 0)
    reaper.UpdateItemInProject(item)
    table.insert(item_t, i, item)    
   end
  end 
 end 
end


function timer() 
 time2 = reaper.time_precise()
 time_con = true
 if time_con == true then
  if time2 - time1 < time then
   
   time_con = true
   reaper.defer(timer)
   else
   time_con = false   
  end
 end  
end


function lock_item() 
 for i = 1, #item_t, 1 do
   local item = item_t[i] -- get item from table    
   reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
   reaper.SetMediaItemInfo_Value(item, "C_LOCK", 1)
   reaper.UpdateItemInProject(item)
   end  
end

-- PERFORM:

-- 1. Do Some action
--
unlock_item()

-- 2. Wait for defined time
time1 = reaper.time_precise()
timer()

-- 3. Do second Action
reaper.atexit(lock_item) -- also stop running script


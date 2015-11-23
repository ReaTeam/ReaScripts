-- Michael Pilyavskiy: Unlock all items for 30 seconds

time = 30 -- time in seconds you need for pause

function unlock_item() -- store item_t table
 item_t = {} -- table for selected items
 item_sel_t = {}
 item_lock_t = {}
 itemcount = reaper.CountMediaItems(0)
 for i = 1, itemcount,1 do
  item = reaper.GetMediaItem(0, i-1)
  if item ~= nil then   
   bool_sel = reaper.IsMediaItemSelected(item)
   lock = reaper.GetMediaItemInfo_Value(item, "C_LOCK")
   reaper.SetMediaItemInfo_Value(item, "C_LOCK", 0) 
   table.insert(item_lock_t, i, lock)
   table.insert(item_sel_t, i, bool_sel)
   table.insert(item_t, i, item)    
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
   local bool = item_sel_t[i]
   if bool == true then
    bool_01 = 1
    else
    bool_01 = 0
   end 
   item_lock = item_lock_t[i]
   reaper.SetMediaItemInfo_Value(item, "B_UISEL", bool_01)
   reaper.SetMediaItemInfo_Value(item, "C_LOCK", item_lock)
   end 
 reaper.UpdateArrange()
end

-- PERFORM:

-- 1. Do Some action
unlock_item()
reaper.UpdateArrange()

-- 2. Wait for defined time
time1 = reaper.time_precise()
timer()

-- 3. Do second Action
reaper.atexit(lock_item) -- also stop running script

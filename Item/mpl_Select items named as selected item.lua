item = reaper.GetSelectedMediaItem(0, 0)
if item ~= nil then
  take = reaper.GetActiveTake(item)
  takename0 = reaper.GetTakeName(take)
  if take ~= nil then
    itemcount = reaper.CountMediaItems(0)
    if itemcount ~= nil then  
     for i = 1, itemcount do
       item1 = reaper.GetMediaItem(0, i-1)     
       if item1 ~= nil then    
         take1 = reaper.GetActiveTake(item1)
         if take1 ~= nil then
           takename = reaper.GetTakeName(take1)      
           if  takename == takename0 then
             reaper.SetMediaItemSelected(item1, true)       
           end
         end
       end  
     end -- for
    end 
  end
end  
reaper.UpdateArrange()  

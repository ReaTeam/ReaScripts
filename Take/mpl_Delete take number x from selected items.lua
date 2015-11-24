reaper.Undo_BeginBlock()

  guids_t = {}
  retval, user_take_num_s = reaper.GetUserInputs("Delete take number x from selected items", 1, "Take number", "")
  if user_take_num_s ~= nil and user_take_num_s ~= "" then
    user_take_num = tonumber(user_take_num_s)
    count_sel_items = reaper.CountSelectedMediaItems(0)
    if count_sel_items ~= nll then
      for i = 1, count_sel_items do  
        item = reaper.GetSelectedMediaItem(0, i-1);
        item_guid = reaper.BR_GetMediaItemGUID(item)
        table.insert(guids_t, item_guid)
      end -- loop
    end -- count sel    
  end -- retval
  
  if guids_t ~= nil then
    for i = 1, #guids_t do
      guid_temp = guids_t[i]
      reaper.Main_OnCommand(40289,0) -- unselect all items
      item = reaper.BR_GetMediaItemByGUID(0, guid_temp)
      reaper.SetMediaItemInfo_Value(item, "B_UISEL", 1)
      takes_count = reaper.CountTakes(item)
      
      if user_take_num <= takes_count then
      
        act_take = reaper.GetActiveTake(item)
        user_take = reaper.GetTake(item, user_take_num-1)
        
        if act_take == user_take then
          reaper.Main_OnCommand(40129,0) -- delete active take
         else
          reaper.SetActiveTake(user_take)
          reaper.Main_OnCommand(40129,0) -- delete active take
          reaper.SetActiveTake(act_take)
        end
      
      end -- if user_take_num <= takes_count
    end -- table loop
  end -- if table exists  
  
reaper.UpdateArrange()  
reaper.Undo_EndBlock("Delete take number x from selected items",0)  


name_script =  "Replace sources for selected items using user defined references with matching"

 
  
 --------------------------------------------------------------------------------------
function GET_new_items()  
  items_new_t = {} 
  sel_items_count = reaper.CountSelectedMediaItems(0)
  if sel_items_count ~= nil then  
   for i = 1, sel_items_count do
     item = reaper.GetSelectedMediaItem(0, i-1)     
     if item ~= nil then
       take = reaper.GetActiveTake(item)
       if take ~= nil then           
         takename = reaper.GetTakeName(take) -- "blablabla.mp3"      
          takename_clear, ext = takename:match("([^.]+).([^.]+)")
          take_guid = reaper.BR_GetMediaItemTakeGUID(take)
          src = reaper.GetMediaItemTake_Source(take)
          src_file = reaper.GetMediaSourceFileName(src, "")          
          takestr = take_guid.."///"..takename_clear.."///"..src_file
          table.insert(items_new_t, i, takestr)
          table.remove(items_new_t, i+1) 
       end --take ~= nil    
     end -- item ~= nil then     
   end --i = 1, sel_items_count
 end -- sel_items_count ~= nil   
end -- func        
     
 --------------------------------------------------------------------------------------
 
function GET_old_items()  
  items_t = {} 
  sel_items_count = reaper.CountSelectedMediaItems(0)
  if sel_items_count ~= nil then  
   for i = 1, sel_items_count do
     item = reaper.GetSelectedMediaItem(0, i-1)     
     if item ~= nil then
       take = reaper.GetActiveTake(item)
       if take ~= nil then           
         takename = reaper.GetTakeName(take) -- "blablabla.mp3"      
          takename_clear, ext = takename:match("([^.]+).([^.]+)")
          take_guid = reaper.BR_GetMediaItemTakeGUID(take)
          src = reaper.GetMediaItemTake_Source(take)
          src_file = reaper.GetMediaSourceFileName(src, "")          
          takestr = take_guid.."///"..takename_clear.."///"..src_file
          table.insert(items_t, i, takestr)
          table.remove(items_t, i+1) 
       end --take ~= nil    
     end -- item ~= nil then     
   end --i = 1, sel_items_count
 end -- sel_items_count ~= nil   
end -- func    
 
 --------------------------------------------------------------------------------------  
 
  function replace_source(take_guid, src_file_new)    
    temp_src = reaper.PCM_Source_CreateFromFile(src_file_new)             
    take = reaper.SNM_GetMediaItemTakeByGUID(0, take_guid)        
    reaper.SetMediaItemTake_Source(take, temp_src)
  end
  
 --------------------------------------------------------------------------------------  
 
  function replace()    
    retval1, retvals_csv = 
     reaper.GetUserInputs("", 3, "Match first characters, Match last characters, Is new name contains old?", "0,0,Y")
     match_first, match_last, is_old_in_new = retvals_csv:match("([^,]+),([^,]+),([^,]+)")
     
     if is_old_in_new == nil then is_old_in_new = "N" end
     if match_first == nil then match_first = 0 end
     if match_last == nil then match_last = 0 end
     match_first = tonumber(match_first)
     match_last = tonumber(match_last)
     
    for i = 1, #items_t, 1 do
      take_string = items_t[i]
      take_guid, takename_clear, src_file = take_string:match("([^///]+)///([^///]+)///([^///]+)")
      for j = 1, #items_new_t, 1 do
        take_string_new = items_new_t[j]
        take_guid_new, takename_clear_new, src_file_new = take_string_new:match("([^///]+)///([^///]+)///([^///]+)")
        
        if is_old_in_new == "Y" then
          st_find, end_find = string.find(takename_clear_new, takename_clear)          
          if st_find ~= nil and end_find ~= nil then
            temp = string.sub(takename_clear, 0, match_first)
            temp2 = string.sub(takename_clear_new, 0, match_first)
            if temp == temp2 then replace_source(take_guid, src_file_new)  end   
            temp3 = string.sub(takename_clear, -match_last)
            temp4 = string.sub(takename_clear_new, -match_last)
            if temp3 == temp4 then replace_source(take_guid, src_file_new)  end                     
          end          
        end 
        if is_old_in_new == "N" then
           st_find, end_find = string.find(takename_clear_new, takename_clear)          
           if st_find == nil and end_find == nil then       
            temp = string.sub(takename_clear, 0, match_first)
            temp2 = string.sub(takename_clear_new, 0, match_first)
            if temp == temp2 then replace_source(take_guid, src_file_new)  end   
            temp3 = string.sub(takename_clear, -match_last)
            temp4 = string.sub(takename_clear_new, -match_last)
            if temp3 == temp4 then replace_source(take_guid, src_file_new)  end  
           end 
        end
      end
    end    
    cond = 0
  end
  
 --------------------------------------------------------------------------------------  
 
function MOUSE_click_under_gui_rect (object_coord_t, offset)   
  if offset == nil then offset = 0 end
  x = object_coord_t[1+offset]
  y = object_coord_t[2+offset]
  w = object_coord_t[3+offset]
  h = object_coord_t[4+offset]
  if LB_DOWN == 1
   and mx > x
   and mx < x + w
   and my > y 
   and my < y + h then       
    return true
  end  
end   

 -------------------------------------------------------------------------------------- 
 function MOUSE_get()
  mx, my = gfx.mouse_x, gfx.mouse_y  
  LB_DOWN = gfx.mouse_cap&1  
  RB_DOWN = gfx.mouse_cap&2 
   
  if MOUSE_click_under_gui_rect(but_get) == true then GET_old_items() end
  if MOUSE_click_under_gui_rect(but_get2) == true then GET_new_items() end 
  if MOUSE_click_under_gui_rect(but_replace) == true then replace() end 
  if MOUSE_click_under_gui_rect(but_about) == true then reaper.ShowMessageBox(about, "About this script", 0) end 
  if MOUSE_click_under_gui_rect(but_exit) == true then cond = 0 end
     
 end
 
 --------------------------------------------------------------------------------------
  
 function GUI_button(xywh, name,fontsize)
   gfx.x = 0
   gfx.y = 0
   gfx.roundrect(xywh[1],xywh[2],xywh[3],xywh[4], 1)
   gfx.setfont(1,"Arial", fontsize)
   strlen = gfx.measurestr(name)
   gfx.x = xywh[1] + (xywh[3]-strlen)/2
   gfx.y = xywh[2] + (xywh[4]-fontsize)/2
   gfx.drawstr(name)
 end 
 
 --------------------------------------------------------------------------------------
 
 function GUI_checkbox(xywh, name,fontsize, is_checked)
   gfx.x = 0
   gfx.y = 0
   gfx.roundrect(xywh[1],xywh[2],xywh[3],xywh[4], 1)
   gfx.setfont(1,"Arial", fontsize)
   
   gfx.x, gfx.y = xywh[1] + 4,xywh[2] -2  
   
   if is_checked == true then gfx.drawstr("x") end
   
   strlen = gfx.measurestr(name)
   gfx.x = xywh[1] + 20
   gfx.y = xywh[2] + (xywh[4]-fontsize)/2
   gfx.drawstr(name)
   
 end 
 
 --------------------------------------------------------------------------------------
 
  function GUI_info(table, xywh)
   
   if table ~= nil then
     for i = 1, #table do
       gfx.x = xywh[1]
       gfx.y = xywh[2] + fontsize * (i-1)
       gfx.drawstr(table[i])
     end
   end
  end 
  
 --------------------------------------------------------------------------------------
 
 function GUI_define_obj()
 fontsize = 16
 main_w, main_h = 900, 400
 but_get = {10, 10 , 105, 30}
 items_place = {115, but_get[2], 200, #items_t*fontsize}
 
 but_get2 = {10, 150 , 105, 30}
 items_place2 = {115, but_get2[2], 200, #items_new_t*fontsize}
 
 but_replace = {10, 270 , 105, 30} 
 
 but_about = {10, 305 , 105, 30} 
 
 but_exit = {10, 340 , 105, 30} 
 end
 
 --------------------------------------------------------------------------------------
 
 function GUI_draw()   
   gfx.x = 0
   gfx.y = 0
   gfx.init(name_script, main_w, main_h)
   
   GUI_button(but_get, "Set old items", fontsize)   
   GUI_info(items_t, items_place)
   
   GUI_button(but_get2, "Set new items", fontsize)
   GUI_info(items_new_t, items_place2)  
   
   GUI_button(but_replace, "Replace sources", fontsize) 
   
   GUI_button(but_exit, "Exit", fontsize) 
 end
 
 --------------------------------------------------------------------------------------
 
 function run()
  if cond == 1 then  
    GUI_define_obj()    
    MOUSE_get()
    GUI_draw()        
    gfx.update()
    reaper.UpdateArrange()
    reaper.defer(run)
   else
    reaper.atexit(gfx.quit) 
  end  
 end
 
 --------------------------------------------------------------------------------------
 
 cond = 1
 items_t = {}
 items_new_t = {} 
 --------------------------------------------------------------------------------------
 
run()

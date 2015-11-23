------  Michael Pilyavskiy Quantize tool  ----

fontsize_menu_name  = 16

vrs = "1.7"
 
changelog =                   
[===[

   ==========
   Changelog:
   ==========   
18.11.2015  1.7 build 3 - need REAPER 5.03+ SWS 2.8.1+
          GUI
            optimized performance by blitting display
            font fix for OSX users
          Bugfixes
            Disabled REAPER/SWS version checking on start
            Fixed negative ref.points
13.10.2015  1.6 build 5  - need REAPER 5.03+ SWS 2.8.1+
          Improvements
            improved mouse tracking, thanks to spk77!
            Help button redirected to Cockos Wiki related page
          Bugfixes
            properly adding last stretch marker on items with different takerate
          
          Option to stretch area around stretch marker (HIDDEN, have a lot of bugs)
            
01.10.2015  1.5 build 4  - need REAPER 5.03+ SWS 2.8.1+
          New
            Show QT in actions info line (main menu right item)
            Added undo points to some operations
          Improvements
            highlight grid and swing slider under mouse cursor
            stretch markers restore/quantize code improvements
            space key pass through and run Transport:Play/Stop
            prevent opening left menu and type swing window when drag swing slider
          Bugfixes
            fixed wrong groove name
            fixed properly 'Groove' path finding both on OSX and Windows
            fixed add null stretch markers when quantize/restore
            fixed new restore button doesn`t work
            Save as rgt groove works also on OSX
          Performance
            'reference grid' generated only where destination points placed +-1bar
              
30.09.2015  1.4 build 9 - need REAPER 5.03+ SWS 2.8.1+
          New
            additional buttons simulate right click for tablet users
            check for SWS version on startup (win only)
          Bugfixes
            disabled get grid on start could make script buggy on start
            fixed loop sourced item stretch markers restore/quantize
          Improvements
            font size param. moved to the top for OSX users who have problems with gui
            
29.09.2015  1.3 build 10  - need REAPER 5.03+ SWS 2.8.1+
          New
            rightclick on user groove open REAPER\Grooves list
            Check for REAPER compatibility on startup
            GUI - options window deprecated and splitted to 3 menus on main page
            GUI - options sliders dynamically shown when relevant
            Store current groove to midi item (notes length = 120ppq)
            Match items positions to ref.points
            Ctrl+LMB click add/subtract value from swing/gravity slider depending on position within slider
          Improvements          
            right click on gravity - type value in ms  
            apply slider position more closer to mouse cursor
          Performance
            Option to disable display (reduce CPU usage a lot in some situations)
            Improved GUI updates
          Bugfixes
            fixed stretch markers quantize for loop sourced items  
            
          Presets temporatory disabled
          
14.09.2015  1.2  build 8
          New
            middle mouse button click on apply slider to set strength value
            right click on custom grid select/form project grid
            added reference actions:
                save as rgt groove (moved from display)
            added quantize actions:
                reset stored str.markers
                reset stored str..markers at time selection
                
          Improvements:
            project grid is default, form points on start                        
            strength slider shows its value
            
          Bugfixes:
            fix wrong formed points in pattern mode for project with different tempo
            fixed preset system dont store dest str.marker settings
            display issues
            grid, swing reference issues
        
13.09.2015  1.1  build 3      
          New: 
            get reference str.marker from selected item/time selection of selected item
            quantize str.marker from selected item/time selection of selected item
            User Groove (import .rgt files for SWS Fingers Groove Tool)
            rmb click on display save current groove to rgt (SWS Fingers Groove Tool) file
            swing value support decimals (only if user type)
            store and recall preset - \REAPER\Scripts\mpl_Quantize_Tool_settings.txt
            set strength/swing/grid via CC and OSC with
              mpl_Quantize_Tool_set_strength.lua
              mpl_Quantize_Tool_set_swing.lua (beetween 0-100%)
              mpl_Quantize_Tool_set_grid.lua
              check in http://github.com/MichaelPilyavskiy/ReaScripts/tree/master/Tools

          Improvements:
            cutted options button (to prevent trigger options page)
            count ref/dest objects
            disable set 'Use Gravity' when choosing destination stretch markers
            Changing global/local mode form relevant mode points and leave previously got points
            Every menu changing also form ref.points or quantize objects to quick preview

          Performance:
            removed display bar lines. -10% CPU
            UpdateArrange() moved to main quantize function: 10%-20% less CPU, depending on how project is big

          Bugfixes: 
            incorrect project/custom grid values
            swing grid tempo bug, project grid tempo bug
            -1 tick midi notes position when quantize/restore
            display issues
            error if project is empty

          Info:
            improved syntax of info strings, thanks to heda!
            donate button
            manual updated           
            
28.08.2015  1.0 
            Public release     
            
23.06.2015  0.01 'swing items' idea
    
 ]===]

about = 'Quantize tool by Michael Pilyavskiy (Russia, Oryol)'..'\n'..'Version '..vrs..'\n'..
[===[    
    ========
    Contacts
    ========
   
            Soundcloud - http://soundcloud.com/mp57
            PromoDJ -  http://pdj.com/michaelpilyavskiy
            VK -  http://vk.com/michael_pilyavskiy         
            GitHub -  http://github.com/MichaelPilyavskiy/ReaScripts
            ReaperForum - http://forum.cockos.com/member.php?u=70694
  
 ]===]
 --------------------
 ------- Code -------
 --------------------
 ---------------------------------------------------------------------------------------------------------------  
 function extract_table(table)
    a = table[1]
    b = table[2]
    c = table[3]
    d = table[4]
    return a,b,c,d
 end

    ---------------------------------------------------------------------------------------------------------------  
 function test_var(test, test2)  
   if test ~= nil then  reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(test) end
   if test2 ~= nil then reaper.ShowConsoleMsg("\n") reaper.ShowConsoleMsg(test2) end
 end


 ---------------------------------------------------------------------------------------------------------------  
  function open_URL(url)    
    if OS=="OSX32" or OS=="OSX64" then
      os.execute("open ".. url)
     else
      os.execute("start ".. url)
    end
  end
  
 
 ---------------------------------------------------------------------------------------------------------------  
 function math.round(num, idp)
   local mult = 10^(idp or 0)
   return math.floor(num * mult + 0.5) / mult
 end 
       
 ---------------------------------------------------------------------------------------------------------------   
 function DEFINE_default_variables()    
     
      snap_mode_values_t = {0,1} 
      pat_len_values_t = {1,0,0}
      pat_edge_values_t = {0,1}
      use_vel_values_t = {0,1} 
      sel_notes_mode_values_t = {0,1}
      sm_rel_ref_values_t = {1,0}
      sm_timesel_ref_values_t = {1,0}
      
      snap_area_values_t = {0,1}
      snap_dir_values_t = {0,1,0}
      swing_scale_values_t = {0,1}
      sel_notes_mode_values_at = {0,1}   
      sm_timesel_dest_values_t = {1,0}
      enable_display_t={1}
      sm_is_transients_t={0}  
   
   
   
   restore_button_state = false
   if snap_mode_values_t[2] == 1 then  quantize_ref_values_t = {0, 0, 0, 0, 0, 0, 0} else quantize_ref_values_t = {0, 0, 0, 0} end
   quantize_dest_values_t = {0, 0, 0, 0}
    
   count_reference_item_positions = 0
   count_reference_sm_positions = 0
   count_reference_ep_positions = 0
   count_reference_notes_positions = 0
   
   count_dest_item_positions = 0
   count_dest_sm_positions = 0
   count_dest_ep_positions = 0
   count_dest_notes_positions = 0
   
   grid_value = 0
   swing_value = 0.25
   strenght_value = 1
   last_strenght_value_s = ""
   gravity_value = 0.5
   gravity_mult_value = 0.3 -- second
   use_vel_value = 0
   if swing_scale_values_t[1]&1 then swing_scale = 1.0 end
   if swing_scale_values_t[2]&1 then swing_scale = 0.5 end
   pattern_len = 1
   quantize_ref_menu_groove_name = "UserGroove"
 end
 
 --------------------------------------------------------------------------------------------------------------- 
  
 function DEFINE_dynamic_variables() 
   --GUI
   apply_slider_xywh_t = {x_offset+40, y_offset1+gui_offset+5+enable_display_t[1]*40, main_w-gui_offset*2-40, heigth3-enable_display_t[1]*40}  
   restore_button_xywh_t = {x_offset, apply_slider_xywh_t[2],35,apply_slider_xywh_t[4]}
     
   quantize_ref_menu_xywh_t = {x_offset+gui_offset+options_button_width, y_offset, 
     main_w/2-options_button_width-gui_offset*1.5-x_offset, y_offset1-y_offset-(use_vel_values_t[1]*30)}
   quantize_dest_menu_xywh_t = {main_w/2+gui_offset/2, y_offset, 
     main_w/2-options_button_width-gui_offset*1.5-x_offset, y_offset1-y_offset-(snap_area_values_t[1]*30)}  
   --Other  
     
   max_object_position, first_measure, last_measure, cml, first_measure_dest_time, last_measure_dest_time, last_measure_dest  = GET_project_len()
   
  --[[ timesig_error = GET_timesigs()
   if timesig_error == nil and cml_com == 4 or timesig_error == false and cml_com == 4 then timesig_error = false end]]
   
   playpos = reaper.GetPlayPosition() 
   editpos = reaper.GetCursorPosition()   
   
   timesel_st, timesel_end = reaper.GetSet_LoopTimeRange2(0, false, true, 0, 1, true)
   
   grid_beats, grid_string, project_grid_measures, project_grid_cml, grid_time, grid_bar_time = GET_grid()
   
   if pat_len_values_t[1] == 1 then  pattern_len = 1 end -- bar  
   if pat_len_values_t[2] == 1 then  pattern_len = 2 end 
   if pat_len_values_t[3] == 1 then  pattern_len = 4 end 
   
   ---------------------
   -- count reference --
   ---------------------
   if snap_mode_values_t[1] == 1 then
     if ref_points_t ~= nil then count_ref_positions = #ref_points_t else count_ref_positions = 0 end
    else
     if ref_points_t2 ~= nil then count_ref_positions = #ref_points_t2 else count_ref_positions = 0 end
   end  
   quantize_ref_menu_item_name = "Items" 
   quantize_ref_menu_sm_name = "Stretch markers" 
   quantize_ref_menu_ep_name = "Envelope points" 
   quantize_ref_menu_notes_name = "Notes" 
   
   if custom_grid_beats_i == 0 or custom_grid_beats_i == nil then  
       quantize_ref_menu_grid_name = "project grid: "..grid_string 
     else quantize_ref_menu_grid_name = "custom grid: "..grid_string end
       
   quantize_ref_menu_swing_name = "swing grid "..math.round(swing_value*100, 2).."%"   
         
   if snap_mode_values_t[2] == 1 then        
     quantize_ref_menu_names_t = {"Reference points ("..count_ref_positions..") :", quantize_ref_menu_item_name, quantize_ref_menu_sm_name,
                                quantize_ref_menu_ep_name, quantize_ref_menu_notes_name, quantize_ref_menu_groove_name,
                                quantize_ref_menu_grid_name,
                                quantize_ref_menu_swing_name}
    else
     quantize_ref_menu_names_t = {"Reference points ("..count_ref_positions..") :", quantize_ref_menu_item_name, quantize_ref_menu_sm_name,
                                quantize_ref_menu_ep_name, quantize_ref_menu_notes_name}
   end
   -----------------------                             
   -- count destination --                             
   -----------------------
   if dest_points_t ~= nil then count_dest_positions = #dest_points_t else count_dest_positions = 0 end
   quantize_dest_menu_item_name = "Items" 
   quantize_dest_menu_sm_name = "Stretch markers" 
   quantize_dest_menu_ep_name = "Envelope points" 
   quantize_dest_menu_notes_name = "Notes" 
   
   quantize_dest_menu_names_t = {"Objects to quantize ("..count_dest_positions..") :",quantize_dest_menu_item_name, quantize_dest_menu_sm_name,
                                quantize_dest_menu_ep_name, quantize_dest_menu_notes_name} 
   
   
   if restore_button_state == false then 
     apply_bypass_slider_name = "Apply quantize "..math.ceil(strenght_value*100).."%" end
 end 
   
 --------------------------------------------------------------------------------------------------------------- 
 
 function DEFINE_default_variables_GUI()
  if OS == "OSX32" or OS == "OSX64" then fontsize_menu_name = fontsize_menu_name - 3 end
  gui_offset = 5
  x_offset = 5
  y_offset = 5
  y_offset1 = 240
  width1 =  400
  heigth1 = 100
  heigth2 = 20  
  heigth3= 100
  heigth4= 80
  beetween_menus1 = 5 -- hor
  beetween_items1 = 10 -- hor
  beetween_menus2 = 5 -- vert
  beetween_items2 = 5 -- vert
  beetween_items3 = 20 -- vert
  options_button_width = 25
  
  
  -- gfx.vars --
  gui_help = 0.0  
  font = "Arial"
  --fontsize_menu_name  = 16
  fontsize_menu_item = fontsize_menu_name-1
  itemcolor1_t = {0.4, 1, 0.4}
  itemcolor2_t = {0.5, 0.8, 1}
  frame_alpha_default = 0.05
  frame_alpha_selected = 0.1
  
  editpos_rgba_t = {0.5, 0, 0, 0.6}
  playpos_rgba_t = {0.5, 0.5, 0, 0.8}
  bar_points_rgba_t = {1,1,1,0.5}
  
  ref_points_rgba_t = {0, 1, 0, 0.5}
  dest_points_rgba_t = {0.1, 0.6, 1, 1}  
    
  display_end = 1 -- 0..1
  display_start = 0 -- 0..1
  
  update_display = true
  
  -- main menu windows
  quantize_ref_menu_xywh_t = {x_offset+gui_offset+options_button_width, y_offset, 
    main_w/2-options_button_width-gui_offset*1.5-x_offset, y_offset1-y_offset-(use_vel_values_t[1]*30)}
  quantize_dest_menu_xywh_t = {main_w/2+gui_offset/2, y_offset, 
    main_w/2-options_button_width-gui_offset*1.5-x_offset, y_offset1-y_offset-(snap_area_values_t[1]*30)}
  
  -- sliders
  use_vel_slider_xywh_t = {quantize_ref_menu_xywh_t[1], quantize_ref_menu_xywh_t[2]+quantize_ref_menu_xywh_t[4]-25,
   quantize_ref_menu_xywh_t[3],25}
   
  gravity_slider_xywh_t = {quantize_dest_menu_xywh_t[1], quantize_dest_menu_xywh_t[2]+quantize_dest_menu_xywh_t[4]+5-30,
   quantize_dest_menu_xywh_t[3]-25,25}  
  
  -- display
  display_rect_xywh_t = {x_offset, y_offset1+gui_offset+5, main_w-gui_offset*2, 35}  
  
  -- menu buttons --
    -- left
    options2_button_xywh_t = {x_offset, y_offset, options_button_width, y_offset1-y_offset}
    --right
    options_button_xywh_t = {x_offset+width1+gui_offset, y_offset, options_button_width, y_offset1-y_offset}
    --right
    opt3_width = 60
    options3_button_xywh_t = {(main_w-opt3_width)/2, y_offset, opt3_width, 20}
    
    type_gravity_button_xywh_t = {gravity_slider_xywh_t[1]+gravity_slider_xywh_t[3]+5,gravity_slider_xywh_t[2],
      20, gravity_slider_xywh_t[4]}
 end
 
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
  
 function GUI_menu_item(b0, item_offset, is_selected_item, is_vert, color_t)
   if is_selected_item == nil then is_selected_item = 0 end
   gfx.setfont(1, font, fontsize_menu_item)    
   measurestr = gfx.measurestr(b0)
   if is_vert == false then 
     x0 = item_offset
     y0 = y + (h - fontsize_menu_name)/2 + 1
   end
   
   if is_vert == true then
     x0 = x + (w - measurestr)/2 + 1
     y0 = item_offset
   end
   
   w0 = measurestr
   h0 = fontsize_menu_item   
   
   gfx.r, gfx.g, gfx.b, gfx.a = color_t[1], color_t[2], color_t[3], is_selected_item * 0.8 + 0.17 
   gfx.x = x0
   gfx.y = y0
   gfx.drawstr(b0) 
   -- gui help --
   gfx.r, gfx.g, gfx.b, gfx.a = 1,1,1,gui_help
   gfx.roundrect(x0,y0,w0,h0,0.1,true) 
   return x, y0, 182.5, h0
 end 
      
 ---------------------------------------------------------------------------------------------------------------   
  
 function GUI_menu (xywh_t, names_t, values_t, is_vertical, is_selected,itemcolor_t,frame_alpha)
   x = xywh_t[1]
   y = xywh_t[2]
   w = xywh_t[3]
   h = xywh_t[4]
   num_buttons = #values_t
      
   -- frame --
   if is_selected ~= nil and is_selected == true then gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = 0,0,1,1,1,0.5
                          else gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = 0,0,1,1,1,frame_alpha end   
   gfx.roundrect(x,y,w,h,0.1,true)   
   
   -- define name strings -- 
   names_com = table.concat(names_t)
   menu_name = names_t[1] 
   b1 = names_t[2]
   b2 = names_t[3]
   b3 = names_t[4]
   b4 = names_t[5]
   b5 = names_t[6]
   b6 = names_t[7]
   b7 = names_t[8]
   b8 = names_t[9]
   b9 = names_t[10]   
   
   -- measure length of strings --
   gfx.setfont(1,font,fontsize_menu_name) 
   measurestrname = gfx.measurestr(menu_name)
   gfx.setfont(1,font,fontsize_menu_item)    
   measurestr1 = gfx.measurestr(b1)
   measurestr2 = gfx.measurestr(b2)
   if b3 ~= nil then measurestr3 = gfx.measurestr(b3) else measurestr3 = 0 end
   if b4 ~= nil then measurestr4 = gfx.measurestr(b4) else measurestr4 = 0 end
   if b5 ~= nil then measurestr5 = gfx.measurestr(b5) else measurestr5 = 0 end
   if b6 ~= nil then measurestr6 = gfx.measurestr(b6) else measurestr6 = 0 end
   if b7 ~= nil then measurestr7 = gfx.measurestr(b7) else measurestr7 = 0 end
   if b8 ~= nil then measurestr8 = gfx.measurestr(b8) else measurestr8 = 0 end
   if b9 ~= nil then measurestr9 = gfx.measurestr(b9) else measurestr9 = 0 end
   if b10 ~= nil then measurestr10 = gfx.measurestr(b10) else measurestr10 = 0 end
   measurestr_menu_com = gfx.measurestr(names_com) + (num_buttons)*beetween_items1
   
   if is_vertical == false then
   
     -- draw menu name --
     gfx.setfont(1,font,fontsize_menu_name)      
     x0 = x + (w - measurestr_menu_com)/2
     y0 = y + (h - fontsize_menu_name)/2
     gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,1,1,1,0.9 
     gfx.drawstr(menu_name)
     
     -- gui help frame for name --
     gfx.r, gfx.g, gfx.b, gfx.a = 1,1,1,gui_help
     gfx.roundrect(x0,y0,measurestrname,fontsize_menu_name,0.1,true,itemcolor_t) 
     
     -- draw menu items --     
     item_x_offset = x0 + measurestrname + beetween_items1
     x1,y1,w1,h1 = GUI_menu_item(b1, item_x_offset, values_t[1],false,itemcolor_t)
     
     item_x_offset = x1 + w1 + beetween_items1
     x2,y2,w2,h2 = GUI_menu_item(b2, item_x_offset, values_t[2],false,itemcolor_t)
     
     if b3~=nil then 
     item_x_offset = x2 + w2 + beetween_items1
     x3,y3,w3,h3 = GUI_menu_item(b3, item_x_offset, values_t[3],false,itemcolor_t) end
     
    else
    
     height_menu_com = fontsize_menu_name + fontsize_menu_item*num_buttons + beetween_items2*(num_buttons+1)
     
     -- draw menu name --
     gfx.setfont(1,font,fontsize_menu_name)      
     x0 = x + (w-measurestrname)/2
     y0 = y + (h - height_menu_com)/2
     gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,1,1,1,0.9 
     gfx.drawstr(menu_name)
     
     -- gui help frame for name --
     gfx.r, gfx.g, gfx.b, gfx.a = 1,1,1,gui_help
     gfx.roundrect(x0,y0,measurestrname,fontsize_menu_name,0.1,true) 
     
     -- draw menu items --     
     item_y_offset = y0 + fontsize_menu_name+ beetween_items2
     x1,y1,w1,h1 = GUI_menu_item(b1, item_y_offset, values_t[1],true,itemcolor_t)
     
     item_y_offset = y1 + h1 + beetween_items2
     x2,y2,w2,h2 = GUI_menu_item(b2, item_y_offset, values_t[2],true,itemcolor_t)
     
     if b3~=nil then 
     item_y_offset = y2 + h2 + beetween_items2
     x3,y3,w3,h3 = GUI_menu_item(b3, item_y_offset, values_t[3],true,itemcolor_t) end
     
     if b4~=nil then 
     item_y_offset = y3 + h3 + beetween_items2
     x4,y4,w4,h4 = GUI_menu_item(b4, item_y_offset, values_t[4],true,itemcolor_t) end  
     
     if b5~=nil then 
     item_y_offset = y4 + h4 + beetween_items2
     x5,y5,w5,h5 = GUI_menu_item(b5, item_y_offset, values_t[5],true,itemcolor_t) end  
     
     if b6~=nil then 
     item_y_offset = y5 + h5 + beetween_items2
     x6,y6,w6,h6 = GUI_menu_item (b6, item_y_offset, values_t[6],true,itemcolor_t) end 
     
     if b7~=nil then 
     item_y_offset = y6 + h6 + beetween_items2
     x7,y7,w7,h7 = GUI_menu_item (b7, item_y_offset, values_t[7],true,itemcolor_t) end 
     
   end   
                   
     
   coord_buttons_data = {x1, y1, w1, h1,
                         x2, y2, w2, h2,
                         x3, y3, w3, h3,
                         x4, y4, w4, h4,
                         x5, y5, w5, h6,
                         x6, y6, w6, h6,
                         x7, y7, w7, h7,
                         x8, y8, w8, h8,
                         x9, y9, w9, h9,
                         x10, y10, w10, h10}
   return coord_buttons_data 
 end  
 
 ---------------------------------------------------------------------------------------------------------------
  
function GUI_display_pos (pos, rgba_t, align, val)  
   if val == nil or val > 1 then val = 1 end      
    
    --GUI_display_length
   x1 = display_rect_xywh_t[1] + display_rect_xywh_t[3] *   ( (pos-gui_display_offset) / gui_display_length)   
   
   if align == "centered" then
     y1 = display_rect_xywh_t[2] + display_rect_xywh_t[4]/2 - (display_rect_xywh_t[4]*0.5)*val
     y2 = display_rect_xywh_t[2] + display_rect_xywh_t[4]/2 + (display_rect_xywh_t[4]*0.5)*val
   end   
   if align == "full" then
     y1 = display_rect_xywh_t[2]
     y2 = display_rect_xywh_t[2] + display_rect_xywh_t[4]
   end
   
   if align == "bottom" then
     y1 = display_rect_xywh_t[2] + display_rect_xywh_t[4] - val * (display_rect_xywh_t[4] / 4)
     y2 = display_rect_xywh_t[2] + display_rect_xywh_t[4]
   end  
   
   if align == "top" then
     y1 = display_rect_xywh_t[2]
     y2 = display_rect_xywh_t[2] + val * (display_rect_xywh_t[4] / 4)
   end     
    
   gfx.x = x1
   gfx.y = y1
   gfx.r, gfx.g, gfx.b, gfx.a = rgba_t[1], rgba_t[2], rgba_t[3], rgba_t[4]
   if x1 >= display_rect_xywh_t[1] and x1 < display_rect_xywh_t[1] + display_rect_xywh_t[3] then
     gfx.line(x1, y1, x1, y2, 0.9)
   end  
end 
 
 ---------------------------------------------------------------------------------------------------------------
 
 function GUI_display() 
   if update_display == true then
     gfx.dest = 2   
     gfx.setimgdim(2,-1,-1)
     gfx.setimgdim(2, display_rect_xywh_t[1]+display_rect_xywh_t[3], 
      display_rect_xywh_t[2]+display_rect_xywh_t[4])
                   
     gui_display_offset = first_measure_dest_time
     gui_display_length = last_measure_dest_time - first_measure_dest_time
     
     -- display main rectangle -- 
     gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1,frame_alpha_default
     gfx.roundrect(display_rect_xywh_t[1], display_rect_xywh_t[2],display_rect_xywh_t[3], display_rect_xywh_t[4],0.1, true)
     
     -- center line
     gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, 0.03
     gfx.line(display_rect_xywh_t[1], 
              display_rect_xywh_t[2]+display_rect_xywh_t[4]/2, 
              display_rect_xywh_t[1]+display_rect_xywh_t[3], 
              display_rect_xywh_t[2]+display_rect_xywh_t[4]/2, 0.9)   
           
     GUI_display_pos(editpos, editpos_rgba_t, "full")
     GUI_display_pos(playpos, playpos_rgba_t, "full")
     
     -- ref points positions
     if ref_points_t ~= nil then
       for i = 1, #ref_points_t do
         ref_point = ref_points_t[i]
         val = ref_point[2]
         if val == nil then val = 1 end       
         if use_vel_values_t[1] == 1 then
           GUI_display_pos(ref_point[1], ref_points_rgba_t, "top", ref_point[2])
          else  
           GUI_display_pos(ref_point[1], ref_points_rgba_t, "top", 1)
         end       
       end
     end  
     
     -- dest points positions
     if dest_points_t ~= nil then
       for i = 1, #dest_points_t do
         dest_point = dest_points_t[i]       
         if dest_point[2] == nil then val = 1 else val = dest_point[2] end
         GUI_display_pos(dest_point[1], dest_points_rgba_t, "bottom", val)
       end
     end 
     
     -- bars
     _, gui_display_length_bars = reaper.TimeMap2_timeToBeats(0, gui_display_length)
     _, gui_display_offset_bars = reaper.TimeMap2_timeToBeats(0, gui_display_offset)
     for i = 0, gui_display_length_bars+1 do      
       bar_time = reaper.TimeMap2_beatsToTime(0, 0, i+gui_display_offset_bars)  
       GUI_display_pos(0, bar_points_rgba_t, "centered", 0.1)   
       GUI_display_pos(bar_time, bar_points_rgba_t, "centered", 0.1)  
     end    
     
     -- beats
     if gui_display_length_bars <= 10 then
       for i = 1, cml*gui_display_length_bars do
         if i%cml ~= 0 then
           beat_time = reaper.TimeMap2_beatsToTime(0, i)
           GUI_display_pos(beat_time+gui_display_offset, bar_points_rgba_t, "centered", 0.01)
         end  
       end  
     end 
     update_display = false
     gfx.dest = -1 
    else -- update display
     gfx.a = 1
     gfx.dest = -1
     gfx.blit(2, 1, 0, display_rect_xywh_t[1], display_rect_xywh_t[2],display_rect_xywh_t[3], display_rect_xywh_t[4],
                       display_rect_xywh_t[1], display_rect_xywh_t[2],display_rect_xywh_t[3], display_rect_xywh_t[4])
   end
               
     
 end  
 
---------------------------------------------------------------------------------------------------------------

 function GUI_slider_gradient(xywh_t, name, slider_val, type,dadx)
   if slider_val > 1 then slider_val = 1 end
   slider_val_inv = math.abs(math.abs(slider_val) - 1)
   x = xywh_t[1]
   y = xywh_t[2]
   w = xywh_t[3]-slider_val_inv*xywh_t[3]
   w0 = xywh_t[3]
   h = xywh_t[4]
   r,g,b,a = 1,1,1,0.0
   gfx.x = x
   gfx.y = y
   drdx = 0
   drdy = 0
   dgdx = 0.0002
   dgdy = 0.002     
   dbdx = 0
   dbdy = 0
   if dadx == nil then dadx = 0.001 end
   dady = 0.0001
   
   if type == "normal" then
     gfx.gradrect(x,y,w,h, r,g,b,a, drdx, dgdx, dbdx, dadx, drdy, dgdy, dbdy, dady)
   end
   
   if type == "centered" then
     if slider_val > 0 then                  
       gfx.gradrect(x+w0/2,y,w/2,h,         r,g,b,a,    drdx, dgdx, dbdx,  dadx, drdy, dgdy, dbdy,  dady)
      else
       a_st =  dadx *  w/2
       gfx.gradrect(x + (w0/2-w/2),y,w/2,h, r,g,b,a_st, drdx, dgdx, dbdx, -dadx, drdy, dgdy, dbdy, -dady)
     end
   end
   
   if type == "mirror" then       
     gfx.gradrect(x+w0/2,y,w/2,h,         r,g,b,a,    drdx, dgdx, dbdx,  dadx, drdy, dgdy, dbdy,  dady)
     a_st =  dadx *  w/2
     gfx.gradrect(x + (w0/2-w/2),y,w/2,h, r,g,b,a_st, drdx, dgdx, dbdx, -dadx, drdy, dgdy, dbdy, -dady)     
   end
     
   -- draw name -- 
   gfx.setfont(1,font,fontsize_menu_name)
   measurestrname = gfx.measurestr(name)      
   x0 = x + (w0 - measurestrname)/2
   y0 = y + (h - fontsize_menu_name)/2
   gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,0.4, 1, 0.4,0.9 
   gfx.drawstr(name)
   
   --draw frame
   gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, frame_alpha_default
   gfx.roundrect(x,y,w0,h,0.1, true)   
 end 
 
---------------------------------------------------------------------------------------------------------------

 function GUI_button(xywh_t, name, name_pressed, state, has_frame, color_t)
   
 
   x = xywh_t[1]
   y = xywh_t[2]
   w = xywh_t[3]
   h = xywh_t[4]
   gfx.x,  gfx.y = x,y
   
   --draw back
   
   gfx.r, gfx.g, gfx.b, gfx.a = 0.2, 0.2, 0.2, 1
   gfx.rect(x,y,w,h,true)
   
   -- draw name -- 
   gfx.setfont(1,font,fontsize_menu_name)
   measurestrname = gfx.measurestr(name)      
   x0 = x + (w - measurestrname)/2
   y0 = y + (h - fontsize_menu_name)/2
   if color_t ~= nil then
     r,g,b,a = extract_table(color_t)
     gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,r,g,b,a 
    else
     gfx.x, gfx.y, gfx.r, gfx.g, gfx.b, gfx.a = x0,y0,0.4, 1, 0.4,0.9 
   end  
    
          
          gfx.drawstr(name) 
     -- frame -- 
     if has_frame == true then
       gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, frame_alpha_default
       gfx.roundrect(x,y,w,h,0.1, true)
     end  
     
 end
 
---------------------------------------------------------------------------------------------------------------
     
 function GUI_DRAW()
 
  if project_grid_measures < 1 then--and timesig_error == false then
  
   ------------------  
   --- main page ----
   ------------------  
   
     -- background --
     gfx.r, gfx.g, gfx.b, gfx.a = 0.2, 0.2, 0.2, 1
     gfx.rect(0,0,main_w,main_h)
    
     -- menus --  
     
     get_but_wh = {25,15}
     quantize_ref_xywh_buttons_t =   
       GUI_menu (quantize_ref_menu_xywh_t, quantize_ref_menu_names_t, 
                 quantize_ref_values_t, true,false,itemcolor1_t,0.05)
     
     
     
     --get items
     get_item_button_xywh_t = {quantize_ref_menu_xywh_t[1]+quantize_ref_menu_xywh_t[3]-30,
         quantize_ref_xywh_buttons_t[2],get_but_wh[1],get_but_wh[2]}
     if show_get_item == true then 
       GUI_button(get_item_button_xywh_t, "get", "<<", _, false) end
     --get sm
     get_sm_button_xywh_t = {quantize_ref_menu_xywh_t[1]+quantize_ref_menu_xywh_t[3]-30,
         quantize_ref_xywh_buttons_t[6],get_but_wh[1],get_but_wh[2]}
     if show_get_sm == true then 
       GUI_button(get_sm_button_xywh_t, "get", "<<", _, false) end
     --get ep
     get_ep_button_xywh_t = {quantize_ref_menu_xywh_t[1]+quantize_ref_menu_xywh_t[3]-30,
         quantize_ref_xywh_buttons_t[10],get_but_wh[1],get_but_wh[2]}
     if show_get_ep == true then 
       GUI_button(get_ep_button_xywh_t, "get", "<<", _, false) end                   
     --get notes
     get_note_button_xywh_t = {quantize_ref_menu_xywh_t[1]+quantize_ref_menu_xywh_t[3]-30,
         quantize_ref_xywh_buttons_t[14],get_but_wh[1],get_but_wh[2]}
     if show_get_note == true then 
       GUI_button(get_note_button_xywh_t, "get", "<<", _, false) end
                 
                 
                 
     if snap_mode_values_t[2] == 1 then -- if pattern mode
       usergroove_line_xywh_t = {quantize_ref_menu_xywh_t[1], quantize_ref_xywh_buttons_t[18],
          quantize_ref_menu_xywh_t[3], fontsize_menu_item}
       
       add_groove_button_xywh_t = {quantize_ref_menu_xywh_t[1]+quantize_ref_menu_xywh_t[3]-30,
         quantize_ref_xywh_buttons_t[18],get_but_wh[1],get_but_wh[2]}
       if show_groove_buttons then GUI_button(add_groove_button_xywh_t, "get", "<<", _, false) end
       --prev groove
       prev_groove_button_xywh_t = {quantize_ref_menu_xywh_t[1]+5,
         quantize_ref_xywh_buttons_t[18],15,15}       
       if show_groove_buttons then GUI_button(prev_groove_button_xywh_t, "<", "<<", _, false) end
       --next groove
       next_groove_button_xywh_t = {quantize_ref_menu_xywh_t[1]+20,
                quantize_ref_xywh_buttons_t[18],15,15}       
       if show_groove_buttons then GUI_button(next_groove_button_xywh_t, ">", "<<", _, false)    end   
       
       
       meas_str_temp = gfx.measurestr(quantize_ref_menu_names_t[7])       -- if grid
       --grid slider
       grid_line_xywh_t = {quantize_ref_menu_xywh_t[1], quantize_ref_xywh_buttons_t[22],
          quantize_ref_menu_xywh_t[3], fontsize_menu_item}
       grid_value_slider_xywh_t = {quantize_ref_menu_xywh_t[1]+5, quantize_ref_xywh_buttons_t[22]-2, quantize_ref_menu_xywh_t[3]-10, fontsize_menu_item+3}
       if show_grid_slider == true then 
         GUI_slider_gradient(grid_value_slider_xywh_t, "", grid_value, "normal") end 
       --swing slider
       swing_line_xywh_t = {quantize_ref_menu_xywh_t[1], quantize_ref_xywh_buttons_t[26], 
         quantize_ref_menu_xywh_t[3], fontsize_menu_item}
       swing_grid_value_slider_xywh_t = {quantize_ref_menu_xywh_t[1]+5, quantize_ref_xywh_buttons_t[26]-1, 
         quantize_ref_menu_xywh_t[3]-35, fontsize_menu_item+3}
       if show_swing_slider then GUI_slider_gradient(swing_grid_value_slider_xywh_t, "", swing_value, "centered",0.005)  end
       --swing button
       type_swing_button_xywh_t = {quantize_ref_menu_xywh_t[1]+quantize_ref_menu_xywh_t[3]-25,
         quantize_ref_xywh_buttons_t[26],20,15}
       if show_swing_slider then GUI_button(type_swing_button_xywh_t, ">", "<<", _, false) end
     end  
          
     quantize_dest_xywh_buttons_t =  
       GUI_menu (quantize_dest_menu_xywh_t, quantize_dest_menu_names_t, 
         quantize_dest_values_t, true,false,itemcolor2_t,0.05)
     
     
     if enable_display_t[1] == 1 then GUI_display() end 
   
     GUI_slider_gradient(apply_slider_xywh_t, apply_bypass_slider_name, strenght_value,"normal",0.0003)
     
     if use_vel_values_t[1]==1 then
       GUI_slider_gradient(use_vel_slider_xywh_t, "Use ref. velocity "..math.floor(use_vel_value*100)..'%', use_vel_value, "normal") end
       
       
     if snap_area_values_t[1] == 1 then 
       GUI_slider_gradient(gravity_slider_xywh_t, "Gravity "..math.floor(gravity_value*gravity_mult_value*1000)..' ms', gravity_value, "mirror") 
       GUI_button(type_gravity_button_xywh_t, ">", "<<", _, true) end -- if gravity
     
     GUI_button(options_button_xywh_t, "<<", "<<", _, true)
     GUI_button(options2_button_xywh_t, ">>", ">>", _, true)
     GUI_button(options3_button_xywh_t, 'Menu', "Menu", _, true)
     GUI_button(restore_button_xywh_t, "R >", "<<", _, true)
             
   else -- if snap > 1 show error
     
     gfx.setfont(1,font,fontsize_menu_name)
     measure_err_str = gfx.measurestr("Set line spacing (Snap/Grid settings) lower than 1")
     gfx.x, gfx.y = (main_w-measure_err_str)/2, main_h/2
     gfx.drawstr("Set line spacing (Snap/Grid settings) lower than 1")   
    
  end -- if project_grid_measures == 0   
  gfx.update()
 end
  
---------------------------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------------------------- 
    
 --[[function GET_timesigs()
   timesig_count = reaper.CountTempoTimeSigMarkers(0)
   if timesig_count ~= nil then
     for i =1, timesig_count do
       _, _, _, _, _, timesig, timesig_denom = reaper.GetTempoTimeSigMarker(0, i-1)
       if timesig == 4 or timesig_denom == 4 then 
         timesig_error = false 
        else 
         timesig_error = true break
       end  
       if timesig == 0 and timesig_denom == 0 then  timesig_error = false   end
     end 
    else
     timesig_error = false  
   end
 end]]
 
 ---------------------------------------------------------------------------------------------------------------      
 function GET_grid()
   project_grid_time = reaper.BR_GetNextGridDivision(0)
   project_grid_beats, project_grid_measures, project_grid_cml = reaper.TimeMap2_timeToBeats(0, project_grid_time)
   
   custom_grid_beats_t = {4/4,
                          4/6,
                          4/8,
                          4/12,
                          4/16,
                          4/24,
                          4/32,
                          4/48,
                          4/64,
                          4/96,
                          4/128}
                                               
   custom_grid_beats_i = math.floor(grid_value*12)
   
   if project_grid_measures == 0 then
     if custom_grid_beats_i == 0 then 
       grid_beats = project_grid_beats *0.5       
      else
       grid_beats = custom_grid_beats_t[custom_grid_beats_i]       
     end   
     
     if grid_beats == nil then grid_beats = project_grid_beats end
     
     grid_divider = math.ceil(math.round(4/grid_beats, 1))*0.5
     grid_string = "1/"..math.ceil(grid_divider)
     
     if grid_divider % 3 == 0 then grid_string = "1/"..math.ceil(grid_divider/3*2).."T" end
     grid_time = reaper.TimeMap2_beatsToTime(0, grid_beats*2) 
     grid_bar_time  = reaper.TimeMap2_beatsToTime(0, 0, 1)
    else
     grid_string = "error"
   end -- if proj grid measures ==0 / snap < 1 
   return  grid_beats, grid_string, project_grid_measures,project_grid_cml, grid_time, grid_bar_time
 end 
  
 --------------------------------------------------------------------------------------------------------------- 
  
 function ENGINE1_get_reference_item_positions()
    ref_items_t = {} 
    ref_items_subt = {}
    count_sel_ref_items = reaper.CountSelectedMediaItems(0) 
    if count_sel_ref_items ~= nil then   -- get measures beetween items
      for i = 1, count_sel_ref_items, 1 do
        ref_item = reaper.GetSelectedMediaItem(0, i-1)          
        ref_item_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")
        ref_item_vol = reaper.GetMediaItemInfo_Value(ref_item, "D_VOL")
        ref_items_subt = {ref_item_pos, ref_item_vol}
        table.insert(ref_items_t, ref_items_subt)   
      end 
    end  
    return #ref_items_t 
  end 
  
 --------------------------------------------------------------------------------------------------------------- 
 
 function ENGINE1_get_reference_SM_positions()   
   ref_sm_pos_t = {}       
   count_sel_ref_items = reaper.CountSelectedMediaItems(0)  
   if count_sel_ref_items ~= nil then
     for i = 1, count_sel_ref_items, 1 do
     ref_item = reaper.GetSelectedMediaItem(0, i-1)       
       if ref_item ~= nil then
         ref_take = reaper.GetActiveTake(ref_item)
         if ref_take ~= nil then    
           takerate = reaper.GetMediaItemTakeInfo_Value(ref_take, "D_PLAYRATE" )           
           str_markers_count = reaper.GetTakeNumStretchMarkers(ref_take) 
           if  str_markers_count ~= nil then
             for j = 1, str_markers_count, 1 do             
              ref_item_pos = reaper.GetMediaItemInfo_Value(ref_item, "D_POSITION")                            
              ref_item_len = reaper.GetMediaItemInfo_Value(ref_item, "D_LENGTH")
              retval, ref_str_mark_pos = reaper.GetTakeStretchMarker(ref_take, j-1)
              ref_sm_pos = ref_item_pos + ref_str_mark_pos/takerate  
              if  ref_str_mark_pos > 0 and ref_str_mark_pos/takerate < ref_item_len-0.000001 then
                if sm_rel_ref_values_t[2] ==1 then  ref_sm_pos = ref_sm_pos-ref_item_pos end
                table.insert(ref_sm_pos_t, ref_sm_pos)                 
              end
             end -- for
           end -- str_markers_count ~= nil
         end -- if take not nil         
       end -- if item not nil  
     end -- forcount sel items       
   end -- if sel items >0 
   return #ref_sm_pos_t   
 end
 
 --------------------------------------------------------------------------------------------------------------- 
 
 function ENGINE1_get_reference_EP_positions()   
  ref_ep_t = {}
  counttracks = reaper.CountTracks(0) 
  if  counttracks ~= nil then
    for i = 1, counttracks do 
      track = reaper.GetTrack(0, i-1)
      env_count = reaper.CountTrackEnvelopes(track)
      if env_count ~= nil then
        for j = 1, env_count do
          envelope = reaper.GetTrackEnvelope(track, j-1)
          if envelope ~= nil then
            envelope_points_count = reaper.CountEnvelopePoints(envelope)
            if envelope_points_count ~= nil then
              for k = 1, envelope_points_count, 1  do
                retval, ref_ep_pos, ref_ep_val, shape, tension, isselected = reaper.GetEnvelopePoint(envelope, k-1)
                if isselected == true then                   
                  table.insert(ref_ep_t, {ref_ep_pos, ref_ep_val} ) 
                end
              end  
            end -- if selected  
          end -- loop env points
        end  --envelope_points_count > 0
      end -- envelope not nil 
    end 
  end        
  
 -- take envelopes --
  count_items = reaper.CountSelectedMediaItems(0)
  if count_items ~= nil then
    for i = 1, count_items do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        takescount =  reaper.CountTakes(item)
        if takescount ~= nil then
          for j = 1, takescount do
            take = reaper.GetTake(item, j-1)
            if take ~= nil  then
              count_take_env = reaper.CountTakeEnvelopes(take)
              if count_take_env ~= nil then
                for env_id = 1, count_take_env do
                  TrackEnvelope = reaper.GetTakeEnvelope(take, env_id-1)
                  if TrackEnvelope ~= nil then
                    count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)
                    if count_env_points ~= nil then 
                      for point_id = 1, count_env_points, 1 do    
                        retval, ref_ep_pos, ref_ep_val, shape, tension, selected = reaper.GetEnvelopePoint(TrackEnvelope, point_id-1)
                        if selected == true then                  
                          table.insert(ref_ep_t, {ref_ep_pos, ref_ep_val} ) 
                        end
                      end -- loop env points  
                    end  -- count_env_points ~= nil  
                  end -- TrackEnvelope ~= nil
                end  
              end
            end
          end
        end
      end
    end
  end
          
  return #ref_ep_t  
 end
 
 ---------------------------------------------------------------------------------------------------------------
 
 function ENGINE1_get_reference_notes_positions()  
     ref_notes_t  = {}
     count_sel_ref_items = reaper.CountSelectedMediaItems(0)
     if count_sel_ref_items ~= nil then   -- get measures beetween items
       for i = 1, count_sel_ref_items, 1 do
         ref_item = reaper.GetSelectedMediaItem(0, i-1)
         if ref_item ~= nil then
           ref_take = reaper.GetActiveTake(ref_item)
           if ref_take ~= nil then
             if reaper.TakeIsMIDI(ref_take) ==  true then   
               retval, notecntOut, ccevtcntOut = reaper.MIDI_CountEvts(ref_take)
               if notecntOut ~= nil then
                 for j = 1, notecntOut, 1 do                 
                   retval, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(ref_take, j-1)
                   if sel_notes_mode_values_t[1] == 1 then -- if selected only
                     if selectedOut == true then
                       ref_note_pos = reaper.MIDI_GetProjTimeFromPPQPos(ref_take, startppqpos)                   
                       table.insert(ref_notes_t, {ref_note_pos, vel/127})
                     end  
                   end  
                   if sel_notes_mode_values_t[2] == 1 then -- if all in item
                     ref_note_pos = reaper.MIDI_GetProjTimeFromPPQPos(ref_take, startppqpos)                   
                     table.insert(ref_notes_t, {ref_note_pos, vel/127})
                   end  
                 end -- count notes                   
               end -- notecntOut > 0
             end -- TakeIsMIDI
           end -- ref_take ~= nil 
         end-- ref_item ~= nil
       end -- for count_sel_ref_items
     end --   count_sel_ref_items > 0 
     return #ref_notes_t           
 end   
 
---------------------------------------------------------------------------

 function ENGINE1_get_reference_usergroove(rel)
   i=-1
   grooves_t = {}
   repeat   
     i = i +1
     groove_name = reaper.EnumerateFiles(exepath..'/Grooves', i)
     if groove_name ~= nil then
       if string.find(groove_name, '.rgt')~= nil then
         table.insert(grooves_t, groove_name)         
       end  
     end  
     until
     groove_name == nil
   
   if grooves_t ~= nil then
     groove_menu_string = table.concat(grooves_t, " | ")
     gfx.x, gfx.y = mx, my
     if rel ~= nil and groove_menu_ret ~= nil then     
       groove_menu_ret = groove_menu_ret+rel end   
     if  groove_menu_ret == nil then 
       groove_menu_ret = 1 
      else
       if  groove_menu_ret <1 then groove_menu_ret = 1 end
     end
     
     if rel == nil then groove_menu_ret = gfx.showmenu(groove_menu_string) end
     
     if groove_menu_ret ~= 0 then
       filename_full = exepath.."/Grooves/"..grooves_t[groove_menu_ret]
         if filename_full ~=nil then          
           content_temp_t = {}
           file = io.open(filename_full, "r")
           if file ~= nil then
             content = file:read("*all")
             for line in io.lines(filename_full) do           
               table.insert(content_temp_t, line) 
             end
             file:close()
            
             beats_in_groove = tonumber(string.sub(content_temp_t[2], 28))
             --pattern_len = math.floor(beats_in_groove/4)
             ref_groove_t = {}  
             table.insert(ref_groove_t, 0)
             for i = 1, #content_temp_t do
                if i>=5 then
                  temp_var = tonumber(content_temp_t[i])
                  temp_var_conv = reaper.TimeMap2_beatsToTime(0, temp_var)
                  table.insert(ref_groove_t, temp_var_conv)
                end  
             end
             quantize_ref_menu_groove_name = grooves_t[groove_menu_ret]
             ENGINE1_get_reference_FORM_points() 
             ENGINE3_quantize_objects() 
           end -- if file ~= nil           
        end   -- if filename_full ~=nil
     end -- if  groove_menu_ret ~= 0
   end -- if grooves_t ~= nil
   
 end
 
---------------------------------------------------------------------------
   
 function ENGINE1_get_reference_grid()   
   ref_grid_t = {}   
   for i = 0, grid_bar_time, grid_time  do     
     table.insert(ref_grid_t, i)
   end
 end 
 
 --------------------------------------------------------------------------------------------------------------- 
   
  function ENGINE1_get_reference_swing_grid()  
     ref_swing_grid_t = {}
     i2 = 0
     if cml_com == nil then cml_com = 4 end     
     for grid_p = 0, grid_bar_time, grid_time do         
       if i2 % 2 == 0 then 
         table.insert(ref_swing_grid_t, grid_p) end
       if i2 % 2 == 1 then        
         grid_p_sw = grid_p + swing_value* swing_scale*grid_time
         table.insert(ref_swing_grid_t,grid_p_sw) 
       end
       i2 = i2+1
     end   
end   
 
 --------------------------------------------------------------------------------------------------------------- 

 function ENGINE1_get_reference_FORM_points()
   ref_points_t = {}
   
     -- items --
     if quantize_ref_values_t[1] == 1 and ref_items_t ~= nil then     
       for i = 1, #ref_items_t do
         table_temp_val = ref_items_t[i]
         table.insert (ref_points_t, i, {table_temp_val[1],table_temp_val[2]})
       end
     end
     
     -- sm --
     if quantize_ref_values_t[2] == 1 and ref_sm_pos_t ~= nil then     
       for i = 1, #ref_sm_pos_t do
         table_temp_val = {ref_sm_pos_t[i],nil}
         if sm_timesel_ref_values_t[2]==1 then 
           if ref_sm_pos_t[i] > timesel_st and ref_sm_pos_t[i] < timesel_end then  table.insert (ref_points_t, table_temp_val) end          
          else  
           table.insert (ref_points_t, table_temp_val)
         end    
       end
     end
     
     -- ep --
     if quantize_ref_values_t[3] == 1 and ref_ep_t ~=nil then     
       for i = 1, #ref_ep_t do
         table_temp_val = ref_ep_t[i]
         table.insert (ref_points_t, i, {table_temp_val[1],table_temp_val[2]})
       end
     end
     
     -- notes --
     if quantize_ref_values_t[4] == 1 and ref_notes_t ~= nil then     
       for i = 1, #ref_notes_t do
         table_temp_val = ref_notes_t[i]
         table.insert (ref_points_t, i, {table_temp_val[1],table_temp_val[2]})
       end
     end               
     
     -- groove 
     if quantize_ref_values_t[5] == 1 and ref_groove_t ~= nil then     
       for i = 1, #ref_groove_t do
         table_temp_val = ref_groove_t[i]
         table.insert (ref_points_t, i, {table_temp_val, 1})
       end
     end      
     
     
     -- grid --
     if quantize_ref_values_t[6] == 1 and ref_grid_t ~= nil then     
       for i = 1, #ref_grid_t do
         temp_val5 = ref_grid_t[i]
         table.insert (ref_points_t, {temp_val5, 1})
       end
     end
     
     -- swing --
     if quantize_ref_values_t[7] == 1 and ref_swing_grid_t ~= nil then   
         for i = 1, #ref_swing_grid_t do
           temp_val4 = ref_swing_grid_t[i]
           table.insert (ref_points_t, {temp_val4, 1})
         end      
     end
    
    
    -- form pattern / generate pattern grid
           
     if ref_points_t ~= nil and snap_mode_values_t[2] == 1 then
        ref_points_t2 = {}--table for beats pos  
              
         -- first ref item measure
        ref_point_subt_temp_min = math.huge --start value  for loop
        for i = 1, #ref_points_t do          
          ref_point_subt_temp = ref_points_t[i]          
          ref_point_subt_temp_min = math.min(ref_point_subt_temp_min, ref_point_subt_temp[1])
        end  
        
        retval, first_pat_measure, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, ref_point_subt_temp_min)
        
        -- if pos not bigger than first item measure + pattern length , add to table
        for i = 1, #ref_points_t do
          ref_point_subt_temp = ref_points_t[i]          
          retval, measure2, cml1, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, ref_point_subt_temp[1])
          if measure2 < first_pat_measure + pattern_len then
            table.insert(ref_points_t2, {retval, ref_point_subt_temp[2]})
          end  
        end
        
        -- add edges
        if pat_edge_values_t[1] == 1 then
          table.insert(ref_points_t2, {0, 1})
          table.insert(ref_points_t2, {pattern_len*cml, 1})
        end
        
        -- generate grid from ref_points_t2
          ref_points_t = {}
          --count dest points max min
          if dest_points_t == nil then dest_points_t = {{0,1}} end
            dest_points_measure_min1 = math.huge
            dest_points_measure_max1 = 0      
                  
            for i=1, #dest_points_t do
              dest_points_t_subt = dest_points_t[i]
              _, measure = reaper.TimeMap2_timeToBeats(0,dest_points_t_subt[1])
              dest_points_measure_min1 = math.min(measure, dest_points_measure_min1)
              dest_points_measure_max1 = math.max(measure, dest_points_measure_max1)
            end  -- for loop
          
            if dest_points_measure_min1 == 0 then dest_points_measure_min1 = 1 end
                      
            for i=dest_points_measure_min1-1, dest_points_measure_max1+1, pattern_len do          
              for j=1, #ref_points_t2 do
                ref_points_t2_subt = ref_points_t2[j]            
                ref_pos_time = reaper.TimeMap2_beatsToTime(0, ref_points_t2_subt[1], i-1)
                if ref_points_t2_subt[1] > cml then
                  ref_pos_time = reaper.TimeMap2_beatsToTime(0, ref_points_t2_subt[1] - cml, i-1)
                end  
                if ref_pos_time > 0 and  ref_points_t2_subt[2] > 0 then 
                  table.insert(ref_points_t, {ref_pos_time, ref_points_t2_subt[2]} )
                end
              end  
            end   -- generate ref point over timeline
              
          
     end       
 end 
   
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
 
function GET_project_len()
  --[[positions_of_objects_t = {}
  count_tracks = reaper.CountTracks(0)
  if count_tracks ~= nil then    
    for i = 1, count_tracks, 1 do
      track = reaper.GetTrack(0, i-1)
      track_guid = reaper.BR_GetMediaTrackGUID(track)
      if track~= nil then
        count_envelopes = reaper.CountTrackEnvelopes(track)
        if count_envelopes ~= nil then
          for j = 1, count_envelopes, 1 do
            TrackEnvelope = reaper.GetTrackEnvelope(track, j-1)      
            if TrackEnvelope ~= nil then
              count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)              
              if count_env_points ~= nil then 
                for k = 1, count_env_points, 1 do  
                  retval, position = reaper.GetEnvelopePoint(TrackEnvelope, k-1)                   
                  table.insert(positions_of_objects_t, position)
                end
              end  
            end
          end
        end  
      end
    end  
  end
  
  count_items = reaper.CountMediaItems(0) 
  if count_items ~= nil then   -- get measures beetween items
    for i = 1, count_items, 1 do
      item = reaper.GetMediaItem(0, i-1)          
      item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") 
      item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")   
      item_end = item_pos + item_len
      table.insert(positions_of_objects_t, item_end)  
    end 
  end  
  
  table.sort(positions_of_objects_t)
  i_max = #positions_of_objects_t
  max_object_position = positions_of_objects_t[i_max]
  if max_object_position == nil then max_object_position = 1 end
  retval, measuresOut, cml = reaper.TimeMap2_timeToBeats(0, max_object_position)
  max_object_position = reaper.TimeMap2_beatsToTime(0, 0, measuresOut+1)
  if max_object_position == nil then max_object_position = 0 end
  retval, last_measure, cml, fullbeats, cdenom = reaper.TimeMap2_timeToBeats(0, max_object_position)]]
  
  max_point = 0
  min_point = math.huge
  
  if dest_points_t ~= nil then
    for i = 1, #dest_points_t do      
      dest_points_t_subt = dest_points_t[i]
      max_point = math.max(dest_points_t_subt[1],max_point)
      min_point = math.min(dest_points_t_subt[1],min_point)
    end
  end  
  _, first_measure_dest = reaper.TimeMap2_timeToBeats(0, min_point)  
  _, last_measure_dest = reaper.TimeMap2_timeToBeats(0, max_point)
  last_measure_dest = last_measure_dest+1
  first_measure_dest_time = reaper.TimeMap2_beatsToTime(0, 0, first_measure_dest)
  last_measure_dest_time = reaper.TimeMap2_beatsToTime(0, 0, last_measure_dest)
  
  if ref_points_t ~= nil then  
    for i = 1, #ref_points_t do
      ref_points_t_item_subt = ref_points_t[i]
      max_point = math.max(ref_points_t_item_subt[1],max_point)
      min_point = math.min(ref_points_t_item_subt[1],min_point)
    end  
  end  
  
  max_object_position = max_point
  _, first_measure = reaper.TimeMap2_timeToBeats(0, min_point)
  _, last_measure1 = reaper.TimeMap2_timeToBeats(0, max_point)
  last_measure = last_measure1 +1
  _, _, cml_com = reaper.TimeMap2_timeToBeats(0, 0)
  return max_object_position, first_measure, last_measure, cml_com, first_measure_dest_time, last_measure_dest_time, last_measure_dest
end
  
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
   
 function ENGINE2_get_dest_items()
  dest_items_t = {}
  dest_items_subt = {}
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then     
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1)
      item_guid = reaper.BR_GetMediaItemGUID(item) 
      item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      item_vol = reaper.GetMediaItemInfo_Value(item, "D_VOL")
      dest_items_subt = {item_guid, item_pos, item_vol}
      table.insert(dest_items_t, dest_items_subt)
    end
  return #dest_items_t
  end  
 end 

 ---------------------------------------------------------------------------------------------------------------
  
 function ENGINE2_get_dest_sm(do_reset, time_sel)
  dest_sm_t = {}
  dest_sm_subt = {} 
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then 
    count_stretch_markers_com = 0
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1) 
      if item ~= nil then   
        item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")    
        take = reaper.GetActiveTake(item)      
        if take ~= nil then
          if reaper.TakeIsMIDI(take) == false then          
            take_guid = reaper.BR_GetMediaItemTakeGUID(take)
            takerate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")                    
            takeoffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
            count_stretch_markers = reaper.GetTakeNumStretchMarkers(take)
            if count_stretch_markers ~= nil then
              for j = 1, count_stretch_markers,1 do
                retval, posOut, srcpos = reaper.GetTakeStretchMarker(take, j-1)
                if do_reset ~= nil and do_reset == true then 
                  if time_sel ~= nil and time_sel == true then
                    pos_true = posOut/takerate+item_pos
                    if pos_true > timesel_st and pos_true < timesel_end then
                      dest_sm_subt = {take_guid, srcpos, srcpos, item_pos, takerate, item_len,takeoffset}
                     else
                      dest_sm_subt = {take_guid, posOut, srcpos, item_pos, takerate, item_len,takeoffset}
                    end  
                   else
                    dest_sm_subt = {take_guid, srcpos, srcpos, item_pos, takerate, item_len,takeoffset}
                  end                    
                 else
                  dest_sm_subt = {take_guid, posOut, srcpos, item_pos, takerate, item_len,takeoffset}
                end  
                if posOut > 0 and posOut < item_len-0.001 then
                  table.insert(dest_sm_t, dest_sm_subt)
                end  
              end -- loop takes  
            end -- count_stretch_markers ~= nil 
          end  
        end -- take ~= nil  
      end 
    end -- item loop
  return #dest_sm_t   
  end -- count_sel_items ~= nil
 end 
 
 ---------------------------------------------------------------------------------------------------------------
  
 function ENGINE2_get_dest_ep()
  dest_ep_t = {}
  dest_ep_subt = {}
  
  -- track envelopes --
  count_tracks = reaper.CountTracks(0)
  if count_tracks ~= nil then    
    for i = 1, count_tracks, 1 do
      track = reaper.GetTrack(0, i-1)
      track_guid = reaper.BR_GetMediaTrackGUID(track)
      if track~= nil then
        count_envelopes = reaper.CountTrackEnvelopes(track)
        if count_envelopes ~= nil then
          for env_id = 1, count_envelopes, 1 do
            TrackEnvelope = reaper.GetTrackEnvelope(track, env_id-1)      
            if TrackEnvelope ~= nil then
              count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)
              if count_env_points ~= nil then 
                for point_id = 1, count_env_points, 1 do    
                  retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(TrackEnvelope, point_id-1)
                  if selected == true then                  
                     dest_ep_subt = {true, track_guid, env_id, point_id, time, value, shape, tension, selected}
                     table.insert(dest_ep_t, dest_ep_subt)
                  end
                end -- loop env points  
              end  -- count_env_points ~= nil  
            end -- TrackEnvelope ~= nil
          end -- loop enelopes
        end -- count_envelopes ~= nil  
      end -- track~= nil
    end  -- loop count_tracks
  end -- count_tracks ~= nil  
  
  -- take envelopes --
  count_items = reaper.CountSelectedMediaItems(0)
  if count_items ~= nil then
    for i = 1, count_items do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        takescount =  reaper.CountTakes(item)
        if takescount ~= nil then
          for j = 1, takescount do
            take = reaper.GetTake(item, j-1)
            take_guid = reaper.BR_GetMediaItemTakeGUID(take)
            if take ~= nil  then
              count_take_env = reaper.CountTakeEnvelopes(take)
              if count_take_env ~= nil then
                for env_id = 1, count_take_env do
                  TrackEnvelope = reaper.GetTakeEnvelope(take, env_id-1)
                  if TrackEnvelope ~= nil then
                    count_env_points = reaper.CountEnvelopePoints(TrackEnvelope)
                    if count_env_points ~= nil then 
                      for point_id = 1, count_env_points, 1 do    
                        retval, time, value, shape, tension, selected = reaper.GetEnvelopePoint(TrackEnvelope, point_id-1)
                        if selected == true then                  
                          dest_ep_subt = {false, take_guid, env_id, point_id, time, value, shape, tension, selected}
                          table.insert(dest_ep_t, dest_ep_subt)
                        end
                      end -- loop env points  
                    end  -- count_env_points ~= nil  
                  end -- TrackEnvelope ~= nil
                end  
              end
            end
          end
        end
      end
    end
  end
  
  return #dest_ep_t
  
 end  
 
 ---------------------------------------------------------------------------------------------------------------

 function ENGINE2_get_dest_notes() 
  dest_notes_t = {}
  dest_notes_t2 = {} -- for notes count if quant sel only
  dest_notes_subt = {} 
  count_sel_items = reaper.CountSelectedMediaItems(0)
  if count_sel_items ~= nil then   -- get measures beetween items
    for i = 1, count_sel_items, 1 do
      item = reaper.GetSelectedMediaItem(0, i-1)
      if item ~= nil then
        take = reaper.GetActiveTake(item)
        take_guid = reaper.BR_GetMediaItemTakeGUID(take)
        if take ~= nil then
          if reaper.TakeIsMIDI(take) ==  true then   
            retval, notecntOut, ccevtcntOut = reaper.MIDI_CountEvts(take)
              if notecntOut ~= nil then
                for j = 1, notecntOut, 1 do                 
                  retval, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote(take, j-1) 
                  dest_note_pos = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)                                 
                  dest_notes_subt = {take_guid, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel, dest_note_pos}                   
                  table.insert(dest_notes_t, dest_notes_subt)  
                  if sel_notes_mode_values_at[1] == 1 then
                    if selectedOut == true then
                      table.insert(dest_notes_t2, dest_notes_subt)
                    end  
                  end
                  if sel_notes_mode_values_at[2] == 1 then
                    table.insert(dest_notes_t2, dest_notes_subt) 
                  end                  
                end -- count notes                   
              end -- notecntOut > 0
            end -- TakeIsMIDI
          end -- ref_take ~= nil 
        end-- ref_item ~= nil
      end -- for count_sel_ref_items
    end --   count_sel_ref_items > 0   
  return #dest_notes_t2
 end 
     
 ---------------------------------------------------------------------------------------------------------------

 function ENGINE2_get_dest_FORM_points()
 
   -- ONLY FOR GUI --
   
   dest_points_t = {} 
   
     -- items --
     if quantize_dest_values_t[1] == 1 and dest_items_t ~= nil then     
       for i = 1, #dest_items_t do
         table_temp_val_sub_t = dest_items_t[i]         
         table.insert (dest_points_t, i, {table_temp_val_sub_t[2], table_temp_val_sub_t[3]})         
       end
     end     
     
     -- sm --
     if quantize_dest_values_t[2] == 1 then     
       for i = 1, #dest_sm_t do
         table_temp_val = dest_sm_t[i]
         --take_guid, posOut, srcpos, item_pos, takerate         
         dest_sm = table_temp_val[4] + (table_temp_val[2]/table_temp_val[5])
         if sm_timesel_dest_values_t[1] == 1 then  table.insert (dest_points_t, {dest_sm, 1} )
           else 
             if dest_sm > timesel_st and dest_sm<timesel_end then
               table.insert (dest_points_t, {dest_sm, 1} )
             end
           end
       end
     end     
     
     -- ep --
     if quantize_dest_values_t[3] == 1 then     
       for i = 1, #dest_ep_t do
         table_temp_val = dest_ep_t[i]
         -- istrackenvelope, track_guid, env_id, point_id, time, value, shape, tension, selected
         table.insert (dest_points_t, {table_temp_val[5], table_temp_val[6]})
       end
     end
     
     -- notes --
     if quantize_dest_values_t[4] == 1 then     
       for i = 1, #dest_notes_t do
         table_temp_val = dest_notes_t[i]
         -- take_guid, selectedOut, mutedOut, startppqpos, endppqpos, chan, pitch, vel, dest_note_pos
         if sel_notes_mode_values_at[1] == 1 then
           if table_temp_val[2] == true then
             table.insert (dest_points_t, {table_temp_val[9], table_temp_val[8]/127})
           end  
         end  
         if sel_notes_mode_values_at[2] == 1 then
           table.insert (dest_points_t, {table_temp_val[9], table_temp_val[8]/127})
         end           
       end
     end       
 end 
 
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
 function ENGINE3_quantize_compare_sub(pos, vol, points_t)
 
      if points_t ~= nil then        
        for i = 1, #points_t do
                
          cur_ref_point_subt = points_t[i]          
          if i < #points_t then next_ref_point_subt = points_t[i+1] else next_ref_point_subt = nil end      
          
        -- perform comparison
        
          if snap_dir_values_t[1] == 1 then -- if snap to prev point
            if pos < cur_ref_point_subt[1] and i == 1 then 
              newval2 = {pos,vol} end
            if next_ref_point_subt ~= nil then if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1]  then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end end
            if pos > cur_ref_point_subt[1] and next_ref_point_subt == nil then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
          end   
                             
          if snap_dir_values_t[2] == 1 then -- if snap to closest point
            if pos < cur_ref_point_subt[1] and i == 1 then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
            if next_ref_point_subt ~= nil then   
              if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1] and pos < cur_ref_point_subt[1] + (next_ref_point_subt[1] - cur_ref_point_subt[1])/2 then 
                newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
              if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1] and pos > cur_ref_point_subt[1] + (next_ref_point_subt[1] - cur_ref_point_subt[1])/2 then 
                newval2 = {next_ref_point_subt[1],next_ref_point_subt[2]} end
            end  
            if pos > cur_ref_point_subt[1] and next_ref_point_subt == nil then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end
          end
        
          if snap_dir_values_t[3] == 1 then -- if snap to next point
            if pos < cur_ref_point_subt[1] and i == 1 then 
              newval2 = {cur_ref_point_subt[1],cur_ref_point_subt[2]} end            
            if next_ref_point_subt ~= nil then if pos > cur_ref_point_subt[1] and pos < next_ref_point_subt[1] then 
              newval2 = {next_ref_point_subt[1],next_ref_point_subt[2]} end   end   
            if pos > cur_ref_point_subt[1] and next_ref_point_subt == nil then 
              newval2 = {pos,vol} end 
          end
        
        end -- for
      end -- if ref_point_t~= nil
      return newval2
   end   
      
 ---------------------------------------------------------------------------------------------------------------       
 
  function ENGINE3_quantize_compare(pos,vol)    
    newval = nil
    if snap_area_values_t[1] == 1 then -- if use gravity      
      pos_gravity_min = pos - gravity_mult_value*gravity_value if pos_gravity_min < 0 then pos_gravity_min = 0 end
      pos_gravity_max = pos + gravity_mult_value*gravity_value
      ref_points_t2 = {} -- store all points which is placed inside gravity area
      if ref_points_t ~= nil then        
        for i = 1, #ref_points_t do      
          cur_ref_point_subt = ref_points_t[i]
          if cur_ref_point_subt[1] >= pos_gravity_min and cur_ref_point_subt[1] <= pos_gravity_max then
            table.insert(ref_points_t2, {cur_ref_point_subt[1],cur_ref_point_subt[2]})
          end
        end
      end  
      if ref_points_t2 ~= nil and #ref_points_t2 >= 1 then
        newval = ENGINE3_quantize_compare_sub (pos,vol,ref_points_t2)
      end
    end
    
    if snap_area_values_t[2] == 1 then -- if snap everything
      newval = ENGINE3_quantize_compare_sub (pos,vol,ref_points_t)
    end -- if snap everything
    
    if newval ~= nil then 
      pos_ret = newval[1] 
      pos_ret = pos - (pos - newval[1]) * strenght_value
      if newval[2] ~= nil then 
        vol_ret = newval[2] 
        vol_ret = vol - (vol - newval[2]) * use_vel_value
       else
        vol_ret = vol
      end  
     else 
      pos_ret = pos
      vol_ret = vol  
    end
    return pos_ret, vol_ret
  end
     
 ---------------------------------------------------------------------------------------------------------------
  
  function ENGINE3_quantize_objects()    
--  reaper.APITest()
    -------------------------------------------------------------------------------------
    --  items --------------------------------------------------------------------------
    -------------------------------------------------------------------------------------
    if quantize_dest_values_t[1] == 1 then 
    
     --  restore items pos and vol --
      if dest_items_t ~= nil then
        for i = 1, #dest_items_t do
          dest_items_subt = dest_items_t[i]
          item = reaper.BR_GetMediaItemByGUID(0, dest_items_subt[1])
          if item ~= nil then
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", dest_items_subt[2])
            reaper.SetMediaItemInfo_Value(item, "D_VOL", dest_items_subt[3])
          end
        end
      end      
      -- quantize items pos and vol --
      if dest_items_t ~= nil and restore_button_state == false then
        for i = 1, #dest_items_t do
          dest_items_subt = dest_items_t[i]
          item = reaper.BR_GetMediaItemByGUID(0, dest_items_subt[1])
          if item ~= nil then
            item_newpos, item_newvol = ENGINE3_quantize_compare(dest_items_subt[2],dest_items_subt[3])
            reaper.SetMediaItemInfo_Value(item, "D_POSITION", item_newpos)
            reaper.SetMediaItemInfo_Value(item, "D_VOL", item_newvol)
          end
         -- reaper.UpdateItemInProject(item)
        end
      end
    end -- if quantize items  
    
    -----------------------------------------------------------------------------
    -- stretch markers ----------------------------------------------------------
    -----------------------------------------------------------------------------
    if quantize_dest_values_t[2] == 1 then 
    --dest sm
    --1take_guid, 2posOut, 3srcpos, 4item_pos, 5takerate, 6item_len
    
    --restore
      --delete all in current take
      --insert from table
    --apply in bypass is off
      --delete all in current take
      --quantize when inserting from table
      --  delete notes from dest takes --
      
    -- restore  
      ENGINE3_restore_dest_sm() 
      
      --quant stretch markers    
      if dest_sm_t ~= nil and restore_button_state == false then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          if take ~= nil then  
            count_sm = reaper.GetTakeNumStretchMarkers(take)
            if count_sm ~= nil then
              for j = 1 , count_sm do
                reaper.DeleteTakeStretchMarkers(take, j)
              end
            end            
          end  
        end
      end
         
      if dest_sm_t ~= nil and restore_button_state == false then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          if take ~= nil then 
            item = reaper.GetMediaItemTake_Item(take)
            --1take_guid, 2posOut, 3srcpos, 4item_pos, 5takerate, 6item_len,7takeoffset
            reaper.SetMediaItemTakeInfo_Value(take, 'D_PLAYRATE', dest_sm_subt[5])
            reaper.SetTakeStretchMarker(take, -1, 0, dest_sm_subt[7])
            true_sm_pos = dest_sm_subt[4] + dest_sm_subt[2]/ dest_sm_subt[5]
            if sm_timesel_dest_values_t[1] == 1 then            
              new_sm_pos = ENGINE3_quantize_compare(true_sm_pos,0)
             else
              if true_sm_pos>timesel_st and true_sm_pos<timesel_end then
                new_sm_pos = ENGINE3_quantize_compare(true_sm_pos,0)
               else
                new_sm_pos = true_sm_pos
              end
            end
            new_sm_pos_rev = (new_sm_pos - dest_sm_subt[4])*dest_sm_subt[5] 
            if new_sm_pos_rev > 0 and new_sm_pos_rev < dest_sm_subt[6] then 
            
              if sm_is_transients_t[1] == 0 then
                reaper.SetTakeStretchMarker(take, -1, new_sm_pos_rev, dest_sm_subt[3]) 
               else
                reaper.UpdateItemInProject(item)
                d = 0.05
                reaper.SetTakeStretchMarker(take, -1, new_sm_pos_rev-d, dest_sm_subt[3]-d)
                reaper.SetTakeStretchMarker(take, -1, new_sm_pos_rev, dest_sm_subt[3])
                reaper.SetTakeStretchMarker(take, -1, new_sm_pos_rev+d, dest_sm_subt[3]+d)
                reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[6]*dest_sm_subt[5], dest_sm_subt[7]+dest_sm_subt[6]*dest_sm_subt[5])
              end
                          
            end
            reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[6]*dest_sm_subt[5], dest_sm_subt[7]+dest_sm_subt[6]*dest_sm_subt[5])
            reaper.UpdateItemInProject(item)
          end--take not nil 
          -- 
          --
        end -- for loop
      end --dest_sm_t ~= nil and restore_button_state == false
      
    end -- if stretch markers
    -----------------------------------------------------------------------------
    -- points -------------------------------------------------------------------
    -----------------------------------------------------------------------------
    
    if quantize_dest_values_t[3] == 1 then 
      --  restore point pos and val --
      if dest_ep_t ~= nil then
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          -- 1 is_track_env, 2 guid, 3 env_id, 4 point_id, 5 time, 6 value, 7 shape, 8 tension, 9  selected
          if dest_ep_subt[1] == true then -- if point of track envelope
            track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) end  end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) end end
          if  TrackEnvelope ~= nil then
            reaper.SetEnvelopePoint(TrackEnvelope, dest_ep_subt[4]-1, dest_ep_subt[5], dest_ep_subt[6], 
            dest_ep_subt[7], dest_ep_subt[8], dest_ep_subt[9], true)   
          end         
        end
        -- sort envelopes
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          if dest_ep_subt[1] == true then track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) reaper.Envelope_SortPoints (TrackEnvelope) end end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) reaper.Envelope_SortPoints(TrackEnvelope) end end          
        end  
      end   
      -- quantize envpoints pos and values --
      if dest_ep_t ~= nil and restore_button_state == false then
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          -- 1 is_track_env, 2 guid, 3 env_id, 4 point_id, 5 time, 6 value, 7 shape, 8 tension, 9  selected
          if dest_ep_subt[1] == true then -- if point of track envelope
            track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) end  end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) end end
          if  TrackEnvelope ~= nil then              
            ep_newpos, ep_newvol = ENGINE3_quantize_compare(dest_ep_subt[5], dest_ep_subt[6])
            reaper.SetEnvelopePoint(TrackEnvelope, dest_ep_subt[4]-1, ep_newpos, ep_newvol, 
            dest_ep_subt[7], dest_ep_subt[8], dest_ep_subt[9], true)
          end         
        end
      end  
      -- sort envelopes
        for i = 1, #dest_ep_t do
          dest_ep_subt = dest_ep_t[i]
          if dest_ep_subt[1] == true then track = reaper.BR_GetMediaTrackByGUID(0, dest_ep_subt[2])
            if track ~= nil then TrackEnvelope = reaper.GetTrackEnvelope(track, dest_ep_subt[3]-1) reaper.Envelope_SortPoints (TrackEnvelope) end end
          if dest_ep_subt[1] == false then -- if point of take envelope
            take = reaper.SNM_GetMediaItemTakeByGUID(0, dest_ep_subt[2])
            if take ~= nil then TrackEnvelope = reaper.GetTakeEnvelope(take, dest_ep_subt[3]-1) reaper.Envelope_SortPoints(TrackEnvelope) end end          
        end    
    end
    
    
    ----------------------------------------------------------------------------
    -- notes -------------------------------------------------------------------
    ----------------------------------------------------------------------------
    
    if quantize_dest_values_t[4] == 1 then 
    
      --RESTORE--
      
      --  delete notes from dest takes --
      if dest_notes_t ~= nil then
        for i = 1, #dest_notes_t do
          dest_notes_subt = dest_notes_t[i]
          --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos  
          take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
          if take ~= nil then          
            -- delete notes from take
            retval, notecnt = reaper.MIDI_CountEvts(take)
            if notecntOut ~= nil then
              for j = 1, notecnt do
                reaper.MIDI_DeleteNote(take, 0)
                reaper.MIDI_Sort(take)
              end
            end 
          end  
        end
      end       
      --insert notes
      if quantize_dest_values_t[4] == 1 then 
        --  Insert notes   --
        if dest_notes_t ~= nil then
          for i = 1, #dest_notes_t do
            dest_notes_subt = dest_notes_t[i]
            --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos  
            take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
            if take ~= nil then  
              reaper.MIDI_InsertNote(take, dest_notes_subt[2], dest_notes_subt[3], dest_notes_subt[4], dest_notes_subt[5], 
                dest_notes_subt[6], dest_notes_subt[7], dest_notes_subt[8], true)
            end 
            reaper.MIDI_Sort(take)
          end           
        end       
      end       
      
      --END RESTORE notes--
    if dest_notes_t ~= nil and restore_button_state == false then
      --  delete notes from dest takes --
      if dest_notes_t ~= nil then
        for i = 1, #dest_notes_t do
          dest_notes_subt = dest_notes_t[i]
          --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos  
          take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
          if take ~= nil then          
            -- delete notes from take
            retval, notecnt = reaper.MIDI_CountEvts(take)
            if notecntOut ~= nil then
              for j = 1, notecnt do
                reaper.MIDI_DeleteNote(take, 0)
                reaper.MIDI_Sort(take)
              end
            end 
          end  
        end
      end  
      --insert
      for i = 1, #dest_notes_t do
        dest_notes_subt = dest_notes_t[i]
        --1take_guid, 2selectedOut, 3mutedOut, 4startppqpos, 5endppqpos, 6chan, 7pitch, 8vel, 9dest_note_pos ,10 1-based noteid    
        take = reaper.GetMediaItemTakeByGUID(0,dest_notes_subt[1])
        if take ~= nil then
          ppq_dif = dest_notes_subt[5] - dest_notes_subt[4]
          
          
          if sel_notes_mode_values_at[1] == 1 then
            if dest_notes_subt[2] == true then
              notes_newpos, notes_newvol = ENGINE3_quantize_compare(dest_notes_subt[9], dest_notes_subt[8]/127)
             else
              notes_newpos = dest_notes_subt[9]
              notes_newvol = dest_notes_subt[8]/127
            end 
          end
          if sel_notes_mode_values_at[2] == 1 then
            notes_newpos, notes_newvol = ENGINE3_quantize_compare(dest_notes_subt[9], dest_notes_subt[8]/127)
          end
          notes_newpos_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, notes_newpos)
          reaper.MIDI_InsertNote(take, dest_notes_subt[2], dest_notes_subt[3], notes_newpos_ppq, notes_newpos_ppq+ppq_dif, 
          dest_notes_subt[6], dest_notes_subt[7], math.ceil(notes_newvol*127), false)
          reaper.MIDI_Sort(take)
        end  
      end    
    end --dest_notes_t ~= nil and restore_button_state == false  
   end     --if quantize_dest_values_t[4] == 1 then 
   if last_LMB_state ~= true then
     reaper.Undo_OnStateChange('mpl QuantizeTool '..math.floor(strenght_value*100)..'%') end
   --reaper.UpdateArrange()
  end -- func
  
        
 ---------------------------------------------------------------------------------------------------------------  
 
 function ENGINE3_restore_dest_sm(sm_timesel_bool,to1x)
    -- restore  
      if dest_sm_t ~= nil then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          if take ~= nil then  
            count_sm = reaper.GetTakeNumStretchMarkers(take)
            if count_sm ~= nil then
              for j = 1 , count_sm do
                reaper.DeleteTakeStretchMarkers(take, j)
              end
            end            
          end  
        end
      end   
      if dest_sm_t ~= nil then
        for i = 1, #dest_sm_t do
          dest_sm_subt = dest_sm_t[i]  
          take = reaper.GetMediaItemTakeByGUID(0,dest_sm_subt[1])
          reaper.SetMediaItemTakeInfo_Value(take, 'D_PLAYRATE', dest_sm_subt[5])
          if take ~= nil then  
            if sm_timesel_bool ~= nil and sm_timesel_bool then
              if dest_sm_subt[2]+dest_sm_subt[4] > timesel_st and 
                dest_sm_subt[2]+dest_sm_subt[4] < timesel_end then 
                 reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[3]-dest_sm_subt[7], dest_sm_subt[3]) 
                else
                 reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[2], dest_sm_subt[3])                              
              end
             else
              if to1x ~= nil and to1x then
                reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[3]-dest_sm_subt[7], dest_sm_subt[3])            
               else
                reaper.SetTakeStretchMarker(take, -1, dest_sm_subt[2], dest_sm_subt[3])            
              end  
            end  
          end  
        end
      end 
     -- reaper.UpdateArrange()  
    end 

 ---------------------------------------------------------------------------------------------------------------    
  function ENGINE3_sync_items_to_points()    
    if ref_points_t ~= nil then
      for i =1, #ref_points_t do
        ref_points_subt = ref_points_t[i]
        if dest_items_t ~= nil and i <= #dest_items_t then
          dest_items_subt = dest_items_t[i]
          if dest_items_subt ~= nil then
            item = reaper.BR_GetMediaItemByGUID(0, dest_items_subt[1])
            if item ~= nil then
              reaper.SetMediaItemInfo_Value(item, "D_POSITION", ref_points_subt[1])
            end
            reaper.UpdateItemInProject(item)
          end        
        end          
      end
    end
  end
 
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------      
 function ENGINE4_save_groove_as_rgt()
   if ref_points_t2 ~= nil then
     rgt_t = {}
     --form_return_lines
     rgt_t[1] = "Version: 0"
     rgt_t[2] = "Number of beats in groove: "..pattern_len*4
     rgt_t[3] = "Groove: "..#ref_points_t2.." positions"
     rgt_t[4] = "1e-007"
     for i = 2, #ref_points_t2 do
        rgt_t_item = ref_points_t2[i]
        rgt_t_item = tostring(math.round(rgt_t_item[1], 10))
        
        table.insert(rgt_t, rgt_t_item)
     end
     
     --write file
     retval, ret_groove_user_input = reaper.GetUserInputs("Save groove", 1, "Name of groove", "")
     if retval ~= nil or ret_groove_user_input ~= "" then     
       ret_filename = exepath.."/Grooves/"..ret_groove_user_input..".rgt"
       
       file = io.open(ret_filename,"w")   
       if   file~= nil then  
         for i = 1, #rgt_t do file:write(rgt_t[i].."\n") end
         file:close()
       end         
     end       
   end
 end
 
 ---------------------------------------------------------------------------------------------------------------
 function ENGINE4_store_groove_to_item()
   if ref_points_t2 ~= nil then
     tr_count = reaper.GetNumTracks()
     reaper.InsertTrackAtIndex(tr_count, true)
     reaper.TrackList_AdjustWindows(false)
     new_tr = reaper.GetTrack(0, tr_count)
     pattern_len_time = reaper.TimeMap2_beatsToTime(0, 0, pattern_len)
     new_item = reaper.CreateNewMIDIItemInProj(new_tr, 0, pattern_len_time)
     new_take = reaper.GetActiveTake(new_item)
     fng_take = reaper.FNG_AllocMidiTake(new_take)
     for i = 1, #ref_points_t2 do
       ref_points_t2_item = ref_points_t2[i]
       ref_points_t2_item_next = ref_points_t2[i+1]
       fng_note = reaper.FNG_AddMidiNote(fng_take)       
       new_pos_time = reaper.TimeMap2_beatsToTime(0, ref_points_t2_item[1])
       new_pos = math.floor(reaper.MIDI_GetPPQPosFromProjTime(new_take, new_pos_time))
       if new_pos ~= nil then
         reaper.FNG_SetMidiNoteIntProperty(fng_note, 'POSITION', new_pos)
         reaper.FNG_SetMidiNoteIntProperty(fng_note, 'VELOCITY', ref_points_t2_item[2]*127)
         reaper.FNG_SetMidiNoteIntProperty(fng_note, 'LENGTH', 120)
       end  
     end
     reaper.FNG_FreeMidiTake(fng_take)
     reaper.UpdateItemInProject(new_item)
   end
 end
 
 ---------------------------------------------------------------------------------------------------------------
 function ENGINE4_save_preset()
   settings_t = {}
   
   settings_t[1] = table.concat(snap_mode_values_t, "")
   settings_t[2] = table.concat(pat_len_values_t, "")
   settings_t[3] = table.concat(pat_edge_values_t, "")
   settings_t[4] = table.concat(use_vel_values_t, "")
   settings_t[5] = table.concat(sel_notes_mode_values_t, "")
   settings_t[6] = table.concat(sm_rel_ref_values_t, "")
   settings_t[7] = table.concat(sm_timesel_ref_values_t, "")
   settings_t[8] = table.concat(snap_area_values_t, "")
   settings_t[9] = table.concat(snap_dir_values_t, "")
   settings_t[10] = table.concat(swing_scale_values_t, "")
   settings_t[11] = table.concat(sel_notes_mode_values_at, "")   
   settings_t[12] = table.concat(sm_timesel_dest_values_t, "")  
      
   file = io.open(settings_filename,"w")        
   if file ~= nil then
     for i = 1, #settings_t do file:write(settings_t[i].."\n") end
     file:write("\n".."Configuration for mpl Quantize Tool".."\n".."If you`re not sure what is that, don`t modify this!".."\n".."\n")
     file:close()
     reaper.MB("Configuration saved successfully to "..exepath.."\\Scripts\\mpl_Quantize_Tool_settings.txt", "Preset saving", 0)
    else
      reaper.MB("Something goes wrong", "Preset saving", 0)
   end  
   
   
 end
 ---------------------------------------------------------------------------------------------------------------
 ---------------------------------------------------------------------------------------------------------------
   
  
  function MOUSE_LB_trigger(b, offset, selfstate, timer)
    local state
    if selfstate == nil then selfstate = false end
    if set_click_time == nil then set_click_time = 0 end
    if MOUSE_match_xy(b, offset) == true and LMB_state and not last_LMB_state and selfstate == false and cur_time - set_click_time > timer then 
      set_click_time = cur_time
      state = true
    end  
    return state
  end
    
   ---------------------------------------------------------------------------------------------------------------  
  function MOUSE_LB_toggle(b, offset, selfstate)
    local state
    if selfstate == nil then selfstate = false end
    if MOUSE_match_xy(b, offset) and LMB_state and not last_LMB_state then selfstate = not selfstate end
    return selfstate
  end
  
  
   ---------------------------------------------------------------------------------------------------------------  
  function MOUSE_LB_gate(b, offset)
    local state
    if not last_LMB_state and LMB_state and MOUSE_match_xy(b, offset) == true then 
      state = true    
     else 
      state = false  
    end
    return state
  end

  
 ---------------------------------------------------------------------------------------------------------------   
  function MOUSE_RB_gate(b, offset)
    local state
    if MOUSE_match_xy(b, offset) == true and RMB_state then 
      state = true    
     else 
      state = false  
    end
    return state
  end  
  
 ---------------------------------------------------------------------------------------------------------------   
  function MOUSE_MB_gate(b, offset)
    local state
    if MOUSE_match_xy(b, offset) == true and MMB_state then 
      state = true    
     else 
      state = false  
    end
    return state
  end    
  
   ---------------------------------------------------------------------------------------------------------------  
  function MOUSE_match_xy(b, offset)
    if    mx > b[1+offset] 
      and mx < b[1+offset]+b[3+offset]
      and my > b[2+offset]
      and my < b[2+offset]+b[4+offset] then
     return true 
    end 
  end
      
   --[[ get_ref_but_state = MOUSE_LB_toggle(get_ref_button_xywh_t,0, get_ref_but_self_state) 
    get_ref_but_self_state = not get_ref_but_state
    
    if get_ref_but_state == true then 
      ref_data_t = ENGINE1_get_item_data()
      ref_sm_t = ENGINE2_get_sm_from_item_data(ref_data_t[7]) -- from ref_com_t
    end 
    
        ]]
        
 --------------------------------------------------------------------------------------------------------------- 
  function menu_entry_ret(table, index)
    if table[index] == 1 then return "!" else return "" end
  end

  function menu_entry_ret2(table, index)
    if table[index] == 1 then return "#" else return "" end
  end
   
 --------------------------------------------------------------------------------------------------------------- 
  function MOUSE_get() 
    cur_time = os.clock()
    timer = 0.5
    LMB_state = gfx.mouse_cap&1 == 1 
    RMB_state = gfx.mouse_cap&2 == 2
    MMB_state = gfx.mouse_cap&64 == 64
    if LMB_state or RMB_state or MMB_state then MB_state =true else MB_state = false end
    
    if LMB_state or RMB_state or MMB_state then reaper.UpdateArrange() end
    
    if last_LMB_state == false then last_mouse_object = nil end
    
    if gfx.mouse_cap == 5 then Ctrl_state = true else Ctrl_state = false end
    mx, my = gfx.mouse_x, gfx.mouse_y  
    
    if last_MB_state and not MB_state then update_display = true end
    
   if project_grid_measures < 1 then   
       
       ------------------------------
       ----- GET REFERENCE MENU -----
       ------------------------------
       
     if snap_mode_values_t[2] == 1 then 
       --items
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,0) then 
         show_get_item = true else show_get_item = false end
       if MOUSE_LB_gate(get_item_button_xywh_t,0) then
         count_reference_item_positions = ENGINE1_get_reference_item_positions() end              
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,0) then 
         quantize_ref_values_t = {1, 0, 0, 0, 0, 0, 0} 
         ENGINE1_get_reference_FORM_points()end
       -- sm  
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,4) then 
         show_get_sm = true else show_get_sm = false end
       if MOUSE_LB_gate(get_sm_button_xywh_t,0) then
         count_reference_sm_positions = ENGINE1_get_reference_SM_positions() end              
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,4) then 
         quantize_ref_values_t = {0, 1, 0, 0, 0, 0, 0} 
         ENGINE1_get_reference_FORM_points() end
       -- ep  
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,8) then 
         show_get_ep = true else show_get_ep = false end
       if MOUSE_LB_gate(get_ep_button_xywh_t,0) then
          count_reference_ep_positions = ENGINE1_get_reference_EP_positions() end  
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,8) then 
         quantize_ref_values_t = {0, 0, 1, 0, 0, 0, 0} 
         ENGINE1_get_reference_FORM_points() end
       -- notes  
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,12) then 
         show_get_note = true else show_get_note = false end
       if MOUSE_LB_gate(get_note_button_xywh_t,0) then
           count_reference_notes_positions = ENGINE1_get_reference_notes_positions() end
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,12) then 
         quantize_ref_values_t = {0, 0, 0, 1, 0, 0, 0}          
         ENGINE1_get_reference_FORM_points() end  
         
       -- user groove--             
       if MOUSE_match_xy(usergroove_line_xywh_t,0) then show_groove_buttons = true else show_groove_buttons = false end
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,16) then 
         quantize_ref_values_t = {0, 0, 0, 0, 1, 0, 0} 
         ENGINE1_get_reference_FORM_points() end  
       if MOUSE_RB_gate(quantize_ref_xywh_buttons_t,16) or MOUSE_LB_gate(add_groove_button_xywh_t,0)then         
          if last_mouse_object=='groove_button' or
          last_mouse_object==nil then ENGINE1_get_reference_usergroove() 
          ENGINE1_get_reference_FORM_points() 
          last_mouse_object='groove_button' end end
       prev_groove_button = MOUSE_LB_trigger(prev_groove_button_xywh_t,0,prev_groove_button,0.5)   
       if prev_groove_button then
          ENGINE1_get_reference_usergroove(-1) 
          ENGINE1_get_reference_FORM_points()
          ENGINE3_quantize_objects() end   
       next_groove_button = MOUSE_LB_trigger(next_groove_button_xywh_t,0,next_groove_button,0.5)   
       if next_groove_button then
          ENGINE1_get_reference_usergroove(1) 
          ENGINE1_get_reference_FORM_points()
          ENGINE3_quantize_objects() end   
          
       -- grid --      
       if MOUSE_match_xy(grid_line_xywh_t, 0) then 
         show_grid_slider = true else 
         show_grid_slider = false end       
       if MOUSE_LB_gate(grid_value_slider_xywh_t, 0) then 
         last_mouse_object='grid_slider' end
       if last_mouse_object=='grid_slider' then  
         quantize_ref_values_t = {0, 0, 0, 0, 0, 1, 0}
         if grid_value_slider_xywh_t ~= nil then grid_value = (mx - grid_value_slider_xywh_t[1])/grid_value_slider_xywh_t[3] end
         ENGINE1_get_reference_grid()
         ENGINE1_get_reference_FORM_points() 
         ENGINE3_quantize_objects()         
       end
             -- (restore grid to project grid)
             if MOUSE_RB_gate(quantize_ref_xywh_buttons_t,20) or MOUSE_RB_gate(grid_value_slider_xywh_t, 0) then 
               quantize_ref_values_t = {0, 0, 0, 0, 0, 1, 0}
               grid_value = 0
               ENGINE1_get_reference_grid()
               ENGINE1_get_reference_FORM_points() 
               ENGINE3_quantize_objects()
             end     
       -- swing --
         if MOUSE_match_xy(swing_line_xywh_t,0) then 
           show_swing_slider = true else show_swing_slider = false end
         if MOUSE_LB_gate(swing_grid_value_slider_xywh_t,0)  then
           last_mouse_object='swing_slider' end
         if last_mouse_object=='swing_slider' then
            quantize_ref_values_t = {0, 0, 0, 0, 0, 0, 1} 
            if Ctrl_state == true then
              swing_value = swing_value+(((mx - swing_grid_value_slider_xywh_t[1])/swing_grid_value_slider_xywh_t[3])*2-1)*0.001
             else swing_value = ((mx - swing_grid_value_slider_xywh_t[1])/swing_grid_value_slider_xywh_t[3])*2-1 end
            if swing_value > 1 then   swing_value = 1 end
            if swing_value < -1 then   swing_value = -1 end
            ENGINE1_get_reference_swing_grid()
            ENGINE1_get_reference_FORM_points()
            ENGINE3_quantize_objects()
         end
          
             -- (type swing value)
             if MOUSE_RB_gate(quantize_ref_xywh_buttons_t,24) or MOUSE_RB_gate(swing_grid_value_slider_xywh_t, 0) 
              or MOUSE_LB_gate(type_swing_button_xywh_t,0) then
                if last_mouse_object == nil or  last_mouse_object == 'type_swing' then
                 swing_value_retval, swing_value_return_s =  reaper.GetUserInputs("Swing value", 1, "Swing", "") 
                 if swing_value_retval ~= nil then 
                   swing_value_return = tonumber(swing_value_return_s)           
                   if swing_value_return == nil then swing_value = 0 else swing_value = swing_value_return / 100 end       
                   if swing_value > 1 then swing_value = 1 end
                   if swing_value < -1 then swing_value = -1 end
                   ENGINE1_get_reference_swing_grid()
                   ENGINE1_get_reference_FORM_points()
                   last_mouse_object = 'type_swing'   
                   update_display = true                 
                 end 
               end  
             end -- rb mouse on swing   
             
             
     else -- if global mode (snap_mode_values_t[1] == 1)
       
       --items
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,0) then 
         show_get_item = true else show_get_item = false end
       if MOUSE_LB_gate(get_item_button_xywh_t,0) then
         count_reference_item_positions = ENGINE1_get_reference_item_positions() end              
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,0) then 
         quantize_ref_values_t = {1, 0, 0, 0} 
         ENGINE1_get_reference_FORM_points()end
       -- sm  
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,4) then 
         show_get_sm = true else show_get_sm = false end
       if MOUSE_LB_gate(get_sm_button_xywh_t,0) then
         count_reference_sm_positions = ENGINE1_get_reference_SM_positions() end              
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,4) then 
         quantize_ref_values_t = {0, 1, 0, 0} 
         ENGINE1_get_reference_FORM_points() end
       -- ep  
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,8) then 
         show_get_ep = true else show_get_ep = false end
       if MOUSE_LB_gate(get_ep_button_xywh_t,0) then
          count_reference_ep_positions = ENGINE1_get_reference_EP_positions() end  
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,8) then 
         quantize_ref_values_t = {0, 0, 1, 0} 
         ENGINE1_get_reference_FORM_points() end
       -- notes  
       if MOUSE_match_xy(quantize_ref_xywh_buttons_t,12) then 
         show_get_note = true else show_get_note = false end
       if MOUSE_LB_gate(get_note_button_xywh_t,0) then
           count_reference_notes_positions = ENGINE1_get_reference_notes_positions() end
       if MOUSE_LB_gate(quantize_ref_xywh_buttons_t,12) then 
         quantize_ref_values_t = {0, 0, 0, 1}          
         ENGINE1_get_reference_FORM_points() end  
         
         
     end -- for reference menu items depending on mode
            
             
       ------------------------------
       -------- GET DEST MENU -------
       ------------------------------
       -- items
       if MOUSE_LB_gate(quantize_dest_xywh_buttons_t,0) then 
         quantize_dest_values_t = {1, 0, 0, 0} 
         count_dest_item_positions = ENGINE2_get_dest_items() 
         ENGINE2_get_dest_FORM_points() 
         ENGINE1_get_reference_FORM_points() end
       -- sm  
       if MOUSE_LB_gate(quantize_dest_xywh_buttons_t,4) then 
         quantize_dest_values_t = {0, 1, 0, 0} 
         count_dest_sm_positions = ENGINE2_get_dest_sm() 
         ENGINE2_get_dest_FORM_points() 
         ENGINE1_get_reference_FORM_points() 
         end
       -- ep  
       if MOUSE_LB_gate(quantize_dest_xywh_buttons_t,8) then 
         quantize_dest_values_t = {0, 0, 1, 0} 
         count_dest_ep_positions = ENGINE2_get_dest_ep()  
         ENGINE2_get_dest_FORM_points()
         ENGINE1_get_reference_FORM_points() end
       -- notes  
       if MOUSE_LB_gate(quantize_dest_xywh_buttons_t,12) then 
         quantize_dest_values_t = {0, 0, 0, 1} 
         count_dest_notes_positions = ENGINE2_get_dest_notes() 
         ENGINE2_get_dest_FORM_points() 
         ENGINE1_get_reference_FORM_points()end 
       
       ------------------------------
       -----------SLIDERS------------
       ------------------------------
       if use_vel_slider_xywh_t ~= nil and use_vel_values_t[1] == 1 then
         if MOUSE_LB_gate(use_vel_slider_xywh_t,0) then
           last_mouse_object = 'use_vel' end
         if   last_mouse_object == 'use_vel' then
           use_vel_value = (mx - use_vel_slider_xywh_t[1])/use_vel_slider_xywh_t[3]*2 
           if use_vel_value > 1 then use_vel_value = 1 end
           if use_vel_value < 0 then use_vel_value = 0 end
           ENGINE3_quantize_objects()
         end                    
       end  
              
       if gravity_slider_xywh_t ~= nil and snap_area_values_t[1] == 1 then
         if MOUSE_LB_gate(gravity_slider_xywh_t,0) == true then 
           last_mouse_object = 'gravity' end
         if last_mouse_object == 'gravity' then  
           if Ctrl_state == true then 
               gravity_value = gravity_value + ((mx - gravity_slider_xywh_t[1])/gravity_slider_xywh_t[3]*2-1)*0.001
             else gravity_value = (mx - gravity_slider_xywh_t[1])/gravity_slider_xywh_t[3]*2 end 
           if gravity_value > 1 then gravity_value = 1 end
           if gravity_value < 0 then gravity_value = 0 end
           ENGINE3_quantize_objects()
         end 
         if MOUSE_LB_gate(type_gravity_button_xywh_t,0) or MOUSE_RB_gate(gravity_slider_xywh_t,0) == true then 
           gravity_value_retval, gravity_value_return_s =  reaper.GetUserInputs("Gravity value", 1, "Gravity, ms", "") 
           if gravity_value_retval ~= nil then 
              gravity_value_return = tonumber(gravity_value_return_s)
              if gravity_value_return == nil then gravity_value = 0 else 
                gravity_value = gravity_value_return / 1000 / gravity_mult_value
                ENGINE3_quantize_objects()
              end
           end
         end
        end       
       
       
       ------------------------------
       --- APPLY BUTTON / SLIDER ----
       ------------------------------  
       
       -- set LB
       if MOUSE_LB_gate(apply_slider_xywh_t,0) then 
         last_mouse_object = 'apply' end
       if last_mouse_object == 'apply' then  
         strenght_value = (mx - apply_slider_xywh_t[1])/apply_slider_xywh_t[3]/0.7-0.2
         if strenght_value >1 then strenght_value = 1 end      
         if strenght_value <0 then strenght_value = 0 end           
         ENGINE3_quantize_objects()
       end        
       -- restore  RB   
       if MOUSE_RB_gate(apply_slider_xywh_t,0) or MOUSE_LB_gate(restore_button_xywh_t, 0 )then 
         restore_button_state = true 
         ENGINE3_quantize_objects()
        else  
         restore_button_state = false 
       end
       
       -- type MB  
       if MOUSE_MB_gate(apply_slider_xywh_t,0) then      
         strenght_value_retval, strenght_value_return_s =  reaper.GetUserInputs("Strenght value", 1, "Strenght (%)", "") 
         if strenght_value_retval ~= nil then 
           strenght_value_return = tonumber(strenght_value_return_s) 
           if strenght_value_return ~= nil then       
             strenght_value = strenght_value_return/100
             if math.abs(strenght_value) >1 then strenght_value = 1 end       
             ENGINE3_quantize_objects()           
           end
         end    
       end    
        
       -------------------------
       -------- OPTIONS --------
       -------------------------        
       
       -- reference side --
                
       actions_menu_t={'#Actions:',
                 'Save current pattern as .rgt groove',
                 'Create MIDI item on new track from current groove|'}
       snap_ref_menu_t = {'#Reference settings:',
                           menu_entry_ret(snap_mode_values_t, 1)..'Mode: Global mode',
                           menu_entry_ret(snap_mode_values_t, 2)..'Mode: Pattern mode|',
                           menu_entry_ret(pat_len_values_t,1)..'Pattern length: 1 bar',
                           menu_entry_ret(pat_len_values_t,2)..'Pattern length: 2 bars',
                           menu_entry_ret(pat_len_values_t,3)..'Pattern length: 4 bars|',
                           menu_entry_ret(pat_edge_values_t,1)..'Enable pattern edges|',
                           menu_entry_ret(use_vel_values_t,1)..'Use Velocity / Gain / Envelope Values|',
                           menu_entry_ret(sel_notes_mode_values_t,1)..'Get only selected notes from MIDI item|',
                           menu_entry_ret(sm_rel_ref_values_t,1)..'Str.markers positions: Bar relative',
                           menu_entry_ret(sm_rel_ref_values_t,2)..'Str.markers positions: Item relative|',
                           menu_entry_ret(sm_timesel_ref_values_t,2)..'Get str. markers only within time selection|'}
       
                 
       menu_t = {}
       table.insert(menu_t, table.concat(actions_menu_t, "|")) 
       table.insert(menu_t, table.concat(snap_ref_menu_t, "|")) 
       if MOUSE_LB_gate(options2_button_xywh_t,0) and last_mouse_object == nil or 
        MOUSE_LB_gate(options2_button_xywh_t,0) and last_mouse_object == 'left_menu' then
         last_mouse_object = 'left_menu'
         menu_string = table.concat(menu_t, "|")
         gfx.x, gfx.y = mx, my 
         menu_ret = gfx.showmenu(menu_string)
                  
         ------------------------------------------  
         if menu_ret == 2 then ENGINE4_save_groove_as_rgt() end 
         if menu_ret == 3 then ENGINE4_store_groove_to_item() end 
         
         -- 1 + #actions_menu_t snap dest settings  
         if menu_ret == 2 + #actions_menu_t then -- set global mode
           snap_mode_values_t = {1, 0}
           quantize_ref_values_t = {quantize_ref_values_t[1], quantize_ref_values_t[2], quantize_ref_values_t[3], quantize_ref_values_t[4]} 
           ENGINE1_get_reference_FORM_points() end  
         if menu_ret == 3 + #actions_menu_t then -- set pattern mode 
           snap_mode_values_t = {0, 1} 
           quantize_ref_values_t = {quantize_ref_values_t[1], quantize_ref_values_t[2], quantize_ref_values_t[3], quantize_ref_values_t[4], 0, 0} 
           ENGINE1_get_reference_FORM_points() end

         if menu_ret == 4 + #actions_menu_t then -- pat len 1 bar
           pat_len_values_t = {1, 0, 0} ENGINE1_get_reference_FORM_points() end
         if menu_ret == 5 + #actions_menu_t then -- pat len 2 bar
           pat_len_values_t = {0, 1, 0} ENGINE1_get_reference_FORM_points() end
         if menu_ret == 6 + #actions_menu_t then -- pat len 4 bar
           pat_len_values_t = {0, 0, 1} ENGINE1_get_reference_FORM_points() end   
           
         if menu_ret == 7 + #actions_menu_t then  -- toogle pat edges                      
           if pat_edge_values_t[2] == 1 then pat_edge_values_t = {1, 0} ENGINE1_get_reference_FORM_points() 
            else pat_edge_values_t = {0, 1} ENGINE1_get_reference_FORM_points() end end
         
         if menu_ret == 8 + #actions_menu_t then  -- use velocity
           if use_vel_values_t[2] == 1 then use_vel_values_t = {1, 0}  
            else use_vel_values_t = {0, 1}  end end
                     
         if menu_ret == 9 + #actions_menu_t then  -- get only selected notes
           if sel_notes_mode_values_t[2] == 1 then 
             sel_notes_mode_values_t = {1, 0} ENGINE1_get_reference_FORM_points()
            else 
             sel_notes_mode_values_t = {0, 1} ENGINE1_get_reference_FORM_points() end end
         
         if menu_ret == 10 + #actions_menu_t then -- str markers bar/item relative
           sm_rel_ref_values_t = {1, 0} ENGINE1_get_reference_FORM_points() end
         if menu_ret == 11 + #actions_menu_t then -- str markers bar/item relative
                    sm_rel_ref_values_t = {0, 1} ENGINE1_get_reference_FORM_points() end
         
         if menu_ret == 12 + #actions_menu_t then -- all markers/timesel
           if sm_timesel_ref_values_t[1] == 1 then 
             sm_timesel_ref_values_t = {0, 1} ENGINE1_get_reference_FORM_points() 
            else sm_timesel_ref_values_t = {1, 0} ENGINE1_get_reference_FORM_points() end end
        end -- options menu click
        
       ---------------------------------------------------------------
       
       --dest side         
                
       actions1_menu_t={'#Actions:',
                         'Reset stored stretch markers to 1.0x',
                         'Reset stored stretch markers to 1.0x in time selection',
                         menu_entry_ret2(snap_mode_values_t, 2)..'Sync stored items positions to reference points|'}
       snap_dest_menu_t = {'#Quantize settings:',
                           menu_entry_ret(snap_area_values_t, 1)..'Use Gravity Area|',
                           menu_entry_ret(snap_dir_values_t,1)..'Snap direction: to previous ref.point',
                           menu_entry_ret(snap_dir_values_t,2)..'Snap direction: to closest ref.point',
                           menu_entry_ret(snap_dir_values_t,3)..'Snap direction: to next ref.point|',
                           menu_entry_ret(swing_scale_values_t,1)..'Swing 100% is next grid|',
                           menu_entry_ret(sel_notes_mode_values_at,1)..'Quantize only selected notes in MIDI item|',
                           menu_entry_ret(sm_timesel_dest_values_t,2)..'Quantize only str. markers only within time selection|'}
                           --menu_entry_ret(sm_is_transients_t,1)..'Quantize stretch marker area (could BREAK your project!)'}
                           
       
                 
       menu_t2 = {}
       table.insert(menu_t2, table.concat(actions1_menu_t, "|")) 
       table.insert(menu_t2, table.concat(snap_dest_menu_t, "|")) 
       if MOUSE_LB_gate(options_button_xywh_t,0) or MOUSE_RB_gate(options_button_xywh_t,0) then
         menu_string2 = table.concat(menu_t2, "|")
         gfx.x, gfx.y = mx, my 
         menu_ret2 = gfx.showmenu(menu_string2)
         
         if menu_ret2 == 2 then -- reset str.markers to 1.0
           ENGINE3_restore_dest_sm(false,true) 
           reaper.Undo_OnStateChange('mpl QT reset str.markers')
           end
         if menu_ret2 == 3 then -- reset str.markers to 1.0 in timesel
           ENGINE3_restore_dest_sm(true,true) 
           reaper.Undo_OnStateChange('mpl QT reset str.markers in timesel') end           
         if menu_ret2 == 4 and snap_mode_values_t[1] == 1 then -- sync item pos
           ENGINE3_sync_items_to_points() end
           
           
         if menu_ret2 == 2 + #actions1_menu_t then -- use gravity
           if snap_area_values_t[2]==1 then snap_area_values_t = {1, 0} ENGINE3_quantize_objects()
            else snap_area_values_t = {0, 1} ENGINE3_quantize_objects() end end
            
         if menu_ret2 == 3 + #actions1_menu_t then   -- to prev point
           snap_dir_values_t = {1,0,0} ENGINE3_quantize_objects() end
         if menu_ret2 == 4 + #actions1_menu_t then   -- to closest point
           snap_dir_values_t = {0,1,0} ENGINE3_quantize_objects() end
         if menu_ret2 == 5 + #actions1_menu_t then   -- to next point
           snap_dir_values_t = {0,0,1} ENGINE3_quantize_objects() end                       
            
         if menu_ret2 == 6 + #actions1_menu_t then -- 1.0x or 0.5(reaper) swing scale
           if  swing_scale_values_t[1] == 1 then
             swing_scale_values_t = {0,1} swing_scale = 0.5 ENGINE3_quantize_objects() 
             else swing_scale_values_t = {1,0} swing_scale = 1 ENGINE3_quantize_objects() end end
         
         if menu_ret2 == 7 + #actions1_menu_t then -- quant sel notes/all notes
           if sel_notes_mode_values_at[1]==1 then
             sel_notes_mode_values_at = {0, 1} ENGINE3_quantize_objects()     
            else sel_notes_mode_values_at = {1, 0} ENGINE3_quantize_objects() end end
            
         if menu_ret2 == 8 + #actions1_menu_t then -- all markers/timesel
           if sm_timesel_dest_values_t[1] == 1 then 
             sm_timesel_dest_values_t = {0, 1} ENGINE3_quantize_objects() 
            else sm_timesel_dest_values_t = {1, 0} ENGINE3_quantize_objects() end end
            
         if menu_ret2 == 9 + #actions1_menu_t then   
            if sm_is_transients_t[1] == 0 then sm_is_transients_t = {1} else
              sm_is_transients_t[1] = 0 end end
             
            
       end -- mouse click on menu
       -----------------------------------------------------------  
       
       -- top menu
       menu_t3 = {'About',
                   'ChangeLog',
                   'Cockos Wiki help page',
                   "GitHub (old versions and related scripts)",
                   'Donate (paypal.me)|',
                   menu_entry_ret(enable_display_t,1)..'Enable display|'}
       if MOUSE_LB_gate(options3_button_xywh_t,0) or MOUSE_RB_gate(options3_button_xywh_t,0) then
         menu_string3 = table.concat(menu_t3, "|")
         gfx.x, gfx.y = mx, my 
         menu_ret3 = gfx.showmenu(menu_string3)
         if menu_ret3 == 1 then --
           reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(about) end     
         if menu_ret3 == 2 then 
           reaper.ShowConsoleMsg("") reaper.ShowConsoleMsg(changelog) end
         if menu_ret3 == 3 then 
           open_URL("http://wiki.cockos.com/wiki/index.php/Quantize_tool_by_mpl")end  
         if menu_ret3 == 4 then 
           open_URL("http://github.com/MichaelPilyavskiy/ReaScripts/tree/master/Tools") end    
         if menu_ret3 == 5 then 
           open_URL("http://paypal.me/donate2mpl") end  
         if menu_ret3 == 6 then 
           if enable_display_t[1] == 1 then enable_display_t={0} else enable_display_t={1} end end
       end   -- mouse click on menu3
               
        --[[# : grayed out
! : checked
> : this menu item shows a submenu
< : last item in the current submenu]]

   end -- if snap >1
   last_LMB_state = LMB_state
   last_RMB_state = RMB_state
   last_MMB_state = MMB_state
   if last_LMB_state or last_RMB_state or last_MMB_state then last_MB_state = true else last_MB_state = false end
 end
        
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
function EXT_get_sub(key, last_value_s)
  if reaper.HasExtState("mplQT_settings", key) == true then
    value_s = reaper.GetExtState("mplQT_settings", key)         
    if last_value_s == nil then last_value_s = ""  end
    if value_s ~= last_value_s then
      value_ret = tonumber(value_s)    
      last_value_s_ret = value_s
      is_apply = true
      local value = value_ret
     else
      is_apply = false
    end  
  end 
  return last_value_s_ret, value_ret, is_apply
end

---------------------------------------------------------------------------------------------------------------
function EXT_get()
  if last_strenght_value_s_ret == nil then first_time_st = true else first_time_st = false end
  last_strenght_value_s_ret, strenght_value_ret, is_apply_strenght = EXT_get_sub("Strenght", last_strenght_value_s)
  if strenght_value_ret ~= nil and is_apply_strenght == true then 
    strenght_value = strenght_value_ret 
    last_strenght_value_s = last_strenght_value_s_ret
    if first_time_st == false then
      ENGINE3_quantize_objects() 
    end  
  end
  
  if last_swing_value_s_ret == nil then first_time_sw = true else first_time_sw = false end
  last_swing_value_s_ret, swing_value_ret, is_apply_swing = EXT_get_sub("Swing", last_swing_value_s)
  if swing_value_ret ~= nil and is_apply_swing == true then 
    swing_value = swing_value_ret 
    last_swing_value_s = last_swing_value_s_ret
    if first_time_sw == false then
      snap_mode_values_t = {0,1} 
      quantize_ref_values_t = {0, 0, 0, 0, 0, 0, 1}
      ENGINE1_get_reference_swing_grid()
      ENGINE1_get_reference_FORM_points()
      ENGINE3_quantize_objects() 
    end  
  end

  if last_grid_value_s_ret == nil then first_time_grid = true else first_time_grid = false end
  last_grid_value_s_ret, grid_value_ret, is_apply_grid = EXT_get_sub("Grid", last_grid_value_s)
  if grid_value_ret ~= nil and is_apply_grid == true then 
    grid_value = grid_value_ret 
    last_grid_value_s = last_grid_value_s_ret
    if first_time_grid == false then    
      snap_mode_values_t = {0,1} 
      quantize_ref_values_t = {0, 0, 0, 0, 0, 1, 0}
      ENGINE1_get_reference_grid()
      ENGINE1_get_reference_FORM_points()
      ENGINE3_quantize_objects() 
    end  
  end  
end     


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

 function MAIN_exit()
   gfx.quit()
 end
 
 --------------------------------------------------------------------------------------------------------------- 
    
 function MAIN_run()      
   DEFINE_dynamic_variables()   
   GUI_DRAW()   
   MOUSE_get()  
   EXT_get()       
   test_var(test)
   char = gfx.getchar()  
   --ENGINE4_save_preset()
   if char == 32 then reaper.Main_OnCommandEx(40044, 0,0) end
   if char == 27 then MAIN_exit() end     
   if char ~= -1 then reaper.defer(MAIN_run) else MAIN_exit() end
 end 
 
 
 ---------------------------------------
 OS=reaper.GetOS()
 exepath = reaper.GetResourcePath()
 
   main_w = 440
   main_h = 355
   
   gfx.init("mpl Quantize tool // ".."Version "..vrs, main_w, main_h)
   reaper.atexit(MAIN_exit) 
   
   DEFINE_default_variables()
   DEFINE_default_variables_GUI() 
   
   MAIN_run()

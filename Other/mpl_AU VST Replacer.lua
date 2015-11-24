--  Michael Pilyavskiy AU VST Replacer --

fontsize  = 16
min_words_compare = 1
 
 
vrs = "1.1"
 
changelog =                   
[===[
            Changelog: 
20.11.2015  1.1
            check for AU plugins moved/renamed/deleted from original project
19.11.2015  1.0
            public release
            support for master track
            Log
            minimum words to compare option
19.11.2015  0.5
            replacing plugins + params
            matching names
18.11.2015  0.2 
            dump AU data to project  
            proper fonts on OSX      
15.11.2015  0.1 alpha 
]===]


about = 'AU VST Replacer by Michael Pilyavskiy'..'\n'..'Version '..vrs..'\n'..
[===[    
            Contacts:
   
            Soundcloud - http://soundcloud.com/mp57
            PromoDJ -  http://pdj.com/michaelpilyavskiy
            VK -  http://vk.com/michael_pilyavskiy         
            GitHub -  http://github.com/MichaelPilyavskiy/ReaScripts
            ReaperForum - http://forum.cockos.com/member.php?u=70694
  
 ]===]
 
  test_t = {}
  function test(str)
    table.insert(test_t,str)
  end
  
  ----------------------------------------------------------------------- 
  function msg(str)
    reaper.ShowConsoleMsg(str..'\n')
  end
  
  ----------------------------------------------------------------------- 
  function F_find_VST_analog(au_name,dumped_ini_pluglist)
    -- split by words
      au_name = au_name:gsub('%p', '')
      au_name_words = {}
      for word in string.gmatch(au_name, '[^%s]+') do table.insert(au_name_words, word) end
      
    -- find closest matching in pluglist
      matched_words = {}
      for i = 1, #dumped_ini_pluglist do
        matched_words_int = 0
        for j = 1, #au_name_words do
          if string.find(dumped_ini_pluglist[i]:gsub('%p', ''):lower(), au_name_words[j]:lower()) ~= nil then matched_words_int = matched_words_int+1 end
        end
        matched_words[i] = matched_words_int
      end
      
      max_match = 0
      max_i = 0
      for i = 1, #matched_words do
        max_match0 = max_match
        max_match = math.max(max_match, tonumber(matched_words[i]))
        if max_match > max_match0 then max_i = i end
      end
      
      if max_i ~= 0 then
        vst_name_line = dumped_ini_pluglist[max_i]:gsub('!!!VSTi','')
        cut = string.find(string.reverse(vst_name_line), ',')
        vst_name = vst_name_line:sub(-cut+1)
      end
    return vst_name, #au_name_words, max_match
  end
  
  -----------------------------------------------------------------------
  function F_add_to_list(config_path)
    file = io.open (config_path, 'r')
    if file ~= nil then 
      for line in io.lines(config_path) do 
        if string.find(line, '[[]') ~= 1 then table.insert(plugins_list, line) end
      end
    end
  end
  
 ----------------------------------------------------------------------- 
 function VAR_default_GUI()
    main_w = 320
    main_h = 120--240
    
    offset = 5         
    if OS == "OSX32" or OS == "OSX64" then fontsize = fontsize - 3 end    
    font = 'Arial'
    fontsize_objects = fontsize - 2    
    COL1 = {0.2, 0.2, 0.2}
    COL2 = {0.4, 1, 0.4} -- green
    COL3 = {1, 1, 1} -- white
    
    h_b = main_h/2-8---(main_h)/4-6
    b_1 = {offset,offset,main_w-offset*2,h_b}
    b_2 = {offset,offset+h_b+5,main_w-offset*2,h_b}
    b_3 = {offset,offset+h_b*2+10,main_w-offset*2,h_b}
    b_4 = {offset,offset+h_b*3+15,main_w-offset*2,h_b}
        
    b_1_name = "Dump AU plugins parameters to project file"
    b_2_name = "Replace VST from stored AU parameters"
    --[[    
    Dump VST plugins parameters to project file
    Replace AU from stored VST parameters]]
  end

-----------------------------------------------------------------------
  function F_extract_table(table,use)
    if table ~= nil then
      a = table[1]
      b = table[2]
      c = table[3]
      d = table[4]
    end  
    if use == 'rgb' then gfx.r,gfx.g,gfx.b = a,b,c end
    if use == 'xywh' then x,y,w,h = a,b,c,d end
    return a,b,c,d
  end 
  
 ----------------------------------------------------------------------- 
  function GUI_button(b_name,xywh_t, frame)
    gfx.a = 0.1
    F_extract_table(COL3,'rgb')
    F_extract_table(xywh_t,'xywh')
    gfx.rect(x,y,w,h)
    
    F_extract_table(xywh_t,'xywh')
    gfx.setfont(1,font,fontsize)
    gfx.x = x + (w - gfx.measurestr(b_name))/2
    gfx.y = y + (h - fontsize_objects)/2
    gfx.a = 1    
    gfx.drawstr(b_name)
    
    if frame then
      gfx.a = 1
      F_extract_table(COL2,'rgb')
      F_extract_table(xywh_t,'xywh')
      gfx.roundrect(x,y,w,h,false,1)
    end
    
  end
  
-----------------------------------------------------------------------
  function GUI_DRAW()
    -- background --
      gfx.a = 1
      F_extract_table(COL1,'rgb')
      gfx.rect(0,0,main_w,main_h)
    
    -- buttons
      GUI_button(b_1_name, b_1, b_1_frame)
      GUI_button(b_2_name, b_2, b_2_frame)
      --GUI_button(b_3_name, b_3, b_3_frame)
      --GUI_button(b_4_name, b_4, b_4_frame)
    gfx.update()
  end
    
-----------------------------------------------------------------------  
  function ENGINE1_dump_AU_to_project()
  
    -- get data
      
      plugdata = {}  
      counttracks = reaper.CountTracks(0)
      for i = 0, counttracks do
        if i == 0 then tr = reaper.GetMasterTrack(0)
         else
          tr = reaper.GetTrack(0,i-1)
          if tr ~= nil then
            tr_guid = reaper.GetTrackGUID(tr)
            fx_count = reaper.TrackFX_GetCount(tr)        
            if fx_count ~= nil then
              for j = 1, fx_count do
                _, fx_name = reaper.TrackFX_GetFXName(tr, j-1, '')
                fx_guid = reaper.TrackFX_GetFXGUID(tr, j-1)
                s_find1,s_find2 = fx_name:find('AU')
                if s_find1 == 1 and s_find2 == 2 then
                  params_count = reaper.TrackFX_GetNumParams(tr, j-1)
                  if params_count ~= nil then
                    val_com = ""
                    for k =1, params_count do
                      val = reaper.TrackFX_GetParamNormalized(tr, j-1, k-1)
                      val_s = string.format('%s',val)
                      val_com = val_com..' '..val_s
                    end
                    div = "||"
                    outstr = tr_guid..div..
                             (j)..div..
                             fx_name:sub(5)..div..
                             val_com
                    table.insert(plugdata, outstr)
                  end
                end
              end
            end
          end 
        end
      end
    
    -- send data to proj ext state
    
      if #plugdata > 0 then 
        plug_count = #plugdata 
        for i =1, #plugdata do reaper.SetProjExtState(0, 'AUVST_replacer', 'AU_dump_'..i, plugdata[i]) end 
       else 
        plug_count = 0  
      end
    
    -- show info message 
    
      if #plugdata > 0 then
        reaper.MB(plug_count..' AU plugin parameter sets dumped to project file', 'AU VST Replacer', 0)
       else
        reaper.MB('There is no any AU plugins in this project', 'AU VST Replacer Error', 0)
      end
    
  end

  -----------------------------------------------------------------------  
  function ENGINE1_restore_VST_from_AU()
    
    -- Extract data from project ext state
    
      i = 0
      plugdata_AU_ret = {}
      repeat
        temp_t = {}
        i=i+1
        retval, key, val = reaper.EnumProjExtState(0, "AUVST_replacer", i-1)
        if key ~= '' then 
          for word in string.gmatch(val, "[^||]+") do
            table.insert(temp_t, word)
          end 
          table.insert(plugdata_AU_ret, temp_t)
        end
      until retval == false
    
    -- Get list of possible vst      
      
      plugins_list  ={}
      F_add_to_list(reaper.GetResourcePath()..'/reaper-vstplugins.ini')
      F_add_to_list(reaper.GetResourcePath()..'/reaper-vstplugins64.ini')
      
    -- Loop main action
    
      if #plugdata_AU_ret > 0 then
      
        has_plugins = ''
        has_plugins2 = ''
        for i = 1, #plugdata_AU_ret do
          has_plugins2 = string.gsub(has_plugins,'%p','')
          str2 = string.gsub(plugdata_AU_ret[i][3],'%p','')
          if string.find(has_plugins2,str2) == nil then          
            has_plugins = has_plugins..'\n'..plugdata_AU_ret[i][3]
          end          
        end
        
        ret_user = reaper.MB('Are you REALLY SURE you have VST analogs of this AU plugins'..'\n'..
        'and you DID NOT TOUCH this project after dumping AU data (otherwise EVERYTHING WILL BE DELETED):'..'\n'..
        has_plugins..'?', '', 4)
   
        if ret_user == 6 then       
          reaper.PreventUIRefresh(1)   
          reaper.Undo_BeginBlock2(0)
---vvvvvvvvvv----------------------------------------------   
          msg("")
          msg('AU VST Replacer Log')
          msg('===================') 
          msg([[If you sure you have VST analog, but it wasn`t replaced and its name contains only ONE word, then change variable <min_words_compare> to zero (it placed in first lines of this script).  Also if something is not OK, do re-scan/clear cache of your plugins - Preferences/VST. If you found a bug, please contact me (list of conacts is inside script under changelog section.]])
          msg('===================') 
          if reaper.CountTracks(0) ~= nil then
            for i = 1, #plugdata_AU_ret do
            
              t_track_guid = plugdata_AU_ret[i][1]              
              t_fx_name = plugdata_AU_ret[i][3]
              t_fx_params = plugdata_AU_ret[i][4]
              t_fx_id = tonumber(plugdata_AU_ret[i][2])
              
              for j=0, reaper.CountTracks(0) do
                if j ==0 then track = reaper.GetMasterTrack(0)
                 else
                  track = reaper.GetTrack(0,j-1)
                  if track ~= nil then
                    trackguid = reaper.GetTrackGUID(track)
                    _, tr_name = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false)
                    if t_track_guid == trackguid then
                      msg('Track '..j..' '..tr_name)
                      -- get VST analog name
                         insert_fx, count_orig_words, matched_words = F_find_VST_analog(t_fx_name,plugins_list)                         
                         if insert_fx ~= nil and matched_words >  min_words_compare then                            
                            msg('   Found match: (AU) '..t_fx_name..' / (VST) '..insert_fx)           
                            fxcount = reaper.TrackFX_GetCount(track)
                              
                            -- check if AU lpugin was not touched
                              _, au_name = reaper.TrackFX_GetFXName(track, t_fx_id-1, '')
                              if au_name:gsub('%p',''):find(t_fx_name:gsub('%p','')) ~= nil then     
                                msg('   Status: OK. AU wasn`t touched')                         
                                -- insert by name 
                                  reaper.TrackFX_GetByName(track, insert_fx, true) 
                                  _, fx_name =  reaper.TrackFX_GetFXName(track, fxcount, "") 
                                  msg('   '..insert_fx..' inserted at the end of chain')
                                
                                -- remove old AU                  
                                  reaper.SNM_MoveOrRemoveTrackFX(track, t_fx_id-1, 0)                   
                                  msg('   AU #'..t_fx_id..' removed')
                                      
                                -- move new VST  
                                  reaper.SNM_MoveOrRemoveTrackFX(track, fxcount-1, t_fx_id-fxcount)
                                  msg('   '..insert_fx..' moved '..t_fx_id-fxcount..' positions in chain')
                                      
                                -- extract/apply parameters
                                  t_fx_params_extracted_t = {}
                                  for word in string.gmatch(t_fx_params, '[^%s]+') do 
                                    table.insert(t_fx_params_extracted_t, word) end   
                                  msg('   '..#t_fx_params_extracted_t..' parameters extracted')
                                -- apply                        
                                  for k = 1, #t_fx_params_extracted_t do
                                    reaper.TrackFX_SetParamNormalized(track, t_fx_id-1, k-1, t_fx_params_extracted_t[k])
                                  end
                                else
                                 msg('   Status: Error. AU was touched (moved, deleted, renamed).'..'\n'.. 
                                 '   Please dump AU plugins again (or run original project again) and DONT DO anything with project before running this script')
                              end -- if au stored==au current
                              
                            else -- vst not found
                             msg('    VST analog of <'..t_fx_name..'> not found')
                          end -- if insert fx ~= nil
                          
                          
                        end
                        
                    end
                end
              end  
                          
            end--loop ret data            
          end -- if cnt tracks ~= nil
--^^^^^^^^^----------------------------------------------- 
          reaper.Undo_EndBlock2(0, 'AU VST replacer - NO UNDO', 1)
          reaper.PreventUIRefresh(-1)
        end --ret user 6
        
      end -- if # ret AU data > 0
      
      --reaper.ShowConsoleMsg(content)
      
  end
  
  -----------------------------------------------------------------------
    function MOUSE_gate(mb, b)
      local state    
      if MOUSE_match_xy(b) then       
       if mb == 1 then if LMB_state and not last_LMB_state then state = true else state = false end end
       if mb == 2 then if RMB_state and not last_RMB_state then state = true else state = false end end 
       if mb == 64 then if MMB_state and not last_MMB_state then state = true else state = false end end        
      end   
      return state
    end
    
  -----------------------------------------------------------------------
  function MOUSE_match_xy(b)
    if    mx > b[1] 
      and mx < b[1]+b[3]
      and my > b[2]
      and my < b[2]+b[4] then
     return true 
    end 
  end
      
  -----------------------------------------------------------------------  
  function MOUSE_get()
      LMB_state = gfx.mouse_cap&1 == 1 
      RMB_state = gfx.mouse_cap&2 == 2 
      MMB_state = gfx.mouse_cap&64 == 64  
      mx, my = gfx.mouse_x, gfx.mouse_y
          
      if MOUSE_gate(1, b_1) then  ENGINE1_dump_AU_to_project()   end      
      if MOUSE_match_xy(b_1) then b_1_frame = true else b_1_frame = false end
      
      if MOUSE_gate(1, b_2) then  ENGINE1_restore_VST_from_AU()   end  
      if MOUSE_match_xy(b_2) then b_2_frame = true else b_2_frame = false end
      
      last_LMB_state = LMB_state    
      last_RMB_state = RMB_state
      last_MMB_state = MMB_state 
  end
  
-----------------------------------------------------------------------
  function F_exit() gfx.quit() end
  
-----------------------------------------------------------------------
  function run()    
    GUI_DRAW()
    MOUSE_get()
    char = gfx.getchar()
    if char == 27 then exit() end     
    if char ~= -1 then reaper.defer(run) else F_exit() end
  end 
  
-----------------------------------------------------------------------
  OS = reaper.GetOS()
  VAR_default_GUI()
  gfx.init("mpl AU VST Replacer // ".."Version "..vrs, main_w, main_h)
  reaper.atexit(F_exit) 
  
  run()
  
  

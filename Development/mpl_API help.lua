-- @description API help
-- @author MPL
-- @version 1.0
-- @changelog + init
-- @about This script supposed to contain basic info provided with API Help page comes with REAPER, but allow to extend info and snippets database from users.

-- @description APIHelp
-- @version 1.0
-- @author MPL
-- @about API help
-- @changelog
--    + init
  
  version = 1.0
  ---------------------------------------------------
  function ExtState_Def()  
    local t= {
    
            -- globals
            mb_title = 'API help',
            ES_key = 'MPL_APIhelp',
            wind_x =  50,
            wind_y =  50,
            wind_w =  600,
            wind_h =  300,
            dock =    0,
            
            filter = '',
            cur_func = 10,
            loadfilteronstart = 0,
            }
    return t
  end
  ------------------------------------------------------------------
  function VF_DATA_Custom_ParseStr(str)  
    local t = {}
    if not str then return end
    local id
    local snip = ''
    for line in str:gmatch('[^\r\n]+') do
      if line:match('FUNC(%d+)') and not line:match('%-%-') then
        id = tonumber(line:match('FUNC(%d+)'))
        local fullfunc = line:match('FUNC[%d]+ (.*)')
        local shname = fullfunc:match('([%a%d_]+)%(')
        if not shname then shname = fullfunc end
        if not fullfunc then fullfunc = line:match('(FUNC[%d]+)') end
        t[id] = {name = fullfunc,
                shname = shname
                }
      end
      
      if line:match('DESC(%d+)') and id then
        local desc = line:match('DESC[%d]+ (.*)')
        t[id].desc = desc
      end
      
      if line:match('SNIP(%d+)_START') and id then
        snip_active = true
        snip = ''
      end
      
      if snip_active and id and not line:match('SNIP(%d+)_START') and not line:match('SNIP(%d+)_END') then 
        snip = snip..line..'\n'
      end
      
      if line:match('SNIP(%d+)_END') and id then
        snip_active = false
        t[id].snip = snip
      end      
      
    end
    return t
  end
  ------------------------------------------------------------------
  function VF_DATA_Init(MOUSE,OBJ,DATA)
    --dofile(reaper.GetResourcePath()..[[\Scripts\MPL Scripts\Various\mpl_APIHelp_list.lua]])
    if mainstr then 
      DATA.custom = {str=mainstr,functions={}}
      DATA.custom.functions = VF_DATA_Custom_ParseStr(mainstr)
    end 
  end
  ---------------------------------------------------------------------
  function VF_run_initVars_overwrite()
    --DATA.conf.cur_func = 0
  end
  ---------------------------------------------------------------------
  function VF_MatchMultiWord(txt1,txt2) -- txt1:match(txt2)
    local t = {}
    local matches = 0
    for word in txt2:gmatch('[^%s]+') do t[#t+1]  = word:lower() end
    for i = 1, #t do if txt1:lower():match(t[i]) then matches = matches + 1 end end
    if matches == #t then return true end
  end
  ---------------------------------------------------------------------
  function VF_DATA_Update_Filter(MOUSE,OBJ,DATA)
    for i = 1, #DATA.custom.functions do
      if DATA.custom.functions[i] then
        local match = true
        if DATA.conf.filter ~= '' and DATA.custom.functions[i] and DATA.custom.functions[i].shname and DATA.conf.filter then 
          match = VF_MatchMultiWord(DATA.custom.functions[i].shname, DATA.conf.filter) or false
        end
        DATA.custom.functions[i].match = match
      end
    end
  end
  ---------------------------------------------------------------------
  function VF_DATA_Update(MOUSE,OBJ,DATA)
    VF_DATA_Update_Filter(MOUSE,OBJ,DATA)
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Update(MOUSE,OBJ,DATA)
    
  end
  ---------------------------------------------------
  function msg(s) 
    if not s then return end 
    if type(s) == 'boolean' then
      if s then s = 'true' else  s = 'false' end
    end
    ShowConsoleMsg(s..'\n') 
  end 
  ------------------------------------------------------------------------------------------------------
  function VF_MenuReturnToggle(MOUSE,OBJ,DATA,str_name, t, value, statecheck)
    local state
    local str=''
    if t[value] then
      str=str_name
      state = t[value]&statecheck==statecheck
     else 
      str=str_name..' [undefined]'
      state = false
    end
    return {  str=str,
              state = state,
              func = function()
                        if not t[value] then return end
                        if t[value]&statecheck==statecheck then
                          t[value] = t[value] - statecheck
                         else
                          t[value] = t[value]|statecheck
                        end
                        DATA.refresh.conf = DATA.refresh.conf|1
                        DATA.refresh.data = DATA.refresh.data|1
                        DATA.refresh.GUI = DATA.refresh.GUI|1
                      end
              }
  end
  ------------------------------------------------------------------------------------------------------
  function VF_MenuReturnUserInput(MOUSE,OBJ,DATA, str_name, captions_csv, t, value, allowemptyresponse)
    local str = ''
    if t[value] then
      str=str_name..': '..t[value]
     else
      str=str_name..': [undefined]'
    end
    return {  str=str,
              func = function()
                        if not t[value] then return end
                        local retval, retvals_csv = reaper.GetUserInputs( str_name, 1, captions_csv, t[value] )
                        if retval  then 
                          if retvals_csv ~= '' or (retvals_csv == '' and allowemptyresponse) then
                            t[value] = tonumber(retvals_csv) or retvals_csv 
                          end
                        end
                      end
              }
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_InitMenuTop(MOUSE,OBJ,DATA, options_t)
     t = {     { str = '#'..DATA.conf.mb_title..' '..DATA.conf.vrs..'|'},
                    { str = '>MPL contacts'},
                    { str = 'Cockos forum centralized thread',
                      func = function() Open_URL('https://forum.cockos.com/showthread.php?t=188335') end  } , 
                    { str = 'VK page',
                      func = function() Open_URL('http://vk.com/mpl57') end  } ,     
                    { str = 'SoundCloud page|<',
                      func = function() Open_URL('http://soundcloud.com/mpl57') end  }, 
              }
    if options_t then for i =1, #options_t do t[#t+1] = options_t[i] end end
    
    -- dock
    t[#t+1] = { str = '|Dock',
                state = DATA.conf.dock > 0,
                func = function() 
                        if DATA.conf.dock > 0 then DATA.conf.dock = 0 else DATA.conf.dock = 1 end
                        gfx.quit()
                        atexit( )
                        VF_run_init()
                        gfx.showmenu('')
                       end
                }
                
    -- close            
    t[#t+1] = {str = 'Close', func = function() gfx.quit() atexit( ) end} 
                
    OBJ.topline_menu = {is_button = true,  
                 x = 0,
                 y = 0,
                 w = DATA.GUIvars.menu_w,
                 h = DATA.GUIvars.menu_h,
                 txt= '>',
                 drawstr_flags = 1|4,
                 fontsz = DATA.GUIvars.menu_fontsz,
                 func_Ltrig =  function() VF_MOUSE_menu(MOUSE,OBJ,DATA,t) end}                
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Init(MOUSE,OBJ,DATA)
    local options_t =  {{ str = '|#Options'},
                        VF_MenuReturnToggle(MOUSE,OBJ,DATA,'Set filter on initialization', DATA.conf, 'loadfilteronstart', 1)}
    OBJ_Buttons_InitMenuTop(MOUSE,OBJ,DATA,options_t)
    
    for i = 1, 500 do  OBJ['snip'..i] = nil end -- clear
    
    DATA.GUIvars.custom = {}
    DATA.GUIvars.custom.funcw = 300.
    DATA.GUIvars.custom.funch = 20
    DATA.GUIvars.custom.offs = 5 
    DATA.GUIvars.custom.snip_fontsz = 17
    DATA.GUIvars.custom.linksw = DATA.GUIvars.custom.snip_fontsz
    if DATA.conf.loadfilteronstart == 1 then OBJ_Buttons_Init_Filter(MOUSE,OBJ,DATA) end
    OBJ_Buttons_Init_LeftPage(MOUSE,OBJ,DATA)
    OBJ_Buttons_ShowFunction(MOUSE,OBJ,DATA,DATA.conf.cur_func)
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Init_Filter(MOUSE,OBJ,DATA)
    local t = VF_MenuReturnUserInput(MOUSE,OBJ,DATA, 'API Filter', DATA.conf.filter, DATA.conf, 'filter', true)
    t.func()
    for i = 1, #DATA.custom.functions do OBJ['function'..i] = nil end
    DATA.refresh.data = DATA.refresh.data|2
    DATA.refresh.GUI = DATA.refresh.GUI|1
    DATA.refresh.conf = DATA.refresh.conf|2
    VF_DATA_Update_Filter(MOUSE,OBJ,DATA)
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_Init_LeftPage(MOUSE,OBJ,DATA)
    local txtfilt = DATA.conf.filter
    if txtfilt == '' then txtfilt = '[no filter set]' end
    OBJ.filter = { is_button = true,
                x = DATA.GUIvars.menu_w,
                y = 0,
                w = DATA.GUIvars.custom.funcw-DATA.GUIvars.menu_w,
                h = DATA.GUIvars.menu_h,
                txt= 'Filter: '..txtfilt,
                drawstr_flags = 1|4,
                fontsz = 17,
                func_Ltrig =  function() OBJ_Buttons_Init_Filter(MOUSE,OBJ,DATA) end
                  }
                  
    
    local y_offs = DATA.GUIvars.menu_h + DATA.GUIvars.custom.offs
    
    for i = 1, #DATA.custom.functions do
      if DATA.custom.functions[i] and DATA.custom.functions[i].match == true then
        OBJ['function'..i] = { is_button = true,
                  x = 0,
                  y = y_offs,
                  w = DATA.GUIvars.custom.funcw,
                  h = DATA.GUIvars.custom.funch,
                  txt= DATA.custom.functions[i].shname:sub(0,50),
                  drawstr_flags = 1|4,
                  fontsz = 17,
                  preventregularselection = true,
                  func_Ltrig =  function() OBJ_Buttons_ShowFunction(MOUSE,OBJ,DATA,i) end
                    } 
        y_offs = y_offs + DATA.GUIvars.custom.funch
      end
    end
  end
  ---------------------------------------------------------------------
  function OBJ_Buttons_ShowFunction(MOUSE,OBJ,DATA,i)
    if not DATA.custom.functions[i] then return end
    -- clear previous func selection
      cur_func = DATA.conf.cur_func
      if cur_func and OBJ['function'..cur_func] then OBJ['function'..cur_func].selected = false end
      if OBJ['function'..i] then OBJ['function'..i].selected = true end
      
    DATA.conf.cur_func = i 
    
    OBJ.functionname = { is_button = true,
                x = DATA.GUIvars.custom.funcw+DATA.GUIvars.custom.offs,
                y = 0,
                w = gfx.w- DATA.GUIvars.custom.funcw-DATA.GUIvars.custom.offs*2,
                h = DATA.GUIvars.menu_h*2,
                txt= DATA.custom.functions[i].name,
                drawstr_flags = 1|4,
                fontsz = 17,
                func_Ltrig =  function() GetUserInputs( '', 1, ',extrawidth=600', DATA.custom.functions[i].name ) end }
    
    OBJ.functiondesc = { is_button = true,
                x = DATA.GUIvars.custom.funcw+DATA.GUIvars.custom.offs,
                y = DATA.GUIvars.menu_h*2 +DATA.GUIvars.custom.offs ,
                w = gfx.w- DATA.GUIvars.custom.funcw-DATA.GUIvars.custom.offs*2,
                h = DATA.GUIvars.menu_h*3,
                txt= DATA.custom.functions[i].desc,
                drawstr_flags = 1|4,
                fontsz = 16,
                func_Ltrig =  function() end }   
                
    local sniptxt = DATA.custom.functions[i].snip 
    if sniptxt then sniptxt = sniptxt:gsub('LINK[%d]+','') end
    OBJ.functionsnip = { is_button = true,
                x = DATA.GUIvars.custom.funcw+DATA.GUIvars.custom.offs+DATA.GUIvars.custom.linksw,
                y = DATA.GUIvars.menu_h*5 +DATA.GUIvars.custom.offs*2 ,
                w = gfx.w- DATA.GUIvars.custom.funcw-DATA.GUIvars.custom.offs*2,
                h = gfx.h- (DATA.GUIvars.menu_h*6 +DATA.GUIvars.custom.offs*3),
                txt= sniptxt,
                highlight = false,
                selected = false,
                preventregularselection = true,
                drawstr_flags = 0,
                fontsz = DATA.GUIvars.custom.snip_fontsz,
                func_Ltrig =  function()  end }  
    local snipw = (gfx.w- DATA.GUIvars.custom.funcw-DATA.GUIvars.custom.offs*2)/2
    OBJ.functionsniprun = { is_button = true,
                x = DATA.GUIvars.custom.funcw+DATA.GUIvars.custom.offs+DATA.GUIvars.custom.linksw,
                y = OBJ.functionsnip.y+OBJ.functionsnip.h +DATA.GUIvars.custom.offs ,
                w = snipw,
                h = DATA.GUIvars.menu_h,
                txt= 'Run code',
                drawstr_flags = 1|4,
                fontsz = DATA.GUIvars.custom.snip_fontsz,
                func_Ltrig =  function() 
                                local cur_func = DATA.custom.cur_func
                                if DATA.custom.functions[i] and sniptxt then
                                  local f = load(sniptxt)  f() 
                                end
                              end } 
    OBJ.functionsnipcopy = { is_button = true,
                x = DATA.GUIvars.custom.funcw+DATA.GUIvars.custom.offs+DATA.GUIvars.custom.linksw+snipw,
                y = OBJ.functionsnip.y+OBJ.functionsnip.h +DATA.GUIvars.custom.offs ,
                w = snipw,
                h = DATA.GUIvars.menu_h,
                txt= 'Copy code',
                drawstr_flags = 1|4,
                fontsz = DATA.GUIvars.custom.snip_fontsz,
                func_Ltrig =  function() GetUserInputs( '', 1, ',extrawidth=600', sniptxt ) end }       
                              
      -- snippet links                         
      for i = 1, 500 do  OBJ['snip'..i] = nil end -- clear
        local cur_func = DATA.conf.cur_func
        if cur_func and DATA.custom.functions[cur_func] and DATA.custom.functions[cur_func].snip then  
          local txt = ''
          local i = 0
          for line in DATA.custom.functions[cur_func].snip:gmatch('[^\r\n]+') do
            i = i +1
            if line:match('LINK%d') then
              OBJ['snip'..i] = { is_button = true,
                          x = DATA.GUIvars.custom.funcw+DATA.GUIvars.custom.offs,
                          y = DATA.GUIvars.menu_h*5 +DATA.GUIvars.custom.offs*2 +DATA.GUIvars.custom.snip_fontsz*(i-1),
                          w = DATA.GUIvars.custom.linksw,
                          h = DATA.GUIvars.custom.snip_fontsz,
                          txt= '>',
                          drawstr_flags = 0,
                          grad_back_a = 0,
                          fontsz = DATA.GUIvars.custom.snip_fontsz,
                          func_Ltrig =  function() 
                                          local funcid = line:match('LINK(%d+)')
                                          if funcid and tonumber(funcid) then 
                                            OBJ_Buttons_ShowFunction(MOUSE,OBJ,DATA,tonumber(funcid)) 
                                          end
                                        end }  
          end
        end
      end  
       
      
    DATA.refresh.data = DATA.refresh.data|2
    DATA.refresh.GUI = DATA.refresh.GUI|4
    DATA.refresh.conf = DATA.refresh.conf|2
  end
---------------------------------------------------
  function VF_run_initVars()
    OBJ = {-- GUI objects
          } 
      
    DATA = {-- Data used by script
      conf = {}, 
      confproj = {}, -- reaper-ext.ini
      dev_mode = 0, -- test stuff
      refresh = { GUI = 1|2|4, --&1 refresh everything &2 buttons &4 buttons update
                  conf = 0, -- save ext state &1 all &2 reaper-ext.ini only &4 projextstate only &8 preset only
                  data = 1|2|4, -- &1 init &2 update data &4 read &8 write
                },
      GUIvars = {
                  grad_sz = 200, -- gradient background src, px
                  colors = VF_run_initVars_SetColors(MOUSE,OBJ,DATA),
                  menu_w = 25, -- top menu, px
                  menu_h = 25, -- top menu, px
                  menu_fontsz = 17, 
                }
      } 
      
    MOUSEt = {}
    VF_ExtState_Load(DATA.conf) 
    if not DATA.conf.vrs then DATA.conf.vrs = '[version undefined]' end
    if not DATA.conf.preset_current then DATA.conf.preset_current = 0 end
    --if DATA.conf.preset_current ~= 0 then VF_ExtState_LoadPreset(conf,preset) end
    --VF_ExtState_LoadProj(DATA.confproj, DATA.conf.ES_key) 
  end  
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_Save(conf) for key in spairs(conf) do if not (key:match('P_(.*)') or key:match('P[%d]+_(.*)')) then SetExtState(conf.ES_key, key, conf[key], true) end  end end
  ------------------------------------------------------------------------------------------------------
  function VF_ExtState_Load(conf)
    local def = ExtState_Def()
    for key in spairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end  
  end 
  --------------------------------------------------------------------
  function VF_run_init()
    gfx.init(DATA.conf.mb_title..' '..DATA.conf.vrs,
                    DATA.conf.wind_w,
                    DATA.conf.wind_h,
                    DATA.conf.dock, 
                    DATA.conf.wind_x, 
                    DATA.conf.wind_y)
    VF_run()
  end
   ---------------------------------------------------  
 function VF_MOUSE_Match(b)
   if not b then return end
   if b.x and b.y and b.w and b.h then  
     return MOUSEt.x > b.x
              and MOUSEt.x < b.x+b.w
              and MOUSEt.y > b.y
              and MOUSEt.y < b.y+b.h 
   end  
 end
--------------------------------------------------- 
 function VF_MOUSE(MOUSEt,OBJ,DATA)
   if MOUSEt.Performafterloop then MOUSEt.Performafterloop(MOUSEt,OBJ,DATA) MOUSEt.Performafterloop = nil end
   -- main
   MOUSEt.char = gfx.getchar()
   MOUSEt.cap = gfx.mouse_cap
   MOUSEt.x = gfx.mouse_x
   MOUSEt.y = gfx.mouse_y
   
   -- L/M/R button states
   MOUSEt.LMB_state = gfx.mouse_cap&1 == 1 
   MOUSEt.LMB_trig = MOUSEt.LMB_state and not MOUSEt.last_LMB_state
   MOUSEt.RMB_state = gfx.mouse_cap&2 == 2 
   MOUSEt.RMB_trig = MOUSEt.RMB_state and not MOUSEt.last_RMB_state
   MOUSEt.MMB_state = gfx.mouse_cap&64 == 64
   MOUSEt.MMB_trig = MOUSEt.MMB_state and not MOUSEt.last_MMB_state 
   MOUSEt.ANY_state = MOUSEt.LMB_state or MOUSEt.RMB_state or MOUSEt.MMB_state
   MOUSEt.ANY_trig = MOUSEt.LMB_trig or MOUSEt.RMB_trig or MOUSEt.MMB_trig
   
   -- latchx/y 
   if MOUSEt.ANY_trig then
     MOUSEt.latchx = MOUSEt.x
     MOUSEt.latchy = MOUSEt.y
   end
   if MOUSEt.ANY_state then 
     MOUSEt.dx = MOUSEt.x - MOUSEt.latchx
     MOUSEt.dy = MOUSEt.y - MOUSEt.latchy
   end
   if not MOUSEt.ANY_state and MOUSEt.last_ANY_state then
     MOUSEt.dx = 0
     MOUSEt.dy = 0
     MOUSEt.latchx = nil
     MOUSEt.latchy = nil
   end 
   MOUSEt.is_moving = MOUSEt.last_x and MOUSEt.last_y and (MOUSEt.last_x ~= MOUSEt.x or MOUSEt.last_y ~= MOUSEt.y)
   
   -- wheel
   MOUSEt.wheel = gfx.mouse_wheel
   MOUSEt.wheel_trig = MOUSEt.last_wheel and MOUSEt.last_wheel ~= MOUSEt.wheel
   MOUSEt.wheel_dir = MOUSEt.last_wheel and MOUSEt.last_wheel-MOUSEt.wheel>0
   
   -- ctrl alt shift
   MOUSEt.Ctrl = gfx.mouse_cap&4 == 4 
   MOUSEt.Shift = gfx.mouse_cap&8 == 8 
   MOUSEt.Alt = gfx.mouse_cap&16 == 16  
   MOUSEt.hasAltkeys = not (MOUSEt.Ctrl or MOUSEt.Shift or MOUSEt.Alt)
   MOUSEt.pointer = ''
   
for key in spairs(OBJ,function(t,a,b) return b > a end) do
  --if type(OBJ[key]) == 'table' then OBJ[key].selfkey = key end 
  if type(OBJ[key]) == 'table' and not OBJ[key].ignore_mouse then
    local regular_match = VF_MOUSE_Match(OBJ[key]) 
    OBJ[key].undermouse = regular_match -- frame around button 
    if regular_match  then  
      MOUSEt.pointer = key 
      if OBJ[key].func_undermouse then OBJ[key].func_undermouse() end
      --if MOUSEt.is_moving then DATA.refresh.GUI = DATA.refresh.GUI|4 end -- trig Obj buttons update 
      if MOUSEt.wheel_trig and OBJ[key].func_Wtrig then OBJ[key].func_Wtrig(MOUSEt) end 
      if MOUSEt.LMB_trig and   OBJ[key].func_Ltrig then MOUSEt.Performafterloop = OBJ[key].func_Ltrig end
      if MOUSEt.RMB_trig and   OBJ[key].func_Rtrig then OBJ[key].func_Rtrig(MOUSEt) end
      if MOUSEt.ANY_trig then 
        if not OBJ[key].preventregularselection then 
          OBJ[key].selected = true 
          DATA.refresh.GUI = DATA.refresh.GUI|4 
        end
        MOUSEt.latch_key = key 
      end  
    end 
  end 
end
   
   -- hook around change pointer
   if MOUSEt.last_pointer and MOUSEt.pointer and MOUSEt.last_pointer ~= MOUSEt.pointer then
     if OBJ[MOUSEt.last_pointer] then OBJ[MOUSEt.last_pointer].undermouse = false end
     DATA.refresh.GUI = DATA.refresh.GUI|4 -- trig Obj buttons update 
     if OBJ[MOUSEt.pointer] and OBJ[MOUSEt.pointer].func_onptrcatch then OBJ[MOUSEt.pointer].func_onptrcatch() end
     if OBJ[MOUSEt.last_pointer] and OBJ[MOUSEt.last_pointer].func_onptrfree then OBJ[MOUSEt.last_pointer].func_onptrfree() end -- release after navigate
   end 
    
    local dragcond = MOUSEt.latch_key and (MOUSEt.latch_key == MOUSEt.pointer or MOUSEt.pointer == '') and MOUSEt.is_moving 
   if dragcond and MOUSEt.LMB_state and OBJ[MOUSEt.latch_key].func_Ldrag then OBJ[MOUSEt.latch_key].func_Ldrag() end
   if dragcond and MOUSEt.RMB_state and OBJ[MOUSEt.latch_key].func_Rdrag then OBJ[MOUSEt.latch_key].func_Rdrag() end
   if dragcond and MOUSEt.MMB_state and OBJ[MOUSEt.latch_key].func_Mdrag then OBJ[MOUSEt.latch_key].func_Mdrag() end
    
   --  on any button release
     if not MOUSEt.ANY_state and MOUSEt.last_ANY_state then 
       local key
       if MOUSEt.latch_key then key = MOUSEt.latch_key end
       if key and OBJ[key] and OBJ[key].func_onptrrelease then OBJ[key].func_onptrrelease() end -- release after drag
       if key and OBJ[key] and MOUSEt.LMB_state == false and MOUSEt.last_LMB_state == true and OBJ[key].func_Lrelease then OBJ[key].func_Lrelease() end
       if key and OBJ[key] and MOUSEt.ANY_state == false and MOUSEt.last_ANY_state == true then
        if not OBJ[key].preventregularselection then 
          OBJ[key].selected = false 
          DATA.refresh.GUI = DATA.refresh.GUI|4 
        end
        if OBJ[key].func_Arelease then 
         OBJ[key].func_Arelease() 
         OBJ[key].undermouse = false 
         DATA.refresh.GUI = DATA.refresh.GUI|4 -- trig Obj buttons updat
        end
        MOUSEt[key] = nil
       end
     end
   
   MOUSEt.last_x = MOUSEt.x
   MOUSEt.last_y = MOUSEt.y
   MOUSEt.last_pointer = MOUSEt.pointer
   MOUSEt.last_LMB_state = MOUSEt.LMB_state  
   MOUSEt.last_RMB_state = MOUSEt.RMB_state  
   MOUSEt.last_MMB_state = MOUSEt.MMB_state  
   MOUSEt.last_ANY_state = MOUSEt.ANY_state 
   MOUSEt.last_wheel = MOUSEt.wheel
 end
 ---------------------------------------------------
  function VF_MOUSE_menu(MOUSEt,OBJ,DATA,t)
    local str, check ,hidden= '', '',''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      if t[i].hidden then hidden = '#' else hidden ='' end
      local add_str = hidden..check..t[i].str 
      str = str..add_str
      str = str..'|'
    end
    gfx.x = MOUSEt.x
    gfx.y = MOUSEt.y
    local ret = gfx.showmenu(str)
    local incr = 0
    if ret > 0 then 
      for i = 1, ret do 
        if t[i+incr].menu_decr == true then incr = incr - 1 end
        if t[i+incr].str:match('>') then incr = incr + 1 end
        if t[i+incr].menu_inc then incr = incr + 1 end
      end
      if t[ret+incr] and t[ret+incr].func then 
        t[ret+incr].func() 
        if VF_run_UpdateAll then VF_run_UpdateAll(DATA) end 
      end 
      --- msg(t[ret+incr].str)
    end 
  end  
  ---------------------------------------------------
  function VF_run_CheckProjUpdates(DATA)
    local ret = 0
    if not DATA.CheckProjUpdates then DATA.CheckProjUpdates = {} end
    
    
    -- SCC &1
      local SCC =  GetProjectStateChangeCount( 0 )
      if (DATA.CheckProjUpdates.lastSCC and DATA.CheckProjUpdates.lastSCC~=DATA.CheckProjUpdates.SCC ) then ret = ret|1 end
      DATA.CheckProjUpdates.lastSCC = DATA.CheckProjUpdates.SCC
      
    -- edit cursor &2
      DATA.CheckProjUpdates.editcurpos =  GetCursorPosition() 
      if (DATA.CheckProjUpdates.last_editcurpos and DATA.CheckProjUpdates.last_editcurpos~=DATA.CheckProjUpdates.editcurpos ) then ret = ret|2 end
      DATA.CheckProjUpdates.last_editcurpos=DATA.editcurpos
    
    -- script XYWH section &4 XY &8 WH/dock
      local  dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
      if not DATA.CheckProjUpdates.last_gfxx 
        or not DATA.CheckProjUpdates.last_gfxy 
        or not DATA.CheckProjUpdates.last_gfxw 
        or not DATA.CheckProjUpdates.last_gfxh 
        or not DATA.CheckProjUpdates.last_dock then 
        DATA.CheckProjUpdates.last_gfxx, 
        DATA.CheckProjUpdates.last_gfxy, 
        DATA.CheckProjUpdates.last_gfxw, 
        DATA.CheckProjUpdates.last_gfxh, 
        DATA.CheckProjUpdates.last_dock = wx,wy,ww,wh, dock
      end
      if wx ~= DATA.CheckProjUpdates.last_gfxx or wy ~= DATA.CheckProjUpdates.last_gfxy then ret = ret|4  end -- XY position change
      if ww ~= DATA.CheckProjUpdates.last_gfxw or wh ~= DATA.CheckProjUpdates.last_gfxh or dock ~= DATA.CheckProjUpdates.last_dock then ret = ret|8 end -- WH and dock change
      DATA.CheckProjUpdates.last_gfxx, DATA.CheckProjUpdates.last_gfxy, DATA.CheckProjUpdates.last_gfxw, DATA.CheckProjUpdates.last_gfxh, DATA.CheckProjUpdates.last_dock = wx,wy,ww,wh,dock
      
    -- proj tab &16
      local reaproj = tostring(EnumProjects( -1 ))
      DATA.CheckProjUpdates.reaproj = reaproj
      if DATA.CheckProjUpdates.last_reaproj and DATA.CheckProjUpdates.last_reaproj ~= DATA.CheckProjUpdates.reaproj then ret = ret|16 end
      DATA.CheckProjUpdates.last_reaproj = reaproj
      
    return ret
  end  
---------------------------------------------------
  function VF_GUI_draw(MOUSEt,OBJ,DATA)
    -- 1 Back main
    -- 2 Back button
    -- 3 Buttons
    -- 4 Dynamic stuff major 
    -- 5 Dynamic stuff minor
    
    -- major GUI update
      if DATA.refresh.GUI&1==1 then 
        VF_GUI_DrawBackground(MOUSEt,OBJ,DATA) 
        VF_GUI_DrawBackgroundButton(MOUSEt,OBJ,DATA)
      end 
    
    -- redraw buttons
      if   DATA.refresh.GUI&1==1 
        or DATA.refresh.GUI&2==2 
        or DATA.refresh.GUI&4==4 
        then 
        gfx.dest = 3
        gfx.setimgdim(3, -1, -1)  
        gfx.setimgdim(3, gfx.w,gfx.h)  
        for key in pairs(OBJ) do VF_GUI_DrawButton(MOUSEt,OBJ,DATA, OBJ[key]) end
      end
    
    -- render layers 
      gfx.mode = 0
      gfx.set(1,1,1,1)
      gfx.dest = -1   
      gfx.a = 1
      gfx.x,gfx.y = 0,0
      gfx.blit(1, 1, 0, 
            0,0,DATA.GUIvars.grad_sz, DATA.GUIvars.grad_sz,
            0,0,gfx.w, gfx.h, 0,0) 
      --[[gfx.blit(2, 1, 0,
            0,0,OBJ.grad_sz, OBJ.grad_sz,
            0,0,gfx.w, gfx.h, 0,0)  ]]         
      gfx.blit(3, 1, 0,
            0,0,gfx.w, gfx.h,
            0,0,gfx.w, gfx.h, 0,0)   
      gfx.blit(4, 1, 0,
            0,0,gfx.w, gfx.h,
            0,0,gfx.w, gfx.h, 0,0)   
      gfx.blit(5, 1, 0,
            0,0,gfx.w, gfx.h,
            0,0,gfx.w, gfx.h, 0,0)   
      
    gfx.update()
  end
  ----------------------------------------------
  function VF_GUI_DrawBackground(MOUSEt,OBJ,DATA)
    local col_back = '#3f484d'
    if DATA.GUIvars.colors and DATA.GUIvars.colors.backgr then col_back = DATA.GUIvars.colors.backgr  end
    local grad_sz = DATA.GUIvars.grad_sz or 200
    gfx.dest = 1
    gfx.setimgdim(1, -1, -1)  
    gfx.setimgdim(1, grad_sz,grad_sz)  
    local r,g,b = VF_hex2rgb(col_back)
    gfx.x, gfx.y = 0,0
    local c = 0.8
    local a=0.9
    local drdx = c*0.00001
    local drdy = c*0.00001
    local dgdx = c*0.00002
    local dgdy = c*0.0001    
    local dbdx = c*0.00008
    local dbdy = c*0.00001
    local dadx = c*0.00001
    local dady = c*0.00001       
    gfx.gradrect(0,0, grad_sz,grad_sz, 
                    r,g,b,a, 
                    drdx, dgdx, dbdx, dadx, 
                    drdy, dgdy, dbdy, dady) 
  end 
  ---------------------------------------------------
  function VF_hex2rgb(s16,set)
    s16 = s16:gsub('#',''):gsub('0X',''):gsub('0x','')
    local b,g,r = ColorFromNative(tonumber(s16, 16))
    if set then
      if GetOS():match('Win') then gfx.set(r/255,g/255,b/255) else gfx.set(b/255,g/255,r/255) end
    end
    return r/255, g/255, b/255
  end
  ---------------------------------------------------  
  function VF_GUI_DrawBackgroundButton(MOUSEt,OBJ,DATA)
    local grad_sz = DATA.GUIvars.grad_sz
    gfx.dest = 2
    gfx.setimgdim(2, -1, -1)
    gfx.setimgdim(2, grad_sz,grad_sz)
    local r,g,b,a = 1,1,1,0.6
    gfx.x, gfx.y = 0,0
    local c = 1
    local drdx = 0--c*0.001
    local drdy = 0--c*0.01
    local dgdx = 0--c*0.001
    local dgdy = 0--c*0.001    
    local dbdx = 0--c*0.00003
    local dbdy = 0--c*0.001
    local dadx = c*0.00015
    local dady = c*0.0001
    gfx.gradrect(0,0, grad_sz,grad_sz,
                    r,g,b,a,
                    drdx, dgdx, dbdx, dadx,
                    drdy, dgdy, dbdy, dady)
  end 
 ---------------------------------------------------
  function VF_GUI_DrawButton(MOUSEt,OBJ,DATA, o) 
    if not o.is_button then return end
    gfx.set(0,0,0,1)
    
    -- defaults
      local x = o.x or 0
      local y = o.y or 0
      local w = o.w or 100
      local h = o.h or 100
      local grad_back_a = o.grad_back_a or 1
      local highlight = o.highlight if highlight == nil then highlight = true end
      local undermouse_frame_a = o.undermouse_frame_a or 0.4
      local undermouse_frame_col = o.undermouse_frame_col or '#FFFFFF'
      local undermouse = o.undermouse or false
      local selected = o.selected or false
      local selection_a = o.selection_a or 0.2
      local selection_col = o.selection_col or '#FFFFFF'
    -- reset
      gfx.set(1,1,1,1) 
    
    -- gradient background 
      if grad_back_a > 0 then
        gfx.a = grad_back_a
        gfx.blit(2, 1, 0, -- buttons
            0,0,DATA.GUIvars.grad_sz,DATA.GUIvars.grad_sz,
            x,y,w,h, 0,0) 
        --[[gfx.blit(2, 1, math.rad(180), -- buttons
            0,DATA.GUIvars.grad_sz/2,DATA.GUIvars.grad_sz,DATA.GUIvars.grad_sz/2,
            x-1,y+h/2,w+1,h/2, 0,0) ]]            
      end
    
    -- rect under mouse
      if highlight ==true and undermouse and undermouse_frame_a > 0 then
        VF_hex2rgb(undermouse_frame_col, true)
        gfx.a = undermouse_frame_a
        VF_GUI_rect(x-1,y-1,w,h+1)
      end
    
    -- selection
      if selected then
        VF_hex2rgb(selection_col, true)
        gfx.a = selection_a
        gfx.rect(x,y,w,h)
      end  
      
    VF_GUI_DrawTxt(MOUSEt,OBJ,DATA, o) 
  end
  
 --------------------------------------------------- 
    function VF_GUI_rect(x,y,w,h)
      gfx.x,gfx.y = x,y
      gfx.lineto(x,y+h)
      gfx.x,gfx.y = x+1,y+h
      gfx.lineto(x+w,y+h)
      gfx.x,gfx.y = x+w,y+h-1
      gfx.lineto(x+w,y)
      gfx.x,gfx.y = x+w-1,y
      gfx.lineto(x+1,y)
    end 
 ---------------------------------------------------     
  function VF_GUI_DrawTxt(MOUSEt,OBJ,DATA, o) 
    local txt = o.txt
    if not txt then return end
    txt = tostring(txt)
    
    -- defaults
      local txt_a = o.txt_a or 0.8
      local x= o.x or 0
      local x = o.x or 0
      local y = o.y or 0
      local w = o.w or 100
      local h = o.h or 100
      local font = o.font or 'Calibri'
      local fontsz = o.fontsz or 12
      local font_flags = o.font_flags or ''
      local txt_col = o.txt_col or '#FFFFFF'
      local txt_a = o.txt_a or 1
      local drawstr_flags = o.drawstr_flags or 1|4
      
    gfx.set(1,1,1)
    gfx.x,gfx.y = x,y 
    VF_hex2rgb(txt_col, true)
    gfx.setfont(1,font, fontsz, font_flags )
    
    
    if gfx.measurestr(txt) <= w and not txt:match('[\r\n]+')then
      gfx.a = txt_a
      gfx.drawstr(txt,drawstr_flags,x+w,y+h )
     else
      if drawstr_flags&8==8 then drawstr_flags=drawstr_flags-8 end -- ignore vertical flags
      if drawstr_flags&4==4 then 
        drawstr_flags=drawstr_flags-4
        gfx.a = txt_a
        local texth = VF_GUI_DrawTxt_WrapTxt(txt,x,y,w,h,drawstr_flags, true) 
        VF_GUI_DrawTxt_WrapTxt(txt,x,y+h/2-texth/2,w,h,drawstr_flags, false) 
       else
        gfx.a = txt_a
        VF_GUI_DrawTxt_WrapTxt(txt,x,y,w,h,drawstr_flags, false) 
      end
    end
    --[[If flags, right ,bottom passed in:
    flags&1: center horizontally
    flags&2: right justify
    flags&4: center vertically
    flags&8: bottom justify
    flags&256: ignore right/bottom, otherwise text is clipped to (gfx.x, gfx.y, right, bottom)]]  
  end
  ---------------------------------------------------  
  function VF_GUI_DrawTxt_WrapTxt(txt, x,y,w,h, drawstr_flags,simulate) 
    local indent_replace = 'indent_custom'
    local y0 =y
    local ystep = gfx.texth
    for stroke in txt:gmatch('[^\r\n]+') do 
      local t = {}
      if stroke:find('%s') == 1 then
        local first_nonindent = stroke:find('[^%s]')
        if first_nonindent then
          str1 = stroke:sub(0,first_nonindent)
          str2 = stroke:sub(first_nonindent+1)
          stroke = str1:gsub('%s',indent_replace)..str2
        end
      end
      for word in stroke:gmatch('[^%s]+') do t[#t+1] = word end
      local s = ''
      for i = 1, #t do
        local s0 = s
        s = s..t[i]..' '
        s=s:gsub(indent_replace,' ')
        if gfx.measurestr( s) > w  then  
          gfx.y=y
          if not simulate then gfx.drawstr(s0,drawstr_flags,x+w,y+h) end
          s=t[i]..' '
          gfx.x=x
          y=y+ystep
        end 
        if i==#t then
         gfx.x=x
         gfx.y=y
         if not simulate then gfx.drawstr(s,drawstr_flags,x+w,y+h) end
        end
      end
      gfx.x=x
      y=y+ystep
      gfx.y=y
    end
    return gfx.y-y0
  end
    
---------------------------------------------------
  function VF_run()
    VF_MOUSE(MOUSEt,OBJ,DATA)
    --[[ 
      check for project change 
        &1 statechangecount 
        &2 edit cursor change 
        &4 minor XY position change 
        &8 WH dock position change
        &16 project change]]
      local project_change = VF_run_CheckProjUpdates(DATA) 
      if project_change&4==4 or project_change&8==8 then DATA.refresh.conf = DATA.refresh.conf|2 end -- save to ext state on XYWH change
      DATA.refresh.project_change = project_change
      
    -- save ext state
      if DATA.refresh.conf&1==1 or DATA.refresh.conf&2==2 then
        DATA.conf.dock , DATA.conf.wind_x, DATA.conf.wind_y, DATA.conf.wind_w,DATA.conf.wind_h= gfx.dock(-1, 0,0,0,0)
        VF_ExtState_Save(DATA.conf)
      end
      --if DATA.refresh.conf&1==1 or DATA.refresh.conf&4==4 then VF_ExtState_SaveProj(DATA.confproj,DATA.conf.ES_key) end
      --if DATA.refresh.conf&1==1 or DATA.refresh.conf&8==8 then VF_ExtState_SavePreset(DATA.conf,DATA.conf.preset_current) end
      DATA.refresh.conf = 0 
      
    -- do stuff
      if VF_DATA_UpdateAlways then VF_DATA_UpdateAlways(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&1==1 and VF_DATA_Init then VF_DATA_Init(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&2==2 and VF_DATA_Update then VF_DATA_Update(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&4==4 and VF_DATA_UpdateRead then VF_DATA_UpdateRead(MOUSEt,OBJ,DATA) end
      if DATA.refresh.data&8==8 and VF_DATA_UpdateWrite then VF_DATA_UpdateWrite(MOUSEt,OBJ,DATA) end
      DATA.refresh.data = 0
      
    -- refresh GUI
      if project_change&8==8 then DATA.refresh.GUI = DATA.refresh.GUI|2 end-- init buttons on window WH change 
      if (DATA.refresh.GUI&1==1 or DATA.refresh.GUI&2==2) and OBJ_Buttons_Init then OBJ_Buttons_Init(MOUSEt,OBJ,DATA) end -- init buttons
      if (DATA.refresh.GUI&1==1 or DATA.refresh.GUI&2==2 or DATA.refresh.GUI&4==4) and OBJ_Buttons_Update then OBJ_Buttons_Update(MOUSEt,OBJ,DATA) end -- update buttons 
      VF_GUI_draw(MOUSEt,OBJ,DATA)
      DATA.refresh.GUI = 0
      
    -- exit
      if MOUSEt.char >= 0 and MOUSEt.char ~= 27 then defer(VF_run) else   atexit(gfx.quit) end
     
  end     
  ---------------------------------------------------------------------
  function VF_run_initVars_SetColors(MOUSEt,OBJ,DATA) -- https://htmlcolorcodes.com/colors/
    return {        backgr = '#3f484d',
                    green = '#17B025',
                    blue = '#1792B0'}
  end  
  ---------------------------------------------------------------------  
  
mainstr=[[
FUNC10 reaper.APITest()
SNIP10_START
reaper.ShowConsoleMsg('Hello world') LINK523
reaper.APITest()
SNIP10_END
FUNC1 MediaItem reaper.AddMediaItemToTrack(MediaTrack tr)
DESC1 creates a new media item.
FUNC2 integer reaper.AddProjectMarker(ReaProject proj, boolean isrgn, number pos, number rgnend, string name, integer wantidx)
DESC2 Returns the index of the created marker/region, or -1 on failure. Supply wantidx>=0 if you want a particular index number, but you'll get a different index number a region and wantidx is already in use.
FUNC3 integer reaper.AddProjectMarker2(ReaProject proj, boolean isrgn, number pos, number rgnend, string name, integer wantidx, integer color)
DESC3 Returns the index of the created marker/region, or -1 on failure. Supply wantidx>=0 if you want a particular index number, but you'll get a different index number a region and wantidx is already in use. color should be 0 (default color), or ColorToNative(r,g,b)|0x1000000
FUNC4 integer reaper.AddRemoveReaScript(boolean add, integer sectionID, string scriptfn, boolean commit)
DESC4 Add a ReaScript (return the new command ID, or 0 if failed) or remove a ReaScript (return >0 on success). Use commit==true when adding/removing a single script. When bulk adding/removing n scripts, you can optimize the n-1 first calls with commit==false and commit==true for the last call.
FUNC5 MediaItem_Take reaper.AddTakeToMediaItem(MediaItem item)
DESC5 creates a new take in an item
FUNC6 boolean reaper.AddTempoTimeSigMarker(ReaProject proj, number timepos, number bpm, integer timesig_num, integer timesig_denom, boolean lineartempochange)
DESC6 Deprecated. Use SetTempoTimeSigMarker with ptidx=-1.
FUNC7 reaper.adjustZoom(number amt, integer forceset, boolean doupd, integer centermode)
DESC7 forceset=0,doupd=true,centermode=-1 for default
FUNC8 boolean reaper.AnyTrackSolo(ReaProject proj)
DESC8 
FUNC9 boolean reaper.APIExists(string function_name)
DESC9 Returns true if function_name exists in the REAPER API
DESC10 Displays a message window if the API was successfully called.
FUNC11 boolean reaper.ApplyNudge(ReaProject project, integer nudgeflag, integer nudgewhat, integer nudgeunits, number value, boolean reverse, integer copies)
DESC11 nudgeflag: &1=set to value (otherwise nudge by value), &2=snapnudgewhat: 0=position, 1=left trim, 2=left edge, 3=right edge, 4=contents, 5=duplicate, 6=edit cursornudgeunit: 0=ms, 1=seconds, 2=grid, 3=256th notes, ..., 15=whole notes, 16=measures.beats (1.15 = 1 measure + 1.5 beats), 17=samples, 18=frames, 19=pixels, 20=item lengths, 21=item selectionsvalue: amount to nudge by, or value to set toreverse: in nudge mode, nudges left (otherwise ignored)copies: in nudge duplicate mode, number of copies (otherwise ignored)
FUNC12 reaper.ArmCommand(integer cmd, string sectionname)
DESC12 arms a command (or disarms if 0 passed) in section sectionname (empty string for main)
FUNC13 reaper.Audio_Init()
DESC13 open all audio and MIDI devices, if not open
FUNC14 integer reaper.Audio_IsPreBuffer()
DESC14 is in pre-buffer? threadsafe
FUNC15 integer reaper.Audio_IsRunning()
DESC15 is audio running at all? threadsafe
FUNC16 reaper.Audio_Quit()
DESC16 close all audio and MIDI devices, if open
FUNC17 boolean reaper.AudioAccessorStateChanged(AudioAccessor accessor)
DESC17 Returns true if the underlying samples (track or media item take) have changed, but does not update the audio accessor, so the user can selectively call AudioAccessorValidateState only when needed. See CreateTakeAudioAccessor, CreateTrackAudioAccessor, DestroyAudioAccessor, GetAudioAccessorEndTime, GetAudioAccessorSamples.
FUNC18 reaper.AudioAccessorUpdate(AudioAccessor accessor)
DESC18 Force the accessor to reload its state from the underlying track or media item take. See CreateTakeAudioAccessor, CreateTrackAudioAccessor, DestroyAudioAccessor, AudioAccessorStateChanged, GetAudioAccessorStartTime, GetAudioAccessorEndTime, GetAudioAccessorSamples.
FUNC19 boolean reaper.AudioAccessorValidateState(AudioAccessor accessor)
DESC19 Validates the current state of the audio accessor -- must ONLY call this from the main thread. Returns true if the state changed.
FUNC20 reaper.BypassFxAllTracks(integer bypass)
DESC20 -1 = bypass all if not all bypassed,otherwise unbypass all
FUNC21 reaper.ClearAllRecArmed()
DESC21 
FUNC22 reaper.ClearConsole()
DESC22 Clear the ReaScript console. See ShowConsoleMsg
FUNC23 reaper.ClearPeakCache()
DESC23 resets the global peak caches
FUNC24 number r, number g, number b = reaper.ColorFromNative(integer col)
DESC24 Extract RGB values from an OS dependent color. See ColorToNative.
FUNC25 integer reaper.ColorToNative(integer r, integer g, integer b)
DESC25 Make an OS dependent color from RGB values (e.g. RGB() macro on Windows). r,g and b are in [0..255]. See ColorFromNative.
FUNC26 integer reaper.CountAutomationItems(TrackEnvelope env)
DESC26 Returns the number of automation items on this envelope. See GetSetAutomationItemInfo
FUNC27 integer reaper.CountEnvelopePoints(TrackEnvelope envelope)
DESC27 Returns the number of points in the envelope. See CountEnvelopePointsEx.
FUNC28 integer reaper.CountEnvelopePointsEx(TrackEnvelope envelope, integer autoitem_idx)
DESC28 Returns the number of points in the envelope.autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc.For automation items, pass autoitem_idx|0x10000000 to base ptidx on the number of points in one full loop iteration,even if the automation item is trimmed so that not all points are visible.Otherwise, ptidx will be based on the number of visible points in the automation item, including all loop iterations.See GetEnvelopePointEx, SetEnvelopePointEx, InsertEnvelopePointEx, DeleteEnvelopePointEx.
FUNC29 integer reaper.CountMediaItems(ReaProject proj)
DESC29 count the number of items in the project (proj=0 for active project)
FUNC30 integer retval, number num_markers, number num_regions = reaper.CountProjectMarkers(ReaProject proj)
DESC30 num_markersOut and num_regionsOut may be NULL.
FUNC31 integer reaper.CountSelectedMediaItems(ReaProject proj)
DESC31 count the number of selected items in the project (proj=0 for active project)
FUNC32 integer reaper.CountSelectedTracks(ReaProject proj)
DESC32 Count the number of selected tracks in the project (proj=0 for active project). This function ignores the master track, see CountSelectedTracks2.
FUNC33 integer reaper.CountSelectedTracks2(ReaProject proj, boolean wantmaster)
DESC33 Count the number of selected tracks in the project (proj=0 for active project).
FUNC34 integer reaper.CountTakeEnvelopes(MediaItem_Take take)
DESC34 See GetTakeEnvelope
FUNC35 integer reaper.CountTakes(MediaItem item)
DESC35 count the number of takes in the item
FUNC36 integer reaper.CountTCPFXParms(ReaProject project, MediaTrack track)
DESC36 Count the number of FX parameter knobs displayed on the track control panel.
FUNC37 integer reaper.CountTempoTimeSigMarkers(ReaProject proj)
DESC37 Count the number of tempo/time signature markers in the project. See GetTempoTimeSigMarker, SetTempoTimeSigMarker, AddTempoTimeSigMarker.
FUNC38 integer reaper.CountTrackEnvelopes(MediaTrack track)
DESC38 see GetTrackEnvelope
FUNC39 integer reaper.CountTrackMediaItems(MediaTrack track)
DESC39 count the number of items in the track
FUNC40 integer reaper.CountTracks(ReaProject proj)
DESC40 count the number of tracks in the project (proj=0 for active project)
FUNC41 MediaItem reaper.CreateNewMIDIItemInProj(MediaTrack track, number starttime, number endtime, optional boolean qnIn)
DESC41 Create a new MIDI media item, containing no MIDI events. Time is in seconds unless qn is set.
FUNC42 AudioAccessor reaper.CreateTakeAudioAccessor(MediaItem_Take take)
DESC42 Create an audio accessor object for this take. Must only call from the main thread. See CreateTrackAudioAccessor, DestroyAudioAccessor, AudioAccessorStateChanged, GetAudioAccessorStartTime, GetAudioAccessorEndTime, GetAudioAccessorSamples.
FUNC43 AudioAccessor reaper.CreateTrackAudioAccessor(MediaTrack track)
DESC43 Create an audio accessor object for this track. Must only call from the main thread. See CreateTakeAudioAccessor, DestroyAudioAccessor, AudioAccessorStateChanged, GetAudioAccessorStartTime, GetAudioAccessorEndTime, GetAudioAccessorSamples.
FUNC44 integer reaper.CreateTrackSend(MediaTrack tr, MediaTrack desttrIn)
DESC44 Create a send/receive (desttrInOptional!=NULL), or a hardware output (desttrInOptional==NULL) with default properties, return >=0 on success (== new send/receive index). See RemoveTrackSend, GetSetTrackSendInfo, GetTrackSendInfo_Value, SetTrackSendInfo_Value.
FUNC45 reaper.CSurf_FlushUndo(boolean force)
DESC45 call this to force flushing of the undo states after using CSurf_On*Change()
FUNC46 boolean reaper.CSurf_GetTouchState(MediaTrack trackid, integer isPan)
DESC46 
FUNC47 reaper.CSurf_GoEnd()
DESC47 
FUNC48 reaper.CSurf_GoStart()
DESC48 
FUNC49 integer reaper.CSurf_NumTracks(boolean mcpView)
DESC49 
FUNC50 reaper.CSurf_OnArrow(integer whichdir, boolean wantzoom)
DESC50 
FUNC51 reaper.CSurf_OnFwd(integer seekplay)
DESC51 
FUNC52 boolean reaper.CSurf_OnFXChange(MediaTrack trackid, integer en)
DESC52 
FUNC53 integer reaper.CSurf_OnInputMonitorChange(MediaTrack trackid, integer monitor)
DESC53 
FUNC54 integer reaper.CSurf_OnInputMonitorChangeEx(MediaTrack trackid, integer monitor, boolean allowgang)
DESC54 
FUNC55 boolean reaper.CSurf_OnMuteChange(MediaTrack trackid, integer mute)
DESC55 
FUNC56 boolean reaper.CSurf_OnMuteChangeEx(MediaTrack trackid, integer mute, boolean allowgang)
DESC56 
FUNC57 number reaper.CSurf_OnPanChange(MediaTrack trackid, number pan, boolean relative)
DESC57 
FUNC58 number reaper.CSurf_OnPanChangeEx(MediaTrack trackid, number pan, boolean relative, boolean allowGang)
DESC58 
FUNC59 reaper.CSurf_OnPause()
DESC59 
FUNC60 reaper.CSurf_OnPlay()
DESC60 
FUNC61 reaper.CSurf_OnPlayRateChange(number playrate)
DESC61 
FUNC62 boolean reaper.CSurf_OnRecArmChange(MediaTrack trackid, integer recarm)
DESC62 
FUNC63 boolean reaper.CSurf_OnRecArmChangeEx(MediaTrack trackid, integer recarm, boolean allowgang)
DESC63 
FUNC64 reaper.CSurf_OnRecord()
DESC64 
FUNC65 number reaper.CSurf_OnRecvPanChange(MediaTrack trackid, integer recv_index, number pan, boolean relative)
DESC65 
FUNC66 number reaper.CSurf_OnRecvVolumeChange(MediaTrack trackid, integer recv_index, number volume, boolean relative)
DESC66 
FUNC67 reaper.CSurf_OnRew(integer seekplay)
DESC67 
FUNC68 reaper.CSurf_OnRewFwd(integer seekplay, integer dir)
DESC68 
FUNC69 reaper.CSurf_OnScroll(integer xdir, integer ydir)
DESC69 
FUNC70 boolean reaper.CSurf_OnSelectedChange(MediaTrack trackid, integer selected)
DESC70 
FUNC71 number reaper.CSurf_OnSendPanChange(MediaTrack trackid, integer send_index, number pan, boolean relative)
DESC71 
FUNC72 number reaper.CSurf_OnSendVolumeChange(MediaTrack trackid, integer send_index, number volume, boolean relative)
DESC72 
FUNC73 boolean reaper.CSurf_OnSoloChange(MediaTrack trackid, integer solo)
DESC73 
FUNC74 boolean reaper.CSurf_OnSoloChangeEx(MediaTrack trackid, integer solo, boolean allowgang)
DESC74 
FUNC75 reaper.CSurf_OnStop()
DESC75 
FUNC76 reaper.CSurf_OnTempoChange(number bpm)
DESC76 
FUNC77 reaper.CSurf_OnTrackSelection(MediaTrack trackid)
DESC77 
FUNC78 number reaper.CSurf_OnVolumeChange(MediaTrack trackid, number volume, boolean relative)
DESC78 
FUNC79 number reaper.CSurf_OnVolumeChangeEx(MediaTrack trackid, number volume, boolean relative, boolean allowGang)
DESC79 
FUNC80 number reaper.CSurf_OnWidthChange(MediaTrack trackid, number width, boolean relative)
DESC80 
FUNC81 number reaper.CSurf_OnWidthChangeEx(MediaTrack trackid, number width, boolean relative, boolean allowGang)
DESC81 
FUNC82 reaper.CSurf_OnZoom(integer xdir, integer ydir)
DESC82 
FUNC83 reaper.CSurf_ResetAllCachedVolPanStates()
DESC83 
FUNC84 reaper.CSurf_ScrubAmt(number amt)
DESC84 
FUNC85 reaper.CSurf_SetAutoMode(integer mode, IReaperControlSurface ignoresurf)
DESC85 
FUNC86 reaper.CSurf_SetPlayState(boolean play, boolean pause, boolean rec, IReaperControlSurface ignoresurf)
DESC86 
FUNC87 reaper.CSurf_SetRepeatState(boolean rep, IReaperControlSurface ignoresurf)
DESC87 
FUNC88 reaper.CSurf_SetSurfaceMute(MediaTrack trackid, boolean mute, IReaperControlSurface ignoresurf)
DESC88 
FUNC89 reaper.CSurf_SetSurfacePan(MediaTrack trackid, number pan, IReaperControlSurface ignoresurf)
DESC89 
FUNC90 reaper.CSurf_SetSurfaceRecArm(MediaTrack trackid, boolean recarm, IReaperControlSurface ignoresurf)
DESC90 
FUNC91 reaper.CSurf_SetSurfaceSelected(MediaTrack trackid, boolean selected, IReaperControlSurface ignoresurf)
DESC91 
FUNC92 reaper.CSurf_SetSurfaceSolo(MediaTrack trackid, boolean solo, IReaperControlSurface ignoresurf)
DESC92 
FUNC93 reaper.CSurf_SetSurfaceVolume(MediaTrack trackid, number volume, IReaperControlSurface ignoresurf)
DESC93 
FUNC94 reaper.CSurf_SetTrackListChange()
DESC94 
FUNC95 MediaTrack reaper.CSurf_TrackFromID(integer idx, boolean mcpView)
DESC95 
FUNC96 integer reaper.CSurf_TrackToID(MediaTrack track, boolean mcpView)
DESC96 
FUNC97 number reaper.DB2SLIDER(number x)
DESC97 
FUNC98 boolean reaper.DeleteEnvelopePointEx(TrackEnvelope envelope, integer autoitem_idx, integer ptidx)
DESC98 Delete an envelope point. If setting multiple points at once, set noSort=true, and call Envelope_SortPoints when done.autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc.For automation items, pass autoitem_idx|0x10000000 to base ptidx on the number of points in one full loop iteration,even if the automation item is trimmed so that not all points are visible.Otherwise, ptidx will be based on the number of visible points in the automation item, including all loop iterations.See CountEnvelopePointsEx, GetEnvelopePointEx, SetEnvelopePointEx, InsertEnvelopePointEx.
FUNC99 boolean reaper.DeleteEnvelopePointRange(TrackEnvelope envelope, number time_start, number time_end)
DESC99 Delete a range of envelope points. See DeleteEnvelopePointRangeEx, DeleteEnvelopePointEx.
FUNC100 boolean reaper.DeleteEnvelopePointRangeEx(TrackEnvelope envelope, integer autoitem_idx, number time_start, number time_end)
DESC100 Delete a range of envelope points. autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc.
FUNC101 reaper.DeleteExtState(string section, string key, boolean persist)
DESC101 Delete the extended state value for a specific section and key. persist=true means the value should remain deleted the next time REAPER is opened. See SetExtState, GetExtState, HasExtState.
FUNC102 boolean reaper.DeleteProjectMarker(ReaProject proj, integer markrgnindexnumber, boolean isrgn)
DESC102 Delete a marker. proj==NULL for the active project.
FUNC103 boolean reaper.DeleteProjectMarkerByIndex(ReaProject proj, integer markrgnidx)
DESC103 Differs from DeleteProjectMarker only in that markrgnidx is 0 for the first marker/region, 1 for the next, etc (see EnumProjectMarkers3), rather than representing the displayed marker/region ID number (see SetProjectMarker4).
FUNC104 boolean reaper.DeleteTakeMarker(MediaItem_Take take, integer idx)
DESC104 Delete a take marker. Note that idx will change for all following take markers. See GetNumTakeMarkers, GetTakeMarker, SetTakeMarker
FUNC105 integer reaper.DeleteTakeStretchMarkers(MediaItem_Take take, integer idx, optional number countIn)
DESC105 Deletes one or more stretch markers. Returns number of stretch markers deleted.
FUNC106 boolean reaper.DeleteTempoTimeSigMarker(ReaProject project, integer markerindex)
DESC106 Delete a tempo/time signature marker.
FUNC107 reaper.DeleteTrack(MediaTrack tr)
DESC107 deletes a track
FUNC108 boolean reaper.DeleteTrackMediaItem(MediaTrack tr, MediaItem it)
DESC108 
FUNC109 reaper.DestroyAudioAccessor(AudioAccessor accessor)
DESC109 Destroy an audio accessor. Must only call from the main thread. See CreateTakeAudioAccessor, CreateTrackAudioAccessor, AudioAccessorStateChanged, GetAudioAccessorStartTime, GetAudioAccessorEndTime, GetAudioAccessorSamples.
FUNC110 reaper.Dock_UpdateDockID(string ident_str, integer whichDock)
DESC110 updates preference for docker window ident_str to be in dock whichDock on next open
FUNC111 integer reaper.DockGetPosition(integer whichDock)
DESC111 -1=not found, 0=bottom, 1=left, 2=top, 3=right, 4=floating
FUNC112 integer retval, boolean isFloatingDocker = reaper.DockIsChildOfDock(HWND hwnd)
DESC112 returns dock index that contains hwnd, or -1
FUNC113 reaper.DockWindowActivate(HWND hwnd)
DESC113 
FUNC114 reaper.DockWindowAdd(HWND hwnd, string name, integer pos, boolean allowShow)
DESC114 
FUNC115 reaper.DockWindowAddEx(HWND hwnd, string name, string identstr, boolean allowShow)
DESC115 
FUNC116 reaper.DockWindowRefresh()
DESC116 
FUNC117 reaper.DockWindowRefreshForHWND(HWND hwnd)
DESC117 
FUNC118 reaper.DockWindowRemove(HWND hwnd)
DESC118 
FUNC119 boolean reaper.EditTempoTimeSigMarker(ReaProject project, integer markerindex)
DESC119 Open the tempo/time signature marker editor dialog.
FUNC120 numberr.left, numberr.top, numberr.right, numberr.bot = reaper.EnsureNotCompletelyOffscreen(numberr.left, numberr.top, numberr.right, numberr.bot)
DESC120 call with a saved window rect for your window and it'll correct any positioning info.
FUNC121 string reaper.EnumerateFiles(string path, integer fileindex)
DESC121 List the files in the "path" directory. Returns NULL/nil when all files have been listed. Use fileindex = -1 to force re-read of directory (invalidate cache). See EnumerateSubdirectories
FUNC122 string reaper.EnumerateSubdirectories(string path, integer subdirindex)
DESC122 List the subdirectories in the "path" directory. Use subdirindex = -1 to force re-read of directory (invalidate cache). Returns NULL/nil when all subdirectories have been listed. See EnumerateFiles
FUNC123 boolean retval, string str = reaper.EnumPitchShiftModes(integer mode)
DESC123 Start querying modes at 0, returns FALSE when no more modes possible, sets strOut to NULL if a mode is currently unsupported
FUNC124 string reaper.EnumPitchShiftSubModes(integer mode, integer submode)
DESC124 Returns submode name, or NULL
FUNC125 integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber = reaper.EnumProjectMarkers(integer idx)
DESC125 
FUNC126 integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber = reaper.EnumProjectMarkers2(ReaProject proj, integer idx)
DESC126 
FUNC127 integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber, number color = reaper.EnumProjectMarkers3(ReaProject proj, integer idx)
DESC127 
FUNC128 ReaProject retval, optional string projfn = reaper.EnumProjects(integer idx)
DESC128 idx=-1 for current project,projfn can be NULL if not interested in filename. use idx 0x40000000 for currently rendering project, if any.
FUNC129 boolean retval, optional string key, optional string val = reaper.EnumProjExtState(ReaProject proj, string extname, integer idx)
DESC129 Enumerate the data stored with the project for a specific extname. Returns false when there is no more data. See SetProjExtState, GetProjExtState.
FUNC130 MediaTrack reaper.EnumRegionRenderMatrix(ReaProject proj, integer regionindex, integer rendertrack)
DESC130 Enumerate which tracks will be rendered within this region when using the region render matrix. When called with rendertrack==0, the function returns the first track that will be rendered (which may be the master track); rendertrack==1 will return the next track rendered, and so on. The function returns NULL when there are no more tracks that will be rendered within this region.
FUNC131 boolean retval, string programName = reaper.EnumTrackMIDIProgramNames(integer track, integer programNumber, string programName)
DESC131 returns false if there are no plugins on the track that support MIDI programs,or if all programs have been enumerated
FUNC132 boolean retval, string programName = reaper.EnumTrackMIDIProgramNamesEx(ReaProject proj, MediaTrack track, integer programNumber, string programName)
DESC132 returns false if there are no plugins on the track that support MIDI programs,or if all programs have been enumerated
FUNC133 integer retval, optional number value, optional number dVdS, optional number ddVdS, optional number dddVdS = reaper.Envelope_Evaluate(TrackEnvelope envelope, number time, number samplerate, integer samplesRequested)
DESC133 Get the effective envelope value at a given time position. samplesRequested is how long the caller expects until the next call to Envelope_Evaluate (often, the buffer block size). The return value is how many samples beyond that time position that the returned values are valid. dVdS is the change in value per sample (first derivative), ddVdS is the second derivative, dddVdS is the third derivative. See GetEnvelopeScalingMode.
FUNC134 string buf = reaper.Envelope_FormatValue(TrackEnvelope env, number value)
DESC134 Formats the value of an envelope to a user-readable form
FUNC135 MediaItem_Take retval, optional number index, optional number index2 = reaper.Envelope_GetParentTake(TrackEnvelope env)
DESC135 If take envelope, gets the take from the envelope. If FX, indexOutOptional set to FX index, index2OutOptional set to parameter index, otherwise -1.
FUNC136 MediaTrack retval, optional number index, optional number index2 = reaper.Envelope_GetParentTrack(TrackEnvelope env)
DESC136 If track envelope, gets the track from the envelope. If FX, indexOutOptional set to FX index, index2OutOptional set to parameter index, otherwise -1.
FUNC137 boolean reaper.Envelope_SortPoints(TrackEnvelope envelope)
DESC137 Sort envelope points by time. See SetEnvelopePoint, InsertEnvelopePoint.
FUNC138 boolean reaper.Envelope_SortPointsEx(TrackEnvelope envelope, integer autoitem_idx)
DESC138 Sort envelope points by time. autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc. See SetEnvelopePoint, InsertEnvelopePoint.
FUNC139 string reaper.ExecProcess(string cmdline, integer timeoutmsec)
DESC139 Executes command line, returns NULL on total failure, otherwise the return value, a newline, and then the output of the command. If timeoutmsec is 0, command will be allowed to run indefinitely (recommended for large amounts of returned output). timeoutmsec is -1 for no wait/terminate, -2 for no wait and minimize
FUNC140 boolean reaper.file_exists(string path)
DESC140 returns true if path points to a valid, readable file
FUNC141 integer reaper.FindTempoTimeSigMarker(ReaProject project, number time)
DESC141 Find the tempo/time signature marker that falls at or before this time position (the marker that is in effect as of this time position).
FUNC142 string buf = reaper.format_timestr(number tpos, string buf)
DESC142 Format tpos (which is time in seconds) as hh:mm:ss.sss. See format_timestr_pos, format_timestr_len.
FUNC143 string buf = reaper.format_timestr_len(number tpos, string buf, number offset, integer modeoverride)
DESC143 time formatting mode overrides: -1=proj default.0=time1=measures.beats + time2=measures.beats3=seconds4=samples5=h:m:s:foffset is start of where the length will be calculated from
FUNC144 string buf = reaper.format_timestr_pos(number tpos, string buf, integer modeoverride)
DESC144 time formatting mode overrides: -1=proj default.0=time1=measures.beats + time2=measures.beats3=seconds4=samples5=h:m:s:f
FUNC145 string gGUID = reaper.genGuid(string gGUID)
DESC145 
FUNC146 boolean retval, string buf = reaper.get_config_var_string(string name)
DESC146 gets ini configuration variable value as string
FUNC147 string reaper.get_ini_file()
DESC147 Get reaper.ini full filename.
FUNC148 MediaItem_Take reaper.GetActiveTake(MediaItem item)
DESC148 get the active take in this item
FUNC149 integer reaper.GetAllProjectPlayStates(ReaProject ignoreProject)
DESC149 returns the bitwise OR of all project play states (1=playing, 2=pause, 4=recording)
FUNC150 string reaper.GetAppVersion()
DESC150 Returns app version which may include an OS/arch signifier, such as: "6.17" (windows 32-bit), "6.17/x64" (windows 64-bit), "6.17/OSX64" (macOS 64-bit Intel), "6.17/OSX" (macOS 32-bit), "6.17/macOS-arm64", "6.17/linux-x86_64", "6.17/linux-i686", "6.17/linux-aarch64", "6.17/linux-armv7l", etc
FUNC151 integer retval, string sec = reaper.GetArmedCommand()
DESC151 gets the currently armed command and section name (returns 0 if nothing armed). section name is empty-string for main section.
FUNC152 number reaper.GetAudioAccessorEndTime(AudioAccessor accessor)
DESC152 Get the end time of the audio that can be returned from this accessor. See CreateTakeAudioAccessor, CreateTrackAudioAccessor, DestroyAudioAccessor, AudioAccessorStateChanged, GetAudioAccessorStartTime, GetAudioAccessorSamples.
FUNC153 string hashNeed128 = reaper.GetAudioAccessorHash(AudioAccessor accessor, string hashNeed128)
DESC153 Deprecated. See AudioAccessorStateChanged instead.
FUNC154 integer reaper.GetAudioAccessorSamples(AudioAccessor accessor, integer samplerate, integer numchannels, number starttime_sec, integer numsamplesperchannel, reaper.array samplebuffer)
DESC154 Get a block of samples from the audio accessor. Samples are extracted immediately pre-FX, and returned interleaved (first sample of first channel, first sample of second channel...). Returns 0 if no audio, 1 if audio, -1 on error. See CreateTakeAudioAccessor, CreateTrackAudioAccessor, DestroyAudioAccessor, AudioAccessorStateChanged, GetAudioAccessorStartTime, GetAudioAccessorEndTime.This function has special handling in Python, and only returns two objects, the API function return value, and the sample buffer. Example usage:tr = RPR_GetTrack(0, 0)aa = RPR_CreateTrackAudioAccessor(tr)buf = list([0]*2*1024) # 2 channels, 1024 samples each, initialized to zeropos = 0.0(ret, buf) = GetAudioAccessorSamples(aa, 44100, 2, pos, 1024, buf)# buf now holds the first 2*1024 audio samples from the track.# typically GetAudioAccessorSamples() would be called within a loop, increasing pos each time.
FUNC155 number reaper.GetAudioAccessorStartTime(AudioAccessor accessor)
DESC155 Get the start time of the audio that can be returned from this accessor. See CreateTakeAudioAccessor, CreateTrackAudioAccessor, DestroyAudioAccessor, AudioAccessorStateChanged, GetAudioAccessorEndTime, GetAudioAccessorSamples.
FUNC156 boolean retval, string desc = reaper.GetAudioDeviceInfo(string attribute, string desc)
DESC156 get information about the currently open audio device. attribute can be MODE, IDENT_IN, IDENT_OUT, BSIZE, SRATE, BPS. returns false if unknown attribute or device not open.
FUNC157 integer reaper.GetConfigWantsDock(string ident_str)
DESC157 gets the dock ID desired by ident_str, if any
FUNC158 ReaProject reaper.GetCurrentProjectInLoadSave()
DESC158 returns current project if in load/save (usually only used from project_config_extension_t)
FUNC159 integer reaper.GetCursorContext()
DESC159 return the current cursor context: 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown
FUNC160 integer reaper.GetCursorContext2(boolean want_last_valid)
DESC160 0 if track panels, 1 if items, 2 if envelopes, otherwise unknown (unlikely when want_last_valid is true)
FUNC161 number reaper.GetCursorPosition()
DESC161 edit cursor position
FUNC162 number reaper.GetCursorPositionEx(ReaProject proj)
DESC162 edit cursor position
FUNC163 integer reaper.GetDisplayedMediaItemColor(MediaItem item)
DESC163 see GetDisplayedMediaItemColor2.
FUNC164 integer reaper.GetDisplayedMediaItemColor2(MediaItem item, MediaItem_Take take)
DESC164 Returns the custom take, item, or track color that is used (according to the user preference) to color the media item. The returned color is OS dependent|0x01000000 (i.e. ColorToNative(r,g,b)|0x01000000), so a return of zero means "no color", not black.
FUNC165 number reaper.GetEnvelopeInfo_Value(TrackEnvelope tr, string parmname)
DESC165 Gets an envelope numerical-value attribute:I_TCPY : int *, Y offset of envelope relative to parent track (may be separate lane or overlap with track contents)I_TCPH : int *, visible height of envelopeI_TCPY_USED : int *, Y offset of envelope relative to parent track, exclusive of paddingI_TCPH_USED : int *, visible height of envelope, exclusive of paddingP_TRACK : MediaTrack *, parent track pointer (if any)P_ITEM : MediaItem *, parent item pointer (if any)P_TAKE : MediaItem_Take *, parent take pointer (if any)
FUNC166 boolean retval, string buf = reaper.GetEnvelopeName(TrackEnvelope env)
DESC166 
FUNC167 boolean retval, optional number time, optional number value, optional number shape, optional number tension, optional boolean selected = reaper.GetEnvelopePoint(TrackEnvelope envelope, integer ptidx)
DESC167 Get the attributes of an envelope point. See GetEnvelopePointEx.
FUNC168 integer reaper.GetEnvelopePointByTime(TrackEnvelope envelope, number time)
DESC168 Returns the envelope point at or immediately prior to the given time position. See GetEnvelopePointByTimeEx.
FUNC169 integer reaper.GetEnvelopePointByTimeEx(TrackEnvelope envelope, integer autoitem_idx, number time)
DESC169 Returns the envelope point at or immediately prior to the given time position.autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc.For automation items, pass autoitem_idx|0x10000000 to base ptidx on the number of points in one full loop iteration,even if the automation item is trimmed so that not all points are visible.Otherwise, ptidx will be based on the number of visible points in the automation item, including all loop iterations.See GetEnvelopePointEx, SetEnvelopePointEx, InsertEnvelopePointEx, DeleteEnvelopePointEx.
FUNC170 boolean retval, optional number time, optional number value, optional number shape, optional number tension, optional boolean selected = reaper.GetEnvelopePointEx(TrackEnvelope envelope, integer autoitem_idx, integer ptidx)
DESC170 Get the attributes of an envelope point.autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc.For automation items, pass autoitem_idx|0x10000000 to base ptidx on the number of points in one full loop iteration,even if the automation item is trimmed so that not all points are visible.Otherwise, ptidx will be based on the number of visible points in the automation item, including all loop iterations.See CountEnvelopePointsEx, SetEnvelopePointEx, InsertEnvelopePointEx, DeleteEnvelopePointEx.
FUNC171 integer reaper.GetEnvelopeScalingMode(TrackEnvelope env)
DESC171 Returns the envelope scaling mode: 0=no scaling, 1=fader scaling. All API functions deal with raw envelope point values, to convert raw from/to scaled values see ScaleFromEnvelopeMode, ScaleToEnvelopeMode.
FUNC172 boolean retval, string str = reaper.GetEnvelopeStateChunk(TrackEnvelope env, string str, boolean isundo)
DESC172 Gets the RPPXML state of an envelope, returns true if successful. Undo flag is a performance/caching hint.
FUNC173 string reaper.GetExePath()
DESC173 returns path of REAPER.exe (not including EXE), i.e. C:\Program Files\REAPER
FUNC174 string reaper.GetExtState(string section, string key)
DESC174 Get the extended state value for a specific section and key. See SetExtState, DeleteExtState, HasExtState.
FUNC175 integer retval, number tracknumber, number itemnumber, number fxnumber = reaper.GetFocusedFX()
DESC175 This function is deprecated (returns GetFocusedFX2()&3), see GetFocusedFX2.
FUNC176 integer retval, number tracknumber, number itemnumber, number fxnumber = reaper.GetFocusedFX2()
DESC176 Return value has 1 set if track FX, 2 if take/item FX, 4 set if FX is no longer focused but still open. tracknumber==0 means the master track, 1 means track 1, etc. itemnumber is zero-based (or -1 if not an item). For interpretation of fxnumber, see GetLastTouchedFX.
FUNC177 integer reaper.GetFreeDiskSpaceForRecordPath(ReaProject proj, integer pathidx)
DESC177 returns free disk space in megabytes, pathIdx 0 for normal, 1 for alternate.
FUNC178 TrackEnvelope reaper.GetFXEnvelope(MediaTrack track, integer fxindex, integer parameterindex, boolean create)
DESC178 Returns the FX parameter envelope. If the envelope does not exist and create=true, the envelope will be created.
FUNC179 integer reaper.GetGlobalAutomationOverride()
DESC179 return -1=no override, 0=trim/read, 1=read, 2=touch, 3=write, 4=latch, 5=bypass
FUNC180 number reaper.GetHZoomLevel()
DESC180 returns pixels/second
FUNC181 string reaper.GetInputChannelName(integer channelIndex)
DESC181 
FUNC182 number inputlatency, number outputLatency = reaper.GetInputOutputLatency()
DESC182 Gets the audio device input/output latency in samples
FUNC183 number, PCM_source which_item, number flags = reaper.GetItemEditingTime2()
DESC183 returns time of relevant edit, set which_item to the pcm_source (if applicable), flags (if specified) will be set to 1 for edge resizing, 2 for fade change, 4 for item move, 8 for item slip edit (edit cursor time or start of item)
FUNC184 MediaItem, MediaItem_Take take = reaper.GetItemFromPoint(integer screen_x, integer screen_y, boolean allow_locked)
DESC184 Returns the first item at the screen coordinates specified. If allow_locked is false, locked items are ignored. If takeOutOptional specified, returns the take hit.
FUNC185 ReaProject reaper.GetItemProjectContext(MediaItem item)
DESC185 
FUNC186 boolean retval, string str = reaper.GetItemStateChunk(MediaItem item, string str, boolean isundo)
DESC186 Gets the RPPXML state of an item, returns true if successful. Undo flag is a performance/caching hint.
FUNC187 string reaper.GetLastColorThemeFile()
DESC187 
FUNC188 number markeridx, number regionidx = reaper.GetLastMarkerAndCurRegion(ReaProject proj, number time)
DESC188 Get the last project marker before time, and/or the project region that includes time. markeridx and regionidx are returned not necessarily as the displayed marker/region index, but as the index that can be passed to EnumProjectMarkers. Either or both of markeridx and regionidx may be NULL. See EnumProjectMarkers.
FUNC189 boolean retval, number tracknumber, number fxnumber, number paramnumber = reaper.GetLastTouchedFX()
DESC189 Returns true if the last touched FX parameter is valid, false otherwise. The low word of tracknumber is the 1-based track index -- 0 means the master track, 1 means track 1, etc. If the high word of tracknumber is nonzero, it refers to the 1-based item index (1 is the first item on the track, etc). For track FX, the low 24 bits of fxnumber refer to the FX index in the chain, and if the next 8 bits are 01, then the FX is record FX. For item FX, the low word defines the FX index in the chain, and the high word defines the take number.
FUNC190 MediaTrack reaper.GetLastTouchedTrack()
DESC190 
FUNC191 HWND reaper.GetMainHwnd()
DESC191 
FUNC192 integer reaper.GetMasterMuteSoloFlags()
DESC192 &1=master mute,&2=master solo. This is deprecated as you can just query the master track as well.
FUNC193 MediaTrack reaper.GetMasterTrack(ReaProject proj)
DESC193 
FUNC194 integer reaper.GetMasterTrackVisibility()
DESC194 returns &1 if the master track is visible in the TCP, &2 if NOT visible in the mixer. See SetMasterTrackVisibility.
FUNC195 integer reaper.GetMaxMidiInputs()
DESC195 returns max dev for midi inputs/outputs
FUNC196 integer reaper.GetMaxMidiOutputs()
DESC196 
FUNC197 integer retval, string buf = reaper.GetMediaFileMetadata(PCM_source mediaSource, string identifier)
DESC197 Get text-based metadata from a media file for a given identifier. Call with identifier="" to list all identifiers contained in the file, separated by newlines. May return "[Binary data]" for metadata that REAPER doesn't handle.
FUNC198 MediaItem reaper.GetMediaItem(ReaProject proj, integer itemidx)
DESC198 get an item from a project by item count (zero-based) (proj=0 for active project)
FUNC199 MediaTrack reaper.GetMediaItem_Track(MediaItem item)
DESC199 Get parent track of media item
FUNC200 number reaper.GetMediaItemInfo_Value(MediaItem item, string parmname)
DESC200 Get media item numerical-value attributes.B_MUTE : bool * : muted (item solo overrides). setting this value will clear C_MUTE_SOLO.B_MUTE_ACTUAL : bool * : muted (ignores solo). setting this value will not affect C_MUTE_SOLO.C_MUTE_SOLO : char * : solo override (-1=soloed, 0=no override, 1=unsoloed). note that this API does not automatically unsolo other items when soloing (nor clear the unsolos when clearing the last soloed item), it must be done by the caller via action or via this API.B_LOOPSRC : bool * : loop sourceB_ALLTAKESPLAY : bool * : all takes playB_UISEL : bool * : selected in arrange viewC_BEATATTACHMODE : char * : item timebase, -1=track or project default, 1=beats (position, length, rate), 2=beats (position only). for auto-stretch timebase: C_BEATATTACHMODE=1, C_AUTOSTRETCH=1C_AUTOSTRETCH: : char * : auto-stretch at project tempo changes, 1=enabled, requires C_BEATATTACHMODE=1C_LOCK : char * : locked, &1=lockedD_VOL : double * : item volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etcD_POSITION : double * : item position in secondsD_LENGTH : double * : item length in secondsD_SNAPOFFSET : double * : item snap offset in secondsD_FADEINLEN : double * : item manual fadein length in secondsD_FADEOUTLEN : double * : item manual fadeout length in secondsD_FADEINDIR : double * : item fadein curvature, -1..1D_FADEOUTDIR : double * : item fadeout curvature, -1..1D_FADEINLEN_AUTO : double * : item auto-fadein length in seconds, -1=no auto-fadeinD_FADEOUTLEN_AUTO : double * : item auto-fadeout length in seconds, -1=no auto-fadeoutC_FADEINSHAPE : int * : fadein shape, 0..6, 0=linearC_FADEOUTSHAPE : int * : fadeout shape, 0..6, 0=linearI_GROUPID : int * : group ID, 0=no groupI_LASTY : int * : Y-position of track in pixels (read-only)I_LASTH : int * : height in track in pixels (read-only)I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). If you do not |0x100000, then it will not be used, but will store the colorI_CURTAKE : int * : active take numberIP_ITEMNUMBER : int, item number on this track (read-only, returns the item number directly)F_FREEMODE_Y : float * : free item positioning Y-position, 0=top of track, 1=bottom of track (will never be 1)F_FREEMODE_H : float * : free item positioning height, 0=no height, 1=full height of track (will never be 0)P_TRACK : MediaTrack * (read-only)
FUNC201 integer reaper.GetMediaItemNumTakes(MediaItem item)
DESC201 
FUNC202 MediaItem_Take reaper.GetMediaItemTake(MediaItem item, integer tk)
DESC202 
FUNC203 MediaItem reaper.GetMediaItemTake_Item(MediaItem_Take take)
DESC203 Get parent item of media item take
FUNC204 integer reaper.GetMediaItemTake_Peaks(MediaItem_Take take, number peakrate, number starttime, integer numchannels, integer numsamplesperchannel, integer want_extra_type, reaper.array buf)
DESC204 Gets block of peak samples to buf. Note that the peak samples are interleaved, but in two or three blocks (maximums, then minimums, then extra). Return value has 20 bits of returned sample count, then 4 bits of output_mode (0xf00000), then a bit to signify whether extra_type was available (0x1000000). extra_type can be 115 ('s') for spectral information, which will return peak samples as integers with the low 15 bits frequency, next 14 bits tonality.
FUNC205 PCM_source reaper.GetMediaItemTake_Source(MediaItem_Take take)
DESC205 Get media source of media item take
FUNC206 MediaTrack reaper.GetMediaItemTake_Track(MediaItem_Take take)
DESC206 Get parent track of media item take
FUNC207 MediaItem_Take reaper.GetMediaItemTakeByGUID(ReaProject project, string guidGUID)
DESC207 
FUNC208 number reaper.GetMediaItemTakeInfo_Value(MediaItem_Take take, string parmname)
DESC208 Get media item take numerical-value attributes.D_STARTOFFS : double * : start offset in source media, in secondsD_VOL : double * : take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flippedD_PAN : double * : take pan, -1..1D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etcD_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etcD_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etcB_PPITCH : bool * : preserve pitch when changing playback rateI_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=rightI_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameterI_CUSTOMCOLOR : int * : custom color, OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). If you do not |0x100000, then it will not be used, but will store the colorIP_TAKENUMBER : int : take number (read-only, returns the take number directly)P_TRACK : pointer to MediaTrack (read-only)P_ITEM : pointer to MediaItem (read-only)P_SOURCE : PCM_source *. Note that if setting this, you should first retrieve the old source, set the new, THEN delete the old.
FUNC209 MediaTrack reaper.GetMediaItemTrack(MediaItem item)
DESC209 
FUNC210 string filenamebuf = reaper.GetMediaSourceFileName(PCM_source source, string filenamebuf)
DESC210 Copies the media source filename to typebuf. Note that in-project MIDI media sources have no associated filename. See GetMediaSourceParent.
FUNC211 number retval, boolean lengthIsQN = reaper.GetMediaSourceLength(PCM_source source)
DESC211 Returns the length of the source media. If the media source is beat-based, the length will be in quarter notes, otherwise it will be in seconds.
FUNC212 integer reaper.GetMediaSourceNumChannels(PCM_source source)
DESC212 Returns the number of channels in the source media.
FUNC213 PCM_source reaper.GetMediaSourceParent(PCM_source src)
DESC213 Returns the parent source, or NULL if src is the root source. This can be used to retrieve the parent properties of sections or reversed sources for example.
FUNC214 integer reaper.GetMediaSourceSampleRate(PCM_source source)
DESC214 Returns the sample rate. MIDI source media will return zero.
FUNC215 string typebuf = reaper.GetMediaSourceType(PCM_source source, string typebuf)
DESC215 copies the media source type ("WAV", "MIDI", etc) to typebuf
FUNC216 number reaper.GetMediaTrackInfo_Value(MediaTrack tr, string parmname)
DESC216 Get track numerical-value attributes.B_MUTE : bool * : mutedB_PHASE : bool * : track phase invertedB_RECMON_IN_EFFECT : bool * : record monitoring in effect (current audio-thread playback state, read-only)IP_TRACKNUMBER : int : track number 1-based, 0=not found, -1=master track (read-only, returns the int directly)I_SOLO : int * : soloed, 0=not soloed, 1=soloed, 2=soloed in place, 5=safe soloed, 6=safe soloed in placeI_FXEN : int * : fx enabled, 0=bypassed, !0=fx activeI_RECARM : int * : record armed, 0=not record armed, 1=record armedI_RECINPUT : int * : record input, <0=no input. if 4096 set, input is MIDI and low 5 bits represent channel (0=all, 1-16=only chan), next 6 bits represent physical input (63=all, 62=VKB). If 4096 is not set, low 10 bits (0..1023) are input start channel (ReaRoute/Loopback start at 512). If 2048 is set, input is multichannel input (using track channel count), or if 1024 is set, input is stereo input, otherwise input is mono.I_RECMODE : int * : record mode, 0=input, 1=stereo out, 2=none, 3=stereo out w/latency compensation, 4=midi output, 5=mono out, 6=mono out w/ latency compensation, 7=midi overdub, 8=midi replaceI_RECMON : int * : record monitoring, 0=off, 1=normal, 2=not when playing (tape style)I_RECMONITEMS : int * : monitor items while recording, 0=off, 1=onI_AUTOMODE : int * : track automation mode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latchI_NCHAN : int * : number of track channels, 2-64, even numbers onlyI_SELECTED : int * : track selected, 0=unselected, 1=selectedI_WNDH : int * : current TCP window height in pixels including envelopes (read-only)I_TCPH : int * : current TCP window height in pixels not including envelopes (read-only)I_TCPY : int * : current TCP window Y-position in pixels relative to top of arrange view (read-only)I_MCPX : int * : current MCP X-position in pixels relative to mixer containerI_MCPY : int * : current MCP Y-position in pixels relative to mixer containerI_MCPW : int * : current MCP width in pixelsI_MCPH : int * : current MCP height in pixelsI_FOLDERDEPTH : int * : folder depth change, 0=normal, 1=track is a folder parent, -1=track is the last in the innermost folder, -2=track is the last in the innermost and next-innermost folders, etcI_FOLDERCOMPACT : int * : folder compacted state (only valid on folders), 0=normal, 1=small, 2=tiny childrenI_MIDIHWOUT : int * : track midi hardware output index, <0=disabled, low 5 bits are which channels (0=all, 1-16), next 5 bits are output device index (0-31)I_PERFFLAGS : int * : track performance flags, &1=no media buffering, &2=no anticipative FXI_CUSTOMCOLOR : int * : custom color, OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). If you do not |0x100000, then it will not be used, but will store the colorI_HEIGHTOVERRIDE : int * : custom height override for TCP window, 0 for none, otherwise size in pixelsB_HEIGHTLOCK : bool * : track height lock (must set I_HEIGHTOVERRIDE before locking)D_VOL : double * : trim volume of track, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etcD_PAN : double * : trim pan of track, -1..1D_WIDTH : double * : width of track, -1..1D_DUALPANL : double * : dualpan position 1, -1..1, only if I_PANMODE==6D_DUALPANR : double * : dualpan position 2, -1..1, only if I_PANMODE==6I_PANMODE : int * : pan mode, 0=classic 3.x, 3=new balance, 5=stereo pan, 6=dual panD_PANLAW : double * : pan law of track, <0=project default, 1=+0dB, etcP_ENV:<envchunkname or P_ENV:{GUID... : TrackEnvelope*, read only. chunkname can be <VOLENV, <PANENV, etc; GUID is the stringified envelope GUID.B_SHOWINMIXER : bool * : track control panel visible in mixer (do not use on master track)B_SHOWINTCP : bool * : track control panel visible in arrange view (do not use on master track)B_MAINSEND : bool * : track sends audio to parentC_MAINSEND_OFFS : char * : channel offset of track send to parentB_FREEMODE : bool * : track free item positioning enabled (call UpdateTimeline() after changing)C_BEATATTACHMODE : char * : track timebase, -1=project default, 0=time, 1=beats (position, length, rate), 2=beats (position


 only)F_MCP_FXSEND_SCALE : float * : scale of fx+send area in MCP (0=minimum allowed, 1=maximum allowed)F_MCP_FXPARM_SCALE : float * : scale of fx parameter area in MCP (0=minimum allowed, 1=maximum allowed)F_MCP_SENDRGN_SCALE : float * : scale of send area as proportion of the fx+send total area (0=minimum allowed, 1=maximum allowed)F_TCP_FXPARM_SCALE : float * : scale of TCP parameter area when TCP FX are embedded (0=min allowed, default, 1=max allowed)I_PLAY_OFFSET_FLAG : int * : track playback offset state, &1=bypassed, &2=offset value is measured in samples (otherwise measured in seconds)D_PLAY_OFFSET : double * : track playback offset, units depend on I_PLAY_OFFSET_FLAGP_PARTRACK : MediaTrack * : parent track (read-only)P_PROJECT : ReaProject * : parent project (read-only)
FUNC217 boolean retval, string nameout = reaper.GetMIDIInputName(integer dev, string nameout)
DESC217 returns true if device present
FUNC218 boolean retval, string nameout = reaper.GetMIDIOutputName(integer dev, string nameout)
DESC218 returns true if device present
FUNC219 MediaTrack reaper.GetMixerScroll()
DESC219 Get the leftmost track visible in the mixer
FUNC220 string action = reaper.GetMouseModifier(string context, integer modifier_flag, string action)
DESC220 Get the current mouse modifier assignment for a specific modifier key assignment, in a specific context.action will be filled in with the command ID number for a built-in mouse modifieror built-in REAPER command ID, or the custom action ID string.See SetMouseModifier for more information.
FUNC221 number x, number y = reaper.GetMousePosition()
DESC221 get mouse position in screen coordinates
FUNC222 integer reaper.GetNumAudioInputs()
DESC222 Return number of normal audio hardware inputs available
FUNC223 integer reaper.GetNumAudioOutputs()
DESC223 Return number of normal audio hardware outputs available
FUNC224 integer reaper.GetNumMIDIInputs()
DESC224 returns max number of real midi hardware inputs
FUNC225 integer reaper.GetNumMIDIOutputs()
DESC225 returns max number of real midi hardware outputs
FUNC226 integer reaper.GetNumTakeMarkers(MediaItem_Take take)
DESC226 Returns number of take markers. See GetTakeMarker, SetTakeMarker, DeleteTakeMarker
FUNC227 integer reaper.GetNumTracks()
DESC227 
FUNC228 string reaper.GetOS()
DESC228 Returns "Win32", "Win64", "OSX32", "OSX64", "macOS-arm64", or "Other".
FUNC229 string reaper.GetOutputChannelName(integer channelIndex)
DESC229 
FUNC230 number reaper.GetOutputLatency()
DESC230 returns output latency in seconds
FUNC231 MediaTrack reaper.GetParentTrack(MediaTrack track)
DESC231 
FUNC232 string buf = reaper.GetPeakFileName(string fn, string buf)
DESC232 get the peak file name for a given file (can be either filename.reapeaks,or a hashed filename in another path)
FUNC233 string buf = reaper.GetPeakFileNameEx(string fn, string buf, boolean forWrite)
DESC233 get the peak file name for a given file (can be either filename.reapeaks,or a hashed filename in another path)
FUNC234 string buf = reaper.GetPeakFileNameEx2(string fn, string buf, boolean forWrite, string peaksfileextension)
DESC234 Like GetPeakFileNameEx, but you can specify peaksfileextension such as ".reapeaks"
FUNC235 number reaper.GetPlayPosition()
DESC235 returns latency-compensated actual-what-you-hear position
FUNC236 number reaper.GetPlayPosition2()
DESC236 returns position of next audio block being processed
FUNC237 number reaper.GetPlayPosition2Ex(ReaProject proj)
DESC237 returns position of next audio block being processed
FUNC238 number reaper.GetPlayPositionEx(ReaProject proj)
DESC238 returns latency-compensated actual-what-you-hear position
FUNC239 integer reaper.GetPlayState()
DESC239 &1=playing,&2=pause,&=4 is recording
FUNC240 integer reaper.GetPlayStateEx(ReaProject proj)
DESC240 &1=playing,&2=pause,&=4 is recording
FUNC241 number reaper.GetProjectLength(ReaProject proj)
DESC241 returns length of project (maximum of end of media item, markers, end of regions, tempo map
FUNC242 string buf = reaper.GetProjectName(ReaProject proj, string buf)
DESC242 
FUNC243 string buf = reaper.GetProjectPath(string buf)
DESC243 Get the project recording path.
FUNC244 string buf = reaper.GetProjectPathEx(ReaProject proj, string buf)
DESC244 Get the project recording path.
FUNC245 integer reaper.GetProjectStateChangeCount(ReaProject proj)
DESC245 returns an integer that changes when the project state changes
FUNC246 number reaper.GetProjectTimeOffset(ReaProject proj, boolean rndframe)
DESC246 Gets project time offset in seconds (project settings - project start time). If rndframe is true, the offset is rounded to a multiple of the project frame size.
FUNC247 number bpm, number bpi = reaper.GetProjectTimeSignature()
DESC247 deprecated
FUNC248 number bpm, number bpi = reaper.GetProjectTimeSignature2(ReaProject proj)
DESC248 Gets basic time signature (beats per minute, numerator of time signature in bpi)this does not reflect tempo envelopes but is purely what is set in the project settings.
FUNC249 integer retval, string val = reaper.GetProjExtState(ReaProject proj, string extname, string key)
DESC249 Get the value previously associated with this extname and key, the last time the project was saved. See SetProjExtState, EnumProjExtState.
FUNC250 string reaper.GetResourcePath()
DESC250 returns path where ini files are stored, other things are in subdirectories.
FUNC251 TrackEnvelope reaper.GetSelectedEnvelope(ReaProject proj)
DESC251 get the currently selected envelope, returns NULL/nil if no envelope is selected
FUNC252 MediaItem reaper.GetSelectedMediaItem(ReaProject proj, integer selitem)
DESC252 get a selected item by selected item count (zero-based) (proj=0 for active project)
FUNC253 MediaTrack reaper.GetSelectedTrack(ReaProject proj, integer seltrackidx)
DESC253 Get a selected track from a project (proj=0 for active project) by selected track count (zero-based). This function ignores the master track, see GetSelectedTrack2.
FUNC254 MediaTrack reaper.GetSelectedTrack2(ReaProject proj, integer seltrackidx, boolean wantmaster)
DESC254 Get a selected track from a project (proj=0 for active project) by selected track count (zero-based).
FUNC255 TrackEnvelope reaper.GetSelectedTrackEnvelope(ReaProject proj)
DESC255 get the currently selected track envelope, returns NULL/nil if no envelope is selected
FUNC256 number start_time, number end_time = reaper.GetSet_ArrangeView2(ReaProject proj, boolean isSet, integer screen_x_start, integer screen_x_end)
DESC256 Gets or sets the arrange view start/end time for screen coordinates. use screen_x_start=screen_x_end=0 to use the full arrange view's start/end time
FUNC257 number start, number end = reaper.GetSet_LoopTimeRange(boolean isSet, boolean isLoop, number start, number end, boolean allowautoseek)
DESC257 
FUNC258 number start, number end = reaper.GetSet_LoopTimeRange2(ReaProject proj, boolean isSet, boolean isLoop, number start, number end, boolean allowautoseek)
DESC258 
FUNC259 number reaper.GetSetAutomationItemInfo(TrackEnvelope env, integer autoitem_idx, string desc, number value, boolean is_set)
DESC259 Get or set automation item information. autoitem_idx=0 for the first automation item on an envelope, 1 for the second item, etc. desc can be any of the following:D_POOL_ID : double * : automation item pool ID (as an integer); edits are propagated to all other automation items that share a pool IDD_POSITION : double * : automation item timeline position in secondsD_LENGTH : double * : automation item length in secondsD_STARTOFFS : double * : automation item start offset in secondsD_PLAYRATE : double * : automation item playback rateD_BASELINE : double * : automation item baseline value in the range [0,1]D_AMPLITUDE : double * : automation item amplitude in the range [-1,1]D_LOOPSRC : double * : nonzero if the automation item contents are loopedD_UISEL : double * : nonzero if the automation item is selected in the arrange viewD_POOL_QNLEN : double * : automation item pooled source length in quarter notes (setting will affect all pooled instances)
FUNC260 boolean retval, string valuestrNeedBig = reaper.GetSetAutomationItemInfo_String(TrackEnvelope env, integer autoitem_idx, string desc, string valuestrNeedBig, boolean is_set)
DESC260 Get or set automation item information. autoitem_idx=0 for the first automation item on an envelope, 1 for the second item, etc. returns true on success. desc can be any of the following:P_POOL_NAME : char *, name of the underlying automation item poolP_POOL_EXT:xyz : char *, extension-specific persistent data
FUNC261 boolean retval, string stringNeedBig = reaper.GetSetEnvelopeInfo_String(TrackEnvelope env, string parmname, string stringNeedBig, boolean setNewValue)
DESC261 Gets/sets an attribute string:P_EXT:xyz : char * : extension-specific persistent dataGUID : GUID * : 16-byte GUID, can query only, not set. If using a _String() function, GUID is a string {xyz-...}.
FUNC262 boolean retval, string str = reaper.GetSetEnvelopeState(TrackEnvelope env, string str)
DESC262 deprecated -- see SetEnvelopeStateChunk, GetEnvelopeStateChunk
FUNC263 boolean retval, string str = reaper.GetSetEnvelopeState2(TrackEnvelope env, string str, boolean isundo)
DESC263 deprecated -- see SetEnvelopeStateChunk, GetEnvelopeStateChunk
FUNC264 boolean retval, string str = reaper.GetSetItemState(MediaItem item, string str)
DESC264 deprecated -- see SetItemStateChunk, GetItemStateChunk
FUNC265 boolean retval, string str = reaper.GetSetItemState2(MediaItem item, string str, boolean isundo)
DESC265 deprecated -- see SetItemStateChunk, GetItemStateChunk
FUNC266 boolean retval, string stringNeedBig = reaper.GetSetMediaItemInfo_String(MediaItem item, string parmname, string stringNeedBig, boolean setNewValue)
DESC266 Gets/sets an item attribute string:P_NOTES : char * : item note text (do not write to returned pointer, use setNewValue to update)P_EXT:xyz : char * : extension-specific persistent dataGUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.
FUNC267 boolean retval, string stringNeedBig = reaper.GetSetMediaItemTakeInfo_String(MediaItem_Take tk, string parmname, string stringNeedBig, boolean setNewValue)
DESC267 Gets/sets a take attribute string:P_NAME : char * : take nameP_EXT:xyz : char * : extension-specific persistent dataGUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.
FUNC268 boolean retval, string stringNeedBig = reaper.GetSetMediaTrackInfo_String(MediaTrack tr, string parmname, string stringNeedBig, boolean setNewValue)
DESC268 Get or set track string attributes.P_NAME : char * : track name (on master returns NULL)P_ICON : const char * : track icon (full filename, or relative to resource_path/data/track_icons)P_MCP_LAYOUT : const char * : layout nameP_RAZOREDITS : const char * : list of razor edit areas, as space-separated triples of start time, end time, and envelope GUID string.Example: "0.00 1.00 \"\" 0.00 1.00 "{xyz-...}"P_TCP_LAYOUT : const char * : layout nameP_EXT:xyz : char * : extension-specific persistent dataGUID : GUID * : 16-byte GUID, can query or update. If using a _String() function, GUID is a string {xyz-...}.
FUNC269 string author = reaper.GetSetProjectAuthor(ReaProject proj, boolean set, string author)
DESC269 gets or sets project author, author_sz is ignored when setting
FUNC270 integer retval, optional number division, optional number swingmode, optional number swingamt = reaper.GetSetProjectGrid(ReaProject project, boolean set, optional number division, optional number swingmode, optional number swingamt)
DESC270 Get or set the arrange view grid division. 0.25=quarter note, 1.0/3.0=half note triplet, etc. swingmode can be 1 for swing enabled, swingamt is -1..1. swingmode can be 3 for measure-grid. Returns grid configuration flags
FUNC271 number reaper.GetSetProjectInfo(ReaProject project, string desc, number value, boolean is_set)
DESC271 Get or set project information.RENDER_SETTINGS : &(1|2)=0:master mix, &1=stems+master mix, &2=stems only, &4=multichannel tracks to multichannel files, &8=use render matrix, &16=tracks with only mono media to mono files, &32=selected media items, &64=selected media items via master, &128=selected tracks via master, &256=embed transients if format supports, &512=embed metadata if format supports, &1024=embed take markers if format supports, &2048=2nd pass renderRENDER_BOUNDSFLAG : 0=custom time bounds, 1=entire project, 2=time selection, 3=all project regions, 4=selected media items, 5=selected project regionsRENDER_CHANNELS : number of channels in rendered fileRENDER_SRATE : sample rate of rendered file (or 0 for project sample rate)RENDER_STARTPOS : render start time when RENDER_BOUNDSFLAG=0RENDER_ENDPOS : render end time when RENDER_BOUNDSFLAG=0RENDER_TAILFLAG : apply render tail setting when rendering: &1=custom time bounds, &2=entire project, &4=time selection, &8=all project regions, &16=selected media items, &32=selected project regionsRENDER_TAILMS : tail length in ms to render (only used if RENDER_BOUNDSFLAG and RENDER_TAILFLAG are set)RENDER_ADDTOPROJ : &1=add rendered files to project, &2=do not render files that are likely silentRENDER_DITHER : &1=dither, &2=noise shaping, &4=dither stems, &8=noise shaping on stemsPROJECT_SRATE : samplerate (ignored unless PROJECT_SRATE_USE set)PROJECT_SRATE_USE : set to 1 if project samplerate is used
FUNC272 boolean retval, string valuestrNeedBig = reaper.GetSetProjectInfo_String(ReaProject project, string desc, string valuestrNeedBig, boolean is_set)
DESC272 Get or set project information.TRACK_GROUP_NAME:X : track group name, X should be 1..64MARKER_GUID:X : get the GUID (unique ID) of the marker or region with index X, where X is the index passed to EnumProjectMarkers, not necessarily the displayed numberRECORD_PATH : recording directory -- may be blank or a relative path, to get the effective path see GetProjectPathEx()RENDER_FILE : render directoryRENDER_PATTERN : render file name (may contain wildcards)RENDER_METADATA : get or set the metadata saved with the project (not metadata embedded in project media). Example, ID3 album name metadata: "ID3:TALB" to get, "ID3:TALB|my album name" to set.RENDER_TARGETS : semicolon separated list of files that would be written if the project is rendered using the most recent render settingsRENDER_FORMAT : base64-encoded sink configuration (see project files, etc). Callers can also pass a simple 4-byte string (non-base64-encoded), e.g. "evaw" or "l3pm", to use default settings for that sink type.RENDER_FORMAT2 : base64-encoded secondary sink configuration. Callers can also pass a simple 4-byte string (non-base64-encoded), e.g. "evaw" or "l3pm", to use default settings for that sink type, or "" to disable secondary render.    Formats available on this machine:    "wave" "aiff" "iso " "ddp " "flac" "mp3l" "oggv" "OggS" "FFMP" "GIF " "LCF " "wvpk"
FUNC273 string notes = reaper.GetSetProjectNotes(ReaProject proj, boolean set, string notes)
DESC273 gets or sets project notes, notesNeedBig_sz is ignored when setting
FUNC274 integer reaper.GetSetRepeat(integer val)
DESC274 -1 == query,0=clear,1=set,>1=toggle . returns new value
FUNC275 integer reaper.GetSetRepeatEx(ReaProject proj, integer val)
DESC275 -1 == query,0=clear,1=set,>1=toggle . returns new value
FUNC276 integer reaper.GetSetTrackGroupMembership(MediaTrack tr, string groupname, integer setmask, integer setvalue)
DESC276 Gets or modifies the group membership for a track. Returns group state prior to call (each bit represents one of the 32 group numbers). if setmask has bits set, those bits in setvalue will be applied to group. Group can be one of:VOLUME_LEADVOLUME_FOLLOWVOLUME_VCA_LEADVOLUME_VCA_FOLLOWPAN_LEADPAN_FOLLOWWIDTH_LEADWIDTH_FOLLOWMUTE_LEADMUTE_FOLLOWSOLO_LEADSOLO_FOLLOWRECARM_LEADRECARM_FOLLOWPOLARITY_LEADPOLARITY_FOLLOWAUTOMODE_LEADAUTOMODE_FOLLOWVOLUME_REVERSEPAN_REVERSEWIDTH_REVERSENO_LEAD_WHEN_FOLLOWVOLUME_VCA_FOLLOW_ISPREFXNote: REAPER v6.11 and earlier used _MASTER and _SLAVE rather than _LEAD and _FOLLOW, which is deprecated but still supported (scripts that must support v6.11 and earlier can use the deprecated strings).
FUNC277 integer reaper.GetSetTrackGroupMembershipHigh(MediaTrack tr, string groupname, integer setmask, integer setvalue)
DESC277 Gets or modifies the group membership for a track. Returns group state prior to call (each bit represents one of the high 32 group numbers). if setmask has bits set, those bits in setvalue will be applied to group. Group can be one of:VOLUME_LEADVOLUME_FOLLOWVOLUME_VCA_LEADVOLUME_VCA_FOLLOWPAN_LEADPAN_FOLLOWWIDTH_LEADWIDTH_FOLLOWMUTE_LEADMUTE_FOLLOWSOLO_LEADSOLO_FOLLOWRECARM_LEADRECARM_FOLLOWPOLARITY_LEADPOLARITY_FOLLOWAUTOMODE_LEADAUTOMODE_FOLLOWVOLUME_REVERSEPAN_REVERSEWIDTH_REVERSENO_LEAD_WHEN_FOLLOWVOLUME_VCA_FOLLOW_ISPREFXNote: REAPER v6.11 and earlier used _MASTER and _SLAVE rather than _LEAD and _FOLLOW, which is deprecated but still supported (scripts that must support v6.11 and earlier can use the deprecated strings).
FUNC278 boolean retval, string stringNeedBig = reaper.GetSetTrackSendInfo_String(MediaTrack tr, integer category, integer sendidx, string parmname, string stringNeedBig, boolean setNewValue)
DESC278 Gets/sets a send attribute string:P_EXT:xyz : char * : extension-specific persistent data
FUNC279 boolean retval, string str = reaper.GetSetTrackState(MediaTrack track, string str)
DESC279 deprecated -- see SetTrackStateChunk, GetTrackStateChunk
FUNC280 boolean retval, string str = reaper.GetSetTrackState2(MediaTrack track, string str, boolean isundo)
DESC280 deprecated -- see SetTrackStateChunk, GetTrackStateChunk
FUNC281 ReaProject reaper.GetSubProjectFromSource(PCM_source src)
DESC281 
FUNC282 MediaItem_Take reaper.GetTake(MediaItem item, integer takeidx)
DESC282 get a take from an item by take count (zero-based)
FUNC283 TrackEnvelope reaper.GetTakeEnvelope(MediaItem_Take take, integer envidx)
DESC283 
FUNC284 TrackEnvelope reaper.GetTakeEnvelopeByName(MediaItem_Take take, string envname)
DESC284 
FUNC285 number retval, string name, optional number color = reaper.GetTakeMarker(MediaItem_Take take, integer idx)
DESC285 Get information about a take marker. Returns the position in media item source time, or -1 if the take marker does not exist. See GetNumTakeMarkers, SetTakeMarker, DeleteTakeMarker
FUNC286 string reaper.GetTakeName(MediaItem_Take take)
DESC286 returns NULL if the take is not valid
FUNC287 integer reaper.GetTakeNumStretchMarkers(MediaItem_Take take)
DESC287 Returns number of stretch markers in take
FUNC288 integer retval, number pos, optional number srcpos = reaper.GetTakeStretchMarker(MediaItem_Take take, integer idx)
DESC288 Gets information on a stretch marker, idx is 0..n. Returns false if stretch marker not valid. posOut will be set to position in item, srcposOutOptional will be set to source media position. Returns index. if input index is -1, next marker is found using position (or source position if position is -1). If position/source position are used to find marker position, their values are not updated.
FUNC289 number reaper.GetTakeStretchMarkerSlope(MediaItem_Take take, integer idx)
DESC289 See SetTakeStretchMarkerSlope
FUNC290 boolean retval, number fxindex, number parmidx = reaper.GetTCPFXParm(ReaProject project, MediaTrack track, integer index)
DESC290 Get information about a specific FX parameter knob (see CountTCPFXParms).
FUNC291 boolean retval, number rate, number targetlen = reaper.GetTempoMatchPlayRate(PCM_source source, number srcscale, number position, number mult)
DESC291 finds the playrate and target length to insert this item stretched to a round power-of-2 number of bars, between 1/8 and 256
FUNC292 boolean retval, number timepos, number measurepos, number beatpos, number bpm, number timesig_num, number timesig_denom, boolean lineartempo = reaper.GetTempoTimeSigMarker(ReaProject proj, integer ptidx)
DESC292 Get information about a tempo/time signature marker. See CountTempoTimeSigMarkers, SetTempoTimeSigMarker, AddTempoTimeSigMarker.
FUNC293 integer reaper.GetThemeColor(string ini_key, integer flags)
DESC293 Returns the theme color specified, or -1 on failure. If the low bit of flags is set, the color as originally specified by the theme (before any transformations) is returned, otherwise the current (possibly transformed and modified) color is returned. See SetThemeColor for a list of valid ini_key.
FUNC294 integer reaper.GetToggleCommandState(integer command_id)
DESC294 See GetToggleCommandStateEx.
FUNC295 integer reaper.GetToggleCommandStateEx(integer section_id, integer command_id)
DESC295 For the main action context, the MIDI editor, or the media explorer, returns the toggle state of the action. 0=off, 1=on, -1=NA because the action does not have on/off states. For the MIDI editor, the action state for the most recently focused window will be returned.
FUNC296 HWND reaper.GetTooltipWindow()
DESC296 gets a tooltip window,in case you want to ask it for font information. Can return NULL.
FUNC297 MediaTrack reaper.GetTrack(ReaProject proj, integer trackidx)
DESC297 get a track from a project by track count (zero-based) (proj=0 for active project)
FUNC298 integer reaper.GetTrackAutomationMode(MediaTrack tr)
DESC298 return the track mode, regardless of global override
FUNC299 integer reaper.GetTrackColor(MediaTrack track)
DESC299 Returns the track custom color as OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). Black is returned as 0x01000000, no color setting is returned as 0.
FUNC300 integer reaper.GetTrackDepth(MediaTrack track)
DESC300 
FUNC301 TrackEnvelope reaper.GetTrackEnvelope(MediaTrack track, integer envidx)
DESC301 
FUNC302 TrackEnvelope reaper.GetTrackEnvelopeByChunkName(MediaTrack tr, string cfgchunkname_or_guid)
DESC302 Gets a built-in track envelope by configuration chunk name, like "<VOLENV", or GUID string, like "{B577250D-146F-B544-9B34-F24FBE488F1F}".
FUNC303 TrackEnvelope reaper.GetTrackEnvelopeByName(MediaTrack track, string envname)
DESC303 
FUNC304 MediaTrack retval, optional number info = reaper.GetTrackFromPoint(integer screen_x, integer screen_y)
DESC304 Returns the track from the screen coordinates specified. If the screen coordinates refer to a window associated to the track (such as FX), the track will be returned. infoOutOptional will be set to 1 if it is likely an envelope, 2 if it is likely a track FX.
FUNC305 string GUID = reaper.GetTrackGUID(MediaTrack tr)
DESC305 
FUNC306 MediaItem reaper.GetTrackMediaItem(MediaTrack tr, integer itemidx)
DESC306 
FUNC307 boolean retval, string bufWant = reaper.GetTrackMIDILyrics(MediaTrack track, integer flag, string bufWant)
DESC307 Get all MIDI lyrics on the track. Lyrics will be returned as one string with tabs between each word. flag&1: double tabs at the end of each measure and triple tabs when skipping measures, flag&2: each lyric is preceded by its beat position in the project (example with flag=2: "1.1.2\tLyric for measure 1 beat 2\t.1.1\tLyric for measure 2 beat 1 "). See SetTrackMIDILyrics
FUNC308 string reaper.GetTrackMIDINoteName(integer track, integer pitch, integer chan)
DESC308 see GetTrackMIDINoteNameEx
FUNC309 string reaper.GetTrackMIDINoteNameEx(ReaProject proj, MediaTrack track, integer pitch, integer chan)
DESC309 Get note/CC name. pitch 128 for CC0 name, 129 for CC1 name, etc. See SetTrackMIDINoteNameEx
FUNC310 number note_lo, number note_hi = reaper.GetTrackMIDINoteRange(ReaProject proj, MediaTrack track)
DESC310 
FUNC311 boolean retval, string buf = reaper.GetTrackName(MediaTrack track)
DESC311 Returns "MASTER" for master track, "Track N" if track has no name.
FUNC312 integer reaper.GetTrackNumMediaItems(MediaTrack tr)
DESC312 
FUNC313 integer reaper.GetTrackNumSends(MediaTrack tr, integer category)
DESC313 returns number of sends/receives/hardware outputs - category is <0 for receives, 0=sends, >0 for hardware outputs
FUNC314 boolean retval, string buf = reaper.GetTrackReceiveName(MediaTrack track, integer recv_index, string buf)
DESC314 See GetTrackSendName.
FUNC315 boolean retval, boolean mute = reaper.GetTrackReceiveUIMute(MediaTrack track, integer recv_index)
DESC315 See GetTrackSendUIMute.
FUNC316 boolean retval, number volume, number pan = reaper.GetTrackReceiveUIVolPan(MediaTrack track, integer recv_index)
DESC316 See GetTrackSendUIVolPan.
FUNC317 number reaper.GetTrackSendInfo_Value(MediaTrack tr, integer category, integer sendidx, string parmname)
DESC317 Get send/receive/hardware output numerical-value attributes.category is <0 for receives, 0=sends, >0 for hardware outputsparameter names:B_MUTE : bool *B_PHASE : bool *, true to flip phaseB_MONO : bool *D_VOL : double *, 1.0 = +0dB etcD_PAN : double *, -1..+1D_PANLAW : double *,1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etcI_SENDMODE : int *, 0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fxI_AUTOMODE : int * : automation mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)I_SRCCHAN : int *, index,&1024=mono, -1 for noneI_DSTCHAN : int *, index, &1024=mono, otherwise stereo pair, hwout:&512=rearouteI_MIDIFLAGS : int *, low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanP_DESTTRACK : read only, returns MediaTrack *, destination track, only applies for sends/recvsP_SRCTRACK : read only, returns MediaTrack *, source track, only applies for sends/recvsP_ENV:<envchunkname : read only, returns TrackEnvelope *. Call with :<VOLENV, :<PANENV, etc appended.See CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
FUNC318 boolean retval, string buf = reaper.GetTrackSendName(MediaTrack track, integer send_index, string buf)
DESC318 send_idx>=0 for hw ouputs, >=nb_of_hw_ouputs for sends. See GetTrackReceiveName.
FUNC319 boolean retval, boolean mute = reaper.GetTrackSendUIMute(MediaTrack track, integer send_index)
DESC319 send_idx>=0 for hw ouputs, >=nb_of_hw_ouputs for sends. See GetTrackReceiveUIMute.
FUNC320 boolean retval, number volume, number pan = reaper.GetTrackSendUIVolPan(MediaTrack track, integer send_index)
DESC320 send_idx>=0 for hw ouputs, >=nb_of_hw_ouputs for sends. See GetTrackReceiveUIVolPan.
FUNC321 string retval, number flags = reaper.GetTrackState(MediaTrack track)
DESC321 Gets track state, returns track name.flags will be set to:&1=folder&2=selected&4=has fx enabled&8=muted&16=soloed&32=SIP'd (with &16)&64=rec armed&128=rec monitoring on&256=rec monitoring auto&512=hide from TCP&1024=hide from MCP
FUNC322 boolean retval, string str = reaper.GetTrackStateChunk(MediaTrack track, string str, boolean isundo)
DESC322 Gets the RPPXML state of a track, returns true if successful. Undo flag is a performance/caching hint.
FUNC323 boolean retval, boolean mute = reaper.GetTrackUIMute(MediaTrack track)
DESC323 
FUNC324 boolean retval, number pan1, number pan2, number panmode = reaper.GetTrackUIPan(MediaTrack track)
DESC324 
FUNC325 boolean retval, number volume, number pan = reaper.GetTrackUIVolPan(MediaTrack track)
DESC325 
FUNC326 optional number audio_xrun, optional number media_xrun, optional number curtime = reaper.GetUnderrunTime()
DESC326 retrieves the last timestamps of audio xrun (yellow-flash, if available), media xrun (red-flash), and the current time stamp (all milliseconds)
FUNC327 boolean retval, string filenameNeed4096 = reaper.GetUserFileNameForRead(string filenameNeed4096, string title, string defext)
DESC327 returns true if the user selected a valid file, false if the user canceled the dialog
FUNC328 boolean retval, string retvals_csv = reaper.GetUserInputs(string title, integer num_inputs, string captions_csv, string retvals_csv)
DESC328 Get values from the user.If a caption begins with *, for example "*password", the edit field will not display the input text.Maximum fields is 16. Values are returned as a comma-separated string. Returns false if the user canceled the dialog. You can supply special extra information via additional caption fields: extrawidth=XXX to increase text field width, separator=X to use a different separator for returned fields.
FUNC329 reaper.GoToMarker(ReaProject proj, integer marker_index, boolean use_timeline_order)
DESC329 Go to marker. If use_timeline_order==true, marker_index 1 refers to the first marker on the timeline. If use_timeline_order==false, marker_index 1 refers to the first marker with the user-editable index of 1.
FUNC330 reaper.GoToRegion(ReaProject proj, integer region_index, boolean use_timeline_order)
DESC330 Seek to region after current region finishes playing (smooth seek). If use_timeline_order==true, region_index 1 refers to the first region on the timeline. If use_timeline_order==false, region_index 1 refers to the first region with the user-editable index of 1.
FUNC331 integer retval, number color = reaper.GR_SelectColor(HWND hwnd)
DESC331 Runs the system color chooser dialog. Returns 0 if the user cancels the dialog.
FUNC332 integer reaper.GSC_mainwnd(integer t)
DESC332 this is just like win32 GetSysColor() but can have overrides.
FUNC333 string destNeed64 = reaper.guidToString(string gGUID, string destNeed64)
DESC333 dest should be at least 64 chars long to be safe
FUNC334 boolean reaper.HasExtState(string section, string key)
DESC334 Returns true if there exists an extended state value for a specific section and key. See SetExtState, GetExtState, DeleteExtState.
FUNC335 string reaper.HasTrackMIDIPrograms(integer track)
DESC335 returns name of track plugin that is supplying MIDI programs,or NULL if there is none
FUNC336 string reaper.HasTrackMIDIProgramsEx(ReaProject proj, MediaTrack track)
DESC336 returns name of track plugin that is supplying MIDI programs,or NULL if there is none
FUNC337 reaper.Help_Set(string helpstring, boolean is_temporary_help)
DESC337 
FUNC338 string out = reaper.image_resolve_fn(string in, string out)
DESC338 
FUNC339 integer reaper.InsertAutomationItem(TrackEnvelope env, integer pool_id, number position, number length)
DESC339 Insert a new automation item. pool_id < 0 collects existing envelope points into the automation item; if pool_id is >= 0 the automation item will be a new instance of that pool (which will be created as an empty instance if it does not exist). Returns the index of the item, suitable for passing to other automation item API functions. See GetSetAutomationItemInfo.
FUNC340 boolean reaper.InsertEnvelopePoint(TrackEnvelope envelope, number time, number value, integer shape, number tension, boolean selected, optional boolean noSortIn)
DESC340 Insert an envelope point. If setting multiple points at once, set noSort=true, and call Envelope_SortPoints when done. See InsertEnvelopePointEx.
FUNC341 boolean reaper.InsertEnvelopePointEx(TrackEnvelope envelope, integer autoitem_idx, number time, number value, integer shape, number tension, boolean selected, optional boolean noSortIn)
DESC341 Insert an envelope point. If setting multiple points at once, set noSort=true, and call Envelope_SortPoints when done.autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc.For automation items, pass autoitem_idx|0x10000000 to base ptidx on the number of points in one full loop iteration,even if the automation item is trimmed so that not all points are visible.Otherwise, ptidx will be based on the number of visible points in the automation item, including all loop iterations.See CountEnvelopePointsEx, GetEnvelopePointEx, SetEnvelopePointEx, DeleteEnvelopePointEx.
FUNC342 integer reaper.InsertMedia(string file, integer mode)
DESC342 mode: 0=add to current track, 1=add new track, 3=add to selected items as takes, &4=stretch/loop to fit time sel, &8=try to match tempo 1x, &16=try to match tempo 0.5x, &32=try to match tempo 2x, &64=don't preserve pitch when matching tempo, &128=no loop/section if startpct/endpct set, &256=force loop regardless of global preference for looping imported items, &512=use high word as absolute track index if mode&3==0, &1024=insert into reasamplomatic on a new track, &2048=insert into open reasamplomatic instance, &4096=move to source preferred position (BWF start offset), &8192=reverse
FUNC343 integer reaper.InsertMediaSection(string file, integer mode, number startpct, number endpct, number pitchshift)
DESC343 See InsertMedia.
FUNC344 reaper.InsertTrackAtIndex(integer idx, boolean wantDefaults)
DESC344 inserts a track at idx,of course this will be clamped to 0..GetNumTracks(). wantDefaults=TRUE for default envelopes/FX,otherwise no enabled fx/env
FUNC345 boolean reaper.IsMediaExtension(string ext, boolean wantOthers)
DESC345 Tests a file extension (i.e. "wav" or "mid") to see if it's a media extension.If wantOthers is set, then "RPP", "TXT" and other project-type formats will also pass.
FUNC346 boolean reaper.IsMediaItemSelected(MediaItem item)
DESC346 
FUNC347 integer reaper.IsProjectDirty(ReaProject proj)
DESC347 Is the project dirty (needing save)? Always returns 0 if 'undo/prompt to save' is disabled in preferences.
FUNC348 boolean reaper.IsTrackSelected(MediaTrack track)
DESC348 
FUNC349 boolean reaper.IsTrackVisible(MediaTrack track, boolean mixer)
DESC349 If mixer==true, returns true if the track is visible in the mixer. If mixer==false, returns true if the track is visible in the track control panel.
FUNC350 joystick_device reaper.joystick_create(string guidGUID)
DESC350 creates a joystick device
FUNC351 reaper.joystick_destroy(joystick_device device)
DESC351 destroys a joystick device
FUNC352 string retval, optional string namestr = reaper.joystick_enum(integer index)
DESC352 enumerates installed devices, returns GUID as a string
FUNC353 number reaper.joystick_getaxis(joystick_device dev, integer axis)
DESC353 returns axis value (-1..1)
FUNC354 integer reaper.joystick_getbuttonmask(joystick_device dev)
DESC354 returns button pressed mask, 1=first button, 2=second...
FUNC355 integer retval, optional number axes, optional number povs = reaper.joystick_getinfo(joystick_device dev)
DESC355 returns button count
FUNC356 number reaper.joystick_getpov(joystick_device dev, integer pov)
DESC356 returns POV value (usually 0..655.35, or 655.35 on error)
FUNC357 boolean reaper.joystick_update(joystick_device dev)
DESC357 Updates joystick state from hardware, returns true if successful (joystick_get* will not be valid until joystick_update() is called successfully)
FUNC358 boolean retval, number pX1, number pY1, number pX2, number pY2 = reaper.LICE_ClipLine(number pX1, number pY1, number pX2, number pY2, integer xLo, integer yLo, integer xHi, integer yHi)
DESC358 Returns false if the line is entirely offscreen.
FUNC359 string reaper.LocalizeString(string src_string, string section, integer flags)
DESC359 Returns a localized version of src_string, in section section. flags can have 1 set to only localize if sprintf-style formatting matches the original.
FUNC360 boolean reaper.Loop_OnArrow(ReaProject project, integer direction)
DESC360 Move the loop selection left or right. Returns true if snap is enabled.
FUNC361 reaper.Main_OnCommand(integer command, integer flag)
DESC361 See Main_OnCommandEx.
FUNC362 reaper.Main_OnCommandEx(integer command, integer flag, ReaProject proj)
DESC362 Performs an action belonging to the main action section. To perform non-native actions (ReaScripts, custom or extension plugins' actions) safely, see NamedCommandLookup().
FUNC363 reaper.Main_openProject(string name)
DESC363 opens a project. will prompt the user to save unless name is prefixed with 'noprompt:'. If name is prefixed with 'template:', project file will be loaded as a template.If passed a .RTrackTemplate file, adds the template to the existing project.
FUNC364 reaper.Main_SaveProject(ReaProject proj, boolean forceSaveAsIn)
DESC364 Save the project.
FUNC365 reaper.Main_UpdateLoopInfo(integer ignoremask)
DESC365 
FUNC366 reaper.MarkProjectDirty(ReaProject proj)
DESC366 Marks project as dirty (needing save) if 'undo/prompt to save' is enabled in preferences.
FUNC367 reaper.MarkTrackItemsDirty(MediaTrack track, MediaItem item)
DESC367 If track is supplied, item is ignored
FUNC368 number reaper.Master_GetPlayRate(ReaProject project)
DESC368 
FUNC369 number reaper.Master_GetPlayRateAtTime(number time_s, ReaProject proj)
DESC369 
FUNC370 number reaper.Master_GetTempo()
DESC370 
FUNC371 number reaper.Master_NormalizePlayRate(number playrate, boolean isnormalized)
DESC371 Convert play rate to/from a value between 0 and 1, representing the position on the project playrate slider.
FUNC372 number reaper.Master_NormalizeTempo(number bpm, boolean isnormalized)
DESC372 Convert the tempo to/from a value between 0 and 1, representing bpm in the range of 40-296 bpm.
FUNC373 integer reaper.MB(string msg, string title, integer type)
DESC373 type 0=OK,1=OKCANCEL,2=ABORTRETRYIGNORE,3=YESNOCANCEL,4=YESNO,5=RETRYCANCEL : ret 1=OK,2=CANCEL,3=ABORT,4=RETRY,5=IGNORE,6=YES,7=NO
FUNC374 integer reaper.MediaItemDescendsFromTrack(MediaItem item, MediaTrack track)
DESC374 Returns 1 if the track holds the item, 2 if the track is a folder containing the track that holds the item, etc.
FUNC375 integer retval, number notecnt, number ccevtcnt, number textsyxevtcnt = reaper.MIDI_CountEvts(MediaItem_Take take)
DESC375 Count the number of notes, CC events, and text/sysex events in a given MIDI item.
FUNC376 boolean reaper.MIDI_DeleteCC(MediaItem_Take take, integer ccidx)
DESC376 Delete a MIDI CC event.
FUNC377 boolean reaper.MIDI_DeleteEvt(MediaItem_Take take, integer evtidx)
DESC377 Delete a MIDI event.
FUNC378 boolean reaper.MIDI_DeleteNote(MediaItem_Take take, integer noteidx)
DESC378 Delete a MIDI note.
FUNC379 boolean reaper.MIDI_DeleteTextSysexEvt(MediaItem_Take take, integer textsyxevtidx)
DESC379 Delete a MIDI text or sysex event.
FUNC380 reaper.MIDI_DisableSort(MediaItem_Take take)
DESC380 Disable sorting for all MIDI insert, delete, get and set functions, until MIDI_Sort is called.
FUNC381 integer reaper.MIDI_EnumSelCC(MediaItem_Take take, integer ccidx)
DESC381 Returns the index of the next selected MIDI CC event after ccidx (-1 if there are no more selected events).
FUNC382 integer reaper.MIDI_EnumSelEvts(MediaItem_Take take, integer evtidx)
DESC382 Returns the index of the next selected MIDI event after evtidx (-1 if there are no more selected events).
FUNC383 integer reaper.MIDI_EnumSelNotes(MediaItem_Take take, integer noteidx)
DESC383 Returns the index of the next selected MIDI note after noteidx (-1 if there are no more selected events).
FUNC384 integer reaper.MIDI_EnumSelTextSysexEvts(MediaItem_Take take, integer textsyxidx)
DESC384 Returns the index of the next selected MIDI text/sysex event after textsyxidx (-1 if there are no more selected events).
FUNC385 boolean retval, string buf = reaper.MIDI_GetAllEvts(MediaItem_Take take, string buf)
DESC385 Get all MIDI data. MIDI buffer is returned as a list of { int offset, char flag, int msglen, unsigned char msg[] }.offset: MIDI ticks from previous eventflag: &1=selected &2=mutedflag high 4 bits for CC shape: &16=linear, &32=slow start/end, &16|32=fast start, &64=fast end, &64|16=beziermsg: the MIDI message.A meta-event of type 0xF followed by 'CCBZ ' and 5 more bytes represents bezier curve data for the previous MIDI event: 1 byte for the bezier type (usually 0) and 4 bytes for the bezier tension as a float.For tick intervals longer than a 32 bit word can represent, zero-length meta events may be placed between valid events.See MIDI_SetAllEvts.
FUNC386 boolean retval, boolean selected, boolean muted, number ppqpos, number chanmsg, number chan, number msg2, number msg3 = reaper.MIDI_GetCC(MediaItem_Take take, integer ccidx)
DESC386 Get MIDI CC event properties.
FUNC387 boolean retval, number shape, number beztension = reaper.MIDI_GetCCShape(MediaItem_Take take, integer ccidx)
DESC387 Get CC shape and bezier tension. See MIDI_GetCC, MIDI_SetCCShape
FUNC388 boolean retval, boolean selected, boolean muted, number ppqpos, string msg = reaper.MIDI_GetEvt(MediaItem_Take take, integer evtidx, boolean selected, boolean muted, number ppqpos, string msg)
DESC388 Get MIDI event properties.
FUNC389 number retval, optional number swing, optional number noteLen = reaper.MIDI_GetGrid(MediaItem_Take take)
DESC389 Returns the most recent MIDI editor grid size for this MIDI take, in QN. Swing is between 0 and 1. Note length is 0 if it follows the grid size.
FUNC390 boolean retval, string hash = reaper.MIDI_GetHash(MediaItem_Take take, boolean notesonly, string hash)
DESC390 Get a string that only changes when the MIDI data changes. If notesonly==true, then the string changes only when the MIDI notes change. See MIDI_GetTrackHash
FUNC391 boolean retval, boolean selected, boolean muted, number startppqpos, number endppqpos, number chan, number pitch, number vel = reaper.MIDI_GetNote(MediaItem_Take take, integer noteidx)
DESC391 Get MIDI note properties.
FUNC392 number reaper.MIDI_GetPPQPos_EndOfMeasure(MediaItem_Take take, number ppqpos)
DESC392 Returns the MIDI tick (ppq) position corresponding to the end of the measure.
FUNC393 number reaper.MIDI_GetPPQPos_StartOfMeasure(MediaItem_Take take, number ppqpos)
DESC393 Returns the MIDI tick (ppq) position corresponding to the start of the measure.
FUNC394 number reaper.MIDI_GetPPQPosFromProjQN(MediaItem_Take take, number projqn)
DESC394 Returns the MIDI tick (ppq) position corresponding to a specific project time in quarter notes.
FUNC395 number reaper.MIDI_GetPPQPosFromProjTime(MediaItem_Take take, number projtime)
DESC395 Returns the MIDI tick (ppq) position corresponding to a specific project time in seconds.
FUNC396 number reaper.MIDI_GetProjQNFromPPQPos(MediaItem_Take take, number ppqpos)
DESC396 Returns the project time in quarter notes corresponding to a specific MIDI tick (ppq) position.
FUNC397 number reaper.MIDI_GetProjTimeFromPPQPos(MediaItem_Take take, number ppqpos)
DESC397 Returns the project time in seconds corresponding to a specific MIDI tick (ppq) position.
FUNC398 boolean retval, number root, number scale, string name = reaper.MIDI_GetScale(MediaItem_Take take, number root, number scale, string name)
DESC398 Get the active scale in the media source, if any. root 0=C, 1=C#, etc. scale &0x1=root, &0x2=minor 2nd, &0x4=major 2nd, &0x8=minor 3rd, &0xF=fourth, etc.
FUNC399 boolean retval, optional boolean selected, optional boolean muted, optional number ppqpos, optional number type, optional string msg = reaper.MIDI_GetTextSysexEvt(MediaItem_Take take, integer textsyxevtidx, optional boolean selected, optional boolean muted, optional number ppqpos, optional number type, optional string msg)
DESC399 Get MIDI meta-event properties. Allowable types are -1:sysex (msg should not include bounding F0..F7), 1-14:MIDI text event types, 15=REAPER notation event. For all other meta-messages, type is returned as -2 and msg returned as all zeroes. See MIDI_GetEvt.
FUNC400 boolean retval, string hash = reaper.MIDI_GetTrackHash(MediaTrack track, boolean notesonly, string hash)
DESC400 Get a string that only changes when the MIDI data changes. If notesonly==true, then the string changes only when the MIDI notes change. See MIDI_GetHash
FUNC401 boolean reaper.MIDI_InsertCC(MediaItem_Take take, boolean selected, boolean muted, number ppqpos, integer chanmsg, integer chan, integer msg2, integer msg3)
DESC401 Insert a new MIDI CC event.
FUNC402 boolean reaper.MIDI_InsertEvt(MediaItem_Take take, boolean selected, boolean muted, number ppqpos, string bytestr)
DESC402 Insert a new MIDI event.
FUNC403 boolean reaper.MIDI_InsertNote(MediaItem_Take take, boolean selected, boolean muted, number startppqpos, number endppqpos, integer chan, integer pitch, integer vel, optional boolean noSortIn)
DESC403 Insert a new MIDI note. Set noSort if inserting multiple events, then call MIDI_Sort when done.
FUNC404 boolean reaper.MIDI_InsertTextSysexEvt(MediaItem_Take take, boolean selected, boolean muted, number ppqpos, integer type, string bytestr)
DESC404 Insert a new MIDI text or sysex event. Allowable types are -1:sysex (msg should not include bounding F0..F7), 1-14:MIDI text event types, 15=REAPER notation event.
FUNC405 reaper.midi_reinit()
DESC405 Reset all MIDI devices
FUNC406 reaper.MIDI_SelectAll(MediaItem_Take take, boolean select)
DESC406 Select or deselect all MIDI content.
FUNC407 boolean reaper.MIDI_SetAllEvts(MediaItem_Take take, string buf)
DESC407 Set all MIDI data. MIDI buffer is passed in as a list of { int offset, char flag, int msglen, unsigned char msg[] }.offset: MIDI ticks from previous eventflag: &1=selected &2=mutedflag high 4 bits for CC shape: &16=linear, &32=slow start/end, &16|32=fast start, &64=fast end, &64|16=beziermsg: the MIDI message.A meta-event of type 0xF followed by 'CCBZ ' and 5 more bytes represents bezier curve data for the previous MIDI event: 1 byte for the bezier type (usually 0) and 4 bytes for the bezier tension as a float.For tick intervals longer than a 32 bit word can represent, zero-length meta events may be placed between valid events.See MIDI_GetAllEvts.
FUNC408 boolean reaper.MIDI_SetCC(MediaItem_Take take, integer ccidx, optional boolean selectedIn, optional boolean mutedIn, optional number ppqposIn, optional number chanmsgIn, optional number chanIn, optional number msg2In, optional number msg3In, optional boolean noSortIn)
DESC408 Set MIDI CC event properties. Properties passed as NULL will not be set. set noSort if setting multiple events, then call MIDI_Sort when done.
FUNC409 boolean reaper.MIDI_SetCCShape(MediaItem_Take take, integer ccidx, integer shape, number beztension, optional boolean noSortIn)
DESC409 Set CC shape and bezier tension. set noSort if setting multiple events, then call MIDI_Sort when done. See MIDI_SetCC, MIDI_GetCCShape
FUNC410 boolean reaper.MIDI_SetEvt(MediaItem_Take take, integer evtidx, optional boolean selectedIn, optional boolean mutedIn, optional number ppqposIn, optional string msg, optional boolean noSortIn)
DESC410 Set MIDI event properties. Properties passed as NULL will not be set. set noSort if setting multiple events, then call MIDI_Sort when done.
FUNC411 boolean reaper.MIDI_SetItemExtents(MediaItem item, number startQN, number endQN)
DESC411 Set the start/end positions of a media item that contains a MIDI take.
FUNC412 boolean reaper.MIDI_SetNote(MediaItem_Take take, integer noteidx, optional boolean selectedIn, optional boolean mutedIn, optional number startppqposIn, optional number endppqposIn, optional number chanIn, optional number pitchIn, optional number velIn, optional boolean noSortIn)
DESC412 Set MIDI note properties. Properties passed as NULL (or negative values) will not be set. Set noSort if setting multiple events, then call MIDI_Sort when done. Setting multiple note start positions at once is done more safely by deleting and re-inserting the notes.
FUNC413 boolean reaper.MIDI_SetTextSysexEvt(MediaItem_Take take, integer textsyxevtidx, optional boolean selectedIn, optional boolean mutedIn, optional number ppqposIn, optional number typeIn, optional string msg, optional boolean noSortIn)
DESC413 Set MIDI text or sysex event properties. Properties passed as NULL will not be set. Allowable types are -1:sysex (msg should not include bounding F0..F7), 1-14:MIDI text event types, 15=REAPER notation event. set noSort if setting multiple events, then call MIDI_Sort when done.
FUNC414 reaper.MIDI_Sort(MediaItem_Take take)
DESC414 Sort MIDI events after multiple calls to MIDI_SetNote, MIDI_SetCC, etc.
FUNC415 HWND reaper.MIDIEditor_GetActive()
DESC415 get a pointer to the focused MIDI editor windowsee MIDIEditor_GetMode, MIDIEditor_OnCommand
FUNC416 integer reaper.MIDIEditor_GetMode(HWND midieditor)
DESC416 get the mode of a MIDI editor (0=piano roll, 1=event list, -1=invalid editor)see MIDIEditor_GetActive, MIDIEditor_OnCommand
FUNC417 integer reaper.MIDIEditor_GetSetting_int(HWND midieditor, string setting_desc)
DESC417 Get settings from a MIDI editor. setting_desc can be:snap_enabled: returns 0 or 1active_note_row: returns 0-127last_clicked_cc_lane: returns 0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity, 0x208=notation events, 0x210=media item lanedefault_note_vel: returns 0-127default_note_chan: returns 0-15default_note_len: returns default length in MIDI ticksscale_enabled: returns 0-1scale_root: returns 0-12 (0=C)if setting_desc is unsupported, the function returns -1.See MIDIEditor_SetSetting_int, MIDIEditor_GetActive, MIDIEditor_GetSetting_str
FUNC418 boolean retval, string buf = reaper.MIDIEditor_GetSetting_str(HWND midieditor, string setting_desc, string buf)
DESC418 Get settings from a MIDI editor. setting_desc can be:last_clicked_cc_lane: returns text description ("velocity", "pitch", etc)scale: returns the scale record, for example "102034050607" for a major scaleif setting_desc is unsupported, the function returns false.See MIDIEditor_GetActive, MIDIEditor_GetSetting_int
FUNC419 MediaItem_Take reaper.MIDIEditor_GetTake(HWND midieditor)
DESC419 get the take that is currently being edited in this MIDI editor
FUNC420 boolean reaper.MIDIEditor_LastFocused_OnCommand(integer command_id, boolean islistviewcommand)
DESC420 Send an action command to the last focused MIDI editor. Returns false if there is no MIDI editor open, or if the view mode (piano roll or event list) does not match the input.see MIDIEditor_OnCommand
FUNC421 boolean reaper.MIDIEditor_OnCommand(HWND midieditor, integer command_id)
DESC421 Send an action command to a MIDI editor. Returns false if the supplied MIDI editor pointer is not valid (not an open MIDI editor).see MIDIEditor_GetActive, MIDIEditor_LastFocused_OnCommand
FUNC422 boolean reaper.MIDIEditor_SetSetting_int(HWND midieditor, string setting_desc, integer setting)
DESC422 Set settings for a MIDI editor. setting_desc can be:active_note_row: 0-127See MIDIEditor_GetSetting_int
FUNC423 string strNeed64 = reaper.mkpanstr(string strNeed64, number pan)
DESC423 
FUNC424 string strNeed64 = reaper.mkvolpanstr(string strNeed64, number vol, number pan)
DESC424 
FUNC425 string strNeed64 = reaper.mkvolstr(string strNeed64, number vol)
DESC425 
FUNC426 reaper.MoveEditCursor(number adjamt, boolean dosel)
DESC426 
FUNC427 boolean reaper.MoveMediaItemToTrack(MediaItem item, MediaTrack desttr)
DESC427 returns TRUE if move succeeded
FUNC428 reaper.MuteAllTracks(boolean mute)
DESC428 
FUNC429 reaper.my_getViewport(numberr.left, numberr.top, numberr.right, numberr.bot, number sr.left, number sr.top, number sr.right, number sr.bot, boolean wantWorkArea)
DESC429 
FUNC430 integer reaper.NamedCommandLookup(string command_name)
DESC430 Get the command ID number for named command that was registered by an extension such as "_SWS_ABOUT" or "_113088d11ae641c193a2b7ede3041ad5" for a ReaScript or a custom action.
FUNC431 reaper.OnPauseButton()
DESC431 direct way to simulate pause button hit
FUNC432 reaper.OnPauseButtonEx(ReaProject proj)
DESC432 direct way to simulate pause button hit
FUNC433 reaper.OnPlayButton()
DESC433 direct way to simulate play button hit
FUNC434 reaper.OnPlayButtonEx(ReaProject proj)
DESC434 direct way to simulate play button hit
FUNC435 reaper.OnStopButton()
DESC435 direct way to simulate stop button hit
FUNC436 reaper.OnStopButtonEx(ReaProject proj)
DESC436 direct way to simulate stop button hit
FUNC437 boolean reaper.OpenColorThemeFile(string fn)
DESC437 
FUNC438 HWND reaper.OpenMediaExplorer(string mediafn, boolean play)
DESC438 Opens mediafn in the Media Explorer, play=true will play the file immediately (or toggle playback if mediafn was already open), =false will just select it.
FUNC439 reaper.OscLocalMessageToHost(string message, optional number valueIn)
DESC439 Send an OSC message directly to REAPER. The value argument may be NULL. The message will be matched against the default OSC patterns. Only supported if control surface support was enabled when installing REAPER.
FUNC440 number reaper.parse_timestr(string buf)
DESC440 Parse hh:mm:ss.sss time string, return time in seconds (or 0.0 on error). See parse_timestr_pos, parse_timestr_len.
FUNC441 number reaper.parse_timestr_len(string buf, number offset, integer modeoverride)
DESC441 time formatting mode overrides: -1=proj default.0=time1=measures.beats + time2=measures.beats3=seconds4=samples5=h:m:s:f
FUNC442 number reaper.parse_timestr_pos(string buf, integer modeoverride)
DESC442 Parse time string, time formatting mode overrides: -1=proj default.0=time1=measures.beats + time2=measures.beats3=seconds4=samples5=h:m:s:f
FUNC443 number reaper.parsepanstr(string str)
DESC443 
FUNC444 integer retval, string descstr = reaper.PCM_Sink_Enum(integer idx)
DESC444 
FUNC445 string reaper.PCM_Sink_GetExtension(string data)
DESC445 
FUNC446 HWND reaper.PCM_Sink_ShowConfig(string cfg, HWND hwndParent)
DESC446 
FUNC447 PCM_source reaper.PCM_Source_CreateFromFile(string filename)
DESC447 See PCM_Source_CreateFromFileEx.
FUNC448 PCM_source reaper.PCM_Source_CreateFromFileEx(string filename, boolean forcenoMidiImp)
DESC448 Create a PCM_source from filename, and override pref of MIDI files being imported as in-project MIDI events.
FUNC449 PCM_source reaper.PCM_Source_CreateFromType(string sourcetype)
DESC449 Create a PCM_source from a "type" (use this if you're going to load its state via LoadState/ProjectStateContext).Valid types include "WAVE", "MIDI", or whatever plug-ins define as well.
FUNC450 reaper.PCM_Source_Destroy(PCM_source src)
DESC450 Deletes a PCM_source -- be sure that you remove any project reference before deleting a source
FUNC451 integer reaper.PCM_Source_GetPeaks(PCM_source src, number peakrate, number starttime, integer numchannels, integer numsamplesperchannel, integer want_extra_type, reaper.array buf)
DESC451 Gets block of peak samples to buf. Note that the peak samples are interleaved, but in two or three blocks (maximums, then minimums, then extra). Return value has 20 bits of returned sample count, then 4 bits of output_mode (0xf00000), then a bit to signify whether extra_type was available (0x1000000). extra_type can be 115 ('s') for spectral information, which will return peak samples as integers with the low 15 bits frequency, next 14 bits tonality.
FUNC452 boolean retval, number offs, number len, boolean rev = reaper.PCM_Source_GetSectionInfo(PCM_source src)
DESC452 If a section/reverse block, retrieves offset/len/reverse. return true if success
FUNC453 reaper.PluginWantsAlwaysRunFx(integer amt)
DESC453 
FUNC454 reaper.PreventUIRefresh(integer prevent_count)
DESC454 adds prevent_count to the UI refresh prevention state; always add then remove the same amount, or major disfunction will occur
FUNC455 integer reaper.PromptForAction(integer session_mode, integer init_id, integer section_id)
DESC455 Uses the action list to choose an action. Call with session_mode=1 to create a session (init_id will be the initial action to select, or 0), then poll with session_mode=0, checking return value for user-selected action (will return 0 if no action selected yet, or -1 if the action window is no longer available). When finished, call with session_mode=-1.
FUNC456 reaper.ReaScriptError(string errmsg)
DESC456 Causes REAPER to display the error message after the current ReaScript finishes. If called within a Lua context and errmsg has a ! prefix, script execution will be terminated.
FUNC457 integer reaper.RecursiveCreateDirectory(string path, integer ignored)
DESC457 returns positive value on success, 0 on failure.
FUNC458 integer reaper.reduce_open_files(integer flags)
DESC458 garbage-collects extra open files and closes them. if flags has 1 set, this is done incrementally (call this from a regular timer, if desired). if flags has 2 set, files are aggressively closed (they may need to be re-opened very soon). returns number of files closed by this call.
FUNC459 reaper.RefreshToolbar(integer command_id)
DESC459 See RefreshToolbar2.
FUNC460 reaper.RefreshToolbar2(integer section_id, integer command_id)
DESC460 Refresh the toolbar button states of a toggle action.
FUNC461 string out = reaper.relative_fn(string in, string out)
DESC461 Makes a filename "in" relative to the current project, if any.
FUNC462 boolean reaper.RemoveTrackSend(MediaTrack tr, integer category, integer sendidx)
DESC462 Remove a send/receive/hardware output, return true on success. category is <0 for receives, 0=sends, >0 for hardware outputs. See CreateTrackSend, GetSetTrackSendInfo, GetTrackSendInfo_Value, SetTrackSendInfo_Value, GetTrackNumSends.
FUNC463 boolean reaper.RenderFileSection(string source_filename, string target_filename, number start_percent, number end_percent, number playrate)
DESC463 Not available while playing back.
FUNC464 boolean reaper.ReorderSelectedTracks(integer beforeTrackIdx, integer makePrevFolder)
DESC464 Moves all selected tracks to immediately above track specified by index beforeTrackIdx, returns false if no tracks were selected. makePrevFolder=0 for normal, 1 = as child of track preceding track specified by beforeTrackIdx, 2 = if track preceding track specified by beforeTrackIdx is last track in folder, extend folder
FUNC465 string reaper.Resample_EnumModes(integer mode)
DESC465 
FUNC466 string out = reaper.resolve_fn(string in, string out)
DESC466 See resolve_fn2.
FUNC467 string out = reaper.resolve_fn2(string in, string out, optional string checkSubDir)
DESC467 Resolves a filename "in" by using project settings etc. If no file found, out will be a copy of in.
FUNC468 string reaper.ReverseNamedCommandLookup(integer command_id)
DESC468 Get the named command for the given command ID. The returned string will not start with '_' (e.g. it will return "SWS_ABOUT"), it will be NULL if command_id is a native action.
FUNC469 number reaper.ScaleFromEnvelopeMode(integer scaling_mode, number val)
DESC469 See GetEnvelopeScalingMode.
FUNC470 number reaper.ScaleToEnvelopeMode(integer scaling_mode, number val)
DESC470 See GetEnvelopeScalingMode.
FUNC471 reaper.SelectAllMediaItems(ReaProject proj, boolean selected)
DESC471 
FUNC472 reaper.SelectProjectInstance(ReaProject proj)
DESC472 
FUNC473 reaper.SetActiveTake(MediaItem_Take take)
DESC473 set this take active in this media item
FUNC474 reaper.SetAutomationMode(integer mode, boolean onlySel)
DESC474 sets all or selected tracks to mode.
FUNC475 reaper.SetCurrentBPM(ReaProject __proj, number bpm, boolean wantUndo)
DESC475 set current BPM in project, set wantUndo=true to add undo point
FUNC476 reaper.SetCursorContext(integer mode, TrackEnvelope envIn)
DESC476 You must use this to change the focus programmatically. mode=0 to focus track panels, 1 to focus the arrange window, 2 to focus the arrange window and select env (or env==NULL to clear the current track/take envelope selection)
FUNC477 reaper.SetEditCurPos(number time, boolean moveview, boolean seekplay)
DESC477 
FUNC478 reaper.SetEditCurPos2(ReaProject proj, number time, boolean moveview, boolean seekplay)
DESC478 
FUNC479 boolean reaper.SetEnvelopePoint(TrackEnvelope envelope, integer ptidx, optional number timeIn, optional number valueIn, optional number shapeIn, optional number tensionIn, optional boolean selectedIn, optional boolean noSortIn)
DESC479 Set attributes of an envelope point. Values that are not supplied will be ignored. If setting multiple points at once, set noSort=true, and call Envelope_SortPoints when done. See SetEnvelopePointEx.
FUNC480 boolean reaper.SetEnvelopePointEx(TrackEnvelope envelope, integer autoitem_idx, integer ptidx, optional number timeIn, optional number valueIn, optional number shapeIn, optional number tensionIn, optional boolean selectedIn, optional boolean noSortIn)
DESC480 Set attributes of an envelope point. Values that are not supplied will be ignored. If setting multiple points at once, set noSort=true, and call Envelope_SortPoints when done.autoitem_idx=-1 for the underlying envelope, 0 for the first automation item on the envelope, etc.For automation items, pass autoitem_idx|0x10000000 to base ptidx on the number of points in one full loop iteration,even if the automation item is trimmed so that not all points are visible.Otherwise, ptidx will be based on the number of visible points in the automation item, including all loop iterations.See CountEnvelopePointsEx, GetEnvelopePointEx, InsertEnvelopePointEx, DeleteEnvelopePointEx.
FUNC481 boolean reaper.SetEnvelopeStateChunk(TrackEnvelope env, string str, boolean isundo)
DESC481 Sets the RPPXML state of an envelope, returns true if successful. Undo flag is a performance/caching hint.
FUNC482 reaper.SetExtState(string section, string key, string value, boolean persist)
DESC482 Set the extended state value for a specific section and key. persist=true means the value should be stored and reloaded the next time REAPER is opened. See GetExtState, DeleteExtState, HasExtState.
FUNC483 reaper.SetGlobalAutomationOverride(integer mode)
DESC483 mode: see GetGlobalAutomationOverride
FUNC484 boolean reaper.SetItemStateChunk(MediaItem item, string str, boolean isundo)
DESC484 Sets the RPPXML state of an item, returns true if successful. Undo flag is a performance/caching hint.
FUNC485 integer reaper.SetMasterTrackVisibility(integer flag)
DESC485 set &1 to show the master track in the TCP, &2 to HIDE in the mixer. Returns the previous visibility state. See GetMasterTrackVisibility.
FUNC486 boolean reaper.SetMediaItemInfo_Value(MediaItem item, string parmname, number newvalue)
DESC486 Set media item numerical-value attributes.B_MUTE : bool * : muted (item solo overrides). setting this value will clear C_MUTE_SOLO.B_MUTE_ACTUAL : bool * : muted (ignores solo). setting this value will not affect C_MUTE_SOLO.C_MUTE_SOLO : char * : solo override (-1=soloed, 0=no override, 1=unsoloed). note that this API does not automatically unsolo other items when soloing (nor clear the unsolos when clearing the last soloed item), it must be done by the caller via action or via this API.B_LOOPSRC : bool * : loop sourceB_ALLTAKESPLAY : bool * : all takes playB_UISEL : bool * : selected in arrange viewC_BEATATTACHMODE : char * : item timebase, -1=track or project default, 1=beats (position, length, rate), 2=beats (position only). for auto-stretch timebase: C_BEATATTACHMODE=1, C_AUTOSTRETCH=1C_AUTOSTRETCH: : char * : auto-stretch at project tempo changes, 1=enabled, requires C_BEATATTACHMODE=1C_LOCK : char * : locked, &1=lockedD_VOL : double * : item volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etcD_POSITION : double * : item position in secondsD_LENGTH : double * : item length in secondsD_SNAPOFFSET : double * : item snap offset in secondsD_FADEINLEN : double * : item manual fadein length in secondsD_FADEOUTLEN : double * : item manual fadeout length in secondsD_FADEINDIR : double * : item fadein curvature, -1..1D_FADEOUTDIR : double * : item fadeout curvature, -1..1D_FADEINLEN_AUTO : double * : item auto-fadein length in seconds, -1=no auto-fadeinD_FADEOUTLEN_AUTO : double * : item auto-fadeout length in seconds, -1=no auto-fadeoutC_FADEINSHAPE : int * : fadein shape, 0..6, 0=linearC_FADEOUTSHAPE : int * : fadeout shape, 0..6, 0=linearI_GROUPID : int * : group ID, 0=no groupI_LASTY : int * : Y-position of track in pixels (read-only)I_LASTH : int * : height in track in pixels (read-only)I_CUSTOMCOLOR : int * : custom color, OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). If you do not |0x100000, then it will not be used, but will store the colorI_CURTAKE : int * : active take numberIP_ITEMNUMBER : int, item number on this track (read-only, returns the item number directly)F_FREEMODE_Y : float * : free item positioning Y-position, 0=top of track, 1=bottom of track (will never be 1)F_FREEMODE_H : float * : free item positioning height, 0=no height, 1=full height of track (will never be 0)
FUNC487 boolean reaper.SetMediaItemLength(MediaItem item, number length, boolean refreshUI)
DESC487 Redraws the screen only if refreshUI == true.See UpdateArrange().
FUNC488 boolean reaper.SetMediaItemPosition(MediaItem item, number position, boolean refreshUI)
DESC488 Redraws the screen only if refreshUI == true.See UpdateArrange().
FUNC489 reaper.SetMediaItemSelected(MediaItem item, boolean selected)
DESC489 
FUNC490 boolean reaper.SetMediaItemTake_Source(MediaItem_Take take, PCM_source source)
DESC490 Set media source of media item take. The old source will not be destroyed, it is the caller's responsibility to retrieve it and destroy it after. If source already exists in any project, it will be duplicated before being set. C/C++ code should not use this and instead use GetSetMediaItemTakeInfo() with P_SOURCE to manage ownership directly.
FUNC491 boolean reaper.SetMediaItemTakeInfo_Value(MediaItem_Take take, string parmname, number newvalue)
DESC491 Set media item take numerical-value attributes.D_STARTOFFS : double * : start offset in source media, in secondsD_VOL : double * : take volume, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etc, negative if take polarity is flippedD_PAN : double * : take pan, -1..1D_PANLAW : double * : take pan law, -1=default, 0.5=-6dB, 1.0=+0dB, etcD_PLAYRATE : double * : take playback rate, 0.5=half speed, 1=normal, 2=double speed, etcD_PITCH : double * : take pitch adjustment in semitones, -12=one octave down, 0=normal, +12=one octave up, etcB_PPITCH : bool * : preserve pitch when changing playback rateI_CHANMODE : int * : channel mode, 0=normal, 1=reverse stereo, 2=downmix, 3=left, 4=rightI_PITCHMODE : int * : pitch shifter mode, -1=projext default, otherwise high 2 bytes=shifter, low 2 bytes=parameterI_CUSTOMCOLOR : int * : custom color, OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). If you do not |0x100000, then it will not be used, but will store the colorIP_TAKENUMBER : int : take number (read-only, returns the take number directly)
FUNC492 boolean reaper.SetMediaTrackInfo_Value(MediaTrack tr, string parmname, number newvalue)
DESC492 Set track numerical-value attributes.B_MUTE : bool * : mutedB_PHASE : bool * : track phase invertedB_RECMON_IN_EFFECT : bool * : record monitoring in effect (current audio-thread playback state, read-only)IP_TRACKNUMBER : int : track number 1-based, 0=not found, -1=master track (read-only, returns the int directly)I_SOLO : int * : soloed, 0=not soloed, 1=soloed, 2=soloed in place, 5=safe soloed, 6=safe soloed in placeI_FXEN : int * : fx enabled, 0=bypassed, !0=fx activeI_RECARM : int * : record armed, 0=not record armed, 1=record armedI_RECINPUT : int * : record input, <0=no input. if 4096 set, input is MIDI and low 5 bits represent channel (0=all, 1-16=only chan), next 6 bits represent physical input (63=all, 62=VKB). If 4096 is not set, low 10 bits (0..1023) are input start channel (ReaRoute/Loopback start at 512). If 2048 is set, input is multichannel input (using track channel count), or if 1024 is set, input is stereo input, otherwise input is mono.I_RECMODE : int * : record mode, 0=input, 1=stereo out, 2=none, 3=stereo out w/latency compensation, 4=midi output, 5=mono out, 6=mono out w/ latency compensation, 7=midi overdub, 8=midi replaceI_RECMON : int * : record monitoring, 0=off, 1=normal, 2=not when playing (tape style)I_RECMONITEMS : int * : monitor items while recording, 0=off, 1=onI_AUTOMODE : int * : track automation mode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latchI_NCHAN : int * : number of track channels, 2-64, even numbers onlyI_SELECTED : int * : track selected, 0=unselected, 1=selectedI_WNDH : int * : current TCP window height in pixels including envelopes (read-only)I_TCPH : int * : current TCP window height in pixels not including envelopes (read-only)I_TCPY : int * : current TCP window Y-position in pixels relative to top of arrange view (read-only)I_MCPX : int * : current MCP X-position in pixels relative to mixer containerI_MCPY : int * : current MCP Y-position in pixels relative to mixer containerI_MCPW : int * : current MCP width in pixelsI_MCPH : int * : current MCP height in pixelsI_FOLDERDEPTH : int * : folder depth change, 0=normal, 1=track is a folder parent, -1=track is the last in the innermost folder, -2=track is the last in the innermost and next-innermost folders, etcI_FOLDERCOMPACT : int * : folder compacted state (only valid on folders), 0=normal, 1=small, 2=tiny childrenI_MIDIHWOUT : int * : track midi hardware output index, <0=disabled, low 5 bits are which channels (0=all, 1-16), next 5 bits are output device index (0-31)I_PERFFLAGS : int * : track performance flags, &1=no media buffering, &2=no anticipative FXI_CUSTOMCOLOR : int * : custom color, OS dependent color|0x100000 (i.e. ColorToNative(r,g,b)|0x100000). If you do not |0x100000, then it will not be used, but will store the colorI_HEIGHTOVERRIDE : int * : custom height override for TCP window, 0 for none, otherwise size in pixelsB_HEIGHTLOCK : bool * : track height lock (must set I_HEIGHTOVERRIDE before locking)D_VOL : double * : trim volume of track, 0=-inf, 0.5=-6dB, 1=+0dB, 2=+6dB, etcD_PAN : double * : trim pan of track, -1..1D_WIDTH : double * : width of track, -1..1D_DUALPANL : double * : dualpan position 1, -1..1, only if I_PANMODE==6D_DUALPANR : double * : dualpan position 2, -1..1, only if I_PANMODE==6I_PANMODE : int * : pan mode, 0=classic 3.x, 3=new balance, 5=stereo pan, 6=dual panD_PANLAW : double * : pan law of track, <0=project default, 1=+0dB, etcP_ENV:<envchunkname or P_ENV:{GUID... : TrackEnvelope*, read only. chunkname can be <VOLENV, <PANENV, etc; GUID is the stringified envelope GUID.B_SHOWINMIXER : bool * : track control panel visible in mixer (do not use on master track)B_SHOWINTCP : bool * : track control panel visible in arrange view (do not use on master track)B_MAINSEND : bool * : track sends audio to parentC_MAINSEND_OFFS : char * : channel offset of track send to parentB_FREEMODE : bool * : track free item positioning enabled (call UpdateTimeline() after changing)C_BEATATTACHMODE : char * : track timebase, -1=project default, 0=time, 1=beats (position, length, rate), 2=beats (position


 only)F_MCP_FXSEND_SCALE : float * : scale of fx+send area in MCP (0=minimum allowed, 1=maximum allowed)F_MCP_FXPARM_SCALE : float * : scale of fx parameter area in MCP (0=minimum allowed, 1=maximum allowed)F_MCP_SENDRGN_SCALE : float * : scale of send area as proportion of the fx+send total area (0=minimum allowed, 1=maximum allowed)F_TCP_FXPARM_SCALE : float * : scale of TCP parameter area when TCP FX are embedded (0=min allowed, default, 1=max allowed)I_PLAY_OFFSET_FLAG : int * : track playback offset state, &1=bypassed, &2=offset value is measured in samples (otherwise measured in seconds)D_PLAY_OFFSET : double * : track playback offset, units depend on I_PLAY_OFFSET_FLAG
FUNC493 reaper.SetMIDIEditorGrid(ReaProject project, number division)
DESC493 Set the MIDI editor grid division. 0.25=quarter note, 1.0/3.0=half note tripet, etc.
FUNC494 MediaTrack reaper.SetMixerScroll(MediaTrack leftmosttrack)
DESC494 Scroll the mixer so that leftmosttrack is the leftmost visible track. Returns the leftmost track after scrolling, which may be different from the passed-in track if there are not enough tracks to its right.
FUNC495 reaper.SetMouseModifier(string context, integer modifier_flag, string action)
DESC495 Set the mouse modifier assignment for a specific modifier key assignment, in a specific context.Context is a string like "MM_CTX_ITEM". Find these strings by modifying an assignment inPreferences/Editing/Mouse Modifiers, then looking in reaper-mouse.ini.Modifier flag is a number from 0 to 15: add 1 for shift, 2 for control, 4 for alt, 8 for win.(macOS: add 1 for shift, 2 for command, 4 for opt, 8 for control.)For left-click and double-click contexts, the action can be any built-in command ID numberor any custom action ID string. Find built-in command IDs in the REAPER actions window(enable "show action IDs" in the context menu), and find custom action ID strings in reaper-kb.ini.For built-in mouse modifier behaviors, find action IDs (which will be low numbers)by modifying an assignment in Preferences/Editing/Mouse Modifiers, then looking in reaper-mouse.ini.Assigning an action of -1 will reset that mouse modifier behavior to factory default.See GetMouseModifier.
FUNC496 reaper.SetOnlyTrackSelected(MediaTrack track)
DESC496 Set exactly one track selected, deselect all others
FUNC497 reaper.SetProjectGrid(ReaProject project, number division)
DESC497 Set the arrange view grid division. 0.25=quarter note, 1.0/3.0=half note triplet, etc.
FUNC498 boolean reaper.SetProjectMarker(integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name)
DESC498 
FUNC499 boolean reaper.SetProjectMarker2(ReaProject proj, integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name)
DESC499 
FUNC500 boolean reaper.SetProjectMarker3(ReaProject proj, integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name, integer color)
DESC500 
FUNC501 boolean reaper.SetProjectMarker4(ReaProject proj, integer markrgnindexnumber, boolean isrgn, number pos, number rgnend, string name, integer color, integer flags)
DESC501 color should be 0 to not change, or ColorToNative(r,g,b)|0x1000000, flags&1 to clear name
FUNC502 boolean reaper.SetProjectMarkerByIndex(ReaProject proj, integer markrgnidx, boolean isrgn, number pos, number rgnend, integer IDnumber, string name, integer color)
DESC502 See SetProjectMarkerByIndex2.
FUNC503 boolean reaper.SetProjectMarkerByIndex2(ReaProject proj, integer markrgnidx, boolean isrgn, number pos, number rgnend, integer IDnumber, string name, integer color, integer flags)
DESC503 Differs from SetProjectMarker4 in that markrgnidx is 0 for the first marker/region, 1 for the next, etc (see EnumProjectMarkers3), rather than representing the displayed marker/region ID number (see SetProjectMarker3). Function will fail if attempting to set a duplicate ID number for a region (duplicate ID numbers for markers are OK). , flags&1 to clear name.
FUNC504 integer reaper.SetProjExtState(ReaProject proj, string extname, string key, string value)
DESC504 Save a key/value pair for a specific extension, to be restored the next time this specific project is loaded. Typically extname will be the name of a reascript or extension section. If key is NULL or "", all extended data for that extname will be deleted. If val is NULL or "", the data previously associated with that key will be deleted. Returns the size of the state for this extname. See GetProjExtState, EnumProjExtState.
FUNC505 reaper.SetRegionRenderMatrix(ReaProject proj, integer regionindex, MediaTrack track, integer addorremove)
DESC505 Add (addorremove > 0) or remove (addorremove < 0) a track from this region when using the region render matrix.
FUNC506 integer reaper.SetTakeMarker(MediaItem_Take take, integer idx, string nameIn, optional number srcposIn, optional number colorIn)
DESC506 Inserts or updates a take marker. If idx<0, a take marker will be added, otherwise an existing take marker will be updated. Returns the index of the new or updated take marker (which may change if srcPos is updated). See GetNumTakeMarkers, GetTakeMarker, DeleteTakeMarker
FUNC507 integer reaper.SetTakeStretchMarker(MediaItem_Take take, integer idx, number pos, optional number srcposIn)
DESC507 Adds or updates a stretch marker. If idx<0, stretch marker will be added. If idx>=0, stretch marker will be updated. When adding, if srcposInOptional is omitted, source position will be auto-calculated. When updating a stretch marker, if srcposInOptional is omitted, srcpos will not be modified. Position/srcposition values will be constrained to nearby stretch markers. Returns index of stretch marker, or -1 if did not insert (or marker already existed at time).
FUNC508 boolean reaper.SetTakeStretchMarkerSlope(MediaItem_Take take, integer idx, number slope)
DESC508 See GetTakeStretchMarkerSlope
FUNC509 boolean reaper.SetTempoTimeSigMarker(ReaProject proj, integer ptidx, number timepos, integer measurepos, number beatpos, number bpm, integer timesig_num, integer timesig_denom, boolean lineartempo)
DESC509 Set parameters of a tempo/time signature marker. Provide either timepos (with measurepos=-1, beatpos=-1), or measurepos and beatpos (with timepos=-1). If timesig_num and timesig_denom are zero, the previous time signature will be used. ptidx=-1 will insert a new tempo/time signature marker. See CountTempoTimeSigMarkers, GetTempoTimeSigMarker, AddTempoTimeSigMarker.
FUNC510 integer reaper.SetThemeColor(string ini_key, integer color, integer flags)
DESC510 Temporarily updates the theme color to the color specified (or the theme default color if -1 is specified). Returns -1 on failure, otherwise returns the color (or transformed-color). Note that the UI is not updated by this, the caller should call UpdateArrange() etc as necessary. If the low bit of flags is set, any color transformations are bypassed. To read a value see GetThemeColor.Currently valid ini_keys:col_main_bg2 : Main window/transport background -- current RGB: 51,51,51col_main_text2 : Main window/transport text -- current RGB: 170,170,170col_main_textshadow : Main window text shadow (ignored if too close to text color) -- current RGB: 18,26,29col_main_3dhl : Main window 3D highlight -- current RGB: 51,51,51col_main_3dsh : Main window 3D shadow -- current RGB: 51,51,51col_main_resize2 : Main window pane resize mouseover -- current RGB: 51,51,51col_main_text : Window text -- current RGB: 64,64,64col_main_bg : Window background -- current RGB: 186,192,192col_main_editbk : Window edit background -- current RGB: 207,211,211col_transport_editbk : Transport edit background -- current RGB: 51,51,51col_toolbar_text : Toolbar button text -- current RGB: 159,159,159col_toolbar_text_on : Toolbar button enabled text -- current RGB: 191,251,192col_toolbar_frame : Toolbar frame when floating or docked -- current RGB: 71,78,78toolbararmed_color : Toolbar button armed color -- current RGB: 255,128,0toolbararmed_drawmode : Toolbar button armed fill mode -- blendmode 00028001io_text : I/O window text -- current RGB: 63,74,75io_3dhl : I/O window 3D highlight -- current RGB: 126,137,137io_3dsh : I/O window 3D shadow -- current RGB: 201,207,207genlist_bg : Window list background -- current RGB: 255,255,255genlist_fg : Window list text -- current RGB: 0,0,0genlist_grid : Window list grid lines -- current RGB: 224,224,224genlist_selbg : Window list selected row -- current RGB: 51,153,255genlist_selfg : Window list selected text -- current RGB: 255,255,255genlist_seliabg : Window list selected row (inactive) -- current RGB: 240,240,240genlist_seliafg : Window list selected text (inactive) -- current RGB: 0,0,0genlist_hilite : Window list highlighted text -- current RGB: 0,0,224genlist_hilite_sel : Window list highlighted selected text -- current RGB: 192,192,255col_buttonbg : Button background -- current RGB: 0,0,0col_tcp_text : Track panel text -- current RGB: 18,26,29col_tcp_textsel : Track panel (selected) text -- current RGB: 18,26,29col_seltrack : Selected track control panel background -- current RGB: 210,210,210col_seltrack2 : Unselected track control panel background (enabled with a checkbox above) -- current RGB: 197,197,197tcplocked_color : Locked track control panel overlay color -- current RGB: 51,51,51tcplocked_drawmode : Locked track control panel fill mode -- blendmode 0002c000col_tracklistbg : Empty track list area -- current RGB: 51,51,51col_mixerbg : Empty mixer list area -- current RGB: 51,51,51col_arrangebg : Empty arrange view area -- current RGB: 190,192,192arrange_vgrid : Empty arrange view area vertical grid shading -- current RGB: 190,192,192col_fadearm : Fader background when automation recording -- current RGB: 255,125,125col_fadearm2 : Fader background when automation playing -- current RGB: 125,255,125col_fadearm3 : Fader background when in inactive touch/latch -- current RGB: 255,255,98col_tl_fg : Timeline foreground -- current RGB: 169,171,171col_tl_fg2 : Timeline foreground (secondary markings) -- current RGB: 121,122,122col_tl_bg : Timeline background -- current RGB: 73,73,73col_tl_bgsel : Time selection color -- current RGB: 255,255,255timesel_drawmode : Time selection fill mode -- blendmode 00021901col_tl_bgsel2 : Timeline background (in loop points) -- current RGB: 255,255,255col_trans_bg : Transport status background -- current RGB: 73,73,73col_trans_fg : Transport status text -- current RGB: 169,171,171playrate_edited : Project play rate control when not 1.0 -- current RGB: 127,63,0col_mi_label : Media item label -- current RGB: 35,35,35col_mi_label_sel : Media item label (selected) -- cu


rrent RGB: 235,235,235col_mi_label_float : Floating media item label -- current RGB: 35,35,35col_mi_label_float_sel : Floating media item label (selected) -- current RGB: 8,8,8col_mi_bg : Media item background (odd tracks) -- current RGB: 175,182,182col_mi_bg2 : Media item background (even tracks) -- current RGB: 178,178,178col_tr1_itembgsel : Media item background selected (odd tracks) -- current RGB: 59,59,59col_tr2_itembgsel : Media item background selected (even tracks) -- current RGB: 59,59,59itembg_drawmode : Media item background fill mode -- blendmode 00030000col_tr1_peaks : Media item peaks (odd tracks) -- current RGB: 89,94,98col_tr2_peaks : Media item peaks (even tracks) -- current RGB: 89,94,98col_tr1_ps2 : Media item peaks when selected (odd tracks) -- current RGB: 200,202,204col_tr2_ps2 : Media item peaks when selected (even tracks) -- current RGB: 200,202,204col_peaksedge : Media item peaks edge highlight (odd tracks) -- current RGB: 49,54,57col_peaksedge2 : Media item peaks edge highlight (even tracks) -- current RGB: 49,54,57col_peaksedgesel : Media item peaks edge highlight when selected (odd tracks) -- current RGB: 230,231,232col_peaksedgesel2 : Media item peaks edge highlight when selected (even tracks) -- current RGB: 230,231,232cc_chase_drawmode : Media item MIDI CC peaks fill mode -- blendmode 00024000col_peaksfade : Media item peaks when active in crossfade editor (fade-out) -- current RGB: 0,255,0col_peaksfade2 : Media item peaks when active in crossfade editor (fade-in) -- current RGB: 255,0,0col_mi_fades : Media item fade/volume controls -- current RGB: 215,215,215fadezone_color : Media item fade quiet zone fill color -- current RGB: 215,215,215fadezone_drawmode : Media item fade quiet zone fill mode -- blendmode 00022600fadearea_color : Media item fade full area fill color -- current RGB: 0,0,96fadearea_drawmode : Media item fade full area fill mode -- blendmode 00020000col_mi_fade2 : Media item edges of controls -- current RGB: 194,204,204col_mi_fade2_drawmode : Media item edges of controls blend mode -- blendmode 00025901item_grouphl : Media item edge when selected via grouping -- current RGB: 51,184,48col_offlinetext : Media item "offline" text -- current RGB: 48,66,71col_stretchmarker : Media item stretch marker line -- current RGB: 84,124,124col_stretchmarker_h0 : Media item stretch marker handle (1x) -- current RGB: 120,135,135col_stretchmarker_h1 : Media item stretch marker handle (>1x) -- current RGB: 40,141,196col_stretchmarker_h2 : Media item stretch marker handle (<1x) -- current RGB: 159,64,64col_stretchmarker_b : Media item stretch marker handle edge -- current RGB: 192,192,192col_stretchmarkerm : Media item stretch marker blend mode -- blendmode 00030000col_stretchmarker_text : Media item stretch marker text -- current RGB: 126,153,154col_stretchmarker_tm : Media item transient guide handle -- current RGB: 0,234,0take_marker : Media item take marker -- current RGB: 255,255,0selitem_tag : Selected media item bar color -- current RGB: 0,0,0activetake_tag : Active media item take bar color -- current RGB: 0,0,0col_tr1_bg : Track background (odd tracks) -- current RGB: 196,198,198col_tr2_bg : Track background (even tracks) -- current RGB: 190,192,192selcol_tr1_bg : Selected track background (odd tracks) -- current RGB: 196,198,198selcol_tr2_bg : Selected track background (even tracks) -- current RGB: 190,192,192col_tr1_divline : Track divider line (odd tracks) -- current RGB: 196,198,198col_tr2_divline : Track divider line (even tracks) -- current RGB: 190,192,192col_envlane1_divline : Envelope lane divider line (odd tracks) -- current RGB: 255,255,255col_envlane2_divline : Envelope lane divider line (even tracks) -- current RGB: 255,255,255marquee_fill : Marquee fill -- current RGB: 128,128,110marquee_drawmode : Marquee fill mode -- blendmode 000299ffmarquee_outline : Marquee outline -- current RGB: 255,255,255marqueezoom_fill : Marquee zoom fill -- current RGB: 255,255,255marqueezoom_drawmode : Marquee zoom fill mode -- blendmode 00024002marqueezoom_outline : Marquee zoom outline 


-- current RGB: 0,255,0areasel_fill : Razor edit area fill -- current RGB: 31,233,192areasel_drawmode : Razor edit area fill mode -- blendmode 00021c01areasel_outline : Razor edit area outline -- current RGB: 0,251,201areasel_outlinemode : Razor edit area outline mode -- blendmode 0002c000col_cursor : Edit cursor -- current RGB: 235,235,235col_cursor2 : Edit cursor (alternate) -- current RGB: 235,235,235playcursor_color : Play cursor -- current RGB: 0,0,0playcursor_drawmode : Play cursor fill mode -- blendmode 00028003col_gridlines2 : Grid lines (start of measure) -- current RGB: 159,159,159col_gridlines2dm : Grid lines (start of measure) - draw mode -- blendmode 00030000col_gridlines3 : Grid lines (start of beats) -- current RGB: 167,167,167col_gridlines3dm : Grid lines (start of beats) - draw mode -- blendmode 00030000col_gridlines : Grid lines (in between beats) -- current RGB: 182,182,182col_gridlines1dm : Grid lines (in between beats) - draw mode -- blendmode 00030000guideline_color : Editing guide line color -- current RGB: 95,169,167guideline_drawmode : Editing guide fill mode -- blendmode 00024c01region : Regions -- current RGB: 128,138,138region_lane_bg : Region lane background -- current RGB: 51,51,51region_lane_text : Region lane text -- current RGB: 31,39,37marker : Markers -- current RGB: 0,82,121marker_lane_bg : Marker lane background -- current RGB: 73,73,73marker_lane_text : Marker lane text -- current RGB: 165,165,165col_tsigmark : Time signature change marker -- current RGB: 31,39,37ts_lane_bg : Time signature lane background -- current RGB: 51,51,51ts_lane_text : Time signature lane text -- current RGB: 165,165,165timesig_sel_bg : Time signature marker selected background -- current RGB: 0,82,121col_routinghl1 : Routing matrix row highlight -- current RGB: 255,255,192col_routinghl2 : Routing matrix column highlight -- current RGB: 128,128,255col_vudoint : Theme has interlaced VU meters -- bool 00000000col_vuclip : VU meter clip indicator -- current RGB: 255,0,0col_vutop : VU meter top -- current RGB: 0,254,149col_vumid : VU meter middle -- current RGB: 0,218,173col_vubot : VU meter bottom -- current RGB: 0,191,191col_vuintcol : VU meter interlace/edge color -- current RGB: 32,32,32col_vumidi : VU meter midi activity -- current RGB: 255,0,0col_vuind1 : VU (indicator) - no signal -- current RGB: 32,32,32col_vuind2 : VU (indicator) - low signal -- current RGB: 0,40,0col_vuind3 : VU (indicator) - med signal -- current RGB: 32,255,0col_vuind4 : VU (indicator) - hot signal -- current RGB: 255,255,0mcp_sends_normal : Sends text: normal -- current RGB: 163,163,163mcp_sends_muted : Sends text: muted -- current RGB: 152,134,99mcp_send_midihw : Sends text: MIDI hardware -- current RGB: 40,40,40mcp_sends_levels : Sends level -- current RGB: 48,66,71mcp_fx_normal : FX insert text: normal -- current RGB: 164,164,164mcp_fx_bypassed : FX insert text: bypassed -- current RGB: 152,134,99mcp_fx_offlined : FX insert text: offline -- current RGB: 152,99,99mcp_fxparm_normal : FX parameter text: normal -- current RGB: 163,163,163mcp_fxparm_bypassed : FX parameter text: bypassed -- current RGB: 152,134,99mcp_fxparm_offlined : FX parameter text: offline -- current RGB: 152,99,99tcp_list_scrollbar : List scrollbar (track panel) -- current RGB: 50,50,50tcp_list_scrollbar_mode : List scrollbar (track panel) - draw mode -- blendmode 00028000tcp_list_scrollbar_mouseover : List scrollbar mouseover (track panel) -- current RGB: 30,30,30tcp_list_scrollbar_mouseover_mode : List scrollbar mouseover (track panel) - draw mode -- blendmode 00028000mcp_list_scrollbar : List scrollbar (mixer panel) -- current RGB: 140,140,140mcp_list_scrollbar_mode : List scrollbar (mixer panel) - draw mode -- blendmode 00028000mcp_list_scrollbar_mouseover : List scrollbar mouseover (mixer panel) -- current RGB: 64,191,159mcp_list_scrollbar_mouseover_mode : List scrollbar mouseover (mixer panel) - draw mode -- blendmode 00028000midi_rulerbg : MIDI editor ruler background -- current RGB: 186,192,192midi_rulerfg : MIDI editor ruler text -- current RGB: 55,55,


55midi_grid2 : MIDI editor grid line (start of measure) -- current RGB: 112,112,112midi_griddm2 : MIDI editor grid line (start of measure) - draw mode -- blendmode 00030000midi_grid3 : MIDI editor grid line (start of beats) -- current RGB: 129,129,129midi_griddm3 : MIDI editor grid line (start of beats) - draw mode -- blendmode 00030000midi_grid1 : MIDI editor grid line (between beats) -- current RGB: 185,185,185midi_griddm1 : MIDI editor grid line (between beats) - draw mode -- blendmode 00030000midi_trackbg1 : MIDI editor background color (naturals) -- current RGB: 234,234,234midi_trackbg2 : MIDI editor background color (sharps/flats) -- current RGB: 225,225,225midi_trackbg_outer1 : MIDI editor background color, out of bounds (naturals) -- current RGB: 216,216,216midi_trackbg_outer2 : MIDI editor background color, out of bounds (sharps/flats) -- current RGB: 200,200,200midi_selpitch1 : MIDI editor background color, selected pitch (naturals) -- current RGB: 225,209,209midi_selpitch2 : MIDI editor background color, selected pitch (sharps/flats) -- current RGB: 217,201,201midi_selbg : MIDI editor time selection color -- current RGB: 255,255,255midi_selbg_drawmode : MIDI editor time selection fill mode -- blendmode 00021001midi_gridhc : MIDI editor CC horizontal center line -- current RGB: 129,129,129midi_gridhcdm : MIDI editor CC horizontal center line - draw mode -- blendmode 00030000midi_gridh : MIDI editor CC horizontal line -- current RGB: 129,129,129midi_gridhdm : MIDI editor CC horizontal line - draw mode -- blendmode 00028000midi_ccbut : MIDI editor CC lane add/remove buttons -- current RGB: 55,55,55midi_ccbut_text : MIDI editor CC lane button text -- current RGB: 55,55,55midi_ccbut_arrow : MIDI editor CC lane button arrow -- current RGB: 55,55,55midioct : MIDI editor octave line color -- current RGB: 185,185,185midi_inline_trackbg1 : MIDI inline background color (naturals) -- current RGB: 197,197,197midi_inline_trackbg2 : MIDI inline background color (sharps/flats) -- current RGB: 181,181,181midioct_inline : MIDI inline octave line color -- current RGB: 144,144,144midi_endpt : MIDI editor end marker -- current RGB: 58,58,58midi_notebg : MIDI editor note, unselected (midi_note_colormap overrides) -- current RGB: 91,123,108midi_notefg : MIDI editor note, selected (midi_note_colormap overrides) -- current RGB: 49,49,49midi_notemute : MIDI editor note, muted, unselected (midi_note_colormap overrides) -- current RGB: 53,53,53midi_notemute_sel : MIDI editor note, muted, selected (midi_note_colormap overrides) -- current RGB: 24,24,24midi_itemctl : MIDI editor note controls -- current RGB: 197,197,197midi_ofsn : MIDI editor note (offscreen) -- current RGB: 59,59,59midi_ofsnsel : MIDI editor note (offscreen, selected) -- current RGB: 59,59,59midi_editcurs : MIDI editor cursor -- current RGB: 162,36,36midi_pkey1 : MIDI piano key color (naturals background, sharps/flats text) -- current RGB: 255,255,255midi_pkey2 : MIDI piano key color (sharps/flats background, naturals text) -- current RGB: 0,0,0midi_pkey3 : MIDI piano key color (selected) -- current RGB: 93,93,93midi_noteon_flash : MIDI piano key note-on flash -- current RGB: 64,0,0midi_leftbg : MIDI piano pane background -- current RGB: 186,192,192midifont_col_light_unsel : MIDI editor note text and control color, unselected (light) -- current RGB: 224,224,224midifont_col_dark_unsel : MIDI editor note text and control color, unselected (dark) -- current RGB: 32,32,32midifont_mode_unsel : MIDI editor note text and control mode, unselected -- blendmode 0002c000midifont_col_light : MIDI editor note text and control color (light) -- current RGB: 192,192,192midifont_col_dark : MIDI editor note text and control color (dark) -- current RGB: 64,64,64midifont_mode : MIDI editor note text and control mode -- blendmode 00030000score_bg : MIDI notation editor background -- current RGB: 255,255,255score_fg : MIDI notation editor staff/notation/text -- current RGB: 0,0,0score_sel : MIDI notation editor selected staff/notation/text -- current RGB: 0,0,255score_timesel : MIDI notation 


editor time selection -- current RGB: 255,255,224score_loop : MIDI notation editor loop points, selected pitch -- current RGB: 255,192,0midieditorlist_bg : MIDI list editor background -- current RGB: 255,255,255midieditorlist_fg : MIDI list editor text -- current RGB: 0,0,0midieditorlist_grid : MIDI list editor grid lines -- current RGB: 224,224,224midieditorlist_selbg : MIDI list editor selected row -- current RGB: 51,153,255midieditorlist_selfg : MIDI list editor selected text -- current RGB: 255,255,255midieditorlist_seliabg : MIDI list editor selected row (inactive) -- current RGB: 240,240,240midieditorlist_seliafg : MIDI list editor selected text (inactive) -- current RGB: 0,0,0midieditorlist_bg2 : MIDI list editor background (secondary) -- current RGB: 210,210,225midieditorlist_fg2 : MIDI list editor text (secondary) -- current RGB: 0,0,0midieditorlist_selbg2 : MIDI list editor selected row (secondary) -- current RGB: 35,135,240midieditorlist_selfg2 : MIDI list editor selected text (secondary) -- current RGB: 255,255,255col_explorer_sel : Media explorer selection -- current RGB: 255,255,255col_explorer_seldm : Media explorer selection mode -- blendmode 00021901col_explorer_seledge : Media explorer selection edge -- current RGB: 255,255,255docker_shadow : Tab control shadow -- current RGB: 18,26,29docker_selface : Tab control selected tab -- current RGB: 71,78,78docker_unselface : Tab control unselected tab -- current RGB: 51,51,51docker_text : Tab control text -- current RGB: 51,51,51docker_text_sel : Tab control text selected tab -- current RGB: 51,51,51docker_bg : Tab control background -- current RGB: 73,73,73windowtab_bg : Tab control background in windows -- current RGB: 73,73,73auto_item_unsel : Envelope: Unselected automation item -- current RGB: 96,96,96col_env1 : Envelope: Volume (pre-FX) -- current RGB: 0,220,128col_env2 : Envelope: Volume -- current RGB: 64,128,64env_trim_vol : Envelope: Trim Volume -- current RGB: 0,0,0col_env3 : Envelope: Pan (pre-FX) -- current RGB: 255,0,0col_env4 : Envelope: Pan -- current RGB: 255,150,0env_track_mute : Envelope: Mute -- current RGB: 192,0,0col_env5 : Envelope: Master playrate -- current RGB: 0,0,0col_env6 : Envelope: Master tempo -- current RGB: 0,255,255col_env7 : Envelope: Send volume -- current RGB: 128,0,0col_env8 : Envelope: Send pan -- current RGB: 0,128,128col_env9 : Envelope: Send volume 2 -- current RGB: 0,128,192col_env10 : Envelope: Send pan 2 -- current RGB: 0,64,0env_sends_mute : Envelope: Send mute -- current RGB: 192,192,0col_env11 : Envelope: Audio hardware output volume -- current RGB: 0,255,255col_env12 : Envelope: Audio hardware output pan -- current RGB: 255,255,0col_env13 : Envelope: FX parameter 1 -- current RGB: 128,0,255col_env14 : Envelope: FX parameter 2 -- current RGB: 64,128,128col_env15 : Envelope: FX parameter 3 -- current RGB: 0,0,255col_env16 : Envelope: FX parameter 4 -- current RGB: 255,0,128env_item_vol : Envelope: Item take volume -- current RGB: 128,0,0env_item_pan : Envelope: Item take pan -- current RGB: 0,128,128env_item_mute : Envelope: Item take mute -- current RGB: 192,192,0env_item_pitch : Envelope: Item take pitch -- current RGB: 0,255,255wiring_grid2 : Wiring: Background -- current RGB: 46,46,46wiring_grid : Wiring: Background grid lines -- current RGB: 51,51,51wiring_border : Wiring: Box border -- current RGB: 153,153,153wiring_tbg : Wiring: Box background -- current RGB: 38,38,38wiring_ticon : Wiring: Box foreground -- current RGB: 204,204,204wiring_recbg : Wiring: Record section background -- current RGB: 101,77,77wiring_recitem : Wiring: Record section foreground -- current RGB: 63,33,33wiring_media : Wiring: Media -- current RGB: 32,64,32wiring_recv : Wiring: Receives -- current RGB: 92,92,92wiring_send : Wiring: Sends -- current RGB: 92,92,92wiring_fader : Wiring: Fader -- current RGB: 128,128,192wiring_parent : Wiring: Master/Parent -- current RGB: 64,128,128wiring_parentwire_border : Wiring: Master/Parent wire border -- current RGB: 100,100,100wiring_parentwire_master : Wiring: Master/Parent to master wire -- c


urrent RGB: 192,192,192wiring_parentwire_folder : Wiring: Master/Parent to parent folder wire -- current RGB: 128,128,128wiring_pin_normal : Wiring: Pins normal -- current RGB: 192,192,192wiring_pin_connected : Wiring: Pins connected -- current RGB: 96,144,96wiring_pin_disconnected : Wiring: Pins disconnected -- current RGB: 64,32,32wiring_horz_col : Wiring: Horizontal pin connections -- current RGB: 72,72,72wiring_sendwire : Wiring: Send hanging wire -- current RGB: 128,128,128wiring_hwoutwire : Wiring: Hardware output wire -- current RGB: 128,128,128wiring_recinputwire : Wiring: Record input wire -- current RGB: 255,128,128wiring_hwout : Wiring: System hardware outputs -- current RGB: 64,64,64wiring_recinput : Wiring: System record inputs -- current RGB: 128,64,64group_0 : Group #1 -- current RGB: 255,0,0group_1 : Group #2 -- current RGB: 0,255,0group_2 : Group #3 -- current RGB: 0,0,255group_3 : Group #4 -- current RGB: 255,255,0group_4 : Group #5 -- current RGB: 255,0,255group_5 : Group #6 -- current RGB: 0,255,255group_6 : Group #7 -- current RGB: 192,0,0group_7 : Group #8 -- current RGB: 0,192,0group_8 : Group #9 -- current RGB: 0,0,192group_9 : Group #10 -- current RGB: 192,192,0group_10 : Group #11 -- current RGB: 192,0,192group_11 : Group #12 -- current RGB: 0,192,192group_12 : Group #13 -- current RGB: 128,0,0group_13 : Group #14 -- current RGB: 0,128,0group_14 : Group #15 -- current RGB: 0,0,128group_15 : Group #16 -- current RGB: 128,128,0group_16 : Group #17 -- current RGB: 128,0,128group_17 : Group #18 -- current RGB: 0,128,128group_18 : Group #19 -- current RGB: 192,128,0group_19 : Group #20 -- current RGB: 0,192,128group_20 : Group #21 -- current RGB: 0,128,192group_21 : Group #22 -- current RGB: 192,128,0group_22 : Group #23 -- current RGB: 128,0,192group_23 : Group #24 -- current RGB: 128,192,0group_24 : Group #25 -- current RGB: 64,0,0group_25 : Group #26 -- current RGB: 0,64,0group_26 : Group #27 -- current RGB: 0,0,64group_27 : Group #28 -- current RGB: 64,64,0group_28 : Group #29 -- current RGB: 64,0,64group_29 : Group #30 -- current RGB: 0,64,64group_30 : Group #31 -- current RGB: 64,0,64group_31 : Group #32 -- current RGB: 0,64,64group_32 : Group #33 -- current RGB: 128,255,255group_33 : Group #34 -- current RGB: 128,0,128group_34 : Group #35 -- current RGB: 1,255,128group_35 : Group #36 -- current RGB: 128,0,255group_36 : Group #37 -- current RGB: 1,255,255group_37 : Group #38 -- current RGB: 1,0,128group_38 : Group #39 -- current RGB: 128,255,224group_39 : Group #40 -- current RGB: 128,63,128group_40 : Group #41 -- current RGB: 32,255,128group_41 : Group #42 -- current RGB: 128,63,224group_42 : Group #43 -- current RGB: 32,255,224group_43 : Group #44 -- current RGB: 32,63,128group_44 : Group #45 -- current RGB: 128,255,192group_45 : Group #46 -- current RGB: 128,127,128group_46 : Group #47 -- current RGB: 64,255,128group_47 : Group #48 -- current RGB: 128,127,192group_48 : Group #49 -- current RGB: 64,255,192group_49 : Group #50 -- current RGB: 64,127,128group_50 : Group #51 -- current RGB: 128,127,224group_51 : Group #52 -- current RGB: 64,63,128group_52 : Group #53 -- current RGB: 32,127,128group_53 : Group #54 -- current RGB: 128,127,224group_54 : Group #55 -- current RGB: 32,255,192group_55 : Group #56 -- current RGB: 128,63,192group_56 : Group #57 -- current RGB: 128,255,160group_57 : Group #58 -- current RGB: 128,191,128group_58 : Group #59 -- current RGB: 96,255,128group_59 : Group #60 -- current RGB: 128,191,160group_60 : Group #61 -- current RGB: 96,255,160group_61 : Group #62 -- current RGB: 96,191,128group_62 : Group #63 -- current RGB: 96,255,160group_63 : Group #64 -- current RGB: 96,191,128
FUNC511 boolean reaper.SetToggleCommandState(integer section_id, integer command_id, integer state)
DESC511 Updates the toggle state of an action, returns true if succeeded. Only ReaScripts can have their toggle states changed programmatically. See RefreshToolbar2.
FUNC512 reaper.SetTrackAutomationMode(MediaTrack tr, integer mode)
DESC512 
FUNC513 reaper.SetTrackColor(MediaTrack track, integer color)
DESC513 Set the custom track color, color is OS dependent (i.e. ColorToNative(r,g,b).
FUNC514 boolean reaper.SetTrackMIDILyrics(MediaTrack track, integer flag, string str)
DESC514 Set all MIDI lyrics on the track. Lyrics will be stuffed into any MIDI items found in range. Flag is unused at present. str is passed in as beat position, tab, text, tab (example with flag=2: "1.1.2\tLyric for measure 1 beat 2\t.1.1\tLyric for measure 2 beat 1 "). See GetTrackMIDILyrics
FUNC515 boolean reaper.SetTrackMIDINoteName(integer track, integer pitch, integer chan, string name)
DESC515 channel < 0 assigns these note names to all channels.
FUNC516 boolean reaper.SetTrackMIDINoteNameEx(ReaProject proj, MediaTrack track, integer pitch, integer chan, string name)
DESC516 channel < 0 assigns note name to all channels. pitch 128 assigns name for CC0, pitch 129 for CC1, etc.
FUNC517 reaper.SetTrackSelected(MediaTrack track, boolean selected)
DESC517 
FUNC518 boolean reaper.SetTrackSendInfo_Value(MediaTrack tr, integer category, integer sendidx, string parmname, number newvalue)
DESC518 Set send/receive/hardware output numerical-value attributes, return true on success.category is <0 for receives, 0=sends, >0 for hardware outputsparameter names:B_MUTE : bool *B_PHASE : bool *, true to flip phaseB_MONO : bool *D_VOL : double *, 1.0 = +0dB etcD_PAN : double *, -1..+1D_PANLAW : double *,1.0=+0.0db, 0.5=-6dB, -1.0 = projdef etcI_SENDMODE : int *, 0=post-fader, 1=pre-fx, 2=post-fx (deprecated), 3=post-fxI_AUTOMODE : int * : automation mode (-1=use track automode, 0=trim/off, 1=read, 2=touch, 3=write, 4=latch)I_SRCCHAN : int *, index,&1024=mono, -1 for noneI_DSTCHAN : int *, index, &1024=mono, otherwise stereo pair, hwout:&512=rearouteI_MIDIFLAGS : int *, low 5 bits=source channel 0=all, 1-16, next 5 bits=dest channel, 0=orig, 1-16=chanSee CreateTrackSend, RemoveTrackSend, GetTrackNumSends.
FUNC519 boolean reaper.SetTrackSendUIPan(MediaTrack track, integer send_idx, number pan, integer isend)
DESC519 send_idx<0 for receives, >=0 for hw ouputs, >=nb_of_hw_ouputs for sends. isend=1 for end of edit, -1 for an instant edit (such as reset), 0 for normal tweak.
FUNC520 boolean reaper.SetTrackSendUIVol(MediaTrack track, integer send_idx, number vol, integer isend)
DESC520 send_idx<0 for receives, >=0 for hw ouputs, >=nb_of_hw_ouputs for sends. isend=1 for end of edit, -1 for an instant edit (such as reset), 0 for normal tweak.
FUNC521 boolean reaper.SetTrackStateChunk(MediaTrack track, string str, boolean isundo)
DESC521 Sets the RPPXML state of a track, returns true if successful. Undo flag is a performance/caching hint.
FUNC522 reaper.ShowActionList(KbdSectionInfo caller, HWND callerWnd)
DESC522 
FUNC523 reaper.ShowConsoleMsg(string msg)
DESC523 Show a message to the user (also useful for debugging). Send "\n" for newline, "" to clear the console. See ClearConsole
FUNC524 integer reaper.ShowMessageBox(string msg, string title, integer type)
DESC524 type 0=OK,1=OKCANCEL,2=ABORTRETRYIGNORE,3=YESNOCANCEL,4=YESNO,5=RETRYCANCEL : ret 1=OK,2=CANCEL,3=ABORT,4=RETRY,5=IGNORE,6=YES,7=NO
FUNC525 reaper.ShowPopupMenu(string name, integer x, integer y, HWND hwndParent, identifier ctx, integer ctx2, integer ctx3)
DESC525 shows a context menu, valid names include: track_input, track_panel, track_area, track_routing, item, ruler, envelope, envelope_point, envelope_item. ctxOptional can be a track pointer for track_*, item pointer for item* (but is optional). for envelope_point, ctx2Optional has point index, ctx3Optional has item index (0=main envelope, 1=first AI). for envelope_item, ctx2Optional has AI index (1=first AI)
FUNC526 number reaper.SLIDER2DB(number y)
DESC526 
FUNC527 number reaper.SnapToGrid(ReaProject project, number time_pos)
DESC527 
FUNC528 reaper.SoloAllTracks(integer solo)
DESC528 solo=2 for SIP
FUNC529 HWND reaper.Splash_GetWnd()
DESC529 gets the splash window, in case you want to display a message over it. Returns NULL when the sphah window is not displayed.
FUNC530 MediaItem reaper.SplitMediaItem(MediaItem item, number position)
DESC530 the original item becomes the left-hand split, the function returns the right-hand split (or NULL if the split failed)
FUNC531 string gGUID = reaper.stringToGuid(string str, string gGUID)
DESC531 
FUNC532 reaper.StuffMIDIMessage(integer mode, integer msg1, integer msg2, integer msg3)
DESC532 Stuffs a 3 byte MIDI message into either the Virtual MIDI Keyboard queue, or the MIDI-as-control input queue, or sends to a MIDI hardware output. mode=0 for VKB, 1 for control (actions map etc), 2 for VKB-on-current-channel; 16 for external MIDI device 0, 17 for external MIDI device 1, etc; see GetNumMIDIOutputs, GetMIDIOutputName.
FUNC533 integer reaper.TakeFX_AddByName(MediaItem_Take take, string fxname, integer instantiate)
DESC533 Adds or queries the position of a named FX in a take. See TrackFX_AddByName() for information on fxname and instantiate.
FUNC534 reaper.TakeFX_CopyToTake(MediaItem_Take src_take, integer src_fx, MediaItem_Take dest_take, integer dest_fx, boolean is_move)
DESC534 Copies (or moves) FX from src_take to dest_take. Can be used with src_track=dest_track to reorder.
FUNC535 reaper.TakeFX_CopyToTrack(MediaItem_Take src_take, integer src_fx, MediaTrack dest_track, integer dest_fx, boolean is_move)
DESC535 Copies (or moves) FX from src_take to dest_track. dest_fx can have 0x1000000 set to reference input FX.
FUNC536 boolean reaper.TakeFX_Delete(MediaItem_Take take, integer fx)
DESC536 Remove a FX from take chain (returns true on success)
FUNC537 boolean reaper.TakeFX_EndParamEdit(MediaItem_Take take, integer fx, integer param)
DESC537 
FUNC538 boolean retval, string buf = reaper.TakeFX_FormatParamValue(MediaItem_Take take, integer fx, integer param, number val, string buf)
DESC538 Note: only works with FX that support Cockos VST extensions.
FUNC539 boolean retval, string buf = reaper.TakeFX_FormatParamValueNormalized(MediaItem_Take take, integer fx, integer param, number value, string buf)
DESC539 Note: only works with FX that support Cockos VST extensions.
FUNC540 integer reaper.TakeFX_GetChainVisible(MediaItem_Take take)
DESC540 returns index of effect visible in chain, or -1 for chain hidden, or -2 for chain visible but no effect selected
FUNC541 integer reaper.TakeFX_GetCount(MediaItem_Take take)
DESC541 
FUNC542 boolean reaper.TakeFX_GetEnabled(MediaItem_Take take, integer fx)
DESC542 See TakeFX_SetEnabled
FUNC543 TrackEnvelope reaper.TakeFX_GetEnvelope(MediaItem_Take take, integer fxindex, integer parameterindex, boolean create)
DESC543 Returns the FX parameter envelope. If the envelope does not exist and create=true, the envelope will be created.
FUNC544 HWND reaper.TakeFX_GetFloatingWindow(MediaItem_Take take, integer index)
DESC544 returns HWND of floating window for effect index, if any
FUNC545 boolean retval, string buf = reaper.TakeFX_GetFormattedParamValue(MediaItem_Take take, integer fx, integer param, string buf)
DESC545 
FUNC546 string GUID = reaper.TakeFX_GetFXGUID(MediaItem_Take take, integer fx)
DESC546 
FUNC547 boolean retval, string buf = reaper.TakeFX_GetFXName(MediaItem_Take take, integer fx, string buf)
DESC547 
FUNC548 integer retval, optional number inputPins, optional number outputPins = reaper.TakeFX_GetIOSize(MediaItem_Take take, integer fx)
DESC548 sets the number of input/output pins for FX if available, returns plug-in type or -1 on error
FUNC549 boolean retval, string buf = reaper.TakeFX_GetNamedConfigParm(MediaItem_Take take, integer fx, string parmname)
DESC549 gets plug-in specific named configuration value (returns true on success). see TrackFX_GetNamedConfigParm
FUNC550 integer reaper.TakeFX_GetNumParams(MediaItem_Take take, integer fx)
DESC550 
FUNC551 boolean reaper.TakeFX_GetOffline(MediaItem_Take take, integer fx)
DESC551 See TakeFX_SetOffline
FUNC552 boolean reaper.TakeFX_GetOpen(MediaItem_Take take, integer fx)
DESC552 Returns true if this FX UI is open in the FX chain window or a floating window. See TakeFX_SetOpen
FUNC553 number retval, number minval, number maxval = reaper.TakeFX_GetParam(MediaItem_Take take, integer fx, integer param)
DESC553 
FUNC554 boolean retval, number step, number smallstep, number largestep, boolean istoggle = reaper.TakeFX_GetParameterStepSizes(MediaItem_Take take, integer fx, integer param)
DESC554 
FUNC555 number retval, number minval, number maxval, number midval = reaper.TakeFX_GetParamEx(MediaItem_Take take, integer fx, integer param)
DESC555 
FUNC556 boolean retval, string buf = reaper.TakeFX_GetParamName(MediaItem_Take take, integer fx, integer param, string buf)
DESC556 
FUNC557 number reaper.TakeFX_GetParamNormalized(MediaItem_Take take, integer fx, integer param)
DESC557 
FUNC558 integer retval, optional number high32 = reaper.TakeFX_GetPinMappings(MediaItem_Take tr, integer fx, integer isoutput, integer pin)
DESC558 gets the effective channel mapping bitmask for a particular pin. high32OutOptional will be set to the high 32 bits
FUNC559 boolean retval, string presetname = reaper.TakeFX_GetPreset(MediaItem_Take take, integer fx, string presetname)
DESC559 Get the name of the preset currently showing in the REAPER dropdown, or the full path to a factory preset file for VST3 plug-ins (.vstpreset). Returns false if the current FX parameters do not exactly match the preset (in other words, if the user loaded the preset but moved the knobs afterward). See TakeFX_SetPreset.
FUNC560 integer retval, number numberOfPresets = reaper.TakeFX_GetPresetIndex(MediaItem_Take take, integer fx)
DESC560 Returns current preset index, or -1 if error. numberOfPresetsOut will be set to total number of presets available. See TakeFX_SetPresetByIndex
FUNC561 string fn = reaper.TakeFX_GetUserPresetFilename(MediaItem_Take take, integer fx, string fn)
DESC561 
FUNC562 boolean reaper.TakeFX_NavigatePresets(MediaItem_Take take, integer fx, integer presetmove)
DESC562 presetmove==1 activates the next preset, presetmove==-1 activates the previous preset, etc.
FUNC563 reaper.TakeFX_SetEnabled(MediaItem_Take take, integer fx, boolean enabled)
DESC563 See TakeFX_GetEnabled
FUNC564 boolean reaper.TakeFX_SetNamedConfigParm(MediaItem_Take take, integer fx, string parmname, string value)
DESC564 gets plug-in specific named configuration value (returns true on success)
FUNC565 reaper.TakeFX_SetOffline(MediaItem_Take take, integer fx, boolean offline)
DESC565 See TakeFX_GetOffline
FUNC566 reaper.TakeFX_SetOpen(MediaItem_Take take, integer fx, boolean open)
DESC566 Open this FX UI. See TakeFX_GetOpen
FUNC567 boolean reaper.TakeFX_SetParam(MediaItem_Take take, integer fx, integer param, number val)
DESC567 
FUNC568 boolean reaper.TakeFX_SetParamNormalized(MediaItem_Take take, integer fx, integer param, number value)
DESC568 
FUNC569 boolean reaper.TakeFX_SetPinMappings(MediaItem_Take tr, integer fx, integer isoutput, integer pin, integer low32bits, integer hi32bits)
DESC569 sets the channel mapping bitmask for a particular pin. returns false if unsupported (not all types of plug-ins support this capability)
FUNC570 boolean reaper.TakeFX_SetPreset(MediaItem_Take take, integer fx, string presetname)
DESC570 Activate a preset with the name shown in the REAPER dropdown. Full paths to .vstpreset files are also supported for VST3 plug-ins. See TakeFX_GetPreset.
FUNC571 boolean reaper.TakeFX_SetPresetByIndex(MediaItem_Take take, integer fx, integer idx)
DESC571 Sets the preset idx, or the factory preset (idx==-2), or the default user preset (idx==-1). Returns true on success. See TakeFX_GetPresetIndex.
FUNC572 reaper.TakeFX_Show(MediaItem_Take take, integer index, integer showFlag)
DESC572 showflag=0 for hidechain, =1 for show chain(index valid), =2 for hide floating window(index valid), =3 for show floating window (index valid)
FUNC573 boolean reaper.TakeIsMIDI(MediaItem_Take take)
DESC573 Returns true if the active take contains MIDI.
FUNC574 boolean retval, string name = reaper.ThemeLayout_GetLayout(string section, integer idx)
DESC574 Gets theme layout information. section can be 'global' for global layout override, 'seclist' to enumerate a list of layout sections, otherwise a layout section such as 'mcp', 'tcp', 'trans', etc. idx can be -1 to query the current value, -2 to get the description of the section (if not global), -3 will return the current context DPI-scaling (256=normal, 512=retina, etc), or 0..x. returns false if failed.
FUNC575 string retval, optional string desc, optional number value, optional number defValue, optional number minValue, optional number maxValue = reaper.ThemeLayout_GetParameter(integer wp)
DESC575 returns theme layout parameter. return value is cfg-name, or nil/empty if out of range.
FUNC576 reaper.ThemeLayout_RefreshAll()
DESC576 Refreshes all layouts
FUNC577 boolean reaper.ThemeLayout_SetLayout(string section, string layout)
DESC577 Sets theme layout override for a particular section -- section can be 'global' or 'mcp' etc. If setting global layout, prefix a ! to the layout string to clear any per-layout overrides. Returns false if failed.
FUNC578 boolean reaper.ThemeLayout_SetParameter(integer wp, integer value, boolean persist)
DESC578 sets theme layout parameter to value. persist=true in order to have change loaded on next theme load. note that the caller should update layouts via ??? to make changes visible.
FUNC579 number reaper.time_precise()
DESC579 Gets a precise system timestamp in seconds
FUNC580 number reaper.TimeMap2_beatsToTime(ReaProject proj, number tpos, optional number measuresIn)
DESC580 convert a beat position (or optionally a beats+measures if measures is non-NULL) to time.
FUNC581 number reaper.TimeMap2_GetDividedBpmAtTime(ReaProject proj, number time)
DESC581 get the effective BPM at the time (seconds) position (i.e. 2x in /8 signatures)
FUNC582 number reaper.TimeMap2_GetNextChangeTime(ReaProject proj, number time)
DESC582 when does the next time map (tempo or time sig) change occur
FUNC583 number reaper.TimeMap2_QNToTime(ReaProject proj, number qn)
DESC583 converts project QN position to time.
FUNC584 number retval, optional number measures, optional number cml, optional number fullbeats, optional number cdenom = reaper.TimeMap2_timeToBeats(ReaProject proj, number tpos)
DESC584 convert a time into beats.if measures is non-NULL, measures will be set to the measure count, return value will be beats since measure.if cml is non-NULL, will be set to current measure length in beats (i.e. time signature numerator)if fullbeats is non-NULL, and measures is non-NULL, fullbeats will get the full beat count (same value returned if measures is NULL).if cdenom is non-NULL, will be set to the current time signature denominator.
FUNC585 number reaper.TimeMap2_timeToQN(ReaProject proj, number tpos)
DESC585 converts project time position to QN position.
FUNC586 number retval, optional boolean dropFrame = reaper.TimeMap_curFrameRate(ReaProject proj)
DESC586 Gets project framerate, and optionally whether it is drop-frame timecode
FUNC587 number reaper.TimeMap_GetDividedBpmAtTime(number time)
DESC587 get the effective BPM at the time (seconds) position (i.e. 2x in /8 signatures)
FUNC588 number retval, number qn_start, number qn_end, number timesig_num, number timesig_denom, number tempo = reaper.TimeMap_GetMeasureInfo(ReaProject proj, integer measure)
DESC588 Get the QN position and time signature information for the start of a measure. Return the time in seconds of the measure start.
FUNC589 integer retval, string pattern = reaper.TimeMap_GetMetronomePattern(ReaProject proj, number time, string pattern)
DESC589 Fills in a string representing the active metronome pattern. For example, in a 7/8 measure divided 3+4, the pattern might be "1221222". The length of the string is the time signature numerator, and the function returns the time signature denominator.
FUNC590 number timesig_num, number timesig_denom, number tempo = reaper.TimeMap_GetTimeSigAtTime(ReaProject proj, number time)
DESC590 get the effective time signature and tempo
FUNC591 integer retval, optional number qnMeasureStart, optional number qnMeasureEnd = reaper.TimeMap_QNToMeasures(ReaProject proj, number qn)
DESC591 Find which measure the given QN position falls in.
FUNC592 number reaper.TimeMap_QNToTime(number qn)
DESC592 converts project QN position to time.
FUNC593 number reaper.TimeMap_QNToTime_abs(ReaProject proj, number qn)
DESC593 Converts project quarter note count (QN) to time. QN is counted from the start of the project, regardless of any partial measures. See TimeMap2_QNToTime
FUNC594 number reaper.TimeMap_timeToQN(number tpos)
DESC594 converts project QN position to time.
FUNC595 number reaper.TimeMap_timeToQN_abs(ReaProject proj, number tpos)
DESC595 Converts project time position to quarter note count (QN). QN is counted from the start of the project, regardless of any partial measures. See TimeMap2_timeToQN
FUNC596 boolean reaper.ToggleTrackSendUIMute(MediaTrack track, integer send_idx)
DESC596 send_idx<0 for receives, >=0 for hw ouputs, >=nb_of_hw_ouputs for sends.
FUNC597 number reaper.Track_GetPeakHoldDB(MediaTrack track, integer channel, boolean clear)
DESC597 Returns meter hold state, in dB*0.01 (0 = +0dB, -0.01 = -1dB, 0.02 = +2dB, etc). If clear is set, clears the meter hold. If master track and channel==1024 or channel==1025, returns/clears RMS maximum state.
FUNC598 number reaper.Track_GetPeakInfo(MediaTrack track, integer channel)
DESC598 Returns peak meter value (1.0=+0dB, 0.0=-inf) for channel. If master track and channel==1024 or channel==1025, returns RMS meter value. if master track and channel==2048 or channel=2049, returns RMS meter hold value.
FUNC599 reaper.TrackCtl_SetToolTip(string fmt, integer xpos, integer ypos, boolean topmost)
DESC599 displays tooltip at location, or removes if empty string
FUNC600 integer reaper.TrackFX_AddByName(MediaTrack track, string fxname, boolean recFX, integer instantiate)
DESC600 Adds or queries the position of a named FX from the track FX chain (recFX=false) or record input FX/monitoring FX (recFX=true, monitoring FX are on master track). Specify a negative value for instantiate to always create a new effect, 0 to only query the first instance of an effect, or a positive value to add an instance if one is not found. If instantiate is <= -1000, it is used for the insertion position (-1000 is first item in chain, -1001 is second, etc). fxname can have prefix to specify type: VST3:,VST2:,VST:,AU:,JS:, or DX:, or FXADD: which adds selected items from the currently-open FX browser, FXADD:2 to limit to 2 FX added, or FXADD:2e to only succeed if exactly 2 FX are selected. Returns -1 on failure or the new position in chain on success.
FUNC601 reaper.TrackFX_CopyToTake(MediaTrack src_track, integer src_fx, MediaItem_Take dest_take, integer dest_fx, boolean is_move)
DESC601 Copies (or moves) FX from src_track to dest_take. src_fx can have 0x1000000 set to reference input FX.
FUNC602 reaper.TrackFX_CopyToTrack(MediaTrack src_track, integer src_fx, MediaTrack dest_track, integer dest_fx, boolean is_move)
DESC602 Copies (or moves) FX from src_track to dest_track. Can be used with src_track=dest_track to reorder, FX indices have 0x1000000 set to reference input FX.
FUNC603 boolean reaper.TrackFX_Delete(MediaTrack track, integer fx)
DESC603 Remove a FX from track chain (returns true on success)
FUNC604 boolean reaper.TrackFX_EndParamEdit(MediaTrack track, integer fx, integer param)
DESC604 
FUNC605 boolean retval, string buf = reaper.TrackFX_FormatParamValue(MediaTrack track, integer fx, integer param, number val, string buf)
DESC605 Note: only works with FX that support Cockos VST extensions.
FUNC606 boolean retval, string buf = reaper.TrackFX_FormatParamValueNormalized(MediaTrack track, integer fx, integer param, number value, string buf)
DESC606 Note: only works with FX that support Cockos VST extensions.
FUNC607 integer reaper.TrackFX_GetByName(MediaTrack track, string fxname, boolean instantiate)
DESC607 Get the index of the first track FX insert that matches fxname. If the FX is not in the chain and instantiate is true, it will be inserted. See TrackFX_GetInstrument, TrackFX_GetEQ. Deprecated in favor of TrackFX_AddByName.
FUNC608 integer reaper.TrackFX_GetChainVisible(MediaTrack track)
DESC608 returns index of effect visible in chain, or -1 for chain hidden, or -2 for chain visible but no effect selected
FUNC609 integer reaper.TrackFX_GetCount(MediaTrack track)
DESC609 
FUNC610 boolean reaper.TrackFX_GetEnabled(MediaTrack track, integer fx)
DESC610 See TrackFX_SetEnabled
FUNC611 integer reaper.TrackFX_GetEQ(MediaTrack track, boolean instantiate)
DESC611 Get the index of ReaEQ in the track FX chain. If ReaEQ is not in the chain and instantiate is true, it will be inserted. See TrackFX_GetInstrument, TrackFX_GetByName.
FUNC612 boolean reaper.TrackFX_GetEQBandEnabled(MediaTrack track, integer fxidx, integer bandtype, integer bandidx)
DESC612 Returns true if the EQ band is enabled.Returns false if the band is disabled, or if track/fxidx is not ReaEQ.Bandtype: 0=lhipass, 1=loshelf, 2=band, 3=notch, 4=hishelf, 5=lopass.Bandidx: 0=first band matching bandtype, 1=2nd band matching bandtype, etc.See TrackFX_GetEQ, TrackFX_GetEQParam, TrackFX_SetEQParam, TrackFX_SetEQBandEnabled.
FUNC613 boolean retval, number bandtype, number bandidx, number paramtype, number normval = reaper.TrackFX_GetEQParam(MediaTrack track, integer fxidx, integer paramidx)
DESC613 Returns false if track/fxidx is not ReaEQ.Bandtype: -1=master gain, 0=lhipass, 1=loshelf, 2=band, 3=notch, 4=hishelf, 5=lopass.Bandidx (ignored for master gain): 0=first band matching bandtype, 1=2nd band matching bandtype, etc.Paramtype (ignored for master gain): 0=freq, 1=gain, 2=Q.See TrackFX_GetEQ, TrackFX_SetEQParam, TrackFX_GetEQBandEnabled, TrackFX_SetEQBandEnabled.
FUNC614 HWND reaper.TrackFX_GetFloatingWindow(MediaTrack track, integer index)
DESC614 returns HWND of floating window for effect index, if any
FUNC615 boolean retval, string buf = reaper.TrackFX_GetFormattedParamValue(MediaTrack track, integer fx, integer param, string buf)
DESC615 
FUNC616 string GUID = reaper.TrackFX_GetFXGUID(MediaTrack track, integer fx)
DESC616 
FUNC617 boolean retval, string buf = reaper.TrackFX_GetFXName(MediaTrack track, integer fx, string buf)
DESC617 
FUNC618 integer reaper.TrackFX_GetInstrument(MediaTrack track)
DESC618 Get the index of the first track FX insert that is a virtual instrument, or -1 if none. See TrackFX_GetEQ, TrackFX_GetByName.
FUNC619 integer retval, optional number inputPins, optional number outputPins = reaper.TrackFX_GetIOSize(MediaTrack track, integer fx)
DESC619 sets the number of input/output pins for FX if available, returns plug-in type or -1 on error
FUNC620 boolean retval, string buf = reaper.TrackFX_GetNamedConfigParm(MediaTrack track, integer fx, string parmname)
DESC620 gets plug-in specific named configuration value (returns true on success). Special values: 'pdc' returns PDC latency. 'in_pin_0' returns name of first input pin (if available), 'out_pin_0' returns name of first output pin (if available), etc.
FUNC621 integer reaper.TrackFX_GetNumParams(MediaTrack track, integer fx)
DESC621 
FUNC622 boolean reaper.TrackFX_GetOffline(MediaTrack track, integer fx)
DESC622 See TrackFX_SetOffline
FUNC623 boolean reaper.TrackFX_GetOpen(MediaTrack track, integer fx)
DESC623 Returns true if this FX UI is open in the FX chain window or a floating window. See TrackFX_SetOpen
FUNC624 number retval, number minval, number maxval = reaper.TrackFX_GetParam(MediaTrack track, integer fx, integer param)
DESC624 
FUNC625 boolean retval, number step, number smallstep, number largestep, boolean istoggle = reaper.TrackFX_GetParameterStepSizes(MediaTrack track, integer fx, integer param)
DESC625 
FUNC626 number retval, number minval, number maxval, number midval = reaper.TrackFX_GetParamEx(MediaTrack track, integer fx, integer param)
DESC626 
FUNC627 boolean retval, string buf = reaper.TrackFX_GetParamName(MediaTrack track, integer fx, integer param, string buf)
DESC627 
FUNC628 number reaper.TrackFX_GetParamNormalized(MediaTrack track, integer fx, integer param)
DESC628 
FUNC629 integer retval, optional number high32 = reaper.TrackFX_GetPinMappings(MediaTrack tr, integer fx, integer isoutput, integer pin)
DESC629 gets the effective channel mapping bitmask for a particular pin. high32OutOptional will be set to the high 32 bits
FUNC630 boolean retval, string presetname = reaper.TrackFX_GetPreset(MediaTrack track, integer fx, string presetname)
DESC630 Get the name of the preset currently showing in the REAPER dropdown, or the full path to a factory preset file for VST3 plug-ins (.vstpreset). Returns false if the current FX parameters do not exactly match the preset (in other words, if the user loaded the preset but moved the knobs afterward). See TrackFX_SetPreset.
FUNC631 integer retval, number numberOfPresets = reaper.TrackFX_GetPresetIndex(MediaTrack track, integer fx)
DESC631 Returns current preset index, or -1 if error. numberOfPresetsOut will be set to total number of presets available. See TrackFX_SetPresetByIndex
FUNC632 integer reaper.TrackFX_GetRecChainVisible(MediaTrack track)
DESC632 returns index of effect visible in record input chain, or -1 for chain hidden, or -2 for chain visible but no effect selected
FUNC633 integer reaper.TrackFX_GetRecCount(MediaTrack track)
DESC633 returns count of record input FX. To access record input FX, use a FX indices [0x1000000..0x1000000+n). On the master track, this accesses monitoring FX rather than record input FX.
FUNC634 string fn = reaper.TrackFX_GetUserPresetFilename(MediaTrack track, integer fx, string fn)
DESC634 
FUNC635 boolean reaper.TrackFX_NavigatePresets(MediaTrack track, integer fx, integer presetmove)
DESC635 presetmove==1 activates the next preset, presetmove==-1 activates the previous preset, etc.
FUNC636 reaper.TrackFX_SetEnabled(MediaTrack track, integer fx, boolean enabled)
DESC636 See TrackFX_GetEnabled
FUNC637 boolean reaper.TrackFX_SetEQBandEnabled(MediaTrack track, integer fxidx, integer bandtype, integer bandidx, boolean enable)
DESC637 Enable or disable a ReaEQ band.Returns false if track/fxidx is not ReaEQ.Bandtype: 0=lhipass, 1=loshelf, 2=band, 3=notch, 4=hishelf, 5=lopass.Bandidx: 0=first band matching bandtype, 1=2nd band matching bandtype, etc.See TrackFX_GetEQ, TrackFX_GetEQParam, TrackFX_SetEQParam, TrackFX_GetEQBandEnabled.
FUNC638 boolean reaper.TrackFX_SetEQParam(MediaTrack track, integer fxidx, integer bandtype, integer bandidx, integer paramtype, number val, boolean isnorm)
DESC638 Returns false if track/fxidx is not ReaEQ. Targets a band matching bandtype.Bandtype: -1=master gain, 0=lhipass, 1=loshelf, 2=band, 3=notch, 4=hishelf, 5=lopass.Bandidx (ignored for master gain): 0=target first band matching bandtype, 1=target 2nd band matching bandtype, etc.Paramtype (ignored for master gain): 0=freq, 1=gain, 2=Q.See TrackFX_GetEQ, TrackFX_GetEQParam, TrackFX_GetEQBandEnabled, TrackFX_SetEQBandEnabled.
FUNC639 boolean reaper.TrackFX_SetNamedConfigParm(MediaTrack track, integer fx, string parmname, string value)
DESC639 sets plug-in specific named configuration value (returns true on success)
FUNC640 reaper.TrackFX_SetOffline(MediaTrack track, integer fx, boolean offline)
DESC640 See TrackFX_GetOffline
FUNC641 reaper.TrackFX_SetOpen(MediaTrack track, integer fx, boolean open)
DESC641 Open this FX UI. See TrackFX_GetOpen
FUNC642 boolean reaper.TrackFX_SetParam(MediaTrack track, integer fx, integer param, number val)
DESC642 
FUNC643 boolean reaper.TrackFX_SetParamNormalized(MediaTrack track, integer fx, integer param, number value)
DESC643 
FUNC644 boolean reaper.TrackFX_SetPinMappings(MediaTrack tr, integer fx, integer isoutput, integer pin, integer low32bits, integer hi32bits)
DESC644 sets the channel mapping bitmask for a particular pin. returns false if unsupported (not all types of plug-ins support this capability)
FUNC645 boolean reaper.TrackFX_SetPreset(MediaTrack track, integer fx, string presetname)
DESC645 Activate a preset with the name shown in the REAPER dropdown. Full paths to .vstpreset files are also supported for VST3 plug-ins. See TrackFX_GetPreset.
FUNC646 boolean reaper.TrackFX_SetPresetByIndex(MediaTrack track, integer fx, integer idx)
DESC646 Sets the preset idx, or the factory preset (idx==-2), or the default user preset (idx==-1). Returns true on success. See TrackFX_GetPresetIndex.
FUNC647 reaper.TrackFX_Show(MediaTrack track, integer index, integer showFlag)
DESC647 showflag=0 for hidechain, =1 for show chain(index valid), =2 for hide floating window(index valid), =3 for show floating window (index valid)
FUNC648 reaper.TrackList_AdjustWindows(boolean isMinor)
DESC648 
FUNC649 reaper.TrackList_UpdateAllExternalSurfaces()
DESC649 
FUNC650 reaper.Undo_BeginBlock()
DESC650 call to start a new block
FUNC651 reaper.Undo_BeginBlock2(ReaProject proj)
DESC651 call to start a new block
FUNC652 string reaper.Undo_CanRedo2(ReaProject proj)
DESC652 returns string of next action,if able,NULL if not
FUNC653 string reaper.Undo_CanUndo2(ReaProject proj)
DESC653 returns string of last action,if able,NULL if not
FUNC654 integer reaper.Undo_DoRedo2(ReaProject proj)
DESC654 nonzero if success
FUNC655 integer reaper.Undo_DoUndo2(ReaProject proj)
DESC655 nonzero if success
FUNC656 reaper.Undo_EndBlock(string descchange, integer extraflags)
DESC656 call to end the block,with extra flags if any,and a description
FUNC657 reaper.Undo_EndBlock2(ReaProject proj, string descchange, integer extraflags)
DESC657 call to end the block,with extra flags if any,and a description
FUNC658 reaper.Undo_OnStateChange(string descchange)
DESC658 limited state change to items
FUNC659 reaper.Undo_OnStateChange2(ReaProject proj, string descchange)
DESC659 limited state change to items
FUNC660 reaper.Undo_OnStateChange_Item(ReaProject proj, string name, MediaItem item)
DESC660 
FUNC661 reaper.Undo_OnStateChangeEx(string descchange, integer whichStates, integer trackparm)
DESC661 trackparm=-1 by default,or if updating one fx chain,you can specify track index
FUNC662 reaper.Undo_OnStateChangeEx2(ReaProject proj, string descchange, integer whichStates, integer trackparm)
DESC662 trackparm=-1 by default,or if updating one fx chain,you can specify track index
FUNC663 reaper.UpdateArrange()
DESC663 Redraw the arrange view
FUNC664 reaper.UpdateItemInProject(MediaItem item)
DESC664 
FUNC665 reaper.UpdateTimeline()
DESC665 Redraw the arrange view and ruler
FUNC666 boolean reaper.ValidatePtr(identifier pointer, string ctypename)
DESC666 see ValidatePtr2
FUNC667 boolean reaper.ValidatePtr2(ReaProject proj, identifier pointer, string ctypename)
DESC667 Return true if the pointer is a valid object of the right type in proj (proj is ignored if pointer is itself a project). Supported types are: ReaProject*, MediaTrack*, MediaItem*, MediaItem_Take*, TrackEnvelope* and PCM_source*.
FUNC668 reaper.ViewPrefs(integer page, string pageByName)
DESC668 Opens the prefs to a page, use pageByName if page is 0.
FUNC669 BR_Envelope reaper.BR_EnvAlloc(TrackEnvelope envelope, boolean takeEnvelopesUseProjectTime)
DESC669 [BR] Allocate envelope object from track or take envelope pointer. Always call BR_EnvFree when done to release the object and commit changes if needed.takeEnvelopesUseProjectTime: take envelope points' positions are counted from take position, not project start time. If you want to work with project time instead, pass this as true.For further manipulation see BR_EnvCountPoints, BR_EnvDeletePoint, BR_EnvFind, BR_EnvFindNext, BR_EnvFindPrevious, BR_EnvGetParentTake, BR_EnvGetParentTrack, BR_EnvGetPoint, BR_EnvGetProperties, BR_EnvSetPoint, BR_EnvSetProperties, BR_EnvValueAtPos.
FUNC670 integer reaper.BR_EnvCountPoints(BR_Envelope envelope)
DESC670 [BR] Count envelope points in the envelope object allocated with BR_EnvAlloc.
FUNC671 boolean reaper.BR_EnvDeletePoint(BR_Envelope envelope, integer id)
DESC671 [BR] Delete envelope point by index (zero-based) in the envelope object allocated with BR_EnvAlloc. Returns true on success.
FUNC672 integer reaper.BR_EnvFind(BR_Envelope envelope, number position, number delta)
DESC672 [BR] Find envelope point at time position in the envelope object allocated with BR_EnvAlloc. Pass delta > 0 to search surrounding range - in that case the closest point to position within delta will be searched for. Returns envelope point id (zero-based) on success or -1 on failure.
FUNC673 integer reaper.BR_EnvFindNext(BR_Envelope envelope, number position)
DESC673 [BR] Find next envelope point after time position in the envelope object allocated with BR_EnvAlloc. Returns envelope point id (zero-based) on success or -1 on failure.
FUNC674 integer reaper.BR_EnvFindPrevious(BR_Envelope envelope, number position)
DESC674 [BR] Find previous envelope point before time position in the envelope object allocated with BR_EnvAlloc. Returns envelope point id (zero-based) on success or -1 on failure.
FUNC675 boolean reaper.BR_EnvFree(BR_Envelope envelope, boolean commit)
DESC675 [BR] Free envelope object allocated with BR_EnvAlloc and commit changes if needed. Returns true if changes were committed successfully. Note that when envelope object wasn't modified nothing will get committed even if commit = true - in that case function returns false.
FUNC676 MediaItem_Take reaper.BR_EnvGetParentTake(BR_Envelope envelope)
DESC676 [BR] If envelope object allocated with BR_EnvAlloc is take envelope, returns parent media item take, otherwise NULL.
FUNC677 MediaItem reaper.BR_EnvGetParentTrack(BR_Envelope envelope)
DESC677 [BR] Get parent track of envelope object allocated with BR_EnvAlloc. If take envelope, returns NULL.
FUNC678 boolean retval, number position, number value, number shape, boolean selected, number bezier = reaper.BR_EnvGetPoint(BR_Envelope envelope, integer id)
DESC678 [BR] Get envelope point by id (zero-based) from the envelope object allocated with BR_EnvAlloc. Returns true on success.
FUNC679 boolean active, boolean visible, boolean armed, boolean inLane, number laneHeight, number defaultShape, number minValue, number maxValue, number centerValue, number type, boolean faderScaling = reaper.BR_EnvGetProperties(BR_Envelope envelope)
DESC679 [BR] Get envelope properties for the envelope object allocated with BR_EnvAlloc.active: true if envelope is activevisible: true if envelope is visiblearmed: true if envelope is armedinLane: true if envelope has it's own envelope lanelaneHeight: envelope lane override height. 0 for none, otherwise size in pixelsdefaultShape: default point shape: 0->Linear, 1->Square, 2->Slow start/end, 3->Fast start, 4->Fast end, 5->BezierminValue: minimum envelope valuemaxValue: maximum envelope valuetype: envelope type: 0->Volume, 1->Volume (Pre-FX), 2->Pan, 3->Pan (Pre-FX), 4->Width, 5->Width (Pre-FX), 6->Mute, 7->Pitch, 8->Playrate, 9->Tempo map, 10->ParameterfaderScaling: true if envelope uses fader scaling
FUNC680 boolean reaper.BR_EnvSetPoint(BR_Envelope envelope, integer id, number position, number value, integer shape, boolean selected, number bezier)
DESC680 [BR] Set envelope point by id (zero-based) in the envelope object allocated with BR_EnvAlloc. To create point instead, pass id = -1. Note that if new point is inserted or existing point's time position is changed, points won't automatically get sorted. To do that, see BR_EnvSortPoints.Returns true on success.
FUNC681 reaper.BR_EnvSetProperties(BR_Envelope envelope, boolean active, boolean visible, boolean armed, boolean inLane, integer laneHeight, integer defaultShape, boolean faderScaling)
DESC681 [BR] Set envelope properties for the envelope object allocated with BR_EnvAlloc. For parameter description see BR_EnvGetProperties.
FUNC682 reaper.BR_EnvSortPoints(BR_Envelope envelope)
DESC682 [BR] Sort envelope points by position. The only reason to call this is if sorted points are explicitly needed after editing them with BR_EnvSetPoint. Note that you do not have to call this before doing BR_EnvFree since it does handle unsorted points too.
FUNC683 number reaper.BR_EnvValueAtPos(BR_Envelope envelope, number position)
DESC683 [BR] Get envelope value at time position for the envelope object allocated with BR_EnvAlloc.
FUNC684 number startTime, number endTime = reaper.BR_GetArrangeView(ReaProject proj)
DESC684 [BR] Deprecated, see GetSet_ArrangeView2 (REAPER v5.12pre4+) -- Get start and end time position of arrange view. To set arrange view instead, see BR_SetArrangeView.
FUNC685 number reaper.BR_GetClosestGridDivision(number position)
DESC685 [BR] Get closest grid division to position. Note that this functions is different from SnapToGrid in two regards. SnapToGrid() needs snap enabled to work and this one works always. Secondly, grid divisions are different from grid lines because some grid lines may be hidden due to zoom level - this function ignores grid line visibility and always searches for the closest grid division at given position. For more grid division functions, see BR_GetNextGridDivision and BR_GetPrevGridDivision.
FUNC686 string themePath, string themeName = reaper.BR_GetCurrentTheme()
DESC686 [BR] Get current theme information. themePathOut is set to full theme path and themeNameOut is set to theme name excluding any path info and extension
FUNC687 MediaItem reaper.BR_GetMediaItemByGUID(ReaProject proj, string guidStringIn)
DESC687 [BR] Get media item from GUID string. Note that the GUID must be enclosed in braces {}. To get item's GUID as a string, see BR_GetMediaItemGUID.
FUNC688 string guidString = reaper.BR_GetMediaItemGUID(MediaItem item)
DESC688 [BR] Get media item GUID as a string (guidStringOut_sz should be at least 64). To get media item back from GUID string, see BR_GetMediaItemByGUID.
FUNC689 boolean retval, string image, number imageFlags = reaper.BR_GetMediaItemImageResource(MediaItem item)
DESC689 [BR] Get currently loaded image resource and it's flags for a given item. Returns false if there is no image resource set. To set image resource, see BR_SetMediaItemImageResource.
FUNC690 string guidString = reaper.BR_GetMediaItemTakeGUID(MediaItem_Take take)
DESC690 [BR] Get media item take GUID as a string (guidStringOut_sz should be at least 64). To get take from GUID string, see SNM_GetMediaItemTakeByGUID.
FUNC691 boolean retval, boolean section, number start, number length, number fade, boolean reverse = reaper.BR_GetMediaSourceProperties(MediaItem_Take take)
DESC691 [BR] Get take media source properties as they appear in Item properties. Returns false if take can't have them (MIDI items etc.).To set source properties, see BR_SetMediaSourceProperties.
FUNC692 MediaTrack reaper.BR_GetMediaTrackByGUID(ReaProject proj, string guidStringIn)
DESC692 [BR] Get media track from GUID string. Note that the GUID must be enclosed in braces {}. To get track's GUID as a string, see BR_GetMediaTrackGUID.
FUNC693 integer reaper.BR_GetMediaTrackFreezeCount(MediaTrack track)
DESC693 [BR] Get media track freeze count (if track isn't frozen at all, returns 0).
FUNC694 string guidString = reaper.BR_GetMediaTrackGUID(MediaTrack track)
DESC694 [BR] Get media track GUID as a string (guidStringOut_sz should be at least 64). To get media track back from GUID string, see BR_GetMediaTrackByGUID.
FUNC695 string mcpLayoutName, string tcpLayoutName = reaper.BR_GetMediaTrackLayouts(MediaTrack track)
DESC695 [BR] Deprecated, see GetSetMediaTrackInfo (REAPER v5.02+). Get media track layouts for MCP and TCP. Empty string ("") means that layout is set to the default layout. To set media track layouts, see BR_SetMediaTrackLayouts.
FUNC696 TrackEnvelope reaper.BR_GetMediaTrackSendInfo_Envelope(MediaTrack track, integer category, integer sendidx, integer envelopeType)
DESC696 [BR] Get track envelope for send/receive/hardware output.category is <0 for receives, 0=sends, >0 for hardware outputssendidx is zero-based (see GetTrackNumSends to count track sends/receives/hardware outputs)envelopeType determines which envelope is returned (0=volume, 1=pan, 2=mute)Note: To get or set other send attributes, see BR_GetSetTrackSendInfo and BR_GetMediaTrackSendInfo_Track.
FUNC697 MediaTrack reaper.BR_GetMediaTrackSendInfo_Track(MediaTrack track, integer category, integer sendidx, integer trackType)
DESC697 [BR] Get source or destination media track for send/receive.category is <0 for receives, 0=sendssendidx is zero-based (see GetTrackNumSends to count track sends/receives)trackType determines which track is returned (0=source track, 1=destination track)Note: To get or set other send attributes, see BR_GetSetTrackSendInfo and BR_GetMediaTrackSendInfo_Envelope.
FUNC698 number reaper.BR_GetMidiSourceLenPPQ(MediaItem_Take take)
DESC698 [BR] Get MIDI take source length in PPQ. In case the take isn't MIDI, return value will be -1.
FUNC699 boolean retval, string guidString = reaper.BR_GetMidiTakePoolGUID(MediaItem_Take take)
DESC699 [BR] Get MIDI take pool GUID as a string (guidStringOut_sz should be at least 64). Returns true if take is pooled.
FUNC700 boolean retval, boolean ignoreProjTempo, number bpm, number num, number den = reaper.BR_GetMidiTakeTempoInfo(MediaItem_Take take)
DESC700 [BR] Get "ignore project tempo" information for MIDI take. Returns true if take can ignore project tempo (no matter if it's actually ignored), otherwise false.
FUNC701 string window, string segment, string details = reaper.BR_GetMouseCursorContext()
DESC701 [BR] Get mouse cursor context. Each parameter returns information in a form of string as specified in the table below.To get more info on stuff that was found under mouse cursor see BR_GetMouseCursorContext_Envelope, BR_GetMouseCursorContext_Item, BR_GetMouseCursorContext_MIDI, BR_GetMouseCursorContext_Position, BR_GetMouseCursorContext_Take, BR_GetMouseCursorContext_TrackWindow  Segment  Detailsunknown  ""  ""ruler  region_lane  ""marker_lane  ""tempo_lane  ""timeline  ""transport  ""  ""tcp  track  ""envelope  ""empty  ""mcp  track  ""empty  ""arrange  track  empty,item, item_stretch_marker,env_point, env_segmentenvelope  empty, env_point, env_segmentempty  ""midi_editor  unknown  ""ruler  ""piano  ""notes  ""cc_lane  cc_selector, cc_lane
FUNC702 TrackEnvelope retval, boolean takeEnvelope = reaper.BR_GetMouseCursorContext_Envelope()
DESC702 [BR] Returns envelope that was captured with the last call to BR_GetMouseCursorContext. In case the envelope belongs to take, takeEnvelope will be true.
FUNC703 MediaItem reaper.BR_GetMouseCursorContext_Item()
DESC703 [BR] Returns item under mouse cursor that was captured with the last call to BR_GetMouseCursorContext. Note that the function will return item even if mouse cursor is over some other track lane element like stretch marker or envelope. This enables for easier identification of items when you want to ignore elements within the item.
FUNC704 identifier retval, boolean inlineEditor, number noteRow, number ccLane, number ccLaneVal, number ccLaneId = reaper.BR_GetMouseCursorContext_MIDI()
DESC704 [BR] Returns midi editor under mouse cursor that was captured with the last call to BR_GetMouseCursorContext.inlineEditor: if mouse was captured in inline MIDI editor, this will be true (consequentially, returned MIDI editor will be NULL)noteRow: note row or piano key under mouse cursor (0-127)ccLane: CC lane under mouse cursor (CC0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207=off velocity, 0x208=notation events)ccLaneVal: value in CC lane under mouse cursor (0-127 or 0-16383)ccLaneId: lane position, counting from the top (0 based)Note: due to API limitations, if mouse is over inline MIDI editor with some note rows hidden, noteRow will be -1
FUNC705 number reaper.BR_GetMouseCursorContext_Position()
DESC705 [BR] Returns project time position in arrange/ruler/midi editor that was captured with the last call to BR_GetMouseCursorContext.
FUNC706 integer reaper.BR_GetMouseCursorContext_StretchMarker()
DESC706 [BR] Returns id of a stretch marker under mouse cursor that was captured with the last call to BR_GetMouseCursorContext.
FUNC707 MediaItem_Take reaper.BR_GetMouseCursorContext_Take()
DESC707 [BR] Returns take under mouse cursor that was captured with the last call to BR_GetMouseCursorContext.
FUNC708 MediaTrack reaper.BR_GetMouseCursorContext_Track()
DESC708 [BR] Returns track under mouse cursor that was captured with the last call to BR_GetMouseCursorContext.
FUNC709 number reaper.BR_GetNextGridDivision(number position)
DESC709 [BR] Get next grid division after the time position. For more grid divisions function, see BR_GetClosestGridDivision and BR_GetPrevGridDivision.
FUNC710 number reaper.BR_GetPrevGridDivision(number position)
DESC710 [BR] Get previous grid division before the time position. For more grid division functions, see BR_GetClosestGridDivision and BR_GetNextGridDivision.
FUNC711 number reaper.BR_GetSetTrackSendInfo(MediaTrack track, integer category, integer sendidx, string parmname, boolean setNewValue, number newValue)
DESC711 [BR] Get or set send attributes.category is <0 for receives, 0=sends, >0 for hardware outputssendidx is zero-based (see GetTrackNumSends to count track sends/receives/hardware outputs)To set attribute, pass setNewValue as trueList of possible parameters:B_MUTE : send mute state (1.0 if muted, otherwise 0.0)B_PHASE : send phase state (1.0 if phase is inverted, otherwise 0.0)B_MONO : send mono state (1.0 if send is set to mono, otherwise 0.0)D_VOL : send volume (1.0=+0dB etc...)D_PAN : send pan (-1.0=100%L, 0=center, 1.0=100%R)D_PANLAW : send pan law (1.0=+0.0db, 0.5=-6dB, -1.0=project default etc...)I_SENDMODE : send mode (0=post-fader, 1=pre-fx, 2=post-fx(deprecated), 3=post-fx)I_SRCCHAN : audio source starting channel index or -1 if audio send is disabled (&1024=mono...note that in that case, when reading index, you should do (index XOR 1024) to get starting channel index)I_DSTCHAN : audio destination starting channel index (&1024=mono (and in case of hardware output &512=rearoute)...note that in that case, when reading index, you should do (index XOR (1024 OR 512)) to get starting channel index)I_MIDI_SRCCHAN : source MIDI channel, -1 if MIDI send is disabled (0=all, 1-16)I_MIDI_DSTCHAN : destination MIDI channel, -1 if MIDI send is disabled (0=original, 1-16)I_MIDI_SRCBUS : source MIDI bus, -1 if MIDI send is disabled (0=all, otherwise bus index)I_MIDI_DSTBUS : receive MIDI bus, -1 if MIDI send is disabled (0=all, otherwise bus index)I_MIDI_LINK_VOLPAN : link volume/pan controls to MIDINote: To get or set other send attributes, see BR_GetMediaTrackSendInfo_Envelope and BR_GetMediaTrackSendInfo_Track.
FUNC712 integer reaper.BR_GetTakeFXCount(MediaItem_Take take)
DESC712 [BR] Returns FX count for supplied take
FUNC713 boolean reaper.BR_IsMidiOpenInInlineEditor(MediaItem_Take take)
DESC713 [SWS] Check if take has MIDI inline editor open and returns true or false.
FUNC714 boolean retval, boolean inProjectMidi = reaper.BR_IsTakeMidi(MediaItem_Take take)
DESC714 [BR] Check if take is MIDI take, in case MIDI take is in-project MIDI source data, inProjectMidiOut will be true, otherwise false.
FUNC715 MediaItem retval, number position = reaper.BR_ItemAtMouseCursor()
DESC715 [BR] Get media item under mouse cursor. Position is mouse cursor position in arrange.
FUNC716 boolean reaper.BR_MIDI_CCLaneRemove(identifier midiEditor, integer laneId)
DESC716 [BR] Remove CC lane in midi editor. Top visible CC lane is laneId 0. Returns true on success
FUNC717 boolean reaper.BR_MIDI_CCLaneReplace(identifier midiEditor, integer laneId, integer newCC)
DESC717 [BR] Replace CC lane in midi editor. Top visible CC lane is laneId 0. Returns true on success.Valid CC lanes: CC0-127=CC, 0x100|(0-31)=14-bit CC, 0x200=velocity, 0x201=pitch, 0x202=program, 0x203=channel pressure, 0x204=bank/program select, 0x205=text, 0x206=sysex, 0x207
FUNC718 number reaper.BR_PositionAtMouseCursor(boolean checkRuler)
DESC718 [BR] Get position at mouse cursor. To check ruler along with arrange, pass checkRuler=true. Returns -1 if cursor is not over arrange/ruler.
FUNC719 reaper.BR_SetArrangeView(ReaProject proj, number startTime, number endTime)
DESC719 [BR] Deprecated, see GetSet_ArrangeView2 (REAPER v5.12pre4+) -- Set start and end time position of arrange view. To get arrange view instead, see BR_GetArrangeView.
FUNC720 boolean reaper.BR_SetItemEdges(MediaItem item, number startTime, number endTime)
DESC720 [BR] Set item start and end edges' position - returns true in case of any changes
FUNC721 reaper.BR_SetMediaItemImageResource(MediaItem item, string imageIn, integer imageFlags)
DESC721 [BR] Set image resource and it's flags for a given item. To clear current image resource, pass imageIn as . To get image resource, see BR_GetMediaItemImageResource.
FUNC722 boolean reaper.BR_SetMediaSourceProperties(MediaItem_Take take, boolean section, number start, number length, number fade, boolean reverse)
DESC722 [BR] Set take media source properties. Returns false if take can't have them (MIDI items etc.). Section parameters have to be valid only when passing section=true.To get source properties, see BR_GetMediaSourceProperties.
FUNC723 boolean reaper.BR_SetMediaTrackLayouts(MediaTrack track, string mcpLayoutNameIn, string tcpLayoutNameIn)
DESC723 [BR] Deprecated, see GetSetMediaTrackInfo (REAPER v5.02+). Set media track layouts for MCP and TCP. To set default layout, pass empty string ("") as layout name. In case layouts were successfully set, returns true (if layouts are already set to supplied layout names, it will return false since no changes were made).To get media track layouts, see BR_GetMediaTrackLayouts.
FUNC724 boolean reaper.BR_SetMidiTakeTempoInfo(MediaItem_Take take, boolean ignoreProjTempo, number bpm, integer num, integer den)
DESC724 [BR] Set "ignore project tempo" information for MIDI take. Returns true in case the take was successfully updated.
FUNC725 boolean reaper.BR_SetTakeSourceFromFile(MediaItem_Take take, string filenameIn, boolean inProjectData)
DESC725 [BR] Set new take source from file. To import MIDI file as in-project source data pass inProjectData=true. Returns false if failed.Any take source properties from the previous source will be lost - to preserve them, see BR_SetTakeSourceFromFile2.Note: To set source from existing take, see SNM_GetSetSourceState2.
FUNC726 boolean reaper.BR_SetTakeSourceFromFile2(MediaItem_Take take, string filenameIn, boolean inProjectData, boolean keepSourceProperties)
DESC726 [BR] Differs from BR_SetTakeSourceFromFile only that it can also preserve existing take media source properties.
FUNC727 MediaItem_Take retval, number position = reaper.BR_TakeAtMouseCursor()
DESC727 [BR] Get take under mouse cursor. Position is mouse cursor position in arrange.
FUNC728 MediaTrack retval, number context, number position = reaper.BR_TrackAtMouseCursor()
DESC728 [BR] Get track under mouse cursor.Context signifies where the track was found: 0 = TCP, 1 = MCP, 2 = Arrange.Position will hold mouse cursor position in arrange if applicable.
FUNC729 boolean retval, string name = reaper.BR_TrackFX_GetFXModuleName(MediaTrack track, integer fx)
DESC729 [BR] Get the exact name (like effect.dll, effect.vst3, etc...) of an FX.
FUNC730 integer reaper.BR_Win32_CB_FindString(identifier comboBoxHwnd, integer startId, string string)
DESC730 [BR] Equivalent to win32 API ComboBox_FindString().
FUNC731 integer reaper.BR_Win32_CB_FindStringExact(identifier comboBoxHwnd, integer startId, string string)
DESC731 [BR] Equivalent to win32 API ComboBox_FindStringExact().
FUNC732 number x, number y = reaper.BR_Win32_ClientToScreen(identifier hwnd, integer xIn, integer yIn)
DESC732 [BR] Equivalent to win32 API ClientToScreen().
FUNC733 identifier reaper.BR_Win32_FindWindowEx(string hwndParent, string hwndChildAfter, string className, string windowName, boolean searchClass, boolean searchName)
DESC733 [BR] Equivalent to win32 API FindWindowEx(). Since ReaScript doesn't allow passing NULL (None in Python, nil in Lua etc...) parameters, to search by supplied class or name set searchClass and searchName accordingly. HWND parameters should be passed as either "0" to signify NULL or as string obtained from BR_Win32_HwndToString.
FUNC734 integer reaper.BR_Win32_GET_X_LPARAM(integer lParam)
DESC734 [BR] Equivalent to win32 API GET_X_LPARAM().
FUNC735 integer reaper.BR_Win32_GET_Y_LPARAM(integer lParam)
DESC735 [BR] Equivalent to win32 API GET_Y_LPARAM().
FUNC736 integer reaper.BR_Win32_GetConstant(string constantName)
DESC736 [BR] Returns various constants needed for BR_Win32 functions.Supported constants are:CB_ERR, CB_GETCOUNT, CB_GETCURSEL, CB_SETCURSELEM_SETSELGW_CHILD, GW_HWNDFIRST, GW_HWNDLAST, GW_HWNDNEXT, GW_HWNDPREV, GW_OWNERGWL_STYLESW_HIDE, SW_MAXIMIZE, SW_SHOW, SW_SHOWMINIMIZED, SW_SHOWNA, SW_SHOWNOACTIVATE, SW_SHOWNORMALSWP_FRAMECHANGED, SWP_FRAMECHANGED, SWP_NOMOVE, SWP_NOOWNERZORDER, SWP_NOSIZE, SWP_NOZORDERVK_DOWN, VK_UPWM_CLOSE, WM_KEYDOWNWS_MAXIMIZE, WS_OVERLAPPEDWINDOW
FUNC737 boolean retval, number x, number y = reaper.BR_Win32_GetCursorPos()
DESC737 [BR] Equivalent to win32 API GetCursorPos().
FUNC738 identifier reaper.BR_Win32_GetFocus()
DESC738 [BR] Equivalent to win32 API GetFocus().
FUNC739 identifier reaper.BR_Win32_GetForegroundWindow()
DESC739 [BR] Equivalent to win32 API GetForegroundWindow().
FUNC740 identifier reaper.BR_Win32_GetMainHwnd()
DESC740 [BR] Alternative to GetMainHwnd. REAPER seems to have problems with extensions using HWND type for exported functions so all BR_Win32 functions use void* instead of HWND type
FUNC741 identifier retval, boolean isDocked = reaper.BR_Win32_GetMixerHwnd()
DESC741 [BR] Get mixer window HWND. isDockedOut will be set to true if mixer is docked
FUNC742 number left, number top, number right, number bottom = reaper.BR_Win32_GetMonitorRectFromRect(boolean workingAreaOnly, integer leftIn, integer topIn, integer rightIn, integer bottomIn)
DESC742 [BR] Get coordinates for screen which is nearest to supplied coordinates. Pass workingAreaOnly as true to get screen coordinates excluding taskbar (or menu bar on OSX).
FUNC743 identifier reaper.BR_Win32_GetParent(identifier hwnd)
DESC743 [BR] Equivalent to win32 API GetParent().
FUNC744 integer retval, string string = reaper.BR_Win32_GetPrivateProfileString(string sectionName, string keyName, string defaultString, string filePath)
DESC744 [BR] Equivalent to win32 API GetPrivateProfileString(). For example, you can use this to get values from REAPER.ini
FUNC745 identifier reaper.BR_Win32_GetWindow(identifier hwnd, integer cmd)
DESC745 [BR] Equivalent to win32 API GetWindow().
FUNC746 integer reaper.BR_Win32_GetWindowLong(identifier hwnd, integer index)
DESC746 [BR] Equivalent to win32 API GetWindowLong().
FUNC747 boolean retval, number left, number top, number right, number bottom = reaper.BR_Win32_GetWindowRect(identifier hwnd)
DESC747 [BR] Equivalent to win32 API GetWindowRect().
FUNC748 integer retval, string text = reaper.BR_Win32_GetWindowText(identifier hwnd)
DESC748 [BR] Equivalent to win32 API GetWindowText().
FUNC749 integer reaper.BR_Win32_HIBYTE(integer value)
DESC749 [BR] Equivalent to win32 API HIBYTE().
FUNC750 integer reaper.BR_Win32_HIWORD(integer value)
DESC750 [BR] Equivalent to win32 API HIWORD().
FUNC751 string string = reaper.BR_Win32_HwndToString(identifier hwnd)
DESC751 [BR] Convert HWND to string. To convert string back to HWND, see BR_Win32_StringToHwnd.
FUNC752 boolean reaper.BR_Win32_IsWindow(identifier hwnd)
DESC752 [BR] Equivalent to win32 API IsWindow().
FUNC753 boolean reaper.BR_Win32_IsWindowVisible(identifier hwnd)
DESC753 [BR] Equivalent to win32 API IsWindowVisible().
FUNC754 integer reaper.BR_Win32_LOBYTE(integer value)
DESC754 [BR] Equivalent to win32 API LOBYTE().
FUNC755 integer reaper.BR_Win32_LOWORD(integer value)
DESC755 [BR] Equivalent to win32 API LOWORD().
FUNC756 integer reaper.BR_Win32_MAKELONG(integer low, integer high)
DESC756 [BR] Equivalent to win32 API MAKELONG().
FUNC757 integer reaper.BR_Win32_MAKELPARAM(integer low, integer high)
DESC757 [BR] Equivalent to win32 API MAKELPARAM().
FUNC758 integer reaper.BR_Win32_MAKELRESULT(integer low, integer high)
DESC758 [BR] Equivalent to win32 API MAKELRESULT().
FUNC759 integer reaper.BR_Win32_MAKEWORD(integer low, integer high)
DESC759 [BR] Equivalent to win32 API MAKEWORD().
FUNC760 integer reaper.BR_Win32_MAKEWPARAM(integer low, integer high)
DESC760 [BR] Equivalent to win32 API MAKEWPARAM().
FUNC761 identifier reaper.BR_Win32_MIDIEditor_GetActive()
DESC761 [BR] Alternative to MIDIEditor_GetActive. REAPER seems to have problems with extensions using HWND type for exported functions so all BR_Win32 functions use void* instead of HWND type.
FUNC762 number x, number y = reaper.BR_Win32_ScreenToClient(identifier hwnd, integer xIn, integer yIn)
DESC762 [BR] Equivalent to win32 API ClientToScreen().
FUNC763 integer reaper.BR_Win32_SendMessage(identifier hwnd, integer msg, integer lParam, integer wParam)
DESC763 [BR] Equivalent to win32 API SendMessage().
FUNC764 identifier reaper.BR_Win32_SetFocus(identifier hwnd)
DESC764 [BR] Equivalent to win32 API SetFocus().
FUNC765 integer reaper.BR_Win32_SetForegroundWindow(identifier hwnd)
DESC765 [BR] Equivalent to win32 API SetForegroundWindow().
FUNC766 integer reaper.BR_Win32_SetWindowLong(identifier hwnd, integer index, integer newLong)
DESC766 [BR] Equivalent to win32 API SetWindowLong().
FUNC767 boolean reaper.BR_Win32_SetWindowPos(identifier hwnd, string hwndInsertAfter, integer x, integer y, integer width, integer height, integer flags)
DESC767 [BR] Equivalent to win32 API SetWindowPos().hwndInsertAfter may be a string: "HWND_BOTTOM", "HWND_NOTOPMOST", "HWND_TOP", "HWND_TOPMOST" or a string obtained with BR_Win32_HwndToString.
FUNC768 integer reaper.BR_Win32_ShellExecute(string operation, string file, string parameters, string directory, integer showFlags)
DESC768 [BR] Equivalent to win32 API ShellExecute() with HWND set to main window
FUNC769 boolean reaper.BR_Win32_ShowWindow(identifier hwnd, integer cmdShow)
DESC769 [BR] Equivalent to win32 API ShowWindow().
FUNC770 identifier reaper.BR_Win32_StringToHwnd(string string)
DESC770 [BR] Convert string to HWND. To convert HWND back to string, see BR_Win32_HwndToString.
FUNC771 identifier reaper.BR_Win32_WindowFromPoint(integer x, integer y)
DESC771 [BR] Equivalent to win32 API WindowFromPoint().
FUNC772 boolean reaper.BR_Win32_WritePrivateProfileString(string sectionName, string keyName, string value, string filePath)
DESC772 [BR] Equivalent to win32 API WritePrivateProfileString(). For example, you can use this to write to REAPER.ini
FUNC773 integer retval, number time, number endTime, boolean isRegion, string name = reaper.CF_EnumMediaSourceCues(PCM_source src, integer index)
DESC773 Enumerate the source's media cues. Returns the next index or 0 when finished.
FUNC774 integer reaper.CF_EnumSelectedFX(FxChain hwnd, integer index)
DESC774 Return the index of the next selected effect in the given FX chain. Start index should be -1. Returns -1 if there are no more selected effects.
FUNC775 integer retval, string name = reaper.CF_EnumerateActions(integer section, integer index, string name)
DESC775 Wrapper for the unexposed kbd_enumerateActions API function.Main=0, Main (alt recording)=100, MIDI Editor=32060, MIDI Event List Editor=32061, MIDI Inline Editor=32062, Media Explorer=32063
FUNC776 boolean reaper.CF_ExportMediaSource(PCM_source src, string fn)
DESC776 Export the source to the given file (MIDI only).
FUNC777 string buf = reaper.CF_GetClipboard(string buf)
DESC777 Read the contents of the system clipboard (limited to 1023 characters in Lua).
FUNC778 string reaper.CF_GetClipboardBig(WDL_FastString output)
DESC778 Read the contents of the system clipboard. See SNM_CreateFastString and SNM_DeleteFastString.
FUNC779 string reaper.CF_GetCommandText(integer section, integer command)
DESC779 Wrapper for the unexposed kbd_getTextFromCmd API function. See CF_EnumerateActions for common section IDs.
FUNC780 FxChain = reaper.CF_GetFocusedFXChain()
DESC780 Return a handle to the currently focused FX chain window.
FUNC781 integer reaper.CF_GetMediaSourceBitDepth(PCM_source src)
DESC781 Returns the bit depth if available (0 otherwise).
FUNC782 boolean retval, string out = reaper.CF_GetMediaSourceMetadata(PCM_source src, string name, string out)
DESC782 Get the value of the given metadata field (eg. DESC, ORIG, ORIGREF, DATE, TIME, UMI, CODINGHISTORY for BWF).
FUNC783 boolean reaper.CF_GetMediaSourceOnline(PCM_source src)
DESC783 Returns the online/offline status of the given source.
FUNC784 boolean retval, string fn = reaper.CF_GetMediaSourceRPP(PCM_source src, string fn)
DESC784 Get the project associated with this source (BWF, subproject...).
FUNC785 string buf = reaper.CF_GetSWSVersion(string buf)
DESC785 Return the current SWS version number.
FUNC786 FxChain reaper.CF_GetTakeFXChain(MediaItem_Take take)
DESC786 Return a handle to the given take FX chain window. HACK: This temporarily renames the take in order to disambiguate the take FX chain window from similarily named takes.
FUNC787 FxChain reaper.CF_GetTrackFXChain(MediaTrack track)
DESC787 Return a handle to the given track FX chain window.
FUNC788 boolean reaper.CF_LocateInExplorer(string file)
DESC788 Select the given file in explorer/finder.
FUNC789 reaper.CF_SetClipboard(string str)
DESC789 Write the given string into the system clipboard.
FUNC790 reaper.CF_SetMediaSourceOnline(PCM_source src, boolean set)
DESC790 Set the online/offline status of the given source (closes files when set=false).
FUNC791 boolean reaper.CF_ShellExecute(string file)
DESC791 Open the given file or URL in the default application. See also CF_LocateInExplorer.
FUNC792 RprMidiNote reaper.FNG_AddMidiNote(RprMidiTake midiTake)
DESC792 [FNG] Add MIDI note to MIDI take
FUNC793 RprMidiTake reaper.FNG_AllocMidiTake(MediaItem_Take take)
DESC793 [FNG] Allocate a RprMidiTake from a take pointer. Returns a NULL pointer if the take is not an in-project MIDI take
FUNC794 integer reaper.FNG_CountMidiNotes(RprMidiTake midiTake)
DESC794 [FNG] Count of how many MIDI notes are in the MIDI take
FUNC795 reaper.FNG_FreeMidiTake(RprMidiTake midiTake)
DESC795 [FNG] Commit changes to MIDI take and free allocated memory
FUNC796 RprMidiNote reaper.FNG_GetMidiNote(RprMidiTake midiTake, integer index)
DESC796 [FNG] Get a MIDI note from a MIDI take at specified index
FUNC797 integer reaper.FNG_GetMidiNoteIntProperty(RprMidiNote midiNote, string property)
DESC797 [FNG] Get MIDI note property
FUNC798 reaper.FNG_SetMidiNoteIntProperty(RprMidiNote midiNote, string property, integer value)
DESC798 [FNG] Set MIDI note property
FUNC799 boolean retval, string payload = reaper.ImGui_AcceptDragDropPayload(ImGui_Context ctx, string type, string payload, optional number flagsIn)
DESC799 Accept contents of a given type. If ImGui_DragDropFlags_AcceptBeforeDelivery is set you can peek into the payload before the mouse button is released.Default values: flags = ImGui_DragDropFlags_None
FUNC800 boolean retval, number count = reaper.ImGui_AcceptDragDropPayloadFiles(ImGui_Context ctx, number count, optional number flagsIn)
DESC800 Accept a list of dropped files. See ImGui_AcceptDragDropPayload and ImGui_GetDragDropPayloadFile.Default values: flags = ImGui_DragDropFlags_None
FUNC801 boolean retval, number rgb = reaper.ImGui_AcceptDragDropPayloadRGB(ImGui_Context ctx, number rgb, optional number flagsIn)
DESC801 Accept a RGB color. See ImGui_AcceptDragDropPayload.Default values: flags = ImGui_DragDropFlags_None
FUNC802 boolean retval, number rgba = reaper.ImGui_AcceptDragDropPayloadRGBA(ImGui_Context ctx, number rgba, optional number flagsIn)
DESC802 Accept a RGBA color. See ImGui_AcceptDragDropPayload.Default values: flags = ImGui_DragDropFlags_None
FUNC803 reaper.ImGui_AlignTextToFramePadding(ImGui_Context ctx)
DESC803 Vertically align upcoming text baseline to ImGui_StyleVar_FramePadding.y so that it will align properly to regularly framed items (call if you have text on a line before a framed item)
FUNC804 boolean reaper.ImGui_ArrowButton(ImGui_Context ctx, string str_id, integer dir)
DESC804 Square button with an arrow shape.
FUNC805 reaper.ImGui_AttachFont(ImGui_Context ctxImGui_Font font)
DESC805 Enable a font for use in the given context. Fonts must be attached as soon as possible after creating the context or on a new defer cycle.
FUNC806 boolean retval, boolean p_open = reaper.ImGui_Begin(ImGui_Context ctx, string name, boolean p_open, optional number flagsIn)
DESC806 Push window to the stack and start appending to it. See ImGui_End.- Passing true to 'p_open' shows a window-closing widget in the upper-right corner of the window, which clicking will set the boolean to false when returned.- You may append multiple times to the same window during the same frame by calling Begin()/End() pairs multiple times. Some information such as 'flags' or 'open' will only be considered by the first call to Begin().- Begin() return false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting anything to the window.- Note that the bottom of window stack always contains a window called "Debug".Default values: flags = ImGui_WindowFlags_None
FUNC807 boolean reaper.ImGui_BeginChild(ImGui_Context ctx, string str_id, optional number size_wIn, optional number size_hIn, optional boolean borderIn, optional number flagsIn)
DESC807 Use child windows to begin into a self-contained independent scrolling/clipping regions within a host window. Child windows can embed their own child.- For each independent axis of 'size': ==0.0f: use remaining host window size / >0.0f: fixed size / <0.0f: use remaining window size minus abs(size) / Each axis can use a different mode, e.g. size = 0x400.- BeginChild() returns false to indicate the window is collapsed or fully clipped, so you may early out and omit submitting anything to the window.See ImGui_EndChild.Default values: size_w = 0.0, size_h = 0.0, border = false, flags = ImGui_WindowFlags_None
FUNC808 boolean reaper.ImGui_BeginChildFrame(ImGui_Context ctx, string str_id, number size_w, number size_h, optional number flagsIn)
DESC808 Helper to create a child window / scrolling region that looks like a normal widget frame. See ImGui_EndChildFrame.Default values: flags = ImGui_WindowFlags_None
FUNC809 boolean reaper.ImGui_BeginCombo(ImGui_Context ctx, string label, string preview_value, optional number flagsIn)
DESC809 The ImGui_BeginCombo/ImGui_EndCombo API allows you to manage your contents and selection state however you want it, by creating e.g. ImGui_Selectable items.Default values: flags = ImGui_ComboFlags_None
FUNC810 boolean reaper.ImGui_BeginDragDropSource(ImGui_Context ctx, optional number flagsIn)
DESC810 Call when the current item is active. If this return true, you can call ImGui_SetDragDropPayload + ImGui_EndDragDropSource.If you stop calling BeginDragDropSource() the payload is preserved however it won't have a preview tooltip (we currently display a fallback "..." tooltip as replacement).Default values: flags = ImGui_DragDropFlags_None
FUNC811 boolean reaper.ImGui_BeginDragDropTarget(ImGui_Context ctx)
DESC811 Call after submitting an item that may receive a payload. If this returns true, you can call ImGui_AcceptDragDropPayload + ImGui_EndDragDropTarget.
FUNC812 reaper.ImGui_BeginGroup(ImGui_Context ctx)
DESC812 Lock horizontal starting position. See ImGui_EndGroup.
FUNC813 boolean reaper.ImGui_BeginListBox(ImGui_Context ctx, string label, optional number size_wIn, optional number size_hIn)
DESC813 Open a framed scrolling region. This is essentially a thin wrapper to using ImGui_BeginChild/ImGui_EndChild with some stylistic changes.The ImGui_BeginListBox/ImGui_EndListBox API allows you to manage your contents and selection state however you want it, by creating e.g. ImGui_Selectable or any items.- Choose frame width: width > 0.0: custom / width < 0.0 or -FLT_MIN: right-align / width = 0.0 (default): use current ItemWidth- Choose frame height: height > 0.0: custom / height < 0.0 or -FLT_MIN: bottom-align / height = 0.0 (default): arbitrary default height which can fit ~7 itemsDefault values: size_w = 0.0, size_h = 0.0See ImGui_EndListBox.
FUNC814 boolean reaper.ImGui_BeginMenu(ImGui_Context ctx, string label, optional boolean enabledIn)
DESC814 Create a sub-menu entry. only call ImGui_EndMenu if this returns true!Default values: enabled = true
FUNC815 boolean reaper.ImGui_BeginMenuBar(ImGui_Context ctx)
DESC815 Append to menu-bar of current window (requires ImGui_WindowFlags_MenuBar flag set on parent window). See ImGui_EndMenuBar.
FUNC816 boolean reaper.ImGui_BeginPopup(ImGui_Context ctx, string str_id, optional number flagsIn)
DESC816 Popups, Modals- They block normal mouse hovering detection (and therefore most mouse interactions) behind them.- If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.- Their visibility state (~bool) is held internally instead of being held by the programmer as we are used to with regular Begin*() calls.- The 3 properties above are related: we need to retain popup visibility state in the library because popups may be closed as any time.- You can bypass the hovering restriction by using ImGui_HoveredFlags_AllowWhenBlockedByPopup when calling ImGui_IsItemHovered or ImGui_IsWindowHovered.- IMPORTANT: Popup identifiers are relative to the current ID stack, so ImGui_OpenPopup and BeginPopup generally needs to be at the same level of the stack.Query popup state, if open start appending into the window. Call ImGui_EndPopup afterwards. ImGui_WindowFlags* are forwarded to the window.Return true if the popup is open, and you can start outputting to it.Default values: flags = ImGui_WindowFlags_None
FUNC817 boolean reaper.ImGui_BeginPopupContextItem(ImGui_Context ctx, optional string str_idIn, optional number popup_flagsIn)
DESC817 This is a helper to handle the simplest case of associating one named popup to one given widget. You can pass a NULL str_id to use the identifier of the last item. This is essentially the same as calling ImGui_OpenPopupOnItemClick + ImGui_BeginPopup but written to avoid computing the ID twice because BeginPopupContextXXX functions may be called very frequently.Open+begin popup when clicked on last item. if you can pass a NULL str_id only if the previous item had an id. If you want to use that on a non-interactive item such as ImGui_Text you need to pass in an explicit ID here.- IMPORTANT: Notice that BeginPopupContextXXX takes ImGui_PopupFlags just like ImGui_OpenPopup and unlike ImGui_BeginPopup.- IMPORTANT: We exceptionally default their flags to 1 (== ImGui_PopupFlags_MouseButtonRight) for backward compatibility with older API taking 'int mouse_button = 1' parameter, so if you add other flags remember to re-add the ImGui_PopupFlags_MouseButtonRight.Default values: str_id = nil, popup_flags = ImGui_PopupFlags_MouseButtonRight
FUNC818 boolean reaper.ImGui_BeginPopupContextWindow(ImGui_Context ctx, optional string str_idIn, optional number popup_flagsIn)
DESC818 Open+begin popup when clicked on current window.Default values: str_id = nil, popup_flags = ImGui_PopupFlags_MouseButtonRight
FUNC819 boolean retval, boolean p_open = reaper.ImGui_BeginPopupModal(ImGui_Context ctx, string name, boolean p_open, optional number flagsIn)
DESC819 Block every interactions behind the window, cannot be closed by user, add a dimming background, has a title bar. Return true if the modal is open, and you can start outputting to it. See ImGui_BeginPopup.Default values: flags = ImGui_WindowFlags_None
FUNC820 boolean reaper.ImGui_BeginTabBar(ImGui_Context ctx, string str_id, optional number flagsIn)
DESC820 Create and append into a TabBar.Default values: flags = ImGui_TabBarFlags_None
FUNC821 boolean retval, boolean p_open = reaper.ImGui_BeginTabItem(ImGui_Context ctx, string label, boolean p_open, optional number flagsIn)
DESC821 Create a Tab. Returns true if the Tab is selected. Set 'p_open' to true to enable the close button.Default values: flags = ImGui_TabItemFlags_None
FUNC822 boolean reaper.ImGui_BeginTable(ImGui_Context ctx, string str_id, integer column, optional number flagsIn, optional number outer_size_wIn, optional number outer_size_hIn, optional number inner_widthIn)
DESC822 [BETA API] API may evolve slightly! If you use this, please update to the next version when it comes out!- See Demo->Tables for demo code.- See top of imgui_tables.cpp for general commentary.- See ImGui_TableFlags* and ImGui_TableColumnFlags* enums for a description of available flags.The typical call flow is:- 1. Call ImGui_BeginTable.- 2. Optionally call ImGui_TableSetupColumn to submit column name/flags/defaults.- 3. Optionally call ImGui_TableSetupScrollFreeze to request scroll freezing of columns/rows.- 4. Optionally call ImGui_TableHeadersRow to submit a header row. Names are pulled from ImGui_TableSetupColumn data.- 5. Populate contents:Â Â Â - In most situations you can use ImGui_TableNextRow + ImGui_TableSetColumnIndex(N) to start appending into a column.Â Â Â - If you are using tables as a sort of grid, where every columns is holding the same type of contents,Â Â Â Â Â you may prefer using ImGui_TableNextColumn instead of ImGui_TableNextRow + ImGui_TableSetColumnIndex.Â Â Â Â Â ImGui_TableNextColumn will automatically wrap-around into the next row if needed.Â Â Â - Summary of possible call flow:Â Â Â Â Â Â Â --------------------------------------------------------------------------------------------------------Â Â Â Â Â Â Â TableNextRow() -> TableSetColumnIndex(0) -> Text("Hello 0") -> TableSetColumnIndex(1) -> Text("Hello 1")Â Â // OKÂ Â Â Â Â Â Â TableNextRow() -> TableNextColumn()Â Â Â Â Â Â -> Text("Hello 0") -> TableNextColumn()Â Â Â Â Â Â -> Text("Hello 1")Â Â // OKÂ Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â TableNextColumn()Â Â Â Â Â Â -> Text("Hello 0") -> TableNextColumn()Â Â Â Â Â Â -> Text("Hello 1")Â Â // OK: TableNextColumn() automatically gets to next row!Â Â Â Â Â Â Â TableNextRow()Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â -> Text("Hello 0")Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â Â // Not OK! Missing TableSetColumnIndex() or TableNextColumn()! Text will not appear!Â Â Â Â Â Â Â --------------------------------------------------------------------------------------------------------- 5. Call ImGui_EndTable.Default values: flags = ImGui_TableFlags_None, outer_size_w = 0.0, outer_size_h = 0.0, inner_width = 0.0
FUNC823 reaper.ImGui_BeginTooltip(ImGui_Context ctx)
DESC823 Begin/append a tooltip window. To create full-featured tooltip (with any kind of items).
FUNC824 reaper.ImGui_Bullet(ImGui_Context ctx)
DESC824 Draw a small circle + keep the cursor on the same line. Advance cursor x position by ImGui_GetTreeNodeToLabelSpacing, same distance that ImGui_TreeNode uses.
FUNC825 reaper.ImGui_BulletText(ImGui_Context ctx, string text)
DESC825 Shortcut for ImGui_Bullet + ImGui_Text.
FUNC826 boolean reaper.ImGui_Button(ImGui_Context ctx, string label, optional number size_wIn, optional number size_hIn)
DESC826 Most widgets return true when the value has been changed or when pressed/selectedYou may also use one of the many IsItemXXX functions (e.g. ImGui_IsItemActive, ImGui_IsItemHovered, etc.) to query widget state.Default values: size_w = 0.0, size_h = 0.0
FUNC827 integer reaper.ImGui_ButtonFlags_MouseButtonLeft()
DESC827 React on left mouse button (default).
FUNC828 integer reaper.ImGui_ButtonFlags_MouseButtonMiddle()
DESC828 React on center mouse button.
FUNC829 integer reaper.ImGui_ButtonFlags_MouseButtonRight()
DESC829 React on right mouse button.
FUNC830 integer reaper.ImGui_ButtonFlags_None()
DESC830 Flags for ImGui_InvisibleButton.
FUNC831 number reaper.ImGui_CalcItemWidth(ImGui_Context ctx)
DESC831 Width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
FUNC832 number w, number h = reaper.ImGui_CalcTextSize(ImGui_Context ctx, string text, number w, number h, optional boolean hide_text_after_double_hashIn, optional number wrap_widthIn)
DESC832 Default values: hide_text_after_double_hash = false, wrap_width = -1.0
FUNC833 reaper.ImGui_CaptureKeyboardFromApp(ImGui_Context ctx, optional boolean want_capture_keyboard_valueIn)
DESC833 Manually enable or disable capture of keyboard shortcuts in the global scope for the next frame.Default values: want_capture_keyboard_value = true
FUNC834 boolean retval, boolean v = reaper.ImGui_Checkbox(ImGui_Context ctx, string label, boolean v)
DESC834 
FUNC835 boolean retval, number flags = reaper.ImGui_CheckboxFlags(ImGui_Context ctx, string label, number flags, integer flags_value)
DESC835 
FUNC836 reaper.ImGui_CloseCurrentPopup(ImGui_Context ctx)
DESC836 Manually close the popup we have begin-ed into. Use inside the ImGUi_BeginPopup/ImGui_EndPopup scope to close manually.CloseCurrentPopup() is called by default by ImGui_Selectable/ImGui_MenuItem when activated.
FUNC837 integer reaper.ImGui_Col_Border()
DESC837 
FUNC838 integer reaper.ImGui_Col_BorderShadow()
DESC838 
FUNC839 integer reaper.ImGui_Col_Button()
DESC839 
FUNC840 integer reaper.ImGui_Col_ButtonActive()
DESC840 
FUNC841 integer reaper.ImGui_Col_ButtonHovered()
DESC841 
FUNC842 integer reaper.ImGui_Col_CheckMark()
DESC842 
FUNC843 integer reaper.ImGui_Col_ChildBg()
DESC843 Background of child windows.
FUNC844 integer reaper.ImGui_Col_DockingEmptyBg()
DESC844 Background color for empty node (e.g. CentralNode with no window docked into it).
FUNC845 integer reaper.ImGui_Col_DockingPreview()
DESC845 Preview overlay color when about to docking something.
FUNC846 integer reaper.ImGui_Col_DragDropTarget()
DESC846 
FUNC847 integer reaper.ImGui_Col_FrameBg()
DESC847 Background of checkbox, radio button, plot, slider, text input.
FUNC848 integer reaper.ImGui_Col_FrameBgActive()
DESC848 
FUNC849 integer reaper.ImGui_Col_FrameBgHovered()
DESC849 
FUNC850 integer reaper.ImGui_Col_Header()
DESC850 Header* colors are used for ImGui_CollapsingHeader, ImGui_TreeNode, ImGui_Selectable, ImGui_MenuItem.
FUNC851 integer reaper.ImGui_Col_HeaderActive()
DESC851 
FUNC852 integer reaper.ImGui_Col_HeaderHovered()
DESC852 
FUNC853 integer reaper.ImGui_Col_MenuBarBg()
DESC853 
FUNC854 integer reaper.ImGui_Col_ModalWindowDimBg()
DESC854 Darken/colorize entire screen behind a modal window, when one is active.
FUNC855 integer reaper.ImGui_Col_NavHighlight()
DESC855 Gamepad/keyboard: current highlighted item.
FUNC856 integer reaper.ImGui_Col_NavWindowingDimBg()
DESC856 Darken/colorize entire screen behind the CTRL+TAB window list, when active.
FUNC857 integer reaper.ImGui_Col_NavWindowingHighlight()
DESC857 Highlight window when using CTRL+TAB.
FUNC858 integer reaper.ImGui_Col_PlotHistogram()
DESC858 
FUNC859 integer reaper.ImGui_Col_PlotHistogramHovered()
DESC859 
FUNC860 integer reaper.ImGui_Col_PlotLines()
DESC860 
FUNC861 integer reaper.ImGui_Col_PlotLinesHovered()
DESC861 
FUNC862 integer reaper.ImGui_Col_PopupBg()
DESC862 Background of popups, menus, tooltips windows.
FUNC863 integer reaper.ImGui_Col_ResizeGrip()
DESC863 
FUNC864 integer reaper.ImGui_Col_ResizeGripActive()
DESC864 
FUNC865 integer reaper.ImGui_Col_ResizeGripHovered()
DESC865 
FUNC866 integer reaper.ImGui_Col_ScrollbarBg()
DESC866 
FUNC867 integer reaper.ImGui_Col_ScrollbarGrab()
DESC867 
FUNC868 integer reaper.ImGui_Col_ScrollbarGrabActive()
DESC868 
FUNC869 integer reaper.ImGui_Col_ScrollbarGrabHovered()
DESC869 
FUNC870 integer reaper.ImGui_Col_Separator()
DESC870 
FUNC871 integer reaper.ImGui_Col_SeparatorActive()
DESC871 
FUNC872 integer reaper.ImGui_Col_SeparatorHovered()
DESC872 
FUNC873 integer reaper.ImGui_Col_SliderGrab()
DESC873 
FUNC874 integer reaper.ImGui_Col_SliderGrabActive()
DESC874 
FUNC875 integer reaper.ImGui_Col_Tab()
DESC875 
FUNC876 integer reaper.ImGui_Col_TabActive()
DESC876 
FUNC877 integer reaper.ImGui_Col_TabHovered()
DESC877 
FUNC878 integer reaper.ImGui_Col_TabUnfocused()
DESC878 
FUNC879 integer reaper.ImGui_Col_TabUnfocusedActive()
DESC879 
FUNC880 integer reaper.ImGui_Col_TableBorderLight()
DESC880 Table inner borders (prefer using Alpha=1.0 here).
FUNC881 integer reaper.ImGui_Col_TableBorderStrong()
DESC881 Table outer and header borders (prefer using Alpha=1.0 here).
FUNC882 integer reaper.ImGui_Col_TableHeaderBg()
DESC882 Table header background.
FUNC883 integer reaper.ImGui_Col_TableRowBg()
DESC883 Table row background (even rows).
FUNC884 integer reaper.ImGui_Col_TableRowBgAlt()
DESC884 Table row background (odd rows).
FUNC885 integer reaper.ImGui_Col_Text()
DESC885 
FUNC886 integer reaper.ImGui_Col_TextDisabled()
DESC886 
FUNC887 integer reaper.ImGui_Col_TextSelectedBg()
DESC887 
FUNC888 integer reaper.ImGui_Col_TitleBg()
DESC888 
FUNC889 integer reaper.ImGui_Col_TitleBgActive()
DESC889 
FUNC890 integer reaper.ImGui_Col_TitleBgCollapsed()
DESC890 
FUNC891 integer reaper.ImGui_Col_WindowBg()
DESC891 Background of normal windows.
FUNC892 boolean retval, boolean p_visible = reaper.ImGui_CollapsingHeader(ImGui_Context ctx, string label, boolean p_visible, optional number flagsIn)
DESC892 Returns true when opened but do not indent nor push into the ID stack (because of the ImGui_TreeNodeFlags_NoTreePushOnOpen flag).This is basically the same as calling TreeNode(label, ImGui_TreeNodeFlags_CollapsingHeader). You can remove the _NoTreePushOnOpen flag if you want behavior closer to normal ImGui_TreeNode.When 'visible' is provided: if 'true' display an additional small close button on upper right of the header which will set the bool to false when clicked, if 'false' don't display the header.Default values: flags = ImGui_TreeNodeFlags_None
FUNC893 boolean reaper.ImGui_ColorButton(ImGui_Context ctx, string desc_id, integer col_rgba, optional number flagsIn, optional number size_wIn, optional number size_hIn)
DESC893 Display a color square/button, hover for details, return true when pressed.Default values: flags = ImGui_ColorEditFlags_None, size_w = 0.0, size_h = 0.0
FUNC894 integer retval, number r, number g, number b = reaper.ImGui_ColorConvertHSVtoRGB(number h, number s, number v, optional number alphaIn)
DESC894 Return 0x00RRGGBB or, if alpha is provided, 0xRRGGBBAA.Default values: alpha = nil
FUNC895 integer reaper.ImGui_ColorConvertNative(integer rgb)
DESC895 Convert native colors coming from REAPER. This swaps the red and blue channels of the specified 0xRRGGBB color on Windows.
FUNC896 integer retval, number h, number s, number v = reaper.ImGui_ColorConvertRGBtoHSV(number r, number g, number b, optional number alphaIn)
DESC896 Return 0x00HHSSVV or, if alpha is provided, 0xHHSSVVAA.Default values: alpha = nil
FUNC897 boolean retval, number col_rgb = reaper.ImGui_ColorEdit3(ImGui_Context ctx, string label, number col_rgb, optional number flagsIn)
DESC897 Color is in 0xXXRRGGBB. XX is ignored and will not be modified.Tip: the ColorEdit* functions have a little color square that can be left-clicked to open a picker, and right-clicked to open an option menu.Default values: flags = ImGui_ColorEditFlags_None
FUNC898 boolean retval, number col_rgba = reaper.ImGui_ColorEdit4(ImGui_Context ctx, string label, number col_rgba, optional number flagsIn)
DESC898 Color is in 0xRRGGBBAA or, if ImGui_ColorEditFlags_NoAlpha is set, 0xXXRRGGBB (XX is ignored and will not be modified).Tip: the ColorEdit* functions have a little color square that can be left-clicked to open a picker, and right-clicked to open an option menu.Default values: flags = ImGui_ColorEditFlags_None
FUNC899 integer reaper.ImGui_ColorEditFlags_AlphaBar()
DESC899 ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
FUNC900 integer reaper.ImGui_ColorEditFlags_AlphaPreview()
DESC900 ColorEdit, ColorPicker, ColorButton: display preview as a transparent color over a checkerboard, instead of opaque.
FUNC901 integer reaper.ImGui_ColorEditFlags_AlphaPreviewHalf()
DESC901 ColorEdit, ColorPicker, ColorButton: display half opaque / half checkerboard, instead of opaque.
FUNC902 integer reaper.ImGui_ColorEditFlags_DisplayHSV()
DESC902 ColorEdit: override _display_ type to HSV. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
FUNC903 integer reaper.ImGui_ColorEditFlags_DisplayHex()
DESC903 ColorEdit: override _display_ type to Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
FUNC904 integer reaper.ImGui_ColorEditFlags_DisplayRGB()
DESC904 ColorEdit: override _display_ type to RGB. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
FUNC905 integer reaper.ImGui_ColorEditFlags_Float()
DESC905 ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
FUNC906 integer reaper.ImGui_ColorEditFlags_InputHSV()
DESC906 ColorEdit, ColorPicker: input and output data in HSV format.
FUNC907 integer reaper.ImGui_ColorEditFlags_InputRGB()
DESC907 ColorEdit, ColorPicker: input and output data in RGB format.
FUNC908 integer reaper.ImGui_ColorEditFlags_NoAlpha()
DESC908 ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
FUNC909 integer reaper.ImGui_ColorEditFlags_NoBorder()
DESC909 ColorButton: disable border (which is enforced by default).
FUNC910 integer reaper.ImGui_ColorEditFlags_NoDragDrop()
DESC910 ColorEdit: disable drag and drop target. ColorButton: disable drag and drop source.
FUNC911 integer reaper.ImGui_ColorEditFlags_NoInputs()
DESC911 ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
FUNC912 integer reaper.ImGui_ColorEditFlags_NoLabel()
DESC912 ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
FUNC913 integer reaper.ImGui_ColorEditFlags_NoOptions()
DESC913 ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
FUNC914 integer reaper.ImGui_ColorEditFlags_NoPicker()
DESC914 ColorEdit: disable picker when clicking on color square.
FUNC915 integer reaper.ImGui_ColorEditFlags_NoSidePreview()
DESC915 ColorPicker: disable bigger color preview on right side of the picker, use small color square preview instead.
FUNC916 integer reaper.ImGui_ColorEditFlags_NoSmallPreview()
DESC916 ColorEdit, ColorPicker: disable color square preview next to the inputs. (e.g. to show only the inputs).
FUNC917 integer reaper.ImGui_ColorEditFlags_NoTooltip()
DESC917 ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
FUNC918 integer reaper.ImGui_ColorEditFlags_None()
DESC918 Flags for ImGui_ColorEdit3 / ImGui_ColorEdit4 / ImGui_ColorPicker3 / ImGui_ColorPicker4 / ImGui_ColorButton.
FUNC919 integer reaper.ImGui_ColorEditFlags_PickerHueBar()
DESC919 ColorPicker: bar for Hue, rectangle for Sat/Value.
FUNC920 integer reaper.ImGui_ColorEditFlags_PickerHueWheel()
DESC920 ColorPicker: wheel for Hue, triangle for Sat/Value.
FUNC921 integer reaper.ImGui_ColorEditFlags_Uint8()
DESC921 ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
FUNC922 integer reaper.ImGui_ColorEditFlags__OptionsDefault()
DESC922 Defaults Options. You can set application defaults using ImGui_SetColorEditOptions. The intent is that you probably don't want to override them in most of your calls. Let the user choose via the option menu and/or call SetColorEditOptions() once during startup.
FUNC923 boolean retval, number col_rgb = reaper.ImGui_ColorPicker3(ImGui_Context ctx, string label, number col_rgb, optional number flagsIn)
DESC923 Color is in 0xXXRRGGBB. XX is ignored and will not be modified.Default values: flags = ImGui_ColorEditFlags_None
FUNC924 boolean retval, number col_rgba = reaper.ImGui_ColorPicker4(ImGui_Context ctx, string label, number col_rgba, optional number flagsIn, optional number ref_colIn)
DESC924 Default values: flags = ImGui_ColorEditFlags_None, ref_col = nil
FUNC925 boolean retval, number current_item, string items = reaper.ImGui_Combo(ImGui_Context ctx, string label, number current_item, string items, optional number popup_max_height_in_itemsIn)
DESC925 Helper over ImGui_BeginCombo/ImGui_EndCombo for convenience purpose. Use \31 (ASCII Unit Separator) to separate items within the string and to terminate it.Default values: popup_max_height_in_items = -1
FUNC926 integer reaper.ImGui_ComboFlags_HeightLarge()
DESC926 Max ~20 items visible.
FUNC927 integer reaper.ImGui_ComboFlags_HeightLargest()
DESC927 As many fitting items as possible.
FUNC928 integer reaper.ImGui_ComboFlags_HeightRegular()
DESC928 Max ~8 items visible (default).
FUNC929 integer reaper.ImGui_ComboFlags_HeightSmall()
DESC929 Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use ImGui_SetNextWindowSizeConstraints prior to calling ImGui_BeginCombo.
FUNC930 integer reaper.ImGui_ComboFlags_NoArrowButton()
DESC930 Display on the preview box without the square arrow button.
FUNC931 integer reaper.ImGui_ComboFlags_NoPreview()
DESC931 Display only a square arrow button.
FUNC932 integer reaper.ImGui_ComboFlags_None()
DESC932 Flags for ImGui_BeginCombo.
FUNC933 integer reaper.ImGui_ComboFlags_PopupAlignLeft()
DESC933 Align the popup toward the left by default.
FUNC934 integer reaper.ImGui_Cond_Always()
DESC934 No condition (always set the variable).
FUNC935 integer reaper.ImGui_Cond_Appearing()
DESC935 Set the variable if the object/window is appearing after being hidden/inactive (or the first time).
FUNC936 integer reaper.ImGui_Cond_FirstUseEver()
DESC936 Set the variable if the object/window has no persistently saved data (no entry in .ini file).
FUNC937 integer reaper.ImGui_Cond_Once()
DESC937 Set the variable once per runtime session (only the first call will succeed).
FUNC938 integer reaper.ImGui_ConfigFlags_DockingEnable()
DESC938 [BETA] Enable docking functionality.
FUNC939 integer reaper.ImGui_ConfigFlags_NavEnableKeyboard()
DESC939 Master keyboard navigation enable flag.
FUNC940 integer reaper.ImGui_ConfigFlags_NavEnableSetMousePos()
DESC940 Instruct navigation to move the mouse cursor.
FUNC941 integer reaper.ImGui_ConfigFlags_NoMouse()
DESC941 Instruct imgui to ignore mouse position/buttons.
FUNC942 integer reaper.ImGui_ConfigFlags_NoMouseCursorChange()
DESC942 Instruct backend to not alter mouse cursor shape and visibility.
FUNC943 integer reaper.ImGui_ConfigFlags_NoSavedSettings()
DESC943 Disable state restoration and persistence for the whole context.
FUNC944 integer reaper.ImGui_ConfigFlags_None()
DESC944 Flags for ImGui_SetConfigFlags.
FUNC945 ImGui_Context reaper.ImGui_CreateContext(string label, optional number config_flagsIn)
DESC945 Create a new ReaImGui context. The context will remain valid as long as it is used in each defer cycle.The label is used for the tab text when windows are docked in REAPER and also as a unique identifier for storing settings.Default values: config_flags = ImGui_ConfigFlags_None
FUNC946 ImGui_Font reaper.ImGui_CreateFont(string family_or_file, integer size, optional number flagsIn)
DESC946 Load a font matching a font family name or from a font file. The font will remain valid while it's attached to a context. See ImGui_AttachFont.The family name can be an installed font or one of the generic fonts: sans-serif, serif, monospace, cursive, fantasy.If 'family_or_file' specifies a path to a font file (contains a / or \):- The first byte of 'flags' is used as the font index within the file- The font styles in 'flags' are simulated by the font rendererDefault values: flags = ImGui_FontFlags_None
FUNC947 ImGui_ListClipper reaper.ImGui_CreateListClipper(ImGui_Context ctx)
DESC947 Helper: Manually clip large list of items.If you are submitting lots of evenly spaced items and you have a random access to the list, you can perform coarseclipping based on visibility to save yourself from processing those items at all.The clipper calculates the range of visible items and advance the cursor to compensate for the non-visible items we have skipped.(Dear ImGui already clip items based on their bounds but it needs to measure text size to do so, whereas manual coarse clipping before submission makes this cost and your own data fetching/submission cost almost null)Usage:
FUNC948 Â Â local clipper = reaper.ImGui_CreateListClipper(ctx)
DESC948 
FUNC949 Â Â reaper.ImGui_ListClipper_Begin(clipper, 1000) -- We have 1000 elements, evenly spaced
DESC949 
FUNC950 Â Â while reaper.ImGui_ListClipper_Step(clipper) do
DESC950 
FUNC951 Â Â Â Â local display_start, display_end = reaper.ImGui_ListClipper_GetDisplayRange(clipper)
DESC951 Â Â Â Â for row = display_start, display_end - 1 do
FUNC952 Â Â Â Â Â Â reaper.ImGui_Text(ctx, ("line number %d"):format(i))
DESC952 Â Â Â Â endGenerally what happens is:- Clipper lets you process the first element (DisplayStart = 0, DisplayEnd = 1) regardless of it being visible or not.- User code submit one element.- Clipper can measure the height of the first element- Clipper calculate the actual range of elements to display based on the current clipping rectangle, position the cursor before the first visible element.- User code submit visible elements.The returned clipper object is tied to the context and is valid as long as it is used in each defer cycle. See ImGui_ListClipper_Begin.
FUNC953 reaper.ImGui_DestroyContext(ImGui_Context ctx)
DESC953 Close and free the resources used by a context.
FUNC954 integer reaper.ImGui_Dir_Down()
DESC954 A cardinal direction.
FUNC955 integer reaper.ImGui_Dir_Left()
DESC955 A cardinal direction.
FUNC956 integer reaper.ImGui_Dir_None()
DESC956 A cardinal direction.
FUNC957 integer reaper.ImGui_Dir_Right()
DESC957 A cardinal direction.
FUNC958 integer reaper.ImGui_Dir_Up()
DESC958 A cardinal direction.
FUNC959 boolean retval, number v = reaper.ImGui_DragDouble(ImGui_Context ctx, string label, number v, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC959 Default values: v_speed = 1.0, v_min = 0.0, v_max = 0.0, format = '%.3f', flags = ImGui_SliderFlags_None
FUNC960 boolean retval, number v1, number v2 = reaper.ImGui_DragDouble2(ImGui_Context ctx, string label, number v1, number v2, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC960 Default values: v_speed = 1.0, v_min = 0.0, v_max = 0.0, format = '%.3f', flags = ImGui_SliderFlags_None
FUNC961 boolean retval, number v1, number v2, number v3 = reaper.ImGui_DragDouble3(ImGui_Context ctx, string label, number v1, number v2, number v3, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC961 Default values: v_speed = 1.0, v_min = 0.0, v_max = 0.0, format = '%.3f', flags = ImGui_SliderFlags_None
FUNC962 boolean retval, number v1, number v2, number v3, number v4 = reaper.ImGui_DragDouble4(ImGui_Context ctx, string label, number v1, number v2, number v3, number v4, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC962 Default values: v_speed = 1.0, v_min = 0.0, v_max = 0.0, format = '%.3f', flags = ImGui_SliderFlags_None
FUNC963 boolean reaper.ImGui_DragDoubleN(ImGui_Context ctx, string labelreaper_array values, optional number speedIn, optional number minIn, optional number maxIn, optional string formatIn, optional number flagsIn)
DESC963 Default values: speed = 1.0, min = nil, max = nil, format = '%.3f', flags = ImGui_SliderFlags_None
FUNC964 integer reaper.ImGui_DragDropFlags_AcceptBeforeDelivery()
DESC964 ImGui_AcceptDragDropPayload will returns true even before the mouse button is released. You can then check ImGui_GetDragDropPayload/is_delivery to test if the payload needs to be delivered.
FUNC965 integer reaper.ImGui_DragDropFlags_AcceptNoDrawDefaultRect()
DESC965 Do not draw the default highlight rectangle when hovering over target.
FUNC966 integer reaper.ImGui_DragDropFlags_AcceptNoPreviewTooltip()
DESC966 Request hiding the ImGui_BeginDragDropSource tooltip from the ImGui_BeginDragDropTarget site.
FUNC967 integer reaper.ImGui_DragDropFlags_AcceptPeekOnly()
DESC967 For peeking ahead and inspecting the payload before delivery. Equivalent to ImGui_DragDropFlags_AcceptBeforeDelivery | ImGui_DragDropFlags_AcceptNoDrawDefaultRect.
FUNC968 integer reaper.ImGui_DragDropFlags_None()
DESC968 Flags for ImGui_BeginDragDropSource, ImGui_AcceptDragDropPayload.
FUNC969 integer reaper.ImGui_DragDropFlags_SourceAllowNullID()
DESC969 Allow items such as ImGui_Text, ImGui_Image that have no unique identifier to be used as drag source, by manufacturing a temporary identifier based on their window-relative position. This is extremely unusual within the dear imgui ecosystem and so we made it explicit.
FUNC970 integer reaper.ImGui_DragDropFlags_SourceAutoExpirePayload()
DESC970 Automatically expire the payload if the source cease to be submitted (otherwise payloads are persisting while being dragged).
FUNC971 integer reaper.ImGui_DragDropFlags_SourceExtern()
DESC971 External source (from outside of dear imgui), won't attempt to read current item/window info. Will always return true. Only one Extern source can be active simultaneously.
FUNC972 integer reaper.ImGui_DragDropFlags_SourceNoDisableHover()
DESC972 By default, when dragging we clear data so that ImGui_IsItemHovered will return false, to avoid subsequent user code submitting tooltips. This flag disable this behavior so you can still call ImGui_IsItemHovered on the source item.
FUNC973 integer reaper.ImGui_DragDropFlags_SourceNoHoldToOpenOthers()
DESC973 Disable the behavior that allows to open tree nodes and collapsing header by holding over them while dragging a source item.
FUNC974 integer reaper.ImGui_DragDropFlags_SourceNoPreviewTooltip()
DESC974 By default, a successful call to ImGui_BeginDragDropSource opens a tooltip so you can display a preview or description of the source contents. This flag disable this behavior.
FUNC975 boolean retval, number v_current_min, number v_current_max = reaper.ImGui_DragFloatRange2(ImGui_Context ctx, string label, number v_current_min, number v_current_max, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional string format_maxIn, optional number flagsIn)
DESC975 Default values: v_speed = 1.0, v_min = 0.0, v_max = 0.0, format = '%.3f', format_max = nil, flags = ImGui_SliderFlags_None
FUNC976 boolean retval, number v = reaper.ImGui_DragInt(ImGui_Context ctx, string label, number v, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC976 - CTRL+Click on any drag box to turn them into an input box. Manually input values aren't clamped and can go off-bounds.- Adjust format string to decorate the value with a prefix, a suffix, or adapt the editing and display precision e.g. "%.3f" -> 1.234; "%5.2f secs" -> 01.23 secs; "Biscuit: %.0f" -> Biscuit: 1; etc.- Format string may also be set to NULL or use the default format ("%f" or "%d").- Speed are per-pixel of mouse movement (v_speed=0.2f: mouse needs to move by 5 pixels to increase value by 1). For gamepad/keyboard navigation, minimum speed is Max(v_speed, minimum_step_at_given_precision).- Use v_min < v_max to clamp edits to given limits. Note that CTRL+Click manual input can override those limits.- Use v_max = FLT_MAX / INT_MAX etc to avoid clamping to a maximum, same with v_min = -FLT_MAX / INT_MIN to avoid clamping to a minimum.- We use the same sets of flags for DragXXX() and SliderXXX() functions as the features are the same and it makes it easier to swap them.Default values: v_speed = 1.0, v_min = 0, v_max = 0, format = '%d', flags = ImGui_SliderFlags_None
FUNC977 boolean retval, number v1, number v2 = reaper.ImGui_DragInt2(ImGui_Context ctx, string label, number v1, number v2, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC977 Default values: v_speed = 1.0, v_min = 0, v_max = 0, format = '%d', flags = ImGui_SliderFlags_None)
FUNC978 boolean retval, number v1, number v2, number v3 = reaper.ImGui_DragInt3(ImGui_Context ctx, string label, number v1, number v2, number v3, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC978 Default values: v_speed = 1.0, v_min = 0, v_max = 0, format = '%d', flags = ImGui_SliderFlags_None)
FUNC979 boolean retval, number v1, number v2, number v3, number v4 = reaper.ImGui_DragInt4(ImGui_Context ctx, string label, number v1, number v2, number v3, number v4, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional number flagsIn)
DESC979 Default values: v_speed = 1.0, v_min = 0, v_max = 0, format = '%d', flags = ImGui_SliderFlags_None)
FUNC980 boolean retval, number v_current_min, number v_current_max = reaper.ImGui_DragIntRange2(ImGui_Context ctx, string label, number v_current_min, number v_current_max, optional number v_speedIn, optional number v_minIn, optional number v_maxIn, optional string formatIn, optional string format_maxIn, optional number flagsIn)
DESC980 Default values: v_speed = 1.0, v_min = 0, v_max = 0, format = '%d', format_max = nil, flags = ImGui_SliderFlags_None
FUNC981 integer reaper.ImGui_DrawFlags_Closed()
DESC981 ImGui_DrawList_PathStroke, ImGui_DrawList_AddPolyline: specify that shape should be closed (Important: this is always == 1 for legacy reason).
FUNC982 integer reaper.ImGui_DrawFlags_None()
DESC982 
FUNC983 integer reaper.ImGui_DrawFlags_RoundCornersAll()
DESC983 
FUNC984 integer reaper.ImGui_DrawFlags_RoundCornersBottom()
DESC984 
FUNC985 integer reaper.ImGui_DrawFlags_RoundCornersBottomLeft()
DESC985 ImGui_DrawList_AddRect, ImGui_DrawList_AddRectFilled, ImGui_DrawList_PathRect: enable rounding bottom-left corner only (when rounding > 0.0f, we default to all corners).
FUNC986 integer reaper.ImGui_DrawFlags_RoundCornersBottomRight()
DESC986 ImGui_DrawList_AddRect, ImGui_DrawList_AddRectFilled, ImGui_DrawList_PathRect: enable rounding bottom-right corner only (when rounding > 0.0f, we default to all corners).
FUNC987 integer reaper.ImGui_DrawFlags_RoundCornersLeft()
DESC987 
FUNC988 integer reaper.ImGui_DrawFlags_RoundCornersNone()
DESC988 ImGui_DrawList_AddRect, ImGui_DrawList_AddRectFilled, ImGui_DrawList_PathRect: disable rounding on all corners (when rounding > 0.0f). This is NOT zero, NOT an implicit flag!.
FUNC989 integer reaper.ImGui_DrawFlags_RoundCornersRight()
DESC989 
FUNC990 integer reaper.ImGui_DrawFlags_RoundCornersTop()
DESC990 
FUNC991 integer reaper.ImGui_DrawFlags_RoundCornersTopLeft()
DESC991 ImGui_DrawList_AddRect, ImGui_DrawList_AddRectFilled, ImGui_DrawList_PathRect: enable rounding top-left corner only (when rounding > 0.0f, we default to all corners).
FUNC992 integer reaper.ImGui_DrawFlags_RoundCornersTopRight()
DESC992 ImGui_DrawList_AddRect, ImGui_DrawList_AddRectFilled, ImGui_DrawList_PathRect: enable rounding top-right corner only (when rounding > 0.0f, we default to all corners).
FUNC993 reaper.ImGui_DrawList_AddBezierCubic(ImGui_DrawList draw_list, number p1_x, number p1_y, number p2_x, number p2_y, number p3_x, number p3_y, number p4_x, number p4_y, integer col_rgba, number thickness, optional number num_segmentsIn)
DESC993 Cubic Bezier (4 control points)Default values: num_segments = 0
FUNC994 reaper.ImGui_DrawList_AddBezierQuadratic(ImGui_DrawList draw_list, number p1_x, number p1_y, number p2_x, number p2_y, number p3_x, number p3_y, integer col_rgba, number thickness, optional number num_segmentsIn)
DESC994 Quadratic Bezier (3 control points)Default values: num_segments = 0
FUNC995 reaper.ImGui_DrawList_AddCircle(ImGui_DrawList draw_list, number center_x, number center_y, number radius, integer col_rgba, optional number num_segmentsIn, optional number thicknessIn)
DESC995 Use "num_segments == 0" to automatically calculate tessellation (preferred).Default values: num_segments = 0, thickness = 1.0
FUNC996 reaper.ImGui_DrawList_AddCircleFilled(ImGui_DrawList draw_list, number center_x, number center_y, number radius, integer col_rgba, optional number num_segmentsIn)
DESC996 Use "num_segments == 0" to automatically calculate tessellation (preferred).Default values: num_segments = 0
FUNC997 reaper.ImGui_DrawList_AddConvexPolyFilled(ImGui_DrawList draw_listreaper_array points, integer num_points, integer col_rgba)
DESC997 Note: Anti-aliased filling requires points to be in clockwise order.
FUNC998 reaper.ImGui_DrawList_AddLine(ImGui_DrawList draw_list, number p1_x, number p1_y, number p2_x, number p2_y, integer col_rgba, optional number thicknessIn)
DESC998 Default values: thickness = 1.0
FUNC999 reaper.ImGui_DrawList_AddNgon(ImGui_DrawList draw_list, number center_x, number center_y, number radius, integer col_rgba, integer num_segments, optional number thicknessIn)
DESC999 Default values: thickness = 1.0
FUNC1000 reaper.ImGui_DrawList_AddNgonFilled(ImGui_DrawList draw_list, number center_x, number center_y, number radius, integer col_rgba, integer num_segments)
DESC1000 
FUNC1001 reaper.ImGui_DrawList_AddPolyline(ImGui_DrawList draw_listreaper_array points, integer col_rgba, integer flags, number thickness)
DESC1001 Points is a list of x,y coordinates.
FUNC1002 reaper.ImGui_DrawList_AddQuad(ImGui_DrawList draw_list, number p1_x, number p1_y, number p2_x, number p2_y, number p3_x, number p3_y, number p4_x, number p4_y, integer col_rgba, optional number thicknessIn)
DESC1002 Default values: thickness = 1.0
FUNC1003 reaper.ImGui_DrawList_AddQuadFilled(ImGui_DrawList draw_list, number p1_x, number p1_y, number p2_x, number p2_y, number p3_x, number p3_y, number p4_x, number p4_y, integer col_rgba)
DESC1003 
FUNC1004 reaper.ImGui_DrawList_AddRect(ImGui_DrawList draw_list, number p_min_x, number p_min_y, number p_max_x, number p_max_y, integer col_rgba, optional number roundingIn, optional number flagsIn, optional number thicknessIn)
DESC1004 Default values: rounding = 0.0, flags = ImGui_DrawFlags_None, thickness = 1.0
FUNC1005 reaper.ImGui_DrawList_AddRectFilled(ImGui_DrawList draw_list, number p_min_x, number p_min_y, number p_max_x, number p_max_y, integer col_rgba, optional number roundingIn, optional number flagsIn)
DESC1005 Default values: rounding = 0.0, flags = ImGui_DrawFlags_None
FUNC1006 reaper.ImGui_DrawList_AddRectFilledMultiColor(ImGui_DrawList draw_list, number p_min_x, number p_min_y, number p_max_x, number p_max_y, integer col_upr_left, integer col_upr_right, integer col_bot_right, integer col_bot_left)
DESC1006 
FUNC1007 reaper.ImGui_DrawList_AddText(ImGui_DrawList draw_list, number x, number y, integer col_rgba, string text)
DESC1007 
FUNC1008 reaper.ImGui_DrawList_AddTextEx(ImGui_DrawList draw_listImGui_Font font, number font_size, number pos_x, number pos_y, integer col_rgba, string text, optional number wrap_widthIn, optional number cpu_fine_clip_rect_xIn, optional number cpu_fine_clip_rect_yIn, optional number cpu_fine_clip_rect_wIn, optional number cpu_fine_clip_rect_hIn)
DESC1008 The default font is used if font = nil. cpu_fine_clip_rect_* only takes effect if all four are non-nil.Default values: wrap_width = 0.0, cpu_fine_clip_rect_x = nil, cpu_fine_clip_rect_y = nil, cpu_fine_clip_rect_w = nil, cpu_fine_clip_rect_h = nil
FUNC1009 reaper.ImGui_DrawList_AddTriangle(ImGui_DrawList draw_list, number p1_x, number p1_y, number p2_x, number p2_y, number p3_x, number p3_y, integer col_rgba, optional number thicknessIn)
DESC1009 Default values: thickness = 1.0
FUNC1010 reaper.ImGui_DrawList_AddTriangleFilled(ImGui_DrawList draw_list, number p1_x, number p1_y, number p2_x, number p2_y, number p3_x, number p3_y, integer col_rgba)
DESC1010 
FUNC1011 reaper.ImGui_DrawList_PathArcTo(ImGui_DrawList draw_list, number center_x, number center_y, number radius, number a_min, number a_max, optional number num_segmentsIn)
DESC1011 Default values: num_segments = 0
FUNC1012 reaper.ImGui_DrawList_PathArcToFast(ImGui_DrawList draw_list, number center_x, number center_y, number radius, integer a_min_of_12, integer a_max_of_12)
DESC1012 Use precomputed angles for a 12 steps circle.
FUNC1013 reaper.ImGui_DrawList_PathBezierCubicCurveTo(ImGui_DrawList draw_list, number p2_x, number p2_y, number p3_x, number p3_y, number p4_x, number p4_y, optional number num_segmentsIn)
DESC1013 Cubic Bezier (4 control points)Default values: num_segments = 0
FUNC1014 reaper.ImGui_DrawList_PathBezierQuadraticCurveTo(ImGui_DrawList draw_list, number p2_x, number p2_y, number p3_x, number p3_y, optional number num_segmentsIn)
DESC1014 Quadratic Bezier (3 control points)Default values: num_segments = 0
FUNC1015 reaper.ImGui_DrawList_PathClear(ImGui_DrawList draw_list)
DESC1015 
FUNC1016 reaper.ImGui_DrawList_PathFillConvex(ImGui_DrawList draw_list, integer col_rgba)
DESC1016 Note: Anti-aliased filling requires points to be in clockwise order.
FUNC1017 reaper.ImGui_DrawList_PathLineTo(ImGui_DrawList draw_list, number pos_x, number pos_y)
DESC1017 Stateful path API, add points then finish with ImGui_DrawList_PathFillConvex or ImGui_DrawList_PathStroke.
FUNC1018 reaper.ImGui_DrawList_PathRect(ImGui_DrawList draw_list, number rect_min_x, number rect_min_y, number rect_max_x, number rect_max_y, optional number roundingIn, optional number flagsIn)
DESC1018 Default values: rounding = 0.0, flags = ImGui_DrawFlags_None
FUNC1019 reaper.ImGui_DrawList_PathStroke(ImGui_DrawList draw_list, integer col_rgba, optional number flagsIn, optional number thicknessIn)
DESC1019 Default values: flags = ImGui_DrawFlags_None, thickness = 1.0
FUNC1020 reaper.ImGui_DrawList_PopClipRect(ImGui_DrawList draw_list)
DESC1020 See DrawList_PushClipRect
FUNC1021 reaper.ImGui_DrawList_PushClipRect(ImGui_DrawList draw_list, number clip_rect_min_x, number clip_rect_min_y, number clip_rect_max_x, number clip_rect_max_y, optional boolean intersect_with_current_clip_rectIn)
DESC1021 Render-level scissoring. Prefer using higher-level ImGui_PushClipRect to affect logic (hit-testing and widget culling).Default values: intersect_with_current_clip_rect = false
FUNC1022 reaper.ImGui_DrawList_PushClipRectFullScreen(ImGui_DrawList draw_list)
DESC1022 
FUNC1023 reaper.ImGui_Dummy(ImGui_Context ctx, number size_w, number size_h)
DESC1023 Add a dummy item of given size. unlike ImGui_InvisibleButton, Dummy() won't take the mouse click or be navigable into.
FUNC1024 reaper.ImGui_End(ImGui_Context ctx)
DESC1024 Pop window from the stack. See ImGui_Begin.
FUNC1025 reaper.ImGui_EndChild(ImGui_Context ctx)
DESC1025 See ImGui_BeginChild.
FUNC1026 reaper.ImGui_EndChildFrame(ImGui_Context ctx)
DESC1026 See ImGui_BeginChildFrame.
FUNC1027 reaper.ImGui_EndCombo(ImGui_Context ctx)
DESC1027 Only call EndCombo() if ImGui_BeginCombo returns true!
FUNC1028 reaper.ImGui_EndDragDropSource(ImGui_Context ctx)
DESC1028 Only call EndDragDropSource() if ImGui_BeginDragDropSource returns true!
FUNC1029 reaper.ImGui_EndDragDropTarget(ImGui_Context ctx)
DESC1029 Only call EndDragDropTarget() if ImGui_BeginDragDropTarget returns true!
FUNC1030 reaper.ImGui_EndGroup(ImGui_Context ctx)
DESC1030 Unlock horizontal starting position + capture the whole group bounding box into one "item" (so you can use ImGui_IsItemHovered or layout primitives such as ImGui_SameLine on whole group, etc.).See ImGui_BeginGroup.
FUNC1031 reaper.ImGui_EndListBox(ImGui_Context ctx)
DESC1031 Only call EndListBox() if ImGui_BeginListBox returned true!
FUNC1032 reaper.ImGui_EndMenu(ImGui_Context ctx)
DESC1032 Only call EndMenu() if ImGui_BeginMenu returns true!
FUNC1033 reaper.ImGui_EndMenuBar(ImGui_Context ctx)
DESC1033 Only call EndMenuBar if ImGui_BeginMenuBar returns true!
FUNC1034 reaper.ImGui_EndPopup(ImGui_Context ctx)
DESC1034 Only call EndPopup() if BeginPopupXXX() returns true!
FUNC1035 reaper.ImGui_EndTabBar(ImGui_Context ctx)
DESC1035 Only call EndTabBar() if BeginTabBar() returns true!
FUNC1036 reaper.ImGui_EndTabItem(ImGui_Context ctx)
DESC1036 Only call EndTabItem() if BeginTabItem() returns true!
FUNC1037 reaper.ImGui_EndTable(ImGui_Context ctx)
DESC1037 Only call EndTable() if BeginTable() returns true!
FUNC1038 reaper.ImGui_EndTooltip(ImGui_Context ctx)
DESC1038 
FUNC1039 integer reaper.ImGui_FocusedFlags_AnyWindow()
DESC1039 ImGui_IsWindowFocused: Return true if any window is focused. Important: If you are trying to tell how to dispatch your low-level inputs, do NOT use this. Use 'io.WantCaptureMouse' instead! Please read the FAQ!.
FUNC1040 integer reaper.ImGui_FocusedFlags_ChildWindows()
DESC1040 ImGui_IsWindowFocused: Return true if any children of the window is focused.
FUNC1041 integer reaper.ImGui_FocusedFlags_None()
DESC1041 Flags for ImGui_IsWindowFocused.
FUNC1042 integer reaper.ImGui_FocusedFlags_RootAndChildWindows()
DESC1042 ImGui_FocusedFlags_RootWindow | ImGui_FocusedFlags_ChildWindows
FUNC1043 integer reaper.ImGui_FocusedFlags_RootWindow()
DESC1043 ImGui_IsWindowFocused: Test from root window (top most parent of the current hierarchy).
FUNC1044 integer reaper.ImGui_FontFlags_Bold()
DESC1044 
FUNC1045 integer reaper.ImGui_FontFlags_Italic()
DESC1045 
FUNC1046 integer reaper.ImGui_FontFlags_None()
DESC1046 
FUNC1047 ImGui_DrawList reaper.ImGui_GetBackgroundDrawList(ImGui_Context ctx)
DESC1047 This draw list will be the first rendering one. Useful to quickly draw shapes/text behind dear imgui contents.
FUNC1048 string reaper.ImGui_GetClipboardText(ImGui_Context ctx)
DESC1048 See ImGui_SetClipboardText.
FUNC1049 integer reaper.ImGui_GetColor(ImGui_Context ctx, integer idx, optional number alpha_mulIn)
DESC1049 Retrieve given style color with style alpha applied and optional extra alpha multiplier, packed as a 32-bit value (RGBA). See ImGui_Col_* for available style colors.Default values: alpha_mul = 1.0
FUNC1050 integer reaper.ImGui_GetColorEx(ImGui_Context ctx, integer col_rgba)
DESC1050 Retrieve given color with style alpha applied, packed as a 32-bit value (RGBA).
FUNC1051 integer reaper.ImGui_GetConfigFlags(ImGui_Context ctx)
DESC1051 See ImGui_SetConfigFlags, ImGui_ConfigFlags_*.
FUNC1052 number x, number y = reaper.ImGui_GetContentRegionAvail(ImGui_Context ctx)
DESC1052 == ImGui_GetContentRegionMax() - ImGui_GetCursorPos()
FUNC1053 number x, number y = reaper.ImGui_GetContentRegionMax(ImGui_Context ctx)
DESC1053 Current content boundaries (typically window boundaries including scrolling, or current column boundaries), in windows coordinates.
FUNC1054 number x, number y = reaper.ImGui_GetCursorPos(ImGui_Context ctx)
DESC1054 Cursor position in window
FUNC1055 number reaper.ImGui_GetCursorPosX(ImGui_Context ctx)
DESC1055 Cursor X position in window
FUNC1056 number reaper.ImGui_GetCursorPosY(ImGui_Context ctx)
DESC1056 Cursor Y position in window
FUNC1057 number x, number y = reaper.ImGui_GetCursorScreenPos(ImGui_Context ctx)
DESC1057 Cursor position in absolute screen coordinates (useful to work with the DrawList API).
FUNC1058 number x, number y = reaper.ImGui_GetCursorStartPos(ImGui_Context ctx)
DESC1058 Initial cursor position in window coordinates.
FUNC1059 number reaper.ImGui_GetDeltaTime(ImGui_Context ctx)
DESC1059 Time elapsed since last frame, in seconds.
FUNC1060 boolean retval, string type, string payload, boolean is_preview, boolean is_delivery = reaper.ImGui_GetDragDropPayload(ImGui_Context ctx)
DESC1060 Peek directly into the current payload from anywhere.
FUNC1061 boolean retval, string filename = reaper.ImGui_GetDragDropPayloadFile(ImGui_Context ctx, integer index)
DESC1061 Get a filename from the list of dropped files. Returns false if index is out of bounds.
FUNC1062 ImGui_Font reaper.ImGui_GetFont(ImGui_Context ctx)
DESC1062 Get the current font
FUNC1063 number reaper.ImGui_GetFontSize(ImGui_Context ctx)
DESC1063 Get current font size (= height in pixels) of current font with current scale applied
FUNC1064 ImGui_DrawList reaper.ImGui_GetForegroundDrawList(ImGui_Context ctx)
DESC1064 This draw list will be the last rendered one. Useful to quickly draw shapes/text over dear imgui contents.
FUNC1065 integer reaper.ImGui_GetFrameCount(ImGui_Context ctx)
DESC1065 Get global imgui frame count. incremented by 1 every frame.
FUNC1066 number reaper.ImGui_GetFrameHeight(ImGui_Context ctx)
DESC1066 ~ ImGui_GetFontSize + ImGui_StyleVar_FramePadding.y * 2
FUNC1067 number reaper.ImGui_GetFrameHeightWithSpacing(ImGui_Context ctx)
DESC1067 ~ ImGui_GetFontSize + ImGui_StyleVar_FramePadding.y * 2 + ImGui_StyleVar_ItemSpacing.y (distance in pixels between 2 consecutive lines of framed widgets)
FUNC1068 boolean retval, number unicode_char = reaper.ImGui_GetInputQueueCharacter(ImGui_Context ctx, integer idx)
DESC1068 Read from ImGui's character input queue. Call with increasing idx until false is returned.
FUNC1069 number x, number y = reaper.ImGui_GetItemRectMax(ImGui_Context ctx)
DESC1069 Get lower-right bounding rectangle of the last item (screen space)
FUNC1070 number x, number y = reaper.ImGui_GetItemRectMin(ImGui_Context ctx)
DESC1070 Get upper-left bounding rectangle of the last item (screen space)
FUNC1071 number w, number h = reaper.ImGui_GetItemRectSize(ImGui_Context ctx)
DESC1071 Get size of last item
FUNC1072 number reaper.ImGui_GetKeyDownDuration(ImGui_Context ctx, integer key_code)
DESC1072 Duration the keyboard key has been down (0.0f == just pressed)
FUNC1073 integer reaper.ImGui_GetKeyMods(ImGui_Context ctx)
DESC1073 Ctrl/Shift/Alt/Super. See ImGui_KeyModFlags_*.
FUNC1074 integer reaper.ImGui_GetKeyPressedAmount(ImGui_Context ctx, integer key_index, number repeat_delay, number rate)
DESC1074 Uses provided repeat rate/delay. return a count, most often 0 or 1 but might be >1 if RepeatRate is small enough that DeltaTime > RepeatRate
FUNC1075 ImGui_Viewport reaper.ImGui_GetMainViewport(ImGui_Context ctx)
DESC1075 Currently represents REAPER's main window (arrange view). This may change in the future.",- Main Area = entire viewport.- Work Area = entire viewport minus sections used by main menu bars (for platform windows), or by task bar (for platform monitor).Windows are generally trying to stay within the Work Area of their host viewport.
FUNC1076 number x, number y = reaper.ImGui_GetMouseClickedPos(ImGui_Context ctx, integer button)
DESC1076 
FUNC1077 integer reaper.ImGui_GetMouseCursor(ImGui_Context ctx)
DESC1077 Get desired cursor type, reset every frame. This is updated during the frame.
FUNC1078 number x, number y = reaper.ImGui_GetMouseDelta(ImGui_Context ctx)
DESC1078 Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.
FUNC1079 number reaper.ImGui_GetMouseDownDuration(ImGui_Context ctx, integer button)
DESC1079 Duration the mouse button has been down (0.0f == just clicked)
FUNC1080 number x, number y = reaper.ImGui_GetMouseDragDelta(ImGui_Context ctx, number x, number y, optional number buttonIn, optional number lock_thresholdIn)
DESC1080 Return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and return 0.0f until the mouse moves past a distance threshold at least once (if lock_threshold < -1.0f, uses io.MouseDraggingThreshold).Default values: button = ImGui_MouseButton_Left, lock_threshold = -1.0
FUNC1081 number x, number y = reaper.ImGui_GetMousePos(ImGui_Context ctx)
DESC1081 
FUNC1082 number x, number y = reaper.ImGui_GetMousePosOnOpeningCurrentPopup(ImGui_Context ctx)
DESC1082 Retrieve mouse position at the time of opening popup we have BeginPopup() into (helper to avoid user backing that value themselves)
FUNC1083 number vertical, number horizontal = reaper.ImGui_GetMouseWheel(ImGui_Context ctx)
DESC1083 Mouse wheel Vertical: 1 unit scrolls about 5 lines text.
FUNC1084 number reaper.ImGui_GetScrollMaxX(ImGui_Context ctx)
DESC1084 Get maximum scrolling amount ~~ ContentSize.x - WindowSize.x - DecorationsSize.x
FUNC1085 number reaper.ImGui_GetScrollMaxY(ImGui_Context ctx)
DESC1085 Get maximum scrolling amount ~~ ContentSize.y - WindowSize.y - DecorationsSize.y
FUNC1086 number reaper.ImGui_GetScrollX(ImGui_Context ctx)
DESC1086 Get scrolling amount [0 .. ImGui_GetScrollMaxX()]
FUNC1087 number reaper.ImGui_GetScrollY(ImGui_Context ctx)
DESC1087 Get scrolling amount [0 .. ImGui_GetScrollMaxY()]
FUNC1088 integer reaper.ImGui_GetStyleColor(ImGui_Context ctx, integer idx)
DESC1088 Retrieve style color as stored in ImGuiStyle structure. Use to feed back into ImGui_PushStyleColor, Otherwise use ImGui_GetColor to get style color with style alpha baked in. See ImGui_Col_* for available style colors.
FUNC1089 string reaper.ImGui_GetStyleColorName(integer idx)
DESC1089 Get a string corresponding to the enum value (for display, saving, etc.).
FUNC1090 number val1, number val2 = reaper.ImGui_GetStyleVar(ImGui_Context ctx, integer var_idx)
DESC1090 
FUNC1091 number reaper.ImGui_GetTextLineHeight(ImGui_Context ctx)
DESC1091 Same as ImGui_GetFontSize
FUNC1092 number reaper.ImGui_GetTextLineHeightWithSpacing(ImGui_Context ctx)
DESC1092 ~ ImGui_GetFontSize + ImGui_StyleVar_ItemSpacing.y (distance in pixels between 2 consecutive lines of text)
FUNC1093 number reaper.ImGui_GetTime(ImGui_Context ctx)
DESC1093 Get global imgui time. Incremented every frame.
FUNC1094 number reaper.ImGui_GetTreeNodeToLabelSpacing(ImGui_Context ctx)
DESC1094 Horizontal distance preceding label when using ImGui_TreeNode*() or ImGui_Bullet() == (ImGui_GetFontSize + ImGui_StyleVar_FramePadding.x*2) for a regular unframed ImGui_TreeNode.
FUNC1095 string imgui_version, string reaimgui_version = reaper.ImGui_GetVersion()
DESC1095 
FUNC1096 number x, number y = reaper.ImGui_GetWindowContentRegionMax(ImGui_Context ctx)
DESC1096 Content boundaries max (roughly (0,0)+Size-Scroll) where Size can be override with ImGui_SetNextWindowContentSize, in window coordinates.
FUNC1097 number x, number y = reaper.ImGui_GetWindowContentRegionMin(ImGui_Context ctx)
DESC1097 Content boundaries min (roughly (0,0)-Scroll), in window coordinates.
FUNC1098 number reaper.ImGui_GetWindowContentRegionWidth(ImGui_Context ctx)
DESC1098 
FUNC1099 integer reaper.ImGui_GetWindowDockID(ImGui_Context ctx)
DESC1099 See ImGui_SetNextWindowDockID.
FUNC1100 ImGui_DrawList reaper.ImGui_GetWindowDrawList(ImGui_Context ctx)
DESC1100 The draw list associated to the current window, to append your own drawing primitives
FUNC1101 number reaper.ImGui_GetWindowHeight(ImGui_Context ctx)
DESC1101 Get current window height (shortcut for ({ImGui_GetWindowSize()})[2])
FUNC1102 number x, number y = reaper.ImGui_GetWindowPos(ImGui_Context ctx)
DESC1102 Get current window position in screen space (useful if you want to do your own drawing via the DrawList API)
FUNC1103 number w, number h = reaper.ImGui_GetWindowSize(ImGui_Context ctx)
DESC1103 Get current window size
FUNC1104 number reaper.ImGui_GetWindowWidth(ImGui_Context ctx)
DESC1104 Get current window width (shortcut for ({ImGui_GetWindowSize()})[1])
FUNC1105 integer reaper.ImGui_HoveredFlags_AllowWhenBlockedByActiveItem()
DESC1105 Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
FUNC1106 integer reaper.ImGui_HoveredFlags_AllowWhenBlockedByPopup()
DESC1106 Return true even if a popup window is normally blocking access to this item/window.
FUNC1107 integer reaper.ImGui_HoveredFlags_AllowWhenDisabled()
DESC1107 Return true even if the item is disabled.
FUNC1108 integer reaper.ImGui_HoveredFlags_AllowWhenOverlapped()
DESC1108 Return true even if the position is obstructed or overlapped by another window.
FUNC1109 integer reaper.ImGui_HoveredFlags_AnyWindow()
DESC1109 ImGui_IsWindowHovered only: Return true if any window is hovered.
FUNC1110 integer reaper.ImGui_HoveredFlags_ChildWindows()
DESC1110 ImGui_IsWindowHovered only: Return true if any children of the window is hovered.
FUNC1111 integer reaper.ImGui_HoveredFlags_None()
DESC1111 Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
FUNC1112 integer reaper.ImGui_HoveredFlags_RectOnly()
DESC1112 ImGui_HoveredFlags_AllowWhenBlockedByPopup | ImGui_HoveredFlags_AllowWhenBlockedByActiveItem | ImGui_HoveredFlags_AllowWhenOverlapped
FUNC1113 integer reaper.ImGui_HoveredFlags_RootAndChildWindows()
DESC1113 ImGui_HoveredFlags_RootWindow | ImGui_HoveredFlags_ChildWindows
FUNC1114 integer reaper.ImGui_HoveredFlags_RootWindow()
DESC1114 ImGui_IsWindowHovered only: Test from root window (top most parent of the current hierarchy).
FUNC1115 reaper.ImGui_Indent(ImGui_Context ctx, optional number indent_wIn)
DESC1115 Move content position toward the right, by 'indent_w', or ImGui_StyleVar_IndentSpacing if 'indent_w' <= 0Default values: indent_w = 0.0
FUNC1116 boolean retval, number v = reaper.ImGui_InputDouble(ImGui_Context ctx, string label, number v, optional number stepIn, optional number step_fastIn, optional string formatIn, optional number flagsIn)
DESC1116 Default values: step = 0.0, step_fast = 0.0, format = '%.3f', flags = ImGui_InputTextFlags_None
FUNC1117 boolean retval, number v1, number v2 = reaper.ImGui_InputDouble2(ImGui_Context ctx, string label, number v1, number v2, optional string formatIn, optional number flagsIn)
DESC1117 Default values: format = '%.3f', flags = ImGui_InputTextFlags_None
FUNC1118 boolean retval, number v1, number v2, number v3 = reaper.ImGui_InputDouble3(ImGui_Context ctx, string label, number v1, number v2, number v3, optional string formatIn, optional number flagsIn)
DESC1118 Default values: format = '%.3f', flags = ImGui_InputTextFlags_None
FUNC1119 boolean retval, number v1, number v2, number v3, number v4 = reaper.ImGui_InputDouble4(ImGui_Context ctx, string label, number v1, number v2, number v3, number v4, optional string formatIn, optional number flagsIn)
DESC1119 Default values: format = '%.3f', flags = ImGui_InputTextFlags_None
FUNC1120 boolean reaper.ImGui_InputDoubleN(ImGui_Context ctx, string labelreaper_array values, optional number stepIn, optional number step_fastIn, optional string formatIn, optional number flagsIn)
DESC1120 Default values: step = nil, format = nil, step_fast = nil, format = '%.3f', flags = ImGui_InputTextFlags_None
FUNC1121 boolean retval, number v = reaper.ImGui_InputInt(ImGui_Context ctx, string label, number v, optional number stepIn, optional number step_fastIn, optional number flagsIn)
DESC1121 Default values: step = 1, step_fast = 100, flags = ImGui_InputTextFlags_None
FUNC1122 boolean retval, number v1, number v2 = reaper.ImGui_InputInt2(ImGui_Context ctx, string label, number v1, number v2, optional number flagsIn)
DESC1122 Default values: flags = ImGui_InputTextFlags_None
FUNC1123 boolean retval, number v1, number v2, number v3 = reaper.ImGui_InputInt3(ImGui_Context ctx, string label, number v1, number v2, number v3, optional number flagsIn)
DESC1123 Default values: flags = ImGui_InputTextFlags_None
FUNC1124 boolean retval, number v1, number v2, number v3, number v4 = reaper.ImGui_InputInt4(ImGui_Context ctx, string label, number v1, number v2, number v3, number v4, optional number flagsIn)
DESC1124 Default values: flags = ImGui_InputTextFlags_None
FUNC1125 boolean retval, string buf = reaper.ImGui_InputText(ImGui_Context ctx, string label, string buf, optional number flagsIn)
DESC1125 Default values: flags = ImGui_InputTextFlags_None
FUNC1126 integer reaper.ImGui_InputTextFlags_AllowTabInput()
DESC1126 Pressing TAB input a '\t' character into the text field.
FUNC1127 integer reaper.ImGui_InputTextFlags_AlwaysOverwrite()
DESC1127 Overwrite mode.
FUNC1128 integer reaper.ImGui_InputTextFlags_AutoSelectAll()
DESC1128 Select entire text when first taking mouse focus.
FUNC1129 integer reaper.ImGui_InputTextFlags_CharsDecimal()
DESC1129 Allow 0123456789.+-*/.
FUNC1130 integer reaper.ImGui_InputTextFlags_CharsHexadecimal()
DESC1130 Allow 0123456789ABCDEFabcdef.
FUNC1131 integer reaper.ImGui_InputTextFlags_CharsNoBlank()
DESC1131 Filter out spaces, tabs.
FUNC1132 integer reaper.ImGui_InputTextFlags_CharsScientific()
DESC1132 Allow 0123456789.+-*/eE (Scientific notation input).
FUNC1133 integer reaper.ImGui_InputTextFlags_CharsUppercase()
DESC1133 Turn a..z into A..Z.
FUNC1134 integer reaper.ImGui_InputTextFlags_CtrlEnterForNewLine()
DESC1134 In multi-line mode, unfocus with Enter, add new line with Ctrl+Enter (default is opposite: unfocus with Ctrl+Enter, add line with Enter).
FUNC1135 integer reaper.ImGui_InputTextFlags_EnterReturnsTrue()
DESC1135 Return 'true' when Enter is pressed (as opposed to every time the value was modified). Consider looking at the ImGui_IsItemDeactivatedAfterEdit function.
FUNC1136 integer reaper.ImGui_InputTextFlags_NoHorizontalScroll()
DESC1136 Disable following the cursor horizontally.
FUNC1137 integer reaper.ImGui_InputTextFlags_NoUndoRedo()
DESC1137 Disable undo/redo. Note that input text owns the text data while active.
FUNC1138 integer reaper.ImGui_InputTextFlags_None()
DESC1138 Most of the InputTextFlags flags are only useful for ImGui_InputText and not for InputIntX, InputDouble etc.
FUNC1139 integer reaper.ImGui_InputTextFlags_Password()
DESC1139 Password mode, display all characters as '*'.
FUNC1140 integer reaper.ImGui_InputTextFlags_ReadOnly()
DESC1140 Read-only mode.
FUNC1141 boolean retval, string buf = reaper.ImGui_InputTextMultiline(ImGui_Context ctx, string label, string buf, optional number size_wIn, optional number size_hIn, optional number flagsIn)
DESC1141 Default values: size_w = 0.0, size_h = 0.0, flags = ImGui_InputTextFlags_None
FUNC1142 boolean retval, string buf = reaper.ImGui_InputTextWithHint(ImGui_Context ctx, string label, string hint, string buf, optional number flagsIn)
DESC1142 Default values: flags = ImGui_InputTextFlags_None
FUNC1143 boolean reaper.ImGui_InvisibleButton(ImGui_Context ctx, string str_id, number size_w, number size_h, optional number flagsIn)
DESC1143 Flexible button behavior without the visuals, frequently useful to build custom behaviors using the public api (along with ImGui_IsItemActive, ImGui_IsItemHovered, etc.).Default values: flags = ImGui_ButtonFlags_None
FUNC1144 boolean reaper.ImGui_IsAnyItemActive(ImGui_Context ctx)
DESC1144 
FUNC1145 boolean reaper.ImGui_IsAnyItemFocused(ImGui_Context ctx)
DESC1145 
FUNC1146 boolean reaper.ImGui_IsAnyItemHovered(ImGui_Context ctx)
DESC1146 
FUNC1147 boolean reaper.ImGui_IsAnyMouseDown(ImGui_Context ctx)
DESC1147 Is any mouse button held?
FUNC1148 boolean reaper.ImGui_IsItemActivated(ImGui_Context ctx)
DESC1148 Was the last item just made active (item was previously inactive).
FUNC1149 boolean reaper.ImGui_IsItemActive(ImGui_Context ctx)
DESC1149 Is the last item active? (e.g. button being held, text field being edited. This will continuously return true while holding mouse button on an item. Items that don't interact will always return false)
FUNC1150 boolean reaper.ImGui_IsItemClicked(ImGui_Context ctx, optional number mouse_buttonIn)
DESC1150 Is the last item clicked? (e.g. button/node just clicked on) == ImGui_IsMouseClicked(mouse_button) && ImGui_IsItemHovered().This is NOT equivalent to the behavior of e.g. ImGui_Button. Most widgets have specific reactions based on mouse-up/down state, mouse position etc.Default values: mouse_button = ImGui_MouseButton_Left
FUNC1151 boolean reaper.ImGui_IsItemDeactivated(ImGui_Context ctx)
DESC1151 Was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that requires continuous editing.
FUNC1152 boolean reaper.ImGui_IsItemDeactivatedAfterEdit(ImGui_Context ctx)
DESC1152 Was the last item just made inactive and made a value change when it was active? (e.g. Slider/Drag moved). Useful for Undo/Redo patterns with widgets that requires continuous editing. Note that you may get false positives (some widgets such as ImGui_Combo/ImGui_ListBox/ImGui_Selectable will return true even when clicking an already selected item).
FUNC1153 boolean reaper.ImGui_IsItemEdited(ImGui_Context ctx)
DESC1153 Did the last item modify its underlying value this frame? or was pressed? This is generally the same as the "bool" return value of many widgets.
FUNC1154 boolean reaper.ImGui_IsItemFocused(ImGui_Context ctx)
DESC1154 Is the last item focused for keyboard/gamepad navigation?
FUNC1155 boolean reaper.ImGui_IsItemHovered(ImGui_Context ctx, optional number flagsIn)
DESC1155 Is the last item hovered? (and usable, aka not blocked by a popup, etc.). See ImGui_HoveredFlags_* for more options.Default values: flags = ImGui_HoveredFlags_None
FUNC1156 boolean reaper.ImGui_IsItemToggledOpen(ImGui_Context ctx)
DESC1156 Was the last item open state toggled? Set by ImGui_TreeNode.
FUNC1157 boolean reaper.ImGui_IsItemVisible(ImGui_Context ctx)
DESC1157 Is the last item visible? (items may be out of sight because of clipping/scrolling)
FUNC1158 boolean reaper.ImGui_IsKeyDown(ImGui_Context ctx, integer key_code)
DESC1158 Is key being held.
FUNC1159 boolean reaper.ImGui_IsKeyPressed(ImGui_Context ctx, integer key_code, optional boolean repeatIn)
DESC1159 Was key pressed (went from !Down to Down)? if repeat=true, uses io.KeyRepeatDelay / KeyRepeatRateDefault values: repeat = true
FUNC1160 boolean reaper.ImGui_IsKeyReleased(ImGui_Context ctx, integer key_code)
DESC1160 Was key released (went from Down to !Down)?
FUNC1161 boolean reaper.ImGui_IsMouseClicked(ImGui_Context ctx, integer button, optional boolean repeatIn)
DESC1161 Did mouse button clicked? (went from !Down to Down)Default values: repeat = false
FUNC1162 boolean reaper.ImGui_IsMouseDoubleClicked(ImGui_Context ctx, integer button)
DESC1162 Did mouse button double-clicked? (note that a double-click will also report ImGui_IsMouseClicked() == true)
FUNC1163 boolean reaper.ImGui_IsMouseDown(ImGui_Context ctx, integer button)
DESC1163 Is mouse button held?
FUNC1164 boolean reaper.ImGui_IsMouseDragging(ImGui_Context ctx, integer button, optional number lock_thresholdIn)
DESC1164 Is mouse dragging? (if lock_threshold < -1.0, uses io.MouseDraggingThreshold)Default values: lock_threshold = -1.0
FUNC1165 boolean reaper.ImGui_IsMouseHoveringRect(ImGui_Context ctx, number r_min_x, number r_min_y, number r_max_x, number r_max_y, optional boolean clipIn)
DESC1165 Is mouse hovering given bounding rect (in screen space). clipped by current clipping settings, but disregarding of other consideration of focus/window ordering/popup-block.Default values: clip = true
FUNC1166 boolean reaper.ImGui_IsMousePosValid(ImGui_Context ctx, optional number mouse_pos_xIn, optional number mouse_pos_yIn)
DESC1166 Default values: mouse_pos_x = nil, mouse_pos_y = nil
FUNC1167 boolean reaper.ImGui_IsMouseReleased(ImGui_Context ctx, integer button)
DESC1167 Did mouse button released? (went from Down to !Down)
FUNC1168 boolean reaper.ImGui_IsPopupOpen(ImGui_Context ctx, string str_id, optional number flagsIn)
DESC1168 Return true if the popup is open at the current ImGui_BeginPopup level of the popup stack.With ImGui_PopupFlags_AnyPopupId: return true if any popup is open at the current BeginPopup() level of the popup stack.With ImGui_PopupFlags_AnyPopupId + ImGui_PopupFlags_AnyPopupLevel: return true if any popup is open.Default values: flags = ImGui_PopupFlags_None
FUNC1169 boolean reaper.ImGui_IsRectVisible(ImGui_Context ctx, number size_w, number size_h)
DESC1169 Test if rectangle (of given size, starting from cursor position) is visible / not clipped.
FUNC1170 boolean reaper.ImGui_IsRectVisibleEx(ImGui_Context ctx, number rect_min_x, number rect_min_y, number rect_max_x, number rect_max_y)
DESC1170 Test if rectangle (in screen space) is visible / not clipped. to perform coarse clipping on user's side.
FUNC1171 boolean reaper.ImGui_IsWindowAppearing(ImGui_Context ctx)
DESC1171 
FUNC1172 boolean reaper.ImGui_IsWindowCollapsed(ImGui_Context ctx)
DESC1172 
FUNC1173 boolean reaper.ImGui_IsWindowDocked(ImGui_Context ctx)
DESC1173 Is current window docked into another window or a REAPER docker?
FUNC1174 boolean reaper.ImGui_IsWindowFocused(ImGui_Context ctx, optional number flagsIn)
DESC1174 Is current window focused? or its root/child, depending on flags. see flags for options.Default values: flags = ImGui_FocusedFlags_None
FUNC1175 boolean reaper.ImGui_IsWindowHovered(ImGui_Context ctx, optional number flagsIn)
DESC1175 Is current window hovered (and typically: not blocked by a popup/modal)? see flags for options.Default values: flags = ImGui_HoveredFlags_None
FUNC1176 integer reaper.ImGui_KeyModFlags_Alt()
DESC1176 
FUNC1177 integer reaper.ImGui_KeyModFlags_Ctrl()
DESC1177 
FUNC1178 integer reaper.ImGui_KeyModFlags_None()
DESC1178 
FUNC1179 integer reaper.ImGui_KeyModFlags_Shift()
DESC1179 
FUNC1180 integer reaper.ImGui_KeyModFlags_Super()
DESC1180 
FUNC1181 reaper.ImGui_LabelText(ImGui_Context ctx, string label, string text)
DESC1181 Display text+label aligned the same way as value+label widgets
FUNC1182 boolean retval, number current_item, string items = reaper.ImGui_ListBox(ImGui_Context ctx, string label, number current_item, string items, optional number height_in_itemsIn)
DESC1182 This is an helper over ImGui_BeginListBox/ImGui_EndListBox for convenience purpose. This is analoguous to how Combos are created.Use \31 (ASCII Unit Separator) to separate items within the string and to terminate it.Default values: height_in_items = -1
FUNC1183 reaper.ImGui_ListClipper_Begin(ImGui_ListClipper clipper, integer items_count, optional number items_heightIn)
DESC1183 items_count: Use INT_MAX if you don't know how many items you have (in which case the cursor won't be advanced in the final step)items_height: Use -1.0f to be calculated automatically on first step. Otherwise pass in the distance between your items, typically ImGui_GetTextLineHeightWithSpacing or ImGui_GetFrameHeightWithSpacing.Default values: items_height = -1.0
FUNC1184 reaper.ImGui_ListClipper_End(ImGui_ListClipper clipper)
DESC1184 Automatically called on the last call of ImGui_ListClipper_Step that returns false.
FUNC1185 number display_start, number display_end = reaper.ImGui_ListClipper_GetDisplayRange(ImGui_ListClipper clipper)
DESC1185 
FUNC1186 boolean reaper.ImGui_ListClipper_Step(ImGui_ListClipper clipper)
DESC1186 Call until it returns false. The display_start/display_end fields from ImGui_ListClipper_GetDisplayRange will be set and you can process/draw those items.
FUNC1187 reaper.ImGui_LogFinish(ImGui_Context ctx)
DESC1187 Stop logging (close file, etc.)
FUNC1188 reaper.ImGui_LogText(ImGui_Context ctx, string text)
DESC1188 Pass text data straight to log (without being displayed)
FUNC1189 reaper.ImGui_LogToClipboard(ImGui_Context ctx, optional number auto_open_depthIn)
DESC1189 Start logging all text output from the interface to the OS clipboard. By default, tree nodes are automatically opened during logging. See also ImGui_SetClipboardText.Default values: auto_open_depth = -1
FUNC1190 reaper.ImGui_LogToFile(ImGui_Context ctx, optional number auto_open_depthIn, optional string filenameIn)
DESC1190 Start logging all text output from the interface to a file. By default, tree nodes are automatically opened during logging. The data is saved to $resource_path/imgui_log.txt if filename is nil.Default values: auto_open_depth = -1, filename = nil
FUNC1191 reaper.ImGui_LogToTTY(ImGui_Context ctx, optional number auto_open_depthIn)
DESC1191 Start logging all text output from the interface to the TTY (stdout). By default, tree nodes are automatically opened during logging.Default values: auto_open_depth = -1
FUNC1192 boolean retval, optional boolean p_selected = reaper.ImGui_MenuItem(ImGui_Context ctx, string label, optional string shortcutIn, optional boolean p_selected, optional boolean enabledIn)
DESC1192 Return true when activated. Shortcuts are displayed for convenience but not processed by ImGui at the moment. Toggle state is written to 'selected' when provided.Default values: enabled = true
FUNC1193 integer reaper.ImGui_MouseButton_Left()
DESC1193 
FUNC1194 integer reaper.ImGui_MouseButton_Middle()
DESC1194 
FUNC1195 integer reaper.ImGui_MouseButton_Right()
DESC1195 
FUNC1196 integer reaper.ImGui_MouseCursor_Arrow()
DESC1196 
FUNC1197 integer reaper.ImGui_MouseCursor_Hand()
DESC1197 (Unused by Dear ImGui functions. Use for e.g. hyperlinks)
FUNC1198 integer reaper.ImGui_MouseCursor_NotAllowed()
DESC1198 When hovering something with disallowed interaction. Usually a crossed circle.
FUNC1199 integer reaper.ImGui_MouseCursor_ResizeAll()
DESC1199 (Unused by Dear ImGui functions)
FUNC1200 integer reaper.ImGui_MouseCursor_ResizeEW()
DESC1200 When hovering over a vertical border or a column.
FUNC1201 integer reaper.ImGui_MouseCursor_ResizeNESW()
DESC1201 When hovering over the bottom-left corner of a window.
FUNC1202 integer reaper.ImGui_MouseCursor_ResizeNS()
DESC1202 When hovering over an horizontal border.
FUNC1203 integer reaper.ImGui_MouseCursor_ResizeNWSE()
DESC1203 When hovering over the bottom-right corner of a window.
FUNC1204 integer reaper.ImGui_MouseCursor_TextInput()
DESC1204 When hovering over ImGui_InputText, etc.
FUNC1205 reaper.ImGui_NewLine(ImGui_Context ctx)
DESC1205 Undo a SameLine() or force a new line when in an horizontal-layout context.
FUNC1206 number min, number max = reaper.ImGui_NumericLimits_Float()
DESC1206 Returns FLT_MIN and FLT_MAX for this system.
FUNC1207 reaper.ImGui_OpenPopup(ImGui_Context ctx, string str_id, optional number popup_flagsIn)
DESC1207 Set popup state to open (don't call every frame!). ImGuiPopupFlags are available for opening options.If not modal: they can be closed by clicking anywhere outside them, or by pressing ESCAPE.Use ImGui_PopupFlags_NoOpenOverExistingPopup to avoid opening a popup if there's already one at the same level.Default values: popup_flags = ImGui_PopupFlags_None
FUNC1208 reaper.ImGui_OpenPopupOnItemClick(ImGui_Context ctx, optional string str_idIn, optional number popup_flagsIn)
DESC1208 Helper to open popup when clicked on last item. return true when just opened. (note: actually triggers on the mouse _released_ event to be consistent with popup behaviors)Default values: str_id = nil, popup_flags = ImGui_PopupFlags_MouseButtonRight
FUNC1209 reaper.ImGui_PlotHistogram(ImGui_Context ctx, string labelreaper_array values, optional number values_offsetIn, optional string overlay_textIn, optional number scale_minIn, optional number scale_maxIn, optional number graph_size_wIn, optional number graph_size_hIn)
DESC1209 Default values: values_offset = 0, overlay_text = nil, scale_min = FLT_MAX, scale_max = FLT_MAX, graph_size_w = 0.0, graph_size_h = 0.0
FUNC1210 reaper.ImGui_PlotLines(ImGui_Context ctx, string labelreaper_array values, optional number values_offsetIn, optional string overlay_textIn, optional number scale_minIn, optional number scale_maxIn, optional number graph_size_wIn, optional number graph_size_hIn)
DESC1210 Default values: values_offset = 0, overlay_text = nil, scale_min = 0.0, scale_max = 0.0, graph_size_w = 0.0, graph_size_h = 0.0
FUNC1211 number x, number y = reaper.ImGui_PointConvertNative(ImGui_Context ctx, number x, number y, optional boolean to_nativeIn)
DESC1211 Convert a position from the current platform's native coordinate position system to ReaImGui global coordinates (or vice versa).This flips the Y coordinate on macOS and applies HiDPI scaling on Windows and Linux.Default values: to_native = false
FUNC1212 reaper.ImGui_PopAllowKeyboardFocus(ImGui_Context ctx)
DESC1212 See ImGui_PushAllowKeyboardFocus
FUNC1213 reaper.ImGui_PopButtonRepeat(ImGui_Context ctx)
DESC1213 See ImGui_PushButtonRepeat
FUNC1214 reaper.ImGui_PopClipRect(ImGui_Context ctx)
DESC1214 See ImGui_PushClipRect
FUNC1215 reaper.ImGui_PopFont(ImGui_Context ctx)
DESC1215 See ImGui_PushFont.
FUNC1216 reaper.ImGui_PopID(ImGui_Context ctx)
DESC1216 Pop from the ID stack.
FUNC1217 reaper.ImGui_PopItemWidth(ImGui_Context ctx)
DESC1217 See ImGui_PushItemWidth
FUNC1218 reaper.ImGui_PopStyleColor(ImGui_Context ctx, optional number countIn)
DESC1218 Default values: count = 1
FUNC1219 reaper.ImGui_PopStyleVar(ImGui_Context ctx, optional number countIn)
DESC1219 Reset a style variable.Default values: count = 1
FUNC1220 reaper.ImGui_PopTextWrapPos(ImGui_Context ctx)
DESC1220 
FUNC1221 integer reaper.ImGui_PopupFlags_AnyPopup()
DESC1221 ImGui_PopupFlags_AnyPopupId | ImGui_PopupFlags_AnyPopupLevel
FUNC1222 integer reaper.ImGui_PopupFlags_AnyPopupId()
DESC1222 For ImGui_IsPopupOpen: ignore the str_id parameter and test for any popup.
FUNC1223 integer reaper.ImGui_PopupFlags_AnyPopupLevel()
DESC1223 For ImGui_IsPopupOpen: search/test at any level of the popup stack (default test in the current level).
FUNC1224 integer reaper.ImGui_PopupFlags_MouseButtonLeft()
DESC1224 For BeginPopupContext*(): open on Left Mouse release. Guaranteed to always be == 0 (same as ImGui_MouseButton_Left).
FUNC1225 integer reaper.ImGui_PopupFlags_MouseButtonMiddle()
DESC1225 For BeginPopupContext*(): open on Middle Mouse release. Guaranteed to always be == 2 (same as ImGui_MouseButton_Middle).
FUNC1226 integer reaper.ImGui_PopupFlags_MouseButtonRight()
DESC1226 For BeginPopupContext*(): open on Right Mouse release. Guaranteed to always be == 1 (same as ImGui_MouseButton_Right).
FUNC1227 integer reaper.ImGui_PopupFlags_NoOpenOverExistingPopup()
DESC1227 For OpenPopup*(), BeginPopupContext*(): don't open if there's already a popup at the same level of the popup stack.
FUNC1228 integer reaper.ImGui_PopupFlags_NoOpenOverItems()
DESC1228 For ImGui_BeginPopupContextWindow: don't return true when hovering items, only when hovering empty space.
FUNC1229 integer reaper.ImGui_PopupFlags_None()
DESC1229 Flags for OpenPopup*(), BeginPopupContext*(), ImGui_IsPopupOpen.
FUNC1230 reaper.ImGui_ProgressBar(ImGui_Context ctx, number fraction, optional number size_arg_wIn, optional number size_arg_hIn, optional string overlayIn)
DESC1230 Default values: size_arg_w = -FLT_MIN, size_arg_h = 0.0, overlay = nil
FUNC1231 reaper.ImGui_PushAllowKeyboardFocus(ImGui_Context ctx, boolean allow_keyboard_focus)
DESC1231 Allow focusing using TAB/Shift-TAB, enabled by default but you can disable it for certain widgets
FUNC1232 reaper.ImGui_PushButtonRepeat(ImGui_Context ctx, boolean repeat)
DESC1232 In 'repeat' mode, Button*() functions return repeated true in a typematic manner (using io.KeyRepeatDelay/io.KeyRepeatRate setting). Note that you can call ImGui_IsItemActive after any ImGui_Button to tell if the button is held in the current frame.
FUNC1233 reaper.ImGui_PushClipRect(ImGui_Context ctx, number clip_rect_min_x, number clip_rect_min_y, number clip_rect_max_x, number clip_rect_max_y, boolean intersect_with_current_clip_rect)
DESC1233 Mouse hovering is affected by PushClipRect() calls, unlike direct calls to ImGui_DrawList_PushClipRect which are render only. See ImGui_PopClipRect.
FUNC1234 reaper.ImGui_PushFont(ImGui_Context ctxImGui_Font font)
DESC1234 Change the current font. Use nil to push the default font. See ImGui_PopFont.
FUNC1235 reaper.ImGui_PushID(ImGui_Context ctx, string str_id)
DESC1235 Push string into the ID stack. Read the FAQ for more details about how ID are handled in dear imgui.If you are creating widgets in a loop you most likely want to push a unique identifier (e.g. object pointer, loop index) to uniquely differentiate them.You can also use the "Label##foobar" syntax within widget label to distinguish them from each others.
FUNC1236 reaper.ImGui_PushItemWidth(ImGui_Context ctx, number item_width)
DESC1236 Push width of items for common large "item+label" widgets. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side). 0.0f = default to ~2/3 of windows width,
FUNC1237 reaper.ImGui_PushStyleColor(ImGui_Context ctx, integer idx, integer col_rgba)
DESC1237 Modify a style color. Call ImGui_PopStyleColor to undo after use (before the end of the frame). See ImGui_Col_* for available style colors.
FUNC1238 reaper.ImGui_PushStyleVar(ImGui_Context ctx, integer var_idx, number val1, optional number val2In)
DESC1238 See ImGui_StyleVar_* for possible values of 'var_idx'.Default values: val2 = nil
FUNC1239 reaper.ImGui_PushTextWrapPos(ImGui_Context ctx, optional number wrap_local_pos_xIn)
DESC1239 Push word-wrapping position for Text*() commands. < 0.0f: no wrapping; 0.0f: wrap to end of window (or column); > 0.0f: wrap at 'wrap_pos_x' position in window local space.Default values: wrap_local_pos_x = 0.0
FUNC1240 boolean reaper.ImGui_RadioButton(ImGui_Context ctx, string label, boolean active)
DESC1240 Use with e.g. if (RadioButton("one", my_value==1)) { my_value = 1; }
FUNC1241 boolean retval, number v = reaper.ImGui_RadioButtonEx(ImGui_Context ctx, string label, number v, integer v_button)
DESC1241 Shortcut to handle RadioButton's example pattern when value is an integer
FUNC1242 reaper.ImGui_ResetMouseDragDelta(ImGui_Context ctx, optional number buttonIn)
DESC1242 Default values: button = ImGui_MouseButton_Left
FUNC1243 reaper.ImGui_SameLine(ImGui_Context ctx, optional number offset_from_start_xIn, optional number spacingIn)
DESC1243 Call between widgets or groups to layout them horizontally. X position given in window coordinates.Default values: offset_from_start_x = 0.0, spacing = -1.0.
FUNC1244 boolean retval, boolean p_selected = reaper.ImGui_Selectable(ImGui_Context ctx, string label, boolean p_selected, optional number flagsIn, optional number size_wIn, optional number size_hIn)
DESC1244 A selectable highlights when hovered, and can display another color when selected.Neighbors selectable extend their highlight bounds in order to leave no gap between them. This is so a series of selected Selectable appear contiguous.Default values: flags = ImGui_SelectableFlags_None, size_w = 0.0, size_h = 0.0
FUNC1245 integer reaper.ImGui_SelectableFlags_AllowDoubleClick()
DESC1245 Generate press events on double clicks too.
FUNC1246 integer reaper.ImGui_SelectableFlags_AllowItemOverlap()
DESC1246 Hit testing to allow subsequent widgets to overlap this one.
FUNC1247 integer reaper.ImGui_SelectableFlags_Disabled()
DESC1247 Cannot be selected, display grayed out text.
FUNC1248 integer reaper.ImGui_SelectableFlags_DontClosePopups()
DESC1248 Clicking this don't close parent popup window.
FUNC1249 integer reaper.ImGui_SelectableFlags_None()
DESC1249 Flags for ImGui_Selectable.
FUNC1250 integer reaper.ImGui_SelectableFlags_SpanAllColumns()
DESC1250 Selectable frame can span all columns (text will still fit in current column).
FUNC1251 reaper.ImGui_Separator(ImGui_Context ctx)
DESC1251 Separator, generally horizontal. inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
FUNC1252 reaper.ImGui_SetClipboardText(ImGui_Context ctx, string text)
DESC1252 See also the ImGui_LogToClipboard function to capture GUI into clipboard, or easily output text data to the clipboard.
FUNC1253 reaper.ImGui_SetColorEditOptions(ImGui_Context ctx, integer flags)
DESC1253 Picker type, etc. User will be able to change many settings, unless you pass the _NoOptions flag to your calls.
FUNC1254 reaper.ImGui_SetConfigFlags(ImGui_Context ctx, integer flags)
DESC1254 See ImGui_GetConfigFlags, ImGui_ConfigFlags_*.
FUNC1255 reaper.ImGui_SetCursorPos(ImGui_Context ctx, number local_pos_x, number local_pos_y)
DESC1255 Cursor position in window
FUNC1256 reaper.ImGui_SetCursorPosX(ImGui_Context ctx, number local_x)
DESC1256 Cursor X position in window
FUNC1257 reaper.ImGui_SetCursorPosY(ImGui_Context ctx, number local_y)
DESC1257 Cursor Y position in window
FUNC1258 reaper.ImGui_SetCursorScreenPos(ImGui_Context ctx, number pos_x, number pos_y)
DESC1258 Cursor position in absolute screen coordinates.
FUNC1259 boolean reaper.ImGui_SetDragDropPayload(ImGui_Context ctx, string type, string data, optional number condIn)
DESC1259 type is a user defined string of maximum 32 characters. Strings starting with '_' are reserved for dear imgui internal types. Data is copied and held by imgui.Default values: cond = ImGui_Cond_Always
FUNC1260 reaper.ImGui_SetItemAllowOverlap(ImGui_Context ctx)
DESC1260 Allow last item to be overlapped by a subsequent item. sometimes useful with invisible buttons, selectables, etc. to catch unused area.
FUNC1261 reaper.ImGui_SetItemDefaultFocus(ImGui_Context ctx)
DESC1261 Make last item the default focused item of a window.Prefer using "SetItemDefaultFocus()" over "if (ImGui_IsWindowAppearing()) ImGui_SetScrollHereY()" when applicable to signify "this is the default item"
FUNC1262 reaper.ImGui_SetKeyboardFocusHere(ImGui_Context ctx, optional number offsetIn)
DESC1262 Focus keyboard on the next widget. Use positive 'offset' to access sub components of a multiple component widget. Use -1 to access previous widget.Default values: offset = 0
FUNC1263 reaper.ImGui_SetMouseCursor(ImGui_Context ctx, integer cursor_type)
DESC1263 Set desired cursor type
FUNC1264 reaper.ImGui_SetNextItemOpen(ImGui_Context ctx, boolean is_open, optional number condIn)
DESC1264 Set next ImGui_TreeNode/ImGui_CollapsingHeader open state. Can also be done with the ImGui_TreeNodeFlags_DefaultOpen flag.Default values: cond = ImGui_Cond_Always.
FUNC1265 reaper.ImGui_SetNextItemWidth(ImGui_Context ctx, number item_width)
DESC1265 Set width of the _next_ common large "item+label" widget. >0.0f: width in pixels, <0.0f align xx pixels to the right of window (so -FLT_MIN always align width to the right side)
FUNC1266 reaper.ImGui_SetNextWindowBgAlpha(ImGui_Context ctx, number alpha)
DESC1266 Set next window background color alpha. helper to easily override the Alpha component of ImGui_Col_WindowBg/ChildBg/PopupBg. you may also use ImGui_WindowFlags_NoBackground.
FUNC1267 reaper.ImGui_SetNextWindowCollapsed(ImGui_Context ctx, boolean collapsed, optional number condIn)
DESC1267 Set next window collapsed state. Call before ImGui_Begin.Default values: cond = ImGui_Cond_Always
FUNC1268 reaper.ImGui_SetNextWindowContentSize(ImGui_Context ctx, number size_w, number size_h)
DESC1268 Set next window content size (~ scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor ImGui_StyleVar_WindowPadding. set an axis to 0.0f to leave it automatic. Call before ImGui_Begin.
FUNC1269 reaper.ImGui_SetNextWindowDockID(ImGui_Context ctx, integer dock_id, optional number condIn)
DESC1269 Set next window dock ID. 0 = undocked, < 0 = REAPER docker index (-1 = first dock, -2 = second dock, etc), > 0 = Dear ImGui dockspace ID.See ImGui_GetWindowDockID, ImGui_IsWindowDocked.Default values: cond = ImGui_Cond_Always
FUNC1270 reaper.ImGui_SetNextWindowFocus(ImGui_Context ctx)
DESC1270 Set next window to be focused / top-most. Call before ImGui_Begin.
FUNC1271 reaper.ImGui_SetNextWindowPos(ImGui_Context ctx, number pos_x, number pos_y, optional number condIn, optional number pivot_xIn, optional number pivot_yIn)
DESC1271 Set next window position. Call before ImGui_Begin. Use pivot=(0.5,0.5) to center on given point, etc.Default values: cond = ImGui_Cond_Always, pivot_x = 0.0, pivot_y = 0.0
FUNC1272 reaper.ImGui_SetNextWindowSize(ImGui_Context ctx, number size_w, number size_h, optional number condIn)
DESC1272 Set next window size. set axis to 0.0f to force an auto-fit on this axis. Call before ImGui_Begin.Default values: cond = ImGui_Cond_Always
FUNC1273 reaper.ImGui_SetNextWindowSizeConstraints(ImGui_Context ctx, number size_min_w, number size_min_h, number size_max_w, number size_max_h)
DESC1273 Set next window size limits. use -1,-1 on either X/Y axis to preserve the current size. Sizes will be rounded down.
FUNC1274 reaper.ImGui_SetScrollFromPosX(ImGui_Context ctx, number local_x, optional number center_x_ratioIn)
DESC1274 Adjust scrolling amount to make given position visible. Generally ImGui_GetCursorStartPos() + offset to compute a valid position.Default values: center_x_ratio = 0.5
FUNC1275 reaper.ImGui_SetScrollFromPosY(ImGui_Context ctx, number local_y, optional number center_y_ratioIn)
DESC1275 Adjust scrolling amount to make given position visible. Generally ImGui_GetCursorStartPos() + offset to compute a valid position.Default values: center_y_ratio = 0.5
FUNC1276 reaper.ImGui_SetScrollHereX(ImGui_Context ctx, optional number center_x_ratioIn)
DESC1276 Adjust scrolling amount to make current cursor position visible. center_x_ratio=0.0: left, 0.5: center, 1.0: right. When using to make a "default/current item" visible, consider using ImGui_SetItemDefaultFocus instead.Default values: center_x_ratio = 0.5
FUNC1277 reaper.ImGui_SetScrollHereY(ImGui_Context ctx, optional number center_y_ratioIn)
DESC1277 Adjust scrolling amount to make current cursor position visible. center_y_ratio=0.0: top, 0.5: center, 1.0: bottom. When using to make a "default/current item" visible, consider using ImGui_SetItemDefaultFocus instead.Default values: center_y_ratio = 0.5
FUNC1278 reaper.ImGui_SetScrollX(ImGui_Context ctx, number scroll_x)
DESC1278 Set scrolling amount [0 .. ImGui_GetScrollMaxX()]
FUNC1279 reaper.ImGui_SetScrollY(ImGui_Context ctx, number scroll_y)
DESC1279 Set scrolling amount [0 .. ImGui_GetScrollMaxY()]
FUNC1280 reaper.ImGui_SetTabItemClosed(ImGui_Context ctx, string tab_or_docked_window_label)
DESC1280 Notify TabBar or Docking system of a closed tab/window ahead (useful to reduce visual flicker on reorderable tab bars). For tab-bar: call after ImGui_BeginTabBar and before Tab submissions. Otherwise call with a window name.
FUNC1281 reaper.ImGui_SetTooltip(ImGui_Context ctx, string text)
DESC1281 Set a text-only tooltip, typically use with ImGui_IsItemHovered. override any previous call to ImGui_SetTooltip.
FUNC1282 reaper.ImGui_SetWindowCollapsed(ImGui_Context ctx, boolean collapsed, optional number condIn)
DESC1282 (Not recommended) Set current window collapsed state. Prefer using ImGui_SetNextWindowCollapsed.Default values: cond = ImGui_Cond_Always
FUNC1283 reaper.ImGui_SetWindowCollapsedEx(ImGui_Context ctx, string name, boolean collapsed, optional number condIn)
DESC1283 Set named window collapsed state.Default values: cond = ImGui_Cond_Always
FUNC1284 reaper.ImGui_SetWindowFocus(ImGui_Context ctx)
DESC1284 (Not recommended) Set current window to be focused / top-most. Prefer using ImGui_SetNextWindowFocus.
FUNC1285 reaper.ImGui_SetWindowFocusEx(ImGui_Context ctx, string name)
DESC1285 Set named window to be focused / top-most. Use an empty name to remove focus.
FUNC1286 reaper.ImGui_SetWindowPos(ImGui_Context ctx, number pos_x, number pos_y, optional number condIn)
DESC1286 (Not recommended) Set current window position - call within ImGui_Begin/ImGui_End. Prefer using ImGui_SetNextWindowPos, as this may incur tearing and side-effects.Default values: cond = ImGui_Cond_Always
FUNC1287 reaper.ImGui_SetWindowPosEx(ImGui_Context ctx, string name, number pos_x, number pos_y, optional number condIn)
DESC1287 Set named window position.Default values: cond = ImGui_Cond_Always
FUNC1288 reaper.ImGui_SetWindowSize(ImGui_Context ctx, number size_w, number size_h, optional number condIn)
DESC1288 (Not recommended) Set current window size - call within ImGui_Begin/ImGui_End. Set size_w and size_h to 0 to force an auto-fit. Prefer using ImGui_SetNextWindowSize, as this may incur tearing and minor side-effects.Default values: cond = ImGui_Cond_Always
FUNC1289 reaper.ImGui_SetWindowSizeEx(ImGui_Context ctx, string name, number size_w, number size_h, optional number condIn)
DESC1289 Set named window size. Set axis to 0.0f to force an auto-fit on this axis.Default values: cond = ImGui_Cond_Always
FUNC1290 boolean p_open = reaper.ImGui_ShowAboutWindow(ImGui_Context ctx, boolean p_open)
DESC1290 Create About window. Display ReaImGui version, Dear ImGui version, credits and build/system information.
FUNC1291 boolean p_open = reaper.ImGui_ShowMetricsWindow(ImGui_Context ctx, boolean p_open)
DESC1291 Create Metrics/Debugger window. Display Dear ImGui internals: windows, draw commands, various internal state, etc. Set p_open to true to enable the close button.
FUNC1292 boolean retval, number v_rad = reaper.ImGui_SliderAngle(ImGui_Context ctx, string label, number v_rad, optional number v_degrees_minIn, optional number v_degrees_maxIn, optional string formatIn, optional number flagsIn)
DESC1292 Default values: v_degrees_min = -360.0, v_degrees_max = +360.0, format = '%.0f deg', flags = ImGui_SliderFlags_None
FUNC1293 boolean retval, number v = reaper.ImGui_SliderDouble(ImGui_Context ctx, string label, number v, number v_min, number v_max, optional string formatIn, optional number flagsIn)
DESC1293 Default values: format = '%.3f', flags = ImGui_SliderFlags_None
FUNC1294 boolean retval, number v1, number v2 = reaper.ImGui_SliderDouble2(ImGui_Context ctx, string label, number v1, number v2, number v_min, number v_max, optional string formatIn, optional number flagsIn)
DESC1294 Default values: format = '%.3f', flags = ImGui_SliderFlags_None
FUNC1295 boolean retval, number v1, number v2, number v3 = reaper.ImGui_SliderDouble3(ImGui_Context ctx, string label, number v1, number v2, number v3, number v_min, number v_max, optional string formatIn, optional number flagsIn)
DESC1295 Default values: format = '%.3f', flags = ImGui_SliderFlags_None
FUNC1296 boolean retval, number v1, number v2, number v3, number v4 = reaper.ImGui_SliderDouble4(ImGui_Context ctx, string label, number v1, number v2, number v3, number v4, number v_min, number v_max, optional string formatIn, optional number flagsIn)
DESC1296 Default values: format = '%.3f', flags = ImGui_SliderFlags_None
FUNC1297 boolean reaper.ImGui_SliderDoubleN(ImGui_Context ctx, string labelreaper_array values, number v_min, number v_max, optional string formatIn, optional number flagsIn)
DESC1297 Default values: format = '%.3f', flags = ImGui_SliderFlags_None
FUNC1298 integer reaper.ImGui_SliderFlags_AlwaysClamp()
DESC1298 Clamp value to min/max bounds when input manually with CTRL+Click. By default CTRL+Click allows going out of bounds.
FUNC1299 integer reaper.ImGui_SliderFlags_Logarithmic()
DESC1299 Make the widget logarithmic (linear otherwise). Consider using ImGui_SliderFlags_NoRoundToFormat with this if using a format-string with small amount of digits.
FUNC1300 integer reaper.ImGui_SliderFlags_NoInput()
DESC1300 Disable CTRL+Click or Enter key allowing to input text directly into the widget.
FUNC1301 integer reaper.ImGui_SliderFlags_NoRoundToFormat()
DESC1301 Disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits).
FUNC1302 integer reaper.ImGui_SliderFlags_None()
DESC1302 For ImGui_DragDouble, ImGui_DragInt, ImGui_SliderDouble, ImGui_SliderInt etc.
FUNC1303 boolean retval, number v = reaper.ImGui_SliderInt(ImGui_Context ctx, string label, number v, integer v_min, integer v_max, optional string formatIn, optional number flagsIn)
DESC1303 Default values: format = '%d', flags = ImGui_SliderFlags_None
FUNC1304 boolean retval, number v1, number v2 = reaper.ImGui_SliderInt2(ImGui_Context ctx, string label, number v1, number v2, integer v_min, integer v_max, optional string formatIn, optional number flagsIn)
DESC1304 Default values: format = '%d', flags = ImGui_SliderFlags_None
FUNC1305 boolean retval, number v1, number v2, number v3 = reaper.ImGui_SliderInt3(ImGui_Context ctx, string label, number v1, number v2, number v3, integer v_min, integer v_max, optional string formatIn, optional number flagsIn)
DESC1305 Default values: format = '%d', flags = ImGui_SliderFlags_None
FUNC1306 boolean retval, number v1, number v2, number v3, number v4 = reaper.ImGui_SliderInt4(ImGui_Context ctx, string label, number v1, number v2, number v3, number v4, integer v_min, integer v_max, optional string formatIn, optional number flagsIn)
DESC1306 Default values: format = '%d', flags = ImGui_SliderFlags_None
FUNC1307 boolean reaper.ImGui_SmallButton(ImGui_Context ctx, string label)
DESC1307 Button with ImGui_StyleVar_FramePadding=(0,0) to easily embed within text.
FUNC1308 integer reaper.ImGui_SortDirection_Ascending()
DESC1308 Ascending = 0->9, A->Z etc.
FUNC1309 integer reaper.ImGui_SortDirection_Descending()
DESC1309 Descending = 9->0, Z->A etc.
FUNC1310 integer reaper.ImGui_SortDirection_None()
DESC1310 
FUNC1311 reaper.ImGui_Spacing(ImGui_Context ctx)
DESC1311 Add vertical spacing.
FUNC1312 integer reaper.ImGui_StyleVar_Alpha()
DESC1312 Global alpha applies to everything in Dear ImGui.
FUNC1313 integer reaper.ImGui_StyleVar_ButtonTextAlign()
DESC1313 Alignment of button text when button is larger than text. Defaults to (0.5f, 0.5f) (centered).
FUNC1314 integer reaper.ImGui_StyleVar_CellPadding()
DESC1314 Padding within a table cell.
FUNC1315 integer reaper.ImGui_StyleVar_ChildBorderSize()
DESC1315 Thickness of border around child windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
FUNC1316 integer reaper.ImGui_StyleVar_ChildRounding()
DESC1316 Radius of child window corners rounding. Set to 0.0f to have rectangular windows.
FUNC1317 integer reaper.ImGui_StyleVar_FrameBorderSize()
DESC1317 Thickness of border around frames. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
FUNC1318 integer reaper.ImGui_StyleVar_FramePadding()
DESC1318 Padding within a framed rectangle (used by most widgets).
FUNC1319 integer reaper.ImGui_StyleVar_FrameRounding()
DESC1319 Radius of frame corners rounding. Set to 0.0f to have rectangular frame (used by most widgets).
FUNC1320 integer reaper.ImGui_StyleVar_GrabMinSize()
DESC1320 Minimum width/height of a grab box for slider/scrollbar.
FUNC1321 integer reaper.ImGui_StyleVar_GrabRounding()
DESC1321 Radius of grabs corners rounding. Set to 0.0f to have rectangular slider grabs.
FUNC1322 integer reaper.ImGui_StyleVar_IndentSpacing()
DESC1322 Horizontal indentation when e.g. entering a tree node. Generally == (ImGui_GetFontSize + ImGui_StyleVar_FramePadding.x*2).
FUNC1323 integer reaper.ImGui_StyleVar_ItemInnerSpacing()
DESC1323 Horizontal and vertical spacing between within elements of a composed widget (e.g. a slider and its label).
FUNC1324 integer reaper.ImGui_StyleVar_ItemSpacing()
DESC1324 Horizontal and vertical spacing between widgets/lines.
FUNC1325 integer reaper.ImGui_StyleVar_PopupBorderSize()
DESC1325 Thickness of border around popup/tooltip windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
FUNC1326 integer reaper.ImGui_StyleVar_PopupRounding()
DESC1326 Radius of popup window corners rounding. (Note that tooltip windows use ImGui_StyleVar_WindowRounding.)
FUNC1327 integer reaper.ImGui_StyleVar_ScrollbarRounding()
DESC1327 Radius of grab corners for scrollbar.
FUNC1328 integer reaper.ImGui_StyleVar_ScrollbarSize()
DESC1328 Width of the vertical scrollbar, Height of the horizontal scrollbar.
FUNC1329 integer reaper.ImGui_StyleVar_SelectableTextAlign()
DESC1329 Alignment of selectable text. Defaults to (0.0f, 0.0f) (top-left aligned). It's generally important to keep this left-aligned if you want to lay multiple items on a same line.
FUNC1330 integer reaper.ImGui_StyleVar_TabRounding()
DESC1330 Radius of upper corners of a tab. Set to 0.0f to have rectangular tabs.
FUNC1331 integer reaper.ImGui_StyleVar_WindowBorderSize()
DESC1331 Thickness of border around windows. Generally set to 0.0f or 1.0f. (Other values are not well tested and more CPU/GPU costly).
FUNC1332 integer reaper.ImGui_StyleVar_WindowMinSize()
DESC1332 Minimum window size. This is a global setting. If you want to constraint individual windows, use ImGui_SetNextWindowSizeConstraints.
FUNC1333 integer reaper.ImGui_StyleVar_WindowPadding()
DESC1333 Padding within a window.
FUNC1334 integer reaper.ImGui_StyleVar_WindowRounding()
DESC1334 Radius of window corners rounding. Set to 0.0f to have rectangular windows. Large values tend to lead to variety of artifacts and are not recommended.
FUNC1335 integer reaper.ImGui_StyleVar_WindowTitleAlign()
DESC1335 Alignment for title bar text. Defaults to (0.0f,0.5f) for left-aligned,vertically centered.
FUNC1336 integer reaper.ImGui_TabBarFlags_AutoSelectNewTabs()
DESC1336 Automatically select new tabs when they appear.
FUNC1337 integer reaper.ImGui_TabBarFlags_FittingPolicyResizeDown()
DESC1337 Resize tabs when they don't fit.
FUNC1338 integer reaper.ImGui_TabBarFlags_FittingPolicyScroll()
DESC1338 Add scroll buttons when tabs don't fit.
FUNC1339 integer reaper.ImGui_TabBarFlags_NoCloseWithMiddleMouseButton()
DESC1339 Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You can still repro this behavior on user's side with if(ImGui_IsItemHovered() && ImGui_IsMouseClicked(2)) *p_open = false.
FUNC1340 integer reaper.ImGui_TabBarFlags_NoTabListScrollingButtons()
DESC1340 Disable scrolling buttons (apply when fitting policy is ImGui_TabBarFlags_FittingPolicyScroll).
FUNC1341 integer reaper.ImGui_TabBarFlags_NoTooltip()
DESC1341 Disable tooltips when hovering a tab.
FUNC1342 integer reaper.ImGui_TabBarFlags_None()
DESC1342 Flags for ImGui_BeginTabBar.
FUNC1343 integer reaper.ImGui_TabBarFlags_Reorderable()
DESC1343 Allow manually dragging tabs to re-order them + New tabs are appended at the end of list.
FUNC1344 integer reaper.ImGui_TabBarFlags_TabListPopupButton()
DESC1344 Disable buttons to open the tab list popup.
FUNC1345 boolean reaper.ImGui_TabItemButton(ImGui_Context ctx, string label, optional number flagsIn)
DESC1345 Create a Tab behaving like a button. return true when clicked. cannot be selected in the tab bar.Default values: flags = ImGui_TabItemFlags_None
FUNC1346 integer reaper.ImGui_TabItemFlags_Leading()
DESC1346 Enforce the tab position to the left of the tab bar (after the tab list popup button).
FUNC1347 integer reaper.ImGui_TabItemFlags_NoCloseWithMiddleMouseButton()
DESC1347 Disable behavior of closing tabs (that are submitted with p_open != NULL) with middle mouse button. You can still repro this behavior on user's side with if (ImGui_IsItemHovered() && ImGui_IsMouseClicked(2)) *p_open = false.
FUNC1348 integer reaper.ImGui_TabItemFlags_NoPushId()
DESC1348 Don't call ImGui_PushID(tab->ID)/ImGui_PopID() on ImGui_BeginTabItem/ImGui_EndTabItem.
FUNC1349 integer reaper.ImGui_TabItemFlags_NoReorder()
DESC1349 Disable reordering this tab or having another tab cross over this tab.
FUNC1350 integer reaper.ImGui_TabItemFlags_NoTooltip()
DESC1350 Disable tooltip for the given tab.
FUNC1351 integer reaper.ImGui_TabItemFlags_None()
DESC1351 Flags for ImGui_BeginTabItem.
FUNC1352 integer reaper.ImGui_TabItemFlags_SetSelected()
DESC1352 Trigger flag to programmatically make the tab selected when calling ImGui_BeginTabItem.
FUNC1353 integer reaper.ImGui_TabItemFlags_Trailing()
DESC1353 Enforce the tab position to the right of the tab bar (before the scrolling buttons).
FUNC1354 integer reaper.ImGui_TabItemFlags_UnsavedDocument()
DESC1354 Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. Also: tab is selected on closure and closure is deferred by one frame to allow code to undo it without flicker.
FUNC1355 integer reaper.ImGui_TableBgTarget_CellBg()
DESC1355 Set cell background color (top-most color).
FUNC1356 integer reaper.ImGui_TableBgTarget_None()
DESC1356 Enum: A color target for TableSetBgColor()Background colors are rendering in 3 layers:Â - Layer 0: draw with RowBg0 color if set, otherwise draw with ColumnBg0 if set.Â - Layer 1: draw with RowBg1 color if set, otherwise draw with ColumnBg1 if set.Â - Layer 2: draw with CellBg color if set.The purpose of the two row/columns layers is to let you decide if a background color changes should override or blend with the existing color.When using ImGui_TableFlags_RowBg on the table, each row has the RowBg0 color automatically set for odd/even rows.If you set the color of RowBg0 target, your color will override the existing RowBg0 color.If you set the color of RowBg1 or ColumnBg1 target, your color will blend over the RowBg0 color.
FUNC1357 integer reaper.ImGui_TableBgTarget_RowBg0()
DESC1357 Set row background color 0 (generally used for background, automatically set when ImGui_TableFlags_RowBg is used).
FUNC1358 integer reaper.ImGui_TableBgTarget_RowBg1()
DESC1358 Set row background color 1 (generally used for selection marking).
FUNC1359 integer reaper.ImGui_TableColumnFlags_DefaultHide()
DESC1359 Default as a hidden/disabled column.
FUNC1360 integer reaper.ImGui_TableColumnFlags_DefaultSort()
DESC1360 Default as a sorting column.
FUNC1361 integer reaper.ImGui_TableColumnFlags_IndentDisable()
DESC1361 Ignore current Indent value when entering cell (default for columns > 0). Indentation changes _within_ the cell will still be honored.
FUNC1362 integer reaper.ImGui_TableColumnFlags_IndentEnable()
DESC1362 Use current Indent value when entering cell (default for column 0).
FUNC1363 integer reaper.ImGui_TableColumnFlags_IsEnabled()
DESC1363 Status: is enabled == not hidden by user/api (referred to as "Hide" in _DefaultHide and _NoHide) flags.
FUNC1364 integer reaper.ImGui_TableColumnFlags_IsHovered()
DESC1364 Status: is hovered by mouse.
FUNC1365 integer reaper.ImGui_TableColumnFlags_IsSorted()
DESC1365 Status: is currently part of the sort specs.
FUNC1366 integer reaper.ImGui_TableColumnFlags_IsVisible()
DESC1366 Status: is visible == is enabled AND not clipped by scrolling.
FUNC1367 integer reaper.ImGui_TableColumnFlags_NoClip()
DESC1367 Disable clipping for this column (all NoClip columns will render in a same draw command).
FUNC1368 integer reaper.ImGui_TableColumnFlags_NoHeaderWidth()
DESC1368 Disable header text width contribution to automatic column width.
FUNC1369 integer reaper.ImGui_TableColumnFlags_NoHide()
DESC1369 Disable ability to hide/disable this column.
FUNC1370 integer reaper.ImGui_TableColumnFlags_NoReorder()
DESC1370 Disable manual reordering this column, this will also prevent other columns from crossing over this column.
FUNC1371 integer reaper.ImGui_TableColumnFlags_NoResize()
DESC1371 Disable manual resizing.
FUNC1372 integer reaper.ImGui_TableColumnFlags_NoSort()
DESC1372 Disable ability to sort on this field (even if ImGui_TableFlags_Sortable is set on the table).
FUNC1373 integer reaper.ImGui_TableColumnFlags_NoSortAscending()
DESC1373 Disable ability to sort in the ascending direction.
FUNC1374 integer reaper.ImGui_TableColumnFlags_NoSortDescending()
DESC1374 Disable ability to sort in the descending direction.
FUNC1375 integer reaper.ImGui_TableColumnFlags_None()
DESC1375 Flags for ImGui_TableSetupColumn.
FUNC1376 integer reaper.ImGui_TableColumnFlags_PreferSortAscending()
DESC1376 Make the initial sort direction Ascending when first sorting on this column (default).
FUNC1377 integer reaper.ImGui_TableColumnFlags_PreferSortDescending()
DESC1377 Make the initial sort direction Descending when first sorting on this column.
FUNC1378 integer reaper.ImGui_TableColumnFlags_WidthFixed()
DESC1378 Column will not stretch. Preferable with horizontal scrolling enabled (default if table sizing policy is _SizingFixedFit and table is resizable).
FUNC1379 integer reaper.ImGui_TableColumnFlags_WidthStretch()
DESC1379 Column will stretch. Preferable with horizontal scrolling disabled (default if table sizing policy is _SizingStretchSame or _SizingStretchProp).
FUNC1380 integer reaper.ImGui_TableFlags_Borders()
DESC1380 Draw all borders.
FUNC1381 integer reaper.ImGui_TableFlags_BordersH()
DESC1381 Draw horizontal borders.
FUNC1382 integer reaper.ImGui_TableFlags_BordersInner()
DESC1382 Draw inner borders.
FUNC1383 integer reaper.ImGui_TableFlags_BordersInnerH()
DESC1383 Draw horizontal borders between rows.
FUNC1384 integer reaper.ImGui_TableFlags_BordersInnerV()
DESC1384 Draw vertical borders between columns.
FUNC1385 integer reaper.ImGui_TableFlags_BordersOuter()
DESC1385 Draw outer borders.
FUNC1386 integer reaper.ImGui_TableFlags_BordersOuterH()
DESC1386 Draw horizontal borders at the top and bottom.
FUNC1387 integer reaper.ImGui_TableFlags_BordersOuterV()
DESC1387 Draw vertical borders on the left and right sides.
FUNC1388 integer reaper.ImGui_TableFlags_BordersV()
DESC1388 Draw vertical borders.
FUNC1389 integer reaper.ImGui_TableFlags_ContextMenuInBody()
DESC1389 Right-click on columns body/contents will display table context menu. By default it is available in ImGui_TableHeadersRow.
FUNC1390 integer reaper.ImGui_TableFlags_Hideable()
DESC1390 Enable hiding/disabling columns in context menu.
FUNC1391 integer reaper.ImGui_TableFlags_NoClip()
DESC1391 Disable clipping rectangle for every individual columns (reduce draw command count, items will be able to overflow into other columns). Generally incompatible with ImGui_TableSetupScrollFreeze.
FUNC1392 integer reaper.ImGui_TableFlags_NoHostExtendX()
DESC1392 Make outer width auto-fit to columns, overriding outer_size.x value. Only available when ScrollX/ScrollY are disabled and Stretch columns are not used.
FUNC1393 integer reaper.ImGui_TableFlags_NoHostExtendY()
DESC1393 Make outer height stop exactly at outer_size.y (prevent auto-extending table past the limit). Only available when ScrollX/ScrollY are disabled. Data below the limit will be clipped and not visible.
FUNC1394 integer reaper.ImGui_TableFlags_NoKeepColumnsVisible()
DESC1394 Disable keeping column always minimally visible when ScrollX is off and table gets too small. Not recommended if columns are resizable.
FUNC1395 integer reaper.ImGui_TableFlags_NoPadInnerX()
DESC1395 Disable inner padding between columns (double inner padding if ImGui_TableFlags_BordersOuterV is on, single inner padding if BordersOuterV is off).
FUNC1396 integer reaper.ImGui_TableFlags_NoPadOuterX()
DESC1396 Default if ImGui_TableFlags_BordersOuterV is off. Disable outer-most padding.
FUNC1397 integer reaper.ImGui_TableFlags_NoSavedSettings()
DESC1397 Disable persisting columns order, width and sort settings in the .ini file.
FUNC1398 integer reaper.ImGui_TableFlags_None()
DESC1398 For ImGui_BeginTable.- Important! Sizing policies have complex and subtle side effects, more so than you would expect.Â Â Read comments/demos carefully + experiment with live demos to get acquainted with them.- The DEFAULT sizing policies are:Â Â Â - Default to ImGui_TableFlags_SizingFixedFit if ScrollX is on, or if host window has ImGui_WindowFlags_AlwaysAutoResize.Â Â Â - Default to ImGui_TableFlags_SizingStretchSame if ScrollX is off.- When ScrollX is off:Â Â Â - Table defaults to ImGui_TableFlags_SizingStretchSame -> all Columns defaults to ImGui_TableColumnFlags_WidthStretch with same weight.Â Â Â - Columns sizing policy allowed: Stretch (default), Fixed/Auto.Â Â Â - Fixed Columns will generally obtain their requested width (unless the table cannot fit them all).Â Â Â - Stretch Columns will share the remaining width.Â Â Â - Mixed Fixed/Stretch columns is possible but has various side-effects on resizing behaviors.Â Â Â Â Â The typical use of mixing sizing policies is: any number of LEADING Fixed columns, followed by one or two TRAILING Stretch columns.Â Â Â Â Â (this is because the visible order of columns have subtle but necessary effects on how they react to manual resizing).- When ScrollX is on:Â Â Â - Table defaults to ImGui_TableFlags_SizingFixedFit -> all Columns defaults to ImGui_TableColumnFlags_WidthFixedÂ Â Â - Columns sizing policy allowed: Fixed/Auto mostly.Â Â Â - Fixed Columns can be enlarged as needed. Table will show an horizontal scrollbar if needed.Â Â Â - When using auto-resizing (non-resizable) fixed columns, querying the content width to use item right-alignment e.g. ImGui_SetNextItemWidth(-FLT_MIN) doesn't make sense, would create a feedback loop.Â Â Â - Using Stretch columns OFTEN DOES NOT MAKE SENSE if ScrollX is on, UNLESS you have specified a value for 'inner_width' in ImGui_BeginTable().Â Â Â Â Â If you specify a value for 'inner_width' then effectively the scrolling space is known and Stretch or mixed Fixed/Stretch columns become meaningful again.- Read on documentation at the top of imgui_tables.cpp for details.
FUNC1399 integer reaper.ImGui_TableFlags_PadOuterX()
DESC1399 Default if ImGui_TableFlags_BordersOuterV is on. Enable outer-most padding. Generally desirable if you have headers.
FUNC1400 integer reaper.ImGui_TableFlags_PreciseWidths()
DESC1400 Disable distributing remainder width to stretched columns (width allocation on a 100-wide table with 3 columns: Without this flag: 33,33,34. With this flag: 33,33,33). With larger number of columns, resizing will appear to be less smooth.
FUNC1401 integer reaper.ImGui_TableFlags_Reorderable()
DESC1401 Enable reordering columns in header row (need calling ImGui_TableSetupColumn + ImGui_TableHeadersRow to display headers).
FUNC1402 integer reaper.ImGui_TableFlags_Resizable()
DESC1402 Enable resizing columns.
FUNC1403 integer reaper.ImGui_TableFlags_RowBg()
DESC1403 Set each RowBg color with ImGui_Col_TableRowBg or ImGui_Col_TableRowBgAlt (equivalent of calling ImGui_TableSetBgColor with ImGui_TableBgTarget_RowBg0 on each row manually).
FUNC1404 integer reaper.ImGui_TableFlags_ScrollX()
DESC1404 Enable horizontal scrolling. Require 'outer_size' parameter of ImGui_BeginTable to specify the container size. Changes default sizing policy. Because this create a child window, ScrollY is currently generally recommended when using ScrollX.
FUNC1405 integer reaper.ImGui_TableFlags_ScrollY()
DESC1405 Enable vertical scrolling. Require 'outer_size' parameter of ImGui_BeginTable to specify the container size.
FUNC1406 integer reaper.ImGui_TableFlags_SizingFixedFit()
DESC1406 Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching contents width.
FUNC1407 integer reaper.ImGui_TableFlags_SizingFixedSame()
DESC1407 Columns default to _WidthFixed or _WidthAuto (if resizable or not resizable), matching the maximum contents width of all columns. Implicitly enable ImGui_TableFlags_NoKeepColumnsVisible.
FUNC1408 integer reaper.ImGui_TableFlags_SizingStretchProp()
DESC1408 Columns default to _WidthStretch with default weights proportional to each columns contents widths.
FUNC1409 integer reaper.ImGui_TableFlags_SizingStretchSame()
DESC1409 Columns default to _WidthStretch with default weights all equal, unless overriden by ImGui_TableSetupColumn.
FUNC1410 integer reaper.ImGui_TableFlags_SortMulti()
DESC1410 Hold shift when clicking headers to sort on multiple column. ImGui_TableGetGetSortSpecs may return specs where (SpecsCount > 1).
FUNC1411 integer reaper.ImGui_TableFlags_SortTristate()
DESC1411 Allow no sorting, disable default sorting. ImGui_TableGetColumnSortSpecs may return specs where (SpecsCount == 0).
FUNC1412 integer reaper.ImGui_TableFlags_Sortable()
DESC1412 Enable sorting. Call ImGui_TableNeedSort/ImGui_TableGetColumnSortSpecs to obtain sort specs. Also see ImGui_TableFlags_SortMulti and ImGui_TableFlags_SortTristate.
FUNC1413 integer reaper.ImGui_TableGetColumnCount(ImGui_Context ctx)
DESC1413 Return number of columns (value passed to ImGui_BeginTable).
FUNC1414 integer reaper.ImGui_TableGetColumnFlags(ImGui_Context ctx, optional number column_nIn)
DESC1414 Return column flags so you can query their Enabled/Visible/Sorted/Hovered status flags. Pass -1 to use current column.Default values: column_n = -1
FUNC1415 integer reaper.ImGui_TableGetColumnIndex(ImGui_Context ctx)
DESC1415 Return current column index.
FUNC1416 string reaper.ImGui_TableGetColumnName(ImGui_Context ctx, optional number column_nIn)
DESC1416 Return "" if column didn't have a name declared by ImGui_TableSetupColumn. Pass -1 to use current column.Default values: column_n = -1
FUNC1417 boolean retval, number column_user_id, number column_index, number sort_order, number sort_direction = reaper.ImGui_TableGetColumnSortSpecs(ImGui_Context ctx, integer id)
DESC1417 Sorting specification for one column of a table. Call while incrementing id from 0 until false is returned.ColumnUserID:Â Â User id of the column (if specified by a ImGui_TableSetupColumn call)ColumnIndex:Â Â Â Index of the columnSortOrder:Â Â Â Â Â Index within parent SortSpecs (always stored in order starting from 0, tables sorted on a single criteria will always have a 0 here)SortDirection: ImGui_SortDirection_Ascending or ImGui_SortDirection_Descending (you can use this or SortSign, whichever is more convenient for your sort function)See ImGui_TableNeedSort.
FUNC1418 integer reaper.ImGui_TableGetRowIndex(ImGui_Context ctx)
DESC1418 Return current row index.
FUNC1419 reaper.ImGui_TableHeader(ImGui_Context ctx, string label)
DESC1419 Submit one header cell manually (rarely used). See ImGui_TableSetupColumn.
FUNC1420 reaper.ImGui_TableHeadersRow(ImGui_Context ctx)
DESC1420 Submit all headers cells based on data provided to ImGui_TableSetupColumn + submit context menu.
FUNC1421 boolean retval, boolean has_specs = reaper.ImGui_TableNeedSort(ImGui_Context ctx)
DESC1421 Return true once when sorting specs have changed since last call, or the first time. 'has_specs' is false when not sorting. See ImGui_TableGetColumnSortSpecs.
FUNC1422 boolean reaper.ImGui_TableNextColumn(ImGui_Context ctx)
DESC1422 Append into the next column (or first column of next row if currently in last column). Return true when column is visible.
FUNC1423 reaper.ImGui_TableNextRow(ImGui_Context ctx, optional number row_flagsIn, optional number min_row_heightIn)
DESC1423 Append into the first cell of a new row.Default values: row_flags = ImGui_TableRowFlags_None, min_row_height = 0.0
FUNC1424 integer reaper.ImGui_TableRowFlags_Headers()
DESC1424 Identify header row (set default background color + width of its contents accounted different for auto column width).
FUNC1425 integer reaper.ImGui_TableRowFlags_None()
DESC1425 Flags for ImGui_TableNextRow.
FUNC1426 reaper.ImGui_TableSetBgColor(ImGui_Context ctx, integer target, integer color_rgba, optional number column_nIn)
DESC1426 Change the color of a cell, row, or column. See ImGui_TableBgTarget_* flags for details.Default values: column_n = -1
FUNC1427 reaper.ImGui_TableSetColumnEnabled(ImGui_Context ctx, integer column_n, boolean v)
DESC1427 Change enabled/disabled state of a column, set to false to hide the column. Note that end-user can use the context menu to change this themselves (right-click in headers, or right-click in columns body with ImGui_TableFlags_ContextMenuInBody).
FUNC1428 boolean reaper.ImGui_TableSetColumnIndex(ImGui_Context ctx, integer column_n)
DESC1428 Append into the specified column. Return true when column is visible.
FUNC1429 reaper.ImGui_TableSetupColumn(ImGui_Context ctx, string label, optional number flagsIn, optional number init_width_or_weightIn, optional number user_idIn)
DESC1429 Use to specify label, resizing policy, default width/weight, id, various other flags etc.Default values: flags = ImGui_TableColumnFlags_None, init_width_or_weight = 0.0, user_id = 0
FUNC1430 reaper.ImGui_TableSetupScrollFreeze(ImGui_Context ctx, integer cols, integer rows)
DESC1430 Lock columns/rows so they stay visible when scrolled.
FUNC1431 reaper.ImGui_Text(ImGui_Context ctx, string text)
DESC1431 
FUNC1432 reaper.ImGui_TextColored(ImGui_Context ctx, integer col_rgba, string text)
DESC1432 Shortcut for ImGui_PushStyleColor(ImGui_Col_Text, color); ImGui_Text(text); ImGui_PopStyleColor();
FUNC1433 reaper.ImGui_TextDisabled(ImGui_Context ctx, string text)
DESC1433 
FUNC1434 reaper.ImGui_TextWrapped(ImGui_Context ctx, string text)
DESC1434 Shortcut for ImGui_PushTextWrapPos(0.0f); ImGui_Text(fmt, ...); ImGui_PopTextWrapPos();. Note that this won't work on an auto-resizing window if there's no other widgets to extend the window width, yoy may need to set a size using ImGui_SetNextWindowSize.
FUNC1435 boolean reaper.ImGui_TreeNode(ImGui_Context ctx, string label, optional number flagsIn)
DESC1435 TreeNode functions return true when the node is open, in which case you need to also call ImGui_TreePop when you are finished displaying the tree node contents.Default values: flags = ImGui_TreeNodeFlags_None
FUNC1436 boolean reaper.ImGui_TreeNodeEx(ImGui_Context ctx, string str_id, string label, optional number flagsIn)
DESC1436 Helper variation to easily decorelate the id from the displayed string. Read the FAQ about why and how to use ID. to align arbitrary text at the same level as a ImGui_TreeNode you can use ImGui_Bullet.Default values: flags = ImGui_TreeNodeFlags_None
FUNC1437 integer reaper.ImGui_TreeNodeFlags_AllowItemOverlap()
DESC1437 Hit testing to allow subsequent widgets to overlap this one.
FUNC1438 integer reaper.ImGui_TreeNodeFlags_Bullet()
DESC1438 Display a bullet instead of arrow.
FUNC1439 integer reaper.ImGui_TreeNodeFlags_CollapsingHeader()
DESC1439 
FUNC1440 integer reaper.ImGui_TreeNodeFlags_DefaultOpen()
DESC1440 Default node to be open.
FUNC1441 integer reaper.ImGui_TreeNodeFlags_FramePadding()
DESC1441 Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling ImGui_AlignTextToFramePadding.
FUNC1442 integer reaper.ImGui_TreeNodeFlags_Framed()
DESC1442 Draw frame with background (e.g. for ImGui_CollapsingHeader).
FUNC1443 integer reaper.ImGui_TreeNodeFlags_Leaf()
DESC1443 No collapsing, no arrow (use as a convenience for leaf nodes).
FUNC1444 integer reaper.ImGui_TreeNodeFlags_NoAutoOpenOnLog()
DESC1444 Don't automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes).
FUNC1445 integer reaper.ImGui_TreeNodeFlags_NoTreePushOnOpen()
DESC1445 Don't do a ImGui_TreePush when open (e.g. for ImGui_CollapsingHeader) = no extra indent nor pushing on ID stack.
FUNC1446 integer reaper.ImGui_TreeNodeFlags_None()
DESC1446 Flags for ImGui_TreeNode, ImGui_TreeNodeEx, ImGui_CollapsingHeader.
FUNC1447 integer reaper.ImGui_TreeNodeFlags_OpenOnArrow()
DESC1447 Only open when clicking on the arrow part. If ImGui_TreeNodeFlags_OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
FUNC1448 integer reaper.ImGui_TreeNodeFlags_OpenOnDoubleClick()
DESC1448 Need double-click to open node.
FUNC1449 integer reaper.ImGui_TreeNodeFlags_Selected()
DESC1449 Draw as selected.
FUNC1450 integer reaper.ImGui_TreeNodeFlags_SpanAvailWidth()
DESC1450 Extend hit box to the right-most edge, even if not framed. This is not the default in order to allow adding other items on the same line. In the future we may refactor the hit system to be front-to-back, allowing natural overlaps and then this can become the default.
FUNC1451 integer reaper.ImGui_TreeNodeFlags_SpanFullWidth()
DESC1451 Extend hit box to the left-most and right-most edges (bypass the indented area).
FUNC1452 reaper.ImGui_TreePop(ImGui_Context ctx)
DESC1452 ImGui_Unindent()+ImGui_PopID()
FUNC1453 reaper.ImGui_TreePush(ImGui_Context ctx, string str_id)
DESC1453 ~ ImGui_Indent()+ImGui_PushID(). Already called by ImGui_TreeNode when returning true, but you can call ImGui_TreePush/ImGui_TreePop yourself if desired.
FUNC1454 reaper.ImGui_Unindent(ImGui_Context ctx, optional number indent_wIn)
DESC1454 Move content position back to the left, by 'indent_w', or ImGui_StyleVar_IndentSpacing if 'indent_w' <= 0Default values: indent_w = 0.0
FUNC1455 boolean retval, number v = reaper.ImGui_VSliderDouble(ImGui_Context ctx, string label, number size_w, number size_h, number v, number v_min, number v_max, optional string formatIn, optional number flagsIn)
DESC1455 Default values: format = '%.3f', flags = ImGui_SliderFlags_None
FUNC1456 boolean retval, number v = reaper.ImGui_VSliderInt(ImGui_Context ctx, string label, number size_w, number size_h, number v, integer v_min, integer v_max, optional string formatIn, optional number flagsIn)
DESC1456 Default values: format = '%d', flags = ImGui_SliderFlags_None
FUNC1457 boolean reaper.ImGui_ValidatePtr(identifier pointer, string type)
DESC1457 Return whether the pointer of the specified type is valid. Supported types are ImGui_Context*, ImGui_DrawList*, ImGui_ListClipper* and ImGui_Viewport*.
FUNC1458 number x, number y = reaper.ImGui_Viewport_GetCenter(ImGui_Viewport viewport)
DESC1458 Main Area: Center of the viewport.
FUNC1459 number x, number y = reaper.ImGui_Viewport_GetPos(ImGui_Viewport viewport)
DESC1459 Main Area: Position of the viewport (Dear ImGui coordinates are the same as OS desktop/native coordinates)
FUNC1460 number w, number h = reaper.ImGui_Viewport_GetSize(ImGui_Viewport viewport)
DESC1460 Main Area: Size of the viewport.
FUNC1461 number x, number y = reaper.ImGui_Viewport_GetWorkCenter(ImGui_Viewport viewport)
DESC1461 Work Area: Center of the viewport.
FUNC1462 number x, number y = reaper.ImGui_Viewport_GetWorkPos(ImGui_Viewport viewport)
DESC1462 Work Area: Position of the viewport minus task bars, menus bars, status bars (>= Pos)
FUNC1463 number w, number h = reaper.ImGui_Viewport_GetWorkSize(ImGui_Viewport viewport)
DESC1463 Work Area: Size of the viewport minus task bars, menu bars, status bars (<= Size)
FUNC1464 integer reaper.ImGui_WindowFlags_AlwaysAutoResize()
DESC1464 Resize every window to its content every frame.
FUNC1465 integer reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()
DESC1465 Always show horizontal scrollbar (even if ContentSize.x < Size.x).
FUNC1466 integer reaper.ImGui_WindowFlags_AlwaysUseWindowPadding()
DESC1466 Ensure child windows without border uses ImGui_StyleVar_WindowPadding (ignored by default for non-bordered child windows, because more convenient).
FUNC1467 integer reaper.ImGui_WindowFlags_AlwaysVerticalScrollbar()
DESC1467 Always show vertical scrollbar (even if ContentSize.y < Size.y).
FUNC1468 integer reaper.ImGui_WindowFlags_HorizontalScrollbar()
DESC1468 Allow horizontal scrollbar to appear (off by default). You may use ImGui_SetNextWindowContentSize(width, 0.0) prior to calling ImGui_Begin() to specify width. Read code in the demo's "Horizontal Scrolling" section.
FUNC1469 integer reaper.ImGui_WindowFlags_MenuBar()
DESC1469 Has a menu-bar.
FUNC1470 integer reaper.ImGui_WindowFlags_NoBackground()
DESC1470 Disable drawing background color (WindowBg, etc.) and outside border. Similar as using ImGui_SetNextWindowBgAlpha(0.0).
FUNC1471 integer reaper.ImGui_WindowFlags_NoCollapse()
DESC1471 Disable user collapsing window by double-clicking on it.
FUNC1472 integer reaper.ImGui_WindowFlags_NoDecoration()
DESC1472 ImGui_WindowFlags_NoTitleBar | ImGui_WindowFlags_NoResize | ImGui_WindowFlags_NoScrollbar | ImGui_WindowFlags_NoCollapse
FUNC1473 integer reaper.ImGui_WindowFlags_NoDocking()
DESC1473 Disable docking of this window.
FUNC1474 integer reaper.ImGui_WindowFlags_NoFocusOnAppearing()
DESC1474 Disable taking focus when transitioning from hidden to visible state.
FUNC1475 integer reaper.ImGui_WindowFlags_NoInputs()
DESC1475 ImGui_WindowFlags_NoMouseInputs | ImGui_WindowFlags_NoNavInputs | ImGui_WindowFlags_NoNavFocus
FUNC1476 integer reaper.ImGui_WindowFlags_NoMouseInputs()
DESC1476 Disable catching mouse, hovering test with pass through.
FUNC1477 integer reaper.ImGui_WindowFlags_NoMove()
DESC1477 Disable user moving the window.
FUNC1478 integer reaper.ImGui_WindowFlags_NoNav()
DESC1478 ImGui_WindowFlags_NoNavInputs | ImGui_WindowFlags_NoNavFocus
FUNC1479 integer reaper.ImGui_WindowFlags_NoNavFocus()
DESC1479 No focusing toward this window with gamepad/keyboard navigation (e.g. skipped by CTRL+TAB).
FUNC1480 integer reaper.ImGui_WindowFlags_NoNavInputs()
DESC1480 No gamepad/keyboard navigation within the window.
FUNC1481 integer reaper.ImGui_WindowFlags_NoResize()
DESC1481 Disable user resizing with the lower-right grip.
FUNC1482 integer reaper.ImGui_WindowFlags_NoSavedSettings()
DESC1482 Never load/save settings in .ini file.
FUNC1483 integer reaper.ImGui_WindowFlags_NoScrollWithMouse()
DESC1483 Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
FUNC1484 integer reaper.ImGui_WindowFlags_NoScrollbar()
DESC1484 Disable scrollbars (window can still scroll with mouse or programmatically).
FUNC1485 integer reaper.ImGui_WindowFlags_NoTitleBar()
DESC1485 Disable title-bar.
FUNC1486 integer reaper.ImGui_WindowFlags_None()
DESC1486 Default flag. See ImGui_Begin.
FUNC1487 integer reaper.ImGui_WindowFlags_UnsavedDocument()
DESC1487 Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. When used in a tab/docking context, tab is selected on closure and closure is deferred by one frame to allow code to cancel the closure (with a confirmation popup, etc.) without flicker.
FUNC1488 integer reaper.JS_Actions_CountShortcuts(integer section, integer cmdID)
DESC1488 Section:0 = Main, 100 = Main (alt recording), 32060 = MIDI Editor, 32061 = MIDI Event List Editor, 32062 = MIDI Inline Editor, 32063 = Media Explorer.
FUNC1489 boolean reaper.JS_Actions_DeleteShortcut(integer section, integer cmdID, integer shortcutidx)
DESC1489 Section:0 = Main, 100 = Main (alt recording), 32060 = MIDI Editor, 32061 = MIDI Event List Editor, 32062 = MIDI Inline Editor, 32063 = Media Explorer.
FUNC1490 boolean reaper.JS_Actions_DoShortcutDialog(integer section, integer cmdID, integer shortcutidx)
DESC1490 Section:0 = Main, 100 = Main (alt recording), 32060 = MIDI Editor, 32061 = MIDI Event List Editor, 32062 = MIDI Inline Editor, 32063 = Media Explorer.If the shortcut index is higher than the current number of shortcuts, it will add a new shortcut.
FUNC1491 boolean retval, string desc = reaper.JS_Actions_GetShortcutDesc(integer section, integer cmdID, integer shortcutidx)
DESC1491 Section:0 = Main, 100 = Main (alt recording), 32060 = MIDI Editor, 32061 = MIDI Event List Editor, 32062 = MIDI Inline Editor, 32063 = Media Explorer.
FUNC1492 number byte = reaper.JS_Byte(identifier pointer, integer offset)
DESC1492 Returns the unsigned byte at address[offset]. Offset is added as steps of 1 byte each.
FUNC1493 integer reaper.JS_Composite(identifier windowHWND, integer dstx, integer dsty, integer dstw, integer dsth, identifier sysBitmap, integer srcx, integer srcy, integer srcw, integer srch, unsupported autoUpdate)
DESC1493 Composites a LICE bitmap with a REAPER window. Each time that the window is re-drawn, the bitmap will be blitted over the window's client area (with per-pixel alpha blending).* If dstw or dsth is -1, the bitmap will be stretched to fill the width or height of the window, respectively.* autoUpdate is an optional parameter that is false by default. If true, JS_Composite will automatically invalidate and re-draw the part of the window that covers the current position of the bitmap, and if the bitmap is being moved, also the previous position. (If only one or a handful of bitmaps are being moved across the screen, autoUpdate should result in smoother animation on WindowsOS; if numerous bitmaps are spread over the entire window, it may be faster to disable autoUpdate and instead call JS_Window_InvalidateRect explicitly once all bitmaps have been moved.)* InvalidateRect should also be called whenever the contents of the bitmap contents have been changed, but not the position, to trigger a window update.* On WindowsOS, the key to reducing flickering is to slow down the frequency at which the window is re-drawn. InvalidateRect should only be called when absolutely necessary, preferably not more than 20 times per second. (Also refer to the JS_Composite_Delay function.)* On WindowsOS, flickering can further be reduced by keeping the invalidated area as small as possible, covering only the bitmaps that have been edited or moved. However, if numerous bitmaps are spread over the entire window, it may be faster to simply invalidate the entire client area.* This function should not be applied directly to top-level windows, but rather to child windows.* Some classes of UI elements, particularly buttons, do not take kindly to being composited, and may crash REAPER.* On WindowsOS, GDI blitting does not perform alpha multiplication of the source bitmap. For proper color rendering, a separate pre-multiplication step is therefore required, using either LICE_Blit or LICE_ProcessRect.Returns:1 if successful, otherwise -1 = windowHWND is not a window, -3 = Could not obtain the original window process, -4 = sysBitmap is not a LICE bitmap, -5 = sysBitmap is not a system bitmap, -6 = Could not obtain the window HDC, -7 = Error when subclassing to new window process.
FUNC1494 integer retval, number prevMinTime, number prevMaxTime, number prevBitmaps = reaper.JS_Composite_Delay(identifier windowHWND, number minTime, number maxTime, integer numBitmapsWhenMax)
DESC1494 On WindowsOS, flickering of composited images can be improved considerably by slowing the refresh rate of the window. The optimal refresh rate may depend on the number of composited bitmaps.minTime is the minimum refresh delay, in seconds, when only one bitmap is composited onto the window. The delay time will increase linearly with the number of bitmaps, up to a maximum of maxTime when numBitmapsWhenMax is reached.If both minTime and maxTime are 0, all delay settings for the window are cleared.Returns:* retval = 1 if successful, 0 if arguments are invalid (i.e. if maxTime < minTime, or maxBitmaps < 1).* If delay times have not previously been set for this window, prev time values are 0.
FUNC1495 integer retval, string list = reaper.JS_Composite_ListBitmaps(identifier windowHWND)
DESC1495 Returns all bitmaps composited to the given window.The list is formatted as a comma-separated string of hexadecimal values, each representing a LICE_IBitmap* pointer.retval is the number of linked bitmaps found, or negative if an error occured.
FUNC1496 reaper.JS_Composite_Unlink(identifier windowHWND, identifier bitmap, unsupported autoUpdate)
DESC1496 Unlinks the window and bitmap.* autoUpdate is an optional parameter. If unlinking a single bitmap and autoUpdate is true, the function will automatically re-draw the window to remove the blitted image.If no bitmap is specified, all bitmaps composited to the window will be unlinked -- even those by other scripts.
FUNC1497 integer retval, string folder = reaper.JS_Dialog_BrowseForFolder(string caption, string initialFolder)
DESC1497 retval is 1 if a file was selected, 0 if the user cancelled the dialog, and -1 if an error occurred.
FUNC1498 integer retval, string fileNames = reaper.JS_Dialog_BrowseForOpenFiles(string windowTitle, string initialFolder, string initialFile, string extensionList, boolean allowMultiple)
DESC1498 If allowMultiple is true, multiple files may be selected. The returned string is \0-separated, with the first substring containing the folder path and subsequent substrings containing the file names.* On macOS, the first substring may be empty, and each file name will then contain its entire path.* This function only allows selection of existing files, and does not allow creation of new files.extensionList is a string containing pairs of \0-terminated substrings. The last substring must be terminated by two \0 characters. Each pair defines one filter pattern:* The first substring in each pair describes the filter in user-readable form (for example, "Lua script files (*.lua)") and will be displayed in the dialog box.* The second substring specifies the filter that the operating system must use to search for the files (for example, "*.txt"; the wildcard should not be omitted). To specify multiple extensions for a single display string, use a semicolon to separate the patterns (for example, "*.lua;*.eel").An example of an extensionList string:"ReaScript files\0*.lua;*.eel\0Lua files (.lua)\0*.lua\0EEL files (.eel)\0*.eel\0\0".On macOS, file dialogs do not accept empty extensionLists, nor wildcard extensions (such as "All files\0*.*\0\0"), so each acceptable extension must be listed explicitly. On Linux and Windows, wildcard extensions are acceptable, and if the extensionList string is empty, the dialog will display a default "All files (*.*)" filter.retval is 1 if one or more files were selected, 0 if the user cancelled the dialog, or negative if an error occurred.Displaying \0-separated strings:* REAPER's IDE and ShowConsoleMsg only display strings up to the first \0 byte. If multiple files were selected, only the first substring containing the path will be displayed. This is not a problem for Lua or EEL, which can access the full string beyond the first \0 byte as usual.
FUNC1499 integer retval, string fileName = reaper.JS_Dialog_BrowseForSaveFile(string windowTitle, string initialFolder, string initialFile, string extensionList)
DESC1499 retval is 1 if a file was selected, 0 if the user cancelled the dialog, or negative if an error occurred.extensionList is as described for JS_Dialog_BrowseForOpenFiles.
FUNC1500 number double = reaper.JS_Double(identifier pointer, integer offset)
DESC1500 Returns the 8-byte floating point value at address[offset]. Offset is added as steps of 8 bytes each.
FUNC1501 integer retval, number size, string accessedTime, string modifiedTime, string cTime, number deviceID, number deviceSpecialID, number inode, number mode, number numLinks, number ownerUserID, number ownerGroupID = reaper.JS_File_Stat(string filePath)
DESC1501 Returns information about a file.cTime is not implemented on all systems. If it does return a time, the value may differ depending on the OS: on WindowsOS, it may refer to the time that the file was either created or copied, whereas on Linux and macOS, it may refer to the time of last status change.retval is 0 if successful, negative if not.
FUNC1502 reaper.JS_GDI_Blit(identifier destHDC, integer dstx, integer dsty, identifier sourceHDC, integer srcx, integer srxy, integer width, integer height, optional string mode)
DESC1502 Blits between two device contexts, which may include LICE "system bitmaps".mode: Optional parameter. "SRCCOPY" by default, or specify "ALPHA" to enable per-pixel alpha blending.WARNING: On WindowsOS, GDI_Blit does not perform alpha multiplication of the source bitmap. For proper color rendering, a separate pre-multiplication step is therefore required, using either LICE_Blit or LICE_ProcessRect.
FUNC1503 identifier reaper.JS_GDI_CreateFillBrush(integer color)
DESC1503 
FUNC1504 identifier reaper.JS_GDI_CreateFont(integer height, integer weight, integer angle, boolean italic, boolean underline, boolean strike, string fontName)
DESC1504 Parameters:* weight: 0 - 1000, with 0 = auto, 400 = normal and 700 = bold.* angle: the angle, in tenths of degrees, between the text and the x-axis of the device.* fontName: If empty string "", uses first font that matches the other specified attributes.Note: Text color must be set separately.
FUNC1505 identifier reaper.JS_GDI_CreatePen(integer width, integer color)
DESC1505 
FUNC1506 reaper.JS_GDI_DeleteObject(identifier GDIObject)
DESC1506 
FUNC1507 integer reaper.JS_GDI_DrawText(identifier deviceHDC, string text, integer len, integer left, integer top, integer right, integer bottom, string align))
DESC1507 Parameters:* align: Combination of: "TOP", "VCENTER", "LEFT", "HCENTER", "RIGHT", "BOTTOM", "WORDBREAK", "SINGLELINE", "NOCLIP", "CALCRECT", "NOPREFIX" or "ELLIPSIS"
FUNC1508 reaper.JS_GDI_FillEllipse(identifier deviceHDC, integer left, integer top, integer right, integer bottom)
DESC1508 
FUNC1509 reaper.JS_GDI_FillPolygon(identifier deviceHDC, string packedX, string packedY, integer numPoints)
DESC1509 packedX and packedY are strings of points, each packed as "<i4".
FUNC1510 reaper.JS_GDI_FillRect(identifier deviceHDC, integer left, integer top, integer right, integer bottom)
DESC1510 
FUNC1511 reaper.JS_GDI_FillRoundRect(identifier deviceHDC, integer left, integer top, integer right, integer bottom, integer xrnd, integer yrnd)
DESC1511 
FUNC1512 identifier reaper.JS_GDI_GetClientDC(identifier windowHWND)
DESC1512 Returns the device context for the client area of the specified window.
FUNC1513 identifier reaper.JS_GDI_GetScreenDC()
DESC1513 Returns a device context for the entire screen.WARNING: Only available on Windows, not Linux or macOS.
FUNC1514 integer reaper.JS_GDI_GetSysColor(string GUIElement)
DESC1514 
FUNC1515 integer reaper.JS_GDI_GetTextColor(identifier deviceHDC)
DESC1515 
FUNC1516 identifier reaper.JS_GDI_GetWindowDC(identifier windowHWND)
DESC1516 Returns the device context for the entire window, including title bar and frame.
FUNC1517 reaper.JS_GDI_Line(identifier deviceHDC, integer x1, integer y1, integer x2, integer y2)
DESC1517 
FUNC1518 reaper.JS_GDI_Polyline(identifier deviceHDC, string packedX, string packedY, integer numPoints)
DESC1518 packedX and packedY are strings of points, each packed as "<i4".
FUNC1519 integer reaper.JS_GDI_ReleaseDC(identifier deviceHDC, identifier windowHWND)
DESC1519 To release a window HDC, both arguments must be supplied: the HWND as well as the HDC. To release a screen DC, only the HDC needs to be supplied.For compatibility with previous versions, the HWND and HDC can be supplied in any order.NOTE: Any GDI HDC should be released immediately after drawing, and deferred scripts should get and release new DCs in each cycle.
FUNC1520 identifier reaper.JS_GDI_SelectObject(identifier deviceHDC, identifier GDIObject)
DESC1520 Activates a font, pen, or fill brush for subsequent drawing in the specified device context.
FUNC1521 reaper.JS_GDI_SetPixel(identifier deviceHDC, integer x, integer y, integer color)
DESC1521 
FUNC1522 reaper.JS_GDI_SetTextBkColor(identifier deviceHDC, integer color)
DESC1522 
FUNC1523 reaper.JS_GDI_SetTextBkMode(identifier deviceHDC, integer mode)
DESC1523 
FUNC1524 reaper.JS_GDI_SetTextColor(identifier deviceHDC, integer color)
DESC1524 
FUNC1525 reaper.JS_GDI_StretchBlit(identifier destHDC, integer dstx, integer dsty, integer dstw, integer dsth, identifier sourceHDC, integer srcx, integer srxy, integer srcw, integer srch, optional string mode)
DESC1525 Blits between two device contexts, which may include LICE "system bitmaps".modeOptional: "SRCCOPY" by default, or specify "ALPHA" to enable per-pixel alpha blending.WARNING: On WindowsOS, GDI_Blit does not perform alpha multiplication of the source bitmap. For proper color rendering, a separate pre-multiplication step is therefore required, using either LICE_Blit or LICE_ProcessRect.
FUNC1526 number int = reaper.JS_Int(identifier pointer, integer offset)
DESC1526 Returns the 4-byte signed integer at address[offset]. Offset is added as steps of 4 bytes each.
FUNC1527 reaper.JS_LICE_AlterBitmapHSV(identifier bitmap, number hue, number saturation, number value)
DESC1527 Hue is rolled over, saturation and value are clamped, all 0..1. (Alpha remains unchanged.)
FUNC1528 reaper.JS_LICE_AlterRectHSV(identifier bitmap, integer x, integer y, integer w, integer h, number hue, number saturation, number value)
DESC1528 Hue is rolled over, saturation and value are clamped, all 0..1. (Alpha remains unchanged.)
FUNC1529 reaper.JS_LICE_Arc(identifier bitmap, number cx, number cy, number r, number minAngle, number maxAngle, integer color, number alpha, string mode, boolean antialias)
DESC1529 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1530 integer reaper.JS_LICE_ArrayAllBitmaps(identifier reaperarray)
DESC1530 
FUNC1531 reaper.JS_LICE_Bezier(identifier bitmap, number xstart, number ystart, number xctl1, number yctl1, number xctl2, number yctl2, number xend, number yend, number tol, integer color, number alpha, string mode, boolean antialias)
DESC1531 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA" to enable per-pixel alpha blending.LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1532 reaper.JS_LICE_Blit(identifier destBitmap, integer dstx, integer dsty, identifier sourceBitmap, integer srcx, integer srcy, integer width, integer height, number alpha, string mode)
DESC1532 Standard LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA" to enable per-pixel alpha blending.In addition to the standard LICE modes, LICE_Blit also offers:* "CHANCOPY_XTOY", with X and Y any of the four channels, A, R, G or B. (CHANCOPY_ATOA is similar to MASK mode.)* "BLUR"* "ALPHAMUL", which overwrites the destination with a per-pixel alpha-multiplied copy of the source. (Similar to first clearing the destination with 0x00000000 and then blitting with "COPY,ALPHA".)
FUNC1533 reaper.JS_LICE_Circle(identifier bitmap, number cx, number cy, number r, integer color, number alpha, string mode, boolean antialias)
DESC1533 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1534 reaper.JS_LICE_Clear(identifier bitmap, integer color)
DESC1534 
FUNC1535 identifier reaper.JS_LICE_CreateBitmap(boolean isSysBitmap, integer width, integer height)
DESC1535 
FUNC1536 identifier reaper.JS_LICE_CreateFont()
DESC1536 
FUNC1537 reaper.JS_LICE_DestroyBitmap(identifier bitmap)
DESC1537 Deletes the bitmap, and also unlinks bitmap from any composited window.
FUNC1538 reaper.JS_LICE_DestroyFont(identifier LICEFont)
DESC1538 
FUNC1539 reaper.JS_LICE_DrawChar(identifier bitmap, integer x, integer y, integer c, integer color, number alpha, integer mode))
DESC1539 
FUNC1540 integer reaper.JS_LICE_DrawText(identifier bitmap, identifier LICEFont, string text, integer textLen, integer x1, integer y1, integer x2, integer y2)
DESC1540 
FUNC1541 reaper.JS_LICE_FillCircle(identifier bitmap, number cx, number cy, number r, integer color, number alpha, string mode, boolean antialias)
DESC1541 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1542 reaper.JS_LICE_FillPolygon(identifier bitmap, string packedX, string packedY, integer numPoints, integer color, number alpha, string mode)
DESC1542 packedX and packedY are two strings of coordinates, each packed as "<i4".LICE modes : "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA" to enable per-pixel alpha blending.LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1543 reaper.JS_LICE_FillRect(identifier bitmap, integer x, integer y, integer w, integer h, integer color, number alpha, string mode)
DESC1543 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1544 reaper.JS_LICE_FillTriangle(identifier bitmap, integer x1, integer y1, integer x2, integer y2, integer x3, integer y3, integer color, number alpha, string mode)
DESC1544 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1545 identifier reaper.JS_LICE_GetDC(identifier bitmap)
DESC1545 
FUNC1546 integer reaper.JS_LICE_GetHeight(identifier bitmap)
DESC1546 
FUNC1547 number color = reaper.JS_LICE_GetPixel(identifier bitmap, integer x, integer y)
DESC1547 Returns the color of the specified pixel.
FUNC1548 integer reaper.JS_LICE_GetWidth(identifier bitmap)
DESC1548 
FUNC1549 reaper.JS_LICE_GradRect(identifier bitmap, integer dstx, integer dsty, integer dstw, integer dsth, number ir, number ig, number ib, number ia, number drdx, number dgdx, number dbdx, number dadx, number drdy, number dgdy, number dbdy, number dady, string mode)
DESC1549 
FUNC1550 boolean reaper.JS_LICE_IsFlipped(identifier bitmap)
DESC1550 
FUNC1551 reaper.JS_LICE_Line(identifier bitmap, number x1, number y1, number x2, number y2, integer color, number alpha, string mode, boolean antialias)
DESC1551 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1552 integer retval, string list = reaper.JS_LICE_ListAllBitmaps()
DESC1552 
FUNC1553 identifier reaper.JS_LICE_LoadJPG(string filename)
DESC1553 Returns a system LICE bitmap containing the JPEG.
FUNC1554 identifier reaper.JS_LICE_LoadPNG(string filename)
DESC1554 Returns a system LICE bitmap containing the PNG.
FUNC1555 number width, number Height = reaper.JS_LICE_MeasureText(string text)
DESC1555 
FUNC1556 boolean reaper.JS_LICE_ProcessRect(identifier bitmap, integer x, integer y, integer w, integer h, string mode, number operand)
DESC1556 Applies bitwise operations to each pixel in the target rectangle.operand: a color in 0xAARRGGBB format.modes:* "XOR", "OR" or "AND".* "SET_XYZ", with XYZ any combination of A, R, G, and B: copies the specified channels from operand to the bitmap. (Useful for setting the alpha values of a bitmap.)* "ALPHAMUL": Performs alpha pre-multiplication on each pixel in the rect. operand is ignored in this mode. (On WindowsOS, GDI_Blit does not perform alpha multiplication on the fly, and a separate alpha pre-multiplication step is therefore required.)NOTE:LICE_Blit and LICE_ScaledBlit are also useful for processing bitmap colors. For example, to multiply all channel values by 1.5:
FUNC1557 reaper.JS_LICE_Blit(bitmap, x, y, bitmap, x, y, w, h, 0.5, "ADD").
DESC1557 
FUNC1558 reaper.JS_LICE_PutPixel(identifier bitmap, integer x, integer y, number color, number alpha, string mode)
DESC1558 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1559 reaper.JS_LICE_Resize(identifier bitmap, integer width, integer height)
DESC1559 
FUNC1560 reaper.JS_LICE_RotatedBlit(identifier destBitmap, integer dstx, integer dsty, integer dstw, integer dsth, identifier sourceBitmap, number srcx, number srcy, number srcw, number srch, number angle, number rotxcent, number rotycent, boolean cliptosourcerect, number alpha, string mode)
DESC1560 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA" to enable per-pixel alpha blending.
FUNC1561 reaper.JS_LICE_RoundRect(identifier bitmap, number x, number y, number w, number h, integer cornerradius, integer color, number alpha, string mode, boolean antialias)
DESC1561 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA".LICE color format: 0xAARRGGBB (AA is only used in ALPHA mode).
FUNC1562 reaper.JS_LICE_ScaledBlit(identifier destBitmap, integer dstx, integer dsty, integer dstw, integer dsth, identifier srcBitmap, number srcx, number srcy, number srcw, number srch, number alpha, string mode)
DESC1562 LICE modes: "COPY" (default if empty string), "MASK", "ADD", "DODGE", "MUL", "OVERLAY" or "HSVADJ", any of which may be combined with "ALPHA" to enable per-pixel alpha blending.
FUNC1563 reaper.JS_LICE_SetAlphaFromColorMask(identifier bitmap, integer colorRGB)
DESC1563 Sets all pixels that match the given color's RGB values to fully transparent, and all other pixels to fully opaque. (All pixels' RGB values remain unchanged.)
FUNC1564 reaper.JS_LICE_SetFontBkColor(identifier LICEFont, integer color)
DESC1564 
FUNC1565 reaper.JS_LICE_SetFontColor(identifier LICEFont, integer color)
DESC1565 
FUNC1566 reaper.JS_LICE_SetFontFromGDI(identifier LICEFont, identifier GDIFont, string moreFormats)
DESC1566 Converts a GDI font into a LICE font.The font can be modified by the following flags, in a comma-separated list:"VERTICAL", "BOTTOMUP", "NATIVE", "BLUR", "INVERT", "MONO", "SHADOW" or "OUTLINE".
FUNC1567 boolean reaper.JS_LICE_WriteJPG(string filenameLICE_IBitmap bitmap, integer quality, unsupported forceBaseline)
DESC1567 Parameters:* quality is an integer in the range 1..100.* forceBaseline is an optional boolean parameter that ensures compatibility with all JPEG viewers by preventing too low quality, "cubist" settings.
FUNC1568 boolean reaper.JS_LICE_WritePNG(string filenameLICE_IBitmap bitmap, boolean wantAlpha)
DESC1568 
FUNC1569 reaper.JS_ListView_EnsureVisible(identifier listviewHWND, integer index, boolean partialOK)
DESC1569 
FUNC1570 integer reaper.JS_ListView_EnumSelItems(identifier listviewHWND, integer index)
DESC1570 Returns the index of the next selected list item with index greater that the specified number. Returns -1 if no selected items left.
FUNC1571 integer retval, string text = reaper.JS_ListView_GetFocusedItem(identifier listviewHWND)
DESC1571 Returns the index and text of the focused item, if any.
FUNC1572 string text, number state = reaper.JS_ListView_GetItem(identifier listviewHWND, integer index, integer subItem)
DESC1572 Returns the text and state of specified item.
FUNC1573 integer reaper.JS_ListView_GetItemCount(identifier listviewHWND)
DESC1573 
FUNC1574 boolean retval, number left, number top, number right, number bottom = reaper.JS_ListView_GetItemRect(identifier listviewHWND, integer index)
DESC1574 Returns client coordinates of the item.
FUNC1575 integer reaper.JS_ListView_GetItemState(identifier listviewHWND, integer index)
DESC1575 State is a bitmask:1 = selected, 2 = focused. On Windows only, cut-and-paste marked = 4, drag-and-drop highlighted = 8.Warning: this function uses the Win32 bitmask values, which differ from the values used by WDL/swell.
FUNC1576 string text = reaper.JS_ListView_GetItemText(identifier listviewHWND, integer index, integer subItem)
DESC1576 
FUNC1577 integer reaper.JS_ListView_GetSelectedCount(identifier listviewHWND)
DESC1577 
FUNC1578 integer reaper.JS_ListView_GetTopIndex(identifier listviewHWND)
DESC1578 
FUNC1579 number index, number subItem, number flags = reaper.JS_ListView_HitTest(identifier listviewHWND, integer clientX, integer clientY)
DESC1579 
FUNC1580 integer retval, string items = reaper.JS_ListView_ListAllSelItems(identifier listviewHWND)
DESC1580 Returns the indices of all selected items as a comma-separated list.* retval: Number of selected items found; negative or zero if an error occured.
FUNC1581 reaper.JS_ListView_SetItemState(identifier listviewHWND, integer index, integer state, integer mask)
DESC1581 The mask parameter specifies the state bits that must be set, and the state parameter specifies the new values for those bits.1 = selected, 2 = focused. On Windows only, cut-and-paste marked = 4, drag-and-drop highlighted = 8.Warning: this function uses the Win32 bitmask values, which differ from the values used by WDL/swell.
FUNC1582 reaper.JS_ListView_SetItemText(identifier listviewHWND, integer index, integer subItem, string text)
DESC1582 Currently, this fuction only accepts ASCII text.
FUNC1583 string translation = reaper.JS_Localize(string USEnglish, string LangPackSection)
DESC1583 Returns the translation of the given US English text, according to the currently loaded Language Pack.Parameters:* LangPackSection: Language Packs are divided into sections such as "common" or "DLG_102".* In Lua, by default, text of up to 1024 chars can be returned. To increase (or reduce) the default buffer size, a string and size can be included as optional 3rd and 4th arguments.
FUNC1584 Example: reaper.JS_Localize("Actions", "common", "", 20)
DESC1584 
FUNC1585 integer reaper.JS_MIDIEditor_ArrayAll(identifier reaperarray)
DESC1585 Finds all open MIDI windows (whether docked or not).* retval: The number of MIDI editor windows found; negative if an error occurred.
FUNC1586 * The address of each MIDI editor window is stored in the provided reaper.array. Each address can be converted to a REAPER object (HWND) by the function JS_Window_HandleFromAddress.
DESC1586 
FUNC1587 integer retval, string list = reaper.JS_MIDIEditor_ListAll()
DESC1587 Finds all open MIDI windows (whether docked or not).* retval: The number of MIDI editor windows found; negative if an error occurred.* list: Comma-separated string of hexadecimal values. Each value is an address that can be converted to a HWND by the function Window_HandleFromAddress.
FUNC1588 identifier reaper.JS_Mem_Alloc(integer sizeBytes)
DESC1588 Allocates memory for general use by functions that require memory buffers.
FUNC1589 boolean reaper.JS_Mem_Free(identifier mallocPointer)
DESC1589 Frees memory that was previously allocated by JS_Mem_Alloc.
FUNC1590 boolean reaper.JS_Mem_FromString(identifier mallocPointer, integer offset, string packedString, integer stringLength)
DESC1590 Copies a packed string into a memory buffer.
FUNC1591 identifier reaper.JS_Mouse_GetCursor()
DESC1591 On Windows, retrieves a handle to the current mouse cursor.On Linux and macOS, retrieves a handle to the last cursor set by REAPER or its extensions via SWELL.
FUNC1592 integer reaper.JS_Mouse_GetState(integer flags)
DESC1592 Retrieves the states of mouse buttons and modifiers keys.Parameters:* flags, state: The parameter and the return value both use the same format as gfx.mouse_cap. For example, to get the states of the left mouse button and the ctrl key, use flags = 0b00000101.
FUNC1593 identifier reaper.JS_Mouse_LoadCursor(integer cursorNumber)
DESC1593 Loads a cursor by number.cursorNumber: Same as used for gfx.setcursor, and includes some of Windows' predefined cursors (with numbers > 32000; refer to documentation for the Win32 C++ function LoadCursor), and REAPER's own cursors (with numbers < 2000).If successful, returns a handle to the cursor, which can be used in JS_Mouse_SetCursor.
FUNC1594 identifier reaper.JS_Mouse_LoadCursorFromFile(string pathAndFileName, unsupported forceNewLoad)
DESC1594 Loads a cursor from a .cur file.forceNewLoad is an optional boolean parameter:* If omitted or false, and if the .cur file has already been loaded previously during the REAPER session, the file will not be re-loaded, and the previous handle will be returned, thereby (slightly) improving speed and (slighty) lowering memory usage.* If true, the file will be re-loaded and a new handle will be returned.If successful, returns a handle to the cursor, which can be used in JS_Mouse_SetCursor.
FUNC1595 reaper.JS_Mouse_SetCursor(identifier cursorHandle)
DESC1595 Sets the mouse cursor. (Only lasts while script is running, and for a single "defer" cycle.)
FUNC1596 boolean reaper.JS_Mouse_SetPosition(integer x, integer y)
DESC1596 Moves the mouse cursor to the specified screen coordinates.NOTES:* On Windows and Linux, screen coordinates are relative to *upper* left corner of the primary display, and the positive Y-axis points downward.* On macOS, screen coordinates are relative to the *bottom* left corner of the primary display, and the positive Y-axis points upward.
FUNC1597 number version = reaper.JS_ReaScriptAPI_Version()
DESC1597 Returns the version of the js_ReaScriptAPI extension.
FUNC1598 boolean retval, string buf = reaper.JS_String(identifier pointer, integer offset, integer lengthChars)
DESC1598 Returns the memory contents starting at address[offset] as a packed string. Offset is added as steps of 1 byte (char) each.
FUNC1599 string state = reaper.JS_VKeys_GetDown(number cutoffTime)
DESC1599 Returns a 255-byte array that specifies which virtual keys, from 0x01 to 0xFF, have sent KEYDOWN messages since cutoffTime.Notes:* Mouse buttons and modifier keys are not (currently) reliably detected, and JS_Mouse_GetState can be used instead.* Auto-repeated KEYDOWN messages are ignored.
FUNC1600 string state = reaper.JS_VKeys_GetState(number cutoffTime)
DESC1600 Retrieves the current states (0 or 1) of all virtual keys, from 0x01 to 0xFF, in a 255-byte array.cutoffTime: A key is only regarded as down if it sent a KEYDOWN message after the cut-off time, not followed by KEYUP. (This is useful for excluding old KEYDOWN messages that weren't properly followed by KEYUP.)If cutoffTime is positive, is it interpreted as absolute time in similar format as time_precise().If cutoffTime is negative, it is relative to the current time.Notes:* Mouse buttons and modifier keys are not (currently) reliably detected, and JS_Mouse_GetState can be used instead.* Auto-repeated KEYDOWN messages are ignored.
FUNC1601 string state = reaper.JS_VKeys_GetUp(number cutoffTime)
DESC1601 Return a 255-byte array that specifies which virtual keys, from 0x01 to 0xFF, have sent KEYUP messages since cutoffTime.Note: Mouse buttons and modifier keys are not (currently) reliably detected, and JS_Mouse_GetState can be used instead.
FUNC1602 integer reaper.JS_VKeys_Intercept(integer keyCode, integer intercept)
DESC1602 Intercepting (blocking) virtual keys work similar to the native function PreventUIRefresh: Each key has a (non-negative) intercept state, and the key is passed through as usual if the state equals 0, or blocked if the state is greater than 0.keyCode: The virtual key code of the key, or -1 to change the state of all keys.intercept: A script can increase the intercept state by passing +1, or lower the state by passing -1. Multiple scripts can block the same key, and the intercept state may reach up to 255. If zero is passed, the intercept state is not changed, but the current state is returned.Returns: If keyCode refers to a single key, the intercept state of that key is returned. If keyCode = -1, the state of the key that is most strongly blocked (highest intercept state) is returned.
FUNC1603 integer reaper.JS_WindowMessage_Intercept(identifier windowHWND, string message, boolean passThrough)
DESC1603 Begins intercepting a window message type to specified window.Parameters:* message: a single message type to be intercepted, either in WM_ or hexadecimal format. For example "WM_SETCURSOR" or "0x0020".* passThrough: Whether message should be blocked (false) or passed through (true) to the window.For more information on message codes, refer to the Win32 C++ API documentation.All WM_ and CB_ message types listed in swell-types.h should be valid cross-platform, and the function can recognize all of these by name. Other messages can be specified by their hex code.Returns:* 1: Success.* 0: The message type is already being intercepted by another script.* -2: message string could not be parsed.* -3: Failure getting original window process / window not valid.* -6: Could not obtain the window client HDC.Notes:* Intercepted messages can be polled using JS_WindowMessage_Peek.* Intercepted messages can be edited, if necessary, and then forwarded to their original destination using JS_WindowMessage_Post or JS_WindowMessage_Send.* To check whether a message type is being blocked or passed through, Peek the message type, or retrieve the entire List of intercepts.* Mouse events are typically received by the child window under the mouse, not the parent window.Keyboard events are usually *not* received by any individual window. To intercept keyboard events, use the VKey functions.
FUNC1604 integer reaper.JS_WindowMessage_InterceptList(identifier windowHWND, string messages)
DESC1604 Begins intercepting window messages to specified window.Parameters:* messages: comma-separated string of message types to be intercepted (either in WM_ or hexadecimal format), each with a "block" or "passthrough" modifier to specify whether the message should be blocked or passed through to the window. For example "WM_SETCURSOR:block, 0x0201:passthrough".For more information on message codes, refer to the Win32 C++ API documentation.All WM_ and CB_ message types listed in swell-types.h should be valid cross-platform, and the function can recognize all of these by name. Other messages can be specified by their hex code.Returns:* 1: Success.* 0: The message type is already being intercepted by another script.* -1: windowHWND is not a valid window.* -2: message string could not be parsed.* -3: Failure getting original window process.* -6: COuld not obtain the window client HDC.Notes:* Intercepted messages can be polled using JS_WindowMessage_Peek.* Intercepted messages can be edited, if necessary, and then forwarded to their original destination using JS_WindowMessage_Post or JS_WindowMessage_Send.* To check whether a message type is being blocked or passed through, Peek the message type, or retrieve the entire List of intercepts.
FUNC1605 boolean retval, string list = reaper.JS_WindowMessage_ListIntercepts(identifier windowHWND)
DESC1605 Returns a string with a list of all message types currently being intercepted for the specified window.
FUNC1606 integer reaper.JS_WindowMessage_PassThrough(identifier windowHWND, string message, boolean passThrough)
DESC1606 Changes the passthrough setting of a message type that is already being intercepted.Returns 1 if successful, 0 if the message type is not yet being intercepted, or -2 if the argument could not be parsed.
FUNC1607 boolean retval, boolean passedThrough, number time, number wParamLow, number wParamHigh, number lParamLow, number lParamHigh = reaper.JS_WindowMessage_Peek(identifier windowHWND, string message)
DESC1607 Polls the state of an intercepted message.Parameters:* message: String containing a single message name, such as "WM_SETCURSOR", or in hexadecimal format, "0x0020".(For a list of WM_ and CB_ message types that are valid cross-platform, refer to swell-types.h. Only these will be recognized by WM_ or CB_ name.)Returns:* A retval of false indicates that the message type is not being intercepted in the specified window.* All messages are timestamped. A time of 0 indicates that no message if this type has been intercepted yet.* For more information about wParam and lParam for different message types, refer to Win32 C++ documentation.* For example, in the case of mousewheel, returns mousewheel delta, modifier keys, x position and y position.* wParamHigh, lParamLow and lParamHigh are signed, whereas wParamLow is unsigned.
FUNC1608 boolean reaper.JS_WindowMessage_Post(identifier windowHWND, string message, number wParam, integer wParamHighWord, number lParam, integer lParamHighWord)
DESC1608 If the specified window and message type are not currently being intercepted by a script, this function will post the message in the message queue of the specified window, and return without waiting.If the window and message type are currently being intercepted, the message will be sent directly to the original window process, similar to WindowMessage_Send, thereby skipping any intercepts.Parameters:* message: String containing a single message name, such as "WM_SETCURSOR", or in hexadecimal format, "0x0020".(For a list of WM_ and CB_ message types that are valid cross-platform, refer to swell-types.h. Only these will be recognized by WM_ or CB_ name.)* wParam, wParamHigh, lParam and lParamHigh: Low and high 16-bit WORDs of the WPARAM and LPARAM parameters.(Most window messages encode separate information into the two WORDs. However, for those rare cases in which the entire WPARAM and LPARAM must be used to post a large pointer, the script can store this address in wParam or lParam, and keep wParamHigh and lParamHigh zero.)Notes:* For more information about parameter values, refer to documentation for the Win32 C++ function PostMessage.* Messages should only be sent to windows that were created from the main thread.* Useful for simulating mouse clicks and calling mouse modifier actions from scripts.
FUNC1609 integer reaper.JS_WindowMessage_Release(identifier windowHWND, string messages)
DESC1609 Release intercepts of specified message types.Parameters:* messages: "WM_SETCURSOR,WM_MOUSEHWHEEL" or "0x0020,0x020E", for example.
FUNC1610 reaper.JS_WindowMessage_ReleaseAll()
DESC1610 Release script intercepts of window messages for all windows.
FUNC1611 reaper.JS_WindowMessage_ReleaseWindow(identifier windowHWND)
DESC1611 Release script intercepts of window messages for specified window.
FUNC1612 integer reaper.JS_WindowMessage_Send(identifier windowHWND, string message, number wParam, integer wParamHighWord, number lParam, integer lParamHighWord)
DESC1612 Sends a message to the specified window by calling the window process directly, and only returns after the message has been processed. Any intercepts of the message by scripts will be skipped, and the message can therefore not be blocked.Parameters:* message: String containing a single message name, such as "WM_SETCURSOR", or in hexadecimal format, "0x0020".(For a list of WM_ and CB_ message types that are valid cross-platform, refer to swell-types.h. Only these will be recognized by WM_ or CB_ name.)* wParam, wParamHigh, lParam and lParamHigh: Low and high 16-bit WORDs of the WPARAM and LPARAM parameters.(Most window messages encode separate information into the two WORDs. However, for those rare cases in which the entire WPARAM and LPARAM must be used to post a large pointer, the script can store this address in wParam or lParam, and keep wParamHigh and lParamHigh zero.)Notes:* For more information about parameter and return values, refer to documentation for the Win32 C++ function SendMessage.* Messages should only be sent to windows that were created from the main thread.* Useful for simulating mouse clicks and calling mouse modifier actions from scripts.
FUNC1613 number address = reaper.JS_Window_AddressFromHandle(identifier handle)
DESC1613 
FUNC1614 integer reaper.JS_Window_ArrayAllChild(identifier parentHWND, identifier reaperarray)
DESC1614 Finds all child windows of the specified parent.Returns:* retval: The number of windows found; negative if an error occurred.
FUNC1615 * The addresses are stored in the provided reaper.array, and can be converted to REAPER objects (HWNDs) by the function JS_Window_HandleFromAddress.
DESC1615 
FUNC1616 integer reaper.JS_Window_ArrayAllTop(identifier reaperarray)
DESC1616 Finds all top-level windows.Returns:* retval: The number of windows found; negative if an error occurred.
FUNC1617 * The addresses are stored in the provided reaper.array, and can be converted to REAPER objects (HWNDs) by the function JS_Window_HandleFromAddress.
DESC1617 
FUNC1618 integer reaper.JS_Window_ArrayFind(string title, boolean exact, identifier reaperarray)
DESC1618 Finds all windows, whether top-level or child, whose titles match the specified string.Returns:* retval: The number of windows found; negative if an error occurred.
FUNC1619 * The addresses are stored in the provided reaper.array, and can be converted to REAPER objects (HWNDs) by the function JS_Window_HandleFromAddress.
DESC1619 Parameters:* exact: Match entire title exactly, or match substring of title.
FUNC1620 reaper.JS_Window_AttachResizeGrip(identifier windowHWND)
DESC1620 
FUNC1621 reaper.JS_Window_AttachTopmostPin(identifier windowHWND)
DESC1621 Attaches a "pin on top" button to the window frame. The button should remember its state when closing and re-opening the window.WARNING: This function does not yet work on Linux.
FUNC1622 number x, number y = reaper.JS_Window_ClientToScreen(identifier windowHWND, integer x, integer y)
DESC1622 Converts the client-area coordinates of a specified point to screen coordinates.NOTES:* On Windows and Linux, screen coordinates are relative to *upper* left corner of the primary display, and the positive Y-axis points downward.* On macOS, screen coordinates are relative to the *bottom* left corner of the primary display, and the positive Y-axis points upward.* On all platforms, client coordinates are relative to the upper left corner of the client area.
FUNC1623 identifier retval, optional string style = reaper.JS_Window_Create(string title, string className, integer x, integer y, integer w, integer h, optional string style, identifier ownerHWND)
DESC1623 Creates a modeless window with WS_OVERLAPPEDWINDOW style and only rudimentary features. Scripts can paint into the window using GDI or LICE/Composite functions (and JS_Window_InvalidateRect to trigger re-painting).style: An optional parameter that overrides the default style. The string may include any combination of standard window styles, such as "POPUP" for a frameless window, or "CAPTION,SIZEBOX,SYSMENU" for a standard framed window.On Linux and macOS, "MAXIMIZE" has not yet been implemented, and the remaining styles may appear slightly different from their WindowsOS counterparts.className: On Windows, only standard ANSI characters are supported.ownerHWND: Optional parameter, only available on WindowsOS. Usually either the REAPER main window or another script window, and useful for ensuring that the created window automatically closes when the owner is closed.NOTE: On Linux and macOS, the window contents are only updated *between* defer cycles, so the window cannot be animated by for/while loops within a single defer cycle.
FUNC1624 reaper.JS_Window_Destroy(identifier windowHWND)
DESC1624 Destroys the specified window.
FUNC1625 reaper.JS_Window_Enable(identifier windowHWND, boolean enable)
DESC1625 Enables or disables mouse and keyboard input to the specified window or control.
FUNC1626 integer reaper.JS_Window_EnableMetal(identifier windowHWND)
DESC1626 On macOS, returns the Metal graphics setting:2 = Metal enabled and support GetDC()/ReleaseDC() for drawing (more overhead).1 = Metal enabled.0 = N/A (Windows and Linux).-1 = non-metal async layered mode.-2 = non-metal non-async layered mode.WARNING: If using mode -1, any BitBlt()/StretchBlt() MUST have the source bitmap persist. If it is resized after Blit it could cause crashes.
FUNC1627 identifier reaper.JS_Window_Find(string title, boolean exact)
DESC1627 Returns a HWND to a window whose title matches the specified string.* Unlike the Win32 function FindWindow, this function searches top-level as well as child windows, so that the target window can be found irrespective of docked state.* In addition, the function can optionally match substrings of the title.* Matching is not case sensitive.Parameters:* exact: Match entire title, or match substring of title.
FUNC1628 identifier reaper.JS_Window_FindChild(identifier parentHWND, string title, boolean exact)
DESC1628 Returns a HWND to a child window whose title matches the specified string.Parameters:* exact: Match entire title length, or match substring of title. In both cases, matching is not case sensitive.
FUNC1629 identifier reaper.JS_Window_FindChildByID(identifier parentHWND, integer ID)
DESC1629 Similar to the C++ WIN32 function GetDlgItem, this function finds child windows by ID.(The ID of a window may be retrieved by JS_Window_GetLongPtr.)
FUNC1630 identifier reaper.JS_Window_FindEx(identifier parentHWND, identifier childHWND, string className, string title)
DESC1630 Returns a handle to a child window whose class and title match the specified strings.Parameters: * childWindow: The function searches child windows, beginning with the window *after* the specified child window. If childHWND is equal to parentHWND, the search begins with the first child window of parentHWND.* title: An empty string, "", will match all windows. (Search is not case sensitive.)
FUNC1631 identifier reaper.JS_Window_FindTop(string title, boolean exact)
DESC1631 Returns a HWND to a top-level window whose title matches the specified string.Parameters:* exact: Match entire title length, or match substring of title. In both cases, matching is not case sensitive.
FUNC1632 identifier reaper.JS_Window_FromPoint(integer x, integer y)
DESC1632 Retrieves a HWND to the window that contains the specified point.NOTES:* On Windows and Linux, screen coordinates are relative to *upper* left corner of the primary display, and the positive Y-axis points downward.* On macOS, screen coordinates are relative to the *bottom* left corner of the primary display, and the positive Y-axis points upward.
FUNC1633 string class = reaper.JS_Window_GetClassName(identifier windowHWND)
DESC1633 WARNING: May not be fully implemented on macOS and Linux.
FUNC1634 boolean retval, number left, number top, number right, number bottom = reaper.JS_Window_GetClientRect(identifier windowHWND)
DESC1634 Retrieves the screen coordinates of the client area rectangle of the specified window.NOTES:* Unlike the C++ function GetClientRect, this function returns the screen coordinates, not the width and height. To get the client size, use GetClientSize.* The pixel at (right, bottom) lies immediately outside the rectangle.* On Windows and Linux, screen coordinates are relative to *upper* left corner of the primary display, and the positive Y-axis points downward.* On macOS, screen coordinates are relative to the *bottom* left corner of the primary display, and the positive Y-axis points upward.
FUNC1635 boolean retval, number width, number height = reaper.JS_Window_GetClientSize(identifier windowHWND)
DESC1635 
FUNC1636 identifier reaper.JS_Window_GetFocus()
DESC1636 Retrieves a HWND to the window that has the keyboard focus, if the window is attached to the calling thread's message queue.
FUNC1637 identifier reaper.JS_Window_GetForeground()
DESC1637 Retrieves a HWND to the top-level foreground window (the window with which the user is currently working).
FUNC1638 number retval = reaper.JS_Window_GetLong(identifier windowHWND, string info)
DESC1638 Similar to JS_Window_GetLongPtr, but returns the information as a number instead of a pointer.In the case of "DLGPROC" and "WNDPROC", the return values can be converted to pointers by JS_Window_HandleFromAddress.If the function fails, the return value is 0.
FUNC1639 identifier reaper.JS_Window_GetLongPtr(identifier windowHWND, string info)
DESC1639 Returns information about the specified window.info: "USERDATA", "WNDPROC", "DLGPROC", "ID", "EXSTYLE" or "STYLE".For documentation about the types of information returned, refer to the Win32 function GetWindowLongPtr.The values returned by "DLGPROC" and "WNDPROC" are typically used as-is, as pointers, whereas the others should first be converted to integers.If the function fails, a null pointer is returned.
FUNC1640 identifier reaper.JS_Window_GetParent(identifier windowHWND)
DESC1640 Retrieves a HWND to the specified window's parent or owner.Returns NULL if the window is unowned or if the function otherwise fails.
FUNC1641 boolean retval, number left, number top, number right, number bottom = reaper.JS_Window_GetRect(identifier windowHWND)
DESC1641 Retrieves the screen coordinates of the bounding rectangle of the specified window.NOTES:* On Windows and Linux, coordinates are relative to *upper* left corner of the primary display, and the positive Y-axis points downward.* On macOS, coordinates are relative to the *bottom* left corner of the primary display, and the positive Y-axis points upward.* The pixel at (right, bottom) lies immediately outside the rectangle.
FUNC1642 identifier reaper.JS_Window_GetRelated(identifier windowHWND, string relation)
DESC1642 Retrieves a handle to a window that has the specified relationship (Z-Order or owner) to the specified window.relation: "LAST", "NEXT", "PREV", "OWNER" or "CHILD".(Refer to documentation for Win32 C++ function GetWindow.)
FUNC1643 boolean retval, number position, number pageSize, number min, number max, number trackPos = reaper.JS_Window_GetScrollInfo(identifier windowHWND, string scrollbar)
DESC1643 Retrieves the scroll information of a window.Parameters:* windowHWND: The window that contains the scrollbar. This is usually a child window, not a top-level, framed window.* scrollbar: "v" (or "SB_VERT", or "VERT") for vertical scroll, "h" (or "SB_HORZ" or "HORZ") for horizontal.Returns:* Leftmost or topmost visible pixel position, as well as the visible page size, the range minimum and maximum, and scroll box tracking position.
FUNC1644 string title = reaper.JS_Window_GetTitle(identifier windowHWND)
DESC1644 Returns the title (if any) of the specified window.
FUNC1645 number left, number top, number right, number bottom = reaper.JS_Window_GetViewportFromRect(integer x1, integer y1, integer x2, integer y2, boolean wantWork)
DESC1645 Retrieves the dimensions of the display monitor that has the largest area of intersection with the specified rectangle.If the monitor is not the primary display, some of the rectangle's coordinates may be negative.wantWork: Returns the work area of the display, which excludes the system taskbar or application desktop toolbars.
FUNC1646 identifier reaper.JS_Window_HandleFromAddress(number address)
DESC1646 Converts an address to a handle (such as a HWND) that can be utilized by REAPER and other API functions.
FUNC1647 boolean reaper.JS_Window_InvalidateRect(identifier windowHWND, integer left, integer top, integer right, integer bottom, boolean eraseBackground)
DESC1647 Similar to the Win32 function InvalidateRect.
FUNC1648 boolean reaper.JS_Window_IsChild(identifier parentHWND, identifier childHWND)
DESC1648 Determines whether a window is a child window or descendant window of a specified parent window.
FUNC1649 boolean reaper.JS_Window_IsVisible(identifier windowHWND)
DESC1649 Determines the visibility state of the window.
FUNC1650 boolean reaper.JS_Window_IsWindow(identifier windowHWND)
DESC1650 Determines whether the specified window handle identifies an existing window.On macOS and Linux, only windows that were created by WDL/swell will be identified (and only such windows should be acted on by scripts).NOTE: Since REAPER v5.974, windows can be checked using the native function ValidatePtr(windowHWND, "HWND").
FUNC1651 integer retval, string list = reaper.JS_Window_ListAllChild(identifier parentHWND)
DESC1651 Finds all child windows of the specified parent.Returns:* retval: The number of windows found; negative if an error occurred.* list: A comma-separated string of hexadecimal values.Each value is an address that can be converted to a HWND by the function Window_HandleFromAddress.
FUNC1652 integer retval, string list = reaper.JS_Window_ListAllTop()
DESC1652 Finds all top-level windows.Returns:* retval: The number of windows found; negative if an error occurred.* list: A comma-separated string of hexadecimal values. Each value is an address that can be converted to a HWND by the function Window_HandleFromAddress.
FUNC1653 integer retval, string list = reaper.JS_Window_ListFind(string title, boolean exact)
DESC1653 Finds all windows (whether top-level or child) whose titles match the specified string.Returns:* retval: The number of windows found; negative if an error occurred.* list: A comma-separated string of hexadecimal values. Each value is an address that can be converted to a HWND by the function Window_HandleFromAddress.Parameters:* exact: Match entire title exactly, or match substring of title.
FUNC1654 number left, number top, number right, number bottom = reaper.JS_Window_MonitorFromRect(integer x1, integer y1, integer x2, integer y2, boolean wantWork)
DESC1654 Deprecated - use GetViewportFromRect instead.
FUNC1655 reaper.JS_Window_Move(identifier windowHWND, integer left, integer top)
DESC1655 Changes the position of the specified window, keeping its size constant.NOTES:* For top-level windows, position is relative to the primary display.* On Windows and Linux, position is calculated as the coordinates of the upper left corner of the window, relative to upper left corner of the primary display, and the positive Y-axis points downward.* On macOS, position is calculated as the coordinates of the bottom left corner of the window, relative to bottom left corner of the display, and the positive Y-axis points upward.* For a child window, on all platforms, position is relative to the upper-left corner of the parent window's client area.* Equivalent to calling JS_Window_SetPosition with NOSIZE, NOZORDER, NOACTIVATE and NOOWNERZORDER flags set.
FUNC1656 boolean reaper.JS_Window_OnCommand(identifier windowHWND, integer commandID)
DESC1656 Sends a "WM_COMMAND" message to the specified window, which simulates a user selecting a command in the window menu.This function is similar to Main_OnCommand and MIDIEditor_OnCommand, but can send commands to any window that has a menu.In the case of windows that are listed among the Action list's contexts (such as the Media Explorer), the commandIDs of the actions in the Actions list may be used.
FUNC1657 reaper.JS_Window_Resize(identifier windowHWND, integer width, integer height)
DESC1657 Changes the dimensions of the specified window, keeping the top left corner position constant.* If resizing script GUIs, call gfx.update() after resizing.* Equivalent to calling JS_Window_SetPosition with NOMOVE, NOZORDER, NOACTIVATE and NOOWNERZORDER flags set.
FUNC1658 number x, number y = reaper.JS_Window_ScreenToClient(identifier windowHWND, integer x, integer y)
DESC1658 Converts the screen coordinates of a specified point on the screen to client-area coordinates.NOTES:* On Windows and Linux, screen coordinates are relative to *upper* left corner of the primary display, and the positive Y-axis points downward.* On macOS, screen coordinates are relative to the *bottom* left corner of the primary display, and the positive Y-axis points upward.* On all platforms, client coordinates are relative to the upper left corner of the client area.
FUNC1659 reaper.JS_Window_SetFocus(identifier windowHWND)
DESC1659 Sets the keyboard focus to the specified window.
FUNC1660 reaper.JS_Window_SetForeground(identifier windowHWND)
DESC1660 Brings the specified window into the foreground, activates the window, and directs keyboard input to it.
FUNC1661 number retval = reaper.JS_Window_SetLong(identifier windowHWND, string info, number value)
DESC1661 Similar to the Win32 function SetWindowLongPtr.info: "USERDATA", "WNDPROC", "DLGPROC", "ID", "EXSTYLE" or "STYLE", and only on WindowOS, "INSTANCE" and "PARENT".
FUNC1662 boolean reaper.JS_Window_SetOpacity(identifier windowHWND, string mode, number value)
DESC1662 Sets the window opacity.Parameters:mode: either "ALPHA" or "COLOR".value: If ALPHA, the specified value may range from zero to one, and will apply to the entire window, frame included.If COLOR, value specifies a 0xRRGGBB color, and all pixels of this color will be made transparent. (All mouse clicks over transparent pixels will pass through, too). WARNING:COLOR mode is only available in Windows, not Linux or macOS.Transparency can only be applied to top-level windows. If windowHWND refers to a child window, the entire top-level window that contains windowHWND will be made transparent.
FUNC1663 identifier reaper.JS_Window_SetParent(identifier childHWND, identifier parentHWND)
DESC1663 If successful, returns a handle to the previous parent window.Only on WindowsOS: If parentHWND is not specified, the desktop window becomes the new parent window.
FUNC1664 boolean retval, optional string ZOrder, optional string flags = reaper.JS_Window_SetPosition(identifier windowHWND, integer left, integer top, integer width, integer height, optional string ZOrder, optional string flags)
DESC1664 Interface to the Win32/swell function SetWindowPos, with which window position, size, Z-order and visibility can be set, and new frame styles can be applied.ZOrder and flags are optional parameters. If no arguments are supplied, the window will simply be moved and resized, as if the NOACTIVATE, NOZORDER, NOOWNERZORDER flags were set.* ZOrder: "BOTTOM", "TOPMOST", "NOTOPMOST", "TOP" or a window HWND converted to a string, for example by the Lua function tostring.* flags: Any combination of the standard flags, of which "NOMOVE", "NOSIZE", "NOZORDER", "NOACTIVATE", "SHOWWINDOW", "FRAMECHANGED" and "NOCOPYBITS" should be valid cross-platform.
FUNC1665 boolean reaper.JS_Window_SetScrollPos(identifier windowHWND, string scrollbar, integer position)
DESC1665 Parameters:* scrollbar: "v" (or "SB_VERT", or "VERT") for vertical scroll, "h" (or "SB_HORZ" or "HORZ") for horizontal.NOTE: API functions can scroll REAPER's windows, but cannot zoom them. Instead, use actions such as "View: Zoom to one loop iteration".
FUNC1666 boolean retval, string style = reaper.JS_Window_SetStyle(identifier windowHWND, string style)
DESC1666 Sets and applies a window style.style may include any combination of standard window styles, such as "POPUP" for a frameless window, or "CAPTION,SIZEBOX,SYSMENU" for a standard framed window.On Linux and macOS, "MAXIMIZE" has not yet been implmented, and the remaining styles may appear slightly different from their WindowsOS counterparts.
FUNC1667 boolean reaper.JS_Window_SetTitle(identifier windowHWND, string title)
DESC1667 Changes the title of the specified window. Returns true if successful.
FUNC1668 boolean reaper.JS_Window_SetZOrder(identifier windowHWND, string ZOrder, identifier insertAfterHWND)
DESC1668 Sets the window Z order.* Equivalent to calling JS_Window_SetPos with flags NOMOVE | NOSIZE.* Not all the Z orders have been implemented in Linux yet.Parameters:* ZOrder: "BOTTOM", "TOPMOST", "NOTOPMOST", "TOP", or a window HWND converted to a string, for example by the Lua function tostring.* InsertAfterHWND: For compatibility with older versions, this parameter is still available, and is optional. If ZOrder is "INSERTAFTER", insertAfterHWND must be a handle to the window behind which windowHWND will be placed in the Z order, equivalent to setting ZOrder to this HWND; otherwise, insertAfterHWND is ignored and can be left out (or it can simply be set to the same value as windowHWND).
FUNC1669 reaper.JS_Window_Show(identifier windowHWND, string state)
DESC1669 Sets the specified window's show state.Parameters:* state: One of the following options: "SHOW", "SHOWNA" (or "SHOWNOACTIVATE"), "SHOWMINIMIZED", "HIDE", "NORMAL", "SHOWNORMAL", "SHOWMAXIMIZED", "SHOWDEFAULT" or "RESTORE". On Linux and macOS, only the first four options are fully implemented.
FUNC1670 reaper.JS_Window_Update(identifier windowHWND)
DESC1670 Similar to the Win32 function UpdateWindow.
FUNC1671 boolean reaper.NF_AnalyzeMediaItemPeakAndRMS(MediaItem item, number windowSize, identifier reaper.array_peaks, identifier reaper.array_peakpositions, identifier reaper.array_RMSs, identifier reaper.array_RMSpositions)
DESC1671 
FUNC1672 This function combines all other NF_Peak/RMS functions in a single one and additionally returns peak RMS positions. Lua example code here. Note: It's recommended to use this function with ReaScript/Lua as it provides reaper.array objects. If using this function with other scripting languages, you must provide arrays in the reaper.array format.
DESC1672 
FUNC1673 boolean retval, number lufsIntegrated, number range, number truePeak, number truePeakPos, number shortTermMax, number momentaryMax = reaper.NF_AnalyzeTakeLoudness(MediaItem_Take take, boolean analyzeTruePeak)
DESC1673 Full loudness analysis. retval: returns true on successful analysis, false on MIDI take or when analysis failed for some reason. analyzeTruePeak=true: Also do true peak analysis. Returns true peak value and true peak position (relative to item position). Considerably slower than without true peak analysis (since it uses oversampling). Note: Short term uses a time window of 3 sec. for calculation. So for items shorter than this shortTermMaxOut can't be calculated correctly. Momentary uses a time window of 0.4 sec.
FUNC1674 boolean retval, number lufsIntegrated, number range, number truePeak, number truePeakPos, number shortTermMax, number momentaryMax, number shortTermMaxPos, number momentaryMaxPos = reaper.NF_AnalyzeTakeLoudness2(MediaItem_Take take, boolean analyzeTruePeak)
DESC1674 Same as NF_AnalyzeTakeLoudness but additionally returns shortTermMaxPos and momentaryMaxPos (in absolute project time). Note: shortTermMaxPos and momentaryMaxPos actaully indicate the beginning of time intervalls, (3 sec. and 0.4 sec. resp.).
FUNC1675 boolean retval, number lufsIntegrated = reaper.NF_AnalyzeTakeLoudness_IntegratedOnly(MediaItem_Take take)
DESC1675 Does LUFS integrated analysis only. Faster than full loudness analysis (NF_AnalyzeTakeLoudness) . Use this if only LUFS integrated is required. Take vol. env. is taken into account. See: Signal flow
FUNC1676 number reaper.NF_GetMediaItemAverageRMS(MediaItem item)
DESC1676 Returns the average overall (non-windowed) RMS level of active channels of an audio item active take, post item gain, post take volume envelope, post-fade, pre fader, pre item FX.Returns -150.0 if MIDI take or empty item.
FUNC1677 number reaper.NF_GetMediaItemMaxPeak(MediaItem item)
DESC1677 Returns the greatest max. peak value of all active channels of an audio item active take, post item gain, post take volume envelope, post-fade, pre fader, pre item FX.Returns -150.0 if MIDI take or empty item.
FUNC1678 number retval, number maxPeakPos = reaper.NF_GetMediaItemMaxPeakAndMaxPeakPos(MediaItem item)
DESC1678 See NF_GetMediaItemMaxPeak, additionally returns maxPeakPos (relative to item position).
FUNC1679 number reaper.NF_GetMediaItemPeakRMS_NonWindowed(MediaItem item)
DESC1679 Returns the greatest overall (non-windowed) RMS peak level of all active channels of an audio item active take, post item gain, post take volume envelope, post-fade, pre fader, pre item FX.Returns -150.0 if MIDI take or empty item.
FUNC1680 number reaper.NF_GetMediaItemPeakRMS_Windowed(MediaItem item)
DESC1680 Returns the average RMS peak level of all active channels of an audio item active take, post item gain, post take volume envelope, post-fade, pre fader, pre item FX.Obeys 'Window size for peak RMS' setting in 'SWS: Set RMS analysis/normalize options' for calculation. Returns -150.0 if MIDI take or empty item.
FUNC1681 string reaper.NF_GetSWSMarkerRegionSub(integer markerRegionIdx)
DESC1681 Returns SWS/S&M marker/region subtitle. markerRegionIdx: Refers to index that can be passed to EnumProjectMarkers (not displayed marker/region index). Returns empty string if marker/region with specified index not found or marker/region subtitle not set. Lua code example here.
FUNC1682 string reaper.NF_GetSWSTrackNotes(MediaTrack track)
DESC1682 
FUNC1683 boolean reaper.NF_SetSWSMarkerRegionSub(string markerRegionSub, integer markerRegionIdx)
DESC1683 Set SWS/S&M marker/region subtitle. markerRegionIdx: Refers to index that can be passed to EnumProjectMarkers (not displayed marker/region index). Returns true if subtitle is set successfully (i.e. marker/region with specified index is present in project). Lua code example here.
FUNC1684 reaper.NF_SetSWSTrackNotes(MediaTrack track, string str)
DESC1684 
FUNC1685 reaper.NF_UpdateSWSMarkerRegionSubWindow()
DESC1685 Redraw the Notes window (call if you've changed a subtitle via NF_SetSWSMarkerRegionSub which is currently displayed in the Notes window and you want to appear the new subtitle immediately.)
FUNC1686 boolean reaper.ReaPack_AboutInstalledPackage(PackageEntry entry)
DESC1686 Show the about dialog of the given package entry.The repository index is downloaded asynchronously if the cached copy doesn't exist or is older than one week.
FUNC1687 boolean reaper.ReaPack_AboutRepository(string repoName)
DESC1687 Show the about dialog of the given repository. Returns true if the repository exists in the user configuration.The repository index is downloaded asynchronously if the cached copy doesn't exist or is older than one week.
FUNC1688 boolean retval, string error = reaper.ReaPack_AddSetRepository(string name, string url, boolean enable, integer autoInstall)
DESC1688 Add or modify a repository. Set url to nullptr (or empty string in Lua) to keep the existing URL. Call ReaPack_ProcessQueue(true) when done to process the new list and update the GUI.autoInstall: usually set to 2 (obey user setting).
FUNC1689 reaper.ReaPack_BrowsePackages(string filter)
DESC1689 Opens the package browser with the given filter string.
FUNC1690 integer retval, string error = reaper.ReaPack_CompareVersions(string ver1, string ver2)
DESC1690 Returns 0 if both versions are equal, a positive value if ver1 is higher than ver2 and a negative value otherwise.
FUNC1691 boolean retval, string path, number sections, number type = reaper.ReaPack_EnumOwnedFiles(PackageEntry entry, integer index)
DESC1691 Enumerate the files owned by the given package. Returns false when there is no more data.sections: 0=not in action list, &1=main, &2=midi editor, &4=midi inline editortype: see ReaPack_GetEntryInfo.
FUNC1692 boolean reaper.ReaPack_FreeEntry(PackageEntry entry)
DESC1692 Free resources allocated for the given package entry.
FUNC1693 boolean retval, string repo, string cat, string pkg, string desc, number type, string ver, string author, boolean pinned, number fileCount = reaper.ReaPack_GetEntryInfo(PackageEntry entry)
DESC1693 Get the repository name, category, package name, package description, package type, the currently installed version, author name, pinned status and how many files are owned by the given package entry.type: 1=script, 2=extension, 3=effect, 4=data, 5=theme, 6=langpack, 7=webinterface
FUNC1694 PackageEntry retval, string error = reaper.ReaPack_GetOwner(string fn)
DESC1694 Returns the package entry owning the given file.Delete the returned object from memory after use with ReaPack_FreeEntry.
FUNC1695 boolean retval, string url, boolean enabled, number autoInstall = reaper.ReaPack_GetRepositoryInfo(string name)
DESC1695 Get the infos of the given repository.autoInstall: 0=manual, 1=when sychronizing, 2=obey user setting
FUNC1696 reaper.ReaPack_ProcessQueue(boolean refreshUI)
DESC1696 Run pending operations and save the configuration file. If refreshUI is true the browser and manager windows are guaranteed to be refreshed (otherwise it depends on which operations are in the queue).
FUNC1697 boolean reaper.SNM_AddReceive(MediaTrack src, MediaTrack dest, integer type)
DESC1697 [S&M] Deprecated, see CreateTrackSend (v5.15pre1+). Adds a receive. Returns false if nothing updated.type -1=Default type (user preferences), 0=Post-Fader (Post-Pan), 1=Pre-FX, 2=deprecated, 3=Pre-Fader (Post-FX).Note: obeys default sends preferences, supports frozen tracks, etc..
FUNC1698 boolean reaper.SNM_AddTCPFXParm(MediaTrack tr, integer fxId, integer prmId)
DESC1698 [S&M] Add an FX parameter knob in the TCP. Returns false if nothing updated (invalid parameters, knob already present, etc..)
FUNC1699 WDL_FastString reaper.SNM_CreateFastString(string str)
DESC1699 [S&M] Instantiates a new "fast string". You must delete this string, see SNM_DeleteFastString.
FUNC1700 reaper.SNM_DeleteFastString(WDL_FastString str)
DESC1700 [S&M] Deletes a "fast string" instance.
FUNC1701 number reaper.SNM_GetDoubleConfigVar(string varname, number errvalue)
DESC1701 [S&M] Returns a double preference (look in project prefs first, then in general prefs). Returns errvalue if failed (e.g. varname not found).
FUNC1702 string reaper.SNM_GetFastString(WDL_FastString str)
DESC1702 [S&M] Gets the "fast string" content.
FUNC1703 integer reaper.SNM_GetFastStringLength(WDL_FastString str)
DESC1703 [S&M] Gets the "fast string" length.
FUNC1704 integer reaper.SNM_GetIntConfigVar(string varname, integer errvalue)
DESC1704 [S&M] Returns an integer preference (look in project prefs first, then in general prefs). Returns errvalue if failed (e.g. varname not found).
FUNC1705 MediaItem_Take reaper.SNM_GetMediaItemTakeByGUID(ReaProject project, string guid)
DESC1705 [S&M] Gets a take by GUID as string. The GUID must be enclosed in braces {}. To get take GUID as string, see BR_GetMediaItemTakeGUID
FUNC1706 boolean reaper.SNM_GetProjectMarkerName(ReaProject proj, integer num, boolean isrgnWDL_FastString name)
DESC1706 [S&M] Gets a marker/region name. Returns true if marker/region found.
FUNC1707 boolean reaper.SNM_GetSetObjectState(identifier objWDL_FastString state, boolean setnewvalue, boolean wantminimalstate)
DESC1707 [S&M] Gets or sets the state of a track, an item or an envelope. The state chunk size is unlimited. Returns false if failed.When getting a track state (and when you are not interested in FX data), you can use wantminimalstate=true to radically reduce the length of the state. Do not set such minimal states back though, this is for read-only applications!Note: unlike the native GetSetObjectState, calling to FreeHeapPtr() is not required.
FUNC1708 boolean reaper.SNM_GetSetSourceState(MediaItem item, integer takeidxWDL_FastString state, boolean setnewvalue)
DESC1708 [S&M] Gets or sets a take source state. Returns false if failed. Use takeidx=-1 to get/alter the active take.Note: this function does not use a MediaItem_Take* param in order to manage empty takes (i.e. takes with MediaItem_Take*==NULL), see SNM_GetSetSourceState2.
FUNC1709 boolean reaper.SNM_GetSetSourceState2(MediaItem_Take takeWDL_FastString state, boolean setnewvalue)
DESC1709 [S&M] Gets or sets a take source state. Returns false if failed.Note: this function cannot deal with empty takes, see SNM_GetSetSourceState.
FUNC1710 boolean reaper.SNM_GetSourceType(MediaItem_Take takeWDL_FastString type)
DESC1710 [S&M] Gets the source type of a take. Returns false if failed (e.g. take with empty source, etc..)
FUNC1711 boolean reaper.SNM_MoveOrRemoveTrackFX(MediaTrack tr, integer fxId, integer what)
DESC1711 [S&M] Deprecated, see TakeFX_/TrackFX_ CopyToTrack/Take, TrackFX/TakeFX _Delete (v5.95pre2+). Move or removes a track FX. Returns true if tr has been updated.fxId: fx index in chain or -1 for the selected fx. what: 0 to remove, -1 to move fx up in chain, 1 to move fx down in chain.
FUNC1712 boolean retval, string tagval = reaper.SNM_ReadMediaFileTag(string fn, string tag, string tagval)
DESC1712 [S&M] Reads a media file tag. Supported tags: "artist", "album", "genre", "comment", "title", or "year". Returns false if tag was not found. See SNM_TagMediaFile.
FUNC1713 boolean reaper.SNM_RemoveReceive(MediaTrack tr, integer rcvidx)
DESC1713 [S&M] Deprecated, see RemoveTrackSend (v5.15pre1+). Removes a receive. Returns false if nothing updated.
FUNC1714 boolean reaper.SNM_RemoveReceivesFrom(MediaTrack tr, MediaTrack srctr)
DESC1714 [S&M] Removes all receives from srctr. Returns false if nothing updated.
FUNC1715 integer reaper.SNM_SelectResourceBookmark(string name)
DESC1715 [S&M] Select a bookmark of the Resources window. Returns the related bookmark id (or -1 if failed).
FUNC1716 boolean reaper.SNM_SetDoubleConfigVar(string varname, number newvalue)
DESC1716 [S&M] Sets a double preference (look in project prefs first, then in general prefs). Returns false if failed (e.g. varname not found).
FUNC1717 WDL_FastString reaper.SNM_SetFastString(WDL_FastString str, string newstr)
DESC1717 [S&M] Sets the "fast string" content. Returns str for facility.
FUNC1718 boolean reaper.SNM_SetIntConfigVar(string varname, integer newvalue)
DESC1718 [S&M] Sets an integer preference (look in project prefs first, then in general prefs). Returns false if failed (e.g. varname not found).
FUNC1719 boolean reaper.SNM_SetProjectMarker(ReaProject proj, integer num, boolean isrgn, number pos, number rgnend, string name, integer color)
DESC1719 [S&M] Deprecated, see SetProjectMarker4 -- Same function as SetProjectMarker3() except it can set empty names "".
FUNC1720 boolean reaper.SNM_TagMediaFile(string fn, string tag, string tagval)
DESC1720 [S&M] Tags a media file thanks to TagLib. Supported tags: "artist", "album", "genre", "comment", "title", or "year". Use an empty tagval to clear a tag. When a file is opened in REAPER, turn it offline before using this function. Returns false if nothing updated. See SNM_ReadMediaFileTag.
FUNC1721 reaper.SNM_TieResourceSlotActions(integer bookmarkId)
DESC1721 [S&M] Attach Resources slot actions to a given bookmark.
FUNC1722 reaper.SN_FocusMIDIEditor()
DESC1722 Focuses the active/open MIDI editor.
FUNC1723 string reaper.ULT_GetMediaItemNote(MediaItem item)
DESC1723 [ULT] Get item notes.
FUNC1724 reaper.ULT_SetMediaItemNote(MediaItem item, string note)
DESC1724 [ULT] Set item notes.
FUNC1725 AudioWriter reaper.Xen_AudioWriter_Create(string filename, integer numchans, integer samplerate)
DESC1725 Creates writer for 32 bit floating point WAV
FUNC1726 reaper.Xen_AudioWriter_Destroy(AudioWriter writer)
DESC1726 Destroys writer
FUNC1727 integer reaper.Xen_AudioWriter_Write(AudioWriter writer, integer numframes, identifier data, integer offset)
DESC1727 Write interleaved audio data to disk
FUNC1728 integer reaper.Xen_GetMediaSourceSamples(PCM_source src, identifier destbuf, integer destbufoffset, integer numframes, integer numchans, number samplerate, number sourceposition)
DESC1728 Get interleaved audio data from media source
FUNC1729 integer reaper.Xen_StartSourcePreview(PCM_source source, number gain, boolean loop, optional number outputchanindexIn)
DESC1729 Start audio preview of a PCM_source. Returns id of a preview handle that can be provided to Xen_StopSourcePreview.If the given PCM_source does not belong to an existing MediaItem/Take, it will be deleted by the preview system when the preview is stopped.
FUNC1730 integer reaper.Xen_StopSourcePreview(integer preview_id)
DESC1730 Stop audio preview. id -1 stops all.ReaScript/Lua Built-In Function list
FUNC1731 Lua: reaper.atexit(function)
DESC1731 Adds code to be executed when the script finishes or is ended by the user. Typically used to clean up after the user terminates defer() or runloop() code.
FUNC1732 Lua: reaper.defer(function)
DESC1732 Adds code to be called back by REAPER. Used to create persistent ReaScripts that continue to run and respond to input, while the user does other tasks. Identical to runloop().Note that no undo point will be automatically created when the script finishes, unless you create it explicitly.
FUNC1733 Lua: reaper.get_action_context()
DESC1733 
FUNC1734 is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context()
DESC1734 Returns contextual information about the script, typically MIDI/OSC input values.val will be set to a relative or absolute value depending on mode (=0: absolute mode, >0: relative modes). resolution=127 for 7-bit resolution, =16383 for 14-bit resolution.Notes: sectionID, and cmdID will be set to -1 if the script is not part of the action list. mode, resolution and val will be set to -1 if the script was not triggered via MIDI/OSC.Lua: gfx VARIABLESThe following global variables are special and will be used by the graphics system:gfx.r - current red component (0..1) used by drawing operations.gfx.g - current green component (0..1) used by drawing operations.gfx.b - current blue component (0..1) used by drawing operations.gfx.a2 - current alpha component (0..1) used by drawing operations when writing solid colors (normally ignored but useful when creating transparent images).gfx.a - alpha for drawing (1=normal).gfx.mode - blend mode for drawing. Set mode to 0 for default options. Add 1.0 for additive blend mode (if you wish to do subtractive, set gfx.a to negative and use gfx.mode as additive). Add 2.0 to disable source alpha for gfx.blit(). Add 4.0 to disable filtering for gfx.blit().gfx.w - width of the UI framebuffer.gfx.h - height of the UI framebuffer.gfx.x - current graphics position X. Some drawing functions use as start position and update.gfx.y - current graphics position Y. Some drawing functions use as start position and update.gfx.clear - if greater than -1.0, framebuffer will be cleared to that color. the color for this one is packed RGB (0..255), i.e. red+green*256+blue*65536. The default is 0 (black).gfx.dest - destination for drawing operations, -1 is main framebuffer, set to 0..1024-1 to have drawing operations go to an offscreen buffer (or loaded image).gfx.texth - the (READ-ONLY) height of a line of text in the current font. Do not modify this variable.gfx.ext_retina - to support hidpi/retina, callers should set to 1.0 on initialization, will be updated to 2.0 if high resolution display is supported, and if so gfx.w/gfx.h/etc will be doubled.gfx.mouse_x - current X coordinate of the mouse relative to the graphics window.gfx.mouse_y - current Y coordinate of the mouse relative to the graphics window.gfx.mouse_wheel - wheel position, will change typically by 120 or a multiple thereof, the caller should clear the state to 0 after reading it.gfx.mouse_hwheel - horizontal wheel positions, will change typically by 120 or a multiple thereof, the caller should clear the state to 0 after reading it.gfx.mouse_cap - a bitfield of mouse and keyboard modifier state:1: left mouse button2: right mouse button4: Control key8: Shift key16: Alt key32: Windows key64: middle mouse buttonLua: gfx.arc(x,y,r,ang1,ang2[,antialias])Draws an arc of the circle centered at x,y, with ang1/ang2 being specified in radians.Lua: gfx.blit(source, scale, rotation[, srcx, srcy, srcw, srch, destx, desty, destw, desth, rotxoffs, rotyoffs])srcx/srcy/srcw/srch specify the source rectangle (if omitted srcw/srch default to image size), destx/desty/destw/desth specify dest rectangle (if not specified, these will default to reasonable defaults -- destw/desth default to srcw/srch * scale).Lua: gfx.blit(source,scale,rotation)If three parameters are specified, copies the entirity of the source bitmap to gfx.x,gfx.y using current opacity and copy mode (set with gfx.a, gfx.mode). You can specify scale (1.0 is unscaled) and rotation (0.0 is not rotated, angles are in radians).For the "source" parameter specify -1 to use the main framebuffer as source, or an image index (see gfx.loadimg()).Lua: gfx.blitext(source,coordinatelist,rotation)Deprecated, use gfx.blit instead.Lua: gfx.blurto(x,y)Blurs the region of the screen between gfx.x,gfx.y and x,y, and updates gfx.x,gfx.y to x,y.Lua: gfx.circle(x,y,r[,fill,antialias])Draws a circle, optionally filling/antialiasing.Lua: gfx.clienttoscreen(x,y)Converts the coordinates x,y to screen coordinates, returns those values.Lua: gfx.deltablit(srcimg,srcs,srct,srcw,srch,destx,desty,destw,desth,dsdx,dtdx,dsdy


,dtdy,dsdxdy,dtdxdy[,usecliprect=1])Blits from srcimg(srcx,srcy,srcw,srch) to destination (destx,desty,destw,desth). Source texture coordinates are s/t, dsdx represents the change in s coordinate for each x pixel, dtdy represents the change in t coordinate for each y pixel, etc. dsdxdy represents the change in dsdx for each line. If usecliprect is specified and 0, then srcw/srch are ignored.Lua: gfx.dock(v[,wx,wy,ww,wh])Call with v=-1 to query docked state, otherwise v>=0 to set docked state. State is &1 if docked, second byte is docker index (or last docker index if undocked). If wx-wh specified, additional values will be returned with the undocked window position/sizeLua: gfx.drawchar(char)Draws the character (can be a numeric ASCII code as well), to gfx.x, gfx.y, and moves gfx.x over by the size of the character.Lua: gfx.drawnumber(n,ndigits)Draws the number n with ndigits of precision to gfx.x, gfx.y, and updates gfx.x to the right side of the drawing. The text height is gfx.texth.Lua: gfx.drawstr("str"[,flags,right,bottom])Draws a string at gfx.x, gfx.y, and updates gfx.x/gfx.y so that subsequent draws will occur in a similar place.If flags, right ,bottom passed in:flags&1: center horizontallyflags&2: right justifyflags&4: center verticallyflags&8: bottom justifyflags&256: ignore right/bottom, otherwise text is clipped to (gfx.x, gfx.y, right, bottom)Lua: gfx.getchar([char])If char is 0 or omitted, returns a character from the keyboard queue, or 0 if no character is available, or -1 if the graphics window is not open. If char is specified and nonzero, that character's status will be checked, and the function will return greater than 0 if it is pressed.Common values are standard ASCII, such as 'a', 'A', '=' and '1', but for many keys multi-byte values are used, including 'home', 'up', 'down', 'left', 'rght', 'f1'.. 'f12', 'pgup', 'pgdn', 'ins', and 'del'.Modified and special keys can also be returned, including:Ctrl/Cmd+A..Ctrl+Z as 1..26Ctrl/Cmd+Alt+A..Z as 257..282Alt+A..Z as 'A'+256..'Z'+25627 for ESC13 for Enter' ' for space65536 for query of special flags, returns: &1 (supported), &2=window has focus, &4=window is visibleLua: gfx.getdropfile(idx)Returns success,string for dropped file index idx. call gfx.dropfile(-1) to clear the list when finished.Lua: gfx.getfont()Returns current font index, and the actual font face used by this font (if available).Lua: gfx.getimgdim(handle)Retreives the dimensions of an image specified by handle, returns w, h pair.Lua: gfx.getpixel()Returns r,g,b values [0..1] of the pixel at (gfx.x,gfx.y)Lua: gfx.gradrect(x,y,w,h, r,g,b,a[, drdx, dgdx, dbdx, dadx, drdy, dgdy, dbdy, dady])Fills a gradient rectangle with the color and alpha specified. drdx-dadx reflect the adjustment (per-pixel) applied for each pixel moved to the right, drdy-dady are the adjustment applied for each pixel moved toward the bottom. Normally drdx=adjustamount/w, drdy=adjustamount/h, etc.Lua: gfx.init("name"[,width,height,dockstate,xpos,ypos])Initializes the graphics window with title name. Suggested width and height can be specified.Once the graphics window is open, gfx.update() should be called periodically.Lua: gfx.line(x,y,x2,y2[,aa])Draws a line from x,y to x2,y2, and if aa is not specified or 0.5 or greater, it will be antialiased.Lua: gfx.lineto(x,y[,aa])Draws a line from gfx.x,gfx.y to x,y. If aa is 0.5 or greater, then antialiasing is used. Updates gfx.x and gfx.y to x,y.Lua: gfx.loadimg(image,"filename")Load image from filename into slot 0..1024-1 specified by image. Returns the image index if success, otherwise -1 if failure. The image will be resized to the dimensions of the image file.Lua: gfx.measurechar(char)Measures the drawing dimensions of a character with the current font (as set by gfx.setfont). Returns width and height of character.Lua: gfx.measurestr("str")Measures the drawing dimensions of a string with the current font (as set by gfx.setfont). Returns width and height of string.Lua: gfx.muladdrect(x,y,w,h,mul_r,mul_g,mul_b[,mul_a,add_r,add_g,add_b,add_a])Multiplies each pixel by mul_* and 


adds add_*, and updates in-place. Useful for changing brightness/contrast, or other effects.Lua: gfx.printf("format"[, ...])Formats and draws a string at gfx.x, gfx.y, and updates gfx.x/gfx.y accordingly (the latter only if the formatted string contains newline). For more information on format strings, see sprintf()Lua: gfx.quit()Closes the graphics window.Lua: gfx.rect(x,y,w,h[,filled])Fills a rectangle at x,y, w,h pixels in dimension, filled by default.Lua: gfx.rectto(x,y)Fills a rectangle from gfx.x,gfx.y to x,y. Updates gfx.x,gfx.y to x,y.Lua: gfx.roundrect(x,y,w,h,radius[,antialias])Draws a rectangle with rounded corners.Lua: gfx.screentoclient(x,y)Converts the screen coordinates x,y to client coordinates, returns those values.Lua: gfx.set(r[,g,b,a,mode,dest,a2])Sets gfx.r/gfx.g/gfx.b/gfx.a/gfx.mode/gfx.a2, sets gfx.dest if final parameter specifiedLua: gfx.setcursor(resource_id,custom_cursor_name)Sets the mouse cursor. resource_id is a value like 32512 (for an arrow cursor), custom_cursor_name is a string like "arrow" (for the REAPER custom arrow cursor). resource_id must be nonzero, but custom_cursor_name is optional.Lua: gfx.setfont(idx[,"fontface", sz, flags])Can select a font and optionally configure it. idx=0 for default bitmapped font, no configuration is possible for this font. idx=1..16 for a configurable font, specify fontface such as "Arial", sz of 8-100, and optionally specify flags, which is a multibyte character, which can include 'i' for italics, 'u' for underline, or 'b' for bold. These flags may or may not be supported depending on the font and OS. After calling gfx.setfont(), gfx.texth may be updated to reflect the new average line height.Lua: gfx.setimgdim(image,w,h)Resize image referenced by index 0..1024-1, width and height must be 0-8192. The contents of the image will be undefined after the resize.Lua: gfx.setpixel(r,g,b)Writes a pixel of r,g,b to gfx.x,gfx.y.Lua: gfx.showmenu("str")Shows a popup menu at gfx.x,gfx.y. str is a list of fields separated by | characters. Each field represents a menu item.Fields can start with special characters:# : grayed out! : checked> : this menu item shows a submenu< : last item in the current submenuAn empty field will appear as a separator in the menu. gfx.showmenu returns 0 if the user selected nothing from the menu, 1 if the first field is selected, etc.Example:gfx.showmenu("first item, followed by separator||!second item, checked|>third item which spawns a submenu|#first item in submenu, grayed out|<second and last item in submenu|fourth item in top menu")Lua: gfx.transformblit(srcimg,destx,desty,destw,desth,div_w,div_h,table)
FUNC1735 Blits to destination at (destx,desty), size (destw,desth). div_w and div_h should be 2..64, and table should point to a table of 2*div_w*div_h values (table can be a regular table or (for less overhead) a reaper.array). Each pair in the table represents a S,T coordinate in the source image, and the table is treated as a left-right, top-bottom list of texture coordinates, which will then be rendered to the destination.
DESC1735 Lua: gfx.triangle(x1,y1,x2,y2,x3,y3[x4,y4...])Draws a filled triangle, or any convex polygon.Lua: gfx.update()Updates the graphics display, if opened
FUNC1736 Lua: reaper.gmem_attach(sharedMemoryName)
DESC1736 Causes gmem_read()/gmem_write() to read EEL2/JSFX/Video shared memory segment named by parameter. Set to empty string to detach. 6.20+: returns previous shared memory segment name.
FUNC1737 Lua: reaper.gmem_read(index)
DESC1737 Read (number) value from shared memory attached-to by gmem_attach(). index can be [0..1<<25).
FUNC1738 Lua: reaper.gmem_write(index,value)
DESC1738 Write (number) value to shared memory attached-to by gmem_attach(). index can be [0..1<<25).
FUNC1739 Lua: reaper.new_array([table|array][size])
DESC1739 
FUNC1740 Creates a new reaper.array object of maximum and initial size size, if specified, or from the size/values of a table/array. Both size and table/array can be specified, the size parameter will override the table/array size.
DESC1740 
FUNC1741 Lua: reaper.runloop(function)
DESC1741 Adds code to be called back by REAPER. Used to create persistent ReaScripts that continue to run and respond to input, while the user does other tasks. Identical to defer().Note that no undo point will be automatically created when the script finishes, unless you create it explicitly.
FUNC1742 Lua: {reaper.array}.clear([value, offset, size])
DESC1742 Sets the value of zero or more items in the array. If value not specified, 0.0 is used. offset is 1-based, if size omitted then the maximum amount available will be set.
FUNC1743 Lua: {reaper.array}.convolve([src, srcoffs, size, destoffs])
DESC1743 
FUNC1744 Convolves complex value pairs from reaper.array, starting at 1-based srcoffs, reading/writing to 1-based destoffs. size is in normal items (so it must be even)
DESC1744 
FUNC1745 Lua: {reaper.array}.copy([src, srcoffs, size, destoffs])
DESC1745 
FUNC1746 Copies values from reaper.array or table, starting at 1-based srcoffs, writing to 1-based destoffs.
DESC1746 
FUNC1747 Lua: {reaper.array}.fft(size[, permute, offset])
DESC1747 Performs a forward FFT of size. size must be a power of two between 4 and 32768 inclusive. If permute is specified and true, the values will be shuffled following the FFT to be in normal order.
FUNC1748 Lua: {reaper.array}.fft_real(size[, permute, offset])
DESC1748 Performs a forward real->complex FFT of size. size must be a power of two between 4 and 32768 inclusive. If permute is specified and true, the values will be shuffled following the FFT to be in normal order.
FUNC1749 Lua: {reaper.array}.get_alloc()
DESC1749 Returns the maximum (allocated) size of the array.
FUNC1750 Lua: {reaper.array}.ifft(size[, permute, offset])
DESC1750 Performs a backwards FFT of size. size must be a power of two between 4 and 32768 inclusive. If permute is specified and true, the values will be shuffled before the IFFT to be in fft-order.
FUNC1751 Lua: {reaper.array}.ifft_real(size[, permute, offset])
DESC1751 Performs a backwards complex->real FFT of size. size must be a power of two between 4 and 32768 inclusive. If permute is specified and true, the values will be shuffled before the IFFT to be in fft-order.
FUNC1752 Lua: {reaper.array}.multiply([src, srcoffs, size, destoffs])
DESC1752 
FUNC1753 Multiplies values from reaper.array, starting at 1-based srcoffs, reading/writing to 1-based destoffs.
DESC1753 
FUNC1754 Lua: {reaper.array}.resize(size)
DESC1754 Resizes an array object to size. size must be [0..max_size].
FUNC1755 Lua: {reaper.array}.table([offset, size])
DESC1755 Returns a new table with values from items in the array. Offset is 1-based and if size is omitted all available values are used.
]]
  
  for key in pairs(reaper) do _G[key]=reaper[key]  end  VF_run_initVars()  if VF_run_initVars_overwrite then VF_run_initVars_overwrite() end DATA.conf.vrs = version  VF_run_init()  

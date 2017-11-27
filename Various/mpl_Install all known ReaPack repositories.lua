-- @version 1.0
-- @author mpl
-- @description Install all known ReaPack repositories
-- @website http://forum.cockos.com/member.php?u=70694
-- @changelog
--   + init

  -- ReaPack 1.2beta2+ supported
  
  repos = 
    {
      {name='EUGEN27771-ReaScripts',    url='https://raw.githubusercontent.com/EUGEN27771/ReaScripts/master/index.xml'},
      {name='SonicAnomaly JSFX',        url='https://raw.githubusercontent.com/Sonic-Anomaly/Sonic-Anomaly-JSFX/master/index.xml'},
      {name='chtammik_Reaper_Scripts',  url='https://raw.githubusercontent.com/chtammik/chtammik_Reaper_Scripts/master/index.xm'},
      {name='Claudiohbsantos Scripts',  url='https://github.com/Claudiohbsantos/Claudiohbsantos-Scripts/raw/master/index.xml'},
      {name='Fernsehmüll Scripts',      url='https://github.com/fernsehmuell/reaper_scripts/raw/master/index.xml'},
      {name="Geraint's JSFX",           url='https://geraintluff.github.io/jsfx/index.xml'},
      {name='kawa Scripts',             url='https://bitbucket.org/kawaCat/reascript-m2bpack/raw/master/index.xml'},
      {name='luckyxxl Scripts',         url='https://github.com/luckyxxl/reaper-scripts/raw/master/index.xml'},
      {name='me2beats Scripts',         url='https://github.com/me2beats/reapack/raw/master/index.xml'},
      {name='mrlimbic scripts',         url='https://github.com/mrlimbic/reascripts/raw/master/index.xml'},
      {name='nofish ReaScripts',        url='https://github.com/nofishonfriday/ReaScripts/raw/master/index.xml'},
      {name="Przemoc's ReaScripts",     url='https://github.com/przemoc/REAPER-ReaScripts/raw/master/index.xml'},
      {name='RCJacH Scripts',           url='https://github.com/RCJacH/ReaScripts/raw/master/index.xml'},
      {name='RobU Scripts',             url='https://github.com/RobU23/ReaScripts/raw/master/index.xml'},
      {name='Tack Scripts',             url='https://github.com/jtackaberry/reascripts/raw/master/index.xml'},
      {name='X-Raym MIDI Makey Makey',  url='https://github.com/X-Raym/MIDI-Makey-Makey/raw/master/index.xml'},
    }
---------------------------------------------------------------------------------------------------------------------- 
  function form_obj() 
    obj = {}
    gfx.setfont(1,"Arial", 15, '' )
    for i = 0, #repos do
      obj[i] = {x=0,y=i*gfx.h/#repos,w=gfx.w,h=gfx.h/#repos}      
    end
  end
  ---------------------------------------------------------------------------------------------------------------------- 
  function run()
    lb =  gfx.mouse_cap==1
    for i = 0, #obj do
      if not last_lb and lb and gfx.mouse_y >= obj[i].y and gfx.mouse_y <= obj[i].y+obj[i].h then 
        if i > 0 then
          obj[i].state = true
         else
          Install()
        end
      end
      if obj[i].state then gfx.a = 1 else gfx.a = 0.4 end
      gfx.x, gfx.y = obj[i].x,obj[i].y
      local txt if i ==0 then txt = 'Install selected repositories' gfx.x = gfx.w - gfx.measurestr(txt) else txt = repos[i].name end
      gfx.drawstr(txt)
      gfx.a = 0.3
      gfx.line(0,obj[i].y+obj[i].h,gfx.w,obj[i].y+obj[i].h)
    end
    last_lb = lb
    gfx.update()
    if gfx.getchar() >=0 then reaper.defer(run) else reaper.atexit(quit) end
  end
  function quit() gfx.quit() end
  ----------------------------------------------------------------------------------------------------------------------    
    function Install()
      for i =1, #repos do
        if obj[i].state then
          reaper.ReaPack_AddSetRepository(
            repos[i].name,--string name, 
            repos[i].url,--string url, 
            true,--boolean enable, 
            2,--integer autoInstall, 
            true)--boolean commit)
        end
      end
      reaper.MB( 'Repositories were succesfully added to syncronization list. \nTo install all scripts physically run action "ReaPack: Synchronize packages"','Install all known repositories.',0)
      reaper.atexit(quit)
    end
  ---------------------------------------------------------------------------------------------------------------------- 
  if reaper.APIExists('ReaPack_AddSetRepository') then
    gfx.init('',400,300,0, 50,50)
    form_obj()
    run()
   else
    reaper.MB('Script require ReaPack 1.2beta2+','',0)
  end
  

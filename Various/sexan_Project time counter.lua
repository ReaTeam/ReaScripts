--[[
 * ReaScript Name: Project Time Counter with AFK mode
 * Author: SeXan
 * Licence: GPL v3
 * Forum Thread: LUA : Project Work Timer
 * Forum Thread URI: http://forum.cockos.com/showthread.php?t=167883
 * REAPER: 5.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2016-01-29)
  + Initial Release
--]]

---------------------------------------
local afk = 60 -- set afk treshold HERE
---------------------------------------

local last_proj_change_count = reaper.GetProjectStateChangeCount(0)
local last_action_time=0 -- initial action time
local t1 = 0 -- initial interval time

t_sec= 0
t_min = 0
t_hour = 0
t_day = 0

function store_time() -- store time values to project
reaper.SetProjExtState(0, "time", "s", t_sec) -- store seconds
reaper.SetProjExtState(0, "time", "m", t_min) -- store minutes
reaper.SetProjExtState(0, "time", "h", t_hour) -- store hours
reaper.SetProjExtState(0, "time", "d", t_day) -- store days
end

function restore_time() -- restore time values from project
ok,t_sec = reaper.GetProjExtState(0, "time", "s") -- restore seconds  
ok,t_min = reaper.GetProjExtState(0, "time", "m") -- restore minutes
ok,t_hour = reaper.GetProjExtState(0, "time", "h") -- restore hours
ok,t_day = reaper.GetProjExtState(0, "time", "d") -- restore days

  if ok == 0 then -- if no value is stored reset all time values to 0
    t_sec= 0
    t_min = 0
    t_hour = 0
    t_day = 0
  end
  
end

function count_time(timer)

    if timer - t1 == 1 then -- this is interval timer of 1 second needed for counting
       t_sec=t_sec + 1    
       if t_sec == 60 then
          t_min = t_min + 1 
          t_sec = 0                      
          if t_min == 60 then
             t_hour = t_hour + 1
             t_min = 0
             if t_hour == 24 then
                t_day = t_day + 1
                t_hour = 0
             end
          end
       end
    t1 = timer        
    end
    
store_time() -- call function to store time values
end  

function main()
restore_time() -- call function restore_time() to restore time values from project
local currentTime = os.time()
local timer = currentTime - last_action_time -- start counter from 0 when action is made

local play_state = reaper.GetPlayState() -- get transport state
local recording = play_state == 5 -- is record button on
local playing = play_state == 1 -- is play button on
 
  local proj_change_count = reaper.GetProjectStateChangeCount(0)
  if proj_change_count > last_proj_change_count or recording or playing then -- if project state changed or transport is in play or record mode
     last_action_time = currentTime -- get the last action time
     t1 = 0 -- store value for interval timer of 1 sec
     last_proj_change_count = proj_change_count -- store "Project State Change Count" for the next pass 
  end
  
  if timer <= afk then
     count_time(timer)
     else
     timer = 0
  end
           
  --count_time()
-- DRAW GUI --  
     gfx.x = 2
     gfx.y = 15      
     gfx.printf("")
      
     gfx.printf("%02d",math.floor(t_day)) -- math.floor removes decilam numbers
     gfx.printf(":")
     gfx.printf("%02d",math.floor(t_hour))
     gfx.printf(":")
     gfx.printf("%02d",math.floor(t_min)) 
     gfx.printf(":")
     gfx.printf("%02d",math.floor(t_sec))      
         
   --  gfx.x = 5
   --  gfx.y = 5
   --  gfx.printf(" d : h : m : s")  
     gfx.update()
--DRAW GUI -- 

  if gfx.getchar() > -1 then  -- defer while gfx window is open
     reaper.defer(main)
  end
end

local gui = {}
function init()
  -- Add stuff to "gui" table
  gui.settings = {}                 -- Add "settings" table to "gui" table 
  gui.settings.font_size = 24       -- font size
  gui.settings.docker_id = 513        -- try 0, 1, 257, 513, 1027 etc.
  
  ---------------------------
  -- Initialize gfx window --
  ---------------------------
  gfx.init("", 0, 30, gui.settings.docker_id)
  gfx.setfont(1,"Arial", gui.settings.font_size)
  gfx.clear = 3355443
  
  main()   
end
--restore_time() -- call function restore_time() to restore time values from project
init()

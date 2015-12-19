--[[
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Forum Thread URI: http://forum.cockos.com/showthread.php?t=168777
   * Licence: GPL v3
   * Version: 0.2015.12.18
   * NoIndex: true
  ]]
  
-----------------
-- Mouse table --
-----------------
local mouse = {  
        -- Constants
        LB = 1,
        RB = 2,
        CTRL = 4,
        SHIFT = 8,
        ALT = 16,
        
        -- "cap" function
        cap = function (mask)
                if mask == nil then
                  return gfx.mouse_cap end
                return gfx.mouse_cap&mask == mask
              end,
                
        --lb_down = false,
        --lb_up = true,
        uptime = 0,
        moving = false,
        last_state = 0,
        
        last_x = -1, last_y = -1,
       
        dx = 0,
        dy = 0,
        
        ox_l = 0, oy_l = 0,    -- left click positions
        ox_r = 0, oy_r = 0,    -- right click positions
        --capcnt = 0,
        LMB_state = false,
        last_LMB_state = false,
        RMB_state = false,
        last_RMB_state = false
        
     }
     
return mouse

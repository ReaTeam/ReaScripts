--[[
   * ReaScript Name: Compress or expand selected envelope points
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Licence: GPL v3
   * Version: 1.0
  ]]
  
------------- "class.lua" is copied from http://lua-users.org/wiki/SimpleLuaClasses -----------

-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
   local c = {}    -- a new class instance
   if not init and type(base) == 'function' then
      init = base
      base = nil
   elseif type(base) == 'table' then
    -- our new class is a shallow copy of the base class!
      for i,v in pairs(base) do
         c[i] = v
      end
      c._base = base
   end
   -- the class will be the metatable for all its objects,
   -- and they will look up their methods in it.
   c.__index = c

   -- expose a constructor which can be called by <classname>(<args>)
   local mt = {}
   mt.__call = function(class_tbl, ...)
   local obj = {}
   setmetatable(obj,c)
   if init then
      init(obj,...)
   else 
      -- make sure that any stuff from the base class is initialized!
      if base and base.init then
      base.init(obj, ...)
      end
   end
   return obj
   end
   c.init = init
   c.is_a = function(self, klass)
      local m = getmetatable(self)
      while m do 
         if m == klass then return true end
         m = m._base
      end
      return false
   end
   setmetatable(c, mt)
   return c
end
----------------------------------------------------------------------------------------

--///////////////////////
--// Scaling functions //
--///////////////////////

function scale_x_to_slider_val(min_val, max_val, x_coord, x1, x2)
  local scaled_x = min_val + (max_val - min_val) * (x_coord - x1) / (x2 - x1)
  if scaled_x > max_val then scaled_x = max_val end
  if scaled_x < min_val then scaled_x = min_val end
  return scaled_x
end

function scale_slider_val_to_x(min_val, max_val, slider_val, x1, x2)
  return (x1 + (slider_val - min_val) * (x2 - x1) / (max_val - min_val))
end


--//////////////////
--// Slider class //
--//////////////////

local Slider = class(
                      function(sl, x1, y1, w, h, val, default_val, min_val, max_val, lbl, help_text)
                        sl.x1 = x1
                        sl.y1 = y1
                        sl.w = w
                        sl.h = h
                        sl.x2 = sl.x1+w
                        sl.y2 = sl.y1+h
                        
                        sl.val = val
                        sl.default_val = default_val
                        sl.min_val = min_val
                        sl.max_val = max_val
                        sl.lbl = lbl
                        sl.help_text = help_text
                        sl.mouse_state = 0
                        sl.lbl_w, sl.lbl_h = gfx.measurestr(lbl)
                        
                        sl.x_coord = scale_slider_val_to_x(sl.min_val, sl.max_val, sl.val, sl.x1, sl.x2)
                        sl.last_x_coord = sl.x_coord
                        
                      end
                    )
                    
function Slider:set_help_text()
  --if self.help_text == "" then return false end
  gfx.set(1,1,1,1)
  gfx.x = gui.help_text_x
  gfx.y = gui.help_text_y
  gfx.printf(self.help_text)
end

function Slider:draw()
  --self.x2 = self.x1+self.w
  --self.y2 = self.y1+self.h
  
  self.x_coord = scale_slider_val_to_x(self.min_val, self.max_val, self.val, self.x1, self.x2)
  
  self.a = 0.6
  gfx.set(0.2,0.7,0.7,self.a)
  
  if last_mouse_state == 0 and self.mouse_state == 1 then self.mouse_state = 0 end
  
  if self.mouse_state == 1 or gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2 then
    if self.help_text ~= "" then self:set_help_text() end -- Draw info/help text (if self.help_text is not "")
    if last_mouse_state == 0 and gfx.mouse_cap & 1 == 1 and self.mouse_state == 0 then
      self.mouse_state = 1
    end
    if self.mouse_state == 1 then --and mouse.moving then
      self.x_coord = math.min(math.max(0, self.last_x_coord+mouse.dx),self.x2)
      --self.x_coord = math.min(math.max(0, self.last_x_coord+mouse.dx),self.x2)
      --self.val = scale_x_to_slider_val(self.min_val, self.max_val, self.x_coord, self.x1, self.x2)
    end
  end
  self.val = scale_x_to_slider_val(self.min_val, self.max_val, self.x_coord, self.x1, self.x2)
  
  gfx.set(0.2,0.7,0.7,self.a)
  
  --gfx.a = 0.5+0.5*self.x_coord/self.w
  --gfx_a = self.a;
  gfx_a = 1;
  
  gfx.rect(self.x1, self.y1, self.x_coord-self.x1, self.h)
  
  -- Draw slider label (if "slider_label" is not an empty string)
  if self.lbl ~= "" then 
     gfx.x = self.x1+4
     gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth
     gfx.set(1,1,1,1);
     gfx.printf(self.lbl)
  end
  
  gfx.set(0.9,0.9,0.9,0.9)

  --//gfx_a = 0.2;
  gfx.a = self.a-0.5
  gfx.rect(self.x1, self.y1, self.w, self.h)

  --// Show slider value
  
  self.val_w = gfx.measurestr(string.format("%.2f",self.val))
  gfx.a = 1
  gfx.x = 250
  gfx.printf(string.format("%.2f",self.val))
  
  if self.mouse_state == 0 then self.last_x_coord = self.x_coord end
  
  return self.val
  
end

function get_set_envelope_points()
  env = reaper.GetSelectedTrackEnvelope(0)
  if env == nil then
    gfx.x = gui.error_msg_x ; gfx.y = gui.error_msg_y
    gfx.set(1,0,0,1)
    gfx.printf("Please select a 'Track volume envelope'")
  else
    local retval, env_name = reaper.GetEnvelopeName(env, "")
    if env_name ~= "Volume" and env_name ~= "Volume (Pre-FX)" then
      gfx.x = gui.error_msg_x
      gfx.y = gui.error_msg_y
      gfx.set(1,0,0,1)
      gfx.printf("Please select a 'Track volume envelope'") return end
    --local env_scaling = reaper.GetVolumeEnvelopeScaling(env) --todo
    local env_point_count = reaper.CountEnvelopePoints(env)
    
  
    -- collect points
    if gfx.mouse_cap == 1 and array_created == false then
      e_i = {} --reaper.new_array(env_point_count)
      e_v = {}
      sel_points = 0
      local sum = 0
      local c = 1
      for i=1,env_point_count do
        retval, timeOut, value, shape, tensionOut, selected = reaper.GetEnvelopePoint(env, i)
        if selected then
          e_i[c] = i
          e_v[c] = value
          c = c+1
          sel_points = sel_points + 1
          sum = sum + value
        end
      end
      ka = sum/sel_points
      array_created = true
    end
    
    -- apply changes to selected envelope
    if array_created == true then
      --if compress.val ~= last_compress_val then
        gfx.x = gui.error_msg_x
        gfx.y = gui.error_msg_y
        gfx.set(0,1,0,1)
        if compress.val < last_compress_val then
          gfx.printf("Expanding... "..env_name) else gfx.printf("Compressing... "..env_name)
        end
       
        for i=1, sel_points do
          local retval, timeOut, value, shape, tensionOut, selected = reaper.GetEnvelopePoint(env, e_i[i])
          local v = e_v[i]
          value = v + (ka-v) * compress.val
          value = math.min(math.max(0, value), 2)-- end
          reaper.SetEnvelopePoint(env, e_i[i], timeOut, value) 
        end
        --last_compress_val = compress.val
      --end
    end
    
    --reaper.Envelope_SortPoints(env)
    
    if undo_block == 0 then undo_block = 1 end -- a flag for "reaper.Undo_OnStateChange"
    reaper.UpdateArrange()
  end
end
  


--//////////////
--// Mainloop //
--//////////////

function mainloop()
  mouse.lb_down = gfx.mouse_cap & 1 == 1
  
  if last_mouse_state == 0 and mouse.lb_down then
    mouse.click_x = gfx.mouse_x
  end
  
  if mouse.lb_down then
    mouse.dx = gfx.mouse_x-mouse.click_x
    mouse.moving = mouse.dx ~= mouse.last_dx -- true if lmb is down and mouse is moving
    mouse.last_dx = mouse.dx
  end
  
  compress:draw()
  
  if compress.val ~= last_compress_val and mouse.lb_down then
    get_set_envelope_points()
  end
  
  -- Check left mouse btn state
  if not mouse.lb_down then last_mouse_state = 0 else last_mouse_state = 1 end
  
  mouse.dx = 0
  
  if gfx.mouse_cap == 0 then
    if array_created == true then array_created = false end
    if compress.mouse_state == 1 then compress.val = compress.default_val end
  end
  
  -- add undo point if necessary
  if undo_block == 1 and compress.mouse_state == 0 then
    undo_block = 0
    reaper.Undo_OnStateChangeEx("Compress or expand envelope points", -1, -1)
  end
  last_compress_val = compress.val
 
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(mainloop) end
end


--//////////
--// Init //
--//////////

function init()
  gfx.init("Compress or expand selected volume envelope points", 300, 120)
  gfx.setfont(1,"Arial", 15)

  gui = {}
  gui.error_msg_x = 10
  gui.error_msg_y = 10
  
  gui.help_text_x = 10
  gui.help_text_y = gui.error_msg_y + gfx.texth
   
  undo_block = 0
  
  mouse = {}
  mouse.click_x = -1
  mouse.dx = 0
  mouse.last_dx = 0
  mouse.lb_down = false
  mouse.moving = false
  
  array_created = false
                  --(x1, y1, w, h, val, default_val, min_val, max_val, lbl, help_text)
  compress = Slider(10, gui.help_text_y + gfx.texth+10, 200, 15, 0.0, 0.0, -1, 1, "Compress","Drag right to compress, left to expand")
  last_compress_val = 0.0
end

init()
mainloop()

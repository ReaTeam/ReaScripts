--[[
   * Lua script for Cockos REAPER
   * Author: spk77
   * Author URI: http://forum.cockos.com/member.php?u=49553
   * Forum Thread URI: http://forum.cockos.com/showthread.php?t=168777
   * Licence: GPL v3
   * Version: 0.2015.12.18
   * NoIndex: true
  ]]
  
--[[
--Debug
upd_count = 0 --dbg
--]]

------------------------------------------------------------------------------
-- "msg" function
------------------------------------------------------------------------------
function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

local function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end

-- get "script path"
local script_path = get_script_path()
--msg(script_path)

-- modify "package.path"
package.path = package.path .. ";" .. script_path .. "?.lua"
--msg(package.path)

-- Import files ("classes", functions etc.)-----------------
require "spk77_class_function" -- import "base class"
local mouse = require "spk77_mouse_function" -- import "mouse table"



-------------------------------------------------------------------------

local Slider_class = {}
Slider_class.sliders = {}       -- Slider instances are collected to this table
Slider_class.last_touched = {}  -- "Last clicked slider" will populate this table 

-- A function for clearing the slider table
Slider_class.clear_slider_table = 
                        function()
                          for k,v in pairs(Slider_class.sliders) do 
                            Slider_class.sliders[k]=nil
                          end
                          --[[
                          while #Slider_class.sliders ~= 0 do
                            rawset(Slider_class.sliders, #Slider_class.sliders, nil)
                          end
                          --]]
                        end
                        
                   

Slider_class.get_last_touched =
                        function()
                          return Slider_class.last_touched
                        end                   


-------------------------------------------------------------------------


-----------------------
-- Scaling functions --
-----------------------

local function scale_pos_to_slider_val(min_val, max_val, pos, min_pos, max_pos)
  local scaled_pos = min_val + (max_val - min_val) * (pos - min_pos) / (max_pos - min_pos)
  if scaled_pos > max_val then scaled_pos = max_val end
  if scaled_pos < min_val then scaled_pos = min_val end
  return scaled_pos
end


local function scale_slider_val_to_x(min_val, max_val, slider_val, x1, x2)
  return (x1 + (slider_val - min_val) * (x2 - x1) / (max_val - min_val))
end


local function scale_y_to_slider_val(min_val, max_val, y_coord, y1, y2)
  local scaled_y = min_val + (max_val - min_val) * (y_coord - y1) / (y2 - y1)
  if scaled_y > max_val then scaled_y = max_val end
  if scaled_y < min_val then scaled_y = min_val end
  return scaled_y
end


local function scale_slider_val_to_y(min_val, max_val, slider_val, y1, y2)
  return y1 + (slider_val - min_val) * (y2 - y1) / (max_val - min_val)
end



local function mouse_in_rect(x,y,w,h)
  return gfx.mouse_x > x and gfx.mouse_x < x + w and gfx.mouse_y > y and gfx.mouse_y < y + h
end
-------------------------------------------------------------------------


------------------
-- Slider class --
------------------

------------------------------------
-- Default values for all sliders --
------------------------------------
Slider_class.defaults = {}
local sc_def = Slider_class.defaults

sc_def.horiz_spacing = 10
-- First slider's pos/dimensions
sc_def.x1 = 10
sc_def.y1 = 10
sc_def.w = 100
sc_def.h = 15

-- slider "mouse hit area" pos/dimensions    
sc_def.hz_x1 = sc_def.x1
sc_def.hz_y1 = sc_def.y1
sc_def.hz_w = sc_def.h
sc_def.hz_h = sc_def.w

-- slider values
sc_def.val = 1
sc_def.min_val = 0
sc_def.max_val = 1

-- slider foreground colors (foreground is the "moving part" of a slider)
sc_def.fg_r = 0.9
sc_def.fg_g = 0.9
sc_def.fg_b = 0.9
sc_def.fg_a = 0.5

-- slider background colors 
sc_def.bg_r = 0.2
sc_def.bg_g = 0.2
sc_def.bg_b = 1
sc_def.bg_a = 0.3

-- slider mouse hit zone colors (the mouse hit zone is usually invisible)
sc_def.hz_r = 0.8
sc_def.hz_g = 0.2
sc_def.hz_b = 0.2
sc_def.hz_a = 0.4

-- slider value colors
sc_def.val_r = 1
sc_def.val_g = 1
sc_def.val_b = 1
sc_def.val_a = 0.8

-- slider name colors
sc_def.lbl_r = 1
sc_def.lbl_g = 1
sc_def.lbl_b = 1
sc_def.lbl_a = 0.8


-------------------------------
-- "Create slider" -function --
-------------------------------
local Slider = class(
              function(sl, x1, y1, w, h, val, default_val, min_val, max_val, lbl, help_text, id)
                
                -- Slider position, w and h --
                
                -- if no sliders created yet...
                if #Slider_class.sliders == 0 then 
                  sl.x1 = x1 or sc_def.x1
                --if at least one slider is created...
                else
                  if sl.x1 == nil then
                    if #Slider_class.sliders > 0 then --
                      if Slider_class.sliders[#Slider_class.sliders].x1 ~= nil then
                        sl.x1 = Slider_class.sliders[#Slider_class.sliders].x1
                      end
                    else
                      sl.x1 = x1 or sc_def.x1
                    end
                  else
                    sl.x1 = x1 or sc_def.x1
                  end
                end
               -- msg(sl.x1)
                if sl.y1 == nil then
                  if #Slider_class.sliders > 0 then
                    if Slider_class.sliders[#Slider_class.sliders].y2 ~= nil then
                      sl.y1 = Slider_class.sliders[#Slider_class.sliders].y2 + sc_def.horiz_spacing
                    end
                  else
                    sl.y1 = y1 or sc_def.y1
                  end
                else
                  sl.y1 = y1 or sc_def.y1
                end
                
                sl.w = w or sc_def.w
                sl.h = h or sc_def.h
                sl.x2 = sl.x1 + sl.w
                sl.y2 = sl.y1 + sl.h
                
                
                if sl.h > sl.w then
                  sl.horizontal = true
                else
                  sl.horizontal = false
                end
                
                sl.horizontal_stretch = true
               -- sl.vertical_stretch = true
                --msg(sl.vertical_stretch)
                -- Mouse hit zone (Default = slider background area)
                sl:set_hit_zone() -- see "Slider:set_hit_zone"
                
                -- Slider values
                sl.max_val = max_val or sc_def.max_val
                sl.default_val = default_val or (0.5*sc_def.max_val)
                sl.val = val or sl.default_val
                sl.min_val = min_val or math.min(sc_def.min_val, sl.val)
                
                sl.last_val = sl.val
                
                
                
                
                
        
                -- Scale slider value to x pos
                sl.pos = scale_slider_val_to_x(sl.min_val, sl.max_val, sl.val, sl.x1, sl.x2)
                sl.last_pos = sl.pos
                
                sl.y_coord = scale_slider_val_to_y(sl.min_val, sl.max_val, sl.val, sl.y1, sl.y2)
                sl.last_y_coord = sl.y_coord
                
                -- Label
                sl.lbl = lbl or "Slider " .. tostring(#Slider_class.sliders + 1)
                
                sl.help_text = help_text or "" -- Help text is shown when mouse is hovering a slider
                
                --sl._mouse_state = false  -- true if mouse is clicked on "mouse hit zone"
                --                       -- false when LMB or RMB is released
                
                
                sl.lbl_w, sl.lbl_h = gfx.measurestr(lbl) -- Label width and height
                
                -- Colors (default values)
                sl.fg_r = sc_def.fg_r
                sl.fg_g = sc_def.fg_g
                sl.fg_b = sc_def.fg_b
                sl.fg_a = sc_def.fg_a 
                
                sl.bg_r = sc_def.bg_r 
                sl.bg_g = sc_def.bg_g
                sl.bg_b = sc_def.bg_b
                sl.bg_a = sc_def.bg_a
                
                sl.hz_r = sc_def.hz_r
                sl.hz_g = sc_def.hz_g
                sl.hz_b = sc_def.hz_b 
                sl.hz_a = sc_def.hz_a
                
                sl.val_r = sc_def.val_r
                sl.val_g = sc_def.val_g
                sl.val_b = sc_def.val_b
                sl.val_a = sc_def.val_a 
                
                sl.lbl_r = sc_def.lbl_r 
                sl.lbl_g = sc_def.lbl_g
                sl.lbl_b = sc_def.lbl_b
                sl.lbl_a = sc_def.lbl_a
                              
                
                -- Show/hide slider elements
                sl.show = true           -- Show/hide slider
                sl.show_label = true
                sl.show_value = true     -- Show/hide value
                sl.show_bg = true        -- Show/hide slider background
                sl.show_fg = true       -- Show/hide slider foreground
                sl.show_hit_zone = false -- Show/hide hit_zone
                sl.use_images = false
                
                
                
                
                sl.drag_sensitivity = 1               --  "fine adjustment factor"
                --sl.last_drag_sensitivity = 1
                Slider_class.sliders[#Slider_class.sliders+1] = sl
                
                -- "sl.id" can be anything (f.ex. use 0 for first slider, 1 for second slider etc.) 
                sl.id = id or #Slider_class.sliders -- if nil, "id" is slider position in "Slider_class.sliders" (from 1 to n)
                
                
                --sl._mouse_on_slider = false
                sl._mouse_in = false
                --sl._dragging = false
                sl._mouse_LMB_state = false
                sl.last_touched = false
                
                sl._mouse_ox_l, sl._mouse_oy_l = 0,0
                sl._mouse_dx = 0
                sl._mouse_dy = 0
                sl._last_mouse_x, sl._last_mouse_y = 0, 0
                
                sl._prevent_slider_move = false
              end
              )
--local Slider = Slider_class.Slider                    
--Slider.last_touched = nil

-- Slider rectangle
function Slider:set_area(x1, y1, w, h)
  self.x1 = x1
  self.y1 = y1
  self.w = w
  self.h = h
  self.x2 = x1 + w
  self.y2 = y1 + h
end

-- Mouse hit zone 
function Slider:set_hit_zone(x1, y1, w, h)
  self.hit_zone_x1 = x1 or self.x1
  self.hit_zone_y1 = y1 or self.y1
  self.hit_zone_w = w or self.w
  self.hit_zone_h = h or self.h
  if x1~=nil and w~=nil then
    self.hit_zone_x2 = x1 + w
  else
    self.hit_zone_x2 = self.x1 + self.w
  end
  if y1~=nil and h~=nil then
    self.hit_zone_y2 = y1 + h
  else
    self.hit_zone_y2 = self.y1 + self.h
  end  
end


function Slider:set_help_text()
  if self.help_text == "" then return false end
  gfx.set(1,1,1,1)
  gfx.x = 10
  gfx.y = 10
  gfx.printf(self.help_text)
end

-- Set slider foreground color
function Slider:set_fg_color(r,b,g,a)
  self.fg_r = r or gfx.r
  self.fg_g = g or gfx.g
  self.fg_b = b or gfx.b
  self.fg_a = a or gfx.a
end

-- Set slider background color
function Slider:set_bg_color(r,b,g,a)
  self.bg_r = r or gfx.r
  self.bg_g = g or gfx.g
  self.bg_b = b or gfx.b
  self.bg_a = a or gfx.a
end

-- Set mouse hit zone color
function Slider:set_hz_color(r,b,g,a)
  self.hz_r = r or gfx.r
  self.hz_g = g or gfx.g
  self.hz_b = b or gfx.b
  self.hz_a = a or gfx.a
end

-- Set value string color
function Slider:set_value_color(r,b,g,a)
  self.val_r = r or gfx.r
  self.val_g = g or gfx.g
  self.val_b = b or gfx.b
  self.val_a = a or gfx.a
end

-- Set label color
function Slider:set_label_color(r,b,g,a)
  self.lbl_r = r or gfx.r
  self.lbl_g = g or gfx.g
  self.lbl_b = b or gfx.b
  self.lbl_a = a or gfx.a
end

--[[
function Slider:_mouse_on()
  if gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2 then
    self._mouse_on = true
    return true
  else
    self._mouse_on = false
    return false
  end
  --return gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2
end
--]]



function Slider:get_val()
  return self.val
end


function Slider:set_val(val)
  self.val = val
end


function Slider:get_default_val()
  return self.default_val
end


function Slider:show_foreground(b_show)
  self.show_fg = b_show
end


function Slider:show_background(b_show)
  self.show_bg = b_show
end


function Slider:show_hitzone(b_show)
  self.show_hit_zone = b_show
end


function Slider:draw_value(x, y, digits_after_dec_point)
  if self.show_value then
    local digits = digits_after_dec_point or 3
    local val_str = "%." .. tostring(digits).. "f"
    val_str = string.format(val_str, self.val)
    self.val_w = gfx.measurestr(val_str)
    gfx.set(self.val_r, self.val_g, self.val_b, self.val_a)
    gfx.x = x or self.x2-self.val_w
    gfx.y = y or (self.y1 + 0.5*self.h - 0.5*gfx.texth)
    gfx.printf(val_str)
  end
end


function Slider:draw_label(x, y)
  -- Draw slider label (if "slider_label" is not an empty string)
  if self.show_label then 
    if self.lbl ~= "" then
      gfx.x = x or self.x1
       --gfx.x = 0.5*(self.x1+self.x2)-0.5*self.lbl_w
      gfx.y = y or (self.y1 + 0.5*self.h - 0.5*gfx.texth)
      gfx.set(self.lbl_r, self.lbl_g, self.lbl_b, self.lbl_a)
      gfx.printf(self.lbl)
    end
  end
end


function Slider:_draw()
  if not self.show then 
    return
  end
  -- Draw slider foreground
  if self.show_fg then
    gfx.set(self.fg_r, self.fg_g, self.fg_b, self.fg_a)
    gfx.rect(self.x1, self.y1, self.pos - self.x1, self.h)
  end
  
  -- Draw slider background
  if self.show_bg then 
    gfx.set(self.bg_r, self.bg_g, self.bg_b, self.bg_a)
    gfx.rect(self.x1, self.y1, self.w, self.h)
  end
    
  -- Draw mouse hit zone
  if self.show_hit_zone then
    gfx.set(self.hz_r, self.hz_g, self.hz_b, self.hz_a)
    gfx.rect(self.hit_zone_x1, self.hit_zone_y1, self.hit_zone_w, self.hit_zone_h)
  end
  
  self:draw_label()
  self:draw_value()
  
end


function Slider:_is_mouse_on_slider()
  if gfx.mouse_x > self.x1 and gfx.mouse_x < self.x1 + self.w and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y1 + self.h then
    self._mouse_on_slider = true
    --self._mouse_state = true
    return true
  else
    self._mouse_on_slider = false
    return false
  end
  --return gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2
end


function Slider:_on_mouse_hover()
  --if self._dragging or mouse.last_LMB_state == false then
  --  self.val_a = 1 -- highlight value
  self:set_help_text()
  --end
end


function Slider:_on_mouse_on_hitzone()

end

function Slider:_on_mouse_LMB_down()
  --Slider_last_touched = self--self.id
  self._mouse_ox_l, self._mouse_oy_l = gfx.mouse_x, gfx.mouse_y
  Slider_class.last_touched = self
  self._mouse_LMB_state = true -- this is set to false when mouse button is released
  --self.last_touched = true
  --reaper.ShowConsoleMsg("lmb" .. "\n")
  self.last_pos = self.pos
  self.last_val = self.val
  
  -- Prevent moving a slider if "shift + lmb" or "ctrl + lmb" is pressed
  -- (This is used in "Track I/O mixer" script)
  if gfx.mouse_cap == 5 or gfx.mouse_cap == 9 then -- 5: ctrl + lmb, 9: shift + lmb 
    self._prevent_slider_move = true
  end
  --self._dragging = true
end


function Slider:_on_mouse_RMB_down()
  --Slider_last_touched = self--self.id
  --self._mouse_ox_l, self._mouse_oy_l = gfx.mouse_x, gfx.mouse_y
  Slider_class.last_touched = self
  self._mouse_RMB_state = true -- this is set to false when mouse button is released
  --self.last_touched = true
  --reaper.ShowConsoleMsg("rmb" .. "\n")
  --self.last_pos = self.pos
  --self.last_val = self.val
  --self._dragging = true
end


function Slider:_on_mouse_move()
  --if not self._mouse_LMB_state then return end
  
  self._mouse_dx = gfx.mouse_x - self._mouse_ox_l
  self._mouse_dy = gfx.mouse_y - self._mouse_oy_l
  local d = 0 -- mouse position change in pixels
  if self.horizontal then
    d = self._mouse_dy
  else
    d = self._mouse_dx
  end
  if not self._prevent_slider_move then
    self.pos = math.min(math.max(self.x1, self.last_pos+self.drag_sensitivity*d),self.x2)
     
    self.val = scale_pos_to_slider_val(self.min_val, self.max_val, self.pos, self.x1, self.x2)
    self._last_mouse_x, self._last_mouse_y = gfx.mouse_x, gfx.mouse_y
  end
end


function Slider:_on_value_change()
  self.pos = scale_slider_val_to_x(self.min_val, self.max_val, self.val, self.x1, self.x2)
  --self.last_pos = self.pos
end


function Slider:_on_position_change()
  self.val = scale_pos_to_slider_val(self.min_val, self.max_val, self.pos, self.x1, self.x2)
  --self.last_val = self.val
end



------------
-- Update --
------------
function Slider:update()
    
  --[[
  if self.pos ~= self.last_pos then
    self:_on_position_change()
  end
  --]]
  ----if not mouse.LMB_state then --and self._dragging then
  if not (gfx.mouse_cap&1 == 1) then --and self._dragging then
    --self._dragging = false
    self.last_touched = false
    --self.last_pos = self.pos
    self._mouse_LMB_state = false
    self._prevent_slider_move = false
    self.val_a = 0.8 -- set value highlight back to normal
  end
  
  if not (gfx.mouse_cap&2 == 2) then --and self._dragging then
    --self._dragging = false
    --self.last_touched = false
    --self.last_pos = self.pos
    self._mouse_RMB_state = false
    --self.val_a = 0.8 -- set value highlight back to normal
  end
  
  
  ---------------------------------------
  -- Slider value is changed by REAPER --
  ---------------------------------------
  ----if not mouse.LMB_state then -- LMB is not pressed...
  --if not (gfx.mouse_cap&1 == 1) then --and self._dragging then
    if self.val ~= self.last_val then  -- ... check if something has changed the slider value
      self:_on_value_change()
    end
  --end
  
  
  -------------------------------------
  -- Slider value is changed by user --
  -------------------------------------
  
  -- Mouse on slider?
  if mouse_in_rect(self.x1, self.y1, self.w, self.h) then
    self:_on_mouse_hover()
  end
  
  -- Mouse on slider's "mouse hit area"?
   if self.show and mouse_in_rect(self.hit_zone_x1, self.hit_zone_y1, self.hit_zone_w, self.hit_zone_h) then
    self:_on_mouse_on_hitzone()
    self._mouse_in = true
  else
    self._mouse_in = false
  end
  
  
  -- LMB pressed...
  ----if mouse.LMB_state then
  if gfx.mouse_cap&1 == 1 then
    -- ...and mouse was on slider?
    if not self._mouse_LMB_state and not mouse.last_LMB_state and self._mouse_in then 
      self:_on_mouse_LMB_down()
    elseif self._mouse_LMB_state and (gfx.mouse_x ~= self._last_mouse_x or gfx.mouse_y ~= self._last_mouse_y) then
      self:_on_mouse_move()
    end
  --end
  
  elseif gfx.mouse_cap&2 == 2 then
    if not self._mouse_RMB_state and not mouse.last_RMB_state and self._mouse_in then
      self:_on_mouse_RMB_down()
    end
  end
  
  --if self._mouse_LMB_state then
  --end
  self:_draw()
end


function Slider:set_to_default_value()
  self.val = self.default_val
  self.pos = scale_slider_val_to_x(self.min_val, self.max_val, self.val, self.x1, self.x2)
  
  self.last_val = self.val
  self.last_pos = self.pos
  --self:update()
end

         
Slider_class.Slider = Slider         

return Slider_class

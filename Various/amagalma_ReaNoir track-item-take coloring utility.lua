-- @description ReaNoir - Track/Item/Take coloring utility
-- @author amagalma
-- @version 2.15
-- @changelog fix: coloring a range of tracks/items/takes with a gradient (thanks to juliansader)
-- @link http://forum.cockos.com/showthread.php?t=189602
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Track/Item/Take coloring utility - modification of Spacemen Tree's REAchelangelo
--
--   - Palette of 24 colors (Color Boxes) + 1 temporary (Temporary - the big color box on top)
--   - Left-click a Color Box to Color Tracks, Items or Takes and set it as Temporary
--   - Tracks/Items are recognized automatically according to what was lastly clicked while the Takes mode is set manually by the user
--   - Right-click a Color Box to save the Temporary color into that box
--   - Load/save different user palettes (.txt files)
--   - Left-click Save button to Save current palette or Right-Click to Save As
--   - Left-click Load button to load a new palette or Right-Click to load the default palette
--   - Set the Temporary color to the color of the first selected track/item/take according to what was lastly clicked (Get Color button)
--   - Show Hex name of Temporary color
--   - Left-click Hex name to enter a Hex color code manually (formats: 123456, #123456, # 123456 & 0x123456)
--   - Right-click Hex name to paste it to the clipboard for use with SWS Auto Color/Icons
--   - Palette is automatically saved to last_palette_on_exit.txt as a backup. If you try to load last_palette_on_exit, then you are prompted to save it with a new name.
--   - Left-click Darker/Brighter buttons to make Temporary Color brighter or darker. Right-click them to make it black/white
--   - Script saves user palettes in a directory called ReaNoir in the same path as the script. Preferences are saved to ExtState
--   - Click LD/SV SWS button to load SWSColor files
--   - Right-Click LD/SV SWS button to save SWSColor files
--   - Click SWS Colors button to open the SWS Color Management tool
--   - Ability to dock the script to the left or to the right
--   - Right-click sliders' area to toggle between RGB and HSL mode
--   - Information displayed on top of ReaNoir when hovering mouse over buttons/sliders
--   - Ctrl-click on any color box (including the Temporary color box) to color the selected tracks/items/takes from the existing color to the ctrl-clicked color in grades
--   - Find in the script "MODE OF OPERATION" to set to Normal (RGB/HSL) or Compact (No Sliders) mode
--   - When in Compact (No Sliders) Mode, Right-click Get Color Button to set Temporary Color Box's color
--   - Click on "?" on right top corner to display information, Right-Click for manual


-- Special Thanks to: Spacemen Tree, spk77, X-Raym, cfillion, Lokasenna and Gianfini!!! :)


version = "v2.15"




-------------------------------------------------\
--------------------------------------------------|
--                                                |
      mode = "rgb"       -- "rgb" OR "compact"      <<------ MODE OF OPERATION (WITH/OUT SLIDERS)
--                                                |
--------------------------------------------------|
-------------------------------------------------/




local reaper = reaper

-----------------------------------------------FOR DEBUGGING-------------------------------------
function Msg(name)
-- usage: Msg('') // put inside the '' what you want to get
  local value = _G[name]
  for i=1,math.huge do
    local localname, localvalue = debug.getlocal(2,i,1)
    if not localname then
      break -- no more locals to check
    elseif localname == name then
      value = localvalue
    end
  end
  if value then
    reaper.ShowConsoleMsg(string.format("%s = %s", name, tostring(value)).."\n")
  else
    reaper.ShowConsoleMsg(string.format("No variable named '%s' found.", name).."\n")
  end
end
-----------------------------------------------------------------------------------------------
------------- "class.lua" is copied from http://lua-users.org/wiki/SimpleLuaClasses -----------
-- class.lua
-- Compatible with Lua 5.1 (not 5.0).
function class(base, init)
local c = {} -- a new class instance
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
--//Slider Scaling functions //
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
--///////////////////////
--//Button Scaling functions //
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
function(sl, x1, y1, w, h, val, min_val, max_val, lbl, help_text, r, g, b)
sl.x1 = x1
sl.y1 = y1
sl.w = w
sl.h = h
sl.x2 = x1+w
sl.y2 = y1+h
sl.val = val
sl.min_val = min_val
sl.max_val = max_val
sl.lbl = lbl
sl.help_text = help_text

--// Modded Slider Colors //--

  sl.r, sl.g, sl.b = r, g, b

sl.mouse_state = 0
sl.lbl_w, sl.lbl_h = gfx.measurestr(lbl)
end
) -- end of slider class

function Slider:set_help_text()
  if self.help_text == "" then return false end
  if string.match(reaper.GetOS(), "Win") then
      gfx.setfont(2,"Tahoma", 13)
  elseif string.match(reaper.GetOS(), "OSX") then
    gfx.setfont(2,"Geneva", 10)
  else
    gfx.setfont(2,"Tahoma", 11)
  end
  local width = gfx.measurestr(self.help_text)
  gfx.set(0.85,0.85,0.85,1)
  gfx.x = GUI_centerx-width/2
  gfx.y = 11
  gfx.printf(self.help_text)
  gfx.setfont(1)
end

function Slider:draw()
self.a = 0.6
gfx.set(0.7,0.7,0.7,self.a)
if last_mouse_state == 0 and self.mouse_state == 1 then self.mouse_state = 0 end
if self.mouse_state == 1 or gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2 then
if self.help_text ~= "" then self:set_help_text() end -- Draw info/help text (if self.help_text is not "")
if last_mouse_state == 0 and gfx.mouse_cap & 1 == 1 and self.mouse_state == 0 then
self.mouse_state = 1
end
if self.mouse_state == 1 then
self.val = scale_x_to_slider_val(self.min_val, self.max_val, gfx.mouse_x , self.x1, self.x2)
end
end

--// Modded Slider Color //--

    gfx.set(self.r,self.g,self.b,1)

self.x_coord = scale_slider_val_to_x(self.min_val, self.max_val, self.val, self.x1, self.x2)
--// Draw slider
gfx_a = self.a;
gfx_a = 1;
gfx.rect(self.x1, self.y1, self.x_coord-self.x1, self.h)
--// Draw slider label (if "slider_label" is not an empty string)
if self.lbl ~= "" then
gfx.x = self.x1-15
gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth
gfx.set(0.7,0.7,0.7,1);
gfx.printf(self.lbl)
end
gfx.set(0.7,0.7,0.7,1)
gfx_a = 0.2;
gfx.a = self.a-0.3
gfx.rect(self.x1, self.y1, self.w, self.h)
--// Show slider value
self.val_w = gfx.measurestr(string.format("%.2f",self.val))
gfx.a = 1
gfx.x = self.x2 - self.val_w + 33
return self.val
end
    
--//////////////////
--// Button class //
--//////////////////
local Button = class(
function(btn,x1,y1,w,h,state_count,state,visual_state,lbl,help_text,center,border)
btn.x1 = x1
btn.y1 = y1
btn.w = w
btn.h = h
btn.x2 = x1+w
btn.y2 = y1+h
btn.state = state
btn.state_count = state_count - 1
btn.vis_state = visual_state
btn.label = lbl
btn.help_text = help_text
btn.__mouse_state = 0
btn.label_w, btn.label_h = gfx.measurestr(btn.label)
btn.__state_changing = false
btn.r = 0.7
btn.g = 0.7
btn.b = 0.7
btn.a = 0.2
btn.lbl_r = 1
btn.lbl_g = 1
btn.lbl_b = 1
btn.lbl_a = 1
btn.center = center
btn.border = border
end
)
-- get current state
function Button:get_state()
return self.state
end
-- cycle through states
function Button:set_next_state()
if self.state <= self.state_count - 1 then
self.state = self.state + 1
else self.state = 0
end
end
-- get "button label text" w and h
function Button:measure_lbl()
self.label_w, self.label_h = gfx.measurestr(self.label)
end
-- returns true if "mouse on element"
function Button:__is_mouse_on()
return(gfx.mouse_x > self.x1 and gfx.mouse_x < self.x2 and gfx.mouse_y > self.y1 and gfx.mouse_y < self.y2)
end

function Button:__lmb_down()
return(last_mouse_state == 0 and gfx.mouse_cap & 1 == 1 and self.__mouse_state == 0)
end

function Button:__rmb_down()
return(last_mouse_state == 0 and gfx.mouse_cap & 2 == 2 and self.__mouse_state == 0)
end

--- Control + left click
function Button:__lmbCtrl_down()
return(last_mouse_state == 0 and gfx.mouse_cap & 5 == 5 and self.__mouse_state == 0)
end

function Button:set_help_text()
if self.help_text == "" then return false end
gfx.setfont(2)
local width = gfx.measurestr(self.help_text)
gfx.set(0.85,0.85,0.85,1)
gfx.x = GUI_centerx-width/2
gfx.y = 11
gfx.printf(self.help_text)
gfx.setfont(1)
end

function Button:set_color(r,g,b,a)
self.r = r
self.g = g
self.b = b
self.a = a
end
function Button:set_label_color(r,g,b,a)
self.lbl_r = r
self.lbl_g = g
self.lbl_b = b
self.lbl_a = a
end
function Button:draw_label()
-- Draw button label
if self.label ~= "" then
  if self.center ==1 then 
  gfx.x = self.x1 + 5
  else gfx.x = self.x1 + math.floor(0.5 * self.w - 0.5 * self.label_w) -- center the label
  end
gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth
if self.__mouse_state == 1 then
gfx.y = gfx.y + 1
gfx.a = self.lbl_a*0.5
elseif self.__mouse_state == 0 then
gfx.a = self.lbl_a
end
gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,self.lbl_a)
gfx.printf(self.label)
if self.__mouse_state == 1 then gfx.y = gfx.y - 1 end
end
end
-- Draw element (+ mouse handling)
function Button:draw()
  -- button released (and was clicked on element)
  if last_mouse_state == 0 and self.__mouse_state == 1 or 2 or 5 then self.__mouse_state = 0 end
  
  -- Mouse is on element -----------------------
  if self:__is_mouse_on() then
      if self:__lmb_down() then -- Left mouse btn is pressed on button
        self.__mouse_state = 1
        self.__state_changing = true
      end
      self:set_help_text()
      if last_mouse_state == 0 and gfx.mouse_cap & 1 == 0 and self.__state_changing == true then
        if self.onRClick ~= nil then self:onRClick() 
           self.__state_changing = false end
      elseif last_mouse_state == 0 and gfx.mouse_cap == 5 and self.__state_changing == true then  
        if self.onCtrlClick ~= nil then self:onCtrlClick()
           self.__state_changing = false end
      end
    -------Mouse is on element (right button)
      if self:__is_mouse_on() then
        if self:__rmb_down() then -- Right mouse btn is pressed on button
            self.__mouse_state = 2
            self.__state_changing = true
        end
        self:set_help_text()
        if last_mouse_state == 0 and gfx.mouse_cap & 2 == 0 and self.__state_changing == true then
             if self.onClick ~= nil then self:onClick()
          elseif self.onCtrlClick ~= nil then self:onCtrlClick()
          end
            self.__state_changing = false
        end
      ---- Mouse is on element (Ctrl & lmb)
        if self:__is_mouse_on() then
            if self:__lmbCtrl_down() then -- Left mouse btn & Ctrl is pressed on button
              self.__mouse_state = 5
              self.__state_changing = true
            end
            self:set_help_text()
            if last_mouse_state == 0 and gfx.mouse_cap & 5 == 0 and self.__state_changing == true then
            if self.onRClick ~= nil then self:onRClick() 
                  self.__state_changing = false end
          elseif last_mouse_state == 0 and gfx.mouse_cap & 5 == 1 and self.__state_changing == true then  
              if self.onClick ~= nil then self:onClick()
                    self.__state_changing = false end
            end
        end
      end
-- Mouse is not on element -----------------------
  else
      if last_mouse_state == 0 and self.__state_changing == true then
        self.__state_changing = false
      end
  end

  if self.__mouse_state == 1 or self.vis_state == 1 or self.__state_changing then
      gfx.set(0.8*self.r,0.8*self.g,0.8*self.b,math.max(self.a - 0.2, 0.2)*0.8)
      gfx.rect(self.x1, self.y1, self.w, self.h)
-- Button is not pressed
  elseif not self.state_changing or self.vis_state == 0 or self.__mouse_state == 0 then
      gfx.set(self.r+0.2,self.g+0.2,self.b+0.2,self.a)
      gfx.rect(self.x1, self.y1, self.w, self.h)
      gfx.a = math.max(0.4*self.a, 0.6)
      gfx.set(0.3*self.r,0.3*self.g,0.3*self.b,math.max(0.9*self.a,0.8))
  end

  self:draw_label()
    gfx.set(self.r+0.2,self.g+0.2,self.b+0.2,self.a)
    if self.border ~= 1 then
      gfx.rect(self.x1-2, self.y1-2, self.w+4, self.h+4,0) 
      gfx.set(1,1,1,1)
      gfx.set(0.1,0.1,0.1,1)
      gfx.rect(self.x1-3, self.y1-3, self.w+6, self.h+6,0)
    end
    gfx.set(0.1,0.1,0.1,1)
    gfx.rect(self.x1-1, self.y1-1, self.w+2, self.h+2,0)
end

-------- The above is taken from SPK77's Play and Stop Buttons fine script ---------
--------- so a big Thank You to him. Slight mods done to Mouse and colors ----------
------------------------------------------------------------------------------------


         
------------------------------------------
------------- Variables ------------------
------------------------------------------
dock = 0
colors = {}
info = debug.getinfo(1,'S')
script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
separ = string.match(reaper.GetOS(), "Win") and "\\" or "/"
last_palette_on_exit = script_path .."ReaNoir"..separ.."last_palette_on_exit.txt"
UserPalettes_path = script_path .. "ReaNoir"..separ
reaper.RecursiveCreateDirectory(UserPalettes_path,1)

------------------------------------------
--------- GUI Variables ------------------
------------------------------------------
if mode == "compact" then compact = 115 else compact = 0 end
GUI_xstart = 5
GUI_xend = 186
GUI_ystart = 5
GUI_yend = 690 - compact
GUI_centerx = GUI_xend/2 + GUI_xstart
GUI_centery = GUI_yend/2 + GUI_ystart + compact/2
CopiedClipboard = false          

------------------------------------------
--------- ColorBoxes Variables -----------
------------------------------------------
ColorBoxes = {}
defcolors = {"DE6363", "DED663", "A191E3", "DE91E3", "788F63", "6363A3", "59590D", "633363", "306363", "1459E0", "63A363", 
"C44247", "94A654", "639CD1", "CCA626", "247A38", "A16E29", "A18263", "852600", "F21700", "94D1FF", "63F2AB", "3DE063", "FFDB78"}
for row = 1,24 do
table.insert(ColorBoxes, { }) -- insert new row
end 

------------------------------------------
--------- Functions ----------------------
------------------------------------------

    function GUI()
      gfx.clear = 3355443    --- Global Window border color set to dark gray
      gfx.set(0.1,0.1,0.1,1)   --- Global Window color set to lighter gray
      gfx.rect(GUI_xstart,GUI_ystart,GUI_xend-10,GUI_yend-10,1)
      gfx.set(0.4,0.4,0.4,0.5)
      gfx.rect(GUI_xstart +5,GUI_ystart +5,GUI_xend -20,GUI_yend-20,1)
      local begin = 7
      local endd = 168-compact
      gfx.set(0.1,0.1,0.1,1)
      gfx.rect(GUI_xstart+begin+2,GUI_ystart+begin+16,GUI_xend-begin*3-7,GUI_yend-begin*3-179,0)
      gfx.set(0.1,0.1,0.1,0.7)
      gfx.rect(GUI_xstart+begin+4,GUI_ystart+begin+18,GUI_xend-begin*3-11,GUI_yend-begin*3-183,1)
      gfx.rect(GUI_xstart +9,GUI_ystart+532-compact,GUI_xend -28,GUI_yend-endd*3-48-compact*2,1)
      gfx.set(0.1,0.1,0.1,1)
      gfx.rect(GUI_xstart +7,GUI_ystart+530-compact,GUI_xend -24,GUI_yend-endd*3-44-compact*2,0) 
      gfx.set(1,1,1,0.2)   
      gfx.line(GUI_xstart +60,GUI_ystart+548-compact,GUI_xstart +158,GUI_ystart+548-compact,0) -- palette line up
      gfx.line(GUI_xstart +16,GUI_ystart+625-compact,GUI_xstart +158,GUI_ystart+625-compact,0) -- palette line down
      gfx.set(1,1,1,0.5)
      gfx.x = GUI_xstart +16 -- Palette text x and y
      gfx.y = GUI_ystart +540 -compact
      gfx.drawstr ("Palette")
      gfx.set(0.1,0.1,0.1,1)
      gfx.rect(GUI_xstart +13,GUI_ystart+558-compact,GUI_xstart +145,24,0) -- Palette name border
      gfx.set(0.2,0.2,0.2,1) 
      gfx.rect(GUI_xstart +14,GUI_ystart+559-compact,GUI_xstart +143,22,1) -- Palette name field   
    end
        
    function Dock_selector_GUI()
        gfx.set(0.2,0.2,0.2,1)
          if dock == 3841 then 
              DockselR_btn:set_color(0.1,0.1,0.1,1)
              DockselU_btn:set_color(0.1,0.1,0.1,1)              
          elseif dock == 1 then
              DockselL_btn:set_color(0.1,0.1,0.1,1)
              DockselU_btn:set_color(0.1,0.1,0.1,1)          
          elseif dock == 0 then
              DockselL_btn:set_color(0.1,0.1,0.1,1)
              DockselR_btn:set_color(0.1,0.1,0.1,1)          
          end
    end 
    
    function Dock_selector_INIT()   
        local Docksel = ""
        local Docksel_x = GUI_centerx - 95
        local Docksel_y = GUI_centery - 346
        local Docksel_xlength = 10
        local help = "Dock ReaNoir Left"
        DockselL_btn = Button(Docksel_x,Docksel_y +10,Docksel_xlength,11,2,0,0,Docksel, help,0,1)
            if dock == 3841 then 
                DockselL_btn:set_color(0.5,0.1,0.1,1)
            else 
                DockselL_btn:set_color(0.1,0.1,0.1,1)
            end
                DockselL_btn.onClick = function ()
                    dock = 3841
                    DockselL_btn:set_color(0.5,0.1,0.1,1)
                    Write_Prefs()
                end    
        local help = "Dock ReaNoir Right"       
        DockselR_btn = Button(Docksel_x +11,Docksel_y +10,Docksel_xlength,11,2,0,0,Docksel, help,0,1)
            if dock == 1 then 
                DockselR_btn:set_color(0.5,0.1,0.1,1)
            else 
                DockselR_btn:set_color(0.1,0.1,0.1,1)
            end
                DockselR_btn.onClick = function () 
                    dock = 1
                    DockselR_btn:set_color(0.5,0.1,0.1,1)
                    Write_Prefs()
                end
        local help = "Float / Undock ReaNoir"    
        DockselU_btn = Button(Docksel_x,Docksel_y,Docksel_xlength +11,10,2,0,0,Docksel, help,0,1)
            if dock == 0 then 
                DockselU_btn:set_color(0.5,0.1,0.1,1)
            else 
                DockselU_btn:set_color(0.1,0.1,0.1,1)
            end                    
                DockselU_btn.onClick = function () 
                    dock = 0
                    DockselU_btn:set_color(0.5,0.1,0.1,1)
                    Write_Prefs()
                end                     
    end 
    
    function ColorBx_INIT()
        local clx = 5
        local cly = 28
        local drawcount = 1        
          for createbox = 1,24 do            
              ColorBx_GUI(createbox,clx,cly)            
              clx = clx + 25           
                  if drawcount ==4 then 
                     cly = cly + 26
                     drawcount = 0
                     clx = 5
                  end               
              drawcount = drawcount + 1 
          end  
    end
    
    function ColorBx_GUI(boxID,xspace,yspace)
        local ColorBx_x = GUI_centerx -57 + xspace
        local ColorBx_y = GUI_centery -71 + yspace - compact
        local help = "Rmb->Save | Ctrl->Gradient"
        ColorBoxes [boxID] = Button (ColorBx_x, ColorBx_y, 20, 20, 2,0,0, "", help,0,1)
        ColorBoxes [boxID] : set_color(0.1, 0.1, 0.1, 1)
        ColorBx_CLICK(ColorBoxes [boxID],boxID)
    end      
    
    function SetSliders(boxID)
        if mode == "rgb" or mode == "compact" then
              slider_btn_r.val = boxID.r +0.2
              slider_btn_g.val = boxID.g +0.2
              slider_btn_b.val = boxID.b +0.2
              slider_btn_a.val = boxID.a
        elseif mode == "hsl" then
              local h, s, l = rgbToHsl(boxID.r+0.2, boxID.g+0.2, boxID.b+0.2)
              slider_btn_h.val = h
              slider_btn_s.val = s
              slider_btn_l.val = l
              slider_btn_a.val = boxID.a
        end
    end

    function ColorBx_CLICK(boxID)
        boxID.onClick = function ()
            SetSliders(boxID)
            if what == "tracks" then
                Convert_RGB(boxID.r +0.2, boxID.g +0.2, boxID.b +0.2, boxID.a)           
                ApplyColor_Tracks()
            elseif what == "items" then
                Convert_RGB(boxID.r +0.2, boxID.g +0.2, boxID.b +0.2, boxID.a)           
                ApplyColor_Items()
            elseif what == "takes" then
                Convert_RGB(boxID.r +0.2, boxID.g +0.2, boxID.b +0.2, boxID.a)           
                ApplyColor_Takes()
            end
        end
        boxID.onRClick = function ()
        local answer = reaper.MB("Save temporary edit color to clicked colorbox?", "Save edit color", 1)
          if answer == 1 then
            boxID.r = slider_btn_r.val -0.2
            boxID.g = slider_btn_g.val -0.2
            boxID.b = slider_btn_b.val -0.2
            boxID.a = slider_btn_a.val
            SaveColorFile(last_palette_on_exit)
          end
        end
        boxID.onCtrlClick = function ()
          if what == "tracks" then
            local seltracks = reaper.CountSelectedTracks(0)
            if seltracks > 2 then
                  local firsttrack = reaper.GetSelectedTrack(0, 0)
                  local firstcolor = reaper.GetMediaTrackInfo_Value(firsttrack, "I_CUSTOMCOLOR")
                  if firstcolor == 0 or nil then
                    reaper.MB("The first selected track must already have a custom color in order to make a gradient!", "Error!", 0 )
                  else
                    reaper.Undo_BeginBlock()
                    Convert_RGB(boxID.r +0.2, boxID.g +0.2, boxID.b +0.2, boxID.a)                      
                    local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor)
                    local r_step = (red-firstcolor_r)/(seltracks-1)
                    local g_step = (green-firstcolor_g)/(seltracks-1)
                    local b_step = (blue-firstcolor_b)/(seltracks-1)
                    for i=1,seltracks-1 do
                      local value_r,value_g,value_b = math.floor(0.5+firstcolor_r+r_step*i), math.floor(0.5+firstcolor_g+g_step*i), math.floor(0.5+firstcolor_b+b_step*i)
                      local track = reaper.GetSelectedTrack(0, i)
                      reaper.SetTrackColor(track, reaper.ColorToNative(value_r, value_g, value_b))
                    end
                    reaper.Undo_EndBlock("Color selected track(s) with gradient colors", -1)
                    SetSliders(boxID)
                  end
            else
                 reaper.MB( "Please select at least three tracks!", "Cannot create gradient colors!", 0 )
            end
          elseif what == "items" then
            local selitems = reaper.CountSelectedMediaItems(0)
            if selitems > 2 then
                 local item = reaper.GetSelectedMediaItem( 0, 0 )
                 local firstcolor = reaper.GetDisplayedMediaItemColor(item)
                 if firstcolor == 0 or nil then
                   reaper.MB("The first selected item must already have a custom color in order to make a gradient!", "Error!", 0 )
                 else
                   reaper.Undo_BeginBlock()
                   Convert_RGB(boxID.r +0.2, boxID.g +0.2, boxID.b +0.2, boxID.a)
                   local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor|0x1000000)
                   local r_step = (red-firstcolor_r)/(selitems-1)
                   local g_step = (green-firstcolor_g)/(selitems-1)
                   local b_step = (blue-firstcolor_b)/(selitems-1)
                   for i=1,selitems-1 do
                     local value_r,value_g,value_b = math.floor(0.5+firstcolor_r+r_step*i), math.floor(0.5+firstcolor_g+g_step*i), math.floor(0.5+firstcolor_b+b_step*i)
                     local item = reaper.GetSelectedMediaItem(0, i)
                     local color = reaper.ColorToNative(value_r, value_g, value_b)|0x1000000
                     local active_take = reaper.GetActiveTake(item)
                     if active_take ~= nil then
                      reaper.Main_OnCommand(41333, 0) -- Take: Set active take to default color
                     end
                     reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
                     reaper.UpdateArrange()
                   end
                   reaper.Undo_EndBlock("Color selected item(s) with gradient colors", -1)
                   SetSliders(boxID)
                 end
            else
                 reaper.MB( "Please select at least three items!", "Cannot create gradient colors!", 0 )
            end

          elseif what == "takes" then
            local selitems = reaper.CountSelectedMediaItems(0)
            if selitems < 1 then
              reaper.MB("Not any items are selected!", "Error!", 0 )
            else
              for i=0,selitems-1 do
                local item = reaper.GetSelectedMediaItem(0, i)
                local take_cnt = reaper.CountTakes(item)
                if take_cnt < 3 then
                  if found == 1 then found = 1 else found = 0 end
                else
                  found = 1
                  local take = reaper.GetMediaItemTake( item, 0) -- get first take
                  local firstcolor = reaper.GetDisplayedMediaItemColor2( item, take)
                  Convert_RGB(boxID.r +0.2, boxID.g +0.2, boxID.b +0.2, boxID.a)
                  local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor|0x1000000)
                  local r_step = (red-firstcolor_r)/(take_cnt-1)
                  local g_step = (green-firstcolor_g)/(take_cnt-1)
                  local b_step = (blue-firstcolor_b)/(take_cnt-1)
                  reaper.Undo_BeginBlock()
                  for j=1, take_cnt-1 do
                    local take = reaper.GetMediaItemTake( item, j)
                    local value_r,value_g,value_b = math.floor(firstcolor_r+r_step*j), math.floor(firstcolor_g+g_step*j), math.floor(firstcolor_b+b_step*j)
                    local color = reaper.ColorToNative(value_r, value_g, value_b)|0x1000000
                    reaper.SetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR", color|0x1000000)
                    reaper.UpdateItemInProject( item )
                    reaper.UpdateArrange()
                  end
                  reaper.Undo_EndBlock("Color takes of selected item(s) with gradient colors", -1)
                end
              end
              if found == 0 then
                reaper.MB( "Not any item with more than two takes was selected!", "Cannot create gradient colors!", 0 )
              end
            end
            SetSliders(boxID)
            found = nil
          end
        end
    end
   
    function Convert_RGB(ConvertRed,ConvertGreen,ConvertBlue,ConvertAlpha)
        alpha = ConvertAlpha
        red = math.floor(ConvertRed*255 + 0.5)
        green = math.floor(ConvertGreen*255 + .5)
        blue =  math.floor(ConvertBlue*255 + .5)
        ConvertedRGB = reaper.ColorToNative (red, green, blue)    
        return ConvertedRGB, red, green, blue, alpha
    end

-- Emmanuel Oga's rgbToHsl and hslToRgb functions taken from here:
-- https://github.com/EmmanuelOga/columns/blob/master/utils/color.lua

    function rgbToHsl(r, g, b) -- values in-out 0-1
      local max, min = math.max(r, g, b), math.min(r, g, b)
      local h, s, l
      l = (max + min) / 2
      if max == min then
        h, s = 0, 0 -- achromatic
      else
        local d = max - min
        if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
        if max == r then
          h = (g - b) / d
          if g < b then h = h + 6 end
        elseif max == g then h = (b - r) / d + 2
        elseif max == b then h = (r - g) / d + 4
        end
        h = h / 6
      end
      return h, s, l or 1
    end


    function hslToRgb(h, s, l) -- values in-out 0-1
      local r, g, b
      if s == 0 then
        r, g, b = l, l, l -- achromatic
      else
        function hue2rgb(p, q, t)
          if t < 0   then t = t + 1 end
          if t > 1   then t = t - 1 end
          if t < 1/6 then return p + (q - p) * 6 * t end
          if t < 1/2 then return q end
          if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
          return p
        end
        local q
        if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1/3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1/3)
      end
      return r,g,b
    end

    function ApplyColor_Tracks()
      reaper.Undo_BeginBlock()
         local track_count = reaper.CountTracks(0)
         for i=0, track_count-1 do
           local cur_track = reaper.GetTrack(0,i)
           local sel_track = reaper.IsTrackSelected(cur_track)
               if sel_track == true then
               reaper.SetTrackColor(cur_track, ConvertedRGB)
               end
         end
      reaper.Undo_EndBlock("Color selected track(s)", -1)
    end
    
    function ApplyColor_Items()
      reaper.Undo_BeginBlock()     
         local item_count =  reaper.CountSelectedMediaItems(0)
         if item_count > 0 then      
             for i=0, item_count-1 do 
             local cur_item =   reaper.GetSelectedMediaItem(0,i)      
             reaper.SetMediaItemInfo_Value(cur_item,"I_CUSTOMCOLOR",ConvertedRGB|0x1000000)
             reaper.UpdateItemInProject(cur_item)
             end     
         end
      reaper.Undo_EndBlock("Color selected item(s)", -1)
    end
    
    function ApplyColor_Takes()
      reaper.Undo_BeginBlock()     
        local item_count =  reaper.CountSelectedMediaItems(0)
        if item_count > 0 then      
            for i=0, item_count-1 do 
            local cur_item =   reaper.GetSelectedMediaItem(0,i)
            local active_take =  reaper.GetActiveTake(cur_item)
              if active_take ~= nil then
                reaper.SetMediaItemTakeInfo_Value(active_take,"I_CUSTOMCOLOR",ConvertedRGB|0x1000000)
              else
                reaper.SetMediaItemInfo_Value(cur_item,"I_CUSTOMCOLOR",ConvertedRGB|0x1000000)
              end
            reaper.UpdateItemInProject(cur_item)   
            end     
        end
      reaper.Undo_EndBlock("Color active take of selected item(s)", -1)
    end
    
    function Palette_info_GUI()
      if loaded_file == "Default" then palette_display = "Default"
      elseif loaded_file == last_palette_on_exit then palette_display = "unsaved palette"
      else
        palette_display = string.gsub(loaded_file:match("^.+"..separ.."(.+)$"), ".txt", "")
      end
      gfx.set(1,1,1,0.7)
      gfx.x = GUI_xstart +21 -- Palette info text x and y
      gfx.y = GUI_ystart +562 -compact
      gfx.drawstr(palette_display)
    end
    
    function SaveAsPalette()
      local name = tostring("")..","..tostring("")
      local retval, newfile = reaper.GetUserInputs("Save as:", 1, "Save New Palette", name)          
        if retval == true then
          local newpalette_path = UserPalettes_path .. newfile .. ".txt"             
          SaveColorFile(newpalette_path)
          LoadColorFile(newpalette_path)
        end
    end  

  function SaveAsSWSPalette()
      local name = tostring("")..","..tostring("")
      local retval, newfile = reaper.GetUserInputs("Save as SWS:", 1, "Save New SWS Palette", name)          
        if retval == true then
          local newpalette_path = UserPalettes_path .. newfile .. ".SWSColor"             
          SaveSWSColorFile(newpalette_path)
        end
    end 
  
    function SavePalette_INIT()
        local SavePalette_x = GUI_centerx -1
        local SavePalette_y = GUI_centery + 246 -compact
        local SavePalette_w = 65
        local help = "RClick to Save as"
        SavePalette_btn = Button(SavePalette_x, SavePalette_y, SavePalette_w,22,2,0,0,"Save",help,0,1)
        SavePalette_btn :set_label_color(0.8,0.8,0.8,1)
        
        SavePalette_btn.onClick = function ()
          if loaded_file == last_palette_on_exit or loaded_file == "Default" or string.match(loaded_file, "-sws$") == "-sws" then 
            SaveAsPalette() else
          local ok = reaper.ShowMessageBox("This will overwrite the current palette. Are you sure?", "", 1 )
            if ok == 1 then SaveColorFile(loaded_file)
            else
              reaper.ShowMessageBox("Action cancelled by user.".."\n".."If you want to save with a different name then right-click Save", "", 0)
            end   
          end
        end
        SavePalette_btn.onRClick = function ()
          SaveAsPalette()
        end
    end
    
    function GiveFocusBack()
      if gfx.mouse_x >= 0 and gfx.mouse_x <= gfx.w and gfx.mouse_y >= -10 and gfx.mouse_y <= gfx.h then
        if gfx.mouse_cap ~= (0 or 4 or 8 or 12 or 16 or 24 or 28) then
          if what == "tracks" then reaper.SetCursorContext(0)
          elseif what == "items" or what == "takes" then reaper.SetCursorContext(1)
          end
        end
      end 
    end
    
    function Luminance(change)
      local hue, sat, lum = rgbToHsl(red/255, green/255, blue/255)
      lum = lum + change
      local r, g, b = hslToRgb(hue, sat, lum)
      if r<=0 then r = 0 end ; if g<=0 then g = 0 end ; if b<=0 then b = 0 end
      if r>=1 then r = 1 end ; if g>=1 then g = 1 end ; if b>=1 then b = 1 end
      slider_btn_r.val, slider_btn_g.val, slider_btn_b.val = r, g, b
    end
    
    function TintShade(tintorshade)
        if what == "tracks" then
          local seltracks = reaper.CountSelectedTracks(0)
          if seltracks > 2 then
                local firsttrack = reaper.GetSelectedTrack(0, 0)
                local firstcolor = reaper.GetMediaTrackInfo_Value(firsttrack, "I_CUSTOMCOLOR")
                if firstcolor == 0 or nil then
                  reaper.MB("The first selected track must already have a custom color in order to make a gradient!", "Error!", 0 )
                else
                  reaper.Undo_BeginBlock()                    
                  local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor)
                  local firstcolor_h, firstcolor_s, firstcolor_l = rgbToHsl(firstcolor_r/255, firstcolor_g/255, firstcolor_b/255)
                  if math.abs(firstcolor_l-tintorshade) < 0.1 then
                    reaper.MB("The first selected track should have a darker color in order to make tint gradient!", "Error!", 0 )
                  else
                    local lastcolor_r, lastcolor_g, lastcolor_b = hslToRgb(firstcolor_h, firstcolor_s, tintorshade)
                    local r_step = (lastcolor_r*255-firstcolor_r)/(seltracks-1)
                    local g_step = (lastcolor_g*255-firstcolor_g)/(seltracks-1)
                    local b_step = (lastcolor_b*255-firstcolor_b)/(seltracks-1)
                    for i=1,seltracks-1 do
                      local value_r,value_g,value_b = math.floor(0.5+firstcolor_r+r_step*i), math.floor(0.5+firstcolor_g+g_step*i), math.floor(0.5+firstcolor_b+b_step*i)
                      local track = reaper.GetSelectedTrack(0, i)
                      reaper.SetTrackColor(track, reaper.ColorToNative(value_r, value_g, value_b))
                    end
                    reaper.Undo_EndBlock("Color selected track(s) with gradient tint color", -1)
                  end
                end
          else
               reaper.MB( "Please select at least three tracks!", "Cannot create gradient colors!", 0 )
          end
        elseif what == "items" then
          local selitems = reaper.CountSelectedMediaItems(0)
          if selitems > 2 then
              local item = reaper.GetSelectedMediaItem( 0, 0 )
              local firstcolor = reaper.GetDisplayedMediaItemColor(item)
              if firstcolor == 0 or nil then
                reaper.MB("The first selected item must already have a custom color in order to make a gradient!", "Error!", 0 )
              else
                reaper.Undo_BeginBlock()
                local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor|0x1000000)
                local firstcolor_h, firstcolor_s, firstcolor_l = rgbToHsl(firstcolor_r/255, firstcolor_g/255, firstcolor_b/255)
                if math.abs(firstcolor_l-tintorshade) < 0.1 then
                  reaper.MB("The first selected track should have a darker color in order to make tint gradient!", "Error!", 0 )
                else
                  local lastcolor_r, lastcolor_g, lastcolor_b = hslToRgb(firstcolor_h, firstcolor_s, tintorshade)
                  local r_step = (lastcolor_r*255-firstcolor_r)/(selitems-1)
                  local g_step = (lastcolor_g*255-firstcolor_g)/(selitems-1)
                  local b_step = (lastcolor_b*255-firstcolor_b)/(selitems-1)
                  for i=1,selitems-1 do
                    local value_r,value_g,value_b = math.floor(0.5+firstcolor_r+r_step*i), math.floor(0.5+firstcolor_g+g_step*i), math.floor(0.5+firstcolor_b+b_step*i)
                    local item = reaper.GetSelectedMediaItem(0, i)
                    local color = reaper.ColorToNative(value_r, value_g, value_b)|0x1000000
                    local active_take = reaper.GetActiveTake(item)
                    if active_take ~= nil then
                      reaper.Main_OnCommand(41333, 0) -- Take: Set active take to default color
                    end
                    reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
                    reaper.UpdateArrange()
                  end
                  reaper.Undo_EndBlock("Color selected item(s) with gradient colors", -1)
                end
              end
          else
               reaper.MB( "Please select at least three items!", "Cannot create gradient colors!", 0 )
          end
        elseif what == "takes" then
          local selitems = reaper.CountSelectedMediaItems(0)
          if selitems < 1 then
            reaper.MB("Not any items are selected!", "Error!", 0 )
          else
            for i=0,selitems-1 do
              local item = reaper.GetSelectedMediaItem(0, i)
              local take_cnt = reaper.CountTakes(item)
              if take_cnt < 3 then
                if found == 1 then found = 1 else found = 0 end
              else
                found = 1
                local take = reaper.GetMediaItemTake( item, 0) -- get first take
                local firstcolor = reaper.GetDisplayedMediaItemColor2( item, take)
                local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor|0x1000000)
                local firstcolor_h, firstcolor_s, firstcolor_l = rgbToHsl(firstcolor_r/255, firstcolor_g/255, firstcolor_b/255)
                local lastcolor_r, lastcolor_g, lastcolor_b = hslToRgb(firstcolor_h, firstcolor_s, tintorshade)
                local r_step = (lastcolor_r*255-firstcolor_r)/(take_cnt-1)
                local g_step = (lastcolor_g*255-firstcolor_g)/(take_cnt-1)
                local b_step = (lastcolor_b*255-firstcolor_b)/(take_cnt-1)
                reaper.Undo_BeginBlock()
                for j=1, take_cnt-1 do
                  local take = reaper.GetMediaItemTake( item, j)
                  local value_r,value_g,value_b = math.floor(firstcolor_r+r_step*j), math.floor(firstcolor_g+g_step*j), math.floor(firstcolor_b+b_step*j)
                  local color = reaper.ColorToNative(value_r, value_g, value_b)|0x1000000
                  reaper.SetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR", color|0x1000000)
                  reaper.UpdateItemInProject( item )
                  reaper.UpdateArrange()
                end
                reaper.Undo_EndBlock("Color takes of selected item(s) with tint gradient colors", -1)
              end
            end
            if found == 0 then
              reaper.MB( "Not any item with more than two takes was selected!", "Cannot create gradient colors!", 0 )
            end
          end
          found = nil
        end
    end
    
    
    function Darker_INIT()
        local Darker_x = GUI_centerx -64
        local Darker_y = GUI_centery - 85
        local Darker_w = 56
        local help = "Rclick->Black | Ctrl->Shades"
        Darker_btn = Button(Darker_x, Darker_y, Darker_w,22,2,0,0,"Darker",help,0,1)
        Darker_btn :set_label_color(0.8,0.8,0.8,1)
        Darker_btn.onClick = function ()
          Luminance(-0.033)
        end
        Darker_btn.onRClick = function ()
          slider_btn_r.val, slider_btn_g.val, slider_btn_b.val = 0, 0, 0
        end
        Darker_btn.onCtrlClick = function ()
          TintShade(0.08)
        end
    end
    
    function Brighter_INIT()
        local Brighter_x = GUI_centerx -1
        local Brighter_y = GUI_centery - 85
        local Brighter_w = 56
        local help = "Rclick->White | Ctrl->Tints"
        Brighter_btn = Button(Brighter_x, Brighter_y, Brighter_w,22,2,0,0,"Brighter",help,0,1)
        Brighter_btn :set_label_color(0.8,0.8,0.8,1)
        Brighter_btn.onClick = function ()
          Luminance(0.033)
        end
        Brighter_btn.onRClick = function ()
          slider_btn_r.val, slider_btn_g.val, slider_btn_b.val = 1, 1, 1
        end
        Brighter_btn.onCtrlClick = function ()
          TintShade(0.92)
        end
    end
    
    function OpenSWS_INIT()
        local OpenSWS_x = GUI_centerx -4
        local OpenSWS_y = GUI_centery - 192
        local OpenSWS_w = 72
        local help = "SWS Color Management"
        OpenSWS_btn = Button(OpenSWS_x, OpenSWS_y, OpenSWS_w,22,2,0,0,"SWS Colors",help,0,1)
        OpenSWS_btn :set_label_color(0.8,0.8,0.8,1)
        OpenSWS_btn.onClick = function ()
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWSCOLORWND"), 0) -- SWS: Open color management window
        end
        OpenSWS_btn.onRClick = function ()
        end
    end
    
    function LoadSWS_INIT()
        local LoadSWS_x = GUI_centerx -77
        local LoadSWS_y = GUI_centery - 192
        local LoadSWS_w = 66
        local help = "LClick->Load | RClick->Save"
        LoadSWS_btn = Button(LoadSWS_x, LoadSWS_y, LoadSWS_w,22,2,0,0,"LD/SV SWS",help,0,1)
        LoadSWS_btn :set_label_color(0.8,0.8,0.8,1)
        LoadSWS_btn.onClick = function ()
          LoadSWSColors()
        end
        LoadSWS_btn.onRClick = function ()
          SaveAsSWSPalette()
        end
    end

    
    function RandomColors_INIT()
      local RandomColors_x = GUI_centerx -72
      local RandomColors_y = GUI_centery + 128 - compact
      local RandomColors_w = 65
      local help = "Select colors randomly"
      RandomColors_btn = Button(RandomColors_x, RandomColors_y, RandomColors_w,22,2,0,0,"Random",help,0,1)
      RandomColors_btn :set_label_color(0.8,0.8,0.8,1)
      
      RandomColors_btn.onClick = function ()
        local list = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}
        local list_size = 24
        if what == "tracks" then
            local seltracks = reaper.CountSelectedTracks(0)
            reaper.Undo_BeginBlock()
            for i=0, seltracks-1 do
              if list_size == 0 then
                list = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}
                list_size = 24
              end      
              local k = math.random(1, list_size)
              local colorbox = list[k]
              table.remove(list, k)
              list_size = list_size-1
              Convert_RGB(ColorBoxes[colorbox].r +0.2, ColorBoxes[colorbox].g +0.2, ColorBoxes[colorbox].b +0.2, 1)           
              local cur_track = reaper.GetSelectedTrack(0,i)
              local sel_track = reaper.IsTrackSelected(cur_track)
                if sel_track == true then
                  reaper.SetTrackColor(cur_track, ConvertedRGB)
                end
            end
            reaper.Undo_EndBlock("Set random color selection for selected track(s)", -1)
            list, list_size = nil, nil            
        elseif what == "items" then
            local seltitems = reaper.CountSelectedMediaItems(0)
            if seltitems > 0 then
            reaper.Undo_BeginBlock()
              for i=0, seltitems-1 do
                if list_size == 0 then
                  list = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}
                  list_size = 24
                end      
                local k = math.random(1, list_size)
                local colorbox = list[k]
                table.remove(list, k)
                list_size = list_size-1
                Convert_RGB(ColorBoxes[colorbox].r +0.2, ColorBoxes[colorbox].g +0.2, ColorBoxes[colorbox].b +0.2, 1)           
                local cur_item = reaper.GetSelectedMediaItem(0,i)
                reaper.SetMediaItemInfo_Value(cur_item, "I_CUSTOMCOLOR", ConvertedRGB|0x1000000)
                reaper.UpdateItemInProject( cur_item )
              end         
            reaper.Undo_EndBlock("Set random color selection for selected item(s)", -1)
            end
        elseif what == "takes" then
          local seltitems = reaper.CountSelectedMediaItems(0)
          if seltitems > 0 then
            reaper.Undo_BeginBlock()
            for i=0, seltitems-1 do
              local cur_item = reaper.GetSelectedMediaItem(0,i)
              local take_cnt = reaper.CountTakes(cur_item)
              if take_cnt == 0 then
                local k = math.random(1, list_size)
                local colorbox = list[k]
                table.remove(list, k)
                list_size = list_size-1
                Convert_RGB(ColorBoxes[colorbox].r +0.2, ColorBoxes[colorbox].g +0.2, ColorBoxes[colorbox].b +0.2, 1)
                reaper.SetMediaItemInfo_Value(cur_item, "I_CUSTOMCOLOR", ConvertedRGB|0x1000000)
                reaper.UpdateItemInProject(cur_item)
              else
                for j=0, take_cnt-1 do
                  if list_size == 0 then
                    list = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24}
                    list_size = 24
                  end      
                  local k = math.random(1, list_size)
                  local colorbox = list[k]
                  table.remove(list, k)
                  list_size = list_size-1
                  Convert_RGB(ColorBoxes[colorbox].r +0.2, ColorBoxes[colorbox].g +0.2, ColorBoxes[colorbox].b +0.2, 1)           
                  cur_take = reaper.GetMediaItemTake( cur_item, j)
                  reaper.SetMediaItemTakeInfo_Value(cur_take, "I_CUSTOMCOLOR", ConvertedRGB|0x1000000)
                  reaper.UpdateItemInProject(cur_item)
                end
              end
            end         
            reaper.Undo_EndBlock("Set random color selection for selected take(s)", -1)
          end
        end
      end
    end
    
    
    function GetColor_INIT()
       local GetColor_x = GUI_centerx -1
       local GetColor_y = GUI_centery + 128 - compact
       local GetColor_w = 65
       local help = "Lmb->Get sel.| Rmb->OS Set"
       GetColor_btn = Button(GetColor_x,GetColor_y,GetColor_w,22,2,0,0,"Get Color",help,0,1)
       GetColor_btn:set_label_color(0.8,0.8,0.8,1)                 
       GetColor_btn.onClick = function ()         
          if what == "tracks" then
            local seltracks = reaper.CountSelectedTracks(0)
            if seltracks > 0 then 
                 local track =  reaper.GetSelectedTrack( 0, 0 )
                 local color = reaper.GetMediaTrackInfo_Value( track, "I_CUSTOMCOLOR" )
                 if color ~= 0 then
                 R, G, B = reaper.ColorFromNative(color|0x1000000)
                 else R,G,B = 127,127,127
                 end
                 if mode == "rgb" or mode == "compact" then
                   slider_btn_r.val = R/255 
                   slider_btn_g.val = G/255
                   slider_btn_b.val = B/255
                 elseif mode == "hsl" then
                   local h, s, l = rgbToHsl(R/255, G/255, B/255)
                   slider_btn_h.val = h
                   slider_btn_s.val = s
                   slider_btn_l.val = l 
                   slider_btn_a.val = 1  
                 end
            end
          elseif what == "items" or what == "takes" then
            local selitems = reaper.CountSelectedMediaItems(0)
            if selitems > 0 then
                 local item =  reaper.GetSelectedMediaItem( 0, 0 )
                 local color = reaper.GetDisplayedMediaItemColor(item)
                 local R, G, B = reaper.ColorFromNative(color|0x1000000)
                 if color == 0 then R,G,B = 127,127,127 end
                 if mode == "rgb" or mode == "compact" then
                   slider_btn_r.val = R/255 
                   slider_btn_g.val = G/255
                   slider_btn_b.val = B/255
                 elseif mode == "hsl" then
                   local h, s, l = rgbToHsl(R/255, G/255, B/255)
                   slider_btn_h.val = h
                   slider_btn_s.val = s
                   slider_btn_l.val = l 
                   slider_btn_a.val = 1
                 end
            end
          end
       end
       GetColor_btn.onRClick = function ()
          local answer, color = reaper.GR_SelectColor()
          if answer ~= 0 then
            local R, G, B = reaper.ColorFromNative(color|0x1000000)
            if mode == "compact" or mode == "rgb" then
              slider_btn_r.val = R/255 
              slider_btn_g.val = G/255
              slider_btn_b.val = B/255
            elseif mode == "hsl" then
              local h, s, l = rgbToHsl (R/255, G/255, B/255)
              slider_btn_h.val = h
              slider_btn_s.val = s
              slider_btn_l.val = l 
              slider_btn_a.val = 1
            end
          end
       end 
    end
  
    function LoadSWSColors()
        local retval, file_name = reaper.GetUserFileNameForRead(reaper.GetResourcePath()..separ.."Colorset"..separ.."*.SWSColor", "Select .SWSColor file", ".SWSColor")
        if retval == true then
            if string.match(file_name, ".SWSColor$") ~= ".SWSColor" then
                reaper.ShowMessageBox("Please, choose a file with a .SWSColor extrension!", "Error!", 0)
            else
                local file = io.open(file_name)
                file:seek("set", "15")
                swscolors = {}
                for loadcolor = 1,18 do 
                  swscolors [loadcolor] = tonumber(string.match(file:read("*l"), '%d+$'))
                  local value_r, value_g, value_b = reaper.ColorFromNative(swscolors [loadcolor])               
                  ColorBoxes[loadcolor]:set_color(value_r/255-0.2, value_g/255-0.2, value_b/255-0.2, 1)
                end
                --Create Gradients for the rest of the colorboxes
                local r1,g1,b1 = reaper.ColorFromNative(tonumber(swscolors[17]))
                local r2,g2,b2 = reaper.ColorFromNative(tonumber(swscolors[18]))       
                local r_step = (r2-r1)/7
                local g_step = (g2-g1)/7
                local b_step = (b2-b1)/7
                for i=1,7 do
                  local value_r,value_g,value_b = r1+r_step*i, g1+g_step*i, b1+b_step*i
                  ColorBoxes[i+17]:set_color(value_r/255-0.2, value_g/255-0.2, value_b/255-0.2, 1)  
                end
                file:close()
                loaded_file = tostring(string.gsub(file_name, ".SWSColor", "").." -sws")
            end
        end   
    end
  
    function LoadPalette_INIT()
        local LoadPalette_x = GUI_centerx -72
        local LoadPalette_y = GUI_centery + 246 -compact
        local LoadPalette_w = 65
        local help = "RClick to load default"
        LoadPalette_btn = Button(LoadPalette_x, LoadPalette_y, LoadPalette_w,22,2,0,0,"Load",help,0,1)
        LoadPalette_btn :set_label_color(0.8,0.8,0.8,1)
        LoadPalette_btn.onRClick = function ()
         local answer = reaper.MB("The default palette will be loaded. Are you sure?", "Load default palette", 1 )
          if answer == 1 then Create_Default() end
        end
         --- Load palette from file ---
        LoadPalette_btn.onClick = function ()
            local retval, filetxt = reaper.GetUserFileNameForRead(UserPalettes_path..separ.."*.txt", "Select file", ".txt")
              if retval == true then
                if filetxt == last_palette_on_exit then 
                  LoadColorFile(last_palette_on_exit)
                  palette_display = "unsaved palette"
                  reaper.ShowMessageBox("This is the last palette on exit (a backup). Please, save it with a new name.", "Advice:", 0)
                  local retval, newfile = reaper.GetUserInputs("Save as:", 1, "Save New Palette", "")          
                      if retval == true then
                          local newpalette_path = UserPalettes_path .. newfile .. ".txt"             
                          SaveColorFile(newpalette_path)
                          LoadColorFile(newpalette_path)
                      end
                elseif string.match(filetxt, ".txt$") ~= ".txt" then
                  reaper.ShowMessageBox("Please, choose a file with a .txt extension!\nIf you wanted to load a SWSColor file, then use the dedicated Load SWS button.", "Invalid file!", 0)
                else
                  LoadColorFile(filetxt)
                end
              end
        end   
    end
    
    function ColorTracks_INIT()
        local ColorTracks_x = GUI_centerx -78
        local ColorTracks_y = GUI_centery + 292 -compact
        local ColorTracks_w = 46
        local help = "Click to exit Takes mode"
        ColorTracks_btn = Button(ColorTracks_x, ColorTracks_y, ColorTracks_w,22,2,0,0,"Tracks",help,0,1)
        ColorTracks_btn :set_label_color(0.8,0.8,0.8,1)                
        ColorTracks_btn.onClick = function ()
           what = "tracks"
           SetSelected()  
        end   
    end
    
    function ColorItems_INIT()
        local ColorItems_x = GUI_centerx -28
        local ColorItems_y = GUI_centery + 292 -compact
        local ColorItems_w = 46
        local help = "Click to exit Takes mode"
        ColorItems_btn = Button(ColorItems_x, ColorItems_y, ColorItems_w,22,2,0,0,"Items",help,0,1)
        ColorItems_btn :set_label_color(0.8,0.8,0.8,1)
        ColorItems_btn.onClick = function ()
           what = "items"
           SetSelected()         
        end   
    end
    
    function ColorTakes_INIT()
        local ColorTakes_x = GUI_centerx +22
        local ColorTakes_y = GUI_centery + 292 -compact
        local ColorTakes_w = 46
        local help = "Take mode - manual exit"
        ColorTakes_btn = Button(ColorTakes_x, ColorTakes_y, ColorTakes_w,22,2,0,0,"Takes",help,0,1)
        ColorTakes_btn :set_label_color(0.8,0.8,0.8,1)      
        ColorTakes_btn.onClick = function ()
           what = "takes"
           SetSelected()
        end     
    end
    
    function SetSelected()
       if what == "tracks" then
                  ColorTracks_btn:set_color(1,0.05,0,0.3)
                  ColorItems_btn:set_color(0.5,0.5,0.5,0.28)
                  ColorTakes_btn:set_color(0.5,0.5,0.5,0.28)
       elseif what == "items" then
                  ColorTracks_btn:set_color(0.5,0.5,0.5,0.28)
                  ColorItems_btn:set_color(1,0.05,0,0.3)
                  ColorTakes_btn:set_color(0.5,0.5,0.5,0.28)
       else -- takes
                  ColorTracks_btn:set_color(0.5,0.5,0.5,0.28) 
                  ColorItems_btn:set_color(0.5,0.5,0.5,0.28) 
                  ColorTakes_btn:set_color(0.05,1,0,0.3)
       end
    end 
    
    function ShowInfo()
        local ShowInfo_x = GUI_centerx + 50
        local ShowInfo_y = GUI_centery -315
        local help = "lmb->Info | Rmb->Manual"
        ShowInfo_btn = Button(ShowInfo_x, ShowInfo_y, 15,15,2,0,0,"?",help,0,1)
        ShowInfo_btn:set_color(0.4, 0.4, 0.4, 0.25)
        ShowInfo_btn:set_label_color(0.85,0.85,0.85,1)
        ShowInfo_btn.onClick = function ()
            local Info = [[
                                  --- ReaNoir track/item/take coloring utility ---
                                                        script by amagalma
                                      
- part of the code is modification of codes by Spacemen Tree, spk77 & Em. Oga
- special thanks to them and to X-Raym, cfillion and Lokasenna for their help!
- thanks to Gianfini for his addition to export SWS Colorset files

                                                         ^^ Features: ^^

- Palette of 24 Color Boxes + 1 Temporary Color Box (the big color box on top)
- Click any of the color boxes to Color Tracks, Items or Takes and set it as
  Temporary Color
- Tracks/Items Mode is set automatically according to what was lastly clicked.
  The Takes mode is set and exited manually by the user
- Temporary Color can be adjusted by the Sliders and saved in to any of the
  24 Color Boxes
- Hex name of Temporary Color is shown and can be copied to clipboard in a
  SWS Auto Color/Icons ready format
- A color can be entered in the Temporary Color Box by entering its hex code too
- ReaNoir can create Gradient Colors between existing track/item/take colors
  and any of the Color Boxes (including the Temporary & Darker/Brighter boxes)
- Ability to apply a random color selection to tracks/items/takes. No color is
  repeated before all 24 have been used
- Two available Slider Modes: RGB and HSL
- Two available script modes: RGB/HSL and Compact (No Sliders). The mode is
  set inside the script in the "MODE OF OPERATION" section box
- When in Compact (No Sliders) Mode, Right-click Get Color Button to set
  Temporary Color Box's color
- Palettes can be loaded and saved as txt files. They reside in ReaNoir folder in
  the same path as the script
- Default palette is hard-coded into the script
- Current palette is automatically saved as last_palette_on_exit.txt as a backup
  each time the script exits
- SWSColor files can be imported as ReaNoir palettes using the LD/SV SWS
  button.
  The 16 colors get loaded to the first 16 Color Boxes and the rest 8
  Color Boxes get filled with gradient colors from the two gradient colors specified
  in the SWSColor file  
- ReaNoir palettes can be exported as SWSColor palettes by Right Clicking the 
  LD/SV SWS button. The first 16 Color Boxes will be written in SWS format and
  the two gradient colors will be taken from Color Box 17 (gradient start) and 
  Color Box 24 (gradient end)
- ReaNoir can be docked Left/Right or Float and remembers its position and
  dock state, and last Slider Mode (RGB or HSL)  
- 3 available click modes: left click, right click and ctrl-left click
- Information is displayed on top of ReaNoir when hovering mouse over
  buttons/sliders]]
            reaper.MB(Info, "Information", 0)
        end
        ShowInfo_btn.onRClick = function ()
        local Info = [[
FROM TOP TO BOTTOM        
        
Docker Buttons (upper left corner) ----------------------------------------------
- Click to dock Left/Right or Float

Temporary Color Box (big color box on top) -----------------------------------
- Left-click to apply color
- Right-click to apply default color (remove custom color)
- Ctrl-click to make gradient colors from first selected track/item/take color
  to Temporary Color

Hex Display ------------------------------------------------------------------
- Left-click Hex name to enter a Hex color code manually (formats: 123456,
  #123456, # 123456 & 0x123456)
- Right-click to copy Hex code to clipboard

LD/SV SWS Button ------------------------------------------------------------
- Left-click to load SWS Colorset palette
- Right-click to save palette as .SWSColor file

SWS Colors Button: Open SWS Color Management --------------------------

Sliders Area -------------------------------------------------------------------
- Left-click to change Temporary Color
- Right-click to toggle between RGB-HSL modes

Darker/Brighter buttons (in RGB mode) --------------------------------------
- Left-click to darken/brighten Temporary Color
- Right-click to set Temporary Color to Black/White
- Ctrl-click to make gradient tinted/shaded colors from first selected
  track/item/take color

24 Color Boxes ---------------------------------------------------------------
- Left-click to apply color
- Right-click to save Temporary Color into right-clicked color box
- Ctrl-click to make gradient colors from first selected track/item/take
  color to Color Box color

Random Color --------------------------------------------------------------
- Apply random color selection from the palette

Get Color --------------------------------------------------------------------
- Left-click to get first selected track/item/take color and load it to
  Temporary Color Box
- Right-click to define Temporary Color Box's color with OS utility

Palette box: Shows loaded palette --------------------------------------------

Load Button ------------------------------------------------------------------
- Left-click to load ReaNoir palette
- Right-click to load default palette

Save Button -------------------------------------------------------------------
- Left-click to Save
- Right-click to Save As

Tracks/Items/Takes: shows to what colors are applied ------------------------  
]]
            reaper.MB(Info, "Information", 0)
        end
        
    end
                       
    function RGBsquare_GUI()
        local RGBsquare_x = GUI_centerx -48
        local RGBsquare_y = GUI_centery -312
        gfx.set(0,0,0,1)
        gfx.rect(RGBsquare_x + 6,RGBsquare_y + 6,84,74)    
    end
        
    function RGBsquare_INIT()
        local RGBsquare_initx = GUI_centerx -48
        local RGBsquare_inity = GUI_centery -312
        local help = "Rmb->Default | Ctrl->Gradient"             
        RGBsquare_btn = Button(RGBsquare_initx, RGBsquare_inity, 80,70,2,0,0,"",help,0,1)        
        RGBsquare_btn.onClick = function ()
            Convert_RGB(slider_btn_r.val, slider_btn_g.val,slider_btn_b.val, slider_btn_a.val)          
            if what == "tracks" then ApplyColor_Tracks()
            elseif what == "items" then ApplyColor_Items()
            else ApplyColor_Takes()
            end
        end     
        RGBsquare_btn.onRClick = function ()
          if what == "tracks" then reaper.Main_OnCommand(40359, 0) -- Track: Set to default color
          elseif what == "items" then
            reaper.Main_OnCommand(40707, 0) -- Item: Set to default color
            reaper.Main_OnCommand(41337, 0) -- Take: Set all takes of selected items to default color
          else  -- takes
          local item_count =  reaper.CountSelectedMediaItems(0)
              if item_count > 0 then      
                for i=0, item_count-1 do 
                  local cur_item =   reaper.GetSelectedMediaItem(0,i)
                  local active_take =  reaper.GetActiveTake(cur_item)
                    if active_take ~= nil then
                      reaper.Main_OnCommand(41333, 0) -- Take: Set active take to default color
                    else
                      reaper.Main_OnCommand(40707, 0) -- Item: Set to default color
                    end
                      reaper.UpdateItemInProject(cur_item)   
                end     
              end
          end  
        end

        RGBsquare_btn.onCtrlClick = function ()
          if what == "tracks" then
            local seltracks = reaper.CountSelectedTracks(0)
            if seltracks > 2 then
                  local firsttrack = reaper.GetSelectedTrack(0, 0)
                  local firstcolor = reaper.GetMediaTrackInfo_Value(firsttrack, "I_CUSTOMCOLOR")
                  if firstcolor == 0 or nil then
                    reaper.MB("The first selected track must already have a custom color in order to make a gradient!", "Error!", 0 )
                  else
                    reaper.Undo_BeginBlock()
                    Convert_RGB(slider_btn_r.val, slider_btn_g.val,slider_btn_b.val, slider_btn_a.val)                      
                    local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor)
                    local r_step = (red-firstcolor_r)/(seltracks-1)
                    local g_step = (green-firstcolor_g)/(seltracks-1)
                    local b_step = (blue-firstcolor_b)/(seltracks-1)
                    for i=1,seltracks-1 do
                      local value_r,value_g,value_b = math.floor(0.5+firstcolor_r+r_step*i), math.floor(0.5+firstcolor_g+g_step*i), math.floor(0.5+firstcolor_b+b_step*i)
                      local track = reaper.GetSelectedTrack(0, i)
                      reaper.SetTrackColor(track, reaper.ColorToNative(value_r, value_g, value_b))
                    end
                    reaper.Undo_EndBlock("Color selected track(s) with gradient colors", -1)
                  end
            else
                 reaper.MB( "Please select at least three tracks!", "Cannot create gradient colors!", 0 )
            end
          elseif what == "items" then
            local selitems = reaper.CountSelectedMediaItems(0)
            if selitems > 2 then
                 local item = reaper.GetSelectedMediaItem( 0, 0 )
                 local firstcolor = reaper.GetDisplayedMediaItemColor(item)
                 if firstcolor == 0 or nil then
                   reaper.MB("The first selected item must already have a custom color in order to make a gradient!", "Error!", 0 )
                 else
                   reaper.Undo_BeginBlock()
                   Convert_RGB(slider_btn_r.val, slider_btn_g.val,slider_btn_b.val, slider_btn_a.val)
                   local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor|0x1000000)
                   local r_step = (red-firstcolor_r)/(selitems-1)
                   local g_step = (green-firstcolor_g)/(selitems-1)
                   local b_step = (blue-firstcolor_b)/(selitems-1)
                   for i=1,selitems-1 do
                     local value_r,value_g,value_b = math.floor(0.5+firstcolor_r+r_step*i), math.floor(0.5+firstcolor_g+g_step*i), math.floor(0.5+firstcolor_b+b_step*i)
                     local item = reaper.GetSelectedMediaItem(0, i)
                     local color = reaper.ColorToNative(value_r, value_g, value_b)|0x1000000
                     local active_take = reaper.GetActiveTake(item)
                     if active_take ~= nil then
                      reaper.Main_OnCommand(41333, 0) -- Take: Set active take to default color
                     end
                     reaper.SetMediaItemInfo_Value(item, "I_CUSTOMCOLOR", color)
                     reaper.UpdateItemInProject( item )
                   end
                   reaper.Undo_EndBlock("Color selected item(s) with gradient colors", -1)
                 end
            else
                 reaper.MB( "Please select at least three items!", "Cannot create gradient colors!", 0 )
            end
          elseif what == "takes" then
            local selitems = reaper.CountSelectedMediaItems(0)
            if selitems < 1 then
              reaper.MB("Not any items are selected!", "Error!", 0 )
            else
              for i=0,selitems-1 do
                local item = reaper.GetSelectedMediaItem(0, i)
                local take_cnt = reaper.CountTakes(item)
                if take_cnt < 3 then
                  if found == 1 then found = 1 else found = 0 end
                else
                  found = 1
                end
              end
              if found == 1 then
                reaper.Undo_BeginBlock()
                for i=0,selitems-1 do
                  local item = reaper.GetSelectedMediaItem(0, i)
                  local take_cnt = reaper.CountTakes(item)
                  if take_cnt > 2 then
                    local take = reaper.GetMediaItemTake( item, 0) -- get first take
                    local firstcolor = reaper.GetDisplayedMediaItemColor2( item, take)
                    Convert_RGB(slider_btn_r.val, slider_btn_g.val,slider_btn_b.val, slider_btn_a.val)
                    local firstcolor_r, firstcolor_g, firstcolor_b = reaper.ColorFromNative(firstcolor|0x1000000)
                    local r_step = (red-firstcolor_r)/(take_cnt-1)
                    local g_step = (green-firstcolor_g)/(take_cnt-1)
                    local b_step = (blue-firstcolor_b)/(take_cnt-1)
                    for j=1, take_cnt-1 do
                      local take = reaper.GetMediaItemTake( item, j)
                      local value_r,value_g,value_b = math.floor(firstcolor_r+r_step*j), math.floor(firstcolor_g+g_step*j), math.floor(firstcolor_b+b_step*j)
                      local color = reaper.ColorToNative(value_r, value_g, value_b)|0x1000000
                      reaper.SetMediaItemTakeInfo_Value(take, "I_CUSTOMCOLOR", color|0x1000000)
                      reaper.UpdateItemInProject( item )
                    end
                  end
                end
                reaper.Undo_EndBlock("Color selected take(s) with gradient colors", -1)
              elseif found == 0 then
                reaper.MB( "Not any item with more than two takes was selected!", "Cannot create gradient colors!", 0 )
              end
            end
            found = nil
          end
        end

    end

    function Sliders_GUI()
        local Sliders_x = GUI_centerx -65
        local Sliders_y = GUI_centery -155
        gfx.set(0,0,0,1)
        gfx.rect(Sliders_x, Sliders_y - 1,121,17,0)
        gfx.rect(Sliders_x, Sliders_y - 1,20,17,0)
        gfx.rect(Sliders_x, Sliders_y + 19,121,17,0)
        gfx.rect(Sliders_x, Sliders_y + 19,20,17,0)
        gfx.rect(Sliders_x, Sliders_y + 39,121,17,0)
        gfx.rect(Sliders_x, Sliders_y + 39,20,17,0)
        if mode == "hsl" then
          local r, g, b = hslToRgb(slider_btn_h.val, slider_btn_s.val, slider_btn_l.val)
          slider_btn_r.val, slider_btn_g.val, slider_btn_b.val = r, g, b
        end
    end

    function Sliders_INIT()
        local Sliders_initx = GUI_centerx -45
        local Sliders_inity = GUI_centery + (50/2)*-6.2
        local help = "RClick to change to HSL"
        slider_btn_r = Slider(Sliders_initx, Sliders_inity, 100, 15, 0.39, 0, 1, "R",help, 1, 0, 0)
        slider_btn_g = Slider(Sliders_initx, Sliders_inity + 20, 100, 15, 0.39, 0, 1, "G",help, 0, 1, 0)
        slider_btn_b = Slider(Sliders_initx, Sliders_inity + 40, 100, 15, 0.39, 0, 1, "B",help, 0, 0, 1)
        slider_btn_a = Slider(Sliders_initx, Sliders_inity + 60, 100, 15, 1, 0, 1, "A","", 0.6, 0.1, 0.5)                         
        if mode == "hsl" then
          local help = "RClick to change to RGB"
          slider_btn_h = Slider(Sliders_initx, Sliders_inity, 100, 15, 0, 0, 1, "H",help, 0.8, 0, 1)
          slider_btn_s = Slider(Sliders_initx, Sliders_inity + 20, 100, 15, 0, 0, 1, "S",help, 1, 0.05, 0.05)
          slider_btn_l = Slider(Sliders_initx, Sliders_inity + 40, 100, 15, 0.38824, 0, 1, "L",help, 1, 1, 1)
          slider_btn_a = Slider(Sliders_initx, Sliders_inity + 60, 100, 15, 1, 0, 1, "A","", 0.6, 0.1, 0.5) 
        end
    end

    function Change_Mode()
      if gfx.mouse_x >= 34 and gfx.mouse_x <= 152 and gfx.mouse_y >= 195 and gfx.mouse_y <= 250 and last_mouse_state == 0 and gfx.mouse_cap == 2 then
        if lastchange == nil or reaper.time_precise()-lastchange > 0.3 then
          if mode == "rgb" then
              mode = "hsl"
              local prev_red, prev_green, prev_blue = red/255, green/255, blue/255
              gfx.init("ReaNoir "..version, GUI_xend, GUI_yend, dock, lastx, lasty)
              Sliders_INIT()
              local h, s, l = rgbToHsl(prev_red, prev_green, prev_blue)
              slider_btn_h.val = h
              slider_btn_s.val = s
              slider_btn_l.val = l
              lastchange = reaper.time_precise()
          elseif mode == "hsl" then
              mode = "rgb"
              local prev_red, prev_green, prev_blue = red, green, blue
              gfx.init("ReaNoir "..version, GUI_xend, GUI_yend, dock, lastx, lasty)
              Sliders_INIT()
              slider_btn_r.val = prev_red/255
              slider_btn_g.val = prev_green/255
              slider_btn_b.val = prev_blue/255
              lastchange = reaper.time_precise()
          end
        end
      end
    end


    ---  rgbToHex is written by Marcelo Codget ---
    --- https://gist.github.com/marceloCodget/3862929 ---
    function rgbToHex(rgb)
        local hexadecimal = '# '
          for key, value in pairs(rgb) do
            local hex = ''
              while(value > 0)do
                local index = math.fmod(value, 16) + 1
                value = math.floor(value / 16)
                hex = string.sub('0123456789ABCDEF', index, index) .. hex
              end
              if(string.len(hex) == 0)then
                hex = '00'
                elseif(string.len(hex) == 1)then
                hex = '0' .. hex
              end
          hexadecimal = hexadecimal .. hex
          end
        return hexadecimal
    end

    function hex2rgb(hex)
          hex = hex:gsub("#","")
          hex2rgbR = tonumber("0x"..hex:sub(1,2))
          hex2rgbG = tonumber("0x"..hex:sub(3,4))
          hex2rgbB = tonumber("0x"..hex:sub(5,6))
    end

    function HEXinfo_GUI()
          local HEXinfo_x = GUI_centerx -68
          local HEXinfo_y = GUI_centery -187
          Convert_RGB(slider_btn_r.val, slider_btn_g.val,slider_btn_b.val, slider_btn_a.val)
          RGB_values = {red, green, blue}
          Hex_display = rgbToHex(RGB_values)
        -- Hex readout
          gfx.set(0.8,0.8,0.8,1)
          gfx.x = HEXinfo_x +38
          gfx.y = HEXinfo_y -50
          if not CopiedClipboard then
            gfx.drawstr("\n" .. Hex_display)
          else
            gfx.x = gfx.x - 13
            gfx.drawstr("\n copied to clip")
            CopiedClipboard = false
          end
        -- Hex Border
          gfx.set(0.4,0.4,0.4,1)
          gfx.rect(HEXinfo_x + 18, HEXinfo_y - 38,94,21,0)
    end

    function HEXinfo_INIT()
          local HEXinfo_x = GUI_centerx -68
          local HEXinfo_y = GUI_centery -187
          local Hex_label = tostring(Hex_display)
          local help = "Lmb->paste | Rmb->copy"
          HEXinfo_btn = Button(HEXinfo_x +20, HEXinfo_y-36, 90,17,2,0,0,"",help,0,1)
              HEXinfo_btn.onRClick = function ()
                local sws = string.gsub(Hex_display, "#%s", "0x")
                reaper.CF_SetClipboard( sws )
                CopiedClipboard = true
                --reaper.GetUserInputs("Copy SWS ready hex color code", 1, "Press Ctrl+C to copy the code", sws) 
              end
              HEXinfo_btn.onClick = function ()
                local sucess, answer = reaper.GetUserInputs("Hex color code", 1, "Paste color code here:", "")
                if sucess == true then
                  local ans, wer = answer:find("%x%x+")
                  if ans ~= nil and wer ~= nil and answer:len() <= 8 and wer-ans == 5 then
                    if string.match(answer, "# ") == "# " then answer = answer:sub(3)
                    elseif string.match(answer, "#") == "#" then answer = answer:gsub("#", "")
                    elseif string.match(answer, "0x") == "0x" then answer = answer:gsub("0x", "")
                    end
                    local R = tonumber("0x"..answer:sub(1,2))
                    local G = tonumber("0x"..answer:sub(3,4))
                    local B = tonumber("0x"..answer:sub(5,6))
                    if mode == "rgb" or mode == "compact" then
                      slider_btn_r.val = R/255
                      slider_btn_g.val = G/255
                      slider_btn_b.val = B/255
                    elseif mode == "hsl" then
                      local h, s, l = rgbToHsl(R/255, G/255, B/255)
                      slider_btn_h.val = h
                      slider_btn_s.val = s
                      slider_btn_l.val = l
                      slider_btn_a.val = 1
                    end
                  else
                      reaper.ShowMessageBox("This is not a valid number!", "Error!", 0)
                  end
                end
              end
    end



    function RGBToHex(red, green, blue, alpha)
    --https://forum.mtasa.com/viewtopic.php?f=160&t=76355
        if((red < 0 or red > 255 or green < 0 or green > 255
            or blue < 0 or blue > 255) or (alpha and (alpha < 0 or alpha > 255))) then
          return nil
        end
        if(alpha) then
          return string.format("%.2X%.2X%.2X%.2X", red,green,blue,alpha)
          else
          return string.format("%.2X%.2X%.2X", red,green,blue)
        end
    end

    function LoadColorFile(palette_file)
       if palette_file == nil then Create_Default() else
        loaded_file = palette_file end
      local palette = io.open(loaded_file,"r")  -- open colorset file for reading
        if palette == nil or string.match(tostring(palette), ".SWSColor$") == ".SWSColor" then 
           Create_Default()
        else
           for loadcolor = 1,24 do       -- read lines, start on line 1 and go up to 56 ( 14 groups x 4 rgba)   
                local palette_string = palette:read("*l")  -- thisfilestring gets file line value each time for loops     
                colors [loadcolor] = palette_string   -- value gets stored in table
                  if colors [loadcolor] == nil then colors [loadcolor] = "636363" end    
                hex2rgb(colors [loadcolor])
                  if hex2rgbR == nil or hex2rgbG == nil or hex2rgbB == nil then Create_Default()
                    reaper.ShowMessageBox( "This is not a valid palette file!\nIf you were trying to load a SWSColor file, please do it with the Load SWS Button!" , "Error!", 0 )
                  break
                  else
                    value_r = hex2rgbR/255-0.2
                    value_g = hex2rgbG/255-0.2
                    value_b = hex2rgbB/255-0.2
                    ColorBoxes [loadcolor]:set_color(value_r,value_g,value_b,1)
                  end
           end
        Write_Prefs()
        end
    end

    function Create_Default()
      for c, v in ipairs(defcolors) do
        value_r = tonumber("0x"..v:sub(1,2))/255-0.2
        value_g = tonumber("0x"..v:sub(3,4))/255-0.2
        value_b = tonumber("0x"..v:sub(5,6))/255-0.2
      ColorBoxes[c]:set_color(value_r,value_g,value_b,1)
      end
      loaded_file = "Default"
    end

    function SaveColorFile(palette_file)
        file = io.open(palette_file,"w+")
        ---- Collect data ----
        local HexColorList = {}
        local RtoHex = {}
        local GtoHex = {}
        local BtoHex = {}
        for save_hex = 1,24 do
            RtoHex [save_hex] = ColorBoxes [save_hex].r
            GtoHex [save_hex] = ColorBoxes [save_hex].g
            BtoHex [save_hex] = ColorBoxes [save_hex].b
            Convert_RGB(RtoHex [save_hex] +0.2,GtoHex [save_hex] +0.2,BtoHex [save_hex] +0.2)
            HexColorList[save_hex] = RGBToHex(red,green,blue)
              if HexColorList [save_hex] == nil then HexColorList [save_hex] = "636363" end
            ---- Write to file ----
            file:write(HexColorList [save_hex], "\n")
        end
        file:close()
    end

    ---- gianfini: added save SWS file ----
    function SaveSWSColorFile(palette_file)
        file = io.open(palette_file,"w+")
        ---- J Header -----
        file:write("[SWS Color]", "\n")

        ---- Collect data ----
        local IntegerColorList = {}
        local RtoInt = {}
        local GtoInt = {}
        local BtoInt = {}
        for box_pos = 1,16 do
            RtoInt [box_pos] = ColorBoxes [box_pos].r
            GtoInt [box_pos] = ColorBoxes [box_pos].g
            BtoInt [box_pos] = ColorBoxes [box_pos].b
            Convert_RGB(RtoInt [box_pos] +0.2,GtoInt [box_pos] +0.2,BtoInt [box_pos] +0.2)
            IntegerColorList[box_pos] = reaper.ColorToNative(red,green,blue)
            ---- Write to file ----
            file:write("custcolor")
            file:write(box_pos)
            file:write("=")
            file:write(IntegerColorList [box_pos], "\n")
        end
        ---- Write the two gradient files ----
        box_pos = 17
        RtoInt [box_pos] = ColorBoxes [box_pos].r
        GtoInt [box_pos] = ColorBoxes [box_pos].g
        BtoInt [box_pos] = ColorBoxes [box_pos].b
        Convert_RGB(RtoInt [box_pos] +0.2,GtoInt [box_pos] +0.2,BtoInt [box_pos] +0.2)
        IntegerColorList[box_pos] = reaper.ColorToNative(red,green,blue)
        file:write("gradientStart=")
        file:write(IntegerColorList [box_pos], "\n")
        box_pos = 24
        RtoInt [box_pos] = ColorBoxes [box_pos].r
        GtoInt [box_pos] = ColorBoxes [box_pos].g
        BtoInt [box_pos] = ColorBoxes [box_pos].b
        Convert_RGB(RtoInt [box_pos] +0.2,GtoInt [box_pos] +0.2,BtoInt [box_pos] +0.2)
        IntegerColorList[box_pos] = reaper.ColorToNative(red,green,blue)
        file:write("gradientEnd=")
        file:write(IntegerColorList [box_pos], "\n")
        file:close()
    end

    function Write_Prefs()
        reaper.SetExtState("ReaNoir", "Dock", tostring(dock), 1)
        if mode ~= "compact" then reaper.SetExtState("ReaNoir", "Mode", mode, 1) end
        local _, x, y, _, _ = gfx.dock(-1, 0, 0, 0, 0)
        reaper.SetExtState("ReaNoir", "x", tostring(x), 1)
        reaper.SetExtState("ReaNoir", "y", tostring(y), 1)
        if loaded_file ~= nil or string.match(loaded_file, ".SWSColor$") ~= ".SWSColor" or palette_display ~= "unsaved palette" then 
          reaper.SetExtState("ReaNoir", "Loaded file", loaded_file, 1)
        end
    end

    function Read_Prefs()
      local HasState = reaper.HasExtState("ReaNoir", "Dock")
      if HasState == true then dock = tonumber(reaper.GetExtState("ReaNoir", "Dock")) end
      if mode == "rgb" or mode == "hsl" then
        local HasState = reaper.HasExtState("ReaNoir", "Mode")
        if HasState == true then mode = tostring(reaper.GetExtState("ReaNoir", "Mode")) end
      end
      local HasState = reaper.HasExtState("ReaNoir", "Loaded file")
      if HasState == true then last = tostring(reaper.GetExtState("ReaNoir", "Loaded file")) end
      local HasState1 = reaper.HasExtState("ReaNoir", "x")
      local HasState2 = reaper.HasExtState("ReaNoir", "y")
      if HasState1 == true and HasState2 == true then
         lastx = tonumber(reaper.GetExtState("ReaNoir", "x"))
         lasty = tonumber(reaper.GetExtState("ReaNoir", "y"))
      end
    end

------------------------------------------
--------- Init Function ------------------
------------------------------------------

function init ()

  Read_Prefs()
  gfx.init("ReaNoir "..version, GUI_xend, GUI_yend, dock, lastx, lasty)
  if string.match(reaper.GetOS(), "Win") then
    gfx.setfont(2,"Tahoma", 13)
    gfx.setfont(1,"Arial", 15)
  elseif string.match(reaper.GetOS(), "OSX") then
    gfx.setfont(2,"Geneva", 10)
    gfx.setfont(1,"Arial", 12)
  else
    gfx.setfont(2,"Tahoma", 11)
    gfx.setfont(1,"Arial", 12)
  end
  Dock_selector_INIT()
  ColorBx_INIT()

  if last == nil or last == last_palette_on_exit then
    Create_Default()
  elseif string.match(last, "-sws$") == "-sws" then
    LoadColorFile(last_palette_on_exit)
  else
    LoadColorFile(last)
  end

  Sliders_INIT()
  RGBsquare_INIT()
  SavePalette_INIT()
  LoadPalette_INIT()
  ColorTracks_INIT()
  ColorItems_INIT()
  ColorTakes_INIT()
  Darker_INIT()
  Brighter_INIT()
  HEXinfo_INIT()
  GetColor_INIT()
  RandomColors_INIT()
  OpenSWS_INIT()
  LoadSWS_INIT()
  SetSelected()
  ShowInfo()

  -- Initialize focus
  local init_focus = reaper.GetCursorContext2(true)
  if init_focus < 1 then what = "tracks" else what = "items" end
  -- Add "pin on top"
  local js_exists = reaper.APIExists( "JS_Window_Find" )
  if js_exists then
    local w = reaper.JS_Window_Find("ReaNoir "..version, true)
    if w then reaper.JS_Window_AttachTopmostPin(w) end
  end
  if what == "tracks" then reaper.SetCursorContext(0) else reaper.SetCursorContext(1) end

end

------------------------------------------
--------- Main Loop Function -------------
------------------------------------------
function main()
  GUI()
  GiveFocusBack()
  gfx.dock(dock)
  --wheretodock=gfx.dock(-1)
  --Msg('wheretodock')
  DockselL_btn:draw()
  DockselR_btn:draw()
  DockselU_btn:draw()
  Dock_selector_GUI()

  RGBsquare_GUI()
  RGBsquare_btn:draw()
  if mode == "rgb" or "hsl" then
    RGBsquare_btn:set_color(slider_btn_r.val -0.2, slider_btn_g.val -0.2, slider_btn_b.val -0.2, slider_btn_a.val)
  elseif mode == "compact" then
    RGBsquare_btn:set_color(R/255, G/255, B/255, 1)
  end

  HEXinfo_GUI()
  HEXinfo_btn:draw()

  if mode == "hsl" then
    Sliders_GUI()
    slider_btn_h:draw()
    slider_btn_s:draw()
    slider_btn_l:draw()
  elseif mode == "rgb" then
    Sliders_GUI()
    slider_btn_r:draw()
    slider_btn_g:draw()
    slider_btn_b:draw()
  end

  for createbox = 1,24 do
      ColorBoxes [createbox]:draw()      
  end
        
  SavePalette_btn:draw()
  LoadPalette_btn:draw()
  GetColor_btn:draw()
  RandomColors_btn:draw()
  ColorTracks_btn:draw()
  ColorItems_btn:draw()
  ColorTakes_btn:draw()
  if mode == "rgb" then Darker_btn:draw() end
  if mode == "rgb" then Brighter_btn:draw() end
  OpenSWS_btn:draw()
  LoadSWS_btn:draw()
  ShowInfo_btn:draw()  
  Palette_info_GUI()
  Change_Mode()  

      if gfx.mouse_cap & 1 == 0 then
      last_mouse_state = 0
      else last_mouse_state = 1 end
      
      -- Automatic Selection of Tracks or Items mode
      if what == "takes" then SetSelected()
      else
        if reaper.GetCursorContext2(true) == 0 then
                 what = "tracks" ; SetSelected()
        elseif reaper.GetCursorContext2(true) == 1 then
                 what = "items" ; SetSelected()
        end
      end
    
      gfx.update()
      if gfx.getchar() >= 0 then reaper.defer(main)
      else 
          --- EXIT Quit Routines ---
          SaveColorFile(last_palette_on_exit)
          Write_Prefs()
      end  
  
  -- do not let resize
  if dock == 0 and (gfx.w ~= GUI_xend or gfx.h ~= GUI_yend) then
    local _, x_pos, y_pos, _, _ = gfx.dock(-1, 0, 0, 0, 0)
    gfx.quit()
    gfx.init("ReaNoir "..version, GUI_xend, GUI_yend, dock, x_pos, y_pos)
  end

end



---------------------------------------------------
-----------------// RUN SCRIPT //------------------
---------------------------------------------------
init()
main()

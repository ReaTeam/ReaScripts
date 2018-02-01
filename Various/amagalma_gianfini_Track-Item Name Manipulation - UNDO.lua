-- @description amagalma_gianfini_Track-Item Name Manipulation - UNDO
-- @author amagalma & gianfini
-- @version 2.88
-- @about
--   # Utility to manipulate track or item names
--   - Manipulate track/item names (prefix/suffix, trim start/end, keep, clear, uppercase/lowercase, swap case/capitalize/titlecase, replace, strip leading & trailing whitespaces).
--   - Mode (tracks or items) is automatically chosen when the script starts. Then to change mode click on appropriate button.
--   - When satisfied with the modifications (which can be previewed in the list), COMMIT button writes the values to tracks/items and creates an Undo point in Reaper's Undo History
--
-- @link http://forum.cockos.com/showthread.php?t=194414
-- @link http://forum.cockos.com/showthread.php?t=190534
-- @provides amagalma_Track-Item Name Manipulation Replace Help.lua

--[[
 * Changelog:
 * v2.88 (2017-11-14)
  + fixed Reascript Console left open when using Replace
--]]

-- Many thanks to spk77 and to Lokasenna for their code and help! :)

-----------------------------------------------------------------------------------------------

local version = "2.88"

-----------------------------------------------------------------------------------------------
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

--//////////////////
--// Button class //
--//////////////////


local Button = class(
                      function(btn,x1,y1,w,h,state_count,state,visual_state,lbl,help_text)
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
                        btn.r = 0.6
                        btn.g = 0.6
                        btn.b = 0.6
                        btn.a = 0.14
                        btn.lbl_r = 0.7
                        btn.lbl_g = 0.7
                        btn.lbl_b = 0.7
                        btn.lbl_a = 1
                        btn.lbl_store_r = 0.7
                        btn.lbl_store_g = 0.7
                        btn.lbl_store_b = 0.7
                        btn.fill_status = 0
                        btn.active = 1
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

function Button:set_color1()
  self.r = 0.7
  self.g = 0.35
  self.b = 0.15
  self.a = 0.6
  self.lbl_r = 1
  self.lbl_g = .8
  self.lbl_b = .4
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1  
end

function Button:set_color2()
  self.r = 0.7
  self.g = 0.35
  self.b = 0.15
  self.a = 0.2
  self.lbl_r = 0.45
  self.lbl_g = 0.25
  self.lbl_b = 0.1
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1
end

function Button:set_color_reset(on_off)
  self.r = 0.5
  self.g = 0.05
  self.b = 0.05
  self.a = 0.4
  self.lbl_r = 0.98
  self.lbl_g = 0.55
  self.lbl_b = 0.4
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1
  self.active = 1
  if on_off == 0 then
    self.active = 0
    self.lbl_a = self.lbl_a / 2
    self.a = self.a / 2
  end
end

function Button:set_color_undo(on_off)
  self.r = 0.3
  self.g = 0.25
  self.b = 0.05
  self.a = 0.4
  self.lbl_r = 0.88
  self.lbl_g = 0.75
  self.lbl_b = 0.3
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1
  self.active = 1
  if on_off == 0 then
    self.active = 0
    self.lbl_a = self.lbl_a / 2
    self.a = self.a / 2
  end
end

function Button:set_color_redo(on_off)
  self.r = 0.3
  self.g = 0.25
  self.b = 0.05
  self.a = 0.4
  self.lbl_r = 0.88
  self.lbl_g = 0.75
  self.lbl_b = 0.3
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1
  self.active = 1
  if on_off == 0 then
    self.active = 0
    self.lbl_a = self.lbl_a / 2
    self.a = self.a / 2
  end
end

function Button:set_color_commit()
  self.r = 0.1
  self.g = 0.7
  self.b = 0.1
  self.a = 0.18
  self.lbl_r = 0.1
  self.lbl_g = 0.9
  self.lbl_b = 0.25
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1
end

function Button:set_color_updown()
  self.r = 0.5
  self.g = 0.5
  self.b = 0.7
  self.a = 0.5
  self.lbl_r = 0.25
  self.lbl_g = 0.25
  self.lbl_b = 0.4
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1
  self.active = 0
end

function Button:set_color_updown_can_move(arrow_verse)
  self.r = 0.5
  self.g = 0.5
  self.b = 0.7
  self.a = 0.5
  self.lbl_r = 0
  self.lbl_g = 0
  self.lbl_b = 0.2
  self.lbl_store_r = self.lbl_r
  self.lbl_store_g = self.lbl_g
  self.lbl_store_b = self.lbl_b
  self.lbl_a = 1
  self.active = 1
  -- drawing small arrows on button
  gfx.set(0, 0, 0, 1)
  local offset = math.floor(self.w/16)
  if arrow_verse == 0 then
    gfx.line(self.x1 + self.w/6 + offset, self.y1 + self.h/8, self.x1 + self.w/6 + offset, self.y1 + self.h/2.5)
    gfx.line(self.x1 + self.w/6 + offset, self.y1 + self.h/8, self.x1 + self.w/9.5 + offset, self.y1 + self.h/5)
    gfx.line(self.x1 + self.w/6 + offset, self.y1 + self.h/8, self.x1 + self.h/4 + offset, self.y1 + self.h/5)
  else  -- and upside-down
    gfx.line(self.x1 + self.w/6 + offset, self.y1 + (self.h - self.h/8) - 1, self.x1 + self.w/6 + offset, self.y1 + (self.h - self.h/2.5) - 1)
    gfx.line(self.x1 + self.w/6 + offset, self.y1 + (self.h - self.h/8) - 1, self.x1 + self.w/9.5 + offset, self.y1 + (self.h - self.h/5) - 1)
    gfx.line(self.x1 + self.w/6 + offset, self.y1 + (self.h - self.h/8) - 1, self.x1 + self.h/4 + offset, self.y1 + (self.h - self.h/5) - 1)
  end
end


function Button:set_help_text()
  if self.help_text == "Adds index numbers at the start or\nend (p->prefix | s->suffix, then the\nstarting number)" then
    gfx.y = Tracks_btn.y1 - math.floor(win_vert_border/1.7)
  else
    if string.match(self.help_text,"\n") ~= nil then
      gfx.y = Tracks_btn.y1 - math.floor(win_vert_border/3.9)
    else
      gfx.y = Tracks_btn.y1
    end
  end
  local hwidth = gfx.measurestr(self.help_text)
  gfx.x = math.floor(win_w/2 + win_border/2)
  gfx.set(1,.6,.25,1)
  gfx.setfont(2, "Arial", 15)
  if self.active == 1 then
    gfx.printf(self.help_text)
  else
    gfx.a = 0.5
    gfx.printf(self.help_text .. " (inactive)")
  end
end

function Button:draw_label() -- Draw button label
  gfx.setfont(1, "Arial", 19) -- keep font size on mouse over
  local temp_lbl_a = 0.4
  if self.label ~= "" then
    gfx.x = self.x1 + math.floor(0.5*self.w - 0.5 * self.label_w) -- center the label
    gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth
    if self.__mouse_state == 1 and self.active == 1 then 
      gfx.y = gfx.y + 1
      --gfx.a = self.lbl_a*0.5
      temp_lbl_a = self.lbl_a*0.6 -- temp var for transparency
    elseif self.__mouse_state == 0 and self.active == 1 then
      temp_lbl_a = self.lbl_a*0.9
    end
    gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,temp_lbl_a)   -- temp var
    gfx.printf(self.label)
    if self.__mouse_state == 1 then gfx.y = gfx.y - 1 end
  end
end

-- Draw element (+ mouse handling)
function Button:draw()
  -- lmb released (and was clicked on element)
  if last_mouse_state == 0 and self.__mouse_state == 1 then self.__mouse_state = 0 end
  -- Mouse is on element -----------------------
  if self:__is_mouse_on() then 
    if self:__lmb_down() then -- Left mouse btn is pressed on button
      self.__mouse_state = 1
      if self.__state_changing == false then
        self.__state_changing = true
      else self.__state_changing = true
      end
    end
    self:set_help_text() -- Draw info/help text (if 'help_text' is not "")
    if self.fill_status == 1 then  -- different coloring if modifier active
      self.lbl_b = 0.2
      self.lbl_g = 0.6
      self.lbl_r = 1
    elseif self.active == 1 then
      self.lbl_b = self.lbl_store_b + ((1 - self.lbl_store_b)/2) 
      self.lbl_r = self.lbl_store_r + ((1 - self.lbl_store_r)/2)
      self.lbl_g = self.lbl_store_g + ((1 - self.lbl_store_g)/2)
    end
    if last_mouse_state == 1 and gfx.mouse_cap & 1 == 1 and self.__state_changing == true then
      local time = reaper.time_precise()
      if self.onClickPress ~= nil and time >= mouse_state_time + 0.2 then self:onClickPress() end
    end
    if last_mouse_state == 0 and gfx.mouse_cap & 1 == 0 and self.__state_changing == true then
      if self.onClick ~= nil then self:onClick()
        self.__state_changing = false
      else 
        self.__state_changing = false
      end
    end
    if self:__rmb_down() then
      if self.onRClick ~= nil then self:onRClick() end
    end
  -- Mouse is not on element -----------------------
  else
    if last_mouse_state == 0 and self.__state_changing == true then
      self.__state_changing = false
    end
    if self.fill_status == 1 then
      self.lbl_b = 0.4
      self.lbl_g = 0.4
      self.lbl_r = 1
    else
      self.lbl_b = self.lbl_store_b
      self.lbl_r = self.lbl_store_r
      self.lbl_g = self.lbl_store_g
    end
  end
  if (self.__mouse_state == 1 or self.vis_state == 1 or self.__state_changing) and self.active == 1 then
    gfx.set(0.9*self.r,0.9*self.g,0.9*self.b,math.max(self.a - 0.2, 0.2)*0.9)
    gfx.rect(self.x1, self.y1, self.w, self.h)
  -- Button is not pressed
  elseif not self.state_changing or self.vis_state == 0 or self.__mouse_state == 0 then
    gfx.set(self.r+0.2,self.g+0.2,self.b+0.2,self.a)
    gfx.rect(self.x1, self.y1, self.w, self.h)
    gfx.a = math.max(0.4*self.a, 0.6)
    -- light - left
    gfx.line(self.x1, self.y1, self.x1, self.y2-1)
    gfx.line(self.x1+1, self.y1, self.x2-1, self.y1)
    gfx.set(0.3*self.r,0.3*self.g,0.3*self.b,math.max(0.9*self.a,0.8))
    -- shadow - bottom
    gfx.line(self.x1+1, self.y2-1, self.x2-2, self.y2-1)
    -- shadow - right
    gfx.line(self.x2-1, self.y2-1, self.x2-1, self.y1+1)
  end
  self:draw_label()
end


-- The code above is borrowed from spk77's "spk77_Button colors.lua" script found in ReaPack
-- Modified by : gianfini & amagalma
--------------------------------------------------------------------------------------------


-- making local as many as possible of the variables, optimizes script
local reaper = reaper
local has_changed, what, trackCount, indexed_track, scroll_line_selected, itemCount, indexed_item
local undo_stack, ToBeTrackNames, OriginalTrackNames, ToBeItemNames, OriginalItemNames, redo_stack
local mod_stack_name, mod_stack_parm1, mod_stack_parm2 = {}, {}, {} -- management of modifiers' undo stack
local scroll_list_x, scroll_list_y, scroll_list_w, scroll_list_h, scroll_line_selected
gfx.setfont(1, "Arial", 19)
local strw, strh = gfx.measurestr("Strip leading & trailing whitespaces")

-- last_mouse_state & mouse_state_time must be globals


--------------------------------------------------------------------------------------------

local function round(num)
  return math.floor(num * 10 + 0.5) / 10
end


local function f() 
  gfx.setfont(1, "Arial", 19)
end


local function fsmall()
  gfx.setfont(3, "Courier New", 14)
end


-- Needed variables
fsmall()
local lstw_small, lsth_small = gfx.measurestr("Strip leading & trailing whitespaces")


local function IsTable(t) return type(t) == 'table' end


local function Window_At_Center(w, h) -- Lokasenna function
  local l, t, r, b = 0, 0, w, h
  local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)
  local x, y = (screen_w - w) / 2, (screen_h - h) / 2
  gfx.init("Track/Item Name Manipulation v"..version, w, h, 0, x, y)
end


local function swapcase(str)
  local t={}
  str:gsub(".",function(c) table.insert(t,c) end)
  for i=1, #t do
    if t[i] == t[i]:match("%l") then t[i] = t[i]:upper()
    elseif t[i] == t[i]:match("%u") then t[i] = t[i]:lower()
    end
  end
  return table.concat(t)
end


local function CheckTracks()
  local trackCount = reaper.CountSelectedTracks(0)
  if trackCount < 1 then
    reaper.MB("Please select at least one track!", "", 0)
  else  
    return true
  end
end


local function CheckItems()
  local itemCount = reaper.CountSelectedMediaItems(0)
  if itemCount < 1 then
    reaper.MB("Please select at least one item!", "", 0)
  else  
    return true
  end
end


-- versions without message
local function CheckTracks_NM()
  trackCount = reaper.CountSelectedTracks(0)
  if trackCount > 0 then
    return true
  end
end

local function CheckItems_NM()
  itemCount = reaper.CountSelectedMediaItems(0)
  if itemCount > 0 then
    return true
  end
end

-- Store all track names in a table
local function AllTrackNames()
  local alltracks = reaper.CountTracks(0)
  local table = {}
  for i = 0, alltracks-1 do
    local tr = reaper.GetTrack( 0, i)
    local _, name =  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    table[reaper.GetTrackGUID(tr)] = name
  end
  return table
end

-- Store all item names in a table
local function AllItemNames()
  local allitems = reaper.CountMediaItems(0)
  local table = {}
  for i = 0, allitems-1 do
    local it = reaper.GetMediaItem( 0, i)
    local acttake = reaper.GetActiveTake(it)
    if acttake then 
      local _, name = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
      table[reaper.BR_GetMediaItemTakeGUID(acttake)] = name
    else
      local t = {}
      local name = reaper.ULT_GetMediaItemNote(it)
      for word in string.gmatch(name, "[^\n]+") do t[#t+1]= word end
      table[reaper.BR_GetMediaItemGUID(it)] = t
    end
  end
  return table
end

-- Replace button Help if "amagalma_Track-Item Name Manipulation Replace Help.lua" cannot be loaded
local function InfoReplacePattern()
  local info = [[
----- Track/item Name Manipulation: Replace Pattern Help -----

• comma (,) must be escaped with a ~ (~,) otherwise is ignored!

--- SINGLE LETTER CLASSES ------------------------------------

• x   : (where x is not one of the magic characters ().%+-*?[]^$ represents the character x itself
• .   : (a dot) represents all characters
• %a  : represents all letters
• %c  : represents all control characters
• %d  : represents all digits
• %l  : represents all lowercase letters
• %p  : represents all punctuation characters
• %s  : represents all space characters
• %u  : represents all uppercase letters
• %w  : represents all alphanumeric characters
• %x  : represents all hexadecimal digits
• %z  : represents the character with representation 0
• %x  : (where x is any non-alphanumeric character) represents the character x
        
• To escape the magic characters preceed by a %

• For all classes represented by single letters (%a , %c , etc.), the corresponding uppercase letter represents the complement of the class.     


--- SETS -----------------------------------------------------

• [set]:  represents the class which is the union of all characters in set
• [^set]: represents the complement of set

• A range of characters can be specified with a - (for example, [0-7]
• All classes %x described above can also be used in set
• All other characters in set represent themselves


--- MAIN PATTERNS --------------------------------------------

• a single character class followed by * matches 0 or more repetitions of characters (longest possible sequence)
• a single character class followed by + matches 1 or more repetitions of characters in the class (longest sequence)
• a single character class followed by - is like * but matches the shortest possible sequence
• a single character class followed by ? matches 0 or 1 occurrence of a character in the class
  
• ^ anchors the pattern to the beginning of the string
• $ at the end anchors the match at the end of the subject string.
]]
  reaper.ClearConsole()
  reaper.ShowConsoleMsg(info)
end


-- line between buttons
local function DrawOneDividingLine(txx, tyy, strong)
  local txx = 0
  if strong == 0 then
    gfx.set(0, 0, 0, .8)
    gfx.line(txx, tyy, win_w - txx, tyy)
    gfx.set(1, 1, 1, .15)
    gfx.line(txx + 1, tyy + 1, win_w - txx - 1, tyy + 1)
  else
    gfx.set(0, 0, 0, 1)
    gfx.line(txx, tyy, win_w - txx, tyy)
    gfx.set(1, 1, 1, .4)
    gfx.line(txx + 1, tyy + 1, win_w - txx - 1, tyy + 1)
  end
end


local function DrawDividingLines()
  DrawOneDividingLine(trimstart_btn.x1, trimstart_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
  DrawOneDividingLine(replace_btn.x1, replace_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
  DrawOneDividingLine(suffix_btn.x1, suffix_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
  DrawOneDividingLine(number_btn.x1, number_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
  DrawOneDividingLine(swap_btn.x1, swap_btn.y1 + btn_height + math.floor(win_vert_border/2), 0)
  DrawOneDividingLine(reset_btn.x1, reset_btn.y1 + btn_height*2 + math.floor(win_vert_border/2), 1)
end


local function set_list_help_text()
  gfx.y = Tracks_btn.y1
  local help_text_list = "Click on a line for free editing"
  local hwidth = gfx.measurestr(help_text_list)
  gfx.x = math.floor(win_w/2 + win_border/2)
  gfx.set(1,.6,.25,1)
  gfx.setfont(2, "Arial", 15)
  gfx.printf(help_text_list)
end


-- prints a track or item name
local function DrawTrackName(txx, tyy, tname)
    gfx.y = tyy
    gfx.x = txx
    gfx.a = 1
    gfx.set(0, 0, .1, 1)
    fsmall()
    gfx.printf("%.50s", tname)
end


local function RefreshTrackItemList(tl_x, tl_y, tl_w, tl_h) -- redraws the tracks - items scroll list
  local max_lines = math.floor(tl_h/lsth_small)
  local x_start = tl_x
  local y_start = tl_y
  local init_line, last_s_line
  gfx.r = 0.4
  gfx.g = 0.4
  gfx.b = 0.45
  gfx.a = 1
  gfx.rect(tl_x, tl_y - math.floor(lsth_small/3), tl_w, tl_h + math.floor(lsth_small/3))
  num_displayed_tracks = 0  -- gianfini must stay
  if what == "tracks" and CheckTracks_NM() then
    if (trackCount - indexed_track + 1) < max_lines then
      local btn_DOWN_can_move = 0 -- indicates if list can scroll down further (for graphic indication on btn)
      if trackCount > max_lines then
        init_line = trackCount - max_lines
        indexed_track = init_line + 1
      else
        init_line = 0
        indexed_track = 1
      end
    else
      init_line = indexed_track - 1
      if (trackCount - indexed_track + 1) == max_lines then
        btn_DOWN_can_move = 0 -- indicates if list can scroll down further (for graphic indication on btn)
      else
        btn_DOWN_can_move = 1 -- indicates if list can scroll down further (for graphic indication on btn)
      end
    end
    local first_s_line = init_line
    if (trackCount - indexed_track + 1) < max_lines then
      last_s_line = trackCount - 1
    else
      last_s_line = first_s_line + max_lines - 1
    end
  
  num_displayed_lines = last_s_line - first_s_line + 1  --gianfini this has to stay
    for i = first_s_line, last_s_line do
      local trt = reaper.GetSelectedTrack(0, i)
      local track_num = reaper.GetMediaTrackInfo_Value(trt,"IP_TRACKNUMBER")
      DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small), tostring(string.format("%02d",track_num))..". "..tostring(ToBeTrackNames[reaper.GetTrackGUID(trt)]))
    end
  elseif what == "items" and CheckItems_NM() then
    if (itemCount - indexed_item + 1) < max_lines then
      local btn_DOWN_can_move = 0 -- indicates if list can scroll down further (for graphic indication on btn)
      if itemCount > max_lines then
        init_line = itemCount - max_lines
        indexed_item = init_line + 1
      else
        init_line = 0
        indexed_item = 1
      end
    else
      init_line = indexed_item - 1
      if (itemCount - indexed_item + 1) == max_lines then
        btn_DOWN_can_move = 0 -- indicates if list can scroll down further (for graphic indication on btn)
      else
        btn_DOWN_can_move = 1 -- indicates if list can scroll down further (for graphic indication on btn)
      end
    end
    local first_s_line = init_line
    if (itemCount - indexed_item + 1) < max_lines then
      last_s_line = itemCount - 1
    else
      last_s_line = first_s_line + max_lines - 1
    end
  num_displayed_lines = last_s_line - first_s_line + 1 -- gianfini: has to stay
    for i = first_s_line, last_s_line do
      local itemId = reaper.GetSelectedMediaItem(0, i)
      local acttake =  reaper.GetActiveTake(itemId)
      if acttake then
        DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small), tostring(ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]))
      else
        local name = ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)]
        if IsTable(name) then name = table.concat(name, " | ") end
        DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small), tostring(name))
      end
    end
  end
end


function UpdateUndoHelp()
  if undo_stack > 0 then
    local modifier_name = ""
    local last_modifier = mod_stack_name[undo_stack]
    local parm1 = mod_stack_parm1[undo_stack]
    local parm2 = mod_stack_parm2[undo_stack]
    if last_modifier == "prefix" then
      modifier_name = "PREFIX " .. "\'" .. parm1 .. "\'"
    elseif last_modifier == "suffix" then
      modifier_name = "SUFFIX " .. "\'" .. parm1 .. "\'"
    elseif last_modifier == "trimstart" then
      modifier_name = "TRIM START " .. parm1
    elseif last_modifier == "trimend" then
      modifier_name = "TRIM END " .. parm1
    elseif last_modifier == "keep" then
      modifier_name = "KEEP " .. "\'" .. parm1 .. "\'" 
    elseif last_modifier == "replace" then
      modifier_name = "REPLACE " .. "\'" .. tostring(parm1) .. "\'" .. "\nWITH " .. "\'" .. parm2 .. "\'"
    elseif last_modifier == "number" then
      modifier_name = "NUMBER " .. "\'" .. parm1 .. "\'"
    elseif last_modifier == "upper" then
      modifier_name = "UPPERCASE"
    elseif last_modifier == "lower" then
      modifier_name = "LOWERCASE"
    elseif last_modifier == "swap" then
      modifier_name = "SWAPCASE"
    elseif last_modifier == "capitalize" then
      modifier_name = "CAPITALIZE"
    elseif last_modifier == "title" then
      modifier_name = "TITLECASE"
    elseif last_modifier == "strip" then
      modifier_name = "STRIP LEAD/TRAIL SPACES"
    elseif last_modifier == "single_line_edit" then
      modifier_name = "EDIT LINE NO. " .. parm2
  elseif last_modifier == "clear" then
    modifier_name = "CLEAR"
    end  
    undo_btn.help_text = "Undo " .. modifier_name
  else
    undo_btn.help_text = "Nothing to undo"
  end
end


function UpdateRedoHelp()
  if redo_stack > 0 then
    local modifier_name = ""
    local last_modifier = mod_stack_name[undo_stack+1]
    local parm1 = mod_stack_parm1[undo_stack+1]
    local parm2 = mod_stack_parm2[undo_stack+1]
    if last_modifier == "prefix" then
      modifier_name = "PREFIX " .. "\'" .. parm1 .. "\'"
    elseif last_modifier == "suffix" then
      modifier_name = "SUFFIX " .. "\'" .. parm1 .. "\'"
    elseif last_modifier == "trimstart" then
      modifier_name = "TRIM START " .. parm1
    elseif last_modifier == "trimend" then
      modifier_name = "TRIM END " .. parm1
    elseif last_modifier == "keep" then
      modifier_name = "KEEP " .. "\'" .. parm1 .. "\'" 
    elseif last_modifier == "replace" then
      modifier_name = "REPLACE " .. "\'" .. tostring(parm1) .. "\'" .. "\nWITH " .. "\'" .. parm2 .. "\'"
    elseif last_modifier == "number" then
      modifier_name = "NUMBER " .. "\'" .. parm1 .. "\'"
    elseif last_modifier == "upper" then
      modifier_name = "UPPERCASE"
    elseif last_modifier == "lower" then
      modifier_name = "LOWERCASE"
    elseif last_modifier == "swap" then
      modifier_name = "SWAPCASE"
    elseif last_modifier == "capitalize" then
      modifier_name = "CAPITALIZE"
    elseif last_modifier == "title" then
      modifier_name = "TITLECASE"
    elseif last_modifier == "strip" then
      modifier_name = "STRIP LEAD/TRAIL SPACES"
    elseif last_modifier == "single_line_edit" then
      modifier_name = "EDIT LINE NO. " .. parm2
  elseif last_modifier == "clear" then
    modifier_name = "CLEAR"  -- gianfini added
    end  
    redo_btn.help_text = "Redo " .. modifier_name
  else
    redo_btn.help_text = "Nothing to redo" -- gianfini fix
  end
end


function ApplyModifier(prevName, modifier, parm1, parm2, seq_number) -- apply one modifier to a track-item name
  if IsTable(prevName) then prevName = table.concat(prevName) end
  local newName = prevName
  local i = seq_number
  if modifier == "prefix" then
    newName = parm1 .. newName
  elseif modifier == "suffix" then
    newName = newName .. parm1
  elseif modifier == "clear" then
    newName = ""
  elseif modifier == "trimstart" then
    newName = newName:sub(parm1 + 1)
  elseif modifier == "trimend" then
    local length = newName:len()
    newName = newName:sub(1, length - parm1)
  elseif modifier == "keep" then
    local mode, number = parm1:match("([seSE])%s?(%d+)")
    number = tonumber(number)
    if mode:match("[sS]") then
      newName = newName:sub(0, number)
    else
      newName = newName:sub((-1)*number)
    end 
  elseif modifier == "replace" then
    if parm1 ~= "" then
      newName = string.gsub(newName, parm1, parm2)
    end
  elseif modifier == "number" then
    if parm1 ~= "" then
      local mode, number = parm1:match("([psPS])%s?(%d+)")
      if mode:match("[pP]") then
        newName = string.format("%02d", math.floor(number+i)) .. " " .. newName
      else
        newName = newName .. " " .. string.format("%02d", math.floor(number+i))
      end
    end
  elseif modifier == "upper" then
    newName = string.upper(newName)
  elseif modifier == "lower" then
    newName = string.lower(newName)
  elseif modifier == "swap" then
    newName = swapcase(newName)
  elseif modifier == "capitalize" then
    newName = (newName:gsub("^%l", string.upper))
  elseif modifier == "title" then
    newName = string.gsub(" "..newName, "%W%l", string.upper):sub(2)
  elseif modifier == "strip" then
    newName = newName:match("^%s*(.-)%s*$")
  elseif modifier == "single_line_edit" then
    if tonumber(parm2) == (i + 1) then
      newName = parm1
    end
  end
  return newName
end

function SaveNextRedo()  -- saves next redo data, to restore them in case no modification from a modifier
  local next_redo = undo_stack + 1
  if redo_stack > 0 then
    next_redo_name = mod_stack_name[next_redo] 
    next_redo_parm1 = mod_stack_parm1[next_redo]
    next_redo_parm2 = mod_stack_parm2 [next_redo]
  end
end

function RestoreNextRedo()
  local next_redo = undo_stack + 1
  if redo_stack > 0 then
    mod_stack_name[next_redo] = next_redo_name
    mod_stack_parm1[next_redo] = next_redo_parm1
    mod_stack_parm2 [next_redo] = next_redo_parm2
  end
end

function WriteCurrentModifier() -- write last modifier only to all tracks-items list
  has_changed = 0 -- indicate whether a change in track-items names has occurred or not
  if what == "tracks" and CheckTracks() then 
    for i=0, trackCount-1 do
      local trackId = reaper.GetSelectedTrack(0, i)
      local prevName = ToBeTrackNames[reaper.GetTrackGUID(trackId)]
      if undo_stack > 0 then
        local modifier = mod_stack_name[undo_stack]
        local parm1 = mod_stack_parm1[undo_stack]
        local parm2 = mod_stack_parm2[undo_stack]
        newName = ApplyModifier(prevName, modifier, parm1, parm2, i) -- write a single modifier to newName based on prevName
      end
      -- Update list
      if newName ~= prevName then
        ToBeTrackNames[reaper.GetTrackGUID(trackId)] = newName
        has_changed = 1
      end
    end   
  elseif what == "items" and CheckItems() then
    for i=0, itemCount-1 do
      local itemId = reaper.GetSelectedMediaItem(0, i)
      local acttake = reaper.GetActiveTake(itemId)
      local prevName
      if acttake then
        prevName = ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]
      else
        prevName = ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)]
        if IsTable(prevName) then table.concat(prevName) end
      end
      if undo_stack > 0 then
        local modifier = mod_stack_name[undo_stack]
        local parm1 = mod_stack_parm1[undo_stack]
        local parm2 = mod_stack_parm2[undo_stack]
        newName = ApplyModifier(prevName, modifier, parm1, parm2, i) -- write a single modifier to newName based on prevName
      end  
      -- Update list
      if prevName ~= newName then
        if acttake then
          ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)] = newName
        else
          ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)] = newName
        end
        has_changed = 1
      end
    end 
  end
  if has_changed == 0 and undo_stack > 0 then
    undo_stack = undo_stack - 1
  if redo_stack > 0 then RestoreNextRedo() end -- gianfini: needed to keep undo stack if no modification has been done by modifier
  else
    redo_stack = 0  --gianfini to reset undo when branching new modifications: as all undo usually work IF MODIFICATIONS ACTUALLY OCCURRED
  end
  UpdateUndoHelp()
  UpdateRedoHelp()
end


function WriteModifiersStack() -- write all modifiers to track-items list (not to actual tracks-items) up to current undo-level
  if what == "tracks" and CheckTracks() then    
    for i=0, trackCount-1 do
      local trackId = reaper.GetSelectedTrack(0, i)
      local newName = OriginalTrackNames[reaper.GetTrackGUID(trackId)]
      if undo_stack > 0 then
        for j=1, undo_stack do
          local modifier = mod_stack_name[j]
          local parm1 = mod_stack_parm1[j]
          local parm2 = mod_stack_parm2[j]
          prevName = newName
          newName = ApplyModifier(prevName, modifier, parm1, parm2, i) -- write a single modifier to newName based on prevName
        end
      end
      -- Update list
      ToBeTrackNames[reaper.GetTrackGUID(trackId)] = newName
    end
  elseif what == "items" and CheckItems() then           
    for i=0, itemCount-1 do
      local itemId = reaper.GetSelectedMediaItem(0, i)
      local acttake = reaper.GetActiveTake(itemId)
      local newName
      if acttake then
        newName = OriginalItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]
      else
        newName = OriginalItemNames[reaper.BR_GetMediaItemGUID(itemId)]
      end
      if undo_stack > 0 then
        for j=1, undo_stack do
          local modifier = mod_stack_name[j]
          local parm1 = mod_stack_parm1[j]
          local parm2 = mod_stack_parm2[j]
          prevName = newName
          newName = ApplyModifier(prevName, modifier, parm1, parm2, i) -- write a single modifier to newName based on prevName
        end
      end  
      -- Update list
      if acttake then
        ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)] = newName
      else
        ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)] = newName
      end
    end
  end
  UpdateUndoHelp()
  UpdateRedoHelp()
end


local function get_line_name(line_num)  -- get the text of line in scroll list and corresponding Reaper track num
  if what == "tracks" then
    local trackId = reaper.GetSelectedTrack(0, line_num)
    return ToBeTrackNames[reaper.GetTrackGUID(trackId)], reaper.GetMediaTrackInfo_Value(trackId,"IP_TRACKNUMBER")
  else  
    local itemId = reaper.GetSelectedMediaItem(0, line_num)
    local acttake = reaper.GetActiveTake(itemId)
    if acttake then
      return ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)], 0
    else
      return table.concat(ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)]), 0
    end
  end
end


local function modify_single_line(line_num)
  local line_object = ""
  local obj_name, track_num = get_line_name(line_num - 1)
  if what == "tracks" then
    line_object = "TRACK " .. tostring(string.format("%02d",track_num))
  else
    line_object = "ITEM"
  end
  local ok, text = reaper.GetUserInputs("Modify " .. line_object, 1, "Name: ,extrawidth=" .. tostring(math.floor(scroll_list_w*3/5)), obj_name)
  if ok then
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "single_line_edit"
    mod_stack_parm1 [undo_stack] = text
    mod_stack_parm2 [undo_stack] = tostring(line_num)
    WriteCurrentModifier()
  end
end


local function is_mouse_on_list_Down()  --gianfini: this has been reversed to original because the logic is to check mouse over to set help and return mouse button pressed
  fsmall()
  local lstw_small, lsth_small = gfx.measurestr("Strip leading & trailing whitespaces") -- gianfini example string to set width
  
  scroll_line_selected = math.floor((gfx.mouse_y - scroll_list_y + lsth_small) / lsth_small)
  if (gfx.mouse_x > scroll_list_x and gfx.mouse_x < (scroll_list_x + scroll_list_w) and gfx.mouse_y > scroll_list_y and gfx.mouse_y < (scroll_list_y + scroll_list_h) and 
      last_mouse_state == 0) then
    set_list_help_text()
    if (gfx.mouse_cap & 1 == 1 and tonumber(num_displayed_lines) >= scroll_line_selected) then return true end
  end  
end

local function init_tables()
  if what == "tracks" then
    ToBeTrackNames = AllTrackNames()
    OriginalTrackNames = AllTrackNames()
    indexed_track = 1
    undo_stack = 0
    redo_stack = 0
    -- free memory
    ToBeItemNames = nil
    OriginalItemNames = nil
    indexed_item = nil
  elseif what == "items" then
    ToBeItemNames = AllItemNames()
    OriginalItemNames = AllItemNames()
    indexed_item = 1
    undo_stack = 0
    redo_stack = 0
    -- free memory
    ToBeTrackNames = nil
    OriginalTrackNames = nil
    indexed_track = nil
  end
  btn_DOWN_can_move = 0
end


local function main() -- MAIN FUNCTION ---------------------------------------------------------------
  -- Draw buttons
  f(); prefix_btn:draw()
  f(); suffix_btn:draw()
  f(); trimstart_btn:draw()
  f(); trimend_btn:draw()
  f(); keep_btn:draw()
  f(); replace_btn:draw()
  f(); clear_btn:draw()
  f(); upper_btn:draw()
  f(); lower_btn:draw()
  f(); swap_btn:draw()
  f(); capitalize_btn:draw()
  f(); title_btn:draw()
  f(); strip_btn:draw()
  f(); number_btn:draw()
  f(); Tracks_btn:draw()
  f(); Items_btn:draw()
  f(); commit_btn:draw()
  f(); reset_btn:draw()
  f(); undo_btn:draw()
  f(); redo_btn:draw()
  f(); UP_btn:draw()
  f(); DOWN_btn:draw()
  DrawDividingLines()

  if what == "tracks" then
    Tracks_btn:set_color1()
    Items_btn:set_color2()
  else 
    Items_btn:set_color1()  
    Tracks_btn:set_color2() 
  end
  
  commit_btn:set_color_commit()
  
  if undo_stack > 0 then
    undo_btn:set_color_undo(1)
  reset_btn:set_color_reset(1)
  else
    undo_btn:set_color_undo(0)
    if redo_stack > 0 then
    reset_btn:set_color_reset(1)  -- gianfini: added to align reset behavior when redo possible
  else
    reset_btn:set_color_reset(0)
  end
  end
  
  if redo_stack > 0 then
    redo_btn:set_color_undo(1)
  else
    redo_btn:set_color_undo(0)
  end 
  
  if (what == "tracks" and indexed_track > 1) or (what == "items" and indexed_item > 1) then 
    UP_btn:set_color_updown_can_move(0)
  else
    UP_btn:set_color_updown()
  end
  if btn_DOWN_can_move == 1 then
    DOWN_btn:set_color_updown_can_move(1)
  else
    DOWN_btn:set_color_updown()
  end
  
  RefreshTrackItemList(scroll_list_x, scroll_list_y, scroll_list_w, scroll_list_h)
  if is_mouse_on_list_Down() then modify_single_line(tonumber(scroll_line_selected)) end  
  
  -- Check left mouse btn state
  if gfx.mouse_cap & 1 == 0 then
    last_mouse_state = 0
    mouse_state_time = nil
  else
    last_mouse_state = 1
    if not mouse_state_time then mouse_state_time = reaper.time_precise() end
  end
  
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(main)
  else
    local _, x, y, _, _ = gfx.dock(-1, 0, 0, 0, 0)
    reaper.SetExtState("Track-Item Name Manipulation", "x position", x, 1)
    reaper.SetExtState("Track-Item Name Manipulation", "y position", y, 1)
  end
  
end

local function init() -- INITIALIZATION --------------------------------------------------------------
  -- Get current context (tracks or items)
  local context = reaper.GetCursorContext2(true)
  if context == 0 then what = "tracks" else what = "items" end
  init_tables()
  f() -- set font
  gfx.clear = 3084036
  -- set of global variables for screen drawing
  win_w = math.floor(strw*1.6)
  win_h = strh+math.floor(11.5*strh*2.5)
  btn_height = strh+math.floor(strh/3.2)
  win_border = math.floor(strh/2)
  win_vert_border = math.floor(win_border*1.6)
  win_double_vert_border = win_border*2
  -- Remember last screen position 
  local HasState1 = reaper.HasExtState("Track-Item Name Manipulation", "x position")
  local HasState2 = reaper.HasExtState("Track-Item Name Manipulation", "y position")
  if HasState1 and HasState2 then
    local x = tonumber(reaper.GetExtState("Track-Item Name Manipulation", "x position"))
    local y = tonumber(reaper.GetExtState("Track-Item Name Manipulation", "y position"))
    gfx.init("Track/Item Name Manipulation v"..version, win_w, win_h, 0, x, y)
  else
    Window_At_Center(win_w, win_h)
  end
 
  -- parameters: Button(x1,y1,w,h,state_count,state,visual_state,lbl,help_text)
 
  -- 1st raw: Trim, Keep ------------------------------------------------------
  local label, help = "Trim Start", "Removes specified number of\ncharacters from the start"
  local width = math.floor((win_w - 4*win_border)/3)
  local height = btn_height
  local x_pos = win_border
  local y_pos = win_vert_border
  trimstart_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Trim end", "Removes specified number of\ncharacters from the end"
  local x_pos = win_border*2 + width
  trimend_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Keep", "Keeps only specified number of \nchars (s-> from start | e-> from end)"
  local x_pos = win_border*3 + width*2
  keep_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- 2nd raw: Replace Clear ---------------------------------------------------
  local label, help = "Replace", "Replaces all instances of the pattern\nwith replacement (RClick -> help)"
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  replace_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Clear", "Clears all names!"
  local x_pos = win_border*2 + width
  clear_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- 3rd raw: Prefix Suffix ---------------------------------------------------
  local label, help = "Prefix", "Inserts text at the begining"
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  prefix_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Suffix", "Appends text to the end"
  local x_pos = win_border*2 + width
  suffix_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- 4th raw: Numbering -------------------------------------------------------
  local label, help = "Number", "Adds index numbers at the start or\nend (p->prefix | s->suffix, then the\nstarting number)"
  local width = win_w - 2*win_border
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  number_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- 5th raw: Upper/Lower case ------------------------------------------------
  local label, help = "Uppercase", "Converts all letters to UPPERCASE"
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  upper_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Lowercase", "Converts all letters to lowercase"
  local x_pos = win_border*2 + width
  lower_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- 6th raw: Swap case, Capitalize, Titlecase --------------------------------
  local label, help = "Swap case", "Inverts the case of each letter\n(eg Do => dO)"
  local width = math.floor((win_w - 4*win_border)/3)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + math.floor(win_vert_border/2)
  swap_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Capitalize", "Capitalizes the very first letter"
  local x_pos = win_border*2 + width
  capitalize_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Titlecase", "Capitalizes The First Letter Of\nEach Word"
  local x_pos = win_border*3 + width*2
  title_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- 7th raw: Strip whitespaces -----------------------------------------------
  local label, help = "Strip leading & trailing whitespaces", "Removes all leading and trailing\nwhitespaces"
  local width = win_w - 2*win_border
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  strip_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- 8th raw: Reset, Undo/Redo and Commit -------------------------------------
  local label, help = "RESET", "Reset all modifiers and\nredo states"  -- gianfini: description adjusted as per behavior
  local width = (win_w -  3.5*win_border)/5
  local x_pos = win_border
  local y_pos = y_pos + btn_height + math.floor(win_vert_border*0.8)
  local height = btn_height*2
  reset_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "UNDO", "Nothing to undo"
  local x_pos = 1.5*win_border + width
  undo_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "REDO", "Nothing to redo"
  local x_pos = 2*win_border + 2*width
  redo_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "COMMIT", "Commit all modifications"
  local x_pos = 2.5*win_border + 3*width
  commit_btn = Button(x_pos, y_pos, width*2, height, 2, 0, 0, label, help)

  -- 9th raw: Tracks or Items mode --------------------------------------------
  local label, help = "Tracks", "Click to select Tracks mode"
  local height = btn_height
  local width = math.floor((win_w - 5*win_border)/4)
  local x_pos = win_border
  local y_pos = y_pos + height*2 + win_double_vert_border
  Tracks_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help, 2, 0, 0, label, help)
  
  local label, help = "Items", "Click to select Items mode"
  local x_pos = win_border*2 + width
  Items_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  --- scroll list measures ----------------------------------------------------
  scroll_list_x = win_border
  scroll_list_y = y_pos + height + win_double_vert_border
  scroll_list_w = win_w - 2*win_border - 4*win_border
  scroll_list_h = win_h - scroll_list_y - win_vert_border
  indexed_track = 1
  fsmall()
  
  --- scroll table buttons UP and DOWN ----------------------------------------
  local label, help = "U", "Scrolls Up tracknames"
  local width, height = gfx.measurestr(label)
  height = btn_height
  width = math.floor(width*4)
  x_pos = win_w - width - win_border
  y_pos = y_pos + height + win_double_vert_border - math.floor(win_vert_border/3.3)
  UP_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  local label, help = "D", "Scrolls Down tracknames"
  y_pos = y_pos + scroll_list_h - height + win_vert_border/3
  DOWN_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
    
-- BUTTON FUNCTIONS -----------------------------------------------------------

  function Tracks_btn.onClick()
    what = "tracks"
    init_tables()
    undo_btn.help_text = "Nothing to undo"
  redo_btn.help_text = "Nothing to redo"
    has_changed = 0
  end
  
  function Items_btn.onClick()
    what = "items"
    init_tables()
    undo_btn.help_text = "Nothing to undo"
  redo_btn.help_text = "Nothing to redo"
    has_changed = 0
  end

  function prefix_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      local ok, text = reaper.GetUserInputs("Prefix", 1, "Insert text:", "")
      if ok then
        if text ~= "" then
          undo_stack = undo_stack + 1
          mod_stack_name [undo_stack] = "prefix"
          mod_stack_parm1 [undo_stack] = text
          mod_stack_parm2 [undo_stack] = ""
          WriteCurrentModifier()
        end
      end
    end
  end

  function suffix_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      local ok, text = reaper.GetUserInputs("Prefix", 1, "Insert text:", "")
      if ok then
        if text ~= "" then
          undo_stack = undo_stack + 1
          mod_stack_name [undo_stack] = "suffix"
          mod_stack_parm1 [undo_stack] = text
          mod_stack_parm2 [undo_stack] = ""
          WriteCurrentModifier()
        end
      end
    end
  end
  
  function number_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      local ok, text = reaper.GetUserInputs("Numbering (p -> prefix, s -> suffix)", 1, "Specify mode and number:", "")
      if ok then
        if text:match("[psPS]%s?%d+") then
          if text ~= "" then
            undo_stack = undo_stack + 1
            mod_stack_name [undo_stack] = "number"
            mod_stack_parm1 [undo_stack] = text
            mod_stack_parm2 [undo_stack] = ""
          end
          WriteCurrentModifier()
        else
          reaper.MB("Please type p or s followed by the starting number!\n Examples: s02 , P3 , p03 , S 12", "Not valid input!", 0)
        end
      end
    end
  end
  
  function replace_btn.onRClick()
    local HasState = reaper.HasExtState("Track-Item Name Manipulation", "Replace Help Is open")
    if not HasState or (HasState == true and reaper.GetExtState("Track-Item Name Manipulation", "Replace Help Is open") == "0") then
      local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
      local file = ({reaper.get_action_context()})[2]:match("^(.*[/\\])").."amagalma_Track-Item Name Manipulation Replace Help.lua"
      local exists = reaper.file_exists(file)
      if exists then -- load the Replace Help script
        local ActionID = reaper.AddRemoveReaScript(true, 0, file, true)
        reaper.Main_OnCommand(ActionID, 0)
        reaper.AddRemoveReaScript(false, 0, file, true)
      else -- open Reascript console showing the Replace Help
        InfoReplacePattern()
      end
    end
  end
  
  function replace_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      local ok, retvals = reaper.GetUserInputs("Replace", 2, "Pattern:,Replacement:", ",")
      if ok then
        if retvals ~= ",," and retvals ~= "," then
          local words = {}
          retvals = string.gsub(retvals, "~,", "#@c@#")
          for word in retvals:gmatch("[^,]+") do
          word = string.gsub(word, "#@c@#", ",")
            table.insert(words, word)
          end
          local replaceOld = words[1]
          local replaceWith = words[2] or ""   
          if string.sub(retvals, 1, 1) == "," then
            replaceWith = replaceOld
            replaceOld = ""
          end
          if replaceOld == "" then return end
          if text ~= "" then
            undo_stack = undo_stack + 1
            mod_stack_name [undo_stack] = "replace"
            mod_stack_parm1 [undo_stack] = replaceOld
            mod_stack_parm2 [undo_stack] = replaceWith
          end
          WriteCurrentModifier()
        end
      end
    end  
  end

  function upper_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      undo_stack = undo_stack + 1 
      mod_stack_name [undo_stack] = "upper"
      mod_stack_parm1 [undo_stack] = ""
      mod_stack_parm2 [undo_stack] = ""
      WriteCurrentModifier()
    end
  end

  function lower_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      undo_stack = undo_stack + 1 
      mod_stack_name [undo_stack] = "lower"
      mod_stack_parm1 [undo_stack] = ""
      mod_stack_parm2 [undo_stack] = ""
      WriteCurrentModifier()
    end
  end

  function swap_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      undo_stack = undo_stack + 1 
      mod_stack_name [undo_stack] = "swap"
      mod_stack_parm1 [undo_stack] = ""
      mod_stack_parm2 [undo_stack] = ""
      WriteCurrentModifier()
    end  
  end

  -- amagalma clear button
  function clear_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then 
      undo_stack = undo_stack + 1 
      mod_stack_name [undo_stack] = "clear"
      mod_stack_parm1 [undo_stack] = ""
      mod_stack_parm2 [undo_stack] = ""
      WriteCurrentModifier()
    end 
  end

  function capitalize_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      undo_stack = undo_stack + 1 
      mod_stack_name [undo_stack] = "capitalize"
      mod_stack_parm1 [undo_stack] = ""
      mod_stack_parm2 [undo_stack] = ""
      WriteCurrentModifier()
    end  
  end

  function title_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      undo_stack = undo_stack + 1 
      mod_stack_name [undo_stack] = "title"
      mod_stack_parm1 [undo_stack] = ""
      mod_stack_parm2 [undo_stack] = ""
      WriteCurrentModifier()
    end  
  end
  
  function strip_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      undo_stack = undo_stack + 1 
      mod_stack_name [undo_stack] = "strip"
      mod_stack_parm1 [undo_stack] = ""
      mod_stack_parm2 [undo_stack] = ""
      WriteCurrentModifier()
    end  
  end
  
  function trimstart_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", "")
      if ok then
        if tonumber(number) ~= nil then
          undo_stack = undo_stack + 1 
          mod_stack_name [undo_stack] = "trimstart"
          mod_stack_parm1 [undo_stack] = number
          mod_stack_parm2 [undo_stack] = ""
          WriteCurrentModifier()
        else
          reaper.MB("Please, type a number!", "This is not a number!", 0)
        end
      end
    end
  end

  function trimend_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", "")
      if ok then
        if tonumber(number) ~= nil then
          undo_stack = undo_stack + 1 
          mod_stack_name [undo_stack] = "trimend"
          mod_stack_parm1 [undo_stack] = number
          mod_stack_parm2 [undo_stack] = ""
          WriteCurrentModifier()
        else
          reaper.MB("Please, type a number!", "This is not a number!", 0)
        end
      end
    end
  end
  
  function keep_btn.onClick()
    if (what == "tracks" and CheckTracks()) or (what == "items" and CheckItems()) then
      local ok, text = reaper.GetUserInputs("Keep (s -> from start, e -> end)", 1, "Specify mode and number:", "")
      if ok then
        if text:match("[seSE]%s?%d+") then
          undo_stack = undo_stack + 1 
          mod_stack_name [undo_stack] = "keep"
          mod_stack_parm1 [undo_stack] = text
          mod_stack_parm2 [undo_stack] = ""
          WriteCurrentModifier()      
        else
          reaper.MB("Please type s or e followed by the number of characters you want to keep!\nExamples: s8 , E5 , S03 , e 12", "Not valid input!", 0)        
        end
      end
    end  
  end
 
  function UP_btn.onClick()
    if what == "tracks" and CheckTracks() then
      indexed_track = indexed_track - 1
      if indexed_track < 1 then indexed_track = 1 end
    elseif what == "items" and CheckItems() then
      indexed_item = indexed_item - 1
      if indexed_item < 1 then indexed_item = 1 end
    end
  end
  
  function DOWN_btn.onClick()
    if what == "tracks" and CheckTracks() then
      indexed_track = indexed_track + 1
    elseif what == "items" and CheckItems() then
      indexed_item = indexed_item + 1
    end
  end
  
  function UP_btn.onClickPress()
    if what == "tracks" and CheckTracks() then
      indexed_track = indexed_track - 1
      if indexed_track < 1 then indexed_track = 1 end
    elseif what == "items" and CheckItems() then
      indexed_item = indexed_item - 1
      if indexed_item < 1 then indexed_item = 1 end
    end
  end
    
  function DOWN_btn.onClickPress()
    if what == "tracks" and CheckTracks() then
      indexed_track = indexed_track + 1
    elseif what == "items" and CheckItems() then
      indexed_item = indexed_item + 1
    end
  end
  
  function reset_btn.onClick()
    init_tables()
    undo_btn.help_text = "Nothing to undo"
  redo_btn.help_text = "Nothing to redo" -- gianfini fix
  end
  
  function undo_btn.onClick()
    if undo_stack > 0 then
      undo_stack = undo_stack - 1
      redo_stack = redo_stack + 1
    SaveNextRedo()  -- gianfini: needed to manage cornerstone case of modifier no actually modifying anything without having to reset the redo stack
    end
    WriteModifiersStack()
  end
  
  function redo_btn.onClick()
    if redo_stack > 0 then
      undo_stack = undo_stack + 1
      redo_stack = redo_stack - 1
    if redo_stack > 0 then SaveNextRedo() end  -- gianfini: needed to manage cornerstone case of modifier no actually modifying anything without having to reset the redo stack
    end
    WriteModifiersStack()
  end
  
  function commit_btn.onClick()
    if undo_stack > 0 then -- gianfini changed to check undo_stack and not has_changed
      if what == "tracks" and CheckTracks() then
        reaper.Undo_BeginBlock()
        for i=0, trackCount-1 do
          local trackId = reaper.GetSelectedTrack(0, i)
          reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(ToBeTrackNames[reaper.GetTrackGUID(trackId)]), 1)
        end
        reaper.Undo_EndBlock("Track name manipulation", 1)
      elseif what == "items" and CheckItems() then
        reaper.Undo_BeginBlock()
        for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake = reaper.GetActiveTake(itemId)
          if acttake then
            reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]), 1)
          else
            reaper.ULT_SetMediaItemNote(itemId, tostring(ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)]))
          end
        end
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("Item name manipulation", 4)
      end
      init_tables()
      undo_btn.help_text = "Nothing to undo"
      redo_btn.help_text = "Nothing to redo"
      has_changed = 0
    end
  end
  
end -------------------------------- end of init() function ------------------------------------------


init()
reaper.defer(main)

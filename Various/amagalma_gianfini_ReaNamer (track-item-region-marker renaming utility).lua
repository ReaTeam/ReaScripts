-- @description ReaNamer (track-item-region-marker renaming utility)
-- @author amagalma & gianfini
-- @version 1.47
-- @changelog
--   - Fixed bugs in Markers or Regions mode and time selection present
-- @provides
--   amagalma_ReaNamer Replace Help.lua
--   amagalma_ReaNamer utf8data.lua
-- @link
--   http://forum.cockos.com/showthread.php?t=190534
--   http://forum.cockos.com/showthread.php?t=194414
-- @donation https://www.paypal.me/amagalma
-- @about
--   # Utility to manipulate track, item, region or marker names
--
--   - Manipulate track/item/region/marker names (prefix/suffix, trim start/end, keep, clear, uppercase/lowercase, swap case/capitalize/titlecase, replace, strip leading & trailing whitespaces).
--   - Mode (tracks or items) is automatically chosen when the script starts. Then to change mode click on appropriate button.
--   - When satisfied with the modifications (which can be previewed in the list), COMMIT button writes the values to tracks/items/regions/markers and creates an Undo point in Reaper's Undo History
--   - UTF-8 support for case-changing functions
--   - SWS / S&M extension and JS_ReaScriptAPI are required
--
--   Key Shortcuts:
--    Esc to close script
--    Ctrl+Enter to Commit
--    Ctrl+T for Tracks mode
--    Ctrl+I for Items mode
--    Ctrl+R for Regions mode
--    Ctrl+M for Markers mode
--    Ctrl+Z for Undo
--    Ctrl+Shift+Z for Redo
--    Alt+A for swAp case
--    Alt+C for Clear
--    Alt+E for trim End
--    Alt+K for Keep
--    Alt+L for Lowercase
--    Alt+N for Number
--    Alt+P for Prefix
--    Alt+R for Replace
--    Alt+S for trim Start
--    Alt+T for Titlecase
--    Alt+U for Uppercase
--    Alt+W for strip Whitespaces
--    Alt+X for suffiX
--    Alt+Z for capitaliZe

-- Many thanks to spk77 and to Lokasenna for their code and help! :)

-----------------------------------------------------------------------------------------------

local version = "1.47"

if not reaper.APIExists( "BR_Win32_FindWindowEx" ) then
  reaper.MB( "SWS / S&M extension is required for this script to work", "SWS / S&M extension is not installed!", 0 )
  return
end

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

local btn_DOWN_can_move, btn_height, win_border, win_double_vert_border, win_h, win_vert_border, win_w


--//////////////////
--// Button class //
--//////////////////


local Button = class(
                      function(btn,x1,y1,w,h,state_count,state,visual_state,lbl,help_text, underline)
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
                        btn.underline = underline
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
  if self.help_text:find("\n") then
    gfx.y = win_h - math.floor(win_vert_border/1.7)
  else
    gfx.y = win_h
  end
  local hwidth = gfx.measurestr(self.help_text)
  gfx.x = win_border
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
    gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth + 1
    if self.__mouse_state == 1 and self.active == 1 then
      gfx.y = gfx.y + 1
      --gfx.a = self.lbl_a*0.5
      temp_lbl_a = self.lbl_a*0.6 -- temp var for transparency
    elseif self.__mouse_state == 0 and self.active == 1 then
      temp_lbl_a = self.lbl_a*0.9
    end
    if self.underline then
      gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,temp_lbl_a)
      gfx.printf(self.label:sub(1,self.underline-1))
      gfx.set(1,1,.75,temp_lbl_a)
      gfx.printf((self.label:sub(self.underline,self.underline)):upper())
      gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,temp_lbl_a)
      gfx.printf(self.label:sub(self.underline+1))
    else
      gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,temp_lbl_a)
      gfx.printf(self.label)
    end
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

-- UTF8 support
dofile((debug.getinfo(1,'S')).source:match[[^@?(.*[\/])[^\/]-$]] .. "amagalma_ReaNamer utf8data.lua")
local lower = utf8_lc_uc
local upper = utf8_uc_lc
utf8_lc_uc, utf8_uc_lc = nil, nil


-- Global variables
local has_changed, what, trackCount, indexed_track, scroll_line_selected, itemCount, indexed_item
local undo_stack, ToBeTrackNames, OriginalTrackNames, ToBeItemNames, OriginalItemNames, redo_stack
local TotalRegionCount, regionCount, ToBeRegionNames, OriginalRegionNames = 0, 0
local TotalMarkerCount, markerCount, ToBeMarkerNames, OriginalMarkerNames = 0, 0
local mod_stack_name, mod_stack_parm1, mod_stack_parm2 = {}, {}, {} -- management of modifiers' undo stack
local scroll_list_x, scroll_list_y, scroll_list_w, scroll_list_h, scroll_line_selected
local matchCase = "y"
local give_back_focus = false
gfx.setfont(1, "Arial", 19)
local strw, strh = gfx.measurestr("Strip leading & trailing whitespaces")
local NAME = "ReaNamer  v"..version.."   -   Track/Item/Region/Marker Renaming Utility"
local script_hwnd
local utf8_char = "[%z\1-\127\194-\244][\128-\191]*"

-- last_mouse_state & mouse_state_time must be globals


--------------------------------------------------------------------------------------------

local function GiveBackFocus()
  if reaper.ValidatePtr2( 0, script_hwnd, "HWND" ) then
    reaper.BR_Win32_SetFocus( script_hwnd )
  end
end

local function round(num)
  return math.floor(num * 10 + 0.5) / 10
end


local function f()
  gfx.setfont(1, "Arial", 19)
end


local function fsmall()
  gfx.setfont(3, "Courier New", 14)
end

local function ignoreCase(str)
  return str:gsub( "(%a)", function(a)
  return "[" .. a:upper() .. a:lower() .. "]" end )
end

-- Needed variables
fsmall()
local lstw_small, lsth_small = gfx.measurestr("Strip leading & trailing whitespaces")


local function IsTable(t) return type(t) == 'table' end


local function Window_At_Center(w, h) -- Lokasenna function
  local l, t, r, b = 0, 0, w, h
  local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)
  local x, y = (screen_w - w) / 2, (screen_h - h) / 2
  gfx.init(NAME, w, h, 0, x, y)
  script_hwnd = reaper.BR_Win32_FindWindowEx( 0, 0, 0, NAME, 0, true )
end


local function swapcase(str)
  local t, n = {}, 0
  for letter in str:gmatch(utf8_char) do
    if upper[letter] then
      letter = upper[letter]
    elseif lower[letter] then
      letter = lower[letter]
    elseif letter:match("%l") then
      letter = letter:upper()
    elseif letter:match("%u") then
      letter = letter:lower()
    end
    n = n + 1
    t[n] = letter
  end
  return table.concat(t)
end


local function CheckTracks()
  if reaper.CountSelectedTracks(0) < 1 then
    reaper.MB("Please select at least one track", "No tracks selected!", 0)
    GiveBackFocus()
  else
    return true
  end
end


local function CheckItems()
  if reaper.CountSelectedMediaItems(0) < 1 then
    reaper.MB("Please select at least one item", "No items selected!", 0)
    GiveBackFocus()
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

local function Check()
  if what == "tracks" then return CheckTracks()
  elseif what == "items" then return CheckItems()
  elseif what == "regions" then
    if regionCount > 0 then
      return true
    else
      reaper.MB("Please select at least one region", "No regions selected!", 0)
      GiveBackFocus()
      return false
    end
  elseif what == "markers" then
    if markerCount > 0 then
      return true
    else
      reaper.MB("Please select at least one marker", "No markers selected!", 0)
      GiveBackFocus()
      return false
    end
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

local function AllRegionNames() -- in Time Selection
  local st, en = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
  if st == en then
    st, en = -math.huge, math.huge
  else
    st, en = st+.01, en-.01 -- exclude adjacent regions
  end
  local marker_cnt, _, regions = reaper.CountProjectMarkers( 0 )
  local table = {}
  local table2 = {}
  local count = 0
  for i = 0, marker_cnt-1 do
    local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( i )
    if isrgn then
      if (st < pos and en < pos) or (st > rgnend and en > rgnend) then
        -- do not add
      else
        table[markrgnindexnumber] = {pos, rgnend, name}
        count = count + 1
        table2[count] = markrgnindexnumber
      end
    end
  end
  return table, table2, (regions and regions or 0)
end

local function AllMarkerNames() -- in Time Selection
  local st, en = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
  if st == en then
    st, en = -math.huge, math.huge
  end
  local marker_cnt, markers = reaper.CountProjectMarkers( 0 )
  local table = {}
  local table2 = {}
  local count = 0
  for i = 0, marker_cnt-1 do
    local _, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( i )
    if not isrgn then
      if pos >= st and pos <= en then
        table[markrgnindexnumber] = {pos, name}
        count = count + 1
        table2[count] = markrgnindexnumber
      end
    end
  end
  return table, table2, (markers and markers or 0)
end

-- Replace button Help if "amagalma_ReaNamer Replace Help.lua" cannot be loaded
local function InfoReplacePattern()
  local info = [[
----- Track/item Name Manipulation: Replace Pattern Help -----


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
  gfx.y = win_h
  local help_text_list = "Click on a line to edit a single list item"
  local hwidth = gfx.measurestr(help_text_list)
  gfx.x = win_border
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
  num_displayed_tracks = 0
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
    num_displayed_lines = last_s_line - first_s_line + 1
    local digits = #tostring(trackCount)
    for i = first_s_line, last_s_line do
      local trt = reaper.GetSelectedTrack(0, i)
      local track_num = reaper.GetMediaTrackInfo_Value(trt,"IP_TRACKNUMBER")
      DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small),
      string.format("%" .. digits .. "i. ",track_num)..tostring(ToBeTrackNames[reaper.GetTrackGUID(trt)]))
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
    num_displayed_lines = last_s_line - first_s_line + 1
    local digits = #tostring(itemCount)
    for i = first_s_line, last_s_line do
      local itemId = reaper.GetSelectedMediaItem(0, i)
      local acttake =  reaper.GetActiveTake(itemId)
      if acttake then
        DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small),
        string.format("%" .. digits .. "i. ",i+1) .. tostring(ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]))
      else
        local name = ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)]
        if IsTable(name) then name = table.concat(name, " | ") end
        DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small),
        string.format("%" .. digits .. "i. ",i+1) .. tostring(name))
      end
    end
  elseif what == "regions" then
    local rg_table, rg_index = AllRegionNames()
    regionCount = #rg_index
    if regionCount == 0 then return end
    num_displayed_lines = 12
    first_s_line, last_s_line = indexed_region, indexed_region + num_displayed_lines - 1
    last_s_line = last_s_line <= regionCount and last_s_line or regionCount
    if regionCount > num_displayed_lines and last_s_line < regionCount then
      btn_DOWN_can_move = 1
    else
      btn_DOWN_can_move = 0
    end
    local digits = #tostring(regionCount)
    for i = first_s_line, last_s_line do
      DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small),
      string.format("%" .. digits .. "i. ",rg_index[i]) .. tostring(ToBeRegionNames[rg_index[i]][3]))
    end
  elseif what == "markers" then
    local mr_table, mr_index = AllMarkerNames()
    markerCount = #mr_index
    if markerCount == 0 then return end
    num_displayed_lines = 12
    first_s_line, last_s_line = indexed_marker, indexed_marker + num_displayed_lines - 1
    last_s_line = last_s_line <= markerCount and last_s_line or markerCount
    if markerCount > num_displayed_lines and last_s_line < markerCount then
      btn_DOWN_can_move = 1
    else
      btn_DOWN_can_move = 0
    end
    local digits = #tostring(markerCount)
    for i = first_s_line, last_s_line do
      DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small),
      string.format("%" .. digits .. "i. ",mr_index[i]) .. tostring(ToBeMarkerNames[mr_index[i]][2]))
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
      modifier_name = "PREFIX '" .. parm1 .. "'"
    elseif last_modifier == "suffix" then
      modifier_name = "SUFFIX '" .. parm1 .. "'"
    elseif last_modifier == "trimstart" then
      modifier_name = "TRIM START " .. parm1
    elseif last_modifier == "trimend" then
      modifier_name = "TRIM END " .. parm1
    elseif last_modifier == "keep" then
      modifier_name = "KEEP '" .. parm1 .. "'"
    elseif last_modifier == "replace" then
      if parm2 ~= "" then
        modifier_name = "REPLACE '" .. parm1 .. "'\nWITH '" .. parm2 .. "'"
      else
        modifier_name = "REPLACE: removed '" .. parm1 .. "'"
      end
    elseif last_modifier == "number" then
      modifier_name = "NUMBER '" .. parm1 .. "'"
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
      modifier_name = "PREFIX '" .. parm1 .. "'"
    elseif last_modifier == "suffix" then
      modifier_name = "SUFFIX '" .. parm1 .. "'"
    elseif last_modifier == "trimstart" then
      modifier_name = "TRIM START " .. parm1
    elseif last_modifier == "trimend" then
      modifier_name = "TRIM END " .. parm1
    elseif last_modifier == "keep" then
      modifier_name = "KEEP '" .. parm1 .. "'"
    elseif last_modifier == "replace" then
      if parm2 ~= "" then
        modifier_name = "REPLACE '" .. parm1 .. "'\nWITH '" .. parm2 .. "'"
      else
        modifier_name = "REPLACE: removed '" .. parm1 .. "'"
      end
    elseif last_modifier == "number" then
      modifier_name = "NUMBER '" .. parm1 .. "'"
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
    redo_btn.help_text = "Redo " .. modifier_name
  else
    redo_btn.help_text = "Nothing to redo"
  end
end

local function to_capital(letter)
  if lower[letter] then
    return lower[letter]
  else
    return letter:upper()
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
      if matchCase:find("[Yy]") then
        newName = string.gsub(newName, parm1, parm2)
      else
        newName = string.gsub(newName, ignoreCase(parm1), parm2)
      end
    end
  elseif modifier == "number" then
    if parm1 ~= "" then
      local mode, number, digits, separator = parm1:match("([psPS])%s?(%d+)\n(%d+)\n(.*)")
      number = (what == "regions" or what == "markers") and number-1 or number
      if mode:match("[pP]") then
        newName = string.format("%0" .. digits .. "d", math.floor(number+i)) .. separator .. newName
      else
        newName = newName .. separator .. string.format("%0" .. digits .. "d", math.floor(number+i))
      end
    end
  elseif modifier == "upper" then
    local t, n = {}, 0
    for letter in newName:gmatch(utf8_char) do
      if lower[letter] then
        letter = lower[letter]
      else
        letter = letter:upper()
      end
      n = n + 1
      t[n] = letter
    end
    newName = table.concat(t)
  elseif modifier == "lower" then
    local t, n = {}, 0
    for letter in newName:gmatch(utf8_char) do
      if upper[letter] then
        letter = upper[letter]
      else
        letter = letter:lower()
      end
      n = n + 1
      t[n] = letter
    end
    newName = table.concat(t)
  elseif modifier == "swap" then
    newName = swapcase(newName)
  elseif modifier == "capitalize" then
    local t, n = {}, 0
    for letter in newName:gmatch(utf8_char) do
      if n == 0 then
        letter = to_capital(letter)
      end
      n = n + 1
      t[n] = letter
    end
    newName = table.concat(t)
  elseif modifier == "title" then
    local t, n = {}, 0
    for letter in newName:gmatch(utf8_char) do
      if not t[n] or (t[n] and (t[n]):match("%s")) then
        letter = to_capital(letter)
      end
      n = n + 1
      t[n] = letter
    end
    newName = table.concat(t)
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
  elseif what == "regions" then
    local rg_table, rg_index = AllRegionNames()
    regionCount = #rg_index
    for i=1, regionCount do
      local prevName = ToBeRegionNames[rg_index[i]][3]
      if undo_stack > 0 then
        local modifier = mod_stack_name[undo_stack]
        local parm1 = mod_stack_parm1[undo_stack]
        local parm2 = mod_stack_parm2[undo_stack]
        newName = ApplyModifier(prevName, modifier, parm1, parm2, i) -- write a single modifier to newName based on prevName
      end
      -- Update list
      if newName ~= prevName then
        ToBeRegionNames[rg_index[i]][3] = newName
        has_changed = 1
      end
    end
  elseif what == "markers" then
    local mr_table, mr_index = AllMarkerNames()
    markerCount = #mr_index
    for i=1, markerCount do
      local prevName = ToBeMarkerNames[mr_index[i]][2]
      if undo_stack > 0 then
        local modifier = mod_stack_name[undo_stack]
        local parm1 = mod_stack_parm1[undo_stack]
        local parm2 = mod_stack_parm2[undo_stack]
        newName = ApplyModifier(prevName, modifier, parm1, parm2, i) -- write a single modifier to newName based on prevName
      end
      -- Update list
      if newName ~= prevName then
        ToBeMarkerNames[mr_index[i]][2] = newName
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
  elseif what == "regions" then
    local rg_table, rg_index = AllRegionNames()
    regionCount = #rg_index
    for i=1, regionCount do
    local newName = OriginalRegionNames[rg_index[i]][3]
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
    ToBeRegionNames[rg_index[i]][3] = newName
    end
  elseif what == "markers" then
    local mr_table, mr_index = AllMarkerNames()
    markerCount = #mr_index
    for i=1, markerCount do
    local newName = OriginalMarkerNames[mr_index[i]][2]
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
    ToBeMarkerNames[mr_index[i]][2] = newName
    end
  end
  UpdateUndoHelp()
  UpdateRedoHelp()
end


local function get_line_name(line_num)  -- get the text of line in scroll list and corresponding Reaper track num
  if what == "tracks" then
    local trackId = reaper.GetSelectedTrack(0, line_num)
    if trackId then
      return ToBeTrackNames[reaper.GetTrackGUID(trackId)], reaper.GetMediaTrackInfo_Value(trackId,"IP_TRACKNUMBER")
    end
  elseif what == "regions" then
    if RegionNamesIndex[line_num+1] then
      return ToBeRegionNames[RegionNamesIndex[line_num+1]][3], RegionNamesIndex[line_num+1]
    end
  elseif what == "markers" then
    if MarkerNamesIndex[line_num+1] then
      return ToBeMarkerNames[MarkerNamesIndex[line_num+1]][2], MarkerNamesIndex[line_num+1]
    end
  else
    local itemId = reaper.GetSelectedMediaItem(0, line_num)
    if not itemId then return end
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
  local indexed_obj = 1  -- gianfini newnew
  -- local obj_name, track_num = 1  -- gianfini fix single track modify
  if what == "tracks" then  -- gianfini newnew
    indexed_obj = indexed_track
  elseif what == "regions" then
    indexed_obj = indexed_region
  elseif what == "markers" then
    indexed_obj = indexed_marker
  else
    indexed_obj = indexed_item
  end
  local obj_name, track_num = get_line_name(indexed_obj + line_num - 2)  -- gianfini newnew
  if not obj_name or not track_num then return end
  if what == "tracks" then
    line_object = string.format("track %i",track_num)
  elseif what == "regions" then
    line_object = string.format("region %i",track_num)
    line_num = line_num + 1
  elseif what == "markers" then
    line_object = string.format("marker %i",track_num)
    line_num = line_num + 1
  else
    line_object = "item"
  end
  local ok, text = reaper.GetUserInputs("Rename " .. line_object, 1, "Name:,extrawidth=" .. tostring(math.floor(scroll_list_w*3/5)), obj_name)
  GiveBackFocus()
  if ok then
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "single_line_edit"
    mod_stack_parm1 [undo_stack] = text
    mod_stack_parm2 [undo_stack] = tostring(line_num + indexed_obj - 1)  -- gianfini fix single track modify
    WriteCurrentModifier()
  end
end


local function is_mouse_on_list_Down()
  fsmall()
  local lstw_small, lsth_small = gfx.measurestr("Strip leading & trailing whitespaces") -- gianfini example string to set width

  scroll_line_selected = math.floor((gfx.mouse_y - scroll_list_y + lsth_small) / lsth_small)
  if (gfx.mouse_x > scroll_list_x and gfx.mouse_x < (scroll_list_x + scroll_list_w) and gfx.mouse_y > scroll_list_y and gfx.mouse_y < (scroll_list_y + scroll_list_h) and 
      last_mouse_state == 0) then
    set_list_help_text()
    if tonumber(scroll_line_selected) and tonumber(num_displayed_lines) and (gfx.mouse_cap & 1 == 1 and tonumber(num_displayed_lines) >= scroll_line_selected) then return true end
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
    ToBeRegionNames, RegionNamesIndex = nil, nil
    OriginalRegionNames = nil
    indexed_region = nil
    TotalRegionCount = 0
    ToBeMarkerNames, MarkerNamesIndex = nil, nil
    OriginalMarkerNames = nil
    indexed_marker = nil
    TotalMarkerCount = 0
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
    ToBeRegionNames, RegionNamesIndex = nil, nil
    OriginalRegionNames = nil
    indexed_region = nil
    TotalRegionCount = 0
    ToBeMarkerNames, MarkerNamesIndex = nil, nil
    OriginalMarkerNames = nil
    indexed_marker = nil
    TotalMarkerCount = 0
  elseif what == "regions" then
    ToBeRegionNames, RegionNamesIndex, TotalRegionCount = AllRegionNames()
    OriginalRegionNames = AllRegionNames()
    indexed_region = 1
    undo_stack = 0
    redo_stack = 0
    -- free memory
    ToBeTrackNames = nil
    OriginalTrackNames = nil
    indexed_track = nil
    ToBeItemNames = nil
    OriginalItemNames = nil
    indexed_item = nil
    ToBeMarkerNames, MarkerNamesIndex = nil, nil
    OriginalMarkerNames = nil
    indexed_marker = nil
    TotalMarkerCount = 0
  elseif what == "markers" then
    ToBeMarkerNames, MarkerNamesIndex, TotalMarkerCount = AllMarkerNames()
    OriginalMarkerNames = AllMarkerNames()
    indexed_marker = 1
    undo_stack = 0
    redo_stack = 0
    -- free memory
    ToBeTrackNames = nil
    OriginalTrackNames = nil
    indexed_track = nil
    ToBeItemNames = nil
    OriginalItemNames = nil
    indexed_item = nil
    ToBeRegionNames, RegionNamesIndex = nil, nil
    OriginalRegionNames = nil
    indexed_region = nil
    TotalRegionCount = 0
  end
  btn_DOWN_can_move = 0
end


local prev_st, prev_en = reaper.GetSet_LoopTimeRange2( 0, 0, 0, 0, 0, 0 )
local getchar
local mousecap
local key_state
local last_key_time = reaper.time_precise()
local keys = {
  [13] = { [4] = function() commit_btn.onClick() end },
  [65] = { [16] = function() swap_btn.onClick() end },
  [67] = { [16] = function() clear_btn.onClick() end },
  [69] = { [16] = function() trimend_btn.onClick() end },
  [73] = { [4] = function() Items_btn.onClick() end },
  [75] = { [16] = function() keep_btn.onClick() end },
  [76] = { [16] = function() lower_btn.onClick() end },
  [77] = { [4] = function() Markers_btn.onClick() end },
  [78] = { [16] = function() number_btn.onClick() end },
  [80] = { [16] = function() prefix_btn.onClick() end },
  [82] = { [16] = function() replace_btn.onClick() end, [4] = function() Regions_btn.onClick() end }, 
  [83] = { [16] = function() trimstart_btn.onClick() end },
  [84] = { [16] = function() title_btn.onClick() end, [4] = function() Tracks_btn.onClick() end }, 
  [85] = { [16] = function() upper_btn.onClick() end },
  [87] = { [16] = function() strip_btn.onClick() end },
  [88] = { [16] = function() suffix_btn.onClick() end },
  [90] = { [16] = function() capitalize_btn.onClick() end, [4] = function() undo_btn.onClick() end, [12] = function() redo_btn.onClick() end }
}
local key_series = { 13, 65, 67, 69, 73, 75, 76, 77, 78, 80, 82, 83, 84, 85, 87, 88, 90 }

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
  f(); Regions_btn:draw()
  f(); Markers_btn:draw()
  f(); commit_btn:draw()
  f(); reset_btn:draw()
  f(); undo_btn:draw()
  f(); redo_btn:draw()
  f(); UP_btn:draw()
  f(); DOWN_btn:draw()
  DrawDividingLines()

  --[[gfx.x, gfx.y = 329, 334
  gfx.set(1,1,1,0.44)
  gfx.setfont(2, "Arial", 14)
  gfx.printf("amagalma\n&  gianfini")--]]

  if what == "tracks" then
    Tracks_btn:set_color1()
    Items_btn:set_color2()
    Regions_btn:set_color2()
    Markers_btn:set_color2()
  elseif what == "items" then
    Items_btn:set_color1()
    Tracks_btn:set_color2()
    Regions_btn:set_color2()
    Markers_btn:set_color2()
  elseif what == "regions" then
    Regions_btn:set_color1()
    Tracks_btn:set_color2()
    Items_btn:set_color2()
    Markers_btn:set_color2()
  elseif what == "markers" then
    Markers_btn:set_color1()
    Tracks_btn:set_color2()
    Items_btn:set_color2()
    Regions_btn:set_color2()
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

  if (what == "tracks" and indexed_track > 1) or (what == "items" and indexed_item > 1) or
     (what == "regions" and indexed_region > 1) or (what == "markers" and indexed_marker > 1)
  then
    UP_btn:set_color_updown_can_move(0)
  else
    UP_btn:set_color_updown()
  end
  if btn_DOWN_can_move == 1 then
    DOWN_btn:set_color_updown_can_move(1)
  else
    DOWN_btn:set_color_updown()
  end
---HERE
  if what == "regions" then
    local _, _, num_regions = reaper.CountProjectMarkers(0)
    local st, en = reaper.GetSet_LoopTimeRange2( 0, 0, 0, 0, 0, 0 )
    if st ~= prev_st or en ~= prev_en or num_regions ~= TotalRegionCount then
      init_tables()
      prev_st, prev_en = st, en
    end
  elseif what == "markers" then
    local _, num_markers = reaper.CountProjectMarkers( 0 )
    local st, en = reaper.GetSet_LoopTimeRange2( 0, 0, 0, 0, 0, 0 )
    if st ~= prev_st or en ~= prev_en or num_markers ~= TotalMarkerCount then
      init_tables()
      prev_st, prev_en = st, en
    end
  elseif what == "items" then
    if reaper.CountSelectedMediaItems( 0 ) ~= itemCount then
      init_tables()
    end
  elseif what == "tracks" then
    if reaper.CountSelectedTracks( 0 ) ~= trackCount then
      init_tables()
    end
  end

  RefreshTrackItemList(scroll_list_x, scroll_list_y, scroll_list_w, scroll_list_h)
  if is_mouse_on_list_Down() then modify_single_line(tonumber(scroll_line_selected)) end

  mousecap = gfx.mouse_cap
  getchar = gfx.getchar()

  -- Check left mouse btn state
  if mousecap & 1 == 0 then
    last_mouse_state = 0
    mouse_state_time = nil
  else
    last_mouse_state = 1
    if not mouse_state_time then mouse_state_time = reaper.time_precise() end

  end
  -- KEY SHORTCUTS -------------

  -- Alt
  if mousecap == 16 then

    swap_btn.underline = 3
    clear_btn.underline = 1
    trimend_btn.underline = 6
    keep_btn.underline = 1
    lower_btn.underline = 1
    number_btn.underline = 1
    prefix_btn.underline = 1
    replace_btn.underline = 1
    trimstart_btn.underline = 6
    title_btn.underline = 1
    upper_btn.underline = 1
    strip_btn.underline = 26
    suffix_btn.underline = 6
    capitalize_btn.underline = 9

  else

    swap_btn.underline = nil
    clear_btn.underline = nil
    trimend_btn.underline = nil
    keep_btn.underline = nil
    lower_btn.underline = nil
    number_btn.underline = nil
    prefix_btn.underline = nil
    replace_btn.underline = nil
    trimstart_btn.underline = nil
    title_btn.underline = nil
    upper_btn.underline = nil
    strip_btn.underline = nil
    suffix_btn.underline = nil
    capitalize_btn.underline = nil

  end
  
  if mousecap == 4 or mousecap == 16 or mousecap == 12 then
    key_state = reaper.JS_VKeys_GetState(-0.2)
    local time = reaper.time_precise()
    if time - last_key_time > 0.2 then
      for i = 1, 17 do
        if key_state:byte(key_series[i]) ~= 0 and keys[key_series[i]] and keys[key_series[i]][mousecap] then
          --reaper.ShowConsoleMsg( "pressed " .. string.char(key_series[i]) .. "\n")
          keys[key_series[i]][mousecap]()
          last_key_time = time
          break
        end
      end
    end
  end

  -- KEY SHORTCUTS -------------

  gfx.update()
  if getchar < 0 or getchar == 27 then
    local _, x, y, _, _ = gfx.dock(-1, 0, 0, 0, 0)
    reaper.SetExtState("Track-Item Name Manipulation", "x position", x, 1)
    reaper.SetExtState("Track-Item Name Manipulation", "y position", y, 1)
    gfx.quit()
    return
  else
    reaper.defer(main)
  end

end

local function init() -- INITIALIZATION --------------------------------------------------------------
  -- Get current context (tracks or items)
  local context = reaper.GetCursorContext2(true)
  if (context == 1 and reaper.CountSelectedMediaItems(0) > 0) then what = "items" else what = "tracks" end
  init_tables()
  f() -- set font
  gfx.clear = 0x2f1504
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
    gfx.init(NAME, win_w, win_h + 30, 0, x, y)
    script_hwnd =  reaper.BR_Win32_FindWindowEx( 0, 0, 0, NAME, 0, true )
  else
    Window_At_Center(win_w, win_h)
  end

  -- parameters: Button(x1,y1,w,h,state_count,state,visual_state,lbl,help_text)

  -- 1st raw: Trim, Keep ------------------------------------------------------
  local width = math.floor((win_w - 4*win_border)/3)
  local height = btn_height
  local x_pos = win_border
  local y_pos = win_vert_border
  trimstart_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Trim Start",
                    "Removes specified number of characters from the start")

  local x_pos = win_border*2 + width
  trimend_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Trim end",
                  "Removes specified number of characters from the end")

  local x_pos = win_border*3 + width*2
  keep_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Keep",
      "Keeps only specified number of chars\n(s-> from start | e-> from end)")

  -- 2nd raw: Replace Clear ---------------------------------------------------
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  replace_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Replace",
  "Replaces all instances of the pattern with replacement\n(Right click button for help)")

  local x_pos = win_border*2 + width
  clear_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Clear", "Clears all names!")

  -- 3rd raw: Prefix Suffix ---------------------------------------------------
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  prefix_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Prefix",
                  "Inserts text at the begining")

  local x_pos = win_border*2 + width
  suffix_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Suffix", "Appends text to the end")

  -- 4th raw: Numbering -------------------------------------------------------
  local width = win_w - 2*win_border
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  number_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Number",
  "Adds index numbers at the start or end\n(p->prefix | s->suffix, then the starting number)")

  -- 5th raw: Upper/Lower case ------------------------------------------------
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  upper_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Uppercase",
              "Converts all letters to UPPERCASE")

  local x_pos = win_border*2 + width
  lower_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Lowercase",
              "Converts all letters to lowercase")

  -- 6th raw: Swap case, Capitalize, Titlecase --------------------------------
  local width = math.floor((win_w - 4*win_border)/3)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + math.floor(win_vert_border/2)
  swap_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Swap case",
              "Inverts the case of each letter\n(eg GuiTar => gUItAR)")

  local x_pos = win_border*2 + width
  capitalize_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Capitalize",
                    "Capitalizes the very first letter")

  local x_pos = win_border*3 + width*2
  title_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Titlecase",
                    "Capitalizes The First Letter Of Each Word")

  -- 7th raw: Strip whitespaces -----------------------------------------------
  local width = win_w - 2*win_border
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  strip_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, 
  "Strip leading & trailing whitespaces", "Removes all leading and trailing whitespaces" )

  -- 8th raw: Reset, Undo/Redo and Commit -------------------------------------
  local width = (win_w -  3.5*win_border)/5
  local x_pos = win_border
  local y_pos = y_pos + btn_height + math.floor(win_vert_border*0.8)
  local height = btn_height*2
  reset_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "RESET",
              "Reset all modifiers and redo states")

  local x_pos = 1.5*win_border + width
  undo_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "UNDO", "Nothing to undo")

  local x_pos = 2*win_border + 2*width
  redo_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "REDO", "Nothing to redo")

  local x_pos = 2.5*win_border + 3*width
  commit_btn = Button(x_pos, y_pos, width*2, height, 2, 0, 0, "COMMIT",
                "Commit all modifications")

  -- 9th raw: Tracks/Items/Regions/Markers mode --------------------------------------------
  local height = btn_height
  local width = math.floor((win_w - 5*win_border)/4)
  local x_pos = win_border
  local y_pos = y_pos + height*2 + win_double_vert_border
  Tracks_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Tracks",
              "Click to select Tracks mode      [ Ctrl + T ]")

  local x_pos = win_border*2 + width
  Items_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Items",
              "Click to select Items mode      [ Ctrl + I ]")

  local x_pos = win_border*3 + width*2
  Regions_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Regions",
  "Click to select Regions mode      [ Ctrl + R ]\nIf Time Selection, then only regions \z
  touching the TS, else all regions")

  local x_pos = win_border*4 + width*3
  Markers_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, "Markers",
  "Click to select Markers mode      [ Ctrl + M ]\nIf Time Selection, then only markers \z
  touching the TS, else all markers")

  --- scroll list measures ----------------------------------------------------
  scroll_list_x = win_border
  scroll_list_y = y_pos + height + win_double_vert_border
  scroll_list_w = win_w - 2*win_border - 4*win_border
  scroll_list_h = win_h - scroll_list_y - win_vert_border
  indexed_track = 1
  fsmall()

  --- scroll table buttons UP and DOWN ----------------------------------------
  local label, help = "U", "Scrolls Up names"
  local width, height = gfx.measurestr(label)
  height = btn_height
  width = math.floor(width*4)
  x_pos = win_w - width - win_border
  y_pos = y_pos + height + win_double_vert_border - math.floor(win_vert_border/3.3)
  UP_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  local label, help = "D", "Scrolls Down names"
  y_pos = y_pos + scroll_list_h - height + win_vert_border/3
  DOWN_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  local function UpdateTrackManager()
    -- "Mirror track selection must be on"
    local flag = ({reaper.BR_Win32_GetPrivateProfileString( "trackmgr", "flags", "",
                   reaper.get_ini_file() )})[2]
    if flag and flag ~= "" and tonumber(flag) & 8 == 8 then
      local hwnd = reaper.BR_Win32_FindWindowEx( 0, 0, "#32770", "Track Manager", true, true )
      if hwnd then
        local focus = reaper.BR_Win32_GetFocus()
        reaper.BR_Win32_SetFocus( hwnd )
        reaper.BR_Win32_SetFocus( focus )
      end
    end
  end

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

  function Regions_btn.onClick()
    what = "regions"
    init_tables()
    undo_btn.help_text = "Nothing to undo"
    redo_btn.help_text = "Nothing to redo"
    has_changed = 0
  end
  
  function Markers_btn.onClick()
    what = "markers"
    init_tables()
    undo_btn.help_text = "Nothing to undo"
    redo_btn.help_text = "Nothing to redo"
    has_changed = 0
  end

  function prefix_btn.onClick()
    if not Check() then return end
    local ok, text = reaper.GetUserInputs("Prefix", 1, "Insert text:", "")
    GiveBackFocus()
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

  function suffix_btn.onClick()
    if not Check() then return end
    local ok, text = reaper.GetUserInputs("Suffix", 1, "Insert text:", "")
    GiveBackFocus()
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

  function number_btn.onClick()
    if not Check() then return end
    local ok, text = reaper.GetUserInputs("Numbering (p -> prefix, s -> suffix)", 3,
    "Specify mode and number:,Number of digits:,Separator:,separator=\n", "p1\n2\n ")
    GiveBackFocus()
    if ok then
      if text:match("[psPS]%s?%d+\n%d+\n") then
        if text ~= "" then
          undo_stack = undo_stack + 1
          mod_stack_name [undo_stack] = "number"
          mod_stack_parm1 [undo_stack] = text
          mod_stack_parm2 [undo_stack] = ""
        end
        WriteCurrentModifier()
      else
        reaper.MB("Please type p or s followed by the starting number.\nExamples: s02, P3, p03, \z
        S 12\n\nSeparator can be any character(s) or empty.", "Not valid input!", 0)
        GiveBackFocus()
      end
    end
  end

  function replace_btn.onRClick()
    local HasState = reaper.HasExtState("Track-Item Name Manipulation", "Replace Help Is open")
    if not HasState or (HasState == true and reaper.GetExtState("Track-Item Name Manipulation", "Replace Help Is open") == "0") then
      local dir = ({reaper.get_action_context()})[2]:match("^(.*[/\\])")
      local file = ({reaper.get_action_context()})[2]:match("^(.*[/\\])").."amagalma_ReaNamer Replace Help.lua"
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
    if not Check() then return end
    local ok, retvals = reaper.GetUserInputs("Replace (read help file!)", 3, "Pattern:,Replacement:,Match case (y/n):,separator=\n", "\n\ny")
    GiveBackFocus()
    local replaceOld, replaceWith
    replaceOld, replaceWith, matchCase = retvals:match("(.+)\n(.*)\n([YyNn])")
    if ok and replaceOld ~= "" and replaceWith and matchCase and matchCase:find("[YyNn]") then
      undo_stack = undo_stack + 1
      mod_stack_name [undo_stack] = "replace"
      mod_stack_parm1 [undo_stack] = replaceOld
      mod_stack_parm2 [undo_stack] = replaceWith
      WriteCurrentModifier()
    end
  end

  function upper_btn.onClick()
    if not Check() then return end
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "upper"
    mod_stack_parm1 [undo_stack] = ""
    mod_stack_parm2 [undo_stack] = ""
    WriteCurrentModifier()
  end

  function lower_btn.onClick()
    if not Check() then return end
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "lower"
    mod_stack_parm1 [undo_stack] = ""
    mod_stack_parm2 [undo_stack] = ""
    WriteCurrentModifier()
  end

  function swap_btn.onClick()
    if not Check() then return end
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "swap"
    mod_stack_parm1 [undo_stack] = ""
    mod_stack_parm2 [undo_stack] = ""
    WriteCurrentModifier()
  end

  function clear_btn.onClick()
    if not Check() then return end
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "clear"
    mod_stack_parm1 [undo_stack] = ""
    mod_stack_parm2 [undo_stack] = ""
    WriteCurrentModifier()
  end

  function capitalize_btn.onClick()
    if not Check() then return end
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "capitalize"
    mod_stack_parm1 [undo_stack] = ""
    mod_stack_parm2 [undo_stack] = ""
    WriteCurrentModifier()
  end

  function title_btn.onClick()
    if not Check() then return end
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "title"
    mod_stack_parm1 [undo_stack] = ""
    mod_stack_parm2 [undo_stack] = ""
    WriteCurrentModifier()
  end

  function strip_btn.onClick()
    if not Check() then return end
    undo_stack = undo_stack + 1
    mod_stack_name [undo_stack] = "strip"
    mod_stack_parm1 [undo_stack] = ""
    mod_stack_parm2 [undo_stack] = ""
    WriteCurrentModifier()
  end

  function trimstart_btn.onClick()
    if not Check() then return end
    local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", "")
    GiveBackFocus()
    if ok then
      if tonumber(number) ~= nil then
        undo_stack = undo_stack + 1
        mod_stack_name [undo_stack] = "trimstart"
        mod_stack_parm1 [undo_stack] = number
        mod_stack_parm2 [undo_stack] = ""
        WriteCurrentModifier()
      else
        reaper.MB("Please, type a number!", "This is not a number!", 0)
        GiveBackFocus()
      end
    end
  end

  function trimend_btn.onClick()
    if not Check() then return end
    local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", "")
    GiveBackFocus()
    if ok then
      if tonumber(number) ~= nil then
        undo_stack = undo_stack + 1
        mod_stack_name [undo_stack] = "trimend"
        mod_stack_parm1 [undo_stack] = number
        mod_stack_parm2 [undo_stack] = ""
        WriteCurrentModifier()
      else
        reaper.MB("Please, type a number!", "This is not a number!", 0)
        GiveBackFocus()
      end
    end
  end

  function keep_btn.onClick()
    if not Check() then return end
    local ok, text = reaper.GetUserInputs("Keep (s -> from start, e -> end)", 1, "Specify mode and number:", "")
    GiveBackFocus()
    if ok then
      if text:match("[seSE]%s?%d+") then
        undo_stack = undo_stack + 1
        mod_stack_name [undo_stack] = "keep"
        mod_stack_parm1 [undo_stack] = text
        mod_stack_parm2 [undo_stack] = ""
        WriteCurrentModifier()
      else
        reaper.MB("Please type s or e followed by the number of characters you want to keep!\nExamples: s8 , E5 , S03 , e 12", "Not valid input!", 0)        
        GiveBackFocus()
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
    elseif what == "regions" then
      indexed_region = indexed_region - 1
      if indexed_region < 1 then indexed_region = 1 end
    elseif what == "markers" then
      indexed_marker = indexed_marker - 1
      if indexed_marker < 1 then indexed_marker = 1 end
    end
  end

  function DOWN_btn.onClick()
    if btn_DOWN_can_move == 0 then return end
    if what == "tracks" and CheckTracks() then
      indexed_track = indexed_track + 1
    elseif what == "items" and CheckItems() then
      indexed_item = indexed_item + 1
    elseif what == "regions" then
      indexed_region = indexed_region + 1
    elseif what == "markers" then
      indexed_marker = indexed_marker + 1
    end
  end

  function UP_btn.onClickPress()
    if what == "tracks" and CheckTracks() then
      indexed_track = indexed_track - 1
      if indexed_track < 1 then indexed_track = 1 end
    elseif what == "items" and CheckItems() then
      indexed_item = indexed_item - 1
      if indexed_item < 1 then indexed_item = 1 end
    elseif what == "regions" then
      indexed_region = indexed_region - 1
      if indexed_region < 1 then indexed_region = 1 end
    elseif what == "markers" then
      indexed_marker = indexed_marker - 1
      if indexed_marker < 1 then indexed_marker = 1 end
    end
  end

  function DOWN_btn.onClickPress()
    if btn_DOWN_can_move == 0 then return end
    if what == "tracks" and CheckTracks() then
      indexed_track = indexed_track + 1
    elseif what == "items" and CheckItems() then
      indexed_item = indexed_item + 1
    elseif what == "regions" then
      indexed_region = indexed_region + 1
    elseif what == "markers" then
      indexed_marker = indexed_marker + 1
    end
  end

  function reset_btn.onClick()
    init_tables()
    undo_btn.help_text = "Nothing to undo"
    redo_btn.help_text = "Nothing to redo"
  end

  function undo_btn.onClick()
    if undo_stack > 0 then
      undo_stack = undo_stack - 1
      redo_stack = redo_stack + 1
      SaveNextRedo()  -- gianfini: needed to manage cornerstone case of modifier no actually modifying anything without having to reset the redo stack
    else
      return
    end
    WriteModifiersStack()
  end

  function redo_btn.onClick()
    if redo_stack > 0 then
      undo_stack = undo_stack + 1
      redo_stack = redo_stack - 1
      SaveNextRedo() -- gianfini: needed to manage cornerstone case of modifier no actually modifying anything without having to reset the redo stack
    else
      return
    end
    WriteModifiersStack()
  end

  function commit_btn.onClick()
    if undo_stack > 0 then
      reaper.Undo_BeginBlock()
      reaper.PreventUIRefresh( 1 )
      if what == "tracks" and CheckTracks() then
        for i=0, trackCount-1 do
          local trackId = reaper.GetSelectedTrack(0, i)
          reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(ToBeTrackNames[reaper.GetTrackGUID(trackId)]), 1)
        end
        reaper.PreventUIRefresh( -1 )
        reaper.Undo_EndBlock("Track name manipulation", 1)
        UpdateTrackManager()
      elseif what == "items" and CheckItems() then
        for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake = reaper.GetActiveTake(itemId)
          if acttake then
            reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]), 1)
          else
            reaper.ULT_SetMediaItemNote(itemId, tostring(ToBeItemNames[reaper.BR_GetMediaItemGUID(itemId)]))
          end
        end
        reaper.PreventUIRefresh( -1 )
        reaper.UpdateArrange()
        reaper.Undo_EndBlock("Item name manipulation", 4)
      elseif what == "regions" then
        for i = 1, regionCount do
          local t = ToBeRegionNames[RegionNamesIndex[i]]
          reaper.SetProjectMarker4( 0, RegionNamesIndex[i], true, t[1], t[2], t[3], 0, t[3] == "" and 1 or 0 )
        end
        reaper.PreventUIRefresh( -1 )
        reaper.UpdateTimeline()
        reaper.Undo_EndBlock("Region name manipulation", 8)
      elseif what == "markers" then
        for i = 1, markerCount do
          local t = ToBeMarkerNames[MarkerNamesIndex[i]]
          reaper.SetProjectMarker4( 0, MarkerNamesIndex[i], false, t[1], 0, t[2], 0, t[2] == "" and 1 or 0 )
        end
        reaper.PreventUIRefresh( -1 )
        reaper.UpdateTimeline()
        reaper.Undo_EndBlock("Marker name manipulation", 8)
      end
      init_tables()
      undo_btn.help_text = "Nothing to undo"
      redo_btn.help_text = "Nothing to redo"
      has_changed = 0
    else
      return
    end
  end

end -------------------------------- end of init() function ------------------------------------------


init()
reaper.defer(main)

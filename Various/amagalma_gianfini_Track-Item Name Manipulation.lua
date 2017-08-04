-- @description amagalma_gianfini_Track-Item Name Manipulation
-- @author amagalma, modified by gianfini
-- @version 2.3
-- @about
--   # Utility to manipulate track or item names
--   - Manipulate track/item names (prefix, suffix, trim start, trim end, uppercase, lowercase, swap case, capitalize, titlecase, replace, strip leading & trailing whitespaces).
--   - Undo points are created only if track/item names have been changed when you close the script or if track/item names have been changed when you change track/item selection.
--   - Mode is automatically chosen when the script starts. Then to change mode click on appropriate button.
--
-- Modified by gianfini as follows
--	- Can NON DESTRUCTIVELY apply any modifier. They will be shown in a list of tracks or items within the Window
--	- Modifiers when added become 'active' (button with RED text)
--	- Single modifiers can be undone independently from they were insterted by selecting the modifier and clearing the fields in the modifier
--	- Each modifier can be applied once in a session and they are applied from top to bottom (button order). 
--	- To apply twice or in a different order hit COMMIT and then activate the modifier again
--	- When satisfied with the modifications COMMIT writes the values to tracks/items
--
-- @link https://forum.cockos.com/showthread.php?t=194414


-- Changelog:
-- v2.3 (2017-07-30)
--	- Added KEEP modifier from Amagalma script
-- v2.2 (2017-07-29)
--	- Fixed handling empty items: no crash anymore
-- v2.1 (2017-07-28)
--	- Fixed continous "select track/item" windows. Improved switch between tracks and items
-- v2.0 (2017-07-26)
--	- Non desctructive mode implemented + graphic changes

-- Many thanks to spk77 and to Lokasenna for their code and help! :)

version = "2.3"
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
						btn.fill_status = 0 -- gianfini: indicates if modifier exist
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
  --return(last_mouse_state == 0 and self.mouse_state == 1)
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

function Button:set_color_reset()
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

function Button:set_color_updown() -- gianfini
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
end

function Button:set_color_updown_can_move(arrow_verse)  -- gianfini
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
  if self.help_text == "Adds index numbers at the start or\nend (p->prefix | s->suffix, then the\nstarting number)" then -- gianfini redesigned
	gfx.y = Tracks_btn.y1 - math.floor(win_vert_border/1.7)
  else
	if string.match(self.help_text,"\n") ~= nil then
		gfx.y = Tracks_btn.y1 - math.floor(win_vert_border/3.9)
	else
		gfx.y = Tracks_btn.y1 -- math.floor(win_vert_border/3.7)
	end
  end
    local hwidth = gfx.measurestr(self.help_text)
	gfx.x = math.floor(win_w/2 + win_border/2)
    gfx.set(1,.6,.25,1)  -- gianfini changed color
    gfx.setfont(2, "Arial", 15) -- gianfini font size changed
    gfx.printf(self.help_text)
end

function Button:draw_label()
  -- Draw button label
  gfx.setfont(1, "Arial", 19) -- gianfini: keep font size on mouse over
  
  if self.label ~= "" then
    gfx.x = self.x1 + math.floor(0.5*self.w - 0.5 * self.label_w) -- center the label
    gfx.y = self.y1 + 0.5*self.h - 0.5*gfx.texth

    if self.__mouse_state == 1 then 
      gfx.y = gfx.y + 1
      gfx.a = self.lbl_a*0.5
	  temp_lbl_a = self.lbl_a*0.6 -- gianfini temp var for transparency
    elseif self.__mouse_state == 0 then
      gfx.a = self.lbl_a  -- gianfini temp var
	  temp_lbl_a = self.lbl_a*0.9
    end
  
    gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,temp_lbl_a)   -- gianfini temp var
    
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
    --if last_mouse_state == 0 and gfx.mouse_cap & 1 == 1 and self.mouse_state == 0 then
      self.__mouse_state = 1
      if self.__state_changing == false then
        self.__state_changing = true
      else self.__state_changing = true
      end
    end
    
    self:set_help_text() -- Draw info/help text (if 'help_text' is not "")
	
	-- self.lbl_b = 0 -- gianfini to make it yellow
    
	if self.fill_status == 1 then  -- gianfini different coloring if modifier active
		self.lbl_b = 0.2
		self.lbl_g = 0.6
		self.lbl_r = 1
	else
		self.lbl_b = self.lbl_store_b + ((1 - self.lbl_store_b)/2) 
		self.lbl_r = self.lbl_store_r + ((1 - self.lbl_store_r)/2)
		self.lbl_g = self.lbl_store_g + ((1 - self.lbl_store_g)/2)
	end
	
    if last_mouse_state == 0 and gfx.mouse_cap & 1 == 0 and self.__state_changing == true then
      if self.onClick ~= nil then self:onClick()
        self.__state_changing = false
      else self.__state_changing = false
      end
    end
  
  -- Mouse is not on element -----------------------
  else
    if last_mouse_state == 0 and self.__state_changing == true then
      self.__state_changing = false
    end
	
	if self.fill_status == 1 then  -- gianfini different coloring if modifier active
		self.lbl_b = 0.4
		self.lbl_g = 0.4
		self.lbl_r = 1
	else
		self.lbl_b = self.lbl_store_b
		self.lbl_r = self.lbl_store_r
		self.lbl_g = self.lbl_store_g
	end
  end  
  
  if self.__mouse_state == 1 or self.vis_state == 1 or self.__state_changing then
    --self.a = math.max(self.a - 0.2, 0.2)
    --gfx.set(0.8,0,0.8,self.a)
    gfx.set(0.9*self.r,0.9*self.g,0.9*self.b,math.max(self.a - 0.2, 0.2)*0.9)
    gfx.rect(self.x1, self.y1, self.w, self.h)

  -- Button is not pressed
  elseif not self.state_changing or self.vis_state == 0 or self.__mouse_state == 0 then
    gfx.set(self.r+0.2,self.g+0.2,self.b+0.2,self.a)
    gfx.rect(self.x1, self.y1, self.w, self.h)
   
    gfx.a = math.max(0.4*self.a, 0.6)
    -- light - left
    gfx.line(self.x1, self.y1, self.x1, self.y2-1)
    --gfx.line(self.x1+1, self.y1+1, self.x1+1, self.y2-2)  --gianfini to reduce border
    -- light - top
    gfx.line(self.x1+1, self.y1, self.x2-1, self.y1)
    --gfx.line(self.x1+2, self.y1+1, self.x2-2, self.y1+1)  -- gianfini to reduce border

	
    gfx.set(0.3*self.r,0.3*self.g,0.3*self.b,math.max(0.9*self.a,0.8))
    -- shadow - bottom
    gfx.line(self.x1+1, self.y2-1, self.x2-2, self.y2-1)
    --gfx.line(self.x1+2, self.y2-2, self.x2-3, self.y2-2)  --gianfini to reduce border
    -- shadow - right
    gfx.line(self.x2-1, self.y2-1, self.x2-1, self.y1+1)
    --gfx.line(self.x2-2, self.y2-2, self.x2-2, self.y1+2)  --gianfini to reduce border
	
  end
  
  
  self:draw_label()
end


--The code above is borrowed from spk77's "spk77_Button colors.lua" script found in ReaPack
-------------------------------------------------------------------------------------------

local reaper = reaper

local function f() 
  gfx.setfont(1, "Arial", 19) -- SET HERE FONT SIZE (DEFAULT = 19)
end

local function fsmall() --gianfini
  gfx.setfont(3, "Courier New", 14) -- SET HERE SMALL FONT SIZE
end


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
  trackCount = reaper.CountSelectedTracks(0)
  if trackCount < 1 then
    reaper.MB("Please select at least one track!", "", 0)
  else  
    return true
  end
end

local function CheckItems()
  itemCount = reaper.CountSelectedMediaItems(0)
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


local function compare_tables(t1, t2) -- Lokasenna function
  if #t1 ~= #t2 then return false end
  for k, v in pairs(t1) do
    if v ~= t2[k] then return false end
  end
  return true
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
    local acttake =  reaper.GetActiveTake( it )
    if acttake then 
      local _, name = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
      table[reaper.BR_GetMediaItemTakeGUID(acttake)] = name
    end
  end
  return table
end


-- Check previous names of all tracks to their current names
local function UndoIfNamesChanged()
  if what == "tracks" then
    local AllCurrentTrackNames = AllTrackNames()
    if not compare_tables(AllCurrentTrackNames, AllLastTrackNames) then
      AllLastTrackNames = AllCurrentTrackNames
      reaper.Undo_OnStateChangeEx("Track name manipulation", 1, -1)
    end
  elseif what == "items" then
    local AllCurrentItemNames = AllItemNames()
    if not compare_tables(AllCurrentItemNames, AllLastItemNames) then
      AllLastItemNames = AllCurrentItemNames
      reaper.Undo_OnStateChange("Item name manipulation")
    end
  end
end

-- gianfini: line between buttons
local function DrawOneDividingLine(txx, tyy, strong)
	txx = 0
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

local function DrawDividingLines() -- gianfini
	DrawOneDividingLine(trimstart_btn.x1, trimstart_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
	DrawOneDividingLine(replace_btn.x1, replace_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
	DrawOneDividingLine(suffix_btn.x1, suffix_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
	DrawOneDividingLine(number_btn.x1, number_btn.y1 + btn_height + math.floor(win_vert_border/2) - 1, 0)
	DrawOneDividingLine(swap_btn.x1, swap_btn.y1 + btn_height + math.floor(win_vert_border/2), 0)
	DrawOneDividingLine(reset_btn.x1, reset_btn.y1 + btn_height*2 + math.floor(win_vert_border/2), 1)
end

-- gianfini: prints a track or item name
local function DrawTrackName(txx, tyy, tname)
	if (what == "tracks") then
		gfx.y = tyy
		gfx.x = txx
		gfx.a = 1
		gfx.set(0, 0, .15, 1)
		fsmall()
		gfx.printf("%.50s", tname)
	else
		gfx.y = tyy
		gfx.x = txx
		gfx.a = 1
		gfx.set(.35, .1, 0, 1)
		fsmall()
		gfx.printf("%.50s", tname)
	end
end

local function RefreshTrackItemList(tl_x, tl_y, tl_w, tl_h) -- gianfini, redraws the tracks - items scroll list
   --f()
   --lstw, lsth = gfx.measurestr("Strip leading & trailing whitespaces") -- gianfini example string to set width
   --x_start = lsth
   --y_start = 10*lsth*1.5
   
   fsmall()
   lstw_small, lsth_small = gfx.measurestr("Strip leading & trailing whitespaces") -- gianfini example string to set width
   
   --fsmall()
   --strw_small, strh_small = gfx.measurestr("Strip leading & trailing whitespaces")
   max_lines = math.floor(tl_h/lsth_small)
   
   x_start = tl_x
   y_start = tl_y
   
   gfx.r = 0.4
   gfx.g = 0.4
   gfx.b = 0.45
   gfx.a = 1
  
   gfx.rect(tl_x, tl_y - math.floor(lsth_small/3), tl_w, tl_h + math.floor(lsth_small/3))
   
   if what == "tracks" then   
	if CheckTracks_NM() then
		if (trackCount - indexed_track + 1) < max_lines then
			btn_DOWN_can_move = 0 -- indicates if list can scroll down further (for graphic indication on btn)
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
		
		first_s_line = init_line
	
		if (trackCount - indexed_track + 1) < max_lines then
			last_s_line = trackCount - 1
		else
			last_s_line = first_s_line + max_lines - 1
		end
	
		for i = first_s_line, last_s_line do
			local trt = reaper.GetSelectedTrack(0, i)
			track_num = reaper.GetMediaTrackInfo_Value(trt,"IP_TRACKNUMBER")
			DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small), tostring(string.format("%02d",track_num))..". "..tostring(ToBeTrackNames[reaper.GetTrackGUID(trt)]))
		end
	end
   else -- manage items
	if CheckItems_NM() then
		if (itemCount - indexed_item + 1) < max_lines then
			btn_DOWN_can_move = 0 -- indicates if list can scroll down further (for graphic indication on btn)
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
		
		first_s_line = init_line
	
		if (itemCount - indexed_item + 1) < max_lines then
			last_s_line = itemCount - 1
		else
			last_s_line = first_s_line + max_lines - 1
		end
		
		for i = first_s_line, last_s_line do
			local itemId = reaper.GetSelectedMediaItem(0, i)
			local acttake =  reaper.GetActiveTake(itemId)
			-- track_num = reaper.GetMediaTrackInfo_Value(trt,"IP_TRACKNUMBER")
			if acttake then
				DrawTrackName(x_start + math.floor(lsth_small/3), y_start+math.floor((i-first_s_line)*lsth_small), tostring(ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]))
			end
		end
	end
   end
end

function WriteModifiers() -- write modifiers in track - items list, not to Reaper tracks - items
    if what == "tracks" then
      if CheckTracks() then
					  
			for i=0, trackCount-1 do
				local trackId = reaper.GetSelectedTrack(0, i)
				local prevName = OriginalTrackNames[reaper.GetTrackGUID(trackId)] -- gianfini
				
				-- write trim start
				if currTrimStart ~= "" then
					newName = prevName:sub(currTrimStart+1)
				else
					newName = prevName
				end
              
				-- write trim end
				if currTrimEnd ~= "" then
					local length = newName:len()
					newName = newName:sub(1, length-currTrimEnd)
				end
			  
				-- write keep
				if currKeep ~= "" then
					local mode, number = currKeep:match("([seSE])%s?(%d+)")
					number = tonumber(number)
										
                    if mode:match("[sS]") then
						newName = newName:sub(0, number)
					else
						newName = newName:sub((-1)*number)
					end
				end
				
				-- write substitute and replace
				if currSubstFrom ~= "" then
					newName = string.gsub(newName, currSubstFrom, currSubstTo)
				end
			  
				-- write pre-suffix
				newName = currPrefix .. newName .. currSuffix
				
				-- write numbering
				if currNumbering ~= "" then
					local mode, number = currNumbering:match("([psPS])%s?(%d+)")
					if mode:match("[pP]") then
						newName = string.format("%02d", math.floor(number+i)) .. " " .. newName
					else
						newName = newName .. " " .. string.format("%02d", math.floor(number+i))
					end
				end
			
				-- write letter cases
				if currCase == 1 then
					newName = string.upper(newName)
				elseif currCase == 2 then
					newName = string.lower(newName)
				elseif currCase == 3 then
					newName = swapcase(newName)
				elseif currCase == 4 then
					newName = (newName:gsub("^%l", string.upper))
				elseif currCase == 5 then
					newName = string.gsub(" "..newName, "%W%l", string.upper):sub(2)
				end
				
				-- strip leading / trailing white spaces
				if currStrip == 1 then
					newName = newName:match("^%s*(.-)%s*$")
				end
			
				-- Update list
				ToBeTrackNames[reaper.GetTrackGUID(trackId)] = newName -- gianfini
			end
	  end
	else -- managing items
		if CheckItems() then
        					  
			for i=0, itemCount-1 do
				local itemId = reaper.GetSelectedMediaItem(0, i)
				local acttake = reaper.GetActiveTake(itemId)
				if acttake then
					local prevName = OriginalItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]
				
					-- write trim start
					if currTrimStart ~= "" then
						newName = prevName:sub(currTrimStart+1)
					else
						newName = prevName
					end
              
					-- write trim end
					if currTrimEnd ~= "" then
						local length = newName:len()
						newName = newName:sub(1, length-currTrimEnd)
					end
			  
					-- write substitute and replace
					if currSubstFrom ~= "" then
						newName = string.gsub(newName, currSubstFrom, currSubstTo)
					end
			  
					-- write pre-suffix
					newName = currPrefix .. newName .. currSuffix
				
					-- write numbering
					if currNumbering ~= "" then
						local mode, number = currNumbering:match("([psPS])%s?(%d+)")
						if mode:match("[pP]") then
							newName = string.format("%02d", math.floor(number+i)) .. " " .. newName
						else
							newName = newName .. " " .. string.format("%02d", math.floor(number+i))
						end
					end
			
					-- write letter cases
					if currCase == 1 then
						newName = string.upper(newName)
					elseif currCase == 2 then
						newName = string.lower(newName)
					elseif currCase == 3 then
						newName = swapcase(newName)
					elseif currCase == 4 then
						newName = (newName:gsub("^%l", string.upper))
					elseif currCase == 5 then
						newName = string.gsub(" "..newName, "%W%l", string.upper):sub(2)
					end
				
					-- strip leading / trailing white spaces
					if currStrip == 1 then
						newName = newName:match("^%s*(.-)%s*$")
					end
			
					-- Update list
					ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)] = newName -- gianfini
				end
			end
		end
	end
end

local function main() -- MAIN FUNCTION
  -- Draw buttons
  
  f(); prefix_btn:draw()
  f(); suffix_btn:draw()
  f(); trimstart_btn:draw()
  f(); trimend_btn:draw()
  f(); keep_btn:draw()
  f(); replace_btn:draw()
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
  
  -- gianfini new buttons coloring
  commit_btn:set_color_commit()
  reset_btn:set_color_reset()
  
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
  
  RefreshTrackItemList (scroll_list_x, scroll_list_y, scroll_list_w, scroll_list_h)  --gianfini
    
  -- Check every half second to see if the track or item selection has changed
  if what == "tracks" then
    local newtime = reaper.time_precise()
    if newtime-lasttime >= 0.5 then
      lasttime=newtime
      -- Get the number of selected tracks
      trackCount = reaper.CountSelectedTracks(0)
      -- Grab their MediaTracks into a table
      local cur_tracks = {}
      for i = 1, trackCount do
        cur_tracks[i] = reaper.GetSelectedTrack(0, i - 1)
      end
      -- See if the current and stored track selections match
      if not compare_tables(sel_tracks, cur_tracks) then
      -- User changed the track selection
        sel_tracks = cur_tracks
        UndoIfNamesChanged()
      end
    end
  elseif what == "items" then
    local newtime=os.time()
    if newtime-lasttime >= 0.5 then
      lasttime=newtime
      -- Get the number of selected items
      itemCount = reaper.CountSelectedMediaItems(0)
      -- Grab Mediaitems into a table
      local cur_items = {}
      for i = 1, itemCount do
        cur_items[i] = reaper.GetSelectedMediaItem(0, i - 1)
      end
      -- See if the current and stored item selections match
      if not compare_tables(sel_items, cur_items) then
      -- User changed the item selection
        sel_items = cur_items
        UndoIfNamesChanged()
      end
    end
  end
  
  -- Check left mouse btn state
  if gfx.mouse_cap & 1 == 0 then
    last_mouse_state = 0
  else last_mouse_state = 1 end
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(main)
  else UndoIfNamesChanged()
  end
    
end

function Reset_Btn_Lbl_Colors()
	prefix_btn.fill_status = 0
	suffix_btn.fill_status = 0
	number_btn.fill_status = 0
	trimstart_btn.fill_status = 0
	trimend_btn.fill_status = 0
	replace_btn.fill_status = 0
	upper_btn.fill_status = 0
	lower_btn.fill_status = 0
	swap_btn.fill_status = 0
	capitalize_btn.fill_status = 0
	title_btn.fill_status = 0
	strip_btn.fill_status = 0
	keep_btn.fill_status = 0
end

function Reset_Modifiers()
	currTrimStart = ""
	currTrimEnd = ""
	currSubstFrom = ""
	currSubstTo = ""
	
	currPrefix = ""
	currSuffix = ""
	currNumbering = ""
	currKeep = ""
	
	currCase = 0
	-- 0=None
	-- 1=Uppercase
	-- 2=Lowercase
	-- 3=Swap
	-- 4=Capitalize
	-- 5=Title
	
	currStrip = 0
end

local function init_tables()
  if what == "tracks" then
    -- Store initial track selection so that there can be a comparison in main()
    trackCount = reaper.CountSelectedTracks(0)
    sel_tracks = {}
    for i = 1, trackCount do
      sel_tracks[i] = reaper.GetSelectedTrack(0, i - 1)
    end
    -- Store all track names before any manipulation so that there can be a comparison afterwards
    AllLastTrackNames = AllTrackNames()
	-- gianfini
	ToBeTrackNames = AllTrackNames()
	OriginalTrackNames = AllTrackNames()
	indexed_track = 1
	Reset_Modifiers()
		
  elseif what == "items" then
    -- Store initial item selection so that there can be a comparison in main()
    itemCount = reaper.CountSelectedMediaItems(0)
    sel_items = {}
    for i = 1, itemCount do
      sel_items[i] = reaper.GetSelectedMediaItem(0, i - 1)
    end
    -- Store all item names before any manipulation so that there can be a comparison afterwards
    AllLastItemNames = AllItemNames()
	-- gianfini
	ToBeItemNames = AllItemNames()
	OriginalItemNames = AllItemNames()
	indexed_item = 1
	Reset_Modifiers()
  end
  btn_DOWN_can_move = 0
end

local function init() -- INITIALIZATION
  -- Get current context (tracks or items)
  local context = reaper.GetCursorContext2(true)
  if context == 0 then what = "tracks" else what = "items" end
  init_tables()
  
  -- Initialize timer
  lasttime = reaper.time_precise()
  f() -- set font
  strw, strh = gfx.measurestr("Strip leading & trailing whitespaces")
  gfx.clear = 3084036
  
  -- gianfini set of variables for screen drawing
  win_w = math.floor(strw*1.6)
  win_h = strh+math.floor(11.5*strh*2.5)
  btn_height = strh+math.floor(strh/3.2)
  win_border = math.floor(strh/2)
  win_vert_border = math.floor(win_border*1.6)
  win_double_vert_border = win_border*2
  
  Window_At_Center(win_w, win_h) -- gianfini wider window
  
  -- parameters: Button(x1,y1,w,h,state_count,state,visual_state,lbl,help_text)
  
  -- first raw Trim
  
  local label, help = "Trim Start", "Removes specified number of\ncharacters from the start"
  local width = math.floor((win_w - 4*win_border)/3)
  local height = btn_height
  local x_pos = win_border
  local y_pos = win_vert_border
  trimstart_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Trim end", "Removes specified number of\ncharacters from the end"
  local x_pos = win_border*2 + width
  trimend_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Keep", "Keeps only specified number of characters\n (s-> from start | e-> from end)"
  local x_pos = win_border*3 + width*2
  keep_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  -- second raw Replace
    local label, help = "Replace", "Replaces all instances of the pattern\nwith the replacement"
  local width = win_w - 2*win_border
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  replace_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  -- third raw Prefix Suffix
  local label, help = "Prefix", "Inserts text at the begining"
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  prefix_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Suffix", "Appends text to the end"
  local x_pos = win_border*2 + width
  suffix_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  -- fourth raw numbering
  local label, help = "Number", "Adds index numbers at the start or\nend (p->prefix | s->suffix, then the\nstarting number)"
  local width = win_w - 2*win_border
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  
  number_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  -- fifth raw Capitalize /1
  local label, help = "Uppercase", "Converts all letters to UPPERCASE"
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  
  upper_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  local label, help = "Lowercase", "Converts all letters to lowercase"
  local x_pos = win_border*2 + width
  
  lower_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  -- sixth raw Capitalize /2
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
  
  -- seventh raw: strip
  local label, help = "Strip leading & trailing whitespaces", "Removes all leading and trailing\nwhitespaces"
  local width = win_w - 2*win_border
  local x_pos = win_border
  local y_pos = y_pos + btn_height + win_vert_border
  
  strip_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  -- eight raw: reset and commit
  local label, help = "RESET", "Reset all modifiers"
  local width = math.floor((win_w - 3*win_border)/2)
  local x_pos = win_border
  local y_pos = y_pos + btn_height + math.floor(win_vert_border*0.8)
  local height = btn_height*2

  reset_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  local label, help = "COMMIT", "Commit all modifications"
  local x_pos = win_border*2 + width
  
  commit_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)
  
  -- nineth raw: tracks or items
  local label, help = "Tracks", "Click to select Tracks mode"
  local height = btn_height
  local width = math.floor((win_w - 5*win_border)/4)
  local x_pos = win_border
  local y_pos = y_pos + height*2 + win_double_vert_border
  
  Tracks_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help, 2, 0, 0, label, help)
  
  
  local label, help = "Items", "Click to select Items mode"
  local x_pos = win_border*2 + width
  Items_btn = Button(x_pos, y_pos, width, height, 2, 0, 0, label, help)

  --- scroll list measures
  scroll_list_x = win_border
  scroll_list_y = y_pos + height + win_double_vert_border
  scroll_list_w = win_w - 2*win_border - 4*win_border
  scroll_list_h = win_h - scroll_list_y - win_vert_border
  indexed_track = 1
  f()
  strw, strh = gfx.measurestr("Strip leading & trailing whitespaces")
  fsmall()
  strw_small, strh_small = gfx.measurestr("Strip leading & trailing whitespaces")
  visible_track_num = math.floor((8*strh*2.5 + strh - 10*strh*1.5)/strh_small)
  ----- end scroll list

  
  --- scroll table buttons UP and DOWN
  
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
    
  
-- BUTTON FUNCTIONS

  function Tracks_btn.onClick()
    what = "tracks"
    init_tables()
	Reset_Btn_Lbl_Colors()
  end
  
  function Items_btn.onClick()
    what = "items"
    init_tables()
	Reset_Btn_Lbl_Colors()
  end

  function prefix_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        local ok, text = reaper.GetUserInputs("Prefix", 1, "Insert text:", currPrefix)
        if ok then
          
		  --for i=0, trackCount-1 do
          --  local trackId = reaper.GetSelectedTrack(0, i)
          --  local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
	      -- local newName = text .. currentName
		  -- reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
          -- end
		  
			currPrefix = text  -- gianfini
			if text ~= "" then
				prefix_btn.fill_status = 1
			else
				prefix_btn.fill_status = 0
			end
			WriteModifiers() -- gianfini
		
        end
      end
    elseif what == "items" then
      if CheckItems() then
        local ok, text = reaper.GetUserInputs("Prefix", 1, "Insert text:", currPrefix)
        if ok then
          --for i=0, itemCount-1 do
            --local itemId = reaper.GetSelectedMediaItem(0, i)
			--local acttake =  reaper.GetActiveTake( itemId )
            --local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
            --local newName = text .. currentName
            --reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
          --end
		  
			currPrefix = text --gianfini
			if text ~= "" then
				prefix_btn.fill_status = 1
			else
				prefix_btn.fill_status = 0
			end
			WriteModifiers() -- gianfini 
		  
        end
      end
    end
  end

  function suffix_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        local ok, text = reaper.GetUserInputs("Suffix", 1, "Insert text:", currSuffix)
        if ok then
          
		  --for i=0, trackCount-1 do
            --local trackId = reaper.GetSelectedTrack(0, i)
            --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
            --local newName = currentName .. text
            --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
          --end
        
		currSuffix = text  -- gianfini
		if text ~= "" then
			suffix_btn.fill_status = 1
		else
			suffix_btn.fill_status = 0
		end
		WriteModifiers() -- gianfini
			
		end
      end
    elseif what == "items" then
      if CheckItems() then
        local ok, text = reaper.GetUserInputs("Suffix", 1, "Insert text:", currSuffix)
        if ok then
          
		  --[[
		  for i=0, itemCount-1 do
            local itemId = reaper.GetSelectedMediaItem(0, i)
			local acttake =  reaper.GetActiveTake( itemId )
            local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
            local newName = currentName .. text
            reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
          end
		  ]]--
		  
		  currSuffix = text  -- gianfini
		  if text ~= "" then
				suffix_btn.fill_status = 1
		  else
				suffix_btn.fill_status = 0
		  end
		  WriteModifiers() -- gianfini
        end
      end
    end  
  end
  
  function number_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        local ok, text = reaper.GetUserInputs("Numbering (p -> prefix, s -> suffix)", 1, "Specify mode and number:", currNumbering)
		if ok then
		  if text:match("[psPS]%s?%d+") then
            
			currNumbering = text -- gianfini			
			number_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			local newName = ""
			local mode, number = text:match("([psPS])%s?(%d+)")
            
			--for i=0, trackCount-1 do
              --local trackId = reaper.GetSelectedTrack(0, i)
              --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
              --if mode:match("[pP]") then
              --  newName = string.format("%02d", math.floor(number+i)) .. " " .. currentName
              --else
              --  newName = currentName .. " " .. string.format("%02d", math.floor(number+i))
              --end
              --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
			--end
          
		  else
            if text ~= "" then
				reaper.MB("Please type p or s followed by the starting number!\n Examples: s02 , P3 , p03 , S 12", "Not valid input!", 0)
			else
				number_btn.fill_status = 0  -- gianfini: emptying the field rest the modifier
				currNumbering = ""
				WriteModifiers()
			end
		  end
        end
      end  
    elseif what == "items" then
      if CheckItems() then
        local ok, text = reaper.GetUserInputs("Numbering (p -> prefix, s -> suffix)", 1, "Specify mode and number:", currNumbering)
        if ok then
          if text:match("[psPS]%s?%d+") then
		  
			currNumbering = text -- gianfini			
			number_btn.fill_status = 1
			WriteModifiers() -- gianfini
		  
            local newName = ""
            local mode, number = text:match("([psPS])%s?(%d+)")
			
			--[[
            for i=0, itemCount-1 do
              local itemId = reaper.GetSelectedMediaItem(0, i)
			  local acttake =  reaper.GetActiveTake( itemId )
              local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
              if mode:match("[pP]") then
                newName = string.format("%02d", math.floor(number+i)) .. " " .. currentName
              else
                newName = currentName .. " " .. string.format("%02d", math.floor(number+i))
              end
              reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
            end
			]]--
			
          else
			if text ~= "" then
				reaper.MB("Please type p or s followed by the starting number!\n Examples: s02 , P3 , p03 , S 12", "Not valid input!", 0)
			else
				number_btn.fill_status = 0  -- gianfini: emptying the field rest the modifier
				currNumbering = ""
				WriteModifiers()
			end
          end
        end
      end
    end
  end
  
  function replace_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        local ok, retvals = reaper.GetUserInputs("Replace", 2, "Pattern:,Replacement:", currSubstFrom .. "," .. currSubstTo)
        if ok then
          if retvals ~= ",," and retvals ~= "," then
            words = {}
			for word in retvals:gmatch("[^,]+") do table.insert(words, word) end
            local replaceOld = words[1]
            local replaceWith = words[2] or ""
            
			if string.sub(retvals, 1, 1) == "," then  -- gianfini correction to a bug
				replaceWith = replaceOld
				replaceOld = ""
			end
			
			currSubstFrom = replaceOld -- gianfini
			currSubstTo = replaceWith
			replace_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			if replaceOld == "" then return end -- gianfini
			
			--for i=0, trackCount-1 do
              --local trackId = reaper.GetSelectedTrack(0, i)
              --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
              --local newName = string.gsub(currentName, replaceOld, replaceWith)
              --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
            --end
          else  -- gianfini: empty fields reset modifiers
			currSubstFrom = ""
			currSubstTo = ""
			replace_btn.fill_status = 0
			WriteModifiers()
		  end
        end
      end
    elseif what == "items" then
      if CheckItems() then
        local ok, retvals = reaper.GetUserInputs("Replace", 2, "Pattern:,Replacement:", currSubstFrom .. "," .. currSubstTo)
        if ok then
          if retvals ~= ",," and retvals ~= "," then
            words = {}
            for word in retvals:gmatch("[^,]+") do table.insert(words, word) end
            local replaceOld = words[1]
            local replaceWith = words[2] or ""
			
			if string.sub(retvals, 1, 1) == "," then  -- gianfini correction to a bug
				replaceWith = replaceOld
				replaceOld = ""
			end
			
			currSubstFrom = replaceOld -- gianfini
			currSubstTo = replaceWith
			replace_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			if replaceOld == "" then return end -- gianfini
			
			--[[
            for i=0, itemCount-1 do
              local itemId = reaper.GetSelectedMediaItem(0, i)
              local acttake =  reaper.GetActiveTake( itemId )
              local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
              local newName = string.gsub(currentName, replaceOld, replaceWith)
              reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
            end
			]]--
			
          else -- gianfini: empty fields reset modifier
			currSubstFrom = ""
			currSubstTo = ""
			replace_btn.fill_status = 0
			WriteModifiers()
		  end
        end
      end 
    end  
  end

  function upper_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        
		if currCase == 1 then  --gianfini
			currCase = 0
			upper_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 1
			upper_btn.fill_status = 1
			lower_btn.fill_status = 0
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 0
			WriteModifiers()
		end
		
		--for i=0, trackCount-1 do
          --local trackId = reaper.GetSelectedTrack(0, i)
          --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          --local newName = string.upper(currentName)
          --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        --end
      end
    elseif what == "items" then
      if CheckItems() then
        
		if currCase == 1 then  --gianfini
			currCase = 0
			upper_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 1
			upper_btn.fill_status = 1
			lower_btn.fill_status = 0
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 0
			WriteModifiers()
		end
		
		--[[
		for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake =  reaper.GetActiveTake( itemId )
          local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
          local newName = string.upper(currentName)
          reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
        end
		]]--
		
      end 
    end  
  end

  function lower_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        
		if currCase == 2 then  --gianfini
			currCase = 0
			lower_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 2
			upper_btn.fill_status = 0
			lower_btn.fill_status = 1
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 0
			WriteModifiers()
		end
		
		--for i=0, trackCount-1 do
          --local trackId = reaper.GetSelectedTrack(0, i)
          --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          --local newName = string.lower(currentName)
          --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        --end
      end
    elseif what == "items" then
      if CheckItems() then
		
		if currCase == 2 then  --gianfini
			currCase = 0
			lower_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 2
			upper_btn.fill_status = 0
			lower_btn.fill_status = 1
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 0
			WriteModifiers()
		end
		
		--[[
        for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake =  reaper.GetActiveTake( itemId )
          local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
          local newName = string.lower(currentName)
          reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
        end
		]]--
      end  
    end
  end

  function swap_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        
		if currCase == 3 then -- gianfini
			currCase = 0
			swap_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 3
			upper_btn.fill_status = 0
			lower_btn.fill_status = 0
			swap_btn.fill_status = 1
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 0
			WriteModifiers()
		end
		
		--for i=0, trackCount-1 do
          --local trackId = reaper.GetSelectedTrack(0, i)
          --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          --local newName = swapcase(currentName)
          --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        --end
      end
    elseif what == "items" then
      if CheckItems() then
        
		if currCase == 3 then -- gianfini
			currCase = 0
			swap_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 3
			upper_btn.fill_status = 0
			lower_btn.fill_status = 0
			swap_btn.fill_status = 1
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 0
			WriteModifiers()
		end
		
		--[[
		for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake =  reaper.GetActiveTake( itemId )
          local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
          local newName = swapcase(currentName)
          reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
        end
		]]--
      end 
    end  
  end

  function capitalize_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
	  
		if currCase == 4 then -- gianfini
			currCase = 0
			capitalize_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 4
			upper_btn.fill_status = 0
			lower_btn.fill_status = 0
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 1
			title_btn.fill_status = 0
			WriteModifiers()
		end
	  
        --for i=0, trackCount-1 do
          --local trackId = reaper.GetSelectedTrack(0, i)
          --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          --local newName = (currentName:gsub("^%l", string.upper))
          --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        --end
      end
    elseif what == "items" then
      if CheckItems() then
	  
	  if currCase == 4 then -- gianfini
			currCase = 0
			capitalize_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 4
			upper_btn.fill_status = 0
			lower_btn.fill_status = 0
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 1
			title_btn.fill_status = 0
			WriteModifiers()
		end
		
		--[[
        for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake =  reaper.GetActiveTake( itemId )
          local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
          local newName = (currentName:gsub("^%l", string.upper))
          reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
        end
		]]--
		
      end
    end  
  end

  function title_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
	  
		if currCase == 5 then -- gianfini
			currCase = 0
			title_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 5
			upper_btn.fill_status = 0
			lower_btn.fill_status = 0
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 1
			WriteModifiers()
		end
	  
        --for i=0, trackCount-1 do
          --local trackId = reaper.GetSelectedTrack(0, i)
          --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          --local newName = string.gsub(" "..currentName, "%W%l", string.upper):sub(2)
          --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        --end
      end
    elseif what == "items" then
      if CheckItems() then
	  
		if currCase == 5 then -- gianfini
			currCase = 0
			title_btn.fill_status = 0
			WriteModifiers()
		else
			currCase = 5
			upper_btn.fill_status = 0
			lower_btn.fill_status = 0
			swap_btn.fill_status = 0
			capitalize_btn.fill_status = 0
			title_btn.fill_status = 1
			WriteModifiers()
		end
		
		--[[
        for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake =  reaper.GetActiveTake( itemId )
          local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
          local newName = string.gsub(" "..currentName, "%W%l", string.upper):sub(2)
          reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
        end
		]]--
		
      end
    end  
  end

  function strip_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        
		if currStrip == 1 then -- gianfini
			currStrip = 0
			strip_btn.fill_status = 0
			WriteModifiers()
		else
			currStrip = 1
			strip_btn.fill_status = 1
			WriteModifiers()
		end
	  		
		--for i=0, trackCount-1 do
          --local trackId = reaper.GetSelectedTrack(0, i)
          --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          --local newName = currentName:match("^%s*(.-)%s*$")
          --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        --end
      end
    elseif what == "items" then
      if CheckItems() then
		if currStrip == 1 then -- gianfini
			currStrip = 0
			strip_btn.fill_status = 0
			WriteModifiers()
		else
			currStrip = 1
			strip_btn.fill_status = 1
			WriteModifiers()
		end
		
		--[[
        for i=0, itemCount-1 do
          local itemId = reaper.GetSelectedMediaItem(0, i)
          local acttake =  reaper.GetActiveTake( itemId )
          local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
          local newName = currentName:match("^%s*(.-)%s*$")
          reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
        end
		]]--
      end
    end  
  end

  function trimstart_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", currTrimStart)
        if ok then
		  if tonumber(number) ~= nil then
            
			currTrimStart = number  -- gianfini
			trimstart_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			--for i=0, trackCount-1 do
              --local trackId = reaper.GetSelectedTrack(0, i)
              --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
              --local newName = currentName:sub(number+1)
              --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
            --end
          else
            if number ~= "" then
				reaper.MB("Please, type a number!", "This is not a number!", 0)
			else
				currTrimStart = ""   -- gianfini: empty field means resetting Trim
				trimstart_btn.fill_status = 0
				WriteModifiers()
			end
          end
        end
      end
    elseif what == "items" then
      if CheckItems() then
        local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", currTrimStart)
        if ok then
          if tonumber(number) ~= nil then
		  
			currTrimStart = number  -- gianfini
			trimstart_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			--[[
            for i=0, itemCount-1 do
              local itemId = reaper.GetSelectedMediaItem(0, i)
              local acttake =  reaper.GetActiveTake( itemId )
              local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
              local newName = currentName:sub(number+1)
              reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
            end
			]]--
			
          else
            if number ~= "" then
				reaper.MB("Please, type a number!", "This is not a number!", 0)
			else
				currTrimStart = ""   -- gianfini: empty field means resetting Trim
				trimstart_btn.fill_status = 0
				WriteModifiers()
			end
          end
        end
      end
    end   
  end

  function trimend_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", currTrimEnd)
        if ok then
		  
		  if tonumber(number) ~= nil then
            
			currTrimEnd = number  -- gianfini
			trimend_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			--for i=0, trackCount-1 do
              --local trackId = reaper.GetSelectedTrack(0, i)
              --local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
              --local length = currentName:len()
              --local newName = currentName:sub(1, length-number)
              --reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
            --end
          else
            if number ~= "" then
				reaper.MB("Please, type a number!", "This is not a number!", 0)
			else
				currTrimEnd = ""  -- gianfini: empty field means resetting Trim
				trimend_btn.fill_status = 0
				WriteModifiers()
			end
          end
        end
      end  
    elseif what == "items" then
      if CheckItems() then
        local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", currTrimEnd)
        if ok then
          if tonumber(number) ~= nil then
		  
			currTrimEnd = number  -- gianfini
			trimend_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			--[[
            for i=0, itemCount-1 do
              local itemId = reaper.GetSelectedMediaItem(0, i)
			  local acttake =  reaper.GetActiveTake( itemId )
              local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
              local length = currentName:len()
              local newName = currentName:sub(1, length-number)
              reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
            end
			]]--
			
          else
            if number ~= "" then
				reaper.MB("Please, type a number!", "This is not a number!", 0)
			else
				currTrimEnd = ""  -- gianfini: empty field means resetting Trim
				trimend_btn.fill_status = 0
				WriteModifiers()
			end
          end
        end
      end 
    end
  end
  
  function keep_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        local ok, text = reaper.GetUserInputs("Keep (s -> from start, e -> end)", 1, "Specify mode and number:", currKeep)
        if ok then
          if text:match("[seSE]%s?%d+") then
            currKeep = text --gianfini
			keep_btn.fill_status = 1
			WriteModifiers()	
			
			local newName = ""
            local mode, number = text:match("([seSE])%s?(%d+)")
            number = tonumber(number)
            
			--[[
			for i=0, trackCount-1 do
              local trackId = reaper.GetSelectedTrack(0, i)
              local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
              if mode:match("[sS]") then
                newName = currentName:sub(0, number)
              else
                newName = currentName:sub((-1)*number)
              end
              reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
            end
			]]--
			
          else
		  
			if text ~= "" then
				reaper.MB("Please type s or e followed by the number of characters you want to keep!\nExamples: s8 , E5 , S03 , e 12", "Not valid input!", 0)				
			else
				keep_btn.fill_status = 0  -- gianfini: emptying the field rest the modifier
				currKeep = ""
				WriteModifiers()
			end
        
          end
        end
      end  
    elseif what == "items" then
      if CheckItems() then
        local ok, text = reaper.GetUserInputs("Keep (s -> from start, e -> end)", 1, "Specify mode and number:", currKeep)        
        if ok then
          if text:match("[seSE]%s?%d+") then
            
			currKeep = text -- gianfini			
			keep_btn.fill_status = 1
			WriteModifiers() -- gianfini
			
			local newName = ""
            local mode, number = text:match("([seSE])%s?(%d+)")
            
			--[[
			for i=0, itemCount-1 do
              local itemId = reaper.GetSelectedMediaItem(0, i)
              local acttake =  reaper.GetActiveTake( itemId )
              if acttake then
                local _, currentName = reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", "", 0)
                if mode:match("[sS]") then
                  newName = currentName:sub(0, number)
                else
                  newName = currentName:sub((-1)*number)
                end
                reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(newName), 1)
              end
            end
			]]--
			
          else
			if text ~= "" then
				reaper.MB("Please type s or e followed by the number of characters you want to keep!\nExamples: s8 , E5 , S03 , e 12", "Not valid input!", 0)				
			else
				keep_btn.fill_status = 0  -- gianfini: emptying the field rest the modifier
				currKeep = ""
				WriteModifiers()
			end
          end
        end
      end
    end
  end
 
-- gianfini up and down 
  function UP_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        indexed_track = indexed_track - 1
		if indexed_track < 1 then indexed_track = 1 end
      end
	else
	  if CheckItems() then
		indexed_item = indexed_item - 1
		if indexed_item < 1 then indexed_item = 1 end
	  end
	end
  end
  
  function DOWN_btn.onClick()
    if what == "tracks" then
      if CheckTracks() then
        indexed_track = indexed_track + 1
      end
	else
	  if CheckItems() then
		indexed_item = indexed_item + 1
	  end
	end
  end

-- gianfini reset and commit  
  function reset_btn.onClick()
	Reset_Btn_Lbl_Colors()
	init_tables()
  end
  
  function commit_btn.onClick()
	-- insert here the writing to tracks
	if what == "tracks" then
		if CheckTracks() then
			for i=0, trackCount-1 do
				local trackId = reaper.GetSelectedTrack(0, i)
				reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(ToBeTrackNames[reaper.GetTrackGUID(trackId)]), 1)
			end
		end
	else
		if CheckItems() then
			for i=0, itemCount-1 do
				local itemId = reaper.GetSelectedMediaItem(0, i)
				local acttake = reaper.GetActiveTake(itemId)
				if acttake then
					reaper.GetSetMediaItemTakeInfo_String(acttake, "P_NAME", tostring(ToBeItemNames[reaper.BR_GetMediaItemTakeGUID(acttake)]), 1)
				end
			end
		end
	end
	Reset_Btn_Lbl_Colors()
	init_tables()	
  end
	
end -------------------------------- end of init() function


init()
reaper.defer(main)

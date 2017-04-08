-- @description amagalma_Track Name Manipulation
-- @author amagalma
-- @version 1.0
-- @about
--   # Utility to manipulate track names

-- @link http://forum.cockos.com/showthread.php?t=190534

-- Many thanks to spk77 and to Lokasenna for their code and help! :)

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
                        btn.r = 0.7
                        btn.g = 0.8
                        btn.b = 0.6
                        btn.a = 0.14
                        btn.lbl_r = 0.349
                        btn.lbl_g = 1
                        btn.lbl_b = 0.416
                        btn.lbl_a = 1
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

function Button:set_help_text()
  if self.help_text == "Replaces all instances of the pattern provided\n with the replacement" or
     self.help_text == "Removes specified number of characters\n from the start" or
     self.help_text == "Removes specified number of characters\n from the end" then
    gfx.y = strh + 6.75*strh*1.5 
  else
    gfx.y = strh + 7*strh*1.5
  end
    local hwidth = gfx.measurestr(self.help_text)
    gfx.x = (strw + strh*4.625 - hwidth)/2
    gfx.set(1,1,1,1)
    gfx.setfont(2, "Arial", 17)
    gfx.printf(self.help_text)
end

function Button:draw_label()
  -- Draw button label
  if self.label ~= "" then
    gfx.x = self.x1 + math.floor(0.5*self.w - 0.5 * self.label_w) -- center the label
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
  end  
  --gfx.a = self.a
  
  if self.__mouse_state == 1 or self.vis_state == 1 or self.__state_changing then
    --self.a = math.max(self.a - 0.2, 0.2)
    --gfx.set(0.8,0,0.8,self.a)
    gfx.set(0.8*self.r,0.8*self.g,0.8*self.b,math.max(self.a - 0.2, 0.2)*0.8)
    gfx.rect(self.x1, self.y1, self.w, self.h)

  -- Button is not pressed
  elseif not self.state_changing or self.vis_state == 0 or self.__mouse_state == 0 then
    gfx.set(self.r+0.2,self.g+0.2,self.b+0.2,self.a)
    gfx.rect(self.x1, self.y1, self.w, self.h)
   
    gfx.a = math.max(0.4*self.a, 0.6)
    -- light - left
    gfx.line(self.x1, self.y1, self.x1, self.y2-1)
    gfx.line(self.x1+1, self.y1+1, self.x1+1, self.y2-2)
    -- light - top
    gfx.line(self.x1+1, self.y1, self.x2-1, self.y1)
    gfx.line(self.x1+2, self.y1+1, self.x2-2, self.y1+1)

    --gfx.set(0.4,0,0.4,1)
    gfx.set(0.3*self.r,0.3*self.g,0.3*self.b,math.max(0.9*self.a,0.8))
    -- shadow - bottom
    gfx.line(self.x1+1, self.y2-1, self.x2-2, self.y2-1)
    gfx.line(self.x1+2, self.y2-2, self.x2-3, self.y2-2)
    -- shadow - right
    gfx.line(self.x2-1, self.y2-1, self.x2-1, self.y1+1)
    gfx.line(self.x2-2, self.y2-2, self.x2-2, self.y1+2)
  end
  
  
  self:draw_label()
end


--The code above is borrowed from spk77's "spk77_Button colors.lua" script found in ReaPack
-------------------------------------------------------------------------------------------


local function f() 
  gfx.setfont(1, "Arial", 19) -- SET HERE FONT SIZE (DEFAULT = 19)
end


local function Window_At_Center(w, h) -- Lokasenna function
  local l, t, r, b = 0, 0, w, h
  local __, __, screen_w, screen_h = reaper.my_getViewport(l, t, r, b, l, t, r, b, 1)
  local x, y = (screen_w - w) / 2, (screen_h - h) / 2
  gfx.init("Track Names Manipulation", w, h, 0, x, y)
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


local function compare_tables(t1, t2) -- Lokasenna function
  if #t1 ~= #t2 then return false end
  for k, v in pairs(t1) do
    if v ~= t2[k] then return false end
  end
  return true
end


-- Store all track names in a table
function AllTrackNames()
  local alltracks = reaper.CountTracks(0)
  local table = {}
  for i = 0, alltracks-1 do
    local tr = reaper.GetTrack( 0, i)
    local _, name =  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    table[reaper.GetTrackGUID(tr)] = name
  end
  return table
end


-- Check previous names of all tracks to their current names
function UndoIfNamesChanged()
  local AllCurrentTrackNames = AllTrackNames()
  if not compare_tables(AllCurrentTrackNames, AllLastTrackNames) then
    AllLastTrackNames = AllCurrentTrackNames
    reaper.Undo_OnStateChangeEx("Track name manipulation", 1, -1)
  end
end


local function main() -- MAIN FUNCTION
  -- Draw buttons
  f(); prefix_btn:draw()
  f(); suffix_btn:draw()
  f(); trimstart_btn:draw()
  f(); trimend_btn:draw()
  f(); replace_btn:draw()
  f(); upper_btn:draw()
  f(); lower_btn:draw()
  f(); swap_btn:draw()
  f(); capitalize_btn:draw()
  f(); title_btn:draw()
  f(); strip_btn:draw()
  
  -- Check every one second to see if the track selection has changed
  local newtime=os.time()
  if newtime-lasttime >= 1 then
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
  
  -- Check left mouse btn state
  if gfx.mouse_cap & 1 == 0 then
    last_mouse_state = 0
  else last_mouse_state = 1 end
  gfx.update()
  if gfx.getchar() >= 0 then reaper.defer(main)
  else UndoIfNamesChanged()
  end
end


local function init() -- INITIALIZATION
  -- Store initial track selection so that there can be a comparison in main()
  trackCount = reaper.CountSelectedTracks(0)
  sel_tracks = {}
  for i = 1, trackCount do
    sel_tracks[i] = reaper.GetSelectedTrack(0, i - 1)
  end
  -- Store all track names before any manipulation so that there can be a comparison afterwards
  AllLastTrackNames = AllTrackNames()
  -- Initialize timer
  lasttime = os.time()
  f() -- set font
  strw, strh = gfx.measurestr("Strip leading & trailing whitespaces")
  gfx.clear = 3084036
  Window_At_Center(strw + strh*3 ,strh + 8*strh*1.5)
  -- parameters: Button(x1,y1,w,h,state_count,state,visual_state,lbl,help_text)
  local label, help = "Prefix", "Inserts text at the begining"
  local width, height = gfx.measurestr(label)
  prefix_btn = Button(strh, strh, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Suffix", "Appends text to the end"
  local width, height = gfx.measurestr(label)
  suffix_btn = Button(strw + strh*2 - (width + strh), strh, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Trim Start", "Removes specified number of characters\n from the start"
  local width, height = gfx.measurestr(label)
  trimstart_btn = Button(strh, strh + strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Trim end", "Removes specified number of characters\n from the end"
  local width, height = gfx.measurestr(label)
  trimend_btn = Button(strw + strh*2 - (width + strh), strh + strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Replace", "Replaces all instances of the pattern provided\n with the replacement"
  local width, height = gfx.measurestr(label)
  replace_btn = Button((strw + strh*2 - width)/2, strh + 5*strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Uppercase", "Converts all letters to UPPERCASE"
  local width, height = gfx.measurestr(label)
  upper_btn = Button(strh, strh + 2*strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Lowercase", "Converts all letters to lowercase"
  local width, height = gfx.measurestr(label)
  lower_btn = Button(strw + strh*2 - (width + strh), strh + 2*strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Swap case", "Inverts the case of each letter (eg Do => dO)"
  local width, height = gfx.measurestr(label)
  swap_btn = Button((strw + strh*2 - width)/2, strh + 3*strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Capitalize", "Capitalizes the very first letter"
  local width, height = gfx.measurestr(label)
  capitalize_btn = Button(strh, strh + 4*strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Titlecase", "Capitalizes The First Letter Of Each Word"
  local width, height = gfx.measurestr(label)
  title_btn = Button(strw + strh*2 - (width + strh), strh + 4*strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)
  
  local label, help = "Strip leading & trailing whitespaces", "Removes all leading and trailing whitespaces"
  local width, height = gfx.measurestr(label)
  strip_btn = Button(strh, strh + 6*strh*1.5, width + strh, height + strh/8, 2, 0, 0, label, help)            

-- BUTTON FUNCTIONS
  function prefix_btn.onClick()
    if CheckTracks() then
      local ok, text = reaper.GetUserInputs("Prefix", 1, "Insert text:", "")
      if ok then
        for i=0, trackCount-1 do
          local trackId = reaper.GetSelectedTrack(0, i)
          local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          local newName = text .. currentName
          reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        end
      end
    end
  end

  function suffix_btn.onClick()
    if CheckTracks() then
      local ok, text = reaper.GetUserInputs("Suffix", 1, "Insert text:", "")
      if ok then
        for i=0, trackCount-1 do
          local trackId = reaper.GetSelectedTrack(0, i)
          local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          local newName = currentName .. text
          reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        end
      end
    end  
  end

  function replace_btn.onClick()
    if CheckTracks() then
      local ok, retvals = reaper.GetUserInputs("Replace", 2, "Pattern:,Replacement:", "")
      if ok then
        if retvals ~= ",," then
        words = {}
        for word in retvals:gmatch("[^,]+") do table.insert(words, word) end
        local replaceOld = words[1]
        local replaceWith = words[2] or ""
        for i=0, trackCount-1 do
          local trackId = reaper.GetSelectedTrack(0, i)
          local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
          local newName = string.gsub(currentName, replaceOld, replaceWith)
          reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
        end
        end
      end
    end  
  end

  function upper_btn.onClick()
    if CheckTracks() then
      for i=0, trackCount-1 do
        local trackId = reaper.GetSelectedTrack(0, i)
        local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
        local newName = string.upper(currentName)
        reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
      end
    end  
  end

  function lower_btn.onClick()
    if CheckTracks() then
      for i=0, trackCount-1 do
        local trackId = reaper.GetSelectedTrack(0, i)
        local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
        local newName = string.lower(currentName)
        reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
      end
    end  
  end

  function swap_btn.onClick()
    if CheckTracks() then
      for i=0, trackCount-1 do
        local trackId = reaper.GetSelectedTrack(0, i)
        local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
        local newName = swapcase(currentName)
        reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
      end
    end  
  end

  function capitalize_btn.onClick()
    if CheckTracks() then
      for i=0, trackCount-1 do
        local trackId = reaper.GetSelectedTrack(0, i)
        local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
        local newName = (currentName:gsub("^%l", string.upper))
        reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
      end
    end  
  end

  function title_btn.onClick()
    if CheckTracks() then
      for i=0, trackCount-1 do
        local trackId = reaper.GetSelectedTrack(0, i)
        local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
        local newName = string.gsub(" "..currentName, "%W%l", string.upper):sub(2)
        reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
      end
    end  
  end

  function strip_btn.onClick()
    if CheckTracks() then
      for i=0, trackCount-1 do
        local trackId = reaper.GetSelectedTrack(0, i)
        local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
        local newName = currentName:match("^%s*(.-)%s*$")
        reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
      end
    end  
  end

  function trimstart_btn.onClick()
    if CheckTracks() then
      local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", "")
      if ok then
        if tonumber(number) ~= nil then
          for i=0, trackCount-1 do
            local trackId = reaper.GetSelectedTrack(0, i)
            local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
            local newName = currentName:sub(number+1)
            reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
          end
        else
          reaper.MB("Please, type a number!", "This is not a number!", 0)
        end
      end
    end  
  end

  function trimend_btn.onClick()
    if CheckTracks() then
      local ok, number = reaper.GetUserInputs("Trim start", 1, "Insert number of characters:", "")
      if ok then
        if tonumber(number) ~= nil then
          for i=0, trackCount-1 do
            local trackId = reaper.GetSelectedTrack(0, i)
            local _, currentName = reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", "", 0)
            local length = currentName:len()
            local newName = currentName:sub(1, length-number)
            reaper.GetSetMediaTrackInfo_String(trackId, "P_NAME", tostring(newName), 1)
          end
        else
          reaper.MB("Please, type a number!", "This is not a number!", 0)
        end
      end
    end  
  end
end -------------------------------- end of init() function


init()
reaper.defer(main)

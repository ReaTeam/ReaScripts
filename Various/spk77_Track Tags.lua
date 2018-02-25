-- @description Track Tags (based on Tracktion 6 track tags)
-- @version 0.1
-- @author spk77
-- @changelog
--   Create tags from folder parents: don't create new buttons if folder(s) already tagged
-- @links
--   Forum Thread https://forum.cockos.com/showthread.php?t=203446
-- @donation https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=5NUK834ZGR5NU&lc=FI&item_name=SPK77%20scripts%20for%20REAPER&currency_code=EUR&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted
-- @screenshot https://forum.cockos.com/showpost.php?p=1956530&postcount=1
-- @about
--   # Track Tags
--
--   This script is based on Tracktion 6 track tags
--
--   ## Screenshot
--
--   https://forum.cockos.com/showpost.php?p=1956530&postcount=1
--
--   ## Main Features
--
--   - Show and hide tagged track groups from TCP/MCP
--
--   ## Known Issues/Limitations
--
--   - This is an alpha version

local Pickle = { clone = function (t) local nt={}; for i, v in pairs(t) do nt[i]=v end return nt end }

function pickle(t)
  return Pickle:clone():pickle_(t)
end

------------------------------------PICKLE------------------------------------

function Pickle:pickle_(root)
  if type(root) ~= "table" then error("can only pickle tables, not ".. type(root).."s") end
  self._tableToRef = {}
  self._refToTable = {}
  local savecount = 0
  self:ref_(root)
  local s = ""
  
  while #self._refToTable > savecount do
    savecount = savecount + 1
    local t = self._refToTable[savecount]
    s = s.."{\n"
    
    for i, v in pairs(t) do
        s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
    end
    s = s.."},\n"
  end

  return string.format("{%s}", s)
end

function Pickle:value_(v)
  local vtype = type(v)
  if     vtype == "string" then return string.format("%q", v)
  elseif vtype == "number" then return v
  elseif vtype == "boolean" then return tostring(v)
  elseif vtype == "table" then return "{"..self:ref_(v).."}"
  else error("pickle a "..type(v).." is not supported")
  end  
end

function Pickle:ref_(t)
  local ref = self._tableToRef[t]
  if not ref then 
    if t == self then error("can't pickle the pickle class") end
    table.insert(self._refToTable, t)
    ref = #self._refToTable
    self._tableToRef[t] = ref
  end
  return ref
end
----------------------------------------------
-- unpickle
----------------------------------------------
function unpickle(s)
  if type(s) ~= "string" then error("can't unpickle a "..type(s)..", only strings") end
  local gentables = load("return "..s)
  local tables = gentables()
  for tnum = 1, #tables do
    local t = tables[tnum]
    local tcopy = {}; for i, v in pairs(t) do tcopy[i] = v end
    for i, v in pairs(tcopy) do
      local ni, nv
      if type(i) == "table" then ni = tables[i[1]] else ni = i end
      if type(v) == "table" then nv = tables[v[1]] else nv = v end
      t[i] = nil
      t[ni] = nv
    end
  end
  return tables[1]
end
------------------------------------PICKLE------------------------------------


function get_project_filename(proj)
  local ret, proj_filename = reaper.EnumProjects(-1, "")
  if ret then
    return proj_filename
  end
  return ret
end


local script =  {
                  title = "Track Tags",
                  project_filename = get_project_filename(-1)
                }


local GUI = {}
GUI.elements =  {
                  buttons = {}
                }

GUI.safe_remove_btn_by_index = -1     -- remove button by index
GUI.safe_remove_track_from_tag = {}   -- remove tagged track from button
GUI.safe_remove_all_tags = false
GUI.dock = 0
            
local track_list = {}

local main_menu = {}
main_menu.str = ""
main_menu.quit = false
main_menu.show_only_tagged_tracks = true
main_menu.button_layout = 3 -- 1=fit to window, 2=horizontal, 3=vertical
main_menu.min_btn_w = 48

local button_menu = {}
button_menu.str = ""
button_menu.show_in_tcp = true
button_menu.show_in_mcp = true

local char
local loop_count = 0
local GetProjectStateChangeCount = reaper.GetProjectStateChangeCount
local proj_change_count, last_proj_change_count = 0, 0


local btn_font = "Arial"
local btn_font_size = 14

local btn_start_x = 8
local btn_start_y = 8
local btn_w = 48              -- width for new buttons
local btn_h = 14              -- height for new buttons
local btn_pad_x = 3           -- x space between buttons
local btn_pad_y = 5           -- y space between buttons

local mouse_ox, mouse_oy = -1, -1
local m_cap = 0

local last_hovered_element = {}

local mouseRClickOnElement = false
local mouse_on_element = false
local mouse_on_element_index = -1

local tooltip_text, last_tooltip_text = "", ""


local gui_w, last_gui_w = -1, -1
local gui_h, last_gui_h = -1, -1
local last_mouse_cap = 0
local last_x, last_y = 0, 0
--local visible_tracks = {}
--track_list = {}

-- Tracktion 6 track tags colors
local btn_on_bg_col_r = 112/255
local btn_on_bg_col_g = 124/255
local btn_on_bg_col_b = 137/255
local btn_on_bg_col_a = 1

local btn_off_bg_col_r = 255/255
local btn_off_bg_col_g = 255/255
local btn_off_bg_col_b = 26/255
local btn_off_bg_col_a = 1

local gfx = gfx
local reaper = reaper
----------------------------------------------------------------------

function msg(m)
  return reaper.ShowConsoleMsg(tostring(m) .. "\n")
end


function show_all()
  reaper.PreventUIRefresh(1)
  for i=1, reaper.CountTracks(0) do
    local tr = reaper.GetTrack(0, i-1)
    if tr then
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 1)
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 1)
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
end


function hide_all()
  reaper.PreventUIRefresh(1)
  for i=1, reaper.CountTracks(0) do
    local tr = reaper.GetTrack(0, i-1)
    if tr then
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 1)
      reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 1)
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.TrackList_AdjustWindows(false)
end


function sort_buttons_by_tag_name()
  local btns = GUI.elements.buttons
  table.sort(btns, function(a,b) if string.lower(a.lbl) < string.lower(b.lbl) then return true end end)
end



function update_visibility()
  if main_menu.show_only_tagged_tracks then
    local btns = GUI.elements.buttons
    local all_btns_off = true--visible_tracks = {}
    local tr_count = reaper.CountTracks(0)
    reaper.PreventUIRefresh(1)
    if #btns > 0 then
      for i=1, tr_count do
        local tr = reaper.GetTrack(0, i-1)
        --reaper.SetTrackSelected(tr, false)
        reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 0)
        reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 0)
      end
      for i=1, #btns do
        local b = btns[i]
        b.show_mixer = true
        if b.toggle_state then
          if all_btns_off then
            all_btns_off = false
          end
          for t=1, #b.tracks do
            local tr = b.tracks[t]
            if reaper.ValidatePtr(tr, "MediaTrack*") then
              --visible_tracks[#visible_tracks+1] = tr
              reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINTCP", 1)
              reaper.SetMediaTrackInfo_Value(tr, "B_SHOWINMIXER", 1)
            else
              --GUI.safe_remove_track_from_tag[#GUI.safe_remove_track_from_tag + 1] = {i, t} -- i = button index, t = track index
            end
          end
          reaper.Main_OnCommand(reaper.NamedCommandLookup("_XENAKIOS_TVPAGEHOME"), 0)
        end
      end
      
-- TODO: better way to unselect hidden tracks
--[[
      local is_vis = reaper.IsTrackVisible
      local set_sel = reaper.SetTrackSelected
      for i=1, tr_count do
        local tr = reaper.GetTrack(0, i-1)
        if tr then
          if not is_vis(tr, false) then-- and not is_vis(tr, true) then
            set_sel(tr, false)
          end
        end
      end
--]]        
    end
    
    if all_btns_off then
      show_all()
    end
    
    reaper.PreventUIRefresh(-1)
    reaper.TrackList_AdjustWindows(false)
    reaper.UpdateArrange()
  end
end


function show_main_menu(x, y)
  gfx.x, gfx.y = x or gfx.mouse_x, y or gfx.mouse_y
  local m = main_menu
  --m.str = "Create new tag|"
  m.str = ">Create new tag(s) from...|"
  if reaper.CountSelectedTracks(0) > 0 then
    m.str = m.str .. "Track selection|"
  else
    m.str = m.str .. "#Track selection|"
  end
  m.str = m.str .."<Folder parent tracks|"
  if m.show_only_tagged_tracks then
    m.str = m.str .. "!Show only tagged tracks||"
  else
    m.str = m.str .. "Show only tagged tracks||"
  end
  m.str = m.str .. ">Remove|"
  m.str = m.str .. "<All tags|"
  m.str = m.str .. ">Layout|"
  if m.button_layout == 1 then
    m.str = m.str .. "!Fit to window|"
    m.str = m.str .. "Horizontal|"
    m.str = m.str .. "<Vertical||"
  elseif m.button_layout == 2 then
      m.str = m.str .. "Fit to window|"
      m.str = m.str .. "!Horizontal|"
      m.str = m.str .. "<Vertical||"
  elseif m.button_layout == 3 then
    m.str = m.str .. "Fit to window|"
    m.str = m.str .. "Horizontal|"
    m.str = m.str .. "!<Vertical||"
  end
  m.str =  m.str .. "Quit"
  menu_ret = gfx.showmenu(m.str)
  
  --if menu_ret == 1 then 
    --create_button()
  if menu_ret == 1 then
    create_button_from_selection()
  elseif menu_ret == 2 then
    create_buttons_from_folder_parents()
  elseif menu_ret == 3 then
    m.show_only_tagged_tracks = not m.show_only_tagged_tracks
    if not m.show_only_tagged_tracks then
      show_all()
      reaper.TrackList_AdjustWindows(false)
    else
      update_visibility()
    end
  elseif menu_ret == 4 then
    GUI.safe_remove_all_tags = true
  elseif menu_ret == 5 then
    m.button_layout = 1
    update_button_positions()
  elseif menu_ret == 6 then
    m.button_layout = 2
    update_button_positions()
  elseif menu_ret == 7 then
    m.button_layout = 3
    update_button_positions()
    
  elseif menu_ret == 8 then
    exit()
    --return
  end
end

--[[
  Wrapper for gfx.roundrect() with optional fill,
  adapted from mwe's EEL example on the forum.
  
  by Lokasenna
]]--

local function roundrect(x, y, w, h, r, fill, antialias)
  
  local aa = antialias or 1
  -- If we aren't filling it in, the original function is fine
  if fill == 0 or false then
    gfx.roundrect(x, y, w, h, r, aa)
    
  else
    
    -- Corners
    gfx.circle(x + r, y + r, r, 1, aa)
    gfx.circle(x + w - r, y + r, r, 1, aa)
    gfx.circle(x + w - r, y + h - r, r , 1, aa)
    gfx.circle(x + r, y + h - r, r, 1, aa)
    
    -- Ends
    gfx.rect(x, y + r, r, h - r * 2)
    gfx.rect(x + w - r, y + r, r + 1, h - r * 2)
      
    -- Body + sides
    gfx.rect(x + r, y, w - r * 2, h + 1)
  end  
  
end


local Element = {}
function Element:new(x,y,w,h, r,g,b,a, lbl,fnt,fnt_sz, lbl_r, lbl_g, lbl_b, lbl_a, norm_val, toggle_state)
    local elm = {}
    --elm.def_xywh = {x,y,w,h,fnt_sz}
    elm.x, elm.y, elm.w, elm.h = x, y, w, h
    elm.r, elm.g, elm.b, elm.a = r, g, b, a
    elm.lbl, elm.fnt, elm.fnt_sz  = lbl, fnt, fnt_sz
    elm.lbl_r, elm.lbl_g, elm.lbl_b, elm.lbl_a =  lbl_r, lbl_g, lbl_b, lbl_a
    elm.norm_val = norm_val
    elm.toggle_state = toggle_state or false
    setmetatable(elm, self)
    self.__index = self 
    return elm
end

function extended(Child, Parent)
  setmetatable(Child,{__index = Parent})
end

function Element:update_xywh()
  if not Z_w or not Z_h then return end -- return if zoom not defined
  if Z_w>0.5 and Z_w<3 then  
   self.x, self.w = math.ceil(self.def_xywh[1]* Z_w) , math.ceil(self.def_xywh[3]* Z_w) --upd x,w
  end
  if Z_h>0.5 and Z_h<3 then
   self.y, self.h = math.ceil(self.def_xywh[2]* Z_h) , math.ceil(self.def_xywh[4]* Z_h) --upd y,h
  end
  if Z_w>0.5 or Z_h>0.5  then --fix it!--
     self.fnt_sz = math.max(9,self.def_xywh[5]* (Z_w+Z_h)/2)
     self.fnt_sz = math.min(22,self.fnt_sz)
  end       
end


function Element:pointIN(p_x, p_y)
  return p_x >= self.x and p_x <= self.x + self.w and p_y >= self.y and p_y <= self.y + self.h
end

function Element:mouseIN()
  return gfx.mouse_cap & 1 == 0 and gfx.mouse_cap & 2 == 0 and self:pointIN(gfx.mouse_x,gfx.mouse_y)
end

function Element:mouseLDown()
  return gfx.mouse_cap & 1 == 1 and self:pointIN(mouse_ox, mouse_oy)
end

function Element:mouseRDown()
  return gfx.mouse_cap & 2 == 2 and self:pointIN(mouse_ox, mouse_oy)
end

function Element:mouseLClick()
  return gfx.mouse_cap & 1 == 0 and last_mouse_cap & 1 == 1 and
  self:pointIN(gfx.mouse_x, gfx.mouse_y) and self:pointIN(mouse_ox, mouse_oy)         
end

function Element:mouseRClick()
  return gfx.mouse_cap & 2 == 0 and last_mouse_cap & 2 == 2 and
  self:pointIN(gfx.mouse_x, gfx.mouse_y) and self:pointIN(mouse_ox, mouse_oy)         
end

function Element:mouseUp()
  return gfx.mouse_cap & 1 == 0 and self:pointIN(mouse_ox, mouse_oy)
end

--------------------------------------------------------------------------------

local Button = {}
extended(Button, Element)


function Button:set_lbl_colors(r,g,b,a)
  self.lbl_r = r or 1
  self.lbl_g = g or 1
  self.lbl_b = b or 1
  self.lbl_a = a or 1
end


function Button:set_colors(r,g,b,a)
  self.r = r or 1
  self.g = g or 1
  self.b = b or 1
  self.a = a or 1
end


function Button:update_w_by_lbl_w(min_w, max_w)
  self.lbl_w, self.lbl_h = gfx.measurestr(self.lbl)
  self.w = math.max(self.lbl_w + 8, main_menu.min_btn_w)
end


function Button:draw_lbl()
  local x, y, w, h = self.x, self.y, self.w, self.h
  local fnt, fnt_sz = self.fnt, self.fnt_sz
  local r, g, b, a = self.lbl_r, self.lbl_g, self.lbl_b, self.lbl_a
  local lbl_w, lbl_h = self.lbl_w, self.lbl_h
  gfx.set(r, g, b, a)
  --gfx.setfont(1, fnt, fnt_sz)
  gfx.x = x + 0.5 * (w - lbl_w)
  gfx.y = y + 0.5 * (h - lbl_h)
  gfx.drawstr(self.lbl)
end


function Button:draw(index) -- index = current button table in GUI.elements.buttons table
  local x,y,w,h  = self.x, self.y, self.w, self.h
  
  if self.toggle_state then
    self:set_colors(btn_off_bg_col_r, btn_off_bg_col_g, btn_off_bg_col_b, btn_off_bg_col_a)
    self:set_lbl_colors(0.1, 0.1, 0.1, 1)
  else
    self:set_colors(btn_on_bg_col_r, btn_on_bg_col_g, btn_on_bg_col_b, btn_on_bg_col_a)
    self:set_lbl_colors(1, 1, 1, 1)
  end
  
  if self:mouseIN() then
    mouse_on_element = true
    last_hovered_element = self
    if self.onMouseOver then
      self.onMouseOver()
    end
  end
  if self:mouseLClick() and self.onLClick then
    self.toggle_state = not self.toggle_state
    self.onLClick()

  elseif self:mouseRClick() and self.onRClick then
    mouseRClickOnElement = true
    self.onRClick(index)
  end
  
  local r,g,b,a  = self.r,self.g,self.b,self.a
  gfx.set(r,g,b,a)--set btn color
  roundrect(x,y,w,h,0.5*h)--body
  self:draw_lbl()
end


function update_button_positions(w, h)
  local btns = GUI.elements.buttons
  local len_btns = #btns
  if len_btns == 0 then
    return
  end
  local w, h = w or gfx.w, h or gfx.h
  local curr_row = 0
  local x = btn_start_x
  local y = btn_start_y
  local mlo = main_menu.button_layout
  for i=1, len_btns do
    local b = btns[i]
    -- fit to window
    if mlo == 1 then
      if i>1 and x + b.w > w then
        x = btn_start_x
        y = y + b.h + btn_pad_y
        curr_row = curr_row + 1
      end
    -- horizontal
    elseif mlo == 2 then
    -- vertical
    elseif mlo == 3 then
      y = btn_start_y + curr_row*(b.h + btn_pad_y)
      curr_row = curr_row + 1
    end
    b.x = x
    b.y = y
    if mlo < 3 then
      x = x + b.w + btn_pad_x
    end
    --end
  end
end


function on_gui_resize(w, h)
  update_button_positions(w, h)
end
     
                          
function draw_and_update_buttons(tbl)
  local l = #tbl
  for i=1, l do
    local t = tbl[i]
    t:draw(i)
    if t:mouseIN() then
      mouse_on_element_index = i
    end
  end
  if l == 0 then 
    gfx.x, gfx.y = 8,8
    gfx.set(1,1,1,1)
    gfx.drawstr("No tags assigned\nRight click to open the menu")
  end
  gfx.update()
end


function create_button()
  local btns = GUI.elements.buttons
  local btn = Button:new(   
                          0,                    --  x
                          0,                    --  y 
                          btn_w,                --  w
                          btn_h,                --  h
                          0.5,                  --  r
                          0.5,                  --  g
                          0.5,                  --  b
                          1.0,                  --  a
                          "Tag " .. #btns + 1,  --  lbl (button name)
                          "Arial",              --  label font
                          14,                   --  label font size
                          1,                    -- label color r
                          1,                    -- label color g
                          1,                    -- label color b
                          1,                    -- label color a
                          0,                    -- norm_val
                          false                 -- toggle state
                        )
  
  btn:set_colors(112/255, 124/255, 137/255, 1)
  btn.tracks = {}
  btn.type = ""
  btn.tooltip_text = ""
  btn.lbl_w, btn.lbl_h = 0, 0
  
  btn.onLClick =  function()
                    for i=1, #btn.tracks do
                      local tr = btn.tracks[i]
                      if btn.toggle_state then
                      else
                      end
                    end
                    --reaper.defer(update_visibility)
                    update_visibility()
                  end
                  
  btn.onRClick =  function(buttonindex)
                    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
                    local m = button_menu
                    m.str = "Rename tag|"
                    m.str = m.str .. "Remove tag|"
                    --[[
                    m.str = m.str .. ">Options|"
                    if button_menu.show_in_tcp then
                      m.str = m.str .. "Show in TCP|"
                    else
                      m.str = m.str .. "!Show in TCP|"
                    end
                    
                    if button_menu.show_in_mcp then
                      m.str = m.str .. "Show in TCP|"
                    else
                      m.str = m.str .. "!Show in TCP|"
                    end
                    m.str = m.str .. "Show Mixer|"
                    --]]
                    local ret = gfx.showmenu(m.str)
                    if ret == 1 then
                      local retval, retvals_csv = reaper.GetUserInputs("Rename", 1, "Set new name:", btn.lbl)
                      if retval then
                        btn.lbl = retvals_csv
                        btn:update_w_by_lbl_w()
                      end
                      sort_buttons_by_tag_name()
                      update_button_positions()
                    elseif ret == 2 then
                      GUI.safe_remove_btn_by_index = buttonindex
                      --msg(buttonindex)
                    end
                  end
  
  btn.onMouseOver = function()
                    end 
    
  btn.id = tostring(reaper.time_precise())
  btns[#btns + 1] = btn
  btn:update_w_by_lbl_w()
  sort_buttons_by_tag_name()
  update_button_positions()             
  btn:update_w_by_lbl_w()
  btn.tooltip_text = btn.lbl
  return btn
end

 
function create_button_from_selection()
  local btns = GUI.elements.buttons
  local sel_tr_count = reaper.CountSelectedTracks(0)
  local btn = create_button()
  if sel_tr_count == 0 then
    return
  end

  for i=1, reaper.CountSelectedTracks(0) do     -- loop through selected tracks
    local tr = reaper.GetSelectedTrack(0, i-1)
--[[
    name = ""
    for str in string.gmatch(GUID, "([^".. "-".."]+)") do
       name = name .. str
    end
--]]
    local retval, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
    if i==1 then
      if retval then
        btn.lbl = tr_name
        btn:update_w_by_lbl_w()
      end
    end
    btn.tracks[#btn.tracks+1] = tr
    btn.tooltip_text = btn.tooltip_text .. tr_name .. "\n"
  end
  sort_buttons_by_tag_name()
  update_button_positions()
end


function create_buttons_from_folder_parents()
  local btns = GUI.elements.buttons
  local tr_count = reaper.CountTracks(0)
  local current_depth = 0
  local depth_change = 0
  for i=1, tr_count do
    local tr = reaper.GetTrack(0, i-1)
    depth_change = reaper.GetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH")
    current_depth = current_depth + depth_change
    if depth_change == 1 then -- folder parent found
      local is_parent_tagged = false
      for i=1, #btns do
        curr_tag_first_tr = btns[i].tracks[1] -- folder parent track is always the first track
        if curr_tag_first_tr == tr then
          if btns[i].type == "folder parent" then -- folder parent already tagged?
            is_parent_tagged = true
            btn_index = i -- button already exists -> store index
            break
          end
        end
      end

    -- Add buttons
      local d = current_depth
      local btn = {}
      -- No tag-button for this folder parent -> create new tag-button
      if not is_parent_tagged then
        btn = create_button()
        btn.tracks[#btn.tracks+1] = tr
        btn.type = "folder parent"
      -- Tag-button exists
      else
        btn = btns[btn_index]
        for i=2, #btn.tracks do -- remove all children
          btn.tracks[i] = nil
        end
      end
      local retval, tr_name = reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      if retval then
        btn.tooltip_text = btn.tooltip_text .. tr_name .. "\n"
        btn.lbl = tr_name
        btn:update_w_by_lbl_w()
      end
    --end
    
    -- Find last child track
      local j = 1
      while true do
        local child_tr = reaper.GetTrack(0, i-1+j)
        d = d + reaper.GetMediaTrackInfo_Value(child_tr, "I_FOLDERDEPTH")
        local retval, tr_name = reaper.GetSetMediaTrackInfo_String(child_tr, "P_NAME", "", false)
        --local btn = btns[btn_index]
        btn.tracks[#btn.tracks+1] = child_tr
        if d < current_depth or (i-1+j == tr_count - 1) then
          break
        end
        j = j + 1
      end
    end
--[[
    name = ""
    for str in string.gmatch(GUID, "([^".. "-".."]+)") do
       name = name .. str
    end
--]]
  end
  sort_buttons_by_tag_name()
  update_button_positions()
end


function on_track_list_change(last_action_undo_str)
  create_buttons_from_folder_parents() -- tags only new tracks
  update_visibility()
  --msg(last_action_undo_str)
end


function init()
  --track_list = get_track_info()
  local left, top, right, bottom = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, 0)
  local center_w = 0.5*(right-left)
  local center_h = 0.5*(bottom-top)
  local w = 0.1*(right-left)
  local h = w -- 0.1*(bottom-top)
  
  local ok, state = reaper.GetProjExtState(0, "spk77 Track Tags", "GUI_dock_state")
  local dock = state or 0
  gfx.clear = 3355443  -- matches with "FUSION: Pro&Clean Theme :: BETA 01" http://forum.cockos.com/showthread.php?t=155329
                       -- (Double click in ReaScript IDE to open the link)   
  gfx.init(title, w, h, dock, center_w-0.5*w, center_h-0.5*h)
  gfx.setfont(1, btn_font, btn_font_size)
  last_proj_change_count = reaper.GetProjectStateChangeCount(0)
  gui_w, gui_h = gfx.w, gfx.h
  last_gui_w, last_gui_h = gui_w, gui_h
  restore()
end


function mainloop()
  local btns = GUI.elements.buttons
  local m_x, m_y = gfx.mouse_x, gfx.mouse_y
  m_cap = gfx.mouse_cap
  if m_cap&1==1 and last_mouse_cap&1==0 or m_cap&2==2 and last_mouse_cap&2==0 then
    mouse_ox, mouse_oy = m_x, m_y
  end
  
  draw_and_update_buttons(btns)
  char = gfx.getchar()
  
  -- Show main menu on mouse right click
  if m_cap&2==0 and last_mouse_cap & 2 == 2 and not mouseRClickOnElement then
    show_main_menu(m_x, m_y)
  end

  last_mouse_cap = m_cap
  last_x, last_y = m_x, m_y
  last_tooltip_text = tooltip_text

  gui_w, gui_h = gfx.w, gfx.h
  if gui_w ~= last_gui_w or gui_h ~= last_gui_h then
    on_gui_resize(gui_w, gui_h)
    last_gui_w, last_gui_h = gui_w, gui_h
  end

  if m_cap == 0 then mouseRClickOnElement = false end
  if not mouse_on_element then last_hovered_element = {} end
  mouse_on_element = false
  
  -- Remove button outside the drawing loop
  if GUI.safe_remove_btn_by_index > -1 then
    --msg(GUI.safe_remove_btn_by_index)
    --msg(btns[GUI.safe_remove_btn_by_index].lbl)
    table.remove(btns, GUI.safe_remove_btn_by_index)
    update_button_positions()
    update_visibility()
    GUI.safe_remove_btn_by_index = -1
  elseif GUI.safe_remove_all_tags then
    GUI.elements.buttons = nil
    GUI.elements.buttons = {}
    GUI.safe_remove_all_tags = false
  end

  local proj_change_count = GetProjectStateChangeCount(0)
  if proj_change_count > last_proj_change_count then
    local last_action = reaper.Undo_CanUndo2(0)
    -- try to catch changes in track list
    if last_action ~= nil then
      if last_action:lower():find("track") and not last_action:lower():find("selection") then
        on_track_list_change(last_action)
      end
    end
    last_proj_change_count = proj_change_count
  end

  if char~=-1 then reaper.defer(mainloop) end
  --gfx.update()
end
--------------------------------------------------------------------------------


function exit()
  save_btns()
  GUI.dock, x, y, w, h = gfx.dock(-1,0,0,0,0)
  local size = reaper.SetProjExtState(0, "spk77 Track Tags", "GUI_dock_state", GUI.dock)
  gfx.quit()
  show_all()
end


function save_btns()
  local btns = GUI.elements.buttons
  local btn_data = {}
  --local test = {}
  
  for k,v in pairs(btns) do
    local valid_guids = {}
    --test[#test+1] = {lbl = v.lbl, tracks = v.tracks}
    for i = 1, #v.tracks do
      local tr = v.tracks[i]
      if reaper.ValidatePtr(tr, "MediaTrack*") then
        local guid_str = reaper.GetTrackGUID(tr)
        valid_guids[#valid_guids+1] = guid_str
        --msg(guid_str)
      end
    end
    btn_data[#btn_data+1] = {
                              lbl = v.lbl,
                              tracks = valid_guids,
                              type = v.type,
                              toggle_state = v.toggle_state
                            }
  end
  local size = reaper.SetProjExtState(0, "spk77 Track Tags", "buttons", pickle(btn_data))
  --local size = reaper.SetProjExtState(0, "SPK77", "btn", "")
  --msg(pickle(btn_data))
end

function restore()
  local btns = GUI.elements.buttons
  local ok, state = reaper.GetProjExtState(0, "spk77 Track Tags", "buttons")
  if state ~= "" then state = unpickle(state)
    for i = 1, #state do
      local btn = create_button()
      local tr_guids = state[i].tracks
      for j = 1, #tr_guids do
        local guid = tr_guids[j]
        local tr = reaper.BR_GetMediaTrackByGUID(0, guid) 
        if reaper.ValidatePtr(tr, "MediaTrack*") then
          btn.tracks[#btn.tracks+1] = tr
          --msg(guid_str)
        end
      end
      btn.lbl = state[i].lbl
      btn.tooltip_text = state[i].lbl
      btn.type = state[i].type
      btn.toggle_state = state[i].toggle_state
      btn:update_w_by_lbl_w()
    end
  end
  sort_buttons_by_tag_name()
  update_button_positions()
  update_visibility()
end

init()
reaper.atexit(exit)
mainloop()

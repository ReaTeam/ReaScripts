-- @description Edit Group Management Utility_amagalma
-- @version 1.2
-- @author amagalma
-- @about Utility to mimick ProTools' Edit Groups - based on Spacemen Tree's "REAzard of Oz"
-- @link Forum thread https://forum.cockos.com/showthread.php?t=195797
-- @provides
--   [main] .
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 1 (Edit Group Management Utility _ amagalma).lua
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 2 (Edit Group Management Utility _ amagalma).lua
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 3 (Edit Group Management Utility _ amagalma).lua
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 4 (Edit Group Management Utility _ amagalma).lua
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 5 (Edit Group Management Utility _ amagalma).lua
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 6 (Edit Group Management Utility _ amagalma).lua
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 7 (Edit Group Management Utility _ amagalma).lua
--   [main] amagalma_Toggle Edit Group (Edit Group Management Utility).lua > Toggle Edit Group 8 (Edit Group Management Utility _ amagalma).lua


--[[
 * Changelog:
 * v1.2 (2017-11-15)
  + TCP and MCP Buttons now latch
  + Moved Toggle Edit Group 1-8 actions into the package
--]]

-- Special Thanks to: Spacemen Tree, spk77 and cfillion

-------------------------------------------------------------------------------------------------------------

local reaper = reaper
local math = math
local version = "1.2"

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

-------------------------------------------------------------------------------------------------------------

--/////////////////////////////
--//Button Scaling functions //
--/////////////////////////////
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

--- MOD Mouse
function Button:__rmb_down()
return(last_mouse_state == 0 and gfx.mouse_cap & 2 == 2 and self.__mouse_state == 0)
--return(last_mouse_state == 0 and self.mouse_state == 2)
end
function Button:set_help_text()
  local _, wx,wy,_,_ = gfx.dock(-1,0,0,0,0)
  reaper.TrackCtl_SetToolTip(self.help_text, gfx.mouse_x+wx+28, gfx.mouse_y+wy+51, true)
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
    
    function MAKE_X(x1,y1)
     gfx.set(0.3,0.7,0.8,1)
     gfx.line(x1 + self.w/2, y1+8 ,x1 + self.w/2, y1+16,1)
     gfx.line(x1 + 2, y1+12 , x1 + 10 , y1 +12,1)
    end 

-- Draw button label
    if self.label ~= "" then
      if self.center ==1 then 
      gfx.x = self.x1 + 13
      else gfx.x = self.x1 + math.floor(0.5 * self.w - 0.5 * self.label_w) -- center the label
    end
gfx.y = self.y1 -0.5 + 0.5*self.h - 0.5*gfx.texth
if self.__mouse_state == 1 then
gfx.y = gfx.y --+ 1
gfx.a = self.lbl_a*0.5
elseif self.__mouse_state == 0 then
gfx.a = self.lbl_a
end
gfx.set(self.lbl_r,self.lbl_g,self.lbl_b,self.lbl_a)


-------------------------------
if self.label == 0 then MAKE_X(self.x1, self.y1) else gfx.printf(self.label) end
-------------------------------



if self.__mouse_state == 1 then gfx.y = gfx.y - 1 end
end
end
-- Draw element (+ mouse handling)
function Button:draw()
-- lmb released (and was clicked on element)
if last_mouse_state == 0 and self.__mouse_state == 1 then self.__mouse_state = 0 end

------MOD MOUSE RIGHT BUTTON
if last_mouse_state == 0 and self.__mouse_state == 2 then self.__mouse_state = 0 end


-- Mouse is on element -----------------------
if self:__is_mouse_on() then
if self:__lmb_down() then -- Left mouse btn is pressed on button
self.__mouse_state = 1
if self.__state_changing == false then
self.__state_changing = true
else self.__state_changing = true
end
end
self:set_help_text()
if last_mouse_state == 0 and gfx.mouse_cap & 1 == 0 and self.__state_changing == true then
if self.onRClick ~= nil then self:onRClick()
self.__state_changing = false
else self.__state_changing = false
end
end

-------MOD
if self:__is_mouse_on() then
if self:__rmb_down() then -- Right mouse btn is pressed on button
self.__mouse_state = 2
if self.__state_changing == false then
self.__state_changing = true
else self.__state_changing = true
end
end
if last_mouse_state == 0 and gfx.mouse_cap & 2 == 0 and self.__state_changing == true then
if self.onClick ~= nil then self:onClick()
self.__state_changing = false
else self.__state_changing = false
end
end
end
-- Mouse is not on element -----------------------
else
if last_mouse_state == 0 and self.__state_changing == true then
self.__state_changing = false
end
end
if self.__mouse_state == 1 or self.__mouse_state == 2 or self.vis_state == 1 or self.__state_changing then
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
--gfx.set(1,1,1,1)
    if self.border ~= 1 then
    gfx.rect(self.x1-2, self.y1-2, self.w+4, self.h+4,0) -- e este
    gfx.set(1,1,1,1)
    gfx.set(0.1,0.1,0.1,1)
    gfx.rect(self.x1-3, self.y1-3, self.w+6, self.h+6,0)  --este
    --gfx.rect(self.x1-2, self.y1-2, self.w+4, self.h+4,0)
    end
gfx.set(0.1,0.1,0.1,1)
gfx.rect(self.x1-1, self.y1-1, self.w+2, self.h+2,0)
end
         

-------------------------------------------------------------------------------------------------------------
-- Init Variables --
--------------------

local GUI_xstart = 5
local GUI_xend = 256
local GUI_ystart = 5
local GUI_yend = 690
local GUI_centerx = GUI_xend/2 + GUI_xstart
local GUI_centery = GUI_yend/2 + GUI_ystart

local larger = 20

local init_sel_items = {}

local SelAllItemsToggle = false
local SelAllTracksToggle = true

local MATRIX_StoredTracksGroups = { }
  
for row = 1,3 do
  table.insert(MATRIX_StoredTracksGroups, { })
end
    
for row = 1,16 do
  table.insert(MATRIX_StoredTracksGroups [1], { })
  table.insert(MATRIX_StoredTracksGroups [2], { })
  table.insert(MATRIX_StoredTracksGroups [3], { })
end 
    
local MATRIX_GroupMatrixSize = { }  --- Keep number of tracks in each group
    
for row = 1,3 do
  table.insert(MATRIX_GroupMatrixSize, { })
end        

local DOCK_mode = 0 --- DOCKER STARTUP POSITION: UNDOCKED

local MATRIX_TempStoreTracks = {} --- create matrix for storing tracks in each group matrix

local MATRIX_labels = {}  --- GROUPS LABELS MATRIX
  
for row = 1,48 do
  table.insert(MATRIX_labels, { }) -- insert new row
end  
                 
local MATRIX_groupone = {}   --- Matrices where the groups and the corresponding pages
local MATRIX_grouptwo = {}   --- will be alocated
local MATRIX_groupthree = {}
 

local MATRIX_addone = {}      --- Matrices for the buttons of add track to group
local MATRIX_addtwo = {}
local MATRIX_addthree = {}

local Grouped_Items = {}
local Tracks_Visible_TCP = {}
local Tracks_Visible_MCP = {}
local TCP_mode = 0
local MCP_mode = 0
local done_tcp_hide = 0
local done_mcp_hide = 0
local PAGE_mode = 1
local ACTIVEgroup, ACTIVEpage = 0, 0
local ACTIVEgroupLast, ACTIVEpageLast = 0, 0
local change_group
          
-------------------------------------------------------------------------------------------------------------
-- Functions --
---------------
        
--- CONSOLE OUTPUT FOR DEBUG ---
function M(message)
  reaper.ShowConsoleMsg(tostring(message).."\n")
  reaper.ShowConsoleMsg("-----------------------------------".."\n")
  --reaper.ClearConsole()
end  

function Select_all_items(sel)
  local item_cnt = reaper.CountMediaItems( 0 )
  reaper.PreventUIRefresh( 1 )
  for i = 0, item_cnt -1 do
    local item = reaper.GetMediaItem( 0, i )
    reaper.SetMediaItemInfo_Value( item, "B_UISEL", sel )
  end
  reaper.PreventUIRefresh( -1 )
  reaper.UpdateArrange()
end

function Select_all_tracks(sel)
  local track_cnt = reaper.CountTracks( 0 )
  reaper.PreventUIRefresh( 1 )
  for i = 0, track_cnt -1 do
    local track = reaper.GetTrack( 0, i )
    reaper.SetMediaTrackInfo_Value( track, "I_SELECTED", sel )
  end
  reaper.PreventUIRefresh( -1 )
end

--- UI DRAW ---
function UI_TEMPLATE()
  gfx.clear = 3355443    --- Global Window border color set to dark gray
  gfx.set(0.1,0.1,0.1,1)   --- Global Window color set to lighter gray
  gfx.set(0.4,0.4,0.4,0.5)

  local left_x = 7
  local right_x = 168
  gfx.set(0.1,0.1,0.1,1)
  gfx.rect(GUI_xstart+left_x+48,GUI_ystart+left_x+16,GUI_xend -67,GUI_yend-41,0)
  gfx.set(0.1,0.1,0.1,0.7)
  gfx.rect(GUI_xstart+left_x+50,GUI_ystart+left_x+18,GUI_xend -71,GUI_yend-45,1)
      
  gfx.set(0.1,0.1,0.1,0.7)   --- Global Window color set to lighter gray
  gfx.rect(GUI_xstart+11,GUI_ystart+5,29,31,1)
  gfx.set(0.1,0.1,0.1,1)   
  gfx.rect(GUI_xstart+8,GUI_ystart+2,35,37,0)
  
  --- ALL TRACKS UI ---
  gfx.set(0.125,0.125,0.125,1)
  gfx.rect(70,32,80,22,1)
  gfx.set(0,0,0,1)  
  gfx.rect(70,32,80,23,0) 
                       
  --- HIDE BOX UI --    
  gfx.x= 11
  gfx.y= 60
  gfx.set(0.1,0.1,0.1,0.4)
  gfx.rect(4,58,51,75,1)
  gfx.set(0.1,0.1,0.1,1)
  gfx.rect(4,57,51,76,0) 
  gfx.set(0.5,0.5,0.5,1)
  gfx.drawstr("SHOW")
  local xop=76
  for i = 1, 2 do
    gfx.set(0.1,0.1,0.1,0.7)  
    gfx.rect(GUI_xstart+3,GUI_ystart+xop,43,20,1)
    gfx.set(0.1,0.1,0.1,1)
    gfx.rect(GUI_xstart+3,GUI_ystart+xop,43,20,0)
    gfx.set(0.4,0.8,0.9,1)
    xop = xop +26
  end 
  
  --- SELECT BOX UI --
  gfx.x= 6
  gfx.y= 180
  gfx.set(0.1,0.1,0.1,0.4)
  gfx.rect(4,178,51,101,1)
  gfx.set(0.1,0.1,0.1,1)
  gfx.rect(4,177,51,102,0) 
  gfx.set(0.5,0.5,0.5,1)
  gfx.drawstr("SELECT")
  xop=196
  for i = 1, 3 do
    gfx.set(0.1,0.1,0.1,0.7)  
    gfx.rect(GUI_xstart+3,GUI_ystart+xop,43,20,1)
    gfx.set(0.1,0.1,0.1,1)
    gfx.rect(GUI_xstart+3,GUI_ystart+xop,43,20,0)
    gfx.set(0.4,0.8,0.9,1)
    xop = xop +26
  end 
  
  --- GROUP BOX UI --
  gfx.x= 8
  gfx.y= 330 -- 514
  gfx.set(0.1,0.1,0.1,0.4)
  gfx.rect(4,328,51,101,1)
  gfx.set(0.1,0.1,0.1,1)
  gfx.rect(4,327,51,102,0) 
  gfx.set(0.5,0.5,0.5,1)
  gfx.drawstr("GROUP") 
  xop= 346 -- 530
  for i = 1, 3 do
    gfx.set(0.1,0.1,0.1,0.7)  
    gfx.rect(GUI_xstart+3,GUI_ystart+xop,43,20,1)
    gfx.set(0.1,0.1,0.1,1)
    gfx.rect(GUI_xstart+3,GUI_ystart+xop,43,20,0)
    gfx.set(0.4,0.8,0.9,1)
    xop = xop +26
  end              
end 

function Initialize_ALLTRACKS()
  local help = "Toggles grouping of all visible tracks in TCP"
  local labelAll = "ALL TRACKS"
  local alltracks_x = 70
  local alltracks_y = 32
  local alltracks_xlength = 60 + larger
  alltracks_btn = Button(alltracks_x,alltracks_y,alltracks_xlength,22,2,0,0,labelAll, help,0,1)
  alltracks_btn:set_color(0,0,0,0.1)
  alltracks_btn:set_label_color(0.4,0.8,0.9,1)
  alltracks_btn.onClick = function () 
      EXECUTE_AllTracks()
      reaper.SetCursorContext(1)
  end
end

function Initialize_DOCKER()   
  local help = "Script docking selector"
  local Docksel = ""
  local Docksel_x = GUI_xstart+15
  local Docksel_y = GUI_ystart+10
  local Docksel_xlength = -10 + larger
  DockselL_btn = Button(Docksel_x,Docksel_y +10,Docksel_xlength,11,2,0,0,Docksel, help,0,1)
  if DOCK_mode == 257 then 
    DockselL_btn:set_color(0.5,0.1,0.1,1)
  else 
    DockselL_btn:set_color(0.1,0.1,0.1,1)
  end
  DockselL_btn.onClick = function () 
    DOCK_mode = 257
    DockselL_btn:set_color(0.5,0.1,0.1,1)
  end 
        
  DockselR_btn = Button(Docksel_x +11,Docksel_y +10,Docksel_xlength,11,2,0,0,Docksel, help,0,1)
  if DOCK_mode == 1 then 
      DockselR_btn:set_color(0.5,0.1,0.1,1)
  else 
      DockselR_btn:set_color(0.1,0.1,0.1,1)
  end
  DockselR_btn.onClick = function () 
    DOCK_mode = 1
    DockselR_btn:set_color(0.5,0.1,0.1,1)
  end
      
  DockselU_btn = Button(Docksel_x,Docksel_y,Docksel_xlength +11,10,2,0,0,Docksel, help,0,1)
  if DOCK_mode == 0 then 
    DockselU_btn:set_color(0.5,0.1,0.1,1)
  else 
    DockselU_btn:set_color(0.1,0.1,0.1,1)
  end                    
  DockselU_btn.onClick = function () 
    DOCK_mode = 0
    DockselU_btn:set_color(0.5,0.1,0.1,1)
  end                                  
end 

function UI_DOCKER()
  gfx.set(0.2,0.2,0.2,1)
  if DOCK_mode == 257 then 
    DockselR_btn:set_color(0.1,0.1,0.1,1)
    DockselU_btn:set_color(0.1,0.1,0.1,1)             
  elseif DOCK_mode == 1 then
    DockselL_btn:set_color(0.1,0.1,0.1,1)
    DockselU_btn:set_color(0.1,0.1,0.1,1)          
  elseif DOCK_mode == 0 then
    DockselL_btn:set_color(0.1,0.1,0.1,1)
    DockselR_btn:set_color(0.1,0.1,0.1,1)          
  end
end     

function SaveGroupedItems()
  if ACTIVEgroup == 0 then
    local item_cnt = reaper.CountMediaItems( 0 )
    for i = 0, item_cnt -1 do
      local item = reaper.GetMediaItem( 0, i )
      local group_id = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
      if group_id ~= 0 then
        local guid = reaper.BR_GetMediaItemGUID( item )
        Grouped_Items[guid] = group_id
      end
    end
  end
end

function RestoreGroupedItems()
  if ACTIVEgroup == 0 then
    local item_cnt = reaper.CountMediaItems( 0 )
    reaper.PreventUIRefresh( 1 )
    for i = 0, item_cnt -1 do
      local item = reaper.GetMediaItem( 0, i )
      local guid = reaper.BR_GetMediaItemGUID( item )
      if Grouped_Items[guid] then
        reaper.SetMediaItemInfo_Value( item, "I_GROUPID", Grouped_Items[guid])
      end
    end
    reaper.PreventUIRefresh( -1 )
    reaper.UpdateArrange()
    Grouped_Items = {}
  end
end

function TCP_Hide()
  if (TCP_mode == 1 and ACTIVEpage > 0 and ACTIVEgroup > 0) and change_group == 1 then
    local tracks = MATRIX_GroupMatrixSize [ACTIVEpage] [ACTIVEgroup]
    local TracksOfGroup = {}
    for i = 1, tracks do
      local guid = MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup] [i]
      TracksOfGroup[guid] = true
    end
    local all_tracks_cnt = reaper.CountTracks( 0 )
    for i = 0, all_tracks_cnt -1 do
      local track = reaper.GetTrack( 0, i )
      local GUID = reaper.GetTrackGUID( track )
      if done_tcp_hide == 0 then
        Tracks_Visible_TCP[GUID] = reaper.IsTrackVisible( track, false ) and 1 or 0
      end
      if TracksOfGroup[GUID] then
        reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", 1 )
      else
        reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", 0 )
      end
    end
    reaper.TrackList_AdjustWindows(0)
    reaper.UpdateArrange()
    change_group = 0
    done_tcp_hide = 1
  elseif (TCP_mode == 0 and done_tcp_hide == 1)
  or TCP_mode == 1 and done_tcp_hide == 1 and ACTIVEpage == 0 and ACTIVEgroup == 0 then
    for guid, vis in pairs(Tracks_Visible_TCP) do
      local track = reaper.BR_GetMediaTrackByGUID( 0, guid )
      reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", vis )                      
    end
    reaper.TrackList_AdjustWindows(0)
    reaper.UpdateArrange()
    Tracks_Visible_TCP = {}
    done_tcp_hide = 0
    TCP_mode = 0
  end
end

function MCP_Hide()
  if (MCP_mode == 1 and ACTIVEpage > 0 and ACTIVEgroup > 0) and change_group == 1 then
    local tracks = MATRIX_GroupMatrixSize [ACTIVEpage] [ACTIVEgroup]
    local TracksOfGroup = {}
    for i = 1, tracks do
      local guid = MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup] [i]
      TracksOfGroup[guid] = true
    end
    local all_tracks_cnt = reaper.CountTracks( 0 )
    for i = 0, all_tracks_cnt -1 do
      local track = reaper.GetTrack( 0, i )
      local GUID = reaper.GetTrackGUID( track )
      if done_mcp_hide == 0 then
        Tracks_Visible_MCP[GUID] = reaper.IsTrackVisible( track, true ) and 1 or 0
      end
      if TracksOfGroup[GUID] then
        reaper.SetMediaTrackInfo_Value( track, "B_SHOWINMIXER", 1 )
      else
        reaper.SetMediaTrackInfo_Value( track, "B_SHOWINMIXER", 0 )
      end
    end
    reaper.TrackList_AdjustWindows(0)
    change_group = 0
    done_mcp_hide = 1
  elseif (MCP_mode == 0 and done_mcp_hide == 1)
  or MCP_mode == 1 and done_mcp_hide == 1 and ACTIVEpage == 0 and ACTIVEgroup == 0 then
    for guid, vis in pairs(Tracks_Visible_MCP) do
      local track = reaper.BR_GetMediaTrackByGUID( 0, guid )
      reaper.SetMediaTrackInfo_Value( track, "B_SHOWINMIXER", vis )                      
    end
    reaper.TrackList_AdjustWindows(0)
    Tracks_Visible_MCP = {}
    done_mcp_hide = 0
    MCP_mode = 0
  end
end

function Initialize_OPTIONS()
  local x_options =8
  local y_options = 81
  local length = 43
  local y_spacing = 26
  local y_section = 120
 
  --- HIDE ---
  local help = "Toggle Show only the active group in TCP"
  TCP_GUI = Button(x_options,y_options,length,20,2,0,0,"TCP", help,4,1)
  TCP_GUI:set_color(0,0,0,0.1) 
  TCP_GUI:set_label_color(0.4,0.8,0.9,1)
  TCP_GUI.onClick= function ()
    if TCP_mode == 0 then
      TCP_mode = 1 
    else
      TCP_mode = 0
    end
  end
  local help = "Toggle Show only the active group in MCP"
  MCP_GUI = Button(x_options,y_options + y_spacing,length,20,2,0,0,"MCP", help,4,1)
  MCP_GUI:set_color(0,0,0,0.1) 
  MCP_GUI:set_label_color(0.4,0.8,0.9,1)
  MCP_GUI.onClick= function ()
    if MCP_mode == 0 then
      MCP_mode = 1 
    else
      MCP_mode = 0
    end
  end
  local help = "Toggle select tracks of active group"
  TRACK_GUI = Button(x_options,y_options + y_section,length,20,2,0,0,"TRACK", help,4,1)
  TRACK_GUI:set_color(0,0,0,0.1) 
  TRACK_GUI:set_label_color(0.4,0.8,0.9,1)
  TRACK_GUI.onClick= function ()
    if ACTIVEpage > 0 and ACTIVEgroup > 0 then
      reaper.PreventUIRefresh(1)
      local tracks = MATRIX_GroupMatrixSize [ACTIVEpage] [ACTIVEgroup]
      Select_all_tracks(0) -- unselect
      SelAllTracksToggle = not SelAllTracksToggle
      for recall = 1, tracks do
      local guid = MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup] [recall]
      local tr = reaper.BR_GetMediaTrackByGUID(0, guid)
        if tr == nil then                         
          if MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup][recall] ~=nil
          then table.remove(MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup], recall)
          end
          MATRIX_GroupMatrixSize [ACTIVEpage] [ACTIVEgroup] = #MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup]                 
        else
          reaper.SetTrackSelected(tr, SelAllTracksToggle)
        end                            
      end   
      reaper.PreventUIRefresh(-1)
    end
  end           
  
  local help = "Toggle select all items of active group tracks'"
  ITEM_GUI = Button(x_options,y_options + y_section +y_spacing,length,20,2,0,0,"ITEM", help,4,1)
  ITEM_GUI:set_color(0,0,0,0.1) 
  ITEM_GUI:set_label_color(0.4,0.8,0.9,1)
  ITEM_GUI.onClick= function ()
    if ACTIVEpage > 0 and ACTIVEgroup > 0 then
      reaper.PreventUIRefresh(1)
      local tracks = MATRIX_GroupMatrixSize [ACTIVEpage] [ACTIVEgroup]
      Select_all_items(0) -- Unselect all items
      SelAllItemsToggle = not SelAllItemsToggle
      --M(SelAllItemsToggle)
      for recall = 1, tracks do
      guid = MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup] [recall]
      --M(guid) 
      tr = reaper.BR_GetMediaTrackByGUID(0, guid)
        if tr == nil then                         
          if MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup][recall] ~=nil
          then table.remove(MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup], recall)
          end
          MATRIX_GroupMatrixSize [ACTIVEpage] [ACTIVEgroup] = #MATRIX_StoredTracksGroups [ACTIVEpage] [ACTIVEgroup]                 
        else
          local item_cnt = reaper.CountTrackMediaItems(tr)
          for i = 0, item_cnt-1 do
            local item = reaper.GetTrackMediaItem(tr, i)
            reaper.SetMediaItemSelected(item, SelAllItemsToggle)
          end
        end
      end
      reaper.PreventUIRefresh(-1)
      reaper.UpdateArrange() 
    end
  end   
  
  local help = "Unselect all tracks and items"
  NOSEL_GUI = Button(x_options,y_options + y_section + (y_spacing*2),length,20,2,0,0,"NONE", help,4,1)
  NOSEL_GUI:set_color(0,0,0,0.1) 
  NOSEL_GUI:set_label_color(0.4,0.8,0.9,1)
  NOSEL_GUI.onClick= function ()
    Select_all_tracks(0) -- unselect
    Select_all_items(0) -- Unselect all items
    SelAllItemsToggle = false
    SelAllTracksToggle = false
  end  
        
  GROUP_PAGE1_GUI = Button(x_options,y_options + (y_section*4-26)-184,length,20,2,0,0,"1-16", "",4,1)
  GROUP_PAGE1_GUI:set_color(0,0,0,0.1) 
  GROUP_PAGE1_GUI:set_label_color(0.4,0.8,0.9,1)
  GROUP_PAGE1_GUI.onClick= function ()
    ----M("GROUP: 1-16")
    PAGE_mode = 1
    reaper.SetProjExtState( 0, "Edit Groups", "PAGE_mode", 1 )
  end 
  
  GROUP_PAGE2_GUI = Button(x_options,y_options + (y_section*4-26)+ y_spacing-184,length,20,2,0,0,"17-32", "",4,1)
  GROUP_PAGE2_GUI:set_color(0,0,0,0.1) 
  GROUP_PAGE2_GUI:set_label_color(0.4,0.8,0.9,1)
  GROUP_PAGE2_GUI.onClick= function ()
    ----M("GROUP: 17-32")
    PAGE_mode = 2
    reaper.SetProjExtState( 0, "Edit Groups", "PAGE_mode", 2 )
  end  
  
  GROUP_PAGE3_GUI = Button(x_options,y_options + (y_section*4-26)+ (y_spacing*2)-184,length,20,2,0,0,"33-48", "",4,1)
  GROUP_PAGE3_GUI:set_color(0,0,0,0.1) 
  GROUP_PAGE3_GUI:set_label_color(0.4,0.8,0.9,1)
  GROUP_PAGE3_GUI.onClick= function ()
    ----M("GROUP: 32-48")
    PAGE_mode = 3
    reaper.SetProjExtState( 0, "Edit Groups", "PAGE_mode", 3 )            
  end
end         
  
    
function UI_DRAW_OPS()
  --- Draw Show All button ---
  alltracks_btn:draw()
  
  --- Draw DOCKER buttons ---
  DockselL_btn:draw()
  DockselR_btn:draw()
  DockselU_btn:draw()
   
  --- Draw OPTION BOXES buttons ---            
  TCP_GUI:draw()
  MCP_GUI:draw()
  TRACK_GUI:draw()
  ITEM_GUI:draw()
  NOSEL_GUI:draw()
  GROUP_PAGE1_GUI:draw()
  GROUP_PAGE2_GUI:draw()
  GROUP_PAGE3_GUI:draw()

  
  --- Draw OPTION BOXES buttons to reflect SELECTED or not ---
  
  if TCP_mode == 1 then 
    TCP_GUI:set_color(0,0.4,0.6,0.6) TCP_GUI:set_label_color(0.4,0.8,0.9,1) 
  elseif TCP_mode ==0 then TCP_GUI:set_color(0,0,0,0.1)
  end
  
  if MCP_mode == 1 then 
    MCP_GUI:set_color(0,0.4,0.6,0.6) MCP_GUI:set_label_color(0.4,0.8,0.9,1) 
  elseif MCP_mode ==0 then MCP_GUI:set_color(0,0,0,0.1)
  end
  
  if ACTIVEgroup == -1 then
    alltracks_btn:set_color(0,0.4,0.6,0.6) alltracks_btn:set_label_color(1,1,1,1) 
  else alltracks_btn:set_color(0,0,0,0.1) alltracks_btn:set_label_color(0.4,0.8,0.9,1)
  end
              
             
  if PAGE_mode == 1 then 
    GROUP_PAGE1_GUI:set_color(0,0.4,0.6,0.6) GROUP_PAGE1_GUI:set_label_color(0.4,0.8,0.9,1) 
  elseif PAGE_mode ~= 1 then GROUP_PAGE1_GUI:set_color(0,0,0,0.1)
  end
  if PAGE_mode ==2 then
    GROUP_PAGE2_GUI:set_color(0,0.4,0.6,0.6) GROUP_PAGE2_GUI:set_label_color(0.4,0.8,0.9,1) 
  elseif PAGE_mode ~= 2 then GROUP_PAGE2_GUI:set_color(0,0,0,0.1)
  end
  if PAGE_mode ==3 then
    GROUP_PAGE3_GUI:set_color(0,0.4,0.6,0.6) GROUP_PAGE3_GUI:set_label_color(0.4,0.8,0.9,1) 
  elseif PAGE_mode ~= 3 then GROUP_PAGE3_GUI:set_color(0,0,0,0.1)
  end      
end
          
function Initialize_GROUP_PAGE_One(buttonid,ident)          
  local xbutton = 79
  local ybutton = GUI_centery - (50/2)*(13-ident*1.5)
  local length = 157
  table.insert (MATRIX_groupone,{ })
  table.insert (MATRIX_addone,{ })          
  MATRIX_groupone[ident] = Button(xbutton -8,ybutton-1,length,24,2,0,0,
                          MATRIX_labels[ident], "",1,1)
  MATRIX_groupone[ident]:set_color(0,0,0,1)
  MATRIX_groupone[ident]:set_label_color(0.6,0.6,0.6,1)
  local colength = length - 103

  MATRIX_addone[ident] = Button(xbutton+length-7,ybutton,13,24,2,0,0,0, "",0,1)
  MATRIX_addone[ident]:set_color(0,0.3,0.5,0.1)
  groupClick_One (MATRIX_groupone[ident],ident)
  addClick_One (MATRIX_addone[ident],ident)
end

function addClick_One(btn,group)
  btn.onClick = function ()
    local track_cnt = MATRIX_GroupMatrixSize[1][group]
    if track_cnt == 0 or track_cnt == nil then
      EXECUTE_Store_Group(1,group)
    else
      local ok = reaper.MB("Replace saved group with the current track selection", "Replace Group", 1)
      if ok == 1 then
        if group == ACTIVEgroup and ACTIVEpage == 1 then
          EXECUTE_Ungroup(ACTIVEpage, ACTIVEgroup)
          reaper.UpdateArrange()
        end
      end
        MATRIX_StoredTracksGroups [1] [group] = {}
        MATRIX_GroupMatrixSize [1] [group] = nil
        EXECUTE_Store_Group(1,group)
        ACTIVEgroup = 0
    end
  end
  btn.onRClick = function ()
    local track_cnt = MATRIX_GroupMatrixSize[1][group]
    if track_cnt and track_cnt > 0 then
      local ok = reaper.MB ("Are you sure you want to remove this group definition?", "Remove Group", 4)
      if ok == 6 then
        if group == ACTIVEgroup and ACTIVEpage == 1 then
          EXECUTE_Ungroup(ACTIVEpage, ACTIVEgroup)
          reaper.UpdateArrange()
          ACTIVEpage = 0
          ACTIVEgroup = 0
        end 
        MATRIX_StoredTracksGroups [1] [group] = {}
        MATRIX_GroupMatrixSize [1] [group] = nil
        MATRIX_groupone[group]:set_color(0,0,0,1)
        MATRIX_groupone[group]:set_label_color(0.6,0.6,0.6,1)
        MATRIX_TempStoreTracks = {}
      end
    end
  end 
end

function EnableGroup(page, group)
  if ACTIVEpage == -1 then EXECUTE_AllTracks() end
   if group == ACTIVEgroup and ACTIVEpage == page then
     Select_all_tracks(0)  -- Unselect all tracks
     EXECUTE_Ungroup(ACTIVEpage,ACTIVEgroup)
     reaper.UpdateArrange()
     ACTIVEgroup = 0
     ACTIVEpage = 0
     RestoreGroupedItems()
     ACTIVEgroupLast, ACTIVEpageLast = ACTIVEgroup, ACTIVEpage
     ACTIVEgroup = 0
     ACTIVEpage = 0
     Initialize_Groups()
   else
     SaveGroupedItems()
     EXECUTE_Recall(page,group)
   end
end

function groupClick_One(btn,group)
  btn.onClick = function ()
    EnableGroup(1, group)
  end 
  btn.onRClick = function ()                           
    EXECUTE_Rename_Group(btn,group)
  end  
end 

function UI_GROUP_PAGE_One()
  local Start_group_draw = 1
  local increase = 1
  for draw=1,16,1 do
  MATRIX_groupone[Start_group_draw].y1 =  GUI_centery - (50/2)*(13-increase*1.5)
  MATRIX_groupone[Start_group_draw]:draw()

  -- Colocar aqui condição para mostrar add to group
  -- ex: if FLAG "group has tracks assigned show add button" then
  if gfx.mouse_x>= MATRIX_groupone[Start_group_draw].x1 and 
  gfx.mouse_x<= MATRIX_groupone[Start_group_draw].x2+15 and 
  gfx.mouse_y>=MATRIX_groupone[Start_group_draw].y1 and 
  gfx.mouse_y<=MATRIX_groupone[Start_group_draw].y2 then
      MATRIX_addone[Start_group_draw]:draw()
  end    
  Start_group_draw = Start_group_draw + 1
  increase =  increase + 1
  end 
end  

function Initialize_GROUP_PAGE_Two(buttonid,ident)          
  local xbutton = 79
  local ybutton = GUI_centery - (50/2)*(13-ident*1.5)
  local length = 157
  table.insert (MATRIX_grouptwo,{ })
  table.insert (MATRIX_addtwo,{ }) 
  MATRIX_grouptwo[ident] = Button(xbutton -8,ybutton-1,length,24,2,0,0,MATRIX_labels[ident+16], "",1,1)
  MATRIX_grouptwo[ident]:set_color(0,0,0,1)
  MATRIX_grouptwo[ident]:set_label_color(0.6,0.6,0.6,1)
  local colength = length - 103
  MATRIX_addtwo[ident] = Button(xbutton+length-7,ybutton,13,24,2,0,0,0, "",0,1)
  MATRIX_addtwo[ident]:set_color(0,0.3,0.5,0.1)
  groupClick_Two (MATRIX_grouptwo[ident],ident)
  addClick_Two (MATRIX_addtwo[ident],ident)
end 

function addClick_Two(btn,group)
  btn.onClick = function ()
      local track_cnt = MATRIX_GroupMatrixSize[2][group]
      if track_cnt == 0 or track_cnt == nil then
        EXECUTE_Store_Group(2,group)
      else
        local ok = reaper.MB("Replace saved group with the current track selection", "Replace Group", 1)
        if ok == 1 then
          if group == ACTIVEgroup and ACTIVEpage == 2 then
            EXECUTE_Ungroup(ACTIVEpage, ACTIVEgroup)
            reaper.UpdateArrange()
          end
        end
          MATRIX_StoredTracksGroups [2] [group] = {}
          MATRIX_GroupMatrixSize [2] [group] = nil
          EXECUTE_Store_Group(2,group)
          ACTIVEgroup = 0
      end
  end
  btn.onRClick = function ()
    local track_cnt = MATRIX_GroupMatrixSize[2][group]
    if track_cnt and track_cnt > 0 then
      local ok = reaper.MB ("Are you sure you want to remove this group definition?", "Remove Group", 4)
      if ok == 6 then
        --table.remove(MATRIX_StoredTracksGroups [2] [group] )
        ----M("RECALL Group" .. tostring(" "..group+16))
        if group == ACTIVEgroup and ACTIVEpage == 2 then
          EXECUTE_Ungroup(ACTIVEpage, ACTIVEgroup)
          reaper.UpdateArrange()
          ACTIVEpage = 0
          ACTIVEgroup = 0
        end 
        MATRIX_StoredTracksGroups [2] [group] = {}
        MATRIX_GroupMatrixSize [2] [group] = nil
        MATRIX_groupone[group]:set_color(0,0,0,1)
        MATRIX_groupone[group]:set_label_color(0.6,0.6,0.6,1)
        MATRIX_TempStoreTracks = {}
        Initialize_Groups()
      end
    end
  end 
end

function groupClick_Two(btn,group)   
  btn.onClick = function ()
    EnableGroup(2, group)
  end 
  btn.onRClick = function ()           
    --M("RENAME GROUP")
    EXECUTE_Rename_Group(btn,group)     
  end  
end 


function UI_GROUP_PAGE_Two()
  local Start_group_draw = 1
  local increase = 1
  for draw=1,16,1 do
  MATRIX_grouptwo[Start_group_draw].y1 =  GUI_centery - (50/2)*(13-increase*1.5)
  MATRIX_grouptwo[Start_group_draw]:draw()
  
  if gfx.mouse_x>= MATRIX_grouptwo[Start_group_draw].x1 and 
  gfx.mouse_x<= MATRIX_grouptwo[Start_group_draw].x2+15 and 
  gfx.mouse_y>=MATRIX_grouptwo[Start_group_draw].y1 and 
  gfx.mouse_y<=MATRIX_grouptwo[Start_group_draw].y2 then
      MATRIX_addtwo[Start_group_draw]:draw()
  end
  
  Start_group_draw = Start_group_draw + 1
  increase = increase + 1
  end 
end 

function Initialize_GROUP_PAGE_Three(buttonid,ident)          
  local xbutton = 79
  local ybutton = GUI_centery - (50/2)*(13-ident*1.5)
  local length = 157
  table.insert (MATRIX_groupthree,{ })
  table.insert (MATRIX_addthree,{ })           
  MATRIX_groupthree[ident] = Button(xbutton -8,ybutton-1,length,24,2,0,0,MATRIX_labels[ident+32], "",1,1)
  MATRIX_groupthree[ident]:set_color(0,0,0,1)
  MATRIX_groupthree[ident]:set_label_color(0.6,0.6,0.6,1)
  local colength = length - 103
  MATRIX_addthree[ident] = Button(xbutton+length-7,ybutton,13,24,2,0,0,0, "",0,1)
  MATRIX_addthree[ident]:set_color(0,0.3,0.5,0.1)
  groupClick_Three (MATRIX_groupthree[ident],ident)
  addClick_Three (MATRIX_addthree[ident],ident)
end 

function addClick_Three(btn,group)
  btn.onClick = function ()
    local track_cnt = MATRIX_GroupMatrixSize[3][group]
    if track_cnt == 0 or track_cnt == nil then
      EXECUTE_Store_Group(3,group)
    else
      local ok = reaper.MB("Replace saved group with the current track selection", "Replace Group", 1)
      if ok == 1 then
        if group == ACTIVEgroup and ACTIVEpage == 3 then
          EXECUTE_Ungroup(ACTIVEpage, ACTIVEgroup)
          reaper.UpdateArrange()
        end
      end
        MATRIX_StoredTracksGroups [3] [group] = {}
        MATRIX_GroupMatrixSize [3] [group] = nil
        EXECUTE_Store_Group(3,group)
        ACTIVEgroup = 0
    end
  end
  btn.onRClick = function ()
    local track_cnt = MATRIX_GroupMatrixSize[3][group]
    if track_cnt and track_cnt > 0 then      
      local ok = reaper.MB ("Are you sure you want to remove this group definition?", "Remove Group", 4)
      if ok == 6 then
        --table.remove(MATRIX_StoredTracksGroups [3] [group] )
        ----M("RECALL Group" .. tostring(" "..group+32))
        if group == ACTIVEgroup and ACTIVEpage == 3 then
          EXECUTE_Ungroup(ACTIVEpage, ACTIVEgroup)
          reaper.UpdateArrange()
          ACTIVEpage = 0
          ACTIVEgroup = 0
        end 
        MATRIX_StoredTracksGroups [3] [group] = {}
        MATRIX_GroupMatrixSize [3] [group] = nil
        MATRIX_groupone[group]:set_color(0,0,0,1)
        MATRIX_groupone[group]:set_label_color(0.6,0.6,0.6,1)
        MATRIX_TempStoreTracks = {}
        Initialize_Groups()
      end
    end
  end 
end
                  
function groupClick_Three(btn,group)   
  btn.onClick = function ()
    EnableGroup(3, group)
  end 
  btn.onRClick = function ()  
    --M("RENAME GROUP")
    EXECUTE_Rename_Group(btn,group)
  end  
end 


function UI_GROUP_PAGE_Three()
  local Start_group_draw = 1
  local increase = 1
  for draw=1,16,1 do
  MATRIX_groupthree[Start_group_draw].y1 =  GUI_centery - (50/2)*(13-increase*1.5)
  MATRIX_groupthree[Start_group_draw]:draw()
  
  if gfx.mouse_x>= MATRIX_groupthree[Start_group_draw].x1 and 
  gfx.mouse_x<= MATRIX_groupthree[Start_group_draw].x2+15 and 
  gfx.mouse_y>=MATRIX_groupthree[Start_group_draw].y1 and 
  gfx.mouse_y<=MATRIX_groupthree[Start_group_draw].y2 then
      MATRIX_addthree[Start_group_draw]:draw()
  end
  
  Start_group_draw = Start_group_draw + 1
  increase = increase + 1
  end 
end         

  
  
function EXECUTE_Store_Group(page,group)
  local ID_group = group
  local ID_page = page            
  local Group_Size = MATRIX_GroupMatrixSize [ID_page] [ID_group]                                   
  MATRIX_TempStoreTracks = {} -- create temp matrix for storing tracks in each group matrix                          
  -- CHECK IF GROUP ALREADY HAS TRACKS ASSIGNED
  if Group_Size == nil or Group_Size == 0 then MATRIX_EntryPoint = 0  -- else start at 0             
  else MATRIX_EntryPoint = MATRIX_GroupMatrixSize [ID_page] [ID_group] -- 
  end
  -- IF GROUP ALREADY HAS TRACKS
  if MATRIX_EntryPoint > 0 then         
    local TRACKS_Selected = reaper.CountSelectedTracks(0)
    for i = 0, TRACKS_Selected-1 do
        TRACK_CurrentSelected = reaper.GetSelectedTrack(0, i)                                                    
        GUID_Store = reaper.BR_GetMediaTrackGUID(TRACK_CurrentSelected)
        MATRIX_TempStoreTracks [1 + i] = GUID_Store   
    end
    for t =1, #MATRIX_TempStoreTracks do   -- TRACKS IN TEMP MATRIX
      for i = 1, MATRIX_EntryPoint do
        if MATRIX_TempStoreTracks [t] ==
          MATRIX_StoredTracksGroups [ID_page] [ID_group] [i] then                                                          
          table.remove(MATRIX_TempStoreTracks, t)
        end                                                      
      end
    end
    count = MATRIX_EntryPoint + 1     
    for e = 1, #MATRIX_TempStoreTracks,1 do
      MATRIX_StoredTracksGroups [ID_page] [ID_group] [count] =
      MATRIX_TempStoreTracks [e]
      count = count +1
    end                                  
  else
    --- IF GROUP DOESNT HAVE TRACKS YET
    local TRACKS_Selected = reaper.CountSelectedTracks(0)
    for i = 0, TRACKS_Selected-1 do
      TRACK_CurrentSelected = reaper.GetSelectedTrack(0, i)                                                    
      GUID_Store = reaper.BR_GetMediaTrackGUID(TRACK_CurrentSelected)
      MATRIX_TempStoreTracks [1 + i] = GUID_Store   
    end     
    for tracks =1, #MATRIX_TempStoreTracks do
      MATRIX_StoredTracksGroups [ID_page] [ID_group] [tracks] =    
      MATRIX_TempStoreTracks [tracks]
    end
    reaper.SetProjExtState( 0, "Edit Groups", "Group "..tostring(math.floor((page-1)*16+group)), table.concat(MATRIX_TempStoreTracks))
  end
  MATRIX_GroupMatrixSize [ID_page] [ID_group] = #MATRIX_StoredTracksGroups [ID_page] [ID_group]             

  --- Check PAGE and color correct GROUP to reflect GROUP has tracks
  if MATRIX_GroupMatrixSize [ID_page] [ID_group] >0 then
    if page==1 then 
      MATRIX_groupone[group]:set_color(0.6,0.6,0.6,0.3)
      MATRIX_groupone[group]:set_label_color(0.9,0.9,0.9,1)
    elseif page==2 then
      MATRIX_grouptwo[group]:set_color(0.6,0.6,0.6,0.3)
      MATRIX_grouptwo[group]:set_label_color(0.9,0.9,0.9,1)
    elseif page==3 then
      MATRIX_groupthree[group]:set_color(0.6,0.6,0.6,0.3)
      MATRIX_groupthree[group]:set_label_color(0.9,0.9,0.9,1)
    end
  end      
end

function EXECUTE_Ungroup(page, group)
  if group ~= 0 then
    SelAllItemsToggle = false
    local tracks = MATRIX_GroupMatrixSize [page] [group]
    for recall = 1, tracks do
      local guid = MATRIX_StoredTracksGroups [page] [group] [recall]
      --M(guid) 
      local tr = reaper.BR_GetMediaTrackByGUID(0, guid)
      if tr == nil then                         
        if MATRIX_StoredTracksGroups [page] [group][recall] ~= nil
        then table.remove(MATRIX_StoredTracksGroups [page] [group], recall)
        end
        MATRIX_GroupMatrixSize [page] [group] = #MATRIX_StoredTracksGroups [page] [group]                 
      else
        local item_cnt = reaper.CountTrackMediaItems(tr)
        for i = 0, item_cnt-1 do
          local item = reaper.GetTrackMediaItem(tr, i)
          reaper.SetMediaItemInfo_Value(item, "I_GROUPID", 0)
        end
      end                            
    end   
  end
end

local function MaxProjectGroupID()
  local all_item_count = reaper.CountMediaItems(0)
  local MaxGroupID = 0
  for i = 0, all_item_count - 1 do
    local item = reaper.GetMediaItem(0, i)
    local item_group_id = math.floor(reaper.GetMediaItemInfo_Value(item, "I_GROUPID"))
    if item_group_id > MaxGroupID then
      MaxGroupID = item_group_id
    end
  end
  return MaxGroupID
end

function EXECUTE_Recall(ID_page,ID_group)                  
  local tracks = MATRIX_GroupMatrixSize [ID_page] [ID_group]
  if tracks == 0 or tracks == nil then
    --M("No groups stored")              
  else
    Select_all_tracks(0)  -- Unselect all tracks
    EXECUTE_Ungroup(ACTIVEpage,ACTIVEgroup)
    reaper.PreventUIRefresh(1)
    for recall =1, tracks do
        guid = MATRIX_StoredTracksGroups [ID_page] [ID_group] [recall]
        --M(guid) 
        tr = reaper.BR_GetMediaTrackByGUID(0, guid)
        if tr == nil then                         
          if MATRIX_StoredTracksGroups [ID_page] [ID_group][recall] ~=nil then
            table.remove(MATRIX_StoredTracksGroups [ID_page] [ID_group], recall)
          end
          MATRIX_GroupMatrixSize [ID_page] [ID_group] = #MATRIX_StoredTracksGroups [ID_page] [ID_group]                 
        else
          reaper.SetMediaTrackInfo_Value(tr,'I_SELECTED', 1)
        end
    end
    local MaxGroupID = MaxProjectGroupID()
    local selected_tracks_count = reaper.CountSelectedTracks(0)
    local first_track = reaper.GetSelectedTrack(0, 0)
    local count_items_on_track = reaper.CountTrackMediaItems(first_track)
    for i = 0, count_items_on_track - 1  do
      MaxGroupID = MaxGroupID +1
      local item_on_first_track = reaper.GetTrackMediaItem(first_track, i)
      local firstposition = reaper.GetMediaItemInfo_Value(item_on_first_track, "D_POSITION")
      local firstlength = reaper.GetMediaItemInfo_Value(item_on_first_track, "D_LENGTH")
      for j = 1, selected_tracks_count - 1 do
        local track = reaper.GetSelectedTrack(0, j)
        local count_items_on_track2 = reaper.CountTrackMediaItems(track)
        for k = 0, count_items_on_track2 - 1  do
          local item_on_track = reaper.GetTrackMediaItem(track, k)
          local position = reaper.GetMediaItemInfo_Value(item_on_track, "D_POSITION")
          local length = reaper.GetMediaItemInfo_Value(item_on_track, "D_LENGTH")
          if position == firstposition and length == firstlength then
            reaper.SetMediaItemInfo_Value(item_on_first_track, "I_GROUPID", MaxGroupID)
            reaper.SetMediaItemInfo_Value(item_on_track, "I_GROUPID", MaxGroupID)
            break
          end
        end
      end     
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    ACTIVEgroupLast, ACTIVEpageLast = ACTIVEgroup, ACTIVEpage
    ACTIVEpage = ID_page
    ACTIVEgroup = ID_group
    SelAllTracksToggle = true
  end
end


function EXECUTE_AllTracks()  
  if ACTIVEgroup >= 0 then
    SaveGroupedItems()
    Select_all_tracks(0)  -- Unselect all tracks
    EXECUTE_Ungroup(ACTIVEpage,ACTIVEgroup)
    reaper.PreventUIRefresh(1)
    local visible = {}
    local track_cnt = reaper.CountTracks(0)
    for i = 0, track_cnt-1 do
      local track = reaper.GetTrack(0, i)
      local show = reaper.GetMediaTrackInfo_Value(track, "B_SHOWINTCP")
      if show then
        visible[#visible+1] = track
      end
    end
    local MaxGroupID = MaxProjectGroupID()
    local first_track = visible[1]
    local count_items_on_track = reaper.CountTrackMediaItems(first_track)
    for i = 0, count_items_on_track - 1  do
      MaxGroupID = MaxGroupID +1
      local item_on_first_track = reaper.GetTrackMediaItem(first_track, i)
      local firstposition = reaper.GetMediaItemInfo_Value(item_on_first_track, "D_POSITION")
      local firstlength = reaper.GetMediaItemInfo_Value(item_on_first_track, "D_LENGTH")
      for j = 2, #visible do
        local track = visible[j]
        local count_items_on_track2 = reaper.CountTrackMediaItems(track)
        for k = 0, count_items_on_track2 - 1  do
          local item_on_track = reaper.GetTrackMediaItem(track, k)
          local position = reaper.GetMediaItemInfo_Value(item_on_track, "D_POSITION")
          local length = reaper.GetMediaItemInfo_Value(item_on_track, "D_LENGTH")
          if position == firstposition and length == firstlength then
            reaper.SetMediaItemInfo_Value(item_on_first_track, "I_GROUPID", MaxGroupID)
            reaper.SetMediaItemInfo_Value(item_on_track, "I_GROUPID", MaxGroupID)
            break
          end
        end
      end     
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    ACTIVEpage = -1
    ACTIVEgroup = -1
    Select_all_tracks(1)  -- Select all tracks
    Initialize_Groups()
  else
    reaper.PreventUIRefresh(1)
    local item_cnt = reaper.CountMediaItems( 0 )
    -- Remove all items from any group
    for i = 0, item_cnt - 1 do
      local item = reaper.GetMediaItem( 0, i )
      reaper.SetMediaItemInfo_Value( item, "I_GROUPID", 0 )
    end
    Select_all_tracks(0)  -- Unselect all tracks
    reaper.PreventUIRefresh(-1)
    ACTIVEpage = 0
    ACTIVEgroup = 0
    RestoreGroupedItems()
  end
end


function Initialize_LABELS()
  local _, labels = reaper.GetProjExtState( 0, "Edit Groups", "Labels" )
  local i = 1
  if labels ~= "" then 
    for label in string.gmatch(labels, "[^?]+") do
      MATRIX_labels[i] = label
      i = i + 1
    end                   
  else  
    for mk=1,48 do
        MATRIX_labels[mk] = "Group "..tostring(mk)
    end
  end
end

function EXECUTE_Update_Labels()
  for mk=1,16 do
    MATRIX_groupone[mk].label = MATRIX_labels[mk]
    MATRIX_grouptwo [mk].label = MATRIX_labels[16+mk]
    MATRIX_groupthree [mk].label = MATRIX_labels[32+mk]
  end
end        

function EXECUTE_Rename_Group(btn,group)
  if MATRIX_GroupMatrixSize [PAGE_mode] [group] then
    setname = tostring(btn.label)
     rename_boxtitle = "Rename Group"
    if PAGE_mode == 2 then group_number = tostring(group + 16)
    elseif PAGE_mode == 3 then group_number = tostring(group + 32) 
    elseif PAGE_mode == 1 then group_number = tostring(group)
    end
        
    rename_boxtext = "Enter Group ".. group_number .."  name:, extrawidth=56"
    retval, newname = reaper.GetUserInputs(rename_boxtitle, 1, rename_boxtext, setname)

    if retval==true and newname~="" then 
      newname_format = string.sub (newname,1,24)
      btn.label = newname_format         
    end
    EXECUTE_Write_Names()
  end
end

function EXECUTE_Write_Names()
  for id = 1,16 do
    MATRIX_labels[id] = MATRIX_groupone[id].label
  end
  for id = 1,16 do
    MATRIX_labels[id+16] = MATRIX_grouptwo[id].label
  end
  for id = 1,16 do
    MATRIX_labels[id+32] = MATRIX_groupthree[id].label
  end
  reaper.SetProjExtState( 0, "Edit Groups", "Labels", table.concat(MATRIX_labels, "?"))
end 


function Initialize_Groups()
  local ntrack = 0
  local page = 1
  local ngroup
  for i = 1, 48 do
    local _, Guids = reaper.GetProjExtState( 0, "Edit Groups", "Group "..tostring(i) )
    if i <= 16 then
      ngroup = i
    elseif i >= 17 and i <= 32 then
      page = 2
      ngroup = i - 16
    elseif i >= 33 and i <= 48 then
      page = 3
      ngroup = i - 32
    end
    if Guids and Guids ~= "" then
      for guid in string.gmatch(Guids, "{.-}") do
        ntrack = ntrack + 1
        MATRIX_GroupMatrixSize [page] [ngroup] = ntrack
        MATRIX_StoredTracksGroups [page] [ngroup] [ntrack] = guid
      end
    end
    ntrack = 0
  end

  for i= 1,16 do 
    if MATRIX_GroupMatrixSize[1][i] ~= nil then
      if i == ACTIVEgroup and ACTIVEpage == 1 then
        MATRIX_groupone[i]:set_color(0.17,0.41,0.53,0.7)
        MATRIX_groupone[i]:set_label_color(1,1,1,1)
      else
        MATRIX_groupone[i]:set_color(0.6,0.6,0.6,0.3)
        MATRIX_groupone[i]:set_label_color(0.9,0.9,0.9,1)
      end
    else
      MATRIX_groupone[i]:set_color(0,0,0,1)
      MATRIX_groupone[i]:set_label_color(0.6,0.6,0.6,1)
    end
  end
  for i= 1,16 do 
    if MATRIX_GroupMatrixSize[2][i] ~= nil then
      if i == ACTIVEgroup and ACTIVEpage == 2 then
        MATRIX_grouptwo[i]:set_color(0.17,0.41,0.53,0.7)
        MATRIX_grouptwo[i]:set_label_color(1,1,1,1)
      else
        MATRIX_grouptwo[i]:set_color(0.6,0.6,0.6,0.3) 
        MATRIX_grouptwo[i]:set_label_color(0.9,0.9,0.9,1)
      end
    else
      MATRIX_grouptwo[i]:set_color(0,0,0,1)
      MATRIX_grouptwo[i]:set_label_color(0.6,0.6,0.6,1)
    end
  end
  for i= 1,16 do
    if MATRIX_GroupMatrixSize[3][i] ~= nil then
      if i == ACTIVEgroup and ACTIVEpage == 3 then
        MATRIX_groupthree[i]:set_color(0.17,0.41,0.53,0.7)
        MATRIX_groupthree[i]:set_label_color(1,1,1,1)
      else 
        MATRIX_groupthree[i]:set_color(0.6,0.6,0.6,0.3) 
        MATRIX_groupthree[i]:set_label_color(0.9,0.9,0.9,1)
      end
    else
      MATRIX_groupthree[i]:set_color(0,0,0,1)
      MATRIX_groupthree[i]:set_label_color(0.6,0.6,0.6,1)
    end
  end                      
end
          
                  
-------------------------------------------------------------------------------------------------------------
--------- Initialization ---------------------
------------------------------------------

function Initialization()
  local xpos, ypos = 10, 10
  if reaper.HasExtState( "Edit Groups", "Position" ) then
    xpos, ypos = string.match(reaper.GetExtState("Edit Groups", "Position"), "(%d+) (%d+)")
  end
  gfx.init("Edit Groups v"..version, GUI_xend,GUI_yend,dock, tonumber(xpos), tonumber(ypos))
  gfx.setfont(1,"Arial", 15)
  
  local _, state = reaper.GetProjExtState( 0, "Edit Groups", "PAGE_mode" )
  if state and state ~= "" then
    PAGE_mode = tonumber(state)
  else
    PAGE_mode = 1
  end
  Initialize_DOCKER()
  Initialize_OPTIONS()
  Initialize_ALLTRACKS()   
  Initialize_LABELS()
  for mk=1,16 do
    Initialize_GROUP_PAGE_One(MATRIX_labels[mk],mk)
    Initialize_GROUP_PAGE_Two(MATRIX_labels[16+mk],mk)
    Initialize_GROUP_PAGE_Three(MATRIX_labels[32+mk],mk)
  end
  Initialize_Groups()
end

-------------------------------------------------------------------------------------------------------------
--------- Main Loop Function -------------
------------------------------------------

function MAIN()
  gfx.dock(DOCK_mode)
  UI_TEMPLATE()
  UI_DRAW_OPS()
  UI_DOCKER()
  
  
  if PAGE_mode == 1 then UI_GROUP_PAGE_One()
  elseif PAGE_mode == 2 then UI_GROUP_PAGE_Two()
  elseif PAGE_mode == 3 then UI_GROUP_PAGE_Three()
  end
 
  if ACTIVEgroup ~= 0 and ACTIVEpage ~= 0 then
    Initialize_Groups()
  end
  
  if gfx.mouse_cap & 1 == 0 and gfx.mouse_cap & 2 == 0 then
  last_mouse_state = 0
  else last_mouse_state = 1 
  end
  
  if (ACTIVEgroupLast ~= ACTIVEgroup and ACTIVEgroup > 0 and ACTIVEpage > 0) 
  or (ACTIVEpageLast ~= ACTIVEpage and ACTIVEgroup > 0 and ACTIVEpage > 0)
  then
    change_group = 1
  else
    change_group = 0
  end
  TCP_Hide()
  MCP_Hide()
  
  gfx.update()
   
  if reaper.HasExtState( "Edit Groups", "Active group" ) then
    local act_group = tonumber(reaper.GetExtState("Edit Groups", "Active group"))
    EnableGroup(1, act_group)
    reaper.DeleteExtState( "Edit Groups", "Active group", false )
  end
  
  if gfx.getchar() >= 0 then reaper.defer(MAIN)
  else
    reaper.PreventUIRefresh(1)
    if ACTIVEgroup > 0 and ACTIVEpage > 0 then
      EXECUTE_Ungroup(ACTIVEpage, ACTIVEgroup)
    end
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    local _, x, y, _, _ = gfx.dock(-1, 0, 0, 0, 0)
    local position = tostring(math.floor(x) .. " " .. math.floor(y))
    reaper.SetExtState( "Edit Groups", "Position", position, true )
    gfx.quit()
  end    
end

-------------------------------------------------------------------------------------------------------------
-----------------// RUN SCRIPT //------------------
---------------------------------------------------  
  
Initialization()    
MAIN()

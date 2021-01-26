-- @description MFXlist
-- @author M Fabian
-- @version 0.9.3beta
-- @changelog
--   Prevent nil error if click and drag while no fx
--   Fix the all-tracks-hidden bug (issue #16)
--   Add menu to switch to next docker
-- @provides [windows] .
-- @screenshot MFXlist.gif https://github.com/martinfabian/MFXlist/raw/main/MFXlist.gif
-- @about
--   # MFXlist
--   A Lua ReaScript that implements an FX strip meant to be docked to the left
--   of the TCP in the arrange view. The original idea comes from Doppelganger's 
--   fxlist (https://forum.cockos.com/showthread.php?t=210987), but this is a 
--   native ReaScript re-implementation of the FX strip part of fxlist. MFXlist 
--   packages existing functionality into a better (in my opinion) user interface 
--   compared to the existing native implementation; the used screen estate is
--   simply smaller. 
--
--   MFXlist is mainly developed and tested on Windows and Reaper 6.20, and it 
--   uses the js_ReaScriptAPI  extension (https://forum.cockos.com/showthread.php?t=212174).
--
--   For detailed info see the MFXlist Github repo https://github.com/martinfabian/MFXlist. 
--   For bugs and questions, see the Reaper forum thread https://forum.cockos.com/showthread.php?p=2395782

local string, table, math = string, table, math
local rpr, gfx = reaper, gfx
-------------------------------------------
-- Variables with underscore are global
-- All caps denotes constants, do not assign to these in the code!
-- Non-constants are used to communicate between different parts of the code
local MFXlist = 
{ 
  -- user settable stuff
  COLOR_EMPTYSLOT = {40/255, 40/255, 40/255},
  COLOR_FXHOVERED = {1, 1, 0}, 
  --[[ not used for now
  COLOR_BLACK   = {012/255, 012/255, 012/255},
  COLOR_VST     = {},
  COLOR_JSFX    = {},
  COLOR_HIGHLIGHT = {},
  COLOR_FAINT = {60/255, 60/255, 60/255},
  --]]
  FX_DISABLEDA = 0.3, -- fade of name for disabled FX
  FX_OFFLINEDA = 0.1, -- even fainter for offlined FX
  
  -- Delay for return of focus during mouse wheel
  FOCUS_DELAY = 10, 
  
  FONT_NAME1 = "Arial",
  FONT_NAME2 = "Courier New",
  FONT_SIZE1 = 14,
  FONT_SIZE2 = 16,
  FONT_FXNAME = 1,
  FONT_FXBOLD = 2,
  FONT_HEADER = 16,
  FONT_BOLDFLAG = 0x42000000,   -- bold
  FONT_ITFLAG = 0x49000000,     -- italics
  FONT_OUTFLAG = 0x4F000000,    -- outline
  FONT_BLURFLAG = 0x52000000,   -- blurred
  FONT_SHARPFLAG = 0x53000000,  -- sharpen
  FONT_UNDERFLAG = 0x55000000,  -- underline
  FONT_INVFLAG = 0x56000000,    -- invert  
  
  -- Script specific constants, from here below change only if you really know what you are doing
  SCRIPT_VERSION = "v0.9.3",
  SCRIPT_NAME = "MFX-list",
  SCRIPT_AUTHORS = {"M Fabian"},
  SCRIPT_YEAR = "2020-2021",
  
  -- Mouse button and modifier key constants
  MB_LEFT = 1,
  MB_RIGHT = 2,
  
  MOD_CTRL = 4, 
  MOD_SHIFT = 8,
  MOD_ALT = 16, 
  MOD_WIN = 32, 
  MOD_KEYS = 4+8+16+32, 
  
  -- determines how far nmouse can be moved between down and up to still be considered a left click
  -- this then also decides how much the mosue has to move with left MB down to be considered as dragging
  CLICK_RESOX = 30, -- maybe should not really care about horizontal moves?
  CLICK_RESOY = 10, 
  
  -- Right click menu 
  MENU_STR = "Next dock|Info|Quit",
  MENU_NEXTDOCK = 1,
  MENU_SHOWINFO = 2,
  MENU_QUIT = 3,
  
  -- Flag constants for TrackFX_Show(track, index, showFlag)
  FXCHAIN_HIDE = 0, 
  FXCHAIN_SHOW = 1,
  FXFLOAT_HIDE = 2,
  FXFLOAT_SHOW = 3,
  
  -- flag constants for GetTrackState(track) return
  TRACK_FXENABLED = 4, 
  TRACK_MUTED = 8, -- seemed liek a good idea, but don't know how to really use it
  
  -- Height for FX slots, FX names are drawn centered (and clipped) inside this high rectangles
  SLOT_HEIGHT = 13, -- pixels high
  
  -- Gap between the first track and teh master track (when visible)
  MASTER_GAP = 5,
  
  -- For matching and shrinking FX names
  MATCH_UPTOCOLON = "(.-:)",
  
  -- Nondocked window size, and docker address (overridden from EXTSTATE if such exists)
  WIN_X = 1000,
  WIN_Y = 200,
  WIN_W = 200,
  WIN_H = 200,
  DOCKER_NUM = 512+1, -- 512 = left of arrange view, +1 == docked (not universally true)
  
  -- Window class names to look for, I have no idea how or if this works on Mac/Linux
  -- CLASS_TRACKLISTWIN = "REAPERTrackListWindow", -- this is the arrange view where the media items live
  CLASS_TCPDISPLAY = "REAPERTCPDisplay", -- this is the TCP where the track panes live
  
  TCP_HWND = nil, -- filled in when script initializes (so strictly speaking not constant, but yeah...)
  TCP_top = nil, -- Set on every defer before calling any other function
  TCP_bot = nil, -- Set on every defer before calling any other function
  
  MFX_HWND = nil, -- this is our own window, need this to make mousewheel work
  
  ACT_SCROLLVERT = 989, -- View: Scroll vertically (MIDI CC relative/mousewheel)
  ACT_ZOOMVERT = 991, -- View: Zoom vertically (MIDI CC relative/mousewheel)
  ACT_SCROLLVIEWDOWN = 40139, -- View: Scroll view down
  ACT_SCROLLVIEWUP = 40138, -- View: Scroll view up
  
  ACT_ZOOMINVERT = 40111, -- View: Zoom in vertical
  ACT_ZOOMOUTVERT = 40112, -- View: Zoom out vertical
  
  ACT_FXBROWSERWINDOW = 40271, -- View: Show FX browser window
  
  CMD_FOCUSARRANGE = 0, -- SWS/BR: Focus arrange (_BR_FOCUS_ARRANGE_WND)
  CMD_FOCUSTRACKS = 0,  -- SWS/BR: Focus tracks (_BR_FOCUS_TRACKS)
  CMD_SCROLLTCPDOWN = 0,-- Xenakios/SWS: Scroll track view down (page)
  CMD_SCROLLTCPUP = 0,  -- Xenakios/SWS: Scroll track view up (page)
  
  -- off-screen draw buffer for the header (coudl not get thsi to work, see drawHeader() below)
  BLITBUF_HEAD = 16, 
  BLITBUF_HEADW = 300,
  BLITBUF_HEADH = 300,
  
  -- Globally accessible variables used to communicate between different parts of the code
  mouse_y = nil, -- is set to mouse_y when mouse inside MFXlist, else nil
  track_hovered = nil, -- is set to the track (ptr) currently under mouse cursor, nil if mouse outside of client are
  fx_hovered = nil, -- is set to the index (1-based!) of FX under the mouse cursor, nil if mouse is outside of current track FX 
  
  mbl_downx = nil, -- stores left mouse button down coords, used for left MB drag actions
  mbl_downy = nil,
  down_object = nil, -- {track, fx} stores left mouse button down object if any
  drag_object = nil, -- {track, fx} that is dragged, given by track_hovered, fx_hovered
  drag_endx = nil,
  drag_endy = nil,
  
  openwin_list = nil, -- list of currently open windows to help the external win-close focus issue
  count_down = 0,
  
  footer_text = "MFX-list", -- changes after initializing, shows name of currently hovered track
  header_text = "MFX-list", -- this doesn't really change after initialzing, but could if useful
}

local CURR_PROJ = 0
------------------------------------------ Stolen from https://stackoverflow.com/questions/41942289/display-contents-of-tables-in-lua
-- Recursive print of a table, returns a string
local function tprint (tbl, indent)
  if not indent then indent = 0 end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2 
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint  .. k ..  "= "   
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table") then
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end
-------------------------- Windows specific stuff here --------------------------------------------------------------
-------------------------------------------------------- Stolen from https://forum.cockos.com/showthread.php?t=230919
-- Requires js_ReaScriptAPI extension, 
-- https://forum.cockos.com/showthread.php?t=212174
local function getClientBounds(hwnd)
  
  local ret, left, top, right, bottom = rpr.JS_Window_GetClientRect(hwnd)
  return left, top, right-left, bottom-top
  
end --GetClientBounds
-----------------------------------------
local function getAllChildWindows(hwnd)
  
  local arr = rpr.new_array({}, 255)
  rpr.JS_Window_ArrayAllChild(hwnd, arr)
  return arr.table() 

end -- getAllChildWIndows
------------------------------------------
local function getTitleMatchWindows(title, exact)
  
  local reaperarray = rpr.new_array({}, 255)
  rpr.JS_Window_ArrayFind(title, exact, reaperarray)
  return reaperarray.table()
  
end -- getTitleMatchWindows
-----------------------------------------------------------------
-- Find the occurrance-th instance of a window named by classname 
local function FindChildByClass(hwnd, classname, occurrence) 

  local adr = getAllChildWindows(hwnd)
  local count = #adr
  for j = 1, count do
    local hwnd = rpr.JS_Window_HandleFromAddress(adr[j]) 
    if rpr.JS_Window_GetClassName(hwnd) == classname then
      occurrence = occurrence - 1
      if occurrence == 0 then
        return hwnd
      end
    end
  end
  
end --FindChildByClass
---------------------------------------------------------
-- Returns the HWND and the screen coordinates of the TCP
local function getTCPProperties()
-- get first reaper child window with classname "REAPERTCPDisplay".
  local tcp_hwnd = FindChildByClass(rpr.GetMainHwnd(), MFXlist.CLASS_TCPDISPLAY, 1) 
  if tcp_hwnd then
    local x,y,w,h = getClientBounds(tcp_hwnd)
    --msg(w) -- show width
    return tcp_hwnd, x, y, w, h
  end
  return nil, -1, -1, -1, -1
end
------------------------------------------------------------------------------------
-- This works, except for when no modifier key is used, then it scrolls the arrange!
local function sendTCPWheelMessage(mbkeys, wheel, screenx, screeny)
  
  local retval = rpr.JS_WindowMessage_Send(MFXlist.TCP_HWND, 
      "WM_MOUSEWHEEL", 
      mbkeys, -- wParam, mouse buttons and modifier keys
      wheel, -- wParamHighWWord, wheel distance
      screenx, screeny) -- lParam, lParamHighWord, need to fake it is over TCP?  
  
  return retval

end -- sendTCPWheelMessage
--------------------------------------------------------------------
-- None of these seem to work, disregard
local function sendTCPScrollMessage(mbkeys, wheel, screenx, screeny)
  
  -- From swell-types.h: 
  local SB_LINEUP, SB_LINEDOWN = 0, 1
  local updown = wheel < 0 and SB_LINEDOWN or SB_LINEUP
  local retval = rpr.JS_WindowMessage_Send(MFXlist.TCP_HWND, "WM_VSCROLL", updown, 0, 0, 0)
  
end
---------------------------------------------- SWS specifc stuff go here
local function initSWSCommands()
  
  MFXlist.CMD_FOCUSARRANGE = rpr.NamedCommandLookup("_BR_FOCUS_ARRANGE_WND")
  MFXlist.CMD_FOCUSTRACKS = rpr.NamedCommandLookup("_BR_FOCUS_TRACKS")
  MFXlist.CMD_SCROLLTCPDOWN = rpr.NamedCommandLookup("_XENAKIOS_TVPAGEDOWN") -- scrolls TCP, but too much
  MFXlist.CMD_SCROLLTCPUP = rpr.NamedCommandLookup("_XENAKIOS_TVPAGEUP")
  
end 
-------------------------------------------------
-- These scroll whole pages, I don't want that
local function scrollTCPUp()
  
  rpr.Main_OnCommand(MFXlist.CMD_SCROLLTCPUP, 0)
  
end -- scrollTCPUp
-------------------------------
local function scrollTCPDown()
  
  rpr.Main_OnCommand(MFXlist.CMD_SCROLLTCPDOWN, 0)
  
end -- scrollTCPDown
-----------------------------------------------
-- Set the focus to TCP so keystrokes go there
-- Called after (almost) every mouse click
local function focusTCP()

  rpr.JS_Window_SetFocus(MFXlist.TCP_HWND)

end -- focusTCP
---------------
local function focusMFX()
  
  rpr.JS_Window_SetFocus(MFXlist.MFX_HWND)
  
end -- focusMFX
---------------
local function hasFocusMFX()
  
  return rpr.JS_Window_GetFocus() == MFXlist.MFX_HWND
  
end -- hasFocusMFX
----------------------------------------------------------
-- Simple linked list implementation for the openwin_list
linkedList = -- has to be global here, made local below
{
  head = nil,
  length = 0,
  
  new = function()
          local self = {}
          setmetatable(self, {__index = linkedList})
          return self
        end, -- new
        
  insert = function(self, element) 
              self.head = {next = self.head, elem = element}
              self.length = self.length + 1
              return 
            end, -- insert
            
  print = function(self, outputter)
            if not outputter then
              outputter = print
            end
            if not self.head then
              outputter("<empty list>")
              return
            end
            local ptr = self.head
            while ptr do
              outputter(ptr.elem)
              ptr = ptr.next
            end
          end, -- print
          
  find = function(self, element, compare)
          if not compare then
            compare = function(p1, p2) return p1 == p2 end 
          end
          local ptr = self.head
          while ptr do
            if compare(ptr.elem, element) then
              return ptr
            end
            ptr = ptr.next
          end
          return ptr -- nil
        end, -- find
        
  -- Have to first find, then remove
  remove = function(self, ptr)
            if not ptr then return false end
            
            if ptr == self.head then
              self.head = self.head.next
              self.length = self.length - 1
              return true
            end
            local pptr = self.head
            while pptr do
              if pptr.next == ptr then 
                pptr.next = ptr.next -- adjust links
                self.length = self.length - 1
                return true
              end
              pptr = pptr.next
            end
            return false -- not found    
          end, -- remove (ptr)
}
local linkedList = linkedList
----------------------------------------------------------------
-- This doesn't work, I find no way to make sense of the docker
local function findLeftDock()
  
  local mhwnd = rpr.GetMainHwnd()
  local _, mleft, mtop, mright, mbottom = rpr.JS_Window_GetClientRect(mhwnd)
  Msg("MainHwnd, left: "..mleft..", top: "..mtop..", right: "..mright..", bottom: "..mbottom)
  
  local adr = getTitleMatchWindows("REAPER_dock", true) -- this does get all 16 dockers
  local count = #adr
  local docknumber = 0 -- the order of how the dockers are returned does not make sense to me
  for i = 1, count do
    local hwnd = rpr.JS_Window_HandleFromAddress(adr[i]) 
    --local classname = rpr.JS_Window_GetClassName(hwnd)
    --Msg("i: "..i..", adr: "..adr[i]..", class: "..classname)
    --if classname == "REAPER_dock" then
      local _, left, top, right, bottom = rpr.JS_Window_GetRect(hwnd) 
      Msg("REAPER_dock #"..docknumber..", left: "..left..", top: "..top..", right: "..right..", bottom: "..bottom)
      if left == mleft then -- this should be the left docker?
        -- then what? how to get its number? do they come in order?
        --MFXlist.DOCKER_NUM = 2^docknumber + 1
      end
      docknumber = docknumber + 1
    --end
  end
  
end -- findLeftDock
---------------------------------------------
-- This is the next best thing we can do, add
-- menu option to switch to the next docker
local function nextDocker(bits)
  
  local masked = bits & 0xFFFF
  local shifted = masked >> 1
  if shifted == 0 then
    shifted = 0x8001
  else
    shifted = shifted | 0x01
  end
  return shifted
  
end -- nextDocker
------------------------------
local function switchDocker()
  
  MFXlist.DOCKER_NUM = nextDocker(MFXlist.DOCKER_NUM)

  gfx.quit()
  gfx.clear = MFXlist.COLOR_EMPTYSLOT[1] * 255 + MFXlist.COLOR_EMPTYSLOT[2] * 255 * 256 + MFXlist.COLOR_EMPTYSLOT[3] * 255 * 65536
  gfx.init(MFXlist.SCRIPT_NAME, MFXlist.WIN_W, MFXlist.WIN_H, MFXlist.DOCKER_NUM, MFXlist.WIN_X, MFXlist.WIN_Y)
  
end -- switchDocker
-----------------------------------------
-- Seems that the only way to affect last
-- touched track by scripting is to do:
local function setLastTouchedTrack(track)
  
  -- Save current track selection
  rpr.SetOnlyTrackSelected(track)
  -- set back current track selection
  
end -- setLastTouchedTrack
--------------------------------------------------------
local function collectFX(track)
  assert(track, "collectFX: invalid parameter - track")
  
  local fxtab = {}
  
  local numfx = rpr.TrackFX_GetCount(track)
  for i = 1, numfx do
    local _, fxname = rpr.TrackFX_GetFXName(track, i-1, "")
    local fxtype = fxname:match(MFXlist.MATCH_UPTOCOLON) or "VID:"  -- Video processor FX don't have prefixes
    fxname = fxname:gsub(MFXlist.MATCH_UPTOCOLON.."%s", "") -- up to colon and then space, replace by nothing
    fxname = fxname:gsub("%([^()]*%)","")
    local enabled =  rpr.TrackFX_GetEnabled(track, i-1)
    local offlined = rpr.TrackFX_GetOffline(track, i-1)
    table.insert(fxtab, {fxname = fxname, fxtype = fxtype, enabled = enabled, offlined = offlined}) -- confusing <key, value> pairs here, but it works
  end
  return fxtab
end
------------------------------------------
local function getTrackPosAndHeight(track)
  assert(track, "getTrackPosAndHeight: invalid parameter - track")
  
  local height = rpr.GetMediaTrackInfo_Value(track, "I_WNDH") -- current TCP window height in pixels including envelopes
  local posy = rpr.GetMediaTrackInfo_Value(track, "I_TCPY") -- current TCP window Y-position in pixels relative to top of arrange view
  return posy, height
  
end -- getTrackPosAndHeight()
---------------------------------------------------------------------------
local function getTrackInfo(track)
  assert(track, "getTrackInfo: invalid parameter - track")
  
  local _, name = rpr.GetTrackName(track)
  local visible = rpr.IsTrackVisible(track, false) -- false for TCP (true for MCP)
  local enabled = rpr.GetMediaTrackInfo_Value(track, "I_FXEN") ~= 0 -- fx enabled, 0=bypassed, !0=fx active
  local selected = rpr.IsTrackSelected(track) -- true if selected, false if not
  local posy, height = getTrackPosAndHeight(track)
  local fx = collectFX(track)
  
  return {track = track, name = name, selected = selected, visible = visible, enabled = enabled, height = height, posy = posy, fx = fx}
end
------------------------------
local function collectTracks()
  local tracks = {}
  
  if rpr.GetMasterTrackVisibility() & 0x1 == 1 then -- Master track visible in TCP
    local master = rpr.GetMasterTrack(CURR_PROJ)
    local info = getTrackInfo(master)
    table.insert(tracks, info)
  end

  local numtracks = rpr.CountTracks(CURR_PROJ) -- excludes the master track, taken care of above
  for i = 1, numtracks do
    local track = rpr.GetTrack(CURR_PROJ, i-1)
    local info = getTrackInfo(track)
    table.insert(tracks, info)
  end
  
  return tracks
end
--------------------------------------------------------
local function showTracks(tracks) -- In console output

  for i = 1, #tracks do
    local trinfo = tracks[i]
    -- local fxtable = collectFX(trinfo.track)
    local fxtable = trinfo.fx
    for j = 1, #fxtable do
      local fx = fxtable[j]
    end
  end
end
--------------------------------------------------------
-- Find the index of the first track visible in the TCP
-- A track can be invisible from the TCP for two reasons:
-- 1. It has its TCP visbility property set to false, and then its height seems to be 0 (this is used)
-- 2. It is outside of the TCP view rectangle, posy either negative or larger than TCP height
local function getFirstTCPTrackLinear()
-- This version does a linear search from index 0 looking for the first track for which posy+height > 0
-- Note that the returned track index is 1-based, just as track numbering, so MASTER is index 0
  
  if rpr.GetMasterTrackVisibility() & 0x1 == 1 then -- Master track visible in TCP
    local master = rpr.GetMasterTrack(CURR_PROJ)
    local posy, height = getTrackPosAndHeight(master)
    if height + posy > 0 then return master, 0 end
  end

  local numtracks = rpr.CountTracks(CURR_PROJ) -- excludes the master track, taken care of above
  if numtracks == 0 then return nil, -1 end
    
  for i = 1, numtracks do
    local track = rpr.GetTrack(CURR_PROJ, i-1)
    local posy, height = getTrackPosAndHeight(track)
    if height + posy > 0 then return track, i end -- rules out invisible track (height == 0) at the top (posy = 0)
  end
  assert(nil, "getFirstTrackLinear: Should never get here!")
  
end -- getFirstTCPTrackLinear
---------------------------------------
local function getFirstTCPTrackBinary()
  
  local fixForMasterTCPgap = false
  
  if rpr.GetMasterTrackVisibility() & 0x1 == 1 then -- Master track visible in TCP
    local master = rpr.GetMasterTrack(CURR_PROJ)
    local posy, height = getTrackPosAndHeight(master)
    if height + posy > 0 then return master, 0 end
    if height + posy + MFXlist.MASTER_GAP >= 0 then fixForMasterTCPgap = true end
  end
  
  local numtracks = rpr.CountTracks(CURR_PROJ)
  if numtracks == 0 then return nil, -1 end
  
  -- When the MASTER posy + height == 0, then the 0th track is at posy == 5
  -- And this is then the first visible track. Special case
  if fixForMasterTCPgap then 
    local track = rpr.GetTrack(CURR_PROJ, 0)
    return track, 1
  end

  local left, right = 0, numtracks - 1
  while left <= right do
    local index = math.floor((left + right) / 2)
    local track = rpr.GetTrack(CURR_PROJ, index)
    local posy, height = getTrackPosAndHeight(track)
    if posy < 0 then
      if posy + height > 0 then return track, index + 1 end -- Rules out invisible tracks, height == 0, at the top
      left = index + 1
    elseif posy > 0 then
      right = index - 1
    else -- posy == 0, then this is the one
      return track, index + 1
    end      
  end
  
  -- Are all tracks hidden (height = 0) and first track has negative y-coord? (issue #18)
  -- Then there are no visible tracks, what do we do? Pretend that there are no tracks!
  return nil, -1
  
end -- getFirstTCPTrackBinary
---------------------------------------------------------------------------
-- Does a binary search, halving and halving until it finds the right track
-- If no tracks, or only the Master track is visible, this returns nil, 0
-- But in that case getFirstTCPTrack has already returned either the master or -1
local function getLastTCPTrackBinary(tcpheight)
  assert(tcpheight, "getLastTCPTrack: invalid parameter - tcpheight")
  
  local numtracks = rpr.CountTracks(CURR_PROJ)
  if numtracks == 0 then return nil, 0 end
  
  -- is the last track visible?, If so we are done
  local track = rpr.GetTrack(CURR_PROJ, numtracks-1)
  local posy, _ = getTrackPosAndHeight(track)
  if posy < tcpheight then return track, numtracks end
  
  -- else, do a binary search
  local left, right = 0, numtracks - 1
  while left <= right do
    local index = math.floor((left + right) / 2)
    local track = rpr.GetTrack(CURR_PROJ, index)
    local posy, height = getTrackPosAndHeight(track)
    if posy < tcpheight then
      if posy + height >= tcpheight then return track, index + 1 end
      left = index + 1
    elseif posy > tcpheight then
      right = index - 1
    else -- posy == tcpheight, the previous track is the last visible
      local track = rpr.GetTrack(CURR_PROJ, index - 1)
      return track, index
    end
  end

  return nil, 0 -- we should never really get here
  
end -- getLastTCPTrackBinary
--------------------------------------------------------------------
-- Since the TCP has a limited number of visible tracks, a linear search
-- starting from the first visible track may be faster than a binary
-- That was the idea, but measuring there seems to be no significant improvement
-- Instead binary search is slightly better with many visible tracks 
local function getLastTCPTrackLinear(tcpheight, firsttrack)
  assert(tcpheight and firsttrack, "getLastTrackLinear: invalid parameter - tcpheight or firsttrack")

  -- Same as in binary search, first take care of some obvious easy cases
  local numtracks = rpr.CountTracks(CURR_PROJ)
  if numtracks == 0 then return nil, 0 end
  
  -- is the last track visible?, If so we are done
  local track = rpr.GetTrack(CURR_PROJ, numtracks-1)
  local posy, _ = getTrackPosAndHeight(track)
  if posy < tcpheight then return track, numtracks end
  
  -- else, look from the first towards the last linearily
  for i = firsttrack, numtracks do -- firsttrack is 1-based
    local track = rpr.GetTrack(CURR_PROJ, i-1)
    local posy, height = getTrackPosAndHeight(track)
    if posy + height > tcpheight then return track, i end
  end

  assert(nil, "getLastTCPTrackLinear: should not really get here!")
  
end -- getLastTCPTrackLinear
--------------------------------------------
-- Tracks can be invisible for two reasons:
-- 1. outside the TCP bounding box
-- 2. have visibility property turned off
local function collectVisibleTracks()
  
  local _, _, _, h = getClientBounds(MFXlist.TCP_HWND)
  
  local _, findex = getFirstTCPTrackBinary()
  local _, lindex = getLastTCPTrackBinary(h)
  
  local vistracks = {}
  if findex < 0 then return vistracks end -- No visible tracks
  if findex == 0 then -- master track is visible
    local master = rpr.GetMasterTrack(CURR_PROJ)
    local minfo = getTrackInfo(master)
    table.insert(vistracks, minfo)
    findex = 1
  end
  
  for i = findex, lindex do
    local track = rpr.GetTrack(CURR_PROJ, i-1)
    local trinfo = getTrackInfo(track)
    if trinfo.visible then table.insert(vistracks, trinfo) end
  end
  
  return vistracks
  
end -- collectVisibleTracks
-----------------------------
local function drawHeader()

  -- Draw over everything above the FX list drawing area
  gfx.set(MFXlist.COLOR_EMPTYSLOT[1], MFXlist.COLOR_EMPTYSLOT[2], MFXlist.COLOR_EMPTYSLOT[3])
  gfx.rect(0, 0, gfx.w, MFXlist.TCP_top)
  --gfx.set(MFXlist.COLOR_FAINT[1], MFXlist.COLOR_FAINT[1], MFXlist.COLOR_FAINT[1])
  gfx.set(1, 1, 1, 0.7)
  gfx.x, gfx.y = 0, 0
  gfx.setfont(MFXlist.FONT_HEADER)
  gfx.drawstr(MFXlist.header_text, 5, gfx.w, MFXlist.TCP_top)
  gfx.a = MFXlist.FX_DISABLEDA
  gfx.line(0, MFXlist.TCP_top, gfx.w, MFXlist.TCP_top)
  
end -- drawHeader
------------------------------
local function drawFooter()
  
  -- Draw bottom line of FX list area (should not draw FX below this, it will be erased)
  gfx.line(0, MFXlist.TCP_bot, gfx.w, MFXlist.TCP_bot)  
  gfx.set(MFXlist.COLOR_EMPTYSLOT[1], MFXlist.COLOR_EMPTYSLOT[2], MFXlist.COLOR_EMPTYSLOT[3])
  gfx.rect(0, MFXlist.TCP_bot + 1, gfx.w, gfx.h - MFXlist.TCP_bot - 1)
  
  local text = MFXlist.footer_text
  if text and text ~= "" then 
    gfx.set(1, 1, 1, 0.7)
    gfx.setfont(MFXlist.FONT_FXNAME, MFXlist.FONT_NAME1, MFXlist.FONT_SIZE1)
    gfx.x, gfx.y = 0, MFXlist.TCP_bot   
    gfx.drawstr(text, 5, gfx.w, gfx.h) -- Note, the last two parameters are the right/bottom COORDS of the box to draw within, not width/height
  end

end -- drawFooter
----------------------------------------------------
local function drawSelectedIndicator(ycoord, height)
  
  -- Msg("drawSelectedIndicator("..ycoord..", "..height..")")
  gfx.set(1, 1, 1, 1)
  gfx.line(gfx.w-2, ycoord + 1, gfx.w-2, ycoord + height - 2)
  
end -- drawSelectedIndicator
----------------------------------
local function drawDropIndicator()
  
  if gfx.mouse_cap & MFXlist.MOD_CTRL == MFXlist.MOD_CTRL then
    gfx.set(0, 0, 1) -- blue indicates copy
  else
    gfx.set(0, 1, 0) -- green indicates move
  end
  gfx.line(10, gfx.y, gfx.w-10, gfx.y)
  
end -- drawDropIndicator
-----------------------
local function drawTracks()
  
  -- gfx.set(1, 1, 1)
  gfx.setfont(MFXlist.FONT_FXNAME)--, MFXlist.FONT_NAME1, MFXlist.FONT_SIZE1)
  
  MFXlist.fx_hovered = nil
  MFXlist.track_hovered = nil
  
  local drawy = MFXlist.TCP_top
  
  local vistracks = collectVisibleTracks()
  local numtracks = #vistracks
  for i = 1, numtracks do 
    gfx.set(1, 1, 1, gfx.a)
    local insidetrack = false -- used to send message from track to FX on track
    local trinfo = vistracks[i]
    local posy = trinfo.posy
    local height = trinfo.height
    local selected = trinfo.selected
    local chainon = trinfo.enabled -- track FX chain enabled
    -- if the mouse is currently inside this track rect
    if MFXlist.mouse_y and posy <= MFXlist.mouse_y-drawy and MFXlist.mouse_y-drawy <= posy + height then
      
      MFXlist.footer_text = trinfo.name
      insidetrack = true -- send message to FX part of code, see below
      MFXlist.track_hovered = trinfo.track
      
    end
    -- Draw bounding box for track FX
    gfx.a = MFXlist.FX_OFFLINEDA -- bounding box is always drawn faint
    gfx.rect(0, drawy + posy, gfx.w, height, (chainon and 0 or 1)) -- disabled chain is not filled with faint color
    -- Calc the number of FX slots to draw, and draw them
    local fxlist = trinfo.fx
    local numfxs = math.ceil(height / MFXlist.SLOT_HEIGHT) -- max num FX to show 
    local count = math.min(#fxlist, numfxs)
    local cropy = drawy+posy+height-1 -- crop FX name slot to this
    gfx.x, gfx.y = 0, drawy + posy  -- drawing FX names start at this position
    for i = 1, count do
      local fx = fxlist[i]
      gfx.a = (fx.enabled and not fx.offlined and chainon) and 1 or MFXlist.FX_DISABLEDA -- disabled FX are shown faint
      -- if mouse hovers over this FX, draw it in different color
      if insidetrack and gfx.y <= MFXlist.mouse_y and MFXlist.mouse_y < gfx.y + MFXlist.SLOT_HEIGHT then
        
        gfx.set(MFXlist.COLOR_FXHOVERED[1], MFXlist.COLOR_FXHOVERED[2], MFXlist.COLOR_FXHOVERED[3], gfx.a)
        gfx.setfont(MFXlist.FONT_FXBOLD)
        MFXlist.fx_hovered = i -- store fx index (1-based!) for mouse click
        
      else
        
        gfx.setfont(MFXlist.FONT_FXNAME)
        gfx.set(1, 1, 1, gfx.a)
        
      end
      gfx.x = 0
      local corner = math.min(gfx.y + MFXlist.SLOT_HEIGHT, cropy) -- make sure to crop within the bounding track rect
      gfx.drawstr(fx.fxname, 1, gfx.w, corner) 
      if fx.offlined then -- strikeout offlined FX
        
        local w, h = gfx.measurestr(fx.name)
        local y = gfx.y + MFXlist.SLOT_HEIGHT/2
        gfx.line((gfx.w-w)/2, y, (gfx.w+w)/2, y, gfx.a)
        
      end
      -- if dragging and are on top of this FX, show drop indicator above it
      if insidetrack and MFXlist.drag_object and MFXlist.fx_hovered == i then
        
        drawDropIndicator()
        
      end
      gfx.y = gfx.y + MFXlist.SLOT_HEIGHT
      
    end
    -- if dragging and not hovering any FX, draw drop indicator at end of FX chain
    if insidetrack and MFXlist.drag_object and not MFXlist.fx_hovered then
      
      drawDropIndicator()
      
    end
    
    if selected then 
      drawSelectedIndicator(drawy + posy, height)
    end
    
  end

end -- drawTracks
-----------------------------------------
-- Shows it in Reaper's console (for now)
local function showInfo(mx, my)
  
  rpr.ShowConsoleMsg(MFXlist.SCRIPT_NAME.." "..MFXlist.SCRIPT_VERSION..'\n')
  local authors = table.concat(MFXlist.SCRIPT_AUTHORS, ", ")
  rpr.ShowConsoleMsg(authors..", "..MFXlist.SCRIPT_YEAR..'\n')
  rpr.ShowConsoleMsg("Dock: "..gfx.dock(-1)..", gfx.w: "..gfx.w..", gfx.h: "..gfx.h)
  -- rpr.ShowConsoleMsg("TCP area (screen coords): "..x..", "..y..", "..w..", "..h)
  rpr.ShowConsoleMsg("\nMFXlist header: 0, 0, "..gfx.w..", "..MFXlist.TCP_top) 
  rpr.ShowConsoleMsg("\nMFXlist drawing area: 0, "..MFXlist.TCP_top..", "..gfx.w..", "..MFXlist.TCP_bot - MFXlist.TCP_top)
  rpr.ShowConsoleMsg("\nMFXlist footer: 0, "..MFXlist.TCP_bot..", "..gfx.w..", "..gfx.h - MFXlist.TCP_bot)
  
end -- showInfo
---------------------------------------
local function handleMenu(mcap, mx, my)

  local menustr = MFXlist.MENU_STR
  
  gfx.x, gfx.y = mx, my
  local ret = gfx.showmenu(menustr)
  if ret == MFXlist.MENU_QUIT then
    return ret
  elseif ret == MFXlist.MENU_SHOWINFO then
    showInfo(mx, my)
  elseif ret == MFXlist.MENU_NEXTDOCK then
    switchDocker()
  elseif ret == MENU_SETUP10 then
    setupForTesting(10)
  elseif ret == MFXlist.MENU_SHOWFIRSTTCP then
    local startt = rpr.time_precise()
    local track, idx = getFirstTCPTrackBinary()
    local endt = rpr.time_precise()
    Msg("First visible track: "..idx.." ("..endt-startt..")")
  elseif ret == MFXlist.MENU_SHOWLASTTCP then
    local _, _, _, h = getClientBounds(MFXlist.TCP_HWND)
    local startt = rpr.time_precise()
    local track, idx = getLastTCPTrackBinary(h)
    local endt = rpr.time_precise()
    Msg("Last visible track (bin): "..idx.." ("..endt-startt..")")
  elseif ret == MFXlist.MENU_LINEARFINDLAST then
    local ftrack, fidx = getFirstTCPTrackBinary()
    local _, _, _, h = getClientBounds(MFXlist.TCP_HWND)
    local startt = rpr.time_precise()
    local ltrack, lidx = getLastTCPTrackLinear(h, fidx)
    local endt = rpr.time_precise()
    Msg("Last visible track (lin): "..lidx.." ("..endt-startt..")")
  elseif ret == MFXlist.MENU_FINDLEFTDOCK then
    findLeftDock()
  end
  
  return ret
  
end -- handleMenu
--------------------------------------------
-- Swap bits 2 and 3 (0-based from the left)
local function swapCtrlShft(bits)	
  
  local mask = MFXlist.MOD_CTRL | MFXlist.MOD_SHIFT -- 0xC -- 1100
  local shftctrl = ((bits & MFXlist.MOD_CTRL) << 1) | ((bits & MFXlist.MOD_SHIFT) >> 1)

  return (bits & ~mask) | shftctrl

end -- swapCtrlShft
---------------------------------------------------------------
-- Mouse wheel over MFXlist, send the TCP a mousewheel message
-- These variables are global but locally to handleWheel
-- local count_down = 0 -- replaced by MFXlist.count_down
local prev_wheel = 0

local function handleWheel(mcap, mx, my)
  
  local wheel = gfx.mouse_wheel
  gfx.mouse_wheel = 0
  
  if wheel == 0 and prev_wheel == 0 then 
    --[ [ -- this can maybe also be handled right before the defer in the main fun
    if MFXlist.count_down == 0 then return end
    
    MFXlist.count_down = MFXlist.count_down - 1 
    if MFXlist.count_down == 0 then
      focusTCP() -- do this after count down
    end
    --]]
    return 
    
  end -- no wheeling, nothing more to do

  MFXlist.count_down = MFXlist.FOCUS_DELAY
  
  -- So here wheel ~= 0, if this is the first time we need to grab focus and wait one scan cycle to get mod keys
  if prev_wheel == 0 then -- remeber current wheel so we can act on it on the next scan
    
    prev_wheel = wheel -- remember wheel value
    focusMFX() -- set focus so we get the mod keys
    MFXlist.count_down = 0 -- make sure we do not lose focus
    return
    
  end
  
  -- Here prev_wheel ~= 0 and focus is on MFX
  
  if mcap == 0 then -- no mod key
    
    if prev_wheel < 0 then
      rpr.Main_OnCommand(MFXlist.ACT_SCROLLVIEWDOWN, 0)
    else
      rpr.Main_OnCommand(MFXlist.ACT_SCROLLVIEWUP, 0)
    end
    
  elseif mcap & MFXlist.MOD_KEYS == MFXlist.MOD_CTRL then
    -- Ctrl+Wheel over TCP locks the zoom to the track that is (or comes) under the cursor, pushing the
    -- other tracks up/down. When sending wheel message with Ctrl mod key, this does not happen, instead
    -- something unclear-what-exactly happens; but we leave it for now...
    -- Could it be View: Zoom in/out vertically (40111, resp 40112) is what happens? No, not exactly that 
    -- either, as those also lock to the track that is (or comes) under the cursor. Maybe must do that?
    
    -- No, these does not seem to work as expected either. 
    -- setLastTouchedTrack(MFXlist.track_hovered)
    if prev_wheel < 0 then
      rpr.Main_OnCommand(MFXlist.ACT_ZOOMOUTVERT, 0)
    else
      rpr.Main_OnCommand(MFXlist.ACT_ZOOMINVERT, 0)
    end
    
  else
    -- It does not seem to matter which type of coordinates that are sent
    -- local screenx, screeny = gfx.clienttoscreen(mx, my)
    -- local tcpx, tcpy = rpr.JS_Window_ScreenToClient(MFXlist.TCP_HWND, screenx, screeny)
    sendTCPWheelMessage(mcap, prev_wheel, mx, my) 
    
  end 
  
  prev_wheel = 0
  
end -- handleMousewheel
-----------------------------------------------------------------------------
-- When FX chain or FX float win is opened, it is added to the openwin_list
-- If externally closed (ESC or top right X) it remains on the list
-- If there is no such win open, MFX has focus and need to give it away
-- Walk the list, if a window on the list is found that is not open, give the
-- focus to teh TCP (ideally would be to the next window, but no idea how)
local function manageOpenWindows()
  
  if MFXlist.openwin_list.length > 0 then -- is it faster to check head for nil?
    local ptr = MFXlist.openwin_list.head
    while ptr do
      if not rpr.TrackFX_GetOpen(ptr.elem[1], ptr.elem[2]) then -- someone closed, but not me
        MFXlist.openwin_list:remove(ptr)
        focusTCP()
        return
      end
      ptr = ptr.next
    end
  end
  
end -- manageOpenWindows
-----------------------------------------------------------------------------------
-- It seems manageOpenWindows solved the problem was attempted to be solved by this
local prev_focus = false
local focus_counter = 0 -- just for debug, really
local function manageFocus()
  
  local hasfocus = hasFocusMFX()
  -- Just got focus
  if hasfocus and not prev_focus then
    
    focus_counter = focus_counter + 1
    prev_focus = true
    
  -- Just lost focus
  elseif not hasfocus and prev_focus then
    
    focus_counter = focus_counter + 1
    prev_focus = false
    
  -- was lost, still lost
  elseif not hasFocus and not prev_focus then
    
  -- had focus. still have it
  else -- hasFocus and prev_focus 
    
  end
  
end -- manageFocus
-----------------------------------------------------------
-- index is here 0-based!
-- wtype is 0 for FX chain window, 2 for floating FX window
local function handleToggleWindow(track, index, wtype)
  
  local openclose = rpr.TrackFX_GetOpen(track, index) and wtype or wtype + 1 -- 0,2: to close, 1,3: to open
  
  rpr.TrackFX_Show(track, index, openclose)  
  
  if openclose == wtype then -- just closed, remove from openwin_list, and focus TCP
    
    local compare = function(p1, p2) return p1[1] == p2[1] and p1[2] == p2[2] end
    local ptr = MFXlist.openwin_list:find({track, index}, compare)
    
    if ptr then -- what if not found (we get nil here)?
      
      MFXlist.openwin_list:remove(ptr)
      
    end
    
    focusTCP()
    
  else -- just opened, add to openwin_list
    
    MFXlist.openwin_list:insert({track, index})
    
  end
  
end -- handleToggleWindow
----------------------------------------------
local function handleLeftMBclick(mcap, mx, my)
  
  local track = MFXlist.track_hovered
  local index = MFXlist.fx_hovered
  local modkeys = mcap & MFXlist.MOD_KEYS
  
  if not track then -- we clicked oustide track area, header or footer
    
    if my < MFXlist.TCP_top then
      -- TODO! Left click over header, invoke command
    elseif my >= MFXlist.TCP_bot then
      -- TODO! Left click over footer. Anything useful to do?
    end
    focusTCP()
    return
    
  -- Left click inside track rect but not on FX, empty slot
  elseif not MFXlist.fx_hovered then -- so we hover over track but not any fx
    
    if modkeys == 0 then -- No modifier key, open Add FX dialog
      
      rpr.SetOnlyTrackSelected(track)
      rpr.Main_OnCommand(MFXlist.ACT_FXBROWSERWINDOW, 0)    
      return
      
    elseif modkeys == (MFXlist.MOD_SHIFT | MFXlist.MOD_CTRL | MFXlist.MOD_ALT) then
      -- Shift+Ctrl+Alt
      -- TODO! Left click over track empty slot with Shift+Ctrl+Alt key!
      focusTCP()
      return
    elseif modkeys == (MFXlist.MOD_SHIFT | MFXlist.MOD_ALT) then
      -- Shift+Alt
      -- "TODO! Left click over track empty slot with Shift+Alt key!
      focusTCP()
      return
    elseif modkeys == (MFXlist.MOD_SHIFT | MFXlist.MOD_CTRL) then
      -- Shift+Ctrl
      -- TODO! Left click over track empty slot with Shift+Ctrl key!
      focusTCP()
      return
    elseif modkeys == (MFXlist.MOD_CTRL | MFXlist.MOD_ALT) then
      -- Ctrl+Alt
      -- TODO! Left click over track empty slot with Ctrl+Alt key!
      focusTCP()
      return
    elseif modkeys == MFXlist.MOD_SHIFT then 
      -- Shift key
      -- TODO! Left click over track empty slot with Shift key!
      focusTCP()
      return
    elseif modkeys == MFXlist.MOD_CTRL then
      -- Ctrl-left click over track empty slot, behave as with no Ctrl key
      local count = rpr.TrackFX_GetCount(track) 
      if count == 0 then -- this case needs specal treatment
        
        -- Quirk around Reaper anomaly here, FX chain window cannot open/close unless 
        -- some FX is selected. So we add ReaEQ, open/close window, remove ReaEQ
        rpr.TrackFX_AddByName(track, "ReaEQ", false, -1)
        
        handleToggleWindow(track, 0, 0)
        
        rpr.TrackFX_Delete(track, 0) -- YES! This f***ing seems to work!
        -- But the delete makes teh window unfocused! Never mind for now.
        
      else -- if FX Chain is not empty, toggling works if some fx is selected
        
        handleToggleWindow(track, count-1, 0)
        
      end
      return
      
    elseif modkeys == MFXlist.MOD_ALT then
      -- Alt key
      -- TODO! Left click over track empty slot with Alt key!
      focusTCP()
      return
    else
      assert(nil, "handleLeftMB (1): should not get here!")
    end
    return
  end
  
  -- Clicked on specific FX in track
  if modkeys == 0 then 
    -- no mod key show/hide floating window for FX
    
    handleToggleWindow(track, index-1, 2)
    
  elseif modkeys == (MFXlist.MOD_SHIFT | MFXlist.MOD_CTRL | MFXlist.MOD_ALT) then
    -- Shift+Ctrl+Alt
    -- TODO! Left click over track FX with Shift+Ctrl+Alt key!
    -- Set focus to TCP so key strokes go there
    focusTCP()
    return
    
  elseif modkeys == (MFXlist.MOD_SHIFT | MFXlist.MOD_ALT) then
    -- Shift+Alt
    -- TODO! Left click over FX with Shift+Alt key!
    -- Set focus to TCP so key strokes go there
    focusTCP()
    return
    
  elseif modkeys == (MFXlist.MOD_SHIFT | MFXlist.MOD_CTRL) then
    -- Shift+Ctrl
    -- TODO! Left click over FX with Shift+Ctrl key!
    -- Set focus to TCP so key strokes go there
    focusTCP()
    return
    
  elseif modkeys == (MFXlist.MOD_CTRL | MFXlist.MOD_ALT) then
    -- Ctr+Alt+Left click on FX, toggle offline/online
    
    local isoffline = rpr.TrackFX_GetOffline(track, index-1)
    rpr.TrackFX_SetOffline(track, index-1, not isoffline)
    -- Set focus to TCP so key strokes go there
    focusTCP()
    return
    
  elseif modkeys == MFXlist.MOD_SHIFT then 
    -- Shift+Left click on FX, toggle enable/disable
    
    local endisabled = not rpr.TrackFX_GetEnabled(track, index-1)
    rpr.TrackFX_SetEnabled(track, index-1, endisabled)
    -- Set focus to TCP so key strokes go there
    focusTCP()
    return
    
  elseif modkeys == MFXlist.MOD_CTRL then -- show/hide chain
    -- Ctrl+Left click on FX, toggle track FX Chain window with FX selected
    
    handleToggleWindow(track, index-1, 0)
    
  elseif modkeys == MFXlist.MOD_ALT then -- delete
    -- Alt+Left click on FX, delete FX
    
    rpr.TrackFX_Delete(track, index-1)
    -- Set focus to TCP so key strokes go there
    focusTCP()
    return
    
  else
    assert(nil, "handleLeftMB (2): should not get here!")
  end
  
end -- handleLeftMB
--------------------------------------------------------------------
local function withinResolution(mx, my)
  
return MFXlist.mbl_downx - MFXlist.CLICK_RESOX <= mx and  
      mx <= MFXlist.mbl_downx + MFXlist.CLICK_RESOX and 
      MFXlist.mbl_downy - MFXlist.CLICK_RESOY <= my and 
      my <= MFXlist.mbl_downy + MFXlist.CLICK_RESOY
      
end -- insideResolution
------
local mblprev, mbrprev -- global but local, used only in handleMouse

local function handleMouse()
  
  local mx, my = gfx.mouse_x, gfx.mouse_y
  
  -- if we are not inside the client rect, we can just as well return (but not quit)
  if mx < 0 or gfx.w < mx or my < 0 or gfx.h < my then -- outside of client area
    MFXlist.mouse_y = nil
    MFXlist.footer_text = MFXlist.SCRIPT_NAME
    return true -- means "do not quit"
  end    
  
  -- Are we inside the track draw area?
  if 0 <= mx and mx <= gfx.w and MFXlist.TCP_top <= my and my <= MFXlist.TCP_bot then 
    -- this only works when docked (but then... lots of stuff here only works when docked)
    MFXlist.mouse_y = my
    
  else -- either in header or in footer
    
    MFXlist.fx_hovered = nil
    MFXlist.mouse_y = nil
    MFXlist.footer_text = MFXlist.SCRIPT_NAME
    
  end
  
  local mcap = gfx.mouse_cap
  local mbldown = mcap & MFXlist.MB_LEFT
  local mbrdown = mcap & MFXlist.MB_RIGHT
  
  handleWheel(mcap, mx, my)
  
  -- left mouse button up-flank
  if mbldown ~= MFXlist.MB_LEFT and mblprev == MFXlist.MB_LEFT then
    
    mblprev = 0
    -- Is up-flank within the resoultion, then it is a click
    -- Note that if dragging is started, and then the drop is done within the resolution
    -- of mbl_down (drag start), then this is interpreted as a click. fxlist does the same
    if withinResolution(mx, my) then
      
      handleLeftMBclick(mcap, mx, my)
      
    else -- this is drag end, aka drop
      
      -- If the drop is done outside of MFXlist, then strack and ttrack == nil
      -- This also fixes dropping on header or footer, it seems
      local strack = MFXlist.drag_object and MFXlist.drag_object[1] or nil  -- source track
      local ttrack = MFXlist.track_hovered  -- target track
      if strack and ttrack then
        local sfxid = MFXlist.drag_object[2]  -- source fx id, can be nil
        local tfxid = MFXlist.fx_hovered      -- target fxid, can be nil
        
        -- Handle the drop
        if sfxid then
          if not tfxid then
            tfxid = rpr.TrackFX_GetCount(ttrack) + 1
          end
          -- If any combination of Ctrl is held down when dropping, then it is a copy
          local tomove = not (gfx.mouse_cap & MFXlist.MOD_CTRL == MFXlist.MOD_CTRL)
          rpr.TrackFX_CopyToTrack(strack, sfxid-1, ttrack, tfxid-1, tomove)
        end
      end
      
      -- Reset drag info
      MFXlist.mbl_downx, MFXlist.mbl_downy = nil, nil
      MFXlist.drag_object = nil
      MFXlist.down_object = nil
      
      focusTCP()
      
    end
  -- left mouse button down-flank, may be click or drag start
  elseif mbldown == MFXlist.MB_LEFT and mblprev ~= MFXlist.MB_LEFT then
    
    mblprev = MFXlist.MB_LEFT 
    MFXlist.mbl_downx, MFXlist.mbl_downy = mx, my
    if MFXlist.track_hovered then
      MFXlist.down_object = {MFXlist.track_hovered, MFXlist.fx_hovered}
    else -- mouse down on header or footer
      MFXlist.down_object = nil
    end
    MFXlist.count_down = 0
    
  -- down now, down previously, maybe we are dragging
  elseif mbldown == MFXlist.MB_LEFT and mblprev == MFXlist.MB_LEFT then
    
    if not withinResolution(mx, my) then
      if not MFXlist.drag_object and MFXlist.down_object then
        
        MFXlist.drag_object = MFXlist.down_object 
        MFXlist.count_down = 0 -- (try to) make sure we do not lose focus
        
        if DO_DEBUG then
          local track = MFXlist.drag_object[1]
          local fxid = MFXlist.drag_object[2]
          if not track or not fxid then
            Msg("track: "..(track and "valid" or "nil")..", fxid: "..(fxid and fxid or "nil"))
          else
            local _, tname = rpr.GetTrackName(track)
            local _, fxname = rpr.TrackFX_GetFXName(track, fxid-1, "") 
            Msg("Possible drag start: "..tname..", "..fxname)
          end
        end -- DO_DEBUG
        
      end
    end
    
  elseif mbldown ~= MFXlist.MB_LEFT and mblprev ~= MFXlist.MB_LEFT then
    
    -- is up now, was up previosly, just idling
    
  end
  
  -- right mouse button down flank?
  if mbrdown == MFXlist.MB_RIGHT and mbrprev ~= MFXlist.MB_RIGHT then
    
    mbrprev = MFXlist.MB_RIGHT
    local ret = handleMenu(mcap, mx, my) -- onRightClick()
    if ret == MFXlist.MENU_QUIT then
      gfx.quit()
      return false -- tell the defer loop to quit
    end
  -- right mouse button up flank?
  elseif mbrdown ~= MFXlist.MB_RIGHT and mbrprev == MFXlist.MB_RIGHT then
    
    mbrprev = 0
    
  end
  
  return true
  
end -- handleMouse
-----------------------------
-- Write EXSTATE info
local function exitScript()
  
  local dockstate, wx, wy, ww, wh = gfx.dock(-1, wx, wy, ww, wh)  
  local dockstr = string.format("%d", dockstate)
  rpr.SetExtState(MFXlist.SCRIPT_NAME, "dock", dockstr, true)
  
  local coordstr = string.format("%d,%d,%d,%d", wx, wy, ww, wh)
  rpr.SetExtState(MFXlist.SCRIPT_NAME, "coords", coordstr, true)
  
  rpr.SetExtState(MFXlist.SCRIPT_NAME, "version", MFXlist.SCRIPT_VERSION, true)
  
end -- exitScript
------------------------------------------------------------
-- Read EXSTATE info and set up in previous docker (if any)
local function openWindow()
  
  -- Dock state - not valid for Reaper v4 or earlier
  local dockstate = MFXlist.DOCKER_NUM
  if rpr.HasExtState(MFXlist.SCRIPT_NAME, "dock") then 
      local extstate = rpr.GetExtState(MFXlist.SCRIPT_NAME, "dock")
      dockstate = tonumber(extstate)
  end
  local docker = dockstate
  
  -- If we are docked, these coords don't really matter, but still...
  if rpr.HasExtState(MFXlist.SCRIPT_NAME, "coords") then
      local coordstr = rpr.GetExtState(MFXlist.SCRIPT_NAME, "coords")
      local x, y, w, h = coordstr:match("(%d+),(%d+),(%d+),(%d+)")
      MFXlist.WIN_X, MFXlist.WIN_Y, MFXlist.WIN_W, MFXlist.WIN_H = tonumber(x), tonumber(y), tonumber(w), tonumber(h)
  end
  
  gfx.clear = MFXlist.COLOR_EMPTYSLOT[1] * 255 + MFXlist.COLOR_EMPTYSLOT[2] * 255 * 256 + MFXlist.COLOR_EMPTYSLOT[3] * 255 * 65536
  gfx.init(MFXlist.SCRIPT_NAME, MFXlist.WIN_W, MFXlist.WIN_H, docker, MFXlist.WIN_X, MFXlist.WIN_Y)
  
end -- openWindow
------------------------------------------------ 
local function initializeScript()
  
  local hwnd, x, y, w, h = getTCPProperties() -- TCP screen coordinates
  assert(hwnd, "Could not get TCP HWND, cannot do much now, sorry")
  MFXlist.TCP_HWND = hwnd
  
  local cx, cy = gfx.screentoclient(x, y)
  MFXlist.TCP_top = cy
  MFXlist.TCP_bot = MFXlist.TCP_top + h
  
  gfx.line(0, cy, gfx.w, cy) -- line on level with TCP top (do not draw FX above this)
  gfx.line(0, cy + h, gfx.w, cy + h) -- line on level with TCP bottom (do not draw FX below this)
  
  initSWSCommands()
  
  rpr.atexit(exitScript)
  openWindow()
  
  MFXlist.MFX_HWND = rpr.JS_Window_GetFocus() -- I'm assuming we have the focus now
  -- MFXlist.MFX_HWND = rpr.JS_Window_Find(MFXlist.SCRIPT_NAME, true) -- should also work but have not tried it
  --local foregraound = rpr.JS_Window_GetForeground() -- and that we are at the foreground
  --assert(foregraound == MFXlist.MFX_HWND, "Something is amiss, either I'm not focused or I'm not foreground")

  
  MFXlist.header_text = MFXlist.SCRIPT_NAME.." "..MFXlist.SCRIPT_VERSION
  
  gfx.setfont(MFXlist.FONT_FXNAME, MFXlist.FONT_NAME1, MFXlist.FONT_SIZE1)
  gfx.setfont(MFXlist.FONT_FXBOLD, MFXlist.FONT_NAME1, MFXlist.FONT_SIZE1, MFXlist.FONT_BOLDFLAG)
  gfx.setfont(MFXlist.FONT_HEADER, MFXlist.FONT_NAME2, MFXlist.FONT_SIZE2)
  
  MFXlist.openwin_list = linkedList.new()
    
  -- Set up the header buffer for blitting -- cannot seem to get the blit of the header to work 
  gfx.dest = MFXlist.BLITBUF_HEAD
  -- according to https://forum.cockos.com/showthread.php?t=204629, this piece is missing
  gfx.setimgdim(MFXlist.BLITBUF_HEAD , -1 , -1);
  gfx.setimgdim(MFXlist.BLITBUF_HEAD, MFXlist.BLITBUF_HEADW, MFXlist.BLITBUF_HEADH)
  gfx.clear = MFXlist.COLOR_EMPTYSLOT[1] * 255 + MFXlist.COLOR_EMPTYSLOT[2] * 255 * 256 + MFXlist.COLOR_EMPTYSLOT[3] * 255 * 256 * 256 -- will this clear gfx.dest?
  gfx.set(1, 1, 1, 0.7)
  gfx.x, gfx.y = 0, 0
  gfx.setfont(MFXlist.FONT_HEADER, MFXlist.FONT_NAME1, MFXlist.FONT_HEADSIZE, MFXlist.FONT_BOLDFLAG)
  gfx.drawstr(MFXlist.SCRIPT_NAME, 5, MFXlist.BLITBUF_HEADW, MFXlist.BLITBUF_HEADH) 
  
  gfx.dest = -1
  drawTracks()
  drawHeader()
  drawFooter()
  
  focusTCP()
  
end -- initializeScript
------------------------------------------------ Here is the main loop
local function mfxlistMain()
  
  local x, y, w, h = getClientBounds(MFXlist.TCP_HWND) -- screen coords of the TCP 
  _, MFXlist.TCP_top = gfx.screentoclient(x, y) -- top y coord to draw FX at, above this only header stuff
  MFXlist.TCP_bot = MFXlist.TCP_top + h -- bottom y coord to draw FX at, below this only footer stuff
  
  rpr.PreventUIRefresh(1)

  
  drawTracks()
  drawHeader()
  drawFooter()
  
  local continue = handleMouse() 
  
  rpr.PreventUIRefresh(-1)
  -- rpr.TrackList_AdjustWindows(true)
  -- rpr.UpdateArrange()
  
  -- Check if we are to quit or not
  if gfx.getchar() < 0 or not continue then 
    gfx.quit()
    return
  end

  manageOpenWindows()
  -- manageFocus()

  rpr.defer(mfxlistMain)
  
end -- mfxlistMain
------------------------------------------------ It all starts here, really

-- Adding preset awareness here
local function Init()
  initializeScript()
  mfxlistMain() -- run main loop
end

if not preset_file_init then 
  Init()
end

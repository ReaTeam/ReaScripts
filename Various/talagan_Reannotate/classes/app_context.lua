-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This file is part of Reannotate

local LaunchContext         = require "classes/launch_context"
local ArrangeViewWatcher    = require "classes/arrange_view_watcher"
local ImGui                 = require "ext/imgui"
local reaper_ext            = require "modules/reaper_ext"
local D                     = require "modules/defines"

local AppContext = {}
AppContext.__index = AppContext

function AppContext:new()
  local instance = {}
  setmetatable(instance, self)
  instance:_initialize()
  return instance
end

function AppContext:findMCPHwnds()

  local mixerHwnd = reaper.JS_Window_Find("Mixer",true)
  local next_child = mixerHwnd

  local master_mcp_hwnd = nil
  local other_mcp_hwnd = nil
  while next_child do
    next_child = reaper.JS_Window_FindEx(mixerHwnd, next_child, "REAPERMCPDisplay", "")
    if next_child then
      local title = reaper.JS_Window_GetTitle(next_child)
      if title == "master" then
        master_mcp_hwnd = next_child
      else
        other_mcp_hwnd = next_child
      end
    end
  end

  return master_mcp_hwnd, other_mcp_hwnd, mixerHwnd
end

function AppContext:getImage(image_name)
  self.images = self.images or {}
  local images = self.images

  if (not images[image_name]) or (not ImGui.ValidatePtr(images[image_name], 'ImGui_Image*')) then
    local bin = require("images/" .. image_name)
    images[image_name] = ImGui.CreateImageFromMem(bin)
    -- Prevent the GC from freeing this image
    ImGui.Attach(self.imgui_ctx, images[image_name])
  end

  return images[image_name]
end

function AppContext:findMainToolbarHwnd(main_hwnd, time_ruler_hwnd, tcp_hwnd)
  -- Some people don't use the main toolbar as main toolbar
  local hwnd = reaper.JS_Window_Find('Main toolbar',true)
  if not hwnd then
    -- Use dirty heuristic : find the window that aligns with the time ruler and the TCP
    local _, tr_l,  tr_t,   tr_r,   tr_b    = reaper.JS_Window_GetRect(time_ruler_hwnd)
    local _, tcp_l, tcp_t,  tcp_r,  tcp_b   = reaper.JS_Window_GetRect(tcp_hwnd)
    local _, l = reaper.JS_Window_ListAllChild(main_hwnd)
    for token in string.gmatch(l, "[^,]+") do
---@diagnostic disable-next-line: param-type-mismatch
      local subhwnd = reaper.JS_Window_HandleFromAddress(token)
      if subhwnd then
        local _, a_l, a_t, a_r, a_b = reaper.JS_Window_GetRect(subhwnd)

        if a_l == tcp_l and a_r == tcp_r and math.abs(a_t - tr_t) <= 2 and math.abs(a_b - tr_b) <= 10 then
          hwnd = subhwnd
          break
        end
      end
    end
  end
  return hwnd
end


function AppContext:_initialize()
  self.launch_context             = LaunchContext:new()
  self.arrange_view_watcher       = ArrangeViewWatcher:new()

  -- Main view
  self.mv                         = { hwnd=reaper.GetMainHwnd() }
  -- Arrange view
  self.av                         = { hwnd=reaper.JS_Window_FindChildByID(self.mv.hwnd, 1000) }

  self.transport                  = { hwnd=reaper.JS_Window_FindChild(reaper.GetMainHwnd(), "Transport", true) }
  -- TCP view
  self.tcp                        = { hwnd=reaper.JS_Window_FindEx(reaper.GetMainHwnd(), reaper.GetMainHwnd(), "REAPERTCPDisplay", "") }
  -- Time Ruler
  self.time_ruler                 = { hwnd=reaper.JS_Window_FindChildByID(self.mv.hwnd, 1005) }
  -- Main toolbar
  self.main_toolbar               = { hwnd=self:findMainToolbarHwnd(self.mv.hwnd, self.time_ruler.hwnd, self.tcp.hwnd)}

  local master_mcp_hwnd, other_mcp_hwnd, mcp_window = self:findMCPHwnds()

  -- MCP, master part
  self.mcp_master                 = { hwnd=master_mcp_hwnd }
  -- MCP, other part
  self.mcp_other                  = { hwnd=other_mcp_hwnd }
  -- MCP, wrapper window
  self.mcp_window                 = { hwnd=mcp_window, is_top = (reaper.JS_Window_FindTop("Mixer", true) ~= nil) }

  self.imgui_ctx                  = ImGui.CreateContext("Reannotate")
  self.dpi_scale                  = ImGui.GetWindowDpiScale(self.imgui_ctx)

  self.cursor_func                = ImGui.CreateFunctionFromEEL([[
      (WANTED_CURSOR >= 0)?(
        CursorPos = WANTED_CURSOR;
        WANTED_CURSOR = -1;
      );
    ]])

  self.arial_font         = ImGui.CreateFont("Arial", ImGui.FontFlags_None)
  self.arial_font_italic  = ImGui.CreateFont("Arial", ImGui.FontFlags_Italic | ImGui.FontFlags_Bold)

  ImGui.Attach(self.imgui_ctx, self.cursor_func)
  ImGui.Attach(self.imgui_ctx, self.arial_font)
  ImGui.Attach(self.imgui_ctx, self.arial_font_italic)

  self.enabled_category_filters = {}
  for i=1, D.MAX_SLOTS do
    self.enabled_category_filters[i] = true
  end

  AppContext.__singleton = self
end

-- Return absolute coordinates, normalized by ImGui PointConvertNative.
-- These coordinates are meant to be used with drawlists essentially.
-- Scrollbar corrections may be passed.
-- DPI is applied if there's scaling under windows
function AppContext:retrieveCoordinates(sub, scrollbar_w, scrollbar_h)
  if not sub.hwnd then return end
  local _, x, y, x2, y2       = reaper.JS_Window_GetRect(sub.hwnd)

  sub.x, sub.y                = ImGui.PointConvertNative(self.imgui_ctx, x,  y, false)
  local xx2, yy2              = ImGui.PointConvertNative(self.imgui_ctx, x2, y2, false)

  sub.w = math.abs(xx2 - sub.x)
  sub.h = math.abs(yy2 - sub.y)

  sub.dpi = sub.w / (x2 - x)

  if scrollbar_w then
    local w  = math.abs(x2 - x)
    local hr = (w - scrollbar_w) / w
    sub.w = math.floor(sub.w * hr + 0.5)
  end

  if scrollbar_h then
    local h = math.abs(y2 - y)
    local hr = (h - scrollbar_h) / h
    sub.h = math.floor(sub.h * hr + 0.5)
  end

end

function AppContext:retrievePinnedTcpHeight()
  -- Loop on all tracks
  local track_count = reaper.CountTracks(0)

  local bypos   = nil
  local btrack  = nil

  -- Among the visible pinned tracks, find the bottomost
  for i = -1, track_count - 1 do
    local track = (i==-1) and reaper.GetMasterTrack(0) or reaper.GetTrack(0, i)

    if reaper_ext.IsTrackPinned(track) and reaper_ext.IsTrackVisibleInTcp(track, i == -1) then
      local typos = reaper.GetMediaTrackInfo_Value(track, "I_TCPY")
      if bypos == nil or typos > bypos then
        bypos   = typos
        btrack  = track
      end
    end
  end

  if not btrack then return 0 end

  local ph  = bypos + reaper.GetMediaTrackInfo_Value(btrack, "I_TCPH")

  local ei = 0
  while true do
    local envelope = reaper.GetTrackEnvelope(btrack, ei)
    if not envelope then break end

    if reaper_ext.IsEnvelopeVisible(envelope) then
      local env_height  = reaper.GetEnvelopeInfo_Value(envelope, "I_TCPH")
      ph = ph + env_height
    end

    ei = ei + 1
  end

  if ph > 0 then
    -- Add extra space for resizing grip
    ph = ph + 10
  end

  return ph
end

function AppContext:updateWindowLayouts()

  self:retrieveCoordinates(self.av, 16, 16)
  self:retrieveCoordinates(self.mv)
  self:retrieveCoordinates(self.tcp)
  self:retrieveCoordinates(self.mcp_master)
  self:retrieveCoordinates(self.mcp_other)
  self:retrieveCoordinates(self.main_toolbar)
  self:retrieveCoordinates(self.time_ruler)
  self:retrieveCoordinates(self.mcp_window)
  self:retrieveCoordinates(self.transport)

  self.av.pinned_height = self:retrievePinnedTcpHeight()

  self.av.start_time, self.av.end_time  = reaper.GetSet_ArrangeView2(0, false, 0, 0)
end

function AppContext:tick()
  self.frame_time = reaper.time_precise()
end

function AppContext:flog(txt)
  --reaper.ShowConsoleMsg("[" .. string.format("%.3f",self.frame_time) .. "] " .. txt .. "\n")
end

function AppContext.instance()
  return AppContext.__singleton
end

return AppContext

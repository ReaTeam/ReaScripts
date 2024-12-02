-- @noindex
-- @author Ben 'Talagan' Babut
-- @license MIT
-- @description This is part of Talagan Docking Tools

local function CheckReapack(func_name, api_name, search_string)
  if not reaper.APIExists(func_name) then
    local answer = reaper.MB( api_name .. " is required and you need to install it.\z
      Right-click the entry in the next window and choose to install.",
      api_name .. " not installed", 0 )
    reaper.ReaPack_BrowsePackages( search_string )
    return false
  end
  return true
end

local function CheckDependencies()
  if not CheckReapack("JS_ReaScriptAPI_Version",   "JS_ReaScriptAPI",  "js_ReaScriptAPI")     then return false end

  return true
end


------------------------

DOCK_BOTTOM   = 0
DOCK_FLOATING = 4

local function setTimeout(callback, timeout)
  local wur = timeout
  local wut = reaper.time_precise()

  function _wait_ready()

    if reaper.time_precise() - wut < wur then
      reaper.defer(_wait_ready)
      return
    end

    callback()
  end

  reaper.defer(_wait_ready)
end

-- Thanks to @edgemeal for this technique !
local function JS_LDrag(hwnd, x_start,x_end, y_start,y_end)
  reaper.JS_WindowMessage_Send(hwnd, "WM_LBUTTONDOWN", 1, 0, x_start, y_start)
  reaper.JS_WindowMessage_Send(hwnd, "WM_LBUTTONUP",   0, 0, x_end,   y_end)
end

local function JS_Window_GetTopParent(hwnd)
  local p = hwnd; local p2 = hwnd;
  while p2 do
    p  = p2;
    p2 = reaper.JS_Window_GetParent(p)
  end
  return p
end

local function JS_Window_GetBounds(hwnd)
  local _, left, top, right, bottom = reaper.JS_Window_GetClientRect( hwnd )

  local os = reaper.GetOS()
  h = top - bottom

  -- Under windows, vertical coordinates are flipped !
  if os == "Win32" or os == "Win64" then
    h = bottom - top
  end

  return {hwnd = hwnd, l = left, t = top, r = right, b = bottom, w = (right-left), h = h }
end

local function JS_Window_Debug(hwnd)
  local bounds = JS_Window_GetBounds(hwnd);
  reaper.ShowConsoleMsg("Title : " .. reaper.JS_Window_GetTitle(hwnd) .. "\n");
  reaper.ShowConsoleMsg("Width : " .. bounds.w .. "\n");
  reaper.ShowConsoleMsg("Height : " .. bounds.h .. "\n");
  reaper.ShowConsoleMsg("T,R,B,L : " .. bounds.t .. ", " .. bounds.r .. ", " .. bounds.b .. ", " .. bounds.l .. "\n");
end

local function findDockerThatContainsWindow(hwnd_to_find)
  local c, l = reaper.JS_Window_ListFind("REAPER_dock",true);
  for token in string.gmatch(l, "[^,]+") do
    local hwnd = reaper.JS_Window_HandleFromAddress(token);
    if reaper.JS_Window_IsChild(hwnd, hwnd_to_find) then
      return JS_Window_GetBounds(hwnd);
    end
  end
  return nil;
end

local function findBottommostDock()
  local lowest = nil
  local blowest = nil
  local c, l = reaper.JS_Window_ListFind("REAPER_dock",true);
  for token in string.gmatch(l, "[^,]+") do
    local hwnd    = reaper.JS_Window_HandleFromAddress(token);
    local idx,_   = reaper.DockIsChildOfDock(hwnd)
    local pos     = reaper.DockGetPosition(idx)

    -- Don't try to do something on docks that are not docked at the bottom
    if pos == DOCK_BOTTOM then
      local bounds  = JS_Window_GetBounds(hwnd)

      local bot = bounds.b
      if os == "Win32" or os == "Win64" then
        -- Under windows we reverse the bottom bound to have the same ordering logic as on MacOS/Linux
        -- (This will be negative but we don't care, we just want to know what's the bottommost dock)
        bot = - bot
      end

      if not lowest or bot < blowest then
        lowest  = bounds
        blowest = bot
      end
    end

  end

  if lowest then
    return lowest
  end

  return nil
end

local function findTopWindowThatContainsWindow(hwnd_to_find)
  local c, l = reaper.JS_Window_ListAllTop();
  for token in string.gmatch(l, "[^,]+") do
    local hwnd = reaper.JS_Window_HandleFromAddress(token);
    if reaper.JS_Window_IsChild(hwnd, hwnd_to_find) then
      return JS_Window_GetBounds(hwnd);
    end
  end
  return nil;
end

local function deferredDebugPostCheck()
  setTimeout(function()
    local redock = JS_Window_GetBounds(dock.hwnd);
    if redock.h ~= height then
      reaper.ShowConsoleMsg("Requested height : " .. height .. " , but got height " .. redock.h .. "\n")
    end
  end, 1.0);
end

local function safeHeight(dock, height)
  -- We need to clamp the requested height so that what we ask
  -- will match what's REAPER will be able to do
  -- else, at the end of our action subsequent actions will not work on a valid height
  -- (they will run on what we have set, but a few cycles later, REAPER
  -- will repack the UI, making those adjusments wrong)

  local sheight = height

  local topw       = JS_Window_GetTopParent(dock.hwnd);
  local topwbounds = JS_Window_GetBounds(topw);

  -- JS_Window_Debug(topw);

  local maxheight  = topwbounds.h - 191;
  local minheight  = math.min(320, topwbounds.h - 174);

  -- reaper.ShowConsoleMsg(height .. "\n");
  -- reaper.ShowConsoleMsg(maxheight .. "\n");
  -- reaper.ShowConsoleMsg(minheight .. "\n");

  if sheight > maxheight then
   sheight = maxheight;
  end

  if sheight < minheight then
   sheight = minheight;
  end

  -- reaper.ShowConsoleMsg("Safe height : " .. sheight)

  return sheight
end

local function resizeDock(dock, height)

  -- height = safeHeight(dock, height)
  -- reaper.ShowConsoleMsg(height .. "\n");

  -- Remember current focus
  local focused = reaper.JS_Window_GetFocus();

  -- Drag the resize grip... thanks @edgemeal for the technique !
  JS_LDrag(dock.hwnd, 0, 0, 0, dock.h - height)

  -- Restore focus
  reaper.JS_Window_SetFocus(focused);

  -- The next call helps to check if what we requested is what we got
  -- use it in debug mode only
  -- deferredDebugPostCheck();
end

-- Exports

local function resizeMidiDock(height)
  local me   = reaper.MIDIEditor_GetActive(); -- Exists because we found the parent docket
  if not me then return end

  local dock = findDockerThatContainsWindow(me);
  if not dock then return end

  resizeDock(dock, height);
end

local function resizeBottommostDock(height)
  local dock = findBottommostDock()
  if not dock then return end
  resizeDock(dock, height)
end

local function maximizeMidiDock() resizeMidiDock(10000) end
local function minimizeMidiDock() resizeMidiDock(0)     end

local function maximizeBottommostDock()  resizeBottommostDock(10000)  end
local function minimizeBottommostDock()  resizeBottommostDock(0)      end


return {
  CheckDependencies=CheckDependencies,
  setTimeout=setTimeout,

  resizeMidiDock=resizeMidiDock,
  maximizeMidiDock=maximizeMidiDock,
  minimizeMidiDock=minimizeMidiDock,

  resizeBottommostDock=resizeBottommostDock,
  maximizeBottommostDock=maximizeBottommostDock,
  minimizeBottommostDock=minimizeBottommostDock,
}


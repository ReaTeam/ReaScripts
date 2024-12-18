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


local DockableComponents = {
  "Mixer",
  "Project Bay",
  "Media Explorer",
  "Track Manager",
  "Track Group Manager",
  "Take Properties",
  "Undo History",
  "Envelope Manager",
  "Routing Matrix",
  "Track Grouping Matrix",
  "Track Wiring Diagram",
  "Region Render Matrix",
  "FX Browser",
  "Navigator",
  "Big Clock",
  "Performance Meter"
}

local DOCK_BOTTOM   = 0
local DOCK_LEFT     = 1
local DOCK_TOP      = 2
local DOCK_RIGHT    = 3

local DOCK_FLOATING = 4

-- Thanks to @Edgemeal for this technique !
local function JS_LDrag(hwnd, x_start,x_end, y_start,y_end)
  reaper.JS_WindowMessage_Send(hwnd, "WM_LBUTTONDOWN", 1, 0, x_start, y_start)
  reaper.JS_WindowMessage_Send(hwnd, "WM_LBUTTONUP",   0, 0, x_end,   y_end)
end

local function JS_Window_GetBounds(hwnd)
  local _, left, top, right, bottom = reaper.JS_Window_GetClientRect( hwnd )

  local os  = reaper.GetOS()
  local h   = top - bottom

  -- Under windows, vertical coordinates are flipped !
  if os == "Win32" or os == "Win64" then
    h = bottom - top
  end

  return {hwnd = hwnd, l = left, t = top, r = right, b = bottom, w = (right-left), h = h }
end

local function getHwndDock(hwnd)
  local p     = nil
  local dock  = nil

  p           = reaper.JS_Window_GetParent(hwnd)
  while p do
    if reaper.JS_Window_GetTitle(p) == "REAPER_dock" then
      dock  = p
      p     = nil
    else
      p = reaper.JS_Window_GetParent(p);
    end
  end
  return dock
end

local function dockInfo(dockhwnd)
  local did, floating   = reaper.DockIsChildOfDock(dockhwnd)
  local pos             = reaper.DockGetPosition(did)
  local bounds          = JS_Window_GetBounds(dockhwnd)

  return {
    hwnd=dockhwnd,
    id=did,
    floating=floating,
    pos=pos,
    bounds=bounds
  }
end

local function findDockThatContainsWindow(hwnd)
  local dockhwnd            = getHwndDock(hwnd)
  if not dockhwnd then return nil end

  return dockInfo(dockhwnd)
end

local function findDockThatContainsWindowWithTitle(title)
  local hwnd            = reaper.JS_Window_Find(title,true)
  if not hwnd then return nil end

  return findDockThatContainsWindow(hwnd)
end

local function findDockThatContainsActiveMidiEditor()
  local me   = reaper.MIDIEditor_GetActive() -- Exists because we found the parent docket
  if not me then return end

  return findDockThatContainsWindow(me)
end

local function findDirmostDock(wanted_dir)
  local extrema_dock  = nil
  local extrema_val   = nil

  local comparator = function(cur, ext)
    if wanted_dir == DOCK_BOTTOM then return cur < ext end
    if wanted_dir == DOCK_RIGHT  then return cur < ext end
    if wanted_dir == DOCK_TOP    then return cur > ext end
    if wanted_dir == DOCK_LEFT   then return cur > ext end
  end

  local ext_coord = function(bnd)
    local coord = nil

    if wanted_dir == DOCK_BOTTOM then coord = bnd.b end
    if wanted_dir == DOCK_RIGHT  then coord = bnd.r end
    if wanted_dir == DOCK_TOP    then coord = bnd.t end
    if wanted_dir == DOCK_LEFT   then coord = bnd.l end

    if (os == "Win32" or os == "Win64") and (wanted_dir == DOCK_TOP or wanted_dir == DOCK_BOTTOM ) then
      -- Under windows we reverse the bottom bound to have the same ordering logic as on MacOS/Linux
      -- (This will be negative but we don't care, we just want to know what's the bottommost dock)
      coord = - coord
    end

    return coord
  end

  -- Enumerate all docks
  local c, l = reaper.JS_Window_ListFind("REAPER_dock",true);
  for token in string.gmatch(l, "[^,]+") do
    local addr    = tonumber(token) or 0
    local hwnd    = reaper.JS_Window_HandleFromAddress(addr);
    local dock    = dockInfo(hwnd)

    -- Don't try to do something on docks that are not docked at the bottom
    if dock.pos == wanted_dir and reaper.JS_Window_IsVisible(dock.hwnd) then
      local coord   = ext_coord(dock.bounds)

      if not extrema_dock or comparator(coord, extrema_val) then
        extrema_dock  = dock
        extrema_val   = coord
      end
    end

  end

  -- May be nil
  return extrema_dock
end

local function baseSize(dock)
  if dock.pos == DOCK_BOTTOM or dock.pos == DOCK_TOP then
    return dock.bounds.h
  elseif dock.pos == DOCK_LEFT or dock.pos == DOCK_RIGHT then
    return dock.bounds.w
  end
  return nil
end

local function resolveWantedSize(dock, sizes)
  local size = nil
  if dock.pos == DOCK_BOTTOM then
    size = sizes.b
  elseif dock.pos == DOCK_TOP then
    size = sizes.t
  elseif dock.pos == DOCK_LEFT then
    size = sizes.l
  elseif dock.pos == DOCK_RIGHT then
    size = sizes.r
  end

  if size == 'min'  then return 0      end
  if size == 'max'  then return 10000  end

  return tonumber(size)
end

local function resizeDock(dock, sizes)

  aaa_sizes = sizes
  if not dock then return end

  if type(sizes) == "table" then
    -- Ok
  elseif type(sizes) == "number" then
    local size = sizes
    sizes = {b=size,t=size,r=size,l=size}
  elseif type(sizes) == "string" then
    local size = sizes
    sizes = {b=size,t=size,r=size,l=size}
  else
    error("Type mismatch for argument 'sizes'. Should be a table, a number or a keyword.")
  end

  -- Dock should be docked
  if not (dock.pos == DOCK_BOTTOM or dock.pos == DOCK_TOP or dock.pos == DOCK_LEFT or dock.pos == DOCK_RIGHT) then return nil end

  local base_size   = baseSize(dock)
  local wanted_size = resolveWantedSize(dock, sizes)

  if not base_size or not wanted_size then return nil end

  -- Remember current focus
  local focused     = reaper.JS_Window_GetFocus();

  local delta_size = base_size - wanted_size

  -- Drag the resize grip... thanks @Edgemeal for the technique !
  if dock.pos == DOCK_BOTTOM then
    JS_LDrag(dock.hwnd, 0, 0, 0, delta_size)
  elseif dock.pos == DOCK_TOP then
    JS_LDrag(dock.hwnd, 0, 0, base_size, base_size - delta_size)
  elseif dock.pos == DOCK_LEFT then
    JS_LDrag(dock.hwnd, base_size, base_size - delta_size, 0, 0)
  elseif dock.pos == DOCK_RIGHT then
    JS_LDrag(dock.hwnd, 0, delta_size, 0, 0)
  end

  -- Restore focus
  reaper.JS_Window_SetFocus(focused)
end

local function resizeMidiDock(sizes)
  local dock = findDockThatContainsActiveMidiEditor()

  resizeDock(dock, sizes);
end

local function resizeDirmostDock(findfunc, sizes)
  local dock = findfunc()

  resizeDock(dock, sizes)
end


local function maximizeMidiDock() resizeMidiDock('max') end
local function minimizeMidiDock() resizeMidiDock('min')     end

local function findBottommostDock() return findDirmostDock(DOCK_BOTTOM) end
local function findLeftmostDock()   return findDirmostDock(DOCK_LEFT)   end
local function findRightmostDock()  return findDirmostDock(DOCK_RIGHT)  end
local function findTopmostDock()    return findDirmostDock(DOCK_TOP)    end

local function resizeBottommostDock(sizes)  resizeDirmostDock(findBottommostDock, sizes) end
local function maximizeBottommostDock()     resizeBottommostDock('max')   end
local function minimizeBottommostDock()     resizeBottommostDock('min')   end

local function resizeLeftmostDock(sizes)    resizeDirmostDock(findLeftmostDock, sizes) end
local function maximizeLeftmostDock()       resizeLeftmostDock('max')     end
local function minimizeLeftmmostDock()      resizeLeftmostDock('min')     end

local function resizeRightmostDock(sizes)   resizeDirmostDock(findRightmostDock, sizes) end
local function maximizeRightmostDock()      resizeRightmostDock('max')    end
local function minimizeRightmmostDock()     resizeRightmostDock('min')    end

local function resizeTopmostDock(sizes)     resizeDirmostDock(findTopmostDock, sizes) end
local function maximizeTopmostDock()        resizeTopmostDock('max')      end
local function minimizeTopmmostDock()       resizeTopmostDock('min')      end

-- All resize functions accept the following values for 'sizes' :

--   * a table  : {t=tsize, l=lsize, r=rsize, b=bsize}, the size will be applied conditionally.
--   * a number : (will be applied to all docking positions)
--   * a string : (will be applied to all docking positions)

--  Each individual size can be a number or a keyword (only 'min', 'max' are supported)

local function splitString(str, sep)
  local result = {}

  for v in string.gmatch(str..sep, '([^'.. sep ..']*)' .. sep) do
    table.insert(result, v)
  end

  return result
end

local function extractSizesFromAction(size_str)
  local tokens = splitString(size_str, ',')

  if #tokens == 1 then
    return {t=tokens[1], r=tokens[1], b=tokens[1], l=tokens[1] }
  elseif #tokens == 4 then
    return {t=tokens[1], r=tokens[2], b=tokens[3], l=tokens[4] }
  else
    error("In action name size string : '" .. size_str .. "'. should pass exactly 1 or 4 parameters separated by comas" )
  end
end

local function findDirmostDockFromString(dir)
  if dir == 'left' then
    return findLeftmostDock()
  elseif dir == 'right' then
    return findRightmostDock()
  elseif dir == 'top' then
    return findTopmostDock()
  elseif dir == 'bottom' then
    return findBottommostDock()
  else
    error("In action name, dirmost dock '" .. dir .. "' does not exist.")
  end
end

local function findContainerDockFromString(dstr)
  if dstr == 'active midi editor' then
    return findDockThatContainsActiveMidiEditor()
  elseif dstr then
    for _, s in ipairs(DockableComponents) do
      if string.lower(s) == dstr then
        return findDockThatContainsWindowWithTitle(s)
      end
    end
    return nil
  end
end

local function resizeDockFromActionName(filename)

  local s, e, dir, cnt, sizes

  local rxdir       = "talagan_Set (%a+)most dock size %((.+)%)%.lua"
  s, e, dir, sizes  = string.find(filename, rxdir)
  if s then
    local dock      = findDirmostDockFromString(string.lower(dir))
    sizes           = extractSizesFromAction(sizes)
    resizeDock(dock, sizes)
    return
  end

  -- Backward compatibility with the first version
  local rxdirh       = "talagan_Set (%a+)most dock height %((.+)%)%.lua"
  s, e, dir, sizes  = string.find(filename, rxdirh)
  if s then
    local dock      = findDirmostDockFromString(string.lower(dir))
    sizes           = extractSizesFromAction(sizes)
    resizeDock(dock, {b=sizes.b})
    return
  end

  local rxdirmin    = "talagan_Minimize (%a+)most dock.lua"
  s, e, dir         = string.find(filename, rxdirmin)
  if s then
    local dock      = findDirmostDockFromString(string.lower(dir))
    resizeDock(dock, 'min')
    return
  end

  local rxdirmax    = "talagan_Maximize (%a+)most dock.lua"
  s, e, dir         = string.find(filename, rxdirmax)
  if s then
    local dock      = findDirmostDockFromString(string.lower(dir))
    resizeDock(dock, 'max')
    return
  end

  -----------

  local rx          = "talagan_Set dock containing (.+) size %((.+)%)%.lua"
  s, e, cnt, sizes  = string.find(filename, rx)
  if s then
    local dock      = findContainerDockFromString(string.lower(cnt))
    sizes           = extractSizesFromAction(sizes)
    resizeDock(dock, sizes)
    return
  end

  -- Backward compatibility with the first version
  local rxh         = "talagan_Set dock containing (.+) height %((.+)%)%.lua"
  s, e, cnt, sizes  = string.find(filename, rxh)
  if s then
    local dock      = findContainerDockFromString(string.lower(cnt))
    sizes           = extractSizesFromAction(sizes)
    resizeDock(dock, {b=sizes.b})
    return
  end

  local rxmin       = "talagan_Minimize dock containing (.*).lua"
  s, e, cnt         = string.find(filename, rxmin)
  if s then
    local dock      = findContainerDockFromString(string.lower(cnt))
    resizeDock(dock, 'min')
    return
  end

  local rxmax       = "talagan_Maximize dock containing (.*).lua"
  s, e, cnt         = string.find(filename, rxmax)
  if s then
    local dock      = findContainerDockFromString(string.lower(cnt))
    resizeDock(dock, 'max')
    return
  end

end


return {
  CheckDependencies=CheckDependencies,

  -- LIB : Finders

  findDockThatContainsWindowWithTitle=findDockThatContainsWindowWithTitle,
  findDockThatContainsWindow=findDockThatContainsWindow,
  findDockThatContainsActiveMidiEditor=findDockThatContainsActiveMidiEditor,

  findBottommostDock=findBottommostDock,
  findLeftmostDock=findLeftmostDock,
  findRightmostDock=findRightmostDock,
  findTopmostDock=findTopmostDock,

  -- LIB : Resizers

  resizeDock=resizeDock,

  resizeMidiDock=resizeMidiDock,
  maximizeMidiDock=maximizeMidiDock,
  minimizeMidiDock=minimizeMidiDock,

  resizeBottommostDock=resizeBottommostDock,
  maximizeBottommostDock=maximizeBottommostDock,
  minimizeBottommostDock=minimizeBottommostDock,

  resizeLeftmostDock=resizeLeftmostDock,
  maximizeLeftmostDock=maximizeLeftmostDock,
  minimizeLeftmmostDock=minimizeLeftmmostDock,

  resizeTopmostDock=resizeTopmostDock,
  maximizeTopmostDock=maximizeTopmostDock,
  minimizeTopmmostDock=minimizeTopmmostDock,

  resizeRightmostDock=resizeRightmostDock,
  maximizeRightmostDock=maximizeRightmostDock,
  minimizeRightmmostDock=minimizeRightmmostDock,

  -- To use with action names

  resizeDockFromActionName=resizeDockFromActionName,
}


--[[
    Description: CC Ryder
    Version: 1.0.2
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Fix: Detecting the number of slots was using the wrong .ini key
    Links:
        Forum Thread https://forum.cockos.com/showthread.php?p=2141684
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Provides a graphical interface for accessing the "SWS/S&M: Save/Restore
        displayed CC lanes..." actions.

        Requires the SWS extension.
    Donation: https://www.paypal.me/Lokasenna
    Provides:
        Lokasenna_CC Ryder/*.png
]]--


-- luacheck: globals GUI reaper gfx missing_lib

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB(
      "Couldn't load the Lokasenna_GUI library. "..
        "Please run 'Set Lokasenna_GUI v2 library path.lua' "..
        "in the Lokasenna_GUI folder.",
      "Whoops!",
      0
    )
    return
end
loadfile(lib_path .. "Core.lua")()

if not GUI.SWS_exists then
  reaper.MB("This script requires the SWS extension for Reaper.", "Whoops!", 0)
  return
end


GUI.req("Classes/Class - Button.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

local images = {}
local function loadImage(image)
  if images[image] then return images[image] end

  local buffer = GUI.GetBuffer()
  local ret = gfx.loadimg(buffer, GUI.script_path.."/Lokasenna_CC Ryder/"..image..".png")

  if ret > -1 then
    images[image] = buffer
    return buffer
  else
    GUI.FreeBuffer(buffer)
  end

  return false
end


local IButton = GUI.Element:new()
GUI.IButton = IButton

IButton.__index = IButton

function IButton:new(name, props)
  local button = props

  button.name = name
  button.type = "IButton"

  button.state = 0

  GUI.redraw_z[button.z] = true

  return setmetatable(button, self)
end

function IButton:init()
  self.imageBuffer = loadImage(self.image)
  if not self.imageBuffer then error("IButton: The specified image was not found") end
end

function IButton:draw()
  gfx.mode = 0
  gfx.blit(self.imageBuffer, 1, 0, self.state * self.w, 0, self.w, self.h, self.x, self.y, self.w, self.h)
end

function IButton:onupdate()
  if self.state > 0 and not GUI.IsInside(self, GUI.mouse.x, GUI.mouse.y) then
    self.state = 0
    self:redraw()
  end

end

function IButton:onmouseover()
  self.state = 1
  self:redraw()
end

IButton.redraw = GUI.Button.redraw
function IButton:onmousedown()
  self.state = 2
  self:redraw()
end

IButton.onmouseup = GUI.Button.onmouseup
IButton.ondoubleclick = GUI.Button.ondoubleclick




------------------------------------
-------- Logic ---------------------
------------------------------------


local saveMode = false
local numSlots = (function()
  local path = reaper.GetResourcePath() .. "/S&M.ini"
  local _, slotsA = reaper.BR_Win32_GetPrivateProfileString("NbOfActions", "S&M_SAVECCLANES_ME", "", path)
  local _, slotsB = reaper.BR_Win32_GetPrivateProfileString("NbOfActions", "S&M_SETCCLANES_ME", "", path)

  slotsA = tonumber(slotsA:match("^(%d+)")) or 8
  slotsB = tonumber(slotsB:match("^(%d+)")) or 8
  return math.max(slotsA, slotsB)
end)()

local function assignImages()
  local modeStr = (saveMode and "save_" or "restore_")

  for i = 1, numSlots do
    local elm = GUI.elms["btn_"..i]
    elm.image = modeStr..i
  end

  local elm = GUI.elms["btn_mode"]
  elm.image = modeStr.."label"
end

local function loadImages()
  for i = 1, numSlots do
    local elm = GUI.elms["btn_"..i]
    elm:init()
    elm:redraw()
  end

  local elm = GUI.elms["btn_mode"]
  elm:init()
  elm:redraw()
end

local function setMode(mode)
  if mode == nil then
    saveMode = not saveMode
  else
    saveMode = mode
  end

  assignImages()
  loadImages()
end

local function saveCCLanes(slot)
  local editor = reaper.MIDIEditor_GetActive()
  if not editor then return end

  -- _S&M_SAVECCLANES_ME1
  local id = reaper.NamedCommandLookup("_S&M_SAVECCLANES_ME"..slot)
  reaper.MIDIEditor_OnCommand(editor, id)

  setMode(false)
end

local function restoreCCLanes(slot)
  local editor = reaper.MIDIEditor_GetActive()
  if not editor then return end

  -- _S&M_SETCCLANES_ME1
  local id = reaper.NamedCommandLookup("_S&M_SETCCLANES_ME"..slot)
  reaper.MIDIEditor_OnCommand(editor, id)
end


local function handleLabelClick()
  setMode()
end

local function handleClick(slot)
  if saveMode then
    saveCCLanes(slot)
  else
    reaper.Undo_BeginBlock()
    restoreCCLanes(slot)
    reaper.Undo_EndBlock("Lokasenna_CC Ryder", -1)
  end
end




------------------------------------
-------- GUI Layout ----------------
------------------------------------


local btnWidth = 21
local btnHeight = 17

local labelRef = {
  x = 0,
  y = 0,
  w = 22,
  h = btnHeight,
}

local btnRef = {
  x = function(i) return labelRef.w + btnWidth * i end,
  y = 0,
  w = btnWidth,
  h = btnHeight,
}

GUI.name = "CC Ryder"
GUI.x = 0
GUI.y = 0
GUI.w = btnRef.x(numSlots)
GUI.h = 17
GUI.anchor, GUI.corner = "mouse", "C"
GUI.version = nil

local processedButtons = {}
for i = 1, numSlots do
  local elm = {}
  elm.type = "IButton"
  elm.z = 1
  elm.x = btnRef.x(i - 1)
  elm.y = btnRef.y
  elm.w = btnRef.w
  elm.h = btnRef.h
  elm.func = handleClick
  elm.params = {i}
  processedButtons["btn_"..i] = elm
end
processedButtons["btn_mode"] = {
  type = "IButton",
  z = 1,
  x = labelRef.x,
  y = labelRef.y,
  w = labelRef.w,
  h = labelRef.h,
  func = handleLabelClick,
  params = {},
}

GUI.CreateElms(processedButtons)

assignImages()

local w, h = GUI.w, GUI.h
GUI.load_window_state("Lokasenna_CC Ryder")
GUI.w, GUI.h = w, h -- These still need to be dynamic in case the user edited the # of slots

GUI.exit = function()
  GUI.save_window_state("Lokasenna_CC Ryder")
end

GUI.Init()

if (reaper.JS_Window_Find) then
  local hwnd = reaper.JS_Window_Find(GUI.name, true)
  reaper.JS_Window_SetZOrder(hwnd, "TOPMOST", hwnd)
end

GUI.Main()

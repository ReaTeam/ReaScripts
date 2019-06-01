--[[
    Description: Pedal Steel
    Version: 1.0.2
    Author: Lokasenna
    Donation: https://paypal.me/Lokasenna
    Changelog:
        Add: Link to forum thread
    Links:
        Forum Thread https://forum.cockos.com/showthread.php?p=2141684    
        Lokasenna's Website http://forum.cockos.com/member.php?u=10417
    About:
        Provides a small toolbar for inserting MIDI keyswitches and setting
        velocities, intended for use with Tod's Pedal Steel library for Kontakt.
    Donation: https://www.paypal.me/Lokasenna
    Provides:
        Lokasenna_Pedal Steel/*.png
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

GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Label.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

local images = {}
local function loadImage(image)
  if images[image] then return images[image] end

  local buffer = GUI.GetBuffer()
  local ret = gfx.loadimg(buffer, GUI.script_path.."/Lokasenna_Pedal Steel/"..image..".png")

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

  if not button.image then error("IButton: Missing 'image' property") end

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


local ILabel = GUI.Element:new()
GUI.ILabel = ILabel

ILabel.__index = ILabel

function ILabel:new(name, props)
  local label = props

  label.name = name
  label.type = "ILabel"

  if not label.image then error("IButton: Missing 'image' property") end

  GUI.redraw_z[label.z] = true

  return setmetatable(label, self)
end

function ILabel:init()
  self.imageBuffer = loadImage(self.image)
  if not self.imageBuffer then error("IButton: The specified image was not found") end
end

function ILabel:draw()
  gfx.mode = 0
  gfx.blit(self.imageBuffer, 1, 0, 0, 0, self.w, self.h, self.x, self.y, self.w, self.h)
end

------------------------------------
-------- Logic ---------------------
------------------------------------


local function setSelectedNotesVelocity(vel, relative)
  local editor = reaper.MIDIEditor_GetActive()
  if not editor then return end

  local take = reaper.MIDIEditor_GetTake(editor)
  if not take then return end

  reaper.Undo_BeginBlock()

  local idx = -2
  while true do
    idx = reaper.MIDI_EnumSelNotes(take, idx)
    if idx == -1 then break end

    -- retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, noteidx )
    local _, _, muted, startPPQ, endPPQ, chan, pitch, oldVel = reaper.MIDI_GetNote(take, idx)

    reaper.MIDI_SetNote(take, idx, 1, muted, startPPQ, endPPQ, chan, pitch, (relative and (oldVel + vel) or vel))
  end


  local undoStr = (relative
    and ("Adjust selected notes velocities by " .. vel)
    or ("Set selected notes velocities to " .. vel)
  )
  reaper.Undo_EndBlock(undoStr, -1)
end


local function insertKeyswitch(note)
  local editor = reaper.MIDIEditor_GetActive()
  if not editor then return end

  local take = reaper.MIDIEditor_GetTake(editor)
  if not take then return end

  local eventIdx = -2
  local minPosPPQ
  while true do
    eventIdx = reaper.MIDI_EnumSelEvts(take, eventIdx)
    if eventIdx == -1 then break end;

    local _, _, _, eventPosPPQ = reaper.MIDI_GetEvt(take, eventIdx, 0, 0, 0, "")
    if (not minPosPPQ or eventPosPPQ < minPosPPQ) then minPosPPQ = eventPosPPQ end
  end

  if not minPosPPQ then return end

  local startPPQ = minPosPPQ - 3

  local newCursorPos = reaper.MIDI_GetProjTimeFromPPQPos(take, minPosPPQ - 6)

  reaper.Undo_BeginBlock()

  -- Clear the note selection
  reaper.MIDI_SelectAll(take, false)

  -- Insert the keyswitch note
  reaper.MIDI_InsertNote(take, 1, 0, startPPQ, startPPQ + 350, 1, note, 20, 0)

  -- Move six ticks to the left
  reaper.ApplyNudge(0, 1, 6, 1, newCursorPos, false, 0)

  reaper.Undo_EndBlock("Insert keyswitch, note " .. note, -1)
end




------------------------------------
-------- Element Properties --------
------------------------------------


local topRow = {
  {
    -- Main
    caption = "Main",
    -- image = "top_Main",
    func = insertKeyswitch,
    params = {36},
  },
  {
    -- CC1
    caption = "CC1",
    -- image= "top_CC1",
    func = insertKeyswitch,
    params = {37},
  },
  {
    -- CC2
    caption = "CC2",
    -- image= "top_CC2",
    func = insertKeyswitch,
    params = {38},
  },
  {
    -- CC3
    caption = "CC3",
    -- image= "top_CC3",
    func = insertKeyswitch,
    params = {39},
  },
  {
    -- CC4
    caption = "CC4",
    -- image= "top_CC4",
    func = insertKeyswitch,
    params = {40},
  }
}

local rows = {

  ------------------------------------
  -------- Second row ----------------
  ------------------------------------

  {
    {
      -- -1
      caption = "-1",
      image = "left_-1",
      params = {-1, true}
    },
    {
      -- 108
      caption = "108",
    },
    {
      -- 112
      caption = "112",
    },
    {
      -- 116
      caption = "116",
    },
    {
      -- 120
      w = 33,
      caption = "120",
    },
  },

  ------------------------------------
  -------- Third row -----------------
  ------------------------------------

  {

    {
      -- +1
      caption = "+1",
      image = "left_+1",
      params = {1, true}
    },
    {
      -- 92
      caption = "92",
    },
    {
      -- 96
      caption = "96",
    },
    {
      -- 100
      caption = "100",
    },

    {
      -- 104
      w = 33,
      caption = "104",
    },
  },

  ------------------------------------
  -------- Fourth row ----------------
  ------------------------------------

  {
    {
      -- 80
      image = "left_80",
      caption = "80",
    },
    {
      -- 76
      caption = "76",
    },
    {
      -- 80
      caption = "80",
    },

    {
      -- 84
      caption = "84",
    },
    {
      -- 88
      w = 33,
      caption = "88",
    },
  },

  ------------------------------------
  -------- Fifth row -----------------
  ------------------------------------

  {

    {
      -- 70
      image = "left_70",
      caption = "70",
    },
    {
      -- 60
      caption = "60",
    },

    {
      -- 64
      caption = "64",
    },

    {
      -- 68
      caption = "68",
    },

    {
      -- 72
      w = 33,
      caption = "72",
    },
  },

  ------------------------------------
  -------- Sixth row -----------------
  ------------------------------------

  {
    {
      -- 60
      image = "left_60",
      caption = "60",
    },
    {
      -- 44
      caption = "44",
    },

    {
      -- 48
      caption = "48",
    },

    {
      -- 52
      caption = "52",
    },



    {
      -- 56
      w = 33,
      caption = "56",
    },
  },

  ------------------------------------
  -------- Seventh row ---------------
  ------------------------------------

  {

    {
      -- 50
      image = "left_50",
      caption = "50",
    },
    {
      -- 28
      caption = "28",
    },

    {
      -- 32
      caption = "32",
    },


    {
      -- 36
      caption = "36",
    },

    {
      -- 40
      w = 33,
      caption = "40",
    },
  },

    ------------------------------------
    -------- Eighth row ----------------
    ------------------------------------

  {

    {
      -- 40
      image = "left_40",
      caption = "40",
    },

    {
      -- 18
      caption = "18",
    },

    {
      -- 20
      caption = "20",
    },

    {
      -- 22
      caption = "22",
    },

    {
      -- 24
      w = 33,
      caption = "24",
    },
  },

  ------------------------------------
  -------- Ninth row -----------------
  ------------------------------------

  {

    {
      -- 30
      image = "left_30",
      caption = "30",
    },
    {
      -- 10
      caption = "10",
    },

    {
      -- 12
      caption = "12",
    },

    {
      -- 14
      caption = "14",
    },

    {
      -- 16
      w = 33,
      caption = "16",
    },

  },

  ------------------------------------
  -------- Tenth Row -----------------
  ------------------------------------

  {
    {
      -- 20
      image = "left_20",
      caption = "20",
    },
    {
      -- 5
      caption = "5",
    },

    {
      -- 6
      caption = "6",
    },

    {
      -- 7
      caption = "7",
    },

    {
      -- 8
      w = 33,
      caption = "8",
    },


  },

  ------------------------------------
  -------- Bottom row ----------------
  ------------------------------------

  {

    {
      -- 10
      image = "left_10",
      caption = "10",
    },
    {
      -- 1
      caption = "1",
    },


    {
      -- 2
      caption = "2",
    },

    {
      -- 3
      caption = "3",
    },

    {
      -- 4
      w = 33,
      caption = "4",
    },
  },
}

local labels = {
  "G#3-C#5",
  "F#3-B4",
  "E3-A4",
  "D#3-G#4",
  "B2-E4",
  "G#2-C#4",
  "F#2-F3",
  "E2-D#3",
  "D2-C#3",
  "B1-A#2",
}



------------------------------------
-------- GUI Layout ----------------
------------------------------------


local topGap = -1
local topWidth = 45
local gridWidth = 31
local btnHeight = 17

local topRef = {
  x = function(i) return (topWidth + topGap) * i end,
  y = 0,
  w = topWidth,
  h = btnHeight
}

local gridRef = {
  x = function(i) return gridWidth * i end,
  y = function(i) return btnHeight + btnHeight * i end,
  w = gridWidth,
  h = btnHeight,
}

local labelRefX = gridRef.x(5) + 2

GUI.name = "Pedal Steel"
GUI.x = 0
GUI.y = 0
GUI.w = topRef.x(#topRow)
GUI.h = gridRef.y(#rows) + 1
GUI.anchor, GUI.corner = "mouse", "C"
GUI.version = nil

local processedTopRow = {}
for i, elm in ipairs(topRow) do
  elm.type = "IButton"
  elm.z = 1
  elm.x = topRef.x(i - 1)
  elm.y = topRef.y
  elm.w = topRef.w
  elm.h = topRef.h
  elm.image = "top_"..elm.caption

  processedTopRow["btn_1_"..i] = elm
end
GUI.CreateElms(processedTopRow)


for rowIdx, row in ipairs(rows) do
  local processedRow = {}
  for elmIdx, elm in ipairs(row) do
    elm.type = "IButton"
    elm.z = rowIdx + 1
    elm.x = gridRef.x(elmIdx - 1)
    elm.y = gridRef.y(rowIdx - 1)
    elm.w = elm.w or gridRef.w
    elm.h = gridRef.h
    elm.image = elm.image or "grid_"..elm.caption

    elm.func = elm.func or setSelectedNotesVelocity
    elm.params = elm.params or {tonumber(elm.caption)}
    processedRow["gridBtn"..(rowIdx + 1).."_"..elmIdx] = elm
  end
  GUI.CreateElms(processedRow)
end


local processedLabels = {}
for idx, str in ipairs(labels) do
  processedLabels["gridLbl"..idx] = {
    type = "ILabel",
    z = idx + 1,
    x = labelRefX,
    y = gridRef.y(idx - 1),
    w = 63,
    h = 17,
    image = "range_"..str,
  }
end
GUI.CreateElms(processedLabels)

GUI.load_window_state("Lokasenna_Pedal Steel")

GUI.exit = function()
  GUI.save_window_state("Lokasenna_Pedal Steel")
end

GUI.Init()

if (reaper.JS_Window_Find) then
  local hwnd = reaper.JS_Window_Find(GUI.name, true)
  reaper.JS_Window_SetZOrder(hwnd, "TOPMOST", hwnd)
end

GUI.Main()

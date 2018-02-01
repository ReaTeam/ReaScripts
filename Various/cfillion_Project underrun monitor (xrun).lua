-- @description Project underrun monitor (xrun)
-- @version 1.0
-- @author cfillion
-- @website
--   cfillion.ca https://cfillion.ca
--   Request Thread https://forum.cockos.com/showthread.php?p=1942953
-- @screenshot https://i.imgur.com/ECoEWks.gif
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Project+underrun+monitor+(xrun)
-- @about
--   # Project underrun monitor
--
--   This script keeps track of the project time where an audio or media buffer
--   underrun occured. Markers can optionally be created. The reported time and
--   marker position accuracy is limited by the polling speed of ReaScripts
--   which is around 30Hz.

local EXT_SECTION      = 'cfillion_underrun_monitor'
local EXT_WINDOW_STATE = 'window_state'
local EXT_MARKER_TYPE  = 'marker_type'
local EXT_MARKER_WHEN  = 'marker_when'

local WIN_PADDING = 10
local BOX_PADDING = 7
local LINE_HEIGHT = 28
local TIME_WIDTH  = 100

local KEY_ESCAPE = 0x1b

local AUDIO_XRUN = 1
local MEDIA_XRUN = 2

local AUDIO_MARKER = 'audio xrun'
local MEDIA_MARKER = 'media xrun'

local AUDIO_COLOR = reaper.ColorToNative(255, 0, 0)|0x1000000
local MEDIA_COLOR = reaper.ColorToNative(255, 255, 0)|0x1000000

local DEFAULT_SETTINGS = {
  [EXT_MARKER_TYPE]=AUDIO_XRUN|MEDIA_XRUN,
  [EXT_MARKER_WHEN]=4,
}

local MARKER_TYPE_MENU = {
  {str='(off)',      val=0},
  {str='any',        val=AUDIO_XRUN|MEDIA_XRUN},
  {str='audio',      val=AUDIO_XRUN},
  {str='media',      val=MEDIA_XRUN},
}

local MARKER_WHEN_MENU = {
  {str='play or record',val=1|4},
  {str='playing',       val=1},
  {str='recording ',    val=4},
}

local mouseDown  = false
local mouseClick = false
local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local prev_audio, prev_media = reaper.GetUnderrunTime()
local audio_time, media_time, last_project

function position()
  if reaper.GetPlayState() & 1 == 0 then
    return reaper.GetCursorPosition()
  else
    return reaper.GetPlayPosition2()
  end
end

function markerSettings()
  local playbackState = reaper.GetPlayState()
  local markerWhen = tonumber(reaper.GetExtState(EXT_SECTION, EXT_MARKER_WHEN))

  if playbackState & markerWhen ~= 0 then
    return tonumber(reaper.GetExtState(EXT_SECTION, EXT_MARKER_TYPE))
  else
    return 0
  end
end

function probeUnderruns()
  local markerType = markerSettings()
  local audio_xrun, media_xrun, curtime = reaper.GetUnderrunTime()

  if audio_xrun > 0 and audio_xrun ~= prev_audio then
    prev_audio = audio_xrun
    audio_time = position()

    if markerType & AUDIO_XRUN ~= 0 then
      reaper.AddProjectMarker2(0, 0, audio_time, 0, AUDIO_MARKER, -1, AUDIO_COLOR)
    end
  end

  if media_xrun > 0 and media_xrun ~= prev_media then
    prev_media = media_xrun
    media_time = position()

    if markerType & MEDIA_XRUN ~= 0 then
      reaper.AddProjectMarker2(0, 0, media_time, 0, MEDIA_MARKER, -1, MEDIA_COLOR)
    end
  end
end

function eraseMarkers(name)
  if not last_project or not reaper.ValidatePtr(last_project, 'ReaProject*') then return end

  local index  = 0

  -- integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber
  while true do
    local marker = {reaper.EnumProjectMarkers2(last_project, index)}
    if marker[1] < 1 then break end

    if not marker[2] and marker[5] == name then
      reaper.DeleteProjectMarkerByIndex(last_project, index)
    else
      index = index + 1
    end
  end
end

function reset(xrunType)
  if xrunType & AUDIO_XRUN ~= 0 then
    audio_time = nil
    eraseMarkers(AUDIO_MARKER)
  end

  if xrunType & MEDIA_XRUN ~= 1 then
    media_time = nil
    eraseMarkers(MEDIA_MARKER)
  end
end

function detectProjectChange()
  local current_project = reaper.EnumProjects(-1, '')

  if last_project ~= current_project then
    reset(AUDIO_XRUN | MEDIA_XRUN)
    last_project = current_project
  end
end

function formatTime(time)
  if time then
    return reaper.format_timestr(time, '')
  else
    return '(never)'
  end
end

function boxRect(box)
  local x, y = gfx.x, gfx.y
  local w, h = gfx.measurestr(box.text)

  w = w + (BOX_PADDING * 2)
  h = h + BOX_PADDING

  if box.w then w = box.w end
  if box.h then h = box.h end

  return {x=x, y=y, w=w, h=h}
end

function drawBox(box)
  if not box.color then box.color = {255, 255, 255} end

  setColor(box.color)
  gfx.rect(box.rect.x + 1, box.rect.y + 1, box.rect.w - 2, box.rect.h - 2, true)

  gfx.x = box.rect.x
  setColor({42, 42, 42})
  if not box.noborder then
    gfx.rect(box.rect.x, box.rect.y, box.rect.w, box.rect.h, false)
  end

  gfx.x = box.rect.x + BOX_PADDING
  gfx.drawstr(box.text, 4, gfx.x + box.rect.w - (BOX_PADDING * 2), gfx.y + box.rect.h + 2)

  gfx.x = box.rect.x + box.rect.w + BOX_PADDING
end

function box(box)
  if box.menu then menu(box) end
  if not box.rect then box.rect = boxRect(box) end
  if box.callback then button(box) end
  drawBox(box)
end

function menu(box)
  local value = tonumber(reaper.GetExtState(EXT_SECTION, box.key))
  local menustr = ''

  for _, item in ipairs(box.menu) do
    if menustr:len() > 0 then menustr = menustr .. '|' end

    if value == item.val then
      box.text = item.str
      menustr = menustr .. '!'
    end

    menustr = menustr .. item.str
  end

  if not box.rect then box.rect = boxRect(box) end

  box.callback = function()
    local oldY = gfx.y
    gfx.y = gfx.y + box.rect.h
    local index = gfx.showmenu(menustr)
    gfx.y = oldY

    if index > 0 then
      reaper.SetExtState(EXT_SECTION, box.key, box.menu[index].val, true)
    end
  end
end

function button(box)
  local underMouse =
    gfx.mouse_x >= box.rect.x and
    gfx.mouse_x < box.rect.x + box.rect.w and
    gfx.mouse_y >= box.rect.y and
    gfx.mouse_y < box.rect.y + box.rect.h

  if mouseClick and underMouse then
    box.callback()

    if box.active ~= nil then
      box.active = true
    end
  end

  if box.active then
    box.color = {150, 175, 225}
  elseif (underMouse and mouseDown) or kbTrigger then
    box.color = {120, 120, 120}
  else
    box.color = {220, 220, 220}
  end

  drawBox(box)
end

function setColor(color)
  gfx.r = color[1] / 255.0
  gfx.g = color[2] / 255.0
  gfx.b = color[3] / 255.0
end

function draw()
  gfx.x, gfx.y = WIN_PADDING, WIN_PADDING

  box({w=170, text='Last audio xrun position:', noborder=true})
  box({w=100, text=formatTime(audio_time)})
  box({text="Jump", callback=audio_time and function()
    reaper.SetEditCurPos(audio_time, true, false)
  end})
  box({text="Reset", callback=audio_time and function() reset(AUDIO_XRUN) end})

  gfx.x, gfx.y = WIN_PADDING, (WIN_PADDING+LINE_HEIGHT)

  box({w=170, text='Last media xrun position:', noborder=true})
  box({w=100, text=formatTime(media_time)})
  box({text="Jump", callback=media_time and function()
    reaper.SetEditCurPos(media_time, true, false)
  end})
  box({text="Reset", callback=media_time and function() reset(MEDIA_XRUN) end})

  gfx.x, gfx.y = WIN_PADDING, (WIN_PADDING+LINE_HEIGHT)*2
  box({text='Create markers on', noborder=true})
  box({w=60, menu=MARKER_TYPE_MENU, key=EXT_MARKER_TYPE})
  box({text='xruns, when', noborder=true})
  box({w=107, menu=MARKER_WHEN_MENU, key=EXT_MARKER_WHEN})
end

function mouseInput()
  if mouseClick then
    mouseClick = false
  elseif gfx.mouse_cap == 1 then
    mouseDown = true
  elseif mouseDown then
    mouseClick = true
    mouseDown = false
  elseif mouseClick then
    mouseClick = false
  end
end

function loop()
  detectProjectChange()
  probeUnderruns()
  mouseInput()

  gfx.clear = 16777215
  draw()
  gfx.update()

  local key = gfx.getchar()

  if key < 0 then
    return
  elseif key == KEY_ESCAPE then
    gfx.quit()
  else
    reaper.defer(loop)
  end
end

function previousWindowState()
  local state = tostring(reaper.GetExtState(EXT_SECTION, EXT_WINDOW_STATE))
  return state:match("^(%d+) (%d+) (%d+) (-?%d+) (-?%d+)$")
end

function saveWindowState()
  local dockState, xpos, ypos = gfx.dock(-1, 0, 0, 0, 0)
  local w, h = gfx.w, gfx.h
  if dockState > 0 then
    w, h = previousWindowState()
  end

  reaper.SetExtState(EXT_SECTION, EXT_WINDOW_STATE,
    string.format("%d %d %d %d %d", w, h, dockState, xpos, ypos), true)
end

for key, default in pairs(DEFAULT_SETTINGS) do
  if not reaper.HasExtState(EXT_SECTION, key) then
    reaper.SetExtState(EXT_SECTION, key, default, true)
  end
end

local w, h, dockState, x, y = previousWindowState()

if w then
  gfx.init(scriptName, w, h, dockState, x, y)
else
  gfx.init(scriptName, 406, 107)
end

if reaper.GetAppVersion():match('OSX') then
  gfx.setfont(1, 'sans-serif', 12)
else
  gfx.setfont(1, 'sans-serif', 15)
end

reaper.atexit(function()
  saveWindowState()
  reset(AUDIO_XRUN|MEDIA_XRUN)
end)

loop()

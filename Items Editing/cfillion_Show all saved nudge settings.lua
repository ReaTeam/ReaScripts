-- @description Show all saved nudge settings
-- @version 1.1
-- @changelog
--   Add "Save current" button
--   Improve text legibility on Windows
--   Remember window position
-- @author cfillion
-- @link cfillion.ca https://cfillion.ca
-- @donation https://www.paypal.me/cfillion
-- @screenshot https://i.imgur.com/PrITgVt.png
-- @about
--   # Show every saved nudge settings
--
--   **Tip:** Switch to a different nudge setting with the 0-8 keys.

local WHAT_MAP = {'position', 'left trim', 'left edge', 'right trim', 'contents',
  'duplicate', 'edit cursor', 'end position'}

local UNIT_MAP =  {'milliseconds', 'seconds', 'grid units', 'notes',
  [17]='measures.beats', [18]='samples', [19]='frames', [20]='pixels',
  [21]='item lengths', [22]='item selections'}

local NOTE_MAP = {'1/256', '1/128', '1/64', '1/32T', '1/32', '1/16T', '1/16',
  '1/8T', '1/8', '1/4T', '1/4', '1/2', 'whole'}

local SAVE_ACTIONS = {41271, 41272, 41273, 41274, 41283, 41284, 41285, 41286}

local WIN_PADDING = 10
local BOX_PADDING = 7

local EXT_SECTION = 'cfillion_show_nudge_settings'
local EXT_WINDOW_STATE = 'windowState'

local exit = false
local mouseDown = false
local mouseClick = false
local iniFile = reaper.get_ini_file()
local setting = {}
local lastRefresh = os.time()

local scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+).lua$")

function iniRead(key, n)
  if n > 0 then
    key = string.format('%s_%d', key, n)
  end

  return tonumber(({reaper.BR_Win32_GetPrivateProfileString(
    'REAPER', key, '0', iniFile)})[2])
end

function boolValue(val, off, on)
  if not off then off = 'OFF' end
  if not on then on = 'ON' end

  if val == 0 then
    return off
  else
    return on
  end
end

function mapValue(val, strings)
  return strings[val] or string.format('%d (Unknown)', val)
end

function isAny(val, array)
  for _,n in ipairs(array) do
    if val == n then
      return true
    end
  end

  return false
end

function snapTo(unit)
  if isAny(unit, {3, 21, 22}) then
    return 'grid'
  elseif unit == 17 then -- measures.beats
    return 'bar'
  end

  return 'unit'
end

function loadSetting(n, reload)
  if setting.n == n and not reload then return end

  setting = {n=n}

  local nudge = iniRead('nudge', n)
  setting.mode = nudge & 1
  setting.what = (nudge >> 12) + 1
  setting.unit = (nudge >> 4 & 0xFF) + 1
  setting.snap = nudge & 2
  setting.rel = nudge & 4

  if setting.unit >= 4 and setting.unit <= 16 then
    setting.note = setting.unit - 3
    setting.unit = 4
  end

  if setting.mode == 0 then
    setting.amount = iniRead('nudgeamt', n)
  else
    setting.amount = '(N/A)'
  end
end

function saveCurrent()
  reaper.Main_OnCommand(SAVE_ACTIONS[setting.n], 0)
  loadSetting(setting.n, true)
end

function boxRect(box)
  local x, y = gfx.x, gfx.y
  local w, h = gfx.measurestr(box.text)

  w = w + (BOX_PADDING * 2)
  h = h + BOX_PADDING

  if box.w then w = box.w end
  if box.h then h = box.h end

  if box.rtl then x = math.max(box.rtl, (gfx.w - w) - x) end

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
  box.rect = boxRect(box)
  drawBox(box)
end

function button(box, active, callback)
  box.rect = boxRect(box)

  local underMouse =
    gfx.mouse_x >= box.rect.x and
    gfx.mouse_x < box.rect.x + box.rect.w and
    gfx.mouse_y >= box.rect.y and
    gfx.mouse_y < box.rect.y + box.rect.h

  if mouseClick and underMouse then
    callback()
    active = true
  end

  if active then
    box.color = {150, 175, 225}
  elseif underMouse and mouseDown then
    box.color = {120, 120, 120}
  else
    box.color = {220, 220, 220}
  end

  drawBox(box)
end

function draw()
  gfx.x, gfx.y = WIN_PADDING, WIN_PADDING
  box({w=70, text=boolValue(setting.mode, 'Nudge', 'Set')})
  box({w=100, text=mapValue(setting.what, WHAT_MAP)})
  box({noborder=true, text=boolValue(setting.mode, 'by:', 'to:')})
  box({w=70, text=setting.amount})
  if setting.note then
    box({w=50, text=mapValue(setting.note, NOTE_MAP)})
  end
  box({w=gfx.w - gfx.x - WIN_PADDING, text=mapValue(setting.unit, UNIT_MAP)})

  gfx.x, gfx.y = WIN_PADDING - BOX_PADDING, 35
  box({text=string.format('Snap to %s: %s', snapTo(setting.unit),
    boolValue(setting.snap)), noborder=true})

  if setting.mode == 1 and isAny(setting.what, {1, 6, 8}) then
    gfx.x = 110
    box({text=string.format('Relative set: %s', boolValue(setting.rel)), noborder=true})
  end

  gfx.x, gfx.y = WIN_PADDING, 60
  button({text='Last'}, setting.n == 0, function() loadSetting(0) end)
  for i=1,8 do
    button({text=i}, setting.n == i, function() loadSetting(i) end)
  end

  if setting.n > 0 then
    local minX = gfx.x
    gfx.x = WIN_PADDING
    button({text='Save current', rtl=minX}, false, saveCurrent)
  end
end

function setColor(color)
  gfx.r = color[1] / 255.0
  gfx.g = color[2] / 255.0
  gfx.b = color[3] / 255.0
end

function keyboardInput()
  local key = gfx.getchar()

  if key < 0 then
    exit = true
  elseif key >= string.byte('0') and key <= string.byte('8') then
    loadSetting(key - string.byte('0'))
  end
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
  keyboardInput()
  mouseInput()

  if exit then return end

  if lastRefresh < os.time() then
    loadSetting(setting.n, true)
    lastRefresh = os.time()
  end

  gfx.clear = 16777215
  draw()
  gfx.update()

  if not exit then
    reaper.defer(loop)
  else
    gfx.quit()
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

local w, h, dockState, x, y = previousWindowState()

if w then
  gfx.init(scriptName, w, h, dockState, x, y)
else
  gfx.init(scriptName, 475, 90)
end

if reaper.GetAppVersion():match('OSX') then
  gfx.setfont(1, 'sans-serif', 12)
else
  gfx.setfont(1, 'sans-serif', 15)
end

reaper.atexit(saveWindowState)

loadSetting(0)
loop()

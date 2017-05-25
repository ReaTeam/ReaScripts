-- @description Big Repeat Button
-- @version 1.0.2
-- @author cfillion
-- @changelog
--   Improve button sizing in wide + short windows
--   Try harder to fit the button in very small windows
-- @link
--   cfillion.ca https://cfillion.ca
--   Request Thread http://forum.cockos.com/showthread.php?t=191477
-- @screenshot https://i.imgur.com/BUripgE.gif
-- @donation https://www.paypal.me/cfillion/10

local HIGHLIGHT = 0.1
local REPEAT_QUERY = -1
local REPEAT_TOGGLE = 255

local CENTER_H = 1
local CENTER_V = 4

local mouse_down = false

function status(on)
  if on then
    return "ON "
  else
    return "OFF"
  end
end

function loop()
  local margin = math.min(gfx.w, gfx.h) / 8
  local left = gfx.w - margin
  local width = left - margin
  local bottom = gfx.h - margin
  local height = bottom - margin
  local mouse_hit =
    (gfx.mouse_x > margin and gfx.mouse_x < left) and
    (gfx.mouse_y > margin and gfx.mouse_y < bottom)

  if gfx.getchar() < 0 then
    return gfx.quit()
  elseif (gfx.mouse_cap & 1) ~= 0 and mouse_hit then
    mouse_down = true
  elseif mouse_down then
    reaper.GetSetRepeat(REPEAT_TOGGLE)
    mouse_down = false
  end

  local on = reaper.GetSetRepeat(REPEAT_QUERY) == 1
  local label = string.format("Repeat %s", status(on))
  gfx.setfont(1)
  local w, h = gfx.measurestr(label)

  if w > width or h > height then
    local diff = math.max(w - width, h - height)

    if diff <= margin then
      margin = margin - diff
      width = width + (diff * 2)
      height = height + (diff * 2)
    else
      gfx.x = 0; gfx.y = 0
      gfx.setfont(0)
      gfx.drawstr("The window is too small to fit the button.")
      gfx.update()
      reaper.defer(loop)
      return
    end
  end

  gfx.r = 0; gfx.g = 0; gfx.b = 0

  if on then
    gfx.g = 0.3
  else
    gfx.r = 0.3
  end

  if mouse_hit then
    if mouse_down then
      gfx.b = 0.5
    else
      gfx.r = gfx.r + HIGHLIGHT
      gfx.g = gfx.g + HIGHLIGHT
      gfx.b = gfx.b + HIGHLIGHT
    end
  end

  gfx.rect(margin, margin, width, height, true)

  gfx.r = 0.9; gfx.g = 0.9; gfx.b = 1
  gfx.rect(margin, margin, width, height, false)

  gfx.x = margin; gfx.y = margin
  gfx.drawstr(label, CENTER_H | CENTER_V, left, bottom)

  gfx.update()
  reaper.defer(loop)
end

gfx.setfont(1, 'sans-serif', 62, 9)
gfx.init("Big Repeat Button", 700, 300)
loop()

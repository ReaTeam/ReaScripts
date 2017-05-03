-- @description Big Repeat Button
-- @version 1.0
-- @author cfillion
-- @link
--   Author's Website https://cfillion.ca
--   Request Thread http://forum.cockos.com/showthread.php?t=191477
-- @screenshot https://i.imgur.com/BUripgE.gif
-- @donation https://www.paypal.me/cfillion/10

local MARGIN = 40
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
  if gfx.getchar() < 0 then
    return gfx.quit()
  elseif (gfx.mouse_cap & 1) ~= 0 then
    mouse_down = true
  elseif mouse_down then
    reaper.GetSetRepeat(REPEAT_TOGGLE)
    mouse_down = false
  end

  local on = reaper.GetSetRepeat(REPEAT_QUERY) == 1

  local left = gfx.w - MARGIN
  local width = left - MARGIN
  local bottom = gfx.h - MARGIN
  local height = bottom - MARGIN

  gfx.r = 0; gfx.g = 0; gfx.b = 0

  if on then
    gfx.g = 0.3
  else
    gfx.r = 0.3
  end

  local hit_x = gfx.mouse_x > MARGIN and gfx.mouse_x < left
  local hit_y = gfx.mouse_y > MARGIN and gfx.mouse_y < bottom

  if hit_x and hit_y then
    if mouse_down then
      gfx.b = 0.5
    else
      gfx.r = gfx.r + HIGHLIGHT
      gfx.g = gfx.g + HIGHLIGHT
      gfx.b = gfx.b + HIGHLIGHT
    end
  end

  gfx.rect(MARGIN, MARGIN, width, height, true)

  gfx.r = 0.9; gfx.g = 0.9; gfx.b = 1
  gfx.rect(MARGIN, MARGIN, width, height, false)

  gfx.x = MARGIN; gfx.y = MARGIN
  gfx.drawstr(string.format("Repeat %s", status(on)),
    CENTER_H | CENTER_V, left, bottom)

  gfx.update()
  reaper.defer(loop)
end

gfx.setfont(1, 'sans-serif', 62, 9)
gfx.init("Big Repeat Button", 700, 300)
loop()

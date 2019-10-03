-- @description Linear ramp selected envelope points
-- @author cfillion
-- @version 1.0
-- @screenshot https://i.imgur.com/KwqzjfC.gif
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

local MARGIN = 10
local IDC_ARROW = 32512
local IDC_SIZENS = 32645
local HCENTER = 1
local VCENTER = 1<<2
local ADJ_RIGHT = 0
local ADJ_LEFT  = 1
local UNDO_STATE_TRACKCFG = 1

function enumEnvelopePoints()
  local pi = 0
  local count = reaper.CountEnvelopePoints(state.env)

  return function()
    local point = {reaper.GetEnvelopePoint(state.env, pi)}
    if point[1] then -- retval
      point[1] = pi
      point[3] = reaper.ScaleFromEnvelopeMode(state.scalingMode, point[3])

      pi = pi + 1
      return point
    end
  end
end

function getSelectedPoints()
  local points = {}

  for point in enumEnvelopePoints() do
    if point[6] then -- selected
      table.insert(points, point)
    end
  end

  return points
end

function loadState(count)
  if gfx.w ~= state.oldw or gfx.h ~= state.oldh then
    state.count = nil -- invalidate the state
  end

  local env = reaper.GetSelectedEnvelope(0)
  local stateCount = reaper.GetProjectStateChangeCount()

  if stateCount == state.count and state.env == env then
    return
  end

  state = {
    env = env,
    count = count, oldw = gfx.w, oldh = gfx.h
  }

  if not state.env then
    state.error = "No envelope selected"
    return
  end

  state.scalingMode = reaper.GetEnvelopeScalingMode(state.env)

  state.selectedPoints = getSelectedPoints()
  if #state.selectedPoints < 3 then
    state.error = "Select at least three points"
    return
  end

  local brenv = reaper.BR_EnvAlloc(state.env, false)
  local envprops = {reaper.BR_EnvGetProperties(brenv)}
  reaper.BR_EnvFree(brenv, false)

  state.firstPos = state.selectedPoints[1][2]
  state.lastPos = state.selectedPoints[#state.selectedPoints][2]

  state.timeSpan = state.lastPos - state.firstPos
  state.xscale = (state.lastPos - state.firstPos) / w

  state.minValue, state.maxValue = envprops[7], envprops[8]
  state.valueDelta = state.maxValue - state.minValue
  state.yscale = state.valueDelta / h
  if state.yscale <= 0 then state.yscale = 1 end
end

function adjustValue(point)
  local value = point[3]

  if not adjustment then
    return value
  end

  local force = (point[2] - state.firstPos) / state.timeSpan
  if adjustmentDir == ADJ_LEFT then
    force = 1 - force
  end

  value = value + (adjustment * force)
  return math.min(math.max(value, state.minValue), state.maxValue)
end

function formatValue(value)
  value = reaper.ScaleToEnvelopeMode(state.scalingMode, value)
  return reaper.Envelope_FormatValue(state.env, value)
end

function applyAdjustment()
  reaper.Undo_BeginBlock()

  for _, point in ipairs(state.selectedPoints) do
    local value = adjustValue(point)
    value = reaper.ScaleToEnvelopeMode(state.scalingMode, value)
    reaper.SetEnvelopePoint(state.env, point[1], nil, value, nil, nil, nil, true)
  end

  reaper.Envelope_SortPoints(state.env)
  reaper.UpdateArrange()

  reaper.Undo_EndBlock(scriptName, UNDO_STATE_TRACKCFG)
end

function clearAdjustment()
  mouseDownY, adjustment = nil, nil
end

function setColor(color)
  gfx.r = (color >> 16      ) / 255
  gfx.g = (color >> 8 & 0xFF) / 255
  gfx.b = (color      & 0xFF) / 255
end

function drawMessage(message, align)
  gfx.x, gfx.y = 0, 0
  setColor(0x000000)
  gfx.drawstr(message, align or (HCENTER | VCENTER), gfx.w, gfx.h)
end

function mouseEvents()
  if gfx.mouse_x > MARGIN and gfx.mouse_x - MARGIN < w and
     gfx.mouse_y > MARGIN and gfx.mouse_y - MARGIN < h then
    gfx.setcursor(IDC_SIZENS)

    if gfx.mouse_cap & 1 == 1 and not mouseDownY then
      mouseDownY, adjustment = gfx.mouse_y, 0

      if gfx.mouse_x >= w/2 then
        adjustmentDir = ADJ_RIGHT
      else
        adjustmentDir = ADJ_LEFT
      end
    end
  else
    gfx.setcursor(IDC_ARROW)
  end

  if gfx.mouse_cap & 1 == 1 then
    if mouseDownY then -- if the mousedown happened in the clickable area
      adjustment = (mouseDownY - gfx.mouse_y) * state.yscale
    end
  elseif adjustment then
    applyAdjustment()
    clearAdjustment()
  end
end

function timeToPixel(time)
  return MARGIN + (time - state.firstPos) / state.xscale
end

function valueToPixel(value)
  return MARGIN + h - (value - state.minValue) / state.yscale
end

function drawPoint(i, point, nextPoint, adjust)
  local value = adjust and adjustValue(point) or point[3]
  local x = timeToPixel(point[2])
  local y = valueToPixel(value)
  gfx.circle(x, y, 3, true)

  if nextPoint then
    local nextX = timeToPixel(nextPoint[2])
    local nextY = valueToPixel(adjust and adjustValue(nextPoint) or nextPoint[3])

    gfx.line(x, y, nextX, nextY)
    if not adjust then
      gfx.a = 0.5
      gfx.triangle(x, y, x, h + MARGIN, nextX, h + MARGIN, nextX-1, nextY)
      gfx.a = 1
    end
  end

  local humanValue = formatValue(value)
  gfx.x, gfx.y = x + 3, y + 3

  local strW, strY = gfx.measurestr(humanValue)
  if gfx.x + strW > w + MARGIN then
    gfx.x = w - strW + MARGIN
  end
  if gfx.y + strY > h + MARGIN then
    gfx.y = h - strY + MARGIN
  end

  gfx.drawstr(humanValue)
end

function drawEnvelope()
  setColor(0x3b7b39)
  for i, point in ipairs(state.selectedPoints) do
    drawPoint(i, point, state.selectedPoints[i + 1], false)
  end

  if adjustment then
    setColor(0x7600ff)
    for i, point in ipairs(state.selectedPoints) do
      drawPoint(i, point, state.selectedPoints[i + 1], true)
    end
  end
end

function loop()
  if gfx.getchar() < 0 then
    gfx.quit()
    return
  end

  w, h = gfx.w - MARGIN * 2, gfx.h - MARGIN * 2

  gfx.clear = 0xffffff

  setColor(0xe1e1e1)
  gfx.rect(MARGIN + 1, MARGIN + 1, w - 2, h - 2)

  loadState()

  if state.error then
    drawMessage(state.error)
  else
    mouseEvents()
    drawEnvelope()
  end

  gfx.r, gfx.g, gfx.b, gfx.a = 0, 0, 0, 1
  gfx.rect(MARGIN, MARGIN, w, h, false)

  gfx.update()
  reaper.defer(loop)
end

state = {}
scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

gfx.init(scriptName, 600, 100)
if reaper.GetAppVersion():match('OSX') then
  gfx.setfont(1, 'sans-serif', 12)
else
  gfx.setfont(1, 'sans-serif', 15)
end

reaper.defer(loop)

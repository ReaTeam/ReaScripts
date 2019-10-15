-- @description Search action by command ID or name
-- @author cfillion
-- @version 1.0
-- @screenshot https://i.imgur.com/nlGMR1T.gif
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD

local AL_SECTIONS = {
  [0    ] = 'Main',
  [100  ] = 'Main (alt recording)',
  [32060] = 'MIDI Editor',
  [32061] = 'MIDI Event List Editor',
  [32062] = 'MIDI Inline Editor',
  [32063] = 'Media Explorer',
}

local MARGIN  = 10
local PADDING = 7

local MB_OK = 0

local function iterateActions(section)
  local i = 0

  return function()
    local retval, name = reaper.CF_EnumerateActions(section, i, '')
    if retval > 0 then
      i = i + 1
      return retval, name
    end
  end
end

local function findAction(section)
  local findId = commandIdField.value
  local findName = actionNameField.value

  for id, name in iterateActions(section) do
    if id == findId or name == findName then
      return id, name
    end
  end
end

local function updateMatch()
  local value = commandIdField.value or actionNameField.value
  if not value then return end

  local id, name = findAction(sectionField.value, value)

  if not id then
    reaper.ShowMessageBox("Command ID or action name not found.", scriptName, MB_OK)
  end

  local namedId = reaper.ReverseNamedCommandLookup(id)
  commandIdField.value = namedId and ('_' .. namedId) or id
  actionNameField.value = name
end

local function setColor(color)
  gfx.r = (color >> 16      ) / 255
  gfx.g = (color >> 8 & 0xFF) / 255
  gfx.b = (color      & 0xFF) / 255
end

local function button(x, y, w, h, label, onclick)
  local underMouse =
    gfx.mouse_x >= x and gfx.mouse_x < x + w and
    gfx.mouse_y >= y and gfx.mouse_y < y + h

  if mouseClick and underMouse then
    gfx.x = x
    local oldY = gfx.y
    gfx.y = y + h
    onclick()
    gfx.y = oldY
  end

  setColor((underMouse and mouseDown) and 0x787878 or 0xdcdcdc)
  gfx.rect(x, y, w, h, true)
  setColor(0x2a2a2a)
  gfx.rect(x, y, w, h, false)

  gfx.x = x + PADDING
  gfx.drawstr(label, 0, gfx.x + w - (PADDING * 2), gfx.y + h)
end

local function mouseInput()
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

local function defaultSetValue(field)
  return reaper.GetUserInputs(scriptName, 1, field.label, field.value or '')
end

local function loop()
  mouseInput()

  if gfx.getchar() < 0 then
    gfx.quit()
    return
  end

  gfx.clear = 0xffffff

  local labelWidth, labelHeight = 0, 0
  for _, field in ipairs(fields) do
    local w, h = gfx.measurestr(field.label)
    labelWidth = math.max(labelWidth, w)
    labelHeight = math.max(labelHeight, h)
  end

  local buttonX = MARGIN + labelWidth + 10
  local buttonWidth = gfx.w - buttonX - MARGIN
  local buttonYoffset = labelHeight / 2.5
  local buttonHeight = labelHeight * 1.5

  gfx.y = MARGIN * 1.5
  for _, field in ipairs(fields) do
    gfx.x = MARGIN
    setColor(0x000000)
    gfx.drawstr(field.label)

    local displayValue =
      field.displayValue and field.displayValue(field.value) or field.value or ''

    button(buttonX, gfx.y - buttonYoffset, buttonWidth, buttonHeight,
           displayValue, function()
      local setValue = field.setValue or defaultSetValue
      local ok, newValue = setValue(field)

      if ok then
        field.value = newValue
      end

      updateMatch()
    end)

    gfx.y = gfx.y + buttonHeight + (MARGIN / 2)
  end

  gfx.x = gfx.w - MARGIN
  gfx.y = gfx.y + PADDING

  for _, control in ipairs(controls) do
    local w = gfx.measurestr(control.label) + (PADDING * 2)
    gfx.x = gfx.x - w
    button(gfx.x, gfx.y - buttonYoffset, w, buttonHeight,
      control.label, control.onclick)
    gfx.x = gfx.x - w
  end

  gfx.update()
  reaper.defer(loop)
end

sectionField = {
  label = 'Section name:',
  value = 0,
  setValue = function()
    local sectionIds = {}
    for id, _ in pairs(AL_SECTIONS) do
      table.insert(sectionIds, id)
    end
    table.sort(sectionIds)

    local menu = {}
    for _, id in ipairs(sectionIds) do
      table.insert(menu, AL_SECTIONS[id])
    end

    local choice = gfx.showmenu(table.concat(menu, '|'))
    if choice > 0 then
      commandIdField.value = nil
      actionNameField.value = nil
      return true, sectionIds[choice]
    end
  end,
  displayValue = function(value)
    return AL_SECTIONS[value]
  end,
}

commandIdField = {
  label = 'Command ID:',
  setValue = function(field)
    local retval, newValue = defaultSetValue(field)
    if retval then
      actionNameField.value = nil
      newValue = reaper.NamedCommandLookup(newValue)
      return retval, newValue
    end
  end,
}

actionNameField = {
  label = 'Action name:',
  setValue = function(field)
    local retval, newValue = defaultSetValue(field)
    if retval then
      commandIdField.value = nil
      return retval, newValue
    end
  end,
}

copyCommandId = {
  label = 'Copy command ID',
  onclick = function()
    reaper.CF_SetClipboard(commandIdField.value)
  end,
}

copyActionName = {
  label = 'Copy action name',
  onclick = function()
    reaper.CF_SetClipboard(actionNameField.value)
  end,
}

fields = {sectionField, commandIdField, actionNameField}
controls = {copyActionName, copyCommandId}

scriptName = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
gfx.init(scriptName, 400, 125)

if reaper.GetAppVersion():match('OSX') then
  gfx.setfont(1, 'sans-serif', 12)
else
  gfx.setfont(1, 'sans-serif', 15)
end

loop()

-- @version 0.2
-- @author cfillion
-- @changelog
--   + enhance formatting of arrays containing nil values
--   + implement Delete key
--   + implement word movement keys (Shift+Left and Shift+Right)
--   + imply the return statement by default
--   + limit maximum depth when formatting tables
--   + protect against overriding of built-in variables
--
-- Send patches at <https://github.com/cfillion/reascripts>.

local string, table, math, os, reaper, gfx = string, table, math, os, reaper, gfx
local load, xpcall, pairs, ipairs = load, xpcall, pairs, ipairs

local ireascript = {
  -- settings
  TITLE = 'Interactive ReaScript',
  BANNER = 'Interactive ReaScript v0.2 by cfillion',
  MARGIN = 3,
  MAXLINES = 1024,
  MAXDEPTH = 3,
  INDENT = 2,
  INDENT_THRESHOLD = 5,
  PROMPT = '> ',
  PREFIX = '.',

  COLOR_BLACK = {12, 12, 12},
  COLOR_BLUE = {88, 124, 212},
  COLOR_DEFAULT = {190, 190, 190},
  COLOR_GREEN = {90, 173, 87},
  COLOR_MAGENTA = {175, 95, 95},
  COLOR_ORANGE = {255, 93, 40},
  COLOR_RED = {255, 85, 85},
  COLOR_WHITE = {255, 255, 255},
  COLOR_YELLOW = {199, 199, 0},
  COLOR_SCROLL = {190, 190, 190},

  -- internal constants
  SG_NEWLINE = 1,
  SG_CURSOR = 2,

  FONT_NORMAL = 1,
  FONT_BOLD = 2,

  KEY_BACKSPACE = 8,
  KEY_CLEAR = 144,
  KEY_CTRLD = 4,
  KEY_CTRLL = 12,
  KEY_CTRLU = 21,
  KEY_DELETE = 6579564,
  KEY_DOWN = 1685026670,
  KEY_END = 6647396,
  KEY_ENTER = 13,
  KEY_HOME = 1752132965,
  KEY_INPUTRANGE_FIRST = 32,
  KEY_INPUTRANGE_LAST = 125,
  KEY_LEFT = 1818584692,
  KEY_RIGHT = 1919379572,
  KEY_UP = 30064,
}

function ireascript.help()
  ireascript.resetFormat()
  ireascript.push('Built-in commands:')
  ireascript.nl()

  local colWidth = 8

  for i,command in ipairs(ireascript.BUILTIN) do
    local spaces = string.rep(' ', colWidth - command.name:len())

    ireascript.foreground = ireascript.COLOR_WHITE
    ireascript.push(string.format('.%s', command.name))

    ireascript.resetFormat()
    ireascript.push(spaces .. command.desc)

    ireascript.nl()
  end
end

function ireascript.clear()
  ireascript.reset(false)
  ireascript.update()
end

function ireascript.replay()
  local line = ireascript.history[1]
  if line and line ~= ireascript.PREFIX then
    ireascript.input = line
    ireascript.eval()
  else
    ireascript.errorFormat()
    ireascript.push('history is empty')
  end
end

function ireascript.exit()
  gfx.quit()
end

ireascript.BUILTIN = {
  {name='clear', desc="Clear the line buffer", func=ireascript.clear},
  {name='exit', desc="Close iReaScript", func=ireascript.exit},
  {name='', desc="Repeat the last command", func=ireascript.replay},
  {name='help', desc="Print this help text", func=ireascript.help},
}

function ireascript.reset(banner)
  ireascript.buffer = {}
  ireascript.wrappedBuffer = {w = 0}
  ireascript.input = ''
  ireascript.lines = 0
  ireascript.cursor = 0
  ireascript.history = {}
  ireascript.hindex = 0
  ireascript.scroll = 0

  if banner then
    ireascript.resetFormat()
    ireascript.push(ireascript.BANNER)
    ireascript.nl()
    ireascript.push("Type Lua code or .help")
    ireascript.nl()
  end

  ireascript.prompt()
end

function ireascript.keyboard()
  local char = gfx.getchar()

  if char < 0 then
    -- bye bye!
    return false
  end

  -- if char ~= 0 then
  --   reaper.ShowConsoleMsg(char)
  --   reaper.ShowConsoleMsg("\n")
  -- end

  if char == ireascript.KEY_BACKSPACE then
    local before, after = ireascript.splitInput()
    ireascript.input = string.sub(before, 0, -2) .. after
    ireascript.moveCursor(ireascript.cursor - 1)
    ireascript.prompt()
  elseif char == ireascript.KEY_DELETE then
    local before, after = ireascript.splitInput()
    ireascript.input = before .. string.sub(after, 2)
    ireascript.scrollTo(0)
    ireascript.prompt()
  elseif char == ireascript.KEY_CLEAR then
    ireascript.input = ''
    ireascript.moveCursor(0)
    ireascript.prompt()
  elseif char == ireascript.KEY_CTRLU then
    local before, after = ireascript.splitInput()
    ireascript.input = after
    ireascript.moveCursor(0)
    ireascript.prompt()
  elseif char == ireascript.KEY_ENTER then
    ireascript.removeCursor()
    ireascript.nl()
    if ireascript.input:len() > 0 then
      ireascript.eval()
      ireascript.input = ''
      ireascript.hindex = 0
    end
    ireascript.moveCursor(0)
  elseif char == ireascript.KEY_CTRLL then
    ireascript.clear()
  elseif char == ireascript.KEY_CTRLD then
    ireascript.exit()
  elseif char == ireascript.KEY_HOME then
    ireascript.moveCursor(0)
  elseif char == ireascript.KEY_LEFT then
    local pos

    if gfx.mouse_cap & 8 == 8 then
      local length = ireascript.input:len()
      pos = length - ireascript.nextBoundary(ireascript.input:reverse(),
        length - ireascript.cursor + 1)
      if pos > 0 then pos = pos + 1 end
    else
      pos = ireascript.cursor - 1
    end

    ireascript.moveCursor(pos)
  elseif char == ireascript.KEY_RIGHT then
    local pos

    if gfx.mouse_cap & 8 == 8 then
      pos = ireascript.nextBoundary(ireascript.input, ireascript.cursor)
    else
      pos = ireascript.cursor + 1
    end

    ireascript.moveCursor(pos)
  elseif char == ireascript.KEY_END then
    ireascript.moveCursor(ireascript.input:len())
  elseif char == ireascript.KEY_UP then
    ireascript.historyJump(ireascript.hindex + 1)
  elseif char == ireascript.KEY_DOWN then
    ireascript.historyJump(ireascript.hindex - 1)
  elseif char >= ireascript.KEY_INPUTRANGE_FIRST and char <= ireascript.KEY_INPUTRANGE_LAST then
    local before, after = ireascript.splitInput()
    ireascript.input = before .. string.char(char) .. after
    ireascript.moveCursor(ireascript.cursor + 1)
    ireascript.prompt()
  end

  return true
end

function ireascript.nextBoundary(input, from)
  local boundary = input:find('%W%w', from + 1)

  if boundary then
    return boundary
  else
    return input:len()
  end
end

function ireascript.draw()
  ireascript.useColor(ireascript.COLOR_BLACK)
  gfx.rect(0, 0, gfx.w, gfx.h)

  gfx.x = ireascript.MARGIN
  gfx.y = ireascript.MARGIN + (ireascript.drawOffset or 0)

  local lines, lineHeight, cursor = {}, ireascript.MARGIN, nil

  for i=1,#ireascript.wrappedBuffer do
    local segment = ireascript.wrappedBuffer[i]

    if segment == ireascript.SG_NEWLINE then
      gfx.x = ireascript.MARGIN
      gfx.y = gfx.y + lineHeight

      lines[#lines + 1] = lineHeight
      lineHeight = 0
    elseif segment == ireascript.SG_CURSOR then
      if os.time() % 2 == 0 then
        cursor = {x=gfx.x, y=gfx.y, h=lineHeight}
      end
    elseif gfx.y < -segment.h or gfx.y > gfx.h then
      lineHeight = math.max(lineHeight, segment.h)
    else
      ireascript.useFont(segment.font)

      ireascript.useColor(segment.bg)
      gfx.rect(gfx.x, gfx.y, segment.w, segment.h)

      ireascript.useColor(segment.fg)

      gfx.drawstr(segment.text)
      lineHeight = math.max(lineHeight, segment.h)
    end
  end

  lines[#lines + 1] = lineHeight -- last line

  if cursor then
    gfx.line(cursor.x, cursor.y, cursor.x, cursor.y + cursor.h)
  end

  local height = ireascript.MARGIN
  ireascript.scroll = math.max(0, math.min(ireascript.scroll, #lines))
  for i=1,#lines - ireascript.scroll do
    height = height + lines[i]
  end

  ireascript.drawOffset = gfx.h - height

  if ireascript.drawOffset > 0 then
    -- allow the first line to be completely visible, but not anything above that
    if ireascript.drawOffset > lines[1] then
      local extra = lines[1]

      for i=1,#lines do
        ireascript.scroll = ireascript.scroll - 1
        extra = extra + lines[i]

        if extra > ireascript.drawOffset then
          break
        end
      end
    end

    ireascript.drawOffset = 0
  end

  local before = math.abs(ireascript.drawOffset)
  local after = 0
  for i=(#lines-ireascript.scroll)+1,#lines do
    if lines[i] then
      after = after + lines[i]
    end
  end

  ireascript.scrollbar(before, after)
end

function ireascript.scrollbar(before, after)
  local total = before + gfx.h + after
  local visible = gfx.h / total

  if visible == 1 then
    return
  end

  local width, rawHeight = 4, gfx.h * visible - (ireascript.MARGIN * 2)
  local height = math.max(20, rawHeight)
  local scale = 1 - (math.abs(height - rawHeight) / gfx.h)

  local left = gfx.w - ireascript.MARGIN - width
  local top = ireascript.MARGIN + (before * visible * scale)

  ireascript.useColor(ireascript.COLOR_SCROLL)
  gfx.rect(left, top, width, height)
end

function ireascript.update()
  if gfx.w < 1 then
    return -- gui is not ready yet
  end

  ireascript.wrappedBuffer = {}
  ireascript.wrappedBuffer.w = gfx.w

  local leftmost = ireascript.MARGIN
  local left = leftmost

  for i=1,#ireascript.buffer do
    local segment = ireascript.buffer[i]

    if type(segment) ~= 'table' then
      ireascript.wrappedBuffer[#ireascript.wrappedBuffer + 1] = segment

      if segment == ireascript.SG_NEWLINE then
        left = leftmost
      end
    else
      ireascript.useFont(segment.font)

      local text = segment.text

      while text:len() > 0 do
        local w, h = gfx.measurestr(text)
        local count = segment.text:len()
        local resized = false

        resizeBy = function(chars)
          count = count - chars
          w, h = gfx.measurestr(segment.text:sub(0, count))
          resized = true
        end

        -- rough first try for speed
        local overflow = (w + left) - gfx.w
        if overflow > 0 then
          local firstCharWidth, _ = gfx.measurestr(segment.text:sub(0, 1))
          resizeBy(math.floor(overflow / firstCharWidth))
        end

        while w + left > gfx.w do
          resizeBy(1)
        end

        left = left + w

        local newSeg = ireascript.dup(segment)
        newSeg.text = text:sub(0, count)
        newSeg.w = w
        newSeg.h = h
        ireascript.wrappedBuffer[#ireascript.wrappedBuffer + 1] = newSeg

        if resized then
          ireascript.wrappedBuffer[#ireascript.wrappedBuffer + 1] = ireascript.SG_NEWLINE
          left = leftmost
        end

        text = text:sub(count + 1)
      end
    end
  end
end

function ireascript.loop()
  if ireascript.keyboard() then
    reaper.defer(ireascript.loop)
  end

  if gfx.mouse_wheel ~= 0 then
    local lines = math.ceil(math.abs(gfx.mouse_wheel) / 24)

    if gfx.mouse_wheel > 0 then
      ireascript.scrollTo(ireascript.scroll + lines)
    else
      ireascript.scrollTo(ireascript.scroll - lines)
    end

    gfx.mouse_wheel = 0
  end

  if ireascript.wrappedBuffer.w ~= gfx.w then
    ireascript.update()
  end

  ireascript.draw()

  gfx.update()
end

function ireascript.resetFormat()
  ireascript.font = ireascript.FONT_NORMAL
  ireascript.foreground = ireascript.COLOR_DEFAULT
  ireascript.background = ireascript.COLOR_BLACK
end

function ireascript.errorFormat()
  ireascript.font = ireascript.FONT_BOLD
  ireascript.foreground = ireascript.COLOR_WHITE
  ireascript.background = ireascript.COLOR_RED
end

function ireascript.nl()
  if ireascript.lines >= ireascript.MAXLINES then
    local first = ireascript.buffer[1]

    while first ~= nil do
      table.remove(ireascript.buffer, 1)

      if first == ireascript.SG_NEWLINE then
        break
      end

      first = ireascript.buffer[1]
    end
  else
    ireascript.lines = ireascript.lines + 1
  end

  ireascript.buffer[#ireascript.buffer + 1] = ireascript.SG_NEWLINE
end

function ireascript.push(contents)
  if contents == nil then
    error('content is nil')
  end

  ireascript.buffer[#ireascript.buffer + 1] = {
    font=ireascript.font,
    fg=ireascript.foreground, bg=ireascript.background,
    text=contents,
  }
end

function ireascript.prompt()
  local before, after = ireascript.splitInput()

  ireascript.resetFormat()
  ireascript.backtrack()
  ireascript.push(ireascript.PROMPT)
  ireascript.push(before)
  ireascript.buffer[#ireascript.buffer + 1] = ireascript.SG_CURSOR
  ireascript.push(after)
  ireascript.update()
end

function ireascript.backtrack()
  local i = #ireascript.buffer
  while i >= 1 do
    if ireascript.buffer[i] == ireascript.SG_NEWLINE then
      return
    end

    table.remove(ireascript.buffer)
    i = i - 1
  end
end

function ireascript.removeCursor()
  local i = #ireascript.buffer
  while i >= 1 do
    local segment = ireascript.buffer[i]

    if segment == ireascript.SG_NEWLINE then
      return
    elseif segment == ireascript.SG_CURSOR then
      table.remove(ireascript.buffer, i)
    end

    i = i - 1
  end
end

function ireascript.moveCursor(pos)
  ireascript.scrollTo(0)

  if pos >= 0 and pos <= ireascript.input:len() then
    ireascript.cursor = pos
    ireascript.prompt()
  end
end

function ireascript.historyJump(pos)
  if pos < 0 or pos > #ireascript.history then
    return
  elseif ireascript.hindex == 0 then
    ireascript.history[0] = ireascript.input
  end

  ireascript.hindex = pos
  ireascript.input = ireascript.history[ireascript.hindex]
  ireascript.moveCursor(ireascript.input:len())
  ireascript.prompt()
end

function ireascript.scrollTo(pos)
  ireascript.scroll = pos
  -- more calculations, bould checking and adjustments done by update()
end

function ireascript.eval()
  local prefixLength = ireascript.PREFIX:len()
  if ireascript.input:sub(0, prefixLength) == ireascript.PREFIX then
    local name = ireascript.input:sub(prefixLength + 1)
    local match, lower = nil, name:lower()

    for _,command in ipairs(ireascript.BUILTIN) do
      if command.name == lower then
        match = command
        break
      end
    end

    if match then
      match.func()

      if ireascript.input:len() == 0 then
        return -- buffer got reset
      end
    else
      ireascript.errorFormat()
      ireascript.push(string.format("command not found: '%s'", name))
    end
  elseif ireascript.input:len() > 0 then
    local err = ireascript.lua(ireascript.input)

    if err then
      ireascript.errorFormat()
      ireascript.push(err)
    else
      reaper.TrackList_AdjustWindows(false)
      reaper.UpdateArrange()
    end
  end

  ireascript.nl()
  table.insert(ireascript.history, 1, ireascript.input)
end

function ireascript.lua(code)
  local scope = 'eval' -- arbitrary value to have consistent error messages

  local ok, values = xpcall(function()
    local func, err = load('return ' .. code, scope)

    if not func then
      -- hack: reparse without the implicit return
      func, err = load(code, scope)
    end

    if func then
      return {func()}
    else
      error(err, 2)
    end
  end, function(err)
    return err
  end)

  if ok then
    if #values <= 1 then
      ireascript.format(values[1])
    else
      ireascript.format(values)
    end
  else
    return values:sub(20)
  end
end

function ireascript.format(value)
  ireascript.resetFormat()

  local t = type(value)

  if t == 'table' then
    local i, array, last = 0, #value > 0, 0

    for k,v in pairs(value) do
      if tonumber(k) then
        i = i + (k - last) - 1
        last = k
      else
        array = false
      end

      i = i + 1
    end

    if ireascript.flevel == nil then
      ireascript.flevel = 1
    elseif ireascript.flevel >= ireascript.MAXDEPTH then
      ireascript.errorFormat()
      ireascript.push('...')
      return
    else
      ireascript.flevel = ireascript.flevel + 1
    end

    if array then
      ireascript.formatArray(value, i)
    else
      ireascript.formatTable(value, i)
    end

    ireascript.flevel = ireascript.flevel - 1

    return
  elseif value == nil then
    ireascript.foreground = ireascript.COLOR_YELLOW
  elseif t == 'number' or t == 'boolean' then
    ireascript.foreground = ireascript.COLOR_BLUE
  elseif t == 'function' or t == 'userdata' then
    ireascript.foreground = ireascript.COLOR_MAGENTA
    value = string.format('<%s>', value)
  elseif t == 'string' then
    ireascript.foreground = ireascript.COLOR_GREEN
    value = string.format('"%s"',
      value:gsub('\\', '\\\\'):gsub("\n", '\\n'):gsub('"', '\\"')
    )
  end

  ireascript.push(tostring(value))
end

function ireascript.formatArray(value, size)
  ireascript.push('[')

  for i=1,size do
    local v = value[i]
    if i > 1 then
      ireascript.resetFormat()
      ireascript.push(', ')
    end

    ireascript.format(v)
    i = i + 1
  end

  ireascript.resetFormat()
  ireascript.push(']')
end

function ireascript.formatTable(value, size)
  local i, indent = 1, size > ireascript.INDENT_THRESHOLD

  if indent then
    if ireascript.ilevel == nil then
      ireascript.ilevel = 1
    else
      ireascript.ilevel = ireascript.ilevel + 1
    end
  end

  local doIndent = function()
    ireascript.nl()
    ireascript.push(string.rep(' ', ireascript.INDENT * ireascript.ilevel))
  end

  ireascript.push('{')
  if indent then
    doIndent()
  end

  for k,v in pairs(value) do
    if i > 1 then
      ireascript.resetFormat()

      if indent then
        ireascript.push(',')
        doIndent()
      else
        ireascript.push(', ')
      end
    end

    ireascript.format(k)
    ireascript.resetFormat()
    ireascript.push('=')
    ireascript.format(v)

    i = i + 1
  end

  ireascript.resetFormat()

  if indent then
    ireascript.push(',')
    ireascript.ilevel = ireascript.ilevel - 1
    doIndent()
  end

  ireascript.push('}')
end

function ireascript.splitInput()
  local before = ireascript.input:sub(0, ireascript.cursor)
  local after = ireascript.input:sub(ireascript.cursor + 1)
  return before, after
end

function ireascript.useFont(font)
  if ireascript.currentFont ~= font then
    gfx.setfont(font)
    ireascript.currentFont = font
  end
end

function ireascript.useColor(color)
  gfx.r = color[1] / 255
  gfx.g = color[2] / 255
  gfx.b = color[3] / 255
end

function ireascript.dup(table)
  local copy = {}
  for k,v in pairs(table) do copy[k] = v end
  return copy
end

ireascript.reset(true)

gfx.init(ireascript.TITLE, 550, 350)
gfx.setfont(ireascript.FONT_NORMAL, 'Courier', 14)
gfx.setfont(ireascript.FONT_BOLD, 'Courier', 14, 'b')

-- GO!!
ireascript.loop()

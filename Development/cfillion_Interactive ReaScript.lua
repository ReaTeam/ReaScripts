-- @version 0.6.1
-- @author cfillion
-- @changelog
--   fix division by zero when wrapping lines starting with a zero-length character
--   fix invisible \t (tabs) on windows
--   fix ugly font on windows
-- @description Interactive ReaScript (iReaScript)
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=177324
-- @donation https://www.paypal.me/cfillion
-- @screenshot http://i.imgur.com/RrGfulR.gif
-- @about
--   # Interactive ReaScript (iReaScript)
--
--   This script simulates a [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)
--   shell for Lua ReaScript inside of REAPER, for quickly experimenting code and API functions.
--
--   ## Screenshot
--
--   http://i.imgur.com/RrGfulR.gif
--
--   ## Main Features
--
--   - Autocompletion
--   - Code history
--   - Colored output
--   - Copy/Paste from clipboard
--   - Error catching
--   - Multiline input (functions, conditions...)
--   - Pretty print return values
--   - Scrolling
--   - Text wrapping
--   - Run actions (!command_id, !!midi_editor_action)
--
--   ## Known Issues/Limitations
--
--   - Some errors cannot be caught (see http://forum.cockos.com/showthread.php?t=177319)
--   - This tool cannot be used to open a new GFX window
--
--   ## Contributing
--
--   Send patches at <https://github.com/cfillion/reascripts>.

local string, table, math, os = string, table, math, os
local load, xpcall, pairs, ipairs = load, xpcall, pairs, ipairs, select

local ireascript = {
  -- settings
  TITLE = 'Interactive ReaScript',
  VERSION = '0.6.1',

  MARGIN = 3,
  MAXLINES = 2048,
  MAXDEPTH = 3, -- maximum array depth
  MAXLEN = 1024, -- maximum array size
  INDENT = 2,
  INDENT_THRESHOLD = 5,
  PROMPT = '> ',
  PROMPT_CONTINUE = '*> ',
  CMD_PREFIX = '.',
  ACTION_PREFIX = '!',

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
  SG_BUFNEWLINE = 2,

  FONT_NORMAL = 1,
  FONT_BOLD = 2,

  EMPTY_LINE_HEIGHT = 14,

  KEY_BACKSPACE = 8,
  KEY_CLEAR = 144,
  KEY_CTRLC = 3,
  KEY_CTRLD = 4,
  KEY_CTRLL = 12,
  KEY_CTRLU = 21,
  KEY_CTRLV = 22,
  KEY_DELETE = 6579564,
  KEY_DOWN = 1685026670,
  KEY_END = 6647396,
  KEY_ENTER = 13,
  KEY_HOME = 1752132965,
  KEY_INPUTRANGE_FIRST = 32,
  KEY_INPUTRANGE_LAST = 126,
  KEY_LEFT = 1818584692,
  KEY_PGDOWN = 1885824110,
  KEY_PGUP = 1885828464,
  KEY_RIGHT = 1919379572,
  KEY_TAB = 9,
  KEY_UP = 30064,

  EXT_SECTION = 'cfillion_ireascript',
  EXT_WINDOW_STATE = 'window_state',
  EXT_LAST_DOCK = 'last_dock',
}

print = function(...)
  for i=1,select('#', ...) do
    if i > 1 then ireascript.push("\t") end
    ireascript.format(select(i, ...))
  end
  ireascript.nl()
end

function ireascript.help()
  function helpLine(name, desc, colWidth)
    local spaces = string.rep(' ', (colWidth - name:len()) + 1)
    ireascript.highlightFormat()
    ireascript.push(name)
    ireascript.resetFormat()
    ireascript.push(spaces .. desc)
    ireascript.nl()
  end

  ireascript.resetFormat()
  ireascript.push('Built-in commands:\n')

  for i,command in ipairs(ireascript.BUILTIN) do
    helpLine(string.format('.%s', command.name), command.desc, 7)
  end

  ireascript.nl()
  ireascript.push('Built-in functions and variables:\n')
  helpLine("print(...)", "Print any number of values", 11)
  helpLine("_", "Last return value", 11)
end

function ireascript.replay()
  local line = ireascript.history[1]
  if line and line ~= ireascript.CMD_PREFIX then
    ireascript.input = line
    ireascript.eval(true)
  else
    ireascript.errorFormat()
    ireascript.push('history is empty')
  end
end

function ireascript.exit()
  gfx.quit()
end

function ireascript.reset(banner)
  ireascript.buffer = {}
  ireascript.lines = 0
  ireascript.page = 0
  ireascript.scroll = 0
  ireascript.wrappedBuffer = {w = 0}
  ireascript.from = nil

  if banner then
    ireascript.resetFormat()

    ireascript.push(string.format('%s v%s by cfillion\n',
      ireascript.TITLE, ireascript.VERSION))
    ireascript.push('Type Lua code, !ACTION or .help\n')
  end

  ireascript.prompt()
end

ireascript.BUILTIN = {
  {name='clear', desc="Clear the line buffer", func=ireascript.reset},
  {name='exit', desc="Close iReaScript", func=ireascript.exit},
  {name='', desc="Repeat the last command", func=ireascript.replay},
  {name='help', desc="Print this help text", func=ireascript.help},
}

function ireascript.run()
  ireascript.input = ''
  ireascript.prepend = ''
  ireascript.caret = 0
  ireascript.history = {}
  ireascript.hindex = 0
  ireascript.lastMove = os.time()
  ireascript.mouse_cap = 0

  ireascript.reset(true)
  ireascript.loop()
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
    ireascript.moveCaret(ireascript.caret - 1)
  elseif char == ireascript.KEY_DELETE then
    local before, after = ireascript.splitInput()
    ireascript.input = before .. string.sub(after, 2)
    ireascript.scrollTo(0)
    ireascript.prompt()
  elseif char == ireascript.KEY_CLEAR then
    ireascript.input = ''
    ireascript.moveCaret(0)
  elseif char == ireascript.KEY_CTRLU then
    local before, after = ireascript.splitInput()
    ireascript.input = after
    ireascript.moveCaret(0)
  elseif char == ireascript.KEY_ENTER then
    ireascript.removeCaret()
    ireascript.nl()
    ireascript.eval()
    ireascript.moveCaret(0)
  elseif char == ireascript.KEY_CTRLL then
    ireascript.reset()
  elseif char == ireascript.KEY_CTRLD then
    ireascript.exit()
  elseif char == ireascript.KEY_HOME then
    ireascript.moveCaret(0)
  elseif char == ireascript.KEY_LEFT then
    local pos

    if gfx.mouse_cap & 8 == 8 then
      local length = ireascript.input:len()
      pos = length - ireascript.nextBoundary(ireascript.input:reverse(),
        length - ireascript.caret + 1)
      if pos > 0 then pos = pos + 1 end
    else
      pos = ireascript.caret - 1
    end

    ireascript.moveCaret(pos)
  elseif char == ireascript.KEY_RIGHT then
    local pos

    if gfx.mouse_cap & 8 == 8 then
      pos = ireascript.nextBoundary(ireascript.input, ireascript.caret)
    else
      pos = ireascript.caret + 1
    end

    ireascript.moveCaret(pos)
  elseif char == ireascript.KEY_END then
    ireascript.moveCaret(ireascript.input:len())
  elseif char == ireascript.KEY_UP then
    ireascript.historyJump(ireascript.hindex + 1)
  elseif char == ireascript.KEY_DOWN then
    ireascript.historyJump(ireascript.hindex - 1)
  elseif char == ireascript.KEY_PGUP then
    ireascript.scrollTo(ireascript.scroll + ireascript.page)
  elseif char == ireascript.KEY_PGDOWN then
    ireascript.scrollTo(ireascript.scroll - ireascript.page)
  elseif char == ireascript.KEY_CTRLC then
    ireascript.copy()
  elseif char == ireascript.KEY_CTRLV then
    ireascript.paste()
  elseif char == ireascript.KEY_TAB then
    ireascript.complete()
  elseif char >= ireascript.KEY_INPUTRANGE_FIRST and char <= ireascript.KEY_INPUTRANGE_LAST then
    local before, after = ireascript.splitInput()
    ireascript.input = before .. string.char(char) .. after
    ireascript.moveCaret(ireascript.caret + 1)
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

function ireascript.draw(offset)
  ireascript.useColor(ireascript.COLOR_BLACK)
  gfx.rect(0, 0, gfx.w, gfx.h)

  gfx.x = ireascript.MARGIN
  gfx.y = gfx.h - (offset or 0)

  local lineEnd = #ireascript.wrappedBuffer
  local nl = lineEnd + 1 -- past the end of the buffer
  local lines, lineHeight = 0, 0
  local lastSkipped, before, after = nil, 0, 0

  ireascript.page = 0

  while nl > 0 do
    lineHeight = 0

    while nl > 0 do
      local segment = ireascript.wrappedBuffer[nl]

      if type(segment) == 'table' then
        lineHeight = math.max(lineHeight, segment.h)
      elseif segment == ireascript.SG_NEWLINE then
        if lineHeight == 0 then
          lineHeight = ireascript.EMPTY_LINE_HEIGHT
        end
        break
      end

      nl = nl - 1
    end

    local lineStart = nl + 1

    lines = lines + 1

    if lines > ireascript.scroll then
      gfx.x, gfx.y = ireascript.MARGIN, gfx.y - lineHeight

      if gfx.y > 0 then
        -- only count 100% visible lines
        ireascript.page = ireascript.page + 1
        ireascript.drawLine(lineStart, lineEnd, lineHeight)
      elseif gfx.y > -lineHeight then
        -- partially visible line at the top
        before = before + math.abs(gfx.y)
        ireascript.drawLine(lineStart, lineEnd, lineHeight)
      else
        before = before + lineHeight
      end
    else
      after = after + lineHeight
      lastSkipped = {lineStart, lineEnd, lineHeight}
    end

    lineEnd = nl - 1
    nl = lineEnd
  end

  if offset then
    if lastSkipped then
      -- draw incomplete line below scrolling
      lineStart, lineEnd = lastSkipped[1], lastSkipped[2]
      gfx.x, gfx.y = ireascript.MARGIN, gfx.h - offset
      after = after - (lastSkipped[3] - offset)
      ireascript.drawLine(lineStart, lineEnd, lastSkipped[3])
    end

    -- simulate how many lines would be needed to fill the window
    ireascript.page = ireascript.page + math.floor(offset / lineHeight)
  elseif gfx.y > ireascript.MARGIN then
    -- the window is not full, redraw aligned to the top
    return ireascript.draw(gfx.y - ireascript.MARGIN)
  end

  ireascript.scrollbar(before, after)
end

function ireascript.drawLine(lineStart, lineEnd, lineHeight)
  local now = os.time()

  for i=lineStart,lineEnd do
    local segment = ireascript.wrappedBuffer[i]

    if type(segment) == 'table' then
      ireascript.useFont(segment.font)

      ireascript.useColor(segment.bg)
      gfx.rect(gfx.x, gfx.y, segment.w, segment.h)

      ireascript.useColor(segment.fg)

      if segment.caret and (now % 2 == 0 or now - ireascript.lastMove < 1) then
        local w, _ = gfx.measurestr(segment.text:sub(0, segment.caret))
        ireascript.drawCaret(gfx.x + w, gfx.y, lineHeight)
      end

      gfx.drawstr(segment.text)
    end
  end
end

function ireascript.drawCaret(x, y, h)
  gfx.line(x, y, x, y + h)
end

function ireascript.scrollbar(before, after)
  local total = before + gfx.h + after
  local visible = gfx.h / total

  if visible >= 1 then
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

  if not ireascript.from or ireascript.from.wrapped <= 1 then
    ireascript.wrappedBuffer = {lines=0}
    ireascript.from = {buffer=1}
  else
    while #ireascript.wrappedBuffer > ireascript.from.wrapped do
      if ireascript.wrappedBuffer[#ireascript.wrappedBuffer] == ireascript.SG_NEWLINE then
        ireascript.wrappedBuffer.lines = ireascript.wrappedBuffer.lines - 1
      end

      table.remove(ireascript.wrappedBuffer)
    end
  end

  ireascript.wrappedBuffer.w = gfx.w

  local leftmost = ireascript.MARGIN
  local left = leftmost

  for i=ireascript.from.buffer,#ireascript.buffer do
    local segment = ireascript.buffer[i]

    if type(segment) ~= 'table' then
      ireascript.wrappedBuffer[#ireascript.wrappedBuffer + 1] = segment

      if segment == ireascript.SG_NEWLINE then
        -- insert buffer newline marker before the display newline
        table.insert(ireascript.wrappedBuffer,
          #ireascript.wrappedBuffer, ireascript.SG_BUFNEWLINE)
        ireascript.wrappedBuffer.lines = ireascript.wrappedBuffer.lines + 1
        left = leftmost
      end
    else
      ireascript.useFont(segment.font)

      local text = segment.text
      local caret = segment.caret
      local startpos = 0

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
          local firstCharWidth, _ = gfx.measurestr(segment.text:match("%w"))
          if firstCharWidth > 0 then
            resizeBy(math.floor(overflow / firstCharWidth))
          end
        end

        while w + left > gfx.w do
          resizeBy(1)
        end

        left = left + w

        local newSeg = ireascript.dup(segment)
        newSeg.text = text:sub(0, count)
        newSeg.w = w
        newSeg.h = h

        if caret and caret >= startpos and
            (caret < startpos + count or not resized) then
          newSeg.caret = caret - startpos
        else
          newSeg.caret = nil
        end

        ireascript.wrappedBuffer[#ireascript.wrappedBuffer + 1] = newSeg

        if resized then
          ireascript.wrappedBuffer[#ireascript.wrappedBuffer + 1] = ireascript.SG_NEWLINE
          ireascript.wrappedBuffer.lines = ireascript.wrappedBuffer.lines + 1
          left = leftmost
        end

        text = text:sub(count + 1)
        startpos = startpos + count
      end
    end
  end

  ireascript.from = {buffer=#ireascript.buffer + 1, wrapped=#ireascript.wrappedBuffer + 1}
end

function ireascript.contextMenu()
  local dockState = gfx.dock(-1)
  local dockFlag = ''
  if dockState > 0 then dockFlag = '!' end

  local menu = string.format(
    'Copy (^C)|Paste (^V)||Clear (^L)||%sDock window|Close iReaScript (^D)',
    dockFlag
  )

  local actions = {
    ireascript.copy, ireascript.paste,
    function() ireascript.reset() end,
    function()
      if dockState == 0 then
        local lastDock = tonumber(reaper.GetExtState(
          ireascript.EXT_SECTION, ireascript.EXT_LAST_DOCK))
        if not lastDock or lastDock < 1 then lastDock = 1 end

        gfx.dock(lastDock)
      else
        reaper.SetExtState(ireascript.EXT_SECTION, ireascript.EXT_LAST_DOCK,
          tostring(dockState), true)
        gfx.dock(0)
      end
    end,
    ireascript.exit,
  }

  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local index = gfx.showmenu(menu)
  if actions[index] then actions[index]() end
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

  if gfx.mouse_cap ~= ireascript.mouse_cap then
    if gfx.mouse_cap & 2 == 0 and ireascript.mouse_cap & 2 == 2 then
      ireascript.contextMenu()
    end

    ireascript.mouse_cap = gfx.mouse_cap
  end

  if ireascript.wrappedBuffer.w ~= gfx.w then
    ireascript.from = nil -- full reflow
    ireascript.update()
  end

  ireascript.draw()
  ireascript.scrollTo(ireascript.scroll) -- refreshed bound check

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

function ireascript.highlightFormat()
  ireascript.font = ireascript.FONT_BOLD
  ireascript.foreground = ireascript.COLOR_WHITE
  ireascript.background = ireascript.COLOR_BLACK
end

function ireascript.nl()
  if ireascript.lines >= ireascript.MAXLINES then
    local buf = ireascript.removeUntil(ireascript.buffer, ireascript.SG_NEWLINE)
    local wrap, nlCount = ireascript.removeUntil(ireascript.wrappedBuffer, ireascript.SG_BUFNEWLINE)

    ireascript.wrappedBuffer.lines = ireascript.wrappedBuffer.lines - nlCount

    if ireascript.from then
      ireascript.from.buffer = ireascript.from.buffer - buf
      ireascript.from.wrapped = ireascript.from.wrapped - wrap
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

  local index = 0

  for line in ireascript.each_lines(contents) do
    if index > 0 then ireascript.nl() end
    index = index + 1

    if line:len() > 0 then -- skip empty lines
      ireascript.buffer[#ireascript.buffer + 1] = {
        font=ireascript.font,
        fg=ireascript.foreground, bg=ireascript.background,
        text=line:gsub("\t", string.rep("\x20", ireascript.INDENT)),
      }
    end
  end
end

function ireascript.prompt()
  ireascript.resetFormat()
  ireascript.backtrack()
  if ireascript.prepend:len() == 0 then
    ireascript.push(ireascript.PROMPT)
  else
    ireascript.push(ireascript.PROMPT_CONTINUE)
  end

  if ireascript.input:len() > 0 then
    ireascript.push(ireascript.input)
    ireascript.buffer[#ireascript.buffer].caret = ireascript.caret
  else
    local promptLen = ireascript.buffer[#ireascript.buffer].text:len()
    ireascript.buffer[#ireascript.buffer].caret = promptLen
  end

  ireascript.update()
end

function ireascript.backtrack()
  local bi = #ireascript.buffer
  while bi > 0 do
    if ireascript.buffer[bi] == ireascript.SG_NEWLINE then
      break
    end

    table.remove(ireascript.buffer)
    bi = bi - 1
  end

  if ireascript.from and ireascript.from.buffer > bi then
    ireascript.from.buffer = bi

    local wi = #ireascript.wrappedBuffer
    while wi > 0 do
      if ireascript.wrappedBuffer[wi] == ireascript.SG_BUFNEWLINE then
        break
      end

      wi = wi - 1
    end

    ireascript.from.wrapped = wi - 1
  end
end

function ireascript.removeCaret()
  ireascript.buffer[#ireascript.buffer].caret = nil

  local wi = #ireascript.wrappedBuffer
  while wi > 0 do
    local segment = ireascript.wrappedBuffer[wi]

    if segment == ireascript.SG_BUFNEWLINE then
      break
    elseif type(segment) == 'table' then
      segment.caret = nil
    end

    wi = wi - 1
  end
end

function ireascript.removeUntil(buf, sep)
  local first, count, nl = buf[1], 0, 0

  while first ~= nil do
    table.remove(buf, 1)
    count = count + 1

    if first == ireascript.SG_NEWLINE then
      nl = nl + 1
    end

    if first == sep then
      break
    end

    first = buf[1]
  end

  return count, nl
end

function ireascript.moveCaret(pos)
  ireascript.scrollTo(0)

  if pos >= 0 and pos <= ireascript.input:len() then
    ireascript.caret = pos
    ireascript.lastMove = os.time()
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
  ireascript.moveCaret(ireascript.input:len())
  ireascript.prompt()
end

function ireascript.scrollTo(pos)
  local max = ireascript.wrappedBuffer.lines - (ireascript.page - 1)
  ireascript.scroll = math.max(0, math.min(pos, max))
end

function ireascript.eval(nested)
  local code = ireascript.code()
  if code:len() < 1 then return end

  if code:sub(0, 1) == ireascript.CMD_PREFIX then
    ireascript.execCommand(code:sub(2))
  elseif code:sub(0, 1) == ireascript.ACTION_PREFIX then
    ireascript.execAction(code:sub(2))
  else
    local err = ireascript.lua(code)

    if err then
      ireascript.errorFormat()
      ireascript.push(err)
      ireascript.nl()
    else
      reaper.TrackList_AdjustWindows(false)
      reaper.UpdateArrange()
    end
  end

  if nested then return end

  table.insert(ireascript.history, 1, ireascript.input)
  ireascript.hindex = 0
  ireascript.input = ''

  if ireascript.lines == 0 then
    -- buffer got reset (.clear)
    ireascript.input = ''
  end
end

function ireascript.execCommand(name)
  local match, lower = nil, name:lower()

  for _,command in ipairs(ireascript.BUILTIN) do
    if command.name == lower then
      match = command
      break
    end
  end

  if match then
    match.func()
  else
    ireascript.errorFormat()
    ireascript.push(string.format("command not found: '%s'\n", name))
  end
end

function ireascript.execAction(name)
  local midi = false

  if name:sub(0, 1) == ireascript.ACTION_PREFIX then
    name, midi = name:sub(2), true
  end

  local id = reaper.NamedCommandLookup(name)

  if id > 0 then
    if midi then
      reaper.MIDIEditor_LastFocused_OnCommand(id, false)
    else
      reaper.Main_OnCommand(id, 0)
    end

    ireascript.format(id)
    ireascript.nl()
  else
    ireascript.errorFormat()
    ireascript.push(string.format("action not found: '%s'\n", name))
  end
end

function ireascript.code()
  if ireascript.prepend:len() > 0 then
    return ireascript.prepend .. "\n" .. ireascript.input
  else
    return ireascript.input
  end
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
      _ = values[1]
      ireascript.format(values[1])
    else
      _ = values
      ireascript.format(values)
    end

    ireascript.nl()
    ireascript.prepend = ''
  else
    if values:sub(-5) == '<eof>' and ireascript.input:len() > 0 then
      ireascript.prepend = code
      return
    else
      ireascript.prepend = ''
    end

    return values:sub(20)
  end
end

function ireascript.format(value)
  ireascript.resetFormat()

  local t = type(value)

  if t == 'table' then
    local i, array, last = 0, true, 0

    for k,v in pairs(value) do
      if type(k) == 'number' and k > 0 then
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
    value = string.format('%q', value):
      gsub("\\\n", '\\n'):
      gsub('\\0*13', '\\r'):
      gsub("\\0*9", '\\t')
  end

  ireascript.push(tostring(value))
end

function ireascript.formatArray(value, size)
  ireascript.push('{')

  for i=1,size do
    local v = value[i]
    if i > 1 then
      ireascript.resetFormat()
      ireascript.push(', ')
    end

    if i > ireascript.MAXLEN then
      ireascript.errorFormat()
      ireascript.push(string.format('%d more...', size - i))
      break
    else
      ireascript.format(v)
      i = i + 1
    end
  end

  ireascript.resetFormat()
  ireascript.push('}')
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

    if i > ireascript.MAXLEN then
      ireascript.errorFormat()
      ireascript.push(string.format('%d more...', size - i))
      break
    else
      ireascript.format(k)
      ireascript.resetFormat()
      ireascript.push('=')
      ireascript.format(v)

      i = i + 1
    end
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
  local before = ireascript.input:sub(0, ireascript.caret)
  local after = ireascript.input:sub(ireascript.caret + 1)
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

function ireascript.copy()
  local tool

  if ireascript.ismacos() then
    tool = 'pbcopy'
  elseif ireascript.iswindows() then
    tool = 'clip'
  end

  local proc, error = io.popen(tool, 'w')

  if not proc then
    ireascript.removeCaret()
    ireascript.nl()
    ireascript.errorFormat()
    ireascript.push(error)
    ireascript.nl()
    ireascript.prompt()
    return
  end

  proc:write(ireascript.code())
  proc:close()
end

function ireascript.paste()
  local tool

  if ireascript.ismacos() then
    tool = 'pbpaste'
  elseif ireascript.iswindows() then
    tool = 'powershell -windowstyle hidden -Command Get-Clipboard'
  end

  local first = true
  local proc, error = io.popen(tool, 'r')

  if not proc then
    ireascript.removeCaret()
    ireascript.nl()
    ireascript.errorFormat()
    ireascript.push(error)
    ireascript.nl()
    ireascript.prompt()
    return
  end

  for line in proc:lines() do
    if line:len() > 0 then
      if first then
        first = false
      else
        ireascript.removeCaret()
        ireascript.nl()
        ireascript.eval()
        ireascript.moveCaret(0)
      end

      local before, after = ireascript.splitInput()
      ireascript.input = before .. line .. after
      ireascript.moveCaret(ireascript.caret + line:len())
    end
  end

  proc:close()
end

function ireascript.complete()
  local before, after = ireascript.splitInput()

  local code = ireascript.prepend .. "\x20" .. before
  local matches, source = {}
  local var, word = code:match("([%a$d_]+)%s?%.%s?([%a%d_]*)$")

  if word then
    source = _G[var]
    if type(source) ~= 'table' then return end
  else
    var = before:match("([%a%d_]+)$")
    if not var then return end

    source = _G
    word = var
  end

  word = word:lower()

  for k, _ in pairs(source) do
    local test = k:lower()
    if test:sub(1, word:len()) == word then
      matches[#matches + 1] = k
    end
  end

  local exact

  if #matches == 1 then
    exact = matches[1]
    table.remove(matches, 1)
  elseif #matches < 1 then
    return
  else
    table.sort(matches)

    len = matches[1]:len()
    for i=1,#matches-1 do
      while len > word:len() do
        if matches[i]:sub(1, len) == matches[i + 1]:sub(1, len) then
          break
        else
          len = len - 1
        end
      end
    end

    if len >= word:len() then
      exact = matches[1]:sub(1, len)
    end
  end

  if exact then
    before = before:sub(1, -(word:len() + 1))
    ireascript.input = before .. exact .. after
    ireascript.caret = ireascript.caret + (exact:len() - word:len())
  end

  if #matches > 0 then
    ireascript.removeCaret()
    ireascript.nl()

    for i=1,#matches do
      ireascript.push(matches[i])
      ireascript.nl()
    end
  end

  ireascript.prompt()
end

function ireascript.iswindows()
  return reaper.GetOS():find('Win') ~= nil
end

function ireascript.ismacos()
  return reaper.GetOS():find('OSX') ~= nil
end

function ireascript.dup(table)
  local copy = {}
  for k,v in pairs(table) do copy[k] = v end
  return copy
end

function ireascript.contains(table, val)
  for i=1,#table do
    if table[i] == val then
      return true
    end
  end

  return false
end

function ireascript.each_lines(text)
  local pos, offset, finished = -1, 0, false

  return function()
    if finished then return end

    pos = text:find('[\r\n]', pos + 1)

    if not pos then
      finished = true
      return text:sub(offset)
    end

    local line = text:sub(offset, pos - 1)
    offset = pos + 1
    return line
  end
end

function previousWindowState()
  local state = tostring(reaper.GetExtState(
    ireascript.EXT_SECTION, ireascript.EXT_WINDOW_STATE))
  return state:match("^(%d+) (%d+) (%d+) (-?%d+) (-?%d+)$")
end

function saveWindowState()
  local dockState, xpos, ypos = gfx.dock(-1, 0, 0, 0, 0)
  local w, h = gfx.w, gfx.h
  if dockState > 0 then
    w, h = previousWindowState()
  end

  reaper.SetExtState(ireascript.EXT_SECTION, ireascript.EXT_WINDOW_STATE,
    string.format("%d %d %d %d %d", w, h, dockState, xpos, ypos), true)
end

local w, h, dockState, x, y = previousWindowState()

if w then
  gfx.init(ireascript.TITLE, w, h, dockState, x, y)
else
  gfx.init(ireascript.TITLE, 550, 350)
end

if ireascript.iswindows() then
  gfx.setfont(ireascript.FONT_NORMAL, 'Consolas', 16)
  gfx.setfont(ireascript.FONT_BOLD, 'Consolas', 16, string.byte('b'))
else
  gfx.setfont(ireascript.FONT_NORMAL, 'Courier', 14)
  gfx.setfont(ireascript.FONT_BOLD, 'Courier', 14, string.byte('b'))
end

-- GO!!
ireascript.run()

reaper.atexit(saveWindowState)

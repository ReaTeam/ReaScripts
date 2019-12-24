-- @description Interactive ReaScript (iReaScript)
-- @author cfillion
-- @version 0.8.3
-- @changelog
--   Fix blinking caret
--   Fix initial blank window on macOS and REAPER 5
--   Print the command name when running actions (SWS v2.10+ only)
-- @link
--   cfillion.ca https://cfillion.ca
--   Forum Thread https://forum.cockos.com/showthread.php?t=177324
-- @screenshot https://i.imgur.com/RrGfulR.gif
-- @donation https://www.paypal.me/cfillion
-- @about
--   # Interactive ReaScript (iReaScript)
--
--   This script simulates a [REPL](https://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop)
--   shell for Lua ReaScript inside of REAPER, for quickly experimenting code and API functions.
--
--   ## Screenshot
--
--   https://i.imgur.com/RrGfulR.gif
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
--   - Run actions (!command_id, !!midi_editor_action)
--   - Scrolling
--   - Text selection
--   - Text wrapping for long lines
--
--   ## Known Issues/Limitations
--
--   - Some errors cannot be caught (see https://forum.cockos.com/showthread.php?t=177319)
--   - This tool cannot be used to open a new GFX window
--
--   ## Contributing
--
--   Send patches at <https://github.com/cfillion/reascripts>.

local string, table, math, os, utf8 = string, table, math, os, utf8
local load, xpcall, pairs, ipairs = load, xpcall, pairs, ipairs, select
local reaper, gfx = reaper, gfx

function utf8.sub(s, i, j)
  i = utf8.offset(s, i)
  if not i then return '' end -- i is out of bounds

  if j and (j > 0 or j < -1) then
    j = utf8.offset(s, j + 1)
    if j then j = j - 1 end
  end

  return string.sub(s, i, j)
end

function utf8.reverse(s)
  local ns = ''

  for p, c in utf8.codes(s) do
    ns = utf8.char(c) .. ns
  end

  return ns
end

function utf8.find(s, pattern, i, plain)
  if i then
    i = utf8.offset(s, i)

    if not i then
      return
    end
  end

  local startPos = string.find(s, pattern, i, plain)
  if startPos then
    return utf8.len(s:sub(1, startPos))
  end
end

function utf8.rfind(str, pattern, plain)
  local pos = utf8.find(utf8.reverse(str), pattern, nil, plain)

  if pos then
    return utf8.len(str) - pos + 1
  end
end

local ireascript = {
  -- settings
  TITLE = 'Interactive ReaScript (iReaScript)',
  NAME = 'Interactive ReaScript',
  VERSION = '0.8.3',

  MARGIN = 3,
  MAXLINES = 2048,
  MAXDEPTH = 3, -- maximum array depth
  MAXLEN = 2048, -- maximum array and string size
  INDENT = 2,
  INDENT_THRESHOLD = 5,
  PROMPT = '> ',
  PROMPT_CONTINUE = '*> ',
  CMD_PREFIX = '.',
  ACTION_PREFIX = '!',

  COLOR_BLACK     = {012, 012, 012},
  COLOR_BLUE      = {088, 124, 212},
  COLOR_DEFAULT   = {190, 190, 190},
  COLOR_GREEN     = {090, 173, 087},
  COLOR_MAGENTA   = {175, 095, 095},
  COLOR_ORANGE    = {255, 093, 040},
  COLOR_RED       = {255, 085, 085},
  COLOR_WHITE     = {255, 255, 255},
  COLOR_YELLOW    = {199, 199, 000},
  COLOR_SCROLL    = {190, 190, 190},
  COLOR_SELECTION = {020, 040, 105},

  -- internal constants
  SG_NEWLINE = 1,
  SG_BUFNEWLINE = 2,

  IDC_IBEAM = 32513,

  FONT_NORMAL = 1,
  FONT_BOLD = 2,

  EMPTY_LINE_HEIGHT = 14,

  KEY_BACKSPACE = 8,
  KEY_CLEAR = 144,
  KEY_ESCAPE = 27,
  KEY_CTRLA = 1,
  KEY_CTRLC = 3,
  KEY_CTRLD = 4,
  KEY_CTRLL = 12,
  KEY_CTRLU = 21,
  KEY_CTRLV = 22,
  KEY_CTRLW = 23,
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
  KEY_F1 = 26161,

  MIDDLE_BTN = 64,
  LEFT_BTN = 1,
  RIGHT_BTN = 2,
  DOUBLECLICK_TIME = 0.2,

  MOD_SHIFT = 8,

  EXT_SECTION = 'cfillion_ireascript',
  EXT_WINDOW_STATE = 'window_state',
  EXT_LAST_DOCK = 'last_dock',

  HISTORY_FILE = ({reaper.get_action_context()})[2] .. '.history',
  HISTORY_LIMIT = 1000,

  WORD_SEPARATOR = '[%s"\'<>:;,!&|=/\\%(%)%%%+%-%*%?%[%]%^%$]',

  NO_CLIPBOARD_API = 'Copy/paste requires SWS v2.9.6 or newer',
  NO_REAPACK_API = 'ReaPack v1.2+ is required to use this feature',
  MANUALLY_INSTALLED = 'iReaScript must be installed through ReaPack to use this feature',
}

print = function(...)
  ireascript.backtrack()

  for i=1,select('#', ...) do
    if i > 1 then ireascript.push("\t") end
    ireascript.format(select(i, ...))
  end
  ireascript.nl()

  ireascript.doprompt = true
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
  helpLine('print(...)', 'Print any number of values', 11)
  helpLine('_', 'Last return values', 11)
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

function ireascript.about()
  if not reaper.ReaPack_GetOwner then
    reaper.internalError(ireascript.NO_REAPACK_API)
    return
  end

  local owner = reaper.ReaPack_GetOwner(({reaper.get_action_context()})[2])

  if not owner then
    ireascript.internalError(ireascript.MANUALLY_INSTALLED)
    return
  end

  reaper.ReaPack_AboutInstalledPackage(owner)
  reaper.ReaPack_FreeEntry(owner)
end

function ireascript.exit()
  gfx.quit()
end

function ireascript.reset(banner)
  ireascript.buffer = {}
  ireascript.lineCount = 0
  ireascript.page = 0
  ireascript.scroll = 0
  ireascript.wrappedBuffer = {w = 0}
  ireascript.from = nil

  if banner then
    ireascript.resetFormat()

    ireascript.push(string.format('%s v%s by cfillion\n',
      ireascript.NAME, ireascript.VERSION))
    ireascript.push('Type Lua code, !ACTION or .help\n')
  end

  if #ireascript.history == 0 then
    ireascript.readHistory()
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
  ireascript.lastRedraw = os.time()
  ireascript.mouseCap = 0
  ireascript.selection = nil
  ireascript.lastClick = 0.0
  ireascript.reset(true)

  ireascript.initgfx()
  ireascript.loop()
end

function ireascript.keyboard()
  local char = gfx.getchar()

  if char < 0 then
    -- bye bye!
    return false
  end

  if char == ireascript.KEY_BACKSPACE then
    local before, after = ireascript.splitInput()
    ireascript.input = utf8.sub(before, 0, -2) .. after
    ireascript.moveCaret(ireascript.caret - 1)
  elseif char == ireascript.KEY_DELETE then
    local before, after = ireascript.splitInput()
    ireascript.input = before .. utf8.sub(after, 2)
    ireascript.scrollTo(0)
    ireascript.prompt()
  elseif char == ireascript.KEY_CLEAR then
    ireascript.input = ''
    ireascript.moveCaret(0)
  elseif char == ireascript.KEY_CTRLU then
    local before, after = ireascript.splitInput()
    ireascript.input = after
    ireascript.moveCaret(0)
  elseif char == ireascript.KEY_CTRLW then
    local before, after = ireascript.splitInput()
    local wordStart = ireascript.lastWord(before)
    ireascript.input = utf8.sub(before, 1, wordStart) .. after
    ireascript.moveCaret(wordStart)
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

    if gfx.mouse_cap & ireascript.MOD_SHIFT ~= 0 then
      pos = ireascript.lastWord(ireascript.splitInput())
    else
      pos = ireascript.caret - 1
    end

    ireascript.moveCaret(pos)
  elseif char == ireascript.KEY_RIGHT then
    local pos

    if gfx.mouse_cap & ireascript.MOD_SHIFT ~= 0 then
      pos = ireascript.nextWord(ireascript.input, ireascript.caret)
    else
      pos = ireascript.caret + 1
    end

    ireascript.moveCaret(pos)
  elseif char == ireascript.KEY_END then
    ireascript.moveCaret(utf8.len(ireascript.input))
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
  elseif char == ireascript.KEY_F1 then
    ireascript.about()
  elseif char == ireascript.KEY_CTRLA then
    ireascript.selectAll()
  elseif char == ireascript.KEY_ESCAPE then
    ireascript.selection = nil
  elseif char >= ireascript.KEY_INPUTRANGE_FIRST and char <= ireascript.KEY_INPUTRANGE_LAST then
    local before, after = ireascript.splitInput()
    ireascript.input = before .. utf8.char(char) .. after
    ireascript.moveCaret(ireascript.caret + 1)
  end

  return true
end

function ireascript.lastWord(str)
  local pos = utf8.rfind(str, '[^%s]%s')

  if pos then
    return pos - 1
  else
    return 0
  end
end

function ireascript.nextWord(str, pos)
  return utf8.find(str, '%s[^%s]', pos + 1) or utf8.len(str)
end

function ireascript.wrappedLines()
  local lineEnd = #ireascript.wrappedBuffer
  local nl = lineEnd + 1 -- past the end of the buffer

  return function()
    if nl < 1 then return end

    local lineHeight = 0

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

    local line = {front=nl + 1, back=lineEnd, height=lineHeight}

    lineEnd = nl - 1
    nl = lineEnd

    return line
  end
end

function ireascript.draw(offset)
  ireascript.useColor(ireascript.COLOR_BLACK)
  gfx.rect(0, 0, gfx.w, gfx.h)

  gfx.x = ireascript.MARGIN
  gfx.y = gfx.h - (offset or 0)
  ireascript.pageBottom = gfx.y

  local lines, lineHeight = 0, 0
  local lastSkipped, before, after = nil, 0, 0

  ireascript.page = 0

  for line in ireascript.wrappedLines() do
    lineHeight = line.height
    lines = lines + 1

    if lines > ireascript.scroll then
      gfx.x, gfx.y = ireascript.MARGIN, gfx.y - lineHeight

      if gfx.y > 0 then
        -- only count 100% visible lines
        ireascript.page = ireascript.page + 1
        ireascript.drawLine(line)
      elseif gfx.y > -lineHeight then
        -- partially visible line at the top
        before = before + math.abs(gfx.y)
        ireascript.drawLine(line)
      else
        before = before + lineHeight
      end
    else
      after = after + lineHeight
      lastSkipped = line
    end
  end

  if offset then
    if lastSkipped then
      -- draw incomplete line below scrolling
      gfx.x, gfx.y = ireascript.MARGIN, gfx.h - offset
      after = after - (lastSkipped.height - offset)
      ireascript.drawLine(lastSkipped)
    end

    -- simulate how many lines would be needed to fill the window
    ireascript.page = ireascript.page + math.floor(offset / lineHeight)
  elseif gfx.y > ireascript.MARGIN then
    -- the window is not full, redraw aligned to the top
    return ireascript.draw(gfx.y - ireascript.MARGIN)
  end

  ireascript.scrollbar(before, after)
end

function ireascript.segmentSelection(segmentIndex)
  local selected = ireascript.selection and
    segmentIndex >= ireascript.selection[1].segment and
    segmentIndex <= ireascript.selection[2].segment

  if not selected then return end

  local isFirst = segmentIndex == ireascript.selection[1].segment
  local isLast = segmentIndex == ireascript.selection[2].segment

  local segment, width = ireascript.wrappedBuffer[segmentIndex]

  if type(segment) == 'table' then
    width = segment.w
  else
    width = 10
  end

  local start = isFirst and ireascript.selection[1].offset or 0
  local stop = isLast and ireascript.selection[2].offset or width

  return start, stop
end

function ireascript.drawLine(line)
  local now = os.time()

  for i=line.front,line.back do
    local segment = ireascript.wrappedBuffer[i]
    local selectionStart, selectionEnd = ireascript.segmentSelection(i)

    if type(segment) == 'table' then
      ireascript.useFont(segment.font)

      ireascript.useColor(segment.bg)
      gfx.rect(gfx.x, gfx.y, segment.w, segment.h)

      if selectionStart then
        ireascript.useColor(ireascript.COLOR_SELECTION)
        gfx.rect(gfx.x + selectionStart, gfx.y, selectionEnd - selectionStart, line.height)
      end

      ireascript.useColor(segment.fg)

      if segment.caret and (now % 2 == 0 or now - ireascript.lastMove < 1) then
        local w, _ = gfx.measurestr(utf8.sub(segment.text, 0, segment.caret))
        ireascript.drawCaret(gfx.x + w, gfx.y, line.height)
      end

      gfx.drawstr(segment.text)
    elseif segment == ireascript.SG_BUFNEWLINE and selectionStart then
      ireascript.useColor(ireascript.COLOR_SELECTION)
      gfx.rect(gfx.x , gfx.y, selectionEnd, line.height)
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

  ireascript.selection = nil
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
        local count = utf8.len(segment.text)
        local resized = false

        while w + left > gfx.w do
          count = count - 1
          w, h = gfx.measurestr(utf8.sub(segment.text, 1, count))
          resized = true
        end

        left = left + w

        local newSeg = ireascript.dup(segment)
        newSeg.text = utf8.sub(text, 1, count)
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

        text = utf8.sub(text, count + 1)
        startpos = startpos + count
      end
    end
  end

  ireascript.from = {buffer=#ireascript.buffer + 1, wrapped=#ireascript.wrappedBuffer + 1}
  ireascript.redraw = true
end

function ireascript.contextMenu()
  local dockState = gfx.dock(-1)
  local dockFlag = ''
  if dockState > 0 then dockFlag = '!' end

  local menu = string.format(
    'Copy (^C)|Paste (^V)||Select all (^A)||Clear (^L)||%sDock window|About iReaScript (F1)|Close iReaScript (^D)',
    dockFlag
  )

  local actions = {
    ireascript.copy, ireascript.paste, ireascript.selectAll, ireascript.reset,
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
    ireascript.about,
    ireascript.exit,
  }

  gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y
  local index = gfx.showmenu(menu)
  if actions[index] then actions[index]() end
end

function ireascript.mouseWheel()
  if gfx.mouse_wheel ~= 0 then
    local lines = math.ceil(math.abs(gfx.mouse_wheel) / 24)

    if gfx.mouse_wheel > 0 then
      ireascript.scrollTo(ireascript.scroll + lines)
    else
      ireascript.scrollTo(ireascript.scroll - lines)
    end

    gfx.mouse_wheel = 0
  end
end

function ireascript.mouseBtnEvent()
  if ireascript.isMouseDown(ireascript.LEFT_BTN) then
    ireascript.mouseDownPoint = ireascript.pointUnderMouse()
  elseif ireascript.isMouseUp(ireascript.LEFT_BTN) then
    local now = reaper.time_precise()

    if ireascript.lastClick > now - ireascript.DOUBLECLICK_TIME then
      ireascript.selectWord(ireascript.pointUnderMouse())
    else
      ireascript.lastClick = now
    end
  end

  if ireascript.isMouseUp(ireascript.MIDDLE_BTN) then
    ireascript.paste(true)
  end

  if ireascript.isMouseUp(ireascript.RIGHT_BTN) then
    ireascript.contextMenu()
  end
end

function ireascript.loop()
  if ireascript.doprompt then
    ireascript.doprompt = false
    ireascript.prompt()
  end

  if ireascript.keyboard() then
    reaper.defer(function() ireascript.try(ireascript.loop) end)
  end

  ireascript.mouseWheel()

  if gfx.mouse_cap ~= ireascript.mouseCap then
    ireascript.mouseBtnEvent()

    ireascript.mouseCap = gfx.mouse_cap
  elseif ireascript.isMouseDrag(ireascript.LEFT_BTN) then
    ireascript.selectRange(ireascript.mouseDownPoint, ireascript.pointUnderMouse())
  end

  if ireascript.wrappedBuffer.w ~= gfx.w then
    ireascript.from = nil -- full reflow
    ireascript.update()
  end

  local now = os.time()
  if now - ireascript.lastRedraw >= 1 then
    -- let the cursor caret blink
    ireascript.redraw = true
    ireascript.lastRedraw = now
  end

  if ireascript.redraw then
    ireascript.redraw = false
    ireascript.draw()
  end

  gfx.update()

  ireascript.scrollTo(ireascript.scroll) -- refreshed bound check
end

function ireascript.isMouseDown(flag)
  return gfx.mouse_cap & flag == flag and ireascript.mouseCap & flag == 0
end

function ireascript.isMouseDrag(flag)
  return gfx.mouse_cap & flag == flag
end

function ireascript.isMouseUp(flag)
  return gfx.mouse_cap & flag == 0 and ireascript.mouseCap & flag == flag
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
  if ireascript.lineCount >= ireascript.MAXLINES then
    local buf = ireascript.removeUntil(ireascript.buffer, ireascript.SG_NEWLINE)
    local wrap, nlCount = ireascript.removeUntil(ireascript.wrappedBuffer, ireascript.SG_BUFNEWLINE)

    ireascript.wrappedBuffer.lines = ireascript.wrappedBuffer.lines - nlCount

    if ireascript.from then
      ireascript.from.buffer = ireascript.from.buffer - buf
      ireascript.from.wrapped = ireascript.from.wrapped - wrap
    end
  else
    ireascript.lineCount = ireascript.lineCount + 1
  end

  ireascript.buffer[#ireascript.buffer + 1] = ireascript.SG_NEWLINE
end

function ireascript.push(contents)
  if contents == nil then
    error('content is nil')
  end

  local index = 0

  for line in ireascript.lines(contents) do
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

  if pos >= 0 and pos <= utf8.len(ireascript.input) then
    ireascript.caret = pos
    ireascript.lastMove = os.time()
    ireascript.prompt()
  end
end

function ireascript.readHistory()
  local file, err = io.open(ireascript.HISTORY_FILE, 'r')
  if not file then return -1 end

  ireascript.history = {}

  for line in file:lines() do
    if #ireascript.history >= ireascript.HISTORY_LIMIT then break end
    if utf8.len(line) then
      table.insert(ireascript.history, line)
    end
  end

  file:close()
  return #ireascript.history
end

function ireascript.writeHistory()
  local file, err = io.open(ireascript.HISTORY_FILE, 'w')
  if not file then return false end

  local count = math.min(#ireascript.history, ireascript.HISTORY_LIMIT)
  for i=1, count do
    file:write(string.format('%s\n', ireascript.history[i]))
  end

  file:close()
  return count
end

function ireascript.pushHistory(line)
  for i=1,math.min(50, #ireascript.history) do
    if ireascript.history[i] == line then
      table.remove(ireascript.history, i)
      i = i - 1
    end
  end

  table.insert(ireascript.history, 1, line)
  ireascript.hindex = 0
end

function ireascript.historyJump(pos)
  if pos < 0 or pos > #ireascript.history then
    return
  elseif ireascript.hindex == 0 then
    ireascript.history[0] = ireascript.input
  end

  ireascript.hindex = pos
  ireascript.input = ireascript.history[ireascript.hindex]
  ireascript.moveCaret(utf8.len(ireascript.input))
  ireascript.prompt()
end

function ireascript.scrollTo(pos)
  local max = ireascript.wrappedBuffer.lines - (ireascript.page - 1)
  local newscroll = math.max(0, math.min(pos, max))

  if newscroll ~= ireascript.scroll then
    ireascript.scroll = newscroll
    ireascript.redraw = true
  end
end

function ireascript.eval(nested)
  local code = ireascript.code()
  if code:len() < 1 then return end

  if code:sub(0, 1) == ireascript.CMD_PREFIX then
    ireascript.execCommand(code:sub(2))
  elseif code:sub(0, 1) == ireascript.ACTION_PREFIX then
    ireascript.execAction(code:sub(2))
  else
    if ireascript.lua(code) then
      reaper.TrackList_AdjustWindows(false)
      reaper.UpdateArrange()
    end
  end

  if nested then return end

  ireascript.pushHistory(ireascript.input)
  ireascript.input = ''

  if ireascript.lineCount == 0 then
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

  local id, section = reaper.NamedCommandLookup(name), 0

  if id > 0 then
    if midi then
      reaper.MIDIEditor_LastFocused_OnCommand(id, false)
      section = 32060
    else
      reaper.Main_OnCommand(id, 0)
    end

    ireascript.format(id)
    if reaper.CF_GetCommandText then -- SWS v2.10+
      ireascript.push('\x20')
      ireascript.format(reaper.CF_GetCommandText(section, id))
    end
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
    local hasMessage = type(values) == 'string'

    if hasMessage and values:sub(-5) == '<eof>' and ireascript.input:len() > 0 then
      ireascript.prepend = code
      return
    else
      ireascript.prepend = ''
    end

    ireascript.errorFormat()

    if hasMessage then
      if values:len() >= 20 then
        ireascript.push(values:sub(20))
      else
        ireascript.push('\x20')
      end
    else
      ireascript.push('error')
      ireascript.resetFormat()
      ireascript.push(' ')
      ireascript.format(values)
    end

    ireascript.nl()
  end

  return ok
end

function ireascript.format(value)
  ireascript.resetFormat()

  local t = type(value)

  if t == 'table' then
    ireascript.formatAnyTable(value)
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

    local len = utf8.len(value)
    local illformed = not len

    if (len or value:len()) > ireascript.MAXLEN then
      value = utf8.sub(value, 1, ireascript.MAXLEN) .. '...'
    end

    value = ireascript.tostringliteral(value)

    if illformed then
      value = ireascript.repairUTF8(value)
    end
  end

  ireascript.push(tostring(value))
end

function ireascript.tostringliteral(value)
  return string.format('%q', value):
    gsub("\\\n", '\\n'):
    gsub('\\0*13', '\\r'):
    gsub("\\0*9", '\\t')
end

function ireascript.repairUTF8(value)
  return value:gsub('[\128-\255]', function(c)
    return string.format('\\%03d', c:byte())
  end)
end

function ireascript.formatAnyTable(value)
  local size, isArray = ireascript.realTableSize(value)

  if ireascript.flevel == nil then
    ireascript.flevel = 1
  elseif ireascript.flevel >= ireascript.MAXDEPTH then
    ireascript.errorFormat()
    ireascript.push('...')
    return
  else
    ireascript.flevel = ireascript.flevel + 1
  end

  (isArray and ireascript.formatArray or ireascript.formatTable)(value, size)

  ireascript.flevel = ireascript.flevel - 1
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

  for k,v in ireascript.sortedPairs(value) do
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
      ireascript.push('[')
      ireascript.format(k)
      ireascript.resetFormat()
      ireascript.push(']=')
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
  local before = utf8.sub(ireascript.input, 0, ireascript.caret)
  local after = utf8.sub(ireascript.input, ireascript.caret + 1)
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
  if not reaper.CF_SetClipboard then
    ireascript.internalError(ireascript.NO_CLIPBOARD_API)
    return
  end

  local selectedText = ireascript.selectedText()
  local clipboard = selectedText and selectedText or ireascript.code()

  if clipboard:len() > 0 then
    reaper.CF_SetClipboard(clipboard)
  end
end

function ireascript.paste(selection)
  if not reaper.CF_GetClipboard then
    ireascript.internalError(ireascript.NO_CLIPBOARD_API)
    return
  end

  local isFirst, clipboard = true, nil

  if selection and ireascript.selection then
    clipboard = ireascript.selectedText()
  else
    clipboard = reaper.CF_GetClipboard('')
  end

  for line in ireascript.lines(clipboard) do
    if line:len() > 0 then
      if isFirst then
        isFirst = false
      else
        ireascript.removeCaret()
        ireascript.nl()
        ireascript.eval()
        ireascript.moveCaret(0)
      end

      local before, after = ireascript.splitInput()
      ireascript.input = before .. line .. after
      ireascript.moveCaret(ireascript.caret + utf8.len(line))
    end
  end
end

function ireascript.internalError(msg)
  ireascript.removeCaret()
  ireascript.nl()
  ireascript.errorFormat()
  ireascript.push(string.format('internal error: %s', msg))
  ireascript.nl()
  ireascript.prompt()
  return
end

function ireascript.complete()
  local before, after = ireascript.splitInput()

  local code = ireascript.prepend .. "\x20" .. before
  local matches, source = {}, _G
  local prefix, word = code:match("([%a%d_%s%.]*[%a%d_]+)%s*%.%s*([^%s]*)$")

  if word then
    for key in prefix:gmatch('[^%.%s]+') do
      source = source[key]
      if type(source) ~= 'table' then return end
    end
  else
    word = before:match("([%a%d_]+)$")
    if not word then return end
  end

  local wordLength = utf8.len(word)
  word = word:lower()

  for k, _ in pairs(source) do
    local test = k:lower()
    if utf8.sub(test, 1, wordLength) == word then
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

    local len = utf8.len(matches[1])
    for i=1,#matches-1 do
      while len > wordLength do
        if utf8.sub(matches[i], 1, len) == utf8.sub(matches[i + 1], 1, len) then
          break
        else
          len = len - 1
        end
      end
    end

    if len >= wordLength then
      exact = utf8.sub(matches[1], 1, len)
    end
  end

  if exact then
    if exact:match('[^%a%d_]') then
      local dot = utf8.rfind(before, '%.')
      before = utf8.sub(before, 1, dot - 1)
      exact = string.format('[%s]', ireascript.tostringliteral(exact))
    else
      before = utf8.sub(before, 1, -(wordLength + 1))
    end
    ireascript.input = before .. exact .. after
    ireascript.caret = utf8.len(before .. exact)
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

function ireascript.lineAt(ypos)
  local lineBottom = ireascript.pageBottom
  local lines = 0

  for line in ireascript.wrappedLines() do
    lines = lines + 1

    if lines > ireascript.scroll then
      local lineTop = lineBottom - line.height

      if lineTop <= ypos then
        return line
      end

      lineBottom = lineTop
    end

    -- past the top of the screen
    if lineBottom <= 0 then return end
  end
end

function ireascript.segmentAt(line, xpos)
  local lineLeft = 0
  for i=line.front,line.back do
    local segment = ireascript.wrappedBuffer[i]

    if type(segment) == 'table' then
      local lineRight = lineLeft + segment.w

      if lineLeft <= xpos and lineRight >= xpos then
        return i, lineLeft
      end

      lineLeft = lineRight
    end
  end
end

function ireascript.characterAt(segment, xpos)
  local charLeft = 0

  ireascript.useFont(segment.font)

  for i=1,utf8.len(segment.text) do
    local charRight = gfx.measurestr(utf8.sub(segment.text, 1, i))

    if charLeft <= xpos and charRight >= xpos then
      return i, charLeft
    end

    charLeft = charRight
  end
end

function ireascript.bufferStartPoint()
  return {segment=1, char=0, offset=0}
end

function ireascript.bufferEndPoint()
  local bufSize = #ireascript.wrappedBuffer
  local lastSeg = ireascript.wrappedBuffer[bufSize]

  return {segment=bufSize, char=lastSeg.text:len() + 1, offset=lastSeg.w}
end

function ireascript.pointUnderMouse()
  local mouseX = math.max(ireascript.MARGIN, math.min(gfx.mouse_x, gfx.w))
  local mouseY = math.max(ireascript.MARGIN, math.min(gfx.mouse_y, gfx.h))

  local line = ireascript.lineAt(mouseY)
  if not line then
    return ireascript.bufferEndPoint()
  end

  local segIndex, segX = ireascript.segmentAt(line, mouseX)

  if segIndex then
    local segment = ireascript.wrappedBuffer[segIndex]
    local char, offset = ireascript.characterAt(segment, mouseX - segX)

    return {segment=segIndex, char=char, offset=offset}
  else
    local segment = ireascript.wrappedBuffer[line.back]

    if segment == ireascript.SG_BUFNEWLINE then
      line.back = line.back - 1
      segment = ireascript.wrappedBuffer[line.back]
    end

    if type(segment) == 'table' then
      return {segment=line.back, char=utf8.len(segment.text) + 1, offset=segment.w}
    else
      return {segment=line.back, char=0, offset=0}
    end
  end
end

function ireascript.comparePoints(a, b)
  if a.segment == b.segment then
    return a.offset < b.offset
  else
    return a.segment < b.segment
  end
end

function ireascript.selectRange(a, b)
  if ireascript.comparePoints(a, b) == ireascript.comparePoints(b, a) then
    -- both points are identical, clear selection
    ireascript.selection = nil
  else
    ireascript.selection = {a, b}
    table.sort(ireascript.selection, ireascript.comparePoints)
  end

  ireascript.redraw = true
end

function ireascript.surroundingBoundaries(str, pos)
  local char = utf8.sub(str, pos, pos)
  local wordStart, wordEnd

  if char:match(ireascript.WORD_SEPARATOR) then
    -- select only repeated same separator characters
    wordStart, wordEnd = pos - 1, pos + 1

    while wordStart > 0 and utf8.sub(str, wordStart, wordStart) == char do
      wordStart = wordStart - 1
    end

    while utf8.sub(str, wordEnd, wordEnd) == char do
      wordEnd = wordEnd + 1
    end
  else
    wordStart = utf8.rfind(utf8.sub(str, 1, pos), ireascript.WORD_SEPARATOR) or 0
    wordEnd = utf8.find(str, ireascript.WORD_SEPARATOR, pos, plain)
    wordEnd = wordEnd or (utf8.len(str) + 1)
  end

  return (wordStart or 0), wordEnd - 1
end

function ireascript.selectWord(point)
  local segment = ireascript.wrappedBuffer[point.segment]
  if type(segment) ~= 'table' then return end

  local wordStart, wordEnd = ireascript.surroundingBoundaries(segment.text, point.char)

  ireascript.useFont(segment.font)
  local startOffset = gfx.measurestr(utf8.sub(segment.text, 1, wordStart))
  local stopOffset = gfx.measurestr(utf8.sub(segment.text, 1, wordEnd))

  local start = {segment=point.segment, char=wordStart + 1, offset=startOffset}
  local stop = {segment=point.segment, char=wordEnd + 1, offset=stopOffset}

  ireascript.selectRange(start, stop)
end

function ireascript.selectedText()
  if not ireascript.selection then return end

  local text = ''

  for i=ireascript.selection[1].segment,ireascript.selection[2].segment do
    local segment = ireascript.wrappedBuffer[i]

    if type(segment) == 'table' then
      local start, stop

      if i == ireascript.selection[1].segment then
        start = ireascript.selection[1].char
      else
        start = 0
      end

      if i == ireascript.selection[2].segment then
        stop = ireascript.selection[2].char - 1
      else
        stop = utf8.len(segment.text)
      end

      text = text .. utf8.sub(segment.text, start, stop)
    elseif segment == ireascript.SG_BUFNEWLINE then
      text = text .. "\n"
    end
  end

  return text
end

function ireascript.selectAll()
  ireascript.selection = {ireascript.bufferStartPoint(), ireascript.bufferEndPoint()}
  ireascript.redraw = true
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

function ireascript.realTableSize(table)
  local i, array, last = 0, true, 0

  for k,v in ireascript.sortedPairs(table) do
    if type(k) == 'number' and k > 0 then
      i = i + (k - last) - 1
      last = k
    else
      array = false
      i = 0
      break
    end

    i = i + 1
  end

  if not array then
    for k,v in pairs(table) do
      i = i + 1
    end
  end

  return i, array
end

function ireascript.anySort(a, b)
  if type(a) ~= 'number' or type(b) ~= 'number' then
    a = tostring(a)
    b = tostring(b)
  end

  return a < b
end

function ireascript.sortedPairs(t)
  local keys = {}
  for key,_ in pairs(t) do
    table.insert(keys, key)
  end
  table.sort(keys, ireascript.anySort)

  local it, state, n = ipairs(keys)

  return function()
    local newn, key = it(state, n)
    n = newn

    if key then
      return key, t[key]
    end
  end
end

function ireascript.lines(text)
  local offset, finished = 0, false
  local from, to = -1

  return function()
    if finished then return end

    from, to = text:find('\r?\n', from + 1)

    if not from then
      finished = true
      return text:sub(offset)
    end

    local line = text:sub(offset, from - 1)
    offset = to + 1
    return line
  end
end

function ireascript.previousWindowState()
  local state = tostring(reaper.GetExtState(
    ireascript.EXT_SECTION, ireascript.EXT_WINDOW_STATE))
  return state:match("^(%d+) (%d+) (%d+) (-?%d+) (-?%d+)$")
end

function ireascript.saveWindowState()
  local dockState, xpos, ypos = gfx.dock(-1, 0, 0, 0, 0)
  local w, h = gfx.w, gfx.h
  if dockState > 0 then
    w, h = ireascript.previousWindowState()
  end

  reaper.SetExtState(ireascript.EXT_SECTION, ireascript.EXT_WINDOW_STATE,
    string.format("%d %d %d %d %d", w, h, dockState, xpos, ypos), true)
end

function ireascript.try(callback)
  local report

  xpcall(callback, function(errObject)
    report = string.format('%s\n%s', errObject, debug.traceback())
  end)

  if report then
    error(report)
  end
end

function ireascript.initgfx()
  local w, h, dockState, x, y = ireascript.previousWindowState()

  if w then
    gfx.init(ireascript.TITLE, w, h, dockState, x, y)
  else
    gfx.init(ireascript.TITLE, 550, 350)
  end

  gfx.setcursor(ireascript.IDC_IBEAM)
  gfx.clear = -1

  if ireascript.iswindows() then
    gfx.setfont(ireascript.FONT_NORMAL, 'Consolas', 16)
    gfx.setfont(ireascript.FONT_BOLD, 'Consolas', 16, string.byte('b'))
  elseif ireascript.ismacos() then
    gfx.setfont(ireascript.FONT_NORMAL, 'Menlo', 14)
    gfx.setfont(ireascript.FONT_BOLD, 'Menlo', 14, string.byte('b'))
  else
    gfx.setfont(ireascript.FONT_NORMAL, 'monospace', 14)
    gfx.setfont(ireascript.FONT_BOLD, 'monospace', 14, string.byte('b'))
  end
end

-- GO!!
ireascript.try(ireascript.run)

-- since some v5.XX update the first frame is blank on macOS
-- this got fixed v6.0rc9: https://forum.cockos.com/showthread.php?t=227788
if not reaper.reduce_open_files then -- REAPER < 6
  reaper.defer(ireascript.draw)
end

reaper.atexit(function()
  ireascript.saveWindowState()
  ireascript.writeHistory()
end)

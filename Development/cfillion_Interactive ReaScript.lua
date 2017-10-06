-- @description Interactive ReaScript (iReaScript)
-- @version 0.7
-- @author cfillion
-- @changelog
--   add "Select all" action to the context menu (also Ctrl+A)
--   avoid clearing the clipboard
--   clear selection when pressing Escape
--   copy selected text instead of current input if non-empty
--   display table keys in alphabetical order
--   implement text selection!
--   paste from selection (if non-empty) on middle click
--   remove duplicate entries in history
--   select word under cursor on double click
--   set cursor to I-beam
--   sort by key alphabetically when displaying table values
-- @links
--   cfillion.ca https://cfillion.ca
--   Forum Thread https://forum.cockos.com/showthread.php?t=177324
-- @donation https://www.paypal.me/cfillion
-- @screenshot https://i.imgur.com/RrGfulR.gif
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

local string, table, math, os = string, table, math, os
local load, xpcall, pairs, ipairs = load, xpcall, pairs, ipairs, select

local ireascript = {
  -- settings
  TITLE = 'Interactive ReaScript',
  VERSION = '0.7',

  MARGIN = 3,
  MAXLINES = 2048,
  MAXDEPTH = 3, -- maximum array depth
  MAXLEN = 2048, -- maximum array size
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
  COLOR_SELECTION = {20, 40, 105},

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

  EXT_SECTION = 'cfillion_ireascript',
  EXT_WINDOW_STATE = 'window_state',
  EXT_LAST_DOCK = 'last_dock',

  HISTORY_FILE = ({reaper.get_action_context()})[2] .. '.history',
  HISTORY_LIMIT = 1000,

  WORD_SEPARATORS = '%s"\'<>:;,!&|=/\\%(%)%%%+%-%*%?%[%]%^%$',

  NO_CLIPBOARD_API = 'Copy/paste requires SWS v2.9.6 or newer',
  NO_REAPACK_API = 'ReaPack v1.2+ is required to use this feature',
  MANUALLY_INSTALLED = 'iReaScript must be installed through ReaPack to use this feature',
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
      ireascript.TITLE, ireascript.VERSION))
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
  ireascript.mouseCap = 0
  ireascript.selection = nil
  ireascript.lastClick = 0.0

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
  elseif char == ireascript.KEY_F1 then
    ireascript.about()
  elseif char == ireascript.KEY_CTRLA then
    ireascript.selectAll()
  elseif char == ireascript.KEY_ESCAPE then
    ireascript.selection = nil
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
        local w, _ = gfx.measurestr(segment.text:sub(0, segment.caret))
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
  if ireascript.keyboard() then
    reaper.defer(ireascript.loop)
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

  ireascript.draw()
  ireascript.scrollTo(ireascript.scroll) -- refreshed bound check

  gfx.update()
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

  if pos >= 0 and pos <= ireascript.input:len() then
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
    table.insert(ireascript.history, line)
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

    if value:len() > ireascript.MAXLEN then
      value = value:sub(1, ireascript.MAXLEN) .. '...'
    end

    value = string.format('%q', value):
      gsub("\\\n", '\\n'):
      gsub('\\0*13', '\\r'):
      gsub("\\0*9", '\\t')
  end

  ireascript.push(tostring(value))
end

function ireascript.formatAnyTable(value)
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
      ireascript.moveCaret(ireascript.caret + line:len())
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

function ireascript.lineAt(ypos)
  local lineBottom = ireascript.pageBottom
  local lines = 0

  for line in ireascript.wrappedLines() do
    lines = lines + 1

    if lines > ireascript.scroll then
      local lineTop = lineBottom - line.height

      if lineTop <= ypos and lineBottom >= ypos then
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

  for i=1,segment.text:len() do
    local charRight = gfx.measurestr(segment.text:sub(1, i))

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
      return {segment=line.back, char=segment.text:len() + 1, offset=segment.w}
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
end

function ireascript.selectWord(point)
  local segment = ireascript.wrappedBuffer[point.segment]
  if type(segment) ~= 'table' then return end

  local match = string.format('[%s]', ireascript.WORD_SEPARATORS)
  if segment.text:sub(point.char, point.char):match(match) then
    -- select only whitespace if the point is between words
    match = string.format('[^%s]', ireascript.WORD_SEPARATORS)
  end

  local before = segment.text:sub(1, point.char):reverse()
  local wordStart = before:find(match)
  if wordStart then
    wordStart = before:len() - wordStart + 2
  else
    wordStart = 1
  end

  local wordEnd = segment.text:find(match, point.char) or (segment.text:len() + 1)

  ireascript.useFont(segment.font)
  local startOffset = gfx.measurestr(segment.text:sub(1, wordStart - 1))
  local stopOffset = gfx.measurestr(segment.text:sub(1, wordEnd - 1))

  local start = {segment=point.segment, char=wordStart, offset=startOffset}
  local stop = {segment=point.segment, char=wordEnd, offset=stopOffset}

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
        stop = segment.text:len()
      end

      text = text .. segment.text:sub(start, stop)
    elseif segment == ireascript.SG_BUFNEWLINE then
      text = text .. "\n"
    end
  end

  return text
end

function ireascript.selectAll()
  ireascript.selection = {ireascript.bufferStartPoint(), ireascript.bufferEndPoint()}
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

function ireascript.sortedPairs(t)
  local keys = {}
  for key,_ in pairs(t) do
    table.insert(keys, key)
  end
  table.sort(keys)

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

local w, h, dockState, x, y = ireascript.previousWindowState()

if w then
  gfx.init(ireascript.TITLE, w, h, dockState, x, y)
else
  gfx.init(ireascript.TITLE, 550, 350)
end

gfx.setcursor(ireascript.IDC_IBEAM)

if ireascript.iswindows() then
  gfx.setfont(ireascript.FONT_NORMAL, 'Consolas', 16)
  gfx.setfont(ireascript.FONT_BOLD, 'Consolas', 16, string.byte('b'))
else
  gfx.setfont(ireascript.FONT_NORMAL, 'Courier', 14)
  gfx.setfont(ireascript.FONT_BOLD, 'Courier', 14, string.byte('b'))
end

-- GO!!
ireascript.run()

reaper.atexit(function()
  ireascript.saveWindowState()
  ireascript.writeHistory()
end)

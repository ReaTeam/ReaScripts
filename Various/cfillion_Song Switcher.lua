-- @description Song Switcher
-- @version 1.3
-- @changelog
--   * fix detection of start/end time when there are no items in the first few tracks
--   Web Interface:
--   * add midi panic and data reset buttons
--   * disable spell check on the input box
--   * implement timeline view with seek support and markers
--   * make spacebar trigger play/stop on desktop
--   * rewrite with cleaner code
-- @author cfillion
-- @provides
--   [main] cfillion_Song Switcher/*.lua
--   [webinterface] cfillion_Song Switcher/song_switcher.html > song_switcher.html
-- @link Forum Thread http://forum.cockos.com/showthread.php?t=181159
-- @donation https://www.paypal.me/cfillion
-- @screenshot
--   Docked Mode https://i.imgur.com/4xPMV9J.gif
--   Windowed Mode https://i.imgur.com/KOP2yK3.png
--   Web Interface https://i.imgur.com/DPcRCGh.png
-- @about
--   # Song Switcher
--
--   The purpose of this script is to quickly switch between songs in a single
--   project during live shows. It is a replacement for the slow
--   SWS Snapshots (visibility + mute).
--
--   ## Usage
--
--   Each song must be in a top-level folder track named "#. Song Name"
--   ("#" being any number).
--
--   After selecting a song, Song Switcher mutes and hides all songs in the
--   project except for the current one. Other tracks/folders that are not part
--   of a song's top-level folder are left untouched.  
--   Song Switcher can also optionally stop playback and/or seek to the
--   first item in the song when switching.
--
--   This script works best with REAPER settings "**Do not process muted tracks**"
--   and "**Track mute fade**" enabled.
--
--   The following actions are included:
--
--   - **cfillion_Song Switcher.lua**:
--     This is the main script. It must be open to use the others.
--   - **cfillion_Song Switcher (previous).lua**: Goes to the previous song
--   - **cfillion_Song Switcher (next).lua**: Goes to the next song
--   - **cfillion_Song Switcher (reset).lua**: Rebuilds the song list
--
--   A web browser interface is also installed as **song_switcher.html** for
--   remote use (this feature requires REAPER v5.30+ and ReaPack v1.1+).

WINDOW_TITLE = 'Song Switcher'

FONT_DEFAULT = 0
FONT_LARGE = 1
FONT_SMALL = 2
FONT_HUGE = 3

COLOR_WHITE = {255, 255, 255}
COLOR_GRAY = {190, 190, 190}
COLOR_BLACK = {0, 0, 0}
COLOR_RED = {255, 0, 0}

COLOR_NAME = COLOR_WHITE
COLOR_FILTER = COLOR_WHITE
COLOR_BORDER = COLOR_GRAY
COLOR_BUTTON = COLOR_GRAY
COLOR_HOVERBG = {30, 30, 30}
COLOR_HOVERFG = COLOR_WHITE
COLOR_ACTIVEBG = {124, 165, 215}
COLOR_ACTIVEFG = COLOR_BLACK
COLOR_DANGERBG = COLOR_RED
COLOR_DANGERFG = COLOR_BLACK
COLOR_HIGHLIGHTBG = {60, 90, 100}
COLOR_HIGHLIGHTFG = COLOR_WHITE

KEY_ESCAPE = 27
KEY_SPACE = 32
KEY_UP = 30064
KEY_DOWN = 1685026670
KEY_RIGHT = 1919379572
KEY_LEFT = 1818584692
KEY_INPUTRANGE_FIRST = 32
KEY_INPUTRANGE_LAST = 125
KEY_ENTER = 13
KEY_BACKSPACE = 8
KEY_CTRLU = 21
KEY_CLEAR = 144
KEY_PGUP = 1885828464
KEY_PGDOWN = 1885824110
KEY_MINUS = 45
KEY_PLUS = 43
KEY_STAR = 42
KEY_F3 = 26163

PADDING = 3
MARGIN = 10
HALF_MARGIN = 5
LIST_START = 50

EXT_SECTION = 'cfillion_song_switcher'
EXT_SWITCH_MODE = 'onswitch'
EXT_WINDOW_STATE = 'window_state'
EXT_LAST_DOCK = 'last_dock'
EXT_REL_MOVE = 'relative_move'
EXT_RESET = 'reset'
EXT_STATE = 'state'
EXT_FILTER = 'filter'

SWITCH_NOACTION = 0
SWITCH_SEEK = 1
SWITCH_SEEKSTOP = 2

function loadTracks()
  local songs = {}
  local depth = 0
  local isSong = false

  for index=0,reaper.GetNumTracks()-1 do
    local track = reaper.GetTrack(0, index)

    local track_depth = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')

    if depth == 0 and track_depth == 1 then
      local _, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

      if name:find("%d+%.") then
        isSong = true
        table.insert(songs, {name=name, folder=track, tracks={track}})
      else
        isSong = false
      end
    elseif depth >= 1 and isSong then
      local song = songs[#songs]
      song.tracks[#song.tracks + 1] = track

      for itemIndex=0,reaper.CountTrackMediaItems(track)-1 do
        local item = reaper.GetTrackMediaItem(track, itemIndex)
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local endTime = pos + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')

        if not song.startTime or song.startTime > pos then
          song.startTime = pos
        end
        if not song.endTime or song.endTime < endTime then
          song.endTime = endTime
        end
      end
    end

    depth = depth + track_depth
  end

  for _,song in ipairs(songs) do
    if not song.startTime then song.startTime = 0 end
    if not song.endTime then song.endTime = reaper.GetProjectLength() end
  end

  table.sort(songs, compareSongs)
  return songs
end

function getSongNum(song)
  return tonumber(string.match(song.name, '^%d+'))
end

function compareSongs(a, b)
  local anum, bnum = getSongNum(a), getSongNum(b)

  if anum and bnum then
    return anum < bnum
  else
    return a.name < b.name
  end
end

function isSongValid(song)
  for _,track in ipairs(song.tracks) do
    if not reaper.ValidatePtr(track, 'MediaTrack*') then
      return false
    end
  end

  return true
end

function setSongEnabled(song, enabled)
  if song == nil then return end

  invalid = not isSongValid(song)
  if invalid then return false end

  local on, off = 1, 0

  if not enabled then
    on, off = 0, 1
  end

  reaper.SetMediaTrackInfo_Value(song.folder, 'B_MUTE', off)

  for _,track in ipairs(song.tracks) do
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINMIXER', on)
    reaper.SetMediaTrackInfo_Value(track, 'B_SHOWINTCP', on)
  end

  return true
end

function setCurrentIndex(index)
  reaper.PreventUIRefresh(1)

  if currentIndex < 1 then
    for _,song in ipairs(songs) do
      setSongEnabled(song, false)
    end
  elseif index ~= currentIndex then
    setSongEnabled(songs[currentIndex], false)
  end

  local song = songs[index]
  local disableOk = not invalid
  local enableOk = setSongEnabled(song, true)

  if enableOk or disableOk then
    currentIndex = index
    setNextIndex(index)

    local mode = getSwitchMode()
    if mode == SWITCH_SEEKSTOP then
      reaper.CSurf_OnStop()
    end
    if mode == SWITCH_SEEK or mode == SWITCH_SEEKSTOP then
      reaper.SetEditCurPos(song.startTime, true, true)
    end
  end

  reaper.PreventUIRefresh(-1)

  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()

  filterPrompt = false
  filterBuffer = ''
  updateState();
end

function trySetCurrentIndex(index)
  if songs[index] then
    setCurrentIndex(index)
  end
end

function setNextIndex(index)
  if songs[index] then
    nextIndex = index
    scrollTo = index
    highlightTime = os.time()
  end
end

function findSong(buffer)
  if string.len(buffer) == 0 then return end
  buffer = string.upper(buffer)

  local index = 0
  local song = songs[index]

  for index, song in ipairs(songs) do
    local name = string.upper(song.name)

    if string.find(name, buffer, 0, true) ~= nil then
      return index, song
    end
  end
end

function useColor(color)
  gfx.r = color[1] / 255
  gfx.g = color[2] / 255
  gfx.b = color[3] / 255
end

function textLine(text, x, padding)
  local w, h = gfx.measurestr(text)
  local y = gfx.y

  if x == nil then
    x = math.max(0, (gfx.w - w) / 2)
  end

  local tx, ty, tw = x, y, w

  if padding ~= nil then
    x = x - padding
    w = w + (padding * 2)

    ty = y + padding
    h = h + (padding * 2)
  end

  local rect = {x=0, y=y, w=gfx.w, h=h}
  return {text=text, rect=rect, tx=tx, ty=ty, tw=tw}
end

function drawTextLine(line)
  gfx.x = line.tx
  gfx.y = line.ty

  gfx.drawstr(line.text)
  gfx.y = line.rect.y + line.rect.h
end

function drawName(song)
  local name = '## No Song Selected ##'

  if song ~= nil then
    name = song.name
  end

  line = textLine(name)

  if invalid then
    useColor(COLOR_DANGERBG)
    gfx.rect(line.rect.x, line.rect.y, line.rect.w, line.rect.h)
  end

  useColor(COLOR_NAME)
  drawTextLine(line)

  if isLineUnderMouse(line) and isDoubleClick then
    filterPrompt = true
  end
end

function drawFilter()
  useColor(COLOR_FILTER)

  local buffer = filterBuffer

  if string.len(buffer) == 0 then
    buffer = "\x20"
  end

  local line = textLine(buffer)
  drawTextLine(line)

  if os.time() % 2 == 0 then
    local topRight = line.tx + line.tw
    gfx.line(topRight, line.ty, topRight, line.ty + line.rect.h)
  end

  if isLineUnderMouse(line) and isDoubleClick then
    filterPrompt = false
  end
end

function songList(y)
  gfx.setfont(FONT_DEFAULT)
  gfx.y = y - scrollOffset

  local lastIndex, line, bottom, newScrollOffset

  for index, song in ipairs(songs) do
    lastIndex = index
    line = textLine(song.name, MARGIN, PADDING)
    bottom = line.rect.y + line.rect.h

    if line.rect.y >= y - line.rect.h and bottom < gfx.h + line.rect.h then
      if button(line, index == currentIndex, index == nextIndex) then
        setCurrentIndex(index)
      end
    else
      gfx.y = bottom
    end

    if index == scrollTo then
      if bottom + line.rect.h > gfx.h then
        -- scroll down
        newScrollOffset = scrollOffset + (bottom - gfx.h) + line.rect.h
      elseif line.rect.y <= y + line.rect.h then
        -- scroll up
        newScrollOffset = scrollOffset - ((y - line.rect.y) + line.rect.h)
      end
    end
  end

  scrollTo = 0

  if lastIndex then
    maxScrollOffset = math.max(0,
      scrollOffset + (bottom - gfx.h) + PADDING)

    scrollbar(y, gfx.h - y)
  end

  scrollOffset = math.max(0,
    math.min(newScrollOffset or scrollOffset, maxScrollOffset))
end

function scrollbar(top, height)
  if maxScrollOffset < 1 then return end

  height = height - MARGIN

  local bottom = height + maxScrollOffset
  local percent = height / bottom

  useColor(COLOR_BORDER)
  gfx.rect((gfx.w - MARGIN), top + (scrollOffset * percent), 4, height * percent)
end

function resetButton()
  gfx.setfont(FONT_DEFAULT)
  gfx.x = 0
  gfx.y = 0

  btn = textLine('reset')
  btn.tx = btn.rect.w - btn.tw
  btn.rect.w = btn.tw
  btn.rect.x = btn.tx

  if button(btn, false, false, true) then
    reset()
  end
end

function switchModeButton()
  gfx.setfont(FONT_DEFAULT)
  gfx.x = 0
  gfx.y = LIST_START - (MARGIN / 2)

  local mode, action = getSwitchMode()

  if mode == SWITCH_SEEK then
    action = 'seek'
  elseif mode == SWITCH_SEEKSTOP then
    action = 'seek+stop'
  else
    action = 'onswitch'
  end

  btn = textLine(action)
  btn.tx = btn.rect.w - btn.tw
  btn.ty = btn.ty - btn.rect.h
  btn.rect.w = btn.tw
  btn.rect.x = btn.tx
  btn.rect.y = btn.ty

  if button(btn, mode > SWITCH_NOACTION, false, false) then
    setSwitchMode((mode + 1) % (SWITCH_SEEKSTOP + 1))
  end
end

function dockButton()
  gfx.setfont(FONT_DEFAULT)
  gfx.x = 0
  gfx.y = 0

  btn = textLine('dock', 0)
  btn.rect.w = btn.tw

  local dockState = gfx.dock(-1)

  if button(btn, dockState ~= 0, false, false) then
    if dockState == 0 then
      local lastDock = tonumber(reaper.GetExtState(EXT_SECTION,
        EXT_LAST_DOCK))
      if not lastDock or lastDock < 1 then lastDock = 1 end

      gfx.dock(lastDock)
    else
      reaper.SetExtState(EXT_SECTION, EXT_LAST_DOCK,
        tostring(dockState), true)
      gfx.dock(0)
    end
  end
end

function navButtons()
  gfx.setfont(FONT_HUGE)

  if currentIndex > 1 then
    gfx.y = MARGIN + PADDING

    prev = textLine('◀', 0)
    prev.rect.x = gfx.y
    prev.tx = gfx.y
    prev.rect.w = prev.tw

    if button(prev, false, false, false) then
      setCurrentIndex(currentIndex - 1)
    end
  end

  if songs[currentIndex + 1] then
    gfx.y = MARGIN + PADDING

    next = textLine('▶', 0)
    next.tx = next.rect.w - next.tw - gfx.y
    next.rect.x = next.tx
    next.rect.w = next.tw

    if button(next, false, false, false) then
      setCurrentIndex(currentIndex + 1)
    end
  end
end

function button(line, active, highlight, danger)
  local color, triggered = COLOR_BUTTON, false

  if active then
    useColor(COLOR_ACTIVEBG)
    gfx.rect(line.rect.x, line.rect.y, line.rect.w, line.rect.h)
    color = COLOR_ACTIVEFG
  end

  if isUnderMouse(line.rect.x, line.rect.y, line.rect.w, line.rect.h) then
    if mouseState > 0 then
      if danger then
        useColor(COLOR_DANGERBG)
        color = COLOR_DANGERFG
      else
        useColor(COLOR_HIGHLIGHTBG)
        color = COLOR_HIGHLIGHTFG
      end
    elseif not active then
      useColor(COLOR_HOVERBG)
      color = COLOR_HOVERFG
    end

    gfx.rect(line.rect.x, line.rect.y, line.rect.w, line.rect.h)

    if mouseClick then
      triggered = true
    end
  end

  -- draw highlight rect after mouse colors
  -- so that hover don't override it
  if highlight and not active and shouldShowHighlight() then
    useColor(COLOR_HIGHLIGHTBG)
    color = COLOR_HIGHLIGHTFG
    gfx.rect(line.rect.x, line.rect.y, line.rect.w, line.rect.h)
  end

  useColor(color)
  drawTextLine(line)

  return triggered
end

function shouldShowHighlight()
  local time = os.time() - highlightTime
  return time < 2 or time % 2 == 0
end

function keyboard()
  local input = gfx.getchar()

  if input < 0 then
    -- bye bye!
    return false
  end

  -- if input ~= 0 then
  --   reaper.ShowConsoleMsg(input)
  --   reaper.ShowConsoleMsg("\n")
  -- end

  if filterPrompt then
    filterKey(input)
  else
    normalKey(input)
  end

  return true
end

function filterKey(input)
  if input == KEY_BACKSPACE then
    if filterBuffer:len() == 0 then
      filterPrompt = false
    else
      filterBuffer = string.sub(filterBuffer, 0, -2)
    end
  elseif input == KEY_CLEAR or input == KEY_CTRLU then
    filterBuffer = ''
  elseif input == KEY_ESCAPE then
    filterPrompt = false
    filterBuffer = ''
  elseif input == KEY_ENTER then
    local index, _ = findSong(filterBuffer)

    if index then
      setCurrentIndex(index)
    end

    filterPrompt = false
    filterBuffer = ''
  elseif input >= KEY_INPUTRANGE_FIRST and input <= KEY_INPUTRANGE_LAST then
    filterBuffer = filterBuffer .. string.char(input)
  end
end

function normalKey(input)
  if (input == KEY_ESCAPE and dockedState == 0) or input == KEY_STAR then
    gfx.quit()
  elseif input == KEY_SPACE then
    local playing = reaper.GetPlayState() == 1

    if playing then
      reaper.OnStopButton()
    else
      reaper.OnPlayButton()
    end
  elseif input == KEY_UP or input == KEY_LEFT then
    setNextIndex(nextIndex - 1)
  elseif input == KEY_DOWN or input == KEY_RIGHT then
    setNextIndex(nextIndex + 1)
  elseif input == KEY_PGUP or input == KEY_MINUS then
    trySetCurrentIndex(currentIndex - 1)
  elseif input == KEY_PGDOWN or input == KEY_PLUS then
    trySetCurrentIndex(currentIndex + 1)
  elseif input == KEY_CLEAR then
    reset()
  elseif input == KEY_F3 then
    reaper.Main_OnCommand(40345, 0) -- send all note off
  elseif input == KEY_ENTER then
    if nextIndex == currentIndex then
      filterPrompt = true
    else
      setCurrentIndex(nextIndex)
    end
  end
end

function isUnderMouse(x, y, w, h)
  local hor, ver = false, false

  if gfx.mouse_x > x and gfx.mouse_x <= x + w then
    hor = true
  end

  if gfx.mouse_y > y and gfx.mouse_y <= y + h then
    ver = true
  end

  if hor and ver then return true else return false end
end

function isLineUnderMouse(line)
  return isUnderMouse(line.rect.x, line.rect.y, line.rect.w, line.rect.h)
end

function mouse()
  isDoubleClick = false
  mouseClick = false

  if gfx.mouse_wheel ~= 0 then
    local offset = math.max(0, scrollOffset - gfx.mouse_wheel)
    scrollOffset = math.min(offset, maxScrollOffset)

    gfx.mouse_wheel = 0
  end

  if mouseState == 0 and gfx.mouse_cap ~= 0 then
    -- NOTE: mouse press handling here
  end

  if mouseState == 3 and gfx.mouse_cap < 3 and gfx.mouse_cap >= 0 then
    -- two button release
    -- also triggered if one button is released slightly before the other
    reset()
  elseif mouseState == 1 and gfx.mouse_cap == 0 then
    -- left button release

    local now = os.clock()
    if lastClick > now - 0.2 then
      isDoubleClick = true
      lastClick = 0
    else
      lastClick = now
    end

    mouseClick = true
  end

  mouseState = gfx.mouse_cap
end

function loop()
  execRemoteActions()

  local fullUI = gfx.h > LIST_START + MARGIN

  if fullUI then
    songList(LIST_START)

    -- solid header background, to hide scrolled list items
    gfx.y = MARGIN
    useColor(COLOR_BLACK)
    gfx.rect(0, 0, gfx.w, LIST_START)

    -- separator line
    gfx.y = LIST_START - HALF_MARGIN
    useColor(COLOR_BORDER)
    gfx.line(0, gfx.y, gfx.w, gfx.y)

    dockButton()
    switchModeButton()
    resetButton()

    gfx.setfont(FONT_LARGE)
  else
    gfx.y = MARGIN + PADDING
    gfx.setfont(FONT_HUGE)
  end

  if filterPrompt then
    drawFilter()
  else
    drawName(songs[currentIndex])
  end

  if not fullUI then
    navButtons()
  end

  gfx.update()

  if keyboard() then
    reaper.defer(loop)
  end

  mouse()
end

function execRemoteActions()
  if reaper.HasExtState(EXT_SECTION, EXT_REL_MOVE) then
    local move = tonumber(reaper.GetExtState(EXT_SECTION, EXT_REL_MOVE))
    reaper.DeleteExtState(EXT_SECTION, EXT_REL_MOVE, false);

    if move then
      trySetCurrentIndex(currentIndex + move)
    end
  end

  if reaper.HasExtState(EXT_SECTION, EXT_RESET) then
    reaper.DeleteExtState(EXT_SECTION, EXT_RESET, false);
    reset()
  end

  if reaper.HasExtState(EXT_SECTION, EXT_FILTER) then
    local filter = reaper.GetExtState(EXT_SECTION, EXT_FILTER)
    reaper.DeleteExtState(EXT_SECTION, EXT_FILTER, false);

    local index, _ = findSong(filter)

    if index then
      setCurrentIndex(index)
    end
  end
end

function reset()
  songs = loadTracks()

  local activeIndex, activeCount, visibleCount = nil, 0, 0

  for index,song in ipairs(songs) do
    local muted = reaper.GetMediaTrackInfo_Value(song.folder, 'B_MUTE')

    if muted == 0 then
      if activeIndex == nil then
        activeIndex = index
      end

      activeCount = activeCount + 1
    end

    if activeIndex ~= index then
      for _,track in ipairs(song.tracks) do
        local tcp = reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINTCP')
        local mixer = reaper.GetMediaTrackInfo_Value(track, 'B_SHOWINMIXER')

        if tcp == 1 or mixer == 1 then
          visibleCount = visibleCount + 1
        end
      end
    end
  end

  currentIndex = 0
  nextIndex = 0
  invalid = false
  scrollOffset = 0
  maxScrollOffset = 0
  filterPrompt = false
  filterBuffer = ''

  -- clear previous pending external commands
  reaper.DeleteExtState(EXT_SECTION, EXT_REL_MOVE, false)
  reaper.DeleteExtState(EXT_SECTION, EXT_RESET, false)
  reaper.DeleteExtState(EXT_SECTION, EXT_FILTER, false)

  if activeCount == 1 then
    if visibleCount == 0 then
      currentIndex = activeIndex
      nextIndex = activeIndex
      scrollTo = activeIndex

      updateState();
    else
      setCurrentIndex(activeIndex)
    end
  else
    updateState();
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

function getSwitchMode()
  local mode = tonumber(reaper.GetExtState(EXT_SECTION, EXT_SWITCH_MODE))

  if mode and mode <= SWITCH_SEEKSTOP then
    return mode
  else
    return SWITCH_NOACTION
  end
end

function setSwitchMode(mode)
  reaper.SetExtState(EXT_SECTION, EXT_SWITCH_MODE, tostring(mode), true)
end

function updateState()
  local song = songs[currentIndex] or {name='', startTime=0, endTime=0}

  local state = string.format("%d\t%d\t%s\t%f\t%f\t%s",
    currentIndex, #songs, song.name, song.startTime, song.endTime,
    tostring(invalid)
  )
  reaper.SetExtState(EXT_SECTION, EXT_STATE, state, false)
end

-- graphics initialization
mouseState = 0
mouseClick = false
highlightTime = 0
scrollTo = 0
lastClick = 0
isDoubleClick = false

local w, h, dockState, x, y = previousWindowState()

if w then
  gfx.init(WINDOW_TITLE, w, h, dockState, x, y)
else
  gfx.init(WINDOW_TITLE, 500, 300)
end

gfx.setfont(FONT_HUGE, 'sans-serif', 36)
gfx.setfont(FONT_LARGE, 'sans-serif', 28)
gfx.setfont(FONT_SMALL, 'sans-serif', 13)

-- other variable initializations in reset()
reset()

-- GO!!
loop()

reaper.atexit(function()
  saveWindowState()
  reaper.DeleteExtState(EXT_SECTION, EXT_STATE, false)
end)

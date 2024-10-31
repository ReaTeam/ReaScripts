-- @description Song switcher (for live use)
-- @author cfillion
-- @version 1.7.1
-- @changelog fix validation of song tracks when the project tab is inactive
-- @provides
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Switch to next song.lua
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Switch to previous song.lua
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Reset data.lua
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Switch to queued song.lua
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Switch song by MIDI CC.lua
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Queue next song.lua
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Queue previous song.lua
--   [main] cfillion_Song switcher/cfillion_Song switcher - Send signal.lua > cfillion_Song switcher/cfillion_Song switcher - Queue song by MIDI CC.lua
--   [webinterface] cfillion_Song switcher/song_switcher.html > song_switcher.html
-- @link Forum Thread https://forum.cockos.com/showthread.php?t=181159
-- @screenshot
--   Windowed mode https://i.imgur.com/9tcudKT.png
--   Docked mode https://i.imgur.com/4xPMV9J.gif
--   Web interface https://i.imgur.com/DPcRCGh.png
-- @donation https://reapack.com/donate
-- @about
--   # Song switcher
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
--   After selecting a song, Song switcher mutes and hides all songs in the
--   project except for the current one. Other tracks/folders that are not part
--   of a song's top-level folder are left untouched.  
--   Song switcher can also optionally stop playback and/or seek to the
--   first item in the song when switching.
--
--   This script works best with REAPER settings "**Do not process muted tracks**"
--   and "**Track mute fade**" enabled.
--
--   The following additional actions are included for communicating to the main script:
--   - cfillion_Song switcher - Switch to previous song.lua
--   - cfillion_Song switcher - Switch to next song.lua
--   - cfillion_Song switcher - Switch song by MIDI CC.lua
--   - cfillion_Song switcher - Switch to queued song.lua
--   - cfillion_Song switcher - Reset data.lua
--
--   Take markers starting with a `!` within the current song's folder track are treated as action markers.
--
--   A web browser interface is also installed as **song_switcher.html** for
--   remote use (this feature requires REAPER v5.30+ and ReaPack v1.1+).
--   Note that the timecode displayed in the web interface always starts at 00:00 for convenience.
--   This means that a song spanning from 7:45 to 9:12 in the project is displayed as 00:00 to 01:26 on the web interface.

local SCRIPT_NAME = 'Song switcher'

if not reaper.ImGui_GetBuiltinPath then
  return reaper.MB('ReaImGui is not installed or too old.', SCRIPT_NAME, 0)
end
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.3'

local EXT_SECTION     = 'cfillion_song_switcher'
local EXT_SWITCH_MODE = 'onswitch'
local EXT_LAST_DOCK   = 'last_dock'
local EXT_STATE       = 'state'

local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()

local SWITCH_SEEK   = 1<<0
local SWITCH_STOP   = 1<<1
local SWITCH_SCROLL = 1<<2

local UNDO_STATE_TRACKCFG = 1

local scrollTo, setDock
-- initialized in reset()
local currentIndex, nextIndex, invalid, filterPrompt
local signals = {}
local prevPlayPos

local fonts = {
  small = ImGui.CreateFont('sans-serif', 13),
  large = ImGui.CreateFont('sans-serif', 28),
  huge  = ImGui.CreateFont('sans-serif', 38),
}

local ctx = ImGui.CreateContext(SCRIPT_NAME)

for key, font in pairs(fonts) do
  ImGui.Attach(ctx, font)
end

local function parseSongName(trackName)
  local number, separator, name = string.match(trackName, '^(%d+)(%W+)(.+)$')
  number = tonumber(number)

  if number and separator and name then
    return {number=number, separator=separator, name=name}
  end
end

local function compareSongs(a, b)
  local aparts, bparts = parseSongName(a.name), parseSongName(b.name)

  if aparts.number == bparts.number then
    return aparts.name < bparts.name
  else
    return aparts.number < bparts.number
  end
end

local function loadTracks()
  local songs = {}
  local depth = 0
  local isSong = false

  for index=0,reaper.GetNumTracks()-1 do
    local track = reaper.GetTrack(0, index)

    local track_depth = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERDEPTH')

    if depth == 0 and track_depth == 1 then
      local _, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)

      if parseSongName(name) then
        isSong = true
        table.insert(songs, {name=name, folder=track, tracks={track}, uniqId=#songs})
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

local function isSongValid(song)
  for _,track in ipairs(song.tracks) do
    if not pcall(reaper.GetTrackNumMediaItems, track) then
      return false
    end
  end

  return true
end

local function setSongEnabled(song, enabled)
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

local function updateState()
  local song = songs[currentIndex] or {name='', startTime=0, endTime=0}

  local state = ("%d\t%d\t%s\t%f\t%f\t%s"):format(
    currentIndex, #songs, song.name, song.startTime, song.endTime,
    tostring(invalid)
  )
  reaper.SetExtState(EXT_SECTION, EXT_STATE, state, false)
end

local function getSwitchMode()
  local mode = tonumber(reaper.GetExtState(EXT_SECTION, EXT_SWITCH_MODE))
  return mode and mode or 0
end

local function setSwitchMode(mode)
  reaper.SetExtState(EXT_SECTION, EXT_SWITCH_MODE, tostring(mode), true)
end

local function setNextIndex(index)
  if songs[index] then
    nextIndex = index
    scrollTo = index
    highlightTime = ImGui.GetTime(ctx)
  end
end

local function setCurrentIndex(index)
  reaper.PreventUIRefresh(1)

  if currentIndex < 1 then
    for _,song in ipairs(songs) do
      setSongEnabled(song, false)
    end
  elseif index ~= currentIndex then
    setSongEnabled(songs[currentIndex], false)
  end

  local mode = getSwitchMode()

  if mode & SWITCH_STOP ~= 0 then
    reaper.CSurf_OnStop()
  end

  local song = songs[index]
  local disableOk = not invalid
  local enableOk = setSongEnabled(song, true)

  if enableOk or disableOk then
    currentIndex = index
    setNextIndex(index)

    if mode & SWITCH_SEEK ~= 0 then
      reaper.SetEditCurPos(song.startTime, true, true)
    end

    if mode & SWITCH_SCROLL ~= 0 then
      reaper.GetSet_ArrangeView2(0, true, 0, 0, song.startTime, song.endTime + 5)
    end
  end

  reaper.PreventUIRefresh(-1)

  reaper.TrackList_AdjustWindows(false)
  reaper.UpdateArrange()

  filterPrompt = false
  updateState()
end

local function trySetCurrentIndex(index)
  if songs[index] then
    setCurrentIndex(index)
  end
end

local function moveSong(from, to)
  local target = songs[from]
  songs[from] = songs[to]
  songs[to]   = target

  if currentIndex == from then
    currentIndex = to
  elseif to <= currentIndex and from > currentIndex then
    currentIndex = currentIndex + 1
  elseif from < currentIndex and to >= currentIndex then
    currentIndex = currentIndex - 1
  end

  if nextIndex == from then
    nextIndex = to
  elseif to <= nextIndex and from > nextIndex then
    nextIndex = nextIndex + 1
  elseif from < nextIndex and to >= nextIndex then
    nextIndex = nextIndex - 1
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local maxNumLength = math.max(2, tostring(#songs):len())
  for index, song in ipairs(songs) do
    local nameParts = parseSongName(song.name)
    local newName = string.format('%0' .. maxNumLength .. 'd%s%s',
      index, nameParts.separator, nameParts.name)
    song.name = newName

    if reaper.ValidatePtr(song.folder, 'MediaTrack*') then
      reaper.GetSetMediaTrackInfo_String(song.folder, 'P_NAME', newName, true)
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.Undo_EndBlock('Song switcher: Change song order', UNDO_STATE_TRACKCFG)
end

local function findSong(buffer)
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

local function reset()
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

  filterPrompt, invalid = false, false
  currentIndex, nextIndex, scrollTo = 0, 0, 0
  highlightTime = ImGui.GetTime(ctx)
  prevPlayPos = nil

  -- clear previous pending external commands
  for signal, _ in pairs(signals) do
    reaper.DeleteExtState(EXT_SECTION, signal, false)
  end

  if activeCount == 1 then
    if visibleCount == 0 then
      currentIndex = activeIndex
      nextIndex = activeIndex
      scrollTo = activeIndex

      updateState()
    else
      setCurrentIndex(activeIndex)
    end
  else
    updateState()
  end
end

local function execRemoteActions()
  for signal, handler in pairs(signals) do
    if reaper.HasExtState(EXT_SECTION, signal) then
      local value = reaper.GetExtState(EXT_SECTION, signal)
      reaper.DeleteExtState(EXT_SECTION, signal, false);
      handler(value)
    end
  end
end

local function getParentProject(track)
  local search = reaper.GetMediaTrackInfo_Value(track, 'P_PROJECT')

  if reaper.JS_Window_HandleFromAddress then
    return reaper.JS_Window_HandleFromAddress(search)
  end

  for i = 0, math.huge do
    local project = reaper.EnumProjects(i)
    if not project then break end

    local master = reaper.GetMasterTrack(project)
    if search == reaper.GetMediaTrackInfo_Value(master, 'P_PROJECT') then
      return project
    end
  end
end

local function execTakeMarkers()
  if not reaper.GetNumTakeMarkers then return end -- REAPER v5

  local song = songs[currentIndex]
  local track = song and song.tracks[1]
  local valid, numItems = pcall(reaper.GetTrackNumMediaItems, track)
  if not valid then return end -- validates track across all tabs

  local proj = getParentProject(track)
  if reaper.GetPlayStateEx(proj) & 3 ~= 1 then return end -- not playing or paused

  local playPos = reaper.GetPlayPositionEx(proj)
  if playPos == prevPlayPos then return end

  local minPos, maxPos = playPos, playPos
  if prevPlayPos and playPos > prevPlayPos and (playPos - prevPlayPos) < 0.1 then
    minPos = prevPlayPos
  end
  prevPlayPos = playPos

  for ii = 0, numItems - 1 do
    local item = reaper.GetTrackMediaItem(track, ii)
    local mute = reaper.GetMediaItemInfo_Value(item, 'B_MUTE')
    local pos  = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local len  = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    local take = reaper.GetActiveTake(item)

    if take and mute == 0 and pos <= minPos and pos + len > maxPos then
      local offs = reaper.GetMediaItemTakeInfo_Value(take, 'D_STARTOFFS')

      for mi = 0, reaper.GetNumTakeMarkers(take) - 1 do
        local time, name = reaper.GetTakeMarker(take, mi)
        time = time + pos - offs
        if time >= minPos and time <= maxPos and name:sub(1, 1) == '!' then
          for action in name:sub(2):gmatch('%S+') do
            local action = reaper.NamedCommandLookup(action)
            if action ~= 0 then reaper.Main_OnCommandEx(action, 0, proj) end
          end
        end
      end
    end
  end
end

function drawName(song)
  local name = song and song.name or 'No song selected'

  ImGui.PushStyleColor(ctx, ImGui.Col_Text,
    ImGui.GetStyleColor(ctx, (song and ImGui.Col_Text or ImGui.Col_TextDisabled)))
  ImGui.PushStyleColor(ctx, ImGui.Col_Button, invalid and 0xff0000ff or 0)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x323232ff)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  0x3232327f)
  if ImGui.Button(ctx, ('%s###song_name'):format(name), -FLT_MIN) then
    filterPrompt = true
  end
  ImGui.PopStyleColor(ctx, 4)
end

local function drawFilter()
  ImGui.SetNextItemWidth(ctx, -FLT_MIN)
  ImGui.SetKeyboardFocusHere(ctx)
  local rv, filter = ImGui.InputText(ctx, '##name_fiter', '', ImGui.InputTextFlags_EnterReturnsTrue)
  if ImGui.IsItemDeactivated(ctx) then
    filterPrompt = false
  end
  if rv then
    local index, _ = findSong(filter)

    if index then
      setCurrentIndex(index)
    end
  end
end

local function formatTime(time)
  return reaper.format_timestr(time, '')
end

local function songList(y)
  local flags = ImGui.TableFlags_Borders   |
                ImGui.TableFlags_RowBg     |
                ImGui.TableFlags_ScrollY   |
                ImGui.TableFlags_Hideable  |
                ImGui.TableFlags_Resizable |
                ImGui.TableFlags_Reorderable
  if not ImGui.BeginTable(ctx, 'song_list', 4, flags, -FLT_MIN, -FLT_MIN) then return end

  ImGui.TableSetupColumn(ctx, '#. Name',   ImGui.TableColumnFlags_WidthStretch)
  ImGui.TableSetupColumn(ctx, 'Start',  ImGui.TableColumnFlags_WidthFixed)
  ImGui.TableSetupColumn(ctx, 'End',    ImGui.TableColumnFlags_WidthFixed)
  ImGui.TableSetupColumn(ctx, 'Length', ImGui.TableColumnFlags_WidthFixed)
  ImGui.TableSetupScrollFreeze(ctx, 0, 1)
  ImGui.TableHeadersRow(ctx)

  local swap
  for index, song in ipairs(songs) do
    ImGui.TableNextRow(ctx)

    ImGui.TableNextColumn(ctx)
    local color = ImGui.GetStyleColor(ctx, ImGui.Col_Header)
    local isCurrent, isNext = index == currentIndex, index == nextIndex
    if isNext and not isCurrent then
      -- swap blue <-> green
      color = (color & 0xFF0000FF) | (color & 0x00FF0000) >> 8 | (color & 0x0000FF00) << 8
      if (math.floor(highlightTime - ImGui.GetTime(ctx)) & 1) == 0 then
        color = (color & ~0xff) | 0x1a
      end
    end
    ImGui.PushStyleColor(ctx, ImGui.Col_Header, color)
    if ImGui.Selectable(ctx, ('%s###%d'):format(song.name, song.uniqId),
        isCurrent or isNext,
        ImGui.SelectableFlags_SpanAllColumns) then
      setCurrentIndex(index)
    end
    if ImGui.IsItemActive(ctx) and not ImGui.IsItemHovered(ctx) then
      local mouseDelta = select(2, ImGui.GetMouseDragDelta(ctx, nil, nil, ImGui.MouseButton_Left))
      local newIndex = index + (mouseDelta < 0 and -1 or 1)
      if newIndex > 0 and newIndex <= #songs then
        swap = { from=index, to=newIndex }
        ImGui.ResetMouseDragDelta(ctx, ImGui.MouseButton_Left)
      end
    end
    ImGui.PopStyleColor(ctx)

    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, formatTime(song.startTime))

    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, formatTime(song.endTime))

    ImGui.TableNextColumn(ctx)
    ImGui.Text(ctx, formatTime(song.endTime - song.startTime))

    if index == scrollTo then
      ImGui.SetScrollHereY(ctx, 1)
    end
  end

  ImGui.EndTable(ctx)
  scrollTo = nil

  if swap then
    moveSong(swap.from, swap.to)
  end
end

local function switchModeMenu()
  local mode = getSwitchMode()
  if ImGui.MenuItem(ctx, 'Stop playback', nil, mode & SWITCH_STOP ~= 0) then
    setSwitchMode(mode ~ SWITCH_STOP)
  end
  if ImGui.MenuItem(ctx, 'Seek to first item', nil, mode & SWITCH_SEEK ~= 0) then
    setSwitchMode(mode ~ SWITCH_SEEK)
  end
  if ImGui.MenuItem(ctx, 'Scroll to first item', nil, mode & SWITCH_SCROLL ~= 0) then
    setSwitchMode(mode ~ SWITCH_SCROLL)
  end
end

local function switchModeButton()
  ImGui.SmallButton(ctx, 'onswitch')
  if ImGui.BeginPopupContextItem(ctx, 'onswitch_menu', ImGui.PopupFlags_MouseButtonLeft) then
    switchModeMenu()
    ImGui.EndPopup(ctx)
  end
end

local function toggleDock(dockId)
  dockId = dockId or ImGui.GetWindowDockID(ctx)
  if dockId >= 0 then
    local lastDock = tonumber(reaper.GetExtState(EXT_SECTION, EXT_LAST_DOCK))
    if not lastDock or lastDock < 0 or lastDock > 16 then lastDock = 0 end
    setDock = ~lastDock
  else
    reaper.SetExtState(EXT_SECTION, EXT_LAST_DOCK, tostring(~dockId), true)
    setDock = 0
  end
end

local function contextMenu()
  local dockId = ImGui.GetWindowDockID(ctx)
  if not ImGui.BeginPopupContextWindow(ctx, 'context_menu') then return end

  if ImGui.MenuItem(ctx, 'Dock window', nil, dockId ~= 0) then
    toggleDock(dockId)
  end
  if ImGui.MenuItem(ctx, 'Reset data') then
    reset()
  end
  if ImGui.BeginMenu(ctx, 'When switching to a song...') then
    switchModeMenu()
    ImGui.EndMenu(ctx)
  end
  ImGui.Separator(ctx)
  if #songs > 0 then
    for index, song in ipairs(songs) do
      if ImGui.MenuItem(ctx, song.name, nil, index == currentIndex) then
        setCurrentIndex(index)
      end
    end
    ImGui.Separator(ctx)
  end
  if ImGui.MenuItem(ctx, 'Help') then
    about()
  end

  ImGui.EndPopup(ctx)
end

function about()
  local owner = reaper.ReaPack_GetOwner((select(2, reaper.get_action_context())))
  if owner then
    reaper.ReaPack_AboutInstalledPackage(owner)
    reaper.ReaPack_FreeEntry(owner)
  else
    reaper.ShowMessageBox('Song switcher must be installed through ReaPack to use this feature.', SCRIPT_NAME, 0)
  end
end

local function navButtons()
  local pad_x, pad_y = 8, 8
  local dl = ImGui.GetWindowDrawList(ctx)
  local x1, y1 = ImGui.GetItemRectMin(ctx)
  local x2, y2 = ImGui.GetItemRectMax(ctx)
  local size = y2 - y1

  local col_text   = ImGui.GetColor(ctx, ImGui.Col_Text)
  local col_hover  = ImGui.GetColor(ctx, ImGui.Col_ButtonHovered)
  local col_active = ImGui.GetColor(ctx, ImGui.Col_ButtonActive)

  local function btn(isPrev)
    ImGui.SetCursorScreenPos(ctx, isPrev and x1 or (x2 - size), y1)

    if ImGui.InvisibleButton(ctx, isPrev and 'prev' or 'next', size, size) then
      setCurrentIndex(currentIndex + (isPrev and -1 or 1))
    end

    local color = ImGui.IsItemActive(ctx)  and col_active
               or ImGui.IsItemHovered(ctx) and col_hover
               or col_text

    local min_x, min_y = ImGui.GetItemRectMin(ctx)
    local max_x, max_y = ImGui.GetItemRectMax(ctx)
    local mid_y = min_y + ((max_y - min_y) / 2)
    min_x, min_y = min_x + pad_x, min_y + pad_y
    max_x, max_y = max_x - pad_x, max_y - pad_y

    if isPrev then
      ImGui.DrawList_AddTriangleFilled(dl,
        min_x, mid_y, max_x, min_y, max_x, max_y, color)
    else
      ImGui.DrawList_AddTriangleFilled(dl,
        min_x, min_y, max_x, mid_y, min_x, max_y, color)
    end
  end

  if currentIndex > 1        then btn(true)  end
  if songs[currentIndex + 1] then btn(false) end
end

local function keyInput(input)
  if ImGui.IsAnyItemActive(ctx) then return end

  if ImGui.Shortcut(ctx, ImGui.Key_UpArrow, ImGui.InputFlags_Repeat) or
     ImGui.Shortcut(ctx, ImGui.Key_LeftArrow, ImGui.InputFlags_Repeat) then
    setNextIndex(nextIndex - 1)
  elseif ImGui.Shortcut(ctx, ImGui.Key_DownArrow, ImGui.InputFlags_Repeat) or
         ImGui.Shortcut(ctx, ImGui.Key_RightArrow, ImGui.InputFlags_Repeat) then
    setNextIndex(nextIndex + 1)
  elseif ImGui.Shortcut(ctx, ImGui.Key_PageUp) or
         ImGui.Shortcut(ctx, ImGui.Key_KeypadSubtract) then
    trySetCurrentIndex(currentIndex - 1)
  elseif ImGui.Shortcut(ctx, ImGui.Key_PageDown) or
         ImGui.Shortcut(ctx, ImGui.Key_KeypadAdd) then
    trySetCurrentIndex(currentIndex + 1)
  elseif ImGui.Shortcut(ctx, ImGui.Key_Insert) or
         ImGui.Shortcut(ctx, ImGui.Key_NumLock) then
    reset()
  elseif ImGui.Shortcut(ctx, ImGui.Key_Enter) or
         ImGui.Shortcut(ctx, ImGui.Key_KeypadEnter) then
    if nextIndex == currentIndex then
      filterPrompt = true
    else
      setCurrentIndex(nextIndex)
    end
  end
end

local function buttonSize(label)
  return ImGui.CalcTextSize(ctx, label) +
    (ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding) * 2)
end

local function toolbar()
  local y_bak = ImGui.GetCursorPosY(ctx)
  local x1, y1 = ImGui.GetItemRectMin(ctx)
  local x2, y2 = ImGui.GetItemRectMax(ctx)
  local btn_height = ImGui.GetFontSize(ctx)

  local frame_padding_x, frame_padding_y = ImGui.GetStyleVar(ctx, ImGui.StyleVar_FramePadding)
  local item_spacing_x,  item_spacing_y  = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, frame_padding_x, math.floor(frame_padding_y * 0.60))
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,  item_spacing_x,  math.floor(item_spacing_y  * 0.60))
  ImGui.PushFont(ctx, nil)

  ImGui.SetCursorScreenPos(ctx, x1, y1)
  local dockLabel = ImGui.IsWindowDocked(ctx) and 'undock' or 'dock'
  if ImGui.SmallButton(ctx, ('%s###dock'):format(dockLabel)) then
    toggleDock()
  end

  ImGui.SetCursorScreenPos(ctx, x1, y2 - btn_height)
  switchModeButton()

  ImGui.SetCursorScreenPos(ctx, x2 - buttonSize('reset'), y1)
  ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0xff4242ff)
  if ImGui.SmallButton(ctx, 'reset') then reset() end
  ImGui.PopStyleColor(ctx)

  ImGui.SetCursorScreenPos(ctx, x2 - buttonSize('help'), y2 - btn_height)
  if ImGui.SmallButton(ctx, 'help') then about() end

  ImGui.PopFont(ctx)
  ImGui.PopStyleVar(ctx, 2)

  ImGui.SetCursorPosY(ctx, y_bak)
end

local function mainWindow()
  contextMenu()
  keyInput()

  local avail_y = select(2, ImGui.GetContentRegionAvail(ctx))
  local fullUI = avail_y > 50 and ImGui.GetScrollMaxY(ctx) <= avail_y

  filterPrompt = filterPrompt and ImGui.IsWindowFocused(ctx)
  -- cache to not call toolbar() on the frame when drawFilter() clears it
  local filterPrompt = filterPrompt

  ImGui.PushFont(ctx, fullUI and fonts.large or fonts.huge)
  if filterPrompt then
    drawFilter()
  else
    ImGui.SetNextItemAllowOverlap(ctx)
    drawName(songs[currentIndex])
    if not fullUI then
      navButtons()
    end
  end
  ImGui.PopFont(ctx)

  if fullUI then
    if not filterPrompt then
      toolbar()
    end
    ImGui.Spacing(ctx)
    songList()
  end
end

local function loop()
  execRemoteActions()
  execTakeMarkers()

  ImGui.PushFont(ctx, fonts.small)
  ImGui.SetNextWindowSize(ctx, 500, 300, setDock and ImGui.Cond_Always or ImGui.Cond_FirstUseEver)
  if setDock then
    ImGui.SetNextWindowDockID(ctx, setDock)
    setDock = nil
  end
  local visible, open = ImGui.Begin(ctx, SCRIPT_NAME, true, ImGui.WindowFlags_NoScrollbar)
  if visible then
    mainWindow()
    ImGui.End(ctx)
  end
  ImGui.PopFont(ctx)

  if open then
    reaper.defer(loop)
  end
end

signals.relative_move = function(move)
  move = tonumber(move)

  if move then
    trySetCurrentIndex(currentIndex + move)
  end
end

signals.absolute_move = function(index)
  trySetCurrentIndex(tonumber(index))
end

signals.activate_queued = function()
  if currentIndex ~= nextIndex then
    setCurrentIndex(nextIndex)
  end
end

signals.relative_queue = function(move)
  move = tonumber(move)

  if move then
    setNextIndex(nextIndex + move)
  end
end

signals.absolute_queue = function(index)
  setNextIndex(tonumber(index))
end

signals.filter = function(filter)
  local index = findSong(filter)

  if index then
    setCurrentIndex(index)
  end
end

signals.reset = reset

-- GO!!
reset()
reaper.defer(loop)

reaper.atexit(function()
  reaper.DeleteExtState(EXT_SECTION, EXT_STATE, false)
end)

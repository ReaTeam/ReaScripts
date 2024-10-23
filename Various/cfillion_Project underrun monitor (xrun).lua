-- @description Project underrun monitor (xrun)
-- @author cfillion
-- @version 2.1.1
-- @changelog Internal code cleanup
-- @link
--   cfillion.ca https://cfillion.ca
--   Request Thread https://forum.cockos.com/showthread.php?p=1942953
-- @screenshot https://i.imgur.com/DBHf0w0.gif
-- @donation https://reapack.com/donate
-- @about
--   # Project underrun monitor
--
--   This script keeps track of the project time where an audio or media buffer
--   underrun occured. Markers can optionally be created. The reported time and
--   marker position accuracy is limited by the polling speed of ReaScripts
--   which is around 30Hz.

local SCRIPT_NAME = select(2, reaper.get_action_context()):match('([^/\\_]+)%.lua$')

if not reaper.ImGui_GetBuiltinPath then
  reaper.MB('This script requires ReaImGui. \z
    Install it from ReaPack > Browse packages.', SCRIPT_NAME, 0)
  return
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'

local EXT_SECTION      = 'cfillion_underrun_monitor'
local EXT_MARKER_TYPE  = 'marker_type'
local EXT_MARKER_WHEN  = 'marker_when'

local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()

local AUDIO_XRUN = 1
local MEDIA_XRUN = 2

local KIND_MAP = {
  [AUDIO_XRUN] = {
    display_name = 'Audio',
    marker_name  = 'audio xrun',
    marker_color = ImGui.ColorConvertNative(0x1ff0000),
  },
  [MEDIA_XRUN] = {
    display_name = 'Media',
    marker_name  = 'media xrun',
    marker_color = ImGui.ColorConvertNative(0x1ffff00),
  }
}

local DEFAULT_SETTINGS = {
  [EXT_MARKER_TYPE] = AUDIO_XRUN|MEDIA_XRUN,
  [EXT_MARKER_WHEN] = 4,
}

local MARKER_TYPE_MENU = {
  {str = '(off)', val = 0 },
  {str = 'any',   val = AUDIO_XRUN|MEDIA_XRUN },
  {str = 'audio', val = AUDIO_XRUN },
  {str = 'media', val = MEDIA_XRUN },
}

local MARKER_WHEN_MENU = {
  { str = 'play or record', val = 1|4 },
  { str = 'playing',        val = 1   },
  { str = 'recording ',     val = 4   },
}
local EVENT_LOG_WAS_AT_BOTTOM    = 1
local EVENT_LOG_SCROLL_TO_BOTTOM = 2

local prev_audio, prev_media = reaper.GetUnderrunTime()
local last_project
local ctx, clipper
local event_log, event_log_flags, event_log_sel = {}, EVENT_LOG_WAS_AT_BOTTOM

local xruns = {
  [AUDIO_XRUN] = { count = 0, position = nil },
  [MEDIA_XRUN] = { count = 0, position = nil },
}

local ctx = ImGui.CreateContext(SCRIPT_NAME)

local font = ImGui.CreateFont('sans-serif',
  reaper.GetAppVersion():match('OSX') and 12 or 14)
ImGui.Attach(ctx, font)

local function position()
  if reaper.GetPlayState() & 1 == 0 then
    return reaper.GetCursorPosition()
  else
    return reaper.GetPlayPosition2()
  end
end

local function markerSettings()
  local playbackState = reaper.GetPlayState()
  local markerWhen = tonumber(reaper.GetExtState(EXT_SECTION, EXT_MARKER_WHEN))

  if playbackState & markerWhen ~= 0 then
    return tonumber(reaper.GetExtState(EXT_SECTION, EXT_MARKER_TYPE))
  else
    return 0
  end
end

local function addXrun(kind)
  local xrun = xruns[kind]
  xrun.count = xrun.count + 1
  xrun.position = position()

  local kind_info = KIND_MAP[kind]
  if markerSettings() & kind ~= 0 then
    reaper.AddProjectMarker2(nil, false, xrun.position, 0,
      kind_info.marker_name, -1, kind_info.marker_color)
  end

  event_log[#event_log + 1] = { kind=kind, position=xrun.position, time=os.time() }
  if event_log_flags & EVENT_LOG_WAS_AT_BOTTOM ~= 0 then
    event_log_flags = event_log_flags | EVENT_LOG_SCROLL_TO_BOTTOM
  end
end

local function probeUnderruns()
  local audio_xrun, media_xrun, curtime = reaper.GetUnderrunTime()

  if audio_xrun > 0 and audio_xrun ~= prev_audio then
    prev_audio = audio_xrun
    addXrun(AUDIO_XRUN)
  end

  if media_xrun > 0 and media_xrun ~= prev_media then
    prev_media = media_xrun
    addXrun(MEDIA_XRUN)
  end
end

local function eraseMarkers(kind)
  if not last_project or not reaper.ValidatePtr(last_project, 'ReaProject*') then return end

  local index  = 0

  -- integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber
  while true do
    local marker = {reaper.EnumProjectMarkers2(last_project, index)}
    if marker[1] < 1 then break end

    if not marker[2] and marker[5] == kind.marker_name then
      reaper.DeleteProjectMarkerByIndex(last_project, index)
    else
      index = index + 1
    end
  end
end

local function reset(xrunType)
  for kind, info in pairs(KIND_MAP) do
    if xrunType & kind ~= 0 then
      xruns[kind].position = nil
      eraseMarkers(info)
    end
  end
end

local function detectProjectChange()
  local current_project = reaper.EnumProjects(-1, '')

  if last_project ~= current_project then
    reset(AUDIO_XRUN | MEDIA_XRUN)
    last_project = current_project
  end
end

local function formatPosition(time)
  if time then
    return reaper.format_timestr(time, '')
  else
    return '(never)'
  end
end

local function combo(key, choices)
  local value = tonumber(reaper.GetExtState(EXT_SECTION, key))
  local label = ''

  for _, choice in ipairs(choices) do
    if value == choice.val then
      label = choice.str
      break
    end
  end

  if ImGui.BeginCombo(ctx, '##' .. key, label) then
    for _, choice in ipairs(choices) do
      if ImGui.Selectable(ctx, choice.str, value == choice.val) then
        reaper.SetExtState(EXT_SECTION, key, choice.val, true)
      end
    end
    ImGui.EndCombo(ctx)
  end
end

local function drawXrun(name, kind)
  local time = xruns[kind].position
  local disabledCursor = function()
    if not time and ImGui.IsItemHovered(ctx) then
      ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_NotAllowed)
    end
  end

  ImGui.PushID(ctx, kind)
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, ('Last %s xrun position:'):format(name))
  ImGui.SameLine(ctx, 179)
  ImGui.SetNextItemWidth(ctx, 115)
  ImGui.InputText(ctx, '##time', formatPosition(time), ImGui.InputTextFlags_ReadOnly)
  ImGui.SameLine(ctx)
  if not time then
    local frameBg = ImGui.GetStyleColor(ctx, ImGui.Col_FrameBg)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,        frameBg)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,  frameBg)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, frameBg)
  end
  if ImGui.Button(ctx, 'Jump') and time then reaper.SetEditCurPos(time, true, false) end
  disabledCursor()
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Reset') and time then reset(kind) end
  disabledCursor()
  if not time then
    ImGui.PopStyleColor(ctx, 3)
  end
  ImGui.PopID(ctx)
end

local function drawEventLog()
  local table_flags = ImGui.TableFlags_Borders |
                      ImGui.TableFlags_RowBg   |
                      ImGui.TableFlags_SizingStretchSame |
                      ImGui.TableFlags_ScrollY
  if not ImGui.BeginTable(ctx, 'Event log', 3, table_flags, 0, 100) then return end
  ImGui.TableSetupScrollFreeze(ctx, 0, 1)
  ImGui.TableSetupColumn(ctx, 'Time')
  ImGui.TableSetupColumn(ctx, 'Kind')
  ImGui.TableSetupColumn(ctx, 'Position')
  ImGui.TableHeadersRow(ctx)

  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 4, 4) -- selectable padding

  if not ImGui.ValidatePtr(clipper, 'ImGui_ListClipper*') then
    clipper = ImGui.CreateListClipper(ctx)
  end
  ImGui.ListClipper_Begin(clipper, #event_log)
  while ImGui.ListClipper_Step(clipper) do
    local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
    for i = display_start, display_end - 1 do
      ImGui.PushID(ctx, i)
      local entry = event_log[i + 1]
      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, os.date('%Y-%m-%d %H:%M:%S', entry.time))
      ImGui.TableNextColumn(ctx)
      local kinds = {}
      for flag, info in pairs(KIND_MAP) do
        if entry.kind & flag ~= 0 then kinds[#kinds + 1] = info.display_name end
      end
      if ImGui.Selectable(ctx, table.concat(kinds, ', '), event_log_sel == i,
          ImGui.SelectableFlags_SpanAllColumns) then
        event_log_sel = i
        reaper.SetEditCurPos(entry.position, true, false)
      end
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, formatPosition(entry.position))
      ImGui.PopID(ctx)
    end
  end

  if event_log_flags & EVENT_LOG_SCROLL_TO_BOTTOM ~= 0 then
    ImGui.SetScrollHereY(ctx)
    event_log_flags = event_log_flags & ~EVENT_LOG_SCROLL_TO_BOTTOM
  end
  if ImGui.GetScrollY(ctx) >= ImGui.GetScrollMaxY(ctx) then
    event_log_flags = event_log_flags | EVENT_LOG_WAS_AT_BOTTOM
  else
    event_log_flags = event_log_flags & ~EVENT_LOG_WAS_AT_BOTTOM
  end

  ImGui.PopStyleVar(ctx)
  ImGui.EndTable(ctx)
end

local function draw()
  drawXrun('audio', AUDIO_XRUN)
  drawXrun('media', MEDIA_XRUN)
  ImGui.Spacing(ctx)

  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'Create markers on')
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 80)
  combo(EXT_MARKER_TYPE, MARKER_TYPE_MENU)
  ImGui.SameLine(ctx)
  ImGui.Text(ctx, 'xruns, when')
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, -FLT_MIN)
  combo(EXT_MARKER_WHEN, MARKER_WHEN_MENU)

  if ImGui.CollapsingHeader(ctx, 'Event log') then
    drawEventLog()

    local no_events = #event_log < 1
    if no_events then
      ImGui.BeginDisabled(ctx)
    end
    if ImGui.Button(ctx, 'Clear') then
      event_log, event_log_flags, event_log_sel = {}, EVENT_LOG_WAS_AT_BOTTOM
      for k, v in pairs(xruns) do xruns[k].count = 0 end
    end
    ImGui.SameLine(ctx)
    if no_events then
      ImGui.Text(ctx, 'No audio or media xrun events recorded')
      ImGui.EndDisabled(ctx)
    else
      ImGui.Text(ctx, ('%d xrun events recorded (%d audio, %d media)')
        :format(#event_log, xruns[AUDIO_XRUN].count, xruns[MEDIA_XRUN].count))
    end
  end
end

local function about()
  local owner = reaper.ReaPack_GetOwner((select(2, reaper.get_action_context())))

  if not owner then
    reaper.MB((
      'This feature is unavailable because "%s" \z
       was not installed using ReaPack.'
    ):format(SCRIPT_NAME), SCRIPT_NAME, 0)
    return
  end

  reaper.ReaPack_AboutInstalledPackage(owner)
  reaper.ReaPack_FreeEntry(owner)
end

local function contextMenu()
  local dock_id = ImGui.GetWindowDockID(ctx)
  local popup_flags = ImGui.PopupFlags_MouseButtonRight |
                      ImGui.PopupFlags_NoOpenOverItems
  if not ImGui.BeginPopupContextWindow(ctx, nil, popup_flags) then return end
  if ImGui.BeginMenu(ctx, 'Dock window') then
    if ImGui.MenuItem(ctx, 'Floating', nil, dock_id == 0) then
      set_dock_id = 0
    end
    for i = 0, 15 do
      if ImGui.MenuItem(ctx, ('Docker %d'):format(i + 1), nil, dock_id == ~i) then
        set_dock_id = ~i
      end
    end
    ImGui.EndMenu(ctx)
  end
  ImGui.Separator(ctx)
  if ImGui.MenuItem(ctx, 'About/help', 'F1', false, reaper.ReaPack_GetOwner ~= nil) then
    about()
  end
  if ImGui.MenuItem(ctx, 'Close', 'Escape') then
    exit = true
  end
  ImGui.EndPopup(ctx)
end

function loop()
  detectProjectChange()
  probeUnderruns()

  ImGui.PushFont(ctx, font)
  ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg,  0xffffffff)
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, 0xffffffff)

  --ImGui.SetNextWindowSize(ctx, 412, 140)
  if set_dock_id then
    ImGui.SetNextWindowDockID(ctx, set_dock_id)
    set_dock_id = nil
  end
  local visible, open = ImGui.Begin(ctx, SCRIPT_NAME, true,
    ImGui.WindowFlags_AlwaysAutoResize)
  if visible then
    ImGui.PushStyleColor(ctx, ImGui.Col_Border,           0x2a2a2aff)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button,           0xdcdcdcff)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive,     0x787878ff)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered,    0xdcdcdcff)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg,          0xffffffff)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered,   0x96afe1ff)
    ImGui.PushStyleColor(ctx, ImGui.Col_Header,           0x96afe180)
    ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered,    0x96afe1ff)
    ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg,          0xffffffff)
    ImGui.PushStyleColor(ctx, ImGui.Col_ScrollbarBg,      0xacacacff)
    ImGui.PushStyleColor(ctx, ImGui.Col_TableBorderLight, 0x999999ff)
    ImGui.PushStyleColor(ctx, ImGui.Col_TableHeaderBg,    0xdcdcdcff)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text,             0x2a2a2aff)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameBorderSize, 1)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding,    7, 4)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing,     7, 7)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_ScrollbarSize,   12)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding,  10, 10)

    contextMenu()
    draw()

    ImGui.PopStyleVar(ctx, 5)
    ImGui.PopStyleColor(ctx, 13)
    ImGui.End(ctx)
  end

  ImGui.PopStyleColor(ctx, 2)
  ImGui.PopFont(ctx)

  if ImGui.IsKeyPressed(ctx, ImGui.Key_F1) then about() end
  if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) or exit then open = false end

  if open then
    reaper.defer(loop)
  end
end

for key, default in pairs(DEFAULT_SETTINGS) do
  if not reaper.HasExtState(EXT_SECTION, key) then
    reaper.SetExtState(EXT_SECTION, key, default, true)
  end
end

reaper.defer(loop)
reaper.atexit(function() reset(AUDIO_XRUN|MEDIA_XRUN) end)

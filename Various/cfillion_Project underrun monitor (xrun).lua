-- @description Project underrun monitor (xrun)
-- @author cfillion
-- @version 2.0.2
-- @changelog Enable ReaImGui's backward compatibility shims
-- @link
--   cfillion.ca https://cfillion.ca
--   Request Thread https://forum.cockos.com/showthread.php?p=1942953
-- @screenshot https://i.imgur.com/ECoEWks.gif
-- @donation https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Project+underrun+monitor+(xrun)
-- @about
--   # Project underrun monitor
--
--   This script keeps track of the project time where an audio or media buffer
--   underrun occured. Markers can optionally be created. The reported time and
--   marker position accuracy is limited by the polling speed of ReaScripts
--   which is around 30Hz.

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.7')

local r = reaper

local EXT_SECTION      = 'cfillion_underrun_monitor'
local EXT_MARKER_TYPE  = 'marker_type'
local EXT_MARKER_WHEN  = 'marker_when'

local FLT_MIN, FLT_MAX = r.ImGui_NumericLimits_Float()
local RO        = r.ImGui_InputTextFlags_ReadOnly()
local WND_FLAGS = r.ImGui_WindowFlags_NoScrollbar() |
                  r.ImGui_WindowFlags_NoScrollWithMouse() |
                  r.ImGui_WindowFlags_NoResize()

local KEY_ESCAPE = 0x1b
local KEY_F1     = 0x70

local AUDIO_XRUN = 1
local MEDIA_XRUN = 2

local AUDIO_MARKER = 'audio xrun'
local MEDIA_MARKER = 'media xrun'

local AUDIO_COLOR = r.ImGui_ColorConvertNative(0x1ff0000)
local MEDIA_COLOR = r.ImGui_ColorConvertNative(0x1ffff00)

local DEFAULT_SETTINGS = {
  [EXT_MARKER_TYPE]=AUDIO_XRUN|MEDIA_XRUN,
  [EXT_MARKER_WHEN]=4,
}

local MARKER_TYPE_MENU = {
  {str='(off)', val=0},
  {str='any',   val=AUDIO_XRUN|MEDIA_XRUN},
  {str='audio', val=AUDIO_XRUN},
  {str='media', val=MEDIA_XRUN},
}

local MARKER_WHEN_MENU = {
  {str='play or record', val=1|4},
  {str='playing',        val=1},
  {str='recording ',     val=4},
}

local scriptName = ({r.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
local prev_audio, prev_media = r.GetUnderrunTime()
local audio_time, media_time, last_project

function position()
  if r.GetPlayState() & 1 == 0 then
    return r.GetCursorPosition()
  else
    return r.GetPlayPosition2()
  end
end

function markerSettings()
  local playbackState = r.GetPlayState()
  local markerWhen = tonumber(r.GetExtState(EXT_SECTION, EXT_MARKER_WHEN))

  if playbackState & markerWhen ~= 0 then
    return tonumber(r.GetExtState(EXT_SECTION, EXT_MARKER_TYPE))
  else
    return 0
  end
end

function probeUnderruns()
  local markerType = markerSettings()
  local audio_xrun, media_xrun, curtime = r.GetUnderrunTime()

  if audio_xrun > 0 and audio_xrun ~= prev_audio then
    prev_audio = audio_xrun
    audio_time = position()

    if markerType & AUDIO_XRUN ~= 0 then
      r.AddProjectMarker2(0, 0, audio_time, 0, AUDIO_MARKER, -1, AUDIO_COLOR)
    end
  end

  if media_xrun > 0 and media_xrun ~= prev_media then
    prev_media = media_xrun
    media_time = position()

    if markerType & MEDIA_XRUN ~= 0 then
      r.AddProjectMarker2(0, 0, media_time, 0, MEDIA_MARKER, -1, MEDIA_COLOR)
    end
  end
end

function eraseMarkers(name)
  if not last_project or not r.ValidatePtr(last_project, 'ReaProject*') then return end

  local index  = 0

  -- integer retval, boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber
  while true do
    local marker = {r.EnumProjectMarkers2(last_project, index)}
    if marker[1] < 1 then break end

    if not marker[2] and marker[5] == name then
      r.DeleteProjectMarkerByIndex(last_project, index)
    else
      index = index + 1
    end
  end
end

function reset(xrunType)
  if xrunType & AUDIO_XRUN ~= 0 then
    audio_time = nil
    eraseMarkers(AUDIO_MARKER)
  end

  if xrunType & MEDIA_XRUN ~= 1 then
    media_time = nil
    eraseMarkers(MEDIA_MARKER)
  end
end

function detectProjectChange()
  local current_project = r.EnumProjects(-1, '')

  if last_project ~= current_project then
    reset(AUDIO_XRUN | MEDIA_XRUN)
    last_project = current_project
  end
end

function formatTime(time)
  if time then
    return r.format_timestr(time, '')
  else
    return '(never)'
  end
end

function combo(key, choices)
  local value = tonumber(r.GetExtState(EXT_SECTION, key))
  local label = ''

  for _, choice in ipairs(choices) do
    if value == choice.val then
      label = choice.str
      break
    end
  end

  if r.ImGui_BeginCombo(ctx, '##' .. key, label) then
    for _, choice in ipairs(choices) do
      if r.ImGui_Selectable(ctx, choice.str, value == choice.val) then
        r.SetExtState(EXT_SECTION, key, choice.val, true)
      end
    end
    r.ImGui_EndCombo(ctx)
  end
end

function drawXrun(name, flag, time)
  local disabledCursor = function()
    if not time and r.ImGui_IsItemHovered(ctx) then
      r.ImGui_SetMouseCursor(ctx, r.ImGui_MouseCursor_NotAllowed())
    end
  end

  r.ImGui_PushID(ctx, flag)
  r.ImGui_AlignTextToFramePadding(ctx)
  r.ImGui_Text(ctx, ('Last %s xrun position:'):format(name))
  r.ImGui_SameLine(ctx, 179)
  r.ImGui_SetNextItemWidth(ctx, 115)
  r.ImGui_InputText(ctx, '##time', formatTime(time), RO)
  r.ImGui_SameLine(ctx)
  if not time then
    local frameBg = r.ImGui_GetStyleColor(ctx, r.ImGui_Col_FrameBg())
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),        frameBg)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),  frameBg)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(),  frameBg)
  end
  if r.ImGui_Button(ctx, 'Jump') and time then r.SetEditCurPos(time, true, false) end
  disabledCursor()
  r.ImGui_SameLine(ctx)
  if r.ImGui_Button(ctx, 'Reset') and time then reset(flag) end
  disabledCursor()
  if not time then
    r.ImGui_PopStyleColor(ctx, 3)
  end
  r.ImGui_PopID(ctx)
end

function draw()
  drawXrun('audio', AUDIO_XRUN, audio_time)
  drawXrun('media', MEDIA_XRUN, media_time)
  r.ImGui_Spacing(ctx)

  r.ImGui_AlignTextToFramePadding(ctx)
  r.ImGui_Text(ctx, 'Create markers on')
  r.ImGui_SameLine(ctx)
  r.ImGui_SetNextItemWidth(ctx, 80)
  combo(EXT_MARKER_TYPE, MARKER_TYPE_MENU)
  r.ImGui_SameLine(ctx)
  r.ImGui_Text(ctx, 'xruns, when')
  r.ImGui_SameLine(ctx)
  r.ImGui_SetNextItemWidth(ctx, -FLT_MIN)
  combo(EXT_MARKER_WHEN, MARKER_WHEN_MENU)
end

function contextMenu()
  local dock_id = r.ImGui_GetWindowDockID(ctx)
  if not reaper.ImGui_BeginPopupContextWindow(ctx) then return end
  if r.ImGui_BeginMenu(ctx, 'Dock window') then
    if r.ImGui_MenuItem(ctx, 'Floating', nil, dock_id == 0) then
      set_dock_id = 0
    end
    for i = 0, 15 do
      if r.ImGui_MenuItem(ctx, ('Docker %d'):format(i + 1), nil, dock_id == ~i) then
        set_dock_id = ~i
      end
    end
    r.ImGui_EndMenu(ctx)
  end
  r.ImGui_Separator(ctx)
  if r.ImGui_MenuItem(ctx, 'About/help', 'F1', false, r.ReaPack_GetOwner ~= nil) then
    about()
  end
  if r.ImGui_MenuItem(ctx, 'Close', 'Escape') then
    exit = true
  end
  r.ImGui_EndPopup(ctx)
end

function about()
  local owner = r.ReaPack_GetOwner(({r.get_action_context()})[2])

  if not owner then
    r.MB(string.format(
      'This feature is unavailable because "%s" was not installed using ReaPack.',
      scriptName), scriptName, 0)
    return
  end

  r.ReaPack_AboutInstalledPackage(owner)
  r.ReaPack_FreeEntry(owner)
end

function loop()
  detectProjectChange()
  probeUnderruns()

  r.ImGui_PushFont(ctx, font)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ChildBg(),       0xffffffff)
  r.ImGui_PushStyleColor(ctx, r.ImGui_Col_WindowBg(),       0xffffffff)

  r.ImGui_SetNextWindowSize(ctx, 412, 120)
  if set_dock_id then
    r.ImGui_SetNextWindowDockID(ctx, set_dock_id)
    set_dock_id = nil
  end
  local visible, open = r.ImGui_Begin(ctx, scriptName, true, WND_FLAGS)
  if visible then
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Border(),         0x2a2a2aff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Button(),         0xdcdcdcff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonActive(),   0x787878ff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_ButtonHovered(),  0xdcdcdcff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBg(),        0xffffffff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_FrameBgHovered(), 0x96afe1ff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Header(),         0x96afe180)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_HeaderHovered(),  0x96afe1ff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_PopupBg(),        0xffffffff)
    r.ImGui_PushStyleColor(ctx, r.ImGui_Col_Text(),           0x2a2a2aff)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FrameBorderSize(),  1)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_FramePadding(),     7, 4)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_ItemSpacing(),      7, 7)
    r.ImGui_PushStyleVar(ctx, r.ImGui_StyleVar_WindowPadding(),   10, 10)

    contextMenu()
    draw()

    r.ImGui_PopStyleVar(ctx, 4)
    r.ImGui_PopStyleColor(ctx, 10)
    r.ImGui_End(ctx)
  end

  r.ImGui_PopStyleColor(ctx, 2)
  r.ImGui_PopFont(ctx)

  if r.ImGui_IsKeyPressed(ctx, KEY_F1) then about() end
  if r.ImGui_IsKeyPressed(ctx, KEY_ESCAPE) or exit then open = false end

  if open then
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

for key, default in pairs(DEFAULT_SETTINGS) do
  if not r.HasExtState(EXT_SECTION, key) then
    r.SetExtState(EXT_SECTION, key, default, true)
  end
end

r.atexit(function()
  reset(AUDIO_XRUN|MEDIA_XRUN)
end)

if not r.ImGui_CreateContext then
  r.MB('This script requires ReaImGui. Install it from ReaPack > Browse packages.', scriptName, 0)
  return
end

ctx = r.ImGui_CreateContext(scriptName, r.ImGui_ConfigFlags_DockingEnable())

local size = r.GetAppVersion():match('OSX') and 12 or 14
font = r.ImGui_CreateFont('sans-serif', size)
r.ImGui_AttachFont(ctx, font)

r.defer(loop)

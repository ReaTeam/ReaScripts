-- @description Toggle track FX bypass by name
-- @author cfillion
-- @version 2.0
-- @changelog
--   Add an option to include input and monitoring effects [cfillion/reascripts#6]
--   Fix truncated labels by replacing the GetUserInputs prompt with a ReaImGui interface
-- @provides
--   .
--   [main] . > cfillion_Toggle track FX bypass by name (create action).lua
-- @link http://forum.cockos.com/showthread.php?t=184623
-- @screenshot
--   Basic Usage https://i.imgur.com/jVgwbi3.gif
--   Undo Points https://i.imgur.com/dtNwlsn.png
-- @about
--   # Toggle track FX bypass by name
--
--   This script asks for a string to match against all track FX in the current
--   project, matching tracks or selected tracks. The search is case insensitive.
--   Bypass is toggled for all matching FXs. Undo points are consolidated into one.
--
--   This script can also be used to create custom actions that bypass matching
--   track effects without always requesting user input.

local script_path = select(2, reaper.get_action_context())
local script_name = script_path:match("([^/\\_]+)%.lua$")

if not reaper.GetTrackName then
  -- for REAPER prior to v5.30 (native GetTrackName returns "Track N" when it's empty)
  function reaper.GetTrackName(track, _)
    return reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
  end
end

local function matchTrack(track, filter)
  if filter == '/selected' then
    return reaper.IsTrackSelected(track)
  elseif filter == '/master' then
    return reaper.GetMasterTrack(nil) == track
  else
    local _, name = reaper.GetTrackName(track, '')
    return name:lower():find(filter)
  end
end

local function sanitizeFilename(name)
  -- replace special characters that are reserved on Windows
  return name:gsub("[*\\:<>?/|\"%c]+", '-')
end

local function createAction()
  local fx_filter_fn = sanitizeFilename(fx_filter)
  local action_name = ('Toggle track FX bypass by name - %s'):format(fx_filter_fn)
  local output_fn = ('%s/Scripts/%s.lua'):format(
    reaper.GetResourcePath(), action_name)
  local base_name = script_path:match('([^/\\]+)$')
  local rel_path = script_path:sub(reaper.GetResourcePath():len() + 2)

  local code = ([[
-- This file was created by %s on %s

fx_filter, track_filter, search_record = %q, %q, %q
dofile((%q):format(reaper.GetResourcePath()))
]]):format(base_name, os.date('%c'), fx_filter, track_filter, search_record,
  '%s/'..rel_path)

  local file = assert(io.open(output_fn, 'w'))
  file:write(code)
  file:close()

  if reaper.AddRemoveReaScript(true, 0, output_fn, true) == 0 then
    reaper.ShowMessageBox(
      'Failed to create or register the new action.', script_name, 0)
    return
  end

  reaper.ShowMessageBox(
    ('Created the action "%s".'):format(action_name), script_name, 0)
end

local function matchToggleFX(track, fi, fx_filter)
  local fx_name = select(2, reaper.TrackFX_GetFXName(track, fi, ''))
  if fx_name:lower():find(fx_filter) then
    reaper.TrackFX_SetEnabled(track, fi,
    not reaper.TrackFX_GetEnabled(track, fi))
  end
end

local function run()
  local fx_filter, track_filter = fx_filter:lower(), track_filter:lower()

  reaper.PreventUIRefresh(1)
  reaper.Undo_BeginBlock()

  for ti = 0, reaper.CountTracks() do
    local track = reaper.CSurf_TrackFromID(ti, false)

    if matchTrack(track, track_filter) then
      for fi = 0, reaper.TrackFX_GetCount(track) - 1 do
        matchToggleFX(track, fi, fx_filter)
      end
      if search_record then
        for fi = 0, reaper.TrackFX_GetRecCount(track) - 1 do
          matchToggleFX(track, 0x1000000 + fi, fx_filter)
        end
      end
    end
  end

  reaper.Undo_EndBlock(
    ("Toggle track FX bypass matching '%s'"):format(fx_filter), -1)
  reaper.PreventUIRefresh(-1)
end

if fx_filter and track_filter then return run() end -- user action

fx_filter, track_filter = '', ''
local mode = (function()
  if reaper.CountSelectedTracks() > 0 then
    return 1
  elseif reaper.IsTrackSelected(reaper.GetMasterTrack(nil)) then
    return 2
  else
    return 0
  end
end)()
search_record = false

if reaper.CountSelectedTracks() == 1 then
  local sel_track = reaper.GetSelectedTrack(nil, 0)
  track_filter = select(2,
    reaper.GetSetMediaTrackInfo_String(sel_track, 'P_NAME', '', false))
end

local is_create_action =
  script_name == 'Toggle track FX bypass by name (create action)'

if not reaper.ImGui_GetBuiltinPath then
  reaper.MB('This script requires ReaImGui. \z
    Install it from ReaPack > Browse packages.', script_name, 0)
  return
end

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'
local ctx = ImGui.CreateContext('Toggle track FX bypass by name')
local font = ImGui.CreateFont('sans-serif',
  reaper.GetAppVersion():match('OSX') and 12 or 14)
ImGui.Attach(ctx, font)

local function helpTooltip(ctx, desc)
  ImGui.TextDisabled(ctx, '(?)')
  ImGui.SetItemTooltip(ctx, desc)
end

local function loop()
  ImGui.PushFont(ctx, font)
  local visible, open = ImGui.Begin(ctx, script_name .. '###window', true,
    ImGui.WindowFlags_AlwaysAutoResize)
  if visible then
    ImGui.Text(ctx, 'Toggle bypass of effects matching:')
    if ImGui.IsWindowAppearing(ctx) then ImGui.SetKeyboardFocusHere(ctx) end
    fx_filter = select(2, ImGui.InputText(ctx, 'FX name', fx_filter))
    ImGui.SameLine(ctx)
    helpTooltip(ctx, 'Search is case-insensitive.')

    ImGui.Spacing(ctx)

    ImGui.Text(ctx, '...on tracks:')
    if ImGui.RadioButton(ctx, 'Selected tracks', mode == 1) then
      mode = 1
    end
    if ImGui.RadioButton(ctx, 'Master track', mode == 2) then
      mode = 2
    end
    if ImGui.RadioButton(ctx, 'Track name matching:', mode == 0) then
      mode = 0
      ImGui.SetKeyboardFocusHere(ctx)
    end
    ImGui.BeginDisabled(ctx, mode ~= 0)
    track_filter = select(2, ImGui.InputText(ctx, 'Track name', track_filter))
    ImGui.EndDisabled(ctx)
    ImGui.SameLine(ctx)
    helpTooltip(ctx, 'Search is case-insensitive. Leave empty to search all tracks.')

    ImGui.Spacing(ctx)

    search_record = select(2, ImGui.Checkbox(ctx,
      'Include input and monitoring effects', search_record))

    ImGui.Spacing(ctx)

    local btn_spacing = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
    local btn_w = (ImGui.GetContentRegionAvail(ctx) - btn_spacing) // 2
    if ImGui.Button(ctx, is_create_action and 'Create action' or 'OK', btn_w) or
        ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or
        ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter) then
      if mode == 1 then
        track_filter = '/selected'
      elseif mode == 2 then
        track_filter = '/master'
      end
      (is_create_action and createAction or run)()
      open = false
    end
    ImGui.SameLine(ctx)
    if ImGui.Button(ctx, 'Cancel', btn_w) or
        ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
      open = false
    end
    ImGui.End(ctx)
  end
  if open then
    reaper.defer(loop)
  end
  ImGui.PopFont(ctx)
end

reaper.defer(loop)

-- @description Select track FX by name
-- @author cfillion
-- @version 1.0
-- @provides
--   .
--   [main] . > cfillion_Select track FX by name (create action).lua
-- @donation Donate via PayPal https://paypal.me/cfillion
-- @about
--   # Select track FX by name
--
--   This script asks for a string to match against all track FX in the current
--   project, matching tracks or selected tracks. The search is case insensitive.
--   The first matching effect in each track is selected in the FX chain.
--
--   This script can also be used to create custom actions that select matching
--   track effects without always requesting user input.

if not reaper.GetTrackName then
  -- for REAPER prior to v5.30 (native GetTrackName returns "Track N" when it's empty)
  function reaper.GetTrackName(track, _)
    return reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
  end
end

if not reaper.CF_SelectTrackFX then
  -- for SWS prior to v2.12
  function reaper.CF_SelectTrackFX(track, fx_index)
    if reaper.TrackFX_GetChainVisible(track) ~= -1 then -- the FX chain is open
      reaper.TrackFX_Show(track, fx_index, 1);
      return
    end

    local _, chunk = reaper.GetTrackStateChunk(track, '', false)
    local new_chunk = chunk:gsub('\nLASTSEL %d+\n',
      string.format('\nLASTSEL %d\n', fx_index), 1)

    if chunk ~= new_chunk then
      reaper.SetTrackStateChunk(track, new_chunk, false)
    end
  end
end

local function matchTrack(track, filter)
  if filter == '/selected' then
    return reaper.IsTrackSelected(track)
  else
    local _, name = reaper.GetTrackName(track, '')
    return name:lower():find(filter)
  end
end

local function prompt()
  local default_track_filter = ''
  if reaper.CountSelectedTracks() > 0 then
    default_track_filter = '/selected'
  end

  local ok, csv = reaper.GetUserInputs(script_name, 2,
    "Select track FX matching:,On tracks (name or /selected):,extrawidth=100",
    ',' .. default_track_filter)
  if not ok or csv:len() <= 1 then return end

  local fx_filter, track_filter = csv:match("^(.*),(.*)$")
  return fx_filter:lower(), track_filter:lower()
end

local function sanitizeFilename(name)
  -- replace special characters that are reserved on Windows
  return name:gsub("[*\\:<>?/|\"%c]+", '-')
end

local function createAction()
  local fx_filter_fn = sanitizeFilename(fx_filter)
  local action_name = string.format('Select track FX by name - %s', fx_filter_fn)
  local output_fn = string.format('%s/Scripts/%s.lua',
    reaper.GetResourcePath(), action_name)
  local base_name = script_path:match('([^/\\]+)$')
  local rel_path = script_path:sub(reaper.GetResourcePath():len() + 2)

  local code = string.format([[
-- This file was created by %s on %s

fx_filter = %q
track_filter = %q
dofile(string.format(%q, reaper.GetResourcePath()))
]], base_name, os.date('%c'), fx_filter, track_filter, '%s/'..rel_path)

  local file = assert(io.open(output_fn, 'w'))
  file:write(code)
  file:close()

  if reaper.AddRemoveReaScript(true, 0, output_fn, true) == 0 then
    reaper.ShowMessageBox(
      'Failed to create or register the new action.', script_name, 0)
    return
  end

  reaper.ShowMessageBox(
    string.format('Created the action "%s".', action_name), script_name, 0)
end

script_path = ({reaper.get_action_context()})[2]
script_name = script_path:match("([^/\\_]+)%.lua$")

if not fx_filter or not track_filter then
  fx_filter, track_filter = prompt()

  if not fx_filter then
    reaper.defer(function() end) -- no undo point if nothing to do
    return
  end
end

if script_name == 'Select track FX by name (create action)' then
  createAction()
  return
end

reaper.Undo_BeginBlock()

for ti=0,reaper.CountTracks()-1 do
  local track = reaper.GetTrack(0, ti)

  if matchTrack(track, track_filter) then
    local do_select

    for fi=0,reaper.TrackFX_GetCount(track)-1 do
      local _, fx_name = reaper.TrackFX_GetFXName(track, fi, '')
      if fx_name:lower():find(fx_filter) then
        do_select = fi
        break
      end
    end

    if do_select then
      reaper.CF_SelectTrackFX(track, do_select)
    end
  end
end

reaper.Undo_EndBlock(
  string.format("Select track FX matching '%s'", fx_filter), -1)

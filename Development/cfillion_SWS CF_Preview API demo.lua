-- @description SWS CF_Preview API demo
-- @author cfillion
-- @version 1.0.3
-- @changelog Repair "through track" playback mode
-- @donation https://reapack.com/donate

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'

local SCRIPT_NAME = 'SWS CF_Preview API demo'
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local ctx = ImGui.CreateContext(SCRIPT_NAME)
local sans_serif = ImGui.CreateFont('sans-serif', 13)
ImGui.Attach(ctx, sans_serif)

local preview
local file = reaper.GetExtState('sws_test', 'preview_file')
local volume, pan, fadein_len, fadeout_len, loop, reverse = 1, 0, 0, 0, false, false
local output_chan, output_proj, output_track, out_to_track = 0, nil, nil, false
local play_rate, pitch, preserve_pitch, measure_align, seek_pos = 1, 0, true, 0, nil
local ps_mode, ps_modes, ps_sub_mode, ps_sub_modes = 1, {{v=-1, n='Project default'}}, 1
local peak_chans = 2

local function updatePitchShiftSubmodes()
  ps_sub_modes = {}
  for i = 0, math.huge do
    local mode = reaper.EnumPitchShiftSubModes(ps_modes[ps_mode].v, i)
    if not mode then break end
    ps_sub_modes[#ps_sub_modes + 1] = mode
  end
end

for i = 0, math.huge do
  local rv, mode = reaper.EnumPitchShiftModes(i)
  if not rv then break end
  if mode then ps_modes[#ps_modes + 1] = {v=i, n=mode} end
end
updatePitchShiftSubmodes()

local function VAL2DB(x)
  if x < 0.0000000298023223876953125 then
    return -150
  else
    return math.max(-150, math.log(x) * 8.6858896380650365530225783783321)
  end
end

local function formatChan(chan)
  local n = chan & 1023
  if (chan & 1024) == 0 then
   return ('Channel %d/%d'):format(n + 1, n + 2)
  else
    return ('Channel %d'):format(n + 1)
  end
end

local function pitchMode()
  if ps_modes[ps_mode].v == -1 then
    return -1
  else
    return (ps_modes[ps_mode].v << 16) | (ps_sub_mode - 1)
  end
end

local function outputSelect()
  local rv = false
  if ImGui.RadioButton(ctx, 'Hardware output', not out_to_track) then
    out_to_track = false
    rv = true
  end
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 110)
  if ImGui.BeginCombo(ctx, '##chan', formatChan(output_chan)) then
    local mono_changed
    mono_changed, output_chan = ImGui.CheckboxFlags(ctx, 'Mono', output_chan, 1024)
    if mono_changed then rv = true end
    ImGui.Spacing(ctx)
    local chan = output_chan & 1023
    local mono_flag = (output_chan & 1024)
    local skip = mono_flag == 0 and 2 or 1
    for i = 0, reaper.GetNumAudioOutputs() - 1, skip do
      if ImGui.Selectable(ctx, formatChan(i | mono_flag), chan == i) then
        output_chan = i | mono_flag
        out_to_track = false
        rv = true
      end
    end
    ImGui.EndCombo(ctx)
  end

  local num_tracks = reaper.GetNumTracks()
  if not reaper.ValidatePtr(output_proj, 'ReaProject*') or
     not reaper.ValidatePtr2(output_proj, output_track, 'MediaTrack*') then
    out_to_track = false
    output_track = reaper.GetTrack(nil, 0)
    output_proj = reaper.EnumProjects(-1)
    rv = true
  end
  ImGui.BeginDisabled(ctx, not output_track and num_tracks == 0)
  ImGui.SameLine(ctx)
  if ImGui.RadioButton(ctx, 'Through track', out_to_track) then
    out_to_track = true
    rv = true
  end
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, -FLT_MIN)
  local trackName = '<no track>'
  if output_track then trackName = select(2, reaper.GetTrackName(output_track)) end
  if ImGui.BeginCombo(ctx, '##track', trackName) then
    for i = 0, num_tracks - 1 do
      local track = reaper.GetTrack(nil, i)
      trackName = select(2, reaper.GetTrackName(track))
      if ImGui.Selectable(ctx, trackName, track == output_track) then
        output_track = track
        output_proj = reaper.EnumProjects(-1)
        out_to_track = true
        rv = true
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.EndDisabled(ctx)

  return rv
end

local function pitchShiftSelect()
  local rv = false

  ImGui.SetNextItemWidth(ctx, 200)
  if ImGui.BeginCombo(ctx, 'Pitch shift mode', ps_modes[ps_mode].n) then
    for i, mode in ipairs(ps_modes) do
      if ImGui.Selectable(ctx, mode.n, ps_mode == i) then
        ps_mode = i
        ps_sub_mode = 1
        updatePitchShiftSubmodes()
        rv = true
      end
    end
    ImGui.EndCombo(ctx)
  end

  ImGui.SameLine(ctx)
  ImGui.BeginDisabled(ctx, #ps_sub_modes == 0)
  ImGui.SetNextItemWidth(ctx, -62)
  if ImGui.BeginCombo(ctx, 'Submode', ps_sub_modes[ps_sub_mode] or '') then
    for i, submode in ipairs(ps_sub_modes) do
      if ImGui.Selectable(ctx, submode, ps_sub_mode == i) then
        ps_sub_mode = i
        rv = true
      end
    end
    ImGui.EndCombo(ctx)
  end
  ImGui.EndDisabled(ctx)

  return rv
end

local function start()
  local source = reaper.PCM_Source_CreateFromFile(file)
  if not source then return end

  if reverse then
    local section = reaper.PCM_Source_CreateFromType('SECTION')
    reaper.CF_PCM_Source_SetSectionInfo(section, source, 0, 0, true)
    reaper.PCM_Source_Destroy(source)
    source = section
  end

  if preview then reaper.CF_Preview_Stop(preview) end
  preview = reaper.CF_CreatePreview(source)
  if out_to_track then
    reaper.CF_Preview_SetOutputTrack(preview, output_proj, output_track)
  else
    reaper.CF_Preview_SetValue(preview, 'I_OUTCHAN', output_chan)
  end
  -- reaper.CF_Preview_SetValue(preview, 'D_POSITION', position)
  reaper.CF_Preview_SetValue(preview, 'B_LOOP', loop and 1 or 0)
  reaper.CF_Preview_SetValue(preview, 'D_VOLUME', volume)
  reaper.CF_Preview_SetValue(preview, 'D_PAN', pan)
  reaper.CF_Preview_SetValue(preview, 'D_MEASUREALIGN', measure_align)
  reaper.CF_Preview_SetValue(preview, 'D_PLAYRATE', play_rate)
  reaper.CF_Preview_SetValue(preview, 'D_PITCH', pitch)
  reaper.CF_Preview_SetValue(preview, 'B_PPITCH', preserve_pitch and 1 or 0)
  reaper.CF_Preview_SetValue(preview, 'I_PITCHMODE', pitchMode())
  reaper.CF_Preview_SetValue(preview, 'D_FADEINLEN', fadein_len)
  reaper.CF_Preview_SetValue(preview, 'D_fadeout_len', fadeout_len)
  reaper.CF_Preview_Play(preview)
  reaper.PCM_Source_Destroy(source)
end

local function window()
  local rv
  local active, position = reaper.CF_Preview_GetValue(preview, 'D_POSITION')
  local length = select(2, reaper.CF_Preview_GetValue(preview, 'D_LENGTH'))

  ImGui.PushItemWidth(ctx, -72)
  ImGui.AlignTextToFramePadding(ctx)
  ImGui.Text(ctx, 'File:')
  ImGui.SameLine(ctx)
  rv, file = ImGui.InputText(ctx, '##path', file)
  ImGui.SameLine(ctx)
  if ImGui.Button(ctx, 'Browse...') then
    local rv, new_file = reaper.JS_Dialog_BrowseForOpenFiles('Select audio file', '', file, '', false)
    if rv and new_file:len() > 0 then
      file = new_file
      reaper.SetExtState('sws_test', 'preview_file', file, false)
    end
  end

  local time, want_pos = ('%s / %s'):format(
    reaper.format_timestr(position, ''), reaper.format_timestr(length, ''))
  rv, want_pos = ImGui.SliderDouble(ctx, '##position', seek_pos or position, 0, length, time)
  if ImGui.IsItemDeactivatedAfterEdit(ctx) then
    reaper.CF_Preview_SetValue(preview, 'D_POSITION', seek_pos)
    seek_pos = nil
  elseif rv then
    seek_pos = want_pos
  end
  ImGui.SameLine(ctx)
  rv, loop = ImGui.Checkbox(ctx, 'Loop', loop)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'B_LOOP', loop and 1 or 0) end

  if outputSelect() then
    if out_to_track then
      reaper.CF_Preview_SetOutputTrack(preview, output_proj, output_track)
    else
      reaper.CF_Preview_SetValue(preview, 'I_OUTCHAN', output_chan)
    end
  end

  ImGui.SetNextItemWidth(ctx, -340)
  rv, volume = ImGui.SliderDouble(ctx, 'Volume', volume, 0, 2,
    ('%.2fdB'):format(VAL2DB(volume)), ImGui.SliderFlags_Logarithmic)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_VOLUME', volume) end
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 55)
  rv, pan = ImGui.SliderDouble(ctx, 'Pan', pan, -1, 1)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_PAN', pan) end
  ImGui.SameLine(ctx)
  local avail_w = ImGui.PushItemWidth(ctx, 40)
  rv, fadein_len = ImGui.InputDouble(ctx, 'Fade in', fadein_len)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_FADEINLEN', fadein_len) end
  ImGui.SameLine(ctx)
  rv, fadeout_len = ImGui.InputDouble(ctx, 'Fade out', fadeout_len)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_fadeout_len', fadeout_len) end
  ImGui.PopItemWidth(ctx)

  ImGui.PushItemWidth(ctx, 50)
  rv, play_rate = ImGui.InputDouble(ctx, 'Playback rate', play_rate)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_PLAYRATE', play_rate) end
  ImGui.SameLine(ctx)
  rv, pitch = ImGui.InputDouble(ctx, 'Pitch adjust (semitones)', pitch)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_PITCH', pitch) end
  ImGui.PopItemWidth(ctx)
  ImGui.SameLine(ctx)
  rv, preserve_pitch = ImGui.Checkbox(ctx, 'Preserve pitch when changing rate', preserve_pitch)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'B_PPITCH', preserve_pitch and 1 or 0) end

  rv = pitchShiftSelect()
  if rv and active then
    reaper.CF_Preview_SetValue(preview, 'I_PITCHMODE', pitchMode())
  end

  ImGui.Spacing(ctx)
  if ImGui.Button(ctx, 'Start preview') then start() end
  ImGui.SameLine(ctx)
  ImGui.BeginDisabled(ctx, not active)
  if ImGui.Button(ctx, 'Stop') then
    reaper.CF_Preview_Stop(preview)
    preview = nil
  end
  ImGui.EndDisabled(ctx)
  ImGui.SameLine(ctx, nil, 20)
  ImGui.SetNextItemWidth(ctx, 72)
  rv, measure_align = ImGui.InputInt(ctx, 'Align to measure', measure_align)
  if rv and measure_align < 0 then measure_align = 0 end
  ImGui.SameLine(ctx, nil, 20)
  rv, reverse = ImGui.Checkbox(ctx, 'Reverse', reverse)
  ImGui.SameLine(ctx, nil, 20)
  ImGui.SetNextItemWidth(ctx, -62)
  rv, peak_chans = ImGui.InputInt(ctx, 'Peaks', peak_chans, 1, 1)
  if rv then peak_chans = math.max(2, math.min(128, peak_chans)) end

  ImGui.Spacing(ctx)
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local spacing_x, spacing_h = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing)
  local meter_h = math.max(spacing_h, ((avail_h + spacing_h) / peak_chans) - spacing_h)
  for i = 0, peak_chans - 1 do
    local valid, peak = reaper.CF_Preview_GetPeak(preview, i)
    ImGui.BeginDisabled(ctx, not valid)
    ImGui.ProgressBar(ctx, peak, -FLT_MIN, meter_h, ' ')
    ImGui.EndDisabled(ctx)
  end

  ImGui.PopItemWidth(ctx)
end

local function loop()
  ImGui.PushFont(ctx, sans_serif)
  ImGui.SetNextWindowSizeConstraints(ctx, 590, 240, FLT_MAX, FLT_MAX)
  local visible, open = ImGui.Begin(ctx, SCRIPT_NAME, true)
  if visible then
    window()
    ImGui.End(ctx)
  end
  ImGui.PopFont(ctx)

  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

reaper.atexit(function()
  -- EnumProjects(0) to check whether SWS is still loaded
  if preview and reaper.EnumProjects(0) then
    reaper.CF_Preview_Stop(preview)
  end
end)

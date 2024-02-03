-- @description SWS CF_Preview API demo
-- @author cfillion
-- @version 1.0.1
-- @changelog Fix display of the first peak channel
-- @donation https://reapack.com/donate

dofile(reaper.GetResourcePath() .. '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.8.5')

local ImGui = {}
for name, func in pairs(reaper) do
  name = name:match('^ImGui_(.+)$')
  if name then ImGui[name] = func end
end

local SCRIPT_NAME = 'SWS CF_Preview API demo'
local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local ctx = ImGui.CreateContext(SCRIPT_NAME)
local sans_serif = ImGui.CreateFont('sans-serif', 13)
ImGui.Attach(ctx, sans_serif)

local preview
local file = reaper.GetExtState('sws_test', 'preview_file')
local volume, pan, fadeInLen, fadeOutLen, loop, reverse = 1, 0, 0, 0, false, false
local outputChan, outputProj, outputTrack, outToTrack = 0, nil, nil, false
local playRate, pitch, preservePitch, measureAlign, seekPos = 1, 0, true, 0, 0
local psMode, psModes, psSubMode, psSubModes = 1, {{v=-1, n='Project default'}}, 1
local peakChans = 2

local function updatePitchShiftSubmodes()
  psSubModes = {}
  local i = 0
  while true do
    local mode = reaper.EnumPitchShiftSubModes(psModes[psMode].v, i)
    if not mode then break end
    psSubModes[#psSubModes + 1] = mode
    i = i + 1
  end
end

local i = 0
while true do
  local rv, mode = reaper.EnumPitchShiftModes(i)
  if not rv then break end
  if mode then psModes[#psModes + 1] = {v=i, n=mode} end
  i = i + 1
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
  if psModes[psMode].v == -1 then
    return -1
  else
    return (psModes[psMode].v << 16) | (psSubMode - 1)
  end
end

local function outputSelect()
  local rv = false
  if ImGui.RadioButton(ctx, 'Hardware output', not outToTrack) then
    outToTrack = false
    rv = true
  end
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 110)
  if ImGui.BeginCombo(ctx, '##chan', formatChan(outputChan)) then
    local monoChanged
    monoChanged, outputChan = ImGui.CheckboxFlags(ctx, 'Mono', outputChan, 1024)
    if monoChanged then rv = true end
    ImGui.Spacing(ctx)
    local chan = outputChan & 1023
    local monoFlag = (outputChan & 1024)
    local skip = monoFlag == 0 and 2 or 1
    for i = 0, reaper.GetNumAudioOutputs() - 1, skip do
      if ImGui.Selectable(ctx, formatChan(i | monoFlag), chan == i) then
        outputChan = i | monoFlag
        outToTrack = false
        rv = true
      end
    end
    ImGui.EndCombo(ctx)
  end

  local numTracks = reaper.GetNumTracks()
  if not reaper.ValidatePtr(outputProj, 'ReaProject*') or
     not reaper.ValidatePtr2(outputProj, outputTrack, 'MediaTrack*') then
    outToTrack = false
    outputTrack = reaper.GetTrack(nil, 0)
    outputProj = reaper.EnumProjects(-1)
    rv = true
  end
  ImGui.BeginDisabled(ctx, not outputTrack and numTracks == 0)
  ImGui.SameLine(ctx)
  if ImGui.RadioButton(ctx, 'Through track', outToTrack) then
    outToTrack = true
    rv = true
  end
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, -FLT_MIN)
  local trackName = '<no track>'
  if outputTrack then trackName = select(2, reaper.GetTrackName(outputTrack)) end
  if ImGui.BeginCombo(ctx, '##track', trackName) then
    for i = 0, numTracks - 1 do
      local track = reaper.GetTrack(nil, i)
      trackName = select(2, reaper.GetTrackName(track))
      if ImGui.Selectable(ctx, trackName, track == outputTrack) then
        outputTrack = track
        outputProj = reaper.EnumProjects(-1)
        outToTrack = true
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
  if ImGui.BeginCombo(ctx, 'Pitch shift mode', psModes[psMode].n) then
    for i, mode in ipairs(psModes) do
      if ImGui.Selectable(ctx, mode.n, psMode == i) then
        psMode = i
        psSubMode = 1
        updatePitchShiftSubmodes()
        rv = true
      end
    end
    ImGui.EndCombo(ctx)
  end

  ImGui.SameLine(ctx)
  ImGui.BeginDisabled(ctx, #psSubModes == 0)
  ImGui.SetNextItemWidth(ctx, -62)
  if ImGui.BeginCombo(ctx, 'Submode', psSubModes[psSubMode] or '') then
    for i, submode in ipairs(psSubModes) do
      if ImGui.Selectable(ctx, submode, psSubMode == i) then
        psSubMode = i
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
  if outToTrack then
    reaper.CF_Preview_SetOutputTrack(preview, outputProj, outputTrack)
  else
    reaper.CF_Preview_SetValue(preview, 'I_OUTCHAN', outputChan)
  end
  -- reaper.CF_Preview_SetValue(preview, 'D_POSITION', position)
  reaper.CF_Preview_SetValue(preview, 'B_LOOP', loop and 1 or 0)
  reaper.CF_Preview_SetValue(preview, 'D_VOLUME', volume)
  reaper.CF_Preview_SetValue(preview, 'D_PAN', pan)
  reaper.CF_Preview_SetValue(preview, 'D_MEASUREALIGN', measureAlign)
  reaper.CF_Preview_SetValue(preview, 'D_PLAYRATE', playRate)
  reaper.CF_Preview_SetValue(preview, 'D_PITCH', pitch)
  reaper.CF_Preview_SetValue(preview, 'B_PPITCH', preservePitch and 1 or 0)
  reaper.CF_Preview_SetValue(preview, 'I_PITCHMODE', pitchMode())
  reaper.CF_Preview_SetValue(preview, 'D_FADEINLEN', fadeInLen)
  reaper.CF_Preview_SetValue(preview, 'D_FADEOUTLEN', fadeOutLen)
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
    local rv, newFile = reaper.JS_Dialog_BrowseForOpenFiles('Select audio file', '', file, '', false)
    if rv and newFile:len() > 0 then
      file = newFile
      reaper.SetExtState('sws_test', 'preview_file', file, false)
    end
  end

  local time = ('%s / %s'):format(
    reaper.format_timestr(position, ''),
    reaper.format_timestr(length, ''))
  rv, seekPos = ImGui.SliderDouble(ctx, '##position', seekPos or position, 0, length, time)
  if ImGui.IsItemDeactivatedAfterEdit(ctx) then
    reaper.CF_Preview_SetValue(preview, 'D_POSITION', seekPos)
  elseif not ImGui.IsItemActive(ctx) then
    seekPos = position
  end
  ImGui.SameLine(ctx)
  rv, loop = ImGui.Checkbox(ctx, 'Loop', loop)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'B_LOOP', loop and 1 or 0) end

  if outputSelect() then
    if outToTrack then
      reaper.CF_Preview_SetOutputTrack(preview, outputProj, outputTrack)
    else
      reaper.CF_Preview_SetValue(preview, 'I_OUTCHAN', outputChan)
    end
  end

  ImGui.SetNextItemWidth(ctx, -340)
  rv, volume = ImGui.SliderDouble(ctx, 'Volume', volume, 0, 2,
    ('%.2fdB'):format(VAL2DB(volume)), ImGui.SliderFlags_Logarithmic())
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_VOLUME', volume) end
  ImGui.SameLine(ctx)
  ImGui.SetNextItemWidth(ctx, 55)
  rv, pan = ImGui.SliderDouble(ctx, 'Pan', pan, -1, 1)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_PAN', pan) end
  ImGui.SameLine(ctx)
  local avail_w = ImGui.PushItemWidth(ctx, 40)
  rv, fadeInLen = ImGui.InputDouble(ctx, 'Fade in', fadeInLen)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_FADEINLEN', fadeInLen) end
  ImGui.SameLine(ctx)
  rv, fadeOutLen = ImGui.InputDouble(ctx, 'Fade out', fadeOutLen)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_FADEOUTLEN', fadeOutLen) end
  ImGui.PopItemWidth(ctx)

  ImGui.PushItemWidth(ctx, 50)
  rv, playRate = ImGui.InputDouble(ctx, 'Playback rate', playRate)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_PLAYRATE', playRate) end
  ImGui.SameLine(ctx)
  rv, pitch = ImGui.InputDouble(ctx, 'Pitch adjust (semitones)', pitch)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'D_PITCH', pitch) end
  ImGui.PopItemWidth(ctx)
  ImGui.SameLine(ctx)
  rv, preservePitch = ImGui.Checkbox(ctx, 'Preserve pitch when changing rate', preservePitch)
  if rv and active then reaper.CF_Preview_SetValue(preview, 'B_PPITCH', preservePitch and 1 or 0) end

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
  rv, measureAlign = ImGui.InputInt(ctx, 'Align to measure', measureAlign)
  if rv and measureAlign < 0 then measureAlign = 0 end
  ImGui.SameLine(ctx, nil, 20)
  rv, reverse = ImGui.Checkbox(ctx, 'Reverse', reverse)
  ImGui.SameLine(ctx, nil, 20)
  ImGui.SetNextItemWidth(ctx, -62)
  rv, peakChans = ImGui.InputInt(ctx, 'Peaks', peakChans, 1, 1)
  if rv then peakChans = math.max(2, math.min(128, peakChans)) end

  ImGui.Spacing(ctx)
  local avail_w, avail_h = ImGui.GetContentRegionAvail(ctx)
  local spacing_x, spacing_h = ImGui.GetStyleVar(ctx, ImGui.StyleVar_ItemSpacing())
  local meter_h = math.max(spacing_h, ((avail_h + spacing_h) / peakChans) - spacing_h)
  for i = 0, peakChans - 1 do
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

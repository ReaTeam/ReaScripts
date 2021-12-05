-- @description Apply render preset
-- @author cfillion
-- @version 2.0.2
-- @changelog Fix restoration of the tail checkbox
-- @provides
--   .
--   [main] . > cfillion_Apply render preset (create action).lua
-- @link https://cfillion.ca
-- @screenshot
--   https://i.imgur.com/Xy44ZlR.gif
--   Interface customization https://i.imgur.com/vKa8oc9.gif
-- @donation https://paypal.me/cfillion
-- @about
--   # Apply render preset
--
--   This package provides two scripts for applying render presets from outside
--   of the render dialog.
--
--   The primary action, *cfillion_Apply render preset.lua*, shows a list of
--   all available presets and applies the selected one.
--
--   The second action, *cfillion_Apply render preset (create action)*.lua,
--   dynamically creates a new action script for applying the chosen preset.
--   This new action can be used for applying the chosen preset without any
--   user interaction (eg. as part of a custom action).
--
--   The main script and generated scripts can be combined with the REAPER action
--   "File: Render project, using the most recent render settings" (or similar)
--   as part of a custom action.
--
--   ## Caveats
--
--   The following restrictions apply due to current limitations in REAPER's
--   scripting API.
--
--   These settings are applied but not visible immediately in the render dialog (if opened):
--
--   - Render speed
--   - Resample mode
--   - Use project sample rate for mixing and FX/synth processing

local r = reaper
local REAPER_BEFORE_V6 = tonumber(r.GetAppVersion():match('^%d+')) < 6
local SETTINGS_SOURCE_MASK  = 0x10EB
local SETTINGS_OPTIONS_MASK = 0x0F14

local function getScriptInfo()
  local path = ({r.get_action_context()})[2]

  local isCreate = false
  local first, last = path:find(' %(create action%)')
  if first and last then
    isCreate = true
    path = path:sub(1, first  - 1) .. path:sub(last + 1)
  end

  return {
    path = path,
    name = path:match("([^/\\_]+)%.lua$"),
    isCreate = isCreate,
  }
end

local scriptInfo = getScriptInfo()

local function insertPreset(presets, name)
  local preset = presets[name]

  if not preset then
    preset = {}
    presets[name] = preset
  end

  return preset
end

local function checkTokenCount(tokens, expectedMin, expectedMax)
  if #tokens < expectedMin then
    return false, string.format(
      'reaper-render.ini: %s contains %d tokens, expected at least %d',
      tokens[1], #tokens, expectedMin
    )
  elseif expectedMax and #tokens > expectedMax then
    return false, string.format(
      'reaper-render.ini: %s contains %d tokens, expected no more than %d',
      tokens[1], #tokens, expectedMax
    )
  else
    return true
  end
end

local function tokenize(line)
  local pos, tokens = 1, {}

  while pos do
    local tail, eat = nil, 1

    if line:sub(pos, pos) == '"' then
      pos = pos + 1 -- eat the opening quote
      tail = line:find('"%s', pos)
      eat = 2

      if not tail then
        if line:sub(-1) == '"' then
          tail = line:len()
        else
          error('missing closing quote')
        end
      end
    else
      tail = line:find('%s', pos)
    end

    if pos <= line:len() then
      table.insert(tokens, line:sub(pos, tail and tail - 1))
    end

    pos = tail and tail + eat
  end

  return tokens
end

function parseDefault(presets, line)
  local tokens = tokenize(line)

  if tokens[1] == '<RENDERPRESET' then
    return parseFormatPreset(presets, tokens)
  elseif tokens[1] == '<RENDERPRESET2' then
    return parseFormatPreset2(presets, tokens)
  elseif tokens[1] == 'RENDERPRESET_OUTPUT' then
    return parseOutputPreset(presets, tokens)
  elseif tokens[1] == 'RENDERPRESET_EXT' then
    return parseNormalizePreset(presets, tokens)
  end

  return nil, string.format(
    'reaper-render.ini: found unknown preset type: %s', tokens[1])
end

function nodeContentExtractor(preset, key)
  local function parser(_, line)
    if line:sub(1, 1) == '>' then
      -- reached the end of the RENDERPRESET tag
      return parseDefault
    end

    preset[key] = (preset[key] or '') .. line:match('[^%s]+')

    return parser
  end

  return parser
end

local function addPresetSettings(preset, mask, value)
  preset.RENDER_SETTINGS = (value & mask) | (preset.RENDER_SETTINGS or 0)
  preset._render_settings_mask = mask | (preset._render_settings_mask or 0)
end

function parseFormatPreset(presets, tokens)
  local ok, err = checkTokenCount(tokens, 8, 9)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  preset.RENDER_SRATE           = tonumber(tokens[3])
  preset.RENDER_CHANNELS        = tonumber(tokens[4])
  preset.projrenderlimit        = tonumber(tokens[5]) -- render speed
  preset.projrenderrateinternal = tonumber(tokens[6]) -- use proj splrate
  preset.projrenderresample     = tonumber(tokens[7])
  preset.RENDER_DITHER          = tonumber(tokens[8])
  preset.RENDER_FORMAT2         = '' -- reset when no <RENDERPRESET2 node exists

  -- Moved from output presets to format presets in v6.0
  -- RENDER_SETTINGS is still shared with Source settings from output presets
  if tokens[9] ~= nil then
    addPresetSettings(preset, SETTINGS_OPTIONS_MASK, tonumber(tokens[9]))
  end

  return nodeContentExtractor(preset, 'RENDER_FORMAT')
end

function parseFormatPreset2(presets, tokens)
  local ok, err = checkTokenCount(tokens, 1)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  return nodeContentExtractor(preset, 'RENDER_FORMAT2')
end

function parseOutputPreset(presets, tokens)
  local ok, err = checkTokenCount(tokens, 9)
  if not ok then return nil, err end

  local settingsMask = SETTINGS_SOURCE_MASK
  if REAPER_BEFORE_V6 then
    -- "Tracks with only mono media to mono files" and
    -- "Multichannel tracks to multichannel files"
    settingsMask = settingsMask | SETTINGS_OPTIONS_MASK
  end

  local preset = insertPreset(presets, tokens[2])
  preset.RENDER_BOUNDSFLAG = tonumber(tokens[3])
  preset.RENDER_STARTPOS   = tonumber(tokens[4])
  preset.RENDER_ENDPOS     = tonumber(tokens[5])
  addPresetSettings(preset, settingsMask, tonumber(tokens[6]))
  preset._unknown          = tokens[7]           -- what is this (always 0)?
  preset.RENDER_PATTERN    = tostring(tokens[8]) -- file name
  preset.RENDER_TAILFLAG   = tonumber(tokens[9]) == 0 and 0 or 0xFF

  return parseDefault
end

function parseNormalizePreset(presets, tokens)
  local ok, err = checkTokenCount(tokens, 3)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  preset.RENDER_NORMALIZE        = tonumber(tokens[3])
  preset.RENDER_NORMALIZE_TARGET = tonumber(tokens[4])
  if tokens[5] ~= nil then
    preset.RENDER_BRICKWALL = tonumber(tokens[5]) -- v6.37
  end

  return parseDefault
end

local function getRenderPresets()
  local presets = {}
  local parser = parseDefault

  local path = string.format('%s/reaper-render.ini', r.GetResourcePath())
  if not r.file_exists(path) then
    return presets
  end

  local file, err = assert(io.open(path, 'r'))

  for line in file:lines() do
    parser = assert(parser(presets, line))
  end

  file:close()

  assert(parser == parseDefault, 'reaper-render.ini: prematurely reached EOF')

  return presets
end

local function applyRenderPreset(project, preset)
  for key, value in pairs(preset) do
    if key:match('^_') or key == 'RENDER_FORMAT' then -- unsupported setting
    elseif type(value) == 'string' then
      r.GetSetProjectInfo_String(project, key, value, true)
    elseif key:match('^[a-z]') then -- lowercase
      r.SNM_SetIntConfigVar(key, value)
    else
      local mask = preset[('_%s_mask'):format(key:lower())]
      if mask then
        value = (value & mask) |
          (r.GetSetProjectInfo(project, key, 0, false) & ~mask)
      end
      r.GetSetProjectInfo(project, key, value, true)
    end
  end

  if preset.RENDER_FORMAT then
    -- workaround for this REAPER bug: https://forum.cockos.com/showthread.php?t=224539
    r.GetSetProjectInfo_String(project, 'RENDER_FORMAT', preset.RENDER_FORMAT, true)
  end
end

local function sanitizeFilename(name)
  -- replace special characters that are reserved on Windows
  return name:gsub('[*\\:<>?/|"%c]+', '-')
end

local function createAction(presetName)
  local fnPresetName = sanitizeFilename(presetName)
  local actionName = string.format('Apply render preset - %s', fnPresetName)
  local outputFn = string.format('%s/Scripts/%s.lua',
    r.GetResourcePath(), actionName)
  local baseName = scriptInfo.path:match('([^/\\]+)$')
  local relPath = scriptInfo.path:sub(r.GetResourcePath():len() + 2)

  local code = string.format([[
-- This file was created by %s on %s

ApplyPresetByName = %q
dofile(string.format(%q, reaper.GetResourcePath()))
]], baseName, os.date('%c'), presetName, '%s/'..relPath)

  local file = assert(io.open(outputFn, 'w'))
  file:write(code)
  file:close()

  if r.AddRemoveReaScript(true, 0, outputFn, true) == 0 then
    r.ShowMessageBox(
      'Failed to create or register the new action.', scriptInfo.name, 0)
    return
  end

  r.ShowMessageBox(
    string.format('Created the action "%s".', actionName), scriptInfo.name, 0)
end

local function main(presetName, preset)
  if scriptInfo.isCreate then
    createAction(presetName)
  else
    applyRenderPreset(nil, preset)
  end
end

local function gfxdo(callback)
  local app = r.GetAppVersion()
  if app:match('OSX') or app:match('linux') then
    return callback()
  end

  local curx, cury = r.GetMousePosition()
  gfx.init("", 0, 0, 0, curx, cury)

  if r.JS_Window_SetStyle then
    local window = r.JS_Window_GetFocus()
    local winx, winy = r.JS_Window_ClientToScreen(window, 0, 0)
    gfx.x = gfx.x - (winx - curx)
    gfx.y = gfx.y - (winy - cury)
    r.JS_Window_SetStyle(window, "POPUP")
    r.JS_Window_SetOpacity(window, 'ALPHA', 0)
  end

  local value = callback()
  gfx.quit()
  return value
end

local function boolText(ctx, bool)
  r.ImGui_Text(ctx, bool and 'On' or 'Off')
end

local function isCellHovered(ctx)
  -- Call before adding content to the cell.
  -- Uses Selectable so that using IsItemHovered after calling this will
  -- be true over the whole cell.
  local x = r.ImGui_GetCursorPosX(ctx)
  r.ImGui_Selectable(ctx, '')
  r.ImGui_SameLine(ctx)
  r.ImGui_SetCursorPosX(ctx, x)
  return r.ImGui_IsItemHovered(ctx)
end

local function enumCell(ctx, values, value)
  if value then
    r.ImGui_Text(ctx, values[value + 1] or ('Unknown (%d)'):format(value))
  end
end

local function sampleRateCell(ctx, preset)
  if isCellHovered(ctx) and preset.projrenderrateinternal ~= nil then
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_Checkbox(ctx,
      'Use project sample rate for mixing and FX/synth processing',
      preset.projrenderrateinternal)
    r.ImGui_EndTooltip(ctx)
  end

  if preset.RENDER_SRATE then
    r.ImGui_Text(ctx, ('%g kHz'):format(preset.RENDER_SRATE / 1000))
  end
end

local function channelsCell(ctx, preset)
  local channels = { 'Mono', 'Stereo' }
  r.ImGui_Text(ctx,
    channels[preset.RENDER_CHANNELS] or preset.RENDER_CHANNELS)
end

local function ditherCell(ctx, preset)
  local dither = preset.RENDER_DITHER
  if not dither then return end
  if isCellHovered(ctx) then
    r.ImGui_BeginTooltip(ctx)
    if r.ImGui_BeginTable(ctx, 'dither', 2) then
      r.ImGui_TableNextRow(ctx)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_CheckboxFlags(ctx, 'Dither master', dither, 1)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_CheckboxFlags(ctx, 'Dither stems', dither, 4)

      r.ImGui_TableNextRow(ctx)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_CheckboxFlags(ctx, 'Noise shape master', dither, 2)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_CheckboxFlags(ctx, 'Noise shape stems', dither, 8)
      r.ImGui_EndTable(ctx)
    end
    r.ImGui_EndTooltip(ctx)
  end
  boolText(ctx, dither ~= 0)
end

local function VAL2DB(x)
  -- ported from WDL's val2db.h
  local TWENTY_OVER_LN10 = 8.6858896380650365530225783783321
  if x < 0.0000000298023223876953125 then return -150.0 end
  local v = math.log(x) * TWENTY_OVER_LN10
  return math.max(v, -150.0)
end

local function normalizeCell(ctx, preset)
  local NORMALIZE_ENABLE = 1
  local BRICKWALL_ENABLE = 64

  local normalize = preset.RENDER_NORMALIZE
  if not normalize then return end
  if isCellHovered(ctx) then
    r.ImGui_BeginTooltip(ctx)

    if r.ImGui_BeginTable(ctx, 'normal', 3) then
      r.ImGui_TableNextRow(ctx)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_CheckboxFlags(ctx, 'Normalize to:', normalize, NORMALIZE_ENABLE)
      r.ImGui_TableNextColumn(ctx)
      enumCell(ctx, { 'LUFS-I', 'RMS', 'Peak', 'True peak' }, (normalize & 14) >> 1)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_Text(ctx, ('%g dB'):format(VAL2DB(preset.RENDER_NORMALIZE_TARGET)))

      r.ImGui_TableNextRow(ctx)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_CheckboxFlags(ctx, 'Brickwall limit:', normalize, BRICKWALL_ENABLE)
      r.ImGui_TableNextColumn(ctx)
      enumCell(ctx, { 'Peak', 'True peak' }, (normalize >> 7) & 1)
      r.ImGui_TableNextColumn(ctx)
      r.ImGui_Text(ctx, ('%g dB'):format(VAL2DB(preset.RENDER_BRICKWALL or 1)))

      r.ImGui_EndTable(ctx)
    end

    r.ImGui_EndTooltip(ctx)
  end
  boolText(ctx, (normalize & (NORMALIZE_ENABLE | BRICKWALL_ENABLE)) ~= 0)
end

local function sourceCell(ctx, preset)
  if ((preset._render_settings_mask or 0) & SETTINGS_SOURCE_MASK) == 0 then
    return
  end

  local source = preset.RENDER_SETTINGS & SETTINGS_SOURCE_MASK
  local sources = {
    [0x0000] = 'Master mix',
    [0x0003] = 'Stems (selected tracks)',
    [0x0001] = 'Master mix + stems',
    [0x0080] = 'Selected tracks via master',
    [0x0008] = 'Region render matrix',
    [0x0020] = 'Selected media items',
    [0x0040] = 'Selected media items via master',
    [0x1000] = 'Razor edit areas',
    [0x1080] = 'Razor edit areas via master',
  }
  r.ImGui_Text(ctx, sources[source] or ('Unknown (%d)'):format(source))
end

local function boundsCell(ctx, preset)
  if not preset.RENDER_BOUNDSFLAG then return end

  local bounds = {
    'Custom time range', 'Entire project', 'Time selection', 'Project regions',
    'Selected media items', 'Selected regions',
  }

  if preset.RENDER_BOUNDSFLAG == 0
      and preset.RENDER_STARTPOS and preset.RENDER_ENDPOS then
    r.ImGui_Text(ctx, ('%s to %s'):format(
      r.format_timestr(preset.RENDER_STARTPOS, ''),
      r.format_timestr(preset.RENDER_ENDPOS, '')))
  else
    enumCell(ctx, bounds, preset.RENDER_BOUNDSFLAG)
  end
end

local function optionsCell(ctx, preset)
  if ((preset._render_settings_mask or 0) & SETTINGS_OPTIONS_MASK) == 0 then
    return
  end

  if isCellHovered(ctx) then
    r.ImGui_BeginTooltip(ctx)
    r.ImGui_CheckboxFlags(ctx, '2nd pass render', preset.RENDER_SETTINGS, 2048)
    r.ImGui_CheckboxFlags(ctx, 'Tracks with only mono media to mono files',
      preset.RENDER_SETTINGS, 16)
    r.ImGui_CheckboxFlags(ctx, 'Multichannel tracks to multichannel files',
      preset.RENDER_SETTINGS, 4)

    r.ImGui_AlignTextToFramePadding(ctx)
    r.ImGui_Text(ctx, 'Embed:')
    r.ImGui_SameLine(ctx)
    r.ImGui_CheckboxFlags(ctx, 'Metadata', preset.RENDER_SETTINGS, 512)
    r.ImGui_SameLine(ctx)
    r.ImGui_CheckboxFlags(ctx, 'Stretch markers/transient guides',
      preset.RENDER_SETTINGS, 256)
    r.ImGui_SameLine(ctx)
    r.ImGui_CheckboxFlags(ctx, 'Take markers', preset.RENDER_SETTINGS, 1024)

    r.ImGui_EndTooltip(ctx)
  end

  r.ImGui_Bullet(ctx)
end

function decodeBase64(data)
  -- source: https://stackoverflow.com/a/35303321/796375
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  data = data:gsub('[^'..b..'=]', '')
  return data:gsub('.', function(x)
    if x == '=' then return '' end
    local r, f = '', b:find(x) - 1
    for i = 6, 1, -1 do
      r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0')
    end
    return r
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if #x ~= 8 then return '' end
    local c = 0
    for i = 1, 8 do
      c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
    end
    return string.char(c)
  end)
end

local function formatCell(ctx, preset, key)
  if not preset[key] then return end
  if preset[key] == '' then
    boolText(ctx, false)
    return
  end

  if not preset._format_cache then
    preset._format_cache = {}
  end
  if not preset._format_cache[key] then
    local data = decodeBase64(preset[key])
    preset._format_cache[key] = string.unpack('c4', data):reverse()
  end

  local formats = {
    ['wave'] = 'WAV',
    ['aiff'] = 'AIFF',
    ['mp3l'] = 'MP3 (LAME)',
    ['wvpk'] = 'WavPack',
    ['OggS'] = 'OGG Opus',
    ['flac'] = 'FLAC',
    ['ddp '] = 'DDP',
    ['iso '] = 'CD image',
    ['oggv'] = 'OGG Vorbis',
    ['FFMP'] = 'Video (ffmpeg)',
    ['XAVF'] = 'Video (AVFoundation)',
    ['GIF '] = 'Video (GIF)',
    ['LCF '] = 'Video (LCF)',
  }
  r.ImGui_Text(ctx, formats[preset._format_cache[key]] or preset._format_cache[key])
end

local function presetRow(ctx, name, preset)
  r.ImGui_TableNextColumn(ctx)
  if r.ImGui_Selectable(ctx, name, false,
      r.ImGui_SelectableFlags_SpanAllColumns()) then
    main(name, preset)
    r.ImGui_CloseCurrentPopup(ctx)
  end

  local speeds = {
    'Full-speed Offline', '1x Offline', 'Online Render', 'Online Render (Idle)',
    'Offline Render (Idle)',
  }

  local resampleModes = {
    'Medium (64pt Sinc)', 'Low (Linear Interpolation)',
    'Lowest (Point Sampling)', 'Good (192pt Sinc)', 'Better (348pt Sinc)',
    'Fast (IIR + Linear Interpolation)', 'Fast (IIRx2 + Linear Interpolation)',
    'Fast (16pt Sinc)', 'HQ (512 pt)', 'Extreme HQ (768pt HQ Sinc)',
  }


  local cells = {
    function() formatCell(ctx, preset, 'RENDER_FORMAT') end,
    function() formatCell(ctx, preset, 'RENDER_FORMAT2') end,
    sampleRateCell,
    channelsCell,
    function() enumCell(ctx, speeds, preset.projrenderlimit) end,
    function() enumCell(ctx, resampleModes, preset.projrenderresample) end,
    ditherCell,
    normalizeCell,
    sourceCell,
    boundsCell,
    function()
      if preset.RENDER_TAILFLAG then boolText(ctx, preset.RENDER_TAILFLAG ~= 0) end
    end,
    'RENDER_PATTERN', -- file name
    optionsCell,
  }

  for _, cell in ipairs(cells) do
    if r.ImGui_TableNextColumn(ctx) then
      if type(cell) == 'function' then
        cell(ctx, preset)
      else
        r.ImGui_Text(ctx, preset[cell])
      end
    end
  end
end

assert(r.GetSetProjectInfo,   'REAPER v5.975 or newer is required')
assert(r.SNM_SetIntConfigVar, 'The SWS extension is not installed')

local presets = getRenderPresets()

if ApplyPresetByName then
  local preset = presets[ApplyPresetByName]
  if preset then
    applyRenderPreset(nil, preset)
  else
    r.ShowMessageBox(
      string.format("Unable to find a render preset named '%s'.", ApplyPresetByName),
      scriptInfo.name, 0)
  end
  return
end

local names = {}
for name, preset in pairs(presets) do
  table.insert(names, name)
end
table.sort(names, function(a, b) return a:lower() < b:lower() end)

if not r.ImGui_CreateContext then
  local presetName = gfxdo(function()
    if #names == 0 then
      gfx.showmenu('#No render preset found')
      return
    end

    table.insert(names, 1, '#Select a render preset (legacy menu, ReaImGui not found):')

    local choice = gfx.showmenu(table.concat(names, '|'))
    if choice < 2 then return end

    return names[choice] -- preset name
  end)
  if presetName then
    main(presetName, presets[presetName])
  end
  return
end

local contextFlags = r.ImGui_ConfigFlags_NavEnableKeyboard()
local windowFlags  =
  r.ImGui_WindowFlags_AlwaysAutoResize() |
  r.ImGui_WindowFlags_NoDocking()        |
  r.ImGui_WindowFlags_NoTitleBar()       |
  r.ImGui_WindowFlags_TopMost()
local tableFlags   =
  r.ImGui_TableFlags_Borders()           |
  r.ImGui_TableFlags_Hideable()          |
  r.ImGui_TableFlags_Reorderable()       |
  r.ImGui_TableFlags_Resizable()         |
  r.ImGui_TableFlags_RowBg()
local hiddenColFlags =
  r.ImGui_TableColumnFlags_DefaultHide()

local ctx = r.ImGui_CreateContext(scriptInfo.name, contextFlags)
local clipper = r.ImGui_CreateListClipper(ctx)
local size = r.GetAppVersion():match('OSX') and 12 or 14
local font = r.ImGui_CreateFont('sans-serif', size)
r.ImGui_AttachFont(ctx, font)

local function popup()
  if #names == 0 then
    r.ImGui_TextDisabled(ctx, 'No render presets found.')
  else
    if scriptInfo.isCreate then
      r.ImGui_Text(ctx, 'Select a render preset for the new action:')
    else
      r.ImGui_Text(ctx, 'Select a render preset to apply:')
    end
    r.ImGui_Spacing(ctx)

    if r.ImGui_BeginTable(ctx, 'Presets', 14, tableFlags) then
      r.ImGui_TableSetupColumn(ctx, 'Name')
      r.ImGui_TableSetupColumn(ctx, 'Format')
      r.ImGui_TableSetupColumn(ctx, 'Format (secondary)', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Sample rate')
      r.ImGui_TableSetupColumn(ctx, 'Channels', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Speed', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Resample mode', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Dither', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Normalize', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Source', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Bounds', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Tail', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'File name', hiddenColFlags)
      r.ImGui_TableSetupColumn(ctx, 'Options', hiddenColFlags)

      r.ImGui_TableHeadersRow(ctx)

      r.ImGui_ListClipper_Begin(clipper, #names)
      while r.ImGui_ListClipper_Step(clipper) do
        local display_start, display_end = r.ImGui_ListClipper_GetDisplayRange(clipper)
        for i = display_start + 1, display_end do
          local name = names[i]
          r.ImGui_TableNextRow(ctx)
          r.ImGui_PushID(ctx, i)
          presetRow(ctx, name, presets[name])
          r.ImGui_PopID(ctx)
        end
      end

      r.ImGui_EndTable(ctx)
    end
  end
end

local function loop()
  if r.ImGui_IsWindowAppearing(ctx) then
    r.ImGui_SetNextWindowPos(ctx,
      r.ImGui_PointConvertNative(ctx, r.GetMousePosition()))
    r.ImGui_OpenPopup(ctx, scriptInfo.name)
  end

  if r.ImGui_IsPopupOpen(ctx, scriptInfo.name) then
    -- HACK: Dirty trick to force the table to save its settings.
    -- Tables inherit the NoSavedSettings flag from the parent top-level window.
    -- Creating the window first prevents BeginPopup from setting that flag.
    local WindowFlags_Popup = 1 << 26
    if r.ImGui_Begin(ctx, '##Popup_b362686d', false,
        windowFlags | WindowFlags_Popup) then
      r.ImGui_End(ctx)
    end
  end

  if r.ImGui_BeginPopup(ctx, scriptInfo.name, windowFlags) then
    r.ImGui_PushFont(ctx, font)
    popup()
    r.ImGui_PopFont(ctx)
    r.ImGui_EndPopup(ctx)
    r.defer(loop)
  else
    r.ImGui_DestroyContext(ctx)
  end
end

r.defer(loop)

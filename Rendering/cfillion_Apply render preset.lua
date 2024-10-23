-- @description Apply render preset
-- @author cfillion
-- @version 2.1.5
-- @changelog Display REAPER v7.23's new normalization options
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

local ImGui
if reaper.ImGui_GetBuiltinPath then
  package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
  ImGui = require 'imgui' '0.9'
end

local FLT_MIN, FLT_MAX = ImGui.NumericLimits_Float()
local REAPER_BEFORE_V6 = tonumber(reaper.GetAppVersion():match('^%d+')) < 6
local SETTINGS_SOURCE_MASK  = 0x10EB
local SETTINGS_OPTIONS_MASK = 0x6F14
local KNOWN_METADATA_TAGS = {
  ['Title'] = {
    'APE:Title', 'ASWG:project', 'CAFINFO:title', 'CART:Title',
    'CUE:DISC_TITLE', 'ID3:TIT2', 'IFF:NAME', 'INFO:INAM', 'IXML:PROJECT',
    'VORBIS:TITLE', 'XMP:dc/title',
  },
  ['Description'] = {
    'APE:Subtitle', 'ASWG:session', 'BWF:Description', 'ID3:TIT3', 'IFF:ANNO',
    'INFO:IKEY', 'INFO:ISBJ', 'VORBIS:DESCRIPTION', 'XMP:dc/description',
  },
  ['Comment'] = {
    'APE:Comment', 'ASWG:notes', 'CAFINFO:comments', 'CART:TagText',
    'CUE:DISC_REM', 'ID3:COMM', 'INFO:ICMT', 'IXML:NOTE', 'VORBIS:COMMENT',
    'XMP:dm/logComment',
  },
  ['Artist'] = {
    'APE:Artist', 'ASWG:artist', 'CAFINFO:artist', 'CART:Artist', 'ID3:TPE1',
    'IFF:AUTH', 'INFO:IART', 'VORBIS:ARTIST', 'XMP:dm/artist',
  },
  ['Album Artist'] = {
    'ID3:TPE2', 'VORBIS:ALBUMARTIST',
  },
  ['Performer'] = {
    'CUE:DISC_PERFORMER', 'VORBIS:PERFORMER',
  },
  ['Date'] = {
    'APE:Record Date', 'APE:Year', 'BWF:OriginationDate', 'CAFINFO:year',
    'CART:StartDate', 'ID3:TDRC', 'ID3:TYER', 'INFO:ICRD', 'VORBIS:DATE',
    'XMP:dc/date',
  },
  ['Recording Time'] = {
    'BWF:OriginationTime', 'CAFINFO:recorded date', 'ID3:TIME',
  },
  ['Genre'] = {
    'APE:Genre', 'ASWG:genre', 'CAFINFO:genre', 'CART:Category', 'ID3:TCON',
    'INFO:IGNR', 'VORBIS:GENRE', 'XMP:dm/genre',
  },
  ['Key'] = {
    'APE:Key', 'ASWG:inKey', 'CAFINFO:key signature', 'ID3:TKEY', 'VORBIS:KEY',
    'XMP:dm/key',
  },
  ['Tempo'] = {
    'APE:BPM', 'ASWG:tempo', 'CAFINFO:tempo', 'ID3:TBPM', 'VORBIS:BPM',
    'XMP:dm/tempo',
  },
  ['Time Signature'] = {
    'ASWG:timeSig', 'CAFINFO:time signature', 'XMP:dm/timeSignature',
  },
  -- skipped: Start Offset (automatic)
  ['Track Number'] = {
    'APE:Track', 'CAFINFO:track number', 'CART:CutID', 'CUE:INDEX',
    'ID3:TRCK', 'INFO:TRCK', 'VORBIS:TRACKNUMBER', 'XMP:dm/trackNumber',
  },
  -- skipped: Chapter (automatic)
  ['Part Number'] = {
    'ASWG:orderRef', 'ID3:TPOS', 'VORBIS:PARTNUMBER',
  },
  ['Scene'] = {
    'IXML:SCENE', 'XMP:dm/scene',
  },
  ['Lyrics'] = {
    'ID3:USLT', 'VORBIS:LYRICS',
  },
  ['Composer'] = {
    'APE:Composer', 'ASWG:composer', 'CAFINFO:composer', 'ID3:TCOM',
    'VORBIS:COMPOSER', 'XMP:dm/composer',
  },
  ['Conductor'] = {
    'APE:Conductor', 'VORBIS:CONDUCTOR',
  },
  ['Creator'] = {
    'ASWG:creatorId', 'XMP:dc/creator',
  },
  ['Engineer'] = {
    'ASWG:recEngineer', 'INFO:IENG', 'XMP:dm/engineer',
  },
  ['Lyricist'] = {
    'CAFINFO:lyricist', 'ID3:TEXT', 'VORBIS:LYRICIST',
  },
  ['Producer'] = {
    'ASWG:producer', 'VORBIS:PRODUCER',
  },
  ['Publisher'] = {
    'APE:Publisher', 'ASWG:musicPublisher', 'VORBIS:PUBLISHER',
  },
  ['Album'] = {
    'APE:Album', 'CAFINFO:album', 'ID3:TALB', 'INFO:IPRD', 'VORBIS:ALBUM',
    'XMP:dm/album',
  },
  ['Originator'] = {
    'ASWG:originator', 'BWF:Originator',
  },
  ['Source'] = {
    'ASWG:isSource', 'INFO:ISRC',
  },
  ['Version'] = {
    'ASWG:musicVersion', 'VORBIS:VERSION',
  },
  ['Media Explorer Tags'] = {
  },
  -- skipped: User Defined
  ['ISRC'] = {
    'APE:ISRC', 'ASWG:isrcId', 'AXML:ISRC', 'ID3:TSRC', 'VORBIS:ISRC',
  },
  ['Barcode'] = {
    'CUE:DISC_CATALOG', 'VORBIS:EAN/UPN',
  },
  ['Copyright Message'] = {
    'CAFINFO:copyright', 'ID3:TCOP', 'IFF:COPY', 'INFO:ICOP', 'XMP:dm/copyright',
  },
  ['Copyright Holder'] = {
    'APE:Copyright', 'VORBIS:COPYRIGHT',
  },
  ['License'] = {
    'ASWG:isLicensed', 'VORBIS:LICENSE',
  },
  ['Channel Configuration'] = {
    'CAFINFO:channel configuration', 'WAVEXT:channel configuration',
  },
  ['Channel Layout Text'] = {
    'ASWG:channelConfig', 'CAFINFO:channel layout',
  },
  ['Encoded By'] = {
    'CAFINFO:encoding application', 'VORBIS:ENCODED-BY',
  },
  ['Encoding Settings'] = {
    'CAFINFO:source encoder', 'VORBIS:ENCODING',
  },
  ['Language'] = {
    'APE:Language', 'ASWG:language', 'ID3:COMMENT_LANG', 'ID3:LYRIC_LANG',
    'VORBIS:LANGUAGE', 'XMP:dc/language',
  },
  ['LRA Loudness Range'] = {
    'ASWG:loudnessRange', 'BWF:LoudnessRange',
  },
  ['LUFS-I Integrated Loudness'] = {
    'ASWG:loudness', 'BWF:LoudnessValue',
  },
  ['Recording Location'] = {
    'APE:Record Location', 'ASWG:impulseLocation', 'ASWG:recordingLoc',
    'VORBIS:LOCATION',
  },
  ['Image Type'] = {
    'FLACPIC:APIC_TYPE', 'ID3:APIC_TYPE',
  },
  ['Image Description'] = {
    'FLACPIC:APIC_DESC', 'ID3:APIC_DESC',
  },
  ['Image File'] = {
    'FLACPIC:APIC_FILE', 'ID3:APIC_FILE',
  },
}
local METADATA_IMAGE_TYPES = {
  'Other', '32z32 pixel file icon', 'Other file icon', 'Cover (front)',
  'Cover (back)', 'Leaflet page', 'Media', 'Lead artist/Lead performer/Soloist',
  'Artist/Performer', 'Conductor', 'Band/Orchestra', 'Composer',
  'Lyricist/Text Writer', 'Recording Location', 'During recording',
  'During performance', 'Movie/video screen capture', 'A bright colored fish',
  'Illustration', 'Band/Artist logotype', 'Publisher/Studio logotype',
}

local function getScriptInfo()
  local path = select(2, reaper.get_action_context())

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

local function checkTokenCount(file, tokens, expectedMin, expectedMax)
  if not expectedMax then expectedMax = expectedMin end

  if #tokens < expectedMin then
    return false, ('%s: %s contains %d tokens, expected at least %d'):format(
      file, tokens[1], #tokens, expectedMin)
  elseif #tokens > expectedMax then
    return false, ('%s: %s contains %d tokens, expected no more than %d'):format(
      file, tokens[1], #tokens, expectedMax)
  else
    return true
  end
end

local function tokenize(line)
  local pos, tokens = 1, {}

  while pos do
    local tail, eat = nil, 1

    local quote = line:sub(pos, pos)
    if quote == '"' or quote == "'" or quote == '`' then
      pos = pos + 1 -- eat the opening quote
      tail = line:find(quote .. '%s', pos)
      eat = 2

      if not tail then
        if line:sub(-1) == quote then
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

function parseDefault(presets, file, line)
  local tokens = tokenize(line)

  -- reaper-render.ini
  if tokens[1] == '<RENDERPRESET' then
    return parseFormatPreset(presets, file, tokens)
  elseif tokens[1] == '<RENDERPRESET2' then
    return parseFormatPreset2(presets, file, tokens)
  elseif tokens[1] == 'RENDERPRESET_OUTPUT' then
    return parseOutputPreset(presets, file, tokens)
  elseif tokens[1] == 'RENDERPRESET_EXT' then
    return parsePostprocessPreset(presets, file, tokens)
  end

  -- reaper-render2.ini
  if tokens[1] == '<RENDERPRESETMETADATA' then
    return parseMetadataPreset(presets, file, tokens)
  end

  return nil, ('%s: found unknown preset type: %s'):format(file, tokens[1])
end

function parseNodeContents(extractor, defaultParser)
  local function parser(presets, file, line)
    line = line:match('^%s*(.*)$')

    if line:sub(1, 1) == '>' then
      -- reached the end of the XMLRPP tag
      return defaultParser or parseDefault
    end

    local ok, err = extractor(file, line)
    if ok == true then ok = parser end
    return ok, err
  end

  return parser
end

local function propertyExtractor(preset, key)
  return function(file, line)
    preset[key] = (preset[key] or '') .. line
    return true
  end
end

local function addPresetSettings(preset, mask, value)
  preset.RENDER_SETTINGS = (value & mask) | (preset.RENDER_SETTINGS or 0)
  preset._render_settings_mask = mask | (preset._render_settings_mask or 0)
end

function parseFormatPreset(presets, file, tokens)
  local ok, err = checkTokenCount(file, tokens, 8, 9)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  preset.RENDER_SRATE           = tonumber(tokens[3])
  preset.RENDER_CHANNELS        = tonumber(tokens[4])
  preset.projrenderlimit        = tonumber(tokens[5]) -- render speed
  preset.projrenderrateinternal = tonumber(tokens[6]) -- use proj splrate
  preset.projrenderresample     = tonumber(tokens[7])
  preset.RENDER_DITHER          = tonumber(tokens[8])
  preset.RENDER_FORMAT          = '' -- handle duplicate <RENDERPRESET
  preset.RENDER_FORMAT2         = '' -- reset when no <RENDERPRESET2 node exists

  -- Moved from output presets to format presets in v6.0
  -- RENDER_SETTINGS is still shared with Source settings from output presets
  if tokens[9] ~= nil then
    addPresetSettings(preset, SETTINGS_OPTIONS_MASK, tonumber(tokens[9]))
  end

  return parseNodeContents(propertyExtractor(preset, 'RENDER_FORMAT'))
end

function parseFormatPreset2(presets, file, tokens)
  local ok, err = checkTokenCount(file, tokens, 2)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  return parseNodeContents(propertyExtractor(preset, 'RENDER_FORMAT2'))
end

function parseOutputPreset(presets, file, tokens)
  local ok, err = checkTokenCount(file, tokens, 9, 11)
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
  if tokens[10] ~= nil then
    preset.RENDER_FILE = tokens[10] -- v6.43, not accessible via API
  end
  if tokens[11] ~= nil then
    preset.RENDER_TAILMS = tonumber(tokens[11]) -- v6.62
  end

  return parseDefault
end

function parsePostprocessPreset(presets, file, tokens)
  local ok, err = checkTokenCount(file, tokens, 4, 9)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  preset.RENDER_NORMALIZE        = tonumber(tokens[3])
  preset.RENDER_NORMALIZE_TARGET = tonumber(tokens[4])
  if tokens[5] ~= nil then
    preset.RENDER_BRICKWALL = tonumber(tokens[5]) -- v6.37
  end
  if tokens[6] ~= nil then
    preset.RENDER_FADEIN       = tonumber(tokens[6])
    preset.RENDER_FADEOUT      = tonumber(tokens[7])
    preset.RENDER_FADEINSHAPE  = tonumber(tokens[8])
    preset.RENDER_FADEOUTSHAPE = tonumber(tokens[9])
  end

  return parseDefault
end

local function findMetadataTagRoot(search)
  for key, synonyms in pairs(KNOWN_METADATA_TAGS) do
    for i, ident in ipairs(synonyms) do
      if ident == search then return key end
    end
  end

  return search
end

local function addSingleLineMetadata(preset, file, tokens)
  local ok, err = checkTokenCount(file, tokens, 3)
  if not ok then return nil, err end

  preset.metadata[#preset.metadata + 1] =
    { tag = tokens[2], value = tokens[3] }
  return true
end

local function addMultilineMetadata(preset, file, tokens)
  local ok, err = checkTokenCount(file, tokens, 2)
  if not ok then return nil, err end

  local metadata = { tag = tokens[2], value = '', isBase64 = true }
  preset.metadata[#preset.metadata + 1] = metadata

  return parseNodeContents(function(file, line)
    metadata.value = metadata.value .. line
    return true
  end, parseNodeContents(metadataExtractor(preset)))
end

function metadataExtractor(preset)
  return function(file, line)
    if not preset.metadata then preset.metadata = {} end

    local tokens = tokenize(line)

    if tokens[1] == 'TAG' then
      return addSingleLineMetadata(preset, file, tokens)
    elseif tokens[1] == '<TAG' then
      return addMultilineMetadata(preset, file, tokens)
    else
      return nil, ('%s: unknown metadata line: %s'):format(file, tokens[1])
    end
  end
end

function parseMetadataPreset(presets, file, tokens)
  local ok, err = checkTokenCount(file, tokens, 2)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  return parseNodeContents(metadataExtractor(preset))
end

local function readRenderPresets(presets, filename)
  local path = ('%s/%s'):format(reaper.GetResourcePath(), filename)
  if not reaper.file_exists(path) then
    return presets
  end

  local file = assert(io.open(path, 'r'))

  local parser = parseDefault
  for line in file:lines() do
    line = line:match('^(.-)\r*$')
    parser = assert(parser(presets, filename, line))
  end

  file:close()

  assert(parser == parseDefault, ('%s: prematurely reached EOF'):format(filename))
end

local function clearMetadata(project)
  local tags = select(2, reaper.GetSetProjectInfo_String(project, 'RENDER_METADATA', '', false))
  for tag in tags:gmatch('[^;]+') do
    reaper.GetSetProjectInfo_String(project, 'RENDER_METADATA', ('%s|'):format(tag), true)
  end
end

local function applyMetadata(project, tags)
  for i, metadata in ipairs(tags) do
    reaper.GetSetProjectInfo_String(project, 'RENDER_METADATA',
      ('%s|%s'):format(metadata.tag, metadata.value), true)
  end
end

local function applyRenderPreset(project, preset)
  for key, value in pairs(preset) do
    if key:match('^_') or key == 'RENDER_FORMAT' then -- unsupported setting
    elseif key == 'metadata' then
      clearMetadata(project)
      applyMetadata(project, preset.metadata)
    elseif type(value) == 'string' then
      reaper.GetSetProjectInfo_String(project, key, value, true)
    elseif key:match('^[a-z]') then -- lowercase
      reaper.SNM_SetIntConfigVar(key, value)
    else
      local mask = preset[('_%s_mask'):format(key:lower())]
      if mask then
        value = (value & mask) |
          (reaper.GetSetProjectInfo(project, key, 0, false) & ~mask)
      end
      reaper.GetSetProjectInfo(project, key, value, true)
    end
  end

  if preset.RENDER_FORMAT then
    -- workaround for this REAPER bug: https://forum.cockos.com/showthread.php?t=224539
    reaper.GetSetProjectInfo_String(project, 'RENDER_FORMAT', preset.RENDER_FORMAT, true)
  end
end

local function sanitizeFilename(name)
  -- replace special characters that are reserved on Windows
  return name:gsub('[*\\:<>?/|"%c]+', '-')
end

local function createAction(presetName)
  local fnPresetName = sanitizeFilename(presetName)
  local actionName = ('Apply render preset - %s'):format(fnPresetName)
  local outputFn = ('%s/Scripts/%s.lua'):format(
    reaper.GetResourcePath(), actionName)
  local baseName = scriptInfo.path:match('([^/\\]+)$')
  local relPath = scriptInfo.path:sub(reaper.GetResourcePath():len() + 2)

  local code = ([[
-- This file was created by %s on %s

ApplyPresetByName = %q
dofile((%q):format(reaper.GetResourcePath()))
]]):format(baseName, os.date('%c'), presetName, '%s/'..relPath)

  local file = assert(io.open(outputFn, 'w'))
  file:write(code)
  file:close()

  if reaper.AddRemoveReaScript(true, 0, outputFn, true) == 0 then
    reaper.ShowMessageBox(
      'Failed to create or register the new action.', scriptInfo.name, 0)
    return
  end

  reaper.ShowMessageBox(('Created the action "%s".'):format(actionName),
    scriptInfo.name, 0)
end

local function main(presetName, preset)
  if scriptInfo.isCreate then
    createAction(presetName)
  else
    applyRenderPreset(nil, preset)
  end
end

local function gfxdo(callback)
  local app = reaper.GetAppVersion()
  if app:match('OSX') or app:match('linux') then
    return callback()
  end

  local curx, cury = reaper.GetMousePosition()
  gfx.init("", 0, 0, 0, curx, cury)

  if reaper.JS_Window_SetStyle then
    local window = reaper.JS_Window_GetFocus()
    local winx, winy = reaper.JS_Window_ClientToScreen(window, 0, 0)
    gfx.x = gfx.x - (winx - curx)
    gfx.y = gfx.y - (winy - cury)
    reaper.JS_Window_SetStyle(window, "POPUP")
    reaper.JS_Window_SetOpacity(window, 'ALPHA', 0)
  end

  local value = callback()
  gfx.quit()
  return value
end

local function boolText(ctx, bool)
  ImGui.Text(ctx, bool and 'On' or 'Off')
end

local function isCellHovered(ctx)
  -- Call before adding content to the cell.
  -- Uses Selectable so that using IsItemHovered after calling this will
  -- be true over the whole cell.
  local x = ImGui.GetCursorPosX(ctx)
  ImGui.Selectable(ctx, '')
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, x)
  return ImGui.IsItemHovered(ctx)
end

local function enumCell(ctx, values, value)
  if value then
    ImGui.Text(ctx, values[value + 1] or ('Unknown (%d)'):format(value))
  end
end

local function sampleRateCell(ctx, preset)
  if isCellHovered(ctx) and preset.projrenderrateinternal ~= nil and ImGui.BeginTooltip(ctx) then
    ImGui.Checkbox(ctx,
      'Use project sample rate for mixing and FX/synth processing',
      preset.projrenderrateinternal)
    ImGui.EndTooltip(ctx)
  end

  if preset.RENDER_SRATE then
    ImGui.Text(ctx, ('%g kHz'):format(preset.RENDER_SRATE / 1000))
  end
end

local function channelsCell(ctx, preset)
  local channels = { 'Mono', 'Stereo' }
  ImGui.Text(ctx,
    channels[preset.RENDER_CHANNELS] or preset.RENDER_CHANNELS)
end

local function ditherCell(ctx, preset)
  local dither = preset.RENDER_DITHER
  if not dither then return end
  if isCellHovered(ctx) and ImGui.BeginTooltip(ctx) then
    if ImGui.BeginTable(ctx, 'dither', 2) then
      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Dither master', dither, 1)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Dither stems', dither, 4)

      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Noise shape master', dither, 2)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Noise shape stems', dither, 8)
      ImGui.EndTable(ctx)
    end
    ImGui.EndTooltip(ctx)
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

local function postprocessCell(ctx, preset)
  local NORMALIZE_ENABLE    = 1
  local NORMALIZE_TOO_LOUD  = 1<<8
  local NORMALIZE_TOO_QUIET = 1<<11
  local NORMALIZE_MODE_BITS = {5, 12}
  local BRICKWALL_ENABLE    = 1<<6
  -- local BRICKWALL_TPEAK  = 1<<7
  local FADEIN_ENABLE       = 1<<9
  local FADEOUT_ENABLE      = 1<<10

  local postprocess = preset.RENDER_NORMALIZE
  if not postprocess then return end
  if isCellHovered(ctx) and ImGui.BeginTooltip(ctx) then
    if ImGui.BeginTable(ctx, 'normal', 3) then
      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Normalize to:', postprocess, NORMALIZE_ENABLE)
      ImGui.TableNextColumn(ctx)
      enumCell(ctx, { 'LUFS-I', 'RMS', 'Peak', 'True peak' }, (postprocess & 14) >> 1)
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, ('%g dB'):format(VAL2DB(preset.RENDER_NORMALIZE_TARGET)))

      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Brickwall limit:', postprocess, BRICKWALL_ENABLE)
      ImGui.TableNextColumn(ctx)
      enumCell(ctx, { 'Peak', 'True peak' }, (postprocess >> 7) & 1)
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, ('%g dB'):format(VAL2DB(preset.RENDER_BRICKWALL or 1)))

      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Fade-in:', postprocess, FADEIN_ENABLE)
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, ('%g ms'):format(preset.RENDER_FADEIN * 1e4))
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, ('Shape %d'):format(preset.RENDER_FADEINSHAPE))

      ImGui.TableNextRow(ctx)
      ImGui.TableNextColumn(ctx)
      ImGui.CheckboxFlags(ctx, 'Fade-out:', postprocess, FADEOUT_ENABLE)
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, ('%g ms'):format(preset.RENDER_FADEOUT * 1e4))
      ImGui.TableNextColumn(ctx)
      ImGui.Text(ctx, ('Shape %d'):format(preset.RENDER_FADEOUTSHAPE))

      ImGui.EndTable(ctx)
    end
    ImGui.Separator(ctx)

    ImGui.AlignTextToFramePadding(ctx)
    ImGui.Text(ctx, 'Only normalize files that are')
    ImGui.SameLine(ctx)
    ImGui.CheckboxFlags(ctx, 'too loud', postprocess, NORMALIZE_TOO_LOUD)
    ImGui.SameLine(ctx)
    ImGui.CheckboxFlags(ctx, 'too quiet', postprocess, NORMALIZE_TOO_QUIET)

    local mode = 0
    for i, bit in ipairs(NORMALIZE_MODE_BITS) do
      mode = mode | ((postprocess >> bit & 1) << (i - 1))
    end
    local modes =
      'Normalize each file separately\0\z
       Normalize all files to master mix\0\z
       Normalize to loudest file\0\z
       Normalize as if one long file\0'
    ImGui.SetNextItemWidth(ctx, -FLT_MIN)
    ImGui.Combo(ctx, '##mode', mode, modes)

    ImGui.EndTooltip(ctx)
  end

  local enable_mask =
    NORMALIZE_ENABLE | BRICKWALL_ENABLE | FADEIN_ENABLE | FADEOUT_ENABLE
  boolText(ctx, (postprocess & enable_mask) ~= 0)
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
  ImGui.Text(ctx, sources[source] or ('Unknown (%d)'):format(source))
end

local function boundsCell(ctx, preset)
  if not preset.RENDER_BOUNDSFLAG then return end

  local bounds = {
    'Custom time range', 'Entire project', 'Time selection', 'Project regions',
    'Selected media items', 'Selected regions',
  }

  if preset.RENDER_BOUNDSFLAG == 0
      and preset.RENDER_STARTPOS and preset.RENDER_ENDPOS then
    ImGui.Text(ctx, ('%s to %s'):format(
      reaper.format_timestr(preset.RENDER_STARTPOS, ''),
      reaper.format_timestr(preset.RENDER_ENDPOS, '')))
  else
    enumCell(ctx, bounds, preset.RENDER_BOUNDSFLAG)
  end
end

local function optionsCell(ctx, preset)
  if ((preset._render_settings_mask or 0) & SETTINGS_OPTIONS_MASK) == 0 then
    return
  end

  if isCellHovered(ctx) and ImGui.BeginTooltip(ctx) then
    ImGui.CheckboxFlags(ctx, '2nd pass render', preset.RENDER_SETTINGS, 2048)
    ImGui.CheckboxFlags(ctx, 'Tracks with only mono media to mono files',
      preset.RENDER_SETTINGS, 16)
    ImGui.CheckboxFlags(ctx, 'Multichannel tracks to multichannel files',
      preset.RENDER_SETTINGS, 4)
    ImGui.CheckboxFlags(ctx, 'Only render channels that are sent to parent',
      preset.RENDER_SETTINGS, 16384)
    ImGui.CheckboxFlags(ctx, 'Render stems pre-fader',
      preset.RENDER_SETTINGS, 8192)

    ImGui.AlignTextToFramePadding(ctx)
    ImGui.Text(ctx, 'Embed:')
    ImGui.SameLine(ctx)
    ImGui.CheckboxFlags(ctx, 'Metadata', preset.RENDER_SETTINGS, 512)
    ImGui.SameLine(ctx)
    ImGui.CheckboxFlags(ctx, 'Stretch markers/transient guides',
      preset.RENDER_SETTINGS, 256)
    ImGui.SameLine(ctx)
    ImGui.CheckboxFlags(ctx, 'Take markers', preset.RENDER_SETTINGS, 1024)

    ImGui.EndTooltip(ctx)
  end

  ImGui.Bullet(ctx)
end

local function mergeMetadata(tags)
  local merged, indices = {}, {}
  for i, metadata in ipairs(tags) do
    local root = findMetadataTagRoot(metadata.tag)
    local namespace = metadata.tag:match('^[^:]+')
    local value = metadata.value
    if metadata.isBase64 then value = decodeBase64(value) end

    local match = merged[indices[root]]
    if match and match.value == value then
      match.namespaces[#match.namespaces + 1] = namespace
    else
      if match then root = metadata.tag end -- different value
      indices[root] = #merged + 1
      merged[#merged + 1] =
        { tag = root, value = value, namespaces = { namespace } }
    end
  end
  return merged
end

local function ellipsis(text, maxLen)
  text = text:gsub('[\r\n]+', '\x20')
  if text:len() > maxLen then
    return text:sub(1, maxLen) .. '...'
  else
    return text
  end
end

local function metadataCell(ctx, preset)
  if not preset.metadata then return end

  if isCellHovered(ctx) and ImGui.BeginTooltip(ctx) then
    if not preset._metadata_merged then
      preset._metadata_merged = mergeMetadata(preset.metadata)
    end
    local tableFlags = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg
    if ImGui.BeginTable(ctx, 'metadata', 3, tableFlags) then
      ImGui.TableSetupColumn(ctx, 'Tag')
      ImGui.TableSetupColumn(ctx, 'Value')
      ImGui.TableSetupColumn(ctx, 'Namespaces')
      ImGui.TableHeadersRow(ctx)

      for i, metadata in ipairs(preset._metadata_merged) do
        ImGui.TableNextRow(ctx)
        ImGui.TableNextColumn(ctx)
        ImGui.Text(ctx, metadata.tag)
        ImGui.TableNextColumn(ctx)
        if metadata.tag == 'Image Type' then
          enumCell(ctx, METADATA_IMAGE_TYPES, tonumber(metadata.value))
        else
          ImGui.Text(ctx, ellipsis(metadata.value, 64))
        end
        ImGui.TableNextColumn(ctx)
        ImGui.PushTextWrapPos(ctx, ImGui.GetCursorPosX(ctx) + 255)
        ImGui.Text(ctx, table.concat(metadata.namespaces, ', '))
        ImGui.PopTextWrapPos(ctx)
      end

      ImGui.EndTable(ctx)
    end

    ImGui.EndTooltip(ctx)
  end

  ImGui.Bullet(ctx)
end

function decodeBase64(data)
  if reaper.NF_Base64_Decode then
    return select(2, reaper.NF_Base64_Decode(data))
  end

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
    if #data >= 4 then
      data = ('c4'):unpack(data):reverse()
    else
      data = '<invalid>'
    end
    preset._format_cache[key] = data
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
  ImGui.Text(ctx, formats[preset._format_cache[key]] or preset._format_cache[key])
end

local function presetRow(ctx, name, preset)
  ImGui.TableNextColumn(ctx)
  if ImGui.Selectable(ctx, name, false, ImGui.SelectableFlags_SpanAllColumns) then
    main(name, preset)
    ImGui.CloseCurrentPopup(ctx)
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
    postprocessCell,
    sourceCell,
    boundsCell,
    function()
      if not preset.RENDER_TAILFLAG then return end
      boolText(ctx, preset.RENDER_TAILFLAG ~= 0)
      if preset.RENDER_TAILMS then
        ImGui.SameLine(ctx, nil, 0)
        ImGui.Text(ctx, (' (%d ms)'):format(preset.RENDER_TAILMS))
      end
    end,
    'RENDER_FILE',    -- directory
    'RENDER_PATTERN', -- file name
    optionsCell,
    metadataCell,
  }

  for _, cell in ipairs(cells) do
    if ImGui.TableNextColumn(ctx) then
      if type(cell) == 'function' then
        cell(ctx, preset)
      else
        ImGui.Text(ctx, preset[cell])
      end
    end
  end
end

assert(reaper.GetSetProjectInfo,   'REAPER v5.975 or newer is required')
assert(reaper.SNM_SetIntConfigVar, 'The SWS extension is not installed')

local presets = {}
readRenderPresets(presets, 'reaper-render.ini')
readRenderPresets(presets, 'reaper-render2.ini')

if ApplyPresetByName then
  local preset = presets[ApplyPresetByName]
  if preset then
    applyRenderPreset(nil, preset)
  else
    reaper.ShowMessageBox(
      ("Unable to find a render preset named '%s'."):format(ApplyPresetByName),
      scriptInfo.name, 0)
  end
  return
end

local names = {}
for name, preset in pairs(presets) do
  table.insert(names, name)
end
table.sort(names, function(a, b) return a:lower() < b:lower() end)

if not ImGui then
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

local ctx = ImGui.CreateContext(scriptInfo.name, ImGui.ConfigFlags_NavEnableKeyboard)
local clipper = ImGui.CreateListClipper(ctx)
local size = reaper.GetAppVersion():match('OSX') and 12 or 14
local font = ImGui.CreateFont('sans-serif', size)
ImGui.Attach(ctx, font)

local function popup()
  if #names == 0 then
    ImGui.TextDisabled(ctx, 'No render presets found.')
    return
  end

  if scriptInfo.isCreate then
    ImGui.Text(ctx, 'Select a render preset for the new action:')
  else
    ImGui.Text(ctx, 'Select a render preset to apply:')
  end
  ImGui.Spacing(ctx)

  local tableFlags  =
    ImGui.TableFlags_Borders     |
    ImGui.TableFlags_Hideable    |
    ImGui.TableFlags_Reorderable |
    ImGui.TableFlags_Resizable   |
    ImGui.TableFlags_RowBg
  local hiddenColFlags =
    ImGui.TableColumnFlags_DefaultHide

  if not ImGui.BeginTable(ctx, 'Presets', 16, tableFlags) then return end
  ImGui.TableSetupColumn(ctx, 'Name')
  ImGui.TableSetupColumn(ctx, 'Format')
  ImGui.TableSetupColumn(ctx, 'Format (secondary)', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Sample rate')
  ImGui.TableSetupColumn(ctx, 'Channels', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Speed', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Resample mode', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Dither', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Post-processing', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Source', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Bounds', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Tail', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Directory', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'File name', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Options', hiddenColFlags)
  ImGui.TableSetupColumn(ctx, 'Metadata', hiddenColFlags)

  ImGui.TableHeadersRow(ctx)

  ImGui.ListClipper_Begin(clipper, #names)
  while ImGui.ListClipper_Step(clipper) do
    local display_start, display_end = ImGui.ListClipper_GetDisplayRange(clipper)
    for i = display_start + 1, display_end do
      local name = names[i]
      ImGui.TableNextRow(ctx)
      ImGui.PushID(ctx, i)
      presetRow(ctx, name, presets[name])
      ImGui.PopID(ctx)
    end
  end

  ImGui.EndTable(ctx)
end

local function loop()
  if ImGui.IsWindowAppearing(ctx) then
    ImGui.SetNextWindowPos(ctx,
      ImGui.PointConvertNative(ctx, reaper.GetMousePosition()))
    ImGui.OpenPopup(ctx, scriptInfo.name)
  end

  local windowFlags =
    ImGui.WindowFlags_AlwaysAutoResize |
    ImGui.WindowFlags_NoDocking        |
    ImGui.WindowFlags_NoTitleBar       |
    ImGui.WindowFlags_TopMost

  if ImGui.IsPopupOpen(ctx, scriptInfo.name) then
    -- HACK: Dirty trick to force the table to save its settings.
    -- Tables inherit the NoSavedSettings flag from the parent top-level window.
    -- Creating the window first prevents BeginPopup from setting that flag.
    local WindowFlags_Popup = 1 << 26
    if ImGui.Begin(ctx, '##Popup_b362686d', false,
        windowFlags | WindowFlags_Popup) then
      ImGui.End(ctx)
    end
  end

  if ImGui.BeginPopup(ctx, scriptInfo.name, windowFlags) then
    ImGui.PushFont(ctx, font)
    popup()
    ImGui.PopFont(ctx)
    ImGui.EndPopup(ctx)
    reaper.defer(loop)
  end
end

reaper.defer(loop)

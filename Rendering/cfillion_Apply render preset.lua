-- @description Apply render prefix
-- @author cfillion
-- @version 1.0
-- @provides [main] . > cfillion_Apply render preset (create action).lua
-- @link cfillion.ca https://cfillion.ca
-- @donation Donate via PayPal https://paypal.me/cfillion
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
--
--   These settings are NOT applied:
--
--   - Use project sample rate for mixing and FX/synth processing

local function insertPreset(presets, name)
  local preset = presets[name]

  if not preset then
    preset = {}
    presets[name] = preset
  end

  return preset
end

local function checkTokenCount(tokens, expected)
  if #tokens == expected then
    return true
  else
    return false, string.format(
      'reaper-render.ini: %s contains %d tokens, expected %d',
      tokens[1], #tokens, expected
    )
  end
end

local function tokenize(line)
  local pos, tokens = 1, {}

  while pos do
    local tail, eat

    if line:sub(pos, pos) == '"' then
      pos = pos + 1 -- eat the opening quote
      tail = assert(line:find('"%s', pos), 'missing closing quote')
      eat = 2
    else
      tail = line:find('%s', pos)
      eat = 1
    end

    if pos < line:len() then
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
  elseif tokens[1] == 'RENDERPRESET_OUTPUT' then
    return parseOutputPreset(presets, tokens)
  end

  return nil, string.format(
    'reaper-render.ini: found unknown preset type: %s', tokens[1])
end

function parseFormatPreset(presets, tokens)
  local ok, err = checkTokenCount(tokens, 8)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  preset.RENDER_SRATE       = tonumber(tokens[3])
  preset.RENDER_CHANNELS    = tonumber(tokens[4])
  preset.projrenderlimit    = tonumber(tokens[5]) -- render speed
  preset._useProjSRate      = tonumber(tokens[6])
  preset.projrenderresample = tonumber(tokens[7])
  preset.RENDER_DITHER      = tonumber(tokens[8])
  preset.RENDER_FORMAT      = '' -- filled below

  local function parseFormat(_, line)
    if line:sub(1, 1) == '>' then
      -- reached the end of the RENDERPRESET tag
      return parseDefault
    end

    preset.RENDER_FORMAT = preset.RENDER_FORMAT .. line:match('[^%s]+')

    return parseFormat
  end

  return parseFormat
end

function parseOutputPreset(presets, tokens)
  local ok, err = checkTokenCount(tokens, 9)
  if not ok then return nil, err end

  local preset = insertPreset(presets, tokens[2])
  preset.RENDER_BOUNDSFLAG = tonumber(tokens[3])
  preset.RENDER_STARTPOS   = tonumber(tokens[4])
  preset.RENDER_ENDPOS     = tonumber(tokens[5])
  preset.RENDER_SETTINGS   = tonumber(tokens[6]) -- source
  preset._unknown          = tokens[7]           -- what is this (always 0)?
  preset.RENDER_PATTERN    = tostring(tokens[8]) -- file name
  preset.RENDER_TAILFLAG   = tonumber(tokens[9])

  return parseDefault
end

local function getRenderPresets()
  local presets = {}
  local parser = parseDefault

  local path = string.format('%s/reaper-render.ini', reaper.GetResourcePath())
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
    if key:match('^_') then -- unsupported setting
    elseif type(value) == 'string' then
      reaper.GetSetProjectInfo_String(project, key, value, true)
    elseif key:match('^[a-z]') then -- lowercase
      reaper.SNM_SetIntConfigVar(key, value)
    else
      reaper.GetSetProjectInfo(project, key, value, true)
    end
  end
end

local function selectRenderPreset(presets)
  if next(presets) == nil then
    gfx.showmenu('#No render preset found')
    return
  end

  local menu = {}
  for name, preset in pairs(presets) do
    table.insert(menu, name)
  end

  table.sort(menu)
  table.insert(menu, 1, '#Select a render preset:')

  local choice = gfx.showmenu(table.concat(menu, '|'))
  if choice < 2 then return end

  return menu[choice] -- preset name
end

local function createAction(presetName, scriptInfo)
  local actionName = string.format('%s "%s"', scriptInfo.name, presetName)
  local outputFn = string.format('%s/Scripts/%s.lua',
    reaper.GetResourcePath(), actionName)
  local baseName = scriptInfo.path:match('([^/\\]+)$')
  local relPath = scriptInfo.path:sub(reaper.GetResourcePath():len() + 2)
  assert(not relPath:match('%]%]'))

  local code = string.format(
[[-- This file was created by %s on %s

ApplyPresetByName = ({reaper.get_action_context()})[2]:match('"(.+)"%%.lua$')
dofile(string.format(]]..'[[%%s/%s]]'..[[, reaper.GetResourcePath()))
]], baseName, os.date('%c'), relPath)

  local file = assert(io.open(outputFn, 'w'))
  file:write(code)
  file:close()

  if reaper.AddRemoveReaScript(true, 0, outputFn, true) == 0 then
    reaper.ShowMessageBox(
      'Failed to create or register the new action.', scriptInfo.name, 0)
    return
  end

  reaper.ShowMessageBox(
    string.format('Action created: %s', actionName), scriptInfo.name, 0)
end

local function getScriptInfo()
  local path = ({reaper.get_action_context()})[2]

  return {
    path = path,
    name = path:match("([^/\\_]+)%.lua$"),
  }
end

local scriptInfo = getScriptInfo()
local presets = getRenderPresets()
local presetName = ApplyPresetByName or selectRenderPreset(presets)

if presetName then
  if scriptInfo.name:match('create action') then
    createAction(presetName, scriptInfo)
  else
    applyRenderPreset(0, presets[presetName])
  end
elseif ApplyPresetByName then
  reaper.ShowMessageBox(string.format(
    "Unable to find a render preset named '%s'.", scriptInfo.name, 0))
end

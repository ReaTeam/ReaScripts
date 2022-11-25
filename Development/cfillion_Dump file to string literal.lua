-- @description Dump file to string literal
-- @author cfillion
-- @version 1.0

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')
  ('0.7.2')

local BYTES_PER_LINE = 16
local FMT = {
  'local %s =\n "%s"', -- Lua
  '%s =\n  "%s";',     -- EEL
  '%s = \\\n ("%s")'   -- Python
}
local NL = {
  '\\z\n  ', -- Lua
  '"\n  "',  -- EEL
  '"\n  "',  -- Python
}

local file, lang, dump = '', 1, ''
local FLT_MIN, FLT_MAX = reaper.ImGui_NumericLimits_Float()
local scriptName = 'Dump file to string literal'
local ctx = reaper.ImGui_CreateContext(scriptName)

local sans_serif = reaper.ImGui_CreateFont('sans-serif', 13)
local monospace = reaper.ImGui_CreateFont('monospace', 14)
reaper.ImGui_AttachFont(ctx, sans_serif)
reaper.ImGui_AttachFont(ctx, monospace)

local function updateDump()
  if file:len() < 1 then return end
  local f, err = io.open(file, 'rb')
  if err then dump = err return end

  local i = 0
  local data = f:read('*all'):gsub('.', function(byte)
    i = i + 1
    local nl
    if i == BYTES_PER_LINE then
      nl = NL[lang]
      i = 0
    else
      nl = ''
    end
    return ('\\x%02X'):format(string.byte(byte))..nl
  end)

  if i == 0 then
    data = data:sub(1, data:len() - NL[lang]:len())
  end

  local var = file:match('[^/\\]+$'):gsub('[^A-Za-z0-9]', '_')
  dump = (FMT[lang]):format(var, data)
  f:close()
end

local function filePicker()
  reaper.ImGui_PushItemWidth(ctx, -75)
  reaper.ImGui_AlignTextToFramePadding(ctx)
  reaper.ImGui_Text(ctx, 'File:')
  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_InputText(ctx, '##path', file, reaper.ImGui_InputTextFlags_ReadOnly())
  reaper.ImGui_SameLine(ctx)
  if reaper.ImGui_Button(ctx, 'Browse...', -FLT_MIN) then
    local rv, newFile = reaper.JS_Dialog_BrowseForOpenFiles('Select file', '', file, '', false)
    if rv and newFile:len() > 0 then
      file = newFile
      return true
    end
  end
  return false
end
local function langSelect()
  local rv, update
  reaper.ImGui_AlignTextToFramePadding(ctx)
  reaper.ImGui_Text(ctx, 'Language:')
  reaper.ImGui_SameLine(ctx)
  rv, lang = reaper.ImGui_RadioButtonEx(ctx, 'Lua',    lang, 1)
  if rv then update = true end
  reaper.ImGui_SameLine(ctx)
  rv, lang = reaper.ImGui_RadioButtonEx(ctx, 'EEL2',   lang, 2)
  if rv then update = true end
  reaper.ImGui_SameLine(ctx)
  rv, lang = reaper.ImGui_RadioButtonEx(ctx, 'Python', lang, 3)
  if rv then update = true end
  return update
end

local function loop()
  reaper.ImGui_PushFont(ctx, sans_serif)
  reaper.ImGui_SetNextWindowSize(ctx, 600, 600, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctx, scriptName, true)
  if visible then
    if filePicker() then updateDump() end
    if langSelect() then updateDump() end
    reaper.ImGui_Spacing(ctx)

    local avail_w, avail_h = reaper.ImGui_GetContentRegionAvail(ctx)
    reaper.ImGui_PushFont(ctx, monospace)
    reaper.ImGui_BeginDisabled(ctx, dump:len() == 0)
    reaper.ImGui_InputTextMultiline(ctx, '##f', dump, avail_w, avail_h,
      reaper.ImGui_InputTextFlags_ReadOnly())
    reaper.ImGui_EndDisabled(ctx)
    reaper.ImGui_PopFont(ctx)
    reaper.ImGui_End(ctx)
  end
  reaper.ImGui_PopFont(ctx)
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

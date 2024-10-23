-- @noindex

ScriptName = 'az_Trim left, right or both item edges via mouse and razor'

function msg(s) reaper.ShowConsoleMsg(tostring(s)..'\n') end

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  script_path = script_path:gsub('[^/\\]*[/\\]*$','') --one level up
  return script_path
end

local script_path = get_script_path()

local file = script_path .. ScriptName ..'.lua'
local scriptPart = ''
local add

for line in io.lines(file) do
  if line:match('--Start load file') then add = true end
  if add == true then scriptPart = scriptPart ..line ..'\n' end
  if line:match('--End load file') then break end
end
--msg(scriptPart)
local func = load(scriptPart)

if func then
  func()
  ExternalOpen = true
  OptionsWindow()
end

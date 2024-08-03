-- @noindex

ScriptName = 'az_Fade tool (work on context of mouse, razor or time selection)'
GUIName = 'az_Options window for az_Fade tool'

function msg(s) reaper.ShowConsoleMsg(tostring(s)..'\n') end

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  --script_path = script_path:gsub('[^/\\]*[/\\]*$','') --one level up
  return script_path
end

local gui_path = get_script_path()

local gui_file = gui_path .. GUIName ..'.lua'
dofile(gui_file)
--------

local script_path = get_script_path()
script_path = script_path:gsub('[^/\\]*[/\\]*$','') --one level up

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
  
  OptDefaults = {}
  OptionsDefaults(OptDefaults)
  GetExtStates(OptDefaults)
  
  ExternalOpen = true
  OptionsWindow(OptDefaults, 'Fade Tool Options')
end

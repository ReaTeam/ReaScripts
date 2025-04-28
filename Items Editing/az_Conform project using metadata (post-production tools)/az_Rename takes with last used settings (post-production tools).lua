-- @noindex

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  --script_path = script_path:gsub('[^/\\]*[/\\]*$','') --one level up
  return script_path
end

---------------------------

local script_path = get_script_path()
local file = script_path..'az_Conform project_Core.lua'
dofile(file)

--------------START----------------

  local renameStr = reaper.GetExtState(ExtStateName, 'RenameStr')
  if renameStr == '' then renameStr = '@SCENE-T@TAKE_@fieldRecTRACK' end
  
  local noteStr = reaper.GetExtState(ExtStateName, 'NoteStr')
  if noteStr == '' then noteStr = '@NOTE' end
  
  UseTakeMarkerNote = ValToBool( reaper.GetExtState(ExtStateName, 'TakeMarkNote') )
  if UseTakeMarkerNote == nil then UseTakeMarkerNote = true end
  
  local selItems, _ = GetSelItemsPerTrack(true, true)
  RenameTakes(selItems, renameStr, noteStr)

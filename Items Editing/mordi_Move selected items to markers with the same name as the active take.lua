-- @description Move selected items to markers with the same name as the active take
-- @author Mordi
-- @version 1.0
-- @screenshot https://i.imgur.com/fkc8Ley.gif
-- @about Moves each selected item to each marker it finds, in the order of the marker index. If there are more items than markers, the surplus items simply stay put.

SCRIPT_NAME = "Move selected items to markers with the same name as the active take"

reaper.ClearConsole()

function Msg(variable)
  reaper.ShowConsoleMsg(tostring(variable).."\n")
end

function get_selected_items_data()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      t[i].item = item
      
      -- Get active take name
      activeTakeIndex = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
      activeTake = reaper.GetTake(item, activeTakeIndex)
      t[i].name = reaper.GetTakeName(activeTake)
    end
  end
  return t
end

-- ######################################################################

reaper.Undo_BeginBlock()

-- Count markers
retval, marker_count, rgn_count = reaper.CountProjectMarkers(0)

-- Check if any markers exist
if marker_count + rgn_count < 1 then
  reaper.ShowMessageBox("There are no regions or markers in the project", SCRIPT_NAME, 0)
  return
end

-- Store markers info in an array
markers = {}
for i = 0, marker_count+rgn_count-1 do
  retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
  
  if not isrgn then
    markers[i] = {}
    markers[i].name = name
    markers[i].pos = pos
    markers[i].hasBeenUsed = false
  end
end

-- Count selected items
selectedItemNum = reaper.CountSelectedMediaItems(0)
if selectedItemNum == 0 then
  reaper.ShowMessageBox("There are no items selected", SCRIPT_NAME, 0)
  return
end

-- Loop through selected items
data = get_selected_items_data()
for i=1, #data do
  for n = 0, #markers do
    if markers[n].hasBeenUsed == false and markers[n].name == data[i].name then
      -- Move item to marker
      reaper.SetMediaItemInfo_Value(data[i].item, "D_POSITION", markers[n].pos)
      markers[n].hasBeenUsed = true
      break
    end
  end
end

reaper.Undo_EndBlock(SCRIPT_NAME, 0)

-- @description Add project markers as take markers into selected items
-- @author Mordi
-- @version 1.1
-- @changelog Fixed playrate of take not being taken into account. Removed unused line. Thanks to X-Raym.
-- @about Adds project markers into selected items active take.

SCRIPT_NAME = "Add project markers as take markers into selected items"
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
      t[i].startPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      t[i].length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
      t[i].endPos = t[i].startPos + t[i].length
      
      -- Get active take name
      activeTakeIndex = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
      activeTake = reaper.GetTake(item, activeTakeIndex)
      t[i].take = activeTake
      t[i].name = reaper.GetTakeName(activeTake)
      t[i].startOffset = reaper.GetMediaItemTakeInfo_Value(activeTake, "D_STARTOFFS")
      t[i].rate = reaper.GetMediaItemTakeInfo_Value(activeTake, "D_PLAYRATE")
    end
  end
  return t
end

-- Get markers
retval, marker_count, rgn_count = reaper.CountProjectMarkers(0)

-- Check if any markers exist
if marker_count + rgn_count < 1 then
  reaper.ShowMessageBox("There are no regions or markers in the project", SCRIPT_NAME, 0)
  return
end

-- Get project time offset
offset = reaper.GetProjectTimeOffset(0, false)

-- Get selected items data
items = get_selected_items_data()
if #items == 0 then
  return
end

reaper.Undo_BeginBlock()

-- Loop through all markers and regions
for i = 0, marker_count+rgn_count-1 do
  retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers(i)
  if isrgn then goto continue end
  
  -- Loop through selected items
  for n = 1, #items do
    if items[n].startPos < pos and items[n].endPos > pos then
      reaper.SetTakeMarker(items[n].take, -1, name, (pos - items[n].startPos) * items[n].rate + items[n].startOffset)
    end
  end
  
  ::continue::
end

reaper.Undo_EndBlock(SCRIPT_NAME, 0)

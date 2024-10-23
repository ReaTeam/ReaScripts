-- @description Glue items, add take markers and name after first item
-- @author Mordi
-- @version 1.0
-- @changelog Initial version.
-- @about
--   # Glue items, add take markers and name after first item
--
--   This script was made to speed up the process of consolidating an audio library from one-sound-per-file into multiple-sounds-per-file.
--
--   Import your sounds and place them however you'd like. I like to use a script that lines them up with a 100-200 ms gap between each. Select them and run this script, then rename the item. Render the new item and delete the existing single-file sounds from your library.

function log(str)
  reaper.ShowConsoleMsg(str .. "\n")
end

function get_selected_items_data()
  local t={}
  for i=1, reaper.CountSelectedMediaItems(0) do
    t[i] = {}
    local item = reaper.GetSelectedMediaItem(0, i-1)
    if item ~= nil then
      t[i].item = item
      t[i].pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
      
      t[i].take = reaper.GetActiveTake(item)
      retval, t[i].name = reaper.GetSetMediaItemTakeInfo_String(t[i].take, "P_NAME", "", false)
    end
  end
  return t
end

reaper.Undo_BeginBlock()

data = get_selected_items_data()
if #data == 0 then return end

-- Glue
reaper.Main_OnCommand(42432, 0)

gluedItem = reaper.GetSelectedMediaItem(0, 0)
gluedTake = reaper.GetActiveTake(gluedItem)

-- Add take markers
for i=1, #data do
  reaper.SetTakeMarker(gluedTake, -1, "", data[i].pos - data[1].pos)
end

-- Set name
reaper.GetSetMediaItemTakeInfo_String(gluedTake, "P_NAME", data[1].name, true)

reaper.Undo_EndBlock("Consolidate separate items, add take markers and name after first", 0)

-- @noindex

-- @description Set Subprojects in Selected Items to Color...
-- @author Aaron Cendan
-- @version 1.0
-- @link https://aaroncendan.me
-- @about
--   # Set Subprojects in Selected Items Color
--   By Aaron Cendan - June 2020
--
--   ### General Info
--   * Sets color of all subprojects in selected items based on criteria in script name
--   * Can easily be combined with "Item: Select all items" to affect all subprojects in current project
--
--   ### Requirements
--   * SWS Extension: https://www.sws-extension.org/

-- Set subproject item color
local function setSubProjItemsColor(filename, track, item)
  reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
  reaper.SetMediaItemSelected( item, true )

  if not custom_color_set then
    reaper.Main_OnCommand(40704, 0) --Set item to one random color
    custom_color_set = true
    selected_color = reaper.GetMediaItemInfo_Value( item, "I_CUSTOMCOLOR" )
  else
    reaper.SetMediaItemInfo_Value( item, "I_CUSTOMCOLOR", selected_color )
  end

  reaper.UpdateArrange()
end

-- Save item selection
function saveSelectedItems (table)
  for i = 1, reaper.CountSelectedMediaItems(0) do
    table[i] = reaper.GetSelectedMediaItem(0, i-1)
  end
end

-- Restore item selection
function restoreSelectedItems(table)
  for i = 1, tableLength(table) do
    reaper.SetMediaItemSelected( table[i], true )
  end
end

-- Get table length
function tableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Get file name of active take
local function getFilenameTrackActiveTake(item)
  if item ~= nil then
    local tk = reaper.GetActiveTake(item)
    if tk ~= nil then
      local pcm_source = reaper.GetMediaItemTake_Source(tk)
      local filenamebuf = ""
      filenamebuf = reaper.GetMediaSourceFileName(pcm_source, filenamebuf)
      local track = reaper.GetMediaItemTrack(item)
      return filenamebuf, track
    end
  end
  return nil, nil
end

-- Get three character extension on filename
local function getFileExtension(filename)
  return filename:sub(-3):upper()
end

-- Main - filter out subprojects in selected items
local function main()
  local at_least_one_subproj = false
  for i, item in ipairs( init_sel_items ) do
    local filename, track = getFilenameTrackActiveTake(item)
    if filename ~= nil then
      if getFileExtension(filename) == "RPP" then
        setSubProjItemsColor(filename, track, item)
        at_least_one_subproj = true
      end
    end
  end
  if not at_least_one_subproj then reaper.MB("No subprojects in selected items!","Set Subproject Color",0) end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
reaper.ClearConsole()
init_sel_items = {}
custom_color_set = false
saveSelectedItems( init_sel_items )
main()
restoreSelectedItems( init_sel_items )
reaper.Undo_EndBlock("Set selected subproject colors",-1)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

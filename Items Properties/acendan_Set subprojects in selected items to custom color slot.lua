-- @description Set color of subprojects in selected items
-- @author Aaron Cendan
-- @version 1.0
-- @metapackage
-- @provides
--   [main] . > acendan_Set subprojects in selected items to custom color slot 1.lua
--   [main] . > acendan_Set subprojects in selected items to custom color slot 2.lua
--   [main] . > acendan_Set subprojects in selected items to custom color slot 3.lua
--   [main] . > acendan_Set subprojects in selected items to custom color slot 4.lua
--   [main] . > acendan_Set subprojects in selected items to custom color slot 5.lua
--   [main] . > acendan_Set subprojects in selected items to custom color slot 6.lua
--   [main] . > acendan_Set subprojects in selected items to custom color slot 7.lua
--   [main] . > acendan_Set subprojects in selected items to custom color slot 8.lua
--   [main] acendan_Set subprojects in selected items to custom color slot/acendan_Set subprojects in selected items to random colors.lua
--   [main] acendan_Set subprojects in selected items to custom color slot/acendan_Set subprojects in selected items to random custom colors.lua
--   [main] acendan_Set subprojects in selected items to custom color slot/acendan_Set subprojects in selected items to color.lua
-- @link https://aaroncendan.me
-- @about
--   # Set Color of Subprojects in Selected Items
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
  local slot_number = extractNumberInScriptName() --Get custom color slot from script name
  local set_color_action = reaper.NamedCommandLookup( "_SWS_ITEMCUSTCOL" .. slot_number ) --Set item to custom color slot
  reaper.Main_OnCommand(set_color_action, 0)

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

-- Get number from script name
function extractNumberInScriptName()
  local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")
  return tonumber(string.match(script_name, "%d+"))
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
saveSelectedItems( init_sel_items )
main()
restoreSelectedItems( init_sel_items )
reaper.Undo_EndBlock("Set selected subproject colors",-1)
reaper.UpdateArrange()
reaper.PreventUIRefresh(-1)

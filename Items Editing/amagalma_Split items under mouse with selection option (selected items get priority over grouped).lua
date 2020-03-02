-- @description amagalma_Split items under mouse with selection option (selected items get priority over grouped)
-- @author amagalma
-- @version 1.0
-- @about
--   # Splits item(s) under mouse cursor and all relevant grouped items
--   - If there are selected items, they get priority over grouped items (only the selected ones will be split)
--   - You can specify in the script if you want a change of selection by selecting left or right slpit items or not
--   - Smart undo point creation

--[[
 @changelog
 * v1.0 (2020-02-03)
  + replaces "amagalma_Split selected or grouped items at mouse cursor (with selection option).lua"
--]]

-----------------------------------------------------------------------------------------------------


-- USER SETTINGS -- 0: no change,  1: select left,  2: select right --
local selection = 2                                                 --
----------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------

local reaper = reaper
local item, pos = reaper.BR_ItemAtMouseCursor()
if not item then return reaper.defer(function () end) end

-- Load relevant commands to user settings
local restore_selected = false
local cmd_mouse, cmd_cursor
if selection == 1 then
  cmd_mouse = 40747 -- Split item under mouse cursor (select left)
  cmd_cursor = 40758 -- Split items at edit cursor (select left)
elseif selection == 2 then
  cmd_mouse = 40748 -- Split item under mouse cursor (select right)
  cmd_cursor = 40759 -- Split items at edit cursor (select right)
else
  cmd_mouse = 40746 -- Split item under mouse cursor
  cmd_cursor = 40757 -- Split items at edit cursor (no change selection)
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
local cursor = reaper.GetCursorPosition()
local item_group = reaper.GetMediaItemInfo_Value(item, "I_GROUPID")
local undoMsg = ""
local all_selected, selected, grouped = {}, {}, {}
local item_cnt = reaper.CountMediaItems(0)
-- find relative items to position, selection and grouping
for i = 0, item_cnt - 1 do
  local it = reaper.GetMediaItem(0, i)
  local group_it = reaper.GetMediaItemInfo_Value(it, "I_GROUPID")
  -- table for restoring item selection if needed
  if reaper.IsMediaItemSelected( it ) then
    all_selected[#all_selected+1] = it
  end
  -- put relative items in appropriate tables
  local Start = reaper.GetMediaItemInfo_Value(it, "D_POSITION")
  local End = Start + reaper.GetMediaItemInfo_Value(it, "D_LENGTH")
  if Start < pos and End > pos then
    if item_group ~= 0 and group_it == item_group then
      grouped[#grouped+1] = it
    end
    if reaper.IsMediaItemSelected( it ) then
      selected[#selected+1] = it
    end
  end
end

-- Main function
if #selected == 0 then -- no selected items
  if #grouped == 0 then -- single item, unselected, not grouped
    reaper.Main_OnCommand(cmd_mouse, 0) 
    undoMsg = "Split item under mouse"
  else -- not selected, grouped
    reaper.SelectAllMediaItems( 0, false )
    reaper.SetMediaItemSelected( item, true )
    reaper.Main_OnCommand(40034, 0) -- Item grouping: Select all items in groups
    reaper.SetEditCurPos( pos, false, false )
    reaper.Main_OnCommand(cmd_cursor, 0)
    undoMsg = "Split grouped items under mouse"
    if selection == 0 then
      restore_selected = true
    end
  end
else -- split selected items
  reaper.SetEditCurPos( pos, false, false )
  reaper.Main_OnCommand(40186, 0) -- Item: Split items at edit or play cursor (ignoring grouping)
  undoMsg = "Split selected item" .. (#selected > 1 and "s" or "") .. " under mouse"
  if selection == 1 then
    restore_selected = true
  end
end

-- restore item selection and cursor position
if restore_selected then
  reaper.SelectAllMediaItems( 0, false )
  for i = 1, #all_selected do
    reaper.SetMediaItemSelected( all_selected[i], true )
  end
end
reaper.SetEditCurPos( cursor, false, false )

-- Update Arrange and Undo
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock2( 0, undoMsg, 4 )

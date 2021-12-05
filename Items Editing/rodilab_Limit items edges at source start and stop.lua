-- @description Limit items edges at source start and stop
-- @author Rodilab
-- @version 1.0
-- @about
--   This is a togglable defer script.
--   As long is activate : dragging the items edges can't expand audio items beyond source media start and end.
--
--   Requirement :
--   - SWS Extension
--   - js_ReaScriptAPI: API functions
--
--   by Rodrigo Diaz (aka Rodilab)

---------------------------------------
-- Debug
---------------------------------------
function Debug()
  local debug = false
  local debug_str = ''
  if reaper.APIExists('CF_GetSWSVersion') == false then
    debug_str = "\"SWS extension\" : https://www.sws-extension.org\n"
    debug = true
  end
  if reaper.APIExists('JS_ReaScriptAPI_Version') == false then
    local ReaPack_exist = reaper.APIExists('ReaPack_BrowsePackages')
    if ReaPack_exist == true then
      reaper.ReaPack_BrowsePackages('js_ReaScriptAPI: API functions for ReaScripts')
    end
    debug_str = debug_str.."\"js_ReaScriptAPI: API functions for ReaScripts\" with ReaPack and restart Reaper\n"
    debug = true
  end
  if debug then
    reaper.ShowMessageBox('Please install :\n'..debug_str, 'Error', 0)
    return false
  else
    return true
  end
end

---------------------------------------
-- Global variables
---------------------------------------
is_clicking = false
item, is_edge = nil
last_left_click = 0
item_list, edge_pos_list = {}

---------------------------------------
-- Functions
---------------------------------------
function ToggleThisScript(state)
  local is_new_value, filename, section_id, command_id = reaper.get_action_context()
  reaper.SetToggleCommandState(section_id, command_id, state)
  reaper.RefreshToolbar2(section_id, command_id)
end

function IsEdge(item)
  local cursor_pos = reaper.BR_PositionAtMouseCursor(false)
  local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
  local zoom = reaper.GetHZoomLevel()
  if cursor_pos >= pos and cursor_pos <= (pos + 7/zoom) then
    return 1
  elseif cursor_pos <= pos+length and cursor_pos >= (pos+length)-8/zoom then
    return 2
  end
  return nil
end

function GetItemList(item)
  local item_list = {}
  local edge_pos_list = {}
  if reaper.IsMediaItemSelected(item) then
    local count = reaper.CountSelectedMediaItems(0)
    for i=0, count-1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      if reaper.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 0 then
        table.insert(item_list, item)
      end
    end
  else
    if reaper.GetMediaItemInfo_Value(item, 'B_LOOPSRC') == 0 then
      table.insert(item_list, item)
    end
  end
  for i, item in ipairs(item_list) do
    local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    if is_edge == 1 then
      table.insert(edge_pos_list, pos)
    elseif is_edge == 2 then
      length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      table.insert(edge_pos_list, pos+length)
    end
  end
  return item_list, edge_pos_list
end

function GetGroupedItems(item)
  local list = {}
  local group = reaper.GetMediaItemInfo_Value(item, 'I_GROUPID')
  if group > 0 then
    local count = reaper.CountMediaItems(0)
    for i=0, count-1 do
      local group_item = reaper.GetMediaItem(0, i)
      if group_item ~= item and group == reaper.GetMediaItemInfo_Value(group_item, 'I_GROUPID') then
        table.insert(list, group_item)
      end
    end
  end
  return list
end

function TrimOversizedEdge(item, edge)
local take = reaper.GetActiveTake(item)
  if take then
    local source = reaper.GetMediaItemTake_Source(take)
    local samplerate = reaper.GetMediaSourceSampleRate(source)
    if samplerate > 0 then
      local position = reaper.GetMediaItemInfo_Value(item,"D_POSITION")
      local length = reaper.GetMediaItemInfo_Value(item,"D_LENGTH")
      local playrate = reaper.GetMediaItemTakeInfo_Value(take,"D_PLAYRATE")
      local startoffs = reaper.GetMediaItemTakeInfo_Value(take,"D_STARTOFFS")/playrate
      local source_length, lengthIsQN = reaper.GetMediaSourceLength(source)
      if lengthIsQN == true then return end
      local source_length = source_length/playrate
      local group_list = GetGroupedItems(item)
      local cut
      if edge == 1 and startoffs < 0 then
        -- Trim left edge to cursor
        cut = position-startoffs
        local new_item = reaper.SplitMediaItem(item, cut)
        reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
      elseif edge == 2 and length+startoffs > source_length then
        -- Trim right edge to cursor
        cut = position-startoffs+source_length
        local new_item = reaper.SplitMediaItem(item, cut)
        reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(new_item), new_item)
      end
      if #group_list > 0 then
        for i, item in ipairs(group_list) do
          local new_item = reaper.SplitMediaItem(item, cut)
          if edge == 1 then
            reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
          elseif edge == 2 then
            reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(new_item), new_item)
          end
        end
      end
    end
  end
end

reaper.atexit(function()
  ToggleThisScript(0)
end)

---------------------------------------
-- Main Loop
---------------------------------------
function loop()
  local left_click = reaper.JS_Mouse_GetState(1)
  if not is_clicking and last_left_click == 0 and left_click == 1 then
    local x, y = reaper.GetMousePosition() 
    local rv, info = reaper.GetThingFromPoint(x, y)
    if rv and info == 'arrange' then
      item = reaper.GetItemFromPoint(x, y, false)
      if item then
        is_edge = IsEdge(item)
      else
        item = reaper.GetItemFromPoint(x-4, y, false)
        is_edge = 2
        if not item then
          item = reaper.GetItemFromPoint(x+4, y, false)
          is_edge = 1
        end
      end
      if item and is_edge then
        is_clicking = true
        item_list, edge_pos_list = GetItemList(item)
      else
        item, is_edge = nil
        item_list, edge_pos_list = {}
      end
    end
  elseif is_clicking and left_click == 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    for i, item in ipairs(item_list) do
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      if (is_edge == 1 and pos ~= edge_pos_list[i]) or (is_edge == 2 and pos+length ~= edge_pos_list[i]) then
        TrimOversizedEdge(item, is_edge)
      end
    end
    reaper.Undo_EndBlock("Limit items edges at source start and stop",0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    is_clicking = false
    item, is_edge = nil
    item_list, edge_pos_list = {}
  end
  last_left_click = left_click
  reaper.defer(loop)
end

---------------------------------------
-- Start
---------------------------------------
if Debug() then
  ToggleThisScript(1)
  reaper.defer(loop)
end

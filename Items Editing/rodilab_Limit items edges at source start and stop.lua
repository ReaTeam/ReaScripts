-- @description Limit items edges at source start and stop
-- @author Rodilab
-- @version 1.1
-- @changelog
--   This version works in a very different way.
--   Now works with crossfades, double adjacent edges and "move item contents".
-- @about
--   This is a togglable defer script.
--   As long is enable : dragging items edges can't expand audio items beyond source media start and end.
--
--   Requirement :
--   - js_ReaScriptAPI: API functions
--
--   by Rodrigo Diaz (aka Rodilab)

---------------------------------------
-- Debug
---------------------------------------

function Debug()
  if reaper.APIExists('JS_ReaScriptAPI_Version') then
    return true
  else
    if reaper.APIExists('ReaPack_BrowsePackages') then
      reaper.ReaPack_BrowsePackages('js_ReaScriptAPI: API functions for ReaScripts')
    end
    reaper.ShowMessageBox('Please install \"js_ReaScriptAPI: API functions for ReaScripts\" and restart Reaper', 'Error', 0)
    return false
  end
end

---------------------------------------
-- Global variables
---------------------------------------

OS_Mac = string.match(reaper.GetOS(),"OSX")
is_clicking = false
last_left_click = 0
local reaper_cursors = {
                        {417,'EDGE L'},
                        {418,'EDGE R'},
                        {450,'EDGE DOUBLE'},
                        {105,'FADE L'},
                        {184,'FADE R'},
                        {463,'FADE MOVE'},
                        {528,'FADE LENGTH'},
                        {465,'MOVE CONTENT'}
                       }

---------------------------------------
-- Functions
---------------------------------------

function Msg(str)
  reaper.ShowConsoleMsg(tostring(str)..'\n')
end

function ToggleThisScript(state)
  local is_new_value, filename, section_id, command_id = reaper.get_action_context()
  reaper.SetToggleCommandState(section_id, command_id, state)
  reaper.RefreshToolbar2(section_id, command_id)
end

function MouseCursor()
  local cur_cursor = reaper.JS_Mouse_GetCursor()
  for i = 1, #reaper_cursors do
    local cursor = reaper.JS_Mouse_LoadCursor(reaper_cursors[i][1])
    if cur_cursor == cursor then
      return reaper_cursors[i][2]
    end
  end
  return nil
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
      if (edge == 'left' or edge == 'content') and startoffs < 0 then
        reaper.SetEditCurPos(position-startoffs, false, false)
        reaper.SelectAllMediaItems(0, false)
        reaper.SetMediaItemSelected(item, true)
        reaper.Main_OnCommand(41305, 0) -- Item edit: Trim left edge of item to edit cursor
      end
      if (edge == 'right' or edge == 'content') and length+startoffs > source_length then
        reaper.SetEditCurPos(position-startoffs+source_length, false, false)
        reaper.SelectAllMediaItems(0, false)
        reaper.SetMediaItemSelected(item, true)
        reaper.Main_OnCommand(41311, 0) -- Item edit: Trim right edge of item to edit cursor
      end
    end
  end
end

function GetSelectedItems()
  local list = {}
  local count = reaper.CountSelectedMediaItems(0)
  if count > 0 then
    for i=0, count-1 do
      local item = reaper.GetSelectedMediaItem(0, i)
      table.insert(list, item)
    end
  end
  return list
end

function SelectListItems(list)
  reaper.SelectAllMediaItems(0, false)
  for i, item in ipairs(list) do
    reaper.SetMediaItemSelected(item, true)
  end
end

function GetAllItemsFromPoint(x, y, MC)
  local rv, left, top = reaper.JS_Window_GetClientRect(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000))
  if not rv then return end
  local cur_pos = reaper.GetSet_ArrangeView2(0, false, x, x+1)
  local track, info = reaper.GetTrackFromPoint(x, y)
  if track and info == 0 then
    local count = reaper.CountTrackMediaItems(track)
    if count > 0 then
      local track_y = reaper.GetMediaTrackInfo_Value(track, 'I_TCPY')
      local y2
      if OS_Mac then
        y2 = top-y
      else
        y2 = y-top
      end
      local zoom = reaper.GetHZoomLevel()
      local list = {}
      local is_selected = false
      for i=0, count-1 do
        local match = false
        local edge
        local item = reaper.GetTrackMediaItem(track, i)
        local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local fade_in =  reaper.GetMediaItemInfo_Value(item, 'D_FADEINLEN_AUTO')
        local fade_out =  reaper.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN_AUTO')
        if pos-9/zoom > cur_pos then break end
        if reaper.GetMediaItemInfo_Value(item, 'C_LOCK') == 0 then
          if (MC == 'EDGE L' and cur_pos >= pos-4/zoom and cur_pos <= pos+8/zoom)
          or (MC == 'FADE R' and fade_in  > 0 and cur_pos >= pos-8/zoom and cur_pos < pos+fade_in)
          or (MC == 'EDGE DOUBLE' and cur_pos >= pos-4/zoom and cur_pos <= pos+4/zoom)
          or ((MC == 'FADE MOVE' or MC == 'FADE LENGTH') and fade_in > 0 and cur_pos > pos and cur_pos < pos+fade_in) then
            edge = 'left'
          elseif (MC == 'EDGE R' and cur_pos >= pos+length-8/zoom and cur_pos <= pos+length+4/zoom)
          or (MC == 'FADE L' and fade_out > 0 and cur_pos > pos+length-fade_out and cur_pos <= pos+length+8/zoom)
          or (MC == 'EDGE DOUBLE' and cur_pos >= pos+length-4/zoom and cur_pos <= pos+length+4/zoom)
          or ((MC == 'FADE MOVE' or MC == 'FADE LENGTH') and fade_out > 0 and cur_pos > pos+length-fade_out and cur_pos < pos+length) then
            edge = 'right'
          elseif MC == 'MOVE CONTENT' and cur_pos > pos and cur_pos < pos+length then
            edge = 'content'
          end
          if edge then
            lasty = reaper.GetMediaItemInfo_Value(item, 'I_LASTY')
            lasth = reaper.GetMediaItemInfo_Value(item, 'I_LASTH')
            if y2 >= track_y+lasty and y2 <= track_y+lasty+lasth then
              if (MC == 'EDGE L' or MC == 'EDGE R' or MC == 'MOVE CONTENT') and not is_selected and reaper.IsMediaItemSelected(item) then
                is_selected = true
              end
              local edge_pos
              if edge == 'left' then
                edge_pos = pos
              elseif edge == 'right' then
                edge_pos = pos+length
              elseif edge == 'content' then
                edge_pos = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), 'D_STARTOFFS')
              end
              table.insert(list, {item, edge, edge_pos})
            end
          end
        end
      end
      if #list > 0 then
        return true, list, is_selected
      end
    end
  end
  return false
end

function AddSelItems(MC)
  local count = reaper.CountSelectedMediaItems(0)
  local tmp_item_list = {}
  for i=1, #item_list do
    tmp_item_list[item_list[i][1]] = true
  end
  for i=0, count-1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    if not tmp_item_list[item] then
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      local edge, edge_pos
      if MC == 'EDGE L' then
        edge = 'left'
        edge_pos = pos
      elseif MC == 'EDGE R' then
        edge = 'right'
        edge_pos = pos+length
      elseif MC == 'MOVE CONTENT' then
        edge = 'content'
        edge_pos = reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), 'D_STARTOFFS')
      end
      table.insert(item_list, {item, edge, edge_pos})
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
      local track, info = reaper.GetTrackFromPoint(x, y)
      if info == 0 then
        local MC = MouseCursor()
        if MC then
          is_clicking, item_list, is_selected = GetAllItemsFromPoint(x, y, MC)
          if is_selected then
            AddSelItems(MC)
          end
        end
      end
    end
  elseif is_clicking and left_click == 0 then
    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)
    local selected_items = GetSelectedItems()
    for i, list in ipairs(item_list) do
      local item = list[1]
      local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
      local length = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
      if (list[2] == 'left'    and list[3] ~= pos)
      or (list[2] == 'right'   and list[3] ~= pos+length)
      or (list[2] == 'content' and list[3] ~= reaper.GetMediaItemTakeInfo_Value(reaper.GetActiveTake(item), 'D_STARTOFFS')) then
        TrimOversizedEdge(item, list[2])
      end
    end
    SelectListItems(selected_items)
    reaper.Undo_EndBlock("Limit items edges at source start and stop",0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    is_clicking = false
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

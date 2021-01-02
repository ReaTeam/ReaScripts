-- @version 0.2
-- @author spk77
-- @changelog
--   Script now accounts for projects with a time offset
-- @description Export item names and time stamps to a text file
-- @website
--   Forum Thread http://forum.cockos.com/showthread.php?t=180003
-- @about
--   # Export item names and time stamps to a text file
--
--   This script creates a text file from selected items.
--
--   ## Main Features
--   - "exports" item names and positions 
--   - new file is created into script folder
--   - created file name is "Exported item list.txt"

local file_name = "Exported item list.txt"

function msg(m)
  reaper.ShowConsoleMsg(tostring(m) .. "\n")
end

------------------------------------------------------------------------------
-- "Get script path" function
------------------------------------------------------------------------------
function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end


sort_func = function(a,b) -- https://forums.coronalabs.com/topic/37595-nested-sorting-on-multi-dimensional-array/
              if (a.pos < b.pos) then
                -- primary sort on length -> a before b
                return true
              --[[
              elseif (a.len > b.len) then
                -- primary sort on length -> b before a
                return false
              else
                -- primary sort tied, resolve w secondary sort on position
                return a.position < b.position
              --]]
              end
            end


function get_items()
  local t = {}
  local num_items = reaper.CountSelectedMediaItems(tr)
  if num_items == 0 then
    return false, t
  end
  for i_i=1, num_items do
    local item = reaper.GetSelectedMediaItem(tr, i_i-1)
    if item == nil then
      goto continue_item
    end
    local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetProjectTimeOffset(tr, false)
    local take = reaper.GetActiveTake(item)
    if take ~= nil then
      t[#t+1] = {}
      local take_name = reaper.GetTakeName(take)
      t[#t].take_name = take_name
      local pos_str= reaper.format_timestr(pos, "")
      reaper.parse_timestr_pos("pos", 1)
      t[#t].pos = pos_str
    end
    ::continue_item::
  end
  return true, t 
end


local ret, data = get_items()
if ret and #data > 0 then
  table.sort(data, sort_func)
  local s = ""
  for i=1, #data do
    s = s .. data[i].pos .. "\t" .. data[i].take_name .. "\n"
  end
  reaper.ClearConsole()
  --msg(s)
  local sep = "/"
  if reaper.GetOS() == "Win32" or reaper.GetOS() == "Win64" then
    sep = "\\"
  end
  local path = get_script_path() .. sep .. file_name
  local file = io.open(path, "w+")
  file:write(s)
  io.close(file)
end

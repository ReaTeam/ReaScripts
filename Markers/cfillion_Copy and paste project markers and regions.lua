-- @description Copy/paste project markers and/or regions
-- @version 1.1.1
-- @changelog
--   Fix markers being copied past the end of the time selection [p=1942313]
--   Renumber markers and regions when pasting
-- @author cfillion
-- @links
--   cfillion.ca https://cfillion.ca/
--   Request Thread https://forum.cockos.com/showthread.php?t=201983
-- @screenshots
--   Basic usage https://i.imgur.com/dSyRnKe.gif
--   Paste at edit cursor https://i.imgur.com/Zdu5VIF.gif
-- @donate https://www.paypal.com/cgi-bin/webscr?business=T3DEWBQJAV7WL&cmd=_donations&currency_code=CAD&item_name=ReaScript%3A+Set+item+playback+rate+from+semitones
-- @provides
--   . > cfillion_Copy project markers and regions in time selection.lua
--   . > cfillion_Copy project markers in time selection.lua
--   . > cfillion_Copy project regions in time selection.lua
--   . > cfillion_Paste project markers and regions.lua
--   . > cfillion_Paste project markers and regions at edit cursor.lua
-- @about
--   This script provides actions to copy and paste project markers and/or
--   regions in the time selection. All markers and/or regions in the project
--   are copied if no time selection is set. The IDs are automatically
--   incremented when pasting.
--
--   - Copy project markers and regions in time selection
--   - Copy project markers in time selection
--   - Copy project regions in time selection
--   - Paste project markers and regions
--   - Paste project markers and regions at edit cursor

local UNDO_STATE_MISCCFG = 8
local EXT_SECTION = 'cfillion_copy_paste_markers'

local script_name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)%.lua$")

function copy()
  clear()

  local n = 0
  for i=0, reaper.CountProjectMarkers(0)-1 do
    local marker = {reaper.EnumProjectMarkers3(0, i)}
    table.remove(marker, 1)

    -- boolean isrgn, number pos, number rgnend, string name, number markrgnindexnumber, number color

    if testType(marker[1]) and testPos(marker[2], marker[3]) then
      n = n + 1
      reaper.SetExtState(EXT_SECTION, makeKey(n), serialize(marker), false)
    end
  end
end

function paste()
  local markers = readClipboard()
  local relative, offset = script_name:match('at edit cursor')
  local _, markerId, regionId = reaper.CountProjectMarkers(0)

  if #markers < 1 then
    reaper.MB("Marker clipboard is empty!", script_name, 0)
    return
  end

  reaper.Undo_BeginBlock()

  for i, marker in ipairs(markers) do
    -- paste at edit cursor
    if relative then
      if not offset then
        offset = marker[2] - reaper.GetCursorPosition()
      end

      marker[2] = marker[2] - offset

      if marker[1] then -- move the region end
        marker[3] = marker[3] - offset
      end
    end

    -- renumber the requested index
    if marker[1] then
      regionId = regionId + 1
      marker[5] = regionId
    else
      markerId = markerId + 1
      marker[5] = markerId
    end

    reaper.AddProjectMarker2(0, table.unpack(marker))
  end

  reaper.Undo_EndBlock(script_name, UNDO_STATE_MISCCFG)
end

function clear()
  for key in clipboardIterator() do
    reaper.DeleteExtState(EXT_SECTION, key, false)
  end
end

function makeKey(i)
  return string.format("marker%03d", i)
end

function clipboardIterator()
  local i = 0
  return function()
    i = i + 1

    local key = makeKey(i)

    if reaper.HasExtState(EXT_SECTION, key) then
      return key
    end
  end
end

function serialize(tbl)
  local str = ''

  for _, value in ipairs(tbl) do
    str = str .. type(value) .. '\31' .. tostring(value) .. '\30'
  end

  return str
end

function unserialize(str)
  local type_map = {
    string  = tostring,
    number  = tonumber,
    boolean = function(v) return v == 'true' and true or false end,
  }

  local tbl = {}

  for type, value in str:gmatch('(.-)\31(.-)\30') do
    if not type_map[type] then
      error(string.format("unsupported value type: %s", type))
    end

    table.insert(tbl, type_map[type](value))
  end

  return tbl
end

function readClipboard()
  local markers = {}

  for key in clipboardIterator() do
    table.insert(markers, unserialize(reaper.GetExtState(EXT_SECTION, key)))
  end

  return markers
end

function testType(isrgn)
  return script_name:match(isrgn and 'region' or 'marker')
end

function testPos(startpos, endpos)
  local tstart, tend = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)

  if endpos == 0 then
    endpos = startpos
  end

  return startpos >= tstart and (tend == 0 or endpos <= tend)
end

(script_name:match('Copy') and copy or paste)()
reaper.defer(function() end) -- disable automatic undo point

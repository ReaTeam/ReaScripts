-- @description Change Take Volume (insert 4 points) for selected items (or selected take vol env) in time selection by set amount (up)
-- @author amagalma
-- @version 1.01
-- @changelog Fix: now works with items with multiple takes too
-- @link https://forum.cockos.com/showthread.php?t=242569
-- @screenshot https://i.ibb.co/K5qdpZ3/amagalma-Change-Take-Volume-insert-4-points-for-selected-items-or-selected-take-vol-env-in-time-sele.gif
-- @donation https://www.paypal.me/amagalma
-- @about
--   Raises the Take Volume for selected items (or selected take vol env if no items are selected) in time selection by a set amount.
--
--   - Inserts 4 envelope points if needed
--   - Shows Take Volume envelope if not already visible
--   - Raises all existing envelope points in time selection by set amount
--   - Amount of volume change and transition duration can be set with additional Settings script (default values: 3dB and 3ms)
--   - Smart undo

local ST, EN = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 )
if ST == EN then return end

local item_cnt = reaper.CountSelectedMediaItems( 0 )
local items = {}
if item_cnt == 0 then
  local sel_env = reaper.GetSelectedEnvelope( 0 )
  if not sel_env then return end
  local take, index, index2 = reaper.Envelope_GetParentTake( sel_env )
  local _, name = reaper.GetEnvelopeName( sel_env )
  if not take or not (index == -1 and index2 == -1) or name ~= "Volume" then return end
  items[1] = {reaper.GetMediaItemTake_Item( take ), take}
else
  local s = 0
  for i = 0, item_cnt-1 do
    local item = reaper.GetSelectedMediaItem( 0, i )
    local take = reaper.GetActiveTake( item )
    if take then
      s = s + 1
      items[s] = {item, take}
    end
  end
end

local function eq( a, b )
  return math.abs( a - b ) < 0.00001
end

local change = (tonumber(reaper.GetExtState( "amagalma_Take_Vol_in_TS", "change" )) or 3)
local length = (tonumber(reaper.GetExtState( "amagalma_Take_Vol_in_TS", "length" )) or 3) * 0.001
local undo_str = "Take Vol: " .. change .. "dB (item" .. (item_cnt > 1 and "s" or "") .. " in time selection)"
change = 10 ^ ( change / 20 )
local undo = false
local vol_env = "\n<VOLENV\nEGUID " .. reaper.genGuid("") ..
"\nACT 1 -1\nVIS 1 1 1\nLANEHEIGHT 0 0\nARM 1\nDEFSHAPE 0 -1 -1\nVOLTYPE 1\nPT 0 1 0\n>\n"

local function EnableTakeVol(take, item)
  local takeGUID = reaper.BR_GetMediaItemTakeGUID( take )
  local take_cnt = reaper.CountTakes( item )
  local fx_count = reaper.TakeFX_GetCount( take )
  local _, chunk = reaper.GetItemStateChunk( item, "", false )
  local t = {}
  local i = 0
  local insert
  local foundTake = take_cnt == 1
  local search_take_end = true
  for line in chunk:gmatch("[^\n]+") do
    i = i + 1
    t[i] = line
    if not foundTake then
      if line:find(takeGUID:gsub("-", "%%-")) then
      foundTake = true
      end
    end
    if foundTake then
      if (not insert) and i > 30 then
        if line:find("^<.-ENV$") then
          insert = i
        elseif fx_count > 0 then
          if line:find("^TAKE_FX_HAVE_") then
            insert = i + 1
          end
        end
      end
      if not insert and search_take_end and line == ">" then
        search_take_end = false
        insert = i + 1
      end
    end
  end
  chunk = table.concat(t, "\n", 1, insert-1 ) .. vol_env .. table.concat(t, "\n", insert )
  reaper.SetItemStateChunk( item, chunk, true )
  return reaper.GetTakeEnvelopeByName( take, "Volume" )
end

local function adjustPoints(env, id1, id2, mode, change)
  for id = id1, id2 do
    local _, time, val, shape, tens, sel = reaper.GetEnvelopePoint( env, id )
    local newval = mode == 0 and val*change or
           reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val )*change))
    reaper.SetEnvelopePoint( env, id, time, newval, shape, tens, sel, true )
  end
end

reaper.PreventUIRefresh( 1 )
for i = 1, #items do
  local item = items[i][1]
  local take = items[i][2]
  local ST, EN = ST, EN
  local position = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
  local End = position + reaper.GetMediaItemInfo_Value( item, "D_LENGTH" )
  local inside_area = true
  if position >= EN or End <= ST then inside_area = false end
  if inside_area then
    if ST < position then ST = position end
    if EN > End then EN = End end
    local env = reaper.GetTakeEnvelopeByName( take, "Volume" )
    if not env then env = EnableTakeVol(take, item) end
    local mode = reaper.GetEnvelopeScalingMode( env )
    local ST_in_item = ST - position
    local EN_in_item = EN - position
    local id1 = reaper.GetEnvelopePointByTime( env, ST_in_item )
    local id2 = reaper.GetEnvelopePointByTime( env, EN_in_item )
    local _, time = reaper.GetEnvelopePoint( env, id1 )
    local _, time2 = reaper.GetEnvelopePoint( env, id2 )
    if eq(time, ST_in_item) and eq(time2, EN_in_item) then
      adjustPoints(env, id1, id2, mode, change)
    else
      local samplerate = reaper.GetMediaSourceSampleRate( reaper.GetMediaItemTake_Source( take ) )
      local _, val1 = reaper.Envelope_Evaluate( env, ST_in_item - length, samplerate, 5 )
      local _, val2 = reaper.Envelope_Evaluate( env, EN_in_item + length, samplerate, 5 )
      local newval1 = mode == 0 and val1*change or
             reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val1 )*change))
      local newval2 = mode == 0 and val2*change or
             reaper.ScaleToEnvelopeMode( 1, (reaper.ScaleFromEnvelopeMode( 1, val2 )*change))
      local noSorted = true
      if id1 ~= id2 then
        noSorted = false
      end
      reaper.InsertEnvelopePoint( env, ST_in_item - length, val1, 0, 0, 0, noSorted )
      reaper.InsertEnvelopePoint( env, ST_in_item, newval1, 0, 0, 0, noSorted )
      reaper.InsertEnvelopePoint( env, EN_in_item, newval2, 0, 0, 0, noSorted )
      reaper.InsertEnvelopePoint( env, EN_in_item + length, val2, 0, 0, 0, noSorted )
      if not noSorted then
        adjustPoints(env, id1 + 3, id2 + 2, mode, change)
      end
    end
    reaper.Envelope_SortPoints( env )
    undo = true
  end
end
reaper.PreventUIRefresh( -1 )

if undo then
  reaper.Undo_OnStateChangeEx( undo_str, 1, -1 )
else
  reaper.defer(function() end)
end
